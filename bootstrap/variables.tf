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
  description = "Nombre del repositorio de GitHub (ej: 'citas-escolares-aws')."
  type        = string
  default     = "citas-escolares-aws"
}

variable "github_branch" {
  description = "Rama principal que tiene autorización para desplegar en AWS."
  type        = string
  default     = "main"
}
