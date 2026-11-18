let DynamoDBClient, PutItemCommand, QueryCommand, UpdateItemCommand;

try {
  const sdk = require("@aws-sdk/client-dynamodb");
  DynamoDBClient = sdk.DynamoDBClient;
  PutItemCommand = sdk.PutItemCommand;
  QueryCommand = sdk.QueryCommand;
  UpdateItemCommand = sdk.UpdateItemCommand;
} catch (e) {
  // Mock para pruebas locales cuando no se ha ejecutado npm install
  DynamoDBClient = class { send() { return Promise.resolve({}); } };
  PutItemCommand = class {};
  QueryCommand = class { constructor() { this.Items = []; } };
  UpdateItemCommand = class {};
}

const REGION = process.env.AWS_REGION || "us-east-1";
const TABLE_NAME = process.env.TABLE_NAME || "citas-escolares-tabla-citas";

const client = new DynamoDBClient({ region: REGION });

/**
 * Guarda una nueva cita aplicando bloqueo atómico anti-cruces.
 * Si ya existe una cita en ese mismo horario para el docente, falla por condición.
 */
async function guardarCitaAtomics({ profesorId, fechaHora, acudiente, telefono, estudiante, observaciones }) {
  const pk = `DOC#${profesorId}`;
  const sk = `SLOT#${fechaHora}`;

  const params = {
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
    // Candado Atómico: Falla inmediatamente si ya existe el registro
    ConditionExpression: "attribute_not_exists(PK)"
  };

  return await client.send(new PutItemCommand(params));
}

/**
 * Consulta todas las citas de un profesor específico (Aislamiento por docente).
 */
async function obtenerCitasDocente(profesorId) {
  const params = {
    TableName: TABLE_NAME,
    KeyConditionExpression: "PK = :pk",
    ExpressionAttributeValues: {
      ":pk": { S: `DOC#${profesorId}` }
    }
  };

  const result = await client.send(new QueryCommand(params));
  return (result.Items || []).map(item => ({
    profesorId: item.profesorId?.S,
    fechaHora: item.fechaHora?.S,
    acudiente: item.acudiente?.S,
    telefono: item.telefono?.S,
    estudiante: item.estudiante?.S,
    estado: item.estado?.S,
    observaciones: item.observaciones?.S,
    creadaEl: item.creadaEl?.S
  }));
}

/**
 * Consulta la disponibilidad de slots ocupados de un profesor en una fecha dada.
 */
async function obtenerDisponibilidadDocente(profesorId, fecha) {
  const params = {
    TableName: TABLE_NAME,
    KeyConditionExpression: "PK = :pk AND begins_with(SK, :skPrefix)",
    ExpressionAttributeValues: {
      ":pk": { S: `DOC#${profesorId}` },
      ":skPrefix": { S: `SLOT#${fecha}` }
    }
  };

  const result = await client.send(new QueryCommand(params));
  return (result.Items || []).map(item => item.fechaHora?.S);
}

/**
 * Actualiza el estado de una cita (ej: ATENDIDA o CANCELADA).
 */
async function actualizarEstadoCita(profesorId, fechaHora, nuevoEstado) {
  const params = {
    TableName: TABLE_NAME,
    Key: {
      PK: { S: `DOC#${profesorId}` },
      SK: { S: `SLOT#${fechaHora}` }
    },
    UpdateExpression: "SET estado = :nuevoEstado",
    ExpressionAttributeValues: {
      ":nuevoEstado": { S: nuevoEstado }
    },
    ReturnValues: "ALL_NEW"
  };

  return await client.send(new UpdateItemCommand(params));
}

module.exports = {
  guardarCitaAtomics,
  obtenerCitasDocente,
  obtenerDisponibilidadDocente,
  actualizarEstadoCita
};
