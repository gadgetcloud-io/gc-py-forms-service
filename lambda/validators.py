"""
Validation utilities for forms lambda
"""
import re
from typing import Dict, List, Any, Tuple


def validate_email(email: str) -> bool:
    """Validate email format"""
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return bool(re.match(pattern, email))


def validate_phone(phone: str) -> bool:
    """Validate phone number format"""
    pattern = r'^[+]?[0-9]{10,15}$'
    return bool(re.match(pattern, phone))


def validate_field(field_name: str, value: Any, constraints: Dict) -> Tuple[bool, str]:
    """
    Validate a single field against its constraints
    Returns: (is_valid, error_message)
    """
    if constraints.get('required') and not value:
        return False, f"{field_name} is required"

    if not value and not constraints.get('required'):
        return True, ""

    field_type = constraints.get('type', 'text')

    # Type-specific validation
    if field_type == 'email':
        if not validate_email(str(value)):
            return False, f"{field_name} must be a valid email address"

    elif field_type == 'phone':
        if not validate_phone(str(value)):
            return False, f"{field_name} must be a valid phone number"

    elif field_type == 'text':
        value_str = str(value)

        # Pattern validation
        if 'pattern' in constraints:
            if not re.match(constraints['pattern'], value_str):
                return False, f"{field_name} format is invalid"

        # Length validation
        if 'minLength' in constraints:
            if len(value_str) < constraints['minLength']:
                return False, f"{field_name} must be at least {constraints['minLength']} characters"

        if 'maxLength' in constraints:
            if len(value_str) > constraints['maxLength']:
                return False, f"{field_name} must not exceed {constraints['maxLength']} characters"

    elif field_type == 'object':
        if not isinstance(value, dict):
            return False, f"{field_name} must be an object"

    return True, ""


def validate_form_data(
    form_data: Dict,
    required_fields: List[str],
    field_constraints: Dict
) -> Tuple[bool, List[str]]:
    """
    Validate form data against requirements and constraints
    Returns: (is_valid, list_of_errors)
    """
    errors = []

    # Check required fields
    for field in required_fields:
        if field not in form_data:
            errors.append(f"Missing required field: {field}")
            continue

        # Validate field if constraints exist
        if field in field_constraints:
            is_valid, error = validate_field(field, form_data[field], field_constraints[field])
            if not is_valid:
                errors.append(error)

    # Validate non-required fields that are present
    for field, value in form_data.items():
        if field in field_constraints and field not in required_fields:
            is_valid, error = validate_field(field, value, field_constraints[field])
            if not is_valid:
                errors.append(error)

    return len(errors) == 0, errors


def validate_client(client: str, allowed_clients: List[str]) -> Tuple[bool, str]:
    """
    Validate client parameter
    Returns: (is_valid, error_message)
    """
    if not client:
        return False, "Client parameter is required"

    if client not in allowed_clients:
        return False, f"Invalid client: {client}"

    return True, ""


def validate_form_type(
    form_type: str,
    client: str,
    allowed_form_types: Dict
) -> Tuple[bool, str]:
    """
    Validate form type for a specific client
    Returns: (is_valid, error_message)
    """
    if not form_type:
        return False, "Form type is required"

    if client not in allowed_form_types:
        return False, f"No form types configured for client: {client}"

    if form_type not in allowed_form_types[client]:
        return False, f"Form type '{form_type}' not allowed for client '{client}'"

    return True, ""


def sanitize_input(value: str, max_length: int = 1000) -> str:
    """Sanitize user input to prevent XSS and injection attacks"""
    if not isinstance(value, str):
        return str(value)[:max_length]

    # Remove potentially dangerous characters
    sanitized = value.replace('<', '&lt;').replace('>', '&gt;')
    sanitized = sanitized.replace('"', '&quot;').replace("'", '&#x27;')

    return sanitized[:max_length]


def check_honeypot(form_data: Dict, honeypot_field: str) -> bool:
    """
    Check if honeypot field is present (indicates bot submission)
    Returns: True if it's a bot, False if it's legitimate
    """
    return honeypot_field in form_data and form_data[honeypot_field]


def validate_payload_size(payload: str, max_size: int) -> Tuple[bool, str]:
    """
    Validate payload size
    Returns: (is_valid, error_message)
    """
    payload_size = len(payload.encode('utf-8'))

    if payload_size > max_size:
        return False, f"Payload size ({payload_size} bytes) exceeds maximum allowed ({max_size} bytes)"

    return True, ""
