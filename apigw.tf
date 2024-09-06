# api gateway 로컬 변수
locals {
  api_prefix = join("-", [
    local.resource_prefix,
    "api"
  ])
}

# signed url api gateway
resource "aws_apigatewayv2_api" "surl_api" {
  name          = join("-", [local.api_prefix, "surl", local.resource_suffix])
  protocol_type = "HTTP"
}



resource "aws_apigatewayv2_integration" "surl_root" {
  api_id           = aws_apigatewayv2_api.surl_api.id
  integration_type = "AWS_PROXY"

  connection_type        = "INTERNET"
  description            = "Signedurl Generate"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.surl.invoke_arn
  passthrough_behavior   = "WHEN_NO_MATCH"
  payload_format_version = "2.0"
}
resource "aws_apigatewayv2_integration" "surl_lambda_integration" {
  api_id           = aws_apigatewayv2_api.surl_api.id
  integration_type = "AWS_PROXY"

  connection_type        = "INTERNET"
  description            = "Signedurl Generate"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.surl.invoke_arn
  passthrough_behavior   = "WHEN_NO_MATCH"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "surl" {
  api_id    = aws_apigatewayv2_api.surl_api.id
  route_key = "ANY /{proxy+}"

  target = "integrations/${aws_apigatewayv2_integration.surl_lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "surl_root" {
  api_id    = aws_apigatewayv2_api.surl_api.id
  route_key = "ANY /"

  target = "integrations/${aws_apigatewayv2_integration.surl_root.id}"
}

resource "aws_apigatewayv2_stage" "surl_stage" {
  api_id      = aws_apigatewayv2_api.surl_api.id
  name        = "surl"
  auto_deploy = true
}

resource "aws_apigatewayv2_deployment" "surl" {
  api_id      = aws_apigatewayv2_route.surl.api_id
  description = "surl deployment"

  lifecycle {
    create_before_destroy = true
  }
}