#!/usr/bin/env python3
"""
Healthcare IoT Data Generator

Generates realistic patient monitoring data including:
- Vital signs monitoring
- Medical device readings
- Clinical alerts
- Medication administration
- Staff assignments
Note: All data is synthetic and for educational purposes only
"""

import csv
import random
import yaml
import argparse
from datetime import datetime, timedelta
from pathlib import Path
import math
from typing import List, Dict, Tuple, Any
import hashlib

class HealthcareIoTGenerator:
    def __init__(self, config_path: str):
        """Initialize generator with configuration"""
        with open(config_path, 'r') as f:
            self.config = yaml.safe_load(f)

        self.seed = self.config.get('seed', 42)
        random.seed(self.seed)

        self.output_dir = Path(self.config['output_dir'])
        self.output_dir.mkdir(parents=True, exist_ok=True)

        # Data containers
        self.hospitals = []
        self.departments = []
        self.patients = []
        self.devices = []
        self.device_assignments = []
        self.medical_staff = []
        self.vital_signs = []
        self.device_readings = []
        self.alerts = []
        self.medications = []
        self.clinical_scores = []
        self.staff_assignments = []
        self.audit_logs = []

        # Counters
        self.alert_id = 1
        self.medication_id = 1
        self.assignment_id = 1
        self.audit_id = 1

    def generate_all(self):
        """Generate all data in sequence"""
        print("Generating Healthcare IoT data...")
        print("Note: All patient data is synthetic for educational purposes")

        # Infrastructure
        self._generate_hospitals()
        self._generate_departments()
        self._generate_medical_staff()
        self._generate_patients()
        self._generate_devices()
        self._generate_device_assignments()

        # Clinical data
        self._generate_vital_signs()
        self._generate_device_readings()
        self._generate_alerts()
        self._generate_medications()
        self._generate_clinical_scores()
        self._generate_staff_assignments()
        self._generate_audit_logs()

        # Write to CSV
        self._write_all_csvs()

        # Generate SQL scripts
        self._generate_sql_scripts()

        print(f"[OK] Generated data for {len(self.hospitals)} hospitals, "
              f"{len(self.patients)} patients, {len(self.devices)} devices")
        print(f"[OK] Generated {len(self.vital_signs)} vital sign readings")
        print(f"[OK] Output written to {self.output_dir}")

    def _generate_hospitals(self):
        """Generate hospital facilities"""
        hospital_names = ["City General", "St. Mary's", "Regional Medical"]

        for i in range(self.config['counts']['hospitals']):
            hospital_type = random.choices(
                list(self.config['hospital_types'].keys()),
                weights=list(self.config['hospital_types'].values())
            )[0]

            hospital = {
                'hospital_id': i + 1,
                'hospital_name': f"{hospital_names[i % len(hospital_names)]} Hospital",
                'hospital_type': hospital_type,
                'bed_count': random.randint(100, 500),
                'icu_beds': random.randint(10, 50),
                'address': f"{random.randint(100, 999)} Medical Center Dr",
                'city': f"City_{i+1}",
                'state': random.choice(['CA', 'NY', 'TX', 'FL', 'IL']),
                'accreditation': 'JCAHO',
                'trauma_level': random.choice([1, 2, 3, 4]),
                'is_active': True
            }
            self.hospitals.append(hospital)

    def _generate_departments(self):
        """Generate hospital departments"""
        dept_id = 1

        for hospital in self.hospitals:
            depts_per_hospital = self.config['counts']['departments'] // len(self.hospitals)

            for i in range(min(depts_per_hospital, len(self.config['departments']))):
                department = {
                    'department_id': dept_id,
                    'hospital_id': hospital['hospital_id'],
                    'department_name': self.config['departments'][i],
                    'floor': random.randint(1, 10),
                    'bed_count': random.randint(10, 50),
                    'phone_extension': f"{random.randint(1000, 9999)}",
                    'is_critical_care': self.config['departments'][i] in ['ICU', 'Emergency'],
                    'nurse_ratio': '1:2' if self.config['departments'][i] == 'ICU' else '1:4'
                }
                self.departments.append(department)
                dept_id += 1

    def _generate_medical_staff(self):
        """Generate medical staff members"""
        staff_id = 1
        first_names = ['Dr. Smith', 'Dr. Johnson', 'Nurse Williams', 'Nurse Brown']

        for _ in range(self.config['counts']['medical_staff']):
            role = random.choices(
                list(self.config['staff_roles'].keys()),
                weights=list(self.config['staff_roles'].values())
            )[0]

            staff = {
                'staff_id': staff_id,
                'employee_id': f"EMP{staff_id:05d}",
                'name': f"{random.choice(first_names)}_{staff_id}",
                'role': role,
                'department_id': random.choice(self.departments)['department_id'],
                'specialization': random.choice(['cardiology', 'neurology', 'general', 'pediatrics']),
                'shift': random.choice(['day', 'evening', 'night']),
                'license_number': f"LIC{random.randint(100000, 999999)}",
                'hire_date': datetime.now() - timedelta(days=random.randint(365, 3650)),
                'is_active': True
            }
            self.medical_staff.append(staff)
            staff_id += 1

    def _generate_patients(self):
        """Generate anonymized patient records"""
        patient_id = 1

        for _ in range(self.config['counts']['patients']):
            admission_date = datetime.strptime(
                self.config['date_ranges']['admission_start'], '%Y-%m-%d'
            ) + timedelta(days=random.randint(0, 30))

            # Determine age group
            age_group = random.choice(['pediatric', 'adult', 'elderly'])
            if age_group == 'pediatric':
                age = random.randint(1, 17)
            elif age_group == 'adult':
                age = random.randint(18, 65)
            else:
                age = random.randint(66, 95)

            condition = random.choices(
                list(self.config['patient_conditions'].keys()),
                weights=list(self.config['patient_conditions'].values())
            )[0]

            patient = {
                'patient_id': patient_id,
                'medical_record_number': f"MRN{patient_id:08d}",
                'age': age,
                'age_group': age_group,
                'gender': random.choice(['M', 'F']),
                'admission_date': admission_date,
                'department_id': random.choice(self.departments)['department_id'],
                'bed_number': f"{random.choice(['A', 'B', 'C'])}{random.randint(101, 350)}",
                'condition': condition,
                'primary_diagnosis': f"Diagnosis_{random.randint(1, 100)}",
                'fall_risk': random.choice(['low', 'medium', 'high']),
                'isolation_required': random.random() < 0.1,
                'discharge_date': admission_date + timedelta(days=random.randint(1, 14))
                                 if random.random() > 0.3 else None
            }
            self.patients.append(patient)
            patient_id += 1

    def _generate_devices(self):
        """Generate medical devices"""
        device_id = 1

        for _ in range(self.config['counts']['devices']):
            device_type = random.choice(list(self.config['device_types'].keys()))

            device = {
                'device_id': device_id,
                'serial_number': f"SN{device_id:010d}",
                'device_type': device_type,
                'manufacturer': random.choice(['Medtronic', 'GE Healthcare', 'Philips', 'Siemens']),
                'model': f"Model-{random.choice(['X', 'Y', 'Z'])}{random.randint(100, 999)}",
                'department_id': random.choice(self.departments)['department_id'],
                'installation_date': datetime.now() - timedelta(days=random.randint(30, 1095)),
                'last_calibration': datetime.now() - timedelta(days=random.randint(1, 30)),
                'next_maintenance': datetime.now() + timedelta(days=random.randint(1, 30)),
                'battery_level': random.randint(20, 100) if random.random() > 0.5 else None,
                'firmware_version': f"{random.randint(1, 5)}.{random.randint(0, 9)}.{random.randint(0, 99)}",
                'status': random.choices(['active', 'maintenance', 'standby'],
                                        weights=[0.85, 0.05, 0.10])[0]
            }
            self.devices.append(device)
            device_id += 1

    def _generate_device_assignments(self):
        """Assign devices to patients"""
        assignment_id = 1

        for patient in self.patients:
            # Critical patients get more devices
            if patient['condition'] == 'critical':
                num_devices = random.randint(3, 5)
            elif patient['condition'] == 'monitoring':
                num_devices = random.randint(2, 3)
            else:
                num_devices = random.randint(1, 2)

            assigned_devices = random.sample(self.devices, min(num_devices, len(self.devices)))

            for device in assigned_devices:
                assignment = {
                    'assignment_id': assignment_id,
                    'patient_id': patient['patient_id'],
                    'device_id': device['device_id'],
                    'assigned_at': patient['admission_date'],
                    'unassigned_at': patient['discharge_date'],
                    'assigned_by': random.choice(self.medical_staff)['staff_id'],
                    'notes': None
                }
                self.device_assignments.append(assignment)
                assignment_id += 1

    def _generate_vital_signs(self):
        """Generate vital sign readings"""
        print("  Generating vital signs...")

        # Limit to recent patients for performance
        recent_patients = self.patients[:20]
        start_date = datetime.now() - timedelta(days=2)
        end_date = datetime.now()

        for patient in recent_patients:
            age_group = patient['age_group']
            normal_ranges = self.config['vital_signs']['by_age_group'][age_group]

            current_time = start_date
            reading_count = 0
            max_readings = 200  # Limit per patient

            while current_time <= end_date and reading_count < max_readings:
                # Generate vital signs based on patient condition
                if patient['condition'] == 'critical':
                    hr_variation = 20
                    bp_variation = 15
                else:
                    hr_variation = 10
                    bp_variation = 5

                vital = {
                    'reading_id': len(self.vital_signs) + 1,
                    'patient_id': patient['patient_id'],
                    'timestamp': current_time,
                    'heart_rate': int(random.gauss(
                        sum(normal_ranges['heart_rate']) / 2,
                        hr_variation
                    )),
                    'respiratory_rate': int(random.gauss(
                        sum(normal_ranges['respiratory_rate']) / 2,
                        5
                    )),
                    'systolic_bp': int(random.gauss(120, bp_variation)),
                    'diastolic_bp': int(random.gauss(80, bp_variation / 2)),
                    'temperature': round(random.gauss(37.0, 0.5), 1),
                    'spo2': min(100, int(random.gauss(97, 2))),
                    'recorded_by': random.choice(self.medical_staff)['staff_id']
                }
                self.vital_signs.append(vital)

                current_time += timedelta(minutes=15)
                reading_count += 1

    def _generate_device_readings(self):
        """Generate device-specific readings"""
        print("  Generating device readings...")

        # Limit for performance
        recent_assignments = self.device_assignments[:50]

        for assignment in recent_assignments:
            device = next(d for d in self.devices if d['device_id'] == assignment['device_id'])
            device_config = self.config['device_types'].get(device['device_type'], {})

            if not device_config:
                continue

            # Generate a few readings
            for _ in range(10):  # Limited readings per device
                timestamp = datetime.now() - timedelta(hours=random.randint(0, 48))

                for parameter in device_config.get('parameters', []):
                    thresholds = device_config.get('critical_thresholds', {}).get(parameter, [0, 100])

                    reading = {
                        'reading_id': len(self.device_readings) + 1,
                        'device_id': device['device_id'],
                        'patient_id': assignment['patient_id'],
                        'timestamp': timestamp,
                        'parameter': parameter,
                        'value': round(random.uniform(thresholds[0], thresholds[1]), 2),
                        'unit': self._get_parameter_unit(parameter),
                        'quality': 'good' if device['status'] == 'active' else 'questionable'
                    }
                    self.device_readings.append(reading)

    def _generate_alerts(self):
        """Generate clinical alerts"""
        print("  Generating alerts...")

        start_date = datetime.now() - timedelta(days=self.config['counts']['days_of_data'])
        end_date = datetime.now()
        current_date = start_date

        while current_date <= end_date:
            daily_alerts = self.config['counts']['alerts_per_day']

            for _ in range(daily_alerts):
                alert_type = random.choices(
                    list(self.config['alert_types'].keys()),
                    weights=list(self.config['alert_types'].values())
                )[0]

                severity = random.choices(
                    list(self.config['alert_severity'].keys()),
                    weights=list(self.config['alert_severity'].values())
                )[0]

                patient = random.choice(self.patients)
                triggered_at = current_date + timedelta(hours=random.randint(0, 23))

                alert = {
                    'alert_id': self.alert_id,
                    'patient_id': patient['patient_id'],
                    'alert_type': alert_type,
                    'severity': severity,
                    'triggered_at': triggered_at,
                    'message': self._get_alert_message(alert_type),
                    'acknowledged_by': random.choice(self.medical_staff)['staff_id']
                                      if random.random() > 0.1 else None,
                    'acknowledged_at': triggered_at + timedelta(minutes=random.randint(1, 30))
                                      if random.random() > 0.1 else None,
                    'resolved_at': triggered_at + timedelta(minutes=random.randint(5, 60))
                                  if random.random() > 0.2 else None,
                    'false_positive': random.random() < 0.1
                }
                self.alerts.append(alert)
                self.alert_id += 1

            current_date += timedelta(days=1)

    def _generate_medications(self):
        """Generate medication administration records"""
        print("  Generating medication records...")

        for patient in self.patients[:30]:  # Limit for performance
            # Generate medications based on condition
            num_meds = random.randint(1, 5)
            patient_meds = random.sample(self.config['medications'], min(num_meds, len(self.config['medications'])))

            for med_config in patient_meds:
                # Generate administration times
                for day in range(min(3, self.config['counts']['days_of_data'])):
                    admin_time = datetime.now() - timedelta(days=day)

                    medication = {
                        'medication_id': self.medication_id,
                        'patient_id': patient['patient_id'],
                        'medication_name': med_config['name'],
                        'dose': random.uniform(med_config['typical_dose'][0], med_config['typical_dose'][1]),
                        'unit': med_config['unit'],
                        'route': med_config['route'],
                        'scheduled_time': admin_time,
                        'administered_time': admin_time + timedelta(minutes=random.randint(-15, 30)),
                        'administered_by': random.choice([s for s in self.medical_staff if s['role'] == 'nurse'])['staff_id']
                                         if any(s['role'] == 'nurse' for s in self.medical_staff) else 1,
                        'notes': None
                    }
                    self.medications.append(medication)
                    self.medication_id += 1

    def _generate_clinical_scores(self):
        """Generate clinical scoring (MEWS, SOFA, etc.)"""
        print("  Generating clinical scores...")

        for vital in self.vital_signs[:100]:  # Limit for performance
            # Calculate MEWS score
            mews_score = self._calculate_mews(vital)

            score = {
                'score_id': len(self.clinical_scores) + 1,
                'patient_id': vital['patient_id'],
                'score_type': 'MEWS',
                'score_value': mews_score,
                'timestamp': vital['timestamp'],
                'components': {
                    'heart_rate': self._get_mews_component('heart_rate', vital['heart_rate']),
                    'respiratory_rate': self._get_mews_component('respiratory_rate', vital['respiratory_rate']),
                    'systolic_bp': self._get_mews_component('systolic_bp', vital['systolic_bp']),
                    'temperature': self._get_mews_component('temperature', vital['temperature'])
                },
                'risk_level': 'high' if mews_score >= 5 else 'medium' if mews_score >= 3 else 'low'
            }
            self.clinical_scores.append(score)

    def _generate_staff_assignments(self):
        """Generate staff-patient assignments"""
        print("  Generating staff assignments...")

        for patient in self.patients:
            # Assign primary nurse
            nurses = [s for s in self.medical_staff if s['role'] == 'nurse']
            if nurses:
                assignment = {
                    'assignment_id': self.assignment_id,
                    'staff_id': random.choice(nurses)['staff_id'],
                    'patient_id': patient['patient_id'],
                    'assignment_type': 'primary_nurse',
                    'start_time': patient['admission_date'],
                    'end_time': patient['discharge_date'],
                    'is_active': patient['discharge_date'] is None
                }
                self.staff_assignments.append(assignment)
                self.assignment_id += 1

            # Assign attending physician
            physicians = [s for s in self.medical_staff if s['role'] == 'physician']
            if physicians:
                assignment = {
                    'assignment_id': self.assignment_id,
                    'staff_id': random.choice(physicians)['staff_id'],
                    'patient_id': patient['patient_id'],
                    'assignment_type': 'attending_physician',
                    'start_time': patient['admission_date'],
                    'end_time': patient['discharge_date'],
                    'is_active': patient['discharge_date'] is None
                }
                self.staff_assignments.append(assignment)
                self.assignment_id += 1

    def _generate_audit_logs(self):
        """Generate HIPAA-compliant audit logs"""
        print("  Generating audit logs...")

        # Sample audit events
        for _ in range(100):  # Limited audit entries
            audit = {
                'audit_id': self.audit_id,
                'timestamp': datetime.now() - timedelta(hours=random.randint(0, 168)),
                'user_id': random.choice(self.medical_staff)['staff_id'],
                'patient_id': random.choice(self.patients)['patient_id'],
                'action': random.choice(['view', 'update', 'create', 'export']),
                'resource': random.choice(['vital_signs', 'medications', 'lab_results', 'notes']),
                'ip_address': f"192.168.{random.randint(1, 254)}.{random.randint(1, 254)}",
                'success': random.random() > 0.02,
                'details': 'Access granted' if random.random() > 0.02 else 'Access denied'
            }
            self.audit_logs.append(audit)
            self.audit_id += 1

    # Helper methods
    def _get_parameter_unit(self, parameter: str) -> str:
        """Get unit for device parameter"""
        units = {
            'heart_rate': 'bpm',
            'respiratory_rate': 'breaths/min',
            'temperature': '°C',
            'spo2': '%',
            'glucose': 'mg/dL',
            'systolic': 'mmHg',
            'diastolic': 'mmHg',
            'flow_rate': 'mL/hr'
        }
        return units.get(parameter, '')

    def _get_alert_message(self, alert_type: str) -> str:
        """Get alert message based on type"""
        messages = {
            'vital_sign_critical': 'Critical vital sign detected',
            'device_malfunction': 'Device requires attention',
            'medication_due': 'Medication administration due',
            'fall_detected': 'Potential fall detected',
            'patient_distress': 'Patient call button activated',
            'connection_lost': 'Device connection lost',
            'battery_low': 'Device battery low'
        }
        return messages.get(alert_type, 'Alert triggered')

    def _calculate_mews(self, vital: Dict) -> int:
        """Calculate Modified Early Warning Score"""
        score = 0

        # Heart rate scoring
        if vital['heart_rate'] < 40 or vital['heart_rate'] > 130:
            score += 3
        elif vital['heart_rate'] < 50 or vital['heart_rate'] > 110:
            score += 1

        # Respiratory rate scoring
        if vital['respiratory_rate'] < 9 or vital['respiratory_rate'] > 29:
            score += 3
        elif vital['respiratory_rate'] > 20:
            score += 1

        # Systolic BP scoring
        if vital['systolic_bp'] < 70 or vital['systolic_bp'] > 199:
            score += 3
        elif vital['systolic_bp'] < 81:
            score += 2
        elif vital['systolic_bp'] < 101:
            score += 1

        # Temperature scoring
        if vital['temperature'] < 35 or vital['temperature'] > 39:
            score += 2
        elif vital['temperature'] < 36 or vital['temperature'] > 38:
            score += 1

        return score

    def _get_mews_component(self, parameter: str, value: float) -> int:
        """Get MEWS component score"""
        # Simplified scoring logic
        if parameter == 'heart_rate':
            if value < 40 or value > 130:
                return 3
            elif value < 50 or value > 110:
                return 1
        return 0

    def _write_all_csvs(self):
        """Write all data to CSV files"""
        datasets = [
            ('hospitals', self.hospitals),
            ('departments', self.departments),
            ('medical_staff', self.medical_staff),
            ('patients', self.patients),
            ('devices', self.devices),
            ('device_assignments', self.device_assignments),
            ('vital_signs', self.vital_signs[:5000]),  # Limit for size
            ('device_readings', self.device_readings[:5000]),
            ('alerts', self.alerts),
            ('medications', self.medications),
            ('clinical_scores', self.clinical_scores),
            ('staff_assignments', self.staff_assignments),
            ('audit_logs', self.audit_logs)
        ]

        for filename, data in datasets:
            if not data:
                continue

            filepath = self.output_dir / f"{filename}.csv"
            with open(filepath, 'w', newline='', encoding='utf-8') as f:
                if data:
                    # Handle dict fields
                    if filename == 'clinical_scores':
                        for item in data:
                            if 'components' in item:
                                item['components'] = str(item['components'])

                    writer = csv.DictWriter(f, fieldnames=data[0].keys())
                    writer.writeheader()
                    writer.writerows(data)

            print(f"  [OK] Wrote {len(data)} records to {filename}.csv")

    def _generate_sql_scripts(self):
        """Generate SQL load scripts"""
        load_script = f"""-- Load generated Healthcare IoT data
-- Generated on {datetime.now()}
-- Note: All patient data is synthetic for educational purposes

-- Clear existing data
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE audit_logs;
TRUNCATE TABLE staff_assignments;
TRUNCATE TABLE clinical_scores;
TRUNCATE TABLE medications;
TRUNCATE TABLE alerts;
TRUNCATE TABLE device_readings;
TRUNCATE TABLE vital_signs;
TRUNCATE TABLE device_assignments;
TRUNCATE TABLE devices;
TRUNCATE TABLE patients;
TRUNCATE TABLE medical_staff;
TRUNCATE TABLE departments;
TRUNCATE TABLE hospitals;
SET FOREIGN_KEY_CHECKS = 1;

-- Load data files
LOAD DATA INFILE '/var/lib/mysql-files/healthcare/hospitals.csv'
INTO TABLE hospitals
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\\n'
IGNORE 1 ROWS;

-- Update statistics
ANALYZE TABLE hospitals, patients, vital_signs, alerts;

SELECT 'Data load complete!' as status;
"""

        script_path = self.output_dir / 'load_data.sql'
        with open(script_path, 'w') as f:
            f.write(load_script)

        print(f"  [OK] Generated SQL load script: load_data.sql")

def main():
    parser = argparse.ArgumentParser(description='Generate Healthcare IoT data')
    parser.add_argument('--config', required=True, help='Path to config.yaml')
    args = parser.parse_args()

    generator = HealthcareIoTGenerator(args.config)
    generator.generate_all()

if __name__ == '__main__':
    main()