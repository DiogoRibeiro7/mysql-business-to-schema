-- ============================================================================
-- Healthcare IoT Tables
-- ============================================================================

USE healthcare_iot;

-- ============================================================================
-- Healthcare Facilities
-- ============================================================================

-- Hospitals and medical facilities
CREATE TABLE hospitals (
    hospital_id INT AUTO_INCREMENT PRIMARY KEY,
    hospital_name VARCHAR(200) NOT NULL,
    hospital_code VARCHAR(20) UNIQUE NOT NULL,
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(50),
    zip_code VARCHAR(20),
    country VARCHAR(100) DEFAULT 'USA',
    phone VARCHAR(20),
    email VARCHAR(100),
    license_number VARCHAR(50),
    accreditation VARCHAR(100),
    bed_capacity INT,
    emergency_services BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_hospital_code (hospital_code),
    INDEX idx_hospital_location (state, city)
) ENGINE=InnoDB;

-- Hospital departments/units
CREATE TABLE departments (
    department_id INT AUTO_INCREMENT PRIMARY KEY,
    hospital_id INT NOT NULL,
    department_name VARCHAR(100) NOT NULL,
    department_code VARCHAR(20) NOT NULL,
    department_type ENUM('ICU', 'Emergency', 'Surgery', 'Pediatrics', 'Cardiology',
                         'Neurology', 'Oncology', 'Maternity', 'General', 'Other') NOT NULL,
    floor_number INT,
    bed_count INT,
    nurse_station_location VARCHAR(50),
    phone_extension VARCHAR(10),
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_dept_code (hospital_id, department_code),
    INDEX idx_dept_type (department_type),
    INDEX idx_dept_active (hospital_id, is_active)
) ENGINE=InnoDB;

-- Hospital rooms
CREATE TABLE rooms (
    room_id INT AUTO_INCREMENT PRIMARY KEY,
    department_id INT NOT NULL,
    room_number VARCHAR(20) NOT NULL,
    room_type ENUM('Private', 'Semi-Private', 'Ward', 'ICU', 'Operating', 'Emergency') NOT NULL,
    bed_count INT DEFAULT 1,
    floor INT,
    is_occupied BOOLEAN DEFAULT FALSE,
    is_isolation BOOLEAN DEFAULT FALSE,
    has_monitoring BOOLEAN DEFAULT TRUE,
    equipment_list JSON,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_room_number (department_id, room_number),
    INDEX idx_room_availability (department_id, is_occupied)
) ENGINE=InnoDB;

-- ============================================================================
-- Healthcare Providers
-- ============================================================================

-- Medical staff
CREATE TABLE staff (
    staff_id INT AUTO_INCREMENT PRIMARY KEY,
    hospital_id INT NOT NULL,
    employee_id VARCHAR(20) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    title VARCHAR(50),
    role ENUM('Doctor', 'Nurse', 'Technician', 'Administrator', 'Support') NOT NULL,
    specialization VARCHAR(100),
    license_number VARCHAR(50),
    license_expiry DATE,
    department_id INT,
    email VARCHAR(100),
    phone VARCHAR(20),
    shift_type ENUM('Day', 'Night', 'Rotating', 'On-Call'),
    hire_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_staff_hospital (hospital_id, is_active),
    INDEX idx_staff_role (role, department_id),
    INDEX idx_staff_license (license_number)
) ENGINE=InnoDB;

-- Staff schedules
CREATE TABLE staff_schedules (
    schedule_id INT AUTO_INCREMENT PRIMARY KEY,
    staff_id INT NOT NULL,
    department_id INT NOT NULL,
    shift_date DATE NOT NULL,
    shift_start TIME NOT NULL,
    shift_end TIME NOT NULL,
    break_minutes INT DEFAULT 30,
    is_on_call BOOLEAN DEFAULT FALSE,
    actual_start DATETIME,
    actual_end DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_staff_shift (staff_id, shift_date, shift_start),
    INDEX idx_schedule_date (shift_date, department_id),
    INDEX idx_schedule_staff (staff_id, shift_date)
) ENGINE=InnoDB;

-- ============================================================================
-- Patients
-- ============================================================================

-- Patient information (PHI - Protected Health Information)
CREATE TABLE patients (
    patient_id INT AUTO_INCREMENT PRIMARY KEY,
    medical_record_number VARCHAR(20) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender ENUM('Male', 'Female', 'Other') NOT NULL,
    blood_type ENUM('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Unknown'),
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
    primary_physician_id INT,
    allergies JSON,
    chronic_conditions JSON,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_patient_mrn (medical_record_number),
    INDEX idx_patient_name (last_name, first_name),
    INDEX idx_patient_dob (date_of_birth),
    INDEX idx_patient_physician (primary_physician_id)
) ENGINE=InnoDB;

-- Patient admissions
CREATE TABLE admissions (
    admission_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    hospital_id INT NOT NULL,
    department_id INT NOT NULL,
    room_id INT,
    admission_date DATETIME NOT NULL,
    discharge_date DATETIME,
    admission_type ENUM('Emergency', 'Scheduled', 'Transfer', 'Observation') NOT NULL,
    admission_source ENUM('Emergency Room', 'Physician Referral', 'Transfer', 'Walk-in', 'Other'),
    chief_complaint TEXT,
    diagnosis_codes JSON,
    attending_physician_id INT NOT NULL,
    admitting_physician_id INT,
    status ENUM('Active', 'Discharged', 'Transferred', 'Deceased') DEFAULT 'Active',
    discharge_disposition ENUM('Home', 'Rehab', 'Nursing Facility', 'Transfer', 'Deceased', 'AMA', 'Other'),
    total_charges DECIMAL(10,2),
    insurance_coverage DECIMAL(10,2),
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_admission_patient (patient_id, admission_date),
    INDEX idx_admission_status (status, hospital_id),
    INDEX idx_admission_dates (admission_date, discharge_date),
    INDEX idx_admission_physician (attending_physician_id)
) ENGINE=InnoDB;

-- ============================================================================
-- Medical Devices
-- ============================================================================

-- IoT medical devices
CREATE TABLE devices (
    device_id INT AUTO_INCREMENT PRIMARY KEY,
    device_serial VARCHAR(50) UNIQUE NOT NULL,
    device_type ENUM('Heart Monitor', 'Blood Pressure', 'Pulse Oximeter', 'Glucose Monitor',
                     'Temperature', 'Ventilator', 'Infusion Pump', 'EEG', 'ECG', 'Other') NOT NULL,
    manufacturer VARCHAR(100),
    model VARCHAR(100),
    firmware_version VARCHAR(50),
    hospital_id INT NOT NULL,
    department_id INT,
    room_id INT,
    current_patient_id INT,
    installation_date DATE,
    last_maintenance_date DATE,
    next_maintenance_date DATE,
    calibration_date DATE,
    battery_level INT,
    connectivity_status ENUM('Online', 'Offline', 'Intermittent') DEFAULT 'Offline',
    last_seen DATETIME,
    is_active BOOLEAN DEFAULT TRUE,
    settings JSON,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_device_type (device_type, is_active),
    INDEX idx_device_location (hospital_id, department_id, room_id),
    INDEX idx_device_patient (current_patient_id),
    INDEX idx_device_maintenance (next_maintenance_date)
) ENGINE=InnoDB;

-- Device assignments to patients
CREATE TABLE device_assignments (
    assignment_id INT AUTO_INCREMENT PRIMARY KEY,
    device_id INT NOT NULL,
    patient_id INT NOT NULL,
    admission_id INT NOT NULL,
    assigned_at DATETIME NOT NULL,
    unassigned_at DATETIME,
    assigned_by INT NOT NULL,
    unassigned_by INT,
    reason VARCHAR(200),
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_assignment_active (patient_id, is_active),
    INDEX idx_assignment_device (device_id, assigned_at),
    INDEX idx_assignment_dates (assigned_at, unassigned_at)
) ENGINE=InnoDB;

-- ============================================================================
-- Vital Signs and Monitoring
-- ============================================================================

-- Vital signs readings (partitioned by month)
CREATE TABLE vital_signs (
    reading_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    admission_id INT,
    device_id INT,
    recorded_at DATETIME NOT NULL,
    heart_rate INT,
    respiratory_rate INT,
    systolic_bp INT,
    diastolic_bp INT,
    oxygen_saturation DECIMAL(5,2),
    temperature DECIMAL(4,1),
    blood_glucose DECIMAL(6,2),
    pain_level INT,
    consciousness_level ENUM('Alert', 'Verbal', 'Pain', 'Unresponsive'),
    early_warning_score INT GENERATED ALWAYS AS (
        calculate_early_warning_score(
            respiratory_rate, oxygen_saturation, systolic_bp,
            heart_rate, consciousness_level, temperature
        )
    ) STORED,
    recorded_by INT,
    is_manual_entry BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_vitals_patient (patient_id, recorded_at DESC),
    INDEX idx_vitals_admission (admission_id, recorded_at DESC),
    INDEX idx_vitals_warning (early_warning_score, recorded_at DESC),
    INDEX idx_vitals_device (device_id, recorded_at DESC)
) ENGINE=InnoDB
PARTITION BY RANGE (TO_DAYS(recorded_at)) (
    PARTITION p202401 VALUES LESS THAN (TO_DAYS('2024-02-01')),
    PARTITION p202402 VALUES LESS THAN (TO_DAYS('2024-03-01')),
    PARTITION p202403 VALUES LESS THAN (TO_DAYS('2024-04-01')),
    PARTITION p202404 VALUES LESS THAN (TO_DAYS('2024-05-01')),
    PARTITION p202405 VALUES LESS THAN (TO_DAYS('2024-06-01')),
    PARTITION p202406 VALUES LESS THAN (TO_DAYS('2024-07-01'))
);

-- Continuous device readings (high-frequency data)
CREATE TABLE device_readings (
    reading_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    device_id INT NOT NULL,
    patient_id INT,
    timestamp DATETIME(3) NOT NULL,
    metric_type VARCHAR(50) NOT NULL,
    metric_value DECIMAL(10,3),
    metric_unit VARCHAR(20),
    quality_score INT,
    raw_data JSON,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_readings_device (device_id, timestamp DESC),
    INDEX idx_readings_patient (patient_id, timestamp DESC),
    INDEX idx_readings_metric (metric_type, timestamp DESC)
) ENGINE=InnoDB
PARTITION BY RANGE (TO_DAYS(timestamp)) (
    PARTITION p202401 VALUES LESS THAN (TO_DAYS('2024-02-01')),
    PARTITION p202402 VALUES LESS THAN (TO_DAYS('2024-03-01')),
    PARTITION p202403 VALUES LESS THAN (TO_DAYS('2024-04-01')),
    PARTITION p202404 VALUES LESS THAN (TO_DAYS('2024-05-01')),
    PARTITION p202405 VALUES LESS THAN (TO_DAYS('2024-06-01')),
    PARTITION p202406 VALUES LESS THAN (TO_DAYS('2024-07-01'))
);

-- ============================================================================
-- Alerts and Notifications
-- ============================================================================

-- Medical alerts
CREATE TABLE alerts (
    alert_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    admission_id INT,
    device_id INT,
    alert_type ENUM('Critical', 'Warning', 'Info') NOT NULL,
    alert_category ENUM('Vital Signs', 'Device', 'Medication', 'Lab Results', 'Fall', 'Other') NOT NULL,
    alert_code VARCHAR(50),
    alert_message TEXT NOT NULL,
    metric_name VARCHAR(50),
    metric_value DECIMAL(10,3),
    threshold_value DECIMAL(10,3),
    triggered_at DATETIME NOT NULL,
    acknowledged_at DATETIME,
    acknowledged_by INT,
    resolved_at DATETIME,
    resolved_by INT,
    escalated BOOLEAN DEFAULT FALSE,
    response_time_seconds INT,
    actions_taken TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_alert_patient (patient_id, triggered_at DESC),
    INDEX idx_alert_unack (acknowledged_at, alert_type),
    INDEX idx_alert_critical (alert_type, triggered_at DESC),
    INDEX idx_alert_device (device_id, triggered_at DESC)
) ENGINE=InnoDB;

-- Alert rules configuration
CREATE TABLE alert_rules (
    rule_id INT AUTO_INCREMENT PRIMARY KEY,
    rule_name VARCHAR(100) NOT NULL,
    rule_type ENUM('Threshold', 'Trend', 'Pattern', 'Missing Data') NOT NULL,
    metric_type VARCHAR(50) NOT NULL,
    condition_operator ENUM('>', '<', '>=', '<=', '=', '!=', 'BETWEEN', 'OUTSIDE') NOT NULL,
    threshold_value1 DECIMAL(10,3),
    threshold_value2 DECIMAL(10,3),
    time_window_minutes INT,
    severity ENUM('Critical', 'Warning', 'Info') NOT NULL,
    department_id INT,
    is_active BOOLEAN DEFAULT TRUE,
    notification_channels JSON,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_rule_active (is_active, metric_type),
    INDEX idx_rule_dept (department_id, is_active)
) ENGINE=InnoDB;

-- ============================================================================
-- Medications
-- ============================================================================

-- Medication database
CREATE TABLE medications (
    medication_id INT AUTO_INCREMENT PRIMARY KEY,
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
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_med_name (medication_name),
    INDEX idx_med_generic (generic_name),
    INDEX idx_med_ndc (ndc_code)
) ENGINE=InnoDB;

-- Patient prescriptions
CREATE TABLE prescriptions (
    prescription_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    admission_id INT,
    medication_id INT NOT NULL,
    prescribing_physician_id INT NOT NULL,
    dosage VARCHAR(100) NOT NULL,
    frequency VARCHAR(100) NOT NULL,
    route ENUM('Oral', 'IV', 'IM', 'Subcutaneous', 'Topical', 'Inhalation', 'Other') NOT NULL,
    start_date DATETIME NOT NULL,
    end_date DATETIME,
    duration_days INT,
    refills INT DEFAULT 0,
    instructions TEXT,
    is_prn BOOLEAN DEFAULT FALSE,
    prn_reason VARCHAR(200),
    is_active BOOLEAN DEFAULT TRUE,
    discontinued_date DATETIME,
    discontinued_by INT,
    discontinued_reason VARCHAR(200),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_rx_patient (patient_id, is_active),
    INDEX idx_rx_admission (admission_id, is_active),
    INDEX idx_rx_dates (start_date, end_date)
) ENGINE=InnoDB;

-- Medication administration records (MAR)
CREATE TABLE medication_administration (
    administration_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    prescription_id INT NOT NULL,
    patient_id INT NOT NULL,
    scheduled_time DATETIME NOT NULL,
    actual_time DATETIME,
    administered_by INT,
    dosage_given VARCHAR(100),
    route_used VARCHAR(50),
    taken BOOLEAN DEFAULT FALSE,
    missed BOOLEAN DEFAULT FALSE,
    refused BOOLEAN DEFAULT FALSE,
    reason VARCHAR(200),
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_mar_patient (patient_id, scheduled_time),
    INDEX idx_mar_schedule (scheduled_time, taken),
    INDEX idx_mar_prescription (prescription_id, scheduled_time)
) ENGINE=InnoDB;

-- ============================================================================
-- Lab Results
-- ============================================================================

-- Laboratory tests
CREATE TABLE lab_tests (
    test_id INT AUTO_INCREMENT PRIMARY KEY,
    test_code VARCHAR(20) NOT NULL,
    test_name VARCHAR(200) NOT NULL,
    test_category VARCHAR(100),
    specimen_type VARCHAR(50),
    normal_range_low DECIMAL(10,3),
    normal_range_high DECIMAL(10,3),
    unit VARCHAR(20),
    critical_low DECIMAL(10,3),
    critical_high DECIMAL(10,3),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_test_code (test_code),
    INDEX idx_test_name (test_name),
    INDEX idx_test_category (test_category)
) ENGINE=InnoDB;

-- Lab orders
CREATE TABLE lab_orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    admission_id INT,
    ordering_physician_id INT NOT NULL,
    order_date DATETIME NOT NULL,
    priority ENUM('Routine', 'Urgent', 'STAT') NOT NULL,
    tests_ordered JSON NOT NULL,
    specimen_collected BOOLEAN DEFAULT FALSE,
    collected_at DATETIME,
    collected_by INT,
    status ENUM('Ordered', 'Collected', 'Processing', 'Resulted', 'Cancelled') DEFAULT 'Ordered',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_lab_patient (patient_id, order_date DESC),
    INDEX idx_lab_status (status, priority),
    INDEX idx_lab_admission (admission_id)
) ENGINE=InnoDB;

-- Lab results
CREATE TABLE lab_results (
    result_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    test_id INT NOT NULL,
    patient_id INT NOT NULL,
    result_value DECIMAL(10,3),
    result_text VARCHAR(500),
    abnormal_flag ENUM('Normal', 'Low', 'High', 'Critical Low', 'Critical High'),
    reference_range VARCHAR(100),
    resulted_at DATETIME NOT NULL,
    verified_by INT,
    verified_at DATETIME,
    comments TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_result_patient (patient_id, resulted_at DESC),
    INDEX idx_result_order (order_id),
    INDEX idx_result_abnormal (abnormal_flag, resulted_at DESC)
) ENGINE=InnoDB;

-- ============================================================================
-- Clinical Notes and Documentation
-- ============================================================================

-- Clinical notes
CREATE TABLE clinical_notes (
    note_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    admission_id INT,
    note_type ENUM('Progress', 'Admission', 'Discharge', 'Consultation', 'Procedure', 'Nursing') NOT NULL,
    author_id INT NOT NULL,
    note_date DATETIME NOT NULL,
    note_text TEXT NOT NULL,
    is_signed BOOLEAN DEFAULT FALSE,
    signed_at DATETIME,
    cosigner_id INT,
    cosigned_at DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_note_patient (patient_id, note_date DESC),
    INDEX idx_note_admission (admission_id, note_date DESC),
    INDEX idx_note_author (author_id, note_date DESC),
    FULLTEXT idx_note_text (note_text)
) ENGINE=InnoDB;

-- ============================================================================
-- Emergency Response
-- ============================================================================

-- Code blue and rapid response events
CREATE TABLE emergency_events (
    event_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    admission_id INT,
    event_type ENUM('Code Blue', 'Rapid Response', 'Code Stroke', 'Code STEMI', 'Other') NOT NULL,
    location VARCHAR(100) NOT NULL,
    initiated_at DATETIME NOT NULL,
    team_arrived_at DATETIME,
    resolved_at DATETIME,
    initiated_by INT NOT NULL,
    team_lead_id INT,
    outcome ENUM('Stabilized', 'Transferred', 'Deceased', 'False Alarm') ,
    interventions JSON,
    medications_given JSON,
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_emergency_patient (patient_id, initiated_at DESC),
    INDEX idx_emergency_type (event_type, initiated_at DESC),
    INDEX idx_emergency_active (resolved_at, event_type)
) ENGINE=InnoDB;

-- ============================================================================
-- Patient Monitoring Analytics
-- ============================================================================

-- Daily patient summary
CREATE TABLE patient_daily_summary (
    summary_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    admission_id INT NOT NULL,
    summary_date DATE NOT NULL,
    avg_heart_rate DECIMAL(5,2),
    avg_bp_systolic DECIMAL(5,2),
    avg_bp_diastolic DECIMAL(5,2),
    avg_temperature DECIMAL(4,1),
    avg_oxygen_sat DECIMAL(5,2),
    min_oxygen_sat DECIMAL(5,2),
    max_early_warning_score INT,
    alert_count INT,
    critical_alert_count INT,
    medications_administered INT,
    medications_missed INT,
    lab_tests_ordered INT,
    lab_results_abnormal INT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_patient_date (patient_id, admission_id, summary_date),
    INDEX idx_summary_date (summary_date),
    INDEX idx_summary_admission (admission_id, summary_date)
) ENGINE=InnoDB;