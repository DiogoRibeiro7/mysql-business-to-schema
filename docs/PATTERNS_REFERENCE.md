# Database Patterns Quick Reference

A concise reference of database patterns demonstrated across all examples in this repository.

## 🔄 Time Series Patterns

### Pattern: Range Partitioning
**Examples**: 02, 03, 05, 06, 07, 08, 09
```sql
CREATE TABLE sensor_readings (
    id BIGINT AUTO_INCREMENT,
    sensor_id INT NOT NULL,
    timestamp DATETIME NOT NULL,
    value DECIMAL(10,2),
    PRIMARY KEY (id, timestamp)
) PARTITION BY RANGE (TO_DAYS(timestamp)) (
    PARTITION p202501 VALUES LESS THAN (TO_DAYS('2025-02-01')),
    PARTITION p202502 VALUES LESS THAN (TO_DAYS('2025-03-01')),
    PARTITION pmax VALUES LESS THAN MAXVALUE
);
```

### Pattern: Data Aggregation
**Examples**: 02, 03, 05
```sql
-- Hourly rollup
INSERT INTO hourly_aggregates
SELECT
    sensor_id,
    DATE_FORMAT(timestamp, '%Y-%m-%d %H:00:00') as hour,
    AVG(value) as avg_value,
    MIN(value) as min_value,
    MAX(value) as max_value,
    COUNT(*) as reading_count
FROM sensor_readings
WHERE timestamp >= DATE_SUB(NOW(), INTERVAL 1 HOUR)
GROUP BY sensor_id, hour;
```

### Pattern: Sliding Window
**Examples**: 07, 09
```sql
SELECT
    timestamp,
    value,
    AVG(value) OVER (
        ORDER BY timestamp
        ROWS BETWEEN 5 PRECEDING AND CURRENT ROW
    ) as moving_avg
FROM readings
WHERE sensor_id = 1;
```

## 🏢 Multi-Tenant Patterns

### Pattern: Tenant Isolation
**Example**: 03
```sql
-- Row-level security with tenant_id
CREATE TABLE meter_readings (
    tenant_id INT NOT NULL,
    meter_id INT NOT NULL,
    reading_time DATETIME,
    value DECIMAL(10,2),
    INDEX idx_tenant (tenant_id),
    PRIMARY KEY (tenant_id, meter_id, reading_time)
);

-- Query always includes tenant filter
SELECT * FROM meter_readings
WHERE tenant_id = ? AND reading_time > ?;
```

### Pattern: Shared Schema
**Example**: 03
```sql
-- Shared tables with tenant column
CREATE VIEW tenant_view AS
SELECT * FROM customers
WHERE tenant_id = CURRENT_TENANT();
```

## 📍 Geospatial Patterns

### Pattern: Distance Calculation
**Examples**: 02, 07
```sql
-- Haversine formula
SELECT
    id,
    name,
    ST_Distance_Sphere(
        POINT(longitude, latitude),
        POINT(?, ?)  -- target coordinates
    ) / 1000 as distance_km
FROM locations
HAVING distance_km < 10
ORDER BY distance_km;
```

### Pattern: Geofencing
**Example**: 07
```sql
-- Check if point is within polygon
SELECT vehicle_id
FROM gps_positions
WHERE ST_Contains(
    ST_GeomFromText('POLYGON((...))', 4326),
    POINT(longitude, latitude)
);
```

## 🏭 Manufacturing Patterns

### Pattern: OEE Calculation
**Example**: 05
```sql
CREATE VIEW oee_metrics AS
SELECT
    line_id,
    date,
    shift,
    -- Availability = Running Time / Planned Time
    (planned_time - downtime) / planned_time as availability,
    -- Performance = Actual Output / Theoretical Output
    actual_output / (ideal_cycle_time * operating_time) as performance,
    -- Quality = Good Output / Total Output
    good_units / total_units as quality,
    -- OEE = Availability × Performance × Quality
    ((planned_time - downtime) / planned_time) *
    (actual_output / (ideal_cycle_time * operating_time)) *
    (good_units / total_units) as oee
FROM production_metrics;
```

### Pattern: Downtime Tracking
**Example**: 05
```sql
CREATE TABLE downtime_events (
    event_id INT PRIMARY KEY AUTO_INCREMENT,
    machine_id INT NOT NULL,
    start_time DATETIME NOT NULL,
    end_time DATETIME,
    reason_code VARCHAR(50),
    is_planned BOOLEAN DEFAULT FALSE,
    INDEX idx_machine_time (machine_id, start_time)
);
```

## 🛒 E-commerce Patterns

### Pattern: Shopping Cart
**Example**: 04
```sql
-- Persistent cart with expiry
CREATE TABLE carts (
    cart_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    session_id VARCHAR(100),
    created_at DATETIME DEFAULT NOW(),
    expires_at DATETIME DEFAULT DATE_ADD(NOW(), INTERVAL 7 DAY),
    INDEX idx_user (user_id),
    INDEX idx_session (session_id),
    INDEX idx_expires (expires_at)
);

-- Cleanup expired carts
CREATE EVENT cleanup_carts
ON SCHEDULE EVERY 1 DAY
DO DELETE FROM carts WHERE expires_at < NOW();
```

### Pattern: Inventory Tracking
**Example**: 04
```sql
-- Optimistic locking for inventory
UPDATE inventory
SET quantity = quantity - ?,
    version = version + 1
WHERE product_id = ?
  AND warehouse_id = ?
  AND quantity >= ?
  AND version = ?;
```

## 🏥 Healthcare Patterns

### Pattern: Audit Trail
**Examples**: 01, 08
```sql
CREATE TABLE audit_log (
    audit_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    table_name VARCHAR(50),
    record_id INT,
    action ENUM('INSERT', 'UPDATE', 'DELETE'),
    user_id INT,
    timestamp DATETIME DEFAULT NOW(),
    old_values JSON,
    new_values JSON,
    ip_address VARCHAR(45),
    INDEX idx_table_record (table_name, record_id),
    INDEX idx_user_time (user_id, timestamp)
);
```

### Pattern: Appointment Scheduling
**Example**: 01
```sql
-- Prevent double-booking
CREATE UNIQUE INDEX uk_doctor_timeslot
ON appointments(doctor_id, appointment_date, time_slot)
WHERE status != 'cancelled';
```

## 🤖 ML/Analytics Patterns

### Pattern: Feature Store
**Example**: 09
```sql
CREATE TABLE user_features (
    user_id INT PRIMARY KEY,
    feature_vector JSON,
    computed_at DATETIME,
    -- Individual features for querying
    session_count INT GENERATED ALWAYS AS (JSON_EXTRACT(feature_vector, '$.sessions')),
    avg_duration DECIMAL(10,2) GENERATED ALWAYS AS (JSON_EXTRACT(feature_vector, '$.avg_duration')),
    INDEX idx_computed (computed_at)
);
```

### Pattern: A/B Testing
**Example**: 09
```sql
CREATE TABLE experiments (
    experiment_id INT PRIMARY KEY,
    name VARCHAR(100),
    variants JSON,  -- ["control", "variant_a", "variant_b"]
    allocation JSON, -- {"control": 0.5, "variant_a": 0.25, "variant_b": 0.25}
    start_date DATETIME,
    end_date DATETIME,
    metrics JSON,    -- ["conversion_rate", "revenue", "engagement"]
    status ENUM('draft', 'running', 'completed', 'aborted')
);
```

## 🚗 Fleet Management Patterns

### Pattern: Trip Segmentation
**Example**: 07
```sql
-- Identify trip segments from GPS data
WITH trip_segments AS (
    SELECT
        vehicle_id,
        timestamp,
        speed_kmh,
        CASE
            WHEN speed_kmh = 0 AND LAG(speed_kmh) OVER (ORDER BY timestamp) > 0
            THEN 1 ELSE 0
        END as trip_end
    FROM gps_positions
)
SELECT
    vehicle_id,
    MIN(timestamp) as trip_start,
    MAX(timestamp) as trip_end,
    AVG(speed_kmh) as avg_speed
FROM trip_segments
GROUP BY vehicle_id, SUM(trip_end) OVER (ORDER BY timestamp);
```

### Pattern: Driver Scoring
**Example**: 07
```sql
CREATE VIEW driver_scores AS
SELECT
    driver_id,
    COUNT(CASE WHEN event_type = 'harsh_brake' THEN 1 END) as harsh_brakes,
    COUNT(CASE WHEN event_type = 'speeding' THEN 1 END) as speeding_events,
    -- Safety score calculation
    GREATEST(0, 100 -
        (harsh_brakes * 2) -
        (speeding_events * 5)
    ) as safety_score
FROM driver_events
WHERE timestamp > DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY driver_id;
```

## 🔋 Energy Management Patterns

### Pattern: Demand Response
**Example**: 03
```sql
CREATE TABLE demand_response_events (
    event_id INT PRIMARY KEY AUTO_INCREMENT,
    utility_id INT,
    event_type ENUM('critical_peak', 'emergency', 'test'),
    start_time DATETIME,
    end_time DATETIME,
    target_reduction_mw DECIMAL(10,2),
    actual_reduction_mw DECIMAL(10,2),
    participants INT,
    INDEX idx_utility_time (utility_id, start_time)
);
```

### Pattern: Peak Detection
**Example**: 03
```sql
-- Identify peak consumption periods
SELECT
    DATE(reading_time) as date,
    HOUR(reading_time) as hour,
    SUM(consumption_kwh) as total_consumption,
    RANK() OVER (
        PARTITION BY DATE(reading_time)
        ORDER BY SUM(consumption_kwh) DESC
    ) as peak_rank
FROM consumption_readings
GROUP BY DATE(reading_time), HOUR(reading_time)
HAVING peak_rank <= 3;  -- Top 3 peak hours
```

## 🌾 Agriculture Patterns

### Pattern: Irrigation Control
**Example**: 06
```sql
CREATE TABLE irrigation_schedules (
    schedule_id INT PRIMARY KEY AUTO_INCREMENT,
    zone_id INT,
    start_time TIME,
    duration_minutes INT,
    days_of_week SET('Mon','Tue','Wed','Thu','Fri','Sat','Sun'),
    soil_moisture_threshold DECIMAL(5,2),
    weather_override BOOLEAN DEFAULT TRUE,
    is_active BOOLEAN DEFAULT TRUE,
    INDEX idx_zone_active (zone_id, is_active)
);
```

## 🔧 Performance Optimization Patterns

### Pattern: Covering Index
**Used in**: All examples
```sql
-- Index covers entire query
CREATE INDEX idx_covering
ON orders(user_id, order_date, status, total_amount)
WHERE status = 'completed';
```

### Pattern: Partial Index
**Examples**: 01, 04
```sql
-- Index only relevant rows
CREATE INDEX idx_active_users
ON users(last_login, email)
WHERE is_active = TRUE;
```

### Pattern: Materialized View
**Examples**: 05, 09
```sql
-- Pre-compute expensive aggregations
CREATE TABLE daily_summaries AS
SELECT
    DATE(timestamp) as date,
    sensor_id,
    MIN(value) as min_value,
    MAX(value) as max_value,
    AVG(value) as avg_value,
    COUNT(*) as reading_count
FROM sensor_readings
GROUP BY DATE(timestamp), sensor_id;

-- Refresh periodically
CREATE EVENT refresh_summaries
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_DATE + INTERVAL 1 DAY + INTERVAL 2 HOUR
DO CALL refresh_daily_summaries();
```

## 🔐 Security Patterns

### Pattern: Row-Level Security
**Examples**: 03, 08
```sql
CREATE VIEW user_data AS
SELECT * FROM sensitive_data
WHERE user_id = USER()
   OR EXISTS (
       SELECT 1 FROM user_permissions
       WHERE granted_to = USER()
         AND granted_on = sensitive_data.id
   );
```

### Pattern: Data Masking
**Example**: 08
```sql
CREATE VIEW masked_patients AS
SELECT
    patient_id,
    CONCAT(LEFT(name, 1), REPEAT('*', LENGTH(name)-2), RIGHT(name, 1)) as name,
    CONCAT('***-**-', RIGHT(ssn, 4)) as ssn_masked,
    date_of_birth,
    medical_record_number
FROM patients;
```

## 📊 Reporting Patterns

### Pattern: Period Comparison
**Used in**: Multiple examples
```sql
WITH current_period AS (
    SELECT SUM(amount) as current_total
    FROM transactions
    WHERE date BETWEEN DATE_SUB(CURDATE(), INTERVAL 30 DAY) AND CURDATE()
),
previous_period AS (
    SELECT SUM(amount) as previous_total
    FROM transactions
    WHERE date BETWEEN DATE_SUB(CURDATE(), INTERVAL 60 DAY)
                   AND DATE_SUB(CURDATE(), INTERVAL 30 DAY)
)
SELECT
    current_total,
    previous_total,
    ((current_total - previous_total) / previous_total * 100) as growth_percentage
FROM current_period, previous_period;
```

---

## 🎯 Pattern Selection Guide

| If you need to... | Use Pattern | See Example |
|-------------------|-------------|-------------|
| Store time series data | Range Partitioning | 02, 03, 05 |
| Calculate distances | Haversine Formula | 02, 07 |
| Track inventory | Optimistic Locking | 04 |
| Implement multi-tenancy | Row-level Security | 03 |
| Audit changes | Audit Trail | 01, 08 |
| Handle high-frequency data | Aggregation Tables | 03, 05, 07 |
| Score/rank items | Window Functions | 07, 09 |
| Detect anomalies | Statistical Analysis | 05, 08 |
| Process real-time data | Event Tables | 07, 09 |
| Optimize read performance | Covering Indexes | All |

---

**Note**: These patterns are simplified for learning. Production implementations may require additional considerations for security, scalability, and specific business requirements.