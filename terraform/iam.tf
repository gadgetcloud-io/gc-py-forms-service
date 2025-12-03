# IAM Role for Lambda Execution
resource "aws_iam_role" "lambda_execution" {
  name = "${var.project_name}-${var.environment}-lambda-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-lambda-execution"
  }
}

# Attach AWS Managed Policy for Lambda Basic Execution
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Custom Policy for DynamoDB Access
resource "aws_iam_policy" "lambda_dynamodb" {
  name        = "${var.project_name}-${var.environment}-lambda-dynamodb"
  description = "Policy for Lambda to access DynamoDB form submissions table"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem"
        ]
        Resource = [
          aws_dynamodb_table.form_submissions.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          "${aws_dynamodb_table.form_submissions.arn}/index/*"
        ]
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-lambda-dynamodb"
  }
}

# Attach DynamoDB Policy to Lambda Execution Role
resource "aws_iam_role_policy_attachment" "lambda_dynamodb" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = aws_iam_policy.lambda_dynamodb.arn
}

# Custom Policy for SES (Simple Email Service)
resource "aws_iam_policy" "lambda_ses" {
  name        = "${var.project_name}-${var.environment}-lambda-ses"
  description = "Policy for Lambda to send emails via SES"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-lambda-ses"
  }
}

# Attach SES Policy to Lambda Execution Role
resource "aws_iam_role_policy_attachment" "lambda_ses" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = aws_iam_policy.lambda_ses.arn
}

# CloudWatch Logs Policy
resource "aws_iam_policy" "lambda_cloudwatch_logs" {
  name        = "${var.project_name}-${var.environment}-lambda-cloudwatch"
  description = "Policy for Lambda to write CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:*:*"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-lambda-cloudwatch"
  }
}

# Attach CloudWatch Logs Policy
resource "aws_iam_role_policy_attachment" "lambda_cloudwatch_logs" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = aws_iam_policy.lambda_cloudwatch_logs.arn
}

# SSM Parameter Store Policy
resource "aws_iam_policy" "lambda_ssm" {
  name        = "${var.project_name}-${var.environment}-lambda-ssm"
  description = "Policy for Lambda to read SSM Parameter Store"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:*:parameter/gadgetcloud/*"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-lambda-ssm"
  }
}

# Attach SSM Policy to Lambda Execution Role
resource "aws_iam_role_policy_attachment" "lambda_ssm" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = aws_iam_policy.lambda_ssm.arn
}
