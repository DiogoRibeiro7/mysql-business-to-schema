-- PostgreSQL Schema
-- Converted from MySQL on 2026-02-17T23:11:17.325816
-- Generator: MySQL to PostgreSQL Converter

-- Enum Types
CREATE TYPE bins_status AS ENUM ('active', 'maintenance', 'damaged', 'decommissioned');
CREATE TYPE sensors_status AS ENUM ('active', 'offline', 'maintenance', 'faulty', 'decommissioned');
CREATE TYPE collection_routes_status AS ENUM ('regular', 'express', 'emergency', 'special');
CREATE TYPE trucks_status AS ENUM ('available', 'in_use', 'maintenance', 'repair', 'decommissioned');
CREATE TYPE drivers_status AS ENUM ('active', 'on_leave', 'sick', 'terminated');
CREATE TYPE collection_schedules_status AS ENUM ('scheduled', 'in_progress', 'completed', 'cancelled', 'delayed');
CREATE TYPE sensor_readings_status AS ENUM ('good', 'warning', 'error');
CREATE TYPE alert_thresholds_status AS ENUM ('fill_level', 'temperature', 'odor', 'battery', 'weight', 'tilt');
CREATE TYPE alerts_status AS ENUM ('info', 'warning', 'critical', 'emergency');

DROP DATABASE IF EXISTS iot_bins;
-- Create database (run as superuser)
-- CREATE DATABASE iot_bins;
-- \c iot_bins

SELECT 'Database iot_bins created successfully' AS Status;
CREATE TABLE IF NOT EXISTS districts (
    name VARCHAR(100) NOT NULL,
    area_km2 DECIMAL(10, 2) NOT NULL,
    population INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS bins (
    district_id INTEGER NOT NULL,
    bin_type bins_status NOT NULL DEFAULT 'general',
    capacity_liters INTEGER NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    address VARCHAR(255),
    location_type bins_status DEFAULT 'public',
    installation_date DATE NOT NULL,
    last_maintenance_date DATE,
    status bins_status DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sensors (
    bin_id INTEGER NOT NULL,
    sensor_type sensors_status NOT NULL,
    manufacturer VARCHAR(100),
    model VARCHAR(100),
    firmware_version VARCHAR(20),
    installation_date DATE NOT NULL,
    reading_frequency_seconds INTEGER NOT NULL DEFAULT 300,
    status sensors_status DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS collection_routes (
    district_id INTEGER NOT NULL,
    route_name VARCHAR(100),
    route_type collection_routes_status DEFAULT 'regular',
    estimated_duration_minutes INTEGER,
    estimated_distance_km DECIMAL(10, 2),
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS route_bin_assignments (
    route_id INTEGER NOT NULL,
    bin_id INTEGER NOT NULL,
    collection_order INTEGER NOT NULL,
    estimated_collection_time TIME,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (route_id, bin_id)
);

CREATE TABLE IF NOT EXISTS trucks (
    manufacturer VARCHAR(100),
    model VARCHAR(100),
    year INTEGER,
    capacity_kg INTEGER NOT NULL,
    fuel_type trucks_status DEFAULT 'diesel',
    last_maintenance_date DATE,
    next_maintenance_date DATE,
    odometer_km INTEGER,
    status trucks_status DEFAULT 'available',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS drivers (
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    license_expiry_date DATE NOT NULL,
    hire_date DATE NOT NULL,
    status drivers_status DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS collection_schedules (
    route_id INTEGER NOT NULL,
    truck_id INTEGER NOT NULL,
    driver_id INTEGER NOT NULL,
    scheduled_date DATE NOT NULL,
    scheduled_start_time TIME NOT NULL,
    scheduled_end_time TIME NOT NULL,
    status collection_schedules_status DEFAULT 'scheduled',
    actual_start_time TIMESTAMP NULL,
    actual_end_time TIMESTAMP NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS collection_events (
    bin_id INTEGER NOT NULL,
    schedule_id INTEGER,
    truck_id INTEGER NOT NULL,
    driver_id INTEGER NOT NULL,
    collected_at TIMESTAMP NOT NULL,
    fill_level_before DECIMAL(5, 2),
    collection_duration_seconds INTEGER,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sensor_readings (
    sensor_id INTEGER NOT NULL,
    reading_time TIMESTAMP NOT NULL,
    reading_value DECIMAL(10, 3) NOT NULL,
    unit VARCHAR(20) NOT NULL,
    quality sensor_readings_status DEFAULT 'good',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sensor_readings_hourly (
    sensor_id INTEGER NOT NULL,
    hour_start TIMESTAMP NOT NULL,
    min_value DECIMAL(10, 3),
    max_value DECIMAL(10, 3),
    avg_value DECIMAL(10, 3),
    reading_count INTEGER,
    quality_good_count INTEGER,
    quality_warning_count INTEGER,
    quality_error_count INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (sensor_id, hour_start)
);

CREATE TABLE IF NOT EXISTS sensor_readings_daily (
    sensor_id INTEGER NOT NULL,
    date DATE NOT NULL,
    min_value DECIMAL(10, 3),
    max_value DECIMAL(10, 3),
    avg_value DECIMAL(10, 3),
    peak_hour TIME,
    peak_value DECIMAL(10, 3),
    reading_count INTEGER,
    quality_good_pct DECIMAL(5, 2),
    quality_warning_pct DECIMAL(5, 2),
    quality_error_pct DECIMAL(5, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (sensor_id, date)
);

CREATE TABLE IF NOT EXISTS alert_thresholds (
    name VARCHAR(100) NOT NULL,
    bin_type alert_thresholds_status DEFAULT 'all',
    sensor_type alert_thresholds_status NOT NULL,
    warning_value DECIMAL(10, 3),
    critical_value DECIMAL(10, 3),
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS alerts (
    bin_id INTEGER NOT NULL,
    sensor_id INTEGER,
    threshold_id INTEGER,
    alert_type alerts_status NOT NULL,
    severity alerts_status NOT NULL,
    triggered_at TIMESTAMP NOT NULL,
    resolved_at TIMESTAMP NULL,
    alert_value DECIMAL(10, 3),
    message TEXT,
    acknowledged BOOLEAN DEFAULT FALSE,
    acknowledged_by VARCHAR(100),
    acknowledged_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS fill_rate_predictions (
    bin_id INTEGER NOT NULL,
    prediction_date DATE NOT NULL,
    prediction_hour TIME NOT NULL,
    predicted_fill_rate DECIMAL(5, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (bin_id, prediction_date, prediction_hour)
);

SELECT 'All tables created successfully' AS Status;
ALTER TABLE bins
ADD CONSTRAINT fk_bins_district
FOREIGN KEY (district_id) REFERENCES districts(district_id)
ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE sensors
ADD CONSTRAINT fk_sensors_bin
FOREIGN KEY (bin_id) REFERENCES bins(bin_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE collection_routes
ADD CONSTRAINT fk_routes_district
FOREIGN KEY (district_id) REFERENCES districts(district_id)
ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE route_bin_assignments
ADD CONSTRAINT fk_assignment_route
FOREIGN KEY (route_id) REFERENCES collection_routes(route_id)
ON DELETE CASCADE ON UPDATE CASCADE,
ADD CONSTRAINT fk_assignment_bin
FOREIGN KEY (bin_id) REFERENCES bins(bin_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE collection_schedules
ADD CONSTRAINT fk_schedule_route
FOREIGN KEY (route_id) REFERENCES collection_routes(route_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_schedule_truck
FOREIGN KEY (truck_id) REFERENCES trucks(truck_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_schedule_driver
FOREIGN KEY (driver_id) REFERENCES drivers(driver_id)
ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE collection_events
ADD CONSTRAINT fk_event_bin
FOREIGN KEY (bin_id) REFERENCES bins(bin_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_event_schedule
FOREIGN KEY (schedule_id) REFERENCES collection_schedules(schedule_id)
ON DELETE SET NULL ON UPDATE CASCADE,
ADD CONSTRAINT fk_event_truck
FOREIGN KEY (truck_id) REFERENCES trucks(truck_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_event_driver
FOREIGN KEY (driver_id) REFERENCES drivers(driver_id)
ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE sensor_readings
ADD CONSTRAINT fk_readings_sensor
FOREIGN KEY (sensor_id) REFERENCES sensors(sensor_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE sensor_readings_hourly
ADD CONSTRAINT fk_hourly_sensor
FOREIGN KEY (sensor_id) REFERENCES sensors(sensor_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE sensor_readings_daily
ADD CONSTRAINT fk_daily_sensor
FOREIGN KEY (sensor_id) REFERENCES sensors(sensor_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE alerts
ADD CONSTRAINT fk_alerts_bin
FOREIGN KEY (bin_id) REFERENCES bins(bin_id)
ON DELETE CASCADE ON UPDATE CASCADE,
ADD CONSTRAINT fk_alerts_sensor
FOREIGN KEY (sensor_id) REFERENCES sensors(sensor_id)
ON DELETE SET NULL ON UPDATE CASCADE,
ADD CONSTRAINT fk_alerts_threshold
FOREIGN KEY (threshold_id) REFERENCES alert_thresholds(threshold_id)
ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE fill_rate_predictions
ADD CONSTRAINT fk_predictions_bin
FOREIGN KEY (bin_id) REFERENCES bins(bin_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE districts
ADD CONSTRAINT chk_district_area CHECK (area_km2 > 0),
ADD CONSTRAINT chk_district_population CHECK (population >= 0);
ALTER TABLE bins
ADD CONSTRAINT chk_bin_capacity CHECK (capacity_liters > 0),
ADD CONSTRAINT chk_bin_latitude CHECK (latitude BETWEEN -90 AND 90),
ADD CONSTRAINT chk_bin_longitude CHECK (longitude BETWEEN -180 AND 180);
ALTER TABLE sensors
ADD CONSTRAINT chk_sensor_frequency CHECK (reading_frequency_seconds > 0),
ADD CONSTRAINT chk_sensor_battery CHECK (battery_level BETWEEN 0 AND 100);
ALTER TABLE collection_routes
ADD CONSTRAINT chk_route_duration CHECK (estimated_duration_minutes > 0),
ADD CONSTRAINT chk_route_distance CHECK (estimated_distance_km > 0);
ALTER TABLE route_bin_assignments
ADD CONSTRAINT chk_assignment_order CHECK (collection_order > 0);
ALTER TABLE trucks
ADD CONSTRAINT chk_truck_capacity CHECK (capacity_kg > 0),
ADD CONSTRAINT chk_truck_year CHECK (year >= 1990 AND year <= YEAR(CURDATE()) + 1),
ADD CONSTRAINT chk_truck_odometer CHECK (odometer_km >= 0);
ALTER TABLE drivers
ADD CONSTRAINT chk_driver_license_expiry CHECK (license_expiry_date > hire_date);
ALTER TABLE collection_schedules
ADD CONSTRAINT chk_schedule_times CHECK (scheduled_end_time > scheduled_start_time);
ALTER TABLE collection_events
ADD CONSTRAINT chk_event_fill_level CHECK (fill_level_before BETWEEN 0 AND 100),
ADD CONSTRAINT chk_event_weight CHECK (weight_kg >= 0),
ADD CONSTRAINT chk_event_duration CHECK (collection_duration_seconds >= 0);
ALTER TABLE sensor_readings_hourly
ADD CONSTRAINT chk_hourly_counts CHECK (reading_count > 0);
ALTER TABLE sensor_readings_daily
ADD CONSTRAINT chk_daily_counts CHECK (reading_count > 0),
ADD CONSTRAINT chk_daily_quality_pct CHECK (
quality_good_pct >= 0 AND quality_good_pct <= 100 AND
quality_warning_pct >= 0 AND quality_warning_pct <= 100 AND
quality_error_pct >= 0 AND quality_error_pct <= 100
);
ALTER TABLE alert_thresholds
ADD CONSTRAINT chk_threshold_values CHECK (critical_value >= warning_value OR critical_value IS NULL OR warning_value IS NULL),
ADD CONSTRAINT chk_threshold_interval CHECK (check_interval_seconds > 0);
ALTER TABLE fill_rate_predictions
ADD CONSTRAINT chk_prediction_fill_rate CHECK (predicted_fill_rate BETWEEN 0 AND 100),
ADD CONSTRAINT chk_prediction_confidence CHECK (confidence_score BETWEEN 0 AND 100);
SELECT 'All constraints created successfully' AS Status;
ALTER TABLE bins
ADD INDEX idx_district_type_status (district_id, bin_type, status);
ALTER TABLE bins
ADD SPATIAL INDEX idx_spatial_location (latitude, longitude);
ALTER TABLE sensors
ADD INDEX idx_bin_type_status (bin_id, sensor_type, status);
ALTER TABLE sensors
ADD INDEX idx_status_last_reading (status, last_reading_time);
ALTER TABLE sensor_readings
ADD INDEX idx_sensor_time_quality (sensor_id, reading_time, quality);
ALTER TABLE sensor_readings
ADD INDEX idx_time_sensor (reading_time, sensor_id);
ALTER TABLE collection_events
ADD INDEX idx_bin_collected_fill (bin_id, collected_at, fill_level_before);
ALTER TABLE collection_events
ADD INDEX idx_date_truck_driver (collected_at, truck_id, driver_id);
ALTER TABLE alerts
ADD INDEX idx_bin_resolved_severity (bin_id, resolved_at, severity);
ALTER TABLE alerts
ADD INDEX idx_severity_triggered (severity, triggered_at, resolved_at);
ALTER TABLE alerts
ADD INDEX idx_acknowledged_severity (acknowledged, severity, triggered_at);
ALTER TABLE collection_schedules
ADD INDEX idx_date_status_route (scheduled_date, status, route_id);
ALTER TABLE collection_schedules
ADD INDEX idx_driver_date_status (driver_id, scheduled_date, status);
ALTER TABLE route_bin_assignments
ADD INDEX idx_route_order_bin (route_id, collection_order, bin_id);
ALTER TABLE bins
ADD INDEX idx_covering_dashboard (
status,
bin_type,
district_id,
capacity_liters,
latitude,
longitude
);
ALTER TABLE sensors
ADD INDEX idx_covering_battery (
sensor_type,
status,
battery_level,
last_reading_time,
bin_id
);
ALTER TABLE sensor_readings_hourly
ADD INDEX idx_covering_hourly_analysis (
sensor_id,
hour_start,
avg_value,
min_value,
max_value,
reading_count
);
ALTER TABLE collection_events
ADD INDEX idx_covering_performance (
driver_id,
collected_at,
collection_duration_seconds,
weight_kg
);
ALTER TABLE sensor_readings
ADD INDEX idx_hour_aggregation (
sensor_id,
DATE(reading_time),
HOUR(reading_time)
);
ALTER TABLE sensor_readings_daily
ADD INDEX idx_month_aggregation (
sensor_id,
YEAR(date),
MONTH(date)
);
ALTER TABLE collection_events
ADD INDEX idx_collection_stats (
bin_id,
YEAR(collected_at),
MONTH(collected_at)
);
ALTER TABLE bins
ADD FULLTEXT INDEX ft_address (address);
ALTER TABLE collection_events
ADD FULLTEXT INDEX ft_notes (notes);
ALTER TABLE alerts
ADD FULLTEXT INDEX ft_message (message);
CREATE OR REPLACE VIEW v_index_usage_stats AS
SELECT
table_name,
index_name,
cardinality,
ROUND((data_length + index_length) / 1024 / 1024, 2) AS size_mb
FROM information_schema.statistics
WHERE table_schema = 'iot_bins'
AND index_name != 'PRIMARY'
GROUP BY table_name, index_name
ORDER BY table_name, index_name;
SELECT 'All indexes created successfully' AS Status;
SELECT
CONCAT('Created ', COUNT(DISTINCT index_name), ' indexes across ',
COUNT(DISTINCT table_name), ' tables') AS Summary
FROM information_schema.statistics
WHERE table_schema = 'iot_bins'
AND index_name != 'PRIMARY';
-- Indexes
