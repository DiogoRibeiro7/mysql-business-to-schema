-- ============================================================================
-- IoT Garbage Bin Monitoring System - Analytics Queries
-- ============================================================================
-- Description: Time series analysis and trend detection queries
-- ============================================================================

USE iot_bins;

-- ============================================================================
-- 1. Average Fill Rates by District and Bin Type
-- ============================================================================
SELECT
    d.name AS district,
    b.bin_type,
    COUNT(DISTINCT b.bin_id) AS bin_count,
    ROUND(AVG(srd.avg_value), 2) AS avg_fill_rate,
    ROUND(MIN(srd.min_value), 2) AS min_fill_rate,
    ROUND(MAX(srd.max_value), 2) AS max_fill_rate,
    ROUND(STD(srd.avg_value), 2) AS std_dev_fill_rate
FROM sensor_readings_daily srd
INNER JOIN sensors s ON srd.sensor_id = s.sensor_id
INNER JOIN bins b ON s.bin_id = b.bin_id
INNER JOIN districts d ON b.district_id = d.district_id
WHERE s.sensor_type = 'fill_level'
    AND srd.date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY d.district_id, b.bin_type
ORDER BY d.name, avg_fill_rate DESC;

-- ============================================================================
-- 2. Peak Usage Hours Analysis
-- ============================================================================
SELECT
    HOUR(sr.reading_time) AS hour_of_day,
    DAYNAME(sr.reading_time) AS day_of_week,
    b.location_type,
    COUNT(*) AS reading_count,
    ROUND(AVG(sr.reading_value), 2) AS avg_fill_level,
    ROUND(MAX(sr.reading_value), 2) AS max_fill_level
FROM sensor_readings sr
INNER JOIN sensors s ON sr.sensor_id = s.sensor_id
INNER JOIN bins b ON s.bin_id = b.bin_id
WHERE s.sensor_type = 'fill_level'
    AND sr.reading_time >= DATE_SUB(NOW(), INTERVAL 7 DAY)
    AND sr.quality = 'good'
GROUP BY HOUR(sr.reading_time), DAYNAME(sr.reading_time), b.location_type
ORDER BY day_of_week, hour_of_day;

-- ============================================================================
-- 3. Weekly Fill Pattern by Location Type
-- ============================================================================
SELECT
    b.location_type,
    DAYNAME(srd.date) AS day_of_week,
    DAYOFWEEK(srd.date) AS day_number,
    COUNT(DISTINCT b.bin_id) AS bin_count,
    ROUND(AVG(srd.avg_value), 2) AS avg_daily_fill,
    ROUND(AVG(srd.peak_value), 2) AS avg_peak_fill,
    TIME_FORMAT(SEC_TO_TIME(AVG(TIME_TO_SEC(srd.peak_hour))), '%H:%i') AS avg_peak_hour
FROM sensor_readings_daily srd
INNER JOIN sensors s ON srd.sensor_id = s.sensor_id
INNER JOIN bins b ON s.bin_id = b.bin_id
WHERE s.sensor_type = 'fill_level'
    AND srd.date >= DATE_SUB(CURDATE(), INTERVAL 4 WEEK)
GROUP BY b.location_type, DAYOFWEEK(srd.date)
ORDER BY b.location_type, day_number;

-- ============================================================================
-- 4. Monthly Trend Analysis
-- ============================================================================
SELECT
    DATE_FORMAT(srd.date, '%Y-%m') AS month,
    d.name AS district,
    COUNT(DISTINCT b.bin_id) AS active_bins,
    ROUND(AVG(srd.avg_value), 2) AS avg_fill_rate,
    ROUND(SUM(ce.weight_kg) / 1000, 2) AS total_waste_tons,
    COUNT(DISTINCT ce.event_id) AS collection_count,
    ROUND(AVG(ce.fill_level_before), 2) AS avg_fill_on_collection
FROM sensor_readings_daily srd
INNER JOIN sensors s ON srd.sensor_id = s.sensor_id
INNER JOIN bins b ON s.bin_id = b.bin_id
INNER JOIN districts d ON b.district_id = d.district_id
LEFT JOIN collection_events ce ON b.bin_id = ce.bin_id
    AND DATE(ce.collected_at) = srd.date
WHERE s.sensor_type = 'fill_level'
GROUP BY DATE_FORMAT(srd.date, '%Y-%m'), d.district_id
ORDER BY month DESC, district;

-- ============================================================================
-- 5. Sensor Quality Analysis
-- ============================================================================
SELECT
    s.sensor_type,
    DATE(sr.reading_time) AS date,
    COUNT(*) AS total_readings,
    SUM(CASE WHEN sr.quality = 'good' THEN 1 ELSE 0 END) AS good_readings,
    SUM(CASE WHEN sr.quality = 'warning' THEN 1 ELSE 0 END) AS warning_readings,
    SUM(CASE WHEN sr.quality = 'error' THEN 1 ELSE 0 END) AS error_readings,
    ROUND(
        SUM(CASE WHEN sr.quality = 'good' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS quality_percentage
FROM sensor_readings sr
INNER JOIN sensors s ON sr.sensor_id = s.sensor_id
WHERE sr.reading_time >= DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY s.sensor_type, DATE(sr.reading_time)
ORDER BY date DESC, sensor_type;

-- ============================================================================
-- 6. Anomaly Detection - Unusual Fill Rates
-- ============================================================================
WITH fill_statistics AS (
    SELECT
        b.bin_id,
        b.bin_code,
        b.location_type,
        AVG(srd.avg_value) AS mean_fill,
        STD(srd.avg_value) AS std_fill
    FROM sensor_readings_daily srd
    INNER JOIN sensors s ON srd.sensor_id = s.sensor_id
    INNER JOIN bins b ON s.bin_id = b.bin_id
    WHERE s.sensor_type = 'fill_level'
        AND srd.date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY b.bin_id
),
recent_readings AS (
    SELECT
        b.bin_id,
        AVG(sr.reading_value) AS recent_avg
    FROM sensor_readings sr
    INNER JOIN sensors s ON sr.sensor_id = s.sensor_id
    INNER JOIN bins b ON s.bin_id = b.bin_id
    WHERE s.sensor_type = 'fill_level'
        AND sr.reading_time >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
        AND sr.quality = 'good'
    GROUP BY b.bin_id
)
SELECT
    fs.bin_code,
    fs.location_type,
    ROUND(fs.mean_fill, 2) AS historical_avg,
    ROUND(rr.recent_avg, 2) AS last_24h_avg,
    ROUND(rr.recent_avg - fs.mean_fill, 2) AS deviation,
    ROUND((rr.recent_avg - fs.mean_fill) / NULLIF(fs.std_fill, 0), 2) AS z_score,
    CASE
        WHEN ABS((rr.recent_avg - fs.mean_fill) / NULLIF(fs.std_fill, 0)) > 3 THEN 'ANOMALY'
        WHEN ABS((rr.recent_avg - fs.mean_fill) / NULLIF(fs.std_fill, 0)) > 2 THEN 'WARNING'
        ELSE 'NORMAL'
    END AS status
FROM fill_statistics fs
INNER JOIN recent_readings rr ON fs.bin_id = rr.bin_id
WHERE ABS((rr.recent_avg - fs.mean_fill) / NULLIF(fs.std_fill, 0)) > 2
ORDER BY ABS((rr.recent_avg - fs.mean_fill) / NULLIF(fs.std_fill, 0)) DESC
LIMIT 20;

-- ============================================================================
-- 7. Temperature vs Fill Rate Correlation
-- ============================================================================
SELECT
    DATE(sr_fill.reading_time) AS date,
    b.location_type,
    ROUND(AVG(sr_fill.reading_value), 2) AS avg_fill_level,
    ROUND(AVG(sr_temp.reading_value), 2) AS avg_temperature,
    COUNT(DISTINCT b.bin_id) AS bin_count,
    ROUND(
        (COUNT(*) * SUM(sr_fill.reading_value * sr_temp.reading_value) -
         SUM(sr_fill.reading_value) * SUM(sr_temp.reading_value)) /
        SQRT(
            (COUNT(*) * SUM(POW(sr_fill.reading_value, 2)) - POW(SUM(sr_fill.reading_value), 2)) *
            (COUNT(*) * SUM(POW(sr_temp.reading_value, 2)) - POW(SUM(sr_temp.reading_value), 2))
        ), 3
    ) AS correlation_coefficient
FROM sensor_readings sr_fill
INNER JOIN sensors s_fill ON sr_fill.sensor_id = s_fill.sensor_id
INNER JOIN bins b ON s_fill.bin_id = b.bin_id
INNER JOIN sensors s_temp ON b.bin_id = s_temp.bin_id AND s_temp.sensor_type = 'temperature'
INNER JOIN sensor_readings sr_temp ON s_temp.sensor_id = sr_temp.sensor_id
    AND DATE(sr_temp.reading_time) = DATE(sr_fill.reading_time)
    AND HOUR(sr_temp.reading_time) = HOUR(sr_fill.reading_time)
WHERE s_fill.sensor_type = 'fill_level'
    AND sr_fill.quality = 'good'
    AND sr_temp.quality = 'good'
    AND sr_fill.reading_time >= DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY DATE(sr_fill.reading_time), b.location_type
HAVING bin_count > 5
ORDER BY date DESC, location_type;

-- ============================================================================
-- 8. Collection Efficiency Trends
-- ============================================================================
SELECT
    DATE_FORMAT(ce.collected_at, '%Y-%m-%d') AS collection_date,
    d.name AS district,
    COUNT(DISTINCT ce.bin_id) AS bins_collected,
    ROUND(AVG(ce.fill_level_before), 2) AS avg_fill_level,
    ROUND(SUM(ce.weight_kg), 2) AS total_weight_kg,
    ROUND(AVG(ce.collection_duration_seconds) / 60, 2) AS avg_duration_minutes,
    COUNT(DISTINCT ce.truck_id) AS trucks_used,
    COUNT(DISTINCT ce.driver_id) AS drivers_involved
FROM collection_events ce
INNER JOIN bins b ON ce.bin_id = b.bin_id
INNER JOIN districts d ON b.district_id = d.district_id
WHERE ce.collected_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY DATE(ce.collected_at), d.district_id
ORDER BY collection_date DESC, district;

-- ============================================================================
-- 9. Bin Fill Rate Acceleration
-- ============================================================================
SELECT
    vfra.bin_code,
    d.name AS district,
    b.location_type,
    b.bin_type,
    ROUND(vfra.previous_week_avg, 2) AS prev_week_avg_fill,
    ROUND(vfra.current_week_avg, 2) AS curr_week_avg_fill,
    ROUND(vfra.fill_rate_change, 2) AS weekly_change,
    CASE
        WHEN vfra.fill_rate_change > 10 THEN 'INCREASING_RAPIDLY'
        WHEN vfra.fill_rate_change > 5 THEN 'INCREASING'
        WHEN vfra.fill_rate_change < -5 THEN 'DECREASING'
        ELSE 'STABLE'
    END AS trend
FROM v_fill_rate_acceleration vfra
INNER JOIN bins b ON vfra.bin_id = b.bin_id
INNER JOIN districts d ON b.district_id = d.district_id
WHERE ABS(vfra.fill_rate_change) > 5
ORDER BY vfra.fill_rate_change DESC
LIMIT 25;

-- ============================================================================
-- 10. Hourly Pattern Heatmap Data
-- ============================================================================
SELECT
    HOUR(srh.hour_start) AS hour,
    DAYNAME(srh.hour_start) AS day_of_week,
    ROUND(AVG(srh.avg_value), 2) AS avg_fill_level,
    COUNT(DISTINCT s.bin_id) AS bin_count,
    ROUND(MIN(srh.min_value), 2) AS min_fill,
    ROUND(MAX(srh.max_value), 2) AS max_fill
FROM sensor_readings_hourly srh
INNER JOIN sensors s ON srh.sensor_id = s.sensor_id
WHERE s.sensor_type = 'fill_level'
    AND srh.hour_start >= DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY HOUR(srh.hour_start), DAYOFWEEK(srh.hour_start), DAYNAME(srh.hour_start)
ORDER BY
    FIELD(DAYNAME(srh.hour_start), 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
    hour;