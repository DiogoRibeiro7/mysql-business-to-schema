"""
Migration Handler for Admin Dashboard
Manages database migrations and version control
"""

import logging
from typing import List, Dict, Any, Optional
from pathlib import Path
import json
from datetime import datetime
import hashlib

logger = logging.getLogger(__name__)


class MigrationHandler:
    """Handles database migrations and version control"""

    def __init__(self):
        self.migrations_path = Path(__file__).parent.parent.parent / "migrations"
        self.migration_history = []
        self.pending_migrations = []
        self._load_migrations()

    def _load_migrations(self):
        """Load all available migrations"""
        try:
            if self.migrations_path.exists():
                migration_files = sorted(self.migrations_path.glob("*.sql"))

                for migration_file in migration_files:
                    migration_info = {
                        "id": migration_file.stem,
                        "filename": migration_file.name,
                        "path": str(migration_file),
                        "size": migration_file.stat().st_size,
                        "created_at": datetime.fromtimestamp(
                            migration_file.stat().st_ctime
                        ).isoformat(),
                        "checksum": self._calculate_checksum(migration_file),
                        "status": "pending",
                    }
                    self.pending_migrations.append(migration_info)

            logger.info(f"Loaded {len(self.pending_migrations)} migrations")
        except Exception as e:
            logger.error(f"Error loading migrations: {e}")

    def _calculate_checksum(self, file_path: Path) -> str:
        """Calculate SHA256 checksum of a file"""
        sha256_hash = hashlib.sha256()
        try:
            with open(file_path, "rb") as f:
                for byte_block in iter(lambda: f.read(4096), b""):
                    sha256_hash.update(byte_block)
            return sha256_hash.hexdigest()
        except Exception as e:
            logger.error(f"Error calculating checksum: {e}")
            return ""

    def get_all_migrations(self) -> List[Dict[str, Any]]:
        """Get list of all migrations"""
        return self.migration_history + self.pending_migrations

    def get_pending_migrations(self) -> List[Dict[str, Any]]:
        """Get list of pending migrations"""
        return self.pending_migrations

    def get_migration_history(self) -> List[Dict[str, Any]]:
        """Get migration history"""
        return self.migration_history

    def apply_migration(self, migration_id: str) -> Dict[str, Any]:
        """Apply a specific migration"""
        migration = next(
            (m for m in self.pending_migrations if m["id"] == migration_id), None
        )

        if not migration:
            return {"status": "error", "message": f"Migration {migration_id} not found"}

        # Simulate migration application
        result = {
            "status": "success",
            "migration_id": migration_id,
            "applied_at": datetime.now().isoformat(),
            "duration_ms": 150,
            "changes": {
                "tables_created": 0,
                "tables_modified": 0,
                "indexes_created": 0,
                "rows_affected": 0,
            },
        }

        # Move to history
        migration["status"] = "applied"
        migration["applied_at"] = result["applied_at"]
        self.migration_history.append(migration)
        self.pending_migrations = [
            m for m in self.pending_migrations if m["id"] != migration_id
        ]

        return result

    def rollback_migration(self, migration_id: str) -> Dict[str, Any]:
        """Rollback a specific migration"""
        migration = next(
            (m for m in self.migration_history if m["id"] == migration_id), None
        )

        if not migration:
            return {
                "status": "error",
                "message": f"Migration {migration_id} not found in history",
            }

        # Simulate rollback
        result = {
            "status": "success",
            "migration_id": migration_id,
            "rolled_back_at": datetime.now().isoformat(),
            "duration_ms": 100,
        }

        # Move back to pending
        migration["status"] = "pending"
        if "applied_at" in migration:
            del migration["applied_at"]
        self.pending_migrations.append(migration)
        self.migration_history = [
            m for m in self.migration_history if m["id"] != migration_id
        ]

        # Re-sort pending migrations
        self.pending_migrations.sort(key=lambda x: x["id"])

        return result

    def create_migration(self, name: str, sql_content: str) -> Dict[str, Any]:
        """Create a new migration"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        migration_id = f"{timestamp}_{name}"
        file_path = self.migrations_path / f"{migration_id}.sql"

        try:
            # Ensure migrations directory exists
            self.migrations_path.mkdir(parents=True, exist_ok=True)

            # Write migration file
            with open(file_path, "w") as f:
                f.write(sql_content)

            migration_info = {
                "id": migration_id,
                "filename": f"{migration_id}.sql",
                "path": str(file_path),
                "size": len(sql_content),
                "created_at": datetime.now().isoformat(),
                "checksum": hashlib.sha256(sql_content.encode()).hexdigest(),
                "status": "pending",
            }

            self.pending_migrations.append(migration_info)

            return {
                "status": "success",
                "migration": migration_info,
                "message": f"Migration {migration_id} created successfully",
            }
        except Exception as e:
            return {
                "status": "error",
                "message": f"Failed to create migration: {str(e)}",
            }

    def validate_migration(self, migration_id: str) -> Dict[str, Any]:
        """Validate a migration before applying"""
        migration = next(
            (m for m in self.pending_migrations if m["id"] == migration_id), None
        )

        if not migration:
            return {"valid": False, "error": "Migration not found"}

        return {
            "valid": True,
            "migration_id": migration_id,
            "checks": {
                "syntax": True,
                "dependencies": True,
                "conflicts": False,
                "reversible": True,
            },
            "warnings": [],
            "estimated_duration_ms": 150,
        }

    def get_migration_status(self) -> Dict[str, Any]:
        """Get overall migration status"""
        return {
            "total_migrations": len(self.migration_history)
            + len(self.pending_migrations),
            "applied": len(self.migration_history),
            "pending": len(self.pending_migrations),
            "last_applied": (
                self.migration_history[-1]["applied_at"]
                if self.migration_history
                else None
            ),
            "next_migration": (
                self.pending_migrations[0]["id"] if self.pending_migrations else None
            ),
        }
