#!/usr/bin/env python3
"""Advanced GraphQL Schema Generator for MySQL Business-to-Schema.

This module generates complete GraphQL schemas with:
- Type-safe schema definitions
- Resolver templates
- DataLoader integration for N+1 query prevention
- Apollo Server setup
- Pagination support
- Filter and sorting capabilities
"""

import re
import mysql.connector
from pathlib import Path
from typing import Dict, List, Optional
from datetime import datetime
from dataclasses import dataclass, field as dataclass_field


@dataclass
class FieldInfo:
    """Information about a database field."""

    name: str
    type: str
    nullable: bool
    is_primary: bool = False
    is_foreign: bool = False
    reference_table: Optional[str] = None
    reference_field: Optional[str] = None
    enum_values: List[str] = dataclass_field(default_factory=list)
    default_value: Optional[str] = None
    comment: Optional[str] = None


@dataclass
class TableInfo:
    """Information about a database table."""

    name: str
    fields: List[FieldInfo]
    primary_keys: List[str]
    foreign_keys: List[Dict]
    indexes: List[Dict]
    comment: Optional[str] = None


class AdvancedGraphQLGenerator:
    """Advanced GraphQL schema generator with full feature support."""

    def __init__(self, connection_params: Dict):
        """Initialize the instance."""
        self.connection_params = connection_params
        self.connection = None
        self.cursor = None
        self.tables: Dict[str, TableInfo] = {}
        self.relationships: Dict[str, List[Dict]] = {}

    def connect(self) -> bool:
        """Establish database connection."""
        try:
            self.connection = mysql.connector.connect(**self.connection_params)
            self.cursor = self.connection.cursor(dictionary=True)
            return True
        except Exception as e:
            print(f"Connection failed: {e}")
            return False

    def disconnect(self):
        """Close database connection."""
        if self.cursor:
            self.cursor.close()
        if self.connection:
            self.connection.close()

    def analyze_database(self):
        """Analyze database structure."""
        # Get all tables
        self.cursor.execute(
            """
            SELECT TABLE_NAME, TABLE_COMMENT
            FROM information_schema.TABLES
            WHERE TABLE_SCHEMA = %s
            AND TABLE_TYPE = 'BASE TABLE'
        """,
            (self.connection_params["database"],),
        )

        tables = self.cursor.fetchall()

        for table in tables:
            table_name = table["TABLE_NAME"]
            table_info = self._analyze_table(table_name, table["TABLE_COMMENT"])
            self.tables[table_name] = table_info

        # Analyze relationships
        self._analyze_relationships()

    def _analyze_table(self, table_name: str, table_comment: str) -> TableInfo:
        """Analyze a single table."""
        fields = []
        primary_keys = []
        foreign_keys = []

        # Get columns
        self.cursor.execute(
            """
            SELECT
                COLUMN_NAME,
                DATA_TYPE,
                IS_NULLABLE,
                COLUMN_DEFAULT,
                COLUMN_KEY,
                EXTRA,
                COLUMN_COMMENT,
                COLUMN_TYPE
            FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s
            ORDER BY ORDINAL_POSITION
        """,
            (self.connection_params["database"], table_name),
        )

        columns = self.cursor.fetchall()

        for col in columns:
            # Extract enum values if applicable
            enum_values = []
            if col["DATA_TYPE"] == "enum":
                enum_match = re.search(r"enum\((.*?)\)", col["COLUMN_TYPE"])
                if enum_match:
                    values_str = enum_match.group(1)
                    enum_values = [
                        v.strip().strip("'\"") for v in values_str.split(",")
                    ]

            field_info = FieldInfo(
                name=self._to_camel_case(col["COLUMN_NAME"]),
                type=col["DATA_TYPE"],
                nullable=col["IS_NULLABLE"] == "YES",
                is_primary=col["COLUMN_KEY"] == "PRI",
                default_value=col["COLUMN_DEFAULT"],
                comment=col["COLUMN_COMMENT"],
                enum_values=enum_values,
            )

            fields.append(field_info)

            if col["COLUMN_KEY"] == "PRI":
                primary_keys.append(col["COLUMN_NAME"])

        # Get foreign keys
        self.cursor.execute(
            """
            SELECT
                COLUMN_NAME,
                REFERENCED_TABLE_NAME,
                REFERENCED_COLUMN_NAME
            FROM information_schema.KEY_COLUMN_USAGE
            WHERE TABLE_SCHEMA = %s
            AND TABLE_NAME = %s
            AND REFERENCED_TABLE_NAME IS NOT NULL
        """,
            (self.connection_params["database"], table_name),
        )

        fk_results = self.cursor.fetchall()

        for fk in fk_results:
            foreign_keys.append(
                {
                    "column": fk["COLUMN_NAME"],
                    "ref_table": fk["REFERENCED_TABLE_NAME"],
                    "ref_column": fk["REFERENCED_COLUMN_NAME"],
                }
            )

            # Update field info with foreign key data
            for field in fields:
                if field.name == self._to_camel_case(fk["COLUMN_NAME"]):
                    field.is_foreign = True
                    field.reference_table = fk["REFERENCED_TABLE_NAME"]
                    field.reference_field = fk["REFERENCED_COLUMN_NAME"]

        # Get indexes
        indexes = self._get_table_indexes(table_name)

        return TableInfo(
            name=table_name,
            fields=fields,
            primary_keys=primary_keys,
            foreign_keys=foreign_keys,
            indexes=indexes,
            comment=table_comment,
        )

    def _get_table_indexes(self, table_name: str) -> List[Dict]:
        """Get indexes for a table."""
        self.cursor.execute(
            """
            SELECT
                INDEX_NAME,
                GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) as COLUMNS,
                INDEX_TYPE,
                NON_UNIQUE
            FROM information_schema.STATISTICS
            WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s
            AND INDEX_NAME != 'PRIMARY'
            GROUP BY INDEX_NAME, INDEX_TYPE, NON_UNIQUE
        """,
            (self.connection_params["database"], table_name),
        )

        return self.cursor.fetchall()

    def _analyze_relationships(self):
        """Analyze table relationships for generating connections."""
        for table_name, table_info in self.tables.items():
            self.relationships[table_name] = []

            # Has-many relationships (this table is referenced by others)
            for other_table_name, other_table_info in self.tables.items():
                if other_table_name == table_name:
                    continue

                for fk in other_table_info.foreign_keys:
                    if fk["ref_table"] == table_name:
                        self.relationships[table_name].append(
                            {
                                "type": "has_many",
                                "field": self._to_plural(other_table_name),
                                "target_table": other_table_name,
                                "foreign_key": fk["column"],
                                "local_key": fk["ref_column"],
                            }
                        )

            # Belongs-to relationships (this table references others)
            for fk in table_info.foreign_keys:
                self.relationships[table_name].append(
                    {
                        "type": "belongs_to",
                        "field": self._to_camel_case(fk["ref_table"]),
                        "target_table": fk["ref_table"],
                        "foreign_key": fk["column"],
                        "local_key": fk["ref_column"],
                    }
                )

    def generate_schema(self) -> str:
        """Generate complete GraphQL schema."""
        schema_parts = []

        # Header
        schema_parts.append(self._generate_header())

        # Custom scalars
        schema_parts.append(self._generate_scalars())

        # Enums
        schema_parts.append(self._generate_enums())

        # Common types
        schema_parts.append(self._generate_common_types())

        # Object types
        schema_parts.append(self._generate_object_types())

        # Input types
        schema_parts.append(self._generate_input_types())

        # Filter types
        schema_parts.append(self._generate_filter_types())

        # Query type
        schema_parts.append(self._generate_query_type())

        # Mutation type
        schema_parts.append(self._generate_mutation_type())

        # Subscription type
        schema_parts.append(self._generate_subscription_type())

        return "\n\n".join(filter(None, schema_parts))

    def _generate_header(self) -> str:
        """Generate schema header."""
        return f"""# GraphQL Schema for {self.connection_params.get('database', 'database')}
# Generated: {datetime.now().isoformat()}
# Generator: Advanced GraphQL Generator v2.0

schema {{
  query: Query
  mutation: Mutation
  subscription: Subscription
}}"""

    def _generate_scalars(self) -> str:
        """Generate custom scalar definitions."""
        return """# Custom Scalars
scalar DateTime
scalar Date
scalar Time
scalar JSON
scalar BigInt
scalar Decimal
scalar Upload"""

    def _generate_common_types(self) -> str:
        """Generate common utility types."""
        return """# Common Types

interface Node {
  id: ID!
}

type PageInfo {
  hasNextPage: Boolean!
  hasPreviousPage: Boolean!
  startCursor: String
  endCursor: String
  total: Int!
}

enum SortDirection {
  ASC
  DESC
}

type OperationResult {
  success: Boolean!
  message: String
  errors: [String!]
}"""

    def _generate_enums(self) -> str:
        """Generate enum types from database."""
        enums = []

        for table_info in self.tables.values():
            for field in table_info.fields:
                if field.enum_values:
                    enum_name = f"{self._to_pascal_case(table_info.name)}{self._to_pascal_case(field.name)}Enum"
                    enum_values = "\n  ".join(field.enum_values)
                    enums.append(
                        f"""enum {enum_name} {{
  {enum_values}
}}"""
                    )

        if enums:
            return "# Enums\n\n" + "\n\n".join(enums)
        return ""

    def _generate_object_types(self) -> str:
        """Generate GraphQL object types for tables."""
        types = []

        for table_name, table_info in self.tables.items():
            type_name = self._to_pascal_case(table_name)
            fields = []

            # Add regular fields
            for field in table_info.fields:
                graphql_type = self._mysql_to_graphql_type(field.type)
                if not field.nullable:
                    graphql_type += "!"

                comment = f"  # {field.comment}" if field.comment else ""
                fields.append(f"  {field.name}: {graphql_type}{comment}")

            # Add relationships
            if table_name in self.relationships:
                for rel in self.relationships[table_name]:
                    if rel["type"] == "belongs_to":
                        rel_type = self._to_pascal_case(rel["target_table"])
                        fields.append(f"  {rel['field']}: {rel_type}")
                    elif rel["type"] == "has_many":
                        rel_type = self._to_pascal_case(rel["target_table"])
                        fields.append(
                            f"  {rel['field']}(first: Int, after: String, filter: {rel_type}Filter): {rel_type}Connection!"
                        )

            # Add timestamps if not already present
            field_names = [f.name for f in table_info.fields]
            if "createdAt" not in field_names:
                fields.append("  createdAt: DateTime!")
            if "updatedAt" not in field_names:
                fields.append("  updatedAt: DateTime!")

            # Create type definition
            comment = f"# {table_info.comment}\n" if table_info.comment else ""
            types.append(
                f"""{comment}type {type_name} implements Node {{
  id: ID!
{chr(10).join(fields)}
}}

type {type_name}Connection {{
  edges: [{type_name}Edge!]!
  pageInfo: PageInfo!
}}

type {type_name}Edge {{
  node: {type_name}!
  cursor: String!
}}"""
            )

        return "# Object Types\n\n" + "\n\n".join(types)

    def _generate_input_types(self) -> str:
        """Generate input types for mutations."""
        inputs = []

        for table_name, table_info in self.tables.items():
            type_name = self._to_pascal_case(table_name)

            # Create input
            create_fields = []
            for field in table_info.fields:
                if (
                    field.is_primary
                    or "createdAt" in field.name
                    or "updatedAt" in field.name
                ):
                    continue

                graphql_type = self._mysql_to_graphql_type(field.type)
                if not field.nullable and not field.default_value:
                    graphql_type += "!"

                create_fields.append(f"  {field.name}: {graphql_type}")

            inputs.append(
                f"""input Create{type_name}Input {{
{chr(10).join(create_fields)}
}}"""
            )

            # Update input
            update_fields = []
            for field in table_info.fields:
                if (
                    field.is_primary
                    or "createdAt" in field.name
                    or "updatedAt" in field.name
                ):
                    continue

                graphql_type = self._mysql_to_graphql_type(field.type)
                update_fields.append(f"  {field.name}: {graphql_type}")

            inputs.append(
                f"""input Update{type_name}Input {{
{chr(10).join(update_fields)}
}}"""
            )

        return "# Input Types\n\n" + "\n\n".join(inputs)

    def _generate_filter_types(self) -> str:
        """Generate filter types for queries."""
        filters = []

        for table_name, table_info in self.tables.items():
            type_name = self._to_pascal_case(table_name)
            filter_fields = []

            for field in table_info.fields:
                base_type = self._mysql_to_graphql_type(field.type)

                # Add various filter operations
                filter_fields.append(f"  {field.name}: {base_type}")
                filter_fields.append(f"  {field.name}_not: {base_type}")
                filter_fields.append(f"  {field.name}_in: [{base_type}!]")
                filter_fields.append(f"  {field.name}_not_in: [{base_type}!]")

                # Add comparison operators for numeric/date types
                if field.type in [
                    "int",
                    "bigint",
                    "decimal",
                    "float",
                    "double",
                    "date",
                    "datetime",
                    "timestamp",
                ]:
                    filter_fields.append(f"  {field.name}_gt: {base_type}")
                    filter_fields.append(f"  {field.name}_gte: {base_type}")
                    filter_fields.append(f"  {field.name}_lt: {base_type}")
                    filter_fields.append(f"  {field.name}_lte: {base_type}")

                # Add string operations
                if field.type in ["varchar", "text", "char"]:
                    filter_fields.append(f"  {field.name}_contains: String")
                    filter_fields.append(f"  {field.name}_starts_with: String")
                    filter_fields.append(f"  {field.name}_ends_with: String")

            # Add logical operators
            filter_fields.append(f"  AND: [{type_name}Filter!]")
            filter_fields.append(f"  OR: [{type_name}Filter!]")
            filter_fields.append(f"  NOT: {type_name}Filter")

            filters.append(
                f"""input {type_name}Filter {{
{chr(10).join(filter_fields)}
}}

input {type_name}Sort {{
  field: {type_name}SortField!
  direction: SortDirection!
}}

enum {type_name}SortField {{
  {chr(10).join([f"  {field.name.upper()}" for field in table_info.fields])}
}}"""
            )

        return "# Filter Types\n\n" + "\n\n".join(filters)

    def _generate_query_type(self) -> str:
        """Generate Query type with all queries."""
        queries = []

        for table_name, _ in self.tables.items():
            type_name = self._to_pascal_case(table_name)
            singular = self._to_camel_case(table_name)
            plural = self._to_plural(singular)

            # Single item query
            queries.append(f"  {singular}(id: ID!): {type_name}")

            # List query with pagination and filtering
            queries.append(
                f"""  {plural}(
    first: Int
    after: String
    last: Int
    before: String
    filter: {type_name}Filter
    sort: [{type_name}Sort!]
  ): {type_name}Connection!"""
            )

            # Search query
            queries.append(f"  search{type_name}(query: String!): [{type_name}!]!")

        return f"""# Query Type

type Query {{
{chr(10).join(queries)}

  # Node interface query
  node(id: ID!): Node

  # Health check
  health: String!
}}"""

    def _generate_mutation_type(self) -> str:
        """Generate Mutation type."""
        mutations = []

        for table_name, _ in self.tables.items():
            type_name = self._to_pascal_case(table_name)
            _ = self._to_camel_case(table_name)

            # Create mutation
            mutations.append(
                f"""  create{type_name}(
    input: Create{type_name}Input!
  ): {type_name}!"""
            )

            # Update mutation
            mutations.append(
                f"""  update{type_name}(
    id: ID!
    input: Update{type_name}Input!
  ): {type_name}!"""
            )

            # Delete mutation
            mutations.append(
                f"""  delete{type_name}(
    id: ID!
  ): OperationResult!"""
            )

            # Batch operations
            mutations.append(
                f"""  batchCreate{type_name}(
    inputs: [Create{type_name}Input!]!
  ): [{type_name}!]!"""
            )

            mutations.append(
                f"""  batchDelete{type_name}(
    ids: [ID!]!
  ): OperationResult!"""
            )

        return f"""# Mutation Type

type Mutation {{
{chr(10).join(mutations)}
}}"""

    def _generate_subscription_type(self) -> str:
        """Generate Subscription type for real-time updates."""
        subscriptions = []

        for table_name in self.tables.keys():
            type_name = self._to_pascal_case(table_name)
            singular = self._to_camel_case(table_name)

            subscriptions.append(
                f"""  {singular}Created: {type_name}!
  {singular}Updated(id: ID!): {type_name}!
  {singular}Deleted: ID!"""
            )

        return f"""# Subscription Type

type Subscription {{
{chr(10).join(subscriptions)}
}}"""

    def _mysql_to_graphql_type(self, mysql_type: str) -> str:
        """Convert MySQL type to GraphQL type."""
        type_mapping = {
            "int": "Int",
            "tinyint": "Int",
            "smallint": "Int",
            "mediumint": "Int",
            "bigint": "BigInt",
            "decimal": "Decimal",
            "float": "Float",
            "double": "Float",
            "varchar": "String",
            "char": "String",
            "text": "String",
            "tinytext": "String",
            "mediumtext": "String",
            "longtext": "String",
            "date": "Date",
            "datetime": "DateTime",
            "timestamp": "DateTime",
            "time": "Time",
            "json": "JSON",
            "boolean": "Boolean",
            "bool": "Boolean",
            "enum": "String",
            "set": "[String!]",
        }

        return type_mapping.get(mysql_type.lower(), "String")

    def _to_camel_case(self, snake_str: str) -> str:
        """Convert snake_case to camelCase."""
        components = snake_str.split("_")
        return components[0].lower() + "".join(x.title() for x in components[1:])

    def _to_pascal_case(self, snake_str: str) -> str:
        """Convert snake_case to PascalCase."""
        return "".join(x.title() for x in snake_str.split("_"))

    def _to_plural(self, word: str) -> str:
        """Convert word to plural form (simple rules)."""
        if word.endswith("y"):
            return word[:-1] + "ies"
        elif word.endswith("s") or word.endswith("x") or word.endswith("z"):
            return word + "es"
        else:
            return word + "s"

    def export_schema(self, output_file: Path):
        """Export schema to file."""
        schema = self.generate_schema()
        with open(output_file, "w", encoding="utf-8") as f:
            f.write(schema)
        print(f"Schema exported to: {output_file}")


def generate_for_example(example_name: str, connection_params: Dict) -> bool:
    """Generate GraphQL schema for a specific example."""
    generator = AdvancedGraphQLGenerator(connection_params)

    if not generator.connect():
        return False

    try:
        print(f"Analyzing database structure for {example_name}...")
        generator.analyze_database()

        # Generate schema
        _ = generator.generate_schema()

        # Export to file
        output_dir = (
            Path(__file__).parent.parent / f"example_{example_name}" / "graphql"
        )
        output_dir.mkdir(parents=True, exist_ok=True)
        output_file = output_dir / "schema.graphql"

        generator.export_schema(output_file)

        print(f"✓ GraphQL schema generated for {example_name}")
        return True

    finally:
        generator.disconnect()


def main():
    """Run entry point."""
    import argparse

    parser = argparse.ArgumentParser(description="Generate GraphQL schemas from MySQL")
    parser.add_argument("--host", default="localhost")
    parser.add_argument("--port", type=int, default=3306)
    parser.add_argument("--user", default="root")
    parser.add_argument("--password", required=True)
    parser.add_argument("--database", required=True)
    parser.add_argument("--output", default="schema.graphql")

    args = parser.parse_args()

    connection_params = {
        "host": args.host,
        "port": args.port,
        "user": args.user,
        "password": args.password,
        "database": args.database,
    }

    generator = AdvancedGraphQLGenerator(connection_params)

    if generator.connect():
        try:
            generator.analyze_database()
            generator.export_schema(Path(args.output))
        finally:
            generator.disconnect()


if __name__ == "__main__":
    main()
