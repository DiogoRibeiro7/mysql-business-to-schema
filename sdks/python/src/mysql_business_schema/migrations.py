"""Migration management for MySQL Business-to-Schema SDK."""

import hashlib
import logging
from datetime import datetime
from typing import List, Optional, Dict, Any
from pathlib import Path

from .models import Migration, MigrationStatus
from .exceptions import ValidationError

logger = logging.getLogger(__name__)


class MigrationManager:
    """Manage database migrations programmatically."""

    def __init__(self, client):
        """Initialize migration manager.

        Args:
            client: MySQLSchemaClient instance
        """
        self.client = client
        self.migrations_dir = Path("migrations")

    def create_migration(
        self,
        name: str,
        up_script: str,
        down_script: Optional[str] = None,
        description: Optional[str] = None,
    ) -> Migration:
        """Create a new migration.

        Args:
            name: Migration name
            up_script: SQL script for upgrade
            down_script: SQL script for rollback
            description: Migration description

        Returns:
            Created Migration object

        Example:
            >>> migration = manager.create_migration(
            ...     name="add_users_table",
            ...     up_script="CREATE TABLE users (...)",
            ...     down_script="DROP TABLE users"
            ... )
        """
        # Generate version from timestamp
        version = datetime.now().strftime("%Y%m%d%H%M%S")

        # Generate checksum
        _ = self._calculate_checksum(up_script)

        # Validate scripts
        self._validate_sql(up_script)
        if down_script:
            self._validate_sql(down_script)

        # Create migration via API
        migration = self.client.create_migration(
            description=description or name,
            up_script=up_script,
            down_script=down_script,
        )

        # Save to local file if migrations directory exists
        if self.migrations_dir.exists():
            self._save_migration_file(version, name, up_script, down_script)

        logger.info(f"Created migration: {version}_{name}")
        return migration

    def apply_migrations(
        self, target_version: Optional[str] = None, dry_run: bool = False
    ) -> List[Migration]:
        """Apply pending migrations up to target version.

        Args:
            target_version: Target version to migrate to (latest if None)
            dry_run: Perform dry run without applying changes

        Returns:
            List of applied migrations

        Example:
            >>> applied = manager.apply_migrations()
            >>> print(f"Applied {len(applied)} migrations")
        """
        result = self.client.apply_migration(
            target_version=target_version, dry_run=dry_run
        )

        if dry_run:
            logger.info(f"Dry run completed. Would apply migration: {result.version}")
        else:
            logger.info(f"Applied migration: {result.version}")

        return [result]

    def rollback_migrations(
        self, steps: int = 1, target_version: Optional[str] = None
    ) -> List[Migration]:
        """Rollback migrations.

        Args:
            steps: Number of migrations to rollback
            target_version: Specific version to rollback to

        Returns:
            List of rolled back migrations

        Example:
            >>> rolled_back = manager.rollback_migrations(steps=2)
        """
        result = self.client.rollback_migration(
            target_version=target_version, steps=steps
        )

        logger.info(f"Rolled back to version: {result.version}")
        return [result]

    def get_status(self) -> Dict[str, Any]:
        """Get current migration status.

        Returns:
            Migration status information

        Example:
            >>> status = manager.get_status()
            >>> print(f"Pending: {status['pending_count']}")
        """
        migrations = self.client.list_migrations()

        pending = [m for m in migrations if m.status == MigrationStatus.PENDING]
        completed = [m for m in migrations if m.status == MigrationStatus.COMPLETED]
        failed = [m for m in migrations if m.status == MigrationStatus.FAILED]

        return {
            "total_migrations": len(migrations),
            "pending_count": len(pending),
            "completed_count": len(completed),
            "failed_count": len(failed),
            "current_version": completed[-1].version if completed else None,
            "pending_migrations": [m.version for m in pending],
            "last_migration": completed[-1] if completed else None,
        }

    def validate_migration(self, migration: Migration) -> bool:
        """Validate a migration before applying.

        Args:
            migration: Migration to validate

        Returns:
            True if valid

        Raises:
            ValidationError: If migration is invalid
        """
        # Check required fields
        if not migration.up_script:
            raise ValidationError("Migration must have an up_script")

        # Validate SQL syntax
        self._validate_sql(migration.up_script)
        if migration.down_script:
            self._validate_sql(migration.down_script)

        # Check for destructive operations
        destructive_keywords = ["DROP TABLE", "TRUNCATE", "DELETE FROM"]
        for keyword in destructive_keywords:
            if keyword in migration.up_script.upper():
                logger.warning(f"Migration contains destructive operation: {keyword}")

        return True

    def generate_migration_from_diff(
        self, source_database: str, target_database: str, name: str
    ) -> Migration:
        """Generate migration from database differences.

        Args:
            source_database: Source database name
            target_database: Target database name
            name: Migration name

        Returns:
            Generated Migration object

        Example:
            >>> migration = manager.generate_migration_from_diff(
            ...     source_database="dev_db",
            ...     target_database="prod_db",
            ...     name="sync_prod_schema"
            ... )
        """
        # Get schemas
        source = self.client.get_database(source_database)
        target = self.client.get_database(target_database)

        # Calculate differences
        up_script = self._calculate_schema_diff(source, target)
        down_script = self._calculate_schema_diff(target, source)

        # Create migration
        return self.create_migration(
            name=name,
            up_script=up_script,
            down_script=down_script,
            description=f"Sync {source_database} to {target_database}",
        )

    def _calculate_checksum(self, content: str) -> str:
        """Calculate SHA256 checksum of content."""
        return hashlib.sha256(content.encode()).hexdigest()

    def _validate_sql(self, sql: str):
        """Validate SQL syntax (basic validation)."""
        if not sql.strip():
            raise ValidationError("SQL script cannot be empty")

        # Check for basic SQL structure
        sql_upper = sql.upper()
        valid_statements = [
            "CREATE",
            "ALTER",
            "DROP",
            "INSERT",
            "UPDATE",
            "DELETE",
            "SELECT",
            "GRANT",
            "REVOKE",
            "BEGIN",
            "COMMIT",
            "ROLLBACK",
        ]

        has_valid_statement = any(
            statement in sql_upper for statement in valid_statements
        )

        if not has_valid_statement:
            raise ValidationError("SQL script must contain valid SQL statements")

    def _save_migration_file(
        self, version: str, name: str, up_script: str, down_script: Optional[str] = None
    ):
        """Save migration to local file."""
        filename = f"{version}_{name}.sql"
        filepath = self.migrations_dir / filename

        content = f"-- Migration: {version}_{name}\n"
        content += f"-- Created: {datetime.now()}\n\n"
        content += "-- UP\n"
        content += up_script

        if down_script:
            content += "\n\n-- DOWN\n"
            content += down_script

        filepath.write_text(content)
        logger.info(f"Saved migration file: {filepath}")

    def _calculate_schema_diff(self, source, target) -> str:
        """Calculate schema differences between databases."""
        # This would implement schema comparison logic
        # For now, return a placeholder
        return "-- Schema synchronization script\n"

    def load_migrations_from_directory(
        self, directory: Optional[Path] = None
    ) -> List[Migration]:
        """Load migrations from local directory.

        Args:
            directory: Directory containing migration files

        Returns:
            List of loaded migrations
        """
        migrations_dir = directory or self.migrations_dir
        if not migrations_dir.exists():
            return []

        migrations = []
        for file in sorted(migrations_dir.glob("*.sql")):
            migration = self._parse_migration_file(file)
            if migration:
                migrations.append(migration)

        return migrations

    def _parse_migration_file(self, filepath: Path) -> Optional[Migration]:
        """Parse migration from file."""
        content = filepath.read_text()

        # Extract version from filename
        filename = filepath.stem
        parts = filename.split("_", 1)
        if len(parts) != 2:
            logger.warning(f"Invalid migration filename: {filename}")
            return None

        version = parts[0]
        name = parts[1]

        # Split up and down scripts
        up_script = ""
        down_script = ""
        current_section = None

        for line in content.split("\n"):
            if "-- UP" in line:
                current_section = "up"
            elif "-- DOWN" in line:
                current_section = "down"
            elif current_section == "up":
                up_script += line + "\n"
            elif current_section == "down":
                down_script += line + "\n"

        return Migration(
            version=version,
            description=name,
            up_script=up_script.strip(),
            down_script=down_script.strip() if down_script else None,
            status=MigrationStatus.PENDING,
            checksum=self._calculate_checksum(up_script),
        )
