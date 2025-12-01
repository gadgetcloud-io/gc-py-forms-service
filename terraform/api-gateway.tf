# API Gateway HTTP API
resource "aws_apigatewayv2_api" "main" {
  name          = var.api_name
  protocol_type = "HTTP"
  description   = var.api_description

  # CORS Configuration
  dynamic "cors_configuration" {
    for_each = var.enable_cors ? [1] : []
    content {
      allow_origins = var.cors_allow_origins
      allow_methods = var.cors_allow_methods
      allow_headers = var.cors_allow_headers
      max_age       = 300
    }
  }

  tags = {
    Name = var.api_name
  }
}

# API Gateway Stage
resource "aws_apigatewayv2_stage" "main" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = var.environment
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId       = "$context.requestId"
      ip              = "$context.identity.sourceIp"
      requestTime     = "$context.requestTime"
      httpMethod      = "$context.httpMethod"
      routeKey        = "$context.routeKey"
      status          = "$context.status"
      protocol        = "$context.protocol"
      responseLength  = "$context.responseLength"
      errorMessage    = "$context.error.message"
    })
  }

  default_route_settings {
    throttling_burst_limit = 5000
    throttling_rate_limit  = 10000
  }

  tags = {
    Name = "${var.api_name}-${var.environment}"
  }
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.api_name}"
  retention_in_days = 7

  tags = {
    Name = "${var.api_name}-logs"
  }
}

# Lambda Integration
resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.forms.invoke_arn
  payload_format_version = "2.0"
}

# Health Check Route (public, no auth)
resource "aws_apigatewayv2_route" "health" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /forms/health"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# Info Route (public, no auth)
resource "aws_apigatewayv2_route" "info" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /forms/info"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# Forms Route (public, no auth required)
resource "aws_apigatewayv2_route" "forms" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /forms"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}
