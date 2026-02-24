-- ETL from raw denormalized table into normalized tables
USE clinic;

INSERT INTO dim_patient (full_name, dob, phone, email, address, status)
SELECT DISTINCT r.patient_full_name, r.patient_dob, r.patient_phone, r.patient_email, r.patient_address, r.patient_status
FROM raw_clinic_intake r;

INSERT INTO dim_doctor (full_name, specialty)
SELECT DISTINCT r.doctor_full_name, r.doctor_specialty
FROM raw_clinic_intake r;

INSERT INTO dim_appointment (start, status, reason)
SELECT DISTINCT r.appointment_start, r.appointment_status, r.appointment_reason
FROM raw_clinic_intake r;

INSERT INTO dim_invoice (number, total, status)
SELECT DISTINCT r.invoice_number, r.invoice_total, r.invoice_status
FROM raw_clinic_intake r;

INSERT INTO dim_payment (date, method, amount)
SELECT DISTINCT r.payment_date, r.payment_method, r.payment_amount
FROM raw_clinic_intake r;

INSERT INTO fact_clinic_intake (patient_id, doctor_id, appointment_id, invoice_id, payment_id, source_row_id)
SELECT
    d_patient.patient_id,
    d_doctor.doctor_id,
    d_appointment.appointment_id,
    d_invoice.invoice_id,
    d_payment.payment_id,
    r.intake_id
FROM raw_clinic_intake r
LEFT JOIN dim_patient d_patient ON r.patient_full_name <=> d_patient.full_name AND r.patient_dob <=> d_patient.dob AND r.patient_phone <=> d_patient.phone AND r.patient_email <=> d_patient.email AND r.patient_address <=> d_patient.address AND r.patient_status <=> d_patient.status
LEFT JOIN dim_doctor d_doctor ON r.doctor_full_name <=> d_doctor.full_name AND r.doctor_specialty <=> d_doctor.specialty
LEFT JOIN dim_appointment d_appointment ON r.appointment_start <=> d_appointment.start AND r.appointment_status <=> d_appointment.status AND r.appointment_reason <=> d_appointment.reason
LEFT JOIN dim_invoice d_invoice ON r.invoice_number <=> d_invoice.number AND r.invoice_total <=> d_invoice.total AND r.invoice_status <=> d_invoice.status
LEFT JOIN dim_payment d_payment ON r.payment_date <=> d_payment.date AND r.payment_method <=> d_payment.method AND r.payment_amount <=> d_payment.amount
;
