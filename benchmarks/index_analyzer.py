#!/usr/bin/env python3
"""Index Effectiveness Analyzer.

This tool analyzes index usage and effectiveness across database schemas,
providing recommendations for index optimization.
"""

import mysql.connector
from typing import Dict, List
from dataclasses import dataclass, field
from datetime import datetime
import json
from pathlib import Path
import statistics


@dataclass
class IndexStats:
    """Statistics for a single index."""

    table_name: str
    index_name: str
    column_names: List[str]
    index_type: str
    cardinality: int
    size_bytes: int
    usage_count: int = 0
    selectivity: float = 0.0
    efficiency_score: float = 0.0
    recommendations: List[str] = field(default_factory=list)

    def to_dict(self) -> Dict:
        """Convert to dictionary for JSON serialization."""
        return {
            "table_name": self.table_name,
            "index_name": self.index_name,
            "columns": self.column_names,
            "type": self.index_type,
            "cardinality": self.cardinality,
            "size_mb": round(self.size_bytes / (1024 * 1024), 2),
            "usage_count": self.usage_count,
            "selectivity": round(self.selectivity, 4),
            "efficiency_score": round(self.efficiency_score, 2),
            "recommendations": self.recommendations,
        }


class IndexAnalyzer:
    """Analyze index effectiveness and provide optimization recommendations."""

    def __init__(self, connection_params: Dict):
        """Initialize the instance."""
        self.connection_params = connection_params
        self.connection = None
        self.cursor = None
        self.indexes = {}
        self.unused_indexes = []
        self.duplicate_indexes = []
        self.missing_indexes = []

    def connect(self) -> bool:
        """Establish database connection."""
        try:
            self.connection = mysql.connector.connect(**self.connection_params)
            self.cursor = self.connection.cursor(dictionary=True)
            return True
        except Exception as e:
            print(f"Connection failed: {e}")
            return False

    def disconnect(self):
        """Close database connection."""
        if self.cursor:
            self.cursor.close()
        if self.connection:
            self.connection.close()

    def analyze_all_indexes(self) -> Dict:
        """Perform comprehensive index analysis."""
        print("Starting index analysis...")

        # Collect all indexes
        self._collect_indexes()

        # Analyze index usage
        self._analyze_index_usage()

        # Check for duplicate indexes
        self._find_duplicate_indexes()

        # Analyze cardinality and selectivity
        self._analyze_cardinality()

        # Find potentially missing indexes
        self._find_missing_indexes()

        # Calculate efficiency scores
        self._calculate_efficiency_scores()

        # Generate recommendations
        self._generate_recommendations()

        return self._compile_report()

    def _collect_indexes(self):
        """Collect all indexes from the database."""
        self.cursor.execute(
            """
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
        """,
            (self.connection_params["database"],),
        )

        for row in self.cursor.fetchall():
            index_stats = IndexStats(
                table_name=row["TABLE_NAME"],
                index_name=row["INDEX_NAME"],
                column_names=row["COLUMNS"].split(",") if row["COLUMNS"] else [],
                index_type=row["INDEX_TYPE"],
                cardinality=row["CARDINALITY"] or 0,
                size_bytes=self._get_index_size(row["TABLE_NAME"], row["INDEX_NAME"]),
            )
            self.indexes[f"{row['TABLE_NAME']}.{row['INDEX_NAME']}"] = index_stats

    def _get_index_size(self, table_name: str, index_name: str) -> int:
        """Get the size of an index in bytes."""
        try:
            self.cursor.execute(
                """
                SELECT
                    (INDEX_LENGTH + DATA_LENGTH) as SIZE_BYTES
                FROM information_schema.TABLES
                WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s
            """,
                (self.connection_params["database"], table_name),
            )

            result = self.cursor.fetchone()
            return result["SIZE_BYTES"] if result else 0
        except Exception:
            return 0

    def _analyze_index_usage(self):
        """Analyze how often each index is being used."""
        try:
            # Check if performance_schema is available
            self.cursor.execute(
                """
                SELECT COUNT(*) as count
                FROM information_schema.TABLES
                WHERE TABLE_SCHEMA = 'performance_schema'
                AND TABLE_NAME = 'table_io_waits_summary_by_index_usage'
            """
            )

            if self.cursor.fetchone()["count"] > 0:
                self.cursor.execute(
                    """
                    SELECT
                        OBJECT_NAME as TABLE_NAME,
                        INDEX_NAME,
                        COUNT_READ,
                        COUNT_WRITE,
                        COUNT_FETCH,
                        COUNT_INSERT,
                        COUNT_UPDATE,
                        COUNT_DELETE
                    FROM performance_schema.table_io_waits_summary_by_index_usage
                    WHERE OBJECT_SCHEMA = %s
                    AND INDEX_NAME IS NOT NULL
                """,
                    (self.connection_params["database"],),
                )

                for row in self.cursor.fetchall():
                    key = f"{row['TABLE_NAME']}.{row['INDEX_NAME']}"
                    if key in self.indexes:
                        self.indexes[key].usage_count = (
                            row["COUNT_READ"] + row["COUNT_FETCH"]
                        )

                # Find unused indexes
                for _, index in self.indexes.items():
                    if index.usage_count == 0 and index.index_name != "PRIMARY":
                        self.unused_indexes.append(index)
        except Exception as e:
            print(
                f"Warning: Could not analyze index usage from performance_schema: {e}"
            )

    def _find_duplicate_indexes(self):
        """Find duplicate or redundant indexes."""
        index_signatures = {}

        for _, index in self.indexes.items():
            # Create signature based on table and columns
            signature = f"{index.table_name}:{','.join(index.column_names)}"

            if signature in index_signatures:
                # Found a duplicate
                existing = index_signatures[signature]
                self.duplicate_indexes.append(
                    {
                        "index1": existing.index_name,
                        "index2": index.index_name,
                        "table": index.table_name,
                        "columns": index.column_names,
                    }
                )
            else:
                index_signatures[signature] = index

            # Check for prefix duplicates (e.g., idx(a,b) is redundant if idx(a,b,c) exists)
            for other_sig, other_index in index_signatures.items():
                if (
                    other_sig.startswith(signature + ",")
                    and other_index.table_name == index.table_name
                ):
                    self.duplicate_indexes.append(
                        {
                            "index1": index.index_name,
                            "index2": other_index.index_name,
                            "table": index.table_name,
                            "type": "prefix_duplicate",
                            "columns": index.column_names,
                        }
                    )

    def _analyze_cardinality(self):
        """Analyze index cardinality and selectivity."""
        for _, index in self.indexes.items():
            # Get total row count
            self.cursor.execute(f"SELECT COUNT(*) as total FROM {index.table_name}")
            total_rows = self.cursor.fetchone()["total"]

            if total_rows > 0:
                # Calculate selectivity (higher is better)
                index.selectivity = (
                    index.cardinality / total_rows if index.cardinality else 0
                )

                # Low selectivity indexes might not be effective
                if index.selectivity < 0.1 and index.index_name != "PRIMARY":
                    index.recommendations.append(
                        f"Low selectivity ({index.selectivity:.2%}) - consider removing"
                    )

    def _find_missing_indexes(self):
        """Analyze slow query log to find potentially missing indexes."""
        try:
            # Check if slow query log is enabled
            self.cursor.execute("SHOW VARIABLES LIKE 'slow_query_log'")
            slow_log = self.cursor.fetchone()

            if slow_log and slow_log["Value"] == "ON":
                # Get slow query log file location
                self.cursor.execute("SHOW VARIABLES LIKE 'slow_query_log_file'")
                _ = self.cursor.fetchone()

                # Note: In production, you'd parse the slow query log
                # For now, we'll check for common patterns

                # Check for WHERE clauses without indexes
                for table_name in {idx.table_name for idx in self.indexes.values()}:
                    self._check_table_for_missing_indexes(table_name)
        except Exception as e:
            print(f"Warning: Could not analyze slow query log: {e}")

    def _check_table_for_missing_indexes(self, table_name: str):
        """Check if a table might benefit from additional indexes."""
        try:
            # Get columns that are frequently used in WHERE clauses
            # This is a simplified check - in production, analyze actual queries
            self.cursor.execute(f"DESCRIBE {table_name}")
            columns = self.cursor.fetchall()

            indexed_columns = set()
            for index in self.indexes.values():
                if index.table_name == table_name:
                    indexed_columns.update(index.column_names)

            for column in columns:
                col_name = column["Field"]
                col_type = column["Type"]

                # Check if foreign key columns have indexes
                if col_name.endswith("_id") and col_name not in indexed_columns:
                    self.missing_indexes.append(
                        {
                            "table": table_name,
                            "column": col_name,
                            "reason": "Foreign key column without index",
                        }
                    )

                # Check if date/timestamp columns used for filtering have indexes
                if (
                    "date" in col_type.lower() or "time" in col_type.lower()
                ) and col_name not in indexed_columns:
                    self.missing_indexes.append(
                        {
                            "table": table_name,
                            "column": col_name,
                            "reason": "Date/time column often used for filtering",
                        }
                    )
        except Exception as e:
            print(
                f"Warning: Could not check table {table_name} for missing indexes: {e}"
            )

    def _calculate_efficiency_scores(self):
        """Calculate efficiency score for each index."""
        for index in self.indexes.values():
            score = 0

            # Factor 1: Usage (40% weight)
            if index.usage_count > 0:
                score += 40

            # Factor 2: Selectivity (30% weight)
            score += index.selectivity * 30

            # Factor 3: Size efficiency (20% weight)
            if index.size_bytes < 10 * 1024 * 1024:  # Less than 10MB
                score += 20
            elif index.size_bytes < 100 * 1024 * 1024:  # Less than 100MB
                score += 10

            # Factor 4: Not duplicate (10% weight)
            is_duplicate = any(
                d["index1"] == index.index_name or d["index2"] == index.index_name
                for d in self.duplicate_indexes
            )
            if not is_duplicate:
                score += 10

            index.efficiency_score = min(score, 100)

    def _generate_recommendations(self):
        """Generate specific recommendations for each index."""
        for index in self.indexes.values():
            # Unused indexes
            if index.usage_count == 0 and index.index_name != "PRIMARY":
                index.recommendations.append(
                    "UNUSED: Consider dropping this index to save space"
                )

            # Large indexes with low usage
            if index.size_bytes > 100 * 1024 * 1024 and index.usage_count < 100:
                index.recommendations.append(
                    f"OVERSIZED: Large index ({index.size_bytes / (1024*1024):.1f}MB) with low usage"
                )

            # Low efficiency score
            if index.efficiency_score < 30:
                index.recommendations.append(
                    f"INEFFICIENT: Score {index.efficiency_score:.1f}/100 - review necessity"
                )

    def _compile_report(self) -> Dict:
        """Compile comprehensive analysis report."""
        report = {
            "timestamp": datetime.now().isoformat(),
            "database": self.connection_params["database"],
            "summary": {
                "total_indexes": len(self.indexes),
                "unused_indexes": len(self.unused_indexes),
                "duplicate_indexes": len(self.duplicate_indexes),
                "missing_indexes": len(self.missing_indexes),
                "total_index_size_mb": sum(
                    idx.size_bytes for idx in self.indexes.values()
                )
                / (1024 * 1024),
                "avg_efficiency_score": (
                    statistics.mean(
                        idx.efficiency_score for idx in self.indexes.values()
                    )
                    if self.indexes
                    else 0
                ),
            },
            "indexes": [idx.to_dict() for idx in self.indexes.values()],
            "unused_indexes": [idx.to_dict() for idx in self.unused_indexes],
            "duplicate_indexes": self.duplicate_indexes,
            "missing_indexes": self.missing_indexes,
            "top_recommendations": self._get_top_recommendations(),
        }

        return report

    def _get_top_recommendations(self) -> List[Dict]:
        """Get top actionable recommendations."""
        recommendations = []

        # Recommend dropping unused indexes
        for index in self.unused_indexes[:5]:
            recommendations.append(
                {
                    "priority": "HIGH",
                    "action": "DROP INDEX",
                    "target": f"{index.table_name}.{index.index_name}",
                    "reason": "Index is not being used",
                    "sql": f"ALTER TABLE {index.table_name} DROP INDEX {index.index_name};",
                }
            )

        # Recommend removing duplicate indexes
        for dup in self.duplicate_indexes[:5]:
            recommendations.append(
                {
                    "priority": "MEDIUM",
                    "action": "DROP DUPLICATE",
                    "target": f"{dup['table']}.{dup['index2']}",
                    "reason": f"Duplicate of {dup['index1']}",
                    "sql": f"ALTER TABLE {dup['table']} DROP INDEX {dup['index2']};",
                }
            )

        # Recommend adding missing indexes
        for missing in self.missing_indexes[:5]:
            recommendations.append(
                {
                    "priority": "MEDIUM",
                    "action": "CREATE INDEX",
                    "target": f"{missing['table']}.{missing['column']}",
                    "reason": missing["reason"],
                    "sql": f"CREATE INDEX idx_{missing['column']} ON {missing['table']}({missing['column']});",
                }
            )

        return recommendations

    def export_report(self, output_file: Path):
        """Export analysis report to JSON file."""
        report = self.analyze_all_indexes()

        with open(output_file, "w") as f:
            json.dump(report, f, indent=2)

        print(f"Index analysis report exported to: {output_file}")

        # Print summary
        print("\n=== Index Analysis Summary ===")
        print(f"Total Indexes: {report['summary']['total_indexes']}")
        print(f"Unused Indexes: {report['summary']['unused_indexes']}")
        print(f"Duplicate Indexes: {report['summary']['duplicate_indexes']}")
        print(f"Missing Indexes: {report['summary']['missing_indexes']}")
        print(f"Total Index Size: {report['summary']['total_index_size_mb']:.2f} MB")
        print(
            f"Avg Efficiency Score: {report['summary']['avg_efficiency_score']:.1f}/100"
        )

        if report["top_recommendations"]:
            print("\n=== Top Recommendations ===")
            for rec in report["top_recommendations"][:5]:
                print(f"[{rec['priority']}] {rec['action']}: {rec['target']}")
                print(f"  Reason: {rec['reason']}")
                print(f"  SQL: {rec['sql']}\n")


def main():
    """Run entry point."""
    # Example usage
    connection_params = {
        "host": "localhost",
        "port": 3308,
        "user": "root",
        "password": "clinic_root",
        "database": "clinic_db",
    }

    analyzer = IndexAnalyzer(connection_params)

    if analyzer.connect():
        try:
            output_dir = Path(__file__).parent / "results"
            output_dir.mkdir(exist_ok=True)
            output_file = output_dir / "index_analysis.json"

            analyzer.export_report(output_file)
        finally:
            analyzer.disconnect()


if __name__ == "__main__":
    main()
