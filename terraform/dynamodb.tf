# DynamoDB Table for Form Submissions
resource "aws_dynamodb_table" "form_submissions" {
  name         = "${var.project_name}-${var.environment}-form_submissions"
  billing_mode = var.dynamodb_billing_mode
  hash_key     = "submissionId"
  range_key    = "timestamp"

  attribute {
    name = "submissionId"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  attribute {
    name = "formType"
    type = "S"
  }

  attribute {
    name = "client"
    type = "S"
  }

  # Global Secondary Index for querying by form type
  global_secondary_index {
    name            = "FormTypeIndex"
    hash_key        = "formType"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  # Global Secondary Index for querying by client
  global_secondary_index {
    name            = "ClientIndex"
    hash_key        = "client"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  # Enable point-in-time recovery
  point_in_time_recovery {
    enabled = true
  }

  # Enable server-side encryption
  server_side_encryption {
    enabled = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-form_submissions"
  }
}
