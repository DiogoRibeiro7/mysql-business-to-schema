#!/usr/bin/env python3
"""Base benchmark class for all benchmarks."""

from abc import ABC, abstractmethod
from dataclasses import dataclass, asdict
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Any
import json
import time
import psutil
import statistics


@dataclass
class BenchmarkResult:
    """Container for benchmark results."""

    name: str
    type: str
    duration: float
    metrics: Dict[str, Any]
    timestamp: datetime
    environment: Dict[str, Any]

    def to_dict(self) -> Dict:
        """Convert to dictionary for JSON serialization."""
        result = asdict(self)
        result["timestamp"] = self.timestamp.isoformat()
        return result


class BaseBenchmark(ABC):
    """Base class for all benchmarks."""

    def __init__(self, name: str, output_dir: Optional[Path] = None):
        """Initialize the benchmark."""
        self.name = name
        self.output_dir = output_dir or Path("benchmark_results")
        self.output_dir.mkdir(parents=True, exist_ok=True)
        self.results: List[BenchmarkResult] = []
        self.start_time: Optional[float] = None
        self.end_time: Optional[float] = None

    @abstractmethod
    def setup(self) -> None:
        """Setup the benchmark environment."""
        pass

    @abstractmethod
    def run(self) -> BenchmarkResult:
        """Run the benchmark and return results."""
        pass

    @abstractmethod
    def analyze(self) -> Dict[str, Any]:
        """Analyze the benchmark results."""
        pass

    @abstractmethod
    def cleanup(self) -> None:
        """Cleanup after benchmark."""
        pass

    def warmup(self, iterations: int = 3) -> None:
        """Run warmup iterations."""
        print(f"Running {iterations} warmup iterations...")
        for i in range(iterations):
            try:
                self.run()
            except Exception as e:
                print(f"Warmup iteration {i+1} failed: {e}")
        # Clear warmup results
        self.results.clear()

    def benchmark(self, iterations: int = 10, warmup_iterations: int = 3) -> Dict[str, Any]:
        """Run the full benchmark process."""
        print(f"\n{'='*60}")
        print(f"Running benchmark: {self.name}")
        print(f"{'='*60}")

        # Setup
        print("\n1. Setting up...")
        self.setup()

        # Warmup
        if warmup_iterations > 0:
            print("\n2. Warming up...")
            self.warmup(warmup_iterations)

        # Run benchmark iterations
        print(f"\n3. Running {iterations} benchmark iterations...")
        self.start_time = time.time()

        for i in range(iterations):
            print(f"   Iteration {i+1}/{iterations}...", end="")
            try:
                result = self.run()
                self.results.append(result)
                print(f" [OK] ({result.duration:.2f}s)")
            except Exception as e:
                print(f" [FAIL] (Error: {e})")

        self.end_time = time.time()

        # Analyze results
        print("\n4. Analyzing results...")
        analysis = self.analyze()

        # Cleanup
        print("\n5. Cleaning up...")
        self.cleanup()

        # Save results
        print("\n6. Saving results...")
        self.save_results(analysis)

        total_time = self.end_time - self.start_time
        print(f"\n{'='*60}")
        print(f"Benchmark completed in {total_time:.2f}s")
        print(f"{'='*60}\n")

        return analysis

    def get_system_metrics(self) -> Dict[str, Any]:
        """Get current system metrics."""
        return {
            "cpu_percent": psutil.cpu_percent(interval=1),
            "memory_percent": psutil.virtual_memory().percent,
            "memory_mb": psutil.virtual_memory().used / 1024 / 1024,
            "disk_io": {
                "read_bytes": psutil.disk_io_counters().read_bytes,
                "write_bytes": psutil.disk_io_counters().write_bytes,
            }
        }

    def get_statistics(self, values: List[float]) -> Dict[str, float]:
        """Calculate statistics for a list of values."""
        if not values:
            return {}

        return {
            "min": min(values),
            "max": max(values),
            "mean": statistics.mean(values),
            "median": statistics.median(values),
            "stdev": statistics.stdev(values) if len(values) > 1 else 0,
            "p95": statistics.quantiles(values, n=20)[18] if len(values) > 1 else values[0],
            "p99": statistics.quantiles(values, n=100)[98] if len(values) > 1 else values[0],
        }

    def save_results(self, analysis: Dict[str, Any]) -> None:
        """Save benchmark results to file."""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"{self.name}_{timestamp}.json"
        filepath = self.output_dir / filename

        output = {
            "benchmark": self.name,
            "timestamp": datetime.now().isoformat(),
            "total_duration": self.end_time - self.start_time if self.end_time and self.start_time else 0,
            "iterations": len(self.results),
            "results": [r.to_dict() for r in self.results],
            "analysis": analysis,
        }

        with open(filepath, "w") as f:
            json.dump(output, f, indent=2, default=str)

        print(f"Results saved to: {filepath}")

    def compare_with_baseline(self, baseline_file: Path) -> Dict[str, Any]:
        """Compare current results with a baseline."""
        if not baseline_file.exists():
            return {"error": f"Baseline file not found: {baseline_file}"}

        with open(baseline_file, "r") as f:
            baseline = json.load(f)

        current_metrics = self.analyze()
        baseline_metrics = baseline.get("analysis", {})

        comparison = {
            "baseline_timestamp": baseline.get("timestamp"),
            "current_timestamp": datetime.now().isoformat(),
            "changes": {}
        }

        for metric, current_value in current_metrics.items():
            if metric in baseline_metrics:
                baseline_value = baseline_metrics[metric]
                if isinstance(current_value, (int, float)) and isinstance(baseline_value, (int, float)):
                    change_pct = ((current_value - baseline_value) / baseline_value) * 100 if baseline_value != 0 else 0
                    comparison["changes"][metric] = {
                        "baseline": baseline_value,
                        "current": current_value,
                        "change_percent": round(change_pct, 2),
                        "improved": change_pct < 0 if "time" in metric.lower() or "duration" in metric.lower() else change_pct > 0
                    }

        return comparison