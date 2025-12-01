terraform {
  backend "s3" {
    # Configure these in terraform init command or backend config file
    # Example:
    # terraform init -backend-config="bucket=your-bucket" \
    #   -backend-config="key=forms-service/terraform.tfstate" \
    #   -backend-config="region=ap-south-1" \
    #   -backend-config="profile=your-profile" \
    #   -backend-config="dynamodb_table=your-locks-table"
  }
}
