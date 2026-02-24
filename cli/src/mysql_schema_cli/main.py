#!/usr/bin/env python3
"""
MySQL Business-to-Schema CLI - Main entry point
"""

import os
import sys
import click
from pathlib import Path
from rich.console import Console
from rich.panel import Panel
from rich import print as rprint

from .commands import (
    init,
    generate,
    schema,
    migrate,
    query,
    backup,
    monitor,
    docker,
    deploy,
    config,
)
from .core import CliContext, load_config
from .version import __version__

console = Console()

CONTEXT_SETTINGS = dict(
    help_option_names=['-h', '--help'],
    max_content_width=120,
)


class AliasedGroup(click.Group):
    """Custom group that supports command aliases."""

    def get_command(self, ctx, cmd_name):
        # Command aliases
        aliases = {
            'g': 'generate',
            'gen': 'generate',
            'm': 'migrate',
            'mig': 'migrate',
            'q': 'query',
            'b': 'backup',
            'bak': 'backup',
            'd': 'deploy',
            's': 'schema',
            'mon': 'monitor',
        }

        # Resolve alias
        cmd_name = aliases.get(cmd_name, cmd_name)

        return super().get_command(ctx, cmd_name)


@click.group(cls=AliasedGroup, context_settings=CONTEXT_SETTINGS)
@click.version_option(version=__version__, prog_name="mysql-schema")
@click.option('-c', '--config', type=click.Path(), help='Config file path')
@click.option('-v', '--verbose', count=True, help='Increase verbosity')
@click.option('--profile', default='default', help='Config profile to use')
@click.option('--no-color', is_flag=True, help='Disable colored output')
@click.option('--json', 'output_json', is_flag=True, help='Output in JSON format')
@click.pass_context
def cli(ctx, config, verbose, profile, no_color, output_json):
    """
    MySQL Business-to-Schema CLI - Unified tool for database management.

    A powerful command-line interface for managing MySQL schemas, migrations,
    data generation, monitoring, and deployment.

    \b
    Quick Examples:
        mysql-schema init myproject              # Initialize new project
        mysql-schema generate clinic --rows 1000 # Generate test data
        mysql-schema migrate up                  # Apply migrations
        mysql-schema monitor status              # Check system status
        mysql-schema deploy k8s                  # Deploy to Kubernetes

    \b
    Command Aliases:
        g, gen  → generate
        m, mig  → migrate
        q       → query
        b, bak  → backup
        s       → schema
        d       → deploy
        mon     → monitor

    Use 'mysql-schema COMMAND --help' for more information on a command.
    """
    # Initialize context
    ctx.ensure_object(dict)

    # Load configuration
    config_path = config or os.getenv('MYSQL_SCHEMA_CONFIG')
    cfg = load_config(config_path, profile)

    # Create CLI context
    cli_context = CliContext(
        config=cfg,
        verbose=verbose,
        profile=profile,
        no_color=no_color,
        output_json=output_json
    )

    ctx.obj = cli_context

    # Configure Rich console
    if no_color:
        console.no_color = True

    # Show banner in verbose mode
    if verbose and not output_json:
        _show_banner()


def _show_banner():
    """Display CLI banner."""
    banner = Panel.fit(
        f"""[bold cyan]MySQL Business-to-Schema CLI[/bold cyan]
[dim]Version {__version__}[/dim]

[yellow]Ready to manage your database schemas![/yellow]""",
        border_style="cyan",
        padding=(1, 2)
    )
    console.print(banner)


# Register command groups
cli.add_command(init.init_cmd)
cli.add_command(generate.generate_group)
cli.add_command(schema.schema_group)
cli.add_command(migrate.migrate_group)
cli.add_command(query.query_group)
cli.add_command(backup.backup_group)
cli.add_command(monitor.monitor_group)
cli.add_command(docker.docker_group)
cli.add_command(deploy.deploy_group)
cli.add_command(config.config_group)


@cli.command()
@click.pass_context
def interactive(ctx):
    """Start interactive mode with guided prompts."""
    from .interactive import start_interactive_mode
    start_interactive_mode(ctx.obj)


@cli.command()
@click.argument('command', required=False)
def shell(command):
    """
    Start interactive shell or execute shell command.

    Without arguments, starts an interactive MySQL shell.
    With arguments, executes the command in the context of the project.
    """
    from .shell import start_shell
    start_shell(command)


@cli.command()
@click.option('--shell', type=click.Choice(['bash', 'zsh', 'fish', 'powershell']),
              help='Shell type for completion')
@click.option('--path', type=click.Path(), help='Installation path')
def completion(shell, path):
    """
    Generate shell completion scripts.

    \b
    Examples:
        mysql-schema completion --shell bash >> ~/.bashrc
        mysql-schema completion --shell zsh >> ~/.zshrc
        mysql-schema completion --shell fish > ~/.config/fish/completions/mysql-schema.fish
    """
    from .completion import generate_completion
    script = generate_completion(shell or 'bash')
    click.echo(script)


@cli.command()
@click.option('--format', type=click.Choice(['text', 'json', 'yaml']),
              default='text', help='Output format')
@click.pass_context
def info(ctx, format):
    """Display system and configuration information."""
    from .info import show_info
    show_info(ctx.obj, format)


@cli.command()
@click.argument('path', type=click.Path())
@click.option('--watch', is_flag=True, help='Watch for changes')
@click.option('--validate', is_flag=True, help='Validate syntax only')
@click.pass_context
def validate(ctx, path, watch, validate):
    """
    Validate SQL files, schemas, or configurations.

    \b
    Validates:
        - SQL syntax and schema definitions
        - Migration files
        - Configuration files
        - Docker Compose files
    """
    from .validator import validate_files
    validate_files(ctx.obj, path, watch, validate_only=validate)


@cli.command()
@click.option('--check', is_flag=True, help='Check for updates only')
@click.option('--pre', is_flag=True, help='Include pre-release versions')
def upgrade(check, pre):
    """Upgrade CLI to the latest version."""
    from .upgrade import check_and_upgrade
    check_and_upgrade(check_only=check, include_pre=pre)


@cli.command()
@click.option('--all', 'show_all', is_flag=True, help='Show all commands')
@click.option('--markdown', is_flag=True, help='Output in Markdown format')
def commands(show_all, markdown):
    """List all available commands and their descriptions."""
    from .help import list_commands
    list_commands(show_all=show_all, markdown=markdown)


@cli.result_callback()
@click.pass_context
def process_result(ctx, result, **kwargs):
    """Process command results for consistent output."""
    if result and ctx.obj.output_json:
        import json
        if isinstance(result, (dict, list)):
            click.echo(json.dumps(result, indent=2, default=str))


def main():
    """Main entry point for the CLI."""
    try:
        # Enable auto-completion
        import click_completion
        click_completion.init()

        # Run CLI
        cli(prog_name='mysql-schema')
    except KeyboardInterrupt:
        console.print("\n[yellow]Interrupted by user[/yellow]")
        sys.exit(1)
    except Exception as e:
        if '--verbose' in sys.argv or '-v' in sys.argv:
            console.print_exception()
        else:
            console.print(f"[red]Error: {e}[/red]")
            console.print("[dim]Run with -v for full traceback[/dim]")
        sys.exit(1)


if __name__ == '__main__':
    main()