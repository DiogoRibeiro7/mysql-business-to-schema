# MySQL Business-to-Schema Data Pipeline & Analytics

Complete data pipeline infrastructure for real-time and batch processing of MySQL schema data.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Data Sources                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │  MySQL   │  │  MySQL   │  │  MySQL   │  │  MySQL   │   │
│  │ Clinic DB│  │ E-comm DB│  │  IoT DB  │  │ Social DB│   │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘   │
└───────┼─────────────┼─────────────┼─────────────┼──────────┘
        │             │             │             │
    ┌───▼─────────────▼─────────────▼─────────────▼───┐
    │            Change Data Capture (CDC)             │
    │         Debezium MySQL Connectors                │
    └───────────────────┬───────────────────────────────┘
                        │
    ┌───────────────────▼───────────────────────────────┐
    │              Apache Kafka Cluster                  │
    │  ┌──────────────────────────────────────────┐    │
    │  │ Topics: CDC Events, Analytics, Alerts    │    │
    │  └──────────────────────────────────────────┘    │
    └──────┬──────────────┬──────────────┬──────────────┘
           │              │              │
    ┌──────▼───────┐ ┌───▼──────┐ ┌────▼──────┐
    │Apache Flink  │ │  Apache  │ │  Faust    │
    │ Real-time    │ │  Spark   │ │  Stream   │
    │ Processing   │ │  Batch   │ │ Processor │
    └──────┬───────┘ └───┬──────┘ └────┬──────┘
           │             │              │
    ┌──────▼─────────────▼──────────────▼───────┐
    │           Data Storage Layer               │
    │  ┌──────────┐ ┌──────────┐ ┌──────────┐ │
    │  │ClickHouse│ │  MinIO   │ │  Redis   │ │
    │  │   OLAP   │ │    S3    │ │  Cache   │ │
    │  └──────────┘ └──────────┘ └──────────┘ │
    └──────────────┬─────────────────────────────┘
                   │
    ┌──────────────▼─────────────────────────────┐
    │         Analytics & Visualization           │
    │  ┌──────────┐ ┌──────────┐ ┌──────────┐  │
    │  │ Superset │ │  Jupyter │ │  Grafana │  │
    │  └──────────┘ └──────────┘ └──────────┘  │
    └─────────────────────────────────────────────┘
```

## 🚀 Components

### 1. **Message Streaming (Apache Kafka)**
- 2-broker cluster with Zookeeper
- Schema Registry for Avro schemas
- Kafka Connect for CDC with Debezium
- Kafka UI for monitoring

### 2. **Stream Processing**
- **Apache Flink**: Complex event processing, pattern detection
- **Apache Spark Streaming**: Micro-batch processing
- **Faust (Python)**: Lightweight stream processing

### 3. **Batch Processing**
- **Apache Spark**: ETL jobs, data warehouse loading
- **Apache NiFi**: Data flow orchestration

### 4. **Data Storage**
- **ClickHouse**: OLAP database for analytics
- **Apache Druid**: Real-time analytics database
- **MinIO**: S3-compatible object storage
- **Redis**: Caching and real-time counters

### 5. **Analytics & Visualization**
- **Apache Superset**: Business intelligence
- **Jupyter**: Data science notebooks
- **Grafana**: Metrics visualization

## 📦 Quick Start

### Prerequisites
- Docker and Docker Compose
- 16GB+ RAM recommended
- 50GB+ disk space

### Starting the Pipeline

```bash
# Clone the repository
git clone <repository-url>
cd data-pipeline

# Start all services
docker-compose up -d

# Wait for services to be healthy
docker-compose ps

# Create Kafka topics
docker exec -it kafka1 kafka-topics.sh --create \
  --topic mysql-schema.clinic_db.patients \
  --bootstrap-server localhost:9092 \
  --partitions 3 --replication-factor 2

# Deploy Debezium MySQL connector
curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d @kafka-connect/connectors/mysql-source.json

# Start stream processors
docker exec -it jupyter-spark spark-submit /opt/spark-apps/etl_job.py

# Start Faust application
docker exec -it faust-processor python app.py worker -l info
```

### Accessing Services

| Service | URL | Credentials |
|---------|-----|------------|
| Kafka UI | http://localhost:8080 | - |
| Schema Registry | http://localhost:8081 | - |
| Kafka Connect | http://localhost:8083 | - |
| Spark Master | http://localhost:8088 | - |
| Flink JobManager | http://localhost:8082 | - |
| Jupyter Notebook | http://localhost:8888 | token displayed in logs |
| ClickHouse | http://localhost:8123 | default / - |
| Superset | http://localhost:8089 | admin / admin |
| MinIO Console | http://localhost:9002 | minioadmin / minioadmin |
| NiFi | https://localhost:8443 | admin / admin123456789 |

## 📊 Data Processing Pipelines

### Real-time Processing (Flink)

The Flink job performs:
- **Fraud Detection**: Pattern matching for suspicious orders
- **Anomaly Detection**: Statistical analysis of IoT sensor data
- **Patient Monitoring**: Critical condition alerts
- **Cross-domain Correlation**: Event correlation across databases

```java
// Example: Fraud detection pattern
Pattern<OrderEvent, ?> fraudPattern = Pattern.<OrderEvent>begin("first")
    .where(order -> order.amount > 5000)
    .followedBy("second")
    .where(order -> order.amount > 5000)
    .within(Time.minutes(10));
```

### Stream Processing (Faust)

The Faust application handles:
- **Event Routing**: CDC events to specific processors
- **Aggregations**: Real-time metrics calculation
- **State Management**: Customer profiles, device statistics
- **Alert Generation**: Business rule evaluation

```python
@app.agent(clinic_patients_topic)
async def process_patients(patients):
    async for patient in patients:
        # Update metrics
        patient_counts['total'] += 1
        # Check data quality
        if not patient.email:
            await alerts_topic.send(...)
```

### Batch Processing (Spark)

Spark ETL jobs perform:
- **Data Enrichment**: Adding calculated fields
- **Aggregations**: Hourly/daily rollups
- **Data Quality**: Validation and cleansing
- **Warehouse Loading**: ClickHouse and S3

```python
def process_order_data(df):
    return df.withColumn("order_value_category",
        when(col("total_amount") < 50, "Low")
        .when(col("total_amount") < 200, "Medium")
        .otherwise("High"))
```

## 🔧 Configuration

### Kafka Topics

```bash
# CDC topics (created automatically by Debezium)
mysql-schema.clinic_db.patients
mysql-schema.clinic_db.appointments
mysql-schema.ecommerce_db.orders
mysql-schema.ecommerce_db.products
mysql-schema.iot_db.devices
mysql-schema.iot_db.readings
mysql-schema.social_media_db.users
mysql-schema.social_media_db.posts

# Processed data topics
processed.patients
processed.orders
processed.iot
analytics.events
alerts.notifications
metrics.aggregations
```

### ClickHouse Tables

```sql
-- Fact tables
cdc_events          -- Raw CDC events
patients_fact       -- Patient data
orders_fact         -- Order transactions
iot_readings_fact   -- IoT sensor readings
social_posts_fact   -- Social media posts

-- Aggregated tables
patient_metrics_hourly
order_metrics_hourly
iot_metrics_5min
business_metrics_daily

-- Dimension tables
dim_customers
dim_products
dim_devices
```

## 📈 Analytics Queries

### Business Metrics

```sql
-- Revenue by hour
SELECT
    toStartOfHour(order_date) as hour,
    sum(total_amount) as revenue,
    count() as orders
FROM orders_fact
WHERE order_date >= today()
GROUP BY hour
ORDER BY hour;

-- Patient admissions trend
SELECT
    toStartOfDay(created_at) as day,
    age_group,
    count() as patients
FROM patients_fact
WHERE created_at >= today() - 30
GROUP BY day, age_group
ORDER BY day, age_group;

-- IoT anomaly rate
SELECT
    device_id,
    toStartOfHour(timestamp) as hour,
    countIf(is_anomaly) / count() as anomaly_rate
FROM iot_readings_fact
WHERE timestamp >= now() - INTERVAL 24 HOUR
GROUP BY device_id, hour
HAVING anomaly_rate > 0.1;
```

### Real-time Dashboards

Superset dashboards available:
1. **Executive Dashboard**: KPIs across all schemas
2. **Operations Monitor**: System health and performance
3. **Customer Analytics**: Behavior and segmentation
4. **IoT Device Status**: Real-time sensor monitoring
5. **Social Media Trends**: Engagement metrics

## 🔍 Monitoring & Alerting

### Metrics Collection

- **Kafka Metrics**: JMX exporters for Prometheus
- **Flink Metrics**: Built-in metrics reporter
- **Spark Metrics**: Spark History Server
- **Application Metrics**: Custom Prometheus exporters

### Alert Rules

```yaml
# Example alerts
- High order value anomaly
- IoT sensor failure
- Patient critical condition
- Social media viral content
- System performance degradation
```

## 🛠️ Development

### Adding New Processors

1. **Flink Job**: Add to `flink/jobs/`
2. **Spark Job**: Add to `spark/apps/`
3. **Faust Agent**: Extend `stream-processors/app.py`

### Testing

```bash
# Run unit tests
docker exec -it spark-master spark-submit --master local[2] tests/test_etl.py

# Generate test data
docker exec -it kafka1 kafka-console-producer.sh \
  --broker-list localhost:9092 \
  --topic test-topic < test-data.json

# Verify processing
docker exec -it clickhouse clickhouse-client \
  --query "SELECT count() FROM analytics.orders_fact"
```

## 📝 Maintenance

### Backup

```bash
# Backup ClickHouse
docker exec clickhouse clickhouse-backup create

# Backup Kafka topics
docker exec kafka1 kafka-topics.sh --describe --zookeeper zookeeper:2181 > topics-backup.txt

# Backup MinIO data
docker exec minio mc mirror minio/mysql-schema-data /backup/
```

### Scaling

```yaml
# Scale Spark workers
docker-compose up -d --scale spark-worker=4

# Scale Flink task managers
docker-compose up -d --scale flink-taskmanager=3

# Add Kafka brokers
# Edit docker-compose.yml to add kafka3, kafka4...
```

### Performance Tuning

```bash
# Kafka optimization
KAFKA_HEAP_OPTS="-Xmx4G -Xms4G"
KAFKA_JVM_PERFORMANCE_OPTS="-XX:+UseG1GC -XX:MaxGCPauseMillis=20"

# Spark optimization
spark.sql.adaptive.enabled=true
spark.sql.adaptive.coalescePartitions.enabled=true

# ClickHouse optimization
max_threads=8
max_memory_usage=10000000000
```

## 🔒 Security

### Authentication
- Kafka: SASL/SCRAM authentication
- ClickHouse: User/password authentication
- Superset: OAuth integration ready

### Encryption
- Kafka: SSL/TLS for inter-broker communication
- MinIO: TLS encryption
- NiFi: HTTPS with certificates

### Authorization
- Kafka: ACLs for topic access
- ClickHouse: Role-based access control
- Superset: Row-level security

## 📚 Additional Resources

- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)
- [Apache Flink Documentation](https://flink.apache.org/docs/)
- [Apache Spark Documentation](https://spark.apache.org/docs/)
- [ClickHouse Documentation](https://clickhouse.com/docs/)
- [Faust Documentation](https://faust.readthedocs.io/)

## 🤝 Contributing

To add new data processing capabilities:

1. Create processor in appropriate directory
2. Add Kafka topic if needed
3. Update ClickHouse schema
4. Create Superset dashboard
5. Add monitoring and alerts
6. Update documentation

## 📄 License

Part of the MySQL Business-to-Schema project.