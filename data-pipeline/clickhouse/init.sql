-- ClickHouse Analytics Database Schema
-- Optimized for OLAP workloads and real-time analytics

-- Create analytics database
CREATE DATABASE IF NOT EXISTS analytics;

USE analytics;

-- ==================== Fact Tables ====================

-- CDC Events table (raw events)
CREATE TABLE IF NOT EXISTS cdc_events
(
    database String,
    table_name String,
    operation Enum8('INSERT' = 1, 'UPDATE' = 2, 'DELETE' = 3),
    timestamp DateTime,
    before String,
    after String,
    transaction_id String,
    processing_time DateTime DEFAULT now(),
    INDEX idx_timestamp timestamp TYPE minmax GRANULARITY 1
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (database, table_name, timestamp)
TTL timestamp + INTERVAL 90 DAY;

-- Patient Facts
CREATE TABLE IF NOT EXISTS patients_fact
(
    patient_id UInt32,
    name String,
    date_of_birth Date,
    age UInt8,
    age_group String,
    gender Enum8('Male' = 1, 'Female' = 2, 'Other' = 3),
    phone String,
    email String,
    address String,
    insurance_provider String,
    registration_date Date,
    registration_year UInt16,
    registration_month UInt8,
    registration_week UInt8,
    last_visit_date Nullable(Date),
    total_visits UInt32 DEFAULT 0,
    created_at DateTime,
    updated_at DateTime,
    INDEX idx_age age TYPE minmax GRANULARITY 1,
    INDEX idx_registration registration_date TYPE minmax GRANULARITY 1
)
ENGINE = ReplacingMergeTree(updated_at)
PARTITION BY toYYYYMM(registration_date)
ORDER BY (patient_id, registration_date);

-- Order Facts
CREATE TABLE IF NOT EXISTS orders_fact
(
    order_id UInt32,
    customer_id UInt32,
    order_date DateTime,
    order_year UInt16,
    order_month UInt8,
    order_day UInt8,
    order_hour UInt8,
    order_weekday UInt8,
    status Enum8('pending' = 1, 'processing' = 2, 'shipped' = 3, 'delivered' = 4, 'cancelled' = 5),
    total_amount Decimal(10, 2),
    order_value_category String,
    shipping_address String,
    payment_method String,
    items_count UInt16,
    total_items_quantity UInt32,
    discount_amount Decimal(10, 2) DEFAULT 0,
    tax_amount Decimal(10, 2) DEFAULT 0,
    shipping_cost Decimal(10, 2) DEFAULT 0,
    processing_time DateTime DEFAULT now(),
    INDEX idx_customer customer_id TYPE bloom_filter GRANULARITY 1,
    INDEX idx_order_date order_date TYPE minmax GRANULARITY 1,
    INDEX idx_amount total_amount TYPE minmax GRANULARITY 1
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(order_date)
ORDER BY (order_date, customer_id, order_id);

-- Order Items (Nested table)
CREATE TABLE IF NOT EXISTS order_items
(
    order_id UInt32,
    product_id UInt32,
    product_name String,
    category String,
    quantity UInt16,
    unit_price Decimal(10, 2),
    total_price Decimal(10, 2),
    discount_percent Float32 DEFAULT 0
)
ENGINE = MergeTree()
ORDER BY (order_id, product_id);

-- IoT Readings Facts
CREATE TABLE IF NOT EXISTS iot_readings_fact
(
    device_id String,
    sensor_type String,
    value Float64,
    unit String,
    timestamp DateTime,
    reading_date Date,
    reading_hour UInt8,
    location_lat Nullable(Float64),
    location_lon Nullable(Float64),
    metadata String,
    moving_avg Float64,
    moving_std Float64,
    moving_min Float64,
    moving_max Float64,
    is_anomaly Bool DEFAULT 0,
    processing_time DateTime DEFAULT now(),
    INDEX idx_device device_id TYPE bloom_filter GRANULARITY 1,
    INDEX idx_timestamp timestamp TYPE minmax GRANULARITY 1,
    INDEX idx_anomaly is_anomaly TYPE set(2) GRANULARITY 1
)
ENGINE = MergeTree()
PARTITION BY toYYYYMMDD(reading_date)
ORDER BY (device_id, sensor_type, timestamp)
TTL timestamp + INTERVAL 30 DAY;

-- Social Media Posts Facts
CREATE TABLE IF NOT EXISTS social_posts_fact
(
    post_id UInt64,
    user_id UInt32,
    content String,
    post_type Enum8('text' = 1, 'image' = 2, 'video' = 3, 'link' = 4),
    created_at DateTime,
    post_date Date,
    post_hour UInt8,
    likes_count UInt32,
    comments_count UInt32,
    shares_count UInt32,
    total_engagement UInt32,
    sentiment Enum8('positive' = 1, 'neutral' = 2, 'negative' = 3),
    hashtags Array(String),
    mentions Array(String),
    is_viral Bool DEFAULT 0,
    INDEX idx_user user_id TYPE bloom_filter GRANULARITY 1,
    INDEX idx_created created_at TYPE minmax GRANULARITY 1,
    INDEX idx_viral is_viral TYPE set(2) GRANULARITY 1
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(post_date)
ORDER BY (user_id, created_at, post_id);

-- ==================== Aggregated Tables ====================

-- Hourly Patient Metrics
CREATE TABLE IF NOT EXISTS patient_metrics_hourly
(
    window_start DateTime,
    window_end DateTime,
    gender String,
    age_group String,
    insurance_provider String,
    patient_count UInt32,
    avg_age Float32,
    min_age UInt8,
    max_age UInt8
)
ENGINE = SummingMergeTree()
PARTITION BY toYYYYMM(window_start)
ORDER BY (window_start, gender, age_group, insurance_provider);

-- Hourly Order Metrics
CREATE TABLE IF NOT EXISTS order_metrics_hourly
(
    window_start DateTime,
    window_end DateTime,
    status String,
    payment_method String,
    order_value_category String,
    order_count UInt32,
    total_revenue Decimal(12, 2),
    avg_order_value Decimal(10, 2),
    total_items_sold UInt32,
    avg_items_per_order Float32
)
ENGINE = SummingMergeTree()
PARTITION BY toYYYYMM(window_start)
ORDER BY (window_start, status, payment_method);

-- 5-Minute IoT Metrics
CREATE TABLE IF NOT EXISTS iot_metrics_5min
(
    window_start DateTime,
    window_end DateTime,
    device_id String,
    sensor_type String,
    reading_count UInt32,
    avg_value Float64,
    min_value Float64,
    max_value Float64,
    std_value Float64,
    anomaly_count UInt32,
    anomaly_rate Float32
)
ENGINE = SummingMergeTree()
PARTITION BY toYYYYMMDD(window_start)
ORDER BY (window_start, device_id, sensor_type);

-- Daily Business Metrics
CREATE TABLE IF NOT EXISTS business_metrics_daily
(
    date Date,
    metric_type String,
    database String,
    metric_name String,
    metric_value Float64,
    previous_value Nullable(Float64),
    change_percent Nullable(Float32)
)
ENGINE = ReplacingMergeTree()
PARTITION BY toYYYYMM(date)
ORDER BY (date, metric_type, database, metric_name);

-- ==================== Dimension Tables ====================

-- Customer Dimension
CREATE TABLE IF NOT EXISTS dim_customers
(
    customer_id UInt32,
    customer_name String,
    email String,
    phone String,
    registration_date Date,
    customer_segment String,
    lifetime_value Decimal(12, 2),
    total_orders UInt32,
    last_order_date Nullable(Date),
    churn_risk_score Float32
)
ENGINE = ReplacingMergeTree()
ORDER BY customer_id;

-- Product Dimension
CREATE TABLE IF NOT EXISTS dim_products
(
    product_id UInt32,
    product_name String,
    category String,
    subcategory String,
    brand String,
    unit_price Decimal(10, 2),
    cost Decimal(10, 2),
    margin_percent Float32,
    stock_quantity UInt32,
    is_active Bool
)
ENGINE = ReplacingMergeTree()
ORDER BY product_id;

-- Device Dimension
CREATE TABLE IF NOT EXISTS dim_devices
(
    device_id String,
    device_type String,
    manufacturer String,
    model String,
    firmware_version String,
    location_name String,
    location_lat Float64,
    location_lon Float64,
    installation_date Date,
    last_maintenance_date Nullable(Date),
    status Enum8('active' = 1, 'inactive' = 2, 'maintenance' = 3)
)
ENGINE = ReplacingMergeTree()
ORDER BY device_id;

-- ==================== Real-time Views ====================

-- Real-time Revenue Dashboard
CREATE MATERIALIZED VIEW IF NOT EXISTS revenue_realtime
ENGINE = SummingMergeTree()
PARTITION BY toYYYYMM(order_hour)
ORDER BY order_hour
AS
SELECT
    toStartOfHour(order_date) as order_hour,
    sum(total_amount) as revenue,
    count() as order_count,
    avg(total_amount) as avg_order_value
FROM orders_fact
GROUP BY order_hour;

-- Real-time IoT Anomalies
CREATE MATERIALIZED VIEW IF NOT EXISTS anomalies_realtime
ENGINE = MergeTree()
PARTITION BY toYYYYMMDD(detection_time)
ORDER BY (detection_time, device_id)
AS
SELECT
    device_id,
    sensor_type,
    timestamp as detection_time,
    value,
    moving_avg,
    abs(value - moving_avg) / moving_std as z_score
FROM iot_readings_fact
WHERE is_anomaly = 1;

-- Customer Behavior View
CREATE MATERIALIZED VIEW IF NOT EXISTS customer_behavior
ENGINE = SummingMergeTree()
PARTITION BY toYYYYMM(order_month)
ORDER BY (order_month, customer_id)
AS
SELECT
    customer_id,
    toStartOfMonth(order_date) as order_month,
    count() as monthly_orders,
    sum(total_amount) as monthly_spend,
    avg(total_amount) as avg_order_value,
    max(order_date) as last_order_date
FROM orders_fact
GROUP BY customer_id, order_month;

-- ==================== Utility Functions ====================

-- Function to calculate percentiles
CREATE FUNCTION IF NOT EXISTS calculate_percentile AS (arr, p) ->
    arrayElement(arraySort(arr), toUInt32(length(arr) * p / 100));

-- Function to detect outliers
CREATE FUNCTION IF NOT EXISTS is_outlier AS (value, mean, std) ->
    abs(value - mean) > 3 * std;

-- ==================== Data Retention Policies ====================

-- Set TTL for old partitions
ALTER TABLE cdc_events MODIFY TTL timestamp + INTERVAL 90 DAY;
ALTER TABLE iot_readings_fact MODIFY TTL timestamp + INTERVAL 30 DAY;

-- ==================== Indexes for Performance ====================

-- Add Bloom filter indexes for high cardinality columns
ALTER TABLE orders_fact ADD INDEX idx_customer_bloom customer_id TYPE bloom_filter GRANULARITY 1;
ALTER TABLE iot_readings_fact ADD INDEX idx_device_bloom device_id TYPE bloom_filter GRANULARITY 1;
ALTER TABLE social_posts_fact ADD INDEX idx_user_bloom user_id TYPE bloom_filter GRANULARITY 1;

-- ==================== Initial Data Load ====================

-- Insert sample dimension data (for testing)
INSERT INTO dim_customers (customer_id, customer_name, email, registration_date, customer_segment)
VALUES
    (1, 'John Doe', 'john@example.com', '2024-01-01', 'Premium'),
    (2, 'Jane Smith', 'jane@example.com', '2024-01-15', 'Regular'),
    (3, 'Bob Johnson', 'bob@example.com', '2024-02-01', 'New');

INSERT INTO dim_devices (device_id, device_type, manufacturer, location_name, status)
VALUES
    ('DEV001', 'Temperature Sensor', 'SensorCorp', 'Building A', 'active'),
    ('DEV002', 'Pressure Sensor', 'IoTech', 'Building B', 'active'),
    ('DEV003', 'Flow Meter', 'FlowTech', 'Building C', 'maintenance');

-- ==================== Permissions ====================

-- Create read-only user for BI tools
CREATE USER IF NOT EXISTS bi_user IDENTIFIED BY 'bi_password';
GRANT SELECT ON analytics.* TO bi_user;

-- Create write user for data pipeline
CREATE USER IF NOT EXISTS pipeline_user IDENTIFIED BY 'pipeline_password';
GRANT SELECT, INSERT, ALTER ON analytics.* TO pipeline_user;