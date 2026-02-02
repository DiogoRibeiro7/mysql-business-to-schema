-- Joins: appointments with patient + doctor

-- 1) Appointment list with patient and doctor names (expect: readable schedule rows)
SELECT a.appointment_id,
       a.start_time,
       a.status,
       p.first_name AS patient_first_name,
       p.last_name AS patient_last_name,
       d.first_name AS doctor_first_name,
       d.last_name AS doctor_last_name
FROM appointments a
JOIN patients p ON p.patient_id = a.patient_id
JOIN doctors d ON d.doctor_id = a.doctor_id
ORDER BY a.start_time;

-- 2) Upcoming appointments by doctor (expect: grouped by doctor)
SELECT d.doctor_id, d.first_name, d.last_name, a.appointment_id, a.start_time, a.status
FROM doctors d
JOIN appointments a ON a.doctor_id = d.doctor_id
WHERE a.start_time >= CURRENT_DATE()
ORDER BY d.last_name, a.start_time;

-- 3) Appointments with specialty (expect: specialty attached to appointment)
SELECT a.appointment_id, a.start_time, s.name AS specialty
FROM appointments a
JOIN doctor_specialties ds ON ds.doctor_id = a.doctor_id
JOIN specialties s ON s.specialty_id = ds.specialty_id
ORDER BY a.start_time;

-- 4) Invoice items with appointment details (expect: invoice lines with visit)
SELECT ii.invoice_item_id,
       ii.invoice_id,
       ii.description,
       a.appointment_id,
       a.start_time
FROM invoice_items ii
JOIN appointments a ON a.appointment_id = ii.appointment_id
ORDER BY ii.invoice_id, ii.invoice_item_id;

-- 5) Invoices with patient name (expect: invoice summary by patient)
SELECT i.invoice_id, i.invoice_number, i.issued_at, i.total_amount,
       p.first_name, p.last_name
FROM invoices i
JOIN patients p ON p.patient_id = i.patient_id
ORDER BY i.issued_at DESC;

-- 6) Payments with patient name (expect: payment list)
SELECT pay.payment_id, pay.amount, pay.payment_date,
       p.first_name, p.last_name
FROM payments pay
JOIN patients p ON p.patient_id = pay.patient_id
ORDER BY pay.payment_date DESC;

-- 7) Payments allocated to invoices (expect: payment-to-invoice mapping)
SELECT pa.payment_id, pa.invoice_id, pa.amount_applied,
       i.invoice_number, i.total_amount
FROM payment_allocations pa
JOIN invoices i ON i.invoice_id = pa.invoice_id
ORDER BY pa.payment_id;

-- 8) Appointments with invoice status (expect: appointment billed status)
SELECT a.appointment_id, a.start_time, i.status AS invoice_status
FROM appointments a
JOIN invoice_items ii ON ii.appointment_id = a.appointment_id
JOIN invoices i ON i.invoice_id = ii.invoice_id
ORDER BY a.start_time;

-- 9) Doctors and their specialties (expect: many-to-many listing)
SELECT d.doctor_id, d.first_name, d.last_name, s.name AS specialty
FROM doctors d
JOIN doctor_specialties ds ON ds.doctor_id = d.doctor_id
JOIN specialties s ON s.specialty_id = ds.specialty_id
ORDER BY d.last_name, s.name;
