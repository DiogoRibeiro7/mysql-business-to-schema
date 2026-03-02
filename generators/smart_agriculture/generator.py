#!/usr/bin/env python3
"""Smart Agriculture System Data Generator.

Generates realistic data for precision farming with IoT sensors, crop management, and livestock
"""

import csv
import json
import random
from datetime import datetime, timedelta, date
from pathlib import Path
from faker import Faker
import numpy as np
import math

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
    "farms": 5,
    "fields_per_farm": 8,
    "zones_per_field": 4,
    "sensors_per_zone": 3,
    "crops": 15,
    "animals_per_farm": 50,  # For mixed/dairy farms
    "days_of_history": 90,  # Full growing season
    "readings_per_day": 24,  # Hourly readings
    "weather_stations": 3,
}


class SmartAgricultureGenerator:
    """Represent SmartAgricultureGenerator."""

    def __init__(self):
        # Core entities
        """Initialize the instance."""
        self.farms: List[Any] = []
        self.fields: List[Any] = []
        self.zones: List[Any] = []
        self.crops: List[Any] = []
        self.operators: List[Any] = []

        # Planting and crop management
        self.planting_records: List[Any] = []
        self.growth_stages: List[Any] = []
        self.harvest_records: List[Any] = []
        self.yield_predictions: List[Any] = []

        # IoT and sensors
        self.sensors: List[Any] = []
        self.sensor_readings: List[Any] = []
        self.weather_stations: List[Any] = []
        self.weather_data: List[Any] = []

        # Irrigation
        self.irrigation_systems: List[Any] = []
        self.irrigation_events: List[Any] = []
        self.irrigation_schedules: List[Any] = []

        # Farm inputs
        self.fertilizer_applications: List[Any] = []
        self.pesticide_applications: List[Any] = []

        # Livestock (for dairy/mixed farms)
        self.animals: List[Any] = []
        self.health_records: List[Any] = []
        self.milk_production: List[Any] = []

        # Counters
        self.field_id = 0
        self.zone_id = 0
        self.planting_id = 0
        self.stage_id = 0
        self.sensor_id = 0
        self.reading_id = 0
        self.station_id = 0
        self.weather_id = 0
        self.system_id = 0
        self.event_id = 0
        self.schedule_id = 0
        self.fertilizer_id = 0
        self.pesticide_id = 0
        self.animal_id = 0
        self.health_id = 0
        self.milk_id = 0
        self.harvest_id = 0
        self.prediction_id = 0
        self.operator_id = 0

        # Start date for historical data
        self.start_date = datetime.now() - timedelta(days=CONFIG["days_of_history"])

    def generate_all(self):
        """Generate all smart agriculture data."""
        print("Starting Smart Agriculture Data Generation...")
        print("Configuration:")
        print(f"  Farms: {CONFIG['farms']}")
        print(f"  Total fields: {CONFIG['farms'] * CONFIG['fields_per_farm']}")
        print(
            f"  Total zones: {CONFIG['farms'] * CONFIG['fields_per_farm'] * CONFIG['zones_per_field']}"
        )
        print(f"  Days of history: {CONFIG['days_of_history']}")

        # Core infrastructure
        self.generate_farms()
        self.generate_operators()
        self.generate_fields()
        self.generate_zones()
        self.generate_crops()

        # Planting and crops
        self.generate_planting_records()
        self.generate_growth_stages()

        # IoT infrastructure
        self.generate_sensors()
        self.generate_weather_stations()

        # Irrigation
        self.generate_irrigation_systems()
        self.generate_irrigation_schedules()

        # Generate time-series data
        self.generate_sensor_data()
        self.generate_weather_data()
        self.generate_irrigation_events()

        # Farm management
        self.generate_fertilizer_applications()
        self.generate_pesticide_applications()

        # Harvest and predictions
        self.generate_harvest_records()
        self.generate_yield_predictions()

        # Livestock (for applicable farms)
        self.generate_animals()
        self.generate_health_records()
        self.generate_milk_production()

        # Save all data
        self.save_all()

    def generate_farms(self):
        """Generate farm data."""
        print(f"Generating {CONFIG['farms']} farms...")

        farm_types = ["crop", "dairy", "mixed", "orchard", "greenhouse"]
        climate_zones = ["temperate", "subtropical", "mediterranean", "continental"]
        soil_types = ["loam", "clay", "sandy", "silt", "peat"]

        for i in range(CONFIG["farms"]):
            farm_type = random.choice(farm_types)

            # Generate farm location
            base_lat = 40.0 + random.uniform(-5, 5)
            base_lng = -100.0 + random.uniform(-20, 20)

            self.farms.append(
                {
                    "farm_id": i + 1,
                    "farm_name": f"{fake.last_name()} {random.choice(['Family', 'Agricultural', 'Organic', 'Heritage'])} Farm",
                    "farm_type": farm_type,
                    "owner_name": fake.name(),
                    "location": f"{fake.city()}, {fake.state()}",
                    "total_area_hectares": round(random.uniform(50, 500), 2),
                    "latitude": round(base_lat, 6),
                    "longitude": round(base_lng, 6),
                    "elevation_meters": random.randint(100, 1500),
                    "climate_zone": random.choice(climate_zones),
                    "soil_type": random.choice(soil_types),
                    "established_date": fake.date_between(
                        start_date="-30y", end_date="-1y"
                    ),
                    "organic_certified": random.random() < 0.3,
                    "created_at": datetime.now(),
                }
            )

    def generate_operators(self):
        """Generate farm operators/workers."""
        print("Generating farm operators...")

        roles = [
            "Farm Manager",
            "Field Supervisor",
            "Equipment Operator",
            "Irrigation Specialist",
            "Agronomist",
            "Veterinarian",
        ]

        for farm in self.farms:
            num_operators = random.randint(3, 8)
            for _ in range(num_operators):
                self.operator_id += 1
                self.operators.append(
                    {
                        "operator_id": self.operator_id,
                        "farm_id": farm["farm_id"],
                        "operator_name": fake.name(),
                        "role": random.choice(roles),
                        "email": fake.email(),
                        "phone": fake.phone_number()[:20],
                        "hire_date": fake.date_between(
                            start_date="-5y", end_date="today"
                        ),
                        "is_active": random.random() > 0.1,
                    }
                )

    def generate_fields(self):
        """Generate fields within farms."""
        print("Generating fields...")

        irrigation_types = ["drip", "sprinkler", "flood", "pivot", "none"]
        drainage_classes = ["well", "moderate", "poor"]

        for farm in self.farms:
            total_area = farm["total_area_hectares"]
            area_per_field = total_area / CONFIG["fields_per_farm"]

            for j in range(CONFIG["fields_per_farm"]):
                self.field_id += 1

                # Generate GPS boundaries (simplified as rectangular fields)
                lat = farm["latitude"]
                lng = farm["longitude"]
                field_size = (
                    math.sqrt(area_per_field * 10000) / 111000
                )  # Convert hectares to degrees

                boundaries = [
                    {"lat": lat, "lng": lng},
                    {"lat": lat + field_size, "lng": lng},
                    {"lat": lat + field_size, "lng": lng + field_size},
                    {"lat": lat, "lng": lng + field_size},
                ]

                self.fields.append(
                    {
                        "field_id": self.field_id,
                        "farm_id": farm["farm_id"],
                        "field_name": f"Field {chr(65+j)}",
                        "area_hectares": round(
                            area_per_field * random.uniform(0.8, 1.2), 2
                        ),
                        "soil_type": farm["soil_type"],
                        "slope_percentage": round(random.uniform(0, 15), 1),
                        "drainage_class": random.choice(drainage_classes),
                        "irrigation_type": random.choice(irrigation_types),
                        "gps_boundaries": json.dumps(boundaries),
                        "last_soil_test": fake.date_between(
                            start_date="-2y", end_date="today"
                        ),
                        "created_at": datetime.now(),
                    }
                )

    def generate_zones(self):
        """Generate management zones within fields."""
        print("Generating zones...")

        zone_types = ["productivity", "soil_type", "topography", "custom"]

        for field in self.fields:
            area_per_zone = field["area_hectares"] / CONFIG["zones_per_field"]

            for k in range(CONFIG["zones_per_field"]):
                self.zone_id += 1

                characteristics = {
                    "organic_matter": round(random.uniform(1, 5), 1),
                    "cec": round(random.uniform(10, 30), 1),
                    "water_holding_capacity": random.choice(["low", "medium", "high"]),
                    "compaction_level": random.choice(
                        ["none", "slight", "moderate", "severe"]
                    ),
                }

                self.zones.append(
                    {
                        "zone_id": self.zone_id,
                        "field_id": field["field_id"],
                        "zone_name": f"Zone {field['field_name']}-{k+1}",
                        "area_hectares": round(
                            area_per_zone * random.uniform(0.9, 1.1), 2
                        ),
                        "management_zone_type": random.choice(zone_types),
                        "characteristics": json.dumps(characteristics),
                        "created_at": datetime.now(),
                    }
                )

    def generate_crops(self):
        """Generate crop catalog."""
        print(f"Generating {CONFIG['crops']} crop types...")

        crop_data = [
            (
                "Corn",
                "Zea mays",
                "Poaceae",
                "cereal",
                120,
                10,
                15,
                30,
                5.0,
                150,
                60,
                120,
                6.0,
                7.0,
            ),
            (
                "Wheat",
                "Triticum aestivum",
                "Poaceae",
                "cereal",
                110,
                0,
                12,
                25,
                4.0,
                120,
                50,
                100,
                6.0,
                7.5,
            ),
            (
                "Soybeans",
                "Glycine max",
                "Fabaceae",
                "legume",
                100,
                10,
                18,
                30,
                4.5,
                20,
                40,
                60,
                6.0,
                7.0,
            ),
            (
                "Rice",
                "Oryza sativa",
                "Poaceae",
                "cereal",
                130,
                10,
                20,
                35,
                10.0,
                100,
                40,
                80,
                6.0,
                7.0,
            ),
            (
                "Potato",
                "Solanum tuberosum",
                "Solanaceae",
                "vegetable",
                90,
                7,
                15,
                25,
                4.0,
                120,
                60,
                150,
                5.0,
                6.5,
            ),
            (
                "Tomato",
                "Solanum lycopersicum",
                "Solanaceae",
                "vegetable",
                80,
                10,
                18,
                28,
                5.0,
                150,
                60,
                200,
                6.0,
                7.0,
            ),
            (
                "Lettuce",
                "Lactuca sativa",
                "Asteraceae",
                "vegetable",
                60,
                5,
                15,
                22,
                3.0,
                100,
                40,
                120,
                6.0,
                7.0,
            ),
            (
                "Apple",
                "Malus domestica",
                "Rosaceae",
                "fruit",
                150,
                7,
                15,
                25,
                4.0,
                80,
                40,
                120,
                6.0,
                7.5,
            ),
            (
                "Alfalfa",
                "Medicago sativa",
                "Fabaceae",
                "forage",
                60,
                5,
                15,
                28,
                6.0,
                20,
                50,
                200,
                6.5,
                7.5,
            ),
            (
                "Cotton",
                "Gossypium hirsutum",
                "Malvaceae",
                "cash_crop",
                140,
                15,
                20,
                32,
                5.0,
                120,
                40,
                60,
                6.0,
                7.5,
            ),
            (
                "Barley",
                "Hordeum vulgare",
                "Poaceae",
                "cereal",
                95,
                0,
                12,
                24,
                3.5,
                100,
                40,
                80,
                6.0,
                7.8,
            ),
            (
                "Sunflower",
                "Helianthus annuus",
                "Asteraceae",
                "cash_crop",
                100,
                6,
                18,
                28,
                4.5,
                80,
                60,
                60,
                6.0,
                7.5,
            ),
            (
                "Canola",
                "Brassica napus",
                "Brassicaceae",
                "cash_crop",
                110,
                5,
                12,
                24,
                3.5,
                150,
                60,
                100,
                5.8,
                7.0,
            ),
            (
                "Sugar Beet",
                "Beta vulgaris",
                "Amaranthaceae",
                "cash_crop",
                120,
                3,
                15,
                25,
                5.0,
                120,
                40,
                120,
                6.5,
                8.0,
            ),
            (
                "Grapes",
                "Vitis vinifera",
                "Vitaceae",
                "fruit",
                150,
                10,
                18,
                30,
                3.5,
                30,
                30,
                100,
                6.0,
                7.0,
            ),
        ]

        for i, crop_info in enumerate(crop_data):
            self.crops.append(
                {
                    "crop_id": i + 1,
                    "crop_name": crop_info[0],
                    "scientific_name": crop_info[1],
                    "crop_family": crop_info[2],
                    "crop_type": crop_info[3],
                    "growth_days": crop_info[4],
                    "base_temperature_c": crop_info[5],
                    "optimal_temp_min": crop_info[6],
                    "optimal_temp_max": crop_info[7],
                    "water_needs_mm_per_day": crop_info[8],
                    "nitrogen_kg_per_hectare": crop_info[9],
                    "phosphorus_kg_per_hectare": crop_info[10],
                    "potassium_kg_per_hectare": crop_info[11],
                    "optimal_ph_min": crop_info[12],
                    "optimal_ph_max": crop_info[13],
                    "created_at": datetime.now(),
                }
            )

    def generate_planting_records(self):
        """Generate planting records for fields."""
        print("Generating planting records...")

        varieties = {
            "Corn": ["Pioneer 1197", "DeKalb 62-08", "Golden Harvest 10T22"],
            "Wheat": ["Hard Red Winter", "Soft White", "Durum"],
            "Soybeans": ["Roundup Ready", "Liberty Link", "Conventional"],
        }

        _ = ["planted", "growing", "harvested"]

        for field in self.fields:
            # Each field can have multiple plantings over time
            num_plantings = random.randint(1, 3)

            for _ in range(num_plantings):
                self.planting_id += 1
                crop = random.choice(self.crops[:10])  # Focus on common crops

                planting_date = fake.date_between(
                    start_date=self.start_date,
                    end_date=self.start_date + timedelta(days=30),
                )
                harvest_date = planting_date + timedelta(days=crop["growth_days"])

                # Determine status based on dates
                today = date.today()
                if harvest_date < today:
                    status = "harvested"
                    actual_harvest = harvest_date + timedelta(
                        days=random.randint(-5, 5)
                    )
                elif planting_date < today:
                    status = "growing"
                    actual_harvest = None
                else:
                    status = "planted"
                    actual_harvest = None

                # Calculate yields
                expected_yield = random.uniform(3000, 8000)  # kg/ha
                actual_yield = (
                    expected_yield * random.uniform(0.8, 1.2)
                    if status == "harvested"
                    else None
                )

                self.planting_records.append(
                    {
                        "planting_id": self.planting_id,
                        "field_id": field["field_id"],
                        "zone_id": random.choice(
                            [
                                z["zone_id"]
                                for z in self.zones
                                if z["field_id"] == field["field_id"]
                            ]
                        ),
                        "crop_id": crop["crop_id"],
                        "variety": random.choice(
                            varieties.get(crop["crop_name"], ["Standard"])
                        ),
                        "planting_date": planting_date,
                        "expected_harvest_date": harvest_date,
                        "actual_harvest_date": actual_harvest,
                        "area_planted_hectares": field["area_hectares"]
                        * random.uniform(0.8, 1.0),
                        "seed_rate_kg_per_hectare": random.uniform(50, 200),
                        "row_spacing_cm": random.uniform(15, 75),
                        "plant_spacing_cm": random.uniform(10, 30),
                        "planting_depth_cm": random.uniform(2, 8),
                        "expected_yield_kg_per_hectare": expected_yield,
                        "actual_yield_kg_per_hectare": actual_yield,
                        "status": status,
                        "notes": None,
                        "created_at": planting_date,
                    }
                )

    def generate_growth_stages(self):
        """Generate crop growth stage observations."""
        print("Generating growth stages...")

        stages = [
            ("Germination", "VE", 0.1),
            ("Seedling", "V2", 0.15),
            ("Vegetative", "V6", 0.25),
            ("Reproductive", "R1", 0.5),
            ("Grain Fill", "R3", 0.75),
            ("Maturity", "R6", 0.9),
        ]

        for planting in self.planting_records:
            if planting["status"] in ["growing", "harvested"]:
                crop = next(
                    c for c in self.crops if c["crop_id"] == planting["crop_id"]
                )

                for stage_name, stage_code, progress in stages:
                    # Calculate when this stage occurred
                    days_to_stage = int(crop["growth_days"] * progress)
                    observation_date = planting["planting_date"] + timedelta(
                        days=days_to_stage
                    )

                    # Skip future dates
                    if observation_date > date.today():
                        continue

                    self.stage_id += 1

                    # Calculate GDD (simplified)
                    gdd = days_to_stage * max(0, 20 - crop["base_temperature_c"])

                    self.growth_stages.append(
                        {
                            "stage_id": self.stage_id,
                            "planting_id": planting["planting_id"],
                            "stage_name": stage_name,
                            "stage_code": stage_code,
                            "observation_date": observation_date,
                            "gdd_accumulated": gdd,
                            "plant_height_cm": progress * random.uniform(150, 250),
                            "leaf_area_index": progress * random.uniform(3, 6),
                            "notes": None,
                            "created_at": observation_date,
                        }
                    )

    def generate_sensors(self):
        """Generate sensor deployments."""
        print("Generating sensors...")

        sensor_types = [
            "soil_moisture",
            "soil_temperature",
            "soil_ph",
            "air_temperature",
            "humidity",
            "light",
            "rainfall",
            "wind_speed",
        ]
        manufacturers = [
            "Davis Instruments",
            "METER Group",
            "Campbell Scientific",
            "Sentek",
            "AquaCheck",
        ]

        for zone in self.zones:
            num_sensors = random.randint(1, CONFIG["sensors_per_zone"])

            for _ in range(num_sensors):
                self.sensor_id += 1
                sensor_type = random.choice(sensor_types)

                self.sensors.append(
                    {
                        "sensor_id": self.sensor_id,
                        "zone_id": zone["zone_id"],
                        "sensor_code": f"SEN{self.sensor_id:06d}",
                        "sensor_type": sensor_type,
                        "manufacturer": random.choice(manufacturers),
                        "model": f"Model-{random.choice(['X100', 'Pro2', 'Plus', 'HD'])}",
                        "installation_date": fake.date_between(
                            start_date="-2y", end_date="-6m"
                        ),
                        "depth_cm": (
                            random.randint(10, 60) if "soil" in sensor_type else None
                        ),
                        "height_m": (
                            random.uniform(1, 3) if "soil" not in sensor_type else None
                        ),
                        "calibration_date": fake.date_between(
                            start_date="-6m", end_date="today"
                        ),
                        "battery_type": random.choice(["Lithium", "Solar", "AC Power"]),
                        "is_active": random.random() > 0.05,
                        "created_at": datetime.now(),
                    }
                )

    def generate_weather_stations(self):
        """Generate weather stations."""
        print(f"Generating {CONFIG['weather_stations']} weather stations...")

        for _ in range(CONFIG["weather_stations"]):
            self.station_id += 1
            farm = random.choice(self.farms)

            self.weather_stations.append(
                {
                    "station_id": self.station_id,
                    "farm_id": farm["farm_id"],
                    "station_code": f"WS{self.station_id:03d}",
                    "station_name": f"{farm['farm_name']} Weather Station",
                    "latitude": farm["latitude"] + random.uniform(-0.01, 0.01),
                    "longitude": farm["longitude"] + random.uniform(-0.01, 0.01),
                    "elevation_m": farm["elevation_meters"],
                    "installation_date": fake.date_between(
                        start_date="-3y", end_date="-1y"
                    ),
                    "is_active": True,
                    "created_at": datetime.now(),
                }
            )

    def generate_irrigation_systems(self):
        """Generate irrigation systems."""
        print("Generating irrigation systems...")

        _ = ["drip", "sprinkler", "pivot", "flood"]

        for field in self.fields:
            if field["irrigation_type"] != "none":
                self.system_id += 1

                self.irrigation_systems.append(
                    {
                        "system_id": self.system_id,
                        "field_id": field["field_id"],
                        "system_type": field["irrigation_type"],
                        "capacity_liters_per_hour": random.randint(5000, 50000),
                        "coverage_hectares": field["area_hectares"],
                        "efficiency_percentage": random.uniform(70, 95),
                        "installation_date": fake.date_between(
                            start_date="-5y", end_date="-1y"
                        ),
                        "last_maintenance": fake.date_between(
                            start_date="-6m", end_date="today"
                        ),
                        "is_active": random.random() > 0.1,
                        "created_at": datetime.now(),
                    }
                )

    def generate_irrigation_schedules(self):
        """Generate irrigation schedules."""
        print("Generating irrigation schedules...")

        for system in self.irrigation_systems:
            # Create weekly schedule
            for day_of_week in range(7):
                if random.random() < 0.6:  # Not every day
                    self.schedule_id += 1

                    start_time = random.choice(["06:00:00", "18:00:00"])
                    duration = random.randint(30, 180)

                    self.irrigation_schedules.append(
                        {
                            "schedule_id": self.schedule_id,
                            "system_id": system["system_id"],
                            "day_of_week": day_of_week,
                            "start_time": start_time,
                            "duration_minutes": duration,
                            "flow_rate_liters_per_minute": system[
                                "capacity_liters_per_hour"
                            ]
                            / 60,
                            "is_active": True,
                            "created_at": datetime.now(),
                        }
                    )

    def generate_sensor_data(self):
        """Generate sensor readings."""
        print("Generating sensor data (this may take a while)...")

        current = self.start_date
        end = datetime.now()

        while current <= end:
            for sensor in self.sensors[:50]:  # Limit for demo
                if not sensor["is_active"]:
                    continue

                self.reading_id += 1

                # Generate realistic values based on sensor type
                if sensor["sensor_type"] == "soil_moisture":
                    value = random.uniform(15, 35)
                elif sensor["sensor_type"] == "soil_temperature":
                    value = random.uniform(10, 25)
                elif sensor["sensor_type"] == "soil_ph":
                    value = random.uniform(5.5, 7.5)
                elif sensor["sensor_type"] == "air_temperature":
                    value = random.uniform(5, 35)
                elif sensor["sensor_type"] == "humidity":
                    value = random.uniform(30, 90)
                elif sensor["sensor_type"] == "light":
                    value = random.uniform(0, 100000)
                elif sensor["sensor_type"] == "rainfall":
                    value = random.uniform(0, 20) if random.random() < 0.1 else 0
                else:
                    value = random.uniform(0, 100)

                self.sensor_readings.append(
                    {
                        "reading_id": self.reading_id,
                        "sensor_id": sensor["sensor_id"],
                        "reading_time": current,
                        "value": round(value, 2),
                        "unit": self.get_sensor_unit(sensor["sensor_type"]),
                        "quality_flag": (
                            random.choice(["good", "good", "good", "suspect"])
                            if random.random() > 0.95
                            else "good"
                        ),
                        "created_at": current,
                    }
                )

            current += timedelta(hours=1)

    def get_sensor_unit(self, sensor_type):
        """Get unit for sensor type."""
        units = {
            "soil_moisture": "%",
            "soil_temperature": "°C",
            "soil_ph": "pH",
            "air_temperature": "°C",
            "humidity": "%",
            "light": "lux",
            "rainfall": "mm",
            "wind_speed": "m/s",
        }
        return units.get(sensor_type, "unit")

    def generate_weather_data(self):
        """Generate weather data."""
        print("Generating weather data...")

        current = self.start_date
        end = datetime.now()

        while current <= end:
            for station in self.weather_stations:
                self.weather_id += 1

                # Generate realistic weather patterns
                hour = current.hour
                base_temp = 20 + 10 * math.sin((hour - 6) * math.pi / 12)

                self.weather_data.append(
                    {
                        "weather_id": self.weather_id,
                        "station_id": station["station_id"],
                        "observation_time": current,
                        "temperature_c": round(base_temp + random.uniform(-5, 5), 1),
                        "humidity_percent": random.uniform(40, 80),
                        "pressure_hpa": random.uniform(1000, 1030),
                        "wind_speed_ms": random.uniform(0, 15),
                        "wind_direction_degrees": random.randint(0, 359),
                        "precipitation_mm": (
                            random.uniform(0, 5) if random.random() < 0.1 else 0
                        ),
                        "solar_radiation_wm2": (
                            max(0, 800 * math.sin((hour - 6) * math.pi / 12))
                            if 6 <= hour <= 18
                            else 0
                        ),
                        "uv_index": (
                            max(0, int(10 * math.sin((hour - 6) * math.pi / 12)))
                            if 6 <= hour <= 18
                            else 0
                        ),
                        "created_at": current,
                    }
                )

            current += timedelta(hours=1)

    def generate_irrigation_events(self):
        """Generate irrigation events."""
        print("Generating irrigation events...")

        for schedule in self.irrigation_schedules:
            _ = next(
                s
                for s in self.irrigation_systems
                if s["system_id"] == schedule["system_id"]
            )

            current = self.start_date
            end = datetime.now()

            while current <= end:
                if current.weekday() == schedule["day_of_week"]:
                    self.event_id += 1

                    # Parse start time
                    hour = int(schedule["start_time"].split(":")[0])
                    start = current.replace(hour=hour, minute=0, second=0)
                    end_time = start + timedelta(minutes=schedule["duration_minutes"])

                    water_used = (
                        schedule["flow_rate_liters_per_minute"]
                        * schedule["duration_minutes"]
                    )

                    self.irrigation_events.append(
                        {
                            "event_id": self.event_id,
                            "system_id": schedule["system_id"],
                            "schedule_id": schedule["schedule_id"],
                            "start_time": start,
                            "end_time": end_time,
                            "water_used_liters": water_used,
                            "triggered_by": "schedule",
                            "created_at": start,
                        }
                    )

                current += timedelta(days=1)

    def generate_fertilizer_applications(self):
        """Generate fertilizer application records."""
        print("Generating fertilizer applications...")

        fertilizer_types = ["Urea", "DAP", "MOP", "NPK 15-15-15", "Ammonium Sulfate"]
        application_methods = ["broadcast", "banding", "foliar", "fertigation"]

        for planting in self.planting_records:
            # 2-3 fertilizer applications per planting
            num_applications = random.randint(2, 3)

            for i in range(num_applications):
                self.fertilizer_id += 1

                # Space out applications
                days_after_planting = (i + 1) * 30
                application_date = planting["planting_date"] + timedelta(
                    days=days_after_planting
                )

                if application_date > date.today():
                    continue

                self.fertilizer_applications.append(
                    {
                        "application_id": self.fertilizer_id,
                        "field_id": planting["field_id"],
                        "planting_id": planting["planting_id"],
                        "application_date": application_date,
                        "fertilizer_type": random.choice(fertilizer_types),
                        "application_method": random.choice(application_methods),
                        "rate_kg_per_hectare": random.uniform(50, 200),
                        "n_content": random.uniform(10, 46),
                        "p_content": random.uniform(0, 46),
                        "k_content": random.uniform(0, 60),
                        "cost_per_kg": random.uniform(0.5, 2.0),
                        "operator_id": random.choice(self.operators)["operator_id"],
                        "notes": None,
                        "created_at": application_date,
                    }
                )

    def generate_pesticide_applications(self):
        """Generate pesticide application records."""
        print("Generating pesticide applications...")

        pesticide_types = ["Herbicide", "Insecticide", "Fungicide"]
        products = {
            "Herbicide": ["Roundup", "Atrazine", "2,4-D"],
            "Insecticide": ["Chlorpyrifos", "Imidacloprid", "Spinosad"],
            "Fungicide": ["Mancozeb", "Propiconazole", "Azoxystrobin"],
        }

        for planting in self.planting_records:
            # 1-2 pesticide applications per planting
            if random.random() < 0.7:
                self.pesticide_id += 1

                pesticide_type = random.choice(pesticide_types)
                product = random.choice(products[pesticide_type])

                application_date = planting["planting_date"] + timedelta(
                    days=random.randint(20, 60)
                )

                if application_date > date.today():
                    continue

                self.pesticide_applications.append(
                    {
                        "application_id": self.pesticide_id,
                        "field_id": planting["field_id"],
                        "planting_id": planting["planting_id"],
                        "application_date": application_date,
                        "pesticide_type": pesticide_type,
                        "product_name": product,
                        "active_ingredient": f"AI-{product[:3]}",
                        "rate_ml_per_hectare": random.uniform(500, 2000),
                        "target_pest": f"Target pest for {pesticide_type}",
                        "rei_hours": random.choice([4, 12, 24, 48]),
                        "cost_per_liter": random.uniform(20, 100),
                        "operator_id": random.choice(self.operators)["operator_id"],
                        "weather_conditions": random.choice(
                            ["Clear", "Partly Cloudy", "Overcast"]
                        ),
                        "wind_speed_ms": random.uniform(0, 5),
                        "created_at": application_date,
                    }
                )

    def generate_harvest_records(self):
        """Generate harvest records."""
        print("Generating harvest records...")

        for planting in self.planting_records:
            if planting["status"] == "harvested":
                self.harvest_id += 1

                self.harvest_records.append(
                    {
                        "harvest_id": self.harvest_id,
                        "planting_id": planting["planting_id"],
                        "harvest_date": planting["actual_harvest_date"],
                        "yield_kg": planting["actual_yield_kg_per_hectare"]
                        * planting["area_planted_hectares"],
                        "moisture_percentage": random.uniform(12, 20),
                        "quality_grade": random.choice(["A", "B", "C"]),
                        "storage_location": f"Silo {random.randint(1, 5)}",
                        "market_price_per_kg": random.uniform(0.15, 0.35),
                        "harvesting_hours": random.uniform(4, 12),
                        "operator_id": random.choice(self.operators)["operator_id"],
                        "notes": None,
                        "created_at": planting["actual_harvest_date"],
                    }
                )

    def generate_yield_predictions(self):
        """Generate yield predictions."""
        print("Generating yield predictions...")

        for planting in self.planting_records:
            if planting["status"] == "growing":
                # Generate weekly predictions
                current = max(planting["planting_date"], self.start_date.date())

                while current <= date.today():
                    self.prediction_id += 1

                    # Prediction gets more accurate closer to harvest
                    days_to_harvest = (planting["expected_harvest_date"] - current).days
                    accuracy_factor = max(0.5, 1 - days_to_harvest / 100)

                    predicted_yield = planting[
                        "expected_yield_kg_per_hectare"
                    ] * random.uniform(
                        1 - (1 - accuracy_factor) * 0.3, 1 + (1 - accuracy_factor) * 0.3
                    )

                    self.yield_predictions.append(
                        {
                            "prediction_id": self.prediction_id,
                            "planting_id": planting["planting_id"],
                            "prediction_date": current,
                            "predicted_yield_kg_per_hectare": round(predicted_yield, 2),
                            "confidence_level": round(accuracy_factor * 100, 1),
                            "model_version": "1.0",
                            "factors_considered": json.dumps(
                                ["weather", "soil", "growth_stage"]
                            ),
                            "created_at": current,
                        }
                    )

                    current += timedelta(days=7)

    def generate_animals(self):
        """Generate livestock for dairy/mixed farms."""
        print("Generating livestock...")

        for farm in self.farms:
            if farm["farm_type"] in ["dairy", "mixed"]:
                num_animals = CONFIG["animals_per_farm"]

                for _ in range(num_animals):
                    self.animal_id += 1

                    birth_date = fake.date_between(start_date="-5y", end_date="-1y")

                    self.animals.append(
                        {
                            "animal_id": self.animal_id,
                            "farm_id": farm["farm_id"],
                            "tag_number": f"TAG{self.animal_id:06d}",
                            "animal_type": "Dairy Cow",
                            "breed": random.choice(["Holstein", "Jersey", "Guernsey"]),
                            "birth_date": birth_date,
                            "gender": random.choice(
                                ["F", "F", "F", "M"]
                            ),  # More females
                            "weight_kg": random.uniform(400, 700),
                            "status": random.choice(
                                ["active", "active", "active", "pregnant", "dry"]
                            ),
                            "created_at": birth_date,
                        }
                    )

    def generate_health_records(self):
        """Generate animal health records."""
        print("Generating health records...")

        health_types = ["vaccination", "checkup", "treatment", "deworming"]

        for animal in self.animals:
            # 2-4 health records per animal
            num_records = random.randint(2, 4)

            for _ in range(num_records):
                self.health_id += 1

                record_date = fake.date_between(start_date="-1y", end_date="today")

                self.health_records.append(
                    {
                        "record_id": self.health_id,
                        "animal_id": animal["animal_id"],
                        "record_date": record_date,
                        "record_type": random.choice(health_types),
                        "description": f"Routine {random.choice(health_types)}",
                        "veterinarian": fake.name(),
                        "medication": random.choice(
                            ["Vaccine A", "Antibiotic B", "Dewormer C", None]
                        ),
                        "dosage": (
                            f"{random.randint(5, 20)} ml"
                            if random.random() > 0.3
                            else None
                        ),
                        "next_visit_date": record_date
                        + timedelta(days=random.randint(30, 180)),
                        "created_at": record_date,
                    }
                )

    def generate_milk_production(self):
        """Generate milk production records for dairy cows."""
        print("Generating milk production records...")

        for animal in self.animals:
            if animal["gender"] == "F" and animal["status"] in ["active", "pregnant"]:
                # Daily milk production for last 30 days
                current = self.start_date
                end = datetime.now()

                while current <= end:
                    self.milk_id += 1

                    # Morning and evening milking
                    morning_yield = random.uniform(10, 20)
                    evening_yield = random.uniform(8, 18)

                    self.milk_production.append(
                        {
                            "production_id": self.milk_id,
                            "animal_id": animal["animal_id"],
                            "production_date": current.date(),
                            "morning_yield_liters": round(morning_yield, 1),
                            "evening_yield_liters": round(evening_yield, 1),
                            "total_yield_liters": round(
                                morning_yield + evening_yield, 1
                            ),
                            "fat_percentage": random.uniform(3.0, 4.5),
                            "protein_percentage": random.uniform(3.0, 3.5),
                            "somatic_cell_count": random.randint(100000, 400000),
                            "created_at": current,
                        }
                    )

                    current += timedelta(days=1)

    def save_all(self):
        """Save all generated data to CSV files."""
        OUTPUT_DIR.mkdir(exist_ok=True)

        print("\nSaving data to CSV files...")

        datasets = [
            ("farms", self.farms),
            ("operators", self.operators),
            ("fields", self.fields),
            ("zones", self.zones),
            ("crops", self.crops),
            ("planting_records", self.planting_records),
            ("growth_stages", self.growth_stages),
            ("sensors", self.sensors),
            ("sensor_readings", self.sensor_readings),
            ("weather_stations", self.weather_stations),
            ("weather_data", self.weather_data),
            ("irrigation_systems", self.irrigation_systems),
            ("irrigation_schedules", self.irrigation_schedules),
            ("irrigation_events", self.irrigation_events),
            ("fertilizer_applications", self.fertilizer_applications),
            ("pesticide_applications", self.pesticide_applications),
            ("harvest_records", self.harvest_records),
            ("yield_predictions", self.yield_predictions),
            ("animals", self.animals),
            ("health_records", self.health_records),
            ("milk_production", self.milk_production[:1000]),  # Limit for demo
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
        """Generate summary statistics."""
        print("\nSmart Agriculture Data Generation Summary")
        print("=" * 50)

        print("\nFarm Infrastructure:")
        print(f"  Farms: {len(self.farms)}")
        print(f"  Fields: {len(self.fields)}")
        print(f"  Zones: {len(self.zones)}")
        print(f"  Operators: {len(self.operators)}")

        print("\nCrop Management:")
        print(f"  Crop Types: {len(self.crops)}")
        print(f"  Plantings: {len(self.planting_records)}")
        print(f"  Growth Observations: {len(self.growth_stages)}")
        print(f"  Harvests: {len(self.harvest_records)}")

        print("\nIoT & Monitoring:")
        print(f"  Sensors: {len(self.sensors)}")
        print(f"  Sensor Readings: {len(self.sensor_readings):,}")
        print(f"  Weather Stations: {len(self.weather_stations)}")
        print(f"  Weather Records: {len(self.weather_data):,}")

        print("\nFarm Operations:")
        print(f"  Irrigation Systems: {len(self.irrigation_systems)}")
        print(f"  Irrigation Events: {len(self.irrigation_events):,}")
        print(f"  Fertilizer Applications: {len(self.fertilizer_applications)}")
        print(f"  Pesticide Applications: {len(self.pesticide_applications)}")

        if self.animals:
            print("\nLivestock:")
            print(f"  Animals: {len(self.animals)}")
            print(f"  Health Records: {len(self.health_records)}")
            print(f"  Milk Production Records: {len(self.milk_production):,}")

        # Calculate some statistics
        total_area = sum(f["total_area_hectares"] for f in self.farms)
        total_yield = (
            sum(h["yield_kg"] for h in self.harvest_records)
            if self.harvest_records
            else 0
        )

        print("\nProduction Statistics:")
        print(f"  Total Farm Area: {total_area:,.2f} hectares")
        print(f"  Total Harvest: {total_yield:,.0f} kg")
        if self.harvest_records:
            print(f"  Average Yield: {total_yield / total_area:,.0f} kg/hectare")

        print("\nFiles Generated: 21")


if __name__ == "__main__":
    generator = SmartAgricultureGenerator()
    generator.generate_all()
    print("\n[SUCCESS] Smart Agriculture data generation complete!")
