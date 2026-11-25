# 1. Proveedor OIDC de GitHub en AWS (Solo se crea una vez en la cuenta)
data "aws_iam_openid_connect_provider" "existing_github" {
  count = var.create_oidc_provider ? 0 : 1
  url   = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github" {
  count           = var.create_oidc_provider ? 1 : 0
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

locals {
  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : data.aws_iam_openid_connect_provider.existing_github[0].arn
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
          Federated = local.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            # Permite a todos los repositorios configurados bajo github_org asumir el rol (github_repo = "*" para todos)
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
        Resource = var.enable_dynamodb_lock ? aws_dynamodb_table.terraform_locks[0].arn : "arn:aws:dynamodb:${var.aws_region}:*:table/${var.project_name}-tf-locks"
      },
      # Permisos para aprovisionar los servicios de los repositorios (Serverless, EC2, ASG, ALB, CloudWatch)
      {
        Sid    = "DeploySchoolServices"
        Effect = "Allow"
        Action = [
          # S3 y CloudFront (Frontend)
          "s3:*",
          "cloudfront:*",
          # Cómputo Serverless y Gateway
          "lambda:*",
          "apigateway:*",
          # Cómputo EC2, Redes, Balanceo de Carga y Auto Scaling
          "ec2:*",
          "autoscaling:*",
          "elasticloadbalancing:*",
          # Base de Datos
          "dynamodb:*",
          # Seguridad, Criptografía e Identidad
          "cognito-idp:*",
          "kms:*",
          "ssm:*",
          "sts:GetCallerIdentity",
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:ListRoles",
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
          "iam:CreatePolicyVersion",
          "iam:DeletePolicyVersion",
          "iam:SetDefaultPolicyVersion",
          "iam:ListPolicies",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:TagPolicy",
          "iam:UntagPolicy",
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:GetInstanceProfile",
          "iam:ListInstanceProfiles",
          "iam:ListInstanceProfilesForRole",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:TagInstanceProfile",
          "iam:UntagInstanceProfile",
          "iam:CreateServiceLinkedRole",
          # Monitoreo, Alarmas y Notificaciones
          "cloudwatch:*",
          "logs:*",
          "sns:*",
          "tag:*"
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
