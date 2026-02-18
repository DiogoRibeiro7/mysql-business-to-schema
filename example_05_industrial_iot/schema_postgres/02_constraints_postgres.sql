-- PostgreSQL Schema
-- Converted from MySQL on 2026-02-17T23:11:17.344056
-- Generator: MySQL to PostgreSQL Converter

-- Enum Types
CREATE TYPE factories_status AS ENUM ('automotive', 'electronics', 'consumer_goods', 'pharmaceutical', 'food');
CREATE TYPE production_lines_status AS ENUM ('operational', 'maintenance', 'idle', 'decommissioned');
CREATE TYPE machines_status AS ENUM ('running', 'idle', 'maintenance', 'error', 'offline');
CREATE TYPE sensors_status AS ENUM ('temperature', 'vibration', 'pressure', 'humidity', 'current', 'voltage', 'speed', 'flow', 'position', 'force', 'acoustic');
CREATE TYPE sensor_readings_status AS ENUM ('good', 'uncertain', 'bad');
CREATE TYPE work_orders_status AS ENUM ('planned', 'in_progress', 'completed', 'cancelled', 'on_hold');
CREATE TYPE quality_inspections_status AS ENUM ('pass', 'fail', 'conditional');
CREATE TYPE defects_status AS ENUM ('critical', 'major', 'minor', 'cosmetic');
CREATE TYPE maintenance_schedules_status AS ENUM ('preventive', 'predictive', 'corrective', 'calibration');
CREATE TYPE maintenance_records_status AS ENUM ('scheduled', 'in_progress', 'completed', 'cancelled');
CREATE TYPE alerts_status AS ENUM ('critical', 'high', 'medium', 'low', 'info');
CREATE TYPE downtime_events_status AS ENUM ('line_stop', 'reduced_speed', 'quality_impact');
CREATE TYPE operators_status AS ENUM ('trainee', 'operator', 'senior', 'supervisor');
CREATE TYPE shift_logs_status AS ENUM ('morning', 'afternoon', 'night');

DROP DATABASE IF EXISTS industrial_iot;
-- Create database (run as superuser)
-- CREATE DATABASE industrial_iot;
-- \c industrial_iot

DELIMITER $$
CREATE PROCEDURE create_monthly_partitions(
IN table_name VARCHAR(64),
IN months_ahead INT
)
BEGIN
DECLARE i INT DEFAULT 0;
DECLARE partition_date DATE;
DECLARE partition_name VARCHAR(64);
DECLARE sql_text TEXT;
WHILE i < months_ahead DO
SET partition_date = DATE_ADD(CURDATE(), INTERVAL i MONTH);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
END WHILE;
END$$
DELIMITER ;
CREATE USER IF NOT EXISTS 'factory_operator'@'%' IDENTIFIED BY 'operator_pass_2024';
GRANT SELECT ON industrial_iot.* TO 'factory_operator'@'%';
CREATE USER IF NOT EXISTS 'production_manager'@'%' IDENTIFIED BY 'manager_pass_2024';
GRANT SELECT, INSERT, UPDATE ON industrial_iot.* TO 'production_manager'@'%';
CREATE USER IF NOT EXISTS 'maintenance_engineer'@'%' IDENTIFIED BY 'maintenance_pass_2024';
GRANT ALL PRIVILEGES ON industrial_iot.* TO 'maintenance_engineer'@'%';
CREATE USER IF NOT EXISTS 'data_analyst'@'%' IDENTIFIED BY 'analyst_pass_2024';
GRANT SELECT ON industrial_iot.* TO 'data_analyst'@'%';
FLUSH PRIVILEGES;
CREATE TABLE IF NOT EXISTS factories (
    factory_name VARCHAR(100) NOT NULL,
    factory_type factories_status NOT NULL,
    location VARCHAR(100) NOT NULL,
    country VARCHAR(50) NOT NULL,
    timezone VARCHAR(50) DEFAULT 'UTC',
    established_date DATE,
    total_area_sqm DECIMAL(10,2),
    employee_count INTEGER,
    shifts_per_day INTEGER DEFAULT 2,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS production_lines (
    factory_id INTEGER NOT NULL,
    line_name VARCHAR(100) NOT NULL,
    line_type production_lines_status NOT NULL,
    capacity_per_hour INTEGER,
    product_types JSONB,
    installation_date DATE,
    last_maintenance_date DATE,
    status production_lines_status DEFAULT 'operational',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS machines (
    line_id INTEGER NOT NULL,
    machine_name VARCHAR(100) NOT NULL,
    machine_type machines_status NOT NULL,
    manufacturer VARCHAR(100),
    model VARCHAR(100),
    serial_number VARCHAR(100),
    installation_date DATE,
    warranty_expiry DATE,
    ideal_cycle_time_seconds DECIMAL(10,2),
    max_capacity_per_hour INTEGER,
    power_consumption_kw DECIMAL(10,2),
    status machines_status DEFAULT 'idle',
    total_operating_hours DECIMAL(12,2) DEFAULT 0,
    total_cycle_count BIGINT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sensors (
    machine_id INTEGER NOT NULL,
    sensor_type sensors_status NOT NULL,
    unit_of_measure VARCHAR(20) NOT NULL,
    min_value DECIMAL(12,4),
    max_value DECIMAL(12,4),
    normal_min DECIMAL(12,4),
    normal_max DECIMAL(12,4),
    critical_min DECIMAL(12,4),
    critical_max DECIMAL(12,4),
    sampling_rate_seconds INTEGER DEFAULT 60,
    calibration_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sensor_readings (
    reading_id BIGSERIAL,
    sensor_id INTEGER NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    value DECIMAL(12,4) NOT NULL,
    quality sensor_readings_status DEFAULT 'good',
    PRIMARY KEY (reading_id, timestamp),
    PARTITION TEXT VALUES LESS THAN (TO_DAYS('2025-03-01')),
    PARTITION TEXT VALUES LESS THAN (TO_DAYS('2025-04-01')),
    PARTITION TEXT VALUES LESS THAN MAXVALUE
);

CREATE TABLE IF NOT EXISTS products (
    product_name VARCHAR(200) NOT NULL,
    product_category VARCHAR(100),
    unit_of_measure VARCHAR(20) DEFAULT 'unit',
    standard_cycle_time_seconds DECIMAL(10,2),
    weight_kg DECIMAL(10,3),
    quality_specs JSONB,
    bom JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS work_orders (
    product_id INTEGER NOT NULL,
    line_id INTEGER NOT NULL,
    planned_quantity INTEGER NOT NULL,
    planned_start_time TIMESTAMP NOT NULL,
    planned_end_time TIMESTAMP NOT NULL,
    actual_start_time TIMESTAMP,
    actual_end_time TIMESTAMP,
    produced_quantity INTEGER DEFAULT 0,
    good_quantity INTEGER DEFAULT 0,
    rejected_quantity INTEGER DEFAULT 0,
    status work_orders_status DEFAULT 'planned',
    priority INTEGER DEFAULT 5 COMMENT '1=highest,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS production_runs (
    order_id INTEGER NOT NULL,
    machine_id INTEGER NOT NULL,
    operator_id INTEGER,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    quantity_produced INTEGER DEFAULT 0,
    quantity_good INTEGER DEFAULT 0,
    quantity_rejected INTEGER DEFAULT 0,
    cycle_time_actual DECIMAL(10,2),
    downtime_minutes DECIMAL(10,2) DEFAULT 0,
    speed_percentage DECIMAL(5,2) DEFAULT 100,
    notes TEXT
);

CREATE TABLE IF NOT EXISTS quality_inspections (
    run_id BIGINT NOT NULL,
    product_id INTEGER NOT NULL,
    inspection_time TIMESTAMP NOT NULL,
    inspector_id INTEGER,
    sample_size INTEGER,
    defects_found INTEGER DEFAULT 0,
    defect_types JSONB,
    measurements JSONB,
    pass_fail quality_inspections_status NOT NULL,
    notes TEXT
);

CREATE TABLE IF NOT EXISTS defects (
    inspection_id INTEGER NOT NULL,
    defect_type VARCHAR(100) NOT NULL,
    severity defects_status NOT NULL,
    quantity INTEGER DEFAULT 1,
    root_cause VARCHAR(200),
    corrective_action TEXT,
    image_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS oee_metrics (
    machine_id INTEGER NOT NULL,
    line_id INTEGER NOT NULL,
    metric_timestamp TIMESTAMP NOT NULL,
    hour_start TIMESTAMP NOT NULL,
    hour_end TIMESTAMP NOT NULL,
    planned_production_time_min DECIMAL(10,2),
    operating_time_min DECIMAL(10,2),
    downtime_min DECIMAL(10,2),
    availability_percentage DECIMAL(5,2),
    ideal_cycle_time_sec DECIMAL(10,2),
    total_pieces_produced INTEGER,
    performance_percentage DECIMAL(5,2),
    good_pieces INTEGER,
    total_pieces INTEGER,
    quality_percentage DECIMAL(5,2),
    oee_percentage DECIMAL(5,2),
    UNIQUE (machine_id, hour_start)
);

CREATE TABLE IF NOT EXISTS maintenance_schedules (
    machine_id INTEGER NOT NULL,
    maintenance_type maintenance_schedules_status NOT NULL,
    frequency_days INTEGER,
    last_performed DATE,
    next_due DATE,
    estimated_duration_hours DECIMAL(5,2),
    parts_required JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS maintenance_records (
    machine_id INTEGER NOT NULL,
    schedule_id INTEGER,
    maintenance_type maintenance_records_status NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    technician_id INTEGER,
    downtime_minutes DECIMAL(10,2),
    parts_replaced JSONB,
    cost DECIMAL(10,2),
    findings TEXT,
    actions_taken TEXT,
    next_action TEXT,
    status maintenance_records_status DEFAULT 'scheduled',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS alerts (
    source_type alerts_status NOT NULL,
    source_id INTEGER NOT NULL,
    alert_type VARCHAR(100) NOT NULL,
    severity alerts_status NOT NULL,
    message TEXT NOT NULL,
    threshold_value DECIMAL(12,4),
    actual_value DECIMAL(12,4),
    triggered_at TIMESTAMP NOT NULL,
    acknowledged_at TIMESTAMP,
    acknowledged_by INTEGER,
    resolved_at TIMESTAMP,
    resolved_by INTEGER,
    resolution_notes TEXT
);

CREATE TABLE IF NOT EXISTS downtime_events (
    machine_id INTEGER NOT NULL,
    line_id INTEGER NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    duration_minutes DECIMAL(10,2),
    reason_category downtime_events_status NOT NULL,
    reason_detail VARCHAR(500),
    impact_level downtime_events_status DEFAULT 'line_stop',
    lost_production_units INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS operators (
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    shift operators_status NOT NULL,
    skill_level operators_status NOT NULL,
    certifications JSONB,
    factory_id INTEGER NOT NULL,
    hire_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS shift_logs (
    shift_date DATE NOT NULL,
    shift_type shift_logs_status NOT NULL,
    line_id INTEGER NOT NULL,
    supervisor_id INTEGER,
    operators_count INTEGER,
    production_target INTEGER,
    production_actual INTEGER,
    oee_target DECIMAL(5,2),
    oee_actual DECIMAL(5,2),
    safety_incidents INTEGER DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (line_id, shift_date, shift_type)
);

ALTER TABLE production_lines
ADD CONSTRAINT fk_line_factory
FOREIGN KEY (factory_id) REFERENCES factories(factory_id)
ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE machines
ADD CONSTRAINT fk_machine_line
FOREIGN KEY (line_id) REFERENCES production_lines(line_id)
ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE sensors
ADD CONSTRAINT fk_sensor_machine
FOREIGN KEY (machine_id) REFERENCES machines(machine_id)
ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE work_orders
ADD CONSTRAINT fk_order_product
FOREIGN KEY (product_id) REFERENCES products(product_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_order_line
FOREIGN KEY (line_id) REFERENCES production_lines(line_id)
ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE production_runs
ADD CONSTRAINT fk_run_order
FOREIGN KEY (order_id) REFERENCES work_orders(order_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_run_machine
FOREIGN KEY (machine_id) REFERENCES machines(machine_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_run_operator
FOREIGN KEY (operator_id) REFERENCES operators(operator_id)
ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE quality_inspections
ADD CONSTRAINT fk_inspection_run
FOREIGN KEY (run_id) REFERENCES production_runs(run_id)
ON DELETE CASCADE ON UPDATE CASCADE,
ADD CONSTRAINT fk_inspection_product
FOREIGN KEY (product_id) REFERENCES products(product_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_inspection_inspector
FOREIGN KEY (inspector_id) REFERENCES operators(operator_id)
ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE defects
ADD CONSTRAINT fk_defect_inspection
FOREIGN KEY (inspection_id) REFERENCES quality_inspections(inspection_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE oee_metrics
ADD CONSTRAINT fk_oee_machine
FOREIGN KEY (machine_id) REFERENCES machines(machine_id)
ON DELETE CASCADE ON UPDATE CASCADE,
ADD CONSTRAINT fk_oee_line
FOREIGN KEY (line_id) REFERENCES production_lines(line_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE maintenance_schedules
ADD CONSTRAINT fk_schedule_machine
FOREIGN KEY (machine_id) REFERENCES machines(machine_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE maintenance_records
ADD CONSTRAINT fk_maintenance_machine
FOREIGN KEY (machine_id) REFERENCES machines(machine_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_maintenance_schedule
FOREIGN KEY (schedule_id) REFERENCES maintenance_schedules(schedule_id)
ON DELETE SET NULL ON UPDATE CASCADE,
ADD CONSTRAINT fk_maintenance_technician
FOREIGN KEY (technician_id) REFERENCES operators(operator_id)
ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE downtime_events
ADD CONSTRAINT fk_downtime_machine
FOREIGN KEY (machine_id) REFERENCES machines(machine_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_downtime_line
FOREIGN KEY (line_id) REFERENCES production_lines(line_id)
ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE operators
ADD CONSTRAINT fk_operator_factory
FOREIGN KEY (factory_id) REFERENCES factories(factory_id)
ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE shift_logs
ADD CONSTRAINT fk_shift_line
FOREIGN KEY (line_id) REFERENCES production_lines(line_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_shift_supervisor
FOREIGN KEY (supervisor_id) REFERENCES operators(operator_id)
ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE work_orders
ADD CONSTRAINT chk_order_quantities
CHECK (planned_quantity > 0 AND produced_quantity >= 0
AND good_quantity >= 0 AND rejected_quantity >= 0);
ALTER TABLE work_orders
ADD CONSTRAINT chk_order_times
CHECK (planned_end_time > planned_start_time);
ALTER TABLE production_runs
ADD CONSTRAINT chk_run_times
CHECK (end_time IS NULL OR end_time > start_time);
ALTER TABLE maintenance_records
ADD CONSTRAINT chk_maintenance_times
CHECK (end_time IS NULL OR end_time > start_time);
ALTER TABLE downtime_events
ADD CONSTRAINT chk_downtime_times
CHECK (end_time IS NULL OR end_time > start_time);
ALTER TABLE sensors
ADD CONSTRAINT chk_sensor_ranges
CHECK (min_value <= max_value
AND critical_min <= normal_min
AND normal_max <= critical_max
AND normal_min <= normal_max);
ALTER TABLE oee_metrics
ADD CONSTRAINT chk_oee_percentages
CHECK (availability_percentage BETWEEN 0 AND 100
AND performance_percentage BETWEEN 0 AND 100
AND quality_percentage BETWEEN 0 AND 100
AND oee_percentage BETWEEN 0 AND 100);
ALTER TABLE production_runs
ADD CONSTRAINT chk_run_quantities
CHECK (quantity_produced = quantity_good + quantity_rejected);
ALTER TABLE factories
ADD CONSTRAINT chk_factory_shifts
CHECK (shifts_per_day BETWEEN 1 AND 4);
ALTER TABLE work_orders
ADD CONSTRAINT chk_order_priority
CHECK (priority BETWEEN 1 AND 10);
DELIMITER $$
CREATE TRIGGER trg_update_machine_status_on_run
AFTER INSERT ON production_runs
FOR EACH ROW
BEGIN
IF NEW.end_time IS NULL THEN
UPDATE machines
SET status = 'running'
WHERE machine_id = NEW.machine_id;
END IF;
END$$
CREATE TRIGGER trg_complete_production_run
AFTER UPDATE ON production_runs
FOR EACH ROW
BEGIN
IF OLD.end_time IS NULL AND NEW.end_time IS NOT NULL THEN
UPDATE machines
SET status = 'idle',
total_operating_hours = total_operating_hours +
TIMESTAMPDIFF(SECOND, NEW.start_time, NEW.end_time) / 3600,
total_cycle_count = total_cycle_count + NEW.quantity_produced
WHERE machine_id = NEW.machine_id;
END IF;
END$$
CREATE TRIGGER trg_calculate_oee
BEFORE INSERT ON oee_metrics
FOR EACH ROW
BEGIN
SET NEW.oee_percentage = (NEW.availability_percentage / 100) *
(NEW.performance_percentage / 100) *
(NEW.quality_percentage / 100) * 100;
END$$
CREATE TRIGGER trg_update_oee
BEFORE UPDATE ON oee_metrics
FOR EACH ROW
BEGIN
SET NEW.oee_percentage = (NEW.availability_percentage / 100) *
(NEW.performance_percentage / 100) *
(NEW.quality_percentage / 100) * 100;
END$$
CREATE TRIGGER trg_update_work_order_from_run
AFTER UPDATE ON production_runs
FOR EACH ROW
BEGIN
IF NEW.end_time IS NOT NULL THEN
UPDATE work_orders
SET produced_quantity = produced_quantity + NEW.quantity_produced,
good_quantity = good_quantity + NEW.quantity_good,
rejected_quantity = rejected_quantity + NEW.quantity_rejected
WHERE order_id = NEW.order_id;
END IF;
END$$
CREATE TRIGGER trg_complete_work_order
AFTER UPDATE ON work_orders
FOR EACH ROW
BEGIN
IF NEW.produced_quantity >= NEW.planned_quantity
AND OLD.status IN ('planned', 'in_progress') THEN
UPDATE work_orders
SET status = 'completed',
actual_end_time = NOW()
WHERE order_id = NEW.order_id;
END IF;
END$$
CREATE TRIGGER trg_sensor_alert
AFTER INSERT ON sensor_readings
FOR EACH ROW
BEGIN
DECLARE v_sensor_type VARCHAR(50);
DECLARE v_critical_min DECIMAL(12,4);
DECLARE v_critical_max DECIMAL(12,4);
DECLARE v_machine_id INT;
SELECT s.sensor_type, s.critical_min, s.critical_max, s.machine_id
INTO v_sensor_type, v_critical_min, v_critical_max, v_machine_id
FROM sensors s
WHERE s.sensor_id = NEW.sensor_id;
IF NEW.value < v_critical_min OR NEW.value > v_critical_max THEN
INSERT INTO alerts (source_type, source_id, alert_type, severity,
message, threshold_value, actual_value, triggered_at)
VALUES ('sensor', NEW.sensor_id,
CONCAT(v_sensor_type, '_critical'),
'high',
CONCAT('Sensor ', NEW.sensor_id, ' reading critical: ', NEW.value),
CASE WHEN NEW.value < v_critical_min THEN v_critical_min ELSE v_critical_max END,
NEW.value,
NEW.timestamp);
END IF;
END$$
CREATE TRIGGER trg_calculate_downtime
BEFORE UPDATE ON downtime_events
FOR EACH ROW
BEGIN
IF NEW.end_time IS NOT NULL AND OLD.end_time IS NULL THEN
SET NEW.duration_minutes = TIMESTAMPDIFF(MINUTE, NEW.start_time, NEW.end_time);
END IF;
END$$
CREATE TRIGGER trg_update_maintenance_schedule
AFTER UPDATE ON maintenance_records
FOR EACH ROW
BEGIN
IF NEW.status = 'completed' AND NEW.schedule_id IS NOT NULL THEN
UPDATE maintenance_schedules
SET last_performed = DATE(NEW.end_time),
next_due = DATE_ADD(DATE(NEW.end_time), INTERVAL frequency_days DAY)
WHERE schedule_id = NEW.schedule_id;
END IF;
END$$
DELIMITER ;
ALTER TABLE sensors
ADD CONSTRAINT uk_machine_sensor_code
UNIQUE KEY (machine_id, sensor_code);
ALTER TABLE maintenance_schedules
ADD CONSTRAINT uk_machine_maintenance_type
UNIQUE KEY (machine_id, maintenance_type, is_active);
ALTER TABLE production_runs
ALTER COLUMN end_time SET DEFAULT NULL;
ALTER TABLE maintenance_records
ALTER COLUMN end_time SET DEFAULT NULL;
ALTER TABLE downtime_events
ALTER COLUMN end_time SET DEFAULT NULL;
-- Indexes
