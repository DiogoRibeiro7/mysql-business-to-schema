# MySQL Database Migration System

A comprehensive, production-ready migration system for MySQL databases with version control, rollback capabilities, and automated schema change management.

## 🌟 Features

- **Version Control**: Track all database schema changes with versioned migrations
- **Rollback Support**: Every migration can include a rollback script for easy reversal
- **Auto-Generation**: Generate migrations from schema differences automatically
- **Validation**: Built-in validation for dangerous operations and syntax checking
- **Dry-Run Mode**: Test migrations without applying them
- **Production Safety**: Special checks and warnings for production environments
- **Migration History**: Complete audit trail of all applied migrations
- **Checksum Verification**: Detect when migration files have been modified
- **Conflict Detection**: Identify and prevent conflicting operations
- **CLI Interface**: User-friendly command-line interface

## 📋 Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Migration Files](#migration-files)
- [CLI Commands](#cli-commands)
- [Advanced Usage](#advanced-usage)
- [Production Deployment](#production-deployment)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## 🚀 Installation

### Requirements

- Python 3.7+
- MySQL 5.7+ or MySQL 8.0+
- Required Python packages:
  ```bash
  pip install mysql-connector-python click tabulate sqlparse
  ```

### Setup

1. **Clone or copy the migration system**:
   ```bash
   cd your-project
   cp -r path/to/migration_system .
   ```

2. **Make the CLI executable**:
   ```bash
   chmod +x migrate
   # Or on Windows, use migrate.bat
   ```

3. **Initialize the migration system**:
   ```bash
   ./migrate init --user root --password yourpass --database mydb
   ```

## 🎯 Quick Start

### 1. Initialize Migration System

```bash
./migrate init \
  --host localhost \
  --port 3306 \
  --user root \
  --password yourpass \
  --database myapp_db
```

This creates:
- `.migration-config.json` - Database configuration
- `migrations/` directory - Where migration files are stored
- `schema_migrations` table - Tracks applied migrations

### 2. Create Your First Migration

**Option A: Generate from SQL file**
```bash
./migrate generate \
  --description "Create users table" \
  --from-file schema/users.sql \
  --include-rollback
```

**Option B: Create empty template**
```bash
./migrate generate \
  --description "Create users table" \
  --type sql
```

**Option C: Auto-generate from database differences**
```bash
./migrate diff \
  --source dev_db \
  --target prod_db \
  --output migrations/sync_prod.sql
```

### 3. Review Migration

```bash
# Show migration details
./migrate show V001_20240120_100000

# Validate migration
./migrate validate
```

### 4. Apply Migrations

```bash
# Dry run first (preview without applying)
./migrate up --dry-run

# Apply all pending migrations
./migrate up

# Apply up to specific version
./migrate up --target V002_20240120_110000
```

### 5. Check Status

```bash
# Show migration status
./migrate status

# Show migration history
./migrate history
```

### 6. Rollback if Needed

```bash
# Rollback last migration
./migrate down

# Rollback multiple migrations
./migrate down --steps 2

# Rollback to specific version
./migrate down --target V001_20240120_100000
```

## 📁 Migration Files

### File Naming Convention

```
V{version}__{description}.sql
```

Examples:
- `V001__initial_schema.sql`
- `V002_20240120_143000__add_users_table.sql`
- `V003__add_indexes.sql`

### Migration Structure

```sql
-- Migration: Description of changes
-- Generated: 2024-01-20T10:00:00

-- ============================================
-- UP MIGRATION
-- ============================================

CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE
);

-- ============================================
-- ==== ROLLBACK ====
-- ============================================

DROP TABLE IF EXISTS users;
```

### Python Migrations

For complex migrations requiring logic:

```python
"""
Migration: Complex data transformation
Generated: 2024-01-20T10:00:00
"""

def up(connection):
    """Execute forward migration."""
    cursor = connection.cursor()

    # Complex migration logic
    cursor.execute("SELECT * FROM old_table")
    for row in cursor.fetchall():
        # Transform data
        transformed = transform_data(row)
        cursor.execute("INSERT INTO new_table VALUES (%s)", transformed)

    connection.commit()
    cursor.close()

def down(connection):
    """Execute rollback migration."""
    cursor = connection.cursor()
    cursor.execute("DROP TABLE new_table")
    connection.commit()
    cursor.close()
```

## 💻 CLI Commands

### `init` - Initialize Migration System

```bash
./migrate init [OPTIONS]

Options:
  -h, --host TEXT        Database host [default: localhost]
  -p, --port INTEGER     Database port [default: 3306]
  -u, --user TEXT        Database user [required]
  -P, --password TEXT    Database password [prompted if not provided]
  -d, --database TEXT    Database name [required]
  --migrations-path TEXT Path to migrations directory [default: migrations]
```

### `up` - Run Migrations

```bash
./migrate up [OPTIONS]

Options:
  -t, --target TEXT     Target version to migrate to
  --dry-run            Preview migrations without executing
  -f, --force          Skip confirmation prompt
```

### `down` - Rollback Migrations

```bash
./migrate down [OPTIONS]

Options:
  -t, --target TEXT     Target version to rollback to
  -s, --steps INTEGER   Number of migrations to rollback
  -f, --force          Skip confirmation prompt
```

### `status` - Show Migration Status

```bash
./migrate status
```

Output:
```
📊 Migration Status
==================================================
Total migrations:   5
Applied migrations: 3
Pending migrations: 2

Last migration:
  Version:     V003_20240120_150000
  Description: Add user roles
  Applied:     2024-01-20 15:30:00
  By:          admin

Pending migrations:
  • V004_20240121_100000
  • V005_20240121_110000
```

### `history` - Show Migration History

```bash
./migrate history [OPTIONS]

Options:
  -n, --limit INTEGER   Number of migrations to show [default: 10]
  -a, --all            Show all migrations
```

### `generate` - Generate New Migration

```bash
./migrate generate [OPTIONS]

Options:
  -d, --description TEXT  Migration description [required]
  -t, --type CHOICE      Migration type (auto|sql|python) [default: auto]
  -f, --from-file PATH   Generate from SQL file
  --include-rollback     Generate rollback script
```

### `validate` - Validate Migrations

```bash
./migrate validate [OPTIONS]

Options:
  --production         Use production validation rules (stricter)
```

### `show` - Show Migration Details

```bash
./migrate show VERSION
```

### `diff` - Generate Migration from Database Differences

```bash
./migrate diff [OPTIONS]

Options:
  -s, --source TEXT    Source database [required]
  -t, --target TEXT    Target database [required]
  -o, --output PATH    Output migration file
```

### `repair` - Repair Failed Migration

```bash
./migrate repair VERSION [OPTIONS]

Options:
  -f, --force          Force repair without confirmation
```

## 🔧 Advanced Usage

### Custom Migration Paths

```bash
# Use different migrations directory
./migrate --config custom-config.json up

# Or specify in init
./migrate init --migrations-path db/migrations
```

### Production Deployment

```bash
# 1. Validate with production rules
./migrate validate --production

# 2. Dry run
./migrate up --dry-run

# 3. Apply with monitoring
./migrate up --target V005_20240121_110000
```

### Handling Failed Migrations

```bash
# Check what failed
./migrate status

# Option 1: Fix and mark as completed
./migrate repair V004_20240121_100000

# Option 2: Rollback and retry
./migrate down --steps 1
# Fix the migration file
./migrate up
```

### Batch Operations

```bash
# Apply multiple migrations from directory
for file in pending/*.sql; do
  ./migrate generate --from-file "$file" --description "$(basename $file)"
done

# Apply all
./migrate up
```

## 🏭 Production Deployment

### Pre-deployment Checklist

1. **Backup Database**:
   ```bash
   mysqldump -u root -p mydb > backup_$(date +%Y%m%d_%H%M%S).sql
   ```

2. **Validate Migrations**:
   ```bash
   ./migrate validate --production
   ```

3. **Test in Staging**:
   ```bash
   # Apply to staging first
   ./migrate --config staging-config.json up
   ```

4. **Schedule Maintenance Window** (if needed):
   - For ALTER TABLE on large tables
   - For operations requiring locks
   - For data migrations

### Deployment Script

```bash
#!/bin/bash
# deploy_migrations.sh

set -e

echo "🔍 Pre-deployment checks..."
./migrate validate --production || exit 1

echo "💾 Creating backup..."
mysqldump -u root -p"$DB_PASS" mydb > "backup_$(date +%Y%m%d_%H%M%S).sql"

echo "🚀 Applying migrations..."
./migrate up --force

echo "✅ Verifying..."
./migrate status

echo "🎉 Deployment complete!"
```

## ✅ Best Practices

### 1. Migration Design

- **Keep migrations small and focused** - One logical change per migration
- **Always include rollback scripts** - Even if it's just a comment explaining why rollback isn't possible
- **Test rollbacks** - Ensure they actually work
- **Use transactions** - Wrap DDL operations in transactions where supported
- **Add comments** - Explain why changes are being made

### 2. Naming Conventions

- Use descriptive names: `V001__create_users_table.sql` not `V001__update.sql`
- Include dates for better tracking: `V002_20240120_143000__add_email_index.sql`
- Group related changes: `V003__user_system_improvements.sql`

### 3. Safety Rules

- **Never modify existing migrations** - Create new ones instead
- **Don't use `CASCADE` in production** without careful consideration
- **Avoid `NOT NULL` without defaults** on existing columns with data
- **Be careful with `UNIQUE` constraints** on existing data
- **Test migrations on production-like data volumes**

### 4. Performance Considerations

- **Add indexes in separate migrations** - They can be slow on large tables
- **Use online DDL** for large table modifications:
  ```sql
  ALTER TABLE large_table ADD COLUMN new_col INT, ALGORITHM=INPLACE, LOCK=NONE;
  ```
- **Consider pt-online-schema-change** for very large tables
- **Monitor replication lag** during migrations

### 5. Team Collaboration

- **Coordinate migration numbers** - Avoid conflicts
- **Document breaking changes** - In migration comments
- **Review migrations** - Before applying to production
- **Keep migrations in version control** - Always

## 🔍 Troubleshooting

### Common Issues

#### 1. Migration Checksum Mismatch

**Error**: `Checksum mismatch - migration file has been modified`

**Solution**:
```bash
# Option 1: Restore original file from version control
git checkout migrations/V001__initial_schema.sql

# Option 2: Force update (dangerous!)
# Manually update checksum in schema_migrations table
```

#### 2. Foreign Key Constraint Failures

**Error**: `Cannot delete or update a parent row: a foreign key constraint fails`

**Solution**:
```sql
-- Temporarily disable foreign key checks
SET FOREIGN_KEY_CHECKS = 0;
-- Run migration
-- Re-enable checks
SET FOREIGN_KEY_CHECKS = 1;
```

#### 3. Locked Tables During Migration

**Error**: `Lock wait timeout exceeded`

**Solution**:
```bash
# Check for locks
SHOW PROCESSLIST;

# Kill blocking queries
KILL <process_id>;
```

#### 4. Out of Sync Migrations

**Error**: `Migration V002 not found but V003 is applied`

**Solution**:
```bash
# Add missing migration to history
mysql> INSERT INTO schema_migrations
       (version, description, status, applied_at)
       VALUES ('V002', 'Missing migration', 'completed', NOW());
```

### Debug Mode

```bash
# Enable verbose logging
export MIGRATION_DEBUG=1
./migrate up

# Check migration files
ls -la migrations/
cat migrations/V001__initial_schema.sql

# Check history table
mysql -u root -p mydb -e "SELECT * FROM schema_migrations ORDER BY applied_at DESC LIMIT 10"
```

## 📚 Examples

### Example 1: Adding a New Table

```sql
-- migrations/V004__create_products_table.sql

-- UP
CREATE TABLE products (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(200) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    category_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(id),
    INDEX idx_category (category_id),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB;

-- ==== ROLLBACK ====
DROP TABLE IF EXISTS products;
```

### Example 2: Complex Data Migration

```sql
-- migrations/V005__migrate_user_emails.sql

-- UP
-- Add new email_verified column
ALTER TABLE users ADD COLUMN email_verified BOOLEAN DEFAULT FALSE;

-- Migrate data from old system
UPDATE users u
JOIN legacy_verifications lv ON u.email = lv.email
SET u.email_verified = TRUE
WHERE lv.verified = 1;

-- Clean up
DROP TABLE legacy_verifications;

-- ==== ROLLBACK ====
-- Recreate legacy table
CREATE TABLE legacy_verifications AS
SELECT email, email_verified as verified
FROM users WHERE email_verified = TRUE;

-- Remove column
ALTER TABLE users DROP COLUMN email_verified;
```

### Example 3: Adding Index to Large Table

```sql
-- migrations/V006__add_user_email_index.sql

-- UP
-- Use ALGORITHM=INPLACE for online DDL
ALTER TABLE users
ADD INDEX idx_email_domain (email(50)),
ALGORITHM=INPLACE,
LOCK=NONE;

-- ==== ROLLBACK ====
ALTER TABLE users
DROP INDEX idx_email_domain,
ALGORITHM=INPLACE,
LOCK=NONE;
```

## 🔗 Architecture

The migration system consists of several key components:

1. **Core (`core.py`)**: Migration execution engine, history tracking, rollback support
2. **Generator (`generator.py`)**: Auto-generation of migrations from schema differences
3. **Validator (`validator.py`)**: Safety checks, syntax validation, production rules
4. **CLI (`cli.py`)**: User-friendly command-line interface
5. **Migration Files**: Version-controlled SQL/Python scripts

## 🤝 Contributing

Contributions are welcome! Areas for improvement:

1. Support for more database systems (PostgreSQL, SQLite)
2. Web interface for migration management
3. Enhanced conflict resolution
4. Migration scheduling and automation
5. Cloud database support (AWS RDS, Azure SQL, Google Cloud SQL)
6. Schema versioning and branching
7. Data migration capabilities (not just schema)

## 📝 License

This migration system is part of the MySQL Business-to-Schema project.

## 📞 Support

For issues and questions:
- Open an issue on GitHub
- Check existing documentation
- Review troubleshooting section

---

**⚠️ Important**: Always backup your database before running migrations in production!