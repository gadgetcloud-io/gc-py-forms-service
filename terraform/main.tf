terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Service     = "Forms"
    }
  }
}

# Data source to access base infrastructure outputs (for wildcard certificate)
data "terraform_remote_state" "base_infra" {
  backend = "s3"

  config = {
    bucket  = var.terraform_state_bucket
    key     = "infrastructure/terraform.tfstate"
    region  = var.aws_region
    profile = var.aws_profile
  }
}
