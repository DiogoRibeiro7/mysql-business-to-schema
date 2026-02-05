-- ============================================================================
-- Fleet Management Advanced Analytics & Predictions
-- ============================================================================

USE fleet_management;

-- ============================================================================
-- Predictive Maintenance Analytics
-- ============================================================================

-- Vehicle failure prediction based on diagnostic patterns
WITH diagnostic_patterns AS (
    SELECT
        vd.vehicle_id,
        COUNT(DISTINCT DATE(vd.timestamp)) AS days_with_issues,
        AVG(vd.engine_load_percent) AS avg_engine_load,
        MAX(vd.coolant_temp_f) AS max_coolant_temp,
        MIN(vd.oil_pressure_psi) AS min_oil_pressure,
        AVG(vd.battery_voltage) AS avg_battery_voltage,
        SUM(CASE WHEN vd.check_engine_light = TRUE THEN 1 ELSE 0 END) AS check_engine_days,
        JSON_LENGTH(JSON_ARRAYAGG(DISTINCT JSON_EXTRACT(vd.dtc_codes, '$[*]'))) AS unique_dtc_codes
    FROM vehicle_diagnostics vd
    WHERE vd.timestamp >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY vd.vehicle_id
),
maintenance_history AS (
    SELECT
        mr.vehicle_id,
        COUNT(CASE WHEN mr.maintenance_type = 'repair' THEN 1 END) AS repair_count,
        AVG(CASE WHEN mr.maintenance_type = 'repair'
            THEN DATEDIFF(mr.service_date, LAG(mr.service_date)
                OVER (PARTITION BY mr.vehicle_id ORDER BY mr.service_date))
            END) AS avg_days_between_repairs,
        SUM(mr.total_cost) AS total_maintenance_cost,
        MAX(mr.service_date) AS last_service_date
    FROM maintenance_records mr
    WHERE mr.service_date >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
    GROUP BY mr.vehicle_id
),
vehicle_usage AS (
    SELECT
        t.vehicle_id,
        SUM(t.distance_miles) AS total_miles_30d,
        AVG(t.harsh_events_count / NULLIF(t.distance_miles, 0)) AS harsh_events_per_mile,
        AVG(t.idle_time_minutes / NULLIF(t.duration_minutes, 0)) AS idle_ratio
    FROM trips t
    WHERE t.start_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY t.vehicle_id
)
SELECT
    v.vehicle_number,
    v.vehicle_type,
    v.year,
    v.odometer_miles,
    DATEDIFF(CURDATE(), mh.last_service_date) AS days_since_service,
    v.odometer_miles - v.last_service_miles AS miles_since_service,
    -- Risk scoring
    (
        CASE WHEN dp.check_engine_days > 5 THEN 3 ELSE 0 END +
        CASE WHEN dp.max_coolant_temp > 230 THEN 2 ELSE 0 END +
        CASE WHEN dp.min_oil_pressure < 25 THEN 2 ELSE 0 END +
        CASE WHEN dp.unique_dtc_codes > 3 THEN 2 ELSE 0 END +
        CASE WHEN mh.repair_count > 2 THEN 2 ELSE 0 END +
        CASE WHEN v.odometer_miles > 100000 THEN 1 ELSE 0 END +
        CASE WHEN vu.harsh_events_per_mile > 0.1 THEN 1 ELSE 0 END +
        CASE WHEN v.odometer_miles - v.last_service_miles > 5000 THEN 1 ELSE 0 END
    ) AS risk_score,
    CASE
        WHEN (
            CASE WHEN dp.check_engine_days > 5 THEN 3 ELSE 0 END +
            CASE WHEN dp.max_coolant_temp > 230 THEN 2 ELSE 0 END +
            CASE WHEN dp.min_oil_pressure < 25 THEN 2 ELSE 0 END +
            CASE WHEN dp.unique_dtc_codes > 3 THEN 2 ELSE 0 END +
            CASE WHEN mh.repair_count > 2 THEN 2 ELSE 0 END +
            CASE WHEN v.odometer_miles > 100000 THEN 1 ELSE 0 END +
            CASE WHEN vu.harsh_events_per_mile > 0.1 THEN 1 ELSE 0 END +
            CASE WHEN v.odometer_miles - v.last_service_miles > 5000 THEN 1 ELSE 0 END
        ) >= 8 THEN 'CRITICAL - Schedule immediate maintenance'
        WHEN (
            CASE WHEN dp.check_engine_days > 5 THEN 3 ELSE 0 END +
            CASE WHEN dp.max_coolant_temp > 230 THEN 2 ELSE 0 END +
            CASE WHEN dp.min_oil_pressure < 25 THEN 2 ELSE 0 END +
            CASE WHEN dp.unique_dtc_codes > 3 THEN 2 ELSE 0 END +
            CASE WHEN mh.repair_count > 2 THEN 2 ELSE 0 END +
            CASE WHEN v.odometer_miles > 100000 THEN 1 ELSE 0 END +
            CASE WHEN vu.harsh_events_per_mile > 0.1 THEN 1 ELSE 0 END +
            CASE WHEN v.odometer_miles - v.last_service_miles > 5000 THEN 1 ELSE 0 END
        ) >= 5 THEN 'HIGH - Monitor closely'
        WHEN (
            CASE WHEN dp.check_engine_days > 5 THEN 3 ELSE 0 END +
            CASE WHEN dp.max_coolant_temp > 230 THEN 2 ELSE 0 END +
            CASE WHEN dp.min_oil_pressure < 25 THEN 2 ELSE 0 END +
            CASE WHEN dp.unique_dtc_codes > 3 THEN 2 ELSE 0 END +
            CASE WHEN mh.repair_count > 2 THEN 2 ELSE 0 END +
            CASE WHEN v.odometer_miles > 100000 THEN 1 ELSE 0 END +
            CASE WHEN vu.harsh_events_per_mile > 0.1 THEN 1 ELSE 0 END +
            CASE WHEN v.odometer_miles - v.last_service_miles > 5000 THEN 1 ELSE 0 END
        ) >= 3 THEN 'MEDIUM - Plan maintenance'
        ELSE 'LOW - Normal operation'
    END AS maintenance_recommendation,
    -- Estimated days until failure (simplified model)
    GREATEST(
        7,
        LEAST(
            90,
            90 - (
                (dp.check_engine_days * 3) +
                (mh.repair_count * 10) +
                (CASE WHEN dp.max_coolant_temp > 220 THEN (dp.max_coolant_temp - 220) ELSE 0 END)
            )
        )
    ) AS estimated_days_to_failure,
    mh.total_maintenance_cost AS recent_maintenance_cost,
    ROUND(mh.total_maintenance_cost / NULLIF(vu.total_miles_30d, 0), 2) AS cost_per_mile
FROM vehicles v
LEFT JOIN diagnostic_patterns dp ON v.vehicle_id = dp.vehicle_id
LEFT JOIN maintenance_history mh ON v.vehicle_id = mh.vehicle_id
LEFT JOIN vehicle_usage vu ON v.vehicle_id = vu.vehicle_id
WHERE v.status = 'active'
ORDER BY risk_score DESC, estimated_days_to_failure ASC;

-- ============================================================================
-- Route Optimization Analytics
-- ============================================================================

-- Route efficiency analysis with recommendations
WITH route_performance AS (
    SELECT
        r.route_id,
        r.route_name,
        r.distance_miles AS planned_distance,
        AVG(t.distance_miles) AS actual_avg_distance,
        AVG(t.duration_minutes) AS avg_duration,
        AVG(t.fuel_consumed_gallons) AS avg_fuel,
        STD(t.duration_minutes) AS duration_variability,
        COUNT(DISTINCT t.trip_id) AS trip_count,
        AVG(t.stops_count) AS avg_stops,
        AVG(t.idle_time_minutes) AS avg_idle_time
    FROM routes r
    LEFT JOIN trips t ON calculate_distance(
            t.start_latitude, t.start_longitude,
            JSON_EXTRACT(r.waypoints, '$[0].lat'),
            JSON_EXTRACT(r.waypoints, '$[0].lng')
        ) < 1  -- Within 1km of route start
    WHERE r.is_active = TRUE
      AND t.start_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY r.route_id
),
traffic_patterns AS (
    SELECT
        r.route_id,
        HOUR(t.start_time) AS hour_of_day,
        AVG(t.avg_speed_mph) AS avg_speed,
        AVG(t.duration_minutes) AS avg_duration
    FROM routes r
    LEFT JOIN trips t ON calculate_distance(
            t.start_latitude, t.start_longitude,
            JSON_EXTRACT(r.waypoints, '$[0].lat'),
            JSON_EXTRACT(r.waypoints, '$[0].lng')
        ) < 1
    WHERE r.is_active = TRUE
      AND t.start_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY r.route_id, HOUR(t.start_time)
),
best_times AS (
    SELECT
        route_id,
        hour_of_day AS optimal_start_hour,
        avg_speed,
        avg_duration,
        ROW_NUMBER() OVER (PARTITION BY route_id ORDER BY avg_speed DESC) AS speed_rank
    FROM traffic_patterns
)
SELECT
    rp.route_name,
    rp.trip_count AS trips_last_30_days,
    ROUND(rp.planned_distance, 1) AS planned_miles,
    ROUND(rp.actual_avg_distance, 1) AS actual_avg_miles,
    ROUND(rp.actual_avg_distance - rp.planned_distance, 1) AS avg_deviation_miles,
    ROUND(rp.avg_duration, 0) AS avg_duration_minutes,
    ROUND(rp.duration_variability, 0) AS duration_std_dev,
    ROUND(rp.avg_fuel, 2) AS avg_fuel_gallons,
    ROUND(rp.actual_avg_distance / NULLIF(rp.avg_fuel, 0), 1) AS route_mpg,
    ROUND(rp.avg_idle_time, 0) AS avg_idle_minutes,
    ROUND((rp.avg_idle_time / NULLIF(rp.avg_duration, 0)) * 100, 1) AS idle_percentage,
    bt.optimal_start_hour,
    CONCAT(
        CASE
            WHEN rp.duration_variability > 30 THEN 'High variability - consider traffic analysis. '
            ELSE ''
        END,
        CASE
            WHEN rp.actual_avg_distance > rp.planned_distance * 1.1 THEN 'Route deviation detected - review driver routing. '
            ELSE ''
        END,
        CASE
            WHEN rp.avg_idle_time > rp.avg_duration * 0.2 THEN 'Excessive idle time - optimize stop sequence. '
            ELSE ''
        END,
        CASE
            WHEN rp.avg_fuel > (rp.actual_avg_distance / 8) THEN 'Poor fuel efficiency - check vehicle assignment. '
            ELSE ''
        END
    ) AS recommendations
FROM route_performance rp
LEFT JOIN best_times bt ON rp.route_id = bt.route_id AND bt.speed_rank = 1
ORDER BY rp.trip_count DESC;

-- ============================================================================
-- Driver Risk Profiling
-- ============================================================================

-- Comprehensive driver risk assessment
WITH driver_metrics AS (
    SELECT
        d.driver_id,
        CONCAT(d.first_name, ' ', d.last_name) AS driver_name,
        d.license_class,
        COUNT(DISTINCT t.trip_id) AS total_trips,
        SUM(t.distance_miles) AS total_miles,
        AVG(t.max_speed_mph) AS avg_max_speed,
        SUM(t.harsh_events_count) AS total_harsh_events,
        AVG(ds.safety_score) AS avg_safety_score,
        COUNT(hv.violation_id) AS hos_violations,
        COUNT(DISTINCT DATE(de.timestamp)) AS days_with_events
    FROM drivers d
    LEFT JOIN trips t ON d.driver_id = t.driver_id
        AND t.start_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    LEFT JOIN driver_scores ds ON d.driver_id = ds.driver_id
        AND ds.score_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    LEFT JOIN hos_violations hv ON d.driver_id = hv.driver_id
        AND hv.violation_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    LEFT JOIN driver_events de ON d.driver_id = de.driver_id
        AND de.timestamp >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
        AND de.severity IN ('high', 'medium')
    WHERE d.status = 'active'
    GROUP BY d.driver_id
),
event_patterns AS (
    SELECT
        driver_id,
        event_type,
        COUNT(*) AS event_count,
        AVG(CASE
            WHEN severity = 'high' THEN 3
            WHEN severity = 'medium' THEN 2
            ELSE 1
        END) AS avg_severity
    FROM driver_events
    WHERE timestamp >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY driver_id, event_type
),
risk_factors AS (
    SELECT
        dm.driver_id,
        dm.driver_name,
        dm.license_class,
        dm.total_trips,
        dm.total_miles,
        -- Calculate risk score (0-100)
        LEAST(100, GREATEST(0,
            100 - dm.avg_safety_score +
            (dm.total_harsh_events / NULLIF(dm.total_miles, 0) * 1000) +
            (dm.hos_violations * 5) +
            (dm.days_with_events * 2) +
            CASE WHEN dm.avg_max_speed > 75 THEN 10 ELSE 0 END
        )) AS risk_score,
        dm.avg_safety_score,
        ROUND(dm.total_harsh_events / NULLIF(dm.total_miles, 0) * 100, 2) AS events_per_100_miles,
        dm.hos_violations,
        -- Get most frequent event type
        (SELECT event_type
         FROM event_patterns ep
         WHERE ep.driver_id = dm.driver_id
         ORDER BY event_count DESC
         LIMIT 1) AS most_common_event
    FROM driver_metrics dm
)
SELECT
    driver_name,
    license_class,
    total_trips,
    ROUND(total_miles, 0) AS total_miles,
    ROUND(risk_score, 1) AS risk_score,
    CASE
        WHEN risk_score >= 70 THEN 'HIGH RISK'
        WHEN risk_score >= 40 THEN 'MODERATE RISK'
        ELSE 'LOW RISK'
    END AS risk_category,
    ROUND(avg_safety_score, 1) AS safety_score,
    events_per_100_miles,
    hos_violations,
    most_common_event,
    CASE
        WHEN risk_score >= 70 THEN 'Immediate coaching required. Consider suspension pending review.'
        WHEN risk_score >= 50 THEN 'Schedule defensive driving training. Increase monitoring.'
        WHEN risk_score >= 40 THEN 'Monitor closely. Provide feedback on specific behaviors.'
        WHEN risk_score >= 20 THEN 'Continue regular monitoring. Positive reinforcement.'
        ELSE 'Excellent driver. Consider for recognition program.'
    END AS recommendation,
    RANK() OVER (ORDER BY risk_score DESC) AS risk_rank,
    RANK() OVER (ORDER BY avg_safety_score DESC) AS safety_rank
FROM risk_factors
ORDER BY risk_score DESC;

-- ============================================================================
-- Fuel Optimization Opportunities
-- ============================================================================

-- Identify fuel waste and optimization opportunities
WITH fuel_analysis AS (
    SELECT
        v.vehicle_id,
        v.vehicle_number,
        v.vehicle_type,
        v.fuel_capacity_gallons,
        AVG(ft.price_per_gallon) AS avg_fuel_price,
        SUM(ft.gallons) AS total_gallons,
        SUM(ft.total_cost) AS total_fuel_cost,
        COUNT(ft.transaction_id) AS fuel_stops,
        AVG(t.distance_miles / NULLIF(t.fuel_consumed_gallons, 0)) AS avg_mpg,
        STD(t.distance_miles / NULLIF(t.fuel_consumed_gallons, 0)) AS mpg_variance,
        AVG(t.idle_time_minutes) AS avg_idle_time,
        SUM(t.idle_time_minutes * 0.5 / 60) AS idle_fuel_gallons -- Assume 0.5 gal/hr idle
    FROM vehicles v
    LEFT JOIN fuel_transactions ft ON v.vehicle_id = ft.vehicle_id
        AND ft.transaction_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    LEFT JOIN trips t ON v.vehicle_id = t.vehicle_id
        AND t.start_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    WHERE v.status = 'active'
    GROUP BY v.vehicle_id
),
benchmarks AS (
    SELECT
        vehicle_type,
        AVG(avg_mpg) AS type_avg_mpg,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY avg_mpg) AS top_quartile_mpg
    FROM fuel_analysis fa
    INNER JOIN vehicles v ON fa.vehicle_id = v.vehicle_id
    GROUP BY vehicle_type
)
SELECT
    fa.vehicle_number,
    fa.vehicle_type,
    fa.fuel_stops AS fuel_stops_30d,
    ROUND(fa.total_gallons, 1) AS gallons_30d,
    ROUND(fa.total_fuel_cost, 2) AS fuel_cost_30d,
    ROUND(fa.avg_mpg, 2) AS vehicle_mpg,
    ROUND(b.type_avg_mpg, 2) AS fleet_avg_mpg,
    ROUND(b.top_quartile_mpg, 2) AS best_practice_mpg,
    ROUND(fa.avg_mpg - b.type_avg_mpg, 2) AS mpg_vs_avg,
    ROUND(fa.idle_fuel_gallons, 1) AS idle_fuel_gallons,
    ROUND(fa.idle_fuel_gallons * fa.avg_fuel_price, 2) AS idle_fuel_cost,
    -- Potential savings
    ROUND(
        CASE
            WHEN fa.avg_mpg < b.type_avg_mpg THEN
                fa.total_fuel_cost - (fa.total_fuel_cost * b.type_avg_mpg / NULLIF(fa.avg_mpg, 0))
            ELSE 0
        END, 2
    ) AS potential_savings,
    -- Recommendations
    CONCAT(
        CASE
            WHEN fa.avg_mpg < b.type_avg_mpg * 0.8 THEN 'URGENT: Vehicle performing 20%+ below average. '
            WHEN fa.avg_mpg < b.type_avg_mpg * 0.9 THEN 'Vehicle underperforming. '
            ELSE ''
        END,
        CASE
            WHEN fa.idle_fuel_gallons > 10 THEN 'High idle time detected. '
            ELSE ''
        END,
        CASE
            WHEN fa.mpg_variance > 2 THEN 'Inconsistent driving patterns. '
            ELSE ''
        END,
        CASE
            WHEN fa.fuel_stops > 20 THEN 'Consider fuel card policy review. '
            ELSE ''
        END
    ) AS optimization_recommendations
FROM fuel_analysis fa
INNER JOIN benchmarks b ON fa.vehicle_type = b.vehicle_type
WHERE fa.total_gallons > 0
ORDER BY potential_savings DESC;

-- ============================================================================
-- Geofence Analytics & Unauthorized Usage
-- ============================================================================

-- Detect unauthorized vehicle usage patterns
WITH after_hours AS (
    SELECT
        gp.vehicle_id,
        gp.driver_id,
        COUNT(*) AS after_hours_positions,
        MIN(gp.timestamp) AS first_activity,
        MAX(gp.timestamp) AS last_activity,
        AVG(gp.speed_mph) AS avg_speed,
        MAX(calculate_distance(
            gp.latitude, gp.longitude,
            d.latitude, d.longitude
        )) AS max_distance_from_depot
    FROM gps_positions gp
    CROSS JOIN (
        SELECT latitude, longitude
        FROM depots
        WHERE depot_id = (SELECT depot_id FROM vehicles WHERE vehicle_id = gp.vehicle_id)
    ) d
    WHERE (HOUR(gp.timestamp) < 6 OR HOUR(gp.timestamp) > 20)  -- After hours
      AND gp.ignition_on = TRUE
      AND gp.timestamp >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
    GROUP BY gp.vehicle_id, gp.driver_id
),
weekend_usage AS (
    SELECT
        t.vehicle_id,
        t.driver_id,
        COUNT(*) AS weekend_trips,
        SUM(t.distance_miles) AS weekend_miles,
        SUM(t.duration_minutes) AS weekend_minutes
    FROM trips t
    WHERE DAYOFWEEK(t.start_time) IN (1, 7)  -- Sunday, Saturday
      AND t.start_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY t.vehicle_id, t.driver_id
),
restricted_zones AS (
    SELECT
        ge.vehicle_id,
        ge.driver_id,
        g.geofence_name,
        COUNT(*) AS violations,
        SUM(ge.duration_minutes) AS total_duration
    FROM geofence_events ge
    INNER JOIN geofences g ON ge.geofence_id = g.geofence_id
    WHERE g.geofence_type = 'restricted'
      AND ge.event_type = 'enter'
      AND ge.timestamp >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY ge.vehicle_id, ge.driver_id, g.geofence_id
)
SELECT
    v.vehicle_number,
    COALESCE(CONCAT(d.first_name, ' ', d.last_name), 'Unknown') AS driver_name,
    COALESCE(ah.after_hours_positions, 0) AS after_hours_events,
    COALESCE(wu.weekend_trips, 0) AS weekend_trips,
    COALESCE(wu.weekend_miles, 0) AS weekend_miles,
    COALESCE(rz.violations, 0) AS restricted_zone_violations,
    CASE
        WHEN ah.after_hours_positions > 10 OR wu.weekend_trips > 5 THEN 'HIGH'
        WHEN ah.after_hours_positions > 5 OR wu.weekend_trips > 2 THEN 'MEDIUM'
        WHEN ah.after_hours_positions > 0 OR wu.weekend_trips > 0 THEN 'LOW'
        ELSE 'NONE'
    END AS unauthorized_risk_level,
    CONCAT(
        CASE WHEN ah.after_hours_positions > 10 THEN 'Excessive after-hours usage. ' ELSE '' END,
        CASE WHEN wu.weekend_trips > 5 THEN 'High weekend activity. ' ELSE '' END,
        CASE WHEN rz.violations > 0 THEN CONCAT('Entered restricted zones ', rz.violations, ' times. ') ELSE '' END,
        CASE WHEN ah.max_distance_from_depot > 50 THEN 'Vehicle traveled far from depot after hours. ' ELSE '' END
    ) AS alerts
FROM vehicles v
LEFT JOIN after_hours ah ON v.vehicle_id = ah.vehicle_id
LEFT JOIN weekend_usage wu ON v.vehicle_id = wu.vehicle_id
LEFT JOIN restricted_zones rz ON v.vehicle_id = rz.vehicle_id
LEFT JOIN drivers d ON COALESCE(ah.driver_id, wu.driver_id, rz.driver_id) = d.driver_id
WHERE v.status = 'active'
  AND (ah.after_hours_positions > 0 OR wu.weekend_trips > 0 OR rz.violations > 0)
ORDER BY unauthorized_risk_level DESC, ah.after_hours_positions DESC;

-- ============================================================================
-- Fleet TCO (Total Cost of Ownership) Analysis
-- ============================================================================

-- Calculate total cost of ownership per vehicle
WITH vehicle_costs AS (
    SELECT
        v.vehicle_id,
        v.vehicle_number,
        v.vehicle_type,
        v.year,
        v.purchase_price,
        v.odometer_miles,
        DATEDIFF(CURDATE(), v.created_at) AS days_owned,
        -- Fuel costs
        COALESCE(SUM(ft.total_cost), 0) AS fuel_cost_ytd,
        -- Maintenance costs
        COALESCE(SUM(mr.total_cost), 0) AS maintenance_cost_ytd,
        -- Insurance (estimated)
        (v.purchase_price * 0.05 / 365) * DATEDIFF(CURDATE(), DATE_FORMAT(CURDATE(), '%Y-01-01')) AS insurance_cost_ytd,
        -- Depreciation (straight line over 5 years)
        (v.purchase_price * 0.2 / 365) * DATEDIFF(CURDATE(), DATE_FORMAT(CURDATE(), '%Y-01-01')) AS depreciation_ytd,
        -- Usage metrics
        SUM(t.distance_miles) AS miles_ytd,
        SUM(t.duration_minutes) / 60 AS hours_operated_ytd
    FROM vehicles v
    LEFT JOIN fuel_transactions ft ON v.vehicle_id = ft.vehicle_id
        AND ft.transaction_date >= DATE_FORMAT(CURDATE(), '%Y-01-01')
    LEFT JOIN maintenance_records mr ON v.vehicle_id = mr.vehicle_id
        AND mr.service_date >= DATE_FORMAT(CURDATE(), '%Y-01-01')
    LEFT JOIN trips t ON v.vehicle_id = t.vehicle_id
        AND t.start_time >= DATE_FORMAT(CURDATE(), '%Y-01-01')
    WHERE v.status != 'retired'
    GROUP BY v.vehicle_id
)
SELECT
    vehicle_number,
    vehicle_type,
    year,
    FORMAT(purchase_price, 2) AS purchase_price,
    ROUND(odometer_miles, 0) AS odometer_miles,
    days_owned,
    ROUND(miles_ytd, 0) AS miles_ytd,
    ROUND(hours_operated_ytd, 0) AS hours_ytd,
    ROUND(fuel_cost_ytd, 2) AS fuel_cost_ytd,
    ROUND(maintenance_cost_ytd, 2) AS maintenance_cost_ytd,
    ROUND(insurance_cost_ytd, 2) AS insurance_est_ytd,
    ROUND(depreciation_ytd, 2) AS depreciation_ytd,
    ROUND(fuel_cost_ytd + maintenance_cost_ytd + insurance_cost_ytd + depreciation_ytd, 2) AS total_cost_ytd,
    ROUND((fuel_cost_ytd + maintenance_cost_ytd + insurance_cost_ytd + depreciation_ytd) / NULLIF(miles_ytd, 0), 3) AS cost_per_mile,
    ROUND((fuel_cost_ytd + maintenance_cost_ytd + insurance_cost_ytd + depreciation_ytd) / NULLIF(hours_operated_ytd, 0), 2) AS cost_per_hour,
    CASE
        WHEN odometer_miles > 150000 THEN 'Consider replacement'
        WHEN (maintenance_cost_ytd / NULLIF(miles_ytd, 0)) > 0.15 THEN 'High maintenance costs'
        WHEN year < YEAR(CURDATE()) - 7 THEN 'Aging vehicle'
        ELSE 'Operating normally'
    END AS lifecycle_recommendation
FROM vehicle_costs
ORDER BY total_cost_ytd DESC;

-- ============================================================================
-- Compliance Risk Dashboard
-- ============================================================================

-- Comprehensive compliance risk assessment
SELECT
    'HOS Violations' AS compliance_area,
    COUNT(DISTINCT hv.driver_id) AS drivers_affected,
    COUNT(hv.violation_id) AS total_violations,
    SUM(CASE WHEN hv.severity = 'critical' THEN 1 ELSE 0 END) AS critical_issues,
    SUM(CASE WHEN hv.resolved = FALSE THEN 1 ELSE 0 END) AS unresolved_issues,
    AVG(CASE
        WHEN hv.severity = 'critical' THEN 1000
        WHEN hv.severity = 'major' THEN 500
        ELSE 100
    END) AS avg_fine_risk,
    'Review driver logs, implement ELD if not present' AS mitigation_strategy
FROM hos_violations hv
WHERE hv.violation_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)

UNION ALL

SELECT
    'DVIR Compliance' AS compliance_area,
    COUNT(DISTINCT dv.vehicle_id) AS vehicles_affected,
    COUNT(CASE WHEN dv.defects_found = TRUE AND dv.repaired = FALSE THEN 1 END) AS unrepaired_defects,
    COUNT(CASE WHEN dv.signature_driver IS NULL THEN 1 END) AS unsigned_reports,
    COUNT(CASE WHEN dv.defects_found = TRUE THEN 1 END) AS total_defects,
    500 AS avg_fine_risk,
    'Enforce pre/post-trip inspections, track repairs' AS mitigation_strategy
FROM dvir_reports dv
WHERE dv.inspection_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)

UNION ALL

SELECT
    'License Expiry' AS compliance_area,
    COUNT(*) AS drivers_affected,
    SUM(CASE WHEN DATEDIFF(license_expiry, CURDATE()) < 0 THEN 1 ELSE 0 END) AS expired,
    SUM(CASE WHEN DATEDIFF(license_expiry, CURDATE()) BETWEEN 0 AND 30 THEN 1 ELSE 0 END) AS expiring_soon,
    0 AS no_action_needed,
    2000 AS avg_fine_risk,
    'Implement automated renewal reminders' AS mitigation_strategy
FROM drivers
WHERE status = 'active'
  AND license_expiry <= DATE_ADD(CURDATE(), INTERVAL 30 DAY)

UNION ALL

SELECT
    'Medical Certificates' AS compliance_area,
    COUNT(*) AS drivers_affected,
    SUM(CASE WHEN DATEDIFF(medical_cert_expiry, CURDATE()) < 0 THEN 1 ELSE 0 END) AS expired,
    SUM(CASE WHEN DATEDIFF(medical_cert_expiry, CURDATE()) BETWEEN 0 AND 30 THEN 1 ELSE 0 END) AS expiring_soon,
    0 AS no_action_needed,
    1500 AS avg_fine_risk,
    'Schedule medical exams proactively' AS mitigation_strategy
FROM drivers
WHERE status = 'active'
  AND license_class IN ('CDL_A', 'CDL_B')
  AND medical_cert_expiry <= DATE_ADD(CURDATE(), INTERVAL 30 DAY)

UNION ALL

SELECT
    'Vehicle Registration' AS compliance_area,
    COUNT(*) AS vehicles_affected,
    SUM(CASE WHEN DATEDIFF(registration_expiry, CURDATE()) < 0 THEN 1 ELSE 0 END) AS expired,
    SUM(CASE WHEN DATEDIFF(registration_expiry, CURDATE()) BETWEEN 0 AND 30 THEN 1 ELSE 0 END) AS expiring_soon,
    0 AS no_action_needed,
    1000 AS avg_fine_risk,
    'Centralize registration management' AS mitigation_strategy
FROM vehicles
WHERE status = 'active'
  AND registration_expiry <= DATE_ADD(CURDATE(), INTERVAL 30 DAY)

ORDER BY (critical_issues + unresolved_issues) DESC;