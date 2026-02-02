-- ============================================================================
-- IoT Garbage Bin Monitoring System - Management Reports
-- ============================================================================
-- Description: Executive and operational reports for management
-- ============================================================================

USE iot_bins;

-- ============================================================================
-- 1. Executive Dashboard Summary
-- ============================================================================
SELECT 'Executive Summary - Last 30 Days' AS report_title;

SELECT
    'Total Waste Collected' AS metric,
    CONCAT(ROUND(SUM(weight_kg) / 1000, 2), ' tons') AS value
FROM collection_events
WHERE collected_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
UNION ALL
SELECT
    'Average Collection Efficiency',
    CONCAT(ROUND(AVG(fill_level_before), 1), '%')
FROM collection_events
WHERE collected_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
UNION ALL
SELECT
    'Total Collections',
    FORMAT(COUNT(*), 0)
FROM collection_events
WHERE collected_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
UNION ALL
SELECT
    'Active Bins',
    FORMAT(COUNT(*), 0)
FROM bins
WHERE status = 'active'
UNION ALL
SELECT
    'Sensor Uptime',
    CONCAT(ROUND(
        100.0 * SUM(CASE WHEN status = 'active' THEN 1 ELSE 0 END) / COUNT(*),
    1), '%')
FROM sensors
UNION ALL
SELECT
    'Critical Alerts (Unresolved)',
    FORMAT(COUNT(*), 0)
FROM alerts
WHERE severity IN ('critical', 'emergency')
    AND resolved_at IS NULL;

-- ============================================================================
-- 2. District Performance Report
-- ============================================================================
SELECT
    d.name AS district,
    COUNT(DISTINCT b.bin_id) AS total_bins,
    COUNT(DISTINCT ce.event_id) AS collections,
    ROUND(SUM(ce.weight_kg) / 1000, 2) AS waste_collected_tons,
    ROUND(AVG(ce.fill_level_before), 1) AS avg_fill_at_collection,
    COUNT(DISTINCT cs.schedule_id) AS scheduled_routes,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN cs.status = 'completed' THEN cs.schedule_id END) /
          NULLIF(COUNT(DISTINCT cs.schedule_id), 0), 1) AS completion_rate,
    COUNT(DISTINCT a.alert_id) AS total_alerts,
    ROUND(AVG(TIMESTAMPDIFF(HOUR, a.triggered_at, a.resolved_at)), 1) AS avg_alert_resolution_hours
FROM districts d
LEFT JOIN bins b ON d.district_id = b.district_id
LEFT JOIN collection_events ce ON b.bin_id = ce.bin_id
    AND ce.collected_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
LEFT JOIN collection_routes cr ON d.district_id = cr.district_id
LEFT JOIN collection_schedules cs ON cr.route_id = cs.route_id
    AND cs.scheduled_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
LEFT JOIN alerts a ON b.bin_id = a.bin_id
    AND a.triggered_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY d.district_id
ORDER BY waste_collected_tons DESC;

-- ============================================================================
-- 3. Fleet Utilization Report
-- ============================================================================
SELECT
    t.truck_code,
    t.fuel_type,
    t.capacity_kg,
    COUNT(DISTINCT ce.event_id) AS total_collections,
    COUNT(DISTINCT DATE(ce.collected_at)) AS days_active,
    ROUND(SUM(ce.weight_kg), 2) AS total_weight_collected_kg,
    ROUND(AVG(ce.weight_kg), 2) AS avg_collection_weight_kg,
    ROUND(100.0 * SUM(ce.weight_kg) / (t.capacity_kg * COUNT(DISTINCT DATE(ce.collected_at))), 1)
        AS avg_capacity_utilization_pct,
    t.odometer_km,
    t.next_maintenance_date,
    CASE
        WHEN t.next_maintenance_date < DATE_ADD(CURDATE(), INTERVAL 7 DAY) THEN 'DUE SOON'
        ELSE 'OK'
    END AS maintenance_status
FROM trucks t
LEFT JOIN collection_events ce ON t.truck_id = ce.truck_id
    AND ce.collected_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
WHERE t.status != 'decommissioned'
GROUP BY t.truck_id
ORDER BY total_collections DESC;

-- ============================================================================
-- 4. Driver Performance Report
-- ============================================================================
SELECT
    dr.employee_id,
    CONCAT(dr.first_name, ' ', dr.last_name) AS driver_name,
    COUNT(DISTINCT cs.schedule_id) AS routes_assigned,
    COUNT(DISTINCT CASE WHEN cs.status = 'completed' THEN cs.schedule_id END) AS routes_completed,
    COUNT(DISTINCT ce.event_id) AS bins_collected,
    ROUND(SUM(ce.weight_kg) / 1000, 2) AS waste_collected_tons,
    ROUND(AVG(ce.collection_duration_seconds) / 60, 1) AS avg_collection_time_minutes,
    COUNT(DISTINCT DATE(cs.scheduled_date)) AS days_worked,
    ROUND(
        100.0 * COUNT(DISTINCT CASE WHEN cs.actual_start_time <= CONCAT(cs.scheduled_date, ' ', cs.scheduled_start_time) THEN cs.schedule_id END) /
        NULLIF(COUNT(DISTINCT cs.schedule_id), 0), 1
    ) AS on_time_percentage
FROM drivers dr
LEFT JOIN collection_schedules cs ON dr.driver_id = cs.driver_id
    AND cs.scheduled_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
LEFT JOIN collection_events ce ON dr.driver_id = ce.driver_id
    AND ce.collected_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
WHERE dr.status = 'active'
GROUP BY dr.driver_id
ORDER BY waste_collected_tons DESC;

-- ============================================================================
-- 5. Sensor Health Report
-- ============================================================================
SELECT
    s.sensor_type,
    COUNT(*) AS total_sensors,
    COUNT(CASE WHEN s.status = 'active' THEN 1 END) AS active,
    COUNT(CASE WHEN s.status = 'offline' THEN 1 END) AS offline,
    COUNT(CASE WHEN s.status = 'maintenance' THEN 1 END) AS maintenance,
    COUNT(CASE WHEN s.status = 'faulty' THEN 1 END) AS faulty,
    ROUND(AVG(s.battery_level), 1) AS avg_battery_level,
    COUNT(CASE WHEN s.battery_level < 20 THEN 1 END) AS low_battery_count,
    ROUND(AVG(DATEDIFF(CURDATE(), s.installation_date)), 0) AS avg_age_days,
    COUNT(CASE WHEN TIMESTAMPDIFF(HOUR, s.last_reading_time, NOW()) > 24 THEN 1 END) AS no_recent_data
FROM sensors s
GROUP BY s.sensor_type
ORDER BY s.sensor_type;

-- ============================================================================
-- 6. Cost Analysis Report
-- ============================================================================
WITH operational_metrics AS (
    SELECT
        DATE_FORMAT(ce.collected_at, '%Y-%m') AS month,
        COUNT(DISTINCT ce.event_id) AS total_collections,
        SUM(ce.weight_kg) / 1000 AS total_tons,
        COUNT(DISTINCT ce.truck_id) AS trucks_used,
        COUNT(DISTINCT ce.driver_id) AS drivers_used,
        COUNT(DISTINCT DATE(ce.collected_at)) AS operational_days,
        AVG(ce.collection_duration_seconds) / 3600 AS avg_collection_hours
    FROM collection_events ce
    WHERE ce.collected_at >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
    GROUP BY DATE_FORMAT(ce.collected_at, '%Y-%m')
)
SELECT
    month,
    total_collections,
    ROUND(total_tons, 2) AS waste_tons,
    trucks_used,
    drivers_used,
    operational_days,
    ROUND(total_tons / total_collections, 3) AS tons_per_collection,
    ROUND(total_collections / operational_days, 1) AS collections_per_day,
    -- Cost estimates (example values - adjust based on actual costs)
    ROUND(total_tons * 50, 2) AS disposal_cost_estimate,  -- $50 per ton
    ROUND(operational_days * drivers_used * 200, 2) AS labor_cost_estimate,  -- $200 per driver per day
    ROUND(operational_days * trucks_used * 150, 2) AS fuel_cost_estimate  -- $150 per truck per day
FROM operational_metrics
ORDER BY month DESC;

-- ============================================================================
-- 7. Environmental Impact Report
-- ============================================================================
SELECT
    DATE_FORMAT(ce.collected_at, '%Y-%m') AS month,
    b.bin_type,
    COUNT(DISTINCT ce.event_id) AS collections,
    ROUND(SUM(ce.weight_kg) / 1000, 2) AS total_tons,
    ROUND(AVG(ce.fill_level_before), 1) AS avg_fill_level,
    -- Environmental metrics
    CASE b.bin_type
        WHEN 'recycling' THEN ROUND(SUM(ce.weight_kg) / 1000 * 0.89, 2)  -- 89% diversion rate
        WHEN 'organic' THEN ROUND(SUM(ce.weight_kg) / 1000 * 0.95, 2)    -- 95% composting rate
        WHEN 'paper' THEN ROUND(SUM(ce.weight_kg) / 1000 * 0.87, 2)      -- 87% recycling rate
        WHEN 'glass' THEN ROUND(SUM(ce.weight_kg) / 1000 * 0.90, 2)      -- 90% recycling rate
        ELSE 0
    END AS diverted_from_landfill_tons,
    -- CO2 savings estimate (tons CO2 per ton of material)
    CASE b.bin_type
        WHEN 'recycling' THEN ROUND(SUM(ce.weight_kg) / 1000 * 2.5, 2)
        WHEN 'organic' THEN ROUND(SUM(ce.weight_kg) / 1000 * 0.5, 2)
        WHEN 'paper' THEN ROUND(SUM(ce.weight_kg) / 1000 * 3.0, 2)
        WHEN 'glass' THEN ROUND(SUM(ce.weight_kg) / 1000 * 0.3, 2)
        ELSE 0
    END AS co2_saved_tons
FROM collection_events ce
INNER JOIN bins b ON ce.bin_id = b.bin_id
WHERE ce.collected_at >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
GROUP BY DATE_FORMAT(ce.collected_at, '%Y-%m'), b.bin_type
ORDER BY month DESC, b.bin_type;

-- ============================================================================
-- 8. Service Level Agreement (SLA) Compliance
-- ============================================================================
WITH sla_metrics AS (
    SELECT
        d.name AS district,
        COUNT(DISTINCT b.bin_id) AS total_bins,
        -- Bins collected within SLA (e.g., before 85% full)
        COUNT(DISTINCT CASE
            WHEN ce.fill_level_before <= 85 THEN ce.bin_id
        END) AS within_sla,
        -- Bins that exceeded SLA
        COUNT(DISTINCT CASE
            WHEN ce.fill_level_before > 85 THEN ce.bin_id
        END) AS exceeded_sla,
        -- Overflow incidents (>95% full)
        COUNT(DISTINCT CASE
            WHEN ce.fill_level_before > 95 THEN ce.bin_id
        END) AS overflow_incidents,
        -- Average response time to critical alerts
        AVG(CASE
            WHEN a.severity = 'critical' THEN
                TIMESTAMPDIFF(HOUR, a.triggered_at, a.resolved_at)
        END) AS avg_critical_response_hours
    FROM districts d
    INNER JOIN bins b ON d.district_id = b.district_id
    LEFT JOIN collection_events ce ON b.bin_id = ce.bin_id
        AND ce.collected_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    LEFT JOIN alerts a ON b.bin_id = a.bin_id
        AND a.triggered_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    WHERE b.status = 'active'
    GROUP BY d.district_id
)
SELECT
    district,
    total_bins,
    within_sla,
    exceeded_sla,
    ROUND(100.0 * within_sla / NULLIF(within_sla + exceeded_sla, 0), 1) AS sla_compliance_pct,
    overflow_incidents,
    ROUND(avg_critical_response_hours, 1) AS avg_critical_response_hours,
    CASE
        WHEN 100.0 * within_sla / NULLIF(within_sla + exceeded_sla, 0) >= 95 THEN 'EXCELLENT'
        WHEN 100.0 * within_sla / NULLIF(within_sla + exceeded_sla, 0) >= 90 THEN 'GOOD'
        WHEN 100.0 * within_sla / NULLIF(within_sla + exceeded_sla, 0) >= 85 THEN 'FAIR'
        ELSE 'NEEDS IMPROVEMENT'
    END AS performance_rating
FROM sla_metrics
ORDER BY sla_compliance_pct DESC;

-- ============================================================================
-- 9. Predictive Maintenance Report
-- ============================================================================
SELECT
    'Sensors Requiring Maintenance' AS category,
    s.sensor_code,
    s.sensor_type,
    b.bin_code,
    s.battery_level,
    DATEDIFF(CURDATE(), s.installation_date) AS days_in_service,
    s.status,
    CASE
        WHEN s.battery_level < 15 THEN 'Replace Battery Immediately'
        WHEN s.battery_level < 25 THEN 'Schedule Battery Replacement'
        WHEN DATEDIFF(CURDATE(), s.installation_date) > 730 THEN 'Schedule Preventive Maintenance'
        WHEN s.status = 'faulty' THEN 'Repair Required'
        ELSE 'Monitor'
    END AS recommendation
FROM sensors s
INNER JOIN bins b ON s.bin_id = b.bin_id
WHERE s.battery_level < 25
    OR DATEDIFF(CURDATE(), s.installation_date) > 730
    OR s.status IN ('faulty', 'maintenance')
ORDER BY s.battery_level ASC, days_in_service DESC;

-- ============================================================================
-- 10. Weekly Operations Summary
-- ============================================================================
SELECT
    WEEK(ce.collected_at) AS week_number,
    DATE(MIN(ce.collected_at)) AS week_start,
    DATE(MAX(ce.collected_at)) AS week_end,
    COUNT(DISTINCT ce.bin_id) AS unique_bins_collected,
    COUNT(ce.event_id) AS total_collections,
    ROUND(SUM(ce.weight_kg) / 1000, 2) AS total_waste_tons,
    COUNT(DISTINCT ce.truck_id) AS trucks_used,
    COUNT(DISTINCT ce.driver_id) AS drivers_active,
    ROUND(AVG(ce.fill_level_before), 1) AS avg_fill_level,
    ROUND(AVG(ce.collection_duration_seconds) / 60, 1) AS avg_collection_minutes
FROM collection_events ce
WHERE ce.collected_at >= DATE_SUB(CURDATE(), INTERVAL 8 WEEK)
GROUP BY WEEK(ce.collected_at)
ORDER BY week_number DESC;