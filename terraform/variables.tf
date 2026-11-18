variable "aws_region" {
  description = "Región de AWS donde se desplegarán todos los recursos serverless."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Entorno de despliegue (prod, dev, staging)."
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Prefijo para los nombres de los recursos del proyecto."
  type        = string
  default     = "citas-escolares"
}

variable "whatsapp_token_secret_name" {
  description = "Nombre del secreto en AWS Secrets Manager para almacenar el token de la API de WhatsApp."
  type        = string
  default     = "citas-escolares/whatsapp-token"
}
