#!/usr/bin/env python3
"""
MySQL to MongoDB Schema Converter

Converts MySQL schemas to MongoDB document structures with:
- Denormalization strategies
- Embedded vs. referenced relationships
- Index recommendations
- Aggregation pipeline templates
"""

import re
import json
import argparse
from pathlib import Path
from typing import Dict, List, Optional, Any
from datetime import datetime


class MySQLToMongoDBConverter:
    """Convert MySQL schemas to MongoDB document designs"""

    def __init__(self):
        self.tables = {}
        self.relationships = []
        self.collections = {}
        self.indexes = {}
        self.aggregations = {}

    def parse_sql_file(self, sql_file: Path) -> bool:
        """Parse MySQL SQL file and extract schema information"""
        try:
            with open(sql_file, "r", encoding="utf-8") as f:
                content = f.read()

            # Clean content
            content = re.sub(r"--.*$", "", content, flags=re.MULTILINE)
            content = re.sub(r"/\*.*?\*/", "", content, flags=re.DOTALL)

            # Find CREATE TABLE statements
            table_pattern = r"CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?`?(\w+)`?\s*\((.*?)\)\s*(?:ENGINE|;)"
            matches = re.finditer(table_pattern, content, re.IGNORECASE | re.DOTALL)

            for match in matches:
                table_name = match.group(1)
                table_content = match.group(2)
                self._parse_table(table_name, table_content)

            # Analyze relationships to determine document structure
            self._analyze_relationships()

            return True
        except Exception as e:
            print(f"Error parsing SQL file: {e}")
            return False

    def _parse_table(self, table_name: str, content: str):
        """Parse a CREATE TABLE statement"""
        fields = []
        primary_keys = []
        foreign_keys = []
        indexes = []

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
                    self.relationships.append(
                        {
                            "from_table": table_name,
                            "from_field": fk_match.group(1),
                            "to_table": fk_match.group(2),
                            "to_field": fk_match.group(3),
                            "type": "many_to_one",
                        }
                    )
                continue

            # Check for INDEX
            if any(keyword in line.upper() for keyword in ["INDEX", "KEY", "UNIQUE"]):
                if "UNIQUE" in line.upper():
                    indexes.append({"type": "unique", "definition": line})
                else:
                    indexes.append({"type": "index", "definition": line})
                continue

            # Parse field definition
            field_match = re.match(r"`?(\w+)`?\s+(\S+)(?:\(([^)]+)\))?\s*(.*)", line)
            if field_match:
                field_name = field_match.group(1)
                field_type = field_match.group(2)
                field_size = field_match.group(3)
                field_modifiers = field_match.group(4) or ""

                fields.append(
                    {
                        "name": field_name,
                        "type": field_type,
                        "size": field_size,
                        "nullable": "NOT NULL" not in field_modifiers.upper(),
                        "auto_increment": "AUTO_INCREMENT" in field_modifiers.upper(),
                        "default": self._extract_default(field_modifiers),
                    }
                )

        self.tables[table_name] = {
            "fields": fields,
            "primary_keys": primary_keys,
            "foreign_keys": foreign_keys,
            "indexes": indexes,
        }

    def _extract_default(self, modifiers: str) -> Optional[str]:
        """Extract default value from field modifiers"""
        default_match = re.search(r"DEFAULT\s+'?([^']+)'?", modifiers, re.IGNORECASE)
        if default_match:
            return default_match.group(1)
        return None

    def _analyze_relationships(self):
        """Analyze relationships to determine embedding vs. referencing"""
        # Identify one-to-many and many-to-many relationships
        for rel in self.relationships:
            from_table = rel["from_table"]
            to_table = rel["to_table"]

            # Check for junction tables (many-to-many)
            if self._is_junction_table(from_table):
                # This is likely a many-to-many relationship
                rel["type"] = "many_to_many"
                rel["embed_strategy"] = (
                    "reference"  # Usually better to reference in M:N
                )
            else:
                # Check cardinality based on field names and patterns
                if rel["from_field"].endswith("_id"):
                    # Likely a foreign key reference
                    rel["embed_strategy"] = self._determine_embed_strategy(
                        from_table, to_table
                    )
                else:
                    # Default to reference for unknown patterns
                    rel["embed_strategy"] = "reference"

    def _is_junction_table(self, table_name: str) -> bool:
        """Determine if a table is a junction/bridge table"""
        table = self.tables.get(table_name, {})

        # Junction tables typically have:
        # 1. Two or more foreign keys
        # 2. Few additional fields
        # 3. Composite primary key

        fk_count = len(table.get("foreign_keys", []))
        field_count = len(table.get("fields", []))
        pk_count = len(table.get("primary_keys", []))

        return fk_count >= 2 and field_count <= fk_count + 2 and pk_count > 1

    def _determine_embed_strategy(self, from_table: str, to_table: str) -> str:
        """Determine whether to embed or reference related documents"""
        # Simple heuristics for embedding vs. referencing
        # In practice, this would consider:
        # - Size of related documents
        # - Access patterns
        # - Update frequency
        # - Cardinality

        # Common patterns for embedding
        embed_patterns = [
            ("order", "order_items"),  # Order items usually embedded in orders
            ("user", "address"),  # Addresses often embedded in user documents
            ("product", "review"),  # Reviews can be embedded if limited
            ("post", "comment"),  # Comments often embedded (with limits)
        ]

        for pattern in embed_patterns:
            if pattern[0] in to_table.lower() and pattern[1] in from_table.lower():
                return "embed"

        # Default to reference for most relationships
        return "reference"

    def generate_mongodb_schema(self) -> Dict[str, Any]:
        """Generate MongoDB schema from parsed MySQL tables"""
        schema = {
            "database": "converted_db",
            "collections": {},
            "indexes": {},
            "validation": {},
            "aggregations": {},
        }

        for table_name, table_info in self.tables.items():
            # Skip junction tables (they become arrays in MongoDB)
            if self._is_junction_table(table_name):
                continue

            # Create collection schema
            collection = self._create_collection_schema(table_name, table_info)
            schema["collections"][table_name] = collection

            # Create indexes
            indexes = self._create_indexes(table_name, table_info)
            schema["indexes"][table_name] = indexes

            # Create validation rules
            validation = self._create_validation(table_name, table_info)
            schema["validation"][table_name] = validation

            # Create aggregation pipelines
            aggregations = self._create_aggregations(table_name)
            if aggregations:
                schema["aggregations"][table_name] = aggregations

        return schema

    def _create_collection_schema(self, table_name: str, table_info: Dict) -> Dict:
        """Create MongoDB collection schema from MySQL table"""
        schema = {"name": table_name, "document": {}, "embedded": [], "references": []}

        # Convert fields to document structure
        for field in table_info["fields"]:
            field_name = field["name"]
            mongo_type = self._mysql_to_mongo_type(field["type"])

            # Skip if it's an auto-increment ID (use MongoDB ObjectId)
            if field["auto_increment"]:
                continue

            # Create field schema
            field_schema = {"type": mongo_type, "required": not field["nullable"]}

            if field["default"]:
                field_schema["default"] = field["default"]

            schema["document"][field_name] = field_schema

        # Add embedded relationships
        for rel in self.relationships:
            if rel["to_table"] == table_name and rel.get("embed_strategy") == "embed":
                embedded = {
                    "field": rel["from_table"] + "s",  # Pluralize
                    "type": "array",
                    "schema": rel["from_table"],
                }
                schema["embedded"].append(embedded)

            elif (
                rel["from_table"] == table_name
                and rel.get("embed_strategy") == "reference"
            ):
                reference = {
                    "field": rel["to_table"] + "_id",
                    "collection": rel["to_table"],
                    "type": "ObjectId",
                }
                schema["references"].append(reference)

        # Add timestamps
        schema["document"]["created_at"] = {"type": "Date", "default": "new Date()"}
        schema["document"]["updated_at"] = {"type": "Date", "default": "new Date()"}

        return schema

    def _mysql_to_mongo_type(self, mysql_type: str) -> str:
        """Convert MySQL type to MongoDB type"""
        mysql_type = mysql_type.upper()

        type_map = {
            # Numeric
            "TINYINT": "Number",
            "SMALLINT": "Number",
            "MEDIUMINT": "Number",
            "INT": "Number",
            "INTEGER": "Number",
            "BIGINT": "Number",
            "DECIMAL": "Decimal128",
            "FLOAT": "Number",
            "DOUBLE": "Number",
            # String
            "CHAR": "String",
            "VARCHAR": "String",
            "TEXT": "String",
            "TINYTEXT": "String",
            "MEDIUMTEXT": "String",
            "LONGTEXT": "String",
            # Binary
            "BINARY": "BinData",
            "VARBINARY": "BinData",
            "BLOB": "BinData",
            # Date/Time
            "DATE": "Date",
            "DATETIME": "Date",
            "TIMESTAMP": "Date",
            "TIME": "String",
            "YEAR": "Number",
            # Boolean
            "BOOLEAN": "Boolean",
            "BOOL": "Boolean",
            # JSON
            "JSON": "Object",
            # Enum
            "ENUM": "String",
            "SET": "Array",
        }

        for key, value in type_map.items():
            if mysql_type.startswith(key):
                return value

        return "String"  # Default

    def _create_indexes(self, table_name: str, table_info: Dict) -> List[Dict]:
        """Create MongoDB indexes from MySQL indexes"""
        indexes = []

        # Add index for primary key if it's not _id
        if table_info["primary_keys"] and table_info["primary_keys"][0] != "id":
            indexes.append(
                {
                    "name": f"{table_name}_pk",
                    "keys": {pk: 1 for pk in table_info["primary_keys"]},
                    "unique": True,
                }
            )

        # Add indexes for foreign keys
        for fk in table_info["foreign_keys"]:
            indexes.append(
                {"name": f"{table_name}_{fk['field']}_idx", "keys": {fk["field"]: 1}}
            )

        # Add other indexes
        for idx in table_info.get("indexes", []):
            if "UNIQUE" in idx.get("definition", "").upper():
                # Parse unique index
                indexes.append({"name": f"{table_name}_unique_idx", "unique": True})

        # Add text index for searchable fields
        text_fields = [
            f["name"]
            for f in table_info["fields"]
            if f["type"].upper() in ["TEXT", "VARCHAR"] and f.get("size", 0) != "255"
        ]
        if text_fields:
            indexes.append(
                {
                    "name": f"{table_name}_text",
                    "keys": {
                        field: "text" for field in text_fields[:3]
                    },  # Limit to 3 fields
                }
            )

        return indexes

    def _create_validation(self, table_name: str, table_info: Dict) -> Dict:
        """Create MongoDB validation rules"""
        required = []
        properties = {}

        for field in table_info["fields"]:
            if field["auto_increment"]:
                continue

            field_name = field["name"]
            mongo_type = self._mysql_to_mongo_type(field["type"])

            # Add to required if NOT NULL
            if not field["nullable"]:
                required.append(field_name)

            # Create property validation
            prop = {"bsonType": mongo_type.lower()}

            # Add string length validation
            if field["type"].upper() == "VARCHAR" and field["size"]:
                prop["maxLength"] = int(field["size"])

            # Add enum validation
            if field["type"].upper() == "ENUM":
                # Would need to parse enum values from original SQL
                prop["enum"] = []

            properties[field_name] = prop

        return {
            "$jsonSchema": {
                "bsonType": "object",
                "required": required,
                "properties": properties,
            }
        }

    def _create_aggregations(self, table_name: str) -> List[Dict]:
        """Create common aggregation pipeline templates"""
        aggregations = []

        # Check if this table has relationships that need lookup
        related_tables = [
            rel["to_table"]
            for rel in self.relationships
            if rel["from_table"] == table_name and rel["embed_strategy"] == "reference"
        ]

        if related_tables:
            # Create lookup aggregation
            pipeline = []
            for related in related_tables:
                pipeline.append(
                    {
                        "$lookup": {
                            "from": related,
                            "localField": f"{related}_id",
                            "foreignField": "_id",
                            "as": related,
                        }
                    }
                )
                pipeline.append(
                    {
                        "$unwind": {
                            "path": f"${related}",
                            "preserveNullAndEmptyArrays": True,
                        }
                    }
                )

            aggregations.append(
                {
                    "name": f"{table_name}_with_relations",
                    "description": f"Fetch {table_name} with related documents",
                    "pipeline": pipeline,
                }
            )

        # Add reporting aggregation if table has numeric fields
        numeric_fields = [
            f["name"]
            for f in self.tables[table_name]["fields"]
            if self._mysql_to_mongo_type(f["type"]) == "Number"
        ]

        if numeric_fields:
            aggregations.append(
                {
                    "name": f"{table_name}_summary",
                    "description": f"Summary statistics for {table_name}",
                    "pipeline": [
                        {
                            "$group": {
                                "_id": None,
                                "count": {"$sum": 1},
                                **{
                                    f"avg_{field}": {"$avg": f"${field}"}
                                    for field in numeric_fields[:3]
                                },
                                **{
                                    f"sum_{field}": {"$sum": f"${field}"}
                                    for field in numeric_fields[:3]
                                },
                            }
                        }
                    ],
                }
            )

        return aggregations

    def generate_migration_script(self) -> str:
        """Generate MongoDB migration script"""
        # Get schema first
        schema = self.generate_mongodb_schema()

        script = []

        # Header
        script.append("// MongoDB Migration Script")
        script.append(f"// Generated: {datetime.now().isoformat()}")
        script.append("// From MySQL to MongoDB\n")

        # Use database
        script.append("use converted_db;\n")

        # Create collections
        for collection_name in schema["collections"]:
            script.append(f"// Create collection: {collection_name}")
            script.append(f"db.createCollection('{collection_name}');\n")

        # Create indexes
        for collection_name, indexes in schema["indexes"].items():
            if indexes:
                script.append(f"// Indexes for {collection_name}")
                for index in indexes:
                    if "keys" in index:
                        keys = json.dumps(index["keys"])
                        options = {}
                        if index.get("unique"):
                            options["unique"] = True
                        if index.get("name"):
                            options["name"] = index["name"]

                        script.append(
                            f"db.{collection_name}.createIndex({keys}, {json.dumps(options)});"
                        )
                script.append("")

        # Add validation
        for collection_name, validation in schema["validation"].items():
            script.append(f"// Validation for {collection_name}")
            script.append(f"db.runCommand({{")
            script.append(f"  collMod: '{collection_name}',")
            script.append(f"  validator: {json.dumps(validation, indent=2)}")
            script.append("});\n")

        return "\n".join(script)


def convert_example(example_dir: Path, output_dir: Path = None) -> bool:
    """Convert MySQL schema to MongoDB for an example"""
    print(f"Converting {example_dir.name} to MongoDB...")

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
        output_dir = example_dir / "schema_mongodb"
    output_dir.mkdir(exist_ok=True)

    converter = MySQLToMongoDBConverter()

    # Parse all SQL files
    for sql_file in sql_files:
        converter.parse_sql_file(sql_file)

    # Generate MongoDB schema
    mongodb_schema = converter.generate_mongodb_schema()

    # Save schema as JSON
    schema_file = output_dir / "mongodb_schema.json"
    with open(schema_file, "w", encoding="utf-8") as f:
        json.dump(mongodb_schema, f, indent=2)
    print(f"  Generated: {schema_file.name}")

    # Generate migration script
    migration_script = converter.generate_migration_script()
    script_file = output_dir / "migration.js"
    with open(script_file, "w", encoding="utf-8") as f:
        f.write(migration_script)
    print(f"  Generated: {script_file.name}")

    # Generate documentation
    doc_file = output_dir / "README.md"
    with open(doc_file, "w", encoding="utf-8") as f:
        f.write(f"# MongoDB Schema for {example_dir.name}\n\n")
        f.write(f"Converted from MySQL on {datetime.now().isoformat()}\n\n")
        f.write(f"## Collections\n\n")
        for collection, schema in mongodb_schema["collections"].items():
            f.write(f"### {collection}\n\n")
            f.write(f"**Document Structure:**\n")
            f.write("```json\n")
            f.write(json.dumps(schema["document"], indent=2))
            f.write("\n```\n\n")
            if schema["embedded"]:
                f.write(
                    f"**Embedded Documents:** {', '.join([e['field'] for e in schema['embedded']])}\n\n"
                )
            if schema["references"]:
                f.write(
                    f"**References:** {', '.join([r['field'] for r in schema['references']])}\n\n"
                )
    print(f"  Generated: {doc_file.name}")

    print(f"  Tables converted: {len(converter.tables)}")
    print(f"  Collections created: {len(mongodb_schema['collections'])}")

    return True


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description="Convert MySQL schemas to MongoDB")
    parser.add_argument(
        "input", nargs="?", help="Input MySQL SQL file or example directory"
    )
    parser.add_argument("--output", help="Output directory")
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

        print("MySQL to MongoDB Converter")
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
        convert_example(input_path, Path(args.output) if args.output else None)


if __name__ == "__main__":
    main()
