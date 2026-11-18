# Empaquetado automático del código fuente desde la carpeta separada 'backend/src'
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../backend/src"
  output_path = "${path.module}/lambda_payload.zip"
}

# Grupo de logs de CloudWatch con retención limitada y cifrado KMS
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.project_name}-backend"
  retention_in_days = 14
  kms_key_id        = aws_kms_key.main.arn

  tags = {
    Name = "${var.project_name}-logs"
  }
}

# Función Lambda Serverless
resource "aws_lambda_function" "api_handler" {
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  function_name    = "${var.project_name}-backend"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  architectures    = ["arm64"] # Arquitectura Graviton2 para costo mínimo y alta velocidad

  memory_size = 128
  timeout     = 10

  environment {
    variables = {
      TABLE_NAME  = aws_dynamodb_table.citas.name
      KMS_KEY_ARN = aws_kms_key.main.arn
      ENVIRONMENT = var.environment
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda_logs,
    aws_iam_role_policy_attachment.lambda_attach
  ]

  tags = {
    Name        = "${var.project_name}-backend"
    Security    = "Firecracker-Sandbox"
    Environment = var.environment
  }
}
