-- PostgreSQL Schema
-- Converted from MySQL on 2026-02-17T23:11:17.343457
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

-- Indexes
