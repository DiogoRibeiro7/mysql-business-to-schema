-- ============================================================================
-- IoT Garbage Bin Monitoring System - Aggregation Procedures
-- ============================================================================
-- Description: Stored procedures for data aggregation and summarization
-- ============================================================================

USE iot_bins;

DELIMITER //

-- ============================================================================
-- Procedure: Aggregate Hourly Sensor Data
-- ============================================================================
DROP PROCEDURE IF EXISTS sp_aggregate_hourly_data//

CREATE PROCEDURE sp_aggregate_hourly_data(
    IN p_start_datetime DATETIME,
    IN p_end_datetime DATETIME
)
BEGIN
    DECLARE v_rows_processed INT DEFAULT 0;

    -- Delete existing aggregates for the period (to handle re-runs)
    DELETE FROM sensor_readings_hourly
    WHERE hour_start >= p_start_datetime
        AND hour_start < p_end_datetime;

    -- Insert new hourly aggregates
    INSERT INTO sensor_readings_hourly (
        sensor_id,
        hour_start,
        min_value,
        max_value,
        avg_value,
        reading_count,
        quality_good_count,
        quality_warning_count,
        quality_error_count
    )
    SELECT
        sr.sensor_id,
        DATE_FORMAT(sr.reading_time, '%Y-%m-%d %H:00:00') AS hour_start,
        MIN(CASE WHEN sr.quality != 'error' THEN sr.reading_value END) AS min_value,
        MAX(CASE WHEN sr.quality != 'error' THEN sr.reading_value END) AS max_value,
        AVG(CASE WHEN sr.quality != 'error' THEN sr.reading_value END) AS avg_value,
        COUNT(*) AS reading_count,
        SUM(CASE WHEN sr.quality = 'good' THEN 1 ELSE 0 END) AS quality_good_count,
        SUM(CASE WHEN sr.quality = 'warning' THEN 1 ELSE 0 END) AS quality_warning_count,
        SUM(CASE WHEN sr.quality = 'error' THEN 1 ELSE 0 END) AS quality_error_count
    FROM sensor_readings sr
    WHERE sr.reading_time >= p_start_datetime
        AND sr.reading_time < p_end_datetime
    GROUP BY sr.sensor_id, DATE_FORMAT(sr.reading_time, '%Y-%m-%d %H:00:00');

    SET v_rows_processed = ROW_COUNT();

    SELECT CONCAT('Hourly aggregation complete. Rows processed: ', v_rows_processed) AS result;
END//

-- ============================================================================
-- Procedure: Aggregate Daily Sensor Data
-- ============================================================================
DROP PROCEDURE IF EXISTS sp_aggregate_daily_data//

CREATE PROCEDURE sp_aggregate_daily_data(
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    DECLARE v_rows_processed INT DEFAULT 0;

    -- Delete existing aggregates for the period
    DELETE FROM sensor_readings_daily
    WHERE date >= p_start_date
        AND date <= p_end_date;

    -- Insert new daily aggregates
    INSERT INTO sensor_readings_daily (
        sensor_id,
        date,
        min_value,
        max_value,
        avg_value,
        peak_hour,
        peak_value,
        reading_count,
        quality_good_pct,
        quality_warning_pct,
        quality_error_pct
    )
    SELECT
        srh.sensor_id,
        DATE(srh.hour_start) AS date,
        MIN(srh.min_value) AS min_value,
        MAX(srh.max_value) AS max_value,
        AVG(srh.avg_value) AS avg_value,
        SUBSTRING_INDEX(
            GROUP_CONCAT(
                TIME(srh.hour_start) ORDER BY srh.max_value DESC LIMIT 1
            ), ',', 1
        ) AS peak_hour,
        MAX(srh.max_value) AS peak_value,
        SUM(srh.reading_count) AS reading_count,
        ROUND(100.0 * SUM(srh.quality_good_count) / SUM(srh.reading_count), 2) AS quality_good_pct,
        ROUND(100.0 * SUM(srh.quality_warning_count) / SUM(srh.reading_count), 2) AS quality_warning_pct,
        ROUND(100.0 * SUM(srh.quality_error_count) / SUM(srh.reading_count), 2) AS quality_error_pct
    FROM sensor_readings_hourly srh
    WHERE DATE(srh.hour_start) >= p_start_date
        AND DATE(srh.hour_start) <= p_end_date
    GROUP BY srh.sensor_id, DATE(srh.hour_start);

    SET v_rows_processed = ROW_COUNT();

    SELECT CONCAT('Daily aggregation complete. Rows processed: ', v_rows_processed) AS result;
END//

-- ============================================================================
-- Procedure: Generate Alert Summary Report
-- ============================================================================
DROP PROCEDURE IF EXISTS sp_generate_alert_summary//

CREATE PROCEDURE sp_generate_alert_summary(
    IN p_district_id INT,
    IN p_days_back INT
)
BEGIN
    SELECT
        a.alert_type,
        a.severity,
        COUNT(*) AS alert_count,
        COUNT(DISTINCT a.bin_id) AS affected_bins,
        AVG(CASE
            WHEN a.resolved_at IS NOT NULL THEN
                TIMESTAMPDIFF(MINUTE, a.triggered_at, a.resolved_at)
            ELSE NULL
        END) AS avg_resolution_minutes,
        SUM(CASE WHEN a.resolved_at IS NULL THEN 1 ELSE 0 END) AS unresolved_count
    FROM alerts a
    INNER JOIN bins b ON a.bin_id = b.bin_id
    WHERE (p_district_id IS NULL OR b.district_id = p_district_id)
        AND a.triggered_at >= DATE_SUB(NOW(), INTERVAL p_days_back DAY)
    GROUP BY a.alert_type, a.severity
    ORDER BY
        FIELD(a.severity, 'emergency', 'critical', 'warning', 'info'),
        alert_count DESC;
END//

-- ============================================================================
-- Procedure: Calculate Collection Efficiency
-- ============================================================================
DROP PROCEDURE IF EXISTS sp_calculate_collection_efficiency//

CREATE PROCEDURE sp_calculate_collection_efficiency(
    IN p_start_date DATE,
    IN p_end_date DATE,
    OUT p_avg_efficiency DECIMAL(5,2),
    OUT p_total_collections INT,
    OUT p_total_weight_tons DECIMAL(10,2)
)
BEGIN
    SELECT
        ROUND(AVG(fill_level_before), 2),
        COUNT(*),
        ROUND(SUM(weight_kg) / 1000, 2)
    INTO
        p_avg_efficiency,
        p_total_collections,
        p_total_weight_tons
    FROM collection_events
    WHERE DATE(collected_at) BETWEEN p_start_date AND p_end_date;

    -- Also return as result set
    SELECT
        p_avg_efficiency AS avg_fill_at_collection,
        p_total_collections AS total_collections,
        p_total_weight_tons AS total_weight_tons,
        CASE
            WHEN p_avg_efficiency >= 85 THEN 'Excellent'
            WHEN p_avg_efficiency >= 75 THEN 'Good'
            WHEN p_avg_efficiency >= 65 THEN 'Fair'
            ELSE 'Needs Improvement'
        END AS efficiency_rating;
END//

-- ============================================================================
-- Procedure: Update Sensor Battery Levels
-- ============================================================================
DROP PROCEDURE IF EXISTS sp_update_sensor_battery_levels//

CREATE PROCEDURE sp_update_sensor_battery_levels()
BEGIN
    DECLARE v_updated_count INT DEFAULT 0;

    -- Update battery levels based on last reading from battery sensors
    UPDATE sensors s
    INNER JOIN (
        SELECT
            s2.bin_id,
            sr.reading_value AS battery_level
        FROM sensors s2
        INNER JOIN sensor_readings sr ON s2.sensor_id = sr.sensor_id
        WHERE s2.sensor_type = 'battery'
            AND sr.reading_time = (
                SELECT MAX(sr2.reading_time)
                FROM sensor_readings sr2
                WHERE sr2.sensor_id = s2.sensor_id
                    AND sr2.quality = 'good'
            )
    ) AS battery_data ON s.bin_id = battery_data.bin_id
    SET s.battery_level = battery_data.battery_level,
        s.updated_at = NOW();

    SET v_updated_count = ROW_COUNT();

    SELECT CONCAT('Battery levels updated for ', v_updated_count, ' sensors') AS result;
END//

-- ============================================================================
-- Procedure: Generate Route Optimization Suggestions
-- ============================================================================
DROP PROCEDURE IF EXISTS sp_generate_route_suggestions//

CREATE PROCEDURE sp_generate_route_suggestions(
    IN p_district_id INT,
    IN p_fill_threshold DECIMAL(5,2)
)
BEGIN
    -- Find bins that need collection soon
    WITH bins_needing_collection AS (
        SELECT
            b.bin_id,
            b.bin_code,
            b.latitude,
            b.longitude,
            cbs.current_fill_percentage,
            (cbs.current_fill_percentage / 100) * b.capacity_liters * 0.3 AS estimated_weight_kg
        FROM bins b
        INNER JOIN v_current_bin_status cbs ON b.bin_id = cbs.bin_id
        WHERE b.district_id = p_district_id
            AND b.status = 'active'
            AND cbs.current_fill_percentage >= p_fill_threshold
    )
    SELECT
        bnc1.bin_code AS bin1,
        bnc2.bin_code AS bin2,
        ROUND(ST_Distance_Sphere(
            POINT(bnc1.longitude, bnc1.latitude),
            POINT(bnc2.longitude, bnc2.latitude)
        ) / 1000, 2) AS distance_km,
        ROUND(bnc1.current_fill_percentage, 1) AS bin1_fill_pct,
        ROUND(bnc2.current_fill_percentage, 1) AS bin2_fill_pct,
        ROUND(bnc1.estimated_weight_kg + bnc2.estimated_weight_kg, 2) AS combined_weight_kg
    FROM bins_needing_collection bnc1
    CROSS JOIN bins_needing_collection bnc2
    WHERE bnc1.bin_id < bnc2.bin_id
        AND ST_Distance_Sphere(
            POINT(bnc1.longitude, bnc1.latitude),
            POINT(bnc2.longitude, bnc2.latitude)
        ) / 1000 < 1  -- Within 1 km
    ORDER BY distance_km ASC
    LIMIT 20;
END//

-- ============================================================================
-- Procedure: Process Real-time Alerts
-- ============================================================================
DROP PROCEDURE IF EXISTS sp_process_realtime_alerts//

CREATE PROCEDURE sp_process_realtime_alerts()
BEGIN
    DECLARE v_alert_count INT DEFAULT 0;
    DECLARE v_bin_id INT;
    DECLARE v_sensor_id INT;
    DECLARE v_threshold_id INT;
    DECLARE v_alert_type VARCHAR(50);
    DECLARE v_severity VARCHAR(20);
    DECLARE v_alert_value DECIMAL(10,3);
    DECLARE v_message TEXT;

    -- Check fill level alerts
    INSERT INTO alerts (
        bin_id,
        sensor_id,
        threshold_id,
        alert_type,
        severity,
        triggered_at,
        alert_value,
        message
    )
    SELECT
        b.bin_id,
        s.sensor_id,
        at.threshold_id,
        CASE
            WHEN sr.reading_value >= at.critical_value THEN 'fill_critical'
            ELSE 'fill_warning'
        END,
        CASE
            WHEN sr.reading_value >= at.critical_value THEN 'critical'
            ELSE 'warning'
        END,
        NOW(),
        sr.reading_value,
        CONCAT(
            'Bin ', b.bin_code, ' fill level at ',
            ROUND(sr.reading_value, 1), '%'
        )
    FROM sensor_readings sr
    INNER JOIN sensors s ON sr.sensor_id = s.sensor_id
    INNER JOIN bins b ON s.bin_id = b.bin_id
    INNER JOIN alert_thresholds at ON at.sensor_type = s.sensor_type
        AND (at.bin_type = 'all' OR at.bin_type = b.bin_type)
    WHERE s.sensor_type = 'fill_level'
        AND sr.reading_time >= DATE_SUB(NOW(), INTERVAL 5 MINUTE)
        AND sr.quality = 'good'
        AND sr.reading_value >= at.warning_value
        AND NOT EXISTS (
            -- Don't create duplicate alerts
            SELECT 1
            FROM alerts a
            WHERE a.bin_id = b.bin_id
                AND a.alert_type IN ('fill_critical', 'fill_warning')
                AND a.resolved_at IS NULL
        );

    SET v_alert_count = ROW_COUNT();

    SELECT CONCAT('Processed alerts. New alerts created: ', v_alert_count) AS result;
END//

-- ============================================================================
-- Procedure: Calculate Bin Fill Predictions
-- ============================================================================
DROP PROCEDURE IF EXISTS sp_calculate_fill_predictions//

CREATE PROCEDURE sp_calculate_fill_predictions(
    IN p_bin_id INT,
    IN p_hours_ahead INT
)
BEGIN
    DECLARE v_current_fill DECIMAL(10,3);
    DECLARE v_avg_hourly_rate DECIMAL(10,3);
    DECLARE v_predicted_fill DECIMAL(10,3);

    -- Get current fill level
    SELECT reading_value INTO v_current_fill
    FROM sensor_readings sr
    INNER JOIN sensors s ON sr.sensor_id = s.sensor_id
    WHERE s.bin_id = p_bin_id
        AND s.sensor_type = 'fill_level'
    ORDER BY sr.reading_time DESC
    LIMIT 1;

    -- Calculate average hourly fill rate from last 7 days
    SELECT
        AVG(hourly_change) INTO v_avg_hourly_rate
    FROM (
        SELECT
            (srh2.avg_value - srh1.avg_value) AS hourly_change
        FROM sensor_readings_hourly srh1
        INNER JOIN sensor_readings_hourly srh2
            ON srh1.sensor_id = srh2.sensor_id
            AND srh2.hour_start = DATE_ADD(srh1.hour_start, INTERVAL 1 HOUR)
        INNER JOIN sensors s ON srh1.sensor_id = s.sensor_id
        WHERE s.bin_id = p_bin_id
            AND s.sensor_type = 'fill_level'
            AND srh1.hour_start >= DATE_SUB(NOW(), INTERVAL 7 DAY)
    ) AS rates
    WHERE hourly_change > 0;  -- Only consider positive changes

    -- Calculate prediction
    SET v_predicted_fill = LEAST(100, v_current_fill + (v_avg_hourly_rate * p_hours_ahead));

    -- Return prediction
    SELECT
        p_bin_id AS bin_id,
        v_current_fill AS current_fill_pct,
        v_avg_hourly_rate AS avg_hourly_increase,
        p_hours_ahead AS hours_ahead,
        v_predicted_fill AS predicted_fill_pct,
        CASE
            WHEN v_predicted_fill >= 90 THEN 'Will need collection'
            WHEN v_predicted_fill >= 80 THEN 'Monitor closely'
            ELSE 'OK'
        END AS recommendation;
END//

DELIMITER ;

-- ============================================================================
-- Schedule Regular Aggregations (Example Events)
-- ============================================================================

-- Create event to run hourly aggregation every hour
-- Note: Events must be enabled in MySQL configuration
/*
CREATE EVENT IF NOT EXISTS event_hourly_aggregation
ON SCHEDULE EVERY 1 HOUR
STARTS CURRENT_TIMESTAMP
DO
    CALL sp_aggregate_hourly_data(
        DATE_SUB(NOW(), INTERVAL 2 HOUR),
        DATE_SUB(NOW(), INTERVAL 1 HOUR)
    );

CREATE EVENT IF NOT EXISTS event_daily_aggregation
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_DATE + INTERVAL 1 HOUR
DO
    CALL sp_aggregate_daily_data(
        DATE_SUB(CURDATE(), INTERVAL 1 DAY),
        DATE_SUB(CURDATE(), INTERVAL 1 DAY)
    );

CREATE EVENT IF NOT EXISTS event_process_alerts
ON SCHEDULE EVERY 5 MINUTE
STARTS CURRENT_TIMESTAMP
DO
    CALL sp_process_realtime_alerts();
*/

SELECT 'Aggregation procedures created successfully' AS Status;