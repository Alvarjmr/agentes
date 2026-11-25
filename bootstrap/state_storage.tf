resource "random_string" "state_suffix" {
  length  = 8
  special = false
  upper   = false
}

# 1. Bucket S3 para almacenar el estado remoto de Terraform (terraform.tfstate)
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.project_name}-tfstate-${random_string.state_suffix.result}"

  # Protección contra borrado accidental
  lifecycle {
    prevent_destroy = false
  }
}

# Habilitar versionado de estado (permite rollback de infraestructura)
resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Cifrado en reposo obligatorio con AES-256
resource "aws_s3_bucket_server_side_encryption_configuration" "state_encryption" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Bloqueo total de acceso público (Seguridad de Estado)
resource "aws_s3_bucket_public_access_block" "state_public_block" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 2. Tabla DynamoDB opcional para Bloqueo Concurrente de Estado (State Locking)
resource "aws_dynamodb_table" "terraform_locks" {
  count        = var.enable_dynamodb_lock ? 1 : 0
  name         = "${var.project_name}-tf-locks"
  billing_mode = "PAY_PER_REQUEST" # Free tier ($0)
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name = "${var.project_name}-tf-locks"
  }
}
