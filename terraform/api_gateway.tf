# 1. API Gateway HTTP API v2 (Ultraligera, 100% Serverless)
resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.project_name}-http-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_credentials = false
    allow_headers     = ["Content-Type", "Authorization", "X-Amz-Date", "X-Api-Key", "X-Amz-Security-Token"]
    allow_methods     = ["GET", "POST", "OPTIONS", "PATCH"]
    allow_origins     = ["*"] # En producción se puede restringir al dominio de CloudFront
    max_age           = 3600
  }

  tags = {
    Name     = "${var.project_name}-api"
    Security = "TLS1.3-Endpoint"
  }
}

# 2. Autorizador JWT de Amazon Cognito para Docentes
resource "aws_apigatewayv2_authorizer" "cognito" {
  api_id           = aws_apigatewayv2_api.http_api.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "${var.project_name}-cognito-authorizer"

  jwt_configuration {
    audience = [aws_cognito_user_pool_client.pwa_client.id]
    issuer   = "https://${aws_cognito_user_pool.profesores.endpoint}"
  }
}

# 3. Integración de API Gateway con AWS Lambda (AWS_PROXY)
resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.api_handler.arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# 4. Rutas de la API

# RUTA A: POST /citas (Pública para Acudientes)
resource "aws_apigatewayv2_route" "post_citas" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /citas"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# RUTA B: GET /disponibilidad (Pública para consultar horarios disponibles)
resource "aws_apigatewayv2_route" "get_disponibilidad" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /disponibilidad"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# RUTA C: GET /mis-citas (Protegida exclusivamente para Profesores con JWT de Cognito)
resource "aws_apigatewayv2_route" "get_mis_citas" {
  api_id             = aws_apigatewayv2_api.http_api.id
  route_key          = "GET /mis-citas"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

# RUTA D: PATCH /citas (Protegida para Profesores: cambiar estado a ATENDIDA/CANCELADA)
resource "aws_apigatewayv2_route" "patch_citas" {
  api_id             = aws_apigatewayv2_api.http_api.id
  route_key          = "PATCH /citas"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

# 5. Despliegue automático ($default stage)
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  tags = {
    Name = "${var.project_name}-default-stage"
  }
}

# Grupo de logs para API Gateway
resource "aws_cloudwatch_log_group" "api_gw_logs" {
  name              = "/aws/apigateway/${var.project_name}-api"
  retention_in_days = 14
  kms_key_id        = aws_kms_key.main.arn
}

# 6. Permiso para que API Gateway invoque la función Lambda
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.arn}/*/*"
}
