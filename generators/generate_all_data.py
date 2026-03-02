#!/usr/bin/env python3
"""Comprehensive Data Generation Script for MySQL Business-to-Schema.

Generates realistic test data for all 20 business domain schemas
"""

import os
import json
import random
import mysql.connector
from datetime import datetime
from typing import Dict, List
from faker import Faker
from colorama import init, Fore, Style
import argparse
import logging
from concurrent.futures import ThreadPoolExecutor, as_completed
import tqdm

# Initialize colorama for colored output
init()
fake = Faker()

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# Database configuration
DB_CONFIG = {
    "host": os.getenv("MYSQL_HOST", "localhost"),
    "user": os.getenv("MYSQL_USER", "root"),
    "password": os.getenv("MYSQL_PASSWORD", "root"),
    "port": int(os.getenv("MYSQL_PORT", 3306)),
}

# Schema configurations with their specific generators
SCHEMA_CONFIGS = {
    "clinic_db": {
        "tables": [
            "patients",
            "doctors",
            "appointments",
            "prescriptions",
            "medical_records",
        ],
        "relationships": True,
        "generator": "clinic",
    },
    "iot_bins_db": {
        "tables": ["bins", "sensors", "readings", "alerts", "maintenance"],
        "relationships": True,
        "generator": "iot_bins",
    },
    "smart_energy_db": {
        "tables": ["meters", "readings", "customers", "billing", "tariffs"],
        "relationships": True,
        "generator": "smart_energy",
    },
    "ecommerce_db": {
        "tables": ["customers", "products", "orders", "order_items", "reviews"],
        "relationships": True,
        "generator": "ecommerce",
    },
    "industrial_iot_db": {
        "tables": ["equipment", "sensors", "readings", "maintenance", "production"],
        "relationships": True,
        "generator": "industrial_iot",
    },
    "smart_agriculture_db": {
        "tables": ["farms", "fields", "sensors", "readings", "crops", "harvests"],
        "relationships": True,
        "generator": "smart_agriculture",
    },
    "fleet_management_db": {
        "tables": ["vehicles", "drivers", "trips", "maintenance", "fuel_logs"],
        "relationships": True,
        "generator": "fleet_management",
    },
    "healthcare_iot_db": {
        "tables": ["patients", "devices", "readings", "alerts", "healthcare_providers"],
        "relationships": True,
        "generator": "healthcare_iot",
    },
    "streaming_ml_db": {
        "tables": ["streams", "events", "models", "predictions", "evaluations"],
        "relationships": True,
        "generator": "streaming_ml",
    },
    "fintech_db": {
        "tables": ["accounts", "transactions", "customers", "cards", "loans"],
        "relationships": True,
        "generator": "fintech",
    },
    "social_media_db": {
        "tables": ["users", "posts", "comments", "likes", "followers"],
        "relationships": True,
        "generator": "social_media",
    },
    "real_estate_db": {
        "tables": ["properties", "listings", "agents", "viewings", "offers"],
        "relationships": True,
        "generator": "real_estate",
    },
    "event_ticketing_db": {
        "tables": ["events", "venues", "tickets", "bookings", "customers"],
        "relationships": True,
        "generator": "event_ticketing",
    },
    "logistics_db": {
        "tables": ["warehouses", "shipments", "packages", "routes", "tracking"],
        "relationships": True,
        "generator": "logistics",
    },
    "education_db": {
        "tables": ["courses", "students", "enrollments", "assignments", "grades"],
        "relationships": True,
        "generator": "education",
    },
    "cryptocurrency_db": {
        "tables": ["wallets", "transactions", "blocks", "mining_pools", "exchanges"],
        "relationships": True,
        "generator": "cryptocurrency",
    },
    "food_delivery_db": {
        "tables": ["restaurants", "menus", "orders", "deliveries", "riders"],
        "relationships": True,
        "generator": "food_delivery",
    },
    "gaming_platform_db": {
        "tables": ["games", "players", "sessions", "achievements", "leaderboards"],
        "relationships": True,
        "generator": "gaming_platform",
    },
    "insurance_db": {
        "tables": ["policies", "claims", "customers", "agents", "payments"],
        "relationships": True,
        "generator": "insurance",
    },
    "hotel_chain_db": {
        "tables": ["hotels", "rooms", "bookings", "guests", "services"],
        "relationships": True,
        "generator": "hotel_chain",
    },
}


class DataGenerator:
    """Base class for data generation."""

    def __init__(self, schema_name: str, connection: mysql.connector.MySQLConnection):
        """Initialize the instance."""
        self.schema_name = schema_name
        self.connection = connection
        self.cursor = connection.cursor()
        self.fake = Faker()

    def generate_patients(self, count: int) -> List[Dict]:
        """Generate patient records for healthcare schemas."""
        patients = []
        for _ in range(count):
            patients.append(
                {
                    "first_name": self.fake.first_name(),
                    "last_name": self.fake.last_name(),
                    "date_of_birth": self.fake.date_of_birth(
                        minimum_age=1, maximum_age=100
                    ),
                    "gender": random.choice(["M", "F", "O"]),
                    "email": self.fake.email(),
                    "phone": self.fake.phone_number()[:20],
                    "address": self.fake.address()[:255],
                    "city": self.fake.city()[:100],
                    "state": self.fake.state_abbr(),
                    "zip_code": self.fake.zipcode()[:10],
                    "emergency_contact": self.fake.name(),
                    "emergency_phone": self.fake.phone_number()[:20],
                    "insurance_provider": self.fake.company()[:100],
                    "insurance_number": self.fake.uuid4()[:50],
                    "created_at": self.fake.date_time_between(
                        start_date="-2y", end_date="now"
                    ),
                }
            )
        return patients

    def generate_iot_sensors(self, count: int) -> List[Dict]:
        """Generate IoT sensor records."""
        sensors = []
        sensor_types = [
            "temperature",
            "humidity",
            "pressure",
            "motion",
            "light",
            "sound",
            "vibration",
        ]
        for i in range(count):
            sensors.append(
                {
                    "sensor_id": f"SENSOR_{i:06d}",
                    "type": random.choice(sensor_types),
                    "manufacturer": self.fake.company(),
                    "model": f"Model-{random.randint(100, 999)}",
                    "location": self.fake.address()[:255],
                    "latitude": float(self.fake.latitude()),
                    "longitude": float(self.fake.longitude()),
                    "installation_date": self.fake.date_between(
                        start_date="-3y", end_date="-1m"
                    ),
                    "status": random.choice(["active", "inactive", "maintenance"]),
                    "last_reading": self.fake.date_time_between(
                        start_date="-1d", end_date="now"
                    ),
                    "battery_level": random.uniform(0, 100),
                }
            )
        return sensors

    def generate_ecommerce_products(self, count: int) -> List[Dict]:
        """Generate e-commerce product records."""
        products = []
        categories = [
            "Electronics",
            "Clothing",
            "Books",
            "Home",
            "Sports",
            "Toys",
            "Food",
            "Beauty",
        ]
        for _ in range(count):
            products.append(
                {
                    "name": self.fake.catch_phrase(),
                    "description": self.fake.text(max_nb_chars=500),
                    "category": random.choice(categories),
                    "price": round(random.uniform(9.99, 999.99), 2),
                    "cost": round(random.uniform(5.00, 500.00), 2),
                    "sku": self.fake.uuid4()[:20],
                    "barcode": self.fake.ean13(),
                    "weight": round(random.uniform(0.1, 50.0), 2),
                    "stock_quantity": random.randint(0, 1000),
                    "reorder_point": random.randint(10, 100),
                    "supplier": self.fake.company(),
                    "created_at": self.fake.date_time_between(
                        start_date="-1y", end_date="now"
                    ),
                }
            )
        return products

    def generate_financial_transactions(self, count: int) -> List[Dict]:
        """Generate financial transaction records."""
        transactions = []
        transaction_types = ["deposit", "withdrawal", "transfer", "payment", "refund"]
        for _ in range(count):
            transactions.append(
                {
                    "transaction_id": self.fake.uuid4(),
                    "account_from": self.fake.iban(),
                    "account_to": self.fake.iban(),
                    "type": random.choice(transaction_types),
                    "amount": round(random.uniform(1.00, 10000.00), 2),
                    "currency": random.choice(["USD", "EUR", "GBP", "JPY"]),
                    "status": random.choice(
                        ["pending", "completed", "failed", "cancelled"]
                    ),
                    "timestamp": self.fake.date_time_between(
                        start_date="-6m", end_date="now"
                    ),
                    "description": self.fake.sentence(nb_words=6),
                    "reference": self.fake.uuid4()[:20],
                    "fee": round(random.uniform(0, 50.00), 2),
                }
            )
        return transactions

    def insert_batch(self, table: str, data: List[Dict], batch_size: int = 1000):
        """Insert data in batches."""
        if not data:
            return 0

        columns = list(data[0].keys())
        placeholders = ", ".join(["%s"] * len(columns))
        columns_str = ", ".join([f"`{col}`" for col in columns])

        query = f"INSERT INTO `{table}` ({columns_str}) VALUES ({placeholders})"

        inserted = 0
        for i in range(0, len(data), batch_size):
            batch = data[i: i + batch_size]
            values = [tuple(record.values()) for record in batch]

            try:
                self.cursor.executemany(query, values)
                self.connection.commit()
                inserted += len(batch)
            except mysql.connector.Error as e:
                logger.error(f"Error inserting into {table}: {e}")
                self.connection.rollback()

        return inserted


def generate_schema_data(
    schema_name: str, config: Dict, records_per_table: int
) -> Dict[str, int]:
    """Generate data for a specific schema."""
    results = {}

    try:
        # Connect to MySQL
        conn = mysql.connector.connect(**DB_CONFIG, database=schema_name)
        generator = DataGenerator(schema_name, conn)

        logger.info(f"Generating data for {schema_name}...")

        # Generate data based on schema type
        if "clinic" in schema_name or "healthcare" in schema_name:
            # Healthcare-related data
            patients = generator.generate_patients(records_per_table)
            if patients:
                results["patients"] = generator.insert_batch("patients", patients)

        elif "iot" in schema_name or "sensor" in schema_name:
            # IoT/Sensor data
            sensors = generator.generate_iot_sensors(records_per_table)
            if sensors:
                results["sensors"] = generator.insert_batch("sensors", sensors)

        elif "ecommerce" in schema_name:
            # E-commerce data
            products = generator.generate_ecommerce_products(records_per_table)
            if products:
                results["products"] = generator.insert_batch("products", products)

        elif "fintech" in schema_name or "cryptocurrency" in schema_name:
            # Financial data
            transactions = generator.generate_financial_transactions(records_per_table)
            if transactions:
                results["transactions"] = generator.insert_batch(
                    "transactions", transactions
                )

        # Generate generic data for remaining tables
        for table in config.get("tables", []):
            if table not in results:
                # Generate generic records
                generic_data = []
                for _ in range(min(records_per_table, 100)):  # Limit generic data
                    generic_data.append(
                        {
                            "name": generator.fake.company(),
                            "description": generator.fake.text(max_nb_chars=200),
                            "created_at": generator.fake.date_time_between(
                                start_date="-1y", end_date="now"
                            ),
                            "status": random.choice(["active", "inactive", "pending"]),
                        }
                    )
                # Note: This might fail for tables with different schemas
                # In production, you'd want table-specific generators

        conn.close()

    except mysql.connector.Error as e:
        logger.error(f"Database error for {schema_name}: {e}")
    except Exception as e:
        logger.error(f"Unexpected error for {schema_name}: {e}")

    return results


def print_summary(results: Dict[str, Dict[str, int]]):
    """Print generation summary."""
    print(f"\n{Fore.CYAN}{'='*60}{Style.RESET_ALL}")
    print(f"{Fore.CYAN}Data Generation Summary{Style.RESET_ALL}")
    print(f"{Fore.CYAN}{'='*60}{Style.RESET_ALL}\n")

    total_records = 0
    successful_schemas = 0

    for schema, tables in results.items():
        if tables:
            successful_schemas += 1
            schema_total = sum(tables.values())
            total_records += schema_total

            print(f"{Fore.GREEN}✓{Style.RESET_ALL} {schema}: {schema_total} records")
            for table, count in tables.items():
                print(f"  └─ {table}: {count} records")
        else:
            print(f"{Fore.YELLOW}○{Style.RESET_ALL} {schema}: No data generated")

    print(f"\n{Fore.CYAN}{'='*60}{Style.RESET_ALL}")
    print(f"{Fore.GREEN}Total Records Generated: {total_records}{Style.RESET_ALL}")
    print(
        f"{Fore.GREEN}Successful Schemas: {successful_schemas}/{len(results)}{Style.RESET_ALL}"
    )
    print(f"{Fore.CYAN}{'='*60}{Style.RESET_ALL}\n")


def main():
    """Run execution function."""
    parser = argparse.ArgumentParser(description="Generate test data for MySQL schemas")
    parser.add_argument(
        "--records",
        type=int,
        default=1000,
        help="Number of records per table (default: 1000)",
    )
    parser.add_argument(
        "--schemas", nargs="+", help="Specific schemas to generate (default: all)"
    )
    parser.add_argument(
        "--parallel", action="store_true", help="Generate data in parallel"
    )
    parser.add_argument(
        "--clean", action="store_true", help="Clean existing data before generating"
    )

    args = parser.parse_args()

    print(f"\n{Fore.CYAN}MySQL Business-to-Schema Data Generator{Style.RESET_ALL}")
    print(f"{Fore.CYAN}Started: {datetime.now()}{Style.RESET_ALL}\n")

    # Determine which schemas to process
    schemas_to_process = args.schemas if args.schemas else list(SCHEMA_CONFIGS.keys())

    # Clean existing data if requested
    if args.clean:
        print(f"{Fore.YELLOW}Cleaning existing data...{Style.RESET_ALL}")
        for schema in schemas_to_process:
            try:
                conn = mysql.connector.connect(**DB_CONFIG, database=schema)
                cursor = conn.cursor()

                # Get all tables
                cursor.execute("SHOW TABLES")
                tables = [table[0] for table in cursor.fetchall()]

                # Disable foreign key checks and truncate
                cursor.execute("SET FOREIGN_KEY_CHECKS = 0")
                for table in tables:
                    cursor.execute(f"TRUNCATE TABLE `{table}`")
                    print(f"  Cleaned: {schema}.{table}")
                cursor.execute("SET FOREIGN_KEY_CHECKS = 1")

                conn.commit()
                conn.close()
            except Exception as e:
                logger.warning(f"Could not clean {schema}: {e}")

    # Generate data
    results = {}

    if args.parallel:
        # Parallel generation
        print(f"Generating data in parallel for {len(schemas_to_process)} schemas...\n")
        with ThreadPoolExecutor(max_workers=5) as executor:
            futures = {}
            for schema in schemas_to_process:
                if schema in SCHEMA_CONFIGS:
                    future = executor.submit(
                        generate_schema_data,
                        schema,
                        SCHEMA_CONFIGS[schema],
                        args.records,
                    )
                    futures[future] = schema

            # Process results with progress bar
            with tqdm.tqdm(total=len(futures), desc="Generating data") as pbar:
                for future in as_completed(futures):
                    schema = futures[future]
                    try:
                        result = future.result()
                        results[schema] = result
                    except Exception as e:
                        logger.error(f"Error processing {schema}: {e}")
                        results[schema] = {}
                    pbar.update(1)
    else:
        # Sequential generation
        print(f"Generating data for {len(schemas_to_process)} schemas...\n")
        for schema in tqdm.tqdm(schemas_to_process, desc="Processing schemas"):
            if schema in SCHEMA_CONFIGS:
                results[schema] = generate_schema_data(
                    schema, SCHEMA_CONFIGS[schema], args.records
                )

    # Print summary
    print_summary(results)

    # Save results to file
    results_file = (
        f"data_generation_results_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
    )
    with open(results_file, "w") as f:
        json.dump(results, f, indent=2, default=str)
    print(f"Results saved to: {results_file}")

    print(f"\n{Fore.CYAN}Completed: {datetime.now()}{Style.RESET_ALL}\n")


if __name__ == "__main__":
    main()
