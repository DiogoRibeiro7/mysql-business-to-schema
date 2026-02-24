# MySQL Business-to-Schema Observability Stack

Comprehensive observability infrastructure for monitoring MySQL schemas, applications, and business metrics.

## 📊 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Applications                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │
│  │  MySQL   │  │  Apps    │  │  Custom  │  │  System  │       │
│  │ Schemas  │  │ Services │  │ Exporters│  │  Metrics │       │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘       │
└───────┼─────────────┼─────────────┼─────────────┼──────────────┘
        │             │             │             │
    ┌───▼─────────────▼─────────────▼─────────────▼───┐
    │              Collection Layer                     │
    │  ┌──────────┐  ┌──────────┐  ┌──────────┐      │
    │  │Prometheus│  │ Promtail │  │ Filebeat │      │
    │  └────┬─────┘  └────┬─────┘  └────┬─────┘      │
    └───────┼─────────────┼─────────────┼─────────────┘
            │             │             │
    ┌───────▼─────────────▼─────────────▼─────────────┐
    │           Processing & Storage                   │
    │  ┌──────────┐  ┌──────────┐  ┌──────────┐     │
    │  │Prometheus│  │   Loki   │  │ Elastic- │     │
    │  │  TSDB    │  │          │  │  search  │     │
    │  └────┬─────┘  └────┬─────┘  └────┬─────┘     │
    └───────┼─────────────┼─────────────┼────────────┘
            │             │             │
    ┌───────▼─────────────▼─────────────▼─────────────┐
    │           Visualization & Alerting               │
    │  ┌──────────┐  ┌──────────┐  ┌──────────┐     │
    │  │ Grafana  │  │  Kibana  │  │  Alert-  │     │
    │  │          │  │          │  │  Manager │     │
    │  └──────────┘  └──────────┘  └──────────┘     │
    └──────────────────────────────────────────────────┘
```

## 🚀 Components

### 1. **Metrics Collection (Prometheus)**
- **MySQL Exporter**: Collects MySQL performance metrics
- **Node Exporter**: System-level metrics (CPU, memory, disk, network)
- **cAdvisor**: Container metrics
- **Custom Schema Exporter**: Business-specific metrics for each schema

### 2. **Log Aggregation**
- **Loki + Promtail**: Lightweight log aggregation
- **Elasticsearch + Logstash + Kibana (ELK)**: Full-text search and analysis
- **Filebeat**: Log shipping from containers

### 3. **Distributed Tracing**
- **Jaeger**: End-to-end transaction tracing
- **OpenTelemetry**: Vendor-neutral telemetry data collection

### 4. **Visualization**
- **Grafana**: Metrics visualization and dashboards
- **Kibana**: Log exploration and analysis

### 5. **Alerting**
- **AlertManager**: Alert routing and notification
- **Prometheus Alerts**: Rule-based alerting

## 📦 Quick Start

### Prerequisites
- Docker and Docker Compose
- 8GB+ RAM available
- 20GB+ disk space

### Starting the Stack

```bash
# Start all services
cd observability
docker-compose up -d

# Check service health
docker-compose ps

# View logs
docker-compose logs -f
```

### Accessing Services

| Service | URL | Default Credentials |
|---------|-----|-------------------|
| Grafana | http://localhost:3000 | admin / admin |
| Prometheus | http://localhost:9090 | - |
| AlertManager | http://localhost:9093 | - |
| Kibana | http://localhost:5601 | - |
| Jaeger UI | http://localhost:16686 | - |
| Loki | http://localhost:3100 | - |

## 📊 Dashboards

### Pre-configured Dashboards

1. **MySQL Schema Overview** (`mysql-schema-overview`)
   - Active databases count
   - CPU and memory usage
   - Query rate
   - Database status table

2. **MySQL Performance** (`mysql-performance`)
   - Queries per second
   - Slow queries
   - Connection pool status
   - Buffer pool metrics
   - Network traffic
   - Table sizes

3. **Business Metrics** (`business-metrics`)
   - Clinic: Patient counts, appointments
   - E-commerce: Orders, revenue
   - IoT: Device status, data ingestion
   - Social Media: User activity, posts

4. **System Metrics**
   - Node exporter dashboard
   - Container metrics
   - Resource utilization

## 🔔 Alerting Rules

### Critical Alerts
- MySQL down
- Replication lag > 30s
- Disk space < 10%
- Memory usage > 90%
- Slow query rate high

### Warning Alerts
- CPU usage > 80%
- Connection pool > 80%
- Table fragmentation > 30%
- Business metric anomalies

### Alert Channels
- Email notifications
- Slack integration
- PagerDuty for critical alerts
- Webhook endpoints

## 📈 Custom Metrics

### Schema Exporter Metrics

```python
# Schema-level metrics
mysql_schema_table_count{database="clinic_db"} 15
mysql_schema_total_size_bytes{database="clinic_db"} 1048576
mysql_schema_index_count{database="clinic_db"} 25

# Business metrics
mysql_schema_clinic_patients_total{database="clinic_db"} 1234
mysql_schema_ecommerce_revenue_total{database="shop_db"} 99999.99
mysql_schema_iot_devices_active{database="iot_db"} 42
```

## 📝 Log Processing

### Logstash Pipeline

The Logstash pipeline processes:
- MySQL error logs
- MySQL slow query logs
- Application logs (JSON format)
- System logs (syslog)

Features:
- Multi-line log aggregation
- Error code extraction
- Performance classification
- GeoIP enrichment
- Deduplication

### Log Queries

```
# Loki LogQL examples
{job="mysql"} |= "error"
{app="api"} | json | level="error"
{container="mysql"} |~ "deadlock|timeout"

# Elasticsearch queries
GET mysql-logs-*/_search
{
  "query": {
    "match": {
      "severity": "high"
    }
  }
}
```

## 🔧 Configuration

### Environment Variables

Create `.env` file:
```bash
# MySQL
MYSQL_HOST=mysql
MYSQL_PORT=3306
MYSQL_USER=root
MYSQL_PASSWORD=root

# Alerting
SMTP_USERNAME=alerts@example.com
SMTP_PASSWORD=smtp_password
SLACK_WEBHOOK_URL=https://hooks.slack.com/...
PAGERDUTY_SERVICE_KEY=your_key

# Monitoring
ENVIRONMENT=production
CLUSTER_NAME=mysql-cluster
REGION=us-east-1
```

### Scaling Considerations

For production deployments:

1. **Prometheus**: Use remote storage (Thanos, Cortex)
2. **Elasticsearch**: Multi-node cluster with dedicated masters
3. **Grafana**: Enable HA mode with shared database
4. **AlertManager**: Configure clustering for HA

## 📚 Maintenance

### Backup

```bash
# Backup Prometheus data
docker run --rm -v prometheus_data:/data -v $(pwd):/backup alpine tar czf /backup/prometheus-backup.tar.gz /data

# Backup Grafana dashboards
curl -X GET http://admin:admin@localhost:3000/api/dashboards/db/mysql-performance > dashboards-backup.json

# Backup Elasticsearch indices
curl -X PUT "localhost:9200/_snapshot/backup" -H 'Content-Type: application/json' -d'
{
  "type": "fs",
  "settings": {
    "location": "/backup"
  }
}'
```

### Retention Policies

```yaml
# Prometheus retention (prometheus.yml)
storage.tsdb.retention.time: 30d
storage.tsdb.retention.size: 50GB

# Loki retention (loki-config.yml)
retention_period: 744h  # 31 days

# Elasticsearch (via Curator or ILM)
PUT _ilm/policy/mysql-logs-policy
{
  "policy": {
    "phases": {
      "delete": {
        "min_age": "30d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}
```

## 🔍 Troubleshooting

### Common Issues

1. **High memory usage**
   ```bash
   # Check memory usage
   docker stats

   # Limit container memory
   docker-compose down
   # Edit docker-compose.yml to add memory limits
   docker-compose up -d
   ```

2. **Prometheus scrape failures**
   ```bash
   # Check targets
   curl http://localhost:9090/api/v1/targets

   # Verify exporter endpoints
   curl http://localhost:9104/metrics  # MySQL exporter
   curl http://localhost:9100/metrics  # Node exporter
   ```

3. **Grafana dashboard not loading**
   ```bash
   # Check datasource configuration
   curl -X GET http://admin:admin@localhost:3000/api/datasources

   # Test datasource
   curl -X POST http://admin:admin@localhost:3000/api/datasources/1/health
   ```

## 📖 Additional Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Loki Documentation](https://grafana.com/docs/loki/)
- [Elasticsearch Documentation](https://www.elastic.co/guide/)
- [Jaeger Documentation](https://www.jaegertracing.io/docs/)

## 🤝 Contributing

To add new metrics or dashboards:

1. Create exporter in `exporters/` directory
2. Add scrape config to `prometheus/prometheus.yml`
3. Create dashboard JSON in `grafana/dashboards/`
4. Add alert rules to `prometheus/alerts.yml`
5. Update documentation

## 📄 License

This observability stack is part of the MySQL Business-to-Schema project.