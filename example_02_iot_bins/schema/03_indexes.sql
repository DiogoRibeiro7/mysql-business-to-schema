-- ============================================================================
-- IoT Garbage Bin Monitoring System - Performance Indexes
-- ============================================================================
-- Description: Creates performance indexes for optimized query execution
-- Dependencies: 01_tables.sql and 02_constraints.sql must be run first
-- ============================================================================

USE iot_bins;

-- ============================================================================
-- Composite Indexes for Common Query Patterns
-- ============================================================================

-- Bins: Query by district and type
ALTER TABLE bins
    ADD INDEX idx_district_type_status (district_id, bin_type, status);

-- Sensors: Query active sensors by bin
ALTER TABLE sensors
    ADD INDEX idx_bin_type_status (bin_id, sensor_type, status);

-- Sensors: Find offline sensors
ALTER TABLE sensors
    ADD INDEX idx_status_last_reading (status, last_reading_time);

-- Sensor Readings: Time-based queries per sensor
ALTER TABLE sensor_readings
    ADD INDEX idx_sensor_time_quality (sensor_id, reading_time, quality);

-- Sensor Readings: Recent readings across all sensors
ALTER TABLE sensor_readings
    ADD INDEX idx_time_sensor (reading_time, sensor_id);

-- Collection Events: History per bin
ALTER TABLE collection_events
    ADD INDEX idx_bin_collected_fill (bin_id, collected_at, fill_level_before);

-- Collection Events: Daily collection summary
ALTER TABLE collection_events
    ADD INDEX idx_date_truck_driver (collected_at, truck_id, driver_id);

-- Alerts: Active alerts per bin
ALTER TABLE alerts
    ADD INDEX idx_bin_resolved_severity (bin_id, resolved_at, severity);

-- Alerts: Recent critical alerts
ALTER TABLE alerts
    ADD INDEX idx_severity_triggered (severity, triggered_at, resolved_at);

-- Alerts: Unacknowledged alerts
ALTER TABLE alerts
    ADD INDEX idx_acknowledged_severity (acknowledged, severity, triggered_at);

-- Collection Schedules: Daily schedule view
ALTER TABLE collection_schedules
    ADD INDEX idx_date_status_route (scheduled_date, status, route_id);

-- Collection Schedules: Driver schedule
ALTER TABLE collection_schedules
    ADD INDEX idx_driver_date_status (driver_id, scheduled_date, status);

-- Route Bin Assignments: Optimize route planning
ALTER TABLE route_bin_assignments
    ADD INDEX idx_route_order_bin (route_id, collection_order, bin_id);

-- ============================================================================
-- Covering Indexes for Frequent Queries
-- ============================================================================

-- Bins: Dashboard query (bin info without joins)
ALTER TABLE bins
    ADD INDEX idx_covering_dashboard (
        status,
        bin_type,
        district_id,
        capacity_liters,
        latitude,
        longitude
    );

-- Sensors: Battery monitoring query
ALTER TABLE sensors
    ADD INDEX idx_covering_battery (
        sensor_type,
        status,
        battery_level,
        last_reading_time,
        bin_id
    );

-- Sensor Readings Hourly: Time series analysis
ALTER TABLE sensor_readings_hourly
    ADD INDEX idx_covering_hourly_analysis (
        sensor_id,
        hour_start,
        avg_value,
        min_value,
        max_value,
        reading_count
    );

-- Collection Events: Performance metrics
ALTER TABLE collection_events
    ADD INDEX idx_covering_performance (
        driver_id,
        collected_at,
        collection_duration_seconds,
        weight_kg
    );

-- ============================================================================
-- Indexes for Aggregation Queries
-- ============================================================================

-- Sensor Readings: For hourly aggregation
ALTER TABLE sensor_readings
    ADD INDEX idx_hour_aggregation (
        sensor_id,
        DATE(reading_time),
        HOUR(reading_time)
    );

-- Sensor Readings Daily: For monthly summaries
ALTER TABLE sensor_readings_daily
    ADD INDEX idx_month_aggregation (
        sensor_id,
        YEAR(date),
        MONTH(date)
    );

-- Collection Events: For collection statistics
ALTER TABLE collection_events
    ADD INDEX idx_collection_stats (
        bin_id,
        YEAR(collected_at),
        MONTH(collected_at)
    );

-- ============================================================================
-- Full Text Indexes for Search
-- ============================================================================

-- Bins: Address search
ALTER TABLE bins
    ADD FULLTEXT INDEX ft_address (address);

-- Collection Events: Notes search
ALTER TABLE collection_events
    ADD FULLTEXT INDEX ft_notes (notes);

-- Alerts: Message search
ALTER TABLE alerts
    ADD FULLTEXT INDEX ft_message (message);

-- ============================================================================
-- Performance Monitoring Views (Optional)
-- ============================================================================

-- Create view for index usage statistics
CREATE OR REPLACE VIEW v_index_usage_stats AS
SELECT
    table_name,
    index_name,
    cardinality,
    ROUND((data_length + index_length) / 1024 / 1024, 2) AS size_mb
FROM information_schema.statistics;

-- Display confirmation
SELECT 'All indexes created successfully' AS Status;

-- Show index statistics
SELECT
    CONCAT('Created ', COUNT(DISTINCT index_name), ' indexes across ',
           COUNT(DISTINCT table_name), ' tables') AS Summary
FROM information_schema.statistics;
