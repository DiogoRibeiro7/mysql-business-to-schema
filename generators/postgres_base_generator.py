#!/usr/bin/env python3
"""PostgreSQL Data Generator Base Class.

Base class for PostgreSQL-specific data generation with support for:
- JSONB data types
- Arrays
- Advanced indexing
- Partitioning
- Full-text search
"""

import os
import psycopg2
from psycopg2.extras import execute_batch, Json
from datetime import datetime
import random
from typing import Dict, List, Any, Optional, Tuple
from faker import Faker
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


class PostgreSQLGenerator:
    """Base class for PostgreSQL data generation."""

    def __init__(self, config: Optional[Dict[str, Any]] = None):
        """Initialize PostgreSQL generator."""
        self.config = config or self._get_default_config()
        self.fake = Faker()
        Faker.seed(42)  # For reproducibility
        random.seed(42)

        # Database connection
        self.connection: Optional[Any] = None
        self.cursor: Optional[Any] = None

        # Statistics
        self.stats: Dict[str, Any] = {
            "tables_created": 0,
            "records_inserted": {},
            "errors": [],
            "start_time": None,
            "end_time": None,
        }

    def _get_default_config(self) -> Dict[str, Any]:
        """Get default configuration from environment."""
        return {
            "host": os.getenv("POSTGRES_HOST", "localhost"),
            "port": int(os.getenv("POSTGRES_PORT", 5432)),
            "database": os.getenv("POSTGRES_DATABASE", "test_db"),
            "user": os.getenv("POSTGRES_USER", "postgres"),
            "password": os.getenv("POSTGRES_PASSWORD", "postgres"),
            "batch_size": int(os.getenv("BATCH_SIZE", 1000)),
            "generator_mode": os.getenv("GENERATOR_MODE", "test"),
        }

    def connect(self) -> bool:
        """Establish PostgreSQL connection."""
        try:
            self.connection = psycopg2.connect(
                host=self.config["host"],
                port=self.config["port"],
                database=self.config["database"],
                user=self.config["user"],
                password=self.config["password"],
            )
            self.cursor = self.connection.cursor()
            logger.info(
                f"Connected to PostgreSQL: {self.config['database']}@{self.config['host']}"
            )
            return True
        except Exception as e:
            logger.error(f"Connection failed: {e}")
            self.stats["errors"].append(str(e))
            return False

    def disconnect(self):
        """Close database connection."""
        if self.cursor:
            self.cursor.close()
        if self.connection:
            self.connection.close()
        logger.info("Disconnected from PostgreSQL")

    def execute_query(
        self, query: str, params: Optional[Tuple[Any, ...]] = None
    ) -> bool:
        """Execute a single query."""
        if self.cursor is None or self.connection is None:
            raise RuntimeError("Not connected to PostgreSQL")
        try:
            self.cursor.execute(query, params)
            self.connection.commit()
            return True
        except Exception as e:
            logger.error(f"Query execution failed: {e}")
            logger.error(f"Query: {query[:200]}...")
            self.connection.rollback()
            self.stats["errors"].append(str(e))
            return False

    def batch_insert(
        self, table: str, columns: List[str], data: List[Tuple[Any, ...]]
    ) -> int:
        """Batch insert data using PostgreSQL's execute_batch."""
        if not data:
            return 0

        if self.cursor is None or self.connection is None:
            raise RuntimeError("Not connected to PostgreSQL")

        try:
            placeholders = ",".join(["%s"] * len(columns))
            query = f"INSERT INTO {table} ({','.join(columns)}) VALUES ({placeholders})"

            # Use execute_batch for better performance
            execute_batch(self.cursor, query, data, page_size=self.config["batch_size"])
            self.connection.commit()

            count = len(data)
            self.stats["records_inserted"][table] = (
                self.stats["records_inserted"].get(table, 0) + count
            )
            logger.info(f"Inserted {count} records into {table}")
            return count

        except Exception as e:
            logger.error(f"Batch insert failed for {table}: {e}")
            self.connection.rollback()
            self.stats["errors"].append(str(e))
            return 0

    def copy_from_csv(
        self, table: str, csv_file: str, columns: Optional[List[str]] = None
    ) -> bool:
        """Use COPY command for ultra-fast data loading."""
        if self.cursor is None or self.connection is None:
            raise RuntimeError("Not connected to PostgreSQL")
        try:
            with open(csv_file, "r") as f:
                if columns:
                    columns_str = f"({','.join(columns)})"
                else:
                    columns_str = ""

                self.cursor.copy_expert(
                    f"COPY {table}{columns_str} FROM STDIN WITH CSV HEADER", f
                )
                self.connection.commit()
                logger.info(f"Loaded data from {csv_file} into {table}")
                return True

        except Exception as e:
            logger.error(f"COPY failed for {table}: {e}")
            self.connection.rollback()
            return False

    # PostgreSQL-specific data generators

    def generate_jsonb(self, schema: Optional[Dict[str, Any]] = None) -> Json:
        """Generate JSONB data."""
        if schema:
            data = {}
            for key, value_type in schema.items():
                if value_type == "string":
                    data[key] = self.fake.word()
                elif value_type == "number":
                    data[key] = random.randint(1, 100)
                elif value_type == "boolean":
                    data[key] = random.choice([True, False])
                elif value_type == "array":
                    data[key] = [self.fake.word() for _ in range(random.randint(1, 5))]
                elif value_type == "object":
                    data[key] = {"nested": self.fake.word()}
        else:
            # Generate random JSON structure
            data = {
                "id": self.fake.uuid4(),
                "name": self.fake.name(),
                "metadata": {
                    "created_at": datetime.now().isoformat(),
                    "tags": [self.fake.word() for _ in range(3)],
                    "score": random.random(),
                },
            }

        return Json(data)

    def generate_array(
        self, element_type: str, min_size: int = 1, max_size: int = 10
    ) -> List[Any]:
        """Generate PostgreSQL array data."""
        size = random.randint(min_size, max_size)

        if element_type == "integer":
            return [random.randint(1, 1000) for _ in range(size)]
        elif element_type == "text":
            return [self.fake.word() for _ in range(size)]
        elif element_type == "uuid":
            return [self.fake.uuid4() for _ in range(size)]
        elif element_type == "date":
            return [self.fake.date() for _ in range(size)]
        else:
            return []

    def generate_tsvector(self, text: Optional[str] = None) -> str:
        """Generate tsvector for full-text search."""
        if not text:
            text = self.fake.text()
        # In actual insertion, use to_tsvector() function
        return str(text)

    def generate_point(self) -> Tuple[float, float]:
        """Generate geometric point data."""
        lat = self.fake.latitude()
        lon = self.fake.longitude()
        return (float(lat), float(lon))

    def generate_uuid(self) -> str:
        """Generate UUID."""
        return self.fake.uuid4()

    def generate_inet(self) -> str:
        """Generate INET address."""
        return self.fake.ipv4()

    def generate_cidr(self) -> str:
        """Generate CIDR network."""
        return f"{self.fake.ipv4()}/24"

    def generate_macaddr(self) -> str:
        """Generate MAC address."""
        return self.fake.mac_address()

    # Table creation helpers

    def create_partitioned_table(
        self, table_name: str, partition_column: str, partition_type: str = "RANGE"
    ) -> bool:
        """Create a partitioned table."""
        # This is a template - actual implementation depends on schema
        query = f"""
        CREATE TABLE IF NOT EXISTS {table_name} (
            id SERIAL,
            {partition_column} DATE NOT NULL,
            data JSONB,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (id, {partition_column})
        ) PARTITION BY {partition_type} ({partition_column});
        """
        return self.execute_query(query)

    def create_partition(
        self, parent_table: str, partition_name: str, start_value: str, end_value: str
    ) -> bool:
        """Create a partition for a partitioned table."""
        query = f"""
        CREATE TABLE IF NOT EXISTS {partition_name}
        PARTITION OF {parent_table}
        FOR VALUES FROM ('{start_value}') TO ('{end_value}');
        """
        return self.execute_query(query)

    def create_gin_index(
        self, table: str, column: str, index_name: Optional[str] = None
    ) -> bool:
        """Create GIN index for JSONB or array columns."""
        if not index_name:
            index_name = f"idx_{table}_{column}_gin"

        query = (
            f"CREATE INDEX IF NOT EXISTS {index_name} ON {table} USING GIN ({column});"
        )
        return self.execute_query(query)

    def create_gist_index(
        self, table: str, column: str, index_name: Optional[str] = None
    ) -> bool:
        """Create GiST index for geometric or full-text search."""
        if not index_name:
            index_name = f"idx_{table}_{column}_gist"

        query = (
            f"CREATE INDEX IF NOT EXISTS {index_name} ON {table} USING GIST ({column});"
        )
        return self.execute_query(query)

    def create_brin_index(
        self, table: str, column: str, index_name: Optional[str] = None
    ) -> bool:
        """Create BRIN index for large tables with natural ordering."""
        if not index_name:
            index_name = f"idx_{table}_{column}_brin"

        query = (
            f"CREATE INDEX IF NOT EXISTS {index_name} ON {table} USING BRIN ({column});"
        )
        return self.execute_query(query)

    # Utility methods

    def vacuum_analyze(self, table: Optional[str] = None):
        """Run VACUUM ANALYZE for query optimization."""
        if self.connection is None or self.cursor is None:
            raise RuntimeError("Not connected to PostgreSQL")
        old_isolation = self.connection.isolation_level
        self.connection.set_isolation_level(0)  # AUTOCOMMIT

        try:
            if table:
                self.cursor.execute(f"VACUUM ANALYZE {table};")
                logger.info(f"Ran VACUUM ANALYZE on {table}")
            else:
                self.cursor.execute("VACUUM ANALYZE;")
                logger.info("Ran VACUUM ANALYZE on entire database")
        finally:
            self.connection.set_isolation_level(old_isolation)

    def get_table_size(self, table: str) -> Dict[str, Any]:
        """Get table size information."""
        if self.cursor is None:
            raise RuntimeError("Not connected to PostgreSQL")
        query = """
        SELECT
            pg_size_pretty(pg_total_relation_size(%s)) as total_size,
            pg_size_pretty(pg_relation_size(%s)) as table_size,
            pg_size_pretty(pg_indexes_size(%s)) as indexes_size
        """
        self.cursor.execute(query, (table, table, table))
        result = self.cursor.fetchone()

        if result:
            return {
                "total_size": result[0],
                "table_size": result[1],
                "indexes_size": result[2],
            }
        return {}

    def enable_extension(self, extension: str) -> bool:
        """Enable a PostgreSQL extension."""
        if self.cursor is None or self.connection is None:
            raise RuntimeError("Not connected to PostgreSQL")
        try:
            self.cursor.execute(f"CREATE EXTENSION IF NOT EXISTS {extension};")
            self.connection.commit()
            logger.info(f"Enabled extension: {extension}")
            return True
        except Exception as e:
            logger.error(f"Failed to enable extension {extension}: {e}")
            self.connection.rollback()
            return False

    def run(self):
        """Run generation process - to be implemented by subclasses."""
        raise NotImplementedError("Subclasses must implement the run() method")

    def print_statistics(self):
        """Print generation statistics."""
        print("\n" + "=" * 60)
        print("PostgreSQL Data Generation Statistics")
        print("=" * 60)

        if self.stats["start_time"] and self.stats["end_time"]:
            duration = (
                self.stats["end_time"] - self.stats["start_time"]
            ).total_seconds()
            print(f"Duration: {duration:.2f} seconds")

        print("\nRecords Inserted:")
        total_records = 0
        for table, count in self.stats["records_inserted"].items():
            print(f"  {table}: {count:,}")
            total_records += count
        print(f"  Total: {total_records:,}")

        if self.stats["errors"]:
            print(f"\nErrors ({len(self.stats['errors'])}):")
            for error in self.stats["errors"][:5]:  # Show first 5 errors
                print(f"  - {error[:100]}")

        print("=" * 60)


class PostgreSQLTestGenerator(PostgreSQLGenerator):
    """Test generator with small datasets for PostgreSQL."""

    def run(self):
        """Run test data generation."""
        self.stats["start_time"] = datetime.now()

        if not self.connect():
            return False

        try:
            # Enable useful extensions
            self.enable_extension("uuid-ossp")
            self.enable_extension("pg_trgm")  # For similarity searches

            # Generate test data
            self._generate_test_data()

            # Run optimization
            self.vacuum_analyze()

        finally:
            self.disconnect()

        self.stats["end_time"] = datetime.now()
        self.print_statistics()

        return len(self.stats["errors"]) == 0

    def _generate_test_data(self):
        """Generate small test dataset."""
        # Example: Create a test table with various PostgreSQL types
        create_table = """
        CREATE TABLE IF NOT EXISTS test_records (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            name TEXT NOT NULL,
            metadata JSONB,
            tags TEXT[],
            location POINT,
            ip_address INET,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            search_vector TSVECTOR
        );
        """
        self.execute_query(create_table)

        # Generate test records
        records = []
        for _ in range(100):
            record = (
                self.generate_uuid(),
                self.fake.name(),
                self.generate_jsonb(),
                self.generate_array("text", 1, 5),
                self.generate_point(),
                self.generate_inet(),
                datetime.now(),
                self.generate_tsvector(),
            )
            records.append(record)

        # Insert records
        columns = [
            "id",
            "name",
            "metadata",
            "tags",
            "location",
            "ip_address",
            "created_at",
            "search_vector",
        ]
        self.batch_insert("test_records", columns, records)

        # Create indexes
        self.create_gin_index("test_records", "metadata")
        self.create_gin_index("test_records", "tags")
        self.create_gist_index("test_records", "search_vector")


if __name__ == "__main__":
    generator = PostgreSQLTestGenerator()
    generator.run()
