#!/usr/bin/env python3
"""
MySQL to PostgreSQL Schema Converter

Converts MySQL DDL to PostgreSQL-compatible SQL.
"""

import re
import argparse
from pathlib import Path
from typing import List, Dict, Optional, Tuple
from datetime import datetime


class MySQLToPostgreSQLConverter:
    """Convert MySQL schemas to PostgreSQL"""

    # Type mappings from MySQL to PostgreSQL
    TYPE_MAPPINGS = {
        # Numeric types
        "tinyint": "SMALLINT",
        "smallint": "SMALLINT",
        "mediumint": "INTEGER",
        "int": "INTEGER",
        "integer": "INTEGER",
        "bigint": "BIGINT",
        "decimal": "DECIMAL",
        "numeric": "NUMERIC",
        "float": "REAL",
        "double": "DOUBLE PRECISION",
        "real": "REAL",
        "bit": "BOOLEAN",
        "boolean": "BOOLEAN",
        "bool": "BOOLEAN",
        # String types
        "char": "CHAR",
        "varchar": "VARCHAR",
        "tinytext": "TEXT",
        "text": "TEXT",
        "mediumtext": "TEXT",
        "longtext": "TEXT",
        "binary": "BYTEA",
        "varbinary": "BYTEA",
        "tinyblob": "BYTEA",
        "blob": "BYTEA",
        "mediumblob": "BYTEA",
        "longblob": "BYTEA",
        # Date/Time types
        "date": "DATE",
        "datetime": "TIMESTAMP",
        "timestamp": "TIMESTAMP",
        "time": "TIME",
        "year": "INTEGER",
        # JSON
        "json": "JSONB",
        # Enum handled separately
        "enum": "VARCHAR",
        "set": "TEXT[]",
    }

    def __init__(self):
        self.output_lines = []
        self.enums = {}
        self.sequences = []
        self.current_table = None
        self.foreign_keys = []
        self.indexes = []

    def convert_file(self, input_file: Path) -> str:
        """Convert a MySQL SQL file to PostgreSQL"""
        with open(input_file, "r", encoding="utf-8") as f:
            content = f.read()

        # Clean the content
        content = self._clean_sql(content)

        # Split into statements
        statements = self._split_statements(content)

        # Process each statement
        for statement in statements:
            self._process_statement(statement)

        # Build final output
        return self._build_output()

    def _clean_sql(self, sql: str) -> str:
        """Clean SQL content"""
        # Remove MySQL-specific comments
        sql = re.sub(r"/\*![\d\s]+", "/*", sql)
        sql = re.sub(r"\*/", "*/", sql)

        # Remove backticks
        sql = sql.replace("`", "")

        return sql

    def _split_statements(self, sql: str) -> List[str]:
        """Split SQL into individual statements"""
        # Simple split by semicolon (can be improved)
        statements = []
        current = []

        for line in sql.split("\n"):
            line = line.strip()
            if not line or line.startswith("--"):
                continue

            current.append(line)

            if line.endswith(";"):
                statements.append("\n".join(current))
                current = []

        if current:
            statements.append("\n".join(current))

        return statements

    def _process_statement(self, statement: str) -> None:
        """Process a single SQL statement"""
        statement = statement.strip()

        if not statement:
            return

        # Determine statement type
        upper_stmt = statement.upper()

        if upper_stmt.startswith("CREATE DATABASE"):
            self._process_create_database(statement)
        elif upper_stmt.startswith("CREATE TABLE"):
            self._process_create_table(statement)
        elif upper_stmt.startswith("ALTER TABLE"):
            self._process_alter_table(statement)
        elif upper_stmt.startswith("CREATE INDEX"):
            self._process_create_index(statement)
        elif upper_stmt.startswith("INSERT"):
            self._process_insert(statement)
        elif upper_stmt.startswith("USE"):
            # Skip USE statements
            pass
        elif upper_stmt.startswith("DROP"):
            self.output_lines.append(statement)
        elif upper_stmt.startswith("SET"):
            # Skip SET statements
            pass
        else:
            # Keep other statements as-is
            self.output_lines.append(statement)

    def _process_create_database(self, statement: str) -> None:
        """Process CREATE DATABASE statement"""
        # PostgreSQL version
        db_match = re.search(
            r"CREATE\s+DATABASE\s+(?:IF\s+NOT\s+EXISTS\s+)?(\w+)",
            statement,
            re.IGNORECASE,
        )
        if db_match:
            db_name = db_match.group(1)
            self.output_lines.append(f"-- Create database (run as superuser)")
            self.output_lines.append(f"-- CREATE DATABASE {db_name};")
            self.output_lines.append(f"-- \\c {db_name}")
            self.output_lines.append("")

    def _process_create_table(self, statement: str) -> None:
        """Process CREATE TABLE statement"""
        # Extract table name
        table_match = re.search(
            r"CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?(\w+)", statement, re.IGNORECASE
        )
        if not table_match:
            return

        table_name = table_match.group(1)
        self.current_table = table_name

        # Extract table content
        content_match = re.search(
            r"CREATE\s+TABLE[^(]+\((.*)\)\s*(?:ENGINE|;)",
            statement,
            re.IGNORECASE | re.DOTALL,
        )
        if not content_match:
            return

        content = content_match.group(1)

        # Start building PostgreSQL table
        pg_lines = [f"CREATE TABLE IF NOT EXISTS {table_name} ("]
        field_lines = []

        # Parse fields
        lines = self._split_table_content(content)

        for line in lines:
            line = line.strip()
            if not line:
                continue

            # Handle different line types
            if re.match(r"^\w+\s+", line) and not any(
                k in line.upper()
                for k in [
                    "PRIMARY",
                    "FOREIGN",
                    "KEY",
                    "INDEX",
                    "UNIQUE",
                    "CONSTRAINT",
                    "CHECK",
                ]
            ):
                # This is a field definition
                pg_field = self._convert_field(line, table_name)
                if pg_field:
                    field_lines.append(f"    {pg_field}")
            elif "PRIMARY KEY" in line.upper():
                # Handle primary key
                pk = self._convert_primary_key(line)
                if pk:
                    field_lines.append(f"    {pk}")
            elif "FOREIGN KEY" in line.upper():
                # Store foreign key for later
                self.foreign_keys.append((table_name, line))
            elif "INDEX" in line.upper() or "KEY" in line.upper():
                # Store index for later
                if "UNIQUE" in line.upper():
                    unique = self._convert_unique_constraint(line)
                    if unique:
                        field_lines.append(f"    {unique}")
                else:
                    self.indexes.append((table_name, line))

        pg_lines.append(",\n".join(field_lines))
        pg_lines.append(");")

        self.output_lines.append("\n".join(pg_lines))
        self.output_lines.append("")

        # Add foreign keys as separate statements
        for fk_table, fk_line in self.foreign_keys:
            if fk_table == table_name:
                fk_statement = self._convert_foreign_key(table_name, fk_line)
                if fk_statement:
                    self.output_lines.append(fk_statement)

        self.foreign_keys = [(t, l) for t, l in self.foreign_keys if t != table_name]

    def _split_table_content(self, content: str) -> List[str]:
        """Split table content into field/constraint lines"""
        lines = []
        current_line = ""
        paren_depth = 0

        for char in content:
            current_line += char

            if char == "(":
                paren_depth += 1
            elif char == ")":
                paren_depth -= 1
            elif char == "," and paren_depth == 0:
                lines.append(current_line[:-1].strip())
                current_line = ""

        if current_line.strip():
            lines.append(current_line.strip())

        return lines

    def _convert_field(self, field_line: str, table_name: str) -> Optional[str]:
        """Convert a field definition from MySQL to PostgreSQL"""
        # Parse field
        match = re.match(r"(\w+)\s+(\w+)(?:\(([^)]+)\))?\s*(.*)", field_line)
        if not match:
            return None

        field_name = match.group(1)
        field_type = match.group(2).lower()
        field_size = match.group(3)
        modifiers = match.group(4) if match.group(4) else ""

        # Convert type
        pg_type = self._convert_type(field_type, field_size)

        # Handle AUTO_INCREMENT
        if "AUTO_INCREMENT" in modifiers.upper():
            # Use SERIAL or BIGSERIAL
            if "bigint" in field_type:
                pg_type = "BIGSERIAL"
            else:
                pg_type = "SERIAL"
            modifiers = re.sub(r"AUTO_INCREMENT", "", modifiers, flags=re.IGNORECASE)

        # Handle UNSIGNED
        modifiers = re.sub(r"UNSIGNED", "", modifiers, flags=re.IGNORECASE)

        # Handle ON UPDATE CURRENT_TIMESTAMP
        if "ON UPDATE CURRENT_TIMESTAMP" in modifiers.upper():
            modifiers = re.sub(
                r"ON\s+UPDATE\s+CURRENT_TIMESTAMP", "", modifiers, flags=re.IGNORECASE
            )
            # Note: PostgreSQL doesn't have automatic ON UPDATE, need trigger

        # Handle DEFAULT
        modifiers = self._convert_default(modifiers)

        # Handle COMMENT
        modifiers = re.sub(r"COMMENT\s+'[^']*'", "", modifiers, flags=re.IGNORECASE)

        # Clean up
        modifiers = " ".join(modifiers.split())

        return f"{field_name} {pg_type} {modifiers}".strip()

    def _convert_type(self, mysql_type: str, size: Optional[str]) -> str:
        """Convert MySQL type to PostgreSQL type"""
        base_type = mysql_type.lower()

        # Check if it's an enum
        if base_type == "enum" and size:
            # Create enum type with better naming
            enum_name = f"{self.current_table}_status"
            values = [v.strip().strip("'\"") for v in size.split(",")]
            self.enums[enum_name] = values
            return enum_name

        # Get PostgreSQL equivalent
        pg_type = self.TYPE_MAPPINGS.get(base_type, "TEXT")

        # Handle types with size
        if size and base_type in ["varchar", "char", "decimal", "numeric"]:
            return f"{pg_type}({size})"

        return pg_type

    def _convert_default(self, modifiers: str) -> str:
        """Convert DEFAULT clause"""
        # Replace MySQL functions with PostgreSQL equivalents
        modifiers = re.sub(
            r"DEFAULT\s+CURRENT_TIMESTAMP",
            "DEFAULT CURRENT_TIMESTAMP",
            modifiers,
            flags=re.IGNORECASE,
        )
        modifiers = re.sub(
            r"DEFAULT\s+NULL", "DEFAULT NULL", modifiers, flags=re.IGNORECASE
        )
        modifiers = re.sub(
            r"DEFAULT\s+\(''\)", "DEFAULT ''", modifiers, flags=re.IGNORECASE
        )

        return modifiers

    def _convert_primary_key(self, line: str) -> Optional[str]:
        """Convert PRIMARY KEY constraint"""
        match = re.search(r"PRIMARY\s+KEY\s*\(([^)]+)\)", line, re.IGNORECASE)
        if match:
            keys = match.group(1)
            return f"PRIMARY KEY ({keys})"
        return None

    def _convert_foreign_key(self, table_name: str, line: str) -> Optional[str]:
        """Convert FOREIGN KEY constraint to separate ALTER TABLE"""
        match = re.search(
            r"(?:CONSTRAINT\s+(\w+)\s+)?FOREIGN\s+KEY\s*\(([^)]+)\)\s+REFERENCES\s+(\w+)\s*\(([^)]+)\)",
            line,
            re.IGNORECASE,
        )
        if match:
            constraint_name = match.group(1) or f"fk_{table_name}_{match.group(2)}"
            local_key = match.group(2)
            ref_table = match.group(3)
            ref_key = match.group(4)

            # Check for ON DELETE/UPDATE actions
            on_delete = ""
            on_update = ""
            if "ON DELETE" in line.upper():
                del_match = re.search(r"ON\s+DELETE\s+(\w+)", line, re.IGNORECASE)
                if del_match:
                    on_delete = f" ON DELETE {del_match.group(1)}"
            if "ON UPDATE" in line.upper():
                upd_match = re.search(r"ON\s+UPDATE\s+(\w+)", line, re.IGNORECASE)
                if upd_match:
                    on_update = f" ON UPDATE {upd_match.group(1)}"

            return f"ALTER TABLE {table_name} ADD CONSTRAINT {constraint_name} FOREIGN KEY ({local_key}) REFERENCES {ref_table}({ref_key}){on_delete}{on_update};"

        return None

    def _convert_unique_constraint(self, line: str) -> Optional[str]:
        """Convert UNIQUE constraint"""
        match = re.search(
            r"UNIQUE\s+(?:KEY|INDEX)?\s*(?:\w+)?\s*\(([^)]+)\)", line, re.IGNORECASE
        )
        if match:
            keys = match.group(1)
            return f"UNIQUE ({keys})"
        return None

    def _process_alter_table(self, statement: str) -> None:
        """Process ALTER TABLE statement"""
        # Most ALTER TABLE statements can remain similar
        statement = statement.replace("`", "")
        statement = re.sub(r"AFTER\s+\w+", "", statement, flags=re.IGNORECASE)
        statement = re.sub(r"FIRST", "", statement, flags=re.IGNORECASE)
        self.output_lines.append(statement)

    def _process_create_index(self, statement: str) -> None:
        """Process CREATE INDEX statement"""
        statement = statement.replace("`", "")
        # PostgreSQL syntax is similar
        self.output_lines.append(statement)

    def _process_insert(self, statement: str) -> None:
        """Process INSERT statement"""
        statement = statement.replace("`", "")
        # Handle different NULL representations
        statement = statement.replace("\\N", "NULL")
        self.output_lines.append(statement)

    def _build_output(self) -> str:
        """Build final PostgreSQL output"""
        output = []

        # Header
        output.append("-- PostgreSQL Schema")
        output.append(f"-- Converted from MySQL on {datetime.now().isoformat()}")
        output.append("-- Generator: MySQL to PostgreSQL Converter")
        output.append("")

        # Create enum types first
        if self.enums:
            output.append("-- Enum Types")
            for enum_name, values in self.enums.items():
                values_str = ", ".join(f"'{v}'" for v in values)
                output.append(f"CREATE TYPE {enum_name} AS ENUM ({values_str});")
            output.append("")

        # Add main content
        output.extend(self.output_lines)

        # Add indexes at the end
        if self.indexes:
            output.append("-- Indexes")
            for table_name, index_line in self.indexes:
                # Convert MySQL index to PostgreSQL
                if "KEY" in index_line.upper():
                    match = re.search(
                        r"KEY\s+(\w+)\s*\(([^)]+)\)", index_line, re.IGNORECASE
                    )
                    if match:
                        index_name = match.group(1)
                        columns = match.group(2)
                        output.append(
                            f"CREATE INDEX idx_{table_name}_{index_name} ON {table_name}({columns});"
                        )
            output.append("")

        return "\n".join(output)


def convert_example(example_dir: Path, output_dir: Path = None) -> bool:
    """Convert schemas for a single example"""
    print(f"Converting {example_dir.name} to PostgreSQL...")

    # Find SQL files
    schema_dir = example_dir / "schema"
    if not schema_dir.exists():
        print(f"  No schema directory found")
        return False

    sql_files = sorted(schema_dir.glob("*.sql"))
    if not sql_files:
        print(f"  No SQL files found")
        return False

    # Create output directory
    if output_dir is None:
        output_dir = example_dir / "schema_postgres"
    output_dir.mkdir(exist_ok=True)

    converter = MySQLToPostgreSQLConverter()

    for sql_file in sql_files:
        print(f"  Converting {sql_file.name}...")

        try:
            # Convert file
            postgres_sql = converter.convert_file(sql_file)

            # Save output
            output_file = output_dir / sql_file.name.replace(".sql", "_postgres.sql")
            with open(output_file, "w", encoding="utf-8") as f:
                f.write(postgres_sql)

            print(f"    -> {output_file.name}")

        except Exception as e:
            print(f"    ERROR: {e}")
            return False

    print(f"  Completed: {len(sql_files)} files converted")
    return True


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description="Convert MySQL schemas to PostgreSQL")
    parser.add_argument(
        "input", nargs="?", help="Input MySQL SQL file or example directory"
    )
    parser.add_argument("--output", help="Output file or directory")
    parser.add_argument("--all", action="store_true", help="Convert all examples")

    args = parser.parse_args()

    if not args.all and not args.input:
        parser.error("Either provide an input file/directory or use --all flag")

    # Get project root
    script_dir = Path(__file__).parent
    project_root = script_dir.parent

    if args.all:
        # Convert all examples
        example_dirs = sorted([d for d in project_root.glob("example_*") if d.is_dir()])

        print("MySQL to PostgreSQL Converter")
        print("=" * 60)
        print(f"Converting {len(example_dirs)} examples")
        print()

        successful = 0
        failed = 0

        for example_dir in example_dirs:
            if convert_example(example_dir):
                successful += 1
            else:
                failed += 1

        print()
        print("=" * 60)
        print(f"Successful: {successful}")
        print(f"Failed: {failed}")

    else:
        input_path = Path(args.input)

        if input_path.is_dir():
            # Convert example directory
            convert_example(input_path, Path(args.output) if args.output else None)
        else:
            # Convert single file
            converter = MySQLToPostgreSQLConverter()
            postgres_sql = converter.convert_file(input_path)

            if args.output:
                with open(args.output, "w", encoding="utf-8") as f:
                    f.write(postgres_sql)
                print(f"Converted to: {args.output}")
            else:
                print(postgres_sql)


if __name__ == "__main__":
    main()
