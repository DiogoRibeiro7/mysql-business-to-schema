-- ============================================================================
-- IoT Garbage Bin Monitoring System - Core Tables
-- ============================================================================
-- Description: Creates core tables for IoT bin monitoring system
-- Dependencies: 00_create_database.sql must be run first
-- ============================================================================

USE iot_bins;

-- ============================================================================
-- Infrastructure Tables
-- ============================================================================

-- Districts - City districts for organizing collection routes
CREATE TABLE IF NOT EXISTS districts (
    district_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    district_code VARCHAR(10) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    area_km2 DECIMAL(10, 2) NOT NULL,
    population INT UNSIGNED,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_district_code (district_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bins - Physical garbage bin locations and metadata
CREATE TABLE IF NOT EXISTS bins (
    bin_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    bin_code VARCHAR(20) UNIQUE NOT NULL,
    district_id INT UNSIGNED NOT NULL,
    bin_type ENUM('general', 'recycling', 'organic', 'hazardous', 'paper', 'glass', 'plastic') NOT NULL DEFAULT 'general',
    capacity_liters INT UNSIGNED NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    address VARCHAR(255),
    location_type ENUM('residential', 'commercial', 'industrial', 'park', 'school', 'hospital', 'public') DEFAULT 'public',
    installation_date DATE NOT NULL,
    last_maintenance_date DATE,
    status ENUM('active', 'maintenance', 'damaged', 'decommissioned') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_district (district_id),
    INDEX idx_bin_type (bin_type),
    INDEX idx_status (status),
    INDEX idx_location (latitude, longitude),
    INDEX idx_bin_code (bin_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Sensors - IoT sensors attached to bins
CREATE TABLE IF NOT EXISTS sensors (
    sensor_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    sensor_code VARCHAR(30) UNIQUE NOT NULL,
    bin_id INT UNSIGNED NOT NULL,
    sensor_type ENUM('fill_level', 'temperature', 'odor', 'battery', 'weight', 'tilt') NOT NULL,
    manufacturer VARCHAR(100),
    model VARCHAR(100),
    firmware_version VARCHAR(20),
    installation_date DATE NOT NULL,
    reading_frequency_seconds INT UNSIGNED NOT NULL DEFAULT 300, -- Default 5 minutes
    battery_level DECIMAL(5, 2), -- Percentage
    last_reading_time TIMESTAMP NULL,
    status ENUM('active', 'offline', 'maintenance', 'faulty', 'decommissioned') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_bin (bin_id),
    INDEX idx_sensor_type (sensor_type),
    INDEX idx_status (status),
    INDEX idx_last_reading (last_reading_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- Collection Management Tables
-- ============================================================================

-- Collection Routes - Predefined collection routes
CREATE TABLE IF NOT EXISTS collection_routes (
    route_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    route_code VARCHAR(20) UNIQUE NOT NULL,
    district_id INT UNSIGNED NOT NULL,
    route_name VARCHAR(100),
    route_type ENUM('regular', 'express', 'emergency', 'special') DEFAULT 'regular',
    estimated_duration_minutes INT UNSIGNED,
    estimated_distance_km DECIMAL(10, 2),
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_district (district_id),
    INDEX idx_route_type (route_type),
    INDEX idx_active (active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Route Bin Assignments - Which bins belong to which routes
CREATE TABLE IF NOT EXISTS route_bin_assignments (
    assignment_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    route_id INT UNSIGNED NOT NULL,
    bin_id INT UNSIGNED NOT NULL,
    collection_order INT UNSIGNED NOT NULL,
    estimated_collection_time TIME,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unique_route_bin (route_id, bin_id),
    INDEX idx_route (route_id),
    INDEX idx_bin (bin_id),
    INDEX idx_order (route_id, collection_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Trucks - Collection vehicles
CREATE TABLE IF NOT EXISTS trucks (
    truck_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    truck_code VARCHAR(20) UNIQUE NOT NULL,
    license_plate VARCHAR(20) UNIQUE NOT NULL,
    manufacturer VARCHAR(100),
    model VARCHAR(100),
    year INT UNSIGNED,
    capacity_kg INT UNSIGNED NOT NULL,
    fuel_type ENUM('diesel', 'electric', 'hybrid', 'cng') DEFAULT 'diesel',
    last_maintenance_date DATE,
    next_maintenance_date DATE,
    odometer_km INT UNSIGNED,
    status ENUM('available', 'in_use', 'maintenance', 'repair', 'decommissioned') DEFAULT 'available',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_status (status),
    INDEX idx_truck_code (truck_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Drivers - Collection crew
CREATE TABLE IF NOT EXISTS drivers (
    driver_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    employee_id VARCHAR(20) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE,
    phone VARCHAR(20),
    license_number VARCHAR(50) UNIQUE NOT NULL,
    license_expiry_date DATE NOT NULL,
    hire_date DATE NOT NULL,
    status ENUM('active', 'on_leave', 'sick', 'terminated') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_employee_id (employee_id),
    INDEX idx_status (status),
    INDEX idx_name (last_name, first_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Collection Schedules - Planned collections
CREATE TABLE IF NOT EXISTS collection_schedules (
    schedule_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    route_id INT UNSIGNED NOT NULL,
    truck_id INT UNSIGNED NOT NULL,
    driver_id INT UNSIGNED NOT NULL,
    scheduled_date DATE NOT NULL,
    scheduled_start_time TIME NOT NULL,
    scheduled_end_time TIME NOT NULL,
    status ENUM('scheduled', 'in_progress', 'completed', 'cancelled', 'delayed') DEFAULT 'scheduled',
    actual_start_time TIMESTAMP NULL,
    actual_end_time TIMESTAMP NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_route (route_id),
    INDEX idx_truck (truck_id),
    INDEX idx_driver (driver_id),
    INDEX idx_date (scheduled_date),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Collection Events - Actual collection records
CREATE TABLE IF NOT EXISTS collection_events (
    event_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    bin_id INT UNSIGNED NOT NULL,
    schedule_id INT UNSIGNED,
    truck_id INT UNSIGNED NOT NULL,
    driver_id INT UNSIGNED NOT NULL,
    collected_at TIMESTAMP NOT NULL,
    fill_level_before DECIMAL(5, 2), -- Percentage
    weight_kg DECIMAL(10, 2),
    collection_duration_seconds INT UNSIGNED,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_bin (bin_id),
    INDEX idx_schedule (schedule_id),
    INDEX idx_truck (truck_id),
    INDEX idx_driver (driver_id),
    INDEX idx_collected_at (collected_at),
    INDEX idx_bin_date (bin_id, collected_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- Time Series Tables
-- ============================================================================

-- Sensor Readings - Raw sensor data (will be partitioned)
CREATE TABLE IF NOT EXISTS sensor_readings (
    reading_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    sensor_id INT UNSIGNED NOT NULL,
    reading_time TIMESTAMP NOT NULL,
    reading_value DECIMAL(10, 3) NOT NULL,
    unit VARCHAR(20) NOT NULL,
    quality ENUM('good', 'warning', 'error') DEFAULT 'good',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_sensor_time (sensor_id, reading_time),
    INDEX idx_reading_time (reading_time),
    INDEX idx_quality (quality)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Sensor Readings Hourly - Hourly aggregates
CREATE TABLE IF NOT EXISTS sensor_readings_hourly (
    aggregation_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    sensor_id INT UNSIGNED NOT NULL,
    hour_start TIMESTAMP NOT NULL,
    min_value DECIMAL(10, 3),
    max_value DECIMAL(10, 3),
    avg_value DECIMAL(10, 3),
    reading_count INT UNSIGNED,
    quality_good_count INT UNSIGNED,
    quality_warning_count INT UNSIGNED,
    quality_error_count INT UNSIGNED,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_sensor_hour (sensor_id, hour_start),
    INDEX idx_hour_start (hour_start),
    INDEX idx_sensor_hour (sensor_id, hour_start)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Sensor Readings Daily - Daily aggregates
CREATE TABLE IF NOT EXISTS sensor_readings_daily (
    aggregation_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    sensor_id INT UNSIGNED NOT NULL,
    date DATE NOT NULL,
    min_value DECIMAL(10, 3),
    max_value DECIMAL(10, 3),
    avg_value DECIMAL(10, 3),
    peak_hour TIME,
    peak_value DECIMAL(10, 3),
    reading_count INT UNSIGNED,
    quality_good_pct DECIMAL(5, 2),
    quality_warning_pct DECIMAL(5, 2),
    quality_error_pct DECIMAL(5, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_sensor_date (sensor_id, date),
    INDEX idx_date (date),
    INDEX idx_sensor_date (sensor_id, date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- Alert System Tables
-- ============================================================================

-- Alert Thresholds - Configurable alert rules
CREATE TABLE IF NOT EXISTS alert_thresholds (
    threshold_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    bin_type ENUM('general', 'recycling', 'organic', 'hazardous', 'paper', 'glass', 'plastic', 'all') DEFAULT 'all',
    sensor_type ENUM('fill_level', 'temperature', 'odor', 'battery', 'weight', 'tilt') NOT NULL,
    warning_value DECIMAL(10, 3),
    critical_value DECIMAL(10, 3),
    check_interval_seconds INT UNSIGNED DEFAULT 300,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_active (active),
    INDEX idx_bin_sensor_type (bin_type, sensor_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Alerts - System-generated alerts
CREATE TABLE IF NOT EXISTS alerts (
    alert_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    bin_id INT UNSIGNED NOT NULL,
    sensor_id INT UNSIGNED,
    threshold_id INT UNSIGNED,
    alert_type ENUM('fill_critical', 'fill_warning', 'temperature_high', 'temperature_low',
                    'odor_high', 'battery_low', 'sensor_offline', 'tilt_detected',
                    'collection_overdue', 'maintenance_required') NOT NULL,
    severity ENUM('info', 'warning', 'critical', 'emergency') NOT NULL,
    triggered_at TIMESTAMP NOT NULL,
    resolved_at TIMESTAMP NULL,
    alert_value DECIMAL(10, 3),
    message TEXT,
    acknowledged BOOLEAN DEFAULT FALSE,
    acknowledged_by VARCHAR(100),
    acknowledged_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_bin (bin_id),
    INDEX idx_sensor (sensor_id),
    INDEX idx_triggered_at (triggered_at),
    INDEX idx_severity (severity),
    INDEX idx_resolved (resolved_at),
    INDEX idx_bin_unresolved (bin_id, resolved_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- Predictive Analytics Tables
-- ============================================================================

-- Fill Rate Predictions - ML model predictions
CREATE TABLE IF NOT EXISTS fill_rate_predictions (
    prediction_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    bin_id INT UNSIGNED NOT NULL,
    prediction_date DATE NOT NULL,
    prediction_hour TIME NOT NULL,
    predicted_fill_rate DECIMAL(5, 2) NOT NULL, -- Percentage
    confidence_score DECIMAL(5, 2), -- Percentage
    model_version VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_bin_date_hour (bin_id, prediction_date, prediction_hour),
    INDEX idx_bin_date (bin_id, prediction_date),
    INDEX idx_date (prediction_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Display confirmation
SELECT 'All tables created successfully' AS Status;