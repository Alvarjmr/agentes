resource "aws_cognito_user_pool" "profesores" {
  name = "${var.project_name}-user-pool-profesores"

  # Configuración de inicio de sesión por correo institucional
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  # Políticas de robustez de contraseñas (Habeas Data & Ciberseguridad)
  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }

  # Verificación de identidad y recuperación de cuenta
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  user_pool_add_ons {
    advanced_security_mode = "AUDIT"
  }

  tags = {
    Name     = "${var.project_name}-cognito-pool"
    Security = "PBKDF2-Salt-Hashing"
  }
}

# Cliente de la aplicación móvil PWA para Docentes (Autenticación SRP sin exponer claves)
resource "aws_cognito_user_pool_client" "pwa_client" {
  name         = "${var.project_name}-pwa-client"
  user_pool_id = aws_cognito_user_pool.profesores.id

  generate_secret = false # Aplicación SPA/PWA móvil pública

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",      # Secure Remote Password: la clave nunca viaja por la red
    "ALLOW_REFRESH_TOKEN_AUTH", # Renovación de sesión segura
    "ALLOW_USER_PASSWORD_AUTH"
  ]

  prevent_user_existence_errors = "ENABLED" # Mitiga ataques de enumeración de usuarios

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  access_token_validity  = 1
  id_token_validity      = 1
  refresh_token_validity = 30
}
