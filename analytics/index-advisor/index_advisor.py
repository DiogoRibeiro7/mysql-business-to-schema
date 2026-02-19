#!/usr/bin/env python3
"""
Advanced Index Advisor System

Intelligent index recommendation engine that:
- Analyzes slow query patterns
- Recommends optimal indexes
- Predicts performance improvements
- Provides impact analysis
- Generates CREATE INDEX statements
"""

import re
import json
import hashlib
import mysql.connector
from datetime import datetime, timedelta
from typing import Dict, List, Tuple, Optional, Set
from dataclasses import dataclass, field
from collections import defaultdict
import numpy as np
from pathlib import Path

@dataclass
class QueryPattern:
    """Represents a query pattern for analysis"""
    query_hash: str
    query_template: str
    table_name: str
    columns_used: List[str]
    where_columns: List[str]
    join_columns: List[str]
    order_columns: List[str]
    group_columns: List[str]
    execution_count: int = 0
    total_time: float = 0.0
    avg_time: float = 0.0
    rows_examined: int = 0
    rows_returned: int = 0
    selectivity: float = 0.0

@dataclass
class IndexRecommendation:
    """Index recommendation with impact analysis"""
    table_name: str
    column_names: List[str]
    index_name: str
    index_type: str  # BTREE, HASH, FULLTEXT
    reason: str
    estimated_improvement: float  # Percentage improvement
    affected_queries: List[str]  # Query hashes
    priority: str  # HIGH, MEDIUM, LOW
    create_statement: str
    size_estimate_mb: float
    maintenance_cost: str  # LOW, MEDIUM, HIGH

    def to_dict(self) -> Dict:
        return {
            'table': self.table_name,
            'columns': self.column_names,
            'name': self.index_name,
            'type': self.index_type,
            'reason': self.reason,
            'improvement': f"{self.estimated_improvement:.1f}%",
            'affected_queries': len(self.affected_queries),
            'priority': self.priority,
            'sql': self.create_statement,
            'size_mb': f"{self.size_estimate_mb:.2f}",
            'maintenance_cost': self.maintenance_cost
        }

@dataclass
class IndexImpact:
    """Impact analysis for an index recommendation"""
    before_metrics: Dict
    after_metrics: Dict
    improvement_percentage: float
    affected_queries: int
    disk_space_required: float
    write_overhead: float

class AdvancedIndexAdvisor:
    """Advanced index recommendation system"""

    def __init__(self, connection_params: Dict):
        self.connection_params = connection_params
        self.connection = None
        self.cursor = None
        self.query_patterns = {}
        self.existing_indexes = {}
        self.recommendations = []
        self.table_statistics = {}

    def connect(self) -> bool:
        """Establish database connection"""
        try:
            self.connection = mysql.connector.connect(**self.connection_params)
            self.cursor = self.connection.cursor(dictionary=True)

            # Enable slow query log if not enabled
            self._enable_slow_query_log()

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

    def analyze(self,
                slow_query_threshold: float = 1.0,
                min_execution_count: int = 5,
                days_to_analyze: int = 7) -> List[IndexRecommendation]:
        """
        Perform comprehensive index analysis

        Args:
            slow_query_threshold: Queries slower than this (seconds)
            min_execution_count: Minimum times query must appear
            days_to_analyze: How many days of history to analyze
        """
        print("Starting Advanced Index Analysis...")

        # Step 1: Collect existing indexes
        self._collect_existing_indexes()

        # Step 2: Analyze slow query log
        self._analyze_slow_queries(slow_query_threshold, days_to_analyze)

        # Step 3: Analyze query patterns
        self._analyze_query_patterns(min_execution_count)

        # Step 4: Collect table statistics
        self._collect_table_statistics()

        # Step 5: Generate recommendations
        self._generate_recommendations()

        # Step 6: Perform impact analysis
        self._perform_impact_analysis()

        # Step 7: Prioritize recommendations
        self._prioritize_recommendations()

        return self.recommendations

    def _enable_slow_query_log(self):
        """Enable slow query log if not already enabled"""
        try:
            self.cursor.execute("SET GLOBAL slow_query_log = 'ON'")
            self.cursor.execute("SET GLOBAL long_query_time = 1")
            self.cursor.execute("SET GLOBAL log_queries_not_using_indexes = 'ON'")
        except:
            pass  # May not have SUPER privilege

    def _collect_existing_indexes(self):
        """Collect information about existing indexes"""
        self.cursor.execute("""
            SELECT
                TABLE_NAME,
                INDEX_NAME,
                GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) as COLUMNS,
                INDEX_TYPE,
                CARDINALITY,
                NON_UNIQUE
            FROM information_schema.STATISTICS
            WHERE TABLE_SCHEMA = %s
            GROUP BY TABLE_NAME, INDEX_NAME
        """, (self.connection_params['database'],))

        for row in self.cursor.fetchall():
            table = row['TABLE_NAME']
            if table not in self.existing_indexes:
                self.existing_indexes[table] = []

            self.existing_indexes[table].append({
                'name': row['INDEX_NAME'],
                'columns': row['COLUMNS'].split(',') if row['COLUMNS'] else [],
                'type': row['INDEX_TYPE'],
                'cardinality': row['CARDINALITY'],
                'unique': not row['NON_UNIQUE']
            })

    def _analyze_slow_queries(self, threshold: float, days: int):
        """Analyze slow query log patterns"""
        # Try to read from performance_schema first
        try:
            self.cursor.execute("""
                SELECT
                    DIGEST_TEXT,
                    COUNT_STAR as EXEC_COUNT,
                    SUM_TIMER_WAIT/1000000000000 as TOTAL_TIME,
                    AVG_TIMER_WAIT/1000000000000 as AVG_TIME,
                    SUM_ROWS_EXAMINED as ROWS_EXAMINED,
                    SUM_ROWS_SENT as ROWS_SENT
                FROM performance_schema.events_statements_summary_by_digest
                WHERE DIGEST_TEXT IS NOT NULL
                AND AVG_TIMER_WAIT/1000000000000 > %s
                ORDER BY SUM_TIMER_WAIT DESC
                LIMIT 1000
            """, (threshold,))

            for row in self.cursor.fetchall():
                self._parse_query_pattern(
                    row['DIGEST_TEXT'],
                    row['EXEC_COUNT'],
                    row['TOTAL_TIME'],
                    row['AVG_TIME'],
                    row['ROWS_EXAMINED'],
                    row['ROWS_SENT']
                )
        except:
            # Fallback to slow query log file if available
            self._parse_slow_log_file(threshold, days)

    def _parse_query_pattern(self, query: str, exec_count: int,
                            total_time: float, avg_time: float,
                            rows_examined: int, rows_sent: int):
        """Parse a query and extract pattern information"""
        query = query.upper().strip()

        # Skip non-SELECT queries for now
        if not query.startswith('SELECT'):
            return

        # Extract table name
        table_match = re.search(r'FROM\s+`?(\w+)`?', query)
        if not table_match:
            return

        table_name = table_match.group(1).lower()

        # Generate query hash
        query_hash = hashlib.md5(query.encode()).hexdigest()[:8]

        # Extract columns from WHERE clause
        where_columns = self._extract_where_columns(query)

        # Extract JOIN columns
        join_columns = self._extract_join_columns(query)

        # Extract ORDER BY columns
        order_columns = self._extract_order_columns(query)

        # Extract GROUP BY columns
        group_columns = self._extract_group_columns(query)

        # Extract all referenced columns
        all_columns = set(where_columns + join_columns + order_columns + group_columns)

        # Calculate selectivity
        selectivity = rows_sent / rows_examined if rows_examined > 0 else 1.0

        # Create or update pattern
        if query_hash not in self.query_patterns:
            self.query_patterns[query_hash] = QueryPattern(
                query_hash=query_hash,
                query_template=query[:200],  # Store first 200 chars
                table_name=table_name,
                columns_used=list(all_columns),
                where_columns=where_columns,
                join_columns=join_columns,
                order_columns=order_columns,
                group_columns=group_columns,
                execution_count=exec_count,
                total_time=total_time,
                avg_time=avg_time,
                rows_examined=rows_examined,
                rows_returned=rows_sent,
                selectivity=selectivity
            )
        else:
            pattern = self.query_patterns[query_hash]
            pattern.execution_count += exec_count
            pattern.total_time += total_time
            pattern.avg_time = pattern.total_time / pattern.execution_count

    def _extract_where_columns(self, query: str) -> List[str]:
        """Extract columns used in WHERE clause"""
        columns = []

        # Extract WHERE clause
        where_match = re.search(r'WHERE\s+(.*?)(?:GROUP|ORDER|LIMIT|$)', query)
        if where_match:
            where_clause = where_match.group(1)

            # Find column references
            col_pattern = r'`?(\w+)`?\s*(?:=|!=|<>|>|<|>=|<=|LIKE|IN|BETWEEN|IS)'
            columns = re.findall(col_pattern, where_clause)

            # Clean column names
            columns = [col.lower() for col in columns if not col.upper() in
                      ('AND', 'OR', 'NOT', 'NULL', 'TRUE', 'FALSE')]

        return list(set(columns))

    def _extract_join_columns(self, query: str) -> List[str]:
        """Extract columns used in JOIN conditions"""
        columns = []

        # Find JOIN clauses
        join_pattern = r'JOIN\s+.*?\s+ON\s+(.*?)(?:JOIN|WHERE|GROUP|ORDER|LIMIT|$)'
        join_matches = re.findall(join_pattern, query)

        for join_clause in join_matches:
            # Extract column names from join condition
            col_pattern = r'`?(\w+)`?\.`?(\w+)`?'
            found_cols = re.findall(col_pattern, join_clause)
            columns.extend([col[1].lower() for col in found_cols])

        return list(set(columns))

    def _extract_order_columns(self, query: str) -> List[str]:
        """Extract columns used in ORDER BY clause"""
        columns = []

        order_match = re.search(r'ORDER\s+BY\s+(.*?)(?:LIMIT|$)', query)
        if order_match:
            order_clause = order_match.group(1)

            # Extract column names
            col_pattern = r'`?(\w+)`?(?:\s+(?:ASC|DESC))?'
            columns = re.findall(col_pattern, order_clause)
            columns = [col.lower() for col in columns if col.lower() not in ('asc', 'desc')]

        return list(set(columns))

    def _extract_group_columns(self, query: str) -> List[str]:
        """Extract columns used in GROUP BY clause"""
        columns = []

        group_match = re.search(r'GROUP\s+BY\s+(.*?)(?:HAVING|ORDER|LIMIT|$)', query)
        if group_match:
            group_clause = group_match.group(1)

            # Extract column names
            col_pattern = r'`?(\w+)`?'
            columns = re.findall(col_pattern, group_clause)
            columns = [col.lower() for col in columns]

        return list(set(columns))

    def _analyze_query_patterns(self, min_count: int):
        """Analyze collected query patterns"""
        print(f"Analyzing {len(self.query_patterns)} query patterns...")

        # Filter patterns by minimum execution count
        self.query_patterns = {
            k: v for k, v in self.query_patterns.items()
            if v.execution_count >= min_count
        }

    def _collect_table_statistics(self):
        """Collect table statistics for better recommendations"""
        tables = set(p.table_name for p in self.query_patterns.values())

        for table in tables:
            try:
                # Get table size
                self.cursor.execute("""
                    SELECT
                        TABLE_ROWS,
                        DATA_LENGTH/1024/1024 as DATA_SIZE_MB,
                        INDEX_LENGTH/1024/1024 as INDEX_SIZE_MB
                    FROM information_schema.TABLES
                    WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s
                """, (self.connection_params['database'], table))

                result = self.cursor.fetchone()
                if result:
                    self.table_statistics[table] = {
                        'row_count': result['TABLE_ROWS'],
                        'data_size_mb': result['DATA_SIZE_MB'],
                        'index_size_mb': result['INDEX_SIZE_MB']
                    }

                # Get column cardinality
                self.cursor.execute("""
                    SELECT
                        COLUMN_NAME,
                        DATA_TYPE,
                        CHARACTER_MAXIMUM_LENGTH
                    FROM information_schema.COLUMNS
                    WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s
                """, (self.connection_params['database'], table))

                columns = {}
                for col in self.cursor.fetchall():
                    col_name = col['COLUMN_NAME'].lower()

                    # Estimate cardinality (simplified)
                    self.cursor.execute(f"""
                        SELECT COUNT(DISTINCT `{col_name}`) as cardinality
                        FROM `{table}`
                        LIMIT 1000
                    """)

                    cardinality = self.cursor.fetchone()['cardinality']

                    columns[col_name] = {
                        'type': col['DATA_TYPE'],
                        'length': col['CHARACTER_MAXIMUM_LENGTH'],
                        'cardinality': cardinality
                    }

                self.table_statistics[table]['columns'] = columns

            except Exception as e:
                print(f"Warning: Could not collect statistics for {table}: {e}")

    def _generate_recommendations(self):
        """Generate index recommendations based on patterns"""
        recommendations_map = {}  # Key: (table, columns_tuple)

        for pattern in self.query_patterns.values():
            # Skip if query is already fast
            if pattern.avg_time < 0.1:  # Less than 100ms
                continue

            # Skip if selectivity is good
            if pattern.selectivity > 0.5:  # More than 50% of rows returned
                continue

            # Check for missing indexes on WHERE columns
            if pattern.where_columns:
                self._recommend_index(
                    pattern.table_name,
                    pattern.where_columns,
                    'WHERE clause optimization',
                    pattern,
                    recommendations_map
                )

            # Check for covering indexes
            if pattern.where_columns and pattern.columns_used:
                covering_columns = pattern.where_columns + [
                    col for col in pattern.columns_used
                    if col not in pattern.where_columns
                ][:3]  # Limit covering columns

                self._recommend_index(
                    pattern.table_name,
                    covering_columns,
                    'Covering index for SELECT',
                    pattern,
                    recommendations_map,
                    is_covering=True
                )

            # Check for ORDER BY optimization
            if pattern.order_columns:
                order_index_cols = pattern.where_columns + pattern.order_columns
                self._recommend_index(
                    pattern.table_name,
                    order_index_cols,
                    'ORDER BY optimization',
                    pattern,
                    recommendations_map
                )

            # Check for GROUP BY optimization
            if pattern.group_columns:
                group_index_cols = pattern.where_columns + pattern.group_columns
                self._recommend_index(
                    pattern.table_name,
                    group_index_cols,
                    'GROUP BY optimization',
                    pattern,
                    recommendations_map
                )

            # Check for JOIN optimization
            if pattern.join_columns:
                for col in pattern.join_columns:
                    self._recommend_index(
                        pattern.table_name,
                        [col],
                        'JOIN optimization',
                        pattern,
                        recommendations_map
                    )

        # Convert map to list
        self.recommendations = list(recommendations_map.values())

    def _recommend_index(self, table: str, columns: List[str],
                        reason: str, pattern: QueryPattern,
                        recommendations_map: Dict,
                        is_covering: bool = False):
        """Create an index recommendation"""
        # Clean and deduplicate columns
        columns = [col.lower() for col in columns if col]
        columns = list(dict.fromkeys(columns))  # Preserve order, remove duplicates

        if not columns:
            return

        # Check if index already exists
        if self._index_exists(table, columns):
            return

        # Create unique key for deduplication
        rec_key = (table, tuple(columns))

        # Calculate estimated improvement
        improvement = self._estimate_improvement(table, columns, pattern)

        # Estimate index size
        size_mb = self._estimate_index_size(table, columns)

        # Determine maintenance cost
        maintenance_cost = self._estimate_maintenance_cost(table, columns)

        # Generate index name
        index_name = f"idx_{table}_{'_'.join(columns[:3])}"
        if is_covering:
            index_name = f"covering_{index_name}"

        # Create SQL statement
        create_statement = f"CREATE INDEX {index_name} ON {table} ({', '.join(columns)})"

        # Determine priority
        priority = self._determine_priority(improvement, pattern.execution_count)

        # Create or update recommendation
        if rec_key in recommendations_map:
            # Update existing recommendation
            existing = recommendations_map[rec_key]
            existing.affected_queries.append(pattern.query_hash)
            existing.estimated_improvement = max(existing.estimated_improvement, improvement)
        else:
            # Create new recommendation
            recommendations_map[rec_key] = IndexRecommendation(
                table_name=table,
                column_names=columns,
                index_name=index_name,
                index_type='BTREE',
                reason=reason,
                estimated_improvement=improvement,
                affected_queries=[pattern.query_hash],
                priority=priority,
                create_statement=create_statement,
                size_estimate_mb=size_mb,
                maintenance_cost=maintenance_cost
            )

    def _index_exists(self, table: str, columns: List[str]) -> bool:
        """Check if an index already exists for these columns"""
        if table not in self.existing_indexes:
            return False

        columns_set = set(columns)

        for index in self.existing_indexes[table]:
            # Check if existing index covers our columns
            if set(index['columns'][:len(columns)]) == columns_set:
                return True

        return False

    def _estimate_improvement(self, table: str, columns: List[str],
                             pattern: QueryPattern) -> float:
        """Estimate performance improvement from index"""
        improvement = 0.0

        # Base improvement from reducing table scan
        if pattern.rows_examined > 1000:
            improvement += min(50, pattern.rows_examined / 1000)

        # Improvement from selectivity
        if pattern.selectivity < 0.1:  # High selectivity
            improvement += 30
        elif pattern.selectivity < 0.3:
            improvement += 20

        # Improvement based on column cardinality
        if table in self.table_statistics:
            stats = self.table_statistics[table]
            for col in columns[:1]:  # Check first column (most important)
                if col in stats.get('columns', {}):
                    cardinality = stats['columns'][col]['cardinality']
                    row_count = stats.get('row_count', 1)

                    if row_count > 0:
                        selectivity = cardinality / row_count
                        if selectivity > 0.5:  # Good selectivity
                            improvement += 20

        # Cap improvement at 90%
        return min(90, improvement)

    def _estimate_index_size(self, table: str, columns: List[str]) -> float:
        """Estimate index size in MB"""
        if table not in self.table_statistics:
            return 10.0  # Default estimate

        stats = self.table_statistics[table]
        row_count = stats.get('row_count', 0)

        # Estimate bytes per index entry
        bytes_per_entry = 8  # Overhead

        for col in columns:
            if col in stats.get('columns', {}):
                col_type = stats['columns'][col]['type']

                if 'int' in col_type.lower():
                    bytes_per_entry += 4
                elif 'bigint' in col_type.lower():
                    bytes_per_entry += 8
                elif 'varchar' in col_type.lower():
                    length = stats['columns'][col].get('length', 50)
                    bytes_per_entry += min(length, 50)  # Assume average fill
                elif 'date' in col_type.lower():
                    bytes_per_entry += 3
                elif 'datetime' in col_type.lower():
                    bytes_per_entry += 8
                else:
                    bytes_per_entry += 20  # Default

        # Calculate total size
        total_bytes = row_count * bytes_per_entry
        size_mb = total_bytes / (1024 * 1024)

        return round(size_mb, 2)

    def _estimate_maintenance_cost(self, table: str, columns: List[str]) -> str:
        """Estimate maintenance cost of index"""
        if table not in self.table_statistics:
            return 'MEDIUM'

        stats = self.table_statistics[table]
        row_count = stats.get('row_count', 0)

        # High maintenance for large tables with many columns
        if row_count > 1000000 and len(columns) > 3:
            return 'HIGH'
        elif row_count > 100000 or len(columns) > 2:
            return 'MEDIUM'
        else:
            return 'LOW'

    def _determine_priority(self, improvement: float, exec_count: int) -> str:
        """Determine recommendation priority"""
        score = improvement * np.log(exec_count + 1)

        if score > 100:
            return 'HIGH'
        elif score > 50:
            return 'MEDIUM'
        else:
            return 'LOW'

    def _perform_impact_analysis(self):
        """Perform detailed impact analysis for recommendations"""
        print("Performing impact analysis...")

        for recommendation in self.recommendations:
            # Simulate index creation and measure impact
            # In production, this would use EXPLAIN with hypothetical indexes

            # For now, we'll use our estimates
            total_queries_affected = len(recommendation.affected_queries)
            total_time_saved = 0

            for query_hash in recommendation.affected_queries:
                if query_hash in self.query_patterns:
                    pattern = self.query_patterns[query_hash]
                    time_saved = pattern.total_time * (recommendation.estimated_improvement / 100)
                    total_time_saved += time_saved

            # Update recommendation with impact data
            recommendation.estimated_time_saved = total_time_saved

    def _prioritize_recommendations(self):
        """Prioritize recommendations based on impact"""
        # Sort by priority and improvement
        priority_order = {'HIGH': 0, 'MEDIUM': 1, 'LOW': 2}

        self.recommendations.sort(
            key=lambda r: (
                priority_order.get(r.priority, 3),
                -r.estimated_improvement,
                -len(r.affected_queries)
            )
        )

    def _parse_slow_log_file(self, threshold: float, days: int):
        """Parse slow query log file as fallback"""
        # This would parse the actual slow query log file
        # Implementation depends on log file location and format
        pass

    def export_recommendations(self, output_file: Path):
        """Export recommendations to JSON file"""
        data = {
            'timestamp': datetime.now().isoformat(),
            'database': self.connection_params['database'],
            'analysis_summary': {
                'queries_analyzed': len(self.query_patterns),
                'recommendations': len(self.recommendations),
                'high_priority': sum(1 for r in self.recommendations if r.priority == 'HIGH'),
                'estimated_improvement': np.mean([r.estimated_improvement for r in self.recommendations]) if self.recommendations else 0
            },
            'recommendations': [r.to_dict() for r in self.recommendations],
            'query_patterns': {
                k: {
                    'table': v.table_name,
                    'exec_count': v.execution_count,
                    'avg_time': v.avg_time,
                    'total_time': v.total_time,
                    'selectivity': v.selectivity
                }
                for k, v in list(self.query_patterns.items())[:20]  # Top 20 patterns
            }
        }

        with open(output_file, 'w') as f:
            json.dump(data, f, indent=2)

        print(f"Recommendations exported to: {output_file}")

    def print_summary(self):
        """Print analysis summary"""
        print("\n" + "=" * 60)
        print("INDEX ADVISOR ANALYSIS SUMMARY")
        print("=" * 60)

        print(f"\nQueries Analyzed: {len(self.query_patterns)}")
        print(f"Total Recommendations: {len(self.recommendations)}")

        # Group by priority
        by_priority = defaultdict(list)
        for rec in self.recommendations:
            by_priority[rec.priority].append(rec)

        print(f"\nBy Priority:")
        print(f"  HIGH: {len(by_priority['HIGH'])}")
        print(f"  MEDIUM: {len(by_priority['MEDIUM'])}")
        print(f"  LOW: {len(by_priority['LOW'])}")

        # Top recommendations
        if self.recommendations:
            print(f"\nTop Recommendations:")
            for i, rec in enumerate(self.recommendations[:5], 1):
                print(f"\n{i}. {rec.index_name}")
                print(f"   Table: {rec.table_name}")
                print(f"   Columns: {', '.join(rec.column_names)}")
                print(f"   Improvement: {rec.estimated_improvement:.1f}%")
                print(f"   Affected Queries: {len(rec.affected_queries)}")
                print(f"   Priority: {rec.priority}")
                print(f"   Size: ~{rec.size_estimate_mb:.1f} MB")
                print(f"   SQL: {rec.create_statement}")

        # Total estimated improvement
        if self.recommendations:
            avg_improvement = np.mean([r.estimated_improvement for r in self.recommendations])
            print(f"\nAverage Expected Improvement: {avg_improvement:.1f}%")

    def generate_implementation_script(self, output_file: Path):
        """Generate SQL script to implement recommendations"""
        with open(output_file, 'w') as f:
            f.write("-- Index Recommendations Implementation Script\n")
            f.write(f"-- Generated: {datetime.now().isoformat()}\n")
            f.write(f"-- Database: {self.connection_params['database']}\n")
            f.write("-- \n")
            f.write("-- Review each index carefully before applying\n")
            f.write("-- Test in development environment first\n")
            f.write("-- Monitor performance after implementation\n\n")

            # Group by priority
            by_priority = defaultdict(list)
            for rec in self.recommendations:
                by_priority[rec.priority].append(rec)

            for priority in ['HIGH', 'MEDIUM', 'LOW']:
                if by_priority[priority]:
                    f.write(f"\n-- {priority} PRIORITY INDEXES\n")
                    f.write("-" * 60 + "\n\n")

                    for rec in by_priority[priority]:
                        f.write(f"-- Index: {rec.index_name}\n")
                        f.write(f"-- Reason: {rec.reason}\n")
                        f.write(f"-- Expected Improvement: {rec.estimated_improvement:.1f}%\n")
                        f.write(f"-- Affected Queries: {len(rec.affected_queries)}\n")
                        f.write(f"-- Estimated Size: {rec.size_estimate_mb:.1f} MB\n")
                        f.write(f"-- Maintenance Cost: {rec.maintenance_cost}\n\n")

                        f.write(f"{rec.create_statement};\n\n")

            # Add analysis queries
            f.write("\n-- POST-IMPLEMENTATION VERIFICATION\n")
            f.write("-" * 60 + "\n\n")
            f.write("-- Check if indexes were created successfully:\n")
            f.write("SHOW INDEXES FROM your_table;\n\n")
            f.write("-- Analyze table after index creation:\n")
            f.write("ANALYZE TABLE your_table;\n\n")
            f.write("-- Monitor slow query log for improvements:\n")
            f.write("SHOW VARIABLES LIKE 'slow_query_log%';\n")

        print(f"Implementation script generated: {output_file}")


def main():
    """Main entry point for Index Advisor"""
    import argparse

    parser = argparse.ArgumentParser(description='Advanced Index Advisor')
    parser.add_argument('--host', default='localhost')
    parser.add_argument('--port', type=int, default=3306)
    parser.add_argument('--user', default='root')
    parser.add_argument('--password', required=True)
    parser.add_argument('--database', required=True)
    parser.add_argument('--threshold', type=float, default=1.0,
                       help='Slow query threshold in seconds')
    parser.add_argument('--min-count', type=int, default=5,
                       help='Minimum execution count for analysis')
    parser.add_argument('--days', type=int, default=7,
                       help='Days of history to analyze')
    parser.add_argument('--output', default='index_recommendations.json')
    parser.add_argument('--script', default='implement_indexes.sql',
                       help='Output SQL script file')

    args = parser.parse_args()

    connection_params = {
        'host': args.host,
        'port': args.port,
        'user': args.user,
        'password': args.password,
        'database': args.database
    }

    advisor = AdvancedIndexAdvisor(connection_params)

    if advisor.connect():
        try:
            # Run analysis
            recommendations = advisor.analyze(
                slow_query_threshold=args.threshold,
                min_execution_count=args.min_count,
                days_to_analyze=args.days
            )

            # Print summary
            advisor.print_summary()

            # Export results
            advisor.export_recommendations(Path(args.output))

            # Generate implementation script
            advisor.generate_implementation_script(Path(args.script))

        finally:
            advisor.disconnect()


if __name__ == '__main__':
    main()