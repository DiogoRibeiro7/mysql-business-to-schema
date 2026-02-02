# Business Problem

## Clinic scenario
The clinic provides outpatient medical services. Patients book appointments with doctors for specific date/time slots. Appointments can be completed, cancelled, or marked as no-show. Each appointment generates billing: either a single invoice per appointment or a bundled invoice that groups multiple appointments for the same patient. Payments can be partial and can be applied over time to one or more invoices.

## Goals
- Track patients, doctors, services, and appointments over time.
- Record appointment outcomes (completed, cancelled, no-show) with reasons and timestamps.
- Issue invoices per appointment or as bundled invoices.
- Accept and apply partial payments.
- Produce operational and financial reporting (daily schedules, revenue, no-show rates).
