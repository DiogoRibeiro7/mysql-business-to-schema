#!/usr/bin/env python3
"""
Performance Regression Detector

This tool compares benchmark results over time to detect performance regressions
and improvements across database schemas and generators.
"""

import json
import statistics
from pathlib import Path
from datetime import datetime, timedelta
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass, field
from enum import Enum
import sys


class ChangeType(Enum):
    """Type of performance change detected"""

    REGRESSION = "regression"
    IMPROVEMENT = "improvement"
    STABLE = "stable"
    NEW = "new"
    REMOVED = "removed"


@dataclass
class PerformanceChange:
    """Represents a performance change between two benchmarks"""

    metric_name: str
    baseline_value: float
    current_value: float
    change_percent: float
    change_type: ChangeType
    severity: str  # LOW, MEDIUM, HIGH, CRITICAL
    details: Dict = field(default_factory=dict)

    def to_dict(self) -> Dict:
        """Convert to dictionary for JSON serialization"""
        return {
            "metric": self.metric_name,
            "baseline": round(self.baseline_value, 2),
            "current": round(self.current_value, 2),
            "change_percent": round(self.change_percent, 2),
            "change_type": self.change_type.value,
            "severity": self.severity,
            "details": self.details,
        }


class RegressionDetector:
    """Detect performance regressions between benchmark runs"""

    def __init__(self, results_dir: str = "benchmark_results"):
        self.results_dir = Path(results_dir)
        self.baseline = None
        self.current = None
        self.changes = []
        self.config = {
            "thresholds": {
                "regression": {
                    "low": 10,  # 10% slower
                    "medium": 25,  # 25% slower
                    "high": 50,  # 50% slower
                    "critical": 100,  # 100% slower
                },
                "improvement": {
                    "low": -10,  # 10% faster
                    "medium": -25,  # 25% faster
                    "high": -50,  # 50% faster
                },
            },
            "metrics": {
                "generator_duration": {"weight": 1.0, "direction": "lower_better"},
                "memory_peak_mb": {"weight": 0.8, "direction": "lower_better"},
                "cpu_peak_percent": {"weight": 0.6, "direction": "lower_better"},
                "queries_per_second": {"weight": 0.9, "direction": "higher_better"},
                "rows_per_second": {"weight": 0.7, "direction": "higher_better"},
            },
        }

    def load_benchmark_results(self, filename: str) -> Dict:
        """Load benchmark results from JSON file"""
        file_path = self.results_dir / filename

        if not file_path.exists():
            raise FileNotFoundError(f"Benchmark file not found: {file_path}")

        with open(file_path, "r") as f:
            return json.load(f)

    def load_latest_benchmarks(self, count: int = 2) -> List[Dict]:
        """Load the most recent benchmark results"""
        benchmark_files = sorted(self.results_dir.glob("benchmark_*.json"))

        if len(benchmark_files) < count:
            print(f"Warning: Only {len(benchmark_files)} benchmark files found")

        results = []
        for file in benchmark_files[-count:]:
            results.append(self.load_benchmark_results(file.name))

        return results

    def compare_benchmarks(self, baseline_file: str, current_file: str) -> Dict:
        """Compare two benchmark runs"""
        self.baseline = self.load_benchmark_results(baseline_file)
        self.current = self.load_benchmark_results(current_file)

        # Compare generator performance
        self._compare_generators()

        # Compare query performance
        self._compare_queries()

        # Compare index effectiveness
        self._compare_indexes()

        # Calculate overall health score
        health_score = self._calculate_health_score()

        # Generate report
        return self._generate_report(health_score)

    def _compare_generators(self):
        """Compare generator performance metrics"""
        baseline_gens = self.baseline.get("results", {})
        current_gens = self.current.get("results", {})

        all_examples = set(baseline_gens.keys()) | set(current_gens.keys())

        for example in all_examples:
            baseline_data = baseline_gens.get(example, {}).get("generator", {})
            current_data = current_gens.get(example, {}).get("generator", {})

            if not baseline_data and current_data:
                # New generator added
                self.changes.append(
                    PerformanceChange(
                        metric_name=f"{example}_generator",
                        baseline_value=0,
                        current_value=current_data.get("duration", 0),
                        change_percent=0,
                        change_type=ChangeType.NEW,
                        severity="INFO",
                        details={"example": example},
                    )
                )
            elif baseline_data and not current_data:
                # Generator removed
                self.changes.append(
                    PerformanceChange(
                        metric_name=f"{example}_generator",
                        baseline_value=baseline_data.get("duration", 0),
                        current_value=0,
                        change_percent=0,
                        change_type=ChangeType.REMOVED,
                        severity="WARNING",
                        details={"example": example},
                    )
                )
            elif baseline_data and current_data:
                # Compare performance
                self._compare_metric(
                    f"{example}_duration",
                    baseline_data.get("duration", 0),
                    current_data.get("duration", 0),
                    "lower_better",
                    {"example": example, "type": "generator"},
                )

                self._compare_metric(
                    f"{example}_memory",
                    baseline_data.get("memory_peak_mb", 0),
                    current_data.get("memory_peak_mb", 0),
                    "lower_better",
                    {"example": example, "type": "memory"},
                )

    def _compare_queries(self):
        """Compare query performance metrics"""
        # This would compare query benchmark results if available
        # For now, we'll check if query benchmarks exist in the results
        pass

    def _compare_indexes(self):
        """Compare index effectiveness metrics"""
        # This would compare index analysis results if available
        pass

    def _compare_metric(
        self,
        metric_name: str,
        baseline: float,
        current: float,
        direction: str,
        details: Dict = None,
    ):
        """Compare a single metric and determine if there's a regression"""

        if baseline == 0:
            if current != 0:
                self.changes.append(
                    PerformanceChange(
                        metric_name=metric_name,
                        baseline_value=baseline,
                        current_value=current,
                        change_percent=100,
                        change_type=ChangeType.NEW,
                        severity="INFO",
                        details=details or {},
                    )
                )
            return

        # Calculate percentage change
        change_percent = ((current - baseline) / baseline) * 100

        # Determine change type and severity
        if direction == "lower_better":
            # Higher values are worse (e.g., execution time, memory usage)
            if change_percent > self.config["thresholds"]["regression"]["low"]:
                change_type = ChangeType.REGRESSION
                severity = self._get_severity(change_percent, "regression")
            elif change_percent < self.config["thresholds"]["improvement"]["low"]:
                change_type = ChangeType.IMPROVEMENT
                severity = "INFO"
            else:
                change_type = ChangeType.STABLE
                severity = "INFO"
        else:
            # Higher values are better (e.g., queries per second)
            if change_percent < -self.config["thresholds"]["regression"]["low"]:
                change_type = ChangeType.REGRESSION
                severity = self._get_severity(-change_percent, "regression")
            elif change_percent > -self.config["thresholds"]["improvement"]["low"]:
                change_type = ChangeType.IMPROVEMENT
                severity = "INFO"
            else:
                change_type = ChangeType.STABLE
                severity = "INFO"

        self.changes.append(
            PerformanceChange(
                metric_name=metric_name,
                baseline_value=baseline,
                current_value=current,
                change_percent=change_percent,
                change_type=change_type,
                severity=severity,
                details=details or {},
            )
        )

    def _get_severity(self, change_percent: float, change_type: str) -> str:
        """Determine severity based on percentage change"""
        thresholds = self.config["thresholds"][change_type]
        abs_change = abs(change_percent)

        if abs_change >= thresholds.get("critical", 100):
            return "CRITICAL"
        elif abs_change >= thresholds["high"]:
            return "HIGH"
        elif abs_change >= thresholds["medium"]:
            return "MEDIUM"
        else:
            return "LOW"

    def _calculate_health_score(self) -> float:
        """Calculate overall health score (0-100)"""
        if not self.changes:
            return 100.0

        score = 100.0
        severity_penalties = {
            "CRITICAL": 25,
            "HIGH": 15,
            "MEDIUM": 8,
            "LOW": 3,
            "WARNING": 5,
            "INFO": 0,
        }

        for change in self.changes:
            if change.change_type == ChangeType.REGRESSION:
                score -= severity_penalties.get(change.severity, 0)
            elif change.change_type == ChangeType.IMPROVEMENT:
                score += severity_penalties.get(change.severity, 0) * 0.5

        return max(0, min(100, score))

    def _generate_report(self, health_score: float) -> Dict:
        """Generate comprehensive comparison report"""

        regressions = [
            c for c in self.changes if c.change_type == ChangeType.REGRESSION
        ]
        improvements = [
            c for c in self.changes if c.change_type == ChangeType.IMPROVEMENT
        ]

        report = {
            "timestamp": datetime.now().isoformat(),
            "baseline": {
                "file": self.baseline.get("file", "unknown"),
                "timestamp": self.baseline.get("timestamp", "unknown"),
            },
            "current": {
                "file": self.current.get("file", "unknown"),
                "timestamp": self.current.get("timestamp", "unknown"),
            },
            "summary": {
                "health_score": round(health_score, 2),
                "total_changes": len(self.changes),
                "regressions": len(regressions),
                "improvements": len(improvements),
                "critical_issues": len(
                    [c for c in regressions if c.severity == "CRITICAL"]
                ),
                "high_issues": len([c for c in regressions if c.severity == "HIGH"]),
            },
            "changes": [c.to_dict() for c in self.changes],
            "regressions": [c.to_dict() for c in regressions],
            "improvements": [c.to_dict() for c in improvements],
            "recommendations": self._generate_recommendations(),
        }

        return report

    def _generate_recommendations(self) -> List[Dict]:
        """Generate actionable recommendations based on detected changes"""
        recommendations = []

        # Group regressions by type
        generator_regressions = [
            c
            for c in self.changes
            if c.change_type == ChangeType.REGRESSION
            and c.details.get("type") == "generator"
        ]

        memory_regressions = [
            c
            for c in self.changes
            if c.change_type == ChangeType.REGRESSION
            and c.details.get("type") == "memory"
        ]

        # Generator performance recommendations
        if generator_regressions:
            worst = max(generator_regressions, key=lambda x: x.change_percent)
            recommendations.append(
                {
                    "priority": worst.severity,
                    "area": "Generator Performance",
                    "issue": f"{worst.details.get('example', 'Unknown')} generator is {worst.change_percent:.1f}% slower",
                    "action": "Review recent changes to generator code and optimize batch operations",
                }
            )

        # Memory usage recommendations
        if memory_regressions:
            worst = max(memory_regressions, key=lambda x: x.change_percent)
            recommendations.append(
                {
                    "priority": worst.severity,
                    "area": "Memory Usage",
                    "issue": f"{worst.details.get('example', 'Unknown')} using {worst.change_percent:.1f}% more memory",
                    "action": "Profile memory usage and optimize data structures",
                }
            )

        # Critical issues
        critical = [
            c
            for c in self.changes
            if c.change_type == ChangeType.REGRESSION and c.severity == "CRITICAL"
        ]

        for issue in critical[:3]:  # Top 3 critical issues
            recommendations.append(
                {
                    "priority": "CRITICAL",
                    "area": issue.metric_name,
                    "issue": f"Critical regression: {issue.change_percent:.1f}% degradation",
                    "action": "Immediate investigation required - consider reverting recent changes",
                }
            )

        return recommendations

    def export_report(self, report: Dict, output_file: Path):
        """Export regression report to file"""
        with open(output_file, "w") as f:
            json.dump(report, f, indent=2)

        print(f"Regression report exported to: {output_file}")

    def print_summary(self, report: Dict):
        """Print human-readable summary"""
        print("\n" + "=" * 60)
        print("Performance Regression Analysis")
        print("=" * 60)

        summary = report["summary"]
        print(f"\nHealth Score: {summary['health_score']}/100")
        print(f"Total Changes: {summary['total_changes']}")
        print(
            f"Regressions: {summary['regressions']} "
            f"(Critical: {summary['critical_issues']}, High: {summary['high_issues']})"
        )
        print(f"Improvements: {summary['improvements']}")

        if report["regressions"]:
            print("\n⚠️  Performance Regressions:")
            for reg in report["regressions"][:5]:
                severity_icon = {
                    "CRITICAL": "🔴",
                    "HIGH": "🟠",
                    "MEDIUM": "🟡",
                    "LOW": "⚪",
                }.get(reg["severity"], "⚪")

                print(
                    f"  {severity_icon} [{reg['severity']}] {reg['metric']}: "
                    f"{reg['change_percent']:+.1f}% "
                    f"({reg['baseline']:.2f} → {reg['current']:.2f})"
                )

        if report["improvements"]:
            print("\n✅ Performance Improvements:")
            for imp in report["improvements"][:5]:
                print(
                    f"  {imp['metric']}: {imp['change_percent']:+.1f}% "
                    f"({imp['baseline']:.2f} → {imp['current']:.2f})"
                )

        if report["recommendations"]:
            print("\n📋 Recommendations:")
            for rec in report["recommendations"][:5]:
                print(f"  [{rec['priority']}] {rec['area']}")
                print(f"    Issue: {rec['issue']}")
                print(f"    Action: {rec['action']}")


def main():
    """Main entry point"""
    import argparse

    parser = argparse.ArgumentParser(description="Detect performance regressions")
    parser.add_argument("--baseline", help="Baseline benchmark file")
    parser.add_argument("--current", help="Current benchmark file")
    parser.add_argument(
        "--latest", action="store_true", help="Compare two most recent benchmarks"
    )
    parser.add_argument("--output", help="Output file for report")

    args = parser.parse_args()

    detector = RegressionDetector()

    if args.latest:
        benchmarks = detector.load_latest_benchmarks(2)
        if len(benchmarks) >= 2:
            # Create temporary files for comparison
            baseline_file = "temp_baseline.json"
            current_file = "temp_current.json"

            # Use the loaded benchmarks directly
            detector.baseline = benchmarks[0]
            detector.current = benchmarks[1]

            # Compare
            detector._compare_generators()
            health_score = detector._calculate_health_score()
            report = detector._generate_report(health_score)
        else:
            print("Not enough benchmark files for comparison")
            sys.exit(1)
    elif args.baseline and args.current:
        report = detector.compare_benchmarks(args.baseline, args.current)
    else:
        print("Please specify --baseline and --current files, or use --latest")
        sys.exit(1)

    # Print summary
    detector.print_summary(report)

    # Export if requested
    if args.output:
        output_path = Path(args.output)
        detector.export_report(report, output_path)
    else:
        # Default output
        output_dir = Path("benchmark_results") / "regression_reports"
        output_dir.mkdir(exist_ok=True)
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        output_path = output_dir / f"regression_{timestamp}.json"
        detector.export_report(report, output_path)


if __name__ == "__main__":
    main()
