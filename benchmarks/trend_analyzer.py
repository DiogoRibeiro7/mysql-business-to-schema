#!/usr/bin/env python3
"""Performance trend analyzer.

Analyzes benchmark results over time to identify trends, patterns, and anomalies.
"""

import json
import statistics
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Any, Tuple
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from dataclasses import dataclass


@dataclass
class TrendPoint:
    """Single data point in a trend."""

    timestamp: datetime
    value: float
    metadata: Optional[Dict[str, Any]] = None


@dataclass
class Trend:
    """Trend analysis results."""

    metric: str
    points: List[TrendPoint]
    direction: str  # "improving", "degrading", "stable"
    change_percent: float
    slope: float
    r_squared: float
    forecast: Optional[List[float]] = None


class TrendAnalyzer:
    """Analyze performance trends from benchmark results."""

    def __init__(self, results_dir: Path):
        """Initialize the trend analyzer."""
        self.results_dir = Path(results_dir)
        self.benchmark_files = []
        self.data = {}

    def load_historical_data(self, days: int = 30) -> None:
        """Load historical benchmark data."""
        cutoff_date = datetime.now() - timedelta(days=days)

        # Find all benchmark result files
        for file_path in self.results_dir.glob("**/*.json"):
            try:
                # Check file date
                file_mtime = datetime.fromtimestamp(file_path.stat().st_mtime)
                if file_mtime < cutoff_date:
                    continue

                # Load and parse file
                with open(file_path, "r") as f:
                    data = json.load(f)

                # Extract timestamp
                timestamp = None
                if "timestamp" in data:
                    timestamp = datetime.fromisoformat(data["timestamp"])
                elif "metadata" in data and "timestamp" in data["metadata"]:
                    timestamp = datetime.fromisoformat(data["metadata"]["timestamp"])
                else:
                    timestamp = file_mtime

                self.benchmark_files.append({
                    "path": file_path,
                    "timestamp": timestamp,
                    "data": data
                })

            except Exception as e:
                print(f"Warning: Failed to load {file_path}: {e}")

        # Sort by timestamp
        self.benchmark_files.sort(key=lambda x: x["timestamp"])

        print(f"Loaded {len(self.benchmark_files)} benchmark files from the last {days} days")

    def extract_metrics(self) -> Dict[str, List[TrendPoint]]:
        """Extract metrics from loaded benchmark data."""
        metrics = {}

        for benchmark in self.benchmark_files:
            timestamp = benchmark["timestamp"]
            data = benchmark["data"]

            # Extract generator metrics
            if "generator" in data.get("results", {}):
                gen_data = data["results"]["generator"]
                if "overall_health" in gen_data:
                    if "generator_health" not in metrics:
                        metrics["generator_health"] = []
                    metrics["generator_health"].append(
                        TrendPoint(timestamp, gen_data["overall_health"])
                    )

                # Extract per-example metrics
                if "results" in gen_data:
                    for example, example_data in gen_data["results"].items():
                        if isinstance(example_data, dict):
                            # Rows per second
                            if "rows_per_second" in example_data:
                                metric_name = f"generator_{example}_rows_per_sec"
                                if metric_name not in metrics:
                                    metrics[metric_name] = []

                                value = example_data["rows_per_second"]
                                if isinstance(value, dict) and "median" in value:
                                    value = value["median"]

                                metrics[metric_name].append(
                                    TrendPoint(timestamp, float(value))
                                )

                            # Memory usage
                            if "memory_mb" in example_data:
                                metric_name = f"generator_{example}_memory_mb"
                                if metric_name not in metrics:
                                    metrics[metric_name] = []

                                value = example_data["memory_mb"]
                                if isinstance(value, dict) and "median" in value:
                                    value = value["median"]

                                metrics[metric_name].append(
                                    TrendPoint(timestamp, float(value))
                                )

            # Extract query performance metrics
            if "query" in data.get("results", {}):
                query_data = data["results"]["query"]
                for db, db_data in query_data.items():
                    if isinstance(db_data, dict) and "queries" in db_data:
                        for query_name, query_result in db_data["queries"].items():
                            if "execution_time" in query_result:
                                metric_name = f"query_{db}_{query_name}_time"
                                if metric_name not in metrics:
                                    metrics[metric_name] = []

                                metrics[metric_name].append(
                                    TrendPoint(timestamp, float(query_result["execution_time"]))
                                )

            # Extract overall health score
            if "health_score" in data:
                if "overall_health" not in metrics:
                    metrics["overall_health"] = []
                metrics["overall_health"].append(
                    TrendPoint(timestamp, data["health_score"])
                )

        return metrics

    def analyze_trends(self, days: int = 30) -> Dict[str, Trend]:
        """Analyze trends in the data."""
        # Load data
        self.load_historical_data(days)

        # Extract metrics
        metrics = self.extract_metrics()

        # Analyze each metric
        trends = {}
        for metric_name, points in metrics.items():
            if len(points) < 2:
                continue

            trend = self.analyze_metric_trend(metric_name, points)
            trends[metric_name] = trend

        return trends

    def analyze_metric_trend(self, metric_name: str, points: List[TrendPoint]) -> Trend:
        """Analyze trend for a specific metric."""
        # Sort points by timestamp
        points.sort(key=lambda x: x.timestamp)

        # Extract values
        timestamps = [p.timestamp for p in points]
        values = [p.value for p in points]

        # Calculate linear regression
        slope, intercept, r_squared = self.calculate_linear_regression(timestamps, values)

        # Determine trend direction
        first_value = values[0] if values else 0
        last_value = values[-1] if values else 0
        change_percent = ((last_value - first_value) / first_value * 100) if first_value != 0 else 0

        # Determine if metric is improving or degrading
        # For metrics like time/memory, lower is better
        # For metrics like health/throughput, higher is better
        is_lower_better = any(x in metric_name.lower() for x in ["time", "memory", "duration"])

        if abs(change_percent) < 5:
            direction = "stable"
        elif change_percent > 0:
            direction = "degrading" if is_lower_better else "improving"
        else:
            direction = "improving" if is_lower_better else "degrading"

        # Generate forecast (simple linear extrapolation)
        forecast = None
        if len(points) >= 5:
            forecast = self.generate_forecast(slope, intercept, timestamps, days=7)

        return Trend(
            metric=metric_name,
            points=points,
            direction=direction,
            change_percent=change_percent,
            slope=slope,
            r_squared=r_squared,
            forecast=forecast
        )

    def calculate_linear_regression(
        self, timestamps: List[datetime], values: List[float]
    ) -> Tuple[float, float, float]:
        """Calculate linear regression for trend analysis."""
        if len(timestamps) < 2:
            return 0, 0, 0

        # Convert timestamps to numeric values (days from first point)
        first_timestamp = timestamps[0]
        x_values = [(t - first_timestamp).total_seconds() / 86400 for t in timestamps]

        # Calculate regression
        n = len(x_values)
        sum_x = sum(x_values)
        sum_y = sum(values)
        sum_xx = sum(x * x for x in x_values)
        sum_xy = sum(x * y for x, y in zip(x_values, values))

        # Calculate slope and intercept
        denominator = n * sum_xx - sum_x * sum_x
        if denominator == 0:
            return 0, sum_y / n if n > 0 else 0, 0

        slope = (n * sum_xy - sum_x * sum_y) / denominator
        intercept = (sum_y - slope * sum_x) / n

        # Calculate R-squared
        y_mean = sum_y / n
        ss_total = sum((y - y_mean) ** 2 for y in values)
        ss_residual = sum((y - (slope * x + intercept)) ** 2 for x, y in zip(x_values, values))

        r_squared = 1 - (ss_residual / ss_total) if ss_total != 0 else 0

        return slope, intercept, r_squared

    def generate_forecast(
        self, slope: float, intercept: float, timestamps: List[datetime], days: int = 7
    ) -> List[float]:
        """Generate forecast for future values."""
        if not timestamps:
            return []

        first_timestamp = timestamps[0]
        last_timestamp = timestamps[-1]

        forecast = []
        for i in range(1, days + 1):
            future_timestamp = last_timestamp + timedelta(days=i)
            days_from_start = (future_timestamp - first_timestamp).total_seconds() / 86400
            forecast_value = slope * days_from_start + intercept
            forecast.append(max(0, forecast_value))  # Ensure non-negative

        return forecast

    def plot_trends(self, metric_name: str, output_path: Optional[Path] = None) -> None:
        """Plot trend for a specific metric."""
        # Load data if not already loaded
        if not self.benchmark_files:
            self.load_historical_data()

        metrics = self.extract_metrics()
        if metric_name not in metrics:
            print(f"Metric '{metric_name}' not found")
            return

        points = metrics[metric_name]
        trend = self.analyze_metric_trend(metric_name, points)

        # Create plot
        fig, ax = plt.subplots(figsize=(12, 6))

        # Plot actual data
        timestamps = [p.timestamp for p in points]
        values = [p.value for p in points]
        ax.plot(timestamps, values, 'o-', label='Actual', linewidth=2, markersize=8)

        # Plot trend line
        if len(points) >= 2:
            first_timestamp = timestamps[0]
            x_values = [(t - first_timestamp).total_seconds() / 86400 for t in timestamps]
            trend_values = [trend.slope * x + trend.intercept for x in x_values]
            ax.plot(timestamps, trend_values, '--', label='Trend', linewidth=2, alpha=0.7)

        # Plot forecast
        if trend.forecast:
            last_timestamp = timestamps[-1]
            forecast_timestamps = [
                last_timestamp + timedelta(days=i + 1)
                for i in range(len(trend.forecast))
            ]
            ax.plot(forecast_timestamps, trend.forecast, ':', label='Forecast', linewidth=2, alpha=0.5)

        # Formatting
        ax.set_title(f"Trend Analysis: {metric_name}", fontsize=14, fontweight='bold')
        ax.set_xlabel("Date", fontsize=12)
        ax.set_ylabel("Value", fontsize=12)
        ax.grid(True, alpha=0.3)
        ax.legend(loc='best')

        # Format x-axis dates
        ax.xaxis.set_major_formatter(mdates.DateFormatter('%Y-%m-%d'))
        ax.xaxis.set_major_locator(mdates.DayLocator(interval=max(1, len(timestamps) // 10)))
        plt.xticks(rotation=45)

        # Add trend information
        trend_text = (
            f"Direction: {trend.direction.upper()}\n"
            f"Change: {trend.change_percent:+.1f}%\n"
            f"R²: {trend.r_squared:.3f}"
        )
        ax.text(0.02, 0.98, trend_text, transform=ax.transAxes,
                verticalalignment='top', bbox=dict(boxstyle='round', facecolor='wheat', alpha=0.5))

        plt.tight_layout()

        # Save or show
        if output_path:
            plt.savefig(output_path, dpi=300, bbox_inches='tight')
            print(f"Plot saved to: {output_path}")
        else:
            plt.show()

        plt.close()

    def generate_report(self, trends: Dict[str, Trend]) -> str:
        """Generate a text report of trend analysis."""
        report = []
        report.append("=" * 70)
        report.append("PERFORMANCE TREND ANALYSIS REPORT")
        report.append("=" * 70)
        report.append(f"Generated: {datetime.now().isoformat()}")
        report.append(f"Data Points: {len(self.benchmark_files)}")
        report.append(f"Metrics Analyzed: {len(trends)}")
        report.append("")

        # Summary statistics
        improving = sum(1 for t in trends.values() if t.direction == "improving")
        degrading = sum(1 for t in trends.values() if t.direction == "degrading")
        stable = sum(1 for t in trends.values() if t.direction == "stable")

        report.append("SUMMARY")
        report.append("-" * 40)
        report.append(f"🟢 Improving: {improving}")
        report.append(f"🔴 Degrading: {degrading}")
        report.append(f"🟡 Stable: {stable}")
        report.append("")

        # Detailed trends
        report.append("DETAILED TRENDS")
        report.append("-" * 40)

        # Sort trends by change percent
        sorted_trends = sorted(trends.values(), key=lambda x: abs(x.change_percent), reverse=True)

        for trend in sorted_trends:
            emoji = "🟢" if trend.direction == "improving" else "🔴" if trend.direction == "degrading" else "🟡"
            report.append("")
            report.append(f"{emoji} {trend.metric}")
            report.append(f"   Direction: {trend.direction.upper()}")
            report.append(f"   Change: {trend.change_percent:+.2f}%")
            report.append(f"   Slope: {trend.slope:+.4f}")
            report.append(f"   R²: {trend.r_squared:.3f}")
            report.append(f"   Data Points: {len(trend.points)}")

            if trend.forecast:
                report.append(f"   7-Day Forecast: {trend.forecast[-1]:.2f}")

        # Alerts
        report.append("")
        report.append("ALERTS")
        report.append("-" * 40)

        alerts = []
        for trend in trends.values():
            if trend.direction == "degrading" and abs(trend.change_percent) > 20:
                alerts.append(f"⚠️  CRITICAL: {trend.metric} degraded by {abs(trend.change_percent):.1f}%")
            elif trend.direction == "degrading" and abs(trend.change_percent) > 10:
                alerts.append(f"⚠️  WARNING: {trend.metric} degraded by {abs(trend.change_percent):.1f}%")

        if alerts:
            report.extend(alerts)
        else:
            report.append("✅ No critical alerts")

        report.append("")
        report.append("=" * 70)

        return "\n".join(report)

    def detect_anomalies(self, metric_name: str, threshold_std: float = 3.0) -> List[TrendPoint]:
        """Detect anomalies in a metric using statistical methods."""
        metrics = self.extract_metrics()
        if metric_name not in metrics:
            return []

        points = metrics[metric_name]
        if len(points) < 10:
            return []  # Need sufficient data for anomaly detection

        values = [p.value for p in points]
        mean = statistics.mean(values)
        stdev = statistics.stdev(values)

        anomalies = []
        for point in points:
            z_score = abs((point.value - mean) / stdev) if stdev > 0 else 0
            if z_score > threshold_std:
                anomalies.append(point)

        return anomalies


if __name__ == "__main__":
    # Example usage
    import argparse

    parser = argparse.ArgumentParser(description="Analyze performance trends")
    parser.add_argument("--days", type=int, default=30, help="Number of days to analyze")
    parser.add_argument("--plot", help="Metric name to plot")
    parser.add_argument("--output", type=Path, help="Output path for plot")

    args = parser.parse_args()

    results_dir = Path(__file__).parent / "benchmark_results"
    analyzer = TrendAnalyzer(results_dir)

    # Analyze trends
    trends = analyzer.analyze_trends(days=args.days)

    # Generate report
    report = analyzer.generate_report(trends)
    print(report)

    # Plot if requested
    if args.plot:
        analyzer.plot_trends(args.plot, args.output)