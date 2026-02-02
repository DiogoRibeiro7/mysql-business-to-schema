# Requirements

## Entities and attributes

### Patient
- patient_id (PK)
- first_name
- last_name
- date_of_birth
- phone
- email
- created_at
- status (active, inactive)

### Doctor
- doctor_id (PK)
- first_name
- last_name
- specialty
- email
- phone
- active_from
- active_to (nullable)

### Service
- service_id (PK)
- code (clinic-specific unique code)
- name
- description
- base_price
- active (boolean)

### Appointment
- appointment_id (PK)
- patient_id (FK)
- doctor_id (FK)
- scheduled_start (datetime)
- scheduled_end (datetime)
- status (scheduled, completed, cancelled, no_show)
- cancel_reason (nullable)
- no_show_reason (nullable)
- created_at
- updated_at

### Appointment Service (line items)
- appointment_service_id (PK)
- appointment_id (FK)
- service_id (FK)
- quantity
- unit_price (captured at booking time)

### Invoice
- invoice_id (PK)
- patient_id (FK)
- invoice_number (unique)
- invoice_date
- status (open, partially_paid, paid, void)
- total_amount

### Invoice Item
- invoice_item_id (PK)
- invoice_id (FK)
- appointment_id (FK, nullable for bundled-only lines if needed)
- appointment_service_id (FK, nullable)
- description
- quantity
- unit_price
- line_total

### Payment
- payment_id (PK)
- patient_id (FK)
- payment_date
- method (cash, card, transfer, other)
- reference (nullable)
- amount

### Payment Allocation
- payment_allocation_id (PK)
- payment_id (FK)
- invoice_id (FK)
- amount_applied

## Business rules
- A patient can have many appointments; each appointment belongs to exactly one patient.
- A doctor can have many appointments; each appointment is assigned to exactly one doctor.
- An appointment must have a scheduled_start and scheduled_end; scheduled_end must be after scheduled_start.
- No two appointments for the same doctor may overlap in time.
- Appointment status is required and limited to: scheduled, completed, cancelled, no_show.
- If status = cancelled, cancel_reason is required.
- If status = no_show, no_show_reason is required.
- A service code is unique within the clinic.
- Each appointment must have at least one appointment_service line item.
- Invoice_number is unique and human-readable.
- An invoice can represent a single appointment or bundle multiple appointments for the same patient.
- An invoice must have at least one invoice item.
- Invoice items that reference appointments must belong to the same patient as the invoice.
- Payment amount must be positive.
- Payment allocations cannot exceed the payment amount.
- The sum of allocations for an invoice cannot exceed invoice total_amount.
- Invoice status rules:
  - open: 0 paid
  - partially_paid: 0 < paid < total_amount
  - paid: paid = total_amount
  - void: invoice not collectible; allocations must be 0

## Reporting needs
- Top 10 doctors by revenue for a given date range.
- Daily schedule for a given date (doctor, patient, time, status).
- No-show rate by doctor and by clinic for a given date range.
