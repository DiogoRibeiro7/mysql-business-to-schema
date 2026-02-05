# Medical Clinic Data Generator

## Overview

Generates synthetic data for a medical clinic management system, including patient records, doctor profiles, appointments, billing, and payment tracking.

## Features

### Data Generated

1. **Core Entities**
   - Patients (30 records by default)
   - Doctors (10 practitioners)
   - Medical specializations

2. **Appointment Management**
   - Appointment scheduling (200 appointments)
   - Status tracking (scheduled, completed, cancelled, no-show)
   - Time slot management
   - Doctor-patient assignments

3. **Billing System**
   - Invoices (120 invoices)
   - Service charges
   - Payment tracking (150 payments)
   - Partial payment support

## Configuration

Edit `config.yaml` to adjust:

```yaml
counts:
  patients: 30        # Number of patients
  doctors: 10         # Number of doctors
  appointments: 200   # Total appointments
  invoices: 120      # Billing records
  payments: 150      # Payment transactions

date_ranges:
  appointments_start: "2025-02-01"
  appointments_end: "2025-03-31"
  invoices_start: "2025-02-01"
  invoices_end: "2025-03-31"
  payments_start: "2025-02-02"
  payments_end: "2025-04-15"
```

### Medical Specializations

- General Practice
- Pediatrics
- Cardiology
- Dermatology
- Orthopedics
- Psychiatry
- Gynecology
- Neurology
- Ophthalmology
- ENT

### Appointment Status Distribution

- **Completed (70%)**: Successfully completed appointments
- **Scheduled (15%)**: Upcoming appointments
- **Cancelled (10%)**: Cancelled by patient/doctor
- **No-show (5%)**: Patient didn't attend

## Usage

```bash
cd generators/clinic
python generate.py
```

## Output Files

All files are generated in the `output/` directory:

### Core Data Files

- `patients.csv` - Patient demographics and contact info
- `doctors.csv` - Doctor profiles with specializations
- `appointments.csv` - Appointment schedule and status

### Financial Data

- `invoices.csv` - Billing records with amounts
- `payments.csv` - Payment transactions with methods

### Metadata

- `generation_summary.json` - Statistics and configuration

## Data Patterns

### Appointment Patterns

- **Peak Hours**: 9 AM - 12 PM (40%), 2 PM - 5 PM (35%)
- **Day Distribution**: Higher on weekdays
- **Duration**: 15-60 minutes based on appointment type
- **Lead Time**: 1-30 days advance booking

### Patient Demographics

| Age Group | Distribution | Appointment Frequency |
|-----------|--------------|----------------------|
| 0-17 | 15% | Pediatric visits |
| 18-35 | 25% | General/preventive |
| 36-50 | 30% | Mixed specialties |
| 51-65 | 20% | Chronic conditions |
| 65+ | 10% | Regular monitoring |

### Billing Patterns

- **Service Charges**: $50 - $500 per appointment
- **Insurance Coverage**: 60% of patients
- **Payment Timeline**: 0-45 days from invoice
- **Partial Payments**: 20% of transactions

### Payment Methods

- Credit Card (40%)
- Insurance (30%)
- Cash (20%)
- Bank Transfer (10%)

## Realistic Features

### Patient Data
- Consistent phone number formats
- Age-appropriate medical needs
- Realistic address generation
- Emergency contact information

### Doctor Scheduling
- No double-booking
- Appropriate patient load
- Specialty-based appointment duration
- Break times included

### Financial Realism
- Invoice-payment relationships
- Outstanding balance tracking
- Payment date after invoice date
- Partial payment scenarios

## Business Rules Enforced

1. **Appointment Constraints**
   - One doctor per time slot
   - Appointments within business hours
   - No weekend appointments (configurable)
   - Minimum 15-minute slots

2. **Billing Rules**
   - Invoice generated after appointment
   - Payments never exceed invoice amount
   - Payment date >= Invoice date
   - Cancelled appointments may have cancellation fees

3. **Data Integrity**
   - Referential integrity maintained
   - No orphaned records
   - Consistent date relationships
   - Valid status transitions

## Performance Notes

- Generation time: < 1 minute
- Memory efficient for up to 100,000 records
- CSV format for easy import
- Deterministic with seed value

## Use Cases

1. **System Testing**
   - Load testing appointment systems
   - Billing workflow validation
   - Report generation testing

2. **Development**
   - UI/UX prototyping
   - API development
   - Database design validation

3. **Training**
   - Staff training environments
   - Medical billing education
   - System demonstrations

4. **Analytics**
   - Revenue analysis
   - Appointment optimization
   - No-show pattern analysis
   - Doctor utilization studies

## Sample Queries

After importing the data, you can run analytics like:

```sql
-- Monthly revenue per doctor
SELECT
    d.doctor_id,
    d.name,
    DATE_FORMAT(i.issued_at, '%Y-%m') as month,
    SUM(i.total_amount) as revenue
FROM doctors d
JOIN appointments a ON d.doctor_id = a.doctor_id
JOIN invoices i ON a.appointment_id = i.appointment_id
GROUP BY d.doctor_id, month;

-- No-show rate analysis
SELECT
    doctor_id,
    COUNT(CASE WHEN status = 'no-show' THEN 1 END) as no_shows,
    COUNT(*) as total_appointments,
    ROUND(COUNT(CASE WHEN status = 'no-show' THEN 1 END) * 100.0 / COUNT(*), 2) as no_show_rate
FROM appointments
GROUP BY doctor_id;
```

## Customization

The generator supports easy customization:

1. **Add Specializations**: Modify the `SPECIALIZATIONS` list
2. **Adjust Distributions**: Change probability weights
3. **Add Fields**: Extend the data classes
4. **Custom Rules**: Add business logic validations

## Notes

- All personal data is synthetic and randomly generated
- No real patient information is used or referenced
- Suitable for HIPAA-compliant training environments
- Dates are relative to configuration for repeatability