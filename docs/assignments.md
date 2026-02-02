# Assignments

Use the generated dataset and schema in this repo. All tasks are specific and testable.

## Assignment 1: Add prescriptions table + constraints (DDL)

### Task
Add a new table `prescriptions` and enforce relationships.

Required columns:
- prescription_id (PK, auto increment)
- appointment_id (FK → appointments.appointment_id, NOT NULL)
- patient_id (FK → patients.patient_id, NOT NULL)
- doctor_id (FK → doctors.doctor_id, NOT NULL)
- medication_name (VARCHAR, NOT NULL)
- dosage (VARCHAR, NOT NULL)
- frequency (VARCHAR, NOT NULL)
- start_date (DATE, NOT NULL)
- end_date (DATE, NULL)
- notes (VARCHAR, NULL)
- created_at (DATETIME, NOT NULL, default current timestamp)

Required constraints:
- FK consistency: appointment, patient, and doctor must all exist.
- Appointment-patient/doctor consistency: prescription.patient_id must match the appointment’s patient_id; prescription.doctor_id must match the appointment’s doctor_id.
- CHECK: end_date is NULL or end_date >= start_date.
- NOT NULLs for required fields.
- No cascading deletes from patients/doctors/appointments (use RESTRICT).

### Deliverable
SQL DDL in `example_01_clinic/schema/04_prescriptions.sql`.

### Test
Insert 1 valid prescription and 1 invalid one (mismatched patient_id vs appointment). The invalid insert must fail.

## Assignment 2: Reporting queries (5 queries)

### Task
Write 5 queries in `example_01_clinic/queries/06_assignments.sql` using generated data.

1) **Monthly revenue per doctor**  
Output columns: doctor_id, doctor_name, month (YYYY-MM), revenue  
Sort by month then revenue descending.

2) **Patient balance report**  
Output columns: patient_id, patient_name, total_invoiced, total_paid, balance  
Include only patients with balance > 0.

3) **No-show rate by doctor**  
Output columns: doctor_id, doctor_name, no_show_count, total_appointments, no_show_rate_pct  
Return all doctors.

4) **Top 5 patients by billed amount**  
Output columns: patient_id, patient_name, total_billed  
Sort descending, limit 5.

5) **Daily schedule for a given doctor**  
Input: a doctor_id and date  
Output columns: appointment_id, start_time, end_time, patient_name, status  
Filter for that day.

### Deliverable
SQL queries with comments in `example_01_clinic/queries/06_assignments.sql`.

### Test
Each query returns at least 1 row on the seed dataset.

## Assignment 3: Index + EXPLAIN comparison

### Task
Choose one of the reporting queries and:
- Add a new index that supports it (e.g., `appointments(doctor_id, start_time)` or `invoices(patient_id, issued_at)`).
- Capture EXPLAIN output before and after the index.

### Deliverable
1) Index DDL in `example_01_clinic/schema/05_assignment_indexes.sql`.  
2) EXPLAIN outputs saved in `docs/assignment_explain.md` (before/after).

### Test
EXPLAIN after the index shows a more selective access path (e.g., range or ref instead of full scan).

## Grading rubric (0–20)
- 0–5: Incomplete or missing deliverables; schema or queries do not run.
- 6–10: Partial implementation; constraints or queries missing; incorrect results.
- 11–15: Fully implemented; minor issues in correctness, comments, or formatting.
- 16–18: Fully correct; clear comments; constraints and queries pass tests.
- 19–20: Excellent: robust constraints, clean EXPLAIN analysis, and thoughtful edge cases.

## Common mistakes
- Missing FK constraints or using CASCADE deletes unintentionally.
- Forgetting to enforce appointment → patient/doctor consistency in prescriptions.
- Using incorrect joins that inflate counts or revenue.
- Not filtering by date boundaries correctly (off-by-one-day errors).
- EXPLAIN run without the same filters or query shape before/after.
