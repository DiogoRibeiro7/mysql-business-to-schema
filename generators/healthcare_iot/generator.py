#!/usr/bin/env python3
"""
Healthcare IoT System Data Generator
Generates realistic data for hospital IoT medical device monitoring and patient care
"""

import csv
import json
import random
import hashlib
from datetime import datetime, timedelta, time, date
from decimal import Decimal
from pathlib import Path
from faker import Faker
import numpy as np
import math

from typing import Any, Dict, List

# Configuration
SEED = 42
OUTPUT_DIR = Path("output")
fake = Faker()
Faker.seed(SEED)
random.seed(SEED)
np.random.seed(SEED)

# Scale configuration
CONFIG = {
    "hospitals": 3,
    "departments_per_hospital": 8,
    "rooms_per_department": 10,
    "staff_per_department": 15,
    "patients": 500,
    "devices_per_department": 20,
    "days_of_history": 30,
    "vital_readings_per_day": 24,  # Hourly
    "device_readings_per_hour": 60,  # Every minute
}


class HealthcareIoTGenerator:
    def __init__(self):
        self.hospitals: List[Any] = []
        self.departments: List[Any] = []
        self.rooms: List[Any] = []
        self.staff: List[Any] = []
        self.staff_schedules: List[Any] = []
        self.patients: List[Any] = []
        self.admissions: List[Any] = []
        self.devices: List[Any] = []
        self.device_assignments: List[Any] = []
        self.vital_signs: List[Any] = []
        self.device_readings: List[Any] = []
        self.alerts: List[Any] = []
        self.alert_rules: List[Any] = []
        self.medications: List[Any] = []
        self.prescriptions: List[Any] = []
        self.medication_administrations: List[Any] = []

        # Counters
        self.department_id = 0
        self.room_id = 0
        self.staff_id = 0
        self.schedule_id = 0
        self.patient_id = 0
        self.admission_id = 0
        self.device_id = 0
        self.assignment_id = 0
        self.reading_id = 0
        self.device_reading_id = 0
        self.alert_id = 0
        self.rule_id = 0
        self.medication_id = 0
        self.prescription_id = 0
        self.admin_id = 0

        # Start date for historical data
        self.start_date = datetime.now() - timedelta(days=CONFIG["days_of_history"])

    def generate_all(self):
        """Generate all healthcare IoT data"""
        print("Starting Healthcare IoT System Data Generation...")
        print(f"Configuration:")
        print(f"  Hospitals: {CONFIG['hospitals']}")
        print(
            f"  Total departments: {CONFIG['hospitals'] * CONFIG['departments_per_hospital']}"
        )
        print(
            f"  Total rooms: {CONFIG['hospitals'] * CONFIG['departments_per_hospital'] * CONFIG['rooms_per_department']}"
        )
        print(f"  Patients: {CONFIG['patients']}")
        print(f"  Days of history: {CONFIG['days_of_history']}")

        # Core infrastructure
        self.generate_hospitals()
        self.generate_departments_and_rooms()
        self.generate_staff()

        # Patients and admissions
        self.generate_patients()
        self.generate_admissions()

        # Medical devices
        self.generate_devices()
        self.generate_device_assignments()

        # Alert rules
        self.generate_alert_rules()

        # Medications
        self.generate_medications()
        self.generate_prescriptions()

        # Vital signs and monitoring
        self.generate_vital_signs()
        self.generate_device_readings()

        # Alerts based on readings
        self.generate_alerts()

        # Staff schedules
        self.generate_staff_schedules()

        # Save all data
        self.save_all()

    def generate_hospitals(self):
        """Generate hospital facilities"""
        print(f"Generating {CONFIG['hospitals']} hospitals...")

        hospital_names = [
            "St. Mary's Medical Center",
            "City General Hospital",
            "University Medical Center",
            "Regional Heart Institute",
            "Children's Hospital",
        ]

        cities = [
            ("Boston", "MA", "02108"),
            ("New York", "NY", "10001"),
            ("Los Angeles", "CA", "90001"),
        ]

        for i in range(CONFIG["hospitals"]):
            city_info = cities[i % len(cities)]

            hospital = {
                "hospital_id": i + 1,
                "hospital_name": hospital_names[i % len(hospital_names)],
                "hospital_code": f"H{str(i+1).zfill(3)}",
                "address": fake.street_address(),
                "city": city_info[0],
                "state": city_info[1],
                "zip_code": city_info[2],
                "country": "USA",
                "phone": fake.phone_number()[:20],
                "email": f"admin@hospital{i+1}.org",
                "license_number": fake.bothify(text="LIC########"),
                "accreditation": random.choice(["JCAHO", "DNV", "HFAP"]),
                "bed_capacity": random.randint(200, 800),
                "emergency_services": True,
                "created_at": fake.date_time_between(start_date="-10y", end_date="-5y"),
                "updated_at": fake.date_time_between(start_date="-30d", end_date="now"),
            }
            self.hospitals.append(hospital)

    def generate_departments_and_rooms(self):
        """Generate hospital departments and rooms"""
        print("Generating departments and rooms...")

        department_types = [
            "ICU",
            "Emergency",
            "Surgery",
            "Pediatrics",
            "Cardiology",
            "Neurology",
            "Oncology",
            "Maternity",
            "General",
        ]

        for hospital in self.hospitals:
            for dept_num in range(CONFIG["departments_per_hospital"]):
                self.department_id += 1
                dept_type = department_types[dept_num % len(department_types)]

                department = {
                    "department_id": self.department_id,
                    "hospital_id": hospital["hospital_id"],
                    "department_name": f"{dept_type} Department",
                    "department_code": f"D{hospital['hospital_code']}{str(dept_num+1).zfill(2)}",
                    "department_type": dept_type,
                    "floor_number": (dept_num // 3) + 1,
                    "bed_count": CONFIG["rooms_per_department"] * 2,
                    "nurse_station_location": f"Floor {(dept_num // 3) + 1} - Central",
                    "phone_extension": str(2000 + dept_num),
                    "is_active": True,
                    "created_at": hospital["created_at"],
                }
                self.departments.append(department)

                # Generate rooms for this department
                for room_num in range(CONFIG["rooms_per_department"]):
                    self.room_id += 1

                    # Room type based on department
                    if dept_type == "ICU":
                        room_type = "ICU"
                        bed_count = 1
                    elif dept_type == "Emergency":
                        room_type = "Emergency"
                        bed_count = 1
                    elif dept_type == "Surgery":
                        room_type = "Operating"
                        bed_count = 1
                    else:
                        room_type = random.choice(["Private", "Semi-Private"])
                        bed_count = 1 if room_type == "Private" else 2

                    room = {
                        "room_id": self.room_id,
                        "department_id": self.department_id,
                        "room_number": f"{department['floor_number']}{str(room_num+1).zfill(2)}",
                        "room_type": room_type,
                        "bed_count": bed_count,
                        "floor": department["floor_number"],
                        "is_occupied": random.random() > 0.3,  # 70% occupancy
                        "is_isolation": random.random() > 0.9,  # 10% isolation rooms
                        "has_monitoring": dept_type
                        in ["ICU", "Emergency", "Cardiology"],
                        "equipment_list": json.dumps(
                            ["Bed", "Monitor", "IV Stand", "Oxygen"]
                        ),
                        "created_at": department["created_at"],
                    }
                    self.rooms.append(room)

    def generate_staff(self):
        """Generate medical staff"""
        print("Generating medical staff...")

        roles = ["Doctor", "Nurse", "Technician"]
        specializations = {
            "Doctor": [
                "Cardiologist",
                "Neurologist",
                "Surgeon",
                "Pediatrician",
                "Internist",
                "Emergency",
            ],
            "Nurse": ["RN", "LPN", "Critical Care", "Pediatric", "Emergency"],
            "Technician": [
                "Radiology",
                "Laboratory",
                "Respiratory",
                "EKG",
                "Phlebotomy",
            ],
        }
        shifts = ["Day", "Night", "Rotating"]

        for department in self.departments:
            for staff_num in range(CONFIG["staff_per_department"]):
                self.staff_id += 1
                role = random.choice(roles)

                staff_member = {
                    "staff_id": self.staff_id,
                    "hospital_id": department["hospital_id"],
                    "employee_id": f"EMP{str(self.staff_id).zfill(5)}",
                    "first_name": fake.first_name(),
                    "last_name": fake.last_name(),
                    "title": "Dr." if role == "Doctor" else None,
                    "role": role,
                    "specialization": random.choice(specializations[role]),
                    "license_number": (
                        fake.bothify(text="LIC########")
                        if role in ["Doctor", "Nurse"]
                        else None
                    ),
                    "license_expiry": (
                        fake.date_between(start_date="+1y", end_date="+5y")
                        if role in ["Doctor", "Nurse"]
                        else None
                    ),
                    "department_id": department["department_id"],
                    "email": fake.email(),
                    "phone": fake.phone_number()[:20],
                    "shift_type": random.choice(shifts),
                    "hire_date": fake.date_between(start_date="-10y", end_date="-6m"),
                    "is_active": random.random() > 0.05,  # 95% active
                    "created_at": department["created_at"],
                    "updated_at": fake.date_time_between(
                        start_date="-7d", end_date="now"
                    ),
                }
                self.staff.append(staff_member)

    def generate_patients(self):
        """Generate patient records"""
        print(f"Generating {CONFIG['patients']} patients...")

        blood_types = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]
        chronic_conditions = [
            "Diabetes",
            "Hypertension",
            "Asthma",
            "COPD",
            "Heart Disease",
            "Arthritis",
            "Cancer",
            "Kidney Disease",
            "None",
        ]
        allergies_list = ["Penicillin", "Aspirin", "Iodine", "Latex", "Peanuts", "None"]

        for i in range(CONFIG["patients"]):
            dob = fake.date_of_birth(minimum_age=1, maximum_age=90)
            height = random.uniform(150, 200)
            weight = random.uniform(45, 150)

            patient = {
                "patient_id": i + 1,
                "medical_record_number": f"MRN{str(i+1).zfill(7)}",
                "first_name": fake.first_name(),
                "last_name": fake.last_name(),
                "date_of_birth": dob,
                "gender": random.choice(["Male", "Female", "Other"]),
                "blood_type": random.choice(blood_types),
                "height_cm": round(height, 2),
                "weight_kg": round(weight, 2),
                "address": fake.street_address(),
                "city": fake.city(),
                "state": fake.state_abbr(),
                "zip_code": fake.postcode(),
                "phone": fake.phone_number()[:20],
                "email": fake.email(),
                "emergency_contact_name": fake.name(),
                "emergency_contact_phone": fake.phone_number()[:20],
                "emergency_contact_relation": random.choice(
                    ["Spouse", "Parent", "Child", "Sibling", "Friend"]
                ),
                "insurance_provider": random.choice(
                    ["BlueCross", "Aetna", "UnitedHealth", "Cigna", "Medicare"]
                ),
                "insurance_id": fake.bothify(text="INS#########"),
                "primary_physician_id": random.choice(
                    [s["staff_id"] for s in self.staff if s["role"] == "Doctor"]
                ),
                "allergies": json.dumps(
                    random.sample(allergies_list, k=random.randint(0, 2))
                ),
                "chronic_conditions": json.dumps(
                    random.sample(chronic_conditions, k=random.randint(0, 3))
                ),
                "created_at": fake.date_time_between(start_date="-5y", end_date="-1m"),
                "updated_at": fake.date_time_between(start_date="-30d", end_date="now"),
            }
            self.patients.append(patient)

    def generate_admissions(self):
        """Generate patient admissions"""
        print("Generating patient admissions...")

        admission_types = ["Emergency", "Scheduled", "Transfer", "Observation"]
        chief_complaints = [
            "Chest pain",
            "Shortness of breath",
            "Abdominal pain",
            "Fever",
            "Injury",
            "Surgery",
            "Cardiac event",
            "Stroke symptoms",
            "Fracture",
            "Infection",
            "Chronic condition management",
        ]

        # Generate admissions for ~60% of patients
        admitted_patients = random.sample(self.patients, int(len(self.patients) * 0.6))

        for patient in admitted_patients:
            # Some patients may have multiple admissions
            num_admissions = random.choices([1, 2, 3], weights=[70, 25, 5])[0]

            for _ in range(num_admissions):
                self.admission_id += 1

                admission_date = fake.date_time_between(
                    start_date=self.start_date, end_date="now"
                )
                stay_length = random.randint(1, 14)  # 1-14 days
                discharge_date = (
                    admission_date + timedelta(days=stay_length)
                    if random.random() > 0.2
                    else None
                )

                department = random.choice(self.departments)
                room = random.choice(
                    [
                        r
                        for r in self.rooms
                        if r["department_id"] == department["department_id"]
                    ]
                )

                admission = {
                    "admission_id": self.admission_id,
                    "patient_id": patient["patient_id"],
                    "hospital_id": department["hospital_id"],
                    "department_id": department["department_id"],
                    "room_id": room["room_id"],
                    "admission_date": admission_date,
                    "discharge_date": discharge_date,
                    "admission_type": random.choice(admission_types),
                    "admission_source": random.choice(
                        ["Emergency Room", "Physician Referral", "Transfer"]
                    ),
                    "chief_complaint": random.choice(chief_complaints),
                    "diagnosis_codes": json.dumps(
                        [
                            f"ICD-{random.randint(100, 999)}"
                            for _ in range(random.randint(1, 3))
                        ]
                    ),
                    "attending_physician_id": random.choice(
                        [
                            s["staff_id"]
                            for s in self.staff
                            if s["role"] == "Doctor"
                            and s["department_id"] == department["department_id"]
                        ]
                    ),
                    "admitting_physician_id": random.choice(
                        [s["staff_id"] for s in self.staff if s["role"] == "Doctor"]
                    ),
                    "status": (
                        "Discharged"
                        if discharge_date and discharge_date < datetime.now()
                        else "Active"
                    ),
                    "discharge_disposition": (
                        random.choice(["Home", "Rehab", "Transfer"])
                        if discharge_date
                        else None
                    ),
                    "total_charges": round(random.uniform(5000, 100000), 2),
                    "insurance_coverage": round(
                        random.uniform(0.7, 1.0) * random.uniform(5000, 100000), 2
                    ),
                    "notes": fake.sentence() if random.random() > 0.7 else None,
                    "created_at": admission_date,
                    "updated_at": discharge_date
                    or fake.date_time_between(
                        start_date=admission_date, end_date="now"
                    ),
                }
                self.admissions.append(admission)

    def generate_devices(self):
        """Generate medical IoT devices"""
        print("Generating medical devices...")

        device_types = [
            "Heart Monitor",
            "Blood Pressure",
            "Pulse Oximeter",
            "Glucose Monitor",
            "Temperature",
            "Ventilator",
            "Infusion Pump",
            "ECG",
        ]
        manufacturers = ["Philips", "GE Healthcare", "Medtronic", "Siemens", "Abbott"]

        for department in self.departments:
            # Number of devices varies by department type
            if department["department_type"] == "ICU":
                num_devices = CONFIG["devices_per_department"] * 2
            elif department["department_type"] in ["Emergency", "Cardiology"]:
                num_devices = int(CONFIG["devices_per_department"] * 1.5)
            else:
                num_devices = CONFIG["devices_per_department"]

            for device_num in range(num_devices):
                self.device_id += 1

                device_type = random.choice(device_types)

                device = {
                    "device_id": self.device_id,
                    "device_serial": f"SN{fake.bothify(text='########')}",
                    "device_type": device_type,
                    "manufacturer": random.choice(manufacturers),
                    "model": f"Model-{random.randint(1000, 9999)}",
                    "firmware_version": f"{random.randint(1, 5)}.{random.randint(0, 9)}.{random.randint(0, 99)}",
                    "hospital_id": department["hospital_id"],
                    "department_id": department["department_id"],
                    "room_id": random.choice(
                        [
                            r["room_id"]
                            for r in self.rooms
                            if r["department_id"] == department["department_id"]
                        ]
                    ),
                    "current_patient_id": None,  # Will be set by assignments
                    "installation_date": fake.date_between(
                        start_date="-3y", end_date="-6m"
                    ),
                    "last_maintenance_date": fake.date_between(
                        start_date="-3m", end_date="today"
                    ),
                    "next_maintenance_date": fake.date_between(
                        start_date="+1m", end_date="+6m"
                    ),
                    "calibration_date": fake.date_between(
                        start_date="-1m", end_date="today"
                    ),
                    "battery_level": (
                        random.randint(20, 100) if device_type != "Ventilator" else None
                    ),
                    "connectivity_status": random.choices(
                        ["Online", "Offline", "Intermittent"], weights=[85, 10, 5]
                    )[0],
                    "last_seen": fake.date_time_between(
                        start_date="-1h", end_date="now"
                    ),
                    "is_active": random.random() > 0.1,  # 90% active
                    "settings": json.dumps(
                        {
                            "alarm_enabled": True,
                            "threshold_high": 100,
                            "threshold_low": 60,
                        }
                    ),
                    "created_at": department["created_at"],
                    "updated_at": fake.date_time_between(
                        start_date="-7d", end_date="now"
                    ),
                }
                self.devices.append(device)

    def generate_device_assignments(self):
        """Assign devices to admitted patients"""
        print("Generating device assignments...")

        active_admissions = [a for a in self.admissions if a["status"] == "Active"]

        for admission in active_admissions:
            # Critical patients get more devices
            department = next(
                d
                for d in self.departments
                if d["department_id"] == admission["department_id"]
            )

            if department["department_type"] == "ICU":
                num_devices = random.randint(3, 5)
            elif department["department_type"] in ["Emergency", "Cardiology"]:
                num_devices = random.randint(2, 4)
            else:
                num_devices = random.randint(1, 2)

            # Get available devices in the department
            dept_devices = [
                d
                for d in self.devices
                if d["department_id"] == admission["department_id"]
                and d["is_active"]
                and d["current_patient_id"] is None
            ]

            if dept_devices:
                assigned_devices = random.sample(
                    dept_devices, min(num_devices, len(dept_devices))
                )

                for device in assigned_devices:
                    self.assignment_id += 1

                    assignment = {
                        "assignment_id": self.assignment_id,
                        "device_id": device["device_id"],
                        "patient_id": admission["patient_id"],
                        "admission_id": admission["admission_id"],
                        "assigned_at": admission["admission_date"],
                        "unassigned_at": admission["discharge_date"],
                        "assigned_by": admission["admitting_physician_id"],
                        "unassigned_by": (
                            admission["attending_physician_id"]
                            if admission["discharge_date"]
                            else None
                        ),
                        "reason": "Patient monitoring",
                        "is_active": admission["status"] == "Active",
                        "created_at": admission["admission_date"],
                    }
                    self.device_assignments.append(assignment)

                    # Update device's current patient
                    device["current_patient_id"] = (
                        admission["patient_id"]
                        if admission["status"] == "Active"
                        else None
                    )

    def generate_alert_rules(self):
        """Generate alert rule configurations"""
        print("Generating alert rules...")

        rules = [
            # Vital sign rules
            {
                "name": "High Heart Rate",
                "metric": "heart_rate",
                "operator": ">",
                "value1": 120,
                "severity": "Warning",
            },
            {
                "name": "Critical Heart Rate",
                "metric": "heart_rate",
                "operator": ">",
                "value1": 150,
                "severity": "Critical",
            },
            {
                "name": "Low Heart Rate",
                "metric": "heart_rate",
                "operator": "<",
                "value1": 50,
                "severity": "Warning",
            },
            {
                "name": "High Blood Pressure",
                "metric": "systolic_bp",
                "operator": ">",
                "value1": 160,
                "severity": "Warning",
            },
            {
                "name": "Critical Blood Pressure",
                "metric": "systolic_bp",
                "operator": ">",
                "value1": 180,
                "severity": "Critical",
            },
            {
                "name": "Low Blood Pressure",
                "metric": "systolic_bp",
                "operator": "<",
                "value1": 90,
                "severity": "Warning",
            },
            {
                "name": "Low Oxygen",
                "metric": "oxygen_saturation",
                "operator": "<",
                "value1": 92,
                "severity": "Warning",
            },
            {
                "name": "Critical Low Oxygen",
                "metric": "oxygen_saturation",
                "operator": "<",
                "value1": 88,
                "severity": "Critical",
            },
            {
                "name": "High Temperature",
                "metric": "temperature",
                "operator": ">",
                "value1": 38.5,
                "severity": "Warning",
            },
            {
                "name": "Critical Temperature",
                "metric": "temperature",
                "operator": ">",
                "value1": 40,
                "severity": "Critical",
            },
        ]

        for rule_config in rules:
            self.rule_id += 1

            rule = {
                "rule_id": self.rule_id,
                "rule_name": rule_config["name"],
                "rule_type": "Threshold",
                "metric_type": rule_config["metric"],
                "condition_operator": rule_config["operator"],
                "threshold_value1": rule_config["value1"],
                "threshold_value2": rule_config.get("value2"),
                "time_window_minutes": 5,
                "severity": rule_config["severity"],
                "department_id": None,  # Global rules
                "is_active": True,
                "notification_channels": json.dumps(["dashboard", "pager", "email"]),
                "created_at": fake.date_time_between(start_date="-1y", end_date="-6m"),
                "updated_at": fake.date_time_between(start_date="-30d", end_date="now"),
            }
            self.alert_rules.append(rule)

    def generate_medications(self):
        """Generate medication database"""
        print("Generating medications...")

        medications_list = [
            {
                "name": "Aspirin",
                "generic": "Acetylsalicylic acid",
                "class": "Analgesic",
                "form": "Tablet",
                "strength": "81mg",
            },
            {
                "name": "Lisinopril",
                "generic": "Lisinopril",
                "class": "ACE Inhibitor",
                "form": "Tablet",
                "strength": "10mg",
            },
            {
                "name": "Metformin",
                "generic": "Metformin HCl",
                "class": "Antidiabetic",
                "form": "Tablet",
                "strength": "500mg",
            },
            {
                "name": "Omeprazole",
                "generic": "Omeprazole",
                "class": "Proton Pump Inhibitor",
                "form": "Capsule",
                "strength": "20mg",
            },
            {
                "name": "Atorvastatin",
                "generic": "Atorvastatin",
                "class": "Statin",
                "form": "Tablet",
                "strength": "40mg",
            },
            {
                "name": "Amoxicillin",
                "generic": "Amoxicillin",
                "class": "Antibiotic",
                "form": "Capsule",
                "strength": "500mg",
            },
            {
                "name": "Morphine",
                "generic": "Morphine Sulfate",
                "class": "Opioid",
                "form": "Injection",
                "strength": "10mg/mL",
            },
            {
                "name": "Insulin",
                "generic": "Insulin Regular",
                "class": "Hormone",
                "form": "Injection",
                "strength": "100units/mL",
            },
            {
                "name": "Warfarin",
                "generic": "Warfarin Sodium",
                "class": "Anticoagulant",
                "form": "Tablet",
                "strength": "5mg",
            },
            {
                "name": "Furosemide",
                "generic": "Furosemide",
                "class": "Diuretic",
                "form": "Tablet",
                "strength": "40mg",
            },
        ]

        for med in medications_list:
            self.medication_id += 1

            medication = {
                "medication_id": self.medication_id,
                "medication_name": med["name"],
                "generic_name": med["generic"],
                "drug_class": med["class"],
                "ndc_code": fake.bothify(text="#####-####-##"),
                "dosage_form": med["form"],
                "strength": med["strength"],
                "unit": "mg" if "mg" in med["strength"] else "units",
                "manufacturer": random.choice(
                    ["Pfizer", "Novartis", "Roche", "Merck", "GSK"]
                ),
                "controlled_substance_schedule": (
                    "II" if med["name"] == "Morphine" else None
                ),
                "requires_refrigeration": med["name"] == "Insulin",
                "black_box_warning": None,
                "created_at": fake.date_time_between(start_date="-5y", end_date="-4y"),
            }
            self.medications.append(medication)

    def generate_prescriptions(self):
        """Generate patient prescriptions"""
        print("Generating prescriptions...")

        routes = ["Oral", "IV", "IM", "Subcutaneous"]
        frequencies = [
            "Once daily",
            "Twice daily",
            "Three times daily",
            "Four times daily",
            "As needed",
        ]

        for admission in self.admissions:
            # Generate 1-5 prescriptions per admission
            num_prescriptions = random.randint(1, 5)

            for _ in range(num_prescriptions):
                self.prescription_id += 1

                medication = random.choice(self.medications)

                prescription = {
                    "prescription_id": self.prescription_id,
                    "patient_id": admission["patient_id"],
                    "admission_id": admission["admission_id"],
                    "medication_id": medication["medication_id"],
                    "prescribing_physician_id": admission["attending_physician_id"],
                    "dosage": medication["strength"],
                    "frequency": random.choice(frequencies),
                    "route": random.choice(routes),
                    "start_date": admission["admission_date"],
                    "end_date": (
                        admission["discharge_date"]
                        if admission["discharge_date"]
                        else None
                    ),
                    "duration_days": (
                        (admission["discharge_date"] - admission["admission_date"]).days
                        if admission["discharge_date"]
                        else None
                    ),
                    "refills": random.randint(0, 3),
                    "instructions": fake.sentence(),
                    "is_prn": random.random() > 0.7,  # 30% PRN
                    "prn_reason": "Pain" if random.random() > 0.5 else "Nausea",
                    "is_active": admission["status"] == "Active",
                    "discontinued_date": None,
                    "discontinued_by": None,
                    "discontinued_reason": None,
                    "created_at": admission["admission_date"],
                    "updated_at": admission["admission_date"],
                }
                self.prescriptions.append(prescription)

    def generate_vital_signs(self):
        """Generate vital signs readings"""
        print("Generating vital signs (this may take a while)...")

        # Sample period
        sample_days = min(7, CONFIG["days_of_history"])
        start_date = datetime.now() - timedelta(days=sample_days)

        # Generate for active admissions
        active_admissions = [
            a
            for a in self.admissions
            if a["admission_date"] <= datetime.now()
            and (a["discharge_date"] is None or a["discharge_date"] > start_date)
        ]

        for admission in random.sample(
            active_admissions, min(len(active_admissions), 50)
        ):
            patient = next(
                p for p in self.patients if p["patient_id"] == admission["patient_id"]
            )
            age = (datetime.now().date() - patient["date_of_birth"]).days // 365

            # Get assigned devices
            assigned_devices = [
                a
                for a in self.device_assignments
                if a["admission_id"] == admission["admission_id"]
            ]

            current_date = max(admission["admission_date"], start_date)
            end_date = (
                admission["discharge_date"]
                if admission["discharge_date"]
                else datetime.now()
            )

            while current_date < end_date:
                # Generate readings every hour
                for hour in range(24):
                    reading_time = current_date.replace(
                        hour=hour, minute=0, second=0, microsecond=0
                    )

                    if reading_time > end_date:
                        break

                    self.reading_id += 1

                    # Generate realistic vital signs based on age and condition
                    vital = {
                        "reading_id": self.reading_id,
                        "patient_id": admission["patient_id"],
                        "admission_id": admission["admission_id"],
                        "device_id": (
                            assigned_devices[0]["device_id"]
                            if assigned_devices
                            else None
                        ),
                        "recorded_at": reading_time,
                        "heart_rate": self.generate_heart_rate(age),
                        "respiratory_rate": random.randint(12, 20),
                        "systolic_bp": random.randint(100, 140),
                        "diastolic_bp": random.randint(60, 90),
                        "oxygen_saturation": round(random.uniform(94, 100), 2),
                        "temperature": round(random.uniform(36.0, 37.5), 1),
                        "blood_glucose": (
                            round(random.uniform(70, 140), 2)
                            if random.random() > 0.5
                            else None
                        ),
                        "pain_level": (
                            random.randint(0, 5) if random.random() > 0.3 else None
                        ),
                        "consciousness_level": "Alert",
                        "recorded_by": random.choice(
                            [
                                s["staff_id"]
                                for s in self.staff
                                if s["role"] == "Nurse"
                                and s["department_id"] == admission["department_id"]
                            ]
                        ),
                        "is_manual_entry": random.random() > 0.3,  # 70% manual
                        "notes": None,
                        "created_at": reading_time,
                    }
                    self.vital_signs.append(vital)

                    # Check for alert conditions
                    self.check_vital_alerts(vital, admission)

                current_date += timedelta(days=1)

    def generate_heart_rate(self, age):
        """Generate realistic heart rate based on age"""
        if age < 1:
            return random.randint(100, 160)
        elif age < 10:
            return random.randint(70, 120)
        elif age < 18:
            return random.randint(60, 100)
        else:
            return random.randint(60, 90)

    def check_vital_alerts(self, vital, admission):
        """Check vital signs against alert rules and generate alerts"""
        for rule in self.alert_rules:
            triggered = False
            value = None

            if rule["metric_type"] == "heart_rate" and vital["heart_rate"]:
                value = vital["heart_rate"]
                if (
                    rule["condition_operator"] == ">"
                    and value > rule["threshold_value1"]
                ):
                    triggered = True
                elif (
                    rule["condition_operator"] == "<"
                    and value < rule["threshold_value1"]
                ):
                    triggered = True

            elif rule["metric_type"] == "systolic_bp" and vital["systolic_bp"]:
                value = vital["systolic_bp"]
                if (
                    rule["condition_operator"] == ">"
                    and value > rule["threshold_value1"]
                ):
                    triggered = True
                elif (
                    rule["condition_operator"] == "<"
                    and value < rule["threshold_value1"]
                ):
                    triggered = True

            elif (
                rule["metric_type"] == "oxygen_saturation"
                and vital["oxygen_saturation"]
            ):
                value = vital["oxygen_saturation"]
                if (
                    rule["condition_operator"] == "<"
                    and value < rule["threshold_value1"]
                ):
                    triggered = True

            elif rule["metric_type"] == "temperature" and vital["temperature"]:
                value = vital["temperature"]
                if (
                    rule["condition_operator"] == ">"
                    and value > rule["threshold_value1"]
                ):
                    triggered = True

            if triggered and random.random() > 0.7:  # Don't generate too many alerts
                self.alert_id += 1

                alert = {
                    "alert_id": self.alert_id,
                    "patient_id": vital["patient_id"],
                    "admission_id": vital["admission_id"],
                    "device_id": vital["device_id"],
                    "alert_type": rule["severity"],
                    "alert_category": "Vital Signs",
                    "alert_code": f"VS_{rule['metric_type'].upper()}",
                    "alert_message": f"{rule['rule_name']}: {rule['metric_type']} is {value}",
                    "metric_name": rule["metric_type"],
                    "metric_value": value,
                    "threshold_value": rule["threshold_value1"],
                    "triggered_at": vital["recorded_at"],
                    "acknowledged_at": (
                        vital["recorded_at"] + timedelta(minutes=random.randint(1, 30))
                        if random.random() > 0.3
                        else None
                    ),
                    "acknowledged_by": (
                        random.choice(
                            [
                                s["staff_id"]
                                for s in self.staff
                                if s["role"] == "Nurse"
                                and s["department_id"] == admission["department_id"]
                            ]
                        )
                        if random.random() > 0.3
                        else None
                    ),
                    "resolved_at": (
                        vital["recorded_at"]
                        + timedelta(minutes=random.randint(30, 120))
                        if random.random() > 0.4
                        else None
                    ),
                    "resolved_by": (
                        random.choice(
                            [s["staff_id"] for s in self.staff if s["role"] == "Doctor"]
                        )
                        if random.random() > 0.4
                        else None
                    ),
                    "escalated": rule["severity"] == "Critical",
                    "response_time_seconds": (
                        random.randint(30, 600) if random.random() > 0.3 else None
                    ),
                    "actions_taken": fake.sentence() if random.random() > 0.5 else None,
                    "created_at": vital["recorded_at"],
                }
                self.alerts.append(alert)

    def generate_device_readings(self):
        """Generate continuous device readings"""
        print("Generating device readings...")

        # Sample a smaller period for performance
        sample_hours = 24  # Last 24 hours
        start_time = datetime.now() - timedelta(hours=sample_hours)

        # Get active device assignments
        active_assignments = [a for a in self.device_assignments if a["is_active"]]

        for assignment in random.sample(
            active_assignments, min(len(active_assignments), 20)
        ):
            device = next(
                d for d in self.devices if d["device_id"] == assignment["device_id"]
            )

            current_time = start_time
            while current_time < datetime.now():
                # Generate reading based on device type
                if device["device_type"] == "Heart Monitor":
                    metric_type = "heart_rate"
                    metric_value = random.uniform(60, 100)
                    metric_unit = "bpm"
                elif device["device_type"] == "Blood Pressure":
                    metric_type = "blood_pressure"
                    metric_value = random.uniform(110, 130)  # Systolic
                    metric_unit = "mmHg"
                elif device["device_type"] == "Pulse Oximeter":
                    metric_type = "spo2"
                    metric_value = random.uniform(94, 100)
                    metric_unit = "%"
                elif device["device_type"] == "Temperature":
                    metric_type = "temperature"
                    metric_value = random.uniform(36.0, 37.5)
                    metric_unit = "°C"
                else:
                    metric_type = "generic"
                    metric_value = random.uniform(0, 100)
                    metric_unit = "units"

                self.device_reading_id += 1

                reading = {
                    "reading_id": self.device_reading_id,
                    "device_id": device["device_id"],
                    "patient_id": assignment["patient_id"],
                    "timestamp": current_time,
                    "metric_type": metric_type,
                    "metric_value": round(metric_value, 3),
                    "metric_unit": metric_unit,
                    "quality_score": random.randint(90, 100),
                    "raw_data": json.dumps({"raw": metric_value, "processed": True}),
                    "created_at": current_time,
                }
                self.device_readings.append(reading)

                current_time += timedelta(minutes=1)

    def generate_alerts(self):
        """Generate additional system alerts"""
        # Alerts are already generated in check_vital_alerts
        # This could generate other types of alerts (device, medication, etc.)
        pass

    def generate_staff_schedules(self):
        """Generate staff schedules"""
        print("Generating staff schedules...")

        for staff_member in random.sample(self.staff, min(len(self.staff), 100)):
            current_date = self.start_date.date()

            while current_date <= datetime.now().date():
                # Skip some days for days off
                if random.random() > 0.8:  # 20% days off
                    current_date += timedelta(days=1)
                    continue

                self.schedule_id += 1

                # Determine shift times based on shift type
                if staff_member["shift_type"] == "Day":
                    shift_start = time(7, 0)
                    shift_end = time(19, 0)
                elif staff_member["shift_type"] == "Night":
                    shift_start = time(19, 0)
                    shift_end = time(7, 0)
                else:  # Rotating
                    if random.random() > 0.5:
                        shift_start = time(7, 0)
                        shift_end = time(19, 0)
                    else:
                        shift_start = time(19, 0)
                        shift_end = time(7, 0)

                schedule = {
                    "schedule_id": self.schedule_id,
                    "staff_id": staff_member["staff_id"],
                    "department_id": staff_member["department_id"],
                    "shift_date": current_date,
                    "shift_start": shift_start,
                    "shift_end": shift_end,
                    "break_minutes": 30,
                    "is_on_call": random.random() > 0.9,  # 10% on call
                    "actual_start": datetime.combine(current_date, shift_start)
                    + timedelta(minutes=random.randint(-15, 15)),
                    "actual_end": datetime.combine(current_date, shift_end)
                    + timedelta(minutes=random.randint(-15, 30)),
                    "created_at": datetime.combine(current_date, time(0, 0))
                    - timedelta(days=7),
                }
                self.staff_schedules.append(schedule)

                current_date += timedelta(days=1)

    def save_to_csv(self, table_name, data):
        """Save data to CSV file"""
        if not data:
            return

        output_file = OUTPUT_DIR / f"{table_name}.csv"

        with open(output_file, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=data[0].keys())
            writer.writeheader()
            writer.writerows(data)

    def save_all(self):
        """Save all generated data to CSV files"""
        print("\nSaving data to CSV files...")

        OUTPUT_DIR.mkdir(exist_ok=True)

        # Save all tables
        tables = [
            ("hospitals", self.hospitals),
            ("departments", self.departments),
            ("rooms", self.rooms),
            ("staff", self.staff),
            ("staff_schedules", self.staff_schedules),
            ("patients", self.patients),
            ("admissions", self.admissions),
            ("devices", self.devices),
            ("device_assignments", self.device_assignments),
            ("vital_signs", self.vital_signs),
            ("device_readings", self.device_readings),
            ("alerts", self.alerts),
            ("alert_rules", self.alert_rules),
            ("medications", self.medications),
            ("prescriptions", self.prescriptions),
        ]

        for table_name, data in tables:
            if data:
                self.save_to_csv(table_name, data)
                print(f"  [OK] {table_name}: {len(data):,} records")

        # Generate summary statistics
        self.generate_summary()

    def generate_summary(self):
        """Generate summary statistics"""
        total_alerts = len(self.alerts)
        critical_alerts = len([a for a in self.alerts if a["alert_type"] == "Critical"])

        summary = f"""
Healthcare IoT System Data Generation Summary
=============================================
Infrastructure:
  Hospitals: {len(self.hospitals)}
  Departments: {len(self.departments)}
  Rooms: {len(self.rooms)}
  Medical Staff: {len(self.staff)}

Patients & Care:
  Patients: {len(self.patients)}
  Active Admissions: {len([a for a in self.admissions if a['status'] == 'Active'])}
  Total Admissions: {len(self.admissions)}

Medical Devices:
  Total Devices: {len(self.devices)}
  Active Devices: {len([d for d in self.devices if d['is_active']])}
  Device Assignments: {len(self.device_assignments)}

Monitoring Data:
  Vital Signs Readings: {len(self.vital_signs):,}
  Device Readings: {len(self.device_readings):,}

Alerts & Safety:
  Alert Rules: {len(self.alert_rules)}
  Total Alerts: {total_alerts}
  Critical Alerts: {critical_alerts}
  Alert Rate: {(critical_alerts/total_alerts*100 if total_alerts > 0 else 0):.1f}% critical

Medications:
  Medications: {len(self.medications)}
  Active Prescriptions: {len([p for p in self.prescriptions if p['is_active']])}

Staff Management:
  Schedule Records: {len(self.staff_schedules):,}

Files Generated: {len(list(OUTPUT_DIR.glob('*.csv')))}
"""

        print(summary)

        # Save summary to file
        with open(OUTPUT_DIR / "generation_summary.txt", "w") as f:
            f.write(summary)


if __name__ == "__main__":
    generator = HealthcareIoTGenerator()
    generator.generate_all()
    print("\n[SUCCESS] Healthcare IoT System data generation complete!")
