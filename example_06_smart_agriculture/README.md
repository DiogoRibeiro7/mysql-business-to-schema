# Smart Agriculture IoT System

## Overview

This example demonstrates a precision agriculture IoT platform for modern farming, featuring soil monitoring, weather tracking, irrigation automation, crop health assessment, and yield optimization.

## Business Context

Modern agriculture faces critical challenges:

- **Water Scarcity**: Inefficient irrigation wastes precious resources
- **Climate Change**: Unpredictable weather patterns affect yields
- **Food Security**: Need to increase production sustainably
- **Input Costs**: Fertilizer and pesticide overuse
- **Labor Shortage**: Need for automation in farming
- **Crop Diseases**: Late detection causes massive losses

This Smart Agriculture solution provides:

- Precision irrigation based on soil moisture and weather
- Crop health monitoring using NDVI sensors
- Pest and disease early warning systems
- Fertilizer optimization using soil nutrient data
- Yield prediction and harvest planning
- Livestock tracking and health monitoring

## Unique Agricultural IoT Patterns

### Environmental Sensing

- **Soil Sensors**: Moisture, pH, NPK, temperature, EC
- **Weather Stations**: Temperature, humidity, rainfall, wind
- **Crop Sensors**: NDVI, leaf wetness, canopy temperature
- **Water Quality**: pH, dissolved oxygen, turbidity

### Precision Agriculture

- **Variable Rate Application**: GPS-guided fertilizer/pesticide
- **Irrigation Zones**: Micro-climate based watering
- **Crop Scouting**: Drone imagery analysis
- **Yield Mapping**: Harvest data by GPS location

### Livestock Management

- **Animal Tracking**: GPS collars, RFID tags
- **Health Monitoring**: Temperature, activity, rumination
- **Feed Optimization**: Automated feeding systems
- **Milk Production**: Automated milking parlors

## Database Schema Highlights

### Core Entities

1. **Farm Hierarchy**

  ```
  Farms → Fields → Zones → Sensor Nodes
     → Livestock → Herds
     → Equipment → Implements
  ```

2. **Crop Lifecycle**

  ```
  Planting → Growing → Monitoring → Harvesting → Storage
  ```

3. **Data Types**

4. Time series sensor data (moisture, temperature)
5. Spatial data (field boundaries, GPS tracks)
6. Image data (drone/satellite imagery)
7. Predictive models (yield, disease probability)

## Key Tables

### Farm Management

- `farms` - Farm properties and metadata
- `fields` - Individual field boundaries (GIS)
- `zones` - Management zones within fields
- `crops` - Crop types and varieties
- `plantings` - Planting records and schedules

### Sensor Infrastructure

- `sensor_nodes` - IoT devices in fields
- `soil_sensors` - Soil monitoring points
- `weather_stations` - On-farm weather data
- `sensor_readings` - Time series data

### Irrigation System

- `irrigation_zones` - Sprinkler/drip zones
- `irrigation_schedules` - Watering plans
- `water_usage` - Consumption tracking
- `soil_moisture_thresholds` - Trigger levels

### Crop Health

- `ndvi_readings` - Vegetation indices
- `pest_detections` - Pest/disease alerts
- `scouting_reports` - Field observations
- `treatment_applications` - Pesticide records

### Livestock

- `animals` - Individual animal records
- `health_readings` - Vitals and behavior
- `feeding_records` - Feed consumption
- `milk_production` - Dairy metrics

### Harvest & Yield

- `harvest_data` - Yield by location
- `storage_facilities` - Grain bins, silos
- `quality_tests` - Grain quality metrics

## Sample Queries

### 1\. Irrigation Optimization

```sql
-- Determine which zones need irrigation based on soil moisture and forecast
WITH moisture_status AS (
    SELECT
        z.zone_id,
        z.zone_name,
        f.field_name,
        AVG(sr.moisture_percentage) as current_moisture,
        z.target_moisture_min,
        z.target_moisture_max,
        c.water_requirement_mm_per_day
    FROM zones z
    JOIN fields f ON z.field_id = f.field_id
    JOIN crops c ON f.current_crop_id = c.crop_id
    JOIN soil_sensors ss ON z.zone_id = ss.zone_id
    JOIN sensor_readings sr ON ss.sensor_id = sr.sensor_id
    WHERE sr.reading_type = 'soil_moisture'
        AND sr.timestamp >= NOW() - INTERVAL 2 HOUR
    GROUP BY z.zone_id
),
weather_forecast AS (
    SELECT
        f.field_id,
        SUM(CASE WHEN wf.forecast_date = CURDATE() THEN wf.precipitation_mm ELSE 0 END) as today_rain,
        SUM(CASE WHEN wf.forecast_date = DATE_ADD(CURDATE(), INTERVAL 1 DAY) THEN wf.precipitation_mm ELSE 0 END) as tomorrow_rain
    FROM fields f
    JOIN weather_forecasts wf ON f.location_id = wf.location_id
    WHERE wf.forecast_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 1 DAY)
    GROUP BY f.field_id
)
SELECT
    ms.zone_name,
    ms.field_name,
    ROUND(ms.current_moisture, 1) as current_moisture_pct,
    ms.target_moisture_min,
    CASE
        WHEN ms.current_moisture < ms.target_moisture_min * 0.8 THEN 'CRITICAL'
        WHEN ms.current_moisture < ms.target_moisture_min THEN 'LOW'
        WHEN ms.current_moisture > ms.target_moisture_max THEN 'EXCESS'
        ELSE 'OPTIMAL'
    END as moisture_status,
    ROUND(wf.today_rain, 1) as rain_today_mm,
    ROUND(wf.tomorrow_rain, 1) as rain_tomorrow_mm,
    CASE
        WHEN ms.current_moisture < ms.target_moisture_min AND wf.today_rain < 5 THEN
            ROUND((ms.target_moisture_min - ms.current_moisture) * 10, 1) -- mm of irrigation needed
        ELSE 0
    END as irrigation_needed_mm
FROM moisture_status ms
JOIN fields f ON ms.zone_id IN (SELECT zone_id FROM zones WHERE field_id = f.field_id)
LEFT JOIN weather_forecast wf ON f.field_id = wf.field_id
WHERE ms.current_moisture < ms.target_moisture_min * 1.2
ORDER BY moisture_status, ms.current_moisture;
```

### 2\. Crop Health Assessment

```sql
-- NDVI analysis for crop stress detection
SELECT
    f.field_name,
    p.planting_date,
    DATEDIFF(CURDATE(), p.planting_date) as days_since_planting,
    c.crop_name,
    c.variety,
    AVG(n.ndvi_value) as avg_ndvi,
    MIN(n.ndvi_value) as min_ndvi,
    MAX(n.ndvi_value) as max_ndvi,
    STDDEV(n.ndvi_value) as ndvi_variation,
    CASE
        WHEN AVG(n.ndvi_value) < 0.3 THEN 'POOR - Severe stress'
        WHEN AVG(n.ndvi_value) < 0.5 THEN 'FAIR - Moderate stress'
        WHEN AVG(n.ndvi_value) < 0.7 THEN 'GOOD - Healthy'
        ELSE 'EXCELLENT - Very healthy'
    END as crop_health,
    -- Compare to historical average for this growth stage
    (
        SELECT AVG(ndvi_value)
        FROM ndvi_readings hist
        WHERE hist.field_id = f.field_id
            AND hist.days_after_planting BETWEEN DATEDIFF(CURDATE(), p.planting_date) - 7
            AND DATEDIFF(CURDATE(), p.planting_date) + 7
            AND YEAR(hist.reading_date) = YEAR(CURDATE()) - 1
    ) as historical_ndvi
FROM fields f
JOIN plantings p ON f.field_id = p.field_id
JOIN crops c ON p.crop_id = c.crop_id
JOIN ndvi_readings n ON f.field_id = n.field_id
WHERE n.reading_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
    AND p.harvest_date IS NULL
GROUP BY f.field_id
ORDER BY crop_health, avg_ndvi;
```

### 3\. Yield Prediction

```sql
-- Predict yield based on current conditions
WITH growth_metrics AS (
    SELECT
        p.planting_id,
        f.field_name,
        c.crop_name,
        f.area_hectares,
        DATEDIFF(c.typical_harvest_days, DATEDIFF(CURDATE(), p.planting_date)) as days_to_harvest,
        AVG(sr.value) as avg_soil_moisture,
        AVG(n.ndvi_value) as avg_ndvi,
        SUM(w.precipitation_mm) as total_rainfall,
        AVG(w.temperature_avg) as avg_temperature
    FROM plantings p
    JOIN fields f ON p.field_id = f.field_id
    JOIN crops c ON p.crop_id = c.crop_id
    LEFT JOIN sensor_readings sr ON f.field_id = sr.field_id
        AND sr.reading_type = 'soil_moisture'
        AND sr.timestamp >= DATE_SUB(NOW(), INTERVAL 30 DAY)
    LEFT JOIN ndvi_readings n ON f.field_id = n.field_id
        AND n.reading_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    LEFT JOIN weather_data w ON f.location_id = w.location_id
        AND w.date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    WHERE p.harvest_date IS NULL
    GROUP BY p.planting_id
)
SELECT
    field_name,
    crop_name,
    area_hectares,
    days_to_harvest,
    ROUND(avg_soil_moisture, 1) as soil_moisture_pct,
    ROUND(avg_ndvi, 2) as vegetation_index,
    ROUND(total_rainfall, 1) as rainfall_30d_mm,
    ROUND(avg_temperature, 1) as avg_temp_c,
    -- Simplified yield prediction formula
    ROUND(
        area_hectares *
        (SELECT avg_yield_tons_per_hectare FROM crops WHERE crop_name = gm.crop_name) *
        (0.7 + (avg_ndvi * 0.3)) * -- NDVI factor
        (CASE
            WHEN avg_soil_moisture BETWEEN 40 AND 60 THEN 1.0
            WHEN avg_soil_moisture BETWEEN 30 AND 70 THEN 0.9
            ELSE 0.8
        END) * -- Moisture factor
        (CASE
            WHEN total_rainfall BETWEEN 100 AND 200 THEN 1.0
            WHEN total_rainfall BETWEEN 50 AND 250 THEN 0.9
            ELSE 0.8
        END), -- Rainfall factor
    2) as predicted_yield_tons
FROM growth_metrics gm
ORDER BY days_to_harvest;
```

### 4\. Livestock Health Monitoring

```sql
-- Detect anomalies in cattle health metrics
WITH health_baseline AS (
    SELECT
        a.animal_id,
        a.tag_number,
        a.breed,
        AVG(h.body_temperature) as avg_temp,
        STDDEV(h.body_temperature) as std_temp,
        AVG(h.activity_level) as avg_activity,
        AVG(h.rumination_minutes) as avg_rumination
    FROM animals a
    JOIN health_readings h ON a.animal_id = h.animal_id
    WHERE h.timestamp >= DATE_SUB(NOW(), INTERVAL 7 DAY)
        AND h.timestamp < DATE_SUB(NOW(), INTERVAL 1 DAY)
    GROUP BY a.animal_id
),
current_health AS (
    SELECT
        a.animal_id,
        AVG(h.body_temperature) as current_temp,
        AVG(h.activity_level) as current_activity,
        AVG(h.rumination_minutes) as current_rumination,
        MAX(h.timestamp) as last_reading
    FROM animals a
    JOIN health_readings h ON a.animal_id = h.animal_id
    WHERE h.timestamp >= DATE_SUB(NOW(), INTERVAL 4 HOUR)
    GROUP BY a.animal_id
)
SELECT
    hb.tag_number,
    hb.breed,
    ROUND(ch.current_temp, 1) as temperature_c,
    ROUND(ch.current_activity, 0) as activity_steps,
    ROUND(ch.current_rumination, 0) as rumination_min,
    CASE
        WHEN ch.current_temp > hb.avg_temp + (2 * hb.std_temp) THEN 'FEVER'
        WHEN ch.current_temp < hb.avg_temp - (2 * hb.std_temp) THEN 'HYPOTHERMIA'
        WHEN ch.current_activity < hb.avg_activity * 0.5 THEN 'LETHARGY'
        WHEN ch.current_rumination < hb.avg_rumination * 0.6 THEN 'LOW_RUMINATION'
        ELSE 'HEALTHY'
    END as health_status,
    TIMESTAMPDIFF(MINUTE, ch.last_reading, NOW()) as minutes_since_reading
FROM health_baseline hb
JOIN current_health ch ON hb.animal_id = ch.animal_id
WHERE ch.current_temp > hb.avg_temp + (2 * hb.std_temp)
   OR ch.current_temp < hb.avg_temp - (2 * hb.std_temp)
   OR ch.current_activity < hb.avg_activity * 0.5
   OR ch.current_rumination < hb.avg_rumination * 0.6
ORDER BY health_status, hb.tag_number;
```

## Advanced Features

### 1\. Precision Application

- Variable rate fertilizer maps
- GPS-guided spraying
- Section control for overlaps
- As-applied documentation

### 2\. Remote Sensing

- Satellite imagery analysis (Sentinel, Landsat)
- Drone flight planning
- Multispectral imaging
- 3D crop modeling

### 3\. AI/ML Applications

- Yield prediction models
- Disease identification (computer vision)
- Pest population forecasting
- Optimal planting date selection

### 4\. Farm Management

- Cost tracking per field/crop
- ROI analysis by zone
- Labor management
- Equipment maintenance scheduling

## Integration Points

### Farm Management Software

- John Deere Operations Center
- Climate FieldView
- FarmLogs
- Ag Leader

### IoT Platforms

- AWS IoT for Agriculture
- Azure FarmBeats
- IBM Watson for Agriculture

### External Data Sources

- NOAA weather data
- USDA crop reports
- Commodity prices
- Soil survey databases

## Benefits & ROI

### Typical Improvements

- **Water Usage**: -30%
- **Fertilizer Costs**: -20%
- **Yield Increase**: +15%
- **Labor Efficiency**: +25%
- **Crop Loss**: -40%

### Sustainability Impact

- Reduced chemical runoff
- Lower carbon footprint
- Improved soil health
- Water conservation

This Smart Agriculture system enables data-driven farming decisions for improved yields and sustainability.
