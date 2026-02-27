#!/usr/bin/env python3
"""
Fleet Management Data Generator

Generates realistic fleet tracking data including:
- High-frequency GPS positions
- Driver behavior events
- Engine diagnostics (OBD-II)
- Fuel consumption tracking
- Trip and stop records
- Maintenance schedules
- Compliance (HOS, DVIR)
"""

import csv
import random
import yaml
import argparse
from datetime import datetime, timedelta
from pathlib import Path
import math
from typing import List, Dict, Tuple, Any
import uuid
from faker import Faker


class FleetManagementGenerator:
    def __init__(self, config_path: str):
        """Initialize generator with configuration"""
        with open(config_path, "r") as f:
            self.config = yaml.safe_load(f)

        self.seed = self.config.get("seed", 42)
        random.seed(self.seed)
        self.fake = Faker("en_US")
        self.fake.seed_instance(self.seed)

        self.output_dir = Path(self.config["output_dir"])
        self.output_dir.mkdir(parents=True, exist_ok=True)

        # Data containers
        self.depots = []
        self.vehicles = []
        self.drivers = []
        self.routes = []
        self.trips = []
        self.trip_stops = []
        self.gps_positions = []
        self.driver_events = []
        self.engine_diagnostics = []
        self.fuel_readings = []
        self.maintenance_records = []
        self.dvir_reports = []
        self.driver_logs = []
        self.diagnostic_codes = []

        # Counters
        self.trip_id_counter = 1
        self.stop_id_counter = 1
        self.event_id_counter = 1
        self.maintenance_id_counter = 1
        self.dvir_id_counter = 1

    def generate_all(self):
        """Generate all data in sequence"""
        print("Generating Fleet Management data...")

        # Master data
        self._generate_depots()
        self._generate_vehicles()
        self._generate_drivers()
        self._generate_routes()

        # Operational data
        self._generate_trips()
        self._generate_gps_positions()
        self._generate_driver_events()
        self._generate_engine_diagnostics()
        self._generate_fuel_readings()
        self._generate_maintenance_records()
        self._generate_compliance_data()

        # Write to CSV
        self._write_all_csvs()

        # Generate SQL scripts
        self._generate_sql_scripts()

        print(
            f"[OK] Generated data for {len(self.vehicles)} vehicles, "
            f"{len(self.drivers)} drivers, {len(self.trips)} trips"
        )
        print(f"[OK] Generated {len(self.gps_positions)} GPS positions")
        print(f"[OK] Output written to {self.output_dir}")

    def _generate_depots(self):
        """Generate depot/facility locations"""
        cities = self.config["geographic_distribution"]["cities"]

        for i in range(self.config["counts"]["depots"]):
            city = cities[i % len(cities)]
            city_name, state = city.rsplit(", ", 1)

            depot = {
                "depot_id": i + 1,
                "depot_code": f"DEP{state}{i+1:02d}",
                "depot_name": f"{city_name} Distribution Center",
                "address": self.fake.street_address(),
                "city": city_name,
                "state": state,
                "zip_code": self.fake.zipcode(),
                "latitude": self._get_city_coordinates(city_name)[0]
                + random.uniform(-0.1, 0.1),
                "longitude": self._get_city_coordinates(city_name)[1]
                + random.uniform(-0.1, 0.1),
                "capacity": random.randint(50, 200),
                "type": random.choice(["main", "regional", "satellite"]),
                "is_active": True,
            }
            self.depots.append(depot)

    def _generate_vehicles(self):
        """Generate vehicle fleet"""
        vehicle_id = 1

        for _ in range(self.config["counts"]["vehicles"]):
            # Vehicle type
            vehicle_type = random.choices(
                list(self.config["vehicle_distribution"]["types"].keys()),
                weights=list(self.config["vehicle_distribution"]["types"].values()),
            )[0]

            # Fuel type
            fuel_type = random.choices(
                list(self.config["vehicle_distribution"]["fuel_types"].keys()),
                weights=list(
                    self.config["vehicle_distribution"]["fuel_types"].values()
                ),
            )[0]

            # Age
            age_range = random.choices(
                list(self.config["vehicle_distribution"]["age_years"].keys()),
                weights=list(self.config["vehicle_distribution"]["age_years"].values()),
            )[0]
            min_age, max_age = map(int, age_range.split("-"))
            vehicle_age = random.randint(min_age, max_age)

            # Calculate dates
            manufacture_year = datetime.now().year - vehicle_age
            purchase_date = datetime(
                manufacture_year, random.randint(1, 12), random.randint(1, 28)
            )

            # Assign to depot
            depot = random.choice(self.depots)

            vehicle = {
                "vehicle_id": vehicle_id,
                "vehicle_number": f"FLT{vehicle_id:04d}",
                "vin": self._generate_vin(),
                "plate_number": self._generate_plate(),
                "vehicle_type": vehicle_type,
                "make": random.choice(
                    [
                        "Freightliner",
                        "Volvo",
                        "Peterbilt",
                        "Mack",
                        "International",
                        "Ford",
                        "Mercedes",
                    ]
                ),
                "model": f"Model_{random.choice(['X', 'T', 'S', 'Pro'])}{random.randint(100, 900)}",
                "year": manufacture_year,
                "fuel_type": fuel_type,
                "depot_id": depot["depot_id"],
                "purchase_date": purchase_date,
                "current_odometer_km": random.randint(10000, 300000),
                "last_service_date": self.fake.date_between(
                    start_date="-60days", end_date="today"
                ),
                "last_service_odometer_km": random.randint(5000, 295000),
                "capacity_kg": self._get_vehicle_capacity(vehicle_type),
                "status": random.choices(
                    ["active", "maintenance", "inactive"], weights=[0.85, 0.10, 0.05]
                )[0],
                "has_gps": True,
                "has_eld": random.random() < self.config["compliance"]["eld_adoption"],
                "has_dashcam": random.random() < 0.6,
                "has_reefer": vehicle_type == "refrigerated",
            }
            self.vehicles.append(vehicle)
            vehicle_id += 1

    def _generate_drivers(self):
        """Generate driver profiles"""
        driver_id = 1

        for _ in range(self.config["counts"]["drivers"]):
            # Experience level
            experience_level = random.choice(
                list(self.config["driver_profiles"]["experience_years"].keys())
            )
            exp_range = self.config["driver_profiles"]["experience_years"][
                experience_level
            ]
            years_experience = random.randint(exp_range[0], exp_range[1])

            # License class
            license_class = random.choices(
                list(self.config["driver_profiles"]["license_classes"].keys()),
                weights=list(
                    self.config["driver_profiles"]["license_classes"].values()
                ),
            )[0]

            # Hire date based on experience
            if years_experience > 0:
                hire_date = self.fake.date_between(
                    start_date=f"-{years_experience}years", end_date="-1days"
                )
            else:
                hire_date = self.fake.date_between(
                    start_date="-90days", end_date="-1days"
                )

            driver = {
                "driver_id": driver_id,
                "employee_id": f"EMP{driver_id:05d}",
                "driver_name": self.fake.name(),
                "license_number": f"{self.fake.state_abbr()}{random.randint(1000000, 9999999)}",
                "license_class": license_class,
                "license_expiry": self.fake.date_between(
                    start_date="today", end_date="+3years"
                ),
                "phone": self.fake.phone_number()[:20],
                "email": self.fake.email(),
                "hire_date": hire_date,
                "years_experience": years_experience,
                "safety_score": random.randint(70, 100),
                "status": random.choices(
                    ["active", "on_leave", "terminated"], weights=[0.90, 0.08, 0.02]
                )[0],
                "home_depot_id": random.choice(self.depots)["depot_id"],
                "medical_cert_expiry": self.fake.date_between(
                    start_date="+30days", end_date="+2years"
                ),
                "hazmat_certified": random.random() < 0.3,
                "last_drug_test": self.fake.date_between(
                    start_date="-90days", end_date="today"
                ),
                "violations_count": random.choices(
                    [0, 1, 2, 3], weights=[0.7, 0.2, 0.08, 0.02]
                )[0],
            }
            self.drivers.append(driver)
            driver_id += 1

    def _generate_routes(self):
        """Generate predefined routes"""
        route_id = 1

        for _ in range(self.config["counts"]["routes"]):
            # Route type
            route_type = random.choices(
                list(self.config["geographic_distribution"]["route_types"].keys()),
                weights=list(
                    self.config["geographic_distribution"]["route_types"].values()
                ),
            )[0]

            # Origin and destination
            cities = self.config["geographic_distribution"]["cities"]
            origin_city = random.choice(cities)
            dest_city = random.choice([c for c in cities if c != origin_city])

            # Distance based on route type
            if route_type == "local":
                distance_km = random.randint(20, 80)
            elif route_type == "regional":
                distance_km = random.randint(80, 320)
            else:  # long_haul
                distance_km = random.randint(320, 1600)

            route = {
                "route_id": route_id,
                "route_code": f"RT{route_id:03d}",
                "route_name": f"{origin_city.split(',')[0]} to {dest_city.split(',')[0]}",
                "origin_depot_id": random.choice(self.depots)["depot_id"],
                "destination_depot_id": random.choice(self.depots)["depot_id"],
                "route_type": route_type,
                "distance_km": distance_km,
                "estimated_duration_hours": distance_km
                / 60,  # Assuming 60 km/h average
                "toll_cost": (
                    round(distance_km * 0.15, 2) if random.random() < 0.4 else 0
                ),
                "fuel_cost_estimate": round(distance_km * 0.35, 2),
                "is_active": True,
            }
            self.routes.append(route)
            route_id += 1

    def _generate_trips(self):
        """Generate trip records"""
        print("  Generating trips...")

        start_date = datetime.strptime(
            self.config["date_ranges"]["data_start"], "%Y-%m-%d"
        )
        end_date = datetime.strptime(self.config["date_ranges"]["data_end"], "%Y-%m-%d")
        current_date = start_date

        while current_date <= end_date:
            for vehicle in self.vehicles:
                if vehicle["status"] != "active":
                    continue

                # Generate trips for this vehicle on this day
                num_trips = random.randint(
                    1, self.config["counts"]["trips_per_vehicle_per_day"]
                )

                for trip_num in range(num_trips):
                    # Assign driver and route
                    eligible_drivers = [
                        d for d in self.drivers if d["status"] == "active"
                    ]
                    if not eligible_drivers:
                        continue

                    driver = random.choice(eligible_drivers)
                    route = random.choice(self.routes)

                    # Calculate trip timing
                    start_hour = 6 + trip_num * 6  # Space trips throughout the day
                    trip_start = current_date.replace(
                        hour=start_hour, minute=random.randint(0, 59)
                    )
                    trip_duration_hours = route[
                        "estimated_duration_hours"
                    ] * random.uniform(0.9, 1.3)
                    trip_end = trip_start + timedelta(hours=trip_duration_hours)

                    # Cargo details
                    cargo_type = random.choices(
                        list(self.config["cargo_types"].keys()),
                        weights=list(self.config["cargo_types"].values()),
                    )[0]

                    trip = {
                        "trip_id": self.trip_id_counter,
                        "vehicle_id": vehicle["vehicle_id"],
                        "driver_id": driver["driver_id"],
                        "route_id": route["route_id"],
                        "trip_number": f"TRP{self.trip_id_counter:08d}",
                        "start_time": trip_start,
                        "end_time": trip_end,
                        "origin": route["route_name"].split(" to ")[0],
                        "destination": route["route_name"].split(" to ")[1],
                        "planned_distance_km": route["distance_km"],
                        "actual_distance_km": route["distance_km"]
                        * random.uniform(0.95, 1.1),
                        "planned_duration_hours": route["estimated_duration_hours"],
                        "cargo_type": cargo_type,
                        "cargo_weight_kg": random.uniform(
                            100, vehicle["capacity_kg"] * 0.9
                        ),
                        "fuel_consumed_liters": self._calculate_fuel_consumption(
                            vehicle["vehicle_type"], route["distance_km"]
                        ),
                        "status": (
                            "completed" if trip_end < datetime.now() else "in_progress"
                        ),
                    }
                    self.trips.append(trip)

                    # Generate stops for this trip
                    self._generate_trip_stops(trip, vehicle["vehicle_type"])

                    self.trip_id_counter += 1

            current_date += timedelta(days=1)

    def _generate_trip_stops(self, trip: Dict, vehicle_type: str):
        """Generate stops for a trip"""
        stop_range = self.config["driving_patterns"]["stops_per_trip"].get(
            vehicle_type, [1, 5]
        )
        num_stops = random.randint(stop_range[0], stop_range[1])

        trip_duration = (trip["end_time"] - trip["start_time"]).total_seconds() / 3600
        time_between_stops = trip_duration / (num_stops + 1)

        for i in range(num_stops):
            stop_time = trip["start_time"] + timedelta(
                hours=(i + 1) * time_between_stops
            )
            stop_duration = random.randint(
                self.config["driving_patterns"]["stop_duration_minutes"]["delivery"][0],
                self.config["driving_patterns"]["stop_duration_minutes"]["delivery"][1],
            )

            stop = {
                "stop_id": self.stop_id_counter,
                "trip_id": trip["trip_id"],
                "stop_sequence": i + 1,
                "stop_type": random.choice(["delivery", "pickup", "break", "fuel"]),
                "scheduled_time": stop_time,
                "actual_arrival": stop_time
                + timedelta(minutes=random.randint(-15, 30)),
                "actual_departure": stop_time + timedelta(minutes=stop_duration),
                "location_name": self.fake.company(),
                "address": self.fake.street_address(),
                "latitude": 40.7128 + random.uniform(-1, 1),
                "longitude": -74.0060 + random.uniform(-1, 1),
                "packages_delivered": (
                    random.randint(1, 20) if vehicle_type == "delivery_van" else 0
                ),
                "packages_picked_up": (
                    random.randint(0, 10) if random.random() < 0.3 else 0
                ),
                "delay_minutes": max(0, random.randint(-5, 20)),
                "delay_reason": random.choice(
                    ["traffic", "customer_not_ready", "loading_delay", None]
                ),
            }
            self.trip_stops.append(stop)
            self.stop_id_counter += 1

    def _generate_gps_positions(self):
        """Generate high-frequency GPS tracking data"""
        print("  Generating GPS positions (this may take a moment)...")

        gps_freq = self.config["counts"]["gps_frequency_seconds"]

        # Limit to recent trips for performance
        recent_trips = [
            t
            for t in self.trips
            if t["start_time"] > datetime.now() - timedelta(days=2)
        ][:50]

        for trip in recent_trips:
            current_time = trip["start_time"]
            trip_stops_list = [
                s for s in self.trip_stops if s["trip_id"] == trip["trip_id"]
            ]

            # Starting position
            lat = 40.7128 + random.uniform(-0.5, 0.5)
            lon = -74.0060 + random.uniform(-0.5, 0.5)
            current_speed = 0

            while current_time <= trip["end_time"]:
                # Determine road type based on time in trip
                progress = (current_time - trip["start_time"]).total_seconds() / (
                    trip["end_time"] - trip["start_time"]
                ).total_seconds()

                if progress < 0.2 or progress > 0.8:
                    road_type = "urban"
                else:
                    road_type = "highway"

                # Calculate speed
                speed_config = self.config["driving_patterns"]["speed_profiles"][
                    road_type
                ]
                target_speed = random.gauss(
                    speed_config["typical"],
                    (speed_config["max"] - speed_config["min"]) / 6,
                )

                # Smooth speed changes
                current_speed = current_speed * 0.8 + target_speed * 0.2

                # Check if near a stop
                is_stopped = False
                for stop in trip_stops_list:
                    if (
                        abs((stop["actual_arrival"] - current_time).total_seconds())
                        < 600
                    ):
                        is_stopped = True
                        current_speed = 0
                        break

                # Update position
                if not is_stopped:
                    # Convert speed to position change
                    distance_km = (current_speed * 1.60934) * (gps_freq / 3600)
                    lat += random.gauss(0, 0.0001) + (
                        distance_km / 111
                    )  # rough conversion
                    lon += random.gauss(0, 0.0001) + (distance_km / 111)

                gps_position = {
                    "position_id": len(self.gps_positions) + 1,
                    "vehicle_id": trip["vehicle_id"],
                    "trip_id": trip["trip_id"],
                    "timestamp": current_time,
                    "latitude": round(lat, 6),
                    "longitude": round(lon, 6),
                    "speed_kmh": round(current_speed * 1.60934, 1),
                    "heading": random.randint(0, 359),
                    "altitude_m": random.randint(0, 500),
                    "satellites": random.randint(6, 12),
                    "hdop": round(
                        random.uniform(0.8, 2.5), 1
                    ),  # Horizontal dilution of precision
                    "engine_on": not is_stopped,
                    "address": None,  # Would be reverse geocoded in production
                }
                self.gps_positions.append(gps_position)

                current_time += timedelta(seconds=gps_freq)

    def _generate_driver_events(self):
        """Generate driver behavior events"""
        print("  Generating driver events...")

        for trip in self.trips:
            distance_km = trip["actual_distance_km"]

            # Calculate expected events based on distance
            events_per_100km = {
                "harsh_brake": self.config["driving_patterns"]["event_rates"][
                    "harsh_brake"
                ],
                "harsh_acceleration": self.config["driving_patterns"]["event_rates"][
                    "harsh_acceleration"
                ],
                "harsh_cornering": self.config["driving_patterns"]["event_rates"][
                    "harsh_cornering"
                ],
                "speeding": self.config["driving_patterns"]["event_rates"]["speeding"],
                "idle_excessive": self.config["driving_patterns"]["event_rates"][
                    "idle_excessive"
                ],
            }

            for event_type, rate in events_per_100km.items():
                # Simple approximation of Poisson distribution
                expected_events = rate * distance_km / 100
                num_events = max(
                    0, int(random.gauss(expected_events, expected_events**0.5))
                )

                for _ in range(num_events):
                    event_time = self.fake.date_time_between(
                        start_date=trip["start_time"], end_date=trip["end_time"]
                    )

                    event = {
                        "event_id": self.event_id_counter,
                        "trip_id": trip["trip_id"],
                        "vehicle_id": trip["vehicle_id"],
                        "driver_id": trip["driver_id"],
                        "event_type": event_type,
                        "event_time": event_time,
                        "severity": random.choice(["low", "medium", "high"]),
                        "duration_seconds": random.randint(1, 10),
                        "value": self._get_event_value(event_type),
                        "speed_kmh": random.uniform(20, 100),
                        "location_lat": 40.7128 + random.uniform(-0.5, 0.5),
                        "location_lon": -74.0060 + random.uniform(-0.5, 0.5),
                        "g_force": (
                            round(random.uniform(0.3, 0.8), 2)
                            if "harsh" in event_type
                            else None
                        ),
                    }
                    self.driver_events.append(event)
                    self.event_id_counter += 1

    def _generate_engine_diagnostics(self):
        """Generate OBD-II diagnostic data"""
        print("  Generating engine diagnostics...")

        for trip in self.trips[:100]:  # Limit for performance
            # Generate readings every 30 seconds during trip
            current_time = trip["start_time"]

            while current_time <= trip["end_time"]:
                for param in self.config["engine_diagnostics"]["parameters"]:
                    value = self._get_diagnostic_value(param, trip["vehicle_id"])

                    diagnostic = {
                        "diagnostic_id": len(self.engine_diagnostics) + 1,
                        "vehicle_id": trip["vehicle_id"],
                        "trip_id": trip["trip_id"],
                        "timestamp": current_time,
                        "parameter": param,
                        "value": value,
                        "unit": self._get_parameter_unit(param),
                    }
                    self.engine_diagnostics.append(diagnostic)

                current_time += timedelta(seconds=30)

            # Chance of diagnostic trouble code
            if random.random() < self.config["engine_diagnostics"]["dtc_probability"]:
                dtc_code = random.choice(
                    self.config["engine_diagnostics"]["common_dtc_codes"]
                )
                dtc = {
                    "dtc_id": len(self.diagnostic_codes) + 1,
                    "vehicle_id": trip["vehicle_id"],
                    "dtc_code": dtc_code,
                    "description": self._get_dtc_description(dtc_code),
                    "severity": random.choice(["minor", "moderate", "severe"]),
                    "detected_at": trip["start_time"],
                    "cleared_at": None,
                    "mil_on": random.random() < 0.5,  # Malfunction indicator lamp
                }
                self.diagnostic_codes.append(dtc)

    def _generate_fuel_readings(self):
        """Generate fuel consumption data"""
        print("  Generating fuel readings...")

        for trip in self.trips:
            vehicle = next(
                v for v in self.vehicles if v["vehicle_id"] == trip["vehicle_id"]
            )
            vehicle_type = vehicle["vehicle_type"]

            # Initial fuel level
            fuel_level = random.uniform(50, 100)

            # Generate readings every 15 minutes
            current_time = trip["start_time"]
            while current_time <= trip["end_time"]:
                # Fuel consumption
                consumption_rate = self._calculate_fuel_consumption_rate(vehicle_type)
                fuel_level = max(10, fuel_level - consumption_rate)

                fuel_reading = {
                    "reading_id": len(self.fuel_readings) + 1,
                    "vehicle_id": trip["vehicle_id"],
                    "trip_id": trip["trip_id"],
                    "timestamp": current_time,
                    "fuel_level_pct": round(fuel_level, 1),
                    "fuel_level_liters": round(fuel_level * 2, 1),  # Assuming 200L tank
                    "fuel_consumed_liters": round(consumption_rate, 2),
                    "fuel_rate_lph": round(consumption_rate * 4, 2),  # Liters per hour
                    "engine_on": True,
                }
                self.fuel_readings.append(fuel_reading)

                current_time += timedelta(minutes=15)

    def _generate_maintenance_records(self):
        """Generate maintenance history"""
        print("  Generating maintenance records...")

        for vehicle in self.vehicles:
            # Generate historical maintenance
            current_odometer = vehicle["current_odometer_km"]
            last_service_odometer = vehicle["last_service_odometer_km"]

            # Oil changes
            oil_interval = self.config["maintenance"]["service_intervals"]["oil_change"]
            num_oil_changes = (current_odometer - 10000) // oil_interval

            for i in range(min(num_oil_changes, 10)):  # Limit history
                service_odometer = 10000 + (i * oil_interval)
                service_date = self.fake.date_between(
                    start_date="-2years", end_date="today"
                )

                maintenance = {
                    "maintenance_id": self.maintenance_id_counter,
                    "vehicle_id": vehicle["vehicle_id"],
                    "service_type": "oil_change",
                    "service_date": service_date,
                    "odometer_km": service_odometer,
                    "description": "Regular oil change and filter replacement",
                    "parts_replaced": "Oil filter, Engine oil",
                    "labor_hours": 0.5,
                    "parts_cost": 45.00,
                    "labor_cost": 50.00,
                    "total_cost": 95.00,
                    "performed_by": self.fake.name(),
                    "next_service_km": service_odometer + oil_interval,
                    "warranty": random.random() < 0.8,
                }
                self.maintenance_records.append(maintenance)
                self.maintenance_id_counter += 1

    def _generate_compliance_data(self):
        """Generate HOS and DVIR compliance data"""
        print("  Generating compliance data...")

        for trip in self.trips:
            driver = next(
                d for d in self.drivers if d["driver_id"] == trip["driver_id"]
            )
            vehicle = next(
                v for v in self.vehicles if v["vehicle_id"] == trip["vehicle_id"]
            )

            # Driver logs (simplified HOS)
            log = {
                "log_id": len(self.driver_logs) + 1,
                "driver_id": trip["driver_id"],
                "date": trip["start_time"].date(),
                "duty_start": trip["start_time"].replace(minute=0, second=0),
                "duty_end": trip["end_time"].replace(minute=0, second=0),
                "driving_hours": (trip["end_time"] - trip["start_time"]).total_seconds()
                / 3600,
                "on_duty_hours": (trip["end_time"] - trip["start_time"]).total_seconds()
                / 3600
                + 1,
                "off_duty_hours": 24
                - ((trip["end_time"] - trip["start_time"]).total_seconds() / 3600 + 1),
                "breaks_taken": random.randint(0, 2),
                "violations": "none",
                "eld_malfunction": random.random() < 0.02,
            }
            self.driver_logs.append(log)

            # DVIR (pre-trip inspection)
            if random.random() < self.config["compliance"]["dvir_completion_rate"]:
                dvir = {
                    "dvir_id": self.dvir_id_counter,
                    "vehicle_id": trip["vehicle_id"],
                    "driver_id": trip["driver_id"],
                    "trip_id": trip["trip_id"],
                    "inspection_type": "pre_trip",
                    "inspection_time": trip["start_time"] - timedelta(minutes=15),
                    "odometer_km": vehicle["current_odometer_km"],
                    "brakes": "pass",
                    "tires": "pass",
                    "lights": "pass",
                    "horn": "pass",
                    "mirrors": "pass",
                    "coupling": (
                        "pass" if vehicle["vehicle_type"] == "semi_truck" else "n/a"
                    ),
                    "emergency_equipment": "pass",
                    "defects_found": random.random() < 0.05,
                    "defect_description": (
                        "Minor tire wear" if random.random() < 0.05 else None
                    ),
                    "signature": driver["driver_name"],
                }
                self.dvir_reports.append(dvir)
                self.dvir_id_counter += 1

    # Helper methods
    def _get_city_coordinates(self, city_name: str) -> Tuple[float, float]:
        """Get approximate coordinates for major cities"""
        coords = {
            "New York": (40.7128, -74.0060),
            "Los Angeles": (34.0522, -118.2437),
            "Chicago": (41.8781, -87.6298),
            "Houston": (29.7604, -95.3698),
            "Phoenix": (33.4484, -112.0740),
            "Philadelphia": (39.9526, -75.1652),
            "San Antonio": (29.4241, -98.4936),
            "San Diego": (32.7157, -117.1611),
            "Dallas": (32.7767, -96.7970),
            "Atlanta": (33.7490, -84.3880),
        }
        return coords.get(city_name, (40.7128, -74.0060))

    def _generate_vin(self) -> str:
        """Generate a valid-looking VIN"""
        return "".join(random.choices("ABCDEFGHJKLMNPRSTUVWXYZ0123456789", k=17))

    def _generate_plate(self) -> str:
        """Generate a license plate number"""
        return f"{random.choice(['ABC', 'XYZ', 'DEF'])}-{random.randint(1000, 9999)}"

    def _get_vehicle_capacity(self, vehicle_type: str) -> int:
        """Get vehicle cargo capacity in kg"""
        capacities = {
            "delivery_van": 1500,
            "box_truck": 5000,
            "semi_truck": 20000,
            "refrigerated": 15000,
            "flatbed": 18000,
        }
        return capacities.get(vehicle_type, 5000)

    def _calculate_fuel_consumption(
        self, vehicle_type: str, distance_km: float
    ) -> float:
        """Calculate fuel consumption for a trip"""
        mpg_range = self.config["fuel_consumption"]["mpg_ranges"].get(
            vehicle_type, [10, 15]
        )
        mpg = random.uniform(mpg_range[0], mpg_range[1])
        liters_per_100km = 235.214 / mpg  # Convert MPG to L/100km
        return round((distance_km / 100) * liters_per_100km, 2)

    def _calculate_fuel_consumption_rate(self, vehicle_type: str) -> float:
        """Calculate fuel consumption rate in liters per 15 minutes"""
        mpg_range = self.config["fuel_consumption"]["mpg_ranges"].get(
            vehicle_type, [10, 15]
        )
        mpg = random.uniform(mpg_range[0], mpg_range[1])
        # Assuming average speed of 60 km/h
        km_per_15min = 15
        liters_per_100km = 235.214 / mpg
        return (km_per_15min / 100) * liters_per_100km

    def _get_event_value(self, event_type: str) -> float:
        """Get value for driver event"""
        values = {
            "harsh_brake": random.uniform(-8, -4),  # deceleration m/s²
            "harsh_acceleration": random.uniform(4, 8),  # acceleration m/s²
            "harsh_cornering": random.uniform(0.4, 0.8),  # lateral g-force
            "speeding": random.uniform(10, 30),  # km/h over limit
            "idle_excessive": random.uniform(10, 60),  # minutes
        }
        return round(values.get(event_type, 0), 2)

    def _get_diagnostic_value(self, parameter: str, vehicle_id: int) -> float:
        """Get diagnostic parameter value"""
        values = {
            "engine_rpm": random.gauss(2000, 500),
            "vehicle_speed": random.uniform(0, 120),
            "coolant_temp": random.gauss(90, 10),
            "fuel_level": random.uniform(10, 100),
            "oil_pressure": random.gauss(40, 5),
            "battery_voltage": random.gauss(14.2, 0.5),
            "engine_load": random.uniform(20, 80),
            "throttle_position": random.uniform(0, 100),
        }
        return round(values.get(parameter, 0), 2)

    def _get_parameter_unit(self, parameter: str) -> str:
        """Get unit for diagnostic parameter"""
        units = {
            "engine_rpm": "rpm",
            "vehicle_speed": "km/h",
            "coolant_temp": "°C",
            "fuel_level": "%",
            "oil_pressure": "psi",
            "battery_voltage": "V",
            "engine_load": "%",
            "throttle_position": "%",
        }
        return units.get(parameter, "")

    def _get_dtc_description(self, dtc_code: str) -> str:
        """Get description for diagnostic trouble code"""
        descriptions = {
            "P0300": "Random/Multiple Cylinder Misfire Detected",
            "P0171": "System Too Lean (Bank 1)",
            "P0420": "Catalyst System Efficiency Below Threshold",
            "P0442": "Evaporative Emission System Leak Detected",
            "P0128": "Coolant Thermostat Temperature Below Regulating Temperature",
        }
        return descriptions.get(dtc_code, "Generic fault code")

    def _write_all_csvs(self):
        """Write all data to CSV files"""
        datasets = [
            ("depots", self.depots),
            ("vehicles", self.vehicles),
            ("drivers", self.drivers),
            ("routes", self.routes),
            ("trips", self.trips),
            ("trip_stops", self.trip_stops),
            ("gps_positions", self.gps_positions[:10000]),  # Limit for file size
            ("driver_events", self.driver_events),
            ("engine_diagnostics", self.engine_diagnostics[:5000]),
            ("fuel_readings", self.fuel_readings[:5000]),
            ("maintenance_records", self.maintenance_records),
            ("dvir_reports", self.dvir_reports),
            ("driver_logs", self.driver_logs),
            ("diagnostic_codes", self.diagnostic_codes),
        ]

        for filename, data in datasets:
            if not data:
                continue

            filepath = self.output_dir / f"{filename}.csv"
            with open(filepath, "w", newline="", encoding="utf-8") as f:
                if data:
                    writer = csv.DictWriter(f, fieldnames=data[0].keys())
                    writer.writeheader()
                    writer.writerows(data)

            print(f"  [OK] Wrote {len(data)} records to {filename}.csv")

    def _generate_sql_scripts(self):
        """Generate SQL load scripts"""
        load_script = f"""-- Load generated Fleet Management data
-- Generated on {datetime.now()}

-- Clear existing data
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE gps_positions;
TRUNCATE TABLE driver_events;
TRUNCATE TABLE engine_diagnostics;
TRUNCATE TABLE fuel_readings;
TRUNCATE TABLE diagnostic_codes;
TRUNCATE TABLE trip_stops;
TRUNCATE TABLE trips;
TRUNCATE TABLE maintenance_records;
TRUNCATE TABLE dvir_reports;
TRUNCATE TABLE driver_logs;
TRUNCATE TABLE routes;
TRUNCATE TABLE drivers;
TRUNCATE TABLE vehicles;
TRUNCATE TABLE depots;
SET FOREIGN_KEY_CHECKS = 1;

-- Load data files
LOAD DATA INFILE '/var/lib/mysql-files/fleet/depots.csv'
INTO TABLE depots
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\\n'
IGNORE 1 ROWS;

LOAD DATA INFILE '/var/lib/mysql-files/fleet/vehicles.csv'
INTO TABLE vehicles
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\\n'
IGNORE 1 ROWS;

LOAD DATA INFILE '/var/lib/mysql-files/fleet/drivers.csv'
INTO TABLE drivers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\\n'
IGNORE 1 ROWS;

LOAD DATA INFILE '/var/lib/mysql-files/fleet/trips.csv'
INTO TABLE trips
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\\n'
IGNORE 1 ROWS;

LOAD DATA INFILE '/var/lib/mysql-files/fleet/gps_positions.csv'
INTO TABLE gps_positions
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\\n'
IGNORE 1 ROWS;

-- Update statistics
ANALYZE TABLE vehicles, drivers, trips, gps_positions;

SELECT 'Data load complete!' as status;
SELECT COUNT(*) as vehicle_count FROM vehicles;
SELECT COUNT(*) as driver_count FROM drivers;
SELECT COUNT(*) as trip_count FROM trips;
SELECT COUNT(*) as gps_count FROM gps_positions;
"""

        script_path = self.output_dir / "load_data.sql"
        with open(script_path, "w") as f:
            f.write(load_script)

        print(f"  [OK] Generated SQL load script: load_data.sql")


def main():
    parser = argparse.ArgumentParser(description="Generate Fleet Management data")
    parser.add_argument("--config", default="config.yaml", help="Path to config.yaml")
    args = parser.parse_args()

    generator = FleetManagementGenerator(args.config)
    generator.generate_all()


if __name__ == "__main__":
    main()
