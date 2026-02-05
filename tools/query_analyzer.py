#!/usr/bin/env python3
"""
MySQL Query Performance Analyzer

Analyzes query performance across all database examples, providing:
- EXPLAIN plan analysis
- Execution time benchmarks
- Index usage statistics
- Optimization recommendations
"""

import argparse
import json
import re
import time
from pathlib import Path
from typing import Dict, List, Tuple, Optional
import mysql.connector
from mysql.connector import Error
from tabulate import tabulate
import yaml

class QueryPerformanceAnalyzer:
    def __init__(self, host='localhost', port=3306, user='root', password=''):
        """Initialize the analyzer with database connection parameters."""
        self.host = host
        self.port = port
        self.user = user
        self.password = password
        self.connection = None
        self.results = []

    def connect(self, database: str) -> bool:
        """Connect to a specific database."""
        try:
            if self.connection:
                self.connection.close()

            self.connection = mysql.connector.connect(
                host=self.host,
                port=self.port,
                user=self.user,
                password=self.password,
                database=database
            )
            return True
        except Error as e:
            print(f"Error connecting to database {database}: {e}")
            return False

    def analyze_query(self, query: str, query_name: str = "Query") -> Dict:
        """Analyze a single query's performance."""
        if not self.connection:
            return {"error": "No database connection"}

        cursor = self.connection.cursor(dictionary=True)
        result = {
            "query_name": query_name,
            "query": query[:200] + "..." if len(query) > 200 else query,
            "execution_times": [],
            "explain_plan": [],
            "index_usage": {},
            "recommendations": []
        }

        try:
            # Run EXPLAIN
            explain_query = f"EXPLAIN {query}"
            cursor.execute(explain_query)
            result["explain_plan"] = cursor.fetchall()

            # Analyze EXPLAIN output
            result["index_usage"] = self._analyze_explain(result["explain_plan"])

            # Run query multiple times for timing
            for i in range(3):
                start_time = time.time()
                cursor.execute(query)
                cursor.fetchall()  # Fetch all results to complete execution
                execution_time = (time.time() - start_time) * 1000  # Convert to ms
                result["execution_times"].append(execution_time)

            # Calculate statistics
            result["avg_execution_time"] = sum(result["execution_times"]) / len(result["execution_times"])
            result["min_execution_time"] = min(result["execution_times"])
            result["max_execution_time"] = max(result["execution_times"])

            # Generate recommendations
            result["recommendations"] = self._generate_recommendations(
                result["explain_plan"],
                result["index_usage"],
                result["avg_execution_time"]
            )

        except Error as e:
            result["error"] = str(e)

        finally:
            cursor.close()

        return result

    def _analyze_explain(self, explain_plan: List[Dict]) -> Dict:
        """Analyze EXPLAIN output for index usage and performance issues."""
        analysis = {
            "indexes_used": [],
            "full_table_scans": [],
            "filesorts": False,
            "temporary_tables": False,
            "total_rows_examined": 0
        }

        for row in explain_plan:
            # Check for index usage
            if row.get('key'):
                analysis["indexes_used"].append({
                    "table": row.get('table'),
                    "index": row.get('key'),
                    "key_len": row.get('key_len')
                })

            # Check for full table scans
            if row.get('type') in ['ALL', 'index']:
                analysis["full_table_scans"].append({
                    "table": row.get('table'),
                    "rows": row.get('rows', 0)
                })

            # Check for filesort
            if row.get('Extra') and 'filesort' in str(row.get('Extra')).lower():
                analysis["filesorts"] = True

            # Check for temporary tables
            if row.get('Extra') and 'temporary' in str(row.get('Extra')).lower():
                analysis["temporary_tables"] = True

            # Sum rows examined
            analysis["total_rows_examined"] += int(row.get('rows', 0))

        return analysis

    def _generate_recommendations(self, explain_plan: List[Dict], index_usage: Dict, avg_time: float) -> List[str]:
        """Generate optimization recommendations based on analysis."""
        recommendations = []

        # Check for missing indexes
        if index_usage["full_table_scans"]:
            for scan in index_usage["full_table_scans"]:
                if scan["rows"] > 1000:
                    recommendations.append(
                        f"⚠️ Table '{scan['table']}' is doing a full scan of {scan['rows']} rows. "
                        f"Consider adding an index on the WHERE/JOIN columns."
                    )

        # Check for filesort
        if index_usage["filesorts"]:
            recommendations.append(
                "⚠️ Query uses filesort for ORDER BY. Consider adding an index on the ORDER BY columns."
            )

        # Check for temporary tables
        if index_usage["temporary_tables"]:
            recommendations.append(
                "⚠️ Query creates temporary tables. Consider optimizing GROUP BY or DISTINCT operations."
            )

        # Check execution time
        if avg_time > 1000:  # More than 1 second
            recommendations.append(
                f"⚠️ Query takes {avg_time:.2f}ms on average. Consider optimization."
            )
        elif avg_time < 10:  # Less than 10ms
            recommendations.append(
                f"✅ Query performs well with {avg_time:.2f}ms average execution time."
            )

        # Check rows examined vs returned
        for row in explain_plan:
            if row.get('filtered') and float(row.get('filtered', 100)) < 25:
                recommendations.append(
                    f"⚠️ Table '{row.get('table')}' has low filtering efficiency ({row.get('filtered')}%). "
                    f"Consider adding more selective indexes."
                )

        if not recommendations:
            recommendations.append("✅ Query appears to be well optimized.")

        return recommendations

    def analyze_query_file(self, file_path: Path, database: str) -> List[Dict]:
        """Analyze all queries in a SQL file."""
        if not self.connect(database):
            return []

        results = []
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Extract queries (simple pattern - may need refinement)
        queries = self._extract_queries(content)

        print(f"\nAnalyzing {len(queries)} queries from {file_path.name}...")

        for i, (query, comment) in enumerate(queries, 1):
            query_name = comment if comment else f"Query {i}"
            print(f"  Analyzing: {query_name}")

            result = self.analyze_query(query, query_name)
            results.append(result)

        return results

    def _extract_queries(self, sql_content: str) -> List[Tuple[str, Optional[str]]]:
        """Extract SELECT queries from SQL file content."""
        queries = []

        # Remove single-line comments but capture query descriptions
        lines = sql_content.split('\n')
        current_query = []
        current_comment = None

        for line in lines:
            # Check for comment with query description
            if line.strip().startswith('--') and not current_query:
                current_comment = line.strip()[2:].strip()
            elif line.strip() and not line.strip().startswith('--'):
                current_query.append(line)

                # Check if query is complete (ends with semicolon)
                if ';' in line:
                    query_text = ' '.join(current_query)

                    # Only process SELECT queries
                    if 'SELECT' in query_text.upper():
                        # Clean up the query
                        query_text = query_text.split(';')[0].strip()
                        queries.append((query_text, current_comment))

                    current_query = []
                    current_comment = None

        return queries

    def generate_report(self, results: List[Dict], output_format: str = 'text') -> str:
        """Generate a performance report from analysis results."""
        if output_format == 'json':
            return json.dumps(results, indent=2, default=str)

        report = []
        report.append("=" * 80)
        report.append("MYSQL QUERY PERFORMANCE ANALYSIS REPORT")
        report.append("=" * 80)

        for result in results:
            if "error" in result:
                report.append(f"\n❌ {result['query_name']}")
                report.append(f"   Error: {result['error']}")
                continue

            report.append(f"\n📊 {result['query_name']}")
            report.append(f"   Query: {result['query']}")

            # Execution times
            report.append(f"\n   ⏱️ Execution Times:")
            report.append(f"      Average: {result['avg_execution_time']:.2f}ms")
            report.append(f"      Min: {result['min_execution_time']:.2f}ms")
            report.append(f"      Max: {result['max_execution_time']:.2f}ms")

            # Index usage
            index_info = result['index_usage']
            report.append(f"\n   📚 Index Usage:")

            if index_info['indexes_used']:
                for idx in index_info['indexes_used']:
                    report.append(f"      ✓ Table '{idx['table']}' uses index '{idx['index']}'")
            else:
                report.append(f"      ⚠️ No indexes used")

            if index_info['full_table_scans']:
                for scan in index_info['full_table_scans']:
                    report.append(f"      ⚠️ Full scan on '{scan['table']}' ({scan['rows']} rows)")

            report.append(f"      Total rows examined: {index_info['total_rows_examined']}")

            # Recommendations
            report.append(f"\n   💡 Recommendations:")
            for rec in result['recommendations']:
                report.append(f"      {rec}")

        return "\n".join(report)

    def analyze_example(self, example_dir: Path) -> Dict:
        """Analyze all queries for a specific example."""
        example_name = example_dir.name
        database_name = self._get_database_name(example_name)

        print(f"\n🔍 Analyzing {example_name} (database: {database_name})")

        results = {
            "example": example_name,
            "database": database_name,
            "query_files": {}
        }

        # Find all query files
        query_dir = example_dir / "queries"
        if query_dir.exists():
            for query_file in sorted(query_dir.glob("*.sql")):
                file_results = self.analyze_query_file(query_file, database_name)
                results["query_files"][query_file.name] = file_results

        return results

    def _get_database_name(self, example_name: str) -> str:
        """Extract database name from example directory name."""
        # Map example names to database names
        mapping = {
            "example_01_clinic": "clinic",
            "example_02_iot_bins": "iot_bins",
            "example_03_smart_energy": "smart_energy",
            "example_04_ecommerce": "ecommerce",
            "example_05_industrial_iot": "industrial_iot",
            "example_06_smart_agriculture": "smart_agriculture",
            "example_07_fleet_management": "fleet_management",
            "example_08_healthcare_iot": "healthcare_iot",
            "example_09_streaming_ml": "streaming_ml",
            "example_10_fintech": "fintech"
        }
        return mapping.get(example_name, example_name.split('_', 2)[-1])

    def compare_examples(self, results: List[Dict]) -> str:
        """Generate a comparison report across all examples."""
        comparison = []
        comparison.append("\n" + "=" * 80)
        comparison.append("PERFORMANCE COMPARISON ACROSS EXAMPLES")
        comparison.append("=" * 80)

        summary_data = []

        for example_result in results:
            total_queries = 0
            total_time = 0
            slow_queries = 0
            optimized_queries = 0
            queries_with_issues = 0

            for file_name, file_queries in example_result["query_files"].items():
                for query in file_queries:
                    if "error" not in query:
                        total_queries += 1
                        total_time += query['avg_execution_time']

                        if query['avg_execution_time'] > 100:  # >100ms is slow
                            slow_queries += 1
                        elif query['avg_execution_time'] < 10:  # <10ms is fast
                            optimized_queries += 1

                        if query['index_usage']['full_table_scans'] or \
                           query['index_usage']['filesorts'] or \
                           query['index_usage']['temporary_tables']:
                            queries_with_issues += 1

            if total_queries > 0:
                summary_data.append([
                    example_result['example'],
                    total_queries,
                    f"{total_time/total_queries:.2f}ms",
                    slow_queries,
                    optimized_queries,
                    queries_with_issues
                ])

        headers = ["Example", "Total Queries", "Avg Time", "Slow", "Optimized", "Issues"]
        comparison.append(tabulate(summary_data, headers=headers, tablefmt="grid"))

        return "\n".join(comparison)

def main():
    parser = argparse.ArgumentParser(description="MySQL Query Performance Analyzer")
    parser.add_argument("--host", default="localhost", help="MySQL host")
    parser.add_argument("--port", type=int, default=3306, help="MySQL port")
    parser.add_argument("--user", default="root", help="MySQL user")
    parser.add_argument("--password", default="", help="MySQL password")
    parser.add_argument("--example", help="Specific example to analyze (e.g., example_01_clinic)")
    parser.add_argument("--all", action="store_true", help="Analyze all examples")
    parser.add_argument("--output", choices=["text", "json"], default="text", help="Output format")
    parser.add_argument("--save", help="Save report to file")

    args = parser.parse_args()

    analyzer = QueryPerformanceAnalyzer(
        host=args.host,
        port=args.port,
        user=args.user,
        password=args.password
    )

    results = []

    if args.all:
        # Analyze all examples
        project_root = Path(__file__).parent.parent
        for example_dir in sorted(project_root.glob("example_*")):
            if example_dir.is_dir():
                try:
                    result = analyzer.analyze_example(example_dir)
                    results.append(result)
                except Exception as e:
                    print(f"Error analyzing {example_dir}: {e}")

    elif args.example:
        # Analyze specific example
        project_root = Path(__file__).parent.parent
        example_dir = project_root / args.example
        if example_dir.exists():
            result = analyzer.analyze_example(example_dir)
            results.append(result)
        else:
            print(f"Example directory not found: {args.example}")
            return

    else:
        print("Please specify --example or --all")
        return

    # Generate reports
    for result in results:
        all_queries = []
        for file_queries in result["query_files"].values():
            all_queries.extend(file_queries)

        report = analyzer.generate_report(all_queries, args.output)
        print(report)

    # Generate comparison if multiple examples
    if len(results) > 1:
        comparison = analyzer.compare_examples(results)
        print(comparison)

    # Save report if requested
    if args.save:
        with open(args.save, 'w') as f:
            for result in results:
                all_queries = []
                for file_queries in result["query_files"].values():
                    all_queries.extend(file_queries)
                report = analyzer.generate_report(all_queries, args.output)
                f.write(report)
                f.write("\n\n")

            if len(results) > 1:
                f.write(analyzer.compare_examples(results))

        print(f"\nReport saved to: {args.save}")

if __name__ == "__main__":
    main()