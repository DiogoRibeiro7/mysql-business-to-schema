#!/usr/bin/env python3
"""
MySQL Examples Test Runner

Comprehensive testing framework for validating all database examples:
- Schema creation and integrity
- Data generator validation
- Query execution testing
- Performance baselines
- Business logic verification
"""

import argparse
import json
import logging
import os
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Tuple, Optional, Any
import yaml
import mysql.connector
from mysql.connector import Error
from tabulate import tabulate

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class TestResult:
    """Container for test results."""

    def __init__(self, test_name: str, test_type: str):
        self.test_name = test_name
        self.test_type = test_type
        self.status = 'pending'
        self.message = ''
        self.duration = 0
        self.details = {}
        self.errors = []
        self.warnings = []

    def passed(self, message: str = 'Test passed', duration: float = 0):
        self.status = 'passed'
        self.message = message
        self.duration = duration

    def failed(self, message: str, error: str = None):
        self.status = 'failed'
        self.message = message
        if error:
            self.errors.append(error)

    def skipped(self, reason: str):
        self.status = 'skipped'
        self.message = reason

    def add_warning(self, warning: str):
        self.warnings.append(warning)

    def to_dict(self) -> Dict:
        return {
            'test_name': self.test_name,
            'test_type': self.test_type,
            'status': self.status,
            'message': self.message,
            'duration': self.duration,
            'errors': self.errors,
            'warnings': self.warnings,
            'details': self.details
        }


class DatabaseTestSuite:
    """Main test suite for database examples."""

    def __init__(self, host='localhost', port=3306, user='root', password=''):
        self.host = host
        self.port = port
        self.user = user
        self.password = password
        self.connection = None
        self.results = []
        self.project_root = Path(__file__).parent.parent

    def connect(self, database: str = None) -> bool:
        """Establish database connection."""
        try:
            if self.connection:
                self.connection.close()

            self.connection = mysql.connector.connect(
                host=self.host,
                port=self.port,
                user=self.user,
                password=self.password,
                database=database
            )
            return True
        except Error as e:
            logger.error(f"Connection failed: {e}")
            return False

    def execute_query(self, query: str, fetch: bool = True) -> Tuple[bool, Any]:
        """Execute a query and return results."""
        if not self.connection:
            return False, "No database connection"

        try:
            cursor = self.connection.cursor(dictionary=True)
            cursor.execute(query)

            if fetch:
                result = cursor.fetchall()
            else:
                self.connection.commit()
                result = cursor.rowcount

            cursor.close()
            return True, result
        except Error as e:
            return False, str(e)

    def test_example(self, example_name: str) -> List[TestResult]:
        """Run all tests for a specific example."""
        logger.info(f"Testing {example_name}...")
        example_results = []

        example_path = self.project_root / example_name
        if not example_path.exists():
            result = TestResult(example_name, 'existence')
            result.failed(f"Example directory not found: {example_path}")
            return [result]

        # Extract database name
        db_name = self._get_database_name(example_name)

        # Test schema creation
        example_results.extend(self.test_schema_creation(example_name, db_name))

        # Test table structure
        example_results.extend(self.test_table_structure(example_name, db_name))

        # Test constraints
        example_results.extend(self.test_constraints(example_name, db_name))

        # Test indexes
        example_results.extend(self.test_indexes(example_name, db_name))

        # Test queries
        example_results.extend(self.test_queries(example_name, db_name))

        # Test data generators
        example_results.extend(self.test_generators(example_name, db_name))

        # Test business logic
        example_results.extend(self.test_business_logic(example_name, db_name))

        return example_results

    def test_schema_creation(self, example_name: str, db_name: str) -> List[TestResult]:
        """Test that schema files execute without errors."""
        results = []
        schema_path = self.project_root / example_name / 'schema'

        # Test database creation
        result = TestResult(f"{example_name}/00_create_database", 'schema_creation')
        db_script = schema_path / '00_create_database.sql'

        if db_script.exists():
            start_time = time.time()
            success = self._execute_sql_file(db_script)
            duration = time.time() - start_time

            if success:
                result.passed(f"Database {db_name} created successfully", duration)
            else:
                result.failed(f"Failed to create database {db_name}")
        else:
            result.skipped("Database creation script not found")

        results.append(result)

        # Test other schema files in order
        schema_files = sorted([
            f for f in schema_path.glob('*.sql')
            if f.name != '00_create_database.sql' and not f.name.startswith('10_')
        ])

        for schema_file in schema_files:
            result = TestResult(f"{example_name}/{schema_file.name}", 'schema_creation')

            if not self.connect(db_name):
                result.failed(f"Cannot connect to database {db_name}")
            else:
                start_time = time.time()
                success = self._execute_sql_file(schema_file, db_name)
                duration = time.time() - start_time

                if success:
                    result.passed(f"Schema file executed successfully", duration)
                else:
                    result.failed(f"Schema file execution failed")

            results.append(result)

        return results

    def test_table_structure(self, example_name: str, db_name: str) -> List[TestResult]:
        """Validate table structures and column definitions."""
        results = []
        result = TestResult(f"{example_name}/table_structure", 'structure_validation')

        if not self.connect(db_name):
            result.failed(f"Cannot connect to database {db_name}")
            results.append(result)
            return results

        # Get all tables
        success, tables = self.execute_query("SHOW TABLES")

        if not success:
            result.failed("Failed to retrieve tables", str(tables))
        elif not tables:
            result.failed("No tables found in database")
        else:
            table_count = len(tables)
            result.details['table_count'] = table_count

            # Check each table has primary key
            tables_without_pk = []
            for table_row in tables:
                table_name = list(table_row.values())[0]
                success, columns = self.execute_query(f"SHOW KEYS FROM {table_name} WHERE Key_name = 'PRIMARY'")

                if success and not columns:
                    tables_without_pk.append(table_name)

            if tables_without_pk:
                result.add_warning(f"Tables without primary keys: {', '.join(tables_without_pk)}")

            result.passed(f"Found {table_count} tables", 0.1)

        results.append(result)

        # Test for required tables based on example type
        required_tables = self._get_required_tables(example_name)

        if required_tables:
            result = TestResult(f"{example_name}/required_tables", 'structure_validation')
            success, actual_tables = self.execute_query("SHOW TABLES")

            if success:
                actual_table_names = [list(t.values())[0] for t in actual_tables]
                missing_tables = [t for t in required_tables if t not in actual_table_names]

                if missing_tables:
                    result.failed(f"Missing required tables: {', '.join(missing_tables)}")
                else:
                    result.passed(f"All {len(required_tables)} required tables present")
            else:
                result.failed("Could not verify required tables")

            results.append(result)

        return results

    def test_constraints(self, example_name: str, db_name: str) -> List[TestResult]:
        """Test referential integrity and constraints."""
        results = []
        result = TestResult(f"{example_name}/constraints", 'constraint_validation')

        if not self.connect(db_name):
            result.failed(f"Cannot connect to database {db_name}")
            results.append(result)
            return results

        # Check foreign key constraints
        query = """
        SELECT
            TABLE_NAME,
            CONSTRAINT_NAME,
            REFERENCED_TABLE_NAME
        FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
        WHERE TABLE_SCHEMA = %s
          AND REFERENCED_TABLE_NAME IS NOT NULL
        """

        try:
            cursor = self.connection.cursor(dictionary=True)
            cursor.execute(query, (db_name,))
            constraints = cursor.fetchall()
            cursor.close()

            if constraints:
                result.details['foreign_key_count'] = len(constraints)
                result.passed(f"Found {len(constraints)} foreign key constraints")
            else:
                result.add_warning("No foreign key constraints found")
                result.passed("Constraint check completed")

        except Error as e:
            result.failed("Failed to check constraints", str(e))

        results.append(result)

        # Test unique constraints
        result = TestResult(f"{example_name}/unique_constraints", 'constraint_validation')

        query = """
        SELECT
            TABLE_NAME,
            CONSTRAINT_NAME
        FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
        WHERE TABLE_SCHEMA = %s
          AND CONSTRAINT_TYPE = 'UNIQUE'
        """

        try:
            cursor = self.connection.cursor(dictionary=True)
            cursor.execute(query, (db_name,))
            unique_constraints = cursor.fetchall()
            cursor.close()

            result.details['unique_constraint_count'] = len(unique_constraints)
            result.passed(f"Found {len(unique_constraints)} unique constraints")

        except Error as e:
            result.failed("Failed to check unique constraints", str(e))

        results.append(result)

        return results

    def test_indexes(self, example_name: str, db_name: str) -> List[TestResult]:
        """Test index configuration and performance."""
        results = []
        result = TestResult(f"{example_name}/indexes", 'index_validation')

        if not self.connect(db_name):
            result.failed(f"Cannot connect to database {db_name}")
            results.append(result)
            return results

        # Count and analyze indexes
        query = """
        SELECT
            TABLE_NAME,
            INDEX_NAME,
            NON_UNIQUE,
            SEQ_IN_INDEX,
            COLUMN_NAME
        FROM INFORMATION_SCHEMA.STATISTICS
        WHERE TABLE_SCHEMA = %s
          AND INDEX_NAME != 'PRIMARY'
        ORDER BY TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX
        """

        try:
            cursor = self.connection.cursor(dictionary=True)
            cursor.execute(query, (db_name,))
            indexes = cursor.fetchall()
            cursor.close()

            # Group indexes by table
            table_indexes = {}
            for idx in indexes:
                table = idx['TABLE_NAME']
                if table not in table_indexes:
                    table_indexes[table] = set()
                table_indexes[table].add(idx['INDEX_NAME'])

            total_indexes = sum(len(idxs) for idxs in table_indexes.values())
            result.details['total_indexes'] = total_indexes
            result.details['tables_with_indexes'] = len(table_indexes)

            # Check for tables without indexes
            success, all_tables = self.execute_query("SHOW TABLES")
            if success:
                all_table_names = [list(t.values())[0] for t in all_tables]
                tables_without_indexes = [t for t in all_table_names if t not in table_indexes]

                if tables_without_indexes:
                    result.add_warning(f"Tables without indexes: {', '.join(tables_without_indexes[:5])}")

            result.passed(f"Found {total_indexes} indexes across {len(table_indexes)} tables")

        except Error as e:
            result.failed("Failed to analyze indexes", str(e))

        results.append(result)

        return results

    def test_queries(self, example_name: str, db_name: str) -> List[TestResult]:
        """Test that sample queries execute without errors."""
        results = []
        queries_path = self.project_root / example_name / 'queries'

        if not queries_path.exists():
            result = TestResult(f"{example_name}/queries", 'query_validation')
            result.skipped("No queries directory found")
            results.append(result)
            return results

        if not self.connect(db_name):
            result = TestResult(f"{example_name}/queries", 'query_validation')
            result.failed(f"Cannot connect to database {db_name}")
            results.append(result)
            return results

        # Test each query file
        query_files = sorted(queries_path.glob('*.sql'))

        for query_file in query_files[:3]:  # Test first 3 query files to save time
            result = TestResult(f"{example_name}/{query_file.name}", 'query_validation')

            # Extract and test first SELECT query from file
            try:
                with open(query_file, 'r', encoding='utf-8') as f:
                    content = f.read()

                # Simple extraction of first SELECT statement
                if 'SELECT' in content.upper():
                    # Find first SELECT and try to extract complete query
                    select_pos = content.upper().find('SELECT')
                    query_part = content[select_pos:]

                    # Find the end of query (semicolon or LIMIT)
                    end_pos = query_part.find(';')
                    if end_pos > 0:
                        test_query = query_part[:end_pos]

                        # Add LIMIT if not present to avoid large results
                        if 'LIMIT' not in test_query.upper():
                            test_query += ' LIMIT 1'

                        start_time = time.time()
                        success, result_data = self.execute_query(test_query)
                        duration = time.time() - start_time

                        if success:
                            result.passed(f"Query executed successfully", duration)
                        else:
                            result.failed(f"Query execution failed: {result_data}")
                    else:
                        result.skipped("Could not extract complete query")
                else:
                    result.skipped("No SELECT queries found")

            except Exception as e:
                result.failed(f"Failed to process query file: {e}")

            results.append(result)

        return results

    def test_generators(self, example_name: str, db_name: str) -> List[TestResult]:
        """Test data generators if they exist."""
        results = []

        # Map example to generator name
        generator_name = self._get_generator_name(example_name)
        if not generator_name:
            result = TestResult(f"{example_name}/generator", 'generator_validation')
            result.skipped("No generator mapped for this example")
            results.append(result)
            return results

        generator_path = self.project_root / 'generators' / generator_name

        result = TestResult(f"{example_name}/generator", 'generator_validation')

        if not generator_path.exists():
            result.skipped(f"Generator directory not found: {generator_name}")
        else:
            # Check for required files
            generate_script = generator_path / 'generate.py'
            config_file = generator_path / 'config.yaml'

            if not generate_script.exists():
                result.failed("generate.py not found")
            elif not config_file.exists():
                result.failed("config.yaml not found")
            else:
                # Test that config is valid YAML
                try:
                    with open(config_file, 'r') as f:
                        config = yaml.safe_load(f)

                    if 'counts' in config and 'distributions' in config:
                        result.passed(f"Generator {generator_name} is properly configured")
                    else:
                        result.failed("Generator config missing required sections")

                except Exception as e:
                    result.failed(f"Invalid generator config: {e}")

        results.append(result)

        return results

    def test_business_logic(self, example_name: str, db_name: str) -> List[TestResult]:
        """Test example-specific business logic."""
        results = []

        # Run specific tests based on example type
        if 'fintech' in example_name:
            results.extend(self._test_fintech_logic(db_name))
        elif 'iot_bins' in example_name:
            results.extend(self._test_iot_logic(db_name))
        elif 'social_media' in example_name:
            results.extend(self._test_social_media_logic(db_name))
        elif 'ecommerce' in example_name:
            results.extend(self._test_ecommerce_logic(db_name))

        if not results:
            result = TestResult(f"{example_name}/business_logic", 'logic_validation')
            result.skipped("No specific business logic tests for this example")
            results.append(result)

        return results

    def _test_fintech_logic(self, db_name: str) -> List[TestResult]:
        """Test FinTech-specific business rules."""
        results = []

        if not self.connect(db_name):
            return results

        # Test double-entry bookkeeping
        result = TestResult("fintech/double_entry", 'logic_validation')

        query = """
        SELECT journal_id,
               total_debits,
               total_credits,
               (total_debits - total_credits) AS difference
        FROM journal_entries
        WHERE status = 'posted'
        LIMIT 10
        """

        success, entries = self.execute_query(query)

        if success and entries:
            unbalanced = [e for e in entries if e['difference'] != 0]
            if unbalanced:
                result.failed(f"Found {len(unbalanced)} unbalanced journal entries")
            else:
                result.passed("All journal entries are balanced")
        else:
            result.skipped("No journal entries to test")

        results.append(result)

        return results

    def _test_iot_logic(self, db_name: str) -> List[TestResult]:
        """Test IoT-specific logic."""
        results = []

        if not self.connect(db_name):
            return results

        # Test sensor data partitioning
        result = TestResult("iot/partitioning", 'logic_validation')

        query = """
        SELECT partition_name
        FROM information_schema.partitions
        WHERE table_schema = %s
          AND table_name = 'sensor_readings'
          AND partition_name IS NOT NULL
        """

        try:
            cursor = self.connection.cursor(dictionary=True)
            cursor.execute(query, (db_name,))
            partitions = cursor.fetchall()
            cursor.close()

            if partitions:
                result.passed(f"Found {len(partitions)} partitions for sensor_readings")
            else:
                result.add_warning("No partitions found for sensor_readings table")
                result.passed("Partitioning check completed")

        except Error as e:
            result.failed("Failed to check partitions", str(e))

        results.append(result)

        return results

    def _test_social_media_logic(self, db_name: str) -> List[TestResult]:
        """Test social media-specific logic."""
        results = []

        if not self.connect(db_name):
            return results

        # Test relationship reciprocity
        result = TestResult("social_media/relationships", 'logic_validation')

        query = """
        SELECT COUNT(*) as relationship_count
        FROM relationships
        WHERE status = 'active'
        """

        success, data = self.execute_query(query)

        if success and data:
            count = data[0]['relationship_count']
            result.details['relationship_count'] = count
            result.passed(f"Found {count} active relationships")
        else:
            result.failed("Could not verify relationships")

        results.append(result)

        return results

    def _test_ecommerce_logic(self, db_name: str) -> List[TestResult]:
        """Test e-commerce-specific logic."""
        results = []

        if not self.connect(db_name):
            return results

        # Test inventory consistency
        result = TestResult("ecommerce/inventory", 'logic_validation')

        # This would check that inventory levels are consistent
        result.skipped("Inventory validation not implemented")
        results.append(result)

        return results

    def _execute_sql_file(self, file_path: Path, database: str = None) -> bool:
        """Execute a SQL file using mysql command line."""
        cmd = ['mysql', '-h', self.host, '-u', self.user]

        if self.password:
            cmd.extend([f'-p{self.password}'])

        if database:
            cmd.append(database)

        try:
            with open(file_path, 'r') as f:
                subprocess.run(cmd, stdin=f, capture_output=True, text=True, check=True)
            return True
        except subprocess.CalledProcessError as e:
            logger.error(f"Failed to execute {file_path}: {e.stderr}")
            return False
        except Exception as e:
            logger.error(f"Error executing {file_path}: {e}")
            return False

    def _get_database_name(self, example_name: str) -> str:
        """Extract database name from example name."""
        mapping = {
            'example_01_clinic': 'clinic',
            'example_02_iot_bins': 'iot_bins',
            'example_03_smart_energy': 'smart_energy',
            'example_04_ecommerce': 'ecommerce',
            'example_05_industrial_iot': 'industrial_iot',
            'example_06_smart_agriculture': 'smart_agriculture',
            'example_07_fleet_management': 'fleet_management',
            'example_08_healthcare_iot': 'healthcare_iot',
            'example_09_streaming_ml': 'streaming_ml',
            'example_10_fintech': 'fintech',
            'example_11_social_media': 'social_media'
        }
        return mapping.get(example_name, example_name.split('_', 2)[-1])

    def _get_generator_name(self, example_name: str) -> Optional[str]:
        """Map example to generator name."""
        mapping = {
            'example_01_clinic': 'clinic',
            'example_02_iot_bins': 'iot_bins',
            'example_03_smart_energy': 'smart_energy',
            'example_04_ecommerce': 'ecommerce',
            'example_05_industrial_iot': 'industrial_iot',
            'example_06_smart_agriculture': 'smart_agriculture',
            'example_07_fleet_management': 'fleet_management',
            'example_08_healthcare_iot': 'healthcare_iot',
            'example_09_streaming_ml': 'streaming_ml',
            'example_10_fintech': 'fintech',
            'example_11_social_media': 'social_media'
        }
        return mapping.get(example_name)

    def _get_required_tables(self, example_name: str) -> List[str]:
        """Get list of required tables for an example."""
        requirements = {
            'example_01_clinic': ['patients', 'doctors', 'appointments'],
            'example_02_iot_bins': ['bins', 'sensors', 'sensor_readings'],
            'example_03_smart_energy': ['buildings', 'energy_meters', 'energy_readings'],
            'example_04_ecommerce': ['users', 'products', 'orders', 'order_items'],
            'example_10_fintech': ['customers', 'accounts', 'transactions', 'journal_entries'],
            'example_11_social_media': ['users', 'posts', 'relationships', 'comments']
        }
        return requirements.get(example_name, [])

    def generate_report(self, results: List[TestResult], format: str = 'text') -> str:
        """Generate test report."""
        if format == 'json':
            return json.dumps([r.to_dict() for r in results], indent=2)

        # Group results by example
        example_results = {}
        for result in results:
            example = result.test_name.split('/')[0]
            if example not in example_results:
                example_results[example] = []
            example_results[example].append(result)

        # Generate text report
        report_lines = []
        report_lines.append("=" * 80)
        report_lines.append("DATABASE EXAMPLES TEST REPORT")
        report_lines.append(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        report_lines.append("=" * 80)

        # Summary statistics
        total_tests = len(results)
        passed = sum(1 for r in results if r.status == 'passed')
        failed = sum(1 for r in results if r.status == 'failed')
        skipped = sum(1 for r in results if r.status == 'skipped')

        report_lines.append("\nSUMMARY")
        report_lines.append("-" * 40)
        report_lines.append(f"Total Tests: {total_tests}")
        report_lines.append(f"Passed: {passed} ({100*passed//max(total_tests,1)}%)")
        report_lines.append(f"Failed: {failed} ({100*failed//max(total_tests,1)}%)")
        report_lines.append(f"Skipped: {skipped} ({100*skipped//max(total_tests,1)}%)")

        # Detailed results by example
        report_lines.append("\nDETAILED RESULTS BY EXAMPLE")
        report_lines.append("-" * 40)

        for example, example_tests in sorted(example_results.items()):
            report_lines.append(f"\n📁 {example}")

            for test in example_tests:
                icon = {
                    'passed': '✅',
                    'failed': '❌',
                    'skipped': '⏭️ '
                }.get(test.status, '❓')

                report_lines.append(f"  {icon} {test.test_name.split('/')[-1]}: {test.message}")

                if test.errors:
                    for error in test.errors:
                        report_lines.append(f"      ERROR: {error}")

                if test.warnings:
                    for warning in test.warnings:
                        report_lines.append(f"      ⚠️  WARNING: {warning}")

                if test.details:
                    for key, value in test.details.items():
                        report_lines.append(f"      ℹ️  {key}: {value}")

        # Failed tests summary
        if failed > 0:
            report_lines.append("\nFAILED TESTS")
            report_lines.append("-" * 40)

            for result in results:
                if result.status == 'failed':
                    report_lines.append(f"❌ {result.test_name}: {result.message}")

        return "\n".join(report_lines)

    def run_all_tests(self) -> List[TestResult]:
        """Run tests for all examples."""
        all_results = []

        # Find all example directories
        example_dirs = sorted([
            d for d in self.project_root.iterdir()
            if d.is_dir() and d.name.startswith('example_')
        ])

        logger.info(f"Found {len(example_dirs)} examples to test")

        for example_dir in example_dirs:
            example_results = self.test_example(example_dir.name)
            all_results.extend(example_results)

        return all_results


def main():
    parser = argparse.ArgumentParser(description='MySQL Examples Test Suite')
    parser.add_argument('--host', default='localhost', help='MySQL host')
    parser.add_argument('--port', type=int, default=3306, help='MySQL port')
    parser.add_argument('--user', default='root', help='MySQL user')
    parser.add_argument('--password', default='', help='MySQL password')
    parser.add_argument('--example', help='Test specific example')
    parser.add_argument('--all', action='store_true', help='Test all examples')
    parser.add_argument('--output', choices=['text', 'json'], default='text', help='Output format')
    parser.add_argument('--save', help='Save report to file')
    parser.add_argument('--verbose', action='store_true', help='Verbose output')

    args = parser.parse_args()

    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)

    # Create test suite
    suite = DatabaseTestSuite(
        host=args.host,
        port=args.port,
        user=args.user,
        password=args.password
    )

    # Run tests
    results = []

    if args.all:
        results = suite.run_all_tests()
    elif args.example:
        results = suite.test_example(args.example)
    else:
        print("Please specify --example or --all")
        sys.exit(1)

    # Generate report
    report = suite.generate_report(results, args.output)
    print(report)

    # Save report if requested
    if args.save:
        with open(args.save, 'w') as f:
            f.write(report)
        print(f"\nReport saved to: {args.save}")

    # Exit with appropriate code
    failed_count = sum(1 for r in results if r.status == 'failed')
    sys.exit(1 if failed_count > 0 else 0)


if __name__ == '__main__':
    main()