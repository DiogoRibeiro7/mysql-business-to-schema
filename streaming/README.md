# Real-Time Streaming Pipelines for MySQL Business-to-Schema

Complete streaming infrastructure with Apache Kafka, Change Data Capture (CDC), and real-time analytics.

## 🚀 Overview

This streaming platform provides:
- **Change Data Capture (CDC)** from MySQL, PostgreSQL, and MongoDB
- **Real-time stream processing** with Kafka Streams
- **Analytics queries** using KSQL
- **Anomaly detection** and fraud prevention
- **Data enrichment** and transformation
- **Multi-database synchronization**

## 📦 Components

### Core Infrastructure
- **Apache Kafka**: Message streaming platform
- **Kafka Connect**: CDC and data integration
- **Schema Registry**: Schema management and evolution
- **KSQL**: Stream processing with SQL
- **Kafka Streams**: Java/Python stream processing

### Connectors
- **Debezium MySQL**: CDC from MySQL databases
- **Debezium PostgreSQL**: CDC from PostgreSQL
- **MongoDB Connector**: Change streams from MongoDB
- **Elasticsearch Sink**: Real-time search indexing
- **S3 Sink**: Data lake integration

## 🛠️ Quick Start

### 1. Start Infrastructure

```bash
# Start all streaming services
docker-compose -f streaming/docker-compose.kafka.yml up -d

# Wait for services to be ready
sleep 30

# Check health
python streaming/stream_manager.py health
```

### 2. Deploy CDC Connectors

```bash
# Deploy MySQL CDC
python streaming/stream_manager.py deploy-connector mysql-cdc-connector.json

# Deploy PostgreSQL CDC
python streaming/stream_manager.py deploy-connector postgres-cdc-connector.json

# Deploy MongoDB CDC
python streaming/stream_manager.py deploy-connector mongodb-cdc-connector.json
```

### 3. Deploy Analytics Queries

```bash
# Deploy KSQL queries
python streaming/stream_manager.py deploy-ksql analytics_queries.sql
```

### 4. Start Stream Processing

```bash
# Run stream processor
python streaming/streams/stream_processor.py
```

## 📊 Use Cases

### 1. E-Commerce Real-Time Analytics

Monitor and analyze e-commerce operations in real-time:

```sql
-- Real-time revenue dashboard
SELECT
    WINDOWSTART AS hour,
    COUNT(*) AS orders,
    SUM(total_amount) AS revenue,
    COUNT(DISTINCT customer_id) AS customers
FROM orders_stream
WINDOW TUMBLING (SIZE 1 HOUR)
GROUP BY WINDOWSTART;
```

**Features:**
- Order tracking and fulfillment
- Inventory management
- Customer behavior analysis
- Fraud detection
- Dynamic pricing

### 2. Financial Transaction Monitoring

Real-time fraud detection and compliance:

```python
# Detect suspicious transactions
if transaction.amount > 10000:
    fraud_score += 30
if time_since_last_transaction < 60:
    fraud_score += 40
if unusual_location:
    fraud_score += 30
```

**Features:**
- Real-time fraud scoring
- AML/KYC compliance
- Transaction pattern analysis
- Risk assessment
- Regulatory reporting

### 3. IoT Sensor Data Processing

Process high-volume IoT data streams:

```sql
-- Aggregate sensor readings
CREATE TABLE sensor_aggregates AS
SELECT
    sensor_id,
    AVG(value) AS avg_value,
    MAX(value) AS max_value,
    MIN(value) AS min_value
FROM sensor_stream
WINDOW TUMBLING (SIZE 5 MINUTES)
GROUP BY sensor_id;
```

**Features:**
- Real-time alerting
- Predictive maintenance
- Anomaly detection
- Time-series analysis
- Edge computing integration

## 🔄 CDC Configuration

### MySQL CDC Setup

1. **Enable Binary Logging:**
```sql
-- In MySQL configuration
[mysqld]
log-bin=mysql-bin
binlog_format=ROW
binlog_row_image=FULL
```

2. **Create CDC User:**
```sql
CREATE USER 'debezium'@'%' IDENTIFIED BY 'password';
GRANT SELECT, RELOAD, SHOW DATABASES, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'debezium'@'%';
```

### PostgreSQL CDC Setup

1. **Enable Logical Replication:**
```sql
-- In postgresql.conf
wal_level = logical
max_replication_slots = 4
max_wal_senders = 4
```

2. **Create Publication:**
```sql
CREATE PUBLICATION cdc_publication FOR ALL TABLES;
```

### MongoDB CDC Setup

1. **Enable Change Streams:**
```javascript
// MongoDB 4.0+ with replica set
rs.initiate()
```

2. **Create Change Stream:**
```javascript
const changeStream = db.collection.watch([
    { $match: { operationType: { $in: ["insert", "update", "delete"] } } }
]);
```

## 📈 Monitoring & Observability

### Kafka Metrics

Access metrics at `http://localhost:9090` (Prometheus):

- **Broker Metrics:**
  - Messages/sec
  - Bytes in/out
  - Request latency
  - ISR shrinks/expansions

- **Consumer Metrics:**
  - Lag per partition
  - Consumption rate
  - Commit latency

- **Producer Metrics:**
  - Production rate
  - Batch size
  - Compression ratio

### KSQL Metrics

Monitor stream processing at `http://localhost:8088`:

```sql
-- Show processing statistics
SHOW QUERIES;
DESCRIBE EXTENDED <query_id>;
```

### Grafana Dashboards

Import pre-built dashboards at `http://localhost:3000`:

1. Kafka Overview
2. CDC Pipeline Health
3. Stream Processing Metrics
4. Business KPIs

## 🔧 Advanced Configuration

### Scaling Kafka

```yaml
# Increase partitions for throughput
kafka:
  environment:
    KAFKA_NUM_PARTITIONS: 10
    KAFKA_DEFAULT_REPLICATION_FACTOR: 3
```

### Tuning Stream Processing

```python
# Optimize for latency
config = {
    'max.poll.records': 100,
    'fetch.min.bytes': 1,
    'linger.ms': 0
}

# Optimize for throughput
config = {
    'max.poll.records': 5000,
    'fetch.min.bytes': 50000,
    'linger.ms': 100
}
```

### Error Handling

```json
{
  "errors.tolerance": "all",
  "errors.log.enable": true,
  "errors.deadletterqueue.topic.name": "dlq",
  "errors.deadletterqueue.topic.replication.factor": 1
}
```

## 🎯 Performance Optimization

### Kafka Optimization

1. **Compression:**
   - Use Snappy for balanced performance
   - LZ4 for higher throughput
   - GZIP for better compression ratio

2. **Batching:**
   - Increase `batch.size` for throughput
   - Adjust `linger.ms` for latency vs throughput

3. **Memory:**
   - Tune JVM heap size
   - Adjust buffer sizes

### KSQL Optimization

1. **State Stores:**
   - Use RocksDB for large state
   - Configure cache size
   - Enable changelog compression

2. **Windowing:**
   - Choose appropriate window size
   - Use hopping windows for overlapping analysis
   - Session windows for user activity

## 🔒 Security

### Enable SSL/TLS

```yaml
kafka:
  environment:
    KAFKA_SSL_KEYSTORE_LOCATION: /var/ssl/private/kafka.keystore.jks
    KAFKA_SSL_KEYSTORE_PASSWORD: password
    KAFKA_SSL_KEY_PASSWORD: password
    KAFKA_SSL_TRUSTSTORE_LOCATION: /var/ssl/private/kafka.truststore.jks
    KAFKA_SSL_TRUSTSTORE_PASSWORD: password
```

### Enable SASL Authentication

```yaml
kafka:
  environment:
    KAFKA_SASL_ENABLED_MECHANISMS: PLAIN
    KAFKA_SASL_MECHANISM_INTER_BROKER_PROTOCOL: PLAIN
```

### Data Privacy

- Use field-level encryption for sensitive data
- Implement PII masking in stream processing
- Configure audit logging

## 📝 Troubleshooting

### Common Issues

1. **Connector Fails to Start:**
   ```bash
   # Check connector status
   curl http://localhost:8083/connectors/{name}/status

   # View logs
   docker logs streaming_kafka_connect
   ```

2. **High Consumer Lag:**
   ```bash
   # Check consumer group
   kafka-consumer-groups --bootstrap-server localhost:9092 \
     --group {group-id} --describe
   ```

3. **KSQL Query Errors:**
   ```sql
   -- Check query status
   SHOW QUERIES;
   EXPLAIN <query-id>;
   ```

### Debug Mode

Enable debug logging:

```yaml
kafka-connect:
  environment:
    CONNECT_LOG4J_ROOT_LOGLEVEL: DEBUG
```

## 📚 Examples

### Example 1: Customer 360 View

Combine data from multiple sources:

```sql
CREATE STREAM customer_360 AS
SELECT
    c.customer_id,
    c.email,
    o.order_count,
    o.total_spent,
    s.last_support_ticket,
    m.marketing_segment
FROM customers_stream c
    LEFT JOIN order_aggregates o ON c.customer_id = o.customer_id
    LEFT JOIN support_stream s ON c.customer_id = s.customer_id
    LEFT JOIN marketing_stream m ON c.customer_id = m.customer_id;
```

### Example 2: Real-Time Recommendations

Generate product recommendations:

```python
def generate_recommendations(event):
    # Get user's purchase history
    history = get_purchase_history(event.customer_id)

    # Find similar users
    similar_users = find_similar_users(history)

    # Get their purchases
    recommendations = get_top_products(similar_users)

    # Publish to recommendation topic
    producer.send('recommendations', {
        'customer_id': event.customer_id,
        'recommendations': recommendations,
        'timestamp': datetime.now()
    })
```

### Example 3: Inventory Optimization

Predict stock requirements:

```sql
CREATE TABLE inventory_predictions AS
SELECT
    product_id,
    AVG(daily_sales) * 7 AS weekly_forecast,
    STDDEV(daily_sales) AS volatility,
    CASE
        WHEN stock_level < AVG(daily_sales) * 3 THEN 'REORDER_NOW'
        WHEN stock_level < AVG(daily_sales) * 7 THEN 'REORDER_SOON'
        ELSE 'SUFFICIENT'
    END AS status
FROM product_sales_stream
WINDOW TUMBLING (SIZE 30 DAYS)
GROUP BY product_id;
```

## 🚀 Production Deployment

### Kubernetes Deployment

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: kafka
spec:
  replicas: 3
  serviceName: kafka-headless
  template:
    spec:
      containers:
      - name: kafka
        image: confluentinc/cp-kafka:7.5.0
        resources:
          requests:
            memory: "4Gi"
            cpu: "2"
          limits:
            memory: "8Gi"
            cpu: "4"
```

### Monitoring Stack

Deploy monitoring with Helm:

```bash
# Prometheus
helm install prometheus prometheus-community/prometheus

# Grafana
helm install grafana grafana/grafana

# Kafka Exporter
helm install kafka-exporter prometheus-community/prometheus-kafka-exporter
```

## 📖 References

- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)
- [Debezium Documentation](https://debezium.io/documentation/)
- [KSQL Documentation](https://docs.ksqldb.io/)
- [Confluent Schema Registry](https://docs.confluent.io/platform/current/schema-registry/)

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

## 📄 License

MIT License - see [LICENSE](../LICENSE) for details.