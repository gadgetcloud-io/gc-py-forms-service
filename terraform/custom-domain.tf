# API Gateway Custom Domain (optional) - uses existing wildcard certificate
resource "aws_apigatewayv2_domain_name" "api" {
  count       = var.enable_custom_domain ? 1 : 0
  domain_name = var.custom_domain_name

  domain_name_configuration {
    certificate_arn = data.terraform_remote_state.base_infra.outputs.api_wildcard_certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

# API Gateway Domain Mapping (optional)
resource "aws_apigatewayv2_api_mapping" "api" {
  count       = var.enable_custom_domain ? 1 : 0
  api_id      = aws_apigatewayv2_api.main.id
  domain_name = aws_apigatewayv2_domain_name.api[0].id
  stage       = aws_apigatewayv2_stage.main.id
}

# Route53 A Record for Custom Domain (optional)
resource "aws_route53_record" "api" {
  count   = var.enable_custom_domain ? 1 : 0
  zone_id = var.hosted_zone_id
  name    = var.custom_domain_name
  type    = "A"

  alias {
    name                   = aws_apigatewayv2_domain_name.api[0].domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.api[0].domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}

# Route53 AAAA Record for Custom Domain (IPv6) (optional)
resource "aws_route53_record" "api_ipv6" {
  count   = var.enable_custom_domain ? 1 : 0
  zone_id = var.hosted_zone_id
  name    = var.custom_domain_name
  type    = "AAAA"

  alias {
    name                   = aws_apigatewayv2_domain_name.api[0].domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.api[0].domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}
