-- ============================================================================
-- Smart Agriculture Management Reports
-- ============================================================================

USE smart_agriculture;

-- ============================================================================
-- Executive Farm Summary Report
-- ============================================================================

-- Farm-level KPI dashboard
SELECT
    f.farm_name,
    f.farm_type,
    f.total_area_hectares,
    f.organic_certified,

    -- Land utilization
    COALESCE(land.fields_count, 0) AS total_fields,
    COALESCE(land.planted_area, 0) AS planted_hectares,
    ROUND(COALESCE(land.planted_area / f.total_area_hectares * 100, 0), 1) AS land_utilization_pct,

    -- Crop diversity
    COALESCE(crops.crop_varieties, 0) AS crop_varieties,
    COALESCE(crops.expected_harvest_value, 0) AS expected_harvest_value,

    -- Water usage
    COALESCE(water.total_water_used_m3, 0) AS water_used_m3_mtd,
    COALESCE(water.irrigation_events, 0) AS irrigation_events_mtd,

    -- Livestock
    COALESCE(livestock.total_animals, 0) AS livestock_count,
    COALESCE(livestock.healthy_pct, 0) AS livestock_healthy_pct,
    COALESCE(milk.monthly_production, 0) AS milk_production_liters_mtd,

    -- Financial
    COALESCE(finance.monthly_costs, 0) AS costs_mtd,
    COALESCE(finance.expected_revenue, 0) AS expected_revenue_mtd

FROM farms f

-- Land utilization
LEFT JOIN (
    SELECT
        fd.farm_id,
        COUNT(DISTINCT fd.field_id) AS fields_count,
        SUM(pr.area_planted_hectares) AS planted_area
    FROM fields fd
    LEFT JOIN planting_records pr ON fd.field_id = pr.field_id
        AND pr.status IN ('planted', 'growing')
    GROUP BY fd.farm_id
) land ON f.farm_id = land.farm_id

-- Crop information
LEFT JOIN (
    SELECT
        fd.farm_id,
        COUNT(DISTINCT pr.crop_id) AS crop_varieties,
        SUM(pr.area_planted_hectares * pr.expected_yield_kg_per_hectare * 2.5) AS expected_harvest_value
    FROM planting_records pr
    INNER JOIN fields fd ON pr.field_id = fd.field_id
    WHERE pr.status = 'growing'
    GROUP BY fd.farm_id
) crops ON f.farm_id = crops.farm_id

-- Water usage
LEFT JOIN (
    SELECT
        fd.farm_id,
        COUNT(DISTINCT ie.event_id) AS irrigation_events,
        SUM(ie.water_amount_liters) / 1000 AS total_water_used_m3
    FROM irrigation_events ie
    INNER JOIN irrigation_systems isys ON ie.system_id = isys.system_id
    INNER JOIN fields fd ON isys.field_id = fd.field_id
    WHERE ie.start_time >= DATE_FORMAT(CURDATE(), '%Y-%m-01')
    GROUP BY fd.farm_id
) water ON f.farm_id = water.farm_id

-- Livestock
LEFT JOIN (
    SELECT
        farm_id,
        COUNT(*) AS total_animals,
        SUM(CASE WHEN health_status = 'healthy' THEN 1 ELSE 0 END) / COUNT(*) * 100 AS healthy_pct
    FROM animals
    WHERE health_status != 'deceased'
    GROUP BY farm_id
) livestock ON f.farm_id = livestock.farm_id

-- Milk production
LEFT JOIN (
    SELECT
        a.farm_id,
        SUM(mp.quantity_liters) AS monthly_production
    FROM milk_production mp
    INNER JOIN animals a ON mp.animal_id = a.animal_id
    WHERE mp.milking_date >= DATE_FORMAT(CURDATE(), '%Y-%m-01')
    GROUP BY a.farm_id
) milk ON f.farm_id = milk.farm_id

-- Financial summary
LEFT JOIN (
    SELECT
        fd.farm_id,
        SUM(fa.cost_per_hectare * z.area_hectares) +
        SUM(pa.application_rate_per_hectare * z.area_hectares * 50) AS monthly_costs,
        0 AS expected_revenue  -- Placeholder for revenue calculation
    FROM fields fd
    LEFT JOIN zones z ON fd.field_id = z.field_id
    LEFT JOIN fertilizer_applications fa ON fd.field_id = fa.field_id
        AND fa.application_date >= DATE_FORMAT(CURDATE(), '%Y-%m-01')
    LEFT JOIN pesticide_applications pa ON fd.field_id = pa.field_id
        AND pa.application_date >= DATE_FORMAT(CURDATE(), '%Y-%m-01')
    GROUP BY fd.farm_id
) finance ON f.farm_id = finance.farm_id

ORDER BY f.farm_name;

-- ============================================================================
-- Crop Production Report
-- ============================================================================

-- Detailed crop production status
SELECT
    f.farm_name,
    fd.field_name,
    c.crop_name,
    pr.variety,
    pr.planting_date,
    pr.expected_harvest_date,
    pr.status,
    pr.area_planted_hectares,
    pr.seed_rate_kg_per_hectare,
    pr.expected_yield_kg_per_hectare,
    COALESCE(gs.current_stage, 'Not recorded') AS growth_stage,
    COALESCE(gs.gdd_accumulated, 0) AS gdd_accumulated,
    DATEDIFF(pr.expected_harvest_date, CURDATE()) AS days_to_harvest,
    COALESCE(yp.predicted_yield, pr.expected_yield_kg_per_hectare) AS predicted_yield,
    COALESCE(yp.confidence_level, 0) AS prediction_confidence,
    COALESCE(fert.applications, 0) AS fertilizer_applications,
    COALESCE(pest.applications, 0) AS pesticide_applications,
    COALESCE(irr.events, 0) AS irrigation_events,
    COALESCE(irr.total_water_liters, 0) AS total_water_applied
FROM planting_records pr
INNER JOIN fields fd ON pr.field_id = fd.field_id
INNER JOIN farms f ON fd.farm_id = f.farm_id
INNER JOIN crops c ON pr.crop_id = c.crop_id
LEFT JOIN (
    SELECT planting_id, MAX(stage_name) AS current_stage, MAX(gdd_accumulated) AS gdd_accumulated
    FROM growth_stages
    GROUP BY planting_id
) gs ON pr.planting_id = gs.planting_id
LEFT JOIN (
    SELECT planting_id, predicted_yield_kg_per_hectare AS predicted_yield, confidence_level
    FROM yield_predictions
    WHERE (planting_id, prediction_date) IN (
        SELECT planting_id, MAX(prediction_date)
        FROM yield_predictions
        GROUP BY planting_id
    )
) yp ON pr.planting_id = yp.planting_id
LEFT JOIN (
    SELECT field_id, COUNT(*) AS applications
    FROM fertilizer_applications
    WHERE application_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY field_id
) fert ON pr.field_id = fert.field_id
LEFT JOIN (
    SELECT field_id, COUNT(*) AS applications
    FROM pesticide_applications
    WHERE application_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY field_id
) pest ON pr.field_id = pest.field_id
LEFT JOIN (
    SELECT
        z.field_id,
        COUNT(ie.event_id) AS events,
        SUM(ie.water_amount_liters) AS total_water_liters
    FROM irrigation_events ie
    INNER JOIN zones z ON ie.zone_id = z.zone_id
    WHERE ie.start_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY z.field_id
) irr ON pr.field_id = irr.field_id
WHERE pr.status IN ('planted', 'growing')
ORDER BY f.farm_name, pr.expected_harvest_date;

-- ============================================================================
-- Harvest Summary Report
-- ============================================================================

-- Monthly harvest report
SELECT
    DATE_FORMAT(hr.harvest_date, '%Y-%m') AS harvest_month,
    f.farm_name,
    c.crop_name,
    COUNT(DISTINCT hr.harvest_id) AS harvests,
    SUM(hr.area_harvested_hectares) AS total_area,
    SUM(hr.total_yield_kg) AS total_yield_kg,
    SUM(hr.marketable_yield_kg) AS marketable_yield_kg,
    ROUND(AVG(hr.marketable_yield_kg / hr.total_yield_kg * 100), 1) AS marketable_pct,
    ROUND(AVG(hr.total_yield_kg / hr.area_harvested_hectares), 0) AS avg_yield_per_hectare,
    AVG(hr.moisture_percentage) AS avg_moisture,
    GROUP_CONCAT(DISTINCT hr.quality_grade) AS quality_grades,
    SUM(hr.harvest_cost) AS total_harvest_cost,
    SUM(hr.labor_hours) AS total_labor_hours
FROM harvest_records hr
INNER JOIN planting_records pr ON hr.planting_id = pr.planting_id
INNER JOIN crops c ON pr.crop_id = c.crop_id
INNER JOIN fields fd ON pr.field_id = fd.field_id
INNER JOIN farms f ON fd.farm_id = f.farm_id
WHERE hr.harvest_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY DATE_FORMAT(hr.harvest_date, '%Y-%m'), f.farm_id, c.crop_id
ORDER BY harvest_month DESC, f.farm_name, c.crop_name;

-- ============================================================================
-- Irrigation Efficiency Report
-- ============================================================================

-- Water usage efficiency by field and system
SELECT
    f.farm_name,
    fd.field_name,
    isys.system_type,
    isys.efficiency_percentage AS system_efficiency,
    COUNT(DISTINCT ie.event_id) AS irrigation_events_30d,
    SUM(ie.water_amount_liters) / 1000 AS water_used_m3_30d,
    AVG(TIMESTAMPDIFF(MINUTE, ie.start_time, ie.end_time)) AS avg_duration_minutes,
    AVG(ie.soil_moisture_before) AS avg_moisture_before,
    AVG(ie.soil_moisture_after) AS avg_moisture_after,
    AVG(ie.soil_moisture_after - ie.soil_moisture_before) AS avg_moisture_gain,
    SUM(CASE WHEN ie.trigger_type = 'sensor' THEN 1 ELSE 0 END) AS sensor_triggered,
    SUM(CASE WHEN ie.trigger_type = 'scheduled' THEN 1 ELSE 0 END) AS scheduled,
    SUM(CASE WHEN ie.trigger_type = 'manual' THEN 1 ELSE 0 END) AS manual,
    ROUND(SUM(ie.water_amount_liters) / fd.area_hectares / 30, 2) AS daily_mm_equivalent
FROM irrigation_systems isys
INNER JOIN fields fd ON isys.field_id = fd.field_id
INNER JOIN farms f ON fd.farm_id = f.farm_id
LEFT JOIN irrigation_events ie ON isys.system_id = ie.system_id
    AND ie.start_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
WHERE isys.is_active = TRUE
GROUP BY isys.system_id
ORDER BY f.farm_name, fd.field_name;

-- ============================================================================
-- Livestock Health Report
-- ============================================================================

-- Animal health status and veterinary costs
SELECT
    f.farm_name,
    a.animal_type,
    COUNT(DISTINCT a.animal_id) AS total_count,
    AVG(DATEDIFF(CURDATE(), a.birth_date) / 365.25) AS avg_age_years,
    AVG(a.weight_kg) AS avg_weight_kg,
    SUM(CASE WHEN a.health_status = 'healthy' THEN 1 ELSE 0 END) AS healthy,
    SUM(CASE WHEN a.health_status = 'sick' THEN 1 ELSE 0 END) AS sick,
    SUM(CASE WHEN a.health_status = 'quarantine' THEN 1 ELSE 0 END) AS quarantine,
    COUNT(DISTINCT hr.record_id) AS health_events_30d,
    SUM(CASE WHEN hr.record_type = 'vaccination' THEN 1 ELSE 0 END) AS vaccinations_30d,
    SUM(CASE WHEN hr.record_type = 'treatment' THEN 1 ELSE 0 END) AS treatments_30d,
    COALESCE(SUM(hr.cost), 0) AS veterinary_costs_30d,
    COALESCE(mp.milk_production, 0) AS milk_production_30d
FROM animals a
INNER JOIN farms f ON a.farm_id = f.farm_id
LEFT JOIN health_records hr ON a.animal_id = hr.animal_id
    AND hr.record_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
LEFT JOIN (
    SELECT
        animal_id,
        SUM(quantity_liters) AS milk_production
    FROM milk_production
    WHERE milking_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY animal_id
) mp ON a.animal_id = mp.animal_id
WHERE a.health_status != 'deceased'
GROUP BY f.farm_id, a.animal_type
ORDER BY f.farm_name, a.animal_type;

-- ============================================================================
-- Compliance and Certification Report
-- ============================================================================

-- PHI and REI compliance status
SELECT
    f.farm_name,
    fd.field_name,
    c.crop_name,
    pa.product_name,
    pa.active_ingredient,
    pa.application_date,
    pa.phi_days,
    pa.rei_hours,
    DATE_ADD(pa.application_date, INTERVAL pa.phi_days DAY) AS phi_end_date,
    DATE_ADD(pa.application_date, INTERVAL pa.rei_hours HOUR) AS rei_end_time,
    pr.expected_harvest_date,
    CASE
        WHEN pr.expected_harvest_date < DATE_ADD(pa.application_date, INTERVAL pa.phi_days DAY)
        THEN 'PHI VIOLATION RISK'
        WHEN DATEDIFF(pr.expected_harvest_date, DATE_ADD(pa.application_date, INTERVAL pa.phi_days DAY)) <= 7
        THEN 'PHI WARNING'
        ELSE 'COMPLIANT'
    END AS phi_compliance,
    CASE
        WHEN NOW() < DATE_ADD(pa.application_date, INTERVAL pa.rei_hours HOUR)
        THEN CONCAT('REI ACTIVE - ',
                   TIMESTAMPDIFF(HOUR, NOW(), DATE_ADD(pa.application_date, INTERVAL pa.rei_hours HOUR)),
                   ' hours remaining')
        ELSE 'REI CLEARED'
    END AS rei_status
FROM pesticide_applications pa
INNER JOIN fields fd ON pa.field_id = fd.field_id
INNER JOIN farms f ON fd.farm_id = f.farm_id
LEFT JOIN planting_records pr ON fd.field_id = pr.field_id
    AND pr.status = 'growing'
LEFT JOIN crops c ON pr.crop_id = c.crop_id
WHERE pa.application_date >= DATE_SUB(CURDATE(), INTERVAL 60 DAY)
ORDER BY phi_compliance, pa.application_date DESC;

-- ============================================================================
-- Weather Impact Report
-- ============================================================================

-- Weather summary and agricultural impacts
SELECT
    ws.station_name,
    f.farm_name,
    DATE(wd.observation_time) AS date,
    MIN(wd.temperature_c) AS min_temp,
    MAX(wd.temperature_c) AS max_temp,
    AVG(wd.temperature_c) AS avg_temp,
    SUM(wd.rainfall_mm) AS total_rainfall,
    AVG(wd.humidity_percent) AS avg_humidity,
    MAX(wd.wind_speed_kmh) AS max_wind_speed,
    AVG(wd.solar_radiation_wm2) AS avg_solar_radiation,
    SUM(wd.evapotranspiration_mm) AS total_et,
    calculate_gdd(MIN(wd.temperature_c), MAX(wd.temperature_c), 10) AS gdd_accumulated,
    CASE
        WHEN MIN(wd.temperature_c) < 0 THEN 'FROST'
        WHEN MAX(wd.temperature_c) > 35 THEN 'HEAT STRESS'
        WHEN SUM(wd.rainfall_mm) > 50 THEN 'EXCESSIVE RAIN'
        WHEN SUM(wd.rainfall_mm) < 2 AND AVG(wd.temperature_c) > 25 THEN 'DROUGHT RISK'
        ELSE 'NORMAL'
    END AS agricultural_alert
FROM weather_data wd
INNER JOIN weather_stations ws ON wd.station_id = ws.station_id
INNER JOIN farms f ON ws.farm_id = f.farm_id
WHERE wd.observation_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY ws.station_id, f.farm_id, DATE(wd.observation_time)
ORDER BY date DESC, f.farm_name;