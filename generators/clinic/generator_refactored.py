#!/usr/bin/env python3
"""
Medical Clinic Data Generator - Refactored with BaseGenerator
Generates realistic sample data for the medical clinic database schema
"""

import sys
import os
import random
import json
import yaml
import argparse
from datetime import datetime, timedelta, date
from typing import List, Dict, Any, Tuple

# Add parent directory to path to import base_generator
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from base_generator import BaseGenerator

from faker import Faker
from faker.providers import person, address, phone_number, company, date_time, python


class ClinicDataGenerator(BaseGenerator):
    """Medical Clinic Data Generator using BaseGenerator infrastructure"""

    def __init__(self, config_path: str = "config.yaml", **db_params):
        """Initialize the generator with configuration and database connection"""
        # Initialize base class with database connection parameters
        super().__init__(**db_params)

        # Additional faker setup
        self.fake = self.faker  # Use the faker from base class
        self.fake.add_provider(person)
        self.fake.add_provider(address)
        self.fake.add_provider(phone_number)
        self.fake.add_provider(company)
        self.fake.add_provider(date_time)
        self.fake.add_provider(python)

        # Load configuration
        if os.path.exists(config_path):
            with open(config_path, "r") as f:
                self.config = yaml.safe_load(f)
        else:
            self.config = self.get_default_config()

        # Data storage (will be populated during generation)
        self.clinics = []
        self.departments = []
        self.doctors = []
        self.nurses = []
        self.staff = []
        self.patients = []
        self.appointments = []
        self.medical_records = []
        self.prescriptions = []
        self.lab_tests = []
        self.lab_results = []
        self.billing_items = []
        self.invoices = []
        self.payments = []
        self.insurance_claims = []
        self.inventory_items = []
        self.inventory_transactions = []
        self.equipment = []
        self.maintenance_logs = []

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

        self.blood_types = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]

        self.insurance_providers = [
            "Blue Cross Blue Shield",
            "Aetna",
            "UnitedHealth",
            "Cigna",
            "Humana",
            "Kaiser Permanente",
            "Anthem",
            "Centene",
        ]

        self.lab_test_types = [
            "Complete Blood Count",
            "Blood Chemistry Panel",
            "Lipid Panel",
            "Thyroid Function",
            "Liver Function",
            "Kidney Function",
            "Urinalysis",
            "X-Ray",
            "MRI",
            "CT Scan",
            "Ultrasound",
        ]

        self.medications = [
            "Amoxicillin",
            "Lisinopril",
            "Levothyroxine",
            "Metformin",
            "Atorvastatin",
            "Omeprazole",
            "Simvastatin",
            "Losartan",
            "Albuterol",
            "Gabapentin",
            "Metoprolol",
            "Sertraline",
            "Acetaminophen",
            "Ibuprofen",
            "Prednisone",
        ]

    def get_default_config(self) -> dict:
        """Return default configuration if config file is not found"""
        return {
            "scale": {
                "small": {
                    "clinics": 2,
                    "departments_per_clinic": 5,
                    "doctors": 20,
                    "nurses": 30,
                    "staff": 15,
                    "patients": 500,
                    "appointments": 1000,
                    "prescriptions": 800,
                    "lab_tests": 600,
                    "invoices": 900,
                },
                "medium": {
                    "clinics": 5,
                    "departments_per_clinic": 8,
                    "doctors": 50,
                    "nurses": 80,
                    "staff": 40,
                    "patients": 2000,
                    "appointments": 5000,
                    "prescriptions": 4000,
                    "lab_tests": 3000,
                    "invoices": 4500,
                },
                "large": {
                    "clinics": 10,
                    "departments_per_clinic": 10,
                    "doctors": 100,
                    "nurses": 150,
                    "staff": 80,
                    "patients": 10000,
                    "appointments": 25000,
                    "prescriptions": 20000,
                    "lab_tests": 15000,
                    "invoices": 22000,
                },
            },
            "settings": {"start_date": "2023-01-01", "end_date": "2024-12-31"},
        }

    def generate_clinics(self, count: int):
        """Generate clinic data"""
        for _ in range(count):
            clinic = {
                "clinic_id": self.counters["clinic"],
                "clinic_name": f"{self.fake.company()} Medical Center",
                "address": self.fake.street_address(),
                "city": self.fake.city(),
                "state": self.fake.state_abbr(),
                "zip_code": self.fake.zipcode(),
                "phone": self.fake.phone_number(),
                "email": self.fake.company_email(),
                "website": self.fake.url(),
                "established_date": self.fake.date_between(
                    start_date="-20y", end_date="-1y"
                ),
                "license_number": f"LIC-{self.fake.random_int(10000, 99999)}",
                "tax_id": f"{self.fake.random_int(10, 99)}-{self.fake.random_int(1000000, 9999999)}",
                "is_emergency_available": random.choice([0, 1]),
            }
            self.clinics.append(clinic)
            self.counters["clinic"] += 1

    def generate_departments(self, departments_per_clinic: int):
        """Generate department data"""
        for clinic in self.clinics:
            for dept_type in random.sample(
                self.department_types,
                min(departments_per_clinic, len(self.department_types)),
            ):
                department = {
                    "department_id": self.counters["department"],
                    "clinic_id": clinic["clinic_id"],
                    "department_name": dept_type,
                    "department_head": self.fake.name(),
                    "phone_extension": self.fake.random_int(1000, 9999),
                    "floor": self.fake.random_int(1, 5),
                    "operating_hours": (
                        "08:00-17:00" if dept_type != "Emergency" else "24/7"
                    ),
                    "is_active": 1,
                }
                self.departments.append(department)
                self.counters["department"] += 1

    def generate_doctors(self, count: int):
        """Generate doctor data"""
        for _ in range(count):
            doctor = {
                "doctor_id": self.counters["doctor"],
                "employee_id": f"EMP-{self.fake.random_int(10000, 99999)}",
                "first_name": self.fake.first_name(),
                "last_name": self.fake.last_name(),
                "specialization": random.choice(self.specializations),
                "license_number": f"MD-{self.fake.random_int(100000, 999999)}",
                "phone": self.fake.phone_number(),
                "email": self.fake.email(),
                "department_id": (
                    random.choice(self.departments)["department_id"]
                    if self.departments
                    else 1
                ),
                "hire_date": self.fake.date_between(
                    start_date="-10y", end_date="today"
                ),
                "consultation_fee": round(random.uniform(100, 500), 2),
                "is_available": 1,
                "years_of_experience": self.fake.random_int(1, 30),
                "education": f"{self.fake.company()} Medical School",
                "certifications": json.dumps(
                    [f"Board Certified - {random.choice(self.specializations)}"]
                ),
            }
            self.doctors.append(doctor)
            self.counters["doctor"] += 1

    def generate_patients(self, count: int):
        """Generate patient data"""
        for _ in range(count):
            patient = {
                "patient_id": self.counters["patient"],
                "medical_record_number": f"MRN-{self.fake.random_int(100000, 999999)}",
                "first_name": self.fake.first_name(),
                "last_name": self.fake.last_name(),
                "date_of_birth": self.fake.date_of_birth(minimum_age=1, maximum_age=90),
                "gender": random.choice(["M", "F", "Other"]),
                "blood_type": random.choice(self.blood_types),
                "phone": self.fake.phone_number(),
                "email": self.fake.email(),
                "address": self.fake.street_address(),
                "city": self.fake.city(),
                "state": self.fake.state_abbr(),
                "zip_code": self.fake.zipcode(),
                "emergency_contact_name": self.fake.name(),
                "emergency_contact_phone": self.fake.phone_number(),
                "insurance_provider": random.choice(self.insurance_providers),
                "insurance_policy_number": f"POL-{self.fake.random_int(10000000, 99999999)}",
                "allergies": json.dumps(
                    random.sample(
                        ["Penicillin", "Peanuts", "Latex", "None"], random.randint(0, 2)
                    )
                ),
                "chronic_conditions": json.dumps(
                    random.sample(
                        ["Diabetes", "Hypertension", "Asthma", "None"],
                        random.randint(0, 2),
                    )
                ),
            }
            self.patients.append(patient)
            self.counters["patient"] += 1

    def generate_appointments(self, count: int):
        """Generate appointment data"""
        start_date = datetime.strptime(
            self.config["settings"]["start_date"], "%Y-%m-%d"
        )
        end_date = datetime.strptime(self.config["settings"]["end_date"], "%Y-%m-%d")

        for _ in range(count):
            appointment_date = self.random_datetime_between(start_date, end_date)
            appointment = {
                "appointment_id": self.counters["appointment"],
                "patient_id": (
                    random.choice(self.patients)["patient_id"] if self.patients else 1
                ),
                "doctor_id": (
                    random.choice(self.doctors)["doctor_id"] if self.doctors else 1
                ),
                "appointment_date": appointment_date.date(),
                "appointment_time": appointment_date.strftime("%H:%M:%S"),
                "appointment_type": random.choice(self.appointment_types),
                "status": random.choice(self.appointment_statuses),
                "reason_for_visit": self.fake.sentence(nb_words=10),
                "notes": (
                    self.fake.text(max_nb_chars=200) if random.random() > 0.5 else None
                ),
                "duration_minutes": random.choice([15, 30, 45, 60]),
                "created_at": appointment_date - timedelta(days=random.randint(1, 30)),
                "updated_at": appointment_date,
            }
            self.appointments.append(appointment)
            self.counters["appointment"] += 1

    def insert_data_to_database(self):
        """Insert generated data into database using bulk operations"""
        try:
            # Connect to database
            self.connect()

            # Clear existing data (optional - be careful in production!)
            if self.config.get("clear_existing_data", False):
                self.truncate_all_tables()

            # Insert clinics
            if self.clinics:
                clinic_data = [tuple(clinic.values()) for clinic in self.clinics]
                self.bulk_insert("clinics", clinic_data, list(self.clinics[0].keys()))
                print(f"Inserted {len(self.clinics)} clinics")

            # Insert departments
            if self.departments:
                dept_data = [tuple(dept.values()) for dept in self.departments]
                self.bulk_insert(
                    "departments", dept_data, list(self.departments[0].keys())
                )
                print(f"Inserted {len(self.departments)} departments")

            # Insert doctors
            if self.doctors:
                doctor_data = [tuple(doctor.values()) for doctor in self.doctors]
                self.bulk_insert("doctors", doctor_data, list(self.doctors[0].keys()))
                print(f"Inserted {len(self.doctors)} doctors")

            # Insert patients
            if self.patients:
                patient_data = [tuple(patient.values()) for patient in self.patients]
                self.bulk_insert(
                    "patients", patient_data, list(self.patients[0].keys())
                )
                print(f"Inserted {len(self.patients)} patients")

            # Insert appointments
            if self.appointments:
                appointment_data = [
                    tuple(appointment.values()) for appointment in self.appointments
                ]
                self.bulk_insert(
                    "appointments", appointment_data, list(self.appointments[0].keys())
                )
                print(f"Inserted {len(self.appointments)} appointments")

            # Print statistics
            self.print_statistics()

        except Exception as e:
            print(f"Error inserting data: {e}")
            raise
        finally:
            # Disconnect from database
            self.disconnect()

    def generate_data(self, scale: str = "small"):
        """Main method to generate all data"""
        scale_config = self.config["scale"][scale]

        print(f"\nGenerating {scale} scale data for clinic database...")
        print("=" * 50)

        # Generate data in order of dependencies
        self.generate_clinics(scale_config["clinics"])
        print(f"✓ Generated {len(self.clinics)} clinics")

        self.generate_departments(scale_config["departments_per_clinic"])
        print(f"✓ Generated {len(self.departments)} departments")

        self.generate_doctors(scale_config["doctors"])
        print(f"✓ Generated {len(self.doctors)} doctors")

        self.generate_patients(scale_config["patients"])
        print(f"✓ Generated {len(self.patients)} patients")

        self.generate_appointments(scale_config["appointments"])
        print(f"✓ Generated {len(self.appointments)} appointments")

        # TODO: Add generation for other entities (prescriptions, lab_tests, invoices, etc.)

        return {
            "clinics": self.clinics,
            "departments": self.departments,
            "doctors": self.doctors,
            "patients": self.patients,
            "appointments": self.appointments,
        }

    def export_to_json(self, filename: str):
        """Export generated data to JSON file"""
        data = {
            "clinics": self.clinics,
            "departments": self.departments,
            "doctors": self.doctors,
            "patients": self.patients,
            "appointments": self.appointments,
        }

        with open(filename, "w") as f:
            json.dump(data, f, indent=2, default=str)
        print(f"\nData exported to {filename}")

    def export_to_sql(self, filename: str):
        """Export generated data to SQL file (legacy support)"""
        sql_statements = []

        # Generate INSERT statements for each table
        for clinic in self.clinics:
            values = ", ".join(
                [f"'{v}'" if v is not None else "NULL" for v in clinic.values()]
            )
            sql = f"INSERT INTO clinics ({', '.join(clinic.keys())}) VALUES ({values});"
            sql_statements.append(sql)

        for dept in self.departments:
            values = ", ".join(
                [f"'{v}'" if v is not None else "NULL" for v in dept.values()]
            )
            sql = (
                f"INSERT INTO departments ({', '.join(dept.keys())}) VALUES ({values});"
            )
            sql_statements.append(sql)

        # ... (similar for other tables)

        with open(filename, "w") as f:
            f.write("\n".join(sql_statements))
        print(f"\nSQL statements exported to {filename}")


def main():
    parser = argparse.ArgumentParser(
        description="Generate sample data for clinic database"
    )
    parser.add_argument(
        "--scale",
        choices=["small", "medium", "large"],
        default="small",
        help="Scale of data to generate",
    )
    parser.add_argument("--output", default="sample_data.sql", help="Output file")
    parser.add_argument(
        "--format",
        choices=["sql", "json", "database"],
        default="database",
        help="Output format (sql, json, or direct database insertion)",
    )
    parser.add_argument(
        "--config", default="config.yaml", help="Configuration file path"
    )

    # Database connection parameters
    parser.add_argument("--host", default="localhost", help="Database host")
    parser.add_argument("--port", type=int, default=3306, help="Database port")
    parser.add_argument("--user", default="root", help="Database user")
    parser.add_argument("--password", default="password", help="Database password")
    parser.add_argument("--database", default="clinic_management", help="Database name")

    args = parser.parse_args()

    # Create generator with database parameters
    generator = ClinicDataGenerator(
        config_path=args.config,
        host=args.host,
        port=args.port,
        user=args.user,
        password=args.password,
        database=args.database,
    )

    # Generate data
    data = generator.generate_data(args.scale)

    # Output based on format
    if args.format == "database":
        # Insert directly into database
        generator.insert_data_to_database()
    elif args.format == "json":
        # Export to JSON
        generator.export_to_json(args.output.replace(".sql", ".json"))
    else:  # sql
        # Export to SQL file
        generator.export_to_sql(args.output)

    print("\n✅ Data generation complete!")


if __name__ == "__main__":
    main()
