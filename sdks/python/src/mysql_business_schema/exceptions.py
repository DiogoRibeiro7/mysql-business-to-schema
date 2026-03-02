"""Custom exceptions for MySQL Business-to-Schema SDK."""


class MySQLSchemaError(Exception):
    """Base exception for MySQL Schema SDK."""

    code = None
    default_message = "MySQL schema error"

    def __init__(self, *args):
        """Initialize the instance."""
        if not args:
            args = (self.default_message,)
        super().__init__(*args)
        self.message = args[0]
        self.details = args[1] if len(args) > 1 and isinstance(args[1], dict) else {}


class AuthenticationError(MySQLSchemaError):
    """Raised when authentication fails."""

    code = "AUTH_ERROR"
    default_message = "Authentication failed"


class ConnectionError(MySQLSchemaError):
    """Raised when connection to API fails."""

    code = "CONNECTION_ERROR"
    default_message = "Connection failed"


class ValidationError(MySQLSchemaError):
    """Raised when data validation fails."""

    code = "VALIDATION_ERROR"
    default_message = "Validation failed"


class NotFoundError(MySQLSchemaError):
    """Raised when requested resource is not found."""

    code = "NOT_FOUND"
    default_message = "Resource not found"


class PermissionError(MySQLSchemaError):
    """Raised when user lacks required permissions."""

    code = "PERMISSION_DENIED"
    default_message = "Permission denied"


class MigrationError(MySQLSchemaError):
    """Raised when migration operation fails."""

    code = "MIGRATION_ERROR"
    default_message = "Migration failed"


class QueryError(MySQLSchemaError):
    """Raised when query execution fails."""

    code = "QUERY_ERROR"
    default_message = "Query failed"


class BackupError(MySQLSchemaError):
    """Raised when backup operation fails."""

    code = "BACKUP_ERROR"
    default_message = "Backup operation failed"


class TimeoutError(MySQLSchemaError):
    """Raised when operation times out."""

    code = "TIMEOUT"
    default_message = "Operation timed out"


class RateLimitError(MySQLSchemaError):
    """Raised when API rate limit is exceeded."""

    code = "RATE_LIMIT"
    default_message = "Rate limit exceeded"
