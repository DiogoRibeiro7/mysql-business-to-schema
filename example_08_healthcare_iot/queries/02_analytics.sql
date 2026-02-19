-- ============================================================================
-- Healthcare IoT Analytics Queries
-- ============================================================================

USE healthcare_iot;

-- Smoke test for CI query runner
SELECT 1 AS query_smoke_test;

-- ============================================================================
-- Patient Outcome Analytics
-- ============================================================================

-- Early warning score trends and outcomes
WITH ews_progression AS (
    SELECT
        v.patient_id,
        v.admission_id,
        DATE(v.recorded_at) AS reading_date,
        AVG(v.early_warning_score) AS avg_ews,
        MAX(v.early_warning_score) AS max_ews,
        MIN(v.early_warning_score) AS min_ews,
        STD(v.early_warning_score) AS ews_variability,
        COUNT(*) AS reading_count,
        SUM(CASE WHEN v.early_warning_score >= 7 THEN 1 ELSE 0 END) AS critical_count
    FROM vital_signs v
    WHERE v.recorded_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY v.patient_id, v.admission_id, DATE(v.recorded_at)
),
patient_outcomes AS (
    SELECT
        a.patient_id,
        a.admission_id,
        a.admission_type,
        a.status,
        a.discharge_disposition,
        DATEDIFF(COALESCE(a.discharge_date, NOW()), a.admission_date) AS length_of_stay
    FROM admissions a
    WHERE a.admission_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
)
SELECT
    po.admission_type,
    po.discharge_disposition,
    COUNT(DISTINCT po.patient_id) AS patient_count,
    AVG(po.length_of_stay) AS avg_los,
    AVG(ep.avg_ews) AS overall_avg_ews,
    AVG(ep.max_ews) AS avg_max_ews,
    AVG(ep.ews_variability) AS avg_ews_variability,
    SUM(ep.critical_count) AS total_critical_readings,
    ROUND(AVG(CASE WHEN ep.max_ews >= 7 THEN 1 ELSE 0 END) * 100, 1) AS pct_with_critical_ews,
    ROUND(AVG(CASE WHEN po.discharge_disposition = 'Deceased' THEN 1 ELSE 0 END) * 100, 2) AS mortality_rate
FROM patient_outcomes po
LEFT JOIN ews_progression ep ON po.patient_id = ep.patient_id AND po.admission_id = ep.admission_id
GROUP BY po.admission_type, po.discharge_disposition
ORDER BY patient_count DESC;

-- Readmission analysis
WITH readmissions AS (
    SELECT
        a1.patient_id,
        a1.admission_id AS first_admission,
        a1.discharge_date AS first_discharge,
        a2.admission_id AS readmission_id,
        a2.admission_date AS readmission_date,
        DATEDIFF(a2.admission_date, a1.discharge_date) AS days_to_readmission,
        a1.diagnosis_codes AS first_diagnosis,
        a2.diagnosis_codes AS readmission_diagnosis
    FROM admissions a1
    INNER JOIN admissions a2 ON a1.patient_id = a2.patient_id
        AND a2.admission_date > a1.discharge_date
        AND a2.admission_date <= DATE_ADD(a1.discharge_date, INTERVAL 30 DAY)
    WHERE a1.discharge_date >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
)
SELECT
    CASE
        WHEN days_to_readmission <= 7 THEN '0-7 days'
        WHEN days_to_readmission <= 14 THEN '8-14 days'
        WHEN days_to_readmission <= 21 THEN '15-21 days'
        ELSE '22-30 days'
    END AS readmission_window,
    COUNT(*) AS readmission_count,
    AVG(days_to_readmission) AS avg_days_to_readmission,
    COUNT(DISTINCT r.patient_id) AS unique_patients
FROM readmissions r
GROUP BY
    CASE
        WHEN days_to_readmission <= 7 THEN '0-7 days'
        WHEN days_to_readmission <= 14 THEN '8-14 days'
        WHEN days_to_readmission <= 21 THEN '15-21 days'
        ELSE '22-30 days'
    END
ORDER BY MIN(days_to_readmission);

-- ============================================================================
-- Alert Response Analytics
-- ============================================================================

-- Alert response time analysis by type and department
SELECT
    a.alert_type,
    a.alert_category,
    d.department_name,
    d.department_type,
    COUNT(a.alert_id) AS total_alerts,
    COUNT(CASE WHEN a.acknowledged_at IS NOT NULL THEN 1 END) AS acknowledged_alerts,
    ROUND(AVG(a.response_time_seconds), 0) AS avg_response_seconds,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY a.response_time_seconds) AS median_response_seconds,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY a.response_time_seconds) AS p95_response_seconds,
    MIN(a.response_time_seconds) AS min_response_seconds,
    MAX(a.response_time_seconds) AS max_response_seconds,
    SUM(CASE WHEN a.escalated = TRUE THEN 1 ELSE 0 END) AS escalated_count,
    ROUND(AVG(CASE WHEN a.escalated = TRUE THEN 1 ELSE 0 END) * 100, 1) AS escalation_rate
FROM alerts a
INNER JOIN admissions ad ON a.patient_id = ad.patient_id
    AND a.triggered_at BETWEEN ad.admission_date AND COALESCE(ad.discharge_date, NOW())
INNER JOIN departments d ON ad.department_id = d.department_id
WHERE a.triggered_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY a.alert_type, a.alert_category, d.department_id
ORDER BY total_alerts DESC;

-- Alert patterns by time of day
SELECT
    HOUR(a.triggered_at) AS hour_of_day,
    a.alert_type,
    COUNT(a.alert_id) AS alert_count,
    AVG(a.response_time_seconds) AS avg_response_seconds,
    SUM(CASE WHEN a.acknowledged_at IS NULL THEN 1 ELSE 0 END) AS unacknowledged_count,
    ROUND(AVG(CASE WHEN a.acknowledged_at IS NULL THEN 1 ELSE 0 END) * 100, 1) AS unacknowledged_rate
FROM alerts a
WHERE a.triggered_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
GROUP BY HOUR(a.triggered_at), a.alert_type
ORDER BY hour_of_day, alert_type;

-- ============================================================================
-- Device Performance Analytics
-- ============================================================================

-- Device reliability metrics
WITH device_metrics AS (
    SELECT
        d.device_id,
        d.device_type,
        d.manufacturer,
        d.model,
        COUNT(DISTINCT DATE(dr.timestamp)) AS days_active,
        COUNT(dr.reading_id) AS total_readings,
        AVG(dr.quality_score) AS avg_quality_score,
        SUM(CASE WHEN dr.quality_score < 70 THEN 1 ELSE 0 END) AS poor_quality_readings,
        MIN(dr.timestamp) AS first_reading,
        MAX(dr.timestamp) AS last_reading
    FROM devices d
    LEFT JOIN device_readings dr ON d.device_id = dr.device_id
        AND dr.timestamp >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    WHERE d.is_active = TRUE
    GROUP BY d.device_id
),
device_issues AS (
    SELECT
        device_id,
        COUNT(*) AS alert_count,
        SUM(CASE WHEN alert_type = 'Critical' THEN 1 ELSE 0 END) AS critical_alerts
    FROM alerts
    WHERE device_id IS NOT NULL
      AND triggered_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY device_id
)
SELECT
    dm.device_type,
    dm.manufacturer,
    dm.model,
    COUNT(dm.device_id) AS device_count,
    AVG(dm.days_active) AS avg_days_active,
    AVG(dm.total_readings) AS avg_readings_per_device,
    ROUND(AVG(dm.avg_quality_score), 1) AS avg_quality_score,
    SUM(dm.poor_quality_readings) AS total_poor_quality_readings,
    ROUND(AVG(dm.poor_quality_readings / NULLIF(dm.total_readings, 0) * 100), 2) AS poor_quality_rate,
    COALESCE(SUM(di.alert_count), 0) AS total_alerts,
    COALESCE(SUM(di.critical_alerts), 0) AS total_critical_alerts,
    ROUND(AVG(TIMESTAMPDIFF(HOUR, dm.first_reading, dm.last_reading) / NULLIF(dm.days_active, 0)), 1) AS avg_daily_operating_hours
FROM device_metrics dm
LEFT JOIN device_issues di ON dm.device_id = di.device_id
GROUP BY dm.device_type, dm.manufacturer, dm.model
ORDER BY device_count DESC, avg_quality_score DESC;

-- Device maintenance effectiveness
SELECT
    d.device_type,
    COUNT(DISTINCT d.device_id) AS total_devices,
    COUNT(DISTINCT CASE WHEN d.next_maintenance_date < CURDATE() THEN d.device_id END) AS overdue_maintenance,
    COUNT(DISTINCT CASE WHEN d.connectivity_status = 'Offline' THEN d.device_id END) AS offline_devices,
    AVG(DATEDIFF(d.next_maintenance_date, d.last_maintenance_date)) AS avg_maintenance_interval_days,
    AVG(d.battery_level) AS avg_battery_level,
    COUNT(DISTINCT CASE WHEN d.battery_level < 20 THEN d.device_id END) AS low_battery_devices,
    ROUND(AVG(CASE WHEN d.connectivity_status = 'Online' THEN 1 ELSE 0 END) * 100, 1) AS online_rate
FROM devices d
WHERE d.is_active = TRUE
GROUP BY d.device_type
ORDER BY total_devices DESC;

-- ============================================================================
-- Medication Analytics
-- ============================================================================

-- Medication administration compliance by department
WITH medication_stats AS (
    SELECT
        d.department_id,
        d.department_name,
        d.department_type,
        DATE(ma.scheduled_time) AS admin_date,
        COUNT(*) AS scheduled_doses,
        SUM(CASE WHEN ma.taken = TRUE THEN 1 ELSE 0 END) AS administered_doses,
        SUM(CASE WHEN ma.missed = TRUE THEN 1 ELSE 0 END) AS missed_doses,
        SUM(CASE WHEN ma.refused = TRUE THEN 1 ELSE 0 END) AS refused_doses,
        SUM(CASE WHEN ma.taken = TRUE AND ma.actual_time > DATE_ADD(ma.scheduled_time, INTERVAL 30 MINUTE) THEN 1 ELSE 0 END) AS late_doses
    FROM medication_administration ma
    INNER JOIN prescriptions pr ON ma.prescription_id = pr.prescription_id
    INNER JOIN admissions a ON pr.admission_id = a.admission_id
    INNER JOIN departments d ON a.department_id = d.department_id
    WHERE ma.scheduled_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
      AND ma.scheduled_time <= NOW()
    GROUP BY d.department_id, DATE(ma.scheduled_time)
)
SELECT
    department_name,
    department_type,
    COUNT(DISTINCT admin_date) AS days_tracked,
    SUM(scheduled_doses) AS total_scheduled,
    SUM(administered_doses) AS total_administered,
    SUM(missed_doses) AS total_missed,
    SUM(refused_doses) AS total_refused,
    SUM(late_doses) AS total_late,
    ROUND(SUM(administered_doses) / SUM(scheduled_doses) * 100, 1) AS compliance_rate,
    ROUND(SUM(late_doses) / NULLIF(SUM(administered_doses), 0) * 100, 1) AS late_administration_rate,
    ROUND(AVG(scheduled_doses), 0) AS avg_daily_doses
FROM medication_stats
GROUP BY department_id
ORDER BY compliance_rate DESC;

-- High-risk medication monitoring
SELECT
    m.medication_name,
    m.drug_class,
    m.controlled_substance_schedule,
    COUNT(DISTINCT pr.prescription_id) AS active_prescriptions,
    COUNT(DISTINCT pr.patient_id) AS patients_on_medication,
    AVG(CAST(pr.dosage AS UNSIGNED)) AS avg_dosage,
    COUNT(DISTINCT ma.administration_id) AS doses_administered,
    SUM(CASE WHEN ma.missed = TRUE THEN 1 ELSE 0 END) AS doses_missed,
    COUNT(DISTINCT al.alert_id) AS medication_alerts
FROM medications m
INNER JOIN prescriptions pr ON m.medication_id = pr.medication_id
    AND pr.is_active = TRUE
LEFT JOIN medication_administration ma ON pr.prescription_id = ma.prescription_id
    AND ma.scheduled_time >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
LEFT JOIN alerts al ON pr.patient_id = al.patient_id
    AND al.alert_category = 'Medication'
    AND al.triggered_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
WHERE m.controlled_substance_schedule IS NOT NULL
   OR m.black_box_warning IS NOT NULL
GROUP BY m.medication_id
ORDER BY patients_on_medication DESC;

-- ============================================================================
-- Laboratory Analytics
-- ============================================================================

-- Lab test turnaround time analysis
SELECT
    lt.test_category,
    lo.priority,
    COUNT(lr.result_id) AS total_tests,
    AVG(TIMESTAMPDIFF(MINUTE, lo.order_date, lr.resulted_at)) AS avg_turnaround_minutes,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY TIMESTAMPDIFF(MINUTE, lo.order_date, lr.resulted_at)) AS median_turnaround,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY TIMESTAMPDIFF(MINUTE, lo.order_date, lr.resulted_at)) AS p95_turnaround,
    MIN(TIMESTAMPDIFF(MINUTE, lo.order_date, lr.resulted_at)) AS min_turnaround,
    MAX(TIMESTAMPDIFF(MINUTE, lo.order_date, lr.resulted_at)) AS max_turnaround,
    SUM(CASE WHEN lr.abnormal_flag IN ('Critical Low', 'Critical High') THEN 1 ELSE 0 END) AS critical_results,
    ROUND(AVG(CASE WHEN lr.abnormal_flag != 'Normal' THEN 1 ELSE 0 END) * 100, 1) AS abnormal_rate
FROM lab_results lr
INNER JOIN lab_orders lo ON lr.order_id = lo.order_id
INNER JOIN lab_tests lt ON lr.test_id = lt.test_id
WHERE lo.order_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY lt.test_category, lo.priority
ORDER BY lt.test_category, lo.priority;

-- Most common abnormal lab results
SELECT
    lt.test_name,
    lt.test_category,
    COUNT(lr.result_id) AS total_results,
    SUM(CASE WHEN lr.abnormal_flag != 'Normal' THEN 1 ELSE 0 END) AS abnormal_results,
    ROUND(AVG(CASE WHEN lr.abnormal_flag != 'Normal' THEN 1 ELSE 0 END) * 100, 1) AS abnormal_rate,
    SUM(CASE WHEN lr.abnormal_flag = 'Critical Low' THEN 1 ELSE 0 END) AS critical_low,
    SUM(CASE WHEN lr.abnormal_flag = 'Critical High' THEN 1 ELSE 0 END) AS critical_high,
    AVG(lr.result_value) AS avg_value,
    STD(lr.result_value) AS std_dev_value,
    CONCAT(lt.normal_range_low, ' - ', lt.normal_range_high, ' ', lt.unit) AS normal_range
FROM lab_results lr
INNER JOIN lab_tests lt ON lr.test_id = lt.test_id
WHERE lr.resulted_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY lt.test_id
HAVING abnormal_results > 0
ORDER BY abnormal_rate DESC, total_results DESC
LIMIT 20;

-- ============================================================================
-- Department Performance Analytics
-- ============================================================================

-- Department efficiency metrics
WITH dept_metrics AS (
    SELECT
        d.department_id,
        d.department_name,
        d.department_type,
        d.bed_count,
        COUNT(DISTINCT a.admission_id) AS total_admissions,
        COUNT(DISTINCT CASE WHEN a.status = 'Active' THEN a.admission_id END) AS current_patients,
        AVG(DATEDIFF(COALESCE(a.discharge_date, CURDATE()), a.admission_date)) AS avg_los,
        COUNT(DISTINCT ee.event_id) AS emergency_events,
        AVG(al.response_time_seconds) AS avg_alert_response
    FROM departments d
    LEFT JOIN admissions a ON d.department_id = a.department_id
        AND a.admission_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    LEFT JOIN emergency_events ee ON a.admission_id = ee.admission_id
    LEFT JOIN alerts al ON a.admission_id = al.admission_id
        AND al.acknowledged_at IS NOT NULL
    WHERE d.is_active = TRUE
    GROUP BY d.department_id
)
SELECT
    dm.department_name,
    dm.department_type,
    dm.bed_count,
    dm.current_patients,
    ROUND(dm.current_patients / NULLIF(dm.bed_count, 0) * 100, 1) AS occupancy_rate,
    dm.total_admissions AS admissions_30d,
    ROUND(dm.avg_los, 1) AS avg_los_days,
    dm.emergency_events,
    ROUND(dm.avg_alert_response / 60, 1) AS avg_alert_response_minutes,
    ROUND(dm.total_admissions / 30.0, 1) AS daily_admission_rate
FROM dept_metrics dm
ORDER BY dm.department_type, dm.occupancy_rate DESC;

-- ============================================================================
-- Patient Risk Stratification
-- ============================================================================

-- Comprehensive patient risk scoring
WITH patient_risk_factors AS (
    SELECT
        p.patient_id,
        p.medical_record_number,
        CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
        TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) AS age,
        a.admission_id,
        a.admission_type,
        DATEDIFF(NOW(), a.admission_date) AS days_admitted,
        -- Clinical risk factors
        MAX(v.early_warning_score) AS max_ews_24h,
        AVG(v.early_warning_score) AS avg_ews_24h,
        COUNT(DISTINCT al.alert_id) AS alert_count_24h,
        COUNT(DISTINCT CASE WHEN al.alert_type = 'Critical' THEN al.alert_id END) AS critical_alerts_24h,
        COUNT(DISTINCT lr.result_id) AS abnormal_labs,
        COUNT(DISTINCT pr.prescription_id) AS active_medications,
        JSON_LENGTH(p.chronic_conditions) AS chronic_condition_count,
        -- Calculate composite risk score
        (
            CASE WHEN MAX(v.early_warning_score) >= 7 THEN 30
                 WHEN MAX(v.early_warning_score) >= 5 THEN 20
                 WHEN MAX(v.early_warning_score) >= 3 THEN 10
                 ELSE 0
            END +
            CASE WHEN TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) >= 80 THEN 15
                 WHEN TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) >= 65 THEN 10
                 ELSE 0
            END +
            CASE WHEN COUNT(DISTINCT CASE WHEN al.alert_type = 'Critical' THEN al.alert_id END) > 0 THEN 20
                 ELSE 0
            END +
            CASE WHEN DATEDIFF(NOW(), a.admission_date) > 7 THEN 10
                 ELSE 0
            END +
            CASE WHEN JSON_LENGTH(p.chronic_conditions) >= 3 THEN 15
                 WHEN JSON_LENGTH(p.chronic_conditions) >= 1 THEN 10
                 ELSE 0
            END
        ) AS risk_score
    FROM patients p
    INNER JOIN admissions a ON p.patient_id = a.patient_id AND a.status = 'Active'
    LEFT JOIN vital_signs v ON p.patient_id = v.patient_id
        AND v.recorded_at >= NOW() - INTERVAL 24 HOUR
    LEFT JOIN alerts al ON p.patient_id = al.patient_id
        AND al.triggered_at >= NOW() - INTERVAL 24 HOUR
    LEFT JOIN lab_results lr ON p.patient_id = lr.patient_id
        AND lr.resulted_at >= NOW() - INTERVAL 24 HOUR
        AND lr.abnormal_flag != 'Normal'
    LEFT JOIN prescriptions pr ON p.patient_id = pr.patient_id
        AND pr.is_active = TRUE
    GROUP BY p.patient_id, a.admission_id
)
SELECT
    patient_name,
    medical_record_number,
    age,
    admission_type,
    days_admitted,
    ROUND(avg_ews_24h, 1) AS avg_ews_24h,
    max_ews_24h,
    alert_count_24h,
    critical_alerts_24h,
    abnormal_labs,
    active_medications,
    chronic_condition_count,
    risk_score,
    CASE
        WHEN risk_score >= 70 THEN 'CRITICAL'
        WHEN risk_score >= 50 THEN 'HIGH'
        WHEN risk_score >= 30 THEN 'MODERATE'
        ELSE 'LOW'
    END AS risk_category,
    RANK() OVER (ORDER BY risk_score DESC) AS risk_rank
FROM patient_risk_factors
ORDER BY risk_score DESC;
