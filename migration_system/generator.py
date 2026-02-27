"""
Migration generator - automatically creates migrations from schema changes.
"""

import difflib
import re
from datetime import datetime
from typing import Dict, List, Tuple, Optional, Any
from pathlib import Path
import mysql.connector
import logging

logger = logging.getLogger(__name__)


class SchemaInspector:
    """Inspects database schema structure."""

    def __init__(self, connection):
        self.connection = connection

    def get_schema(self, database: Optional[str] = None) -> Dict[str, Any]:
        """Get complete schema structure."""
        cursor = self.connection.cursor(dictionary=True)

        if database:
            cursor.execute(f"USE {database}")

        schema = {
            "database": database or self.connection.database,
            "tables": {},
            "views": {},
            "procedures": {},
            "functions": {},
            "triggers": {},
        }

        # Get tables
        cursor.execute(
            """
            SELECT TABLE_NAME, ENGINE, TABLE_COLLATION, TABLE_COMMENT
            FROM INFORMATION_SCHEMA.TABLES
            WHERE TABLE_SCHEMA = DATABASE()
            AND TABLE_TYPE = 'BASE TABLE'
        """
        )

        for table in cursor.fetchall():
            table_name = table["TABLE_NAME"]
            schema["tables"][table_name] = {
                "engine": table["ENGINE"],
                "collation": table["TABLE_COLLATION"],
                "comment": table["TABLE_COMMENT"],
                "columns": self.get_columns(table_name),
                "indexes": self.get_indexes(table_name),
                "foreign_keys": self.get_foreign_keys(table_name),
                "triggers": self.get_table_triggers(table_name),
            }

        # Get views
        cursor.execute(
            """
            SELECT TABLE_NAME, VIEW_DEFINITION
            FROM INFORMATION_SCHEMA.VIEWS
            WHERE TABLE_SCHEMA = DATABASE()
        """
        )

        for view in cursor.fetchall():
            schema["views"][view["TABLE_NAME"]] = view["VIEW_DEFINITION"]

        # Get stored procedures
        cursor.execute(
            """
            SELECT ROUTINE_NAME, ROUTINE_DEFINITION, ROUTINE_TYPE
            FROM INFORMATION_SCHEMA.ROUTINES
            WHERE ROUTINE_SCHEMA = DATABASE()
            AND ROUTINE_TYPE = 'PROCEDURE'
        """
        )

        for proc in cursor.fetchall():
            schema["procedures"][proc["ROUTINE_NAME"]] = proc["ROUTINE_DEFINITION"]

        # Get functions
        cursor.execute(
            """
            SELECT ROUTINE_NAME, ROUTINE_DEFINITION, ROUTINE_TYPE
            FROM INFORMATION_SCHEMA.ROUTINES
            WHERE ROUTINE_SCHEMA = DATABASE()
            AND ROUTINE_TYPE = 'FUNCTION'
        """
        )

        for func in cursor.fetchall():
            schema["functions"][func["ROUTINE_NAME"]] = func["ROUTINE_DEFINITION"]

        cursor.close()
        return schema

    def get_columns(self, table_name: str) -> List[Dict[str, Any]]:
        """Get columns for a table."""
        cursor = self.connection.cursor(dictionary=True)
        cursor.execute(
            """
            SELECT
                COLUMN_NAME,
                COLUMN_TYPE,
                IS_NULLABLE,
                COLUMN_DEFAULT,
                EXTRA,
                COLUMN_COMMENT,
                ORDINAL_POSITION
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
            AND TABLE_NAME = %s
            ORDER BY ORDINAL_POSITION
        """,
            (table_name,),
        )

        columns = cursor.fetchall()
        cursor.close()
        return columns

    def get_indexes(self, table_name: str) -> List[Dict[str, Any]]:
        """Get indexes for a table."""
        cursor = self.connection.cursor(dictionary=True)
        cursor.execute(
            """
            SELECT
                INDEX_NAME,
                NON_UNIQUE,
                GROUP_CONCAT(
                    COLUMN_NAME ORDER BY SEQ_IN_INDEX
                ) as COLUMNS
            FROM INFORMATION_SCHEMA.STATISTICS
            WHERE TABLE_SCHEMA = DATABASE()
            AND TABLE_NAME = %s
            GROUP BY INDEX_NAME, NON_UNIQUE
        """,
            (table_name,),
        )

        indexes = cursor.fetchall()
        cursor.close()
        return indexes

    def get_foreign_keys(self, table_name: str) -> List[Dict[str, Any]]:
        """Get foreign keys for a table."""
        cursor = self.connection.cursor(dictionary=True)
        cursor.execute(
            """
            SELECT
                CONSTRAINT_NAME,
                COLUMN_NAME,
                REFERENCED_TABLE_NAME,
                REFERENCED_COLUMN_NAME,
                UPDATE_RULE,
                DELETE_RULE
            FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE k
            JOIN INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS r
                ON k.CONSTRAINT_NAME = r.CONSTRAINT_NAME
                AND k.TABLE_SCHEMA = r.CONSTRAINT_SCHEMA
            WHERE k.TABLE_SCHEMA = DATABASE()
            AND k.TABLE_NAME = %s
            AND k.REFERENCED_TABLE_NAME IS NOT NULL
        """,
            (table_name,),
        )

        foreign_keys = cursor.fetchall()
        cursor.close()
        return foreign_keys

    def get_table_triggers(self, table_name: str) -> List[Dict[str, Any]]:
        """Get triggers for a table."""
        cursor = self.connection.cursor(dictionary=True)
        cursor.execute(
            """
            SELECT
                TRIGGER_NAME,
                EVENT_MANIPULATION,
                ACTION_TIMING,
                ACTION_STATEMENT
            FROM INFORMATION_SCHEMA.TRIGGERS
            WHERE EVENT_OBJECT_SCHEMA = DATABASE()
            AND EVENT_OBJECT_TABLE = %s
        """,
            (table_name,),
        )

        triggers = cursor.fetchall()
        cursor.close()
        return triggers


class SchemaDiffer:
    """Compares two schemas and generates differences."""

    def __init__(self):
        self.differences = []

    def compare_schemas(
        self, source_schema: Dict[str, Any], target_schema: Dict[str, Any]
    ) -> List[Dict[str, Any]]:
        """
        Compare two schemas and return differences.

        Args:
            source_schema: Current database schema
            target_schema: Desired schema

        Returns:
            List of differences
        """
        self.differences = []

        # Compare tables
        self._compare_tables(
            source_schema.get("tables", {}), target_schema.get("tables", {})
        )

        # Compare views
        self._compare_views(
            source_schema.get("views", {}), target_schema.get("views", {})
        )

        # Compare procedures
        self._compare_procedures(
            source_schema.get("procedures", {}), target_schema.get("procedures", {})
        )

        # Compare functions
        self._compare_functions(
            source_schema.get("functions", {}), target_schema.get("functions", {})
        )

        return self.differences

    def _compare_tables(self, source_tables: Dict, target_tables: Dict):
        """Compare tables between schemas."""
        # Find new tables
        for table_name, table_def in target_tables.items():
            if table_name not in source_tables:
                self.differences.append(
                    {
                        "type": "CREATE_TABLE",
                        "table": table_name,
                        "definition": table_def,
                    }
                )

        # Find dropped tables
        for table_name in source_tables:
            if table_name not in target_tables:
                self.differences.append({"type": "DROP_TABLE", "table": table_name})

        # Compare existing tables
        for table_name in set(source_tables) & set(target_tables):
            self._compare_table_structure(
                table_name, source_tables[table_name], target_tables[table_name]
            )

    def _compare_table_structure(
        self, table_name: str, source_table: Dict, target_table: Dict
    ):
        """Compare structure of a single table."""
        # Compare columns
        self._compare_columns(
            table_name, source_table.get("columns", []), target_table.get("columns", [])
        )

        # Compare indexes
        self._compare_indexes(
            table_name, source_table.get("indexes", []), target_table.get("indexes", [])
        )

        # Compare foreign keys
        self._compare_foreign_keys(
            table_name,
            source_table.get("foreign_keys", []),
            target_table.get("foreign_keys", []),
        )

    def _compare_columns(
        self, table_name: str, source_columns: List[Dict], target_columns: List[Dict]
    ):
        """Compare columns of a table."""
        source_col_map = {col["COLUMN_NAME"]: col for col in source_columns}
        target_col_map = {col["COLUMN_NAME"]: col for col in target_columns}

        # Find new columns
        for col_name, col_def in target_col_map.items():
            if col_name not in source_col_map:
                self.differences.append(
                    {
                        "type": "ADD_COLUMN",
                        "table": table_name,
                        "column": col_name,
                        "definition": col_def,
                    }
                )

        # Find dropped columns
        for col_name in source_col_map:
            if col_name not in target_col_map:
                self.differences.append(
                    {"type": "DROP_COLUMN", "table": table_name, "column": col_name}
                )

        # Compare existing columns
        for col_name in set(source_col_map) & set(target_col_map):
            source_col = source_col_map[col_name]
            target_col = target_col_map[col_name]

            if self._column_differs(source_col, target_col):
                self.differences.append(
                    {
                        "type": "MODIFY_COLUMN",
                        "table": table_name,
                        "column": col_name,
                        "old_definition": source_col,
                        "new_definition": target_col,
                    }
                )

    def _column_differs(self, source_col: Dict, target_col: Dict) -> bool:
        """Check if two column definitions differ."""
        compare_fields = ["COLUMN_TYPE", "IS_NULLABLE", "COLUMN_DEFAULT", "EXTRA"]
        for field in compare_fields:
            if source_col.get(field) != target_col.get(field):
                return True
        return False

    def _compare_indexes(
        self, table_name: str, source_indexes: List[Dict], target_indexes: List[Dict]
    ):
        """Compare indexes of a table."""
        source_idx_map = {idx["INDEX_NAME"]: idx for idx in source_indexes}
        target_idx_map = {idx["INDEX_NAME"]: idx for idx in target_indexes}

        # Find new indexes
        for idx_name, idx_def in target_idx_map.items():
            if idx_name not in source_idx_map:
                self.differences.append(
                    {
                        "type": "CREATE_INDEX",
                        "table": table_name,
                        "index": idx_name,
                        "definition": idx_def,
                    }
                )

        # Find dropped indexes
        for idx_name in source_idx_map:
            if idx_name not in target_idx_map and idx_name != "PRIMARY":
                self.differences.append(
                    {"type": "DROP_INDEX", "table": table_name, "index": idx_name}
                )

    def _compare_foreign_keys(
        self, table_name: str, source_fks: List[Dict], target_fks: List[Dict]
    ):
        """Compare foreign keys of a table."""
        source_fk_map = {fk["CONSTRAINT_NAME"]: fk for fk in source_fks}
        target_fk_map = {fk["CONSTRAINT_NAME"]: fk for fk in target_fks}

        # Find new foreign keys
        for fk_name, fk_def in target_fk_map.items():
            if fk_name not in source_fk_map:
                self.differences.append(
                    {
                        "type": "ADD_FOREIGN_KEY",
                        "table": table_name,
                        "constraint": fk_name,
                        "definition": fk_def,
                    }
                )

        # Find dropped foreign keys
        for fk_name in source_fk_map:
            if fk_name not in target_fk_map:
                self.differences.append(
                    {
                        "type": "DROP_FOREIGN_KEY",
                        "table": table_name,
                        "constraint": fk_name,
                    }
                )

    def _compare_views(self, source_views: Dict, target_views: Dict):
        """Compare views between schemas."""
        for view_name, view_def in target_views.items():
            if view_name not in source_views:
                self.differences.append(
                    {"type": "CREATE_VIEW", "view": view_name, "definition": view_def}
                )
            elif source_views[view_name] != view_def:
                self.differences.append(
                    {
                        "type": "ALTER_VIEW",
                        "view": view_name,
                        "old_definition": source_views[view_name],
                        "new_definition": view_def,
                    }
                )

        for view_name in source_views:
            if view_name not in target_views:
                self.differences.append({"type": "DROP_VIEW", "view": view_name})

    def _compare_procedures(self, source_procs: Dict, target_procs: Dict):
        """Compare stored procedures between schemas."""
        for proc_name, proc_def in target_procs.items():
            if proc_name not in source_procs:
                self.differences.append(
                    {
                        "type": "CREATE_PROCEDURE",
                        "procedure": proc_name,
                        "definition": proc_def,
                    }
                )
            elif source_procs[proc_name] != proc_def:
                self.differences.append(
                    {
                        "type": "ALTER_PROCEDURE",
                        "procedure": proc_name,
                        "old_definition": source_procs[proc_name],
                        "new_definition": proc_def,
                    }
                )

        for proc_name in source_procs:
            if proc_name not in target_procs:
                self.differences.append(
                    {"type": "DROP_PROCEDURE", "procedure": proc_name}
                )

    def _compare_functions(self, source_funcs: Dict, target_funcs: Dict):
        """Compare functions between schemas."""
        for func_name, func_def in target_funcs.items():
            if func_name not in source_funcs:
                self.differences.append(
                    {
                        "type": "CREATE_FUNCTION",
                        "function": func_name,
                        "definition": func_def,
                    }
                )
            elif source_funcs[func_name] != func_def:
                self.differences.append(
                    {
                        "type": "ALTER_FUNCTION",
                        "function": func_name,
                        "old_definition": source_funcs[func_name],
                        "new_definition": func_def,
                    }
                )

        for func_name in source_funcs:
            if func_name not in target_funcs:
                self.differences.append(
                    {"type": "DROP_FUNCTION", "function": func_name}
                )


class MigrationGenerator:
    """Generates migration files from schema differences."""

    def __init__(self, migrations_path: str = "migrations"):
        self.migrations_path = Path(migrations_path)
        self.migrations_path.mkdir(exist_ok=True)

    def generate_migration(
        self,
        differences: List[Dict[str, Any]],
        description: str,
        version: Optional[str] = None,
    ) -> Tuple[str, str]:
        """
        Generate migration from differences.

        Args:
            differences: List of schema differences
            description: Migration description
            version: Version (auto-generated if None)

        Returns:
            Tuple of (version, filename)
        """
        if not version:
            version = self._generate_version()

        up_statements = []
        down_statements = []

        for diff in differences:
            up_sql, down_sql = self._generate_sql_for_difference(diff)
            if up_sql:
                up_statements.append(up_sql)
            if down_sql:
                down_statements.append(down_sql)

        # Create migration content
        content = self._format_migration_content(
            up_statements, down_statements, description
        )

        # Write migration file
        filename = self._generate_filename(version, description)
        file_path = self.migrations_path / filename

        with open(file_path, "w") as f:
            f.write(content)

        logger.info(f"Generated migration: {filename}")
        return version, filename

    def _generate_version(self) -> str:
        """Generate version number for migration."""
        # Find existing migrations
        existing = list(self.migrations_path.glob("V*.sql"))

        if existing:
            # Extract numbers from existing versions
            numbers = []
            for file in existing:
                match = re.match(r"V(\d+)", file.name)
                if match:
                    numbers.append(int(match.group(1)))

            if numbers:
                next_num = max(numbers) + 1
            else:
                next_num = 1
        else:
            next_num = 1

        # Add timestamp for uniqueness
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        return f"V{next_num:03d}_{timestamp}"

    def _generate_filename(self, version: str, description: str) -> str:
        """Generate migration filename."""
        # Clean description for filename
        clean_desc = re.sub(r"[^\w\s-]", "", description)
        clean_desc = re.sub(r"[-\s]+", "_", clean_desc)
        clean_desc = clean_desc[:50]  # Limit length

        return f"{version}__{clean_desc}.sql"

    def _generate_sql_for_difference(self, diff: Dict[str, Any]) -> Tuple[str, str]:
        """Generate SQL statements for a difference."""
        diff_type = diff["type"]
        up_sql = ""
        down_sql = ""

        if diff_type == "CREATE_TABLE":
            up_sql = self._generate_create_table(diff)
            down_sql = f"DROP TABLE IF EXISTS {diff['table']};"

        elif diff_type == "DROP_TABLE":
            up_sql = f"DROP TABLE IF EXISTS {diff['table']};"
            # For rollback, we'd need the full table definition
            down_sql = "-- TODO: Add CREATE TABLE statement for rollback"

        elif diff_type == "ADD_COLUMN":
            up_sql = self._generate_add_column(diff)
            down_sql = f"ALTER TABLE {diff['table']} DROP COLUMN {diff['column']};"

        elif diff_type == "DROP_COLUMN":
            up_sql = f"ALTER TABLE {diff['table']} DROP COLUMN {diff['column']};"
            down_sql = "-- TODO: Add ALTER TABLE ADD COLUMN statement for rollback"

        elif diff_type == "MODIFY_COLUMN":
            up_sql = self._generate_modify_column(diff)
            down_sql = self._generate_modify_column_rollback(diff)

        elif diff_type == "CREATE_INDEX":
            up_sql = self._generate_create_index(diff)
            down_sql = f"DROP INDEX {diff['index']} ON {diff['table']};"

        elif diff_type == "DROP_INDEX":
            up_sql = f"DROP INDEX {diff['index']} ON {diff['table']};"
            down_sql = "-- TODO: Add CREATE INDEX statement for rollback"

        elif diff_type == "ADD_FOREIGN_KEY":
            up_sql = self._generate_add_foreign_key(diff)
            down_sql = (
                f"ALTER TABLE {diff['table']} DROP FOREIGN KEY {diff['constraint']};"
            )

        elif diff_type == "DROP_FOREIGN_KEY":
            up_sql = (
                f"ALTER TABLE {diff['table']} DROP FOREIGN KEY {diff['constraint']};"
            )
            down_sql = "-- TODO: Add foreign key for rollback"

        elif diff_type == "CREATE_VIEW":
            up_sql = f"CREATE VIEW {diff['view']} AS {diff['definition']};"
            down_sql = f"DROP VIEW IF EXISTS {diff['view']};"

        elif diff_type == "ALTER_VIEW":
            up_sql = (
                f"CREATE OR REPLACE VIEW {diff['view']} AS {diff['new_definition']};"
            )
            down_sql = (
                f"CREATE OR REPLACE VIEW {diff['view']} AS {diff['old_definition']};"
            )

        elif diff_type == "DROP_VIEW":
            up_sql = f"DROP VIEW IF EXISTS {diff['view']};"
            down_sql = "-- TODO: Add CREATE VIEW statement for rollback"

        return up_sql, down_sql

    def _generate_create_table(self, diff: Dict) -> str:
        """Generate CREATE TABLE statement."""
        table_def = diff["definition"]
        sql = f"CREATE TABLE {diff['table']} (\n"

        # Add columns
        columns = []
        for col in table_def.get("columns", []):
            col_sql = f"    {col['COLUMN_NAME']} {col['COLUMN_TYPE']}"
            if col["IS_NULLABLE"] == "NO":
                col_sql += " NOT NULL"
            if col["COLUMN_DEFAULT"]:
                col_sql += f" DEFAULT {col['COLUMN_DEFAULT']}"
            if col["EXTRA"]:
                col_sql += f" {col['EXTRA']}"
            if col["COLUMN_COMMENT"]:
                col_sql += f" COMMENT '{col['COLUMN_COMMENT']}'"
            columns.append(col_sql)

        sql += ",\n".join(columns)

        # Add indexes
        for idx in table_def.get("indexes", []):
            if idx["INDEX_NAME"] == "PRIMARY":
                sql += f",\n    PRIMARY KEY ({idx['COLUMNS']})"
            elif idx["NON_UNIQUE"] == 0:
                sql += f",\n    UNIQUE KEY {idx['INDEX_NAME']} ({idx['COLUMNS']})"
            else:
                sql += f",\n    KEY {idx['INDEX_NAME']} ({idx['COLUMNS']})"

        # Add foreign keys
        for fk in table_def.get("foreign_keys", []):
            sql += f",\n    CONSTRAINT {fk['CONSTRAINT_NAME']} "
            sql += f"FOREIGN KEY ({fk['COLUMN_NAME']}) "
            sql += f"REFERENCES {fk['REFERENCED_TABLE_NAME']}({fk['REFERENCED_COLUMN_NAME']})"
            if fk["DELETE_RULE"] != "RESTRICT":
                sql += f" ON DELETE {fk['DELETE_RULE']}"
            if fk["UPDATE_RULE"] != "RESTRICT":
                sql += f" ON UPDATE {fk['UPDATE_RULE']}"

        sql += f"\n) ENGINE={table_def.get('engine', 'InnoDB')}"

        if table_def.get("collation"):
            sql += f" DEFAULT CHARSET={table_def['collation'].split('_')[0]}"

        if table_def.get("comment"):
            sql += f" COMMENT='{table_def['comment']}'"

        sql += ";"
        return sql

    def _generate_add_column(self, diff: Dict) -> str:
        """Generate ADD COLUMN statement."""
        col = diff["definition"]
        sql = f"ALTER TABLE {diff['table']} ADD COLUMN {col['COLUMN_NAME']} {col['COLUMN_TYPE']}"

        if col["IS_NULLABLE"] == "NO":
            sql += " NOT NULL"
        if col["COLUMN_DEFAULT"]:
            sql += f" DEFAULT {col['COLUMN_DEFAULT']}"
        if col["EXTRA"]:
            sql += f" {col['EXTRA']}"
        if col["COLUMN_COMMENT"]:
            sql += f" COMMENT '{col['COLUMN_COMMENT']}'"

        # Add position
        if col.get("ORDINAL_POSITION") == 1:
            sql += " FIRST"
        elif col.get("after_column"):
            sql += f" AFTER {col['after_column']}"

        sql += ";"
        return sql

    def _generate_modify_column(self, diff: Dict) -> str:
        """Generate MODIFY COLUMN statement."""
        col = diff["new_definition"]
        sql = f"ALTER TABLE {diff['table']} MODIFY COLUMN {col['COLUMN_NAME']} {col['COLUMN_TYPE']}"

        if col["IS_NULLABLE"] == "NO":
            sql += " NOT NULL"
        if col["COLUMN_DEFAULT"]:
            sql += f" DEFAULT {col['COLUMN_DEFAULT']}"
        if col["EXTRA"]:
            sql += f" {col['EXTRA']}"
        if col["COLUMN_COMMENT"]:
            sql += f" COMMENT '{col['COLUMN_COMMENT']}'"

        sql += ";"
        return sql

    def _generate_modify_column_rollback(self, diff: Dict) -> str:
        """Generate MODIFY COLUMN rollback statement."""
        col = diff["old_definition"]
        sql = f"ALTER TABLE {diff['table']} MODIFY COLUMN {col['COLUMN_NAME']} {col['COLUMN_TYPE']}"

        if col["IS_NULLABLE"] == "NO":
            sql += " NOT NULL"
        if col["COLUMN_DEFAULT"]:
            sql += f" DEFAULT {col['COLUMN_DEFAULT']}"
        if col["EXTRA"]:
            sql += f" {col['EXTRA']}"
        if col["COLUMN_COMMENT"]:
            sql += f" COMMENT '{col['COLUMN_COMMENT']}'"

        sql += ";"
        return sql

    def _generate_create_index(self, diff: Dict) -> str:
        """Generate CREATE INDEX statement."""
        idx = diff["definition"]
        if idx["NON_UNIQUE"] == 0:
            sql = f"CREATE UNIQUE INDEX {idx['INDEX_NAME']} "
        else:
            sql = f"CREATE INDEX {idx['INDEX_NAME']} "

        sql += f"ON {diff['table']} ({idx['COLUMNS']});"
        return sql

    def _generate_add_foreign_key(self, diff: Dict) -> str:
        """Generate ADD FOREIGN KEY statement."""
        fk = diff["definition"]
        sql = f"ALTER TABLE {diff['table']} "
        sql += f"ADD CONSTRAINT {fk['CONSTRAINT_NAME']} "
        sql += f"FOREIGN KEY ({fk['COLUMN_NAME']}) "
        sql += (
            f"REFERENCES {fk['REFERENCED_TABLE_NAME']}({fk['REFERENCED_COLUMN_NAME']})"
        )

        if fk["DELETE_RULE"] != "RESTRICT":
            sql += f" ON DELETE {fk['DELETE_RULE']}"
        if fk["UPDATE_RULE"] != "RESTRICT":
            sql += f" ON UPDATE {fk['UPDATE_RULE']}"

        sql += ";"
        return sql

    def _format_migration_content(
        self, up_statements: List[str], down_statements: List[str], description: str
    ) -> str:
        """Format migration file content."""
        content = f"""-- Migration: {description}
-- Generated: {datetime.now().isoformat()}

-- ============================================
-- UP MIGRATION
-- ============================================

"""
        content += "\n".join(up_statements)

        if down_statements:
            content += """

-- ============================================
-- ==== ROLLBACK ====
-- ============================================

"""
            content += "\n".join(down_statements)

        return content

    def generate_from_sql_file(
        self, sql_file: Path, description: str, include_rollback: bool = False
    ) -> Tuple[str, str]:
        """
        Generate migration from SQL file.

        Args:
            sql_file: Path to SQL file
            description: Migration description
            include_rollback: Whether to generate rollback

        Returns:
            Tuple of (version, filename)
        """
        version = self._generate_version()

        with open(sql_file, "r") as f:
            up_sql = f.read()

        down_sql = ""
        if include_rollback:
            # Try to generate rollback (simplified)
            down_sql = self._generate_simple_rollback(up_sql)

        content = self._format_migration_content(
            [up_sql], [down_sql] if down_sql else [], description
        )

        filename = self._generate_filename(version, description)
        file_path = self.migrations_path / filename

        with open(file_path, "w") as f:
            f.write(content)

        logger.info(f"Generated migration from SQL file: {filename}")
        return version, filename

    def _generate_simple_rollback(self, up_sql: str) -> str:
        """Generate simple rollback from up migration."""
        rollback_statements = []

        # Simple pattern matching for common cases
        create_table_pattern = r"CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?(\w+)"
        for match in re.finditer(create_table_pattern, up_sql, re.IGNORECASE):
            table_name = match.group(1)
            rollback_statements.append(f"DROP TABLE IF EXISTS {table_name};")

        add_column_pattern = r"ALTER\s+TABLE\s+(\w+)\s+ADD\s+(?:COLUMN\s+)?(\w+)"
        for match in re.finditer(add_column_pattern, up_sql, re.IGNORECASE):
            table_name = match.group(1)
            column_name = match.group(2)
            rollback_statements.append(
                f"ALTER TABLE {table_name} DROP COLUMN {column_name};"
            )

        create_index_pattern = r"CREATE\s+(?:UNIQUE\s+)?INDEX\s+(\w+)\s+ON\s+(\w+)"
        for match in re.finditer(create_index_pattern, up_sql, re.IGNORECASE):
            index_name = match.group(1)
            table_name = match.group(2)
            rollback_statements.append(f"DROP INDEX {index_name} ON {table_name};")

        if rollback_statements:
            return "\n".join(reversed(rollback_statements))
        else:
            return "-- TODO: Add rollback statements"
