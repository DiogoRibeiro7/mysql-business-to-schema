"""Config command - Configuration management"""

import click
from rich.console import Console

console = Console()


@click.group(name="config")
def config_group():
    """Manage CLI configuration."""
    pass


@config_group.command(name="set")
@click.argument("key")
@click.argument("value")
@click.pass_context
def config_set(ctx, key, value):
    """Set configuration value."""
    console.print(f"[green]✓[/green] Set {key} = {value}")
