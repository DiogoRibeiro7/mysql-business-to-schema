"""Monitor command - System monitoring"""
import click
from rich.console import Console

console = Console()

@click.group(name='monitor')
def monitor_group():
    """Monitor database performance and metrics."""
    pass

@monitor_group.command(name='status')
@click.pass_context
def monitor_status(ctx):
    """Show system status."""
    console.print("[cyan]System Status[/cyan]")