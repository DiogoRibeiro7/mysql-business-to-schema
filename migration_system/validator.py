"""
Migration validation and safety checks.
"""

import re
import sqlparse
from typing import List, Tuple, Dict, Optional, Any
import logging

logger = logging.getLogger(__name__)

class MigrationValidator:
    """Validates migrations for safety and correctness."""

    def __init__(self):
        self.warnings = []
        self.errors = []

        # Dangerous operations
        self.dangerous_operations = [
            r'DROP\s+DATABASE',
            r'TRUNCATE\s+TABLE',
            r'DELETE\s+FROM\s+\w+\s*(?:;|$)',  # DELETE without WHERE
            r'UPDATE\s+\w+\s+SET.*(?:;|$)(?!.*WHERE)',  # UPDATE without WHERE
            r'GRANT\s+ALL',
            r'REVOKE\s+ALL',
            r'FLUSH\s+PRIVILEGES',
        ]

        # Operations requiring locks
        self.locking_operations = [
            r'ALTER\s+TABLE',
            r'RENAME\s+TABLE',
            r'CREATE\s+INDEX',
            r'DROP\s+INDEX',
        ]

        # Data loss operations
        self.data_loss_operations = [
            r'DROP\s+TABLE',
            r'DROP\s+COLUMN',
            r'TRUNCATE',
            r'DELETE\s+FROM',
        ]

    def validate_migration(self,
                          up_script: str,
                          down_script: Optional[str] = None,
                          production_mode: bool = False) -> Tuple[bool, List[str], List[str]]:
        """
        Validate migration scripts.

        Args:
            up_script: Up migration script
            down_script: Optional down migration script
            production_mode: If True, apply stricter validation

        Returns:
            Tuple of (is_valid, errors, warnings)
        """
        self.warnings = []
        self.errors = []

        # Validate up script
        self._validate_sql(up_script, "up", production_mode, down_script)

        # Validate down script if provided
        if down_script:
            self._validate_sql(down_script, "down", production_mode, down_script=None)
            self._validate_reversibility(up_script, down_script)

        # Check for migration conflicts
        self._check_conflicts(up_script)

        is_valid = len(self.errors) == 0
        return is_valid, self.errors, self.warnings

    def _validate_sql(
        self,
        sql: str,
        direction: str,
        production_mode: bool,
        down_script: Optional[str] = None
    ):
        """Validate SQL script."""
        # Parse SQL
        try:
            statements = sqlparse.parse(sql)
        except Exception as e:
            self.errors.append(f"Failed to parse {direction} SQL: {e}")
            return

        # Check for syntax errors
        for statement in statements:
            if not self._is_valid_syntax(statement):
                self.errors.append(f"Invalid SQL syntax in {direction} migration")

        # Check for dangerous operations
        for pattern in self.dangerous_operations:
            if re.search(pattern, sql, re.IGNORECASE | re.MULTILINE):
                if production_mode:
                    self.errors.append(f"Dangerous operation detected in {direction}: {pattern}")
                else:
                    self.warnings.append(f"Dangerous operation in {direction}: {pattern}")

        # Check for locking operations
        for pattern in self.locking_operations:
            if re.search(pattern, sql, re.IGNORECASE):
                self.warnings.append(f"Locking operation in {direction}: {pattern}")

        # Check for data loss
        for pattern in self.data_loss_operations:
            if re.search(pattern, sql, re.IGNORECASE):
                if not down_script:
                    self.warnings.append(f"Potential data loss in {direction} without rollback: {pattern}")
                else:
                    self.warnings.append(f"Potential data loss operation: {pattern}")

        # Production-specific checks
        if production_mode:
            self._production_checks(sql, direction)

    def _is_valid_syntax(self, statement) -> bool:
        """Check if SQL statement has valid syntax."""
        # Basic syntax validation
        str_statement = str(statement).strip()

        if not str_statement:
            return True  # Empty statements are ok

        # Check for common syntax issues
        if str_statement.count('(') != str_statement.count(')'):
            return False

        if str_statement.count("'") % 2 != 0:
            return False

        if str_statement.count('"') % 2 != 0:
            return False

        return True

    def _validate_reversibility(self, up_script: str, down_script: str):
        """Validate that down script properly reverses up script."""
        # Extract operations from scripts
        up_ops = self._extract_operations(up_script)
        down_ops = self._extract_operations(down_script)

        # Check CREATE TABLE has corresponding DROP TABLE
        for op in up_ops:
            if op['type'] == 'CREATE_TABLE':
                table_name = op['object']
                if not any(d['type'] == 'DROP_TABLE' and d['object'] == table_name for d in down_ops):
                    self.warnings.append(f"CREATE TABLE {table_name} has no corresponding DROP in rollback")

        # Check ADD COLUMN has corresponding DROP COLUMN
        for op in up_ops:
            if op['type'] == 'ADD_COLUMN':
                if not any(d['type'] == 'DROP_COLUMN' for d in down_ops):
                    self.warnings.append(f"ADD COLUMN operations may not be fully reversible")

    def _extract_operations(self, sql: str) -> List[Dict[str, str]]:
        """Extract operations from SQL script."""
        operations = []

        # CREATE TABLE
        for match in re.finditer(r'CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?(\w+)', sql, re.IGNORECASE):
            operations.append({'type': 'CREATE_TABLE', 'object': match.group(1)})

        # DROP TABLE
        for match in re.finditer(r'DROP\s+TABLE\s+(?:IF\s+EXISTS\s+)?(\w+)', sql, re.IGNORECASE):
            operations.append({'type': 'DROP_TABLE', 'object': match.group(1)})

        # ALTER TABLE ADD COLUMN
        for match in re.finditer(r'ALTER\s+TABLE\s+(\w+)\s+ADD\s+(?:COLUMN\s+)?(\w+)', sql, re.IGNORECASE):
            operations.append({'type': 'ADD_COLUMN', 'object': f"{match.group(1)}.{match.group(2)}"})

        # ALTER TABLE DROP COLUMN
        for match in re.finditer(r'ALTER\s+TABLE\s+(\w+)\s+DROP\s+(?:COLUMN\s+)?(\w+)', sql, re.IGNORECASE):
            operations.append({'type': 'DROP_COLUMN', 'object': f"{match.group(1)}.{match.group(2)}"})

        # CREATE INDEX
        for match in re.finditer(r'CREATE\s+(?:UNIQUE\s+)?INDEX\s+(\w+)', sql, re.IGNORECASE):
            operations.append({'type': 'CREATE_INDEX', 'object': match.group(1)})

        # DROP INDEX
        for match in re.finditer(r'DROP\s+INDEX\s+(\w+)', sql, re.IGNORECASE):
            operations.append({'type': 'DROP_INDEX', 'object': match.group(1)})

        return operations

    def _check_conflicts(self, sql: str):
        """Check for potential conflicts."""
        operations = self._extract_operations(sql)

        # Check for duplicate operations
        seen = set()
        for op in operations:
            key = f"{op['type']}:{op['object']}"
            if key in seen:
                self.warnings.append(f"Duplicate operation detected: {key}")
            seen.add(key)

        # Check for conflicting operations
        tables_created = {op['object'] for op in operations if op['type'] == 'CREATE_TABLE'}
        tables_dropped = {op['object'] for op in operations if op['type'] == 'DROP_TABLE'}

        conflicts = tables_created & tables_dropped
        if conflicts:
            self.errors.append(f"Conflicting operations on tables: {conflicts}")

    def _production_checks(self, sql: str, direction: str):
        """Additional checks for production migrations."""
        # Check for missing WHERE clauses in UPDATE/DELETE
        delete_without_where = re.search(
            r'DELETE\s+FROM\s+\w+\s*(?:;|$)',
            sql,
            re.IGNORECASE | re.MULTILINE
        )
        if delete_without_where:
            self.errors.append(f"DELETE without WHERE clause in {direction} - extremely dangerous in production")

        update_without_where = re.search(
            r'UPDATE\s+\w+\s+SET[^;]+(?:;|$)(?!.*WHERE)',
            sql,
            re.IGNORECASE | re.MULTILINE
        )
        if update_without_where:
            self.errors.append(f"UPDATE without WHERE clause in {direction} - extremely dangerous in production")

        # Check for large table operations
        large_table_ops = [
            r'ALTER\s+TABLE\s+(?:users|orders|transactions|logs)',
            r'CREATE\s+INDEX\s+\w+\s+ON\s+(?:users|orders|transactions|logs)',
        ]

        for pattern in large_table_ops:
            if re.search(pattern, sql, re.IGNORECASE):
                self.warnings.append(f"Operation on potentially large table in {direction} - consider online migration")

    def validate_naming_convention(self, version: str, filename: str) -> bool:
        """Validate migration naming convention."""
        # Version format: V001 or V001_20240120_123456
        version_pattern = r'^V\d{3}(?:_\d{8}_\d{6})?$'
        if not re.match(version_pattern, version):
            self.errors.append(f"Invalid version format: {version}. Expected V### or V###_YYYYMMDD_HHMMSS")
            return False

        # Filename format: V001__description.sql
        filename_pattern = r'^V\d{3}(?:_\d{8}_\d{6})?__[\w_]+\.sql$'
        if not re.match(filename_pattern, filename):
            self.errors.append(f"Invalid filename format: {filename}")
            return False

        return True

    def estimate_execution_time(self, sql: str, table_sizes: Optional[Dict[str, int]] = None) -> Dict[str, Any]:
        """
        Estimate migration execution time.

        Args:
            sql: SQL script
            table_sizes: Optional dict of table_name -> row_count

        Returns:
            Estimation details
        """
        estimation = {
            "total_seconds": 0,
            "operations": [],
            "warnings": []
        }

        operations = self._extract_operations(sql)

        for op in operations:
            time_estimate = 0

            if op['type'] == 'CREATE_TABLE':
                time_estimate = 0.1  # Usually fast

            elif op['type'] == 'DROP_TABLE':
                time_estimate = 0.5  # Can be slower with foreign keys

            elif op['type'] in ['ADD_COLUMN', 'DROP_COLUMN']:
                table_name = op['object'].split('.')[0]
                if table_sizes and table_name in table_sizes:
                    rows = table_sizes[table_name]
                    # Rough estimate: 1ms per 1000 rows
                    time_estimate = rows / 1000
                else:
                    time_estimate = 1  # Default estimate

            elif op['type'] == 'CREATE_INDEX':
                # Index creation can be very slow on large tables
                if table_sizes:
                    # Try to find table from CREATE INDEX statement
                    match = re.search(
                        rf"CREATE\s+(?:UNIQUE\s+)?INDEX\s+{op['object']}\s+ON\s+(\w+)",
                        sql,
                        re.IGNORECASE
                    )
                    if match:
                        table_name = match.group(1)
                        if table_name in table_sizes:
                            rows = table_sizes[table_name]
                            # Rough estimate: 10ms per 1000 rows
                            time_estimate = rows / 100
                else:
                    time_estimate = 10  # Default estimate

            estimation["operations"].append({
                "operation": op,
                "estimated_seconds": time_estimate
            })
            estimation["total_seconds"] += time_estimate

        # Add warnings for slow operations
        if estimation["total_seconds"] > 60:
            estimation["warnings"].append(
                f"Migration may take {estimation['total_seconds']:.0f} seconds"
            )

        if estimation["total_seconds"] > 300:
            estimation["warnings"].append(
                "Consider running migration during maintenance window"
            )

        return estimation

    def check_data_integrity(self, sql: str) -> List[str]:
        """Check for potential data integrity issues."""
        integrity_issues = []

        # Check for nullable to non-nullable conversions
        nullable_change = re.search(
            r'ALTER\s+TABLE\s+\w+\s+MODIFY\s+(?:COLUMN\s+)?\w+[^;]+NOT\s+NULL',
            sql,
            re.IGNORECASE
        )
        if nullable_change:
            integrity_issues.append(
                "Changing column to NOT NULL - ensure no NULL values exist"
            )

        # Check for type conversions that might lose data
        type_changes = [
            (r'VARCHAR\(\d+\).*?INT', "VARCHAR to INT conversion may lose data"),
            (r'TEXT.*?VARCHAR\(\d+\)', "TEXT to VARCHAR conversion may truncate data"),
            (r'DECIMAL\(\d+,\d+\).*?INT', "DECIMAL to INT conversion will lose precision"),
            (r'BIGINT.*?INT(?!.*BIG)', "BIGINT to INT conversion may cause overflow"),
        ]

        for pattern, message in type_changes:
            if re.search(pattern, sql, re.IGNORECASE):
                integrity_issues.append(message)

        # Check for foreign key additions on existing data
        if re.search(r'ADD\s+(?:CONSTRAINT\s+\w+\s+)?FOREIGN\s+KEY', sql, re.IGNORECASE):
            integrity_issues.append(
                "Adding foreign key - ensure referential integrity in existing data"
            )

        # Check for unique constraints on existing columns
        if re.search(r'ADD\s+(?:CONSTRAINT\s+\w+\s+)?UNIQUE', sql, re.IGNORECASE):
            integrity_issues.append(
                "Adding unique constraint - ensure no duplicate values exist"
            )

        return integrity_issues

class DryRunValidator:
    """Validates migrations using dry-run execution."""

    def __init__(self, connection):
        self.connection = connection

    def dry_run(self, sql: str) -> Tuple[bool, List[str]]:
        """
        Perform dry-run validation.

        Args:
            sql: SQL script to validate

        Returns:
            Tuple of (success, errors)
        """
        errors = []

        try:
            # Start transaction
            self.connection.start_transaction()

            cursor = self.connection.cursor()

            # Split and execute statements
            statements = self._split_sql_statements(sql)

            for i, statement in enumerate(statements):
                if statement.strip():
                    try:
                        cursor.execute(statement)
                    except Exception as e:
                        errors.append(f"Statement {i+1} failed: {e}")
                        break

            # Always rollback (dry-run)
            self.connection.rollback()

            cursor.close()

            return len(errors) == 0, errors

        except Exception as e:
            try:
                self.connection.rollback()
            except:
                pass
            return False, [f"Dry-run failed: {e}"]

    def _split_sql_statements(self, sql: str) -> List[str]:
        """Split SQL into individual statements."""
        statements = []
        current = []

        for line in sql.split('\n'):
            # Skip comments
            if line.strip().startswith('--'):
                continue

            current.append(line)

            # Check for statement end
            if line.rstrip().endswith(';'):
                statements.append('\n'.join(current))
                current = []

        # Add remaining if any
        if current:
            statements.append('\n'.join(current))

        return statements

    def check_table_locks(self, sql: str) -> List[str]:
        """Check which tables would be locked during migration."""
        locked_tables = []

        # Find ALTER TABLE operations
        for match in re.finditer(r'ALTER\s+TABLE\s+(\w+)', sql, re.IGNORECASE):
            locked_tables.append(match.group(1))

        # Find CREATE INDEX operations
        for match in re.finditer(r'CREATE\s+(?:UNIQUE\s+)?INDEX\s+\w+\s+ON\s+(\w+)', sql, re.IGNORECASE):
            locked_tables.append(match.group(1))

        return list(set(locked_tables))

    def estimate_downtime(self,
                         sql: str,
                         avg_query_rate: float = 100) -> float:
        """
        Estimate downtime based on locking operations.

        Args:
            sql: SQL script
            avg_query_rate: Average queries per second on affected tables

        Returns:
            Estimated downtime in seconds
        """
        locked_tables = self.check_table_locks(sql)

        if not locked_tables:
            return 0

        # Get table sizes
        cursor = self.connection.cursor()
        total_rows = 0

        for table in locked_tables:
            try:
                cursor.execute(f"SELECT COUNT(*) FROM {table}")
                count = cursor.fetchone()[0]
                total_rows += count
            except:
                pass

        cursor.close()

        # Rough estimate: 1ms per 100 rows for ALTER TABLE
        base_time = total_rows / 100000

        # Add time for waiting queries to complete
        wait_time = 1 / avg_query_rate if avg_query_rate > 0 else 0

        return base_time + wait_time
