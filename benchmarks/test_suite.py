#!/usr/bin/env python3
"""Test the performance benchmarking suite."""

import sys
from pathlib import Path
import json

# Add parent directory to path
sys.path.append(str(Path(__file__).parent.parent))

from benchmarks.generator_benchmark import GeneratorBenchmark
from benchmarks.report_generator import ReportGenerator


def test_generator_benchmark():
    """Test generator benchmarking."""
    print("\n" + "="*60)
    print("Testing Generator Benchmark")
    print("="*60)

    # Test cryptocurrency generator
    gen_path = Path(__file__).parent.parent / "generators" / "cryptocurrency"
    benchmark = GeneratorBenchmark("cryptocurrency", gen_path)

    # Run benchmark with minimal iterations
    results = benchmark.benchmark(iterations=2, warmup_iterations=1)

    print(f"\nResults Summary:")
    print(f"  Performance Score: {results.get('performance_score', 0):.1f}/100")
    print(f"  Duration: {results['duration']['median']:.2f}s")
    print(f"  Rows/Second: {results['rows_per_second']['median']:.1f}")
    print(f"  Memory Used: {results['memory_mb']['median']:.2f} MB")

    return results


def test_report_generation(benchmark_results):
    """Test report generation."""
    print("\n" + "="*60)
    print("Testing Report Generation")
    print("="*60)

    # Create test results structure
    report_data = {
        "metadata": {
            "timestamp": "2026-03-02T23:30:00",
            "duration_seconds": 10.5,
            "project_root": str(Path(__file__).parent.parent),
        },
        "results": {
            "generator": benchmark_results
        },
        "summary": {
            "total_benchmarks_run": 1,
            "successful": 1,
            "failed": 0,
            "generator": {
                "total_generators": 1,
                "overall_health": benchmark_results.get("performance_score", 0)
            }
        },
        "health_score": benchmark_results.get("performance_score", 0),
        "recommendations": [
            "[GOOD] Generator performance is excellent",
            "[TIP] Consider enabling parallel execution for faster benchmarks",
            "[TIP] Run benchmarks regularly to detect performance regressions"
        ]
    }

    # Generate HTML report
    generator = ReportGenerator(report_data)

    output_dir = Path(__file__).parent / "test_reports"
    output_dir.mkdir(exist_ok=True)

    html_path = output_dir / "test_report.html"
    generator.generate("html", html_path)
    print(f"\n[OK] HTML report generated: {html_path}")

    # Generate Markdown report
    md_path = output_dir / "test_report.md"
    generator.generate("markdown", md_path)
    print(f"[OK] Markdown report generated: {md_path}")

    # Generate JSON report
    json_path = output_dir / "test_report.json"
    generator.generate("json", json_path)
    print(f"[OK] JSON report generated: {json_path}")


def main():
    """Run all tests."""
    print("\n" + "="*70)
    print("  Performance Benchmarking Suite Test")
    print("="*70)

    try:
        # Test generator benchmark
        gen_results = test_generator_benchmark()

        # Test report generation
        test_report_generation(gen_results)

        print("\n" + "="*70)
        print("  [SUCCESS] All tests completed successfully!")
        print("="*70 + "\n")

        return 0

    except Exception as e:
        print(f"\n[ERROR] Test failed: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())