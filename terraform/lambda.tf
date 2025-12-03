# Archive Lambda function code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = var.lambda_source_dir
  output_path = "${path.module}/.terraform/lambda_function.zip"
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-forms"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-${var.environment}-forms-logs"
  }
}

# Lambda Function
resource "aws_lambda_function" "forms" {
  function_name    = "${var.project_name}-${var.environment}-forms"
  role             = aws_iam_role.lambda_execution.arn
  handler          = "handler.lambda_handler"
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  filename         = data.archive_file.lambda_zip.output_path

  environment {
    variables = {
      ENVIRONMENT            = var.environment
      LOG_LEVEL              = "INFO"
      NOTIFICATION_EMAIL     = var.notification_email
      FORM_SUBMISSIONS_TABLE = aws_dynamodb_table.form_submissions.name
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda_logs,
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.lambda_dynamodb,
    aws_iam_role_policy_attachment.lambda_ses
  ]

  tags = {
    Name = "${var.project_name}-${var.environment}-forms"
  }
}

# Lambda Permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.forms.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}
