-- ============================================================================
-- Smart Agriculture Analytics Queries
-- ============================================================================

USE smart_agriculture;

-- ============================================================================
-- Crop Yield Analysis
-- ============================================================================

-- Yield performance by crop and field
SELECT
    c.crop_name,
    c.crop_type,
    f.farm_name,
    fd.field_name,
    COUNT(DISTINCT hr.harvest_id) AS harvests,
    SUM(hr.area_harvested_hectares) AS total_area_harvested,
    SUM(hr.total_yield_kg) AS total_yield_kg,
    AVG(hr.total_yield_kg / hr.area_harvested_hectares) AS avg_yield_kg_per_hectare,
    MAX(hr.total_yield_kg / hr.area_harvested_hectares) AS best_yield_kg_per_hectare,
    MIN(hr.total_yield_kg / hr.area_harvested_hectares) AS worst_yield_kg_per_hectare,
    AVG(hr.marketable_yield_kg / hr.total_yield_kg * 100) AS avg_marketable_pct,
    AVG(pr.expected_yield_kg_per_hectare) AS avg_expected_yield,
    AVG((hr.total_yield_kg / hr.area_harvested_hectares) / pr.expected_yield_kg_per_hectare * 100) AS yield_achievement_pct
FROM harvest_records hr
INNER JOIN planting_records pr ON hr.planting_id = pr.planting_id
INNER JOIN crops c ON pr.crop_id = c.crop_id
INNER JOIN fields fd ON pr.field_id = fd.field_id
INNER JOIN farms f ON fd.farm_id = f.farm_id
WHERE hr.harvest_date >= DATE_SUB(CURDATE(), INTERVAL 365 DAY)
GROUP BY c.crop_id, f.farm_id, fd.field_id
ORDER BY avg_yield_kg_per_hectare DESC;

-- Yield correlation with environmental factors
WITH yield_environment AS (
    SELECT
        pr.planting_id,
        c.crop_name,
        hr.total_yield_kg / hr.area_harvested_hectares AS yield_per_hectare,
        AVG(wd.temperature_c) AS avg_temperature,
        SUM(wd.rainfall_mm) AS total_rainfall,
        AVG(wd.solar_radiation_wm2) AS avg_solar_radiation,
        COUNT(DISTINCT ie.event_id) AS irrigation_events,
        SUM(ie.water_amount_liters) / pr.area_planted_hectares AS water_per_hectare
    FROM harvest_records hr
    INNER JOIN planting_records pr ON hr.planting_id = pr.planting_id
    INNER JOIN crops c ON pr.crop_id = c.crop_id
    INNER JOIN fields fd ON pr.field_id = fd.field_id
    LEFT JOIN weather_stations ws ON fd.farm_id = ws.farm_id
    LEFT JOIN weather_data wd ON ws.station_id = wd.station_id
        AND wd.observation_time BETWEEN pr.planting_date AND hr.harvest_date
    LEFT JOIN irrigation_events ie ON ie.zone_id IN (
        SELECT zone_id FROM zones WHERE field_id = fd.field_id
    ) AND ie.start_time BETWEEN pr.planting_date AND hr.harvest_date
    WHERE hr.harvest_date >= DATE_SUB(CURDATE(), INTERVAL 180 DAY)
    GROUP BY pr.planting_id
)
SELECT
    crop_name,
    COUNT(*) AS samples,
    ROUND(AVG(yield_per_hectare), 0) AS avg_yield,
    ROUND(AVG(avg_temperature), 1) AS avg_temp_c,
    ROUND(AVG(total_rainfall), 0) AS avg_rainfall_mm,
    ROUND(AVG(water_per_hectare), 0) AS avg_irrigation_liters,
    ROUND(CORR(yield_per_hectare, avg_temperature), 3) AS temp_correlation,
    ROUND(CORR(yield_per_hectare, total_rainfall), 3) AS rainfall_correlation,
    ROUND(CORR(yield_per_hectare, water_per_hectare), 3) AS irrigation_correlation
FROM yield_environment
GROUP BY crop_name
HAVING COUNT(*) >= 5;

-- ============================================================================
-- Water Usage Analytics
-- ============================================================================

-- Water efficiency by irrigation method and crop
SELECT
    isys.system_type AS irrigation_method,
    c.crop_name,
    COUNT(DISTINCT ie.event_id) AS irrigation_count,
    SUM(ie.water_amount_liters) AS total_water_liters,
    AVG(ie.water_amount_liters) AS avg_water_per_event,
    SUM(pr.area_planted_hectares) AS total_area_hectares,
    SUM(ie.water_amount_liters) / SUM(pr.area_planted_hectares) AS liters_per_hectare,
    AVG(hr.total_yield_kg / hr.area_harvested_hectares) AS avg_yield_kg_per_hectare,
    (AVG(hr.total_yield_kg / hr.area_harvested_hectares) /
     (SUM(ie.water_amount_liters) / SUM(pr.area_planted_hectares))) * 1000 AS kg_per_1000_liters,
    isys.efficiency_percentage AS system_efficiency
FROM irrigation_events ie
INNER JOIN irrigation_systems isys ON ie.system_id = isys.system_id
INNER JOIN fields fd ON isys.field_id = fd.field_id
LEFT JOIN zones z ON ie.zone_id = z.zone_id
INNER JOIN planting_records pr ON fd.field_id = pr.field_id
    AND pr.planting_date <= ie.start_time
    AND (pr.actual_harvest_date IS NULL OR pr.actual_harvest_date >= ie.start_time)
INNER JOIN crops c ON pr.crop_id = c.crop_id
LEFT JOIN harvest_records hr ON pr.planting_id = hr.planting_id
WHERE ie.start_time >= DATE_SUB(CURDATE(), INTERVAL 365 DAY)
GROUP BY isys.system_type, c.crop_name, isys.efficiency_percentage
ORDER BY kg_per_1000_liters DESC;

-- Water usage trends and conservation
SELECT
    DATE_FORMAT(ie.start_time, '%Y-%m') AS month,
    COUNT(DISTINCT ie.event_id) AS irrigation_events,
    SUM(ie.water_amount_liters) / 1000 AS total_water_cubic_meters,
    AVG(ie.water_amount_liters) AS avg_water_per_event,
    SUM(TIMESTAMPDIFF(MINUTE, ie.start_time, ie.end_time)) / 60 AS total_irrigation_hours,
    COUNT(DISTINCT isys.system_id) AS systems_used,
    AVG(ie.soil_moisture_after - ie.soil_moisture_before) AS avg_moisture_increase,
    SUM(CASE WHEN ie.trigger_type = 'sensor' THEN 1 ELSE 0 END) / COUNT(*) * 100 AS sensor_triggered_pct,
    SUM(CASE WHEN ie.trigger_type = 'manual' THEN 1 ELSE 0 END) / COUNT(*) * 100 AS manual_triggered_pct
FROM irrigation_events ie
INNER JOIN irrigation_systems isys ON ie.system_id = isys.system_id
WHERE ie.start_time >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY DATE_FORMAT(ie.start_time, '%Y-%m')
ORDER BY month DESC;

-- ============================================================================
-- Soil Health Analytics
-- ============================================================================

-- Soil parameter trends by zone
WITH soil_metrics AS (
    SELECT
        z.zone_id,
        z.zone_name,
        fd.field_name,
        s.sensor_type,
        DATE(sr.timestamp) AS reading_date,
        AVG(sr.value) AS avg_value,
        MIN(sr.value) AS min_value,
        MAX(sr.value) AS max_value
    FROM sensor_readings sr
    INNER JOIN sensors s ON sr.sensor_id = s.sensor_id
    INNER JOIN zones z ON s.zone_id = z.zone_id
    INNER JOIN fields fd ON z.field_id = fd.field_id
    WHERE s.sensor_type IN ('soil_moisture', 'soil_temperature', 'soil_ph', 'soil_ec')
        AND sr.timestamp >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY z.zone_id, s.sensor_type, DATE(sr.timestamp)
)
SELECT
    field_name,
    zone_name,
    sensor_type,
    AVG(avg_value) AS overall_avg,
    MIN(min_value) AS overall_min,
    MAX(max_value) AS overall_max,
    STDDEV(avg_value) AS daily_variation,
    CASE sensor_type
        WHEN 'soil_moisture' THEN
            CASE
                WHEN AVG(avg_value) < 30 THEN 'TOO DRY'
                WHEN AVG(avg_value) > 80 THEN 'TOO WET'
                ELSE 'OPTIMAL'
            END
        WHEN 'soil_ph' THEN
            CASE
                WHEN AVG(avg_value) < 6.0 THEN 'ACIDIC'
                WHEN AVG(avg_value) > 7.5 THEN 'ALKALINE'
                ELSE 'OPTIMAL'
            END
        WHEN 'soil_temperature' THEN
            CASE
                WHEN AVG(avg_value) < 15 THEN 'COLD'
                WHEN AVG(avg_value) > 30 THEN 'HOT'
                ELSE 'OPTIMAL'
            END
        ELSE 'CHECK'
    END AS health_status
FROM soil_metrics
GROUP BY field_name, zone_name, sensor_type
ORDER BY field_name, zone_name, sensor_type;

-- Fertilizer application effectiveness
SELECT
    fd.field_name,
    fa.fertilizer_type,
    fa.application_date,
    fa.n_kg_per_hectare + fa.p_kg_per_hectare + fa.k_kg_per_hectare AS total_npk,
    fa.cost_per_hectare,
    pr.crop_name,
    pr.yield_after AS yield_kg_per_hectare_after,
    pr.yield_before AS yield_kg_per_hectare_before,
    ((pr.yield_after - pr.yield_before) / pr.yield_before * 100) AS yield_improvement_pct,
    (pr.yield_after - pr.yield_before) / (fa.n_kg_per_hectare + fa.p_kg_per_hectare + fa.k_kg_per_hectare) AS kg_yield_per_kg_fertilizer,
    ((pr.yield_after - pr.yield_before) * pr.market_price - fa.cost_per_hectare) AS net_benefit_per_hectare
FROM fertilizer_applications fa
INNER JOIN fields fd ON fa.field_id = fd.field_id
INNER JOIN (
    SELECT
        pr.field_id,
        c.crop_name,
        AVG(hr1.total_yield_kg / hr1.area_harvested_hectares) AS yield_before,
        AVG(hr2.total_yield_kg / hr2.area_harvested_hectares) AS yield_after,
        50 AS market_price -- Assumed price per kg
    FROM planting_records pr
    INNER JOIN crops c ON pr.crop_id = c.crop_id
    INNER JOIN harvest_records hr1 ON pr.planting_id = hr1.planting_id
    LEFT JOIN planting_records pr2 ON pr.field_id = pr2.field_id
        AND pr2.planting_date > pr.actual_harvest_date
    LEFT JOIN harvest_records hr2 ON pr2.planting_id = hr2.planting_id
    GROUP BY pr.field_id, c.crop_name
) pr ON fa.field_id = pr.field_id
WHERE fa.application_date >= DATE_SUB(CURDATE(), INTERVAL 365 DAY)
ORDER BY yield_improvement_pct DESC;

-- ============================================================================
-- Livestock Analytics
-- ============================================================================

-- Milk production trends and quality
SELECT
    DATE_FORMAT(mp.milking_date, '%Y-%m') AS month,
    COUNT(DISTINCT mp.animal_id) AS unique_cows,
    COUNT(*) AS total_milkings,
    SUM(mp.quantity_liters) AS total_liters,
    AVG(mp.quantity_liters) AS avg_liters_per_milking,
    AVG(mp.fat_percentage) AS avg_fat_pct,
    AVG(mp.protein_percentage) AS avg_protein_pct,
    AVG(mp.somatic_cell_count) AS avg_scc,
    SUM(CASE WHEN mp.quality_grade = 'A' THEN 1 ELSE 0 END) / COUNT(*) * 100 AS grade_a_pct,
    SUM(mp.quantity_liters *
        CASE mp.quality_grade
            WHEN 'A' THEN 1.0
            WHEN 'B' THEN 0.9
            WHEN 'C' THEN 0.8
            ELSE 0.5
        END) AS quality_adjusted_liters
FROM milk_production mp
WHERE mp.milking_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY DATE_FORMAT(mp.milking_date, '%Y-%m')
ORDER BY month DESC;

-- Animal health and treatment costs
SELECT
    a.animal_type,
    COUNT(DISTINCT a.animal_id) AS animal_count,
    COUNT(hr.record_id) AS health_events,
    SUM(CASE WHEN hr.record_type = 'vaccination' THEN 1 ELSE 0 END) AS vaccinations,
    SUM(CASE WHEN hr.record_type = 'treatment' THEN 1 ELSE 0 END) AS treatments,
    SUM(hr.cost) AS total_health_cost,
    AVG(hr.cost) AS avg_cost_per_event,
    SUM(hr.cost) / COUNT(DISTINCT a.animal_id) AS health_cost_per_animal,
    AVG(a.weight_kg) AS avg_weight_kg,
    SUM(CASE WHEN a.health_status = 'healthy' THEN 1 ELSE 0 END) / COUNT(*) * 100 AS healthy_pct
FROM animals a
LEFT JOIN health_records hr ON a.animal_id = hr.animal_id
    AND hr.record_date >= DATE_SUB(CURDATE(), INTERVAL 365 DAY)
WHERE a.health_status != 'deceased'
GROUP BY a.animal_type
ORDER BY total_health_cost DESC;

-- ============================================================================
-- Cost-Benefit Analysis
-- ============================================================================

-- Field profitability analysis
WITH field_costs AS (
    SELECT
        fd.field_id,
        fd.field_name,
        fd.area_hectares,
        SUM(fa.cost_per_hectare * COALESCE(fa.zone_id, fd.area_hectares)) AS fertilizer_cost,
        SUM(pa.application_rate_per_hectare * COALESCE(pa.zone_id, fd.area_hectares) * 50) AS pesticide_cost,
        SUM(ie.water_amount_liters * 0.001) AS water_cost,  -- Assuming $0.001 per liter
        SUM(hr.harvest_cost) AS harvest_cost,
        SUM(hr.labor_hours * 15) AS labor_cost  -- Assuming $15/hour
    FROM fields fd
    LEFT JOIN fertilizer_applications fa ON fd.field_id = fa.field_id
        AND fa.application_date >= DATE_SUB(CURDATE(), INTERVAL 365 DAY)
    LEFT JOIN pesticide_applications pa ON fd.field_id = pa.field_id
        AND pa.application_date >= DATE_SUB(CURDATE(), INTERVAL 365 DAY)
    LEFT JOIN irrigation_systems isys ON fd.field_id = isys.field_id
    LEFT JOIN irrigation_events ie ON isys.system_id = ie.system_id
        AND ie.start_time >= DATE_SUB(CURDATE(), INTERVAL 365 DAY)
    LEFT JOIN planting_records pr ON fd.field_id = pr.field_id
    LEFT JOIN harvest_records hr ON pr.planting_id = hr.planting_id
        AND hr.harvest_date >= DATE_SUB(CURDATE(), INTERVAL 365 DAY)
    GROUP BY fd.field_id
),
field_revenue AS (
    SELECT
        pr.field_id,
        SUM(hr.marketable_yield_kg * 2.5) AS revenue  -- Assuming $2.5/kg
    FROM planting_records pr
    INNER JOIN harvest_records hr ON pr.planting_id = hr.planting_id
    WHERE hr.harvest_date >= DATE_SUB(CURDATE(), INTERVAL 365 DAY)
    GROUP BY pr.field_id
)
SELECT
    f.farm_name,
    fc.field_name,
    fc.area_hectares,
    ROUND(COALESCE(fr.revenue, 0), 2) AS total_revenue,
    ROUND(COALESCE(fc.fertilizer_cost, 0), 2) AS fertilizer_cost,
    ROUND(COALESCE(fc.pesticide_cost, 0), 2) AS pesticide_cost,
    ROUND(COALESCE(fc.water_cost, 0), 2) AS water_cost,
    ROUND(COALESCE(fc.harvest_cost, 0), 2) AS harvest_cost,
    ROUND(COALESCE(fc.labor_cost, 0), 2) AS labor_cost,
    ROUND(COALESCE(fc.fertilizer_cost + fc.pesticide_cost + fc.water_cost + fc.harvest_cost + fc.labor_cost, 0), 2) AS total_costs,
    ROUND(COALESCE(fr.revenue, 0) - COALESCE(fc.fertilizer_cost + fc.pesticide_cost + fc.water_cost + fc.harvest_cost + fc.labor_cost, 0), 2) AS net_profit,
    ROUND((COALESCE(fr.revenue, 0) - COALESCE(fc.fertilizer_cost + fc.pesticide_cost + fc.water_cost + fc.harvest_cost + fc.labor_cost, 0)) / fc.area_hectares, 2) AS profit_per_hectare
FROM field_costs fc
INNER JOIN fields fd ON fc.field_id = fd.field_id
INNER JOIN farms f ON fd.farm_id = f.farm_id
LEFT JOIN field_revenue fr ON fc.field_id = fr.field_id
ORDER BY profit_per_hectare DESC;