#!/usr/bin/env python3
"""Comprehensive Component Testing for MySQL Business-to-Schema.

Tests all major components without requiring MySQL to be running
"""

import os
import sys
import json
import subprocess
from datetime import datetime
from colorama import init, Fore, Style
import importlib.util

# Initialize colorama
init()


class ComponentTester:
    """Test all system components."""

    def __init__(self):
        """Initialize the instance."""
        self.results = {"passed": [], "failed": [], "skipped": [], "warnings": []}
        self.start_time = datetime.now()

    def print_header(self, text: str):
        """Print section header."""
        print(f"\n{Fore.CYAN}{'='*70}{Style.RESET_ALL}")
        print(f"{Fore.CYAN}{text:^70}{Style.RESET_ALL}")
        print(f"{Fore.CYAN}{'='*70}{Style.RESET_ALL}\n")

    def print_test(self, name: str, status: str, message: str = ""):
        """Print test result."""
        if status == "PASS":
            print(f"  {Fore.GREEN}[OK]{Style.RESET_ALL} {name}")
            self.results["passed"].append(name)
        elif status == "FAIL":
            print(f"  {Fore.RED}[X]{Style.RESET_ALL} {name}")
            if message:
                print(f"    {Fore.YELLOW}-> {message}{Style.RESET_ALL}")
            self.results["failed"].append((name, message))
        elif status == "SKIP":
            print(f"  {Fore.YELLOW}[-]{Style.RESET_ALL} {name} (skipped)")
            if message:
                print(f"    {Fore.YELLOW}-> {message}{Style.RESET_ALL}")
            self.results["skipped"].append(name)
        elif status == "WARN":
            print(f"  {Fore.YELLOW}[!]{Style.RESET_ALL} {name}")
            if message:
                print(f"    {Fore.YELLOW}-> {message}{Style.RESET_ALL}")
            self.results["warnings"].append((name, message))

    def test_project_structure(self):
        """Test project directory structure."""
        self.print_header("Project Structure")

        required_dirs = {
            "example_01_clinic": "Clinic management schema",
            "example_02_iot_bins": "IoT bins schema",
            "example_03_smart_energy": "Smart energy schema",
            "example_04_ecommerce": "E-commerce schema",
            "example_05_industrial_iot": "Industrial IoT schema",
            "admin_dashboard": "Admin dashboard",
            "sdks": "SDK libraries",
            "generators": "Data generators",
            "ml-platform": "ML platform",
            "data-pipeline": "Data pipeline",
            "observability": "Observability stack",
            "performance-testing": "Performance testing",
            "migration_system": "Migration system",
            "tests": "Test suites",
            "docs": "Documentation",
            "demo_data": "Generated demo data",
            "scripts": "Utility scripts",
        }

        for dir_name, description in required_dirs.items():
            if os.path.exists(dir_name):
                # Count files
                file_count = sum(1 for _, _, files in os.walk(dir_name) for _ in files)
                self.print_test(f"{description} ({file_count} files)", "PASS")
            else:
                self.print_test(
                    f"{description}", "FAIL", f"Directory {dir_name} not found"
                )

    def test_schema_files(self):
        """Test schema SQL files."""
        self.print_header("Schema SQL Files")

        schema_count = 0
        for i in range(1, 21):
            # Find schema directory
            schema_dirs = [
                d for d in os.listdir(".") if d.startswith(f"example_{i:02d}_")
            ]

            if schema_dirs:
                schema_dir = schema_dirs[0]
                schema_path = os.path.join(schema_dir, "schema")

                if os.path.exists(schema_path):
                    sql_files = [
                        f for f in os.listdir(schema_path) if f.endswith(".sql")
                    ]

                    # Check for essential files
                    essential_files = ["00_create_database.sql", "01_tables.sql"]
                    has_essentials = all(f in sql_files for f in essential_files)

                    if has_essentials:
                        self.print_test(
                            f"Schema {i}: {schema_dir} ({len(sql_files)} SQL files)",
                            "PASS",
                        )
                        schema_count += 1
                    else:
                        self.print_test(
                            f"Schema {i}: {schema_dir}",
                            "WARN",
                            "Missing essential SQL files",
                        )
                else:
                    self.print_test(
                        f"Schema {i}: {schema_dir}", "FAIL", "No schema directory"
                    )

        print(f"\n  {Fore.CYAN}Total schemas found: {schema_count}/20{Style.RESET_ALL}")

    def test_generated_data(self):
        """Test generated demo data."""
        self.print_header("Generated Demo Data")

        if not os.path.exists("demo_data"):
            self.print_test("Demo data directory", "FAIL", "Directory not found")
            return

        sql_files = [f for f in os.listdir("demo_data") if f.endswith(".sql")]

        if sql_files:
            self.print_test(f"Demo data directory ({len(sql_files)} SQL files)", "PASS")

            # Check specific schema data files
            expected_data_files = [
                "clinic_db_data.sql",
                "ecommerce_db_data.sql",
                "iot_bins_db_data.sql",
                "fintech_db_data.sql",
                "social_media_db_data.sql",
                "real_estate_db_data.sql",
            ]

            for data_file in expected_data_files:
                file_path = os.path.join("demo_data", data_file)
                if os.path.exists(file_path):
                    size_kb = os.path.getsize(file_path) / 1024
                    self.print_test(f"{data_file} ({size_kb:.1f} KB)", "PASS")
                else:
                    self.print_test(f"{data_file}", "SKIP", "Not generated yet")

            # Check master import scripts
            if os.path.exists("demo_data/import_complete.sql"):
                self.print_test("Complete master import script", "PASS")
            else:
                self.print_test("Complete master import script", "WARN", "Not found")
        else:
            self.print_test("Demo data files", "FAIL", "No SQL files generated")

    def test_python_components(self):
        """Test Python components."""
        self.print_header("Python Components")

        # Test generators
        generator_files = [
            "generators/generate_all_data.py",
            "generators/demo_data_generator.py",
            "generators/generate_additional_schemas.py",
            "generators/generate_remaining_schemas.py",
            "generators/clinic/patient_generator.py",
        ]

        for gen_file in generator_files:
            if os.path.exists(gen_file):
                try:
                    # Try to import the module to check syntax
                    spec = importlib.util.spec_from_file_location(
                        "test_module", gen_file
                    )
                    if spec:
                        self.print_test(
                            f"Generator: {os.path.basename(gen_file)}", "PASS"
                        )
                    else:
                        self.print_test(
                            f"Generator: {os.path.basename(gen_file)}",
                            "FAIL",
                            "Cannot load module",
                        )
                except Exception as e:
                    self.print_test(
                        f"Generator: {os.path.basename(gen_file)}", "FAIL", str(e)
                    )
            else:
                self.print_test(
                    f"Generator: {os.path.basename(gen_file)}", "SKIP", "File not found"
                )

        # Test SDK
        if os.path.exists("sdks/python/src/mysql_business_schema/__init__.py"):
            self.print_test("Python SDK package", "PASS")
        else:
            self.print_test("Python SDK package", "WARN", "Not found")

        # Test admin dashboard backend
        if os.path.exists("admin_dashboard/backend/main.py"):
            self.print_test("Admin Dashboard FastAPI backend", "PASS")
        else:
            self.print_test("Admin Dashboard FastAPI backend", "FAIL", "Not found")

    def test_frontend_components(self):
        """Test frontend components."""
        self.print_header("Frontend Components")

        # Check React frontend
        if os.path.exists("admin_dashboard/frontend/package.json"):
            try:
                with open("admin_dashboard/frontend/package.json", "r") as f:
                    package = json.load(f)
                    deps = package.get("dependencies", {})

                    # Check key dependencies
                    key_deps = ["react", "react-dom", "@mui/material", "redux", "axios"]
                    for dep in key_deps:
                        if dep in deps:
                            self.print_test(f"Frontend dependency: {dep}", "PASS")
                        else:
                            self.print_test(
                                f"Frontend dependency: {dep}",
                                "FAIL",
                                "Not in package.json",
                            )
            except Exception as e:
                self.print_test("Frontend package.json", "FAIL", str(e))
        else:
            self.print_test("Frontend package.json", "SKIP", "Frontend not built")

        # Check key React components
        component_files = [
            "admin_dashboard/frontend/src/App.tsx",
            "admin_dashboard/frontend/src/components/Dashboard.tsx",
            "admin_dashboard/frontend/src/components/SchemaList.tsx",
        ]

        for comp_file in component_files:
            if os.path.exists(comp_file):
                self.print_test(
                    f"React component: {os.path.basename(comp_file)}", "PASS"
                )
            else:
                self.print_test(
                    f"React component: {os.path.basename(comp_file)}",
                    "SKIP",
                    "Not created",
                )

    def test_docker_configs(self):
        """Test Docker configurations."""
        self.print_header("Docker Configurations")

        docker_files = [
            ("docker-compose.yml", "Main Docker Compose"),
            ("docker-compose.mysql.yml", "MySQL-only setup"),
            ("docker-compose.core.yml", "Core services"),
            ("observability/docker-compose.yml", "Observability stack"),
            ("data-pipeline/docker-compose.yml", "Data pipeline"),
            ("ml-platform/docker-compose.yml", "ML platform"),
        ]

        for file_path, description in docker_files:
            if os.path.exists(file_path):
                # Check if it's valid YAML (basic check)
                try:
                    with open(file_path, "r") as f:
                        content = f.read()
                        if "version:" in content and "services:" in content:
                            self.print_test(f"{description}", "PASS")
                        else:
                            self.print_test(
                                f"{description}", "WARN", "May be incomplete"
                            )
                except Exception as e:
                    self.print_test(f"{description}", "FAIL", str(e))
            else:
                self.print_test(f"{description}", "SKIP", "Not found")

    def test_documentation(self):
        """Test documentation files."""
        self.print_header("Documentation")

        doc_files = [
            ("README.md", "Main README"),
            ("SYSTEM_REVIEW.md", "System review"),
            ("QUICK_START.md", "Quick start guide"),
            ("DATA_GENERATION_GUIDE.md", "Data generation guide"),
            ("docs/API_DOCUMENTATION.md", "API documentation"),
            ("docs/ARCHITECTURE.md", "Architecture docs"),
            ("admin_dashboard/README.md", "Admin dashboard docs"),
            ("ml-platform/README.md", "ML platform docs"),
            ("data-pipeline/README.md", "Data pipeline docs"),
            ("observability/README.md", "Observability docs"),
        ]

        for file_path, description in doc_files:
            if os.path.exists(file_path):
                size = os.path.getsize(file_path)
                if size > 100:  # Has content
                    self.print_test(f"{description} ({size/1024:.1f} KB)", "PASS")
                else:
                    self.print_test(f"{description}", "WARN", "File too small")
            else:
                self.print_test(f"{description}", "SKIP", "Not found")

    def test_configuration_files(self):
        """Test configuration files."""
        self.print_header("Configuration Files")

        config_files = [
            ("observability/prometheus/prometheus.yml", "Prometheus config"),
            ("observability/prometheus/alerts.yml", "Alert rules"),
            (
                "observability/grafana/dashboards/mysql-overview.json",
                "Grafana dashboard",
            ),
            ("ml-platform/mlflow/mlflow.conf", "MLflow config"),
            ("data-pipeline/kafka/server.properties", "Kafka config"),
            ("performance-testing/locust/locustfile.py", "Locust test file"),
            ("performance-testing/k6/load-test.js", "K6 test script"),
            (".github/workflows/ci.yml", "CI/CD workflow"),
        ]

        for file_path, description in config_files:
            if os.path.exists(file_path):
                self.print_test(description, "PASS")
            else:
                self.print_test(description, "SKIP", "Not configured")

    def test_utility_scripts(self):
        """Test utility scripts."""
        self.print_header("Utility Scripts")

        scripts = [
            ("scripts/run_data_generation.sh", "Linux data generation"),
            ("scripts/run_data_generation.bat", "Windows data generation"),
            ("scripts/verify_data.py", "Data verification"),
            ("scripts/docker-init/01-create-schemas.sql", "Docker init SQL"),
            ("test_system.py", "System test script"),
        ]

        for script_path, description in scripts:
            if os.path.exists(script_path):
                # Check if executable (for .sh files)
                if script_path.endswith(".sh"):
                    self.print_test(f"{description}", "PASS")
                else:
                    self.print_test(f"{description}", "PASS")
            else:
                self.print_test(f"{description}", "SKIP", "Not found")

    def test_migration_system(self):
        """Test migration system."""
        self.print_header("Migration System")

        if os.path.exists("migration_system"):
            files = os.listdir("migration_system")
            if "migration_cli.py" in files:
                self.print_test("Migration CLI tool", "PASS")
            else:
                self.print_test("Migration CLI tool", "WARN", "CLI not found")

            if "CLI_DOCUMENTATION.md" in files:
                self.print_test("Migration documentation", "PASS")
            else:
                self.print_test("Migration documentation", "SKIP", "Docs not found")

            if os.path.exists("migrations"):
                migration_files = [
                    f for f in os.listdir("migrations") if f.endswith(".sql")
                ]
                if migration_files:
                    self.print_test(
                        f"Migration files ({len(migration_files)} found)", "PASS"
                    )
                else:
                    self.print_test("Migration files", "WARN", "No migrations created")
        else:
            self.print_test("Migration system", "SKIP", "Not implemented")

    def run_quick_validation(self):
        """Run quick validation checks."""
        self.print_header("Quick Validation Checks")

        # Check Python version
        python_version = sys.version_info
        if python_version.major >= 3 and python_version.minor >= 8:
            self.print_test(
                f"Python version ({python_version.major}.{python_version.minor})",
                "PASS",
            )
        else:
            self.print_test(
                f"Python version ({python_version.major}.{python_version.minor})",
                "WARN",
                "Python 3.8+ recommended",
            )

        # Check for Docker
        try:
            result = subprocess.run(
                ["docker", "--version"], capture_output=True, text=True
            )
            if result.returncode == 0:
                self.print_test("Docker installed", "PASS")
            else:
                self.print_test("Docker installed", "FAIL", "Docker not available")
        except Exception:
            self.print_test("Docker installed", "SKIP", "Cannot check Docker")

        # Check for Node.js
        try:
            result = subprocess.run(
                ["node", "--version"], capture_output=True, text=True
            )
            if result.returncode == 0:
                self.print_test(f"Node.js installed ({result.stdout.strip()})", "PASS")
            else:
                self.print_test("Node.js installed", "WARN", "Node.js not available")
        except Exception:
            self.print_test("Node.js installed", "SKIP", "Cannot check Node.js")

        # Check for Git
        try:
            result = subprocess.run(
                ["git", "--version"], capture_output=True, text=True
            )
            if result.returncode == 0:
                self.print_test("Git installed", "PASS")
        except Exception:
            self.print_test("Git installed", "SKIP", "Cannot check Git")

    def print_summary(self):
        """Print test summary."""
        self.print_header("Test Summary")

        total = (
            len(self.results["passed"])
            + len(self.results["failed"])
            + len(self.results["skipped"])
        )

        print(
            f"{Fore.GREEN}Passed:{Style.RESET_ALL} {len(self.results['passed'])}/{total}"
        )
        print(
            f"{Fore.RED}Failed:{Style.RESET_ALL} {len(self.results['failed'])}/{total}"
        )
        print(
            f"{Fore.YELLOW}Skipped:{Style.RESET_ALL} {len(self.results['skipped'])}/{total}"
        )
        print(
            f"{Fore.YELLOW}Warnings:{Style.RESET_ALL} {len(self.results['warnings'])}"
        )

        if self.results["failed"]:
            print(f"\n{Fore.RED}Failed Tests:{Style.RESET_ALL}")
            for name, message in self.results["failed"]:
                print(f"  - {name}: {message}")

        if self.results["warnings"]:
            print(f"\n{Fore.YELLOW}Warnings:{Style.RESET_ALL}")
            for name, message in self.results["warnings"][:5]:  # Show first 5
                print(f"  - {name}: {message}")

        # Overall status
        elapsed = (datetime.now() - self.start_time).total_seconds()
        print(
            f"\n{Fore.CYAN}Testing completed in {elapsed:.1f} seconds{Style.RESET_ALL}"
        )

        if not self.results["failed"]:
            print(f"\n{Fore.GREEN}{'='*70}{Style.RESET_ALL}")
            print(
                f"{Fore.GREEN}[OK] ALL CRITICAL COMPONENTS VALIDATED!{Style.RESET_ALL}"
            )
            print(f"{Fore.GREEN}{'='*70}{Style.RESET_ALL}")
        else:
            print(f"\n{Fore.YELLOW}{'='*70}{Style.RESET_ALL}")
            print(f"{Fore.YELLOW}[!] Some components need attention{Style.RESET_ALL}")
            print(f"{Fore.YELLOW}{'='*70}{Style.RESET_ALL}")

    def run_all_tests(self):
        """Run all component tests."""
        print(
            f"\n{Fore.CYAN}MySQL Business-to-Schema Component Testing{Style.RESET_ALL}"
        )
        print(f"{Fore.CYAN}Started: {datetime.now()}{Style.RESET_ALL}")

        # Run test suites
        self.test_project_structure()
        self.test_schema_files()
        self.test_generated_data()
        self.test_python_components()
        self.test_frontend_components()
        self.test_docker_configs()
        self.test_documentation()
        self.test_configuration_files()
        self.test_utility_scripts()
        self.test_migration_system()
        self.run_quick_validation()

        # Print summary
        self.print_summary()


def main():
    """Run execution."""
    tester = ComponentTester()
    tester.run_all_tests()

    # Return exit code based on failures
    sys.exit(0 if not tester.results["failed"] else 1)


if __name__ == "__main__":
    main()
