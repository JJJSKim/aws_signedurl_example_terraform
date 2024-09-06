# SignedURL 생성을 위한 PublicKey 저장

# PrivateKey 생성
resource "tls_private_key" "private_key" {
  for_each  = toset(var.signed_url_bucket_names)
  algorithm = "RSA"
  rsa_bits  = "2048"
}

# Cloudfront PublicKey 생성
resource "aws_cloudfront_public_key" "cf_key" {
  for_each    = toset(var.signed_url_bucket_names)
  comment     = "${each.value} public key"
  encoded_key = tls_private_key.private_key[each.value].public_key_pem
  name        = "aws-cf-pubkey-${each.value}-an2"
}

# Cloudfront PublicKey group 생성
resource "aws_cloudfront_key_group" "cf_key_group" {
  for_each = toset(var.signed_url_bucket_names)
  items    = [aws_cloudfront_public_key.cf_key[each.value].id]
  name     = "aws-cf-keygroup-${each.value}-an2"
}