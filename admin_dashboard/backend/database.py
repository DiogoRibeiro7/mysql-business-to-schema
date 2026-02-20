"""
Database management module
"""

import mysql.connector
from mysql.connector import pooling
import asyncio
from typing import Dict, List, Any, Optional
import logging
from datetime import datetime, timedelta
import json
import os
from pathlib import Path

logger = logging.getLogger(__name__)

class DatabaseManager:
    """Manages database connections and operations."""

    def __init__(self):
        self.config = self._load_config()
        self.pool = None
        self.initialized = False

    def _load_config(self) -> Dict[str, Any]:
        """Load database configuration."""
        # Try to load from config file
        config_file = Path(".migration-config.json")
        if config_file.exists():
            with open(config_file, 'r') as f:
                config = json.load(f)
        else:
            # Use environment variables or defaults
            config = {
                'host': os.getenv('DB_HOST', 'localhost'),
                'port': int(os.getenv('DB_PORT', 3306)),
                'user': os.getenv('DB_USER', 'root'),
                'password': os.getenv('DB_PASSWORD', ''),
                'database': os.getenv('DB_NAME', 'mysql_business_schema')
            }
        return config

    async def initialize(self):
        """Initialize database connection pool."""
        try:
            self.pool = pooling.MySQLConnectionPool(
                pool_name="admin_dashboard_pool",
                pool_size=10,
                pool_reset_session=True,
                **self.config
            )
            self.initialized = True
            logger.info("Database connection pool initialized")

            # Create necessary tables
            await self._create_dashboard_tables()
        except Exception as e:
            logger.error(f"Failed to initialize database: {e}")
            raise

    async def _create_dashboard_tables(self):
        """Create dashboard-specific tables."""
        conn = self.pool.get_connection()
        cursor = conn.cursor()

        try:
            # Query history table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS query_history (
                    query_id VARCHAR(36) PRIMARY KEY,
                    query_text TEXT NOT NULL,
                    database_name VARCHAR(100),
                    user VARCHAR(100),
                    execution_time FLOAT,
                    row_count INT,
                    status VARCHAR(20),
                    error_message TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    INDEX idx_user (user),
                    INDEX idx_created_at (created_at)
                )
            """)

            # Alert configuration table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS alert_configs (
                    alert_id VARCHAR(36) PRIMARY KEY,
                    name VARCHAR(200) NOT NULL,
                    metric VARCHAR(100) NOT NULL,
                    threshold FLOAT NOT NULL,
                    condition_type VARCHAR(20) NOT NULL,
                    is_enabled BOOLEAN DEFAULT TRUE,
                    notification_channels JSON,
                    description TEXT,
                    created_by VARCHAR(100),
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                    INDEX idx_metric (metric),
                    INDEX idx_enabled (is_enabled)
                )
            """)

            # Alert history table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS alert_history (
                    id BIGINT PRIMARY KEY AUTO_INCREMENT,
                    alert_id VARCHAR(36) NOT NULL,
                    alert_name VARCHAR(200),
                    triggered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    metric_value FLOAT,
                    threshold FLOAT,
                    condition_type VARCHAR(20),
                    notification_sent BOOLEAN DEFAULT FALSE,
                    resolved_at TIMESTAMP NULL,
                    FOREIGN KEY (alert_id) REFERENCES alert_configs(alert_id) ON DELETE CASCADE,
                    INDEX idx_alert_id (alert_id),
                    INDEX idx_triggered_at (triggered_at)
                )
            """)

            # Backup metadata table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS backup_metadata (
                    backup_id VARCHAR(36) PRIMARY KEY,
                    database_name VARCHAR(100) NOT NULL,
                    backup_type VARCHAR(20) NOT NULL,
                    size_bytes BIGINT,
                    location VARCHAR(500),
                    checksum VARCHAR(64),
                    status VARCHAR(20),
                    description TEXT,
                    created_by VARCHAR(100),
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    completed_at TIMESTAMP NULL,
                    INDEX idx_database (database_name),
                    INDEX idx_created_at (created_at)
                )
            """)

            conn.commit()
            logger.info("Dashboard tables created successfully")

        except Exception as e:
            logger.error(f"Error creating dashboard tables: {e}")
            conn.rollback()
            raise
        finally:
            cursor.close()
            conn.close()

    def get_connection(self):
        """Get a database connection from the pool."""
        if not self.initialized:
            raise RuntimeError("Database not initialized")
        return self.pool.get_connection()

    async def execute_query(self, query: str, params: Optional[tuple] = None) -> List[Dict[str, Any]]:
        """Execute a SELECT query and return results."""
        conn = self.get_connection()
        cursor = conn.cursor(dictionary=True)

        try:
            cursor.execute(query, params or ())
            results = cursor.fetchall()
            return results
        finally:
            cursor.close()
            conn.close()

    async def execute_update(self, query: str, params: Optional[tuple] = None) -> int:
        """Execute an UPDATE/INSERT/DELETE query."""
        conn = self.get_connection()
        cursor = conn.cursor()

        try:
            cursor.execute(query, params or ())
            conn.commit()
            return cursor.rowcount
        except Exception as e:
            conn.rollback()
            raise
        finally:
            cursor.close()
            conn.close()

    async def get_system_status(self) -> Dict[str, Any]:
        """Get overall system status."""
        status = {
            "database": {},
            "migrations": {},
            "connections": {},
            "uptime": "",
            "last_backup": None
        }

        conn = self.get_connection()
        cursor = conn.cursor(dictionary=True)

        try:
            # Database status
            cursor.execute("SELECT VERSION() as version")
            status["database"]["version"] = cursor.fetchone()["version"]

            cursor.execute("SHOW STATUS LIKE 'Uptime'")
            uptime_seconds = int(cursor.fetchone()["Value"])
            status["uptime"] = self._format_uptime(uptime_seconds)

            # Connection status
            cursor.execute("SHOW STATUS LIKE 'Threads_connected'")
            status["connections"]["active"] = int(cursor.fetchone()["Value"])

            cursor.execute("SHOW VARIABLES LIKE 'max_connections'")
            status["connections"]["max"] = int(cursor.fetchone()["Value"])

            # Migration status
            cursor.execute("""
                SELECT
                    COUNT(*) as total,
                    SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed,
                    SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending
                FROM schema_migrations
            """)
            migration_stats = cursor.fetchone()
            if migration_stats:
                status["migrations"] = migration_stats

            # Last backup
            cursor.execute("""
                SELECT created_at
                FROM backup_metadata
                WHERE status = 'completed'
                ORDER BY created_at DESC
                LIMIT 1
            """)
            last_backup = cursor.fetchone()
            if last_backup:
                status["last_backup"] = last_backup["created_at"]

            return status

        finally:
            cursor.close()
            conn.close()

    async def list_databases(self) -> List[str]:
        """List all databases."""
        results = await self.execute_query("SHOW DATABASES")
        return [r["Database"] for r in results]

    async def get_database_size(self, database: str) -> float:
        """Get database size in MB."""
        query = """
        SELECT
            ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) as size_mb
        FROM information_schema.TABLES
        WHERE table_schema = %s
        """
        result = await self.execute_query(query, (database,))
        return result[0]["size_mb"] if result else 0

    async def get_table_stats(self, database: str, table: str) -> Dict[str, Any]:
        """Get table statistics."""
        query = """
        SELECT
            table_rows as row_count,
            ROUND(data_length / 1024 / 1024, 2) as data_size_mb,
            ROUND(index_length / 1024 / 1024, 2) as index_size_mb,
            ROUND((data_length + index_length) / 1024 / 1024, 2) as total_size_mb,
            engine,
            table_collation as collation,
            create_time,
            update_time
        FROM information_schema.TABLES
        WHERE table_schema = %s AND table_name = %s
        """
        result = await self.execute_query(query, (database, table))
        return result[0] if result else {}

    async def list_backups(self) -> List[Dict[str, Any]]:
        """List all backups."""
        query = """
        SELECT
            backup_id,
            database_name,
            backup_type,
            size_bytes,
            location,
            status,
            description,
            created_by,
            created_at,
            completed_at
        FROM backup_metadata
        ORDER BY created_at DESC
        """
        return await self.execute_query(query)

    async def create_backup(self, database: str, description: Optional[str] = None) -> Dict[str, Any]:
        """Create a database backup."""
        import uuid
        import subprocess
        from datetime import datetime

        backup_id = str(uuid.uuid4())
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"{database}_backup_{timestamp}.sql"
        backup_path = Path("backups") / filename
        backup_path.parent.mkdir(exist_ok=True)

        # Insert backup record
        await self.execute_update("""
            INSERT INTO backup_metadata
            (backup_id, database_name, backup_type, location, status, description, created_by)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """, (backup_id, database, 'full', str(backup_path), 'running', description, 'admin'))

        try:
            # Execute mysqldump
            cmd = [
                'mysqldump',
                f'-h{self.config["host"]}',
                f'-u{self.config["user"]}',
                f'-p{self.config["password"]}',
                '--single-transaction',
                '--routines',
                '--triggers',
                database
            ]

            with open(backup_path, 'w') as f:
                result = subprocess.run(cmd, stdout=f, stderr=subprocess.PIPE, text=True)

            if result.returncode != 0:
                raise Exception(f"Backup failed: {result.stderr}")

            # Update backup record
            file_size = backup_path.stat().st_size
            await self.execute_update("""
                UPDATE backup_metadata
                SET status = 'completed', size_bytes = %s, completed_at = NOW()
                WHERE backup_id = %s
            """, (file_size, backup_id))

            return {
                "backup_id": backup_id,
                "filename": filename,
                "size_bytes": file_size,
                "status": "completed"
            }

        except Exception as e:
            # Mark backup as failed
            await self.execute_update("""
                UPDATE backup_metadata
                SET status = 'failed'
                WHERE backup_id = %s
            """, (backup_id,))
            raise

    async def restore_backup(self, backup_id: str, target_database: str) -> Dict[str, Any]:
        """Restore from backup."""
        # Get backup info
        backup = await self.execute_query(
            "SELECT * FROM backup_metadata WHERE backup_id = %s",
            (backup_id,)
        )

        if not backup:
            raise ValueError(f"Backup {backup_id} not found")

        backup = backup[0]
        backup_file = Path(backup["location"])

        if not backup_file.exists():
            raise ValueError(f"Backup file {backup_file} not found")

        try:
            # Create database if it doesn't exist
            conn = self.get_connection()
            cursor = conn.cursor()
            cursor.execute(f"CREATE DATABASE IF NOT EXISTS {target_database}")
            cursor.close()
            conn.close()

            # Restore backup
            import subprocess
            cmd = [
                'mysql',
                f'-h{self.config["host"]}',
                f'-u{self.config["user"]}',
                f'-p{self.config["password"]}',
                target_database
            ]

            with open(backup_file, 'r') as f:
                result = subprocess.run(cmd, stdin=f, stderr=subprocess.PIPE, text=True)

            if result.returncode != 0:
                raise Exception(f"Restore failed: {result.stderr}")

            return {
                "success": True,
                "target_database": target_database,
                "backup_id": backup_id
            }

        except Exception as e:
            logger.error(f"Restore failed: {e}")
            raise

    async def list_alerts(self) -> List[Dict[str, Any]]:
        """List configured alerts."""
        query = """
        SELECT
            alert_id,
            name,
            metric,
            threshold,
            condition_type,
            is_enabled,
            notification_channels,
            description,
            created_by,
            created_at
        FROM alert_configs
        ORDER BY created_at DESC
        """
        return await self.execute_query(query)

    async def create_alert(
        self,
        name: str,
        metric: str,
        threshold: float,
        condition: str,
        notification_channels: List[str]
    ) -> Dict[str, Any]:
        """Create an alert configuration."""
        import uuid

        alert_id = str(uuid.uuid4())

        await self.execute_update("""
            INSERT INTO alert_configs
            (alert_id, name, metric, threshold, condition_type, notification_channels, created_by)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """, (
            alert_id,
            name,
            metric,
            threshold,
            condition,
            json.dumps(notification_channels),
            'admin'
        ))

        return {"alert_id": alert_id, "name": name}

    async def get_alert_history(self, limit: int = 50) -> List[Dict[str, Any]]:
        """Get alert history."""
        query = """
        SELECT
            ah.*,
            ac.name as alert_name
        FROM alert_history ah
        JOIN alert_configs ac ON ah.alert_id = ac.alert_id
        ORDER BY ah.triggered_at DESC
        LIMIT %s
        """
        results = await self.execute_query(query, (limit,))

        # Convert JSON strings
        for r in results:
            if isinstance(r.get('notification_channels'), str):
                r['notification_channels'] = json.loads(r['notification_channels'])

        return results

    def _format_uptime(self, seconds: int) -> str:
        """Format uptime in human-readable format."""
        days = seconds // 86400
        hours = (seconds % 86400) // 3600
        minutes = (seconds % 3600) // 60

        parts = []
        if days > 0:
            parts.append(f"{days}d")
        if hours > 0:
            parts.append(f"{hours}h")
        if minutes > 0:
            parts.append(f"{minutes}m")

        return " ".join(parts) if parts else "0m"

    async def close(self):
        """Close database connections."""
        if self.pool:
            # Close all connections in pool
            self.pool._remove_connections()
            logger.info("Database connection pool closed")

# Singleton instance
db_manager = DatabaseManager()

async def get_db():
    """Dependency to get database manager."""
    if not db_manager.initialized:
        await db_manager.initialize()
    return db_manager