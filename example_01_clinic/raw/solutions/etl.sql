-- ETL from raw denormalized table into normalized tables
USE clinic;

INSERT INTO dim_patient (full_name, first_name, last_name, dob, phone, email, address_line_1, address_city, address_state, address_postal_code, address_country, status, created_at, updated_at)
SELECT DISTINCT r.patient_full_name, SUBSTRING_INDEX(r.patient_full_name, ' ', 1), CASE WHEN INSTR(r.patient_full_name, ' ') > 0 THEN SUBSTRING(r.patient_full_name, INSTR(r.patient_full_name, ' ') + 1) ELSE '' END, r.patient_dob, r.patient_phone, r.patient_email, r.patient_address, NULL, NULL, NULL, NULL, r.patient_status, NOW(), NOW()
FROM raw_clinic_intake r;

INSERT INTO dim_doctor (full_name, first_name, last_name, specialty, created_at, updated_at)
SELECT DISTINCT r.doctor_full_name, SUBSTRING_INDEX(r.doctor_full_name, ' ', 1), CASE WHEN INSTR(r.doctor_full_name, ' ') > 0 THEN SUBSTRING(r.doctor_full_name, INSTR(r.doctor_full_name, ' ') + 1) ELSE '' END, r.doctor_specialty, NOW(), NOW()
FROM raw_clinic_intake r;

INSERT INTO dim_appointment (start, status, reason, created_at, updated_at)
SELECT DISTINCT r.appointment_start, r.appointment_status, r.appointment_reason, NOW(), NOW()
FROM raw_clinic_intake r;

INSERT INTO dim_invoice (number, total, status, created_at, updated_at)
SELECT DISTINCT r.invoice_number, r.invoice_total, r.invoice_status, NOW(), NOW()
FROM raw_clinic_intake r;

INSERT INTO dim_payment (date, method, amount, created_at, updated_at)
SELECT DISTINCT r.payment_date, r.payment_method, r.payment_amount, NOW(), NOW()
FROM raw_clinic_intake r;

INSERT INTO fact_clinic_intake (patient_id, doctor_id, appointment_id, invoice_id, payment_id, source_row_id, created_at, updated_at)
SELECT
    d_patient.patient_id,
    d_doctor.doctor_id,
    d_appointment.appointment_id,
    d_invoice.invoice_id,
    d_payment.payment_id,
    r.intake_id,
    NOW(),
    NOW()
FROM raw_clinic_intake r
LEFT JOIN dim_patient d_patient ON r.patient_full_name <=> d_patient.full_name AND SUBSTRING_INDEX(r.patient_full_name, ' ', 1) <=> d_patient.first_name AND CASE WHEN INSTR(r.patient_full_name, ' ') > 0 THEN SUBSTRING(r.patient_full_name, INSTR(r.patient_full_name, ' ') + 1) ELSE '' END <=> d_patient.last_name AND r.patient_dob <=> d_patient.dob AND r.patient_phone <=> d_patient.phone AND r.patient_email <=> d_patient.email AND r.patient_address <=> d_patient.address_line_1 AND d_patient.address_city IS NULL AND d_patient.address_state IS NULL AND d_patient.address_postal_code IS NULL AND d_patient.address_country IS NULL AND r.patient_status <=> d_patient.status
LEFT JOIN dim_doctor d_doctor ON r.doctor_full_name <=> d_doctor.full_name AND SUBSTRING_INDEX(r.doctor_full_name, ' ', 1) <=> d_doctor.first_name AND CASE WHEN INSTR(r.doctor_full_name, ' ') > 0 THEN SUBSTRING(r.doctor_full_name, INSTR(r.doctor_full_name, ' ') + 1) ELSE '' END <=> d_doctor.last_name AND r.doctor_specialty <=> d_doctor.specialty
LEFT JOIN dim_appointment d_appointment ON r.appointment_start <=> d_appointment.start AND r.appointment_status <=> d_appointment.status AND r.appointment_reason <=> d_appointment.reason
LEFT JOIN dim_invoice d_invoice ON r.invoice_number <=> d_invoice.number AND r.invoice_total <=> d_invoice.total AND r.invoice_status <=> d_invoice.status
LEFT JOIN dim_payment d_payment ON r.payment_date <=> d_payment.date AND r.payment_method <=> d_payment.method AND r.payment_amount <=> d_payment.amount
;
