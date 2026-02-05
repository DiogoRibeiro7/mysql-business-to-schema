-- ============================================================================
-- Smart Agriculture Real-time Monitoring Queries
-- ============================================================================

USE smart_agriculture;

-- ============================================================================
-- Field Status Dashboard
-- ============================================================================

-- Current field and crop status overview
SELECT
    f.farm_name,
    fd.field_name,
    fd.area_hectares,
    fd.irrigation_type,
    c.crop_name,
    pr.variety,
    pr.planting_date,
    pr.expected_harvest_date,
    pr.status AS crop_status,
    DATEDIFF(pr.expected_harvest_date, CURDATE()) AS days_to_harvest,
    pr.area_planted_hectares,
    COALESCE(gs.gdd_accumulated, 0) AS gdd_accumulated,
    COALESCE(latest_moisture.soil_moisture, 'N/A') AS current_soil_moisture,
    COALESCE(latest_temp.soil_temp, 'N/A') AS current_soil_temp
FROM fields fd
INNER JOIN farms f ON fd.farm_id = f.farm_id
LEFT JOIN planting_records pr ON fd.field_id = pr.field_id
    AND pr.status IN ('planted', 'growing')
LEFT JOIN crops c ON pr.crop_id = c.crop_id
LEFT JOIN (
    SELECT planting_id, MAX(gdd_accumulated) AS gdd_accumulated
    FROM growth_stages
    GROUP BY planting_id
) gs ON pr.planting_id = gs.planting_id
LEFT JOIN LATERAL (
    SELECT AVG(sr.value) AS soil_moisture
    FROM sensors s
    INNER JOIN sensor_readings sr ON s.sensor_id = sr.sensor_id
    INNER JOIN zones z ON s.zone_id = z.zone_id
    WHERE z.field_id = fd.field_id
        AND s.sensor_type = 'soil_moisture'
        AND sr.timestamp > NOW() - INTERVAL 1 HOUR
) latest_moisture ON TRUE
LEFT JOIN LATERAL (
    SELECT AVG(sr.value) AS soil_temp
    FROM sensors s
    INNER JOIN sensor_readings sr ON s.sensor_id = sr.sensor_id
    INNER JOIN zones z ON s.zone_id = z.zone_id
    WHERE z.field_id = fd.field_id
        AND s.sensor_type = 'soil_temperature'
        AND sr.timestamp > NOW() - INTERVAL 1 HOUR
) latest_temp ON TRUE
ORDER BY f.farm_name, fd.field_name;

-- ============================================================================
-- Real-time Sensor Monitoring
-- ============================================================================

-- Latest sensor readings by zone
WITH latest_readings AS (
    SELECT
        s.sensor_id,
        s.zone_id,
        s.sensor_type,
        sr.value,
        sr.timestamp,
        sr.battery_voltage,
        ROW_NUMBER() OVER (PARTITION BY s.sensor_id ORDER BY sr.timestamp DESC) AS rn
    FROM sensors s
    INNER JOIN sensor_readings sr ON s.sensor_id = sr.sensor_id
    WHERE sr.timestamp > NOW() - INTERVAL 6 HOUR
        AND s.is_active = TRUE
)
SELECT
    f.farm_name,
    fd.field_name,
    z.zone_name,
    lr.sensor_type,
    ROUND(AVG(lr.value), 2) AS avg_value,
    MIN(lr.value) AS min_value,
    MAX(lr.value) AS max_value,
    COUNT(DISTINCT lr.sensor_id) AS sensor_count,
    AVG(lr.battery_voltage) AS avg_battery_v,
    CASE
        WHEN lr.sensor_type = 'soil_moisture' THEN
            CASE
                WHEN AVG(lr.value) < 30 THEN 'LOW - Irrigation needed'
                WHEN AVG(lr.value) > 80 THEN 'HIGH - Over-watered'
                ELSE 'OPTIMAL'
            END
        WHEN lr.sensor_type = 'soil_temperature' THEN
            CASE
                WHEN AVG(lr.value) < 10 THEN 'TOO COLD'
                WHEN AVG(lr.value) > 35 THEN 'TOO HOT'
                ELSE 'OPTIMAL'
            END
        WHEN lr.sensor_type = 'soil_ph' THEN
            CASE
                WHEN AVG(lr.value) < 5.5 THEN 'TOO ACIDIC'
                WHEN AVG(lr.value) > 8.0 THEN 'TOO ALKALINE'
                ELSE 'OPTIMAL'
            END
        ELSE 'CHECK'
    END AS status
FROM latest_readings lr
INNER JOIN zones z ON lr.zone_id = z.zone_id
INNER JOIN fields fd ON z.field_id = fd.field_id
INNER JOIN farms f ON fd.farm_id = f.farm_id
WHERE lr.rn = 1
GROUP BY f.farm_id, fd.field_id, z.zone_id, lr.sensor_type
ORDER BY f.farm_name, fd.field_name, z.zone_name, lr.sensor_type;

-- ============================================================================
-- Weather Monitoring
-- ============================================================================

-- Current weather conditions and forecast impact
SELECT
    ws.station_name,
    f.farm_name,
    wd.observation_time,
    wd.temperature_c,
    wd.humidity_percent,
    wd.rainfall_mm,
    wd.wind_speed_kmh,
    wd.solar_radiation_wm2,
    wd.evapotranspiration_mm,
    CASE
        WHEN wd.temperature_c < 0 THEN 'FROST RISK'
        WHEN wd.temperature_c > 35 THEN 'HEAT STRESS'
        WHEN wd.rainfall_mm > 50 THEN 'HEAVY RAIN'
        WHEN wd.wind_speed_kmh > 50 THEN 'HIGH WIND'
        ELSE 'NORMAL'
    END AS weather_alert,
    ROUND(calculate_gdd(
        wd.temperature_c - 5,
        wd.temperature_c + 5,
        10  -- Base temperature
    ), 2) AS gdd_today
FROM weather_stations ws
INNER JOIN farms f ON ws.farm_id = f.farm_id
INNER JOIN weather_data wd ON ws.station_id = wd.station_id
WHERE wd.observation_time >= NOW() - INTERVAL 1 HOUR
ORDER BY ws.station_name, wd.observation_time DESC
LIMIT 20;

-- ============================================================================
-- Irrigation Monitoring
-- ============================================================================

-- Active and recent irrigation events
SELECT
    f.farm_name,
    fd.field_name,
    z.zone_name,
    isys.system_type,
    ie.start_time,
    ie.end_time,
    CASE
        WHEN ie.end_time IS NULL THEN 'ACTIVE'
        ELSE 'COMPLETED'
    END AS status,
    TIMESTAMPDIFF(MINUTE, ie.start_time, COALESCE(ie.end_time, NOW())) AS duration_minutes,
    ie.water_amount_liters,
    ie.trigger_type,
    ie.trigger_reason,
    ie.soil_moisture_before,
    ie.soil_moisture_after
FROM irrigation_events ie
INNER JOIN irrigation_systems isys ON ie.system_id = isys.system_id
INNER JOIN fields fd ON isys.field_id = fd.field_id
INNER JOIN farms f ON fd.farm_id = f.farm_id
LEFT JOIN zones z ON ie.zone_id = z.zone_id
WHERE ie.start_time >= NOW() - INTERVAL 24 HOUR
ORDER BY ie.start_time DESC;

-- Irrigation needs assessment
SELECT
    f.farm_name,
    fd.field_name,
    c.crop_name,
    pr.area_planted_hectares,
    c.water_needs_mm_per_day,
    latest_moisture.avg_moisture AS current_moisture_pct,
    latest_weather.rainfall_24h,
    latest_weather.evapotranspiration_24h,
    CASE
        WHEN latest_moisture.avg_moisture < 30 THEN 'URGENT'
        WHEN latest_moisture.avg_moisture < 40 THEN 'NEEDED'
        WHEN latest_moisture.avg_moisture < 60 THEN 'MONITOR'
        ELSE 'ADEQUATE'
    END AS irrigation_priority,
    (c.water_needs_mm_per_day - COALESCE(latest_weather.rainfall_24h, 0) +
     COALESCE(latest_weather.evapotranspiration_24h, 0)) AS net_water_needed_mm
FROM planting_records pr
INNER JOIN fields fd ON pr.field_id = fd.field_id
INNER JOIN farms f ON fd.farm_id = f.farm_id
INNER JOIN crops c ON pr.crop_id = c.crop_id
LEFT JOIN LATERAL (
    SELECT AVG(sr.value) AS avg_moisture
    FROM zones z
    INNER JOIN sensors s ON z.zone_id = s.zone_id
    INNER JOIN sensor_readings sr ON s.sensor_id = sr.sensor_id
    WHERE z.field_id = fd.field_id
        AND s.sensor_type = 'soil_moisture'
        AND sr.timestamp > NOW() - INTERVAL 2 HOUR
) latest_moisture ON TRUE
LEFT JOIN LATERAL (
    SELECT
        SUM(rainfall_mm) AS rainfall_24h,
        SUM(evapotranspiration_mm) AS evapotranspiration_24h
    FROM weather_data wd
    INNER JOIN weather_stations ws ON wd.station_id = ws.station_id
    WHERE ws.farm_id = f.farm_id
        AND wd.observation_time > NOW() - INTERVAL 24 HOUR
) latest_weather ON TRUE
WHERE pr.status = 'growing'
ORDER BY irrigation_priority, f.farm_name, fd.field_name;

-- ============================================================================
-- Livestock Monitoring
-- ============================================================================

-- Livestock health status overview
SELECT
    f.farm_name,
    a.animal_type,
    COUNT(*) AS total_count,
    SUM(CASE WHEN a.health_status = 'healthy' THEN 1 ELSE 0 END) AS healthy_count,
    SUM(CASE WHEN a.health_status = 'sick' THEN 1 ELSE 0 END) AS sick_count,
    SUM(CASE WHEN a.health_status = 'quarantine' THEN 1 ELSE 0 END) AS quarantine_count,
    AVG(a.weight_kg) AS avg_weight_kg,
    MIN(a.weight_kg) AS min_weight_kg,
    MAX(a.weight_kg) AS max_weight_kg
FROM animals a
INNER JOIN farms f ON a.farm_id = f.farm_id
WHERE a.health_status != 'deceased'
GROUP BY f.farm_id, a.animal_type
ORDER BY f.farm_name, a.animal_type;

-- Today's milk production
SELECT
    f.farm_name,
    mp.milking_time,
    COUNT(DISTINCT mp.animal_id) AS cows_milked,
    SUM(mp.quantity_liters) AS total_liters,
    AVG(mp.quantity_liters) AS avg_per_cow,
    AVG(mp.fat_percentage) AS avg_fat_pct,
    AVG(mp.protein_percentage) AS avg_protein_pct,
    AVG(mp.somatic_cell_count) AS avg_scc,
    MIN(mp.quality_grade) AS lowest_grade
FROM milk_production mp
INNER JOIN animals a ON mp.animal_id = a.animal_id
INNER JOIN farms f ON a.farm_id = f.farm_id
WHERE mp.milking_date = CURDATE()
GROUP BY f.farm_id, mp.milking_time
ORDER BY f.farm_name, mp.milking_time;

-- ============================================================================
-- Pest and Disease Alerts
-- ============================================================================

-- Recent pesticide applications and PHI status
SELECT
    f.farm_name,
    fd.field_name,
    pa.product_name,
    pa.target_pest,
    pa.application_date,
    pa.phi_days,
    DATE_ADD(pa.application_date, INTERVAL pa.phi_days DAY) AS safe_harvest_date,
    CASE
        WHEN DATE_ADD(pa.application_date, INTERVAL pa.phi_days DAY) > CURDATE() THEN
            CONCAT('PHI ACTIVE - ', DATEDIFF(DATE_ADD(pa.application_date, INTERVAL pa.phi_days DAY), CURDATE()), ' days remaining')
        ELSE 'SAFE TO HARVEST'
    END AS phi_status,
    pr.expected_harvest_date,
    CASE
        WHEN pr.expected_harvest_date < DATE_ADD(pa.application_date, INTERVAL pa.phi_days DAY) THEN 'CONFLICT'
        ELSE 'OK'
    END AS harvest_phi_check
FROM pesticide_applications pa
INNER JOIN fields fd ON pa.field_id = fd.field_id
INNER JOIN farms f ON fd.farm_id = f.farm_id
LEFT JOIN planting_records pr ON fd.field_id = pr.field_id
    AND pr.status = 'growing'
WHERE pa.application_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
ORDER BY pa.application_date DESC;

-- ============================================================================
-- Growth Progress Monitoring
-- ============================================================================

-- Crop growth progress vs expected
SELECT
    f.farm_name,
    fd.field_name,
    c.crop_name,
    pr.variety,
    pr.planting_date,
    DATEDIFF(CURDATE(), pr.planting_date) AS days_since_planting,
    c.growth_days AS expected_growth_days,
    ROUND((DATEDIFF(CURDATE(), pr.planting_date) / c.growth_days) * 100, 1) AS growth_progress_pct,
    gs.latest_stage,
    gs.gdd_accumulated,
    pr.expected_harvest_date,
    CASE
        WHEN DATEDIFF(CURDATE(), pr.planting_date) / c.growth_days > 0.9 THEN 'NEAR HARVEST'
        WHEN DATEDIFF(CURDATE(), pr.planting_date) / c.growth_days > 0.6 THEN 'MATURING'
        WHEN DATEDIFF(CURDATE(), pr.planting_date) / c.growth_days > 0.3 THEN 'DEVELOPING'
        ELSE 'EARLY GROWTH'
    END AS growth_phase
FROM planting_records pr
INNER JOIN fields fd ON pr.field_id = fd.field_id
INNER JOIN farms f ON fd.farm_id = f.farm_id
INNER JOIN crops c ON pr.crop_id = c.crop_id
LEFT JOIN (
    SELECT
        planting_id,
        MAX(stage_name) AS latest_stage,
        MAX(gdd_accumulated) AS gdd_accumulated
    FROM growth_stages
    GROUP BY planting_id
) gs ON pr.planting_id = gs.planting_id
WHERE pr.status = 'growing'
ORDER BY growth_progress_pct DESC;