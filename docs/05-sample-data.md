# Sample Data

## Overview
Sample data is critical for testing database designs, validating queries, and understanding performance characteristics. This repository provides multiple approaches to generating and loading test data.

## Data Generation Approaches

### 1. Static SQL Seed Files
Located in `example_XX/data/seed.sql`, these provide:
- **Deterministic** - Same data every time
- **Small scale** - Usually 100-1000 records
- **Hand-crafted** - Specific test scenarios
- **Quick loading** - Direct SQL inserts

Example:
```sql
-- Load seed data
mysql -u root -p database_name < data/seed.sql
```

### 2. Python Data Generators
Available for 6 of 9 examples in the `generators/` directory:
- **Configurable** - YAML-based settings
- **Scalable** - Generate millions of records
- **Realistic** - Business patterns and distributions
- **Reproducible** - Seed-based randomization

Example:
```bash
cd generators/iot_bins
python generate.py --config config.yaml
```

### 3. Stored Procedure Generators
Some examples include procedure-based generators:
```sql
CALL generate_test_data(1000); -- Generate 1000 records
```

## Data Characteristics by Example

### Time Series Data (IoT Examples)
- **Frequency**: 1 second to 1 hour intervals
- **Volume**: 100K-10M readings per day
- **Patterns**: Daily/weekly seasonality
- **Anomalies**: 1-5% outliers included
- **Gaps**: Realistic sensor downtime

### Transactional Data (Clinic, E-commerce)
- **Relationships**: Proper foreign key distributions
- **Business Rules**: Valid state transitions
- **Historical**: 1-2 years of history
- **Current**: Active transactions
- **Edge Cases**: Cancellations, refunds, etc.

## Loading Strategies

### Small Datasets (<100K records)
```sql
-- Direct insert
mysql -u root -p database_name < data/seed.sql
```

### Medium Datasets (100K-10M records)
```bash
# Use LOAD DATA INFILE for CSV files
mysql --local-infile=1 -u root -p

LOAD DATA LOCAL INFILE 'output/sensor_readings.csv'
INTO TABLE sensor_readings
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
```

### Large Datasets (>10M records)
```bash
# Disable checks for faster loading
SET foreign_key_checks = 0;
SET unique_checks = 0;
SET autocommit = 0;

# Load data in batches
python load_batches.py --batch-size 10000

# Re-enable checks
SET foreign_key_checks = 1;
SET unique_checks = 1;
COMMIT;
```

## Data Quality Considerations

### Realistic Distributions
- **User Activity**: Power law (80/20 rule)
- **Time Patterns**: Business hours, weekends
- **Geographic**: Population-based clustering
- **Financial**: Normal with long tail

### Data Integrity
- **Referential**: Valid foreign keys
- **Temporal**: Correct date sequences
- **Business**: Valid state transitions
- **Constraints**: Respect check constraints

### Privacy and Compliance
- **PII**: Use fake but realistic names/emails
- **HIPAA**: No real medical data
- **GDPR**: Anonymized identifiers
- **Financial**: Synthetic account numbers

## Generator Configuration

### YAML Configuration Example
```yaml
# generators/iot_bins/config.yaml
counts:
  bins: 500
  trucks: 20
  zones: 10

time_range:
  start: "2024-01-01"
  days: 30

patterns:
  fill_rate:
    daily_cycle: true
    weekly_cycle: true
    base_rate: 0.5
    variance: 0.2

output:
  format: csv
  batch_size: 10000
  compress: true
```

### Customizing Generators

1. **Adjust Volume**:
```yaml
counts:
  users: 10000  # Increase user count
  orders: 50000 # More orders
```

2. **Change Time Range**:
```yaml
time_range:
  start: "2023-01-01"
  days: 365  # Full year
```

3. **Modify Patterns**:
```yaml
patterns:
  peak_hours: [9, 12, 18]  # Rush hours
  quiet_days: ["Sunday"]    # Low activity
```

## Performance Impact

### Index Considerations
- Load data before creating non-primary indexes
- Rebuild statistics after bulk loads:
```sql
ANALYZE TABLE sensor_readings;
```

### Partitioning
For time series data, ensure even distribution:
```sql
-- Check partition distribution
SELECT
    partition_name,
    table_rows
FROM information_schema.partitions
WHERE table_name = 'sensor_readings';
```

### Memory Usage
Monitor during generation:
```bash
# Watch memory usage
watch -n 1 "mysql -e 'SHOW PROCESSLIST' && free -h"
```

## Validation

### Row Counts
```sql
-- Verify expected counts
SELECT
    'bins' as entity, COUNT(*) as count FROM bins
UNION ALL
SELECT 'readings', COUNT(*) FROM sensor_readings
UNION ALL
SELECT 'alerts', COUNT(*) FROM alerts;
```

### Data Quality Checks
```sql
-- Check for orphaned records
SELECT COUNT(*)
FROM sensor_readings r
LEFT JOIN sensors s ON r.sensor_id = s.sensor_id
WHERE s.sensor_id IS NULL;

-- Verify date ranges
SELECT
    MIN(timestamp) as earliest,
    MAX(timestamp) as latest,
    COUNT(*) as total_readings
FROM sensor_readings;
```

### Statistical Validation
```sql
-- Check distributions
SELECT
    DATE(timestamp) as day,
    COUNT(*) as readings,
    AVG(value) as avg_value,
    STDDEV(value) as std_dev
FROM sensor_readings
GROUP BY DATE(timestamp)
ORDER BY day;
```

## Troubleshooting

### Common Issues

**Out of Memory**:
- Reduce batch sizes
- Use streaming writes
- Increase system memory

**Slow Generation**:
- Use bulk inserts
- Disable autocommit
- Generate in parallel

**Invalid Data**:
- Check foreign key order
- Verify date formats
- Review constraint violations

### Debugging Generators
```python
# Add debug output
python generate.py --debug --limit 100

# Profile performance
python -m cProfile generate.py
```

## Best Practices

1. **Start Small**: Test with 100-1000 records first
2. **Incremental Loading**: Load in batches, verify each
3. **Keep Seeds**: Use same seed for reproducible tests
4. **Document Anomalies**: Note any intentional bad data
5. **Version Control**: Track generator changes
6. **Monitor Resources**: Watch disk/memory during generation
7. **Validate Output**: Always verify data quality

## Next Steps

After loading sample data:
1. Run test queries from `example_XX/queries/`
2. Check query performance with `EXPLAIN`
3. Monitor resource usage
4. Test application integration
5. Validate business rules