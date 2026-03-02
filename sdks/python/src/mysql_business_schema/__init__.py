"""MySQL Business-to-Schema Python SDK.

A comprehensive Python client library for interacting with MySQL Business-to-Schema system.
"""

from .client import MySQLSchemaClient
from .models import (
    Database,
    Table,
    Column,
    Migration,
    Query,
    User,
    Backup,
    Alert,
    SchemaInfo,
    MigrationStatus,
    BackupType,
)
from .generators import DataGenerator, SchemaGenerator
from .migrations import MigrationManager
from .exceptions import (
    MySQLSchemaError,
    AuthenticationError,
    ConnectionError,
    ValidationError,
    NotFoundError,
)

__version__ = "1.0.0"
__author__ = "MySQL Business Schema Team"
__email__ = "admin@mysqlbusinessschema.com"

__all__ = [
    "MySQLSchemaClient",
    "Database",
    "Table",
    "Column",
    "Migration",
    "Query",
    "User",
    "Backup",
    "Alert",
    "SchemaInfo",
    "MigrationStatus",
    "BackupType",
    "DataGenerator",
    "SchemaGenerator",
    "MigrationManager",
    "MySQLSchemaError",
    "AuthenticationError",
    "ConnectionError",
    "ValidationError",
    "NotFoundError",
]


# Convenience function for quick client creation
def create_client(
    host: str = "localhost",
    port: int = 8000,
    api_key: str = None,
    username: str = None,
    password: str = None,
    timeout: int = 30,
    **kwargs
) -> MySQLSchemaClient:
    """Create a MySQL Schema client instance.

    Args:
        host: API host address
        port: API port number
        api_key: API key for authentication
        username: Username for basic auth
        password: Password for basic auth
        timeout: Request timeout in seconds
        **kwargs: Additional configuration options

    Returns:
        MySQLSchemaClient: Configured client instance

    Example:
        >>> client = create_client(username="admin", password="admin123")
        >>> databases = client.list_databases()
    """
    return MySQLSchemaClient(
        host=host,
        port=port,
        api_key=api_key,
        username=username,
        password=password,
        timeout=timeout,
        **kwargs
    )
