#!/usr/bin/env python3
"""
Generate data for remaining schemas
Covers: smart_energy, industrial_iot, smart_agriculture, fleet_management,
        healthcare_iot, streaming_ml, event_ticketing, cryptocurrency
"""

import os
import sys
import json
import random
from datetime import datetime, timedelta
from faker import Faker
from typing import List, Dict

# Fix encoding for Windows
if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

fake = Faker()

class RemainingSchemaGenerator:
    """Generate data for remaining business schemas"""

    def __init__(self, output_dir: str = "demo_data"):
        self.output_dir = output_dir
        os.makedirs(output_dir, exist_ok=True)
        self.fake = Faker()

    def escape_sql(self, value):
        """Escape SQL special characters"""
        if value is None:
            return 'NULL'
        return str(value).replace("'", "''").replace("\\", "\\\\")

    def generate_smart_energy_data(self, count: int = 100):
        """Generate smart energy/utility data"""
        print("Generating smart energy data...")

        sql_lines = [
            "-- Demo data for smart_energy_db",
            "USE smart_energy_db;",
            "",
            "SET FOREIGN_KEY_CHECKS = 0;",
            "TRUNCATE TABLE meters;",
            "TRUNCATE TABLE readings;",
            "TRUNCATE TABLE customers;",
            "TRUNCATE TABLE billing;",
            "SET FOREIGN_KEY_CHECKS = 1;",
            "",
            "-- Insert meters",
            "INSERT INTO meters (meter_id, customer_id, meter_type, installation_date, location, status) VALUES"
        ]

        # Generate meters
        meter_values = []
        meter_types = ['electricity', 'gas', 'water', 'solar']
        for i in range(count):
            meter = (
                f"('MTR{i+1:08d}', 'CUST{random.randint(1, count):06d}', "
                f"'{random.choice(meter_types)}', "
                f"'{fake.date_between(start_date='-5y', end_date='-1m')}', "
                f"'{self.escape_sql(fake.address()[:255])}', "
                f"'{random.choice(['active', 'inactive', 'maintenance'])}')"
            )
            meter_values.append(meter)

        sql_lines.append(',\n'.join(meter_values) + ';')

        # Generate readings
        sql_lines.append("\n-- Insert meter readings")
        sql_lines.append("INSERT INTO readings (meter_id, timestamp, value, unit, tariff_rate) VALUES")

        reading_values = []
        for i in range(count * 10):  # 10 readings per meter
            reading = (
                f"('MTR{random.randint(1, count):08d}', "
                f"'{fake.date_time_between(start_date='-30d', end_date='now')}', "
                f"{round(random.uniform(0, 1000), 2)}, "
                f"'{random.choice(['kWh', 'm3', 'gallons'])}', "
                f"{round(random.uniform(0.05, 0.30), 3)})"
            )
            reading_values.append(reading)

        sql_lines.append(',\n'.join(reading_values) + ';')

        # Save file
        output_file = os.path.join(self.output_dir, 'smart_energy_db_data.sql')
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write('\n'.join(sql_lines))

        print(f"  Created: {output_file} ({count} meters, {count*10} readings)")
        return output_file

    def generate_industrial_iot_data(self, count: int = 100):
        """Generate industrial IoT data"""
        print("Generating industrial IoT data...")

        sql_lines = [
            "-- Demo data for industrial_iot_db",
            "USE industrial_iot_db;",
            "",
            "SET FOREIGN_KEY_CHECKS = 0;",
            "TRUNCATE TABLE equipment;",
            "TRUNCATE TABLE sensors;",
            "TRUNCATE TABLE production_metrics;",
            "TRUNCATE TABLE maintenance_logs;",
            "SET FOREIGN_KEY_CHECKS = 1;",
            "",
            "-- Insert equipment",
            "INSERT INTO equipment (equipment_id, name, type, manufacturer, model, location, status, last_maintenance) VALUES"
        ]

        # Generate equipment
        equipment_values = []
        equipment_types = ['CNC Machine', 'Conveyor', 'Robot Arm', 'Press', 'Furnace', 'Packaging Machine']
        for i in range(count // 2):
            equipment = (
                f"('EQP{i+1:06d}', 'Equipment-{fake.word().upper()}-{i+1}', "
                f"'{random.choice(equipment_types)}', "
                f"'{self.escape_sql(fake.company())}', "
                f"'Model-{random.randint(1000, 9999)}', "
                f"'Zone-{random.choice(['A', 'B', 'C', 'D'])}', "
                f"'{random.choice(['operational', 'maintenance', 'idle'])}', "
                f"'{fake.date_between(start_date='-90d', end_date='today')}')"
            )
            equipment_values.append(equipment)

        sql_lines.append(',\n'.join(equipment_values) + ';')

        # Generate production metrics
        sql_lines.append("\n-- Insert production metrics")
        sql_lines.append("INSERT INTO production_metrics (equipment_id, timestamp, units_produced, efficiency, quality_score, downtime_minutes) VALUES")

        metric_values = []
        for i in range(count * 5):
            metric = (
                f"('EQP{random.randint(1, count//2):06d}', "
                f"'{fake.date_time_between(start_date='-7d', end_date='now')}', "
                f"{random.randint(100, 10000)}, "
                f"{round(random.uniform(70, 99), 1)}, "
                f"{round(random.uniform(85, 100), 1)}, "
                f"{random.randint(0, 120)})"
            )
            metric_values.append(metric)

        sql_lines.append(',\n'.join(metric_values) + ';')

        # Save file
        output_file = os.path.join(self.output_dir, 'industrial_iot_db_data.sql')
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write('\n'.join(sql_lines))

        print(f"  Created: {output_file} ({count//2} equipment, {count*5} metrics)")
        return output_file

    def generate_smart_agriculture_data(self, count: int = 100):
        """Generate smart agriculture data"""
        print("Generating smart agriculture data...")

        sql_lines = [
            "-- Demo data for smart_agriculture_db",
            "USE smart_agriculture_db;",
            "",
            "SET FOREIGN_KEY_CHECKS = 0;",
            "TRUNCATE TABLE farms;",
            "TRUNCATE TABLE fields;",
            "TRUNCATE TABLE sensors;",
            "TRUNCATE TABLE crop_data;",
            "SET FOREIGN_KEY_CHECKS = 1;",
            "",
            "-- Insert farms",
            "INSERT INTO farms (farm_id, name, owner, location, total_area_hectares, established_date) VALUES"
        ]

        # Generate farms
        farm_values = []
        for i in range(20):  # 20 farms
            farm = (
                f"({i+1}, '{fake.last_name()} Farm', "
                f"'{self.escape_sql(fake.name())}', "
                f"'{self.escape_sql(fake.address()[:255])}', "
                f"{round(random.uniform(10, 500), 2)}, "
                f"'{fake.date_between(start_date='-20y', end_date='-1y')}')"
            )
            farm_values.append(farm)

        sql_lines.append(',\n'.join(farm_values) + ';')

        # Generate fields
        sql_lines.append("\n-- Insert fields")
        sql_lines.append("INSERT INTO fields (field_id, farm_id, name, area_hectares, crop_type, planting_date, harvest_date) VALUES")

        field_values = []
        crop_types = ['Wheat', 'Corn', 'Soybeans', 'Rice', 'Cotton', 'Barley', 'Potatoes']
        for i in range(count):
            planting = fake.date_between(start_date='-6m', end_date='-2m')
            harvest = planting + timedelta(days=random.randint(90, 180))
            field = (
                f"({i+1}, {random.randint(1, 20)}, "
                f"'Field-{random.choice(['North', 'South', 'East', 'West'])}-{i+1}', "
                f"{round(random.uniform(1, 50), 2)}, "
                f"'{random.choice(crop_types)}', "
                f"'{planting}', "
                f"'{harvest if harvest <= datetime.now().date() else 'NULL'}')"
            )
            field_values.append(field)

        sql_lines.append(',\n'.join(field_values) + ';')

        # Save file
        output_file = os.path.join(self.output_dir, 'smart_agriculture_db_data.sql')
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write('\n'.join(sql_lines))

        print(f"  Created: {output_file} (20 farms, {count} fields)")
        return output_file

    def generate_fleet_management_data(self, count: int = 100):
        """Generate fleet management data"""
        print("Generating fleet management data...")

        sql_lines = [
            "-- Demo data for fleet_management_db",
            "USE fleet_management_db;",
            "",
            "SET FOREIGN_KEY_CHECKS = 0;",
            "TRUNCATE TABLE vehicles;",
            "TRUNCATE TABLE drivers;",
            "TRUNCATE TABLE trips;",
            "TRUNCATE TABLE maintenance;",
            "SET FOREIGN_KEY_CHECKS = 1;",
            "",
            "-- Insert vehicles",
            "INSERT INTO vehicles (vehicle_id, plate_number, make, model, year, type, fuel_type, mileage, status) VALUES"
        ]

        # Generate vehicles
        vehicle_values = []
        vehicle_types = ['Truck', 'Van', 'Car', 'Bus', 'Motorcycle']
        fuel_types = ['Gasoline', 'Diesel', 'Electric', 'Hybrid']
        makes = ['Ford', 'Toyota', 'Mercedes', 'Volvo', 'Tesla']

        for i in range(count):
            vehicle = (
                f"('VEH{i+1:06d}', '{fake.license_plate()}', "
                f"'{random.choice(makes)}', 'Model-{fake.word().title()}', "
                f"{random.randint(2015, 2024)}, "
                f"'{random.choice(vehicle_types)}', "
                f"'{random.choice(fuel_types)}', "
                f"{random.randint(0, 200000)}, "
                f"'{random.choice(['active', 'maintenance', 'inactive'])}')"
            )
            vehicle_values.append(vehicle)

        sql_lines.append(',\n'.join(vehicle_values) + ';')

        # Generate drivers
        sql_lines.append("\n-- Insert drivers")
        sql_lines.append("INSERT INTO drivers (driver_id, first_name, last_name, license_number, phone, hire_date, status) VALUES")

        driver_values = []
        for i in range(count // 2):
            driver = (
                f"('DRV{i+1:05d}', '{self.escape_sql(fake.first_name())}', "
                f"'{self.escape_sql(fake.last_name())}', "
                f"'DL{random.randint(10000000, 99999999)}', "
                f"'{fake.phone_number()[:20]}', "
                f"'{fake.date_between(start_date='-5y', end_date='today')}', "
                f"'{random.choice(['active', 'on_leave', 'terminated'])}')"
            )
            driver_values.append(driver)

        sql_lines.append(',\n'.join(driver_values) + ';')

        # Generate trips
        sql_lines.append("\n-- Insert trips")
        sql_lines.append("INSERT INTO trips (trip_id, vehicle_id, driver_id, start_location, end_location, start_time, end_time, distance_km, fuel_consumed) VALUES")

        trip_values = []
        for i in range(count * 3):
            start_time = fake.date_time_between(start_date='-30d', end_date='now')
            end_time = start_time + timedelta(hours=random.randint(1, 12))
            distance = round(random.uniform(10, 500), 1)

            trip = (
                f"('TRP{i+1:08d}', 'VEH{random.randint(1, count):06d}', "
                f"'DRV{random.randint(1, count//2):05d}', "
                f"'{self.escape_sql(fake.city())}', "
                f"'{self.escape_sql(fake.city())}', "
                f"'{start_time}', '{end_time}', "
                f"{distance}, "
                f"{round(distance * random.uniform(0.05, 0.15), 2)})"
            )
            trip_values.append(trip)

        sql_lines.append(',\n'.join(trip_values) + ';')

        # Save file
        output_file = os.path.join(self.output_dir, 'fleet_management_db_data.sql')
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write('\n'.join(sql_lines))

        print(f"  Created: {output_file} ({count} vehicles, {count//2} drivers, {count*3} trips)")
        return output_file

    def generate_healthcare_iot_data(self, count: int = 100):
        """Generate healthcare IoT data"""
        print("Generating healthcare IoT data...")

        sql_lines = [
            "-- Demo data for healthcare_iot_db",
            "USE healthcare_iot_db;",
            "",
            "SET FOREIGN_KEY_CHECKS = 0;",
            "TRUNCATE TABLE patients;",
            "TRUNCATE TABLE devices;",
            "TRUNCATE TABLE vital_readings;",
            "TRUNCATE TABLE alerts;",
            "SET FOREIGN_KEY_CHECKS = 1;",
            "",
            "-- Insert patients",
            "INSERT INTO patients (patient_id, first_name, last_name, date_of_birth, medical_record_number, primary_condition) VALUES"
        ]

        # Generate patients
        patient_values = []
        conditions = ['Diabetes', 'Hypertension', 'Heart Disease', 'COPD', 'Asthma', 'Post-Surgery']

        for i in range(count):
            patient = (
                f"('PAT{i+1:06d}', '{self.escape_sql(fake.first_name())}', "
                f"'{self.escape_sql(fake.last_name())}', "
                f"'{fake.date_of_birth(minimum_age=30, maximum_age=85)}', "
                f"'MRN{random.randint(100000, 999999)}', "
                f"'{random.choice(conditions)}')"
            )
            patient_values.append(patient)

        sql_lines.append(',\n'.join(patient_values) + ';')

        # Generate devices
        sql_lines.append("\n-- Insert medical devices")
        sql_lines.append("INSERT INTO devices (device_id, device_type, manufacturer, model, patient_id, assigned_date) VALUES")

        device_values = []
        device_types = ['Heart Rate Monitor', 'Blood Pressure Monitor', 'Glucose Monitor', 'Pulse Oximeter', 'ECG Monitor']

        for i in range(count * 2):  # 2 devices per patient average
            device = (
                f"('DEV{i+1:08d}', '{random.choice(device_types)}', "
                f"'{self.escape_sql(fake.company())}', "
                f"'Model-{random.randint(100, 999)}', "
                f"'PAT{random.randint(1, count):06d}', "
                f"'{fake.date_between(start_date='-1y', end_date='today')}')"
            )
            device_values.append(device)

        sql_lines.append(',\n'.join(device_values) + ';')

        # Generate vital readings
        sql_lines.append("\n-- Insert vital readings")
        sql_lines.append("INSERT INTO vital_readings (device_id, timestamp, heart_rate, blood_pressure_systolic, blood_pressure_diastolic, glucose_level, oxygen_saturation, temperature) VALUES")

        reading_values = []
        for i in range(count * 10):  # Many readings
            reading = (
                f"('DEV{random.randint(1, count*2):08d}', "
                f"'{fake.date_time_between(start_date='-7d', end_date='now')}', "
                f"{random.randint(60, 100) if random.random() > 0.3 else 'NULL'}, "
                f"{random.randint(100, 160) if random.random() > 0.3 else 'NULL'}, "
                f"{random.randint(60, 100) if random.random() > 0.3 else 'NULL'}, "
                f"{random.randint(70, 200) if random.random() > 0.5 else 'NULL'}, "
                f"{random.randint(92, 100) if random.random() > 0.3 else 'NULL'}, "
                f"{round(random.uniform(96.5, 99.5), 1) if random.random() > 0.5 else 'NULL'})"
            )
            reading_values.append(reading)

        sql_lines.append(',\n'.join(reading_values) + ';')

        # Save file
        output_file = os.path.join(self.output_dir, 'healthcare_iot_db_data.sql')
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write('\n'.join(sql_lines))

        print(f"  Created: {output_file} ({count} patients, {count*2} devices, {count*10} readings)")
        return output_file

    def generate_streaming_ml_data(self, count: int = 100):
        """Generate streaming ML platform data"""
        print("Generating streaming ML data...")

        sql_lines = [
            "-- Demo data for streaming_ml_db",
            "USE streaming_ml_db;",
            "",
            "SET FOREIGN_KEY_CHECKS = 0;",
            "TRUNCATE TABLE data_streams;",
            "TRUNCATE TABLE models;",
            "TRUNCATE TABLE predictions;",
            "TRUNCATE TABLE model_metrics;",
            "SET FOREIGN_KEY_CHECKS = 1;",
            "",
            "-- Insert data streams",
            "INSERT INTO data_streams (stream_id, name, source_type, schema_definition, created_at, status) VALUES"
        ]

        # Generate streams
        stream_values = []
        source_types = ['Kafka', 'Kinesis', 'PubSub', 'MQTT', 'WebSocket']

        for i in range(20):  # 20 streams
            stream = (
                f"('STREAM{i+1:03d}', 'Stream-{fake.word()}-{i+1}', "
                f"'{random.choice(source_types)}', "
                f"'{{\"fields\": [\"id\", \"timestamp\", \"value\"]}}', "
                f"'{fake.date_time_between(start_date='-6m', end_date='now')}', "
                f"'{random.choice(['active', 'paused', 'stopped'])}')"
            )
            stream_values.append(stream)

        sql_lines.append(',\n'.join(stream_values) + ';')

        # Generate models
        sql_lines.append("\n-- Insert ML models")
        sql_lines.append("INSERT INTO models (model_id, name, type, algorithm, version, accuracy, status, created_at) VALUES")

        model_values = []
        model_types = ['classification', 'regression', 'clustering', 'anomaly_detection', 'forecasting']
        algorithms = ['RandomForest', 'XGBoost', 'NeuralNetwork', 'LSTM', 'KMeans', 'IsolationForest']

        for i in range(count // 5):
            model = (
                f"('MODEL{i+1:04d}', 'Model-{fake.word()}-v{random.randint(1, 5)}', "
                f"'{random.choice(model_types)}', "
                f"'{random.choice(algorithms)}', "
                f"'{random.randint(1, 5)}.{random.randint(0, 9)}.{random.randint(0, 9)}', "
                f"{round(random.uniform(0.70, 0.99), 3)}, "
                f"'{random.choice(['deployed', 'testing', 'archived'])}', "
                f"'{fake.date_time_between(start_date='-1y', end_date='now')}')"
            )
            model_values.append(model)

        sql_lines.append(',\n'.join(model_values) + ';')

        # Generate predictions
        sql_lines.append("\n-- Insert predictions")
        sql_lines.append("INSERT INTO predictions (prediction_id, model_id, stream_id, input_data, prediction, confidence, timestamp) VALUES")

        prediction_values = []
        for i in range(count * 5):
            prediction = (
                f"('PRED{i+1:010d}', 'MODEL{random.randint(1, count//5):04d}', "
                f"'STREAM{random.randint(1, 20):03d}', "
                f"'{{\"value\": {random.uniform(0, 100):.2f}}}', "
                f"'{random.choice(['positive', 'negative', 'neutral']) if random.random() > 0.5 else round(random.uniform(0, 100), 2)}', "
                f"{round(random.uniform(0.5, 1.0), 3)}, "
                f"'{fake.date_time_between(start_date='-24h', end_date='now')}')"
            )
            prediction_values.append(prediction)

        sql_lines.append(',\n'.join(prediction_values) + ';')

        # Save file
        output_file = os.path.join(self.output_dir, 'streaming_ml_db_data.sql')
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write('\n'.join(sql_lines))

        print(f"  Created: {output_file} (20 streams, {count//5} models, {count*5} predictions)")
        return output_file

    def generate_event_ticketing_data(self, count: int = 100):
        """Generate event ticketing data"""
        print("Generating event ticketing data...")

        sql_lines = [
            "-- Demo data for event_ticketing_db",
            "USE event_ticketing_db;",
            "",
            "SET FOREIGN_KEY_CHECKS = 0;",
            "TRUNCATE TABLE venues;",
            "TRUNCATE TABLE events;",
            "TRUNCATE TABLE tickets;",
            "TRUNCATE TABLE bookings;",
            "SET FOREIGN_KEY_CHECKS = 1;",
            "",
            "-- Insert venues",
            "INSERT INTO venues (venue_id, name, address, city, capacity, type) VALUES"
        ]

        # Generate venues
        venue_values = []
        venue_types = ['Stadium', 'Theater', 'Arena', 'Convention Center', 'Club', 'Concert Hall']

        for i in range(30):  # 30 venues
            venue = (
                f"({i+1}, '{self.escape_sql(fake.company())} {random.choice(venue_types)}', "
                f"'{self.escape_sql(fake.street_address())}', '{fake.city()}', "
                f"{random.randint(100, 50000)}, "
                f"'{random.choice(venue_types)}')"
            )
            venue_values.append(venue)

        sql_lines.append(',\n'.join(venue_values) + ';')

        # Generate events
        sql_lines.append("\n-- Insert events")
        sql_lines.append("INSERT INTO events (event_id, name, venue_id, event_date, event_time, category, description, ticket_price) VALUES")

        event_values = []
        categories = ['Concert', 'Sports', 'Theater', 'Conference', 'Festival', 'Comedy']

        for i in range(count):
            event = (
                f"({i+1}, '{self.escape_sql(fake.catch_phrase())} Event', "
                f"{random.randint(1, 30)}, "
                f"'{fake.date_between(start_date='today', end_date='+6m')}', "
                f"'{random.randint(10, 22):02d}:{random.choice(['00', '30'])}:00', "
                f"'{random.choice(categories)}', "
                f"'{self.escape_sql(fake.text(max_nb_chars=200))}', "
                f"{round(random.uniform(20, 500), 2)})"
            )
            event_values.append(event)

        sql_lines.append(',\n'.join(event_values) + ';')

        # Save file
        output_file = os.path.join(self.output_dir, 'event_ticketing_db_data.sql')
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write('\n'.join(sql_lines))

        print(f"  Created: {output_file} (30 venues, {count} events)")
        return output_file

    def generate_cryptocurrency_data(self, count: int = 100):
        """Generate cryptocurrency exchange data"""
        print("Generating cryptocurrency data...")

        sql_lines = [
            "-- Demo data for cryptocurrency_db",
            "USE cryptocurrency_db;",
            "",
            "SET FOREIGN_KEY_CHECKS = 0;",
            "TRUNCATE TABLE wallets;",
            "TRUNCATE TABLE cryptocurrencies;",
            "TRUNCATE TABLE transactions;",
            "TRUNCATE TABLE market_data;",
            "SET FOREIGN_KEY_CHECKS = 1;",
            "",
            "-- Insert cryptocurrencies",
            "INSERT INTO cryptocurrencies (symbol, name, market_cap, current_price, volume_24h, circulating_supply) VALUES"
        ]

        # Generate cryptocurrencies
        crypto_values = []
        cryptos = [
            ('BTC', 'Bitcoin', 1000000000000, 45000, 30000000000, 19000000),
            ('ETH', 'Ethereum', 400000000000, 3000, 15000000000, 120000000),
            ('BNB', 'Binance Coin', 60000000000, 400, 2000000000, 150000000),
            ('ADA', 'Cardano', 15000000000, 0.45, 500000000, 35000000000),
            ('SOL', 'Solana', 20000000000, 60, 1000000000, 350000000),
            ('DOT', 'Polkadot', 10000000000, 8, 400000000, 1200000000),
            ('DOGE', 'Dogecoin', 12000000000, 0.08, 600000000, 140000000000),
            ('MATIC', 'Polygon', 8000000000, 0.9, 300000000, 9000000000),
            ('LINK', 'Chainlink', 7000000000, 15, 250000000, 500000000),
            ('AVAX', 'Avalanche', 9000000000, 25, 350000000, 350000000)
        ]

        for symbol, name, cap, price, volume, supply in cryptos:
            # Add some randomization
            price_var = price * random.uniform(0.8, 1.2)
            crypto = (
                f"('{symbol}', '{name}', {cap * random.uniform(0.8, 1.2):.0f}, "
                f"{price_var:.6f}, {volume * random.uniform(0.5, 1.5):.0f}, {supply})"
            )
            crypto_values.append(crypto)

        sql_lines.append(',\n'.join(crypto_values) + ';')

        # Generate wallets
        sql_lines.append("\n-- Insert wallets")
        sql_lines.append("INSERT INTO wallets (wallet_address, user_id, created_at, balance_btc, balance_eth, balance_usd) VALUES")

        wallet_values = []
        for i in range(count):
            wallet = (
                f"('0x{fake.sha256()[:40]}', 'USER{i+1:06d}', "
                f"'{fake.date_time_between(start_date='-2y', end_date='now')}', "
                f"{round(random.uniform(0, 10), 8)}, "
                f"{round(random.uniform(0, 100), 8)}, "
                f"{round(random.uniform(100, 100000), 2)})"
            )
            wallet_values.append(wallet)

        sql_lines.append(',\n'.join(wallet_values) + ';')

        # Generate transactions
        sql_lines.append("\n-- Insert transactions")
        sql_lines.append("INSERT INTO transactions (tx_hash, from_wallet, to_wallet, cryptocurrency, amount, fee, status, timestamp) VALUES")

        tx_values = []
        for i in range(count * 3):
            tx = (
                f"('0x{fake.sha256()}', "
                f"'0x{fake.sha256()[:40]}', '0x{fake.sha256()[:40]}', "
                f"'{random.choice([c[0] for c in cryptos])}', "
                f"{round(random.uniform(0.001, 100), 8)}, "
                f"{round(random.uniform(0.0001, 0.01), 6)}, "
                f"'{random.choice(['confirmed', 'pending', 'failed'])}', "
                f"'{fake.date_time_between(start_date='-30d', end_date='now')}')"
            )
            tx_values.append(tx)

        sql_lines.append(',\n'.join(tx_values) + ';')

        # Save file
        output_file = os.path.join(self.output_dir, 'cryptocurrency_db_data.sql')
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write('\n'.join(sql_lines))

        print(f"  Created: {output_file} (10 cryptos, {count} wallets, {count*3} transactions)")
        return output_file

    def generate_all_remaining(self, records_per_schema: int = 100):
        """Generate data for all remaining schemas"""
        print("\n" + "="*60)
        print("Generating Remaining Schema Data")
        print("="*60 + "\n")

        files_created = []

        # Generate all remaining schemas
        files_created.append(self.generate_smart_energy_data(records_per_schema))
        files_created.append(self.generate_industrial_iot_data(records_per_schema))
        files_created.append(self.generate_smart_agriculture_data(records_per_schema))
        files_created.append(self.generate_fleet_management_data(records_per_schema))
        files_created.append(self.generate_healthcare_iot_data(records_per_schema))
        files_created.append(self.generate_streaming_ml_data(records_per_schema))
        files_created.append(self.generate_event_ticketing_data(records_per_schema))
        files_created.append(self.generate_cryptocurrency_data(records_per_schema))

        # Create master import script for remaining schemas
        master_script = os.path.join(self.output_dir, 'import_remaining.sql')
        with open(master_script, 'w', encoding='utf-8') as f:
            f.write("-- Master import script for remaining schema data\n")
            f.write("-- Run this after creating the database schemas\n\n")
            for file in files_created:
                f.write(f"SOURCE {os.path.basename(file)};\n")

        print(f"\n  Created master script: {master_script}")

        # Create complete master import script
        complete_master = os.path.join(self.output_dir, 'import_complete.sql')
        with open(complete_master, 'w', encoding='utf-8') as f:
            f.write("-- Complete master import script for ALL 20 schemas\n")
            f.write("-- This imports all generated demo data\n\n")
            f.write("-- First batch (original 3)\n")
            f.write("SOURCE clinic_db_data.sql;\n")
            f.write("SOURCE ecommerce_db_data.sql;\n")
            f.write("SOURCE iot_bins_db_data.sql;\n\n")
            f.write("-- Second batch (additional 9)\n")
            f.write("SOURCE import_additional.sql;\n\n")
            f.write("-- Third batch (remaining 8)\n")
            f.write("SOURCE import_remaining.sql;\n")

        print(f"  Created complete master script: {complete_master}")

        print("\n" + "="*60)
        print("All Schema Data Generation Complete!")
        print("="*60)
        print("\nGenerated data for final 8 schemas:")
        for file in files_created:
            print(f"  - {os.path.basename(file)}")

        return files_created

def main():
    """Main execution"""
    import argparse

    parser = argparse.ArgumentParser(description='Generate remaining schema SQL data')
    parser.add_argument('--records', type=int, default=100,
                       help='Number of records per schema (default: 100)')
    parser.add_argument('--output', default='demo_data',
                       help='Output directory (default: demo_data)')

    args = parser.parse_args()

    generator = RemainingSchemaGenerator(args.output)
    generator.generate_all_remaining(args.records)

if __name__ == "__main__":
    main()