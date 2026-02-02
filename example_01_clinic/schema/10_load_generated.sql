-- Load generated CSVs into MySQL (Docker-friendly)
-- This script expects CSVs copied into /var/lib/mysql-files/clinic_generated/
-- If secure_file_priv is enabled, the path must be inside that directory.
--
-- Files expected:
--   patients.csv, doctors.csv, appointments.csv, invoices.csv, payments.csv

USE clinic;

-- Patients
LOAD DATA INFILE '/var/lib/mysql-files/clinic_generated/patients.csv'
INTO TABLE patients
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(patient_id, nif, first_name, last_name, date_of_birth, phone, email, created_at, status);

-- Doctors (active_to is nullable)
LOAD DATA INFILE '/var/lib/mysql-files/clinic_generated/doctors.csv'
INTO TABLE doctors
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(doctor_id, license_number, first_name, last_name, email, phone, active_from, @active_to)
SET active_to = NULLIF(@active_to, '');

-- Appointments (cancel_reason, no_show_reason nullable)
LOAD DATA INFILE '/var/lib/mysql-files/clinic_generated/appointments.csv'
INTO TABLE appointments
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
  appointment_id,
  patient_id,
  doctor_id,
  start_time,
  end_time,
  status,
  @cancel_reason,
  @no_show_reason,
  created_at,
  updated_at
)
SET
  cancel_reason = NULLIF(@cancel_reason, ''),
  no_show_reason = NULLIF(@no_show_reason, '');

-- Invoices
LOAD DATA INFILE '/var/lib/mysql-files/clinic_generated/invoices.csv'
INTO TABLE invoices
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(invoice_id, patient_id, invoice_number, issued_at, status, total_amount);

-- Payments (reference nullable)
LOAD DATA INFILE '/var/lib/mysql-files/clinic_generated/payments.csv'
INTO TABLE payments
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(payment_id, patient_id, payment_date, method, @reference, amount)
SET reference = NULLIF(@reference, '');
