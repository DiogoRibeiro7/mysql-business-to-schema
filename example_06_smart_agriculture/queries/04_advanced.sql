-- ============================================================================
-- Smart Agriculture Advanced Queries
-- ============================================================================

USE smart_agriculture;

-- ============================================================================
-- Yield Prediction Models
-- ============================================================================

-- Machine learning features for yield prediction
WITH environmental_features AS (
    SELECT
        pr.planting_id,
        pr.field_id,
        c.crop_name,
        pr.planting_date,
        pr.expected_harvest_date,
        pr.area_planted_hectares,

        -- Soil features
        AVG(CASE WHEN s.sensor_type = 'soil_moisture' THEN sr.value END) AS avg_soil_moisture,
        STDDEV(CASE WHEN s.sensor_type = 'soil_moisture' THEN sr.value END) AS std_soil_moisture,
        AVG(CASE WHEN s.sensor_type = 'soil_temperature' THEN sr.value END) AS avg_soil_temp,
        AVG(CASE WHEN s.sensor_type = 'soil_ph' THEN sr.value END) AS avg_soil_ph,

        -- Weather features
        AVG(wd.temperature_c) AS avg_air_temp,
        SUM(wd.rainfall_mm) AS total_rainfall,
        AVG(wd.humidity_percent) AS avg_humidity,
        SUM(wd.solar_radiation_wm2) AS total_solar_radiation,
        SUM(calculate_gdd(wd.temperature_c - 5, wd.temperature_c + 5, c.base_temperature_c)) AS total_gdd,

        -- Management features
        COUNT(DISTINCT fa.application_id) AS fertilizer_applications,
        SUM(fa.n_kg_per_hectare + fa.p_kg_per_hectare + fa.k_kg_per_hectare) AS total_npk,
        COUNT(DISTINCT pa.application_id) AS pesticide_applications,
        COUNT(DISTINCT ie.event_id) AS irrigation_events,
        SUM(ie.water_amount_liters) / pr.area_planted_hectares AS water_per_hectare,

        -- Historical yield (for training)
        hr.total_yield_kg / hr.area_harvested_hectares AS actual_yield_per_hectare

    FROM planting_records pr
    INNER JOIN crops c ON pr.crop_id = c.crop_id
    INNER JOIN fields fd ON pr.field_id = fd.field_id

    -- Soil sensor data
    LEFT JOIN zones z ON fd.field_id = z.field_id
    LEFT JOIN sensors s ON z.zone_id = s.zone_id
    LEFT JOIN sensor_readings sr ON s.sensor_id = sr.sensor_id
        AND sr.timestamp BETWEEN pr.planting_date AND COALESCE(pr.actual_harvest_date, pr.expected_harvest_date)

    -- Weather data
    LEFT JOIN weather_stations ws ON fd.farm_id = ws.farm_id
    LEFT JOIN weather_data wd ON ws.station_id = wd.station_id
        AND DATE(wd.observation_time) BETWEEN pr.planting_date AND COALESCE(pr.actual_harvest_date, pr.expected_harvest_date)

    -- Management practices
    LEFT JOIN fertilizer_applications fa ON pr.field_id = fa.field_id
        AND fa.application_date BETWEEN pr.planting_date AND COALESCE(pr.actual_harvest_date, pr.expected_harvest_date)
    LEFT JOIN pesticide_applications pa ON pr.field_id = pa.field_id
        AND pa.application_date BETWEEN pr.planting_date AND COALESCE(pr.actual_harvest_date, pr.expected_harvest_date)
    LEFT JOIN irrigation_events ie ON z.zone_id = ie.zone_id
        AND ie.start_time BETWEEN pr.planting_date AND COALESCE(pr.actual_harvest_date, pr.expected_harvest_date)

    -- Historical yield
    LEFT JOIN harvest_records hr ON pr.planting_id = hr.planting_id

    WHERE pr.status IN ('growing', 'harvested')
    GROUP BY pr.planting_id
)
SELECT
    crop_name,
    COUNT(*) AS samples,
    ROUND(AVG(actual_yield_per_hectare), 0) AS avg_yield,
    ROUND(STDDEV(actual_yield_per_hectare), 0) AS std_yield,

    -- Feature importance (correlation with yield)
    ROUND(CORR(avg_soil_moisture, actual_yield_per_hectare), 3) AS moisture_correlation,
    ROUND(CORR(avg_soil_temp, actual_yield_per_hectare), 3) AS temp_correlation,
    ROUND(CORR(total_rainfall, actual_yield_per_hectare), 3) AS rainfall_correlation,
    ROUND(CORR(total_gdd, actual_yield_per_hectare), 3) AS gdd_correlation,
    ROUND(CORR(total_npk, actual_yield_per_hectare), 3) AS fertilizer_correlation,
    ROUND(CORR(water_per_hectare, actual_yield_per_hectare), 3) AS irrigation_correlation,

    -- Optimal ranges (where yield is maximized)
    ROUND(AVG(CASE WHEN actual_yield_per_hectare > AVG(actual_yield_per_hectare) OVER() THEN avg_soil_moisture END), 1) AS optimal_moisture,
    ROUND(AVG(CASE WHEN actual_yield_per_hectare > AVG(actual_yield_per_hectare) OVER() THEN total_rainfall END), 0) AS optimal_rainfall,
    ROUND(AVG(CASE WHEN actual_yield_per_hectare > AVG(actual_yield_per_hectare) OVER() THEN total_npk END), 0) AS optimal_npk

FROM environmental_features
WHERE actual_yield_per_hectare IS NOT NULL
GROUP BY crop_name
HAVING COUNT(*) >= 5;

-- ============================================================================
-- Precision Irrigation Optimization
-- ============================================================================

-- Water stress index and irrigation recommendations
WITH soil_moisture_analysis AS (
    SELECT
        z.zone_id,
        z.zone_name,
        fd.field_name,
        c.crop_name,
        c.water_needs_mm_per_day,

        -- Current moisture levels
        AVG(CASE WHEN DATE(sr.timestamp) = CURDATE() THEN sr.value END) AS moisture_today,
        AVG(CASE WHEN DATE(sr.timestamp) = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN sr.value END) AS moisture_yesterday,
        AVG(CASE WHEN DATE(sr.timestamp) >= DATE_SUB(CURDATE(), INTERVAL 7 DAY) THEN sr.value END) AS moisture_7d_avg,

        -- Moisture depletion rate
        (AVG(CASE WHEN DATE(sr.timestamp) = DATE_SUB(CURDATE(), INTERVAL 7 DAY) THEN sr.value END) -
         AVG(CASE WHEN DATE(sr.timestamp) = CURDATE() THEN sr.value END)) / 7 AS daily_depletion_rate,

        -- Weather forecast impact
        COALESCE(weather.rainfall_forecast, 0) AS rainfall_forecast_mm,
        COALESCE(weather.et_forecast, 3) AS et_forecast_mm,

        -- Last irrigation
        MAX(ie.start_time) AS last_irrigation,
        DATEDIFF(CURDATE(), DATE(MAX(ie.start_time))) AS days_since_irrigation

    FROM zones z
    INNER JOIN fields fd ON z.field_id = fd.field_id
    INNER JOIN planting_records pr ON fd.field_id = pr.field_id AND pr.status = 'growing'
    INNER JOIN crops c ON pr.crop_id = c.crop_id
    LEFT JOIN sensors s ON z.zone_id = s.zone_id AND s.sensor_type = 'soil_moisture'
    LEFT JOIN sensor_readings sr ON s.sensor_id = sr.sensor_id
        AND sr.timestamp >= DATE_SUB(NOW(), INTERVAL 7 DAY)
    LEFT JOIN irrigation_events ie ON z.zone_id = ie.zone_id
    LEFT JOIN (
        SELECT
            ws.farm_id,
            SUM(CASE WHEN DATE(wd.observation_time) = DATE_ADD(CURDATE(), INTERVAL 1 DAY)
                     THEN wd.rainfall_mm END) AS rainfall_forecast,
            AVG(CASE WHEN DATE(wd.observation_time) = DATE_ADD(CURDATE(), INTERVAL 1 DAY)
                     THEN wd.evapotranspiration_mm END) AS et_forecast
        FROM weather_data wd
        INNER JOIN weather_stations ws ON wd.station_id = ws.station_id
        GROUP BY ws.farm_id
    ) weather ON fd.farm_id = weather.farm_id

    GROUP BY z.zone_id
),
irrigation_decision AS (
    SELECT
        zone_id,
        zone_name,
        field_name,
        crop_name,
        moisture_today,
        moisture_7d_avg,
        daily_depletion_rate,
        water_needs_mm_per_day,
        rainfall_forecast_mm,
        et_forecast_mm,
        days_since_irrigation,

        -- Calculate water stress index (0-100, higher = more stress)
        CASE
            WHEN moisture_today < 20 THEN 100
            WHEN moisture_today < 30 THEN 80
            WHEN moisture_today < 40 THEN 60
            WHEN moisture_today < 50 THEN 40
            WHEN moisture_today < 60 THEN 20
            ELSE 0
        END AS water_stress_index,

        -- Days until critical moisture (< 30%)
        CASE
            WHEN daily_depletion_rate > 0 THEN
                ROUND((moisture_today - 30) / daily_depletion_rate, 1)
            ELSE NULL
        END AS days_to_critical,

        -- Recommended irrigation amount (mm)
        GREATEST(0,
            (water_needs_mm_per_day * 3) - rainfall_forecast_mm + et_forecast_mm
        ) AS recommended_irrigation_mm,

        -- Priority score (0-10)
        CASE
            WHEN moisture_today < 30 THEN 10
            WHEN moisture_today < 40 AND rainfall_forecast_mm < 5 THEN 8
            WHEN moisture_today < 50 AND daily_depletion_rate > 5 THEN 6
            WHEN days_since_irrigation > 7 THEN 4
            ELSE 2
        END AS irrigation_priority

    FROM soil_moisture_analysis
)
SELECT
    field_name,
    zone_name,
    crop_name,
    ROUND(moisture_today, 1) AS current_moisture_pct,
    ROUND(moisture_7d_avg, 1) AS avg_moisture_7d,
    ROUND(daily_depletion_rate, 2) AS depletion_rate,
    water_stress_index,
    days_to_critical,
    days_since_irrigation,
    ROUND(recommended_irrigation_mm, 1) AS irrigation_needed_mm,
    irrigation_priority,
    CASE irrigation_priority
        WHEN 10 THEN 'CRITICAL - Irrigate immediately'
        WHEN 8 THEN 'HIGH - Irrigate within 24 hours'
        WHEN 6 THEN 'MEDIUM - Irrigate within 2-3 days'
        WHEN 4 THEN 'LOW - Monitor closely'
        ELSE 'ADEQUATE - No irrigation needed'
    END AS recommendation
FROM irrigation_decision
ORDER BY irrigation_priority DESC, water_stress_index DESC;

-- ============================================================================
-- Disease Risk Prediction
-- ============================================================================

-- Fungal disease risk based on weather conditions
WITH disease_conditions AS (
    SELECT
        f.farm_name,
        fd.field_name,
        c.crop_name,
        DATE(wd.observation_time) AS date,
        AVG(wd.temperature_c) AS avg_temp,
        AVG(wd.humidity_percent) AS avg_humidity,
        SUM(wd.rainfall_mm) AS daily_rainfall,

        -- Leaf wetness duration estimate (hours with humidity > 90%)
        SUM(CASE WHEN wd.humidity_percent > 90 THEN 1 ELSE 0 END) AS leaf_wetness_hours,

        -- Disease favorability scores
        CASE
            WHEN c.crop_type = 'cereal' AND AVG(wd.temperature_c) BETWEEN 15 AND 25
                 AND AVG(wd.humidity_percent) > 80 THEN 'HIGH'
            WHEN c.crop_type = 'vegetable' AND AVG(wd.temperature_c) BETWEEN 20 AND 30
                 AND SUM(wd.rainfall_mm) > 10 THEN 'HIGH'
            WHEN AVG(wd.humidity_percent) > 85 AND AVG(wd.temperature_c) > 20 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS fungal_risk,

        CASE
            WHEN AVG(wd.temperature_c) > 30 AND AVG(wd.humidity_percent) < 50 THEN 'HIGH'
            WHEN AVG(wd.temperature_c) > 28 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS heat_stress_risk,

        -- Recent pesticide protection
        MAX(pa.application_date) AS last_fungicide_date,
        DATEDIFF(CURDATE(), MAX(pa.application_date)) AS days_since_fungicide

    FROM weather_data wd
    INNER JOIN weather_stations ws ON wd.station_id = ws.station_id
    INNER JOIN farms f ON ws.farm_id = f.farm_id
    INNER JOIN fields fd ON f.farm_id = fd.farm_id
    INNER JOIN planting_records pr ON fd.field_id = pr.field_id AND pr.status = 'growing'
    INNER JOIN crops c ON pr.crop_id = c.crop_id
    LEFT JOIN pesticide_applications pa ON fd.field_id = pa.field_id
        AND pa.target_pest LIKE '%fung%'
        AND pa.application_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)

    WHERE wd.observation_time >= DATE_SUB(NOW(), INTERVAL 7 DAY)
    GROUP BY f.farm_id, fd.field_id, c.crop_id, DATE(wd.observation_time)
)
SELECT
    farm_name,
    field_name,
    crop_name,
    date,
    ROUND(avg_temp, 1) AS temperature_c,
    ROUND(avg_humidity, 1) AS humidity_pct,
    ROUND(daily_rainfall, 1) AS rainfall_mm,
    leaf_wetness_hours,
    fungal_risk,
    heat_stress_risk,
    days_since_fungicide,
    CASE
        WHEN fungal_risk = 'HIGH' AND (days_since_fungicide > 14 OR days_since_fungicide IS NULL) THEN
            'URGENT - Apply fungicide within 24 hours'
        WHEN fungal_risk = 'HIGH' AND days_since_fungicide <= 14 THEN
            'PROTECTED - Monitor conditions'
        WHEN fungal_risk = 'MEDIUM' AND (days_since_fungicide > 21 OR days_since_fungicide IS NULL) THEN
            'PREVENTIVE - Consider fungicide application'
        WHEN heat_stress_risk = 'HIGH' THEN
            'HEAT STRESS - Increase irrigation'
        ELSE
            'LOW RISK - Continue monitoring'
    END AS action_recommendation
FROM disease_conditions
WHERE date >= DATE_SUB(CURDATE(), INTERVAL 3 DAY)
ORDER BY
    CASE fungal_risk WHEN 'HIGH' THEN 1 WHEN 'MEDIUM' THEN 2 ELSE 3 END,
    date DESC;

-- ============================================================================
-- Crop Rotation Optimization
-- ============================================================================

-- Analyze crop rotation patterns and soil health
WITH rotation_history AS (
    SELECT
        fd.field_id,
        fd.field_name,
        pr.planting_id,
        c.crop_name,
        c.crop_family,
        c.nitrogen_kg_per_hectare,
        pr.planting_date,
        pr.actual_harvest_date,
        LAG(c.crop_name) OVER (PARTITION BY fd.field_id ORDER BY pr.planting_date) AS previous_crop,
        LAG(c.crop_family) OVER (PARTITION BY fd.field_id ORDER BY pr.planting_date) AS previous_family,
        LAG(pr.actual_harvest_date) OVER (PARTITION BY fd.field_id ORDER BY pr.planting_date) AS previous_harvest,
        LEAD(c.crop_name) OVER (PARTITION BY fd.field_id ORDER BY pr.planting_date) AS next_crop,
        hr.total_yield_kg / hr.area_harvested_hectares AS yield_per_hectare
    FROM fields fd
    INNER JOIN planting_records pr ON fd.field_id = pr.field_id
    INNER JOIN crops c ON pr.crop_id = c.crop_id
    LEFT JOIN harvest_records hr ON pr.planting_id = hr.planting_id
    WHERE pr.planting_date >= DATE_SUB(CURDATE(), INTERVAL 3 YEAR)
),
rotation_analysis AS (
    SELECT
        field_name,
        crop_name,
        crop_family,
        previous_crop,
        previous_family,
        planting_date,
        DATEDIFF(planting_date, previous_harvest) AS fallow_days,
        yield_per_hectare,

        -- Rotation score (higher is better)
        CASE
            WHEN crop_family != previous_family THEN 3  -- Different family
            WHEN crop_name != previous_crop THEN 2      -- Different crop, same family
            ELSE 1                                       -- Same crop (monoculture)
        END AS rotation_score,

        -- Nitrogen balance
        CASE
            WHEN crop_family = 'legume' THEN nitrogen_kg_per_hectare * -1  -- Nitrogen fixing
            ELSE nitrogen_kg_per_hectare                                    -- Nitrogen consuming
        END AS nitrogen_impact

    FROM rotation_history
)
SELECT
    field_name,
    GROUP_CONCAT(CONCAT(crop_name, ' (', DATE_FORMAT(planting_date, '%Y'), ')')
                ORDER BY planting_date SEPARATOR ' → ') AS rotation_sequence,
    COUNT(DISTINCT crop_family) AS crop_diversity,
    AVG(rotation_score) AS avg_rotation_score,
    SUM(nitrogen_impact) AS cumulative_nitrogen_balance,
    AVG(fallow_days) AS avg_fallow_period,
    AVG(yield_per_hectare) AS avg_yield,
    CASE
        WHEN AVG(rotation_score) >= 2.5 THEN 'EXCELLENT'
        WHEN AVG(rotation_score) >= 2.0 THEN 'GOOD'
        WHEN AVG(rotation_score) >= 1.5 THEN 'FAIR'
        ELSE 'POOR - Diversify crops'
    END AS rotation_health,
    CASE
        WHEN SUM(nitrogen_impact) > 100 THEN 'Plant nitrogen-fixing crops (legumes)'
        WHEN SUM(nitrogen_impact) < -100 THEN 'Plant nitrogen-demanding crops'
        ELSE 'Balanced'
    END AS recommendation
FROM rotation_analysis
GROUP BY field_name
ORDER BY avg_rotation_score DESC;

-- ============================================================================
-- Livestock Feed Optimization
-- ============================================================================

-- Calculate feed requirements and optimize rations
WITH feed_requirements AS (
    SELECT
        a.farm_id,
        a.animal_type,
        a.animal_id,
        a.weight_kg,
        DATEDIFF(CURDATE(), a.birth_date) / 365.25 AS age_years,

        -- Daily feed requirements (simplified calculation)
        CASE a.animal_type
            WHEN 'cattle' THEN a.weight_kg * 0.025  -- 2.5% of body weight
            WHEN 'sheep' THEN a.weight_kg * 0.035   -- 3.5% of body weight
            WHEN 'goat' THEN a.weight_kg * 0.04     -- 4% of body weight
            WHEN 'pig' THEN a.weight_kg * 0.03      -- 3% of body weight
            ELSE a.weight_kg * 0.02
        END AS daily_feed_kg,

        -- Nutritional requirements
        CASE a.animal_type
            WHEN 'cattle' THEN 12  -- % protein
            WHEN 'pig' THEN 16
            WHEN 'chicken' THEN 18
            ELSE 14
        END AS protein_requirement_pct,

        -- Production adjustments
        CASE
            WHEN mp.animal_id IS NOT NULL THEN 1.3  -- Lactating animals need 30% more
            WHEN a.animal_type = 'cattle' AND age_years < 1 THEN 1.2  -- Growing calves
            ELSE 1.0
        END AS production_multiplier

    FROM animals a
    LEFT JOIN (
        SELECT DISTINCT animal_id
        FROM milk_production
        WHERE milking_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
    ) mp ON a.animal_id = mp.animal_id
    WHERE a.health_status != 'deceased'
),
feed_summary AS (
    SELECT
        f.farm_name,
        fr.animal_type,
        COUNT(fr.animal_id) AS animal_count,
        AVG(fr.weight_kg) AS avg_weight_kg,
        SUM(fr.daily_feed_kg * fr.production_multiplier) AS total_daily_feed_kg,
        AVG(fr.protein_requirement_pct) AS avg_protein_requirement,

        -- Monthly projections
        SUM(fr.daily_feed_kg * fr.production_multiplier * 30) AS monthly_feed_needed_kg,
        SUM(fr.daily_feed_kg * fr.production_multiplier * 30 * 0.5) AS monthly_feed_cost_usd  -- $0.50/kg

    FROM feed_requirements fr
    INNER JOIN farms f ON fr.farm_id = f.farm_id
    GROUP BY f.farm_id, fr.animal_type
)
SELECT
    farm_name,
    animal_type,
    animal_count,
    ROUND(avg_weight_kg, 1) AS avg_weight_kg,
    ROUND(total_daily_feed_kg, 1) AS daily_feed_kg,
    ROUND(avg_protein_requirement, 1) AS protein_pct_needed,
    ROUND(monthly_feed_needed_kg, 0) AS monthly_feed_kg,
    ROUND(monthly_feed_cost_usd, 2) AS monthly_feed_cost_usd,
    ROUND(monthly_feed_cost_usd / animal_count, 2) AS cost_per_animal_per_month
FROM feed_summary
ORDER BY farm_name, monthly_feed_cost_usd DESC;