#!/usr/bin/env python3
"""
Real-time Stream Processing Application
Processes MySQL CDC events from Kafka using Faust
"""

import os
import json
import asyncio
import logging
from datetime import datetime, timedelta
from typing import Dict, Any, Optional, List
from decimal import Decimal

import faust
from faust import Record
from redis import Redis
import clickhouse_driver
from prometheus_client import Counter, Histogram, Gauge, start_http_server
import structlog

# Configure structured logging
structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.UnicodeDecoder(),
        structlog.processors.JSONRenderer()
    ],
    context_class=dict,
    logger_factory=structlog.stdlib.LoggerFactory(),
    cache_logger_on_first_use=True,
)

logger = structlog.get_logger()

# Environment configuration
KAFKA_BROKERS = os.getenv('KAFKA_BROKERS', 'kafka1:29092,kafka2:29093').split(',')
REDIS_HOST = os.getenv('REDIS_HOST', 'localhost')
REDIS_PORT = int(os.getenv('REDIS_PORT', 6379))
CLICKHOUSE_HOST = os.getenv('CLICKHOUSE_HOST', 'localhost')
CLICKHOUSE_PORT = int(os.getenv('CLICKHOUSE_PORT', 9000))
METRICS_PORT = int(os.getenv('METRICS_PORT', 8000))

# Metrics
events_processed = Counter('stream_events_processed_total', 'Total events processed', ['database', 'table', 'operation'])
events_failed = Counter('stream_events_failed_total', 'Total events failed', ['database', 'table', 'error_type'])
processing_time = Histogram('stream_processing_duration_seconds', 'Event processing time', ['processor'])
aggregation_value = Gauge('stream_aggregation_value', 'Current aggregation value', ['metric_type', 'database'])
lag_gauge = Gauge('stream_consumer_lag', 'Consumer lag', ['topic', 'partition'])

# Initialize external connections
redis_client = Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True)
clickhouse_client = clickhouse_driver.Client(host=CLICKHOUSE_HOST, port=CLICKHOUSE_PORT)

# Create Faust app
app = faust.App(
    'mysql-stream-processor',
    broker=KAFKA_BROKERS,
    value_serializer='json',
    store='rocksdb://',
    topic_partitions=4,
    processing_guarantee='exactly_once',
    stream_buffer_maxsize=100000,
)

# ==================== Data Models ====================

class DatabaseEvent(Record):
    """Base CDC event from MySQL"""
    database: str
    table: str
    operation: str  # INSERT, UPDATE, DELETE
    timestamp: datetime
    before: Optional[Dict[str, Any]] = None
    after: Optional[Dict[str, Any]] = None
    transaction_id: Optional[str] = None

class ClinicPatientEvent(Record):
    """Patient event from clinic database"""
    patient_id: int
    name: str
    date_of_birth: datetime
    gender: str
    phone: str
    email: Optional[str]
    created_at: datetime
    updated_at: datetime

class EcommerceOrderEvent(Record):
    """Order event from e-commerce database"""
    order_id: int
    customer_id: int
    order_date: datetime
    status: str
    total_amount: Decimal
    items: List[Dict[str, Any]]
    payment_method: str

class IoTReadingEvent(Record):
    """IoT sensor reading event"""
    device_id: str
    sensor_type: str
    value: float
    unit: str
    timestamp: datetime
    location: Optional[Dict[str, float]]
    metadata: Optional[Dict[str, Any]]

class SocialMediaPostEvent(Record):
    """Social media post event"""
    post_id: int
    user_id: int
    content: str
    post_type: str
    created_at: datetime
    likes_count: int
    comments_count: int
    shares_count: int

# ==================== Topics ====================

# Input topics from Debezium CDC
cdc_events_topic = app.topic('mysql-schema.*', value_type=DatabaseEvent, pattern=True)
clinic_patients_topic = app.topic('clinic_db.patients', value_type=ClinicPatientEvent)
ecommerce_orders_topic = app.topic('ecommerce_db.orders', value_type=EcommerceOrderEvent)
iot_readings_topic = app.topic('iot_db.readings', value_type=IoTReadingEvent)
social_posts_topic = app.topic('social_media_db.posts', value_type=SocialMediaPostEvent)

# Output topics for processed data
analytics_topic = app.topic('analytics.events', value_type=dict)
alerts_topic = app.topic('alerts.notifications', value_type=dict)
metrics_topic = app.topic('metrics.aggregations', value_type=dict)

# ==================== Tables (State Stores) ====================

# Aggregation tables
patient_counts = app.Table('patient_counts', default=int)
order_totals = app.Table('order_totals', default=float)
device_stats = app.Table('device_stats', default=dict)
user_activity = app.Table('user_activity', default=dict)

# Window tables for time-based aggregations
orders_hourly = app.Table('orders_hourly', default=list).tumbling(
    size=timedelta(hours=1),
    expires=timedelta(hours=24)
)

readings_5min = app.Table('readings_5min', default=list).tumbling(
    size=timedelta(minutes=5),
    expires=timedelta(hours=1)
)

# ==================== Stream Processors ====================

@app.agent(cdc_events_topic)
async def process_cdc_events(events):
    """Process all CDC events from MySQL"""
    async for event in events:
        try:
            logger.info("Processing CDC event",
                       database=event.database,
                       table=event.table,
                       operation=event.operation)

            # Update metrics
            events_processed.labels(
                database=event.database,
                table=event.table,
                operation=event.operation
            ).inc()

            # Route to specific processors based on database/table
            if event.database == 'clinic_db' and event.table == 'patients':
                await process_patient_change(event)
            elif event.database == 'ecommerce_db' and event.table == 'orders':
                await process_order_change(event)
            elif event.database == 'iot_db' and event.table == 'readings':
                await process_iot_reading(event)
            elif event.database == 'social_media_db' and event.table == 'posts':
                await process_social_post(event)

            # Store in data warehouse
            await store_to_clickhouse(event)

        except Exception as e:
            logger.error("Failed to process CDC event", error=str(e))
            events_failed.labels(
                database=event.database,
                table=event.table,
                error_type=type(e).__name__
            ).inc()

@app.agent(clinic_patients_topic)
async def process_patients(patients):
    """Process patient events for analytics"""
    async for patient in patients:
        # Update patient count
        patient_counts['total'] += 1
        patient_counts[f'gender_{patient.gender}'] += 1

        # Check for data quality issues
        if not patient.email or '@' not in patient.email:
            await alerts_topic.send(value={
                'alert_type': 'data_quality',
                'severity': 'warning',
                'message': f'Patient {patient.patient_id} has invalid email',
                'timestamp': datetime.utcnow().isoformat()
            })

        # Calculate patient age and segment
        age = (datetime.now() - patient.date_of_birth).days // 365
        age_group = get_age_group(age)
        patient_counts[f'age_group_{age_group}'] += 1

        # Send to analytics
        await analytics_topic.send(value={
            'event_type': 'patient_registration',
            'patient_id': patient.patient_id,
            'age': age,
            'age_group': age_group,
            'gender': patient.gender,
            'timestamp': patient.created_at.isoformat()
        })

@app.agent(ecommerce_orders_topic)
async def process_orders(orders):
    """Process e-commerce orders for real-time analytics"""
    async for order in orders.group_by(lambda o: o.customer_id):
        # Update order totals
        order_totals['revenue'] += float(order.total_amount)
        order_totals['count'] += 1
        order_totals[f'status_{order.status}'] += 1

        # Calculate customer lifetime value
        customer_orders = await get_customer_orders(order.customer_id)
        ltv = sum(float(o.get('total_amount', 0)) for o in customer_orders)

        # Detect high-value customers
        if ltv > 10000:
            await alerts_topic.send(value={
                'alert_type': 'high_value_customer',
                'severity': 'info',
                'customer_id': order.customer_id,
                'ltv': ltv,
                'timestamp': datetime.utcnow().isoformat()
            })

        # Add to hourly window
        orders_hourly[order.order_date.hour].append({
            'order_id': order.order_id,
            'amount': float(order.total_amount),
            'items_count': len(order.items)
        })

        # Real-time fraud detection
        if await detect_fraud(order):
            await alerts_topic.send(value={
                'alert_type': 'potential_fraud',
                'severity': 'critical',
                'order_id': order.order_id,
                'customer_id': order.customer_id,
                'amount': float(order.total_amount),
                'timestamp': datetime.utcnow().isoformat()
            })

@app.agent(iot_readings_topic)
async def process_iot_readings(readings):
    """Process IoT sensor readings for anomaly detection"""
    async for reading in readings.group_by(lambda r: r.device_id):
        device_id = reading.device_id

        # Update device statistics
        if device_id not in device_stats:
            device_stats[device_id] = {
                'count': 0,
                'sum': 0,
                'min': float('inf'),
                'max': float('-inf'),
                'last_reading': None
            }

        stats = device_stats[device_id]
        stats['count'] += 1
        stats['sum'] += reading.value
        stats['min'] = min(stats['min'], reading.value)
        stats['max'] = max(stats['max'], reading.value)
        stats['last_reading'] = reading.timestamp.isoformat()

        # Calculate moving average
        avg = stats['sum'] / stats['count']

        # Anomaly detection
        if reading.value > avg * 1.5 or reading.value < avg * 0.5:
            await alerts_topic.send(value={
                'alert_type': 'anomaly_detected',
                'severity': 'warning',
                'device_id': device_id,
                'sensor_type': reading.sensor_type,
                'value': reading.value,
                'average': avg,
                'timestamp': reading.timestamp.isoformat()
            })

        # Add to 5-minute window for aggregation
        readings_5min[reading.timestamp].append({
            'device_id': device_id,
            'value': reading.value,
            'sensor_type': reading.sensor_type
        })

        # Update metrics
        aggregation_value.labels(
            metric_type='iot_reading',
            database='iot_db'
        ).set(reading.value)

@app.agent(social_posts_topic)
async def process_social_posts(posts):
    """Process social media posts for engagement analytics"""
    async for post in posts:
        user_id = str(post.user_id)

        # Update user activity
        if user_id not in user_activity:
            user_activity[user_id] = {
                'posts_count': 0,
                'total_likes': 0,
                'total_comments': 0,
                'total_shares': 0,
                'engagement_rate': 0
            }

        activity = user_activity[user_id]
        activity['posts_count'] += 1
        activity['total_likes'] += post.likes_count
        activity['total_comments'] += post.comments_count
        activity['total_shares'] += post.shares_count

        # Calculate engagement rate
        total_engagement = post.likes_count + post.comments_count + post.shares_count
        activity['engagement_rate'] = total_engagement / activity['posts_count']

        # Detect viral content
        if total_engagement > 1000:
            await alerts_topic.send(value={
                'alert_type': 'viral_content',
                'severity': 'info',
                'post_id': post.post_id,
                'user_id': post.user_id,
                'engagement': total_engagement,
                'timestamp': post.created_at.isoformat()
            })

        # Sentiment analysis (simplified)
        sentiment = analyze_sentiment(post.content)

        # Send to analytics
        await analytics_topic.send(value={
            'event_type': 'social_post',
            'post_id': post.post_id,
            'user_id': post.user_id,
            'sentiment': sentiment,
            'engagement': total_engagement,
            'timestamp': post.created_at.isoformat()
        })

# ==================== Helper Functions ====================

async def process_patient_change(event: DatabaseEvent):
    """Process patient-specific changes"""
    if event.operation == 'INSERT':
        redis_client.incr('clinic:patients:total')
        redis_client.incr(f'clinic:patients:daily:{datetime.now().date()}')
    elif event.operation == 'DELETE':
        redis_client.decr('clinic:patients:total')

async def process_order_change(event: DatabaseEvent):
    """Process order-specific changes"""
    if event.operation == 'INSERT' and event.after:
        amount = float(event.after.get('total_amount', 0))
        redis_client.incrbyfloat('ecommerce:revenue:total', amount)
        redis_client.incrbyfloat(f'ecommerce:revenue:daily:{datetime.now().date()}', amount)

async def process_iot_reading(event: DatabaseEvent):
    """Process IoT reading changes"""
    if event.operation == 'INSERT' and event.after:
        device_id = event.after.get('device_id')
        value = float(event.after.get('value', 0))
        redis_client.zadd(f'iot:readings:{device_id}', {datetime.now().timestamp(): value})

async def process_social_post(event: DatabaseEvent):
    """Process social media post changes"""
    if event.operation == 'INSERT':
        redis_client.incr('social:posts:total')
        redis_client.incr(f'social:posts:hourly:{datetime.now().hour}')

async def store_to_clickhouse(event: DatabaseEvent):
    """Store processed events in ClickHouse"""
    try:
        clickhouse_client.execute(
            """
            INSERT INTO analytics.events (
                database, table_name, operation,
                timestamp, data, created_at
            ) VALUES (
                %(database)s, %(table)s, %(operation)s,
                %(timestamp)s, %(data)s, now()
            )
            """,
            {
                'database': event.database,
                'table': event.table,
                'operation': event.operation,
                'timestamp': event.timestamp,
                'data': json.dumps(event.after or event.before)
            }
        )
    except Exception as e:
        logger.error("Failed to store in ClickHouse", error=str(e))

async def get_customer_orders(customer_id: int) -> List[Dict]:
    """Get all orders for a customer from Redis cache"""
    orders = redis_client.get(f'customer:{customer_id}:orders')
    if orders:
        return json.loads(orders)
    return []

async def detect_fraud(order: EcommerceOrderEvent) -> bool:
    """Simple fraud detection based on patterns"""
    # Check for unusual order amount
    if float(order.total_amount) > 10000:
        return True

    # Check for rapid orders
    recent_orders = redis_client.get(f'customer:{order.customer_id}:recent_orders')
    if recent_orders:
        recent = json.loads(recent_orders)
        if len(recent) > 5:  # More than 5 orders in short time
            return True

    return False

def get_age_group(age: int) -> str:
    """Categorize age into groups"""
    if age < 18:
        return 'minor'
    elif age < 30:
        return 'young_adult'
    elif age < 50:
        return 'adult'
    elif age < 65:
        return 'middle_age'
    else:
        return 'senior'

def analyze_sentiment(content: str) -> str:
    """Simplified sentiment analysis"""
    positive_words = ['good', 'great', 'excellent', 'amazing', 'love']
    negative_words = ['bad', 'terrible', 'hate', 'awful', 'horrible']

    content_lower = content.lower()
    positive_count = sum(word in content_lower for word in positive_words)
    negative_count = sum(word in content_lower for word in negative_words)

    if positive_count > negative_count:
        return 'positive'
    elif negative_count > positive_count:
        return 'negative'
    else:
        return 'neutral'

# ==================== Periodic Tasks ====================

@app.timer(interval=60.0)  # Every minute
async def publish_metrics():
    """Publish aggregated metrics to metrics topic"""
    metrics = {
        'timestamp': datetime.utcnow().isoformat(),
        'patients': {
            'total': patient_counts.get('total', 0),
            'by_gender': {
                'male': patient_counts.get('gender_male', 0),
                'female': patient_counts.get('gender_female', 0)
            }
        },
        'orders': {
            'total': order_totals.get('count', 0),
            'revenue': order_totals.get('revenue', 0),
            'average': order_totals.get('revenue', 0) / max(order_totals.get('count', 1), 1)
        },
        'devices': {
            'active': len(device_stats),
            'total_readings': sum(d['count'] for d in device_stats.values())
        },
        'social': {
            'active_users': len(user_activity),
            'total_posts': sum(u['posts_count'] for u in user_activity.values())
        }
    }

    await metrics_topic.send(value=metrics)
    logger.info("Published metrics", metrics=metrics)

@app.timer(interval=300.0)  # Every 5 minutes
async def cleanup_old_data():
    """Clean up old data from state stores"""
    cutoff = datetime.now() - timedelta(days=7)

    # Clean Redis
    for key in redis_client.scan_iter("*:daily:*"):
        date_str = key.split(':')[-1]
        try:
            date = datetime.strptime(date_str, '%Y-%m-%d')
            if date < cutoff:
                redis_client.delete(key)
        except:
            pass

    logger.info("Cleaned up old data")

@app.timer(interval=30.0)  # Every 30 seconds
async def monitor_lag():
    """Monitor consumer lag"""
    for tp in app.consumer.assignment():
        committed = await app.consumer.committed(tp)
        position = await app.consumer.position(tp)
        lag = position - committed if committed else 0

        lag_gauge.labels(
            topic=tp.topic,
            partition=tp.partition
        ).set(lag)

# ==================== Main ====================

@app.on_leader_election
async def on_leader_election(app, was_leader_before: bool):
    """Handle leader election events"""
    if not was_leader_before:
        logger.info("Became leader, initializing resources")
        # Initialize ClickHouse tables
        clickhouse_client.execute("""
            CREATE TABLE IF NOT EXISTS analytics.events (
                database String,
                table_name String,
                operation String,
                timestamp DateTime,
                data String,
                created_at DateTime DEFAULT now()
            ) ENGINE = MergeTree()
            PARTITION BY toYYYYMM(created_at)
            ORDER BY (database, table_name, created_at)
        """)

if __name__ == '__main__':
    # Start metrics server
    start_http_server(METRICS_PORT)
    logger.info(f"Metrics server started on port {METRICS_PORT}")

    # Start Faust app
    app.main()