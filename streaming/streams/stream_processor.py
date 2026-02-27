#!/usr/bin/env python3
"""
Kafka Streams Processor for MySQL Business-to-Schema

Processes CDC events and performs:
- Data enrichment
- Aggregations
- Anomaly detection
- Real-time analytics
"""

import os
import json
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional
from dataclasses import dataclass
from enum import Enum

from confluent_kafka import Consumer, Producer, KafkaError, KafkaException
from confluent_kafka.schema_registry import SchemaRegistryClient
from confluent_kafka.serialization import (
    StringSerializer,
    StringDeserializer,
    SerializationContext,
    MessageField,
)
from confluent_kafka.schema_registry.avro import AvroSerializer, AvroDeserializer
import avro.schema

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


class EventType(Enum):
    """CDC Event Types"""

    INSERT = "insert"
    UPDATE = "update"
    DELETE = "delete"
    SNAPSHOT = "snapshot"


@dataclass
class CDCEvent:
    """Represents a Change Data Capture event"""

    event_type: EventType
    database: str
    table: str
    timestamp: datetime
    key: Dict[str, Any]
    before: Optional[Dict[str, Any]]
    after: Optional[Dict[str, Any]]
    source: Dict[str, Any]


class StreamProcessor:
    """Main stream processing application"""

    def __init__(self, config: Dict[str, Any]):
        """Initialize the stream processor"""
        self.config = config
        self.running = False

        # Kafka configuration
        self.bootstrap_servers = config.get("bootstrap_servers", "localhost:9092")
        self.schema_registry_url = config.get(
            "schema_registry_url", "http://localhost:8081"
        )
        self.group_id = config.get("group_id", "stream-processor")

        # Topics
        self.input_topics = config.get("input_topics", ["cdc.ecommerce.orders"])
        self.output_topics = config.get(
            "output_topics",
            {
                "enriched": "enriched-data",
                "aggregated": "aggregated-data",
                "anomalies": "anomalies",
            },
        )

        # Initialize clients
        self.consumer = None
        self.producer = None
        self.schema_registry = None

        # State stores (in production, use external state store)
        self.state = {
            "customer_profiles": {},
            "product_catalog": {},
            "aggregations": {},
            "anomaly_scores": {},
        }

        # Metrics
        self.metrics = {
            "events_processed": 0,
            "events_enriched": 0,
            "anomalies_detected": 0,
            "errors": 0,
        }

    def initialize(self):
        """Initialize Kafka clients"""
        try:
            # Consumer configuration
            consumer_config = {
                "bootstrap.servers": self.bootstrap_servers,
                "group.id": self.group_id,
                "enable.auto.commit": False,
                "auto.offset.reset": "earliest",
                "max.poll.interval.ms": 300000,
                "session.timeout.ms": 45000,
                "heartbeat.interval.ms": 3000,
            }

            # Producer configuration
            producer_config = {
                "bootstrap.servers": self.bootstrap_servers,
                "acks": "all",
                "retries": 3,
                "max.in.flight.requests.per.connection": 5,
                "compression.type": "snappy",
                "linger.ms": 10,
                "batch.size": 16384,
            }

            # Schema Registry configuration
            schema_registry_config = {"url": self.schema_registry_url}

            # Initialize clients
            self.consumer = Consumer(consumer_config)
            self.producer = Producer(producer_config)
            self.schema_registry = SchemaRegistryClient(schema_registry_config)

            # Subscribe to topics
            self.consumer.subscribe(self.input_topics)

            logger.info(
                f"Stream processor initialized. Subscribed to: {self.input_topics}"
            )

        except Exception as e:
            logger.error(f"Failed to initialize stream processor: {e}")
            raise

    def process_event(self, event: CDCEvent) -> Dict[str, Any]:
        """Process a single CDC event"""
        processed = {
            "original_event": event.__dict__,
            "processing_timestamp": datetime.now().isoformat(),
            "enrichments": {},
            "aggregations": {},
            "flags": [],
        }

        # Route based on table
        if event.table == "orders":
            processed = self._process_order_event(event, processed)
        elif event.table == "customers":
            processed = self._process_customer_event(event, processed)
        elif event.table == "products":
            processed = self._process_product_event(event, processed)
        elif event.table == "transactions":
            processed = self._process_transaction_event(event, processed)

        # Detect anomalies
        anomalies = self._detect_anomalies(event, processed)
        if anomalies:
            processed["anomalies"] = anomalies
            self.metrics["anomalies_detected"] += 1

        return processed

    def _process_order_event(self, event: CDCEvent, processed: Dict) -> Dict:
        """Process order events"""
        if event.event_type == EventType.INSERT:
            # New order created
            order_data = event.after

            # Enrich with customer data
            customer_id = order_data.get("customer_id")
            if customer_id:
                customer = self._get_customer_profile(customer_id)
                if customer:
                    processed["enrichments"]["customer"] = customer
                    processed["enrichments"]["customer_segment"] = (
                        self._get_customer_segment(customer)
                    )

            # Calculate order metrics
            processed["aggregations"]["order_value"] = order_data.get("total_amount", 0)
            processed["aggregations"]["item_count"] = order_data.get("item_count", 0)

            # Check for high-value order
            if order_data.get("total_amount", 0) > 1000:
                processed["flags"].append("HIGH_VALUE_ORDER")

            # Update customer lifetime value
            self._update_customer_ltv(customer_id, order_data.get("total_amount", 0))

        elif event.event_type == EventType.UPDATE:
            # Order updated
            before = event.before
            after = event.after

            # Track status changes
            if before.get("status") != after.get("status"):
                processed["enrichments"]["status_change"] = {
                    "from": before.get("status"),
                    "to": after.get("status"),
                    "timestamp": datetime.now().isoformat(),
                }

                # Check for cancellation
                if after.get("status") == "cancelled":
                    processed["flags"].append("ORDER_CANCELLED")

        return processed

    def _process_customer_event(self, event: CDCEvent, processed: Dict) -> Dict:
        """Process customer events"""
        if event.event_type == EventType.INSERT:
            # New customer registered
            customer_data = event.after
            customer_id = customer_data.get("customer_id")

            # Initialize customer profile
            self.state["customer_profiles"][customer_id] = {
                "registration_date": datetime.now().isoformat(),
                "total_orders": 0,
                "total_spent": 0,
                "last_activity": datetime.now().isoformat(),
                "segment": "new",
                "risk_score": 0,
            }

            processed["flags"].append("NEW_CUSTOMER")

        elif event.event_type == EventType.UPDATE:
            # Customer profile updated
            before = event.before
            after = event.after

            # Check for email change (potential fraud)
            if before.get("email") != after.get("email"):
                processed["flags"].append("EMAIL_CHANGED")
                processed["enrichments"]["email_change"] = {
                    "from": before.get("email"),
                    "to": after.get("email"),
                }

        return processed

    def _process_product_event(self, event: CDCEvent, processed: Dict) -> Dict:
        """Process product events"""
        if event.event_type == EventType.UPDATE:
            before = event.before
            after = event.after

            # Track price changes
            if before.get("price") != after.get("price"):
                price_change = {
                    "product_id": after.get("product_id"),
                    "old_price": before.get("price"),
                    "new_price": after.get("price"),
                    "change_percentage": (
                        (after.get("price", 0) - before.get("price", 0))
                        / before.get("price", 1)
                    )
                    * 100,
                }
                processed["enrichments"]["price_change"] = price_change

                # Alert on significant price changes
                if abs(price_change["change_percentage"]) > 20:
                    processed["flags"].append("SIGNIFICANT_PRICE_CHANGE")

            # Track inventory changes
            if before.get("stock_quantity") != after.get("stock_quantity"):
                if after.get("stock_quantity", 0) <= 10:
                    processed["flags"].append("LOW_INVENTORY")
                if after.get("stock_quantity", 0) == 0:
                    processed["flags"].append("OUT_OF_STOCK")

        return processed

    def _process_transaction_event(self, event: CDCEvent, processed: Dict) -> Dict:
        """Process financial transaction events"""
        if event.event_type == EventType.INSERT:
            transaction = event.after
            amount = transaction.get("amount", 0)

            # Fraud detection rules
            fraud_score = 0

            # Check for unusual amount
            if amount > 10000:
                fraud_score += 30
                processed["flags"].append("HIGH_AMOUNT_TRANSACTION")

            # Check for rapid transactions
            customer_id = transaction.get("customer_id")
            if customer_id:
                last_transaction = self._get_last_transaction(customer_id)
                if last_transaction:
                    time_diff = datetime.now() - datetime.fromisoformat(
                        last_transaction["timestamp"]
                    )
                    if time_diff < timedelta(minutes=1):
                        fraud_score += 40
                        processed["flags"].append("RAPID_TRANSACTION")

            # Check for unusual location
            location = transaction.get("location")
            if location and self._is_unusual_location(customer_id, location):
                fraud_score += 30
                processed["flags"].append("UNUSUAL_LOCATION")

            processed["enrichments"]["fraud_score"] = fraud_score
            if fraud_score >= 70:
                processed["flags"].append("POTENTIAL_FRAUD")

        return processed

    def _detect_anomalies(self, event: CDCEvent, processed: Dict) -> List[Dict]:
        """Detect anomalies in the event stream"""
        anomalies = []

        # Example: Detect unusual patterns
        if event.table == "orders":
            order_data = event.after or {}

            # Unusual order timing
            order_hour = datetime.now().hour
            if 2 <= order_hour <= 5:  # Orders between 2 AM and 5 AM
                anomalies.append(
                    {
                        "type": "unusual_timing",
                        "description": "Order placed during unusual hours",
                        "severity": "low",
                        "hour": order_hour,
                    }
                )

            # Unusual order size
            total_amount = order_data.get("total_amount", 0)
            avg_order_value = self._get_average_order_value()
            if avg_order_value and total_amount > avg_order_value * 5:
                anomalies.append(
                    {
                        "type": "unusual_amount",
                        "description": "Order amount significantly above average",
                        "severity": "medium",
                        "amount": total_amount,
                        "average": avg_order_value,
                    }
                )

        return anomalies

    def _get_customer_profile(self, customer_id: str) -> Optional[Dict]:
        """Get customer profile from state store"""
        return self.state["customer_profiles"].get(customer_id)

    def _get_customer_segment(self, customer: Dict) -> str:
        """Determine customer segment based on behavior"""
        total_spent = customer.get("total_spent", 0)
        total_orders = customer.get("total_orders", 0)

        if total_spent > 10000:
            return "vip"
        elif total_spent > 1000:
            return "premium"
        elif total_orders > 5:
            return "regular"
        else:
            return "new"

    def _update_customer_ltv(self, customer_id: str, amount: float):
        """Update customer lifetime value"""
        if customer_id not in self.state["customer_profiles"]:
            self.state["customer_profiles"][customer_id] = {
                "total_orders": 0,
                "total_spent": 0,
            }

        profile = self.state["customer_profiles"][customer_id]
        profile["total_orders"] += 1
        profile["total_spent"] += amount
        profile["last_activity"] = datetime.now().isoformat()

    def _get_last_transaction(self, customer_id: str) -> Optional[Dict]:
        """Get last transaction for a customer"""
        # In production, query from database or cache
        return None

    def _is_unusual_location(self, customer_id: str, location: str) -> bool:
        """Check if location is unusual for customer"""
        # In production, implement location analysis
        return False

    def _get_average_order_value(self) -> float:
        """Get average order value from aggregations"""
        aggregations = self.state.get("aggregations", {})
        return aggregations.get("avg_order_value", 100.0)

    def produce_output(self, topic: str, key: str, value: Dict):
        """Produce message to output topic"""
        try:
            self.producer.produce(
                topic=topic,
                key=key,
                value=json.dumps(value),
                callback=self._delivery_report,
            )
            self.producer.poll(0)
        except Exception as e:
            logger.error(f"Failed to produce message: {e}")
            self.metrics["errors"] += 1

    def _delivery_report(self, err, msg):
        """Callback for message delivery reports"""
        if err is not None:
            logger.error(f"Message delivery failed: {err}")
        else:
            logger.debug(f"Message delivered to {msg.topic()} [{msg.partition()}]")

    def run(self):
        """Main processing loop"""
        self.running = True
        logger.info("Starting stream processor...")

        try:
            while self.running:
                # Poll for messages
                msg = self.consumer.poll(timeout=1.0)

                if msg is None:
                    continue

                if msg.error():
                    if msg.error().code() == KafkaError._PARTITION_EOF:
                        continue
                    else:
                        raise KafkaException(msg.error())

                # Parse CDC event
                try:
                    event_data = json.loads(msg.value())
                    event = self._parse_cdc_event(event_data)

                    # Process event
                    processed = self.process_event(event)
                    self.metrics["events_processed"] += 1

                    # Produce enriched data
                    if processed.get("enrichments"):
                        self.produce_output(
                            self.output_topics["enriched"], msg.key(), processed
                        )
                        self.metrics["events_enriched"] += 1

                    # Produce anomalies
                    if processed.get("anomalies"):
                        for anomaly in processed["anomalies"]:
                            self.produce_output(
                                self.output_topics["anomalies"], msg.key(), anomaly
                            )

                    # Commit offset
                    self.consumer.commit()

                except Exception as e:
                    logger.error(f"Error processing message: {e}")
                    self.metrics["errors"] += 1

                # Log metrics periodically
                if self.metrics["events_processed"] % 1000 == 0:
                    logger.info(f"Metrics: {self.metrics}")

        except KeyboardInterrupt:
            logger.info("Stream processor interrupted by user")
        finally:
            self.shutdown()

    def _parse_cdc_event(self, data: Dict) -> CDCEvent:
        """Parse raw CDC event into CDCEvent object"""
        # This depends on the CDC format (Debezium, etc.)
        return CDCEvent(
            event_type=EventType(data.get("op", "insert")),
            database=data.get("source", {}).get("db"),
            table=data.get("source", {}).get("table"),
            timestamp=datetime.fromisoformat(data.get("ts_ms", "")),
            key=data.get("key", {}),
            before=data.get("before"),
            after=data.get("after"),
            source=data.get("source", {}),
        )

    def shutdown(self):
        """Graceful shutdown"""
        logger.info("Shutting down stream processor...")
        self.running = False

        if self.consumer:
            self.consumer.close()
        if self.producer:
            self.producer.flush()

        logger.info(f"Final metrics: {self.metrics}")


def main():
    """Main entry point"""
    config = {
        "bootstrap_servers": os.getenv("BOOTSTRAP_SERVERS", "localhost:9092"),
        "schema_registry_url": os.getenv(
            "SCHEMA_REGISTRY_URL", "http://localhost:8081"
        ),
        "group_id": os.getenv("GROUP_ID", "stream-processor"),
        "input_topics": os.getenv("INPUT_TOPICS", "cdc.ecommerce.orders").split(","),
        "output_topics": {
            "enriched": os.getenv("ENRICHED_TOPIC", "enriched-data"),
            "aggregated": os.getenv("AGGREGATED_TOPIC", "aggregated-data"),
            "anomalies": os.getenv("ANOMALIES_TOPIC", "anomalies"),
        },
    }

    processor = StreamProcessor(config)
    processor.initialize()
    processor.run()


if __name__ == "__main__":
    main()
