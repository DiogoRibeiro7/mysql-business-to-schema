-- KSQL Analytics Queries for MySQL Business-to-Schema Streaming
--
-- These queries create streams and tables for real-time analytics on CDC data

-- ============================================================================
-- SETUP: Create base streams from Kafka topics
-- ============================================================================

-- Create stream for order events
CREATE STREAM orders_stream (
    order_id BIGINT KEY,
    customer_id BIGINT,
    order_date TIMESTAMP,
    total_amount DECIMAL(12,2),
    status VARCHAR,
    payment_status VARCHAR,
    shipping_address STRUCT<
        city VARCHAR,
        state VARCHAR,
        country VARCHAR,
        postal_code VARCHAR
    >,
    items ARRAY<STRUCT<
        product_id BIGINT,
        quantity INT,
        unit_price DECIMAL(10,2)
    >>,
    cdc_timestamp BIGINT,
    operation VARCHAR
) WITH (
    KAFKA_TOPIC = 'cdc.ecommerce.orders',
    VALUE_FORMAT = 'AVRO',
    TIMESTAMP = 'order_date'
);

-- Create stream for customer events
CREATE STREAM customers_stream (
    customer_id BIGINT KEY,
    email VARCHAR,
    first_name VARCHAR,
    last_name VARCHAR,
    registration_date TIMESTAMP,
    customer_type VARCHAR,
    lifetime_value DECIMAL(12,2),
    status VARCHAR,
    cdc_timestamp BIGINT,
    operation VARCHAR
) WITH (
    KAFKA_TOPIC = 'cdc.ecommerce.customers',
    VALUE_FORMAT = 'AVRO'
);

-- Create stream for product events
CREATE STREAM products_stream (
    product_id BIGINT KEY,
    product_name VARCHAR,
    category_id INT,
    brand_id INT,
    price DECIMAL(10,2),
    stock_quantity INT,
    status VARCHAR,
    cdc_timestamp BIGINT,
    operation VARCHAR
) WITH (
    KAFKA_TOPIC = 'cdc.ecommerce.products',
    VALUE_FORMAT = 'AVRO'
);

-- Create stream for transaction events
CREATE STREAM transactions_stream (
    transaction_id BIGINT KEY,
    customer_id BIGINT,
    order_id BIGINT,
    amount DECIMAL(12,2),
    currency VARCHAR,
    payment_method VARCHAR,
    status VARCHAR,
    transaction_date TIMESTAMP,
    fraud_score INT,
    cdc_timestamp BIGINT,
    operation VARCHAR
) WITH (
    KAFKA_TOPIC = 'cdc.fintech.transactions',
    VALUE_FORMAT = 'AVRO'
);

-- ============================================================================
-- REAL-TIME AGGREGATIONS
-- ============================================================================

-- Real-time order totals by hour
CREATE TABLE hourly_order_totals AS
SELECT
    WINDOWSTART AS window_start,
    WINDOWEND AS window_end,
    COUNT(*) AS order_count,
    SUM(total_amount) AS total_revenue,
    AVG(total_amount) AS avg_order_value,
    MAX(total_amount) AS max_order_value,
    MIN(total_amount) AS min_order_value
FROM orders_stream
WINDOW TUMBLING (SIZE 1 HOUR)
GROUP BY WINDOWSTART, WINDOWEND
EMIT CHANGES;

-- Real-time customer activity
CREATE TABLE customer_activity AS
SELECT
    customer_id,
    COUNT(*) AS order_count,
    SUM(total_amount) AS total_spent,
    AVG(total_amount) AS avg_order_value,
    MAX(order_date) AS last_order_date,
    MIN(order_date) AS first_order_date
FROM orders_stream
WHERE status != 'cancelled'
GROUP BY customer_id
EMIT CHANGES;

-- Product sales velocity (last 24 hours)
CREATE TABLE product_sales_velocity AS
SELECT
    product_id,
    COUNT(*) AS units_sold,
    SUM(quantity) AS total_quantity,
    SUM(quantity * unit_price) AS total_revenue,
    AVG(unit_price) AS avg_price
FROM orders_stream
    CROSS JOIN UNNEST(items) AS item
WINDOW HOPPING (SIZE 24 HOURS, ADVANCE BY 1 HOUR)
GROUP BY product_id
EMIT CHANGES;

-- Real-time revenue by geographic region
CREATE TABLE revenue_by_region AS
SELECT
    shipping_address->country AS country,
    shipping_address->state AS state,
    COUNT(*) AS order_count,
    SUM(total_amount) AS total_revenue,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM orders_stream
WHERE shipping_address IS NOT NULL
GROUP BY shipping_address->country, shipping_address->state
EMIT CHANGES;

-- ============================================================================
-- ANOMALY DETECTION
-- ============================================================================

-- High-value orders detection
CREATE STREAM high_value_orders AS
SELECT
    order_id,
    customer_id,
    total_amount,
    status,
    order_date,
    'HIGH_VALUE_ORDER' AS alert_type,
    CONCAT('Order amount $', CAST(total_amount AS VARCHAR), ' exceeds threshold') AS alert_message
FROM orders_stream
WHERE total_amount > 1000
EMIT CHANGES;

-- Rapid transaction detection (potential fraud)
CREATE STREAM rapid_transactions AS
SELECT
    t1.transaction_id AS transaction_id,
    t1.customer_id AS customer_id,
    t1.amount AS amount,
    t1.transaction_date AS current_transaction,
    t2.transaction_date AS previous_transaction,
    'RAPID_TRANSACTION' AS alert_type,
    CONCAT('Two transactions within 60 seconds for customer ', CAST(t1.customer_id AS VARCHAR)) AS alert_message
FROM transactions_stream t1
    INNER JOIN transactions_stream t2
    WITHIN 1 MINUTE
    ON t1.customer_id = t2.customer_id
WHERE t1.transaction_id != t2.transaction_id
    AND ABS(t1.transaction_date - t2.transaction_date) < 60000
EMIT CHANGES;

-- Unusual order patterns
CREATE STREAM unusual_order_patterns AS
SELECT
    customer_id,
    COUNT(*) AS order_count_last_hour,
    SUM(total_amount) AS total_spent_last_hour,
    'UNUSUAL_PATTERN' AS alert_type,
    CONCAT('Customer ', CAST(customer_id AS VARCHAR), ' has ',
           CAST(COUNT(*) AS VARCHAR), ' orders in last hour') AS alert_message
FROM orders_stream
WINDOW TUMBLING (SIZE 1 HOUR)
GROUP BY customer_id
HAVING COUNT(*) > 5
EMIT CHANGES;

-- Low inventory alert
CREATE STREAM low_inventory_alert AS
SELECT
    product_id,
    product_name,
    stock_quantity,
    'LOW_INVENTORY' AS alert_type,
    CONCAT('Product ', product_name, ' has only ',
           CAST(stock_quantity AS VARCHAR), ' units left') AS alert_message
FROM products_stream
WHERE stock_quantity < 10
    AND stock_quantity > 0
    AND operation IN ('insert', 'update')
EMIT CHANGES;

-- ============================================================================
-- CUSTOMER SEGMENTATION
-- ============================================================================

-- Customer segments based on spending
CREATE TABLE customer_segments AS
SELECT
    customer_id,
    CASE
        WHEN SUM(total_amount) > 10000 THEN 'VIP'
        WHEN SUM(total_amount) > 5000 THEN 'PREMIUM'
        WHEN SUM(total_amount) > 1000 THEN 'REGULAR'
        ELSE 'NEW'
    END AS segment,
    COUNT(*) AS order_count,
    SUM(total_amount) AS lifetime_value,
    AVG(total_amount) AS avg_order_value
FROM orders_stream
WHERE status != 'cancelled'
GROUP BY customer_id
EMIT CHANGES;

-- Moving customer cohorts
CREATE TABLE customer_cohorts AS
SELECT
    FORMAT_DATE(registration_date, 'yyyy-MM') AS cohort_month,
    COUNT(DISTINCT customer_id) AS customer_count,
    AVG(lifetime_value) AS avg_lifetime_value
FROM customers_stream
GROUP BY FORMAT_DATE(registration_date, 'yyyy-MM')
EMIT CHANGES;

-- ============================================================================
-- BUSINESS METRICS
-- ============================================================================

-- Real-time conversion funnel
CREATE TABLE conversion_funnel AS
SELECT
    WINDOWSTART AS window_start,
    COUNT(DISTINCT CASE WHEN status = 'pending' THEN order_id END) AS pending_orders,
    COUNT(DISTINCT CASE WHEN status = 'confirmed' THEN order_id END) AS confirmed_orders,
    COUNT(DISTINCT CASE WHEN status = 'shipped' THEN order_id END) AS shipped_orders,
    COUNT(DISTINCT CASE WHEN status = 'delivered' THEN order_id END) AS delivered_orders,
    COUNT(DISTINCT CASE WHEN status = 'cancelled' THEN order_id END) AS cancelled_orders
FROM orders_stream
WINDOW TUMBLING (SIZE 1 DAY)
GROUP BY WINDOWSTART
EMIT CHANGES;

-- Payment success rate
CREATE TABLE payment_metrics AS
SELECT
    payment_method,
    COUNT(*) AS total_transactions,
    COUNT(CASE WHEN status = 'success' THEN 1 END) AS successful,
    COUNT(CASE WHEN status = 'failed' THEN 1 END) AS failed,
    CAST(COUNT(CASE WHEN status = 'success' THEN 1 END) AS DOUBLE) /
        CAST(COUNT(*) AS DOUBLE) * 100 AS success_rate
FROM transactions_stream
GROUP BY payment_method
EMIT CHANGES;

-- Average order processing time
CREATE TABLE order_processing_time AS
SELECT
    DATE_FORMAT(order_date, 'yyyy-MM-dd') AS order_day,
    AVG(CASE
        WHEN status = 'delivered'
        THEN DATEDIFF('minute', order_date, CURRENT_TIMESTAMP)
        ELSE NULL
    END) AS avg_delivery_time_minutes,
    COUNT(*) AS total_orders
FROM orders_stream
GROUP BY DATE_FORMAT(order_date, 'yyyy-MM-dd')
EMIT CHANGES;

-- ============================================================================
-- JOINS AND ENRICHMENT
-- ============================================================================

-- Enriched order stream with customer data
CREATE STREAM enriched_orders AS
SELECT
    o.order_id,
    o.customer_id,
    c.first_name + ' ' + c.last_name AS customer_name,
    c.customer_type,
    c.lifetime_value AS customer_ltv,
    o.total_amount AS order_amount,
    o.status AS order_status,
    o.order_date
FROM orders_stream o
    LEFT JOIN customers_stream c
    ON o.customer_id = c.customer_id
EMIT CHANGES;

-- Order items with product details
CREATE STREAM order_items_enriched AS
SELECT
    o.order_id,
    item->product_id AS product_id,
    p.product_name,
    p.category_id,
    item->quantity AS quantity,
    item->unit_price AS unit_price,
    item->quantity * item->unit_price AS line_total
FROM orders_stream o
    CROSS JOIN UNNEST(o.items) AS item
    LEFT JOIN products_stream p
    ON item->product_id = p.product_id
EMIT CHANGES;

-- ============================================================================
-- WINDOWED AGGREGATIONS
-- ============================================================================

-- Rolling 7-day revenue
CREATE TABLE rolling_weekly_revenue AS
SELECT
    'global' AS metric_name,
    COUNT(*) AS order_count,
    SUM(total_amount) AS total_revenue,
    AVG(total_amount) AS avg_order_value,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM orders_stream
WINDOW HOPPING (SIZE 7 DAYS, ADVANCE BY 1 DAY)
WHERE status != 'cancelled'
GROUP BY 'global'
EMIT CHANGES;

-- Top selling products (last 24 hours)
CREATE TABLE top_products_24h AS
SELECT
    product_id,
    SUM(quantity) AS total_sold,
    SUM(quantity * unit_price) AS total_revenue,
    COUNT(DISTINCT order_id) AS order_count
FROM orders_stream
    CROSS JOIN UNNEST(items) AS item
WINDOW TUMBLING (SIZE 24 HOURS)
GROUP BY product_id
EMIT CHANGES;

-- Peak hours analysis
CREATE TABLE peak_hours AS
SELECT
    HOUR(order_date) AS order_hour,
    COUNT(*) AS order_count,
    SUM(total_amount) AS total_revenue,
    AVG(total_amount) AS avg_order_value
FROM orders_stream
GROUP BY HOUR(order_date)
EMIT CHANGES;

-- ============================================================================
-- MATERIALIZED VIEWS FOR DASHBOARDS
-- ============================================================================

-- Real-time dashboard metrics
CREATE TABLE dashboard_metrics AS
SELECT
    1 AS id,
    COUNT(*) AS total_orders_today,
    SUM(total_amount) AS revenue_today,
    COUNT(DISTINCT customer_id) AS unique_customers_today,
    AVG(total_amount) AS avg_order_value_today,
    MAX(total_amount) AS largest_order_today
FROM orders_stream
WHERE DATE_FORMAT(order_date, 'yyyy-MM-dd') = DATE_FORMAT(CURRENT_DATE, 'yyyy-MM-dd')
    AND status != 'cancelled'
GROUP BY 1
EMIT CHANGES;

-- Category performance
CREATE TABLE category_performance AS
SELECT
    p.category_id,
    COUNT(DISTINCT o.order_id) AS order_count,
    SUM(item->quantity) AS units_sold,
    SUM(item->quantity * item->unit_price) AS total_revenue
FROM orders_stream o
    CROSS JOIN UNNEST(o.items) AS item
    LEFT JOIN products_stream p
    ON item->product_id = p.product_id
GROUP BY p.category_id
EMIT CHANGES;

-- ============================================================================
-- ALERTS AND MONITORING
-- ============================================================================

-- System health monitoring
CREATE STREAM system_alerts AS
SELECT
    'SYSTEM_ALERT' AS alert_type,
    CASE
        WHEN COUNT(*) = 0 THEN 'NO_DATA'
        WHEN COUNT(*) > 10000 THEN 'HIGH_VOLUME'
        ELSE 'NORMAL'
    END AS alert_level,
    COUNT(*) AS event_count,
    WINDOWSTART AS window_start,
    WINDOWEND AS window_end
FROM orders_stream
WINDOW TUMBLING (SIZE 5 MINUTES)
GROUP BY WINDOWSTART, WINDOWEND
HAVING COUNT(*) = 0 OR COUNT(*) > 10000
EMIT CHANGES;