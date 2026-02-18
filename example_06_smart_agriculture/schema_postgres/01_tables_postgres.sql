-- PostgreSQL Schema
-- Converted from MySQL on 2026-02-17T23:11:17.348315
-- Generator: MySQL to PostgreSQL Converter

-- Enum Types
CREATE TYPE farms_status AS ENUM ('crop', 'dairy', 'mixed', 'orchard', 'greenhouse', 'aquaculture');
CREATE TYPE fields_status AS ENUM ('drip', 'sprinkler', 'flood', 'pivot', 'none');
CREATE TYPE zones_status AS ENUM ('productivity', 'soil_type', 'topography', 'custom');
CREATE TYPE crops_status AS ENUM ('cereal', 'legume', 'vegetable', 'fruit', 'forage', 'cash_crop');
CREATE TYPE planting_records_status AS ENUM ('planned', 'planted', 'growing', 'harvested', 'failed');
CREATE TYPE sensors_status AS ENUM ('soil_moisture', 'soil_temperature', 'soil_ph', 'soil_ec', 'air_temperature', 'humidity', 'light', 'rainfall', 'wind_speed', 'wind_direction', 'leaf_wetness', 'soil_npk');
CREATE TYPE sensor_readings_status AS ENUM ('good', 'suspect', 'bad');
CREATE TYPE irrigation_systems_status AS ENUM ('drip', 'sprinkler', 'pivot', 'flood', 'micro_sprinkler');
CREATE TYPE irrigation_events_status AS ENUM ('manual', 'scheduled', 'sensor', 'weather');
CREATE TYPE fertilizer_applications_status AS ENUM ('broadcast', 'banding', 'foliar', 'fertigation', 'injection');
CREATE TYPE pesticide_applications_status AS ENUM ('spray', 'granular', 'seed_treatment', 'soil_injection');
CREATE TYPE animals_status AS ENUM ('healthy', 'sick', 'quarantine', 'deceased');
CREATE TYPE milk_production_status AS ENUM ('A', 'B', 'C', 'rejected');
CREATE TYPE harvest_records_status AS ENUM ('manual', 'mechanical', 'combined');
CREATE TYPE operators_status AS ENUM ('owner', 'manager', 'supervisor', 'operator', 'seasonal');

DROP DATABASE IF EXISTS smart_agriculture;
-- Create database (run as superuser)
-- CREATE DATABASE smart_agriculture;
-- \c smart_agriculture

DELIMITER $$
CREATE PROCEDURE create_daily_partitions(
IN table_name VARCHAR(64),
IN days_ahead INT
)
BEGIN
DECLARE i INT DEFAULT 0;
DECLARE partition_date DATE;
DECLARE partition_name VARCHAR(64);
DECLARE sql_text TEXT;
WHILE i < days_ahead DO
SET partition_date = DATE_ADD(CURDATE(), INTERVAL i DAY);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
END WHILE;
END$$
CREATE FUNCTION calculate_gdd(
min_temp DECIMAL(5,2),
max_temp DECIMAL(5,2),
base_temp DECIMAL(5,2)
)
RETURNS DECIMAL(8,2)
DETERMINISTIC
BEGIN
DECLARE avg_temp DECIMAL(5,2);
IF avg_temp <= base_temp THEN
RETURN 0;
ELSE
RETURN avg_temp - base_temp;
END IF;
END$$
DELIMITER ;
CREATE USER IF NOT EXISTS 'farm_operator'@'%' IDENTIFIED BY 'operator_pass_2024';
GRANT SELECT, INSERT, UPDATE ON smart_agriculture.* TO 'farm_operator'@'%';
CREATE USER IF NOT EXISTS 'agronomist'@'%' IDENTIFIED BY 'agro_pass_2024';
GRANT ALL PRIVILEGES ON smart_agriculture.* TO 'agronomist'@'%';
CREATE USER IF NOT EXISTS 'veterinarian'@'%' IDENTIFIED BY 'vet_pass_2024';
GRANT SELECT, INSERT, UPDATE ON smart_agriculture.animals TO 'veterinarian'@'%';
GRANT SELECT, INSERT, UPDATE ON smart_agriculture.health_records TO 'veterinarian'@'%';
CREATE USER IF NOT EXISTS 'farm_analyst'@'%' IDENTIFIED BY 'analyst_pass_2024';
GRANT SELECT ON smart_agriculture.* TO 'farm_analyst'@'%';
FLUSH PRIVILEGES;
CREATE TABLE IF NOT EXISTS farms (
    farm_name VARCHAR(100) NOT NULL,
    farm_type farms_status NOT NULL,
    owner_name VARCHAR(100),
    location VARCHAR(200),
    total_area_hectares DECIMAL(10,2),
    latitude DECIMAL(10,6),
    longitude DECIMAL(10,6),
    elevation_meters INTEGER,
    climate_zone VARCHAR(50),
    soil_type VARCHAR(50),
    established_date DATE,
    organic_certified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS fields (
    farm_id INTEGER NOT NULL,
    field_name VARCHAR(100) NOT NULL,
    area_hectares DECIMAL(10,2) NOT NULL,
    soil_type VARCHAR(50),
    slope_percentage DECIMAL(5,2),
    drainage_class fields_status DEFAULT 'moderate',
    irrigation_type fields_status DEFAULT 'none',
    gps_boundaries JSONB,
    last_soil_test DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS zones (
    field_id INTEGER NOT NULL,
    zone_name VARCHAR(50),
    area_hectares DECIMAL(8,2),
    management_zone_type zones_status DEFAULT 'productivity',
    characteristics JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS crops (
    crop_name VARCHAR(100) NOT NULL,
    scientific_name VARCHAR(200),
    crop_family VARCHAR(100),
    crop_type crops_status NOT NULL,
    growth_days INTEGER,
    base_temperature_c DECIMAL(4,1),
    optimal_temp_min DECIMAL(4,1),
    optimal_temp_max DECIMAL(4,1),
    water_needs_mm_per_day DECIMAL(5,2),
    nitrogen_kg_per_hectare DECIMAL(6,2),
    phosphorus_kg_per_hectare DECIMAL(6,2),
    potassium_kg_per_hectare DECIMAL(6,2),
    optimal_ph_min DECIMAL(3,1),
    optimal_ph_max DECIMAL(3,1),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS planting_records (
    field_id INTEGER NOT NULL,
    zone_id INTEGER,
    crop_id INTEGER NOT NULL,
    variety VARCHAR(100),
    planting_date DATE NOT NULL,
    expected_harvest_date DATE,
    actual_harvest_date DATE,
    area_planted_hectares DECIMAL(10,2) NOT NULL,
    seed_rate_kg_per_hectare DECIMAL(8,2),
    row_spacing_cm DECIMAL(5,1),
    plant_spacing_cm DECIMAL(5,1),
    planting_depth_cm DECIMAL(4,1),
    expected_yield_kg_per_hectare DECIMAL(10,2),
    actual_yield_kg_per_hectare DECIMAL(10,2),
    status planting_records_status DEFAULT 'planned',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS growth_stages (
    planting_id INTEGER NOT NULL,
    stage_name VARCHAR(50) NOT NULL,
    stage_code VARCHAR(20),
    observation_date DATE NOT NULL,
    gdd_accumulated DECIMAL(8,2),
    plant_height_cm DECIMAL(6,1),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sensors (
    zone_id INTEGER NOT NULL,
    sensor_type sensors_status NOT NULL,
    manufacturer VARCHAR(100),
    model VARCHAR(100),
    installation_date DATE,
    depth_cm INTEGER,
    height_m DECIMAL(4,2),
    calibration_date DATE,
    battery_type VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sensor_readings (
    reading_id BIGSERIAL,
    sensor_id INTEGER NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    value DECIMAL(12,4) NOT NULL,
    unit VARCHAR(20),
    quality_flag sensor_readings_status DEFAULT 'good',
    battery_voltage DECIMAL(4,2),
    PRIMARY KEY (reading_id, timestamp),
    PARTITION TEXT VALUES LESS THAN (TO_DAYS('2025-03-01')),
    PARTITION TEXT VALUES LESS THAN MAXVALUE
);

CREATE TABLE IF NOT EXISTS weather_stations (
    farm_id INTEGER NOT NULL,
    station_name VARCHAR(100),
    latitude DECIMAL(10,6),
    longitude DECIMAL(10,6),
    elevation_m INTEGER,
    installation_date DATE,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS weather_data (
    station_id INTEGER NOT NULL,
    observation_time TIMESTAMP NOT NULL,
    temperature_c DECIMAL(5,2),
    humidity_percent DECIMAL(5,2),
    pressure_hpa DECIMAL(7,2),
    rainfall_mm DECIMAL(6,2),
    wind_speed_kmh DECIMAL(5,2),
    wind_direction_degrees INTEGER,
    solar_radiation_wm2 DECIMAL(6,2),
    evapotranspiration_mm DECIMAL(5,2),
    dew_point_c DECIMAL(5,2)
);

CREATE TABLE IF NOT EXISTS irrigation_systems (
    field_id INTEGER NOT NULL,
    system_type irrigation_systems_status NOT NULL,
    flow_rate_lpm DECIMAL(10,2),
    coverage_area_hectares DECIMAL(10,2),
    efficiency_percentage DECIMAL(5,2) DEFAULT 85,
    installation_date DATE,
    last_maintenance_date DATE,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS irrigation_events (
    system_id INTEGER NOT NULL,
    zone_id INTEGER,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    water_amount_liters DECIMAL(12,2),
    trigger_type irrigation_events_status NOT NULL,
    trigger_reason VARCHAR(200),
    soil_moisture_before DECIMAL(5,2),
    soil_moisture_after DECIMAL(5,2),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS irrigation_schedules (
    system_id INTEGER NOT NULL,
    schedule_name VARCHAR(100),
    days_of_week TEXT[],
    start_time TIME,
    duration_minutes INTEGER,
    water_amount_mm DECIMAL(6,2),
    moisture_threshold_min DECIMAL(5,2),
    moisture_threshold_max DECIMAL(5,2),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS fertilizer_applications (
    field_id INTEGER NOT NULL,
    zone_id INTEGER,
    application_date DATE NOT NULL,
    fertilizer_type VARCHAR(100),
    n_kg_per_hectare DECIMAL(8,2),
    p_kg_per_hectare DECIMAL(8,2),
    k_kg_per_hectare DECIMAL(8,2),
    application_method fertilizer_applications_status NOT NULL,
    cost_per_hectare DECIMAL(10,2),
    weather_conditions VARCHAR(200),
    operator_id INTEGER,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS pesticide_applications (
    field_id INTEGER NOT NULL,
    zone_id INTEGER,
    application_date DATE NOT NULL,
    product_name VARCHAR(100) NOT NULL,
    active_ingredient VARCHAR(100),
    target_pest VARCHAR(100),
    application_rate_per_hectare VARCHAR(50),
    rei_hours INTEGER,
    phi_days INTEGER,
    application_method pesticide_applications_status NOT NULL,
    weather_conditions VARCHAR(200),
    wind_speed_kmh DECIMAL(5,2),
    temperature_c DECIMAL(5,2),
    operator_id INTEGER,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS animals (
    farm_id INTEGER NOT NULL,
    animal_type animals_status NOT NULL,
    breed VARCHAR(100),
    gender animals_status NOT NULL,
    birth_date DATE,
    weight_kg DECIMAL(8,2),
    mother_id INTEGER,
    father_id INTEGER,
    purchase_date DATE,
    purchase_price DECIMAL(10,2),
    current_location VARCHAR(100),
    health_status animals_status DEFAULT 'healthy',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS health_records (
    animal_id INTEGER NOT NULL,
    record_date DATE NOT NULL,
    description TEXT,
    medication VARCHAR(200),
    dosage VARCHAR(100),
    veterinarian_name VARCHAR(100),
    cost DECIMAL(10,2),
    next_followup_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS milk_production (
    animal_id INTEGER NOT NULL,
    milking_date DATE NOT NULL,
    milking_time milk_production_status NOT NULL,
    quantity_liters DECIMAL(6,2) NOT NULL,
    fat_percentage DECIMAL(4,2),
    protein_percentage DECIMAL(4,2),
    somatic_cell_count INTEGER,
    temperature_c DECIMAL(4,1),
    quality_grade milk_production_status,
    UNIQUE (animal_id, milking_date, milking_time)
);

CREATE TABLE IF NOT EXISTS harvest_records (
    planting_id INTEGER NOT NULL,
    harvest_date DATE NOT NULL,
    area_harvested_hectares DECIMAL(10,2) NOT NULL,
    total_yield_kg DECIMAL(12,2) NOT NULL,
    marketable_yield_kg DECIMAL(12,2),
    moisture_percentage DECIMAL(5,2),
    quality_grade harvest_records_status,
    storage_location VARCHAR(100),
    harvest_method harvest_records_status DEFAULT 'mechanical',
    weather_conditions VARCHAR(200),
    labor_hours DECIMAL(8,2),
    harvest_cost DECIMAL(10,2),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS yield_predictions (
    planting_id INTEGER NOT NULL,
    prediction_date DATE NOT NULL,
    predicted_yield_kg_per_hectare DECIMAL(10,2),
    confidence_level DECIMAL(5,2),
    model_version VARCHAR(20),
    factors JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS operators (
    farm_id INTEGER NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    role operators_status NOT NULL,
    specialization VARCHAR(100),
    phone VARCHAR(20),
    email VARCHAR(200),
    hire_date DATE,
    certifications JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
