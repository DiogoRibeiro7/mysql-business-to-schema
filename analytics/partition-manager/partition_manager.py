#!/usr/bin/env python3
"""Partition Manager for MySQL Time-Series Data.

Automatically manages partitions for optimal performance
"""

import mysql.connector
from mysql.connector import Error
from datetime import datetime, timedelta
from typing import Dict, List
import logging
import json
import yaml
from pathlib import Path


class PartitionManager:
    """Manages MySQL partitions for time-series data."""

    def __init__(self, connection_params: Dict[str, any]):
        """Initialize Partition Manager."""
        self.connection_params = connection_params
        self.logger = logging.getLogger(__name__)
        logging.basicConfig(level=logging.INFO)

    def analyze_table(self, database: str, table: str) -> Dict:
        """Analyze a table to determine if it needs partitioning."""
        try:
            conn = mysql.connector.connect(**self.connection_params)
            cursor = conn.cursor(dictionary=True)

            # Switch to database
            cursor.execute(f"USE {database}")

            # Get table information
            cursor.execute(
                """
                SELECT
                    TABLE_ROWS as row_count,
                    DATA_LENGTH as data_size,
                    INDEX_LENGTH as index_size,
                    CREATE_TIME as created_at,
                    UPDATE_TIME as updated_at
                FROM information_schema.TABLES
                WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s
            """,
                (database, table),
            )

            table_info = cursor.fetchone()

            # Check if table has date/timestamp columns
            cursor.execute(
                """
                SELECT
                    COLUMN_NAME,
                    DATA_TYPE,
                    COLUMN_TYPE,
                    IS_NULLABLE,
                    COLUMN_KEY
                FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s
                AND DATA_TYPE IN ('date', 'datetime', 'timestamp')
                ORDER BY ORDINAL_POSITION
            """,
                (database, table),
            )

            date_columns = cursor.fetchall()

            # Check if table is already partitioned
            cursor.execute(
                """
                SELECT
                    PARTITION_NAME,
                    PARTITION_EXPRESSION,
                    PARTITION_DESCRIPTION,
                    TABLE_ROWS
                FROM information_schema.PARTITIONS
                WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s
                AND PARTITION_NAME IS NOT NULL
            """,
                (database, table),
            )

            partitions = cursor.fetchall()

            # Analyze data distribution over time
            distribution = {}
            if date_columns:
                primary_date = date_columns[0]["COLUMN_NAME"]
                cursor.execute(
                    f"""
                    SELECT
                        DATE_FORMAT({primary_date}, '%%Y-%%m') as month,
                        COUNT(*) as row_count,
                        MIN({primary_date}) as min_date,
                        MAX({primary_date}) as max_date
                    FROM {table}
                    GROUP BY DATE_FORMAT({primary_date}, '%%Y-%%m')
                    ORDER BY month DESC
                    LIMIT 24
                """
                )

                for row in cursor.fetchall():
                    distribution[row["month"]] = {
                        "row_count": row["row_count"],
                        "min_date": str(row["min_date"]),
                        "max_date": str(row["max_date"]),
                    }

            cursor.close()
            conn.close()

            # Generate recommendations
            recommendations = self._generate_recommendations(
                table_info, date_columns, partitions, distribution
            )

            return {
                "database": database,
                "table": table,
                "info": table_info,
                "date_columns": date_columns,
                "existing_partitions": partitions,
                "data_distribution": distribution,
                "recommendations": recommendations,
            }

        except Error as e:
            self.logger.error(f"Error analyzing table: {e}")
            return {"error": str(e)}

    def create_partitions(
        self, database: str, table: str, partition_config: Dict
    ) -> bool:
        """Create partitions for a table."""
        try:
            conn = mysql.connector.connect(**self.connection_params)
            cursor = conn.cursor()

            cursor.execute(f"USE {database}")

            partition_type = partition_config["type"]
            column = partition_config["column"]

            if partition_type == "RANGE":
                sql = self._create_range_partitions(table, column, partition_config)
            elif partition_type == "LIST":
                sql = self._create_list_partitions(table, column, partition_config)
            elif partition_type == "HASH":
                sql = self._create_hash_partitions(table, column, partition_config)
            else:
                raise ValueError(f"Unsupported partition type: {partition_type}")

            # Execute partition creation
            self.logger.info(f"Creating partitions for {database}.{table}")
            cursor.execute(sql)

            conn.commit()
            cursor.close()
            conn.close()

            self.logger.info(f"Successfully created partitions for {database}.{table}")
            return True

        except Error as e:
            self.logger.error(f"Error creating partitions: {e}")
            return False

    def add_partition(
        self, database: str, table: str, partition_name: str, partition_value: str
    ) -> bool:
        """Add a new partition to an existing partitioned table."""
        try:
            conn = mysql.connector.connect(**self.connection_params)
            cursor = conn.cursor()

            cursor.execute(f"USE {database}")

            sql = f"""
                ALTER TABLE {table}
                ADD PARTITION (
                    PARTITION {partition_name} VALUES LESS THAN ('{partition_value}')
                )
            """

            cursor.execute(sql)
            conn.commit()

            cursor.close()
            conn.close()

            self.logger.info(f"Added partition {partition_name} to {database}.{table}")
            return True

        except Error as e:
            self.logger.error(f"Error adding partition: {e}")
            return False

    def drop_partition(self, database: str, table: str, partition_name: str) -> bool:
        """Drop a partition from a table."""
        try:
            conn = mysql.connector.connect(**self.connection_params)
            cursor = conn.cursor()

            cursor.execute(f"USE {database}")

            sql = f"ALTER TABLE {table} DROP PARTITION {partition_name}"
            cursor.execute(sql)

            conn.commit()
            cursor.close()
            conn.close()

            self.logger.info(
                f"Dropped partition {partition_name} from {database}.{table}"
            )
            return True

        except Error as e:
            self.logger.error(f"Error dropping partition: {e}")
            return False

    def reorganize_partitions(
        self,
        database: str,
        table: str,
        old_partitions: List[str],
        new_partition_config: Dict,
    ) -> bool:
        """Reorganize existing partitions."""
        try:
            conn = mysql.connector.connect(**self.connection_params)
            cursor = conn.cursor()

            cursor.execute(f"USE {database}")

            # Build reorganize statement
            old_parts = ", ".join(old_partitions)
            new_parts = self._build_partition_definitions(new_partition_config)

            sql = f"""
                ALTER TABLE {table}
                REORGANIZE PARTITION {old_parts}
                INTO ({new_parts})
            """

            cursor.execute(sql)
            conn.commit()

            cursor.close()
            conn.close()

            self.logger.info(f"Reorganized partitions for {database}.{table}")
            return True

        except Error as e:
            self.logger.error(f"Error reorganizing partitions: {e}")
            return False

    def auto_maintain_partitions(
        self,
        database: str,
        table: str,
        retention_days: int = 365,
        future_partitions: int = 3,
    ) -> Dict:
        """Automatically maintain partitions (add future, drop old)."""
        results = {"added": [], "dropped": [], "errors": []}

        try:
            conn = mysql.connector.connect(**self.connection_params)
            cursor = conn.cursor(dictionary=True)

            cursor.execute(f"USE {database}")

            # Get current partitions
            cursor.execute(
                """
                SELECT
                    PARTITION_NAME,
                    PARTITION_DESCRIPTION,
                    TABLE_ROWS
                FROM information_schema.PARTITIONS
                WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s
                AND PARTITION_NAME IS NOT NULL
                ORDER BY PARTITION_DESCRIPTION
            """,
                (database, table),
            )

            partitions = cursor.fetchall()

            if not partitions:
                results["errors"].append(f"Table {table} is not partitioned")
                return results

            # Determine partition scheme (assuming monthly for now)
            today = datetime.now()
            cutoff_date = today - timedelta(days=retention_days)

            # Drop old partitions
            for partition in partitions:
                if partition["PARTITION_DESCRIPTION"]:
                    # Parse partition date from description
                    try:
                        part_date = datetime.strptime(
                            partition["PARTITION_DESCRIPTION"].strip("'"), "%Y-%m-%d"
                        )
                        if part_date < cutoff_date:
                            if self.drop_partition(
                                database, table, partition["PARTITION_NAME"]
                            ):
                                results["dropped"].append(partition["PARTITION_NAME"])
                                self.logger.info(
                                    f"Dropped old partition {partition['PARTITION_NAME']} "
                                    f"(date: {part_date})"
                                )
                    except ValueError:
                        continue

            # Add future partitions
            last_partition_date = (
                datetime.strptime(
                    partitions[-1]["PARTITION_DESCRIPTION"].strip("'"), "%Y-%m-%d"
                )
                if partitions
                else today
            )

            for i in range(1, future_partitions + 1):
                next_month = last_partition_date + timedelta(days=30 * i)
                partition_name = f"p{next_month.strftime('%Y%m')}"
                partition_value = (next_month + timedelta(days=30)).strftime("%Y-%m-%d")

                # Check if partition already exists
                exists = any(p["PARTITION_NAME"] == partition_name for p in partitions)

                if not exists:
                    if self.add_partition(
                        database, table, partition_name, partition_value
                    ):
                        results["added"].append(partition_name)
                        self.logger.info(
                            f"Added future partition {partition_name} "
                            f"(values < {partition_value})"
                        )

            cursor.close()
            conn.close()

        except Error as e:
            results["errors"].append(str(e))
            self.logger.error(f"Error in auto-maintenance: {e}")

        return results

    def get_partition_statistics(self, database: str, table: str) -> List[Dict]:
        """Get detailed statistics for each partition."""
        try:
            conn = mysql.connector.connect(**self.connection_params)
            cursor = conn.cursor(dictionary=True)

            cursor.execute(f"USE {database}")

            # Get partition information
            cursor.execute(
                """
                SELECT
                    p.PARTITION_NAME,
                    p.PARTITION_EXPRESSION,
                    p.PARTITION_DESCRIPTION,
                    p.TABLE_ROWS,
                    p.DATA_LENGTH,
                    p.INDEX_LENGTH,
                    p.CREATE_TIME,
                    p.UPDATE_TIME,
                    p.CHECK_TIME
                FROM information_schema.PARTITIONS p
                WHERE p.TABLE_SCHEMA = %s AND p.TABLE_NAME = %s
                AND p.PARTITION_NAME IS NOT NULL
                ORDER BY p.PARTITION_ORDINAL_POSITION
            """,
                (database, table),
            )

            partitions = cursor.fetchall()

            # Calculate statistics
            total_rows = sum(p["TABLE_ROWS"] or 0 for p in partitions)
            total_size = sum(
                (p["DATA_LENGTH"] or 0) + (p["INDEX_LENGTH"] or 0) for p in partitions
            )

            stats = []
            for partition in partitions:
                rows = partition["TABLE_ROWS"] or 0
                data_size = partition["DATA_LENGTH"] or 0
                index_size = partition["INDEX_LENGTH"] or 0
                total_partition_size = data_size + index_size

                stats.append(
                    {
                        "name": partition["PARTITION_NAME"],
                        "description": partition["PARTITION_DESCRIPTION"],
                        "rows": rows,
                        "row_percentage": round(
                            (rows / total_rows * 100) if total_rows > 0 else 0, 2
                        ),
                        "data_size_mb": round(data_size / (1024 * 1024), 2),
                        "index_size_mb": round(index_size / (1024 * 1024), 2),
                        "total_size_mb": round(total_partition_size / (1024 * 1024), 2),
                        "size_percentage": round(
                            (
                                (total_partition_size / total_size * 100)
                                if total_size > 0
                                else 0
                            ),
                            2,
                        ),
                        "last_updated": (
                            str(partition["UPDATE_TIME"])
                            if partition["UPDATE_TIME"]
                            else None
                        ),
                    }
                )

            cursor.close()
            conn.close()

            return stats

        except Error as e:
            self.logger.error(f"Error getting partition statistics: {e}")
            return []

    def _generate_recommendations(
        self, table_info: Dict, date_columns: List, partitions: List, distribution: Dict
    ) -> Dict:
        """Generate partitioning recommendations."""
        recommendations = {
            "should_partition": False,
            "reasons": [],
            "strategy": None,
            "estimated_benefit": None,
        }

        # Check if already partitioned
        if partitions:
            recommendations["already_partitioned"] = True
            recommendations["current_partitions"] = len(partitions)
            return recommendations

        # Check table size
        if table_info:
            row_count = table_info.get("row_count", 0)
            data_size = table_info.get("data_size", 0)

            # Recommend partitioning for large tables
            if row_count > 1000000 or data_size > 1073741824:  # 1GB
                recommendations["should_partition"] = True
                recommendations["reasons"].append(
                    f"Large table: {row_count:,} rows, "
                    f"{data_size / (1024**3):.2f} GB"
                )

        # Check for time-series pattern
        if date_columns and distribution:
            recommendations["should_partition"] = True
            recommendations["reasons"].append(
                f"Time-series data with {len(date_columns)} date columns"
            )

            # Recommend strategy based on distribution
            if len(distribution) > 12:
                recommendations["strategy"] = {
                    "type": "RANGE",
                    "column": date_columns[0]["COLUMN_NAME"],
                    "interval": "MONTHLY",
                    "reason": "Even distribution over multiple months",
                }
            elif len(distribution) > 52:
                recommendations["strategy"] = {
                    "type": "RANGE",
                    "column": date_columns[0]["COLUMN_NAME"],
                    "interval": "WEEKLY",
                    "reason": "High-frequency time-series data",
                }
            else:
                recommendations["strategy"] = {
                    "type": "RANGE",
                    "column": date_columns[0]["COLUMN_NAME"],
                    "interval": "QUARTERLY",
                    "reason": "Low-frequency time-series data",
                }

            # Estimate benefits
            recommendations["estimated_benefit"] = {
                "query_improvement": "50-80% for date-range queries",
                "maintenance_improvement": "Faster deletes and archiving",
                "backup_improvement": "Partition-level backups possible",
            }

        return recommendations

    def _create_range_partitions(self, table: str, column: str, config: Dict) -> str:
        """Create RANGE partition SQL."""
        interval = config.get("interval", "MONTHLY")
        start_date = config.get("start_date", "2020-01-01")
        num_partitions = config.get("num_partitions", 24)

        # Generate partition definitions
        partitions = []
        current_date = datetime.strptime(start_date, "%Y-%m-%d")

        for _ in range(num_partitions):
            if interval == "MONTHLY":
                next_date = current_date + timedelta(days=30)
                partition_name = f"p{current_date.strftime('%Y%m')}"
            elif interval == "WEEKLY":
                next_date = current_date + timedelta(days=7)
                partition_name = f"p{current_date.strftime('%Y%U')}"
            elif interval == "QUARTERLY":
                next_date = current_date + timedelta(days=90)
                partition_name = f"p{current_date.year}q{(current_date.month-1)//3 + 1}"
            else:
                next_date = current_date + timedelta(days=365)
                partition_name = f"p{current_date.year}"

            partitions.append(
                f"PARTITION {partition_name} VALUES LESS THAN ('{next_date.strftime('%Y-%m-%d')}')"
            )
            current_date = next_date

        # Add future partition
        partitions.append("PARTITION p_future VALUES LESS THAN MAXVALUE")

        partition_sql = ",\n    ".join(partitions)

        return f"""
ALTER TABLE {table}
PARTITION BY RANGE (TO_DAYS({column}))
(
    {partition_sql}
)
        """

    def _create_list_partitions(self, table: str, column: str, config: Dict) -> str:
        """Create LIST partition SQL."""
        values_map = config["values_map"]

        partitions = []
        for partition_name, values in values_map.items():
            values_str = ", ".join(f"'{v}'" for v in values)
            partitions.append(f"PARTITION {partition_name} VALUES IN ({values_str})")

        partition_sql = ",\n    ".join(partitions)

        return f"""
ALTER TABLE {table}
PARTITION BY LIST ({column})
(
    {partition_sql}
)
        """

    def _create_hash_partitions(self, table: str, column: str, config: Dict) -> str:
        """Create HASH partition SQL."""
        num_partitions = config.get("num_partitions", 4)

        return f"""
ALTER TABLE {table}
PARTITION BY HASH({column})
PARTITIONS {num_partitions}
        """

    def _build_partition_definitions(self, config: Dict) -> str:
        """Build partition definitions for reorganization."""
        definitions = []

        for partition in config["partitions"]:
            if "values_less_than" in partition:
                definitions.append(
                    f"PARTITION {partition['name']} VALUES LESS THAN ({partition['values_less_than']})"
                )
            elif "values_in" in partition:
                values = ", ".join(f"'{v}'" for v in partition["values_in"])
                definitions.append(
                    f"PARTITION {partition['name']} VALUES IN ({values})"
                )

        return ",\n    ".join(definitions)


class PartitionAutomation:
    """Automated partition management with scheduling."""

    def __init__(self, config_file: str):
        """Initialize automation from config file."""
        self.config_file = Path(config_file)
        self.load_config()

    def load_config(self):
        """Load automation configuration."""
        with open(self.config_file, "r") as f:
            self.config = yaml.safe_load(f)

    def run_maintenance(self):
        """Run maintenance for all configured tables."""
        results = {}

        for db_config in self.config["databases"]:
            database = db_config["name"]
            connection_params = db_config["connection"]

            manager = PartitionManager(connection_params)

            for table_config in db_config["tables"]:
                table = table_config["name"]
                retention = table_config.get("retention_days", 365)
                future = table_config.get("future_partitions", 3)

                self.logger.info(f"Running maintenance for {database}.{table}")

                result = manager.auto_maintain_partitions(
                    database, table, retention, future
                )

                results[f"{database}.{table}"] = result

        return results

    def analyze_all_tables(self):
        """Analyze all configured tables for partition recommendations."""
        results = {}

        for db_config in self.config["databases"]:
            database = db_config["name"]
            connection_params = db_config["connection"]

            manager = PartitionManager(connection_params)

            for table_config in db_config["tables"]:
                table = table_config["name"]

                analysis = manager.analyze_table(database, table)
                results[f"{database}.{table}"] = analysis

        return results


def create_example_config():
    """Create example configuration file."""
    config = {
        "databases": [
            {
                "name": "iot_bins",
                "connection": {
                    "host": "localhost",
                    "port": 3309,
                    "user": "root",
                    "password": "iot_root",
                },
                "tables": [
                    {
                        "name": "sensor_readings",
                        "retention_days": 90,
                        "future_partitions": 3,
                        "partition_interval": "WEEKLY",
                    },
                    {
                        "name": "alerts",
                        "retention_days": 365,
                        "future_partitions": 2,
                        "partition_interval": "MONTHLY",
                    },
                ],
            },
            {
                "name": "smart_energy_db",
                "connection": {
                    "host": "localhost",
                    "port": 3310,
                    "user": "root",
                    "password": "energy_root",
                },
                "tables": [
                    {
                        "name": "meter_readings",
                        "retention_days": 730,
                        "future_partitions": 3,
                        "partition_interval": "MONTHLY",
                    }
                ],
            },
        ],
        "maintenance_schedule": {
            "enabled": True,
            "cron": "0 2 * * 1",  # Every Monday at 2 AM
            "notify_email": "admin@example.com",
        },
    }

    with open("partition_config.yml", "w") as f:
        yaml.dump(config, f, default_flow_style=False)

    print("Created example configuration: partition_config.yml")


if __name__ == "__main__":
    # Create example configuration
    create_example_config()

    # Example usage
    connection_params = {
        "host": "localhost",
        "port": 3309,
        "user": "root",
        "password": "iot_root",
    }

    manager = PartitionManager(connection_params)

    # Analyze a table
    analysis = manager.analyze_table("iot_bins", "sensor_readings")
    print(json.dumps(analysis, indent=2, default=str))
