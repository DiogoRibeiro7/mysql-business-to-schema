#!/usr/bin/env python3
"""MySQL Migration CLI - Command-line interface for database migrations."""

import click
import mysql.connector
import json
import sys
from pathlib import Path
from datetime import datetime
from typing import Optional, Dict, Any
import logging
from tabulate import tabulate

from .core import MigrationRunner, MigrationHistory
from .generator import MigrationGenerator, SchemaInspector, SchemaDiffer
from .validator import MigrationValidator

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# Configuration file handling
CONFIG_FILE = ".migration-config.json"


def load_config() -> Dict[str, Any]:
    """Load configuration from file."""
    if Path(CONFIG_FILE).exists():
        with open(CONFIG_FILE, "r") as f:
            return json.load(f)
    return {}


def save_config(config: Dict[str, Any]):
    """Save configuration to file."""
    with open(CONFIG_FILE, "w") as f:
        json.dump(config, f, indent=2)


def get_connection(
    config: Optional[Dict[str, Any]] = None
) -> mysql.connector.MySQLConnection:
    """Get database connection."""
    if not config:
        config = load_config()

    if not config:
        click.echo("No configuration found. Run 'migrate init' first.", err=True)
        sys.exit(1)

    try:
        return mysql.connector.connect(
            host=config.get("host", "localhost"),
            port=config.get("port", 3306),
            user=config["user"],
            password=config["password"],
            database=config["database"],
        )
    except mysql.connector.Error as e:
        click.echo(f"Failed to connect to database: {e}", err=True)
        sys.exit(1)


@click.group()
@click.option("--config", "-c", help="Configuration file path")
@click.pass_context
def cli(ctx, config):
    """Run the MySQL migration system."""
    ctx.ensure_object(dict)
    if config:
        ctx.obj["config_file"] = config


@cli.command()
@click.option("--host", "-h", default="localhost", help="Database host")
@click.option("--port", "-p", default=3306, help="Database port")
@click.option("--user", "-u", required=True, help="Database user")
@click.option(
    "--password", "-P", prompt=True, hide_input=True, help="Database password"
)
@click.option("--database", "-d", required=True, help="Database name")
@click.option("--migrations-path", default="migrations", help="Migrations directory")
def init(host, port, user, password, database, migrations_path):
    """Initialize migration system."""
    click.echo("🚀 Initializing migration system...")

    # Create configuration
    config = {
        "host": host,
        "port": port,
        "user": user,
        "password": password,
        "database": database,
        "migrations_path": migrations_path,
    }

    # Test connection
    try:
        conn = mysql.connector.connect(
            host=host, port=port, user=user, password=password, database=database
        )

        # Create migration history table
        MigrationHistory(conn)
        conn.close()

        click.echo("✅ Database connection successful")
    except mysql.connector.Error as e:
        click.echo(f"❌ Failed to connect to database: {e}", err=True)
        sys.exit(1)

    # Create migrations directory
    Path(migrations_path).mkdir(exist_ok=True)

    # Save configuration
    save_config(config)

    click.echo(f"✅ Created migrations directory: {migrations_path}")
    click.echo(f"✅ Saved configuration to {CONFIG_FILE}")
    click.echo("\nMigration system initialized successfully!")
    click.echo("\nNext steps:")
    click.echo(
        "  1. Create a migration: migrate generate --description 'Initial schema'"
    )
    click.echo("  2. Run migrations: migrate up")


@cli.command()
@click.option("--target", "-t", help="Target version to migrate to")
@click.option("--dry-run", is_flag=True, help="Preview migrations without executing")
@click.option("--force", "-f", is_flag=True, help="Skip confirmation")
def up(target, dry_run, force):
    """Run pending migrations."""
    config = load_config()
    conn = get_connection(config)

    runner = MigrationRunner(conn, config.get("migrations_path", "migrations"))

    # Get status
    status = runner.get_status()

    if status["pending_migrations"] == 0:
        click.echo("✅ No pending migrations")
        return

    click.echo(f"\n📋 Found {status['pending_migrations']} pending migrations:")

    # List pending migrations
    pending = runner.history.get_pending_migrations(runner.discover_migrations())
    for migration in pending:
        click.echo(f"  • {migration.version}: {migration.description}")

    if not dry_run and not force:
        if not click.confirm("\nDo you want to run these migrations?"):
            click.echo("Aborted.")
            return

    # Run migrations
    click.echo("\n🚀 Running migrations...")

    results = runner.run_migrations(target_version=target, dry_run=dry_run)

    if results["success"]:
        if dry_run:
            click.echo("\n✅ Dry run completed successfully")
        else:
            click.echo(
                f"\n✅ Successfully ran {len(results['migrations_run'])} migrations"
            )
            for version in results["migrations_run"]:
                click.echo(f"  ✓ {version}")
    else:
        click.echo("\n❌ Migration failed!", err=True)
        for error in results["errors"]:
            click.echo(f"  • {error}", err=True)
        sys.exit(1)

    conn.close()


@cli.command()
@click.option("--target", "-t", help="Target version to rollback to")
@click.option("--steps", "-s", type=int, help="Number of migrations to rollback")
@click.option("--force", "-f", is_flag=True, help="Skip confirmation")
def down(target, steps, force):
    """Rollback migrations."""
    config = load_config()
    conn = get_connection(config)

    runner = MigrationRunner(conn, config.get("migrations_path", "migrations"))

    # Get applied migrations
    history = MigrationHistory(conn)
    applied = history.get_applied_migrations()

    if not applied:
        click.echo("No migrations to rollback")
        return

    # Determine what to rollback
    if steps:
        to_rollback = applied[-steps:] if steps <= len(applied) else applied
        click.echo(f"\n📋 Will rollback {len(to_rollback)} migration(s):")
    elif target:
        to_rollback = [m for m in applied if m["version"] > target]
        click.echo(f"\n📋 Will rollback to version {target}:")
    else:
        to_rollback = [applied[-1]]
        click.echo("\n📋 Will rollback last migration:")

    for migration in to_rollback:
        click.echo(f"  • {migration['version']}: {migration['description']}")

    if not force:
        if not click.confirm("\n⚠️  This will rollback the database. Continue?"):
            click.echo("Aborted.")
            return

    # Perform rollback
    click.echo("\n🔄 Rolling back migrations...")

    results = runner.rollback(target_version=target)

    if results["success"]:
        click.echo(
            f"\n✅ Successfully rolled back {len(results['migrations_rolled_back'])} migrations"
        )
        for version in results["migrations_rolled_back"]:
            click.echo(f"  ✓ {version}")
    else:
        click.echo("\n❌ Rollback failed!", err=True)
        for error in results["errors"]:
            click.echo(f"  • {error}", err=True)
        sys.exit(1)

    conn.close()


@cli.command()
def status():
    """Show migration status."""
    config = load_config()
    conn = get_connection(config)

    runner = MigrationRunner(conn, config.get("migrations_path", "migrations"))
    status = runner.get_status()

    click.echo("\n📊 Migration Status")
    click.echo("=" * 50)
    click.echo(f"Total migrations:   {status['total_migrations']}")
    click.echo(f"Applied migrations: {status['applied_migrations']}")
    click.echo(f"Pending migrations: {status['pending_migrations']}")

    if status["last_migration"]:
        last = status["last_migration"]
        click.echo("\nLast migration:")
        click.echo(f"  Version:     {last['version']}")
        click.echo(f"  Description: {last['description']}")
        click.echo(f"  Applied:     {last['applied_at']}")
        click.echo(f"  By:          {last['applied_by']}")

    if status["pending_migrations"] > 0:
        click.echo("\nPending migrations:")
        for version in status["pending_versions"][:5]:
            click.echo(f"  • {version}")
        if len(status["pending_versions"]) > 5:
            click.echo(f"  ... and {len(status['pending_versions']) - 5} more")

    conn.close()


@cli.command()
@click.option(
    "--limit", "-n", type=int, default=10, help="Number of migrations to show"
)
@click.option("--all", "-a", is_flag=True, help="Show all migrations")
def history(limit, all):
    """Show migration history."""
    config = load_config()
    conn = get_connection(config)

    history = MigrationHistory(conn)
    migrations = history.get_applied_migrations()

    if not migrations:
        click.echo("No migrations have been applied yet")
        return

    if not all and len(migrations) > limit:
        migrations = migrations[-limit:]
        click.echo(f"\n📜 Last {limit} migrations:")
    else:
        click.echo(f"\n📜 Migration history ({len(migrations)} total):")

    # Prepare table data
    table_data = []
    for m in migrations:
        table_data.append(
            [
                m["version"],
                (
                    m["description"][:40] + "..."
                    if len(m["description"]) > 40
                    else m["description"]
                ),
                m["applied_at"],
                m.get("execution_time", "N/A"),
                m["status"],
            ]
        )

    headers = ["Version", "Description", "Applied At", "Time (s)", "Status"]
    click.echo(tabulate(table_data, headers=headers, tablefmt="grid"))

    conn.close()


@cli.command()
@click.option("--description", "-d", required=True, help="Migration description")
@click.option(
    "--type",
    "-t",
    type=click.Choice(["auto", "sql", "python"]),
    default="auto",
    help="Migration type",
)
@click.option("--from-file", "-f", help="Generate from SQL file")
@click.option("--include-rollback", is_flag=True, help="Generate rollback script")
def generate(description, type, from_file, include_rollback):
    """Generate a new migration."""
    config = load_config()
    generator = MigrationGenerator(config.get("migrations_path", "migrations"))

    if from_file:
        # Generate from SQL file
        sql_file = Path(from_file)
        if not sql_file.exists():
            click.echo(f"❌ File not found: {from_file}", err=True)
            sys.exit(1)

        version, filename = generator.generate_from_sql_file(
            sql_file, description, include_rollback
        )
    elif type == "auto":
        # Auto-generate from schema differences
        click.echo("🔍 Analyzing schema differences...")

        conn = get_connection(config)
        inspector = SchemaInspector(conn)

        # Get current schema
        inspector.get_schema()

        # TODO: Get target schema from models or schema files
        click.echo("⚠️  Auto-generation from models not yet implemented")
        click.echo("Use --from-file to generate from SQL file")
        conn.close()
        return
    else:
        # Create empty migration template
        version = generator._generate_version()
        filename = generator._generate_filename(version, description)
        file_path = Path(config.get("migrations_path", "migrations")) / filename

        if type == "sql":
            template = f"""-- Migration: {description}
-- Generated: {datetime.now().isoformat()}

-- ============================================
-- UP MIGRATION
-- ============================================

-- TODO: Add your up migration SQL here


-- ============================================
-- ==== ROLLBACK ====
-- ============================================

-- TODO: Add your rollback SQL here (optional)
"""
        else:  # python
            template = f'''"""
Migration: {description}
Generated: {datetime.now().isoformat()}
"""

def up(connection):
    """Execute forward migration."""
    cursor = connection.cursor()

    # TODO: Add your migration logic here

    cursor.close()
    connection.commit()


def down(connection):
    """Execute rollback migration."""
    cursor = connection.cursor()

    # TODO: Add your rollback logic here

    cursor.close()
    connection.commit()
'''

        with open(file_path, "w") as f:
            f.write(template)

    click.echo(f"✅ Generated migration: {filename}")
    click.echo(
        f"   Edit the file at: {config.get('migrations_path', 'migrations')}/{filename}"
    )


@cli.command()
@click.option("--production", is_flag=True, help="Use production validation rules")
def validate(production):
    """Validate all migrations."""
    config = load_config()
    conn = get_connection(config)

    runner = MigrationRunner(conn, config.get("migrations_path", "migrations"))
    validator = MigrationValidator()

    click.echo("🔍 Validating migrations...")

    # Validate migration consistency
    results = runner.validate_migrations()

    if results["valid"]:
        click.echo("✅ All migrations are valid")
    else:
        click.echo("❌ Validation failed!", err=True)
        for issue in results["issues"]:
            click.echo(f"  • {issue}", err=True)

    # Validate individual migrations
    migrations = runner.discover_migrations()
    all_valid = True

    for migration in migrations:
        is_valid, errors, warnings = validator.validate_migration(
            migration.up_script, migration.down_script, production_mode=production
        )

        if not is_valid:
            all_valid = False
            click.echo(f"\n❌ {migration.version}: {migration.description}")
            for error in errors:
                click.echo(f"  ERROR: {error}", err=True)

        if warnings:
            click.echo(f"\n⚠️  {migration.version}: {migration.description}")
            for warning in warnings:
                click.echo(f"  WARNING: {warning}")

    if all_valid:
        click.echo("\n✅ All migrations passed validation")
    else:
        sys.exit(1)

    conn.close()


@cli.command()
@click.argument("version")
def show(version):
    """Show details of a specific migration."""
    config = load_config()
    conn = get_connection(config)

    runner = MigrationRunner(conn, config.get("migrations_path", "migrations"))
    migrations = runner.discover_migrations()

    migration = next((m for m in migrations if m.version == version), None)

    if not migration:
        click.echo(f"❌ Migration {version} not found", err=True)
        sys.exit(1)

    click.echo(f"\n📄 Migration: {migration.version}")
    click.echo("=" * 50)
    click.echo(f"Description: {migration.description}")
    click.echo(f"Type:        {migration.type.value}")
    click.echo(f"Filename:    {migration.filename}")
    click.echo(f"Checksum:    {migration.checksum}")

    # Check if applied
    history = MigrationHistory(conn)
    if history.is_applied(version):
        applied = next(
            (m for m in history.get_applied_migrations() if m["version"] == version),
            None,
        )
        if applied:
            click.echo("\n✅ Applied")
            click.echo(f"Applied at:  {applied['applied_at']}")
            click.echo(f"Applied by:  {applied['applied_by']}")
            click.echo(f"Exec time:   {applied.get('execution_time', 'N/A')} seconds")
    else:
        click.echo("\n⏳ Pending")
    # Show SQL preview
    if migration.type.value == "sql":
        click.echo("\n📝 Up Migration:")
        click.echo("-" * 40)
        lines = migration.up_script.split("\n")
        for line in lines[:20]:
            click.echo(line)
        if len(lines) > 20:
            click.echo(f"... ({len(lines) - 20} more lines)")

        if migration.down_script:
            click.echo("\n🔄 Rollback Migration:")
            click.echo("-" * 40)
            lines = migration.down_script.split("\n")
            for line in lines[:20]:
                click.echo(line)
            if len(lines) > 20:
                click.echo(f"... ({len(lines) - 20} more lines)")

    conn.close()


@cli.command()
@click.option("--source", "-s", required=True, help="Source database")
@click.option("--target", "-t", required=True, help="Target database")
@click.option("--output", "-o", help="Output migration file")
def diff(source, target, output):
    """Generate migration from database differences."""
    config = load_config()

    # Connect to source database
    source_config = config.copy()
    source_config["database"] = source
    source_conn = mysql.connector.connect(**source_config)

    # Connect to target database
    target_config = config.copy()
    target_config["database"] = target
    target_conn = mysql.connector.connect(**target_config)

    # Get schemas
    inspector = SchemaInspector(source_conn)
    source_schema = inspector.get_schema(source)

    inspector = SchemaInspector(target_conn)
    target_schema = inspector.get_schema(target)

    # Compare schemas
    differ = SchemaDiffer()
    differences = differ.compare_schemas(source_schema, target_schema)

    if not differences:
        click.echo("✅ No differences found between databases")
        return

    click.echo(f"\n📊 Found {len(differences)} differences:")

    for diff in differences[:10]:
        click.echo(f"  • {diff['type']}: ", nl=False)
        if "table" in diff:
            click.echo(f"{diff['table']}", nl=False)
        if "column" in diff:
            click.echo(f".{diff['column']}", nl=False)
        if "index" in diff:
            click.echo(f" (index: {diff['index']})", nl=False)
        click.echo()

    if len(differences) > 10:
        click.echo(f"  ... and {len(differences) - 10} more")

    if output or click.confirm("\nGenerate migration file?"):
        generator = MigrationGenerator(config.get("migrations_path", "migrations"))
        description = f"Sync {source} to {target}"

        version, filename = generator.generate_migration(differences, description)

        if output:
            # Move to specified output file
            import shutil

            shutil.move(
                Path(config.get("migrations_path", "migrations")) / filename, output
            )
            click.echo(f"✅ Generated migration: {output}")
        else:
            click.echo(f"✅ Generated migration: {filename}")

    source_conn.close()
    target_conn.close()


@cli.command()
@click.argument("version")
@click.option("--force", "-f", is_flag=True, help="Force repair without confirmation")
def repair(version, force):
    """Repair a failed migration."""
    config = load_config()
    conn = get_connection(config)

    history = MigrationHistory(conn)

    # Check migration status
    applied = history.get_applied_migrations()
    migration_record = next((m for m in applied if m["version"] == version), None)

    if not migration_record:
        click.echo(f"❌ Migration {version} not found in history", err=True)
        sys.exit(1)

    if migration_record["status"] != "failed":
        click.echo(
            f"Migration {version} is not in failed state (status: {migration_record['status']})"
        )
        return

    click.echo(f"\n⚠️  Migration {version} is in failed state")

    if not force:
        click.echo("\nOptions:")
        click.echo("  1. Mark as completed (if manually fixed)")
        click.echo("  2. Remove from history (to retry)")
        click.echo("  3. Cancel")

        choice = click.prompt("Choose option", type=int)

        if choice == 1:
            # Mark as completed
            cursor = conn.cursor()
            cursor.execute(
                """
                UPDATE schema_migrations
                SET status = 'completed'
                WHERE version = %s
            """,
                (version,),
            )
            conn.commit()
            cursor.close()
            click.echo("✅ Marked migration as completed")

        elif choice == 2:
            # Remove from history
            cursor = conn.cursor()
            cursor.execute(
                """
                DELETE FROM schema_migrations
                WHERE version = %s
            """,
                (version,),
            )
            conn.commit()
            cursor.close()
            click.echo("✅ Removed migration from history")
            click.echo("You can now retry the migration with 'migrate up'")

    conn.close()


if __name__ == "__main__":
    cli()
