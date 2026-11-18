# Fase de Bootstrap: OIDC para CI/CD y Backend Remoto de Terraform

Esta fase se ejecuta **una sola vez de forma manual** (o mediante credenciales de administrador temporal) para preparar la cuenta de AWS con:
1. **Proveedor OIDC de GitHub Actions**: Permite a GitHub identificarse criptográficamente con AWS usando tokens JWT efímeros. **Cero llaves permanentes (`AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`)**.
2. **Rol IAM para el Pipeline**: Con permisos delimitados para desplegar la infraestructura, el backend y el frontend.
3. **Almacenamiento de Estado Remoto (S3 + DynamoDB)**: Para que Terraform guarde su archivo de estado de forma segura y cifrada con bloqueo concurrente.

---

## 🚀 Cómo Ejecutar el Bootstrap

### 1. Configurar variables en `terraform.tfvars` (Opcional)
Edita `variables.tf` o crea un archivo `terraform.tfvars` indicando tu usuario y repositorio de GitHub:
```hcl
github_org  = "tu-usuario-o-organizacion"
github_repo = "tu-repositorio-citas"
aws_region  = "us-east-1"
```

### 2. Aplicar el Bootstrap
```bash
cd D:\Curso_Ciberseguridad\agentes\bootstrap
terraform init
terraform apply -auto-approve
```

### 3. Configurar GitHub Actions Secrets
Al finalizar, copia el valor de `github_actions_role_arn` y agrégalo en tu repositorio de GitHub:
* Ve a: **Settings** > **Secrets and variables** > **Actions** > **New repository secret**.
* Nombre: `AWS_ROLE_TO_ASSUME`
* Valor: `arn:aws:iam::123456789012:role/citas-escolares-github-oidc-role`
* Nombre: `AWS_REGION`
* Valor: `us-east-1`
