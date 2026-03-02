#!/usr/bin/env python3
"""Generator Performance Benchmarking Tool.

Benchmarks data generation performance across all generators,
measuring speed, memory usage, and efficiency.
"""

import sys
import time
import subprocess
import json
import psutil
import os
from pathlib import Path
from typing import Dict, List, Optional, Any
from datetime import datetime
import statistics
import tempfile
import shutil

# Add parent directory to path
sys.path.append(str(Path(__file__).parent.parent))

from benchmarks.base_benchmark import BaseBenchmark, BenchmarkResult


class GeneratorBenchmark(BaseBenchmark):
    """Benchmark data generators performance."""

    def __init__(self, example: str, generator_path: Path, output_dir: Optional[Path] = None):
        """Initialize generator benchmark."""
        super().__init__(f"generator_{example}", output_dir)
        self.example = example
        self.generator_path = generator_path
        self.temp_dir = None
        self.process = None
        self.current_config = None

    def setup(self) -> None:
        """Setup the benchmark environment."""
        # Create temporary directory for generated data
        self.temp_dir = tempfile.mkdtemp(prefix=f"bench_{self.example}_")
        print(f"   Created temp directory: {self.temp_dir}")

        # Load and modify config to use small dataset for benchmarking
        config_path = self.generator_path / "config.yaml"
        if config_path.exists():
            with open(config_path, "r") as f:
                self.current_config = json.load(f)

            # Create test config with smaller counts
            test_config = self.current_config.copy()
            if "counts" in test_config:
                for key in test_config["counts"]:
                    # Reduce counts for benchmarking
                    test_config["counts"][key] = min(test_config["counts"][key], 100)

            # Save test config
            self.test_config_path = Path(self.temp_dir) / "test_config.yaml"
            with open(self.test_config_path, "w") as f:
                json.dump(test_config, f)

    def run(self) -> BenchmarkResult:
        """Run the generator and measure performance."""
        start_time = time.time()
        start_memory = psutil.Process().memory_info().rss / 1024 / 1024  # MB
        start_cpu = psutil.cpu_percent(interval=0.1)

        # Determine generator type and command
        generate_py = self.generator_path / "generate.py"
        generator_py = self.generator_path / "generator.py"

        if generate_py.exists():
            # Foldered generator
            cmd = [
                sys.executable,
                str(generate_py),
                "-c", str(self.test_config_path) if self.test_config_path else str(self.generator_path / "config.yaml"),
                "-o", self.temp_dir,
                "--seed", "42"
            ]
        elif generator_py.exists():
            # Script generator or unfoldered generator
            cmd = [sys.executable, str(generator_py)]
        else:
            raise FileNotFoundError(f"No generator found for {self.example}")

        # Run the generator
        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=300,  # 5 minute timeout
                cwd=str(self.generator_path.parent)
            )

            if result.returncode != 0:
                raise RuntimeError(f"Generator failed: {result.stderr}")

            # Measure performance metrics
            end_time = time.time()
            duration = end_time - start_time

            # Get peak memory and CPU during generation
            end_memory = psutil.Process().memory_info().rss / 1024 / 1024
            end_cpu = psutil.cpu_percent(interval=0.1)

            memory_used = end_memory - start_memory
            avg_cpu = (start_cpu + end_cpu) / 2

            # Count generated files and rows
            generated_files = list(Path(self.temp_dir).glob("*.csv"))
            total_rows = 0
            total_size = 0

            for file_path in generated_files:
                total_size += file_path.stat().st_size
                with open(file_path, "r") as f:
                    # Count lines (minus header)
                    total_rows += sum(1 for _ in f) - 1

            # Calculate metrics
            rows_per_second = total_rows / duration if duration > 0 else 0
            mb_per_second = (total_size / 1024 / 1024) / duration if duration > 0 else 0

            metrics = {
                "duration_seconds": duration,
                "total_rows": total_rows,
                "total_files": len(generated_files),
                "total_size_mb": total_size / 1024 / 1024,
                "rows_per_second": rows_per_second,
                "mb_per_second": mb_per_second,
                "memory_used_mb": memory_used,
                "avg_cpu_percent": avg_cpu,
                "exit_code": result.returncode,
            }

            return BenchmarkResult(
                name=f"{self.example}_generator",
                type="generator",
                duration=duration,
                metrics=metrics,
                timestamp=datetime.now(),
                environment=self.get_system_metrics()
            )

        except subprocess.TimeoutExpired:
            raise RuntimeError(f"Generator timeout after 300 seconds")
        except Exception as e:
            raise RuntimeError(f"Generator error: {e}")

    def analyze(self) -> Dict[str, Any]:
        """Analyze the benchmark results."""
        if not self.results:
            return {"error": "No results to analyze"}

        durations = [r.duration for r in self.results]
        rows_per_sec = [r.metrics.get("rows_per_second", 0) for r in self.results]
        memory_used = [r.metrics.get("memory_used_mb", 0) for r in self.results]
        cpu_usage = [r.metrics.get("avg_cpu_percent", 0) for r in self.results]

        analysis = {
            "example": self.example,
            "iterations": len(self.results),
            "duration": self.get_statistics(durations),
            "rows_per_second": self.get_statistics(rows_per_sec),
            "memory_mb": self.get_statistics(memory_used),
            "cpu_percent": self.get_statistics(cpu_usage),
            "performance_score": self.calculate_performance_score(),
        }

        # Add summary metrics
        if self.results:
            latest = self.results[-1]
            analysis["summary"] = {
                "total_rows": latest.metrics.get("total_rows", 0),
                "total_files": latest.metrics.get("total_files", 0),
                "total_size_mb": latest.metrics.get("total_size_mb", 0),
            }

        return analysis

    def calculate_performance_score(self) -> float:
        """Calculate overall performance score (0-100)."""
        if not self.results:
            return 0

        scores = []

        # Score based on rows per second (higher is better)
        rows_per_sec = [r.metrics.get("rows_per_second", 0) for r in self.results]
        if rows_per_sec:
            median_rps = statistics.median(rows_per_sec)
            # Assume good performance is 1000 rows/sec
            rps_score = min(100, (median_rps / 1000) * 100)
            scores.append(rps_score)

        # Score based on memory usage (lower is better)
        memory_used = [r.metrics.get("memory_used_mb", 0) for r in self.results]
        if memory_used:
            median_memory = statistics.median(memory_used)
            # Assume good performance is under 100MB
            memory_score = max(0, 100 - (median_memory / 100) * 50)
            scores.append(memory_score)

        # Score based on CPU usage (lower is better)
        cpu_usage = [r.metrics.get("avg_cpu_percent", 0) for r in self.results]
        if cpu_usage:
            median_cpu = statistics.median(cpu_usage)
            # Good performance is under 50% CPU
            cpu_score = max(0, 100 - (median_cpu / 50) * 50)
            scores.append(cpu_score)

        return sum(scores) / len(scores) if scores else 0

    def cleanup(self) -> None:
        """Cleanup after benchmark."""
        # Remove temporary directory
        if self.temp_dir and Path(self.temp_dir).exists():
            shutil.rmtree(self.temp_dir)
            print(f"   Removed temp directory: {self.temp_dir}")

        # Reset config if needed
        self.temp_dir = None
        self.test_config_path = None


class GeneratorBenchmarkSuite:
    """Run benchmarks for all generators."""

    def __init__(self, project_root: Path, output_dir: Optional[Path] = None):
        """Initialize the benchmark suite."""
        self.project_root = project_root
        self.generators_dir = project_root / "generators"
        self.output_dir = output_dir or project_root / "benchmark_results" / "generator_benchmarks"
        self.output_dir.mkdir(parents=True, exist_ok=True)

    def find_generators(self) -> List[Dict[str, Any]]:
        """Find all available generators."""
        generators = []

        # Check each example directory
        for example_dir in self.project_root.glob("example_*"):
            example_name = example_dir.name.replace("example_", "").split("_", 1)[1]

            # Check for foldered generator
            generator_dir = self.generators_dir / example_name
            if generator_dir.exists() and (generator_dir / "generate.py").exists():
                generators.append({
                    "example": example_name,
                    "type": "foldered",
                    "path": generator_dir
                })
            # Check for script generator
            elif (self.generators_dir / f"{example_name}_generator.py").exists():
                generators.append({
                    "example": example_name,
                    "type": "script",
                    "path": self.generators_dir / f"{example_name}_generator.py"
                })
            # Check for generator.py in folder without generate.py
            elif generator_dir.exists() and (generator_dir / "generator.py").exists():
                generators.append({
                    "example": example_name,
                    "type": "unfoldered",
                    "path": generator_dir
                })

        return generators

    def run_all(self, iterations: int = 5, parallel: bool = False) -> Dict[str, Any]:
        """Run benchmarks for all generators."""
        generators = self.find_generators()
        print(f"\nFound {len(generators)} generators to benchmark")

        results = {}
        failed = []

        for gen in generators:
            print(f"\nBenchmarking {gen['example']} ({gen['type']} generator)...")

            try:
                benchmark = GeneratorBenchmark(
                    gen["example"],
                    gen["path"] if gen["type"] != "script" else gen["path"].parent,
                    self.output_dir
                )

                result = benchmark.benchmark(iterations=iterations, warmup_iterations=2)
                results[gen["example"]] = result

            except Exception as e:
                print(f"   ✗ Failed: {e}")
                failed.append({
                    "example": gen["example"],
                    "error": str(e)
                })

        # Generate summary report
        summary = self.generate_summary(results, failed)

        # Save summary
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        summary_file = self.output_dir / f"generator_benchmark_summary_{timestamp}.json"

        with open(summary_file, "w") as f:
            json.dump(summary, f, indent=2, default=str)

        print(f"\n{'='*60}")
        print(f"Generator Benchmark Suite Completed")
        print(f"{'='*60}")
        print(f"Successful: {len(results)}")
        print(f"Failed: {len(failed)}")
        print(f"Summary saved to: {summary_file}")

        return summary

    def generate_summary(self, results: Dict[str, Any], failed: List[Dict]) -> Dict[str, Any]:
        """Generate summary of all benchmark results."""
        summary = {
            "timestamp": datetime.now().isoformat(),
            "total_generators": len(results) + len(failed),
            "successful": len(results),
            "failed": len(failed),
            "results": results,
            "failures": failed,
            "rankings": self.calculate_rankings(results),
            "overall_health": self.calculate_overall_health(results)
        }

        return summary

    def calculate_rankings(self, results: Dict[str, Any]) -> Dict[str, List]:
        """Calculate generator rankings by different metrics."""
        rankings = {
            "by_speed": [],
            "by_memory": [],
            "by_overall_score": []
        }

        for example, result in results.items():
            if "rows_per_second" in result:
                rankings["by_speed"].append({
                    "example": example,
                    "rows_per_second": result["rows_per_second"].get("median", 0)
                })

            if "memory_mb" in result:
                rankings["by_memory"].append({
                    "example": example,
                    "memory_mb": result["memory_mb"].get("median", 0)
                })

            if "performance_score" in result:
                rankings["by_overall_score"].append({
                    "example": example,
                    "score": result["performance_score"]
                })

        # Sort rankings
        rankings["by_speed"].sort(key=lambda x: x["rows_per_second"], reverse=True)
        rankings["by_memory"].sort(key=lambda x: x["memory_mb"])
        rankings["by_overall_score"].sort(key=lambda x: x["score"], reverse=True)

        return rankings

    def calculate_overall_health(self, results: Dict[str, Any]) -> float:
        """Calculate overall health score for all generators."""
        if not results:
            return 0

        scores = [r.get("performance_score", 0) for r in results.values()]
        return sum(scores) / len(scores) if scores else 0


if __name__ == "__main__":
    # Example usage
    import argparse

    parser = argparse.ArgumentParser(description="Benchmark data generators")
    parser.add_argument("--examples", nargs="+", help="Specific examples to benchmark")
    parser.add_argument("--iterations", type=int, default=5, help="Number of iterations")
    parser.add_argument("--parallel", action="store_true", help="Run in parallel")

    args = parser.parse_args()

    project_root = Path(__file__).parent.parent
    suite = GeneratorBenchmarkSuite(project_root)

    if args.examples:
        # Benchmark specific examples
        for example in args.examples:
            gen_path = project_root / "generators" / example
            if gen_path.exists():
                bench = GeneratorBenchmark(example, gen_path)
                bench.benchmark(iterations=args.iterations)
    else:
        # Run all benchmarks
        suite.run_all(iterations=args.iterations, parallel=args.parallel)