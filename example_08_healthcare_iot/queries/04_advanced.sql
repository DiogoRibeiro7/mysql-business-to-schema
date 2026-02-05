-- ============================================================================
-- Healthcare IoT Advanced Analytics & Predictions
-- ============================================================================

USE healthcare_iot;

-- ============================================================================
-- Patient Deterioration Prediction
-- ============================================================================

-- Identify patients at risk of deterioration based on vital sign trends
WITH vital_trends AS (
    SELECT
        v.patient_id,
        v.admission_id,
        v.recorded_at,
        v.early_warning_score,
        v.heart_rate,
        v.respiratory_rate,
        v.oxygen_saturation,
        v.systolic_bp,
        -- Calculate 6-hour moving averages
        AVG(v.early_warning_score) OVER (
            PARTITION BY v.patient_id
            ORDER BY v.recorded_at
            RANGE BETWEEN INTERVAL 6 HOUR PRECEDING AND CURRENT ROW
        ) AS ews_6h_avg,
        -- Calculate trends (current vs 6 hours ago)
        v.early_warning_score - LAG(v.early_warning_score, 6) OVER (
            PARTITION BY v.patient_id ORDER BY v.recorded_at
        ) AS ews_trend,
        v.heart_rate - LAG(v.heart_rate, 6) OVER (
            PARTITION BY v.patient_id ORDER BY v.recorded_at
        ) AS hr_trend,
        v.oxygen_saturation - LAG(v.oxygen_saturation, 6) OVER (
            PARTITION BY v.patient_id ORDER BY v.recorded_at
        ) AS o2_trend,
        ROW_NUMBER() OVER (PARTITION BY v.patient_id ORDER BY v.recorded_at DESC) AS rn
    FROM vital_signs v
    INNER JOIN admissions a ON v.admission_id = a.admission_id
    WHERE a.status = 'Active'
      AND v.recorded_at >= NOW() - INTERVAL 24 HOUR
),
risk_scores AS (
    SELECT
        patient_id,
        admission_id,
        recorded_at,
        early_warning_score,
        ews_6h_avg,
        ews_trend,
        hr_trend,
        o2_trend,
        -- Calculate deterioration risk score
        (
            -- Current EWS contribution
            CASE
                WHEN early_warning_score >= 7 THEN 40
                WHEN early_warning_score >= 5 THEN 25
                WHEN early_warning_score >= 3 THEN 10
                ELSE 0
            END +
            -- Trend contribution
            CASE
                WHEN ews_trend >= 3 THEN 30
                WHEN ews_trend >= 2 THEN 20
                WHEN ews_trend >= 1 THEN 10
                ELSE 0
            END +
            -- Vital sign deterioration
            CASE WHEN hr_trend > 20 OR hr_trend < -20 THEN 15 ELSE 0 END +
            CASE WHEN o2_trend < -5 THEN 20 WHEN o2_trend < -3 THEN 10 ELSE 0 END +
            -- Sustained elevation
            CASE WHEN ews_6h_avg >= 5 THEN 15 ELSE 0 END
        ) AS deterioration_risk_score
    FROM vital_trends
    WHERE rn = 1
)
SELECT
    p.medical_record_number,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    d.department_name,
    r.room_number,
    rs.early_warning_score AS current_ews,
    ROUND(rs.ews_6h_avg, 1) AS avg_ews_6h,
    rs.ews_trend AS ews_change_6h,
    rs.hr_trend AS heart_rate_change_6h,
    rs.o2_trend AS o2_sat_change_6h,
    rs.deterioration_risk_score,
    CASE
        WHEN rs.deterioration_risk_score >= 70 THEN 'CRITICAL - Immediate intervention needed'
        WHEN rs.deterioration_risk_score >= 50 THEN 'HIGH - Close monitoring required'
        WHEN rs.deterioration_risk_score >= 30 THEN 'MODERATE - Increased observation'
        ELSE 'LOW - Continue routine monitoring'
    END AS risk_level,
    -- Predicted probability of ICU transfer (simplified model)
    ROUND(
        LEAST(100, rs.deterioration_risk_score * 1.2 +
        CASE WHEN d.department_type != 'ICU' THEN 10 ELSE 0 END)
    , 1) AS icu_transfer_probability,
    CONCAT(s.first_name, ' ', s.last_name) AS attending_physician
FROM risk_scores rs
INNER JOIN patients p ON rs.patient_id = p.patient_id
INNER JOIN admissions a ON rs.admission_id = a.admission_id
INNER JOIN departments d ON a.department_id = d.department_id
LEFT JOIN rooms r ON a.room_id = r.room_id
LEFT JOIN staff s ON a.attending_physician_id = s.staff_id
WHERE rs.deterioration_risk_score >= 30
ORDER BY rs.deterioration_risk_score DESC;

-- ============================================================================
-- Sepsis Early Detection
-- ============================================================================

-- SIRS and qSOFA criteria for sepsis screening
WITH sepsis_indicators AS (
    SELECT
        v.patient_id,
        v.admission_id,
        v.recorded_at,
        -- SIRS criteria
        CASE WHEN v.temperature > 38 OR v.temperature < 36 THEN 1 ELSE 0 END AS temp_abnormal,
        CASE WHEN v.heart_rate > 90 THEN 1 ELSE 0 END AS tachycardia,
        CASE WHEN v.respiratory_rate > 20 THEN 1 ELSE 0 END AS tachypnea,
        -- qSOFA criteria
        CASE WHEN v.respiratory_rate >= 22 THEN 1 ELSE 0 END AS qsofa_resp,
        CASE WHEN v.systolic_bp <= 100 THEN 1 ELSE 0 END AS qsofa_bp,
        CASE WHEN v.consciousness_level != 'Alert' THEN 1 ELSE 0 END AS qsofa_mental,
        -- Lab indicators (if available)
        lr.wbc_count,
        lr.lactate,
        lr.creatinine,
        lr.platelet_count
    FROM vital_signs v
    LEFT JOIN (
        SELECT
            patient_id,
            MAX(CASE WHEN test_id = (SELECT test_id FROM lab_tests WHERE test_code = 'WBC') THEN result_value END) AS wbc_count,
            MAX(CASE WHEN test_id = (SELECT test_id FROM lab_tests WHERE test_code = 'LACT') THEN result_value END) AS lactate,
            MAX(CASE WHEN test_id = (SELECT test_id FROM lab_tests WHERE test_code = 'CREAT') THEN result_value END) AS creatinine,
            MAX(CASE WHEN test_id = (SELECT test_id FROM lab_tests WHERE test_code = 'PLT') THEN result_value END) AS platelet_count
        FROM lab_results
        WHERE resulted_at >= NOW() - INTERVAL 24 HOUR
        GROUP BY patient_id
    ) lr ON v.patient_id = lr.patient_id
    WHERE v.recorded_at >= NOW() - INTERVAL 4 HOUR
),
sepsis_scores AS (
    SELECT
        patient_id,
        admission_id,
        MAX(recorded_at) AS last_assessment,
        -- SIRS score (2+ indicates SIRS)
        MAX(temp_abnormal + tachycardia + tachypnea +
            CASE WHEN wbc_count > 12 OR wbc_count < 4 THEN 1 ELSE 0 END) AS sirs_score,
        -- qSOFA score (2+ indicates high risk)
        MAX(qsofa_resp + qsofa_bp + qsofa_mental) AS qsofa_score,
        MAX(lactate) AS lactate_level,
        MAX(creatinine) AS creatinine_level,
        MIN(platelet_count) AS platelet_count
    FROM sepsis_indicators
    GROUP BY patient_id, admission_id
)
SELECT
    p.medical_record_number,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) AS age,
    d.department_name,
    ss.sirs_score,
    ss.qsofa_score,
    ss.lactate_level,
    ss.creatinine_level,
    ss.platelet_count,
    CASE
        WHEN ss.qsofa_score >= 2 THEN 'HIGH RISK - Possible sepsis'
        WHEN ss.sirs_score >= 2 AND ss.lactate_level > 2 THEN 'HIGH RISK - SIRS with hyperlactatemia'
        WHEN ss.sirs_score >= 2 THEN 'MODERATE RISK - SIRS criteria met'
        ELSE 'LOW RISK'
    END AS sepsis_risk,
    CASE
        WHEN ss.qsofa_score >= 2 OR (ss.sirs_score >= 2 AND ss.lactate_level > 2) THEN
            'Initiate sepsis bundle: Blood cultures, broad-spectrum antibiotics, fluid resuscitation'
        WHEN ss.sirs_score >= 2 THEN
            'Monitor closely, consider blood cultures and lactate'
        ELSE 'Continue routine monitoring'
    END AS recommended_action
FROM sepsis_scores ss
INNER JOIN patients p ON ss.patient_id = p.patient_id
INNER JOIN admissions a ON ss.admission_id = a.admission_id
INNER JOIN departments d ON a.department_id = d.department_id
WHERE ss.sirs_score >= 2 OR ss.qsofa_score >= 2
ORDER BY ss.qsofa_score DESC, ss.sirs_score DESC;

-- ============================================================================
-- Length of Stay Prediction
-- ============================================================================

-- Predict expected length of stay based on patient characteristics and conditions
WITH patient_factors AS (
    SELECT
        a.admission_id,
        a.patient_id,
        a.admission_type,
        a.admission_date,
        TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) AS age,
        p.gender,
        JSON_LENGTH(p.chronic_conditions) AS chronic_condition_count,
        d.department_type,
        -- Clinical complexity indicators
        MAX(v.early_warning_score) AS max_ews_48h,
        COUNT(DISTINCT pr.prescription_id) AS medication_count,
        COUNT(DISTINCT lo.order_id) AS lab_order_count,
        COUNT(DISTINCT al.alert_id) AS alert_count,
        COUNT(DISTINCT ee.event_id) AS emergency_events,
        -- Current LOS
        DATEDIFF(NOW(), a.admission_date) AS current_los
    FROM admissions a
    INNER JOIN patients p ON a.patient_id = p.patient_id
    INNER JOIN departments d ON a.department_id = d.department_id
    LEFT JOIN vital_signs v ON a.admission_id = v.admission_id
        AND v.recorded_at >= a.admission_date
        AND v.recorded_at <= DATE_ADD(a.admission_date, INTERVAL 48 HOUR)
    LEFT JOIN prescriptions pr ON a.admission_id = pr.admission_id AND pr.is_active = TRUE
    LEFT JOIN lab_orders lo ON a.admission_id = lo.admission_id
    LEFT JOIN alerts al ON a.admission_id = al.admission_id
    LEFT JOIN emergency_events ee ON a.admission_id = ee.admission_id
    WHERE a.status = 'Active'
    GROUP BY a.admission_id
),
historical_los AS (
    SELECT
        admission_type,
        department_type,
        AVG(DATEDIFF(discharge_date, admission_date)) AS avg_los,
        STD(DATEDIFF(discharge_date, admission_date)) AS std_los,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY DATEDIFF(discharge_date, admission_date)) AS median_los,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY DATEDIFF(discharge_date, admission_date)) AS p75_los
    FROM admissions a
    INNER JOIN departments d ON a.department_id = d.department_id
    WHERE discharge_date IS NOT NULL
      AND discharge_date >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
    GROUP BY admission_type, department_type
)
SELECT
    p.medical_record_number,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    pf.admission_type,
    pf.department_type,
    pf.current_los AS days_admitted,
    -- Base prediction from historical data
    ROUND(hl.avg_los, 0) AS typical_los,
    -- Adjusted prediction based on patient factors
    ROUND(
        hl.avg_los *
        -- Age adjustment
        CASE
            WHEN pf.age >= 80 THEN 1.3
            WHEN pf.age >= 65 THEN 1.15
            ELSE 1.0
        END *
        -- Clinical complexity adjustment
        CASE
            WHEN pf.max_ews_48h >= 7 THEN 1.5
            WHEN pf.max_ews_48h >= 5 THEN 1.25
            ELSE 1.0
        END *
        -- Comorbidity adjustment
        (1 + pf.chronic_condition_count * 0.1) *
        -- Emergency event adjustment
        (1 + pf.emergency_events * 0.2)
    , 0) AS predicted_los,
    -- Estimated discharge date
    DATE_ADD(pf.admission_date, INTERVAL
        ROUND(
            hl.avg_los *
            CASE WHEN pf.age >= 80 THEN 1.3 WHEN pf.age >= 65 THEN 1.15 ELSE 1.0 END *
            CASE WHEN pf.max_ews_48h >= 7 THEN 1.5 WHEN pf.max_ews_48h >= 5 THEN 1.25 ELSE 1.0 END *
            (1 + pf.chronic_condition_count * 0.1) *
            (1 + pf.emergency_events * 0.2)
        , 0) DAY
    ) AS estimated_discharge_date,
    -- Risk of extended stay
    CASE
        WHEN pf.current_los > hl.p75_los THEN 'Already Extended'
        WHEN pf.max_ews_48h >= 5 OR pf.emergency_events > 0 THEN 'High Risk'
        WHEN pf.chronic_condition_count >= 3 OR pf.age >= 75 THEN 'Moderate Risk'
        ELSE 'Low Risk'
    END AS extended_stay_risk,
    pf.max_ews_48h,
    pf.medication_count,
    pf.chronic_condition_count
FROM patient_factors pf
INNER JOIN patients p ON pf.patient_id = p.patient_id
LEFT JOIN historical_los hl ON pf.admission_type = hl.admission_type
    AND pf.department_type = hl.department_type
ORDER BY predicted_los DESC;

-- ============================================================================
-- Medication Adherence Prediction
-- ============================================================================

-- Identify patients at risk for medication non-compliance
WITH adherence_history AS (
    SELECT
        ma.patient_id,
        pr.prescription_id,
        m.medication_name,
        COUNT(*) AS total_doses,
        SUM(CASE WHEN ma.taken = TRUE THEN 1 ELSE 0 END) AS taken_doses,
        SUM(CASE WHEN ma.missed = TRUE THEN 1 ELSE 0 END) AS missed_doses,
        SUM(CASE WHEN ma.refused = TRUE THEN 1 ELSE 0 END) AS refused_doses,
        AVG(CASE WHEN ma.actual_time IS NOT NULL
            THEN TIMESTAMPDIFF(MINUTE, ma.scheduled_time, ma.actual_time)
            ELSE NULL END) AS avg_delay_minutes
    FROM medication_administration ma
    INNER JOIN prescriptions pr ON ma.prescription_id = pr.prescription_id
    INNER JOIN medications m ON pr.medication_id = m.medication_id
    WHERE ma.scheduled_time >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
      AND ma.scheduled_time <= NOW()
    GROUP BY ma.patient_id, pr.prescription_id
),
patient_adherence AS (
    SELECT
        ah.patient_id,
        COUNT(DISTINCT ah.prescription_id) AS medication_count,
        AVG(ah.taken_doses / ah.total_doses * 100) AS overall_adherence_rate,
        SUM(ah.missed_doses) AS total_missed,
        SUM(ah.refused_doses) AS total_refused,
        AVG(ah.avg_delay_minutes) AS avg_dose_delay,
        GROUP_CONCAT(
            CASE
                WHEN (ah.taken_doses / ah.total_doses) < 0.8
                THEN ah.medication_name
                ELSE NULL
            END
            SEPARATOR ', '
        ) AS problematic_medications
    FROM adherence_history ah
    GROUP BY ah.patient_id
)
SELECT
    p.medical_record_number,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) AS age,
    d.department_name,
    pa.medication_count AS active_medications,
    ROUND(pa.overall_adherence_rate, 1) AS adherence_rate_pct,
    pa.total_missed AS missed_doses_7d,
    pa.total_refused AS refused_doses_7d,
    ROUND(pa.avg_dose_delay, 0) AS avg_delay_minutes,
    -- Risk scoring
    CASE
        WHEN pa.overall_adherence_rate < 70 THEN 'HIGH RISK'
        WHEN pa.overall_adherence_rate < 85 THEN 'MODERATE RISK'
        WHEN pa.overall_adherence_rate < 95 THEN 'LOW RISK'
        ELSE 'COMPLIANT'
    END AS compliance_risk,
    pa.problematic_medications,
    -- Intervention recommendations
    CASE
        WHEN pa.overall_adherence_rate < 70 THEN
            'Immediate intervention: Patient education, simplified regimen, consider supervised administration'
        WHEN pa.overall_adherence_rate < 85 THEN
            'Schedule medication counseling, review regimen complexity'
        WHEN pa.total_refused > 0 THEN
            'Investigate reason for refusals, consider alternatives'
        ELSE 'Continue current management'
    END AS intervention_recommendation
FROM patient_adherence pa
INNER JOIN patients p ON pa.patient_id = p.patient_id
INNER JOIN admissions a ON p.patient_id = a.patient_id AND a.status = 'Active'
INNER JOIN departments d ON a.department_id = d.department_id
WHERE pa.overall_adherence_rate < 95
   OR pa.total_missed > 0
   OR pa.total_refused > 0
ORDER BY pa.overall_adherence_rate ASC;

-- ============================================================================
-- Resource Optimization Analysis
-- ============================================================================

-- Optimize device allocation based on patient acuity
WITH device_demand AS (
    SELECT
        d.department_id,
        d.department_name,
        d.department_type,
        COUNT(DISTINCT a.admission_id) AS patient_count,
        AVG(v.early_warning_score) AS avg_dept_ews,
        MAX(v.early_warning_score) AS max_dept_ews,
        COUNT(DISTINCT CASE WHEN v.early_warning_score >= 5 THEN a.patient_id END) AS high_risk_patients
    FROM departments d
    INNER JOIN admissions a ON d.department_id = a.department_id AND a.status = 'Active'
    LEFT JOIN vital_signs v ON a.admission_id = v.admission_id
        AND v.recorded_at >= NOW() - INTERVAL 24 HOUR
    GROUP BY d.department_id
),
device_availability AS (
    SELECT
        dev.department_id,
        dev.device_type,
        COUNT(*) AS total_devices,
        SUM(CASE WHEN dev.current_patient_id IS NULL THEN 1 ELSE 0 END) AS available_devices,
        SUM(CASE WHEN dev.connectivity_status = 'Online' THEN 1 ELSE 0 END) AS online_devices
    FROM devices dev
    WHERE dev.is_active = TRUE
    GROUP BY dev.department_id, dev.device_type
)
SELECT
    dd.department_name,
    dd.department_type,
    dd.patient_count,
    dd.high_risk_patients,
    ROUND(dd.avg_dept_ews, 1) AS avg_ews,
    da.device_type,
    da.total_devices,
    da.available_devices,
    -- Calculate recommended devices based on acuity
    GREATEST(
        dd.high_risk_patients,
        CEIL(dd.patient_count *
            CASE
                WHEN dd.department_type = 'ICU' THEN 1.0
                WHEN dd.department_type = 'Emergency' THEN 0.7
                WHEN dd.avg_dept_ews >= 3 THEN 0.5
                ELSE 0.3
            END
        )
    ) AS recommended_devices,
    -- Gap analysis
    GREATEST(
        dd.high_risk_patients,
        CEIL(dd.patient_count *
            CASE
                WHEN dd.department_type = 'ICU' THEN 1.0
                WHEN dd.department_type = 'Emergency' THEN 0.7
                WHEN dd.avg_dept_ews >= 3 THEN 0.5
                ELSE 0.3
            END
        )
    ) - da.total_devices AS device_gap,
    CASE
        WHEN da.available_devices = 0 AND dd.high_risk_patients > 0 THEN 'CRITICAL - No devices available for high-risk patients'
        WHEN da.total_devices < dd.high_risk_patients THEN 'SHORTAGE - Insufficient devices for monitoring needs'
        WHEN da.available_devices < dd.high_risk_patients * 0.2 THEN 'WARNING - Low device availability'
        ELSE 'ADEQUATE'
    END AS resource_status
FROM device_demand dd
LEFT JOIN device_availability da ON dd.department_id = da.department_id
ORDER BY
    CASE
        WHEN da.available_devices = 0 AND dd.high_risk_patients > 0 THEN 1
        WHEN da.total_devices < dd.high_risk_patients THEN 2
        ELSE 3
    END,
    dd.avg_dept_ews DESC;

-- ============================================================================
-- ML Feature Engineering for Patient Outcomes
-- ============================================================================

-- Prepare features for machine learning models
SELECT
    -- Patient demographics
    p.patient_id,
    TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) AS age,
    CASE p.gender WHEN 'Male' THEN 1 WHEN 'Female' THEN 0 ELSE NULL END AS gender_male,
    p.bmi,
    JSON_LENGTH(p.chronic_conditions) AS chronic_condition_count,
    JSON_LENGTH(p.allergies) AS allergy_count,

    -- Admission characteristics
    a.admission_id,
    CASE a.admission_type
        WHEN 'Emergency' THEN 1
        WHEN 'Scheduled' THEN 0
        ELSE 0.5
    END AS emergency_admission,
    DATEDIFF(NOW(), a.admission_date) AS current_los,

    -- Vital signs features (24h window)
    AVG(v.heart_rate) AS avg_heart_rate_24h,
    STD(v.heart_rate) AS std_heart_rate_24h,
    MAX(v.heart_rate) AS max_heart_rate_24h,
    MIN(v.heart_rate) AS min_heart_rate_24h,

    AVG(v.systolic_bp) AS avg_systolic_24h,
    STD(v.systolic_bp) AS std_systolic_24h,

    AVG(v.oxygen_saturation) AS avg_o2_sat_24h,
    MIN(v.oxygen_saturation) AS min_o2_sat_24h,

    AVG(v.temperature) AS avg_temp_24h,
    MAX(v.temperature) AS max_temp_24h,

    AVG(v.early_warning_score) AS avg_ews_24h,
    MAX(v.early_warning_score) AS max_ews_24h,
    STD(v.early_warning_score) AS std_ews_24h,

    -- Alert features
    COUNT(DISTINCT al.alert_id) AS alert_count_24h,
    COUNT(DISTINCT CASE WHEN al.alert_type = 'Critical' THEN al.alert_id END) AS critical_alerts_24h,
    AVG(al.response_time_seconds) AS avg_alert_response_24h,

    -- Medication features
    COUNT(DISTINCT pr.prescription_id) AS active_medications,
    COUNT(DISTINCT CASE WHEN pr.is_prn = TRUE THEN pr.prescription_id END) AS prn_medications,

    -- Lab features
    COUNT(DISTINCT lr.result_id) AS lab_results_24h,
    COUNT(DISTINCT CASE WHEN lr.abnormal_flag != 'Normal' THEN lr.result_id END) AS abnormal_labs_24h,

    -- Target variables for prediction
    CASE WHEN a.status = 'Active' THEN NULL
         WHEN a.discharge_disposition = 'Deceased' THEN 1
         ELSE 0
    END AS mortality_outcome,
    DATEDIFF(a.discharge_date, a.admission_date) AS actual_los,
    CASE WHEN EXISTS (
        SELECT 1 FROM admissions a2
        WHERE a2.patient_id = a.patient_id
          AND a2.admission_date > a.discharge_date
          AND a2.admission_date <= DATE_ADD(a.discharge_date, INTERVAL 30 DAY)
    ) THEN 1 ELSE 0 END AS readmitted_30d

FROM patients p
INNER JOIN admissions a ON p.patient_id = a.patient_id
LEFT JOIN vital_signs v ON a.admission_id = v.admission_id
    AND v.recorded_at >= NOW() - INTERVAL 24 HOUR
LEFT JOIN alerts al ON a.admission_id = al.admission_id
    AND al.triggered_at >= NOW() - INTERVAL 24 HOUR
LEFT JOIN prescriptions pr ON a.admission_id = pr.admission_id
    AND pr.is_active = TRUE
LEFT JOIN lab_results lr ON p.patient_id = lr.patient_id
    AND lr.resulted_at >= NOW() - INTERVAL 24 HOUR
WHERE a.admission_date >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
GROUP BY p.patient_id, a.admission_id;

-- ============================================================================
-- Clinical Pathway Optimization
-- ============================================================================

-- Analyze clinical pathways and identify optimization opportunities
WITH pathway_analysis AS (
    SELECT
        a.admission_type,
        a.chief_complaint,
        d.department_type,
        -- Time metrics
        AVG(TIMESTAMPDIFF(MINUTE, a.admission_date,
            (SELECT MIN(v.recorded_at) FROM vital_signs v WHERE v.admission_id = a.admission_id)
        )) AS avg_time_to_first_vitals,
        AVG(TIMESTAMPDIFF(MINUTE, a.admission_date,
            (SELECT MIN(lo.order_date) FROM lab_orders lo WHERE lo.admission_id = a.admission_id)
        )) AS avg_time_to_first_labs,
        AVG(TIMESTAMPDIFF(MINUTE, a.admission_date,
            (SELECT MIN(pr.start_date) FROM prescriptions pr WHERE pr.admission_id = a.admission_id)
        )) AS avg_time_to_first_medication,
        -- Process metrics
        COUNT(DISTINCT a.admission_id) AS patient_count,
        AVG(DATEDIFF(COALESCE(a.discharge_date, CURDATE()), a.admission_date)) AS avg_los,
        AVG(CASE WHEN a.discharge_disposition = 'Deceased' THEN 1 ELSE 0 END) * 100 AS mortality_rate,
        COUNT(DISTINCT ee.event_id) / COUNT(DISTINCT a.admission_id) AS emergency_events_per_patient
    FROM admissions a
    INNER JOIN departments d ON a.department_id = d.department_id
    LEFT JOIN emergency_events ee ON a.admission_id = ee.admission_id
    WHERE a.admission_date >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
    GROUP BY a.admission_type, a.chief_complaint, d.department_type
    HAVING patient_count >= 10
)
SELECT
    admission_type,
    chief_complaint,
    department_type,
    patient_count,
    ROUND(avg_time_to_first_vitals / 60, 1) AS hours_to_first_vitals,
    ROUND(avg_time_to_first_labs / 60, 1) AS hours_to_first_labs,
    ROUND(avg_time_to_first_medication / 60, 1) AS hours_to_first_medication,
    ROUND(avg_los, 1) AS avg_los_days,
    ROUND(mortality_rate, 2) AS mortality_pct,
    ROUND(emergency_events_per_patient, 2) AS emergency_rate,
    -- Optimization recommendations
    CONCAT(
        CASE
            WHEN avg_time_to_first_vitals > 30 THEN 'Reduce vital sign assessment time. '
            ELSE ''
        END,
        CASE
            WHEN avg_time_to_first_labs > 120 AND admission_type = 'Emergency' THEN 'Expedite lab ordering for emergency admissions. '
            ELSE ''
        END,
        CASE
            WHEN avg_los > (SELECT AVG(DATEDIFF(discharge_date, admission_date))
                           FROM admissions
                           WHERE admission_type = pa.admission_type
                             AND discharge_date IS NOT NULL) * 1.2 THEN 'LOS exceeds benchmark - review discharge planning. '
            ELSE ''
        END
    ) AS optimization_opportunities
FROM pathway_analysis pa
ORDER BY patient_count DESC, mortality_rate DESC;