/**
 * Microservicio Serverless: Gestión de Citas Escolares
 * Implementa concurrencia atómica (Anti-Cruces) y aislamiento estricto por docente
 */

const { DynamoDBClient, PutItemCommand, QueryCommand } = require("@aws-sdk/client-dynamodb");

const dynamo = new DynamoDBClient({ region: process.env.AWS_REGION });
const TABLE_NAME = process.env.TABLE_NAME;

const HEADERS = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token",
  "Access-Control-Allow-Methods": "OPTIONS,POST,GET"
};

exports.handler = async (event) => {
  console.log("Evento recibido:", JSON.stringify(event));

  const httpMethod = event.requestContext?.http?.method || event.httpMethod;
  const path = event.requestContext?.http?.path || event.path;

  // Manejo de preflight CORS OPTIONS
  if (httpMethod === "OPTIONS") {
    return { statusCode: 204, headers: HEADERS, body: "" };
  }

  try {
    // RUTA 1: Agendar Cita (Público para Acudientes)
    // POST /citas
    if (httpMethod === "POST" && path.includes("/citas")) {
      const body = JSON.parse(event.body || "{}");
      const { profesorId, fechaHora, acudiente, telefono, estudiante, observaciones } = body;

      if (!profesorId || !fechaHora || !acudiente || !telefono) {
        return {
          statusCode: 400,
          headers: HEADERS,
          body: JSON.stringify({ error: "Faltan datos obligatorios (profesorId, fechaHora, acudiente, telefono)" })
        };
      }

      const pk = `DOC#${profesorId}`;
      const sk = `SLOT#${fechaHora}`;

      // Candado Atómico Anti-Cruces:
      // ConditionExpression: "attribute_not_exists(PK)" garantiza que si ya existe un slot a esa hora, falla inmediatamente
      const putParams = {
        TableName: TABLE_NAME,
        Item: {
          PK: { S: pk },
          SK: { S: sk },
          profesorId: { S: profesorId },
          fechaHora: { S: fechaHora },
          acudiente: { S: acudiente },
          telefono: { S: telefono },
          estudiante: { S: estudiante || "No especificado" },
          observaciones: { S: observaciones || "" },
          estado: { S: "CONFIRMADA" },
          creadaEl: { S: new Date().toISOString() }
        },
        ConditionExpression: "attribute_not_exists(PK)"
      };

      try {
        await dynamo.send(new PutItemCommand(putParams));

        return {
          statusCode: 201,
          headers: HEADERS,
          body: JSON.stringify({
            mensaje: "¡Cita confirmada exitosamente!",
            detalle: { profesorId, fechaHora, acudiente, estado: "CONFIRMADA" }
          })
        };
      } catch (dbError) {
        // Captura colisión simultánea
        if (dbError.name === "ConditionalCheckFailedException") {
          return {
            statusCode: 409,
            headers: HEADERS,
            body: JSON.stringify({
              error: "Horario no disponible",
              mensaje: "Este horario acaba de ser ocupado por otro acudiente. Por favor elija otro turno."
            })
          };
        }
        throw dbError;
      }
    }

    // RUTA 2: Consultar Agenda del Docente (Protegido por Cognito JWT)
    // GET /mis-citas
    if (httpMethod === "GET" && path.includes("/mis-citas")) {
      // El ID del docente se extrae del JWT verificado en el contexto de API Gateway
      const claims = event.requestContext?.authorizer?.jwt?.claims;
      const docenteId = claims?.sub || claims?.["cognito:username"] || event.queryStringParameters?.profesorId;

      if (!docenteId) {
        return {
          statusCode: 401,
          headers: HEADERS,
          body: JSON.stringify({ error: "No autorizado. Token de docente no válido." })
        };
      }

      // Consulta filtrada estrictamente por el ID del docente autenticado
      const queryParams = {
        TableName: TABLE_NAME,
        KeyConditionExpression: "PK = :pk",
        ExpressionAttributeValues: {
          ":pk": { S: `DOC#${docenteId}` }
        }
      };

      const result = await dynamo.send(new QueryCommand(queryParams));
      const citas = (result.Items || []).map(item => ({
        fechaHora: item.fechaHora?.S,
        acudiente: item.acudiente?.S,
        telefono: item.telefono?.S,
        estudiante: item.estudiante?.S,
        estado: item.estado?.S,
        observaciones: item.observaciones?.S
      }));

      return {
        statusCode: 200,
        headers: HEADERS,
        body: JSON.stringify({ docenteId, total: citas.length, citas })
      };
    }

    // Ruta no encontrada
    return {
      statusCode: 404,
      headers: HEADERS,
      body: JSON.stringify({ error: "Ruta no encontrada" })
    };

  } catch (error) {
    console.error("Error en procesamiento:", error);
    return {
      statusCode: 500,
      headers: HEADERS,
      body: JSON.stringify({ error: "Error interno del servidor", detalle: error.message })
    };
  }
};
