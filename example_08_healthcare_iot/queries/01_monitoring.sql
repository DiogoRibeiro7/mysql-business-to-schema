-- ============================================================================
-- Healthcare IoT Real-time Monitoring Queries
-- ============================================================================

USE healthcare_iot;

-- Smoke test for CI query runner
SELECT 1 AS query_smoke_test;

-- ============================================================================
-- Patient Vital Signs Monitoring Dashboard
-- ============================================================================

-- Current patient vital signs with early warning scores
WITH latest_vitals AS (
    SELECT
        v.patient_id,
        v.admission_id,
        v.recorded_at,
        v.heart_rate,
        v.respiratory_rate,
        v.systolic_bp,
        v.diastolic_bp,
        v.oxygen_saturation,
        v.temperature,
        v.blood_glucose,
        v.pain_level,
        v.consciousness_level,
        v.early_warning_score,
        v.device_id,
        v.is_manual_entry,
        ROW_NUMBER() OVER (PARTITION BY v.patient_id ORDER BY v.recorded_at DESC) AS rn
    FROM vital_signs v
    INNER JOIN admissions a ON v.patient_id = a.patient_id
    WHERE a.status = 'Active'
      AND v.recorded_at >= NOW() - INTERVAL 2 HOUR
)
SELECT
    p.medical_record_number,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    p.date_of_birth,
    TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) AS age,
    d.department_name,
    r.room_number,
    lv.recorded_at AS last_reading,
    TIMESTAMPDIFF(MINUTE, lv.recorded_at, NOW()) AS minutes_since_reading,
    lv.heart_rate,
    lv.respiratory_rate,
    CONCAT(lv.systolic_bp, '/', lv.diastolic_bp) AS blood_pressure,
    lv.oxygen_saturation,
    lv.temperature,
    lv.blood_glucose,
    lv.pain_level,
    lv.consciousness_level,
    lv.early_warning_score,
    CASE
        WHEN lv.early_warning_score >= 7 THEN 'CRITICAL'
        WHEN lv.early_warning_score >= 5 THEN 'HIGH'
        WHEN lv.early_warning_score >= 3 THEN 'MEDIUM'
        WHEN lv.early_warning_score >= 1 THEN 'LOW'
        ELSE 'STABLE'
    END AS risk_level,
    CASE
        WHEN lv.device_id IS NOT NULL THEN 'Continuous'
        ELSE 'Manual'
    END AS monitoring_type,
    CONCAT(s.first_name, ' ', s.last_name) AS attending_physician
FROM latest_vitals lv
INNER JOIN patients p ON lv.patient_id = p.patient_id
INNER JOIN admissions a ON lv.admission_id = a.admission_id
INNER JOIN departments d ON a.department_id = d.department_id
LEFT JOIN rooms r ON a.room_id = r.room_id
LEFT JOIN staff s ON a.attending_physician_id = s.staff_id
WHERE lv.rn = 1
ORDER BY lv.early_warning_score DESC, lv.recorded_at DESC;

-- ============================================================================
-- Critical Alerts Monitoring
-- ============================================================================

-- Active unacknowledged alerts
SELECT
    a.alert_id,
    p.medical_record_number,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    d.department_name,
    r.room_number,
    a.alert_type,
    a.alert_category,
    a.alert_message,
    a.triggered_at,
    TIMESTAMPDIFF(MINUTE, a.triggered_at, NOW()) AS minutes_unacknowledged,
    a.metric_name,
    a.metric_value,
    a.threshold_value,
    CASE
        WHEN a.escalated = TRUE THEN 'ESCALATED'
        WHEN TIMESTAMPDIFF(MINUTE, a.triggered_at, NOW()) > 15 THEN 'OVERDUE'
        WHEN TIMESTAMPDIFF(MINUTE, a.triggered_at, NOW()) > 10 THEN 'URGENT'
        ELSE 'PENDING'
    END AS alert_status,
    dev.device_serial,
    dev.device_type
FROM alerts a
INNER JOIN patients p ON a.patient_id = p.patient_id
INNER JOIN admissions ad ON a.patient_id = ad.patient_id AND ad.status = 'Active'
INNER JOIN departments d ON ad.department_id = d.department_id
LEFT JOIN rooms r ON ad.room_id = r.room_id
LEFT JOIN devices dev ON a.device_id = dev.device_id
WHERE a.acknowledged_at IS NULL
  AND a.triggered_at >= NOW() - INTERVAL 24 HOUR
ORDER BY
    CASE a.alert_type
        WHEN 'Critical' THEN 1
        WHEN 'Warning' THEN 2
        ELSE 3
    END,
    a.triggered_at ASC;

-- ============================================================================
-- Device Status Monitoring
-- ============================================================================

-- Real-time device status and connectivity
SELECT
    d.device_serial,
    d.device_type,
    d.manufacturer,
    d.model,
    dept.department_name,
    r.room_number,
    CONCAT(p.first_name, ' ', p.last_name) AS assigned_patient,
    d.connectivity_status,
    d.last_seen,
    TIMESTAMPDIFF(MINUTE, d.last_seen, NOW()) AS minutes_offline,
    d.battery_level,
    CASE
        WHEN d.battery_level < 10 THEN 'CRITICAL'
        WHEN d.battery_level < 25 THEN 'LOW'
        ELSE 'OK'
    END AS battery_status,
    DATEDIFF(d.next_maintenance_date, CURDATE()) AS days_to_maintenance,
    CASE
        WHEN d.connectivity_status = 'Offline' AND TIMESTAMPDIFF(MINUTE, d.last_seen, NOW()) > 30 THEN 'DEVICE OFFLINE'
        WHEN d.battery_level < 10 THEN 'BATTERY CRITICAL'
        WHEN DATEDIFF(d.next_maintenance_date, CURDATE()) <= 0 THEN 'MAINTENANCE OVERDUE'
        WHEN DATEDIFF(d.next_maintenance_date, CURDATE()) <= 7 THEN 'MAINTENANCE DUE SOON'
        ELSE 'OPERATIONAL'
    END AS device_alert
FROM devices d
LEFT JOIN departments dept ON d.department_id = dept.department_id
LEFT JOIN rooms r ON d.room_id = r.room_id
LEFT JOIN patients p ON d.current_patient_id = p.patient_id
WHERE d.is_active = TRUE
  AND (d.connectivity_status = 'Offline'
       OR d.battery_level < 25
       OR DATEDIFF(d.next_maintenance_date, CURDATE()) <= 7)
ORDER BY
    CASE
        WHEN d.connectivity_status = 'Offline' THEN 1
        WHEN d.battery_level < 10 THEN 2
        ELSE 3
    END,
    d.last_seen DESC;

-- ============================================================================
-- Medication Administration Monitoring
-- ============================================================================

-- Medications due in next 2 hours
SELECT
    p.medical_record_number,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    d.department_name,
    r.room_number,
    m.medication_name,
    pr.dosage,
    pr.frequency,
    pr.route,
    ma.scheduled_time,
    TIMESTAMPDIFF(MINUTE, NOW(), ma.scheduled_time) AS minutes_until_due,
    pr.is_prn,
    pr.prn_reason,
    CASE
        WHEN ma.scheduled_time < NOW() THEN 'OVERDUE'
        WHEN TIMESTAMPDIFF(MINUTE, NOW(), ma.scheduled_time) <= 30 THEN 'DUE SOON'
        ELSE 'SCHEDULED'
    END AS status,
    m.controlled_substance_schedule,
    pr.instructions
FROM medication_administration ma
INNER JOIN prescriptions pr ON ma.prescription_id = pr.prescription_id
INNER JOIN patients p ON ma.patient_id = p.patient_id
INNER JOIN medications m ON pr.medication_id = m.medication_id
INNER JOIN admissions a ON p.patient_id = a.patient_id AND a.status = 'Active'
INNER JOIN departments d ON a.department_id = d.department_id
LEFT JOIN rooms r ON a.room_id = r.room_id
WHERE ma.taken = FALSE
  AND ma.missed = FALSE
  AND ma.scheduled_time BETWEEN NOW() - INTERVAL 30 MINUTE AND NOW() + INTERVAL 2 HOUR
  AND pr.is_active = TRUE
ORDER BY ma.scheduled_time ASC, p.last_name;

-- ============================================================================
-- High-Risk Patients Monitoring
-- ============================================================================

-- Patients with elevated early warning scores
WITH risk_trends AS (
    SELECT
        v.patient_id,
        v.admission_id,
        AVG(v.early_warning_score) AS avg_ews,
        MAX(v.early_warning_score) AS max_ews,
        MIN(v.early_warning_score) AS min_ews,
        COUNT(*) AS reading_count,
        SUM(CASE WHEN v.early_warning_score >= 7 THEN 1 ELSE 0 END) AS critical_readings,
        SUM(CASE WHEN v.early_warning_score >= 5 THEN 1 ELSE 0 END) AS high_readings
    FROM vital_signs v
    WHERE v.recorded_at >= NOW() - INTERVAL 6 HOUR
    GROUP BY v.patient_id, v.admission_id
)
SELECT
    p.medical_record_number,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) AS age,
    d.department_name,
    r.room_number,
    rt.max_ews AS max_ews_6h,
    ROUND(rt.avg_ews, 1) AS avg_ews_6h,
    rt.critical_readings,
    rt.high_readings,
    rt.reading_count AS total_readings,
    ROUND((rt.critical_readings + rt.high_readings) / rt.reading_count * 100, 1) AS risk_percentage,
    COUNT(DISTINCT al.alert_id) AS active_alerts,
    a.chief_complaint,
    DATEDIFF(NOW(), a.admission_date) AS days_admitted,
    CONCAT(s.first_name, ' ', s.last_name) AS attending_physician
FROM risk_trends rt
INNER JOIN patients p ON rt.patient_id = p.patient_id
INNER JOIN admissions a ON rt.admission_id = a.admission_id
INNER JOIN departments d ON a.department_id = d.department_id
LEFT JOIN rooms r ON a.room_id = r.room_id
LEFT JOIN staff s ON a.attending_physician_id = s.staff_id
LEFT JOIN alerts al ON p.patient_id = al.patient_id
    AND al.acknowledged_at IS NULL
    AND al.triggered_at >= NOW() - INTERVAL 6 HOUR
WHERE rt.max_ews >= 5
   OR rt.critical_readings > 0
   OR (rt.high_readings / rt.reading_count) > 0.3
GROUP BY rt.patient_id, rt.admission_id
ORDER BY rt.max_ews DESC, rt.avg_ews DESC;

-- ============================================================================
-- Emergency Response Monitoring
-- ============================================================================

-- Active emergency events
SELECT
    e.event_id,
    e.event_type,
    p.medical_record_number,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    e.location,
    e.initiated_at,
    TIMESTAMPDIFF(MINUTE, e.initiated_at, NOW()) AS duration_minutes,
    CONCAT(si.first_name, ' ', si.last_name) AS initiated_by,
    CONCAT(st.first_name, ' ', st.last_name) AS team_lead,
    e.team_arrived_at,
    CASE
        WHEN e.team_arrived_at IS NOT NULL THEN
            TIMESTAMPDIFF(SECOND, e.initiated_at, e.team_arrived_at)
        ELSE NULL
    END AS response_time_seconds,
    JSON_LENGTH(e.interventions) AS intervention_count,
    JSON_LENGTH(e.medications_given) AS medications_count
FROM emergency_events e
INNER JOIN patients p ON e.patient_id = p.patient_id
INNER JOIN staff si ON e.initiated_by = si.staff_id
LEFT JOIN staff st ON e.team_lead_id = st.staff_id
WHERE e.resolved_at IS NULL
  AND e.initiated_at >= NOW() - INTERVAL 24 HOUR
ORDER BY e.initiated_at DESC;

-- ============================================================================
-- Laboratory Results Monitoring
-- ============================================================================

-- Critical lab results pending review
SELECT
    p.medical_record_number,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    d.department_name,
    r.room_number,
    lt.test_name,
    lr.result_value,
    lr.result_text,
    lr.abnormal_flag,
    lr.reference_range,
    lr.resulted_at,
    TIMESTAMPDIFF(MINUTE, lr.resulted_at, NOW()) AS minutes_since_result,
    CASE
        WHEN lr.verified_at IS NULL THEN 'PENDING VERIFICATION'
        ELSE 'VERIFIED'
    END AS verification_status,
    lo.priority AS order_priority,
    CONCAT(s.first_name, ' ', s.last_name) AS ordering_physician
FROM lab_results lr
INNER JOIN lab_orders lo ON lr.order_id = lo.order_id
INNER JOIN lab_tests lt ON lr.test_id = lt.test_id
INNER JOIN patients p ON lr.patient_id = p.patient_id
INNER JOIN admissions a ON p.patient_id = a.patient_id AND a.status = 'Active'
INNER JOIN departments d ON a.department_id = d.department_id
LEFT JOIN rooms r ON a.room_id = r.room_id
INNER JOIN staff s ON lo.ordering_physician_id = s.staff_id
WHERE lr.abnormal_flag IN ('Critical Low', 'Critical High')
  AND lr.resulted_at >= NOW() - INTERVAL 24 HOUR
ORDER BY
    CASE
        WHEN lr.verified_at IS NULL THEN 0
        ELSE 1
    END,
    lr.resulted_at DESC;

-- ============================================================================
-- Staff Coverage Monitoring
-- ============================================================================

-- Current staff on duty by department
SELECT
    d.department_name,
    d.department_type,
    COUNT(DISTINCT CASE WHEN s.role = 'Doctor' THEN ss.staff_id END) AS doctors_on_duty,
    COUNT(DISTINCT CASE WHEN s.role = 'Nurse' THEN ss.staff_id END) AS nurses_on_duty,
    COUNT(DISTINCT CASE WHEN s.role = 'Technician' THEN ss.staff_id END) AS technicians_on_duty,
    COUNT(DISTINCT ss.staff_id) AS total_staff,
    COUNT(DISTINCT a.admission_id) AS active_patients,
    ROUND(COUNT(DISTINCT a.admission_id) / NULLIF(COUNT(DISTINCT CASE WHEN s.role = 'Nurse' THEN ss.staff_id END), 0), 1) AS patient_nurse_ratio,
    GROUP_CONCAT(DISTINCT
        CASE WHEN ss.is_on_call = TRUE THEN CONCAT(s.first_name, ' ', s.last_name) END
        SEPARATOR ', '
    ) AS on_call_staff
FROM departments d
LEFT JOIN staff_schedules ss ON d.department_id = ss.department_id
    AND ss.shift_date = CURDATE()
    AND CURTIME() BETWEEN ss.shift_start AND ss.shift_end
LEFT JOIN staff s ON ss.staff_id = s.staff_id
LEFT JOIN admissions a ON d.department_id = a.department_id AND a.status = 'Active'
WHERE d.is_active = TRUE
GROUP BY d.department_id
ORDER BY d.department_type, d.department_name;

-- ============================================================================
-- Bed Management Monitoring
-- ============================================================================

-- Real-time bed availability
SELECT
    h.hospital_name,
    d.department_name,
    d.department_type,
    r.room_type,
    COUNT(*) AS total_beds,
    SUM(CASE WHEN r.is_occupied = FALSE THEN 1 ELSE 0 END) AS available_beds,
    SUM(CASE WHEN r.is_occupied = TRUE THEN 1 ELSE 0 END) AS occupied_beds,
    ROUND(SUM(CASE WHEN r.is_occupied = TRUE THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS occupancy_rate,
    SUM(CASE WHEN r.is_isolation = TRUE AND r.is_occupied = FALSE THEN 1 ELSE 0 END) AS available_isolation,
    SUM(CASE WHEN r.has_monitoring = TRUE AND r.is_occupied = FALSE THEN 1 ELSE 0 END) AS available_monitored
FROM hospitals h
INNER JOIN departments d ON h.hospital_id = d.hospital_id
INNER JOIN rooms r ON d.department_id = r.department_id
WHERE d.is_active = TRUE
GROUP BY h.hospital_id, d.department_id, r.room_type
ORDER BY h.hospital_name, d.department_type, d.department_name, r.room_type;

-- ============================================================================
-- Medication Compliance Monitoring
-- ============================================================================

-- Recent medication administration compliance
SELECT
    d.department_name,
    DATE(ma.scheduled_time) AS administration_date,
    COUNT(*) AS total_scheduled,
    SUM(CASE WHEN ma.taken = TRUE THEN 1 ELSE 0 END) AS administered,
    SUM(CASE WHEN ma.missed = TRUE THEN 1 ELSE 0 END) AS missed,
    SUM(CASE WHEN ma.refused = TRUE THEN 1 ELSE 0 END) AS refused,
    SUM(CASE WHEN ma.taken = FALSE AND ma.missed = FALSE AND ma.scheduled_time < NOW() THEN 1 ELSE 0 END) AS overdue,
    ROUND(SUM(CASE WHEN ma.taken = TRUE THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS compliance_rate
FROM medication_administration ma
INNER JOIN patients p ON ma.patient_id = p.patient_id
INNER JOIN admissions a ON p.patient_id = a.patient_id AND a.status = 'Active'
INNER JOIN departments d ON a.department_id = d.department_id
WHERE ma.scheduled_time >= NOW() - INTERVAL 24 HOUR
  AND ma.scheduled_time <= NOW()
GROUP BY d.department_id, DATE(ma.scheduled_time)
ORDER BY administration_date DESC, d.department_name;
