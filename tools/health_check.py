#!/usr/bin/env python3
"""Project Health Check Tool.

Validates the integrity and completeness of all examples and generators
"""

import sys
import json
from pathlib import Path
from typing import Tuple
from datetime import datetime

# Add project root to path
PROJECT_ROOT = Path(__file__).parent.parent
sys.path.append(str(PROJECT_ROOT))


class HealthChecker:
    """Represent HealthChecker."""

    def __init__(self):
        """Initialize the instance."""
        self.project_root = PROJECT_ROOT
        self.examples_dir = self.project_root / "example_*"
        self.generators_dir = self.project_root / "generators"
        self.results = {
            "timestamp": datetime.now().isoformat(),
            "examples": {},
            "generators": {},
            "overall": {"passed": 0, "failed": 0, "warnings": 0},
        }

    def check_all(self):
        """Run all health checks."""
        print("=" * 60)
        print("MySQL Business-to-Schema Health Check")
        print("=" * 60)
        print()

        # Check examples
        self.check_examples()

        # Check generators
        self.check_generators()

        # Check documentation
        self.check_documentation()

        # Generate report
        self.generate_report()

    def check_examples(self):
        """Validate all database examples."""
        print("[EXAMPLES] Checking Database Examples...")
        print("-" * 40)

        example_dirs = sorted(self.project_root.glob("example_*"))

        for example_dir in example_dirs:
            example_name = example_dir.name
            print(f"\n  Checking {example_name}...")

            self.results["examples"][example_name] = {
                "status": "PASS",
                "issues": [],
                "warnings": [],
            }

            # Check required directories
            required_dirs = ["schema", "queries"]
            for req_dir in required_dirs:
                if not (example_dir / req_dir).exists():
                    self.results["examples"][example_name]["status"] = "FAIL"
                    self.results["examples"][example_name]["issues"].append(
                        f"Missing required directory: {req_dir}"
                    )

            # Check schema files
            schema_dir = example_dir / "schema"
            if schema_dir.exists():
                required_schema_files = ["00_create_database.sql", "01_tables.sql"]
                for schema_file in required_schema_files:
                    if not (schema_dir / schema_file).exists():
                        self.results["examples"][example_name]["status"] = "FAIL"
                        self.results["examples"][example_name]["issues"].append(
                            f"Missing schema file: {schema_file}"
                        )

                # Optional but recommended files
                optional_files = ["02_constraints.sql", "03_indexes.sql"]
                for opt_file in optional_files:
                    if not (schema_dir / opt_file).exists():
                        self.results["examples"][example_name]["warnings"].append(
                            f"Missing optional file: {opt_file}"
                        )

            # Check README
            if not (example_dir / "README.md").exists():
                self.results["examples"][example_name]["status"] = "FAIL"
                self.results["examples"][example_name]["issues"].append(
                    "Missing README.md"
                )
            else:
                # Check README quality
                readme_path = example_dir / "README.md"
                with open(readme_path, "r", encoding="utf-8") as f:
                    readme_content = f.read()
                    readme_lines = len(readme_content.splitlines())

                    if readme_lines < 100:
                        self.results["examples"][example_name]["warnings"].append(
                            f"README seems too short ({readme_lines} lines)"
                        )

                    # Check for required sections
                    required_sections = [
                        "## Database Overview",
                        "## Schema Structure",
                        "## Getting Started",
                    ]
                    for section in required_sections:
                        if section not in readme_content:
                            self.results["examples"][example_name]["warnings"].append(
                                f"README missing section: {section}"
                            )

            # Display status
            status = self.results["examples"][example_name]["status"]
            if (
                status == "PASS"
                and not self.results["examples"][example_name]["warnings"]
            ):
                print(f"    [OK] {example_name}: PASS")
                self.results["overall"]["passed"] += 1
            elif (
                status == "PASS" and self.results["examples"][example_name]["warnings"]
            ):
                print(f"    [WARN]  {example_name}: PASS with warnings")
                self.results["overall"]["passed"] += 1
                self.results["overall"]["warnings"] += len(
                    self.results["examples"][example_name]["warnings"]
                )
            else:
                print(f"    [FAIL] {example_name}: FAIL")
                self.results["overall"]["failed"] += 1

    def check_generators(self):
        """Validate all data generators."""
        print("\n[GENERATORS] Checking Data Generators...")
        print("-" * 40)

        if not self.generators_dir.exists():
            print("  [FAIL] Generators directory not found!")
            return

        generator_dirs = sorted(
            [
                d
                for d in self.generators_dir.iterdir()
                if d.is_dir() and not d.name.startswith("__")
            ]
        )

        for gen_dir in generator_dirs:
            gen_name = gen_dir.name
            print(f"\n  Checking {gen_name}...")

            self.results["generators"][gen_name] = {
                "status": "PASS",
                "issues": [],
                "warnings": [],
            }

            # Check for generator.py
            if not (gen_dir / "generator.py").exists():
                self.results["generators"][gen_name]["status"] = "FAIL"
                self.results["generators"][gen_name]["issues"].append(
                    "Missing generator.py"
                )

            # Check for test_generator.py
            if not (gen_dir / "test_generator.py").exists():
                self.results["generators"][gen_name]["warnings"].append(
                    "Missing test_generator.py"
                )

            # Check for README
            if not (gen_dir / "README.md").exists():
                self.results["generators"][gen_name]["warnings"].append(
                    "Missing README.md"
                )

            # Check for output directory
            if not (gen_dir / "output").exists():
                self.results["generators"][gen_name]["warnings"].append(
                    "No output directory"
                )

            # Display status
            status = self.results["generators"][gen_name]["status"]
            if (
                status == "PASS"
                and not self.results["generators"][gen_name]["warnings"]
            ):
                print(f"    [OK] {gen_name}: PASS")
                self.results["overall"]["passed"] += 1
            elif status == "PASS" and self.results["generators"][gen_name]["warnings"]:
                print(f"    [WARN]  {gen_name}: PASS with warnings")
                self.results["overall"]["passed"] += 1
                self.results["overall"]["warnings"] += len(
                    self.results["generators"][gen_name]["warnings"]
                )
            else:
                print(f"    [FAIL] {gen_name}: FAIL")
                self.results["overall"]["failed"] += 1

    def check_documentation(self):
        """Check project-level documentation."""
        print("\n[DOCS] Checking Documentation...")
        print("-" * 40)

        required_docs = ["README.md", "CONTRIBUTING.md", "LICENSE"]

        for doc in required_docs:
            doc_path = self.project_root / doc
            if doc_path.exists():
                print(f"    [OK] {doc}: Found")
            else:
                print(f"    [FAIL] {doc}: Missing")
                self.results["overall"]["failed"] += 1

    def check_sql_syntax(self, sql_file: Path) -> Tuple[bool, str]:
        """Validate SQL syntax (requires mysql client)."""
        try:
            # This would require mysql client to be installed
            # For now, just do basic validation
            with open(sql_file, "r", encoding="utf-8") as f:
                content = f.read()

            # Basic checks
            if not content.strip():
                return False, "Empty file"

            # Check for common issues
            if "CREATE TABLE" in content and "ENGINE=" not in content:
                return False, "Missing ENGINE specification"

            return True, "OK"
        except Exception as e:
            return False, str(e)

    def generate_report(self):
        """Generate health check report."""
        print("\n" + "=" * 60)
        print("HEALTH CHECK SUMMARY")
        print("=" * 60)

        total_checks = (
            self.results["overall"]["passed"] + self.results["overall"]["failed"]
        )

        print("\n[STATS] Overall Statistics:")
        print(f"  Total Checks: {total_checks}")
        print(f"  [OK] Passed: {self.results['overall']['passed']}")
        print(f"  [FAIL] Failed: {self.results['overall']['failed']}")
        print(f"  [WARN]  Warnings: {self.results['overall']['warnings']}")

        if self.results["overall"]["failed"] == 0:
            print("\n[SUCCESS] All critical checks passed!")
        else:
            print("\n[WARN]  Some issues need attention.")

        # Save detailed report
        report_file = self.project_root / "health_check_report.json"
        with open(report_file, "w", encoding="utf-8") as f:
            json.dump(self.results, f, indent=2)

        print("\n[REPORT] Detailed report saved to: health_check_report.json")

        # Generate coverage stats
        self.generate_coverage_stats()

    def generate_coverage_stats(self):
        """Generate coverage statistics."""
        print("\n[COVERAGE] Coverage Statistics:")
        print("-" * 40)

        # Count examples with generators
        example_dirs = sorted(self.project_root.glob("example_*"))
        total_examples = len(example_dirs)

        # Map example numbers to generator names
        example_to_generator = {
            "example_01_clinic": "clinic",
            "example_02_ecommerce": "ecommerce",
            "example_03_library": "education",
            "example_04_hotel": "real_estate",
            "example_05_gym": "event_ticketing",
            "example_06_smart_agriculture": "smart_agriculture",
            "example_07_fleet_management": "fleet_management",
            "example_08_iot_waste_bins": "iot_bins",
            "example_09_streaming_ml_platform": "streaming_ml",
            "example_10_fintech": "fintech",
            "example_11_social_media": "social_media",
            "example_12_real_estate": "smart_energy",
            "example_13_event_ticketing": "healthcare_iot",
            "example_14_logistics": "logistics",
            "example_15_education": "industrial_iot",
        }

        examples_with_generators = 0
        for example_dir in example_dirs:
            gen_name = example_to_generator.get(
                example_dir.name,
                example_dir.name.replace("example_", "").replace("_", ""),
            )
            gen_path = self.generators_dir / gen_name / "generator.py"
            if gen_path.exists():
                examples_with_generators += 1

        generator_coverage = (
            (examples_with_generators / total_examples * 100)
            if total_examples > 0
            else 0
        )

        print(f"  Examples: {total_examples}")
        print(
            f"  With Generators: {examples_with_generators}/{total_examples} ({generator_coverage:.1f}%)"
        )

        # Count documentation quality
        well_documented = 0
        for example_dir in example_dirs:
            readme_path = example_dir / "README.md"
            if readme_path.exists():
                with open(readme_path, "r", encoding="utf-8") as f:
                    lines = len(f.read().splitlines())
                    if lines >= 200:
                        well_documented += 1

        doc_coverage = (
            (well_documented / total_examples * 100) if total_examples > 0 else 0
        )
        print(
            f"  Well Documented: {well_documented}/{total_examples} ({doc_coverage:.1f}%)"
        )

        # Overall health score
        health_score = (generator_coverage + doc_coverage) / 2

        print(f"\n[SCORE] Overall Health Score: {health_score:.1f}%")

        if health_score >= 90:
            print("   Status: EXCELLENT")
        elif health_score >= 75:
            print("   Status: GOOD")
        elif health_score >= 60:
            print("   Status: FAIR")
        else:
            print("   Status: NEEDS IMPROVEMENT")


def main():
    """Run health check."""
    checker = HealthChecker()

    # Add command line options
    if len(sys.argv) > 1:
        if sys.argv[1] == "--examples":
            checker.check_examples()
        elif sys.argv[1] == "--generators":
            checker.check_generators()
        elif sys.argv[1] == "--help":
            print("Usage: python health_check.py [OPTIONS]")
            print("\nOptions:")
            print("  --examples    Check only examples")
            print("  --generators  Check only generators")
            print("  --help        Show this help message")
            print("\nWithout options, runs all checks")
        else:
            print(f"Unknown option: {sys.argv[1]}")
            print("Use --help for available options")
    else:
        checker.check_all()

    # Return exit code based on failures
    sys.exit(checker.results["overall"]["failed"])


if __name__ == "__main__":
    main()
