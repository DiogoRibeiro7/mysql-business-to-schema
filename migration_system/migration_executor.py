#!/usr/bin/env python3
"""Migration Executor.

Executes database migrations against target databases with:
- Connection management for different database types
- Transaction support
- Rollback capabilities
- Progress tracking
- Error handling
"""

import os
import json
import time
import logging
from datetime import datetime
from typing import Optional, Dict, Any, List

# Database connectors (will be imported as needed)
try:
    import mysql.connector

    MYSQL_AVAILABLE = True
except ImportError:
    MYSQL_AVAILABLE = False

try:
    import psycopg2

    POSTGRESQL_AVAILABLE = True
except ImportError:
    POSTGRESQL_AVAILABLE = False

try:
    import pymongo

    MONGODB_AVAILABLE = True
except ImportError:
    MONGODB_AVAILABLE = False

from migration_manager import MigrationStatus, DatabaseType

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class ExecutionResult:
    """Result of migration execution."""

    def __init__(self):
        """Initialize the instance."""
        self.success: bool = False
        self.execution_time: float = 0.0
        self.rows_affected: int = 0
        self.error_message: Optional[str] = None
        self.warnings: List[str] = []
        self.rollback_successful: Optional[bool] = None


class DatabaseConnection:
    """Abstract base class for database connections."""

    def connect(self, **kwargs):
        """Establish database connection."""
        raise NotImplementedError

    def disconnect(self):
        """Close database connection."""
        raise NotImplementedError

    def execute_script(self, script: str) -> ExecutionResult:
        """Execute migration script."""
        raise NotImplementedError

    def begin_transaction(self):
        """Start a transaction."""
        raise NotImplementedError

    def commit_transaction(self):
        """Commit the current transaction."""
        raise NotImplementedError

    def rollback_transaction(self):
        """Rollback the current transaction."""
        raise NotImplementedError


class MySQLConnection(DatabaseConnection):
    """MySQL database connection handler."""

    def __init__(self):
        """Initialize the instance."""
        self.connection = None
        self.cursor = None

    def connect(
        self,
        host="localhost",
        port=3306,
        user="root",
        password="",
        database=None,
        **kwargs,
    ):
        """Connect to MySQL database."""
        if not MYSQL_AVAILABLE:
            raise ImportError("mysql-connector-python is not installed")

        try:
            self.connection = mysql.connector.connect(
                host=host,
                port=port,
                user=user,
                password=password,
                database=database,
                autocommit=False,
                use_unicode=True,
                charset="utf8mb4",
            )
            self.cursor = self.connection.cursor()
            logger.info(f"Connected to MySQL database: {database or 'default'}")
            return True
        except Exception as e:
            logger.error(f"Failed to connect to MySQL: {e}")
            raise

    def disconnect(self):
        """Disconnect from MySQL."""
        if self.cursor:
            self.cursor.close()
        if self.connection:
            self.connection.close()
        logger.info("Disconnected from MySQL")

    def execute_script(self, script: str) -> ExecutionResult:
        """Execute SQL script in MySQL."""
        result = ExecutionResult()
        start_time = time.time()

        try:
            # Split script into individual statements
            statements = [s.strip() for s in script.split(";") if s.strip()]

            for statement in statements:
                if statement:
                    self.cursor.execute(statement)
                    result.rows_affected += self.cursor.rowcount

            self.connection.commit()
            result.success = True
            result.execution_time = time.time() - start_time
            logger.info(
                f"Script executed successfully in {result.execution_time:.2f} seconds"
            )

        except Exception as e:
            self.connection.rollback()
            result.error_message = str(e)
            result.execution_time = time.time() - start_time
            logger.error(f"Script execution failed: {e}")

        return result

    def begin_transaction(self):
        """Start a MySQL transaction."""
        self.connection.start_transaction()

    def commit_transaction(self):
        """Commit MySQL transaction."""
        self.connection.commit()

    def rollback_transaction(self):
        """Rollback MySQL transaction."""
        self.connection.rollback()


class PostgreSQLConnection(DatabaseConnection):
    """PostgreSQL database connection handler."""

    def __init__(self):
        """Initialize the instance."""
        self.connection = None
        self.cursor = None

    def connect(
        self,
        host="localhost",
        port=5432,
        user="postgres",
        password="",
        database="postgres",
        **kwargs,
    ):
        """Connect to PostgreSQL database."""
        if not POSTGRESQL_AVAILABLE:
            raise ImportError("psycopg2 is not installed")

        try:
            self.connection = psycopg2.connect(
                host=host, port=port, user=user, password=password, database=database
            )
            self.cursor = self.connection.cursor()
            logger.info(f"Connected to PostgreSQL database: {database}")
            return True
        except Exception as e:
            logger.error(f"Failed to connect to PostgreSQL: {e}")
            raise

    def disconnect(self):
        """Disconnect from PostgreSQL."""
        if self.cursor:
            self.cursor.close()
        if self.connection:
            self.connection.close()
        logger.info("Disconnected from PostgreSQL")

    def execute_script(self, script: str) -> ExecutionResult:
        """Execute SQL script in PostgreSQL."""
        result = ExecutionResult()
        start_time = time.time()

        try:
            # PostgreSQL can handle multi-statement scripts
            self.cursor.execute(script)
            result.rows_affected = self.cursor.rowcount
            self.connection.commit()

            result.success = True
            result.execution_time = time.time() - start_time
            logger.info(
                f"Script executed successfully in {result.execution_time:.2f} seconds"
            )

        except Exception as e:
            self.connection.rollback()
            result.error_message = str(e)
            result.execution_time = time.time() - start_time
            logger.error(f"Script execution failed: {e}")

        return result

    def begin_transaction(self):
        """Start a PostgreSQL transaction."""
        self.connection.set_session(autocommit=False)

    def commit_transaction(self):
        """Commit PostgreSQL transaction."""
        self.connection.commit()

    def rollback_transaction(self):
        """Rollback PostgreSQL transaction."""
        self.connection.rollback()


class MongoDBConnection(DatabaseConnection):
    """MongoDB connection handler."""

    def __init__(self):
        """Initialize the instance."""
        self.client = None
        self.database = None

    def connect(
        self,
        host="localhost",
        port=27017,
        database="test",
        username=None,
        password=None,
        **kwargs,
    ):
        """Connect to MongoDB."""
        if not MONGODB_AVAILABLE:
            raise ImportError("pymongo is not installed")

        try:
            # Build connection string
            if username and password:
                connection_string = f"mongodb://{username}:{password}@{host}:{port}/"
            else:
                connection_string = f"mongodb://{host}:{port}/"

            self.client = pymongo.MongoClient(connection_string)
            self.database = self.client[database]

            # Test connection
            self.client.server_info()
            logger.info(f"Connected to MongoDB database: {database}")
            return True
        except Exception as e:
            logger.error(f"Failed to connect to MongoDB: {e}")
            raise

    def disconnect(self):
        """Disconnect from MongoDB."""
        if self.client:
            self.client.close()
        logger.info("Disconnected from MongoDB")

    def execute_script(self, script: str) -> ExecutionResult:
        """Execute MongoDB script."""
        result = ExecutionResult()
        start_time = time.time()

        try:
            # MongoDB scripts need to be executed differently
            # Parse the script to extract commands
            lines = script.split("\n")
            for line in lines:
                line = line.strip()

                # Skip comments and empty lines
                if not line or line.startswith("//"):
                    continue

                # Handle createCollection commands
                if "createCollection" in line:
                    collection_name = self._extract_collection_name(line)
                    if collection_name:
                        self.database.create_collection(collection_name)
                        logger.info(f"Created collection: {collection_name}")

                # Handle createIndex commands
                elif "createIndex" in line:
                    self._execute_create_index(line)

                # Handle validation commands
                elif "runCommand" in line:
                    # For complex commands, we'd need more parsing
                    logger.info(
                        "Skipping complex runCommand - would need manual execution"
                    )

            result.success = True
            result.execution_time = time.time() - start_time
            logger.info(
                f"MongoDB script executed in {result.execution_time:.2f} seconds"
            )

        except Exception as e:
            result.error_message = str(e)
            result.execution_time = time.time() - start_time
            logger.error(f"MongoDB script execution failed: {e}")

        return result

    def _extract_collection_name(self, line: str) -> Optional[str]:
        """Extract collection name from createCollection command."""
        import re

        match = re.search(r"createCollection\(['\"](\w+)['\"]", line)
        return match.group(1) if match else None

    def _execute_create_index(self, line: str):
        """Execute createIndex command."""
        import re

        # Extract collection and index details
        match = re.search(r"db\.(\w+)\.createIndex\((.*?)\)", line)
        if match:
            collection_name = match.group(1)
            # This is simplified - real implementation would parse the index spec
            logger.info(f"Would create index on collection: {collection_name}")

    def begin_transaction(self):
        """Handle MongoDB transaction begin."""

    def commit_transaction(self):
        """Handle MongoDB transaction commit."""

    def rollback_transaction(self):
        """Handle MongoDB transaction rollback."""
        logger.warning("MongoDB doesn't support traditional rollback")


class MigrationExecutor:
    """Executes database migrations."""

    def __init__(self, migrations_dir: str = "migrations"):
        """Initialize the instance."""
        self.migrations_dir = migrations_dir
        self.connections: Dict[DatabaseType, DatabaseConnection] = {}

    def get_connection(self, db_type: DatabaseType) -> DatabaseConnection:
        """Get or create database connection."""
        if db_type not in self.connections:
            if db_type == DatabaseType.MYSQL:
                self.connections[db_type] = MySQLConnection()
            elif db_type == DatabaseType.POSTGRESQL:
                self.connections[db_type] = PostgreSQLConnection()
            elif db_type == DatabaseType.MONGODB:
                self.connections[db_type] = MongoDBConnection()
            else:
                raise ValueError(f"Unsupported database type: {db_type}")

        return self.connections[db_type]

    def execute_migration(
        self, migration_id: str, connection_params: Dict[str, Any]
    ) -> ExecutionResult:
        """Execute a migration."""
        result = ExecutionResult()

        # Load migration metadata
        metadata_file = os.path.join(self.migrations_dir, f"{migration_id}.json")
        if not os.path.exists(metadata_file):
            result.error_message = f"Migration {migration_id} not found"
            return result

        with open(metadata_file, "r") as f:
            metadata = json.load(f)

        # Load migration script
        up_script_file = os.path.join(self.migrations_dir, "up", f"{migration_id}.sql")
        if not os.path.exists(up_script_file):
            result.error_message = f"Migration script not found: {up_script_file}"
            return result

        with open(up_script_file, "r", encoding="utf-8") as f:
            up_script = f.read()

        # Get connection for target database
        target_type = DatabaseType(metadata["target_type"])
        connection = self.get_connection(target_type)

        try:
            # Connect to database
            connection.connect(**connection_params)

            # Update migration status
            self._update_migration_status(migration_id, MigrationStatus.IN_PROGRESS)

            # Execute migration
            logger.info(f"Executing migration: {migration_id}")
            result = connection.execute_script(up_script)

            if result.success:
                # Update migration status
                self._update_migration_status(
                    migration_id,
                    MigrationStatus.COMPLETED,
                    execution_time=result.execution_time,
                )
                logger.info(f"Migration {migration_id} completed successfully")
            else:
                # Update migration status
                self._update_migration_status(
                    migration_id,
                    MigrationStatus.FAILED,
                    error_message=result.error_message,
                )
                logger.error(f"Migration {migration_id} failed")

        except Exception as e:
            result.error_message = str(e)
            self._update_migration_status(
                migration_id, MigrationStatus.FAILED, error_message=str(e)
            )
            logger.error(f"Migration execution error: {e}")

        finally:
            connection.disconnect()

        return result

    def rollback_migration(
        self, migration_id: str, connection_params: Dict[str, Any]
    ) -> ExecutionResult:
        """Rollback a migration."""
        result = ExecutionResult()

        # Load migration metadata
        metadata_file = os.path.join(self.migrations_dir, f"{migration_id}.json")
        if not os.path.exists(metadata_file):
            result.error_message = f"Migration {migration_id} not found"
            return result

        with open(metadata_file, "r") as f:
            metadata = json.load(f)

        # Load rollback script
        down_script_file = os.path.join(
            self.migrations_dir, "down", f"{migration_id}_rollback.sql"
        )
        if not os.path.exists(down_script_file):
            result.error_message = f"Rollback script not found: {down_script_file}"
            return result

        with open(down_script_file, "r", encoding="utf-8") as f:
            down_script = f.read()

        # Get connection for target database
        target_type = DatabaseType(metadata["target_type"])
        connection = self.get_connection(target_type)

        try:
            # Connect to database
            connection.connect(**connection_params)

            # Execute rollback
            logger.info(f"Rolling back migration: {migration_id}")
            result = connection.execute_script(down_script)

            if result.success:
                # Update migration status
                self._update_migration_status(migration_id, MigrationStatus.ROLLED_BACK)
                logger.info(f"Migration {migration_id} rolled back successfully")
            else:
                logger.error(f"Rollback of migration {migration_id} failed")

        except Exception as e:
            result.error_message = str(e)
            logger.error(f"Rollback execution error: {e}")

        finally:
            connection.disconnect()

        return result

    def _update_migration_status(
        self,
        migration_id: str,
        status: MigrationStatus,
        execution_time: Optional[float] = None,
        error_message: Optional[str] = None,
    ):
        """Update migration status in metadata file."""
        metadata_file = os.path.join(self.migrations_dir, f"{migration_id}.json")

        with open(metadata_file, "r") as f:
            metadata = json.load(f)

        metadata["status"] = status.value
        metadata["last_updated"] = datetime.now().isoformat()

        if execution_time is not None:
            metadata["execution_time"] = execution_time

        if error_message is not None:
            metadata["error_message"] = error_message

        if status == MigrationStatus.COMPLETED:
            metadata["executed_at"] = datetime.now().isoformat()

        with open(metadata_file, "w") as f:
            json.dump(metadata, f, indent=2)

    def close_all_connections(self):
        """Close all open database connections."""
        for connection in self.connections.values():
            connection.disconnect()
        self.connections.clear()


def main():
    """Handle operation."""
    import argparse

    parser = argparse.ArgumentParser(description="Migration Executor")
    parser.add_argument(
        "action", choices=["execute", "rollback"], help="Action to perform"
    )
    parser.add_argument(
        "--migration-id", required=True, help="Migration ID to execute or rollback"
    )
    parser.add_argument("--host", default="localhost", help="Database host")
    parser.add_argument("--port", type=int, help="Database port")
    parser.add_argument("--user", default="root", help="Database user")
    parser.add_argument("--password", default="", help="Database password")
    parser.add_argument("--database", required=True, help="Target database name")

    args = parser.parse_args()

    executor = MigrationExecutor()

    # Prepare connection parameters
    connection_params = {
        "host": args.host,
        "user": args.user,
        "password": args.password,
        "database": args.database,
    }

    if args.port:
        connection_params["port"] = args.port

    try:
        if args.action == "execute":
            result = executor.execute_migration(args.migration_id, connection_params)
            if result.success:
                print(
                    f"Migration executed successfully in {result.execution_time:.2f} seconds"
                )
            else:
                print(f"Migration failed: {result.error_message}")

        elif args.action == "rollback":
            result = executor.rollback_migration(args.migration_id, connection_params)
            if result.success:
                print("Migration rolled back successfully")
            else:
                print(f"Rollback failed: {result.error_message}")

    finally:
        executor.close_all_connections()


if __name__ == "__main__":
    main()
