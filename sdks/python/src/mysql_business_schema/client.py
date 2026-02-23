"""
Main client for MySQL Business-to-Schema SDK
"""

import json
import logging
from typing import List, Dict, Any, Optional, Union
from urllib.parse import urljoin

import requests
from tenacity import retry, stop_after_attempt, wait_exponential

from .models import (
    Database,
    Table,
    Migration,
    Query,
    QueryResult,
    User,
    Backup,
    Alert,
    SchemaInfo,
    SystemStatus,
)
from .exceptions import (
    MySQLSchemaError,
    AuthenticationError,
    ConnectionError,
    ValidationError,
    NotFoundError,
)
from .generators import DataGenerator, SchemaGenerator
from .migrations import MigrationManager
from .websocket import WebSocketClient

logger = logging.getLogger(__name__)


class MySQLSchemaClient:
    """
    Main client for interacting with MySQL Business-to-Schema API.

    This client provides methods for:
    - Schema management (databases, tables, columns)
    - Migration management
    - Query execution and analysis
    - User management
    - Backup operations
    - Monitoring and alerts
    - Data generation
    """

    def __init__(
        self,
        host: str = "localhost",
        port: int = 8000,
        api_key: Optional[str] = None,
        username: Optional[str] = None,
        password: Optional[str] = None,
        timeout: int = 30,
        verify_ssl: bool = True,
        max_retries: int = 3,
        **kwargs
    ):
        """
        Initialize MySQL Schema client.

        Args:
            host: API host address
            port: API port number
            api_key: API key for authentication
            username: Username for basic auth
            password: Password for basic auth
            timeout: Request timeout in seconds
            verify_ssl: Verify SSL certificates
            max_retries: Maximum number of retry attempts
        """
        self.base_url = f"http://{host}:{port}/api"
        self.timeout = timeout
        self.verify_ssl = verify_ssl
        self.max_retries = max_retries

        # Setup session
        self.session = requests.Session()
        self.session.verify = verify_ssl

        # Authentication
        self.api_key = api_key
        self.username = username
        self.password = password
        self.token = None

        # Initialize sub-clients
        self.data_generator = None
        self.schema_generator = None
        self.migration_manager = None
        self.websocket = None

        # Authenticate if credentials provided
        if username and password:
            self.authenticate(username, password)
        elif api_key:
            self.session.headers["Authorization"] = f"Bearer {api_key}"

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=4, max=10)
    )
    def _request(
        self,
        method: str,
        endpoint: str,
        params: Optional[Dict] = None,
        json_data: Optional[Dict] = None,
        **kwargs
    ) -> Dict[str, Any]:
        """
        Make HTTP request to API.

        Args:
            method: HTTP method
            endpoint: API endpoint path
            params: Query parameters
            json_data: JSON request body
            **kwargs: Additional request arguments

        Returns:
            Response data as dictionary

        Raises:
            MySQLSchemaError: On API errors
        """
        url = urljoin(self.base_url, endpoint)

        try:
            response = self.session.request(
                method=method,
                url=url,
                params=params,
                json=json_data,
                timeout=self.timeout,
                **kwargs
            )

            response.raise_for_status()

            if response.content:
                return response.json()
            return {}

        except requests.exceptions.HTTPError as e:
            if e.response.status_code == 401:
                raise AuthenticationError("Authentication failed")
            elif e.response.status_code == 404:
                raise NotFoundError(f"Resource not found: {endpoint}")
            elif e.response.status_code == 400:
                raise ValidationError(f"Validation error: {e.response.text}")
            else:
                raise MySQLSchemaError(f"API error: {e.response.text}")
        except requests.exceptions.ConnectionError as e:
            raise ConnectionError(f"Connection failed: {str(e)}")
        except Exception as e:
            raise MySQLSchemaError(f"Request failed: {str(e)}")

    def authenticate(self, username: str, password: str) -> str:
        """
        Authenticate with username and password.

        Args:
            username: Username
            password: Password

        Returns:
            Authentication token

        Raises:
            AuthenticationError: On authentication failure
        """
        response = self._request(
            "POST",
            "/auth/login",
            json_data={"username": username, "password": password}
        )

        self.token = response.get("access_token")
        if not self.token:
            raise AuthenticationError("Failed to get authentication token")

        self.session.headers["Authorization"] = f"Bearer {self.token}"
        logger.info(f"Successfully authenticated as {username}")
        return self.token

    # ============================================
    # Schema Management
    # ============================================

    def list_databases(self) -> List[Database]:
        """
        List all databases.

        Returns:
            List of Database objects
        """
        data = self._request("GET", "/schemas/databases")
        return [Database(**db) for db in data]

    def get_database(self, name: str) -> Database:
        """
        Get database details.

        Args:
            name: Database name

        Returns:
            Database object

        Raises:
            NotFoundError: If database not found
        """
        data = self._request("GET", f"/schemas/databases/{name}")
        return Database(**data)

    def create_database(
        self,
        name: str,
        charset: str = "utf8mb4",
        collation: str = "utf8mb4_unicode_ci"
    ) -> Database:
        """
        Create a new database.

        Args:
            name: Database name
            charset: Character set
            collation: Collation

        Returns:
            Created Database object
        """
        data = self._request(
            "POST",
            "/schemas/databases",
            json_data={
                "name": name,
                "charset": charset,
                "collation": collation
            }
        )
        return Database(**data)

    def delete_database(self, name: str) -> bool:
        """
        Delete a database.

        Args:
            name: Database name

        Returns:
            True if successful
        """
        self._request("DELETE", f"/schemas/databases/{name}")
        return True

    def list_tables(self, database: str) -> List[Table]:
        """
        List all tables in a database.

        Args:
            database: Database name

        Returns:
            List of Table objects
        """
        data = self._request("GET", f"/schemas/databases/{database}/tables")
        return [Table(**table) for table in data]

    def get_table(self, database: str, table: str) -> Table:
        """
        Get table details.

        Args:
            database: Database name
            table: Table name

        Returns:
            Table object
        """
        data = self._request("GET", f"/schemas/databases/{database}/tables/{table}")
        return Table(**data)

    def create_table(self, database: str, table_definition: Dict) -> Table:
        """
        Create a new table.

        Args:
            database: Database name
            table_definition: Table definition dictionary

        Returns:
            Created Table object
        """
        data = self._request(
            "POST",
            f"/schemas/databases/{database}/tables",
            json_data=table_definition
        )
        return Table(**data)

    # ============================================
    # Migration Management
    # ============================================

    def list_migrations(self, status: Optional[str] = None) -> List[Migration]:
        """
        List database migrations.

        Args:
            status: Filter by status (pending, completed, failed)

        Returns:
            List of Migration objects
        """
        params = {"status": status} if status else None
        data = self._request("GET", "/migrations", params=params)
        return [Migration(**m) for m in data]

    def create_migration(
        self,
        description: str,
        up_script: str,
        down_script: Optional[str] = None
    ) -> Migration:
        """
        Create a new migration.

        Args:
            description: Migration description
            up_script: SQL script for upgrade
            down_script: SQL script for rollback

        Returns:
            Created Migration object
        """
        data = self._request(
            "POST",
            "/migrations/create",
            json_data={
                "description": description,
                "up_script": up_script,
                "down_script": down_script
            }
        )
        return Migration(**data)

    def apply_migration(
        self,
        target_version: Optional[str] = None,
        dry_run: bool = False
    ) -> Migration:
        """
        Apply migrations.

        Args:
            target_version: Target migration version
            dry_run: Perform dry run without applying

        Returns:
            Migration result
        """
        data = self._request(
            "POST",
            "/migrations/apply",
            json_data={
                "target_version": target_version,
                "dry_run": dry_run
            }
        )
        return Migration(**data)

    def rollback_migration(
        self,
        target_version: Optional[str] = None,
        steps: int = 1
    ) -> Migration:
        """
        Rollback migrations.

        Args:
            target_version: Target version to rollback to
            steps: Number of migrations to rollback

        Returns:
            Migration result
        """
        data = self._request(
            "POST",
            "/migrations/rollback",
            json_data={
                "target_version": target_version,
                "steps": steps
            }
        )
        return Migration(**data)

    # ============================================
    # Query Execution
    # ============================================

    def execute_query(
        self,
        query: str,
        database: str,
        limit: Optional[int] = None
    ) -> QueryResult:
        """
        Execute a SQL query.

        Args:
            query: SQL query string
            database: Database name
            limit: Result limit

        Returns:
            QueryResult object
        """
        data = self._request(
            "POST",
            "/query/execute",
            json_data={
                "query": query,
                "database": database,
                "limit": limit
            }
        )
        return QueryResult(**data)

    def explain_query(self, query: str, database: str) -> Dict[str, Any]:
        """
        Explain a SQL query execution plan.

        Args:
            query: SQL query string
            database: Database name

        Returns:
            Query execution plan
        """
        return self._request(
            "POST",
            "/query/explain",
            json_data={
                "query": query,
                "database": database
            }
        )

    def optimize_query(self, query: str, database: str) -> Dict[str, Any]:
        """
        Get query optimization suggestions.

        Args:
            query: SQL query string
            database: Database name

        Returns:
            Optimization suggestions
        """
        return self._request(
            "POST",
            "/query/optimize",
            json_data={
                "query": query,
                "database": database
            }
        )

    # ============================================
    # User Management
    # ============================================

    def list_users(self) -> List[User]:
        """
        List all users.

        Returns:
            List of User objects
        """
        data = self._request("GET", "/users")
        return [User(**user) for user in data]

    def create_user(
        self,
        username: str,
        email: str,
        password: str,
        role: str = "viewer"
    ) -> User:
        """
        Create a new user.

        Args:
            username: Username
            email: Email address
            password: Password
            role: User role (admin, developer, analyst, viewer)

        Returns:
            Created User object
        """
        data = self._request(
            "POST",
            "/users",
            json_data={
                "username": username,
                "email": email,
                "password": password,
                "role": role
            }
        )
        return User(**data)

    def delete_user(self, username: str) -> bool:
        """
        Delete a user.

        Args:
            username: Username

        Returns:
            True if successful
        """
        self._request("DELETE", f"/users/{username}")
        return True

    # ============================================
    # Backup Management
    # ============================================

    def list_backups(self) -> List[Backup]:
        """
        List all backups.

        Returns:
            List of Backup objects
        """
        data = self._request("GET", "/backups")
        return [Backup(**backup) for backup in data]

    def create_backup(
        self,
        database: str,
        description: Optional[str] = None,
        compression: bool = True
    ) -> Backup:
        """
        Create a database backup.

        Args:
            database: Database name
            description: Backup description
            compression: Enable compression

        Returns:
            Created Backup object
        """
        data = self._request(
            "POST",
            "/backups/create",
            json_data={
                "database": database,
                "description": description,
                "compression": compression
            }
        )
        return Backup(**data)

    def restore_backup(
        self,
        backup_id: str,
        target_database: str,
        validate_checksum: bool = True
    ) -> Dict[str, Any]:
        """
        Restore from backup.

        Args:
            backup_id: Backup ID
            target_database: Target database name
            validate_checksum: Validate backup checksum

        Returns:
            Restore result
        """
        return self._request(
            "POST",
            "/backups/restore",
            json_data={
                "backup_id": backup_id,
                "target_database": target_database,
                "validate_checksum": validate_checksum
            }
        )

    # ============================================
    # Monitoring
    # ============================================

    def get_system_status(self) -> SystemStatus:
        """
        Get system status and metrics.

        Returns:
            SystemStatus object
        """
        data = self._request("GET", "/monitoring/status")
        return SystemStatus(**data)

    def get_metrics(self, timeframe: str = "1h") -> Dict[str, Any]:
        """
        Get performance metrics.

        Args:
            timeframe: Time frame (5m, 15m, 1h, 6h, 24h)

        Returns:
            Performance metrics
        """
        return self._request(
            "GET",
            f"/monitoring/performance?timeframe={timeframe}"
        )

    def get_slow_queries(self, limit: int = 10) -> List[Query]:
        """
        Get slow queries.

        Args:
            limit: Number of queries to return

        Returns:
            List of slow Query objects
        """
        data = self._request("GET", f"/monitoring/slow-queries?limit={limit}")
        return [Query(**q) for q in data]

    # ============================================
    # Data Generation
    # ============================================

    def get_data_generator(self) -> DataGenerator:
        """
        Get data generator instance.

        Returns:
            DataGenerator object
        """
        if not self.data_generator:
            self.data_generator = DataGenerator(self)
        return self.data_generator

    def generate_data(
        self,
        schema_name: str,
        rows: int = 1000,
        format: str = "sql"
    ) -> str:
        """
        Generate test data for a schema.

        Args:
            schema_name: Schema/example name
            rows: Number of rows to generate
            format: Output format (sql, csv, json)

        Returns:
            Generated data
        """
        generator = self.get_data_generator()
        return generator.generate(schema_name, rows, format)

    # ============================================
    # WebSocket Connection
    # ============================================

    def connect_websocket(self, auto_reconnect: bool = True) -> WebSocketClient:
        """
        Connect to WebSocket for real-time updates.

        Args:
            auto_reconnect: Enable auto-reconnection

        Returns:
            WebSocketClient instance
        """
        if not self.websocket:
            self.websocket = WebSocketClient(
                host=self.base_url.replace("http", "ws").replace("/api", ""),
                token=self.token,
                auto_reconnect=auto_reconnect
            )
            self.websocket.connect()
        return self.websocket

    def close(self):
        """Close all connections."""
        if self.websocket:
            self.websocket.close()
        self.session.close()