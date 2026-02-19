#!/usr/bin/env python3
"""
CDC Consumer for processing MySQL change events from Debezium
Handles real-time data synchronization and event processing
"""

import json
import logging
import signal
import sys
from datetime import datetime
from typing import Dict, Any, Optional, List, Callable
from dataclasses import dataclass, asdict
from enum import Enum
import asyncio

from kafka import KafkaConsumer, KafkaProducer
from kafka.errors import KafkaError
import redis
from elasticsearch import Elasticsearch, helpers
import psycopg2
from psycopg2.extras import RealDictCursor
import pymongo
from prometheus_client import Counter, Histogram, Gauge, start_http_server


# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


# Metrics
cdc_events_processed = Counter(
    'cdc_events_processed_total',
    'Total number of CDC events processed',
    ['database', 'table', 'operation']
)
cdc_events_failed = Counter(
    'cdc_events_failed_total',
    'Total number of CDC events that failed processing',
    ['database', 'table', 'error_type']
)
cdc_processing_duration = Histogram(
    'cdc_processing_duration_seconds',
    'Duration of CDC event processing',
    ['database', 'table', 'operation']
)
cdc_lag_seconds = Gauge(
    'cdc_lag_seconds',
    'Current lag in CDC processing',
    ['database', 'table']
)


class Operation(Enum):
    """CDC operation types"""
    CREATE = 'c'
    UPDATE = 'u'
    DELETE = 'd'
    READ = 'r'
    TRUNCATE = 't'
    MESSAGE = 'm'


@dataclass
class CDCEvent:
    """Represents a CDC event"""
    database: str
    table: str
    operation: Operation
    timestamp: datetime
    before: Optional[Dict[str, Any]]
    after: Optional[Dict[str, Any]]
    key: Dict[str, Any]
    source: Dict[str, Any]
    transaction_id: Optional[str] = None
    transaction_total_order: Optional[int] = None
    transaction_data_collection_order: Optional[int] = None


class CDCProcessor:
    """Base class for CDC event processors"""

    def __init__(self, name: str):
        self.name = name
        self.processed_count = 0
        self.failed_count = 0

    async def process(self, event: CDCEvent) -> bool:
        """Process a CDC event"""
        raise NotImplementedError

    async def handle_create(self, event: CDCEvent) -> bool:
        """Handle INSERT operation"""
        raise NotImplementedError

    async def handle_update(self, event: CDCEvent) -> bool:
        """Handle UPDATE operation"""
        raise NotImplementedError

    async def handle_delete(self, event: CDCEvent) -> bool:
        """Handle DELETE operation"""
        raise NotImplementedError


class ElasticsearchProcessor(CDCProcessor):
    """Processor for syncing to Elasticsearch"""

    def __init__(self, es_client: Elasticsearch):
        super().__init__("elasticsearch")
        self.es = es_client

    async def process(self, event: CDCEvent) -> bool:
        """Process event and sync to Elasticsearch"""
        try:
            index_name = f"{event.database}_{event.table}"

            if event.operation == Operation.CREATE:
                return await self.handle_create(event, index_name)
            elif event.operation == Operation.UPDATE:
                return await self.handle_update(event, index_name)
            elif event.operation == Operation.DELETE:
                return await self.handle_delete(event, index_name)

            return True

        except Exception as e:
            logger.error(f"Elasticsearch processing failed: {e}")
            return False

    async def handle_create(self, event: CDCEvent, index_name: str) -> bool:
        """Index new document"""
        doc_id = self._get_document_id(event)
        document = {
            **event.after,
            '_timestamp': event.timestamp.isoformat(),
            '_source_db': event.database,
            '_source_table': event.table
        }

        self.es.index(
            index=index_name,
            id=doc_id,
            body=document
        )
        return True

    async def handle_update(self, event: CDCEvent, index_name: str) -> bool:
        """Update existing document"""
        doc_id = self._get_document_id(event)
        document = {
            **event.after,
            '_timestamp': event.timestamp.isoformat(),
            '_updated_at': datetime.now().isoformat()
        }

        self.es.update(
            index=index_name,
            id=doc_id,
            body={'doc': document, 'doc_as_upsert': True}
        )
        return True

    async def handle_delete(self, event: CDCEvent, index_name: str) -> bool:
        """Delete document"""
        doc_id = self._get_document_id(event)
        self.es.delete(index=index_name, id=doc_id, ignore=[404])
        return True

    def _get_document_id(self, event: CDCEvent) -> str:
        """Generate document ID from event key"""
        if event.key:
            return '_'.join(str(v) for v in event.key.values())
        return str(event.timestamp.timestamp())


class RedisProcessor(CDCProcessor):
    """Processor for caching in Redis"""

    def __init__(self, redis_client: redis.Redis):
        super().__init__("redis")
        self.redis = redis_client
        self.ttl = 3600  # 1 hour default TTL

    async def process(self, event: CDCEvent) -> bool:
        """Process event and update Redis cache"""
        try:
            cache_key = self._get_cache_key(event)

            if event.operation == Operation.DELETE:
                self.redis.delete(cache_key)
                # Also invalidate related caches
                pattern = f"{event.database}:{event.table}:*"
                for key in self.redis.scan_iter(match=pattern):
                    self.redis.delete(key)
            else:
                # Store the latest state
                data = json.dumps(event.after, default=str)
                self.redis.setex(cache_key, self.ttl, data)

                # Update materialized views
                await self._update_materialized_views(event)

            return True

        except Exception as e:
            logger.error(f"Redis processing failed: {e}")
            return False

    async def _update_materialized_views(self, event: CDCEvent):
        """Update materialized views in Redis"""
        # Example: Update aggregated statistics
        if event.table == 'appointments' and event.database == 'clinic_db':
            if event.after and event.after.get('doctor_id'):
                doctor_id = event.after['doctor_id']
                key = f"stats:doctor:{doctor_id}:appointments"
                self.redis.hincrby(key, datetime.now().strftime('%Y-%m-%d'), 1)

    def _get_cache_key(self, event: CDCEvent) -> str:
        """Generate cache key"""
        key_parts = [event.database, event.table]
        if event.key:
            key_parts.extend(str(v) for v in event.key.values())
        return ':'.join(key_parts)


class PostgreSQLProcessor(CDCProcessor):
    """Processor for syncing to PostgreSQL data warehouse"""

    def __init__(self, pg_conn):
        super().__init__("postgresql")
        self.conn = pg_conn

    async def process(self, event: CDCEvent) -> bool:
        """Process event and sync to PostgreSQL"""
        try:
            schema = f"cdc_{event.database}"
            table = event.table

            with self.conn.cursor() as cursor:
                # Ensure schema exists
                cursor.execute(f"CREATE SCHEMA IF NOT EXISTS {schema}")

                if event.operation == Operation.CREATE:
                    await self._handle_insert(cursor, schema, table, event)
                elif event.operation == Operation.UPDATE:
                    await self._handle_update(cursor, schema, table, event)
                elif event.operation == Operation.DELETE:
                    await self._handle_delete(cursor, schema, table, event)

                self.conn.commit()

            return True

        except Exception as e:
            logger.error(f"PostgreSQL processing failed: {e}")
            self.conn.rollback()
            return False

    async def _handle_insert(self, cursor, schema: str, table: str, event: CDCEvent):
        """Handle INSERT to PostgreSQL"""
        columns = list(event.after.keys())
        values = [event.after[col] for col in columns]

        # Add CDC metadata columns
        columns.extend(['_cdc_timestamp', '_cdc_operation', '_cdc_source'])
        values.extend([event.timestamp, 'INSERT', event.database])

        placeholders = ','.join(['%s'] * len(values))
        cols = ','.join(columns)

        query = f"""
            INSERT INTO {schema}.{table} ({cols})
            VALUES ({placeholders})
            ON CONFLICT DO NOTHING
        """
        cursor.execute(query, values)

    async def _handle_update(self, cursor, schema: str, table: str, event: CDCEvent):
        """Handle UPDATE to PostgreSQL"""
        set_clause = ','.join([f"{k} = %s" for k in event.after.keys()])
        where_clause = ' AND '.join([f"{k} = %s" for k in event.key.keys()])

        values = list(event.after.values()) + list(event.key.values())

        query = f"""
            UPDATE {schema}.{table}
            SET {set_clause}, _cdc_timestamp = %s, _cdc_operation = 'UPDATE'
            WHERE {where_clause}
        """
        values.append(event.timestamp)
        cursor.execute(query, values)

    async def _handle_delete(self, cursor, schema: str, table: str, event: CDCEvent):
        """Handle DELETE in PostgreSQL (soft delete)"""
        where_clause = ' AND '.join([f"{k} = %s" for k in event.key.keys()])

        query = f"""
            UPDATE {schema}.{table}
            SET _cdc_deleted = TRUE,
                _cdc_deleted_at = %s,
                _cdc_operation = 'DELETE'
            WHERE {where_clause}
        """
        cursor.execute(query, [event.timestamp] + list(event.key.values()))


class MongoDBProcessor(CDCProcessor):
    """Processor for syncing to MongoDB"""

    def __init__(self, mongo_client: pymongo.MongoClient):
        super().__init__("mongodb")
        self.client = mongo_client

    async def process(self, event: CDCEvent) -> bool:
        """Process event and sync to MongoDB"""
        try:
            db = self.client[f"cdc_{event.database}"]
            collection = db[event.table]

            if event.operation == Operation.CREATE:
                await self._handle_insert(collection, event)
            elif event.operation == Operation.UPDATE:
                await self._handle_update(collection, event)
            elif event.operation == Operation.DELETE:
                await self._handle_delete(collection, event)

            return True

        except Exception as e:
            logger.error(f"MongoDB processing failed: {e}")
            return False

    async def _handle_insert(self, collection, event: CDCEvent):
        """Insert document to MongoDB"""
        document = {
            **event.after,
            '_cdc_metadata': {
                'timestamp': event.timestamp,
                'operation': 'INSERT',
                'source_database': event.database,
                'source_table': event.table,
                'transaction_id': event.transaction_id
            }
        }
        collection.insert_one(document)

    async def _handle_update(self, collection, event: CDCEvent):
        """Update document in MongoDB"""
        filter_doc = self._build_filter(event.key)
        update_doc = {
            '$set': {
                **event.after,
                '_cdc_metadata.timestamp': event.timestamp,
                '_cdc_metadata.operation': 'UPDATE',
                '_cdc_metadata.last_updated': datetime.now()
            }
        }
        collection.update_one(filter_doc, update_doc, upsert=True)

    async def _handle_delete(self, collection, event: CDCEvent):
        """Delete document from MongoDB"""
        filter_doc = self._build_filter(event.key)
        # Soft delete
        update_doc = {
            '$set': {
                '_cdc_metadata.deleted': True,
                '_cdc_metadata.deleted_at': event.timestamp,
                '_cdc_metadata.operation': 'DELETE'
            }
        }
        collection.update_one(filter_doc, update_doc)

    def _build_filter(self, key: Dict[str, Any]) -> Dict[str, Any]:
        """Build MongoDB filter from key"""
        return {k: v for k, v in key.items()}


class CDCConsumer:
    """Main CDC consumer that orchestrates processing"""

    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.kafka_consumer = None
        self.processors: List[CDCProcessor] = []
        self.running = False

    def add_processor(self, processor: CDCProcessor):
        """Add a processor to the pipeline"""
        self.processors.append(processor)

    async def start(self):
        """Start consuming CDC events"""
        self.running = True

        # Initialize Kafka consumer
        self.kafka_consumer = KafkaConsumer(
            *self.config['topics'],
            bootstrap_servers=self.config['kafka_servers'],
            group_id=self.config.get('group_id', 'cdc-consumer-group'),
            value_deserializer=lambda m: json.loads(m.decode('utf-8')),
            key_deserializer=lambda m: json.loads(m.decode('utf-8')) if m else None,
            auto_offset_reset='earliest',
            enable_auto_commit=False,
            max_poll_records=500,
            session_timeout_ms=30000,
            heartbeat_interval_ms=10000
        )

        logger.info(f"Started CDC consumer for topics: {self.config['topics']}")

        try:
            await self._consume_loop()
        except KeyboardInterrupt:
            logger.info("Shutting down CDC consumer...")
        finally:
            await self.stop()

    async def _consume_loop(self):
        """Main consumption loop"""
        while self.running:
            try:
                # Poll for messages
                messages = self.kafka_consumer.poll(timeout_ms=1000)

                if messages:
                    for topic_partition, records in messages.items():
                        for record in records:
                            await self._process_record(record)

                    # Commit offsets after successful processing
                    self.kafka_consumer.commit()

            except Exception as e:
                logger.error(f"Error in consumption loop: {e}")
                await asyncio.sleep(5)

    async def _process_record(self, record):
        """Process a single Kafka record"""
        try:
            # Parse CDC event
            event = self._parse_event(record)

            # Calculate lag
            lag = (datetime.now() - event.timestamp).total_seconds()
            cdc_lag_seconds.labels(
                database=event.database,
                table=event.table
            ).set(lag)

            # Process through all processors
            with cdc_processing_duration.labels(
                database=event.database,
                table=event.table,
                operation=event.operation.name
            ).time():
                tasks = [
                    processor.process(event)
                    for processor in self.processors
                ]
                results = await asyncio.gather(*tasks, return_exceptions=True)

                # Track metrics
                for i, result in enumerate(results):
                    if isinstance(result, Exception):
                        logger.error(f"Processor {self.processors[i].name} failed: {result}")
                        cdc_events_failed.labels(
                            database=event.database,
                            table=event.table,
                            error_type=type(result).__name__
                        ).inc()
                    elif result:
                        cdc_events_processed.labels(
                            database=event.database,
                            table=event.table,
                            operation=event.operation.name
                        ).inc()

        except Exception as e:
            logger.error(f"Failed to process record: {e}")
            cdc_events_failed.labels(
                database='unknown',
                table='unknown',
                error_type=type(e).__name__
            ).inc()

    def _parse_event(self, record) -> CDCEvent:
        """Parse Kafka record into CDCEvent"""
        value = record.value
        key = record.key

        # Extract operation
        op = value.get('op', 'r')
        operation = Operation(op)

        # Extract source metadata
        source = value.get('source', {})

        # Create CDCEvent
        return CDCEvent(
            database=source.get('db'),
            table=source.get('table'),
            operation=operation,
            timestamp=datetime.fromtimestamp(
                value.get('ts_ms', 0) / 1000
            ),
            before=value.get('before'),
            after=value.get('after'),
            key=key or {},
            source=source,
            transaction_id=value.get('transaction', {}).get('id'),
            transaction_total_order=value.get('transaction', {}).get('total_order'),
            transaction_data_collection_order=value.get('transaction', {}).get('data_collection_order')
        )

    async def stop(self):
        """Stop the consumer"""
        self.running = False
        if self.kafka_consumer:
            self.kafka_consumer.close()


async def main():
    """Main entry point"""
    # Start metrics server
    start_http_server(8000)

    # Configuration
    config = {
        'kafka_servers': ['localhost:29092'],
        'topics': [
            'cdc.clinic.patients',
            'cdc.clinic.appointments',
            'cdc.clinic.doctors',
            'cdc.iot.sensor_readings',
            'cdc.iot.alerts',
            'cdc.ecommerce.orders',
            'cdc.ecommerce.products'
        ],
        'group_id': 'cdc-consumer-group-1'
    }

    # Initialize processors
    es_client = Elasticsearch(['http://localhost:9200'])
    redis_client = redis.Redis(host='localhost', port=6379, decode_responses=True)

    # Create consumer
    consumer = CDCConsumer(config)

    # Add processors
    consumer.add_processor(ElasticsearchProcessor(es_client))
    consumer.add_processor(RedisProcessor(redis_client))

    # PostgreSQL processor (if configured)
    # pg_conn = psycopg2.connect(
    #     host='localhost',
    #     database='warehouse',
    #     user='user',
    #     password='password'
    # )
    # consumer.add_processor(PostgreSQLProcessor(pg_conn))

    # MongoDB processor (if configured)
    # mongo_client = pymongo.MongoClient('mongodb://localhost:27017/')
    # consumer.add_processor(MongoDBProcessor(mongo_client))

    # Start consuming
    await consumer.start()


if __name__ == "__main__":
    asyncio.run(main())