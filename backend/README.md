# Backend Serverless: API de Citas Escolares

Microservicio desarrollado en **Node.js (AWS SDK v3)** para ejecutarse en **AWS Lambda** bajo arquitectura **ARM64 (Graviton2)**.

## 🎯 Rutas de la API

| Método | Endpoint | Autenticación | Descripción |
| :--- | :--- | :--- | :--- |
| `OPTIONS` | `/*` | Ninguna | Preflight CORS para navegadores móviles. |
| `POST` | `/citas` | Ninguna (Pública) | Reserva de cita con bloqueo atómico DynamoDB (`attribute_not_exists(PK)`). |
| `GET` | `/disponibilidad` | Ninguna (Pública) | Consulta qué horarios ya están tomados para un docente en una fecha. |
| `GET` | `/mis-citas` | Cognito JWT (Docente) | Retorna únicamente la agenda del docente autenticado. |
| `PATCH` | `/citas` | Cognito JWT (Docente) | Permite al docente marcar una cita como `ATENDIDA` o `CANCELADA`. |

## 🧪 Pruebas Locales
Para ejecutar las pruebas sin desplegar:
```bash
node test/local-test.js
```
