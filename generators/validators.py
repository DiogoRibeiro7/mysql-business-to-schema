"""Data validation utilities for generators."""

import re
from datetime import datetime
from typing import Optional, Any, Dict, List
import json


def validate_email(email: str) -> bool:
    """Validate email format.

    Args:
        email: Email address to validate

    Returns:
        True if valid, False otherwise
    """
    pattern = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
    return bool(re.match(pattern, email))


def validate_phone(phone: str) -> bool:
    """Validate phone number format.

    Args:
        phone: Phone number to validate

    Returns:
        True if valid, False otherwise
    """
    # Remove common separators
    cleaned = re.sub(r"[\s\-\.\(\)]", "", phone)

    # Check if it's a valid phone number (10-15 digits, optionally starting with +)
    pattern = r"^\+?[1-9]\d{9,14}$"
    return bool(re.match(pattern, cleaned))


def validate_date(date_str: str, format: str = "%Y-%m-%d") -> bool:
    """Validate date string format.

    Args:
        date_str: Date string to validate
        format: Expected date format

    Returns:
        True if valid, False otherwise
    """
    try:
        datetime.strptime(date_str, format)
        return True
    except ValueError:
        return False


def validate_json(json_str: str) -> bool:
    """Validate JSON string.

    Args:
        json_str: JSON string to validate

    Returns:
        True if valid JSON, False otherwise
    """
    try:
        json.loads(json_str)
        return True
    except (json.JSONDecodeError, TypeError):
        return False


def validate_sql_identifier(identifier: str) -> bool:
    """Validate SQL identifier (table/column name).

    Args:
        identifier: SQL identifier to validate

    Returns:
        True if valid, False otherwise
    """
    # SQL identifiers should start with letter or underscore
    # and contain only letters, digits, and underscores
    pattern = r"^[a-zA-Z_][a-zA-Z0-9_]*$"
    return bool(re.match(pattern, identifier)) and len(identifier) <= 64


def validate_ip_address(ip: str) -> bool:
    """Validate IP address (IPv4).

    Args:
        ip: IP address to validate

    Returns:
        True if valid, False otherwise
    """
    pattern = r"^(\d{1,3}\.){3}\d{1,3}$"
    if not re.match(pattern, ip):
        return False

    # Check each octet is 0-255
    octets = ip.split(".")
    return all(0 <= int(octet) <= 255 for octet in octets)


def validate_url(url: str) -> bool:
    """Validate URL format.

    Args:
        url: URL to validate

    Returns:
        True if valid, False otherwise
    """
    pattern = r"^https?://[^\s/$.?#].[^\s]*$"
    return bool(re.match(pattern, url, re.IGNORECASE))


def validate_uuid(uuid_str: str) -> bool:
    """Validate UUID format.

    Args:
        uuid_str: UUID string to validate

    Returns:
        True if valid, False otherwise
    """
    pattern = r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"
    return bool(re.match(pattern, uuid_str, re.IGNORECASE))


def validate_credit_card(card_number: str) -> bool:
    """Validate credit card number using Luhn algorithm.

    Args:
        card_number: Credit card number to validate

    Returns:
        True if valid, False otherwise
    """
    # Remove spaces and dashes
    card_number = re.sub(r"[\s-]", "", card_number)

    # Check if it's all digits
    if not card_number.isdigit():
        return False

    # Check length (typically 13-19 digits)
    if not 13 <= len(card_number) <= 19:
        return False

    # Luhn algorithm
    def luhn_check(card_num: str) -> bool:
        """Handle luhn check."""
        digits = [int(d) for d in card_num]
        _ = 0

        # Process from right to left
        for i in range(len(digits) - 2, -1, -2):
            digits[i] *= 2
            if digits[i] > 9:
                digits[i] = digits[i] // 10 + digits[i] % 10

        return sum(digits) % 10 == 0

    return luhn_check(card_number)


def validate_postal_code(postal_code: str, country: str = "US") -> bool:
    """Validate postal code format for different countries.

    Args:
        postal_code: Postal code to validate
        country: Country code (US, CA, UK, etc.)

    Returns:
        True if valid, False otherwise
    """
    patterns = {
        "US": r"^\d{5}(-\d{4})?$",  # 12345 or 12345-6789
        "CA": r"^[A-Z]\d[A-Z]\s?\d[A-Z]\d$",  # K1A 0B1
        "UK": r"^[A-Z]{1,2}\d{1,2}[A-Z]?\s?\d[A-Z]{2}$",  # SW1A 1AA
        "DE": r"^\d{5}$",  # 12345
        "FR": r"^\d{5}$",  # 75001
        "JP": r"^\d{3}-?\d{4}$",  # 123-4567
    }

    pattern = patterns.get(country.upper())
    if not pattern:
        return False

    return bool(re.match(pattern, postal_code.upper()))


def validate_data_range(value: Any, min_val: Any = None, max_val: Any = None) -> bool:
    """Validate that a value is within a specified range.

    Args:
        value: Value to check
        min_val: Minimum allowed value
        max_val: Maximum allowed value

    Returns:
        True if within range, False otherwise
    """
    try:
        if min_val is not None and value < min_val:
            return False
        if max_val is not None and value > max_val:
            return False
        return True
    except (TypeError, ValueError):
        return False


def validate_enum(value: str, allowed_values: List[str]) -> bool:
    """Validate that a value is one of the allowed values.

    Args:
        value: Value to check
        allowed_values: List of allowed values

    Returns:
        True if valid, False otherwise
    """
    return value in allowed_values


def validate_schema(data: Dict, schema: Dict) -> tuple[bool, Optional[str]]:
    """Validate data against a schema definition.

    Args:
        data: Data to validate
        schema: Schema definition

    Returns:
        Tuple of (is_valid, error_message)
    """
    try:
        for field, rules in schema.items():
            # Check required fields
            if rules.get("required", False) and field not in data:
                return False, f"Required field '{field}' is missing"

            if field in data:
                value = data[field]

                # Check type
                expected_type = rules.get("type")
                if expected_type and not isinstance(value, expected_type):
                    return (
                        False,
                        f"Field '{field}' must be of type {expected_type.__name__}",
                    )

                # Check length
                if "min_length" in rules and len(value) < rules["min_length"]:
                    return (
                        False,
                        f"Field '{field}' must be at least {rules['min_length']} characters",
                    )

                if "max_length" in rules and len(value) > rules["max_length"]:
                    return (
                        False,
                        f"Field '{field}' must be at most {rules['max_length']} characters",
                    )

                # Check pattern
                if "pattern" in rules and not re.match(rules["pattern"], str(value)):
                    return False, f"Field '{field}' does not match required pattern"

                # Check custom validator
                if "validator" in rules:
                    validator = rules["validator"]
                    if not validator(value):
                        return False, f"Field '{field}' failed validation"

        return True, None

    except Exception as e:
        return False, f"Validation error: {str(e)}"


class DataValidator:
    """Comprehensive data validator class."""

    def __init__(self):
        """Initialize the instance."""
        self.errors = []

    def validate(self, data: Dict, rules: Dict) -> bool:
        """Validate data against a set of rules.

        Args:
            data: Data to validate
            rules: Validation rules

        Returns:
            True if all validations pass
        """
        self.errors = []

        for field, field_rules in rules.items():
            value = data.get(field)

            # Check required
            if field_rules.get("required", False) and value is None:
                self.errors.append(f"{field} is required")
                continue

            if value is not None:
                # Check each rule
                for rule_name, rule_value in field_rules.items():
                    if not self._apply_rule(field, value, rule_name, rule_value):
                        break

        return len(self.errors) == 0

    def _apply_rule(
        self, field: str, value: Any, rule_name: str, rule_value: Any
    ) -> bool:
        """Apply a single validation rule."""
        if rule_name == "type":
            if not isinstance(value, rule_value):
                self.errors.append(f"{field} must be of type {rule_value.__name__}")
                return False

        elif rule_name == "min":
            if value < rule_value:
                self.errors.append(f"{field} must be at least {rule_value}")
                return False

        elif rule_name == "max":
            if value > rule_value:
                self.errors.append(f"{field} must be at most {rule_value}")
                return False

        elif rule_name == "min_length":
            if len(value) < rule_value:
                self.errors.append(f"{field} must be at least {rule_value} characters")
                return False

        elif rule_name == "max_length":
            if len(value) > rule_value:
                self.errors.append(f"{field} must be at most {rule_value} characters")
                return False

        elif rule_name == "pattern":
            if not re.match(rule_value, str(value)):
                self.errors.append(f"{field} does not match required format")
                return False

        elif rule_name == "in":
            if value not in rule_value:
                self.errors.append(f"{field} must be one of {rule_value}")
                return False

        elif rule_name == "custom":
            if not rule_value(value):
                self.errors.append(f"{field} failed custom validation")
                return False

        return True

    def get_errors(self) -> List[str]:
        """Get list of validation errors."""
        return self.errors
