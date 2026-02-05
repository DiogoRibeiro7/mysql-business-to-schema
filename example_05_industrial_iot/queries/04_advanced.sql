-- ============================================================================
-- Industrial IoT Advanced Queries
-- ============================================================================

USE industrial_iot;

-- ============================================================================
-- Predictive Maintenance Models
-- ============================================================================

-- Machine failure prediction based on sensor patterns
WITH sensor_statistics AS (
    SELECT
        s.machine_id,
        s.sensor_type,
        DATE(sr.timestamp) AS reading_date,
        AVG(sr.value) AS daily_avg,
        STDDEV(sr.value) AS daily_stddev,
        MAX(sr.value) AS daily_max,
        MIN(sr.value) AS daily_min,
        COUNT(*) AS reading_count
    FROM sensors s
    INNER JOIN sensor_readings sr ON s.sensor_id = sr.sensor_id
    WHERE sr.timestamp >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
        AND s.sensor_type IN ('vibration', 'temperature', 'current')
    GROUP BY s.machine_id, s.sensor_type, DATE(sr.timestamp)
),
anomaly_detection AS (
    SELECT
        machine_id,
        sensor_type,
        reading_date,
        daily_avg,
        AVG(daily_avg) OVER (
            PARTITION BY machine_id, sensor_type
            ORDER BY reading_date
            ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING
        ) AS baseline_avg,
        STDDEV(daily_avg) OVER (
            PARTITION BY machine_id, sensor_type
            ORDER BY reading_date
            ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING
        ) AS baseline_stddev,
        daily_max
    FROM sensor_statistics
),
risk_scoring AS (
    SELECT
        ad.machine_id,
        ad.sensor_type,
        ad.reading_date,
        ad.daily_avg,
        ad.baseline_avg,
        ad.baseline_stddev,
        ABS((ad.daily_avg - ad.baseline_avg) / NULLIF(ad.baseline_stddev, 0)) AS z_score,
        CASE
            WHEN ABS((ad.daily_avg - ad.baseline_avg) / NULLIF(ad.baseline_stddev, 0)) > 3 THEN 3
            WHEN ABS((ad.daily_avg - ad.baseline_avg) / NULLIF(ad.baseline_stddev, 0)) > 2 THEN 2
            WHEN ABS((ad.daily_avg - ad.baseline_avg) / NULLIF(ad.baseline_stddev, 0)) > 1 THEN 1
            ELSE 0
        END AS anomaly_score,
        de.recent_failures
    FROM anomaly_detection ad
    LEFT JOIN (
        SELECT
            machine_id,
            COUNT(*) AS recent_failures
        FROM downtime_events
        WHERE reason_category = 'equipment_failure'
            AND start_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
        GROUP BY machine_id
    ) de ON ad.machine_id = de.machine_id
    WHERE ad.reading_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
)
SELECT
    m.machine_code,
    m.machine_name,
    m.machine_type,
    pl.line_name,
    MAX(CASE WHEN rs.sensor_type = 'vibration' THEN rs.anomaly_score ELSE 0 END) AS vibration_risk,
    MAX(CASE WHEN rs.sensor_type = 'temperature' THEN rs.anomaly_score ELSE 0 END) AS temperature_risk,
    MAX(CASE WHEN rs.sensor_type = 'current' THEN rs.anomaly_score ELSE 0 END) AS current_risk,
    MAX(rs.anomaly_score) AS max_risk_score,
    COALESCE(rs.recent_failures, 0) AS recent_failures,
    DATEDIFF(CURDATE(), ms.last_performed) AS days_since_maintenance,
    CASE
        WHEN MAX(rs.anomaly_score) = 3 OR COALESCE(rs.recent_failures, 0) > 2 THEN 'CRITICAL - Immediate maintenance required'
        WHEN MAX(rs.anomaly_score) = 2 OR COALESCE(rs.recent_failures, 0) > 1 THEN 'HIGH - Schedule maintenance soon'
        WHEN MAX(rs.anomaly_score) = 1 THEN 'MEDIUM - Monitor closely'
        ELSE 'LOW - Normal operation'
    END AS maintenance_recommendation
FROM risk_scoring rs
INNER JOIN machines m ON rs.machine_id = m.machine_id
INNER JOIN production_lines pl ON m.line_id = pl.line_id
LEFT JOIN maintenance_schedules ms ON m.machine_id = ms.machine_id
    AND ms.maintenance_type = 'preventive'
    AND ms.is_active = TRUE
GROUP BY m.machine_id
HAVING MAX(rs.anomaly_score) > 0
ORDER BY max_risk_score DESC, recent_failures DESC;

-- ============================================================================
-- Production Optimization Analysis
-- ============================================================================

-- Identify production bottlenecks using Theory of Constraints
WITH machine_throughput AS (
    SELECT
        pr.machine_id,
        m.machine_name,
        m.line_id,
        DATE(pr.start_time) AS production_date,
        COUNT(DISTINCT pr.run_id) AS runs,
        SUM(pr.quantity_produced) AS daily_output,
        SUM(TIMESTAMPDIFF(MINUTE, pr.start_time, pr.end_time)) AS operating_minutes,
        SUM(pr.quantity_produced) / NULLIF(SUM(TIMESTAMPDIFF(MINUTE, pr.start_time, pr.end_time)), 0) * 60 AS hourly_rate
    FROM production_runs pr
    INNER JOIN machines m ON pr.machine_id = m.machine_id
    WHERE pr.start_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
        AND pr.end_time IS NOT NULL
    GROUP BY pr.machine_id, DATE(pr.start_time)
),
line_analysis AS (
    SELECT
        line_id,
        machine_id,
        machine_name,
        AVG(hourly_rate) AS avg_hourly_rate,
        MIN(hourly_rate) AS min_hourly_rate,
        MAX(hourly_rate) AS max_hourly_rate,
        STDDEV(hourly_rate) AS rate_variability,
        AVG(daily_output) AS avg_daily_output
    FROM machine_throughput
    GROUP BY line_id, machine_id
),
bottleneck_identification AS (
    SELECT
        line_id,
        machine_id,
        machine_name,
        avg_hourly_rate,
        rate_variability,
        avg_daily_output,
        MIN(avg_hourly_rate) OVER (PARTITION BY line_id) AS line_min_rate,
        RANK() OVER (PARTITION BY line_id ORDER BY avg_hourly_rate) AS bottleneck_rank
    FROM line_analysis
)
SELECT
    pl.line_name,
    bi.machine_name AS bottleneck_machine,
    ROUND(bi.avg_hourly_rate, 1) AS bottleneck_rate,
    ROUND(bi.rate_variability, 2) AS rate_variability,
    ROUND((bi.avg_hourly_rate / line_capacity.max_possible_rate) * 100, 1) AS capacity_utilization_pct,
    ROUND(line_capacity.max_possible_rate - bi.avg_hourly_rate, 1) AS improvement_potential,
    CONCAT(
        'Bottleneck machine: ', bi.machine_name,
        ' | Current rate: ', ROUND(bi.avg_hourly_rate, 0), ' units/hr',
        ' | Potential gain: ', ROUND(line_capacity.max_possible_rate - bi.avg_hourly_rate, 0), ' units/hr'
    ) AS optimization_message
FROM bottleneck_identification bi
INNER JOIN production_lines pl ON bi.line_id = pl.line_id
INNER JOIN (
    SELECT
        line_id,
        MIN(m.max_capacity_per_hour) AS max_possible_rate
    FROM machines m
    GROUP BY line_id
) line_capacity ON bi.line_id = line_capacity.line_id
WHERE bi.bottleneck_rank = 1
ORDER BY improvement_potential DESC;

-- ============================================================================
-- Six Sigma Process Capability Analysis
-- ============================================================================

-- Calculate Cp, Cpk for critical quality parameters
WITH quality_measurements AS (
    SELECT
        p.product_id,
        p.product_code,
        p.product_name,
        JSON_EXTRACT(qi.measurements, '$.dimension') AS measured_value,
        JSON_EXTRACT(p.quality_specs, '$.dimension.target') AS target_value,
        JSON_EXTRACT(p.quality_specs, '$.dimension.lsl') AS lower_spec_limit,
        JSON_EXTRACT(p.quality_specs, '$.dimension.usl') AS upper_spec_limit,
        qi.inspection_time
    FROM quality_inspections qi
    INNER JOIN products p ON qi.product_id = p.product_id
    WHERE qi.inspection_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
        AND JSON_EXTRACT(qi.measurements, '$.dimension') IS NOT NULL
),
process_statistics AS (
    SELECT
        product_id,
        product_code,
        product_name,
        COUNT(*) AS sample_size,
        AVG(measured_value) AS process_mean,
        STDDEV(measured_value) AS process_stddev,
        MIN(measured_value) AS min_value,
        MAX(measured_value) AS max_value,
        AVG(upper_spec_limit) AS usl,
        AVG(lower_spec_limit) AS lsl,
        AVG(target_value) AS target
    FROM quality_measurements
    GROUP BY product_id
    HAVING sample_size >= 30  -- Minimum sample size for reliable statistics
)
SELECT
    product_code,
    product_name,
    sample_size,
    ROUND(process_mean, 4) AS mean,
    ROUND(process_stddev, 4) AS stddev,
    ROUND(lsl, 4) AS lsl,
    ROUND(usl, 4) AS usl,
    ROUND((usl - lsl) / (6 * process_stddev), 3) AS cp,  -- Process capability
    ROUND(LEAST(
        (usl - process_mean) / (3 * process_stddev),
        (process_mean - lsl) / (3 * process_stddev)
    ), 3) AS cpk,  -- Process capability index
    ROUND((1 - (
        (1 - CDF(NORMAL(), (usl - process_mean) / process_stddev)) +
        CDF(NORMAL(), (lsl - process_mean) / process_stddev)
    )) * 100, 2) AS yield_percentage,
    CASE
        WHEN LEAST((usl - process_mean) / (3 * process_stddev),
                  (process_mean - lsl) / (3 * process_stddev)) >= 1.67 THEN '6 Sigma'
        WHEN LEAST((usl - process_mean) / (3 * process_stddev),
                  (process_mean - lsl) / (3 * process_stddev)) >= 1.33 THEN '5 Sigma'
        WHEN LEAST((usl - process_mean) / (3 * process_stddev),
                  (process_mean - lsl) / (3 * process_stddev)) >= 1.00 THEN '4 Sigma'
        WHEN LEAST((usl - process_mean) / (3 * process_stddev),
                  (process_mean - lsl) / (3 * process_stddev)) >= 0.67 THEN '3 Sigma'
        ELSE 'Below 3 Sigma'
    END AS sigma_level
FROM process_statistics
ORDER BY cpk ASC;

-- ============================================================================
-- Energy Efficiency Analysis
-- ============================================================================

-- Energy consumption and efficiency metrics
WITH energy_consumption AS (
    SELECT
        m.machine_id,
        m.machine_code,
        m.machine_name,
        m.machine_type,
        m.power_consumption_kw,
        DATE(pr.start_time) AS production_date,
        SUM(TIMESTAMPDIFF(MINUTE, pr.start_time, pr.end_time)) / 60 AS operating_hours,
        SUM(pr.quantity_good) AS good_units_produced,
        SUM(pr.downtime_minutes) / 60 AS downtime_hours
    FROM machines m
    INNER JOIN production_runs pr ON m.machine_id = pr.machine_id
    WHERE pr.start_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
        AND pr.end_time IS NOT NULL
    GROUP BY m.machine_id, DATE(pr.start_time)
),
energy_metrics AS (
    SELECT
        machine_id,
        machine_code,
        machine_name,
        machine_type,
        power_consumption_kw,
        AVG(operating_hours) AS avg_daily_operating_hours,
        AVG(good_units_produced) AS avg_daily_output,
        AVG(downtime_hours) AS avg_daily_downtime,
        AVG(operating_hours * power_consumption_kw) AS avg_daily_kwh,
        AVG(good_units_produced / NULLIF(operating_hours * power_consumption_kw, 0)) AS units_per_kwh
    FROM energy_consumption
    GROUP BY machine_id
)
SELECT
    machine_type,
    COUNT(*) AS machine_count,
    ROUND(AVG(avg_daily_operating_hours), 1) AS avg_operating_hours,
    ROUND(AVG(avg_daily_kwh), 0) AS avg_daily_kwh,
    ROUND(SUM(avg_daily_kwh), 0) AS total_daily_kwh,
    ROUND(AVG(units_per_kwh), 2) AS avg_efficiency_units_per_kwh,
    ROUND(SUM(avg_daily_kwh) * 0.12, 2) AS daily_energy_cost_usd,  -- Assuming $0.12/kWh
    ROUND(SUM(avg_daily_kwh) * 0.0005, 2) AS daily_co2_tons,  -- Assuming 0.5 kg CO2/kWh
    ROUND(AVG(avg_daily_operating_hours / 24) * 100, 1) AS utilization_rate_pct
FROM energy_metrics
GROUP BY machine_type
ORDER BY total_daily_kwh DESC;

-- ============================================================================
-- Supply Chain Performance
-- ============================================================================

-- Production lead time and cycle time analysis
WITH order_cycle_times AS (
    SELECT
        wo.order_id,
        wo.order_number,
        p.product_code,
        p.product_name,
        wo.planned_quantity,
        wo.produced_quantity,
        wo.planned_start_time,
        wo.planned_end_time,
        wo.actual_start_time,
        wo.actual_end_time,
        TIMESTAMPDIFF(HOUR, wo.planned_start_time, wo.planned_end_time) AS planned_cycle_time_hours,
        TIMESTAMPDIFF(HOUR, wo.actual_start_time, wo.actual_end_time) AS actual_cycle_time_hours,
        TIMESTAMPDIFF(HOUR, wo.created_at, wo.actual_start_time) AS queue_time_hours,
        TIMESTAMPDIFF(HOUR, wo.actual_start_time, MIN(pr.start_time)) AS setup_time_hours,
        SUM(pr.downtime_minutes) / 60 AS total_downtime_hours
    FROM work_orders wo
    INNER JOIN products p ON wo.product_id = p.product_id
    LEFT JOIN production_runs pr ON wo.order_id = pr.order_id
    WHERE wo.status = 'completed'
        AND wo.actual_end_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY wo.order_id
)
SELECT
    product_code,
    product_name,
    COUNT(*) AS orders_completed,
    ROUND(AVG(planned_quantity), 0) AS avg_order_size,
    ROUND(AVG(queue_time_hours), 1) AS avg_queue_time_hours,
    ROUND(AVG(setup_time_hours), 1) AS avg_setup_time_hours,
    ROUND(AVG(actual_cycle_time_hours), 1) AS avg_production_time_hours,
    ROUND(AVG(total_downtime_hours), 1) AS avg_downtime_hours,
    ROUND(AVG(queue_time_hours + actual_cycle_time_hours), 1) AS avg_total_lead_time_hours,
    ROUND(AVG(actual_cycle_time_hours - planned_cycle_time_hours), 1) AS avg_schedule_variance_hours,
    ROUND((AVG(actual_cycle_time_hours - total_downtime_hours) / AVG(actual_cycle_time_hours)) * 100, 1) AS value_added_time_pct
FROM order_cycle_times
GROUP BY product_code, product_name
ORDER BY avg_total_lead_time_hours DESC;