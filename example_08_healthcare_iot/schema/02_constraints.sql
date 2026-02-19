-- ============================================================================
-- Healthcare IoT Constraints
-- ============================================================================

USE healthcare_iot;

-- ============================================================================
-- Foreign Key Constraints
-- ============================================================================

-- Departments -> Hospitals
ALTER TABLE departments
    ADD CONSTRAINT fk_dept_hospital
    FOREIGN KEY (hospital_id) REFERENCES hospitals(hospital_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- Rooms -> Departments
ALTER TABLE rooms
    ADD CONSTRAINT fk_room_department
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- Staff -> Hospitals and Departments
ALTER TABLE staff
    ADD CONSTRAINT fk_staff_hospital
    FOREIGN KEY (hospital_id) REFERENCES hospitals(hospital_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
    ADD CONSTRAINT fk_staff_department
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
    ON DELETE SET NULL ON UPDATE CASCADE;

-- Staff schedules -> Staff and Departments
ALTER TABLE staff_schedules
    ADD CONSTRAINT fk_schedule_staff
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
    ADD CONSTRAINT fk_schedule_department
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- Patients -> Primary physician
ALTER TABLE patients
    ADD CONSTRAINT fk_patient_physician
    FOREIGN KEY (primary_physician_id) REFERENCES staff(staff_id)
    ON DELETE SET NULL ON UPDATE CASCADE;

-- Admissions -> Patients, Hospitals, Departments, Rooms, and Physicians
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

-- Devices -> Hospitals, Departments, Rooms, Patients
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

-- Device assignments -> Devices, Patients, Admissions, Staff
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

-- Vital signs -> Patients, Admissions, Devices, Staff
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

-- Device readings -> Devices, Patients
ALTER TABLE device_readings
    ADD CONSTRAINT fk_reading_device
    FOREIGN KEY (device_id) REFERENCES devices(device_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
    ADD CONSTRAINT fk_reading_patient
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
    ON DELETE SET NULL ON UPDATE CASCADE;

-- Alerts -> Patients, Admissions, Devices, Staff
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

-- Alert rules -> Departments
ALTER TABLE alert_rules
    ADD CONSTRAINT fk_rule_department
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
    ON DELETE SET NULL ON UPDATE CASCADE;

-- Prescriptions -> Patients, Admissions, Medications, Staff
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

-- Medication administration -> Prescriptions, Patients, Staff
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

-- Lab orders -> Patients, Admissions, Staff
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

-- Lab results -> Lab orders, Lab tests, Patients, Staff
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

-- Clinical notes -> Patients, Admissions, Staff
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

-- Emergency events -> Patients, Admissions, Staff
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

-- Patient daily summary -> Patients, Admissions
ALTER TABLE patient_daily_summary
    ADD CONSTRAINT fk_summary_patient
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
    ADD CONSTRAINT fk_summary_admission
    FOREIGN KEY (admission_id) REFERENCES admissions(admission_id)
    ON DELETE CASCADE ON UPDATE CASCADE;

-- ============================================================================
-- Check Constraints
-- ============================================================================

-- Ensure valid vital signs ranges
ALTER TABLE vital_signs
    ADD CONSTRAINT chk_heart_rate CHECK (heart_rate BETWEEN 0 AND 300),
    ADD CONSTRAINT chk_respiratory_rate CHECK (respiratory_rate BETWEEN 0 AND 100),
    ADD CONSTRAINT chk_blood_pressure CHECK (systolic_bp BETWEEN 0 AND 300 AND diastolic_bp BETWEEN 0 AND 200),
    ADD CONSTRAINT chk_oxygen_saturation CHECK (oxygen_saturation BETWEEN 0 AND 100),
    ADD CONSTRAINT chk_temperature CHECK (temperature BETWEEN 25 AND 45),
    ADD CONSTRAINT chk_glucose CHECK (blood_glucose BETWEEN 0 AND 1000),
    ADD CONSTRAINT chk_pain_level CHECK (pain_level BETWEEN 0 AND 10);

-- Ensure valid patient data
ALTER TABLE patients
    ADD CONSTRAINT chk_patient_age CHECK (date_of_birth <= '2100-01-01'),
    ADD CONSTRAINT chk_height CHECK (height_cm BETWEEN 0 AND 300),
    ADD CONSTRAINT chk_weight CHECK (weight_kg BETWEEN 0 AND 500);

-- Ensure valid admission dates
ALTER TABLE admissions
    ADD CONSTRAINT chk_admission_dates CHECK (discharge_date IS NULL OR discharge_date >= admission_date);

-- Ensure valid device battery level
ALTER TABLE devices
    ADD CONSTRAINT chk_battery_level CHECK (battery_level BETWEEN 0 AND 100);

-- Ensure valid prescription dates
ALTER TABLE prescriptions
    ADD CONSTRAINT chk_prescription_dates CHECK (end_date IS NULL OR end_date >= start_date);

-- Ensure valid staff schedule times
ALTER TABLE staff_schedules
    ADD CONSTRAINT chk_schedule_times CHECK (shift_end > shift_start);

-- ============================================================================
-- Triggers for Business Logic
-- ============================================================================


-- ============================================================================
-- Unique Constraints
-- ============================================================================

-- Ensure one active admission per patient
ALTER TABLE admissions
    ADD COLUMN active_patient_id INT GENERATED ALWAYS AS (
        CASE WHEN status = 'Active' THEN patient_id ELSE NULL END
    ) STORED,
    ADD UNIQUE INDEX uk_active_admission (active_patient_id);

-- Ensure unique device assignment
ALTER TABLE device_assignments
    ADD COLUMN active_device_id INT GENERATED ALWAYS AS (
        CASE WHEN is_active = TRUE THEN device_id ELSE NULL END
    ) STORED,
    ADD UNIQUE INDEX uk_active_device_assignment (active_device_id);

-- Ensure unique staff schedule
ALTER TABLE staff_schedules
    ADD CONSTRAINT uk_staff_schedule
    UNIQUE KEY (staff_id, shift_date, shift_start);

-- ============================================================================
-- Default Value Constraints
-- ============================================================================

-- Set default timestamps
ALTER TABLE vital_signs
    MODIFY COLUMN created_at DATETIME DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE device_readings
    MODIFY COLUMN created_at DATETIME DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE alerts
    MODIFY COLUMN created_at DATETIME DEFAULT CURRENT_TIMESTAMP;
