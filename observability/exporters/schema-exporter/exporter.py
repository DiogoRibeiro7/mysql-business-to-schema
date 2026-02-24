#!/usr/bin/env python3
"""
MySQL Business-to-Schema Custom Prometheus Exporter

Provides business-specific metrics for each schema example.
"""

import os
import time
import logging
from typing import Dict, List, Any
import mysql.connector
from prometheus_client import start_http_server, Gauge, Counter, Histogram, Info
from prometheus_client.core import GaugeMetricFamily, CounterMetricFamily, REGISTRY
from prometheus_client import CollectorRegistry

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configuration
MYSQL_HOST = os.getenv('MYSQL_HOST', 'localhost')
MYSQL_PORT = int(os.getenv('MYSQL_PORT', 3306))
MYSQL_USER = os.getenv('MYSQL_USER', 'root')
MYSQL_PASSWORD = os.getenv('MYSQL_PASSWORD', 'root')
EXPORT_PORT = int(os.getenv('EXPORT_PORT', 9105))

# Define metrics
SCHEMA_METRICS = {
    # Schema-level metrics
    'table_count': Gauge(
        'mysql_schema_table_count',
        'Number of tables in database',
        ['database']
    ),
    'total_size_bytes': Gauge(
        'mysql_schema_total_size_bytes',
        'Total size of database in bytes',
        ['database']
    ),
    'index_count': Gauge(
        'mysql_schema_index_count',
        'Number of indexes in database',
        ['database']
    ),
    'migration_version': Gauge(
        'mysql_schema_migration_version',
        'Current migration version',
        ['database']
    ),

    # Table-level metrics
    'table_rows': Gauge(
        'mysql_schema_table_rows',
        'Number of rows in table',
        ['database', 'table']
    ),
    'table_size_bytes': Gauge(
        'mysql_schema_table_size_bytes',
        'Size of table in bytes',
        ['database', 'table']
    ),
    'table_fragmentation': Gauge(
        'mysql_schema_table_fragmentation_ratio',
        'Table fragmentation ratio',
        ['database', 'table']
    ),

    # Business metrics for specific schemas
    'clinic_patients': Gauge(
        'mysql_schema_clinic_patients_total',
        'Total number of patients',
        ['database']
    ),
    'clinic_appointments': Gauge(
        'mysql_schema_clinic_appointments_today',
        'Number of appointments today',
        ['database']
    ),
    'ecommerce_orders': Gauge(
        'mysql_schema_ecommerce_orders_total',
        'Total number of orders',
        ['database']
    ),
    'ecommerce_revenue': Gauge(
        'mysql_schema_ecommerce_revenue_total',
        'Total revenue',
        ['database']
    ),
    'iot_devices': Gauge(
        'mysql_schema_iot_devices_active',
        'Number of active IoT devices',
        ['database']
    ),
    'iot_readings': Counter(
        'mysql_schema_iot_readings_total',
        'Total number of IoT readings',
        ['database']
    ),
    'social_users': Gauge(
        'mysql_schema_social_users_active',
        'Number of active users',
        ['database']
    ),
    'social_posts': Gauge(
        'mysql_schema_social_posts_today',
        'Number of posts today',
        ['database']
    ),
}


class SchemaMetricsCollector:
    """Collects MySQL schema-specific metrics."""

    def __init__(self):
        self.connection = None
        self.connect()

    def connect(self):
        """Establish MySQL connection."""
        try:
            self.connection = mysql.connector.connect(
                host=MYSQL_HOST,
                port=MYSQL_PORT,
                user=MYSQL_USER,
                password=MYSQL_PASSWORD,
                autocommit=True
            )
            logger.info(f"Connected to MySQL at {MYSQL_HOST}:{MYSQL_PORT}")
        except Exception as e:
            logger.error(f"Failed to connect to MySQL: {e}")
            raise

    def execute_query(self, query: str, database: str = None) -> List[Dict]:
        """Execute a MySQL query."""
        if not self.connection or not self.connection.is_connected():
            self.connect()

        cursor = self.connection.cursor(dictionary=True)
        try:
            if database:
                cursor.execute(f"USE {database}")
            cursor.execute(query)
            return cursor.fetchall()
        finally:
            cursor.close()

    def collect_schema_metrics(self):
        """Collect schema-level metrics."""
        # Get all databases
        databases = self.execute_query("SHOW DATABASES")

        for db in databases:
            db_name = db['Database']

            # Skip system databases
            if db_name in ['information_schema', 'mysql', 'performance_schema', 'sys']:
                continue

            try:
                # Table count
                tables = self.execute_query(f"SHOW TABLES", database=db_name)
                SCHEMA_METRICS['table_count'].labels(database=db_name).set(len(tables))

                # Database size
                size_query = """
                    SELECT
                        SUM(data_length + index_length) as size_bytes
                    FROM information_schema.TABLES
                    WHERE table_schema = %s
                """
                cursor = self.connection.cursor()
                cursor.execute(size_query, (db_name,))
                size = cursor.fetchone()[0] or 0
                SCHEMA_METRICS['total_size_bytes'].labels(database=db_name).set(size)
                cursor.close()

                # Collect table-level metrics
                self.collect_table_metrics(db_name)

                # Collect business-specific metrics
                self.collect_business_metrics(db_name)

            except Exception as e:
                logger.error(f"Error collecting metrics for database {db_name}: {e}")

    def collect_table_metrics(self, database: str):
        """Collect table-level metrics."""
        query = """
            SELECT
                table_name,
                table_rows,
                data_length + index_length as size_bytes,
                data_free / (data_length + index_length + 0.001) as fragmentation
            FROM information_schema.TABLES
            WHERE table_schema = %s
        """

        cursor = self.connection.cursor(dictionary=True)
        cursor.execute(query, (database,))
        tables = cursor.fetchall()
        cursor.close()

        for table in tables:
            SCHEMA_METRICS['table_rows'].labels(
                database=database,
                table=table['table_name']
            ).set(table['table_rows'] or 0)

            SCHEMA_METRICS['table_size_bytes'].labels(
                database=database,
                table=table['table_name']
            ).set(table['size_bytes'] or 0)

            SCHEMA_METRICS['table_fragmentation'].labels(
                database=database,
                table=table['table_name']
            ).set(table['fragmentation'] or 0)

    def collect_business_metrics(self, database: str):
        """Collect business-specific metrics based on schema type."""

        # Clinic schema metrics
        if 'clinic' in database.lower():
            try:
                # Patient count
                result = self.execute_query("SELECT COUNT(*) as count FROM patients", database)
                if result:
                    SCHEMA_METRICS['clinic_patients'].labels(database=database).set(result[0]['count'])

                # Today's appointments
                result = self.execute_query(
                    "SELECT COUNT(*) as count FROM appointments WHERE DATE(appointment_date) = CURDATE()",
                    database
                )
                if result:
                    SCHEMA_METRICS['clinic_appointments'].labels(database=database).set(result[0]['count'])
            except:
                pass

        # E-commerce schema metrics
        elif 'ecommerce' in database.lower() or 'shop' in database.lower():
            try:
                # Order count
                result = self.execute_query("SELECT COUNT(*) as count FROM orders", database)
                if result:
                    SCHEMA_METRICS['ecommerce_orders'].labels(database=database).set(result[0]['count'])

                # Total revenue
                result = self.execute_query("SELECT SUM(total_amount) as revenue FROM orders", database)
                if result and result[0]['revenue']:
                    SCHEMA_METRICS['ecommerce_revenue'].labels(database=database).set(result[0]['revenue'])
            except:
                pass

        # IoT schema metrics
        elif 'iot' in database.lower() or 'sensor' in database.lower():
            try:
                # Active devices
                result = self.execute_query(
                    "SELECT COUNT(*) as count FROM devices WHERE status = 'active'",
                    database
                )
                if result:
                    SCHEMA_METRICS['iot_devices'].labels(database=database).set(result[0]['count'])

                # Reading count
                result = self.execute_query("SELECT COUNT(*) as count FROM readings", database)
                if result:
                    SCHEMA_METRICS['iot_readings'].labels(database=database).inc(result[0]['count'])
            except:
                pass

        # Social media schema metrics
        elif 'social' in database.lower():
            try:
                # Active users
                result = self.execute_query(
                    "SELECT COUNT(*) as count FROM users WHERE last_login > DATE_SUB(NOW(), INTERVAL 30 DAY)",
                    database
                )
                if result:
                    SCHEMA_METRICS['social_users'].labels(database=database).set(result[0]['count'])

                # Today's posts
                result = self.execute_query(
                    "SELECT COUNT(*) as count FROM posts WHERE DATE(created_at) = CURDATE()",
                    database
                )
                if result:
                    SCHEMA_METRICS['social_posts'].labels(database=database).set(result[0]['count'])
            except:
                pass

    def run(self):
        """Main loop to collect metrics."""
        while True:
            try:
                self.collect_schema_metrics()
                logger.info("Metrics collected successfully")
            except Exception as e:
                logger.error(f"Error collecting metrics: {e}")
                # Try to reconnect
                try:
                    self.connect()
                except:
                    pass

            # Sleep for 30 seconds
            time.sleep(30)


def main():
    """Main entry point."""
    logger.info(f"Starting MySQL Schema Exporter on port {EXPORT_PORT}")

    # Start Prometheus metrics server
    start_http_server(EXPORT_PORT)
    logger.info(f"Metrics server started on port {EXPORT_PORT}")

    # Start collector
    collector = SchemaMetricsCollector()
    collector.run()


if __name__ == '__main__':
    main()