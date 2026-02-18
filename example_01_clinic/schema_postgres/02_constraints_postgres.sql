-- PostgreSQL Schema
-- Converted from MySQL on 2026-02-17T23:11:17.320044
-- Generator: MySQL to PostgreSQL Converter

-- Enum Types
CREATE TYPE patients_status AS ENUM ('active', 'inactive');
CREATE TYPE appointments_status AS ENUM ('scheduled', 'completed', 'cancelled', 'no_show');
CREATE TYPE invoices_status AS ENUM ('open', 'partially_paid', 'paid', 'void');
CREATE TYPE payments_status AS ENUM ('cash', 'card', 'transfer', 'other');

-- Create database (run as superuser)
-- CREATE DATABASE clinic;
-- \c clinic

CREATE TABLE IF NOT EXISTS patients (
    patient_id BIGSERIAL NOT NULL,
    nif VARCHAR(32) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    phone VARCHAR(40) NOT NULL,
    email VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status patients_status NOT NULL DEFAULT 'active',
    PRIMARY KEY (patient_id)
);

CREATE TABLE IF NOT EXISTS doctors (
    doctor_id BIGSERIAL NOT NULL,
    license_number VARCHAR(64) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(40) NOT NULL,
    active_from DATE NOT NULL,
    active_to DATE NULL,
    PRIMARY KEY (doctor_id)
);

CREATE TABLE IF NOT EXISTS specialties (
    specialty_id BIGSERIAL NOT NULL,
    code VARCHAR(32) NOT NULL,
    name VARCHAR(120) NOT NULL,
    description VARCHAR(500) NULL,
    PRIMARY KEY (specialty_id)
);

CREATE TABLE IF NOT EXISTS doctor_specialties (
    doctor_id BIGINT NOT NULL,
    specialty_id BIGINT NOT NULL,
    assigned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (doctor_id, specialty_id)
);

CREATE TABLE IF NOT EXISTS appointments (
    appointment_id BIGSERIAL NOT NULL,
    patient_id BIGINT NOT NULL,
    doctor_id BIGINT NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    status appointments_status NOT NULL,
    cancel_reason VARCHAR(255) NULL,
    no_show_reason VARCHAR(255) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (appointment_id)
);

CREATE TABLE IF NOT EXISTS invoices (
    invoice_id BIGSERIAL NOT NULL,
    patient_id BIGINT NOT NULL,
    invoice_number VARCHAR(40) NOT NULL,
    issued_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status invoices_status NOT NULL DEFAULT 'open',
    total_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    PRIMARY KEY (invoice_id)
);

CREATE TABLE IF NOT EXISTS invoice_items (
    invoice_item_id BIGSERIAL NOT NULL,
    invoice_id BIGINT NOT NULL,
    appointment_id BIGINT NULL,
    description VARCHAR(255) NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    unit_price DECIMAL(10,2) NOT NULL,
    line_total DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (invoice_item_id)
);

CREATE TABLE IF NOT EXISTS payments (
    payment_id BIGSERIAL NOT NULL,
    patient_id BIGINT NOT NULL,
    payment_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    method payments_status NOT NULL,
    reference VARCHAR(100) NULL,
    amount DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (payment_id)
);

CREATE TABLE IF NOT EXISTS payment_allocations (
    payment_allocation_id BIGSERIAL NOT NULL,
    payment_id BIGINT NOT NULL,
    invoice_id BIGINT NOT NULL,
    amount_applied DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (payment_allocation_id)
);

ALTER TABLE patients
ADD CONSTRAINT uq_patients_nif UNIQUE (nif),
ADD CONSTRAINT uq_patients_email UNIQUE (email);
ALTER TABLE doctors
ADD CONSTRAINT uq_doctors_license UNIQUE (license_number),
ADD CONSTRAINT uq_doctors_email UNIQUE (email);
ALTER TABLE specialties
ADD CONSTRAINT uq_specialties_code UNIQUE (code),
ADD CONSTRAINT uq_specialties_name UNIQUE (name);
ALTER TABLE doctor_specialties
ADD CONSTRAINT fk_doctor_specialties_doctor
FOREIGN KEY (doctor_id) REFERENCES doctors (doctor_id)
ON UPDATE CASCADE ON DELETE RESTRICT,
ADD CONSTRAINT fk_doctor_specialties_specialty
FOREIGN KEY (specialty_id) REFERENCES specialties (specialty_id)
ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE appointments
ADD CONSTRAINT fk_appointments_patient
FOREIGN KEY (patient_id) REFERENCES patients (patient_id)
ON UPDATE CASCADE ON DELETE RESTRICT,
ADD CONSTRAINT fk_appointments_doctor
FOREIGN KEY (doctor_id) REFERENCES doctors (doctor_id)
ON UPDATE CASCADE ON DELETE RESTRICT,
ADD CONSTRAINT chk_appointments_time
CHECK (end_time > start_time),
ADD CONSTRAINT chk_appointments_cancel_reason
CHECK ((status <> 'cancelled') OR (cancel_reason IS NOT NULL)),
ADD CONSTRAINT chk_appointments_no_show_reason
CHECK ((status <> 'no_show') OR (no_show_reason IS NOT NULL));
ALTER TABLE invoices
ADD CONSTRAINT fk_invoices_patient
FOREIGN KEY (patient_id) REFERENCES patients (patient_id)
ON UPDATE CASCADE ON DELETE RESTRICT,
ADD CONSTRAINT uq_invoices_number UNIQUE (invoice_number),
ADD CONSTRAINT chk_invoices_total_amount
CHECK (total_amount >= 0);
ALTER TABLE invoice_items
ADD CONSTRAINT fk_invoice_items_invoice
FOREIGN KEY (invoice_id) REFERENCES invoices (invoice_id)
ON UPDATE CASCADE ON DELETE RESTRICT,
ADD CONSTRAINT fk_invoice_items_appointment
FOREIGN KEY (appointment_id) REFERENCES appointments (appointment_id)
ON UPDATE CASCADE ON DELETE SET NULL,
ADD CONSTRAINT chk_invoice_items_qty
CHECK (quantity > 0),
ADD CONSTRAINT chk_invoice_items_unit_price
CHECK (unit_price >= 0),
ADD CONSTRAINT chk_invoice_items_line_total
CHECK (line_total >= 0);
ALTER TABLE payments
ADD CONSTRAINT fk_payments_patient
FOREIGN KEY (patient_id) REFERENCES patients (patient_id)
ON UPDATE CASCADE ON DELETE RESTRICT,
ADD CONSTRAINT chk_payments_amount
CHECK (amount > 0);
ALTER TABLE payment_allocations
ADD CONSTRAINT fk_payment_allocations_payment
FOREIGN KEY (payment_id) REFERENCES payments (payment_id)
ON UPDATE CASCADE ON DELETE RESTRICT,
ADD CONSTRAINT fk_payment_allocations_invoice
FOREIGN KEY (invoice_id) REFERENCES invoices (invoice_id)
ON UPDATE CASCADE ON DELETE RESTRICT,
ADD CONSTRAINT chk_payment_allocations_amount
CHECK (amount_applied > 0);