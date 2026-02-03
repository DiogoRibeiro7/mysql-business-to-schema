# MySQL Indexing Strategy Guide

## Overview

Indexes are critical for database performance. This guide covers indexing strategies, types, and best practices with examples from our 9 database implementations.

## Table of Contents

1. [Index Types](#index-types)
2. [Index Selection Strategy](#index-selection-strategy)
3. [Time Series Indexing](#time-series-indexing)
4. [Composite Indexes](#composite-indexes)
5. [Spatial Indexes](#spatial-indexes)
6. [Full-Text Indexes](#full-text-indexes)
7. [Index Maintenance](#index-maintenance)
8. [Performance Analysis](#performance-analysis)

## Index Types

### Primary Index (Clustered)

```sql
-- Primary key creates clustered index
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,  -- Clustered index
    email VARCHAR(100),
    created_at TIMESTAMP
);

-- InnoDB stores data in primary key order
-- Fastest for primary key lookups
-- Only one clustered index per table
```

### Secondary Indexes

```sql
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    sku VARCHAR(50),
    name VARCHAR(200),
    category_id INT,
    price DECIMAL(10,2),
    created_at TIMESTAMP,

    -- Single column indexes
    INDEX idx_sku (sku),
    INDEX idx_category (category_id),
    INDEX idx_created (created_at),

    -- Composite index
    INDEX idx_category_price (category_id, price)
);
```

### Unique Indexes

```sql
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    email VARCHAR(100),
    phone VARCHAR(20),

    -- Unique indexes prevent duplicates
    UNIQUE INDEX uk_email (email),
    UNIQUE INDEX uk_phone (phone)
);
```

### Covering Indexes

Used in **E-commerce** for query optimization:

```sql
-- Query we want to optimize
SELECT order_id, order_date, total_amount
FROM orders
WHERE customer_id = 123
AND order_date >= '2025-01-01';

-- Covering index includes all needed columns
CREATE INDEX idx_covering_orders
ON orders(customer_id, order_date, total_amount, order_id);
-- Query can be satisfied entirely from index
```

## Index Selection Strategy

### Cardinality Analysis

```sql
-- Check column cardinality before indexing
SELECT
    COUNT(DISTINCT status) AS status_cardinality,
    COUNT(DISTINCT customer_id) AS customer_cardinality,
    COUNT(DISTINCT order_date) AS date_cardinality,
    COUNT(*) AS total_rows
FROM orders;

-- High cardinality columns are better index candidates
-- status: 5 values (low) - poor index candidate
-- customer_id: 10000 values (high) - good index candidate
-- order_date: 365 values (medium) - moderate candidate
```

### Query Pattern Analysis

Used in **IoT Bins** for sensor data:

```sql
-- Analyze common query patterns
-- Pattern 1: Latest reading per sensor
SELECT * FROM sensor_readings
WHERE sensor_id = 123
ORDER BY reading_time DESC
LIMIT 1;

-- Pattern 2: Time range queries
SELECT * FROM sensor_readings
WHERE reading_time BETWEEN '2025-01-01' AND '2025-01-31';

-- Pattern 3: Sensor + time combination
SELECT * FROM sensor_readings
WHERE sensor_id = 123
AND reading_time >= '2025-01-01';

-- Optimal indexes based on patterns
CREATE INDEX idx_sensor_time ON sensor_readings(sensor_id, reading_time DESC);
CREATE INDEX idx_time ON sensor_readings(reading_time);
```

### Selectivity Formula

```sql
-- Calculate index selectivity
SELECT
    column_name,
    COUNT(DISTINCT column_name) / COUNT(*) AS selectivity
FROM table_name
GROUP BY column_name;

-- Selectivity close to 1 = good index candidate
-- Selectivity close to 0 = poor index candidate
```

## Time Series Indexing

Critical for IoT applications:

### Partitioned Table Indexes

Used in **Smart Energy** for meter readings:

```sql
CREATE TABLE meter_readings (
    tenant_id INT,
    meter_id INT,
    reading_time TIMESTAMP,
    kwh_consumed DECIMAL(10,3),
    PRIMARY KEY (tenant_id, meter_id, reading_time),
    INDEX idx_time (reading_time),
    INDEX idx_meter_time (meter_id, reading_time)
) PARTITION BY RANGE (UNIX_TIMESTAMP(reading_time)) (
    PARTITION p202501 VALUES LESS THAN (UNIX_TIMESTAMP('2025-02-01')),
    PARTITION p202502 VALUES LESS THAN (UNIX_TIMESTAMP('2025-03-01')),
    PARTITION p202503 VALUES LESS THAN (UNIX_TIMESTAMP('2025-04-01'))
);

-- Each partition has its own indexes
-- Partition pruning improves query performance
```

### Time-Based Composite Indexes

```sql
-- For queries filtering by device and time
CREATE INDEX idx_device_time
ON sensor_data(device_id, timestamp DESC);

-- For aggregation queries
CREATE INDEX idx_day_device
ON sensor_data(DATE(timestamp), device_id, value);

-- For latest value queries
CREATE INDEX idx_device_latest
ON sensor_data(device_id, is_latest, timestamp DESC)
WHERE is_latest = TRUE;  -- Partial index
```

## Composite Indexes

### Column Order Matters

```sql
-- Query patterns determine column order
-- Pattern A: Filter by status, sort by date
SELECT * FROM orders
WHERE status = 'pending'
ORDER BY order_date DESC;

-- Pattern B: Filter by customer and status
SELECT * FROM orders
WHERE customer_id = 123
AND status = 'pending';

-- Pattern C: Filter by customer, sort by date
SELECT * FROM orders
WHERE customer_id = 123
ORDER BY order_date DESC;

-- Optimal composite indexes
CREATE INDEX idx_status_date ON orders(status, order_date DESC);
CREATE INDEX idx_customer_status_date ON orders(customer_id, status, order_date DESC);
```

### Leftmost Prefix Rule

```sql
-- Composite index
CREATE INDEX idx_composite ON products(category_id, brand_id, price);

-- This index can satisfy these queries:
-- ✓ WHERE category_id = 1
-- ✓ WHERE category_id = 1 AND brand_id = 2
-- ✓ WHERE category_id = 1 AND brand_id = 2 AND price > 100
-- ✓ WHERE category_id = 1 AND price > 100 (less efficient)

-- This index CANNOT efficiently satisfy:
-- ✗ WHERE brand_id = 2
-- ✗ WHERE price > 100
-- ✗ WHERE brand_id = 2 AND price > 100
```

## Spatial Indexes

Used in **Fleet Management** for GPS tracking:

### Point Data Indexing

```sql
CREATE TABLE vehicle_positions (
    position_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    vehicle_id INT,
    position POINT NOT NULL,
    recorded_at TIMESTAMP,
    SPATIAL INDEX idx_position (position),
    INDEX idx_vehicle_time (vehicle_id, recorded_at)
);

-- Efficient proximity queries
SELECT vehicle_id,
       ST_Distance_Sphere(position,
           ST_GeomFromText('POINT(40.7128 -74.0060)')) AS distance_meters
FROM vehicle_positions
WHERE ST_Distance_Sphere(position,
           ST_GeomFromText('POINT(40.7128 -74.0060)')) < 1000;
```

### Geofencing Queries

```sql
CREATE TABLE geofences (
    fence_id INT PRIMARY KEY,
    fence_name VARCHAR(100),
    boundary POLYGON NOT NULL,
    SPATIAL INDEX idx_boundary (boundary)
);

-- Check if vehicle is within geofence
SELECT f.fence_name
FROM vehicle_positions v
JOIN geofences f ON ST_Contains(f.boundary, v.position)
WHERE v.vehicle_id = 123
AND v.recorded_at = (
    SELECT MAX(recorded_at)
    FROM vehicle_positions
    WHERE vehicle_id = 123
);
```

## Full-Text Indexes

Used in **E-commerce** for product search:

### Creating Full-Text Indexes

```sql
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    name VARCHAR(200),
    description TEXT,
    specifications TEXT,
    FULLTEXT idx_name_desc (name, description),
    FULLTEXT idx_all_text (name, description, specifications)
);

-- Natural language search
SELECT product_id, name,
       MATCH(name, description) AGAINST('wireless headphones' IN NATURAL LANGUAGE MODE) AS relevance
FROM products
WHERE MATCH(name, description) AGAINST('wireless headphones' IN NATURAL LANGUAGE MODE)
ORDER BY relevance DESC;

-- Boolean mode search
SELECT * FROM products
WHERE MATCH(name, description)
      AGAINST('+wireless +headphones -wired' IN BOOLEAN MODE);
```

### Full-Text Search Optimization

```sql
-- Minimum word length configuration
SHOW VARIABLES LIKE 'ft_min_word_len';  -- Default: 4

-- Custom stopword list
CREATE TABLE my_stopwords(value VARCHAR(30));
INSERT INTO my_stopwords VALUES ('the'), ('and'), ('or');
SET GLOBAL ft_stopword_file = 'my_stopwords.txt';
```

## Index Maintenance

### Analyzing Index Usage

```sql
-- Check index usage statistics
SELECT
    table_schema,
    table_name,
    index_name,
    cardinality,
    seq_in_index,
    column_name
FROM information_schema.statistics
WHERE table_schema = 'your_database'
ORDER BY table_name, index_name, seq_in_index;

-- Find unused indexes
SELECT
    s.table_schema,
    s.table_name,
    s.index_name
FROM information_schema.statistics s
LEFT JOIN sys.schema_unused_indexes u
    ON s.table_schema = u.object_schema
    AND s.table_name = u.object_name
    AND s.index_name = u.index_name
WHERE u.index_name IS NOT NULL;
```

### Index Fragmentation

```sql
-- Check table fragmentation
SELECT
    table_name,
    ROUND(data_length / 1024 / 1024, 2) AS data_mb,
    ROUND(index_length / 1024 / 1024, 2) AS index_mb,
    ROUND(data_free / 1024 / 1024, 2) AS free_mb,
    ROUND(data_free * 100 / (data_length + index_length), 2) AS fragmentation_pct
FROM information_schema.tables
WHERE table_schema = 'your_database'
AND data_free > 0
ORDER BY fragmentation_pct DESC;

-- Defragment table
OPTIMIZE TABLE your_table;
```

### Index Rebuilding

```sql
-- Rebuild indexes after bulk operations
ALTER TABLE large_table ENGINE=InnoDB;

-- Or specifically rebuild an index
ALTER TABLE your_table DROP INDEX idx_name, ADD INDEX idx_name(column);

-- Analyze table after rebuild
ANALYZE TABLE your_table;
```

## Performance Analysis

### Using EXPLAIN

```sql
-- Analyze query execution plan
EXPLAIN SELECT o.order_id, c.customer_name, o.total_amount
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_date >= '2025-01-01'
AND o.status = 'completed';

-- EXPLAIN output analysis:
-- type: ALL = full table scan (bad)
-- type: index = full index scan (better)
-- type: range = index range scan (good)
-- type: ref = index lookup (very good)
-- type: const = single row (best)
```

### Query Profiling

```sql
-- Enable profiling
SET profiling = 1;

-- Run query
SELECT * FROM orders WHERE customer_id = 123;

-- View profile
SHOW PROFILES;
SHOW PROFILE FOR QUERY 1;

-- Detailed breakdown
SHOW PROFILE CPU, BLOCK IO FOR QUERY 1;
```

### Index Hints

```sql
-- Force index usage
SELECT * FROM orders USE INDEX (idx_customer_date)
WHERE customer_id = 123
AND order_date >= '2025-01-01';

-- Ignore specific index
SELECT * FROM orders IGNORE INDEX (idx_status)
WHERE status = 'pending';

-- Force specific index for ORDER BY
SELECT * FROM orders FORCE INDEX (idx_date)
WHERE customer_id = 123
ORDER BY order_date DESC;
```

## Best Practices

### 1. Index Design Guidelines

```sql
-- DO: Index foreign keys
ALTER TABLE orders ADD INDEX idx_customer (customer_id);

-- DO: Index columns in WHERE, JOIN, ORDER BY, GROUP BY
CREATE INDEX idx_search ON products(category_id, brand_id, price);

-- DON'T: Over-index
-- Each index slows down INSERT/UPDATE/DELETE
-- Balance read vs write performance

-- DON'T: Index low cardinality columns alone
-- Bad: INDEX idx_status (status)  -- only 3-5 values
-- Good: INDEX idx_status_date (status, created_at)
```

### 2. Monitoring Index Performance

```sql
-- Query to find missing indexes
SELECT
    s.table_schema,
    s.table_name,
    s.column_name,
    s.seq_in_index
FROM information_schema.key_column_usage k
JOIN information_schema.statistics s
    ON k.table_schema = s.table_schema
    AND k.table_name = s.table_name
    AND k.column_name = s.column_name
WHERE k.referenced_table_name IS NOT NULL
AND s.index_name = 'PRIMARY'
AND k.constraint_name != 'PRIMARY';
```

### 3. Index Naming Conventions

```sql
-- Consistent naming helps maintenance
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    status VARCHAR(20),

    -- Naming pattern: idx_tablename_columns
    INDEX idx_orders_customer (customer_id),
    INDEX idx_orders_date (order_date),
    INDEX idx_orders_status_date (status, order_date),

    -- Unique indexes: uk_tablename_column
    UNIQUE INDEX uk_orders_reference (order_reference),

    -- Full-text: ft_tablename_columns
    FULLTEXT ft_orders_notes (order_notes)
);
```

## Example Implementations

### IoT Bins (Time Series)
```sql
-- Optimize for time-based queries
CREATE INDEX idx_sensor_time ON readings(sensor_id, reading_time DESC);
CREATE INDEX idx_daily ON readings(DATE(reading_time), sensor_id);
```

### E-commerce (Mixed Workload)
```sql
-- Balance between reads and writes
CREATE INDEX idx_customer_orders ON orders(customer_id, order_date DESC);
CREATE INDEX idx_product_search ON products(category_id, price, rating);
FULLTEXT idx_product_text (name, description);
```

### Fleet Management (Spatial)
```sql
-- GPS and time-based queries
SPATIAL INDEX idx_position (last_position);
CREATE INDEX idx_vehicle_time ON positions(vehicle_id, recorded_at DESC);
```

### Healthcare IoT (Compliance)
```sql
-- Audit and patient data
CREATE INDEX idx_patient_time ON vitals(patient_id, reading_time);
CREATE INDEX idx_audit ON audit_log(user_id, action_time, table_name);
```

### Smart Energy (Multi-tenant)
```sql
-- Tenant isolation
CREATE INDEX idx_tenant_meter ON readings(tenant_id, meter_id, reading_time);
-- Always include tenant_id as first column
```

## Troubleshooting

### Common Issues

1. **Slow queries despite indexes**
   - Check EXPLAIN plan
   - Verify index is being used
   - Update table statistics: `ANALYZE TABLE`

2. **Index not used**
   - Poor selectivity
   - Type conversion issues
   - Function calls on indexed column

3. **Write performance degradation**
   - Too many indexes
   - Large index size
   - Consider batch inserts

## Conclusion

Effective indexing requires:
1. Understanding query patterns
2. Analyzing data distribution
3. Monitoring performance metrics
4. Regular maintenance
5. Balancing read/write performance

Remember: Indexes are not free - each index has storage and maintenance costs.