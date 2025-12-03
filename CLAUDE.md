# GadgetCloud Forms Service

Serverless forms processing service built with AWS Lambda, API Gateway, DynamoDB, and SES. Provides configuration-driven form validation, multi-client support, and email notifications.

## Project Overview

- **Name**: gc-py-forms-service
- **Type**: Serverless (AWS Lambda + API Gateway)
- **Version**: 0.0.1-SNAPSHOT
- **Clients**: noclient, fixmycar, repairodo, fixmygadgets
- **Form Types**: contacts, feedback, survey, serviceRequests

## Code Style

- Indentation: 2 spaces (no tabs)
- Config over code - prefer configuration files over hardcoded values
- Clear organization of folders - keep related files together

## Git Conventions

- Do not add *.tfvars to .gitignore (tfvars files are committed)
- Keep .gitignore minimal and intentional

## Project Structure

```
lambda/
  handler.py        # Main Lambda handler
  validators.py     # Form validation logic
  config.json       # Base configuration (clients, forms, validation rules)
  config.dev.json   # Development environment overrides
  config.prod.json  # Production environment overrides

terraform/
  main.tf           # Provider configuration
  backend.tf        # S3 backend for state
  lambda.tf         # Lambda function
  api-gateway.tf    # API Gateway
  dynamodb.tf       # DynamoDB table
  ses.tf            # SES email configuration
  iam.tf            # IAM roles and policies
  custom-domain.tf  # Custom domain setup
  variables.tf      # Input variables
  outputs.tf        # Output values
```

## AWS Context

- Region: ap-south-1
- Runtime: python3.11
- Services: Lambda, API Gateway, DynamoDB, SES, CloudWatch

## API Endpoints

- `GET /forms/health` - Health check
- `GET /forms/info` - API information
- `POST /forms` - Submit form

## Terraform

- Use variables and tfvars for configuration
- Keep resources organized by purpose
- Backend: S3 with DynamoDB locking

## Configuration

Base config + environment overrides pattern:

- `config.json` - Base configuration (shared across all environments)
- `config.dev.json` - Development overrides (relaxed security, debug logging)
- `config.prod.json` - Production overrides (strict security, rate limiting)

Environment is set via `ENVIRONMENT` Lambda env var (Terraform `var.environment`).

Base config sections:
- allowed_clients, allowed_form_types
- validation_rules, field_constraints
- email_templates, client_config
- security settings (honeypot, payload limits)

## Commands

```bash
# Deploy
cd terraform && terraform apply

# View logs
aws logs tail /aws/lambda/GadgetCloud-production-forms --follow --profile gc
```
