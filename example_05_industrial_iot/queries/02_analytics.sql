-- ============================================================================
-- Industrial IoT Analytics Queries
-- ============================================================================

USE industrial_iot;

-- ============================================================================
-- OEE Analysis
-- ============================================================================

-- Daily OEE trend by production line (last 30 days)
SELECT
    DATE(om.metric_timestamp) AS date,
    pl.line_name,
    ROUND(AVG(om.availability_percentage), 1) AS avg_availability,
    ROUND(AVG(om.performance_percentage), 1) AS avg_performance,
    ROUND(AVG(om.quality_percentage), 1) AS avg_quality,
    ROUND(AVG(om.oee_percentage), 1) AS avg_oee,
    ROUND(MIN(om.oee_percentage), 1) AS min_oee,
    ROUND(MAX(om.oee_percentage), 1) AS max_oee,
    SUM(om.downtime_min) AS total_downtime_min,
    SUM(om.total_pieces_produced) AS total_production,
    ROUND((SUM(om.good_pieces) / NULLIF(SUM(om.total_pieces), 0)) * 100, 2) AS yield_rate
FROM oee_metrics om
INNER JOIN production_lines pl ON om.line_id = pl.line_id
WHERE om.metric_timestamp >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY DATE(om.metric_timestamp), pl.line_id
ORDER BY date DESC, pl.line_name;

-- OEE Pareto analysis - identify biggest losses
WITH oee_losses AS (
    SELECT
        m.machine_id,
        m.machine_code,
        m.machine_name,
        AVG(om.availability_percentage) AS avg_availability,
        AVG(om.performance_percentage) AS avg_performance,
        AVG(om.quality_percentage) AS avg_quality,
        AVG(om.oee_percentage) AS avg_oee,
        (100 - AVG(om.availability_percentage)) AS availability_loss,
        (100 - AVG(om.performance_percentage)) AS performance_loss,
        (100 - AVG(om.quality_percentage)) AS quality_loss
    FROM oee_metrics om
    INNER JOIN machines m ON om.machine_id = m.machine_id
    WHERE om.metric_timestamp >= DATE_SUB(NOW(), INTERVAL 7 DAY)
    GROUP BY m.machine_id
)
SELECT
    machine_code,
    machine_name,
    ROUND(avg_oee, 1) AS oee,
    ROUND(availability_loss, 1) AS availability_loss_pct,
    ROUND(performance_loss, 1) AS performance_loss_pct,
    ROUND(quality_loss, 1) AS quality_loss_pct,
    CASE
        WHEN availability_loss >= performance_loss AND availability_loss >= quality_loss THEN 'Availability'
        WHEN performance_loss >= quality_loss THEN 'Performance'
        ELSE 'Quality'
    END AS primary_loss_category,
    ROUND(GREATEST(availability_loss, performance_loss, quality_loss), 1) AS max_loss_pct
FROM oee_losses
ORDER BY avg_oee ASC
LIMIT 20;

-- ============================================================================
-- Production Performance Analysis
-- ============================================================================

-- Production efficiency by product
SELECT
    p.product_code,
    p.product_name,
    COUNT(DISTINCT wo.order_id) AS total_orders,
    SUM(wo.planned_quantity) AS total_planned,
    SUM(wo.produced_quantity) AS total_produced,
    SUM(wo.good_quantity) AS total_good,
    SUM(wo.rejected_quantity) AS total_rejected,
    ROUND((SUM(wo.good_quantity) / NULLIF(SUM(wo.produced_quantity), 0)) * 100, 2) AS first_pass_yield,
    ROUND((SUM(wo.produced_quantity) / NULLIF(SUM(wo.planned_quantity), 0)) * 100, 2) AS plan_achievement,
    AVG(TIMESTAMPDIFF(HOUR, wo.actual_start_time, wo.actual_end_time)) AS avg_production_hours
FROM work_orders wo
INNER JOIN products p ON wo.product_id = p.product_id
WHERE wo.status = 'completed'
    AND wo.actual_end_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY p.product_id
ORDER BY total_produced DESC;

-- Shift performance comparison
SELECT
    sl.shift_type,
    COUNT(DISTINCT sl.shift_date) AS days_worked,
    AVG(sl.production_actual) AS avg_production,
    AVG(sl.oee_actual) AS avg_oee,
    ROUND(AVG((sl.production_actual / NULLIF(sl.production_target, 0)) * 100), 1) AS avg_target_achievement,
    SUM(sl.safety_incidents) AS total_safety_incidents,
    AVG(sl.operators_count) AS avg_operator_count,
    ROUND(AVG(sl.production_actual / NULLIF(sl.operators_count, 0)), 1) AS avg_productivity_per_operator
FROM shift_logs sl
WHERE sl.shift_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY sl.shift_type
ORDER BY avg_oee DESC;

-- ============================================================================
-- Downtime Analysis
-- ============================================================================

-- Downtime by category (Pareto chart data)
SELECT
    de.reason_category,
    COUNT(*) AS event_count,
    ROUND(SUM(de.duration_minutes), 0) AS total_downtime_minutes,
    ROUND(AVG(de.duration_minutes), 1) AS avg_downtime_minutes,
    ROUND(SUM(de.duration_minutes) / 60, 1) AS total_downtime_hours,
    SUM(de.lost_production_units) AS total_lost_units,
    ROUND(
        (SUM(de.duration_minutes) / (
            SELECT SUM(duration_minutes)
            FROM downtime_events
            WHERE start_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
        )) * 100,
        1
    ) AS percentage_of_total_downtime
FROM downtime_events de
WHERE de.start_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY de.reason_category
ORDER BY total_downtime_minutes DESC;

-- MTBF (Mean Time Between Failures) and MTTR (Mean Time To Repair) by machine
WITH failure_analysis AS (
    SELECT
        m.machine_id,
        m.machine_code,
        m.machine_name,
        COUNT(de.event_id) AS failure_count,
        SUM(de.duration_minutes) AS total_repair_time_min,
        MIN(de.start_time) AS first_failure,
        MAX(de.start_time) AS last_failure,
        TIMESTAMPDIFF(HOUR, MIN(de.start_time), MAX(de.start_time)) AS operating_hours
    FROM machines m
    LEFT JOIN downtime_events de ON m.machine_id = de.machine_id
        AND de.reason_category IN ('equipment_failure', 'unplanned_maintenance')
        AND de.start_time >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
    GROUP BY m.machine_id
    HAVING failure_count > 0
)
SELECT
    machine_code,
    machine_name,
    failure_count,
    ROUND(operating_hours / NULLIF(failure_count - 1, 0), 1) AS mtbf_hours,
    ROUND(total_repair_time_min / NULLIF(failure_count, 0), 1) AS mttr_minutes,
    ROUND(total_repair_time_min / 60, 1) AS total_downtime_hours
FROM failure_analysis
ORDER BY mtbf_hours ASC;

-- ============================================================================
-- Quality Analysis
-- ============================================================================

-- Quality trends by product
SELECT
    p.product_code,
    p.product_name,
    DATE(qi.inspection_time) AS inspection_date,
    COUNT(*) AS inspections,
    SUM(qi.sample_size) AS total_samples,
    SUM(qi.defects_found) AS total_defects,
    ROUND((SUM(qi.defects_found) / NULLIF(SUM(qi.sample_size), 0)) * 1000000, 0) AS dppm,
    ROUND((SUM(CASE WHEN qi.pass_fail = 'pass' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 1) AS pass_rate
FROM quality_inspections qi
INNER JOIN products p ON qi.product_id = p.product_id
WHERE qi.inspection_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY p.product_id, DATE(qi.inspection_time)
ORDER BY inspection_date DESC, dppm DESC;

-- Top defect types
SELECT
    d.defect_type,
    d.severity,
    COUNT(*) AS defect_count,
    SUM(d.quantity) AS total_quantity,
    COUNT(DISTINCT qi.product_id) AS products_affected,
    COUNT(DISTINCT pr.machine_id) AS machines_involved,
    GROUP_CONCAT(DISTINCT d.root_cause ORDER BY d.root_cause SEPARATOR '; ') AS root_causes
FROM defects d
INNER JOIN quality_inspections qi ON d.inspection_id = qi.inspection_id
INNER JOIN production_runs pr ON qi.run_id = pr.run_id
WHERE qi.inspection_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY d.defect_type, d.severity
ORDER BY
    FIELD(d.severity, 'critical', 'major', 'minor', 'cosmetic'),
    defect_count DESC;

-- ============================================================================
-- Maintenance Effectiveness
-- ============================================================================

-- Maintenance compliance rate
SELECT
    ms.maintenance_type,
    COUNT(*) AS scheduled_count,
    SUM(CASE WHEN ms.next_due < CURDATE() THEN 1 ELSE 0 END) AS overdue_count,
    SUM(CASE WHEN mr.status = 'completed' THEN 1 ELSE 0 END) AS completed_count,
    ROUND((SUM(CASE WHEN mr.status = 'completed' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 1) AS compliance_rate,
    AVG(DATEDIFF(ms.next_due, ms.last_performed)) AS avg_interval_days
FROM maintenance_schedules ms
LEFT JOIN maintenance_records mr ON ms.schedule_id = mr.schedule_id
    AND mr.start_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
WHERE ms.is_active = TRUE
GROUP BY ms.maintenance_type
ORDER BY compliance_rate ASC;

-- Maintenance cost analysis
SELECT
    m.machine_type,
    COUNT(DISTINCT mr.machine_id) AS machines_maintained,
    COUNT(mr.record_id) AS maintenance_events,
    SUM(mr.downtime_minutes) AS total_downtime_min,
    SUM(mr.cost) AS total_cost,
    AVG(mr.cost) AS avg_cost_per_event,
    SUM(mr.cost) / COUNT(DISTINCT mr.machine_id) AS avg_cost_per_machine
FROM maintenance_records mr
INNER JOIN machines m ON mr.machine_id = m.machine_id
WHERE mr.status = 'completed'
    AND mr.end_time >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
GROUP BY m.machine_type
ORDER BY total_cost DESC;

-- ============================================================================
-- Predictive Analytics
-- ============================================================================

-- Sensor trend analysis for predictive maintenance
WITH sensor_trends AS (
    SELECT
        s.sensor_id,
        s.sensor_type,
        s.machine_id,
        DATE(sr.timestamp) AS reading_date,
        AVG(sr.value) AS avg_value,
        STDDEV(sr.value) AS stddev_value,
        MIN(sr.value) AS min_value,
        MAX(sr.value) AS max_value,
        COUNT(*) AS reading_count
    FROM sensors s
    INNER JOIN sensor_readings sr ON s.sensor_id = sr.sensor_id
    WHERE sr.timestamp >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
        AND s.sensor_type IN ('vibration', 'temperature', 'pressure')
    GROUP BY s.sensor_id, DATE(sr.timestamp)
),
trend_calculation AS (
    SELECT
        sensor_id,
        sensor_type,
        machine_id,
        AVG(avg_value) AS overall_avg,
        STDDEV(avg_value) AS overall_stddev,
        -- Calculate trend using linear regression approximation
        (COUNT(*) * SUM(UNIX_TIMESTAMP(reading_date) * avg_value) - SUM(UNIX_TIMESTAMP(reading_date)) * SUM(avg_value)) /
        (COUNT(*) * SUM(UNIX_TIMESTAMP(reading_date) * UNIX_TIMESTAMP(reading_date)) - SUM(UNIX_TIMESTAMP(reading_date)) * SUM(UNIX_TIMESTAMP(reading_date))) AS trend_slope
    FROM sensor_trends
    GROUP BY sensor_id
)
SELECT
    m.machine_code,
    m.machine_name,
    tc.sensor_type,
    ROUND(tc.overall_avg, 2) AS avg_value,
    ROUND(tc.overall_stddev, 2) AS stddev_value,
    CASE
        WHEN tc.trend_slope > 0.001 THEN 'INCREASING'
        WHEN tc.trend_slope < -0.001 THEN 'DECREASING'
        ELSE 'STABLE'
    END AS trend_direction,
    ROUND(tc.trend_slope * 86400, 4) AS daily_change_rate,
    s.critical_max,
    CASE
        WHEN tc.overall_avg > s.normal_max * 0.9 THEN 'HIGH RISK'
        WHEN tc.overall_avg > s.normal_max * 0.8 THEN 'MEDIUM RISK'
        ELSE 'LOW RISK'
    END AS risk_level
FROM trend_calculation tc
INNER JOIN sensors s ON tc.sensor_id = s.sensor_id
INNER JOIN machines m ON tc.machine_id = m.machine_id
WHERE ABS(tc.trend_slope) > 0.0001  -- Only show significant trends
ORDER BY risk_level DESC, ABS(tc.trend_slope) DESC;