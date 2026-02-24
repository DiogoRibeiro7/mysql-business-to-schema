# MySQL Business-to-Schema Performance Testing Suite

Comprehensive performance testing, load testing, and chaos engineering infrastructure.

## 🎯 Testing Philosophy

```
┌─────────────────────────────────────────────────────────────┐
│                    Performance Testing Pyramid               │
│                                                               │
│                          ┌───────┐                           │
│                         /│ Chaos │\                          │
│                        / └───────┘ \                         │
│                       /   Testing   \                        │
│                      /┌─────────────┐\                       │
│                     / │   Stress    │ \                      │
│                    /  │   Testing   │  \                     │
│                   /   └─────────────┘   \                    │
│                  /┌───────────────────────┐\                 │
│                 / │     Load Testing      │ \                │
│                /  │   (Normal conditions) │  \               │
│               /   └───────────────────────┘   \              │
│              /┌─────────────────────────────────┐\            │
│             / │    Performance Baselines        │ \           │
│            /  │   (Smoke tests, unit perf)      │  \          │
│           /   └─────────────────────────────────┘   \         │
│          ─────────────────────────────────────────────        │
└───────────────────────────────────────────────────────────────┘
```

## 🚀 Components

### 1. **Load Testing Tools**

#### Locust
- Python-based load testing
- Distributed testing with master/worker architecture
- Real-time web UI
- Custom user scenarios

#### K6
- JavaScript-based performance testing
- Cloud-native and DevOps-friendly
- Advanced metrics and thresholds
- Integration with Grafana

#### Gatling
- High-performance load testing
- Scala-based DSL
- Detailed reports and analytics
- Enterprise-grade features

#### JMeter
- Java-based testing framework
- GUI and CLI modes
- Protocol support (HTTP, JDBC, JMS, etc.)
- Extensive plugin ecosystem

### 2. **Chaos Engineering**

#### Chaos Monkey
- Container failures
- Network chaos (delay, loss, corruption)
- Resource stress (CPU, memory, disk)
- Database chaos
- API failures

#### Pumba
- Network emulation
- Container chaos
- Docker-specific failures

#### Toxiproxy
- Network simulation
- Latency injection
- Connection failures
- Bandwidth limiting

### 3. **Monitoring & Analysis**

- **InfluxDB**: Time-series metrics storage
- **Grafana**: Real-time dashboards
- **Prometheus**: Metrics collection
- **PostgreSQL**: Test results storage
- **Redis**: Test coordination

## 📦 Quick Start

### Prerequisites
- Docker and Docker Compose
- Python 3.8+
- Node.js 14+
- 8GB+ RAM available

### Installation

```bash
# Clone repository
git clone <repository-url>
cd performance-testing

# Start infrastructure
docker-compose up -d

# Install Python dependencies
pip install -r requirements.txt

# Install K6
brew install k6  # macOS
# or
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update
sudo apt-get install k6  # Ubuntu/Debian
```

### Running Tests

#### Locust Testing
```bash
# Start Locust UI
docker-compose up locust-master locust-worker-1 locust-worker-2

# Access UI
open http://localhost:8089

# Run headless
locust -f locust/locustfile.py --headless -u 100 -r 10 -t 5m --host http://localhost:8000
```

#### K6 Testing
```bash
# Run smoke test
k6 run k6/load-test.js --stage smoke_test

# Run load test
k6 run k6/load-test.js

# Run with cloud output
k6 run --out cloud k6/load-test.js

# Run specific scenario
k6 run k6/load-test.js --env SCENARIO=stress_test
```

#### Chaos Testing
```bash
# Start Chaos Monkey (dry run)
python chaos/chaos_monkey.py chaos/config/dry-run.yaml

# Start Chaos Monkey (production)
python chaos/chaos_monkey.py chaos/config/production.yaml

# Use Pumba for network chaos
docker run -it --rm -v /var/run/docker.sock:/var/run/docker.sock \
  gaiaadm/pumba netem --duration 30s delay --time 1000 re2:^mysql
```

## 📊 Test Scenarios

### 1. Smoke Test
- **Duration**: 1 minute
- **Users**: 2
- **Purpose**: Basic functionality check
- **Pass Criteria**: 0% error rate

### 2. Load Test
- **Duration**: 15 minutes
- **Users**: 50-100 (ramping)
- **Purpose**: Normal load conditions
- **Pass Criteria**: <5% error rate, p95 <500ms

### 3. Stress Test
- **Duration**: 20 minutes
- **Users**: 100-300 (ramping)
- **Purpose**: Find breaking point
- **Pass Criteria**: Graceful degradation

### 4. Spike Test
- **Duration**: 2 minutes
- **Users**: 0-500 (sudden spike)
- **Purpose**: Handle traffic bursts
- **Pass Criteria**: Recovery within 30s

### 5. Soak Test
- **Duration**: 30+ minutes
- **Users**: 50 (constant)
- **Purpose**: Memory leaks, resource exhaustion
- **Pass Criteria**: Stable memory/CPU usage

### 6. Breakpoint Test
- **Duration**: Until failure
- **Users**: Increasing until break
- **Purpose**: Find absolute limits
- **Pass Criteria**: Identify max capacity

## 🔧 Configuration

### Test Configuration
```yaml
# config/test-config.yaml
scenarios:
  - name: "E-commerce Load Test"
    type: "load"
    target_url: "http://api.example.com"
    duration: 900  # 15 minutes
    users: 100
    ramp_up: 60
    thresholds:
      error_rate: 0.05
      p95_response_time: 500
      p99_response_time: 1000

  - name: "API Stress Test"
    type: "stress"
    target_url: "http://api.example.com"
    duration: 1200  # 20 minutes
    stages:
      - duration: 120
        target: 100
      - duration: 300
        target: 200
      - duration: 300
        target: 300
```

### Chaos Configuration
```yaml
# chaos/config/production.yaml
enabled: true
dry_run: false
schedule: "*/10 * * * *"  # Every 10 minutes
max_concurrent_events: 2

targets:
  containers:
    - "mysql-*"
    - "api-*"
    - "kafka-*"
  excluded:
    - "monitoring-*"
    - "chaos-monkey"

events:
  - type: "container_kill"
    probability: 0.05
    duration: 0

  - type: "network_delay"
    probability: 0.20
    duration: 60
    metadata:
      delay: "200ms"
      variance: "50ms"

  - type: "cpu_stress"
    probability: 0.15
    duration: 30
    intensity: 0.5
```

## 📈 Metrics & KPIs

### Performance Metrics
- **Response Time**: p50, p95, p99 percentiles
- **Throughput**: Requests per second (RPS)
- **Error Rate**: Failed requests percentage
- **Concurrency**: Active users/connections

### Resource Metrics
- **CPU Usage**: Per container/service
- **Memory Usage**: Heap, RSS, cache
- **Disk I/O**: Read/write operations
- **Network I/O**: Bandwidth, packet loss

### Business Metrics
- **Transaction Success Rate**
- **Order Processing Time**
- **API Availability** (uptime)
- **Database Query Performance**

## 📊 Test Coordinator API

### Create Test
```bash
curl -X POST http://localhost:5000/api/tests \
  -H "Content-Type: application/json" \
  -d '{
    "test_type": "locust",
    "name": "E-commerce Load Test",
    "target_url": "http://api.example.com",
    "duration": 300,
    "users": 50
  }'
```

### Run Test
```bash
curl -X POST http://localhost:5000/api/tests/{test_id}/run
```

### Get Results
```bash
curl http://localhost:5000/api/tests/{test_id}/results
```

### View Report
```bash
open http://localhost:5000/reports/{test_id}
```

## 🎯 Performance Goals

### API Performance
| Endpoint | p50 | p95 | p99 | Max |
|----------|-----|-----|-----|-----|
| GET /api/patients | 50ms | 200ms | 500ms | 1s |
| POST /api/orders | 100ms | 500ms | 1s | 2s |
| POST /api/iot/readings | 20ms | 100ms | 200ms | 500ms |

### Database Performance
| Operation | Target | Threshold |
|-----------|--------|-----------|
| Simple SELECT | <10ms | <50ms |
| Complex JOIN | <100ms | <500ms |
| INSERT | <20ms | <100ms |
| Bulk INSERT | <1ms/row | <5ms/row |

### System Capacity
| Metric | Target | Minimum |
|--------|--------|---------|
| Concurrent Users | 1,000 | 500 |
| RPS (reads) | 10,000 | 5,000 |
| RPS (writes) | 1,000 | 500 |
| Database Connections | 500 | 200 |

## 🔍 Troubleshooting

### Common Issues

#### 1. High Response Times
```bash
# Check database slow queries
docker exec mysql mysql -e "SHOW PROCESSLIST"

# Check application logs
docker logs api-container

# Profile with k6
k6 run --http-debug k6/debug-test.js
```

#### 2. Memory Leaks
```bash
# Monitor memory usage
docker stats

# Heap dump for Java apps
docker exec app jmap -dump:format=b,file=/tmp/heap.bin <pid>

# Python memory profiling
pip install memory_profiler
python -m memory_profiler app.py
```

#### 3. Connection Errors
```bash
# Check connection pools
curl http://localhost:8000/api/health/db

# Network diagnostics
docker run --rm --network container:api nicolaka/netshoot ss -tan

# Trace network issues
docker run --rm --network container:api nicolaka/netshoot traceroute mysql
```

## 📝 Reports

### Locust HTML Report
Generated automatically after test completion:
- Request statistics
- Response time charts
- Failure analysis
- Download as CSV/JSON

### K6 Summary Report
```javascript
✓ http_req_duration.........: avg=142.23ms min=89.43ms med=125.65ms max=2.34s p(95)=487.21ms p(99)=1.23s
✓ http_req_failed...........: 0.42% ✓ 126 ✗ 29874
✓ http_reqs.................: 30000 500/s
```

### Grafana Dashboard
Access at http://localhost:3001
- Real-time metrics
- Historical trends
- Custom queries
- Alert configuration

## 🚨 CI/CD Integration

### Jenkins Pipeline
```groovy
pipeline {
    agent any
    stages {
        stage('Performance Test') {
            steps {
                sh 'k6 run --out json=results.json k6/load-test.js'
                sh 'python analyze_results.py results.json'
            }
        }
        stage('Chaos Test') {
            when {
                branch 'staging'
            }
            steps {
                sh 'python chaos/chaos_monkey.py chaos/config/staging.yaml'
            }
        }
    }
    post {
        always {
            archiveArtifacts artifacts: 'results/**/*'
            publishHTML target: [
                reportDir: 'results',
                reportFiles: 'index.html',
                reportName: 'Performance Report'
            ]
        }
    }
}
```

### GitHub Actions
```yaml
name: Performance Tests
on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM
  workflow_dispatch:

jobs:
  performance:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run K6 tests
        uses: grafana/k6-action@v0.3.0
        with:
          filename: k6/load-test.js
          flags: --out cloud
      - name: Upload results
        uses: actions/upload-artifact@v2
        with:
          name: performance-results
          path: results/
```

## 📚 Best Practices

### 1. Test Design
- Start with baseline tests
- Gradually increase complexity
- Use realistic data and scenarios
- Test in production-like environments

### 2. Monitoring
- Monitor both application and infrastructure
- Set up alerts for anomalies
- Correlate performance with business metrics
- Use distributed tracing

### 3. Chaos Engineering
- Start with known failure modes
- Gradually increase chaos intensity
- Always have rollback plans
- Document lessons learned

### 4. Reporting
- Automate report generation
- Track performance trends
- Share results with stakeholders
- Create action items from findings

## 🤝 Contributing

To add new test scenarios:

1. Create scenario file in appropriate directory
2. Add configuration to test coordinator
3. Update CI/CD pipelines
4. Document expected results
5. Add to monitoring dashboards

## 📄 License

Part of the MySQL Business-to-Schema project.