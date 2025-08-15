resource "aws_api_gateway_rest_api" "image_api" {
  name = "${var.name}-image-api"

  binary_media_types = ["image/jpeg", "image/png", "image/jpg"]
}

resource "aws_api_gateway_resource" "random" {
  rest_api_id = aws_api_gateway_rest_api.image_api.id
  parent_id   = aws_api_gateway_rest_api.image_api.root_resource_id
  path_part   = "random"
}

resource "aws_api_gateway_method" "get_image" {
  rest_api_id   = aws_api_gateway_rest_api.image_api.id
  resource_id   = aws_api_gateway_resource.random.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id             = aws_api_gateway_rest_api.image_api.id
  resource_id             = aws_api_gateway_resource.random.id
  http_method             = aws_api_gateway_method.get_image.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.random_image.invoke_arn
}

resource "aws_api_gateway_deployment" "image_api" {

  rest_api_id = aws_api_gateway_rest_api.image_api.id
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.random.id,
      aws_api_gateway_method.get_image.id,
      data.archive_file.lambda_zip.output_base64sha256,
      aws_api_gateway_integration.lambda
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "stage" {
  deployment_id = aws_api_gateway_deployment.image_api.id
  rest_api_id   = aws_api_gateway_rest_api.image_api.id
  stage_name    = "prod"
}

resource "aws_lambda_permission" "allow_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.random_image.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.image_api.execution_arn}/*/*"
}

locals {
  zone_domain = "epo.com"
  domain_name = "${var.domain_prefix}.${local.zone_domain}"

}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"

  domain_name = local.zone_domain
  subject_alternative_names = [
    "*.${local.zone_domain}",
  ]

  validation_method      = "DNS"
  create_route53_records = true
  zone_id                = aws_route53_zone.parent_zone.id
}

resource "aws_route53_zone" "parent_zone" {
  name = "${local.zone_domain}."
}

resource "aws_api_gateway_domain_name" "domain" {
  regional_certificate_arn = module.acm.acm_certificate_arn
  domain_name              = local.domain_name

  endpoint_configuration {
    types = ["REGIONAL"]
  }
  security_policy = "TLS_1_2"
}

resource "aws_route53_record" "domain" {
  name    = aws_api_gateway_domain_name.domain.domain_name
  type    = "A"
  zone_id = aws_route53_zone.parent_zone.id

  alias {
    evaluate_target_health = true
    name                   = aws_api_gateway_domain_name.domain.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.domain.regional_zone_id
  }
}

resource "aws_api_gateway_base_path_mapping" "domain" {
  api_id      = aws_api_gateway_rest_api.image_api.id
  domain_name = aws_api_gateway_domain_name.domain.domain_name
  stage_name  = aws_api_gateway_stage.stage.stage_name
}
