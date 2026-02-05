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
    ADD CONSTRAINT chk_patient_age CHECK (date_of_birth <= CURDATE()),
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

DELIMITER $$

-- Trigger to generate alerts for critical vital signs
CREATE TRIGGER trg_vital_signs_alert
AFTER INSERT ON vital_signs
FOR EACH ROW
BEGIN
    DECLARE alert_message TEXT;
    DECLARE alert_type ENUM('Critical', 'Warning', 'Info');
    DECLARE should_alert BOOLEAN DEFAULT FALSE;

    -- Check for critical conditions
    IF NEW.early_warning_score >= 7 THEN
        SET alert_type = 'Critical';
        SET alert_message = CONCAT('Critical Early Warning Score: ', NEW.early_warning_score);
        SET should_alert = TRUE;
    ELSEIF NEW.oxygen_saturation < 88 THEN
        SET alert_type = 'Critical';
        SET alert_message = CONCAT('Critical Low Oxygen Saturation: ', NEW.oxygen_saturation, '%');
        SET should_alert = TRUE;
    ELSEIF NEW.systolic_bp < 90 OR NEW.systolic_bp > 180 THEN
        SET alert_type = 'Critical';
        SET alert_message = CONCAT('Critical Blood Pressure: ', NEW.systolic_bp, '/', NEW.diastolic_bp);
        SET should_alert = TRUE;
    ELSEIF NEW.heart_rate < 40 OR NEW.heart_rate > 150 THEN
        SET alert_type = 'Critical';
        SET alert_message = CONCAT('Critical Heart Rate: ', NEW.heart_rate, ' bpm');
        SET should_alert = TRUE;
    ELSEIF NEW.temperature > 39.5 OR NEW.temperature < 35 THEN
        SET alert_type = 'Warning';
        SET alert_message = CONCAT('Abnormal Temperature: ', NEW.temperature, '°C');
        SET should_alert = TRUE;
    ELSEIF NEW.early_warning_score >= 5 THEN
        SET alert_type = 'Warning';
        SET alert_message = CONCAT('Elevated Early Warning Score: ', NEW.early_warning_score);
        SET should_alert = TRUE;
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

-- Update room occupancy when patient is admitted
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

-- Release room when patient is discharged
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

        -- Unassign devices
        UPDATE device_assignments
        SET is_active = FALSE,
            unassigned_at = NEW.discharge_date
        WHERE patient_id = NEW.patient_id
          AND admission_id = NEW.admission_id
          AND is_active = TRUE;

        -- Update device status
        UPDATE devices
        SET current_patient_id = NULL
        WHERE current_patient_id = NEW.patient_id;
    END IF;
END$$

-- Track device assignment changes
CREATE TRIGGER trg_device_assignment_update
AFTER INSERT ON device_assignments
FOR EACH ROW
BEGIN
    -- Update device's current patient
    UPDATE devices
    SET current_patient_id = NEW.patient_id
    WHERE device_id = NEW.device_id;

    -- Deactivate previous assignments for this device
    UPDATE device_assignments
    SET is_active = FALSE,
        unassigned_at = NEW.assigned_at
    WHERE device_id = NEW.device_id
      AND assignment_id != NEW.assignment_id
      AND is_active = TRUE;
END$$

-- Calculate alert response time
CREATE TRIGGER trg_alert_response_time
BEFORE UPDATE ON alerts
FOR EACH ROW
BEGIN
    IF OLD.acknowledged_at IS NULL AND NEW.acknowledged_at IS NOT NULL THEN
        SET NEW.response_time_seconds = TIMESTAMPDIFF(SECOND, NEW.triggered_at, NEW.acknowledged_at);
    END IF;
END$$

-- Check for medication interactions
CREATE TRIGGER trg_medication_interaction_check
AFTER INSERT ON prescriptions
FOR EACH ROW
BEGIN
    DECLARE interaction_count INT;
    DECLARE interaction_message TEXT;

    -- Simplified interaction check (in production, would use comprehensive drug interaction database)
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

-- Generate medication administration schedule
CREATE TRIGGER trg_generate_mar_schedule
AFTER INSERT ON prescriptions
FOR EACH ROW
BEGIN
    DECLARE current_time DATETIME;
    DECLARE end_time DATETIME;
    DECLARE frequency_hours INT;

    IF NEW.is_active = TRUE AND NEW.is_prn = FALSE THEN
        SET current_time = NEW.start_date;
        SET end_time = COALESCE(NEW.end_date, DATE_ADD(NEW.start_date, INTERVAL NEW.duration_days DAY));

        -- Determine frequency in hours (simplified)
        SET frequency_hours = CASE
            WHEN NEW.frequency LIKE '%QID%' OR NEW.frequency LIKE '%q6h%' THEN 6
            WHEN NEW.frequency LIKE '%TID%' OR NEW.frequency LIKE '%q8h%' THEN 8
            WHEN NEW.frequency LIKE '%BID%' OR NEW.frequency LIKE '%q12h%' THEN 12
            WHEN NEW.frequency LIKE '%Daily%' OR NEW.frequency LIKE '%QD%' THEN 24
            ELSE 24
        END;

        -- Generate administration schedule
        WHILE current_time <= end_time DO
            INSERT INTO medication_administration (
                prescription_id, patient_id, scheduled_time
            ) VALUES (
                NEW.prescription_id, NEW.patient_id, current_time
            );
            SET current_time = DATE_ADD(current_time, INTERVAL frequency_hours HOUR);
        END WHILE;
    END IF;
END$$

-- Update lab order status when results are entered
CREATE TRIGGER trg_lab_result_status
AFTER INSERT ON lab_results
FOR EACH ROW
BEGIN
    UPDATE lab_orders
    SET status = 'Resulted',
        updated_at = NOW()
    WHERE order_id = NEW.order_id;

    -- Generate alert for critical results
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

-- Calculate patient daily summary
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

-- HIPAA audit logging for PHI access
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

-- ============================================================================
-- Unique Constraints
-- ============================================================================

-- Ensure one active admission per patient
CREATE UNIQUE INDEX uk_active_admission
    ON admissions(patient_id, status)
    WHERE status = 'Active';

-- Ensure unique device assignment
CREATE UNIQUE INDEX uk_active_device_assignment
    ON device_assignments(device_id, is_active)
    WHERE is_active = TRUE;

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