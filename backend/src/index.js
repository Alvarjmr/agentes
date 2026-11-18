/**
 * Controlador Principal AWS Lambda: Citas Escolares Serverless
 */

const {
  guardarCitaAtomics,
  obtenerCitasDocente,
  obtenerDisponibilidadDocente,
  actualizarEstadoCita
} = require("./db");

const HEADERS = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token",
  "Access-Control-Allow-Methods": "OPTIONS,POST,GET,PATCH"
};

exports.handler = async (event) => {
  console.log("Evento recibido:", JSON.stringify(event));

  const httpMethod = event.requestContext?.http?.method || event.httpMethod || "GET";
  const path = event.requestContext?.http?.path || event.path || "/";

  // Manejo de preflight CORS
  if (httpMethod === "OPTIONS") {
    return { statusCode: 204, headers: HEADERS, body: "" };
  }

  try {
    // -------------------------------------------------------------
    // RUTA 1: POST /citas (Pública - Agendamiento de Acudientes)
    // -------------------------------------------------------------
    if (httpMethod === "POST" && path.endsWith("/citas")) {
      const body = JSON.parse(event.body || "{}");
      const { profesorId, fechaHora, acudiente, telefono, estudiante, observaciones } = body;

      if (!profesorId || !fechaHora || !acudiente || !telefono) {
        return {
          statusCode: 400,
          headers: HEADERS,
          body: JSON.stringify({ error: "Faltan campos obligatorios: profesorId, fechaHora, acudiente, telefono" })
        };
      }

      try {
        await guardarCitaAtomics({
          profesorId,
          fechaHora,
          acudiente,
          telefono,
          estudiante,
          observaciones
        });

        return {
          statusCode: 201,
          headers: HEADERS,
          body: JSON.stringify({
            mensaje: "¡Cita confirmada exitosamente!",
            detalle: { profesorId, fechaHora, acudiente, estudiante, estado: "CONFIRMADA" }
          })
        };
      } catch (dbError) {
        if (dbError.name === "ConditionalCheckFailedException") {
          return {
            statusCode: 409,
            headers: HEADERS,
            body: JSON.stringify({
              error: "Horario no disponible",
              mensaje: "Este horario acaba de ser ocupado por otro acudiente. Por favor seleccione otro turno."
            })
          };
        }
        throw dbError;
      }
    }

    // -------------------------------------------------------------
    // RUTA 2: GET /disponibilidad (Pública - Horarios ocupados)
    // -------------------------------------------------------------
    if (httpMethod === "GET" && path.includes("/disponibilidad")) {
      const profesorId = event.queryStringParameters?.profesorId;
      const fecha = event.queryStringParameters?.fecha || new Date().toISOString().split("T")[0];

      if (!profesorId) {
        return {
          statusCode: 400,
          headers: HEADERS,
          body: JSON.stringify({ error: "Debe especificar el parámetro 'profesorId'" })
        };
      }

      const ocupados = await obtenerDisponibilidadDocente(profesorId, fecha);
      return {
        statusCode: 200,
        headers: HEADERS,
        body: JSON.stringify({ profesorId, fecha, horariosOcupados: ocupados })
      };
    }

    // -------------------------------------------------------------
    // RUTA 3: GET /mis-citas (Privada - Panel Exclusivo Docente)
    // -------------------------------------------------------------
    if (httpMethod === "GET" && path.endsWith("/mis-citas")) {
      // Extrae la identidad del docente desde el JWT validado por Cognito
      const claims = event.requestContext?.authorizer?.jwt?.claims;
      const docenteId = claims?.sub || claims?.["cognito:username"] || event.queryStringParameters?.profesorId;

      if (!docenteId) {
        return {
          statusCode: 401,
          headers: HEADERS,
          body: JSON.stringify({ error: "No autorizado. Token de docente ausente o inválido." })
        };
      }

      const citas = await obtenerCitasDocente(docenteId);
      return {
        statusCode: 200,
        headers: HEADERS,
        body: JSON.stringify({ docenteId, total: citas.length, citas })
      };
    }

    // -------------------------------------------------------------
    // RUTA 4: PATCH /citas (Privada - Cambiar estado ATENDIDA / CANCELADA)
    // -------------------------------------------------------------
    if (httpMethod === "PATCH" && path.includes("/citas")) {
      const body = JSON.parse(event.body || "{}");
      const { profesorId, fechaHora, nuevoEstado } = body;

      if (!profesorId || !fechaHora || !nuevoEstado) {
        return {
          statusCode: 400,
          headers: HEADERS,
          body: JSON.stringify({ error: "Faltan campos obligatorios: profesorId, fechaHora, nuevoEstado" })
        };
      }

      await actualizarEstadoCita(profesorId, fechaHora, nuevoEstado);
      return {
        statusCode: 200,
        headers: HEADERS,
        body: JSON.stringify({ mensaje: `Estado actualizado a ${nuevoEstado} exitosamente.` })
      };
    }

    // Ruta desconocida
    return {
      statusCode: 404,
      headers: HEADERS,
      body: JSON.stringify({ error: "Ruta no encontrada" })
    };

  } catch (error) {
    console.error("Error en Lambda:", error);
    return {
      statusCode: 500,
      headers: HEADERS,
      body: JSON.stringify({ error: "Error interno del servidor", detalle: error.message })
    };
  }
};
