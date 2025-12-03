# General Configuration
aws_region  = "ap-south-1"
aws_profile = "gc"
environment = "production"

project_name = "GadgetCloud-Forms"

# API Configuration
api_name        = "gadgetcloud-forms-api"
api_description = "GadgetCloud Forms Service HTTP API"

enable_cors         = true
cors_allow_origins  = ["https://gadgetcloud.io", "https://www.gadgetcloud.io", "https://control.gadgetcloud.io", "https://team.gadgetcloud.io", "https://rest.gadgetcloud.io", "https://fixmycar.com", "https://www.fixmycar.com", "https://repairodo.com", "https://www.repairodo.com", "https://fixmygadgets.com", "https://www.fixmygadgets.com"]
cors_allow_methods  = ["GET", "POST", "OPTIONS"]
cors_allow_headers  = ["content-type", "authorization"]

# Lambda Configuration
lambda_runtime     = "python3.11"
lambda_timeout     = 30
lambda_memory_size = 256
lambda_source_dir  = "../lambda"

# Email Configuration
notification_email = "notifications@gadgetcloud.io"
ses_domain         = "gadgetcloud.io"

# DynamoDB Configuration
dynamodb_billing_mode = "PAY_PER_REQUEST"

# Custom Domain Configuration (Optional)
enable_custom_domain = true
custom_domain_name   = "forms.gadgetcloud.io"
hosted_zone_id       = "Z05023092A1IOEM9O5L0Z"

# Backend Configuration
terraform_state_bucket         = "gadgetcloud-tf-state"
terraform_state_dynamodb_table = "gadgetcloud-terraform-locks"
