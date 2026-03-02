#!/usr/bin/env python3
"""
Industrial IoT Manufacturing Data Generator
Generates realistic data for smart factory operations with IoT sensors, OEE metrics, and quality control
"""

import csv
import json
import random
import hashlib
from datetime import datetime, timedelta, time
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
    "factories": 3,
    "lines_per_factory": 5,
    "machines_per_line": 8,
    "sensors_per_machine": 4,  # temp, vibration, current, speed typically
    "products": 50,
    "work_orders_per_day": 20,
    "days_of_history": 30,
    "readings_per_hour": 60,  # Every minute
    "shifts_per_day": 3,
}


class IndustrialIoTGenerator:
    def __init__(self):
        self.factories: List[Any] = []
        self.production_lines: List[Any] = []
        self.machines: List[Any] = []
        self.sensors: List[Any] = []
        self.products: List[Any] = []
        self.work_orders: List[Any] = []
        self.production_runs: List[Any] = []
        self.sensor_readings: List[Any] = []
        self.quality_inspections: List[Any] = []
        self.defects: List[Any] = []
        self.oee_metrics: List[Any] = []
        self.maintenance_schedules: List[Any] = []
        self.maintenance_records: List[Any] = []
        self.alerts: List[Any] = []
        self.downtime_events: List[Any] = []

        # Counters
        self.line_id = 0
        self.machine_id = 0
        self.sensor_id = 0
        self.order_id = 0
        self.run_id = 0
        self.reading_id = 0
        self.inspection_id = 0
        self.defect_id = 0
        self.oee_id = 0
        self.schedule_id = 0
        self.record_id = 0
        self.alert_id = 0
        self.event_id = 0

        # Start date for historical data
        self.start_date = datetime.now() - timedelta(days=CONFIG["days_of_history"])

    def generate_all(self):
        """Generate all Industrial IoT data"""
        print("Starting Industrial IoT Manufacturing Data Generation...")
        print(f"Configuration:")
        print(f"  Factories: {CONFIG['factories']}")
        print(
            f"  Total production lines: {CONFIG['factories'] * CONFIG['lines_per_factory']}"
        )
        print(
            f"  Total machines: {CONFIG['factories'] * CONFIG['lines_per_factory'] * CONFIG['machines_per_line']}"
        )
        print(f"  Days of history: {CONFIG['days_of_history']}")

        # Core infrastructure
        self.generate_factories()
        self.generate_production_lines()
        self.generate_machines()
        self.generate_sensors()

        # Products and production
        self.generate_products()
        self.generate_work_orders_and_runs()

        # Quality control
        self.generate_quality_inspections()

        # Maintenance
        self.generate_maintenance()

        # IoT data and metrics
        self.generate_sensor_data_and_oee()

        # Events and alerts
        self.generate_downtime_events()
        self.generate_alerts()

        # Save all data
        self.save_all()

    def generate_factories(self):
        """Generate factory facilities"""
        print(f"Generating {CONFIG['factories']} factories...")

        factory_types = [
            "automotive",
            "electronics",
            "consumer_goods",
            "pharmaceutical",
            "food",
        ]
        locations = [
            ("Detroit", "USA", "America/Detroit"),
            ("Shanghai", "China", "Asia/Shanghai"),
            ("Stuttgart", "Germany", "Europe/Berlin"),
            ("Tokyo", "Japan", "Asia/Tokyo"),
            ("Mumbai", "India", "Asia/Kolkata"),
        ]

        for i in range(CONFIG["factories"]):
            location = locations[i % len(locations)]
            factory = {
                "factory_id": i + 1,
                "factory_name": f"{location[0]} Manufacturing Plant {i+1}",
                "factory_type": factory_types[i % len(factory_types)],
                "location": location[0],
                "country": location[1],
                "timezone": location[2],
                "established_date": fake.date_between(
                    start_date="-20y", end_date="-5y"
                ),
                "total_area_sqm": round(random.uniform(10000, 100000), 2),
                "employee_count": random.randint(100, 1000),
                "shifts_per_day": CONFIG["shifts_per_day"],
                "is_active": True,
                "created_at": fake.date_time_between(start_date="-5y", end_date="-1y"),
                "updated_at": fake.date_time_between(start_date="-30d", end_date="now"),
            }
            self.factories.append(factory)

    def generate_production_lines(self):
        """Generate production lines for each factory"""
        print(f"Generating production lines...")

        line_types = ["assembly", "packaging", "processing", "testing", "mixed"]

        for factory in self.factories:
            for line_num in range(CONFIG["lines_per_factory"]):
                self.line_id += 1

                # Product types based on factory type
                if factory["factory_type"] == "automotive":
                    product_types = [
                        "engine_parts",
                        "chassis",
                        "electronics",
                        "interior",
                    ]
                elif factory["factory_type"] == "electronics":
                    product_types = ["pcb", "components", "devices", "accessories"]
                elif factory["factory_type"] == "consumer_goods":
                    product_types = ["appliances", "furniture", "toys", "household"]
                elif factory["factory_type"] == "pharmaceutical":
                    product_types = ["tablets", "capsules", "liquids", "packaging"]
                else:  # food
                    product_types = ["beverages", "snacks", "dairy", "prepared"]

                line = {
                    "line_id": self.line_id,
                    "factory_id": factory["factory_id"],
                    "line_name": f"Line {chr(65 + line_num)}",  # Line A, B, C, etc.
                    "line_type": random.choice(line_types),
                    "capacity_per_hour": random.randint(100, 1000),
                    "product_types": json.dumps(
                        random.sample(product_types, k=random.randint(1, 3))
                    ),
                    "installation_date": fake.date_between(
                        start_date="-10y", end_date="-1y"
                    ),
                    "last_maintenance_date": fake.date_between(
                        start_date="-3m", end_date="today"
                    ),
                    "status": random.choices(
                        ["operational", "maintenance", "idle"], weights=[85, 10, 5]
                    )[0],
                    "created_at": factory["created_at"],
                    "updated_at": fake.date_time_between(
                        start_date="-7d", end_date="now"
                    ),
                }
                self.production_lines.append(line)

    def generate_machines(self):
        """Generate machines for each production line"""
        print(f"Generating machines...")

        machine_types_by_line = {
            "assembly": [
                "assembly_robot",
                "welding_robot",
                "conveyor",
                "quality_inspection",
            ],
            "packaging": ["packaging", "conveyor", "quality_inspection", "other"],
            "processing": ["cnc_mill", "injection_mold", "3d_printer", "conveyor"],
            "testing": ["quality_inspection", "conveyor", "other"],
            "mixed": [
                "cnc_mill",
                "assembly_robot",
                "packaging",
                "conveyor",
                "quality_inspection",
            ],
        }

        manufacturers = [
            "Siemens",
            "ABB",
            "Fanuc",
            "Kuka",
            "Mitsubishi",
            "Bosch",
            "Schneider",
        ]

        for line in self.production_lines:
            machine_types = machine_types_by_line.get(line["line_type"], ["other"])

            for machine_num in range(CONFIG["machines_per_line"]):
                self.machine_id += 1

                machine_type = random.choice(machine_types)

                # Set capacity based on machine type
                capacity_ranges = {
                    "cnc_mill": (50, 200),
                    "injection_mold": (100, 500),
                    "assembly_robot": (200, 800),
                    "conveyor": (500, 2000),
                    "packaging": (300, 1000),
                    "quality_inspection": (100, 400),
                    "welding_robot": (50, 300),
                    "3d_printer": (10, 50),
                    "other": (100, 500),
                }
                capacity = random.randint(
                    *capacity_ranges.get(machine_type, (100, 500))
                )

                machine = {
                    "machine_id": self.machine_id,
                    "line_id": line["line_id"],
                    "machine_code": f"MCH{line['line_id']:03d}{machine_num:02d}",
                    "machine_name": f"{machine_type.replace('_', ' ').title()} {machine_num+1}",
                    "machine_type": machine_type,
                    "manufacturer": random.choice(manufacturers),
                    "model": f"Model-{random.randint(1000, 9999)}",
                    "serial_number": fake.bothify(text="SN-########-??"),
                    "installation_date": line["installation_date"],
                    "warranty_expiry": fake.date_between(
                        start_date="today", end_date="+3y"
                    ),
                    "ideal_cycle_time_seconds": round(
                        3600 / capacity, 2
                    ),  # Based on capacity
                    "max_capacity_per_hour": capacity,
                    "power_consumption_kw": round(random.uniform(5, 50), 2),
                    "status": random.choices(
                        ["running", "idle", "maintenance", "error", "offline"],
                        weights=[60, 25, 10, 3, 2],
                    )[0],
                    "total_operating_hours": round(random.uniform(1000, 50000), 2),
                    "total_cycle_count": random.randint(10000, 5000000),
                    "created_at": line["created_at"],
                    "updated_at": fake.date_time_between(
                        start_date="-1d", end_date="now"
                    ),
                }
                self.machines.append(machine)

    def generate_sensors(self):
        """Generate IoT sensors for machines"""
        print(f"Generating sensors...")

        sensor_configs = {
            "temperature": {
                "unit": "°C",
                "min": -50,
                "max": 200,
                "normal_min": 20,
                "normal_max": 80,
            },
            "vibration": {
                "unit": "mm/s",
                "min": 0,
                "max": 100,
                "normal_min": 0,
                "normal_max": 10,
            },
            "pressure": {
                "unit": "bar",
                "min": 0,
                "max": 100,
                "normal_min": 1,
                "normal_max": 10,
            },
            "current": {
                "unit": "A",
                "min": 0,
                "max": 1000,
                "normal_min": 10,
                "normal_max": 100,
            },
            "voltage": {
                "unit": "V",
                "min": 0,
                "max": 1000,
                "normal_min": 200,
                "normal_max": 240,
            },
            "speed": {
                "unit": "rpm",
                "min": 0,
                "max": 10000,
                "normal_min": 500,
                "normal_max": 3000,
            },
            "flow": {
                "unit": "l/min",
                "min": 0,
                "max": 1000,
                "normal_min": 10,
                "normal_max": 100,
            },
            "force": {
                "unit": "N",
                "min": 0,
                "max": 10000,
                "normal_min": 100,
                "normal_max": 1000,
            },
        }

        for machine in self.machines:
            # Determine sensor types based on machine type
            if machine["machine_type"] in ["cnc_mill", "injection_mold"]:
                sensor_types = ["temperature", "vibration", "current", "speed"]
            elif machine["machine_type"] in ["assembly_robot", "welding_robot"]:
                sensor_types = ["temperature", "current", "force", "vibration"]
            elif machine["machine_type"] == "conveyor":
                sensor_types = ["speed", "current", "vibration"]
            elif machine["machine_type"] == "packaging":
                sensor_types = ["speed", "pressure", "temperature"]
            elif machine["machine_type"] == "quality_inspection":
                sensor_types = ["temperature", "current"]
            else:
                sensor_types = random.sample(list(sensor_configs.keys()), k=3)

            for sensor_type in sensor_types:
                self.sensor_id += 1
                config = sensor_configs[sensor_type]

                sensor = {
                    "sensor_id": self.sensor_id,
                    "machine_id": machine["machine_id"],
                    "sensor_code": f"SEN{machine['machine_code']}{sensor_type[:3].upper()}",
                    "sensor_type": sensor_type,
                    "unit_of_measure": config["unit"],
                    "min_value": config["min"],
                    "max_value": config["max"],
                    "normal_min": config["normal_min"],
                    "normal_max": config["normal_max"],
                    "critical_min": config["normal_min"] * 0.8,
                    "critical_max": config["normal_max"] * 1.2,
                    "sampling_rate_seconds": 60,  # Every minute
                    "calibration_date": fake.date_between(
                        start_date="-6m", end_date="today"
                    ),
                    "is_active": random.random() > 0.05,
                    "created_at": machine["created_at"],
                }
                self.sensors.append(sensor)

    def generate_products(self):
        """Generate product catalog"""
        print(f"Generating {CONFIG['products']} products...")

        categories_by_factory = {
            "automotive": [
                "engine_component",
                "brake_system",
                "suspension",
                "electrical",
                "body_part",
            ],
            "electronics": [
                "circuit_board",
                "display",
                "sensor",
                "connector",
                "housing",
            ],
            "consumer_goods": ["appliance", "furniture", "toy", "tool", "accessory"],
            "pharmaceutical": ["tablet", "capsule", "liquid", "cream", "powder"],
            "food": ["beverage", "snack", "dairy", "frozen", "canned"],
        }

        for i in range(CONFIG["products"]):
            factory_type = random.choice(list(categories_by_factory.keys()))
            category = random.choice(categories_by_factory[factory_type])

            # Generate BOM (Bill of Materials)
            bom = []
            num_components = random.randint(3, 10)
            for j in range(num_components):
                bom.append(
                    {
                        "component_id": f"CMP{random.randint(1000, 9999)}",
                        "quantity": random.randint(1, 10),
                        "unit": random.choice(["piece", "kg", "meter", "liter"]),
                    }
                )

            # Quality specifications
            quality_specs = {
                "tolerance": f"±{random.uniform(0.01, 0.1):.3f}",
                "surface_finish": random.choice(
                    ["smooth", "textured", "polished", "matte"]
                ),
                "hardness": random.randint(20, 80),
                "color": random.choice(
                    ["black", "white", "silver", "blue", "red", "green"]
                ),
            }

            product = {
                "product_id": i + 1,
                "product_code": f"PRD{str(i+1).zfill(5)}",
                "product_name": f"{category.replace('_', ' ').title()} {fake.word().capitalize()} {random.randint(100, 999)}",
                "product_category": category,
                "unit_of_measure": random.choice(
                    ["unit", "piece", "kg", "meter", "liter"]
                ),
                "standard_cycle_time_seconds": round(random.uniform(10, 300), 2),
                "weight_kg": round(random.uniform(0.1, 50), 3),
                "quality_specs": json.dumps(quality_specs),
                "bom": json.dumps(bom),
                "created_at": fake.date_time_between(start_date="-2y", end_date="-6m"),
                "updated_at": fake.date_time_between(start_date="-30d", end_date="now"),
            }
            self.products.append(product)

    def generate_work_orders_and_runs(self):
        """Generate work orders and production runs"""
        print("Generating work orders and production runs...")

        current_date = self.start_date

        while current_date < datetime.now():
            daily_orders = random.randint(
                int(CONFIG["work_orders_per_day"] * 0.7),
                int(CONFIG["work_orders_per_day"] * 1.3),
            )

            for _ in range(daily_orders):
                self.order_id += 1

                # Select product and line
                product = random.choice(self.products)
                line = random.choice(
                    [l for l in self.production_lines if l["status"] == "operational"]
                )

                # Plan production
                planned_quantity = random.randint(100, 1000)
                planned_hours = (
                    planned_quantity * product["standard_cycle_time_seconds"] / 3600
                )
                planned_start = current_date + timedelta(hours=random.randint(0, 16))
                planned_end = planned_start + timedelta(hours=planned_hours)

                # Determine actual performance
                efficiency = random.uniform(0.85, 1.05)  # 85-105% efficiency
                actual_quantity = int(planned_quantity * efficiency)
                quality_rate = random.uniform(0.92, 0.99)  # 92-99% quality
                good_quantity = int(actual_quantity * quality_rate)
                rejected_quantity = actual_quantity - good_quantity

                order = {
                    "order_id": self.order_id,
                    "order_number": f"WO{current_date.strftime('%Y%m%d')}{str(self.order_id).zfill(4)}",
                    "product_id": product["product_id"],
                    "line_id": line["line_id"],
                    "planned_quantity": planned_quantity,
                    "planned_start_time": planned_start,
                    "planned_end_time": planned_end,
                    "actual_start_time": planned_start
                    + timedelta(minutes=random.randint(-30, 30)),
                    "actual_end_time": planned_end
                    + timedelta(minutes=random.randint(-60, 120)),
                    "produced_quantity": actual_quantity,
                    "good_quantity": good_quantity,
                    "rejected_quantity": rejected_quantity,
                    "status": (
                        "completed"
                        if current_date < datetime.now() - timedelta(days=1)
                        else "in_progress"
                    ),
                    "priority": random.randint(1, 10),
                    "created_at": current_date,
                    "updated_at": current_date + timedelta(hours=random.randint(1, 24)),
                }
                self.work_orders.append(order)

                # Create production runs for this order
                if order["status"] == "completed":
                    machines_on_line = [
                        m for m in self.machines if m["line_id"] == line["line_id"]
                    ]

                    for machine in random.sample(
                        machines_on_line, k=min(3, len(machines_on_line))
                    ):
                        self.run_id += 1

                        run = {
                            "run_id": self.run_id,
                            "order_id": self.order_id,
                            "machine_id": machine["machine_id"],
                            "operator_id": random.randint(
                                1, 100
                            ),  # Assuming 100 operators
                            "start_time": order["actual_start_time"],
                            "end_time": order["actual_end_time"],
                            "quantity_produced": actual_quantity
                            // len(machines_on_line),
                            "quantity_good": good_quantity // len(machines_on_line),
                            "quantity_rejected": rejected_quantity
                            // len(machines_on_line),
                            "cycle_time_actual": round(
                                product["standard_cycle_time_seconds"]
                                * random.uniform(0.9, 1.1),
                                2,
                            ),
                            "downtime_minutes": round(random.uniform(0, 30), 2),
                            "speed_percentage": round(random.uniform(85, 105), 2),
                            "notes": fake.sentence() if random.random() > 0.8 else None,
                        }
                        self.production_runs.append(run)

            current_date += timedelta(days=1)

    def generate_quality_inspections(self):
        """Generate quality inspections and defects"""
        print("Generating quality inspections...")

        defect_types = {
            "dimensional": [
                "length_deviation",
                "width_deviation",
                "thickness_deviation",
                "diameter_deviation",
            ],
            "surface": [
                "scratch",
                "dent",
                "rough_finish",
                "discoloration",
                "contamination",
            ],
            "functional": [
                "not_working",
                "intermittent",
                "out_of_spec",
                "loose_connection",
            ],
            "cosmetic": [
                "color_mismatch",
                "texture_issue",
                "label_defect",
                "packaging_damage",
            ],
        }

        for run in random.sample(
            self.production_runs, min(len(self.production_runs) // 3, 1000)
        ):
            self.inspection_id += 1

            sample_size = min(10, run["quantity_produced"])
            defects_found = min(
                run["quantity_rejected"], random.randint(0, sample_size // 5)
            )

            # Determine defect types found
            found_defect_types = []
            if defects_found > 0:
                category = random.choice(list(defect_types.keys()))
                found_defect_types = random.sample(
                    defect_types[category], k=min(defects_found, 3)
                )

            # Generate measurements
            measurements = {
                "dimension_1": round(random.uniform(9.95, 10.05), 3),
                "dimension_2": round(random.uniform(19.9, 20.1), 3),
                "weight": round(random.uniform(99.5, 100.5), 2),
                "hardness": random.randint(45, 55),
            }

            inspection = {
                "inspection_id": self.inspection_id,
                "run_id": run["run_id"],
                "product_id": next(
                    wo["product_id"]
                    for wo in self.work_orders
                    if wo["order_id"] == run["order_id"]
                ),
                "inspection_time": run["end_time"]
                + timedelta(minutes=random.randint(5, 30)),
                "inspector_id": random.randint(1, 20),  # Assuming 20 inspectors
                "sample_size": sample_size,
                "defects_found": defects_found,
                "defect_types": json.dumps(found_defect_types),
                "measurements": json.dumps(measurements),
                "pass_fail": "fail" if defects_found > sample_size * 0.1 else "pass",
                "notes": fake.sentence() if random.random() > 0.7 else None,
            }
            self.quality_inspections.append(inspection)

            # Create defect records
            for defect_type in found_defect_types:
                self.defect_id += 1

                defect = {
                    "defect_id": self.defect_id,
                    "inspection_id": self.inspection_id,
                    "defect_type": defect_type,
                    "severity": random.choice(
                        ["critical", "major", "minor", "cosmetic"]
                    ),
                    "quantity": random.randint(
                        1, max(1, defects_found // len(found_defect_types))
                    ),
                    "root_cause": random.choice(
                        [
                            "material_issue",
                            "process_deviation",
                            "equipment_malfunction",
                            "operator_error",
                            "unknown",
                        ]
                    ),
                    "corrective_action": fake.sentence(),
                    "image_url": (
                        f"https://images.example.com/defect_{self.defect_id}.jpg"
                        if random.random() > 0.5
                        else None
                    ),
                    "created_at": inspection["inspection_time"],
                }
                self.defects.append(defect)

    def generate_maintenance(self):
        """Generate maintenance schedules and records"""
        print("Generating maintenance schedules and records...")

        maintenance_types = ["preventive", "predictive", "corrective", "calibration"]

        # Create maintenance schedules for each machine
        for machine in self.machines:
            # Preventive maintenance schedule
            self.schedule_id += 1
            schedule = {
                "schedule_id": self.schedule_id,
                "machine_id": machine["machine_id"],
                "maintenance_type": "preventive",
                "frequency_days": random.choice([30, 60, 90, 180]),
                "last_performed": fake.date_between(start_date="-3m", end_date="today"),
                "next_due": fake.date_between(start_date="today", end_date="+3m"),
                "estimated_duration_hours": round(random.uniform(1, 8), 2),
                "parts_required": (
                    json.dumps(
                        [
                            {"part": "filter", "quantity": 2},
                            {"part": "oil", "quantity": 5, "unit": "liters"},
                            {"part": "belt", "quantity": 1},
                        ]
                    )
                    if random.random() > 0.5
                    else None
                ),
                "is_active": True,
                "created_at": machine["created_at"],
            }
            self.maintenance_schedules.append(schedule)

            # Create maintenance records
            if random.random() > 0.3:  # 70% of machines have maintenance history
                for _ in range(random.randint(1, 5)):
                    self.record_id += 1

                    maintenance_date = fake.date_time_between(
                        start_date="-6m", end_date="now"
                    )
                    duration_hours = random.uniform(0.5, 8)

                    record = {
                        "record_id": self.record_id,
                        "machine_id": machine["machine_id"],
                        "schedule_id": (
                            self.schedule_id if random.random() > 0.3 else None
                        ),
                        "maintenance_type": random.choice(maintenance_types),
                        "start_time": maintenance_date,
                        "end_time": maintenance_date + timedelta(hours=duration_hours),
                        "technician_id": random.randint(
                            1, 10
                        ),  # Assuming 10 technicians
                        "downtime_minutes": round(duration_hours * 60, 2),
                        "parts_replaced": (
                            json.dumps(
                                [
                                    {
                                        "part": random.choice(
                                            ["filter", "belt", "bearing", "seal"]
                                        ),
                                        "quantity": random.randint(1, 3),
                                    }
                                ]
                            )
                            if random.random() > 0.5
                            else None
                        ),
                        "cost": round(random.uniform(100, 5000), 2),
                        "findings": fake.paragraph() if random.random() > 0.5 else None,
                        "actions_taken": fake.sentence(),
                        "next_action": (
                            fake.sentence() if random.random() > 0.7 else None
                        ),
                        "status": "completed",
                        "created_at": maintenance_date,
                        "updated_at": maintenance_date
                        + timedelta(hours=duration_hours),
                    }
                    self.maintenance_records.append(record)

    def generate_sensor_data_and_oee(self):
        """Generate sensor readings and OEE metrics"""
        print("Generating sensor data and OEE metrics (this may take a while)...")

        # Sample period for detailed generation
        sample_days = min(7, CONFIG["days_of_history"])
        start_date = datetime.now() - timedelta(days=sample_days)

        for day in range(sample_days):
            current_date = start_date + timedelta(days=day)

            # Generate hourly OEE metrics for each machine
            for machine in random.sample(self.machines, min(50, len(self.machines))):
                for hour in range(24):
                    hour_start = current_date.replace(
                        hour=hour, minute=0, second=0, microsecond=0
                    )
                    hour_end = hour_start + timedelta(hours=1)

                    # Calculate OEE components
                    planned_time = 60  # minutes
                    downtime = random.uniform(0, 15) if random.random() > 0.7 else 0
                    operating_time = planned_time - downtime
                    availability = (
                        (operating_time / planned_time * 100) if planned_time > 0 else 0
                    )

                    # Performance calculation
                    ideal_cycle_time = machine["ideal_cycle_time_seconds"]
                    theoretical_output = (
                        (operating_time * 60) / ideal_cycle_time
                        if ideal_cycle_time > 0
                        else 0
                    )
                    actual_output = int(theoretical_output * random.uniform(0.8, 1.1))
                    performance = (
                        (actual_output / theoretical_output * 100)
                        if theoretical_output > 0
                        else 0
                    )

                    # Quality calculation
                    good_pieces = int(actual_output * random.uniform(0.92, 0.99))
                    quality = (
                        (good_pieces / actual_output * 100) if actual_output > 0 else 0
                    )

                    # OEE calculation
                    oee = (availability * performance * quality) / 10000

                    self.oee_id += 1
                    oee_metric = {
                        "oee_id": self.oee_id,
                        "machine_id": machine["machine_id"],
                        "line_id": machine["line_id"],
                        "metric_timestamp": hour_end,
                        "hour_start": hour_start,
                        "hour_end": hour_end,
                        "planned_production_time_min": planned_time,
                        "operating_time_min": round(operating_time, 2),
                        "downtime_min": round(downtime, 2),
                        "availability_percentage": round(availability, 2),
                        "ideal_cycle_time_sec": ideal_cycle_time,
                        "total_pieces_produced": actual_output,
                        "performance_percentage": round(performance, 2),
                        "good_pieces": good_pieces,
                        "total_pieces": actual_output,
                        "quality_percentage": round(quality, 2),
                        "oee_percentage": round(oee, 2),
                    }
                    self.oee_metrics.append(oee_metric)

                    # Generate sensor readings for this hour (sampled)
                    machine_sensors = [
                        s
                        for s in self.sensors
                        if s["machine_id"] == machine["machine_id"]
                    ]

                    for sensor in machine_sensors:
                        # Generate readings every 5 minutes (12 per hour)
                        for minute in range(0, 60, 5):
                            reading_time = hour_start + timedelta(minutes=minute)

                            # Calculate sensor value based on machine status and type
                            value = self.calculate_sensor_value(
                                sensor, machine, operating_time > 0
                            )

                            self.reading_id += 1
                            reading = {
                                "reading_id": self.reading_id,
                                "sensor_id": sensor["sensor_id"],
                                "timestamp": reading_time,
                                "value": round(value, 4),
                                "quality": (
                                    "good"
                                    if random.random() > 0.05
                                    else random.choice(["uncertain", "bad"])
                                ),
                            }
                            self.sensor_readings.append(reading)

    def calculate_sensor_value(self, sensor, machine, is_running):
        """Calculate realistic sensor value based on context"""

        if sensor["sensor_type"] == "temperature":
            # Base temperature depends on running state
            base_temp = 60 if is_running else 25
            # Add variation based on machine type
            if machine["machine_type"] in ["welding_robot", "injection_mold"]:
                base_temp += 20
            # Add random variation
            value = base_temp + random.uniform(-10, 10)

        elif sensor["sensor_type"] == "vibration":
            # Higher vibration when running
            base_vibration = 5 if is_running else 0.5
            # Add wear factor based on operating hours
            wear_factor = min(machine["total_operating_hours"] / 50000, 2)
            value = base_vibration * (1 + wear_factor * 0.5) + random.uniform(-1, 1)

        elif sensor["sensor_type"] == "current":
            # Current draw depends on running state
            if is_running:
                # Based on power consumption
                base_current = machine["power_consumption_kw"] * 2  # Rough conversion
                value = base_current * random.uniform(0.8, 1.2)
            else:
                value = random.uniform(0, 5)  # Standby current

        elif sensor["sensor_type"] == "speed":
            # Speed when running
            if is_running:
                # Based on machine capacity
                nominal_speed = (
                    machine["max_capacity_per_hour"] * 10
                )  # Rough RPM estimate
                value = nominal_speed * random.uniform(0.85, 1.05)
            else:
                value = 0

        elif sensor["sensor_type"] == "pressure":
            # Pressure for hydraulic/pneumatic systems
            base_pressure = 6 if is_running else 1
            value = base_pressure + random.uniform(-0.5, 0.5)

        elif sensor["sensor_type"] == "flow":
            # Coolant or material flow
            base_flow = 50 if is_running else 0
            value = base_flow + random.uniform(-5, 5)

        elif sensor["sensor_type"] == "force":
            # Force sensors for robots
            if is_running:
                value = random.uniform(100, 1000)
            else:
                value = random.uniform(0, 10)

        else:  # voltage, humidity, acoustic, position
            value = random.uniform(sensor["normal_min"], sensor["normal_max"])

        # Ensure value is within sensor limits
        value = max(sensor["min_value"], min(sensor["max_value"], value))

        return value

    def generate_downtime_events(self):
        """Generate downtime events"""
        print("Generating downtime events...")

        reason_categories = [
            "equipment_failure",
            "changeover",
            "material_shortage",
            "quality_issue",
            "no_operator",
            "planned_maintenance",
            "unplanned_maintenance",
            "other",
        ]

        # Generate downtime events based on OEE data
        for oee in random.sample(
            self.oee_metrics, min(len(self.oee_metrics) // 10, 500)
        ):
            if oee["downtime_min"] > 5:  # Only create event for significant downtime
                self.event_id += 1

                machine = next(
                    m for m in self.machines if m["machine_id"] == oee["machine_id"]
                )

                event = {
                    "event_id": self.event_id,
                    "machine_id": oee["machine_id"],
                    "line_id": oee["line_id"],
                    "start_time": oee["hour_start"]
                    + timedelta(minutes=random.randint(0, 50)),
                    "end_time": oee["hour_start"]
                    + timedelta(minutes=60 - oee["downtime_min"]),
                    "duration_minutes": oee["downtime_min"],
                    "reason_category": random.choice(reason_categories),
                    "reason_detail": fake.sentence(),
                    "impact_level": random.choice(
                        ["line_stop", "reduced_speed", "quality_impact"]
                    ),
                    "lost_production_units": int(
                        oee["downtime_min"] / machine["ideal_cycle_time_seconds"] * 60
                    ),
                    "created_at": oee["hour_end"],
                }
                self.downtime_events.append(event)

    def generate_alerts(self):
        """Generate system alerts"""
        print("Generating alerts...")

        alert_configs = [
            {
                "source": "sensor",
                "type": "temperature_high",
                "severity": "high",
                "message": "Temperature exceeds threshold",
            },
            {
                "source": "sensor",
                "type": "vibration_high",
                "severity": "medium",
                "message": "Abnormal vibration detected",
            },
            {
                "source": "machine",
                "type": "oee_low",
                "severity": "low",
                "message": "OEE below target",
            },
            {
                "source": "line",
                "type": "production_delay",
                "severity": "medium",
                "message": "Production behind schedule",
            },
            {
                "source": "quality",
                "type": "defect_rate_high",
                "severity": "high",
                "message": "Quality issues detected",
            },
            {
                "source": "maintenance",
                "type": "maintenance_due",
                "severity": "low",
                "message": "Scheduled maintenance due",
            },
        ]

        # Generate alerts based on various triggers
        for _ in range(random.randint(100, 500)):
            config = random.choice(alert_configs)

            # Determine source ID based on type
            if config["source"] == "sensor":
                source_id = random.choice(self.sensors)["sensor_id"]
            elif config["source"] == "machine":
                source_id = random.choice(self.machines)["machine_id"]
            elif config["source"] == "line":
                source_id = random.choice(self.production_lines)["line_id"]
            elif config["source"] == "quality":
                source_id = (
                    random.choice(self.quality_inspections)["inspection_id"]
                    if self.quality_inspections
                    else 1
                )
            else:  # maintenance
                source_id = (
                    random.choice(self.maintenance_schedules)["schedule_id"]
                    if self.maintenance_schedules
                    else 1
                )

            triggered_time = fake.date_time_between(
                start_date=self.start_date, end_date="now"
            )

            self.alert_id += 1
            alert = {
                "alert_id": self.alert_id,
                "source_type": config["source"],
                "source_id": source_id,
                "alert_type": config["type"],
                "severity": config["severity"],
                "message": config["message"],
                "threshold_value": round(random.uniform(50, 100), 4),
                "actual_value": round(random.uniform(60, 120), 4),
                "triggered_at": triggered_time,
                "acknowledged_at": (
                    triggered_time + timedelta(minutes=random.randint(5, 60))
                    if random.random() > 0.2
                    else None
                ),
                "acknowledged_by": (
                    random.randint(1, 10) if random.random() > 0.2 else None
                ),
                "resolved_at": (
                    triggered_time + timedelta(hours=random.randint(1, 24))
                    if random.random() > 0.3
                    else None
                ),
                "resolved_by": random.randint(1, 10) if random.random() > 0.3 else None,
                "resolution_notes": fake.sentence() if random.random() > 0.5 else None,
            }
            self.alerts.append(alert)

    def save_to_csv(self, table_name, data):
        """Save data to CSV file"""
        if not data:
            return

        output_file = OUTPUT_DIR / f"{table_name}.csv"

        with open(output_file, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=data[0].keys())
            writer.writeheader()
            writer.writerows(data)

    def save_all(self):
        """Save all generated data to CSV files"""
        print("\nSaving data to CSV files...")

        OUTPUT_DIR.mkdir(exist_ok=True)

        # Save all tables
        tables = [
            ("factories", self.factories),
            ("production_lines", self.production_lines),
            ("machines", self.machines),
            ("sensors", self.sensors),
            ("products", self.products),
            ("work_orders", self.work_orders),
            ("production_runs", self.production_runs),
            ("quality_inspections", self.quality_inspections),
            ("defects", self.defects),
            ("oee_metrics", self.oee_metrics),
            ("maintenance_schedules", self.maintenance_schedules),
            ("maintenance_records", self.maintenance_records),
            ("alerts", self.alerts),
            ("downtime_events", self.downtime_events),
            ("sensor_readings", self.sensor_readings),
        ]

        for table_name, data in tables:
            if data:
                self.save_to_csv(table_name, data)
                print(f"  [OK] {table_name}: {len(data):,} records")

        # Generate summary statistics
        self.generate_summary()

    def generate_summary(self):
        """Generate summary statistics"""
        # Calculate average OEE
        avg_oee = (
            sum(m["oee_percentage"] for m in self.oee_metrics) / len(self.oee_metrics)
            if self.oee_metrics
            else 0
        )

        # Calculate quality rate
        total_good = sum(wo["good_quantity"] for wo in self.work_orders)
        total_produced = sum(wo["produced_quantity"] for wo in self.work_orders)
        quality_rate = (total_good / total_produced * 100) if total_produced > 0 else 0

        summary = f"""
Industrial IoT Manufacturing Data Generation Summary
====================================================
Infrastructure:
  Factories: {len(self.factories)}
  Production Lines: {len(self.production_lines)}
  Machines: {len(self.machines)}
  Sensors: {len(self.sensors)}

Production:
  Products: {len(self.products)}
  Work Orders: {len(self.work_orders)}
  Production Runs: {len(self.production_runs)}
  Total Units Produced: {total_produced:,}

Quality:
  Inspections: {len(self.quality_inspections)}
  Defects Found: {len(self.defects)}
  Quality Rate: {quality_rate:.2f}%

Performance:
  OEE Records: {len(self.oee_metrics)}
  Average OEE: {avg_oee:.2f}%
  Downtime Events: {len(self.downtime_events)}

Maintenance:
  Schedules: {len(self.maintenance_schedules)}
  Records: {len(self.maintenance_records)}

IoT Data:
  Sensor Readings: {len(self.sensor_readings):,}
  Alerts Generated: {len(self.alerts)}

Files Generated: {len(list(OUTPUT_DIR.glob('*.csv')))}
"""

        print(summary)

        # Save summary to file
        with open(OUTPUT_DIR / "generation_summary.txt", "w") as f:
            f.write(summary)


if __name__ == "__main__":
    generator = IndustrialIoTGenerator()
    generator.generate_all()
    print("\n[SUCCESS] Industrial IoT Manufacturing data generation complete!")
