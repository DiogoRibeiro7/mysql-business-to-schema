"""
Core utilities for MySQL Schema CLI
"""

import os
import yaml
import json
from pathlib import Path
from dataclasses import dataclass, field
from typing import Dict, Any, Optional, List
from rich.console import Console

console = Console()


@dataclass
class Config:
    """CLI configuration."""

    # Connection settings
    host: str = "localhost"
    port: int = 8000
    username: Optional[str] = None
    password: Optional[str] = None
    api_key: Optional[str] = None

    # Database settings
    default_database: Optional[str] = None
    default_charset: str = "utf8mb4"
    default_collation: str = "utf8mb4_unicode_ci"
    default_engine: str = "InnoDB"

    # Generation settings
    default_rows: int = 1000
    default_format: str = "sql"
    faker_locale: str = "en_US"

    # Migration settings
    migrations_dir: str = "./migrations"
    auto_backup: bool = True
    dry_run: bool = False

    # Output settings
    output_dir: str = "./output"
    timestamp_format: str = "%Y%m%d_%H%M%S"

    # Docker settings
    docker_compose_file: str = "docker-compose.yml"
    docker_network: str = "mysql-schema-network"

    # Kubernetes settings
    k8s_namespace: str = "default"
    k8s_context: Optional[str] = None
    helm_chart: str = "./charts/mysql-schema"

    # Monitoring settings
    prometheus_url: Optional[str] = None
    grafana_url: Optional[str] = None
    alert_webhook: Optional[str] = None

    # Advanced settings
    max_retries: int = 3
    timeout: int = 30
    parallel_jobs: int = 4
    cache_enabled: bool = True
    cache_dir: str = "~/.mysql-schema/cache"

    # Profiles
    profiles: Dict[str, Dict[str, Any]] = field(default_factory=dict)


@dataclass
class CliContext:
    """CLI context passed to all commands."""

    config: Config
    verbose: int = 0
    profile: str = "default"
    no_color: bool = False
    output_json: bool = False

    @property
    def is_verbose(self) -> bool:
        return self.verbose > 0

    @property
    def is_debug(self) -> bool:
        return self.verbose > 1

    def get_connection_params(self) -> Dict[str, Any]:
        """Get connection parameters for API client."""
        return {
            "host": self.config.host,
            "port": self.config.port,
            "username": self.config.username,
            "password": self.config.password,
            "api_key": self.config.api_key,
            "timeout": self.config.timeout,
            "max_retries": self.config.max_retries,
        }


def load_config(
    config_path: Optional[str] = None,
    profile: str = "default"
) -> Config:
    """
    Load configuration from file or environment.

    Priority order:
    1. Command-line arguments
    2. Environment variables
    3. Config file
    4. Defaults
    """
    config = Config()

    # Try to load from config file
    if config_path:
        config_file = Path(config_path)
    else:
        # Look for config in standard locations
        config_locations = [
            Path.cwd() / ".mysql-schema.yaml",
            Path.cwd() / "mysql-schema.yaml",
            Path.home() / ".mysql-schema" / "config.yaml",
            Path("/etc/mysql-schema/config.yaml"),
        ]

        config_file = None
        for location in config_locations:
            if location.exists():
                config_file = location
                break

    if config_file and config_file.exists():
        with open(config_file, 'r') as f:
            if config_file.suffix in ['.yaml', '.yml']:
                data = yaml.safe_load(f)
            else:
                data = json.load(f)

        # Load base config
        for key, value in data.items():
            if key != 'profiles' and hasattr(config, key):
                setattr(config, key, value)

        # Load profiles
        if 'profiles' in data:
            config.profiles = data['profiles']

            # Apply selected profile
            if profile in config.profiles:
                for key, value in config.profiles[profile].items():
                    if hasattr(config, key):
                        setattr(config, key, value)

    # Override with environment variables
    env_mappings = {
        'MYSQL_SCHEMA_HOST': 'host',
        'MYSQL_SCHEMA_PORT': 'port',
        'MYSQL_SCHEMA_USERNAME': 'username',
        'MYSQL_SCHEMA_PASSWORD': 'password',
        'MYSQL_SCHEMA_API_KEY': 'api_key',
        'MYSQL_SCHEMA_DATABASE': 'default_database',
        'MYSQL_SCHEMA_MIGRATIONS_DIR': 'migrations_dir',
        'MYSQL_SCHEMA_OUTPUT_DIR': 'output_dir',
    }

    for env_var, config_key in env_mappings.items():
        value = os.getenv(env_var)
        if value:
            if config_key == 'port':
                value = int(value)
            setattr(config, config_key, value)

    return config


def save_config(config: Config, path: Optional[str] = None):
    """Save configuration to file."""
    if not path:
        path = Path.home() / ".mysql-schema" / "config.yaml"
    else:
        path = Path(path)

    # Ensure directory exists
    path.parent.mkdir(parents=True, exist_ok=True)

    # Convert config to dict
    config_dict = {
        key: value for key, value in config.__dict__.items()
        if not key.startswith('_')
    }

    # Save as YAML
    with open(path, 'w') as f:
        yaml.dump(config_dict, f, default_flow_style=False)

    console.print(f"[green]✓[/green] Configuration saved to {path}")


def get_project_root() -> Optional[Path]:
    """Find project root by looking for marker files."""
    current = Path.cwd()

    # Marker files that indicate project root
    markers = [
        '.mysql-schema.yaml',
        'mysql-schema.yaml',
        '.git',
        'docker-compose.yml',
        'migrations',
    ]

    while current != current.parent:
        for marker in markers:
            if (current / marker).exists():
                return current
        current = current.parent

    return None


def ensure_project_structure():
    """Ensure required project directories exist."""
    directories = [
        'migrations',
        'schemas',
        'data',
        'backups',
        'output',
        'config',
        'scripts',
    ]

    project_root = get_project_root() or Path.cwd()

    for dir_name in directories:
        dir_path = project_root / dir_name
        if not dir_path.exists():
            dir_path.mkdir(parents=True)
            console.print(f"[dim]Created directory: {dir_path}[/dim]")


class ApiClient:
    """API client for MySQL Schema backend."""

    def __init__(self, context: CliContext):
        self.context = context
        self.session = None
        self._setup_session()

    def _setup_session(self):
        """Setup HTTP session with authentication."""
        import requests

        self.session = requests.Session()

        # Set base URL
        self.base_url = f"http://{self.context.config.host}:{self.context.config.port}/api"

        # Set authentication
        if self.context.config.api_key:
            self.session.headers['Authorization'] = f"Bearer {self.context.config.api_key}"
        elif self.context.config.username and self.context.config.password:
            # Login to get token
            response = self.session.post(
                f"{self.base_url}/auth/login",
                json={
                    "username": self.context.config.username,
                    "password": self.context.config.password
                }
            )
            if response.ok:
                token = response.json().get('access_token')
                self.session.headers['Authorization'] = f"Bearer {token}"

    def request(self, method: str, endpoint: str, **kwargs) -> Any:
        """Make API request."""
        url = f"{self.base_url}{endpoint}"

        response = self.session.request(
            method=method,
            url=url,
            timeout=self.context.config.timeout,
            **kwargs
        )

        response.raise_for_status()

        if response.content:
            return response.json()
        return None


def format_table(data: List[Dict[str, Any]], columns: Optional[List[str]] = None):
    """Format data as a rich table."""
    from rich.table import Table

    if not data:
        return "No data"

    # Get columns from first row if not specified
    if not columns:
        columns = list(data[0].keys())

    table = Table()
    for col in columns:
        table.add_column(col.replace('_', ' ').title())

    for row in data:
        table.add_row(*[str(row.get(col, '')) for col in columns])

    return table