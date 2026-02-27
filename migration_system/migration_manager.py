#!/usr/bin/env python3
"""
Automated Database Migration System

Handles schema migrations between different database systems:
- MySQL to PostgreSQL
- MySQL to MongoDB
- Version control for migrations
- Rollback capabilities
- Data type mapping
"""

import os
import json
import hashlib
import re
from datetime import datetime
from typing import Dict, List, Optional, Tuple, Any
from dataclasses import dataclass, field
from enum import Enum
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class DatabaseType(Enum):
    """Supported database types"""

    MYSQL = "mysql"
    POSTGRESQL = "postgresql"
    MONGODB = "mongodb"
    SQLITE = "sqlite"


class MigrationStatus(Enum):
    """Migration status types"""

    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    FAILED = "failed"
    ROLLED_BACK = "rolled_back"


@dataclass
class Column:
    """Represents a database column"""

    name: str
    data_type: str
    nullable: bool = True
    primary_key: bool = False
    auto_increment: bool = False
    unique: bool = False
    default: Any = None
    length: Optional[int] = None
    precision: Optional[int] = None
    scale: Optional[int] = None
    comment: Optional[str] = None
    foreign_key: Optional[Dict] = None


@dataclass
class Index:
    """Represents a database index"""

    name: str
    columns: List[str]
    unique: bool = False
    index_type: str = "BTREE"
    comment: Optional[str] = None


@dataclass
class Table:
    """Represents a database table"""

    name: str
    columns: List[Column] = field(default_factory=list)
    indexes: List[Index] = field(default_factory=list)
    primary_key: List[str] = field(default_factory=list)
    foreign_keys: List[Dict] = field(default_factory=list)
    comment: Optional[str] = None
    engine: str = "InnoDB"
    charset: str = "utf8mb4"
    collation: str = "utf8mb4_unicode_ci"


@dataclass
class Migration:
    """Represents a migration"""

    id: str
    name: str
    source_type: DatabaseType
    target_type: DatabaseType
    version: str
    checksum: str
    up_script: str
    down_script: str
    status: MigrationStatus = MigrationStatus.PENDING
    executed_at: Optional[datetime] = None
    execution_time: Optional[float] = None
    error_message: Optional[str] = None


class DataTypeMapper:
    """Maps data types between different database systems"""

    # MySQL to PostgreSQL type mappings
    MYSQL_TO_POSTGRESQL = {
        # Numeric types
        "TINYINT": "SMALLINT",
        "TINYINT UNSIGNED": "SMALLINT",
        "SMALLINT": "SMALLINT",
        "SMALLINT UNSIGNED": "INTEGER",
        "MEDIUMINT": "INTEGER",
        "MEDIUMINT UNSIGNED": "INTEGER",
        "INT": "INTEGER",
        "INT UNSIGNED": "BIGINT",
        "INTEGER": "INTEGER",
        "INTEGER UNSIGNED": "BIGINT",
        "BIGINT": "BIGINT",
        "BIGINT UNSIGNED": "NUMERIC(20)",
        "DECIMAL": "DECIMAL",
        "NUMERIC": "NUMERIC",
        "FLOAT": "REAL",
        "DOUBLE": "DOUBLE PRECISION",
        "BIT": "BIT",
        # String types
        "CHAR": "CHAR",
        "VARCHAR": "VARCHAR",
        "TINYTEXT": "TEXT",
        "TEXT": "TEXT",
        "MEDIUMTEXT": "TEXT",
        "LONGTEXT": "TEXT",
        "ENUM": "VARCHAR",  # PostgreSQL doesn't have ENUM in same way
        "SET": "TEXT[]",  # Use array in PostgreSQL
        # Binary types
        "BINARY": "BYTEA",
        "VARBINARY": "BYTEA",
        "TINYBLOB": "BYTEA",
        "BLOB": "BYTEA",
        "MEDIUMBLOB": "BYTEA",
        "LONGBLOB": "BYTEA",
        # Date and time types
        "DATE": "DATE",
        "TIME": "TIME",
        "DATETIME": "TIMESTAMP",
        "TIMESTAMP": "TIMESTAMP",
        "YEAR": "INTEGER",
        # JSON type
        "JSON": "JSONB",
        # Spatial types
        "GEOMETRY": "GEOMETRY",
        "POINT": "POINT",
        "LINESTRING": "LINE",
        "POLYGON": "POLYGON",
        # Boolean
        "BOOLEAN": "BOOLEAN",
        "BOOL": "BOOLEAN",
    }

    # MySQL to MongoDB type mappings
    MYSQL_TO_MONGODB = {
        # Numeric types
        "TINYINT": "Int32",
        "SMALLINT": "Int32",
        "MEDIUMINT": "Int32",
        "INT": "Int32",
        "INTEGER": "Int32",
        "BIGINT": "Long",
        "DECIMAL": "Decimal128",
        "NUMERIC": "Decimal128",
        "FLOAT": "Double",
        "DOUBLE": "Double",
        "BIT": "Boolean",
        # String types
        "CHAR": "String",
        "VARCHAR": "String",
        "TINYTEXT": "String",
        "TEXT": "String",
        "MEDIUMTEXT": "String",
        "LONGTEXT": "String",
        "ENUM": "String",
        "SET": "Array",
        # Binary types
        "BINARY": "BinData",
        "VARBINARY": "BinData",
        "TINYBLOB": "BinData",
        "BLOB": "BinData",
        "MEDIUMBLOB": "BinData",
        "LONGBLOB": "BinData",
        # Date and time types
        "DATE": "Date",
        "TIME": "String",  # Store as ISO string
        "DATETIME": "Date",
        "TIMESTAMP": "Date",
        "YEAR": "Int32",
        # JSON type
        "JSON": "Object",
        # Spatial types (store as GeoJSON)
        "GEOMETRY": "Object",
        "POINT": "Object",
        "LINESTRING": "Object",
        "POLYGON": "Object",
        # Boolean
        "BOOLEAN": "Boolean",
        "BOOL": "Boolean",
    }

    @classmethod
    def map_type(
        cls,
        source_type: str,
        source_db: DatabaseType,
        target_db: DatabaseType,
        length: Optional[int] = None,
    ) -> str:
        """Map data type from source to target database"""

        source_type = source_type.upper()

        # Remove length/precision from type for mapping
        base_type = re.sub(r"\([^)]+\)", "", source_type).strip()

        if source_db == DatabaseType.MYSQL and target_db == DatabaseType.POSTGRESQL:
            mapped_type = cls.MYSQL_TO_POSTGRESQL.get(base_type, "TEXT")

            # Add length back if applicable
            if length and mapped_type in ["VARCHAR", "CHAR"]:
                mapped_type = f"{mapped_type}({length})"

            return mapped_type

        elif source_db == DatabaseType.MYSQL and target_db == DatabaseType.MONGODB:
            return cls.MYSQL_TO_MONGODB.get(base_type, "String")

        else:
            return source_type  # Return as-is if no mapping available


class SchemaParser:
    """Parses database schemas from SQL files"""

    @staticmethod
    def parse_mysql_schema(sql_content: str) -> List[Table]:
        """Parse MySQL schema from SQL content"""
        tables = []

        # Regular expressions for parsing
        table_pattern = r"CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?`?(\w+)`?\s*\((.*?)\)\s*(?:ENGINE=(\w+))?(?:.*?DEFAULT\s+CHARSET=(\w+))?(?:.*?COLLATE=(\w+))?;"
        column_pattern = r'`?(\w+)`?\s+(\w+(?:\([^)]+\))?)\s*(UNSIGNED)?\s*(NOT\s+NULL|NULL)?\s*(AUTO_INCREMENT)?\s*(PRIMARY\s+KEY)?\s*(UNIQUE)?\s*(?:DEFAULT\s+([^,\n]+))?(?:COMMENT\s+[\'"]([^\'"]+)[\'"])?'
        index_pattern = r"(?:KEY|INDEX)\s+`?(\w+)`?\s*\(([^)]+)\)"
        unique_pattern = r"UNIQUE\s+(?:KEY|INDEX)\s+`?(\w+)`?\s*\(([^)]+)\)"
        primary_pattern = r"PRIMARY\s+KEY\s*\(([^)]+)\)"
        foreign_pattern = (
            r"FOREIGN\s+KEY\s*\(`?(\w+)`?\)\s*REFERENCES\s+`?(\w+)`?\s*\(`?(\w+)`?\)"
        )

        # Find all table definitions
        table_matches = re.finditer(
            table_pattern, sql_content, re.IGNORECASE | re.DOTALL
        )

        for table_match in table_matches:
            table_name = table_match.group(1)
            table_content = table_match.group(2)
            engine = table_match.group(3) or "InnoDB"
            charset = table_match.group(4) or "utf8mb4"
            collation = table_match.group(5) or "utf8mb4_unicode_ci"

            table = Table(
                name=table_name, engine=engine, charset=charset, collation=collation
            )

            # Parse columns
            lines = table_content.split(",")
            for line in lines:
                line = line.strip()

                # Check for primary key constraint
                primary_match = re.match(primary_pattern, line, re.IGNORECASE)
                if primary_match:
                    table.primary_key = [
                        col.strip().strip("`")
                        for col in primary_match.group(1).split(",")
                    ]
                    continue

                # Check for foreign key constraint
                foreign_match = re.match(foreign_pattern, line, re.IGNORECASE)
                if foreign_match:
                    table.foreign_keys.append(
                        {
                            "column": foreign_match.group(1),
                            "ref_table": foreign_match.group(2),
                            "ref_column": foreign_match.group(3),
                        }
                    )
                    continue

                # Check for index
                index_match = re.match(index_pattern, line, re.IGNORECASE)
                if index_match:
                    index = Index(
                        name=index_match.group(1),
                        columns=[
                            col.strip().strip("`")
                            for col in index_match.group(2).split(",")
                        ],
                        unique=False,
                    )
                    table.indexes.append(index)
                    continue

                # Check for unique index
                unique_match = re.match(unique_pattern, line, re.IGNORECASE)
                if unique_match:
                    index = Index(
                        name=unique_match.group(1),
                        columns=[
                            col.strip().strip("`")
                            for col in unique_match.group(2).split(",")
                        ],
                        unique=True,
                    )
                    table.indexes.append(index)
                    continue

                # Parse column definition
                column_match = re.match(column_pattern, line, re.IGNORECASE)
                if column_match:
                    col_name = column_match.group(1)
                    col_type = column_match.group(2)
                    unsigned = column_match.group(3) is not None
                    not_null = (
                        column_match.group(4) and "NOT" in column_match.group(4).upper()
                    )
                    auto_increment = column_match.group(5) is not None
                    primary_key = column_match.group(6) is not None
                    unique = column_match.group(7) is not None
                    default = column_match.group(8)
                    comment = column_match.group(9)

                    # Extract length from type
                    length = None
                    length_match = re.search(r"\((\d+)\)", col_type)
                    if length_match:
                        length = int(length_match.group(1))
                        col_type = re.sub(r"\([^)]+\)", "", col_type)

                    if unsigned:
                        col_type += " UNSIGNED"

                    column = Column(
                        name=col_name,
                        data_type=col_type,
                        nullable=not not_null,
                        primary_key=primary_key,
                        auto_increment=auto_increment,
                        unique=unique,
                        default=default.strip() if default else None,
                        length=length,
                        comment=comment,
                    )

                    table.columns.append(column)

                    if primary_key and col_name not in table.primary_key:
                        table.primary_key.append(col_name)

            tables.append(table)

        return tables


class MigrationGenerator:
    """Generates migration scripts for different database systems"""

    def __init__(self):
        self.type_mapper = DataTypeMapper()

    def generate_postgresql_migration(self, tables: List[Table]) -> str:
        """Generate PostgreSQL migration script from tables"""
        script = []
        script.append("-- PostgreSQL Migration Script")
        script.append("-- Generated at: " + datetime.now().isoformat())
        script.append("")
        script.append("BEGIN;")
        script.append("")

        for table in tables:
            # Drop table if exists
            script.append(f"DROP TABLE IF EXISTS {table.name} CASCADE;")
            script.append("")

            # Create table
            script.append(f"CREATE TABLE {table.name} (")

            # Add columns
            column_definitions = []
            for column in table.columns:
                col_def = f"    {column.name} "

                # Map data type
                pg_type = self.type_mapper.map_type(
                    column.data_type,
                    DatabaseType.MYSQL,
                    DatabaseType.POSTGRESQL,
                    column.length,
                )
                col_def += pg_type

                # Add constraints
                if column.primary_key:
                    col_def += " PRIMARY KEY"
                if column.auto_increment:
                    # PostgreSQL uses SERIAL for auto-increment
                    if "INT" in pg_type or "SERIAL" in pg_type:
                        col_def = f"    {column.name} SERIAL"
                        if column.primary_key:
                            col_def += " PRIMARY KEY"

                if not column.nullable and not column.primary_key:
                    col_def += " NOT NULL"

                if column.unique and not column.primary_key:
                    col_def += " UNIQUE"

                if column.default is not None:
                    default_value = column.default
                    # Handle MySQL specific defaults
                    if default_value.upper() in ["CURRENT_TIMESTAMP", "NOW()"]:
                        default_value = "CURRENT_TIMESTAMP"
                    elif default_value.upper() == "NULL":
                        default_value = "NULL"
                    else:
                        # Quote string defaults
                        if not default_value.isdigit() and default_value != "NULL":
                            default_value = f"'{default_value}'"

                    col_def += f" DEFAULT {default_value}"

                column_definitions.append(col_def)

            # Add foreign key constraints
            for fk in table.foreign_keys:
                fk_def = f"    FOREIGN KEY ({fk['column']}) REFERENCES {fk['ref_table']}({fk['ref_column']})"
                column_definitions.append(fk_def)

            script.append(",\n".join(column_definitions))
            script.append(");")
            script.append("")

            # Create indexes
            for index in table.indexes:
                index_type = "UNIQUE" if index.unique else ""
                index_columns = ", ".join(index.columns)
                script.append(
                    f"CREATE {index_type} INDEX {index.name} ON {table.name} ({index_columns});"
                )

            script.append("")

            # Add table comment
            if table.comment:
                script.append(f"COMMENT ON TABLE {table.name} IS '{table.comment}';")
                script.append("")

            # Add column comments
            for column in table.columns:
                if column.comment:
                    script.append(
                        f"COMMENT ON COLUMN {table.name}.{column.name} IS '{column.comment}';"
                    )

            script.append("")

        script.append("COMMIT;")

        return "\n".join(script)

    def generate_mongodb_migration(self, tables: List[Table]) -> str:
        """Generate MongoDB migration script from tables"""
        script = []
        script.append("// MongoDB Migration Script")
        script.append("// Generated at: " + datetime.now().isoformat())
        script.append("")
        script.append("// Switch to database")
        script.append("use migrated_database;")
        script.append("")

        for table in tables:
            collection_name = table.name
            script.append(f"// Create collection: {collection_name}")
            script.append(f"db.createCollection('{collection_name}');")
            script.append("")

            # Create indexes for primary keys
            if table.primary_key:
                pk_fields = ", ".join([f"{col}: 1" for col in table.primary_key])
                script.append(f"// Primary key index")
                script.append(
                    f"db.{collection_name}.createIndex({{ {pk_fields} }}, {{ unique: true }});"
                )
                script.append("")

            # Create other indexes
            for index in table.indexes:
                index_fields = ", ".join([f"{col}: 1" for col in index.columns])
                unique_option = ", { unique: true }" if index.unique else ""
                script.append(f"// Index: {index.name}")
                script.append(
                    f"db.{collection_name}.createIndex({{ {index_fields} }}{unique_option});"
                )

            script.append("")

            # Create validation schema
            script.append(f"// Validation schema for {collection_name}")
            validation_rules = self._generate_mongodb_validation(table)
            script.append(f"db.runCommand({{")
            script.append(f"    collMod: '{collection_name}',")
            script.append(f"    validator: {{")
            script.append(
                f"        $jsonSchema: {json.dumps(validation_rules, indent=8)}"
            )
            script.append(f"    }},")
            script.append(f"    validationLevel: 'moderate',")
            script.append(f"    validationAction: 'error'")
            script.append(f"}});")
            script.append("")

        return "\n".join(script)

    def _generate_mongodb_validation(self, table: Table) -> Dict:
        """Generate MongoDB JSON schema validation for a table"""
        properties = {}
        required = []

        for column in table.columns:
            mongo_type = self.type_mapper.map_type(
                column.data_type, DatabaseType.MYSQL, DatabaseType.MONGODB
            )

            field_schema = {}

            # Map to BSON types
            if mongo_type == "String":
                field_schema["bsonType"] = "string"
                if column.length:
                    field_schema["maxLength"] = column.length
            elif mongo_type == "Int32":
                field_schema["bsonType"] = "int"
            elif mongo_type == "Long":
                field_schema["bsonType"] = "long"
            elif mongo_type == "Double":
                field_schema["bsonType"] = "double"
            elif mongo_type == "Decimal128":
                field_schema["bsonType"] = "decimal"
            elif mongo_type == "Boolean":
                field_schema["bsonType"] = "bool"
            elif mongo_type == "Date":
                field_schema["bsonType"] = "date"
            elif mongo_type == "Object":
                field_schema["bsonType"] = "object"
            elif mongo_type == "Array":
                field_schema["bsonType"] = "array"
            elif mongo_type == "BinData":
                field_schema["bsonType"] = "binData"

            if column.comment:
                field_schema["description"] = column.comment

            properties[column.name] = field_schema

            if not column.nullable:
                required.append(column.name)

        return {"bsonType": "object", "required": required, "properties": properties}

    def generate_rollback_script(
        self, tables: List[Table], target_type: DatabaseType
    ) -> str:
        """Generate rollback script for a migration"""
        script = []

        if target_type == DatabaseType.POSTGRESQL:
            script.append("-- PostgreSQL Rollback Script")
            script.append("-- Generated at: " + datetime.now().isoformat())
            script.append("")
            script.append("BEGIN;")
            script.append("")

            # Drop tables in reverse order to handle foreign keys
            for table in reversed(tables):
                script.append(f"DROP TABLE IF EXISTS {table.name} CASCADE;")

            script.append("")
            script.append("COMMIT;")

        elif target_type == DatabaseType.MONGODB:
            script.append("// MongoDB Rollback Script")
            script.append("// Generated at: " + datetime.now().isoformat())
            script.append("")
            script.append("use migrated_database;")
            script.append("")

            for table in tables:
                script.append(f"db.{table.name}.drop();")

        return "\n".join(script)


class MigrationManager:
    """Main migration manager class"""

    def __init__(self, migrations_dir: str = "migrations"):
        self.migrations_dir = migrations_dir
        self.parser = SchemaParser()
        self.generator = MigrationGenerator()
        self.migrations: List[Migration] = []

        # Create migrations directory if it doesn't exist
        os.makedirs(migrations_dir, exist_ok=True)
        os.makedirs(os.path.join(migrations_dir, "up"), exist_ok=True)
        os.makedirs(os.path.join(migrations_dir, "down"), exist_ok=True)

    def create_migration(
        self,
        name: str,
        source_file: str,
        source_type: DatabaseType,
        target_type: DatabaseType,
    ) -> Migration:
        """Create a new migration from source schema file"""

        # Read source schema
        with open(source_file, "r", encoding="utf-8") as f:
            sql_content = f.read()

        # Parse schema
        if source_type == DatabaseType.MYSQL:
            tables = self.parser.parse_mysql_schema(sql_content)
        else:
            raise ValueError(f"Unsupported source type: {source_type}")

        # Generate migration scripts
        if target_type == DatabaseType.POSTGRESQL:
            up_script = self.generator.generate_postgresql_migration(tables)
        elif target_type == DatabaseType.MONGODB:
            up_script = self.generator.generate_mongodb_migration(tables)
        else:
            raise ValueError(f"Unsupported target type: {target_type}")

        # Generate rollback script
        down_script = self.generator.generate_rollback_script(tables, target_type)

        # Create migration object
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        migration_id = f"{timestamp}_{name}"
        version = timestamp

        # Calculate checksum
        checksum = hashlib.md5(up_script.encode()).hexdigest()

        migration = Migration(
            id=migration_id,
            name=name,
            source_type=source_type,
            target_type=target_type,
            version=version,
            checksum=checksum,
            up_script=up_script,
            down_script=down_script,
        )

        # Save migration files
        self._save_migration(migration)

        self.migrations.append(migration)
        logger.info(f"Created migration: {migration_id}")

        return migration

    def _save_migration(self, migration: Migration):
        """Save migration scripts to files"""
        up_file = os.path.join(self.migrations_dir, "up", f"{migration.id}.sql")
        down_file = os.path.join(
            self.migrations_dir, "down", f"{migration.id}_rollback.sql"
        )

        with open(up_file, "w", encoding="utf-8") as f:
            f.write(migration.up_script)

        with open(down_file, "w", encoding="utf-8") as f:
            f.write(migration.down_script)

        # Save metadata
        metadata_file = os.path.join(self.migrations_dir, f"{migration.id}.json")
        metadata = {
            "id": migration.id,
            "name": migration.name,
            "source_type": migration.source_type.value,
            "target_type": migration.target_type.value,
            "version": migration.version,
            "checksum": migration.checksum,
            "status": migration.status.value,
            "created_at": datetime.now().isoformat(),
        }

        with open(metadata_file, "w", encoding="utf-8") as f:
            json.dump(metadata, f, indent=2)

    def list_migrations(self) -> List[Dict]:
        """List all migrations"""
        migrations = []

        for file in os.listdir(self.migrations_dir):
            if file.endswith(".json"):
                with open(os.path.join(self.migrations_dir, file), "r") as f:
                    migrations.append(json.load(f))

        return sorted(migrations, key=lambda x: x["version"])

    def get_migration_status(self, migration_id: str) -> Optional[MigrationStatus]:
        """Get status of a specific migration"""
        metadata_file = os.path.join(self.migrations_dir, f"{migration_id}.json")

        if os.path.exists(metadata_file):
            with open(metadata_file, "r") as f:
                metadata = json.load(f)
                return MigrationStatus(metadata["status"])

        return None


def main():
    """Example usage of the migration system"""
    import argparse

    parser = argparse.ArgumentParser(description="Database Migration System")
    parser.add_argument(
        "action", choices=["create", "list", "status"], help="Action to perform"
    )
    parser.add_argument("--name", help="Migration name")
    parser.add_argument("--source", help="Source schema file")
    parser.add_argument(
        "--source-type",
        choices=["mysql", "postgresql"],
        default="mysql",
        help="Source database type",
    )
    parser.add_argument(
        "--target-type",
        choices=["postgresql", "mongodb"],
        required=False,
        help="Target database type",
    )
    parser.add_argument("--migration-id", help="Migration ID for status check")

    args = parser.parse_args()

    manager = MigrationManager()

    if args.action == "create":
        if not args.name or not args.source or not args.target_type:
            print(
                "Error: --name, --source, and --target-type are required for create action"
            )
            return

        source_type = DatabaseType(args.source_type)
        target_type = DatabaseType(args.target_type)

        migration = manager.create_migration(
            name=args.name,
            source_file=args.source,
            source_type=source_type,
            target_type=target_type,
        )

        print(f"Created migration: {migration.id}")
        print(f"Up script: migrations/up/{migration.id}.sql")
        print(f"Down script: migrations/down/{migration.id}_rollback.sql")

    elif args.action == "list":
        migrations = manager.list_migrations()
        if migrations:
            print("Available migrations:")
            for m in migrations:
                print(f"  {m['id']} - {m['name']} ({m['status']})")
        else:
            print("No migrations found")

    elif args.action == "status":
        if not args.migration_id:
            print("Error: --migration-id is required for status action")
            return

        status = manager.get_migration_status(args.migration_id)
        if status:
            print(f"Migration {args.migration_id} status: {status.value}")
        else:
            print(f"Migration {args.migration_id} not found")


if __name__ == "__main__":
    main()
