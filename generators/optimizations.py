"""
Performance optimization utilities for data generators.
"""

import math
import psutil
from typing import Optional, Dict, Any, List, Tuple
import time
from functools import wraps
import logging

logger = logging.getLogger(__name__)


def calculate_optimal_batch_size(
    total_records: int, max_memory_mb: int = 512, record_size_bytes: int = 1024
) -> int:
    """
    Calculate optimal batch size based on available resources.

    Args:
        total_records: Total number of records to process
        max_memory_mb: Maximum memory to use in MB
        record_size_bytes: Estimated size of each record

    Returns:
        Optimal batch size
    """
    # Get available system memory
    available_memory = psutil.virtual_memory().available / 1024 / 1024  # MB

    # Use the smaller of max_memory_mb and half of available memory
    usable_memory = min(max_memory_mb, available_memory * 0.5)

    # Calculate batch size based on memory
    memory_based_batch = int(usable_memory * 1024 * 1024 / record_size_bytes)

    # Apply constraints
    min_batch = 10
    max_batch = 10000

    # Heuristic based on total records
    if total_records < 100:
        suggested_batch = min(total_records, 10)
    elif total_records < 1000:
        suggested_batch = 100
    elif total_records < 10000:
        suggested_batch = 500
    elif total_records < 100000:
        suggested_batch = 1000
    else:
        suggested_batch = 5000

    # Choose the smaller of memory-based and suggested batch
    optimal = min(memory_based_batch, suggested_batch)

    # Apply min/max constraints
    return max(min_batch, min(optimal, max_batch))


def optimize_query(query: str) -> str:
    """
    Apply basic query optimizations.

    Args:
        query: SQL query to optimize

    Returns:
        Optimized query string
    """
    optimized = query.strip()

    # Remove unnecessary whitespace
    import re

    optimized = re.sub(r"\s+", " ", optimized)

    # Suggest index usage for WHERE clauses without indexes
    if "WHERE" in optimized.upper() and "INDEX" not in optimized.upper():
        logger.info("Consider adding indexes for WHERE clause columns")

    # Warn about SELECT *
    if "SELECT *" in optimized.upper():
        logger.warning("SELECT * detected - consider specifying columns")

    # Warn about missing LIMIT in large table queries
    if "LIMIT" not in optimized.upper() and any(
        keyword in optimized.upper() for keyword in ["SELECT", "DELETE", "UPDATE"]
    ):
        logger.info("Consider adding LIMIT clause for large datasets")

    return optimized


def get_query_execution_plan(connection, query: str) -> List[Dict]:
    """
    Get query execution plan.

    Args:
        connection: Database connection
        query: SQL query to analyze

    Returns:
        Execution plan details
    """
    cursor = connection.cursor(dictionary=True)
    cursor.execute(f"EXPLAIN {query}")
    plan = cursor.fetchall()
    cursor.close()
    return plan


def analyze_index_usage(connection, table_name: str) -> Dict[str, Any]:
    """
    Analyze index usage for a table.

    Args:
        connection: Database connection
        table_name: Table to analyze

    Returns:
        Index usage statistics
    """
    cursor = connection.cursor(dictionary=True)

    # Get table indexes
    cursor.execute(
        f"""
        SELECT
            INDEX_NAME,
            COLUMN_NAME,
            NON_UNIQUE,
            SEQ_IN_INDEX
        FROM INFORMATION_SCHEMA.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = '{table_name}'
        ORDER BY INDEX_NAME, SEQ_IN_INDEX
    """
    )
    indexes = cursor.fetchall()

    # Get index statistics
    cursor.execute(
        f"""
        SELECT
            index_name,
            rows_read,
            rows_inserted
        FROM performance_schema.table_io_waits_summary_by_index_usage
        WHERE object_schema = DATABASE()
        AND object_name = '{table_name}'
    """
    )
    stats = cursor.fetchall()

    cursor.close()

    return {"indexes": indexes, "usage_stats": stats}


def suggest_indexes(connection, slow_queries: List[str]) -> List[str]:
    """
    Suggest indexes based on slow queries.

    Args:
        connection: Database connection
        slow_queries: List of slow queries

    Returns:
        List of suggested indexes
    """
    suggestions = []
    cursor = connection.cursor(dictionary=True)

    for query in slow_queries:
        try:
            # Get execution plan
            cursor.execute(f"EXPLAIN {query}")
            plan = cursor.fetchall()

            for row in plan:
                # Check if full table scan
                if row.get("type") == "ALL" and row.get("key") is None:
                    table = row.get("table")
                    # Parse WHERE clause to find columns
                    import re

                    where_match = re.search(r"WHERE\s+(\w+)\s*=", query, re.IGNORECASE)
                    if where_match:
                        column = where_match.group(1)
                        suggestion = (
                            f"CREATE INDEX idx_{table}_{column} ON {table}({column})"
                        )
                        if suggestion not in suggestions:
                            suggestions.append(suggestion)

        except Exception as e:
            logger.error(f"Error analyzing query: {e}")

    cursor.close()
    return suggestions


class QueryOptimizer:
    """
    Query optimization helper class.
    """

    def __init__(self, connection):
        self.connection = connection
        self.cache = {}
        self.stats = {"cache_hits": 0, "cache_misses": 0, "total_queries": 0}

    def execute_with_cache(self, query: str, cache_ttl: int = 60):
        """
        Execute query with result caching.

        Args:
            query: SQL query to execute
            cache_ttl: Cache time-to-live in seconds

        Returns:
            Query results
        """
        self.stats["total_queries"] += 1

        # Check cache
        cache_key = query
        if cache_key in self.cache:
            cached_data, timestamp = self.cache[cache_key]
            if time.time() - timestamp < cache_ttl:
                self.stats["cache_hits"] += 1
                return cached_data

        # Execute query
        self.stats["cache_misses"] += 1
        cursor = self.connection.cursor(dictionary=True)
        cursor.execute(query)
        results = cursor.fetchall()
        cursor.close()

        # Cache results
        self.cache[cache_key] = (results, time.time())

        # Clean old cache entries
        self._clean_cache(cache_ttl)

        return results

    def _clean_cache(self, ttl: int):
        """Clean expired cache entries."""
        current_time = time.time()
        expired_keys = [
            key
            for key, (_, timestamp) in self.cache.items()
            if current_time - timestamp > ttl
        ]
        for key in expired_keys:
            del self.cache[key]

    def get_stats(self) -> Dict[str, Any]:
        """Get cache statistics."""
        hit_rate = (
            self.stats["cache_hits"] / self.stats["total_queries"]
            if self.stats["total_queries"] > 0
            else 0
        )
        return {**self.stats, "hit_rate": hit_rate, "cache_size": len(self.cache)}


def profile_query(func):
    """
    Decorator to profile query execution time.
    """

    @wraps(func)
    def wrapper(*args, **kwargs):
        start_time = time.time()
        start_memory = psutil.Process().memory_info().rss / 1024 / 1024

        try:
            result = func(*args, **kwargs)
            execution_time = time.time() - start_time
            memory_used = (
                psutil.Process().memory_info().rss / 1024 / 1024 - start_memory
            )

            logger.info(
                f"{func.__name__} - Time: {execution_time:.2f}s, "
                f"Memory: {memory_used:.2f}MB"
            )

            # Warn if slow
            if execution_time > 1.0:
                logger.warning(
                    f"{func.__name__} took {execution_time:.2f}s - consider optimization"
                )

            return result

        except Exception as e:
            execution_time = time.time() - start_time
            logger.error(f"{func.__name__} failed after {execution_time:.2f}s: {e}")
            raise

    return wrapper


def batch_processor(
    data: List[Any],
    batch_size: Optional[int] = None,
    processor_func: Optional[callable] = None,
) -> None:
    """
    Process data in optimized batches.

    Args:
        data: List of data to process
        batch_size: Size of each batch (auto-calculated if None)
        processor_func: Function to process each batch
    """
    if batch_size is None:
        batch_size = calculate_optimal_batch_size(len(data))

    total_batches = math.ceil(len(data) / batch_size)

    for i in range(0, len(data), batch_size):
        batch = data[i : i + batch_size]
        batch_num = i // batch_size + 1

        logger.info(f"Processing batch {batch_num}/{total_batches}")

        if processor_func:
            processor_func(batch)
        else:
            yield batch


class PerformanceMonitor:
    """
    Monitor and track performance metrics.
    """

    def __init__(self):
        self.metrics = []
        self.start_time = None

    def start(self):
        """Start monitoring."""
        self.start_time = time.time()
        self.start_memory = psutil.Process().memory_info().rss / 1024 / 1024
        self.start_cpu = psutil.cpu_percent(interval=0.1)

    def checkpoint(self, label: str):
        """Record a checkpoint."""
        if self.start_time is None:
            raise RuntimeError("Monitor not started")

        current_time = time.time()
        current_memory = psutil.Process().memory_info().rss / 1024 / 1024
        current_cpu = psutil.cpu_percent(interval=0.1)

        self.metrics.append(
            {
                "label": label,
                "elapsed_time": current_time - self.start_time,
                "memory_mb": current_memory,
                "memory_delta_mb": current_memory - self.start_memory,
                "cpu_percent": current_cpu,
            }
        )

    def get_report(self) -> Dict[str, Any]:
        """Get performance report."""
        if not self.metrics:
            return {}

        total_time = time.time() - self.start_time if self.start_time else 0
        max_memory = max(m["memory_mb"] for m in self.metrics) if self.metrics else 0
        avg_cpu = (
            sum(m["cpu_percent"] for m in self.metrics) / len(self.metrics)
            if self.metrics
            else 0
        )

        return {
            "total_time": total_time,
            "max_memory_mb": max_memory,
            "avg_cpu_percent": avg_cpu,
            "checkpoints": self.metrics,
        }


def optimize_connection_pool(
    min_size: int = 1, max_size: int = 10, max_idle_time: int = 300
) -> Dict[str, int]:
    """
    Calculate optimal connection pool settings.

    Args:
        min_size: Minimum pool size
        max_size: Maximum pool size
        max_idle_time: Maximum idle time in seconds

    Returns:
        Optimized pool configuration
    """
    # Get system resources
    cpu_count = psutil.cpu_count()
    memory_gb = psutil.virtual_memory().total / 1024 / 1024 / 1024

    # Calculate based on resources
    suggested_min = max(1, cpu_count // 2)
    suggested_max = min(cpu_count * 4, int(memory_gb * 2))

    # Apply constraints
    optimized_min = max(min_size, min(suggested_min, max_size))
    optimized_max = max(optimized_min, min(suggested_max, max_size))

    return {
        "min_size": optimized_min,
        "max_size": optimized_max,
        "max_idle_time": max_idle_time,
        "queue_timeout": 30,
    }
