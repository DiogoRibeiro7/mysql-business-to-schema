-- ============================================================================
-- Fleet Management Reports
-- ============================================================================

USE fleet_management;

-- ============================================================================
-- Executive Fleet Summary Report
-- ============================================================================

-- Company-wide KPI dashboard
SELECT
    c.company_name,

    -- Fleet composition
    COUNT(DISTINCT v.vehicle_id) AS total_vehicles,
    SUM(CASE WHEN v.status = 'active' THEN 1 ELSE 0 END) AS active_vehicles,
    SUM(CASE WHEN v.status = 'maintenance' THEN 1 ELSE 0 END) AS in_maintenance,

    -- Driver metrics
    COUNT(DISTINCT d.driver_id) AS total_drivers,
    SUM(CASE WHEN d.status = 'active' THEN 1 ELSE 0 END) AS active_drivers,

    -- Operations (last 30 days)
    COALESCE(ops.total_trips, 0) AS trips_mtd,
    COALESCE(ops.total_miles, 0) AS miles_mtd,
    COALESCE(ops.total_hours, 0) AS hours_mtd,
    COALESCE(ops.avg_utilization, 0) AS fleet_utilization_pct,

    -- Safety metrics
    COALESCE(safety.harsh_events, 0) AS harsh_events_mtd,
    COALESCE(safety.avg_safety_score, 0) AS avg_safety_score,
    COALESCE(safety.hos_violations, 0) AS hos_violations_mtd,

    -- Fuel metrics
    COALESCE(fuel.total_gallons, 0) AS fuel_gallons_mtd,
    COALESCE(fuel.total_cost, 0) AS fuel_cost_mtd,
    COALESCE(fuel.avg_mpg, 0) AS fleet_avg_mpg,

    -- Maintenance
    COALESCE(maint.total_events, 0) AS maintenance_events_mtd,
    COALESCE(maint.total_cost, 0) AS maintenance_cost_mtd,
    COALESCE(maint.vehicles_due_service, 0) AS vehicles_due_service,

    -- Compliance
    COALESCE(compliance.expired_licenses, 0) AS expired_licenses,
    COALESCE(compliance.expired_medical, 0) AS expired_medical_certs,
    COALESCE(compliance.dvir_defects, 0) AS unresolved_defects

FROM companies c

-- Vehicle and driver counts
LEFT JOIN vehicles v ON c.company_id = v.company_id
LEFT JOIN drivers d ON c.company_id = d.company_id

-- Operations summary
LEFT JOIN (
    SELECT
        v.company_id,
        COUNT(t.trip_id) AS total_trips,
        SUM(t.distance_miles) AS total_miles,
        SUM(t.duration_minutes) / 60 AS total_hours,
        AVG((t.duration_minutes / 60) / 24 * 100) AS avg_utilization
    FROM trips t
    INNER JOIN vehicles v ON t.vehicle_id = v.vehicle_id
    WHERE t.start_time >= DATE_FORMAT(CURDATE(), '%Y-%m-01')
    GROUP BY v.company_id
) ops ON c.company_id = ops.company_id

-- Safety metrics
LEFT JOIN (
    SELECT
        d.company_id,
        COUNT(de.event_id) AS harsh_events,
        AVG(ds.safety_score) AS avg_safety_score,
        COUNT(DISTINCT hv.violation_id) AS hos_violations
    FROM drivers d
    LEFT JOIN driver_events de ON d.driver_id = de.driver_id
        AND de.timestamp >= DATE_FORMAT(CURDATE(), '%Y-%m-01')
    LEFT JOIN driver_scores ds ON d.driver_id = ds.driver_id
        AND ds.score_date >= DATE_FORMAT(CURDATE(), '%Y-%m-01')
    LEFT JOIN hos_violations hv ON d.driver_id = hv.driver_id
        AND hv.violation_date >= DATE_FORMAT(CURDATE(), '%Y-%m-01')
    GROUP BY d.company_id
) safety ON c.company_id = safety.company_id

-- Fuel metrics
LEFT JOIN (
    SELECT
        v.company_id,
        SUM(ft.gallons) AS total_gallons,
        SUM(ft.total_cost) AS total_cost,
        AVG(ft.odometer_miles / NULLIF(ft.gallons, 0)) AS avg_mpg
    FROM fuel_transactions ft
    INNER JOIN vehicles v ON ft.vehicle_id = v.vehicle_id
    WHERE ft.transaction_date >= DATE_FORMAT(CURDATE(), '%Y-%m-01')
    GROUP BY v.company_id
) fuel ON c.company_id = fuel.company_id

-- Maintenance metrics
LEFT JOIN (
    SELECT
        v.company_id,
        COUNT(mr.maintenance_id) AS total_events,
        SUM(mr.total_cost) AS total_cost,
        SUM(CASE WHEN v.odometer_miles >= v.next_service_miles THEN 1 ELSE 0 END) AS vehicles_due_service
    FROM vehicles v
    LEFT JOIN maintenance_records mr ON v.vehicle_id = mr.vehicle_id
        AND mr.service_date >= DATE_FORMAT(CURDATE(), '%Y-%m-01')
    GROUP BY v.company_id
) maint ON c.company_id = maint.company_id

-- Compliance metrics
LEFT JOIN (
    SELECT
        company_id,
        SUM(CASE WHEN license_expiry < CURDATE() THEN 1 ELSE 0 END) AS expired_licenses,
        SUM(CASE WHEN medical_cert_expiry < CURDATE() THEN 1 ELSE 0 END) AS expired_medical,
        0 AS dvir_defects  -- Placeholder
    FROM drivers
    WHERE status = 'active'
    GROUP BY company_id
) compliance ON c.company_id = compliance.company_id

GROUP BY c.company_id;

-- ============================================================================
-- Daily Operations Report
-- ============================================================================

-- Daily fleet activity summary
SELECT
    DATE(t.start_time) AS operation_date,
    COUNT(DISTINCT t.vehicle_id) AS vehicles_used,
    COUNT(DISTINCT t.driver_id) AS drivers_active,
    COUNT(t.trip_id) AS total_trips,
    SUM(t.distance_miles) AS total_miles,
    SUM(t.duration_minutes) / 60 AS total_hours,
    AVG(t.avg_speed_mph) AS avg_speed,
    SUM(t.stops_count) AS total_stops,
    SUM(t.fuel_consumed_gallons) AS fuel_consumed,
    SUM(t.harsh_events_count) AS harsh_events,
    AVG(t.distance_miles / NULLIF(t.fuel_consumed_gallons, 0)) AS avg_mpg
FROM trips t
WHERE t.start_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
  AND t.status = 'completed'
GROUP BY DATE(t.start_time)
ORDER BY operation_date DESC;

-- ============================================================================
-- Driver Performance Report
-- ============================================================================

-- Monthly driver scorecard
SELECT
    CONCAT(d.first_name, ' ', d.last_name) AS driver_name,
    d.license_class,
    d.license_number,
    DATEDIFF(d.license_expiry, CURDATE()) AS days_to_license_expiry,

    -- Activity metrics
    COALESCE(activity.trips, 0) AS trips_completed,
    COALESCE(activity.miles, 0) AS miles_driven,
    COALESCE(activity.hours, 0) AS hours_driven,

    -- Safety metrics
    COALESCE(safety.safety_score, 100) AS safety_score,
    COALESCE(safety.harsh_events, 0) AS harsh_events,
    COALESCE(safety.speeding_events, 0) AS speeding_events,
    COALESCE(safety.events_per_100_miles, 0) AS events_per_100_miles,

    -- Compliance
    COALESCE(compliance.violations, 0) AS hos_violations,
    COALESCE(compliance.uncertified_logs, 0) AS uncertified_logs,

    -- Fuel efficiency
    COALESCE(fuel.avg_mpg, 0) AS avg_mpg,

    -- Overall ranking
    RANK() OVER (ORDER BY safety.safety_score DESC) AS safety_rank

FROM drivers d

-- Activity summary
LEFT JOIN (
    SELECT
        driver_id,
        COUNT(trip_id) AS trips,
        SUM(distance_miles) AS miles,
        SUM(duration_minutes) / 60 AS hours
    FROM trips
    WHERE start_time >= DATE_FORMAT(CURDATE(), '%Y-%m-01')
      AND status = 'completed'
    GROUP BY driver_id
) activity ON d.driver_id = activity.driver_id

-- Safety metrics
LEFT JOIN (
    SELECT
        de.driver_id,
        AVG(ds.safety_score) AS safety_score,
        COUNT(de.event_id) AS harsh_events,
        SUM(CASE WHEN de.event_type = 'speeding' THEN 1 ELSE 0 END) AS speeding_events,
        COUNT(de.event_id) / NULLIF(SUM(t.distance_miles), 0) * 100 AS events_per_100_miles
    FROM driver_events de
    LEFT JOIN driver_scores ds ON de.driver_id = ds.driver_id
        AND ds.score_date >= DATE_FORMAT(CURDATE(), '%Y-%m-01')
    LEFT JOIN trips t ON de.driver_id = t.driver_id
        AND t.start_time >= DATE_FORMAT(CURDATE(), '%Y-%m-01')
    WHERE de.timestamp >= DATE_FORMAT(CURDATE(), '%Y-%m-01')
    GROUP BY de.driver_id
) safety ON d.driver_id = safety.driver_id

-- Compliance metrics
LEFT JOIN (
    SELECT
        dl.driver_id,
        COUNT(hv.violation_id) AS violations,
        SUM(CASE WHEN dl.certified = FALSE THEN 1 ELSE 0 END) AS uncertified_logs
    FROM driver_logs dl
    LEFT JOIN hos_violations hv ON dl.driver_id = hv.driver_id
        AND hv.violation_date >= DATE_FORMAT(CURDATE(), '%Y-%m-01')
    WHERE dl.log_date >= DATE_FORMAT(CURDATE(), '%Y-%m-01')
    GROUP BY dl.driver_id
) compliance ON d.driver_id = compliance.driver_id

-- Fuel efficiency
LEFT JOIN (
    SELECT
        driver_id,
        AVG(distance_miles / NULLIF(fuel_consumed_gallons, 0)) AS avg_mpg
    FROM trips
    WHERE start_time >= DATE_FORMAT(CURDATE(), '%Y-%m-01')
      AND fuel_consumed_gallons > 0
    GROUP BY driver_id
) fuel ON d.driver_id = fuel.driver_id

WHERE d.status = 'active'
ORDER BY safety.safety_score DESC;

-- ============================================================================
-- Vehicle Status Report
-- ============================================================================

-- Comprehensive vehicle status
SELECT
    v.vehicle_number,
    v.vehicle_type,
    v.year,
    v.make,
    v.model,
    v.status,
    v.odometer_miles,

    -- Service status
    v.last_service_date,
    v.odometer_miles - v.last_service_miles AS miles_since_service,
    v.next_service_miles - v.odometer_miles AS miles_to_service,
    CASE
        WHEN v.odometer_miles >= v.next_service_miles THEN 'OVERDUE'
        WHEN v.next_service_miles - v.odometer_miles < 500 THEN 'DUE SOON'
        ELSE 'OK'
    END AS service_status,

    -- Compliance
    DATEDIFF(v.registration_expiry, CURDATE()) AS days_to_registration,
    DATEDIFF(v.insurance_expiry, CURDATE()) AS days_to_insurance,

    -- Usage (last 30 days)
    COALESCE(usage.trips, 0) AS trips_30d,
    COALESCE(usage.miles, 0) AS miles_30d,
    COALESCE(usage.hours, 0) AS hours_30d,
    COALESCE(usage.fuel_gallons, 0) AS fuel_30d,
    COALESCE(usage.mpg, 0) AS mpg_30d,

    -- Maintenance costs (last 90 days)
    COALESCE(maint.events, 0) AS maintenance_events_90d,
    COALESCE(maint.total_cost, 0) AS maintenance_cost_90d,

    -- Current location
    loc.last_location,
    loc.last_seen

FROM vehicles v

-- Usage statistics
LEFT JOIN (
    SELECT
        vehicle_id,
        COUNT(trip_id) AS trips,
        SUM(distance_miles) AS miles,
        SUM(duration_minutes) / 60 AS hours,
        SUM(fuel_consumed_gallons) AS fuel_gallons,
        AVG(distance_miles / NULLIF(fuel_consumed_gallons, 0)) AS mpg
    FROM trips
    WHERE start_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY vehicle_id
) usage ON v.vehicle_id = usage.vehicle_id

-- Maintenance history
LEFT JOIN (
    SELECT
        vehicle_id,
        COUNT(*) AS events,
        SUM(total_cost) AS total_cost
    FROM maintenance_records
    WHERE service_date >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
    GROUP BY vehicle_id
) maint ON v.vehicle_id = maint.vehicle_id

-- Last known location
LEFT JOIN (
    SELECT
        vehicle_id,
        MAX(timestamp) AS last_seen,
        'Location data' AS last_location  -- Placeholder
    FROM gps_positions
    GROUP BY vehicle_id
) loc ON v.vehicle_id = loc.vehicle_id

ORDER BY service_status, v.vehicle_number;

-- ============================================================================
-- Fuel Consumption Report
-- ============================================================================

-- Monthly fuel analysis by vehicle
SELECT
    DATE_FORMAT(ft.transaction_date, '%Y-%m') AS month,
    v.vehicle_number,
    v.vehicle_type,
    COUNT(ft.transaction_id) AS fuel_stops,
    SUM(ft.gallons) AS total_gallons,
    AVG(ft.price_per_gallon) AS avg_price,
    SUM(ft.total_cost) AS total_cost,
    SUM(miles.miles_driven) AS miles_driven,
    AVG(miles.miles_driven / NULLIF(ft.gallons, 0)) AS avg_mpg,
    SUM(ft.total_cost) / NULLIF(SUM(miles.miles_driven), 0) AS cost_per_mile
FROM fuel_transactions ft
INNER JOIN vehicles v ON ft.vehicle_id = v.vehicle_id
LEFT JOIN (
    SELECT
        f1.transaction_id,
        f2.odometer_miles - f1.odometer_miles AS miles_driven
    FROM fuel_transactions f1
    INNER JOIN fuel_transactions f2 ON f1.vehicle_id = f2.vehicle_id
        AND f2.transaction_date = (
            SELECT MIN(transaction_date)
            FROM fuel_transactions
            WHERE vehicle_id = f1.vehicle_id
              AND transaction_date > f1.transaction_date
        )
) miles ON ft.transaction_id = miles.transaction_id
WHERE ft.transaction_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
GROUP BY DATE_FORMAT(ft.transaction_date, '%Y-%m'), v.vehicle_id
ORDER BY month DESC, total_cost DESC;

-- ============================================================================
-- HOS Compliance Report
-- ============================================================================

-- Weekly HOS compliance summary
SELECT
    YEARWEEK(dl.log_date) AS year_week,
    DATE_FORMAT(MIN(dl.log_date), '%Y-%m-%d') AS week_start,
    COUNT(DISTINCT dl.driver_id) AS drivers_logged,
    COUNT(DISTINCT dl.log_id) AS total_logs,

    -- Duty hours
    SUM(CASE WHEN dl.duty_status = 'driving' THEN dl.duration_minutes ELSE 0 END) / 60 AS total_driving_hours,
    SUM(CASE WHEN dl.duty_status IN ('driving', 'on_duty') THEN dl.duration_minutes ELSE 0 END) / 60 AS total_duty_hours,
    SUM(CASE WHEN dl.duty_status IN ('off_duty', 'sleeper') THEN dl.duration_minutes ELSE 0 END) / 60 AS total_rest_hours,

    -- Compliance
    SUM(CASE WHEN dl.certified = TRUE THEN 1 ELSE 0 END) AS certified_logs,
    COUNT(hv.violation_id) AS violations,
    COUNT(DISTINCT hv.driver_id) AS drivers_with_violations,

    -- Violation breakdown
    SUM(CASE WHEN hv.violation_type = '11_hour' THEN 1 ELSE 0 END) AS hour_11_violations,
    SUM(CASE WHEN hv.violation_type = '14_hour' THEN 1 ELSE 0 END) AS hour_14_violations,
    SUM(CASE WHEN hv.violation_type = '30_minute_break' THEN 1 ELSE 0 END) AS break_violations,
    SUM(CASE WHEN hv.violation_type IN ('60_hour_7day', '70_hour_8day') THEN 1 ELSE 0 END) AS weekly_violations

FROM driver_logs dl
LEFT JOIN hos_violations hv ON dl.driver_id = hv.driver_id
    AND DATE(hv.violation_date) = dl.log_date
WHERE dl.log_date >= DATE_SUB(CURDATE(), INTERVAL 12 WEEK)
GROUP BY YEARWEEK(dl.log_date)
ORDER BY year_week DESC;

-- ============================================================================
-- DVIR Compliance Report
-- ============================================================================

-- Daily vehicle inspection summary
SELECT
    dv.inspection_date,
    COUNT(DISTINCT dv.vehicle_id) AS vehicles_inspected,
    COUNT(DISTINCT dv.driver_id) AS drivers_reporting,
    COUNT(dv.dvir_id) AS total_inspections,
    SUM(CASE WHEN dv.inspection_type = 'pre_trip' THEN 1 ELSE 0 END) AS pre_trip,
    SUM(CASE WHEN dv.inspection_type = 'post_trip' THEN 1 ELSE 0 END) AS post_trip,
    SUM(CASE WHEN dv.defects_found = TRUE THEN 1 ELSE 0 END) AS with_defects,
    SUM(CASE WHEN dv.defects_found = TRUE AND dv.repaired = FALSE THEN 1 ELSE 0 END) AS unrepaired_defects,
    GROUP_CONCAT(
        CASE WHEN dv.defects_found = TRUE AND dv.repaired = FALSE
        THEN v.vehicle_number
        ELSE NULL END
        SEPARATOR ', '
    ) AS vehicles_needing_repair
FROM dvir_reports dv
INNER JOIN vehicles v ON dv.vehicle_id = v.vehicle_id
WHERE dv.inspection_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY dv.inspection_date
ORDER BY dv.inspection_date DESC;