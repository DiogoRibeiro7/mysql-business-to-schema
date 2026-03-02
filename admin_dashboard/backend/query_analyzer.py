"""Query Analyzer for Admin Dashboard.

Analyzes and optimizes SQL queries
"""

import logging
from typing import List, Dict, Any
from datetime import datetime
import re
import hashlib

logger = logging.getLogger(__name__)


class QueryAnalyzer:
    """Analyze SQL queries for performance and optimization."""

    def __init__(self):
        """Initialize the instance."""
        self.query_cache = {}
        self.slow_query_threshold_ms = 100
        self.query_history = []
        self.optimization_rules = self._load_optimization_rules()

    def _load_optimization_rules(self) -> List[Dict[str, Any]]:
        """Load query optimization rules."""
        return [
            {
                "id": "missing_index",
                "pattern": r"WHERE\s+(\w+)\s*=",
                "suggestion": "Consider adding an index on column: {column}",
                "severity": "warning",
            },
            {
                "id": "select_star",
                "pattern": r"SELECT\s+\*\s+FROM",
                "suggestion": "Avoid SELECT *, specify needed columns explicitly",
                "severity": "info",
            },
            {
                "id": "no_limit",
                "pattern": r"SELECT.*FROM.*(?!LIMIT)",
                "suggestion": "Consider adding LIMIT clause to prevent large result sets",
                "severity": "info",
            },
            {
                "id": "or_condition",
                "pattern": r"WHERE.*\sOR\s",
                "suggestion": "OR conditions can prevent index usage, consider using UNION",
                "severity": "warning",
            },
            {
                "id": "like_wildcard",
                "pattern": r"LIKE\s+['\"]%\w+",
                "suggestion": "Leading wildcards prevent index usage",
                "severity": "warning",
            },
        ]

    def analyze_query(self, query: str) -> Dict[str, Any]:
        """Analyze a SQL query for performance issues."""
        query_hash = hashlib.md5(query.encode()).hexdigest()

        # Check cache
        if query_hash in self.query_cache:
            return self.query_cache[query_hash]

        analysis = {
            "query": query,
            "hash": query_hash,
            "type": self._detect_query_type(query),
            "tables": self._extract_tables(query),
            "columns": self._extract_columns(query),
            "conditions": self._extract_conditions(query),
            "suggestions": [],
            "estimated_cost": self._estimate_cost(query),
            "complexity": self._calculate_complexity(query),
            "analyzed_at": datetime.now().isoformat(),
        }

        # Apply optimization rules
        for rule in self.optimization_rules:
            if re.search(rule["pattern"], query, re.IGNORECASE):
                analysis["suggestions"].append(
                    {
                        "rule_id": rule["id"],
                        "severity": rule["severity"],
                        "message": rule["suggestion"],
                    }
                )

        # Cache the analysis
        self.query_cache[query_hash] = analysis

        # Add to history
        self.query_history.append(analysis)

        return analysis

    def _detect_query_type(self, query: str) -> str:
        """Detect the type of SQL query."""
        query_upper = query.strip().upper()
        if query_upper.startswith("SELECT"):
            return "SELECT"
        elif query_upper.startswith("INSERT"):
            return "INSERT"
        elif query_upper.startswith("UPDATE"):
            return "UPDATE"
        elif query_upper.startswith("DELETE"):
            return "DELETE"
        elif query_upper.startswith("CREATE"):
            return "CREATE"
        elif query_upper.startswith("ALTER"):
            return "ALTER"
        elif query_upper.startswith("DROP"):
            return "DROP"
        else:
            return "OTHER"

    def _extract_tables(self, query: str) -> List[str]:
        """Extract table names from query."""
        tables = []

        # Extract from FROM clause
        from_pattern = r"FROM\s+([a-zA-Z_]\w*)"
        from_matches = re.findall(from_pattern, query, re.IGNORECASE)
        tables.extend(from_matches)

        # Extract from JOIN clauses
        join_pattern = r"JOIN\s+([a-zA-Z_]\w*)"
        join_matches = re.findall(join_pattern, query, re.IGNORECASE)
        tables.extend(join_matches)

        return list(set(tables))

    def _extract_columns(self, query: str) -> List[str]:
        """Extract column names from query."""
        columns = []

        # Extract from SELECT clause
        select_pattern = r"SELECT\s+(.*?)\s+FROM"
        select_match = re.search(select_pattern, query, re.IGNORECASE | re.DOTALL)
        if select_match:
            select_clause = select_match.group(1)
            if select_clause.strip() != "*":
                # Parse column list
                column_parts = select_clause.split(",")
                for part in column_parts:
                    # Extract column name (handle aliases)
                    col_match = re.match(r"([a-zA-Z_]\w*)", part.strip())
                    if col_match:
                        columns.append(col_match.group(1))

        # Extract from WHERE clause
        where_pattern = r"WHERE\s+([a-zA-Z_]\w*)\s*[=<>]"
        where_matches = re.findall(where_pattern, query, re.IGNORECASE)
        columns.extend(where_matches)

        return list(set(columns))

    def _extract_conditions(self, query: str) -> List[str]:
        """Extract WHERE conditions from query."""
        conditions = []

        where_pattern = r"WHERE\s+(.*?)(?:GROUP|ORDER|LIMIT|$)"
        where_match = re.search(where_pattern, query, re.IGNORECASE | re.DOTALL)

        if where_match:
            where_clause = where_match.group(1)
            # Split by AND/OR
            condition_parts = re.split(
                r"\s+(?:AND|OR)\s+", where_clause, flags=re.IGNORECASE
            )
            conditions = [c.strip() for c in condition_parts if c.strip()]

        return conditions

    def _estimate_cost(self, query: str) -> int:
        """Estimate query cost (simplified)."""
        cost = 10  # Base cost

        # Add cost for joins
        join_count = len(re.findall(r"\bJOIN\b", query, re.IGNORECASE))
        cost += join_count * 20

        # Add cost for subqueries
        subquery_count = query.count("(SELECT")
        cost += subquery_count * 30

        # Add cost for missing LIMIT
        if "LIMIT" not in query.upper() and "SELECT" in query.upper():
            cost += 50

        # Add cost for OR conditions
        or_count = len(re.findall(r"\bOR\b", query, re.IGNORECASE))
        cost += or_count * 15

        return cost

    def _calculate_complexity(self, query: str) -> str:
        """Calculate query complexity level."""
        cost = self._estimate_cost(query)

        if cost < 30:
            return "simple"
        elif cost < 70:
            return "moderate"
        elif cost < 120:
            return "complex"
        else:
            return "very_complex"

    def get_slow_queries(self, limit: int = 10) -> List[Dict[str, Any]]:
        """Get list of slow queries."""
        # Simulate slow queries for demo
        slow_queries = []

        for i, query in enumerate(self.query_history[-limit:]):
            if query.get("estimated_cost", 0) > 50:
                slow_queries.append(
                    {
                        "id": f"slow_{i}",
                        "query": query["query"],
                        "duration_ms": query["estimated_cost"] * 2,
                        "timestamp": query.get(
                            "analyzed_at", datetime.now().isoformat()
                        ),
                        "suggestions": query.get("suggestions", []),
                    }
                )

        return slow_queries

    def optimize_query(self, query: str) -> Dict[str, Any]:
        """Suggest optimizations for a query."""
        analysis = self.analyze_query(query)

        optimized_query = query
        optimizations = []

        # Apply automatic optimizations
        if "SELECT *" in query.upper():
            # This is a simplified example
            optimizations.append(
                {
                    "type": "column_specification",
                    "description": "Replace SELECT * with specific columns",
                    "impact": "high",
                }
            )

        if "LIMIT" not in query.upper() and "SELECT" in query.upper():
            optimized_query += " LIMIT 100"
            optimizations.append(
                {
                    "type": "add_limit",
                    "description": "Added LIMIT clause to prevent large result sets",
                    "impact": "medium",
                }
            )

        return {
            "original_query": query,
            "optimized_query": optimized_query,
            "optimizations": optimizations,
            "estimated_improvement": "30%",
            "analysis": analysis,
        }

    def get_query_plan(self, query: str) -> Dict[str, Any]:
        """Get execution plan for a query (simulated)."""
        return {
            "query": query,
            "plan": {
                "type": "SIMPLE",
                "table": (
                    self._extract_tables(query)[0]
                    if self._extract_tables(query)
                    else "unknown"
                ),
                "possible_keys": ["PRIMARY"],
                "key": "PRIMARY",
                "rows": 100,
                "filtered": 100.0,
                "extra": "Using where",
            },
            "cost": self._estimate_cost(query),
            "warnings": [],
        }

    def get_index_suggestions(self, schema_name: str) -> List[Dict[str, Any]]:
        """Get index suggestions for a schema."""
        suggestions = []

        # Analyze recent queries for this schema
        for query in self.query_history[-100:]:
            for condition in query.get("conditions", []):
                # Extract column from condition
                col_match = re.match(r"([a-zA-Z_]\w*)\s*[=<>]", condition)
                if col_match:
                    column = col_match.group(1)
                    suggestions.append(
                        {
                            "table": (
                                query.get("tables", ["unknown"])[0]
                                if query.get("tables")
                                else "unknown"
                            ),
                            "column": column,
                            "type": "INDEX",
                            "reason": "Frequently used in WHERE clause",
                            "estimated_impact": "medium",
                            "priority": "medium",
                        }
                    )

        # Remove duplicates
        seen = set()
        unique_suggestions = []
        for s in suggestions:
            key = f"{s['table']}_{s['column']}"
            if key not in seen:
                seen.add(key)
                unique_suggestions.append(s)

        return unique_suggestions[:10]  # Return top 10 suggestions
