# MySQL Business-to-Schema API Documentation

## 📚 Complete API Reference

This document provides comprehensive API documentation for all services in the MySQL Business-to-Schema ecosystem.

## Table of Contents

- [Authentication](#authentication)
- [Core APIs](#core-apis)
- [Admin Dashboard API](#admin-dashboard-api)
- [ML Platform API](#ml-platform-api)
- [Data Pipeline API](#data-pipeline-api)
- [WebSocket Events](#websocket-events)
- [Error Handling](#error-handling)
- [Rate Limiting](#rate-limiting)

---

## Authentication

All API endpoints (except health checks) require authentication using JWT tokens.

### Login

```http
POST /api/auth/login
Content-Type: application/json

{
  "username": "admin",
  "password": "admin123"
}
```

**Response:**
```json
{
  "access_token": "<ACCESS_TOKEN_PLACEHOLDER>",
  "refresh_token": "<REFRESH_TOKEN_PLACEHOLDER>",
  "token_type": "bearer",
  "expires_in": 3600,
  "user": {
    "id": 1,
    "username": "admin",
    "email": "admin@example.com",
    "roles": ["admin", "user"]
  }
}
```

### Refresh Token

```http
POST /api/auth/refresh
Authorization: Bearer {refresh_token}
```

### Logout

```http
POST /api/auth/logout
Authorization: Bearer {access_token}
```

---

## Core APIs

### Schema Management

#### List All Schemas

```http
GET /api/schemas
Authorization: Bearer {token}
```

**Response:**
```json
{
  "schemas": [
    {
      "id": "clinic_db",
      "name": "Clinic Management",
      "description": "Healthcare clinic management system",
      "version": "1.0.0",
      "tables_count": 15,
      "created_at": "2024-01-01T00:00:00Z"
    },
    ...
  ],
  "total": 20
}
```

#### Get Schema Details

```http
GET /api/schemas/{schema_id}
Authorization: Bearer {token}
```

**Response:**
```json
{
  "id": "clinic_db",
  "name": "Clinic Management",
  "tables": [
    {
      "name": "patients",
      "columns": 12,
      "rows": 5432,
      "indexes": 4,
      "size_mb": 2.3
    },
    ...
  ],
  "relationships": [...],
  "statistics": {...}
}
```

#### Create Schema

```http
POST /api/schemas
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "new_schema",
  "description": "New business schema",
  "tables": [
    {
      "name": "users",
      "columns": [
        {
          "name": "id",
          "type": "INT",
          "primary_key": true,
          "auto_increment": true
        },
        {
          "name": "email",
          "type": "VARCHAR(255)",
          "unique": true,
          "nullable": false
        }
      ]
    }
  ]
}
```

### Data Generation

#### Generate Test Data

```http
POST /api/data/generate
Authorization: Bearer {token}
Content-Type: application/json

{
  "schema": "clinic_db",
  "table": "patients",
  "count": 1000,
  "format": "sql",
  "options": {
    "include_relations": true,
    "seed": 42
  }
}
```

**Response:**
```json
{
  "job_id": "gen_123456",
  "status": "processing",
  "estimated_time": 30,
  "output_url": "/api/data/download/gen_123456"
}
```

#### Download Generated Data

```http
GET /api/data/download/{job_id}
Authorization: Bearer {token}
```

### Migration Management

#### List Migrations

```http
GET /api/migrations
Authorization: Bearer {token}
```

**Response:**
```json
{
  "migrations": [
    {
      "id": "20240101120000_create_patients_table",
      "schema": "clinic_db",
      "status": "applied",
      "applied_at": "2024-01-01T12:00:00Z"
    },
    ...
  ]
}
```

#### Apply Migration

```http
POST /api/migrations/apply
Authorization: Bearer {token}
Content-Type: application/json

{
  "migration_id": "20240101120000_create_patients_table",
  "target_schema": "clinic_db"
}
```

#### Rollback Migration

```http
POST /api/migrations/rollback
Authorization: Bearer {token}
Content-Type: application/json

{
  "migration_id": "20240101120000_create_patients_table",
  "target_schema": "clinic_db"
}
```

---

## Admin Dashboard API

### System Metrics

#### Get System Health

```http
GET /api/metrics/health
Authorization: Bearer {token}
```

**Response:**
```json
{
  "status": "healthy",
  "checks": {
    "database": "ok",
    "redis": "ok",
    "kafka": "ok",
    "ml_platform": "ok"
  },
  "uptime": 3600,
  "version": "1.0.0"
}
```

#### Get Performance Metrics

```http
GET /api/metrics/performance
Authorization: Bearer {token}
```

**Response:**
```json
{
  "cpu_usage": 45.2,
  "memory_usage": 62.8,
  "disk_usage": 38.5,
  "network_io": {
    "bytes_sent": 1234567890,
    "bytes_received": 9876543210
  },
  "database": {
    "connections": 42,
    "queries_per_second": 1250,
    "slow_queries": 3
  }
}
```

### User Management

#### List Users

```http
GET /api/users
Authorization: Bearer {token}
```

#### Create User

```http
POST /api/users
Authorization: Bearer {token}
Content-Type: application/json

{
  "username": "newuser",
  "email": "user@example.com",
  "password": "securepassword",
  "roles": ["user"]
}
```

#### Update User

```http
PUT /api/users/{user_id}
Authorization: Bearer {token}
Content-Type: application/json

{
  "email": "newemail@example.com",
  "roles": ["user", "analyst"]
}
```

#### Delete User

```http
DELETE /api/users/{user_id}
Authorization: Bearer {token}
```

---

## ML Platform API

### Model Management

#### List Models

```http
GET /api/ml/models
Authorization: Bearer {token}
```

**Response:**
```json
{
  "models": [
    {
      "id": "patient_readmission_v1",
      "name": "Patient Readmission Predictor",
      "version": "1.0.0",
      "status": "deployed",
      "accuracy": 0.85,
      "created_at": "2024-01-01T00:00:00Z"
    },
    ...
  ]
}
```

#### Deploy Model

```http
POST /api/ml/models/deploy
Authorization: Bearer {token}
Content-Type: application/json

{
  "model_id": "patient_readmission_v1",
  "environment": "production",
  "replicas": 3
}
```

### Predictions

#### Patient Readmission Prediction

```http
POST /api/ml/predict/patient-readmission
Authorization: Bearer {token}
Content-Type: application/json

{
  "patient_id": 123,
  "age": 65,
  "gender": "Male",
  "bmi": 28.5,
  "chronic_conditions_count": 2,
  "heart_rate": 75,
  "blood_pressure_systolic": 130,
  "blood_pressure_diastolic": 85,
  "temperature": 37.2,
  "oxygen_saturation": 96
}
```

**Response:**
```json
{
  "patient_id": 123,
  "prediction": {
    "readmission_probability": 0.72,
    "readmission_risk": "High",
    "confidence": 0.89
  },
  "recommendations": [
    "Schedule follow-up within 48 hours",
    "Monitor vital signs daily",
    "Review medication compliance"
  ],
  "model_version": "1.0.0"
}
```

#### Customer Churn Prediction

```http
POST /api/ml/predict/customer-churn
Authorization: Bearer {token}
Content-Type: application/json

{
  "customer_id": 456,
  "registration_days": 365,
  "total_orders": 12,
  "total_spent": 1250.00,
  "avg_order_value": 104.17,
  "days_since_last_order": 45
}
```

#### IoT Anomaly Detection

```http
POST /api/ml/predict/iot-anomaly
Authorization: Bearer {token}
Content-Type: application/json

{
  "device_id": "DEV001",
  "sensor_type": "temperature",
  "current_value": 85.3,
  "rolling_avg": 72.1,
  "rolling_std": 5.2
}
```

### Batch Predictions

```http
POST /api/ml/predict/batch
Authorization: Bearer {token}
Content-Type: application/json

{
  "model": "customer_churn",
  "data": [
    {"customer_id": 1, ...},
    {"customer_id": 2, ...},
    ...
  ]
}
```

---

## Data Pipeline API

### Kafka Management

#### List Topics

```http
GET /api/pipeline/kafka/topics
Authorization: Bearer {token}
```

#### Create Topic

```http
POST /api/pipeline/kafka/topics
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "new-topic",
  "partitions": 3,
  "replication_factor": 2
}
```

#### Publish Message

```http
POST /api/pipeline/kafka/publish
Authorization: Bearer {token}
Content-Type: application/json

{
  "topic": "clinic-events",
  "key": "patient-123",
  "value": {
    "event_type": "admission",
    "patient_id": 123,
    "timestamp": "2024-01-01T12:00:00Z"
  }
}
```

### Spark Jobs

#### Submit Job

```http
POST /api/pipeline/spark/submit
Authorization: Bearer {token}
Content-Type: application/json

{
  "job_name": "patient_etl",
  "class": "com.mysqlschema.PatientETL",
  "jar": "s3://bucket/patient-etl.jar",
  "args": ["--input", "kafka://clinic-events", "--output", "clickhouse://patients"]
}
```

#### Get Job Status

```http
GET /api/pipeline/spark/jobs/{job_id}
Authorization: Bearer {token}
```

### ClickHouse Queries

#### Execute Query

```http
POST /api/pipeline/clickhouse/query
Authorization: Bearer {token}
Content-Type: application/json

{
  "query": "SELECT COUNT(*) FROM patients_fact WHERE age > 65",
  "database": "analytics"
}
```

---

## WebSocket Events

### Connection

```javascript
const ws = new WebSocket('ws://localhost:8000/ws');

ws.onopen = () => {
  // Authenticate
  ws.send(JSON.stringify({
    type: 'auth',
    token: 'your_jwt_token'
  }));

  // Subscribe to events
  ws.send(JSON.stringify({
    type: 'subscribe',
    channels: ['system', 'ml', 'pipeline']
  }));
};
```

### Event Types

#### System Events
```json
{
  "type": "system",
  "event": "health_check",
  "data": {
    "status": "healthy",
    "timestamp": "2024-01-01T12:00:00Z"
  }
}
```

#### ML Events
```json
{
  "type": "ml",
  "event": "prediction_complete",
  "data": {
    "model": "patient_readmission",
    "job_id": "pred_123",
    "result": {...}
  }
}
```

#### Pipeline Events
```json
{
  "type": "pipeline",
  "event": "job_complete",
  "data": {
    "job_id": "spark_456",
    "status": "success",
    "records_processed": 10000
  }
}
```

---

## Error Handling

### Error Response Format

```json
{
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "The requested resource was not found",
    "details": {
      "resource_type": "schema",
      "resource_id": "unknown_db"
    },
    "request_id": "req_123456",
    "timestamp": "2024-01-01T12:00:00Z"
  }
}
```

### Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| UNAUTHORIZED | 401 | Authentication required |
| FORBIDDEN | 403 | Insufficient permissions |
| RESOURCE_NOT_FOUND | 404 | Resource not found |
| VALIDATION_ERROR | 400 | Invalid request data |
| CONFLICT | 409 | Resource conflict |
| RATE_LIMIT_EXCEEDED | 429 | Too many requests |
| INTERNAL_ERROR | 500 | Server error |
| SERVICE_UNAVAILABLE | 503 | Service temporarily unavailable |

---

## Rate Limiting

All API endpoints are rate-limited to prevent abuse.

### Default Limits

| Tier | Requests/Minute | Requests/Hour | Requests/Day |
|------|-----------------|---------------|--------------|
| Free | 60 | 1,000 | 10,000 |
| Basic | 300 | 10,000 | 100,000 |
| Pro | 1,000 | 50,000 | 500,000 |
| Enterprise | Unlimited | Unlimited | Unlimited |

### Rate Limit Headers

```http
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 45
X-RateLimit-Reset: 1704110460
X-RateLimit-Reset-After: 30
```

### Exceeded Rate Limit Response

```http
HTTP/1.1 429 Too Many Requests
Content-Type: application/json
Retry-After: 30

{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "API rate limit exceeded",
    "retry_after": 30
  }
}
```

---

## SDK Examples

### Python

```python
from mysql_business_schema import Client

# Initialize client
client = Client(
    base_url="http://localhost:8000",
    api_key="your_api_key"
)

# List schemas
schemas = client.schemas.list()

# Generate data
data = client.data.generate(
    schema="clinic_db",
    table="patients",
    count=100
)

# Make prediction
result = client.ml.predict(
    model="patient_readmission",
    data={"patient_id": 123, ...}
)
```

### JavaScript/TypeScript

```typescript
import { MySQLSchemaClient } from '@mysql-schema/client';

// Initialize client
const client = new MySQLSchemaClient({
  baseUrl: 'http://localhost:8000',
  apiKey: 'your_api_key'
});

// List schemas
const schemas = await client.schemas.list();

// Generate data
const data = await client.data.generate({
  schema: 'clinic_db',
  table: 'patients',
  count: 100
});

// Make prediction
const result = await client.ml.predict({
  model: 'patient_readmission',
  data: { patientId: 123, ... }
});
```

### cURL

```bash
# List schemas
curl -X GET http://localhost:8000/api/schemas \
  -H "Authorization: Bearer <TOKEN_PLACEHOLDER>"

# Generate data
curl -X POST http://localhost:8000/api/data/generate \
  -H "Authorization: Bearer <TOKEN_PLACEHOLDER>" \
  -H "Content-Type: application/json" \
  -d '{"schema":"clinic_db","table":"patients","count":100}'

# Make prediction
curl -X POST http://localhost:8000/api/ml/predict/patient-readmission \
  -H "Authorization: Bearer <TOKEN_PLACEHOLDER>" \
  -H "Content-Type: application/json" \
  -d '{"patient_id":123,"age":65,...}'
```

---

## API Versioning

The API uses URL versioning. Current version: v1

```http
GET /api/v1/schemas
GET /api/v2/schemas  # Future version
```

### Deprecation Policy

- APIs are supported for minimum 12 months after deprecation notice
- Deprecation warnings included in response headers
- Migration guides provided for breaking changes

---

## Support

For API support, please refer to:
- GitHub Issues: https://github.com/yourorg/mysql-schema/issues
- Documentation: https://docs.mysql-schema.io
- Email: api-support@mysql-schema.io
