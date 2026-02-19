-- PostgreSQL Migration Script
-- Generated at: 2026-02-19T08:59:26.796282

BEGIN;

DROP TABLE IF EXISTS patients CASCADE;

CREATE TABLE patients (
    patient_id NUMERIC(20) NOT NULL,
    nif VARCHAR(32) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    phone VARCHAR(40) NOT NULL,
    email VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR
);



DROP TABLE IF EXISTS doctors CASCADE;

CREATE TABLE doctors (
    doctor_id NUMERIC(20) NOT NULL,
    license_number VARCHAR(64) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(40) NOT NULL,
    active_from DATE NOT NULL,
    active_to DATE
);



DROP TABLE IF EXISTS specialties CASCADE;

CREATE TABLE specialties (
    specialty_id NUMERIC(20) NOT NULL,
    code VARCHAR(32) NOT NULL,
    name VARCHAR(120) NOT NULL,
    description VARCHAR(500)
);



DROP TABLE IF EXISTS doctor_specialties CASCADE;

CREATE TABLE doctor_specialties (
    doctor_id NUMERIC(20) NOT NULL,
    specialty_id NUMERIC(20) NOT NULL,
    assigned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY TEXT
);



DROP TABLE IF EXISTS appointments CASCADE;

CREATE TABLE appointments (
    appointment_id NUMERIC(20) NOT NULL,
    patient_id NUMERIC(20) NOT NULL,
    doctor_id NUMERIC(20) NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    status VARCHAR,
    cancel_reason VARCHAR(255),
    no_show_reason VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT 'CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP'
);



DROP TABLE IF EXISTS invoices CASCADE;

CREATE TABLE invoices (
    invoice_id NUMERIC(20) NOT NULL,
    patient_id NUMERIC(20) NOT NULL,
    invoice_number VARCHAR(40) NOT NULL,
    issued_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR,
    total_amount DECIMAL
);



DROP TABLE IF EXISTS invoice_items CASCADE;

CREATE TABLE invoice_items (
    invoice_item_id NUMERIC(20) NOT NULL,
    invoice_id NUMERIC(20) NOT NULL,
    appointment_id NUMERIC(20),
    description VARCHAR(255) NOT NULL,
    quantity BIGINT NOT NULL DEFAULT 1,
    unit_price DECIMAL,
    line_total DECIMAL
);



DROP TABLE IF EXISTS payments CASCADE;

CREATE TABLE payments (
    payment_id NUMERIC(20) NOT NULL,
    patient_id NUMERIC(20) NOT NULL,
    payment_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    method VARCHAR,
    reference VARCHAR(100),
    amount DECIMAL
);



DROP TABLE IF EXISTS payment_allocations CASCADE;

CREATE TABLE payment_allocations (
    payment_allocation_id NUMERIC(20) NOT NULL,
    payment_id NUMERIC(20) NOT NULL,
    invoice_id NUMERIC(20) NOT NULL,
    amount_applied DECIMAL
);



COMMIT;