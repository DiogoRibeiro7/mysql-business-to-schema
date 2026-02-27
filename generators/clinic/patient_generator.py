#!/usr/bin/env python3
"""
Clinic Patient Data Generator
Generates realistic patient data with medical history
"""

import random
from datetime import datetime, timedelta
from typing import List, Dict
from faker import Faker
from faker.providers import BaseProvider

fake = Faker()


class MedicalProvider(BaseProvider):
    """Custom provider for medical data"""

    blood_types = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]

    allergies = [
        "Penicillin",
        "Pollen",
        "Dust",
        "Peanuts",
        "Shellfish",
        "Latex",
        "Milk",
        "Eggs",
        "Tree nuts",
        "Soy",
        "None",
    ]

    chronic_conditions = [
        "Diabetes Type 2",
        "Hypertension",
        "Asthma",
        "Arthritis",
        "COPD",
        "Heart Disease",
        "Chronic Kidney Disease",
        "None",
    ]

    medications = [
        "Metformin",
        "Lisinopril",
        "Atorvastatin",
        "Omeprazole",
        "Amlodipine",
        "Metoprolol",
        "Albuterol",
        "Losartan",
        "Gabapentin",
        "Hydrochlorothiazide",
    ]

    specialties = [
        "Cardiology",
        "Dermatology",
        "Endocrinology",
        "Gastroenterology",
        "Neurology",
        "Oncology",
        "Pediatrics",
        "Psychiatry",
        "Pulmonology",
        "Rheumatology",
        "General Practice",
    ]

    def blood_type(self):
        return self.random_element(self.blood_types)

    def allergy(self):
        return self.random_element(self.allergies)

    def chronic_condition(self):
        return self.random_element(self.chronic_conditions)

    def medication(self):
        return self.random_element(self.medications)

    def medical_specialty(self):
        return self.random_element(self.specialties)


# Add the custom provider
fake.add_provider(MedicalProvider)


class PatientGenerator:
    """Generate comprehensive patient data"""

    def __init__(self):
        self.fake = fake

    def generate_patients(self, count: int) -> List[Dict]:
        """Generate patient records"""
        patients = []

        for i in range(count):
            dob = self.fake.date_of_birth(minimum_age=1, maximum_age=95)
            age = (datetime.now().date() - dob).days // 365

            patient = {
                "patient_id": f"PAT{i+1:06d}",
                "first_name": self.fake.first_name(),
                "last_name": self.fake.last_name(),
                "date_of_birth": dob,
                "age": age,
                "gender": random.choice(["M", "F", "O"]),
                "blood_type": self.fake.blood_type(),
                "height_cm": random.randint(120, 210),
                "weight_kg": random.randint(30, 150),
                "email": self.fake.email(),
                "phone": self.fake.phone_number()[:20],
                "address": self.fake.street_address(),
                "city": self.fake.city(),
                "state": self.fake.state_abbr(),
                "zip_code": self.fake.zipcode(),
                "emergency_contact_name": self.fake.name(),
                "emergency_contact_phone": self.fake.phone_number()[:20],
                "emergency_contact_relationship": random.choice(
                    ["Spouse", "Parent", "Sibling", "Child", "Friend"]
                ),
                "insurance_provider": self.fake.company(),
                "insurance_policy_number": self.fake.uuid4()[:20],
                "primary_care_physician": f"Dr. {self.fake.name()}",
                "allergies": ", ".join(
                    random.sample(
                        [self.fake.allergy() for _ in range(3)], k=random.randint(0, 3)
                    )
                ),
                "chronic_conditions": ", ".join(
                    random.sample(
                        [self.fake.chronic_condition() for _ in range(2)],
                        k=random.randint(0, 2),
                    )
                ),
                "current_medications": ", ".join(
                    random.sample(
                        [self.fake.medication() for _ in range(5)],
                        k=random.randint(0, 5),
                    )
                ),
                "registration_date": self.fake.date_between(
                    start_date="-5y", end_date="today"
                ),
                "last_visit_date": self.fake.date_between(
                    start_date="-1y", end_date="today"
                ),
                "status": random.choice(
                    ["Active", "Inactive", "Deceased"]
                    if age > 70
                    else ["Active", "Inactive"]
                ),
                "created_at": datetime.now(),
                "updated_at": datetime.now(),
            }

            # Calculate BMI
            if patient["height_cm"] > 0:
                height_m = patient["height_cm"] / 100
                patient["bmi"] = round(patient["weight_kg"] / (height_m**2), 1)

            patients.append(patient)

        return patients

    def generate_doctors(self, count: int) -> List[Dict]:
        """Generate doctor records"""
        doctors = []

        for i in range(count):
            doctor = {
                "doctor_id": f"DOC{i+1:04d}",
                "first_name": self.fake.first_name(),
                "last_name": self.fake.last_name(),
                "specialization": self.fake.medical_specialty(),
                "license_number": f"MD{random.randint(100000, 999999)}",
                "email": self.fake.email(),
                "phone": self.fake.phone_number()[:20],
                "office_address": self.fake.address()[:255],
                "years_experience": random.randint(1, 40),
                "consultation_fee": random.randint(100, 500),
                "available_days": random.choice(
                    ["Mon-Fri", "Mon-Sat", "Tue-Sat", "Mon-Wed-Fri"]
                ),
                "working_hours": random.choice(
                    ["9:00-17:00", "8:00-16:00", "10:00-18:00", "14:00-22:00"]
                ),
                "rating": round(random.uniform(3.5, 5.0), 1),
                "patients_seen": random.randint(100, 10000),
                "joined_date": self.fake.date_between(
                    start_date="-10y", end_date="today"
                ),
                "status": random.choice(
                    ["Active", "On Leave", "Retired"]
                    if random.random() > 0.9
                    else ["Active"]
                ),
                "created_at": datetime.now(),
            }
            doctors.append(doctor)

        return doctors

    def generate_appointments(
        self, count: int, patient_ids: List[str], doctor_ids: List[str]
    ) -> List[Dict]:
        """Generate appointment records"""
        appointments = []
        appointment_types = [
            "Consultation",
            "Follow-up",
            "Emergency",
            "Routine Check-up",
            "Vaccination",
            "Test Results",
        ]
        statuses = ["Scheduled", "Completed", "Cancelled", "No Show", "Rescheduled"]

        for i in range(count):
            appointment_date = self.fake.date_time_between(
                start_date="-1y", end_date="+1m"
            )

            appointment = {
                "appointment_id": f"APT{i+1:08d}",
                "patient_id": random.choice(patient_ids),
                "doctor_id": random.choice(doctor_ids),
                "appointment_date": appointment_date.date(),
                "appointment_time": appointment_date.time(),
                "duration_minutes": random.choice([15, 30, 45, 60]),
                "appointment_type": random.choice(appointment_types),
                "reason_for_visit": self.fake.sentence(nb_words=10),
                "symptoms": ", ".join(self.fake.words(nb=random.randint(1, 5))),
                "status": random.choice(statuses),
                "notes": (
                    self.fake.text(max_nb_chars=200) if random.random() > 0.5 else None
                ),
                "follow_up_required": random.choice([True, False]),
                "created_at": appointment_date - timedelta(days=random.randint(1, 30)),
                "updated_at": datetime.now(),
            }
            appointments.append(appointment)

        return appointments

    def generate_medical_records(
        self, count: int, patient_ids: List[str], doctor_ids: List[str]
    ) -> List[Dict]:
        """Generate medical record entries"""
        records = []
        diagnoses = [
            "Common Cold",
            "Influenza",
            "Hypertension",
            "Diabetes Mellitus",
            "Acute Bronchitis",
            "Gastroenteritis",
            "Urinary Tract Infection",
            "Migraine",
            "Back Pain",
            "Anxiety Disorder",
            "Allergic Rhinitis",
        ]

        for i in range(count):
            record = {
                "record_id": f"MR{i+1:08d}",
                "patient_id": random.choice(patient_ids),
                "doctor_id": random.choice(doctor_ids),
                "visit_date": self.fake.date_between(
                    start_date="-2y", end_date="today"
                ),
                "chief_complaint": self.fake.sentence(nb_words=8),
                "diagnosis": random.choice(diagnoses),
                "icd10_code": f'{random.choice(["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M"])}{random.randint(10, 99)}.{random.randint(0, 9)}',
                "treatment_plan": self.fake.text(max_nb_chars=300),
                "prescriptions": ", ".join(
                    [self.fake.medication() for _ in range(random.randint(0, 3))]
                ),
                "lab_orders": ", ".join(
                    random.sample(
                        [
                            "CBC",
                            "Metabolic Panel",
                            "Lipid Panel",
                            "Thyroid Panel",
                            "Urinalysis",
                        ],
                        k=random.randint(0, 3),
                    )
                ),
                "vital_signs": {
                    "blood_pressure": f"{random.randint(90, 140)}/{random.randint(60, 90)}",
                    "heart_rate": random.randint(60, 100),
                    "temperature": round(random.uniform(97.0, 99.5), 1),
                    "respiratory_rate": random.randint(12, 20),
                    "oxygen_saturation": random.randint(95, 100),
                },
                "follow_up_date": (
                    self.fake.date_between(start_date="today", end_date="+2m")
                    if random.random() > 0.3
                    else None
                ),
                "notes": self.fake.text(max_nb_chars=500),
                "created_at": datetime.now(),
            }
            records.append(record)

        return records

    def generate_prescriptions(
        self, count: int, patient_ids: List[str], doctor_ids: List[str]
    ) -> List[Dict]:
        """Generate prescription records"""
        prescriptions = []
        dosages = ["5mg", "10mg", "20mg", "50mg", "100mg", "250mg", "500mg"]
        frequencies = [
            "Once daily",
            "Twice daily",
            "Three times daily",
            "Four times daily",
            "As needed",
            "Every 6 hours",
        ]

        for i in range(count):
            start_date = self.fake.date_between(start_date="-1y", end_date="today")

            prescription = {
                "prescription_id": f"RX{i+1:08d}",
                "patient_id": random.choice(patient_ids),
                "doctor_id": random.choice(doctor_ids),
                "medication_name": self.fake.medication(),
                "dosage": random.choice(dosages),
                "frequency": random.choice(frequencies),
                "duration_days": random.choice([7, 10, 14, 30, 60, 90]),
                "quantity": random.randint(10, 180),
                "refills": random.randint(0, 5),
                "start_date": start_date,
                "end_date": start_date + timedelta(days=random.randint(7, 90)),
                "instructions": self.fake.sentence(nb_words=15),
                "pharmacy": self.fake.company(),
                "status": random.choice(
                    ["Active", "Completed", "Cancelled", "On Hold"]
                ),
                "dispensed_date": (
                    start_date + timedelta(days=random.randint(0, 2))
                    if random.random() > 0.2
                    else None
                ),
                "created_at": start_date,
                "updated_at": datetime.now(),
            }
            prescriptions.append(prescription)

        return prescriptions


def main():
    """Test the generator"""
    generator = PatientGenerator()

    # Generate sample data
    patients = generator.generate_patients(5)
    doctors = generator.generate_doctors(3)

    patient_ids = [p["patient_id"] for p in patients]
    doctor_ids = [d["doctor_id"] for d in doctors]

    appointments = generator.generate_appointments(10, patient_ids, doctor_ids)
    medical_records = generator.generate_medical_records(15, patient_ids, doctor_ids)
    prescriptions = generator.generate_prescriptions(20, patient_ids, doctor_ids)

    # Display sample
    print("Sample Patient:")
    print(patients[0])
    print("\nSample Doctor:")
    print(doctors[0])
    print("\nSample Appointment:")
    print(appointments[0])


if __name__ == "__main__":
    main()
