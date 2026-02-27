#!/usr/bin/env python3
"""
GraphQL Schema Generator for MySQL Business-to-Schema

Converts MySQL schemas to GraphQL type definitions.
"""

import os
import re
import argparse
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from datetime import datetime


class MySQLToGraphQLMapper:
    """Maps MySQL types to GraphQL types"""

    TYPE_MAPPING = {
        # Numeric types
        "int": "Int",
        "integer": "Int",
        "tinyint": "Int",
        "smallint": "Int",
        "mediumint": "Int",
        "bigint": "String",  # GraphQL doesn't have BigInt natively
        "decimal": "Float",
        "numeric": "Float",
        "float": "Float",
        "double": "Float",
        "real": "Float",
        "bit": "Boolean",
        # String types
        "char": "String",
        "varchar": "String",
        "text": "String",
        "tinytext": "String",
        "mediumtext": "String",
        "longtext": "String",
        "binary": "String",
        "varbinary": "String",
        "blob": "String",
        "tinyblob": "String",
        "mediumblob": "String",
        "longblob": "String",
        # Date/Time types
        "date": "String",  # ISO 8601 date string
        "datetime": "String",  # ISO 8601 datetime string
        "timestamp": "String",  # ISO 8601 datetime string
        "time": "String",
        "year": "Int",
        # JSON type
        "json": "JSON",  # Custom scalar
        # Enum (handled separately)
        "enum": "String",
        "set": "[String]",
        # Boolean
        "boolean": "Boolean",
        "bool": "Boolean",
    }

    @classmethod
    def mysql_to_graphql(cls, mysql_type: str, nullable: bool = True) -> str:
        """Convert MySQL type to GraphQL type"""
        # Extract base type
        base_type = mysql_type.lower().split("(")[0].strip()

        # Get GraphQL type
        graphql_type = cls.TYPE_MAPPING.get(base_type, "String")

        # Add non-nullable marker if needed
        if not nullable:
            graphql_type += "!"

        return graphql_type


class GraphQLSchemaGenerator:
    """Generates GraphQL schemas from MySQL DDL"""

    def __init__(self):
        self.tables = {}
        self.relationships = []
        self.enums = {}

    def parse_sql_file(self, sql_file: Path) -> bool:
        """Parse SQL file and extract schema information"""
        try:
            with open(sql_file, "r", encoding="utf-8") as f:
                content = f.read()

            # Remove comments
            content = re.sub(r"--.*$", "", content, flags=re.MULTILINE)
            content = re.sub(r"/\*.*?\*/", "", content, flags=re.DOTALL)

            # Find CREATE TABLE statements
            table_pattern = r"CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?`?(\w+)`?\s*\((.*?)\)\s*(?:ENGINE|;)"
            matches = re.finditer(table_pattern, content, re.IGNORECASE | re.DOTALL)

            for match in matches:
                table_name = match.group(1)
                table_content = match.group(2)
                self._parse_table(table_name, table_content)

            return True
        except Exception as e:
            print(f"Error parsing SQL file: {e}")
            return False

    def _parse_table(self, table_name: str, content: str):
        """Parse a CREATE TABLE statement"""
        fields = []
        primary_keys = []
        foreign_keys = []

        # Split by lines and parse each field
        lines = content.split(",")

        for line in lines:
            line = line.strip()

            if not line:
                continue

            # Check for PRIMARY KEY
            if "PRIMARY KEY" in line.upper():
                pk_match = re.search(
                    r"PRIMARY\s+KEY\s*\(([^)]+)\)", line, re.IGNORECASE
                )
                if pk_match:
                    keys = pk_match.group(1).replace("`", "").split(",")
                    primary_keys.extend([k.strip() for k in keys])
                continue

            # Check for FOREIGN KEY
            if "FOREIGN KEY" in line.upper():
                fk_match = re.search(
                    r"FOREIGN\s+KEY\s*\(`?(\w+)`?\)\s+REFERENCES\s+`?(\w+)`?\s*\(`?(\w+)`?\)",
                    line,
                    re.IGNORECASE,
                )
                if fk_match:
                    foreign_keys.append(
                        {
                            "field": fk_match.group(1),
                            "ref_table": fk_match.group(2),
                            "ref_field": fk_match.group(3),
                        }
                    )
                continue

            # Skip other constraints
            if any(
                keyword in line.upper()
                for keyword in ["KEY", "INDEX", "UNIQUE", "CONSTRAINT", "CHECK"]
            ):
                continue

            # Parse field definition
            field_match = re.match(r"`?(\w+)`?\s+(\S+)(?:\(([^)]+)\))?\s*(.*)", line)
            if field_match:
                field_name = field_match.group(1)
                field_type = field_match.group(2)
                field_size = field_match.group(3)
                field_modifiers = field_match.group(4) or ""

                # Check if nullable
                nullable = "NOT NULL" not in field_modifiers.upper()

                # Check if auto_increment
                auto_increment = "AUTO_INCREMENT" in field_modifiers.upper()

                # Check for enum values
                enum_values = []
                if field_type.upper() == "ENUM":
                    enum_match = re.search(r"ENUM\s*\((.*?)\)", line, re.IGNORECASE)
                    if enum_match:
                        values_str = enum_match.group(1)
                        enum_values = [
                            v.strip().strip("'\"") for v in values_str.split(",")
                        ]

                fields.append(
                    {
                        "name": field_name,
                        "type": field_type,
                        "size": field_size,
                        "nullable": nullable,
                        "auto_increment": auto_increment,
                        "enum_values": enum_values,
                    }
                )

        # Store table information
        self.tables[table_name] = {
            "fields": fields,
            "primary_keys": primary_keys,
            "foreign_keys": foreign_keys,
        }

    def generate_graphql_schema(self) -> str:
        """Generate GraphQL schema from parsed tables"""
        schema_parts = []

        # Add header
        schema_parts.append(self._generate_header())

        # Add custom scalars
        schema_parts.append(self._generate_scalars())

        # Generate enums
        if self.enums:
            schema_parts.append("# Enums")
            for enum_name, values in self.enums.items():
                schema_parts.append(self._generate_enum(enum_name, values))

        # Generate types for each table
        schema_parts.append("# Types")
        for table_name, table_info in self.tables.items():
            schema_parts.append(self._generate_type(table_name, table_info))

        # Generate input types
        schema_parts.append("# Input Types")
        for table_name, table_info in self.tables.items():
            schema_parts.append(self._generate_input_type(table_name, table_info))

        # Generate queries
        schema_parts.append(self._generate_queries())

        # Generate mutations
        schema_parts.append(self._generate_mutations())

        return "\n\n".join(schema_parts)

    def _generate_header(self) -> str:
        """Generate schema header"""
        return f"""# GraphQL Schema Generated from MySQL
# Generated: {datetime.now().isoformat()}
# Generator: MySQL Business-to-Schema GraphQL Generator

schema {{
  query: Query
  mutation: Mutation
}}"""

    def _generate_scalars(self) -> str:
        """Generate custom scalar definitions"""
        return """# Custom Scalars
scalar DateTime
scalar Date
scalar Time
scalar JSON
scalar BigInt"""

    def _generate_enum(self, name: str, values: List[str]) -> str:
        """Generate enum type"""
        enum_values = "\n  ".join(values)
        return f"""enum {name} {{
  {enum_values}
}}"""

    def _generate_type(self, table_name: str, table_info: Dict) -> str:
        """Generate GraphQL type for a table"""
        type_name = self._to_pascal_case(table_name)
        fields_str = []

        for field in table_info["fields"]:
            field_name = self._to_camel_case(field["name"])
            field_type = MySQLToGraphQLMapper.mysql_to_graphql(
                field["type"], field["nullable"]
            )

            # Handle foreign keys as relationships
            fk_info = next(
                (
                    fk
                    for fk in table_info["foreign_keys"]
                    if fk["field"] == field["name"]
                ),
                None,
            )
            if fk_info:
                # Create relationship field
                ref_type = self._to_pascal_case(fk_info["ref_table"])
                fields_str.append(f"  {field_name}: ID!")
                rel_field_name = self._to_camel_case(fk_info["ref_table"].rstrip("s"))
                fields_str.append(f"  {rel_field_name}: {ref_type}")
            else:
                # Handle primary keys as ID
                if (
                    field["name"] in table_info["primary_keys"]
                    and field["name"] == "id"
                ):
                    fields_str.append(f"  {field_name}: ID!")
                else:
                    # Handle enums
                    if field["enum_values"]:
                        enum_name = (
                            f"{type_name}{self._to_pascal_case(field['name'])}Enum"
                        )
                        self.enums[enum_name] = [
                            v.upper().replace(" ", "_") for v in field["enum_values"]
                        ]
                        field_type = enum_name + ("!" if not field["nullable"] else "")
                        fields_str.append(f"  {field_name}: {field_type}")
                    else:
                        fields_str.append(f"  {field_name}: {field_type}")

        # Add timestamps
        if any(f["name"] in ["created_at", "updated_at"] for f in table_info["fields"]):
            if "createdAt: DateTime" not in "\n".join(fields_str):
                fields_str.append("  createdAt: DateTime")
            if "updatedAt: DateTime" not in "\n".join(fields_str):
                fields_str.append("  updatedAt: DateTime")

        return f"""type {type_name} {{
{chr(10).join(fields_str)}
}}"""

    def _generate_input_type(self, table_name: str, table_info: Dict) -> str:
        """Generate GraphQL input type for mutations"""
        type_name = self._to_pascal_case(table_name)
        fields_str = []

        for field in table_info["fields"]:
            # Skip auto-increment fields
            if field["auto_increment"]:
                continue

            field_name = self._to_camel_case(field["name"])
            field_type = MySQLToGraphQLMapper.mysql_to_graphql(
                field["type"], True
            )  # All input fields optional

            # Handle foreign keys
            fk_info = next(
                (
                    fk
                    for fk in table_info["foreign_keys"]
                    if fk["field"] == field["name"]
                ),
                None,
            )
            if fk_info:
                fields_str.append(f"  {field_name}: ID")
            else:
                # Handle enums
                if field["enum_values"]:
                    enum_name = f"{type_name}{self._to_pascal_case(field['name'])}Enum"
                    fields_str.append(f"  {field_name}: {enum_name}")
                else:
                    fields_str.append(f"  {field_name}: {field_type.rstrip('!')}")

        return f"""input {type_name}Input {{
{chr(10).join(fields_str)}
}}

input {type_name}UpdateInput {{
{chr(10).join(fields_str)}
}}"""

    def _generate_queries(self) -> str:
        """Generate Query type with all queries"""
        queries = []

        for table_name in self.tables:
            type_name = self._to_pascal_case(table_name)
            single_name = self._to_camel_case(table_name.rstrip("s"))
            plural_name = self._to_camel_case(table_name)

            # Single item query
            queries.append(f"  {single_name}(id: ID!): {type_name}")

            # List query with pagination
            queries.append(
                f"""  {plural_name}(
    limit: Int = 10
    offset: Int = 0
    orderBy: String
    filter: String
  ): [{type_name}!]!"""
            )

            # Count query
            queries.append(f"  {plural_name}Count(filter: String): Int!")

        return f"""type Query {{
{chr(10).join(queries)}
}}"""

    def _generate_mutations(self) -> str:
        """Generate Mutation type with all mutations"""
        mutations = []

        for table_name in self.tables:
            type_name = self._to_pascal_case(table_name)
            single_name = self._to_camel_case(table_name.rstrip("s"))

            # Create mutation
            mutations.append(
                f"  create{type_name}(input: {type_name}Input!): {type_name}!"
            )

            # Update mutation
            mutations.append(
                f"  update{type_name}(id: ID!, input: {type_name}UpdateInput!): {type_name}!"
            )

            # Delete mutation
            mutations.append(f"  delete{type_name}(id: ID!): Boolean!")

            # Batch operations
            mutations.append(
                f"  create{type_name}Batch(input: [{type_name}Input!]!): [{type_name}!]!"
            )

        return f"""type Mutation {{
{chr(10).join(mutations)}
}}"""

    def _to_pascal_case(self, snake_str: str) -> str:
        """Convert snake_case to PascalCase"""
        components = snake_str.split("_")
        return "".join(x.title() for x in components)

    def _to_camel_case(self, snake_str: str) -> str:
        """Convert snake_case to camelCase"""
        components = snake_str.split("_")
        return components[0] + "".join(x.title() for x in components[1:])


def generate_for_example(example_dir: Path) -> bool:
    """Generate GraphQL schema for a single example"""
    print(f"Generating GraphQL schema for {example_dir.name}...")

    # Find SQL files
    schema_dir = example_dir / "schema"
    if not schema_dir.exists():
        print(f"  No schema directory found")
        return False

    sql_files = list(schema_dir.glob("*.sql"))
    if not sql_files:
        print(f"  No SQL files found")
        return False

    # Create generator
    generator = GraphQLSchemaGenerator()

    # Parse all SQL files
    for sql_file in sql_files:
        print(f"  Parsing {sql_file.name}...")
        generator.parse_sql_file(sql_file)

    if not generator.tables:
        print(f"  No tables found in SQL files")
        return False

    # Generate GraphQL schema
    graphql_schema = generator.generate_graphql_schema()

    # Create graphql directory
    graphql_dir = example_dir / "graphql"
    graphql_dir.mkdir(exist_ok=True)

    # Write schema file
    output_file = graphql_dir / "schema.graphql"
    with open(output_file, "w", encoding="utf-8") as f:
        f.write(graphql_schema)

    print(f"  Generated: {output_file}")
    print(f"  Tables: {len(generator.tables)}")
    print(f"  Enums: {len(generator.enums)}")

    return True


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description="Generate GraphQL schemas from MySQL DDL"
    )
    parser.add_argument(
        "--examples", nargs="+", help="Specific examples to generate for"
    )
    parser.add_argument("--all", action="store_true", help="Generate for all examples")
    parser.add_argument("--output", help="Output directory for schemas")

    args = parser.parse_args()

    # Get project root
    script_dir = Path(__file__).parent
    project_root = script_dir.parent

    # Determine which examples to process
    if args.all:
        example_dirs = sorted([d for d in project_root.glob("example_*") if d.is_dir()])
    elif args.examples:
        example_dirs = []
        for ex in args.examples:
            if not ex.startswith("example_"):
                ex = f"example_{ex}"
            ex_dir = project_root / ex
            if ex_dir.exists():
                example_dirs.append(ex_dir)
    else:
        print("Please specify --all or --examples")
        return

    print("MySQL to GraphQL Schema Generator")
    print("=" * 60)
    print(f"Processing {len(example_dirs)} examples")
    print()

    successful = 0
    failed = 0

    for example_dir in example_dirs:
        if generate_for_example(example_dir):
            successful += 1
        else:
            failed += 1

    print()
    print("=" * 60)
    print("Summary")
    print(f"Successful: {successful}")
    print(f"Failed: {failed}")


if __name__ == "__main__":
    main()
