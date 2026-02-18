# 🚀 Automated Database Migration System

A powerful, automated system for migrating database schemas between different database systems. Currently supports migrations from MySQL to PostgreSQL and MongoDB.

## ✨ Features

### 🔄 Supported Migrations
- **MySQL → PostgreSQL**: Full schema conversion with data type mapping
- **MySQL → MongoDB**: Document-oriented structure with JSON schema validation
- **Rollback Support**: Automatic generation of rollback scripts
- **Version Control**: Track migration history and status

### 🎯 Key Capabilities

#### Schema Parsing
- Automatic extraction of tables, columns, and constraints
- Foreign key relationship preservation
- Index detection and recreation
- Comment and metadata preservation

#### Intelligent Data Type Mapping
- **Numeric Types**: TINYINT → SMALLINT, BIGINT UNSIGNED → NUMERIC(20)
- **String Types**: TEXT variations unified, ENUM → VARCHAR
- **JSON Support**: MySQL JSON → PostgreSQL JSONB / MongoDB Object
- **Date/Time**: Proper timestamp handling across systems
- **Binary Data**: BLOB → BYTEA (PostgreSQL) / BinData (MongoDB)

#### Advanced Features
- Transaction support for safe migrations
- Checksum verification for migration integrity
- Dry-run mode for testing
- Progress tracking and logging
- Batch processing for large schemas

## 📦 Installation

```bash
# Install required packages
pip install -r requirements.txt
```

### Requirements
- Python 3.7+
- Database-specific drivers (automatically installed)

## 🚀 Quick Start

### 1. Create a Migration

```bash
# MySQL to PostgreSQL
python migrate.py create \
  --name "user_tables" \
  --source /path/to/schema.sql \
  --target-type postgresql

# MySQL to MongoDB
python migrate.py create \
  --name "user_collections" \
  --source /path/to/schema.sql \
  --target-type mongodb
```

### 2. List Migrations

```bash
python migrate.py list
```

Output:
```
Available Migrations:
┌──────────────────────────┬──────────────┬───────────────────┬──────────┬─────────────────┐
│ Migration ID             │ Name         │ Type              │ Status   │ Created         │
├──────────────────────────┼──────────────┼───────────────────┼──────────┼─────────────────┤
│ 20240218_143022_user_... │ user_tables  │ mysql → postgresql│ pending  │ 2024-02-18 14:30│
└──────────────────────────┴──────────────┴───────────────────┴──────────┴─────────────────┘
```

### 3. Execute Migration

```bash
# PostgreSQL
python migrate.py execute \
  --migration-id 20240218_143022_user_tables \
  --host localhost \
  --port 5432 \
  --user postgres \
  --password secret \
  --database target_db

# MongoDB
python migrate.py execute \
  --migration-id 20240218_143022_user_collections \
  --host localhost \
  --port 27017 \
  --database target_db
```

### 4. Rollback (if needed)

```bash
python migrate.py rollback \
  --migration-id 20240218_143022_user_tables \
  --database target_db \
  --user postgres \
  --password secret
```

## 📝 Example Migrations

### MySQL Source Schema
```sql
CREATE TABLE users (
    user_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    metadata JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;
```

### Generated PostgreSQL Migration
```sql
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Generated MongoDB Migration
```javascript
db.createCollection('users');
db.users.createIndex({ user_id: 1 }, { unique: true });
db.users.createIndex({ email: 1 }, { unique: true });

db.runCommand({
    collMod: 'users',
    validator: {
        $jsonSchema: {
            bsonType: 'object',
            required: ['email'],
            properties: {
                user_id: { bsonType: 'long' },
                email: { bsonType: 'string', maxLength: 255 },
                metadata: { bsonType: 'object' },
                created_at: { bsonType: 'date' }
            }
        }
    }
});
```

## 🎮 Demo

Run the interactive demo to see the migration system in action:

```bash
python demo_migration.py
```

This will:
1. Create sample migrations for an e-commerce schema
2. Show PostgreSQL and MongoDB conversions
3. Display data type mappings
4. Generate rollback scripts

## 📁 Project Structure

```
migration_system/
├── migration_manager.py      # Core migration logic
├── migration_executor.py     # Database execution engine
├── migrate.py               # CLI interface
├── demo_migration.py        # Interactive demonstration
├── requirements.txt         # Package dependencies
├── README.md               # This file
└── migrations/             # Generated migrations directory
    ├── up/                 # Forward migration scripts
    ├── down/              # Rollback scripts
    └── *.json            # Migration metadata
```

## 🛠️ Advanced Usage

### Dry Run Mode
Test migrations without making changes:
```bash
python migrate.py execute --migration-id <id> --dry-run --database test_db
```

### Custom Migration Directory
```python
from migration_manager import MigrationManager

manager = MigrationManager(migrations_dir='/custom/path/migrations')
```

### Programmatic Usage
```python
from migration_manager import MigrationManager, DatabaseType
from migration_executor import MigrationExecutor

# Create migration
manager = MigrationManager()
migration = manager.create_migration(
    name="my_schema",
    source_file="schema.sql",
    source_type=DatabaseType.MYSQL,
    target_type=DatabaseType.POSTGRESQL
)

# Execute migration
executor = MigrationExecutor()
result = executor.execute_migration(
    migration.id,
    {'host': 'localhost', 'database': 'mydb', 'user': 'postgres'}
)
```

## 🔍 Data Type Mapping Reference

### MySQL to PostgreSQL

| MySQL | PostgreSQL | Notes |
|-------|------------|-------|
| TINYINT | SMALLINT | Expanded range |
| INT UNSIGNED | BIGINT | Handles unsigned |
| DECIMAL(p,s) | DECIMAL(p,s) | Precision preserved |
| VARCHAR(n) | VARCHAR(n) | Direct mapping |
| TEXT | TEXT | All TEXT types unified |
| JSON | JSONB | Binary JSON for performance |
| DATETIME | TIMESTAMP | Timezone aware |
| ENUM | VARCHAR | Check constraints recommended |
| BLOB | BYTEA | Binary data |

### MySQL to MongoDB

| MySQL | MongoDB | Notes |
|-------|---------|-------|
| INT/BIGINT | Int32/Long | Size-appropriate |
| DECIMAL | Decimal128 | Precise decimal |
| VARCHAR | String | No length limit |
| JSON | Object | Native document |
| DATETIME | Date | ISODate format |
| BLOB | BinData | Binary storage |
| Foreign Keys | References | Application-level |

## ⚙️ Configuration

### Environment Variables
```bash
export MIGRATION_DIR=/path/to/migrations
export DB_HOST=localhost
export DB_PORT=5432
export DB_USER=postgres
```

### Migration Status

| Status | Description |
|--------|-------------|
| `pending` | Created but not executed |
| `in_progress` | Currently executing |
| `completed` | Successfully executed |
| `failed` | Execution failed |
| `rolled_back` | Successfully rolled back |

## 🐛 Troubleshooting

### Common Issues

1. **Connection Failed**
   ```
   Error: Failed to connect to PostgreSQL
   ```
   - Check database credentials
   - Ensure database server is running
   - Verify network connectivity

2. **Data Type Not Supported**
   ```
   Error: Unsupported data type: GEOMETRY
   ```
   - Check data type mapping table
   - Consider custom type handling
   - Use TEXT as fallback

3. **Foreign Key Constraints**
   ```
   Error: Foreign key constraint violation
   ```
   - Ensure proper migration order
   - Consider disabling constraints during migration
   - Check referential integrity

## 📊 Performance Tips

1. **Large Schemas**: Break into multiple migrations
2. **Indexes**: Create indexes after data migration
3. **Transactions**: Use appropriate isolation levels
4. **Monitoring**: Track execution time and resource usage
5. **Testing**: Always test on a staging environment first

## 🤝 Contributing

Contributions are welcome! Areas for improvement:

1. Add support for more database systems (SQLite, Oracle, SQL Server)
2. Implement data migration (not just schema)
3. Add schema diffing capabilities
4. Create web interface for migration management
5. Add support for stored procedures and triggers
6. Implement migration scheduling
7. Add cloud database support (AWS RDS, Azure SQL)

## 📝 License

MIT License - Part of the MySQL Business-to-Schema project

## 🙋 Support

For issues, questions, or suggestions:
- Open an issue on GitHub
- Check existing documentation
- Run demo for examples

---

**Note**: Always backup your database before running migrations in production!