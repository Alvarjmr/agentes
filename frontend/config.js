/**
 * Configuración del Frontend
 * Estos valores se obtienen automáticamente de los outputs de Terraform:
 * `terraform output`
 */
const CONFIG = {
  // URL base de API Gateway generada por Terraform
  API_BASE_URL: "https://ejemplo-api.execute-api.us-east-1.amazonaws.com",

  // Datos de Amazon Cognito para autenticación de profesores
  COGNITO: {
    REGION: "us-east-1",
    USER_POOL_ID: "us-east-1_EjemploPool",
    APP_CLIENT_ID: "ejemploappclientid123456"
  },

  // Catálogo de Docentes del Colegio
  DOCENTES: [
    { id: "101", nombre: "Profa. Claudia Patricia", materia: "Matemáticas", grado: "Grado 9°", avatar: "CP" },
    { id: "102", nombre: "Prof. Ramón García", materia: "Ciencias Naturales", grado: "Grado 9°", avatar: "RG" },
    { id: "103", nombre: "Profa. Laura Jiménez", materia: "Español y Literatura", grado: "Grado 9°", avatar: "LJ" }
  ],

  // Franjas horarias estándar para citas
  FRANJAS_HORARIAS: [
    "08:00 AM", "08:30 AM", "09:00 AM",
    "10:00 AM", "10:30 AM", "11:00 AM",
    "02:00 PM", "02:30 PM", "03:00 PM"
  ]
};
