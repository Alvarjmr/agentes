# 1. Proveedor OIDC de GitHub en AWS (Solo se crea una vez en la cuenta)
# Si ya existe en la cuenta, se puede reutilizar o importar
data "aws_iam_openid_connect_provider" "existing_github" {
  count = 0 # Cambiar a 1 si ya existe en la cuenta
  url   = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f8d264fcd9"
  ]

  tags = {
    Name = "GitHubActionsOIDCProvider"
  }
}

# 2. Rol IAM Asumible mediante OIDC por GitHub Actions (Sin llaves permanentes)
resource "aws_iam_role" "github_actions_role" {
  name        = "${var.project_name}-github-oidc-role"
  description = "Rol asumido temporalmente por GitHub Actions mediante tokens OIDC para CI/CD"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            # Restricción estricta: Solo el repositorio del proyecto puede asumir el rol
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
          }
        }
      }
    ]
  })

  tags = {
    Name     = "${var.project_name}-github-oidc-role"
    Security = "OIDC-ZeroPermanentKeys"
  }
}

# 3. Política de Permisos para el Pipeline de Despliegue (Terraform + App Deploy)
resource "aws_iam_policy" "pipeline_policy" {
  name        = "${var.project_name}-pipeline-deploy-policy"
  description = "Permisos necesarios para que el pipeline cree la infraestructura y despliegue backend/frontend"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Gestión de Estado Remoto en S3 y Bloqueo en DynamoDB
      {
        Sid    = "TerraformStateBackend"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          aws_s3_bucket.terraform_state.arn,
          "${aws_s3_bucket.terraform_state.arn}/*"
        ]
      },
      {
        Sid    = "TerraformStateLocking"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = aws_dynamodb_table.terraform_locks.arn
      },
      # Permisos para aprovisionar los servicios de la arquitectura escolar
      {
        Sid    = "DeploySchoolServices"
        Effect = "Allow"
        Action = [
          # S3 y CloudFront (Frontend)
          "s3:*",
          "cloudfront:*",
          # Cómputo y Gateway
          "lambda:*",
          "apigateway:*",
          # Base de Datos
          "dynamodb:*",
          # Seguridad y Criptografía
          "cognito-idp:*",
          "kms:*",
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:PassRole",
          "iam:PutRolePolicy",
          "iam:GetRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:ListRolePolicies",
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:ListPolicyVersions",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:TagPolicy",
          # Monitoreo
          "logs:*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "pipeline_attach" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.pipeline_policy.arn
}
