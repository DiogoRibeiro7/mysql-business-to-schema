-- ============================================================================
-- Smart Agriculture Indexes
-- ============================================================================

USE smart_agriculture;

-- ============================================================================
-- Sensor Data Indexes (High-frequency queries)
-- ============================================================================

-- Composite index for time-series queries
CREATE INDEX idx_sensor_readings_composite
    ON sensor_readings(sensor_id, timestamp DESC, value);

-- Index for latest readings per sensor
CREATE INDEX idx_sensor_latest
    ON sensor_readings(sensor_id, timestamp DESC);

-- Index for quality filtering
CREATE INDEX idx_sensor_quality
    ON sensor_readings(quality_flag, timestamp DESC);

-- ============================================================================
-- Weather Data Indexes
-- ============================================================================

-- Weather lookups by station and time
CREATE INDEX idx_weather_lookup
    ON weather_data(station_id, observation_time DESC);

-- Weather extremes for alerts
CREATE INDEX idx_weather_extremes
    ON weather_data(observation_time DESC, temperature_c, rainfall_mm);

-- ============================================================================
-- Crop Management Indexes
-- ============================================================================

-- Active plantings by field
CREATE INDEX idx_active_plantings
    ON planting_records(field_id, status, planting_date);

-- Harvest planning
CREATE INDEX idx_harvest_planning
    ON planting_records(expected_harvest_date, status);

-- Growth stage tracking
CREATE INDEX idx_growth_tracking
    ON growth_stages(planting_id, observation_date DESC);

-- Crop rotation analysis
CREATE INDEX idx_crop_rotation
    ON planting_records(field_id, planting_date DESC, crop_id);

-- ============================================================================
-- Irrigation Management Indexes
-- ============================================================================

-- Active irrigation events
CREATE INDEX idx_active_irrigation
    ON irrigation_events(end_time, system_id);

-- Irrigation history by zone
CREATE INDEX idx_irrigation_history
    ON irrigation_events(zone_id, start_time DESC);

-- Water usage analysis
CREATE INDEX idx_water_usage
    ON irrigation_events(start_time DESC, water_amount_liters);

-- Scheduled irrigation lookup
CREATE INDEX idx_scheduled_irrigation
    ON irrigation_schedules(is_active, system_id);

-- ============================================================================
-- Treatment Application Indexes
-- ============================================================================

-- Fertilizer application history
CREATE INDEX idx_fertilizer_history
    ON fertilizer_applications(field_id, application_date DESC);

-- Pesticide compliance tracking
CREATE INDEX idx_pesticide_phi
    ON pesticide_applications(application_date, phi_days);

-- Treatment by zone
CREATE INDEX idx_zone_treatments_fert
    ON fertilizer_applications(zone_id, application_date DESC);

CREATE INDEX idx_zone_treatments_pest
    ON pesticide_applications(zone_id, application_date DESC);

-- ============================================================================
-- Livestock Management Indexes
-- ============================================================================

-- Active animals by type
CREATE INDEX idx_active_animals
    ON animals(farm_id, animal_type, health_status);

-- Health monitoring
CREATE INDEX idx_health_monitoring
    ON health_records(animal_id, record_date DESC);

-- Vaccination tracking
CREATE INDEX idx_vaccination_due
    ON health_records(next_followup_date, record_type);

-- Milk production analysis
CREATE INDEX idx_milk_production
    ON milk_production(milking_date DESC, animal_id);

-- Quality tracking
CREATE INDEX idx_milk_quality
    ON milk_production(quality_grade, milking_date DESC);

-- ============================================================================
-- Harvest and Yield Indexes
-- ============================================================================

-- Harvest tracking
CREATE INDEX idx_harvest_tracking
    ON harvest_records(harvest_date DESC, quality_grade);

-- Yield analysis by crop
CREATE INDEX idx_yield_analysis
    ON harvest_records(planting_id, harvest_date);

-- Storage location lookup
CREATE INDEX idx_storage_lookup
    ON harvest_records(storage_location, harvest_date DESC);

-- Yield predictions
CREATE INDEX idx_yield_predictions
    ON yield_predictions(planting_id, prediction_date DESC);

-- ============================================================================
-- Full-Text Search Indexes
-- ============================================================================

-- Crop variety search
CREATE FULLTEXT INDEX ft_crop_search
    ON crops(crop_name, scientific_name, crop_family);

-- Notes and observations search
CREATE FULLTEXT INDEX ft_planting_notes
    ON planting_records(variety, notes);

CREATE FULLTEXT INDEX ft_growth_notes
    ON growth_stages(notes);

-- Treatment search
CREATE FULLTEXT INDEX ft_pesticide_search
    ON pesticide_applications(product_name, active_ingredient, target_pest);

-- ============================================================================
-- JSON Field Indexes (MySQL 5.7+)
-- ============================================================================

-- Zone characteristics
ALTER TABLE zones ADD INDEX idx_zone_chars
    ((CAST(characteristics->'$.soil_quality' AS CHAR(20))));

-- Operator certifications
ALTER TABLE operators ADD INDEX idx_operator_certs
    ((CAST(certifications->'$[*].type' AS CHAR(50) ARRAY)));

-- GPS boundaries for spatial queries
ALTER TABLE fields ADD INDEX idx_field_bounds
    ((CAST(gps_boundaries->'$[0].lat' AS DECIMAL(10,6))),
     (CAST(gps_boundaries->'$[0].lng' AS DECIMAL(10,6))));

-- ============================================================================
-- Covering Indexes for Common Queries
-- ============================================================================

-- Dashboard - current field status
CREATE INDEX idx_dashboard_fields
    ON planting_records(field_id, status, crop_id, planting_date, expected_harvest_date);

-- Irrigation decision support
CREATE INDEX idx_irrigation_decision
    ON sensor_readings(sensor_id, timestamp DESC, value);

-- Livestock dashboard
CREATE INDEX idx_livestock_dashboard
    ON animals(farm_id, animal_type, health_status, weight_kg);

-- Cost analysis
CREATE INDEX idx_cost_analysis_fert
    ON fertilizer_applications(field_id, application_date, cost_per_hectare);

CREATE INDEX idx_cost_analysis_harvest
    ON harvest_records(planting_id, harvest_date, harvest_cost);

-- ============================================================================
-- Partitioned Table Optimization
-- ============================================================================

-- Create hourly summary for sensor data
CREATE TABLE sensor_readings_hourly (
    sensor_id INT NOT NULL,
    hour_timestamp DATETIME NOT NULL,
    min_value DECIMAL(12,4),
    max_value DECIMAL(12,4),
    avg_value DECIMAL(12,4),
    reading_count INT,
    PRIMARY KEY (sensor_id, hour_timestamp),
    INDEX idx_hourly_lookup (hour_timestamp, sensor_id)
) ENGINE=InnoDB;

-- Create daily weather summary
CREATE TABLE weather_daily_summary (
    station_id INT NOT NULL,
    summary_date DATE NOT NULL,
    temp_min DECIMAL(5,2),
    temp_max DECIMAL(5,2),
    temp_avg DECIMAL(5,2),
    humidity_avg DECIMAL(5,2),
    rainfall_total DECIMAL(6,2),
    wind_speed_max DECIMAL(5,2),
    solar_radiation_total DECIMAL(8,2),
    gdd_accumulated DECIMAL(8,2),
    PRIMARY KEY (station_id, summary_date),
    INDEX idx_date_lookup (summary_date, station_id)
) ENGINE=InnoDB;

-- ============================================================================
-- Spatial Indexes (if using spatial extensions)
-- ============================================================================

-- Farm locations
-- ALTER TABLE farms ADD SPATIAL INDEX idx_farm_location (POINT(latitude, longitude));

-- Field boundaries (would require converting JSON to geometry)
-- ALTER TABLE fields ADD COLUMN boundary GEOMETRY;
-- ALTER TABLE fields ADD SPATIAL INDEX idx_field_boundary (boundary);

-- ============================================================================
-- Statistics Update
-- ============================================================================

-- Update table statistics for optimal query planning
ANALYZE TABLE farms;
ANALYZE TABLE fields;
ANALYZE TABLE zones;
ANALYZE TABLE planting_records;
ANALYZE TABLE sensors;
ANALYZE TABLE sensor_readings;
ANALYZE TABLE weather_data;
ANALYZE TABLE irrigation_events;
ANALYZE TABLE fertilizer_applications;
ANALYZE TABLE pesticide_applications;
ANALYZE TABLE animals;
ANALYZE TABLE health_records;
ANALYZE TABLE harvest_records;
