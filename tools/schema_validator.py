#!/usr/bin/env python3
"""Schema Validator.

Validates database schemas for:
- Naming conventions
- Data type consistency
- Normalization rules
- Best practices
- Anti-patterns
"""

import argparse
import json
import re
from typing import Dict
import mysql.connector
from mysql.connector import Error


class SchemaValidator:
    """Validate database schemas against best practices."""

    def __init__(self, host="localhost", port=3306, user="root", password=""):
        """Initialize the instance."""
        self.host = host
        self.port = port
        self.user = user
        self.password = password
        self.connection = None
        self.issues = []
        self.warnings = []
        self.suggestions = []

    def connect(self, database: str) -> bool:
        """Connect to database."""
        try:
            if self.connection:
                self.connection.close()

            self.connection = mysql.connector.connect(
                host=self.host,
                port=self.port,
                user=self.user,
                password=self.password,
                database=database,
            )
            return True
        except Error as e:
            print(f"Connection error: {e}")
            return False

    def validate_schema(self, database: str) -> Dict:
        """Run all validation checks on a schema."""
        if not self.connect(database):
            return {"error": f"Cannot connect to database {database}"}

        self.issues = []
        self.warnings = []
        self.suggestions = []

        # Run validation checks
        self.check_naming_conventions(database)
        self.check_data_types(database)
        self.check_indexes(database)
        self.check_foreign_keys(database)
        self.check_normalization(database)
        self.check_best_practices(database)
        self.check_anti_patterns(database)

        return {
            "database": database,
            "issues": self.issues,
            "warnings": self.warnings,
            "suggestions": self.suggestions,
            "score": self.calculate_score(),
        }

    def check_naming_conventions(self, database: str):
        """Check naming conventions."""
        cursor = self.connection.cursor(dictionary=True)

        # Check table names
        cursor.execute("SHOW TABLES")
        tables = cursor.fetchall()

        for table_row in tables:
            table_name = list(table_row.values())[0]

            # Check for snake_case
            if not re.match(r"^[a-z][a-z0-9_]*$", table_name):
                self.warnings.append(
                    {
                        "type": "naming",
                        "object": f"table:{table_name}",
                        "message": "Table name should be snake_case",
                    }
                )

            # Check for reserved words
            if table_name.upper() in ["USER", "ORDER", "GROUP", "TABLE", "INDEX"]:
                self.warnings.append(
                    {
                        "type": "naming",
                        "object": f"table:{table_name}",
                        "message": "Table name might conflict with reserved word",
                    }
                )

            # Check column names
            cursor.execute(f"SHOW COLUMNS FROM {table_name}")
            columns = cursor.fetchall()

            for column in columns:
                col_name = column["Field"]

                # Snake case check
                if not re.match(r"^[a-z][a-z0-9_]*$", col_name):
                    self.warnings.append(
                        {
                            "type": "naming",
                            "object": f"{table_name}.{col_name}",
                            "message": "Column name should be snake_case",
                        }
                    )

                # Common naming patterns
                if col_name.endswith("_id") and not column["Key"]:
                    self.suggestions.append(
                        {
                            "type": "naming",
                            "object": f"{table_name}.{col_name}",
                            "message": "Column ending with _id might need an index",
                        }
                    )

        cursor.close()

    def check_data_types(self, database: str):
        """Check data type consistency and best practices."""
        cursor = self.connection.cursor(dictionary=True)

        # Get all columns
        query = """
        SELECT
            TABLE_NAME,
            COLUMN_NAME,
            DATA_TYPE,
            CHARACTER_MAXIMUM_LENGTH,
            IS_NULLABLE,
            COLUMN_DEFAULT
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = %s
        """

        cursor.execute(query, (database,))
        columns = cursor.fetchall()

        # Check for consistency
        type_usage = {}
        for col in columns:
            col_name = col["COLUMN_NAME"]
            data_type = col["DATA_TYPE"]

            # Track type usage for similar column names
            if col_name not in type_usage:
                type_usage[col_name] = []
            type_usage[col_name].append(
                {
                    "table": col["TABLE_NAME"],
                    "type": data_type,
                    "length": col["CHARACTER_MAXIMUM_LENGTH"],
                }
            )

            # Check for deprecated types
            if data_type in ["TINYTEXT", "MEDIUMTEXT"]:
                self.warnings.append(
                    {
                        "type": "datatype",
                        "object": f"{col['TABLE_NAME']}.{col_name}",
                        "message": f"Consider using VARCHAR or TEXT instead of {data_type}",
                    }
                )

            # Check for missing defaults on NOT NULL columns
            if col["IS_NULLABLE"] == "NO" and col["COLUMN_DEFAULT"] is None:
                if (
                    col_name not in ["id", "created_at", "updated_at"]
                    and "_id" not in col_name
                ):
                    self.suggestions.append(
                        {
                            "type": "datatype",
                            "object": f"{col['TABLE_NAME']}.{col_name}",
                            "message": "NOT NULL column without default value",
                        }
                    )

        # Check for inconsistent types for same column names
        for col_name, usages in type_usage.items():
            if len(usages) > 1:
                types = {(u["type"], u["length"]) for u in usages}
                if len(types) > 1:
                    tables = ", ".join(u["table"] for u in usages)
                    self.warnings.append(
                        {
                            "type": "datatype",
                            "object": col_name,
                            "message": f"Inconsistent data types across tables: {tables}",
                        }
                    )

        cursor.close()

    def check_indexes(self, database: str):
        """Check index configuration."""
        cursor = self.connection.cursor(dictionary=True)

        # Get all indexes
        query = """
        SELECT
            TABLE_NAME,
            INDEX_NAME,
            NON_UNIQUE,
            GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) AS columns
        FROM INFORMATION_SCHEMA.STATISTICS
        WHERE TABLE_SCHEMA = %s
        GROUP BY TABLE_NAME, INDEX_NAME, NON_UNIQUE
        """

        cursor.execute(query, (database,))
        indexes = cursor.fetchall()

        # Check for duplicate indexes
        index_signatures = {}
        for idx in indexes:
            signature = f"{idx['TABLE_NAME']}:{idx['columns']}"
            if signature not in index_signatures:
                index_signatures[signature] = []
            index_signatures[signature].append(idx["INDEX_NAME"])

        for signature, index_names in index_signatures.items():
            if len(index_names) > 1:
                self.warnings.append(
                    {
                        "type": "index",
                        "object": signature,
                        "message": f'Duplicate indexes: {", ".join(index_names)}',
                    }
                )

        # Check for missing indexes on foreign keys
        fk_query = """
        SELECT DISTINCT
            TABLE_NAME,
            COLUMN_NAME
        FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
        WHERE TABLE_SCHEMA = %s
          AND REFERENCED_TABLE_NAME IS NOT NULL
        """

        cursor.execute(fk_query, (database,))
        foreign_keys = cursor.fetchall()

        for fk in foreign_keys:
            # Check if there's an index starting with this column
            has_index = False
            for idx in indexes:
                if idx["TABLE_NAME"] == fk["TABLE_NAME"] and idx["columns"].startswith(
                    fk["COLUMN_NAME"]
                ):
                    has_index = True
                    break

            if not has_index:
                self.issues.append(
                    {
                        "type": "index",
                        "object": f"{fk['TABLE_NAME']}.{fk['COLUMN_NAME']}",
                        "message": "Foreign key without index",
                    }
                )

        cursor.close()

    def check_foreign_keys(self, database: str):
        """Check foreign key integrity."""
        cursor = self.connection.cursor(dictionary=True)

        # Get all foreign keys
        query = """
        SELECT
            TABLE_NAME,
            COLUMN_NAME,
            REFERENCED_TABLE_NAME,
            REFERENCED_COLUMN_NAME
        FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
        WHERE TABLE_SCHEMA = %s
          AND REFERENCED_TABLE_NAME IS NOT NULL
        """

        cursor.execute(query, (database,))
        foreign_keys = cursor.fetchall()

        # Check for orphaned foreign keys
        for fk in foreign_keys:
            # Check if referenced table exists
            cursor.execute(f"SHOW TABLES LIKE '{fk['REFERENCED_TABLE_NAME']}'")
            if not cursor.fetchall():
                self.issues.append(
                    {
                        "type": "foreign_key",
                        "object": f"{fk['TABLE_NAME']}.{fk['COLUMN_NAME']}",
                        "message": f"References non-existent table {fk['REFERENCED_TABLE_NAME']}",
                    }
                )

        # Check for missing foreign keys (columns ending with _id)
        cursor.execute("SHOW TABLES")
        tables = cursor.fetchall()

        for table_row in tables:
            table_name = list(table_row.values())[0]
            cursor.execute(f"SHOW COLUMNS FROM {table_name}")
            columns = cursor.fetchall()

            for column in columns:
                col_name = column["Field"]
                if col_name.endswith("_id") and col_name != "id":
                    # Check if it has a foreign key
                    has_fk = any(
                        fk["TABLE_NAME"] == table_name and fk["COLUMN_NAME"] == col_name
                        for fk in foreign_keys
                    )

                    if not has_fk:
                        self.suggestions.append(
                            {
                                "type": "foreign_key",
                                "object": f"{table_name}.{col_name}",
                                "message": "Column ending with _id might need a foreign key",
                            }
                        )

        cursor.close()

    def check_normalization(self, database: str):
        """Check for normalization issues."""
        cursor = self.connection.cursor(dictionary=True)

        # Check for potential denormalization issues
        cursor.execute("SHOW TABLES")
        tables = cursor.fetchall()

        for table_row in tables:
            table_name = list(table_row.values())[0]
            cursor.execute(f"SHOW COLUMNS FROM {table_name}")
            columns = cursor.fetchall()

            # Check for repeating column patterns (column1, column2, column3)
            column_names = [col["Field"] for col in columns]
            for i in range(len(column_names) - 1):
                base_name = re.sub(r"\d+$", "", column_names[i])
                if base_name and any(
                    re.match(f"^{re.escape(base_name)}\\d+$", column_names[j])
                    for j in range(i + 1, len(column_names))
                ):
                    self.warnings.append(
                        {
                            "type": "normalization",
                            "object": table_name,
                            "message": f"Repeating columns pattern ({base_name}N) suggests denormalization",
                        }
                    )
                    break

            # Check for CSV or JSON columns that might need normalization
            for column in columns:
                if column["Type"].upper() in ["JSON", "TEXT", "LONGTEXT"]:
                    col_name = column["Field"]
                    if any(
                        word in col_name.lower()
                        for word in ["list", "items", "tags", "categories"]
                    ):
                        self.suggestions.append(
                            {
                                "type": "normalization",
                                "object": f"{table_name}.{col_name}",
                                "message": "Consider normalizing to separate table",
                            }
                        )

        cursor.close()

    def check_best_practices(self, database: str):
        """Check for best practices."""
        cursor = self.connection.cursor(dictionary=True)

        cursor.execute("SHOW TABLES")
        tables = cursor.fetchall()

        for table_row in tables:
            table_name = list(table_row.values())[0]

            # Check for primary key
            cursor.execute(f"SHOW KEYS FROM {table_name} WHERE Key_name = 'PRIMARY'")
            if not cursor.fetchall():
                self.issues.append(
                    {
                        "type": "best_practice",
                        "object": table_name,
                        "message": "Table without primary key",
                    }
                )

            # Check for timestamp columns
            cursor.execute(f"SHOW COLUMNS FROM {table_name}")
            columns = cursor.fetchall()
            column_names = [col["Field"] for col in columns]

            if "created_at" not in column_names:
                self.suggestions.append(
                    {
                        "type": "best_practice",
                        "object": table_name,
                        "message": "Consider adding created_at timestamp",
                    }
                )

            if "updated_at" not in column_names:
                self.suggestions.append(
                    {
                        "type": "best_practice",
                        "object": table_name,
                        "message": "Consider adding updated_at timestamp",
                    }
                )

            # Check for proper UTF-8 support
            cursor.execute(
                f"""
                SELECT CCSA.character_set_name
                FROM information_schema.TABLES T
                JOIN information_schema.COLLATION_CHARACTER_SET_APPLICABILITY CCSA
                    ON CCSA.collation_name = T.table_collation
                WHERE T.table_schema = '{database}'
                  AND T.table_name = '{table_name}'
            """
            )
            charset = cursor.fetchone()
            charset_name = None
            if charset:
                if "character_set_name" in charset:
                    charset_name = charset["character_set_name"]
                else:
                    # Fallback for drivers returning non-standard dict keys
                    charset_name = next(iter(charset.values()), None)
            if charset_name and charset_name != "utf8mb4":
                self.warnings.append(
                    {
                        "type": "best_practice",
                        "object": table_name,
                        "message": "Consider using utf8mb4 for full Unicode support",
                    }
                )

        cursor.close()

    def check_anti_patterns(self, database: str):
        """Check for common anti-patterns."""
        cursor = self.connection.cursor(dictionary=True)

        # Check for EAV (Entity-Attribute-Value) pattern
        cursor.execute("SHOW TABLES")
        tables = cursor.fetchall()

        for table_row in tables:
            table_name = list(table_row.values())[0]

            # EAV pattern detection
            if any(
                word in table_name.lower() for word in ["attribute", "property", "meta"]
            ):
                cursor.execute(f"SHOW COLUMNS FROM {table_name}")
                columns = cursor.fetchall()
                column_names = [col["Field"].lower() for col in columns]

                if all(
                    name in column_names for name in ["entity", "attribute", "value"]
                ) or all(name in column_names for name in ["key", "value"]):
                    self.warnings.append(
                        {
                            "type": "anti_pattern",
                            "object": table_name,
                            "message": "Possible EAV anti-pattern detected",
                        }
                    )

            # Check for overly wide tables
            cursor.execute(f"SHOW COLUMNS FROM {table_name}")
            columns = cursor.fetchall()
            if len(columns) > 30:
                self.warnings.append(
                    {
                        "type": "anti_pattern",
                        "object": table_name,
                        "message": f"Very wide table ({len(columns)} columns) - consider splitting",
                    }
                )

            # Check for storing calculations
            for column in columns:
                col_name = column["Field"].lower()
                if any(
                    word in col_name
                    for word in ["total", "sum", "count", "avg", "calculated"]
                ):
                    self.suggestions.append(
                        {
                            "type": "anti_pattern",
                            "object": f'{table_name}.{column["Field"]}',
                            "message": "Possibly storing calculated value - consider computing on demand",
                        }
                    )

        cursor.close()

    def calculate_score(self) -> int:
        """Calculate schema quality score."""
        score = 100

        # Deduct points for issues
        score -= len(self.issues) * 10
        score -= len(self.warnings) * 5
        score -= len(self.suggestions) * 2

        return max(0, score)

    def generate_report(self, validation_results: Dict) -> str:
        """Generate validation report."""
        lines = []
        lines.append("=" * 80)
        lines.append(f"SCHEMA VALIDATION REPORT - {validation_results['database']}")
        lines.append("=" * 80)

        lines.append(f"\nQuality Score: {validation_results['score']}/100")

        if validation_results["score"] >= 90:
            lines.append("Grade: A - Excellent schema design")
        elif validation_results["score"] >= 80:
            lines.append("Grade: B - Good schema with minor issues")
        elif validation_results["score"] >= 70:
            lines.append("Grade: C - Acceptable but needs improvement")
        elif validation_results["score"] >= 60:
            lines.append("Grade: D - Significant issues to address")
        else:
            lines.append("Grade: F - Major redesign recommended")

        # Critical issues
        if validation_results["issues"]:
            lines.append("\n❌ CRITICAL ISSUES")
            lines.append("-" * 40)
            for issue in validation_results["issues"]:
                lines.append(
                    f"  • [{issue['type']}] {issue['object']}: {issue['message']}"
                )

        # Warnings
        if validation_results["warnings"]:
            lines.append("\n⚠️  WARNINGS")
            lines.append("-" * 40)
            for warning in validation_results["warnings"]:
                lines.append(
                    f"  • [{warning['type']}] {warning['object']}: {warning['message']}"
                )

        # Suggestions
        if validation_results["suggestions"]:
            lines.append("\n💡 SUGGESTIONS")
            lines.append("-" * 40)
            for suggestion in validation_results["suggestions"]:
                lines.append(
                    f"  • [{suggestion['type']}] {suggestion['object']}: {suggestion['message']}"
                )

        # Summary statistics
        lines.append("\nSUMMARY")
        lines.append("-" * 40)
        lines.append(f"Critical Issues: {len(validation_results['issues'])}")
        lines.append(f"Warnings: {len(validation_results['warnings'])}")
        lines.append(f"Suggestions: {len(validation_results['suggestions'])}")

        return "\n".join(lines)


def main():
    """Handle main."""
    parser = argparse.ArgumentParser(description="Schema Validator")
    parser.add_argument("--host", default="localhost", help="MySQL host")
    parser.add_argument("--port", type=int, default=3306, help="MySQL port")
    parser.add_argument("--user", default="root", help="MySQL user")
    parser.add_argument("--password", default="", help="MySQL password")
    parser.add_argument("--database", required=True, help="Database to validate")
    parser.add_argument("--output", choices=["text", "json"], default="text")
    parser.add_argument("--save", help="Save report to file")

    args = parser.parse_args()

    validator = SchemaValidator(
        host=args.host, port=args.port, user=args.user, password=args.password
    )

    results = validator.validate_schema(args.database)

    if args.output == "json":
        report = json.dumps(results, indent=2)
    else:
        report = validator.generate_report(results)

    print(report)

    if args.save:
        with open(args.save, "w") as f:
            f.write(report)
        print(f"\nReport saved to: {args.save}")


if __name__ == "__main__":
    main()
