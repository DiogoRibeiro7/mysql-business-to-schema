-- Raw denormalized table for normalization exercises
USE healthcare_iot;

DROP TABLE IF EXISTS raw_vital_stream;

CREATE TABLE raw_vital_stream (
    row_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_mrn VARCHAR(255),
    patient_name VARCHAR(255),
    device_serial VARCHAR(255),
    reading_time VARCHAR(255),
    heart_rate VARCHAR(255),
    systolic_bp VARCHAR(255),
    diastolic_bp VARCHAR(255),
    oxygen_sat VARCHAR(255),
    alert_flag VARCHAR(255)
) ENGINE=InnoDB;
