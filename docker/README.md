# Docker Infrastructure for MySQL Business-to-Schema

Complete Docker Compose configurations for all 15 database examples with automated deployment, data generation, and monitoring capabilities.

## Quick Start

### Prerequisites
- Docker Engine 20.10+
- Docker Compose 2.0+
- 8GB+ RAM recommended for running multiple examples
- 20GB+ free disk space

### Basic Usage

```bash
# Start an example
./docker/manage.sh up ecommerce

# Generate test data
./docker/manage.sh generate ecommerce

# View logs
./docker/manage.sh logs ecommerce

# Stop an example
./docker/manage.sh down ecommerce

# Check status
./docker/manage.sh status
```

## Architecture Overview

Each example includes:
- **MySQL 8.0** - Primary database with optimized configurations
- **phpMyAdmin** - Web-based database management
- **Data Generator** - Python-based data generation service
- **Optional Services** - Redis, Kafka, ElasticSearch, monitoring tools

## Port Assignments

| Example | MySQL Port | phpMyAdmin Port | Additional Services |
|---------|------------|-----------------|-------------------|
| clinic | 3308 | 8082 | - |
| iot_bins | 3309 | 8083 | InfluxDB: 8086 |
| smart_energy | 3310 | 8084 | Redis: 6380 |
| ecommerce | 3306 | 8080 | Flask: 5000 |
| industrial_iot | 3311 | 8085 | MQTT: 1883/9001 |
| smart_agriculture | 3312 | 8086 | Weather API: 8087 |
| fleet_management | 3313 | 8088 | GPS Simulator |
| healthcare_iot | 3314 | 8089 | Redis: 6381 |
| streaming_ml | 3315 | 8090 | Kafka: 9092, Kafka UI: 8091 |
| fintech | 3307 | 8081 | Redis: 6379, Grafana: 3000 |
| social_media | 3316 | 8092 | Redis: 6383, Neo4j: 7474 |
| real_estate | 3317 | 8093 | ElasticSearch: 9200, Kibana: 5601 |
| event_ticketing | 3318 | 8094 | Redis: 6384, RabbitMQ: 15672 |
| logistics | 3319 | 8095 | Redis: 6385, PostGIS: 5432 |
| education | 3320 | 8096 | Redis: 6386, MinIO: 9000/9001 |

## Service Profiles

Many examples include optional service profiles for additional functionality:

### Enable Optional Services

```bash
# Start with specific profile
docker-compose --profile monitoring up -d

# Available profiles:
# - monitoring: Prometheus, Grafana
# - services: Additional microservices
# - streaming: Kafka, Zookeeper
# - cache: Redis
# - search: ElasticSearch, Kibana
# - graph: Neo4j
# - geo: PostGIS
# - storage: MinIO
# - queue: RabbitMQ
```

## Data Generation

### Test Mode (Small Dataset)
```bash
# Generate small test dataset (default)
./docker/manage.sh generate ecommerce
```

### Production Mode (Large Dataset)
```bash
# Generate production-scale data
GENERATOR_MODE=production docker-compose run data_generator
```

### Custom Configuration
```bash
# Example: FinTech with custom settings
ENABLE_FRAUD_SIMULATION=true \
TRANSACTION_VOLUME=high \
COMPLIANCE_MODE=strict \
docker-compose -f example_10_fintech/docker-compose.yml run data_generator
```

## Memory Optimization

### MySQL Buffer Pool Sizing
- Small examples (clinic): 1-2GB
- Medium examples (ecommerce): 2-3GB
- Large examples (fintech, streaming_ml): 4GB+

### Adjust memory settings:
```yaml
command:
  - --innodb_buffer_pool_size=2G  # Adjust based on available RAM
  - --max_connections=500          # Reduce if needed
```

## Monitoring & Observability

### FinTech Example with Full Monitoring
```bash
cd example_10_fintech
docker-compose --profile monitoring up -d

# Access:
# - Prometheus: http://localhost:9090
# - Grafana: http://localhost:3000 (admin/admin)
```

### Health Checks
All MySQL services include health checks:
```yaml
healthcheck:
  test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
  timeout: 5s
  retries: 10
  interval: 5s
```

## Troubleshooting

### Common Issues

1. **Port Conflicts**
   ```bash
   # Check port usage
   netstat -an | grep 3306

   # Change port in docker-compose.yml
   ports:
     - "3399:3306"  # Use different host port
   ```

2. **Memory Issues**
   ```bash
   # Check Docker memory allocation
   docker system df

   # Clean up unused resources
   docker system prune -a --volumes
   ```

3. **Slow Startup**
   ```bash
   # Increase health check timeout
   healthcheck:
     timeout: 20s
     retries: 20
   ```

## Backup & Restore

### Backup Database
```bash
# Backup specific database
docker exec clinic_mysql mysqldump -u root -pclinic_root clinic_db > backup.sql

# Backup with compression
docker exec clinic_mysql mysqldump -u root -pclinic_root clinic_db | gzip > backup.sql.gz
```

### Restore Database
```bash
# Restore from backup
docker exec -i clinic_mysql mysql -u root -pclinic_root clinic_db < backup.sql

# Restore compressed backup
gunzip < backup.sql.gz | docker exec -i clinic_mysql mysql -u root -pclinic_root clinic_db
```

## Performance Tuning

### MySQL Optimization
```yaml
command:
  - --innodb_buffer_pool_size=4G
  - --innodb_log_file_size=512M
  - --innodb_flush_log_at_trx_commit=2
  - --innodb_flush_method=O_DIRECT
  - --query_cache_type=1
  - --query_cache_size=256M
  - --max_connections=2000
  - --thread_cache_size=50
  - --table_open_cache=4000
```

### Docker Performance
```yaml
# Use tmpfs for better performance (data not persisted)
volumes:
  - type: tmpfs
    target: /var/lib/mysql
    tmpfs:
      size: 2G
```

## Development Workflow

### 1. Start Development Environment
```bash
# Start MySQL and phpMyAdmin only
docker-compose up -d mysql phpmyadmin

# Wait for MySQL to be ready
docker-compose exec mysql mysqladmin ping -h localhost --wait
```

### 2. Run Schema Migrations
```bash
# Apply schema
docker-compose exec mysql mysql -u root -p < schema/001_initial.sql
```

### 3. Generate Test Data
```bash
# Run generator
docker-compose run --rm data_generator
```

### 4. Develop and Test
```bash
# Connect to MySQL
mysql -h localhost -P 3306 -u root -p

# Use phpMyAdmin
open http://localhost:8080
```

## CI/CD Integration

### GitHub Actions Example
```yaml
name: Test Database Examples

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Test Docker Compose Files
        run: |
          chmod +x docker/test_compose_files.sh
          ./docker/test_compose_files.sh

      - name: Start Example
        run: |
          docker-compose -f example_04_ecommerce/docker-compose.yml up -d
          sleep 30

      - name: Run Tests
        run: |
          docker-compose -f example_04_ecommerce/docker-compose.yml run data_generator
          docker-compose -f example_04_ecommerce/docker-compose.yml logs
```

## Security Best Practices

1. **Change Default Passwords**
   - Never use default passwords in production
   - Use Docker secrets for sensitive data

2. **Network Isolation**
   - Each example uses its own network
   - Services can only communicate within their network

3. **Volume Permissions**
   - Schema files mounted read-only
   - Generator outputs in separate volumes

4. **Environment Variables**
   ```bash
   # Use .env file for sensitive data
   echo "MYSQL_ROOT_PASSWORD=secure_password" > .env
   docker-compose --env-file .env up -d
   ```

## Advanced Usage

### Multi-Example Deployment
```bash
# Start multiple examples
./docker/manage.sh up ecommerce
./docker/manage.sh up fintech
./docker/manage.sh up social_media

# Check all statuses
./docker/manage.sh status
```

### Custom Networks
```yaml
# Connect examples for cross-database queries
networks:
  shared_network:
    external: true
    name: mysql_shared_network
```

### Load Balancing
```yaml
# HAProxy configuration for multiple MySQL instances
haproxy:
  image: haproxy:alpine
  ports:
    - "3306:3306"
  volumes:
    - ./haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro
```

## Maintenance

### Regular Tasks
```bash
# Weekly: Clean unused volumes
docker volume prune -f

# Monthly: Update images
docker-compose pull

# Quarterly: Full system cleanup
docker system prune -a --volumes
```

### Monitoring Disk Usage
```bash
# Check volume sizes
docker system df -v

# Find large volumes
docker volume ls -q | xargs -I {} docker volume inspect {} | jq '.[] | {Name, Size}'
```

## Contributing

To add a new example:

1. Create example directory: `example_XX_name/`
2. Add schema files: `example_XX_name/schema/`
3. Create generator: `generators/name/generator.py`
4. Add docker-compose.yml using template
5. Update manage.sh EXAMPLES array
6. Test with test_compose_files.sh

## License

MIT License - See LICENSE file for details