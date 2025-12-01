# SES Domain Identity
resource "aws_ses_domain_identity" "main" {
  domain = var.ses_domain
}

# SES Email Identity for notification email
resource "aws_ses_email_identity" "notifications" {
  email = var.notification_email
}

# SES DKIM Configuration
resource "aws_ses_domain_dkim" "main" {
  domain = aws_ses_domain_identity.main.domain
}

# SES Domain Verification (requires DNS records to be set up)
resource "aws_ses_domain_identity_verification" "main" {
  domain = aws_ses_domain_identity.main.id

  depends_on = [aws_ses_domain_identity.main]
}

# SES Configuration Set
resource "aws_ses_configuration_set" "main" {
  name = "${var.project_name}-${var.environment}-forms"
}

# CloudWatch Destination for SES events
resource "aws_ses_event_destination" "cloudwatch" {
  name                   = "cloudwatch-destination"
  configuration_set_name = aws_ses_configuration_set.main.name
  enabled                = true
  matching_types         = ["send", "bounce", "complaint", "delivery", "reject", "open", "click"]

  cloudwatch_destination {
    default_value  = "default"
    dimension_name = "ses:configuration-set"
    value_source   = "messageTag"
  }
}
