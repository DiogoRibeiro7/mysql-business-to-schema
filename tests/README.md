# MySQL Business-to-Schema Testing Suite

Comprehensive testing framework covering unit tests, integration tests, end-to-end tests, performance tests, and chaos engineering.

## 📋 Table of Contents

- [Test Structure](#test-structure)
- [Quick Start](#quick-start)
- [Test Categories](#test-categories)
- [Running Tests](#running-tests)
- [Writing Tests](#writing-tests)
- [CI/CD Integration](#cicd-integration)
- [Performance Baselines](#performance-baselines)
- [Troubleshooting](#troubleshooting)

## 🗂️ Test Structure

```
tests/
├── __init__.py              # Test package initialization
├── conftest.py              # Shared fixtures and configuration
├── config/
│   └── local.yaml          # Test environment configuration
├── unit/                   # Unit tests (isolated, fast)
│   └── test_generators.py
├── integration/            # Integration tests (database, services)
│   └── test_database_operations.py
├── e2e/                    # End-to-end tests (full stack)
│   └── test_web_demo.py
├── performance/            # Performance and load tests
│   └── test_load.py
├── chaos/                  # Chaos engineering tests
│   └── test_chaos_engineering.py
└── README.md              # This file
```

## 🚀 Quick Start

### Prerequisites

1. **Install Dependencies**:
```bash
pip install -r test-requirements.txt
playwright install chromium
```

2. **Start Test Infrastructure**:
```bash
docker-compose up -d mysql redis kafka
```

3. **Run Tests**:
```bash
# Run all tests
pytest

# Run specific category
pytest -m unit
pytest -m integration
pytest -m e2e
```

### Using Make Commands

```bash
# Install everything
make install

# Run all tests
make test

# Run specific test types
make test-unit
make test-integration
make test-e2e
make test-performance
make test-chaos

# Generate coverage report
make coverage
```

## 📊 Test Categories

### Unit Tests
Fast, isolated tests for individual components.

```bash
pytest tests/unit/ -v
```

**Coverage**: Data generators, validators, utilities
**Runtime**: < 10 seconds
**Dependencies**: None

### Integration Tests
Tests that interact with databases and external services.

```bash
pytest tests/integration/ -v
```

**Coverage**: Database operations, schema creation, replication
**Runtime**: 1-2 minutes
**Dependencies**: MySQL, Redis

### End-to-End Tests
Full stack tests including UI and API.

```bash
pytest tests/e2e/ -v
```

**Coverage**: Web UI, GraphQL API, REST endpoints
**Runtime**: 3-5 minutes
**Dependencies**: All services running

### Performance Tests
Load testing and performance benchmarking.

```bash
pytest tests/performance/ -v
```

**Coverage**: Query performance, load handling, resource usage
**Runtime**: 5-10 minutes
**Dependencies**: Full environment

### Chaos Tests
Resilience testing with failure injection.

```bash
pytest tests/chaos/ -v
```

**Coverage**: Connection failures, resource exhaustion, recovery
**Runtime**: 2-5 minutes
**Dependencies**: Full environment

## 🏃 Running Tests

### Basic Commands

```bash
# Run all tests
pytest

# Run with verbose output
pytest -v

# Run specific test file
pytest tests/unit/test_generators.py

# Run tests matching pattern
pytest -k "test_patient"

# Run with coverage
pytest --cov=. --cov-report=html

# Run in parallel
pytest -n auto

# Stop on first failure
pytest -x

# Run only failed tests from last run
pytest --lf
```

### Using Markers

```bash
# Run only unit tests
pytest -m unit

# Run non-slow tests
pytest -m "not slow"

# Run smoke tests for quick validation
pytest -m smoke

# Combine markers
pytest -m "unit and not slow"
```

### Performance Testing

```bash
# Run performance tests
pytest tests/performance/ -v

# Run load test with Locust
locust -f tests/performance/test_load.py --host=http://localhost:3001

# Save performance baseline
pytest tests/performance/ --benchmark-save=baseline

# Compare with baseline
pytest tests/performance/ --benchmark-compare=baseline
```

### Chaos Engineering

```bash
# Run chaos tests (use with caution)
pytest tests/chaos/ -v

# Run specific chaos scenario
pytest tests/chaos/test_chaos_engineering.py::TestDatabaseChaos::test_connection_pool_exhaustion
```

## ✍️ Writing Tests

### Test Structure

```python
import pytest
from unittest.mock import Mock

@pytest.mark.unit
class TestExample:
    """Test class description."""

    @pytest.fixture
    def setup_data(self):
        """Setup fixture for tests."""
        return {"test": "data"}

    def test_feature(self, setup_data):
        """Test specific feature."""
        # Arrange
        expected = "data"

        # Act
        result = setup_data["test"]

        # Assert
        assert result == expected

    @pytest.mark.slow
    def test_slow_operation(self):
        """Test that takes longer to run."""
        # Test implementation
        pass
```

### Using Fixtures

```python
def test_with_database(mysql_connection, mysql_cursor):
    """Test using database fixtures."""
    mysql_cursor.execute("SELECT 1")
    result = mysql_cursor.fetchone()
    assert result is not None

def test_with_test_data(test_data_generator):
    """Test using data generator fixture."""
    users = test_data_generator["users"](count=5)
    assert len(users) == 5
```

### Async Tests

```python
@pytest.mark.asyncio
async def test_async_operation():
    """Test async functionality."""
    result = await async_function()
    assert result is not None
```

### Performance Tests

```python
def test_performance(benchmark):
    """Test with performance benchmark."""
    result = benchmark(expensive_function, arg1, arg2)
    assert result is not None
```

## 🔄 CI/CD Integration

### GitHub Actions

```yaml
- name: Run Tests
  run: |
    pip install -r test-requirements.txt
    pytest tests/ -v --junitxml=test-results.xml --cov=. --cov-report=xml

- name: Upload Coverage
  uses: codecov/codecov-action@v3
  with:
    file: ./coverage.xml
```

### Jenkins

```groovy
stage('Test') {
    steps {
        sh 'make test-ci'
        junit 'test-results.xml'
        publishHTML(target: [
            reportDir: 'htmlcov',
            reportFiles: 'index.html',
            reportName: 'Coverage Report'
        ])
    }
}
```

### GitLab CI

```yaml
test:
  script:
    - pip install -r test-requirements.txt
    - pytest --junitxml=report.xml --cov=. --cov-report=term
  artifacts:
    reports:
      junit: report.xml
  coverage: '/TOTAL.*\s+(\d+%)$/'
```

## 📈 Performance Baselines

### Creating Baselines

```bash
# Run performance tests and save baseline
pytest tests/performance/ --benchmark-save=baseline

# Save named baseline
pytest tests/performance/ --benchmark-save=v1.0
```

### Comparing Performance

```bash
# Compare with baseline
pytest tests/performance/ --benchmark-compare=baseline

# Compare specific versions
pytest tests/performance/ --benchmark-compare=v1.0

# Generate comparison report
pytest tests/performance/ --benchmark-compare=baseline --benchmark-compare-fail=mean:10%
```

## 🔧 Configuration

### pytest.ini
Configure pytest behavior in `pytest.ini`:

```ini
[pytest]
markers =
    slow: marks tests as slow
    integration: marks tests as integration tests
addopts = -v --tb=short
```

### Test Environment
Configure test environment in `tests/config/local.yaml`:

```yaml
mysql:
  host: localhost
  port: 3306
  user: root
  password: root

performance:
  max_query_time: 1.0
  max_memory_usage: 512
```

## 🐛 Troubleshooting

### Common Issues

**MySQL Connection Errors**
```bash
# Ensure MySQL is running
docker-compose up -d mysql

# Check connection
mysql -h localhost -P 3306 -u root -proot
```

**Playwright/Selenium Issues**
```bash
# Install browsers
playwright install chromium

# Install with dependencies
playwright install-deps
```

**Test Discovery Issues**
```bash
# Check test discovery
pytest --collect-only

# Verify test paths
pytest --rootdir=. tests/
```

**Performance Test Failures**
```bash
# Increase timeout for slow tests
pytest --timeout=600

# Skip performance tests in CI
pytest -m "not performance"
```

### Debug Mode

```bash
# Run with Python debugger
pytest --pdb

# Run with IPython debugger
pytest --pdbcls=IPython.terminal.debugger:TerminalPdb

# Show local variables on failure
pytest -l

# Verbose output with full diff
pytest -vv
```

### Test Reports

```bash
# HTML report
pytest --html=report.html --self-contained-html

# Allure report
pytest --alluredir=allure-results
allure serve allure-results

# JUnit XML for CI
pytest --junitxml=test-results.xml
```

## 📊 Metrics and KPIs

### Test Coverage Goals
- **Unit Tests**: > 80% coverage
- **Integration Tests**: > 70% coverage
- **Overall**: > 75% coverage

### Performance Targets
- **API Response**: < 200ms average
- **Database Queries**: < 100ms P95
- **Load Handling**: 1000+ req/sec

### Quality Gates
- All tests passing
- No high-severity security issues
- Coverage above threshold
- Performance within baselines

## 🔗 Related Documentation

- [Main README](../README.md)
- [API Documentation](../docs/API_DOCUMENTATION.md)
- [Performance Guide](../performance-testing/README.md)
- [CI/CD Pipeline](../.github/workflows/main.yml)

## 📝 License

This testing suite is part of the MySQL Business-to-Schema project and follows the same license.
