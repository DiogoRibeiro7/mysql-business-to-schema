-- ETL from raw denormalized table into normalized tables
USE healthcare_iot;

INSERT INTO dim_patient (mrn, full_name, first_name, last_name, created_at, updated_at)
SELECT DISTINCT r.patient_mrn, r.patient_name, SUBSTRING_INDEX(r.patient_name, ' ', 1), CASE WHEN INSTR(r.patient_name, ' ') > 0 THEN SUBSTRING(r.patient_name, INSTR(r.patient_name, ' ') + 1) ELSE '' END, NOW(), NOW()
FROM raw_vital_stream r;

INSERT INTO dim_device (serial, created_at, updated_at)
SELECT DISTINCT r.device_serial, NOW(), NOW()
FROM raw_vital_stream r;

INSERT INTO fact_vital_stream (patient_id, device_id, source_row_id, reading_time, heart_rate, systolic_bp, diastolic_bp, oxygen_sat, alert_flag, created_at, updated_at)
SELECT
    d_patient.patient_id,
    d_device.device_id,
    r.row_id,
    r.reading_time,
    r.heart_rate,
    r.systolic_bp,
    r.diastolic_bp,
    r.oxygen_sat,
    r.alert_flag,
    NOW(),
    NOW()
FROM raw_vital_stream r
LEFT JOIN dim_patient d_patient ON r.patient_mrn <=> d_patient.mrn AND r.patient_name <=> d_patient.full_name AND SUBSTRING_INDEX(r.patient_name, ' ', 1) <=> d_patient.first_name AND CASE WHEN INSTR(r.patient_name, ' ') > 0 THEN SUBSTRING(r.patient_name, INSTR(r.patient_name, ' ') + 1) ELSE '' END <=> d_patient.last_name
LEFT JOIN dim_device d_device ON r.device_serial <=> d_device.serial
;
