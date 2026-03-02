#!/usr/bin/env python3
"""Performance Test Coordinator for MySQL Business-to-Schema.

Central coordination and reporting for all performance tests
"""

import os
import time
import json
import uuid
import threading
from datetime import datetime
from typing import Dict, List, Any, Optional
from dataclasses import dataclass, asdict
from enum import Enum

import docker
import psycopg2
import redis
from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
from prometheus_client import CollectorRegistry, Gauge, Counter, generate_latest
import pandas as pd
from plotly.subplots import make_subplots

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Configuration
DATABASE_URL = os.getenv(
    "DATABASE_URL", "postgresql://postgres:password@localhost:5432/performance"
)
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")
DOCKER_SOCKET = os.getenv("DOCKER_SOCKET", "unix:///var/run/docker.sock")

# Initialize connections
redis_client = redis.from_url(REDIS_URL)
docker_client = docker.DockerClient(base_url=DOCKER_SOCKET)

# Metrics registry
registry = CollectorRegistry()
test_runs = Counter(
    "test_coordinator_runs_total", "Total test runs", ["test_type"], registry=registry
)
test_status = Gauge(
    "test_coordinator_status", "Test run status", ["test_id"], registry=registry
)


class TestType(Enum):
    """Types of performance tests."""

    LOCUST = "locust"
    K6 = "k6"
    GATLING = "gatling"
    JMETER = "jmeter"
    CUSTOM = "custom"


class TestStatus(Enum):
    """Test execution status."""

    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"


@dataclass
class TestConfiguration:
    """Test configuration."""

    test_id: str
    test_type: TestType
    name: str
    description: str
    target_url: str
    duration: int  # seconds
    users: int
    ramp_up: int  # seconds
    scenarios: List[Dict[str, Any]]
    thresholds: Dict[str, Any]
    metadata: Dict[str, Any]


@dataclass
class TestResult:
    """Test execution result."""

    test_id: str
    status: TestStatus
    start_time: datetime
    end_time: Optional[datetime]
    metrics: Dict[str, Any]
    errors: List[str]
    report_url: Optional[str]


class TestCoordinator:
    """Run test coordinator."""

    def __init__(self):
        """Initialize the instance."""
        self.active_tests = {}
        self.test_history = []
        self.init_database()

    def init_database(self):
        """Initialize PostgreSQL database."""
        conn = psycopg2.connect(DATABASE_URL)
        cur = conn.cursor()

        # Create tables
        cur.execute(
            """
            CREATE TABLE IF NOT EXISTS test_runs (
                test_id UUID PRIMARY KEY,
                test_type VARCHAR(50),
                name VARCHAR(255),
                description TEXT,
                configuration JSONB,
                status VARCHAR(50),
                start_time TIMESTAMP,
                end_time TIMESTAMP,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """
        )

        cur.execute(
            """
            CREATE TABLE IF NOT EXISTS test_metrics (
                id SERIAL PRIMARY KEY,
                test_id UUID REFERENCES test_runs(test_id),
                timestamp TIMESTAMP,
                metric_name VARCHAR(255),
                metric_value FLOAT,
                metadata JSONB
            )
        """
        )

        cur.execute(
            """
            CREATE TABLE IF NOT EXISTS test_errors (
                id SERIAL PRIMARY KEY,
                test_id UUID REFERENCES test_runs(test_id),
                timestamp TIMESTAMP,
                error_type VARCHAR(255),
                error_message TEXT,
                stack_trace TEXT
            )
        """
        )

        conn.commit()
        cur.close()
        conn.close()

    def create_test(self, config: TestConfiguration) -> str:
        """Create a new test run."""
        test_id = str(uuid.uuid4())
        config.test_id = test_id

        # Store in database
        conn = psycopg2.connect(DATABASE_URL)
        cur = conn.cursor()

        cur.execute(
            """
            INSERT INTO test_runs (test_id, test_type, name, description, configuration, status, start_time)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """,
            (
                test_id,
                config.test_type.value,
                config.name,
                config.description,
                json.dumps(asdict(config)),
                TestStatus.PENDING.value,
                datetime.utcnow(),
            ),
        )

        conn.commit()
        cur.close()
        conn.close()

        # Store in Redis for quick access
        redis_client.setex(
            f"test:{test_id}", 3600, json.dumps(asdict(config))  # 1 hour TTL
        )

        # Add to active tests
        self.active_tests[test_id] = config

        # Increment metrics
        test_runs.labels(test_type=config.test_type.value).inc()

        return test_id

    def run_test(self, test_id: str) -> TestResult:
        """Execute a test run."""
        config = self.active_tests.get(test_id)
        if not config:
            raise ValueError(f"Test {test_id} not found")

        # Update status
        self.update_test_status(test_id, TestStatus.RUNNING)

        # Run test based on type
        if config.test_type == TestType.LOCUST:
            result = self.run_locust_test(config)
        elif config.test_type == TestType.K6:
            result = self.run_k6_test(config)
        elif config.test_type == TestType.GATLING:
            result = self.run_gatling_test(config)
        elif config.test_type == TestType.JMETER:
            result = self.run_jmeter_test(config)
        else:
            result = self.run_custom_test(config)

        # Update status
        self.update_test_status(test_id, result.status)

        # Store results
        self.store_test_results(result)

        return result

    def run_locust_test(self, config: TestConfiguration) -> TestResult:
        """Run Locust test."""
        try:
            # Start Locust master
            master = docker_client.containers.run(
                "locustio/locust",
                command=f"-f /mnt/locust/locustfile.py --master --expect-workers 3 -H {config.target_url}",
                detach=True,
                name=f"locust-master-{config.test_id}",
                volumes={"/opt/locust": {"bind": "/mnt/locust", "mode": "ro"}},
                network="performance-testing",
                environment={"TARGET_HOST": config.target_url},
            )

            # Start workers
            workers = []
            for i in range(3):
                worker = docker_client.containers.run(
                    "locustio/locust",
                    command=f"-f /mnt/locust/locustfile.py --worker --master-host {master.name}",
                    detach=True,
                    name=f"locust-worker-{i}-{config.test_id}",
                    volumes={"/opt/locust": {"bind": "/mnt/locust", "mode": "ro"}},
                    network="performance-testing",
                )
                workers.append(worker)

            # Start test
            time.sleep(5)  # Wait for workers to connect

            # Trigger test via API
            import requests

            _ = requests.post(
                f"http://{master.name}:8089/swarm",
                json={
                    "user_count": config.users,
                    "spawn_rate": config.users / config.ramp_up,
                    "host": config.target_url,
                },
            )

            # Monitor test
            start_time = datetime.utcnow()
            _ = self.monitor_locust_test(master, config.duration)

            # Stop test
            requests.get(f"http://{master.name}:8089/stop")

            # Collect results
            stats = requests.get(f"http://{master.name}:8089/stats/requests").json()

            # Clean up containers
            master.stop()
            master.remove()
            for worker in workers:
                worker.stop()
                worker.remove()

            return TestResult(
                test_id=config.test_id,
                status=TestStatus.COMPLETED,
                start_time=start_time,
                end_time=datetime.utcnow(),
                metrics={
                    "total_requests": stats.get("total_rps", 0),
                    "failure_rate": stats.get("fail_ratio", 0),
                    "response_time_p50": stats.get("response_time_percentile_50", 0),
                    "response_time_p95": stats.get("response_time_percentile_95", 0),
                    "response_time_p99": stats.get("response_time_percentile_99", 0),
                },
                errors=[],
                report_url=f"/reports/{config.test_id}",
            )

        except Exception as e:
            return TestResult(
                test_id=config.test_id,
                status=TestStatus.FAILED,
                start_time=datetime.utcnow(),
                end_time=datetime.utcnow(),
                metrics={},
                errors=[str(e)],
                report_url=None,
            )

    def run_k6_test(self, config: TestConfiguration) -> TestResult:
        """Run K6 test."""
        try:
            # Run K6 container
            _ = docker_client.containers.run(
                "grafana/k6",
                command=f"run /scripts/load-test.js --duration {config.duration}s --vus {config.users}",
                volumes={
                    "/opt/k6": {"bind": "/scripts", "mode": "ro"},
                    "/opt/results": {"bind": "/results", "mode": "rw"},
                },
                environment={
                    "BASE_URL": config.target_url,
                    "K6_OUT": "json=/results/results.json",
                },
                network="performance-testing",
                remove=True,
            )

            # Parse results
            with open("/opt/results/results.json", "r") as f:
                k6_results = json.load(f)

            return TestResult(
                test_id=config.test_id,
                status=TestStatus.COMPLETED,
                start_time=datetime.utcnow(),
                end_time=datetime.utcnow(),
                metrics=k6_results.get("metrics", {}),
                errors=[],
                report_url=f"/reports/{config.test_id}",
            )

        except Exception as e:
            return TestResult(
                test_id=config.test_id,
                status=TestStatus.FAILED,
                start_time=datetime.utcnow(),
                end_time=datetime.utcnow(),
                metrics={},
                errors=[str(e)],
                report_url=None,
            )

    def run_gatling_test(self, config: TestConfiguration) -> TestResult:
        """Run Gatling test."""
        # Implementation for Gatling

    def run_jmeter_test(self, config: TestConfiguration) -> TestResult:
        """Run JMeter test."""
        # Implementation for JMeter

    def run_custom_test(self, config: TestConfiguration) -> TestResult:
        """Run custom test."""
        # Implementation for custom tests

    def monitor_locust_test(self, container, duration: int) -> Dict[str, Any]:
        """Monitor running Locust test."""
        metrics = []
        end_time = time.time() + duration

        while time.time() < end_time:
            try:
                # Get stats from Locust
                import requests

                stats = requests.get(
                    f"http://{container.name}:8089/stats/requests"
                ).json()
                metrics.append(
                    {
                        "timestamp": datetime.utcnow().isoformat(),
                        "rps": stats.get("total_rps", 0),
                        "failures": stats.get("num_failures", 0),
                        "users": stats.get("user_count", 0),
                    }
                )
            except Exception:
                pass

            time.sleep(5)

        return {"timeline": metrics}

    def update_test_status(self, test_id: str, status: TestStatus):
        """Update test status."""
        conn = psycopg2.connect(DATABASE_URL)
        cur = conn.cursor()

        cur.execute(
            """
            UPDATE test_runs
            SET status = %s, end_time = %s
            WHERE test_id = %s
        """,
            (
                status.value,
                (
                    datetime.utcnow()
                    if status in [TestStatus.COMPLETED, TestStatus.FAILED]
                    else None
                ),
                test_id,
            ),
        )

        conn.commit()
        cur.close()
        conn.close()

        # Update metrics
        test_status.labels(test_id=test_id).set(status.value == TestStatus.RUNNING)

    def store_test_results(self, result: TestResult):
        """Store test results in database."""
        conn = psycopg2.connect(DATABASE_URL)
        cur = conn.cursor()

        # Store metrics
        for metric_name, metric_value in result.metrics.items():
            cur.execute(
                """
                INSERT INTO test_metrics (test_id, timestamp, metric_name, metric_value)
                VALUES (%s, %s, %s, %s)
            """,
                (result.test_id, result.end_time, metric_name, metric_value),
            )

        # Store errors
        for error in result.errors:
            cur.execute(
                """
                INSERT INTO test_errors (test_id, timestamp, error_type, error_message)
                VALUES (%s, %s, %s, %s)
            """,
                (result.test_id, result.end_time, "error", error),
            )

        conn.commit()
        cur.close()
        conn.close()

    def generate_report(self, test_id: str) -> str:
        """Generate test report."""
        conn = psycopg2.connect(DATABASE_URL)

        # Get test info
        test_df = pd.read_sql(
            """
            SELECT * FROM test_runs WHERE test_id = %s
        """,
            conn,
            params=(test_id,),
        )

        # Get metrics
        _ = pd.read_sql(
            """
            SELECT * FROM test_metrics WHERE test_id = %s ORDER BY timestamp
        """,
            conn,
            params=(test_id,),
        )

        conn.close()

        # Create visualizations
        fig = make_subplots(
            rows=2,
            cols=2,
            subplot_titles=("Response Time", "Throughput", "Error Rate", "User Load"),
        )

        # Add traces for different metrics
        # ... (visualization code)

        # Generate HTML report
        report_html = f"""
        <html>
        <head><title>Test Report - {test_id}</title></head>
        <body>
            <h1>Performance Test Report</h1>
            <h2>Test: {test_df.iloc[0]['name']}</h2>
            <p>{test_df.iloc[0]['description']}</p>
            <div>{fig.to_html()}</div>
        </body>
        </html>
        """

        # Save report
        report_path = f"/opt/results/reports/{test_id}.html"
        with open(report_path, "w") as f:
            f.write(report_html)

        return report_path


# Create coordinator instance
coordinator = TestCoordinator()


# Flask routes
@app.route("/health")
def health():
    """Health check endpoint."""
    return jsonify({"status": "healthy"})


@app.route("/api/tests", methods=["POST"])
def create_test():
    """Create new test."""
    data = request.json

    config = TestConfiguration(
        test_id="",
        test_type=TestType(data["test_type"]),
        name=data["name"],
        description=data.get("description", ""),
        target_url=data["target_url"],
        duration=data.get("duration", 300),
        users=data.get("users", 10),
        ramp_up=data.get("ramp_up", 30),
        scenarios=data.get("scenarios", []),
        thresholds=data.get("thresholds", {}),
        metadata=data.get("metadata", {}),
    )

    test_id = coordinator.create_test(config)

    return jsonify({"test_id": test_id, "status": "created"})


@app.route("/api/tests/<test_id>/run", methods=["POST"])
def run_test(test_id):
    """Run a test."""
    # Run in background thread
    thread = threading.Thread(target=coordinator.run_test, args=(test_id,))
    thread.start()

    return jsonify({"test_id": test_id, "status": "started"})


@app.route("/api/tests/<test_id>/status")
def get_test_status(test_id):
    """Get test status."""
    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor()

    cur.execute(
        """
        SELECT status, start_time, end_time
        FROM test_runs
        WHERE test_id = %s
    """,
        (test_id,),
    )

    result = cur.fetchone()
    cur.close()
    conn.close()

    if result:
        return jsonify(
            {
                "test_id": test_id,
                "status": result[0],
                "start_time": result[1].isoformat() if result[1] else None,
                "end_time": result[2].isoformat() if result[2] else None,
            }
        )
    else:
        return jsonify({"error": "Test not found"}), 404


@app.route("/api/tests/<test_id>/results")
def get_test_results(test_id):
    """Get test results."""
    conn = psycopg2.connect(DATABASE_URL)

    # Get metrics
    metrics_df = pd.read_sql(
        """
        SELECT metric_name, metric_value, timestamp
        FROM test_metrics
        WHERE test_id = %s
        ORDER BY timestamp
    """,
        conn,
        params=(test_id,),
    )

    conn.close()

    return jsonify({"test_id": test_id, "metrics": metrics_df.to_dict("records")})


@app.route("/reports/<test_id>")
def get_report(test_id):
    """Get test report."""
    report_path = coordinator.generate_report(test_id)
    return send_file(report_path, mimetype="text/html")


@app.route("/metrics")
def metrics():
    """Prometheus metrics endpoint."""
    return generate_latest(registry), 200, {"Content-Type": "text/plain"}


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
