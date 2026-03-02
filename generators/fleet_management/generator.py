#!/usr/bin/env python3
"""
Fleet Management System Data Generator
Generates realistic data for vehicle fleet tracking with GPS, compliance, and telematics
"""

import csv
import json
import random
import hashlib
from datetime import datetime, timedelta, date, time
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
    "companies": 3,
    "depots_per_company": 4,
    "vehicles_per_company": 20,
    "drivers_per_company": 25,
    "days_of_history": 7,  # One week for GPS data
    "gps_interval_seconds": 5,  # GPS tracking every 5 seconds as per requirements
    "trips_per_vehicle_per_day": 3,
    "routes": 15,
    "geofences": 20,
}


class FleetManagementGenerator:
    def __init__(self):
        # Core entities
        self.companies: List[Any] = []
        self.depots: List[Any] = []
        self.vehicles: List[Any] = []
        self.vehicle_specs: List[Any] = []
        self.drivers: List[Any] = []
        self.driver_certifications: List[Any] = []

        # GPS and tracking
        self.gps_positions: List[Any] = []
        self.trips: List[Any] = []
        self.stops: List[Any] = []
        self.routes: List[Any] = []
        self.geofences: List[Any] = []
        self.geofence_events: List[Any] = []

        # Operations
        self.fuel_transactions: List[Any] = []
        self.maintenance_records: List[Any] = []
        self.vehicle_diagnostics: List[Any] = []

        # Compliance
        self.driver_logs: List[Any] = []
        self.hos_violations: List[Any] = []
        self.dvir_reports: List[Any] = []
        self.driver_events: List[Any] = []
        self.driver_scores: List[Any] = []

        # Communications
        self.messages: List[Any] = []

        # Analytics
        self.vehicle_daily_summary: List[Any] = []

        # Counters
        self.depot_id = 0
        self.vehicle_id = 0
        self.spec_id = 0
        self.driver_id = 0
        self.cert_id = 0
        self.position_id = 0
        self.trip_id = 0
        self.stop_id = 0
        self.route_id = 0
        self.geofence_id = 0
        self.geofence_event_id = 0
        self.fuel_id = 0
        self.maintenance_id = 0
        self.diagnostic_id = 0
        self.log_id = 0
        self.violation_id = 0
        self.dvir_id = 0
        self.event_id = 0
        self.score_id = 0
        self.message_id = 0
        self.summary_id = 0

        # Start date for historical data
        self.start_date = datetime.now() - timedelta(days=CONFIG["days_of_history"])

    def generate_all(self):
        """Generate all fleet management data"""
        print("Starting Fleet Management Data Generation...")
        print(f"Configuration:")
        print(f"  Companies: {CONFIG['companies']}")
        print(
            f"  Total vehicles: {CONFIG['companies'] * CONFIG['vehicles_per_company']}"
        )
        print(f"  Total drivers: {CONFIG['companies'] * CONFIG['drivers_per_company']}")
        print(f"  GPS interval: {CONFIG['gps_interval_seconds']} seconds")
        print(f"  Days of history: {CONFIG['days_of_history']}")

        # Core infrastructure
        self.generate_companies()
        self.generate_depots()
        self.generate_vehicles()
        self.generate_vehicle_specs()
        self.generate_drivers()
        self.generate_driver_certifications()

        # Routes and geofences
        self.generate_routes()
        self.generate_geofences()

        # Generate trips and GPS data
        self.generate_trips_and_gps()

        # Operations
        self.generate_fuel_transactions()
        self.generate_maintenance_records()
        self.generate_vehicle_diagnostics()

        # Compliance
        self.generate_driver_logs()
        self.generate_hos_violations()
        self.generate_dvir_reports()
        self.generate_driver_events()
        self.generate_driver_scores()

        # Communications
        self.generate_messages()

        # Analytics
        self.generate_vehicle_daily_summary()

        # Save all data
        self.save_all()

    def generate_companies(self):
        """Generate company data"""
        print(f"Generating {CONFIG['companies']} companies...")

        company_names = [
            "TransLogistics Corp",
            "Fleet Express LLC",
            "Rapid Delivery Systems",
        ]

        for i in range(CONFIG["companies"]):
            self.companies.append(
                {
                    "company_id": i + 1,
                    "company_name": (
                        company_names[i]
                        if i < len(company_names)
                        else f"Transport Co {i+1}"
                    ),
                    "dot_number": f"DOT{random.randint(1000000, 9999999)}",
                    "mc_number": f"MC{random.randint(100000, 999999)}",
                    "address": fake.street_address(),
                    "city": fake.city(),
                    "state": fake.state_abbr(),
                    "zip_code": fake.zipcode(),
                    "country": "USA",
                    "phone": fake.phone_number()[:20],
                    "email": fake.company_email(),
                    "created_at": datetime.now(),
                }
            )

    def generate_depots(self):
        """Generate depot/terminal locations"""
        print("Generating depots...")

        depot_types = [
            "Main Hub",
            "Regional Center",
            "Distribution Center",
            "Service Terminal",
        ]

        for company in self.companies:
            for j in range(CONFIG["depots_per_company"]):
                self.depot_id += 1

                # Generate depot locations across the US
                lat = random.uniform(25, 48)  # Continental US latitude range
                lng = random.uniform(-125, -65)  # Continental US longitude range

                self.depots.append(
                    {
                        "depot_id": self.depot_id,
                        "company_id": company["company_id"],
                        "depot_name": f"{fake.city()} {depot_types[j % len(depot_types)]}",
                        "depot_code": f"DEP{self.depot_id:03d}",
                        "address": fake.street_address(),
                        "city": fake.city(),
                        "state": fake.state_abbr(),
                        "latitude": round(lat, 6),
                        "longitude": round(lng, 6),
                        "timezone": random.choice(
                            [
                                "America/New_York",
                                "America/Chicago",
                                "America/Denver",
                                "America/Los_Angeles",
                            ]
                        ),
                        "is_active": True,
                        "created_at": datetime.now(),
                    }
                )

    def generate_vehicles(self):
        """Generate vehicle fleet"""
        print("Generating vehicles...")

        vehicle_types = [
            "delivery_van",
            "box_truck",
            "semi_truck",
            "refrigerated",
            "flatbed",
        ]
        makes = [
            "Freightliner",
            "Volvo",
            "Peterbilt",
            "Kenworth",
            "International",
            "Mercedes-Benz",
            "Ford",
            "Isuzu",
        ]
        fuel_types = ["diesel", "diesel", "diesel", "gasoline", "electric", "hybrid"]

        for company in self.companies:
            company_depots = [
                d for d in self.depots if d["company_id"] == company["company_id"]
            ]

            for v in range(CONFIG["vehicles_per_company"]):
                self.vehicle_id += 1

                vehicle_type = random.choice(vehicle_types)
                make = random.choice(makes)
                year = random.randint(2018, 2024)

                # Calculate mileage based on age
                age_years = 2024 - year
                base_miles = age_years * random.uniform(40000, 80000)

                purchase_date = date(year, random.randint(1, 12), random.randint(1, 28))

                self.vehicles.append(
                    {
                        "vehicle_id": self.vehicle_id,
                        "company_id": company["company_id"],
                        "depot_id": random.choice(company_depots)["depot_id"],
                        "vehicle_number": f"VEH{company['company_id']:02d}{v+1:03d}",
                        "vin": self.generate_vin(),
                        "license_plate": self.generate_license_plate(),
                        "vehicle_type": vehicle_type,
                        "make": make,
                        "model": f"Model {random.choice(['T680', 'VNL', '579', 'Cascadia'])}",
                        "year": year,
                        "color": random.choice(
                            ["White", "Blue", "Red", "Gray", "Black"]
                        ),
                        "fuel_type": random.choice(fuel_types),
                        "fuel_capacity_gallons": random.uniform(50, 300),
                        "odometer_miles": round(base_miles, 1),
                        "engine_hours": round(base_miles / 45, 1),  # Avg 45 mph
                        "purchase_date": purchase_date,
                        "registration_expiry": purchase_date.replace(
                            year=purchase_date.year + 1
                        ),
                        "insurance_expiry": purchase_date.replace(
                            year=purchase_date.year + 1
                        ),
                        "last_service_date": fake.date_between(
                            start_date="-30d", end_date="today"
                        ),
                        "last_service_miles": round(
                            base_miles - random.uniform(3000, 5000), 1
                        ),
                        "next_service_miles": round(
                            base_miles + random.uniform(5000, 10000), 1
                        ),
                        "status": random.choices(
                            ["active", "maintenance", "inactive"],
                            weights=[0.85, 0.1, 0.05],
                        )[0],
                        "created_at": purchase_date,
                    }
                )

    def generate_vin(self):
        """Generate a realistic VIN"""
        vin = "".join(random.choices("0123456789ABCDEFGHJKLMNPRSTUVWXYZ", k=17))
        return vin

    def generate_license_plate(self):
        """Generate a realistic license plate"""
        return f"{fake.state_abbr()}-{''.join(random.choices('0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ', k=6))}"

    def generate_vehicle_specs(self):
        """Generate vehicle specifications"""
        print("Generating vehicle specifications...")

        for vehicle in self.vehicles:
            self.spec_id += 1

            # Specs based on vehicle type
            if vehicle["vehicle_type"] == "semi_truck":
                gvw = random.randint(60000, 80000)
                cargo_cap = random.randint(40000, 50000)
                cargo_vol = random.uniform(2000, 3000)
                mpg_city = random.uniform(5, 7)
                mpg_highway = random.uniform(6, 9)
            elif vehicle["vehicle_type"] == "box_truck":
                gvw = random.randint(20000, 33000)
                cargo_cap = random.randint(10000, 20000)
                cargo_vol = random.uniform(800, 1500)
                mpg_city = random.uniform(7, 10)
                mpg_highway = random.uniform(10, 14)
            else:  # delivery_van
                gvw = random.randint(8000, 12000)
                cargo_cap = random.randint(3000, 5000)
                cargo_vol = random.uniform(300, 600)
                mpg_city = random.uniform(12, 16)
                mpg_highway = random.uniform(16, 22)

            self.vehicle_specs.append(
                {
                    "spec_id": self.spec_id,
                    "vehicle_id": vehicle["vehicle_id"],
                    "gross_vehicle_weight_lbs": gvw,
                    "cargo_capacity_lbs": cargo_cap,
                    "cargo_volume_cubic_ft": round(cargo_vol, 2),
                    "mpg_city": round(mpg_city, 2),
                    "mpg_highway": round(mpg_highway, 2),
                    "has_gps": True,
                    "has_eld": vehicle["vehicle_type"] in ["semi_truck", "box_truck"],
                    "has_camera": random.random() < 0.6,
                    "has_temperature_control": vehicle["vehicle_type"]
                    == "refrigerated",
                    "has_liftgate": random.random() < 0.3,
                }
            )

    def generate_drivers(self):
        """Generate driver data"""
        print("Generating drivers...")

        license_classes = ["regular", "CDL_A", "CDL_B"]
        statuses = ["active", "active", "active", "on_leave", "inactive"]

        for company in self.companies:
            for d in range(CONFIG["drivers_per_company"]):
                self.driver_id += 1

                hire_date = fake.date_between(start_date="-5y", end_date="today")
                birth_date = fake.date_of_birth(minimum_age=21, maximum_age=65)
                license_expiry = fake.date_between(start_date="today", end_date="+3y")
                medical_cert_expiry = fake.date_between(
                    start_date="today", end_date="+2y"
                )

                self.drivers.append(
                    {
                        "driver_id": self.driver_id,
                        "company_id": company["company_id"],
                        "employee_id": f"EMP{company['company_id']:02d}{d+1:04d}",
                        "first_name": fake.first_name(),
                        "last_name": fake.last_name(),
                        "email": fake.email(),
                        "phone": fake.phone_number()[:20],
                        "license_number": f"DL{fake.state_abbr()}{random.randint(1000000, 9999999)}",
                        "license_state": fake.state_abbr(),
                        "license_class": random.choice(license_classes),
                        "license_expiry": license_expiry,
                        "medical_cert_expiry": medical_cert_expiry,
                        "hire_date": hire_date,
                        "birth_date": birth_date,
                        "address": fake.street_address(),
                        "city": fake.city(),
                        "state": fake.state_abbr(),
                        "zip_code": fake.zipcode(),
                        "emergency_contact": fake.name(),
                        "emergency_phone": fake.phone_number()[:20],
                        "years_experience": random.randint(1, 20),
                        "status": random.choice(statuses),
                        "created_at": hire_date,
                    }
                )

    def generate_driver_certifications(self):
        """Generate driver certifications"""
        print("Generating driver certifications...")

        cert_types = ["HAZMAT", "Tanker", "Double/Triple", "Passenger", "School Bus"]

        for driver in self.drivers:
            if driver["license_class"].startswith("CDL"):
                # CDL drivers have 1-3 certifications
                num_certs = random.randint(1, 3)
                selected_certs = random.sample(cert_types, num_certs)

                for cert_type in selected_certs:
                    self.cert_id += 1

                    issue_date = driver["hire_date"]
                    expiry_date = issue_date + timedelta(days=random.randint(365, 1095))

                    self.driver_certifications.append(
                        {
                            "certification_id": self.cert_id,
                            "driver_id": driver["driver_id"],
                            "certification_type": cert_type,
                            "certification_number": f"CERT{self.cert_id:06d}",
                            "issue_date": issue_date,
                            "expiry_date": expiry_date,
                            "issuing_authority": f"{driver['license_state']} DMV",
                            "is_active": expiry_date > date.today(),
                            "created_at": issue_date,
                        }
                    )

    def generate_routes(self):
        """Generate predefined routes"""
        print(f"Generating {CONFIG['routes']} routes...")

        route_types = ["local", "regional", "long_haul"]

        for i in range(CONFIG["routes"]):
            self.route_id += 1

            # Select random depots as start and end points
            start_depot = random.choice(self.depots)
            end_depot = random.choice(self.depots)

            # Calculate distance (simplified)
            distance = self.calculate_distance(
                start_depot["latitude"],
                start_depot["longitude"],
                end_depot["latitude"],
                end_depot["longitude"],
            )

            # Determine route type based on distance
            if distance < 100:
                route_type = "local"
            elif distance < 500:
                route_type = "regional"
            else:
                route_type = "long_haul"

            self.routes.append(
                {
                    "route_id": self.route_id,
                    "route_name": f"{start_depot['city']} to {end_depot['city']}",
                    "route_code": f"RT{self.route_id:03d}",
                    "origin_depot_id": start_depot["depot_id"],
                    "destination_depot_id": end_depot["depot_id"],
                    "distance_miles": round(distance, 1),
                    "estimated_hours": round(distance / 50, 1),  # Avg 50 mph
                    "route_type": route_type,
                    "toll_cost": (
                        round(distance * 0.05, 2) if random.random() < 0.3 else 0
                    ),
                    "is_active": True,
                    "created_at": datetime.now(),
                }
            )

    def calculate_distance(self, lat1, lon1, lat2, lon2):
        """Calculate distance between two points (Haversine formula)"""
        R = 3959  # Earth's radius in miles

        lat1_rad = math.radians(lat1)
        lat2_rad = math.radians(lat2)
        dlat = math.radians(lat2 - lat1)
        dlon = math.radians(lon2 - lon1)

        a = (
            math.sin(dlat / 2) ** 2
            + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(dlon / 2) ** 2
        )
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

        return R * c

    def generate_geofences(self):
        """Generate geofence zones"""
        print(f"Generating {CONFIG['geofences']} geofences...")

        geofence_types = [
            "depot",
            "customer",
            "rest_area",
            "fuel_station",
            "restricted",
        ]

        # Create geofences around depots
        for depot in self.depots:
            self.geofence_id += 1

            self.geofences.append(
                {
                    "geofence_id": self.geofence_id,
                    "company_id": depot["company_id"],
                    "geofence_name": f"{depot['depot_name']} Zone",
                    "geofence_type": "depot",
                    "center_latitude": depot["latitude"],
                    "center_longitude": depot["longitude"],
                    "radius_meters": 500,
                    "polygon_coordinates": None,
                    "is_active": True,
                    "alert_on_enter": True,
                    "alert_on_exit": True,
                    "created_at": datetime.now(),
                }
            )

        # Create additional customer/fuel station geofences
        remaining = CONFIG["geofences"] - len(self.depots)
        for _ in range(remaining):
            self.geofence_id += 1

            lat = random.uniform(25, 48)
            lng = random.uniform(-125, -65)
            geofence_type = random.choice(["customer", "fuel_station", "rest_area"])

            self.geofences.append(
                {
                    "geofence_id": self.geofence_id,
                    "company_id": random.choice(self.companies)["company_id"],
                    "geofence_name": f"{fake.company()} - {geofence_type.replace('_', ' ').title()}",
                    "geofence_type": geofence_type,
                    "center_latitude": round(lat, 6),
                    "center_longitude": round(lng, 6),
                    "radius_meters": random.randint(100, 1000),
                    "polygon_coordinates": None,
                    "is_active": True,
                    "alert_on_enter": True,
                    "alert_on_exit": geofence_type == "customer",
                    "created_at": datetime.now(),
                }
            )

    def generate_trips_and_gps(self):
        """Generate trips and GPS tracking data"""
        print("Generating trips and GPS tracking data (this may take a while)...")

        current_date = self.start_date.date()
        end_date = datetime.now().date()

        while current_date <= end_date:
            for vehicle in self.vehicles:
                if vehicle["status"] != "active":
                    continue

                # Get available drivers for this company
                available_drivers = [
                    d
                    for d in self.drivers
                    if d["company_id"] == vehicle["company_id"]
                    and d["status"] == "active"
                ]

                if not available_drivers:
                    continue

                # Generate trips for this day
                num_trips = random.randint(1, CONFIG["trips_per_vehicle_per_day"])

                for trip_num in range(num_trips):
                    self.trip_id += 1

                    # Select driver and route
                    driver = random.choice(available_drivers)
                    route = random.choice(self.routes)

                    # Calculate trip timing
                    start_hour = 6 + trip_num * 5  # Space trips throughout the day
                    start_time = datetime.combine(
                        current_date, time(start_hour, random.randint(0, 59))
                    )
                    duration_hours = route["estimated_hours"] * random.uniform(0.9, 1.2)
                    end_time = start_time + timedelta(hours=duration_hours)

                    # Calculate distance and fuel
                    actual_distance = route["distance_miles"] * random.uniform(
                        0.95, 1.1
                    )
                    spec = next(
                        (
                            s
                            for s in self.vehicle_specs
                            if s["vehicle_id"] == vehicle["vehicle_id"]
                        ),
                        None,
                    )
                    fuel_used = (
                        actual_distance / spec["mpg_highway"]
                        if spec
                        else actual_distance / 7
                    )

                    # Determine trip status
                    if end_time.date() < datetime.now().date():
                        status = "completed"
                    elif start_time < datetime.now():
                        status = "in_progress"
                    else:
                        status = "scheduled"

                    trip = {
                        "trip_id": self.trip_id,
                        "vehicle_id": vehicle["vehicle_id"],
                        "driver_id": driver["driver_id"],
                        "route_id": route["route_id"],
                        "start_time": start_time,
                        "end_time": end_time if status == "completed" else None,
                        "start_location": f"{route['origin_depot_id']} depot",
                        "end_location": f"{route['destination_depot_id']} depot",
                        "distance_miles": round(actual_distance, 1),
                        "fuel_used_gallons": round(fuel_used, 2),
                        "average_speed_mph": round(actual_distance / duration_hours, 1),
                        "max_speed_mph": round(65 + random.uniform(0, 15), 1),
                        "idle_time_minutes": random.randint(10, 60),
                        "drive_time_minutes": int(duration_hours * 60),
                        "status": status,
                        "created_at": start_time,
                    }
                    self.trips.append(trip)

                    # Generate GPS positions for this trip (5-second intervals)
                    if status in ["completed", "in_progress"]:
                        self.generate_gps_positions_for_trip(
                            trip, route, start_time, end_time
                        )

                    # Generate stops for this trip
                    self.generate_stops_for_trip(trip, start_time, duration_hours)

            current_date += timedelta(days=1)

    def generate_gps_positions_for_trip(self, trip, route, start_time, end_time):
        """Generate GPS positions for a specific trip at 5-second intervals"""
        # Get depot locations
        origin_depot = next(
            d for d in self.depots if d["depot_id"] == route["origin_depot_id"]
        )
        dest_depot = next(
            d for d in self.depots if d["depot_id"] == route["destination_depot_id"]
        )

        # Current position starts at origin
        current_lat = origin_depot["latitude"]
        current_lng = origin_depot["longitude"]

        # Calculate total seconds and positions needed
        if trip["status"] == "completed":
            total_seconds = int((end_time - start_time).total_seconds())
        else:
            # For in-progress trips, generate up to current time
            total_seconds = int((datetime.now() - start_time).total_seconds())

        num_positions = min(
            total_seconds // CONFIG["gps_interval_seconds"], 10000
        )  # Limit for performance

        # Calculate movement per position
        lat_diff = (
            (dest_depot["latitude"] - origin_depot["latitude"]) / num_positions
            if num_positions > 0
            else 0
        )
        lng_diff = (
            (dest_depot["longitude"] - origin_depot["longitude"]) / num_positions
            if num_positions > 0
            else 0
        )

        for i in range(0, num_positions, 20):  # Sample every 100 seconds for demo
            self.position_id += 1

            timestamp = start_time + timedelta(
                seconds=i * CONFIG["gps_interval_seconds"]
            )

            # Add some random variation to simulate actual driving
            current_lat += lat_diff * 20 + random.uniform(-0.0001, 0.0001)
            current_lng += lng_diff * 20 + random.uniform(-0.0001, 0.0001)

            # Calculate speed (varies throughout trip)
            base_speed = trip["average_speed_mph"]
            current_speed = base_speed + random.uniform(-10, 10)
            current_speed = max(0, min(current_speed, trip["max_speed_mph"]))

            self.gps_positions.append(
                {
                    "position_id": self.position_id,
                    "vehicle_id": trip["vehicle_id"],
                    "trip_id": trip["trip_id"],
                    "timestamp": timestamp,
                    "latitude": round(current_lat, 6),
                    "longitude": round(current_lng, 6),
                    "altitude_meters": random.randint(0, 2000),
                    "speed_mph": round(current_speed, 1),
                    "heading_degrees": random.randint(0, 359),
                    "accuracy_meters": random.uniform(3, 10),
                    "engine_on": current_speed > 0,
                    "created_at": timestamp,
                }
            )

            # Check for geofence events
            self.check_geofence_events(
                trip["vehicle_id"], current_lat, current_lng, timestamp
            )

    def generate_stops_for_trip(self, trip, start_time, duration_hours):
        """Generate stops during a trip"""
        # Number of stops based on trip duration
        num_stops = int(duration_hours / 3)  # Approximately one stop every 3 hours

        for i in range(num_stops):
            self.stop_id += 1

            # Calculate stop timing
            stop_offset = (i + 1) * duration_hours / (num_stops + 1)
            arrival_time = start_time + timedelta(hours=stop_offset)
            stop_duration = random.randint(15, 45)  # 15-45 minutes
            departure_time = arrival_time + timedelta(minutes=stop_duration)

            stop_types = ["fuel", "rest", "delivery", "pickup", "break"]

            self.stops.append(
                {
                    "stop_id": self.stop_id,
                    "trip_id": trip["trip_id"],
                    "stop_type": random.choice(stop_types),
                    "arrival_time": arrival_time,
                    "departure_time": departure_time,
                    "duration_minutes": stop_duration,
                    "location_name": f"{fake.company()} - {fake.city()}",
                    "latitude": random.uniform(25, 48),
                    "longitude": random.uniform(-125, -65),
                    "notes": None,
                    "created_at": arrival_time,
                }
            )

    def check_geofence_events(self, vehicle_id, lat, lng, timestamp):
        """Check if vehicle entered/exited any geofences"""
        for geofence in self.geofences[:10]:  # Check first 10 geofences for demo
            # Simple distance check (should use proper geofence algorithm)
            distance = (
                self.calculate_distance(
                    lat, lng, geofence["center_latitude"], geofence["center_longitude"]
                )
                * 1609.34
            )  # Convert miles to meters

            if (
                distance < geofence["radius_meters"] and random.random() < 0.01
            ):  # Reduced frequency
                self.geofence_event_id += 1

                self.geofence_events.append(
                    {
                        "event_id": self.geofence_event_id,
                        "geofence_id": geofence["geofence_id"],
                        "vehicle_id": vehicle_id,
                        "event_type": random.choice(["enter", "exit"]),
                        "timestamp": timestamp,
                        "latitude": round(lat, 6),
                        "longitude": round(lng, 6),
                        "created_at": timestamp,
                    }
                )

    def generate_fuel_transactions(self):
        """Generate fuel transactions"""
        print("Generating fuel transactions...")

        for trip in self.trips:
            if (
                trip["status"] == "completed" and random.random() < 0.3
            ):  # 30% of trips have fuel stops
                self.fuel_id += 1

                vehicle = next(
                    v for v in self.vehicles if v["vehicle_id"] == trip["vehicle_id"]
                )

                self.fuel_transactions.append(
                    {
                        "transaction_id": self.fuel_id,
                        "vehicle_id": trip["vehicle_id"],
                        "driver_id": trip["driver_id"],
                        "transaction_date": trip["start_time"].date(),
                        "fuel_station_name": f"{random.choice(['Shell', 'Exxon', 'BP', 'Chevron'])} #{random.randint(100, 999)}",
                        "location": fake.city() + ", " + fake.state_abbr(),
                        "gallons": round(
                            random.uniform(20, vehicle["fuel_capacity_gallons"] * 0.8),
                            2,
                        ),
                        "price_per_gallon": round(random.uniform(3.50, 4.50), 2),
                        "total_cost": 0,  # Will be calculated
                        "odometer_reading": vehicle["odometer_miles"]
                        + trip["distance_miles"],
                        "payment_method": random.choice(
                            ["Company Card", "Fleet Card", "Cash"]
                        ),
                        "created_at": trip["start_time"],
                    }
                )

                # Calculate total cost
                self.fuel_transactions[-1]["total_cost"] = round(
                    self.fuel_transactions[-1]["gallons"]
                    * self.fuel_transactions[-1]["price_per_gallon"],
                    2,
                )

    def generate_maintenance_records(self):
        """Generate maintenance records"""
        print("Generating maintenance records...")

        maintenance_types = [
            "Oil Change",
            "Tire Rotation",
            "Brake Service",
            "Filter Replacement",
            "Inspection",
            "Transmission Service",
            "Cooling System",
            "Electrical",
        ]

        for vehicle in self.vehicles:
            # 2-5 maintenance records per vehicle
            num_records = random.randint(2, 5)

            for _ in range(num_records):
                self.maintenance_id += 1

                service_date = fake.date_between(start_date="-6m", end_date="today")

                self.maintenance_records.append(
                    {
                        "maintenance_id": self.maintenance_id,
                        "vehicle_id": vehicle["vehicle_id"],
                        "service_date": service_date,
                        "service_type": random.choice(maintenance_types),
                        "description": f"Routine {random.choice(maintenance_types).lower()}",
                        "odometer_reading": vehicle["odometer_miles"]
                        - random.uniform(1000, 10000),
                        "performed_by": fake.company(),
                        "cost": round(random.uniform(100, 2000), 2),
                        "next_service_miles": vehicle["odometer_miles"]
                        + random.uniform(5000, 15000),
                        "next_service_date": service_date
                        + timedelta(days=random.randint(60, 180)),
                        "warranty_claim": random.random() < 0.1,
                        "notes": None,
                        "created_at": service_date,
                    }
                )

    def generate_vehicle_diagnostics(self):
        """Generate vehicle diagnostic data"""
        print("Generating vehicle diagnostics...")

        for vehicle in self.vehicles:
            if vehicle["status"] == "active":
                # Generate daily diagnostics for last week
                current = self.start_date

                while current <= datetime.now():
                    self.diagnostic_id += 1

                    self.vehicle_diagnostics.append(
                        {
                            "diagnostic_id": self.diagnostic_id,
                            "vehicle_id": vehicle["vehicle_id"],
                            "timestamp": current,
                            "engine_rpm": random.randint(600, 2000),
                            "engine_temp_f": random.randint(180, 210),
                            "oil_pressure_psi": random.randint(25, 65),
                            "coolant_temp_f": random.randint(180, 205),
                            "battery_voltage": round(random.uniform(12.5, 14.5), 1),
                            "fuel_level_percent": random.randint(20, 100),
                            "def_level_percent": (
                                random.randint(30, 100)
                                if vehicle["fuel_type"] == "diesel"
                                else None
                            ),
                            "tire_pressure_psi": json.dumps(
                                {
                                    "front_left": random.randint(95, 110),
                                    "front_right": random.randint(95, 110),
                                    "rear_left": random.randint(95, 110),
                                    "rear_right": random.randint(95, 110),
                                }
                            ),
                            "fault_codes": (
                                None
                                if random.random() > 0.1
                                else f"P{random.randint(1000, 9999)}"
                            ),
                            "created_at": current,
                        }
                    )

                    current += timedelta(hours=12)

    def generate_driver_logs(self):
        """Generate driver HOS (Hours of Service) logs"""
        print("Generating driver logs...")

        log_types = ["driving", "on_duty", "off_duty", "sleeper"]

        for driver in self.drivers:
            if driver["status"] == "active":
                current = self.start_date.date()

                while current <= date.today():
                    # Generate daily log entries
                    daily_hours = 0
                    current_time = datetime.combine(current, time(0, 0))

                    while daily_hours < 24:
                        self.log_id += 1

                        log_type = random.choice(log_types)
                        if log_type == "driving":
                            duration = random.uniform(
                                1, 4
                            )  # Max 4 hours continuous driving
                        elif log_type == "sleeper":
                            duration = random.uniform(6, 10)  # Sleep periods
                        else:
                            duration = random.uniform(0.5, 3)

                        # Don't exceed 24 hours
                        duration = min(duration, 24 - daily_hours)

                        self.driver_logs.append(
                            {
                                "log_id": self.log_id,
                                "driver_id": driver["driver_id"],
                                "log_date": current,
                                "start_time": current_time,
                                "end_time": current_time + timedelta(hours=duration),
                                "activity_type": log_type,
                                "duration_hours": round(duration, 2),
                                "location": fake.city() + ", " + fake.state_abbr(),
                                "vehicle_id": random.choice(
                                    [
                                        v["vehicle_id"]
                                        for v in self.vehicles
                                        if v["company_id"] == driver["company_id"]
                                    ]
                                ),
                                "notes": None,
                                "created_at": current_time,
                            }
                        )

                        daily_hours += duration
                        current_time += timedelta(hours=duration)

                    current += timedelta(days=1)

    def generate_hos_violations(self):
        """Generate HOS violations"""
        print("Generating HOS violations...")

        violation_types = [
            "11_hour_driving",
            "14_hour_on_duty",
            "30_minute_break",
            "60_hour_7_day",
            "70_hour_8_day",
        ]

        for driver in self.drivers:
            if random.random() < 0.2:  # 20% of drivers have violations
                num_violations = random.randint(1, 3)

                for _ in range(num_violations):
                    self.violation_id += 1

                    violation_date = fake.date_between(
                        start_date=self.start_date, end_date="today"
                    )

                    self.hos_violations.append(
                        {
                            "violation_id": self.violation_id,
                            "driver_id": driver["driver_id"],
                            "violation_date": violation_date,
                            "violation_type": random.choice(violation_types),
                            "duration_minutes": random.randint(15, 120),
                            "severity": random.choice(["minor", "major", "critical"]),
                            "description": f"Driver exceeded {random.choice(violation_types).replace('_', ' ')} limit",
                            "corrective_action": random.choice(
                                ["Warning issued", "Training required", "Suspension"]
                            ),
                            "created_at": violation_date,
                        }
                    )

    def generate_dvir_reports(self):
        """Generate Driver Vehicle Inspection Reports"""
        print("Generating DVIR reports...")

        defect_items = [
            "Brakes",
            "Tires",
            "Lights",
            "Horn",
            "Mirrors",
            "Windshield",
            "Coupling Devices",
            "Emergency Equipment",
        ]

        for trip in self.trips:
            if trip["status"] == "completed":
                self.dvir_id += 1

                has_defects = random.random() < 0.1  # 10% have defects

                self.dvir_reports.append(
                    {
                        "report_id": self.dvir_id,
                        "vehicle_id": trip["vehicle_id"],
                        "driver_id": trip["driver_id"],
                        "inspection_date": trip["start_time"].date(),
                        "inspection_type": "pre_trip",
                        "odometer_reading": random.randint(50000, 200000),
                        "has_defects": has_defects,
                        "defects_json": (
                            json.dumps(
                                {
                                    "defects": random.sample(
                                        defect_items, random.randint(1, 3)
                                    )
                                }
                            )
                            if has_defects
                            else None
                        ),
                        "driver_signature": f"DSig_{trip['driver_id']}",
                        "mechanic_signature": (
                            f"MSig_{random.randint(1, 10)}" if has_defects else None
                        ),
                        "repair_date": (
                            trip["start_time"].date() if has_defects else None
                        ),
                        "created_at": trip["start_time"],
                    }
                )

    def generate_driver_events(self):
        """Generate driver events (harsh braking, acceleration, etc.)"""
        print("Generating driver events...")

        event_types = ["harsh_brake", "harsh_acceleration", "harsh_turn", "speeding"]

        for trip in self.trips[:100]:  # Limit for demo
            if trip["status"] == "completed":
                # Generate 0-5 events per trip
                num_events = random.randint(0, 5)

                for _ in range(num_events):
                    self.event_id += 1

                    event_time = trip["start_time"] + timedelta(
                        minutes=random.randint(0, trip["drive_time_minutes"])
                    )

                    self.driver_events.append(
                        {
                            "event_id": self.event_id,
                            "driver_id": trip["driver_id"],
                            "vehicle_id": trip["vehicle_id"],
                            "trip_id": trip["trip_id"],
                            "event_type": random.choice(event_types),
                            "event_time": event_time,
                            "severity": random.choice(["low", "medium", "high"]),
                            "speed_mph": random.randint(45, 80),
                            "g_force": round(random.uniform(0.3, 0.8), 2),
                            "latitude": random.uniform(25, 48),
                            "longitude": random.uniform(-125, -65),
                            "created_at": event_time,
                        }
                    )

    def generate_driver_scores(self):
        """Generate driver safety scores"""
        print("Generating driver scores...")

        for driver in self.drivers:
            if driver["status"] == "active":
                # Monthly scores
                current = self.start_date.replace(day=1)

                while current <= datetime.now():
                    self.score_id += 1

                    # Calculate scores based on events
                    driver_events = [
                        e
                        for e in self.driver_events
                        if e["driver_id"] == driver["driver_id"]
                    ]
                    base_score = 85
                    safety_score = max(0, base_score - len(driver_events) * 2)

                    self.driver_scores.append(
                        {
                            "score_id": self.score_id,
                            "driver_id": driver["driver_id"],
                            "score_date": current.date(),
                            "safety_score": min(
                                100, safety_score + random.randint(-5, 10)
                            ),
                            "fuel_efficiency_score": random.randint(70, 95),
                            "compliance_score": random.randint(80, 100),
                            "overall_score": random.randint(75, 95),
                            "total_miles": random.randint(5000, 15000),
                            "total_trips": random.randint(20, 80),
                            "total_events": len(driver_events),
                            "created_at": current,
                        }
                    )

                    current = (current + timedelta(days=32)).replace(day=1)

    def generate_messages(self):
        """Generate driver-dispatcher messages"""
        print("Generating messages...")

        message_types = ["dispatch", "alert", "info", "emergency"]
        subjects = [
            "New assignment",
            "Route change",
            "Weather alert",
            "Delivery update",
            "Break reminder",
            "Maintenance required",
        ]

        for _ in range(200):  # Generate 200 messages
            self.message_id += 1

            sender_driver = random.choice(self.drivers)
            recipient_driver = random.choice(
                [
                    d
                    for d in self.drivers
                    if d["company_id"] == sender_driver["company_id"]
                ]
            )

            sent_time = fake.date_time_between(
                start_date=self.start_date, end_date="now"
            )

            self.messages.append(
                {
                    "message_id": self.message_id,
                    "sender_type": random.choice(["driver", "dispatcher"]),
                    "sender_id": sender_driver["driver_id"],
                    "recipient_type": random.choice(["driver", "dispatcher"]),
                    "recipient_id": recipient_driver["driver_id"],
                    "message_type": random.choice(message_types),
                    "subject": random.choice(subjects),
                    "message_body": fake.sentence(nb_words=15),
                    "sent_time": sent_time,
                    "read_time": (
                        sent_time + timedelta(minutes=random.randint(1, 60))
                        if random.random() > 0.2
                        else None
                    ),
                    "is_read": random.random() > 0.2,
                    "priority": random.choice(["low", "normal", "high"]),
                    "created_at": sent_time,
                }
            )

    def generate_vehicle_daily_summary(self):
        """Generate daily summary statistics for vehicles"""
        print("Generating vehicle daily summaries...")

        for vehicle in self.vehicles:
            current = self.start_date.date()

            while current <= date.today():
                # Get trips for this vehicle on this date
                daily_trips = [
                    t
                    for t in self.trips
                    if t["vehicle_id"] == vehicle["vehicle_id"]
                    and t["start_time"].date() == current
                ]

                if daily_trips:
                    self.summary_id += 1

                    total_miles = sum(t["distance_miles"] for t in daily_trips)
                    total_fuel = sum(t["fuel_used_gallons"] for t in daily_trips)
                    total_drive_time = sum(t["drive_time_minutes"] for t in daily_trips)
                    total_idle_time = sum(t["idle_time_minutes"] for t in daily_trips)

                    self.vehicle_daily_summary.append(
                        {
                            "summary_id": self.summary_id,
                            "vehicle_id": vehicle["vehicle_id"],
                            "summary_date": current,
                            "total_miles": round(total_miles, 1),
                            "total_trips": len(daily_trips),
                            "total_drive_time_hours": round(total_drive_time / 60, 2),
                            "total_idle_time_hours": round(total_idle_time / 60, 2),
                            "total_fuel_gallons": round(total_fuel, 2),
                            "average_mpg": (
                                round(total_miles / total_fuel, 2)
                                if total_fuel > 0
                                else 0
                            ),
                            "max_speed_mph": max(
                                t["max_speed_mph"] for t in daily_trips
                            ),
                            "harsh_events_count": random.randint(0, 5),
                            "created_at": datetime.combine(current, time(23, 59)),
                        }
                    )

                current += timedelta(days=1)

    def save_all(self):
        """Save all generated data to CSV files"""
        OUTPUT_DIR.mkdir(exist_ok=True)

        print("\nSaving data to CSV files...")

        datasets = [
            ("companies", self.companies),
            ("depots", self.depots),
            ("vehicles", self.vehicles),
            ("vehicle_specs", self.vehicle_specs),
            ("drivers", self.drivers),
            ("driver_certifications", self.driver_certifications),
            ("routes", self.routes),
            ("geofences", self.geofences),
            ("trips", self.trips),
            ("stops", self.stops),
            ("gps_positions", self.gps_positions[:5000]),  # Limit GPS data for demo
            ("geofence_events", self.geofence_events),
            ("fuel_transactions", self.fuel_transactions),
            ("maintenance_records", self.maintenance_records),
            ("vehicle_diagnostics", self.vehicle_diagnostics[:1000]),  # Limit for demo
            ("driver_logs", self.driver_logs[:1000]),  # Limit for demo
            ("hos_violations", self.hos_violations),
            ("dvir_reports", self.dvir_reports),
            ("driver_events", self.driver_events),
            ("driver_scores", self.driver_scores),
            ("messages", self.messages),
            ("vehicle_daily_summary", self.vehicle_daily_summary),
        ]

        for name, data in datasets:
            if data:
                filepath = OUTPUT_DIR / f"{name}.csv"
                with open(filepath, "w", newline="", encoding="utf-8") as f:
                    writer = csv.DictWriter(f, fieldnames=data[0].keys())
                    writer.writeheader()
                    writer.writerows(data)
                print(f"  [OK] {name}: {len(data):,} records")

        self.generate_summary()

    def generate_summary(self):
        """Generate summary statistics"""
        print(f"\nFleet Management Data Generation Summary")
        print("=" * 50)

        print(f"\nCompany Infrastructure:")
        print(f"  Companies: {len(self.companies)}")
        print(f"  Depots: {len(self.depots)}")
        print(f"  Vehicles: {len(self.vehicles)}")
        print(f"  Drivers: {len(self.drivers)}")

        print(f"\nOperations:")
        print(f"  Routes: {len(self.routes)}")
        print(f"  Trips: {len(self.trips)}")
        print(f"  Stops: {len(self.stops)}")
        print(f"  Geofences: {len(self.geofences)}")

        print(f"\nTracking Data:")
        print(f"  GPS Positions: {len(self.gps_positions):,}")
        print(f"  Geofence Events: {len(self.geofence_events):,}")
        print(f"  Driver Events: {len(self.driver_events)}")

        print(f"\nMaintenance & Fuel:")
        print(f"  Fuel Transactions: {len(self.fuel_transactions)}")
        print(f"  Maintenance Records: {len(self.maintenance_records)}")
        print(f"  Diagnostics: {len(self.vehicle_diagnostics):,}")

        print(f"\nCompliance:")
        print(f"  Driver Logs: {len(self.driver_logs):,}")
        print(f"  HOS Violations: {len(self.hos_violations)}")
        print(f"  DVIR Reports: {len(self.dvir_reports)}")
        print(f"  Driver Scores: {len(self.driver_scores)}")

        print(f"\nCommunications:")
        print(f"  Messages: {len(self.messages)}")

        print(f"\nAnalytics:")
        print(f"  Daily Summaries: {len(self.vehicle_daily_summary)}")

        # Calculate some statistics
        total_miles = sum(
            t["distance_miles"] for t in self.trips if t["distance_miles"]
        )
        total_fuel = sum(
            t["fuel_used_gallons"] for t in self.trips if t["fuel_used_gallons"]
        )

        print(f"\nPerformance Metrics:")
        print(f"  Total Miles Driven: {total_miles:,.1f}")
        print(f"  Total Fuel Used: {total_fuel:,.1f} gallons")
        if total_fuel > 0:
            print(f"  Fleet Average MPG: {total_miles / total_fuel:.2f}")

        print(f"\nFiles Generated: 22")


if __name__ == "__main__":
    generator = FleetManagementGenerator()
    generator.generate_all()
    print("\n[SUCCESS] Fleet Management data generation complete!")
