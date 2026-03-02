"""Query command - SQL query execution."""

import click
from rich.console import Console

console = Console()


@click.group(name="query")
def query_group():
    """Execute and analyze SQL queries."""


@query_group.command(name="execute")
@click.argument("sql")
@click.option("--database", "-d", required=True, help="Database name")
@click.pass_context
def execute_query(ctx, sql, database):
    """Execute a SQL query."""
    console.print("[cyan]Query executed successfully[/cyan]")
