-- ============================================================================
-- Smart Energy Monitoring System - Real-Time Monitoring Queries
-- ============================================================================
-- Description: Queries for real-time energy monitoring and power quality
-- ============================================================================

USE smart_energy;

-- ============================================================================
-- 1. Current Building Power Status
-- ============================================================================
SELECT
    b.building_name,
    b.building_code,
    COUNT(DISTINCT em.meter_id) AS active_meters,
    ROUND(SUM(er.power_value), 2) AS total_power_kw,
    ROUND(AVG(er.power_factor), 3) AS avg_power_factor,
    ROUND(AVG(er.voltage_v), 1) AS avg_voltage,
    MAX(er.reading_timestamp) AS last_reading,
    CASE
        WHEN SUM(er.power_value) > b.total_area_sqm * 0.15 THEN 'HIGH'
        WHEN SUM(er.power_value) > b.total_area_sqm * 0.10 THEN 'NORMAL'
        ELSE 'LOW'
    END AS load_level
FROM buildings b
LEFT JOIN energy_meters em ON b.building_id = em.building_id
LEFT JOIN energy_readings er ON em.meter_id = er.meter_id
    AND er.reading_timestamp >= NOW() - INTERVAL 5 MINUTE
WHERE b.status = 'active'
    AND em.status = 'active'
GROUP BY b.building_id
ORDER BY total_power_kw DESC;

-- ============================================================================
-- 2. Zone-Level Energy Consumption
-- ============================================================================
SELECT
    b.building_name,
    f.floor_number,
    f.floor_name,
    z.zone_name,
    z.zone_type,
    ROUND(SUM(er.power_value), 2) AS current_power_kw,
    ROUND(SUM(er.power_value) * 1000 / z.area_sqm, 2) AS power_density_w_sqm,
    COUNT(DISTINCT t.tenant_id) AS tenant_count,
    z.target_temperature_c,
    CASE
        WHEN z.zone_type = 'server_room' AND SUM(er.power_value) > z.area_sqm * 0.5 THEN 'CRITICAL'
        WHEN SUM(er.power_value) * 1000 / z.area_sqm > 100 THEN 'HIGH'
        WHEN SUM(er.power_value) * 1000 / z.area_sqm > 50 THEN 'NORMAL'
        ELSE 'LOW'
    END AS consumption_level
FROM zones z
INNER JOIN floors f ON z.floor_id = f.floor_id
INNER JOIN buildings b ON f.building_id = b.building_id
LEFT JOIN energy_meters em ON z.zone_id = em.zone_id
LEFT JOIN energy_readings er ON em.meter_id = er.meter_id
    AND er.reading_timestamp >= NOW() - INTERVAL 5 MINUTE
LEFT JOIN tenant_zone_assignments tza ON z.zone_id = tza.zone_id
    AND CURDATE() BETWEEN tza.assignment_start_date
    AND COALESCE(tza.assignment_end_date, '9999-12-31')
LEFT JOIN tenants t ON tza.tenant_id = t.tenant_id
WHERE z.zone_type NOT IN ('corridor', 'restroom')
GROUP BY z.zone_id
ORDER BY b.building_name, f.floor_number, power_density_w_sqm DESC;

-- ============================================================================
-- 3. Power Quality Monitoring
-- ============================================================================
WITH power_quality AS (
    SELECT
        em.meter_name,
        em.meter_code,
        b.building_name,
        AVG(er.voltage_v) AS avg_voltage,
        MIN(er.voltage_v) AS min_voltage,
        MAX(er.voltage_v) AS max_voltage,
        STDDEV(er.voltage_v) AS voltage_stddev,
        AVG(er.power_factor) AS avg_pf,
        MIN(er.power_factor) AS min_pf,
        AVG(er.frequency_hz) AS avg_frequency,
        COUNT(*) AS reading_count,
        SUM(CASE WHEN er.quality_flag != 'good' THEN 1 ELSE 0 END) AS error_count
    FROM energy_readings er
    INNER JOIN energy_meters em ON er.meter_id = em.meter_id
    INNER JOIN buildings b ON em.building_id = b.building_id
    WHERE er.reading_timestamp >= NOW() - INTERVAL 1 HOUR
    GROUP BY em.meter_id
)
SELECT
    meter_name,
    building_name,
    ROUND(avg_voltage, 1) AS avg_voltage_v,
    ROUND(min_voltage, 1) AS min_voltage_v,
    ROUND(max_voltage, 1) AS max_voltage_v,
    ROUND(voltage_stddev, 2) AS voltage_stability,
    ROUND(avg_pf, 3) AS power_factor,
    ROUND(avg_frequency, 2) AS frequency_hz,
    reading_count,
    error_count,
    CASE
        WHEN min_voltage < 208 OR max_voltage > 253 THEN 'POOR'
        WHEN avg_pf < 0.85 THEN 'POOR'
        WHEN voltage_stddev > 5 THEN 'FAIR'
        WHEN avg_pf < 0.90 THEN 'FAIR'
        ELSE 'GOOD'
    END AS power_quality_rating
FROM power_quality
WHERE error_count > 0
   OR avg_pf < 0.90
   OR min_voltage < 215
   OR max_voltage > 245
ORDER BY power_quality_rating DESC, avg_pf ASC;

-- ============================================================================
-- 4. HVAC System Status
-- ============================================================================
SELECT
    hu.unit_name,
    hu.unit_type,
    b.building_name,
    ht.supply_temp_c,
    ht.return_temp_c,
    ht.setpoint_temp_c,
    ht.outdoor_temp_c,
    ht.fan_speed_pct,
    ht.compressor_status,
    ROUND(ht.power_kw, 2) AS current_power_kw,
    ROUND(ht.efficiency_cop, 2) AS cop,
    ht.runtime_minutes AS runtime_today_min,
    ht.fault_code,
    CASE
        WHEN ht.fault_code IS NOT NULL THEN 'FAULT'
        WHEN ht.efficiency_cop < 2.0 THEN 'INEFFICIENT'
        WHEN ABS(ht.supply_temp_c - ht.setpoint_temp_c) > 3 THEN 'STRUGGLING'
        ELSE 'NORMAL'
    END AS status
FROM hvac_units hu
INNER JOIN buildings b ON hu.building_id = b.building_id
LEFT JOIN (
    SELECT
        unit_id,
        supply_temp_c,
        return_temp_c,
        setpoint_temp_c,
        outdoor_temp_c,
        fan_speed_pct,
        compressor_status,
        power_kw,
        efficiency_cop,
        runtime_minutes,
        fault_code,
        ROW_NUMBER() OVER (PARTITION BY unit_id ORDER BY timestamp DESC) AS rn
    FROM hvac_telemetry
    WHERE timestamp >= NOW() - INTERVAL 15 MINUTE
) ht ON hu.unit_id = ht.unit_id AND ht.rn = 1
WHERE hu.status = 'active'
ORDER BY status DESC, current_power_kw DESC;

-- ============================================================================
-- 5. Solar Generation Status
-- ============================================================================
SELECT
    ss.system_name,
    ss.system_code,
    b.building_name,
    ss.capacity_kw,
    sp.power_kw AS current_generation_kw,
    ROUND(100.0 * sp.power_kw / ss.capacity_kw, 1) AS capacity_factor_pct,
    sp.irradiance_w_m2,
    sp.panel_temp_c,
    sp.efficiency_pct,
    CASE
        WHEN sp.power_kw IS NULL THEN 'OFFLINE'
        WHEN sp.power_kw < ss.capacity_kw * 0.1 THEN 'LOW'
        WHEN sp.power_kw < ss.capacity_kw * 0.5 THEN 'MODERATE'
        ELSE 'HIGH'
    END AS generation_level,
    -- Calculate daily production
    (
        SELECT ROUND(SUM(energy_kwh), 2)
        FROM solar_production
        WHERE system_id = ss.system_id
            AND DATE(timestamp) = CURDATE()
    ) AS today_production_kwh
FROM solar_systems ss
INNER JOIN buildings b ON ss.building_id = b.building_id
LEFT JOIN (
    SELECT
        system_id,
        power_kw,
        irradiance_w_m2,
        panel_temp_c,
        efficiency_pct,
        ROW_NUMBER() OVER (PARTITION BY system_id ORDER BY timestamp DESC) AS rn
    FROM solar_production
    WHERE timestamp >= NOW() - INTERVAL 15 MINUTE
) sp ON ss.system_id = sp.system_id AND sp.rn = 1
WHERE ss.status = 'active'
ORDER BY current_generation_kw DESC;

-- ============================================================================
-- 6. Battery Storage Status
-- ============================================================================
SELECT
    bs.battery_code,
    bs.system_name,
    b.building_name,
    bs.capacity_kwh,
    bst.state_of_charge_pct,
    ROUND(bs.capacity_kwh * bst.state_of_charge_pct / 100, 2) AS energy_available_kwh,
    bst.power_kw,
    CASE
        WHEN bst.power_kw > 0 THEN 'CHARGING'
        WHEN bst.power_kw < 0 THEN 'DISCHARGING'
        ELSE 'IDLE'
    END AS operation_mode,
    bst.voltage_v,
    bst.temperature_c,
    bst.health_pct,
    bs.cycles_count,
    bs.max_cycles,
    ROUND(100.0 * bs.cycles_count / bs.max_cycles, 1) AS lifecycle_pct,
    CASE
        WHEN bst.health_pct < 70 THEN 'REPLACE'
        WHEN bst.health_pct < 80 THEN 'DEGRADED'
        WHEN bst.temperature_c > 40 THEN 'OVERHEATING'
        WHEN bst.state_of_charge_pct < 20 THEN 'LOW_CHARGE'
        ELSE 'HEALTHY'
    END AS battery_status
FROM battery_storage bs
INNER JOIN buildings b ON bs.building_id = b.building_id
LEFT JOIN (
    SELECT
        battery_id,
        state_of_charge_pct,
        power_kw,
        voltage_v,
        temperature_c,
        health_pct,
        ROW_NUMBER() OVER (PARTITION BY battery_id ORDER BY timestamp DESC) AS rn
    FROM battery_status
    WHERE timestamp >= NOW() - INTERVAL 15 MINUTE
) bst ON bs.battery_id = bst.battery_id AND bst.rn = 1
WHERE bs.status != 'decommissioned'
ORDER BY battery_status DESC, state_of_charge_pct ASC;

-- ============================================================================
-- 7. Tenant Real-Time Consumption
-- ============================================================================
SELECT
    t.company_name,
    t.tenant_code,
    COUNT(DISTINCT z.zone_id) AS zone_count,
    ROUND(SUM(z.area_sqm), 2) AS total_area_sqm,
    ROUND(SUM(er.power_value), 2) AS current_power_kw,
    ROUND(SUM(er.power_value) * 1000 / SUM(z.area_sqm), 2) AS power_density_w_sqm,
    t.energy_budget_kwh AS monthly_budget_kwh,
    -- Month-to-date consumption
    (
        SELECT ROUND(SUM(ech.energy_consumed_kwh), 2)
        FROM energy_consumption_hourly ech
        INNER JOIN energy_meters em2 ON ech.meter_id = em2.meter_id
        INNER JOIN tenant_zone_assignments tza2 ON em2.zone_id = tza2.zone_id
        WHERE tza2.tenant_id = t.tenant_id
            AND MONTH(ech.hour_start) = MONTH(CURDATE())
            AND YEAR(ech.hour_start) = YEAR(CURDATE())
    ) AS mtd_consumption_kwh,
    CASE
        WHEN t.energy_budget_kwh IS NOT NULL AND
             (SELECT SUM(ech.energy_consumed_kwh)
              FROM energy_consumption_hourly ech
              INNER JOIN energy_meters em2 ON ech.meter_id = em2.meter_id
              INNER JOIN tenant_zone_assignments tza2 ON em2.zone_id = tza2.zone_id
              WHERE tza2.tenant_id = t.tenant_id
                AND MONTH(ech.hour_start) = MONTH(CURDATE())
                AND YEAR(ech.hour_start) = YEAR(CURDATE())
             ) > t.energy_budget_kwh * 0.9 THEN 'OVER_BUDGET'
        ELSE 'WITHIN_BUDGET'
    END AS budget_status
FROM tenants t
INNER JOIN tenant_zone_assignments tza ON t.tenant_id = tza.tenant_id
    AND CURDATE() BETWEEN tza.assignment_start_date
    AND COALESCE(tza.assignment_end_date, '9999-12-31')
INNER JOIN zones z ON tza.zone_id = z.zone_id
LEFT JOIN energy_meters em ON z.zone_id = em.zone_id
LEFT JOIN energy_readings er ON em.meter_id = er.meter_id
    AND er.reading_timestamp >= NOW() - INTERVAL 5 MINUTE
WHERE t.status = 'active'
GROUP BY t.tenant_id
ORDER BY current_power_kw DESC;

-- ============================================================================
-- 8. Active Demand Response Events
-- ============================================================================
SELECT
    dre.event_code,
    dre.event_type,
    dre.start_time,
    dre.end_time,
    TIMESTAMPDIFF(MINUTE, NOW(), dre.start_time) AS minutes_until_start,
    TIMESTAMPDIFF(MINUTE, dre.start_time, dre.end_time) AS duration_minutes,
    dre.target_reduction_kw,
    dre.target_reduction_pct,
    dre.incentive_rate,
    dre.response_status,
    -- Current building load
    (
        SELECT ROUND(SUM(er.power_value), 2)
        FROM energy_readings er
        INNER JOIN energy_meters em ON er.meter_id = em.meter_id
        WHERE em.building_id IN (SELECT building_id FROM buildings WHERE status = 'active')
            AND er.reading_timestamp >= NOW() - INTERVAL 5 MINUTE
    ) AS current_total_load_kw,
    CASE
        WHEN dre.response_status = 'pending' AND
             TIMESTAMPDIFF(MINUTE, NOW(), dre.start_time) < 30 THEN 'ACTION_REQUIRED'
        WHEN dre.response_status = 'accepted' AND
             NOW() BETWEEN dre.start_time AND dre.end_time THEN 'IN_PROGRESS'
        WHEN dre.response_status = 'accepted' THEN 'SCHEDULED'
        ELSE dre.response_status
    END AS event_status
FROM demand_response_events dre
WHERE dre.end_time >= NOW()
    AND dre.response_status != 'declined'
ORDER BY dre.start_time ASC;

-- ============================================================================
-- 9. Critical Alerts Dashboard
-- ============================================================================
SELECT
    ea.severity,
    ea.alert_type,
    ea.entity_type,
    CASE ea.entity_type
        WHEN 'meter' THEN (SELECT meter_name FROM energy_meters WHERE meter_id = ea.entity_id)
        WHEN 'hvac' THEN (SELECT unit_name FROM hvac_units WHERE unit_id = ea.entity_id)
        WHEN 'solar' THEN (SELECT system_name FROM solar_systems WHERE system_id = ea.entity_id)
        WHEN 'battery' THEN (SELECT system_name FROM battery_storage WHERE battery_id = ea.entity_id)
        WHEN 'building' THEN (SELECT building_name FROM buildings WHERE building_id = ea.entity_id)
        WHEN 'zone' THEN (SELECT zone_name FROM zones WHERE zone_id = ea.entity_id)
    END AS entity_name,
    ea.triggered_at,
    TIMESTAMPDIFF(MINUTE, ea.triggered_at, NOW()) AS minutes_active,
    ea.alert_value,
    ea.threshold_value,
    ea.message,
    ea.acknowledged
FROM energy_alerts ea
WHERE ea.resolved_at IS NULL
    AND ea.severity IN ('critical', 'emergency')
ORDER BY
    FIELD(ea.severity, 'emergency', 'critical'),
    ea.triggered_at DESC
LIMIT 20;

-- ============================================================================
-- 10. System Performance Summary
-- ============================================================================
SELECT
    'Total Buildings' AS metric,
    COUNT(*) AS value,
    'count' AS unit
FROM buildings WHERE status = 'active'
UNION ALL
SELECT
    'Active Power',
    ROUND(SUM(er.power_value), 2),
    'kW'
FROM energy_readings er
INNER JOIN energy_meters em ON er.meter_id = em.meter_id
WHERE er.reading_timestamp >= NOW() - INTERVAL 5 MINUTE
    AND em.status = 'active'
UNION ALL
SELECT
    'Solar Generation',
    ROUND(SUM(sp.power_kw), 2),
    'kW'
FROM solar_production sp
WHERE sp.timestamp >= NOW() - INTERVAL 5 MINUTE
UNION ALL
SELECT
    'Battery Storage',
    ROUND(SUM(bs.capacity_kwh * bst.state_of_charge_pct / 100), 2),
    'kWh available'
FROM battery_storage bs
INNER JOIN battery_status bst ON bs.battery_id = bst.battery_id
WHERE bst.timestamp >= NOW() - INTERVAL 5 MINUTE
UNION ALL
SELECT
    'Average Power Factor',
    ROUND(AVG(er.power_factor), 3),
    'ratio'
FROM energy_readings er
WHERE er.reading_timestamp >= NOW() - INTERVAL 5 MINUTE
    AND er.power_factor IS NOT NULL
UNION ALL
SELECT
    'Active HVAC Units',
    COUNT(DISTINCT ht.unit_id),
    'units'
FROM hvac_telemetry ht
WHERE ht.timestamp >= NOW() - INTERVAL 5 MINUTE
    AND ht.compressor_status != 'off'
UNION ALL
SELECT
    'Unresolved Alerts',
    COUNT(*),
    'alerts'
FROM energy_alerts
WHERE resolved_at IS NULL
UNION ALL
SELECT
    'Today Energy Cost',
    ROUND(SUM(
        CASE
            WHEN HOUR(ech.hour_start) BETWEEN 14 AND 20 THEN ech.energy_consumed_kwh * 0.25
            WHEN HOUR(ech.hour_start) BETWEEN 9 AND 14 OR
                 HOUR(ech.hour_start) BETWEEN 20 AND 22 THEN ech.energy_consumed_kwh * 0.18
            ELSE ech.energy_consumed_kwh * 0.12
        END
    ), 2),
    'USD'
FROM energy_consumption_hourly ech
WHERE DATE(ech.hour_start) = CURDATE();