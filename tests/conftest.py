"""
Global pytest configuration and fixtures for all test types.
"""

import os
import pytest
import asyncio
import docker
import mysql.connector
import redis
from pathlib import Path
from typing import Generator, Dict, Any
from unittest.mock import Mock
import tempfile
import json
import yaml
from datetime import datetime
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from testcontainers.mysql import MySqlContainer
from testcontainers.kafka import KafkaContainer
from testcontainers.redis import RedisContainer
from faker import Faker

# Initialize Faker for test data generation
fake = Faker()

# Test environment configuration
TEST_ENV = os.getenv("TEST_ENV", "local")
CI_PIPELINE = os.getenv("CI", "false").lower() == "true"

@pytest.fixture(scope="session")
def docker_client():
    """Docker client for container management."""
    return docker.from_env()

@pytest.fixture(scope="session")
def test_config() -> Dict[str, Any]:
    """Load test configuration."""
    config_path = Path(__file__).parent / "config" / f"{TEST_ENV}.yaml"
    with open(config_path, "r") as f:
        return yaml.safe_load(f)

@pytest.fixture(scope="session")
def mysql_container():
    """MySQL test container for integration tests."""
    if CI_PIPELINE:
        # Use external MySQL in CI
        yield {
            "host": "localhost",
            "port": 3306,
            "user": "root",
            "password": "root",
            "database": "test_db"
        }
    else:
        with MySqlContainer("mysql:8.0") as mysql:
            yield {
                "host": mysql.get_container_host_ip(),
                "port": mysql.get_exposed_port(3306),
                "user": mysql.username,
                "password": mysql.password,
                "database": mysql.database
            }

@pytest.fixture(scope="function")
def mysql_connection(mysql_container):
    """MySQL connection for tests."""
    conn = mysql.connector.connect(
        host=mysql_container["host"],
        port=mysql_container["port"],
        user=mysql_container["user"],
        password=mysql_container["password"],
        database=mysql_container["database"]
    )
    yield conn
    conn.close()

@pytest.fixture(scope="function")
def mysql_cursor(mysql_connection):
    """MySQL cursor for test queries."""
    cursor = mysql_connection.cursor(dictionary=True)
    yield cursor
    cursor.close()

@pytest.fixture(scope="session")
def kafka_container():
    """Kafka test container for CDC tests."""
    if CI_PIPELINE:
        yield {
            "bootstrap_servers": "localhost:9092"
        }
    else:
        with KafkaContainer() as kafka:
            yield {
                "bootstrap_servers": kafka.get_bootstrap_server()
            }

@pytest.fixture(scope="session")
def redis_container():
    """Redis test container for caching tests."""
    if CI_PIPELINE:
        yield {
            "host": "localhost",
            "port": 6379
        }
    else:
        with RedisContainer() as redis_cont:
            yield {
                "host": redis_cont.get_container_host_ip(),
                "port": redis_cont.get_exposed_port(6379)
            }

@pytest.fixture(scope="function")
def redis_client(redis_container):
    """Redis client for tests."""
    client = redis.StrictRedis(
        host=redis_container["host"],
        port=redis_container["port"],
        decode_responses=True
    )
    yield client
    client.flushdb()

@pytest.fixture(scope="function")
def sqlalchemy_session(mysql_container):
    """SQLAlchemy session for ORM tests."""
    engine = create_engine(
        f"mysql+mysqlconnector://{mysql_container['user']}:{mysql_container['password']}"
        f"@{mysql_container['host']}:{mysql_container['port']}/{mysql_container['database']}"
    )
    SessionLocal = sessionmaker(bind=engine)
    session = SessionLocal()
    yield session
    session.close()

@pytest.fixture(scope="function")
def temp_schema_file():
    """Temporary schema file for testing."""
    with tempfile.NamedTemporaryFile(mode='w', suffix='.sql', delete=False) as f:
        f.write("""
        CREATE TABLE test_users (
            id INT PRIMARY KEY AUTO_INCREMENT,
            username VARCHAR(50) NOT NULL,
            email VARCHAR(100) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        """)
        temp_path = f.name
    yield temp_path
    os.unlink(temp_path)

@pytest.fixture(scope="function")
def mock_ml_model():
    """Mock ML model for testing predictions."""
    model = Mock()
    model.predict.return_value = [0.85, 0.12, 0.03]
    model.predict_proba.return_value = [[0.15, 0.85]]
    return model

@pytest.fixture(scope="function")
def sample_metrics():
    """Sample performance metrics for testing."""
    return {
        "query_time": 0.123,
        "rows_examined": 1000,
        "rows_sent": 10,
        "index_usage": 0.95,
        "cpu_usage": 45.2,
        "memory_usage": 512,
        "timestamp": datetime.utcnow().isoformat()
    }

@pytest.fixture(scope="function")
def sample_schema():
    """Sample database schema for testing."""
    return {
        "database": "test_db",
        "tables": [
            {
                "name": "users",
                "columns": [
                    {"name": "id", "type": "INT", "primary_key": True},
                    {"name": "username", "type": "VARCHAR(50)"},
                    {"name": "email", "type": "VARCHAR(100)"}
                ]
            },
            {
                "name": "orders",
                "columns": [
                    {"name": "id", "type": "INT", "primary_key": True},
                    {"name": "user_id", "type": "INT", "foreign_key": "users.id"},
                    {"name": "total", "type": "DECIMAL(10,2)"}
                ]
            }
        ]
    }

@pytest.fixture(scope="function")
def graphql_client(test_config):
    """GraphQL test client."""
    from graphql import GraphQLClient

    endpoint = test_config.get("graphql_endpoint", "http://localhost:4000/graphql")
    client = GraphQLClient(endpoint)
    return client

@pytest.fixture(scope="session")
def event_loop():
    """Event loop for async tests."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()

@pytest.fixture(scope="function")
def mock_kafka_producer():
    """Mock Kafka producer for CDC tests."""
    producer = Mock()
    producer.send.return_value = Mock(get=Mock(return_value={"offset": 1, "partition": 0}))
    producer.flush.return_value = None
    return producer

@pytest.fixture(scope="function")
def test_data_generator():
    """Generate test data using Faker."""
    def generate_users(count=10):
        return [
            {
                "username": fake.user_name(),
                "email": fake.email(),
                "first_name": fake.first_name(),
                "last_name": fake.last_name(),
                "created_at": fake.date_time_this_year()
            }
            for _ in range(count)
        ]

    def generate_orders(count=10):
        return [
            {
                "user_id": fake.random_int(1, 100),
                "total": fake.pydecimal(left_digits=5, right_digits=2, positive=True),
                "status": fake.random_element(["pending", "completed", "cancelled"]),
                "created_at": fake.date_time_this_month()
            }
            for _ in range(count)
        ]

    return {
        "users": generate_users,
        "orders": generate_orders
    }

@pytest.fixture(scope="function")
def performance_monitor():
    """Performance monitoring for tests."""
    import time
    import psutil

    class PerformanceMonitor:
        def __init__(self):
            self.start_time = None
            self.start_memory = None
            self.start_cpu = None

        def start(self):
            self.start_time = time.time()
            self.start_memory = psutil.Process().memory_info().rss / 1024 / 1024
            self.start_cpu = psutil.cpu_percent(interval=0.1)

        def stop(self):
            return {
                "duration": time.time() - self.start_time,
                "memory_used": psutil.Process().memory_info().rss / 1024 / 1024 - self.start_memory,
                "cpu_average": psutil.cpu_percent(interval=0.1)
            }

    return PerformanceMonitor()

@pytest.fixture(autouse=True)
def cleanup_test_artifacts():
    """Cleanup test artifacts after each test."""
    yield
    # Cleanup temp files
    temp_dir = Path(tempfile.gettempdir())
    for pattern in ["test_*.sql", "test_*.json", "test_*.log"]:
        for file in temp_dir.glob(pattern):
            if file.is_file() and file.stat().st_mtime < (datetime.now().timestamp() - 3600):
                file.unlink()

# Markers for test categorization
def pytest_configure(config):
    """Configure pytest markers."""
    config.addinivalue_line("markers", "unit: Unit tests")
    config.addinivalue_line("markers", "integration: Integration tests")
    config.addinivalue_line("markers", "e2e: End-to-end tests")
    config.addinivalue_line("markers", "performance: Performance tests")
    config.addinivalue_line("markers", "chaos: Chaos engineering tests")
    config.addinivalue_line("markers", "slow: Slow tests")
    config.addinivalue_line("markers", "smoke: Smoke tests")
    config.addinivalue_line("markers", "regression: Regression tests")