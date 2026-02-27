"""
Init command - Initialize new MySQL Schema projects
"""

import click
import yaml
import shutil
from pathlib import Path
from rich.console import Console
from rich.panel import Panel
from rich.prompt import Prompt, Confirm, IntPrompt
from rich.tree import Tree

from ..core import Config, save_config, ensure_project_structure

console = Console()

PROJECT_TEMPLATES = {
    "basic": {
        "description": "Basic project structure",
        "directories": ["migrations", "schemas", "data", "backups"],
        "files": {
            ".mysql-schema.yaml": "config",
            "README.md": "readme",
            ".gitignore": "gitignore",
        },
    },
    "microservice": {
        "description": "Microservice with Docker and K8s",
        "directories": ["migrations", "schemas", "data", "docker", "k8s", "tests"],
        "files": {
            ".mysql-schema.yaml": "config",
            "docker-compose.yml": "docker-compose",
            "Dockerfile": "dockerfile",
            "README.md": "readme-microservice",
            ".gitignore": "gitignore",
            ".dockerignore": "dockerignore",
        },
    },
    "full": {
        "description": "Full project with CI/CD",
        "directories": [
            "migrations",
            "schemas",
            "data",
            "backups",
            "docker",
            "k8s",
            "tests",
            "scripts",
            ".github/workflows",
        ],
        "files": {
            ".mysql-schema.yaml": "config",
            "docker-compose.yml": "docker-compose",
            "Dockerfile": "dockerfile",
            "Makefile": "makefile",
            "README.md": "readme-full",
            ".gitignore": "gitignore",
            ".dockerignore": "dockerignore",
            ".github/workflows/ci.yml": "github-ci",
            "tests/test_migrations.py": "test-migrations",
        },
    },
}


@click.command(name="init")
@click.argument("project_name", required=False)
@click.option(
    "--template",
    "-t",
    type=click.Choice(["basic", "microservice", "full"]),
    help="Project template to use",
)
@click.option("--path", "-p", type=click.Path(), help="Project directory path")
@click.option("--host", help="MySQL Schema API host")
@click.option("--port", type=int, help="MySQL Schema API port")
@click.option("--username", "-u", help="Username for authentication")
@click.option("--database", "-d", help="Default database name")
@click.option("--git", is_flag=True, help="Initialize git repository")
@click.option("--docker", is_flag=True, help="Include Docker configuration")
@click.option("--k8s", is_flag=True, help="Include Kubernetes manifests")
@click.option("--ci", is_flag=True, help="Include CI/CD configuration")
@click.option("--force", is_flag=True, help="Overwrite existing files")
@click.option("--interactive", "-i", is_flag=True, help="Interactive mode")
def init_cmd(
    project_name,
    template,
    path,
    host,
    port,
    username,
    database,
    git,
    docker,
    k8s,
    ci,
    force,
    interactive,
):
    """
    Initialize a new MySQL Schema project.

    Creates project structure, configuration files, and templates
    for database schema management.

    \b
    Examples:
        mysql-schema init myproject
        mysql-schema init myproject --template microservice
        mysql-schema init --interactive
        mysql-schema init myapp --docker --k8s --ci
    """

    # Interactive mode
    if interactive or not project_name:
        project_name, template, options = _interactive_init()
        docker = options.get("docker", docker)
        k8s = options.get("k8s", k8s)
        ci = options.get("ci", ci)
        git = options.get("git", git)
    else:
        # Determine template based on options
        if not template:
            if ci or (docker and k8s):
                template = "full"
            elif docker:
                template = "microservice"
            else:
                template = "basic"

    # Set project path
    if path:
        project_path = Path(path)
    else:
        project_path = Path.cwd() / project_name

    # Check if path exists
    if project_path.exists() and not force:
        if not Confirm.ask(
            f"[yellow]Directory {project_path} exists. Continue?[/yellow]"
        ):
            console.print("[red]Aborted[/red]")
            raise click.Abort()

    # Show initialization plan
    _show_init_plan(project_name, template, project_path)

    # Create project
    with console.status("Creating project structure..."):
        _create_project(
            project_path=project_path,
            template=template,
            project_name=project_name,
            config={
                "host": host or "localhost",
                "port": port or 8000,
                "username": username,
                "default_database": database,
            },
            docker=docker,
            k8s=k8s,
            ci=ci,
            force=force,
        )

    # Initialize git
    if git:
        _init_git(project_path)

    # Show success message
    _show_success_message(project_name, project_path)


def _interactive_init():
    """Interactive project initialization."""
    console.print(
        Panel.fit(
            "[bold cyan]MySQL Schema Project Initialization[/bold cyan]\n"
            "[dim]Let's set up your new project![/dim]",
            border_style="cyan",
        )
    )

    # Get project name
    project_name = Prompt.ask("\n[bold]Project name[/bold]")

    # Select template
    console.print("\n[bold]Available templates:[/bold]")
    for key, value in PROJECT_TEMPLATES.items():
        console.print(f"  • [cyan]{key}[/cyan]: {value['description']}")

    template = Prompt.ask(
        "Select template", choices=list(PROJECT_TEMPLATES.keys()), default="basic"
    )

    # Additional options
    console.print("\n[bold]Additional options:[/bold]")
    options = {
        "docker": Confirm.ask(
            "Include Docker configuration?", default=template != "basic"
        ),
        "k8s": Confirm.ask("Include Kubernetes manifests?", default=template == "full"),
        "ci": Confirm.ask("Include CI/CD configuration?", default=template == "full"),
        "git": Confirm.ask("Initialize git repository?", default=True),
    }

    return project_name, template, options


def _show_init_plan(project_name: str, template: str, project_path: Path):
    """Show initialization plan."""
    tree = Tree(f"[bold cyan]{project_name}/[/bold cyan]")

    template_config = PROJECT_TEMPLATES[template]

    # Add directories
    for dir_name in template_config["directories"]:
        parts = dir_name.split("/")
        current = tree
        for part in parts:
            # Find or create node
            found = False
            for child in current.children:
                if child.label == f"[blue]{part}/[/blue]":
                    current = child
                    found = True
                    break
            if not found:
                current = current.add(f"[blue]{part}/[/blue]")

    # Add files
    for file_name in template_config["files"].keys():
        if "/" in file_name:
            # File in subdirectory
            parts = file_name.split("/")
            current = tree
            for part in parts[:-1]:
                # Find directory node
                for child in current.children:
                    if child.label == f"[blue]{part}/[/blue]":
                        current = child
                        break
            current.add(f"[green]{parts[-1]}[/green]")
        else:
            tree.add(f"[green]{file_name}[/green]")

    console.print("\n[bold]Project structure to be created:[/bold]")
    console.print(tree)


def _create_project(
    project_path: Path,
    template: str,
    project_name: str,
    config: dict,
    docker: bool,
    k8s: bool,
    ci: bool,
    force: bool,
):
    """Create project structure and files."""
    template_config = PROJECT_TEMPLATES[template]

    # Create directories
    for dir_name in template_config["directories"]:
        dir_path = project_path / dir_name
        dir_path.mkdir(parents=True, exist_ok=True)

    # Create files from templates
    for file_name, template_name in template_config["files"].items():
        file_path = project_path / file_name

        # Skip if exists and not force
        if file_path.exists() and not force:
            console.print(f"[yellow]Skipping existing file: {file_name}[/yellow]")
            continue

        # Create parent directory
        file_path.parent.mkdir(parents=True, exist_ok=True)

        # Write template content
        content = _get_template_content(template_name, project_name, config)
        file_path.write_text(content)

    # Create config file
    config_file = project_path / ".mysql-schema.yaml"
    if not config_file.exists() or force:
        cfg = Config(**config)
        with open(config_file, "w") as f:
            yaml.dump(
                {
                    "host": cfg.host,
                    "port": cfg.port,
                    "username": cfg.username,
                    "default_database": cfg.default_database,
                    "migrations_dir": "./migrations",
                    "output_dir": "./output",
                },
                f,
                default_flow_style=False,
            )


def _get_template_content(template_name: str, project_name: str, config: dict) -> str:
    """Get template file content."""
    templates = {
        "readme": f"""# {project_name}

MySQL Business-to-Schema Project

## Setup

1. Install MySQL Schema CLI:
   ```bash
   pip install mysql-schema-cli
   ```

2. Configure connection:
   ```bash
   mysql-schema config set host {config.get('host', 'localhost')}
   mysql-schema config set port {config.get('port', 8000)}
   ```

3. Initialize database:
   ```bash
   mysql-schema migrate up
   ```

## Usage

Generate test data:
```bash
mysql-schema generate data clinic --rows 1000
```

Create migration:
```bash
mysql-schema migrate create "Add users table"
```

Apply migrations:
```bash
mysql-schema migrate up
```

## Project Structure

- `migrations/` - Database migration files
- `schemas/` - Schema definitions
- `data/` - Test data files
- `backups/` - Database backups
""",
        "gitignore": """# MySQL Schema
.mysql-schema.cache/
*.sql.backup
*.sql.tmp
output/
backups/*.sql
backups/*.gz

# Environment
.env
.env.local
*.env

# IDE
.vscode/
.idea/
*.swp
*.swo

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
venv/
env/

# Logs
*.log
logs/

# OS
.DS_Store
Thumbs.db
""",
        "docker-compose": f"""version: '3.8'

services:
  mysql:
    image: mysql:8.0
    container_name: {project_name}_mysql
    environment:
      MYSQL_ROOT_PASSWORD: rootpass
      MYSQL_DATABASE: {config.get('default_database', project_name)}
      MYSQL_USER: dbuser
      MYSQL_PASSWORD: dbpass
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
      - ./migrations:/docker-entrypoint-initdb.d
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5

  adminer:
    image: adminer
    container_name: {project_name}_adminer
    ports:
      - "8080:8080"
    depends_on:
      - mysql

volumes:
  mysql_data:
""",
        "dockerfile": """FROM mysql:8.0

# Copy initialization scripts
COPY migrations/*.sql /docker-entrypoint-initdb.d/

# Copy custom configuration
COPY config/my.cnf /etc/mysql/conf.d/

# Set environment
ENV MYSQL_ROOT_PASSWORD=rootpass

EXPOSE 3306

CMD ["mysqld"]
""",
        "makefile": f"""# {project_name} Makefile

.PHONY: help init migrate generate test clean

help:
\t@echo "Available commands:"
\t@echo "  make init      - Initialize project"
\t@echo "  make migrate   - Run migrations"
\t@echo "  make generate  - Generate test data"
\t@echo "  make test      - Run tests"
\t@echo "  make clean     - Clean generated files"

init:
\tmysql-schema init

migrate:
\tmysql-schema migrate up

generate:
\tmysql-schema generate data clinic --rows 1000

test:
\tpytest tests/

clean:
\trm -rf output/ backups/*.sql __pycache__/

docker-up:
\tdocker-compose up -d

docker-down:
\tdocker-compose down

docker-logs:
\tdocker-compose logs -f
""",
        "github-ci": """name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_ROOT_PASSWORD: root
          MYSQL_DATABASE: test_db
        ports:
          - 3306:3306
        options: >-
          --health-cmd="mysqladmin ping"
          --health-interval=10s
          --health-timeout=5s
          --health-retries=3

    steps:
    - uses: actions/checkout@v3

    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.10'

    - name: Install dependencies
      run: |
        pip install mysql-schema-cli
        pip install -r requirements.txt

    - name: Run migrations
      run: |
        mysql-schema migrate up
      env:
        MYSQL_SCHEMA_HOST: localhost
        MYSQL_SCHEMA_PORT: 3306
        MYSQL_SCHEMA_USERNAME: root
        MYSQL_SCHEMA_PASSWORD: root

    - name: Run tests
      run: |
        pytest tests/
""",
    }

    return templates.get(template_name, "")


def _init_git(project_path: Path):
    """Initialize git repository."""
    try:
        import subprocess

        subprocess.run(["git", "init"], cwd=project_path, check=True)
        subprocess.run(["git", "add", "."], cwd=project_path, check=True)
        subprocess.run(
            ["git", "commit", "-m", "Initial commit"], cwd=project_path, check=True
        )
        console.print("[green]✓[/green] Git repository initialized")
    except Exception as e:
        console.print(f"[yellow]Warning: Failed to initialize git: {e}[/yellow]")


def _show_success_message(project_name: str, project_path: Path):
    """Show success message with next steps."""
    message = f"""[green]✓ Project '{project_name}' created successfully![/green]

[bold]Next steps:[/bold]
1. Navigate to project: [cyan]cd {project_path}[/cyan]
2. Configure connection: [cyan]mysql-schema config set host <your-host>[/cyan]
3. Create your first schema: [cyan]mysql-schema generate schema microservice --name users[/cyan]
4. Generate test data: [cyan]mysql-schema generate data clinic --rows 1000[/cyan]
5. Create a migration: [cyan]mysql-schema migrate create "Initial schema"[/cyan]

[dim]Run [cyan]mysql-schema --help[/cyan] for more commands[/dim]"""

    console.print(Panel.fit(message, border_style="green"))
