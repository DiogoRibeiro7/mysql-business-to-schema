#!/usr/bin/env python3
"""Database Migration CLI Tool.

A command-line interface for managing database migrations between different systems.
Supports MySQL to PostgreSQL and MySQL to MongoDB migrations.
"""

import os
import sys
import argparse
import json
from datetime import datetime
from tabulate import tabulate
import colorama
from colorama import Fore, Style

from migration_system.migration_manager import MigrationManager, DatabaseType
from migration_system.migration_executor import MigrationExecutor

# Initialize colorama for cross-platform colored output
colorama.init()


class MigrationCLI:
    """Command-line interface for database migrations."""

    def __init__(self):
        """Initialize the instance."""
        self.manager = MigrationManager()
        self.executor = MigrationExecutor()

    def create_migration(self, args):
        """Create a new migration."""
        print(f"{Fore.CYAN}Creating migration...{Style.RESET_ALL}")

        # Validate source file exists
        if not os.path.exists(args.source):
            print(
                f"{Fore.RED}Error: Source file not found: {args.source}{Style.RESET_ALL}"
            )
            return 1

        try:
            # Create the migration
            migration = self.manager.create_migration(
                name=args.name,
                source_file=args.source,
                source_type=DatabaseType(args.source_type),
                target_type=DatabaseType(args.target_type),
            )

            print(f"{Fore.GREEN}✓ Migration created successfully!{Style.RESET_ALL}")
            print(f"\nMigration ID: {Fore.YELLOW}{migration.id}{Style.RESET_ALL}")
            print(f"Source: {args.source_type} → Target: {args.target_type}")
            print("\nGenerated files:")
            print(f"  • Up script:   migrations/up/{migration.id}.sql")
            print(f"  • Down script: migrations/down/{migration.id}_rollback.sql")
            print(f"  • Metadata:    migrations/{migration.id}.json")

            if args.preview:
                print(
                    f"\n{Fore.CYAN}Preview of up script (first 20 lines):{Style.RESET_ALL}"
                )
                print("-" * 60)
                lines = migration.up_script.split("\n")[:20]
                for line in lines:
                    print(line)
                if len(migration.up_script.split("\n")) > 20:
                    print("... (truncated)")

            return 0

        except Exception as e:
            print(f"{Fore.RED}Error creating migration: {e}{Style.RESET_ALL}")
            return 1

    def list_migrations(self, args):
        """List all migrations."""
        migrations = self.manager.list_migrations()

        if not migrations:
            print(f"{Fore.YELLOW}No migrations found{Style.RESET_ALL}")
            return 0

        # Prepare data for table
        table_data = []
        for m in migrations:
            status = m["status"]
            # Color code status
            if status == "completed":
                status_colored = f"{Fore.GREEN}{status}{Style.RESET_ALL}"
            elif status == "failed":
                status_colored = f"{Fore.RED}{status}{Style.RESET_ALL}"
            elif status == "in_progress":
                status_colored = f"{Fore.YELLOW}{status}{Style.RESET_ALL}"
            else:
                status_colored = status

            created = datetime.fromisoformat(m["created_at"]).strftime("%Y-%m-%d %H:%M")

            table_data.append(
                [
                    m["id"][:40] + "..." if len(m["id"]) > 40 else m["id"],
                    m["name"],
                    f"{m['source_type']} → {m['target_type']}",
                    status_colored,
                    created,
                ]
            )

        headers = ["Migration ID", "Name", "Type", "Status", "Created"]
        print(f"\n{Fore.CYAN}Available Migrations:{Style.RESET_ALL}")
        print(tabulate(table_data, headers=headers, tablefmt="grid"))

        # Summary
        total = len(migrations)
        completed = sum(1 for m in migrations if m["status"] == "completed")
        failed = sum(1 for m in migrations if m["status"] == "failed")
        pending = sum(1 for m in migrations if m["status"] == "pending")

        print(
            f"\nTotal: {total} | "
            f"{Fore.GREEN}Completed: {completed}{Style.RESET_ALL} | "
            f"{Fore.YELLOW}Pending: {pending}{Style.RESET_ALL} | "
            f"{Fore.RED}Failed: {failed}{Style.RESET_ALL}"
        )

        return 0

    def execute_migration(self, args):
        """Execute a migration."""
        print(f"{Fore.CYAN}Executing migration: {args.migration_id}{Style.RESET_ALL}")

        # Check if migration exists
        status = self.manager.get_migration_status(args.migration_id)
        if status is None:
            print(f"{Fore.RED}Error: Migration not found{Style.RESET_ALL}")
            return 1

        # Prepare connection parameters
        connection_params = {
            "host": args.host,
            "port": args.port,
            "user": args.user,
            "password": args.password,
            "database": args.database,
        }

        # Remove None values
        connection_params = {
            k: v for k, v in connection_params.items() if v is not None
        }

        if args.dry_run:
            print(f"{Fore.YELLOW}DRY RUN - No changes will be made{Style.RESET_ALL}")
            # Load and display the migration script
            up_script_file = os.path.join(
                "migrations", "up", f"{args.migration_id}.sql"
            )
            if os.path.exists(up_script_file):
                with open(up_script_file, "r") as f:
                    script = f.read()
                print(f"\n{Fore.CYAN}Migration script:{Style.RESET_ALL}")
                print("-" * 60)
                lines = script.split("\n")[:50]
                for line in lines:
                    print(line)
                if len(script.split("\n")) > 50:
                    print("... (truncated)")
            return 0

        try:
            # Execute the migration
            result = self.executor.execute_migration(
                args.migration_id, connection_params
            )

            if result.success:
                print(
                    f"{Fore.GREEN}✓ Migration executed successfully!{Style.RESET_ALL}"
                )
                print(f"  Execution time: {result.execution_time:.2f} seconds")
                if result.rows_affected:
                    print(f"  Rows affected: {result.rows_affected}")
            else:
                print(f"{Fore.RED}✗ Migration failed!{Style.RESET_ALL}")
                print(f"  Error: {result.error_message}")
                return 1

        except Exception as e:
            print(f"{Fore.RED}Error executing migration: {e}{Style.RESET_ALL}")
            return 1

        return 0

    def rollback_migration(self, args):
        """Rollback a migration."""
        print(
            f"{Fore.YELLOW}Rolling back migration: {args.migration_id}{Style.RESET_ALL}"
        )

        # Check if migration exists
        status = self.manager.get_migration_status(args.migration_id)
        if status is None:
            print(f"{Fore.RED}Error: Migration not found{Style.RESET_ALL}")
            return 1

        # Prepare connection parameters
        connection_params = {
            "host": args.host,
            "port": args.port,
            "user": args.user,
            "password": args.password,
            "database": args.database,
        }

        # Remove None values
        connection_params = {
            k: v for k, v in connection_params.items() if v is not None
        }

        if not args.force:
            response = input(
                f"{Fore.YELLOW}Are you sure you want to rollback? (yes/no): {Style.RESET_ALL}"
            )
            if response.lower() != "yes":
                print("Rollback cancelled")
                return 0

        try:
            # Execute the rollback
            result = self.executor.rollback_migration(
                args.migration_id, connection_params
            )

            if result.success:
                print(
                    f"{Fore.GREEN}✓ Migration rolled back successfully!{Style.RESET_ALL}"
                )
            else:
                print(f"{Fore.RED}✗ Rollback failed!{Style.RESET_ALL}")
                print(f"  Error: {result.error_message}")
                return 1

        except Exception as e:
            print(f"{Fore.RED}Error rolling back migration: {e}{Style.RESET_ALL}")
            return 1

        return 0

    def show_migration(self, args):
        """Show details of a specific migration."""
        # Load migration metadata
        metadata_file = os.path.join("migrations", f"{args.migration_id}.json")
        if not os.path.exists(metadata_file):
            print(f"{Fore.RED}Error: Migration not found{Style.RESET_ALL}")
            return 1

        with open(metadata_file, "r") as f:
            metadata = json.load(f)

        # Display metadata
        print(f"\n{Fore.CYAN}Migration Details:{Style.RESET_ALL}")
        print("-" * 60)
        print(f"ID:           {metadata['id']}")
        print(f"Name:         {metadata['name']}")
        print(f"Source Type:  {metadata['source_type']}")
        print(f"Target Type:  {metadata['target_type']}")
        print(f"Status:       {metadata['status']}")
        print(f"Version:      {metadata['version']}")
        print(f"Checksum:     {metadata['checksum']}")
        print(f"Created At:   {metadata['created_at']}")

        if "executed_at" in metadata:
            print(f"Executed At:  {metadata['executed_at']}")
        if "execution_time" in metadata:
            print(f"Exec Time:    {metadata['execution_time']:.2f} seconds")
        if "error_message" in metadata:
            print(
                f"Error:        {Fore.RED}{metadata['error_message']}{Style.RESET_ALL}"
            )

        # Show script preview if requested
        if args.show_script:
            up_script_file = os.path.join(
                "migrations", "up", f"{args.migration_id}.sql"
            )
            if os.path.exists(up_script_file):
                with open(up_script_file, "r") as f:
                    script = f.read()
                print(f"\n{Fore.CYAN}Up Script:{Style.RESET_ALL}")
                print("-" * 60)
                print(script)

            if args.show_rollback:
                down_script_file = os.path.join(
                    "migrations", "down", f"{args.migration_id}_rollback.sql"
                )
                if os.path.exists(down_script_file):
                    with open(down_script_file, "r") as f:
                        script = f.read()
                    print(f"\n{Fore.CYAN}Rollback Script:{Style.RESET_ALL}")
                    print("-" * 60)
                    print(script)

        return 0


def main():
    """Run CLI entry point."""
    parser = argparse.ArgumentParser(
        description="Database Migration Tool - Migrate schemas between different database systems",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Create a migration from MySQL to PostgreSQL
  migrate.py create --name "user_tables" --source schema.sql --target-type postgresql

  # List all migrations
  migrate.py list

  # Execute a migration
  migrate.py execute --migration-id 20240218_123456_user_tables --database mydb --user postgres --password secret

  # Rollback a migration
  migrate.py rollback --migration-id 20240218_123456_user_tables --database mydb --user postgres --password secret

  # Show migration details
  migrate.py show --migration-id 20240218_123456_user_tables --show-script
        """,
    )

    subparsers = parser.add_subparsers(dest="command", help="Commands")

    # Create command
    create_parser = subparsers.add_parser("create", help="Create a new migration")
    create_parser.add_argument("--name", required=True, help="Migration name")
    create_parser.add_argument("--source", required=True, help="Source schema file")
    create_parser.add_argument(
        "--source-type",
        default="mysql",
        choices=["mysql", "postgresql"],
        help="Source database type (default: mysql)",
    )
    create_parser.add_argument(
        "--target-type",
        required=True,
        choices=["postgresql", "mongodb"],
        help="Target database type",
    )
    create_parser.add_argument(
        "--preview", action="store_true", help="Preview the generated migration script"
    )

    # List command
    _ = subparsers.add_parser("list", help="List all migrations")

    # Execute command
    execute_parser = subparsers.add_parser("execute", help="Execute a migration")
    execute_parser.add_argument("--migration-id", required=True, help="Migration ID")
    execute_parser.add_argument("--host", default="localhost", help="Database host")
    execute_parser.add_argument("--port", type=int, help="Database port")
    execute_parser.add_argument("--user", default="root", help="Database user")
    execute_parser.add_argument("--password", help="Database password")
    execute_parser.add_argument("--database", required=True, help="Target database")
    execute_parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be executed without making changes",
    )

    # Rollback command
    rollback_parser = subparsers.add_parser("rollback", help="Rollback a migration")
    rollback_parser.add_argument("--migration-id", required=True, help="Migration ID")
    rollback_parser.add_argument("--host", default="localhost", help="Database host")
    rollback_parser.add_argument("--port", type=int, help="Database port")
    rollback_parser.add_argument("--user", default="root", help="Database user")
    rollback_parser.add_argument("--password", help="Database password")
    rollback_parser.add_argument("--database", required=True, help="Target database")
    rollback_parser.add_argument(
        "--force", action="store_true", help="Skip confirmation prompt"
    )

    # Show command
    show_parser = subparsers.add_parser("show", help="Show migration details")
    show_parser.add_argument("--migration-id", required=True, help="Migration ID")
    show_parser.add_argument(
        "--show-script", action="store_true", help="Show the migration script"
    )
    show_parser.add_argument(
        "--show-rollback", action="store_true", help="Show the rollback script"
    )

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        return 1

    cli = MigrationCLI()

    # Execute the appropriate command
    if args.command == "create":
        return cli.create_migration(args)
    elif args.command == "list":
        return cli.list_migrations(args)
    elif args.command == "execute":
        return cli.execute_migration(args)
    elif args.command == "rollback":
        return cli.rollback_migration(args)
    elif args.command == "show":
        return cli.show_migration(args)

    return 0


if __name__ == "__main__":
    sys.exit(main())
