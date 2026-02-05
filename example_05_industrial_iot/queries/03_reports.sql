-- ============================================================================
-- Industrial IoT Management Reports
-- ============================================================================

USE industrial_iot;

-- ============================================================================
-- Executive Dashboard Report
-- ============================================================================

-- Factory-level KPI summary
SELECT
    f.factory_name,
    f.factory_type,
    COUNT(DISTINCT pl.line_id) AS production_lines,
    COUNT(DISTINCT m.machine_id) AS total_machines,

    -- Production metrics
    COALESCE(prod.orders_completed, 0) AS orders_completed_mtd,
    COALESCE(prod.total_units_produced, 0) AS units_produced_mtd,
    COALESCE(prod.avg_yield, 0) AS avg_yield_percentage,

    -- OEE metrics
    ROUND(oee.avg_oee, 1) AS avg_oee_mtd,
    ROUND(oee.avg_availability, 1) AS avg_availability,
    ROUND(oee.avg_performance, 1) AS avg_performance,
    ROUND(oee.avg_quality, 1) AS avg_quality,

    -- Downtime metrics
    ROUND(dt.total_downtime_hours, 1) AS downtime_hours_mtd,
    dt.primary_downtime_reason,

    -- Quality metrics
    COALESCE(quality.dppm, 0) AS dppm_mtd,
    COALESCE(quality.pass_rate, 0) AS quality_pass_rate

FROM factories f
LEFT JOIN production_lines pl ON f.factory_id = pl.factory_id

LEFT JOIN machines m ON pl.line_id = m.line_id

-- Production summary
LEFT JOIN (
    SELECT
        pl.factory_id,
        COUNT(DISTINCT wo.order_id) AS orders_completed,
        SUM(wo.good_quantity) AS total_units_produced,
        ROUND(AVG((wo.good_quantity / NULLIF(wo.produced_quantity, 0)) * 100), 1) AS avg_yield
    FROM work_orders wo
    INNER JOIN production_lines pl ON wo.line_id = pl.line_id
    WHERE wo.status = 'completed'
        AND wo.actual_end_time >= DATE_FORMAT(CURDATE(), '%Y-%m-01')
    GROUP BY pl.factory_id
) prod ON f.factory_id = prod.factory_id

-- OEE summary
LEFT JOIN (
    SELECT
        pl.factory_id,
        AVG(om.oee_percentage) AS avg_oee,
        AVG(om.availability_percentage) AS avg_availability,
        AVG(om.performance_percentage) AS avg_performance,
        AVG(om.quality_percentage) AS avg_quality
    FROM oee_metrics om
    INNER JOIN production_lines pl ON om.line_id = pl.line_id
    WHERE om.metric_timestamp >= DATE_FORMAT(CURDATE(), '%Y-%m-01')
    GROUP BY pl.factory_id
) oee ON f.factory_id = oee.factory_id

-- Downtime summary
LEFT JOIN (
    SELECT
        pl.factory_id,
        SUM(de.duration_minutes) / 60 AS total_downtime_hours,
        FIRST_VALUE(de.reason_category) OVER (
            PARTITION BY pl.factory_id
            ORDER BY SUM(de.duration_minutes) DESC
        ) AS primary_downtime_reason
    FROM downtime_events de
    INNER JOIN machines m ON de.machine_id = m.machine_id
    INNER JOIN production_lines pl ON m.line_id = pl.line_id
    WHERE de.start_time >= DATE_FORMAT(CURDATE(), '%Y-%m-01')
    GROUP BY pl.factory_id, de.reason_category
) dt ON f.factory_id = dt.factory_id

-- Quality summary
LEFT JOIN (
    SELECT
        pl.factory_id,
        ROUND((SUM(qi.defects_found) / NULLIF(SUM(qi.sample_size), 0)) * 1000000, 0) AS dppm,
        ROUND((SUM(CASE WHEN qi.pass_fail = 'pass' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 1) AS pass_rate
    FROM quality_inspections qi
    INNER JOIN production_runs pr ON qi.run_id = pr.run_id
    INNER JOIN machines m ON pr.machine_id = m.machine_id
    INNER JOIN production_lines pl ON m.line_id = pl.line_id
    WHERE qi.inspection_time >= DATE_FORMAT(CURDATE(), '%Y-%m-01')
    GROUP BY pl.factory_id
) quality ON f.factory_id = quality.factory_id

WHERE f.is_active = TRUE
GROUP BY f.factory_id
ORDER BY f.factory_name;

-- ============================================================================
-- Monthly Production Report
-- ============================================================================

-- Monthly production summary by product
SELECT
    DATE_FORMAT(wo.actual_end_time, '%Y-%m') AS month,
    p.product_category,
    p.product_code,
    p.product_name,
    COUNT(DISTINCT wo.order_id) AS orders_completed,
    SUM(wo.planned_quantity) AS total_planned_qty,
    SUM(wo.produced_quantity) AS total_produced_qty,
    SUM(wo.good_quantity) AS total_good_qty,
    SUM(wo.rejected_quantity) AS total_rejected_qty,
    ROUND((SUM(wo.good_quantity) / NULLIF(SUM(wo.produced_quantity), 0)) * 100, 2) AS yield_pct,
    ROUND((SUM(wo.produced_quantity) / NULLIF(SUM(wo.planned_quantity), 0)) * 100, 2) AS plan_achievement_pct,
    ROUND(AVG(TIMESTAMPDIFF(HOUR, wo.actual_start_time, wo.actual_end_time)), 1) AS avg_cycle_time_hours,
    COUNT(DISTINCT wo.line_id) AS lines_used
FROM work_orders wo
INNER JOIN products p ON wo.product_id = p.product_id
WHERE wo.status = 'completed'
    AND wo.actual_end_time >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
GROUP BY DATE_FORMAT(wo.actual_end_time, '%Y-%m'), p.product_id
ORDER BY month DESC, p.product_category, total_produced_qty DESC;

-- ============================================================================
-- Weekly OEE Report
-- ============================================================================

-- Weekly OEE performance by line
SELECT
    YEARWEEK(om.metric_timestamp) AS year_week,
    DATE_FORMAT(MIN(om.metric_timestamp), '%Y-%m-%d') AS week_start,
    DATE_FORMAT(MAX(om.metric_timestamp), '%Y-%m-%d') AS week_end,
    pl.line_name,
    f.factory_name,
    COUNT(DISTINCT DATE(om.metric_timestamp)) AS operating_days,
    ROUND(AVG(om.availability_percentage), 1) AS avg_availability,
    ROUND(AVG(om.performance_percentage), 1) AS avg_performance,
    ROUND(AVG(om.quality_percentage), 1) AS avg_quality,
    ROUND(AVG(om.oee_percentage), 1) AS avg_oee,
    ROUND(MIN(om.oee_percentage), 1) AS min_oee,
    ROUND(MAX(om.oee_percentage), 1) AS max_oee,
    SUM(om.total_pieces_produced) AS total_pieces,
    SUM(om.good_pieces) AS good_pieces,
    SUM(om.downtime_min) AS total_downtime_min
FROM oee_metrics om
INNER JOIN production_lines pl ON om.line_id = pl.line_id
INNER JOIN factories f ON pl.factory_id = f.factory_id
WHERE om.metric_timestamp >= DATE_SUB(CURDATE(), INTERVAL 12 WEEK)
GROUP BY YEARWEEK(om.metric_timestamp), pl.line_id
ORDER BY year_week DESC, f.factory_name, pl.line_name;

-- ============================================================================
-- Maintenance Compliance Report
-- ============================================================================

-- Maintenance schedule compliance by machine
SELECT
    m.machine_code,
    m.machine_name,
    m.machine_type,
    pl.line_name,
    ms.maintenance_type,
    ms.frequency_days,
    ms.last_performed,
    ms.next_due,
    DATEDIFF(ms.next_due, CURDATE()) AS days_until_due,
    CASE
        WHEN ms.next_due < CURDATE() THEN 'OVERDUE'
        WHEN ms.next_due <= DATE_ADD(CURDATE(), INTERVAL 7 DAY) THEN 'DUE SOON'
        ELSE 'ON SCHEDULE'
    END AS status,
    mr.completed_count,
    mr.avg_duration_hours,
    mr.avg_cost
FROM maintenance_schedules ms
INNER JOIN machines m ON ms.machine_id = m.machine_id
INNER JOIN production_lines pl ON m.line_id = pl.line_id
LEFT JOIN (
    SELECT
        machine_id,
        maintenance_type,
        COUNT(*) AS completed_count,
        AVG(downtime_minutes) / 60 AS avg_duration_hours,
        AVG(cost) AS avg_cost
    FROM maintenance_records
    WHERE status = 'completed'
        AND end_time >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
    GROUP BY machine_id, maintenance_type
) mr ON ms.machine_id = mr.machine_id AND ms.maintenance_type = mr.maintenance_type
WHERE ms.is_active = TRUE
ORDER BY
    CASE
        WHEN ms.next_due < CURDATE() THEN 1
        WHEN ms.next_due <= DATE_ADD(CURDATE(), INTERVAL 7 DAY) THEN 2
        ELSE 3
    END,
    ms.next_due;

-- ============================================================================
-- Quality Control Report
-- ============================================================================

-- Quality performance by inspector
SELECT
    o.first_name,
    o.last_name,
    o.employee_number,
    COUNT(DISTINCT qi.inspection_id) AS inspections_performed,
    SUM(qi.sample_size) AS total_samples_inspected,
    SUM(qi.defects_found) AS total_defects_found,
    ROUND((SUM(qi.defects_found) / NULLIF(SUM(qi.sample_size), 0)) * 1000000, 0) AS dppm,
    COUNT(DISTINCT qi.product_id) AS products_inspected,
    COUNT(DISTINCT DATE(qi.inspection_time)) AS days_worked,
    ROUND(AVG(qi.sample_size), 0) AS avg_sample_size,
    SUM(CASE WHEN qi.pass_fail = 'pass' THEN 1 ELSE 0 END) AS pass_count,
    SUM(CASE WHEN qi.pass_fail = 'fail' THEN 1 ELSE 0 END) AS fail_count,
    ROUND((SUM(CASE WHEN qi.pass_fail = 'pass' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 1) AS pass_rate
FROM quality_inspections qi
INNER JOIN operators o ON qi.inspector_id = o.operator_id
WHERE qi.inspection_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY o.operator_id
ORDER BY inspections_performed DESC;

-- ============================================================================
-- Cost Analysis Report
-- ============================================================================

-- Production cost breakdown
WITH production_costs AS (
    SELECT
        p.product_code,
        p.product_name,
        SUM(wo.good_quantity) AS total_good_units,

        -- Machine hours cost (assumed $50/hour)
        SUM(TIMESTAMPDIFF(MINUTE, pr.start_time, pr.end_time)) / 60 * 50 AS machine_cost,

        -- Labor cost (assumed $30/hour)
        COUNT(DISTINCT pr.operator_id) *
        SUM(TIMESTAMPDIFF(MINUTE, pr.start_time, pr.end_time)) / 60 * 30 AS labor_cost,

        -- Quality cost (rework assumed at $10/unit)
        SUM(wo.rejected_quantity) * 10 AS quality_cost,

        -- Downtime cost (assumed $100/hour)
        COALESCE(dt.downtime_cost, 0) AS downtime_cost

    FROM work_orders wo
    INNER JOIN products p ON wo.product_id = p.product_id
    INNER JOIN production_runs pr ON wo.order_id = pr.order_id
    LEFT JOIN (
        SELECT
            wo.product_id,
            SUM(de.duration_minutes) / 60 * 100 AS downtime_cost
        FROM downtime_events de
        INNER JOIN machines m ON de.machine_id = m.machine_id
        INNER JOIN production_runs pr ON m.machine_id = pr.machine_id
        INNER JOIN work_orders wo ON pr.order_id = wo.order_id
        WHERE de.start_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
        GROUP BY wo.product_id
    ) dt ON p.product_id = dt.product_id
    WHERE wo.status = 'completed'
        AND wo.actual_end_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY p.product_id
)
SELECT
    product_code,
    product_name,
    total_good_units,
    ROUND(machine_cost, 2) AS machine_cost,
    ROUND(labor_cost, 2) AS labor_cost,
    ROUND(quality_cost, 2) AS quality_cost,
    ROUND(downtime_cost, 2) AS downtime_cost,
    ROUND(machine_cost + labor_cost + quality_cost + downtime_cost, 2) AS total_cost,
    ROUND((machine_cost + labor_cost + quality_cost + downtime_cost) / NULLIF(total_good_units, 0), 2) AS cost_per_unit
FROM production_costs
ORDER BY total_cost DESC;

-- ============================================================================
-- Operator Performance Report
-- ============================================================================

-- Operator productivity metrics
SELECT
    o.employee_number,
    o.first_name,
    o.last_name,
    o.shift,
    o.skill_level,
    COUNT(DISTINCT pr.run_id) AS production_runs,
    COUNT(DISTINCT DATE(pr.start_time)) AS days_worked,
    SUM(pr.quantity_good) AS total_good_units,
    SUM(pr.quantity_rejected) AS total_rejected_units,
    ROUND((SUM(pr.quantity_good) / NULLIF(SUM(pr.quantity_produced), 0)) * 100, 1) AS yield_rate,
    ROUND(AVG(pr.quantity_produced / NULLIF(TIMESTAMPDIFF(HOUR, pr.start_time, pr.end_time), 0)), 1) AS avg_units_per_hour,
    SUM(pr.downtime_minutes) AS total_downtime_min,
    COUNT(DISTINCT m.machine_id) AS machines_operated
FROM operators o
LEFT JOIN production_runs pr ON o.operator_id = pr.operator_id
    AND pr.start_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
LEFT JOIN machines m ON pr.machine_id = m.machine_id
WHERE o.is_active = TRUE
GROUP BY o.operator_id
ORDER BY total_good_units DESC;