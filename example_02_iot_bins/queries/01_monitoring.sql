-- ============================================================================
-- IoT Garbage Bin Monitoring System - Real-time Monitoring Queries
-- ============================================================================
-- Description: Queries for real-time monitoring of bin status and sensors
-- ============================================================================

USE iot_bins;

-- ============================================================================
-- 1. Current Critical Bins (>90% full)
-- ============================================================================
SELECT
    b.bin_code,
    b.bin_type,
    d.name AS district,
    b.address,
    ROUND(cbs.current_fill_percentage, 1) AS fill_percentage,
    cbs.last_collected_at,
    TIMESTAMPDIFF(HOUR, cbs.last_collected_at, NOW()) AS hours_since_collection,
    cbs.active_alert_count AS alerts,
    CASE
        WHEN cbs.current_fill_percentage >= 95 THEN 'EMERGENCY'
        WHEN cbs.current_fill_percentage >= 90 THEN 'CRITICAL'
        ELSE 'HIGH'
    END AS urgency
FROM v_current_bin_status cbs
INNER JOIN bins b ON cbs.bin_id = b.bin_id
INNER JOIN districts d ON b.district_id = d.district_id
WHERE cbs.current_fill_percentage >= 90
ORDER BY cbs.current_fill_percentage DESC, hours_since_collection DESC
LIMIT 20;

-- ============================================================================
-- 2. Offline Sensors in Last Hour
-- ============================================================================
SELECT
    s.sensor_code,
    s.sensor_type,
    b.bin_code,
    d.name AS district,
    b.address,
    s.last_reading_time,
    TIMESTAMPDIFF(MINUTE, s.last_reading_time, NOW()) AS minutes_offline,
    s.battery_level
FROM sensors s
INNER JOIN bins b ON s.bin_id = b.bin_id
INNER JOIN districts d ON b.district_id = d.district_id
WHERE s.status = 'active'
    AND (s.last_reading_time IS NULL
         OR TIMESTAMPDIFF(MINUTE, s.last_reading_time, NOW()) > 60)
ORDER BY minutes_offline DESC;

-- ============================================================================
-- 3. Low Battery Sensors (<20%)
-- ============================================================================
SELECT
    s.sensor_code,
    s.sensor_type,
    b.bin_code,
    d.name AS district,
    s.battery_level,
    s.last_reading_time,
    DATEDIFF(NOW(), s.installation_date) AS days_in_service,
    CASE
        WHEN s.battery_level < 10 THEN 'CRITICAL'
        WHEN s.battery_level < 15 THEN 'LOW'
        ELSE 'WARNING'
    END AS battery_status
FROM sensors s
INNER JOIN bins b ON s.bin_id = b.bin_id
INNER JOIN districts d ON b.district_id = d.district_id
WHERE s.status = 'active'
    AND s.battery_level < 20
ORDER BY s.battery_level ASC;

-- ============================================================================
-- 4. District Overview Dashboard
-- ============================================================================
SELECT
    d.name AS district,
    COUNT(DISTINCT b.bin_id) AS total_bins,
    COUNT(DISTINCT CASE WHEN cbs.current_fill_percentage >= 80 THEN b.bin_id END) AS bins_near_full,
    ROUND(AVG(cbs.current_fill_percentage), 1) AS avg_fill_percentage,
    COUNT(DISTINCT CASE WHEN s.status = 'offline' THEN s.sensor_id END) AS offline_sensors,
    COUNT(DISTINCT CASE WHEN a.resolved_at IS NULL THEN a.alert_id END) AS active_alerts
FROM districts d
LEFT JOIN bins b ON d.district_id = b.district_id AND b.status = 'active'
LEFT JOIN v_current_bin_status cbs ON b.bin_id = cbs.bin_id
LEFT JOIN sensors s ON b.bin_id = s.bin_id
LEFT JOIN alerts a ON b.bin_id = a.bin_id AND a.resolved_at IS NULL
GROUP BY d.district_id
ORDER BY bins_near_full DESC, avg_fill_percentage DESC;

-- ============================================================================
-- 5. Real-time Sensor Health Summary
-- ============================================================================
SELECT
    sensor_type,
    COUNT(*) AS total_sensors,
    SUM(CASE WHEN status = 'active' THEN 1 ELSE 0 END) AS active,
    SUM(CASE WHEN status = 'offline' THEN 1 ELSE 0 END) AS offline,
    SUM(CASE WHEN status = 'maintenance' THEN 1 ELSE 0 END) AS maintenance,
    SUM(CASE WHEN status = 'faulty' THEN 1 ELSE 0 END) AS faulty,
    ROUND(AVG(battery_level), 1) AS avg_battery_level,
    MIN(battery_level) AS min_battery_level
FROM sensors
GROUP BY sensor_type
ORDER BY sensor_type;

-- ============================================================================
-- 6. Bins Requiring Immediate Collection
-- ============================================================================
SELECT
    uc.bin_code,
    uc.district_id,
    d.name AS district,
    uc.address,
    uc.bin_type,
    ROUND(uc.current_fill_percentage, 1) AS fill_pct,
    uc.urgency_level,
    uc.route_code,
    uc.hours_since_collection,
    ROUND(uc.avg_fill_rate_per_hour, 2) AS fill_rate_per_hour,
    ROUND(
        CASE
            WHEN uc.avg_fill_rate_per_hour > 0 THEN
                (100 - uc.current_fill_percentage) / uc.avg_fill_rate_per_hour
            ELSE NULL
        END, 1
    ) AS hours_until_full
FROM v_urgent_collections uc
INNER JOIN districts d ON uc.district_id = d.district_id
WHERE uc.urgency_level IN ('Critical', 'High')
ORDER BY
    FIELD(uc.urgency_level, 'Critical', 'High', 'Medium'),
    uc.current_fill_percentage DESC
LIMIT 30;

-- ============================================================================
-- 7. Active Alerts by Severity
-- ============================================================================
SELECT
    a.severity,
    a.alert_type,
    COUNT(*) AS count,
    MIN(a.triggered_at) AS oldest_alert,
    MAX(a.triggered_at) AS newest_alert,
    AVG(TIMESTAMPDIFF(HOUR, a.triggered_at, NOW())) AS avg_age_hours,
    GROUP_CONCAT(DISTINCT b.bin_code ORDER BY b.bin_code SEPARATOR ', ') AS affected_bins
FROM alerts a
INNER JOIN bins b ON a.bin_id = b.bin_id
WHERE a.resolved_at IS NULL
GROUP BY a.severity, a.alert_type
ORDER BY
    FIELD(a.severity, 'emergency', 'critical', 'warning', 'info'),
    count DESC;

-- ============================================================================
-- 8. Collection Progress Today
-- ============================================================================
SELECT
    cs.schedule_id,
    cr.route_code,
    d.name AS district,
    cs.status,
    cs.scheduled_start_time,
    cs.scheduled_end_time,
    t.truck_code,
    CONCAT(dr.first_name, ' ', dr.last_name) AS driver_name,
    (
        SELECT COUNT(*)
        FROM route_bin_assignments rba
        WHERE rba.route_id = cr.route_id
    ) AS total_bins,
    (
        SELECT COUNT(DISTINCT ce.bin_id)
        FROM collection_events ce
        INNER JOIN route_bin_assignments rba2 ON ce.bin_id = rba2.bin_id
        WHERE rba2.route_id = cr.route_id
            AND DATE(ce.collected_at) = CURDATE()
    ) AS bins_collected
FROM collection_schedules cs
INNER JOIN collection_routes cr ON cs.route_id = cr.route_id
INNER JOIN districts d ON cr.district_id = d.district_id
INNER JOIN trucks t ON cs.truck_id = t.truck_id
INNER JOIN drivers dr ON cs.driver_id = dr.driver_id
WHERE cs.scheduled_date = CURDATE()
ORDER BY cs.scheduled_start_time;

-- ============================================================================
-- 9. Temperature Anomalies
-- ============================================================================
SELECT
    b.bin_code,
    b.bin_type,
    d.name AS district,
    sr.reading_value AS temperature,
    sr.reading_time,
    CASE
        WHEN sr.reading_value > 40 THEN 'HIGH_TEMP'
        WHEN sr.reading_value < 0 THEN 'FREEZING'
        ELSE 'ANOMALY'
    END AS issue
FROM sensor_readings sr
INNER JOIN sensors s ON sr.sensor_id = s.sensor_id
INNER JOIN bins b ON s.bin_id = b.bin_id
INNER JOIN districts d ON b.district_id = d.district_id
WHERE s.sensor_type = 'temperature'
    AND sr.reading_time >= DATE_SUB(NOW(), INTERVAL 1 HOUR)
    AND (sr.reading_value > 40 OR sr.reading_value < 0)
ORDER BY sr.reading_time DESC
LIMIT 20;

-- ============================================================================
-- 10. System Performance Metrics
-- ============================================================================
SELECT
    'Total Bins' AS metric,
    COUNT(*) AS value
FROM bins
WHERE status = 'active'
UNION ALL
SELECT
    'Bins >80% Full',
    COUNT(*)
FROM v_current_bin_status
WHERE current_fill_percentage >= 80
UNION ALL
SELECT
    'Active Sensors',
    COUNT(*)
FROM sensors
WHERE status = 'active'
UNION ALL
SELECT
    'Offline Sensors',
    COUNT(*)
FROM sensors
WHERE status = 'offline'
    OR (last_reading_time IS NOT NULL
        AND TIMESTAMPDIFF(HOUR, last_reading_time, NOW()) > 1)
UNION ALL
SELECT
    'Unresolved Alerts',
    COUNT(*)
FROM alerts
WHERE resolved_at IS NULL
UNION ALL
SELECT
    'Collections Today',
    COUNT(*)
FROM collection_events
WHERE DATE(collected_at) = CURDATE()
UNION ALL
SELECT
    'Avg Collection Efficiency %',
    ROUND(AVG(fill_level_before), 1)
FROM collection_events
WHERE collected_at >= DATE_SUB(NOW(), INTERVAL 7 DAY);