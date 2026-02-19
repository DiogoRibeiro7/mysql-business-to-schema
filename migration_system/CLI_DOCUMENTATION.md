# Migration CLI Documentation

## Overview

The Migration CLI is a powerful command-line tool for managing database schema migrations from MySQL to PostgreSQL and MongoDB. It provides a unified interface for creating, managing, and executing database migrations.

## Installation

### Prerequisites
```bash
# Install required Python package
pip install colorama
```

### Setup
```bash
# Make the CLI executable (Unix/Linux/Mac)
chmod +x migration_cli

# Windows users can use migration_cli.bat
```

## Quick Start

```bash
# Create a migration from MySQL to PostgreSQL
./migration_cli create my_migration example_01_clinic/schema/01_tables.sql postgresql

# List all migrations
./migration_cli list

# Show details of a specific migration
./migration_cli show 20260219_084056_my_migration

# Batch migrate all examples to PostgreSQL
./migration_cli batch postgresql
```

## Commands

### 1. `create` - Create a New Migration

Create a migration from a MySQL schema to PostgreSQL or MongoDB.

**Syntax:**
```bash
migration_cli create <name> <source_file> <target_type> [options]
```

**Arguments:**
- `name`: Name for the migration (e.g., "clinic_to_postgres")
- `source_file`: Path to MySQL schema SQL file
- `target_type`: Target database type (`postgresql` or `mongodb`)

**Options:**
- `--source-type`: Source database type (default: `mysql`)
- `-o, --output`: Output directory (default: `migrations`)
- `-p, --preview`: Show migration preview

**Examples:**
```bash
# Basic migration
./migration_cli create clinic_migration example_01_clinic/schema/01_tables.sql postgresql

# With preview
./migration_cli create -p ecommerce_migration example_04_ecommerce/schema/01_tables.sql mongodb

# Custom output directory
./migration_cli create -o my_migrations iot_migration example_02_iot_bins/schema/01_tables.sql postgresql
```

### 2. `list` - List All Migrations

Display all migrations in the migrations directory.

**Syntax:**
```bash
migration_cli list [options]
```

**Options:**
- `-d, --dir`: Migrations directory to list (default: `migrations`)

**Examples:**
```bash
# List migrations in default directory
./migration_cli list

# List migrations in custom directory
./migration_cli list -d my_migrations
```

**Output:**
```
Found 5 migration(s) in 'migrations':

ID                                   Name                      Source->Target       Status
------------------------------------------------------------------------------------------
20260219_084056_clinic_to_postgres   clinic_to_postgres       mysql->postgresql    pending
20260219_084057_iot_to_mongo         iot_to_mongo            mysql->mongodb       completed
20260219_084058_ecommerce_to_pg      ecommerce_to_pg         mysql->postgresql    failed

Total: 5 | Pending: 2 | Completed: 2 | Failed: 1
```

### 3. `show` - Show Migration Details

Display detailed information about a specific migration.

**Syntax:**
```bash
migration_cli show <migration_id> [options]
```

**Arguments:**
- `migration_id`: ID of the migration to show

**Options:**
- `-d, --dir`: Migrations directory (default: `migrations`)
- `-s, --show-sql`: Show SQL content preview

**Examples:**
```bash
# Show basic details
./migration_cli show 20260219_084056_clinic_to_postgres

# Show with SQL preview
./migration_cli show -s 20260219_084056_clinic_to_postgres
```

### 4. `validate` - Validate a Migration

Check if a migration script is valid and properly formatted.

**Syntax:**
```bash
migration_cli validate <migration_id> [options]
```

**Arguments:**
- `migration_id`: ID of the migration to validate

**Options:**
- `-d, --dir`: Migrations directory (default: `migrations`)

**Examples:**
```bash
# Validate a migration
./migration_cli validate 20260219_084056_clinic_to_postgres
```

**Output:**
```
Validating: migrations/up/20260219_084056_clinic_to_postgres.sql

  [PASS] Has CREATE statements
  [PASS] Has table definitions
  [PASS] No syntax errors (basic)
  [PASS] Has proper endings
  [PASS] UTF-8 encoded
  [PASS] PostgreSQL types
  [PASS] No MySQL specific

Validation PASSED - Migration appears valid
```

### 5. `batch` - Batch Create Migrations

Create migrations for multiple schemas at once.

**Syntax:**
```bash
migration_cli batch <target_type> [options]
```

**Arguments:**
- `target_type`: Target database type (`postgresql` or `mongodb`)

**Options:**
- `-p, --pattern`: Schema file pattern (glob) (default: `example_*/schema/01_tables.sql`)
- `-o, --output`: Output directory (default: `migrations`)

**Examples:**
```bash
# Migrate all examples to PostgreSQL
./migration_cli batch postgresql

# Migrate specific pattern to MongoDB
./migration_cli batch mongodb -p "example_0[1-5]*/schema/*.sql"

# Custom output directory
./migration_cli batch postgresql -o batch_migrations
```

### 6. `export` - Export Migration

Export a migration and its metadata to a single JSON file.

**Syntax:**
```bash
migration_cli export <migration_id> [options]
```

**Arguments:**
- `migration_id`: ID of the migration to export

**Options:**
- `-o, --output`: Output file name
- `-d, --dir`: Migrations directory (default: `migrations`)

**Examples:**
```bash
# Export migration
./migration_cli export 20260219_084056_clinic_to_postgres

# Custom output file
./migration_cli export 20260219_084056_clinic_to_postgres -o clinic_migration.json
```

### 7. `clean` - Clean Migration Files

Remove all migration files from the migrations directory.

**Syntax:**
```bash
migration_cli clean [options]
```

**Options:**
- `-d, --dir`: Migrations directory to clean (default: `migrations`)
- `-f, --force`: Skip confirmation prompt

**Examples:**
```bash
# Clean with confirmation
./migration_cli clean

# Force clean without confirmation
./migration_cli clean -f

# Clean custom directory
./migration_cli clean -d old_migrations
```

## Global Options

These options work with all commands:

- `-v, --verbose`: Enable verbose output for debugging
- `--no-color`: Disable colored output

**Examples:**
```bash
# Verbose mode
./migration_cli -v create my_migration schema.sql postgresql

# No colors (useful for logs)
./migration_cli --no-color list
```

## Migration File Structure

The CLI creates the following file structure:

```
migrations/
├── up/
│   ├── 20260219_084056_clinic_to_postgres.sql
│   ├── 20260219_084057_iot_to_mongo.sql
│   └── ...
├── down/
│   ├── 20260219_084056_clinic_to_postgres_rollback.sql
│   ├── 20260219_084057_iot_to_mongo_rollback.sql
│   └── ...
└── *.json (metadata files)
```

- **up/**: Contains forward migration scripts
- **down/**: Contains rollback scripts
- **\*.json**: Metadata files with migration information

## Use Cases

### 1. Single Schema Migration
```bash
# Create migration
./migration_cli create clinic_to_pg example_01_clinic/schema/01_tables.sql postgresql

# Validate it
./migration_cli validate 20260219_*_clinic_to_pg

# Export for deployment
./migration_cli export 20260219_*_clinic_to_pg -o clinic_migration.json
```

### 2. Batch Migration Project
```bash
# Create all migrations
./migration_cli batch postgresql

# List to verify
./migration_cli list

# Validate each one
for id in $(./migration_cli list | grep pending | awk '{print $1}'); do
    ./migration_cli validate $id
done
```

### 3. MongoDB Migration
```bash
# Create MongoDB migration
./migration_cli create app_to_mongo app_schema.sql mongodb -p

# Show with SQL preview
./migration_cli show -s 20260219_*_app_to_mongo
```

## Integration with CI/CD

### GitHub Actions Example
```yaml
- name: Create Migration
  run: |
    python migration_system/migration_cli.py create \
      ${{ github.event.inputs.name }} \
      ${{ github.event.inputs.schema }} \
      postgresql

- name: Validate Migration
  run: |
    python migration_system/migration_cli.py validate \
      $(ls migrations/*.json | head -1 | basename .json)
```

### Jenkins Pipeline Example
```groovy
stage('Create Migrations') {
    steps {
        sh './migration_cli batch postgresql'
        sh './migration_cli list'
    }
}
```

## Error Handling

The CLI provides clear error messages:

```bash
# Missing file
$ ./migration_cli create test missing.sql postgresql
[ERROR] Error: Source file 'missing.sql' not found

# Invalid migration ID
$ ./migration_cli show invalid_id
[ERROR] Migration 'invalid_id' not found

# No migrations found
$ ./migration_cli list
[WARNING] No migrations found
```

## Best Practices

1. **Naming Conventions**
   - Use descriptive names: `clinic_to_postgresql` not `migration1`
   - Include source and target: `ecommerce_mysql_to_mongo`
   - Add version if needed: `users_v2_to_postgresql`

2. **Organization**
   - Keep migrations in version control
   - Use separate directories for different projects
   - Archive old migrations periodically

3. **Validation**
   - Always validate migrations before deployment
   - Review generated SQL manually for complex schemas
   - Test rollback scripts in development

4. **Batch Operations**
   - Use batch command for multiple schemas
   - Process similar schemas together
   - Monitor output for failures

## Troubleshooting

### Common Issues

1. **Import Error: colorama not found**
   ```bash
   pip install colorama
   ```

2. **Permission Denied (Unix/Linux/Mac)**
   ```bash
   chmod +x migration_cli
   ```

3. **Python not found**
   - Ensure Python 3.6+ is installed
   - Check PATH environment variable

4. **Migration not found**
   - Verify migration ID with `list` command
   - Check migrations directory path

### Debug Mode

Enable verbose output for debugging:
```bash
./migration_cli -v create test_migration schema.sql postgresql
```

## Performance Tips

1. **Large Schemas**
   - Process in smaller batches
   - Use custom output directories
   - Monitor disk space

2. **Batch Processing**
   - Limit pattern scope for faster processing
   - Run in parallel with different output directories
   - Use clean command to manage disk usage

## Support

For issues or questions:
1. Check this documentation
2. Review error messages carefully
3. Enable verbose mode for debugging
4. Check GitHub issues
5. Submit bug reports with:
   - Command used
   - Error message
   - Schema file (if possible)
   - Python version

---

*Migration CLI v1.0 - Part of MySQL Business-to-Schema Project*