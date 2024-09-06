# Cloudfront 사용 로컬 변수
locals {
  oac_prefix = join("-", [
    local.resource_prefix,
    "oac"
  ])
  origin_prefix = join("-", [
    local.resource_prefix,
    "org"
  ])
}

#bucket_list 만큼 OAC 생성
resource "aws_cloudfront_origin_access_control" "b_oac" {
  for_each                          = toset(var.bucket_list)
  name                              = join("-", [local.oac_prefix, each.value, local.resource_suffix])
  description                       = "${each.value} origin access control"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

#bucket_list에 맞춰 Distribution 및 resource 생성
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = "${aws_apigatewayv2_api.surl_api.id}.execute-api.${var.region_raw[var.region]}.amazonaws.com"
    origin_id   = aws_apigatewayv2_api.surl_api.name
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  ordered_cache_behavior {
    path_pattern           = "/surl/*"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = aws_apigatewayv2_api.surl_api.name
    viewer_protocol_policy = "allow-all"
    compress               = true
    #aws managed "Managed-CachingDisabled"
    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    #aws managed "Managed-AllViewerExceptHostHeader"
    origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"

  }

  dynamic "origin" {
    for_each = toset(var.bucket_list)
    content {
      domain_name              = aws_s3_bucket.b[origin.value].bucket_regional_domain_name
      origin_access_control_id = aws_cloudfront_origin_access_control.b_oac[origin.value].id
      origin_id                = join("-", [local.origin_prefix, origin.value, local.resource_suffix])
    }
  }

  enabled             = true
  is_ipv6_enabled     = false
  comment             = "Test Distribution"
  default_root_object = "index.html"

  #기본 Behavior
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = join("-", [local.origin_prefix, var.bucket_list[0], local.resource_suffix])

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # bucket_list에 맞춰 추가 Behavior 생성
  dynamic "ordered_cache_behavior" {
    for_each = toset(var.bucket_list)
    content {
      path_pattern       = "/${ordered_cache_behavior.value}/*"
      allowed_methods    = ["GET", "HEAD", "OPTIONS"]
      cached_methods     = ["GET", "HEAD", "OPTIONS"]
      target_origin_id   = join("-", [local.origin_prefix, ordered_cache_behavior.value, local.resource_suffix])
      trusted_key_groups = contains(var.signed_url_bucket_names, ordered_cache_behavior.value) == true ? [aws_cloudfront_key_group.cf_key_group[ordered_cache_behavior.value].id] : null


      forwarded_values {
        query_string = false
        headers      = ["Origin"]

        cookies {
          forward = "none"
        }
      }
      min_ttl                = 0
      default_ttl            = 86400
      max_ttl                = 31536000
      compress               = true
      viewer_protocol_policy = "redirect-to-https"


    }
  }

  price_class = "PriceClass_200"
  # distribution 접근 제한사항(현 설정에선 지역 제한)
  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["KR"]
    }
  }

  tags = {
    Environment = "production"
    Terraform   = "true"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
