# Queries

## Overview
This document covers query patterns, optimization techniques, and best practices for the MySQL database examples in this repository. Each example includes specific query files in the `queries/` directory demonstrating real-world scenarios.

## Query Categories

### 1. Basic CRUD Operations
Found in `example_XX/queries/01_basic.sql`:
- **Create**: INSERT statements with proper null handling
- **Read**: SELECT with joins and filtering
- **Update**: Conditional updates with transactions
- **Delete**: Cascading deletes and soft deletes

### 2. Analytics Queries
Found in `example_XX/queries/02_analytics.sql`:
- **Aggregations**: SUM, AVG, COUNT with GROUP BY
- **Window Functions**: Running totals, rankings, moving averages
- **Time Series**: Date-based grouping and trending
- **Statistical**: Percentiles, standard deviation, correlation

### 3. Advanced Patterns
Found in `example_XX/queries/03_advanced.sql`:
- **Recursive CTEs**: Hierarchical data traversal
- **Pivoting**: Dynamic columns from rows
- **JSON Operations**: Extracting and manipulating JSON data
- **Full-text Search**: MATCH AGAINST for text searching

## Common Query Patterns by Domain

### IoT/Time Series Queries

#### Latest Value Per Sensor
```sql
-- Using window function (MySQL 8.0+)
WITH latest_readings AS (
    SELECT
        sensor_id,
        value,
        timestamp,
        ROW_NUMBER() OVER (PARTITION BY sensor_id ORDER BY timestamp DESC) as rn
    FROM sensor_readings
    WHERE timestamp >= NOW() - INTERVAL 1 HOUR
)
SELECT
    sensor_id,
    value,
    timestamp
FROM latest_readings
WHERE rn = 1;
```

#### Time-bucketed Aggregations
```sql
-- 15-minute averages
SELECT
    sensor_id,
    DATE_FORMAT(timestamp, '%Y-%m-%d %H:00:00') +
        INTERVAL (FLOOR(MINUTE(timestamp)/15)*15) MINUTE as time_bucket,
    AVG(value) as avg_value,
    MIN(value) as min_value,
    MAX(value) as max_value,
    COUNT(*) as sample_count
FROM sensor_readings
WHERE timestamp >= NOW() - INTERVAL 24 HOUR
GROUP BY sensor_id, time_bucket
ORDER BY sensor_id, time_bucket;
```

#### Anomaly Detection
```sql
-- Find readings outside 3 standard deviations
WITH stats AS (
    SELECT
        sensor_id,
        AVG(value) as mean_value,
        STDDEV(value) as std_value
    FROM sensor_readings
    WHERE timestamp >= NOW() - INTERVAL 7 DAY
    GROUP BY sensor_id
)
SELECT
    r.sensor_id,
    r.timestamp,
    r.value,
    s.mean_value,
    s.std_value,
    ABS(r.value - s.mean_value) / s.std_value as z_score
FROM sensor_readings r
JOIN stats s ON r.sensor_id = s.sensor_id
WHERE ABS(r.value - s.mean_value) > 3 * s.std_value
    AND r.timestamp >= NOW() - INTERVAL 1 DAY
ORDER BY z_score DESC;
```

### E-commerce Queries

#### Customer Lifetime Value
```sql
SELECT
    c.customer_id,
    c.email,
    COUNT(DISTINCT o.order_id) as total_orders,
    SUM(oi.quantity * oi.unit_price) as lifetime_value,
    MIN(o.order_date) as first_order,
    MAX(o.order_date) as last_order,
    DATEDIFF(MAX(o.order_date), MIN(o.order_date)) as customer_age_days
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id
HAVING total_orders > 0
ORDER BY lifetime_value DESC;
```

#### Product Recommendations
```sql
-- Products frequently bought together
WITH product_pairs AS (
    SELECT
        oi1.product_id as product1,
        oi2.product_id as product2,
        COUNT(*) as times_together
    FROM order_items oi1
    JOIN order_items oi2 ON oi1.order_id = oi2.order_id
        AND oi1.product_id < oi2.product_id
    GROUP BY oi1.product_id, oi2.product_id
    HAVING times_together >= 5
)
SELECT
    p1.name as product1_name,
    p2.name as product2_name,
    pp.times_together
FROM product_pairs pp
JOIN products p1 ON pp.product1 = p1.product_id
JOIN products p2 ON pp.product2 = p2.product_id
ORDER BY pp.times_together DESC
LIMIT 20;
```

### Healthcare/Clinical Queries

#### Patient Appointment History
```sql
SELECT
    p.patient_id,
    p.name,
    COUNT(a.appointment_id) as total_appointments,
    SUM(CASE WHEN a.status = 'completed' THEN 1 ELSE 0 END) as completed,
    SUM(CASE WHEN a.status = 'cancelled' THEN 1 ELSE 0 END) as cancelled,
    SUM(CASE WHEN a.status = 'no_show' THEN 1 ELSE 0 END) as no_shows,
    ROUND(100.0 * SUM(CASE WHEN a.status = 'no_show' THEN 1 ELSE 0 END) /
        COUNT(a.appointment_id), 2) as no_show_rate
FROM patients p
LEFT JOIN appointments a ON p.patient_id = a.patient_id
WHERE a.appointment_date >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
GROUP BY p.patient_id
HAVING total_appointments >= 3
ORDER BY no_show_rate DESC;
```

## Query Optimization Techniques

### 1. Index Usage

#### Check Index Usage
```sql
EXPLAIN SELECT * FROM orders WHERE customer_id = 123;

-- Look for:
-- type: ref (good) vs ALL (table scan)
-- key: which index is used
-- rows: estimated rows to examine
```

#### Force Index Usage
```sql
SELECT *
FROM orders FORCE INDEX (idx_customer_date)
WHERE customer_id = 123
    AND order_date >= '2024-01-01';
```

### 2. Query Rewriting

#### Avoid SELECT *
```sql
-- Bad
SELECT * FROM large_table;

-- Good
SELECT id, name, status FROM large_table;
```

#### Use EXISTS Instead of IN for Large Sets
```sql
-- Less efficient
SELECT * FROM orders
WHERE customer_id IN (
    SELECT customer_id FROM vip_customers
);

-- More efficient
SELECT * FROM orders o
WHERE EXISTS (
    SELECT 1 FROM vip_customers v
    WHERE v.customer_id = o.customer_id
);
```

### 3. Pagination Strategies

#### Offset Pagination (Simple but Slow for Large Offsets)
```sql
SELECT * FROM products
ORDER BY product_id
LIMIT 20 OFFSET 1000;
```

#### Keyset Pagination (Faster for Large Datasets)
```sql
SELECT * FROM products
WHERE product_id > 1000  -- Last ID from previous page
ORDER BY product_id
LIMIT 20;
```

### 4. Partitioning Benefits

#### Query Partition Pruning
```sql
-- This query only scans relevant partitions
SELECT COUNT(*)
FROM sensor_readings PARTITION (p202401, p202402)
WHERE timestamp BETWEEN '2024-01-01' AND '2024-02-28';
```

## Performance Analysis

### Query Profiling
```sql
-- Enable profiling
SET profiling = 1;

-- Run your query
SELECT ...;

-- View profile
SHOW PROFILES;
SHOW PROFILE FOR QUERY 1;
```

### Slow Query Log
```sql
-- Enable slow query log
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 2;
SET GLOBAL slow_query_log_file = '/var/log/mysql/slow.log';
```

### Query Cache (Deprecated in MySQL 8.0)
For MySQL 5.7:
```sql
-- Check cache status
SHOW VARIABLES LIKE 'query_cache%';
SHOW STATUS LIKE 'Qcache%';
```

## Common Query Antipatterns

### 1. N+1 Query Problem
```sql
-- Bad: One query per customer
FOR each customer:
    SELECT * FROM orders WHERE customer_id = ?

-- Good: Single query with JOIN
SELECT c.*, o.*
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id;
```

### 2. Implicit Type Conversion
```sql
-- Bad: Causes type conversion, can't use index
SELECT * FROM users WHERE phone = 1234567890;  -- phone is VARCHAR

-- Good: Match data types
SELECT * FROM users WHERE phone = '1234567890';
```

### 3. Functions on Indexed Columns
```sql
-- Bad: Can't use index
SELECT * FROM orders
WHERE DATE(created_at) = '2024-01-01';

-- Good: Preserve index usage
SELECT * FROM orders
WHERE created_at >= '2024-01-01'
    AND created_at < '2024-01-02';
```

## Monitoring and Metrics

### Key Metrics to Track
```sql
-- Query execution time
SELECT
    digest_text,
    count_star as exec_count,
    sum_timer_wait/1000000000000 as total_time_sec,
    avg_timer_wait/1000000000 as avg_time_ms,
    sum_rows_examined as total_rows,
    sum_rows_sent
FROM performance_schema.events_statements_summary_by_digest
ORDER BY sum_timer_wait DESC
LIMIT 10;
```

### Connection Pool Monitoring
```sql
-- Current connections
SHOW STATUS LIKE 'Threads_connected';

-- Connection usage
SELECT
    user,
    host,
    count(*) as connection_count
FROM information_schema.processlist
GROUP BY user, host;
```

## Query Best Practices

1. **Use Prepared Statements**: Prevent SQL injection, improve performance
2. **Limit Result Sets**: Always use LIMIT for unbounded queries
3. **Index Foreign Keys**: Especially for JOIN operations
4. **Avoid LIKE with Leading Wildcard**: `LIKE '%search'` can't use indexes
5. **Use UNION ALL vs UNION**: When you don't need duplicate removal
6. **Batch Operations**: INSERT multiple rows in single statement
7. **Read Replicas**: Offload read queries from primary
8. **Query Result Caching**: Application-level caching for expensive queries

## Testing Queries

### Generate Query Plans
```sql
-- Get execution plan
EXPLAIN FORMAT=JSON SELECT ...;

-- Analyze actual execution
EXPLAIN ANALYZE SELECT ...;  -- MySQL 8.0.18+
```

### Load Testing
```bash
# Using mysqlslap
mysqlslap --user=root --password \
  --concurrency=50 \
  --iterations=100 \
  --query="SELECT * FROM orders WHERE status='pending'" \
  --create-schema=ecommerce
```

## Next Steps

1. Review example-specific queries in `example_XX/queries/`
2. Run EXPLAIN on slow queries
3. Create appropriate indexes based on query patterns
4. Monitor query performance in production
5. Implement query result caching where appropriate