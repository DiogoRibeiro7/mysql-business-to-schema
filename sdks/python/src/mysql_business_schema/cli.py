"""
Command-line interface for MySQL Business-to-Schema SDK
"""

import click
import json
import sys
from pathlib import Path
from rich.console import Console
from rich.table import Table as RichTable
from rich.progress import track
from rich import print as rprint

from . import create_client, __version__
from .exceptions import MySQLSchemaError

console = Console()


@click.group()
@click.version_option(version=__version__)
@click.option("--host", default="localhost", help="API host")
@click.option("--port", default=8000, type=int, help="API port")
@click.option("--username", envvar="MYSQL_SCHEMA_USERNAME", help="Username")
@click.option("--password", envvar="MYSQL_SCHEMA_PASSWORD", help="Password")
@click.option("--api-key", envvar="MYSQL_SCHEMA_API_KEY", help="API key")
@click.pass_context
def cli(ctx, host, port, username, password, api_key):
    """MySQL Business-to-Schema CLI - Manage your database schemas."""
    ctx.ensure_object(dict)

    # Create client
    try:
        client = create_client(
            host=host,
            port=port,
            username=username,
            password=password,
            api_key=api_key
        )
        ctx.obj["client"] = client
    except Exception as e:
        console.print(f"[red]Failed to initialize client: {e}[/red]")
        sys.exit(1)


@cli.group()
def db():
    """Database management commands."""
    pass


@db.command("list")
@click.pass_context
def list_databases(ctx):
    """List all databases."""
    client = ctx.obj["client"]

    with console.status("Fetching databases..."):
        try:
            databases = client.list_databases()
        except MySQLSchemaError as e:
            console.print(f"[red]Error: {e}[/red]")
            return

    table = RichTable(title="Databases")
    table.add_column("Name", style="cyan")
    table.add_column("Tables", justify="right")
    table.add_column("Size (MB)", justify="right")
    table.add_column("Charset")
    table.add_column("Collation")

    for db in databases:
        table.add_row(
            db.name,
            str(db.table_count or 0),
            f"{db.size_mb or 0:.2f}",
            db.charset,
            db.collation
        )

    console.print(table)


@db.command("create")
@click.argument("name")
@click.option("--charset", default="utf8mb4", help="Character set")
@click.option("--collation", default="utf8mb4_unicode_ci", help="Collation")
@click.pass_context
def create_database(ctx, name, charset, collation):
    """Create a new database."""
    client = ctx.obj["client"]

    with console.status(f"Creating database '{name}'..."):
        try:
            db = client.create_database(name, charset, collation)
            console.print(f"[green]✓[/green] Database '{db.name}' created successfully")
        except MySQLSchemaError as e:
            console.print(f"[red]✗ Error: {e}[/red]")


@db.command("delete")
@click.argument("name")
@click.confirmation_option(prompt="Are you sure you want to delete this database?")
@click.pass_context
def delete_database(ctx, name):
    """Delete a database."""
    client = ctx.obj["client"]

    with console.status(f"Deleting database '{name}'..."):
        try:
            client.delete_database(name)
            console.print(f"[green]✓[/green] Database '{name}' deleted successfully")
        except MySQLSchemaError as e:
            console.print(f"[red]✗ Error: {e}[/red]")


@cli.group()
def migration():
    """Migration management commands."""
    pass


@migration.command("list")
@click.option("--status", type=click.Choice(["pending", "completed", "failed"]))
@click.pass_context
def list_migrations(ctx, status):
    """List migrations."""
    client = ctx.obj["client"]

    with console.status("Fetching migrations..."):
        try:
            migrations = client.list_migrations(status)
        except MySQLSchemaError as e:
            console.print(f"[red]Error: {e}[/red]")
            return

    table = RichTable(title="Migrations")
    table.add_column("Version", style="cyan")
    table.add_column("Description")
    table.add_column("Status")
    table.add_column("Applied By")
    table.add_column("Executed At")

    for m in migrations:
        status_color = {
            "pending": "yellow",
            "completed": "green",
            "failed": "red"
        }.get(m.status.value, "white")

        table.add_row(
            m.version,
            m.description[:50] + "..." if len(m.description) > 50 else m.description,
            f"[{status_color}]{m.status.value}[/{status_color}]",
            m.applied_by or "-",
            str(m.executed_at) if m.executed_at else "-"
        )

    console.print(table)


@migration.command("apply")
@click.option("--target", help="Target version")
@click.option("--dry-run", is_flag=True, help="Perform dry run")
@click.pass_context
def apply_migrations(ctx, target, dry_run):
    """Apply pending migrations."""
    client = ctx.obj["client"]

    with console.status("Applying migrations..." if not dry_run else "Running dry run..."):
        try:
            result = client.apply_migration(target, dry_run)
            if dry_run:
                console.print(f"[yellow]Dry run completed. Would apply: {result.version}[/yellow]")
            else:
                console.print(f"[green]✓[/green] Applied migration: {result.version}")
        except MySQLSchemaError as e:
            console.print(f"[red]✗ Error: {e}[/red]")


@migration.command("rollback")
@click.option("--steps", default=1, type=int, help="Number of migrations to rollback")
@click.option("--target", help="Target version to rollback to")
@click.confirmation_option(prompt="Are you sure you want to rollback?")
@click.pass_context
def rollback_migrations(ctx, steps, target):
    """Rollback migrations."""
    client = ctx.obj["client"]

    with console.status("Rolling back migrations..."):
        try:
            result = client.rollback_migration(target, steps)
            console.print(f"[green]✓[/green] Rolled back to: {result.version}")
        except MySQLSchemaError as e:
            console.print(f"[red]✗ Error: {e}[/red]")


@cli.group()
def data():
    """Data generation commands."""
    pass


@data.command("generate")
@click.argument("schema", type=click.Choice(["clinic", "ecommerce", "iot", "social_media"]))
@click.option("--rows", default=1000, type=int, help="Number of rows to generate")
@click.option("--format", default="sql", type=click.Choice(["sql", "csv", "json"]))
@click.option("--output", type=click.Path(), help="Output file path")
@click.pass_context
def generate_data(ctx, schema, rows, format, output):
    """Generate test data for a schema."""
    client = ctx.obj["client"]

    with console.status(f"Generating {rows} rows for {schema} schema..."):
        try:
            generator = client.get_data_generator()
            data = generator.generate(schema, rows, format)

            if output:
                output_path = Path(output)
                if format == "json":
                    output_path.write_text(data)
                elif format == "csv":
                    for table_name, csv_data in data.items():
                        table_path = output_path.parent / f"{output_path.stem}_{table_name}.csv"
                        table_path.write_text(csv_data)
                else:
                    output_path.write_text(data)
                console.print(f"[green]✓[/green] Data saved to {output_path}")
            else:
                console.print(data if format != "csv" else "CSV data generated")

        except MySQLSchemaError as e:
            console.print(f"[red]✗ Error: {e}[/red]")


@cli.group()
def query():
    """Query execution commands."""
    pass


@query.command("execute")
@click.argument("sql")
@click.option("--database", "-d", required=True, help="Database name")
@click.option("--limit", type=int, help="Result limit")
@click.pass_context
def execute_query(ctx, sql, database, limit):
    """Execute a SQL query."""
    client = ctx.obj["client"]

    with console.status("Executing query..."):
        try:
            result = client.execute_query(sql, database, limit)

            # Display results in a table
            if result.rows:
                table = RichTable(title=f"Query Results ({result.row_count} rows)")
                for col in result.columns:
                    table.add_column(col)

                for row in result.rows[:20]:  # Show first 20 rows
                    table.add_row(*[str(val) for val in row])

                console.print(table)

                if result.row_count > 20:
                    console.print(f"[yellow]... and {result.row_count - 20} more rows[/yellow]")
            else:
                console.print("[yellow]Query executed successfully. No results returned.[/yellow]")

            console.print(f"[dim]Execution time: {result.execution_time:.3f}s[/dim]")

        except MySQLSchemaError as e:
            console.print(f"[red]✗ Error: {e}[/red]")


@cli.group()
def backup():
    """Backup management commands."""
    pass


@backup.command("list")
@click.pass_context
def list_backups(ctx):
    """List all backups."""
    client = ctx.obj["client"]

    with console.status("Fetching backups..."):
        try:
            backups = client.list_backups()
        except MySQLSchemaError as e:
            console.print(f"[red]Error: {e}[/red]")
            return

    table = RichTable(title="Backups")
    table.add_column("ID", style="cyan")
    table.add_column("Database")
    table.add_column("Type")
    table.add_column("Size (MB)", justify="right")
    table.add_column("Status")
    table.add_column("Created At")

    for b in backups:
        status_color = {
            "completed": "green",
            "running": "yellow",
            "failed": "red"
        }.get(b.status.value, "white")

        table.add_row(
            b.id[:8] + "...",
            b.database,
            b.type.value,
            f"{b.size_mb:.2f}",
            f"[{status_color}]{b.status.value}[/{status_color}]",
            str(b.created_at)
        )

    console.print(table)


@backup.command("create")
@click.argument("database")
@click.option("--description", help="Backup description")
@click.option("--compression/--no-compression", default=True)
@click.pass_context
def create_backup(ctx, database, description, compression):
    """Create a database backup."""
    client = ctx.obj["client"]

    with console.status(f"Creating backup for '{database}'..."):
        try:
            backup = client.create_backup(database, description, compression)
            console.print(f"[green]✓[/green] Backup created: {backup.id}")
        except MySQLSchemaError as e:
            console.print(f"[red]✗ Error: {e}[/red]")


@backup.command("restore")
@click.argument("backup_id")
@click.argument("target_database")
@click.confirmation_option(prompt="Are you sure you want to restore this backup?")
@click.pass_context
def restore_backup(ctx, backup_id, target_database):
    """Restore from backup."""
    client = ctx.obj["client"]

    with console.status(f"Restoring backup to '{target_database}'..."):
        try:
            result = client.restore_backup(backup_id, target_database)
            console.print(f"[green]✓[/green] Backup restored successfully")
        except MySQLSchemaError as e:
            console.print(f"[red]✗ Error: {e}[/red]")


@cli.command("status")
@click.pass_context
def system_status(ctx):
    """Show system status."""
    client = ctx.obj["client"]

    with console.status("Fetching system status..."):
        try:
            status = client.get_system_status()

            console.print("\n[bold cyan]System Status[/bold cyan]")
            console.print(f"Version: {status.version}")
            console.print(f"Environment: {status.environment}")
            console.print(f"Uptime: {status.uptime}")

            console.print(f"\n[bold]Database[/bold]")
            for key, value in status.database.items():
                console.print(f"  {key}: {value}")

            console.print(f"\n[bold]Migrations[/bold]")
            for key, value in status.migrations.items():
                console.print(f"  {key}: {value}")

            console.print(f"\n[bold]Connections[/bold]")
            for key, value in status.connections.items():
                console.print(f"  {key}: {value}")

        except MySQLSchemaError as e:
            console.print(f"[red]Error: {e}[/red]")


def main():
    """Main entry point for CLI."""
    try:
        cli(obj={})
    except KeyboardInterrupt:
        console.print("\n[yellow]Interrupted by user[/yellow]")
        sys.exit(1)
    except Exception as e:
        console.print(f"[red]Unexpected error: {e}[/red]")
        sys.exit(1)


if __name__ == "__main__":
    main()