-- ============================================================================
-- IoT Garbage Bin Monitoring System - Aggregation Tables and Views
-- ============================================================================
-- Description: Creates aggregation views and materialized views for analytics
-- Dependencies: All previous schema files must be run first
-- ============================================================================

USE iot_bins;

-- ============================================================================
-- Views for Real-time Monitoring
-- ============================================================================

-- Current bin status with latest sensor readings
CREATE OR REPLACE VIEW v_current_bin_status AS
SELECT
    b.bin_id,
    b.bin_code,
    b.bin_type,
    b.district_id,
    d.name AS district_name,
    b.latitude,
    b.longitude,
    b.address,
    b.capacity_liters,
    b.status AS bin_status,
    -- Fill level from most recent reading
    (
        SELECT sr.reading_value
        FROM sensor_readings sr
        INNER JOIN sensors s ON sr.sensor_id = s.sensor_id
        WHERE s.bin_id = b.bin_id
            AND s.sensor_type = 'fill_level'
            AND s.status = 'active'
        ORDER BY sr.reading_time DESC
        LIMIT 1
    ) AS current_fill_percentage,
    -- Temperature
    (
        SELECT sr.reading_value
        FROM sensor_readings sr
        INNER JOIN sensors s ON sr.sensor_id = s.sensor_id
        WHERE s.bin_id = b.bin_id
            AND s.sensor_type = 'temperature'
            AND s.status = 'active'
        ORDER BY sr.reading_time DESC
        LIMIT 1
    ) AS current_temperature,
    -- Battery level
    (
        SELECT s.battery_level
        FROM sensors s
        WHERE s.bin_id = b.bin_id
            AND s.sensor_type = 'battery'
            AND s.status = 'active'
        ORDER BY s.last_reading_time DESC
        LIMIT 1
    ) AS battery_level,
    -- Last collection
    (
        SELECT collected_at
        FROM collection_events
        WHERE bin_id = b.bin_id
        ORDER BY collected_at DESC
        LIMIT 1
    ) AS last_collected_at,
    -- Active alerts count
    (
        SELECT COUNT(*)
        FROM alerts
        WHERE bin_id = b.bin_id
            AND resolved_at IS NULL
    ) AS active_alert_count
FROM bins b
INNER JOIN districts d ON b.district_id = d.district_id
WHERE b.status = 'active';

-- Sensors health monitoring view
CREATE OR REPLACE VIEW v_sensor_health AS
SELECT
    s.sensor_id,
    s.sensor_code,
    s.sensor_type,
    b.bin_code,
    b.district_id,
    s.status,
    s.battery_level,
    s.last_reading_time,
    TIMESTAMPDIFF(MINUTE, s.last_reading_time, NOW()) AS minutes_since_last_reading,
    CASE
        WHEN s.status != 'active' THEN 'Inactive'
        WHEN TIMESTAMPDIFF(MINUTE, s.last_reading_time, NOW()) > 60 THEN 'No Recent Data'
        WHEN s.battery_level < 10 THEN 'Critical Battery'
        WHEN s.battery_level < 20 THEN 'Low Battery'
        ELSE 'Healthy'
    END AS health_status
FROM sensors s
INNER JOIN bins b ON s.bin_id = b.bin_id;

-- ============================================================================
-- Analytics Views
-- ============================================================================

-- District-level statistics
CREATE OR REPLACE VIEW v_district_statistics AS
SELECT
    d.district_id,
    d.district_code,
    d.name AS district_name,
    d.area_km2,
    COUNT(DISTINCT b.bin_id) AS total_bins,
    COUNT(DISTINCT CASE WHEN b.status = 'active' THEN b.bin_id END) AS active_bins,
    SUM(b.capacity_liters) / 1000 AS total_capacity_m3,
    COUNT(DISTINCT s.sensor_id) AS total_sensors,
    COUNT(DISTINCT CASE WHEN s.status = 'active' THEN s.sensor_id END) AS active_sensors,
    AVG(
        SELECT AVG(sr.reading_value)
        FROM sensor_readings sr
        INNER JOIN sensors sen ON sr.sensor_id = sen.sensor_id
        WHERE sen.bin_id = b.bin_id
            AND sen.sensor_type = 'fill_level'
            AND sr.reading_time >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
    ) AS avg_fill_level_24h
FROM districts d
LEFT JOIN bins b ON d.district_id = b.district_id
LEFT JOIN sensors s ON b.bin_id = s.bin_id
GROUP BY d.district_id;

-- Collection performance metrics
CREATE OR REPLACE VIEW v_collection_performance AS
SELECT
    DATE(ce.collected_at) AS collection_date,
    d.driver_id,
    CONCAT(d.first_name, ' ', d.last_name) AS driver_name,
    t.truck_code,
    COUNT(DISTINCT ce.bin_id) AS bins_collected,
    SUM(ce.weight_kg) AS total_weight_kg,
    AVG(ce.collection_duration_seconds) AS avg_collection_seconds,
    AVG(ce.fill_level_before) AS avg_fill_level,
    COUNT(DISTINCT cs.route_id) AS routes_completed
FROM collection_events ce
INNER JOIN drivers d ON ce.driver_id = d.driver_id
INNER JOIN trucks t ON ce.truck_id = t.truck_id
LEFT JOIN collection_schedules cs ON ce.schedule_id = cs.schedule_id
WHERE ce.collected_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY DATE(ce.collected_at), d.driver_id, t.truck_id;

-- Daily fill rate trends
CREATE OR REPLACE VIEW v_daily_fill_trends AS
SELECT
    srd.date,
    b.district_id,
    b.bin_type,
    COUNT(DISTINCT b.bin_id) AS bin_count,
    AVG(srd.avg_value) AS avg_fill_rate,
    MAX(srd.max_value) AS max_fill_rate,
    MIN(srd.min_value) AS min_fill_rate,
    AVG(srd.peak_value) AS avg_peak_value,
    AVG(srd.quality_good_pct) AS avg_quality_good_pct
FROM sensor_readings_daily srd
INNER JOIN sensors s ON srd.sensor_id = s.sensor_id
INNER JOIN bins b ON s.bin_id = b.bin_id
WHERE s.sensor_type = 'fill_level'
GROUP BY srd.date, b.district_id, b.bin_type;

-- ============================================================================
-- Route Optimization Views
-- ============================================================================

-- Bins requiring urgent collection
CREATE OR REPLACE VIEW v_urgent_collections AS
SELECT
    b.bin_id,
    b.bin_code,
    b.district_id,
    b.latitude,
    b.longitude,
    b.address,
    b.bin_type,
    cbs.current_fill_percentage,
    cbs.last_collected_at,
    TIMESTAMPDIFF(HOUR, cbs.last_collected_at, NOW()) AS hours_since_collection,
    rba.route_id,
    cr.route_code,
    CASE
        WHEN cbs.current_fill_percentage >= 90 THEN 'Critical'
        WHEN cbs.current_fill_percentage >= 80 THEN 'High'
        WHEN cbs.current_fill_percentage >= 70 THEN 'Medium'
        ELSE 'Low'
    END AS urgency_level,
    -- Estimated fill rate per hour based on historical data
    (
        SELECT AVG(
            (srd2.avg_value - srd1.avg_value) / 24
        )
        FROM sensor_readings_daily srd1
        INNER JOIN sensor_readings_daily srd2
            ON srd1.sensor_id = srd2.sensor_id
            AND srd2.date = DATE_ADD(srd1.date, INTERVAL 1 DAY)
        INNER JOIN sensors s ON srd1.sensor_id = s.sensor_id
        WHERE s.bin_id = b.bin_id
            AND s.sensor_type = 'fill_level'
            AND srd1.date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
    ) AS avg_fill_rate_per_hour
FROM bins b
INNER JOIN v_current_bin_status cbs ON b.bin_id = cbs.bin_id
LEFT JOIN route_bin_assignments rba ON b.bin_id = rba.bin_id
LEFT JOIN collection_routes cr ON rba.route_id = cr.route_id
WHERE b.status = 'active'
    AND cbs.current_fill_percentage >= 70
ORDER BY cbs.current_fill_percentage DESC;

-- Route efficiency metrics
CREATE OR REPLACE VIEW v_route_efficiency AS
SELECT
    cr.route_id,
    cr.route_code,
    cr.route_name,
    d.name AS district_name,
    COUNT(DISTINCT rba.bin_id) AS total_bins,
    cr.estimated_duration_minutes,
    cr.estimated_distance_km,
    -- Average fill level when collected
    (
        SELECT AVG(ce.fill_level_before)
        FROM collection_events ce
        INNER JOIN route_bin_assignments rba2 ON ce.bin_id = rba2.bin_id
        WHERE rba2.route_id = cr.route_id
            AND ce.collected_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
    ) AS avg_fill_on_collection,
    -- Collection frequency
    (
        SELECT COUNT(DISTINCT DATE(ce.collected_at))
        FROM collection_events ce
        INNER JOIN route_bin_assignments rba2 ON ce.bin_id = rba2.bin_id
        WHERE rba2.route_id = cr.route_id
            AND ce.collected_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
    ) AS collections_last_30_days
FROM collection_routes cr
INNER JOIN districts d ON cr.district_id = d.district_id
LEFT JOIN route_bin_assignments rba ON cr.route_id = rba.route_id
WHERE cr.active = TRUE
GROUP BY cr.route_id;

-- ============================================================================
-- Alert Summary Views
-- ============================================================================

-- Active alerts summary
CREATE OR REPLACE VIEW v_active_alerts_summary AS
SELECT
    a.alert_type,
    a.severity,
    COUNT(*) AS alert_count,
    COUNT(DISTINCT a.bin_id) AS affected_bins,
    MIN(a.triggered_at) AS oldest_alert,
    MAX(a.triggered_at) AS newest_alert,
    AVG(TIMESTAMPDIFF(HOUR, a.triggered_at, NOW())) AS avg_age_hours,
    SUM(CASE WHEN a.acknowledged = FALSE THEN 1 ELSE 0 END) AS unacknowledged_count
FROM alerts a
WHERE a.resolved_at IS NULL
GROUP BY a.alert_type, a.severity
ORDER BY
    FIELD(a.severity, 'emergency', 'critical', 'warning', 'info'),
    alert_count DESC;

-- Historical alert patterns
CREATE OR REPLACE VIEW v_alert_patterns AS
SELECT
    DATE(a.triggered_at) AS alert_date,
    HOUR(a.triggered_at) AS alert_hour,
    a.alert_type,
    COUNT(*) AS alert_count,
    COUNT(DISTINCT a.bin_id) AS bins_affected,
    AVG(TIMESTAMPDIFF(MINUTE, a.triggered_at, a.resolved_at)) AS avg_resolution_minutes
FROM alerts a
WHERE a.triggered_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY DATE(a.triggered_at), HOUR(a.triggered_at), a.alert_type;

-- ============================================================================
-- Predictive Analytics Views
-- ============================================================================

-- Bins with increasing fill rates
CREATE OR REPLACE VIEW v_fill_rate_acceleration AS
SELECT
    b.bin_id,
    b.bin_code,
    b.district_id,
    -- Current week average
    (
        SELECT AVG(srd.avg_value)
        FROM sensor_readings_daily srd
        INNER JOIN sensors s ON srd.sensor_id = s.sensor_id
        WHERE s.bin_id = b.bin_id
            AND s.sensor_type = 'fill_level'
            AND srd.date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
    ) AS current_week_avg,
    -- Previous week average
    (
        SELECT AVG(srd.avg_value)
        FROM sensor_readings_daily srd
        INNER JOIN sensors s ON srd.sensor_id = s.sensor_id
        WHERE s.bin_id = b.bin_id
            AND s.sensor_type = 'fill_level'
            AND srd.date >= DATE_SUB(CURDATE(), INTERVAL 14 DAY)
            AND srd.date < DATE_SUB(CURDATE(), INTERVAL 7 DAY)
    ) AS previous_week_avg,
    -- Rate of change
    (
        (
            SELECT AVG(srd.avg_value)
            FROM sensor_readings_daily srd
            INNER JOIN sensors s ON srd.sensor_id = s.sensor_id
            WHERE s.bin_id = b.bin_id
                AND s.sensor_type = 'fill_level'
                AND srd.date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
        ) -
        (
            SELECT AVG(srd.avg_value)
            FROM sensor_readings_daily srd
            INNER JOIN sensors s ON srd.sensor_id = s.sensor_id
            WHERE s.bin_id = b.bin_id
                AND s.sensor_type = 'fill_level'
                AND srd.date >= DATE_SUB(CURDATE(), INTERVAL 14 DAY)
                AND srd.date < DATE_SUB(CURDATE(), INTERVAL 7 DAY)
        )
    ) AS fill_rate_change
FROM bins b
WHERE b.status = 'active'
HAVING current_week_avg IS NOT NULL AND previous_week_avg IS NOT NULL
ORDER BY fill_rate_change DESC;

-- Display confirmation
SELECT 'All aggregation views created successfully' AS Status;