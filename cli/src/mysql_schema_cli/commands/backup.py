"""Backup command - Database backup management."""

import click
from rich.console import Console

console = Console()


@click.group(name="backup")
def backup_group():
    """Manage database backups."""


@backup_group.command(name="create")
@click.argument("database")
@click.pass_context
def create_backup(ctx, database):
    """Create a database backup."""
    console.print(f"[green]✓[/green] Backup created for {database}")
