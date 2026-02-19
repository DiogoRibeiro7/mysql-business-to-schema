-- ============================================================================
-- Fleet Management Analytics Queries
-- ============================================================================

USE fleet_management;

-- Smoke test for CI query runner
SELECT 1 AS query_smoke_test;

-- ============================================================================
-- Fleet Utilization Analysis
-- ============================================================================

-- Vehicle utilization rates
WITH vehicle_metrics AS (
    SELECT
        v.vehicle_id,
        v.vehicle_number,
        v.vehicle_type,
        COUNT(DISTINCT t.trip_id) AS total_trips,
        SUM(t.distance_miles) AS total_miles,
        SUM(t.duration_minutes) / 60 AS total_hours,
        AVG(t.distance_miles) AS avg_trip_distance,
        AVG(t.avg_speed_mph) AS avg_speed,
        SUM(t.fuel_consumed_gallons) AS total_fuel,
        SUM(t.idle_time_minutes) AS total_idle_minutes,
        SUM(t.harsh_events_count) AS total_harsh_events
    FROM vehicles v
    LEFT JOIN trips t ON v.vehicle_id = t.vehicle_id
        AND t.start_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
        AND t.status = 'completed'
    WHERE v.status = 'active'
    GROUP BY v.vehicle_id
)
SELECT
    vehicle_number,
    vehicle_type,
    total_trips,
    ROUND(total_miles, 1) AS total_miles,
    ROUND(total_hours, 1) AS total_hours,
    ROUND(total_miles / NULLIF(total_hours, 0), 1) AS avg_mph,
    ROUND(total_miles / NULLIF(total_fuel, 0), 2) AS mpg,
    ROUND((total_hours / (30 * 24)) * 100, 1) AS utilization_pct,
    ROUND((total_idle_minutes / NULLIF(total_hours * 60, 0)) * 100, 1) AS idle_pct,
    total_harsh_events,
    ROUND(total_harsh_events / NULLIF(total_miles, 0) * 100, 2) AS events_per_100_miles,
    CASE
        WHEN (total_hours / (30 * 24)) > 0.7 THEN 'HIGH'
        WHEN (total_hours / (30 * 24)) > 0.4 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS utilization_level
FROM vehicle_metrics
ORDER BY utilization_pct DESC;

-- Fleet composition and age analysis
SELECT
    vehicle_type,
    COUNT(*) AS count,
    AVG(YEAR(CURDATE()) - year) AS avg_age_years,
    AVG(odometer_miles) AS avg_odometer,
    AVG(odometer_miles / NULLIF(YEAR(CURDATE()) - year, 0)) AS avg_miles_per_year,
    SUM(CASE WHEN DATEDIFF(next_service_miles, odometer_miles) < 1000 THEN 1 ELSE 0 END) AS vehicles_near_service,
    SUM(CASE WHEN DATEDIFF(registration_expiry, CURDATE()) < 30 THEN 1 ELSE 0 END) AS expiring_registrations,
    SUM(CASE WHEN DATEDIFF(insurance_expiry, CURDATE()) < 30 THEN 1 ELSE 0 END) AS expiring_insurance
FROM vehicles
WHERE status != 'retired'
GROUP BY vehicle_type
ORDER BY count DESC;

-- ============================================================================
-- Driver Performance Analysis
-- ============================================================================

-- Driver safety metrics and rankings
WITH driver_metrics AS (
    SELECT
        d.driver_id,
        CONCAT(d.first_name, ' ', d.last_name) AS driver_name,
        d.license_class,
        COUNT(DISTINCT t.trip_id) AS trips_count,
        SUM(t.distance_miles) AS total_miles,
        SUM(t.duration_minutes) / 60 AS total_hours,
        SUM(de.event_count) AS harsh_events,
        SUM(de.speeding_count) AS speeding_events,
        AVG(ds.safety_score) AS avg_safety_score,
        AVG(ds.fuel_efficiency_score) AS avg_fuel_score,
        AVG(ds.compliance_score) AS avg_compliance_score,
        COUNT(hv.violation_id) AS hos_violations
    FROM drivers d
    LEFT JOIN trips t ON d.driver_id = t.driver_id
        AND t.start_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    LEFT JOIN (
        SELECT
            driver_id,
            COUNT(*) AS event_count,
            SUM(CASE WHEN event_type = 'speeding' THEN 1 ELSE 0 END) AS speeding_count
        FROM driver_events
        WHERE timestamp >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
        GROUP BY driver_id
    ) de ON d.driver_id = de.driver_id
    LEFT JOIN driver_scores ds ON d.driver_id = ds.driver_id
        AND ds.score_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    LEFT JOIN hos_violations hv ON d.driver_id = hv.driver_id
        AND hv.violation_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    WHERE d.status = 'active'
    GROUP BY d.driver_id
)
SELECT
    driver_name,
    license_class,
    trips_count,
    ROUND(total_miles, 0) AS total_miles,
    ROUND(total_hours, 1) AS total_hours,
    COALESCE(harsh_events, 0) AS harsh_events,
    COALESCE(speeding_events, 0) AS speeding_events,
    ROUND(harsh_events / NULLIF(total_miles, 0) * 100, 2) AS events_per_100_miles,
    ROUND(avg_safety_score, 1) AS safety_score,
    ROUND(avg_fuel_score, 1) AS fuel_score,
    ROUND(avg_compliance_score, 1) AS compliance_score,
    hos_violations,
    RANK() OVER (ORDER BY avg_safety_score DESC) AS safety_rank,
    RANK() OVER (ORDER BY harsh_events / NULLIF(total_miles, 0)) AS incident_rank
FROM driver_metrics
ORDER BY avg_safety_score DESC;

-- Driver behavior trends
SELECT
    DATE(de.timestamp) AS event_date,
    de.event_type,
    COUNT(*) AS event_count,
    COUNT(DISTINCT de.driver_id) AS drivers_involved,
    COUNT(DISTINCT de.vehicle_id) AS vehicles_involved,
    AVG(de.g_force) AS avg_g_force,
    MAX(de.g_force) AS max_g_force,
    SUM(CASE WHEN de.severity = 'high' THEN 1 ELSE 0 END) AS high_severity,
    SUM(CASE WHEN de.severity = 'medium' THEN 1 ELSE 0 END) AS medium_severity,
    SUM(CASE WHEN de.severity = 'low' THEN 1 ELSE 0 END) AS low_severity
FROM driver_events de
WHERE de.timestamp >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY DATE(de.timestamp), de.event_type
ORDER BY event_date DESC, event_count DESC;

-- ============================================================================
-- Route and Trip Analysis
-- ============================================================================

-- Route efficiency analysis
SELECT
    r.route_name,
    COUNT(DISTINCT t.trip_id) AS trips_count,
    AVG(t.distance_miles) AS avg_distance,
    AVG(t.duration_minutes) AS avg_duration,
    AVG(t.stops_count) AS avg_stops,
    AVG(t.avg_speed_mph) AS avg_speed,
    AVG(t.fuel_consumed_gallons) AS avg_fuel,
    AVG(t.distance_miles / NULLIF(t.fuel_consumed_gallons, 0)) AS avg_mpg,
    STD(t.duration_minutes) AS duration_std_dev,
    MIN(t.duration_minutes) AS fastest_time,
    MAX(t.duration_minutes) AS slowest_time
FROM routes r
LEFT JOIN trips t ON calculate_distance(
        t.start_latitude, t.start_longitude,
        JSON_EXTRACT(r.waypoints, '$[0].lat'),
        JSON_EXTRACT(r.waypoints, '$[0].lng')
    ) < 1  -- Match trips starting within 1km of route start
WHERE r.is_active = TRUE
  AND t.start_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY r.route_id
ORDER BY trips_count DESC;

-- Stop time analysis
SELECT
    s.stop_type,
    COUNT(*) AS total_stops,
    AVG(s.duration_minutes) AS avg_duration,
    MIN(s.duration_minutes) AS min_duration,
    MAX(s.duration_minutes) AS max_duration,
    STD(s.duration_minutes) AS duration_std_dev,
    SUM(s.duration_minutes) AS total_time_minutes,
    COUNT(DISTINCT t.vehicle_id) AS vehicles,
    COUNT(DISTINCT t.driver_id) AS drivers
FROM stops s
INNER JOIN trips t ON s.trip_id = t.trip_id
WHERE t.start_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
  AND s.duration_minutes IS NOT NULL
GROUP BY s.stop_type
ORDER BY total_stops DESC;

-- ============================================================================
-- Fuel Economy Analysis
-- ============================================================================

-- Fuel efficiency by vehicle type
SELECT
    v.vehicle_type,
    COUNT(DISTINCT ft.vehicle_id) AS vehicles,
    COUNT(ft.transaction_id) AS fuel_stops,
    SUM(ft.gallons) AS total_gallons,
    AVG(ft.price_per_gallon) AS avg_price_per_gallon,
    SUM(ft.total_cost) AS total_cost,
    AVG(miles_between.miles_driven / NULLIF(ft.gallons, 0)) AS avg_mpg,
    MIN(miles_between.miles_driven / NULLIF(ft.gallons, 0)) AS worst_mpg,
    MAX(miles_between.miles_driven / NULLIF(ft.gallons, 0)) AS best_mpg
FROM fuel_transactions ft
INNER JOIN vehicles v ON ft.vehicle_id = v.vehicle_id
LEFT JOIN (
    SELECT
        f1.transaction_id,
        f1.vehicle_id,
        f2.odometer_miles - f1.odometer_miles AS miles_driven
    FROM fuel_transactions f1
    INNER JOIN fuel_transactions f2 ON f1.vehicle_id = f2.vehicle_id
        AND f2.transaction_date = (
            SELECT MIN(transaction_date)
            FROM fuel_transactions f3
            WHERE f3.vehicle_id = f1.vehicle_id
              AND f3.transaction_date > f1.transaction_date
        )
) miles_between ON ft.transaction_id = miles_between.transaction_id
WHERE ft.transaction_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY v.vehicle_type
ORDER BY avg_mpg DESC;

-- Fuel cost trends
SELECT
    DATE_FORMAT(ft.transaction_date, '%Y-%m') AS month,
    COUNT(DISTINCT ft.vehicle_id) AS vehicles_fueled,
    COUNT(ft.transaction_id) AS transactions,
    SUM(ft.gallons) AS total_gallons,
    AVG(ft.price_per_gallon) AS avg_price,
    SUM(ft.total_cost) AS total_cost,
    SUM(ft.gallons) / COUNT(DISTINCT DATE(ft.transaction_date)) AS daily_avg_gallons
FROM fuel_transactions ft
WHERE ft.transaction_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY DATE_FORMAT(ft.transaction_date, '%Y-%m')
ORDER BY month DESC;

-- ============================================================================
-- Maintenance Analysis
-- ============================================================================

-- Maintenance costs by vehicle type
SELECT
    v.vehicle_type,
    COUNT(DISTINCT mr.vehicle_id) AS vehicles_serviced,
    COUNT(mr.maintenance_id) AS maintenance_events,
    SUM(CASE WHEN mr.maintenance_type = 'preventive' THEN 1 ELSE 0 END) AS preventive,
    SUM(CASE WHEN mr.maintenance_type = 'repair' THEN 1 ELSE 0 END) AS repairs,
    SUM(mr.total_cost) AS total_cost,
    AVG(mr.total_cost) AS avg_cost_per_event,
    SUM(mr.parts_cost) AS total_parts_cost,
    SUM(mr.labor_cost) AS total_labor_cost,
    AVG(mr.odometer_miles - v.last_service_miles) AS avg_miles_between_service
FROM maintenance_records mr
INNER JOIN vehicles v ON mr.vehicle_id = v.vehicle_id
WHERE mr.service_date >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
GROUP BY v.vehicle_type
ORDER BY total_cost DESC;

-- Vehicle reliability analysis (MTBF)
WITH failure_data AS (
    SELECT
        v.vehicle_id,
        v.vehicle_number,
        v.vehicle_type,
        COUNT(mr.maintenance_id) AS failure_count,
        MIN(mr.service_date) AS first_failure,
        MAX(mr.service_date) AS last_failure,
        DATEDIFF(MAX(mr.service_date), MIN(mr.service_date)) AS days_span
    FROM vehicles v
    LEFT JOIN maintenance_records mr ON v.vehicle_id = mr.vehicle_id
        AND mr.maintenance_type = 'repair'
        AND mr.service_date >= DATE_SUB(CURDATE(), INTERVAL 365 DAY)
    WHERE v.status = 'active'
    GROUP BY v.vehicle_id
    HAVING failure_count > 0
)
SELECT
    vehicle_type,
    COUNT(*) AS vehicles,
    AVG(failure_count) AS avg_failures,
    AVG(days_span / NULLIF(failure_count - 1, 0)) AS mtbf_days,
    MIN(days_span / NULLIF(failure_count - 1, 0)) AS worst_mtbf,
    MAX(days_span / NULLIF(failure_count - 1, 0)) AS best_mtbf
FROM failure_data
GROUP BY vehicle_type
ORDER BY mtbf_days DESC;

-- ============================================================================
-- HOS Compliance Analysis
-- ============================================================================

-- HOS compliance summary
SELECT
    d.driver_id,
    CONCAT(d.first_name, ' ', d.last_name) AS driver_name,
    COUNT(DISTINCT dl.log_date) AS days_logged,
    SUM(CASE WHEN dl.duty_status = 'driving' THEN dl.duration_minutes ELSE 0 END) / 60 AS total_driving_hours,
    SUM(CASE WHEN dl.duty_status IN ('driving', 'on_duty') THEN dl.duration_minutes ELSE 0 END) / 60 AS total_duty_hours,
    SUM(CASE WHEN dl.certified = TRUE THEN 1 ELSE 0 END) AS certified_logs,
    COUNT(hv.violation_id) AS violations,
    SUM(CASE WHEN hv.violation_type = '11_hour' THEN 1 ELSE 0 END) AS hour_11_violations,
    SUM(CASE WHEN hv.violation_type = '14_hour' THEN 1 ELSE 0 END) AS hour_14_violations,
    SUM(CASE WHEN hv.violation_type = '30_minute_break' THEN 1 ELSE 0 END) AS break_violations,
    SUM(CASE WHEN hv.violation_type IN ('60_hour_7day', '70_hour_8day') THEN 1 ELSE 0 END) AS weekly_violations
FROM drivers d
LEFT JOIN driver_logs dl ON d.driver_id = dl.driver_id
    AND dl.log_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
LEFT JOIN hos_violations hv ON d.driver_id = hv.driver_id
    AND hv.violation_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
WHERE d.status = 'active'
  AND d.license_class IN ('CDL_A', 'CDL_B')
GROUP BY d.driver_id
ORDER BY violations DESC, driver_name;

-- ============================================================================
-- Geofencing Analytics
-- ============================================================================

-- Geofence utilization
SELECT
    g.geofence_name,
    g.geofence_type,
    COUNT(ge.event_id) AS total_events,
    SUM(CASE WHEN ge.event_type = 'enter' THEN 1 ELSE 0 END) AS entries,
    SUM(CASE WHEN ge.event_type = 'exit' THEN 1 ELSE 0 END) AS exits,
    COUNT(DISTINCT ge.vehicle_id) AS unique_vehicles,
    AVG(ge.duration_minutes) AS avg_duration_minutes,
    MAX(ge.duration_minutes) AS max_duration_minutes,
    COUNT(DISTINCT DATE(ge.timestamp)) AS active_days
FROM geofences g
LEFT JOIN geofence_events ge ON g.geofence_id = ge.geofence_id
    AND ge.timestamp >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
WHERE g.is_active = TRUE
GROUP BY g.geofence_id
ORDER BY total_events DESC;
