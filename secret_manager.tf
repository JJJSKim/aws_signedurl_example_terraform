locals {
  secret_value = jsonencode({
    for key, value in aws_cloudfront_key_group.cf_key_group : key => tls_private_key.private_key[key].private_key_pem
  })
}

resource "aws_secretsmanager_secret" "surl" {
  name = var.secret_name
}

resource "aws_secretsmanager_secret_version" "surl" {
  secret_id     = aws_secretsmanager_secret.surl.id
  secret_string = local.secret_value
}