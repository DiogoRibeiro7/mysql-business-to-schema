-- PostgreSQL Schema
-- Converted from MySQL on 2026-02-17T23:11:17.354520
-- Generator: MySQL to PostgreSQL Converter

-- Enum Types
CREATE TYPE vehicles_status AS ENUM ('active', 'maintenance', 'inactive', 'retired');
CREATE TYPE drivers_status AS ENUM ('active', 'inactive', 'terminated', 'suspended');
CREATE TYPE trips_status AS ENUM ('in_progress', 'completed', 'cancelled');
CREATE TYPE stops_status AS ENUM ('delivery', 'pickup', 'break', 'fuel', 'maintenance', 'other');
CREATE TYPE driver_events_status AS ENUM ('low', 'medium', 'high');
CREATE TYPE geofences_status AS ENUM ('depot', 'customer', 'restricted', 'rest_area');
CREATE TYPE geofence_events_status AS ENUM ('enter', 'exit');
CREATE TYPE fuel_transactions_status AS ENUM ('fuel_card', 'credit_card', 'cash', 'account');
CREATE TYPE maintenance_records_status AS ENUM ('preventive', 'repair', 'inspection', 'recall');
CREATE TYPE driver_logs_status AS ENUM ('off_duty', 'sleeper', 'driving', 'on_duty', 'yard_move', 'personal_use');
CREATE TYPE hos_violations_status AS ENUM ('minor', 'major', 'critical');
CREATE TYPE dvir_reports_status AS ENUM ('pre_trip', 'post_trip');
CREATE TYPE messages_status AS ENUM ('low', 'normal', 'high', 'urgent');

DROP DATABASE IF EXISTS fleet_management;
-- Create database (run as superuser)
-- CREATE DATABASE fleet_management;
-- \c fleet_management

DELIMITER $$
CREATE FUNCTION calculate_distance(
lat1 DECIMAL(10,6),
lon1 DECIMAL(10,6),
lat2 DECIMAL(10,6),
lon2 DECIMAL(10,6)
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
DECLARE R DECIMAL(10,2) DEFAULT 6371; -- Earth radius in km
DECLARE dLat DECIMAL(10,6);
DECLARE dLon DECIMAL(10,6);
DECLARE a DECIMAL(10,6);
DECLARE c DECIMAL(10,6);
RETURN R * c; -- Distance in km
END$$
CREATE PROCEDURE create_gps_partitions(
IN days_ahead INT
)
BEGIN
DECLARE i INT DEFAULT 0;
DECLARE partition_date DATE;
DECLARE partition_name VARCHAR(64);
WHILE i < days_ahead DO
SET partition_date = DATE_ADD(CURDATE(), INTERVAL i DAY);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
END WHILE;
END$$
DELIMITER ;
CREATE USER IF NOT EXISTS 'fleet_manager'@'%' IDENTIFIED BY 'fleet_pass_2024';
GRANT ALL PRIVILEGES ON fleet_management.* TO 'fleet_manager'@'%';
CREATE USER IF NOT EXISTS 'dispatcher'@'%' IDENTIFIED BY 'dispatch_pass_2024';
GRANT SELECT, INSERT, UPDATE ON fleet_management.* TO 'dispatcher'@'%';
CREATE USER IF NOT EXISTS 'driver_app'@'%' IDENTIFIED BY 'driver_pass_2024';
GRANT SELECT ON fleet_management.* TO 'driver_app'@'%';
GRANT INSERT ON fleet_management.gps_positions TO 'driver_app'@'%';
GRANT INSERT ON fleet_management.driver_logs TO 'driver_app'@'%';
CREATE USER IF NOT EXISTS 'compliance'@'%' IDENTIFIED BY 'compliance_pass_2024';
GRANT SELECT ON fleet_management.* TO 'compliance'@'%';
CREATE USER IF NOT EXISTS 'analyst'@'%' IDENTIFIED BY 'analyst_pass_2024';
GRANT SELECT ON fleet_management.* TO 'analyst'@'%';
FLUSH PRIVILEGES;
CREATE TABLE IF NOT EXISTS companies (
    company_name VARCHAR(100) NOT NULL,
    mc_number VARCHAR(20),
    address VARCHAR(200),
    city VARCHAR(100),
    state VARCHAR(2),
    zip_code VARCHAR(10),
    country VARCHAR(50) DEFAULT 'USA',
    phone VARCHAR(20),
    email VARCHAR(200),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS depots (
    company_id INTEGER NOT NULL,
    depot_name VARCHAR(100) NOT NULL,
    address VARCHAR(200),
    city VARCHAR(100),
    state VARCHAR(2),
    latitude DECIMAL(10,6),
    longitude DECIMAL(10,6),
    timezone VARCHAR(50) DEFAULT 'America/New_York',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS vehicles (
    company_id INTEGER NOT NULL,
    depot_id INTEGER,
    vehicle_type vehicles_status NOT NULL,
    make VARCHAR(50),
    model VARCHAR(50),
    year INTEGER,
    color VARCHAR(30),
    fuel_type vehicles_status DEFAULT 'diesel',
    fuel_capacity_gallons DECIMAL(6,2),
    odometer_miles DECIMAL(10,1),
    engine_hours DECIMAL(10,1),
    purchase_date DATE,
    registration_expiry DATE,
    insurance_expiry DATE,
    last_service_date DATE,
    last_service_miles DECIMAL(10,1),
    next_service_miles DECIMAL(10,1),
    status vehicles_status DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS vehicle_specs (
    gross_vehicle_weight_lbs INTEGER,
    cargo_capacity_lbs INTEGER,
    cargo_volume_cubic_ft DECIMAL(10,2),
    mpg_city DECIMAL(5,2),
    mpg_highway DECIMAL(5,2),
    has_gps BOOLEAN DEFAULT TRUE,
    has_eld BOOLEAN DEFAULT TRUE,
    has_camera BOOLEAN DEFAULT FALSE,
    has_temperature_control BOOLEAN DEFAULT FALSE,
    has_liftgate BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS drivers (
    company_id INTEGER NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    license_state VARCHAR(2),
    license_class drivers_status NOT NULL,
    license_expiry DATE NOT NULL,
    medical_cert_expiry DATE,
    hire_date DATE,
    birth_date DATE,
    address VARCHAR(200),
    city VARCHAR(100),
    state VARCHAR(2),
    zip_code VARCHAR(10),
    emergency_contact VARCHAR(200),
    emergency_phone VARCHAR(20),
    status drivers_status DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS driver_certifications (
    driver_id INTEGER NOT NULL,
    certification_type VARCHAR(100) NOT NULL,
    certification_number VARCHAR(50),
    issue_date DATE,
    expiry_date DATE,
    issuing_authority VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS gps_positions (
    position_id BIGSERIAL,
    vehicle_id INTEGER NOT NULL,
    driver_id INTEGER,
    timestamp TIMESTAMP NOT NULL,
    latitude DECIMAL(10,6) NOT NULL,
    longitude DECIMAL(10,6) NOT NULL,
    speed_mph DECIMAL(5,2),
    heading INTEGER,
    altitude_feet INTEGER,
    satellites INTEGER,
    hdop DECIMAL(4,2),
    ignition_on BOOLEAN DEFAULT TRUE,
    odometer_miles DECIMAL(10,1),
    engine_hours DECIMAL(10,1),
    fuel_level_percent DECIMAL(5,2),
    PRIMARY KEY (position_id, timestamp),
    PARTITION TEXT VALUES LESS THAN (TO_DAYS('2025-03-01')),
    PARTITION TEXT VALUES LESS THAN MAXVALUE
);

CREATE TABLE IF NOT EXISTS trips (
    vehicle_id INTEGER NOT NULL,
    driver_id INTEGER NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    start_location VARCHAR(200),
    start_latitude DECIMAL(10,6),
    start_longitude DECIMAL(10,6),
    end_location VARCHAR(200),
    end_latitude DECIMAL(10,6),
    end_longitude DECIMAL(10,6),
    distance_miles DECIMAL(10,2),
    duration_minutes INTEGER,
    max_speed_mph DECIMAL(5,2),
    avg_speed_mph DECIMAL(5,2),
    fuel_consumed_gallons DECIMAL(8,2),
    idle_time_minutes INTEGER,
    stops_count INTEGER DEFAULT 0,
    harsh_events_count INTEGER DEFAULT 0,
    status trips_status DEFAULT 'in_progress',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS stops (
    trip_id INTEGER NOT NULL,
    stop_sequence INTEGER NOT NULL,
    arrival_time TIMESTAMP NOT NULL,
    departure_time TIMESTAMP,
    latitude DECIMAL(10,6),
    longitude DECIMAL(10,6),
    address VARCHAR(200),
    stop_type stops_status DEFAULT 'delivery',
    duration_minutes INTEGER,
    notes TEXT
);

CREATE TABLE IF NOT EXISTS driver_events (
    vehicle_id INTEGER NOT NULL,
    driver_id INTEGER NOT NULL,
    trip_id INTEGER,
    event_type driver_events_status NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    latitude DECIMAL(10,6),
    longitude DECIMAL(10,6),
    speed_mph DECIMAL(5,2),
    g_force DECIMAL(4,2),
    speed_limit_mph INTEGER,
    duration_seconds INTEGER,
    severity driver_events_status DEFAULT 'medium',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS driver_scores (
    driver_id INTEGER NOT NULL,
    score_date DATE NOT NULL,
    safety_score DECIMAL(5,2) DEFAULT 100,
    fuel_efficiency_score DECIMAL(5,2) DEFAULT 100,
    compliance_score DECIMAL(5,2) DEFAULT 100,
    overall_score DECIMAL(5,2) DEFAULT 100,
    miles_driven DECIMAL(10,2),
    trips_count INTEGER,
    harsh_events_count INTEGER DEFAULT 0,
    speeding_minutes INTEGER DEFAULT 0,
    idle_minutes INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (driver_id, score_date)
);

CREATE TABLE IF NOT EXISTS routes (
    route_name VARCHAR(100) NOT NULL,
    depot_id INTEGER,
    total_distance_miles DECIMAL(10,2),
    estimated_duration_minutes INTEGER,
    waypoints JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS geofences (
    company_id INTEGER NOT NULL,
    geofence_name VARCHAR(100) NOT NULL,
    geofence_type geofences_status NOT NULL,
    center_latitude DECIMAL(10,6),
    center_longitude DECIMAL(10,6),
    radius_meters INTEGER,
    polygon JSONB,
    alert_on_entry BOOLEAN DEFAULT TRUE,
    alert_on_exit BOOLEAN DEFAULT TRUE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS geofence_events (
    geofence_id INTEGER NOT NULL,
    vehicle_id INTEGER NOT NULL,
    driver_id INTEGER,
    event_type geofence_events_status NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    duration_minutes INTEGER COMMENT 'For exit events,
    time TEXT inside'
);

CREATE TABLE IF NOT EXISTS fuel_transactions (
    vehicle_id INTEGER NOT NULL,
    driver_id INTEGER,
    transaction_date TIMESTAMP NOT NULL,
    station_name VARCHAR(100),
    station_address VARCHAR(200),
    latitude DECIMAL(10,6),
    longitude DECIMAL(10,6),
    gallons DECIMAL(8,2) NOT NULL,
    price_per_gallon DECIMAL(6,3),
    total_cost DECIMAL(10,2),
    odometer_miles DECIMAL(10,1),
    payment_method fuel_transactions_status DEFAULT 'fuel_card',
    receipt_number VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS maintenance_records (
    vehicle_id INTEGER NOT NULL,
    maintenance_type maintenance_records_status NOT NULL,
    service_date DATE NOT NULL,
    odometer_miles DECIMAL(10,1),
    engine_hours DECIMAL(10,1),
    service_provider VARCHAR(100),
    description TEXT,
    parts_cost DECIMAL(10,2),
    labor_cost DECIMAL(10,2),
    total_cost DECIMAL(10,2),
    next_service_miles DECIMAL(10,1),
    next_service_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS vehicle_diagnostics (
    vehicle_id INTEGER NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    engine_rpm INTEGER,
    engine_load_percent DECIMAL(5,2),
    coolant_temp_f INTEGER,
    oil_pressure_psi DECIMAL(5,2),
    battery_voltage DECIMAL(4,2),
    dtc_codes JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS driver_logs (
    driver_id INTEGER NOT NULL,
    log_date DATE NOT NULL,
    duty_status driver_logs_status NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    duration_minutes INTEGER,
    location VARCHAR(200),
    latitude DECIMAL(10,6),
    longitude DECIMAL(10,6),
    vehicle_id INTEGER,
    odometer_start DECIMAL(10,1),
    odometer_end DECIMAL(10,1),
    notes TEXT,
    certified BOOLEAN DEFAULT FALSE,
    certified_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (driver_id, start_time)
);

CREATE TABLE IF NOT EXISTS hos_violations (
    driver_id INTEGER NOT NULL,
    violation_date DATE NOT NULL,
    violation_type hos_violations_status NOT NULL,
    duration_minutes INTEGER,
    description TEXT,
    severity hos_violations_status DEFAULT 'major',
    resolved BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS dvir_reports (
    vehicle_id INTEGER NOT NULL,
    driver_id INTEGER NOT NULL,
    inspection_date DATE NOT NULL,
    inspection_type dvir_reports_status NOT NULL,
    odometer_miles DECIMAL(10,1),
    defects_found BOOLEAN DEFAULT FALSE,
    defect_details JSONB,
    signature_driver VARCHAR(200),
    signature_mechanic VARCHAR(200),
    repaired BOOLEAN DEFAULT FALSE,
    repair_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (vehicle_id, inspection_date, inspection_type)
);

CREATE TABLE IF NOT EXISTS messages (
    sender_type messages_status NOT NULL,
    sender_id INTEGER,
    recipient_type messages_status NOT NULL,
    recipient_id INTEGER,
    message_text TEXT NOT NULL,
    priority messages_status DEFAULT 'normal',
    read_status BOOLEAN DEFAULT FALSE,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS vehicle_daily_summary (
    vehicle_id INTEGER NOT NULL,
    summary_date DATE NOT NULL,
    total_miles DECIMAL(10,2),
    total_hours DECIMAL(10,2),
    total_trips INTEGER,
    total_stops INTEGER,
    total_fuel_gallons DECIMAL(10,2),
    avg_mpg DECIMAL(5,2),
    total_idle_minutes INTEGER,
    harsh_events_count INTEGER,
    max_speed_mph DECIMAL(5,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (vehicle_id, summary_date)
);

-- Indexes
