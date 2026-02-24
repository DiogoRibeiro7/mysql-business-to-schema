-- Normalized schema generated from raw denormalized table
USE clinic;

DROP TABLE IF EXISTS fact_clinic_intake;
DROP TABLE IF EXISTS dim_patient;
DROP TABLE IF EXISTS dim_doctor;
DROP TABLE IF EXISTS dim_appointment;
DROP TABLE IF EXISTS dim_invoice;
DROP TABLE IF EXISTS dim_payment;

CREATE TABLE dim_patient (
    patient_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(200) NOT NULL,
    dob DATE NOT NULL,
    phone VARCHAR(30),
    email VARCHAR(255),
    address VARCHAR(255),
    status VARCHAR(20),
    UNIQUE KEY uq_dim_patient_natural (full_name, dob, phone, email, address, status)
) ENGINE=InnoDB;

CREATE TABLE dim_doctor (
    doctor_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(200) NOT NULL,
    specialty VARCHAR(100),
    UNIQUE KEY uq_dim_doctor_natural (full_name, specialty)
) ENGINE=InnoDB;

CREATE TABLE dim_appointment (
    appointment_id INT AUTO_INCREMENT PRIMARY KEY,
    start DATETIME NOT NULL,
    status VARCHAR(30),
    reason VARCHAR(255),
    UNIQUE KEY uq_dim_appointment_natural (start, status, reason)
) ENGINE=InnoDB;

CREATE TABLE dim_invoice (
    invoice_id INT AUTO_INCREMENT PRIMARY KEY,
    number VARCHAR(50),
    total DECIMAL(10,2),
    status VARCHAR(30),
    UNIQUE KEY uq_dim_invoice_natural (number, total, status)
) ENGINE=InnoDB;

CREATE TABLE dim_payment (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    date DATE,
    method VARCHAR(30),
    amount DECIMAL(10,2),
    UNIQUE KEY uq_dim_payment_natural (date, method, amount)
) ENGINE=InnoDB;

CREATE TABLE fact_clinic_intake (
    fact_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT,
    doctor_id INT,
    appointment_id INT,
    invoice_id INT,
    payment_id INT,
    source_row_id INT,
    UNIQUE KEY uq_fact_clinic_intake_source (source_row_id)
) ENGINE=InnoDB;

ALTER TABLE fact_clinic_intake
    ADD CONSTRAINT fk_fact_clinic_intake_patient FOREIGN KEY (patient_id)
    REFERENCES dim_patient (patient_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE fact_clinic_intake
    ADD CONSTRAINT fk_fact_clinic_intake_doctor FOREIGN KEY (doctor_id)
    REFERENCES dim_doctor (doctor_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE fact_clinic_intake
    ADD CONSTRAINT fk_fact_clinic_intake_appointment FOREIGN KEY (appointment_id)
    REFERENCES dim_appointment (appointment_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE fact_clinic_intake
    ADD CONSTRAINT fk_fact_clinic_intake_invoice FOREIGN KEY (invoice_id)
    REFERENCES dim_invoice (invoice_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE fact_clinic_intake
    ADD CONSTRAINT fk_fact_clinic_intake_payment FOREIGN KEY (payment_id)
    REFERENCES dim_payment (payment_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
CREATE INDEX idx_fact_clinic_intake_patient ON fact_clinic_intake (patient_id);
CREATE INDEX idx_fact_clinic_intake_doctor ON fact_clinic_intake (doctor_id);
CREATE INDEX idx_fact_clinic_intake_appointment ON fact_clinic_intake (appointment_id);
CREATE INDEX idx_fact_clinic_intake_invoice ON fact_clinic_intake (invoice_id);
CREATE INDEX idx_fact_clinic_intake_payment ON fact_clinic_intake (payment_id);
CREATE INDEX idx_fact_clinic_intake_source ON fact_clinic_intake (source_row_id);
