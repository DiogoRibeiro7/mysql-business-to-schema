#!/usr/bin/env python3
"""
IoT Waste Management System Data Generator - Refactored with BaseGenerator
Generates realistic data for smart garbage bin monitoring with IoT sensors
"""

import sys
import os
import csv
import json
import random
import hashlib
from datetime import datetime, timedelta, time
from decimal import Decimal
from pathlib import Path
from typing import List, Dict, Any, Tuple
import yaml
import argparse

# Add parent directory to path to import base_generator
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from base_generator import BaseGenerator

from faker import Faker
import numpy as np
import math


class IoTBinsGenerator(BaseGenerator):
    """IoT Waste Management Data Generator using BaseGenerator infrastructure"""

    def __init__(self, config_path: str = "config.yaml", **db_params):
        """Initialize the generator with configuration and database connection"""
        # Initialize base class with database connection parameters
        super().__init__(**db_params)

        # Additional setup
        self.fake = self.faker  # Use the faker from base class
        np.random.seed(42)

        # Load configuration
        if os.path.exists(config_path):
            with open(config_path, "r") as f:
                self.config = yaml.safe_load(f)
        else:
            self.config = self.get_default_config()

        # Data storage
        self.districts: List[Any] = []
        self.bins: List[Any] = []
        self.sensors: List[Any] = []
        self.routes: List[Any] = []
        self.route_assignments: List[Any] = []
        self.trucks: List[Any] = []
        self.drivers: List[Any] = []
        self.schedules: List[Any] = []
        self.collection_events: List[Any] = []
        self.sensor_readings: List[Any] = []
        self.alerts: List[Any] = []
        self.alert_thresholds: List[Any] = []
        self.predictions: List[Any] = []

        # Counters
        self.assignment_id = 0
        self.schedule_id = 0
        self.event_id = 0
        self.reading_id = 0
        self.alert_id = 0
        self.threshold_id = 0
        self.prediction_id = 0

        # Start date for historical data
        self.start_date = datetime.now() - timedelta(
            days=self.config["days_of_history"]
        )

    def get_default_config(self) -> dict:
        """Return default configuration"""
        return {
            "districts": 12,
            "bins_per_district": 100,
            "sensors_per_bin": 3,
            "trucks": 25,
            "drivers": 40,
            "routes_per_district": 5,
            "days_of_history": 90,
            "readings_per_day_per_sensor": 288,  # Every 5 minutes
            "collection_frequency_days": 3,
            "batch_size": 5000,  # For bulk inserts
            "clear_existing_data": False,
        }

    def generate_districts(self):
        """Generate city districts"""
        print(f"Generating {self.config['districts']} districts...")

        district_names = [
            "Downtown",
            "North End",
            "South Side",
            "East Borough",
            "West Village",
            "Central Business",
            "Industrial Zone",
            "Riverside",
            "University Area",
            "Tech Park",
            "Old Town",
            "Harbor District",
        ]

        for i in range(self.config["districts"]):
            district = {
                "district_id": i + 1,
                "district_code": f"D{str(i+1).zfill(3)}",
                "name": (
                    district_names[i] if i < len(district_names) else f"District {i+1}"
                ),
                "area_km2": round(random.uniform(5, 50), 2),
                "population": random.randint(10000, 100000),
                "created_at": self.fake.date_time_between(
                    start_date="-2y", end_date="-1y"
                ),
                "updated_at": self.fake.date_time_between(
                    start_date="-30d", end_date="now"
                ),
            }
            self.districts.append(district)

    def generate_bins(self):
        """Generate smart garbage bins"""
        total_bins = self.config["districts"] * self.config["bins_per_district"]
        print(f"Generating {total_bins} bins...")

        bin_types_weights = {
            "general": 40,
            "recycling": 25,
            "organic": 15,
            "paper": 10,
            "plastic": 5,
            "glass": 3,
            "hazardous": 2,
        }
        bin_types = list(bin_types_weights.keys())
        weights = list(bin_types_weights.values())

        location_types = [
            "residential",
            "commercial",
            "industrial",
            "park",
            "school",
            "hospital",
            "public",
        ]
        location_weights = [35, 25, 10, 10, 8, 7, 5]

        bin_id = 0
        for district in self.districts:
            # Generate base coordinates for district
            base_lat = 40.7128 + random.uniform(-0.1, 0.1)
            base_lon = -74.0060 + random.uniform(-0.1, 0.1)

            for _ in range(self.config["bins_per_district"]):
                bin_id += 1
                bin_type = random.choices(bin_types, weights=weights)[0]

                # Capacity based on bin type
                capacity_ranges = {
                    "general": (500, 1500),
                    "recycling": (400, 1000),
                    "organic": (300, 800),
                    "paper": (500, 1200),
                    "plastic": (400, 1000),
                    "glass": (300, 700),
                    "hazardous": (100, 400),
                }
                capacity = random.randint(*capacity_ranges[bin_type])

                bin_data = {
                    "bin_id": bin_id,
                    "district_id": district["district_id"],
                    "bin_code": f"BIN{district['district_code']}{str(bin_id).zfill(4)}",
                    "bin_type": bin_type,
                    "capacity_liters": capacity,
                    "latitude": base_lat + random.uniform(-0.01, 0.01),
                    "longitude": base_lon + random.uniform(-0.01, 0.01),
                    "location_type": random.choices(
                        location_types, weights=location_weights
                    )[0],
                    "address": self.fake.street_address(),
                    "installation_date": self.fake.date_between(
                        start_date="-3y", end_date="-6m"
                    ),
                    "last_maintenance": self.fake.date_between(
                        start_date="-3m", end_date="today"
                    ),
                    "is_active": 1 if random.random() > 0.05 else 0,  # 95% active
                    "created_at": self.fake.date_time_between(
                        start_date="-3y", end_date="-2y"
                    ),
                    "updated_at": self.fake.date_time_between(
                        start_date="-7d", end_date="now"
                    ),
                }
                self.bins.append(bin_data)

    def generate_sensors(self):
        """Generate sensors for bins"""
        sensor_types = ["fill_level", "temperature", "battery"]
        sensor_id = 0

        for bin_data in self.bins:
            for sensor_type in sensor_types[: self.config["sensors_per_bin"]]:
                sensor_id += 1
                sensor = {
                    "sensor_id": sensor_id,
                    "bin_id": bin_data["bin_id"],
                    "sensor_type": sensor_type,
                    "sensor_code": f"SEN{str(sensor_id).zfill(6)}",
                    "manufacturer": random.choice(
                        ["SensorTech", "IoTDevices", "SmartSense", "TechMeasure"]
                    ),
                    "model": f"{sensor_type.upper()}-{random.choice(['100', '200', 'PRO', 'PLUS'])}",
                    "firmware_version": f"{random.randint(1,3)}.{random.randint(0,9)}.{random.randint(0,99)}",
                    "battery_capacity": (
                        5000
                        if sensor_type == "battery"
                        else random.choice([3000, 4000, 5000])
                    ),
                    "installation_date": bin_data["installation_date"],
                    "last_calibration": self.fake.date_between(
                        start_date="-2m", end_date="today"
                    ),
                    "is_active": bin_data["is_active"],
                    "created_at": bin_data["created_at"],
                    "updated_at": self.fake.date_time_between(
                        start_date="-24h", end_date="now"
                    ),
                }
                self.sensors.append(sensor)

    def generate_trucks(self):
        """Generate collection trucks"""
        print(f"Generating {self.config['trucks']} trucks...")

        truck_types = [
            "compactor",
            "recycling",
            "side_loader",
            "rear_loader",
            "front_loader",
        ]

        for i in range(self.config["trucks"]):
            truck = {
                "truck_id": i + 1,
                "registration_number": f"{self.fake.license_plate()}",
                "truck_type": random.choice(truck_types),
                "capacity_liters": random.choice([10000, 15000, 20000, 25000]),
                "fuel_type": random.choice(["diesel", "electric", "hybrid"]),
                "manufacture_year": random.randint(2018, 2024),
                "last_service_date": self.fake.date_between(
                    start_date="-3m", end_date="today"
                ),
                "next_service_date": self.fake.date_between(
                    start_date="today", end_date="+3m"
                ),
                "is_active": 1 if random.random() > 0.1 else 0,  # 90% active
                "created_at": self.fake.date_time_between(
                    start_date="-5y", end_date="-1y"
                ),
                "updated_at": self.fake.date_time_between(
                    start_date="-7d", end_date="now"
                ),
            }
            self.trucks.append(truck)

    def generate_drivers(self):
        """Generate drivers"""
        print(f"Generating {self.config['drivers']} drivers...")

        for i in range(self.config["drivers"]):
            driver = {
                "driver_id": i + 1,
                "employee_id": f"EMP{str(i+1).zfill(5)}",
                "first_name": self.fake.first_name(),
                "last_name": self.fake.last_name(),
                "phone": self.fake.phone_number(),
                "email": self.fake.email(),
                "license_number": f"DL{self.fake.random_int(10000000, 99999999)}",
                "license_expiry": self.fake.date_between(
                    start_date="+1y", end_date="+5y"
                ),
                "hire_date": self.fake.date_between(start_date="-10y", end_date="-1m"),
                "is_active": 1 if random.random() > 0.1 else 0,  # 90% active
                "created_at": self.fake.date_time_between(
                    start_date="-10y", end_date="-1m"
                ),
                "updated_at": self.fake.date_time_between(
                    start_date="-30d", end_date="now"
                ),
            }
            self.drivers.append(driver)

    def generate_routes(self):
        """Generate collection routes"""
        total_routes = self.config["districts"] * self.config["routes_per_district"]
        print(f"Generating {total_routes} routes...")

        route_id = 0
        for district in self.districts:
            district_bins = [
                b for b in self.bins if b["district_id"] == district["district_id"]
            ]

            for route_num in range(self.config["routes_per_district"]):
                route_id += 1
                route = {
                    "route_id": route_id,
                    "district_id": district["district_id"],
                    "route_code": f"R{district['district_code']}{str(route_num+1).zfill(2)}",
                    "name": f"{district['name']} Route {route_num+1}",
                    "total_distance_km": round(random.uniform(10, 50), 2),
                    "estimated_duration_minutes": random.randint(60, 240),
                    "is_active": 1,
                    "created_at": self.fake.date_time_between(
                        start_date="-2y", end_date="-1y"
                    ),
                    "updated_at": self.fake.date_time_between(
                        start_date="-30d", end_date="now"
                    ),
                }
                self.routes.append(route)

                # Assign bins to routes
                bins_per_route = (
                    len(district_bins) // self.config["routes_per_district"]
                )
                route_bins = random.sample(
                    district_bins, min(bins_per_route, len(district_bins))
                )

                for order, bin_data in enumerate(route_bins, 1):
                    self.assignment_id += 1
                    assignment = {
                        "assignment_id": self.assignment_id,
                        "route_id": route_id,
                        "bin_id": bin_data["bin_id"],
                        "collection_order": order,
                        "assigned_date": route["created_at"],
                        "is_active": 1,
                        "created_at": route["created_at"],
                        "updated_at": route["updated_at"],
                    }
                    self.route_assignments.append(assignment)

    def generate_sensor_readings_batch(self, batch_sensors, current_date):
        """Generate sensor readings for a batch of sensors"""
        readings = []

        for sensor in batch_sensors:
            # Generate readings for the day
            for hour in range(0, 24, 4):  # Every 4 hours for performance
                timestamp = datetime.combine(current_date, time(hour, 0))

                self.reading_id += 1

                # Generate realistic values based on sensor type
                if sensor["sensor_type"] == "fill_level":
                    # Simulate gradual filling with some variation
                    base_fill = 20 + (hour / 24) * 40 + random.gauss(0, 5)
                    value = max(0, min(100, base_fill))
                elif sensor["sensor_type"] == "temperature":
                    # Temperature varies by time of day
                    base_temp = 20 + 5 * math.sin((hour - 6) * math.pi / 12)
                    value = base_temp + random.gauss(0, 2)
                else:  # battery
                    # Battery slowly drains
                    value = max(0, 100 - (hour / 24) * 2 - random.uniform(0, 1))

                reading = (
                    self.reading_id,
                    sensor["sensor_id"],
                    timestamp,
                    round(value, 2),
                    1 if value > 0 else 0,  # is_valid
                    timestamp,
                )
                readings.append(reading)

        return readings

    def insert_data_to_database(self):
        """Insert generated data into database using bulk operations"""
        try:
            # Connect to database
            self.connect()

            # Clear existing data if configured
            if self.config.get("clear_existing_data", False):
                print("Clearing existing data...")
                self.truncate_all_tables()

            # Insert districts
            if self.districts:
                district_data = [tuple(d.values()) for d in self.districts]
                self.bulk_insert(
                    "districts", district_data, list(self.districts[0].keys())
                )
                print(f"Inserted {len(self.districts)} districts")

            # Insert bins
            if self.bins:
                bin_data = [tuple(b.values()) for b in self.bins]
                self.bulk_insert(
                    "bins",
                    bin_data,
                    list(self.bins[0].keys()),
                    batch_size=self.config.get("batch_size", 1000),
                )
                print(f"Inserted {len(self.bins)} bins")

            # Insert sensors
            if self.sensors:
                sensor_data = [tuple(s.values()) for s in self.sensors]
                self.bulk_insert(
                    "sensors",
                    sensor_data,
                    list(self.sensors[0].keys()),
                    batch_size=self.config.get("batch_size", 1000),
                )
                print(f"Inserted {len(self.sensors)} sensors")

            # Insert trucks
            if self.trucks:
                truck_data = [tuple(t.values()) for t in self.trucks]
                self.bulk_insert("trucks", truck_data, list(self.trucks[0].keys()))
                print(f"Inserted {len(self.trucks)} trucks")

            # Insert drivers
            if self.drivers:
                driver_data = [tuple(d.values()) for d in self.drivers]
                self.bulk_insert("drivers", driver_data, list(self.drivers[0].keys()))
                print(f"Inserted {len(self.drivers)} drivers")

            # Insert routes
            if self.routes:
                route_data = [tuple(r.values()) for r in self.routes]
                self.bulk_insert("routes", route_data, list(self.routes[0].keys()))
                print(f"Inserted {len(self.routes)} routes")

            # Insert route assignments
            if self.route_assignments:
                assignment_data = [tuple(a.values()) for a in self.route_assignments]
                self.bulk_insert(
                    "route_bin_assignments",
                    assignment_data,
                    list(self.route_assignments[0].keys()),
                    batch_size=self.config.get("batch_size", 1000),
                )
                print(f"Inserted {len(self.route_assignments)} route assignments")

            # Generate and insert sensor readings in batches
            print("Generating and inserting sensor readings...")
            columns = [
                "reading_id",
                "sensor_id",
                "timestamp",
                "value",
                "is_valid",
                "created_at",
            ]

            # Process one day at a time to manage memory
            for day_offset in range(
                min(7, self.config["days_of_history"])
            ):  # Limit to 7 days for demo
                current_date = datetime.now().date() - timedelta(days=day_offset)
                print(f"  Processing {current_date}...")

                # Process sensors in batches
                batch_size = 100
                for i in range(0, len(self.sensors), batch_size):
                    batch_sensors = self.sensors[i : i + batch_size]
                    readings = self.generate_sensor_readings_batch(
                        batch_sensors, current_date
                    )

                    if readings:
                        self.bulk_insert(
                            "sensor_readings",
                            readings,
                            columns,
                            batch_size=self.config.get("batch_size", 5000),
                        )

                print(
                    f"    Generated {len(self.sensors) * 6} readings for {current_date}"
                )

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
        # Adjust configuration based on scale
        if scale == "small":
            self.config["districts"] = 3
            self.config["bins_per_district"] = 20
            self.config["days_of_history"] = 7
        elif scale == "medium":
            self.config["districts"] = 6
            self.config["bins_per_district"] = 50
            self.config["days_of_history"] = 30
        else:  # large
            self.config["districts"] = 12
            self.config["bins_per_district"] = 100
            self.config["days_of_history"] = 90

        print(f"\nGenerating {scale} scale data for IoT bins database...")
        print("=" * 60)
        print(f"Configuration:")
        print(f"  Districts: {self.config['districts']}")
        print(f"  Bins per district: {self.config['bins_per_district']}")
        print(
            f"  Total bins: {self.config['districts'] * self.config['bins_per_district']}"
        )
        print(f"  Days of history: {self.config['days_of_history']}")
        print("=" * 60)

        # Generate all data
        self.generate_districts()
        self.generate_bins()
        self.generate_sensors()
        self.generate_trucks()
        self.generate_drivers()
        self.generate_routes()

        print(f"\nGeneration Summary:")
        print(f"  Districts: {len(self.districts)}")
        print(f"  Bins: {len(self.bins)}")
        print(f"  Sensors: {len(self.sensors)}")
        print(f"  Trucks: {len(self.trucks)}")
        print(f"  Drivers: {len(self.drivers)}")
        print(f"  Routes: {len(self.routes)}")
        print(f"  Route Assignments: {len(self.route_assignments)}")

        return {
            "districts": self.districts,
            "bins": self.bins,
            "sensors": self.sensors,
            "trucks": self.trucks,
            "drivers": self.drivers,
            "routes": self.routes,
            "route_assignments": self.route_assignments,
        }

    def export_to_json(self, filename: str):
        """Export generated data to JSON file"""
        data = self.generate_data()
        with open(filename, "w") as f:
            json.dump(data, f, indent=2, default=str)
        print(f"\nData exported to {filename}")


def main():
    parser = argparse.ArgumentParser(description="Generate IoT Bins sample data")
    parser.add_argument(
        "--scale",
        choices=["small", "medium", "large"],
        default="small",
        help="Scale of data to generate",
    )
    parser.add_argument(
        "--format",
        choices=["database", "json", "csv"],
        default="database",
        help="Output format",
    )
    parser.add_argument("--config", default="config.yaml", help="Configuration file")

    # Database connection parameters
    parser.add_argument("--host", default="localhost", help="Database host")
    parser.add_argument("--port", type=int, default=3306, help="Database port")
    parser.add_argument("--user", default="root", help="Database user")
    parser.add_argument("--password", default="password", help="Database password")
    parser.add_argument(
        "--database", default="iot_waste_management", help="Database name"
    )

    args = parser.parse_args()

    # Create generator with database parameters
    generator = IoTBinsGenerator(
        config_path=args.config,
        host=args.host,
        port=args.port,
        user=args.user,
        password=args.password,
        database=args.database,
    )

    # Generate data
    if args.format == "database":
        # Generate and insert directly into database
        generator.generate_data(args.scale)
        generator.insert_data_to_database()
    elif args.format == "json":
        # Export to JSON
        generator.export_to_json(f"iot_bins_data_{args.scale}.json")
    else:  # csv
        # Generate data and save to CSV (not fully implemented in this example)
        data = generator.generate_data(args.scale)
        print("CSV export not yet implemented in refactored version")

    print("\n[DONE] IoT Bins data generation complete!")


if __name__ == "__main__":
    main()
