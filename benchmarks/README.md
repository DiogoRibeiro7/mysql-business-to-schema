# Performance Benchmarking Suite

## 🚀 Overview

The Performance Benchmarking Suite provides comprehensive performance analysis for the MySQL Business-to-Schema project. It measures and tracks performance across data generators, query execution, and index effectiveness.

## 📊 Features

### 1. **Generator Benchmarking**
- Measures data generation speed (rows/second)
- Tracks memory and CPU usage
- Monitors batch processing efficiency
- Compares performance across examples

### 2. **Query Performance Analysis**
- Benchmarks query execution times
- Analyzes query plans (EXPLAIN)
- Identifies slow queries
- Measures index usage effectiveness

### 3. **Index Effectiveness Analysis**
- Detects unused indexes
- Finds duplicate/redundant indexes
- Recommends missing indexes
- Calculates index efficiency scores

### 4. **Performance Regression Detection**
- Compares benchmarks over time
- Detects performance degradations
- Provides health scores
- Generates actionable recommendations

## 🎯 Quick Start

### Run Complete Benchmark Suite

```bash
# Run all benchmarks (sequential)
python run_benchmarks.py

# Run in parallel for faster execution
python run_benchmarks.py --parallel

# Benchmark specific examples
python run_benchmarks.py --examples clinic ecommerce fintech

# Run specific benchmark types
python run_benchmarks.py --benchmarks generator query
```

### Individual Benchmark Tools

#### Generator Benchmarking
```bash
python tools/benchmark.py --examples clinic --mode test
```

#### Query Performance
```bash
python benchmarks/query_performance.py
```

#### Index Analysis
```bash
python benchmarks/index_analyzer.py
```

#### Regression Detection
```bash
python benchmarks/regression_detector.py --latest
```

## 📈 Performance Metrics

### Generator Metrics
- **Duration**: Total time to generate data
- **Rows/Second**: Data generation throughput
- **Memory Peak**: Maximum memory usage (MB)
- **CPU Peak**: Maximum CPU utilization (%)
- **Batch Efficiency**: Records per batch operation

### Query Metrics
- **Execution Time**: Query runtime (ms)
- **Rows Examined**: Number of rows scanned
- **Rows Returned**: Result set size
- **Index Usage**: Which indexes were used
- **Cache Hit Rate**: Query cache effectiveness

### Index Metrics
- **Cardinality**: Unique values in index
- **Selectivity**: Cardinality / Total Rows
- **Size**: Index size on disk (MB)
- **Usage Count**: How often index is used
- **Efficiency Score**: Overall effectiveness (0-100)

## 📂 Output Structure

```
benchmark_results/
├── benchmark_20260219_143022.json       # Complete benchmark run
├── regression_reports/
│   └── regression_20260219_144532.json  # Regression analysis
├── query_benchmarks/
│   ├── clinic_query_benchmark.json      # Per-example query analysis
│   └── ecommerce_query_benchmark.json
└── index_analysis/
    ├── clinic_index_analysis.json       # Index effectiveness reports
    └── ecommerce_index_analysis.json
```

## 🔧 Configuration

### Environment Variables

```bash
# Generator benchmarking
export GENERATOR_MODE=test      # test/development/production
export BENCHMARK_ITERATIONS=10  # Number of benchmark runs

# Query benchmarking
export QUERY_WARMUP=3           # Warmup iterations
export QUERY_ITERATIONS=10      # Benchmark iterations

# Regression detection
export REGRESSION_THRESHOLD=10  # Percentage threshold for regression
```

### Configuration File

Create `benchmark_config.json`:

```json
{
  "parallel": true,
  "examples": ["clinic", "ecommerce", "fintech"],
  "benchmarks": ["generator", "query", "index"],
  "thresholds": {
    "regression": {
      "low": 10,
      "medium": 25,
      "high": 50,
      "critical": 100
    }
  }
}
```

## 📊 Understanding Results

### Health Score (0-100)
- **90-100**: Excellent performance
- **70-89**: Good performance
- **50-69**: Acceptable, optimization recommended
- **30-49**: Poor performance, investigation needed
- **0-29**: Critical issues, immediate action required

### Severity Levels
- **CRITICAL**: >100% performance degradation
- **HIGH**: 50-100% degradation
- **MEDIUM**: 25-50% degradation
- **LOW**: 10-25% degradation
- **INFO**: <10% change

## 🔄 Continuous Integration

### GitHub Actions Workflow

The suite includes automated performance testing via GitHub Actions:

```yaml
# .github/workflows/performance.yml
name: Performance Benchmarks
on:
  push:
    branches: [main, develop]
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM
```

### Pull Request Checks

Performance regression checks run on PRs to prevent degradations:

```bash
# Run regression check
python benchmarks/regression_detector.py \
  --baseline main_benchmark.json \
  --current pr_benchmark.json
```

## 📈 Performance Trends

### Viewing Historical Data

```python
from benchmarks.trend_analyzer import TrendAnalyzer

analyzer = TrendAnalyzer('benchmark_results')
trends = analyzer.analyze_trends(days=30)
analyzer.plot_trends('generator_time')
```

### Generating Reports

```bash
# Generate HTML report
python benchmarks/report_generator.py --format html --output report.html

# Generate Markdown report for GitHub
python benchmarks/report_generator.py --format markdown --output PERFORMANCE.md
```

## 🎯 Optimization Recommendations

### Common Performance Issues

1. **Slow Generators**
   - Use bulk inserts instead of individual INSERTs
   - Increase batch sizes
   - Disable autocommit during generation
   - Use prepared statements

2. **Slow Queries**
   - Add appropriate indexes
   - Optimize JOIN operations
   - Use query result caching
   - Consider query rewriting

3. **Inefficient Indexes**
   - Remove unused indexes
   - Consolidate duplicate indexes
   - Add covering indexes for frequent queries
   - Optimize index column order

## 🔍 Troubleshooting

### Common Issues

**Docker containers not running**
```bash
# Start containers before benchmarking
./docker-manager.sh start all
```

**Permission denied errors**
```bash
# Ensure scripts are executable
chmod +x run_benchmarks.py
chmod +x benchmarks/*.py
```

**MySQL connection errors**
```bash
# Check connection parameters
mysql -h localhost -P 3308 -u root -p
```

**Out of memory during benchmarks**
```bash
# Reduce batch sizes or run sequentially
python run_benchmarks.py --no-parallel
```

## 📚 Advanced Usage

### Custom Benchmark Queries

```python
from benchmarks.query_performance import QueryPerformanceBenchmark, QueryType

benchmark = QueryPerformanceBenchmark(connection_params)
benchmark.connect()

# Add custom query
custom_query = """
    SELECT c.name, COUNT(o.id) as order_count
    FROM customers c
    LEFT JOIN orders o ON c.id = o.customer_id
    GROUP BY c.id
    HAVING order_count > 10
"""

result = benchmark.benchmark_query(
    custom_query,
    QueryType.COMPLEX_JOIN,
    warmup=5,
    iterations=20
)

print(f"Execution time: {result.execution_time}ms")
```

### Exporting to External Systems

```python
# Export to Prometheus
from benchmarks.exporters import PrometheusExporter

exporter = PrometheusExporter()
exporter.export_metrics(benchmark_results)

# Export to Grafana
from benchmarks.exporters import GrafanaExporter

exporter = GrafanaExporter(api_key='your_api_key')
exporter.create_dashboard(benchmark_results)
```

## 🤝 Contributing

### Adding New Benchmarks

1. Create a new module in `benchmarks/`
2. Inherit from `BaseBenchmark` class
3. Implement required methods:
   - `setup()`
   - `run()`
   - `analyze()`
   - `cleanup()`
4. Add to `run_benchmarks.py`

### Benchmark Best Practices

- Always include warmup runs
- Use median instead of average for stability
- Monitor system resources during benchmarks
- Run multiple iterations for statistical significance
- Document all metrics and thresholds
- Include error handling and timeouts

## 📖 API Reference

### BenchmarkRunner

```python
class BenchmarkRunner:
    def __init__(self, project_root: Path, config: Dict)
    def run_all(self) -> Dict
    def export_results(self, format: str, output: Path)
```

### QueryPerformanceBenchmark

```python
class QueryPerformanceBenchmark:
    def benchmark_query(sql: str, query_type: QueryType) -> QueryBenchmark
    def benchmark_table_queries(table: str) -> List[QueryBenchmark]
    def analyze_results(self) -> Dict
```

### IndexAnalyzer

```python
class IndexAnalyzer:
    def analyze_all_indexes(self) -> Dict
    def find_duplicate_indexes(self) -> List[Dict]
    def recommend_missing_indexes(self) -> List[Dict]
```

### RegressionDetector

```python
class RegressionDetector:
    def compare_benchmarks(baseline: str, current: str) -> Dict
    def calculate_health_score(self) -> float
    def generate_recommendations(self) -> List[Dict]
```

## 📝 License

This benchmarking suite is part of the MySQL Business-to-Schema project and follows the same license terms.

---

For more information, see the [main project README](../README.md) or visit the [project documentation](../docs/).