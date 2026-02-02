-- ============================================================================
-- IoT Garbage Bin Monitoring System - Route Optimization Queries
-- ============================================================================
-- Description: Queries for optimizing collection routes based on fill levels
-- ============================================================================

USE iot_bins;

-- ============================================================================
-- 1. Bins Needing Collection by Urgency and Proximity
-- ============================================================================
WITH bin_priorities AS (
    SELECT
        b.bin_id,
        b.bin_code,
        b.district_id,
        b.bin_type,
        b.latitude,
        b.longitude,
        b.capacity_liters,
        cbs.current_fill_percentage,
        cbs.last_collected_at,
        TIMESTAMPDIFF(HOUR, cbs.last_collected_at, NOW()) AS hours_since_collection,
        -- Priority score based on fill level and time
        (cbs.current_fill_percentage * 2) +
        (LEAST(TIMESTAMPDIFF(HOUR, cbs.last_collected_at, NOW()), 168) * 0.5) AS priority_score,
        -- Estimated weight to collect
        (cbs.current_fill_percentage / 100) * b.capacity_liters * 0.3 AS estimated_weight_kg
    FROM bins b
    INNER JOIN v_current_bin_status cbs ON b.bin_id = cbs.bin_id
    WHERE b.status = 'active'
        AND cbs.current_fill_percentage >= 70
)
SELECT
    bp.bin_code,
    d.name AS district,
    bp.bin_type,
    ROUND(bp.current_fill_percentage, 1) AS fill_pct,
    bp.hours_since_collection AS hours_since,
    ROUND(bp.priority_score, 1) AS priority,
    ROUND(bp.estimated_weight_kg, 2) AS est_weight_kg,
    bp.latitude,
    bp.longitude,
    -- Find nearest high-priority bin
    (
        SELECT MIN(
            ST_Distance_Sphere(
                POINT(bp.longitude, bp.latitude),
                POINT(bp2.longitude, bp2.latitude)
            ) / 1000
        )
        FROM bin_priorities bp2
        WHERE bp2.bin_id != bp.bin_id
            AND bp2.district_id = bp.district_id
            AND bp2.priority_score > 150
    ) AS nearest_urgent_km
FROM bin_priorities bp
INNER JOIN districts d ON bp.district_id = d.district_id
WHERE bp.priority_score > 140
ORDER BY bp.district_id, bp.priority_score DESC;

-- ============================================================================
-- 2. Optimal Route Calculation Using Spatial Queries
-- ============================================================================
-- Generate optimal collection route for a specific district
SET @target_district_id = 1;
SET @truck_capacity_kg = 10000;
SET @current_lat = 40.7128;  -- Starting point (depot)
SET @current_lon = -74.0060;

WITH RECURSIVE route_builder AS (
    -- Start with the most urgent bin
    SELECT
        1 AS stop_number,
        b.bin_id,
        b.bin_code,
        b.latitude,
        b.longitude,
        cbs.current_fill_percentage,
        (cbs.current_fill_percentage / 100) * b.capacity_liters * 0.3 AS weight_kg,
        (cbs.current_fill_percentage / 100) * b.capacity_liters * 0.3 AS cumulative_weight,
        0 AS distance_from_prev,
        0 AS total_distance,
        CAST(b.bin_id AS CHAR(1000)) AS visited_bins
    FROM bins b
    INNER JOIN v_current_bin_status cbs ON b.bin_id = cbs.bin_id
    WHERE b.district_id = @target_district_id
        AND b.status = 'active'
        AND cbs.current_fill_percentage >= 80
    ORDER BY cbs.current_fill_percentage DESC
    LIMIT 1

    UNION ALL

    -- Add nearest unvisited bin
    SELECT
        rb.stop_number + 1,
        b.bin_id,
        b.bin_code,
        b.latitude,
        b.longitude,
        cbs.current_fill_percentage,
        (cbs.current_fill_percentage / 100) * b.capacity_liters * 0.3 AS weight_kg,
        rb.cumulative_weight + (cbs.current_fill_percentage / 100) * b.capacity_liters * 0.3,
        ST_Distance_Sphere(
            POINT(rb.longitude, rb.latitude),
            POINT(b.longitude, b.latitude)
        ) / 1000 AS distance_from_prev,
        rb.total_distance + ST_Distance_Sphere(
            POINT(rb.longitude, rb.latitude),
            POINT(b.longitude, b.latitude)
        ) / 1000,
        CONCAT(rb.visited_bins, ',', b.bin_id)
    FROM route_builder rb
    INNER JOIN bins b ON b.district_id = @target_district_id
    INNER JOIN v_current_bin_status cbs ON b.bin_id = cbs.bin_id
    WHERE b.status = 'active'
        AND cbs.current_fill_percentage >= 70
        AND FIND_IN_SET(b.bin_id, rb.visited_bins) = 0
        AND rb.cumulative_weight + (cbs.current_fill_percentage / 100) * b.capacity_liters * 0.3 <= @truck_capacity_kg
        AND rb.stop_number < 50  -- Limit stops
    ORDER BY ST_Distance_Sphere(
        POINT(rb.longitude, rb.latitude),
        POINT(b.longitude, b.latitude)
    )
    LIMIT 1
)
SELECT
    stop_number,
    bin_code,
    ROUND(current_fill_percentage, 1) AS fill_pct,
    ROUND(weight_kg, 2) AS weight_kg,
    ROUND(cumulative_weight, 2) AS total_weight_kg,
    ROUND(distance_from_prev, 2) AS distance_km,
    ROUND(total_distance, 2) AS cumulative_distance_km,
    latitude,
    longitude
FROM route_builder
ORDER BY stop_number;

-- ============================================================================
-- 3. Truck Capacity vs Expected Collection Volume
-- ============================================================================
SELECT
    t.truck_code,
    t.capacity_kg,
    t.fuel_type,
    t.status,
    -- Calculate optimal route load for this truck
    (
        SELECT ROUND(SUM(
            (cbs.current_fill_percentage / 100) * b.capacity_liters * 0.3
        ), 2)
        FROM bins b
        INNER JOIN v_current_bin_status cbs ON b.bin_id = cbs.bin_id
        WHERE cbs.current_fill_percentage >= 80
            AND b.status = 'active'
        ORDER BY cbs.current_fill_percentage DESC
        LIMIT FLOOR(t.capacity_kg / 200)  -- Approximate bins based on capacity
    ) AS potential_collection_kg,
    -- Utilization percentage
    (
        SELECT ROUND(100 * SUM(
            (cbs.current_fill_percentage / 100) * b.capacity_liters * 0.3
        ) / t.capacity_kg, 1)
        FROM bins b
        INNER JOIN v_current_bin_status cbs ON b.bin_id = cbs.bin_id
        WHERE cbs.current_fill_percentage >= 80
            AND b.status = 'active'
        ORDER BY cbs.current_fill_percentage DESC
        LIMIT FLOOR(t.capacity_kg / 200)
    ) AS utilization_pct,
    t.next_maintenance_date,
    DATEDIFF(t.next_maintenance_date, CURDATE()) AS days_until_maintenance
FROM trucks t
WHERE t.status IN ('available', 'in_use')
ORDER BY utilization_pct DESC;

-- ============================================================================
-- 4. District Collection Requirements
-- ============================================================================
SELECT
    d.district_id,
    d.name AS district,
    COUNT(DISTINCT b.bin_id) AS total_bins,
    COUNT(DISTINCT CASE WHEN cbs.current_fill_percentage >= 80 THEN b.bin_id END) AS urgent_bins,
    COUNT(DISTINCT CASE WHEN cbs.current_fill_percentage >= 70 THEN b.bin_id END) AS soon_bins,
    ROUND(SUM(
        CASE
            WHEN cbs.current_fill_percentage >= 70 THEN
                (cbs.current_fill_percentage / 100) * b.capacity_liters * 0.3
            ELSE 0
        END
    ), 2) AS total_collection_kg,
    CEIL(SUM(
        CASE
            WHEN cbs.current_fill_percentage >= 70 THEN
                (cbs.current_fill_percentage / 100) * b.capacity_liters * 0.3
            ELSE 0
        END
    ) / 10000) AS trucks_needed,
    -- Estimate collection time
    COUNT(DISTINCT CASE WHEN cbs.current_fill_percentage >= 70 THEN b.bin_id END) * 2 AS est_minutes
FROM districts d
LEFT JOIN bins b ON d.district_id = b.district_id AND b.status = 'active'
LEFT JOIN v_current_bin_status cbs ON b.bin_id = cbs.bin_id
GROUP BY d.district_id
ORDER BY urgent_bins DESC, total_collection_kg DESC;

-- ============================================================================
-- 5. Multi-District Route Optimization
-- ============================================================================
WITH district_clusters AS (
    SELECT
        d.district_id,
        d.name,
        AVG(b.latitude) AS center_lat,
        AVG(b.longitude) AS center_lon,
        COUNT(DISTINCT CASE WHEN cbs.current_fill_percentage >= 80 THEN b.bin_id END) AS urgent_count,
        SUM(CASE WHEN cbs.current_fill_percentage >= 80 THEN
            (cbs.current_fill_percentage / 100) * b.capacity_liters * 0.3
        ELSE 0 END) AS urgent_weight_kg
    FROM districts d
    INNER JOIN bins b ON d.district_id = b.district_id
    INNER JOIN v_current_bin_status cbs ON b.bin_id = cbs.bin_id
    WHERE b.status = 'active'
    GROUP BY d.district_id
),
district_distances AS (
    SELECT
        dc1.district_id AS district1_id,
        dc1.name AS district1,
        dc2.district_id AS district2_id,
        dc2.name AS district2,
        ST_Distance_Sphere(
            POINT(dc1.center_lon, dc1.center_lat),
            POINT(dc2.center_lon, dc2.center_lat)
        ) / 1000 AS distance_km
    FROM district_clusters dc1
    CROSS JOIN district_clusters dc2
    WHERE dc1.district_id < dc2.district_id
)
SELECT
    dd.district1,
    dd.district2,
    ROUND(dd.distance_km, 2) AS distance_km,
    dc1.urgent_count AS district1_urgent,
    dc2.urgent_count AS district2_urgent,
    ROUND(dc1.urgent_weight_kg + dc2.urgent_weight_kg, 2) AS combined_weight_kg,
    CASE
        WHEN dc1.urgent_weight_kg + dc2.urgent_weight_kg <= 10000 THEN 'COMBINE'
        ELSE 'SEPARATE'
    END AS routing_recommendation
FROM district_distances dd
INNER JOIN district_clusters dc1 ON dd.district1_id = dc1.district_id
INNER JOIN district_clusters dc2 ON dd.district2_id = dc2.district_id
WHERE dd.distance_km < 5  -- Only consider nearby districts
    AND (dc1.urgent_count > 0 OR dc2.urgent_count > 0)
ORDER BY dd.distance_km;

-- ============================================================================
-- 6. Time-Based Route Optimization
-- ============================================================================
SELECT
    HOUR(NOW()) AS current_hour,
    cr.route_code,
    cr.route_name,
    d.name AS district,
    COUNT(DISTINCT rba.bin_id) AS total_bins,
    COUNT(DISTINCT CASE WHEN cbs.current_fill_percentage >= 80 THEN rba.bin_id END) AS urgent_bins,
    ROUND(AVG(cbs.current_fill_percentage), 1) AS avg_fill_pct,
    -- Estimate completion time based on current conditions
    COUNT(DISTINCT rba.bin_id) * 2 AS est_minutes,
    ADDTIME(CURTIME(), SEC_TO_TIME(COUNT(DISTINCT rba.bin_id) * 2 * 60)) AS est_completion_time,
    CASE
        WHEN AVG(cbs.current_fill_percentage) >= 75 THEN 'HIGH_PRIORITY'
        WHEN AVG(cbs.current_fill_percentage) >= 60 THEN 'MEDIUM_PRIORITY'
        ELSE 'LOW_PRIORITY'
    END AS priority
FROM collection_routes cr
INNER JOIN districts d ON cr.district_id = d.district_id
INNER JOIN route_bin_assignments rba ON cr.route_id = rba.route_id
INNER JOIN v_current_bin_status cbs ON rba.bin_id = cbs.bin_id
WHERE cr.active = TRUE
GROUP BY cr.route_id
HAVING urgent_bins > 0
ORDER BY priority DESC, urgent_bins DESC;

-- ============================================================================
-- 7. Dynamic Route Assignment
-- ============================================================================
SELECT
    t.truck_code,
    t.capacity_kg,
    dr.employee_id,
    CONCAT(dr.first_name, ' ', dr.last_name) AS driver_name,
    -- Find best route for this truck/driver combination
    (
        SELECT cr.route_code
        FROM collection_routes cr
        INNER JOIN route_bin_assignments rba ON cr.route_id = rba.route_id
        INNER JOIN v_current_bin_status cbs ON rba.bin_id = cbs.bin_id
        WHERE cr.active = TRUE
        GROUP BY cr.route_id
        HAVING SUM(
            (cbs.current_fill_percentage / 100) *
            (SELECT capacity_liters FROM bins WHERE bin_id = rba.bin_id) * 0.3
        ) <= t.capacity_kg
        ORDER BY AVG(cbs.current_fill_percentage) DESC
        LIMIT 1
    ) AS recommended_route,
    -- Expected collection weight
    (
        SELECT ROUND(SUM(
            (cbs.current_fill_percentage / 100) *
            (SELECT capacity_liters FROM bins WHERE bin_id = rba.bin_id) * 0.3
        ), 2)
        FROM collection_routes cr
        INNER JOIN route_bin_assignments rba ON cr.route_id = rba.route_id
        INNER JOIN v_current_bin_status cbs ON rba.bin_id = cbs.bin_id
        WHERE cr.route_code = (
            SELECT cr2.route_code
            FROM collection_routes cr2
            INNER JOIN route_bin_assignments rba2 ON cr2.route_id = rba2.route_id
            INNER JOIN v_current_bin_status cbs2 ON rba2.bin_id = cbs2.bin_id
            WHERE cr2.active = TRUE
            GROUP BY cr2.route_id
            HAVING SUM(
                (cbs2.current_fill_percentage / 100) *
                (SELECT capacity_liters FROM bins WHERE bin_id = rba2.bin_id) * 0.3
            ) <= t.capacity_kg
            ORDER BY AVG(cbs2.current_fill_percentage) DESC
            LIMIT 1
        )
    ) AS expected_weight_kg
FROM trucks t
CROSS JOIN drivers dr
WHERE t.status = 'available'
    AND dr.status = 'active'
    AND NOT EXISTS (
        SELECT 1
        FROM collection_schedules cs
        WHERE cs.driver_id = dr.driver_id
            AND cs.scheduled_date = CURDATE()
            AND cs.status IN ('scheduled', 'in_progress')
    )
ORDER BY t.capacity_kg DESC, driver_name;

-- ============================================================================
-- 8. Emergency Collection Routes
-- ============================================================================
SELECT
    b.bin_id,
    b.bin_code,
    d.name AS district,
    b.bin_type,
    b.address,
    cbs.current_fill_percentage,
    a.alert_type,
    a.severity,
    a.triggered_at,
    TIMESTAMPDIFF(HOUR, a.triggered_at, NOW()) AS alert_age_hours,
    b.latitude,
    b.longitude
FROM bins b
INNER JOIN districts d ON b.district_id = d.district_id
INNER JOIN v_current_bin_status cbs ON b.bin_id = cbs.bin_id
INNER JOIN alerts a ON b.bin_id = a.bin_id
WHERE a.resolved_at IS NULL
    AND a.severity IN ('critical', 'emergency')
    AND a.alert_type IN ('fill_critical', 'odor_high', 'tilt_detected')
    AND b.status = 'active'
ORDER BY
    FIELD(a.severity, 'emergency', 'critical'),
    cbs.current_fill_percentage DESC,
    a.triggered_at;