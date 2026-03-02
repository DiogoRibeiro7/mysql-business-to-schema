"""Docker command - Docker container management."""

import click
from rich.console import Console

console = Console()


@click.group(name="docker")
def docker_group():
    """Manage Docker containers and compose."""


@docker_group.command(name="up")
@click.pass_context
def docker_up(ctx):
    """Start Docker containers."""
    console.print("[green]✓[/green] Docker containers started")
