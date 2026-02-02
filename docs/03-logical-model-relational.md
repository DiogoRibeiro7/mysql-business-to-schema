# Logical Model (Relational)

Draft relational schema (table names and keys match the planned SQL implementation):

## patient
- PK: patient_id
- Columns: first_name, last_name, date_of_birth, phone, email, created_at, status

## doctor
- PK: doctor_id
- Columns: first_name, last_name, specialty, email, phone, active_from, active_to

## service
- PK: service_id
- AK: code (unique)
- Columns: name, description, base_price, active

## appointment
- PK: appointment_id
- FK: patient_id → patient.patient_id
- FK: doctor_id → doctor.doctor_id
- Columns: scheduled_start, scheduled_end, status, cancel_reason, no_show_reason, created_at, updated_at

## appointment_service
- PK: appointment_service_id
- FK: appointment_id → appointment.appointment_id
- FK: service_id → service.service_id
- Columns: quantity, unit_price

## invoice
- PK: invoice_id
- AK: invoice_number (unique)
- FK: patient_id → patient.patient_id
- Columns: invoice_date, status, total_amount

## invoice_item
- PK: invoice_item_id
- FK: invoice_id → invoice.invoice_id
- FK (optional): appointment_id → appointment.appointment_id
- FK (optional): appointment_service_id → appointment_service.appointment_service_id
- Columns: description, quantity, unit_price, line_total

## payment
- PK: payment_id
- FK: patient_id → patient.patient_id
- Columns: payment_date, method, reference, amount

## payment_allocation
- PK: payment_allocation_id
- FK: payment_id → payment.payment_id
- FK: invoice_id → invoice.invoice_id
- Columns: amount_applied
