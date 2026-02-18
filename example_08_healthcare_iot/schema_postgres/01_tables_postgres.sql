-- PostgreSQL Schema
-- Converted from MySQL on 2026-02-17T23:11:17.360366
-- Generator: MySQL to PostgreSQL Converter

-- Enum Types
CREATE TYPE audit_log_status AS ENUM ('INSERT', 'UPDATE', 'DELETE');
CREATE TYPE departments_status AS ENUM ('ICU', 'Emergency', 'Surgery', 'Pediatrics', 'Cardiology', 'Neurology', 'Oncology', 'Maternity', 'General', 'Other');
CREATE TYPE rooms_status AS ENUM ('Private', 'Semi-Private', 'Ward', 'ICU', 'Operating', 'Emergency');
CREATE TYPE staff_status AS ENUM ('Day', 'Night', 'Rotating', 'On-Call');
CREATE TYPE patients_status AS ENUM ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Unknown');
CREATE TYPE admissions_status AS ENUM ('Home', 'Rehab', 'Nursing Facility', 'Transfer', 'Deceased', 'AMA', 'Other');
CREATE TYPE devices_status AS ENUM ('Online', 'Offline', 'Intermittent');
CREATE TYPE vital_signs_status AS ENUM ('Alert', 'Verbal', 'Pain', 'Unresponsive');
CREATE TYPE alerts_status AS ENUM ('Vital Signs', 'Device', 'Medication', 'Lab Results', 'Fall', 'Other');
CREATE TYPE alert_rules_status AS ENUM ('Critical', 'Warning', 'Info');
CREATE TYPE prescriptions_status AS ENUM ('Oral', 'IV', 'IM', 'Subcutaneous', 'Topical', 'Inhalation', 'Other');
CREATE TYPE lab_orders_status AS ENUM ('Ordered', 'Collected', 'Processing', 'Resulted', 'Cancelled');
CREATE TYPE lab_results_status AS ENUM ('Normal', 'Low', 'High', 'Critical Low', 'Critical High');
CREATE TYPE clinical_notes_status AS ENUM ('Progress', 'Admission', 'Discharge', 'Consultation', 'Procedure', 'Nursing');
CREATE TYPE emergency_events_status AS ENUM ('Stabilized', 'Transferred', 'Deceased', 'False Alarm');

DROP DATABASE IF EXISTS healthcare_iot;
-- Create database (run as superuser)
-- CREATE DATABASE healthcare_iot;
-- \c healthcare_iot

CREATE USER IF NOT EXISTS 'health_admin'@'localhost' IDENTIFIED BY 'HealthAdm1n!2024';
GRANT ALL PRIVILEGES ON healthcare_iot.* TO 'health_admin'@'localhost';
CREATE USER IF NOT EXISTS 'medical_staff'@'localhost' IDENTIFIED BY 'MedSt@ff2024';
GRANT SELECT, INSERT, UPDATE ON healthcare_iot.* TO 'medical_staff'@'localhost';
CREATE USER IF NOT EXISTS 'monitoring_system'@'localhost' IDENTIFIED BY 'Mon1t0r$ys2024';
GRANT SELECT, INSERT ON healthcare_iot.vital_signs TO 'monitoring_system'@'localhost';
GRANT SELECT, INSERT ON healthcare_iot.device_readings TO 'monitoring_system'@'localhost';
GRANT SELECT, INSERT ON healthcare_iot.alerts TO 'monitoring_system'@'localhost';
CREATE USER IF NOT EXISTS 'health_analyst'@'localhost' IDENTIFIED BY 'An@lyst2024';
GRANT SELECT ON healthcare_iot.* TO 'health_analyst'@'localhost';
CREATE USER IF NOT EXISTS 'patient_portal'@'localhost' IDENTIFIED BY 'P@tient2024';
GRANT SELECT ON healthcare_iot.patients TO 'patient_portal'@'localhost';
GRANT SELECT ON healthcare_iot.vital_signs TO 'patient_portal'@'localhost';
GRANT SELECT ON healthcare_iot.medications TO 'patient_portal'@'localhost';
FLUSH PRIVILEGES;
DELIMITER $$
CREATE FUNCTION calculate_early_warning_score(
resp_rate INT,
oxygen_saturation DECIMAL(5,2),
systolic_bp INT,
pulse_rate INT,
consciousness_level VARCHAR(10),
temperature DECIMAL(4,1)
) RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
DECLARE score INT DEFAULT 0;
IF resp_rate <= 8 OR resp_rate >= 25 THEN
SET score = score + 3;
ELSEIF resp_rate BETWEEN 9 AND 11 THEN
SET score = score + 1;
ELSEIF resp_rate BETWEEN 21 AND 24 THEN
SET score = score + 2;
END IF;
IF oxygen_saturation <= 91 THEN
SET score = score + 3;
ELSEIF oxygen_saturation BETWEEN 92 AND 93 THEN
SET score = score + 2;
ELSEIF oxygen_saturation BETWEEN 94 AND 95 THEN
SET score = score + 1;
END IF;
IF systolic_bp <= 90 OR systolic_bp >= 220 THEN
SET score = score + 3;
ELSEIF systolic_bp BETWEEN 91 AND 100 THEN
SET score = score + 2;
ELSEIF systolic_bp BETWEEN 101 AND 110 THEN
SET score = score + 1;
END IF;
IF pulse_rate <= 40 OR pulse_rate >= 131 THEN
SET score = score + 3;
ELSEIF pulse_rate BETWEEN 41 AND 50 OR pulse_rate BETWEEN 91 AND 110 THEN
SET score = score + 1;
ELSEIF pulse_rate BETWEEN 111 AND 130 THEN
SET score = score + 2;
END IF;
IF consciousness_level != 'Alert' THEN
SET score = score + 3;
END IF;
IF temperature <= 35.0 THEN
SET score = score + 3;
ELSEIF temperature BETWEEN 35.1 AND 36.0 OR temperature >= 39.1 THEN
SET score = score + 2;
ELSEIF temperature BETWEEN 38.1 AND 39.0 THEN
SET score = score + 1;
END IF;
RETURN score;
END$$
CREATE FUNCTION calculate_bmi(
height_cm DECIMAL(5,2),
weight_kg DECIMAL(5,2)
) RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN
IF height_cm IS NULL OR weight_kg IS NULL OR height_cm = 0 THEN
RETURN NULL;
END IF;
RETURN weight_kg / POWER(height_cm / 100, 2);
END$$
CREATE FUNCTION calculate_adherence_rate(
patient_id INT,
days_back INT
) RETURNS DECIMAL(5,2)
READS SQL DATA
BEGIN
DECLARE total_doses INT;
DECLARE taken_doses INT;
DECLARE adherence_rate DECIMAL(5,2);
SELECT
COUNT(*) AS total,
SUM(CASE WHEN taken = TRUE THEN 1 ELSE 0 END) AS taken
INTO total_doses, taken_doses
FROM medication_administration
WHERE patient_id = patient_id
AND scheduled_time >= DATE_SUB(CURDATE(), INTERVAL days_back DAY)
AND scheduled_time <= NOW();
IF total_doses = 0 THEN
RETURN NULL;
END IF;
RETURN adherence_rate;
END$$
CREATE FUNCTION anonymize_patient_id(
patient_id INT,
salt VARCHAR(32)
) RETURNS VARCHAR(64)
DETERMINISTIC
BEGIN
RETURN SHA2(CONCAT(patient_id, salt), 256);
END$$
DELIMITER ;
DELIMITER $$
CREATE PROCEDURE manage_partitions()
BEGIN
DECLARE partition_date DATE;
DECLARE partition_name VARCHAR(20);
IF NOT EXISTS (
SELECT 1 FROM information_schema.partitions
WHERE table_schema = 'healthcare_iot'
AND table_name = 'vital_signs'
AND partition_name = partition_name
) THEN
SET @sql = CONCAT('ALTER TABLE vital_signs ADD PARTITION (PARTITION ',
partition_name, ' VALUES LESS THAN (TO_DAYS(''',
DATE_ADD(partition_date, INTERVAL 1 MONTH), ''')))');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
END IF;
IF EXISTS (
SELECT 1 FROM information_schema.partitions
WHERE table_schema = 'healthcare_iot'
AND table_name = 'vital_signs'
AND partition_name = partition_name
) THEN
SET @sql = CONCAT('ALTER TABLE vital_signs DROP PARTITION ', partition_name);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
END IF;
END$$
DELIMITER ;
CREATE EVENT IF NOT EXISTS manage_partitions_monthly
ON SCHEDULE EVERY 1 MONTH
STARTS (DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL 1 MONTH), '%Y-%m-01 00:00:00'))
DO CALL manage_partitions();
CREATE TABLE IF NOT EXISTS audit_log (
    table_name VARCHAR(64) NOT NULL,
    operation audit_log_status NOT NULL,
    user VARCHAR(100),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    record_id INTEGER,
    old_values JSONB,
    new_values JSONB
);

CREATE TABLE IF NOT EXISTS schema_version (
    version VARCHAR(20) NOT NULL,
    description TEXT,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    applied_by VARCHAR(100) DEFAULT USER()
);

INSERT INTO schema_version (version, description)
VALUES ('1.0.0', 'Initial Healthcare IoT database schema');
CREATE TABLE IF NOT EXISTS hospitals (
    hospital_name VARCHAR(200) NOT NULL,
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(50),
    zip_code VARCHAR(20),
    country VARCHAR(100) DEFAULT 'USA',
    phone VARCHAR(20),
    email VARCHAR(100),
    license_number VARCHAR(50),
    accreditation VARCHAR(100),
    bed_capacity INTEGER,
    emergency_services BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS departments (
    hospital_id INTEGER NOT NULL,
    department_name VARCHAR(100) NOT NULL,
    department_code VARCHAR(20) NOT NULL,
    department_type departments_status NOT NULL,
    floor_number INTEGER,
    bed_count INTEGER,
    nurse_station_location VARCHAR(50),
    phone_extension VARCHAR(10),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (hospital_id, department_code)
);

CREATE TABLE IF NOT EXISTS rooms (
    department_id INTEGER NOT NULL,
    room_number VARCHAR(20) NOT NULL,
    room_type rooms_status NOT NULL,
    bed_count INTEGER DEFAULT 1,
    floor INTEGER,
    is_occupied BOOLEAN DEFAULT FALSE,
    is_isolation BOOLEAN DEFAULT FALSE,
    has_monitoring BOOLEAN DEFAULT TRUE,
    equipment_list JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (department_id, room_number)
);

CREATE TABLE IF NOT EXISTS staff (
    hospital_id INTEGER NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    title VARCHAR(50),
    role staff_status NOT NULL,
    specialization VARCHAR(100),
    license_number VARCHAR(50),
    license_expiry DATE,
    department_id INTEGER,
    email VARCHAR(100),
    phone VARCHAR(20),
    shift_type staff_status,
    hire_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS staff_schedules (
    staff_id INTEGER NOT NULL,
    department_id INTEGER NOT NULL,
    shift_date DATE NOT NULL,
    shift_start TIME NOT NULL,
    shift_end TIME NOT NULL,
    break_minutes INTEGER DEFAULT 30,
    is_on_call BOOLEAN DEFAULT FALSE,
    actual_start TIMESTAMP,
    actual_end TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (staff_id, shift_date, shift_start)
);

CREATE TABLE IF NOT EXISTS patients (
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender patients_status NOT NULL,
    blood_type patients_status,
    height_cm DECIMAL(5,2),
    weight_kg DECIMAL(5,2),
    bmi DECIMAL(5,2) GENERATED ALWAYS AS (calculate_bmi(height_cm, weight_kg)) STORED,
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(50),
    zip_code VARCHAR(20),
    phone VARCHAR(20),
    email VARCHAR(100),
    emergency_contact_name VARCHAR(200),
    emergency_contact_phone VARCHAR(20),
    emergency_contact_relation VARCHAR(50),
    insurance_provider VARCHAR(100),
    insurance_id VARCHAR(50),
    allergies JSONB,
    chronic_conditions JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS admissions (
    patient_id INTEGER NOT NULL,
    hospital_id INTEGER NOT NULL,
    department_id INTEGER NOT NULL,
    room_id INTEGER,
    admission_date TIMESTAMP NOT NULL,
    discharge_date TIMESTAMP,
    admission_type admissions_status NOT NULL,
    admission_source admissions_status,
    chief_complaint TEXT,
    diagnosis_codes JSONB,
    attending_physician_id INTEGER NOT NULL,
    admitting_physician_id INTEGER,
    status admissions_status DEFAULT 'Active',
    discharge_disposition admissions_status,
    total_charges DECIMAL(10,2),
    insurance_coverage DECIMAL(10,2),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS devices (
    device_type devices_status NOT NULL,
    manufacturer VARCHAR(100),
    model VARCHAR(100),
    firmware_version VARCHAR(50),
    hospital_id INTEGER NOT NULL,
    department_id INTEGER,
    room_id INTEGER,
    current_patient_id INTEGER,
    installation_date DATE,
    last_maintenance_date DATE,
    next_maintenance_date DATE,
    calibration_date DATE,
    battery_level INTEGER,
    connectivity_status devices_status DEFAULT 'Offline',
    last_seen TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    settings JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS device_assignments (
    device_id INTEGER NOT NULL,
    patient_id INTEGER NOT NULL,
    admission_id INTEGER NOT NULL,
    assigned_at TIMESTAMP NOT NULL,
    unassigned_at TIMESTAMP,
    assigned_by INTEGER NOT NULL,
    unassigned_by INTEGER,
    reason VARCHAR(200),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS vital_signs (
    patient_id INTEGER NOT NULL,
    admission_id INTEGER,
    device_id INTEGER,
    recorded_at TIMESTAMP NOT NULL,
    heart_rate INTEGER,
    respiratory_rate INTEGER,
    systolic_bp INTEGER,
    diastolic_bp INTEGER,
    oxygen_saturation DECIMAL(5,2),
    temperature DECIMAL(4,1),
    blood_glucose DECIMAL(6,2),
    pain_level INTEGER,
    consciousness_level vital_signs_status,
    early_warning_score INTEGER GENERATED ALWAYS AS (,
    recorded_by INTEGER,
    is_manual_entry BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PARTITION TEXT VALUES LESS THAN (TO_DAYS('2024-03-01')),
    PARTITION TEXT VALUES LESS THAN (TO_DAYS('2024-04-01')),
    PARTITION TEXT VALUES LESS THAN (TO_DAYS('2024-05-01')),
    PARTITION TEXT VALUES LESS THAN (TO_DAYS('2024-06-01')),
    PARTITION TEXT VALUES LESS THAN (TO_DAYS('2024-07-01'))
);

CREATE TABLE IF NOT EXISTS device_readings (
    device_id INTEGER NOT NULL,
    patient_id INTEGER,
    timestamp TIMESTAMP NOT NULL,
    metric_type VARCHAR(50) NOT NULL,
    metric_value DECIMAL(10,3),
    metric_unit VARCHAR(20),
    quality_score INTEGER,
    raw_data JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PARTITION TEXT VALUES LESS THAN (TO_DAYS('2024-03-01')),
    PARTITION TEXT VALUES LESS THAN (TO_DAYS('2024-04-01')),
    PARTITION TEXT VALUES LESS THAN (TO_DAYS('2024-05-01')),
    PARTITION TEXT VALUES LESS THAN (TO_DAYS('2024-06-01')),
    PARTITION TEXT VALUES LESS THAN (TO_DAYS('2024-07-01'))
);

CREATE TABLE IF NOT EXISTS alerts (
    patient_id INTEGER NOT NULL,
    admission_id INTEGER,
    device_id INTEGER,
    alert_type alerts_status NOT NULL,
    alert_category alerts_status NOT NULL,
    alert_code VARCHAR(50),
    alert_message TEXT NOT NULL,
    metric_name VARCHAR(50),
    metric_value DECIMAL(10,3),
    threshold_value DECIMAL(10,3),
    triggered_at TIMESTAMP NOT NULL,
    acknowledged_at TIMESTAMP,
    acknowledged_by INTEGER,
    resolved_at TIMESTAMP,
    resolved_by INTEGER,
    escalated BOOLEAN DEFAULT FALSE,
    response_time_seconds INTEGER,
    actions_taken TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS alert_rules (
    rule_name VARCHAR(100) NOT NULL,
    rule_type alert_rules_status NOT NULL,
    metric_type VARCHAR(50) NOT NULL,
    condition_operator alert_rules_status NOT NULL,
    threshold_value1 DECIMAL(10,3),
    threshold_value2 DECIMAL(10,3),
    time_window_minutes INTEGER,
    severity alert_rules_status NOT NULL,
    department_id INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    notification_channels JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS medications (
    medication_name VARCHAR(200) NOT NULL,
    generic_name VARCHAR(200),
    drug_class VARCHAR(100),
    ndc_code VARCHAR(20),
    dosage_form VARCHAR(50),
    strength VARCHAR(50),
    unit VARCHAR(20),
    manufacturer VARCHAR(100),
    controlled_substance_schedule VARCHAR(10),
    requires_refrigeration BOOLEAN DEFAULT FALSE,
    black_box_warning TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS prescriptions (
    patient_id INTEGER NOT NULL,
    admission_id INTEGER,
    medication_id INTEGER NOT NULL,
    prescribing_physician_id INTEGER NOT NULL,
    dosage VARCHAR(100) NOT NULL,
    frequency VARCHAR(100) NOT NULL,
    route prescriptions_status NOT NULL,
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP,
    duration_days INTEGER,
    refills INTEGER DEFAULT 0,
    instructions TEXT,
    is_prn BOOLEAN DEFAULT FALSE,
    prn_reason VARCHAR(200),
    is_active BOOLEAN DEFAULT TRUE,
    discontinued_date TIMESTAMP,
    discontinued_by INTEGER,
    discontinued_reason VARCHAR(200),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS medication_administration (
    prescription_id INTEGER NOT NULL,
    patient_id INTEGER NOT NULL,
    scheduled_time TIMESTAMP NOT NULL,
    actual_time TIMESTAMP,
    administered_by INTEGER,
    dosage_given VARCHAR(100),
    route_used VARCHAR(50),
    taken BOOLEAN DEFAULT FALSE,
    missed BOOLEAN DEFAULT FALSE,
    refused BOOLEAN DEFAULT FALSE,
    reason VARCHAR(200),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS lab_tests (
    test_code VARCHAR(20) NOT NULL,
    test_name VARCHAR(200) NOT NULL,
    test_category VARCHAR(100),
    specimen_type VARCHAR(50),
    normal_range_low DECIMAL(10,3),
    normal_range_high DECIMAL(10,3),
    unit VARCHAR(20),
    critical_low DECIMAL(10,3),
    critical_high DECIMAL(10,3),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (test_code)
);

CREATE TABLE IF NOT EXISTS lab_orders (
    patient_id INTEGER NOT NULL,
    admission_id INTEGER,
    ordering_physician_id INTEGER NOT NULL,
    order_date TIMESTAMP NOT NULL,
    priority lab_orders_status NOT NULL,
    tests_ordered JSONB NOT NULL,
    specimen_collected BOOLEAN DEFAULT FALSE,
    collected_at TIMESTAMP,
    collected_by INTEGER,
    status lab_orders_status DEFAULT 'Ordered',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS lab_results (
    order_id INTEGER NOT NULL,
    test_id INTEGER NOT NULL,
    patient_id INTEGER NOT NULL,
    result_value DECIMAL(10,3),
    result_text VARCHAR(500),
    abnormal_flag lab_results_status,
    reference_range VARCHAR(100),
    resulted_at TIMESTAMP NOT NULL,
    verified_by INTEGER,
    verified_at TIMESTAMP,
    comments TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS clinical_notes (
    patient_id INTEGER NOT NULL,
    admission_id INTEGER,
    note_type clinical_notes_status NOT NULL,
    author_id INTEGER NOT NULL,
    note_date TIMESTAMP NOT NULL,
    note_text TEXT NOT NULL,
    is_signed BOOLEAN DEFAULT FALSE,
    signed_at TIMESTAMP,
    cosigner_id INTEGER,
    cosigned_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FULLTEXT TEXT (note_text)
);

CREATE TABLE IF NOT EXISTS emergency_events (
    patient_id INTEGER NOT NULL,
    admission_id INTEGER,
    event_type emergency_events_status NOT NULL,
    location VARCHAR(100) NOT NULL,
    initiated_at TIMESTAMP NOT NULL,
    team_arrived_at TIMESTAMP,
    resolved_at TIMESTAMP,
    initiated_by INTEGER NOT NULL,
    team_lead_id INTEGER,
    outcome emergency_events_status,
    interventions JSONB,
    medications_given JSONB,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS patient_daily_summary (
    patient_id INTEGER NOT NULL,
    admission_id INTEGER NOT NULL,
    summary_date DATE NOT NULL,
    avg_heart_rate DECIMAL(5,2),
    avg_bp_systolic DECIMAL(5,2),
    avg_bp_diastolic DECIMAL(5,2),
    avg_temperature DECIMAL(4,1),
    avg_oxygen_sat DECIMAL(5,2),
    min_oxygen_sat DECIMAL(5,2),
    max_early_warning_score INTEGER,
    alert_count INTEGER,
    critical_alert_count INTEGER,
    medications_administered INTEGER,
    medications_missed INTEGER,
    lab_tests_ordered INTEGER,
    lab_results_abnormal INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (patient_id, admission_id, summary_date)
);

-- Indexes
