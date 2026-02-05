-- ============================================================================
-- Industrial IoT Manufacturing Tables
-- ============================================================================

USE industrial_iot;

-- ============================================================================
-- Factory Infrastructure Tables
-- ============================================================================

-- Factories table
CREATE TABLE factories (
    factory_id INT PRIMARY KEY AUTO_INCREMENT,
    factory_name VARCHAR(100) NOT NULL,
    factory_type ENUM('automotive', 'electronics', 'consumer_goods', 'pharmaceutical', 'food') NOT NULL,
    location VARCHAR(100) NOT NULL,
    country VARCHAR(50) NOT NULL,
    timezone VARCHAR(50) DEFAULT 'UTC',
    established_date DATE,
    total_area_sqm DECIMAL(10,2),
    employee_count INT,
    shifts_per_day INT DEFAULT 2,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_factory_type (factory_type),
    INDEX idx_active (is_active)
) ENGINE=InnoDB;

-- Production lines
CREATE TABLE production_lines (
    line_id INT PRIMARY KEY AUTO_INCREMENT,
    factory_id INT NOT NULL,
    line_name VARCHAR(100) NOT NULL,
    line_type ENUM('assembly', 'packaging', 'processing', 'testing', 'mixed') NOT NULL,
    capacity_per_hour INT,
    product_types JSON COMMENT 'Array of product types this line can handle',
    installation_date DATE,
    last_maintenance_date DATE,
    status ENUM('operational', 'maintenance', 'idle', 'decommissioned') DEFAULT 'operational',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_factory_line (factory_id),
    INDEX idx_line_status (status)
) ENGINE=InnoDB;

-- Machines
CREATE TABLE machines (
    machine_id INT PRIMARY KEY AUTO_INCREMENT,
    line_id INT NOT NULL,
    machine_code VARCHAR(50) UNIQUE NOT NULL,
    machine_name VARCHAR(100) NOT NULL,
    machine_type ENUM('cnc_mill', 'injection_mold', 'assembly_robot', 'conveyor',
                      'packaging', 'quality_inspection', 'welding_robot', '3d_printer', 'other') NOT NULL,
    manufacturer VARCHAR(100),
    model VARCHAR(100),
    serial_number VARCHAR(100),
    installation_date DATE,
    warranty_expiry DATE,
    ideal_cycle_time_seconds DECIMAL(10,2),
    max_capacity_per_hour INT,
    power_consumption_kw DECIMAL(10,2),
    status ENUM('running', 'idle', 'maintenance', 'error', 'offline') DEFAULT 'idle',
    total_operating_hours DECIMAL(12,2) DEFAULT 0,
    total_cycle_count BIGINT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_line_machine (line_id),
    INDEX idx_machine_type (machine_type),
    INDEX idx_machine_status (status)
) ENGINE=InnoDB;

-- ============================================================================
-- Sensor and IoT Tables
-- ============================================================================

-- Sensors
CREATE TABLE sensors (
    sensor_id INT PRIMARY KEY AUTO_INCREMENT,
    machine_id INT NOT NULL,
    sensor_code VARCHAR(50) UNIQUE NOT NULL,
    sensor_type ENUM('temperature', 'vibration', 'pressure', 'humidity', 'current',
                     'voltage', 'speed', 'flow', 'position', 'force', 'acoustic') NOT NULL,
    unit_of_measure VARCHAR(20) NOT NULL,
    min_value DECIMAL(12,4),
    max_value DECIMAL(12,4),
    normal_min DECIMAL(12,4),
    normal_max DECIMAL(12,4),
    critical_min DECIMAL(12,4),
    critical_max DECIMAL(12,4),
    sampling_rate_seconds INT DEFAULT 60,
    calibration_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_machine_sensor (machine_id),
    INDEX idx_sensor_type (sensor_type),
    INDEX idx_active_sensors (is_active)
) ENGINE=InnoDB;

-- Sensor readings (partitioned by month)
CREATE TABLE sensor_readings (
    reading_id BIGINT AUTO_INCREMENT,
    sensor_id INT NOT NULL,
    timestamp DATETIME NOT NULL,
    value DECIMAL(12,4) NOT NULL,
    quality ENUM('good', 'uncertain', 'bad') DEFAULT 'good',
    PRIMARY KEY (reading_id, timestamp),
    INDEX idx_sensor_time (sensor_id, timestamp),
    INDEX idx_timestamp (timestamp)
) ENGINE=InnoDB
PARTITION BY RANGE (TO_DAYS(timestamp)) (
    PARTITION p202501 VALUES LESS THAN (TO_DAYS('2025-02-01')),
    PARTITION p202502 VALUES LESS THAN (TO_DAYS('2025-03-01')),
    PARTITION p202503 VALUES LESS THAN (TO_DAYS('2025-04-01')),
    PARTITION pmax VALUES LESS THAN MAXVALUE
);

-- ============================================================================
-- Production Management Tables
-- ============================================================================

-- Products
CREATE TABLE products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    product_code VARCHAR(50) UNIQUE NOT NULL,
    product_name VARCHAR(200) NOT NULL,
    product_category VARCHAR(100),
    unit_of_measure VARCHAR(20) DEFAULT 'unit',
    standard_cycle_time_seconds DECIMAL(10,2),
    weight_kg DECIMAL(10,3),
    quality_specs JSON,
    bom JSON COMMENT 'Bill of materials',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_product_category (product_category)
) ENGINE=InnoDB;

-- Work orders
CREATE TABLE work_orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    order_number VARCHAR(50) UNIQUE NOT NULL,
    product_id INT NOT NULL,
    line_id INT NOT NULL,
    planned_quantity INT NOT NULL,
    planned_start_time DATETIME NOT NULL,
    planned_end_time DATETIME NOT NULL,
    actual_start_time DATETIME,
    actual_end_time DATETIME,
    produced_quantity INT DEFAULT 0,
    good_quantity INT DEFAULT 0,
    rejected_quantity INT DEFAULT 0,
    status ENUM('planned', 'in_progress', 'completed', 'cancelled', 'on_hold') DEFAULT 'planned',
    priority INT DEFAULT 5 COMMENT '1=highest, 10=lowest',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_product_order (product_id),
    INDEX idx_line_order (line_id),
    INDEX idx_order_status (status),
    INDEX idx_planned_start (planned_start_time)
) ENGINE=InnoDB;

-- Production runs (actual production tracking)
CREATE TABLE production_runs (
    run_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    machine_id INT NOT NULL,
    operator_id INT,
    start_time DATETIME NOT NULL,
    end_time DATETIME,
    quantity_produced INT DEFAULT 0,
    quantity_good INT DEFAULT 0,
    quantity_rejected INT DEFAULT 0,
    cycle_time_actual DECIMAL(10,2),
    downtime_minutes DECIMAL(10,2) DEFAULT 0,
    speed_percentage DECIMAL(5,2) DEFAULT 100,
    notes TEXT,
    INDEX idx_order_run (order_id),
    INDEX idx_machine_run (machine_id),
    INDEX idx_run_time (start_time, end_time)
) ENGINE=InnoDB;

-- ============================================================================
-- Quality Control Tables
-- ============================================================================

-- Quality inspections
CREATE TABLE quality_inspections (
    inspection_id INT PRIMARY KEY AUTO_INCREMENT,
    run_id BIGINT NOT NULL,
    product_id INT NOT NULL,
    inspection_time DATETIME NOT NULL,
    inspector_id INT,
    sample_size INT,
    defects_found INT DEFAULT 0,
    defect_types JSON,
    measurements JSON,
    pass_fail ENUM('pass', 'fail', 'conditional') NOT NULL,
    notes TEXT,
    INDEX idx_run_inspection (run_id),
    INDEX idx_product_inspection (product_id),
    INDEX idx_inspection_time (inspection_time)
) ENGINE=InnoDB;

-- Defect tracking
CREATE TABLE defects (
    defect_id INT PRIMARY KEY AUTO_INCREMENT,
    inspection_id INT NOT NULL,
    defect_type VARCHAR(100) NOT NULL,
    severity ENUM('critical', 'major', 'minor', 'cosmetic') NOT NULL,
    quantity INT DEFAULT 1,
    root_cause VARCHAR(200),
    corrective_action TEXT,
    image_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_inspection_defect (inspection_id),
    INDEX idx_defect_type (defect_type),
    INDEX idx_severity (severity)
) ENGINE=InnoDB;

-- ============================================================================
-- OEE (Overall Equipment Effectiveness) Tables
-- ============================================================================

-- OEE metrics (hourly aggregation)
CREATE TABLE oee_metrics (
    oee_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    machine_id INT NOT NULL,
    line_id INT NOT NULL,
    metric_timestamp DATETIME NOT NULL,
    hour_start DATETIME NOT NULL,
    hour_end DATETIME NOT NULL,

    -- Availability
    planned_production_time_min DECIMAL(10,2),
    operating_time_min DECIMAL(10,2),
    downtime_min DECIMAL(10,2),
    availability_percentage DECIMAL(5,2),

    -- Performance
    ideal_cycle_time_sec DECIMAL(10,2),
    total_pieces_produced INT,
    performance_percentage DECIMAL(5,2),

    -- Quality
    good_pieces INT,
    total_pieces INT,
    quality_percentage DECIMAL(5,2),

    -- OEE
    oee_percentage DECIMAL(5,2),

    INDEX idx_machine_oee (machine_id, metric_timestamp),
    INDEX idx_line_oee (line_id, metric_timestamp),
    INDEX idx_oee_time (metric_timestamp),
    UNIQUE KEY uk_machine_hour (machine_id, hour_start)
) ENGINE=InnoDB;

-- ============================================================================
-- Maintenance Tables
-- ============================================================================

-- Maintenance schedules
CREATE TABLE maintenance_schedules (
    schedule_id INT PRIMARY KEY AUTO_INCREMENT,
    machine_id INT NOT NULL,
    maintenance_type ENUM('preventive', 'predictive', 'corrective', 'calibration') NOT NULL,
    frequency_days INT,
    last_performed DATE,
    next_due DATE,
    estimated_duration_hours DECIMAL(5,2),
    parts_required JSON,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_machine_schedule (machine_id),
    INDEX idx_next_due (next_due),
    INDEX idx_maintenance_type (maintenance_type)
) ENGINE=InnoDB;

-- Maintenance records
CREATE TABLE maintenance_records (
    record_id INT PRIMARY KEY AUTO_INCREMENT,
    machine_id INT NOT NULL,
    schedule_id INT,
    maintenance_type ENUM('preventive', 'predictive', 'corrective', 'emergency', 'calibration') NOT NULL,
    start_time DATETIME NOT NULL,
    end_time DATETIME,
    technician_id INT,
    downtime_minutes DECIMAL(10,2),
    parts_replaced JSON,
    cost DECIMAL(10,2),
    findings TEXT,
    actions_taken TEXT,
    next_action TEXT,
    status ENUM('scheduled', 'in_progress', 'completed', 'cancelled') DEFAULT 'scheduled',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_machine_maintenance (machine_id),
    INDEX idx_maintenance_time (start_time),
    INDEX idx_maintenance_status (status)
) ENGINE=InnoDB;

-- ============================================================================
-- Alert and Event Tables
-- ============================================================================

-- Alerts
CREATE TABLE alerts (
    alert_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    source_type ENUM('sensor', 'machine', 'line', 'quality', 'maintenance') NOT NULL,
    source_id INT NOT NULL,
    alert_type VARCHAR(100) NOT NULL,
    severity ENUM('critical', 'high', 'medium', 'low', 'info') NOT NULL,
    message TEXT NOT NULL,
    threshold_value DECIMAL(12,4),
    actual_value DECIMAL(12,4),
    triggered_at DATETIME NOT NULL,
    acknowledged_at DATETIME,
    acknowledged_by INT,
    resolved_at DATETIME,
    resolved_by INT,
    resolution_notes TEXT,
    INDEX idx_source (source_type, source_id),
    INDEX idx_alert_severity (severity),
    INDEX idx_triggered_at (triggered_at),
    INDEX idx_unresolved (resolved_at)
) ENGINE=InnoDB;

-- Downtime events
CREATE TABLE downtime_events (
    event_id INT PRIMARY KEY AUTO_INCREMENT,
    machine_id INT NOT NULL,
    line_id INT NOT NULL,
    start_time DATETIME NOT NULL,
    end_time DATETIME,
    duration_minutes DECIMAL(10,2),
    reason_category ENUM('equipment_failure', 'changeover', 'material_shortage',
                        'quality_issue', 'no_operator', 'planned_maintenance',
                        'unplanned_maintenance', 'other') NOT NULL,
    reason_detail VARCHAR(500),
    impact_level ENUM('line_stop', 'reduced_speed', 'quality_impact') DEFAULT 'line_stop',
    lost_production_units INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_machine_downtime (machine_id),
    INDEX idx_line_downtime (line_id),
    INDEX idx_downtime_period (start_time, end_time),
    INDEX idx_reason_category (reason_category)
) ENGINE=InnoDB;

-- ============================================================================
-- Personnel Tables
-- ============================================================================

-- Operators
CREATE TABLE operators (
    operator_id INT PRIMARY KEY AUTO_INCREMENT,
    employee_number VARCHAR(50) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(200) UNIQUE,
    phone VARCHAR(20),
    shift ENUM('morning', 'afternoon', 'night', 'rotating') NOT NULL,
    skill_level ENUM('trainee', 'operator', 'senior', 'supervisor') NOT NULL,
    certifications JSON,
    factory_id INT NOT NULL,
    hire_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_factory_operator (factory_id),
    INDEX idx_shift (shift),
    INDEX idx_active_operators (is_active)
) ENGINE=InnoDB;

-- Shift logs
CREATE TABLE shift_logs (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    shift_date DATE NOT NULL,
    shift_type ENUM('morning', 'afternoon', 'night') NOT NULL,
    line_id INT NOT NULL,
    supervisor_id INT,
    operators_count INT,
    production_target INT,
    production_actual INT,
    oee_target DECIMAL(5,2),
    oee_actual DECIMAL(5,2),
    safety_incidents INT DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_shift_date (shift_date),
    INDEX idx_line_shift (line_id),
    UNIQUE KEY uk_line_shift_date (line_id, shift_date, shift_type)
) ENGINE=InnoDB;