-- Constraints
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
