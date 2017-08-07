# ------------------------------------------------------------------------------
# Resources
# ------------------------------------------------------------------------------
variable "prefix" {
  description = "Prefix used for resource names."
}

variable "api_id" {
  description = "Gateway REST API ID."
}

variable "resource_id" {
  description = "Gateway resource ID."
}

variable "http_method" {
  description = "HTTP method to accept in the Gateway resource."
}

variable "lambda_arn" {
  description = "ARN of the lambda function to integrate with."
}

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
data "aws_region" "current" {
  current = true
}

data "aws_caller_identity" "current" {}

resource "aws_api_gateway_method" "request_method" {
  rest_api_id   = "${var.api_id}"
  resource_id   = "${var.resource_id}"
  http_method   = "${var.http_method}"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "request_integration" {
  rest_api_id = "${var.api_id}"
  resource_id = "${var.resource_id}"
  http_method = "${aws_api_gateway_method.request_method.http_method}"
  type        = "AWS"
  uri         = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${var.lambda_arn}/invocations"

  # Lambda accepts POST only.
  integration_http_method = "POST"
}

resource "aws_api_gateway_method_response" "response_method" {
  rest_api_id = "${var.api_id}"
  resource_id = "${var.resource_id}"
  http_method = "${aws_api_gateway_integration.request_integration.http_method}"
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "response_integration" {
  rest_api_id = "${var.api_id}"
  resource_id = "${var.resource_id}"
  http_method = "${aws_api_gateway_method_response.response_method.http_method}"
  status_code = "${aws_api_gateway_method_response.response_method.status_code}"

  response_templates = {
    "application/json" = ""
  }
}

resource "aws_lambda_permission" "invoke" {
  function_name = "${var.lambda_arn}"
  statement_id  = "${var.prefix}-invoke-permission"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.api_id}/*/${aws_api_gateway_method.request_method.http_method}*"
}

# ------------------------------------------------------------------------------
# Output
# ------------------------------------------------------------------------------
output "http_method" {
  value = "${aws_api_gateway_integration_response.response_integration.http_method}"
}