"""
Forms Lambda Function
Handles form submissions with configuration-driven validation,
rate limiting, client management, and email notifications
"""
import json
import os
import boto3
from datetime import datetime
from decimal import Decimal
import uuid
from validators import (
    validate_client, validate_form_type, validate_form_data,
    check_honeypot, validate_payload_size, sanitize_input
)

# Optional: requests library for webhooks (not available by default in Lambda)
try:
    import requests
    REQUESTS_AVAILABLE = True
except ImportError:
    REQUESTS_AVAILABLE = False
    print("Warning: requests library not available. Webhook functionality disabled.")

# AWS clients
dynamodb = boto3.resource('dynamodb')
ses_client = boto3.client('ses')
ssm_client = boto3.client('ssm')

# Environment variables
FORM_SUBMISSIONS_TABLE = os.environ.get('FORM_SUBMISSIONS_TABLE')
NOTIFICATION_EMAIL = os.environ.get('NOTIFICATION_EMAIL')
CLIENTS_PARAM_NAME = os.environ.get('CLIENTS_PARAM_NAME', '/gadgetcloud/clients')

# Get DynamoDB table
submissions_table = dynamodb.Table(FORM_SUBMISSIONS_TABLE)


def load_clients():
    """Load clients configuration from SSM Parameter Store"""
    try:
        response = ssm_client.get_parameter(Name=CLIENTS_PARAM_NAME)
        return json.loads(response['Parameter']['Value'])
    except Exception as e:
        print(f"Error loading clients from Parameter Store: {e}")
        return {}


def load_config():
    """Load base config and merge with environment-specific overrides"""
    base_dir = os.path.dirname(__file__)

    # Load base config
    with open(os.path.join(base_dir, 'config.json'), 'r') as f:
        config = json.load(f)

    # Get environment from Lambda env var (default to 'dev')
    env = os.environ.get('ENVIRONMENT', 'dev')

    # Load environment-specific overrides
    env_config_file = os.path.join(base_dir, f'config.{env}.json')
    if os.path.exists(env_config_file):
        with open(env_config_file, 'r') as f:
            env_config = json.load(f)
        config = deep_merge(config, env_config)

    # Load clients from Parameter Store
    clients = load_clients()
    if clients:
        config['clients'] = clients
        config['allowed_clients'] = list(clients.keys())

    return config


def deep_merge(base: dict, override: dict) -> dict:
    """Deep merge override into base config"""
    result = base.copy()
    for key, value in override.items():
        if key in result and isinstance(result[key], dict) and isinstance(value, dict):
            result[key] = deep_merge(result[key], value)
        else:
            result[key] = value
    return result


CONFIG = load_config()


def get_client_config(client: str) -> dict:
    """Get client configuration from centralized clients store"""
    clients = CONFIG.get('clients', {})
    return clients.get(client, clients.get('noclient', {}))


def get_allowed_form_types(client: str) -> list:
    """Get allowed form types for a client"""
    client_config = get_client_config(client)
    return client_config.get('form_types', [])


def lambda_handler(event, context):
    """
    Main Lambda handler for forms endpoint
    """
    print(f"Event: {json.dumps(event)}")

    # Parse request
    http_method = event['requestContext']['http']['method']
    path = event['requestContext']['http']['path']

    try:
        # Handle different endpoints
        if http_method == 'GET' and '/health' in path:
            return health_check()
        elif http_method == 'GET' and '/info' in path:
            return get_info()
        elif http_method == 'POST' and '/forms' in path:
            return submit_form(event)
        else:
            return response(404, {'error': 'Endpoint not found'})

    except Exception as e:
        print(f"Error: {str(e)}")
        return response(500, {'error': 'Internal server error', 'message': str(e)})


def health_check():
    """Health check endpoint"""
    return response(200, {
        'status': 'healthy',
        'version': CONFIG['version'],
        'timestamp': datetime.utcnow().isoformat()
    })


def get_info():
    """Get API information"""
    return response(200, {
        'name': CONFIG['name'],
        'version': CONFIG['version'],
        'api_version': CONFIG['api_version'],
        'supported_versions': CONFIG['supported_versions'],
        'allowed_clients': CONFIG['allowed_clients'],
        'buildTime': CONFIG['buildTime']
    })


def submit_form(event):
    """Handle form submission with comprehensive validation"""
    try:
        # Get source information
        source_ip = event['requestContext']['http']['sourceIp']
        user_agent = event['requestContext']['http'].get('userAgent', 'Unknown')
        headers = event.get('headers', {})

        # Validate payload size
        body_str = event.get('body', '{}')
        max_size = CONFIG['security']['max_payload_size']
        is_valid, error = validate_payload_size(body_str, max_size)
        if not is_valid:
            return response(413, {'error': error})

        # Parse request body
        try:
            body = json.loads(body_str)
        except json.JSONDecodeError:
            return response(400, {'error': 'Invalid JSON in request body'})

        # Extract parameters
        client = body.get('client', 'noclient')
        form_type = body.get('type', body.get('formType'))
        form_data = body.get('data', body.get('formData', {}))

        # Security check: Honeypot
        honeypot_field = CONFIG['security']['honeypot_field']
        if check_honeypot(form_data, honeypot_field):
            print(f"Bot detected from IP: {source_ip}")
            # Return success to bot but don't process
            return response(201, {
                'submissionId': str(uuid.uuid4()),
                'status': 'received',
                'message': 'Form submitted successfully'
            })

        # Validate client
        is_valid, error = validate_client(client, CONFIG['allowed_clients'])
        if not is_valid:
            return response(400, {'error': error})

        # Validate form type for client
        allowed_form_types = get_allowed_form_types(client)
        if form_type not in allowed_form_types:
            return response(400, {'error': f"Form type '{form_type}' not allowed for client '{client}'"})

        # Check rate limiting
        if CONFIG['rate_limiting']['enabled']:
            is_allowed, error = check_rate_limit(source_ip, client)
            if not is_allowed:
                return response(429, {'error': error})

        # Get validation rules for this form type
        required_fields = CONFIG['validation_rules'].get(form_type, [])
        field_constraints = CONFIG['field_constraints']

        # Validate form data
        is_valid, errors = validate_form_data(
            form_data,
            required_fields,
            field_constraints
        )
        if not is_valid:
            return response(400, {'error': 'Validation failed', 'details': errors})

        # Sanitize form data
        sanitized_data = {
            key: sanitize_input(str(value)) if isinstance(value, str) else value
            for key, value in form_data.items()
        }

        # Generate submission details
        submission_id = str(uuid.uuid4())
        timestamp = int(datetime.utcnow().timestamp())
        timestamp_iso = datetime.utcnow().isoformat()

        # Store in DynamoDB
        item = {
            'submissionId': submission_id,
            'timestamp': timestamp,
            'timestampIso': timestamp_iso,
            'client': client,
            'formType': form_type,
            'formData': sanitized_data,
            'sourceIp': source_ip,
            'userAgent': user_agent,
            'status': 'received'
        }

        submissions_table.put_item(Item=item)
        print(f"Stored form submission: {submission_id}")

        # Send email notification
        try:
            send_notification_email(
                submission_id,
                client,
                form_type,
                sanitized_data,
                timestamp_iso
            )
            print(f"Notification email sent for submission: {submission_id}")
        except Exception as email_error:
            print(f"Failed to send notification email: {str(email_error)}")

        # Send auto-reply if configured
        try:
            send_auto_reply(client, form_type, sanitized_data)
        except Exception as reply_error:
            print(f"Failed to send auto-reply: {str(reply_error)}")

        # Call webhook if configured
        try:
            call_webhook(client, submission_id, form_type, sanitized_data)
        except Exception as webhook_error:
            print(f"Failed to call webhook: {str(webhook_error)}")

        # Return success response
        result = {
            'submissionId': submission_id,
            'timestamp': timestamp_iso,
            'client': client,
            'type': form_type,
            'status': 'received',
            'message': 'Form submitted successfully'
        }

        print(f"Form submitted successfully: {submission_id}")
        return response(201, result)

    except Exception as e:
        print(f"Form submission error: {str(e)}")
        return response(500, {'error': 'Failed to submit form', 'message': str(e)})


def check_rate_limit(ip_address: str, client: str) -> tuple:
    """
    Check rate limiting using DynamoDB
    Returns: (is_allowed, error_message)
    """
    try:
        # For now, implement simple in-memory rate limiting
        # In production, use DynamoDB with TTL
        max_requests = CONFIG['rate_limiting']['max_requests_per_ip']
        # TODO: Implement proper rate limiting with DynamoDB
        return True, ""
    except Exception as e:
        print(f"Rate limit check error: {str(e)}")
        return True, ""  # Allow on error


def send_notification_email(submission_id: str, client: str, form_type: str, form_data: dict, timestamp: str):
    """Send email notification to admin"""
    template = CONFIG['email_templates'].get(form_type, CONFIG['email_templates']['contacts'])
    client_config = get_client_config(client)

    # Determine recipients
    recipients = [client_config.get('notification_email', NOTIFICATION_EMAIL)]

    # Build subject
    subject = template['subject'].replace('{client}', client_config.get('name', client))

    # Format form data
    form_data_text = "\n".join([f"{key}: {value}" for key, value in form_data.items()])
    form_data_rows = "".join([
        f"<tr><td style='padding:8px;border:1px solid #ddd;'>{key}</td>"
        f"<td style='padding:8px;border:1px solid #ddd;'>{value}</td></tr>"
        for key, value in form_data.items()
    ])

    # Email body
    client_name = client_config.get('name', client)
    body_text = f"""
New form submission received!

Client: {client_name}
Submission ID: {submission_id}
Form Type: {form_type}
Timestamp: {timestamp}

Form Data:
{form_data_text}

---
This is an automated notification from GadgetCloud Forms.
"""

    body_html = f"""
<html>
<head></head>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
  <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
    <h2 style="color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 10px;">
      New Form Submission Received
    </h2>

    <div style="background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin: 20px 0;">
      <p><strong>Client:</strong> {client_name}</p>
      <p><strong>Submission ID:</strong> {submission_id}</p>
      <p><strong>Form Type:</strong> {form_type}</p>
      <p><strong>Timestamp:</strong> {timestamp}</p>
    </div>

    <h3 style="color: #2c3e50;">Form Data:</h3>
    <table style="width: 100%; border-collapse: collapse; margin: 20px 0;">
      <thead>
        <tr style="background-color: #3498db; color: white;">
          <th style="padding: 10px; text-align: left; border: 1px solid #ddd;">Field</th>
          <th style="padding: 10px; text-align: left; border: 1px solid #ddd;">Value</th>
        </tr>
      </thead>
      <tbody>
        {form_data_rows}
      </tbody>
    </table>

    <hr style="border: none; border-top: 1px solid #ddd; margin: 30px 0;">
    <p style="color: #7f8c8d; font-size: 12px;">
      This is an automated notification from GadgetCloud Forms.
    </p>
  </div>
</body>
</html>
"""

    # Send email
    ses_client.send_email(
        Source=NOTIFICATION_EMAIL,
        Destination={'ToAddresses': recipients},
        Message={
            'Subject': {'Data': subject, 'Charset': 'UTF-8'},
            'Body': {
                'Text': {'Data': body_text, 'Charset': 'UTF-8'},
                'Html': {'Data': body_html, 'Charset': 'UTF-8'}
            }
        }
    )


def send_auto_reply(client: str, form_type: str, form_data: dict):
    """Send auto-reply to user if configured"""
    template = CONFIG['email_templates'].get(form_type)
    if not template or not template.get('autoReply'):
        return

    # Get user email
    user_email = form_data.get('email')
    if not user_email:
        return

    client_config = get_client_config(client)
    client_name = client_config.get('name', client)

    subject = template.get('autoReplySubject', 'Thank you for your submission')
    message = template.get('autoReplyMessage', 'We have received your submission and will get back to you soon.')

    body_html = f"""
<html>
<head></head>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
  <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
    <h2 style="color: #2c3e50;">{client_name}</h2>
    <p>{message}</p>

    <div style="background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin: 20px 0;">
      <p><strong>Your submission details:</strong></p>
      <p>Form Type: {form_type}</p>
      <p>Submitted: {datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')} UTC</p>
    </div>

    <hr style="border: none; border-top: 1px solid #ddd; margin: 30px 0;">
    <p style="color: #7f8c8d; font-size: 12px;">
      This is an automated message. Please do not reply to this email.
    </p>
  </div>
</body>
</html>
"""

    ses_client.send_email(
        Source=NOTIFICATION_EMAIL,
        Destination={'ToAddresses': [user_email]},
        Message={
            'Subject': {'Data': subject, 'Charset': 'UTF-8'},
            'Body': {'Html': {'Data': body_html, 'Charset': 'UTF-8'}}
        }
    )


def call_webhook(client: str, submission_id: str, form_type: str, form_data: dict):
    """Call webhook if configured for client"""
    if not REQUESTS_AVAILABLE:
        print("Webhook not called: requests library not available")
        return

    client_config = get_client_config(client)
    webhook_url = client_config.get('webhookUrl')
    if not webhook_url:
        return
    payload = {
        'submissionId': submission_id,
        'client': client,
        'formType': form_type,
        'data': form_data,
        'timestamp': datetime.utcnow().isoformat()
    }

    response = requests.post(
        webhook_url,
        json=payload,
        headers={'Content-Type': 'application/json'},
        timeout=10
    )

    print(f"Webhook called: {webhook_url}, Status: {response.status_code}")


def response(status_code: int, body: dict):
    """Helper function to create API Gateway response"""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'X-API-Version': CONFIG['api_version']
        },
        'body': json.dumps(body)
    }
