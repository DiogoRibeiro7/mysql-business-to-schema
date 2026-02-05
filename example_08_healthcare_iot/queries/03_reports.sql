-- ============================================================================
-- Healthcare IoT Executive Reports
-- ============================================================================

USE healthcare_iot;

-- ============================================================================
-- Hospital Executive Dashboard
-- ============================================================================

-- Hospital-wide KPI summary
SELECT
    h.hospital_name,
    h.bed_capacity,
    -- Census metrics
    COUNT(DISTINCT a.admission_id) AS current_census,
    ROUND(COUNT(DISTINCT a.admission_id) / h.bed_capacity * 100, 1) AS occupancy_rate,
    COUNT(DISTINCT CASE WHEN a.admission_type = 'Emergency' THEN a.admission_id END) AS emergency_admissions,
    COUNT(DISTINCT CASE WHEN a.admission_type = 'Scheduled' THEN a.admission_id END) AS scheduled_admissions,
    -- Staff metrics
    COUNT(DISTINCT s.staff_id) AS total_staff,
    COUNT(DISTINCT CASE WHEN s.role = 'Doctor' THEN s.staff_id END) AS doctors,
    COUNT(DISTINCT CASE WHEN s.role = 'Nurse' THEN s.staff_id END) AS nurses,
    ROUND(COUNT(DISTINCT a.admission_id) / NULLIF(COUNT(DISTINCT CASE WHEN s.role = 'Nurse' THEN s.staff_id END), 0), 1) AS patient_nurse_ratio,
    -- Device metrics
    COUNT(DISTINCT d.device_id) AS total_devices,
    COUNT(DISTINCT CASE WHEN d.connectivity_status = 'Online' THEN d.device_id END) AS online_devices,
    ROUND(COUNT(DISTINCT CASE WHEN d.connectivity_status = 'Online' THEN d.device_id END) / COUNT(DISTINCT d.device_id) * 100, 1) AS device_online_rate,
    -- Alert metrics (24h)
    COUNT(DISTINCT al.alert_id) AS alerts_24h,
    COUNT(DISTINCT CASE WHEN al.alert_type = 'Critical' THEN al.alert_id END) AS critical_alerts_24h,
    AVG(al.response_time_seconds) AS avg_alert_response_seconds
FROM hospitals h
LEFT JOIN admissions a ON h.hospital_id = a.hospital_id AND a.status = 'Active'
LEFT JOIN staff s ON h.hospital_id = s.hospital_id AND s.is_active = TRUE
LEFT JOIN devices d ON h.hospital_id = d.hospital_id AND d.is_active = TRUE
LEFT JOIN alerts al ON a.admission_id = al.admission_id
    AND al.triggered_at >= NOW() - INTERVAL 24 HOUR
GROUP BY h.hospital_id;

-- ============================================================================
-- Monthly Performance Report
-- ============================================================================

-- Monthly operational metrics
WITH monthly_metrics AS (
    SELECT
        DATE_FORMAT(a.admission_date, '%Y-%m') AS month,
        COUNT(DISTINCT a.admission_id) AS total_admissions,
        COUNT(DISTINCT a.patient_id) AS unique_patients,
        AVG(DATEDIFF(COALESCE(a.discharge_date, CURDATE()), a.admission_date)) AS avg_los,
        COUNT(DISTINCT CASE WHEN a.admission_type = 'Emergency' THEN a.admission_id END) AS emergency_admissions,
        COUNT(DISTINCT CASE WHEN a.discharge_disposition = 'Deceased' THEN a.admission_id END) AS mortalities,
        SUM(a.total_charges) AS total_revenue,
        AVG(a.total_charges) AS avg_charge_per_admission
    FROM admissions a
    WHERE a.admission_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
    GROUP BY DATE_FORMAT(a.admission_date, '%Y-%m')
),
monthly_quality AS (
    SELECT
        DATE_FORMAT(al.triggered_at, '%Y-%m') AS month,
        COUNT(al.alert_id) AS total_alerts,
        AVG(al.response_time_seconds) AS avg_response_time,
        COUNT(DISTINCT ee.event_id) AS emergency_events
    FROM alerts al
    LEFT JOIN emergency_events ee ON DATE_FORMAT(al.triggered_at, '%Y-%m') = DATE_FORMAT(ee.initiated_at, '%Y-%m')
    WHERE al.triggered_at >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
    GROUP BY DATE_FORMAT(al.triggered_at, '%Y-%m')
)
SELECT
    mm.month,
    mm.total_admissions,
    mm.unique_patients,
    ROUND(mm.avg_los, 1) AS avg_los_days,
    mm.emergency_admissions,
    ROUND(mm.emergency_admissions / mm.total_admissions * 100, 1) AS emergency_pct,
    mm.mortalities,
    ROUND(mm.mortalities / mm.total_admissions * 100, 2) AS mortality_rate,
    FORMAT(mm.total_revenue, 2) AS total_revenue,
    FORMAT(mm.avg_charge_per_admission, 2) AS avg_charge,
    mq.total_alerts,
    ROUND(mq.avg_response_time / 60, 1) AS avg_alert_response_min,
    mq.emergency_events
FROM monthly_metrics mm
LEFT JOIN monthly_quality mq ON mm.month = mq.month
ORDER BY mm.month DESC;

-- ============================================================================
-- Department Performance Report
-- ============================================================================

-- Department comparative analysis
WITH dept_performance AS (
    SELECT
        d.department_name,
        d.department_type,
        d.bed_count,
        COUNT(DISTINCT a.admission_id) AS admissions_30d,
        COUNT(DISTINCT CASE WHEN a.status = 'Active' THEN a.admission_id END) AS current_census,
        AVG(DATEDIFF(COALESCE(a.discharge_date, CURDATE()), a.admission_date)) AS avg_los,
        COUNT(DISTINCT CASE WHEN a.discharge_disposition = 'Deceased' THEN a.admission_id END) AS mortalities
    FROM departments d
    LEFT JOIN admissions a ON d.department_id = a.department_id
        AND a.admission_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    WHERE d.is_active = TRUE
    GROUP BY d.department_id
),
dept_quality AS (
    SELECT
        d.department_id,
        AVG(v.early_warning_score) AS avg_ews,
        MAX(v.early_warning_score) AS max_ews,
        COUNT(DISTINCT al.alert_id) AS alert_count,
        AVG(al.response_time_seconds) AS avg_response_time
    FROM departments d
    LEFT JOIN admissions a ON d.department_id = a.department_id AND a.status = 'Active'
    LEFT JOIN vital_signs v ON a.admission_id = v.admission_id
        AND v.recorded_at >= NOW() - INTERVAL 24 HOUR
    LEFT JOIN alerts al ON a.admission_id = al.admission_id
        AND al.triggered_at >= NOW() - INTERVAL 30 DAY
    GROUP BY d.department_id
)
SELECT
    dp.department_name,
    dp.department_type,
    dp.bed_count,
    dp.current_census,
    ROUND(dp.current_census / NULLIF(dp.bed_count, 0) * 100, 1) AS occupancy_rate,
    dp.admissions_30d,
    ROUND(dp.avg_los, 1) AS avg_los_days,
    dp.mortalities,
    ROUND(dp.mortalities / NULLIF(dp.admissions_30d, 0) * 100, 2) AS mortality_rate_30d,
    ROUND(dq.avg_ews, 1) AS avg_patient_ews,
    dq.max_ews AS max_patient_ews,
    dq.alert_count AS alerts_30d,
    ROUND(dq.avg_response_time / 60, 1) AS avg_alert_response_min,
    RANK() OVER (ORDER BY dp.current_census / NULLIF(dp.bed_count, 0) DESC) AS occupancy_rank,
    RANK() OVER (ORDER BY dp.avg_los) AS los_rank
FROM dept_performance dp
LEFT JOIN dept_quality dq ON dp.department_name =
    (SELECT department_name FROM departments WHERE department_id = dq.department_id)
ORDER BY dp.department_type, dp.department_name;

-- ============================================================================
-- Clinical Quality Report
-- ============================================================================

-- Clinical quality indicators
WITH quality_metrics AS (
    SELECT
        'Medication Compliance' AS metric,
        ROUND(AVG(CASE WHEN ma.taken = TRUE THEN 1 ELSE 0 END) * 100, 1) AS value,
        '%' AS unit
    FROM medication_administration ma
    WHERE ma.scheduled_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
      AND ma.scheduled_time <= NOW()

    UNION ALL

    SELECT
        'Alert Response Time (Critical)',
        ROUND(AVG(response_time_seconds) / 60, 1),
        'minutes'
    FROM alerts
    WHERE alert_type = 'Critical'
      AND acknowledged_at IS NOT NULL
      AND triggered_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)

    UNION ALL

    SELECT
        'Lab TAT (STAT Orders)',
        ROUND(AVG(TIMESTAMPDIFF(MINUTE, lo.order_date, lr.resulted_at)), 0),
        'minutes'
    FROM lab_results lr
    INNER JOIN lab_orders lo ON lr.order_id = lo.order_id
    WHERE lo.priority = 'STAT'
      AND lo.order_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)

    UNION ALL

    SELECT
        'High EWS Patients (≥5)',
        COUNT(DISTINCT patient_id),
        'patients'
    FROM vital_signs
    WHERE early_warning_score >= 5
      AND recorded_at >= NOW() - INTERVAL 24 HOUR

    UNION ALL

    SELECT
        'Device Uptime',
        ROUND(AVG(CASE WHEN connectivity_status = 'Online' THEN 1 ELSE 0 END) * 100, 1),
        '%'
    FROM devices
    WHERE is_active = TRUE

    UNION ALL

    SELECT
        '30-Day Readmission Rate',
        ROUND(COUNT(DISTINCT a2.admission_id) / COUNT(DISTINCT a1.admission_id) * 100, 2),
        '%'
    FROM admissions a1
    LEFT JOIN admissions a2 ON a1.patient_id = a2.patient_id
        AND a2.admission_date > a1.discharge_date
        AND a2.admission_date <= DATE_ADD(a1.discharge_date, INTERVAL 30 DAY)
    WHERE a1.discharge_date >= DATE_SUB(CURDATE(), INTERVAL 60 DAY)
      AND a1.discharge_date <= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
)
SELECT
    metric AS quality_indicator,
    value AS current_value,
    unit,
    CASE
        WHEN metric = 'Medication Compliance' AND value >= 95 THEN 'Excellent'
        WHEN metric = 'Medication Compliance' AND value >= 90 THEN 'Good'
        WHEN metric = 'Medication Compliance' THEN 'Needs Improvement'
        WHEN metric = 'Alert Response Time (Critical)' AND value <= 5 THEN 'Excellent'
        WHEN metric = 'Alert Response Time (Critical)' AND value <= 10 THEN 'Good'
        WHEN metric = 'Alert Response Time (Critical)' THEN 'Needs Improvement'
        WHEN metric = 'Lab TAT (STAT Orders)' AND value <= 30 THEN 'Excellent'
        WHEN metric = 'Lab TAT (STAT Orders)' AND value <= 60 THEN 'Good'
        WHEN metric = 'Lab TAT (STAT Orders)' THEN 'Needs Improvement'
        WHEN metric = 'Device Uptime' AND value >= 99 THEN 'Excellent'
        WHEN metric = 'Device Uptime' AND value >= 95 THEN 'Good'
        WHEN metric = 'Device Uptime' THEN 'Needs Improvement'
        WHEN metric = '30-Day Readmission Rate' AND value <= 10 THEN 'Excellent'
        WHEN metric = '30-Day Readmission Rate' AND value <= 15 THEN 'Good'
        WHEN metric = '30-Day Readmission Rate' THEN 'Needs Improvement'
        ELSE 'Monitor'
    END AS performance_level
FROM quality_metrics;

-- ============================================================================
-- Staff Productivity Report
-- ============================================================================

-- Staff productivity metrics
WITH staff_metrics AS (
    SELECT
        s.staff_id,
        s.role,
        CONCAT(s.first_name, ' ', s.last_name) AS staff_name,
        s.department_id,
        d.department_name,
        COUNT(DISTINCT v.reading_id) AS vitals_recorded,
        COUNT(DISTINCT ma.administration_id) AS medications_administered,
        COUNT(DISTINCT cn.note_id) AS notes_written,
        COUNT(DISTINCT al.alert_id) AS alerts_acknowledged,
        AVG(al.response_time_seconds) AS avg_alert_response
    FROM staff s
    INNER JOIN departments d ON s.department_id = d.department_id
    LEFT JOIN vital_signs v ON s.staff_id = v.recorded_by
        AND v.recorded_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    LEFT JOIN medication_administration ma ON s.staff_id = ma.administered_by
        AND ma.actual_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    LEFT JOIN clinical_notes cn ON s.staff_id = cn.author_id
        AND cn.note_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    LEFT JOIN alerts al ON s.staff_id = al.acknowledged_by
        AND al.acknowledged_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    WHERE s.is_active = TRUE
    GROUP BY s.staff_id
)
SELECT
    role,
    department_name,
    COUNT(DISTINCT staff_id) AS staff_count,
    AVG(vitals_recorded) AS avg_vitals_per_staff,
    AVG(medications_administered) AS avg_meds_per_staff,
    AVG(notes_written) AS avg_notes_per_staff,
    AVG(alerts_acknowledged) AS avg_alerts_per_staff,
    ROUND(AVG(avg_alert_response) / 60, 1) AS avg_alert_response_min,
    SUM(vitals_recorded + medications_administered + notes_written) AS total_activities
FROM staff_metrics
GROUP BY role, department_name
ORDER BY role, total_activities DESC;

-- ============================================================================
-- Patient Safety Report
-- ============================================================================

-- Patient safety events summary
SELECT
    'Critical Alerts (24h)' AS safety_metric,
    COUNT(*) AS occurrences,
    COUNT(DISTINCT patient_id) AS patients_affected,
    ROUND(AVG(response_time_seconds) / 60, 1) AS avg_response_min,
    SUM(CASE WHEN escalated = TRUE THEN 1 ELSE 0 END) AS escalations
FROM alerts
WHERE alert_type = 'Critical'
  AND triggered_at >= NOW() - INTERVAL 24 HOUR

UNION ALL

SELECT
    'Emergency Events (7d)',
    COUNT(*),
    COUNT(DISTINCT patient_id),
    ROUND(AVG(TIMESTAMPDIFF(SECOND, initiated_at, team_arrived_at)) / 60, 1),
    NULL
FROM emergency_events
WHERE initiated_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)

UNION ALL

SELECT
    'High EWS (≥7) (24h)',
    COUNT(*),
    COUNT(DISTINCT patient_id),
    NULL,
    NULL
FROM vital_signs
WHERE early_warning_score >= 7
  AND recorded_at >= NOW() - INTERVAL 24 HOUR

UNION ALL

SELECT
    'Medication Errors (30d)',
    COUNT(*),
    COUNT(DISTINCT patient_id),
    NULL,
    NULL
FROM medication_administration
WHERE (missed = TRUE OR refused = TRUE)
  AND scheduled_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)

UNION ALL

SELECT
    'Critical Lab Results (7d)',
    COUNT(*),
    COUNT(DISTINCT patient_id),
    NULL,
    NULL
FROM lab_results
WHERE abnormal_flag IN ('Critical Low', 'Critical High')
  AND resulted_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY);

-- ============================================================================
-- Financial Performance Report
-- ============================================================================

-- Financial summary by department
WITH financial_metrics AS (
    SELECT
        d.department_name,
        d.department_type,
        COUNT(DISTINCT a.admission_id) AS admissions,
        SUM(a.total_charges) AS total_charges,
        SUM(a.insurance_coverage) AS total_insurance,
        SUM(a.total_charges - COALESCE(a.insurance_coverage, 0)) AS patient_responsibility,
        AVG(a.total_charges) AS avg_charge_per_admission,
        AVG(DATEDIFF(COALESCE(a.discharge_date, CURDATE()), a.admission_date)) AS avg_los
    FROM departments d
    LEFT JOIN admissions a ON d.department_id = a.department_id
        AND a.admission_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    WHERE d.is_active = TRUE
    GROUP BY d.department_id
)
SELECT
    department_name,
    department_type,
    admissions,
    FORMAT(total_charges, 2) AS total_charges,
    FORMAT(total_insurance, 2) AS insurance_payments,
    FORMAT(patient_responsibility, 2) AS patient_payments,
    FORMAT(avg_charge_per_admission, 2) AS avg_charge,
    ROUND(avg_los, 1) AS avg_los_days,
    FORMAT(total_charges / NULLIF(avg_los * admissions, 0), 2) AS revenue_per_day
FROM financial_metrics
WHERE admissions > 0
ORDER BY total_charges DESC;

-- ============================================================================
-- Compliance and Regulatory Report
-- ============================================================================

-- HIPAA compliance audit summary
SELECT
    'PHI Access Logs' AS compliance_item,
    COUNT(*) AS count_30d,
    COUNT(DISTINCT user) AS unique_users,
    'Compliant' AS status
FROM audit_log
WHERE table_name IN ('patients', 'vital_signs', 'prescriptions', 'lab_results')
  AND timestamp >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)

UNION ALL

SELECT
    'Staff License Expiry',
    COUNT(*),
    NULL,
    CASE
        WHEN COUNT(*) = 0 THEN 'Compliant'
        ELSE 'Action Required'
    END
FROM staff
WHERE is_active = TRUE
  AND license_expiry <= DATE_ADD(CURDATE(), INTERVAL 30 DAY)

UNION ALL

SELECT
    'Device Maintenance Overdue',
    COUNT(*),
    NULL,
    CASE
        WHEN COUNT(*) = 0 THEN 'Compliant'
        ELSE 'Action Required'
    END
FROM devices
WHERE is_active = TRUE
  AND next_maintenance_date < CURDATE()

UNION ALL

SELECT
    'Unsigned Clinical Notes',
    COUNT(*),
    COUNT(DISTINCT author_id),
    CASE
        WHEN COUNT(*) = 0 THEN 'Compliant'
        ELSE 'Action Required'
    END
FROM clinical_notes
WHERE is_signed = FALSE
  AND note_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)

UNION ALL

SELECT
    'Unverified Lab Results',
    COUNT(*),
    NULL,
    CASE
        WHEN COUNT(*) = 0 THEN 'Compliant'
        ELSE 'Action Required'
    END
FROM lab_results
WHERE verified_at IS NULL
  AND resulted_at >= DATE_SUB(CURDATE(), INTERVAL 48 HOUR);

-- ============================================================================
-- Device Utilization Report
-- ============================================================================

-- Device utilization and ROI analysis
WITH device_utilization AS (
    SELECT
        d.device_type,
        d.manufacturer,
        COUNT(DISTINCT d.device_id) AS device_count,
        COUNT(DISTINCT da.patient_id) AS patients_monitored,
        COUNT(DISTINCT dr.reading_id) AS readings_collected,
        AVG(d.battery_level) AS avg_battery_level,
        SUM(CASE WHEN d.connectivity_status = 'Online' THEN 1 ELSE 0 END) AS online_devices,
        SUM(CASE WHEN DATEDIFF(d.next_maintenance_date, CURDATE()) < 0 THEN 1 ELSE 0 END) AS maintenance_overdue
    FROM devices d
    LEFT JOIN device_assignments da ON d.device_id = da.device_id
        AND da.assigned_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    LEFT JOIN device_readings dr ON d.device_id = dr.device_id
        AND dr.timestamp >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    WHERE d.is_active = TRUE
    GROUP BY d.device_type, d.manufacturer
)
SELECT
    device_type,
    manufacturer,
    device_count,
    patients_monitored,
    ROUND(patients_monitored / NULLIF(device_count, 0), 1) AS avg_patients_per_device,
    FORMAT(readings_collected, 0) AS total_readings,
    ROUND(readings_collected / NULLIF(device_count * 30, 0), 0) AS avg_daily_readings_per_device,
    ROUND(avg_battery_level, 0) AS avg_battery_pct,
    ROUND(online_devices / device_count * 100, 1) AS online_rate,
    maintenance_overdue,
    CASE
        WHEN readings_collected / NULLIF(device_count * 30, 0) > 100 THEN 'High'
        WHEN readings_collected / NULLIF(device_count * 30, 0) > 50 THEN 'Medium'
        ELSE 'Low'
    END AS utilization_level
FROM device_utilization
ORDER BY device_count DESC;