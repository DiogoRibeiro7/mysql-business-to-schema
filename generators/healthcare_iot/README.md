# Healthcare IoT Patient Monitoring Data Generator

## Overview

Generates synthetic data for a hospital IoT patient monitoring system including medical devices, vital signs, alerts, clinical workflows, and HIPAA-compliant audit trails.

## Features

### Data Generated

1. **Healthcare Infrastructure**
   - Hospitals (3 facilities)
   - Departments (15 units, 5 per hospital)
   - Medical Staff (50 healthcare providers)
   - Patient Registry (100 patients)

2. **Medical Devices**
   - Device Fleet (150 connected devices)
   - Heart Rate Monitors
   - Blood Pressure Monitors
   - Pulse Oximeters
   - Temperature Sensors
   - Glucose Monitors
   - Ventilators
   - ECG Monitors
   - Infusion Pumps

3. **Patient Monitoring**
   - Continuous vital signs (96 readings/day)
   - Real-time alerts
   - Clinical events
   - Medication administration

4. **Clinical Workflows**
   - Admission/discharge records
   - Nursing assessments
   - Physician rounds
   - Alert response times

5. **Compliance & Security**
   - HIPAA audit trails
   - Device access logs
   - Data encryption metadata
   - PHI access controls

## Configuration

Edit `config.yaml` to adjust:

```yaml
counts:
  hospitals: 3                      # Healthcare facilities
  departments: 15                   # Clinical departments
  patients: 100                     # Active patients
  devices: 150                      # Medical devices
  medical_staff: 50                 # Healthcare providers
  readings_per_patient_per_day: 96  # Every 15 minutes
  alerts_per_day: 20                # Clinical alerts
  days_of_data: 7                   # Historical period

date_ranges:
  admission_start: "2025-01-01"
  admission_end: "2025-01-31"
  data_start: "2025-01-25"
  data_end: "2025-02-01"
```

### Hospital Types

| Type | Percentage | Beds | Specialties | Technology Level |
|------|------------|------|-------------|-----------------|
| General | 40% | 200-500 | All departments | Standard |
| Specialty | 30% | 100-300 | Focused care | Advanced |
| Teaching | 20% | 300-800 | Research | Cutting-edge |
| Community | 10% | 50-150 | Basic care | Essential |

### Department Distribution

- Emergency (24/7 critical care)
- ICU (Intensive monitoring)
- Cardiology (Heart conditions)
- Neurology (Neurological care)
- Surgery (Pre/post-operative)
- Pediatrics (Child care)
- Oncology (Cancer treatment)
- Orthopedics (Musculoskeletal)
- Maternity (Obstetrics)
- Psychiatry (Mental health)

### Medical Device Types

| Device | Parameters | Frequency | Critical Use |
|--------|-----------|-----------|--------------|
| Heart Rate Monitor | HR, HRV | 60 sec | Cardiac patients |
| Blood Pressure | Systolic, Diastolic, MAP | 15 min | Hypertension |
| Pulse Oximeter | SpO2, Pulse | 5 min | Respiratory |
| Temperature | Body temp | 30 min | Infection monitoring |
| Glucose Monitor | Blood sugar | 1 hour | Diabetes |
| Ventilator | RR, TV, PEEP | 60 sec | Critical care |
| ECG | Rhythm, ST, QT | 1 sec | Cardiac monitoring |
| Infusion Pump | Flow rate, Volume | 60 sec | Medication delivery |

## Usage

```bash
cd generators/healthcare_iot
python generate.py
```

## Output Files

All files are generated in the `output/` directory:

### Healthcare Infrastructure

- `hospitals.csv` - Facility information
- `departments.csv` - Department details
- `medical_staff.csv` - Provider profiles
- `patients.csv` - Patient demographics (de-identified)

### Medical Devices

- `devices.csv` - Device inventory
- `device_assignments.csv` - Patient-device mapping
- `device_calibrations.csv` - Calibration records
- `device_maintenance.csv` - Service history

### Clinical Data

- `vital_signs.csv` - All vital sign readings
- `alerts.csv` - Clinical alerts and alarms
- `clinical_events.csv` - Significant events
- `medications.csv` - Drug administration

### Time Series Data

- `heart_rate_readings.csv` - Continuous HR monitoring
- `blood_pressure_readings.csv` - BP measurements
- `spo2_readings.csv` - Oxygen saturation
- `temperature_readings.csv` - Body temperature
- `glucose_readings.csv` - Blood sugar levels

### Alert Management

- `alert_rules.csv` - Alert configuration
- `alert_responses.csv` - Staff response times
- `escalations.csv` - Alert escalation chains
- `false_positives.csv` - Alert accuracy tracking

### Compliance Data

- `audit_logs.csv` - HIPAA audit trail
- `access_logs.csv` - PHI access records
- `consent_records.csv` - Patient consent
- `data_integrity.csv` - Checksums and validation

### Metadata

- `generation_summary.json` - Statistics and configuration

## Data Patterns

### Vital Signs Normal Ranges

| Parameter | Adults | Pediatric | Critical Low | Critical High |
|-----------|--------|-----------|--------------|---------------|
| Heart Rate | 60-100 bpm | 80-140 bpm | <40 | >150 |
| Respiratory | 12-20/min | 20-30/min | <8 | >30 |
| Systolic BP | 110-130 mmHg | 90-110 mmHg | <90 | >180 |
| Diastolic BP | 70-85 mmHg | 60-75 mmHg | <60 | >120 |
| Temperature | 36.5-37.5°C | 36-37.5°C | <35.5 | >38.5 |
| SpO2 | 95-100% | 95-100% | <90 | N/A |
| Glucose | 80-120 mg/dL | 80-140 mg/dL | <70 | >180 |

### Alert Priority Levels

| Level | Response Time | Examples | Escalation |
|-------|--------------|----------|------------|
| Critical | <1 min | Cardiac arrest, SpO2 <85% | Immediate |
| High | <5 min | Abnormal vitals, Equipment failure | Rapid |
| Medium | <15 min | Trending deterioration | Standard |
| Low | <30 min | Minor deviations | Routine |
| Info | As needed | Maintenance due | Scheduled |

### Patient Acuity Distribution

| Acuity | ICU | General Ward | ED | Characteristics |
|--------|-----|--------------|----|-----------------|
| Critical | 60% | 5% | 20% | Continuous monitoring |
| High | 30% | 15% | 30% | Frequent monitoring |
| Medium | 8% | 40% | 30% | Regular monitoring |
| Low | 2% | 40% | 20% | Periodic checks |

### Device Utilization Patterns

**By Department:**
- ICU: 8-10 devices per patient
- Emergency: 4-6 devices per patient
- General Ward: 2-3 devices per patient
- Outpatient: 1-2 devices per visit

**By Time of Day:**
- Morning (6-12): High activity, rounds
- Afternoon (12-18): Moderate, procedures
- Evening (18-24): Reduced, shift change
- Night (0-6): Low, emergency only

## Realistic Features

### Clinical Workflows
- Admission-to-discharge tracking
- Shift handoffs and documentation
- Medication administration records
- Nursing assessment schedules
- Physician rounding patterns

### Alert Fatigue Management
- Smart alert suppression
- Contextual thresholds
- Trend-based alerts
- Alert bundling
- Customizable per patient

### Device Integration
- HL7/FHIR compliance
- Real-time streaming
- Automated calibration checks
- Battery monitoring
- Network connectivity status

### Patient Safety Features
- Fall risk scoring
- Pressure ulcer prevention
- Sepsis early warning
- Medication interaction checks
- Patient identification verification

## HIPAA Compliance Features

### Security Measures
- Encrypted data at rest
- Audit trail for all access
- Role-based access control
- Automatic logoff
- PHI de-identification

### Privacy Controls
- Minimum necessary access
- Consent management
- Data retention policies
- Breach notification readiness
- Business associate agreements

## Performance Notes

- Generation time: 5-10 minutes
- Memory usage: ~300MB
- CSV output: ~250MB for 7 days
- Reading frequency: ~15k readings/day

## Use Cases

1. **Clinical Decision Support**
   - Early warning systems
   - Sepsis detection
   - Deterioration prediction
   - Treatment optimization

2. **Operational Efficiency**
   - Staff allocation
   - Device utilization
   - Alert response optimization
   - Workflow automation

3. **Quality Improvement**
   - Clinical outcomes tracking
   - Protocol compliance
   - Incident analysis
   - Performance benchmarking

4. **Research & Analytics**
   - Clinical trials
   - Population health
   - Predictive modeling
   - Outcome studies

## Sample Queries

After importing the data:

```sql
-- Current patient vital signs with alert status
SELECT
    p.patient_id,
    p.admission_date,
    d.department_name,
    MAX(CASE WHEN vs.parameter = 'heart_rate' THEN vs.value END) as heart_rate,
    MAX(CASE WHEN vs.parameter = 'spo2' THEN vs.value END) as spo2,
    MAX(CASE WHEN vs.parameter = 'systolic' THEN vs.value END) as bp_systolic,
    COUNT(a.alert_id) as active_alerts,
    MAX(a.priority) as highest_priority
FROM patients p
JOIN departments d ON p.department_id = d.department_id
LEFT JOIN vital_signs vs ON p.patient_id = vs.patient_id
    AND vs.timestamp > NOW() - INTERVAL 15 MINUTE
LEFT JOIN alerts a ON p.patient_id = a.patient_id
    AND a.status = 'active'
GROUP BY p.patient_id
ORDER BY highest_priority DESC, active_alerts DESC;

-- Alert response time analysis by department
SELECT
    d.department_name,
    a.priority,
    COUNT(*) as alert_count,
    AVG(TIMESTAMPDIFF(SECOND, a.triggered_at, ar.responded_at)) as avg_response_seconds,
    MIN(TIMESTAMPDIFF(SECOND, a.triggered_at, ar.responded_at)) as min_response,
    MAX(TIMESTAMPDIFF(SECOND, a.triggered_at, ar.responded_at)) as max_response
FROM alerts a
JOIN alert_responses ar ON a.alert_id = ar.alert_id
JOIN departments d ON a.department_id = d.department_id
WHERE a.triggered_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY d.department_id, a.priority
ORDER BY d.department_name, a.priority;

-- Device utilization and reliability
SELECT
    dt.device_type,
    COUNT(DISTINCT d.device_id) as total_devices,
    COUNT(DISTINCT da.patient_id) as patients_monitored,
    SUM(CASE WHEN d.status = 'active' THEN 1 ELSE 0 END) as active_devices,
    AVG(d.battery_level) as avg_battery_level,
    COUNT(dm.maintenance_id) as maintenance_events
FROM devices d
JOIN device_assignments da ON d.device_id = da.device_id
LEFT JOIN device_maintenance dm ON d.device_id = dm.device_id
    AND dm.date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY d.device_type;

-- Early warning score trends
SELECT
    p.patient_id,
    p.admission_date,
    DATE(vs.timestamp) as date,
    -- Modified Early Warning Score (MEWS) calculation
    SUM(
        CASE
            WHEN vs.parameter = 'respiratory_rate' THEN
                CASE
                    WHEN vs.value < 9 THEN 2
                    WHEN vs.value BETWEEN 9 AND 14 THEN 0
                    WHEN vs.value BETWEEN 15 AND 20 THEN 1
                    WHEN vs.value BETWEEN 21 AND 29 THEN 2
                    WHEN vs.value >= 30 THEN 3
                END
            WHEN vs.parameter = 'heart_rate' THEN
                CASE
                    WHEN vs.value < 40 THEN 2
                    WHEN vs.value BETWEEN 40 AND 50 THEN 1
                    WHEN vs.value BETWEEN 51 AND 100 THEN 0
                    WHEN vs.value BETWEEN 101 AND 110 THEN 1
                    WHEN vs.value BETWEEN 111 AND 129 THEN 2
                    WHEN vs.value >= 130 THEN 3
                END
            ELSE 0
        END
    ) as mews_score
FROM patients p
JOIN vital_signs vs ON p.patient_id = vs.patient_id
WHERE vs.timestamp >= DATE_SUB(NOW(), INTERVAL 48 HOUR)
GROUP BY p.patient_id, DATE(vs.timestamp)
HAVING mews_score >= 5
ORDER BY mews_score DESC;
```

## Advanced Features

### Predictive Analytics
- Sepsis prediction algorithms
- Length of stay forecasting
- Readmission risk scoring
- Deterioration prediction
- Resource utilization forecasting

### Integration Capabilities
- EHR/EMR systems
- PACS imaging
- Laboratory systems
- Pharmacy systems
- Billing systems

### Clinical Protocols
- Sepsis bundle compliance
- Falls prevention protocol
- Pressure injury prevention
- Medication reconciliation
- Hand hygiene compliance

### Remote Monitoring
- Telehealth integration
- Home monitoring devices
- Wearable integration
- Mobile health apps
- Virtual rounds

## Customization

Extend the generator for:

1. **Specialized Units**: NICU, burn unit, trauma
2. **Wearables**: Smartwatches, patches
3. **Imaging**: CT, MRI, X-ray metadata
4. **Laboratory**: Lab result integration
5. **Pharmacy**: Medication dispensing

## Notes

- HIPAA-compliant data structure
- No real patient information
- Follows HL7/FHIR standards
- Realistic clinical patterns
- Suitable for healthcare IT demos