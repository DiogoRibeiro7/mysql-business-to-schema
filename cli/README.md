# MySQL Schema CLI

A powerful, unified command-line interface for the MySQL Business-to-Schema system. Manage schemas, migrations, generate test data, monitor performance, and deploy with ease.

## 🚀 Features

- **Project Management** - Initialize and manage MySQL schema projects
- **Data Generation** - Generate realistic test data for multiple business domains
- **Schema Management** - Create, modify, and compare database schemas
- **Migration Control** - Version-controlled migrations with rollback support
- **Query Execution** - Execute and analyze SQL queries
- **Backup & Restore** - Automated backup management
- **Monitoring** - Real-time performance monitoring
- **Docker Integration** - Manage Docker containers
- **Kubernetes Deployment** - Deploy to K8s clusters
- **Interactive Mode** - Guided wizards for complex operations
- **Auto-completion** - Shell completion for all commands

## 📦 Installation

### Using pip

```bash
pip install mysql-schema-cli
```

### From source

```bash
git clone https://github.com/yourusername/mysql-business-to-schema.git
cd mysql-business-to-schema/cli
pip install -e .
```

### Enable auto-completion

```bash
# Bash
mysql-schema completion --shell bash >> ~/.bashrc

# Zsh
mysql-schema completion --shell zsh >> ~/.zshrc

# Fish
mysql-schema completion --shell fish > ~/.config/fish/completions/mysql-schema.fish

# PowerShell
mysql-schema completion --shell powershell >> $PROFILE
```

## 🔧 Quick Start

### Initialize a new project

```bash
# Interactive initialization
mysql-schema init --interactive

# Quick initialization
mysql-schema init myproject --template microservice

# Full project with CI/CD
mysql-schema init myapp --docker --k8s --ci --git
```

### Generate test data

```bash
# Generate 5000 rows for clinic schema
mysql-schema generate data clinic --rows 5000

# Generate e-commerce data in CSV format
mysql-schema generate data ecommerce --format csv --output data.csv

# Generate with compression and parallel processing
mysql-schema generate data iot_sensors --rows 100000 --parallel --compress
```

### Create and manage schemas

```bash
# Generate schema from template
mysql-schema generate schema microservice --name user_service

# Create database
mysql-schema schema create mydb --charset utf8mb4

# Compare schemas
mysql-schema schema diff dev_db prod_db

# Export schema
mysql-schema schema export mydb --output schema.sql
```

### Database migrations

```bash
# Create a new migration
mysql-schema migrate create "Add users table"

# Apply pending migrations
mysql-schema migrate up

# Rollback last migration
mysql-schema migrate down

# Check migration status
mysql-schema migrate status

# Dry run (preview changes)
mysql-schema migrate up --dry-run
```

### Query execution

```bash
# Execute query
mysql-schema query execute "SELECT COUNT(*) FROM users" -d mydb

# Explain query plan
mysql-schema query explain "SELECT * FROM orders WHERE status='pending'" -d mydb

# Analyze slow queries
mysql-schema query analyze --slow --last 24h
```

### Backup management

```bash
# Create backup
mysql-schema backup create production_db --compress

# List backups
mysql-schema backup list

# Restore from backup
mysql-schema backup restore backup_20240101_120000.sql --target restored_db

# Schedule automatic backups
mysql-schema backup schedule --daily --time 02:00
```

### Monitoring

```bash
# Show system status
mysql-schema monitor status

# Watch real-time metrics
mysql-schema monitor metrics --watch

# Show slow queries
mysql-schema monitor slow-queries --limit 10

# Check connections
mysql-schema monitor connections
```

### Docker operations

```bash
# Start Docker containers
mysql-schema docker up

# Stop containers
mysql-schema docker down

# View logs
mysql-schema docker logs --follow

# Execute in container
mysql-schema docker exec mysql "SHOW DATABASES"
```

### Kubernetes deployment

```bash
# Deploy to Kubernetes
mysql-schema deploy k8s --namespace production

# Scale deployment
mysql-schema deploy scale --replicas 3

# Update deployment
mysql-schema deploy update --image mysql:8.0.35

# Rollback deployment
mysql-schema deploy rollback
```

## 📁 Project Structure

When you initialize a project, the following structure is created:

```
myproject/
├── .mysql-schema.yaml      # Project configuration
├── migrations/             # Database migrations
│   ├── 001_initial.sql
│   └── 002_add_users.sql
├── schemas/               # Schema definitions
│   ├── tables/
│   └── views/
├── data/                  # Test data files
├── backups/              # Database backups
├── scripts/              # Custom scripts
├── docker/               # Docker configuration
│   └── docker-compose.yml
├── k8s/                  # Kubernetes manifests
│   ├── deployment.yaml
│   └── service.yaml
├── tests/                # Test files
└── README.md            # Project documentation
```

## ⚙️ Configuration

### Global configuration

```bash
# Set default host
mysql-schema config set host localhost

# Set default database
mysql-schema config set database mydb

# View configuration
mysql-schema config show

# Edit configuration file
mysql-schema config edit
```

### Project configuration (.mysql-schema.yaml)

```yaml
# Connection settings
host: localhost
port: 8000
username: admin
default_database: myproject

# Generation settings
default_rows: 1000
default_format: sql
faker_locale: en_US

# Migration settings
migrations_dir: ./migrations
auto_backup: true

# Docker settings
docker_compose_file: docker-compose.yml
docker_network: mysql-schema-network

# Profiles for different environments
profiles:
  dev:
    host: localhost
    database: myproject_dev
  prod:
    host: prod.example.com
    database: myproject_prod
```

### Environment variables

```bash
export MYSQL_SCHEMA_HOST=localhost
export MYSQL_SCHEMA_PORT=8000
export MYSQL_SCHEMA_USERNAME=admin
export MYSQL_SCHEMA_PASSWORD=secret
export MYSQL_SCHEMA_DATABASE=mydb
```

## 🎯 Command Aliases

For faster workflow, use command aliases:

| Alias | Full Command |
|-------|--------------|
| `g` | `generate` |
| `m` | `migrate` |
| `q` | `query` |
| `b` | `backup` |
| `s` | `schema` |
| `d` | `deploy` |
| `mon` | `monitor` |

Examples:
```bash
mysql-schema g data clinic --rows 1000
mysql-schema m up
mysql-schema q execute "SELECT 1"
```

## 🎮 Interactive Mode

Start interactive mode for guided operations:

```bash
# General interactive mode
mysql-schema interactive

# Interactive data generation
mysql-schema generate interactive

# Interactive migration wizard
mysql-schema migrate interactive
```

## 📊 Output Formats

Control output format for automation:

```bash
# JSON output
mysql-schema schema list --json

# Table format (default)
mysql-schema backup list

# CSV output
mysql-schema monitor metrics --format csv

# No color output
mysql-schema --no-color schema list
```

## 🔍 Verbose and Debug Modes

```bash
# Verbose output
mysql-schema -v migrate up

# Very verbose (debug)
mysql-schema -vv generate data clinic

# Show stack traces
mysql-schema --debug schema create test
```

## 📝 Examples

### Complete workflow example

```bash
# 1. Initialize project
mysql-schema init myapp --template microservice

# 2. Navigate to project
cd myapp

# 3. Start Docker containers
mysql-schema docker up

# 4. Create initial schema
mysql-schema generate schema microservice --name users

# 5. Apply schema
mysql-schema migrate up

# 6. Generate test data
mysql-schema generate data clinic --rows 10000

# 7. Create backup
mysql-schema backup create users_db

# 8. Monitor performance
mysql-schema monitor status

# 9. Deploy to Kubernetes
mysql-schema deploy k8s
```

### CI/CD Integration

```yaml
# GitHub Actions example
- name: Install CLI
  run: pip install mysql-schema-cli

- name: Run migrations
  run: mysql-schema migrate up --dry-run

- name: Generate test data
  run: mysql-schema generate data clinic --rows 1000

- name: Run tests
  run: mysql-schema test run
```

## 🆘 Troubleshooting

### Check CLI version
```bash
mysql-schema --version
```

### Validate configuration
```bash
mysql-schema validate
```

### Test connection
```bash
mysql-schema test connection
```

### View logs
```bash
mysql-schema logs --tail 100
```

### Reset configuration
```bash
mysql-schema config reset
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Open a pull request

## 📝 License

MIT License - see LICENSE file for details

## 🔗 Links

- [Documentation](https://mysql-business-schema.readthedocs.io/)
- [GitHub Repository](https://github.com/yourusername/mysql-business-to-schema)
- [Issue Tracker](https://github.com/yourusername/mysql-business-to-schema/issues)
- [PyPI Package](https://pypi.org/project/mysql-schema-cli/)

---

Built with ❤️ for database developers and administrators