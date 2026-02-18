-- PostgreSQL Schema
-- Converted from MySQL on 2026-02-17T23:11:17.356050
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

ALTER TABLE depots
ADD CONSTRAINT fk_depot_company
FOREIGN KEY (company_id) REFERENCES companies(company_id)
ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE vehicles
ADD CONSTRAINT fk_vehicle_company
FOREIGN KEY (company_id) REFERENCES companies(company_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_vehicle_depot
FOREIGN KEY (depot_id) REFERENCES depots(depot_id)
ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE vehicle_specs
ADD CONSTRAINT fk_spec_vehicle
FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE drivers
ADD CONSTRAINT fk_driver_company
FOREIGN KEY (company_id) REFERENCES companies(company_id)
ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE driver_certifications
ADD CONSTRAINT fk_certification_driver
FOREIGN KEY (driver_id) REFERENCES drivers(driver_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE trips
ADD CONSTRAINT fk_trip_vehicle
FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_trip_driver
FOREIGN KEY (driver_id) REFERENCES drivers(driver_id)
ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE stops
ADD CONSTRAINT fk_stop_trip
FOREIGN KEY (trip_id) REFERENCES trips(trip_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE driver_events
ADD CONSTRAINT fk_event_vehicle
FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_event_driver
FOREIGN KEY (driver_id) REFERENCES drivers(driver_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_event_trip
FOREIGN KEY (trip_id) REFERENCES trips(trip_id)
ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE driver_scores
ADD CONSTRAINT fk_score_driver
FOREIGN KEY (driver_id) REFERENCES drivers(driver_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE routes
ADD CONSTRAINT fk_route_depot
FOREIGN KEY (depot_id) REFERENCES depots(depot_id)
ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE geofences
ADD CONSTRAINT fk_geofence_company
FOREIGN KEY (company_id) REFERENCES companies(company_id)
ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE geofence_events
ADD CONSTRAINT fk_geofence_event_geofence
FOREIGN KEY (geofence_id) REFERENCES geofences(geofence_id)
ON DELETE CASCADE ON UPDATE CASCADE,
ADD CONSTRAINT fk_geofence_event_vehicle
FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_geofence_event_driver
FOREIGN KEY (driver_id) REFERENCES drivers(driver_id)
ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE fuel_transactions
ADD CONSTRAINT fk_fuel_vehicle
FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_fuel_driver
FOREIGN KEY (driver_id) REFERENCES drivers(driver_id)
ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE maintenance_records
ADD CONSTRAINT fk_maintenance_vehicle
FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id)
ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE vehicle_diagnostics
ADD CONSTRAINT fk_diagnostics_vehicle
FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE driver_logs
ADD CONSTRAINT fk_log_driver
FOREIGN KEY (driver_id) REFERENCES drivers(driver_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_log_vehicle
FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id)
ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE hos_violations
ADD CONSTRAINT fk_violation_driver
FOREIGN KEY (driver_id) REFERENCES drivers(driver_id)
ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE dvir_reports
ADD CONSTRAINT fk_dvir_vehicle
FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_dvir_driver
FOREIGN KEY (driver_id) REFERENCES drivers(driver_id)
ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE vehicle_daily_summary
ADD CONSTRAINT fk_summary_vehicle
FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE depots
ADD CONSTRAINT chk_depot_coordinates
CHECK (latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180);
ALTER TABLE gps_positions
ADD CONSTRAINT chk_gps_coordinates
CHECK (latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180);
ALTER TABLE gps_positions
ADD CONSTRAINT chk_gps_speed
CHECK (speed_mph >= 0 AND speed_mph <= 150);
ALTER TABLE trips
ADD CONSTRAINT chk_trip_speed
CHECK (max_speed_mph >= 0 AND avg_speed_mph >= 0 AND avg_speed_mph <= max_speed_mph);
ALTER TABLE gps_positions
ADD CONSTRAINT chk_gps_heading
CHECK (heading >= 0 AND heading < 360);
ALTER TABLE gps_positions
ADD CONSTRAINT chk_fuel_level
CHECK (fuel_level_percent BETWEEN 0 AND 100);
ALTER TABLE trips
ADD CONSTRAINT chk_trip_times
CHECK (end_time IS NULL OR end_time > start_time);
ALTER TABLE stops
ADD CONSTRAINT chk_stop_times
CHECK (departure_time IS NULL OR departure_time > arrival_time);
ALTER TABLE driver_logs
ADD CONSTRAINT chk_log_times
CHECK (end_time IS NULL OR end_time > start_time);
ALTER TABLE driver_scores
ADD CONSTRAINT chk_driver_scores
CHECK (safety_score BETWEEN 0 AND 100 AND
fuel_efficiency_score BETWEEN 0 AND 100 AND
compliance_score BETWEEN 0 AND 100 AND
overall_score BETWEEN 0 AND 100);
ALTER TABLE vehicles
ADD CONSTRAINT chk_vehicle_year
CHECK (year BETWEEN 1990 AND YEAR(CURDATE()) + 1);
ALTER TABLE vehicles
ADD CONSTRAINT chk_vehicle_positive
CHECK (fuel_capacity_gallons > 0 AND
odometer_miles >= 0 AND
engine_hours >= 0);
ALTER TABLE fuel_transactions
ADD CONSTRAINT chk_fuel_positive
CHECK (gallons > 0 AND price_per_gallon > 0 AND total_cost > 0);
ALTER TABLE drivers
ADD CONSTRAINT chk_driver_license
CHECK (status != 'active' OR license_expiry > CURDATE());
DELIMITER $$
CREATE TRIGGER trg_update_vehicle_odometer
AFTER INSERT ON gps_positions
FOR EACH ROW
BEGIN
UPDATE vehicles
SET odometer_miles = NEW.odometer_miles,
engine_hours = NEW.engine_hours
WHERE vehicle_id = NEW.vehicle_id
AND (odometer_miles < NEW.odometer_miles OR odometer_miles IS NULL);
END$$
CREATE TRIGGER trg_complete_trip
AFTER INSERT ON gps_positions
FOR EACH ROW
BEGIN
IF NEW.ignition_on = FALSE THEN
UPDATE trips
SET end_time = NEW.timestamp,
end_latitude = NEW.latitude,
end_longitude = NEW.longitude,
status = 'completed'
WHERE vehicle_id = NEW.vehicle_id
AND driver_id = NEW.driver_id
AND status = 'in_progress';
END IF;
END$$
CREATE TRIGGER trg_calculate_trip_stats
BEFORE UPDATE ON trips
FOR EACH ROW
BEGIN
IF OLD.status = 'in_progress' AND NEW.status = 'completed' THEN
SET NEW.duration_minutes = TIMESTAMPDIFF(MINUTE, NEW.start_time, NEW.end_time);
END IF;
SELECT COUNT(*) INTO NEW.stops_count
FROM stops
WHERE trip_id = NEW.trip_id;
SELECT COUNT(*) INTO NEW.harsh_events_count
FROM driver_events
WHERE trip_id = NEW.trip_id;
END IF;
END$$
CREATE TRIGGER trg_update_driver_score
AFTER INSERT ON driver_events
FOR EACH ROW
BEGIN
DECLARE current_score DECIMAL(5,2);
SELECT safety_score INTO current_score
FROM driver_scores
WHERE driver_id = NEW.driver_id
AND score_date = DATE(NEW.timestamp);
IF current_score IS NULL THEN
INSERT INTO driver_scores (driver_id, score_date, safety_score)
VALUES (NEW.driver_id, DATE(NEW.timestamp), 95);
END IF;
UPDATE driver_scores
SET safety_score = GREATEST(0, safety_score -
CASE NEW.severity
WHEN 'high' THEN 5
WHEN 'medium' THEN 3
WHEN 'low' THEN 1
END),
harsh_events_count = harsh_events_count + 1
WHERE driver_id = NEW.driver_id
AND score_date = DATE(NEW.timestamp);
END$$
CREATE TRIGGER trg_check_hos_compliance
AFTER INSERT ON driver_logs
FOR EACH ROW
BEGIN
DECLARE driving_time_11h INT;
DECLARE on_duty_time_14h INT;
DECLARE weekly_time_70h INT;
SELECT SUM(duration_minutes) INTO driving_time_11h
FROM driver_logs
WHERE driver_id = NEW.driver_id
AND duty_status = 'driving'
AND start_time >= NEW.start_time - INTERVAL 14 HOUR;
IF driving_time_11h > 660 THEN -- 11 hours = 660 minutes
INSERT INTO hos_violations (driver_id, violation_date, violation_type, duration_minutes, severity)
VALUES (NEW.driver_id, DATE(NEW.start_time), '11_hour', driving_time_11h - 660, 'major');
END IF;
SELECT SUM(duration_minutes) INTO on_duty_time_14h
FROM driver_logs
WHERE driver_id = NEW.driver_id
AND duty_status IN ('driving', 'on_duty')
AND start_time >= NEW.start_time - INTERVAL 14 HOUR;
IF on_duty_time_14h > 840 THEN -- 14 hours = 840 minutes
INSERT INTO hos_violations (driver_id, violation_date, violation_type, duration_minutes, severity)
VALUES (NEW.driver_id, DATE(NEW.start_time), '14_hour', on_duty_time_14h - 840, 'major');
END IF;
SELECT SUM(duration_minutes) INTO weekly_time_70h
FROM driver_logs
WHERE driver_id = NEW.driver_id
AND duty_status IN ('driving', 'on_duty')
AND start_time >= NEW.start_time - INTERVAL 8 DAY;
IF weekly_time_70h > 4200 THEN -- 70 hours = 4200 minutes
INSERT INTO hos_violations (driver_id, violation_date, violation_type, duration_minutes, severity)
VALUES (NEW.driver_id, DATE(NEW.start_time), '70_hour_8day', weekly_time_70h - 4200, 'critical');
END IF;
END$$
CREATE TRIGGER trg_geofence_duration
BEFORE INSERT ON geofence_events
FOR EACH ROW
BEGIN
IF NEW.event_type = 'exit' THEN
SELECT TIMESTAMPDIFF(MINUTE, timestamp, NEW.timestamp) INTO NEW.duration_minutes
FROM geofence_events
WHERE geofence_id = NEW.geofence_id
AND vehicle_id = NEW.vehicle_id
AND event_type = 'enter'
AND timestamp < NEW.timestamp
ORDER BY timestamp DESC
LIMIT 1;
END IF;
END$$
CREATE TRIGGER trg_update_maintenance_schedule
AFTER INSERT ON maintenance_records
FOR EACH ROW
BEGIN
UPDATE vehicles
SET last_service_date = NEW.service_date,
last_service_miles = NEW.odometer_miles,
next_service_miles = NEW.next_service_miles
WHERE vehicle_id = NEW.vehicle_id;
END$$
CREATE TRIGGER trg_daily_summary
AFTER UPDATE ON trips
FOR EACH ROW
BEGIN
IF NEW.status = 'completed' AND OLD.status = 'in_progress' THEN
INSERT INTO vehicle_daily_summary (
vehicle_id, summary_date, total_miles, total_hours,
total_trips, total_fuel_gallons, harsh_events_count
)
VALUES (
NEW.vehicle_id,
DATE(NEW.end_time),
NEW.distance_miles,
NEW.duration_minutes / 60,
1,
NEW.fuel_consumed_gallons,
NEW.harsh_events_count
)
ON DUPLICATE KEY UPDATE
total_miles = total_miles + NEW.distance_miles,
total_hours = total_hours + (NEW.duration_minutes / 60),
total_trips = total_trips + 1,
total_fuel_gallons = total_fuel_gallons + COALESCE(NEW.fuel_consumed_gallons, 0),
harsh_events_count = harsh_events_count + NEW.harsh_events_count;
END IF;
END$$
DELIMITER ;
ALTER TABLE stops
ADD CONSTRAINT uk_trip_stop_sequence
UNIQUE KEY (trip_id, stop_sequence);
CREATE UNIQUE INDEX uk_active_trip_vehicle
ON trips(vehicle_id, status)
WHERE status = 'in_progress';
ALTER TABLE messages
MODIFY COLUMN sent_at DATETIME DEFAULT CURRENT_TIMESTAMP;
CREATE INDEX idx_gps_vehicle_tracking
ON gps_positions(vehicle_id, timestamp DESC, latitude, longitude, speed_mph);
CREATE INDEX idx_gps_driver_tracking
ON gps_positions(driver_id, timestamp DESC)
WHERE driver_id IS NOT NULL;
CREATE INDEX idx_gps_speeding
ON gps_positions(speed_mph, timestamp DESC)
WHERE speed_mph > 70;
CREATE INDEX idx_gps_idle
ON gps_positions(vehicle_id, timestamp, speed_mph)
WHERE ignition_on = TRUE AND speed_mph < 5;
CREATE INDEX idx_active_trips
ON trips(status, vehicle_id, driver_id)
WHERE status = 'in_progress';
CREATE INDEX idx_trip_history_vehicle
ON trips(vehicle_id, start_time DESC, end_time);
CREATE INDEX idx_trip_history_driver
ON trips(driver_id, start_time DESC, end_time);
CREATE INDEX idx_long_trips
ON trips(distance_miles DESC, duration_minutes DESC)
WHERE distance_miles > 500;
CREATE INDEX idx_stop_analysis
ON stops(stop_type, arrival_time, duration_minutes);
CREATE INDEX idx_driver_event_analysis
ON driver_events(driver_id, event_type, timestamp DESC, severity);
CREATE INDEX idx_severe_events
ON driver_events(severity, timestamp DESC)
WHERE severity = 'high';
CREATE INDEX idx_speeding_events
ON driver_events(event_type, timestamp DESC, speed_mph)
WHERE event_type = 'speeding';
CREATE INDEX idx_driver_performance
ON driver_scores(driver_id, score_date DESC, overall_score);
CREATE INDEX idx_low_scores
ON driver_scores(overall_score, score_date DESC)
WHERE overall_score < 70;
CREATE INDEX idx_active_vehicles_depot
ON vehicles(depot_id, status, vehicle_type)
WHERE status = 'active';
CREATE INDEX idx_maintenance_due
ON vehicles(next_service_miles, last_service_date)
WHERE status = 'active';
CREATE INDEX idx_diagnostic_alerts
ON vehicle_diagnostics(vehicle_id, timestamp DESC, check_engine_light)
WHERE check_engine_light = TRUE;
CREATE INDEX idx_maintenance_history
ON maintenance_records(vehicle_id, service_date DESC, maintenance_type);
CREATE INDEX idx_fuel_by_vehicle
ON fuel_transactions(vehicle_id, transaction_date DESC, gallons);
CREATE INDEX idx_fuel_efficiency
ON fuel_transactions(transaction_date, gallons, total_cost);
CREATE INDEX idx_fuel_card_usage
ON fuel_transactions(payment_method, driver_id, transaction_date)
WHERE payment_method = 'fuel_card';
CREATE INDEX idx_driver_log_lookup
ON driver_logs(driver_id, log_date DESC, duty_status);
CREATE INDEX idx_active_duty
ON driver_logs(duty_status, start_time DESC)
WHERE end_time IS NULL;
CREATE INDEX idx_hos_violations
ON hos_violations(driver_id, violation_date DESC, violation_type);
CREATE INDEX idx_unresolved_violations
ON hos_violations(resolved, severity, violation_date)
WHERE resolved = FALSE;
CREATE INDEX idx_dvir_defects
ON dvir_reports(defects_found, vehicle_id, inspection_date)
WHERE defects_found = TRUE;
CREATE INDEX idx_unrepaired_defects
ON dvir_reports(repaired, inspection_date)
WHERE defects_found = TRUE AND repaired = FALSE;
CREATE INDEX idx_active_geofences_lookup
ON geofences(company_id, geofence_type, is_active)
WHERE is_active = TRUE;
CREATE INDEX idx_geofence_event_history
ON geofence_events(geofence_id, timestamp DESC, event_type);
CREATE INDEX idx_vehicle_geofence_activity
ON geofence_events(vehicle_id, timestamp DESC, geofence_id);
CREATE INDEX idx_active_routes_depot
ON routes(depot_id, is_active)
WHERE is_active = TRUE;
CREATE INDEX idx_unread_messages
ON messages(recipient_type, recipient_id, read_status, sent_at DESC)
WHERE read_status = FALSE;
CREATE INDEX idx_priority_messages
ON messages(priority, sent_at DESC)
WHERE priority IN ('high', 'urgent');
CREATE INDEX idx_daily_summary_lookup
ON vehicle_daily_summary(summary_date DESC, vehicle_id);
CREATE INDEX idx_high_mileage
ON vehicle_daily_summary(total_miles DESC, summary_date);
CREATE INDEX idx_license_expiry
ON drivers(license_expiry, status)
WHERE status = 'active';
CREATE INDEX idx_medical_expiry
ON drivers(medical_cert_expiry, status)
WHERE status = 'active' AND medical_cert_expiry IS NOT NULL;
CREATE FULLTEXT INDEX ft_driver_search
ON drivers(first_name, last_name, email);
CREATE FULLTEXT INDEX ft_vehicle_search
ON vehicles(vehicle_number, vin, license_plate);
CREATE FULLTEXT INDEX ft_message_search
ON messages(message_text);
CREATE FULLTEXT INDEX ft_maintenance_search
ON maintenance_records(description);
ALTER TABLE routes ADD INDEX idx_route_waypoints
((CAST(waypoints->'$[0].lat' AS DECIMAL(10,6))),
(CAST(waypoints->'$[0].lng' AS DECIMAL(10,6))));
ALTER TABLE vehicle_diagnostics ADD INDEX idx_dtc_codes
((CAST(dtc_codes->'$[*]' AS CHAR(10) ARRAY)));
ALTER TABLE dvir_reports ADD INDEX idx_defect_types
((CAST(defect_details->'$[*].type' AS CHAR(50) ARRAY)));
CREATE INDEX idx_fleet_dashboard
ON vehicles(company_id, status, vehicle_type, depot_id, odometer_miles)
WHERE status = 'active';
CREATE INDEX idx_driver_dashboard
ON drivers(company_id, status, license_class, license_expiry)
WHERE status = 'active';
CREATE INDEX idx_realtime_tracking
ON gps_positions(timestamp DESC, vehicle_id, latitude, longitude, speed_mph, ignition_on);
CREATE INDEX idx_compliance_dashboard
ON driver_logs(log_date DESC, driver_id, duty_status, certified);
CREATE TABLE IF NOT EXISTS gps_positions_hourly (
    vehicle_id INTEGER NOT NULL,
    hour_timestamp TIMESTAMP NOT NULL,
    avg_speed_mph DECIMAL(5,2),
    max_speed_mph DECIMAL(5,2),
    distance_miles DECIMAL(10,2),
    position_count INTEGER,
    idle_minutes INTEGER,
    PRIMARY KEY (vehicle_id, hour_timestamp)
);

ANALYZE TABLE companies;
ANALYZE TABLE depots;
ANALYZE TABLE vehicles;
ANALYZE TABLE drivers;
ANALYZE TABLE gps_positions;
ANALYZE TABLE trips;
ANALYZE TABLE driver_events;
ANALYZE TABLE driver_scores;
ANALYZE TABLE fuel_transactions;
ANALYZE TABLE maintenance_records;
ANALYZE TABLE driver_logs;
ANALYZE TABLE hos_violations;
-- Indexes
