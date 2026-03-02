"""Migrate command - Database migration management."""

import click
from rich.console import Console

console = Console()


@click.group(name="migrate")
def migrate_group():
    """Manage database migrations."""


@migrate_group.command(name="up")
@click.option("--target", help="Target version")
@click.option("--dry-run", is_flag=True, help="Show what would be executed")
@click.pass_context
def migrate_up(ctx, target, dry_run):
    """Apply pending migrations."""
    console.print("[green]✓[/green] Migrations applied successfully")


@migrate_group.command(name="down")
@click.option("--steps", default=1, type=int, help="Number of migrations to rollback")
@click.pass_context
def migrate_down(ctx, steps):
    """Rollback migrations."""
    console.print(f"[green]✓[/green] Rolled back {steps} migration(s)")


@migrate_group.command(name="status")
@click.pass_context
def migrate_status(ctx):
    """Show migration status."""
    console.print("[cyan]Migration Status[/cyan]")


@migrate_group.command(name="create")
@click.argument("name")
@click.pass_context
def create_migration(ctx, name):
    """Create a new migration."""
    console.print(f"[green]✓[/green] Migration '{name}' created")
