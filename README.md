# GadgetCloud Forms Service

A serverless forms processing service built with AWS Lambda, API Gateway, DynamoDB, and SES. This service provides configuration-driven form validation, multi-client support, email notifications, and comprehensive security features.

## Features

- **Configuration-Driven**: All validation rules, clients, and form types managed via JSON configuration
- **Multi-Client Support**: Support for multiple clients with client-specific validation and email templates
- **Form Types**: Supports contacts, feedback, survey, and service request forms
- **Email Notifications**: Automatic email notifications with customizable templates
- **Auto-Reply**: Configurable auto-reply emails for specific form types
- **Security Features**:
  - Honeypot bot detection
  - Input sanitization (XSS protection)
  - Payload size limits
  - Rate limiting framework (ready for implementation)
- **Webhook Support**: Optional webhook integration (requires requests library layer)
- **DynamoDB Storage**: All submissions stored with metadata and indexed for querying
- **CloudWatch Logging**: Comprehensive logging for monitoring and debugging

## Architecture

```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │ HTTPS
       ▼
┌─────────────────┐
│  API Gateway    │ (/forms endpoints)
└──────┬──────────┘
       │
       ▼
┌─────────────────┐
│ Lambda Function │ (Python 3.11)
│  - handler.py   │
│  - validators.py│
│  - config.json  │
└──────┬──────────┘
       │
       ├────────────────┐
       │                │
       ▼                ▼
┌───────────────┐  ┌──────────┐
│  DynamoDB     │  │   SES    │
│ (Submissions) │  │ (Emails) │
└───────────────┘  └──────────┘
```

## API Endpoints

### Health Check
```bash
GET /forms/health
```

Response:
```json
{
  "status": "healthy",
  "version": "0.0.1-SNAPSHOT",
  "timestamp": "2025-12-01T10:00:00.000000"
}
```

### API Information
```bash
GET /forms/info
```

Response:
```json
{
  "name": "gc-py-forms",
  "version": "0.0.1-SNAPSHOT",
  "api_version": "v1",
  "supported_versions": ["v1"],
  "allowed_clients": ["noclient", "fixmycar", "repairodo", "fixmygadgets"],
  "buildTime": "2025-11-30T00:00:00Z"
}
```

### Submit Form
```bash
POST /forms
Content-Type: application/json

{
  "client": "noclient",
  "type": "contacts",
  "data": {
    "firstName": "John",
    "lastName": "Doe",
    "email": "john@example.com",
    "message": "This is a test message"
  }
}
```

Response:
```json
{
  "submissionId": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2025-12-01T10:00:00.000000",
  "client": "noclient",
  "type": "contacts",
  "status": "received",
  "message": "Form submitted successfully"
}
```

## Supported Clients

- **noclient**: Default client for general submissions
- **fixmycar**: Car repair service forms
- **repairodo**: General repair service forms
- **fixmygadgets**: Gadget repair service forms

## Supported Form Types

Each client supports different form types:

- **contacts**: Contact form (firstName, lastName, email, message)
- **feedback**: Feedback form (email, comments)
- **survey**: Survey form (email, responses object)
- **serviceRequests**: Service request form (email, firstName, lastName, serviceType, mobile, description)

## Configuration

The service is configured via `lambda/config.json`:

### Key Configuration Sections

1. **allowed_clients**: List of valid client identifiers
2. **allowed_form_types**: Form types allowed per client
3. **validation_rules**: Required fields per form type
4. **field_constraints**: Validation rules for each field
5. **email_templates**: Email subjects and auto-reply settings
6. **client_config**: Client-specific settings (notification emails, webhooks, CORS origins)
7. **rate_limiting**: Rate limiting settings
8. **security**: Security policies (honeypot, payload limits)

See `lambda/config.json` for full configuration details.

## Deployment

### Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- AWS account with permissions for Lambda, API Gateway, DynamoDB, SES, IAM, CloudWatch

### Initial Setup

1. **Clone the repository**:
   ```bash
   cd /path/to/gc-py-forms-service
   ```

2. **Configure Terraform variables**:
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

3. **Configure SES**:
   - Verify your domain in AWS SES
   - Verify notification email address
   - Move out of SES sandbox if needed for production

4. **Initialize Terraform**:
   ```bash
   terraform init \
     -backend-config="bucket=your-tf-state-bucket" \
     -backend-config="key=forms-service/terraform.tfstate" \
     -backend-config="region=ap-south-1" \
     -backend-config="profile=your-profile" \
     -backend-config="dynamodb_table=your-locks-table"
   ```

5. **Deploy the infrastructure**:
   ```bash
   terraform plan
   terraform apply
   ```

### Updating the Service

1. **Modify Lambda code** in `lambda/` directory
2. **Update configuration** in `lambda/config.json` if needed
3. **Apply changes**:
   ```bash
   cd terraform
   terraform apply
   ```

### Custom Domain Setup (Optional)

To use a custom domain (e.g., `forms.gadgetcloud.io`):

1. Set in `terraform.tfvars`:
   ```hcl
   enable_custom_domain = true
   custom_domain_name   = "forms.gadgetcloud.io"
   hosted_zone_id       = "YOUR_ROUTE53_ZONE_ID"
   ```

2. Apply:
   ```bash
   terraform apply
   ```

## Email Configuration

### Notification Emails

Configure in `lambda/config.json`:

```json
{
  "client_config": {
    "noclient": {
      "name": "GadgetCloud",
      "notification_email": "notifications@gadgetcloud.io"
    }
  }
}
```

### Auto-Reply Emails

Enable per form type:

```json
{
  "email_templates": {
    "serviceRequests": {
      "subject": "New Service Request - {client}",
      "autoReply": true,
      "autoReplySubject": "We received your service request",
      "autoReplyMessage": "Thank you! We'll get back to you within 24 hours."
    }
  }
}
```

## Security

### Honeypot Bot Detection

Add a hidden field to your form:
```html
<input type="text" name="_gotcha" style="display:none">
```

If this field is filled, the submission is treated as spam.

### Input Sanitization

All text inputs are automatically sanitized to prevent XSS attacks:
- `<` → `&lt;`
- `>` → `&gt;`
- `"` → `&quot;`
- `'` → `&#x27;`

### Rate Limiting

Framework is in place (see `check_rate_limit()` in handler.py). Implement with DynamoDB TTL for production use.

## Monitoring

### CloudWatch Logs

Logs are available in CloudWatch:
- Lambda logs: `/aws/lambda/{project-name}-{environment}-forms`
- API Gateway logs: `/aws/apigateway/{api-name}`

### View Recent Logs

```bash
aws logs tail /aws/lambda/GadgetCloud-production-forms --follow --profile gc
```

## DynamoDB Schema

### form_submissions Table

**Primary Key**:
- `submissionId` (S) - Partition key
- `timestamp` (N) - Sort key

**Attributes**:
- `timestampIso` (S) - ISO format timestamp
- `client` (S) - Client identifier
- `formType` (S) - Type of form
- `formData` (M) - Form data object
- `sourceIp` (S) - Submitter IP address
- `userAgent` (S) - User agent string
- `status` (S) - Submission status

**Global Secondary Indexes**:
- `FormTypeIndex`: Query by formType + timestamp
- `ClientIndex`: Query by client + timestamp

## Development

### Local Testing

1. **Update config.json** in `lambda/` directory
2. **Test locally** (requires AWS credentials):
   ```bash
   cd lambda
   python3 -c "
   import json
   from handler import lambda_handler
   event = json.load(open('test_event.json'))
   print(lambda_handler(event, None))
   "
   ```

### Adding New Form Types

1. Add to `allowed_form_types` for relevant clients
2. Define `validation_rules` for required fields
3. Add field constraints in `field_constraints`
4. Configure email template in `email_templates`
5. Redeploy: `terraform apply`

### Adding New Clients

1. Add client to `allowed_clients`
2. Define allowed form types in `allowed_form_types`
3. Add client configuration in `client_config`
4. Redeploy: `terraform apply`

## Troubleshooting

### Emails Not Sending

1. Verify SES domain and email identities:
   ```bash
   aws ses get-identity-verification-attributes \
     --identities gadgetcloud.io notifications@gadgetcloud.io
   ```

2. Check if in SES sandbox (can only send to verified addresses)

3. Review CloudWatch logs for SES errors

### Forms Returning 400 Errors

1. Check CloudWatch logs for validation errors
2. Verify request body matches required fields in config.json
3. Test with curl to see exact error message

### Lambda Timeout

1. Increase timeout in `terraform.tfvars`:
   ```hcl
   lambda_timeout = 60
   ```

2. Apply: `terraform apply`

## Outputs

After deployment, Terraform provides:

- `api_endpoint`: Default API endpoint URL
- `api_custom_domain_url`: Custom domain URL (if enabled)
- `lambda_function_name`: Lambda function name
- `dynamodb_table_name`: DynamoDB table name
- `ses_dkim_tokens`: DKIM tokens for DNS configuration

## Contributing

1. Make changes in a feature branch
2. Test thoroughly
3. Update documentation
4. Submit pull request

## License

Proprietary - GadgetCloud

## Support

For issues or questions:
- Email: dev@gadgetcloud.io
- GitHub Issues: [gc-py-forms-service](https://github.com/gadgetcloud-io/gc-py-forms-service)
