# API Gateway Outputs
output "api_id" {
  description = "The ID of the API Gateway"
  value       = aws_apigatewayv2_api.main.id
}

output "api_endpoint" {
  description = "The default endpoint URL for the API Gateway"
  value       = "${aws_apigatewayv2_api.main.api_endpoint}/${var.environment}"
}

output "api_execution_arn" {
  description = "The execution ARN of the API Gateway"
  value       = aws_apigatewayv2_api.main.execution_arn
}

# Custom Domain Outputs (if enabled)
output "api_custom_domain_name" {
  description = "The custom domain name for the API"
  value       = var.enable_custom_domain ? aws_apigatewayv2_domain_name.api[0].domain_name : null
}

output "api_custom_domain_url" {
  description = "The custom domain URL for the API"
  value       = var.enable_custom_domain ? "https://${var.custom_domain_name}" : null
}

output "api_custom_domain_target" {
  description = "The target domain name for the custom domain"
  value       = var.enable_custom_domain ? aws_apigatewayv2_domain_name.api[0].domain_name_configuration[0].target_domain_name : null
}

output "api_certificate_arn" {
  description = "The ARN of the ACM wildcard certificate used for the custom domain (from base infrastructure)"
  value       = var.enable_custom_domain ? data.terraform_remote_state.base_infra.outputs.api_wildcard_certificate_arn : null
}

# Lambda Outputs
output "lambda_function_name" {
  description = "The name of the Lambda function"
  value       = aws_lambda_function.forms.function_name
}

output "lambda_function_arn" {
  description = "The ARN of the Lambda function"
  value       = aws_lambda_function.forms.arn
}

output "lambda_function_invoke_arn" {
  description = "The invoke ARN of the Lambda function"
  value       = aws_lambda_function.forms.invoke_arn
}

# DynamoDB Outputs
output "dynamodb_table_name" {
  description = "The name of the DynamoDB table for form submissions"
  value       = aws_dynamodb_table.form_submissions.name
}

output "dynamodb_table_arn" {
  description = "The ARN of the DynamoDB table for form submissions"
  value       = aws_dynamodb_table.form_submissions.arn
}

# IAM Outputs
output "lambda_execution_role_arn" {
  description = "The ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_execution.arn
}

output "lambda_execution_role_name" {
  description = "The name of the Lambda execution role"
  value       = aws_iam_role.lambda_execution.name
}

# SES Outputs
output "ses_domain_identity" {
  description = "The SES domain identity"
  value       = aws_ses_domain_identity.main.domain
}

output "ses_domain_verification_token" {
  description = "The SES domain verification token"
  value       = aws_ses_domain_identity.main.verification_token
}

output "ses_dkim_tokens" {
  description = "The DKIM tokens for SES domain"
  value       = aws_ses_domain_dkim.main.dkim_tokens
}

# General Outputs
output "aws_region" {
  description = "The AWS region"
  value       = var.aws_region
}

output "environment" {
  description = "The environment name"
  value       = var.environment
}

output "project_name" {
  description = "The project name"
  value       = var.project_name
}
