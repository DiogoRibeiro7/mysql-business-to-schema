"""Monitoring and metrics collection module."""

import asyncio
import psutil
from typing import Dict, List, Any
from datetime import datetime
import logging
import json
from collections import deque
from fastapi import WebSocket

logger = logging.getLogger(__name__)


class MetricsCollector:
    """Collects and manages system metrics."""

    def __init__(self):
        """Initialize the instance."""
        self.metrics_history = {
            "cpu": deque(maxlen=100),
            "memory": deque(maxlen=100),
            "disk_io": deque(maxlen=100),
            "network_io": deque(maxlen=100),
            "query_latency": deque(maxlen=100),
            "qps": deque(maxlen=100),
        }
        self.collection_task = None
        self.is_collecting = False

    async def start_collection(self):
        """Start metrics collection."""
        if not self.is_collecting:
            self.is_collecting = True
            self.collection_task = asyncio.create_task(self._collect_metrics())
            logger.info("Metrics collection started")

    async def stop_collection(self):
        """Stop metrics collection."""
        self.is_collecting = False
        if self.collection_task:
            self.collection_task.cancel()
            try:
                await self.collection_task
            except asyncio.CancelledError:
                pass
            logger.info("Metrics collection stopped")

    async def _collect_metrics(self):
        """Collect metrics periodically."""
        while self.is_collecting:
            try:
                timestamp = datetime.utcnow()

                # System metrics
                cpu_percent = psutil.cpu_percent(interval=1)
                memory = psutil.virtual_memory()
                disk_io = psutil.disk_io_counters()
                network_io = psutil.net_io_counters()

                # Store metrics
                self.metrics_history["cpu"].append(
                    {"timestamp": timestamp.isoformat(), "value": cpu_percent}
                )

                self.metrics_history["memory"].append(
                    {"timestamp": timestamp.isoformat(), "value": memory.percent}
                )

                if disk_io:
                    self.metrics_history["disk_io"].append(
                        {
                            "timestamp": timestamp.isoformat(),
                            "read_bytes": disk_io.read_bytes,
                            "write_bytes": disk_io.write_bytes,
                        }
                    )

                if network_io:
                    self.metrics_history["network_io"].append(
                        {
                            "timestamp": timestamp.isoformat(),
                            "bytes_sent": network_io.bytes_sent,
                            "bytes_recv": network_io.bytes_recv,
                        }
                    )

                # Database metrics (would need actual DB connection)
                # This is placeholder for actual implementation
                self.metrics_history["qps"].append(
                    {
                        "timestamp": timestamp.isoformat(),
                        "value": 0,  # Would calculate actual QPS
                    }
                )

                await asyncio.sleep(5)  # Collect every 5 seconds

            except Exception as e:
                logger.error(f"Error collecting metrics: {e}")
                await asyncio.sleep(5)

    async def get_overview_metrics(self) -> Dict[str, Any]:
        """Get overview metrics for dashboard."""
        # Get database connection for actual metrics
        # This is a simplified version
        from .database import db_manager

        metrics = {
            "database_count": 0,
            "table_count": 0,
            "total_size_mb": 0,
            "active_connections": 0,
            "qps": 0,
            "uptime_percentage": 99.9,
            "slow_queries_count": 0,
            "error_rate": 0,
        }

        try:
            # Get actual database metrics
            databases = await db_manager.execute_query("SHOW DATABASES")
            metrics["database_count"] = len(
                [
                    d
                    for d in databases
                    if d["Database"]
                    not in ["information_schema", "mysql", "performance_schema", "sys"]
                ]
            )

            # Get connection count
            connections = await db_manager.execute_query(
                "SHOW STATUS LIKE 'Threads_connected'"
            )
            if connections:
                metrics["active_connections"] = int(connections[0]["Value"])

            # Get QPS
            queries = await db_manager.execute_query("SHOW STATUS LIKE 'Queries'")
            uptime = await db_manager.execute_query("SHOW STATUS LIKE 'Uptime'")
            if queries and uptime:
                total_queries = int(queries[0]["Value"])
                uptime_seconds = int(uptime[0]["Value"])
                metrics["qps"] = (
                    round(total_queries / uptime_seconds, 2)
                    if uptime_seconds > 0
                    else 0
                )

        except Exception as e:
            logger.error(f"Error getting overview metrics: {e}")

        return metrics

    async def get_performance_metrics(self, timeframe: str = "1h") -> Dict[str, Any]:
        """Get performance metrics for specified timeframe."""
        # Convert timeframe to number of data points
        points_map = {
            "5m": 12,  # 5 minutes, one point every 25 seconds
            "15m": 18,  # 15 minutes
            "1h": 60,  # 1 hour
            "6h": 72,  # 6 hours
            "24h": 96,  # 24 hours
        }
        num_points = points_map.get(timeframe, 60)

        # Get recent metrics from history
        def get_recent(metric_name: str, count: int):
            """Handle get recent."""
            data = list(self.metrics_history[metric_name])
            if len(data) > count:
                return data[-count:]
            return data

        return {
            "cpu_usage": get_recent("cpu", num_points),
            "memory_usage": get_recent("memory", num_points),
            "disk_io": get_recent("disk_io", num_points),
            "network_io": get_recent("network_io", num_points),
            "query_latency": get_recent("query_latency", num_points),
            "timestamps": [datetime.utcnow().isoformat()],
        }

    async def get_slow_queries(self, limit: int = 10) -> List[Dict[str, Any]]:
        """Get slow queries from database."""
        from .database import db_manager

        try:
            # Query slow query log or performance schema
            query = """
            SELECT
                query_time,
                lock_time,
                rows_sent,
                rows_examined,
                db,
                sql_text,
                start_time
            FROM mysql.slow_log
            ORDER BY start_time DESC
            LIMIT %s
            """

            # Try to get from slow log
            try:
                results = await db_manager.execute_query(query, (limit,))
                return [
                    {
                        "query_id": str(i),
                        "query": r["sql_text"],
                        "execution_time": float(r["query_time"]),
                        "rows_examined": r["rows_examined"],
                        "rows_sent": r["rows_sent"],
                        "timestamp": r["start_time"],
                        "database": r["db"],
                    }
                    for i, r in enumerate(results)
                ]
            except Exception:
                # Fallback to performance schema
                query = """
                SELECT
                    DIGEST_TEXT as query,
                    COUNT_STAR as exec_count,
                    AVG_TIMER_WAIT/1000000000 as avg_time_ms,
                    SUM_ROWS_EXAMINED as total_rows_examined,
                    SUM_ROWS_SENT as total_rows_sent,
                    FIRST_SEEN,
                    LAST_SEEN
                FROM performance_schema.events_statements_summary_by_digest
                WHERE DIGEST_TEXT IS NOT NULL
                ORDER BY AVG_TIMER_WAIT DESC
                LIMIT %s
                """
                results = await db_manager.execute_query(query, (limit,))
                return [
                    {
                        "query_id": str(i),
                        "query": r["query"],
                        "execution_time": float(r["avg_time_ms"]),
                        "exec_count": r["exec_count"],
                        "rows_examined": r["total_rows_examined"],
                        "rows_sent": r["total_rows_sent"],
                        "first_seen": r["FIRST_SEEN"],
                        "last_seen": r["LAST_SEEN"],
                    }
                    for i, r in enumerate(results)
                ]

        except Exception as e:
            logger.error(f"Error getting slow queries: {e}")
            return []

    async def get_real_time_metrics(self) -> Dict[str, Any]:
        """Get real-time metrics for WebSocket updates."""
        cpu = psutil.cpu_percent(interval=0.1)
        memory = psutil.virtual_memory()

        # Get database metrics
        from .database import db_manager

        qps = 0
        connections = 0

        try:
            # Get current QPS
            status = await db_manager.execute_query(
                """
                SELECT
                    (SELECT Variable_value FROM performance_schema.global_status WHERE Variable_name = 'Queries') as queries,
                    (SELECT Variable_value FROM performance_schema.global_status WHERE Variable_name = 'Uptime') as uptime,
                    (SELECT Variable_value FROM performance_schema.global_status
                     WHERE Variable_name = 'Threads_connected') as connections
            """
            )

            if status:
                queries = int(status[0].get("queries", 0))
                uptime = int(status[0].get("uptime", 1))
                connections = int(status[0].get("connections", 0))
                qps = round(queries / uptime, 2) if uptime > 0 else 0

        except Exception as e:
            logger.error(f"Error getting real-time database metrics: {e}")

        return {
            "cpu": cpu,
            "memory": memory.percent,
            "qps": qps,
            "active_connections": connections,
            "response_time_ms": 0,  # Would calculate actual response time
            "timestamp": datetime.utcnow().isoformat(),
        }

    async def check_alerts(self) -> List[Dict[str, Any]]:
        """Check for triggered alerts based on current metrics."""
        from .database import db_manager

        triggered_alerts = []

        try:
            # Get active alert configurations
            alerts = await db_manager.execute_query(
                """
                SELECT * FROM alert_configs WHERE is_enabled = 1
            """
            )

            # Get current metrics
            current_metrics = await self.get_real_time_metrics()

            for alert in alerts:
                metric_value = None
                metric_name = alert["metric"]

                # Map metric names to values
                if metric_name == "cpu_usage":
                    metric_value = current_metrics["cpu"]
                elif metric_name == "memory_usage":
                    metric_value = current_metrics["memory"]
                elif metric_name == "qps":
                    metric_value = current_metrics["qps"]
                elif metric_name == "connections":
                    metric_value = current_metrics["active_connections"]

                if metric_value is not None:
                    threshold = float(alert["threshold"])
                    condition = alert["condition_type"]

                    triggered = False
                    if condition == "greater_than" and metric_value > threshold:
                        triggered = True
                    elif condition == "less_than" and metric_value < threshold:
                        triggered = True
                    elif condition == "equals" and abs(metric_value - threshold) < 0.01:
                        triggered = True

                    if triggered:
                        triggered_alerts.append(
                            {
                                "alert_id": alert["alert_id"],
                                "alert_name": alert["name"],
                                "metric": metric_name,
                                "current_value": metric_value,
                                "threshold": threshold,
                                "condition": condition,
                            }
                        )

                        # Record in alert history
                        await db_manager.execute_update(
                            """
                            INSERT INTO alert_history
                            (alert_id, alert_name, metric_value, threshold, condition_type)
                            VALUES (%s, %s, %s, %s, %s)
                        """,
                            (
                                alert["alert_id"],
                                alert["name"],
                                metric_value,
                                threshold,
                                condition,
                            ),
                        )

        except Exception as e:
            logger.error(f"Error checking alerts: {e}")

        return triggered_alerts


class ConnectionManager:
    """Manages WebSocket connections for real-time updates."""

    def __init__(self):
        """Initialize the instance."""
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        """Accept WebSocket connection."""
        await websocket.accept()
        self.active_connections.append(websocket)
        logger.info(
            f"WebSocket client connected. Total connections: {len(self.active_connections)}"
        )

    def disconnect(self, websocket: WebSocket):
        """Remove WebSocket connection."""
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)
            logger.info(
                f"WebSocket client disconnected. Total connections: {len(self.active_connections)}"
            )

    async def send_personal_message(self, message: str, websocket: WebSocket):
        """Send message to specific WebSocket."""
        try:
            await websocket.send_text(message)
        except Exception as e:
            logger.error(f"Error sending WebSocket message: {e}")
            self.disconnect(websocket)

    async def broadcast(self, message: Dict[str, Any]):
        """Broadcast message to all connected clients."""
        message_str = json.dumps(message)
        disconnected = []

        for connection in self.active_connections:
            try:
                await connection.send_text(message_str)
            except Exception as e:
                logger.error(f"Error broadcasting to WebSocket: {e}")
                disconnected.append(connection)

        # Remove disconnected clients
        for connection in disconnected:
            self.disconnect(connection)
