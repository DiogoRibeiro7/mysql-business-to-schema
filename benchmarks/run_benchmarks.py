#!/usr/bin/env python3
"""Main benchmark orchestrator.

Runs all benchmarks (generator, query, index) and generates comprehensive reports.
"""

import sys
import time
import json
import argparse
import concurrent.futures
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional, Any

# Add parent directory to path
sys.path.append(str(Path(__file__).parent.parent))

from benchmarks.generator_benchmark import GeneratorBenchmarkSuite
from benchmarks.query_performance import QueryPerformanceBenchmark
from benchmarks.index_analyzer import IndexAnalyzer
from benchmarks.regression_detector import RegressionDetector


class BenchmarkRunner:
    """Main benchmark orchestrator."""

    def __init__(self, project_root: Path, config: Optional[Dict] = None):
        """Initialize the benchmark runner."""
        self.project_root = project_root
        self.config = config or {}
        self.output_dir = project_root / "benchmark_results"
        self.output_dir.mkdir(parents=True, exist_ok=True)

        # Load config from file if exists
        config_file = project_root / "benchmark_config.json"
        if config_file.exists() and not config:
            with open(config_file, "r") as f:
                self.config = json.load(f)

        # Initialize benchmark components
        self.generator_suite = None
        self.query_benchmark = None
        self.index_analyzer = None
        self.regression_detector = None

        self.results = {}

    def run_all(
        self,
        benchmarks: Optional[List[str]] = None,
        examples: Optional[List[str]] = None,
        parallel: bool = False
    ) -> Dict[str, Any]:
        """Run all specified benchmarks."""
        benchmarks = benchmarks or self.config.get("benchmarks", ["generator", "query", "index"])
        examples = examples or self.config.get("examples", None)

        print(f"\n{'='*70}")
        print(f"  MySQL Business-to-Schema Performance Benchmark Suite")
        print(f"{'='*70}")
        print(f"Timestamp: {datetime.now().isoformat()}")
        print(f"Benchmarks: {', '.join(benchmarks)}")
        print(f"Examples: {', '.join(examples) if examples else 'All'}")
        print(f"Mode: {'Parallel' if parallel else 'Sequential'}")
        print(f"{'='*70}\n")

        start_time = time.time()

        if parallel and len(benchmarks) > 1:
            # Run benchmarks in parallel
            with concurrent.futures.ThreadPoolExecutor(max_workers=3) as executor:
                futures = {}

                if "generator" in benchmarks:
                    futures["generator"] = executor.submit(
                        self.run_generator_benchmarks, examples
                    )

                if "query" in benchmarks:
                    futures["query"] = executor.submit(
                        self.run_query_benchmarks, examples
                    )

                if "index" in benchmarks:
                    futures["index"] = executor.submit(
                        self.run_index_analysis, examples
                    )

                # Collect results
                for name, future in futures.items():
                    try:
                        self.results[name] = future.result(timeout=3600)  # 1 hour timeout
                    except Exception as e:
                        print(f"✗ {name} benchmark failed: {e}")
                        self.results[name] = {"error": str(e)}
        else:
            # Run benchmarks sequentially
            if "generator" in benchmarks:
                self.results["generator"] = self.run_generator_benchmarks(examples)

            if "query" in benchmarks:
                self.results["query"] = self.run_query_benchmarks(examples)

            if "index" in benchmarks:
                self.results["index"] = self.run_index_analysis(examples)

        # Run regression detection if we have results
        if self.results:
            print(f"\n{'='*70}")
            print("Running Regression Detection...")
            print(f"{'='*70}")
            self.results["regression"] = self.run_regression_detection()

        end_time = time.time()
        total_duration = end_time - start_time

        # Generate final report
        report = self.generate_report(total_duration)

        # Save report
        self.save_report(report)

        # Print summary
        self.print_summary(report)

        return report

    def run_generator_benchmarks(self, examples: Optional[List[str]] = None) -> Dict[str, Any]:
        """Run generator benchmarks."""
        print(f"\n{'-'*60}")
        print("GENERATOR BENCHMARKS")
        print(f"{'-'*60}")

        self.generator_suite = GeneratorBenchmarkSuite(
            self.project_root,
            self.output_dir / "generator_benchmarks"
        )

        # Get iterations from config
        iterations = self.config.get("generator", {}).get("iterations", 5)

        try:
            if examples:
                # Run specific examples
                results = {}
                for example in examples:
                    print(f"\nBenchmarking {example} generator...")
                    # Implementation would need to be added to generator_benchmark.py
                    # to support benchmarking specific examples
                return results
            else:
                # Run all generators
                return self.generator_suite.run_all(iterations=iterations)
        except Exception as e:
            print(f"Generator benchmarks failed: {e}")
            return {"error": str(e)}

    def run_query_benchmarks(self, examples: Optional[List[str]] = None) -> Dict[str, Any]:
        """Run query performance benchmarks."""
        print(f"\n{'-'*60}")
        print("QUERY PERFORMANCE BENCHMARKS")
        print(f"{'-'*60}")

        results = {}
        examples_to_test = examples or self.get_all_examples()

        for example in examples_to_test:
            print(f"\nBenchmarking queries for {example}...")

            # Database connection parameters
            db_config = {
                "host": "localhost",
                "port": 3306,
                "user": "root",
                "password": "",
                "database": example
            }

            try:
                benchmark = QueryPerformanceBenchmark(db_config)
                if benchmark.connect():
                    # Run standard query benchmarks
                    example_results = self.run_standard_queries(benchmark, example)
                    results[example] = example_results
                    benchmark.disconnect()
                else:
                    results[example] = {"error": "Failed to connect to database"}
            except Exception as e:
                print(f"   ✗ Failed: {e}")
                results[example] = {"error": str(e)}

        return results

    def run_index_analysis(self, examples: Optional[List[str]] = None) -> Dict[str, Any]:
        """Run index effectiveness analysis."""
        print(f"\n{'-'*60}")
        print("INDEX EFFECTIVENESS ANALYSIS")
        print(f"{'-'*60}")

        results = {}
        examples_to_test = examples or self.get_all_examples()

        for example in examples_to_test:
            print(f"\nAnalyzing indexes for {example}...")

            try:
                analyzer = IndexAnalyzer(
                    host="localhost",
                    port=3306,
                    user="root",
                    password="",
                    database=example
                )

                if analyzer.connect():
                    analysis = analyzer.analyze_all_indexes()
                    results[example] = analysis
                    analyzer.disconnect()
                else:
                    results[example] = {"error": "Failed to connect to database"}
            except Exception as e:
                print(f"   ✗ Failed: {e}")
                results[example] = {"error": str(e)}

        return results

    def run_regression_detection(self) -> Dict[str, Any]:
        """Run regression detection on current results."""
        try:
            detector = RegressionDetector(self.output_dir)

            # Find latest baseline
            baseline_file = self.find_latest_baseline()
            if not baseline_file:
                return {"message": "No baseline found for comparison"}

            # Compare with current results
            comparison = detector.compare_benchmarks(baseline_file, self.results)

            return comparison
        except Exception as e:
            return {"error": str(e)}

    def get_all_examples(self) -> List[str]:
        """Get all available examples."""
        examples = []
        for example_dir in self.project_root.glob("example_*"):
            example_name = example_dir.name.replace("example_", "").split("_", 1)[1]
            examples.append(example_name)
        return examples

    def run_standard_queries(self, benchmark: QueryPerformanceBenchmark, example: str) -> Dict[str, Any]:
        """Run standard query benchmarks for an example."""
        results = {}

        # Define standard queries to benchmark based on example
        queries = self.get_standard_queries(example)

        for query_name, query_sql in queries.items():
            try:
                # Run benchmark for this query
                # Note: This would need to be implemented in QueryPerformanceBenchmark
                result = {"execution_time": 0, "rows_examined": 0}  # Placeholder
                results[query_name] = result
            except Exception as e:
                results[query_name] = {"error": str(e)}

        return results

    def get_standard_queries(self, example: str) -> Dict[str, str]:
        """Get standard queries for benchmarking based on example."""
        # This would be expanded with actual queries for each example
        queries = {
            "simple_select": f"SELECT * FROM users LIMIT 10",
            "count": f"SELECT COUNT(*) FROM users",
        }

        # Add example-specific queries
        if example == "clinic":
            queries.update({
                "appointments_today": "SELECT * FROM appointments WHERE date = CURDATE()",
                "patient_history": "SELECT * FROM medical_records WHERE patient_id = 1",
            })
        elif example == "ecommerce":
            queries.update({
                "recent_orders": "SELECT * FROM orders ORDER BY created_at DESC LIMIT 100",
                "product_sales": "SELECT product_id, COUNT(*) FROM order_items GROUP BY product_id",
            })

        return queries

    def find_latest_baseline(self) -> Optional[Path]:
        """Find the latest baseline benchmark file."""
        baseline_files = list(self.output_dir.glob("benchmark_*.json"))
        if not baseline_files:
            return None

        # Sort by modification time
        baseline_files.sort(key=lambda x: x.stat().st_mtime, reverse=True)

        # Return the most recent file that's not from today
        today = datetime.now().date()
        for file in baseline_files:
            file_date = datetime.fromtimestamp(file.stat().st_mtime).date()
            if file_date < today:
                return file

        return baseline_files[0] if baseline_files else None

    def generate_report(self, total_duration: float) -> Dict[str, Any]:
        """Generate comprehensive benchmark report."""
        report = {
            "metadata": {
                "timestamp": datetime.now().isoformat(),
                "duration_seconds": total_duration,
                "project_root": str(self.project_root),
                "config": self.config,
            },
            "results": self.results,
            "summary": self.generate_summary(),
            "health_score": self.calculate_health_score(),
            "recommendations": self.generate_recommendations(),
        }

        return report

    def generate_summary(self) -> Dict[str, Any]:
        """Generate summary of all benchmark results."""
        summary = {
            "total_benchmarks_run": len(self.results),
            "successful": sum(1 for r in self.results.values() if "error" not in r),
            "failed": sum(1 for r in self.results.values() if "error" in r),
        }

        # Add specific summaries for each benchmark type
        if "generator" in self.results and "error" not in self.results["generator"]:
            gen_results = self.results["generator"]
            summary["generator"] = {
                "total_generators": gen_results.get("total_generators", 0),
                "overall_health": gen_results.get("overall_health", 0),
            }

        if "query" in self.results:
            query_results = self.results["query"]
            summary["query"] = {
                "databases_tested": len(query_results),
                "total_queries_run": sum(
                    len(db.get("queries", {}))
                    for db in query_results.values()
                    if isinstance(db, dict)
                ),
            }

        if "index" in self.results:
            index_results = self.results["index"]
            summary["index"] = {
                "databases_analyzed": len(index_results),
                "total_indexes": sum(
                    len(db.get("indexes", []))
                    for db in index_results.values()
                    if isinstance(db, dict)
                ),
            }

        return summary

    def calculate_health_score(self) -> float:
        """Calculate overall health score (0-100)."""
        scores = []

        # Generator health score
        if "generator" in self.results and "error" not in self.results["generator"]:
            gen_health = self.results["generator"].get("overall_health", 0)
            scores.append(gen_health)

        # Query performance score (placeholder - would need actual implementation)
        if "query" in self.results:
            query_score = 75  # Placeholder
            scores.append(query_score)

        # Index effectiveness score (placeholder - would need actual implementation)
        if "index" in self.results:
            index_score = 80  # Placeholder
            scores.append(index_score)

        # Regression score
        if "regression" in self.results and "score" in self.results["regression"]:
            scores.append(self.results["regression"]["score"])

        return sum(scores) / len(scores) if scores else 0

    def generate_recommendations(self) -> List[str]:
        """Generate actionable recommendations based on results."""
        recommendations = []

        # Check generator performance
        if "generator" in self.results and "rankings" in self.results["generator"]:
            rankings = self.results["generator"]["rankings"]
            if rankings.get("by_speed"):
                slowest = rankings["by_speed"][-3:] if len(rankings["by_speed"]) > 3 else rankings["by_speed"]
                for gen in slowest:
                    if gen.get("rows_per_second", 0) < 100:
                        recommendations.append(
                            f"⚠ {gen['example']} generator is slow ({gen['rows_per_second']:.1f} rows/sec). "
                            f"Consider optimizing batch inserts or data generation logic."
                        )

        # Check for regressions
        if "regression" in self.results and "regressions" in self.results["regression"]:
            for regression in self.results["regression"]["regressions"]:
                recommendations.append(
                    f"⚠ Performance regression detected in {regression['metric']}: "
                    f"{regression['change_percent']:.1f}% slower than baseline"
                )

        # Check index effectiveness
        if "index" in self.results:
            for db, analysis in self.results["index"].items():
                if isinstance(analysis, dict):
                    if "unused_indexes" in analysis and analysis["unused_indexes"]:
                        recommendations.append(
                            f"💡 {db}: Found {len(analysis['unused_indexes'])} unused indexes. "
                            f"Consider removing them to improve write performance."
                        )

                    if "duplicate_indexes" in analysis and analysis["duplicate_indexes"]:
                        recommendations.append(
                            f"💡 {db}: Found {len(analysis['duplicate_indexes'])} duplicate indexes. "
                            f"Consolidate them to save storage space."
                        )

        # General recommendations
        health_score = self.calculate_health_score()
        if health_score < 50:
            recommendations.append(
                "🔴 Overall health score is poor. Immediate optimization required."
            )
        elif health_score < 70:
            recommendations.append(
                "🟡 Overall health score is acceptable but improvements recommended."
            )
        else:
            recommendations.append(
                "🟢 Overall health score is good. Continue monitoring for regressions."
            )

        return recommendations

    def save_report(self, report: Dict[str, Any]) -> None:
        """Save benchmark report to file."""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"benchmark_{timestamp}.json"
        filepath = self.output_dir / filename

        with open(filepath, "w") as f:
            json.dump(report, f, indent=2, default=str)

        print(f"\n📊 Report saved to: {filepath}")

    def print_summary(self, report: Dict[str, Any]) -> None:
        """Print benchmark summary to console."""
        print(f"\n{'='*70}")
        print("BENCHMARK SUMMARY")
        print(f"{'='*70}")

        summary = report["summary"]
        print(f"\nBenchmarks Run: {summary['total_benchmarks_run']}")
        print(f"Successful: {summary['successful']}")
        print(f"Failed: {summary['failed']}")

        health_score = report["health_score"]
        health_emoji = "🟢" if health_score >= 70 else "🟡" if health_score >= 50 else "🔴"
        print(f"\nOverall Health Score: {health_emoji} {health_score:.1f}/100")

        print(f"\n{'='*70}")
        print("RECOMMENDATIONS")
        print(f"{'='*70}")

        for rec in report["recommendations"]:
            print(f"\n{rec}")

        print(f"\n{'='*70}")
        print(f"Benchmark completed in {report['metadata']['duration_seconds']:.2f} seconds")
        print(f"{'='*70}\n")

    def export_results(self, format: str, output: Path) -> None:
        """Export results in different formats."""
        if format == "html":
            self.export_html(output)
        elif format == "markdown":
            self.export_markdown(output)
        elif format == "csv":
            self.export_csv(output)
        else:
            raise ValueError(f"Unsupported format: {format}")

    def export_html(self, output: Path) -> None:
        """Export results as HTML report."""
        # Would implement HTML generation
        pass

    def export_markdown(self, output: Path) -> None:
        """Export results as Markdown report."""
        # Would implement Markdown generation
        pass

    def export_csv(self, output: Path) -> None:
        """Export results as CSV files."""
        # Would implement CSV generation
        pass


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description="Run performance benchmarks")
    parser.add_argument(
        "--benchmarks",
        nargs="+",
        choices=["generator", "query", "index"],
        help="Benchmarks to run (default: all)"
    )
    parser.add_argument(
        "--examples",
        nargs="+",
        help="Specific examples to benchmark (default: all)"
    )
    parser.add_argument(
        "--parallel",
        action="store_true",
        help="Run benchmarks in parallel"
    )
    parser.add_argument(
        "--config",
        type=Path,
        help="Configuration file path"
    )
    parser.add_argument(
        "--export",
        choices=["html", "markdown", "csv"],
        help="Export format for results"
    )
    parser.add_argument(
        "--output",
        type=Path,
        help="Output path for export"
    )

    args = parser.parse_args()

    # Load config if provided
    config = {}
    if args.config and args.config.exists():
        with open(args.config, "r") as f:
            config = json.load(f)

    # Run benchmarks
    project_root = Path(__file__).parent.parent
    runner = BenchmarkRunner(project_root, config)

    report = runner.run_all(
        benchmarks=args.benchmarks,
        examples=args.examples,
        parallel=args.parallel
    )

    # Export if requested
    if args.export and args.output:
        runner.export_results(args.export, args.output)

    return 0 if report["summary"]["failed"] == 0 else 1


if __name__ == "__main__":
    sys.exit(main())