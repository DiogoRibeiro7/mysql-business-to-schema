"""
Load and performance tests using Locust and custom benchmarking.
"""

import pytest
import time
import statistics
import concurrent.futures
import mysql.connector
from locust import HttpUser, task, between, events
from locust.env import Environment
from locust.stats import StatsCSVFileWriter
import psutil
import json
from pathlib import Path

@pytest.mark.performance
class TestDatabasePerformance:
    """Test database performance under load."""

    def test_bulk_insert_performance(self, mysql_connection, mysql_cursor):
        """Test bulk insert performance with varying batch sizes."""
        # Create test table
        mysql_cursor.execute("""
            CREATE TABLE IF NOT EXISTS perf_test (
                id INT PRIMARY KEY AUTO_INCREMENT,
                data VARCHAR(255),
                value DECIMAL(10,2),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        mysql_connection.commit()

        batch_sizes = [100, 500, 1000, 5000, 10000]
        results = {}

        for batch_size in batch_sizes:
            # Generate test data
            data = [(f"data_{i}", i * 0.1) for i in range(batch_size)]

            # Measure insert time
            start = time.time()
            mysql_cursor.executemany(
                "INSERT INTO perf_test (data, value) VALUES (%s, %s)",
                data
            )
            mysql_connection.commit()
            elapsed = time.time() - start

            records_per_second = batch_size / elapsed
            results[batch_size] = {
                "time": elapsed,
                "records_per_second": records_per_second
            }

            # Clean up for next test
            mysql_cursor.execute("TRUNCATE TABLE perf_test")
            mysql_connection.commit()

        # Verify performance meets thresholds
        for batch_size, metrics in results.items():
            print(f"Batch size {batch_size}: {metrics['records_per_second']:.0f} records/sec")
            assert metrics['records_per_second'] > 100  # Minimum 100 records/sec

    def test_concurrent_read_performance(self, mysql_container):
        """Test concurrent read performance."""
        def read_worker(thread_id, num_queries):
            conn = mysql.connector.connect(
                host=mysql_container["host"],
                port=mysql_container["port"],
                user=mysql_container["user"],
                password=mysql_container["password"],
                database=mysql_container["database"]
            )
            cursor = conn.cursor()

            query_times = []
            for i in range(num_queries):
                start = time.time()
                cursor.execute("""
                    SELECT COUNT(*) FROM information_schema.columns
                    WHERE table_schema = DATABASE()
                """)
                cursor.fetchall()
                query_times.append(time.time() - start)

            cursor.close()
            conn.close()
            return query_times

        # Run concurrent readers
        num_threads = 10
        queries_per_thread = 50

        with concurrent.futures.ThreadPoolExecutor(max_workers=num_threads) as executor:
            start = time.time()
            futures = [
                executor.submit(read_worker, i, queries_per_thread)
                for i in range(num_threads)
            ]
            all_times = []
            for future in concurrent.futures.as_completed(futures):
                all_times.extend(future.result())
            total_time = time.time() - start

        # Calculate metrics
        avg_query_time = statistics.mean(all_times)
        p95_query_time = statistics.quantiles(all_times, n=20)[18]  # 95th percentile
        queries_per_second = (num_threads * queries_per_thread) / total_time

        print(f"Concurrent reads: {queries_per_second:.0f} queries/sec")
        print(f"Average query time: {avg_query_time*1000:.2f}ms")
        print(f"P95 query time: {p95_query_time*1000:.2f}ms")

        # Performance assertions
        assert queries_per_second > 100
        assert avg_query_time < 0.1  # Less than 100ms
        assert p95_query_time < 0.2  # P95 less than 200ms

    def test_index_impact_on_performance(self, mysql_connection, mysql_cursor):
        """Test performance impact of indexes."""
        # Create table without index
        mysql_cursor.execute("""
            CREATE TABLE IF NOT EXISTS no_index_test (
                id INT PRIMARY KEY AUTO_INCREMENT,
                user_id INT,
                status VARCHAR(20),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)

        # Create table with index
        mysql_cursor.execute("""
            CREATE TABLE IF NOT EXISTS with_index_test (
                id INT PRIMARY KEY AUTO_INCREMENT,
                user_id INT,
                status VARCHAR(20),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_user_status (user_id, status)
            )
        """)
        mysql_connection.commit()

        # Insert test data
        test_data = [(i % 1000, "active" if i % 2 == 0 else "inactive")
                     for i in range(10000)]

        mysql_cursor.executemany(
            "INSERT INTO no_index_test (user_id, status) VALUES (%s, %s)",
            test_data
        )
        mysql_cursor.executemany(
            "INSERT INTO with_index_test (user_id, status) VALUES (%s, %s)",
            test_data
        )
        mysql_connection.commit()

        # Test query performance without index
        start = time.time()
        mysql_cursor.execute("""
            SELECT COUNT(*) FROM no_index_test
            WHERE user_id = 500 AND status = 'active'
        """)
        mysql_cursor.fetchall()
        no_index_time = time.time() - start

        # Test query performance with index
        start = time.time()
        mysql_cursor.execute("""
            SELECT COUNT(*) FROM with_index_test
            WHERE user_id = 500 AND status = 'active'
        """)
        mysql_cursor.fetchall()
        with_index_time = time.time() - start

        print(f"Query without index: {no_index_time*1000:.2f}ms")
        print(f"Query with index: {with_index_time*1000:.2f}ms")
        print(f"Performance improvement: {(no_index_time/with_index_time):.1f}x")

        # Index should provide significant performance improvement
        assert with_index_time < no_index_time

    def test_memory_usage_under_load(self, mysql_connection, mysql_cursor):
        """Test memory usage under heavy load."""
        process = psutil.Process()
        initial_memory = process.memory_info().rss / 1024 / 1024  # MB

        # Create large result set
        mysql_cursor.execute("""
            CREATE TABLE IF NOT EXISTS memory_test (
                id INT PRIMARY KEY AUTO_INCREMENT,
                large_text TEXT
            )
        """)

        # Insert large data
        large_text = "x" * 10000  # 10KB per row
        for i in range(100):
            mysql_cursor.execute(
                "INSERT INTO memory_test (large_text) VALUES (%s)",
                (large_text,)
            )
        mysql_connection.commit()

        # Query large dataset
        mysql_cursor.execute("SELECT * FROM memory_test")
        results = mysql_cursor.fetchall()

        peak_memory = process.memory_info().rss / 1024 / 1024  # MB
        memory_increase = peak_memory - initial_memory

        print(f"Memory increase: {memory_increase:.1f}MB")

        # Memory usage should be reasonable
        assert memory_increase < 500  # Less than 500MB increase

        # Clean up
        mysql_cursor.execute("DROP TABLE memory_test")
        mysql_connection.commit()


class WebDemoUser(HttpUser):
    """Locust user for load testing web demo."""
    wait_time = between(1, 3)

    @task(3)
    def view_homepage(self):
        """View the homepage."""
        self.client.get("/")

    @task(2)
    def view_schemas(self):
        """View available schemas."""
        self.client.get("/api/v1/schemas")

    @task(5)
    def execute_query(self):
        """Execute a simple query."""
        self.client.post(
            "/api/v1/query",
            json={
                "query": "SELECT 1",
                "database": "test_db"
            },
            headers={"Authorization": "Bearer test-token"}
        )

    @task(1)
    def complex_query(self):
        """Execute a complex query."""
        self.client.post(
            "/api/v1/query",
            json={
                "query": """
                SELECT p.*, COUNT(a.id) as appointment_count
                FROM patients p
                LEFT JOIN appointments a ON p.id = a.patient_id
                GROUP BY p.id
                LIMIT 10
                """,
                "database": "clinic_db"
            },
            headers={"Authorization": "Bearer test-token"}
        )

    @task(2)
    def graphql_query(self):
        """Execute GraphQL query."""
        self.client.post(
            "/graphql",
            json={
                "query": """
                {
                    patients(limit: 10) {
                        id
                        firstName
                        lastName
                    }
                }
                """
            }
        )


@pytest.mark.performance
class TestLoadTesting:
    """Load testing with Locust."""

    def test_load_test_api(self, test_config):
        """Run load test against API."""
        # Setup Locust environment
        env = Environment(user_classes=[WebDemoUser])
        env.create_local_runner()

        # Configure load test
        env.runner.start(
            user_count=10,
            spawn_rate=2,
            wait=False
        )

        # Run for 30 seconds
        time.sleep(30)
        env.runner.stop()

        # Get statistics
        stats = env.stats.total

        print(f"\nLoad Test Results:")
        print(f"Total requests: {stats.num_requests}")
        print(f"Failure rate: {stats.fail_ratio:.1%}")
        print(f"Average response time: {stats.avg_response_time:.0f}ms")
        print(f"P95 response time: {stats.get_response_time_percentile(0.95):.0f}ms")
        print(f"Requests per second: {stats.current_rps:.1f}")

        # Assert performance criteria
        assert stats.fail_ratio < 0.01  # Less than 1% failure rate
        assert stats.avg_response_time < 500  # Average under 500ms
        assert stats.get_response_time_percentile(0.95) < 1000  # P95 under 1 second

    def test_spike_test(self, test_config):
        """Test system behavior under sudden load spike."""
        env = Environment(user_classes=[WebDemoUser])
        env.create_local_runner()

        # Start with low load
        env.runner.start(user_count=5, spawn_rate=1, wait=False)
        time.sleep(10)

        # Sudden spike
        env.runner.start(user_count=50, spawn_rate=10, wait=False)
        time.sleep(20)

        # Return to normal
        env.runner.start(user_count=5, spawn_rate=1, wait=False)
        time.sleep(10)

        env.runner.stop()

        # System should handle spike without crashing
        stats = env.stats.total
        assert stats.fail_ratio < 0.05  # Less than 5% failure during spike

    def test_sustained_load(self, test_config):
        """Test system under sustained load."""
        env = Environment(user_classes=[WebDemoUser])
        env.create_local_runner()

        # Sustained load for 2 minutes
        env.runner.start(user_count=20, spawn_rate=2, wait=False)

        # Collect metrics every 10 seconds
        response_times = []
        error_rates = []

        for i in range(12):  # 2 minutes / 10 seconds
            time.sleep(10)
            stats = env.stats.total
            response_times.append(stats.avg_response_time)
            error_rates.append(stats.fail_ratio)

        env.runner.stop()

        # Check for performance degradation
        initial_response_time = statistics.mean(response_times[:3])
        final_response_time = statistics.mean(response_times[-3:])

        degradation = (final_response_time - initial_response_time) / initial_response_time

        print(f"Performance degradation: {degradation:.1%}")

        # Performance should not degrade significantly
        assert degradation < 0.5  # Less than 50% degradation


@pytest.mark.performance
class TestQueryOptimization:
    """Test query optimization and performance."""

    def test_slow_query_identification(self, mysql_cursor, mysql_connection):
        """Identify and log slow queries."""
        # Enable slow query log
        mysql_cursor.execute("SET GLOBAL slow_query_log = 'ON'")
        mysql_cursor.execute("SET GLOBAL long_query_time = 0.1")  # 100ms

        slow_queries = []

        # Run various queries
        queries = [
            "SELECT SLEEP(0.2)",  # Intentionally slow
            "SELECT COUNT(*) FROM information_schema.columns",
            """
            SELECT t1.table_name, t2.column_name
            FROM information_schema.tables t1
            CROSS JOIN information_schema.columns t2
            LIMIT 1000
            """,
        ]

        for query in queries:
            start = time.time()
            try:
                mysql_cursor.execute(query)
                mysql_cursor.fetchall()
            except:
                pass
            elapsed = time.time() - start

            if elapsed > 0.1:
                slow_queries.append({
                    "query": query[:100],
                    "time": elapsed
                })

        # Log slow queries
        if slow_queries:
            print("\nSlow queries detected:")
            for sq in slow_queries:
                print(f"  Query: {sq['query']}")
                print(f"  Time: {sq['time']*1000:.0f}ms\n")

    def test_query_plan_analysis(self, mysql_cursor, mysql_connection):
        """Analyze query execution plans."""
        # Create test table with data
        mysql_cursor.execute("""
            CREATE TABLE IF NOT EXISTS plan_test (
                id INT PRIMARY KEY AUTO_INCREMENT,
                category VARCHAR(50),
                status VARCHAR(20),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_category (category),
                INDEX idx_status_created (status, created_at)
            )
        """)

        # Insert test data
        categories = ["electronics", "clothing", "books", "food", "toys"]
        statuses = ["pending", "active", "completed"]

        for i in range(1000):
            mysql_cursor.execute(
                "INSERT INTO plan_test (category, status) VALUES (%s, %s)",
                (categories[i % 5], statuses[i % 3])
            )
        mysql_connection.commit()

        # Analyze different query patterns
        queries = [
            ("Good: Using index",
             "SELECT * FROM plan_test WHERE category = 'electronics'"),
            ("Good: Using covering index",
             "SELECT status, created_at FROM plan_test WHERE status = 'active'"),
            ("Bad: Full table scan",
             "SELECT * FROM plan_test WHERE DATE(created_at) = CURDATE()"),
            ("Bad: No index on expression",
             "SELECT * FROM plan_test WHERE UPPER(category) = 'ELECTRONICS'")
        ]

        for description, query in queries:
            mysql_cursor.execute(f"EXPLAIN {query}")
            plan = mysql_cursor.fetchall()

            print(f"\n{description}:")
            print(f"  Query: {query[:80]}")
            for row in plan:
                print(f"  Type: {row.get('type', 'N/A')}, "
                      f"Key: {row.get('key', 'N/A')}, "
                      f"Rows: {row.get('rows', 'N/A')}")

    def test_connection_pool_performance(self, mysql_container):
        """Test connection pool vs individual connections."""
        num_operations = 100

        # Test without connection pooling
        start = time.time()
        for i in range(num_operations):
            conn = mysql.connector.connect(
                host=mysql_container["host"],
                port=mysql_container["port"],
                user=mysql_container["user"],
                password=mysql_container["password"],
                database=mysql_container["database"]
            )
            cursor = conn.cursor()
            cursor.execute("SELECT 1")
            cursor.fetchall()
            cursor.close()
            conn.close()
        no_pool_time = time.time() - start

        # Test with connection pooling
        from mysql.connector import pooling
        pool = pooling.MySQLConnectionPool(
            pool_name="test_pool",
            pool_size=5,
            host=mysql_container["host"],
            port=mysql_container["port"],
            user=mysql_container["user"],
            password=mysql_container["password"],
            database=mysql_container["database"]
        )

        start = time.time()
        for i in range(num_operations):
            conn = pool.get_connection()
            cursor = conn.cursor()
            cursor.execute("SELECT 1")
            cursor.fetchall()
            cursor.close()
            conn.close()
        pool_time = time.time() - start

        improvement = (no_pool_time - pool_time) / no_pool_time * 100

        print(f"\nConnection Pool Performance:")
        print(f"  Without pool: {no_pool_time:.2f}s")
        print(f"  With pool: {pool_time:.2f}s")
        print(f"  Improvement: {improvement:.1f}%")

        # Pool should be faster
        assert pool_time < no_pool_time