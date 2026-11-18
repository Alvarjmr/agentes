# 1. Rol de ejecución para AWS Lambda
resource "aws_iam_role" "lambda_exec" {
  name = "${var.project_name}-lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name     = "${var.project_name}-lambda-role"
    Security = "LeastPrivilege"
  }
}

# 2. Política de Mínimo Privilegio (Principio Zero-Trust)
resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.project_name}-lambda-least-privilege"
  description = "Permisos mínimos para lectura/escritura en DynamoDB y cifrado KMS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Operaciones estrictas en la tabla DynamoDB
      {
        Sid    = "DynamoDBAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:UpdateItem"
        ]
        Resource = [
          aws_dynamodb_table.citas.arn,
          "${aws_dynamodb_table.citas.arn}/index/*"
        ]
      },
      # Permisos criptográficos KMS para descifrar/cifrar en reposo
      {
        Sid    = "KMSOperations"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey*"
        ]
        Resource = aws_kms_key.main.arn
      },
      # Registro de auditoría y métricas en CloudWatch Logs
      {
        Sid    = "CloudWatchLogsAccess"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
      }
    ]
  })
}

# 3. Vincular política al rol de Lambda
resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}
