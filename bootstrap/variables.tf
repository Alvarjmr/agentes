variable "aws_region" {
  description = "Región de AWS donde reside la infraestructura."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefijo para los nombres de los recursos de bootstrap."
  type        = string
  default     = "citas-escolares"
}

variable "github_org" {
  description = "Usuario u Organización de GitHub propietaria del repositorio (ej: 'mi-usuario' o 'colegio-san-jose')."
  type        = string
  default     = "mi-organizacion"
}

variable "github_repo" {
  description = "Nombre del repositorio de GitHub (usa '*' para permitir todos los repositorios de github_org)."
  type        = string
  default     = "*"
}

variable "github_branch" {
  description = "Rama principal que tiene autorización para desplegar en AWS."
  type        = string
  default     = "main"
}

variable "create_oidc_provider" {
  description = "Crear/gestionar el proveedor OIDC de GitHub (importar si ya existe en la cuenta AWS)."
  type        = bool
  default     = true
}

variable "enable_dynamodb_lock" {
  description = "Crear tabla DynamoDB para state locking (false usa S3 use_lockfile nativo de Terraform >= 1.10)."
  type        = bool
  default     = false
}
