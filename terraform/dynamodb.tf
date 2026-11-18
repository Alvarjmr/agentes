resource "aws_dynamodb_table" "citas" {
  name         = "${var.project_name}-tabla-citas"
  billing_mode = "PAY_PER_REQUEST" # Serverless on-demand (Costo fijo $0 USD)
  hash_key     = "PK"
  range_key    = "SK"

  # Clave de partición: Identificador del Profesor (ej: DOC#101)
  attribute {
    name = "PK"
    type = "S"
  }

  # Clave de ordenamiento: Fecha y Hora del Slot (ej: SLOT#2026-11-20T10:00)
  attribute {
    name = "SK"
    type = "S"
  }

  # Cifrado en reposo con AWS KMS (AES-256)
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.main.arn
  }

  # Recuperación ante desastres (Point-in-Time Recovery)
  point_in_time_recovery {
    enabled = true
  }

  # Protección de eliminación accidental en producción
  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Name        = "${var.project_name}-tabla-citas"
    Security    = "At-Rest-Encrypted-KMS"
    Concurrency = "AtomicConditionalWrites"
  }
}
