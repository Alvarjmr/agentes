# Sistema Serverless de Agendamiento de Citas Escolares

Arquitectura **100% Serverless en AWS** para agendamiento de citas escolares, orientada a costo cero ($0 USD/mes dentro de AWS Free Tier), alta disponibilidad y estándares de ciberseguridad (Zero-Trust, OIDC sin llaves permanentes, cifrado KMS AES-256 en reposo y TLS 1.3 en tránsito).

---

## 🏗️ Arquitectura del Proyecto

```
agentes/
├── .github/
│   └── workflows/
│       └── deploy.yml              # Pipeline CI/CD automatizado mediante OIDC
├── backend/                        # Microservicio Node.js (AWS Lambda + DynamoDB)
│   ├── package.json
│   ├── src/
│   │   ├── index.js                # Handler HTTP API y enrutamiento
│   │   └── db.js                   # Consultas y candado atómico anti-colisiones
│   └── test/
│       └── local-test.js           # Pruebas unitarias locales sin despliegue
├── frontend/                       # Interfaz Móvil PWA (HTML5, Vanilla JS, CSS3)
│   ├── index.html                  # Vistas para Acudientes y Docentes
│   ├── app.js                      # Lógica cliente y llamadas a la API
│   ├── config.js                   # Variables de conexión (autoinyectadas por CI/CD)
│   ├── styles.css                  # Estilos responsivos optimizados para móviles
│   └── manifest.json               # Configuración PWA (instalación nativa)
├── bootstrap/                      # Fase Inicial: OIDC y Backend Remoto de Terraform
│   ├── oidc.tf                     # Proveedor OIDC de GitHub + Rol IAM seguro
│   ├── state_storage.tf            # Bucket S3 cifrado y DynamoDB para state locking
│   ├── variables.tf / outputs.tf
│   └── terraform.tfvars            # Configuración vinculada al repositorio GitHub
├── terraform/                      # Infraestructura principal de la aplicación
│   ├── api_gateway.tf              # HTTP API v2 con autorizador JWT y CORS
│   ├── cognito.tf                  # Directorio de docentes con SRP y JWT
│   ├── dynamodb.tf                 # Tabla de citas con bloqueo atómico
│   ├── kms.tf                      # Clave maestra KMS (AES-256)
│   ├── lambda.tf                   # Función Lambda para microservicios
│   ├── s3_cloudfront.tf            # Bucket privado S3 + CDN CloudFront
│   └── frontend_deploy.tf          # Despliegue estático automático a S3
├── bootstrap.ps1                   # Script de automatización de Bootstrap
└── README.md
```

---

## 🚀 Guía de Bootstrap (Paso a Paso)

El proceso de **Bootstrap** prepara tu cuenta de AWS una sola vez para que GitHub Actions pueda desplegar todo automáticamente sin necesidad de almacenar credenciales permanentes (`AWS_ACCESS_KEY_ID` ni `AWS_SECRET_ACCESS_KEY`).

### Requisitos Previos
1. [AWS CLI](https://aws.amazon.com/cli/) instalado y configurado con credenciales de administrador:
   ```powershell
   aws configure
   ```
2. [Terraform](https://www.terraform.io/) (>= 1.5.0) instalado.

---

### Opción A: Bootstrap Automático (Recomendado)
Ejecuta el script PowerShell incluido en la raíz del proyecto:
```powershell
.\bootstrap.ps1
```
Este script:
1. Comprueba la conexión y credenciales activas con AWS (`aws sts get-caller-identity`).
2. Inicializa y aplica Terraform en `./bootstrap` con los parámetros del repositorio `Alvarjmr/agentes`.
3. Crea el bucket S3 cifrado y la tabla DynamoDB para el backend remoto.
4. Crea el rol IAM con proveedor OIDC vinculado a este repositorio.
5. Genera automáticamente el archivo `terraform/backend.tf`.
6. Imprime los valores exactos que debes agregar en los Secretos de GitHub.

---

### Opción B: Bootstrap Manual

1. **Revisar variables:**
   El archivo [`bootstrap/terraform.tfvars`](file:///D:/Curso_Ciberseguridad/agentes/bootstrap/terraform.tfvars) ya está configurado con:
   ```hcl
   github_org    = "Alvarjmr"
   github_repo   = "agentes"
   github_branch = "main"
   aws_region    = "us-east-1"
   project_name  = "citas-escolares"
   ```

2. **Aplicar Terraform Bootstrap:**
   ```powershell
   cd bootstrap
   terraform init
   terraform apply -auto-approve
   ```

3. **Configurar el backend remoto de Terraform:**
   Copia los valores de salida `terraform_state_bucket` y `terraform_lock_table` y crea el archivo `terraform/backend.tf`:
   ```hcl
   terraform {
     backend "s3" {
       bucket         = "<nombre-del-bucket-generado>"
       key            = "prod/terraform.tfstate"
       region         = "us-east-1"
       dynamodb_table = "citas-escolares-tf-locks"
       encrypt        = true
     }
   }
   ```

4. **Configurar Secretos en GitHub Actions:**
   Ve a: **GitHub Repo** > **Settings** > **Secrets and variables** > **Actions** > **New repository secret**:
   - `AWS_ROLE_TO_ASSUME`: ARN del rol devuelto por `github_actions_role_arn`
   - `AWS_REGION`: `us-east-1`

5. **Despliegue Continuo (CI/CD):**
   Realiza un push a la rama `main` para que el flujo en [`.github/workflows/deploy.yml`](file:///D:/Curso_Ciberseguridad/agentes/.github/workflows/deploy.yml) despliegue automáticamente:
   - Infraestructura en AWS con Terraform.
   - Microservicios en AWS Lambda.
   - PWA Frontend sincronizada a S3 e invalidación de caché en CloudFront.
