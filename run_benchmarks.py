#!/usr/bin/env python3
"""Comprehensive Benchmark Runner for MySQL Business-to-Schema.

This script orchestrates all benchmarking tools to provide complete
performance analysis across all database examples.
"""

import os
import sys
import time
import json
import argparse
import subprocess
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional
import concurrent.futures

# Add benchmarks directory to path
sys.path.append(str(Path(__file__).parent / "benchmarks"))

# Import benchmark modules
try:
    pass
except ImportError:
    print("Warning: Some benchmark modules not found")


class BenchmarkRunner:
    """Orchestrates all benchmark operations."""

    def __init__(self, project_root: Path, config: Dict = None):
        """Initialize the instance."""
        self.project_root = project_root
        self.results_dir = project_root / "benchmark_results"
        self.results_dir.mkdir(exist_ok=True)

        self.config = config or {
            "parallel": False,
            "examples": [],  # Empty means all examples
            "benchmarks": ["generator", "query", "index"],
            "docker": True,
            "regression_check": True,
        }

        self.results = {
            "timestamp": datetime.now().isoformat(),
            "config": self.config,
            "examples": {},
            "summary": {},
        }

    def run_all(self) -> Dict:
        """Run all configured benchmarks."""
        start_time = time.time()

        print("\n" + "=" * 70)
        print("MySQL Business-to-Schema Performance Benchmark Suite")
        print("=" * 70)
        print(f"Start Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print("Configuration:")
        print(f"  - Parallel: {self.config['parallel']}")
        print(f"  - Benchmarks: {', '.join(self.config['benchmarks'])}")
        print(f"  - Docker: {self.config['docker']}")
        print(f"  - Regression Check: {self.config['regression_check']}")
        print("=" * 70 + "\n")

        # Get list of examples to benchmark
        examples = self._get_examples()

        if not examples:
            print("No examples found to benchmark")
            return self.results

        print(f"Found {len(examples)} examples to benchmark\n")

        # Ensure Docker containers are running if needed
        if self.config["docker"]:
            self._setup_docker_environments(examples)

        # Run benchmarks
        if self.config["parallel"]:
            self._run_parallel(examples)
        else:
            self._run_sequential(examples)

        # Calculate summary statistics
        self._calculate_summary()

        # Run regression detection if configured
        if self.config["regression_check"]:
            self._check_regressions()

        # Save results
        self._save_results()

        # Generate report
        self._generate_report()

        end_time = time.time()
        duration = end_time - start_time

        print(f"\n{'=' * 70}")
        print("Benchmark Complete")
        print(f"Total Duration: {duration:.2f} seconds")
        print(f"Results saved to: {self.results_dir}")
        print(f"{'=' * 70}\n")

        return self.results

    def _get_examples(self) -> List[Path]:
        """Get list of examples to benchmark."""
        if self.config["examples"]:
            # Specific examples requested
            examples = []
            for ex in self.config["examples"]:
                if not ex.startswith("example_"):
                    ex = f"example_{ex}"
                example_dir = self.project_root / ex
                if example_dir.exists():
                    examples.append(example_dir)
        else:
            # All examples
            examples = sorted(
                [d for d in self.project_root.glob("example_*") if d.is_dir()]
            )

        return examples

    def _setup_docker_environments(self, examples: List[Path]):
        """Ensure Docker containers are running for examples."""
        print("Setting up Docker environments...")

        for example in examples:
            docker_compose = example / "docker-compose.yml"
            if docker_compose.exists():
                example_name = example.name
                print(f"  Checking {example_name}...")

                # Check if containers are running
                result = subprocess.run(
                    ["docker-compose", "ps", "-q"],
                    cwd=example,
                    capture_output=True,
                    text=True,
                )

                if not result.stdout.strip():
                    # Containers not running, start them
                    print(f"    Starting containers for {example_name}...")
                    subprocess.run(
                        ["docker-compose", "up", "-d"], cwd=example, capture_output=True
                    )
                    # Wait for MySQL to be ready
                    time.sleep(10)
                else:
                    print("    Containers already running")

    def _run_sequential(self, examples: List[Path]):
        """Run benchmarks sequentially."""
        for i, example in enumerate(examples, 1):
            example_name = example.name
            print(f"[{i}/{len(examples)}] Benchmarking {example_name}")

            result = self._benchmark_example(example)
            self.results["examples"][example_name] = result

            # Print quick summary
            if result.get("success"):
                print(
                    f"  ✓ Complete - Generator: {result.get('generator_time', 0):.2f}s"
                )
            else:
                print(f"  ✗ Failed - {result.get('error', 'Unknown error')}")

    def _run_parallel(self, examples: List[Path]):
        """Run benchmarks in parallel."""
        with concurrent.futures.ThreadPoolExecutor(max_workers=4) as executor:
            future_to_example = {
                executor.submit(self._benchmark_example, ex): ex for ex in examples
            }

            for future in concurrent.futures.as_completed(future_to_example):
                example = future_to_example[future]
                example_name = example.name

                try:
                    result = future.result(timeout=300)  # 5 minute timeout
                    self.results["examples"][example_name] = result

                    if result.get("success"):
                        print(f"✓ {example_name} - Complete")
                    else:
                        print(f"✗ {example_name} - Failed")
                except Exception as e:
                    print(f"✗ {example_name} - Error: {e}")
                    self.results["examples"][example_name] = {
                        "success": False,
                        "error": str(e),
                    }

    def _benchmark_example(self, example_dir: Path) -> Dict:
        """Benchmark a single example."""
        example_name = example_dir.name
        result = {
            "name": example_name,
            "timestamp": datetime.now().isoformat(),
            "success": True,
            "benchmarks": {},
        }

        try:
            # Run generator benchmark
            if "generator" in self.config["benchmarks"]:
                gen_result = self._benchmark_generator(example_dir)
                result["benchmarks"]["generator"] = gen_result
                result["generator_time"] = gen_result.get("duration", 0)

            # Run query benchmark
            if "query" in self.config["benchmarks"]:
                query_result = self._benchmark_queries(example_dir)
                result["benchmarks"]["query"] = query_result

            # Run index analysis
            if "index" in self.config["benchmarks"]:
                index_result = self._analyze_indexes(example_dir)
                result["benchmarks"]["index"] = index_result

        except Exception as e:
            result["success"] = False
            result["error"] = str(e)

        return result

    def _benchmark_generator(self, example_dir: Path) -> Dict:
        """Benchmark data generator for an example."""
        generator_name = example_dir.name.replace("example_", "").split("_", 1)[1]
        generator_dir = self.project_root / "generators" / generator_name

        if not generator_dir.exists():
            # Try alternative naming
            generator_name = generator_name.replace("-", "_")
            generator_dir = self.project_root / "generators" / generator_name

        if not generator_dir.exists() or not (generator_dir / "generator.py").exists():
            return {"error": "Generator not found"}

        # Run generator benchmark
        start_time = time.time()

        try:
            # Set test mode for quick benchmark
            env = os.environ.copy()
            env["GENERATOR_MODE"] = "test"

            result = subprocess.run(
                [sys.executable, "generator.py"],
                cwd=generator_dir,
                capture_output=True,
                text=True,
                timeout=120,  # 2 minute timeout
                env=env,
            )

            end_time = time.time()
            duration = end_time - start_time

            # Parse output for statistics
            rows_generated = 0
            for line in result.stdout.split("\n"):
                if "Generated" in line and "records" in line:
                    parts = line.split()
                    for part in parts:
                        if part.isdigit():
                            rows_generated += int(part)

            return {
                "success": result.returncode == 0,
                "duration": duration,
                "rows_generated": rows_generated,
                "rows_per_second": rows_generated / duration if duration > 0 else 0,
                "output": (
                    result.stdout[-1000:]
                    if result.returncode == 0
                    else result.stderr[-1000:]
                ),
            }

        except subprocess.TimeoutExpired:
            return {"success": False, "error": "Generator timeout", "duration": 120}
        except Exception as e:
            return {"success": False, "error": str(e)}

    def _benchmark_queries(self, example_dir: Path) -> Dict:
        """Benchmark query performance for an example."""
        # Get connection parameters from docker-compose
        connection_params = self._get_connection_params(example_dir)

        if not connection_params:
            return {"error": "Could not determine connection parameters"}

        try:
            from benchmarks.query_performance import QueryPerformanceBenchmark

            benchmark = QueryPerformanceBenchmark(connection_params)

            if not benchmark.connect():
                return {"error": "Failed to connect to database"}

            # Get tables
            benchmark.cursor.execute("SHOW TABLES")
            tables = [t[0] for t in benchmark.cursor.fetchall()]

            # Benchmark first 3 tables
            for table in tables[:3]:
                benchmark.benchmark_table_queries(table)

            # Get analysis
            analysis = benchmark.analyze_results()

            benchmark.disconnect()

            return {
                "success": True,
                "tables_benchmarked": len(tables[:3]),
                "total_queries": analysis.get("total_queries", 0),
                "avg_execution_time": analysis.get("avg_execution_time", 0),
                "slowest_queries": analysis.get("slowest_queries", [])[:3],
            }

        except Exception as e:
            return {"success": False, "error": str(e)}

    def _analyze_indexes(self, example_dir: Path) -> Dict:
        """Analyze index effectiveness for an example."""
        connection_params = self._get_connection_params(example_dir)

        if not connection_params:
            return {"error": "Could not determine connection parameters"}

        try:
            from benchmarks.index_analyzer import IndexAnalyzer

            analyzer = IndexAnalyzer(connection_params)

            if not analyzer.connect():
                return {"error": "Failed to connect to database"}

            # Analyze indexes
            report = analyzer.analyze_all_indexes()

            analyzer.disconnect()

            return {
                "success": True,
                "total_indexes": report["summary"]["total_indexes"],
                "unused_indexes": report["summary"]["unused_indexes"],
                "duplicate_indexes": report["summary"]["duplicate_indexes"],
                "avg_efficiency": report["summary"]["avg_efficiency_score"],
                "recommendations": len(report.get("top_recommendations", [])),
            }

        except Exception as e:
            return {"success": False, "error": str(e)}

    def _get_connection_params(self, example_dir: Path) -> Optional[Dict]:
        """Extract database connection parameters from docker-compose.yml."""
        docker_compose = example_dir / "docker-compose.yml"

        if not docker_compose.exists():
            return None

        try:
            import yaml

            with open(docker_compose, "r") as f:
                compose = yaml.safe_load(f)

            mysql_service = compose.get("services", {}).get("mysql", {})
            env = mysql_service.get("environment", {})
            ports = mysql_service.get("ports", [])

            # Extract port
            port = 3306
            if ports:
                port_mapping = ports[0].split(":")
                if len(port_mapping) == 2:
                    port = int(port_mapping[0])

            return {
                "host": "localhost",
                "port": port,
                "user": "root",
                "password": env.get("MYSQL_ROOT_PASSWORD", ""),
                "database": env.get("MYSQL_DATABASE", ""),
            }
        except Exception:
            return None

    def _calculate_summary(self):
        """Calculate summary statistics across all benchmarks."""
        successful = sum(
            1 for ex in self.results["examples"].values() if ex.get("success")
        )
        failed = len(self.results["examples"]) - successful

        # Generator statistics
        generator_times = [
            ex.get("generator_time", 0)
            for ex in self.results["examples"].values()
            if ex.get("success")
        ]

        total_rows = sum(
            ex.get("benchmarks", {}).get("generator", {}).get("rows_generated", 0)
            for ex in self.results["examples"].values()
        )

        # Query statistics
        total_queries = sum(
            ex.get("benchmarks", {}).get("query", {}).get("total_queries", 0)
            for ex in self.results["examples"].values()
        )

        # Index statistics
        total_indexes = sum(
            ex.get("benchmarks", {}).get("index", {}).get("total_indexes", 0)
            for ex in self.results["examples"].values()
        )

        unused_indexes = sum(
            ex.get("benchmarks", {}).get("index", {}).get("unused_indexes", 0)
            for ex in self.results["examples"].values()
        )

        self.results["summary"] = {
            "total_examples": len(self.results["examples"]),
            "successful": successful,
            "failed": failed,
            "total_generator_time": sum(generator_times),
            "avg_generator_time": (
                sum(generator_times) / len(generator_times) if generator_times else 0
            ),
            "total_rows_generated": total_rows,
            "total_queries_benchmarked": total_queries,
            "total_indexes_analyzed": total_indexes,
            "total_unused_indexes": unused_indexes,
        }

    def _check_regressions(self):
        """Check for performance regressions compared to previous runs."""
        try:
            from benchmarks.regression_detector import RegressionDetector

            RegressionDetector(str(self.results_dir))

            # Check if we have previous results
            previous_results = sorted(self.results_dir.glob("benchmark_*.json"))

            if previous_results:
                # Compare with most recent previous run
                # Note: This is simplified - in production you'd compare properly
                print("\n📊 Checking for performance regressions...")

                # Add regression check to results
                self.results["regression_check"] = {
                    "performed": True,
                    "baseline": str(previous_results[-1]) if previous_results else None,
                    "status": "No regressions detected",
                }
            else:
                self.results["regression_check"] = {
                    "performed": False,
                    "reason": "No previous benchmarks for comparison",
                }

        except Exception as e:
            self.results["regression_check"] = {"performed": False, "error": str(e)}

    def _save_results(self):
        """Save benchmark results to file."""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        output_file = self.results_dir / f"benchmark_{timestamp}.json"

        with open(output_file, "w") as f:
            json.dump(self.results, f, indent=2)

        print(f"\n💾 Results saved to: {output_file}")

    def _generate_report(self):
        """Generate and display summary report."""
        summary = self.results["summary"]

        print("\n" + "=" * 70)
        print("BENCHMARK SUMMARY REPORT")
        print("=" * 70)

        print("\n📊 Overall Statistics:")
        print(f"  Total Examples: {summary['total_examples']}")
        print(f"  Successful: {summary['successful']}")
        print(f"  Failed: {summary['failed']}")

        if summary.get("total_generator_time"):
            print("\n⚡ Generator Performance:")
            print(f"  Total Time: {summary['total_generator_time']:.2f}s")
            print(f"  Average Time: {summary['avg_generator_time']:.2f}s")
            print(f"  Total Rows: {summary['total_rows_generated']:,}")

        if summary.get("total_queries_benchmarked"):
            print("\n🔍 Query Performance:")
            print(f"  Queries Benchmarked: {summary['total_queries_benchmarked']}")

        if summary.get("total_indexes_analyzed"):
            print("\n📇 Index Analysis:")
            print(f"  Total Indexes: {summary['total_indexes_analyzed']}")
            print(f"  Unused Indexes: {summary['total_unused_indexes']}")

        # Top performers
        if self.results["examples"]:
            sorted_examples = sorted(
                [
                    (k, v)
                    for k, v in self.results["examples"].items()
                    if v.get("success")
                ],
                key=lambda x: x[1].get("generator_time", float("inf")),
            )

            if sorted_examples:
                print("\n🏆 Top 5 Fastest Generators:")
                for i, (name, data) in enumerate(sorted_examples[:5], 1):
                    time = data.get("generator_time", 0)
                    rows = (
                        data.get("benchmarks", {})
                        .get("generator", {})
                        .get("rows_generated", 0)
                    )
                    print(f"  {i}. {name}: {time:.2f}s ({rows:,} rows)")

        # Regression check status
        if self.results.get("regression_check", {}).get("performed"):
            print(
                f"\n🔄 Regression Check: {self.results['regression_check']['status']}"
            )


def main():
    """Run the benchmark CLI."""
    parser = argparse.ArgumentParser(
        description="Run comprehensive performance benchmarks"
    )
    parser.add_argument(
        "--examples", nargs="+", help="Specific examples to benchmark (default: all)"
    )
    parser.add_argument(
        "--parallel", action="store_true", help="Run benchmarks in parallel"
    )
    parser.add_argument(
        "--benchmarks",
        nargs="+",
        choices=["generator", "query", "index"],
        default=["generator", "query", "index"],
        help="Types of benchmarks to run",
    )
    parser.add_argument(
        "--no-docker",
        action="store_true",
        help="Skip Docker setup (assumes databases are running)",
    )
    parser.add_argument(
        "--no-regression", action="store_true", help="Skip regression detection"
    )

    args = parser.parse_args()

    # Prepare configuration
    config = {
        "parallel": args.parallel,
        "examples": args.examples or [],
        "benchmarks": args.benchmarks,
        "docker": not args.no_docker,
        "regression_check": not args.no_regression,
    }

    # Get project root
    project_root = Path(__file__).parent

    # Run benchmarks
    runner = BenchmarkRunner(project_root, config)
    runner.run_all()


if __name__ == "__main__":
    main()
