#!/usr/bin/env python3
"""
Query Performance Benchmarking Tool

This module benchmarks query performance across all database examples,
measuring execution time, resource usage, and index effectiveness.
"""

import os
import sys
import time
import json
import mysql.connector
from datetime import datetime
from typing import Dict, List, Tuple, Optional, Any
from pathlib import Path
import statistics
import hashlib
from dataclasses import dataclass, asdict
from enum import Enum

# Add parent directory to path
sys.path.append(str(Path(__file__).parent.parent))

class QueryType(Enum):
    """Types of queries to benchmark"""
    SIMPLE_SELECT = "simple_select"
    COMPLEX_JOIN = "complex_join"
    AGGREGATE = "aggregate"
    SUBQUERY = "subquery"
    FULL_TEXT = "full_text"
    RANGE_SCAN = "range_scan"
    INDEX_SCAN = "index_scan"
    FULL_TABLE_SCAN = "full_table_scan"

@dataclass
class QueryBenchmark:
    """Container for query benchmark results"""
    query_id: str
    query_type: QueryType
    sql: str
    execution_time: float
    rows_examined: int
    rows_returned: int
    index_used: Optional[str]
    explain_plan: Dict
    cache_hit: bool
    timestamp: datetime

    def to_dict(self) -> Dict:
        """Convert to dictionary for JSON serialization"""
        result = asdict(self)
        result['query_type'] = self.query_type.value
        result['timestamp'] = self.timestamp.isoformat()
        return result

class QueryPerformanceBenchmark:
    """Main query performance benchmarking class"""

    def __init__(self, connection_params: Dict):
        self.connection_params = connection_params
        self.connection = None
        self.cursor = None
        self.results = []
        self.query_cache = {}

    def connect(self) -> bool:
        """Establish database connection with performance schema enabled"""
        try:
            self.connection = mysql.connector.connect(
                **self.connection_params,
                autocommit=False,
                use_pure=True
            )
            self.cursor = self.connection.cursor(dictionary=True)

            # Enable query profiling
            self.cursor.execute("SET profiling = 1")
            self.cursor.execute("SET profiling_history_size = 100")

            # Reset query cache for consistent benchmarks
            try:
                self.cursor.execute("RESET QUERY CACHE")
            except:
                pass  # Query cache might not be available

            return True
        except Exception as e:
            print(f"Connection failed: {e}")
            return False

    def disconnect(self):
        """Close database connection"""
        if self.cursor:
            self.cursor.close()
        if self.connection:
            self.connection.close()

    def benchmark_query(self, sql: str, query_type: QueryType,
                       warmup: int = 3, iterations: int = 10) -> QueryBenchmark:
        """
        Benchmark a single query

        Args:
            sql: SQL query to benchmark
            query_type: Type of query for categorization
            warmup: Number of warmup runs
            iterations: Number of benchmark iterations
        """
        query_id = hashlib.md5(sql.encode()).hexdigest()[:8]

        # Warmup runs
        for _ in range(warmup):
            self.cursor.execute(sql)
            self.cursor.fetchall()

        # Get EXPLAIN plan
        explain_plan = self._get_explain_plan(sql)

        # Benchmark runs
        execution_times = []
        for _ in range(iterations):
            start_time = time.perf_counter()
            self.cursor.execute(sql)
            results = self.cursor.fetchall()
            end_time = time.perf_counter()

            execution_times.append(end_time - start_time)

        # Get query statistics
        stats = self._get_query_statistics()

        # Calculate median execution time (more stable than average)
        median_time = statistics.median(execution_times)

        benchmark = QueryBenchmark(
            query_id=query_id,
            query_type=query_type,
            sql=sql,
            execution_time=median_time * 1000,  # Convert to milliseconds
            rows_examined=stats.get('rows_examined', 0),
            rows_returned=len(results) if results else 0,
            index_used=self._extract_index_from_explain(explain_plan),
            explain_plan=explain_plan,
            cache_hit=query_id in self.query_cache,
            timestamp=datetime.now()
        )

        self.results.append(benchmark)
        self.query_cache[query_id] = True

        return benchmark

    def _get_explain_plan(self, sql: str) -> Dict:
        """Get EXPLAIN output for a query"""
        try:
            # Handle different query types
            if sql.strip().upper().startswith('SELECT'):
                self.cursor.execute(f"EXPLAIN {sql}")
                return self.cursor.fetchall()
            else:
                return {}
        except Exception as e:
            return {'error': str(e)}

    def _get_query_statistics(self) -> Dict:
        """Get detailed query statistics from performance schema"""
        try:
            self.cursor.execute("SHOW PROFILES")
            profiles = self.cursor.fetchall()

            if profiles:
                latest_query_id = profiles[-1]['Query_ID']
                self.cursor.execute(f"SHOW PROFILE FOR QUERY {latest_query_id}")
                profile = self.cursor.fetchall()

                # Extract key statistics
                stats = {
                    'rows_examined': 0,
                    'duration': 0
                }

                for step in profile:
                    stats['duration'] += step.get('Duration', 0)

                return stats
        except:
            return {}

    def _extract_index_from_explain(self, explain_plan: Any) -> Optional[str]:
        """Extract index usage from EXPLAIN plan"""
        if isinstance(explain_plan, list) and explain_plan:
            first_row = explain_plan[0]
            if isinstance(first_row, dict):
                return first_row.get('key')
        return None

    def benchmark_table_queries(self, table_name: str) -> List[QueryBenchmark]:
        """Run standard benchmark queries for a table"""
        benchmarks = []

        # Get table structure
        self.cursor.execute(f"DESCRIBE {table_name}")
        columns = self.cursor.fetchall()

        # Get primary key column
        pk_column = None
        for col in columns:
            if col.get('Key') == 'PRI':
                pk_column = col.get('Field')
                break

        if not pk_column:
            pk_column = 'id'  # Fallback

        # 1. Simple SELECT
        query = f"SELECT * FROM {table_name} LIMIT 100"
        benchmarks.append(self.benchmark_query(query, QueryType.SIMPLE_SELECT))

        # 2. Index scan
        if pk_column:
            query = f"SELECT * FROM {table_name} WHERE {pk_column} = 1"
            benchmarks.append(self.benchmark_query(query, QueryType.INDEX_SCAN))

        # 3. Range scan
        if pk_column:
            query = f"SELECT * FROM {table_name} WHERE {pk_column} BETWEEN 1 AND 100"
            benchmarks.append(self.benchmark_query(query, QueryType.RANGE_SCAN))

        # 4. Aggregate query
        query = f"SELECT COUNT(*), MAX({pk_column}), MIN({pk_column}) FROM {table_name}"
        benchmarks.append(self.benchmark_query(query, QueryType.AGGREGATE))

        # 5. Full table scan (intentional)
        query = f"SELECT * FROM {table_name} WHERE {pk_column} > 0"
        benchmarks.append(self.benchmark_query(query, QueryType.FULL_TABLE_SCAN))

        return benchmarks

    def benchmark_joins(self, tables: List[str]) -> List[QueryBenchmark]:
        """Benchmark JOIN operations between tables"""
        benchmarks = []

        if len(tables) < 2:
            return benchmarks

        # Simple 2-table join
        query = f"""
            SELECT COUNT(*)
            FROM {tables[0]} t1
            INNER JOIN {tables[1]} t2 ON t1.id = t2.id
            LIMIT 100
        """
        benchmarks.append(self.benchmark_query(query, QueryType.COMPLEX_JOIN))

        # Multi-table join if we have enough tables
        if len(tables) >= 3:
            query = f"""
                SELECT COUNT(*)
                FROM {tables[0]} t1
                INNER JOIN {tables[1]} t2 ON t1.id = t2.id
                INNER JOIN {tables[2]} t3 ON t2.id = t3.id
                LIMIT 100
            """
            benchmarks.append(self.benchmark_query(query, QueryType.COMPLEX_JOIN))

        return benchmarks

    def analyze_results(self) -> Dict:
        """Analyze benchmark results and provide recommendations"""
        if not self.results:
            return {}

        analysis = {
            'total_queries': len(self.results),
            'total_execution_time': sum(r.execution_time for r in self.results),
            'avg_execution_time': statistics.mean(r.execution_time for r in self.results),
            'median_execution_time': statistics.median(r.execution_time for r in self.results),
            'slowest_queries': [],
            'index_usage': {},
            'recommendations': []
        }

        # Find slowest queries
        sorted_results = sorted(self.results, key=lambda x: x.execution_time, reverse=True)
        analysis['slowest_queries'] = [
            {
                'query_id': r.query_id,
                'type': r.query_type.value,
                'execution_time': r.execution_time,
                'rows_examined': r.rows_examined,
                'index_used': r.index_used
            }
            for r in sorted_results[:5]
        ]

        # Analyze index usage
        for result in self.results:
            if result.index_used:
                analysis['index_usage'][result.index_used] = \
                    analysis['index_usage'].get(result.index_used, 0) + 1

        # Generate recommendations
        for result in sorted_results[:10]:
            if result.rows_examined > 1000 and not result.index_used:
                analysis['recommendations'].append({
                    'query_id': result.query_id,
                    'issue': 'No index used for query examining many rows',
                    'suggestion': 'Consider adding an index for better performance'
                })

            if result.execution_time > 100:  # > 100ms
                analysis['recommendations'].append({
                    'query_id': result.query_id,
                    'issue': f'Slow query execution: {result.execution_time:.2f}ms',
                    'suggestion': 'Review query optimization and indexing strategy'
                })

        return analysis

    def export_results(self, output_file: Path):
        """Export benchmark results to JSON file"""
        data = {
            'timestamp': datetime.now().isoformat(),
            'database': self.connection_params.get('database', 'unknown'),
            'results': [r.to_dict() for r in self.results],
            'analysis': self.analyze_results()
        }

        with open(output_file, 'w') as f:
            json.dump(data, f, indent=2)

        print(f"Results exported to: {output_file}")


def benchmark_example(example_name: str, connection_params: Dict) -> Dict:
    """Benchmark queries for a specific example database"""

    benchmark = QueryPerformanceBenchmark(connection_params)

    if not benchmark.connect():
        return {'error': 'Failed to connect to database'}

    try:
        # Get all tables
        benchmark.cursor.execute("SHOW TABLES")
        tables = [table[f'Tables_in_{connection_params["database"]}']
                 for table in benchmark.cursor.fetchall()]

        print(f"Benchmarking {len(tables)} tables in {example_name}...")

        # Benchmark individual tables
        for table in tables[:5]:  # Limit to first 5 tables for demo
            print(f"  - Benchmarking table: {table}")
            benchmark.benchmark_table_queries(table)

        # Benchmark joins
        if len(tables) >= 2:
            print(f"  - Benchmarking JOIN operations")
            benchmark.benchmark_joins(tables[:3])

        # Analyze and return results
        analysis = benchmark.analyze_results()

        # Export results
        output_dir = Path(__file__).parent / 'results'
        output_dir.mkdir(exist_ok=True)
        output_file = output_dir / f'{example_name}_query_benchmark.json'
        benchmark.export_results(output_file)

        return analysis

    finally:
        benchmark.disconnect()


def main():
    """Main entry point for query performance benchmarking"""

    # Example usage
    connection_params = {
        'host': 'localhost',
        'port': 3308,
        'user': 'root',
        'password': 'clinic_root',
        'database': 'clinic_db'
    }

    results = benchmark_example('clinic', connection_params)

    print("\n=== Query Performance Analysis ===")
    print(f"Total Queries: {results.get('total_queries', 0)}")
    print(f"Avg Execution Time: {results.get('avg_execution_time', 0):.2f}ms")
    print(f"Median Execution Time: {results.get('median_execution_time', 0):.2f}ms")

    if results.get('recommendations'):
        print("\nRecommendations:")
        for rec in results['recommendations'][:5]:
            print(f"  - {rec['issue']}: {rec['suggestion']}")


if __name__ == '__main__':
    main()