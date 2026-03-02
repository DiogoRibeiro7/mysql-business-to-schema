#!/usr/bin/env python3
"""
Base Generator Class for MySQL Data Generation

Provides common functionality for all data generators including:
- Database connection management
- Bulk insert operations
- Faker data generation
- Common utility methods
"""

import mysql.connector
from mysql.connector import Error
from faker import Faker
import random
import hashlib
from datetime import datetime, timedelta, date
from decimal import Decimal
from typing import List, Dict, Any, Optional, Tuple


class BaseGenerator:
    """Base class for all data generators"""

    def __init__(
        self,
        host="localhost",
        port=3306,
        user="root",
        password="password",
        database="test_db",
    ):
        """Initialize the base generator with database connection parameters"""
        self.host = host
        self.port = port
        self.user = user
        self.password = password
        self.database = database
        self.connection = None
        self.cursor = None
        self.faker = Faker()

        # Seed for reproducibility
        random.seed(42)
        Faker.seed(42)

    def connect(self):
        """Establish database connection"""
        try:
            self.connection = mysql.connector.connect(
                host=self.host,
                port=self.port,
                user=self.user,
                password=self.password,
                database=self.database,
                use_unicode=True,
                charset="utf8mb4",
                collation="utf8mb4_unicode_ci",
                autocommit=False,
            )
            self.cursor = self.connection.cursor(dictionary=True)
            print(f"Successfully connected to database: {self.database}")

            # Set session variables for better performance
            self.cursor.execute("SET FOREIGN_KEY_CHECKS = 0")
            self.cursor.execute("SET UNIQUE_CHECKS = 0")
            self.cursor.execute("SET AUTOCOMMIT = 0")

        except Error as e:
            print(f"Error connecting to database: {e}")
            raise

    def disconnect(self):
        """Close database connection"""
        try:
            if self.connection and self.connection.is_connected():
                # Re-enable checks before disconnecting
                self.cursor.execute("SET FOREIGN_KEY_CHECKS = 1")
                self.cursor.execute("SET UNIQUE_CHECKS = 1")
                self.cursor.execute("SET AUTOCOMMIT = 1")
                self.connection.commit()

                self.cursor.close()
                self.connection.close()
                print("Database connection closed.")
        except Error as e:
            print(f"Error closing connection: {e}")

    def execute_query(self, query: str, params: Optional[Tuple] = None):
        """Execute a single query"""
        try:
            if params:
                self.cursor.execute(query, params)
            else:
                self.cursor.execute(query)
            self.connection.commit()
        except Error as e:
            print(f"Error executing query: {e}")
            print(f"Query: {query}")
            self.connection.rollback()
            raise

    def bulk_insert(
        self, table: str, data: List[Tuple], columns: List[str], batch_size: int = 1000
    ):
        """Perform bulk insert with batching"""
        if not data:
            return

        placeholders = ", ".join(["%s"] * len(columns))
        columns_str = ", ".join([f"`{col}`" for col in columns])
        query = f"INSERT INTO `{table}` ({columns_str}) VALUES ({placeholders})"

        try:
            # Insert in batches
            for i in range(0, len(data), batch_size):
                batch = data[i : i + batch_size]
                self.cursor.executemany(query, batch)
                self.connection.commit()

                if len(data) > batch_size:
                    print(
                        f"  Inserted batch {i//batch_size + 1} ({len(batch)} records) into {table}"
                    )

        except Error as e:
            print(f"Error in bulk insert to {table}: {e}")
            print(f"Query: {query}")
            print(f"Sample data: {data[0] if data else 'No data'}")
            self.connection.rollback()
            raise

    def fetch_all(self, query: str, params: Optional[Tuple] = None) -> List[Dict]:
        """Fetch all results from a query"""
        try:
            if params:
                self.cursor.execute(query, params)
            else:
                self.cursor.execute(query)
            return self.cursor.fetchall()
        except Error as e:
            print(f"Error fetching data: {e}")
            print(f"Query: {query}")
            raise

    def fetch_one(self, query: str, params: Optional[Tuple] = None) -> Optional[Dict]:
        """Fetch single result from a query"""
        try:
            if params:
                self.cursor.execute(query, params)
            else:
                self.cursor.execute(query)
            return self.cursor.fetchone()
        except Error as e:
            print(f"Error fetching data: {e}")
            print(f"Query: {query}")
            raise

    def truncate_table(self, table: str):
        """Truncate a table (delete all data)"""
        try:
            self.cursor.execute(f"TRUNCATE TABLE `{table}`")
            self.connection.commit()
            print(f"Truncated table: {table}")
        except Error as e:
            print(f"Error truncating table {table}: {e}")
            raise

    def truncate_all_tables(self):
        """Truncate all tables in the database"""
        try:
            # Get all tables
            self.cursor.execute(
                """
                SELECT table_name
                FROM information_schema.tables
                WHERE table_schema = %s
                AND table_type = 'BASE TABLE'
            """,
                (self.database,),
            )

            tables = [row["table_name"] for row in self.cursor.fetchall()]

            # Disable foreign key checks
            self.cursor.execute("SET FOREIGN_KEY_CHECKS = 0")

            # Truncate each table
            for table in tables:
                self.truncate_table(table)

            # Re-enable foreign key checks
            self.cursor.execute("SET FOREIGN_KEY_CHECKS = 1")
            self.connection.commit()

        except Error as e:
            print(f"Error truncating all tables: {e}")
            raise

    def generate_password_hash(self, password: Optional[str] = None) -> str:
        """Generate a password hash"""
        if not password:
            password = self.faker.password()
        return hashlib.sha256(password.encode()).hexdigest()

    def random_datetime_between(
        self, start_date: datetime, end_date: datetime
    ) -> datetime:
        """Generate random datetime between two dates"""
        time_delta = end_date - start_date
        random_days = random.randint(0, time_delta.days)
        random_seconds = random.randint(0, 86400)
        return start_date + timedelta(days=random_days, seconds=random_seconds)

    def random_date_between(self, start_date: str, end_date: str) -> date:
        """Generate random date between two date strings"""
        start = datetime.strptime(start_date, "%Y-%m-%d")
        end = datetime.strptime(end_date, "%Y-%m-%d")
        return self.random_datetime_between(start, end).date()

    def get_table_count(self, table: str) -> int:
        """Get the count of records in a table"""
        try:
            self.cursor.execute(f"SELECT COUNT(*) as count FROM `{table}`")
            result = self.cursor.fetchone()
            return result["count"] if result else 0
        except Error as e:
            print(f"Error counting records in {table}: {e}")
            return 0

    def print_statistics(self):
        """Print statistics for all tables"""
        try:
            # Get all tables
            self.cursor.execute(
                """
                SELECT table_name
                FROM information_schema.tables
                WHERE table_schema = %s
                AND table_type = 'BASE TABLE'
                ORDER BY table_name
            """,
                (self.database,),
            )

            tables = [row["table_name"] for row in self.cursor.fetchall()]

            print("\n" + "=" * 60)
            print(f"Database Statistics for: {self.database}")
            print("=" * 60)

            total_records = 0
            for table in tables:
                count = self.get_table_count(table)
                total_records += count
                if count > 0:
                    print(f"{table:30} : {count:,} records")

            print("-" * 60)
            print(f"{'Total':30} : {total_records:,} records")
            print("=" * 60 + "\n")

        except Error as e:
            print(f"Error getting statistics: {e}")
