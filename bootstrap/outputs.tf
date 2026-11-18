output "github_actions_role_arn" {
  description = "ARN del Rol IAM asumible por GitHub Actions mediante OIDC (Agregar como secreto en GitHub: AWS_ROLE_TO_ASSUME)"
  value       = aws_iam_role.github_actions_role.arn
}

output "terraform_state_bucket" {
  description = "Nombre del bucket S3 para el backend remoto de Terraform"
  value       = aws_s3_bucket.terraform_state.id
}

output "terraform_lock_table" {
  description = "Nombre de la tabla DynamoDB para bloqueo concurrente de estado"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "aws_region" {
  description = "Región de AWS configurada"
  value       = var.aws_region
}
