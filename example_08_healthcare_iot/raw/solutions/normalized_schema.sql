-- Normalized schema generated from raw denormalized table
USE healthcare_iot;

DROP TABLE IF EXISTS fact_vital_stream;
DROP TABLE IF EXISTS dim_patient;
DROP TABLE IF EXISTS dim_device;

CREATE TABLE dim_patient (
    patient_id INT AUTO_INCREMENT PRIMARY KEY,
    mrn VARCHAR(255),
    full_name VARCHAR(255),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_dim_patient_natural (mrn, full_name, first_name, last_name),
    INDEX idx_dim_patient_natural (mrn, full_name, first_name, last_name)
) ENGINE=InnoDB;

CREATE TABLE dim_device (
    device_id INT AUTO_INCREMENT PRIMARY KEY,
    serial VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_dim_device_natural (serial),
    INDEX idx_dim_device_natural (serial)
) ENGINE=InnoDB;

CREATE TABLE fact_vital_stream (
    fact_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT,
    device_id INT,
    source_row_id INT,
    UNIQUE KEY uq_fact_vital_stream_source (source_row_id),
    reading_time VARCHAR(255),
    heart_rate VARCHAR(255),
    systolic_bp VARCHAR(255),
    diastolic_bp VARCHAR(255),
    oxygen_sat VARCHAR(255),
    alert_flag VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

ALTER TABLE fact_vital_stream
    ADD CONSTRAINT fk_fact_vital_stream_patient FOREIGN KEY (patient_id)
    REFERENCES dim_patient (patient_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE fact_vital_stream
    ADD CONSTRAINT fk_fact_vital_stream_device FOREIGN KEY (device_id)
    REFERENCES dim_device (device_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;
CREATE INDEX idx_fact_vital_stream_patient ON fact_vital_stream (patient_id);
CREATE INDEX idx_fact_vital_stream_device ON fact_vital_stream (device_id);
CREATE INDEX idx_fact_vital_stream_source ON fact_vital_stream (source_row_id);
