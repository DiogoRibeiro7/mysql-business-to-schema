#!/usr/bin/env python3
"""Performance report generator.

Generates comprehensive performance reports in HTML, Markdown, and other formats.
"""

import json
import statistics
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Any
import base64
import io
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches


class ReportGenerator:
    """Generate performance reports in various formats."""

    def __init__(self, benchmark_results: Dict[str, Any]):
        """Initialize the report generator."""
        self.results = benchmark_results
        self.timestamp = datetime.now()

    def generate(self, format: str, output_path: Path) -> None:
        """Generate report in specified format."""
        if format == "html":
            content = self.generate_html()
        elif format == "markdown":
            content = self.generate_markdown()
        elif format == "json":
            content = json.dumps(self.results, indent=2, default=str)
        else:
            raise ValueError(f"Unsupported format: {format}")

        # Write to file
        with open(output_path, "w", encoding="utf-8") as f:
            f.write(content)

        print(f"Report generated: {output_path}")

    def generate_html(self) -> str:
        """Generate HTML performance report."""
        html = [
            "<!DOCTYPE html>",
            "<html>",
            "<head>",
            "<meta charset='utf-8'>",
            "<title>Performance Benchmark Report</title>",
            self._get_html_style(),
            "</head>",
            "<body>",
            "<div class='container'>",
        ]

        # Header
        html.append(self._generate_html_header())

        # Summary cards
        html.append(self._generate_html_summary_cards())

        # Generator benchmarks
        if "generator" in self.results.get("results", {}):
            html.append(self._generate_html_generator_section())

        # Query benchmarks
        if "query" in self.results.get("results", {}):
            html.append(self._generate_html_query_section())

        # Index analysis
        if "index" in self.results.get("results", {}):
            html.append(self._generate_html_index_section())

        # Regression detection
        if "regression" in self.results.get("results", {}):
            html.append(self._generate_html_regression_section())

        # Recommendations
        if "recommendations" in self.results:
            html.append(self._generate_html_recommendations())

        # Charts
        html.append(self._generate_html_charts())

        # Footer
        html.append(self._generate_html_footer())

        html.extend([
            "</div>",
            "</body>",
            "</html>"
        ])

        return "\n".join(html)

    def _get_html_style(self) -> str:
        """Get CSS styles for HTML report."""
        return """
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body {
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                min-height: 100vh;
                padding: 2rem;
            }
            .container {
                max-width: 1400px;
                margin: 0 auto;
                background: white;
                border-radius: 20px;
                padding: 3rem;
                box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            }
            h1 {
                font-size: 2.5rem;
                color: #2d3748;
                margin-bottom: 0.5rem;
            }
            h2 {
                font-size: 1.8rem;
                color: #4a5568;
                margin-top: 3rem;
                margin-bottom: 1.5rem;
                padding-bottom: 0.5rem;
                border-bottom: 2px solid #e2e8f0;
            }
            h3 {
                font-size: 1.3rem;
                color: #4a5568;
                margin-top: 1.5rem;
                margin-bottom: 1rem;
            }
            .subtitle {
                color: #718096;
                font-size: 1.1rem;
                margin-bottom: 2rem;
            }
            .cards {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
                gap: 1.5rem;
                margin: 2rem 0;
            }
            .card {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                padding: 1.5rem;
                border-radius: 15px;
                color: white;
                box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            }
            .card-title {
                font-size: 0.9rem;
                opacity: 0.9;
                margin-bottom: 0.5rem;
            }
            .card-value {
                font-size: 2rem;
                font-weight: bold;
            }
            .card-subtitle {
                font-size: 0.85rem;
                opacity: 0.8;
                margin-top: 0.5rem;
            }
            .card.success { background: linear-gradient(135deg, #48bb78 0%, #38a169 100%); }
            .card.warning { background: linear-gradient(135deg, #ed8936 0%, #dd6b20 100%); }
            .card.danger { background: linear-gradient(135deg, #f56565 0%, #e53e3e 100%); }
            .table-container {
                overflow-x: auto;
                margin: 1.5rem 0;
            }
            table {
                width: 100%;
                border-collapse: collapse;
                font-size: 0.95rem;
            }
            th {
                background: #f7fafc;
                color: #2d3748;
                padding: 1rem;
                text-align: left;
                font-weight: 600;
                border-bottom: 2px solid #e2e8f0;
            }
            td {
                padding: 0.75rem 1rem;
                border-bottom: 1px solid #e2e8f0;
            }
            tr:hover {
                background: #f7fafc;
            }
            .badge {
                display: inline-block;
                padding: 0.25rem 0.75rem;
                border-radius: 20px;
                font-size: 0.85rem;
                font-weight: 600;
            }
            .badge-success { background: #c6f6d5; color: #22543d; }
            .badge-warning { background: #fed7d7; color: #742a2a; }
            .badge-danger { background: #feb2b2; color: #742a2a; }
            .badge-info { background: #bee3f8; color: #2c5282; }
            .recommendation {
                background: #f7fafc;
                border-left: 4px solid #667eea;
                padding: 1rem;
                margin: 1rem 0;
                border-radius: 5px;
            }
            .chart-container {
                margin: 2rem 0;
                text-align: center;
            }
            .chart-container img {
                max-width: 100%;
                height: auto;
                border-radius: 10px;
                box-shadow: 0 5px 20px rgba(0,0,0,0.1);
            }
            .footer {
                margin-top: 3rem;
                padding-top: 2rem;
                border-top: 1px solid #e2e8f0;
                text-align: center;
                color: #718096;
                font-size: 0.9rem;
            }
            .metric-grid {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                gap: 1rem;
                margin: 1rem 0;
            }
            .metric-item {
                background: #f7fafc;
                padding: 1rem;
                border-radius: 8px;
            }
            .metric-label {
                font-size: 0.85rem;
                color: #718096;
                margin-bottom: 0.25rem;
            }
            .metric-value {
                font-size: 1.5rem;
                font-weight: bold;
                color: #2d3748;
            }
        </style>
        """

    def _generate_html_header(self) -> str:
        """Generate HTML header."""
        return f"""
        <h1>🚀 Performance Benchmark Report</h1>
        <div class='subtitle'>Generated on {self.timestamp.strftime('%Y-%m-%d %H:%M:%S')}</div>
        """

    def _generate_html_summary_cards(self) -> str:
        """Generate summary cards section."""
        summary = self.results.get("summary", {})
        health_score = self.results.get("health_score", 0)

        health_class = "success" if health_score >= 70 else "warning" if health_score >= 50 else "danger"

        cards = f"""
        <div class='cards'>
            <div class='card {health_class}'>
                <div class='card-title'>Overall Health Score</div>
                <div class='card-value'>{health_score:.1f}/100</div>
                <div class='card-subtitle'>System Performance</div>
            </div>
            <div class='card'>
                <div class='card-title'>Total Benchmarks</div>
                <div class='card-value'>{summary.get('total_benchmarks_run', 0)}</div>
                <div class='card-subtitle'>Tests Executed</div>
            </div>
            <div class='card success'>
                <div class='card-title'>Successful</div>
                <div class='card-value'>{summary.get('successful', 0)}</div>
                <div class='card-subtitle'>Passed Tests</div>
            </div>
        """

        if summary.get('failed', 0) > 0:
            cards += f"""
            <div class='card danger'>
                <div class='card-title'>Failed</div>
                <div class='card-value'>{summary.get('failed', 0)}</div>
                <div class='card-subtitle'>Failed Tests</div>
            </div>
            """

        cards += "</div>"
        return cards

    def _generate_html_generator_section(self) -> str:
        """Generate HTML section for generator benchmarks."""
        gen_results = self.results["results"]["generator"]

        html = ["<h2>📊 Generator Benchmarks</h2>"]

        # Overall metrics
        if "overall_health" in gen_results:
            html.append(f"""
            <div class='metric-grid'>
                <div class='metric-item'>
                    <div class='metric-label'>Overall Health</div>
                    <div class='metric-value'>{gen_results['overall_health']:.1f}%</div>
                </div>
                <div class='metric-item'>
                    <div class='metric-label'>Total Generators</div>
                    <div class='metric-value'>{gen_results.get('total_generators', 0)}</div>
                </div>
                <div class='metric-item'>
                    <div class='metric-label'>Successful</div>
                    <div class='metric-value'>{gen_results.get('successful', 0)}</div>
                </div>
            </div>
            """)

        # Rankings table
        if "rankings" in gen_results:
            html.append("<h3>Performance Rankings</h3>")
            html.append(self._generate_rankings_table(gen_results["rankings"]))

        return "\n".join(html)

    def _generate_rankings_table(self, rankings: Dict) -> str:
        """Generate HTML table for rankings."""
        html = ["<div class='table-container'><table>"]

        # Speed rankings
        if "by_speed" in rankings:
            html.append("<tr><th colspan='2'>🏃 Fastest Generators (rows/sec)</th></tr>")
            for item in rankings["by_speed"][:5]:
                html.append(f"""
                <tr>
                    <td>{item['example']}</td>
                    <td><strong>{item['rows_per_second']:.1f}</strong> rows/sec</td>
                </tr>
                """)

        # Memory rankings
        if "by_memory" in rankings:
            html.append("<tr><th colspan='2'>💾 Most Efficient (memory)</th></tr>")
            for item in rankings["by_memory"][:5]:
                html.append(f"""
                <tr>
                    <td>{item['example']}</td>
                    <td><strong>{item['memory_mb']:.1f}</strong> MB</td>
                </tr>
                """)

        html.append("</table></div>")
        return "\n".join(html)

    def _generate_html_query_section(self) -> str:
        """Generate HTML section for query benchmarks."""
        return "<h2>⚡ Query Performance</h2><p>Query benchmark results would go here...</p>"

    def _generate_html_index_section(self) -> str:
        """Generate HTML section for index analysis."""
        return "<h2>🔍 Index Analysis</h2><p>Index effectiveness analysis would go here...</p>"

    def _generate_html_regression_section(self) -> str:
        """Generate HTML section for regression detection."""
        regression_results = self.results["results"].get("regression", {})

        html = ["<h2>📉 Regression Detection</h2>"]

        if "error" in regression_results:
            html.append(f"<p>Error: {regression_results['error']}</p>")
        elif "message" in regression_results:
            html.append(f"<p>{regression_results['message']}</p>")
        else:
            html.append("<p>Regression analysis complete.</p>")

        return "\n".join(html)

    def _generate_html_recommendations(self) -> str:
        """Generate HTML recommendations section."""
        recommendations = self.results.get("recommendations", [])

        html = ["<h2>💡 Recommendations</h2>"]

        for rec in recommendations:
            # Determine recommendation type based on emoji/content
            if "🔴" in rec or "Critical" in rec:
                style = "danger"
            elif "🟡" in rec or "Warning" in rec:
                style = "warning"
            else:
                style = "info"

            html.append(f"<div class='recommendation'>{rec}</div>")

        return "\n".join(html)

    def _generate_html_charts(self) -> str:
        """Generate HTML charts section."""
        html = ["<h2>📈 Performance Charts</h2>"]

        # Generate health score pie chart
        health_chart = self._generate_health_score_chart()
        if health_chart:
            html.append(f"""
            <div class='chart-container'>
                <h3>Health Score Distribution</h3>
                <img src='data:image/png;base64,{health_chart}' alt='Health Score Chart'>
            </div>
            """)

        return "\n".join(html)

    def _generate_health_score_chart(self) -> Optional[str]:
        """Generate health score pie chart as base64 string."""
        try:
            health_score = self.results.get("health_score", 0)

            fig, ax = plt.subplots(figsize=(8, 6))

            # Data for pie chart
            sizes = [health_score, 100 - health_score]
            colors = ['#48bb78', '#e2e8f0']
            explode = (0.05, 0)

            # Create pie chart
            wedges, texts, autotexts = ax.pie(
                sizes,
                explode=explode,
                colors=colors,
                autopct='%1.1f%%',
                startangle=90
            )

            # Style
            ax.set_title(f'Overall Health Score: {health_score:.1f}/100', fontsize=16, fontweight='bold')

            # Legend
            ax.legend(
                ['Healthy', 'Room for Improvement'],
                loc="center right",
                bbox_to_anchor=(1.2, 0.5)
            )

            # Save to base64
            buffer = io.BytesIO()
            plt.savefig(buffer, format='png', bbox_inches='tight', dpi=100)
            buffer.seek(0)
            image_base64 = base64.b64encode(buffer.read()).decode()
            plt.close()

            return image_base64

        except Exception as e:
            print(f"Failed to generate chart: {e}")
            return None

    def _generate_html_footer(self) -> str:
        """Generate HTML footer."""
        return f"""
        <div class='footer'>
            <p>Generated by MySQL Business-to-Schema Benchmark Suite</p>
            <p>{self.timestamp.strftime('%Y-%m-%d %H:%M:%S')}</p>
        </div>
        """

    def generate_markdown(self) -> str:
        """Generate Markdown performance report."""
        md = []

        # Header
        md.append("# Performance Benchmark Report")
        md.append(f"\n*Generated on {self.timestamp.strftime('%Y-%m-%d %H:%M:%S')}*\n")

        # Summary
        summary = self.results.get("summary", {})
        health_score = self.results.get("health_score", 0)

        md.append("## 📊 Summary")
        md.append("")
        md.append(f"- **Overall Health Score**: {health_score:.1f}/100")
        md.append(f"- **Total Benchmarks**: {summary.get('total_benchmarks_run', 0)}")
        md.append(f"- **Successful**: {summary.get('successful', 0)}")
        md.append(f"- **Failed**: {summary.get('failed', 0)}")
        md.append("")

        # Generator benchmarks
        if "generator" in self.results.get("results", {}):
            md.append("## 🚀 Generator Benchmarks")
            gen_results = self.results["results"]["generator"]
            md.append("")
            md.append(f"- **Overall Health**: {gen_results.get('overall_health', 0):.1f}%")
            md.append(f"- **Total Generators**: {gen_results.get('total_generators', 0)}")
            md.append("")

            # Rankings
            if "rankings" in gen_results:
                md.append("### Top Performers")
                md.append("")
                md.append("#### Fastest (rows/sec)")
                md.append("")
                md.append("| Generator | Rows/sec |")
                md.append("|-----------|----------|")
                for item in gen_results["rankings"]["by_speed"][:5]:
                    md.append(f"| {item['example']} | {item['rows_per_second']:.1f} |")
                md.append("")

                md.append("#### Most Memory Efficient")
                md.append("")
                md.append("| Generator | Memory (MB) |")
                md.append("|-----------|-------------|")
                for item in gen_results["rankings"]["by_memory"][:5]:
                    md.append(f"| {item['example']} | {item['memory_mb']:.1f} |")
                md.append("")

        # Query benchmarks
        if "query" in self.results.get("results", {}):
            md.append("## ⚡ Query Performance")
            md.append("")
            md.append("Query benchmark results...")
            md.append("")

        # Index analysis
        if "index" in self.results.get("results", {}):
            md.append("## 🔍 Index Analysis")
            md.append("")
            md.append("Index effectiveness results...")
            md.append("")

        # Recommendations
        if "recommendations" in self.results:
            md.append("## 💡 Recommendations")
            md.append("")
            for rec in self.results["recommendations"]:
                md.append(f"- {rec}")
            md.append("")

        # Footer
        md.append("---")
        md.append("")
        md.append("*Generated by MySQL Business-to-Schema Benchmark Suite*")

        return "\n".join(md)


def main():
    """Main entry point."""
    import argparse

    parser = argparse.ArgumentParser(description="Generate performance reports")
    parser.add_argument("benchmark_file", type=Path, help="Benchmark results JSON file")
    parser.add_argument("--format", choices=["html", "markdown", "json"], default="html",
                       help="Output format")
    parser.add_argument("--output", type=Path, required=True, help="Output file path")

    args = parser.parse_args()

    # Load benchmark results
    with open(args.benchmark_file, "r") as f:
        results = json.load(f)

    # Generate report
    generator = ReportGenerator(results)
    generator.generate(args.format, args.output)

    return 0


if __name__ == "__main__":
    import sys
    sys.exit(main())