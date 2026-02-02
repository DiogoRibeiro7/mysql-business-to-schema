-- Aggregations: revenue per doctor per month

-- 1) Monthly revenue per doctor (expect: month + doctor totals)
SELECT d.doctor_id,
       d.first_name,
       d.last_name,
       DATE_FORMAT(i.issued_at, '%Y-%m') AS revenue_month,
       SUM(ii.line_total) AS revenue
FROM invoice_items ii
JOIN invoices i ON i.invoice_id = ii.invoice_id
JOIN appointments a ON a.appointment_id = ii.appointment_id
JOIN doctors d ON d.doctor_id = a.doctor_id
GROUP BY d.doctor_id, revenue_month
ORDER BY revenue_month, revenue DESC;

-- 2) Total revenue by specialty (expect: sum per specialty)
SELECT s.name AS specialty,
       SUM(ii.line_total) AS revenue
FROM invoice_items ii
JOIN appointments a ON a.appointment_id = ii.appointment_id
JOIN doctor_specialties ds ON ds.doctor_id = a.doctor_id
JOIN specialties s ON s.specialty_id = ds.specialty_id
GROUP BY s.specialty_id
ORDER BY revenue DESC;

-- 3) Appointment counts by status (expect: counts per status)
SELECT status, COUNT(*) AS count_appointments
FROM appointments
GROUP BY status
ORDER BY count_appointments DESC;

-- 4) No-show rate by doctor (expect: no_show ratio)
SELECT d.doctor_id,
       d.first_name,
       d.last_name,
       SUM(CASE WHEN a.status = 'no_show' THEN 1 ELSE 0 END) AS no_shows,
       COUNT(*) AS total,
       ROUND(SUM(CASE WHEN a.status = 'no_show' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS no_show_rate_pct
FROM appointments a
JOIN doctors d ON d.doctor_id = a.doctor_id
GROUP BY d.doctor_id
ORDER BY no_show_rate_pct DESC;

-- 5) Daily appointment volume (expect: counts per day)
SELECT DATE(a.start_time) AS appt_day, COUNT(*) AS total
FROM appointments a
GROUP BY appt_day
ORDER BY appt_day;

-- 6) Average invoice total (expect: single value)
SELECT ROUND(AVG(total_amount), 2) AS avg_invoice_total
FROM invoices;

-- 7) Payments collected per month (expect: sums per month)
SELECT DATE_FORMAT(payment_date, '%Y-%m') AS pay_month,
       SUM(amount) AS total_collected
FROM payments
GROUP BY pay_month
ORDER BY pay_month;

-- 8) Outstanding balance by patient (expect: open/partial totals)
SELECT p.patient_id,
       p.first_name,
       p.last_name,
       SUM(i.total_amount) AS total_invoiced
FROM invoices i
JOIN patients p ON p.patient_id = i.patient_id
WHERE i.status IN ('open', 'partially_paid')
GROUP BY p.patient_id
ORDER BY total_invoiced DESC;

-- 9) Top 10 doctors by revenue (expect: top earners)
SELECT d.doctor_id,
       d.first_name,
       d.last_name,
       SUM(ii.line_total) AS revenue
FROM invoice_items ii
JOIN appointments a ON a.appointment_id = ii.appointment_id
JOIN doctors d ON d.doctor_id = a.doctor_id
GROUP BY d.doctor_id
ORDER BY revenue DESC
LIMIT 10;
