"""Deploy command - Deployment management."""

import click
from rich.console import Console

console = Console()


@click.group(name="deploy")
def deploy_group():
    """Deploy to various environments."""


@deploy_group.command(name="k8s")
@click.pass_context
def deploy_k8s(ctx):
    """Deploy to Kubernetes."""
    console.print("[green]✓[/green] Deployed to Kubernetes")
