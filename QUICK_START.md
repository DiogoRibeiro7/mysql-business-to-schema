# MySQL Business-to-Schema - Quick Start Guide

## 🚀 Quick Setup & Testing

This guide will help you quickly set up and test the entire MySQL Business-to-Schema system.

## Prerequisites

- **Docker & Docker Compose** (required)
- **Python 3.8+** (required)
- **Node.js 14+** (optional, for frontend)
- **Git** (required)
- **16GB RAM minimum** (recommended)
- **50GB disk space** (recommended)

## 📦 Step 1: Initial Setup

```bash
# Clone the repository (if not already done)
git clone <repository-url> mysql-business-to-schema
cd mysql-business-to-schema

# Install Python dependencies
pip install -r requirements.txt

# Create necessary directories
mkdir -p data logs temp results
```

## 🐳 Step 2: Start Core Services

### Option A: Minimal Setup (Quick Testing)
```bash
# Start only essential services
docker-compose -f docker-compose.core.yml up -d

# Services started: MySQL, PostgreSQL, Redis
```

### Option B: Full System (Complete Testing)
```bash
# Start all services - WARNING: Requires significant resources
docker-compose up -d

# Wait for services to initialize (may take 2-3 minutes)
sleep 180

# Check service health
docker-compose ps
```

## 🗄️ Step 3: Initialize Databases

```bash
# Create all MySQL schemas
./scripts/init_databases.sh

# Or manually for specific schemas:
mysql -u root -proot < example_01_clinic/schema/00_create_database.sql
mysql -u root -proot < example_01_clinic/schema/01_tables.sql
mysql -u root -proot < example_01_clinic/schema/02_constraints.sql
mysql -u root -proot < example_01_clinic/schema/03_indexes.sql

# Generate test data
python generators/generate_all_data.py --records=1000
```

## 🧪 Step 4: Run System Tests

```bash
# Run comprehensive system test
python test_system.py

# Expected output:
# ✓ Directory structure validated
# ✓ Database schemas created
# ✓ API endpoints responding
# ✓ SDKs functional
# ... more tests ...
```

## 🎯 Step 5: Test Each Component

### 1. Test Admin Dashboard

```bash
# Start backend API
cd admin_dashboard/backend
uvicorn main:app --reload --port 8000 &

# Start frontend (optional)
cd ../frontend
npm install
npm start &

# Test API
curl http://localhost:8000/health
# Expected: {"status":"healthy"}

curl http://localhost:8000/api/schemas
# Expected: List of schemas

# Access UI (if frontend started)
open http://localhost:3000
```

### 2. Test Python SDK

```python
# Python test script
from mysql_business_schema import MySQLSchemaClient

# Initialize client
client = MySQLSchemaClient(host="localhost", port=8000)

# Test operations
schemas = client.list_schemas()
print(f"Found {len(schemas)} schemas")

# Test data generation
patient_data = client.generate_data("clinic", "patients", count=10)
print(f"Generated {len(patient_data)} patient records")
```

### 3. Test ML Platform

```bash
# Access MLflow UI
open http://localhost:5001

# Test model serving
curl -X POST http://localhost:3000/predict_patient_readmission \
  -H "Content-Type: application/json" \
  -d '{
    "patient_id": 1,
    "age": 65,
    "heart_rate": 75,
    "oxygen_saturation": 96
  }'
```

### 4. Test Data Pipeline

```bash
# Check Kafka topics
docker exec kafka1 kafka-topics --list --bootstrap-server localhost:9092

# Send test message
docker exec kafka1 kafka-console-producer \
  --broker-list localhost:9092 \
  --topic test-topic << EOF
{"test": "message"}
EOF

# Check ClickHouse
curl http://localhost:8123/ping
```

### 5. Test Observability

```bash
# Access monitoring dashboards
open http://localhost:3000  # Grafana
open http://localhost:9090  # Prometheus
open http://localhost:5601  # Kibana

# Check metrics
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets | length'
```

### 6. Test Performance Tools

```bash
# Run quick load test
locust -f performance-testing/locust/locustfile.py \
  --headless -u 10 -r 2 -t 30s \
  --host http://localhost:8000

# Run K6 smoke test
k6 run --stage smoke_test performance-testing/k6/load-test.js
```

## 📊 Step 6: Verify Results

### Check System Health

```bash
# Run health check script
./scripts/health_check.sh

# Or manually check each service:
curl http://localhost:8000/health  # Admin API
curl http://localhost:9090/-/healthy  # Prometheus
curl http://localhost:8123/ping  # ClickHouse
curl http://localhost:5001/health  # MLflow
```

### View Metrics

1. **Grafana Dashboards** (http://localhost:3000)
   - Login: admin/admin
   - Navigate to Dashboards → MySQL Schema Overview

2. **Prometheus Targets** (http://localhost:9090/targets)
   - All targets should show "UP" status

3. **API Documentation** (http://localhost:8000/docs)
   - Interactive Swagger UI

## 🧹 Step 7: Cleanup (Optional)

```bash
# Stop all services
docker-compose down

# Remove all data (WARNING: Deletes everything)
docker-compose down -v

# Clean up test data
rm -rf data/* logs/* temp/* results/*
```

## 🎯 Quick Test Scenarios

### Scenario 1: End-to-End Data Flow
```bash
# 1. Generate data
python generators/clinic/patient_generator.py --count=100

# 2. Insert into MySQL
mysql -u root -proot clinic_db < temp/patients_data.sql

# 3. Trigger CDC to Kafka
# (Automatic with Debezium)

# 4. Process with Flink/Spark
docker exec spark-master spark-submit /opt/spark-apps/etl_job.py

# 5. View in ClickHouse
docker exec clickhouse clickhouse-client \
  --query "SELECT COUNT(*) FROM analytics.patients_fact"
```

### Scenario 2: ML Prediction Flow
```bash
# 1. Train model
python ml-platform/train_model.py --model=patient_readmission

# 2. Deploy model
python ml-platform/deploy_model.py --model=patient_readmission

# 3. Test prediction
python ml-platform/test_prediction.py --patient-id=123
```

### Scenario 3: Performance Test
```bash
# Run comprehensive performance test
./scripts/run_performance_test.sh

# Results will be in: results/performance_report.html
```

## 📋 Validation Checklist

- [ ] All Docker containers running
- [ ] MySQL schemas created (20 total)
- [ ] Admin API responding (http://localhost:8000)
- [ ] Frontend accessible (http://localhost:3000)
- [ ] Grafana dashboards loading
- [ ] MLflow experiments visible
- [ ] Kafka topics created
- [ ] ClickHouse accessible
- [ ] Sample data generated
- [ ] SDK operations working

## 🆘 Troubleshooting

### Issue: Services not starting
```bash
# Check Docker resources
docker system df
docker system prune -a  # WARNING: Removes all unused data

# Increase Docker memory (Docker Desktop settings)
# Recommended: 8GB minimum
```

### Issue: Port conflicts
```bash
# Check port usage
netstat -an | grep -E ':(3000|8000|9090|5432|3306)'

# Stop conflicting services or change ports in docker-compose.yml
```

### Issue: Database connection errors
```bash
# Test MySQL connection
mysql -h localhost -P 3306 -u root -proot -e "SHOW DATABASES"

# Test PostgreSQL connection
psql -h localhost -p 5432 -U postgres -l
```

### Issue: API not responding
```bash
# Check logs
docker logs admin-api
docker logs mlflow-server

# Restart services
docker-compose restart admin-api
```

## 📖 Documentation

- **System Overview**: [SYSTEM_REVIEW.md](SYSTEM_REVIEW.md)
- **Admin Dashboard**: [admin_dashboard/README.md](admin_dashboard/README.md)
- **ML Platform**: [ml-platform/README.md](ml-platform/README.md)
- **Data Pipeline**: [data-pipeline/README.md](data-pipeline/README.md)
- **Performance Testing**: [performance-testing/README.md](performance-testing/README.md)

## ✅ Success Criteria

Your system is working correctly if:

1. **System Test**: `python test_system.py` shows mostly green checkmarks
2. **API Test**: `curl http://localhost:8000/api/schemas` returns schema list
3. **Database Test**: MySQL shows 20 databases with tables
4. **ML Test**: Predictions return valid JSON responses
5. **Monitoring**: Grafana shows metrics being collected

## 🎉 Congratulations!

If all tests pass, you have successfully set up and validated the complete MySQL Business-to-Schema system!

The system includes:
- 20 business domain schemas
- Full-stack admin dashboard
- ML platform with feature store
- Real-time data pipeline
- Complete observability stack
- Performance testing suite
- SDKs and CLI tools

**You're ready to start building on top of this foundation!**