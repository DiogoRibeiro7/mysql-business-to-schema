-- Raw denormalized intake table for normalization exercises
USE clinic;

DROP TABLE IF EXISTS raw_clinic_intake;

CREATE TABLE raw_clinic_intake (
    intake_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_full_name VARCHAR(200) NOT NULL,
    patient_dob DATE NOT NULL,
    patient_phone VARCHAR(30),
    patient_email VARCHAR(255),
    patient_address VARCHAR(255),
    patient_status VARCHAR(20),
    doctor_full_name VARCHAR(200) NOT NULL,
    doctor_specialty VARCHAR(100),
    appointment_start DATETIME NOT NULL,
    appointment_status VARCHAR(30),
    appointment_reason VARCHAR(255),
    invoice_number VARCHAR(50),
    invoice_total DECIMAL(10,2),
    invoice_status VARCHAR(30),
    payment_date DATE,
    payment_method VARCHAR(30),
    payment_amount DECIMAL(10,2)
) ENGINE=InnoDB;
