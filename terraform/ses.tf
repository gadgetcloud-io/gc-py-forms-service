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

# Route53 TXT record for SES domain verification
resource "aws_route53_record" "ses_verification" {
  count = var.enable_custom_domain ? 1 : 0

  zone_id = data.terraform_remote_state.base_infra.outputs.route53_zone_id
  name    = "_amazonses.${var.ses_domain}"
  type    = "TXT"
  ttl     = 600
  records = [aws_ses_domain_identity.main.verification_token]
}

# SES Domain Verification (requires DNS records to be set up)
# Commented out to avoid timeout issues - domain is already verified manually
# resource "aws_ses_domain_identity_verification" "main" {
#   domain = aws_ses_domain_identity.main.id
#
#   depends_on = [aws_ses_domain_identity.main, aws_route53_record.ses_verification]
# }

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
