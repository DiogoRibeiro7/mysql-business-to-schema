-- ETL from raw denormalized table into normalized tables
USE healthcare_iot;

INSERT INTO dim_patient (mrn, name)
SELECT DISTINCT r.patient_mrn, r.patient_name
FROM raw_vital_stream r;

INSERT INTO dim_device (serial)
SELECT DISTINCT r.device_serial
FROM raw_vital_stream r;

INSERT INTO fact_vital_stream (patient_id, device_id, reading_time, heart_rate, systolic_bp, diastolic_bp, oxygen_sat, alert_flag)
SELECT
    d_patient.patient_id,
    d_device.device_id,
    r.reading_time,
    r.heart_rate,
    r.systolic_bp,
    r.diastolic_bp,
    r.oxygen_sat,
    r.alert_flag
FROM raw_vital_stream r
LEFT JOIN dim_patient d_patient ON r.patient_mrn <=> d_patient.mrn AND r.patient_name <=> d_patient.name
LEFT JOIN dim_device d_device ON r.device_serial <=> d_device.serial
;
