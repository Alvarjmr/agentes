# ==============================================================================
# Script de Bootstrap Automatizado - Citas Escolares Serverless
# ==============================================================================
# Este script:
# 1. Verifica herramientas necesarias (Terraform, AWS CLI).
# 2. Comprueba las credenciales de AWS activas.
# 3. Inicializa y aplica la configuración de Terraform en ./bootstrap.
# 4. Genera automáticamente ./terraform/backend.tf con el bucket y tabla creados.
# 5. Muestra los secretos requeridos para GitHub Actions.
# ==============================================================================

$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   INICIANDO BOOTSTRAP DEL PROYECTO (AWS + TERRAFORM + OIDC)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Validar herramientas
Write-Host "`n[1/5] Verificando herramientas instaladas..." -ForegroundColor Yellow
if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
    Write-Error "Terraform no está instalado o no se encuentra en el PATH."
}
if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Error "AWS CLI no está instalado o no se encuentra en el PATH."
}
Write-Host "✓ Terraform y AWS CLI detectados correctamente." -ForegroundColor Green

# 2. Validar credenciales de AWS
Write-Host "`n[2/5] Comprobando credenciales activas de AWS..." -ForegroundColor Yellow
try {
    $awsIdentity = aws sts get-caller-identity --output json 2>$null | ConvertFrom-Json
    if (-not $awsIdentity) {
        throw "No se recibieron datos de identidad."
    }
    Write-Host "✓ Autenticado en AWS como:" -ForegroundColor Green
    Write-Host "  - Cuenta: $($awsIdentity.Account)" -ForegroundColor Gray
    Write-Host "  - ARN:    $($awsIdentity.Arn)" -ForegroundColor Gray
} catch {
    Write-Host "`n[!] ERROR: No se detectaron credenciales válidas de AWS." -ForegroundColor Red
    Write-Host "Por favor configura tus credenciales de AWS antes de continuar:" -ForegroundColor Yellow
    Write-Host "  Opción 1: Ejecutar 'aws configure' e ingresar Access Key y Secret Key." -ForegroundColor White
    Write-Host "  Opción 2: Exportar variables de entorno:" -ForegroundColor White
    Write-Host '            $env:AWS_ACCESS_KEY_ID="tu_access_key"' -ForegroundColor Gray
    Write-Host '            $env:AWS_SECRET_ACCESS_KEY="tu_secret_key"' -ForegroundColor Gray
    Write-Host '            $env:AWS_DEFAULT_REGION="us-east-1"' -ForegroundColor Gray
    Write-Host "  Opción 3: Iniciar sesión con AWS SSO: 'aws sso login'" -ForegroundColor White
    exit 1
}

# 3. Ejecutar Terraform en bootstrap
Write-Host "`n[3/5] Ejecutando Terraform en ./bootstrap..." -ForegroundColor Yellow
$bootstrapDir = Join-Path $PSScriptRoot "bootstrap"
Push-Location $bootstrapDir

try {
    Write-Host "-> Inicializando Terraform (terraform init)..." -ForegroundColor Gray
    terraform init
    if ($LASTEXITCODE -ne 0) { throw "Fallo terraform init" }

    Write-Host "-> Aplicando infraestructura de bootstrap (terraform apply)..." -ForegroundColor Gray
    terraform apply -auto-approve
    if ($LASTEXITCODE -ne 0) { throw "Fallo terraform apply" }

    # Obtener outputs
    $roleArn     = (terraform output -raw github_actions_role_arn).Trim()
    $stateBucket = (terraform output -raw terraform_state_bucket).Trim()
    $lockTable   = (terraform output -raw terraform_lock_table).Trim()
    $region      = (terraform output -raw aws_region).Trim()
} finally {
    Pop-Location
}

# 4. Configurar terraform/backend.tf
Write-Host "`n[4/5] Configurando backend remoto en ./terraform/backend.tf..." -ForegroundColor Yellow
$backendContent = @"
# Generado automáticamente por bootstrap.ps1
terraform {
  backend "s3" {
    bucket         = "$stateBucket"
    key            = "prod/terraform.tfstate"
    region         = "$region"
    dynamodb_table = "$lockTable"
    encrypt        = true
  }
}
"@

$backendPath = Join-Path $PSScriptRoot "terraform\backend.tf"
Set-Content -Path $backendPath -Value $backendContent -Encoding UTF8
Write-Host "✓ Archivo $backendPath generado con éxito." -ForegroundColor Green

# 5. Resumen de configuración para GitHub Actions
Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "   🎉 BOOTSTRAP COMPLETADO EXITOSAMENTE" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "`nRecursos creados en AWS:" -ForegroundColor White
Write-Host "  - Bucket S3 (Estado Remoto):    $stateBucket" -ForegroundColor Gray
Write-Host "  - Tabla DynamoDB (Bloqueo):     $lockTable" -ForegroundColor Gray
Write-Host "  - Rol IAM OIDC (GitHub Actions): $roleArn" -ForegroundColor Gray
Write-Host "  - Región:                       $region" -ForegroundColor Gray

Write-Host "`n👉 PASO SIGUIENTE OBLIGATORIO EN GITHUB:" -ForegroundColor Yellow
Write-Host "Ve a tu repositorio en GitHub:" -ForegroundColor White
Write-Host "https://github.com/Alvarjmr/agentes/settings/secrets/actions" -ForegroundColor Cyan
Write-Host "`nAgrega los siguientes secretos/variables de repositorio:" -ForegroundColor White
Write-Host "--------------------------------------------------------" -ForegroundColor Gray
Write-Host "1. Secret: AWS_ROLE_TO_ASSUME" -ForegroundColor White
Write-Host "   Valor:  $roleArn" -ForegroundColor Green
Write-Host "2. Secret / Variable: AWS_REGION" -ForegroundColor White
Write-Host "   Valor:  $region" -ForegroundColor Green
Write-Host "--------------------------------------------------------" -ForegroundColor Gray
Write-Host "`nUna vez configurados los secretos, haz git push a 'main' para activar el pipeline CI/CD." -ForegroundColor Cyan
