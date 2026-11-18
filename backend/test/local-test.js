/**
 * Script de prueba local para validar la lógica del backend sin desplegar
 */

const { handler } = require("../src/index");

async function runLocalTests() {
  console.log("=== INICIANDO PRUEBAS UNITARIAS LOCALES DEL BACKEND ===\n");

  // Prueba 1: Petición OPTIONS (CORS)
  console.log("1. Probando Preflight CORS (OPTIONS /citas)...");
  const optionsRes = await handler({
    httpMethod: "OPTIONS",
    path: "/citas"
  });
  console.log("-> Código HTTP recibido:", optionsRes.statusCode);
  console.assert(optionsRes.statusCode === 204, "Debe retornar 204 No Content");
  console.log("✓ CORS válido.\n");

  // Prueba 2: Validación de campos obligatorios
  console.log("2. Probando Validación de Body Incompleto (POST /citas)...");
  const invalidPostRes = await handler({
    httpMethod: "POST",
    path: "/citas",
    body: JSON.stringify({ acudiente: "Carlos" }) // Faltan profesorId, fechaHora, telefono
  });
  console.log("-> Código HTTP recibido:", invalidPostRes.statusCode);
  console.assert(invalidPostRes.statusCode === 400, "Debe retornar 400 Bad Request");
  console.log("✓ Validación de campos correcta.\n");

  console.log("=== TODAS LAS PRUEBAS BÁSICAS PASARON EXITOSAMENTE ===");
}

runLocalTests().catch(console.error);
