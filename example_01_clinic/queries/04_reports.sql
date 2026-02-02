-- Reports and views

-- 1) Create view for daily schedule (expect: appointment list by date)
CREATE OR REPLACE VIEW v_daily_schedule AS
SELECT a.appointment_id,
       DATE(a.start_time) AS schedule_date,
       a.start_time,
       a.end_time,
       a.status,
       p.first_name AS patient_first_name,
       p.last_name AS patient_last_name,
       d.first_name AS doctor_first_name,
       d.last_name AS doctor_last_name
FROM appointments a
JOIN patients p ON p.patient_id = a.patient_id
JOIN doctors d ON d.doctor_id = a.doctor_id;

-- 2) Use v_daily_schedule for a specific date (expect: rows for that day)
SELECT *
FROM v_daily_schedule
WHERE schedule_date = '2025-02-10'
ORDER BY start_time;

-- 3) Create view for patient balance (expect: invoice total vs paid)
CREATE OR REPLACE VIEW v_patient_balance AS
SELECT i.invoice_id,
       i.patient_id,
       i.total_amount,
       COALESCE(SUM(pa.amount_applied), 0) AS total_paid,
       i.total_amount - COALESCE(SUM(pa.amount_applied), 0) AS balance
FROM invoices i
LEFT JOIN payment_allocations pa ON pa.invoice_id = i.invoice_id
GROUP BY i.invoice_id;

-- 4) Patient balance summary (expect: current balances)
SELECT vb.invoice_id, vb.patient_id, vb.total_amount, vb.total_paid, vb.balance
FROM v_patient_balance vb
ORDER BY vb.balance DESC;

-- 5) Daily revenue report (expect: sum by day)
SELECT DATE(i.issued_at) AS invoice_day, SUM(i.total_amount) AS revenue
FROM invoices i
GROUP BY invoice_day
ORDER BY invoice_day;

-- 6) No-show rate by day (expect: daily no-show percent)
SELECT DATE(start_time) AS appt_day,
       SUM(CASE WHEN status = 'no_show' THEN 1 ELSE 0 END) AS no_shows,
       COUNT(*) AS total,
       ROUND(SUM(CASE WHEN status = 'no_show' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS no_show_rate_pct
FROM appointments
GROUP BY appt_day
ORDER BY appt_day;

-- 7) Top 10 patients by billed amount (expect: biggest totals)
SELECT p.patient_id, p.first_name, p.last_name, SUM(i.total_amount) AS total_billed
FROM invoices i
JOIN patients p ON p.patient_id = i.patient_id
GROUP BY p.patient_id
ORDER BY total_billed DESC
LIMIT 10;

-- 8) Doctor workload per day (expect: count per doctor per day)
SELECT d.doctor_id,
       d.first_name,
       d.last_name,
       DATE(a.start_time) AS appt_day,
       COUNT(*) AS total_appointments
FROM appointments a
JOIN doctors d ON d.doctor_id = a.doctor_id
GROUP BY d.doctor_id, appt_day
ORDER BY appt_day, total_appointments DESC;

-- 9) Patients with unpaid invoices (expect: open or partial only)
SELECT DISTINCT p.patient_id, p.first_name, p.last_name
FROM patients p
JOIN invoices i ON i.patient_id = p.patient_id
WHERE i.status IN ('open', 'partially_paid')
ORDER BY p.last_name, p.first_name;
