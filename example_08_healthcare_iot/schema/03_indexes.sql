-- ============================================================================
-- Healthcare IoT Indexes
-- ============================================================================

USE healthcare_iot;

-- ============================================================================
-- Patient Care Indexes
-- ============================================================================

-- Patient search optimization
CREATE INDEX idx_patient_search
    ON patients(last_name, first_name, date_of_birth);

-- Active admissions lookup
CREATE INDEX idx_active_admissions
    ON admissions(status, hospital_id, department_id);

-- Admission history by patient
CREATE INDEX idx_admission_history
    ON admissions(patient_id, admission_date DESC, discharge_date);

-- Emergency admissions
CREATE INDEX idx_emergency_admissions
    ON admissions(admission_type, admission_date DESC);

-- ============================================================================
-- Vital Signs Monitoring Indexes
-- ============================================================================

-- Real-time monitoring by patient
CREATE INDEX idx_vitals_realtime
    ON vital_signs(patient_id, recorded_at DESC, early_warning_score);

-- High risk patients (EWS >= 5)
CREATE INDEX idx_high_risk_patients
    ON vital_signs(early_warning_score DESC, recorded_at DESC);

-- Critical vital signs
CREATE INDEX idx_critical_vitals
    ON vital_signs(recorded_at DESC);

-- Device-based vital signs
CREATE INDEX idx_vitals_by_device
    ON vital_signs(device_id, recorded_at DESC);

-- Manual vital signs entries
CREATE INDEX idx_manual_vitals
    ON vital_signs(recorded_by, recorded_at DESC);

-- ============================================================================
-- Device Management Indexes
-- ============================================================================

-- Active devices by location
CREATE INDEX idx_device_location
    ON devices(hospital_id, department_id, room_id, is_active);

-- Devices needing maintenance
CREATE INDEX idx_device_maintenance
    ON devices(next_maintenance_date, device_type);

-- Offline devices
CREATE INDEX idx_offline_devices
    ON devices(connectivity_status, last_seen);

-- Device assignments
CREATE INDEX idx_device_assignment_active
    ON device_assignments(patient_id, device_id, is_active);

-- Device readings by metric
CREATE INDEX idx_device_readings_metric
    ON device_readings(metric_type, timestamp DESC);

-- High-frequency device data
CREATE INDEX idx_device_readings_recent
    ON device_readings(device_id, timestamp DESC);

-- ============================================================================
-- Alert Management Indexes
-- ============================================================================

-- Unacknowledged critical alerts
CREATE INDEX idx_unack_critical_alerts
    ON alerts(alert_type, triggered_at DESC, acknowledged_at);

-- All unacknowledged alerts
CREATE INDEX idx_unack_alerts
    ON alerts(acknowledged_at, alert_type, triggered_at DESC);

-- Patient alert history
CREATE INDEX idx_patient_alerts
    ON alerts(patient_id, triggered_at DESC, alert_type);

-- Alert response metrics
CREATE INDEX idx_alert_response
    ON alerts(alert_type, response_time_seconds, triggered_at DESC);

-- Escalated alerts
CREATE INDEX idx_escalated_alerts
    ON alerts(escalated, triggered_at DESC);

-- Alert rules by metric
CREATE INDEX idx_alert_rules_metric
    ON alert_rules(metric_type, is_active, severity);

-- ============================================================================
-- Medication Management Indexes
-- ============================================================================

-- Active prescriptions by patient
CREATE INDEX idx_active_prescriptions
    ON prescriptions(patient_id, is_active, start_date);

-- PRN medications
CREATE INDEX idx_prn_medications
    ON prescriptions(patient_id, is_prn, is_active);

-- Medication administration schedule
CREATE INDEX idx_mar_schedule
    ON medication_administration(scheduled_time, taken, patient_id);

-- Missed medications
CREATE INDEX idx_missed_medications
    ON medication_administration(scheduled_time DESC, patient_id);

-- Medication search
CREATE FULLTEXT INDEX ft_medication_search
    ON medications(medication_name, generic_name);

-- Controlled substances
CREATE INDEX idx_controlled_substances
    ON medications(controlled_substance_schedule);

-- ============================================================================
-- Laboratory Indexes
-- ============================================================================

-- Pending lab orders
CREATE INDEX idx_pending_labs
    ON lab_orders(status, priority, order_date);

-- STAT lab orders
CREATE INDEX idx_stat_labs
    ON lab_orders(priority, order_date DESC);

-- Lab results by patient
CREATE INDEX idx_lab_results_patient
    ON lab_results(patient_id, resulted_at DESC, abnormal_flag);

-- Abnormal lab results
CREATE INDEX idx_abnormal_labs
    ON lab_results(abnormal_flag, resulted_at DESC);

-- ============================================================================
-- Staff Management Indexes
-- ============================================================================

-- Active staff by department
CREATE INDEX idx_staff_department
    ON staff(department_id, role, is_active);

-- Staff license expiry
CREATE INDEX idx_staff_license_expiry
    ON staff(license_expiry, is_active);

-- Staff schedule lookup
CREATE INDEX idx_staff_schedule_lookup
    ON staff_schedules(shift_date, department_id, staff_id);

-- On-call staff
CREATE INDEX idx_oncall_staff
    ON staff_schedules(shift_date, is_on_call, department_id);

-- ============================================================================
-- Clinical Documentation Indexes
-- ============================================================================

-- Clinical notes by patient
CREATE INDEX idx_notes_patient
    ON clinical_notes(patient_id, note_date DESC, note_type);

-- Unsigned notes
CREATE INDEX idx_unsigned_notes
    ON clinical_notes(is_signed, author_id, note_date);

-- Notes requiring cosignature
CREATE INDEX idx_notes_cosign
    ON clinical_notes(cosigner_id, cosigned_at);

-- ============================================================================
-- Emergency Response Indexes
-- ============================================================================

-- Active emergency events
CREATE INDEX idx_active_emergencies
    ON emergency_events(resolved_at, event_type, initiated_at DESC);

-- Emergency event history
CREATE INDEX idx_emergency_history
    ON emergency_events(patient_id, initiated_at DESC, event_type);

-- Code blue events
CREATE INDEX idx_code_blue
    ON emergency_events(event_type, initiated_at DESC);

-- ============================================================================
-- Room and Bed Management Indexes
-- ============================================================================

-- Available rooms
CREATE INDEX idx_available_rooms
    ON rooms(department_id, room_type, is_occupied);

-- ICU beds
CREATE INDEX idx_icu_beds
    ON rooms(is_occupied, room_type);

-- Isolation rooms
CREATE INDEX idx_isolation_rooms
    ON rooms(is_isolation, is_occupied, department_id);

-- ============================================================================
-- Analytics and Reporting Indexes
-- ============================================================================

-- Patient daily summary
CREATE INDEX idx_daily_summary
    ON patient_daily_summary(summary_date DESC, patient_id, max_early_warning_score);

-- High risk summary
CREATE INDEX idx_high_risk_summary
    ON patient_daily_summary(summary_date, max_early_warning_score DESC);

-- Department metrics
CREATE INDEX idx_dept_metrics
    ON admissions(department_id, admission_date, status);

-- Length of stay analysis
CREATE INDEX idx_los_analysis
    ON admissions(admission_date, discharge_date, department_id);

-- ============================================================================
-- Full-Text Search Indexes
-- ============================================================================

-- Patient search
CREATE FULLTEXT INDEX ft_patient_search
    ON patients(first_name, last_name);

-- Staff search
CREATE FULLTEXT INDEX ft_staff_search
    ON staff(first_name, last_name, specialization);

-- Clinical notes search
-- Already created in tables: ft_note_text

-- Alert message search
CREATE FULLTEXT INDEX ft_alert_search
    ON alerts(alert_message);

-- ============================================================================
-- Covering Indexes for Common Queries
-- ============================================================================

-- Patient monitoring dashboard
CREATE INDEX idx_patient_monitor_dashboard
    ON vital_signs(patient_id, recorded_at DESC, heart_rate, oxygen_saturation,
                  systolic_bp, temperature, early_warning_score);

-- Department census
CREATE INDEX idx_department_census
    ON admissions(department_id, status, admission_date, patient_id);

-- Medication due list
CREATE INDEX idx_medication_due
    ON medication_administration(scheduled_time, taken, patient_id, prescription_id);

-- Device status dashboard
CREATE INDEX idx_device_dashboard
    ON devices(hospital_id, connectivity_status, device_type, last_seen, battery_level);

-- ============================================================================
-- Partitioned Table Optimization
-- ============================================================================

-- Create hourly aggregates for high-frequency data
CREATE TABLE IF NOT EXISTS vital_signs_hourly (
    patient_id INT NOT NULL,
    admission_id INT,
    hour_timestamp DATETIME NOT NULL,
    avg_heart_rate DECIMAL(5,2),
    avg_respiratory_rate DECIMAL(5,2),
    avg_systolic_bp DECIMAL(5,2),
    avg_diastolic_bp DECIMAL(5,2),
    avg_oxygen_sat DECIMAL(5,2),
    avg_temperature DECIMAL(4,1),
    max_early_warning_score INT,
    reading_count INT,
    PRIMARY KEY (patient_id, hour_timestamp),
    INDEX idx_hourly_lookup (hour_timestamp, patient_id),
    INDEX idx_hourly_admission (admission_id, hour_timestamp)
) ENGINE=InnoDB;

-- ============================================================================
-- Statistics Update
-- ============================================================================

-- Update table statistics for optimal query planning
ANALYZE TABLE hospitals;
ANALYZE TABLE departments;
ANALYZE TABLE rooms;
ANALYZE TABLE staff;
ANALYZE TABLE patients;
ANALYZE TABLE admissions;
ANALYZE TABLE devices;
ANALYZE TABLE device_assignments;
ANALYZE TABLE vital_signs;
ANALYZE TABLE device_readings;
ANALYZE TABLE alerts;
ANALYZE TABLE prescriptions;
ANALYZE TABLE medication_administration;
ANALYZE TABLE lab_orders;
ANALYZE TABLE lab_results;
ANALYZE TABLE clinical_notes;
