# lambda 로컬 변수
locals {
  lambda_prefix = join("-", [
    local.resource_prefix,
    "lambda"
  ])

  cf_keypair_list = jsonencode({
    for key, value in aws_cloudfront_key_group.cf_key_group : key => tolist(aws_cloudfront_key_group.cf_key_group[key].items)[0]
  })
}

resource "aws_lambda_function" "surl" {
  filename      = "surl.zip"
  function_name = join("-", [local.lambda_prefix, "surl", local.resource_suffix])
  role          = aws_iam_role.surl_role.arn
  handler       = "surl.handler"
  runtime       = "nodejs20.x"
  environment {
    variables = {
      domain_name    = var.domain_name
      exp_time       = var.exp_time
      key_pair_list  = local.cf_keypair_list
      secret_manager = var.secret_name
    }
  }
}

resource "aws_lambda_permission" "surl_apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.surl.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.surl_api.execution_arn}/*/*/*"
}