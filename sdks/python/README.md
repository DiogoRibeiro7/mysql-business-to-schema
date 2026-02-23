# MySQL Business-to-Schema Python SDK

Official Python SDK for MySQL Business-to-Schema system. Provides programmatic access to schema management, migrations, data generation, and monitoring.

## 🚀 Features

- **Schema Management** - Create, read, update, and delete databases and tables
- **Migration System** - Version-controlled database migrations with rollback
- **Data Generation** - Generate realistic test data for various business domains
- **Query Execution** - Execute and analyze SQL queries
- **User Management** - Manage users and permissions
- **Backup/Restore** - Create and restore database backups
- **Real-time Updates** - WebSocket support for live monitoring
- **CLI Tool** - Command-line interface for all operations

## 📦 Installation

```bash
pip install mysql-business-schema
```

Or install from source:

```bash
git clone https://github.com/yourusername/mysql-business-to-schema.git
cd mysql-business-to-schema/sdks/python
pip install -e .
```

## 🔧 Quick Start

### Basic Usage

```python
from mysql_business_schema import create_client

# Initialize client
client = create_client(
    host="localhost",
    port=8000,
    username="admin",
    password="admin123"
)

# List databases
databases = client.list_databases()
for db in databases:
    print(f"Database: {db.name} ({db.table_count} tables)")

# Get database details
db = client.get_database("my_database")
print(f"Size: {db.size_mb} MB")

# Execute a query
result = client.execute_query(
    query="SELECT * FROM users LIMIT 10",
    database="my_database"
)
print(f"Found {result.row_count} rows")
```

### Schema Management

```python
# Create a new database
new_db = client.create_database(
    name="test_db",
    charset="utf8mb4",
    collation="utf8mb4_unicode_ci"
)

# Create a table
from mysql_business_schema.models import Table, Column, Index

table = Table(
    name="users",
    columns=[
        Column(name="id", type="INT", is_primary=True, auto_increment=True),
        Column(name="username", type="VARCHAR(50)", nullable=False, is_unique=True),
        Column(name="email", type="VARCHAR(100)", nullable=False),
        Column(name="created_at", type="TIMESTAMP", default_value="CURRENT_TIMESTAMP")
    ],
    indexes=[
        Index(name="idx_email", columns=["email"])
    ]
)

client.create_table("test_db", table.dict())
```

### Migration Management

```python
# Create a migration
migration = client.create_migration(
    description="Add users table",
    up_script="""
        CREATE TABLE users (
            id INT PRIMARY KEY AUTO_INCREMENT,
            username VARCHAR(50) NOT NULL,
            email VARCHAR(100) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """,
    down_script="DROP TABLE users"
)

# Apply migrations
applied = client.apply_migration()
print(f"Applied migration: {applied.version}")

# Rollback if needed
client.rollback_migration(steps=1)
```

### Data Generation

```python
# Generate test data
generator = client.get_data_generator()

# Generate data for predefined schemas
sql_data = generator.generate(
    schema_name="clinic",  # or "ecommerce", "iot", "social_media"
    rows=1000,
    format="sql"  # or "csv", "json", "dataframe"
)

# Save to file
with open("test_data.sql", "w") as f:
    f.write(sql_data)
```

### Real-time Monitoring

```python
# Connect to WebSocket for real-time updates
ws = client.connect_websocket()

# Subscribe to events
def on_metrics(data):
    print(f"CPU Usage: {data['cpu']}%")
    print(f"Memory: {data['memory']}%")
    print(f"QPS: {data['qps']}")

ws.on("metrics:update", on_metrics)

# Subscribe to specific channels
ws.subscribe(["metrics", "alerts", "migrations"])

# Keep connection alive
import time
time.sleep(60)  # Monitor for 60 seconds

ws.disconnect()
```

### Query Analysis

```python
# Execute query with analysis
result = client.execute_query(
    query="SELECT * FROM orders WHERE status = 'pending'",
    database="ecommerce"
)

# Get execution plan
plan = client.explain_query(
    query="SELECT * FROM orders WHERE status = 'pending'",
    database="ecommerce"
)
print(f"Estimated rows: {plan['estimated_rows']}")

# Get optimization suggestions
suggestions = client.optimize_query(
    query="SELECT * FROM orders WHERE status = 'pending'",
    database="ecommerce"
)
for suggestion in suggestions['suggestions']:
    print(f"Suggestion: {suggestion}")
```

### Backup Management

```python
# Create backup
backup = client.create_backup(
    database="production_db",
    description="Daily backup",
    compression=True
)
print(f"Backup created: {backup.id}")

# List backups
backups = client.list_backups()
for b in backups:
    print(f"{b.id}: {b.database} - {b.size_mb} MB")

# Restore from backup
client.restore_backup(
    backup_id=backup.id,
    target_database="restored_db"
)
```

## 💻 CLI Usage

The SDK includes a powerful CLI tool:

```bash
# Configure credentials
export MYSQL_SCHEMA_USERNAME=admin
export MYSQL_SCHEMA_PASSWORD=admin123

# List databases
mysql-schema db list

# Create database
mysql-schema db create my_new_db

# List migrations
mysql-schema migration list

# Apply migrations
mysql-schema migration apply

# Generate test data
mysql-schema data generate clinic --rows 5000 --format sql --output clinic_data.sql

# Execute query
mysql-schema query execute "SELECT COUNT(*) FROM users" -d my_database

# Create backup
mysql-schema backup create production_db --description "Before upgrade"

# Show system status
mysql-schema status
```

## 🔧 Configuration

### Environment Variables

```bash
MYSQL_SCHEMA_USERNAME=your_username
MYSQL_SCHEMA_PASSWORD=your_password
MYSQL_SCHEMA_API_KEY=your_api_key
MYSQL_SCHEMA_HOST=localhost
MYSQL_SCHEMA_PORT=8000
```

### Configuration File

Create `~/.mysql-schema/config.json`:

```json
{
  "host": "localhost",
  "port": 8000,
  "username": "admin",
  "timeout": 30,
  "verify_ssl": true
}
```

## 📚 Advanced Usage

### Custom Data Generators

```python
from mysql_business_schema.generators import DataGenerator

class CustomGenerator(DataGenerator):
    def generate_custom_data(self, rows):
        # Your custom generation logic
        pass

generator = CustomGenerator(client)
data = generator.generate_custom_data(1000)
```

### Migration Hooks

```python
from mysql_business_schema.migrations import MigrationManager

manager = MigrationManager(client)

# Create migration from database diff
migration = manager.generate_migration_from_diff(
    source_database="dev_db",
    target_database="prod_db",
    name="sync_prod_schema"
)

# Load migrations from directory
migrations = manager.load_migrations_from_directory(Path("./migrations"))
```

### Error Handling

```python
from mysql_business_schema.exceptions import (
    AuthenticationError,
    ValidationError,
    NotFoundError,
    MigrationError
)

try:
    client.create_database("test")
except AuthenticationError as e:
    print(f"Authentication failed: {e}")
except ValidationError as e:
    print(f"Validation error: {e.details}")
except NotFoundError as e:
    print(f"Resource not found: {e.details['resource']}")
except MigrationError as e:
    print(f"Migration failed: {e.details['migration_id']}")
```

## 🧪 Testing

```bash
# Install dev dependencies
pip install -e ".[dev]"

# Run tests
pytest tests/

# Run with coverage
pytest tests/ --cov=mysql_business_schema --cov-report=html

# Run linting
flake8 src/
mypy src/
black src/
```

## 📖 API Reference

### Client Methods

| Method | Description | Returns |
|--------|-------------|---------|
| `list_databases()` | List all databases | `List[Database]` |
| `get_database(name)` | Get database details | `Database` |
| `create_database(...)` | Create new database | `Database` |
| `list_tables(database)` | List tables in database | `List[Table]` |
| `create_table(...)` | Create new table | `Table` |
| `list_migrations()` | List migrations | `List[Migration]` |
| `apply_migration(...)` | Apply migrations | `Migration` |
| `rollback_migration(...)` | Rollback migrations | `Migration` |
| `execute_query(...)` | Execute SQL query | `QueryResult` |
| `create_backup(...)` | Create backup | `Backup` |
| `restore_backup(...)` | Restore from backup | `Dict` |

### Models

- `Database` - Database schema information
- `Table` - Table definition with columns and indexes
- `Column` - Column definition with constraints
- `Migration` - Migration definition and status
- `Query` - Query definition and metadata
- `Backup` - Backup information and status
- `User` - User account and permissions

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📝 License

MIT License - see LICENSE file for details

## 🆘 Support

- Documentation: [Read the Docs](https://mysql-business-schema.readthedocs.io/)
- Issues: [GitHub Issues](https://github.com/yourusername/mysql-business-to-schema/issues)
- Discussions: [GitHub Discussions](https://github.com/yourusername/mysql-business-to-schema/discussions)

## 🔗 Links

- [PyPI Package](https://pypi.org/project/mysql-business-schema/)
- [GitHub Repository](https://github.com/yourusername/mysql-business-to-schema)
- [API Documentation](https://mysql-business-schema.readthedocs.io/)
- [Examples](https://github.com/yourusername/mysql-business-to-schema/tree/main/examples)