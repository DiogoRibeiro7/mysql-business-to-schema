#!/usr/bin/env python3
"""IoT Waste Management System Data Generator.

Generates realistic data for smart garbage bin monitoring with IoT sensors
"""

import csv
import random
from datetime import datetime, timedelta
from pathlib import Path
from faker import Faker
import numpy as np

from typing import Any, List

# Configuration
SEED = 42
OUTPUT_DIR = Path("output")
fake = Faker()
Faker.seed(SEED)
random.seed(SEED)
np.random.seed(SEED)

# Scale configuration
CONFIG = {
    "districts": 12,
    "bins_per_district": 100,
    "sensors_per_bin": 3,  # fill_level, temperature, battery typically
    "trucks": 25,
    "drivers": 40,
    "routes_per_district": 5,
    "days_of_history": 90,
    "readings_per_day_per_sensor": 288,  # Every 5 minutes
    "collection_frequency_days": 3,  # Average days between collections
}


class IoTBinsGenerator:
    """Represent IoTBinsGenerator."""

    def __init__(self):
        """Initialize the instance."""
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
        self.start_date = datetime.now() - timedelta(days=CONFIG["days_of_history"])

    def generate_all(self):
        """Generate all IoT bins data."""
        print("Starting IoT Waste Management Data Generation...")
        print("Configuration:")
        print(f"  Districts: {CONFIG['districts']}")
        print(f"  Total bins: {CONFIG['districts'] * CONFIG['bins_per_district']}")
        print(
            f"  Total sensors: {CONFIG['districts'] * CONFIG['bins_per_district'] * CONFIG['sensors_per_bin']}"
        )
        print(f"  Days of history: {CONFIG['days_of_history']}")

        # Core infrastructure
        self.generate_districts()
        self.generate_bins()
        self.generate_sensors()

        # Collection management
        self.generate_trucks()
        self.generate_drivers()
        self.generate_routes()
        self.generate_schedules_and_collections()

        # IoT data
        self.generate_alert_thresholds()
        self.generate_sensor_data()

        # Predictive analytics
        self.generate_predictions()

        # Save all data
        self.save_all()

    def generate_districts(self):
        """Generate city districts."""
        print(f"Generating {CONFIG['districts']} districts...")

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

        for i in range(CONFIG["districts"]):
            district = {
                "district_id": i + 1,
                "district_code": f"D{str(i+1).zfill(3)}",
                "name": (
                    district_names[i] if i < len(district_names) else f"District {i+1}"
                ),
                "area_km2": round(random.uniform(5, 50), 2),
                "population": random.randint(10000, 100000),
                "created_at": fake.date_time_between(start_date="-2y", end_date="-1y"),
                "updated_at": fake.date_time_between(start_date="-30d", end_date="now"),
            }
            self.districts.append(district)

    def generate_bins(self):
        """Generate smart garbage bins."""
        print(f"Generating {CONFIG['districts'] * CONFIG['bins_per_district']} bins...")

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

            for _ in range(CONFIG["bins_per_district"]):
                bin_id += 1
                bin_type = random.choices(bin_types, weights=weights)[0]

                # Capacity based on bin type
                capacity_ranges = {
                    "general": (500, 1500),
                    "recycling": (400, 1200),
                    "organic": (200, 600),
                    "paper": (300, 800),
                    "plastic": (300, 800),
                    "glass": (200, 500),
                    "hazardous": (100, 300),
                }
                capacity = random.randint(*capacity_ranges[bin_type])

                bin_data = {
                    "bin_id": bin_id,
                    "bin_code": f"BIN{district['district_code']}{str(bin_id).zfill(4)}",
                    "district_id": district["district_id"],
                    "bin_type": bin_type,
                    "capacity_liters": capacity,
                    "latitude": base_lat + random.uniform(-0.02, 0.02),
                    "longitude": base_lon + random.uniform(-0.02, 0.02),
                    "address": fake.street_address(),
                    "location_type": random.choices(
                        location_types, weights=location_weights
                    )[0],
                    "installation_date": fake.date_between(
                        start_date="-3y", end_date="-6m"
                    ),
                    "last_maintenance_date": fake.date_between(
                        start_date="-3m", end_date="today"
                    ),
                    "status": random.choices(
                        ["active", "maintenance", "damaged"], weights=[95, 4, 1]
                    )[0],
                    "created_at": fake.date_time_between(
                        start_date="-3y", end_date="-6m"
                    ),
                    "updated_at": fake.date_time_between(
                        start_date="-7d", end_date="now"
                    ),
                }
                self.bins.append(bin_data)

    def generate_sensors(self):
        """Generate IoT sensors for bins."""
        print("Generating sensors...")

        sensor_id = 0
        for bin_data in self.bins:
            # Determine sensor types for this bin
            sensor_configs = []

            # All bins get fill level sensor
            sensor_configs.append(
                {
                    "type": "fill_level",
                    "manufacturer": random.choice(
                        ["UltraSonic Inc", "SmartSense", "IoTech"]
                    ),
                    "model": random.choice(["US-100", "FL-200", "SMART-L1"]),
                    "frequency": 300,  # 5 minutes
                }
            )

            # Most bins get battery sensor
            if random.random() > 0.1:
                sensor_configs.append(
                    {
                        "type": "battery",
                        "manufacturer": "PowerMonitor",
                        "model": "BAT-MON-01",
                        "frequency": 3600,  # 1 hour
                    }
                )

            # Some bins get temperature sensor (important for organic waste)
            if bin_data["bin_type"] in ["organic", "general"] or random.random() > 0.7:
                sensor_configs.append(
                    {
                        "type": "temperature",
                        "manufacturer": random.choice(["TempTech", "ClimateGuard"]),
                        "model": random.choice(["T-100", "CG-TEMP-01"]),
                        "frequency": 600,  # 10 minutes
                    }
                )

            # Some bins get odor sensor
            if bin_data["bin_type"] in ["organic", "general"] and random.random() > 0.6:
                sensor_configs.append(
                    {
                        "type": "odor",
                        "manufacturer": "OdorDetect",
                        "model": "OD-500",
                        "frequency": 900,  # 15 minutes
                    }
                )

            # Some bins get weight sensor
            if (
                bin_data["location_type"] in ["commercial", "industrial"]
                and random.random() > 0.5
            ):
                sensor_configs.append(
                    {
                        "type": "weight",
                        "manufacturer": "WeighTech",
                        "model": "WT-1000",
                        "frequency": 300,  # 5 minutes
                    }
                )

            # Rare tilt sensor for security
            if random.random() > 0.95:
                sensor_configs.append(
                    {
                        "type": "tilt",
                        "manufacturer": "SecuritySense",
                        "model": "TILT-01",
                        "frequency": 60,  # 1 minute when active
                    }
                )

            # Create sensor records
            for config in sensor_configs:
                sensor_id += 1
                sensor = {
                    "sensor_id": sensor_id,
                    "sensor_code": f"SEN{bin_data['bin_code']}{config['type'][:3].upper()}",
                    "bin_id": bin_data["bin_id"],
                    "sensor_type": config["type"],
                    "manufacturer": config["manufacturer"],
                    "model": config["model"],
                    "firmware_version": f"{random.randint(1, 3)}.{random.randint(0, 9)}.{random.randint(0, 99)}",
                    "installation_date": bin_data["installation_date"],
                    "reading_frequency_seconds": config["frequency"],
                    "battery_level": (
                        round(random.uniform(20, 100), 2)
                        if config["type"] != "battery"
                        else 100
                    ),
                    "last_reading_time": fake.date_time_between(
                        start_date="-1h", end_date="now"
                    ),
                    "status": random.choices(
                        ["active", "offline", "maintenance", "faulty"],
                        weights=[90, 5, 3, 2],
                    )[0],
                    "created_at": bin_data["created_at"],
                    "updated_at": fake.date_time_between(
                        start_date="-1d", end_date="now"
                    ),
                }
                self.sensors.append(sensor)

    def generate_trucks(self):
        """Generate collection trucks."""
        print(f"Generating {CONFIG['trucks']} trucks...")

        manufacturers = ["Mercedes", "Volvo", "MAN", "Iveco", "DAF"]
        fuel_types = ["diesel", "electric", "hybrid", "cng"]
        fuel_weights = [50, 20, 20, 10]

        for i in range(CONFIG["trucks"]):
            truck = {
                "truck_id": i + 1,
                "truck_code": f"TRK{str(i+1).zfill(3)}",
                "license_plate": fake.license_plate(),
                "manufacturer": random.choice(manufacturers),
                "model": f"WasteCollector {random.randint(2000, 5000)}",
                "year": random.randint(2018, 2024),
                "capacity_kg": random.randint(5000, 15000),
                "fuel_type": random.choices(fuel_types, weights=fuel_weights)[0],
                "last_maintenance_date": fake.date_between(
                    start_date="-2m", end_date="today"
                ),
                "next_maintenance_date": fake.date_between(
                    start_date="today", end_date="+3m"
                ),
                "odometer_km": random.randint(10000, 200000),
                "status": random.choices(
                    ["available", "in_use", "maintenance", "repair"],
                    weights=[40, 45, 10, 5],
                )[0],
                "created_at": fake.date_time_between(start_date="-5y", end_date="-1y"),
                "updated_at": fake.date_time_between(start_date="-7d", end_date="now"),
            }
            self.trucks.append(truck)

    def generate_drivers(self):
        """Generate driver records."""
        print(f"Generating {CONFIG['drivers']} drivers...")

        for i in range(CONFIG["drivers"]):
            driver = {
                "driver_id": i + 1,
                "employee_id": f"EMP{str(i+1).zfill(5)}",
                "first_name": fake.first_name(),
                "last_name": fake.last_name(),
                "email": fake.email(),
                "phone": fake.phone_number()[:20],
                "license_number": f"DL{fake.bothify(text='######??')}",
                "license_expiry_date": fake.date_between(
                    start_date="today", end_date="+5y"
                ),
                "hire_date": fake.date_between(start_date="-10y", end_date="-6m"),
                "status": random.choices(
                    ["active", "on_leave", "sick", "terminated"], weights=[85, 10, 3, 2]
                )[0],
                "created_at": fake.date_time_between(start_date="-10y", end_date="-6m"),
                "updated_at": fake.date_time_between(start_date="-30d", end_date="now"),
            }
            self.drivers.append(driver)

    def generate_routes(self):
        """Generate collection routes and assignments."""
        print("Generating collection routes...")

        route_id = 0
        for district in self.districts:
            district_bins = [
                b for b in self.bins if b["district_id"] == district["district_id"]
            ]

            for route_num in range(CONFIG["routes_per_district"]):
                route_id += 1

                # Determine route type based on district characteristics
                if district["name"] in ["Downtown", "Central Business"]:
                    route_type = random.choice(["express", "regular", "express"])
                elif district["name"] in ["Industrial Zone"]:
                    route_type = random.choice(["special", "regular"])
                else:
                    route_type = "regular"

                route = {
                    "route_id": route_id,
                    "route_code": f"RT{district['district_code']}{str(route_num+1).zfill(2)}",
                    "district_id": district["district_id"],
                    "route_name": f"{district['name']} Route {route_num+1}",
                    "route_type": route_type,
                    "estimated_duration_minutes": random.randint(120, 360),
                    "estimated_distance_km": round(random.uniform(20, 80), 2),
                    "active": random.random() > 0.1,
                    "created_at": fake.date_time_between(
                        start_date="-2y", end_date="-1y"
                    ),
                    "updated_at": fake.date_time_between(
                        start_date="-30d", end_date="now"
                    ),
                }
                self.routes.append(route)

                # Assign bins to route (20-40 bins per route, or fewer if not enough bins)
                min_bins = min(20, len(district_bins))
                max_bins = min(40, len(district_bins))
                num_bins = (
                    random.randint(min_bins, max_bins)
                    if min_bins <= max_bins
                    else len(district_bins)
                )
                route_bins = random.sample(district_bins, num_bins)

                # Sort bins for optimal route (simple distance-based)
                route_bins.sort(key=lambda b: (b["latitude"], b["longitude"]))

                for order, bin_data in enumerate(route_bins, 1):
                    self.assignment_id += 1
                    assignment = {
                        "assignment_id": self.assignment_id,
                        "route_id": route_id,
                        "bin_id": bin_data["bin_id"],
                        "collection_order": order,
                        "estimated_collection_time": f"{6 + order // 10:02d}:{(order * 3) % 60:02d}:00",
                        "notes": None if random.random() > 0.1 else fake.sentence(),
                        "created_at": route["created_at"],
                        "updated_at": route["updated_at"],
                    }
                    self.route_assignments.append(assignment)

    def generate_schedules_and_collections(self):
        """Generate collection schedules and actual collection events."""
        print("Generating collection schedules and events...")

        active_trucks = [
            t for t in self.trucks if t["status"] in ["available", "in_use"]
        ]
        active_drivers = [d for d in self.drivers if d["status"] == "active"]

        current_date = self.start_date
        end_date = datetime.now()

        while current_date < end_date:
            # Schedule collections for each route every few days
            for route in self.routes:
                if not route["active"]:
                    continue

                # Check if this route should be collected today
                # Different frequencies for different route types
                if route["route_type"] == "express":
                    frequency = 2  # Every 2 days
                elif route["route_type"] == "special":
                    frequency = 7  # Weekly
                else:
                    frequency = CONFIG["collection_frequency_days"]

                if (current_date - self.start_date).days % frequency != 0:
                    continue

                self.schedule_id += 1

                # Assign truck and driver
                truck = random.choice(active_trucks)
                driver = random.choice(active_drivers)

                # Determine schedule times
                start_hour = random.choice([5, 6, 7, 8])  # Early morning starts
                duration_hours = route["estimated_duration_minutes"] / 60

                schedule = {
                    "schedule_id": self.schedule_id,
                    "route_id": route["route_id"],
                    "truck_id": truck["truck_id"],
                    "driver_id": driver["driver_id"],
                    "scheduled_date": current_date.date(),
                    "scheduled_start_time": f"{start_hour:02d}:00:00",
                    "scheduled_end_time": f"{int(start_hour + duration_hours):02d}:00:00",
                    "status": (
                        "completed"
                        if current_date < end_date - timedelta(days=1)
                        else "scheduled"
                    ),
                    "actual_start_time": None,
                    "actual_end_time": None,
                    "notes": None if random.random() > 0.05 else fake.sentence(),
                    "created_at": current_date - timedelta(days=7),
                    "updated_at": current_date,
                }

                # If completed, set actual times and create collection events
                if schedule["status"] == "completed":
                    # Add some variance to actual times
                    actual_start = current_date.replace(
                        hour=start_hour, minute=random.randint(0, 30)
                    )
                    actual_duration = route[
                        "estimated_duration_minutes"
                    ] + random.randint(-30, 60)
                    actual_end = actual_start + timedelta(minutes=actual_duration)

                    schedule["actual_start_time"] = actual_start
                    schedule["actual_end_time"] = actual_end

                    # Create collection events for bins on this route
                    route_bins = [
                        a
                        for a in self.route_assignments
                        if a["route_id"] == route["route_id"]
                    ]

                    for assignment in route_bins:
                        # Skip some collections randomly (bin might not need emptying)
                        if random.random() > 0.95:
                            continue

                        bin_data = next(
                            b for b in self.bins if b["bin_id"] == assignment["bin_id"]
                        )

                        # Calculate fill level based on bin type and days since last collection
                        base_fill = random.uniform(
                            40, 95
                        )  # Most bins are fairly full when collected

                        # Adjust based on bin type
                        if bin_data["bin_type"] == "organic":
                            base_fill = min(
                                100, base_fill * 1.2
                            )  # Organic fills faster
                        elif bin_data["bin_type"] == "recycling":
                            base_fill = base_fill * 0.9  # Recycling fills slower

                        self.event_id += 1
                        event = {
                            "event_id": self.event_id,
                            "bin_id": assignment["bin_id"],
                            "schedule_id": self.schedule_id,
                            "truck_id": truck["truck_id"],
                            "driver_id": driver["driver_id"],
                            "collected_at": actual_start
                            + timedelta(minutes=assignment["collection_order"] * 3),
                            "fill_level_before": round(base_fill, 2),
                            "weight_kg": round(
                                base_fill * bin_data["capacity_liters"] * 0.3, 2
                            ),  # Rough weight estimate
                            "collection_duration_seconds": random.randint(30, 180),
                            "notes": (
                                None if random.random() > 0.02 else fake.sentence()
                            ),
                            "created_at": actual_end,
                        }
                        self.collection_events.append(event)

                self.schedules.append(schedule)

            current_date += timedelta(days=1)

    def generate_alert_thresholds(self):
        """Generate alert threshold configurations."""
        print("Generating alert thresholds...")

        threshold_configs = [
            # Fill level thresholds
            {
                "name": "General Bin Fill Warning",
                "bin_type": "general",
                "sensor_type": "fill_level",
                "warning_value": 75,
                "critical_value": 90,
            },
            {
                "name": "Recycling Bin Fill Warning",
                "bin_type": "recycling",
                "sensor_type": "fill_level",
                "warning_value": 80,
                "critical_value": 95,
            },
            {
                "name": "Organic Bin Fill Warning",
                "bin_type": "organic",
                "sensor_type": "fill_level",
                "warning_value": 70,
                "critical_value": 85,
            },
            # Temperature thresholds
            {
                "name": "High Temperature Alert",
                "bin_type": "all",
                "sensor_type": "temperature",
                "warning_value": 35,
                "critical_value": 45,
            },
            {
                "name": "Low Temperature Alert",
                "bin_type": "all",
                "sensor_type": "temperature",
                "warning_value": 0,
                "critical_value": -10,
            },
            # Battery thresholds
            {
                "name": "Low Battery Warning",
                "bin_type": "all",
                "sensor_type": "battery",
                "warning_value": 30,
                "critical_value": 15,
            },
            # Odor thresholds
            {
                "name": "High Odor Level",
                "bin_type": "organic",
                "sensor_type": "odor",
                "warning_value": 60,
                "critical_value": 80,
            },
            # Tilt detection
            {
                "name": "Tilt Detection",
                "bin_type": "all",
                "sensor_type": "tilt",
                "warning_value": 15,
                "critical_value": 45,
            },  # Degrees from vertical
        ]

        for i, config in enumerate(threshold_configs, 1):
            threshold = {
                "threshold_id": i,
                "name": config["name"],
                "bin_type": config["bin_type"],
                "sensor_type": config["sensor_type"],
                "warning_value": config["warning_value"],
                "critical_value": config["critical_value"],
                "check_interval_seconds": 300,  # 5 minutes
                "active": True,
                "created_at": fake.date_time_between(start_date="-1y", end_date="-6m"),
                "updated_at": fake.date_time_between(start_date="-30d", end_date="now"),
            }
            self.alert_thresholds.append(threshold)

    def generate_sensor_data(self):
        """Generate sensor readings and aggregated data."""
        print("Generating sensor readings (this may take a while)...")

        # We'll generate a sample of sensor data for performance reasons
        # In real scenario, this would be continuous streaming data

        hourly_aggregates = []
        daily_aggregates = []
        aggregation_id_hourly = 0
        aggregation_id_daily = 0

        # Generate readings for last 7 days (sampled)
        sample_days = 7
        start_date = datetime.now() - timedelta(days=sample_days)

        for sensor in random.sample(
            self.sensors, min(100, len(self.sensors))
        ):  # Sample of sensors
            bin_data = next(b for b in self.bins if b["bin_id"] == sensor["bin_id"])

            # Find last collection for this bin
            bin_collections = [
                e for e in self.collection_events if e["bin_id"] == sensor["bin_id"]
            ]
            bin_collections.sort(key=lambda x: x["collected_at"], reverse=True)

            current_time = start_date
            while current_time < datetime.now():
                # Determine if we should generate a reading based on frequency
                if random.random() > 0.8:  # Sample 20% of readings for performance
                    current_time += timedelta(
                        seconds=sensor["reading_frequency_seconds"]
                    )
                    continue

                # Calculate reading value based on sensor type
                reading_value = self.calculate_sensor_reading(
                    sensor, bin_data, bin_collections, current_time
                )

                if reading_value is not None:
                    self.reading_id += 1
                    reading = {
                        "reading_id": self.reading_id,
                        "sensor_id": sensor["sensor_id"],
                        "reading_time": current_time,
                        "reading_value": round(reading_value, 3),
                        "unit": self.get_sensor_unit(sensor["sensor_type"]),
                        "quality": self.determine_reading_quality(
                            sensor, reading_value
                        ),
                        "created_at": current_time,
                    }
                    self.sensor_readings.append(reading)

                    # Check for alerts
                    self.check_and_create_alerts(
                        sensor, bin_data, reading_value, current_time
                    )

                current_time += timedelta(seconds=sensor["reading_frequency_seconds"])

            # Generate hourly aggregates for this sensor
            for day in range(sample_days):
                day_date = start_date + timedelta(days=day)
                day_readings = [
                    r
                    for r in self.sensor_readings
                    if r["sensor_id"] == sensor["sensor_id"]
                    and r["reading_time"].date() == day_date.date()
                ]

                if day_readings:
                    # Daily aggregate
                    aggregation_id_daily += 1
                    daily_agg = {
                        "aggregation_id": aggregation_id_daily,
                        "sensor_id": sensor["sensor_id"],
                        "date": day_date.date(),
                        "min_value": min(r["reading_value"] for r in day_readings),
                        "max_value": max(r["reading_value"] for r in day_readings),
                        "avg_value": round(
                            sum(r["reading_value"] for r in day_readings)
                            / len(day_readings),
                            3,
                        ),
                        "peak_hour": max(
                            day_readings, key=lambda r: r["reading_value"]
                        )["reading_time"].time(),
                        "peak_value": max(r["reading_value"] for r in day_readings),
                        "reading_count": len(day_readings),
                        "quality_good_pct": round(
                            len([r for r in day_readings if r["quality"] == "good"])
                            * 100
                            / len(day_readings),
                            2,
                        ),
                        "quality_warning_pct": round(
                            len([r for r in day_readings if r["quality"] == "warning"])
                            * 100
                            / len(day_readings),
                            2,
                        ),
                        "quality_error_pct": round(
                            len([r for r in day_readings if r["quality"] == "error"])
                            * 100
                            / len(day_readings),
                            2,
                        ),
                        "created_at": day_date + timedelta(days=1),
                    }
                    daily_aggregates.append(daily_agg)

                    # Hourly aggregates for this day
                    for hour in range(24):
                        hour_start = day_date.replace(hour=hour, minute=0, second=0)
                        hour_readings = [
                            r for r in day_readings if r["reading_time"].hour == hour
                        ]

                        if hour_readings:
                            aggregation_id_hourly += 1
                            hourly_agg = {
                                "aggregation_id": aggregation_id_hourly,
                                "sensor_id": sensor["sensor_id"],
                                "hour_start": hour_start,
                                "min_value": min(
                                    r["reading_value"] for r in hour_readings
                                ),
                                "max_value": max(
                                    r["reading_value"] for r in hour_readings
                                ),
                                "avg_value": round(
                                    sum(r["reading_value"] for r in hour_readings)
                                    / len(hour_readings),
                                    3,
                                ),
                                "reading_count": len(hour_readings),
                                "quality_good_count": len(
                                    [r for r in hour_readings if r["quality"] == "good"]
                                ),
                                "quality_warning_count": len(
                                    [
                                        r
                                        for r in hour_readings
                                        if r["quality"] == "warning"
                                    ]
                                ),
                                "quality_error_count": len(
                                    [
                                        r
                                        for r in hour_readings
                                        if r["quality"] == "error"
                                    ]
                                ),
                                "created_at": hour_start + timedelta(hours=1),
                            }
                            hourly_aggregates.append(hourly_agg)

        # Save aggregated data
        self.save_to_csv("sensor_readings_hourly", hourly_aggregates)
        self.save_to_csv("sensor_readings_daily", daily_aggregates)

    def calculate_sensor_reading(self, sensor, bin_data, bin_collections, current_time):
        """Calculate realistic sensor reading based on type and context."""
        if sensor["sensor_type"] == "fill_level":
            # Calculate fill level based on time since last collection
            if bin_collections:
                last_collection = bin_collections[0]
                hours_since_collection = (
                    current_time - last_collection["collected_at"]
                ).total_seconds() / 3600

                # Different fill rates for different bin types
                fill_rates = {
                    "general": 1.5,  # % per hour
                    "recycling": 0.8,
                    "organic": 2.0,
                    "paper": 0.5,
                    "plastic": 0.6,
                    "glass": 0.3,
                    "hazardous": 0.2,
                }
                fill_rate = fill_rates.get(bin_data["bin_type"], 1.0)

                # Add daily patterns (more during day, less at night)
                hour = current_time.hour
                if 6 <= hour <= 22:
                    fill_rate *= 1.5
                else:
                    fill_rate *= 0.5

                # Add weekly patterns (more on weekends for residential)
                if (
                    bin_data["location_type"] == "residential"
                    and current_time.weekday() >= 5
                ):
                    fill_rate *= 1.3

                # Calculate fill level
                base_fill = 5  # Start at 5% after collection
                fill_level = base_fill + (hours_since_collection * fill_rate)
                fill_level = min(
                    100, fill_level + random.uniform(-5, 5)
                )  # Add noise and cap at 100

                return max(0, fill_level)
            else:
                # No collection history, random fill
                return random.uniform(20, 80)

        elif sensor["sensor_type"] == "temperature":
            # Simulate daily temperature patterns
            hour = current_time.hour
            base_temp = 20  # Base temperature

            # Daily variation
            if 0 <= hour < 6:
                temp = base_temp - 5
            elif 6 <= hour < 12:
                temp = base_temp + (hour - 6)
            elif 12 <= hour < 18:
                temp = base_temp + 10
            else:
                temp = base_temp + 10 - (hour - 18)

            # Seasonal variation
            month = current_time.month
            if month in [12, 1, 2]:  # Winter
                temp -= 15
            elif month in [6, 7, 8]:  # Summer
                temp += 10

            # Add noise
            temp += random.uniform(-3, 3)

            # Organic bins generate heat
            if bin_data["bin_type"] == "organic":
                temp += random.uniform(2, 8)

            return temp

        elif sensor["sensor_type"] == "battery":
            # Battery slowly depletes over time
            days_since_install = (
                current_time
                - datetime.combine(sensor["installation_date"], datetime.min.time())
            ).days
            depletion_rate = 0.1  # % per day
            battery_level = 100 - (days_since_install * depletion_rate)
            battery_level = max(10, battery_level + random.uniform(-2, 2))
            return min(100, battery_level)

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
                # Get approximate fill level
                fill_level = random.uniform(20, 80)  # Simplified
                temp = 20  # Simplified

                # Calculate odor level
                odor = (fill_level * 0.5) + (max(0, temp - 20) * 2)

                # Organic bins smell more
                if bin_data["bin_type"] == "organic":
                    odor *= 1.5

                return min(100, max(0, odor + random.uniform(-10, 10)))
            return random.uniform(10, 60)

        elif sensor["sensor_type"] == "weight":
            # Weight correlates with fill level
            fill_level = random.uniform(20, 80)  # Simplified
            max_weight = bin_data["capacity_liters"] * 0.5  # kg (rough estimate)
            weight = (fill_level / 100) * max_weight
            return max(0, weight + random.uniform(-10, 10))

        elif sensor["sensor_type"] == "tilt":
            # Usually 0, occasionally tilted
            if random.random() > 0.99:  # 1% chance of tilt
                return random.uniform(5, 45)
            return random.uniform(0, 2)

        return None

    def get_sensor_unit(self, sensor_type):
        """Get the unit for sensor type."""
        units = {
            "fill_level": "%",
            "temperature": "°C",
            "odor": "ppm",
            "battery": "%",
            "weight": "kg",
            "tilt": "degrees",
        }
        return units.get(sensor_type, "units")

    def determine_reading_quality(self, sensor, value):
        """Determine reading quality."""
        # Most readings are good
        if random.random() < 0.95:
            return "good"
        elif random.random() < 0.8:
            return "warning"
        else:
            return "error"

    def check_and_create_alerts(self, sensor, bin_data, reading_value, current_time):
        """Check thresholds and create alerts if needed."""
        # Find applicable thresholds
        thresholds = [
            t
            for t in self.alert_thresholds
            if t["sensor_type"] == sensor["sensor_type"]
            and (t["bin_type"] == "all" or t["bin_type"] == bin_data["bin_type"])
        ]

        for threshold in thresholds:
            alert_type = None
            severity = None
            message = None

            if sensor["sensor_type"] == "fill_level":
                if reading_value >= threshold["critical_value"]:
                    alert_type = "fill_critical"
                    severity = "critical"
                    message = f"Bin {bin_data['bin_code']} is critically full ({reading_value:.1f}%)"
                elif reading_value >= threshold["warning_value"]:
                    alert_type = "fill_warning"
                    severity = "warning"
                    message = f"Bin {bin_data['bin_code']} fill level warning ({reading_value:.1f}%)"

            elif sensor["sensor_type"] == "temperature":
                if reading_value >= threshold["critical_value"]:
                    alert_type = "temperature_high"
                    severity = "critical"
                    message = f"High temperature alert for bin {bin_data['bin_code']} ({reading_value:.1f}°C)"

            elif sensor["sensor_type"] == "battery":
                if reading_value <= threshold["critical_value"]:
                    alert_type = "battery_low"
                    severity = "critical"
                    message = f"Critical battery level for sensor {sensor['sensor_code']} ({reading_value:.1f}%)"

            elif sensor["sensor_type"] == "odor":
                if reading_value >= threshold["critical_value"]:
                    alert_type = "odor_high"
                    severity = "warning"
                    message = f"High odor level detected at bin {bin_data['bin_code']}"

            elif sensor["sensor_type"] == "tilt":
                if reading_value >= threshold["critical_value"]:
                    alert_type = "tilt_detected"
                    severity = "emergency"
                    message = (
                        f"Bin {bin_data['bin_code']} has been tilted or vandalized"
                    )

            if alert_type and random.random() > 0.7:  # Don't create too many alerts
                self.alert_id += 1
                alert = {
                    "alert_id": self.alert_id,
                    "bin_id": bin_data["bin_id"],
                    "sensor_id": sensor["sensor_id"],
                    "threshold_id": threshold["threshold_id"],
                    "alert_type": alert_type,
                    "severity": severity,
                    "triggered_at": current_time,
                    "resolved_at": (
                        current_time + timedelta(hours=random.randint(1, 12))
                        if random.random() > 0.3
                        else None
                    ),
                    "alert_value": reading_value,
                    "message": message,
                    "acknowledged": random.random() > 0.2,
                    "acknowledged_by": fake.name() if random.random() > 0.2 else None,
                    "acknowledged_at": (
                        current_time + timedelta(minutes=random.randint(5, 60))
                        if random.random() > 0.3
                        else None
                    ),
                    "created_at": current_time,
                }
                self.alerts.append(alert)

    def generate_predictions(self):
        """Generate ML predictions for fill rates."""
        print("Generating predictive analytics...")

        # Generate predictions for next 7 days
        prediction_days = 7

        for day in range(prediction_days):
            prediction_date = datetime.now().date() + timedelta(days=day)

            # Generate predictions for a sample of bins
            for bin_data in random.sample(self.bins, min(100, len(self.bins))):
                # Generate hourly predictions for key hours
                for hour in [6, 9, 12, 15, 18, 21]:  # Key hours of the day
                    self.prediction_id += 1

                    # Base prediction on bin type and location
                    base_fill = random.uniform(20, 80)

                    # Adjust based on bin type
                    if bin_data["bin_type"] == "organic":
                        base_fill *= 1.2
                    elif bin_data["bin_type"] == "recycling":
                        base_fill *= 0.8

                    # Adjust based on day of week
                    if prediction_date.weekday() >= 5:  # Weekend
                        base_fill *= 1.1

                    prediction = {
                        "prediction_id": self.prediction_id,
                        "bin_id": bin_data["bin_id"],
                        "prediction_date": prediction_date,
                        "prediction_hour": f"{hour:02d}:00:00",
                        "predicted_fill_rate": min(
                            100, round(base_fill + random.uniform(-10, 10), 2)
                        ),
                        "confidence_score": round(random.uniform(70, 95), 2),
                        "model_version": "1.2.0",
                        "created_at": datetime.now(),
                    }
                    self.predictions.append(prediction)

    def save_to_csv(self, table_name, data):
        """Save data to CSV file."""
        if not data:
            return

        output_file = OUTPUT_DIR / f"{table_name}.csv"

        with open(output_file, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=data[0].keys())
            writer.writeheader()
            writer.writerows(data)

    def save_all(self):
        """Save all generated data to CSV files."""
        print("\nSaving data to CSV files...")

        OUTPUT_DIR.mkdir(exist_ok=True)

        # Save all tables
        tables = [
            ("districts", self.districts),
            ("bins", self.bins),
            ("sensors", self.sensors),
            ("collection_routes", self.routes),
            ("route_bin_assignments", self.route_assignments),
            ("trucks", self.trucks),
            ("drivers", self.drivers),
            ("collection_schedules", self.schedules),
            ("collection_events", self.collection_events),
            ("sensor_readings", self.sensor_readings),
            ("alert_thresholds", self.alert_thresholds),
            ("alerts", self.alerts),
            ("fill_rate_predictions", self.predictions),
        ]

        for table_name, data in tables:
            if data:
                self.save_to_csv(table_name, data)
                print(f"  [OK] {table_name}: {len(data):,} records")

        # Generate summary statistics
        self.generate_summary()

    def generate_summary(self):
        """Generate summary statistics."""
        total_bins = len(self.bins)
        total_sensors = len(self.sensors)
        total_readings = len(self.sensor_readings)
        total_collections = len(self.collection_events)
        total_alerts = len(self.alerts)

        summary = f"""
IoT Waste Management Data Generation Summary
============================================
Infrastructure:
  Districts: {len(self.districts)}
  Bins: {total_bins:,}
  Sensors: {total_sensors:,}

Collection Fleet:
  Trucks: {len(self.trucks)}
  Drivers: {len(self.drivers)}
  Routes: {len(self.routes)}

Operations:
  Scheduled Collections: {len(self.schedules):,}
  Completed Collections: {total_collections:,}

IoT Data:
  Sensor Readings: {total_readings:,}
  Alerts Generated: {total_alerts:,}
  Fill Predictions: {len(self.predictions):,}

Data Quality:
  Bins per District: {total_bins / len(self.districts):.1f}
  Sensors per Bin: {total_sensors / total_bins:.1f}
  Collections per Bin: {total_collections / total_bins:.1f}

Files Generated: {len(list(OUTPUT_DIR.glob('*.csv')))}
"""

        print(summary)

        # Save summary to file
        with open(OUTPUT_DIR / "generation_summary.txt", "w") as f:
            f.write(summary)


if __name__ == "__main__":
    generator = IoTBinsGenerator()
    generator.generate_all()
    print("\n[SUCCESS] IoT Waste Management data generation complete!")
