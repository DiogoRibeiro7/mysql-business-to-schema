#!/usr/bin/env python3
"""Run the MySQL Business-to-Schema test runner."""

import click
import subprocess
import sys
import time
from pathlib import Path


@click.group()
@click.option("--verbose", "-v", is_flag=True, help="Verbose output")
@click.pass_context
def cli(ctx, verbose):
    """Run the MySQL Business-to-Schema test runner."""
    ctx.ensure_object(dict)
    ctx.obj["verbose"] = verbose


def run_command(command, verbose=False):
    """Execute a shell command."""
    if verbose:
        click.echo(f"Running: {command}")

    try:
        result = subprocess.run(
            command, shell=True, capture_output=not verbose, text=True
        )

        if result.returncode != 0 and not verbose:
            click.echo(f"Error: {result.stderr}", err=True)

        return result.returncode == 0
    except Exception as e:
        click.echo(f"Failed to run command: {e}", err=True)
        return False


@cli.command()
@click.option(
    "--category",
    "-c",
    type=click.Choice(["unit", "integration", "e2e", "performance", "chaos", "all"]),
    default="all",
    help="Test category to run",
)
@click.option("--parallel", "-p", is_flag=True, help="Run tests in parallel")
@click.option("--coverage", is_flag=True, help="Generate coverage report")
@click.option("--html-report", is_flag=True, help="Generate HTML report")
@click.option("--markers", "-m", help="Pytest markers to filter tests")
@click.option("--failed-first", is_flag=True, help="Run failed tests first")
@click.pass_context
def run(ctx, category, parallel, coverage, html_report, markers, failed_first):
    """Run test suite."""
    verbose = ctx.obj["verbose"]

    click.echo(f"🧪 Running {category} tests...")

    # Build pytest command
    cmd_parts = ["pytest"]

    # Add test path based on category
    if category == "unit":
        cmd_parts.append("tests/unit/")
        markers = markers or "unit"
    elif category == "integration":
        cmd_parts.append("tests/integration/")
        markers = markers or "integration"
    elif category == "e2e":
        cmd_parts.append("tests/e2e/")
        markers = markers or "e2e"
    elif category == "performance":
        cmd_parts.append("tests/performance/")
        markers = markers or "performance"
    elif category == "chaos":
        cmd_parts.append("tests/chaos/")
        markers = markers or "chaos"
    else:
        cmd_parts.append("tests/")

    # Add options
    if verbose:
        cmd_parts.append("-vv")
    else:
        cmd_parts.append("-v")

    if parallel:
        cmd_parts.append("-n auto")

    if coverage:
        cmd_parts.extend(["--cov=.", "--cov-report=term-missing", "--cov-report=html"])

    if html_report:
        cmd_parts.append("--html=test-report.html --self-contained-html")

    if markers:
        cmd_parts.append(f'-m "{markers}"')

    if failed_first:
        cmd_parts.append("--failed-first")

    # Run tests
    command = " ".join(cmd_parts)
    success = run_command(command, verbose)

    if success:
        click.echo("✅ Tests passed!")

        if coverage:
            click.echo("📊 Coverage report generated in htmlcov/index.html")

        if html_report:
            click.echo("📄 Test report generated in test-report.html")
    else:
        click.echo("❌ Tests failed!", err=True)
        sys.exit(1)


@cli.command()
@click.option("--users", "-u", default=10, help="Number of concurrent users")
@click.option("--spawn-rate", "-r", default=2, help="Users spawn rate")
@click.option("--duration", "-t", default="60s", help="Test duration")
@click.option("--host", default="http://localhost:3001", help="Target host")
@click.pass_context
def load(ctx, users, spawn_rate, duration, host):
    """Run load tests with Locust."""
    verbose = ctx.obj["verbose"]

    click.echo(f"🔥 Running load test with {users} users...")

    command = f"locust -f tests/performance/test_load.py --headless -u {users} -r {spawn_rate} -t {duration} --host={host}"

    if not verbose:
        command += " --only-summary"

    success = run_command(command, verbose)

    if success:
        click.echo("✅ Load test completed!")
    else:
        click.echo("❌ Load test failed!", err=True)
        sys.exit(1)


@cli.command()
@click.option("--fix", is_flag=True, help="Auto-fix issues")
@click.pass_context
def lint(ctx, fix):
    """Run code quality checks."""
    verbose = ctx.obj["verbose"]

    click.echo("🔍 Running code quality checks...")

    # Run Black
    click.echo("  Running Black formatter...")
    black_cmd = "black . --line-length=100"
    if not fix:
        black_cmd += " --check"
    run_command(black_cmd, verbose)

    # Run Flake8
    click.echo("  Running Flake8 linter...")
    run_command("flake8 . --max-line-length=200 --max-complexity=25", verbose)

    # Run MyPy
    click.echo("  Running MyPy type checker...")
    run_command("mypy . --ignore-missing-imports", verbose)

    click.echo("✅ Code quality checks completed!")


@cli.command()
@click.pass_context
def coverage(ctx):
    """Generate and display coverage report."""
    verbose = ctx.obj["verbose"]

    click.echo("📊 Generating coverage report...")

    # Run tests with coverage
    run_command("pytest --cov=. --cov-report=term-missing --cov-report=html", verbose)

    # Open HTML report
    if click.confirm("Open HTML report in browser?"):
        import webbrowser

        webbrowser.open("htmlcov/index.html")


@cli.command()
@click.pass_context
def clean(ctx):
    """Clean test artifacts."""
    click.echo("🧹 Cleaning test artifacts...")

    patterns = [
        "**/__pycache__",
        "**/*.pyc",
        ".pytest_cache",
        "htmlcov",
        ".coverage",
        "coverage.xml",
        "test-report.html",
        "allure-results",
        "*.log",
    ]

    for pattern in patterns:
        for path in Path(".").glob(pattern):
            if path.is_file():
                path.unlink()
                click.echo(f"  Removed: {path}")
            elif path.is_dir():
                import shutil

                shutil.rmtree(path)
                click.echo(f"  Removed: {path}/")

    click.echo("✅ Cleanup completed!")


@cli.command()
@click.option("--start/--stop", default=True, help="Start or stop services")
@click.pass_context
def services(ctx, start):
    """Manage test services such as MySQL, Redis, and Kafka."""
    verbose = ctx.obj["verbose"]

    if start:
        click.echo("🚀 Starting test services...")
        success = run_command("docker-compose up -d mysql redis kafka", verbose)

        if success:
            click.echo("⏳ Waiting for services to be ready...")
            time.sleep(10)
            click.echo("✅ Services started!")
        else:
            click.echo("❌ Failed to start services!", err=True)
            sys.exit(1)
    else:
        click.echo("🛑 Stopping test services...")
        run_command("docker-compose down -v", verbose)
        click.echo("✅ Services stopped!")


@cli.command()
@click.option("--save", help="Save benchmark with name")
@click.option("--compare", help="Compare with saved benchmark")
@click.pass_context
def benchmark(ctx, save, compare):
    """Run performance benchmarks."""
    verbose = ctx.obj["verbose"]

    click.echo("⚡ Running performance benchmarks...")

    cmd = "pytest tests/performance/ -v"

    if save:
        cmd += f" --benchmark-save={save}"
        click.echo(f"💾 Saving benchmark as '{save}'")

    if compare:
        cmd += f" --benchmark-compare={compare}"
        click.echo(f"📊 Comparing with benchmark '{compare}'")

    success = run_command(cmd, verbose)

    if success:
        click.echo("✅ Benchmarks completed!")
    else:
        click.echo("❌ Benchmarks failed!", err=True)
        sys.exit(1)


@cli.command()
@click.argument("test_path", required=False)
@click.option("--debug", is_flag=True, help="Run with debugger")
@click.pass_context
def debug(ctx, test_path, debug):
    """Debug specific test."""
    _ = ctx.obj["verbose"]

    if not test_path:
        test_path = click.prompt(
            "Enter test path (e.g., tests/unit/test_generators.py::TestClinicDataGenerator::test_patient_data_generation)"
        )

    click.echo(f"🐛 Debugging: {test_path}")

    cmd = f"pytest {test_path} -vv"

    if debug:
        cmd += " --pdb --pdbcls=IPython.terminal.debugger:TerminalPdb"

    run_command(cmd, True)  # Always verbose for debugging


@cli.command()
@click.pass_context
def watch(ctx):
    """Watch for file changes and run tests."""
    _ = ctx.obj["verbose"]

    click.echo("👀 Watching for file changes...")
    click.echo("Press Ctrl+C to stop")

    try:
        run_command("ptw -- -v tests/unit/", True)
    except KeyboardInterrupt:
        click.echo("\n✅ Watch mode stopped")


@cli.command()
@click.pass_context
def report(ctx):
    """Generate comprehensive test report."""
    verbose = ctx.obj["verbose"]

    click.echo("📝 Generating comprehensive test report...")

    # Run all tests with reporting
    cmd = "pytest tests/ --html=test-report.html --self-contained-html --junitxml=test-results.xml --cov=. --cov-report=html --cov-report=xml"

    success = run_command(cmd, verbose)

    if success:
        click.echo("✅ Reports generated:")
        click.echo("  📄 HTML Report: test-report.html")
        click.echo("  📊 Coverage Report: htmlcov/index.html")
        click.echo("  📋 JUnit XML: test-results.xml")
        click.echo("  📈 Coverage XML: coverage.xml")

        if click.confirm("Open HTML report in browser?"):
            import webbrowser

            webbrowser.open("test-report.html")
    else:
        click.echo("❌ Report generation failed!", err=True)
        sys.exit(1)


@cli.command()
@click.pass_context
def ci(ctx):
    """Run CI-appropriate tests."""
    verbose = ctx.obj["verbose"]

    click.echo("🤖 Running CI test suite...")

    # Skip slow and chaos tests in CI
    cmd = 'pytest tests/ -v -m "not chaos and not slow" --junitxml=test-results.xml --cov=. --cov-report=xml'

    success = run_command(cmd, verbose)

    if success:
        click.echo("✅ CI tests passed!")
    else:
        click.echo("❌ CI tests failed!", err=True)
        sys.exit(1)


@cli.command()
def info():
    """Display test environment information."""
    click.echo("ℹ️  Test Environment Information")
    click.echo("=" * 40)

    # Check Python version
    import sys

    click.echo(f"Python: {sys.version}")

    # Check pytest version
    try:
        import pytest

        click.echo(f"Pytest: {pytest.__version__}")
    except ImportError:
        click.echo("Pytest: Not installed")

    # Check Docker
    result = subprocess.run(
        "docker --version", shell=True, capture_output=True, text=True
    )
    click.echo(f"Docker: {result.stdout.strip()}")

    # Check services
    result = subprocess.run(
        "docker ps --format 'table {{.Names}}\\t{{.Status}}'",
        shell=True,
        capture_output=True,
        text=True,
    )
    click.echo("\nRunning Services:")
    click.echo(result.stdout)

    # Test statistics
    result = subprocess.run(
        "pytest --collect-only -q", shell=True, capture_output=True, text=True
    )
    lines = result.stdout.strip().split("\n")
    if lines and "collected" in lines[-1]:
        click.echo(f"\nTests available: {lines[-1]}")


if __name__ == "__main__":
    cli(obj={})
