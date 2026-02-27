#!/usr/bin/env python3
"""
Streaming Infrastructure Manager for MySQL Business-to-Schema

Manages Kafka, connectors, and streaming applications.
"""

import os
import sys
import json
import time
import requests
import subprocess
import logging
from pathlib import Path
from typing import Dict, List, Any, Optional
from enum import Enum
import yaml

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


class ServiceStatus(Enum):
    """Service health status"""

    HEALTHY = "healthy"
    UNHEALTHY = "unhealthy"
    STARTING = "starting"
    UNKNOWN = "unknown"


class StreamManager:
    """Manages streaming infrastructure"""

    def __init__(self, config_path: str = None):
        """Initialize stream manager"""
        self.config = self._load_config(config_path)

        # Service URLs
        self.kafka_connect_url = self.config.get(
            "kafka_connect_url", "http://localhost:8083"
        )
        self.schema_registry_url = self.config.get(
            "schema_registry_url", "http://localhost:8081"
        )
        self.ksql_url = self.config.get("ksql_url", "http://localhost:8088")
        self.kafka_ui_url = self.config.get("kafka_ui_url", "http://localhost:8080")

        # Paths
        self.connectors_path = Path(__file__).parent / "connectors"
        self.ksql_path = Path(__file__).parent / "ksql"
        self.docker_compose_file = Path(__file__).parent / "docker-compose.kafka.yml"

    def _load_config(self, config_path: str = None) -> Dict:
        """Load configuration from file or environment"""
        config = {
            "kafka_connect_url": os.getenv(
                "KAFKA_CONNECT_URL", "http://localhost:8083"
            ),
            "schema_registry_url": os.getenv(
                "SCHEMA_REGISTRY_URL", "http://localhost:8081"
            ),
            "ksql_url": os.getenv("KSQL_URL", "http://localhost:8088"),
            "kafka_ui_url": os.getenv("KAFKA_UI_URL", "http://localhost:8080"),
            "bootstrap_servers": os.getenv("KAFKA_BOOTSTRAP_SERVERS", "localhost:9092"),
        }

        if config_path and Path(config_path).exists():
            with open(config_path, "r") as f:
                file_config = yaml.safe_load(f)
                config.update(file_config)

        return config

    # ============================================================================
    # Docker Compose Management
    # ============================================================================

    def start_infrastructure(self, services: List[str] = None):
        """Start streaming infrastructure using Docker Compose"""
        logger.info("Starting streaming infrastructure...")

        cmd = ["docker-compose", "-f", str(self.docker_compose_file), "up", "-d"]
        if services:
            cmd.extend(services)

        try:
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            logger.info("Infrastructure started successfully")
            return True
        except subprocess.CalledProcessError as e:
            logger.error(f"Failed to start infrastructure: {e.stderr}")
            return False

    def stop_infrastructure(self):
        """Stop streaming infrastructure"""
        logger.info("Stopping streaming infrastructure...")

        cmd = ["docker-compose", "-f", str(self.docker_compose_file), "down"]

        try:
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            logger.info("Infrastructure stopped successfully")
            return True
        except subprocess.CalledProcessError as e:
            logger.error(f"Failed to stop infrastructure: {e.stderr}")
            return False

    def get_infrastructure_status(self) -> Dict[str, str]:
        """Get status of all infrastructure services"""
        cmd = [
            "docker-compose",
            "-f",
            str(self.docker_compose_file),
            "ps",
            "--format",
            "json",
        ]

        try:
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            services = json.loads(result.stdout) if result.stdout else []

            status = {}
            for service in services:
                name = service.get("Service", "")
                state = service.get("State", "unknown")
                status[name] = state

            return status
        except (subprocess.CalledProcessError, json.JSONDecodeError) as e:
            logger.error(f"Failed to get infrastructure status: {e}")
            return {}

    # ============================================================================
    # Kafka Connect Management
    # ============================================================================

    def check_kafka_connect_health(self) -> ServiceStatus:
        """Check Kafka Connect health"""
        try:
            response = requests.get(f"{self.kafka_connect_url}/")
            if response.status_code == 200:
                return ServiceStatus.HEALTHY
            return ServiceStatus.UNHEALTHY
        except requests.RequestException:
            return ServiceStatus.UNKNOWN

    def list_connectors(self) -> List[str]:
        """List all deployed connectors"""
        try:
            response = requests.get(f"{self.kafka_connect_url}/connectors")
            response.raise_for_status()
            return response.json()
        except requests.RequestException as e:
            logger.error(f"Failed to list connectors: {e}")
            return []

    def get_connector_status(self, name: str) -> Dict:
        """Get connector status"""
        try:
            response = requests.get(
                f"{self.kafka_connect_url}/connectors/{name}/status"
            )
            response.raise_for_status()
            return response.json()
        except requests.RequestException as e:
            logger.error(f"Failed to get connector status: {e}")
            return {}

    def deploy_connector(self, connector_file: str) -> bool:
        """Deploy a connector from JSON file"""
        connector_path = self.connectors_path / connector_file

        if not connector_path.exists():
            logger.error(f"Connector file not found: {connector_path}")
            return False

        try:
            with open(connector_path, "r") as f:
                config = json.load(f)

            name = config.get("name")
            logger.info(f"Deploying connector: {name}")

            # Check if connector exists
            existing = self.list_connectors()
            if name in existing:
                # Update existing connector
                response = requests.put(
                    f"{self.kafka_connect_url}/connectors/{name}/config",
                    json=config.get("config", {}),
                    headers={"Content-Type": "application/json"},
                )
            else:
                # Create new connector
                response = requests.post(
                    f"{self.kafka_connect_url}/connectors",
                    json=config,
                    headers={"Content-Type": "application/json"},
                )

            response.raise_for_status()
            logger.info(f"Connector {name} deployed successfully")
            return True

        except (json.JSONDecodeError, requests.RequestException) as e:
            logger.error(f"Failed to deploy connector: {e}")
            return False

    def delete_connector(self, name: str) -> bool:
        """Delete a connector"""
        try:
            response = requests.delete(f"{self.kafka_connect_url}/connectors/{name}")
            response.raise_for_status()
            logger.info(f"Connector {name} deleted successfully")
            return True
        except requests.RequestException as e:
            logger.error(f"Failed to delete connector: {e}")
            return False

    def pause_connector(self, name: str) -> bool:
        """Pause a connector"""
        try:
            response = requests.put(f"{self.kafka_connect_url}/connectors/{name}/pause")
            response.raise_for_status()
            logger.info(f"Connector {name} paused")
            return True
        except requests.RequestException as e:
            logger.error(f"Failed to pause connector: {e}")
            return False

    def resume_connector(self, name: str) -> bool:
        """Resume a paused connector"""
        try:
            response = requests.put(
                f"{self.kafka_connect_url}/connectors/{name}/resume"
            )
            response.raise_for_status()
            logger.info(f"Connector {name} resumed")
            return True
        except requests.RequestException as e:
            logger.error(f"Failed to resume connector: {e}")
            return False

    def restart_connector(self, name: str) -> bool:
        """Restart a connector"""
        try:
            response = requests.post(
                f"{self.kafka_connect_url}/connectors/{name}/restart"
            )
            response.raise_for_status()
            logger.info(f"Connector {name} restarted")
            return True
        except requests.RequestException as e:
            logger.error(f"Failed to restart connector: {e}")
            return False

    # ============================================================================
    # KSQL Management
    # ============================================================================

    def check_ksql_health(self) -> ServiceStatus:
        """Check KSQL server health"""
        try:
            response = requests.get(f"{self.ksql_url}/info")
            if response.status_code == 200:
                return ServiceStatus.HEALTHY
            return ServiceStatus.UNHEALTHY
        except requests.RequestException:
            return ServiceStatus.UNKNOWN

    def execute_ksql(self, statement: str) -> Dict:
        """Execute a KSQL statement"""
        try:
            payload = {"ksql": statement, "streamsProperties": {}}
            response = requests.post(
                f"{self.ksql_url}/ksql",
                json=payload,
                headers={"Content-Type": "application/vnd.ksql.v1+json"},
            )
            response.raise_for_status()
            return response.json()
        except requests.RequestException as e:
            logger.error(f"Failed to execute KSQL: {e}")
            return {}

    def deploy_ksql_queries(self, query_file: str) -> bool:
        """Deploy KSQL queries from file"""
        query_path = self.ksql_path / query_file

        if not query_path.exists():
            logger.error(f"Query file not found: {query_path}")
            return False

        try:
            with open(query_path, "r") as f:
                queries = f.read()

            # Split queries by semicolon
            statements = [q.strip() for q in queries.split(";") if q.strip()]

            success_count = 0
            for statement in statements:
                # Skip comments
                if statement.startswith("--") or not statement:
                    continue

                logger.info(f"Executing: {statement[:50]}...")
                result = self.execute_ksql(statement + ";")

                if result:
                    success_count += 1
                    logger.debug(f"Result: {result}")

            logger.info(
                f"Deployed {success_count}/{len(statements)} queries successfully"
            )
            return success_count > 0

        except Exception as e:
            logger.error(f"Failed to deploy KSQL queries: {e}")
            return False

    def list_ksql_streams(self) -> List[Dict]:
        """List all KSQL streams"""
        result = self.execute_ksql("SHOW STREAMS;")
        return result.get("streams", []) if result else []

    def list_ksql_tables(self) -> List[Dict]:
        """List all KSQL tables"""
        result = self.execute_ksql("SHOW TABLES;")
        return result.get("tables", []) if result else []

    # ============================================================================
    # Schema Registry Management
    # ============================================================================

    def check_schema_registry_health(self) -> ServiceStatus:
        """Check Schema Registry health"""
        try:
            response = requests.get(f"{self.schema_registry_url}/subjects")
            if response.status_code == 200:
                return ServiceStatus.HEALTHY
            return ServiceStatus.UNHEALTHY
        except requests.RequestException:
            return ServiceStatus.UNKNOWN

    def list_schemas(self) -> List[str]:
        """List all registered schemas"""
        try:
            response = requests.get(f"{self.schema_registry_url}/subjects")
            response.raise_for_status()
            return response.json()
        except requests.RequestException as e:
            logger.error(f"Failed to list schemas: {e}")
            return []

    def get_schema(self, subject: str, version: str = "latest") -> Dict:
        """Get schema for a subject"""
        try:
            response = requests.get(
                f"{self.schema_registry_url}/subjects/{subject}/versions/{version}"
            )
            response.raise_for_status()
            return response.json()
        except requests.RequestException as e:
            logger.error(f"Failed to get schema: {e}")
            return {}

    # ============================================================================
    # Monitoring and Diagnostics
    # ============================================================================

    def health_check(self) -> Dict[str, ServiceStatus]:
        """Perform health check on all services"""
        logger.info("Performing health check...")

        health = {
            "kafka_connect": self.check_kafka_connect_health(),
            "schema_registry": self.check_schema_registry_health(),
            "ksql": self.check_ksql_health(),
        }

        # Check Docker containers
        container_status = self.get_infrastructure_status()
        for service, state in container_status.items():
            if state == "running":
                health[f"docker_{service}"] = ServiceStatus.HEALTHY
            else:
                health[f"docker_{service}"] = ServiceStatus.UNHEALTHY

        return health

    def get_metrics(self) -> Dict:
        """Get streaming metrics"""
        metrics = {"timestamp": time.time(), "connectors": {}, "ksql": {}}

        # Get connector metrics
        connectors = self.list_connectors()
        for connector in connectors:
            status = self.get_connector_status(connector)
            metrics["connectors"][connector] = {
                "state": status.get("connector", {}).get("state"),
                "tasks": len(status.get("tasks", [])),
                "type": status.get("type"),
            }

        # Get KSQL metrics
        metrics["ksql"]["streams"] = len(self.list_ksql_streams())
        metrics["ksql"]["tables"] = len(self.list_ksql_tables())

        return metrics

    # ============================================================================
    # Deployment Automation
    # ============================================================================

    def deploy_all(self) -> bool:
        """Deploy complete streaming infrastructure"""
        logger.info("Deploying complete streaming infrastructure...")

        # Start infrastructure
        if not self.start_infrastructure():
            logger.error("Failed to start infrastructure")
            return False

        # Wait for services to be ready
        logger.info("Waiting for services to be ready...")
        time.sleep(30)

        # Deploy connectors
        logger.info("Deploying CDC connectors...")
        connector_files = [
            "mysql-cdc-connector.json",
            "postgres-cdc-connector.json",
            "mongodb-cdc-connector.json",
        ]

        for connector_file in connector_files:
            if (self.connectors_path / connector_file).exists():
                self.deploy_connector(connector_file)
                time.sleep(5)

        # Deploy KSQL queries
        logger.info("Deploying KSQL analytics...")
        if (self.ksql_path / "analytics_queries.sql").exists():
            self.deploy_ksql_queries("analytics_queries.sql")

        logger.info("Deployment complete!")
        return True

    def teardown(self) -> bool:
        """Teardown streaming infrastructure"""
        logger.info("Tearing down streaming infrastructure...")

        # Delete all connectors
        connectors = self.list_connectors()
        for connector in connectors:
            self.delete_connector(connector)

        # Stop infrastructure
        return self.stop_infrastructure()


def main():
    """CLI interface for stream manager"""
    import argparse

    parser = argparse.ArgumentParser(description="Streaming Infrastructure Manager")
    parser.add_argument(
        "command",
        choices=[
            "deploy",
            "teardown",
            "status",
            "health",
            "list-connectors",
            "deploy-connector",
            "delete-connector",
            "restart-connector",
            "list-streams",
            "list-tables",
            "metrics",
        ],
        help="Command to execute",
    )
    parser.add_argument("--connector", help="Connector name or file")
    parser.add_argument("--config", help="Configuration file path")

    args = parser.parse_args()

    manager = StreamManager(args.config)

    if args.command == "deploy":
        manager.deploy_all()
    elif args.command == "teardown":
        manager.teardown()
    elif args.command == "status":
        status = manager.get_infrastructure_status()
        print(json.dumps(status, indent=2))
    elif args.command == "health":
        health = manager.health_check()
        for service, status in health.items():
            print(f"{service}: {status.value}")
    elif args.command == "list-connectors":
        connectors = manager.list_connectors()
        for connector in connectors:
            print(connector)
    elif args.command == "deploy-connector":
        if args.connector:
            manager.deploy_connector(args.connector)
    elif args.command == "delete-connector":
        if args.connector:
            manager.delete_connector(args.connector)
    elif args.command == "restart-connector":
        if args.connector:
            manager.restart_connector(args.connector)
    elif args.command == "list-streams":
        streams = manager.list_ksql_streams()
        for stream in streams:
            print(stream)
    elif args.command == "list-tables":
        tables = manager.list_ksql_tables()
        for table in tables:
            print(table)
    elif args.command == "metrics":
        metrics = manager.get_metrics()
        print(json.dumps(metrics, indent=2))


if __name__ == "__main__":
    main()
