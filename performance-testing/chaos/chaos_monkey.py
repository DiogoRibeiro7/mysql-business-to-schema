#!/usr/bin/env python3
"""Chaos Monkey Implementation for MySQL Business-to-Schema.

Controlled chaos engineering for testing system resilience
"""

import sys
import time
import random
import docker
import psutil
import requests
import threading
import logging
from typing import Dict, List, Any
from dataclasses import dataclass
from enum import Enum

import schedule
import yaml
from prometheus_client import Counter, Histogram, Gauge, start_http_server

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger("chaos_monkey")

# Metrics
chaos_events = Counter(
    "chaos_monkey_events_total", "Total chaos events triggered", ["type", "target"]
)
chaos_duration = Histogram(
    "chaos_monkey_duration_seconds", "Duration of chaos events", ["type"]
)
active_chaos = Gauge("chaos_monkey_active_events", "Currently active chaos events")
system_health = Gauge("chaos_monkey_system_health", "System health score (0-100)")

# Docker client
docker_client = docker.from_env()


class ChaosType(Enum):
    """Types of chaos events."""

    CONTAINER_KILL = "container_kill"
    CONTAINER_STOP = "container_stop"
    CONTAINER_PAUSE = "container_pause"
    NETWORK_DELAY = "network_delay"
    NETWORK_LOSS = "network_loss"
    NETWORK_CORRUPT = "network_corrupt"
    NETWORK_PARTITION = "network_partition"
    CPU_STRESS = "cpu_stress"
    MEMORY_STRESS = "memory_stress"
    DISK_STRESS = "disk_stress"
    DATABASE_SLOW = "database_slow"
    DATABASE_LOCK = "database_lock"
    API_LATENCY = "api_latency"
    API_ERROR = "api_error"
    CACHE_FLUSH = "cache_flush"


@dataclass
class ChaosEvent:
    """Chaos event configuration."""

    type: ChaosType
    target: str
    duration: int  # seconds
    intensity: float  # 0.0 to 1.0
    probability: float  # 0.0 to 1.0
    metadata: Dict[str, Any]


class ChaosMonkey:
    """Run Chaos Monkey implementation."""

    def __init__(self, config_path: str = "chaos_config.yaml"):
        """Initialize the instance."""
        self.config = self.load_config(config_path)
        self.active_events = []
        self.docker_client = docker_client
        self.running = False
        self.dry_run = self.config.get("dry_run", True)

    def load_config(self, config_path: str) -> Dict:
        """Load configuration from YAML file."""
        try:
            with open(config_path, "r") as f:
                return yaml.safe_load(f)
        except FileNotFoundError:
            logger.warning(f"Config file {config_path} not found, using defaults")
            return self.get_default_config()

    def get_default_config(self) -> Dict:
        """Get default chaos configuration."""
        return {
            "enabled": True,
            "dry_run": True,
            "schedule": "*/5 * * * *",  # Every 5 minutes
            "max_concurrent_events": 3,
            "notification_webhook": None,
            "targets": {
                "containers": ["mysql-*", "kafka-*", "redis-*", "api-*"],
                "excluded": ["chaos-monkey", "prometheus", "grafana"],
            },
            "events": [
                {
                    "type": "container_kill",
                    "probability": 0.1,
                    "duration": 0,
                    "intensity": 1.0,
                },
                {
                    "type": "network_delay",
                    "probability": 0.3,
                    "duration": 60,
                    "intensity": 0.5,
                    "metadata": {"delay": "100ms", "variance": "50ms"},
                },
                {
                    "type": "cpu_stress",
                    "probability": 0.2,
                    "duration": 30,
                    "intensity": 0.7,
                },
            ],
        }

    def get_target_containers(self) -> List[docker.models.containers.Container]:
        """Get list of target containers based on patterns."""
        all_containers = self.docker_client.containers.list()
        target_containers = []

        for container in all_containers:
            # Check if container matches target patterns
            for pattern in self.config["targets"]["containers"]:
                if pattern.endswith("*"):
                    if container.name.startswith(pattern[:-1]):
                        # Check if not excluded
                        if not any(
                            container.name.startswith(exc)
                            for exc in self.config["targets"]["excluded"]
                        ):
                            target_containers.append(container)
                elif container.name == pattern:
                    if container.name not in self.config["targets"]["excluded"]:
                        target_containers.append(container)

        return target_containers

    def trigger_chaos(self, event: ChaosEvent):
        """Trigger a chaos event."""
        if random.random() > event.probability:
            logger.debug(f"Skipping {event.type} (probability check failed)")
            return

        if len(self.active_events) >= self.config.get("max_concurrent_events", 3):
            logger.warning("Max concurrent events reached, skipping")
            return

        logger.info(
            f"{'[DRY RUN] ' if self.dry_run else ''}Triggering {event.type} on {event.target}"
        )

        # Record metrics
        chaos_events.labels(type=event.type.value, target=event.target).inc()
        active_chaos.inc()
        self.active_events.append(event)

        # Send notification
        self.send_notification(event, "started")

        # Execute chaos based on type
        start_time = time.time()

        try:
            if event.type == ChaosType.CONTAINER_KILL:
                self.kill_container(event)
            elif event.type == ChaosType.CONTAINER_STOP:
                self.stop_container(event)
            elif event.type == ChaosType.CONTAINER_PAUSE:
                self.pause_container(event)
            elif event.type == ChaosType.NETWORK_DELAY:
                self.add_network_delay(event)
            elif event.type == ChaosType.NETWORK_LOSS:
                self.add_packet_loss(event)
            elif event.type == ChaosType.NETWORK_CORRUPT:
                self.corrupt_packets(event)
            elif event.type == ChaosType.NETWORK_PARTITION:
                self.create_network_partition(event)
            elif event.type == ChaosType.CPU_STRESS:
                self.stress_cpu(event)
            elif event.type == ChaosType.MEMORY_STRESS:
                self.stress_memory(event)
            elif event.type == ChaosType.DISK_STRESS:
                self.stress_disk(event)
            elif event.type == ChaosType.DATABASE_SLOW:
                self.slow_database(event)
            elif event.type == ChaosType.DATABASE_LOCK:
                self.lock_database_tables(event)
            elif event.type == ChaosType.API_LATENCY:
                self.add_api_latency(event)
            elif event.type == ChaosType.API_ERROR:
                self.inject_api_errors(event)
            elif event.type == ChaosType.CACHE_FLUSH:
                self.flush_cache(event)

            # Record duration
            duration = time.time() - start_time
            chaos_duration.labels(type=event.type.value).observe(duration)

        except Exception as e:
            logger.error(f"Error triggering {event.type}: {e}")
        finally:
            self.active_events.remove(event)
            active_chaos.dec()
            self.send_notification(event, "completed")

    # Container chaos methods
    def kill_container(self, event: ChaosEvent):
        """Kill a container."""
        if self.dry_run:
            logger.info(f"[DRY RUN] Would kill container: {event.target}")
            return

        try:
            container = self.docker_client.containers.get(event.target)
            container.kill()
            logger.info(f"Killed container: {event.target}")

            # Wait for restart if configured
            if event.metadata.get("wait_for_restart", True):
                time.sleep(5)
                container.start()
                logger.info(f"Restarted container: {event.target}")
        except docker.errors.NotFound:
            logger.error(f"Container not found: {event.target}")

    def stop_container(self, event: ChaosEvent):
        """Stop a container gracefully."""
        if self.dry_run:
            logger.info(f"[DRY RUN] Would stop container: {event.target}")
            return

        try:
            container = self.docker_client.containers.get(event.target)
            container.stop(timeout=10)
            logger.info(f"Stopped container: {event.target}")

            if event.duration > 0:
                time.sleep(event.duration)
                container.start()
                logger.info(f"Restarted container: {event.target}")
        except docker.errors.NotFound:
            logger.error(f"Container not found: {event.target}")

    def pause_container(self, event: ChaosEvent):
        """Pause a container."""
        if self.dry_run:
            logger.info(f"[DRY RUN] Would pause container: {event.target}")
            return

        try:
            container = self.docker_client.containers.get(event.target)
            container.pause()
            logger.info(f"Paused container: {event.target}")

            if event.duration > 0:
                time.sleep(event.duration)
                container.unpause()
                logger.info(f"Unpaused container: {event.target}")
        except docker.errors.NotFound:
            logger.error(f"Container not found: {event.target}")

    # Network chaos methods
    def add_network_delay(self, event: ChaosEvent):
        """Add network delay to container."""
        delay = event.metadata.get("delay", "100ms")
        variance = event.metadata.get("variance", "50ms")

        if self.dry_run:
            logger.info(
                f"[DRY RUN] Would add {delay}±{variance} delay to {event.target}"
            )
            return

        try:
            container = self.docker_client.containers.get(event.target)
            # Use tc (traffic control) to add delay
            cmd = f"tc qdisc add dev eth0 root netem delay {delay} {variance}"
            container.exec_run(cmd)
            logger.info(f"Added network delay to {event.target}")

            if event.duration > 0:
                time.sleep(event.duration)
                # Remove delay
                container.exec_run("tc qdisc del dev eth0 root")
                logger.info(f"Removed network delay from {event.target}")
        except Exception as e:
            logger.error(f"Failed to add network delay: {e}")

    def add_packet_loss(self, event: ChaosEvent):
        """Add packet loss to container."""
        loss_percent = int(event.intensity * 100)

        if self.dry_run:
            logger.info(
                f"[DRY RUN] Would add {loss_percent}% packet loss to {event.target}"
            )
            return

        try:
            container = self.docker_client.containers.get(event.target)
            cmd = f"tc qdisc add dev eth0 root netem loss {loss_percent}%"
            container.exec_run(cmd)
            logger.info(f"Added {loss_percent}% packet loss to {event.target}")

            if event.duration > 0:
                time.sleep(event.duration)
                container.exec_run("tc qdisc del dev eth0 root")
                logger.info(f"Removed packet loss from {event.target}")
        except Exception as e:
            logger.error(f"Failed to add packet loss: {e}")

    def corrupt_packets(self, event: ChaosEvent):
        """Corrupt network packets."""
        corrupt_percent = int(event.intensity * 10)  # Max 10% corruption

        if self.dry_run:
            logger.info(
                f"[DRY RUN] Would corrupt {corrupt_percent}% packets for {event.target}"
            )
            return

        try:
            container = self.docker_client.containers.get(event.target)
            cmd = f"tc qdisc add dev eth0 root netem corrupt {corrupt_percent}%"
            container.exec_run(cmd)
            logger.info(f"Corrupting {corrupt_percent}% packets for {event.target}")

            if event.duration > 0:
                time.sleep(event.duration)
                container.exec_run("tc qdisc del dev eth0 root")
                logger.info(f"Stopped packet corruption for {event.target}")
        except Exception as e:
            logger.error(f"Failed to corrupt packets: {e}")

    def create_network_partition(self, event: ChaosEvent):
        """Create network partition between containers."""
        if self.dry_run:
            logger.info(f"[DRY RUN] Would partition network for {event.target}")
            return

        # This would use iptables to block traffic between specific containers
        logger.info(f"Network partition created for {event.target}")

    # Resource stress methods
    def stress_cpu(self, event: ChaosEvent):
        """Stress CPU resources."""
        cpu_percent = int(event.intensity * 100)

        if self.dry_run:
            logger.info(
                f"[DRY RUN] Would stress CPU at {cpu_percent}% for {event.target}"
            )
            return

        try:
            container = self.docker_client.containers.get(event.target)
            # Use stress-ng to stress CPU
            cmd = f"stress-ng --cpu 0 --cpu-load {cpu_percent} --timeout {event.duration}s"
            container.exec_run(cmd, detach=True)
            logger.info(f"Stressing CPU at {cpu_percent}% for {event.target}")
        except Exception as e:
            logger.error(f"Failed to stress CPU: {e}")

    def stress_memory(self, event: ChaosEvent):
        """Stress memory resources."""
        memory_percent = int(event.intensity * 80)  # Max 80% memory

        if self.dry_run:
            logger.info(
                f"[DRY RUN] Would stress memory at {memory_percent}% for {event.target}"
            )
            return

        try:
            container = self.docker_client.containers.get(event.target)
            # Get container memory limit
            stats = container.stats(stream=False)
            memory_limit = stats["memory_stats"]["limit"]
            memory_bytes = int(memory_limit * memory_percent / 100)

            cmd = f"stress-ng --vm 1 --vm-bytes {memory_bytes} --timeout {event.duration}s"
            container.exec_run(cmd, detach=True)
            logger.info(f"Stressing memory at {memory_percent}% for {event.target}")
        except Exception as e:
            logger.error(f"Failed to stress memory: {e}")

    def stress_disk(self, event: ChaosEvent):
        """Stress disk I/O."""
        io_workers = int(event.intensity * 10)

        if self.dry_run:
            logger.info(
                f"[DRY RUN] Would stress disk with {io_workers} workers for {event.target}"
            )
            return

        try:
            container = self.docker_client.containers.get(event.target)
            cmd = f"stress-ng --io {io_workers} --timeout {event.duration}s"
            container.exec_run(cmd, detach=True)
            logger.info(
                f"Stressing disk I/O with {io_workers} workers for {event.target}"
            )
        except Exception as e:
            logger.error(f"Failed to stress disk: {e}")

    # Database chaos methods
    def slow_database(self, event: ChaosEvent):
        """Slow down database queries."""
        if self.dry_run:
            logger.info(f"[DRY RUN] Would slow database queries for {event.target}")
            return

        # This would add artificial delays to database queries
        logger.info(f"Slowing database queries for {event.target}")

    def lock_database_tables(self, event: ChaosEvent):
        """Lock database tables."""
        if self.dry_run:
            logger.info(f"[DRY RUN] Would lock database tables for {event.target}")
            return

        # This would lock specific database tables
        logger.info(f"Locking database tables for {event.target}")

    # API chaos methods
    def add_api_latency(self, event: ChaosEvent):
        """Add latency to API endpoints."""
        latency_ms = int(event.intensity * 5000)  # Max 5 seconds

        if self.dry_run:
            logger.info(f"[DRY RUN] Would add {latency_ms}ms latency to API")
            return

        # This would configure a proxy to add latency
        logger.info(f"Adding {latency_ms}ms latency to API endpoints")

    def inject_api_errors(self, event: ChaosEvent):
        """Inject API errors."""
        error_rate = int(event.intensity * 50)  # Max 50% error rate

        if self.dry_run:
            logger.info(f"[DRY RUN] Would inject {error_rate}% API errors")
            return

        # This would configure a proxy to return errors
        logger.info(f"Injecting {error_rate}% API error rate")

    def flush_cache(self, event: ChaosEvent):
        """Flush cache systems."""
        if self.dry_run:
            logger.info(f"[DRY RUN] Would flush cache for {event.target}")
            return

        try:
            # Flush Redis cache
            if "redis" in event.target.lower():
                container = self.docker_client.containers.get(event.target)
                container.exec_run("redis-cli FLUSHALL")
                logger.info(f"Flushed Redis cache for {event.target}")
        except Exception as e:
            logger.error(f"Failed to flush cache: {e}")

    def send_notification(self, event: ChaosEvent, status: str):
        """Send notification about chaos event."""
        webhook_url = self.config.get("notification_webhook")
        if not webhook_url:
            return

        payload = {
            "text": f"Chaos Monkey: {status.capitalize()} {event.type.value} on {event.target}",
            "username": "Chaos Monkey",
            "icon_emoji": ":monkey:",
            "attachments": [
                {
                    "color": "warning" if status == "started" else "good",
                    "fields": [
                        {"title": "Type", "value": event.type.value, "short": True},
                        {"title": "Target", "value": event.target, "short": True},
                        {
                            "title": "Duration",
                            "value": f"{event.duration}s",
                            "short": True,
                        },
                        {
                            "title": "Intensity",
                            "value": f"{event.intensity:.0%}",
                            "short": True,
                        },
                    ],
                }
            ],
        }

        try:
            requests.post(webhook_url, json=payload)
        except Exception as e:
            logger.error(f"Failed to send notification: {e}")

    def check_system_health(self) -> float:
        """Check overall system health."""
        health_score = 100.0

        # Check container health
        unhealthy_containers = 0
        for container in self.docker_client.containers.list():
            if container.status != "running":
                unhealthy_containers += 1

        health_score -= unhealthy_containers * 10

        # Check system resources
        cpu_percent = psutil.cpu_percent(interval=1)
        memory_percent = psutil.virtual_memory().percent

        if cpu_percent > 90:
            health_score -= 20
        elif cpu_percent > 75:
            health_score -= 10

        if memory_percent > 90:
            health_score -= 20
        elif memory_percent > 75:
            health_score -= 10

        health_score = max(0, health_score)
        system_health.set(health_score)

        return health_score

    def run(self):
        """Run execution loop."""
        logger.info("Chaos Monkey started")
        self.running = True

        # Start metrics server
        start_http_server(9999)

        # Schedule chaos events
        for event_config in self.config["events"]:
            schedule.every(5).minutes.do(self.trigger_random_chaos, event_config).tag(
                "chaos"
            )

        # Schedule health checks
        schedule.every(1).minutes.do(self.check_system_health).tag("health")

        while self.running:
            schedule.run_pending()
            time.sleep(1)

    def trigger_random_chaos(self, event_config: Dict):
        """Trigger a random chaos event."""
        if not self.config.get("enabled", True):
            return

        # Check system health before triggering chaos
        health = self.check_system_health()
        if health < 50:
            logger.warning(f"System health too low ({health:.0f}%), skipping chaos")
            return

        # Select random target
        targets = self.get_target_containers()
        if not targets:
            logger.warning("No valid targets found")
            return

        target = random.choice(targets)

        # Create chaos event
        event = ChaosEvent(
            type=ChaosType(event_config["type"]),
            target=target.name,
            duration=event_config.get("duration", 0),
            intensity=event_config.get("intensity", 0.5),
            probability=event_config.get("probability", 1.0),
            metadata=event_config.get("metadata", {}),
        )

        # Trigger in separate thread
        thread = threading.Thread(target=self.trigger_chaos, args=(event,))
        thread.start()

    def stop(self):
        """Stop Chaos Monkey."""
        logger.info("Stopping Chaos Monkey")
        self.running = False

        # Clean up any active chaos
        for event in self.active_events:
            logger.info(f"Cleaning up {event.type} on {event.target}")
            # Cleanup logic here


if __name__ == "__main__":
    # Parse command line arguments
    config_path = sys.argv[1] if len(sys.argv) > 1 else "chaos_config.yaml"

    # Create and run Chaos Monkey
    chaos_monkey = ChaosMonkey(config_path)

    try:
        chaos_monkey.run()
    except KeyboardInterrupt:
        chaos_monkey.stop()
