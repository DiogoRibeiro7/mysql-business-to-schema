#!/usr/bin/env python3
"""Medical Clinic Data Generator.

Generates realistic sample data for the medical clinic database schema
"""

import random
import json
import yaml
import argparse
from datetime import datetime, timedelta, date
from typing import List, Dict, Any

# Add faker to pyproject.toml
from faker import Faker
from faker.providers import person, address, phone_number, company, date_time, python


class ClinicDataGenerator:
    """Represent ClinicDataGenerator."""

    def __init__(self, config_path: str = "config.yaml"):
        """Initialize the generator with configuration."""
        self.fake = Faker()
        self.fake.add_provider(person)
        self.fake.add_provider(address)
        self.fake.add_provider(phone_number)
        self.fake.add_provider(company)
        self.fake.add_provider(date_time)
        self.fake.add_provider(python)

        # Load configuration
        with open(config_path, "r") as f:
            self.config = yaml.safe_load(f)

        # Data storage
        self.clinics: List[Any] = []
        self.departments: List[Any] = []
        self.doctors: List[Any] = []
        self.nurses: List[Any] = []
        self.staff: List[Any] = []
        self.patients: List[Any] = []
        self.appointments: List[Any] = []
        self.medical_records: List[Any] = []
        self.prescriptions: List[Any] = []
        self.lab_tests: List[Any] = []
        self.lab_results: List[Any] = []
        self.billing_items: List[Any] = []
        self.invoices: List[Any] = []
        self.payments: List[Any] = []
        self.insurance_claims: List[Any] = []
        self.inventory_items: List[Any] = []
        self.inventory_transactions: List[Any] = []
        self.equipment: List[Any] = []
        self.maintenance_logs: List[Any] = []

        # Counters for IDs
        self.counters = {
            "clinic": 1,
            "department": 1,
            "doctor": 1,
            "nurse": 1,
            "staff": 1,
            "patient": 1,
            "appointment": 1,
            "medical_record": 1,
            "prescription": 1,
            "lab_test": 1,
            "lab_result": 1,
            "billing_item": 1,
            "invoice": 1,
            "payment": 1,
            "insurance_claim": 1,
            "inventory_item": 1,
            "inventory_transaction": 1,
            "equipment": 1,
            "maintenance_log": 1,
        }

        # Medical data
        self.specializations = [
            "General Practice",
            "Cardiology",
            "Dermatology",
            "Endocrinology",
            "Gastroenterology",
            "Neurology",
            "Oncology",
            "Pediatrics",
            "Psychiatry",
            "Radiology",
            "Surgery",
            "Urology",
            "Orthopedics",
            "Ophthalmology",
            "ENT",
            "Gynecology",
            "Anesthesiology",
        ]

        self.department_types = [
            "Emergency",
            "Outpatient",
            "Inpatient",
            "Surgery",
            "ICU",
            "Radiology",
            "Laboratory",
            "Pharmacy",
            "Administration",
        ]

        self.appointment_types = [
            "Consultation",
            "Follow-up",
            "Emergency",
            "Surgery",
            "Lab Test",
            "Imaging",
            "Vaccination",
            "Check-up",
        ]

        self.appointment_statuses = [
            "scheduled",
            "confirmed",
            "in-progress",
            "completed",
            "cancelled",
            "no-show",
        ]

        self.test_types = [
            "Blood Count",
            "Blood Sugar",
            "Lipid Panel",
            "Liver Function",
            "Kidney Function",
            "Thyroid",
            "Urinalysis",
            "X-Ray",
            "CT Scan",
            "MRI",
            "Ultrasound",
            "ECG",
            "Echocardiogram",
        ]

        self.medications = [
            "Paracetamol",
            "Ibuprofen",
            "Amoxicillin",
            "Metformin",
            "Lisinopril",
            "Atorvastatin",
            "Omeprazole",
            "Aspirin",
            "Levothyroxine",
            "Amlodipine",
            "Metoprolol",
            "Losartan",
            "Albuterol",
            "Gabapentin",
            "Hydrochlorothiazide",
        ]

        self.diagnoses = [
            "Hypertension",
            "Type 2 Diabetes",
            "Hyperlipidemia",
            "Asthma",
            "COPD",
            "Arthritis",
            "Depression",
            "Anxiety",
            "Migraine",
            "GERD",
            "Hypothyroidism",
            "Anemia",
            "UTI",
            "Pneumonia",
            "Bronchitis",
            "Sinusitis",
            "Allergic Rhinitis",
            "Back Pain",
        ]

        self.equipment_types = [
            "X-Ray Machine",
            "MRI Scanner",
            "CT Scanner",
            "Ultrasound Machine",
            "ECG Machine",
            "Ventilator",
            "Defibrillator",
            "Patient Monitor",
            "Infusion Pump",
            "Surgical Instruments",
            "Autoclave",
            "Wheelchair",
        ]

    def generate_clinics(self, count: int) -> List[Dict]:
        """Generate clinic data."""
        for _ in range(count):
            clinic_id = self.counters["clinic"]
            self.counters["clinic"] += 1

            clinic = {
                "clinic_id": clinic_id,
                "clinic_name": f"{self.fake.company()} Medical Center",
                "address": self.fake.street_address(),
                "city": self.fake.city(),
                "state": self.fake.state_abbr(),
                "zip_code": self.fake.zipcode(),
                "phone": self.fake.phone_number(),
                "email": self.fake.company_email(),
                "website": f"www.{self.fake.domain_name()}",
                "established_date": self.fake.date_between(
                    start_date="-20y", end_date="-1y"
                ),
                "license_number": f"LIC{random.randint(100000, 999999)}",
                "tax_id": f"{random.randint(10, 99)}-{random.randint(1000000, 9999999)}",
                "is_emergency_available": random.choice([True, False]),
                "created_at": datetime.now(),
                "updated_at": datetime.now(),
            }
            self.clinics.append(clinic)

        return self.clinics

    def generate_departments(self, departments_per_clinic: int) -> List[Dict]:
        """Generate department data for each clinic."""
        for clinic in self.clinics:
            for dept_type in random.sample(
                self.department_types,
                min(departments_per_clinic, len(self.department_types)),
            ):
                dept_id = self.counters["department"]
                self.counters["department"] += 1

                department = {
                    "department_id": dept_id,
                    "clinic_id": clinic["clinic_id"],
                    "department_name": f"{dept_type} Department",
                    "department_head": None,  # Will be assigned after doctors are created
                    "phone_extension": f"{random.randint(100, 999)}",
                    "floor": random.randint(1, 5),
                    "operating_hours": (
                        "08:00-18:00" if dept_type != "Emergency" else "24/7"
                    ),
                    "is_active": True,
                    "created_at": datetime.now(),
                }
                self.departments.append(department)

        return self.departments

    def generate_doctors(self, count: int) -> List[Dict]:
        """Generate doctor data."""
        for _ in range(count):
            doctor_id = self.counters["doctor"]
            self.counters["doctor"] += 1

            dept = random.choice(self.departments)
            hire_date = self.fake.date_between(start_date="-10y", end_date="-1m")

            doctor = {
                "doctor_id": doctor_id,
                "employee_id": f"DOC{str(doctor_id).zfill(5)}",
                "first_name": self.fake.first_name(),
                "last_name": self.fake.last_name(),
                "specialization": random.choice(self.specializations),
                "license_number": f"MD{random.randint(100000, 999999)}",
                "phone": self.fake.phone_number(),
                "email": self.fake.email(),
                "department_id": dept["department_id"],
                "hire_date": hire_date,
                "consultation_fee": random.randint(100, 500) * 10,  # $1000-$5000
                "is_available": True,
                "years_of_experience": random.randint(1, 30),
                "education": f"{self.fake.company()} Medical School",
                "certifications": json.dumps(
                    [f"Board Certified - {random.choice(self.specializations)}"]
                ),
                "created_at": datetime.now(),
            }
            self.doctors.append(doctor)

            # Assign department head
            if dept["department_head"] is None and random.random() > 0.5:
                dept["department_head"] = doctor_id

        return self.doctors

    def generate_nurses(self, count: int) -> List[Dict]:
        """Generate nurse data."""
        for _ in range(count):
            nurse_id = self.counters["nurse"]
            self.counters["nurse"] += 1

            dept = random.choice(self.departments)

            nurse = {
                "nurse_id": nurse_id,
                "employee_id": f"NUR{str(nurse_id).zfill(5)}",
                "first_name": self.fake.first_name(),
                "last_name": self.fake.last_name(),
                "license_number": f"RN{random.randint(100000, 999999)}",
                "phone": self.fake.phone_number(),
                "email": self.fake.email(),
                "department_id": dept["department_id"],
                "shift": random.choice(["Morning", "Evening", "Night"]),
                "hire_date": self.fake.date_between(start_date="-10y", end_date="-1m"),
                "is_active": True,
                "created_at": datetime.now(),
            }
            self.nurses.append(nurse)

        return self.nurses

    def generate_patients(self, count: int) -> List[Dict]:
        """Generate patient data."""
        for _ in range(count):
            patient_id = self.counters["patient"]
            self.counters["patient"] += 1

            birth_date = self.fake.date_of_birth(minimum_age=0, maximum_age=90)

            patient = {
                "patient_id": patient_id,
                "medical_record_number": f"MRN{str(patient_id).zfill(8)}",
                "first_name": self.fake.first_name(),
                "last_name": self.fake.last_name(),
                "date_of_birth": birth_date,
                "gender": random.choice(["M", "F", "Other"]),
                "blood_type": random.choice(
                    ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]
                ),
                "phone": self.fake.phone_number(),
                "email": self.fake.email(),
                "address": self.fake.street_address(),
                "city": self.fake.city(),
                "state": self.fake.state_abbr(),
                "zip_code": self.fake.zipcode(),
                "emergency_contact_name": self.fake.name(),
                "emergency_contact_phone": self.fake.phone_number(),
                "insurance_provider": random.choice(
                    ["Blue Cross", "Aetna", "Cigna", "United", "Medicare", None]
                ),
                "insurance_policy_number": (
                    f"POL{random.randint(100000000, 999999999)}"
                    if random.random() > 0.2
                    else None
                ),
                "allergies": json.dumps(
                    random.sample(
                        ["Penicillin", "Aspirin", "Peanuts", "Latex", "None"],
                        random.randint(0, 2),
                    )
                ),
                "chronic_conditions": json.dumps(
                    random.sample(self.diagnoses, random.randint(0, 3))
                ),
                "created_at": self.fake.date_between(
                    start_date="-5y", end_date="today"
                ),
                "updated_at": datetime.now(),
            }
            self.patients.append(patient)

        return self.patients

    def generate_appointments(self, count: int) -> List[Dict]:
        """Generate appointment data."""
        start_date = datetime.now() - timedelta(days=365)
        end_date = datetime.now() + timedelta(days=30)

        for _ in range(count):
            appointment_id = self.counters["appointment"]
            self.counters["appointment"] += 1

            patient = random.choice(self.patients)
            doctor = random.choice(self.doctors)
            appointment_date = self.fake.date_time_between(
                start_date=start_date, end_date=end_date
            )
            status = random.choices(
                self.appointment_statuses,
                weights=[20, 10, 5, 40, 15, 10],  # Weighted towards completed
            )[0]

            appointment = {
                "appointment_id": appointment_id,
                "patient_id": patient["patient_id"],
                "doctor_id": doctor["doctor_id"],
                "appointment_date": appointment_date.date(),
                "appointment_time": appointment_date.time(),
                "appointment_type": random.choice(self.appointment_types),
                "status": status,
                "reason_for_visit": self.fake.sentence(nb_words=10),
                "notes": (
                    self.fake.text(max_nb_chars=200) if status == "completed" else None
                ),
                "created_at": appointment_date - timedelta(days=random.randint(1, 30)),
                "updated_at": (
                    appointment_date if status == "completed" else datetime.now()
                ),
            }
            self.appointments.append(appointment)

        return self.appointments

    def generate_medical_records(self) -> List[Dict]:
        """Generate medical records for completed appointments."""
        completed_appointments = [
            a for a in self.appointments if a["status"] == "completed"
        ]

        for appointment in completed_appointments:
            record_id = self.counters["medical_record"]
            self.counters["medical_record"] += 1

            patient = next(
                p for p in self.patients if p["patient_id"] == appointment["patient_id"]
            )
            age = (
                appointment["appointment_date"] - patient["date_of_birth"]
            ).days // 365

            # Generate vital signs based on age and conditions
            if age < 18:
                bp_systolic = random.randint(90, 120)
                bp_diastolic = random.randint(60, 80)
                heart_rate = random.randint(70, 100)
            elif age < 60:
                bp_systolic = random.randint(110, 140)
                bp_diastolic = random.randint(70, 90)
                heart_rate = random.randint(60, 90)
            else:
                bp_systolic = random.randint(120, 150)
                bp_diastolic = random.randint(70, 95)
                heart_rate = random.randint(60, 85)

            medical_record = {
                "record_id": record_id,
                "patient_id": appointment["patient_id"],
                "doctor_id": appointment["doctor_id"],
                "appointment_id": appointment["appointment_id"],
                "visit_date": appointment["appointment_date"],
                "chief_complaint": appointment["reason_for_visit"],
                "symptoms": self.fake.text(max_nb_chars=200),
                "diagnosis": random.choice(self.diagnoses),
                "treatment_plan": self.fake.text(max_nb_chars=300),
                "vital_signs": json.dumps(
                    {
                        "blood_pressure": f"{bp_systolic}/{bp_diastolic}",
                        "heart_rate": heart_rate,
                        "temperature": round(random.uniform(97.0, 99.5), 1),
                        "weight": round(random.uniform(50, 100), 1),
                        "height": random.randint(150, 190),
                    }
                ),
                "follow_up_required": random.choice([True, False]),
                "follow_up_date": (
                    (
                        appointment["appointment_date"]
                        + timedelta(days=random.randint(7, 30))
                    )
                    if random.random() > 0.5
                    else None
                ),
                "created_at": appointment["appointment_date"],
                "updated_at": appointment["appointment_date"],
            }
            self.medical_records.append(medical_record)

        return self.medical_records

    def generate_prescriptions(self) -> List[Dict]:
        """Generate prescriptions for medical records."""
        for record in self.medical_records:
            if random.random() > 0.3:  # 70% of visits result in prescriptions
                num_medications = random.randint(1, 3)
                for _ in range(num_medications):
                    prescription_id = self.counters["prescription"]
                    self.counters["prescription"] += 1

                    prescription = {
                        "prescription_id": prescription_id,
                        "record_id": record["record_id"],
                        "patient_id": record["patient_id"],
                        "doctor_id": record["doctor_id"],
                        "medication_name": random.choice(self.medications),
                        "dosage": f"{random.choice([100, 250, 500, 1000])}mg",
                        "frequency": random.choice(
                            [
                                "Once daily",
                                "Twice daily",
                                "Three times daily",
                                "As needed",
                            ]
                        ),
                        "duration": f"{random.randint(5, 30)} days",
                        "quantity": random.randint(10, 90),
                        "refills": random.randint(0, 3),
                        "instructions": self.fake.sentence(nb_words=15),
                        "prescribed_date": record["visit_date"],
                        "expiry_date": record["visit_date"] + timedelta(days=365),
                        "is_dispensed": random.choice([True, False]),
                        "created_at": record["visit_date"],
                    }
                    self.prescriptions.append(prescription)

        return self.prescriptions

    def generate_lab_tests(self) -> List[Dict]:
        """Generate lab test orders."""
        for record in self.medical_records:
            if random.random() > 0.4:  # 60% of visits require lab tests
                num_tests = random.randint(1, 3)
                for _ in range(num_tests):
                    test_id = self.counters["lab_test"]
                    self.counters["lab_test"] += 1

                    lab_test = {
                        "test_id": test_id,
                        "patient_id": record["patient_id"],
                        "doctor_id": record["doctor_id"],
                        "test_name": random.choice(self.test_types),
                        "test_category": random.choice(
                            ["Blood", "Urine", "Imaging", "Cardiology"]
                        ),
                        "ordered_date": record["visit_date"],
                        "status": random.choice(
                            ["pending", "in-progress", "completed"]
                        ),
                        "urgency": random.choice(["routine", "urgent", "stat"]),
                        "special_instructions": (
                            self.fake.sentence() if random.random() > 0.7 else None
                        ),
                        "created_at": record["visit_date"],
                    }
                    self.lab_tests.append(lab_test)

        return self.lab_tests

    def generate_lab_results(self) -> List[Dict]:
        """Generate lab results for completed tests."""
        completed_tests = [t for t in self.lab_tests if t["status"] == "completed"]

        for test in completed_tests:
            result_id = self.counters["lab_result"]
            self.counters["lab_result"] += 1

            # Generate realistic results based on test type
            if "Blood" in test["test_name"]:
                result_value = str(round(random.uniform(4.5, 6.0), 1))
                unit = "mmol/L"
                normal_range = "4.0-6.0"
            elif "Sugar" in test["test_name"]:
                result_value = str(random.randint(70, 150))
                unit = "mg/dL"
                normal_range = "70-100"
            else:
                result_value = random.choice(["Normal", "Abnormal", "Borderline"])
                unit = ""
                normal_range = "Normal"

            lab_result = {
                "result_id": result_id,
                "test_id": test["test_id"],
                "result_value": result_value,
                "unit": unit,
                "normal_range": normal_range,
                "is_abnormal": (
                    random.choice([True, False]) if result_value != "Normal" else False
                ),
                "result_date": test["ordered_date"]
                + timedelta(days=random.randint(1, 3)),
                "performed_by": (
                    random.choice(self.staff)["staff_id"] if self.staff else None
                ),
                "verified_by": random.choice(self.doctors)["doctor_id"],
                "comments": self.fake.sentence() if random.random() > 0.7 else None,
                "created_at": test["ordered_date"]
                + timedelta(days=random.randint(1, 3)),
            }
            self.lab_results.append(lab_result)

        return self.lab_results

    def generate_invoices(self) -> List[Dict]:
        """Generate invoices for completed appointments."""
        completed_appointments = [
            a for a in self.appointments if a["status"] == "completed"
        ]

        for appointment in completed_appointments:
            invoice_id = self.counters["invoice"]
            self.counters["invoice"] += 1

            doctor = next(
                d for d in self.doctors if d["doctor_id"] == appointment["doctor_id"]
            )
            consultation_fee = doctor["consultation_fee"]

            # Add additional charges
            lab_charges = sum(
                random.randint(50, 500)
                for t in self.lab_tests
                if t["patient_id"] == appointment["patient_id"]
                and t["ordered_date"] == appointment["appointment_date"]
            )
            medication_charges = sum(
                random.randint(20, 200)
                for p in self.prescriptions
                if p["patient_id"] == appointment["patient_id"]
                and p["prescribed_date"] == appointment["appointment_date"]
            )

            subtotal = consultation_fee + lab_charges + medication_charges
            tax = subtotal * 0.1
            total = subtotal + tax

            invoice = {
                "invoice_id": invoice_id,
                "invoice_number": f"INV{str(invoice_id).zfill(8)}",
                "patient_id": appointment["patient_id"],
                "appointment_id": appointment["appointment_id"],
                "invoice_date": appointment["appointment_date"],
                "due_date": appointment["appointment_date"] + timedelta(days=30),
                "subtotal": subtotal,
                "tax": tax,
                "discount": 0,
                "total_amount": total,
                "status": random.choices(
                    ["paid", "pending", "overdue"], weights=[60, 30, 10]
                )[0],
                "payment_method": (
                    random.choice(["cash", "credit_card", "insurance", "debit_card"])
                    if random.random() > 0.3
                    else None
                ),
                "notes": None,
                "created_at": appointment["appointment_date"],
                "updated_at": datetime.now(),
            }
            self.invoices.append(invoice)

        return self.invoices

    def generate_sql_inserts(self) -> str:
        """Generate SQL INSERT statements for all data."""
        sql_statements = []

        # Clinics
        for clinic in self.clinics:
            values: tuple[Any, ...] = (
                clinic["clinic_id"],
                clinic["clinic_name"],
                clinic["address"],
                clinic["city"],
                clinic["state"],
                clinic["zip_code"],
                clinic["phone"],
                clinic["email"],
                clinic["website"],
                clinic["established_date"],
                clinic["license_number"],
                clinic["tax_id"],
                clinic["is_emergency_available"],
            )
            sql = f"""INSERT INTO clinics (clinic_id, clinic_name, address, city, state, zip_code,
                     phone, email, website, established_date, license_number, tax_id, is_emergency_available)
                     VALUES {values};"""
            sql_statements.append(sql)

        # Departments
        for dept in self.departments:
            values: tuple[Any, ...] = (
                dept["department_id"],
                dept["clinic_id"],
                dept["department_name"],
                dept["department_head"],
                dept["phone_extension"],
                dept["floor"],
                dept["operating_hours"],
                dept["is_active"],
            )
            sql = f"""INSERT INTO departments (department_id, clinic_id, department_name, department_head,
                     phone_extension, floor, operating_hours, is_active)
                     VALUES {values};"""
            sql_statements.append(sql)

        # Doctors
        for doctor in self.doctors:
            values: tuple[Any, ...] = (
                doctor["doctor_id"],
                doctor["employee_id"],
                doctor["first_name"],
                doctor["last_name"],
                doctor["specialization"],
                doctor["license_number"],
                doctor["phone"],
                doctor["email"],
                doctor["department_id"],
                doctor["hire_date"],
                doctor["consultation_fee"],
                doctor["is_available"],
                doctor["years_of_experience"],
                doctor["education"],
                doctor["certifications"],
            )
            sql = f"""INSERT INTO doctors (doctor_id, employee_id, first_name, last_name, specialization,
                     license_number, phone, email, department_id, hire_date, consultation_fee,
                     is_available, years_of_experience, education, certifications)
                     VALUES {values};"""
            sql_statements.append(sql)

        # Patients
        for patient in self.patients:
            values: tuple[Any, ...] = (
                patient["patient_id"],
                patient["medical_record_number"],
                patient["first_name"],
                patient["last_name"],
                patient["date_of_birth"],
                patient["gender"],
                patient["blood_type"],
                patient["phone"],
                patient["email"],
                patient["address"],
                patient["city"],
                patient["state"],
                patient["zip_code"],
                patient["emergency_contact_name"],
                patient["emergency_contact_phone"],
                patient["insurance_provider"],
                patient["insurance_policy_number"],
                patient["allergies"],
                patient["chronic_conditions"],
            )
            sql = f"""INSERT INTO patients (patient_id, medical_record_number, first_name, last_name,
                     date_of_birth, gender, blood_type, phone, email, address, city, state, zip_code,
                     emergency_contact_name, emergency_contact_phone, insurance_provider,
                     insurance_policy_number, allergies, chronic_conditions)
                     VALUES {values};"""
            sql_statements.append(sql)

        # Add more tables as needed...

        return "\n".join(sql_statements)

    def generate_data(self, scale: str = "small"):
        """Generate all data based on scale."""
        scales = self.config["scales"][scale]

        print(f"Generating {scale} dataset...")
        print(f"- Clinics: {scales['clinics']}")
        print(f"- Departments per clinic: {scales['departments_per_clinic']}")
        print(f"- Doctors: {scales['doctors']}")
        print(f"- Nurses: {scales['nurses']}")
        print(f"- Patients: {scales['patients']}")
        print(f"- Appointments: {scales['appointments']}")

        # Generate data in order
        self.generate_clinics(scales["clinics"])
        self.generate_departments(scales["departments_per_clinic"])
        self.generate_doctors(scales["doctors"])
        self.generate_nurses(scales["nurses"])
        self.generate_patients(scales["patients"])
        self.generate_appointments(scales["appointments"])
        self.generate_medical_records()
        self.generate_prescriptions()
        self.generate_lab_tests()
        self.generate_lab_results()
        self.generate_invoices()

        print("\nData generation complete!")
        print(f"- Medical Records: {len(self.medical_records)}")
        print(f"- Prescriptions: {len(self.prescriptions)}")
        print(f"- Lab Tests: {len(self.lab_tests)}")
        print(f"- Lab Results: {len(self.lab_results)}")
        print(f"- Invoices: {len(self.invoices)}")


def main():
    """Handle main."""
    parser = argparse.ArgumentParser(
        description="Generate sample data for clinic database"
    )
    parser.add_argument(
        "--scale",
        choices=["small", "medium", "large"],
        default="small",
        help="Scale of data to generate",
    )
    parser.add_argument("--output", default="sample_data.sql", help="Output SQL file")
    parser.add_argument(
        "--format", choices=["sql", "json", "csv"], default="sql", help="Output format"
    )

    args = parser.parse_args()

    generator = ClinicDataGenerator()
    generator.generate_data(args.scale)

    # Generate output
    if args.format == "sql":
        sql_output = generator.generate_sql_inserts()
        with open(args.output, "w") as f:
            f.write("-- Medical Clinic Sample Data\n")
            f.write(f"-- Generated: {datetime.now()}\n")
            f.write(f"-- Scale: {args.scale}\n\n")
            f.write("USE clinic_db;\n\n")
            f.write("-- Disable foreign key checks for bulk insert\n")
            f.write("SET FOREIGN_KEY_CHECKS = 0;\n\n")
            f.write(sql_output)
            f.write("\n\n-- Re-enable foreign key checks\n")
            f.write("SET FOREIGN_KEY_CHECKS = 1;\n")
        print(f"\nSQL output written to {args.output}")

    elif args.format == "json":
        output_data = {
            "clinics": generator.clinics,
            "departments": generator.departments,
            "doctors": generator.doctors,
            "nurses": generator.nurses,
            "patients": generator.patients,
            "appointments": generator.appointments,
            "medical_records": generator.medical_records,
            "prescriptions": generator.prescriptions,
            "lab_tests": generator.lab_tests,
            "lab_results": generator.lab_results,
            "invoices": generator.invoices,
        }

        # Convert dates to strings for JSON serialization
        def convert_dates(obj):
            """Handle convert dates."""
            if isinstance(obj, (datetime, date)):
                return obj.isoformat()
            elif isinstance(obj, dict):
                return {k: convert_dates(v) for k, v in obj.items()}
            elif isinstance(obj, list):
                return [convert_dates(item) for item in obj]
            return obj

        output_data = convert_dates(output_data)

        with open(args.output.replace(".sql", ".json"), "w") as f:
            json.dump(output_data, f, indent=2, default=str)
        print(f"\nJSON output written to {args.output.replace('.sql', '.json')}")


if __name__ == "__main__":
    main()
