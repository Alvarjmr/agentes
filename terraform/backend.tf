# Generado automáticamente por bootstrap.ps1
terraform {
  backend "s3" {
    bucket       = "citas-escolares-tfstate-gecj79xu"
    key          = "prod/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile   = true
    encrypt      = true
  }
}
