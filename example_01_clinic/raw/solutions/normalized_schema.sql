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
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    dob DATE NOT NULL,
    phone VARCHAR(30),
    email VARCHAR(255),
    address_line_1 VARCHAR(255),
    address_city VARCHAR(100),
    address_state VARCHAR(100),
    address_postal_code VARCHAR(20),
    address_country VARCHAR(100),
    status VARCHAR(20),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_dim_patient_natural (full_name, first_name, last_name, dob, phone, email, address_line_1, status),
    INDEX idx_dim_patient_natural (full_name, first_name, last_name, dob, phone, email, address_line_1, status),
    CHECK (dob >= '1900-01-01')
) ENGINE=InnoDB;

CREATE TABLE dim_doctor (
    doctor_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(200) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    specialty VARCHAR(100),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_dim_doctor_natural (full_name, first_name, last_name, specialty),
    INDEX idx_dim_doctor_natural (full_name, first_name, last_name, specialty)
) ENGINE=InnoDB;

CREATE TABLE dim_appointment (
    appointment_id INT AUTO_INCREMENT PRIMARY KEY,
    start DATETIME NOT NULL,
    status VARCHAR(30),
    reason VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_dim_appointment_natural (start, status, reason),
    INDEX idx_dim_appointment_natural (start, status, reason),
    CHECK (start >= '1900-01-01')
) ENGINE=InnoDB;

CREATE TABLE dim_invoice (
    invoice_id INT AUTO_INCREMENT PRIMARY KEY,
    number VARCHAR(50),
    total DECIMAL(10,2),
    status VARCHAR(30),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_dim_invoice_natural (number, total, status),
    INDEX idx_dim_invoice_natural (number, total, status),
    CHECK (total >= 0)
) ENGINE=InnoDB;

CREATE TABLE dim_payment (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    date DATE,
    method VARCHAR(30),
    amount DECIMAL(10,2),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_dim_payment_natural (date, method, amount),
    INDEX idx_dim_payment_natural (date, method, amount),
    CHECK (date >= '1900-01-01'),
    CHECK (amount >= 0)
) ENGINE=InnoDB;

CREATE TABLE fact_clinic_intake (
    fact_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT,
    doctor_id INT,
    appointment_id INT,
    invoice_id INT,
    payment_id INT,
    source_row_id INT,
    UNIQUE KEY uq_fact_clinic_intake_source (source_row_id),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

ALTER TABLE fact_clinic_intake
    ADD CONSTRAINT fk_fact_clinic_intake_patient FOREIGN KEY (patient_id)
    REFERENCES dim_patient (patient_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE fact_clinic_intake
    ADD CONSTRAINT fk_fact_clinic_intake_doctor FOREIGN KEY (doctor_id)
    REFERENCES dim_doctor (doctor_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE fact_clinic_intake
    ADD CONSTRAINT fk_fact_clinic_intake_appointment FOREIGN KEY (appointment_id)
    REFERENCES dim_appointment (appointment_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE fact_clinic_intake
    ADD CONSTRAINT fk_fact_clinic_intake_invoice FOREIGN KEY (invoice_id)
    REFERENCES dim_invoice (invoice_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE fact_clinic_intake
    ADD CONSTRAINT fk_fact_clinic_intake_payment FOREIGN KEY (payment_id)
    REFERENCES dim_payment (payment_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;
CREATE INDEX idx_fact_clinic_intake_patient ON fact_clinic_intake (patient_id);
CREATE INDEX idx_fact_clinic_intake_doctor ON fact_clinic_intake (doctor_id);
CREATE INDEX idx_fact_clinic_intake_appointment ON fact_clinic_intake (appointment_id);
CREATE INDEX idx_fact_clinic_intake_invoice ON fact_clinic_intake (invoice_id);
CREATE INDEX idx_fact_clinic_intake_payment ON fact_clinic_intake (payment_id);
CREATE INDEX idx_fact_clinic_intake_source ON fact_clinic_intake (source_row_id);
