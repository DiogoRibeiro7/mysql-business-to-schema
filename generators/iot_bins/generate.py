#!/usr/bin/env python3
"""
IoT Garbage Bin Monitoring System - Data Generator

Generates realistic IoT sensor data for a smart city garbage collection system.
Includes sensor readings, collection events, alerts, and predictive patterns.
"""

import os
import sys
import random
import math
import csv
import yaml
import argparse
from datetime import datetime, timedelta, date, time
from typing import List, Dict, Tuple, Any
from pathlib import Path

# Add parent directory to path for shared utilities
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from faker import Faker


class IoTBinsGenerator:
    """Generates realistic IoT garbage bin monitoring data."""

    def __init__(self, config_path: str = "config.yaml"):
        """Initialize generator with configuration."""
        with open(config_path, "r") as f:
            self.config = yaml.safe_load(f)

        # Initialize Faker with seed
        self.fake = Faker("en_US")
        self.fake.seed_instance(self.config["seed"])
        random.seed(self.config["seed"])

        # Set up output directory
        self.output_dir = Path(self.config["output_dir"])
        self.output_dir.mkdir(parents=True, exist_ok=True)

        # Storage for generated entities
        self.districts = []
        self.bins = []
        self.sensors = []
        self.routes = []
        self.route_assignments = []
        self.trucks = []
        self.drivers = []
        self.schedules = []
        self.collection_events = []
        self.sensor_readings = []
        self.hourly_aggregates = []
        self.daily_aggregates = []
        self.alert_thresholds = []
        self.alerts = []

        # Parse dates
        self.start_date = datetime.strptime(
            self.config["date_ranges"]["historical_start"], "%Y-%m-%d"
        )
        self.end_date = datetime.strptime(
            self.config["date_ranges"]["historical_end"], "%Y-%m-%d"
        )

    def generate_all(self):
        """Generate all data for the IoT bins system."""
        print("Starting IoT Bins data generation...")

        # Infrastructure
        print("Generating infrastructure...")
        self.generate_districts()
        self.generate_bins()
        self.generate_sensors()

        # Collection Management
        print("Generating collection management...")
        self.generate_routes()
        self.generate_route_assignments()
        self.generate_trucks()
        self.generate_drivers()
        self.generate_schedules()
        self.generate_collection_events()

        # Sensor Data
        print("Generating sensor data (this may take a while)...")
        self.generate_sensor_readings()
        self.generate_aggregates()

        # Alerts
        print("Generating alerts...")
        self.generate_alert_thresholds()
        self.generate_alerts()

        # Save all data
        print("Saving data to CSV files...")
        self.save_all()

        print(f"Data generation complete! Files saved to {self.output_dir}")

    def generate_districts(self):
        """Generate city districts."""
        district_names = [
            "Downtown",
            "Northside",
            "Southside",
            "East End",
            "West End",
            "Harbor District",
            "University District",
            "Industrial Zone",
            "Old Town",
            "Business Park",
        ]

        for i in range(self.config["counts"]["districts"]):
            district = {
                "district_id": i + 1,
                "district_code": f"D{str(i + 1).zfill(3)}",
                "name": (
                    district_names[i]
                    if i < len(district_names)
                    else f"District {i + 1}"
                ),
                "area_km2": round(random.uniform(5, 25), 2),
                "population": random.randint(10000, 100000),
            }
            self.districts.append(district)

    def generate_bins(self):
        """Generate garbage bins with spatial distribution."""
        bin_types = list(self.config["distributions"]["bin_types"].keys())
        bin_type_weights = list(self.config["distributions"]["bin_types"].values())

        location_types = list(self.config["distributions"]["location_types"].keys())
        location_type_weights = list(
            self.config["distributions"]["location_types"].values()
        )

        capacities = {
            "general": [240, 360, 660, 1100],
            "recycling": [240, 360, 660],
            "organic": [120, 240],
            "paper": [240, 360],
            "glass": [240, 360],
            "plastic": [240, 360],
            "hazardous": [120],
        }

        center_lat = self.config["city_geography"]["center_lat"]
        center_lon = self.config["city_geography"]["center_lon"]
        radius_km = self.config["city_geography"]["radius_km"]

        for i in range(self.config["counts"]["bins"]):
            # Assign to district (distribute evenly with some randomness)
            district_id = (i % len(self.districts)) + 1
            if random.random() < 0.2:  # 20% chance to assign to random district
                district_id = random.randint(1, len(self.districts))

            bin_type = random.choices(bin_types, bin_type_weights)[0]
            location_type = random.choices(location_types, location_type_weights)[0]

            # Generate coordinates within radius
            angle = random.uniform(0, 2 * math.pi)
            distance = random.uniform(0, radius_km) * (1 / 111)  # Convert km to degrees
            lat = center_lat + distance * math.cos(angle)
            lon = center_lon + distance * math.sin(angle)

            # Installation date
            install_start = datetime.strptime(
                self.config["date_ranges"]["installation_start"], "%Y-%m-%d"
            )
            install_end = datetime.strptime(
                self.config["date_ranges"]["installation_end"], "%Y-%m-%d"
            )
            install_date = self.fake.date_between(install_start, install_end)

            bin_data = {
                "bin_id": i + 1,
                "bin_code": f"BIN-{str(i + 1).zfill(5)}",
                "district_id": district_id,
                "bin_type": bin_type,
                "capacity_liters": random.choice(capacities.get(bin_type, [240])),
                "latitude": round(lat, 8),
                "longitude": round(lon, 8),
                "address": self.fake.street_address(),
                "location_type": location_type,
                "installation_date": install_date,
                "last_maintenance_date": (
                    self.fake.date_between(install_date, self.end_date)
                    if random.random() < 0.3
                    else None
                ),
                "status": random.choices(
                    ["active", "maintenance", "damaged"], weights=[0.95, 0.04, 0.01]
                )[0],
            }
            self.bins.append(bin_data)

    def generate_sensors(self):
        """Generate sensors for each bin."""
        sensor_types = self.config["distributions"]["sensor_types"]
        manufacturers = ["SensorTech", "IoTDevices", "SmartSense", "EcoMonitor"]

        sensor_id = 1
        for bin_data in self.bins:
            if bin_data["status"] == "active":
                num_sensors = self.config["counts"]["sensors_per_bin"]
            else:
                num_sensors = random.randint(1, 3)  # Fewer sensors for non-active bins

            for sensor_type in sensor_types[:num_sensors]:
                manufacturer = random.choice(manufacturers)
                install_date = bin_data["installation_date"]

                # Battery level degrades over time
                days_since_install = (self.end_date.date() - install_date).days
                battery_level = max(
                    10, 100 - (days_since_install * 0.05) + random.uniform(-5, 5)
                )

                sensor = {
                    "sensor_id": sensor_id,
                    "sensor_code": f"SENS-{sensor_type[:4].upper()}-{str(sensor_id).zfill(6)}",
                    "bin_id": bin_data["bin_id"],
                    "sensor_type": sensor_type,
                    "manufacturer": manufacturer,
                    "model": f"{manufacturer}-{sensor_type[:3].upper()}-v{random.randint(1, 3)}",
                    "firmware_version": f"{random.randint(1, 3)}.{random.randint(0, 9)}.{random.randint(0, 99)}",
                    "installation_date": install_date,
                    "reading_frequency_seconds": self.config["sensor_parameters"][
                        "reading_frequency_seconds"
                    ],
                    "battery_level": round(battery_level, 2),
                    "last_reading_time": self.end_date.strftime("%Y-%m-%d %H:%M:%S"),
                    "status": (
                        random.choices(
                            ["active", "offline", "maintenance", "faulty"],
                            weights=[0.92, 0.04, 0.03, 0.01],
                        )[0]
                        if bin_data["status"] == "active"
                        else "offline"
                    ),
                }
                self.sensors.append(sensor)
                sensor_id += 1

    def generate_routes(self):
        """Generate collection routes."""
        route_types = ["regular", "express", "emergency", "special"]

        route_id = 1
        for district in self.districts:
            # Each district gets 2-4 routes
            num_routes = random.randint(2, 4)

            for j in range(num_routes):
                route = {
                    "route_id": route_id,
                    "route_code": f"R-{district['district_code']}-{str(j + 1).zfill(2)}",
                    "district_id": district["district_id"],
                    "route_name": f"{district['name']} Route {j + 1}",
                    "route_type": random.choices(
                        route_types, weights=[0.7, 0.15, 0.05, 0.1]
                    )[0],
                    "estimated_duration_minutes": random.randint(120, 300),
                    "estimated_distance_km": round(random.uniform(20, 80), 2),
                    "active": True if random.random() < 0.95 else False,
                }
                self.routes.append(route)
                route_id += 1

    def generate_route_assignments(self):
        """Assign bins to routes."""
        assignment_id = 1

        for route in self.routes:
            # Get bins in this district
            district_bins = [
                b
                for b in self.bins
                if b["district_id"] == route["district_id"] and b["status"] == "active"
            ]

            # Assign 20-40 bins per route
            num_bins = min(len(district_bins), random.randint(20, 40))
            selected_bins = random.sample(district_bins, num_bins)

            # Sort bins by proximity (simplified - just by coordinates)
            selected_bins.sort(key=lambda b: (b["latitude"], b["longitude"]))

            for order, bin_data in enumerate(selected_bins, 1):
                assignment = {
                    "assignment_id": assignment_id,
                    "route_id": route["route_id"],
                    "bin_id": bin_data["bin_id"],
                    "collection_order": order,
                    "estimated_collection_time": f"{6 + order // 10:02d}:{(order * 3) % 60:02d}:00",
                    "notes": None,
                }
                self.route_assignments.append(assignment)
                assignment_id += 1

    def generate_trucks(self):
        """Generate collection trucks."""
        manufacturers = ["Mercedes", "Volvo", "MAN", "Scania", "DAF"]
        fuel_types = list(self.config["distributions"]["truck_fuel_types"].keys())
        fuel_weights = list(self.config["distributions"]["truck_fuel_types"].values())

        for i in range(self.config["counts"]["trucks"]):
            manufacturer = random.choice(manufacturers)
            year = random.randint(2018, 2024)

            truck = {
                "truck_id": i + 1,
                "truck_code": f"TRK-{str(i + 1).zfill(3)}",
                "license_plate": self.fake.license_plate(),
                "manufacturer": manufacturer,
                "model": f"{manufacturer}-{random.choice(['Econic', 'FE', 'LF', 'P-Series'])}",
                "year": year,
                "capacity_kg": random.choice([5000, 7500, 10000, 12000]),
                "fuel_type": random.choices(fuel_types, fuel_weights)[0],
                "last_maintenance_date": self.fake.date_between(
                    date(2024, 6, 1), self.end_date.date()
                ),
                "next_maintenance_date": self.fake.date_between(
                    self.end_date.date(), date(2025, 6, 30)
                ),
                "odometer_km": random.randint(10000, 150000),
                "status": random.choices(
                    ["available", "in_use", "maintenance"], weights=[0.7, 0.25, 0.05]
                )[0],
            }
            self.trucks.append(truck)

    def generate_drivers(self):
        """Generate driver records."""
        for i in range(self.config["counts"]["drivers"]):
            first_name = self.fake.first_name()
            last_name = self.fake.last_name()

            driver = {
                "driver_id": i + 1,
                "employee_id": f"EMP-{str(i + 1).zfill(5)}",
                "first_name": first_name,
                "last_name": last_name,
                "email": f"{first_name.lower()}.{last_name.lower()}@wastecollection.com",
                "phone": self.fake.phone_number(),
                "license_number": f"DL-{self.fake.random_number(digits=8)}",
                "license_expiry_date": self.fake.date_between(
                    self.end_date.date(), date(2027, 12, 31)
                ),
                "hire_date": self.fake.date_between(
                    date(2015, 1, 1), date(2024, 12, 31)
                ),
                "status": random.choices(
                    ["active", "on_leave", "sick"], weights=[0.9, 0.08, 0.02]
                )[0],
            }
            self.drivers.append(driver)

    def generate_schedules(self):
        """Generate collection schedules."""
        schedule_id = 1
        current_date = self.start_date.date()

        while current_date <= self.end_date.date():
            # Skip Sundays
            if current_date.weekday() == 6:
                current_date += timedelta(days=1)
                continue

            # Schedule 60% of routes each day
            active_routes = [r for r in self.routes if r["active"]]
            num_routes_today = int(len(active_routes) * 0.6)
            scheduled_routes = random.sample(active_routes, num_routes_today)

            available_trucks = [t for t in self.trucks if t["status"] == "available"]
            available_drivers = [d for d in self.drivers if d["status"] == "active"]

            for route in scheduled_routes:
                if available_trucks and available_drivers:
                    truck = random.choice(available_trucks)
                    driver = random.choice(available_drivers)

                    start_hour = random.randint(5, 7)
                    duration_hours = route["estimated_duration_minutes"] // 60

                    schedule = {
                        "schedule_id": schedule_id,
                        "route_id": route["route_id"],
                        "truck_id": truck["truck_id"],
                        "driver_id": driver["driver_id"],
                        "scheduled_date": current_date,
                        "scheduled_start_time": f"{start_hour:02d}:00:00",
                        "scheduled_end_time": f"{start_hour + duration_hours:02d}:00:00",
                        "status": (
                            "completed"
                            if current_date < self.end_date.date()
                            else "scheduled"
                        ),
                        "actual_start_time": (
                            f"{current_date} {start_hour:02d}:{random.randint(0, 15):02d}:00"
                            if current_date < self.end_date.date()
                            else None
                        ),
                        "actual_end_time": (
                            f"{current_date} {start_hour + duration_hours:02d}:{random.randint(0, 30):02d}:00"
                            if current_date < self.end_date.date()
                            else None
                        ),
                        "notes": None,
                    }
                    self.schedules.append(schedule)
                    schedule_id += 1

            current_date += timedelta(days=1)

    def generate_collection_events(self):
        """Generate actual collection events based on schedules."""
        event_id = 1

        for schedule in self.schedules:
            if schedule["status"] != "completed":
                continue

            # Get bins on this route
            route_bins = [
                a
                for a in self.route_assignments
                if a["route_id"] == schedule["route_id"]
            ]

            for assignment in route_bins:
                # Skip some collections randomly (5% chance)
                if random.random() < 0.05:
                    continue

                bin_data = next(
                    b for b in self.bins if b["bin_id"] == assignment["bin_id"]
                )

                # Calculate collection time
                collection_time = datetime.strptime(
                    schedule["actual_start_time"], "%Y-%m-%d %H:%M:%S"
                )
                collection_time += timedelta(minutes=assignment["collection_order"] * 3)

                # Generate fill level based on location type
                location_type = bin_data["location_type"]
                if location_type in ["commercial", "industrial"]:
                    fill_level = random.uniform(60, 95)
                else:
                    fill_level = random.uniform(40, 85)

                # Calculate weight based on fill level and capacity
                weight_per_liter = 0.3  # kg per liter (average waste density)
                weight = (
                    (fill_level / 100) * bin_data["capacity_liters"] * weight_per_liter
                )

                event = {
                    "event_id": event_id,
                    "bin_id": assignment["bin_id"],
                    "schedule_id": schedule["schedule_id"],
                    "truck_id": schedule["truck_id"],
                    "driver_id": schedule["driver_id"],
                    "collected_at": collection_time.strftime("%Y-%m-%d %H:%M:%S"),
                    "fill_level_before": round(fill_level, 2),
                    "weight_kg": round(weight, 2),
                    "collection_duration_seconds": random.randint(30, 180),
                    "notes": None,
                }
                self.collection_events.append(event)
                event_id += 1

    def generate_fill_pattern(
        self, bin_data: Dict, sensor: Dict, current_time: datetime
    ) -> float:
        """Generate realistic fill level pattern."""
        location_type = bin_data["location_type"]
        hour = current_time.hour
        day_of_week = current_time.weekday()

        # Base fill rate patterns
        if location_type == "residential":
            if day_of_week < 5:  # Weekday
                base_rate = (
                    30 + 40 * math.sin((hour - 6) * math.pi / 12)
                    if 6 <= hour <= 22
                    else 20
                )
            else:  # Weekend
                base_rate = (
                    35 + 45 * math.sin((hour - 8) * math.pi / 14)
                    if 8 <= hour <= 22
                    else 25
                )
        elif location_type == "commercial":
            if day_of_week < 5:  # Weekday
                base_rate = 20 + 60 * (1 if 9 <= hour <= 18 else 0.2)
            else:  # Weekend
                base_rate = 15 + 20 * random.random()
        elif location_type == "industrial":
            if day_of_week < 5:  # Weekday
                base_rate = 40 + 50 * (1 if 6 <= hour <= 18 else 0.3)
            else:
                base_rate = 20
        else:  # public, park, school, hospital
            base_rate = (
                25 + 30 * math.sin((hour - 6) * math.pi / 16) if 6 <= hour <= 22 else 15
            )

        # Add noise and events
        noise = random.uniform(-5, 5)
        event_spike = 20 if random.random() < 0.02 else 0  # 2% chance of event

        # Find last collection
        last_collection = None
        for event in sorted(
            self.collection_events, key=lambda e: e["collected_at"], reverse=True
        ):
            if event["bin_id"] == bin_data["bin_id"] and event[
                "collected_at"
            ] < current_time.strftime("%Y-%m-%d %H:%M:%S"):
                last_collection = datetime.strptime(
                    event["collected_at"], "%Y-%m-%d %H:%M:%S"
                )
                break

        # Calculate gradual increase since last collection
        if last_collection:
            hours_since_collection = (
                current_time - last_collection
            ).total_seconds() / 3600
            gradual_increase = min(hours_since_collection * 0.5, 50)  # Max 50% increase
        else:
            gradual_increase = random.uniform(20, 60)

        fill_level = min(100, base_rate + noise + event_spike + gradual_increase)

        # Reset after collection
        if last_collection and (current_time - last_collection).total_seconds() < 3600:
            fill_level = random.uniform(0, 10)

        return max(0, fill_level)

    def generate_sensor_readings(self):
        """Generate time series sensor data."""
        reading_id = 1
        current_time = self.start_date

        # Generate readings for each time slot
        while current_time <= self.end_date:
            for sensor in self.sensors:
                if sensor["status"] != "active":
                    continue

                # Skip offline periods
                if (
                    random.random()
                    < self.config["sensor_parameters"]["offline_probability"]
                ):
                    continue

                bin_data = next(b for b in self.bins if b["bin_id"] == sensor["bin_id"])

                # Generate reading based on sensor type
                if sensor["sensor_type"] == "fill_level":
                    reading_value = self.generate_fill_pattern(
                        bin_data, sensor, current_time
                    )
                    unit = "percentage"
                elif sensor["sensor_type"] == "temperature":
                    # Temperature varies by time and season
                    month = current_time.month
                    if month in [12, 1, 2]:  # Winter
                        base_temp = self.config["sensor_parameters"]["temperature"][
                            "winter_mean"
                        ]
                        std = self.config["sensor_parameters"]["temperature"][
                            "winter_std"
                        ]
                    else:  # Summer/Spring/Fall
                        base_temp = self.config["sensor_parameters"]["temperature"][
                            "summer_mean"
                        ]
                        std = self.config["sensor_parameters"]["temperature"][
                            "summer_std"
                        ]
                    reading_value = random.gauss(base_temp, std)
                    unit = "celsius"
                elif sensor["sensor_type"] == "odor":
                    # Odor correlates with fill level and temperature
                    fill_sensor = next(
                        (
                            s
                            for s in self.sensors
                            if s["bin_id"] == sensor["bin_id"]
                            and s["sensor_type"] == "fill_level"
                        ),
                        None,
                    )
                    if fill_sensor:
                        fill_level = self.generate_fill_pattern(
                            bin_data, fill_sensor, current_time
                        )
                    else:
                        fill_level = 50
                    base_odor = self.config["sensor_parameters"]["odor"]["base_level"]
                    reading_value = (
                        base_odor
                        + (fill_level / 100)
                        * self.config["sensor_parameters"]["odor"]["filled_multiplier"]
                        * 20
                    )
                    unit = "ppm"
                elif sensor["sensor_type"] == "battery":
                    # Battery degrades over time
                    days_elapsed = (current_time - self.start_date).days
                    reading_value = max(
                        10,
                        sensor["battery_level"]
                        - days_elapsed
                        * self.config["sensor_parameters"][
                            "battery_degradation_per_day"
                        ],
                    )
                    unit = "percentage"
                else:
                    continue

                # Determine quality
                if (
                    random.random()
                    < self.config["sensor_parameters"]["error_reading_probability"]
                ):
                    quality = "error"
                    reading_value = -999  # Error value
                elif random.random() < 0.02:
                    quality = "warning"
                else:
                    quality = "good"

                reading = {
                    "reading_id": reading_id,
                    "sensor_id": sensor["sensor_id"],
                    "reading_time": current_time.strftime("%Y-%m-%d %H:%M:%S"),
                    "reading_value": round(reading_value, 3),
                    "unit": unit,
                    "quality": quality,
                }
                self.sensor_readings.append(reading)
                reading_id += 1

            # Move to next time slot (5 minutes)
            current_time += timedelta(minutes=5)

            # Limit total readings for performance
            if len(self.sensor_readings) > 1000000:
                print(
                    f"Generated {len(self.sensor_readings)} readings, stopping early for performance..."
                )
                break

    def generate_aggregates(self):
        """Generate hourly and daily aggregates from sensor readings."""
        # Group readings by sensor and hour
        from collections import defaultdict

        hourly_data = defaultdict(list)
        daily_data = defaultdict(list)

        for reading in self.sensor_readings:
            if reading["quality"] == "error":
                continue

            reading_time = datetime.strptime(
                reading["reading_time"], "%Y-%m-%d %H:%M:%S"
            )
            hour_key = (
                reading["sensor_id"],
                reading_time.strftime("%Y-%m-%d %H:00:00"),
            )
            day_key = (reading["sensor_id"], reading_time.strftime("%Y-%m-%d"))

            hourly_data[hour_key].append(reading)
            daily_data[day_key].append(reading)

        # Generate hourly aggregates
        aggregation_id = 1
        for (sensor_id, hour_start), readings in hourly_data.items():
            values = [r["reading_value"] for r in readings if r["quality"] != "error"]
            if not values:
                continue

            quality_counts = {"good": 0, "warning": 0, "error": 0}
            for r in readings:
                quality_counts[r["quality"]] += 1

            hourly = {
                "aggregation_id": aggregation_id,
                "sensor_id": sensor_id,
                "hour_start": hour_start,
                "min_value": round(min(values), 3),
                "max_value": round(max(values), 3),
                "avg_value": round(sum(values) / len(values), 3),
                "reading_count": len(readings),
                "quality_good_count": quality_counts["good"],
                "quality_warning_count": quality_counts["warning"],
                "quality_error_count": quality_counts["error"],
            }
            self.hourly_aggregates.append(hourly)
            aggregation_id += 1

        # Generate daily aggregates
        aggregation_id = 1
        for (sensor_id, date), readings in daily_data.items():
            values = [r["reading_value"] for r in readings if r["quality"] != "error"]
            if not values:
                continue

            # Find peak hour
            hourly_values = defaultdict(list)
            for r in readings:
                hour = datetime.strptime(r["reading_time"], "%Y-%m-%d %H:%M:%S").hour
                hourly_values[hour].append(r["reading_value"])

            peak_hour = max(
                hourly_values.keys(),
                key=lambda h: sum(hourly_values[h]) / len(hourly_values[h]),
            )
            peak_value = sum(hourly_values[peak_hour]) / len(hourly_values[peak_hour])

            total_readings = len(readings)
            quality_counts = {"good": 0, "warning": 0, "error": 0}
            for r in readings:
                quality_counts[r["quality"]] += 1

            daily = {
                "aggregation_id": aggregation_id,
                "sensor_id": sensor_id,
                "date": date,
                "min_value": round(min(values), 3),
                "max_value": round(max(values), 3),
                "avg_value": round(sum(values) / len(values), 3),
                "peak_hour": f"{peak_hour:02d}:00:00",
                "peak_value": round(peak_value, 3),
                "reading_count": total_readings,
                "quality_good_pct": round(
                    quality_counts["good"] / total_readings * 100, 2
                ),
                "quality_warning_pct": round(
                    quality_counts["warning"] / total_readings * 100, 2
                ),
                "quality_error_pct": round(
                    quality_counts["error"] / total_readings * 100, 2
                ),
            }
            self.daily_aggregates.append(daily)
            aggregation_id += 1

    def generate_alert_thresholds(self):
        """Generate alert threshold configurations."""
        threshold_configs = [
            {
                "name": "Fill Level Warning",
                "bin_type": "all",
                "sensor_type": "fill_level",
                "warning_value": 80,
                "critical_value": 90,
            },
            {
                "name": "Battery Low",
                "bin_type": "all",
                "sensor_type": "battery",
                "warning_value": 20,
                "critical_value": 10,
            },
            {
                "name": "Temperature High",
                "bin_type": "all",
                "sensor_type": "temperature",
                "warning_value": 35,
                "critical_value": 40,
            },
            {
                "name": "Odor High",
                "bin_type": "all",
                "sensor_type": "odor",
                "warning_value": 60,
                "critical_value": 80,
            },
            {
                "name": "Organic Bin Temperature",
                "bin_type": "organic",
                "sensor_type": "temperature",
                "warning_value": 30,
                "critical_value": 35,
            },
            {
                "name": "Hazardous Fill Critical",
                "bin_type": "hazardous",
                "sensor_type": "fill_level",
                "warning_value": 70,
                "critical_value": 85,
            },
        ]

        for i, config in enumerate(threshold_configs, 1):
            threshold = {
                "threshold_id": i,
                "name": config["name"],
                "bin_type": config["bin_type"],
                "sensor_type": config["sensor_type"],
                "warning_value": config["warning_value"],
                "critical_value": config["critical_value"],
                "check_interval_seconds": 300,
                "active": True,
            }
            self.alert_thresholds.append(threshold)

    def generate_alerts(self):
        """Generate alerts based on sensor readings and thresholds."""
        alert_id = 1

        # Sample sensor readings to generate alerts (use hourly aggregates for efficiency)
        for aggregate in self.hourly_aggregates[:1000]:  # Limit for performance
            sensor = next(
                (s for s in self.sensors if s["sensor_id"] == aggregate["sensor_id"]),
                None,
            )
            if not sensor:
                continue

            bin_data = next(
                (b for b in self.bins if b["bin_id"] == sensor["bin_id"]), None
            )
            if not bin_data:
                continue

            # Check thresholds
            for threshold in self.alert_thresholds:
                if threshold["sensor_type"] != sensor["sensor_type"]:
                    continue
                if (
                    threshold["bin_type"] != "all"
                    and threshold["bin_type"] != bin_data["bin_type"]
                ):
                    continue

                # Check if value exceeds threshold
                alert_type = None
                severity = None
                alert_value = aggregate["max_value"]

                if sensor["sensor_type"] == "fill_level":
                    if alert_value >= threshold["critical_value"]:
                        alert_type = "fill_critical"
                        severity = "critical"
                    elif alert_value >= threshold["warning_value"]:
                        alert_type = "fill_warning"
                        severity = "warning"
                elif sensor["sensor_type"] == "temperature":
                    if alert_value >= threshold["critical_value"]:
                        alert_type = "temperature_high"
                        severity = "critical"
                elif sensor["sensor_type"] == "battery":
                    if alert_value <= threshold["critical_value"]:
                        alert_type = "battery_low"
                        severity = "critical"
                elif sensor["sensor_type"] == "odor":
                    if alert_value >= threshold["critical_value"]:
                        alert_type = "odor_high"
                        severity = "warning"

                if alert_type and random.random() < 0.3:  # 30% chance to generate alert
                    triggered_at = datetime.strptime(
                        aggregate["hour_start"], "%Y-%m-%d %H:%M:%S"
                    )
                    triggered_at += timedelta(minutes=random.randint(0, 59))

                    # Resolve some alerts
                    resolved = random.random() < 0.7  # 70% resolved
                    resolved_at = None
                    if resolved:
                        resolved_at = triggered_at + timedelta(
                            hours=random.randint(1, 24)
                        )

                    alert = {
                        "alert_id": alert_id,
                        "bin_id": bin_data["bin_id"],
                        "sensor_id": sensor["sensor_id"],
                        "threshold_id": threshold["threshold_id"],
                        "alert_type": alert_type,
                        "severity": severity,
                        "triggered_at": triggered_at.strftime("%Y-%m-%d %H:%M:%S"),
                        "resolved_at": (
                            resolved_at.strftime("%Y-%m-%d %H:%M:%S")
                            if resolved_at
                            else None
                        ),
                        "alert_value": round(alert_value, 3),
                        "message": f"{alert_type.replace('_', ' ').title()} detected at {bin_data['bin_code']}",
                        "acknowledged": resolved,
                        "acknowledged_by": (
                            f"operator_{random.randint(1, 10)}" if resolved else None
                        ),
                        "acknowledged_at": (
                            (
                                triggered_at + timedelta(minutes=random.randint(5, 60))
                            ).strftime("%Y-%m-%d %H:%M:%S")
                            if resolved
                            else None
                        ),
                    }
                    self.alerts.append(alert)
                    alert_id += 1

    def save_all(self):
        """Save all generated data to CSV files."""
        datasets = [
            ("districts", self.districts),
            ("bins", self.bins),
            ("sensors", self.sensors),
            ("collection_routes", self.routes),
            ("route_bin_assignments", self.route_assignments),
            ("trucks", self.trucks),
            ("drivers", self.drivers),
            ("collection_schedules", self.schedules),
            ("collection_events", self.collection_events),
            ("sensor_readings", self.sensor_readings[:100000]),  # Limit for file size
            ("sensor_readings_hourly", self.hourly_aggregates),
            ("sensor_readings_daily", self.daily_aggregates),
            ("alert_thresholds", self.alert_thresholds),
            ("alerts", self.alerts),
        ]

        for filename, data in datasets:
            if not data:
                continue

            filepath = self.output_dir / f"{filename}.csv"
            with open(filepath, "w", newline="", encoding="utf-8") as f:
                writer = csv.DictWriter(f, fieldnames=data[0].keys())
                writer.writeheader()
                writer.writerows(data)

            print(f"  Saved {len(data)} records to {filename}.csv")


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description="Generate IoT Bins monitoring data")
    parser.add_argument(
        "--config", default="config.yaml", help="Configuration file path"
    )
    args = parser.parse_args()

    generator = IoTBinsGenerator(args.config)
    generator.generate_all()


if __name__ == "__main__":
    main()
