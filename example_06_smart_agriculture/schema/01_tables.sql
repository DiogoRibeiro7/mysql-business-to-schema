-- ============================================================================
-- Smart Agriculture Tables
-- ============================================================================

USE smart_agriculture;

-- ============================================================================
-- Farm Infrastructure Tables
-- ============================================================================

-- Farms table
CREATE TABLE farms (
    farm_id INT PRIMARY KEY AUTO_INCREMENT,
    farm_name VARCHAR(100) NOT NULL,
    farm_type ENUM('crop', 'dairy', 'mixed', 'orchard', 'greenhouse', 'aquaculture') NOT NULL,
    owner_name VARCHAR(100),
    location VARCHAR(200),
    total_area_hectares DECIMAL(10,2),
    latitude DECIMAL(10,6),
    longitude DECIMAL(10,6),
    elevation_meters INT,
    climate_zone VARCHAR(50),
    soil_type VARCHAR(50),
    established_date DATE,
    organic_certified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_farm_type (farm_type),
    INDEX idx_location (latitude, longitude)
) ENGINE=InnoDB;

-- Fields within farms
CREATE TABLE fields (
    field_id INT PRIMARY KEY AUTO_INCREMENT,
    farm_id INT NOT NULL,
    field_name VARCHAR(100) NOT NULL,
    area_hectares DECIMAL(10,2) NOT NULL,
    soil_type VARCHAR(50),
    slope_percentage DECIMAL(5,2),
    drainage_class ENUM('well', 'moderate', 'poor') DEFAULT 'moderate',
    irrigation_type ENUM('drip', 'sprinkler', 'flood', 'pivot', 'none') DEFAULT 'none',
    gps_boundaries JSON COMMENT 'Array of lat/lng coordinates defining field boundary',
    last_soil_test DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_farm_field (farm_id),
    INDEX idx_irrigation (irrigation_type)
) ENGINE=InnoDB;

-- Zones within fields (for precision agriculture)
CREATE TABLE zones (
    zone_id INT PRIMARY KEY AUTO_INCREMENT,
    field_id INT NOT NULL,
    zone_name VARCHAR(50),
    area_hectares DECIMAL(8,2),
    management_zone_type ENUM('productivity', 'soil_type', 'topography', 'custom') DEFAULT 'productivity',
    characteristics JSON COMMENT 'Zone-specific characteristics',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_field_zone (field_id)
) ENGINE=InnoDB;

-- ============================================================================
-- Crop Management Tables
-- ============================================================================

-- Crop types catalog
CREATE TABLE crops (
    crop_id INT PRIMARY KEY AUTO_INCREMENT,
    crop_name VARCHAR(100) NOT NULL,
    scientific_name VARCHAR(200),
    crop_family VARCHAR(100),
    crop_type ENUM('cereal', 'legume', 'vegetable', 'fruit', 'forage', 'cash_crop') NOT NULL,
    growth_days INT COMMENT 'Typical days from planting to harvest',
    base_temperature_c DECIMAL(4,1) COMMENT 'Base temperature for GDD calculation',
    optimal_temp_min DECIMAL(4,1),
    optimal_temp_max DECIMAL(4,1),
    water_needs_mm_per_day DECIMAL(5,2),
    nitrogen_kg_per_hectare DECIMAL(6,2),
    phosphorus_kg_per_hectare DECIMAL(6,2),
    potassium_kg_per_hectare DECIMAL(6,2),
    optimal_ph_min DECIMAL(3,1),
    optimal_ph_max DECIMAL(3,1),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_crop_type (crop_type)
) ENGINE=InnoDB;

-- Planting records
CREATE TABLE planting_records (
    planting_id INT PRIMARY KEY AUTO_INCREMENT,
    field_id INT NOT NULL,
    zone_id INT,
    crop_id INT NOT NULL,
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
    status ENUM('planned', 'planted', 'growing', 'harvested', 'failed') DEFAULT 'planned',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_field_planting (field_id),
    INDEX idx_crop_planting (crop_id),
    INDEX idx_planting_date (planting_date),
    INDEX idx_status (status)
) ENGINE=InnoDB;

-- Crop growth stages
CREATE TABLE growth_stages (
    stage_id INT PRIMARY KEY AUTO_INCREMENT,
    planting_id INT NOT NULL,
    stage_name VARCHAR(50) NOT NULL,
    stage_code VARCHAR(20) COMMENT 'BBCH or other standard code',
    observation_date DATE NOT NULL,
    gdd_accumulated DECIMAL(8,2) COMMENT 'Growing degree days accumulated',
    plant_height_cm DECIMAL(6,1),
    leaf_area_index DECIMAL(4,2),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_planting_stage (planting_id),
    INDEX idx_observation_date (observation_date)
) ENGINE=InnoDB;

-- ============================================================================
-- Sensor and IoT Tables
-- ============================================================================

-- Sensors deployed in fields
CREATE TABLE sensors (
    sensor_id INT PRIMARY KEY AUTO_INCREMENT,
    zone_id INT NOT NULL,
    sensor_code VARCHAR(50) UNIQUE NOT NULL,
    sensor_type ENUM('soil_moisture', 'soil_temperature', 'soil_ph', 'soil_ec',
                     'air_temperature', 'humidity', 'light', 'rainfall',
                     'wind_speed', 'wind_direction', 'leaf_wetness', 'soil_npk') NOT NULL,
    manufacturer VARCHAR(100),
    model VARCHAR(100),
    installation_date DATE,
    depth_cm INT COMMENT 'For soil sensors',
    height_m DECIMAL(4,2) COMMENT 'For above-ground sensors',
    calibration_date DATE,
    battery_type VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_zone_sensor (zone_id),
    INDEX idx_sensor_type (sensor_type),
    INDEX idx_active (is_active)
) ENGINE=InnoDB;

-- Sensor readings (partitioned by day for high-frequency data)
CREATE TABLE sensor_readings (
    reading_id BIGINT AUTO_INCREMENT,
    sensor_id INT NOT NULL,
    timestamp DATETIME NOT NULL,
    value DECIMAL(12,4) NOT NULL,
    unit VARCHAR(20),
    quality_flag ENUM('good', 'suspect', 'bad') DEFAULT 'good',
    battery_voltage DECIMAL(4,2),
    PRIMARY KEY (reading_id, timestamp),
    INDEX idx_sensor_time (sensor_id, timestamp),
    INDEX idx_timestamp (timestamp)
) ENGINE=InnoDB;

-- ============================================================================
-- Weather Data Tables
-- ============================================================================

-- Weather stations
CREATE TABLE weather_stations (
    station_id INT PRIMARY KEY AUTO_INCREMENT,
    farm_id INT NOT NULL,
    station_name VARCHAR(100),
    latitude DECIMAL(10,6),
    longitude DECIMAL(10,6),
    elevation_m INT,
    installation_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    INDEX idx_farm_station (farm_id)
) ENGINE=InnoDB;

-- Weather observations
CREATE TABLE weather_data (
    weather_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    station_id INT NOT NULL,
    observation_time DATETIME NOT NULL,
    temperature_c DECIMAL(5,2),
    humidity_percent DECIMAL(5,2),
    pressure_hpa DECIMAL(7,2),
    rainfall_mm DECIMAL(6,2),
    wind_speed_kmh DECIMAL(5,2),
    wind_direction_degrees INT,
    solar_radiation_wm2 DECIMAL(6,2),
    uv_index DECIMAL(3,1),
    evapotranspiration_mm DECIMAL(5,2),
    dew_point_c DECIMAL(5,2),
    INDEX idx_station_time (station_id, observation_time),
    INDEX idx_observation_time (observation_time)
) ENGINE=InnoDB;

-- ============================================================================
-- Irrigation Management Tables
-- ============================================================================

-- Irrigation systems
CREATE TABLE irrigation_systems (
    system_id INT PRIMARY KEY AUTO_INCREMENT,
    field_id INT NOT NULL,
    system_type ENUM('drip', 'sprinkler', 'pivot', 'flood', 'micro_sprinkler') NOT NULL,
    flow_rate_lpm DECIMAL(10,2) COMMENT 'Liters per minute',
    coverage_area_hectares DECIMAL(10,2),
    efficiency_percentage DECIMAL(5,2) DEFAULT 85,
    installation_date DATE,
    last_maintenance_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    INDEX idx_field_irrigation (field_id)
) ENGINE=InnoDB;

-- Irrigation events
CREATE TABLE irrigation_events (
    event_id INT PRIMARY KEY AUTO_INCREMENT,
    system_id INT NOT NULL,
    zone_id INT,
    start_time DATETIME NOT NULL,
    end_time DATETIME,
    water_amount_liters DECIMAL(12,2),
    trigger_type ENUM('manual', 'scheduled', 'sensor', 'weather') NOT NULL,
    trigger_reason VARCHAR(200),
    soil_moisture_before DECIMAL(5,2),
    soil_moisture_after DECIMAL(5,2),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_system_event (system_id),
    INDEX idx_zone_event (zone_id),
    INDEX idx_event_time (start_time)
) ENGINE=InnoDB;

-- Irrigation schedules
CREATE TABLE irrigation_schedules (
    schedule_id INT PRIMARY KEY AUTO_INCREMENT,
    system_id INT NOT NULL,
    schedule_name VARCHAR(100),
    days_of_week SET('Mon','Tue','Wed','Thu','Fri','Sat','Sun'),
    start_time TIME,
    duration_minutes INT,
    water_amount_mm DECIMAL(6,2),
    moisture_threshold_min DECIMAL(5,2),
    moisture_threshold_max DECIMAL(5,2),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_system_schedule (system_id),
    INDEX idx_active_schedule (is_active)
) ENGINE=InnoDB;

-- ============================================================================
-- Fertilizer and Treatment Tables
-- ============================================================================

-- Fertilizer applications
CREATE TABLE fertilizer_applications (
    application_id INT PRIMARY KEY AUTO_INCREMENT,
    field_id INT NOT NULL,
    zone_id INT,
    application_date DATE NOT NULL,
    fertilizer_type VARCHAR(100),
    n_kg_per_hectare DECIMAL(8,2),
    p_kg_per_hectare DECIMAL(8,2),
    k_kg_per_hectare DECIMAL(8,2),
    application_method ENUM('broadcast', 'banding', 'foliar', 'fertigation', 'injection') NOT NULL,
    cost_per_hectare DECIMAL(10,2),
    weather_conditions VARCHAR(200),
    operator_id INT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_field_fertilizer (field_id),
    INDEX idx_application_date (application_date)
) ENGINE=InnoDB;

-- Pesticide applications
CREATE TABLE pesticide_applications (
    application_id INT PRIMARY KEY AUTO_INCREMENT,
    field_id INT NOT NULL,
    zone_id INT,
    application_date DATE NOT NULL,
    product_name VARCHAR(100) NOT NULL,
    active_ingredient VARCHAR(100),
    target_pest VARCHAR(100),
    application_rate_per_hectare VARCHAR(50),
    rei_hours INT COMMENT 'Restricted Entry Interval',
    phi_days INT COMMENT 'Pre-Harvest Interval',
    application_method ENUM('spray', 'granular', 'seed_treatment', 'soil_injection') NOT NULL,
    weather_conditions VARCHAR(200),
    wind_speed_kmh DECIMAL(5,2),
    temperature_c DECIMAL(5,2),
    operator_id INT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_field_pesticide (field_id),
    INDEX idx_pest_date (application_date)
) ENGINE=InnoDB;

-- ============================================================================
-- Livestock Tables
-- ============================================================================

-- Animals/Livestock
CREATE TABLE animals (
    animal_id INT PRIMARY KEY AUTO_INCREMENT,
    farm_id INT NOT NULL,
    tag_number VARCHAR(50) UNIQUE,
    animal_type ENUM('cattle', 'sheep', 'goat', 'pig', 'chicken', 'horse') NOT NULL,
    breed VARCHAR(100),
    gender ENUM('male', 'female') NOT NULL,
    birth_date DATE,
    weight_kg DECIMAL(8,2),
    mother_id INT,
    father_id INT,
    purchase_date DATE,
    purchase_price DECIMAL(10,2),
    current_location VARCHAR(100),
    health_status ENUM('healthy', 'sick', 'quarantine', 'deceased') DEFAULT 'healthy',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_farm_animal (farm_id),
    INDEX idx_animal_type (animal_type),
    INDEX idx_health_status (health_status)
) ENGINE=InnoDB;

-- Animal health records
CREATE TABLE health_records (
    record_id INT PRIMARY KEY AUTO_INCREMENT,
    animal_id INT NOT NULL,
    record_date DATE NOT NULL,
    record_type ENUM('vaccination', 'treatment', 'checkup', 'injury', 'birth', 'death') NOT NULL,
    description TEXT,
    medication VARCHAR(200),
    dosage VARCHAR(100),
    veterinarian_name VARCHAR(100),
    cost DECIMAL(10,2),
    next_followup_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_animal_health (animal_id),
    INDEX idx_record_date (record_date),
    INDEX idx_record_type (record_type)
) ENGINE=InnoDB;

-- Milk production (for dairy)
CREATE TABLE milk_production (
    production_id INT PRIMARY KEY AUTO_INCREMENT,
    animal_id INT NOT NULL,
    milking_date DATE NOT NULL,
    milking_time ENUM('morning', 'evening') NOT NULL,
    quantity_liters DECIMAL(6,2) NOT NULL,
    fat_percentage DECIMAL(4,2),
    protein_percentage DECIMAL(4,2),
    somatic_cell_count INT,
    temperature_c DECIMAL(4,1),
    quality_grade ENUM('A', 'B', 'C', 'rejected'),
    INDEX idx_animal_milk (animal_id),
    INDEX idx_milking_date (milking_date),
    UNIQUE KEY uk_animal_milking (animal_id, milking_date, milking_time)
) ENGINE=InnoDB;

-- ============================================================================
-- Harvest and Yield Tables
-- ============================================================================

-- Harvest records
CREATE TABLE harvest_records (
    harvest_id INT PRIMARY KEY AUTO_INCREMENT,
    planting_id INT NOT NULL,
    harvest_date DATE NOT NULL,
    area_harvested_hectares DECIMAL(10,2) NOT NULL,
    total_yield_kg DECIMAL(12,2) NOT NULL,
    marketable_yield_kg DECIMAL(12,2),
    moisture_percentage DECIMAL(5,2),
    quality_grade ENUM('premium', 'standard', 'processing', 'feed', 'rejected'),
    storage_location VARCHAR(100),
    harvest_method ENUM('manual', 'mechanical', 'combined') DEFAULT 'mechanical',
    weather_conditions VARCHAR(200),
    labor_hours DECIMAL(8,2),
    harvest_cost DECIMAL(10,2),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_planting_harvest (planting_id),
    INDEX idx_harvest_date (harvest_date)
) ENGINE=InnoDB;

-- Yield predictions (ML-based)
CREATE TABLE yield_predictions (
    prediction_id INT PRIMARY KEY AUTO_INCREMENT,
    planting_id INT NOT NULL,
    prediction_date DATE NOT NULL,
    predicted_yield_kg_per_hectare DECIMAL(10,2),
    confidence_level DECIMAL(5,2),
    model_version VARCHAR(20),
    factors JSON COMMENT 'Factors used in prediction',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_planting_prediction (planting_id),
    INDEX idx_prediction_date (prediction_date)
) ENGINE=InnoDB;

-- ============================================================================
-- Personnel Tables
-- ============================================================================

-- Farm workers/operators
CREATE TABLE operators (
    operator_id INT PRIMARY KEY AUTO_INCREMENT,
    farm_id INT NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    role ENUM('owner', 'manager', 'supervisor', 'operator', 'seasonal') NOT NULL,
    specialization VARCHAR(100),
    phone VARCHAR(20),
    email VARCHAR(200),
    hire_date DATE,
    certifications JSON,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_farm_operator (farm_id),
    INDEX idx_role (role)
) ENGINE=InnoDB;
