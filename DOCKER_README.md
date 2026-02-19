# Docker Compose Configuration Guide

## 📦 Overview

This project includes complete Docker Compose configurations for all 20+ database examples. Each example is fully containerized with MySQL, phpMyAdmin, data generators, and optional supporting services like Redis or Elasticsearch.

## 🚀 Quick Start

### Prerequisites
- Docker Desktop installed and running
- Docker Compose (included with Docker Desktop)
- At least 8GB RAM available for Docker
- 10GB+ free disk space

### Start a Single Example

```bash
# Navigate to any example directory
cd example_01_clinic

# Start the containers
docker-compose up -d

# Generate test data
docker-compose run data_generator
```

### Using the Docker Manager

We provide convenient management scripts for orchestrating all examples:

**Linux/Mac:**
```bash
# Make the script executable
chmod +x docker-manager.sh

# List all available examples
./docker-manager.sh list

# Start a specific example
./docker-manager.sh start clinic

# Start all examples
./docker-manager.sh start all

# Generate data for an example
./docker-manager.sh generate ecommerce

# Show status
./docker-manager.sh status all

# Show all exposed ports
./docker-manager.sh ports
```

**Windows:**
```cmd
# List all available examples
docker-manager.bat list

# Start a specific example
docker-manager.bat start clinic

# Start all examples
docker-manager.bat start all

# Generate data
docker-manager.bat generate ecommerce
```

## 📊 Port Mapping

Each example uses different ports to avoid conflicts when running multiple examples simultaneously:

| Example | MySQL Port | phpMyAdmin | Additional Services |
|---------|------------|------------|-------------------|
| Clinic | 3308 | 8082 | - |
| IoT Bins | 3309 | 8083 | - |
| Smart Energy | 3310 | 8084 | - |
| E-commerce | 3311 | 8085 | Redis: 6380 |
| Industrial IoT | 3312 | 8086 | - |
| Smart Agriculture | 3313 | 8087 | - |
| Fleet Management | 3314 | 8088 | - |
| Healthcare IoT | 3315 | 8089 | - |
| Streaming ML | 3316 | 8090 | Kafka: 9092 |
| FinTech | 3317 | 8091 | Redis: 6381 |
| Social Media | 3318 | 8092 | Redis: 6382, ES: 9200 |
| Real Estate | 3319 | 8093 | - |
| Event Ticketing | 3320 | 8094 | - |
| Logistics | 3321 | 8095 | - |
| Education | 3322 | 8096 | - |
| Cryptocurrency | 3323 | 8097 | - |
| Crypto Exchange | 3326 | 8100 | Redis: 6382 |
| Food Delivery | 3327 | 8101 | - |
| Gaming Platform | 3328 | 8102 | Redis: 6384, ES: 9202 |
| Insurance | 3329 | 8103 | Redis: 6385, PG: 5434 |
| Hotel Chain | 3330 | 8104 | - |

## 🏗️ Architecture

Each Docker Compose configuration includes:

### Core Services
1. **MySQL 8.0**
   - Configured with UTF8MB4 character set
   - Optimized buffer pool and connection settings
   - Automatic schema initialization
   - Health checks for reliability

2. **phpMyAdmin**
   - Web-based MySQL administration
   - Pre-configured connection to MySQL
   - Accessible via web browser

3. **Data Generator**
   - Python-based data generation
   - Configurable via environment variables
   - Batch processing support
   - Realistic data patterns

### Optional Services (Example-specific)
- **Redis**: Session management, caching (Gaming, E-commerce, FinTech)
- **Elasticsearch**: Full-text search, analytics (Social Media, Gaming)
- **PostgreSQL**: Analytics database (Insurance)
- **Kafka**: Event streaming (Streaming ML)

## 🔧 Configuration

### Environment Variables

Each docker-compose.yml supports environment variables for customization:

```bash
# Set generator mode (test/development/production)
GENERATOR_MODE=development docker-compose up

# Configure data volume
USERS_COUNT=5000 docker-compose run data_generator

# Example-specific variables
ORDERS_PER_DAY=1000 docker-compose run data_generator
```

### Custom MySQL Configuration

Modify the MySQL command section in docker-compose.yml:

```yaml
mysql:
  command:
    - --max_connections=500
    - --innodb_buffer_pool_size=2G
    - --slow_query_log=ON
    - --long_query_time=2
```

### Persistent Data

Data is stored in named volumes to persist between container restarts:

```bash
# List all volumes
docker volume ls | grep mysql_data

# Backup a volume
docker run --rm -v clinic_mysql_data:/data -v $(pwd):/backup \
  alpine tar czf /backup/clinic_backup.tar.gz -C /data .

# Restore a volume
docker run --rm -v clinic_mysql_data:/data -v $(pwd):/backup \
  alpine tar xzf /backup/clinic_backup.tar.gz -C /data
```

## 📝 Common Operations

### Connect to MySQL

```bash
# Using mysql client
mysql -h localhost -P 3308 -u root -p clinic_db

# Default passwords:
# - root: [example]_root (e.g., clinic_root)
# - user: [example]_pass (e.g., clinic_pass)
```

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f mysql

# Using manager script
./docker-manager.sh logs clinic
```

### Execute SQL Scripts

```bash
# Run a SQL file
docker-compose exec mysql mysql -u root -p clinic_db < script.sql

# Interactive MySQL shell
docker-compose exec mysql mysql -u root -p
```

### Generate Fresh Data

```bash
# Remove existing data and regenerate
docker-compose down -v
docker-compose up -d
docker-compose run data_generator
```

## 🔍 Monitoring

### Health Checks

All MySQL containers include health checks:

```bash
# Check health status
docker-compose ps

# Detailed health info
docker inspect clinic_mysql --format='{{json .State.Health}}'
```

### Resource Usage

```bash
# Monitor container resources
docker stats

# Check disk usage
docker system df
```

## 🧹 Maintenance

### Clean Up

```bash
# Stop and remove containers for one example
docker-compose down

# Also remove volumes (WARNING: deletes data)
docker-compose down -v

# Clean all examples
./docker-manager.sh clean all

# Remove unused Docker resources
docker system prune -a
```

### Update Images

```bash
# Pull latest images
docker-compose pull

# Rebuild generator image
docker-compose build --no-cache data_generator
```

## 🐛 Troubleshooting

### Common Issues

**Port Already in Use**
```bash
# Find process using port
lsof -i :3308  # Mac/Linux
netstat -ano | findstr :3308  # Windows

# Change port in docker-compose.yml
ports:
  - "3408:3306"  # Use different port
```

**MySQL Connection Refused**
```bash
# Check if MySQL is ready
docker-compose exec mysql mysqladmin -u root -p ping

# Wait for health check
docker-compose exec mysql sh -c 'until mysqladmin ping -h localhost -p; do sleep 1; done'
```

**Out of Disk Space**
```bash
# Clean up Docker resources
docker system prune -a --volumes

# Check volume sizes
docker ps -s
```

**Slow Performance**
```bash
# Increase Docker Desktop memory (Settings > Resources)
# Recommended: 4GB+ for running multiple examples

# Optimize MySQL settings in docker-compose.yml
--innodb_buffer_pool_size=4G
--innodb_log_file_size=512M
```

### Debug Mode

Enable detailed logging:

```yaml
mysql:
  environment:
    MYSQL_LOG_CONSOLE: "true"
  command:
    - --general_log=1
    - --general_log_file=/var/log/mysql/general.log
```

## 🔐 Security Notes

### Production Considerations

⚠️ **The default configurations are for development only!**

For production:
1. Change all default passwords
2. Use secrets management (Docker Secrets, HashiCorp Vault)
3. Enable SSL/TLS for connections
4. Restrict network access
5. Regular security updates

### Secure Configuration Example

```yaml
# docker-compose.prod.yml
mysql:
  secrets:
    - mysql_root_password
    - mysql_user_password
  environment:
    MYSQL_ROOT_PASSWORD_FILE: /run/secrets/mysql_root_password
    MYSQL_PASSWORD_FILE: /run/secrets/mysql_user_password

secrets:
  mysql_root_password:
    external: true
  mysql_user_password:
    external: true
```

## 📚 Advanced Usage

### Multi-Stage Environments

```bash
# Development
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up

# Production
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up
```

### Scaling Services

```bash
# Scale data generators
docker-compose up -d --scale data_generator=3
```

### Custom Networks

Connect examples together:

```yaml
networks:
  shared_network:
    external: true
    name: mysql_examples_network
```

## 🤝 Contributing

To add a new example with Docker support:

1. Create docker-compose.yml in the example directory
2. Use consistent port numbering (33XX for MySQL, 80XX for phpMyAdmin)
3. Include health checks for reliability
4. Add to port mapping documentation
5. Test with the docker-manager script

## 📖 Additional Resources

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [MySQL Docker Hub](https://hub.docker.com/_/mysql)
- [phpMyAdmin Docker Hub](https://hub.docker.com/_/phpmyadmin)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

---

*For more information about specific database examples, see the README.md in each example directory.*