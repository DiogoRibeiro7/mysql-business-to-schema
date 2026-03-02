#!/usr/bin/env python3
"""Data Generator for Logistics & Supply Chain Management System.

Generates realistic data for warehouses, inventory, shipments, and transportation
"""

import random
import json
import yaml
from datetime import datetime, timedelta
from faker import Faker
import mysql.connector
from mysql.connector import Error

from typing import Any, List

fake = Faker()
Faker.seed(42)
random.seed(42)


class LogisticsDataGenerator:
    """Represent LogisticsDataGenerator."""

    def __init__(self, config_file="config.yaml"):
        """Initialize the data generator with configuration."""
        with open(config_file, "r") as f:
            self.config = yaml.safe_load(f)

        self.connection = None
        self.cursor = None

        # Business data
        self.warehouse_ids: List[Any] = []
        self.zone_ids: List[Any] = []
        self.bin_ids: List[Any] = []
        self.product_ids: List[Any] = []
        self.supplier_ids: List[Any] = []
        self.customer_ids: List[Any] = []
        self.carrier_ids: List[Any] = []
        self.vehicle_ids: List[Any] = []
        self.driver_ids: List[Any] = []

    def connect_to_database(self):
        """Establish database connection."""
        try:
            self.connection = mysql.connector.connect(
                host=self.config["database"]["host"],
                user=self.config["database"]["user"],
                password=self.config["database"]["password"],
                database=self.config["database"]["name"],
            )
            self.cursor = self.connection.cursor()
            print("Successfully connected to database")
        except Error as e:
            print(f"Error connecting to database: {e}")
            raise

    def generate_warehouses(self):
        """Generate warehouse data."""
        warehouse_types = ["DC", "FC", "CROSS_DOCK", "COLD_STORAGE", "BONDED"]
        capabilities = ["HAZMAT", "REFRIGERATED", "HIGH_VALUE", "OVERSIZED", "PHARMA"]

        warehouses_data = []
        for i in range(self.config["counts"]["warehouses"]):
            warehouse = {
                "warehouse_code": f"WH{str(i+1).zfill(4)}",
                "warehouse_name": f"{fake.city()} {random.choice(['Distribution', 'Fulfillment', 'Logistics'])} Center",
                "warehouse_type": random.choice(warehouse_types),
                "address_line1": fake.street_address(),
                "address_line2": (
                    fake.secondary_address() if random.random() > 0.7 else None
                ),
                "city": fake.city(),
                "state_province": fake.state_abbr(),
                "postal_code": fake.zipcode(),
                "country_code": "US",
                "latitude": float(fake.latitude()),
                "longitude": float(fake.longitude()),
                "total_capacity_cbm": random.randint(10000, 100000),
                "available_capacity_cbm": random.randint(5000, 50000),
                "operating_hours": json.dumps(
                    {
                        "monday": "06:00-22:00",
                        "tuesday": "06:00-22:00",
                        "wednesday": "06:00-22:00",
                        "thursday": "06:00-22:00",
                        "friday": "06:00-22:00",
                        "saturday": "08:00-18:00",
                        "sunday": "closed",
                    }
                ),
                "capabilities": ",".join(
                    random.sample(capabilities, k=random.randint(1, 3))
                ),
                "manager_name": fake.name(),
                "contact_phone": fake.phone_number(),
                "contact_email": fake.company_email(),
                "is_active": True,
            }
            warehouses_data.append(warehouse)

        # Insert warehouses
        insert_query = """
            INSERT INTO warehouses (
                warehouse_code, warehouse_name, warehouse_type, address_line1, address_line2,
                city, state_province, postal_code, country_code, latitude, longitude,
                total_capacity_cbm, available_capacity_cbm, operating_hours, capabilities,
                manager_name, contact_phone, contact_email, is_active
            ) VALUES (
                %(warehouse_code)s, %(warehouse_name)s, %(warehouse_type)s, %(address_line1)s, %(address_line2)s,
                %(city)s, %(state_province)s, %(postal_code)s, %(country_code)s, %(latitude)s, %(longitude)s,
                %(total_capacity_cbm)s, %(available_capacity_cbm)s, %(operating_hours)s, %(capabilities)s,
                %(manager_name)s, %(contact_phone)s, %(contact_email)s, %(is_active)s
            )
        """

        for warehouse in warehouses_data:
            self.cursor.execute(insert_query, warehouse)
            self.warehouse_ids.append(self.cursor.lastrowid)

        self.connection.commit()
        print(f"Generated {len(warehouses_data)} warehouses")

    def generate_warehouse_zones_and_bins(self):
        """Generate warehouse zones and bins."""
        zone_types = [
            "RECEIVING",
            "STORAGE",
            "PICKING",
            "PACKING",
            "SHIPPING",
            "RETURNS",
            "QUARANTINE",
        ]
        bin_types = ["FLOOR", "PALLET_RACK", "SHELF", "BULK", "CANTILEVER"]

        for warehouse_id in self.warehouse_ids:
            # Generate zones
            num_zones = random.randint(5, 15)
            for z in range(num_zones):
                zone_data = {
                    "warehouse_id": warehouse_id,
                    "zone_code": f"Z{str(z+1).zfill(2)}",
                    "zone_name": f"Zone {chr(65 + z)}",
                    "zone_type": random.choice(zone_types),
                    "temperature_range": "2-8°C" if random.random() > 0.8 else None,
                    "max_weight_kg": random.randint(1000, 10000),
                    "max_height_meters": round(random.uniform(2.5, 6.0), 2),
                    "aisle_width_meters": round(random.uniform(2.0, 4.0), 2),
                    "is_automated": random.random() > 0.85,
                }

                insert_zone_query = """
                    INSERT INTO warehouse_zones (
                        warehouse_id, zone_code, zone_name, zone_type, temperature_range,
                        max_weight_kg, max_height_meters, aisle_width_meters, is_automated
                    ) VALUES (
                        %(warehouse_id)s, %(zone_code)s, %(zone_name)s, %(zone_type)s, %(temperature_range)s,
                        %(max_weight_kg)s, %(max_height_meters)s, %(aisle_width_meters)s, %(is_automated)s
                    )
                """
                self.cursor.execute(insert_zone_query, zone_data)
                zone_id = self.cursor.lastrowid
                self.zone_ids.append(zone_id)

                # Generate bins for each zone
                num_bins = random.randint(20, 100)
                for b in range(num_bins):
                    bin_data = {
                        "zone_id": zone_id,
                        "bin_code": f"A{str(z + 1).zfill(2)}-R{str(b // 10 + 1).zfill(2)}-L{str(b % 10 + 1).zfill(2)}",
                        "aisle": f"A{str(z + 1).zfill(2)}",
                        "rack": f"R{str(b // 10 + 1).zfill(2)}",
                        "level": f"L{str(b % 10 + 1).zfill(2)}",
                        "position": str(b % 4 + 1),
                        "bin_type": random.choice(bin_types),
                        "max_weight_kg": random.randint(100, 2000),
                        "dimensions_lwh": f"{random.randint(100, 200)}x{random.randint(100, 150)}x{random.randint(100, 200)}",
                        "volume_cbm": round(random.uniform(0.5, 5.0), 3),
                        "is_occupied": random.random() > 0.3,
                        "is_locked": False,
                    }

                    insert_bin_query = """
                        INSERT INTO warehouse_bins (
                            zone_id, bin_code, aisle, rack, level, position, bin_type,
                            max_weight_kg, dimensions_lwh, volume_cbm, is_occupied, is_locked
                        ) VALUES (
                            %(zone_id)s, %(bin_code)s, %(aisle)s, %(rack)s, %(level)s, %(position)s, %(bin_type)s,
                            %(max_weight_kg)s, %(dimensions_lwh)s, %(volume_cbm)s, %(is_occupied)s, %(is_locked)s
                        )
                    """
                    self.cursor.execute(insert_bin_query, bin_data)
                    self.bin_ids.append(self.cursor.lastrowid)

        self.connection.commit()
        print(f"Generated {len(self.zone_ids)} zones and {len(self.bin_ids)} bins")

    def generate_products(self):
        """Generate product master data."""
        categories = [
            "Electronics",
            "Apparel",
            "Food",
            "Furniture",
            "Automotive",
            "Pharmaceuticals",
            "Toys",
            "Books",
        ]
        uom_types = ["EACH", "CASE", "PALLET", "KG", "LB", "LITER", "METER"]
        abc_classes = ["A", "B", "C"]

        products_data = []
        for i in range(self.config["counts"]["products"]):
            category = random.choice(categories)
            is_hazmat = (
                category in ["Automotive", "Pharmaceuticals"] and random.random() > 0.7
            )
            requires_temp = (
                category in ["Food", "Pharmaceuticals"] and random.random() > 0.5
            )

            product = {
                "sku": f"SKU{str(i+1).zfill(6)}",
                "product_name": f"{fake.company()} {fake.word().title()} {random.choice(['Pro', 'Plus', 'Elite', 'Basic'])}",
                "product_description": fake.text(max_nb_chars=200),
                "category": category,
                "subcategory": f"{category} - {fake.word().title()}",
                "brand": fake.company(),
                "unit_of_measure": random.choice(uom_types),
                "weight_kg": round(random.uniform(0.1, 50.0), 3),
                "dimensions_lwh": f"{random.randint(10, 100)}x{random.randint(10, 100)}x{random.randint(10, 100)}",
                "volume_cbm": round(random.uniform(0.001, 1.0), 3),
                "is_hazmat": is_hazmat,
                "hazmat_class": f"Class {random.randint(1, 9)}" if is_hazmat else None,
                "requires_temperature_control": requires_temp,
                "min_temperature_celsius": (
                    random.randint(2, 8) if requires_temp else None
                ),
                "max_temperature_celsius": (
                    random.randint(15, 25) if requires_temp else None
                ),
                "shelf_life_days": (
                    random.randint(30, 365) if category == "Food" else None
                ),
                "is_serialized": random.random() > 0.8,
                "is_lot_controlled": random.random() > 0.7,
                "reorder_point": random.randint(10, 100),
                "reorder_quantity": random.randint(50, 500),
                "lead_time_days": random.randint(7, 45),
                "unit_cost": round(random.uniform(1.0, 500.0), 2),
                "selling_price": round(random.uniform(2.0, 1000.0), 2),
                "abc_classification": random.choice(abc_classes),
                "is_active": True,
            }
            products_data.append(product)

        # Insert products
        insert_query = """
            INSERT INTO products (
                sku, product_name, product_description, category, subcategory, brand,
                unit_of_measure, weight_kg, dimensions_lwh, volume_cbm, is_hazmat, hazmat_class,
                requires_temperature_control, min_temperature_celsius, max_temperature_celsius,
                shelf_life_days, is_serialized, is_lot_controlled, reorder_point, reorder_quantity,
                lead_time_days, unit_cost, selling_price, abc_classification, is_active
            ) VALUES (
                %(sku)s, %(product_name)s, %(product_description)s, %(category)s, %(subcategory)s, %(brand)s,
                %(unit_of_measure)s, %(weight_kg)s, %(dimensions_lwh)s, %(volume_cbm)s, %(is_hazmat)s, %(hazmat_class)s,
                %(requires_temperature_control)s, %(min_temperature_celsius)s, %(max_temperature_celsius)s,
                %(shelf_life_days)s, %(is_serialized)s, %(is_lot_controlled)s, %(reorder_point)s, %(reorder_quantity)s,
                %(lead_time_days)s, %(unit_cost)s, %(selling_price)s, %(abc_classification)s, %(is_active)s
            )
        """

        for product in products_data:
            self.cursor.execute(insert_query, product)
            self.product_ids.append(self.cursor.lastrowid)

        self.connection.commit()
        print(f"Generated {len(products_data)} products")

    def generate_inventory(self):
        """Generate inventory levels and product batches."""
        # Generate inventory levels for each warehouse-product combination
        for warehouse_id in self.warehouse_ids[:10]:  # Limit to first 10 warehouses
            num_products = random.randint(100, min(300, len(self.product_ids)))
            selected_products = random.sample(self.product_ids, num_products)

            for product_id in selected_products:
                quantity_on_hand = random.randint(0, 1000)
                quantity_allocated = random.randint(0, min(200, quantity_on_hand))

                inventory_data = {
                    "warehouse_id": warehouse_id,
                    "product_id": product_id,
                    "quantity_on_hand": quantity_on_hand,
                    "quantity_available": quantity_on_hand - quantity_allocated,
                    "quantity_allocated": quantity_allocated,
                    "quantity_in_transit": random.randint(0, 100),
                    "quantity_damaged": random.randint(0, 10),
                    "quantity_quarantine": random.randint(0, 5),
                    "average_cost": round(random.uniform(10.0, 500.0), 4),
                    "last_received_date": fake.date_time_between(
                        start_date="-30d", end_date="now"
                    ),
                    "last_counted_date": fake.date_time_between(
                        start_date="-7d", end_date="now"
                    ),
                    "last_shipped_date": fake.date_time_between(
                        start_date="-3d", end_date="now"
                    ),
                }

                insert_query = """
                    INSERT INTO inventory_levels (
                        warehouse_id, product_id, quantity_on_hand, quantity_available, quantity_allocated,
                        quantity_in_transit, quantity_damaged, quantity_quarantine, average_cost,
                        last_received_date, last_counted_date, last_shipped_date
                    ) VALUES (
                        %(warehouse_id)s, %(product_id)s, %(quantity_on_hand)s, %(quantity_available)s, %(quantity_allocated)s,
                        %(quantity_in_transit)s, %(quantity_damaged)s, %(quantity_quarantine)s, %(average_cost)s,
                        %(last_received_date)s, %(last_counted_date)s, %(last_shipped_date)s
                    )
                """
                self.cursor.execute(insert_query, inventory_data)

                # Generate product batches
                if random.random() > 0.3:  # 70% chance of having batch tracking
                    num_batches = random.randint(1, 5)
                    for _ in range(num_batches):
                        manufacture_date = fake.date_between(
                            start_date="-180d", end_date="-30d"
                        )
                        expiry_date = manufacture_date + timedelta(
                            days=random.randint(180, 730)
                        )
                        quantity_received = random.randint(50, 500)

                        batch_data = {
                            "product_id": product_id,
                            "warehouse_id": warehouse_id,
                            "batch_number": f"BATCH{fake.random_number(digits=8)}",
                            "lot_number": f"LOT{fake.random_number(digits=6)}",
                            "serial_numbers": json.dumps(
                                [
                                    f"SN{fake.random_number(digits=10)}"
                                    for _ in range(min(5, quantity_received))
                                ]
                            ),
                            "manufacture_date": manufacture_date,
                            "expiry_date": (
                                expiry_date if random.random() > 0.5 else None
                            ),
                            "received_date": fake.date_time_between(
                                start_date=manufacture_date, end_date="now"
                            ),
                            "quantity_received": quantity_received,
                            "quantity_remaining": random.randint(0, quantity_received),
                            "supplier_id": (
                                random.choice(self.supplier_ids)
                                if self.supplier_ids
                                else None
                            ),
                            "quality_status": random.choice(
                                ["PASSED", "PASSED", "PASSED", "CONDITIONAL"]
                            ),
                            "quality_certificate_url": f"https://qc.example.com/{fake.random_number(digits=8)}.pdf",
                            "storage_conditions": "Standard warehouse conditions",
                        }

                        insert_batch_query = """
                            INSERT INTO product_batches (
                                product_id, warehouse_id, batch_number, lot_number, serial_numbers,
                                manufacture_date, expiry_date, received_date, quantity_received, quantity_remaining,
                                supplier_id, quality_status, quality_certificate_url, storage_conditions
                            ) VALUES (
                                %(product_id)s, %(warehouse_id)s, %(batch_number)s, %(lot_number)s, %(serial_numbers)s,
                                %(manufacture_date)s, %(expiry_date)s, %(received_date)s, %(quantity_received)s, %(quantity_remaining)s,
                                %(supplier_id)s, %(quality_status)s, %(quality_certificate_url)s, %(storage_conditions)s
                            )
                        """
                        self.cursor.execute(insert_batch_query, batch_data)

        self.connection.commit()
        print("Generated inventory levels and batches")

    def generate_suppliers_and_customers(self):
        """Generate suppliers and customers."""
        # Generate suppliers
        supplier_types = ["MANUFACTURER", "DISTRIBUTOR", "WHOLESALER", "DROPSHIPPER"]
        for i in range(self.config["counts"]["suppliers"]):
            supplier_data = {
                "supplier_code": f"SUP{str(i+1).zfill(5)}",
                "supplier_name": fake.company(),
                "supplier_type": random.choice(supplier_types),
                "tax_id": fake.ein(),
                "address_line1": fake.street_address(),
                "address_line2": (
                    fake.secondary_address() if random.random() > 0.7 else None
                ),
                "city": fake.city(),
                "state_province": fake.state_abbr(),
                "postal_code": fake.zipcode(),
                "country_code": "US",
                "contact_name": fake.name(),
                "contact_phone": fake.phone_number(),
                "contact_email": fake.company_email(),
                "payment_terms": random.choice(
                    ["NET30", "NET60", "NET90", "2/10 NET30"]
                ),
                "currency_code": "USD",
                "credit_limit": round(random.uniform(10000, 1000000), 2),
                "lead_time_days": random.randint(7, 45),
                "minimum_order_value": round(random.uniform(100, 10000), 2),
                "performance_score": round(random.uniform(3.0, 5.0), 2),
                "is_preferred": random.random() > 0.7,
                "is_active": True,
                "certifications": json.dumps(
                    ["ISO9001", "ISO14001"] if random.random() > 0.6 else []
                ),
            }

            insert_query = """
                INSERT INTO suppliers (
                    supplier_code, supplier_name, supplier_type, tax_id, address_line1, address_line2,
                    city, state_province, postal_code, country_code, contact_name, contact_phone,
                    contact_email, payment_terms, currency_code, credit_limit, lead_time_days,
                    minimum_order_value, performance_score, is_preferred, is_active, certifications
                ) VALUES (
                    %(supplier_code)s, %(supplier_name)s, %(supplier_type)s, %(tax_id)s, %(address_line1)s, %(address_line2)s,
                    %(city)s, %(state_province)s, %(postal_code)s, %(country_code)s, %(contact_name)s, %(contact_phone)s,
                    %(contact_email)s, %(payment_terms)s, %(currency_code)s, %(credit_limit)s, %(lead_time_days)s,
                    %(minimum_order_value)s, %(performance_score)s, %(is_preferred)s, %(is_active)s, %(certifications)s
                )
            """
            self.cursor.execute(insert_query, supplier_data)
            self.supplier_ids.append(self.cursor.lastrowid)

        # Generate customers
        customer_types = ["B2B", "B2C", "MARKETPLACE", "INTERNAL"]
        priority_levels = ["STANDARD", "SILVER", "GOLD", "PLATINUM"]

        for i in range(self.config["counts"]["customers"]):
            customer_data = {
                "customer_code": f"CUST{str(i+1).zfill(6)}",
                "customer_name": (
                    fake.company() if random.random() > 0.3 else fake.name()
                ),
                "customer_type": random.choice(customer_types),
                "tax_id": fake.ein() if random.random() > 0.5 else None,
                "billing_address_line1": fake.street_address(),
                "billing_address_line2": (
                    fake.secondary_address() if random.random() > 0.7 else None
                ),
                "billing_city": fake.city(),
                "billing_state_province": fake.state_abbr(),
                "billing_postal_code": fake.zipcode(),
                "billing_country_code": "US",
                "shipping_same_as_billing": random.random() > 0.5,
                "shipping_address_line1": fake.street_address(),
                "shipping_address_line2": (
                    fake.secondary_address() if random.random() > 0.7 else None
                ),
                "shipping_city": fake.city(),
                "shipping_state_province": fake.state_abbr(),
                "shipping_postal_code": fake.zipcode(),
                "shipping_country_code": "US",
                "contact_name": fake.name(),
                "contact_phone": fake.phone_number(),
                "contact_email": fake.email(),
                "payment_terms": random.choice(["NET30", "NET60", "COD", "PREPAID"]),
                "credit_limit": round(random.uniform(1000, 100000), 2),
                "current_balance": round(random.uniform(0, 50000), 2),
                "priority_level": random.choice(priority_levels),
                "is_active": True,
            }

            insert_query = """
                INSERT INTO customers (
                    customer_code, customer_name, customer_type, tax_id, billing_address_line1, billing_address_line2,
                    billing_city, billing_state_province, billing_postal_code, billing_country_code,
                    shipping_same_as_billing, shipping_address_line1, shipping_address_line2,
                    shipping_city, shipping_state_province, shipping_postal_code, shipping_country_code,
                    contact_name, contact_phone, contact_email, payment_terms, credit_limit,
                    current_balance, priority_level, is_active
                ) VALUES (
                    %(customer_code)s, %(customer_name)s, %(customer_type)s, %(tax_id)s, %(billing_address_line1)s, %(billing_address_line2)s,
                    %(billing_city)s, %(billing_state_province)s, %(billing_postal_code)s, %(billing_country_code)s,
                    %(shipping_same_as_billing)s, %(shipping_address_line1)s, %(shipping_address_line2)s,
                    %(shipping_city)s, %(shipping_state_province)s, %(shipping_postal_code)s, %(shipping_country_code)s,
                    %(contact_name)s, %(contact_phone)s, %(contact_email)s, %(payment_terms)s, %(credit_limit)s,
                    %(current_balance)s, %(priority_level)s, %(is_active)s
                )
            """
            self.cursor.execute(insert_query, customer_data)
            self.customer_ids.append(self.cursor.lastrowid)

        self.connection.commit()
        print(
            f"Generated {len(self.supplier_ids)} suppliers and {len(self.customer_ids)} customers"
        )

    def generate_orders(self):
        """Generate purchase and sales orders."""
        # Generate purchase orders
        po_statuses = [
            "DRAFT",
            "SUBMITTED",
            "CONFIRMED",
            "SHIPPED",
            "RECEIVED",
            "PARTIAL",
        ]
        for i in range(self.config["counts"]["purchase_orders"]):
            order_date = fake.date_between(start_date="-90d", end_date="today")
            expected_delivery = order_date + timedelta(days=random.randint(7, 30))

            po_data = {
                "po_number": f"PO{datetime.now().year}{str(i+1).zfill(6)}",
                "supplier_id": random.choice(self.supplier_ids),
                "warehouse_id": random.choice(self.warehouse_ids),
                "order_date": order_date,
                "expected_delivery_date": expected_delivery,
                "actual_delivery_date": (
                    expected_delivery + timedelta(days=random.randint(-2, 5))
                    if random.random() > 0.5
                    else None
                ),
                "total_amount": 0,  # Will update after items
                "currency_code": "USD",
                "status": random.choice(po_statuses),
                "payment_status": random.choice(["PENDING", "PARTIAL", "PAID"]),
                "notes": fake.text(max_nb_chars=100) if random.random() > 0.7 else None,
            }

            insert_po_query = """
                INSERT INTO purchase_orders (
                    po_number, supplier_id, warehouse_id, order_date, expected_delivery_date,
                    actual_delivery_date, total_amount, currency_code, status, payment_status, notes
                ) VALUES (
                    %(po_number)s, %(supplier_id)s, %(warehouse_id)s, %(order_date)s, %(expected_delivery_date)s,
                    %(actual_delivery_date)s, %(total_amount)s, %(currency_code)s, %(status)s, %(payment_status)s, %(notes)s
                )
            """
            self.cursor.execute(insert_po_query, po_data)
            po_id = self.cursor.lastrowid

            # Generate PO items
            num_items = random.randint(1, 10)
            total_amount = 0
            for _ in range(num_items):
                quantity = random.randint(10, 500)
                unit_price = round(random.uniform(10, 500), 4)
                line_total = quantity * unit_price
                total_amount += line_total

                po_item_data = {
                    "po_id": po_id,
                    "product_id": random.choice(self.product_ids),
                    "quantity_ordered": quantity,
                    "quantity_received": (
                        quantity
                        if po_data["status"] == "RECEIVED"
                        else random.randint(0, quantity)
                    ),
                    "unit_price": unit_price,
                    "line_total": line_total,
                    "discount_percent": (
                        round(random.uniform(0, 10), 2) if random.random() > 0.7 else 0
                    ),
                    "tax_amount": line_total * 0.08,
                    "expected_delivery_date": expected_delivery,
                }

                insert_item_query = """
                    INSERT INTO purchase_order_items (
                        po_id, product_id, quantity_ordered, quantity_received, unit_price,
                        line_total, discount_percent, tax_amount, expected_delivery_date
                    ) VALUES (
                        %(po_id)s, %(product_id)s, %(quantity_ordered)s, %(quantity_received)s, %(unit_price)s,
                        %(line_total)s, %(discount_percent)s, %(tax_amount)s, %(expected_delivery_date)s
                    )
                """
                self.cursor.execute(insert_item_query, po_item_data)

            # Update PO total
            self.cursor.execute(
                "UPDATE purchase_orders SET total_amount = %s WHERE po_id = %s",
                (total_amount, po_id),
            )

        # Generate sales orders
        so_statuses = [
            "PENDING",
            "CONFIRMED",
            "PICKING",
            "PACKED",
            "SHIPPED",
            "DELIVERED",
        ]
        for i in range(self.config["counts"]["sales_orders"]):
            order_date = fake.date_time_between(start_date="-30d", end_date="now")
            requested_delivery = fake.date_between(start_date="today", end_date="+14d")

            customer = random.choice(self.customer_ids)

            so_data = {
                "so_number": f"SO{datetime.now().year}{str(i+1).zfill(6)}",
                "customer_id": customer,
                "order_date": order_date,
                "requested_delivery_date": requested_delivery,
                "promised_delivery_date": requested_delivery
                + timedelta(days=random.randint(0, 2)),
                "actual_delivery_date": (
                    requested_delivery + timedelta(days=random.randint(-1, 3))
                    if random.random() > 0.6
                    else None
                ),
                "shipping_address_line1": fake.street_address(),
                "shipping_city": fake.city(),
                "shipping_state_province": fake.state_abbr(),
                "shipping_postal_code": fake.zipcode(),
                "shipping_country_code": "US",
                "subtotal_amount": 0,  # Will update
                "discount_amount": 0,
                "tax_amount": 0,
                "shipping_cost": round(random.uniform(10, 100), 2),
                "total_amount": 0,  # Will update
                "currency_code": "USD",
                "status": random.choice(so_statuses),
                "payment_status": random.choice(
                    ["PENDING", "AUTHORIZED", "CAPTURED", "PAID"]
                ),
                "fulfillment_priority": random.choice(
                    ["STANDARD", "EXPRESS", "URGENT"]
                ),
                "special_instructions": (
                    fake.text(max_nb_chars=100) if random.random() > 0.8 else None
                ),
            }

            insert_so_query = """
                INSERT INTO sales_orders (
                    so_number, customer_id, order_date, requested_delivery_date, promised_delivery_date,
                    actual_delivery_date, shipping_address_line1, shipping_city, shipping_state_province,
                    shipping_postal_code, shipping_country_code, subtotal_amount, discount_amount,
                    tax_amount, shipping_cost, total_amount, currency_code, status, payment_status,
                    fulfillment_priority, special_instructions
                ) VALUES (
                    %(so_number)s, %(customer_id)s, %(order_date)s, %(requested_delivery_date)s, %(promised_delivery_date)s,
                    %(actual_delivery_date)s, %(shipping_address_line1)s, %(shipping_city)s, %(shipping_state_province)s,
                    %(shipping_postal_code)s, %(shipping_country_code)s, %(subtotal_amount)s, %(discount_amount)s,
                    %(tax_amount)s, %(shipping_cost)s, %(total_amount)s, %(currency_code)s, %(status)s, %(payment_status)s,
                    %(fulfillment_priority)s, %(special_instructions)s
                )
            """
            self.cursor.execute(insert_so_query, so_data)
            so_id = self.cursor.lastrowid

            # Generate SO items
            num_items = random.randint(1, 8)
            subtotal = 0
            for _ in range(num_items):
                quantity = random.randint(1, 20)
                unit_price = round(random.uniform(20, 800), 4)
                line_total = quantity * unit_price
                subtotal += line_total

                so_item_data = {
                    "so_id": so_id,
                    "product_id": random.choice(self.product_ids),
                    "warehouse_id": random.choice(
                        self.warehouse_ids[:5]
                    ),  # From top 5 warehouses
                    "quantity_ordered": quantity,
                    "quantity_allocated": (
                        quantity
                        if so_data["status"] in ["PICKING", "PACKED", "SHIPPED"]
                        else 0
                    ),
                    "quantity_picked": (
                        quantity if so_data["status"] in ["PACKED", "SHIPPED"] else 0
                    ),
                    "quantity_shipped": (
                        quantity if so_data["status"] == "SHIPPED" else 0
                    ),
                    "unit_price": unit_price,
                    "discount_percent": (
                        round(random.uniform(0, 15), 2) if random.random() > 0.7 else 0
                    ),
                    "tax_rate": 8.5,
                    "line_total": line_total,
                    "backorder_quantity": 0,
                }

                insert_item_query = """
                    INSERT INTO sales_order_items (
                        so_id, product_id, warehouse_id, quantity_ordered, quantity_allocated,
                        quantity_picked, quantity_shipped, unit_price, discount_percent,
                        tax_rate, line_total, backorder_quantity
                    ) VALUES (
                        %(so_id)s, %(product_id)s, %(warehouse_id)s, %(quantity_ordered)s, %(quantity_allocated)s,
                        %(quantity_picked)s, %(quantity_shipped)s, %(unit_price)s, %(discount_percent)s,
                        %(tax_rate)s, %(line_total)s, %(backorder_quantity)s
                    )
                """
                self.cursor.execute(insert_item_query, so_item_data)

            # Update SO totals
            tax_amount = subtotal * 0.085
            total_amount = subtotal + tax_amount + so_data["shipping_cost"]
            self.cursor.execute(
                """
                UPDATE sales_orders
                SET subtotal_amount = %s, tax_amount = %s, total_amount = %s
                WHERE so_id = %s
            """,
                (subtotal, tax_amount, total_amount, so_id),
            )

        self.connection.commit()
        print(
            f"Generated {self.config['counts']['purchase_orders']} purchase orders and {self.config['counts']['sales_orders']} sales orders"
        )

    def cleanup(self):
        """Close database connections."""
        if self.cursor:
            self.cursor.close()
        if self.connection:
            self.connection.close()
        print("Database connections closed")

    def generate_all(self):
        """Generate all data."""
        try:
            self.connect_to_database()

            print("Starting logistics data generation...")
            self.generate_warehouses()
            self.generate_warehouse_zones_and_bins()
            self.generate_products()
            self.generate_suppliers_and_customers()
            self.generate_inventory()
            self.generate_orders()

            print("Data generation completed successfully!")

        except Exception as e:
            print(f"Error during data generation: {e}")
            if self.connection:
                self.connection.rollback()
            raise
        finally:
            self.cleanup()


if __name__ == "__main__":
    generator = LogisticsDataGenerator()
    generator.generate_all()
