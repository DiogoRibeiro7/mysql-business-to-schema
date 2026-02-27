#!/usr/bin/env python3
"""
Data Verification Script for MySQL Business-to-Schema
Checks and reports on generated data across all schemas
"""

import os
import sys
import mysql.connector
from datetime import datetime
from typing import Dict, List, Tuple
from colorama import init, Fore, Style
import pandas as pd
from tabulate import tabulate

# Initialize colorama
init()

# Database configuration
DB_CONFIG = {
    "host": os.getenv("MYSQL_HOST", "localhost"),
    "user": os.getenv("MYSQL_USER", "root"),
    "password": os.getenv("MYSQL_PASSWORD", "root"),
    "port": int(os.getenv("MYSQL_PORT", 3306)),
}


def print_header(text: str):
    """Print formatted header"""
    print(f"\n{Fore.CYAN}{'='*70}{Style.RESET_ALL}")
    print(f"{Fore.CYAN}{text:^70}{Style.RESET_ALL}")
    print(f"{Fore.CYAN}{'='*70}{Style.RESET_ALL}\n")


def get_schema_stats(conn: mysql.connector.MySQLConnection, schema: str) -> Dict:
    """Get statistics for a schema"""
    cursor = conn.cursor(dictionary=True)
    stats = {"schema": schema}

    try:
        # Get table count and total rows
        cursor.execute(
            f"""
            SELECT
                COUNT(DISTINCT table_name) as table_count,
                SUM(table_rows) as total_rows,
                ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) as size_mb
            FROM information_schema.tables
            WHERE table_schema = '{schema}'
        """
        )
        result = cursor.fetchone()
        stats.update(result if result else {})

        # Get detailed table information
        cursor.execute(
            f"""
            SELECT
                table_name,
                table_rows,
                ROUND((data_length + index_length) / 1024 / 1024, 2) as size_mb,
                (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = t.table_schema AND table_name = t.table_name) as column_count
            FROM information_schema.tables t
            WHERE table_schema = '{schema}'
            ORDER BY table_rows DESC
            LIMIT 10
        """
        )
        stats["tables"] = cursor.fetchall()

        # Get foreign key relationships
        cursor.execute(
            f"""
            SELECT COUNT(*) as fk_count
            FROM information_schema.key_column_usage
            WHERE table_schema = '{schema}'
            AND referenced_table_name IS NOT NULL
        """
        )
        result = cursor.fetchone()
        stats["fk_count"] = result["fk_count"] if result else 0

        # Get index count
        cursor.execute(
            f"""
            SELECT COUNT(DISTINCT index_name) as index_count
            FROM information_schema.statistics
            WHERE table_schema = '{schema}'
            AND index_name != 'PRIMARY'
        """
        )
        result = cursor.fetchone()
        stats["index_count"] = result["index_count"] if result else 0

    except Exception as e:
        print(f"{Fore.RED}Error getting stats for {schema}: {e}{Style.RESET_ALL}")

    cursor.close()
    return stats


def verify_data_quality(conn: mysql.connector.MySQLConnection, schema: str) -> Dict:
    """Check data quality metrics"""
    cursor = conn.cursor()
    quality_report = {"nulls": 0, "duplicates": 0, "orphans": 0, "issues": []}

    try:
        # Switch to schema
        cursor.execute(f"USE {schema}")

        # Get all tables
        cursor.execute("SHOW TABLES")
        tables = [table[0] for table in cursor.fetchall()]

        for table in tables[:5]:  # Check first 5 tables for performance
            # Check for excessive nulls
            cursor.execute(f"SELECT COUNT(*) FROM `{table}`")
            total_rows = cursor.fetchone()[0]

            if total_rows > 0:
                # Get column names
                cursor.execute(f"SHOW COLUMNS FROM `{table}`")
                columns = [col[0] for col in cursor.fetchall()]

                for column in columns[:3]:  # Check first 3 columns
                    try:
                        cursor.execute(
                            f"SELECT COUNT(*) FROM `{table}` WHERE `{column}` IS NULL"
                        )
                        null_count = cursor.fetchone()[0]
                        null_percentage = (null_count / total_rows) * 100

                        if null_percentage > 50:
                            quality_report["issues"].append(
                                f"{table}.{column} has {null_percentage:.1f}% NULL values"
                            )
                            quality_report["nulls"] += 1
                    except:
                        pass

    except Exception as e:
        quality_report["issues"].append(f"Error checking quality: {str(e)}")

    cursor.close()
    return quality_report


def print_summary_table(stats_list: List[Dict]):
    """Print summary statistics in a table"""
    if not stats_list:
        return

    # Prepare data for tabulate
    table_data = []
    for stat in stats_list:
        table_data.append(
            [
                stat.get("schema", "Unknown"),
                stat.get("table_count", 0),
                f"{stat.get('total_rows', 0):,}",
                f"{stat.get('size_mb', 0):.2f} MB",
                stat.get("fk_count", 0),
                stat.get("index_count", 0),
            ]
        )

    headers = ["Schema", "Tables", "Total Rows", "Size", "FKs", "Indexes"]

    print(f"\n{Fore.CYAN}Schema Statistics Summary:{Style.RESET_ALL}")
    print(tabulate(table_data, headers=headers, tablefmt="grid"))


def print_top_tables(stats_list: List[Dict]):
    """Print top tables by row count"""
    print(f"\n{Fore.CYAN}Top Tables by Row Count:{Style.RESET_ALL}")

    all_tables = []
    for stat in stats_list:
        if "tables" in stat:
            for table in stat["tables"]:
                all_tables.append(
                    {
                        "schema": stat["schema"],
                        "table": table["table_name"],
                        "rows": table["table_rows"],
                        "columns": table["column_count"],
                        "size_mb": table["size_mb"],
                    }
                )

    # Sort by row count and get top 10
    all_tables.sort(key=lambda x: x["rows"] if x["rows"] else 0, reverse=True)
    top_tables = all_tables[:10]

    if top_tables:
        table_data = []
        for table in top_tables:
            table_data.append(
                [
                    f"{table['schema']}.{table['table']}",
                    f"{table['rows']:,}" if table["rows"] else "0",
                    table["columns"],
                    f"{table['size_mb']:.2f} MB",
                ]
            )

        headers = ["Table", "Rows", "Columns", "Size"]
        print(tabulate(table_data, headers=headers, tablefmt="grid"))


def generate_sample_queries(stats_list: List[Dict]):
    """Generate sample queries for testing"""
    print(f"\n{Fore.CYAN}Sample Queries for Testing:{Style.RESET_ALL}")

    queries = []

    # Healthcare queries
    if any(s["schema"] == "clinic_db" for s in stats_list):
        queries.append(
            (
                "Patient Statistics (clinic_db)",
                """
SELECT
    COUNT(*) as total_patients,
    AVG(YEAR(CURDATE()) - YEAR(date_of_birth)) as avg_age,
    COUNT(CASE WHEN gender = 'M' THEN 1 END) as male_count,
    COUNT(CASE WHEN gender = 'F' THEN 1 END) as female_count
FROM clinic_db.patients;""",
            )
        )

    # E-commerce queries
    if any(s["schema"] == "ecommerce_db" for s in stats_list):
        queries.append(
            (
                "Order Analytics (ecommerce_db)",
                """
SELECT
    DATE(order_date) as date,
    COUNT(*) as order_count,
    SUM(total_amount) as revenue
FROM ecommerce_db.orders
WHERE order_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY DATE(order_date);""",
            )
        )

    # IoT queries
    if any(s["schema"] == "iot_bins_db" for s in stats_list):
        queries.append(
            (
                "Sensor Readings (iot_bins_db)",
                """
SELECT
    sensor_type,
    COUNT(*) as reading_count,
    AVG(value) as avg_value,
    MAX(value) as max_value
FROM iot_bins_db.sensor_readings
WHERE timestamp >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
GROUP BY sensor_type;""",
            )
        )

    # Print queries
    for title, query in queries[:5]:
        print(f"\n{Fore.GREEN}{title}:{Style.RESET_ALL}")
        print(f"{Fore.YELLOW}{query}{Style.RESET_ALL}")


def main():
    """Main execution function"""
    print_header("MySQL Business-to-Schema Data Verification")
    print(f"Started: {datetime.now()}")

    try:
        # Connect to MySQL
        conn = mysql.connector.connect(**DB_CONFIG)
        cursor = conn.cursor()

        # Get all schemas
        cursor.execute("SHOW DATABASES")
        all_schemas = [db[0] for db in cursor.fetchall()]
        business_schemas = [s for s in all_schemas if s.endswith("_db")]

        print(f"\nFound {len(business_schemas)} business schemas")

        # Collect statistics
        stats_list = []
        quality_reports = []

        for schema in business_schemas:
            print(f"\n{Fore.BLUE}Analyzing {schema}...{Style.RESET_ALL}")

            # Get statistics
            stats = get_schema_stats(conn, schema)
            stats_list.append(stats)

            # Check data quality
            quality = verify_data_quality(conn, schema)
            quality_reports.append({"schema": schema, "quality": quality})

            # Print schema details
            if stats.get("total_rows", 0) > 0:
                print(
                    f"  {Fore.GREEN}✓{Style.RESET_ALL} {stats.get('table_count', 0)} tables, "
                    f"{stats.get('total_rows', 0):,} rows, "
                    f"{stats.get('size_mb', 0):.2f} MB"
                )
            else:
                print(f"  {Fore.YELLOW}○{Style.RESET_ALL} No data found")

        # Print summary tables
        print_summary_table(stats_list)
        print_top_tables(stats_list)

        # Print data quality report
        print(f"\n{Fore.CYAN}Data Quality Report:{Style.RESET_ALL}")
        issues_found = False
        for report in quality_reports:
            if report["quality"]["issues"]:
                issues_found = True
                print(f"\n{Fore.YELLOW}{report['schema']}:{Style.RESET_ALL}")
                for issue in report["quality"]["issues"][:3]:
                    print(f"  - {issue}")

        if not issues_found:
            print(f"{Fore.GREEN}✓ No major data quality issues found{Style.RESET_ALL}")

        # Generate sample queries
        generate_sample_queries(stats_list)

        # Calculate totals
        total_schemas = len(business_schemas)
        total_tables = sum(s.get("table_count", 0) for s in stats_list)
        total_rows = sum(s.get("total_rows", 0) for s in stats_list)
        total_size = sum(s.get("size_mb", 0) for s in stats_list)

        # Print final summary
        print_header("Verification Summary")
        print(f"{Fore.GREEN}✓ Schemas verified: {total_schemas}{Style.RESET_ALL}")
        print(f"{Fore.GREEN}✓ Total tables: {total_tables}{Style.RESET_ALL}")
        print(f"{Fore.GREEN}✓ Total rows: {total_rows:,}{Style.RESET_ALL}")
        print(f"{Fore.GREEN}✓ Total size: {total_size:.2f} MB{Style.RESET_ALL}")

        conn.close()

        # Success message
        print(f"\n{Fore.GREEN}{'='*70}{Style.RESET_ALL}")
        print(f"{Fore.GREEN}{'Data Verification Complete!':^70}{Style.RESET_ALL}")
        print(f"{Fore.GREEN}{'='*70}{Style.RESET_ALL}\n")

    except mysql.connector.Error as e:
        print(f"\n{Fore.RED}Database Error: {e}{Style.RESET_ALL}")
        sys.exit(1)
    except Exception as e:
        print(f"\n{Fore.RED}Unexpected Error: {e}{Style.RESET_ALL}")
        sys.exit(1)


if __name__ == "__main__":
    main()
