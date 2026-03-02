"""Index Advisor - Intelligent index recommendation system.

Analyzes query patterns and suggests optimal indexes
"""

import logging
import re
from typing import List, Dict, Any, Set
from datetime import datetime
from collections import defaultdict, Counter
import json
from pathlib import Path

logger = logging.getLogger(__name__)


class IndexAdvisor:
    """Advanced index recommendation engine."""

    def __init__(self):
        """Initialize the instance."""
        self.slow_queries = []
        self.existing_indexes = {}
        self.table_statistics = {}
        self.query_patterns = defaultdict(list)
        self.index_suggestions = []
        self.cost_model = self._initialize_cost_model()
        self._load_analysis_history()

    def _initialize_cost_model(self) -> Dict[str, float]:
        """Initialize cost factors for different operations."""
        return {
            "full_table_scan": 100.0,
            "index_scan": 10.0,
            "unique_index_lookup": 1.0,
            "range_scan": 20.0,
            "filesort": 50.0,
            "temporary_table": 40.0,
            "join_buffer": 30.0,
            "index_merge": 25.0,
            "write_overhead": 5.0,  # Cost of maintaining index on writes
            "storage_per_mb": 0.1,  # Storage cost factor
        }

    def _load_analysis_history(self):
        """Load previous analysis results."""
        history_path = Path(__file__).parent.parent.parent / "index_analysis"
        history_path.mkdir(exist_ok=True)

        history_file = history_path / "analysis_history.json"
        if history_file.exists():
            try:
                with open(history_file, "r") as f:
                    data = json.load(f)
                    self.query_patterns = defaultdict(list, data.get("patterns", {}))
                    self.index_suggestions = data.get("suggestions", [])
            except Exception as e:
                logger.error(f"Error loading analysis history: {e}")

    def analyze_slow_queries(self, queries: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Analyze slow queries and identify optimization opportunities."""
        analysis_results = {
            "total_queries": len(queries),
            "patterns_found": {},
            "problem_areas": [],
            "optimization_potential": 0,
            "summary": {},
        }

        # Group queries by pattern
        for query in queries:
            pattern = self._extract_query_pattern(query["sql"])
            if pattern:
                self.query_patterns[pattern].append(query)

        # Analyze each pattern
        for pattern, pattern_queries in self.query_patterns.items():
            pattern_analysis = self._analyze_pattern(pattern, pattern_queries)
            analysis_results["patterns_found"][pattern] = pattern_analysis

        # Identify problem areas
        analysis_results["problem_areas"] = self._identify_problem_areas()

        # Calculate optimization potential
        analysis_results["optimization_potential"] = (
            self._calculate_optimization_potential()
        )

        # Generate summary
        analysis_results["summary"] = self._generate_analysis_summary()

        return analysis_results

    def _extract_query_pattern(self, sql: str) -> str:
        """Extract a normalized pattern from SQL query."""
        # Remove literals and normalize
        pattern = re.sub(r"\b\d+\b", "N", sql)  # Replace numbers with N
        pattern = re.sub(r"'[^']*'", "'S'", pattern)  # Replace strings with 'S'
        pattern = re.sub(r"\s+", " ", pattern)  # Normalize whitespace
        pattern = pattern.upper().strip()

        # Extract key components
        if "SELECT" in pattern:
            # Extract SELECT...FROM...WHERE pattern
            match = re.search(r"SELECT .* FROM (\w+).*?(WHERE .*)?", pattern)
            if match:
                table = match.group(1)
                where = match.group(2) or ""
                # Identify columns in WHERE clause
                where_cols = re.findall(r"(\w+)\s*[=<>]", where)
                return f"{table}:{','.join(set(where_cols))}"

        return pattern[:100]  # Fallback to truncated pattern

    def _analyze_pattern(
        self, pattern: str, queries: List[Dict[str, Any]]
    ) -> Dict[str, Any]:
        """Analyze a specific query pattern."""
        total_time = sum(q.get("execution_time", 0) for q in queries)
        avg_time = total_time / len(queries) if queries else 0

        return {
            "count": len(queries),
            "total_time_ms": total_time,
            "avg_time_ms": avg_time,
            "max_time_ms": max(
                (q.get("execution_time", 0) for q in queries), default=0
            ),
            "impact_score": self._calculate_impact_score(len(queries), avg_time),
            "sample_query": queries[0]["sql"] if queries else None,
        }

    def _calculate_impact_score(self, frequency: int, avg_time: float) -> float:
        """Calculate the impact score of a query pattern."""
        # Higher frequency and slower queries have higher impact
        return (frequency * 0.3) + (avg_time * 0.7)

    def _identify_problem_areas(self) -> List[Dict[str, Any]]:
        """Identify the most problematic areas needing optimization."""
        problems = []

        for pattern, queries in self.query_patterns.items():
            if ":" in pattern:  # Table:columns pattern
                table, columns = pattern.split(":", 1)
                if columns:  # Has WHERE clause columns
                    problem = {
                        "type": "missing_index",
                        "table": table,
                        "columns": columns.split(","),
                        "frequency": len(queries),
                        "avg_time": sum(q.get("execution_time", 0) for q in queries)
                        / len(queries),
                        "severity": "high" if len(queries) > 10 else "medium",
                    }
                    problems.append(problem)

        # Sort by severity and frequency
        problems.sort(
            key=lambda x: (x["severity"] == "high", x["frequency"]), reverse=True
        )

        return problems[:10]  # Return top 10 problems

    def _calculate_optimization_potential(self) -> float:
        """Calculate potential performance improvement percentage."""
        current_total = sum(
            sum(q.get("execution_time", 0) for q in queries)
            for queries in self.query_patterns.values()
        )

        if current_total == 0:
            return 0

        # Estimate time after optimization (assuming 70% improvement for indexed queries)
        estimated_total = current_total * 0.3

        improvement = ((current_total - estimated_total) / current_total) * 100
        return min(improvement, 90)  # Cap at 90% to be realistic

    def _generate_analysis_summary(self) -> Dict[str, Any]:
        """Generate a summary of the analysis."""
        total_queries = sum(len(q) for q in self.query_patterns.values())
        slow_patterns = sum(
            1
            for p, q in self.query_patterns.items()
            if q and sum(qu.get("execution_time", 0) for qu in q) / len(q) > 100
        )

        return {
            "total_patterns": len(self.query_patterns),
            "total_queries_analyzed": total_queries,
            "slow_patterns": slow_patterns,
            "tables_affected": len(
                {p.split(":")[0] for p in self.query_patterns if ":" in p}
            ),
            "recommendation": (
                "Critical"
                if slow_patterns > 5
                else "Moderate" if slow_patterns > 2 else "Minor"
            ),
        }

    def suggest_indexes(
        self, schema: Dict[str, Any], workload: List[Dict[str, Any]]
    ) -> List[Dict[str, Any]]:
        """Generate index suggestions based on schema and workload."""
        suggestions = []

        # Analyze each table mentioned in workload
        tables_in_workload = self._extract_tables_from_workload(workload)

        for table_name in tables_in_workload:
            table_info = schema.get("tables", {}).get(table_name)
            if not table_info:
                continue

            # Get existing indexes
            existing = self._get_existing_indexes(table_info)

            # Analyze queries for this table
            table_queries = [
                q for q in workload if table_name in q.get("sql", "").upper()
            ]

            # Generate suggestions for this table
            table_suggestions = self._suggest_indexes_for_table(
                table_name, table_info, existing, table_queries
            )

            suggestions.extend(table_suggestions)

        # Rank suggestions by impact
        suggestions.sort(key=lambda x: x["impact_score"], reverse=True)

        # Add creation SQL for top suggestions
        for suggestion in suggestions[:10]:
            suggestion["create_sql"] = self._generate_index_sql(suggestion)

        return suggestions

    def _extract_tables_from_workload(self, workload: List[Dict[str, Any]]) -> Set[str]:
        """Extract table names from workload queries."""
        tables = set()

        for query in workload:
            sql = query.get("sql", "").upper()
            # Extract table names from FROM and JOIN clauses
            from_tables = re.findall(r"FROM\s+(\w+)", sql)
            join_tables = re.findall(r"JOIN\s+(\w+)", sql)
            tables.update(from_tables + join_tables)

        return tables

    def _get_existing_indexes(self, table_info: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Get existing indexes for a table."""
        return table_info.get("indexes", [])

    def _suggest_indexes_for_table(
        self,
        table_name: str,
        table_info: Dict[str, Any],
        existing_indexes: List[Dict[str, Any]],
        queries: List[Dict[str, Any]],
    ) -> List[Dict[str, Any]]:
        """Generate index suggestions for a specific table."""
        suggestions = []

        # Analyze WHERE clauses
        where_columns = self._analyze_where_clauses(table_name, queries)

        # Analyze JOIN conditions
        join_columns = self._analyze_join_conditions(table_name, queries)

        # Analyze ORDER BY clauses
        orderby_columns = self._analyze_orderby_clauses(table_name, queries)

        # Generate composite index suggestions
        for cols in where_columns:
            if not self._index_exists(cols, existing_indexes):
                suggestion = self._create_index_suggestion(
                    table_name,
                    cols,
                    "where",
                    len(
                        [q for q in queries if all(c in q.get("sql", "") for c in cols)]
                    ),
                )
                suggestions.append(suggestion)

        # Generate join index suggestions
        for col in join_columns:
            if not self._index_exists([col], existing_indexes):
                suggestion = self._create_index_suggestion(
                    table_name, [col], "join", join_columns[col]
                )
                suggestions.append(suggestion)

        # Generate sort index suggestions
        for cols in orderby_columns:
            if not self._index_exists(cols, existing_indexes):
                suggestion = self._create_index_suggestion(
                    table_name,
                    cols,
                    "sort",
                    len([q for q in queries if "ORDER BY" in q.get("sql", "").upper()]),
                )
                suggestions.append(suggestion)

        return suggestions

    def _analyze_where_clauses(
        self, table_name: str, queries: List[Dict[str, Any]]
    ) -> List[List[str]]:
        """Analyze WHERE clauses to find column combinations."""
        column_combinations = []

        for query in queries:
            sql = query.get("sql", "")
            # Extract WHERE clause
            where_match = re.search(
                r"WHERE\s+(.*?)(?:GROUP|ORDER|LIMIT|$)", sql, re.IGNORECASE
            )
            if where_match:
                where_clause = where_match.group(1)
                # Extract column names
                columns = re.findall(r"(\w+)\s*[=<>]", where_clause)
                if columns:
                    # Remove duplicates while preserving order
                    unique_cols = []
                    seen = set()
                    for col in columns:
                        if col.lower() not in seen:
                            unique_cols.append(col.lower())
                            seen.add(col.lower())
                    if unique_cols and unique_cols not in column_combinations:
                        column_combinations.append(unique_cols)

        return column_combinations

    def _analyze_join_conditions(
        self, table_name: str, queries: List[Dict[str, Any]]
    ) -> Dict[str, int]:
        """Analyze JOIN conditions to find frequently joined columns."""
        join_columns = Counter()

        for query in queries:
            sql = query.get("sql", "")
            # Extract JOIN conditions
            join_matches = re.findall(
                rf"JOIN\s+\w+\s+ON\s+.*?{table_name}\.(\w+)", sql, re.IGNORECASE
            )
            join_columns.update(join_matches)

        return dict(join_columns)

    def _analyze_orderby_clauses(
        self, table_name: str, queries: List[Dict[str, Any]]
    ) -> List[List[str]]:
        """Analyze ORDER BY clauses to find sort columns."""
        orderby_combinations = []

        for query in queries:
            sql = query.get("sql", "")
            # Extract ORDER BY clause
            orderby_match = re.search(
                r"ORDER\s+BY\s+(.*?)(?:LIMIT|$)", sql, re.IGNORECASE
            )
            if orderby_match:
                orderby_clause = orderby_match.group(1)
                # Extract column names
                columns = re.findall(r"(\w+)(?:\s+(?:ASC|DESC))?", orderby_clause)
                if columns:
                    columns = [c.lower() for c in columns]
                    if columns not in orderby_combinations:
                        orderby_combinations.append(columns)

        return orderby_combinations

    def _index_exists(
        self, columns: List[str], existing_indexes: List[Dict[str, Any]]
    ) -> bool:
        """Check if an index already exists for the given columns."""
        for index in existing_indexes:
            index_cols = index.get("columns", [])
            # Check if existing index covers these columns (order matters for leftmost prefix)
            if len(index_cols) >= len(columns):
                if index_cols[: len(columns)] == columns:
                    return True
        return False

    def _create_index_suggestion(
        self, table: str, columns: List[str], reason: str, frequency: int
    ) -> Dict[str, Any]:
        """Create an index suggestion with impact analysis."""
        # Estimate size (rough approximation)
        estimated_size_mb = len(columns) * 10 * 0.001 * frequency  # Very rough estimate

        # Calculate impact score
        impact_score = self._calculate_suggestion_impact(
            reason, frequency, len(columns)
        )

        return {
            "table": table,
            "columns": columns,
            "index_name": f"idx_{table}_{'_'.join(columns)}",
            "type": "BTREE",  # Default to BTREE
            "reason": reason,
            "frequency": frequency,
            "impact_score": impact_score,
            "estimated_size_mb": estimated_size_mb,
            "write_overhead": len(columns) * self.cost_model["write_overhead"],
            "recommendation": self._get_recommendation_level(impact_score),
            "benefits": self._describe_benefits(reason, frequency),
            "considerations": self._describe_considerations(columns, estimated_size_mb),
        }

    def _calculate_suggestion_impact(
        self, reason: str, frequency: int, num_columns: int
    ) -> float:
        """Calculate the impact score for an index suggestion."""
        base_score = frequency

        # Adjust based on reason
        if reason == "where":
            base_score *= 1.5  # WHERE clauses are high priority
        elif reason == "join":
            base_score *= 1.3  # JOINs are important
        elif reason == "sort":
            base_score *= 1.1  # Sorting benefits from indexes

        # Adjust for number of columns (composite indexes can be more specific)
        if num_columns == 1:
            base_score *= 1.2  # Single column indexes are versatile
        elif num_columns > 3:
            base_score *= 0.8  # Many columns = more specific, less reusable

        return base_score

    def _get_recommendation_level(self, impact_score: float) -> str:
        """Get recommendation level based on impact score."""
        if impact_score >= 100:
            return "critical"
        elif impact_score >= 50:
            return "high"
        elif impact_score >= 20:
            return "medium"
        else:
            return "low"

    def _describe_benefits(self, reason: str, frequency: int) -> List[str]:
        """Describe the benefits of creating this index."""
        benefits = []

        if reason == "where":
            benefits.append(f"Speeds up {frequency} queries with WHERE conditions")
            benefits.append("Reduces full table scans")
            benefits.append("Improves query response time")
        elif reason == "join":
            benefits.append(f"Optimizes {frequency} JOIN operations")
            benefits.append("Reduces join buffer usage")
            benefits.append("Enables more efficient join algorithms")
        elif reason == "sort":
            benefits.append(f"Eliminates sorting for {frequency} ORDER BY queries")
            benefits.append("Reduces temporary table usage")
            benefits.append("Improves query performance for sorted results")

        return benefits

    def _describe_considerations(self, columns: List[str], size_mb: float) -> List[str]:
        """Describe considerations before creating this index."""
        considerations = []

        considerations.append(f"Estimated storage: {size_mb:.2f} MB")

        if len(columns) > 2:
            considerations.append("Composite index - column order matters")
            considerations.append("May not help queries using only later columns")

        considerations.append("Will add overhead to INSERT/UPDATE operations")

        if size_mb > 100:
            considerations.append("Large index - consider partitioning")

        return considerations

    def _generate_index_sql(self, suggestion: Dict[str, Any]) -> str:
        """Generate SQL to create the suggested index."""
        columns = ", ".join(f"`{col}`" for col in suggestion["columns"])
        return f"CREATE INDEX `{suggestion['index_name']}` ON `{suggestion['table']}` ({columns});"

    def analyze_index_impact(
        self, table: str, index_columns: List[str], sample_queries: List[str]
    ) -> Dict[str, Any]:
        """Analyze the impact of creating a specific index."""
        impact_analysis = {
            "table": table,
            "columns": index_columns,
            "before_metrics": {},
            "after_metrics": {},
            "improvement": {},
            "affected_queries": [],
            "storage_impact": {},
            "write_impact": {},
        }

        # Analyze each sample query
        for query in sample_queries:
            query_impact = self._analyze_query_impact(query, table, index_columns)
            impact_analysis["affected_queries"].append(query_impact)

        # Calculate overall metrics
        impact_analysis["before_metrics"] = {
            "avg_cost": sum(
                q["before_cost"] for q in impact_analysis["affected_queries"]
            )
            / len(sample_queries),
            "total_scanned_rows": sum(
                q["before_rows"] for q in impact_analysis["affected_queries"]
            ),
        }

        impact_analysis["after_metrics"] = {
            "avg_cost": sum(
                q["after_cost"] for q in impact_analysis["affected_queries"]
            )
            / len(sample_queries),
            "total_scanned_rows": sum(
                q["after_rows"] for q in impact_analysis["affected_queries"]
            ),
        }

        # Calculate improvement
        before_cost = impact_analysis["before_metrics"]["avg_cost"]
        after_cost = impact_analysis["after_metrics"]["avg_cost"]

        impact_analysis["improvement"] = {
            "cost_reduction": before_cost - after_cost,
            "percentage": (
                ((before_cost - after_cost) / before_cost * 100)
                if before_cost > 0
                else 0
            ),
            "scan_reduction": impact_analysis["before_metrics"]["total_scanned_rows"]
            - impact_analysis["after_metrics"]["total_scanned_rows"],
        }

        # Estimate storage impact
        impact_analysis["storage_impact"] = {
            "index_size_mb": len(index_columns) * 5,  # Rough estimate
            "additional_memory_mb": len(index_columns) * 2,  # Buffer pool consideration
            "disk_io_increase": "5-10%",  # Estimated write overhead
        }

        # Estimate write impact
        impact_analysis["write_impact"] = {
            "insert_overhead": f"{len(index_columns) * 2}%",
            "update_overhead": f"{len(index_columns) * 3}%",
            "delete_overhead": f"{len(index_columns) * 1}%",
        }

        return impact_analysis

    def _analyze_query_impact(
        self, query: str, table: str, index_columns: List[str]
    ) -> Dict[str, Any]:
        """Analyze impact of index on a specific query."""
        # This is a simplified analysis - in production, would use EXPLAIN
        has_where = "WHERE" in query.upper()
        has_orderby = "ORDER BY" in query.upper()
        has_join = "JOIN" in query.upper()

        # Estimate before metrics (without index)
        before_cost = 100  # Base cost for full table scan
        before_rows = 10000  # Assume scanning all rows

        # Estimate after metrics (with index)
        after_cost = before_cost
        after_rows = before_rows

        # Check if index helps this query
        helps_query = False

        if has_where:
            # Check if WHERE columns match index
            for col in index_columns:
                if col.upper() in query.upper():
                    helps_query = True
                    after_cost = 10  # Index seek
                    after_rows = 100  # Much fewer rows
                    break

        if has_orderby and not helps_query:
            # Check if ORDER BY columns match index
            for col in index_columns:
                if col.upper() in query.upper():
                    helps_query = True
                    after_cost = 20  # Index scan
                    after_rows = 1000
                    break

        if has_join and not helps_query:
            # Check if JOIN columns match index
            for col in index_columns:
                if col.upper() in query.upper():
                    helps_query = True
                    after_cost = 30  # Index join
                    after_rows = 500
                    break

        return {
            "query": query[:100] + "..." if len(query) > 100 else query,
            "uses_index": helps_query,
            "before_cost": before_cost,
            "after_cost": after_cost,
            "before_rows": before_rows,
            "after_rows": after_rows,
            "improvement": (
                ((before_cost - after_cost) / before_cost * 100)
                if before_cost > 0
                else 0
            ),
        }

    def get_index_recommendations(
        self, database: str, limit: int = 10
    ) -> List[Dict[str, Any]]:
        """Get top index recommendations for a database."""
        # Compile all suggestions and sort by impact
        all_suggestions = sorted(
            self.index_suggestions, key=lambda x: x["impact_score"], reverse=True
        )

        # Filter by database if specified
        if database:
            all_suggestions = [
                s for s in all_suggestions if s.get("database") == database
            ]

        return all_suggestions[:limit]

    def generate_index_report(
        self, analysis_results: Dict[str, Any], suggestions: List[Dict[str, Any]]
    ) -> Dict[str, Any]:
        """Generate a comprehensive index optimization report."""
        report = {
            "generated_at": datetime.now().isoformat(),
            "summary": {
                "total_slow_queries": analysis_results["total_queries"],
                "patterns_identified": len(analysis_results["patterns_found"]),
                "problem_areas": len(analysis_results["problem_areas"]),
                "optimization_potential": f"{analysis_results['optimization_potential']:.1f}%",
                "total_suggestions": len(suggestions),
                "critical_suggestions": sum(
                    1 for s in suggestions if s["recommendation"] == "critical"
                ),
                "estimated_improvement": self._estimate_total_improvement(suggestions),
            },
            "top_problems": analysis_results["problem_areas"][:5],
            "top_suggestions": suggestions[:10],
            "implementation_plan": self._create_implementation_plan(suggestions),
            "monitoring_recommendations": [
                "Monitor query performance after index creation",
                "Track index usage statistics",
                "Watch for increased write latency",
                "Review index fragmentation monthly",
                "Consider index maintenance windows",
            ],
        }

        return report

    def _estimate_total_improvement(self, suggestions: List[Dict[str, Any]]) -> str:
        """Estimate total performance improvement from all suggestions."""
        if not suggestions:
            return "0%"

        # Weighted average based on impact scores
        total_impact = sum(s["impact_score"] for s in suggestions[:10])

        if total_impact > 500:
            return "60-80%"
        elif total_impact > 200:
            return "40-60%"
        elif total_impact > 100:
            return "20-40%"
        else:
            return "10-20%"

    def _create_implementation_plan(
        self, suggestions: List[Dict[str, Any]]
    ) -> List[Dict[str, Any]]:
        """Create a phased implementation plan for index creation."""
        plan = []

        # Phase 1: Critical indexes
        critical = [s for s in suggestions if s["recommendation"] == "critical"]
        if critical:
            plan.append(
                {
                    "phase": 1,
                    "priority": "Immediate",
                    "indexes": critical[:3],
                    "estimated_time": "1-2 hours",
                    "risk": "Low",
                    "rollback": "DROP INDEX if issues arise",
                }
            )

        # Phase 2: High impact indexes
        high = [s for s in suggestions if s["recommendation"] == "high"]
        if high:
            plan.append(
                {
                    "phase": 2,
                    "priority": "This week",
                    "indexes": high[:5],
                    "estimated_time": "2-4 hours",
                    "risk": "Low-Medium",
                    "rollback": "Monitor and remove if write performance degrades",
                }
            )

        # Phase 3: Medium impact indexes
        medium = [s for s in suggestions if s["recommendation"] == "medium"]
        if medium:
            plan.append(
                {
                    "phase": 3,
                    "priority": "This month",
                    "indexes": medium[:5],
                    "estimated_time": "2-3 hours",
                    "risk": "Low",
                    "rollback": "Evaluate after 30 days",
                }
            )

        return plan
