#!/usr/bin/env python3
"""
Unified Generator Runner for MySQL Business-to-Schema Examples

This script provides a centralized way to run any or all data generators
with configurable modes (test/full) and detailed progress tracking.
"""

import os
import sys
import time
import argparse
import importlib.util
import traceback
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional, Tuple

# Generator metadata
GENERATORS = {
    "clinic": {
        "name": "Medical Clinic Management",
        "example": "example_01",
        "tables": 18,
        "description": "Healthcare facility with appointments and medical records",
    },
    "ecommerce": {
        "name": "E-Commerce Platform",
        "example": "example_02",
        "tables": 16,
        "description": "Online retail with orders, inventory, and reviews",
    },
    "education": {
        "name": "Education Platform",
        "example": "example_03",
        "tables": 13,
        "description": "Online learning with courses and student progress",
    },
    "real_estate": {
        "name": "Real Estate Management",
        "example": "example_04",
        "tables": 14,
        "description": "Property listings and rental management",
    },
    "event_ticketing": {
        "name": "Event Ticketing System",
        "example": "example_05",
        "tables": 13,
        "description": "Concert and event ticket sales platform",
    },
    "smart_agriculture": {
        "name": "Smart Agriculture",
        "example": "example_06",
        "tables": 21,
        "description": "IoT-enabled farm management with sensors",
    },
    "fleet_management": {
        "name": "Fleet Management",
        "example": "example_07",
        "tables": 22,
        "description": "Vehicle tracking and logistics management",
    },
    "iot_bins": {
        "name": "Smart Waste Management",
        "example": "example_08",
        "tables": 15,
        "description": "IoT waste collection optimization",
    },
    "streaming_ml": {
        "name": "Streaming ML Platform",
        "example": "example_09",
        "tables": 29,
        "description": "Real-time machine learning pipeline",
    },
    "fintech": {
        "name": "FinTech Platform",
        "example": "example_10",
        "tables": 23,
        "description": "Digital banking and payment processing",
    },
    "social_media": {
        "name": "Social Media Platform",
        "example": "example_11",
        "tables": 28,
        "description": "Social network with posts and interactions",
    },
    "smart_energy": {
        "name": "Smart Energy Grid",
        "example": "example_12",
        "tables": 18,
        "description": "Smart grid energy management system",
    },
    "healthcare_iot": {
        "name": "Healthcare IoT",
        "example": "example_13",
        "tables": 24,
        "description": "Remote patient monitoring with IoT devices",
    },
    "logistics": {
        "name": "Logistics & Supply Chain",
        "example": "example_14",
        "tables": 24,
        "description": "Warehouse and supply chain management",
    },
    "industrial_iot": {
        "name": "Industrial IoT",
        "example": "example_15",
        "tables": 20,
        "description": "Manufacturing and industrial monitoring",
    },
}


class GeneratorRunner:
    """Manages execution of data generators"""

    def __init__(self, output_dir: str = "output", verbose: bool = True):
        self.output_dir = Path(output_dir)
        self.verbose = verbose
        self.results = {}

    def load_generator(self, name: str, test_mode: bool = False):
        """Dynamically load a generator module"""
        generator_path = Path(__file__).parent / name

        if test_mode:
            script_name = "test_generator.py"
        else:
            script_name = "generator.py"

        script_path = generator_path / script_name

        if not script_path.exists():
            if test_mode:
                # Fall back to regular generator if no test version
                script_path = generator_path / "generator.py"
                if not script_path.exists():
                    raise FileNotFoundError(f"Generator not found: {name}")
            else:
                raise FileNotFoundError(f"Generator not found: {name}")

        # Load the module
        spec = importlib.util.spec_from_file_location(f"{name}_generator", script_path)
        module = importlib.util.module_from_spec(spec)
        sys.modules[f"{name}_generator"] = module

        return spec, module

    def run_generator(
        self, name: str, test_mode: bool = False
    ) -> Tuple[bool, float, str]:
        """
        Run a single generator
        Returns: (success, duration, message)
        """
        start_time = time.time()

        try:
            if self.verbose:
                info = GENERATORS[name]
                print(f"\n{'='*60}")
                print(f"Running: {info['name']} ({name})")
                print(f"Example: {info['example']}")
                print(f"Tables: {info['tables']}")
                print(f"Mode: {'TEST' if test_mode else 'FULL'}")
                print(f"Description: {info['description']}")
                print(f"{'='*60}")

            # Change to generator directory
            generator_dir = Path(__file__).parent / name
            original_dir = os.getcwd()
            os.chdir(generator_dir)

            # Redirect output to the configured output directory
            output_path = self.output_dir / name
            output_path.mkdir(parents=True, exist_ok=True)

            # Save original sys.path
            original_path = sys.path.copy()
            sys.path.insert(0, str(generator_dir))

            try:
                # Load and execute the generator
                spec, module = self.load_generator(name, test_mode)
                spec.loader.exec_module(module)

                duration = time.time() - start_time
                return True, duration, "Success"

            finally:
                # Restore original state
                sys.path = original_path
                os.chdir(original_dir)

        except Exception as e:
            duration = time.time() - start_time
            error_msg = f"Error: {str(e)}"
            if self.verbose:
                print(f"\n[ERROR] Failed to run {name}:")
                traceback.print_exc()
            return False, duration, error_msg

    def run_all(self, test_mode: bool = False, parallel: bool = False) -> Dict:
        """Run all generators"""
        print(f"\n{'='*60}")
        print(f"Running ALL Generators")
        print(f"Total: {len(GENERATORS)} generators")
        print(f"Mode: {'TEST' if test_mode else 'FULL'}")
        print(f"{'='*60}")

        results = {}
        total_start = time.time()
        successful = 0
        failed = 0

        for i, name in enumerate(GENERATORS.keys(), 1):
            print(f"\n[{i}/{len(GENERATORS)}] Processing {name}...")
            success, duration, message = self.run_generator(name, test_mode)

            results[name] = {
                "success": success,
                "duration": duration,
                "message": message,
            }

            if success:
                successful += 1
                print(f"    [OK] Completed in {duration:.2f}s")
            else:
                failed += 1
                print(f"    [FAILED] Failed: {message}")

        total_duration = time.time() - total_start

        # Print summary
        print(f"\n{'='*60}")
        print(f"SUMMARY")
        print(f"{'='*60}")
        print(f"Total Time: {total_duration:.2f}s")
        print(f"Successful: {successful}/{len(GENERATORS)}")
        print(f"Failed: {failed}/{len(GENERATORS)}")

        if failed > 0:
            print(f"\nFailed generators:")
            for name, result in results.items():
                if not result["success"]:
                    print(f"  - {name}: {result['message']}")

        print(f"{'='*60}\n")

        self.results = results
        return results

    def benchmark(self, generators: List[str] = None) -> Dict:
        """Benchmark generators in both test and full modes"""
        if generators is None:
            generators = list(GENERATORS.keys())

        print(f"\n{'='*60}")
        print(f"BENCHMARKING GENERATORS")
        print(f"{'='*60}")

        benchmarks = {}

        for name in generators:
            if name not in GENERATORS:
                print(f"Skipping unknown generator: {name}")
                continue

            print(f"\nBenchmarking {name}...")

            # Test mode
            print(f"  Running test mode...")
            test_success, test_duration, test_msg = self.run_generator(
                name, test_mode=True
            )

            # Full mode (optional - can be slow)
            full_success = False
            full_duration = 0
            full_msg = "Skipped"

            benchmarks[name] = {
                "test": {
                    "success": test_success,
                    "duration": test_duration,
                    "message": test_msg,
                },
                "full": {
                    "success": full_success,
                    "duration": full_duration,
                    "message": full_msg,
                },
            }

            print(f"  Test mode: {test_duration:.2f}s - {test_msg}")

        return benchmarks


def main():
    """Main CLI interface"""
    parser = argparse.ArgumentParser(
        description="MySQL Business-to-Schema Generator Runner",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Run a single generator in test mode
  python run_generators.py clinic --test

  # Run multiple generators
  python run_generators.py clinic ecommerce fintech

  # Run all generators in test mode
  python run_generators.py --all --test

  # List all available generators
  python run_generators.py --list

  # Benchmark generators
  python run_generators.py --benchmark clinic fintech
        """,
    )

    parser.add_argument(
        "generators",
        nargs="*",
        choices=list(GENERATORS.keys()),
        help="Generators to run (leave empty with --all to run all)",
    )

    parser.add_argument(
        "--test",
        "-t",
        action="store_true",
        help="Run in test mode (reduced data volume)",
    )

    parser.add_argument("--all", "-a", action="store_true", help="Run all generators")

    parser.add_argument(
        "--list", "-l", action="store_true", help="List all available generators"
    )

    parser.add_argument(
        "--output",
        "-o",
        default="output",
        help="Output directory for generated files (default: output)",
    )

    parser.add_argument(
        "--quiet", "-q", action="store_true", help="Reduce output verbosity"
    )

    parser.add_argument(
        "--benchmark", "-b", action="store_true", help="Benchmark specified generators"
    )

    args = parser.parse_args()

    # List generators
    if args.list:
        print(f"\n{'='*60}")
        print("Available Generators")
        print(f"{'='*60}")
        for name, info in GENERATORS.items():
            print(f"\n{name:20} {info['example']:12} ({info['tables']} tables)")
            print(f"  {info['name']}")
            print(f"  {info['description']}")
        print(f"\n{'='*60}")
        return 0

    # Initialize runner
    runner = GeneratorRunner(output_dir=args.output, verbose=not args.quiet)

    # Determine which generators to run
    if args.all:
        if args.benchmark:
            results = runner.benchmark()
        else:
            results = runner.run_all(test_mode=args.test)
    elif args.generators:
        if args.benchmark:
            results = runner.benchmark(args.generators)
        else:
            results = {}
            for name in args.generators:
                if name not in GENERATORS:
                    print(f"Unknown generator: {name}")
                    continue
                success, duration, message = runner.run_generator(name, args.test)
                results[name] = {
                    "success": success,
                    "duration": duration,
                    "message": message,
                }
    else:
        parser.print_help()
        return 1

    # Return exit code based on results
    if results and all(r.get("success", False) for r in results.values()):
        return 0
    else:
        return 1


if __name__ == "__main__":
    sys.exit(main())
