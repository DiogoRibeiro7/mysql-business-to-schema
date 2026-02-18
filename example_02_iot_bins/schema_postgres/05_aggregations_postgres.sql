-- PostgreSQL Schema
-- Converted from MySQL on 2026-02-17T23:11:17.328019
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
DROP TABLE IF EXISTS sensor_readings;
CREATE TABLE IF NOT EXISTS sensor_readings (
    reading_id BIGSERIAL,
    sensor_id INTEGER NOT NULL,
    reading_time TIMESTAMP NOT NULL,
    reading_value DECIMAL(10, 3) NOT NULL,
    unit VARCHAR(20) NOT NULL,
    quality sensor_readings_status DEFAULT 'good',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (reading_id, reading_time),
    PARTITION TEXT VALUES LESS THAN (UNIX_TIMESTAMP('2024-12-01 00:00:00')),
    PARTITION TEXT VALUES LESS THAN (UNIX_TIMESTAMP('2025-01-01 00:00:00')),
    PARTITION TEXT VALUES LESS THAN (UNIX_TIMESTAMP('2025-02-01 00:00:00')),
    PARTITION TEXT VALUES LESS THAN (UNIX_TIMESTAMP('2025-03-01 00:00:00')),
    PARTITION TEXT VALUES LESS THAN (UNIX_TIMESTAMP('2025-04-01 00:00:00')),
    PARTITION TEXT VALUES LESS THAN (UNIX_TIMESTAMP('2025-05-01 00:00:00')),
    PARTITION TEXT VALUES LESS THAN (UNIX_TIMESTAMP('2025-06-01 00:00:00')),
    PARTITION TEXT VALUES LESS THAN (UNIX_TIMESTAMP('2025-07-01 00:00:00')),
    PARTITION TEXT VALUES LESS THAN (UNIX_TIMESTAMP('2025-08-01 00:00:00')),
    PARTITION TEXT VALUES LESS THAN (UNIX_TIMESTAMP('2025-09-01 00:00:00')),
    PARTITION TEXT VALUES LESS THAN (UNIX_TIMESTAMP('2025-10-01 00:00:00')),
    PARTITION TEXT VALUES LESS THAN (UNIX_TIMESTAMP('2025-11-01 00:00:00')),
    PARTITION TEXT VALUES LESS THAN (UNIX_TIMESTAMP('2025-12-01 00:00:00')),
    PARTITION TEXT VALUES LESS THAN (UNIX_TIMESTAMP('2026-01-01 00:00:00')),
    PARTITION TEXT VALUES LESS THAN (UNIX_TIMESTAMP('2026-02-01 00:00:00')),
    PARTITION TEXT VALUES LESS THAN (UNIX_TIMESTAMP('2026-03-01 00:00:00')),
    PARTITION TEXT VALUES LESS THAN (UNIX_TIMESTAMP('2026-04-01 00:00:00')),
    PARTITION TEXT VALUES LESS THAN (UNIX_TIMESTAMP('2026-05-01 00:00:00')),
    PARTITION TEXT VALUES LESS THAN (UNIX_TIMESTAMP('2026-06-01 00:00:00')),
    PARTITION TEXT VALUES LESS THAN (UNIX_TIMESTAMP('2026-07-01 00:00:00')),
    PARTITION TEXT VALUES LESS THAN MAXVALUE
);

ALTER TABLE sensor_readings
ADD CONSTRAINT fk_readings_sensor
FOREIGN KEY (sensor_id) REFERENCES sensors(sensor_id)
ON DELETE CASCADE ON UPDATE CASCADE;
DROP TABLE IF EXISTS collection_events;
CREATE TABLE IF NOT EXISTS collection_events (
    event_id SERIAL,
    bin_id INTEGER NOT NULL,
    schedule_id INTEGER,
    truck_id INTEGER NOT NULL,
    driver_id INTEGER NOT NULL,
    collected_at TIMESTAMP NOT NULL,
    fill_level_before DECIMAL(5, 2),
    weight_kg DECIMAL(10, 2),
    collection_duration_seconds INTEGER,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (event_id, collected_at),
    PARTITION TEXT VALUES LESS THAN (UNIX_TIMESTAMP('2025-04-01 00:00:00')),
    PARTITION TEXT VALUES LESS THAN (UNIX_TIMESTAMP('2025-07-01 00:00:00')),
    PARTITION TEXT VALUES LESS THAN (UNIX_TIMESTAMP('2025-10-01 00:00:00')),
    PARTITION TEXT VALUES LESS THAN (UNIX_TIMESTAMP('2026-01-01 00:00:00')),
    PARTITION TEXT VALUES LESS THAN (UNIX_TIMESTAMP('2026-04-01 00:00:00')),
    PARTITION TEXT VALUES LESS THAN (UNIX_TIMESTAMP('2026-07-01 00:00:00')),
    PARTITION TEXT VALUES LESS THAN MAXVALUE
);

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
ALTER TABLE collection_events
ADD CONSTRAINT chk_event_fill_level CHECK (fill_level_before BETWEEN 0 AND 100),
ADD CONSTRAINT chk_event_weight CHECK (weight_kg >= 0),
ADD CONSTRAINT chk_event_duration CHECK (collection_duration_seconds >= 0);
DROP TABLE IF EXISTS alerts;
CREATE TABLE IF NOT EXISTS alerts (
    alert_id BIGSERIAL,
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
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (alert_id, triggered_at),
    PARTITION TEXT VALUES LESS THAN (UNIX_TIMESTAMP('2025-02-01 00:00:00')),
    PARTITION TEXT VALUES LESS THAN (UNIX_TIMESTAMP('2025-03-01 00:00:00')),
    PARTITION TEXT VALUES LESS THAN (UNIX_TIMESTAMP('2025-04-01 00:00:00')),
    PARTITION TEXT VALUES LESS THAN (UNIX_TIMESTAMP('2025-05-01 00:00:00')),
    PARTITION TEXT VALUES LESS THAN (UNIX_TIMESTAMP('2025-06-01 00:00:00')),
    PARTITION TEXT VALUES LESS THAN (UNIX_TIMESTAMP('2025-07-01 00:00:00')),
    PARTITION TEXT VALUES LESS THAN MAXVALUE
);

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
DELIMITER //
CREATE PROCEDURE add_sensor_reading_partition(
IN partition_date DATE
)
BEGIN
DECLARE partition_name VARCHAR(20);
DECLARE next_date DATE;
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
SELECT CONCAT('Partition ', partition_name, ' created successfully') AS Result;
END//
CREATE PROCEDURE drop_old_partition(
IN table_name VARCHAR(64),
IN partition_to_drop VARCHAR(64)
)
BEGIN
SET @sql = CONCAT(
'ALTER TABLE ', table_name, ' ',
'DROP PARTITION ', partition_to_drop
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
SELECT CONCAT('Partition ', partition_to_drop, ' dropped from ', table_name) AS Result;
END//
CREATE PROCEDURE show_partition_info(
IN table_name VARCHAR(64)
)
BEGIN
SELECT
partition_name,
partition_ordinal_position,
partition_method,
partition_expression,
partition_description,
table_rows,
avg_row_length,
data_length / 1024 / 1024 AS data_mb,
index_length / 1024 / 1024 AS index_mb
FROM information_schema.partitions
WHERE table_schema = 'iot_bins'
AND table_name = table_name
AND partition_name IS NOT NULL
ORDER BY partition_ordinal_position;
END//
DELIMITER ;
CALL show_partition_info('sensor_readings');
SELECT 'Partitioning implemented successfully' AS Status;
CREATE OR REPLACE VIEW v_current_bin_status AS
SELECT
b.bin_id,
b.bin_code,
b.bin_type,
b.district_id,
d.name AS district_name,
b.latitude,
b.longitude,
b.address,
b.capacity_liters,
b.status AS bin_status,
(
SELECT sr.reading_value
FROM sensor_readings sr
INNER JOIN sensors s ON sr.sensor_id = s.sensor_id
WHERE s.bin_id = b.bin_id
AND s.sensor_type = 'fill_level'
AND s.status = 'active'
ORDER BY sr.reading_time DESC
LIMIT 1
) AS current_fill_percentage,
(
SELECT sr.reading_value
FROM sensor_readings sr
INNER JOIN sensors s ON sr.sensor_id = s.sensor_id
WHERE s.bin_id = b.bin_id
AND s.sensor_type = 'temperature'
AND s.status = 'active'
ORDER BY sr.reading_time DESC
LIMIT 1
) AS current_temperature,
(
SELECT s.battery_level
FROM sensors s
WHERE s.bin_id = b.bin_id
AND s.sensor_type = 'battery'
AND s.status = 'active'
ORDER BY s.last_reading_time DESC
LIMIT 1
) AS battery_level,
(
SELECT collected_at
FROM collection_events
WHERE bin_id = b.bin_id
ORDER BY collected_at DESC
LIMIT 1
) AS last_collected_at,
(
SELECT COUNT(*)
FROM alerts
WHERE bin_id = b.bin_id
AND resolved_at IS NULL
) AS active_alert_count
FROM bins b
INNER JOIN districts d ON b.district_id = d.district_id
WHERE b.status = 'active';
CREATE OR REPLACE VIEW v_sensor_health AS
SELECT
s.sensor_id,
s.sensor_code,
s.sensor_type,
b.bin_code,
b.district_id,
s.status,
s.battery_level,
s.last_reading_time,
TIMESTAMPDIFF(MINUTE, s.last_reading_time, NOW()) AS minutes_since_last_reading,
CASE
WHEN s.status != 'active' THEN 'Inactive'
WHEN TIMESTAMPDIFF(MINUTE, s.last_reading_time, NOW()) > 60 THEN 'No Recent Data'
WHEN s.battery_level < 10 THEN 'Critical Battery'
WHEN s.battery_level < 20 THEN 'Low Battery'
ELSE 'Healthy'
END AS health_status
FROM sensors s
INNER JOIN bins b ON s.bin_id = b.bin_id;
CREATE OR REPLACE VIEW v_district_statistics AS
SELECT
d.district_id,
d.district_code,
d.name AS district_name,
d.area_km2,
COUNT(DISTINCT b.bin_id) AS total_bins,
COUNT(DISTINCT CASE WHEN b.status = 'active' THEN b.bin_id END) AS active_bins,
SUM(b.capacity_liters) / 1000 AS total_capacity_m3,
COUNT(DISTINCT s.sensor_id) AS total_sensors,
COUNT(DISTINCT CASE WHEN s.status = 'active' THEN s.sensor_id END) AS active_sensors,
AVG(
SELECT AVG(sr.reading_value)
FROM sensor_readings sr
INNER JOIN sensors sen ON sr.sensor_id = sen.sensor_id
WHERE sen.bin_id = b.bin_id
AND sen.sensor_type = 'fill_level'
AND sr.reading_time >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
) AS avg_fill_level_24h
FROM districts d
LEFT JOIN bins b ON d.district_id = b.district_id
LEFT JOIN sensors s ON b.bin_id = s.bin_id
GROUP BY d.district_id;
CREATE OR REPLACE VIEW v_collection_performance AS
SELECT
DATE(ce.collected_at) AS collection_date,
d.driver_id,
CONCAT(d.first_name, ' ', d.last_name) AS driver_name,
t.truck_code,
COUNT(DISTINCT ce.bin_id) AS bins_collected,
SUM(ce.weight_kg) AS total_weight_kg,
AVG(ce.collection_duration_seconds) AS avg_collection_seconds,
AVG(ce.fill_level_before) AS avg_fill_level,
COUNT(DISTINCT cs.route_id) AS routes_completed
FROM collection_events ce
INNER JOIN drivers d ON ce.driver_id = d.driver_id
INNER JOIN trucks t ON ce.truck_id = t.truck_id
LEFT JOIN collection_schedules cs ON ce.schedule_id = cs.schedule_id
WHERE ce.collected_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY DATE(ce.collected_at), d.driver_id, t.truck_id;
CREATE OR REPLACE VIEW v_daily_fill_trends AS
SELECT
srd.date,
b.district_id,
b.bin_type,
COUNT(DISTINCT b.bin_id) AS bin_count,
AVG(srd.avg_value) AS avg_fill_rate,
MAX(srd.max_value) AS max_fill_rate,
MIN(srd.min_value) AS min_fill_rate,
AVG(srd.peak_value) AS avg_peak_value,
AVG(srd.quality_good_pct) AS avg_quality_good_pct
FROM sensor_readings_daily srd
INNER JOIN sensors s ON srd.sensor_id = s.sensor_id
INNER JOIN bins b ON s.bin_id = b.bin_id
WHERE s.sensor_type = 'fill_level'
GROUP BY srd.date, b.district_id, b.bin_type;
CREATE OR REPLACE VIEW v_urgent_collections AS
SELECT
b.bin_id,
b.bin_code,
b.district_id,
b.latitude,
b.longitude,
b.address,
b.bin_type,
cbs.current_fill_percentage,
cbs.last_collected_at,
TIMESTAMPDIFF(HOUR, cbs.last_collected_at, NOW()) AS hours_since_collection,
rba.route_id,
cr.route_code,
CASE
WHEN cbs.current_fill_percentage >= 90 THEN 'Critical'
WHEN cbs.current_fill_percentage >= 80 THEN 'High'
WHEN cbs.current_fill_percentage >= 70 THEN 'Medium'
ELSE 'Low'
END AS urgency_level,
(
SELECT AVG(
(srd2.avg_value - srd1.avg_value) / 24
)
FROM sensor_readings_daily srd1
INNER JOIN sensor_readings_daily srd2
ON srd1.sensor_id = srd2.sensor_id
AND srd2.date = DATE_ADD(srd1.date, INTERVAL 1 DAY)
INNER JOIN sensors s ON srd1.sensor_id = s.sensor_id
WHERE s.bin_id = b.bin_id
AND s.sensor_type = 'fill_level'
AND srd1.date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
) AS avg_fill_rate_per_hour
FROM bins b
INNER JOIN v_current_bin_status cbs ON b.bin_id = cbs.bin_id
LEFT JOIN route_bin_assignments rba ON b.bin_id = rba.bin_id
LEFT JOIN collection_routes cr ON rba.route_id = cr.route_id
WHERE b.status = 'active'
AND cbs.current_fill_percentage >= 70
ORDER BY cbs.current_fill_percentage DESC;
CREATE OR REPLACE VIEW v_route_efficiency AS
SELECT
cr.route_id,
cr.route_code,
cr.route_name,
d.name AS district_name,
COUNT(DISTINCT rba.bin_id) AS total_bins,
cr.estimated_duration_minutes,
cr.estimated_distance_km,
(
SELECT AVG(ce.fill_level_before)
FROM collection_events ce
INNER JOIN route_bin_assignments rba2 ON ce.bin_id = rba2.bin_id
WHERE rba2.route_id = cr.route_id
AND ce.collected_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
) AS avg_fill_on_collection,
(
SELECT COUNT(DISTINCT DATE(ce.collected_at))
FROM collection_events ce
INNER JOIN route_bin_assignments rba2 ON ce.bin_id = rba2.bin_id
WHERE rba2.route_id = cr.route_id
AND ce.collected_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
) AS collections_last_30_days
FROM collection_routes cr
INNER JOIN districts d ON cr.district_id = d.district_id
LEFT JOIN route_bin_assignments rba ON cr.route_id = rba.route_id
WHERE cr.active = TRUE
GROUP BY cr.route_id;
CREATE OR REPLACE VIEW v_active_alerts_summary AS
SELECT
a.alert_type,
a.severity,
COUNT(*) AS alert_count,
COUNT(DISTINCT a.bin_id) AS affected_bins,
MIN(a.triggered_at) AS oldest_alert,
MAX(a.triggered_at) AS newest_alert,
AVG(TIMESTAMPDIFF(HOUR, a.triggered_at, NOW())) AS avg_age_hours,
SUM(CASE WHEN a.acknowledged = FALSE THEN 1 ELSE 0 END) AS unacknowledged_count
FROM alerts a
WHERE a.resolved_at IS NULL
GROUP BY a.alert_type, a.severity
ORDER BY
FIELD(a.severity, 'emergency', 'critical', 'warning', 'info'),
alert_count DESC;
CREATE OR REPLACE VIEW v_alert_patterns AS
SELECT
DATE(a.triggered_at) AS alert_date,
HOUR(a.triggered_at) AS alert_hour,
a.alert_type,
COUNT(*) AS alert_count,
COUNT(DISTINCT a.bin_id) AS bins_affected,
AVG(TIMESTAMPDIFF(MINUTE, a.triggered_at, a.resolved_at)) AS avg_resolution_minutes
FROM alerts a
WHERE a.triggered_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY DATE(a.triggered_at), HOUR(a.triggered_at), a.alert_type;
CREATE OR REPLACE VIEW v_fill_rate_acceleration AS
SELECT
b.bin_id,
b.bin_code,
b.district_id,
(
SELECT AVG(srd.avg_value)
FROM sensor_readings_daily srd
INNER JOIN sensors s ON srd.sensor_id = s.sensor_id
WHERE s.bin_id = b.bin_id
AND s.sensor_type = 'fill_level'
AND srd.date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
) AS current_week_avg,
(
SELECT AVG(srd.avg_value)
FROM sensor_readings_daily srd
INNER JOIN sensors s ON srd.sensor_id = s.sensor_id
WHERE s.bin_id = b.bin_id
AND s.sensor_type = 'fill_level'
AND srd.date >= DATE_SUB(CURDATE(), INTERVAL 14 DAY)
AND srd.date < DATE_SUB(CURDATE(), INTERVAL 7 DAY)
) AS previous_week_avg,
(
(
SELECT AVG(srd.avg_value)
FROM sensor_readings_daily srd
INNER JOIN sensors s ON srd.sensor_id = s.sensor_id
WHERE s.bin_id = b.bin_id
AND s.sensor_type = 'fill_level'
AND srd.date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
) -
(
SELECT AVG(srd.avg_value)
FROM sensor_readings_daily srd
INNER JOIN sensors s ON srd.sensor_id = s.sensor_id
WHERE s.bin_id = b.bin_id
AND s.sensor_type = 'fill_level'
AND srd.date >= DATE_SUB(CURDATE(), INTERVAL 14 DAY)
AND srd.date < DATE_SUB(CURDATE(), INTERVAL 7 DAY)
)
) AS fill_rate_change
FROM bins b
WHERE b.status = 'active'
HAVING current_week_avg IS NOT NULL AND previous_week_avg IS NOT NULL
ORDER BY fill_rate_change DESC;
SELECT 'All aggregation views created successfully' AS Status;
-- Indexes
