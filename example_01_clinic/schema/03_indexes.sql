-- Indexes
CREATE INDEX idx_appointments_doctor_start
  ON appointments (doctor_id, start_time);

CREATE INDEX idx_appointments_patient_start
  ON appointments (patient_id, start_time);

CREATE INDEX idx_invoices_patient_issued
  ON invoices (patient_id, issued_at);

CREATE INDEX idx_invoice_items_invoice
  ON invoice_items (invoice_id);

CREATE INDEX idx_payments_patient_date
  ON payments (patient_id, payment_date);

CREATE INDEX idx_payment_allocations_invoice
  ON payment_allocations (invoice_id);
