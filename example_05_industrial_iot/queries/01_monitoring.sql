-- ============================================================================
-- Industrial IoT Real-time Monitoring Queries
-- ============================================================================

USE industrial_iot;

-- ============================================================================
-- Production Line Status Dashboard
-- ============================================================================

-- Current production line status with running orders
SELECT
    pl.line_id,
    pl.line_name,
    pl.line_type,
    f.factory_name,
    pl.status AS line_status,
    COUNT(DISTINCT m.machine_id) AS total_machines,
    SUM(CASE WHEN m.status = 'running' THEN 1 ELSE 0 END) AS running_machines,
    SUM(CASE WHEN m.status = 'error' THEN 1 ELSE 0 END) AS error_machines,
    wo.order_number AS current_order,
    p.product_name AS current_product,
    wo.produced_quantity,
    wo.planned_quantity,
    ROUND((wo.produced_quantity / wo.planned_quantity) * 100, 1) AS completion_percentage
FROM production_lines pl
INNER JOIN factories f ON pl.factory_id = f.factory_id
LEFT JOIN machines m ON pl.line_id = m.line_id
LEFT JOIN work_orders wo ON pl.line_id = wo.line_id
    AND wo.status = 'in_progress'
LEFT JOIN products p ON wo.product_id = p.product_id
WHERE f.is_active = TRUE
GROUP BY pl.line_id, wo.order_id
ORDER BY f.factory_name, pl.line_name;

-- ============================================================================
-- Real-time Machine Status
-- ============================================================================

-- Current machine status with sensor readings
WITH latest_readings AS (
    SELECT
        s.machine_id,
        s.sensor_type,
        sr.value,
        sr.timestamp,
        ROW_NUMBER() OVER (PARTITION BY s.sensor_id ORDER BY sr.timestamp DESC) AS rn
    FROM sensors s
    INNER JOIN sensor_readings sr ON s.sensor_id = sr.sensor_id
    WHERE sr.timestamp > NOW() - INTERVAL 5 MINUTE
        AND s.is_active = TRUE
)
SELECT
    m.machine_id,
    m.machine_code,
    m.machine_name,
    m.machine_type,
    m.status,
    pl.line_name,
    ROUND(m.total_operating_hours, 1) AS total_hours,
    m.total_cycle_count,
    MAX(CASE WHEN lr.sensor_type = 'temperature' THEN lr.value END) AS temperature,
    MAX(CASE WHEN lr.sensor_type = 'vibration' THEN lr.value END) AS vibration,
    MAX(CASE WHEN lr.sensor_type = 'pressure' THEN lr.value END) AS pressure,
    MAX(CASE WHEN lr.sensor_type = 'current' THEN lr.value END) AS current_amps
FROM machines m
INNER JOIN production_lines pl ON m.line_id = pl.line_id
LEFT JOIN latest_readings lr ON m.machine_id = lr.machine_id AND lr.rn = 1
WHERE m.status != 'offline'
GROUP BY m.machine_id
ORDER BY pl.line_name, m.machine_name;

-- ============================================================================
-- Active Alerts Monitoring
-- ============================================================================

-- Unresolved alerts by severity
SELECT
    a.alert_id,
    a.severity,
    a.alert_type,
    a.message,
    a.triggered_at,
    TIMESTAMPDIFF(MINUTE, a.triggered_at, NOW()) AS minutes_active,
    CASE a.source_type
        WHEN 'sensor' THEN CONCAT('Sensor: ', s.sensor_code)
        WHEN 'machine' THEN CONCAT('Machine: ', m.machine_code)
        WHEN 'line' THEN CONCAT('Line: ', pl.line_name)
        ELSE a.source_type
    END AS source_name,
    a.actual_value,
    a.threshold_value
FROM alerts a
LEFT JOIN sensors s ON a.source_type = 'sensor' AND a.source_id = s.sensor_id
LEFT JOIN machines m ON a.source_type = 'machine' AND a.source_id = m.machine_id
LEFT JOIN production_lines pl ON a.source_type = 'line' AND a.source_id = pl.line_id
WHERE a.resolved_at IS NULL
ORDER BY
    FIELD(a.severity, 'critical', 'high', 'medium', 'low', 'info'),
    a.triggered_at DESC
LIMIT 50;

-- ============================================================================
-- Current Shift Performance
-- ============================================================================

-- Today's shift performance summary
SELECT
    sl.shift_type,
    sl.line_id,
    pl.line_name,
    sl.production_target,
    sl.production_actual,
    ROUND((sl.production_actual / sl.production_target) * 100, 1) AS achievement_rate,
    sl.oee_target,
    sl.oee_actual,
    sl.oee_actual - sl.oee_target AS oee_variance,
    sl.operators_count,
    sl.safety_incidents,
    o.first_name AS supervisor_first_name,
    o.last_name AS supervisor_last_name
FROM shift_logs sl
INNER JOIN production_lines pl ON sl.line_id = pl.line_id
LEFT JOIN operators o ON sl.supervisor_id = o.operator_id
WHERE sl.shift_date = CURDATE()
ORDER BY sl.shift_type, pl.line_name;

-- ============================================================================
-- Real-time OEE Monitoring
-- ============================================================================

-- Current hour OEE by machine
SELECT
    m.machine_id,
    m.machine_code,
    m.machine_name,
    pl.line_name,
    om.hour_start,
    ROUND(om.availability_percentage, 1) AS availability,
    ROUND(om.performance_percentage, 1) AS performance,
    ROUND(om.quality_percentage, 1) AS quality,
    ROUND(om.oee_percentage, 1) AS oee,
    om.downtime_min,
    om.total_pieces_produced,
    om.good_pieces,
    CASE
        WHEN om.oee_percentage >= 85 THEN 'World Class'
        WHEN om.oee_percentage >= 60 THEN 'Typical'
        WHEN om.oee_percentage >= 40 THEN 'Low'
        ELSE 'Poor'
    END AS oee_rating
FROM oee_metrics om
INNER JOIN machines m ON om.machine_id = m.machine_id
INNER JOIN production_lines pl ON m.line_id = pl.line_id
WHERE om.hour_start >= NOW() - INTERVAL 1 HOUR
ORDER BY om.oee_percentage ASC, pl.line_name, m.machine_name;

-- ============================================================================
-- Active Downtime Events
-- ============================================================================

-- Currently down machines
SELECT
    de.event_id,
    m.machine_code,
    m.machine_name,
    pl.line_name,
    de.start_time,
    TIMESTAMPDIFF(MINUTE, de.start_time, NOW()) AS minutes_down,
    de.reason_category,
    de.reason_detail,
    de.impact_level,
    COALESCE(de.lost_production_units, 0) AS lost_units
FROM downtime_events de
INNER JOIN machines m ON de.machine_id = m.machine_id
INNER JOIN production_lines pl ON m.line_id = pl.line_id
WHERE de.end_time IS NULL
ORDER BY de.start_time;

-- ============================================================================
-- Sensor Anomaly Detection
-- ============================================================================

-- Sensors reading outside normal range
SELECT
    s.sensor_id,
    s.sensor_code,
    s.sensor_type,
    m.machine_code,
    m.machine_name,
    sr.value AS current_value,
    s.normal_min,
    s.normal_max,
    CASE
        WHEN sr.value < s.critical_min OR sr.value > s.critical_max THEN 'CRITICAL'
        WHEN sr.value < s.normal_min OR sr.value > s.normal_max THEN 'WARNING'
        ELSE 'NORMAL'
    END AS status,
    sr.timestamp
FROM sensors s
INNER JOIN (
    SELECT sensor_id, value, timestamp,
           ROW_NUMBER() OVER (PARTITION BY sensor_id ORDER BY timestamp DESC) AS rn
    FROM sensor_readings
    WHERE timestamp > NOW() - INTERVAL 10 MINUTE
) sr ON s.sensor_id = sr.sensor_id AND sr.rn = 1
INNER JOIN machines m ON s.machine_id = m.machine_id
WHERE s.is_active = TRUE
    AND (sr.value < s.normal_min OR sr.value > s.normal_max)
ORDER BY
    CASE
        WHEN sr.value < s.critical_min OR sr.value > s.critical_max THEN 1
        ELSE 2
    END,
    sr.timestamp DESC;

-- ============================================================================
-- Production Progress Monitoring
-- ============================================================================

-- Active work orders progress
SELECT
    wo.order_id,
    wo.order_number,
    p.product_code,
    p.product_name,
    pl.line_name,
    wo.planned_quantity,
    wo.produced_quantity,
    wo.good_quantity,
    wo.rejected_quantity,
    ROUND((wo.good_quantity / wo.planned_quantity) * 100, 1) AS yield_percentage,
    wo.planned_start_time,
    wo.planned_end_time,
    CASE
        WHEN NOW() > wo.planned_end_time THEN 'OVERDUE'
        WHEN wo.produced_quantity >= wo.planned_quantity THEN 'COMPLETE'
        ELSE 'ON TRACK'
    END AS schedule_status,
    ROUND(
        (TIMESTAMPDIFF(MINUTE, wo.actual_start_time, NOW()) /
         TIMESTAMPDIFF(MINUTE, wo.planned_start_time, wo.planned_end_time)) * 100,
        1
    ) AS time_progress_percentage
FROM work_orders wo
INNER JOIN products p ON wo.product_id = p.product_id
INNER JOIN production_lines pl ON wo.line_id = pl.line_id
WHERE wo.status IN ('in_progress', 'planned')
    AND wo.planned_start_time <= NOW()
ORDER BY wo.priority, wo.planned_end_time;

-- ============================================================================
-- Quality Monitoring
-- ============================================================================

-- Recent quality inspection results
SELECT
    qi.inspection_id,
    p.product_code,
    p.product_name,
    qi.inspection_time,
    qi.sample_size,
    qi.defects_found,
    ROUND((qi.defects_found / qi.sample_size) * 1000000, 2) AS dppm,  -- Defects per million
    qi.pass_fail,
    o.first_name AS inspector_first_name,
    o.last_name AS inspector_last_name,
    m.machine_code,
    pl.line_name
FROM quality_inspections qi
INNER JOIN products p ON qi.product_id = p.product_id
INNER JOIN production_runs pr ON qi.run_id = pr.run_id
INNER JOIN machines m ON pr.machine_id = m.machine_id
INNER JOIN production_lines pl ON m.line_id = pl.line_id
LEFT JOIN operators o ON qi.inspector_id = o.operator_id
WHERE qi.inspection_time >= NOW() - INTERVAL 4 HOUR
ORDER BY qi.inspection_time DESC
LIMIT 20;