output "api_url" {
  value = "${aws_api_gateway_deployment.image_api.invoke_url}/${aws_api_gateway_resource.random.path_part}"
}
