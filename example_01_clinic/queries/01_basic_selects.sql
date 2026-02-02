-- Basic selects and filters

-- 1) List all active patients (expect: active rows only)
SELECT patient_id, first_name, last_name, status
FROM patients
WHERE status = 'active'
ORDER BY last_name, first_name;

-- 2) Find a patient by NIF (expect: at most one row)
SELECT patient_id, nif, first_name, last_name
FROM patients
WHERE nif = 'PT10000005';

-- 3) Upcoming appointments in next 7 days (expect: scheduled rows only)
SELECT appointment_id, patient_id, doctor_id, start_time, status
FROM appointments
WHERE status = 'scheduled'
  AND start_time >= CURRENT_DATE()
  AND start_time < DATE_ADD(CURRENT_DATE(), INTERVAL 7 DAY)
ORDER BY start_time;

-- 4) Cancelled appointments with reason (expect: cancelled only)
SELECT appointment_id, patient_id, doctor_id, start_time, cancel_reason
FROM appointments
WHERE status = 'cancelled'
ORDER BY start_time DESC;

-- 5) No-show appointments (expect: no_show only)
SELECT appointment_id, patient_id, doctor_id, start_time, no_show_reason
FROM appointments
WHERE status = 'no_show'
ORDER BY start_time DESC;

-- 6) All invoices for a patient (expect: matching patient)
SELECT invoice_id, invoice_number, issued_at, status, total_amount
FROM invoices
WHERE patient_id = 5
ORDER BY issued_at DESC;

-- 7) Open or partially paid invoices (expect: unpaid invoices)
SELECT invoice_id, patient_id, status, total_amount
FROM invoices
WHERE status IN ('open', 'partially_paid')
ORDER BY issued_at DESC;

-- 8) Payments above 50 (expect: larger payments)
SELECT payment_id, patient_id, amount, payment_date
FROM payments
WHERE amount > 50
ORDER BY amount DESC;

-- 9) Doctors currently active (expect: active_to null or in future)
SELECT doctor_id, first_name, last_name, active_from, active_to
FROM doctors
WHERE active_to IS NULL OR active_to >= CURRENT_DATE()
ORDER BY last_name;
