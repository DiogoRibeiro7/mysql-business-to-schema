"""
Integration tests for database operations.
"""

import pytest
import mysql.connector
from pathlib import Path
import time
import json

@pytest.mark.integration
class TestSchemaCreation:
    """Test database schema creation and validation."""

    def test_create_clinic_schema(self, mysql_cursor, mysql_connection):
        """Test creating clinic database schema."""
        schema_path = Path(__file__).parent.parent.parent / "example_01_clinic" / "schema"

        # Execute schema files in order
        schema_files = [
            "01_tables.sql",
            "02_constraints.sql",
            "03_indexes.sql"
        ]

        for schema_file in schema_files:
            file_path = schema_path / schema_file
            if file_path.exists():
                with open(file_path, 'r') as f:
                    sql = f.read()

                # Split and execute statements
                statements = [s.strip() for s in sql.split(';') if s.strip()]
                for statement in statements:
                    try:
                        mysql_cursor.execute(statement)
                        mysql_connection.commit()
                    except mysql.connector.Error as e:
                        if "already exists" not in str(e):
                            raise

        # Verify tables were created
        mysql_cursor.execute("SHOW TABLES")
        tables = [table["Tables_in_" + mysql_connection.database] for table in mysql_cursor.fetchall()]

        expected_tables = ["patients", "doctors", "appointments", "medical_records"]
        for table in expected_tables:
            assert table in tables

    def test_create_iot_schema_with_partitions(self, mysql_cursor, mysql_connection):
        """Test creating IoT schema with partitions."""
        # Create partitioned table
        create_table_sql = """
        CREATE TABLE IF NOT EXISTS sensor_data (
            id BIGINT AUTO_INCREMENT,
            device_id VARCHAR(50) NOT NULL,
            timestamp TIMESTAMP NOT NULL,
            temperature DECIMAL(5,2),
            humidity DECIMAL(5,2),
            PRIMARY KEY (id, timestamp)
        ) PARTITION BY RANGE (UNIX_TIMESTAMP(timestamp)) (
            PARTITION p_2024_01 VALUES LESS THAN (UNIX_TIMESTAMP('2024-02-01')),
            PARTITION p_2024_02 VALUES LESS THAN (UNIX_TIMESTAMP('2024-03-01')),
            PARTITION p_2024_03 VALUES LESS THAN (UNIX_TIMESTAMP('2024-04-01')),
            PARTITION p_future VALUES LESS THAN MAXVALUE
        )
        """

        mysql_cursor.execute(create_table_sql)
        mysql_connection.commit()

        # Verify partitions
        mysql_cursor.execute("""
            SELECT PARTITION_NAME, PARTITION_EXPRESSION, PARTITION_DESCRIPTION
            FROM INFORMATION_SCHEMA.PARTITIONS
            WHERE TABLE_NAME = 'sensor_data'
            AND TABLE_SCHEMA = DATABASE()
        """)

        partitions = mysql_cursor.fetchall()
        assert len(partitions) > 0
        partition_names = [p["PARTITION_NAME"] for p in partitions]
        assert "p_2024_01" in partition_names
        assert "p_future" in partition_names

    def test_foreign_key_constraints(self, mysql_cursor, mysql_connection):
        """Test foreign key constraints are properly enforced."""
        # Create related tables
        mysql_cursor.execute("""
            CREATE TABLE IF NOT EXISTS test_users (
                id INT PRIMARY KEY AUTO_INCREMENT,
                username VARCHAR(50) NOT NULL
            )
        """)

        mysql_cursor.execute("""
            CREATE TABLE IF NOT EXISTS test_orders (
                id INT PRIMARY KEY AUTO_INCREMENT,
                user_id INT NOT NULL,
                total DECIMAL(10,2),
                FOREIGN KEY (user_id) REFERENCES test_users(id)
                    ON DELETE CASCADE ON UPDATE CASCADE
            )
        """)
        mysql_connection.commit()

        # Insert valid data
        mysql_cursor.execute("INSERT INTO test_users (username) VALUES ('testuser')")
        mysql_connection.commit()
        user_id = mysql_cursor.lastrowid

        mysql_cursor.execute(
            "INSERT INTO test_orders (user_id, total) VALUES (%s, %s)",
            (user_id, 99.99)
        )
        mysql_connection.commit()

        # Try to insert invalid foreign key
        with pytest.raises(mysql.connector.IntegrityError):
            mysql_cursor.execute(
                "INSERT INTO test_orders (user_id, total) VALUES (%s, %s)",
                (99999, 50.00)
            )
            mysql_connection.commit()

        # Test cascade delete
        mysql_cursor.execute(f"DELETE FROM test_users WHERE id = {user_id}")
        mysql_connection.commit()

        mysql_cursor.execute("SELECT COUNT(*) as count FROM test_orders WHERE user_id = %s", (user_id,))
        result = mysql_cursor.fetchone()
        assert result["count"] == 0

@pytest.mark.integration
class TestDataOperations:
    """Test data CRUD operations."""

    def test_batch_insert_performance(self, mysql_cursor, mysql_connection, performance_monitor):
        """Test batch insert performance."""
        # Create test table
        mysql_cursor.execute("""
            CREATE TABLE IF NOT EXISTS batch_test (
                id INT PRIMARY KEY AUTO_INCREMENT,
                data VARCHAR(255),
                value DECIMAL(10,2),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        mysql_connection.commit()

        # Generate test data
        batch_size = 1000
        values = [(f"data_{i}", i * 0.1) for i in range(batch_size)]

        performance_monitor.start()

        # Batch insert
        mysql_cursor.executemany(
            "INSERT INTO batch_test (data, value) VALUES (%s, %s)",
            values
        )
        mysql_connection.commit()

        metrics = performance_monitor.stop()

        # Verify all records inserted
        mysql_cursor.execute("SELECT COUNT(*) as count FROM batch_test")
        assert mysql_cursor.fetchone()["count"] == batch_size

        # Check performance
        assert metrics["duration"] < 5.0  # Should complete within 5 seconds
        print(f"Batch insert of {batch_size} records took {metrics['duration']:.2f} seconds")

    def test_concurrent_writes(self, mysql_container):
        """Test concurrent write operations."""
        import threading
        import queue

        results = queue.Queue()

        def write_data(thread_id):
            try:
                conn = mysql.connector.connect(
                    host=mysql_container["host"],
                    port=mysql_container["port"],
                    user=mysql_container["user"],
                    password=mysql_container["password"],
                    database=mysql_container["database"]
                )
                cursor = conn.cursor()

                # Create table if not exists
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS concurrent_test (
                        id INT PRIMARY KEY AUTO_INCREMENT,
                        thread_id INT,
                        data VARCHAR(255)
                    )
                """)

                # Write data
                for i in range(10):
                    cursor.execute(
                        "INSERT INTO concurrent_test (thread_id, data) VALUES (%s, %s)",
                        (thread_id, f"thread_{thread_id}_data_{i}")
                    )

                conn.commit()
                cursor.close()
                conn.close()
                results.put((thread_id, "success"))
            except Exception as e:
                results.put((thread_id, f"error: {e}"))

        # Start concurrent threads
        threads = []
        for i in range(5):
            t = threading.Thread(target=write_data, args=(i,))
            t.start()
            threads.append(t)

        # Wait for completion
        for t in threads:
            t.join()

        # Check results
        while not results.empty():
            thread_id, status = results.get()
            assert status == "success", f"Thread {thread_id} failed: {status}"

    def test_transaction_rollback(self, mysql_cursor, mysql_connection):
        """Test transaction rollback functionality."""
        # Create test table
        mysql_cursor.execute("""
            CREATE TABLE IF NOT EXISTS transaction_test (
                id INT PRIMARY KEY AUTO_INCREMENT,
                value INT NOT NULL
            )
        """)
        mysql_connection.commit()

        try:
            # Start transaction
            mysql_connection.start_transaction()

            # Insert some data
            mysql_cursor.execute("INSERT INTO transaction_test (value) VALUES (100)")
            mysql_cursor.execute("INSERT INTO transaction_test (value) VALUES (200)")

            # Force an error
            mysql_cursor.execute("INSERT INTO transaction_test (value) VALUES ('invalid')")

            mysql_connection.commit()
        except mysql.connector.Error:
            mysql_connection.rollback()

        # Verify rollback worked
        mysql_cursor.execute("SELECT COUNT(*) as count FROM transaction_test")
        assert mysql_cursor.fetchone()["count"] == 0

@pytest.mark.integration
class TestQueryOptimization:
    """Test query optimization and indexing."""

    def test_index_usage(self, mysql_cursor, mysql_connection):
        """Test that queries use indexes properly."""
        # Create table with indexes
        mysql_cursor.execute("""
            CREATE TABLE IF NOT EXISTS index_test (
                id INT PRIMARY KEY AUTO_INCREMENT,
                user_id INT NOT NULL,
                status VARCHAR(20) NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_user_id (user_id),
                INDEX idx_status (status),
                INDEX idx_created_at (created_at)
            )
        """)
        mysql_connection.commit()

        # Insert test data
        for i in range(1000):
            mysql_cursor.execute(
                "INSERT INTO index_test (user_id, status) VALUES (%s, %s)",
                (i % 100, "active" if i % 2 == 0 else "inactive")
            )
        mysql_connection.commit()

        # Check query execution plan
        mysql_cursor.execute("EXPLAIN SELECT * FROM index_test WHERE user_id = 50")
        explain = mysql_cursor.fetchall()

        # Verify index is being used
        assert any("idx_user_id" in str(row) for row in explain)

    def test_query_cache_performance(self, mysql_cursor, mysql_connection):
        """Test query cache effectiveness."""
        # Create and populate table
        mysql_cursor.execute("""
            CREATE TABLE IF NOT EXISTS cache_test (
                id INT PRIMARY KEY AUTO_INCREMENT,
                data TEXT
            )
        """)

        # Insert test data
        for i in range(100):
            mysql_cursor.execute(
                "INSERT INTO cache_test (data) VALUES (%s)",
                (f"data_{i}" * 100,)
            )
        mysql_connection.commit()

        # First query (cold cache)
        start = time.time()
        mysql_cursor.execute("SELECT * FROM cache_test WHERE id BETWEEN 1 AND 50")
        mysql_cursor.fetchall()
        first_query_time = time.time() - start

        # Second query (warm cache)
        start = time.time()
        mysql_cursor.execute("SELECT * FROM cache_test WHERE id BETWEEN 1 AND 50")
        mysql_cursor.fetchall()
        second_query_time = time.time() - start

        # Cache should make second query faster (or at least not slower)
        assert second_query_time <= first_query_time * 1.1

    def test_slow_query_detection(self, mysql_cursor, mysql_connection):
        """Test slow query detection."""
        # Create large table
        mysql_cursor.execute("""
            CREATE TABLE IF NOT EXISTS slow_query_test (
                id INT PRIMARY KEY AUTO_INCREMENT,
                data VARCHAR(255),
                value DECIMAL(10,2)
            )
        """)

        # Insert substantial data
        values = [(f"data_{i}", i * 0.1) for i in range(5000)]
        mysql_cursor.executemany(
            "INSERT INTO slow_query_test (data, value) VALUES (%s, %s)",
            values
        )
        mysql_connection.commit()

        # Execute potentially slow query
        start = time.time()
        mysql_cursor.execute("""
            SELECT t1.*, t2.value as value2
            FROM slow_query_test t1
            CROSS JOIN slow_query_test t2
            WHERE t1.data LIKE '%1%'
            LIMIT 100
        """)
        mysql_cursor.fetchall()
        query_time = time.time() - start

        # Log slow queries
        if query_time > 1.0:
            print(f"Slow query detected: {query_time:.2f} seconds")

@pytest.mark.integration
class TestReplication:
    """Test database replication scenarios."""

    @pytest.mark.skip(reason="Requires multiple MySQL instances")
    def test_master_slave_replication(self):
        """Test master-slave replication setup."""
        # This would require setting up multiple MySQL containers
        # Skipped in basic tests but important for production
        pass

    def test_read_write_splitting(self, mysql_cursor, mysql_connection):
        """Test read/write query splitting logic."""
        # Simulate read/write splitting logic
        queries = [
            ("SELECT * FROM users", "read"),
            ("INSERT INTO users VALUES (1, 'test')", "write"),
            ("UPDATE users SET name = 'new'", "write"),
            ("SELECT COUNT(*) FROM orders", "read"),
            ("DELETE FROM old_records", "write")
        ]

        read_queries = []
        write_queries = []

        for query, expected_type in queries:
            query_upper = query.strip().upper()
            if query_upper.startswith(("SELECT", "SHOW", "DESC", "EXPLAIN")):
                read_queries.append(query)
                assert expected_type == "read"
            else:
                write_queries.append(query)
                assert expected_type == "write"

        # Verify splitting worked correctly
        assert len(read_queries) == 2
        assert len(write_queries) == 3

@pytest.mark.integration
class TestBackupRestore:
    """Test backup and restore operations."""

    def test_backup_creation(self, mysql_cursor, mysql_connection, tmp_path):
        """Test database backup creation."""
        import subprocess

        # Create test data
        mysql_cursor.execute("""
            CREATE TABLE IF NOT EXISTS backup_test (
                id INT PRIMARY KEY,
                data VARCHAR(255)
            )
        """)

        mysql_cursor.execute("INSERT INTO backup_test VALUES (1, 'test_data')")
        mysql_connection.commit()

        # Create backup
        backup_file = tmp_path / "backup.sql"
        cmd = [
            "mysqldump",
            f"-h{mysql_connection.server_host}",
            f"-u{mysql_connection.user}",
            f"-p{mysql_connection._password}",
            mysql_connection.database,
            "backup_test"
        ]

        try:
            with open(backup_file, 'w') as f:
                result = subprocess.run(cmd, stdout=f, stderr=subprocess.PIPE)
                if result.returncode != 0:
                    print(f"Backup failed: {result.stderr}")
        except FileNotFoundError:
            pytest.skip("mysqldump not available")

        # Verify backup file created
        if backup_file.exists():
            assert backup_file.stat().st_size > 0

    def test_point_in_time_recovery(self, mysql_cursor, mysql_connection):
        """Test point-in-time recovery simulation."""
        # Create table with timestamp
        mysql_cursor.execute("""
            CREATE TABLE IF NOT EXISTS pitr_test (
                id INT PRIMARY KEY AUTO_INCREMENT,
                data VARCHAR(255),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)

        # Insert data at different times
        for i in range(5):
            mysql_cursor.execute(
                "INSERT INTO pitr_test (data) VALUES (%s)",
                (f"data_{i}",)
            )
            mysql_connection.commit()
            time.sleep(0.1)

        # Get timestamp for recovery point
        mysql_cursor.execute("SELECT created_at FROM pitr_test WHERE id = 3")
        recovery_point = mysql_cursor.fetchone()["created_at"]

        # Simulate recovery to point in time
        mysql_cursor.execute(
            "SELECT * FROM pitr_test WHERE created_at <= %s",
            (recovery_point,)
        )
        recovered_data = mysql_cursor.fetchall()

        # Should have 3 records
        assert len(recovered_data) == 3