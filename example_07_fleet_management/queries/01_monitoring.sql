-- ============================================================================
-- Fleet Management Real-time Monitoring Queries
-- ============================================================================

USE fleet_management;

-- ============================================================================
-- Live Vehicle Tracking Dashboard
-- ============================================================================

-- Current vehicle locations and status
WITH latest_positions AS (
    SELECT
        gp.vehicle_id,
        gp.driver_id,
        gp.timestamp,
        gp.latitude,
        gp.longitude,
        gp.speed_mph,
        gp.heading,
        gp.ignition_on,
        gp.fuel_level_percent,
        ROW_NUMBER() OVER (PARTITION BY gp.vehicle_id ORDER BY gp.timestamp DESC) AS rn
    FROM gps_positions gp
    WHERE gp.timestamp > NOW() - INTERVAL 10 MINUTE
)
SELECT
    v.vehicle_number,
    v.vehicle_type,
    d.depot_name,
    CONCAT(dr.first_name, ' ', dr.last_name) AS driver_name,
    lp.timestamp AS last_update,
    TIMESTAMPDIFF(MINUTE, lp.timestamp, NOW()) AS minutes_since_update,
    lp.latitude,
    lp.longitude,
    lp.speed_mph,
    lp.heading,
    CASE
        WHEN lp.ignition_on = FALSE THEN 'PARKED'
        WHEN lp.speed_mph = 0 THEN 'IDLE'
        WHEN lp.speed_mph > 0 AND lp.speed_mph <= 25 THEN 'CITY'
        WHEN lp.speed_mph > 25 AND lp.speed_mph <= 55 THEN 'SUBURBAN'
        WHEN lp.speed_mph > 55 THEN 'HIGHWAY'
    END AS driving_status,
    lp.fuel_level_percent,
    CASE
        WHEN lp.fuel_level_percent < 10 THEN 'CRITICAL'
        WHEN lp.fuel_level_percent < 25 THEN 'LOW'
        ELSE 'OK'
    END AS fuel_status,
    t.trip_id AS active_trip_id,
    t.start_location,
    t.distance_miles AS trip_distance,
    TIMESTAMPDIFF(MINUTE, t.start_time, NOW()) AS trip_duration_minutes
FROM latest_positions lp
INNER JOIN vehicles v ON lp.vehicle_id = v.vehicle_id
LEFT JOIN depots d ON v.depot_id = d.depot_id
LEFT JOIN drivers dr ON lp.driver_id = dr.driver_id
LEFT JOIN trips t ON v.vehicle_id = t.vehicle_id AND t.status = 'in_progress'
WHERE lp.rn = 1
  AND v.status = 'active'
ORDER BY
    CASE
        WHEN TIMESTAMPDIFF(MINUTE, lp.timestamp, NOW()) > 5 THEN 1
        ELSE 2
    END,
    lp.speed_mph DESC;

-- ============================================================================
-- Active Trips Monitoring
-- ============================================================================

-- Currently active trips with progress
SELECT
    t.trip_id,
    v.vehicle_number,
    CONCAT(d.first_name, ' ', d.last_name) AS driver_name,
    t.start_time,
    TIMESTAMPDIFF(MINUTE, t.start_time, NOW()) AS duration_minutes,
    t.start_location,
    t.distance_miles,
    t.stops_count,
    t.harsh_events_count,
    COALESCE(s.current_stop, 'In Transit') AS current_status,
    COALESCE(s.stop_address, 'On Route') AS current_location,
    COALESCE(ns.next_stop_address, 'Final Destination') AS next_stop
FROM trips t
INNER JOIN vehicles v ON t.vehicle_id = v.vehicle_id
INNER JOIN drivers d ON t.driver_id = d.driver_id
LEFT JOIN (
    SELECT
        trip_id,
        CONCAT('Stop #', stop_sequence, ' - ', stop_type) AS current_stop,
        address AS stop_address
    FROM stops
    WHERE departure_time IS NULL
    ORDER BY arrival_time DESC
    LIMIT 1
) s ON t.trip_id = s.trip_id
LEFT JOIN (
    SELECT
        trip_id,
        MIN(stop_sequence) AS next_sequence,
        address AS next_stop_address
    FROM stops
    WHERE arrival_time > NOW()
    GROUP BY trip_id
) ns ON t.trip_id = ns.trip_id
WHERE t.status = 'in_progress'
ORDER BY t.start_time;

-- ============================================================================
-- Driver Behavior Monitoring
-- ============================================================================

-- Recent driver events and violations
SELECT
    de.event_id,
    v.vehicle_number,
    CONCAT(d.first_name, ' ', d.last_name) AS driver_name,
    de.event_type,
    de.timestamp,
    TIMESTAMPDIFF(MINUTE, de.timestamp, NOW()) AS minutes_ago,
    de.severity,
    de.speed_mph,
    de.g_force,
    de.speed_limit_mph,
    CASE
        WHEN de.event_type = 'speeding' THEN CONCAT('Exceeded limit by ', de.speed_mph - de.speed_limit_mph, ' mph')
        WHEN de.event_type = 'harsh_brake' THEN CONCAT('G-force: ', de.g_force)
        WHEN de.event_type = 'harsh_acceleration' THEN CONCAT('G-force: ', de.g_force)
        WHEN de.event_type = 'idle_excessive' THEN CONCAT('Duration: ', de.duration_seconds, ' seconds')
        ELSE 'Check details'
    END AS event_details,
    de.latitude,
    de.longitude
FROM driver_events de
INNER JOIN vehicles v ON de.vehicle_id = v.vehicle_id
INNER JOIN drivers d ON de.driver_id = d.driver_id
WHERE de.timestamp > NOW() - INTERVAL 2 HOUR
ORDER BY de.timestamp DESC
LIMIT 50;

-- Real-time driver scores
SELECT
    CONCAT(d.first_name, ' ', d.last_name) AS driver_name,
    d.license_class,
    ds.score_date,
    ds.safety_score,
    ds.fuel_efficiency_score,
    ds.compliance_score,
    ds.overall_score,
    CASE
        WHEN ds.overall_score >= 90 THEN 'EXCELLENT'
        WHEN ds.overall_score >= 80 THEN 'GOOD'
        WHEN ds.overall_score >= 70 THEN 'FAIR'
        ELSE 'NEEDS IMPROVEMENT'
    END AS rating,
    ds.miles_driven,
    ds.harsh_events_count,
    ds.speeding_minutes,
    ds.idle_minutes,
    RANK() OVER (ORDER BY ds.overall_score DESC) AS fleet_rank
FROM drivers d
INNER JOIN driver_scores ds ON d.driver_id = ds.driver_id
WHERE ds.score_date = CURDATE()
  AND d.status = 'active'
ORDER BY ds.overall_score DESC;

-- ============================================================================
-- HOS Compliance Monitoring
-- ============================================================================

-- Current driver duty status
WITH current_duty AS (
    SELECT
        dl.driver_id,
        dl.duty_status,
        dl.start_time,
        dl.location,
        TIMESTAMPDIFF(MINUTE, dl.start_time, NOW()) AS minutes_in_status,
        ROW_NUMBER() OVER (PARTITION BY dl.driver_id ORDER BY dl.start_time DESC) AS rn
    FROM driver_logs dl
    WHERE dl.end_time IS NULL
)
SELECT
    CONCAT(d.first_name, ' ', d.last_name) AS driver_name,
    cd.duty_status,
    cd.start_time,
    cd.minutes_in_status,
    cd.location,
    -- Calculate remaining hours
    CASE cd.duty_status
        WHEN 'driving' THEN
            GREATEST(0, 660 - COALESCE(driving_time.total_minutes, 0)) / 60
        WHEN 'on_duty' THEN
            GREATEST(0, 840 - COALESCE(duty_time.total_minutes, 0)) / 60
        ELSE NULL
    END AS hours_remaining,
    -- Check for required breaks
    CASE
        WHEN cd.duty_status IN ('driving', 'on_duty')
             AND NOT EXISTS (
                 SELECT 1 FROM driver_logs
                 WHERE driver_id = cd.driver_id
                   AND duty_status IN ('off_duty', 'sleeper')
                   AND duration_minutes >= 30
                   AND start_time > NOW() - INTERVAL 8 HOUR
             )
             AND cd.minutes_in_status > 480
        THEN 'BREAK REQUIRED'
        ELSE 'OK'
    END AS break_status,
    v.recent_violations
FROM current_duty cd
INNER JOIN drivers d ON cd.driver_id = d.driver_id
LEFT JOIN (
    SELECT driver_id, SUM(duration_minutes) AS total_minutes
    FROM driver_logs
    WHERE duty_status = 'driving'
      AND start_time > NOW() - INTERVAL 11 HOUR
    GROUP BY driver_id
) driving_time ON cd.driver_id = driving_time.driver_id
LEFT JOIN (
    SELECT driver_id, SUM(duration_minutes) AS total_minutes
    FROM driver_logs
    WHERE duty_status IN ('driving', 'on_duty')
      AND start_time > NOW() - INTERVAL 14 HOUR
    GROUP BY driver_id
) duty_time ON cd.driver_id = duty_time.driver_id
LEFT JOIN (
    SELECT driver_id, COUNT(*) AS recent_violations
    FROM hos_violations
    WHERE violation_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
      AND resolved = FALSE
    GROUP BY driver_id
) v ON cd.driver_id = v.driver_id
WHERE cd.rn = 1
  AND d.status = 'active'
ORDER BY hours_remaining ASC;

-- ============================================================================
-- Vehicle Health Monitoring
-- ============================================================================

-- Vehicle diagnostics alerts
SELECT
    v.vehicle_number,
    v.vehicle_type,
    vd.timestamp,
    vd.check_engine_light,
    vd.engine_rpm,
    vd.engine_load_percent,
    vd.coolant_temp_f,
    vd.oil_pressure_psi,
    vd.battery_voltage,
    JSON_LENGTH(vd.dtc_codes) AS dtc_count,
    vd.dtc_codes,
    CASE
        WHEN vd.check_engine_light = TRUE THEN 'CHECK ENGINE'
        WHEN vd.coolant_temp_f > 230 THEN 'OVERHEATING'
        WHEN vd.oil_pressure_psi < 20 THEN 'LOW OIL PRESSURE'
        WHEN vd.battery_voltage < 12.0 THEN 'LOW BATTERY'
        ELSE 'OK'
    END AS alert_status,
    DATEDIFF(v.registration_expiry, CURDATE()) AS days_to_registration,
    DATEDIFF(v.insurance_expiry, CURDATE()) AS days_to_insurance,
    v.odometer_miles - v.last_service_miles AS miles_since_service
FROM vehicles v
INNER JOIN (
    SELECT
        vehicle_id,
        timestamp,
        check_engine_light,
        engine_rpm,
        engine_load_percent,
        coolant_temp_f,
        oil_pressure_psi,
        battery_voltage,
        dtc_codes,
        ROW_NUMBER() OVER (PARTITION BY vehicle_id ORDER BY timestamp DESC) AS rn
    FROM vehicle_diagnostics
    WHERE timestamp > NOW() - INTERVAL 1 HOUR
) vd ON v.vehicle_id = vd.vehicle_id AND vd.rn = 1
WHERE v.status = 'active'
  AND (vd.check_engine_light = TRUE
       OR vd.coolant_temp_f > 230
       OR vd.oil_pressure_psi < 20
       OR vd.battery_voltage < 12.0
       OR JSON_LENGTH(vd.dtc_codes) > 0)
ORDER BY alert_status, v.vehicle_number;

-- ============================================================================
-- Geofence Activity Monitoring
-- ============================================================================

-- Recent geofence events
SELECT
    ge.event_id,
    g.geofence_name,
    g.geofence_type,
    v.vehicle_number,
    CONCAT(d.first_name, ' ', d.last_name) AS driver_name,
    ge.event_type,
    ge.timestamp,
    TIMESTAMPDIFF(MINUTE, ge.timestamp, NOW()) AS minutes_ago,
    ge.duration_minutes AS time_inside_minutes,
    CASE g.geofence_type
        WHEN 'depot' THEN
            CASE ge.event_type
                WHEN 'enter' THEN 'Returned to depot'
                WHEN 'exit' THEN 'Departed from depot'
            END
        WHEN 'customer' THEN
            CASE ge.event_type
                WHEN 'enter' THEN 'Arrived at customer'
                WHEN 'exit' THEN 'Left customer site'
            END
        WHEN 'restricted' THEN
            CASE ge.event_type
                WHEN 'enter' THEN '⚠️ ENTERED RESTRICTED ZONE'
                WHEN 'exit' THEN 'Exited restricted zone'
            END
        ELSE ge.event_type
    END AS event_description
FROM geofence_events ge
INNER JOIN geofences g ON ge.geofence_id = g.geofence_id
INNER JOIN vehicles v ON ge.vehicle_id = v.vehicle_id
LEFT JOIN drivers d ON ge.driver_id = d.driver_id
WHERE ge.timestamp > NOW() - INTERVAL 2 HOUR
ORDER BY ge.timestamp DESC
LIMIT 30;

-- ============================================================================
-- Fuel Monitoring
-- ============================================================================

-- Recent fuel transactions and efficiency
SELECT
    ft.transaction_id,
    v.vehicle_number,
    CONCAT(d.first_name, ' ', d.last_name) AS driver_name,
    ft.transaction_date,
    ft.station_name,
    ft.gallons,
    ft.price_per_gallon,
    ft.total_cost,
    ft.odometer_miles,
    ft.odometer_miles - LAG(ft.odometer_miles) OVER (PARTITION BY ft.vehicle_id ORDER BY ft.transaction_date) AS miles_since_last,
    ft.gallons / NULLIF(ft.odometer_miles - LAG(ft.odometer_miles) OVER (PARTITION BY ft.vehicle_id ORDER BY ft.transaction_date), 0) * 100 AS mpg,
    ft.payment_method
FROM fuel_transactions ft
INNER JOIN vehicles v ON ft.vehicle_id = v.vehicle_id
LEFT JOIN drivers d ON ft.driver_id = d.driver_id
WHERE ft.transaction_date > NOW() - INTERVAL 24 HOUR
ORDER BY ft.transaction_date DESC;

-- ============================================================================
-- DVIR Compliance Monitoring
-- ============================================================================

-- Today's inspection reports with defects
SELECT
    dv.dvir_id,
    v.vehicle_number,
    CONCAT(d.first_name, ' ', d.last_name) AS driver_name,
    dv.inspection_type,
    dv.inspection_date,
    dv.defects_found,
    dv.defect_details,
    dv.signature_driver,
    dv.repaired,
    dv.repair_date,
    CASE
        WHEN dv.defects_found = TRUE AND dv.repaired = FALSE THEN 'NEEDS REPAIR'
        WHEN dv.defects_found = TRUE AND dv.repaired = TRUE THEN 'REPAIRED'
        ELSE 'PASS'
    END AS status
FROM dvir_reports dv
INNER JOIN vehicles v ON dv.vehicle_id = v.vehicle_id
INNER JOIN drivers d ON dv.driver_id = d.driver_id
WHERE dv.inspection_date = CURDATE()
ORDER BY dv.defects_found DESC, dv.inspection_type;