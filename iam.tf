# 요청 계정 정보
data "aws_caller_identity" "current" {}

# IAM 로컬 변수
locals {
  user_prefix = join("-", [
    local.resource_prefix,
    "user"
  ])
  role_prefix = join("-", [
    local.resource_prefix,
    "role"
  ])
  policy_prefix = join("-", [
    local.resource_prefix,
    "policy"
  ])
}

resource "aws_iam_policy" "surl_policy" {
  name        = join("-", [local.policy_prefix, "surl", local.resource_suffix])
  path        = "/"
  description = "surl access policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "logs:CreateLogGroup"
        Resource = "arn:aws:logs:${var.region_raw[var.region]}:${data.aws_caller_identity.current.account_id}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = [
          "arn:aws:logs:${var.region_raw[var.region]}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.surl.function_name}:*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        Resource = [
          "${aws_secretsmanager_secret.surl.arn}"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "surl_role" {
  name = join("-", [local.role_prefix, "surl", local.resource_suffix])

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy_attachment" "surl_attach" {
  name       = join("-", [local.role_prefix, "surl-attach", local.resource_suffix])
  roles      = [aws_iam_role.surl_role.name]
  policy_arn = aws_iam_policy.surl_policy.arn
}