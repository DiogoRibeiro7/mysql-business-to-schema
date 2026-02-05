-- ============================================================================
-- Fleet Management Tables
-- ============================================================================

USE fleet_management;

-- ============================================================================
-- Company and Depot Tables
-- ============================================================================

-- Company information
CREATE TABLE companies (
    company_id INT PRIMARY KEY AUTO_INCREMENT,
    company_name VARCHAR(100) NOT NULL,
    dot_number VARCHAR(20) UNIQUE,
    mc_number VARCHAR(20),
    address VARCHAR(200),
    city VARCHAR(100),
    state VARCHAR(2),
    zip_code VARCHAR(10),
    country VARCHAR(50) DEFAULT 'USA',
    phone VARCHAR(20),
    email VARCHAR(200),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_company_name (company_name)
) ENGINE=InnoDB;

-- Depot/terminal locations
CREATE TABLE depots (
    depot_id INT PRIMARY KEY AUTO_INCREMENT,
    company_id INT NOT NULL,
    depot_name VARCHAR(100) NOT NULL,
    depot_code VARCHAR(20) UNIQUE,
    address VARCHAR(200),
    city VARCHAR(100),
    state VARCHAR(2),
    latitude DECIMAL(10,6),
    longitude DECIMAL(10,6),
    timezone VARCHAR(50) DEFAULT 'America/New_York',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_company_depot (company_id),
    INDEX idx_location (latitude, longitude)
) ENGINE=InnoDB;

-- ============================================================================
-- Vehicle Tables
-- ============================================================================

-- Vehicles/trucks
CREATE TABLE vehicles (
    vehicle_id INT PRIMARY KEY AUTO_INCREMENT,
    company_id INT NOT NULL,
    depot_id INT,
    vehicle_number VARCHAR(50) UNIQUE NOT NULL,
    vin VARCHAR(17) UNIQUE,
    license_plate VARCHAR(20) UNIQUE,
    vehicle_type ENUM('delivery_van', 'box_truck', 'semi_truck', 'refrigerated', 'flatbed', 'tanker') NOT NULL,
    make VARCHAR(50),
    model VARCHAR(50),
    year INT,
    color VARCHAR(30),
    fuel_type ENUM('gasoline', 'diesel', 'electric', 'hybrid', 'cng') DEFAULT 'diesel',
    fuel_capacity_gallons DECIMAL(6,2),
    odometer_miles DECIMAL(10,1),
    engine_hours DECIMAL(10,1),
    purchase_date DATE,
    registration_expiry DATE,
    insurance_expiry DATE,
    last_service_date DATE,
    last_service_miles DECIMAL(10,1),
    next_service_miles DECIMAL(10,1),
    status ENUM('active', 'maintenance', 'inactive', 'retired') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_company_vehicle (company_id),
    INDEX idx_depot_vehicle (depot_id),
    INDEX idx_vehicle_type (vehicle_type),
    INDEX idx_status (status)
) ENGINE=InnoDB;

-- Vehicle specifications
CREATE TABLE vehicle_specs (
    spec_id INT PRIMARY KEY AUTO_INCREMENT,
    vehicle_id INT NOT NULL UNIQUE,
    gross_vehicle_weight_lbs INT,
    cargo_capacity_lbs INT,
    cargo_volume_cubic_ft DECIMAL(10,2),
    mpg_city DECIMAL(5,2),
    mpg_highway DECIMAL(5,2),
    has_gps BOOLEAN DEFAULT TRUE,
    has_eld BOOLEAN DEFAULT TRUE,
    has_camera BOOLEAN DEFAULT FALSE,
    has_temperature_control BOOLEAN DEFAULT FALSE,
    has_liftgate BOOLEAN DEFAULT FALSE,
    INDEX idx_vehicle_spec (vehicle_id)
) ENGINE=InnoDB;

-- ============================================================================
-- Driver Tables
-- ============================================================================

-- Drivers
CREATE TABLE drivers (
    driver_id INT PRIMARY KEY AUTO_INCREMENT,
    company_id INT NOT NULL,
    employee_id VARCHAR(50) UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(200) UNIQUE,
    phone VARCHAR(20),
    license_number VARCHAR(50) UNIQUE NOT NULL,
    license_state VARCHAR(2),
    license_class ENUM('regular', 'CDL_A', 'CDL_B', 'CDL_C') NOT NULL,
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
    status ENUM('active', 'inactive', 'terminated', 'suspended') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_company_driver (company_id),
    INDEX idx_license (license_number),
    INDEX idx_status_driver (status)
) ENGINE=InnoDB;

-- Driver certifications and violations
CREATE TABLE driver_certifications (
    certification_id INT PRIMARY KEY AUTO_INCREMENT,
    driver_id INT NOT NULL,
    certification_type VARCHAR(100) NOT NULL,
    certification_number VARCHAR(50),
    issue_date DATE,
    expiry_date DATE,
    issuing_authority VARCHAR(100),
    INDEX idx_driver_cert (driver_id),
    INDEX idx_expiry (expiry_date)
) ENGINE=InnoDB;

-- ============================================================================
-- GPS and Telematics Tables
-- ============================================================================

-- GPS positions (partitioned by day for performance)
CREATE TABLE gps_positions (
    position_id BIGINT AUTO_INCREMENT,
    vehicle_id INT NOT NULL,
    driver_id INT,
    timestamp DATETIME NOT NULL,
    latitude DECIMAL(10,6) NOT NULL,
    longitude DECIMAL(10,6) NOT NULL,
    speed_mph DECIMAL(5,2),
    heading INT COMMENT 'Direction in degrees (0-359)',
    altitude_feet INT,
    satellites INT,
    hdop DECIMAL(4,2) COMMENT 'Horizontal dilution of precision',
    ignition_on BOOLEAN DEFAULT TRUE,
    odometer_miles DECIMAL(10,1),
    engine_hours DECIMAL(10,1),
    fuel_level_percent DECIMAL(5,2),
    PRIMARY KEY (position_id, timestamp),
    INDEX idx_vehicle_time (vehicle_id, timestamp),
    INDEX idx_driver_time (driver_id, timestamp),
    INDEX idx_timestamp (timestamp),
    INDEX idx_location (latitude, longitude)
) ENGINE=InnoDB
PARTITION BY RANGE (TO_DAYS(timestamp)) (
    PARTITION p202501 VALUES LESS THAN (TO_DAYS('2025-02-01')),
    PARTITION p202502 VALUES LESS THAN (TO_DAYS('2025-03-01')),
    PARTITION pmax VALUES LESS THAN MAXVALUE
);

-- Trips
CREATE TABLE trips (
    trip_id INT PRIMARY KEY AUTO_INCREMENT,
    vehicle_id INT NOT NULL,
    driver_id INT NOT NULL,
    start_time DATETIME NOT NULL,
    end_time DATETIME,
    start_location VARCHAR(200),
    start_latitude DECIMAL(10,6),
    start_longitude DECIMAL(10,6),
    end_location VARCHAR(200),
    end_latitude DECIMAL(10,6),
    end_longitude DECIMAL(10,6),
    distance_miles DECIMAL(10,2),
    duration_minutes INT,
    max_speed_mph DECIMAL(5,2),
    avg_speed_mph DECIMAL(5,2),
    fuel_consumed_gallons DECIMAL(8,2),
    idle_time_minutes INT,
    stops_count INT DEFAULT 0,
    harsh_events_count INT DEFAULT 0,
    status ENUM('in_progress', 'completed', 'cancelled') DEFAULT 'in_progress',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_vehicle_trip (vehicle_id, start_time),
    INDEX idx_driver_trip (driver_id, start_time),
    INDEX idx_trip_status (status),
    INDEX idx_trip_time (start_time, end_time)
) ENGINE=InnoDB;

-- Stops during trips
CREATE TABLE stops (
    stop_id INT PRIMARY KEY AUTO_INCREMENT,
    trip_id INT NOT NULL,
    stop_sequence INT NOT NULL,
    arrival_time DATETIME NOT NULL,
    departure_time DATETIME,
    latitude DECIMAL(10,6),
    longitude DECIMAL(10,6),
    address VARCHAR(200),
    stop_type ENUM('delivery', 'pickup', 'break', 'fuel', 'maintenance', 'other') DEFAULT 'delivery',
    duration_minutes INT,
    notes TEXT,
    INDEX idx_trip_stop (trip_id, stop_sequence),
    INDEX idx_stop_time (arrival_time)
) ENGINE=InnoDB;

-- ============================================================================
-- Driver Behavior Tables
-- ============================================================================

-- Driver events (harsh braking, acceleration, cornering, speeding)
CREATE TABLE driver_events (
    event_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    vehicle_id INT NOT NULL,
    driver_id INT NOT NULL,
    trip_id INT,
    event_type ENUM('harsh_brake', 'harsh_acceleration', 'harsh_cornering', 'speeding', 'idle_excessive', 'seatbelt_off') NOT NULL,
    timestamp DATETIME NOT NULL,
    latitude DECIMAL(10,6),
    longitude DECIMAL(10,6),
    speed_mph DECIMAL(5,2),
    g_force DECIMAL(4,2),
    speed_limit_mph INT,
    duration_seconds INT,
    severity ENUM('low', 'medium', 'high') DEFAULT 'medium',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_driver_event (driver_id, timestamp),
    INDEX idx_vehicle_event (vehicle_id, timestamp),
    INDEX idx_event_type (event_type, timestamp),
    INDEX idx_severity (severity)
) ENGINE=InnoDB;

-- Driver scores
CREATE TABLE driver_scores (
    score_id INT PRIMARY KEY AUTO_INCREMENT,
    driver_id INT NOT NULL,
    score_date DATE NOT NULL,
    safety_score DECIMAL(5,2) DEFAULT 100,
    fuel_efficiency_score DECIMAL(5,2) DEFAULT 100,
    compliance_score DECIMAL(5,2) DEFAULT 100,
    overall_score DECIMAL(5,2) DEFAULT 100,
    miles_driven DECIMAL(10,2),
    trips_count INT,
    harsh_events_count INT DEFAULT 0,
    speeding_minutes INT DEFAULT 0,
    idle_minutes INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_driver_date (driver_id, score_date),
    INDEX idx_driver_score (driver_id, score_date),
    INDEX idx_score_date (score_date)
) ENGINE=InnoDB;

-- ============================================================================
-- Routes and Geofencing Tables
-- ============================================================================

-- Planned routes
CREATE TABLE routes (
    route_id INT PRIMARY KEY AUTO_INCREMENT,
    route_name VARCHAR(100) NOT NULL,
    route_code VARCHAR(50) UNIQUE,
    depot_id INT,
    total_distance_miles DECIMAL(10,2),
    estimated_duration_minutes INT,
    waypoints JSON COMMENT 'Array of lat/lng coordinates',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_depot_route (depot_id),
    INDEX idx_active_routes (is_active)
) ENGINE=InnoDB;

-- Geofences
CREATE TABLE geofences (
    geofence_id INT PRIMARY KEY AUTO_INCREMENT,
    company_id INT NOT NULL,
    geofence_name VARCHAR(100) NOT NULL,
    geofence_type ENUM('depot', 'customer', 'restricted', 'rest_area') NOT NULL,
    center_latitude DECIMAL(10,6),
    center_longitude DECIMAL(10,6),
    radius_meters INT,
    polygon JSON COMMENT 'Array of lat/lng points for polygon fence',
    alert_on_entry BOOLEAN DEFAULT TRUE,
    alert_on_exit BOOLEAN DEFAULT TRUE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_company_geofence (company_id),
    INDEX idx_geofence_type (geofence_type),
    INDEX idx_active_geofences (is_active)
) ENGINE=InnoDB;

-- Geofence events
CREATE TABLE geofence_events (
    event_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    geofence_id INT NOT NULL,
    vehicle_id INT NOT NULL,
    driver_id INT,
    event_type ENUM('enter', 'exit') NOT NULL,
    timestamp DATETIME NOT NULL,
    duration_minutes INT COMMENT 'For exit events, time spent inside',
    INDEX idx_geofence_event (geofence_id, timestamp),
    INDEX idx_vehicle_geofence (vehicle_id, timestamp)
) ENGINE=InnoDB;

-- ============================================================================
-- Fuel Management Tables
-- ============================================================================

-- Fuel transactions
CREATE TABLE fuel_transactions (
    transaction_id INT PRIMARY KEY AUTO_INCREMENT,
    vehicle_id INT NOT NULL,
    driver_id INT,
    transaction_date DATETIME NOT NULL,
    station_name VARCHAR(100),
    station_address VARCHAR(200),
    latitude DECIMAL(10,6),
    longitude DECIMAL(10,6),
    gallons DECIMAL(8,2) NOT NULL,
    price_per_gallon DECIMAL(6,3),
    total_cost DECIMAL(10,2),
    odometer_miles DECIMAL(10,1),
    payment_method ENUM('fuel_card', 'credit_card', 'cash', 'account') DEFAULT 'fuel_card',
    receipt_number VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_vehicle_fuel (vehicle_id, transaction_date),
    INDEX idx_driver_fuel (driver_id, transaction_date),
    INDEX idx_fuel_date (transaction_date)
) ENGINE=InnoDB;

-- ============================================================================
-- Maintenance Tables
-- ============================================================================

-- Maintenance records
CREATE TABLE maintenance_records (
    maintenance_id INT PRIMARY KEY AUTO_INCREMENT,
    vehicle_id INT NOT NULL,
    maintenance_type ENUM('preventive', 'repair', 'inspection', 'recall') NOT NULL,
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
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_vehicle_maintenance (vehicle_id, service_date),
    INDEX idx_maintenance_type (maintenance_type),
    INDEX idx_next_service (next_service_date)
) ENGINE=InnoDB;

-- Vehicle diagnostics (OBD-II)
CREATE TABLE vehicle_diagnostics (
    diagnostic_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    vehicle_id INT NOT NULL,
    timestamp DATETIME NOT NULL,
    engine_rpm INT,
    engine_load_percent DECIMAL(5,2),
    coolant_temp_f INT,
    oil_pressure_psi DECIMAL(5,2),
    battery_voltage DECIMAL(4,2),
    check_engine_light BOOLEAN DEFAULT FALSE,
    dtc_codes JSON COMMENT 'Diagnostic trouble codes',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_vehicle_diag (vehicle_id, timestamp),
    INDEX idx_check_engine (check_engine_light, timestamp)
) ENGINE=InnoDB;

-- ============================================================================
-- Compliance Tables (HOS/ELD)
-- ============================================================================

-- Driver logs (Hours of Service)
CREATE TABLE driver_logs (
    log_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    driver_id INT NOT NULL,
    log_date DATE NOT NULL,
    duty_status ENUM('off_duty', 'sleeper', 'driving', 'on_duty', 'yard_move', 'personal_use') NOT NULL,
    start_time DATETIME NOT NULL,
    end_time DATETIME,
    duration_minutes INT,
    location VARCHAR(200),
    latitude DECIMAL(10,6),
    longitude DECIMAL(10,6),
    vehicle_id INT,
    odometer_start DECIMAL(10,1),
    odometer_end DECIMAL(10,1),
    notes TEXT,
    certified BOOLEAN DEFAULT FALSE,
    certified_at DATETIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_driver_log (driver_id, log_date),
    INDEX idx_log_date (log_date),
    INDEX idx_duty_status (duty_status),
    UNIQUE KEY uk_driver_log_time (driver_id, start_time)
) ENGINE=InnoDB;

-- HOS violations
CREATE TABLE hos_violations (
    violation_id INT PRIMARY KEY AUTO_INCREMENT,
    driver_id INT NOT NULL,
    violation_date DATE NOT NULL,
    violation_type ENUM('11_hour', '14_hour', '30_minute_break', '60_hour_7day', '70_hour_8day', 'other') NOT NULL,
    duration_minutes INT,
    description TEXT,
    severity ENUM('minor', 'major', 'critical') DEFAULT 'major',
    resolved BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_driver_violation (driver_id, violation_date),
    INDEX idx_violation_type (violation_type),
    INDEX idx_unresolved (resolved, violation_date)
) ENGINE=InnoDB;

-- DVIR (Driver Vehicle Inspection Reports)
CREATE TABLE dvir_reports (
    dvir_id INT PRIMARY KEY AUTO_INCREMENT,
    vehicle_id INT NOT NULL,
    driver_id INT NOT NULL,
    inspection_date DATE NOT NULL,
    inspection_type ENUM('pre_trip', 'post_trip') NOT NULL,
    odometer_miles DECIMAL(10,1),
    defects_found BOOLEAN DEFAULT FALSE,
    defect_details JSON,
    signature_driver VARCHAR(200),
    signature_mechanic VARCHAR(200),
    repaired BOOLEAN DEFAULT FALSE,
    repair_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_vehicle_dvir (vehicle_id, inspection_date),
    INDEX idx_driver_dvir (driver_id, inspection_date),
    INDEX idx_defects (defects_found, inspection_date),
    UNIQUE KEY uk_vehicle_inspection (vehicle_id, inspection_date, inspection_type)
) ENGINE=InnoDB;

-- ============================================================================
-- Communication Tables
-- ============================================================================

-- Messages between drivers and dispatch
CREATE TABLE messages (
    message_id INT PRIMARY KEY AUTO_INCREMENT,
    sender_type ENUM('driver', 'dispatcher', 'system') NOT NULL,
    sender_id INT,
    recipient_type ENUM('driver', 'dispatcher', 'broadcast') NOT NULL,
    recipient_id INT,
    message_text TEXT NOT NULL,
    priority ENUM('low', 'normal', 'high', 'urgent') DEFAULT 'normal',
    read_status BOOLEAN DEFAULT FALSE,
    sent_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    read_at DATETIME,
    INDEX idx_recipient (recipient_type, recipient_id, sent_at),
    INDEX idx_unread (read_status, recipient_id)
) ENGINE=InnoDB;

-- ============================================================================
-- Analytics Summary Tables
-- ============================================================================

-- Daily vehicle summary (for faster reporting)
CREATE TABLE vehicle_daily_summary (
    summary_id INT PRIMARY KEY AUTO_INCREMENT,
    vehicle_id INT NOT NULL,
    summary_date DATE NOT NULL,
    total_miles DECIMAL(10,2),
    total_hours DECIMAL(10,2),
    total_trips INT,
    total_stops INT,
    total_fuel_gallons DECIMAL(10,2),
    avg_mpg DECIMAL(5,2),
    total_idle_minutes INT,
    harsh_events_count INT,
    max_speed_mph DECIMAL(5,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_vehicle_date (vehicle_id, summary_date),
    INDEX idx_summary_date (summary_date)
) ENGINE=InnoDB;