#!/usr/bin/env python3
"""Performance Benchmark Utility for MySQL Generators.

This script provides detailed performance analysis and benchmarking
for the data generators, helping identify optimization opportunities.
"""

import sys
import time
import psutil
import json
from datetime import datetime
from pathlib import Path
import subprocess
import argparse


from typing import Any, List


class GeneratorBenchmark:
    """Benchmark utility for generator performance analysis."""

    def __init__(self, output_file="benchmark_results.json"):
        """Initialize the instance."""
        self.results: List[Any] = []
        self.output_file = output_file
        self.process = psutil.Process()

    def measure_generator(self, generator_name, test_mode=True):
        """Measure performance metrics for a single generator.

        Returns dict with:
        - duration: Total execution time
        - memory_peak: Peak memory usage
        - cpu_percent: Average CPU usage
        - records_generated: Number of records created
        """
        print(
            f"\nBenchmarking {generator_name} ({'TEST' if test_mode else 'FULL'} mode)..."
        )

        # Initial measurements
        self.process.cpu_percent()  # Initialize CPU monitoring
        initial_memory = self.process.memory_info().rss / 1024 / 1024  # MB

        # Prepare command
        generator_dir = Path(__file__).parent / generator_name
        if test_mode and (generator_dir / "test_generator.py").exists():
            script = "test_generator.py"
        else:
            script = "generator.py"

        # Start monitoring
        start_time = time.time()
        cpu_samples = []
        memory_samples = []

        try:
            # Run generator as subprocess
            cmd = [sys.executable, str(generator_dir / script)]
            process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                cwd=str(generator_dir),
            )

            # Monitor while running
            while process.poll() is None:
                cpu_samples.append(self.process.cpu_percent())
                memory_samples.append(self.process.memory_info().rss / 1024 / 1024)
                time.sleep(0.1)  # Sample every 100ms

            stdout, stderr = process.communicate()
            duration = time.time() - start_time

            # Parse output for record count
            records_generated = self.parse_records_count(stdout)

            # Calculate metrics
            metrics = {
                "generator": generator_name,
                "mode": "test" if test_mode else "full",
                "success": process.returncode == 0,
                "duration": round(duration, 2),
                "memory_initial_mb": round(initial_memory, 2),
                "memory_peak_mb": round(
                    max(memory_samples) if memory_samples else initial_memory, 2
                ),
                "memory_delta_mb": round(
                    (max(memory_samples) if memory_samples else initial_memory)
                    - initial_memory,
                    2,
                ),
                "cpu_average": round(
                    sum(cpu_samples) / len(cpu_samples) if cpu_samples else 0, 2
                ),
                "cpu_peak": round(max(cpu_samples) if cpu_samples else 0, 2),
                "records_generated": records_generated,
                "records_per_second": round(
                    records_generated / duration if duration > 0 else 0, 2
                ),
                "timestamp": datetime.now().isoformat(),
            }

            if process.returncode != 0:
                metrics["error"] = stderr[:500]  # First 500 chars of error

            return metrics

        except Exception as e:
            return {
                "generator": generator_name,
                "mode": "test" if test_mode else "full",
                "success": False,
                "error": str(e),
                "timestamp": datetime.now().isoformat(),
            }

    def parse_records_count(self, output):
        """Extract total records count from generator output."""
        total = 0
        for line in output.split("\n"):
            # Look for patterns like "Saved 1000 records" or "Generated 1000 users"
            if "records" in line.lower() or "generated" in line.lower():
                import re

                numbers = re.findall(r"\d+", line)
                if numbers:
                    # Take the largest number as it's likely the count
                    count = max(int(n) for n in numbers)
                    if count > total and count < 10000000:  # Sanity check
                        total = count
        return total

    def benchmark_all(self, generators, test_mode=True):
        """Benchmark multiple generators."""
        results = []

        print(f"\n{'='*60}")
        print("GENERATOR PERFORMANCE BENCHMARK")
        print(f"Mode: {'TEST' if test_mode else 'FULL'}")
        print(f"Generators: {len(generators)}")
        print(f"{'='*60}")

        for i, generator in enumerate(generators, 1):
            print(f"\n[{i}/{len(generators)}] {generator}")
            metrics = self.measure_generator(generator, test_mode)
            results.append(metrics)

            if metrics["success"]:
                print(f"  ✓ Duration: {metrics['duration']}s")
                print(f"  ✓ Memory Peak: {metrics['memory_peak_mb']}MB")
                print(f"  ✓ Records/sec: {metrics['records_per_second']}")
            else:
                print(f"  ✗ Failed: {metrics.get('error', 'Unknown error')}")

        self.results = results
        self.save_results()
        self.print_summary()

        return results

    def save_results(self):
        """Save benchmark results to JSON file."""
        with open(self.output_file, "w") as f:
            json.dump(self.results, f, indent=2)
        print(f"\nResults saved to: {self.output_file}")

    def print_summary(self):
        """Print benchmark summary with rankings."""
        if not self.results:
            return

        successful = [r for r in self.results if r["success"]]

        if not successful:
            print("\nNo successful benchmarks to summarize")
            return

        print(f"\n{'='*60}")
        print("BENCHMARK SUMMARY")
        print(f"{'='*60}")

        # Fastest generators
        print("\n⚡ Fastest Generators (by duration):")
        by_duration = sorted(successful, key=lambda x: x["duration"])[:5]
        for i, r in enumerate(by_duration, 1):
            print(f"  {i}. {r['generator']:20} {r['duration']:8.2f}s")

        # Most efficient (records per second)
        print("\n📊 Most Efficient (records/second):")
        by_efficiency = sorted(
            successful, key=lambda x: x["records_per_second"], reverse=True
        )[:5]
        for i, r in enumerate(by_efficiency, 1):
            print(f"  {i}. {r['generator']:20} {r['records_per_second']:8.0f} rec/s")

        # Memory usage
        print("\n💾 Lowest Memory Usage:")
        by_memory = sorted(successful, key=lambda x: x["memory_peak_mb"])[:5]
        for i, r in enumerate(by_memory, 1):
            print(f"  {i}. {r['generator']:20} {r['memory_peak_mb']:8.1f} MB")

        # Overall statistics
        print("\n📈 Overall Statistics:")
        avg_duration = sum(r["duration"] for r in successful) / len(successful)
        avg_memory = sum(r["memory_peak_mb"] for r in successful) / len(successful)
        avg_efficiency = sum(r["records_per_second"] for r in successful) / len(
            successful
        )
        total_records = sum(r["records_generated"] for r in successful)

        print(f"  Average Duration: {avg_duration:.2f}s")
        print(f"  Average Memory: {avg_memory:.1f}MB")
        print(f"  Average Efficiency: {avg_efficiency:.0f} records/s")
        print(f"  Total Records Generated: {total_records:,}")

        # Failed generators
        failed = [r for r in self.results if not r["success"]]
        if failed:
            print(f"\n⚠️ Failed Generators: {len(failed)}")
            for r in failed:
                print(f"  - {r['generator']}: {r.get('error', 'Unknown')[:50]}")

        print(f"{'='*60}\n")

    def compare_modes(self, generator):
        """Compare test vs full mode for a generator."""
        print(f"\nComparing modes for {generator}...")

        test_metrics = self.measure_generator(generator, test_mode=True)
        full_metrics = self.measure_generator(generator, test_mode=False)

        print(f"\n{'='*40}")
        print(f"MODE COMPARISON: {generator}")
        print(f"{'='*40}")
        print(f"{'Metric':<20} {'TEST':>10} {'FULL':>10} {'Ratio':>8}")
        print(f"{'-'*48}")

        if test_metrics["success"] and full_metrics["success"]:
            metrics_to_compare = [
                ("Duration (s)", "duration"),
                ("Memory (MB)", "memory_peak_mb"),
                ("Records", "records_generated"),
                ("Records/sec", "records_per_second"),
            ]

            for label, key in metrics_to_compare:
                test_val = test_metrics[key]
                full_val = full_metrics[key]
                ratio = full_val / test_val if test_val > 0 else 0

                print(f"{label:<20} {test_val:>10.1f} {full_val:>10.1f} {ratio:>8.1f}x")

        print(f"{'='*40}\n")


def main():
    """CLI interface for benchmark utility."""
    parser = argparse.ArgumentParser(description="Benchmark MySQL data generators")

    parser.add_argument(
        "generators", nargs="*", help="Generators to benchmark (leave empty for all)"
    )

    parser.add_argument(
        "--test", "-t", action="store_true", help="Benchmark in test mode (default)"
    )

    parser.add_argument(
        "--full",
        "-f",
        action="store_true",
        help="Benchmark in full mode (warning: slow)",
    )

    parser.add_argument(
        "--compare",
        "-c",
        metavar="GENERATOR",
        help="Compare test vs full mode for a generator",
    )

    parser.add_argument(
        "--output",
        "-o",
        default="benchmark_results.json",
        help="Output file for results (default: benchmark_results.json)",
    )

    args = parser.parse_args()

    # Get list of all generators
    generators_dir = Path(__file__).parent
    all_generators = [
        d.name
        for d in generators_dir.iterdir()
        if d.is_dir() and (d / "generator.py").exists()
    ]

    benchmark = GeneratorBenchmark(output_file=args.output)

    if args.compare:
        if args.compare not in all_generators:
            print(f"Unknown generator: {args.compare}")
            return 1
        benchmark.compare_modes(args.compare)
    else:
        # Determine which generators to benchmark
        if args.generators:
            generators = [g for g in args.generators if g in all_generators]
        else:
            # Default to a subset for quick benchmarking
            generators = ["clinic", "ecommerce", "iot_bins", "smart_energy", "fintech"]
            print(f"No generators specified, using default subset: {generators}")

        # Determine mode
        test_mode = not args.full  # Default to test mode

        benchmark.benchmark_all(generators, test_mode=test_mode)

    return 0


if __name__ == "__main__":
    sys.exit(main())
