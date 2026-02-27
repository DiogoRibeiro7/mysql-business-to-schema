#!/usr/bin/env python3
"""
Comprehensive System Testing Script for MySQL Business-to-Schema
Tests all major components and integrations
"""

import os
import sys
import time
import json
import subprocess
import requests
import psycopg2
import mysql.connector
import redis
from typing import Dict, List, Tuple, Any
from datetime import datetime
from colorama import init, Fore, Style

# Initialize colorama for colored output
init()

# Test results storage
test_results = {"passed": [], "failed": [], "skipped": [], "warnings": []}


def print_header(text: str):
    """Print section header"""
    print(f"\n{Fore.CYAN}{'='*60}{Style.RESET_ALL}")
    print(f"{Fore.CYAN}{text:^60}{Style.RESET_ALL}")
    print(f"{Fore.CYAN}{'='*60}{Style.RESET_ALL}\n")


def print_test(name: str, status: str, message: str = ""):
    """Print test result"""
    if status == "PASS":
        print(f"  {Fore.GREEN}✓{Style.RESET_ALL} {name}")
        test_results["passed"].append(name)
    elif status == "FAIL":
        print(f"  {Fore.RED}✗{Style.RESET_ALL} {name}")
        if message:
            print(f"    {Fore.YELLOW}→ {message}{Style.RESET_ALL}")
        test_results["failed"].append((name, message))
    elif status == "SKIP":
        print(f"  {Fore.YELLOW}○{Style.RESET_ALL} {name} (skipped)")
        test_results["skipped"].append(name)
    elif status == "WARN":
        print(f"  {Fore.YELLOW}⚠{Style.RESET_ALL} {name}")
        if message:
            print(f"    {Fore.YELLOW}→ {message}{Style.RESET_ALL}")
        test_results["warnings"].append((name, message))


def run_command(cmd: str) -> Tuple[bool, str]:
    """Run shell command and return success status and output"""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        return result.returncode == 0, result.stdout + result.stderr
    except Exception as e:
        return False, str(e)


# ==================== Test Functions ====================


def test_docker_services():
    """Test if Docker services are running"""
    print_header("Docker Services")

    services = [
        "mysql",
        "postgres",
        "redis",
        "kafka",
        "zookeeper",
        "elasticsearch",
        "prometheus",
        "grafana",
    ]

    for service in services:
        success, output = run_command(f"docker ps | grep {service}")
        if success and service in output:
            print_test(f"Docker: {service}", "PASS")
        else:
            print_test(f"Docker: {service}", "WARN", "Service not running")


def test_database_schemas():
    """Test MySQL database schemas"""
    print_header("Database Schemas")

    try:
        # Connect to MySQL
        conn = mysql.connector.connect(host="localhost", user="root", password="root")
        cursor = conn.cursor()

        # Test each schema
        schemas = [
            "clinic_db",
            "iot_bins_db",
            "smart_energy_db",
            "ecommerce_db",
            "industrial_iot_db",
            "smart_agriculture_db",
            "fleet_management_db",
            "healthcare_iot_db",
            "streaming_ml_db",
            "fintech_db",
        ]

        for schema in schemas:
            cursor.execute(f"SHOW DATABASES LIKE '{schema}'")
            result = cursor.fetchone()
            if result:
                # Check table count
                cursor.execute(
                    f"""
                    SELECT COUNT(*)
                    FROM information_schema.tables
                    WHERE table_schema = '{schema}'
                """
                )
                table_count = cursor.fetchone()[0]
                print_test(f"Schema: {schema} ({table_count} tables)", "PASS")
            else:
                print_test(f"Schema: {schema}", "SKIP", "Not created")

        conn.close()

    except Exception as e:
        print_test("MySQL Connection", "FAIL", str(e))


def test_admin_api():
    """Test Admin Dashboard API"""
    print_header("Admin Dashboard API")

    base_url = "http://localhost:8000"
    endpoints = [
        ("/health", "GET", None),
        ("/api/schemas", "GET", None),
        ("/api/auth/login", "POST", {"username": "admin", "password": "admin"}),
        ("/api/metrics/system", "GET", None),
        ("/api/migrations/status", "GET", None),
    ]

    for endpoint, method, data in endpoints:
        try:
            if method == "GET":
                response = requests.get(f"{base_url}{endpoint}", timeout=5)
            else:
                response = requests.post(f"{base_url}{endpoint}", json=data, timeout=5)

            if response.status_code < 400:
                print_test(f"API: {method} {endpoint}", "PASS")
            else:
                print_test(
                    f"API: {method} {endpoint}",
                    "FAIL",
                    f"Status {response.status_code}",
                )

        except requests.exceptions.ConnectionError:
            print_test(f"API: {method} {endpoint}", "SKIP", "Service not running")
        except Exception as e:
            print_test(f"API: {method} {endpoint}", "FAIL", str(e))


def test_python_sdk():
    """Test Python SDK"""
    print_header("Python SDK")

    try:
        # Import SDK
        sys.path.append("sdks/python/src")
        from mysql_business_schema import MySQLSchemaClient

        # Create client
        client = MySQLSchemaClient(host="localhost", port=8000)
        print_test("SDK: Import", "PASS")

        # Test methods
        try:
            schemas = client.list_schemas()
            print_test(f"SDK: list_schemas ({len(schemas)} found)", "PASS")
        except:
            print_test("SDK: list_schemas", "SKIP", "API not available")

    except ImportError:
        print_test("SDK: Import", "SKIP", "SDK not installed")
    except Exception as e:
        print_test("SDK: Client creation", "FAIL", str(e))


def test_data_generators():
    """Test data generators"""
    print_header("Data Generators")

    generators_dir = "generators"
    if os.path.exists(generators_dir):
        # Count generator files
        generator_files = []
        for root, dirs, files in os.walk(generators_dir):
            for file in files:
                if file.endswith("_generator.py"):
                    generator_files.append(file)

        print_test(f"Generators: {len(generator_files)} files found", "PASS")

        # Test import of a generator
        try:
            sys.path.append(generators_dir)
            from clinic import patient_generator

            print_test("Generator: Import patient_generator", "PASS")
        except:
            print_test(
                "Generator: Import patient_generator", "WARN", "Could not import"
            )
    else:
        print_test("Generators directory", "SKIP", "Not found")


def test_ml_platform():
    """Test ML Platform components"""
    print_header("ML Platform")

    # Test MLflow
    try:
        response = requests.get("http://localhost:5001/health", timeout=5)
        if response.status_code == 200:
            print_test("MLflow: Health check", "PASS")
        else:
            print_test("MLflow: Health check", "FAIL", f"Status {response.status_code}")
    except:
        print_test("MLflow: Health check", "SKIP", "Service not running")

    # Test Feast
    try:
        import feast

        print_test("Feast: Import", "PASS")
    except ImportError:
        print_test("Feast: Import", "SKIP", "Not installed")

    # Test BentoML
    try:
        response = requests.get("http://localhost:3000/health", timeout=5)
        if response.status_code == 200:
            print_test("BentoML: Health check", "PASS")
        else:
            print_test("BentoML: Health check", "FAIL")
    except:
        print_test("BentoML: Health check", "SKIP", "Service not running")


def test_data_pipeline():
    """Test Data Pipeline components"""
    print_header("Data Pipeline")

    # Test Kafka
    success, output = run_command(
        "docker exec kafka1 kafka-topics --list --zookeeper zookeeper:2181"
    )
    if success:
        topics = output.strip().split("\n")
        print_test(f"Kafka: {len(topics)} topics", "PASS")
    else:
        print_test("Kafka: Topic list", "SKIP", "Kafka not running")

    # Test ClickHouse
    try:
        response = requests.get("http://localhost:8123/ping", timeout=5)
        if response.status_code == 200:
            print_test("ClickHouse: Health check", "PASS")
        else:
            print_test("ClickHouse: Health check", "FAIL")
    except:
        print_test("ClickHouse: Health check", "SKIP", "Service not running")


def test_observability():
    """Test Observability Stack"""
    print_header("Observability Stack")

    # Test Prometheus
    try:
        response = requests.get("http://localhost:9090/-/healthy", timeout=5)
        if response.status_code == 200:
            print_test("Prometheus: Health check", "PASS")

            # Check targets
            targets_response = requests.get("http://localhost:9090/api/v1/targets")
            if targets_response.status_code == 200:
                targets = targets_response.json()["data"]["activeTargets"]
                print_test(f"Prometheus: {len(targets)} active targets", "PASS")
        else:
            print_test("Prometheus: Health check", "FAIL")
    except:
        print_test("Prometheus: Health check", "SKIP", "Service not running")

    # Test Grafana
    try:
        response = requests.get("http://localhost:3000/api/health", timeout=5)
        if response.status_code == 200:
            print_test("Grafana: Health check", "PASS")
        else:
            print_test("Grafana: Health check", "FAIL")
    except:
        print_test("Grafana: Health check", "SKIP", "Service not running")


def test_performance():
    """Test Performance Testing Stack"""
    print_header("Performance Testing")

    # Check if Locust is available
    success, output = run_command("which locust")
    if success:
        print_test("Locust: Installed", "PASS")
    else:
        print_test("Locust: Installed", "SKIP", "Not installed")

    # Check if K6 is available
    success, output = run_command("which k6")
    if success:
        print_test("K6: Installed", "PASS")
    else:
        print_test("K6: Installed", "SKIP", "Not installed")

    # Check Chaos Monkey script
    if os.path.exists("performance-testing/chaos/chaos_monkey.py"):
        print_test("Chaos Monkey: Script exists", "PASS")
    else:
        print_test("Chaos Monkey: Script exists", "FAIL")


def test_file_structure():
    """Test project file structure"""
    print_header("Project Structure")

    required_dirs = [
        "example_01_clinic",
        "example_02_iot_bins",
        "generators",
        "tests",
        "admin_dashboard",
        "sdks",
        "observability",
        "data-pipeline",
        "performance-testing",
        "ml-platform",
        "migration_system",
    ]

    for dir_name in required_dirs:
        if os.path.exists(dir_name):
            # Count files in directory
            file_count = sum(1 for _, _, files in os.walk(dir_name) for _ in files)
            print_test(f"Directory: {dir_name} ({file_count} files)", "PASS")
        else:
            print_test(f"Directory: {dir_name}", "FAIL", "Not found")


def test_documentation():
    """Test documentation files"""
    print_header("Documentation")

    doc_files = [
        "README.md",
        "SYSTEM_REVIEW.md",
        "admin_dashboard/README.md",
        "sdks/python/README.md",
        "observability/README.md",
        "data-pipeline/README.md",
        "performance-testing/README.md",
        "ml-platform/README.md",
    ]

    for doc_file in doc_files:
        if os.path.exists(doc_file):
            # Check file size
            size = os.path.getsize(doc_file)
            if size > 100:
                print_test(f"Doc: {doc_file} ({size} bytes)", "PASS")
            else:
                print_test(f"Doc: {doc_file}", "WARN", "File too small")
        else:
            print_test(f"Doc: {doc_file}", "FAIL", "Not found")


def run_integration_test():
    """Run a simple integration test"""
    print_header("Integration Test")

    try:
        # 1. Check if MySQL is accessible
        mysql_conn = mysql.connector.connect(
            host="localhost", user="root", password="root"
        )
        print_test("Integration: MySQL connection", "PASS")

        # 2. Create test database
        cursor = mysql_conn.cursor()
        cursor.execute("CREATE DATABASE IF NOT EXISTS test_integration")
        cursor.execute("USE test_integration")
        print_test("Integration: Create test database", "PASS")

        # 3. Create test table
        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS test_table (
                id INT PRIMARY KEY AUTO_INCREMENT,
                data VARCHAR(255),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """
        )
        print_test("Integration: Create test table", "PASS")

        # 4. Insert test data
        cursor.execute("INSERT INTO test_table (data) VALUES ('test')")
        mysql_conn.commit()
        print_test("Integration: Insert data", "PASS")

        # 5. Query data
        cursor.execute("SELECT COUNT(*) FROM test_table")
        count = cursor.fetchone()[0]
        if count > 0:
            print_test(f"Integration: Query data ({count} rows)", "PASS")
        else:
            print_test("Integration: Query data", "FAIL", "No data found")

        # 6. Clean up
        cursor.execute("DROP DATABASE test_integration")
        mysql_conn.close()
        print_test("Integration: Cleanup", "PASS")

    except Exception as e:
        print_test("Integration test", "FAIL", str(e))


def print_summary():
    """Print test summary"""
    print_header("Test Summary")

    total = (
        len(test_results["passed"])
        + len(test_results["failed"])
        + len(test_results["skipped"])
    )

    print(f"{Fore.GREEN}Passed:{Style.RESET_ALL} {len(test_results['passed'])}/{total}")
    print(f"{Fore.RED}Failed:{Style.RESET_ALL} {len(test_results['failed'])}/{total}")
    print(
        f"{Fore.YELLOW}Skipped:{Style.RESET_ALL} {len(test_results['skipped'])}/{total}"
    )
    print(f"{Fore.YELLOW}Warnings:{Style.RESET_ALL} {len(test_results['warnings'])}")

    if test_results["failed"]:
        print(f"\n{Fore.RED}Failed Tests:{Style.RESET_ALL}")
        for name, message in test_results["failed"]:
            print(f"  - {name}: {message}")

    if test_results["warnings"]:
        print(f"\n{Fore.YELLOW}Warnings:{Style.RESET_ALL}")
        for name, message in test_results["warnings"]:
            print(f"  - {name}: {message}")

    # Overall result
    print(f"\n{Fore.CYAN}{'='*60}{Style.RESET_ALL}")
    if not test_results["failed"]:
        print(f"{Fore.GREEN}✓ ALL CRITICAL TESTS PASSED!{Style.RESET_ALL}")
    else:
        print(f"{Fore.RED}✗ SOME TESTS FAILED - Review required{Style.RESET_ALL}")
    print(f"{Fore.CYAN}{'='*60}{Style.RESET_ALL}")


def main():
    """Main test execution"""
    print(f"\n{Fore.CYAN}MySQL Business-to-Schema System Test{Style.RESET_ALL}")
    print(f"{Fore.CYAN}Started: {datetime.now()}{Style.RESET_ALL}")

    # Run all tests
    test_file_structure()
    test_documentation()
    test_database_schemas()
    test_data_generators()
    test_admin_api()
    test_python_sdk()
    test_ml_platform()
    test_data_pipeline()
    test_observability()
    test_performance()
    test_docker_services()
    run_integration_test()

    # Print summary
    print_summary()

    print(f"\n{Fore.CYAN}Completed: {datetime.now()}{Style.RESET_ALL}\n")


if __name__ == "__main__":
    main()
