# Despliegue automático de los archivos de la carpeta separada 'frontend/' hacia Amazon S3

locals {
  frontend_dir = "${path.module}/../frontend"

  mime_types = {
    "html" = "text/html"
    "css"  = "text/css"
    "js"   = "application/javascript"
    "json" = "application/json"
  }
}

# Subir index.html
resource "aws_s3_object" "frontend_index" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "index.html"
  source       = "${local.frontend_dir}/index.html"
  content_type = "text/html"
  etag         = filemd5("${local.frontend_dir}/index.html")
}

# Subir app.js
resource "aws_s3_object" "frontend_app_js" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "app.js"
  source       = "${local.frontend_dir}/app.js"
  content_type = "application/javascript"
  etag         = filemd5("${local.frontend_dir}/app.js")
}

# Subir config.js
resource "aws_s3_object" "frontend_config_js" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "config.js"
  source       = "${local.frontend_dir}/config.js"
  content_type = "application/javascript"
  etag         = filemd5("${local.frontend_dir}/config.js")
}

# Subir styles.css
resource "aws_s3_object" "frontend_styles" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "styles.css"
  source       = "${local.frontend_dir}/styles.css"
  content_type = "text/css"
  etag         = filemd5("${local.frontend_dir}/styles.css")
}

# Subir manifest.json
resource "aws_s3_object" "frontend_manifest" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "manifest.json"
  source       = "${local.frontend_dir}/manifest.json"
  content_type = "application/json"
  etag         = filemd5("${local.frontend_dir}/manifest.json")
}
