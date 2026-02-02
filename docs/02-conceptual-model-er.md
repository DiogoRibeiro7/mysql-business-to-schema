# Conceptual Model (ER)

This is a text-only ER description using names that map directly to future tables.

## Entities and keys
- Patient (patient_id PK)
- Doctor (doctor_id PK)
- Service (service_id PK)
- Appointment (appointment_id PK)
- AppointmentService (appointment_service_id PK)
- Invoice (invoice_id PK)
- InvoiceItem (invoice_item_id PK)
- Payment (payment_id PK)
- PaymentAllocation (payment_allocation_id PK)

## Relationships, cardinalities, optionality
- Patient 1..* Appointment
  - Each Appointment must reference exactly one Patient (mandatory).
  - A Patient can have zero or many Appointments.

- Doctor 1..* Appointment
  - Each Appointment must reference exactly one Doctor (mandatory).
  - A Doctor can have zero or many Appointments.

- Appointment 1..* AppointmentService
  - Each Appointment must have at least one AppointmentService (mandatory).
  - Each AppointmentService belongs to exactly one Appointment.

- Service 1..* AppointmentService
  - Each AppointmentService must reference exactly one Service (mandatory).
  - A Service can appear in zero or many AppointmentService rows.

- Patient 1..* Invoice
  - Each Invoice must reference exactly one Patient (mandatory).
  - A Patient can have zero or many Invoices.

- Invoice 1..* InvoiceItem
  - Each Invoice must have at least one InvoiceItem (mandatory).
  - Each InvoiceItem belongs to exactly one Invoice.

- Appointment 0..* InvoiceItem
  - An InvoiceItem may reference one Appointment (optional) to tie charges to a visit.
  - An Appointment can appear in zero or many InvoiceItems.

- AppointmentService 0..* InvoiceItem
  - An InvoiceItem may reference one AppointmentService (optional) to tie charges to a specific service line.
  - An AppointmentService can appear in zero or many InvoiceItems.

- Patient 1..* Payment
  - Each Payment must reference exactly one Patient (mandatory).
  - A Patient can have zero or many Payments.

- Payment 1..* PaymentAllocation
  - Each Payment can be split across one or many PaymentAllocation rows.
  - Each PaymentAllocation belongs to exactly one Payment (mandatory).

- Invoice 1..* PaymentAllocation
  - Each PaymentAllocation must reference exactly one Invoice (mandatory).
  - Each Invoice can have zero or many PaymentAllocation rows.

## Key notes and optionality
- All primary keys are surrogate IDs.
- Foreign keys from child to parent are mandatory unless noted as optional above.
- Optional relationships: InvoiceItem → Appointment, InvoiceItem → AppointmentService (both nullable).
- Time overlap rule: a Doctor cannot have overlapping Appointments in time (constraint at relational level).
