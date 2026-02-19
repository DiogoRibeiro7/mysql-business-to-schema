-- KSQL Stream Processing Queries for CDC Events
-- Real-time analytics and transformations on MySQL change data

-- =====================================================
-- 1. Create Source Streams from Kafka Topics
-- =====================================================

-- Clinic Patients Stream
CREATE STREAM patients_stream (
  patient_id BIGINT KEY,
  first_name VARCHAR,
  last_name VARCHAR,
  date_of_birth DATE,
  gender VARCHAR,
  email VARCHAR,
  phone VARCHAR,
  address STRUCT<
    street VARCHAR,
    city VARCHAR,
    state VARCHAR,
    zip VARCHAR
  >,
  insurance_provider VARCHAR,
  insurance_number VARCHAR,
  emergency_contact VARCHAR,
  medical_conditions ARRAY<VARCHAR>,
  op VARCHAR,
  ts_ms BIGINT,
  source STRUCT<
    db VARCHAR,
    table VARCHAR,
    server_id BIGINT,
    gtid VARCHAR,
    file VARCHAR,
    pos BIGINT,
    row INT
  >
) WITH (
  KAFKA_TOPIC='cdc.clinic.patients',
  VALUE_FORMAT='JSON',
  TIMESTAMP='ts_ms'
);

-- Clinic Appointments Stream
CREATE STREAM appointments_stream (
  appointment_id BIGINT KEY,
  patient_id BIGINT,
  doctor_id BIGINT,
  appointment_date TIMESTAMP,
  appointment_type VARCHAR,
  status VARCHAR,
  reason VARCHAR,
  notes VARCHAR,
  duration_minutes INT,
  room_number VARCHAR,
  follow_up_required BOOLEAN,
  op VARCHAR,
  ts_ms BIGINT
) WITH (
  KAFKA_TOPIC='cdc.clinic.appointments',
  VALUE_FORMAT='JSON',
  TIMESTAMP='ts_ms'
);

-- IoT Sensor Readings Stream
CREATE STREAM sensor_readings_stream (
  reading_id BIGINT KEY,
  bin_id VARCHAR,
  timestamp TIMESTAMP,
  fill_level DOUBLE,
  temperature DOUBLE,
  humidity DOUBLE,
  battery_level DOUBLE,
  location STRUCT<
    latitude DOUBLE,
    longitude DOUBLE
  >,
  motion_detected BOOLEAN,
  odor_level INT,
  weight_kg DOUBLE,
  op VARCHAR,
  ts_ms BIGINT
) WITH (
  KAFKA_TOPIC='cdc.iot.sensor_readings',
  VALUE_FORMAT='JSON',
  TIMESTAMP='ts_ms'
);

-- E-Commerce Orders Stream
CREATE STREAM orders_stream (
  order_id BIGINT KEY,
  customer_id BIGINT,
  order_date TIMESTAMP,
  status VARCHAR,
  total_amount DECIMAL(10,2),
  shipping_address STRUCT<
    street VARCHAR,
    city VARCHAR,
    state VARCHAR,
    zip VARCHAR,
    country VARCHAR
  >,
  payment_method VARCHAR,
  shipping_method VARCHAR,
  items ARRAY<STRUCT<
    product_id BIGINT,
    quantity INT,
    unit_price DECIMAL(10,2),
    discount DECIMAL(10,2)
  >>,
  op VARCHAR,
  ts_ms BIGINT
) WITH (
  KAFKA_TOPIC='cdc.ecommerce.orders',
  VALUE_FORMAT='JSON',
  TIMESTAMP='ts_ms'
);

-- =====================================================
-- 2. Create Enriched Streams with Transformations
-- =====================================================

-- Filter only INSERT and UPDATE operations
CREATE STREAM patients_changes AS
  SELECT * FROM patients_stream
  WHERE op IN ('c', 'u')
  EMIT CHANGES;

-- Create appointment statistics stream
CREATE STREAM appointment_stats AS
  SELECT
    doctor_id,
    WINDOWSTART as window_start,
    WINDOWEND as window_end,
    COUNT(*) as appointment_count,
    COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_count,
    COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as cancelled_count,
    COUNT(CASE WHEN status = 'no_show' THEN 1 END) as no_show_count,
    AVG(duration_minutes) as avg_duration,
    COUNT(DISTINCT patient_id) as unique_patients
  FROM appointments_stream
  WINDOW TUMBLING (SIZE 1 HOUR)
  GROUP BY doctor_id
  EMIT CHANGES;

-- Real-time IoT alerting stream
CREATE STREAM iot_alerts AS
  SELECT
    bin_id,
    timestamp,
    fill_level,
    battery_level,
    temperature,
    CASE
      WHEN fill_level > 90 THEN 'CRITICAL_FULL'
      WHEN fill_level > 75 THEN 'NEEDS_COLLECTION'
      WHEN battery_level < 20 THEN 'LOW_BATTERY'
      WHEN temperature > 50 THEN 'HIGH_TEMPERATURE'
      ELSE 'NORMAL'
    END as alert_type,
    location
  FROM sensor_readings_stream
  WHERE fill_level > 75
    OR battery_level < 20
    OR temperature > 50
  EMIT CHANGES;

-- Order value analytics stream
CREATE STREAM order_analytics AS
  SELECT
    SUBSTRING(CAST(order_date AS STRING), 0, 10) as order_day,
    COUNT(*) as order_count,
    SUM(total_amount) as total_revenue,
    AVG(total_amount) as avg_order_value,
    MIN(total_amount) as min_order_value,
    MAX(total_amount) as max_order_value,
    COUNT(DISTINCT customer_id) as unique_customers
  FROM orders_stream
  WINDOW TUMBLING (SIZE 1 DAY)
  GROUP BY SUBSTRING(CAST(order_date AS STRING), 0, 10)
  EMIT CHANGES;

-- =====================================================
-- 3. Create Materialized Tables
-- =====================================================

-- Current patient count by insurance provider
CREATE TABLE patients_by_insurance AS
  SELECT
    insurance_provider,
    COUNT(*) as patient_count,
    COLLECT_LIST(STRUCT(
      patient_id := patient_id,
      name := CONCAT(first_name, ' ', last_name)
    )) as patients
  FROM patients_stream
  WHERE op != 'd'
  GROUP BY insurance_provider
  EMIT CHANGES;

-- Doctor appointment load table
CREATE TABLE doctor_workload AS
  SELECT
    doctor_id,
    COUNT(*) as total_appointments,
    SUM(CASE WHEN status = 'scheduled' THEN 1 ELSE 0 END) as scheduled,
    SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed,
    AVG(duration_minutes) as avg_duration,
    MAX(ROWTIME) as last_updated
  FROM appointments_stream
  WHERE op != 'd'
  GROUP BY doctor_id
  EMIT CHANGES;

-- IoT bin status table
CREATE TABLE bin_current_status AS
  SELECT
    bin_id,
    LATEST_BY_OFFSET(fill_level) as current_fill_level,
    LATEST_BY_OFFSET(battery_level) as current_battery,
    LATEST_BY_OFFSET(temperature) as current_temperature,
    LATEST_BY_OFFSET(timestamp) as last_reading,
    COUNT(*) as total_readings
  FROM sensor_readings_stream
  GROUP BY bin_id
  EMIT CHANGES;

-- Customer order summary table
CREATE TABLE customer_order_summary AS
  SELECT
    customer_id,
    COUNT(*) as total_orders,
    SUM(total_amount) as lifetime_value,
    AVG(total_amount) as avg_order_value,
    MAX(order_date) as last_order_date,
    COLLECT_LIST(order_id) as order_ids
  FROM orders_stream
  WHERE op != 'd'
  GROUP BY customer_id
  EMIT CHANGES;

-- =====================================================
-- 4. Join Streams for Enrichment
-- =====================================================

-- Enrich appointments with patient information
CREATE STREAM enriched_appointments AS
  SELECT
    a.appointment_id,
    a.appointment_date,
    a.doctor_id,
    a.status,
    p.patient_id,
    CONCAT(p.first_name, ' ', p.last_name) as patient_name,
    p.insurance_provider,
    p.medical_conditions,
    a.reason,
    a.duration_minutes
  FROM appointments_stream a
  INNER JOIN patients_stream p
    WITHIN 7 DAYS
    ON a.patient_id = p.patient_id
  EMIT CHANGES;

-- =====================================================
-- 5. Anomaly Detection Queries
-- =====================================================

-- Detect unusual appointment patterns
CREATE STREAM appointment_anomalies AS
  SELECT
    doctor_id,
    appointment_count,
    avg_duration,
    'UNUSUAL_LOAD' as anomaly_type
  FROM appointment_stats
  WHERE appointment_count > 20  -- More than 20 appointments per hour
    OR avg_duration > 120      -- Average duration over 2 hours
  EMIT CHANGES;

-- Detect sensor reading anomalies
CREATE STREAM sensor_anomalies AS
  SELECT
    bin_id,
    timestamp,
    fill_level,
    temperature,
    battery_level,
    CASE
      WHEN fill_level < 0 OR fill_level > 100 THEN 'INVALID_FILL_LEVEL'
      WHEN temperature < -20 OR temperature > 80 THEN 'EXTREME_TEMPERATURE'
      WHEN battery_level < 0 OR battery_level > 100 THEN 'INVALID_BATTERY'
      ELSE 'UNKNOWN'
    END as anomaly_type
  FROM sensor_readings_stream
  WHERE fill_level < 0 OR fill_level > 100
    OR temperature < -20 OR temperature > 80
    OR battery_level < 0 OR battery_level > 100
  EMIT CHANGES;

-- Detect suspicious order patterns
CREATE STREAM suspicious_orders AS
  SELECT
    customer_id,
    COUNT(*) as order_count,
    SUM(total_amount) as total_spent,
    COLLECT_LIST(order_id) as order_ids
  FROM orders_stream
  WINDOW TUMBLING (SIZE 1 HOUR)
  GROUP BY customer_id
  HAVING COUNT(*) > 10  -- More than 10 orders per hour
    OR SUM(total_amount) > 10000  -- Over $10,000 spent in an hour
  EMIT CHANGES;

-- =====================================================
-- 6. Real-time Aggregations
-- =====================================================

-- Appointment trends by hour
CREATE STREAM hourly_appointment_trends AS
  SELECT
    TIMESTAMPTOSTRING(WINDOWSTART, 'yyyy-MM-dd HH:mm:ss') as hour,
    COUNT(*) as appointments,
    COUNT(DISTINCT patient_id) as unique_patients,
    COUNT(DISTINCT doctor_id) as doctors_working,
    AVG(duration_minutes) as avg_duration
  FROM appointments_stream
  WINDOW HOPPING (SIZE 1 HOUR, ADVANCE BY 30 MINUTES)
  GROUP BY ROWKEY
  EMIT CHANGES;

-- IoT collection route optimization
CREATE STREAM collection_priorities AS
  SELECT
    COLLECT_LIST(STRUCT(
      bin_id := bin_id,
      fill_level := fill_level,
      location := location
    )) as bins_to_collect,
    COUNT(*) as bin_count,
    AVG(fill_level) as avg_fill_level
  FROM iot_alerts
  WHERE alert_type IN ('CRITICAL_FULL', 'NEEDS_COLLECTION')
  WINDOW TUMBLING (SIZE 15 MINUTES)
  GROUP BY ROWKEY
  EMIT CHANGES;

-- Revenue tracking by payment method
CREATE STREAM revenue_by_payment AS
  SELECT
    payment_method,
    WINDOWSTART as window_start,
    COUNT(*) as transaction_count,
    SUM(total_amount) as total_revenue,
    AVG(total_amount) as avg_transaction
  FROM orders_stream
  WHERE op != 'd'
  WINDOW TUMBLING (SIZE 1 HOUR)
  GROUP BY payment_method
  EMIT CHANGES;

-- =====================================================
-- 7. CDC Monitoring Queries
-- =====================================================

-- Monitor CDC lag
CREATE STREAM cdc_lag_monitoring AS
  SELECT
    'patients' as table_name,
    MAX(ts_ms) as last_event_time,
    (ROWTIME - MAX(ts_ms)) as lag_ms,
    COUNT(*) as events_processed
  FROM patients_stream
  WINDOW TUMBLING (SIZE 1 MINUTE)
  GROUP BY ROWKEY
  EMIT CHANGES;

-- Track CDC operation distribution
CREATE STREAM cdc_operation_stats AS
  SELECT
    op,
    COUNT(*) as operation_count,
    CASE op
      WHEN 'c' THEN 'INSERT'
      WHEN 'u' THEN 'UPDATE'
      WHEN 'd' THEN 'DELETE'
      WHEN 'r' THEN 'READ'
      ELSE 'UNKNOWN'
    END as operation_type
  FROM appointments_stream
  WINDOW TUMBLING (SIZE 5 MINUTES)
  GROUP BY op
  EMIT CHANGES;

-- =====================================================
-- 8. Data Quality Monitoring
-- =====================================================

-- Check for missing required fields
CREATE STREAM data_quality_issues AS
  SELECT
    'patients' as table_name,
    patient_id,
    CASE
      WHEN first_name IS NULL THEN 'MISSING_FIRST_NAME'
      WHEN last_name IS NULL THEN 'MISSING_LAST_NAME'
      WHEN email IS NULL THEN 'MISSING_EMAIL'
      ELSE 'OTHER'
    END as issue_type,
    ts_ms
  FROM patients_stream
  WHERE first_name IS NULL
    OR last_name IS NULL
    OR email IS NULL
  EMIT CHANGES;

-- =====================================================
-- 9. Create Sink Connectors
-- =====================================================

-- Send alerts to notification topic
CREATE STREAM NOTIFICATION_STREAM
  WITH (KAFKA_TOPIC='notifications', VALUE_FORMAT='JSON')
AS SELECT
  'IOT_ALERT' as notification_type,
  bin_id as entity_id,
  alert_type,
  fill_level,
  battery_level,
  timestamp,
  location
FROM iot_alerts
WHERE alert_type != 'NORMAL'
EMIT CHANGES;

-- Send aggregated stats to reporting topic
CREATE STREAM REPORTING_STREAM
  WITH (KAFKA_TOPIC='reporting.appointments', VALUE_FORMAT='AVRO')
AS SELECT
  doctor_id,
  window_start,
  window_end,
  appointment_count,
  completed_count,
  cancelled_count,
  avg_duration
FROM appointment_stats
EMIT CHANGES;