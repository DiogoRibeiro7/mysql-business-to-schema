#!/usr/bin/env python3
"""
Migration System Test Suite
Tests the migration system with all database examples
"""

import os
import sys
import json
import tempfile
import shutil
from pathlib import Path
from datetime import datetime
import logging

# Add parent directory to path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from migration_system.migration_manager import (
    MigrationManager,
    DatabaseType,
    DataTypeMapper,
    SchemaParser,
)

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


class MigrationTester:
    """Test suite for database migration system"""

    def __init__(self):
        self.test_results = []
        self.examples_dir = Path("../")
        self.temp_dir = None
        self.manager = None

    def setup(self):
        """Set up test environment"""
        # Create temporary directory for test migrations
        self.temp_dir = tempfile.mkdtemp(prefix="migration_test_")
        self.manager = MigrationManager(os.path.join(self.temp_dir, "migrations"))
        logger.info(f"Test environment created at: {self.temp_dir}")

    def teardown(self):
        """Clean up test environment"""
        if self.temp_dir and os.path.exists(self.temp_dir):
            shutil.rmtree(self.temp_dir)
            logger.info("Test environment cleaned up")

    def find_examples(self):
        """Find all database examples"""
        examples = []
        for item in os.listdir(self.examples_dir):
            if item.startswith("example_") and os.path.isdir(self.examples_dir / item):
                schema_dir = self.examples_dir / item / "schema"
                if schema_dir.exists():
                    # Look for main tables file
                    tables_file = schema_dir / "01_tables.sql"
                    if tables_file.exists():
                        examples.append(
                            {
                                "name": item,
                                "path": tables_file,
                                "dir": self.examples_dir / item,
                            }
                        )
        return examples

    def test_mysql_to_postgresql(self, example):
        """Test MySQL to PostgreSQL migration"""
        test_name = f"MySQL->PostgreSQL: {example['name']}"
        logger.info(f"Testing {test_name}")

        try:
            # Create migration
            migration = self.manager.create_migration(
                name=f"{example['name']}_to_postgres",
                source_file=str(example["path"]),
                source_type=DatabaseType.MYSQL,
                target_type=DatabaseType.POSTGRESQL,
            )

            # Validate migration was created
            assert migration is not None, "Migration creation failed"
            assert migration.up_script, "Up script is empty"
            assert migration.down_script, "Down script is empty"

            # Check for PostgreSQL specific syntax
            assert "CREATE TABLE" in migration.up_script
            assert "SERIAL" in migration.up_script or "INTEGER" in migration.up_script
            assert "DROP TABLE" in migration.down_script

            # Validate data type mappings
            if "DATETIME" in open(example["path"]).read():
                assert (
                    "TIMESTAMP" in migration.up_script
                ), "DATETIME not converted to TIMESTAMP"

            if "TINYINT" in open(example["path"]).read().upper():
                assert (
                    "SMALLINT" in migration.up_script
                ), "TINYINT not converted to SMALLINT"

            # Check files were created
            up_file = Path(self.temp_dir) / "migrations" / "up" / f"{migration.id}.sql"
            down_file = (
                Path(self.temp_dir)
                / "migrations"
                / "down"
                / f"{migration.id}_rollback.sql"
            )
            assert up_file.exists(), "Up migration file not created"
            assert down_file.exists(), "Down migration file not created"

            self.test_results.append(
                {
                    "test": test_name,
                    "status": "PASSED",
                    "details": f"Migration created: {migration.id}",
                }
            )
            logger.info(f"✓ {test_name} - PASSED")

        except Exception as e:
            self.test_results.append(
                {"test": test_name, "status": "FAILED", "error": str(e)}
            )
            logger.error(f"✗ {test_name} - FAILED: {e}")

    def test_mysql_to_mongodb(self, example):
        """Test MySQL to MongoDB migration"""
        test_name = f"MySQL->MongoDB: {example['name']}"
        logger.info(f"Testing {test_name}")

        try:
            # Create migration
            migration = self.manager.create_migration(
                name=f"{example['name']}_to_mongo",
                source_file=str(example["path"]),
                source_type=DatabaseType.MYSQL,
                target_type=DatabaseType.MONGODB,
            )

            # Validate migration was created
            assert migration is not None, "Migration creation failed"
            assert migration.up_script, "Up script is empty"
            assert migration.down_script, "Down script is empty"

            # Check for MongoDB specific syntax
            assert "db.createCollection" in migration.up_script
            assert (
                "db.runCommand" in migration.up_script
                or "createIndex" in migration.up_script
            )
            assert ".drop()" in migration.down_script

            # Validate JSON schema validation
            assert (
                "$jsonSchema" in migration.up_script
                or "validator" in migration.up_script
            )

            self.test_results.append(
                {
                    "test": test_name,
                    "status": "PASSED",
                    "details": f"Migration created: {migration.id}",
                }
            )
            logger.info(f"✓ {test_name} - PASSED")

        except Exception as e:
            self.test_results.append(
                {"test": test_name, "status": "FAILED", "error": str(e)}
            )
            logger.error(f"✗ {test_name} - FAILED: {e}")

    def test_data_type_mapping(self):
        """Test data type mapping functionality"""
        test_name = "Data Type Mapping"
        logger.info(f"Testing {test_name}")

        try:
            mapper = DataTypeMapper()

            # Test MySQL to PostgreSQL mappings
            mappings_pg = {
                "VARCHAR(255)": "VARCHAR",
                "INT": "INTEGER",
                "DATETIME": "TIMESTAMP",
                "TEXT": "TEXT",
                "DECIMAL(10,2)": "DECIMAL",
                "JSON": "JSONB",
                "BOOLEAN": "BOOLEAN",
                "BIGINT UNSIGNED": "NUMERIC(20)",
            }

            for mysql_type, expected_pg in mappings_pg.items():
                result = mapper.map_type(
                    mysql_type, DatabaseType.MYSQL, DatabaseType.POSTGRESQL
                )
                # Check if the base type matches (ignoring length specifications)
                base_result = result.split("(")[0]
                base_expected = expected_pg.split("(")[0]
                assert (
                    base_result == base_expected
                ), f"Failed mapping {mysql_type} -> {expected_pg}, got {result}"

            # Test MySQL to MongoDB mappings
            mappings_mongo = {
                "VARCHAR": "String",
                "INT": "Int32",
                "BIGINT": "Long",
                "DECIMAL": "Decimal128",
                "DATETIME": "Date",
                "JSON": "Object",
                "BOOLEAN": "Boolean",
            }

            for mysql_type, expected_mongo in mappings_mongo.items():
                result = mapper.map_type(
                    mysql_type, DatabaseType.MYSQL, DatabaseType.MONGODB
                )
                assert (
                    result == expected_mongo
                ), f"Failed mapping {mysql_type} -> {expected_mongo}, got {result}"

            self.test_results.append(
                {
                    "test": test_name,
                    "status": "PASSED",
                    "details": "All data type mappings correct",
                }
            )
            logger.info(f"✓ {test_name} - PASSED")

        except Exception as e:
            self.test_results.append(
                {"test": test_name, "status": "FAILED", "error": str(e)}
            )
            logger.error(f"✗ {test_name} - FAILED: {e}")

    def test_schema_parser(self, example):
        """Test schema parsing functionality"""
        test_name = f"Schema Parser: {example['name']}"
        logger.info(f"Testing {test_name}")

        try:
            parser = SchemaParser()

            # Read schema file
            with open(example["path"], "r", encoding="utf-8") as f:
                sql_content = f.read()

            # Parse schema
            tables = parser.parse_mysql_schema(sql_content)

            # Validate parsing
            assert len(tables) > 0, "No tables parsed"

            for table in tables:
                assert table.name, "Table has no name"
                assert len(table.columns) > 0, f"Table {table.name} has no columns"

                # Check for at least one column with properties
                has_typed_column = any(col.data_type for col in table.columns)
                assert (
                    has_typed_column
                ), f"Table {table.name} columns have no data types"

            self.test_results.append(
                {
                    "test": test_name,
                    "status": "PASSED",
                    "details": f"Parsed {len(tables)} tables successfully",
                }
            )
            logger.info(f"✓ {test_name} - PASSED: {len(tables)} tables")

        except Exception as e:
            self.test_results.append(
                {"test": test_name, "status": "FAILED", "error": str(e)}
            )
            logger.error(f"✗ {test_name} - FAILED: {e}")

    def test_migration_metadata(self):
        """Test migration metadata and listing"""
        test_name = "Migration Metadata"
        logger.info(f"Testing {test_name}")

        try:
            # Create a test migration
            test_sql = """
            CREATE TABLE test_table (
                id INT PRIMARY KEY AUTO_INCREMENT,
                name VARCHAR(100),
                created_at DATETIME
            );
            """

            # Create temporary SQL file
            test_file = os.path.join(self.temp_dir, "test.sql")
            with open(test_file, "w") as f:
                f.write(test_sql)

            # Create migration
            migration = self.manager.create_migration(
                name="test_metadata",
                source_file=test_file,
                source_type=DatabaseType.MYSQL,
                target_type=DatabaseType.POSTGRESQL,
            )

            # List migrations
            migrations = self.manager.list_migrations()
            assert len(migrations) > 0, "No migrations found in list"

            # Find our test migration
            found = False
            for m in migrations:
                if m["name"] == "test_metadata":
                    found = True
                    assert m["source_type"] == "mysql"
                    assert m["target_type"] == "postgresql"
                    assert m["status"] == "pending"
                    assert "checksum" in m
                    break

            assert found, "Test migration not found in list"

            # Get migration status
            status = self.manager.get_migration_status(migration.id)
            assert status is not None, "Could not get migration status"

            self.test_results.append(
                {
                    "test": test_name,
                    "status": "PASSED",
                    "details": "Metadata operations working correctly",
                }
            )
            logger.info(f"✓ {test_name} - PASSED")

        except Exception as e:
            self.test_results.append(
                {"test": test_name, "status": "FAILED", "error": str(e)}
            )
            logger.error(f"✗ {test_name} - FAILED: {e}")

    def test_complex_schema_features(self):
        """Test migration of complex schema features"""
        test_name = "Complex Schema Features"
        logger.info(f"Testing {test_name}")

        try:
            # Create a complex schema with various features
            complex_sql = """
            CREATE TABLE users (
                id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                email VARCHAR(255) NOT NULL UNIQUE,
                settings JSON,
                location POINT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_email (email),
                FULLTEXT idx_search (email)
            );

            CREATE TABLE posts (
                id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                user_id BIGINT UNSIGNED NOT NULL,
                title VARCHAR(200) NOT NULL,
                content TEXT,
                tags SET('tech', 'news', 'tutorial'),
                status ENUM('draft', 'published', 'archived'),
                published_at DATETIME,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
                INDEX idx_user_status (user_id, status)
            );
            """

            # Create temporary SQL file
            test_file = os.path.join(self.temp_dir, "complex.sql")
            with open(test_file, "w") as f:
                f.write(complex_sql)

            # Test PostgreSQL migration
            pg_migration = self.manager.create_migration(
                name="complex_to_postgres",
                source_file=test_file,
                source_type=DatabaseType.MYSQL,
                target_type=DatabaseType.POSTGRESQL,
            )

            # Check PostgreSQL features
            assert "JSONB" in pg_migration.up_script, "JSON not converted to JSONB"
            assert (
                "CREATE" in pg_migration.up_script and "INDEX" in pg_migration.up_script
            )
            assert "FOREIGN KEY" in pg_migration.up_script

            # Test MongoDB migration
            mongo_migration = self.manager.create_migration(
                name="complex_to_mongo",
                source_file=test_file,
                source_type=DatabaseType.MYSQL,
                target_type=DatabaseType.MONGODB,
            )

            # Check MongoDB features
            assert "createCollection" in mongo_migration.up_script
            assert "createIndex" in mongo_migration.up_script
            assert (
                "validator" in mongo_migration.up_script
                or "$jsonSchema" in mongo_migration.up_script
            )

            self.test_results.append(
                {
                    "test": test_name,
                    "status": "PASSED",
                    "details": "Complex features migrated successfully",
                }
            )
            logger.info(f"✓ {test_name} - PASSED")

        except Exception as e:
            self.test_results.append(
                {"test": test_name, "status": "FAILED", "error": str(e)}
            )
            logger.error(f"✗ {test_name} - FAILED: {e}")

    def run_all_tests(self):
        """Run all migration tests"""
        logger.info("=" * 60)
        logger.info("MIGRATION SYSTEM TEST SUITE")
        logger.info("=" * 60)

        # Setup
        self.setup()

        try:
            # Find examples
            examples = self.find_examples()
            logger.info(f"Found {len(examples)} examples to test")

            # Test core functionality
            self.test_data_type_mapping()
            self.test_migration_metadata()
            self.test_complex_schema_features()

            # Test with first 3 examples for each migration type
            test_examples = examples[:3] if len(examples) >= 3 else examples

            for example in test_examples:
                # Test schema parsing
                self.test_schema_parser(example)

                # Test PostgreSQL migration
                self.test_mysql_to_postgresql(example)

                # Test MongoDB migration
                self.test_mysql_to_mongodb(example)

        finally:
            # Teardown
            self.teardown()

        # Print summary
        self.print_summary()

    def print_summary(self):
        """Print test results summary"""
        logger.info("\n" + "=" * 60)
        logger.info("TEST RESULTS SUMMARY")
        logger.info("=" * 60)

        passed = sum(1 for r in self.test_results if r["status"] == "PASSED")
        failed = sum(1 for r in self.test_results if r["status"] == "FAILED")
        total = len(self.test_results)

        # Print individual results
        for result in self.test_results:
            status_symbol = "✓" if result["status"] == "PASSED" else "✗"
            logger.info(f"{status_symbol} {result['test']}: {result['status']}")
            if result["status"] == "FAILED" and "error" in result:
                logger.info(f"  Error: {result.get('error', 'Unknown error')}")

        # Print summary statistics
        logger.info("-" * 60)
        logger.info(f"Total Tests: {total}")
        logger.info(f"Passed: {passed} ({passed/total*100:.1f}%)")
        logger.info(f"Failed: {failed} ({failed/total*100:.1f}%)")

        # Save results to file
        results_file = "migration_test_results.json"
        with open(results_file, "w") as f:
            json.dump(
                {
                    "timestamp": datetime.now().isoformat(),
                    "summary": {
                        "total": total,
                        "passed": passed,
                        "failed": failed,
                        "success_rate": f"{passed/total*100:.1f}%",
                    },
                    "results": self.test_results,
                },
                f,
                indent=2,
            )

        logger.info(f"\nDetailed results saved to: {results_file}")

        # Return success/failure
        return failed == 0


def main():
    """Run migration system tests"""
    tester = MigrationTester()
    success = tester.run_all_tests()

    # Exit with appropriate code
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
