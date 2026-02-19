# MySQL Performance Tools

## Query Performance Analyzer

A comprehensive tool for analyzing query performance across all database examples in this repository.

### Features

- **EXPLAIN Plan Analysis**: Examines query execution plans
- **Execution Time Benchmarking**: Measures query performance
- **Index Usage Statistics**: Identifies missing or unused indexes
- **Optimization Recommendations**: Provides actionable improvement suggestions
- **Cross-Example Comparison**: Compares performance across different domains

### Installation

```bash
poetry install --no-root
```

### Usage

#### Analyze a Specific Example

```bash
python query_analyzer.py --example example_01_clinic
```

#### Analyze All Examples

```bash
python query_analyzer.py --all
```

#### Save Report to File

```bash
python query_analyzer.py --all --save performance_report.txt
```

#### JSON Output Format

```bash
python query_analyzer.py --example example_10_fintech --output json
```

#### Custom Database Connection

```bash
python query_analyzer.py --host localhost --port 3306 --user root --password mypass --all
```

### Output Format

The analyzer provides detailed information for each query:

```
📊 Customer Account Overview
   Query: SELECT c.customer_id, c.email, CASE WHEN ic.customer_id IS...

   ⏱️ Execution Times:
      Average: 2.45ms
      Min: 2.31ms
      Max: 2.67ms

   📚 Index Usage:
      ✓ Table 'customers' uses index 'PRIMARY'
      ✓ Table 'accounts' uses index 'idx_customer_accounts'
      Total rows examined: 125

   💡 Recommendations:
      ✅ Query performs well with 2.45ms average execution time.
```

### Performance Metrics

#### Query Classification

- **Optimized**: < 10ms execution time
- **Acceptable**: 10-100ms execution time
- **Slow**: > 100ms execution time
- **Critical**: > 1000ms execution time

#### Index Health Indicators

- ✅ **Good**: Query uses appropriate indexes
- ⚠️ **Warning**: Full table scans on large tables
- ❌ **Critical**: Missing indexes causing performance issues

### Comparison Report

When analyzing multiple examples, the tool generates a comparison table:

```
+-------------------------+---------------+----------+------+-----------+--------+
| Example                 | Total Queries | Avg Time | Slow | Optimized | Issues |
+=========================+===============+==========+======+===========+========+
| example_01_clinic       | 24           | 5.32ms   | 0    | 22        | 2      |
| example_02_iot_bins     | 35           | 12.45ms  | 3    | 28        | 7      |
| example_10_fintech      | 40           | 8.91ms   | 2    | 35        | 5      |
+-------------------------+---------------+----------+------+-----------+--------+
```

### Optimization Recommendations

The tool provides specific recommendations based on query analysis:

1. **Missing Indexes**
   - Identifies tables doing full scans
   - Suggests columns for indexing

2. **Inefficient Joins**
   - Detects cartesian products
   - Recommends join optimization

3. **Sorting Issues**
   - Identifies filesort operations
   - Suggests ORDER BY index optimization

4. **Temporary Tables**
   - Detects queries creating temp tables
   - Recommends GROUP BY optimization

5. **Low Selectivity**
   - Identifies poor filtering efficiency
   - Suggests more selective indexes

### Example Workflow

1. **Initial Analysis**
   ```bash
   # Get baseline performance
   python query_analyzer.py --example example_02_iot_bins
   ```

2. **Review Recommendations**
   - Identify queries with issues
   - Note suggested optimizations

3. **Apply Optimizations**
   - Add recommended indexes
   - Refactor problematic queries

4. **Re-analyze**
   ```bash
   # Verify improvements
   python query_analyzer.py --example example_02_iot_bins --save after_optimization.txt
   ```

5. **Compare Results**
   - Review execution time improvements
   - Verify index usage

### Integration with CI/CD

```yaml
# .github/workflows/performance.yml
name: Query Performance Check

on: [push, pull_request]

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Setup MySQL
        run: docker-compose up -d

      - name: Load schemas
        run: ./scripts/load_all_schemas.sh

      - name: Run performance analysis
        run: |
          python tools/query_analyzer.py --all --save report.txt

      - name: Upload report
        uses: actions/upload-artifact@v2
        with:
          name: performance-report
          path: report.txt
```

### Troubleshooting

#### Connection Issues
```
Error: Can't connect to MySQL server
Solution: Ensure MySQL is running and credentials are correct
```

#### Missing Dependencies
```
Error: No module named 'mysql.connector'
Solution: pip install mysql-connector-python
```

#### Empty Results
```
Issue: No queries found in file
Solution: Ensure SQL files contain SELECT statements
```

### Advanced Usage

#### Custom Query Analysis

```python
from query_analyzer import QueryPerformanceAnalyzer

analyzer = QueryPerformanceAnalyzer()
analyzer.connect("fintech")

result = analyzer.analyze_query(
    "SELECT * FROM transactions WHERE amount > 10000",
    "High-value transactions"
)

print(analyzer.generate_report([result]))
```

#### Batch Processing

```python
# Analyze specific query patterns across all databases
for db in ['clinic', 'iot_bins', 'fintech']:
    analyzer.connect(db)
    results = analyzer.analyze_query(
        "SELECT COUNT(*) FROM transactions",
        f"Count in {db}"
    )
```

### Performance Baselines

Expected performance ranges for different query types:

| Query Type | Simple | Medium | Complex |
|------------|--------|--------|---------|
| Point Lookup | <1ms | 1-5ms | 5-10ms |
| Range Scan | <5ms | 5-20ms | 20-50ms |
| Join (2 tables) | <10ms | 10-30ms | 30-100ms |
| Join (3+ tables) | <20ms | 20-50ms | 50-200ms |
| Aggregation | <10ms | 10-100ms | 100-500ms |
| Window Functions | <50ms | 50-200ms | 200-1000ms |

### Contributing

To add new analysis features:

1. Extend `_analyze_explain()` for new EXPLAIN fields
2. Add patterns to `_generate_recommendations()`
3. Update report formatting in `generate_report()`

### Future Enhancements

- [ ] Visual query plan diagrams
- [ ] Historical performance tracking
- [ ] Automatic index recommendations
- [ ] Query rewrite suggestions
- [ ] Workload analysis
- [ ] Resource usage monitoring
