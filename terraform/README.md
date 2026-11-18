# Infraestructura como Código (IaC) en Terraform: Sistema de Citas Escolares

Este directorio contiene la arquitectura **100% Serverless en AWS** para solucionar el agendamiento de citas escolares sin servidores fijos ($0 USD/mes dentro de Free Tier) y con altos estándares de ciberseguridad (cifrado en tránsito y en reposo).

---

## 📁 Arquitectura del Repositorio y Conexiones

El proyecto está organizado en 3 carpetas desacopladas:
* **`backend/`**: Código del microservicio Node.js (AWS Lambda). Terraform lo empaqueta automáticamente desde `backend/src/`.
* **`frontend/`**: Aplicación móvil PWA (HTML, CSS, JS). Terraform la sube automáticamente al bucket S3 privado mediante `terraform/frontend_deploy.tf`.
* **`terraform/`**: Definición de infraestructura en AWS.

```
agentes/
├── backend/                  # CÓDIGO DEL BACKEND (LAMBDA + DYNAMODB)
│   ├── package.json
│   ├── src/
│   │   ├── index.js          # Handler principal y rutas HTTP
│   │   └── db.js             # Bloqueo atómico DynamoDB y consultas
│   └── test/
│       └── local-test.js     # Pruebas unitarias locales
│
├── frontend/                 # CÓDIGO DEL FRONTEND (PWA MÓVIL)
│   ├── index.html            # Interfaz PWA con vistas Acudiente y Docente
│   ├── app.js                # Lógica de cliente, llamadas API y Cognito
│   ├── config.js             # Variables de conexión generadas por Terraform
│   ├── styles.css            # Estilos y efectos de horario ocupado
│   └── manifest.json         # Instalación como App nativa en celular
│
└── terraform/                # INFRAESTRUCTURA COMO CÓDIGO (IaC)
    ├── versions.tf           # Proveedores (AWS ~> 5.0, Archive, Random)
    ├── variables.tf          # Variables de configuración
    ├── kms.tf                # Clave maestra KMS (AES-256) para cifrado en reposo
    ├── dynamodb.tf           # Tabla DynamoDB con bloqueo atómico
    ├── cognito.tf            # Directorio de docentes con SRP y JWT
    ├── s3_cloudfront.tf      # Bucket S3 privado + CloudFront CDN + OAC
    ├── frontend_deploy.tf    # Sube automáticamente frontend/ a S3
    ├── lambda.tf             # Empaqueta y despliega backend/src
    ├── iam.tf                # Permisos de Mínimo Privilegio (Zero-Trust)
    ├── api_gateway.tf        # HTTP API v2 con autorizador JWT y CORS
    └── outputs.tf            # URLs y claves exportadas
```

---

## 🚀 Despliegue Automatizado en 3 Pasos

### 1. Inicializar Terraform
```bash
cd D:\Curso_Ciberseguridad\agentes\terraform
terraform init
```

### 2. Previsualizar la Infraestructura
```bash
terraform plan
```

### 3. Aplicar Cambios
```bash
terraform apply -auto-approve
```

Al terminar el comando:
1. Se crea la base de datos cifrada con KMS en DynamoDB.
2. Se compila y empaqueta el backend desde `backend/src/` hacia AWS Lambda.
3. Se crea el bucket S3 privado y se suben todos los archivos desde `frontend/`.
4. Se crea la distribución CDN de CloudFront con HTTPS/TLS 1.3 forzado.
5. Se imprime en consola la URL lista para usar en el celular.
