"""Core migration system components."""

import os
import hashlib
import json
import time
from datetime import datetime
from typing import List, Dict, Optional, Any, Tuple
from dataclasses import dataclass, field
from enum import Enum
from pathlib import Path
import re
import logging

logger = logging.getLogger(__name__)


class MigrationStatus(Enum):
    """Migration status enumeration."""

    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    ROLLED_BACK = "rolled_back"


class MigrationType(Enum):
    """Types of migrations."""

    SQL = "sql"
    PYTHON = "python"
    VERSIONED = "versioned"
    REPEATABLE = "repeatable"
    UNDO = "undo"


@dataclass
class Migration:
    """Represents a database migration."""

    version: str
    description: str
    type: MigrationType
    checksum: str
    up_script: str
    down_script: Optional[str] = None
    filename: Optional[str] = None
    executed_at: Optional[datetime] = None
    execution_time: Optional[float] = None
    status: MigrationStatus = MigrationStatus.PENDING
    applied_by: Optional[str] = None
    metadata: Dict[str, Any] = field(default_factory=dict)

    def calculate_checksum(self) -> str:
        """Calculate checksum of migration content."""
        content = f"{self.up_script}{self.down_script or ''}"
        return hashlib.sha256(content.encode()).hexdigest()

    def validate(self) -> Tuple[bool, Optional[str]]:
        """Validate migration structure."""
        if not self.version:
            return False, "Migration version is required"

        if not self.description:
            return False, "Migration description is required"

        if not self.up_script:
            return False, "Up migration script is required"

        # Validate version format (e.g., V001, V20240120_1230, etc.)
        version_pattern = r"^V\d+(_\d+)?(__[\w_]+)?$"
        if not re.match(version_pattern, self.version):
            return False, f"Invalid version format: {self.version}"

        # Check checksum
        calculated = self.calculate_checksum()
        if self.checksum and self.checksum != calculated:
            return (
                False,
                f"Checksum mismatch: expected {self.checksum}, got {calculated}",
            )

        return True, None

    def to_dict(self) -> Dict[str, Any]:
        """Convert migration to dictionary."""
        return {
            "version": self.version,
            "description": self.description,
            "type": self.type.value,
            "checksum": self.checksum,
            "filename": self.filename,
            "executed_at": self.executed_at.isoformat() if self.executed_at else None,
            "execution_time": self.execution_time,
            "status": self.status.value,
            "applied_by": self.applied_by,
            "metadata": self.metadata,
        }


class MigrationHistory:
    """Manages migration history in database."""

    def __init__(self, connection):
        """Initialize the instance."""
        self.connection = connection
        self.history_table = "schema_migrations"
        self._ensure_history_table()

    def _ensure_history_table(self):
        """Create migration history table if it doesn't exist."""
        cursor = self.connection.cursor()
        cursor.execute(
            f"""
            CREATE TABLE IF NOT EXISTS {self.history_table} (
                version VARCHAR(255) PRIMARY KEY,
                description TEXT,
                type VARCHAR(50),
                script_name VARCHAR(255),
                checksum VARCHAR(64),
                applied_by VARCHAR(100),
                applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                execution_time FLOAT,
                status VARCHAR(50),
                metadata JSON,
                INDEX idx_applied_at (applied_at),
                INDEX idx_status (status)
            )
        """
        )
        self.connection.commit()
        cursor.close()

    def get_applied_migrations(self) -> List[Dict[str, Any]]:
        """Get list of applied migrations."""
        cursor = self.connection.cursor(dictionary=True)
        cursor.execute(
            f"""
            SELECT * FROM {self.history_table}
            WHERE status = 'completed'
            ORDER BY applied_at
        """
        )
        migrations = cursor.fetchall()
        cursor.close()
        return migrations

    def get_last_migration(self) -> Optional[Dict[str, Any]]:
        """Get the last applied migration."""
        cursor = self.connection.cursor(dictionary=True)
        cursor.execute(
            f"""
            SELECT * FROM {self.history_table}
            WHERE status = 'completed'
            ORDER BY applied_at DESC
            LIMIT 1
        """
        )
        result = cursor.fetchone()
        cursor.close()
        return result

    def is_applied(self, version: str) -> bool:
        """Check if a migration version is already applied."""
        cursor = self.connection.cursor()
        cursor.execute(
            f"""
            SELECT COUNT(*) as count FROM {self.history_table}
            WHERE version = %s AND status = 'completed'
        """,
            (version,),
        )
        result = cursor.fetchone()
        cursor.close()
        return result[0] > 0

    def record_migration(self, migration: Migration):
        """Record migration execution in history."""
        cursor = self.connection.cursor()
        cursor.execute(
            f"""
            INSERT INTO {self.history_table}
            (version, description, type, script_name, checksum, applied_by,
             execution_time, status, metadata)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            ON DUPLICATE KEY UPDATE
                status = VALUES(status),
                execution_time = VALUES(execution_time),
                applied_at = CURRENT_TIMESTAMP
        """,
            (
                migration.version,
                migration.description,
                migration.type.value,
                migration.filename,
                migration.checksum,
                migration.applied_by or os.getenv("USER", "system"),
                migration.execution_time,
                migration.status.value,
                json.dumps(migration.metadata),
            ),
        )
        self.connection.commit()
        cursor.close()

    def mark_as_failed(self, version: str, error: str):
        """Mark a migration as failed."""
        cursor = self.connection.cursor()
        cursor.execute(
            f"""
            UPDATE {self.history_table}
            SET status = 'failed',
                metadata = JSON_SET(COALESCE(metadata, '{{}}'), '$.error', %s)
            WHERE version = %s
        """,
            (error, version),
        )
        self.connection.commit()
        cursor.close()

    def get_pending_migrations(
        self, available_migrations: List[Migration]
    ) -> List[Migration]:
        """Get migrations that haven't been applied yet."""
        applied = {m["version"] for m in self.get_applied_migrations()}
        return [m for m in available_migrations if m.version not in applied]


class MigrationRunner:
    """Executes database migrations."""

    def __init__(self, connection, migrations_path: str = "migrations"):
        """Initialize the instance."""
        self.connection = connection
        self.migrations_path = Path(migrations_path)
        self.history = MigrationHistory(connection)
        self.dry_run = False
        self.auto_rollback = True

    def discover_migrations(self) -> List[Migration]:
        """Discover migration files in migrations directory."""
        migrations = []

        if not self.migrations_path.exists():
            logger.warning(
                f"Migrations directory {self.migrations_path} does not exist"
            )
            return migrations

        # Find all SQL migration files
        for file_path in sorted(self.migrations_path.glob("*.sql")):
            migration = self._parse_migration_file(file_path)
            if migration:
                migrations.append(migration)

        # Find all Python migration files
        for file_path in sorted(self.migrations_path.glob("*.py")):
            if file_path.name != "__init__.py":
                migration = self._parse_python_migration(file_path)
                if migration:
                    migrations.append(migration)

        return sorted(migrations, key=lambda m: m.version)

    def _parse_migration_file(self, file_path: Path) -> Optional[Migration]:
        """Parse a SQL migration file."""
        # Expected format: V001__description.sql or V20240120_1230__description.sql
        pattern = r"^(V\d+(?:_\d+)?)__(.+)\.sql$"
        match = re.match(pattern, file_path.name)

        if not match:
            logger.warning(f"Ignoring file with invalid name format: {file_path.name}")
            return None

        version = match.group(1)
        description = match.group(2).replace("_", " ")

        with open(file_path, "r") as f:
            content = f.read()

        # Split into up and down migrations
        up_script, down_script = self._split_migration_script(content)

        migration = Migration(
            version=version,
            description=description,
            type=MigrationType.SQL,
            checksum="",  # Will be calculated
            up_script=up_script,
            down_script=down_script,
            filename=file_path.name,
        )
        migration.checksum = migration.calculate_checksum()

        return migration

    def _parse_python_migration(self, file_path: Path) -> Optional[Migration]:
        """Parse a Python migration file."""
        # Expected format: V001__description.py
        pattern = r"^(V\d+(?:_\d+)?)__(.+)\.py$"
        match = re.match(pattern, file_path.name)

        if not match:
            return None

        version = match.group(1)
        description = match.group(2).replace("_", " ")

        # For Python migrations, we store the file path
        migration = Migration(
            version=version,
            description=description,
            type=MigrationType.PYTHON,
            checksum="",
            up_script=str(file_path),
            down_script=None,
            filename=file_path.name,
        )

        with open(file_path, "r") as f:
            content = f.read()
            migration.checksum = hashlib.sha256(content.encode()).hexdigest()

        return migration

    def _split_migration_script(self, content: str) -> Tuple[str, Optional[str]]:
        """Split migration script into up and down parts."""
        # Look for markers
        if "-- ==== DOWN ====" in content or "-- ==== ROLLBACK ====" in content:
            parts = re.split(r"-- ==== (?:DOWN|ROLLBACK) ====", content)
            up_script = parts[0].strip()
            down_script = parts[1].strip() if len(parts) > 1 else None
            return up_script, down_script

        # No down migration provided
        return content.strip(), None

    def run_migrations(
        self, target_version: Optional[str] = None, dry_run: bool = False
    ) -> Dict[str, Any]:
        """Run pending migrations up to target version.

        Args:
            target_version: Target version to migrate to (None for latest)
            dry_run: If True, don't actually execute migrations

        Returns:
            Migration results
        """
        self.dry_run = dry_run
        results = {"success": True, "migrations_run": [], "errors": []}

        try:
            # Discover available migrations
            all_migrations = self.discover_migrations()

            if not all_migrations:
                logger.info("No migrations found")
                return results

            # Get pending migrations
            pending = self.history.get_pending_migrations(all_migrations)

            if not pending:
                logger.info("No pending migrations")
                return results

            # Filter up to target version if specified
            if target_version:
                pending = [m for m in pending if m.version <= target_version]

            logger.info(f"Found {len(pending)} pending migrations")

            # Execute migrations
            for migration in pending:
                logger.info(
                    f"Running migration {migration.version}: {migration.description}"
                )

                if dry_run:
                    logger.info(
                        f"[DRY RUN] Would execute:\n{migration.up_script[:500]}"
                    )
                    results["migrations_run"].append(migration.version)
                    continue

                success = self._execute_migration(migration)

                if success:
                    results["migrations_run"].append(migration.version)
                else:
                    results["success"] = False
                    results["errors"].append(
                        f"Failed to run migration {migration.version}"
                    )

                    if self.auto_rollback and migration.down_script:
                        logger.info(f"Rolling back migration {migration.version}")
                        self._rollback_migration(migration)
                    break

        except Exception as e:
            logger.error(f"Migration failed: {e}")
            results["success"] = False
            results["errors"].append(str(e))

        return results

    def _execute_migration(self, migration: Migration) -> bool:
        """Execute a single migration."""
        start_time = time.time()
        migration.status = MigrationStatus.RUNNING
        migration.applied_by = os.getenv("USER", "system")

        try:
            if migration.type == MigrationType.SQL:
                self._execute_sql_migration(migration)
            elif migration.type == MigrationType.PYTHON:
                self._execute_python_migration(migration)

            migration.execution_time = time.time() - start_time
            migration.status = MigrationStatus.COMPLETED
            migration.executed_at = datetime.now()

            # Record in history
            self.history.record_migration(migration)

            logger.info(
                f"Migration {migration.version} completed in {migration.execution_time:.2f}s"
            )
            return True

        except Exception as e:
            migration.status = MigrationStatus.FAILED
            migration.execution_time = time.time() - start_time

            logger.error(f"Migration {migration.version} failed: {e}")
            self.history.mark_as_failed(migration.version, str(e))
            return False

    def _execute_sql_migration(self, migration: Migration):
        """Execute SQL migration."""
        cursor = self.connection.cursor()

        # Split into individual statements
        statements = self._split_sql_statements(migration.up_script)

        for statement in statements:
            if statement.strip():
                cursor.execute(statement)

        self.connection.commit()
        cursor.close()

    def _execute_python_migration(self, migration: Migration):
        """Execute Python migration."""
        import importlib.util

        spec = importlib.util.spec_from_file_location(
            f"migration_{migration.version}", migration.up_script
        )
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)

        # Call the up() function
        if hasattr(module, "up"):
            module.up(self.connection)
        else:
            raise Exception(
                f"Python migration {migration.version} missing up() function"
            )

    def _rollback_migration(self, migration: Migration) -> bool:
        """Rollback a single migration."""
        if not migration.down_script:
            logger.warning(f"No rollback script for migration {migration.version}")
            return False

        try:
            if migration.type == MigrationType.SQL:
                cursor = self.connection.cursor()
                statements = self._split_sql_statements(migration.down_script)
                for statement in statements:
                    if statement.strip():
                        cursor.execute(statement)
                self.connection.commit()
                cursor.close()

            elif migration.type == MigrationType.PYTHON:
                import importlib.util

                spec = importlib.util.spec_from_file_location(
                    f"migration_{migration.version}", migration.up_script
                )
                module = importlib.util.module_from_spec(spec)
                spec.loader.exec_module(module)

                if hasattr(module, "down"):
                    module.down(self.connection)

            migration.status = MigrationStatus.ROLLED_BACK
            self.history.record_migration(migration)

            logger.info(f"Rolled back migration {migration.version}")
            return True

        except Exception as e:
            logger.error(f"Failed to rollback migration {migration.version}: {e}")
            return False

    def _split_sql_statements(self, sql: str) -> List[str]:
        """Split SQL script into individual statements."""
        # Simple split by semicolon (can be improved for complex cases)
        statements = []
        current = []

        for line in sql.split("\n"):
            # Skip comments
            if line.strip().startswith("--"):
                continue

            current.append(line)

            # Check for statement end
            if line.rstrip().endswith(";"):
                statements.append("\n".join(current))
                current = []

        # Add remaining if any
        if current:
            statements.append("\n".join(current))

        return statements

    def rollback(self, target_version: Optional[str] = None) -> Dict[str, Any]:
        """Rollback migrations to target version.

        Args:
            target_version: Version to rollback to (None for last migration)

        Returns:
            Rollback results
        """
        results = {"success": True, "migrations_rolled_back": [], "errors": []}

        try:
            applied = self.history.get_applied_migrations()

            if not applied:
                logger.info("No migrations to rollback")
                return results

            # Determine migrations to rollback
            to_rollback = []
            if target_version:
                to_rollback = [m for m in applied if m["version"] > target_version]
            else:
                # Rollback last migration
                to_rollback = [applied[-1]]

            # Rollback in reverse order
            for migration_record in reversed(to_rollback):
                # Find migration definition
                all_migrations = self.discover_migrations()
                migration = next(
                    (
                        m
                        for m in all_migrations
                        if m.version == migration_record["version"]
                    ),
                    None,
                )

                if not migration:
                    logger.error(f"Migration {migration_record['version']} not found")
                    continue

                if self._rollback_migration(migration):
                    results["migrations_rolled_back"].append(migration.version)
                else:
                    results["success"] = False
                    results["errors"].append(f"Failed to rollback {migration.version}")
                    break

        except Exception as e:
            logger.error(f"Rollback failed: {e}")
            results["success"] = False
            results["errors"].append(str(e))

        return results

    def validate_migrations(self) -> Dict[str, Any]:
        """Validate all migrations for consistency."""
        results = {"valid": True, "issues": []}

        migrations = self.discover_migrations()

        # Check for duplicate versions
        versions = [m.version for m in migrations]
        duplicates = [v for v in versions if versions.count(v) > 1]
        if duplicates:
            results["valid"] = False
            results["issues"].append(f"Duplicate versions found: {duplicates}")

        # Check each migration
        for migration in migrations:
            valid, error = migration.validate()
            if not valid:
                results["valid"] = False
                results["issues"].append(f"{migration.version}: {error}")

        # Check for checksum mismatches with applied migrations
        applied = self.history.get_applied_migrations()
        for record in applied:
            migration = next(
                (m for m in migrations if m.version == record["version"]), None
            )
            if migration and migration.checksum != record.get("checksum"):
                results["valid"] = False
                results["issues"].append(
                    f"{migration.version}: Checksum mismatch - migration file has been modified"
                )

        return results

    def get_status(self) -> Dict[str, Any]:
        """Get current migration status."""
        all_migrations = self.discover_migrations()
        applied = self.history.get_applied_migrations()
        pending = self.history.get_pending_migrations(all_migrations)

        return {
            "total_migrations": len(all_migrations),
            "applied_migrations": len(applied),
            "pending_migrations": len(pending),
            "last_migration": self.history.get_last_migration(),
            "pending_versions": [m.version for m in pending],
        }
