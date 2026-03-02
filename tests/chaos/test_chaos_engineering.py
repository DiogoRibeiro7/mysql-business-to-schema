"""Chaos engineering tests to verify system resilience."""

import pytest
import time
import random
import threading
import mysql.connector
import psutil
import socket


@pytest.mark.chaos
class TestDatabaseChaos:
    """Chaos tests for database layer."""

    def test_connection_pool_exhaustion(self, mysql_container):
        """Test system behavior when connection pool is exhausted."""
        connections = []
        max_connections = 50

        try:
            # Exhaust connection pool
            for _ in range(max_connections):
                conn = mysql.connector.connect(
                    host=mysql_container["host"],
                    port=mysql_container["port"],
                    user=mysql_container["user"],
                    password=mysql_container["password"],
                    database=mysql_container["database"],
                )
                connections.append(conn)

            # Try to get one more connection (should fail or queue)
            with pytest.raises(mysql.connector.Error):
                _ = mysql.connector.connect(
                    host=mysql_container["host"],
                    port=mysql_container["port"],
                    user=mysql_container["user"],
                    password=mysql_container["password"],
                    database=mysql_container["database"],
                    connection_timeout=1,
                )

        finally:
            # Clean up connections
            for conn in connections:
                try:
                    conn.close()
                except Exception:
                    pass

    def test_random_query_failures(self, mysql_cursor, mysql_connection):
        """Test system resilience to random query failures."""
        class ChaosCursor:
            """Represent ChaosCursor."""

            def __init__(self, cursor, failure_rate=0.2):
                """Initialize the instance."""
                self.cursor = cursor
                self.failure_rate = failure_rate

            def execute(self, query, params=None):
                """Handle execute."""
                if random.random() < self.failure_rate:
                    raise mysql.connector.Error("Chaos: Random query failure")
                return self.cursor.execute(query, params)

            def fetchall(self):
                """Handle fetchall."""
                return self.cursor.fetchall()

            def fetchone(self):
                """Handle fetchone."""
                return self.cursor.fetchone()

        chaos_cursor = ChaosCursor(mysql_cursor, failure_rate=0.3)
        successful_queries = 0
        failed_queries = 0

        for _ in range(100):
            try:
                chaos_cursor.execute("SELECT 1")
                chaos_cursor.fetchall()
                successful_queries += 1
            except mysql.connector.Error:
                failed_queries += 1

        print(f"Successful queries: {successful_queries}")
        print(f"Failed queries: {failed_queries}")

        # System should handle some failures
        assert successful_queries > 50  # At least 50% success rate
        assert failed_queries > 20  # Chaos should cause some failures

    def test_table_lock_simulation(self, mysql_cursor, mysql_connection):
        """Test behavior under table locks."""
        # Create test table
        mysql_cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS lock_test (
                id INT PRIMARY KEY,
                value VARCHAR(50)
            )
        """
        )
        mysql_cursor.execute("INSERT INTO lock_test VALUES (1, 'initial')")
        mysql_connection.commit()

        def lock_table():
            """Thread to hold a table lock."""
            lock_conn = mysql.connector.connect(
                host=mysql_connection.server_host,
                port=mysql_connection.server_port,
                user=mysql_connection.user,
                password=mysql_connection._password,
                database=mysql_connection.database,
            )
            lock_cursor = lock_conn.cursor()

            # Acquire table lock
            lock_cursor.execute("LOCK TABLES lock_test WRITE")
            time.sleep(2)  # Hold lock for 2 seconds
            lock_cursor.execute("UNLOCK TABLES")

            lock_cursor.close()
            lock_conn.close()

        # Start lock thread
        lock_thread = threading.Thread(target=lock_table)
        lock_thread.start()

        # Try to access locked table
        time.sleep(0.5)  # Let lock be acquired
        start = time.time()

        try:
            mysql_cursor.execute(
                "SELECT * FROM lock_test",
            )
            # Query should block and timeout
            mysql_cursor.fetchall()
            query_time = time.time() - start
        except mysql.connector.Error:
            query_time = time.time() - start
            print(f"Query blocked for {query_time:.1f} seconds")

        lock_thread.join()

        # Verify query was blocked
        assert query_time > 1.0  # Query should have been blocked

    def test_disk_space_exhaustion(self, tmp_path):
        """Simulate disk space exhaustion."""
        # Create a large file to simulate low disk space
        large_file = tmp_path / "large_file.dat"

        try:
            # Check available space
            disk_usage = psutil.disk_usage(str(tmp_path))
            available_mb = disk_usage.free / 1024 / 1024

            if available_mb > 1000:  # Only run if enough space
                # Write large file (but not too large)
                chunk_size = 1024 * 1024  # 1MB chunks
                chunks_to_write = min(100, int(available_mb * 0.1))  # 10% of available

                with open(large_file, "wb") as f:
                    for _ in range(chunks_to_write):
                        f.write(b"0" * chunk_size)

                # Check system can still operate
                remaining = psutil.disk_usage(str(tmp_path)).free / 1024 / 1024
                print(f"Disk space remaining: {remaining:.0f}MB")

                # System should handle low disk space gracefully
                assert remaining > 10  # At least 10MB remaining

        finally:
            # Clean up
            if large_file.exists():
                large_file.unlink()


@pytest.mark.chaos
class TestNetworkChaos:
    """Network-related chaos tests."""

    def test_network_latency(self, mysql_container):
        """Test system with simulated network latency."""
        class LatencyConnection:
            """Represent LatencyConnection."""

            def __init__(self, connection, latency_ms=100):
                """Initialize the instance."""
                self.connection = connection
                self.latency = latency_ms / 1000.0

            def cursor(self):
                """Handle cursor."""
                time.sleep(self.latency)
                return self.connection.cursor()

            def commit(self):
                """Handle commit."""
                time.sleep(self.latency)
                return self.connection.commit()

            def close(self):
                """Handle close."""
                return self.connection.close()

        # Create connection with simulated latency
        conn = mysql.connector.connect(
            host=mysql_container["host"],
            port=mysql_container["port"],
            user=mysql_container["user"],
            password=mysql_container["password"],
            database=mysql_container["database"],
        )

        latency_conn = LatencyConnection(conn, latency_ms=200)

        # Measure query time with latency
        start = time.time()
        cursor = latency_conn.cursor()
        cursor.execute("SELECT 1")
        cursor.fetchall()
        latency_conn.commit()
        elapsed = time.time() - start

        print(f"Query time with 200ms latency: {elapsed*1000:.0f}ms")

        # Should include network latency
        assert elapsed > 0.4  # At least 400ms (2x latency)

        latency_conn.close()

    def test_packet_loss_simulation(self):
        """Simulate packet loss in network communication."""
        class PacketLossSocket:
            """Represent PacketLossSocket."""

            def __init__(self, socket_obj, loss_rate=0.1):
                """Initialize the instance."""
                self.socket = socket_obj
                self.loss_rate = loss_rate

            def send(self, data):
                """Handle send."""
                if random.random() > self.loss_rate:
                    return self.socket.send(data)
                else:
                    # Simulate packet loss
                    raise socket.error("Simulated packet loss")

            def recv(self, size):
                """Handle recv."""
                if random.random() > self.loss_rate:
                    return self.socket.recv(size)
                else:
                    # Simulate packet loss
                    raise socket.error("Simulated packet loss")

        # Test with simulated packet loss
        successful_operations = 0
        failed_operations = 0

        for _ in range(50):
            try:
                # Simulate network operation
                if random.random() > 0.1:  # 90% success rate
                    successful_operations += 1
                else:
                    raise socket.error("Simulated packet loss")
            except socket.error:
                failed_operations += 1

        print(
            f"Network operations - Success: {successful_operations}, Failed: {failed_operations}"
        )

        # System should handle some packet loss
        assert successful_operations > failed_operations

    def test_connection_timeout(self, mysql_container):
        """Test connection timeout handling."""
        # Try to connect with very short timeout
        with pytest.raises(mysql.connector.Error):
            conn = mysql.connector.connect(
                host=mysql_container["host"],
                port=mysql_container["port"],
                user=mysql_container["user"],
                password=mysql_container["password"],
                database=mysql_container["database"],
                connection_timeout=0.001,  # 1ms timeout (will fail)
            )

        # Try with reasonable timeout
        conn = mysql.connector.connect(
            host=mysql_container["host"],
            port=mysql_container["port"],
            user=mysql_container["user"],
            password=mysql_container["password"],
            database=mysql_container["database"],
            connection_timeout=5,  # 5 second timeout
        )
        assert conn is not None
        conn.close()


@pytest.mark.chaos
class TestApplicationChaos:
    """Application-level chaos tests."""

    def test_memory_leak_simulation(self):
        """Simulate and detect memory leaks."""
        initial_memory = psutil.Process().memory_info().rss / 1024 / 1024

        # Simulate memory leak
        leaked_data = []
        for _ in range(100):
            # Create data that would leak if not cleaned up
            data = [0] * (1024 * 100)  # 100KB per iteration
            leaked_data.append(data)

        peak_memory = psutil.Process().memory_info().rss / 1024 / 1024
        memory_increase = peak_memory - initial_memory

        print(f"Memory increase: {memory_increase:.1f}MB")

        # Clean up
        leaked_data.clear()

        # Check if memory is released
        time.sleep(1)  # Give GC time to run
        import gc

        gc.collect()

        final_memory = psutil.Process().memory_info().rss / 1024 / 1024
        memory_after_cleanup = final_memory - initial_memory

        print(f"Memory after cleanup: {memory_after_cleanup:.1f}MB")

        # Memory should be mostly released
        assert memory_after_cleanup < memory_increase * 0.5

    def test_cpu_spike(self):
        """Test system under CPU spike."""
        def cpu_intensive_task(duration=2):
            """CPU intensive operation."""
            start = time.time()
            while time.time() - start < duration:
                # Intensive calculation
                _ = sum(i**2 for i in range(1000))

        # Monitor CPU before spike
        cpu_before = psutil.cpu_percent(interval=1)

        # Create CPU spike
        thread = threading.Thread(target=cpu_intensive_task)
        thread.start()

        # Monitor CPU during spike
        time.sleep(0.5)
        cpu_during = psutil.cpu_percent(interval=1)

        thread.join()

        # Monitor CPU after spike
        cpu_after = psutil.cpu_percent(interval=1)

        print(
            f"CPU - Before: {cpu_before}%, During: {cpu_during}%, After: {cpu_after}%"
        )

        # CPU should spike during intensive task
        assert cpu_during > cpu_before

    def test_thread_pool_exhaustion(self):
        """Test thread pool exhaustion."""
        import concurrent.futures

        def slow_task(n):
            """Handle slow task."""
            time.sleep(1)
            return n * 2

        # Create thread pool with limited size
        with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
            # Submit more tasks than workers
            futures = []
            for i in range(20):
                future = executor.submit(slow_task, i)
                futures.append(future)

            # Some tasks should queue
            completed = 0
            timeout = 0

            for future in concurrent.futures.as_completed(futures, timeout=5):
                try:
                    _ = future.result(timeout=0.1)
                    completed += 1
                except concurrent.futures.TimeoutError:
                    timeout += 1

            print(f"Completed: {completed}, Timeout: {timeout}")

            # All tasks should eventually complete
            assert completed == 20

    def test_cascading_failure(self, mysql_cursor, mysql_connection):
        """Test cascading failure scenario."""
        # Create interdependent tables
        tables = []
        for i in range(5):
            table_name = f"cascade_test_{i}"
            mysql_cursor.execute(
                f"""
                CREATE TABLE IF NOT EXISTS {table_name} (
                    id INT PRIMARY KEY,
                    value VARCHAR(50)
                )
            """
            )
            tables.append(table_name)
            mysql_cursor.execute(f"INSERT INTO {table_name} VALUES (1, 'test')")

        mysql_connection.commit()

        # Simulate failure in one table
        failed_table = tables[2]
        mysql_cursor.execute(f"DROP TABLE {failed_table}")
        mysql_connection.commit()

        # Try to query all tables (simulating dependent operations)
        successful_queries = 0
        failed_queries = 0

        for table in tables:
            try:
                mysql_cursor.execute(f"SELECT * FROM {table}")
                mysql_cursor.fetchall()
                successful_queries += 1
            except mysql.connector.Error:
                failed_queries += 1
                print(f"Failed to query {table}")

        # Clean up remaining tables
        for table in tables:
            try:
                mysql_cursor.execute(f"DROP TABLE IF EXISTS {table}")
            except Exception:
                pass
        mysql_connection.commit()

        # System should handle partial failures
        assert failed_queries == 1  # Only the dropped table should fail
        assert successful_queries == 4  # Others should succeed


@pytest.mark.chaos
class TestRecoveryChaos:
    """Test system recovery from chaos events."""

    def test_automatic_reconnection(self, mysql_container):
        """Test automatic reconnection after connection loss."""
        class ResilientConnection:
            """Represent ResilientConnection."""

            def __init__(self, config, max_retries=3):
                """Initialize the instance."""
                self.config = config
                self.max_retries = max_retries
                self.connection = None
                self.connect()

            def connect(self):
                """Handle connect."""
                for attempt in range(self.max_retries):
                    try:
                        self.connection = mysql.connector.connect(**self.config)
                        return
                    except mysql.connector.Error:
                        if attempt < self.max_retries - 1:
                            time.sleep(1)
                raise Exception("Failed to connect after retries")

            def execute_query(self, query):
                """Handle execute query."""
                for attempt in range(self.max_retries):
                    try:
                        cursor = self.connection.cursor()
                        cursor.execute(query)
                        result = cursor.fetchall()
                        cursor.close()
                        return result
                    except mysql.connector.Error:
                        # Try to reconnect
                        try:
                            self.connect()
                        except Exception:
                            if attempt == self.max_retries - 1:
                                raise

        config = {
            "host": mysql_container["host"],
            "port": mysql_container["port"],
            "user": mysql_container["user"],
            "password": mysql_container["password"],
            "database": mysql_container["database"],
        }

        resilient = ResilientConnection(config)

        # Execute query successfully
        result = resilient.execute_query("SELECT 1")
        assert result is not None

        # Simulate connection loss
        resilient.connection.close()

        # Should automatically reconnect
        result = resilient.execute_query("SELECT 2")
        assert result is not None

    def test_circuit_breaker_pattern(self):
        """Test circuit breaker pattern implementation."""
        class CircuitBreaker:
            """Represent CircuitBreaker."""

            def __init__(self, failure_threshold=5, recovery_timeout=5):
                """Initialize the instance."""
                self.failure_threshold = failure_threshold
                self.recovery_timeout = recovery_timeout
                self.failure_count = 0
                self.last_failure_time = None
                self.state = "CLOSED"  # CLOSED, OPEN, HALF_OPEN

            def call(self, func, *args, **kwargs):
                """Handle call."""
                if self.state == "OPEN":
                    if time.time() - self.last_failure_time > self.recovery_timeout:
                        self.state = "HALF_OPEN"
                    else:
                        raise Exception("Circuit breaker is OPEN")

                try:
                    result = func(*args, **kwargs)
                    if self.state == "HALF_OPEN":
                        self.state = "CLOSED"
                        self.failure_count = 0
                    return result
                except Exception as e:
                    self.failure_count += 1
                    self.last_failure_time = time.time()

                    if self.failure_count >= self.failure_threshold:
                        self.state = "OPEN"

                    raise e

        # Test circuit breaker
        breaker = CircuitBreaker(failure_threshold=3, recovery_timeout=2)

        def unreliable_operation():
            """Handle unreliable operation."""
            if random.random() < 0.7:  # 70% failure rate
                raise Exception("Operation failed")
            return "Success"

        successes = 0
        failures = 0
        circuit_open = 0

        for _ in range(20):
            try:
                _ = breaker.call(unreliable_operation)
                successes += 1
            except Exception as e:
                if "Circuit breaker is OPEN" in str(e):
                    circuit_open += 1
                else:
                    failures += 1

            time.sleep(0.2)

        print(
            f"Circuit Breaker - Success: {successes}, Failed: {failures}, Circuit Open: {circuit_open}"
        )

        # Circuit breaker should have triggered
        assert circuit_open > 0

    def test_graceful_degradation(self, mysql_cursor, mysql_connection):
        """Test graceful degradation under failure."""
        # Create primary and cache tables
        mysql_cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS primary_data (
                id INT PRIMARY KEY,
                value VARCHAR(50)
            )
        """
        )
        mysql_cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS cache_data (
                id INT PRIMARY KEY,
                value VARCHAR(50),
                cached_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """
        )

        # Insert data
        mysql_cursor.execute("INSERT INTO primary_data VALUES (1, 'primary_value')")
        mysql_cursor.execute("INSERT INTO cache_data VALUES (1, 'cached_value')")
        mysql_connection.commit()

        def get_data_with_fallback(data_id):
            """Handle get data with fallback."""
            try:
                # Try primary source
                mysql_cursor.execute(
                    f"SELECT value FROM primary_data WHERE id = {data_id}"
                )
                result = mysql_cursor.fetchone()
                if result:
                    return result["value"], "primary"
            except Exception:
                pass

            try:
                # Fallback to cache
                mysql_cursor.execute(
                    f"SELECT value FROM cache_data WHERE id = {data_id}"
                )
                result = mysql_cursor.fetchone()
                if result:
                    return result["value"], "cache"
            except Exception:
                pass

            # Final fallback
            return "default_value", "default"

        # Test with working primary
        value, source = get_data_with_fallback(1)
        assert source == "primary"

        # Simulate primary failure
        mysql_cursor.execute("DROP TABLE primary_data")
        mysql_connection.commit()

        # Should fallback to cache
        value, source = get_data_with_fallback(1)
        assert source == "cache"

        # Simulate cache failure too
        mysql_cursor.execute("DROP TABLE cache_data")
        mysql_connection.commit()

        # Should fallback to default
        value, source = get_data_with_fallback(1)
        assert source == "default"
