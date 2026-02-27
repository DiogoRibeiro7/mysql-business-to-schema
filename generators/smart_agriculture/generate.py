#!/usr/bin/env python3
"""
Smart Agriculture Data Generator

Generates realistic farming IoT data including:
- Soil moisture and nutrient sensors
- Weather station data
- Irrigation events
- Crop health (NDVI)
- Livestock monitoring
- Harvest yields
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


class SmartAgricultureGenerator:
    def __init__(self, config_path: str):
        """Initialize generator with configuration"""
        with open(config_path, "r") as f:
            self.config = yaml.safe_load(f)

        self.seed = self.config.get("seed", 42)
        random.seed(self.seed)

        self.output_dir = Path(self.config["output_dir"])
        self.output_dir.mkdir(parents=True, exist_ok=True)

        # Data containers
        self.farms = []
        self.fields = []
        self.zones = []
        self.crops = []
        self.plantings = []
        self.soil_sensors = []
        self.weather_stations = []
        self.sensor_readings = []
        self.irrigation_zones = []
        self.irrigation_events = []
        self.ndvi_readings = []
        self.pest_detections = []
        self.fertilizer_applications = []
        self.harvest_data = []
        self.animals = []
        self.health_readings = []
        self.feeding_records = []

        # Counters
        self.planting_id = 1
        self.irrigation_event_id = 1
        self.pest_detection_id = 1
        self.fertilizer_id = 1
        self.harvest_id = 1
        self.feeding_id = 1

    def generate_all(self):
        """Generate all data in sequence"""
        print("Generating Smart Agriculture data...")

        # Infrastructure
        self._generate_farms()
        self._generate_fields()
        self._generate_zones()
        self._generate_crops()
        self._generate_plantings()
        self._generate_sensors()
        self._generate_weather_stations()

        # Sensor data
        self._generate_sensor_readings()
        self._generate_ndvi_readings()

        # Operations
        self._generate_irrigation_events()
        self._generate_pest_detections()
        self._generate_fertilizer_applications()
        self._generate_harvest_data()

        # Livestock
        self._generate_animals()
        self._generate_health_readings()
        self._generate_feeding_records()

        # Write to CSV
        self._write_all_csvs()

        # Generate SQL scripts
        self._generate_sql_scripts()

        print(
            f"[OK] Generated data for {len(self.farms)} farms, "
            f"{len(self.fields)} fields, {len(self.zones)} zones"
        )
        print(f"[OK] Generated {len(self.sensor_readings)} sensor readings")
        print(f"[OK] Output written to {self.output_dir}")

    def _generate_farms(self):
        """Generate farm properties"""
        farm_names = [
            "Green Valley",
            "Sunshine",
            "Harvest Moon",
            "Golden Fields",
            "Spring Brook",
        ]

        for i in range(self.config["counts"]["farms"]):
            farm_type = random.choices(
                list(self.config["farm_types"].keys()),
                weights=list(self.config["farm_types"].values()),
            )[0]

            farm = {
                "farm_id": i + 1,
                "farm_name": f"{farm_names[i % len(farm_names)]} Farm",
                "farm_type": farm_type,
                "owner_name": f"Farmer_{i+1}",
                "location": f"Region_{i+1}",
                "total_area_hectares": random.randint(50, 500),
                "established_year": random.randint(1950, 2020),
                "organic_certified": random.random() < 0.3,
                "latitude": 40.0 + random.uniform(-5, 5),
                "longitude": -95.0 + random.uniform(-10, 10),
                "elevation_m": random.randint(100, 1000),
                "is_active": True,
            }
            self.farms.append(farm)

    def _generate_fields(self):
        """Generate fields for each farm"""
        field_id = 1

        for farm in self.farms:
            fields_per_farm = self.config["counts"]["fields"] // len(self.farms)

            for field_num in range(fields_per_farm):
                field = {
                    "field_id": field_id,
                    "farm_id": farm["farm_id"],
                    "field_name": f"Field-{chr(65 + field_num)}",
                    "area_hectares": random.uniform(5, 50),
                    "soil_type": random.choice(["clay", "loam", "sandy", "silt"]),
                    "slope_percentage": random.uniform(0, 15),
                    "drainage": random.choice(["good", "moderate", "poor"]),
                    "last_soil_test": datetime.now()
                    - timedelta(days=random.randint(30, 365)),
                    "nitrogen_ppm": random.uniform(10, 50),
                    "phosphorus_ppm": random.uniform(15, 45),
                    "potassium_ppm": random.uniform(100, 300),
                    "ph": random.uniform(5.5, 7.5),
                    "organic_matter_pct": random.uniform(1, 5),
                }
                self.fields.append(field)
                field_id += 1

    def _generate_zones(self):
        """Generate management zones within fields"""
        zone_id = 1

        for field in self.fields:
            zones_per_field = self.config["counts"]["zones"] // len(self.fields)

            for zone_num in range(zones_per_field):
                zone = {
                    "zone_id": zone_id,
                    "field_id": field["field_id"],
                    "zone_name": f"Zone-{field['field_id']}-{zone_num+1}",
                    "area_hectares": field["area_hectares"] / zones_per_field,
                    "irrigation_type": random.choices(
                        list(self.config["irrigation"]["methods"].keys()),
                        weights=list(self.config["irrigation"]["methods"].values()),
                    )[0],
                    "target_moisture_min": 40,
                    "target_moisture_max": 60,
                    "latitude": field["area_hectares"] / zones_per_field,
                    "longitude": field["area_hectares"] / zones_per_field,
                    "elevation_m": random.randint(100, 200),
                    "is_active": True,
                }
                self.zones.append(zone)
                zone_id += 1

    def _generate_crops(self):
        """Generate crop varieties"""
        crop_id = 1

        for crop_name, crop_config in list(self.config["crop_types"].items())[
            : self.config["counts"]["crops"]
        ]:
            crop = {
                "crop_id": crop_id,
                "crop_name": crop_name.title(),
                "variety": f"{crop_name.upper()}-{random.randint(100, 999)}",
                "crop_type": (
                    "grain" if crop_name in ["wheat", "corn", "rice"] else "vegetable"
                ),
                "growth_days": crop_config["growth_days"],
                "water_requirement_mm_per_day": (
                    5 if crop_config["water_needs"] == "high" else 3
                ),
                "optimal_temp_min": crop_config["temp_range"][0],
                "optimal_temp_max": crop_config["temp_range"][1],
                "expected_yield_kg_per_hectare": random.uniform(
                    crop_config["yield_per_hectare"][0],
                    crop_config["yield_per_hectare"][1],
                ),
                "market_price_per_kg": random.uniform(0.5, 5.0),
                "is_organic": random.random() < 0.3,
            }
            self.crops.append(crop)
            crop_id += 1

    def _generate_plantings(self):
        """Generate planting records"""
        for field in self.fields:
            crop = random.choice(self.crops)
            planting_date = datetime.strptime(
                self.config["date_ranges"]["planting_season_start"], "%Y-%m-%d"
            ) + timedelta(days=random.randint(0, 60))

            planting = {
                "planting_id": self.planting_id,
                "field_id": field["field_id"],
                "crop_id": crop["crop_id"],
                "planting_date": planting_date,
                "expected_harvest_date": planting_date
                + timedelta(days=crop["growth_days"]),
                "actual_harvest_date": None,
                "seeds_kg_per_hectare": random.uniform(50, 200),
                "plant_density": random.randint(20000, 100000),
                "row_spacing_cm": random.choice([15, 30, 45, 60, 75]),
                "status": "growing",
            }
            self.plantings.append(planting)
            self.planting_id += 1

    def _generate_sensors(self):
        """Generate soil sensors for zones"""
        sensor_id = 1

        for zone in self.zones:
            sensors_per_zone = self.config["counts"]["sensors"] // len(self.zones)

            for _ in range(sensors_per_zone):
                sensor_type = random.choice(
                    list(self.config["sensor_types"].keys())[:4]
                )
                sensor_config = self.config["sensor_types"][sensor_type]

                sensor = {
                    "sensor_id": sensor_id,
                    "zone_id": zone["zone_id"],
                    "sensor_code": f"SNS{sensor_id:05d}",
                    "sensor_type": sensor_type,
                    "manufacturer": random.choice(
                        ["AgroSense", "FarmTech", "SmartSoil"]
                    ),
                    "model": f"Model-{random.randint(100, 999)}",
                    "installation_date": datetime.now()
                    - timedelta(days=random.randint(90, 730)),
                    "last_calibration": datetime.now()
                    - timedelta(days=random.randint(7, 90)),
                    "battery_level": random.randint(20, 100),
                    "status": random.choices(
                        ["active", "maintenance", "faulty"], weights=[0.90, 0.08, 0.02]
                    )[0],
                }
                self.soil_sensors.append(sensor)
                sensor_id += 1

    def _generate_weather_stations(self):
        """Generate weather stations for farms"""
        station_id = 1

        for farm in self.farms:
            station = {
                "station_id": station_id,
                "farm_id": farm["farm_id"],
                "station_code": f"WS{station_id:03d}",
                "latitude": farm["latitude"],
                "longitude": farm["longitude"],
                "elevation_m": farm["elevation_m"],
                "installation_date": datetime.now()
                - timedelta(days=random.randint(365, 1825)),
                "manufacturer": random.choice(["Davis", "WeatherLink", "AgroMet"]),
                "model": f"Pro-{random.randint(1000, 9999)}",
                "status": "active",
            }
            self.weather_stations.append(station)
            station_id += 1

    def _generate_sensor_readings(self):
        """Generate sensor readings"""
        print("  Generating sensor readings...")

        start_date = datetime.now() - timedelta(
            days=self.config["counts"]["days_of_data"]
        )
        end_date = datetime.now()

        # Limit sensors for performance
        active_sensors = [s for s in self.soil_sensors if s["status"] == "active"][:20]

        for sensor in active_sensors:
            sensor_type = sensor["sensor_type"]
            sensor_config = self.config["sensor_types"].get(sensor_type, {})

            current_time = start_date
            current_value = random.uniform(
                sensor_config.get("optimal_range", [20, 80])[0],
                sensor_config.get("optimal_range", [20, 80])[1],
            )

            reading_count = 0
            max_readings = 500  # Limit per sensor

            while current_time <= end_date and reading_count < max_readings:
                # Add daily variation
                hour = current_time.hour
                if sensor_type == "soil_temperature":
                    # Temperature varies with time of day
                    daily_variation = 5 * math.sin(math.pi * (hour - 6) / 12)
                    current_value = sensor_config["optimal_range"][0] + daily_variation
                elif sensor_type == "soil_moisture":
                    # Moisture decreases during day, increases at night/irrigation
                    current_value = max(30, current_value - random.uniform(0, 1))
                    if hour in [6, 18]:  # Irrigation times
                        current_value = min(70, current_value + random.uniform(10, 20))

                reading = {
                    "reading_id": len(self.sensor_readings) + 1,
                    "sensor_id": sensor["sensor_id"],
                    "timestamp": current_time,
                    "value": round(current_value, 2),
                    "unit": sensor_config.get("unit", "unknown"),
                    "quality": (
                        "good" if sensor["battery_level"] > 20 else "low_battery"
                    ),
                }
                self.sensor_readings.append(reading)

                current_time += timedelta(
                    minutes=sensor_config.get("sampling_minutes", 15)
                )
                reading_count += 1

    def _generate_ndvi_readings(self):
        """Generate NDVI (vegetation health) readings"""
        print("  Generating NDVI readings...")

        for planting in self.plantings[:20]:  # Limit for performance
            field = next(
                f for f in self.fields if f["field_id"] == planting["field_id"]
            )

            days_since_planting = (datetime.now() - planting["planting_date"]).days
            growth_stage = self._get_growth_stage(days_since_planting, planting)

            # NDVI value based on growth stage
            ndvi_ranges = self.config["ndvi_values"].get(growth_stage, [0.3, 0.7])

            for day in range(min(7, self.config["counts"]["days_of_data"])):
                reading_date = datetime.now() - timedelta(days=day)

                ndvi_reading = {
                    "reading_id": len(self.ndvi_readings) + 1,
                    "field_id": field["field_id"],
                    "reading_date": reading_date.date(),
                    "ndvi_value": round(
                        random.uniform(ndvi_ranges[0], ndvi_ranges[1]), 3
                    ),
                    "growth_stage": growth_stage,
                    "days_after_planting": days_since_planting - day,
                    "satellite_source": random.choice(
                        ["Sentinel-2", "Landsat-8", "Drone"]
                    ),
                    "cloud_cover_pct": random.randint(0, 30),
                    "confidence_score": round(random.uniform(0.85, 0.99), 2),
                }
                self.ndvi_readings.append(ndvi_reading)

    def _generate_irrigation_events(self):
        """Generate irrigation events"""
        print("  Generating irrigation events...")

        start_date = datetime.now() - timedelta(
            days=self.config["counts"]["days_of_data"]
        )
        end_date = datetime.now()
        current_date = start_date

        while current_date <= end_date:
            daily_events = self.config["counts"]["irrigation_events_per_day"]

            for _ in range(daily_events):
                zone = random.choice(self.zones)

                # Check soil moisture to decide if irrigation needed
                needs_irrigation = random.random() < 0.7  # 70% chance

                if needs_irrigation:
                    irrigation_method = zone["irrigation_type"]
                    efficiency = self.config["irrigation"]["efficiency"][
                        irrigation_method
                    ]

                    event = {
                        "event_id": self.irrigation_event_id,
                        "zone_id": zone["zone_id"],
                        "start_time": current_date.replace(
                            hour=random.choice([6, 12, 18]), minute=0
                        ),
                        "duration_minutes": random.randint(15, 120),
                        "water_amount_liters": random.randint(1000, 10000),
                        "irrigation_type": irrigation_method,
                        "trigger_type": random.choice(
                            ["scheduled", "moisture_sensor", "manual"]
                        ),
                        "soil_moisture_before": random.uniform(25, 40),
                        "soil_moisture_after": random.uniform(50, 70),
                        "efficiency": efficiency,
                        "water_source": random.choices(
                            list(self.config["irrigation"]["water_sources"].keys()),
                            weights=list(
                                self.config["irrigation"]["water_sources"].values()
                            ),
                        )[0],
                    }
                    self.irrigation_events.append(event)
                    self.irrigation_event_id += 1

            current_date += timedelta(days=1)

    def _generate_pest_detections(self):
        """Generate pest and disease detections"""
        print("  Generating pest detections...")

        for field in self.fields:
            # Generate some pest detections
            num_detections = random.randint(0, 3)

            for _ in range(num_detections):
                pest_type = random.choices(
                    list(self.config["pest_diseases"].keys()),
                    weights=[
                        self.config["pest_diseases"][p]["probability"]
                        for p in self.config["pest_diseases"].keys()
                    ],
                )[0]

                pest_config = self.config["pest_diseases"][pest_type]

                detection = {
                    "detection_id": self.pest_detection_id,
                    "field_id": field["field_id"],
                    "detection_date": datetime.now()
                    - timedelta(days=random.randint(0, 30)),
                    "pest_type": pest_type,
                    "severity": random.choice(["low", "medium", "high"]),
                    "affected_area_pct": random.uniform(
                        5, pest_config["damage_rate"] * 100
                    ),
                    "treatment_applied": pest_config["treatment"],
                    "treatment_date": datetime.now()
                    - timedelta(days=random.randint(0, 7)),
                    "treatment_effectiveness": random.uniform(0.7, 0.95),
                    "detection_method": random.choice(
                        ["visual", "drone", "sensor", "satellite"]
                    ),
                    "estimated_yield_loss_pct": pest_config["damage_rate"] * 100,
                }
                self.pest_detections.append(detection)
                self.pest_detection_id += 1

    def _generate_fertilizer_applications(self):
        """Generate fertilizer application records"""
        print("  Generating fertilizer applications...")

        for planting in self.plantings:
            # Generate fertilizer applications during growing season
            num_applications = random.randint(1, 3)

            for app_num in range(num_applications):
                fertilizer_type = random.choice(
                    list(self.config["fertilizer"]["types"].keys())
                )
                rate_range = self.config["fertilizer"]["application_rates"][
                    fertilizer_type
                ]

                application = {
                    "application_id": self.fertilizer_id,
                    "field_id": planting["field_id"],
                    "application_date": planting["planting_date"]
                    + timedelta(days=30 * app_num),
                    "fertilizer_type": fertilizer_type,
                    "application_rate_kg_per_hectare": random.uniform(
                        rate_range[0], rate_range[1]
                    ),
                    "application_method": random.choice(
                        ["broadcast", "banding", "foliar", "injection"]
                    ),
                    "cost_per_kg": random.uniform(0.5, 2.0),
                    "weather_conditions": random.choice(
                        ["clear", "cloudy", "light_rain"]
                    ),
                    "soil_temperature": random.uniform(15, 25),
                    "soil_moisture": random.uniform(40, 60),
                }
                self.fertilizer_applications.append(application)
                self.fertilizer_id += 1

    def _generate_harvest_data(self):
        """Generate harvest records"""
        print("  Generating harvest data...")

        for planting in self.plantings:
            crop = next(c for c in self.crops if c["crop_id"] == planting["crop_id"])
            field = next(
                f for f in self.fields if f["field_id"] == planting["field_id"]
            )

            # Calculate yield based on conditions
            base_yield = crop["expected_yield_kg_per_hectare"]
            yield_factor = 1.0

            # Apply yield factors
            if random.random() < 0.2:  # 20% chance of suboptimal conditions
                yield_factor *= random.choice(
                    list(self.config["yield_factors"].values())
                )

            actual_yield = base_yield * yield_factor * field["area_hectares"]

            harvest = {
                "harvest_id": self.harvest_id,
                "planting_id": planting["planting_id"],
                "field_id": planting["field_id"],
                "crop_id": planting["crop_id"],
                "harvest_date": planting["expected_harvest_date"]
                + timedelta(days=random.randint(-7, 7)),
                "yield_kg": round(actual_yield, 2),
                "yield_per_hectare": round(actual_yield / field["area_hectares"], 2),
                "moisture_content_pct": random.uniform(12, 20),
                "quality_grade": random.choice(["A", "B", "C"]),
                "market_price_per_kg": crop["market_price_per_kg"],
                "total_revenue": round(actual_yield * crop["market_price_per_kg"], 2),
                "storage_location": f"Silo_{random.randint(1, 5)}",
                "notes": (
                    "Good harvest" if yield_factor >= 0.9 else "Below average yield"
                ),
            }
            self.harvest_data.append(harvest)
            self.harvest_id += 1

    def _generate_animals(self):
        """Generate livestock records"""
        print("  Generating livestock...")

        animal_id = 1

        for farm in self.farms:
            if farm["farm_type"] in ["dairy_farm", "mixed_farm"]:
                # Generate animals for this farm
                for animal_type, config in list(self.config["livestock"].items())[:2]:
                    count_range = config["count"]
                    num_animals = random.randint(count_range[0], count_range[1])

                    for _ in range(min(num_animals, 20)):  # Limit for performance
                        animal = {
                            "animal_id": animal_id,
                            "farm_id": farm["farm_id"],
                            "tag_number": f"TAG{animal_id:06d}",
                            "animal_type": animal_type,
                            "breed": f"{animal_type.title()}-Breed{random.randint(1, 5)}",
                            "birth_date": datetime.now()
                            - timedelta(days=random.randint(180, 1825)),
                            "weight_kg": (
                                random.uniform(200, 800)
                                if animal_type == "cattle"
                                else random.uniform(50, 150)
                            ),
                            "gender": random.choice(["male", "female"]),
                            "health_status": random.choice(
                                ["healthy", "monitoring", "treatment"]
                            ),
                            "location": f"Barn_{random.randint(1, 3)}",
                            "is_active": True,
                        }
                        self.animals.append(animal)
                        animal_id += 1

    def _generate_health_readings(self):
        """Generate animal health monitoring data"""
        print("  Generating animal health readings...")

        for animal in self.animals[:20]:  # Limit for performance
            animal_config = self.config["livestock"].get(animal["animal_type"], {})

            # Generate recent health readings
            for day in range(min(7, self.config["counts"]["days_of_data"])):
                reading_time = datetime.now() - timedelta(days=day)

                health_reading = {
                    "reading_id": len(self.health_readings) + 1,
                    "animal_id": animal["animal_id"],
                    "timestamp": reading_time,
                    "body_temperature": round(random.gauss(38.5, 0.5), 1),
                    "heart_rate": random.randint(60, 100),
                    "activity_level": random.choice(["resting", "normal", "active"]),
                    "feed_intake_kg": animal_config.get("feed_per_day", 10)
                    * random.uniform(0.8, 1.2),
                    "water_intake_liters": animal_config.get("water_per_day", 50)
                    * random.uniform(0.8, 1.2),
                    "weight_kg": animal["weight_kg"] + random.uniform(-2, 2),
                    "notes": (
                        None
                        if animal["health_status"] == "healthy"
                        else "Under observation"
                    ),
                }
                self.health_readings.append(health_reading)

    def _generate_feeding_records(self):
        """Generate feeding records for livestock"""
        print("  Generating feeding records...")

        # Group animals by location for feeding
        locations = set(a["location"] for a in self.animals)

        for location in locations:
            location_animals = [a for a in self.animals if a["location"] == location]

            if location_animals:
                # Generate daily feeding records
                for day in range(self.config["counts"]["days_of_data"]):
                    feeding_time = datetime.now() - timedelta(days=day)

                    for feeding_num in range(2):  # Morning and evening feeding
                        feeding = {
                            "feeding_id": self.feeding_id,
                            "location": location,
                            "feeding_time": feeding_time.replace(
                                hour=6 if feeding_num == 0 else 18
                            ),
                            "feed_type": random.choice(
                                ["hay", "grain", "silage", "mixed"]
                            ),
                            "quantity_kg": len(location_animals)
                            * random.uniform(5, 15),
                            "animal_count": len(location_animals),
                            "cost_per_kg": random.uniform(0.2, 0.5),
                            "notes": None,
                        }
                        self.feeding_records.append(feeding)
                        self.feeding_id += 1

    # Helper methods
    def _get_growth_stage(self, days_since_planting: int, planting: Dict) -> str:
        """Determine crop growth stage"""
        crop = next(c for c in self.crops if c["crop_id"] == planting["crop_id"])
        growth_days = crop["growth_days"]

        if days_since_planting < growth_days * 0.1:
            return "bare_soil"
        elif days_since_planting < growth_days * 0.3:
            return "emerging"
        elif days_since_planting < growth_days * 0.7:
            return "growing"
        elif days_since_planting < growth_days * 0.9:
            return "mature"
        else:
            return "harvest"

    def _write_all_csvs(self):
        """Write all data to CSV files"""
        datasets = [
            ("farms", self.farms),
            ("fields", self.fields),
            ("zones", self.zones),
            ("crops", self.crops),
            ("plantings", self.plantings),
            ("soil_sensors", self.soil_sensors),
            ("weather_stations", self.weather_stations),
            ("sensor_readings", self.sensor_readings[:10000]),  # Limit for size
            ("ndvi_readings", self.ndvi_readings),
            ("irrigation_events", self.irrigation_events),
            ("pest_detections", self.pest_detections),
            ("fertilizer_applications", self.fertilizer_applications),
            ("harvest_data", self.harvest_data),
            ("animals", self.animals),
            ("health_readings", self.health_readings),
            ("feeding_records", self.feeding_records),
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
        load_script = f"""-- Load generated Smart Agriculture data
-- Generated on {datetime.now()}

-- Clear existing data
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE feeding_records;
TRUNCATE TABLE health_readings;
TRUNCATE TABLE animals;
TRUNCATE TABLE harvest_data;
TRUNCATE TABLE fertilizer_applications;
TRUNCATE TABLE pest_detections;
TRUNCATE TABLE irrigation_events;
TRUNCATE TABLE ndvi_readings;
TRUNCATE TABLE sensor_readings;
TRUNCATE TABLE weather_stations;
TRUNCATE TABLE soil_sensors;
TRUNCATE TABLE plantings;
TRUNCATE TABLE crops;
TRUNCATE TABLE zones;
TRUNCATE TABLE fields;
TRUNCATE TABLE farms;
SET FOREIGN_KEY_CHECKS = 1;

-- Load data files
LOAD DATA INFILE '/var/lib/mysql-files/agriculture/farms.csv'
INTO TABLE farms
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\\n'
IGNORE 1 ROWS;

-- Update statistics
ANALYZE TABLE farms, fields, zones, sensor_readings;

SELECT 'Data load complete!' as status;
"""

        script_path = self.output_dir / "load_data.sql"
        with open(script_path, "w") as f:
            f.write(load_script)

        print(f"  [OK] Generated SQL load script: load_data.sql")


def main():
    parser = argparse.ArgumentParser(description="Generate Smart Agriculture data")
    parser.add_argument("--config", default="config.yaml", help="Path to config.yaml")
    args = parser.parse_args()

    generator = SmartAgricultureGenerator(args.config)
    generator.generate_all()


if __name__ == "__main__":
    main()
