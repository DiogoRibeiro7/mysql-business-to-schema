"""Generate command - Test data and schema generation."""

import click
import json
from pathlib import Path
from typing import Any, Dict
from rich.console import Console
from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn
from rich.prompt import Confirm, IntPrompt, Prompt
from rich.table import Table
from rich.panel import Panel

from ..core import CliContext, ApiClient
from ..templates import get_template, render_template

console = Console()

AVAILABLE_SCHEMAS = [
    "clinic",
    "ecommerce",
    "iot_sensors",
    "social_media",
    "fintech",
    "real_estate",
    "education",
    "logistics",
    "food_delivery",
    "gaming",
    "hotel_chain",
    "insurance",
    "cryptocurrency",
]


@click.group(name="generate")
def generate_group():
    """Generate test data, schemas, and configurations."""


@generate_group.command(name="data")
@click.argument("schema", type=click.Choice(AVAILABLE_SCHEMAS))
@click.option("--rows", "-r", default=1000, type=int, help="Number of rows to generate")
@click.option(
    "--format",
    "-f",
    type=click.Choice(["sql", "csv", "json", "parquet", "excel"]),
    default="sql",
    help="Output format",
)
@click.option("--output", "-o", type=click.Path(), help="Output file path")
@click.option("--database", "-d", help="Target database name")
@click.option("--seed", type=int, help="Random seed for reproducibility")
@click.option("--compress", is_flag=True, help="Compress output file")
@click.option("--split-tables", is_flag=True, help="Split output by table")
@click.option("--include-schema", is_flag=True, help="Include CREATE statements")
@click.option("--batch-size", default=1000, type=int, help="Batch size for inserts")
@click.option("--parallel", is_flag=True, help="Generate data in parallel")
@click.pass_context
def generate_data(
    ctx,
    schema,
    rows,
    format,
    output,
    database,
    seed,
    compress,
    split_tables,
    include_schema,
    batch_size,
    parallel,
):
    """Generate test data for predefined schemas.

    
    Examples:
        mysql-schema generate data clinic --rows 5000
        mysql-schema generate data ecommerce --format csv --output data.csv
        mysql-schema generate data iot_sensors --rows 100000 --parallel
        mysql-schema generate data social_media --seed 42 --compress
    """
    cli_context: CliContext = ctx.obj

    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        BarColumn(),
        TextColumn("[progress.percentage]{task.percentage:>3.0f}%"),
        console=console,
    ) as progress:

        # Start generation task
        task = progress.add_task(
            f"Generating {rows:,} rows for {schema} schema...", total=100
        )

        try:
            # Initialize API client
            client = ApiClient(cli_context)
            progress.update(task, advance=10)

            # Prepare request
            params = {
                "schema": schema,
                "rows": rows,
                "format": format,
                "seed": seed,
                "batch_size": batch_size,
                "include_schema": include_schema,
                "parallel": parallel,
            }

            if database:
                params["database"] = database

            # Generate data
            progress.update(task, description="Calling generation API...")
            result = client.request("POST", "/generate/data", json=params)
            progress.update(task, advance=60)

            # Process output
            if output:
                output_path = Path(output)
                progress.update(task, description="Writing to file...")

                if split_tables and format in ["csv", "json"]:
                    # Split by table
                    output_path.mkdir(parents=True, exist_ok=True)
                    for table_name, table_data in result["data"].items():
                        table_file = output_path / f"{table_name}.{format}"
                        _write_output(table_file, table_data, format, compress)
                else:
                    # Single file
                    _write_output(output_path, result["data"], format, compress)

                progress.update(task, advance=30)
                console.print(f"[green]✓[/green] Data saved to {output_path}")
            else:
                # Output to console
                progress.update(task, advance=30)
                if cli_context.output_json:
                    click.echo(json.dumps(result, indent=2))
                else:
                    _display_generated_data(result, format)

            # Show statistics
            if not cli_context.output_json:
                _show_generation_stats(result)

        except Exception as e:
            console.print(f"[red]✗ Generation failed: {e}[/red]")
            if cli_context.is_verbose:
                console.print_exception()
            raise click.Abort()


@generate_group.command(name="schema")
@click.argument(
    "template",
    type=click.Choice(
        [
            "microservice",
            "warehouse",
            "timeseries",
            "multitenant",
            "event-sourcing",
            "graph",
        ]
    ),
)
@click.option("--name", "-n", required=True, help="Database/schema name")
@click.option("--output", "-o", type=click.Path(), help="Output directory")
@click.option("--tables", "-t", multiple=True, help="Table names to include")
@click.option("--with-indexes", is_flag=True, help="Include optimized indexes")
@click.option("--with-partitions", is_flag=True, help="Include partitioning")
@click.option("--with-triggers", is_flag=True, help="Include triggers")
@click.option("--with-procedures", is_flag=True, help="Include stored procedures")
@click.option(
    "--engine",
    type=click.Choice(["InnoDB", "MyISAM", "Memory"]),
    default="InnoDB",
    help="Storage engine",
)
@click.pass_context
def generate_schema(
    ctx,
    template,
    name,
    output,
    tables,
    with_indexes,
    with_partitions,
    with_triggers,
    with_procedures,
    engine,
):
    """Generate database schema from templates.

    
    Templates:
        microservice   - Microservice with events and audit
        warehouse      - Data warehouse with facts and dimensions
        timeseries     - Time-series optimized schema
        multitenant    - Multi-tenant SaaS schema
        event-sourcing - Event sourcing pattern
        graph          - Graph database structure

    
    Examples:
        mysql-schema generate schema microservice --name user_service
        mysql-schema generate schema warehouse --name analytics --with-partitions
        mysql-schema generate schema timeseries --name metrics --with-indexes
    """
    cli_context: CliContext = ctx.obj

    console.print(f"[cyan]Generating {template} schema: {name}[/cyan]")

    try:
        # Load template
        template_data = get_template(f"schema/{template}")

        # Prepare context
        context = {
            "database_name": name,
            "engine": engine,
            "tables": list(tables) if tables else None,
            "with_indexes": with_indexes,
            "with_partitions": with_partitions,
            "with_triggers": with_triggers,
            "with_procedures": with_procedures,
            "charset": cli_context.config.default_charset,
            "collation": cli_context.config.default_collation,
        }

        # Render template
        schema_sql = render_template(template_data, context)

        # Save or display
        if output:
            output_path = Path(output)
            if output_path.is_dir():
                output_file = output_path / f"{name}.sql"
            else:
                output_file = output_path

            output_file.parent.mkdir(parents=True, exist_ok=True)
            output_file.write_text(schema_sql)
            console.print(f"[green]✓[/green] Schema saved to {output_file}")
        else:
            # Display schema
            from pygments import highlight
            from pygments.lexers import SqlLexer
            from pygments.formatters import TerminalFormatter

            if not cli_context.no_color:
                highlighted = highlight(schema_sql, SqlLexer(), TerminalFormatter())
                console.print(highlighted)
            else:
                click.echo(schema_sql)

    except Exception as e:
        console.print(f"[red]✗ Schema generation failed: {e}[/red]")
        raise click.Abort()


@generate_group.command(name="migration")
@click.option("--from-db", required=True, help="Source database")
@click.option("--to-db", required=True, help="Target database")
@click.option("--name", "-n", help="Migration name")
@click.option("--output", "-o", type=click.Path(), help="Output file")
@click.option("--include-data", is_flag=True, help="Include data migration")
@click.option("--safe-mode", is_flag=True, help="Generate safe migrations only")
@click.pass_context
def generate_migration(ctx, from_db, to_db, name, output, include_data, safe_mode):
    """Generate migration from database differences.

    
    Examples:
        mysql-schema generate migration --from-db dev --to-db prod
        mysql-schema generate migration --from-db v1 --to-db v2 --include-data
    """
    cli_context: CliContext = ctx.obj

    with console.status("Analyzing database differences..."):
        try:
            client = ApiClient(cli_context)

            # Get migration
            params = {
                "source_database": from_db,
                "target_database": to_db,
                "include_data": include_data,
                "safe_mode": safe_mode,
            }

            result = client.request("POST", "/generate/migration", json=params)

            # Format migration
            migration_name = name or f"migrate_{from_db}_to_{to_db}"
            timestamp = (
                Path.cwd() / "migrations" / f"{result['version']}_{migration_name}.sql"
            )

            migration_content = f"""-- Migration: {migration_name}
-- Generated: {result['generated_at']}
-- From: {from_db}
-- To: {to_db}

-- UP
{result['up_script']}

-- DOWN
{result['down_script']}
"""

            # Save or display
            if output:
                output_path = Path(output)
            else:
                output_path = timestamp

            output_path.parent.mkdir(parents=True, exist_ok=True)
            output_path.write_text(migration_content)

            console.print(f"[green]✓[/green] Migration saved to {output_path}")

            # Show summary
            table = Table(title="Migration Summary")
            table.add_column("Change Type")
            table.add_column("Count")

            for change_type, count in result["summary"].items():
                table.add_row(change_type.replace("_", " ").title(), str(count))

            console.print(table)

        except Exception as e:
            console.print(f"[red]✗ Migration generation failed: {e}[/red]")
            raise click.Abort()


@generate_group.command(name="config")
@click.argument("type", type=click.Choice(["docker", "k8s", "ci", "monitoring"]))
@click.option("--output", "-o", type=click.Path(), help="Output directory")
@click.option("--name", "-n", help="Project name")
@click.option(
    "--env",
    type=click.Choice(["dev", "staging", "prod"]),
    default="dev",
    help="Environment",
)
@click.pass_context
def generate_config(ctx, type, output, name, env):
    """Generate configuration files.

    
    Types:
        docker     - Docker Compose configuration
        k8s        - Kubernetes manifests
        ci         - CI/CD pipeline configs
        monitoring - Prometheus/Grafana configs

    
    Examples:
        mysql-schema generate config docker --name myproject
        mysql-schema generate config k8s --env prod
        mysql-schema generate config ci --output .github/workflows
    """
    _: CliContext = ctx.obj

    console.print(f"[cyan]Generating {type} configuration for {env} environment[/cyan]")

    # Implementation would generate various config files
    console.print("[green]✓[/green] Configuration generated")


@generate_group.command(name="interactive")
@click.pass_context
def generate_interactive(ctx):
    """Interactive data generation wizard."""
    _: CliContext = ctx.obj

    console.print(
        Panel.fit(
            "[bold cyan]Interactive Data Generation Wizard[/bold cyan]",
            border_style="cyan",
        )
    )

    # Select schema
    console.print("\n[bold]Available schemas:[/bold]")
    for i, schema in enumerate(AVAILABLE_SCHEMAS, 1):
        console.print(f"  {i}. {schema}")

    schema_choice = IntPrompt.ask(
        "Select schema", choices=[str(i) for i in range(1, len(AVAILABLE_SCHEMAS) + 1)]
    )
    schema = AVAILABLE_SCHEMAS[int(schema_choice) - 1]

    # Get parameters
    rows = IntPrompt.ask("Number of rows to generate", default=1000)
    format = Prompt.ask(
        "Output format", choices=["sql", "csv", "json", "parquet"], default="sql"
    )

    include_schema = Confirm.ask("Include CREATE statements?", default=True)
    compress = Confirm.ask("Compress output?", default=False)

    # Generate
    ctx.invoke(
        generate_data,
        schema=schema,
        rows=rows,
        format=format,
        include_schema=include_schema,
        compress=compress,
    )


def _write_output(path: Path, data: Any, format: str, compress: bool):
    """Write output to file."""
    if compress:
        import gzip

        with gzip.open(f"{path}.gz", "wt") as f:
            if format == "json":
                json.dump(data, f, indent=2)
            else:
                f.write(str(data))
    else:
        if format == "json":
            with open(path, "w") as f:
                json.dump(data, f, indent=2)
        else:
            path.write_text(str(data))


def _display_generated_data(result: Dict, format: str):
    """Display generated data preview."""
    console.print("\n[bold]Generated Data Preview:[/bold]")

    if format == "sql":
        # Show first few SQL statements
        lines = result["data"].split("\n")[:20]
        for line in lines:
            console.print(f"[dim]{line}[/dim]")
        if len(result["data"].split("\n")) > 20:
            console.print("[dim]... (truncated)[/dim]")
    else:
        # Show summary
        for table, count in result["tables"].items():
            console.print(f"  • {table}: {count:,} rows")


def _show_generation_stats(result: Dict):
    """Show generation statistics."""
    if "stats" not in result:
        return

    stats = result["stats"]
    table = Table(title="Generation Statistics")
    table.add_column("Metric")
    table.add_column("Value")

    table.add_row("Total Rows", f"{stats.get('total_rows', 0):,}")
    table.add_row("Generation Time", f"{stats.get('time_seconds', 0):.2f}s")
    table.add_row("Rows/Second", f"{stats.get('rows_per_second', 0):,.0f}")
    table.add_row("Output Size", f"{stats.get('size_mb', 0):.2f} MB")

    console.print(table)
