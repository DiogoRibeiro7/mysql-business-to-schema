#!/usr/bin/env python3
"""MySQL Migration CLI Tool.

A comprehensive command-line interface for database migrations
"""

import os
import sys
import argparse
import json
import logging
from pathlib import Path
from datetime import datetime
import colorama
from colorama import Fore, Style

from migration_system.migration_manager import MigrationManager, DatabaseType

# Initialize colorama for cross-platform colored output
colorama.init()

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


class MigrationCLI:
    """Command-line interface for database migrations."""

    def __init__(self):
        """Initialize the instance."""
        self.manager = None
        self.migrations_dir = "migrations"

        # Color scheme
        self.colors = {
            "success": Fore.GREEN,
            "error": Fore.RED,
            "warning": Fore.YELLOW,
            "info": Fore.CYAN,
            "header": Fore.BLUE + Style.BRIGHT,
            "reset": Style.RESET_ALL,
        }

    def print_colored(self, message: str, color_type: str = "info"):
        """Print colored output."""
        color = self.colors.get(color_type, self.colors["info"])
        print(f"{color}{message}{self.colors['reset']}")

    def print_header(self, title: str):
        """Print a formatted header."""
        self.print_colored("\n" + "=" * 70, "header")
        self.print_colored(title.center(70), "header")
        self.print_colored("=" * 70 + "\n", "header")

    def create_migration(self, args):
        """Create a new migration."""
        self.print_header("CREATE MIGRATION")

        # Validate inputs
        if not os.path.exists(args.source):
            self.print_colored(f"Error: Source file '{args.source}' not found", "error")
            return False

        # Initialize manager
        self.manager = MigrationManager(args.output or self.migrations_dir)

        try:
            # Determine source and target database types
            source_type = DatabaseType(args.source_type.lower())
            target_type = DatabaseType(args.target.lower())

            self.print_colored(f"Source: {args.source}", "info")
            self.print_colored(f"Source Type: {source_type.value}", "info")
            self.print_colored(f"Target Type: {target_type.value}", "info")
            self.print_colored(f"Migration Name: {args.name}", "info")
            print()

            # Create migration
            self.print_colored("Creating migration...", "info")
            migration = self.manager.create_migration(
                name=args.name,
                source_file=args.source,
                source_type=source_type,
                target_type=target_type,
            )

            # Display results
            self.print_colored(
                f"\n[SUCCESS] Migration created: {migration.id}", "success"
            )
            self.print_colored(f"Checksum: {migration.checksum}", "info")

            output_dir = Path(args.output or self.migrations_dir)
            self.print_colored("\nGenerated files:", "info")
            self.print_colored(
                f"  Up script:   {output_dir}/up/{migration.id}.sql", "success"
            )
            self.print_colored(
                f"  Down script: {output_dir}/down/{migration.id}_rollback.sql",
                "success",
            )
            self.print_colored(
                f"  Metadata:    {output_dir}/{migration.id}.json", "success"
            )

            # Show preview if requested
            if args.preview:
                self.print_colored("\nMigration Preview (first 50 lines):", "header")
                lines = migration.up_script.split("\n")[:50]
                for line in lines:
                    print(f"  {line}")
                if len(migration.up_script.split("\n")) > 50:
                    self.print_colored("  ... (truncated)", "warning")

            return True

        except Exception as e:
            self.print_colored(f"Error creating migration: {e}", "error")
            logger.exception("Migration creation failed")
            return False

    def list_migrations(self, args):
        """List all migrations."""
        self.print_header("MIGRATION LIST")

        # Initialize manager
        migrations_dir = args.dir or self.migrations_dir
        self.manager = MigrationManager(migrations_dir)

        try:
            migrations = self.manager.list_migrations()

            if not migrations:
                self.print_colored("No migrations found", "warning")
                return True

            # Sort by date
            migrations.sort(key=lambda x: x.get("created_at", ""), reverse=True)

            # Display migrations
            self.print_colored(
                f"Found {len(migrations)} migration(s) in '{migrations_dir}':\n", "info"
            )

            # Table header
            print(f"{'ID':<35} {'Name':<25} {'Source->Target':<20} {'Status':<10}")
            print("-" * 90)

            # Table rows
            for m in migrations:
                migration_id = m["id"][:35]
                name = m["name"][:25]
                path = f"{m['source_type']}->{m['target_type']}"
                status = m["status"]

                # Color code by status
                if status == "completed":
                    status_color = self.colors["success"]
                elif status == "failed":
                    status_color = self.colors["error"]
                else:
                    status_color = self.colors["warning"]

                print(
                    f"{migration_id:<35} {name:<25} {path:<20} {status_color}{status:<10}{self.colors['reset']}"
                )

            # Summary
            print("\n" + "-" * 90)
            pending = sum(1 for m in migrations if m["status"] == "pending")
            completed = sum(1 for m in migrations if m["status"] == "completed")
            failed = sum(1 for m in migrations if m["status"] == "failed")

            summary = f"Total: {len(migrations)} | Pending: {pending} | Completed: {completed} | Failed: {failed}"
            self.print_colored(summary, "info")

            return True

        except Exception as e:
            self.print_colored(f"Error listing migrations: {e}", "error")
            return False

    def show_migration(self, args):
        """Show details of a specific migration."""
        self.print_header("MIGRATION DETAILS")

        # Initialize manager
        migrations_dir = args.dir or self.migrations_dir
        self.manager = MigrationManager(migrations_dir)

        try:
            # Load migration metadata
            metadata_file = Path(migrations_dir) / f"{args.id}.json"

            if not metadata_file.exists():
                self.print_colored(f"Migration '{args.id}' not found", "error")
                return False

            with open(metadata_file, "r") as f:
                metadata = json.load(f)

            # Display metadata
            self.print_colored("Migration Metadata:", "header")
            for key, value in metadata.items():
                if key != "up_script" and key != "down_script":
                    print(f"  {key:20}: {value}")

            # Show file paths
            self.print_colored("\nMigration Files:", "header")
            up_file = Path(migrations_dir) / "up" / f"{args.id}.sql"
            down_file = Path(migrations_dir) / "down" / f"{args.id}_rollback.sql"

            print(f"  Up script:   {up_file} ", end="")
            if up_file.exists():
                size = up_file.stat().st_size
                self.print_colored(f"({size:,} bytes)", "success")
            else:
                self.print_colored("[NOT FOUND]", "error")

            print(f"  Down script: {down_file} ", end="")
            if down_file.exists():
                size = down_file.stat().st_size
                self.print_colored(f"({size:,} bytes)", "success")
            else:
                self.print_colored("[NOT FOUND]", "error")

            # Show content preview if requested
            if args.show_sql:
                if up_file.exists():
                    self.print_colored(
                        "\nUp Script Preview (first 50 lines):", "header"
                    )
                    with open(up_file, "r", encoding="utf-8") as f:
                        lines = f.readlines()[:50]
                        for line in lines:
                            print(f"  {line.rstrip()}")
                        if len(lines) == 50:
                            self.print_colored("  ... (truncated)", "warning")

            return True

        except Exception as e:
            self.print_colored(f"Error showing migration: {e}", "error")
            return False

    def validate_migration(self, args):
        """Validate a migration script."""
        self.print_header("VALIDATE MIGRATION")

        migrations_dir = args.dir or self.migrations_dir
        up_file = Path(migrations_dir) / "up" / f"{args.id}.sql"

        if not up_file.exists():
            self.print_colored(f"Migration file not found: {up_file}", "error")
            return False

        try:
            with open(up_file, "r", encoding="utf-8") as f:
                content = f.read()

            # Basic validation checks
            checks = {
                "Has CREATE statements": "CREATE" in content.upper(),
                "Has table definitions": "TABLE" in content.upper(),
                "No syntax errors (basic)": not (
                    "ERROR" in content.upper() or "FAIL" in content.upper()
                ),
                "Has proper endings": content.strip().endswith(";")
                or content.strip().endswith("//"),
                "UTF-8 encoded": True,  # Already validated by successful read
            }

            # Additional checks for specific target types
            if "postgresql" in args.id.lower():
                checks.update(
                    {
                        "PostgreSQL types": any(
                            t in content.upper() for t in ["SERIAL", "JSONB", "UUID"]
                        ),
                        "No MySQL specific": "ENGINE=" not in content.upper(),
                    }
                )
            elif "mongo" in args.id.lower():
                checks.update(
                    {
                        "MongoDB commands": "db." in content,
                        "Collection creation": "createCollection" in content,
                    }
                )

            # Display results
            self.print_colored(f"Validating: {up_file}\n", "info")

            all_passed = True
            for check, passed in checks.items():
                if passed:
                    self.print_colored(f"  [PASS] {check}", "success")
                else:
                    self.print_colored(f"  [FAIL] {check}", "error")
                    all_passed = False

            print()
            if all_passed:
                self.print_colored(
                    "Validation PASSED - Migration appears valid", "success"
                )
            else:
                self.print_colored(
                    "Validation FAILED - Review the migration script", "error"
                )

            return all_passed

        except Exception as e:
            self.print_colored(f"Error validating migration: {e}", "error")
            return False

    def batch_migrate(self, args):
        """Create migrations for multiple schemas."""
        self.print_header("BATCH MIGRATION")

        # Find all schema files
        schema_pattern = args.pattern or "example_*/schema/01_tables.sql"
        schema_files = list(Path(".").glob(schema_pattern))

        if not schema_files:
            self.print_colored(
                f"No schema files found matching '{schema_pattern}'", "warning"
            )
            return False

        self.print_colored(
            f"Found {len(schema_files)} schema file(s) to migrate\n", "info"
        )

        # Initialize manager
        self.manager = MigrationManager(args.output or self.migrations_dir)

        # Process each schema
        success_count = 0
        failed_count = 0
        target_type = DatabaseType(args.target.lower())

        for schema_file in schema_files:
            example_name = (
                schema_file.parts[0] if len(schema_file.parts) > 0 else "unknown"
            )

            try:
                self.print_colored(f"Processing: {example_name}", "info")

                migration = self.manager.create_migration(
                    name=f"{example_name}_to_{args.target}",
                    source_file=str(schema_file),
                    source_type=DatabaseType.MYSQL,
                    target_type=target_type,
                )

                self.print_colored(
                    f"  [SUCCESS] Created migration: {migration.id}", "success"
                )
                success_count += 1

            except Exception as e:
                self.print_colored(f"  [FAILED] Error: {e}", "error")
                failed_count += 1

        # Summary
        print("\n" + "-" * 70)
        self.print_colored("Batch Migration Complete:", "header")
        self.print_colored(f"  Successful: {success_count}", "success")
        if failed_count > 0:
            self.print_colored(f"  Failed: {failed_count}", "error")

        return failed_count == 0

    def export_migration(self, args):
        """Export migration to a single file."""
        self.print_header("EXPORT MIGRATION")

        migrations_dir = args.dir or self.migrations_dir
        up_file = Path(migrations_dir) / "up" / f"{args.id}.sql"
        down_file = Path(migrations_dir) / "down" / f"{args.id}_rollback.sql"
        metadata_file = Path(migrations_dir) / f"{args.id}.json"

        if not up_file.exists():
            self.print_colored(f"Migration '{args.id}' not found", "error")
            return False

        try:
            # Create export
            export_data = {
                "migration_id": args.id,
                "exported_at": datetime.now().isoformat(),
                "files": {},
            }

            # Load metadata
            if metadata_file.exists():
                with open(metadata_file, "r") as f:
                    export_data["metadata"] = json.load(f)

            # Load scripts
            with open(up_file, "r", encoding="utf-8") as f:
                export_data["files"]["up_script"] = f.read()

            if down_file.exists():
                with open(down_file, "r", encoding="utf-8") as f:
                    export_data["files"]["down_script"] = f.read()

            # Write export file
            output_file = args.output or f"{args.id}_export.json"
            with open(output_file, "w", encoding="utf-8") as f:
                json.dump(export_data, f, indent=2)

            self.print_colored(f"Migration exported to: {output_file}", "success")

            # Show file size
            size = Path(output_file).stat().st_size
            self.print_colored(f"Export size: {size:,} bytes", "info")

            return True

        except Exception as e:
            self.print_colored(f"Error exporting migration: {e}", "error")
            return False

    def clean_migrations(self, args):
        """Clean up old or failed migrations."""
        self.print_header("CLEAN MIGRATIONS")

        migrations_dir = Path(args.dir or self.migrations_dir)

        if not migrations_dir.exists():
            self.print_colored(
                f"Migrations directory not found: {migrations_dir}", "error"
            )
            return False

        try:
            # Count files
            up_files = list((migrations_dir / "up").glob("*.sql"))
            down_files = list((migrations_dir / "down").glob("*.sql"))
            metadata_files = list(migrations_dir.glob("*.json"))

            total_files = len(up_files) + len(down_files) + len(metadata_files)

            if total_files == 0:
                self.print_colored("No migration files to clean", "info")
                return True

            # Calculate size
            total_size = sum(
                f.stat().st_size for f in up_files + down_files + metadata_files
            )

            self.print_colored(
                f"Found {total_files} file(s) using {total_size:,} bytes", "info"
            )

            if not args.force:
                response = input(
                    f"\n{Fore.YELLOW}Are you sure you want to delete all migrations? (y/N): {Style.RESET_ALL}"
                )
                if response.lower() != "y":
                    self.print_colored("Cleanup cancelled", "warning")
                    return False

            # Delete files
            deleted = 0
            for f in up_files + down_files + metadata_files:
                f.unlink()
                deleted += 1

            self.print_colored(f"\nDeleted {deleted} file(s)", "success")
            self.print_colored(f"Freed {total_size:,} bytes", "info")

            return True

        except Exception as e:
            self.print_colored(f"Error cleaning migrations: {e}", "error")
            return False


def main():
    """Run CLI entry point."""
    parser = argparse.ArgumentParser(
        description="MySQL Migration CLI - Manage database migrations",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    # Global options
    parser.add_argument(
        "-v", "--verbose", action="store_true", help="Enable verbose output"
    )
    parser.add_argument(
        "--no-color", action="store_true", help="Disable colored output"
    )

    # Create subparsers
    subparsers = parser.add_subparsers(dest="command", help="Available commands")

    # Create command
    create_parser = subparsers.add_parser("create", help="Create a new migration")
    create_parser.add_argument("name", help="Migration name")
    create_parser.add_argument("source", help="Source schema file")
    create_parser.add_argument(
        "target", choices=["postgresql", "mongodb"], help="Target database type"
    )
    create_parser.add_argument(
        "--source-type", default="mysql", choices=["mysql"], help="Source database type"
    )
    create_parser.add_argument("-o", "--output", help="Output directory")
    create_parser.add_argument(
        "-p", "--preview", action="store_true", help="Show migration preview"
    )

    # List command
    list_parser = subparsers.add_parser("list", help="List all migrations")
    list_parser.add_argument("-d", "--dir", help="Migrations directory")

    # Show command
    show_parser = subparsers.add_parser("show", help="Show migration details")
    show_parser.add_argument("id", help="Migration ID")
    show_parser.add_argument("-d", "--dir", help="Migrations directory")
    show_parser.add_argument(
        "-s", "--show-sql", action="store_true", help="Show SQL content"
    )

    # Validate command
    validate_parser = subparsers.add_parser("validate", help="Validate a migration")
    validate_parser.add_argument("id", help="Migration ID")
    validate_parser.add_argument("-d", "--dir", help="Migrations directory")

    # Batch command
    batch_parser = subparsers.add_parser(
        "batch", help="Create migrations for multiple schemas"
    )
    batch_parser.add_argument(
        "target", choices=["postgresql", "mongodb"], help="Target database type"
    )
    batch_parser.add_argument("-p", "--pattern", help="Schema file pattern (glob)")
    batch_parser.add_argument("-o", "--output", help="Output directory")

    # Export command
    export_parser = subparsers.add_parser("export", help="Export migration to file")
    export_parser.add_argument("id", help="Migration ID")
    export_parser.add_argument("-o", "--output", help="Output file")
    export_parser.add_argument("-d", "--dir", help="Migrations directory")

    # Clean command
    clean_parser = subparsers.add_parser("clean", help="Clean up migration files")
    clean_parser.add_argument("-d", "--dir", help="Migrations directory")
    clean_parser.add_argument(
        "-f", "--force", action="store_true", help="Skip confirmation"
    )

    # Parse arguments
    args = parser.parse_args()

    # Disable colors if requested
    if args.no_color:
        colorama.init(strip=True, convert=False)

    # Set logging level
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)

    # Create CLI instance
    cli = MigrationCLI()

    # Execute command
    if args.command == "create":
        success = cli.create_migration(args)
    elif args.command == "list":
        success = cli.list_migrations(args)
    elif args.command == "show":
        success = cli.show_migration(args)
    elif args.command == "validate":
        success = cli.validate_migration(args)
    elif args.command == "batch":
        success = cli.batch_migrate(args)
    elif args.command == "export":
        success = cli.export_migration(args)
    elif args.command == "clean":
        success = cli.clean_migrations(args)
    else:
        parser.print_help()
        success = False

    # Exit with appropriate code
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
