output "cloudfront_url" {
  description = "URL HTTPS de la aplicación web móvil (PWA) servida por CloudFront"
  value       = "https://${aws_cloudfront_distribution.pwa.domain_name}"
}

output "api_endpoint" {
  description = "URL base del API Gateway HTTP para invocar los microservicios"
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "cognito_user_pool_id" {
  description = "ID del User Pool de Cognito para gestión de docentes"
  value       = aws_cognito_user_pool.profesores.id
}

output "cognito_app_client_id" {
  description = "ID del Cliente de Aplicación en Cognito para la PWA"
  value       = aws_cognito_user_pool_client.pwa_client.id
}

output "dynamodb_table_name" {
  description = "Nombre de la tabla DynamoDB cifrada con KMS"
  value       = aws_dynamodb_table.citas.name
}

output "kms_key_arn" {
  description = "ARN de la llave maestra KMS utilizada para cifrado en reposo"
  value       = aws_kms_key.main.arn
}

output "s3_bucket_name" {
  description = "Nombre del bucket S3 privado donde se sube la interfaz PWA"
  value       = aws_s3_bucket.frontend.id
}


output "cloudfront_distribution_id" {
  description = "ID de la distribución de CloudFront para invalidación de caché"
  value       = aws_cloudfront_distribution.pwa.id
}

output "lambda_function_name" {
  description = "Nombre de la función Lambda para despliegue de código"
  value       = aws_lambda_function.api_handler.function_name
}
