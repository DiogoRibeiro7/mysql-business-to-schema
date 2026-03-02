"""Database connection pool management."""

import mysql.connector
from mysql.connector import pooling
import threading
import time
import queue
from typing import Optional, Dict, Any, List
import logging

logger = logging.getLogger(__name__)


class ConnectionPool:
    """Custom connection pool implementation with advanced features."""

    def __init__(
        self,
        host: str,
        user: str,
        password: str,
        database: str,
        pool_size: int = 5,
        max_overflow: int = 10,
        timeout: int = 30,
        recycle: int = 3600,
        **kwargs,
    ):
        """Initialize connection pool.

        Args:
            host: Database host
            user: Database user
            password: Database password
            database: Database name
            pool_size: Number of persistent connections
            max_overflow: Maximum overflow connections
            timeout: Timeout for getting connection
            recycle: Time to recycle connections (seconds)
            **kwargs: Additional connection parameters
        """
        self.config = {
            "host": host,
            "user": user,
            "password": password,
            "database": database,
            **kwargs,
        }

        self.pool_size = pool_size
        self.max_overflow = max_overflow
        self.timeout = timeout
        self.recycle = recycle

        self._pool: queue.Queue[Any] = queue.Queue(maxsize=pool_size)
        self._overflow = 0
        self._lock = threading.Lock()
        self._connections: Dict[int, Dict[str, Any]] = (
            {}
        )  # Track connection creation time

        # Initialize pool with connections
        self._initialize_pool()

    def _initialize_pool(self):
        """Initialize the connection pool with connections."""
        for _ in range(self.pool_size):
            conn = self._create_connection()
            if conn:
                self._pool.put(conn)

    def _create_connection(self) -> Optional[Any]:
        """Create a new database connection."""
        try:
            conn = mysql.connector.connect(**self.config)
            conn_id = id(conn)
            self._connections[conn_id] = {
                "connection": conn,
                "created_at": time.time(),
                "last_used": time.time(),
                "in_use": False,
            }
            logger.debug(f"Created new connection {conn_id}")
            return conn
        except mysql.connector.Error as e:
            logger.error(f"Failed to create connection: {e}")
            return None

    def _is_connection_valid(self, conn) -> bool:
        """Check if a connection is still valid.

        Args:
            conn: Connection to check

        Returns:
            True if valid, False otherwise
        """
        if not conn or not conn.is_connected():
            return False

        conn_id = id(conn)
        if conn_id not in self._connections:
            return False

        conn_info = self._connections[conn_id]

        # Check if connection should be recycled
        if time.time() - conn_info["created_at"] > self.recycle:
            logger.debug(f"Connection {conn_id} exceeded recycle time")
            return False

        # Test connection with ping
        try:
            conn.ping(reconnect=False, attempts=1, delay=0)
            return True
        except Exception:
            return False

    def get_connection(self, timeout: Optional[float] = None):
        """Get a connection from the pool.

        Args:
            timeout: Timeout in seconds (uses default if None)

        Returns:
            Database connection

        Raises:
            TimeoutError: If unable to get connection within timeout
        """
        if timeout is None:
            timeout = self.timeout

        start_time = time.time()

        while time.time() - start_time < timeout:
            # Try to get from pool
            try:
                conn = self._pool.get_nowait()

                # Validate connection
                if self._is_connection_valid(conn):
                    conn_id = id(conn)
                    self._connections[conn_id]["in_use"] = True
                    self._connections[conn_id]["last_used"] = time.time()
                    logger.debug(f"Reusing connection {conn_id}")
                    return conn
                else:
                    # Connection is invalid, close it
                    try:
                        conn.close()
                    except Exception:
                        pass
                    del self._connections[id(conn)]

                    # Create a new connection
                    new_conn = self._create_connection()
                    if new_conn:
                        conn_id = id(new_conn)
                        self._connections[conn_id]["in_use"] = True
                        return new_conn

            except queue.Empty:
                # Pool is empty, try to create overflow connection
                with self._lock:
                    if self._overflow < self.max_overflow:
                        self._overflow += 1
                        try:
                            conn = self._create_connection()
                            if conn:
                                conn_id = id(conn)
                                self._connections[conn_id]["in_use"] = True
                                self._connections[conn_id]["is_overflow"] = True
                                logger.debug(f"Created overflow connection {conn_id}")
                                return conn
                        except Exception:
                            self._overflow -= 1

            # Wait a bit before retrying
            time.sleep(0.1)

        raise TimeoutError(f"Unable to get connection within {timeout} seconds")

    def release_connection(self, conn):
        """Release a connection back to the pool.

        Args:
            conn: Connection to release
        """
        if not conn:
            return

        conn_id = id(conn)
        if conn_id not in self._connections:
            logger.warning(f"Attempting to release unknown connection {conn_id}")
            return

        conn_info = self._connections[conn_id]
        conn_info["in_use"] = False
        conn_info["last_used"] = time.time()

        # Check if connection is still valid
        if not self._is_connection_valid(conn):
            logger.debug(f"Closing invalid connection {conn_id}")
            try:
                conn.close()
            except Exception:
                pass
            del self._connections[conn_id]

            # Handle overflow connection
            if conn_info.get("is_overflow", False):
                with self._lock:
                    self._overflow -= 1
            return

        # Reset connection state
        try:
            conn.rollback()  # Rollback any uncommitted transactions
        except Exception:
            pass

        # Return to pool or close if overflow
        if conn_info.get("is_overflow", False):
            logger.debug(f"Closing overflow connection {conn_id}")
            try:
                conn.close()
            except Exception:
                pass
            del self._connections[conn_id]
            with self._lock:
                self._overflow -= 1
        else:
            try:
                self._pool.put_nowait(conn)
                logger.debug(f"Returned connection {conn_id} to pool")
            except queue.Full:
                # Pool is full, close the connection
                logger.debug(f"Pool full, closing connection {conn_id}")
                try:
                    conn.close()
                except Exception:
                    pass
                del self._connections[conn_id]

    def close_all(self):
        """Close all connections in the pool."""
        logger.info("Closing all connections in pool")

        # Close pooled connections
        while not self._pool.empty():
            try:
                conn = self._pool.get_nowait()
                conn.close()
            except Exception:
                pass

        # Close any remaining tracked connections
        for conn_info in self._connections.values():
            try:
                conn_info["connection"].close()
            except Exception:
                pass

        self._connections.clear()
        self._overflow = 0

    def get_stats(self) -> Dict[str, Any]:
        """Get pool statistics.

        Returns:
            Dictionary with pool statistics
        """
        active_connections = sum(
            1 for info in self._connections.values() if info.get("in_use", False)
        )

        idle_connections = sum(
            1
            for info in self._connections.values()
            if not info.get("in_use", False) and not info.get("is_overflow", False)
        )

        overflow_connections = sum(
            1 for info in self._connections.values() if info.get("is_overflow", False)
        )

        return {
            "pool_size": self.pool_size,
            "max_overflow": self.max_overflow,
            "active_connections": active_connections,
            "idle_connections": idle_connections,
            "overflow_connections": overflow_connections,
            "total_connections": len(self._connections),
            "queue_size": self._pool.qsize(),
        }

    def health_check(self) -> Dict[str, Any]:
        """Perform health check on the pool.

        Returns:
            Health check results
        """
        stats = self.get_stats()
        issues: List[str] = []
        health: Dict[str, Any] = {"healthy": True, "stats": stats, "issues": issues}

        # Check if pool is exhausted
        if stats["active_connections"] >= self.pool_size + self.max_overflow:
            issues.append("Connection pool exhausted")
            health["healthy"] = False

        # Check for stale connections
        current_time = time.time()
        stale_connections = [
            conn_id
            for conn_id, info in self._connections.items()
            if current_time - info["last_used"] > 3600  # 1 hour
        ]

        if stale_connections:
            issues.append(f"{len(stale_connections)} stale connections detected")

        # Test creating a new connection
        try:
            test_conn = self._create_connection()
            if test_conn:
                test_conn.close()
            else:
                issues.append("Unable to create new connections")
                health["healthy"] = False
        except Exception as e:
            issues.append(f"Connection test failed: {e}")
            health["healthy"] = False

        return health

    def __enter__(self):
        """Context manager entry."""
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit."""
        self.close_all()

    def __del__(self):
        """Destructor to ensure connections are closed."""
        try:
            self.close_all()
        except Exception:
            pass


class MySQLConnectionPool:
    """MySQL connection pool using mysql-connector-python's built-in pooling."""

    def __init__(self, pool_name: str = "mypool", pool_size: int = 5, **config):
        """Initialize MySQL connection pool.

        Args:
            pool_name: Name of the pool
            pool_size: Size of the pool
            **config: Database connection configuration
        """
        self.pool = pooling.MySQLConnectionPool(
            pool_name=pool_name, pool_size=pool_size, pool_reset_session=True, **config
        )
        self.pool_name = pool_name

    def get_connection(self):
        """Return a connection from the pool."""
        return self.pool.get_connection()

    def close_all(self):
        """Close all connections (not directly supported by MySQLConnectionPool)."""
        # MySQL connection pool doesn't provide direct close_all
        # Connections are closed when they go out of scope


def create_pool(
    config: Dict[str, Any], pool_type: str = "custom", **pool_kwargs
) -> Any:
    """Create a connection pool.

    Args:
        config: Database connection configuration
        pool_type: Type of pool ("custom" or "mysql")
        **pool_kwargs: Additional pool configuration

    Returns:
        Connection pool instance
    """
    if pool_type == "mysql":
        return MySQLConnectionPool(**config, **pool_kwargs)
    else:
        return ConnectionPool(**config, **pool_kwargs)
