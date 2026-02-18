-- PostgreSQL Schema
-- Converted from MySQL on 2026-02-17T23:11:17.349484
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

ALTER TABLE fields
ADD CONSTRAINT fk_field_farm
FOREIGN KEY (farm_id) REFERENCES farms(farm_id)
ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE zones
ADD CONSTRAINT fk_zone_field
FOREIGN KEY (field_id) REFERENCES fields(field_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE planting_records
ADD CONSTRAINT fk_planting_field
FOREIGN KEY (field_id) REFERENCES fields(field_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_planting_zone
FOREIGN KEY (zone_id) REFERENCES zones(zone_id)
ON DELETE SET NULL ON UPDATE CASCADE,
ADD CONSTRAINT fk_planting_crop
FOREIGN KEY (crop_id) REFERENCES crops(crop_id)
ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE growth_stages
ADD CONSTRAINT fk_stage_planting
FOREIGN KEY (planting_id) REFERENCES planting_records(planting_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE sensors
ADD CONSTRAINT fk_sensor_zone
FOREIGN KEY (zone_id) REFERENCES zones(zone_id)
ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE weather_stations
ADD CONSTRAINT fk_station_farm
FOREIGN KEY (farm_id) REFERENCES farms(farm_id)
ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE weather_data
ADD CONSTRAINT fk_weather_station
FOREIGN KEY (station_id) REFERENCES weather_stations(station_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE irrigation_systems
ADD CONSTRAINT fk_irrigation_field
FOREIGN KEY (field_id) REFERENCES fields(field_id)
ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE irrigation_events
ADD CONSTRAINT fk_event_system
FOREIGN KEY (system_id) REFERENCES irrigation_systems(system_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_event_zone
FOREIGN KEY (zone_id) REFERENCES zones(zone_id)
ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE irrigation_schedules
ADD CONSTRAINT fk_schedule_system
FOREIGN KEY (system_id) REFERENCES irrigation_systems(system_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE fertilizer_applications
ADD CONSTRAINT fk_fertilizer_field
FOREIGN KEY (field_id) REFERENCES fields(field_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_fertilizer_zone
FOREIGN KEY (zone_id) REFERENCES zones(zone_id)
ON DELETE SET NULL ON UPDATE CASCADE,
ADD CONSTRAINT fk_fertilizer_operator
FOREIGN KEY (operator_id) REFERENCES operators(operator_id)
ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE pesticide_applications
ADD CONSTRAINT fk_pesticide_field
FOREIGN KEY (field_id) REFERENCES fields(field_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_pesticide_zone
FOREIGN KEY (zone_id) REFERENCES zones(zone_id)
ON DELETE SET NULL ON UPDATE CASCADE,
ADD CONSTRAINT fk_pesticide_operator
FOREIGN KEY (operator_id) REFERENCES operators(operator_id)
ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE animals
ADD CONSTRAINT fk_animal_farm
FOREIGN KEY (farm_id) REFERENCES farms(farm_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_animal_mother
FOREIGN KEY (mother_id) REFERENCES animals(animal_id)
ON DELETE SET NULL ON UPDATE CASCADE,
ADD CONSTRAINT fk_animal_father
FOREIGN KEY (father_id) REFERENCES animals(animal_id)
ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE health_records
ADD CONSTRAINT fk_health_animal
FOREIGN KEY (animal_id) REFERENCES animals(animal_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE milk_production
ADD CONSTRAINT fk_milk_animal
FOREIGN KEY (animal_id) REFERENCES animals(animal_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE harvest_records
ADD CONSTRAINT fk_harvest_planting
FOREIGN KEY (planting_id) REFERENCES planting_records(planting_id)
ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE yield_predictions
ADD CONSTRAINT fk_prediction_planting
FOREIGN KEY (planting_id) REFERENCES planting_records(planting_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE operators
ADD CONSTRAINT fk_operator_farm
FOREIGN KEY (farm_id) REFERENCES farms(farm_id)
ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE farms
ADD CONSTRAINT chk_farm_area
CHECK (total_area_hectares > 0);
ALTER TABLE fields
ADD CONSTRAINT chk_field_area
CHECK (area_hectares > 0);
ALTER TABLE zones
ADD CONSTRAINT chk_zone_area
CHECK (area_hectares > 0);
ALTER TABLE farms
ADD CONSTRAINT chk_farm_coordinates
CHECK (latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180);
ALTER TABLE fields
ADD CONSTRAINT chk_field_slope
CHECK (slope_percentage BETWEEN 0 AND 100);
ALTER TABLE irrigation_systems
ADD CONSTRAINT chk_irrigation_efficiency
CHECK (efficiency_percentage BETWEEN 0 AND 100);
ALTER TABLE planting_records
ADD CONSTRAINT chk_planting_dates
CHECK (expected_harvest_date > planting_date AND
(actual_harvest_date IS NULL OR actual_harvest_date > planting_date));
ALTER TABLE sensors
ADD CONSTRAINT chk_sensor_depth
CHECK ((sensor_type LIKE 'soil_%' AND depth_cm > 0) OR
(sensor_type NOT LIKE 'soil_%'));
ALTER TABLE irrigation_events
ADD CONSTRAINT chk_irrigation_times
CHECK (end_time IS NULL OR end_time > start_time);
ALTER TABLE irrigation_events
ADD CONSTRAINT chk_moisture_values
CHECK ((soil_moisture_before BETWEEN 0 AND 100 OR soil_moisture_before IS NULL) AND
(soil_moisture_ 0 AND 100 OR soil_moisture_ NULL));
ALTER TABLE crops
ADD CONSTRAINT chk_crop_ph
CHECK (optimal_ph_min <= optimal_ph_max);
ALTER TABLE crops
ADD CONSTRAINT chk_crop_temp
CHECK (optimal_temp_min <= optimal_temp_max);
ALTER TABLE harvest_records
ADD CONSTRAINT chk_harvest_yield
CHECK (total_yield_kg >= 0 AND marketable_yield_kg >= 0 AND
marketable_yield_kg <= total_yield_kg);
ALTER TABLE milk_production
ADD CONSTRAINT chk_milk_percentages
CHECK (fat_percentage BETWEEN 0 AND 20 AND
protein_percentage BETWEEN 0 AND 10);
DELIMITER $$
CREATE TRIGGER trg_update_planting_status
BEFORE UPDATE ON planting_records
FOR EACH ROW
BEGIN
IF NEW.actual_harvest_date IS NOT NULL THEN
SET NEW.status = 'harvested';
ELSEIF NEW.planting_date <= CURDATE() AND OLD.status = 'planned' THEN
SET NEW.status = 'planted';
END IF;
END$$
CREATE TRIGGER trg_calculate_yield_per_hectare
BEFORE INSERT ON harvest_records
FOR EACH ROW
BEGIN
DECLARE v_area_planted DECIMAL(10,2);
SELECT area_planted_hectares INTO v_area_planted
FROM planting_records
WHERE planting_id = NEW.planting_id;
IF NEW.area_harvested_hectares > 0 THEN
UPDATE planting_records
SET actual_yield_kg_per_hectare = NEW.total_yield_kg / NEW.area_harvested_hectares,
status = 'harvested',
actual_harvest_date = NEW.harvest_date
WHERE planting_id = NEW.planting_id;
END IF;
END$$
CREATE TRIGGER trg_check_irrigation_need
AFTER INSERT ON sensor_readings
FOR EACH ROW
BEGIN
DECLARE v_sensor_type VARCHAR(50);
DECLARE v_zone_id INT;
DECLARE v_threshold_min DECIMAL(5,2);
SELECT sensor_type, zone_id INTO v_sensor_type, v_zone_id
FROM sensors
WHERE sensor_id = NEW.sensor_id;
IF v_sensor_type = 'soil_moisture' THEN
SELECT moisture_threshold_min INTO v_threshold_min
FROM irrigation_schedules isch
INNER JOIN irrigation_systems isys ON isch.system_id = isys.system_id
INNER JOIN fields f ON isys.field_id = f.field_id
INNER JOIN zones z ON f.field_id = z.field_id
WHERE z.zone_id = v_zone_id
AND isch.is_active = TRUE
LIMIT 1;
IF NEW.value < v_threshold_min THEN
INSERT INTO irrigation_events (system_id, zone_id, start_time, trigger_type, trigger_reason, soil_moisture_before)
SELECT isys.system_id, v_zone_id, NOW(), 'sensor',
CONCAT('Soil moisture ', NEW.value, '% below threshold ', v_threshold_min, '%'),
NEW.value
FROM irrigation_systems isys
INNER JOIN fields f ON isys.field_id = f.field_id
INNER JOIN zones z ON f.field_id = z.field_id
WHERE z.zone_id = v_zone_id
AND isys.is_active = TRUE
LIMIT 1;
END IF;
END IF;
END$$
CREATE TRIGGER trg_update_animal_health
AFTER INSERT ON health_records
FOR EACH ROW
BEGIN
IF NEW.record_type IN ('treatment', 'injury') THEN
UPDATE animals
SET health_status = 'sick'
WHERE animal_id = NEW.animal_id;
ELSEIF NEW.record_type = 'death' THEN
UPDATE animals
SET health_status = 'deceased'
WHERE animal_id = NEW.animal_id;
END IF;
END$$
CREATE TRIGGER trg_calculate_gdd
AFTER INSERT ON weather_data
FOR EACH ROW
BEGIN
DECLARE v_base_temp DECIMAL(4,1);
DECLARE v_gdd DECIMAL(8,2);
DECLARE v_farm_id INT;
SELECT farm_id INTO v_farm_id
FROM weather_stations
WHERE station_id = NEW.station_id;
INSERT INTO growth_stages (planting_id, stage_name, observation_date, gdd_accumulated)
SELECT
pr.planting_id,
'GDD Update',
DATE(NEW.observation_time),
calculate_gdd(
NEW.temperature_c - 5,  -- Assuming daily min is 5°C less
NEW.temperature_c + 5,  -- Assuming daily max is 5°C more
c.base_temperature_c
)
FROM planting_records pr
INNER JOIN fields f ON pr.field_id = f.field_id
INNER JOIN crops c ON pr.crop_id = c.crop_id
WHERE f.farm_id = v_farm_id
AND pr.status = 'growing'
AND DATE(NEW.observation_time) > pr.planting_date
ON DUPLICATE KEY UPDATE
gdd_accumulated = gdd_accumulated + VALUES(gdd_accumulated);
END$$
CREATE TRIGGER trg_validate_zone_area
BEFORE INSERT ON zones
FOR EACH ROW
BEGIN
DECLARE v_field_area DECIMAL(10,2);
DECLARE v_total_zone_area DECIMAL(10,2);
SELECT area_hectares INTO v_field_area
FROM fields
WHERE field_id = NEW.field_id;
SELECT COALESCE(SUM(area_hectares), 0) INTO v_total_zone_area
FROM zones
WHERE field_id = NEW.field_id;
IF (v_total_zone_area + NEW.area_hectares) > v_field_area THEN
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT = 'Total zone area cannot exceed field area';
END IF;
END$$
DELIMITER ;
ALTER TABLE sensors
ADD CONSTRAINT uk_zone_sensor_code
UNIQUE KEY (zone_id, sensor_code);
ALTER TABLE irrigation_schedules
ADD CONSTRAINT uk_system_active_schedule
UNIQUE KEY (system_id, schedule_name, is_active);
ALTER TABLE weather_stations
ADD CONSTRAINT uk_station_location
UNIQUE KEY (latitude, longitude);
ALTER TABLE sensor_readings
MODIFY COLUMN timestamp DATETIME DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE weather_data
MODIFY COLUMN observation_time DATETIME DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE irrigation_events
MODIFY COLUMN start_time DATETIME DEFAULT CURRENT_TIMESTAMP;
-- Indexes
