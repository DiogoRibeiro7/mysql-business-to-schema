#!/usr/bin/env python3
"""
Demo Data Generator - Creates sample SQL files
Works without requiring MySQL connection
"""

import os
import json
import random
from datetime import datetime, timedelta
from faker import Faker
from typing import List, Dict
import sys

# Fix encoding for Windows
if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

fake = Faker()

class DemoDataGenerator:
    """Generate demo SQL files for all schemas"""

    def __init__(self, output_dir: str = "demo_data"):
        self.output_dir = output_dir
        os.makedirs(output_dir, exist_ok=True)

    def generate_clinic_data(self, count: int = 100):
        """Generate clinic data"""
        print("Generating clinic data...")

        sql_lines = [
            "-- Demo data for clinic_db",
            "USE clinic_db;",
            "",
            "-- Clear existing data",
            "SET FOREIGN_KEY_CHECKS = 0;",
            "TRUNCATE TABLE patients;",
            "SET FOREIGN_KEY_CHECKS = 1;",
            "",
            "-- Insert patients",
            "INSERT INTO patients (first_name, last_name, date_of_birth, gender, email, phone, address, city, state, zip_code) VALUES"
        ]

        values = []
        for i in range(count):
            street_address = fake.street_address().replace("'", "''")
            patient = (
                f"('{fake.first_name()}', '{fake.last_name()}', "
                f"'{fake.date_of_birth()}', '{random.choice(['M', 'F'])}', "
                f"'{fake.email()}', '{fake.phone_number()[:20]}', "
                f"'{street_address}', "
                f"'{fake.city()}', '{fake.state_abbr()}', '{fake.zipcode()}')"
            )
            values.append(patient)

        sql_lines.append(',\n'.join(values) + ';')

        # Save to file
        output_file = os.path.join(self.output_dir, 'clinic_db_data.sql')
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write('\n'.join(sql_lines))

        print(f"  Created: {output_file} ({count} patients)")
        return output_file

    def generate_ecommerce_data(self, count: int = 100):
        """Generate e-commerce data"""
        print("Generating e-commerce data...")

        sql_lines = [
            "-- Demo data for ecommerce_db",
            "USE ecommerce_db;",
            "",
            "-- Clear existing data",
            "SET FOREIGN_KEY_CHECKS = 0;",
            "TRUNCATE TABLE products;",
            "TRUNCATE TABLE customers;",
            "SET FOREIGN_KEY_CHECKS = 1;",
            "",
            "-- Insert products",
            "INSERT INTO products (name, description, category, price, stock_quantity) VALUES"
        ]

        # Generate products
        values = []
        categories = ['Electronics', 'Clothing', 'Books', 'Home & Garden', 'Sports']
        for i in range(count):
            product_name = fake.catch_phrase().replace("'", "''")
            product_desc = fake.text(max_nb_chars=200).replace("'", "''")
            product = (
                f"('{product_name}', "
                f"'{product_desc}', "
                f"'{random.choice(categories)}', "
                f"{round(random.uniform(9.99, 999.99), 2)}, "
                f"{random.randint(0, 1000)})"
            )
            values.append(product)

        sql_lines.append(',\n'.join(values) + ';')

        # Generate customers
        sql_lines.append("\n-- Insert customers")
        sql_lines.append("INSERT INTO customers (first_name, last_name, email, phone, registration_date) VALUES")

        values = []
        for i in range(count // 2):
            customer = (
                f"('{fake.first_name()}', '{fake.last_name()}', "
                f"'{fake.email()}', '{fake.phone_number()[:20]}', "
                f"'{fake.date_between(start_date='-2y', end_date='today')}')"
            )
            values.append(customer)

        sql_lines.append(',\n'.join(values) + ';')

        # Save to file
        output_file = os.path.join(self.output_dir, 'ecommerce_db_data.sql')
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write('\n'.join(sql_lines))

        print(f"  Created: {output_file} ({count} products, {count//2} customers)")
        return output_file

    def generate_iot_data(self, count: int = 100):
        """Generate IoT sensor data"""
        print("Generating IoT data...")

        sql_lines = [
            "-- Demo data for iot_bins_db",
            "USE iot_bins_db;",
            "",
            "-- Clear existing data",
            "SET FOREIGN_KEY_CHECKS = 0;",
            "TRUNCATE TABLE sensors;",
            "TRUNCATE TABLE readings;",
            "SET FOREIGN_KEY_CHECKS = 1;",
            "",
            "-- Insert sensors",
            "INSERT INTO sensors (sensor_id, type, location, status) VALUES"
        ]

        # Generate sensors
        sensor_types = ['temperature', 'humidity', 'pressure', 'motion', 'light']
        values = []
        for i in range(count // 5):
            sensor_location = fake.address().replace("'", "''")
            sensor = (
                f"('SENSOR_{i+1:06d}', '{random.choice(sensor_types)}', "
                f"'{sensor_location}', 'active')"
            )
            values.append(sensor)

        sql_lines.append(',\n'.join(values) + ';')

        # Generate readings
        sql_lines.append("\n-- Insert sensor readings")
        sql_lines.append("INSERT INTO readings (sensor_id, timestamp, value, unit) VALUES")

        values = []
        for i in range(count):
            sensor_id = f'SENSOR_{random.randint(1, count//5):06d}'
            reading = (
                f"('{sensor_id}', "
                f"'{fake.date_time_between(start_date='-30d', end_date='now')}', "
                f"{round(random.uniform(0, 100), 2)}, "
                f"'{random.choice(['C', '%', 'kPa', 'lux'])}')"
            )
            values.append(reading)

        sql_lines.append(',\n'.join(values) + ';')

        # Save to file
        output_file = os.path.join(self.output_dir, 'iot_bins_db_data.sql')
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write('\n'.join(sql_lines))

        print(f"  Created: {output_file} ({count//5} sensors, {count} readings)")
        return output_file

    def generate_all(self, records_per_schema: int = 100):
        """Generate data for all main schemas"""
        print("\n" + "="*60)
        print("Demo Data Generation")
        print("="*60 + "\n")

        files_created = []

        # Generate data for each schema type
        files_created.append(self.generate_clinic_data(records_per_schema))
        files_created.append(self.generate_ecommerce_data(records_per_schema))
        files_created.append(self.generate_iot_data(records_per_schema))

        # Create a master import script
        master_script = os.path.join(self.output_dir, 'import_all.sql')
        with open(master_script, 'w', encoding='utf-8') as f:
            f.write("-- Master import script for all demo data\n")
            f.write("-- Run this after creating the database schemas\n\n")
            for file in files_created:
                f.write(f"SOURCE {os.path.basename(file)};\n")

        print(f"\n  Created master script: {master_script}")

        # Create summary JSON
        summary = {
            'generated_at': datetime.now().isoformat(),
            'files_created': files_created,
            'total_records': records_per_schema * 3,
            'schemas': ['clinic_db', 'ecommerce_db', 'iot_bins_db']
        }

        summary_file = os.path.join(self.output_dir, 'generation_summary.json')
        with open(summary_file, 'w', encoding='utf-8') as f:
            json.dump(summary, f, indent=2)

        print(f"  Created summary: {summary_file}")

        print("\n" + "="*60)
        print("Demo Data Generation Complete!")
        print("="*60)
        print("\nTo use the generated data:")
        print("1. Ensure MySQL is running with the correct password")
        print("2. Create the schemas first (if not exists):")
        print("   mysql -u root -p < example_01_clinic/schema/00_create_database.sql")
        print("3. Import the demo data:")
        print(f"   cd {self.output_dir}")
        print("   mysql -u root -p < import_all.sql")
        print("\nOr import individual files:")
        for file in files_created:
            print(f"   mysql -u root -p < {os.path.basename(file)}")

def main():
    """Main execution"""
    import argparse

    parser = argparse.ArgumentParser(description='Generate demo SQL data files')
    parser.add_argument('--records', type=int, default=100,
                       help='Number of records per schema (default: 100)')
    parser.add_argument('--output', default='demo_data',
                       help='Output directory (default: demo_data)')

    args = parser.parse_args()

    generator = DemoDataGenerator(args.output)
    generator.generate_all(args.records)

if __name__ == "__main__":
    main()
