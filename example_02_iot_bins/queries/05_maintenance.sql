-- ============================================================================
-- IoT Garbage Bin Monitoring System - Maintenance Queries
-- ============================================================================
-- Description: Queries for sensor health monitoring and predictive maintenance
-- ============================================================================

USE iot_bins;

-- ============================================================================
-- 1. Sensor Battery Degradation Analysis
-- ============================================================================
WITH battery_trend AS (
    SELECT
        s.sensor_id,
        s.sensor_code,
        s.sensor_type,
        b.bin_code,
        s.installation_date,
        s.battery_level AS current_battery,
        DATEDIFF(CURDATE(), s.installation_date) AS days_active,
        -- Calculate degradation rate
        (100 - s.battery_level) / NULLIF(DATEDIFF(CURDATE(), s.installation_date), 0) AS daily_degradation_rate,
        -- Estimate days until critical (10%)
        CASE
            WHEN s.battery_level > 10 THEN
                (s.battery_level - 10) / NULLIF((100 - s.battery_level) / NULLIF(DATEDIFF(CURDATE(), s.installation_date), 0), 0)
            ELSE 0
        END AS estimated_days_remaining
    FROM sensors s
    INNER JOIN bins b ON s.bin_id = b.bin_id
    WHERE s.status = 'active'
        AND s.battery_level IS NOT NULL
)
SELECT
    sensor_code,
    sensor_type,
    bin_code,
    installation_date,
    ROUND(current_battery, 2) AS current_battery_pct,
    days_active,
    ROUND(daily_degradation_rate, 4) AS daily_degradation_pct,
    ROUND(estimated_days_remaining, 0) AS days_until_critical,
    DATE_ADD(CURDATE(), INTERVAL ROUND(estimated_days_remaining, 0) DAY) AS estimated_critical_date,
    CASE
        WHEN estimated_days_remaining <= 7 THEN 'URGENT'
        WHEN estimated_days_remaining <= 30 THEN 'SOON'
        WHEN estimated_days_remaining <= 60 THEN 'SCHEDULED'
        ELSE 'MONITOR'
    END AS maintenance_priority
FROM battery_trend
WHERE estimated_days_remaining < 90
ORDER BY estimated_days_remaining ASC;

-- ============================================================================
-- 2. Sensor Reading Quality Trends
-- ============================================================================
SELECT
    s.sensor_id,
    s.sensor_code,
    s.sensor_type,
    b.bin_code,
    -- Last 7 days quality metrics
    (
        SELECT COUNT(*)
        FROM sensor_readings sr
        WHERE sr.sensor_id = s.sensor_id
            AND sr.reading_time >= DATE_SUB(NOW(), INTERVAL 7 DAY)
    ) AS total_readings_7d,
    (
        SELECT SUM(CASE WHEN quality = 'error' THEN 1 ELSE 0 END)
        FROM sensor_readings sr
        WHERE sr.sensor_id = s.sensor_id
            AND sr.reading_time >= DATE_SUB(NOW(), INTERVAL 7 DAY)
    ) AS error_readings_7d,
    (
        SELECT SUM(CASE WHEN quality = 'warning' THEN 1 ELSE 0 END)
        FROM sensor_readings sr
        WHERE sr.sensor_id = s.sensor_id
            AND sr.reading_time >= DATE_SUB(NOW(), INTERVAL 7 DAY)
    ) AS warning_readings_7d,
    -- Calculate error rate
    ROUND(100.0 * (
        SELECT SUM(CASE WHEN quality IN ('error', 'warning') THEN 1 ELSE 0 END)
        FROM sensor_readings sr
        WHERE sr.sensor_id = s.sensor_id
            AND sr.reading_time >= DATE_SUB(NOW(), INTERVAL 7 DAY)
    ) / NULLIF((
        SELECT COUNT(*)
        FROM sensor_readings sr
        WHERE sr.sensor_id = s.sensor_id
            AND sr.reading_time >= DATE_SUB(NOW(), INTERVAL 7 DAY)
    ), 0), 2) AS error_rate_pct,
    s.last_reading_time,
    TIMESTAMPDIFF(HOUR, s.last_reading_time, NOW()) AS hours_since_last_reading
FROM sensors s
INNER JOIN bins b ON s.bin_id = b.bin_id
WHERE s.status = 'active'
HAVING error_rate_pct > 5 OR hours_since_last_reading > 24
ORDER BY error_rate_pct DESC, hours_since_last_reading DESC;

-- ============================================================================
-- 3. Communication Failures Pattern
-- ============================================================================
WITH offline_periods AS (
    SELECT
        s.sensor_id,
        s.sensor_code,
        b.district_id,
        DATE(sr.reading_time) AS date,
        HOUR(sr.reading_time) AS hour,
        COUNT(*) AS expected_readings,
        SUM(CASE WHEN sr.reading_value IS NOT NULL THEN 1 ELSE 0 END) AS actual_readings
    FROM sensors s
    INNER JOIN bins b ON s.bin_id = b.bin_id
    CROSS JOIN (
        SELECT reading_time
        FROM sensor_readings
        WHERE reading_time >= DATE_SUB(NOW(), INTERVAL 7 DAY)
        GROUP BY reading_time
    ) sr
    LEFT JOIN sensor_readings sr_actual ON s.sensor_id = sr_actual.sensor_id
        AND sr.reading_time = sr_actual.reading_time
    WHERE s.status = 'active'
    GROUP BY s.sensor_id, DATE(sr.reading_time), HOUR(sr.reading_time)
)
SELECT
    d.name AS district,
    COUNT(DISTINCT op.sensor_id) AS affected_sensors,
    op.date,
    op.hour AS hour_of_day,
    AVG(100.0 * (op.expected_readings - op.actual_readings) / op.expected_readings) AS avg_failure_rate_pct,
    GROUP_CONCAT(DISTINCT op.sensor_code ORDER BY op.sensor_code SEPARATOR ', ') AS affected_sensor_codes
FROM offline_periods op
INNER JOIN sensors s ON op.sensor_id = s.sensor_id
INNER JOIN bins b ON s.bin_id = b.bin_id
INNER JOIN districts d ON b.district_id = d.district_id
WHERE op.actual_readings < op.expected_readings * 0.8  -- More than 20% missing
GROUP BY d.district_id, op.date, op.hour
HAVING COUNT(DISTINCT op.sensor_id) > 3  -- Pattern affecting multiple sensors
ORDER BY op.date DESC, op.hour DESC;

-- ============================================================================
-- 4. Bin Physical Maintenance Requirements
-- ============================================================================
SELECT
    b.bin_id,
    b.bin_code,
    b.bin_type,
    d.name AS district,
    b.installation_date,
    DATEDIFF(CURDATE(), b.installation_date) AS age_days,
    b.last_maintenance_date,
    DATEDIFF(CURDATE(), IFNULL(b.last_maintenance_date, b.installation_date)) AS days_since_maintenance,
    -- Check for damage indicators
    (
        SELECT COUNT(*)
        FROM alerts a
        WHERE a.bin_id = b.bin_id
            AND a.alert_type = 'tilt_detected'
            AND a.triggered_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
    ) AS tilt_alerts_30d,
    -- Check unusual patterns
    (
        SELECT COUNT(*)
        FROM alerts a
        WHERE a.bin_id = b.bin_id
            AND a.alert_type = 'maintenance_required'
            AND a.triggered_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
    ) AS maintenance_alerts_30d,
    b.status,
    CASE
        WHEN b.status IN ('maintenance', 'damaged') THEN 'IMMEDIATE'
        WHEN DATEDIFF(CURDATE(), IFNULL(b.last_maintenance_date, b.installation_date)) > 365 THEN 'OVERDUE'
        WHEN DATEDIFF(CURDATE(), IFNULL(b.last_maintenance_date, b.installation_date)) > 300 THEN 'SCHEDULED'
        ELSE 'OK'
    END AS maintenance_status
FROM bins b
INNER JOIN districts d ON b.district_id = d.district_id
WHERE b.status != 'decommissioned'
HAVING maintenance_status IN ('IMMEDIATE', 'OVERDUE', 'SCHEDULED')
ORDER BY
    FIELD(maintenance_status, 'IMMEDIATE', 'OVERDUE', 'SCHEDULED'),
    days_since_maintenance DESC;

-- ============================================================================
-- 5. Sensor Firmware Update Requirements
-- ============================================================================
SELECT
    s.sensor_type,
    s.manufacturer,
    s.model,
    s.firmware_version,
    COUNT(*) AS sensor_count,
    GROUP_CONCAT(s.sensor_code ORDER BY s.sensor_code SEPARATOR ', ') AS sensor_codes,
    MIN(s.installation_date) AS oldest_installation,
    MAX(s.installation_date) AS newest_installation,
    CASE
        WHEN s.firmware_version < '2.0.0' THEN 'CRITICAL UPDATE REQUIRED'
        WHEN s.firmware_version < '2.5.0' THEN 'UPDATE RECOMMENDED'
        ELSE 'UP TO DATE'
    END AS update_status
FROM sensors s
WHERE s.status != 'decommissioned'
GROUP BY s.sensor_type, s.manufacturer, s.model, s.firmware_version
HAVING update_status != 'UP TO DATE'
ORDER BY
    FIELD(update_status, 'CRITICAL UPDATE REQUIRED', 'UPDATE RECOMMENDED'),
    sensor_count DESC;

-- ============================================================================
-- 6. Predictive Failure Analysis
-- ============================================================================
WITH sensor_metrics AS (
    SELECT
        s.sensor_id,
        s.sensor_code,
        s.sensor_type,
        b.bin_code,
        s.battery_level,
        DATEDIFF(CURDATE(), s.installation_date) AS age_days,
        -- Recent error rate
        (
            SELECT AVG(CASE WHEN quality != 'good' THEN 1 ELSE 0 END)
            FROM sensor_readings sr
            WHERE sr.sensor_id = s.sensor_id
                AND sr.reading_time >= DATE_SUB(NOW(), INTERVAL 7 DAY)
        ) AS recent_error_rate,
        -- Offline frequency
        (
            SELECT COUNT(*)
            FROM alerts a
            WHERE a.sensor_id = s.sensor_id
                AND a.alert_type = 'sensor_offline'
                AND a.triggered_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
        ) AS offline_count_30d
    FROM sensors s
    INNER JOIN bins b ON s.bin_id = b.bin_id
    WHERE s.status = 'active'
)
SELECT
    sensor_code,
    sensor_type,
    bin_code,
    ROUND(battery_level, 1) AS battery_pct,
    age_days,
    ROUND(recent_error_rate * 100, 2) AS error_rate_pct,
    offline_count_30d,
    -- Calculate failure risk score (0-100)
    ROUND(
        (CASE WHEN battery_level < 20 THEN 30 ELSE 0 END) +
        (CASE WHEN age_days > 730 THEN 20 ELSE age_days / 36.5 END) +
        (recent_error_rate * 100) +
        (offline_count_30d * 5)
    , 1) AS failure_risk_score,
    CASE
        WHEN (
            (CASE WHEN battery_level < 20 THEN 30 ELSE 0 END) +
            (CASE WHEN age_days > 730 THEN 20 ELSE age_days / 36.5 END) +
            (recent_error_rate * 100) +
            (offline_count_30d * 5)
        ) > 70 THEN 'HIGH RISK'
        WHEN (
            (CASE WHEN battery_level < 20 THEN 30 ELSE 0 END) +
            (CASE WHEN age_days > 730 THEN 20 ELSE age_days / 36.5 END) +
            (recent_error_rate * 100) +
            (offline_count_30d * 5)
        ) > 40 THEN 'MEDIUM RISK'
        ELSE 'LOW RISK'
    END AS risk_category
FROM sensor_metrics
WHERE battery_level < 30
    OR age_days > 500
    OR recent_error_rate > 0.05
    OR offline_count_30d > 2
ORDER BY failure_risk_score DESC;

-- ============================================================================
-- 7. Maintenance Schedule Optimization
-- ============================================================================
SELECT
    d.name AS district,
    COUNT(DISTINCT CASE WHEN s.battery_level < 25 THEN s.sensor_id END) AS sensors_need_battery,
    COUNT(DISTINCT CASE WHEN DATEDIFF(CURDATE(), b.last_maintenance_date) > 365 THEN b.bin_id END) AS bins_need_maintenance,
    COUNT(DISTINCT CASE WHEN s.status = 'faulty' THEN s.sensor_id END) AS faulty_sensors,
    -- Estimate maintenance time
    (COUNT(DISTINCT CASE WHEN s.battery_level < 25 THEN s.sensor_id END) * 15 +
     COUNT(DISTINCT CASE WHEN DATEDIFF(CURDATE(), b.last_maintenance_date) > 365 THEN b.bin_id END) * 30) / 60
        AS estimated_hours,
    -- Suggested maintenance window
    CASE DAYOFWEEK(CURDATE())
        WHEN 1 THEN DATE_ADD(CURDATE(), INTERVAL 1 DAY)  -- Sunday -> Monday
        WHEN 7 THEN DATE_ADD(CURDATE(), INTERVAL 2 DAY)  -- Saturday -> Monday
        ELSE DATE_ADD(CURDATE(), INTERVAL 1 DAY)
    END AS suggested_date,
    -- Priority based on urgency
    CASE
        WHEN COUNT(DISTINCT CASE WHEN s.battery_level < 15 THEN s.sensor_id END) > 5 THEN 'URGENT'
        WHEN COUNT(DISTINCT CASE WHEN s.battery_level < 25 THEN s.sensor_id END) > 10 THEN 'HIGH'
        ELSE 'NORMAL'
    END AS priority
FROM districts d
LEFT JOIN bins b ON d.district_id = b.district_id AND b.status != 'decommissioned'
LEFT JOIN sensors s ON b.bin_id = s.bin_id AND s.status != 'decommissioned'
GROUP BY d.district_id
HAVING sensors_need_battery > 0 OR bins_need_maintenance > 0 OR faulty_sensors > 0
ORDER BY
    FIELD(priority, 'URGENT', 'HIGH', 'NORMAL'),
    estimated_hours DESC;

-- ============================================================================
-- 8. Component Lifecycle Analysis
-- ============================================================================
SELECT
    component_type,
    component_subtype,
    COUNT(*) AS total_count,
    AVG(age_days) AS avg_age_days,
    MIN(age_days) AS min_age_days,
    MAX(age_days) AS max_age_days,
    SUM(CASE WHEN needs_replacement THEN 1 ELSE 0 END) AS need_replacement,
    ROUND(100.0 * SUM(CASE WHEN needs_replacement THEN 1 ELSE 0 END) / COUNT(*), 1) AS replacement_rate_pct
FROM (
    SELECT
        'Sensor' AS component_type,
        sensor_type AS component_subtype,
        DATEDIFF(CURDATE(), installation_date) AS age_days,
        CASE
            WHEN battery_level < 15 OR status = 'faulty' THEN TRUE
            WHEN DATEDIFF(CURDATE(), installation_date) > 1095 THEN TRUE  -- 3 years
            ELSE FALSE
        END AS needs_replacement
    FROM sensors
    WHERE status != 'decommissioned'

    UNION ALL

    SELECT
        'Bin' AS component_type,
        bin_type AS component_subtype,
        DATEDIFF(CURDATE(), installation_date) AS age_days,
        CASE
            WHEN status IN ('damaged', 'decommissioned') THEN TRUE
            WHEN DATEDIFF(CURDATE(), installation_date) > 2190 THEN TRUE  -- 6 years
            ELSE FALSE
        END AS needs_replacement
    FROM bins
) AS components
GROUP BY component_type, component_subtype
ORDER BY replacement_rate_pct DESC, component_type, component_subtype;

-- ============================================================================
-- 9. Maintenance Cost Projection
-- ============================================================================
WITH maintenance_needs AS (
    SELECT
        'Battery Replacement' AS maintenance_type,
        COUNT(*) AS units_needed,
        25.00 AS unit_cost,  -- Cost per battery
        15 AS minutes_per_unit
    FROM sensors
    WHERE battery_level < 25 AND status = 'active'

    UNION ALL

    SELECT
        'Sensor Replacement',
        COUNT(*),
        150.00,  -- Cost per sensor
        30
    FROM sensors
    WHERE status = 'faulty' OR
          (battery_level < 10 AND DATEDIFF(CURDATE(), installation_date) > 1095)

    UNION ALL

    SELECT
        'Bin Repair',
        COUNT(*),
        200.00,  -- Cost per bin repair
        60
    FROM bins
    WHERE status = 'damaged'

    UNION ALL

    SELECT
        'Preventive Maintenance',
        COUNT(*),
        50.00,  -- Cost per bin
        20
    FROM bins
    WHERE DATEDIFF(CURDATE(), IFNULL(last_maintenance_date, installation_date)) > 365
        AND status = 'active'
)
SELECT
    maintenance_type,
    units_needed,
    unit_cost,
    ROUND(units_needed * unit_cost, 2) AS total_cost,
    ROUND(units_needed * minutes_per_unit / 60.0, 1) AS total_hours,
    CEIL(units_needed * minutes_per_unit / 60.0 / 8) AS technician_days_needed
FROM maintenance_needs
WHERE units_needed > 0
UNION ALL
SELECT
    'TOTAL' AS maintenance_type,
    SUM(units_needed),
    NULL,
    ROUND(SUM(units_needed * unit_cost), 2),
    ROUND(SUM(units_needed * minutes_per_unit / 60.0), 1),
    CEIL(SUM(units_needed * minutes_per_unit / 60.0 / 8))
FROM maintenance_needs
ORDER BY
    CASE WHEN maintenance_type = 'TOTAL' THEN 1 ELSE 0 END,
    total_cost DESC;