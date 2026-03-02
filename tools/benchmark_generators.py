#!/usr/bin/env python3
"""Generator Performance Benchmarking Tool.

Benchmarks all data generators and produces performance reports.
"""

import os
import sys
import time
import json
import argparse
import subprocess
from datetime import datetime
from pathlib import Path
from typing import Dict, List
import statistics
import multiprocessing
from concurrent.futures import ProcessPoolExecutor, as_completed


class BenchmarkResult:
    """Container for benchmark results."""

    def __init__(self, name: str):
        """Initialize the instance."""
        self.name = name
        self.start_time = 0
        self.end_time = 0
        self.duration = 0
        self.rows_generated = 0
        self.records_per_second = 0
        self.exit_code = 0
        self.errors = []
        self.output_lines = []

    def to_dict(self) -> Dict:
        """Handle to dict."""
        return {
            "name": self.name,
            "duration": round(self.duration, 2),
            "rows_generated": self.rows_generated,
            "records_per_second": round(self.records_per_second, 2),
            "exit_code": self.exit_code,
            "success": self.exit_code == 0 and not self.errors,
            "errors": self.errors,
        }


def benchmark_generator(
    generator_path: Path, mode: str = "test", timeout: int = 300
) -> BenchmarkResult:
    """Benchmark a single generator."""
    generator_name = generator_path.name
    result = BenchmarkResult(generator_name)

    # Check if generator exists
    generator_file = generator_path / "generator.py"
    if not generator_file.exists():
        test_file = generator_path / "test_generator.py"
        if test_file.exists():
            generator_file = test_file
        else:
            result.errors.append(f"Generator not found: {generator_file}")
            return result

    try:
        env = os.environ.copy()
        env["GENERATOR_MODE"] = mode
        env["PYTHONPATH"] = str(generator_path.parent)

        result.start_time = time.time()

        # Run generator
        process = subprocess.Popen(
            [sys.executable, str(generator_file)],
            cwd=str(generator_path),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=env,
            text=True,
        )

        try:
            stdout, stderr = process.communicate(timeout=timeout)
            result.exit_code = process.returncode
        except subprocess.TimeoutExpired:
            process.kill()
            stdout, stderr = process.communicate()
            result.errors.append(f"Timeout after {timeout} seconds")
            result.exit_code = -1

        result.end_time = time.time()
        result.duration = result.end_time - result.start_time

        # Parse output for metrics
        if stdout:
            result.output_lines = stdout.split("\n")
            for line in result.output_lines:
                line_lower = line.lower()
                if "generated" in line_lower and (
                    "record" in line_lower or "row" in line_lower
                ):
                    # Try to extract number
                    parts = line.split()
                    for _, part in enumerate(parts):
                        if part.replace(",", "").isdigit():
                            num = int(part.replace(",", ""))
                            # Check if this looks like a row count (not a year or ID)
                            if num > 10 and num < 10000000:
                                result.rows_generated = max(result.rows_generated, num)

        # Calculate records per second
        if result.duration > 0 and result.rows_generated > 0:
            result.records_per_second = result.rows_generated / result.duration

        # Capture errors
        if stderr and process.returncode != 0:
            error_lines = stderr.split("\n")
            for line in error_lines:
                if line.strip():
                    result.errors.append(line.strip())

    except Exception as e:
        result.errors.append(f"Exception: {str(e)}")
        result.exit_code = -1

    return result


class BenchmarkSuite:
    """Orchestrate benchmarking of all generators."""

    def __init__(self, project_root: Path):
        """Initialize the instance."""
        self.project_root = project_root
        self.generators_dir = project_root / "generators"
        self.results = []
        self.start_time = None
        self.end_time = None

    def discover_generators(self) -> List[Path]:
        """Find all generator directories."""
        generators = []
        for item in self.generators_dir.iterdir():
            if item.is_dir() and not item.name.startswith("_"):
                # Check if it has generator.py or test_generator.py
                if (item / "generator.py").exists() or (
                    item / "test_generator.py"
                ).exists():
                    generators.append(item)
        return sorted(generators)

    def run(
        self, generators: List[str] = None, mode: str = "test", parallel: bool = False
    ):
        """Run benchmarks."""
        self.start_time = datetime.now()

        # Discover generators
        all_generators = self.discover_generators()
        if generators:
            # Filter to specified generators
            selected = []
            for gen_name in generators:
                for gen_path in all_generators:
                    if gen_name in gen_path.name:
                        selected.append(gen_path)
                        break
            all_generators = selected

        print("MySQL Business-to-Schema Generator Benchmarks")
        print("=" * 60)
        print(f"Generators: {len(all_generators)}")
        print(f"Mode: {mode}")
        print(f"Parallel: {parallel}")
        print("=" * 60)
        print()

        if parallel:
            self._run_parallel(all_generators, mode)
        else:
            self._run_sequential(all_generators, mode)

        self.end_time = datetime.now()
        self._print_summary()

    def _run_sequential(self, generators: List[Path], mode: str):
        """Run benchmarks one at a time."""
        for i, gen_path in enumerate(generators, 1):
            gen_name = gen_path.name
            print(f"[{i}/{len(generators)}] Benchmarking {gen_name}...", end=" ")

            result = benchmark_generator(gen_path, mode)
            self.results.append(result)

            if result.exit_code == 0 and not result.errors:
                print(f"[OK] {result.duration:.2f}s, {result.rows_generated} rows")
            else:
                print(
                    f"[FAIL] {result.errors[0] if result.errors else 'Unknown error'}"
                )

    def _run_parallel(self, generators: List[Path], mode: str):
        """Run benchmarks in parallel."""
        max_workers = min(4, multiprocessing.cpu_count())

        with ProcessPoolExecutor(max_workers=max_workers) as executor:
            futures = {
                executor.submit(benchmark_generator, gen, mode): gen.name
                for gen in generators
            }

            completed = 0
            for future in as_completed(futures):
                completed += 1
                gen_name = futures[future]
                try:
                    result = future.result(timeout=360)
                    self.results.append(result)

                    status = "[OK]" if result.exit_code == 0 else "[FAIL]"
                    print(f"[{completed}/{len(generators)}] {gen_name}: {status}")
                except Exception as e:
                    print(f"[{completed}/{len(generators)}] {gen_name}: [ERROR] {e}")

    def _print_summary(self):
        """Print benchmark summary."""
        duration = (self.end_time - self.start_time).total_seconds()

        print()
        print("=" * 60)
        print("Benchmark Summary")
        print("=" * 60)

        # Overall stats
        successful = [r for r in self.results if r.exit_code == 0 and not r.errors]
        failed = [r for r in self.results if r.exit_code != 0 or r.errors]

        print(f"Total: {len(self.results)} generators")
        print(f"Successful: {len(successful)}")
        print(f"Failed: {len(failed)}")
        print(f"Total Time: {duration:.2f}s")
        print()

        # Performance table
        if successful:
            print("Performance Results:")
            print("-" * 60)
            print(f"{'Generator':<25} {'Duration':<10} {'Rows':<10} {'Rows/sec':<10}")
            print("-" * 60)

            # Sort by performance
            sorted_results = sorted(
                successful, key=lambda x: x.records_per_second, reverse=True
            )

            for result in sorted_results:
                print(
                    f"{result.name:<25} {result.duration:<10.2f} {result.rows_generated:<10} {result.records_per_second:<10.2f}"
                )

            print("-" * 60)

            # Statistics
            durations = [r.duration for r in successful]
            rows = [r.rows_generated for r in successful]
            rates = [
                r.records_per_second for r in successful if r.records_per_second > 0
            ]

            print()
            print("Statistics:")
            print(f"  Average Duration: {statistics.mean(durations):.2f}s")
            print(f"  Total Rows Generated: {sum(rows):,}")
            if rates:
                print(f"  Average Rows/sec: {statistics.mean(rates):.2f}")
                print(f"  Best Rows/sec: {max(rates):.2f}")

        # Failed generators
        if failed:
            print()
            print("Failed Generators:")
            print("-" * 60)
            for result in failed:
                print(
                    f"  {result.name}: {result.errors[0] if result.errors else 'Exit code ' + str(result.exit_code)}"
                )

        # Save results
        self._save_results()

    def _save_results(self):
        """Save results to JSON file."""
        output_dir = self.project_root / "benchmark_results"
        output_dir.mkdir(exist_ok=True)

        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        output_file = output_dir / f"generator_benchmark_{timestamp}.json"

        data = {
            "timestamp": datetime.now().isoformat(),
            "duration": (self.end_time - self.start_time).total_seconds(),
            "results": [r.to_dict() for r in self.results],
        }

        with open(output_file, "w") as f:
            json.dump(data, f, indent=2)

        print()
        print(f"Results saved to: {output_file}")

    def compare_modes(self):
        """Compare test vs production mode performance."""
        print("Comparing Test vs Production Modes")
        print("=" * 60)

        generators = self.discover_generators()[:3]  # Test first 3 for comparison

        test_results = []
        prod_results = []

        print("Running in test mode...")
        for gen in generators:
            result = benchmark_generator(gen, "test", timeout=60)
            test_results.append(result)
            print(f"  {gen.name}: {result.duration:.2f}s")

        print("Running in production mode...")
        for gen in generators:
            result = benchmark_generator(gen, "production", timeout=300)
            prod_results.append(result)
            print(f"  {gen.name}: {result.duration:.2f}s")

        print()
        print("Comparison Results:")
        print("-" * 60)
        print(
            f"{'Generator':<20} {'Test Rows':<12} {'Prod Rows':<12} {'Scale Factor':<12}"
        )
        print("-" * 60)

        for test, prod in zip(test_results, prod_results):
            if test.rows_generated > 0:
                scale = prod.rows_generated / test.rows_generated
            else:
                scale = 0
            print(
                f"{test.name:<20} {test.rows_generated:<12} {prod.rows_generated:<12} {scale:<12.1f}x"
            )


def main():
    """Run entry point."""
    parser = argparse.ArgumentParser(description="Benchmark MySQL data generators")
    parser.add_argument(
        "--generators", nargs="+", help="Specific generators to benchmark"
    )
    parser.add_argument(
        "--mode",
        choices=["test", "production", "both"],
        default="test",
        help="Generator mode (default: test)",
    )
    parser.add_argument("--parallel", action="store_true", help="Run in parallel")
    parser.add_argument(
        "--compare", action="store_true", help="Compare test vs production modes"
    )

    args = parser.parse_args()

    # Get project root
    script_dir = Path(__file__).parent
    project_root = script_dir.parent

    suite = BenchmarkSuite(project_root)

    if args.compare:
        suite.compare_modes()
    elif args.mode == "both":
        # Run both modes
        print("Running TEST mode benchmarks:")
        print()
        suite.run(args.generators, "test", args.parallel)

        print()
        print("Running PRODUCTION mode benchmarks:")
        print()
        suite.results = []  # Reset results
        suite.run(args.generators, "production", args.parallel)
    else:
        suite.run(args.generators, args.mode, args.parallel)


if __name__ == "__main__":
    main()
