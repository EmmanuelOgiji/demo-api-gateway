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
  stage_name  = "prod"
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

resource "aws_lambda_permission" "allow_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.random_image.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.image_api.execution_arn}/*/*"
}
