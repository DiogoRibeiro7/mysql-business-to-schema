"""
Custom exceptions for MySQL Business-to-Schema SDK
"""


class MySQLSchemaError(Exception):
    """Base exception for MySQL Schema SDK."""

    def __init__(self, message: str, code: str = None, details: dict = None):
        super().__init__(message)
        self.message = message
        self.code = code
        self.details = details or {}


class AuthenticationError(MySQLSchemaError):
    """Raised when authentication fails."""

    def __init__(self, message: str = "Authentication failed", **kwargs):
        super().__init__(message, code="AUTH_ERROR", **kwargs)


class ConnectionError(MySQLSchemaError):
    """Raised when connection to API fails."""

    def __init__(self, message: str = "Connection failed", **kwargs):
        super().__init__(message, code="CONNECTION_ERROR", **kwargs)


class ValidationError(MySQLSchemaError):
    """Raised when data validation fails."""

    def __init__(self, message: str = "Validation failed", field: str = None, **kwargs):
        details = kwargs.get("details", {})
        if field:
            details["field"] = field
        super().__init__(message, code="VALIDATION_ERROR", details=details)


class NotFoundError(MySQLSchemaError):
    """Raised when requested resource is not found."""

    def __init__(self, message: str = "Resource not found", resource: str = None, **kwargs):
        details = kwargs.get("details", {})
        if resource:
            details["resource"] = resource
        super().__init__(message, code="NOT_FOUND", details=details)


class PermissionError(MySQLSchemaError):
    """Raised when user lacks required permissions."""

    def __init__(self, message: str = "Permission denied", required_role: str = None, **kwargs):
        details = kwargs.get("details", {})
        if required_role:
            details["required_role"] = required_role
        super().__init__(message, code="PERMISSION_DENIED", details=details)


class MigrationError(MySQLSchemaError):
    """Raised when migration operation fails."""

    def __init__(self, message: str = "Migration failed", migration_id: str = None, **kwargs):
        details = kwargs.get("details", {})
        if migration_id:
            details["migration_id"] = migration_id
        super().__init__(message, code="MIGRATION_ERROR", details=details)


class QueryError(MySQLSchemaError):
    """Raised when query execution fails."""

    def __init__(self, message: str = "Query failed", query: str = None, **kwargs):
        details = kwargs.get("details", {})
        if query:
            details["query"] = query[:500]  # Limit query length in error
        super().__init__(message, code="QUERY_ERROR", details=details)


class BackupError(MySQLSchemaError):
    """Raised when backup operation fails."""

    def __init__(self, message: str = "Backup operation failed", backup_id: str = None, **kwargs):
        details = kwargs.get("details", {})
        if backup_id:
            details["backup_id"] = backup_id
        super().__init__(message, code="BACKUP_ERROR", details=details)


class TimeoutError(MySQLSchemaError):
    """Raised when operation times out."""

    def __init__(self, message: str = "Operation timed out", timeout: int = None, **kwargs):
        details = kwargs.get("details", {})
        if timeout:
            details["timeout_seconds"] = timeout
        super().__init__(message, code="TIMEOUT", details=details)


class RateLimitError(MySQLSchemaError):
    """Raised when API rate limit is exceeded."""

    def __init__(self, message: str = "Rate limit exceeded", retry_after: int = None, **kwargs):
        details = kwargs.get("details", {})
        if retry_after:
            details["retry_after_seconds"] = retry_after
        super().__init__(message, code="RATE_LIMIT", details=details)