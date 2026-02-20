# Clinic Normalization Tasks

## Goal
Normalize the denormalized intake data in `raw_clinic_intake` into a clean schema.

## 1NF
- Split repeated information (patient, doctor) into separate entities.
- Ensure atomic values for address/phone/email where applicable.

## 2NF
- Remove partial dependencies from any composite keys you introduce.

## 3NF
- Remove transitive dependencies (e.g., invoice/payment fields mixed with appointments).

## Suggested Target Entities
- patients
- doctors
- appointments
- invoices
- payments

## Deliverables
- `normalized_schema.sql`
- `etl.sql` to move data from `raw_clinic_intake` into your normalized schema
- Short note explaining the key functional dependencies you used
