-- PostgreSQL Schema
-- Converted from MySQL on 2026-02-17T23:11:17.361127
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

ALTER TABLE departments
ADD CONSTRAINT fk_dept_hospital
FOREIGN KEY (hospital_id) REFERENCES hospitals(hospital_id)
ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE rooms
ADD CONSTRAINT fk_room_department
FOREIGN KEY (department_id) REFERENCES departments(department_id)
ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE staff
ADD CONSTRAINT fk_staff_hospital
FOREIGN KEY (hospital_id) REFERENCES hospitals(hospital_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_staff_department
FOREIGN KEY (department_id) REFERENCES departments(department_id)
ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE staff_schedules
ADD CONSTRAINT fk_schedule_staff
FOREIGN KEY (staff_id) REFERENCES staff(staff_id)
ON DELETE CASCADE ON UPDATE CASCADE,
ADD CONSTRAINT fk_schedule_department
FOREIGN KEY (department_id) REFERENCES departments(department_id)
ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE patients
ADD CONSTRAINT fk_patient_physician
FOREIGN KEY (primary_physician_id) REFERENCES staff(staff_id)
ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE admissions
ADD CONSTRAINT fk_admission_patient
FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_admission_hospital
FOREIGN KEY (hospital_id) REFERENCES hospitals(hospital_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_admission_department
FOREIGN KEY (department_id) REFERENCES departments(department_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_admission_room
FOREIGN KEY (room_id) REFERENCES rooms(room_id)
ON DELETE SET NULL ON UPDATE CASCADE,
ADD CONSTRAINT fk_admission_attending
FOREIGN KEY (attending_physician_id) REFERENCES staff(staff_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_admission_admitting
FOREIGN KEY (admitting_physician_id) REFERENCES staff(staff_id)
ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE devices
ADD CONSTRAINT fk_device_hospital
FOREIGN KEY (hospital_id) REFERENCES hospitals(hospital_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_device_department
FOREIGN KEY (department_id) REFERENCES departments(department_id)
ON DELETE SET NULL ON UPDATE CASCADE,
ADD CONSTRAINT fk_device_room
FOREIGN KEY (room_id) REFERENCES rooms(room_id)
ON DELETE SET NULL ON UPDATE CASCADE,
ADD CONSTRAINT fk_device_patient
FOREIGN KEY (current_patient_id) REFERENCES patients(patient_id)
ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE device_assignments
ADD CONSTRAINT fk_assignment_device
FOREIGN KEY (device_id) REFERENCES devices(device_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_assignment_patient
FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_assignment_admission
FOREIGN KEY (admission_id) REFERENCES admissions(admission_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_assignment_assigned_by
FOREIGN KEY (assigned_by) REFERENCES staff(staff_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_assignment_unassigned_by
FOREIGN KEY (unassigned_by) REFERENCES staff(staff_id)
ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE vital_signs
ADD CONSTRAINT fk_vitals_patient
FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_vitals_admission
FOREIGN KEY (admission_id) REFERENCES admissions(admission_id)
ON DELETE SET NULL ON UPDATE CASCADE,
ADD CONSTRAINT fk_vitals_device
FOREIGN KEY (device_id) REFERENCES devices(device_id)
ON DELETE SET NULL ON UPDATE CASCADE,
ADD CONSTRAINT fk_vitals_recorded_by
FOREIGN KEY (recorded_by) REFERENCES staff(staff_id)
ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE device_readings
ADD CONSTRAINT fk_reading_device
FOREIGN KEY (device_id) REFERENCES devices(device_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_reading_patient
FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE alerts
ADD CONSTRAINT fk_alert_patient
FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_alert_admission
FOREIGN KEY (admission_id) REFERENCES admissions(admission_id)
ON DELETE SET NULL ON UPDATE CASCADE,
ADD CONSTRAINT fk_alert_device
FOREIGN KEY (device_id) REFERENCES devices(device_id)
ON DELETE SET NULL ON UPDATE CASCADE,
ADD CONSTRAINT fk_alert_acknowledged_by
FOREIGN KEY (acknowledged_by) REFERENCES staff(staff_id)
ON DELETE SET NULL ON UPDATE CASCADE,
ADD CONSTRAINT fk_alert_resolved_by
FOREIGN KEY (resolved_by) REFERENCES staff(staff_id)
ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE alert_rules
ADD CONSTRAINT fk_rule_department
FOREIGN KEY (department_id) REFERENCES departments(department_id)
ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE prescriptions
ADD CONSTRAINT fk_rx_patient
FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_rx_admission
FOREIGN KEY (admission_id) REFERENCES admissions(admission_id)
ON DELETE SET NULL ON UPDATE CASCADE,
ADD CONSTRAINT fk_rx_medication
FOREIGN KEY (medication_id) REFERENCES medications(medication_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_rx_physician
FOREIGN KEY (prescribing_physician_id) REFERENCES staff(staff_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_rx_discontinued_by
FOREIGN KEY (discontinued_by) REFERENCES staff(staff_id)
ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE medication_administration
ADD CONSTRAINT fk_mar_prescription
FOREIGN KEY (prescription_id) REFERENCES prescriptions(prescription_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_mar_patient
FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_mar_administered_by
FOREIGN KEY (administered_by) REFERENCES staff(staff_id)
ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE lab_orders
ADD CONSTRAINT fk_lab_patient
FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_lab_admission
FOREIGN KEY (admission_id) REFERENCES admissions(admission_id)
ON DELETE SET NULL ON UPDATE CASCADE,
ADD CONSTRAINT fk_lab_physician
FOREIGN KEY (ordering_physician_id) REFERENCES staff(staff_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_lab_collected_by
FOREIGN KEY (collected_by) REFERENCES staff(staff_id)
ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE lab_results
ADD CONSTRAINT fk_result_order
FOREIGN KEY (order_id) REFERENCES lab_orders(order_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_result_test
FOREIGN KEY (test_id) REFERENCES lab_tests(test_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_result_patient
FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_result_verified_by
FOREIGN KEY (verified_by) REFERENCES staff(staff_id)
ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE clinical_notes
ADD CONSTRAINT fk_note_patient
FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_note_admission
FOREIGN KEY (admission_id) REFERENCES admissions(admission_id)
ON DELETE SET NULL ON UPDATE CASCADE,
ADD CONSTRAINT fk_note_author
FOREIGN KEY (author_id) REFERENCES staff(staff_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_note_cosigner
FOREIGN KEY (cosigner_id) REFERENCES staff(staff_id)
ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE emergency_events
ADD CONSTRAINT fk_emergency_patient
FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_emergency_admission
FOREIGN KEY (admission_id) REFERENCES admissions(admission_id)
ON DELETE SET NULL ON UPDATE CASCADE,
ADD CONSTRAINT fk_emergency_initiated_by
FOREIGN KEY (initiated_by) REFERENCES staff(staff_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_emergency_team_lead
FOREIGN KEY (team_lead_id) REFERENCES staff(staff_id)
ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE patient_daily_summary
ADD CONSTRAINT fk_summary_patient
FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
ON DELETE CASCADE ON UPDATE CASCADE,
ADD CONSTRAINT fk_summary_admission
FOREIGN KEY (admission_id) REFERENCES admissions(admission_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE vital_signs
ADD CONSTRAINT chk_heart_rate CHECK (heart_rate BETWEEN 0 AND 300),
ADD CONSTRAINT chk_respiratory_rate CHECK (respiratory_rate BETWEEN 0 AND 100),
ADD CONSTRAINT chk_blood_pressure CHECK (systolic_bp BETWEEN 0 AND 300 AND diastolic_bp BETWEEN 0 AND 200),
ADD CONSTRAINT chk_oxygen_saturation CHECK (oxygen_saturation BETWEEN 0 AND 100),
ADD CONSTRAINT chk_temperature CHECK (temperature BETWEEN 25 AND 45),
ADD CONSTRAINT chk_glucose CHECK (blood_glucose BETWEEN 0 AND 1000),
ADD CONSTRAINT chk_pain_level CHECK (pain_level BETWEEN 0 AND 10);
ALTER TABLE patients
ADD CONSTRAINT chk_patient_age CHECK (date_of_birth <= CURDATE()),
ADD CONSTRAINT chk_height CHECK (height_cm BETWEEN 0 AND 300),
ADD CONSTRAINT chk_weight CHECK (weight_kg BETWEEN 0 AND 500);
ALTER TABLE admissions
ADD CONSTRAINT chk_admission_dates CHECK (discharge_date IS NULL OR discharge_date >= admission_date);
ALTER TABLE devices
ADD CONSTRAINT chk_battery_level CHECK (battery_level BETWEEN 0 AND 100);
ALTER TABLE prescriptions
ADD CONSTRAINT chk_prescription_dates CHECK (end_date IS NULL OR end_date >= start_date);
ALTER TABLE staff_schedules
ADD CONSTRAINT chk_schedule_times CHECK (shift_end > shift_start);
DELIMITER $$
CREATE TRIGGER trg_vital_signs_alert
AFTER INSERT ON vital_signs
FOR EACH ROW
BEGIN
DECLARE alert_message TEXT;
DECLARE alert_type ENUM('Critical', 'Warning', 'Info');
DECLARE should_alert BOOLEAN DEFAULT FALSE;
IF NEW.early_warning_score >= 7 THEN
SET alert_type = 'Critical';
ELSEIF NEW.oxygen_saturation < 88 THEN
SET alert_type = 'Critical';
ELSEIF NEW.systolic_bp < 90 OR NEW.systolic_bp > 180 THEN
SET alert_type = 'Critical';
ELSEIF NEW.heart_rate < 40 OR NEW.heart_rate > 150 THEN
SET alert_type = 'Critical';
ELSEIF NEW.temperature > 39.5 OR NEW.temperature < 35 THEN
SET alert_type = 'Warning';
ELSEIF NEW.early_warning_score >= 5 THEN
SET alert_type = 'Warning';
END IF;
IF should_alert THEN
INSERT INTO alerts (
patient_id, admission_id, device_id, alert_type, alert_category,
alert_message, metric_name, metric_value, triggered_at
) VALUES (
NEW.patient_id, NEW.admission_id, NEW.device_id, alert_type, 'Vital Signs',
alert_message, 'early_warning_score', NEW.early_warning_score, NEW.recorded_at
);
END IF;
END$$
CREATE TRIGGER trg_admission_room_occupancy
AFTER INSERT ON admissions
FOR EACH ROW
BEGIN
IF NEW.room_id IS NOT NULL THEN
UPDATE rooms
SET is_occupied = TRUE
WHERE room_id = NEW.room_id;
END IF;
END$$
CREATE TRIGGER trg_discharge_room_release
AFTER UPDATE ON admissions
FOR EACH ROW
BEGIN
IF OLD.status = 'Active' AND NEW.status IN ('Discharged', 'Transferred', 'Deceased') THEN
IF OLD.room_id IS NOT NULL THEN
UPDATE rooms
SET is_occupied = FALSE
WHERE room_id = OLD.room_id;
END IF;
UPDATE device_assignments
SET is_active = FALSE,
unassigned_at = NEW.discharge_date
WHERE patient_id = NEW.patient_id
AND admission_id = NEW.admission_id
AND is_active = TRUE;
UPDATE devices
SET current_patient_id = NULL
WHERE current_patient_id = NEW.patient_id;
END IF;
END$$
CREATE TRIGGER trg_device_assignment_update
AFTER INSERT ON device_assignments
FOR EACH ROW
BEGIN
UPDATE devices
SET current_patient_id = NEW.patient_id
WHERE device_id = NEW.device_id;
UPDATE device_assignments
SET is_active = FALSE,
unassigned_at = NEW.assigned_at
WHERE device_id = NEW.device_id
AND assignment_id != NEW.assignment_id
AND is_active = TRUE;
END$$
CREATE TRIGGER trg_alert_response_time
BEFORE UPDATE ON alerts
FOR EACH ROW
BEGIN
IF OLD.acknowledged_at IS NULL AND NEW.acknowledged_at IS NOT NULL THEN
SET NEW.response_time_seconds = TIMESTAMPDIFF(SECOND, NEW.triggered_at, NEW.acknowledged_at);
END IF;
END$$
CREATE TRIGGER trg_medication_interaction_check
AFTER INSERT ON prescriptions
FOR EACH ROW
BEGIN
DECLARE interaction_count INT;
DECLARE interaction_message TEXT;
SELECT COUNT(*) INTO interaction_count
FROM prescriptions p1
INNER JOIN prescriptions p2 ON p1.patient_id = p2.patient_id
WHERE p1.prescription_id = NEW.prescription_id
AND p2.prescription_id != NEW.prescription_id
AND p2.is_active = TRUE
AND p2.end_date >= NEW.start_date;
IF interaction_count > 5 THEN
SET interaction_message = CONCAT('Patient has ', interaction_count, ' concurrent medications. Review for interactions.');
INSERT INTO alerts (
patient_id, admission_id, alert_type, alert_category,
alert_message, triggered_at
) VALUES (
NEW.patient_id, NEW.admission_id, 'Warning', 'Medication',
interaction_message, NOW()
);
END IF;
END$$
CREATE TRIGGER trg_generate_mar_schedule
AFTER INSERT ON prescriptions
FOR EACH ROW
BEGIN
DECLARE current_time DATETIME;
DECLARE end_time DATETIME;
DECLARE frequency_hours INT;
IF NEW.is_active = TRUE AND NEW.is_prn = FALSE THEN
SET current_time = NEW.start_date;
WHILE current_time <= end_time DO
INSERT INTO medication_administration (
prescription_id, patient_id, scheduled_time
) VALUES (
NEW.prescription_id, NEW.patient_id, current_time
);
END WHILE;
END IF;
END$$
CREATE TRIGGER trg_lab_result_status
AFTER INSERT ON lab_results
FOR EACH ROW
BEGIN
UPDATE lab_orders
SET status = 'Resulted',
updated_at = NOW()
WHERE order_id = NEW.order_id;
IF NEW.abnormal_flag IN ('Critical Low', 'Critical High') THEN
INSERT INTO alerts (
patient_id, alert_type, alert_category,
alert_message, metric_name, metric_value, triggered_at
) VALUES (
NEW.patient_id, 'Critical', 'Lab Results',
CONCAT('Critical Lab Result: ',
(SELECT test_name FROM lab_tests WHERE test_id = NEW.test_id),
' = ', NEW.result_value, ' ', NEW.result_text),
(SELECT test_code FROM lab_tests WHERE test_id = NEW.test_id),
NEW.result_value,
NEW.resulted_at
);
END IF;
END$$
CREATE TRIGGER trg_calculate_daily_summary
AFTER INSERT ON vital_signs
FOR EACH ROW
BEGIN
INSERT INTO patient_daily_summary (
patient_id, admission_id, summary_date,
avg_heart_rate, avg_bp_systolic, avg_bp_diastolic,
avg_temperature, avg_oxygen_sat
)
SELECT
NEW.patient_id,
NEW.admission_id,
DATE(NEW.recorded_at),
AVG(heart_rate),
AVG(systolic_bp),
AVG(diastolic_bp),
AVG(temperature),
AVG(oxygen_saturation)
FROM vital_signs
WHERE patient_id = NEW.patient_id
AND admission_id = NEW.admission_id
AND DATE(recorded_at) = DATE(NEW.recorded_at)
ON DUPLICATE KEY UPDATE
avg_heart_rate = VALUES(avg_heart_rate),
avg_bp_systolic = VALUES(avg_bp_systolic),
avg_bp_diastolic = VALUES(avg_bp_diastolic),
avg_temperature = VALUES(avg_temperature),
avg_oxygen_sat = VALUES(avg_oxygen_sat);
END$$
CREATE TRIGGER trg_patient_audit_insert
AFTER INSERT ON patients
FOR EACH ROW
BEGIN
INSERT INTO audit_log (table_name, operation, user, record_id, new_values)
VALUES ('patients', 'INSERT', USER(), NEW.patient_id, JSON_OBJECT('patient_id', NEW.patient_id));
END$$
CREATE TRIGGER trg_patient_audit_update
AFTER UPDATE ON patients
FOR EACH ROW
BEGIN
INSERT INTO audit_log (table_name, operation, user, record_id, old_values, new_values)
VALUES ('patients', 'UPDATE', USER(), NEW.patient_id,
JSON_OBJECT('name', CONCAT(OLD.first_name, ' ', OLD.last_name)),
JSON_OBJECT('name', CONCAT(NEW.first_name, ' ', NEW.last_name)));
END$$
DELIMITER ;
CREATE UNIQUE INDEX uk_active_admission
ON admissions(patient_id, status)
WHERE status = 'Active';
CREATE UNIQUE INDEX uk_active_device_assignment
ON device_assignments(device_id, is_active)
WHERE is_active = TRUE;
ALTER TABLE staff_schedules
ADD CONSTRAINT uk_staff_schedule
UNIQUE KEY (staff_id, shift_date, shift_start);
ALTER TABLE vital_signs
MODIFY COLUMN created_at DATETIME DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE device_readings
MODIFY COLUMN created_at DATETIME DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE alerts
MODIFY COLUMN created_at DATETIME DEFAULT CURRENT_TIMESTAMP;
-- Indexes
