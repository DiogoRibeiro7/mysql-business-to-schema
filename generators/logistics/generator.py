#!/usr/bin/env python3
"""
Logistics and Supply Chain Data Generator
Generates realistic data for warehouse management, inventory, shipping, and distribution
"""

import csv
import json
import random
import hashlib
import uuid
from datetime import datetime, timedelta, date
from decimal import Decimal
from pathlib import Path
from faker import Faker
import numpy as np
import math

# Configuration
SEED = 42
OUTPUT_DIR = Path("output")
fake = Faker()
Faker.seed(SEED)
random.seed(SEED)
np.random.seed(SEED)

# Scale configuration
CONFIG = {
    "warehouses": 5,
    "zones_per_warehouse": 6,
    "bins_per_zone": 20,
    "products": 500,
    "suppliers": 50,
    "customers": 200,
    "carriers": 10,
    "vehicles": 30,
    "drivers": 40,
    "days_of_history": 30,
    "orders_per_day": 50,
    "shipments_per_day": 40,
}

class LogisticsGenerator:
    def __init__(self):
        # Warehouse entities
        self.warehouses = []
        self.warehouse_zones = []
        self.warehouse_bins = []
        self.docking_stations = []

        # Product and inventory
        self.products = []
        self.inventory_levels = []
        self.product_batches = []
        self.inventory_movements = []

        # Partners
        self.suppliers = []
        self.customers = []

        # Orders
        self.purchase_orders = []
        self.purchase_order_items = []
        self.sales_orders = []
        self.sales_order_items = []

        # Shipping
        self.carriers = []
        self.carrier_services = []
        self.shipments = []
        self.shipment_tracking = []

        # Fleet
        self.vehicles = []
        self.drivers = []
        self.routes = []
        self.delivery_runs = []

        # Analytics
        self.kpi_metrics = []
        self.audit_log = []

        # Counters
        self.warehouse_id = 0
        self.zone_id = 0
        self.bin_id = 0
        self.docking_id = 0
        self.product_id = 0
        self.inventory_id = 0
        self.batch_id = 0
        self.movement_id = 0
        self.supplier_id = 0
        self.customer_id = 0
        self.po_id = 0
        self.po_item_id = 0
        self.so_id = 0
        self.so_item_id = 0
        self.carrier_id = 0
        self.service_id = 0
        self.shipment_id = 0
        self.tracking_id = 0
        self.vehicle_id = 0
        self.driver_id = 0
        self.route_id = 0
        self.run_id = 0
        self.kpi_id = 0
        self.audit_id = 0

        # Start date for historical data
        self.start_date = datetime.now() - timedelta(days=CONFIG['days_of_history'])

    def generate_all(self):
        """Generate all logistics data"""
        print("Starting Logistics & Supply Chain Data Generation...")
        print(f"Configuration:")
        print(f"  Warehouses: {CONFIG['warehouses']}")
        print(f"  Products: {CONFIG['products']}")
        print(f"  Days of history: {CONFIG['days_of_history']}")

        # Infrastructure
        self.generate_warehouses()
        self.generate_warehouse_zones()
        self.generate_warehouse_bins()
        self.generate_docking_stations()

        # Products and inventory
        self.generate_products()
        self.generate_inventory_levels()
        self.generate_product_batches()

        # Partners
        self.generate_suppliers()
        self.generate_customers()

        # Orders
        self.generate_purchase_orders()
        self.generate_sales_orders()

        # Shipping
        self.generate_carriers()
        self.generate_carrier_services()
        self.generate_shipments()
        self.generate_shipment_tracking()

        # Fleet
        self.generate_vehicles()
        self.generate_drivers()
        self.generate_routes()
        self.generate_delivery_runs()

        # Movement and analytics
        self.generate_inventory_movements()
        self.generate_kpi_metrics()
        self.generate_audit_log()

        # Save all data
        self.save_all()

    def generate_warehouses(self):
        """Generate warehouse facilities"""
        print(f"Generating {CONFIG['warehouses']} warehouses...")

        warehouse_types = ['Distribution Center', 'Fulfillment Center', 'Cross-Dock', 'Cold Storage', 'Regional Hub']
        cities = ['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix', 'Philadelphia', 'San Antonio', 'Dallas']

        for i in range(CONFIG['warehouses']):
            self.warehouse_id += 1

            city = cities[i % len(cities)]
            state = fake.state_abbr()

            self.warehouses.append({
                'warehouse_id': self.warehouse_id,
                'warehouse_code': f"WH{self.warehouse_id:03d}",
                'warehouse_name': f"{city} {warehouse_types[i % len(warehouse_types)]}",
                'warehouse_type': warehouse_types[i % len(warehouse_types)],
                'address': fake.street_address(),
                'city': city,
                'state': state,
                'zip_code': fake.zipcode(),
                'country': 'USA',
                'latitude': round(random.uniform(25, 48), 6),
                'longitude': round(random.uniform(-125, -65), 6),
                'total_capacity_cubic_meters': random.randint(10000, 100000),
                'available_capacity_cubic_meters': random.randint(5000, 50000),
                'operating_hours': '06:00-22:00',
                'is_climate_controlled': warehouse_types[i % len(warehouse_types)] == 'Cold Storage',
                'is_active': True,
                'created_at': datetime.now() - timedelta(days=random.randint(365, 1825))
            })

    def generate_warehouse_zones(self):
        """Generate zones within warehouses"""
        print("Generating warehouse zones...")

        zone_types = ['Receiving', 'Storage', 'Picking', 'Packing', 'Shipping', 'Returns']

        for warehouse in self.warehouses:
            for zone_type in zone_types:
                self.zone_id += 1

                self.warehouse_zones.append({
                    'zone_id': self.zone_id,
                    'warehouse_id': warehouse['warehouse_id'],
                    'zone_code': f"Z{self.zone_id:04d}",
                    'zone_name': f"{zone_type} Zone {self.zone_id % 10 + 1}",
                    'zone_type': zone_type,
                    'temperature_range': '-20 to -10' if warehouse['is_climate_controlled'] else '15 to 25',
                    'max_weight_kg': random.randint(10000, 50000),
                    'max_height_meters': random.uniform(3, 10),
                    'is_hazmat_certified': random.random() < 0.2,
                    'created_at': warehouse['created_at']
                })

    def generate_warehouse_bins(self):
        """Generate storage bins within zones"""
        print("Generating warehouse bins...")

        bin_types = ['Floor', 'Pallet Rack', 'Shelving', 'Bulk']
        bin_sizes = ['Small', 'Medium', 'Large', 'XLarge']

        for zone in self.warehouse_zones:
            if zone['zone_type'] in ['Storage', 'Picking']:
                num_bins = CONFIG['bins_per_zone']

                for b in range(num_bins):
                    self.bin_id += 1

                    # Generate bin location (aisle-bay-level)
                    aisle = chr(65 + (b // 10))  # A, B, C...
                    bay = (b % 10) + 1
                    level = random.randint(1, 5)

                    self.warehouse_bins.append({
                        'bin_id': self.bin_id,
                        'zone_id': zone['zone_id'],
                        'bin_code': f"{aisle}{bay:02d}-{level}",
                        'bin_type': random.choice(bin_types),
                        'bin_size': random.choice(bin_sizes),
                        'max_weight_kg': random.uniform(100, 2000),
                        'max_volume_cubic_meters': random.uniform(1, 10),
                        'is_available': random.random() > 0.3,
                        'created_at': zone['created_at']
                    })

    def generate_docking_stations(self):
        """Generate loading docks"""
        print("Generating docking stations...")

        for warehouse in self.warehouses:
            num_docks = random.randint(5, 20)

            for d in range(num_docks):
                self.docking_id += 1

                self.docking_stations.append({
                    'dock_id': self.docking_id,
                    'warehouse_id': warehouse['warehouse_id'],
                    'dock_number': d + 1,
                    'dock_type': random.choice(['Inbound', 'Outbound', 'Flexible']),
                    'door_height_meters': random.uniform(3, 4.5),
                    'door_width_meters': random.uniform(2.5, 3.5),
                    'has_dock_leveler': True,
                    'has_dock_seal': random.random() > 0.3,
                    'is_available': random.random() > 0.2,
                    'created_at': warehouse['created_at']
                })

    def generate_products(self):
        """Generate product catalog"""
        print(f"Generating {CONFIG['products']} products...")

        categories = ['Electronics', 'Apparel', 'Food & Beverage', 'Health & Beauty', 'Home & Garden',
                     'Sports & Outdoors', 'Toys & Games', 'Automotive', 'Industrial', 'Office Supplies']

        for i in range(CONFIG['products']):
            self.product_id += 1

            category = random.choice(categories)

            # Generate SKU
            sku = f"{category[:3].upper()}-{self.product_id:06d}"

            # Product attributes based on category
            if category == 'Food & Beverage':
                is_perishable = True
                shelf_life_days = random.randint(7, 365)
                requires_cold_storage = random.random() < 0.3
            else:
                is_perishable = False
                shelf_life_days = None
                requires_cold_storage = False

            self.products.append({
                'product_id': self.product_id,
                'sku': sku,
                'product_name': f"{fake.word().capitalize()} {category} Product {i+1}",
                'category': category,
                'description': fake.sentence(),
                'unit_of_measure': random.choice(['Each', 'Case', 'Pallet', 'Box', 'Carton']),
                'weight_kg': round(random.uniform(0.1, 50), 2),
                'length_cm': round(random.uniform(5, 100), 1),
                'width_cm': round(random.uniform(5, 100), 1),
                'height_cm': round(random.uniform(5, 100), 1),
                'unit_cost': round(random.uniform(1, 500), 2),
                'selling_price': round(random.uniform(2, 750), 2),
                'reorder_point': random.randint(10, 100),
                'reorder_quantity': random.randint(50, 500),
                'is_hazmat': random.random() < 0.05,
                'is_fragile': random.random() < 0.2,
                'is_perishable': is_perishable,
                'shelf_life_days': shelf_life_days,
                'requires_cold_storage': requires_cold_storage,
                'created_at': datetime.now() - timedelta(days=random.randint(180, 730))
            })

    def generate_inventory_levels(self):
        """Generate current inventory levels"""
        print("Generating inventory levels...")

        for product in self.products:
            # Each product in 1-3 warehouses
            num_warehouses = random.randint(1, min(3, len(self.warehouses)))
            selected_warehouses = random.sample(self.warehouses, num_warehouses)

            for warehouse in selected_warehouses:
                self.inventory_id += 1

                # Select a storage bin
                storage_zones = [z for z in self.warehouse_zones
                               if z['warehouse_id'] == warehouse['warehouse_id']
                               and z['zone_type'] == 'Storage']

                if storage_zones:
                    zone = random.choice(storage_zones)
                    zone_bins = [b for b in self.warehouse_bins if b['zone_id'] == zone['zone_id']]
                    bin_location = random.choice(zone_bins)['bin_id'] if zone_bins else None
                else:
                    bin_location = None

                quantity = random.randint(0, 1000)

                self.inventory_levels.append({
                    'inventory_id': self.inventory_id,
                    'product_id': product['product_id'],
                    'warehouse_id': warehouse['warehouse_id'],
                    'bin_location_id': bin_location,
                    'quantity_on_hand': quantity,
                    'quantity_available': int(quantity * 0.9),
                    'quantity_reserved': int(quantity * 0.1),
                    'quantity_in_transit': random.randint(0, 100),
                    'last_counted_date': fake.date_between(start_date='-30d', end_date='today'),
                    'last_movement_date': fake.date_between(start_date='-7d', end_date='today'),
                    'created_at': product['created_at'],
                    'updated_at': datetime.now()
                })

    def generate_product_batches(self):
        """Generate product batches/lots"""
        print("Generating product batches...")

        for inventory in self.inventory_levels[:200]:  # Limit for demo
            if inventory['quantity_on_hand'] > 0:
                # Generate 1-3 batches per inventory location
                num_batches = random.randint(1, 3)
                remaining_qty = inventory['quantity_on_hand']

                for b in range(num_batches):
                    self.batch_id += 1

                    batch_qty = remaining_qty // (num_batches - b) if b < num_batches - 1 else remaining_qty
                    remaining_qty -= batch_qty

                    product = next(p for p in self.products if p['product_id'] == inventory['product_id'])

                    manufacture_date = fake.date_between(start_date='-180d', end_date='today')

                    if product['is_perishable']:
                        expiry_date = manufacture_date + timedelta(days=product['shelf_life_days'])
                    else:
                        expiry_date = None

                    self.product_batches.append({
                        'batch_id': self.batch_id,
                        'inventory_id': inventory['inventory_id'],
                        'batch_number': f"BATCH-{self.batch_id:08d}",
                        'manufacture_date': manufacture_date,
                        'expiry_date': expiry_date,
                        'quantity': batch_qty,
                        'quality_status': random.choice(['Passed', 'Pending', 'On Hold']),
                        'created_at': manufacture_date
                    })

    def generate_suppliers(self):
        """Generate suppliers"""
        print(f"Generating {CONFIG['suppliers']} suppliers...")

        for i in range(CONFIG['suppliers']):
            self.supplier_id += 1

            self.suppliers.append({
                'supplier_id': self.supplier_id,
                'supplier_code': f"SUP{self.supplier_id:04d}",
                'company_name': fake.company(),
                'contact_name': fake.name(),
                'email': fake.company_email(),
                'phone': fake.phone_number()[:20],
                'address': fake.street_address(),
                'city': fake.city(),
                'state': fake.state_abbr(),
                'zip_code': fake.zipcode(),
                'country': random.choice(['USA', 'Canada', 'Mexico', 'China']),
                'payment_terms': random.choice(['Net 30', 'Net 60', 'Net 90', '2/10 Net 30']),
                'lead_time_days': random.randint(1, 30),
                'minimum_order_value': random.randint(100, 10000),
                'rating': round(random.uniform(3.0, 5.0), 1),
                'is_active': random.random() > 0.1,
                'created_at': datetime.now() - timedelta(days=random.randint(365, 1095))
            })

    def generate_customers(self):
        """Generate customers"""
        print(f"Generating {CONFIG['customers']} customers...")

        customer_types = ['Retail', 'Wholesale', 'B2B', 'E-commerce']

        for i in range(CONFIG['customers']):
            self.customer_id += 1

            customer_type = random.choice(customer_types)

            if customer_type in ['B2B', 'Wholesale']:
                name = fake.company()
                email = fake.company_email()
            else:
                name = fake.name()
                email = fake.email()

            self.customers.append({
                'customer_id': self.customer_id,
                'customer_code': f"CUST{self.customer_id:05d}",
                'customer_name': name,
                'customer_type': customer_type,
                'email': email,
                'phone': fake.phone_number()[:20],
                'billing_address': fake.street_address(),
                'billing_city': fake.city(),
                'billing_state': fake.state_abbr(),
                'billing_zip': fake.zipcode(),
                'shipping_address': fake.street_address() if random.random() < 0.3 else None,
                'shipping_city': fake.city() if random.random() < 0.3 else None,
                'shipping_state': fake.state_abbr() if random.random() < 0.3 else None,
                'shipping_zip': fake.zipcode() if random.random() < 0.3 else None,
                'credit_limit': random.randint(1000, 100000) if customer_type in ['B2B', 'Wholesale'] else None,
                'payment_terms': random.choice(['COD', 'Net 30', 'Net 60']) if customer_type in ['B2B', 'Wholesale'] else 'Immediate',
                'is_active': random.random() > 0.05,
                'created_at': datetime.now() - timedelta(days=random.randint(180, 730))
            })

    def generate_purchase_orders(self):
        """Generate purchase orders"""
        print("Generating purchase orders...")

        statuses = ['Draft', 'Submitted', 'Approved', 'Received', 'Closed', 'Cancelled']

        # Generate historical orders
        current = self.start_date

        while current <= datetime.now():
            daily_orders = random.randint(5, 15)

            for _ in range(daily_orders):
                self.po_id += 1

                supplier = random.choice(self.suppliers)
                warehouse = random.choice(self.warehouses)

                order_date = current + timedelta(hours=random.randint(8, 18))

                # Determine status based on age
                days_old = (datetime.now() - order_date).days
                if days_old > 14:
                    status = random.choice(['Received', 'Closed'])
                elif days_old > 7:
                    status = random.choice(['Approved', 'Received'])
                else:
                    status = random.choice(['Submitted', 'Approved'])

                self.purchase_orders.append({
                    'po_id': self.po_id,
                    'po_number': f"PO{datetime.now().year}{self.po_id:06d}",
                    'supplier_id': supplier['supplier_id'],
                    'warehouse_id': warehouse['warehouse_id'],
                    'order_date': order_date,
                    'expected_delivery': order_date + timedelta(days=supplier['lead_time_days']),
                    'actual_delivery': order_date + timedelta(days=supplier['lead_time_days'] + random.randint(-2, 5)) if status in ['Received', 'Closed'] else None,
                    'status': status,
                    'total_amount': 0,  # Will be calculated from items
                    'notes': fake.sentence() if random.random() < 0.3 else None,
                    'created_by': fake.name(),
                    'created_at': order_date
                })

                # Generate order items
                num_items = random.randint(1, 10)
                order_total = 0

                for _ in range(num_items):
                    self.po_item_id += 1

                    product = random.choice(self.products)
                    quantity = random.randint(10, 500)
                    unit_price = product['unit_cost']
                    total_price = quantity * unit_price

                    self.purchase_order_items.append({
                        'po_item_id': self.po_item_id,
                        'po_id': self.po_id,
                        'product_id': product['product_id'],
                        'quantity_ordered': quantity,
                        'quantity_received': quantity if status in ['Received', 'Closed'] else 0,
                        'unit_price': unit_price,
                        'total_price': total_price,
                        'created_at': order_date
                    })

                    order_total += total_price

                # Update order total
                self.purchase_orders[-1]['total_amount'] = round(order_total, 2)

            current += timedelta(days=1)

    def generate_sales_orders(self):
        """Generate sales orders"""
        print("Generating sales orders...")

        statuses = ['Pending', 'Processing', 'Packed', 'Shipped', 'Delivered', 'Cancelled']

        # Generate historical orders
        current = self.start_date

        while current <= datetime.now():
            daily_orders = random.randint(30, CONFIG['orders_per_day'])

            for _ in range(daily_orders):
                self.so_id += 1

                customer = random.choice(self.customers)
                warehouse = random.choice(self.warehouses)

                order_date = current + timedelta(hours=random.randint(0, 23), minutes=random.randint(0, 59))

                # Determine status based on age
                days_old = (datetime.now() - order_date).days
                if days_old > 7:
                    status = random.choice(['Delivered', 'Delivered', 'Cancelled'])
                elif days_old > 3:
                    status = random.choice(['Shipped', 'Delivered'])
                elif days_old > 1:
                    status = random.choice(['Processing', 'Packed', 'Shipped'])
                else:
                    status = random.choice(['Pending', 'Processing'])

                self.sales_orders.append({
                    'so_id': self.so_id,
                    'order_number': f"SO{datetime.now().year}{self.so_id:06d}",
                    'customer_id': customer['customer_id'],
                    'warehouse_id': warehouse['warehouse_id'],
                    'order_date': order_date,
                    'required_date': order_date + timedelta(days=random.randint(1, 5)),
                    'shipped_date': order_date + timedelta(days=random.randint(1, 3)) if status in ['Shipped', 'Delivered'] else None,
                    'delivered_date': order_date + timedelta(days=random.randint(3, 7)) if status == 'Delivered' else None,
                    'status': status,
                    'priority': random.choice(['Low', 'Normal', 'High', 'Urgent']),
                    'shipping_method': random.choice(['Standard', 'Express', 'Next Day']),
                    'subtotal': 0,  # Will be calculated
                    'tax_amount': 0,
                    'shipping_cost': random.uniform(5, 50),
                    'total_amount': 0,
                    'payment_status': random.choice(['Paid', 'Pending', 'Partial']) if status != 'Cancelled' else 'Cancelled',
                    'created_at': order_date
                })

                # Generate order items
                num_items = random.randint(1, 8)
                order_subtotal = 0

                for _ in range(num_items):
                    self.so_item_id += 1

                    product = random.choice(self.products)
                    quantity = random.randint(1, 20)
                    unit_price = product['selling_price']
                    discount = random.uniform(0, 0.2) if random.random() < 0.3 else 0
                    total_price = quantity * unit_price * (1 - discount)

                    self.sales_order_items.append({
                        'so_item_id': self.so_item_id,
                        'so_id': self.so_id,
                        'product_id': product['product_id'],
                        'quantity_ordered': quantity,
                        'quantity_shipped': quantity if status in ['Shipped', 'Delivered'] else 0,
                        'unit_price': unit_price,
                        'discount_percentage': discount * 100,
                        'total_price': round(total_price, 2),
                        'created_at': order_date
                    })

                    order_subtotal += total_price

                # Update order totals
                tax_rate = random.uniform(0.05, 0.10)
                tax = order_subtotal * tax_rate
                self.sales_orders[-1]['subtotal'] = round(order_subtotal, 2)
                self.sales_orders[-1]['tax_amount'] = round(tax, 2)
                self.sales_orders[-1]['total_amount'] = round(order_subtotal + tax + self.sales_orders[-1]['shipping_cost'], 2)

            current += timedelta(days=1)

    def generate_carriers(self):
        """Generate shipping carriers"""
        print(f"Generating {CONFIG['carriers']} carriers...")

        carrier_names = ['FedEx', 'UPS', 'DHL', 'USPS', 'Regional Express', 'Local Courier']

        for i in range(CONFIG['carriers']):
            self.carrier_id += 1

            name = carrier_names[i % len(carrier_names)] + (f" {i//len(carrier_names) + 1}" if i >= len(carrier_names) else "")

            self.carriers.append({
                'carrier_id': self.carrier_id,
                'carrier_code': f"CAR{self.carrier_id:03d}",
                'carrier_name': name,
                'contact_name': fake.name(),
                'phone': fake.phone_number()[:20],
                'email': fake.company_email(),
                'api_endpoint': f"https://api.{name.lower().replace(' ', '')}.com/v1/",
                'api_key': hashlib.md5(f"key_{self.carrier_id}".encode()).hexdigest(),
                'is_active': True,
                'created_at': datetime.now() - timedelta(days=random.randint(365, 730))
            })

    def generate_carrier_services(self):
        """Generate carrier service types"""
        print("Generating carrier services...")

        services = {
            'Ground': (1, 5, 10, 50),
            'Express': (1, 2, 25, 100),
            'Next Day': (1, 1, 50, 200),
            'Economy': (3, 7, 5, 30),
            'Priority': (1, 3, 20, 80)
        }

        for carrier in self.carriers:
            for service_name, (min_days, max_days, min_cost, max_cost) in services.items():
                self.service_id += 1

                self.carrier_services.append({
                    'service_id': self.service_id,
                    'carrier_id': carrier['carrier_id'],
                    'service_name': service_name,
                    'service_code': f"{carrier['carrier_code']}-{service_name[:3].upper()}",
                    'transit_time_days': random.randint(min_days, max_days),
                    'base_cost': round(random.uniform(min_cost, max_cost), 2),
                    'cost_per_kg': round(random.uniform(0.5, 2), 2),
                    'max_weight_kg': random.randint(30, 100),
                    'max_dimensions_cm': '100x100x100',
                    'is_active': True,
                    'created_at': carrier['created_at']
                })

    def generate_shipments(self):
        """Generate shipments for orders"""
        print("Generating shipments...")

        # Create shipments for shipped/delivered sales orders
        shipped_orders = [o for o in self.sales_orders if o['status'] in ['Shipped', 'Delivered']]

        for order in shipped_orders:
            self.shipment_id += 1

            carrier = random.choice(self.carriers)
            carrier_services = [s for s in self.carrier_services if s['carrier_id'] == carrier['carrier_id']]
            service = random.choice(carrier_services)

            # Calculate weight from order items
            order_items = [i for i in self.sales_order_items if i['so_id'] == order['so_id']]
            total_weight = sum(
                next(p for p in self.products if p['product_id'] == item['product_id'])['weight_kg'] * item['quantity_ordered']
                for item in order_items
            )

            self.shipments.append({
                'shipment_id': self.shipment_id,
                'shipment_number': f"SHP{datetime.now().year}{self.shipment_id:06d}",
                'order_id': order['so_id'],
                'order_type': 'sales',
                'carrier_id': carrier['carrier_id'],
                'service_id': service['service_id'],
                'tracking_number': f"{carrier['carrier_code']}{random.randint(1000000000, 9999999999)}",
                'ship_date': order['shipped_date'],
                'estimated_delivery': order['shipped_date'] + timedelta(days=service['transit_time_days']),
                'actual_delivery': order['delivered_date'],
                'status': 'Delivered' if order['status'] == 'Delivered' else 'In Transit',
                'weight_kg': round(total_weight, 2),
                'shipping_cost': order['shipping_cost'],
                'from_warehouse_id': order['warehouse_id'],
                'to_address': fake.street_address(),
                'to_city': fake.city(),
                'to_state': fake.state_abbr(),
                'to_zip': fake.zipcode(),
                'created_at': order['shipped_date']
            })

    def generate_shipment_tracking(self):
        """Generate shipment tracking events"""
        print("Generating shipment tracking...")

        tracking_statuses = [
            'Label Created',
            'Picked Up',
            'In Transit',
            'Out for Delivery',
            'Delivered',
            'Exception'
        ]

        for shipment in self.shipments[:500]:  # Limit for demo
            if shipment['ship_date']:
                current_time = shipment['ship_date']

                # Generate tracking events
                for i, status in enumerate(tracking_statuses[:5] if shipment['status'] == 'Delivered' else tracking_statuses[:3]):
                    self.tracking_id += 1

                    location = fake.city() + ', ' + fake.state_abbr()

                    self.shipment_tracking.append({
                        'tracking_id': self.tracking_id,
                        'shipment_id': shipment['shipment_id'],
                        'status': status,
                        'location': location,
                        'description': f"Package {status.lower()} at {location}",
                        'event_date': current_time,
                        'created_at': current_time
                    })

                    current_time += timedelta(hours=random.randint(4, 24))

                    if status == 'Delivered':
                        break

    def generate_vehicles(self):
        """Generate delivery vehicles"""
        print(f"Generating {CONFIG['vehicles']} vehicles...")

        vehicle_types = ['Van', 'Truck', 'Semi-Trailer', 'Box Truck']

        for i in range(CONFIG['vehicles']):
            self.vehicle_id += 1

            vehicle_type = random.choice(vehicle_types)

            self.vehicles.append({
                'vehicle_id': self.vehicle_id,
                'vehicle_number': f"VEH{self.vehicle_id:04d}",
                'license_plate': f"{fake.state_abbr()}{random.randint(100, 999)}{random.choice('ABCDEFGHIJKLMNOPQRSTUVWXYZ')}{random.choice('ABCDEFGHIJKLMNOPQRSTUVWXYZ')}{random.randint(0, 9)}",
                'vehicle_type': vehicle_type,
                'make': random.choice(['Ford', 'Chevrolet', 'Mercedes', 'Volvo']),
                'model': f"Model {random.randint(2018, 2024)}",
                'year': random.randint(2018, 2024),
                'capacity_kg': random.randint(1000, 10000) if vehicle_type != 'Semi-Trailer' else random.randint(20000, 30000),
                'fuel_type': random.choice(['Gasoline', 'Diesel', 'Electric']),
                'current_mileage': random.randint(10000, 200000),
                'last_service_date': fake.date_between(start_date='-60d', end_date='today'),
                'next_service_mileage': random.randint(210000, 250000),
                'insurance_expiry': fake.date_between(start_date='today', end_date='+1y'),
                'registration_expiry': fake.date_between(start_date='today', end_date='+1y'),
                'status': random.choice(['Available', 'In Use', 'Maintenance']),
                'assigned_warehouse_id': random.choice(self.warehouses)['warehouse_id'],
                'created_at': datetime.now() - timedelta(days=random.randint(180, 1095))
            })

    def generate_drivers(self):
        """Generate drivers"""
        print(f"Generating {CONFIG['drivers']} drivers...")

        for i in range(CONFIG['drivers']):
            self.driver_id += 1

            hire_date = fake.date_between(start_date='-5y', end_date='today')

            self.drivers.append({
                'driver_id': self.driver_id,
                'employee_id': f"EMP{self.driver_id:05d}",
                'first_name': fake.first_name(),
                'last_name': fake.last_name(),
                'email': fake.email(),
                'phone': fake.phone_number()[:20],
                'license_number': f"DL{fake.state_abbr()}{random.randint(1000000, 9999999)}",
                'license_type': random.choice(['Regular', 'CDL-A', 'CDL-B']),
                'license_expiry': fake.date_between(start_date='+6m', end_date='+3y'),
                'hire_date': hire_date,
                'assigned_vehicle_id': random.choice(self.vehicles)['vehicle_id'] if random.random() < 0.7 else None,
                'home_warehouse_id': random.choice(self.warehouses)['warehouse_id'],
                'status': random.choice(['Active', 'On Leave', 'Terminated']),
                'created_at': hire_date
            })

    def generate_routes(self):
        """Generate delivery routes"""
        print("Generating delivery routes...")

        # Generate daily routes
        current = self.start_date.date()

        while current <= date.today():
            # Generate 5-10 routes per day
            daily_routes = random.randint(5, 10)

            for _ in range(daily_routes):
                self.route_id += 1

                warehouse = random.choice(self.warehouses)

                # Get orders for this day and warehouse
                day_orders = [o for o in self.sales_orders
                            if o['order_date'].date() == current
                            and o['warehouse_id'] == warehouse['warehouse_id']
                            and o['status'] in ['Processing', 'Packed', 'Shipped']]

                if day_orders:
                    num_stops = min(len(day_orders), random.randint(5, 20))
                    route_orders = random.sample(day_orders, num_stops)

                    self.routes.append({
                        'route_id': self.route_id,
                        'route_code': f"RT{current.strftime('%Y%m%d')}{self.route_id:04d}",
                        'route_date': current,
                        'warehouse_id': warehouse['warehouse_id'],
                        'planned_stops': num_stops,
                        'completed_stops': num_stops if current < date.today() else 0,
                        'total_distance_km': random.uniform(50, 300),
                        'estimated_duration_hours': random.uniform(4, 10),
                        'actual_duration_hours': random.uniform(4, 12) if current < date.today() else None,
                        'status': 'Completed' if current < date.today() else 'Planned',
                        'created_at': datetime.combine(current, datetime.min.time())
                    })

            current += timedelta(days=1)

    def generate_delivery_runs(self):
        """Generate delivery run assignments"""
        print("Generating delivery runs...")

        for route in self.routes:
            if route['planned_stops'] > 0:
                self.run_id += 1

                # Assign driver and vehicle
                available_drivers = [d for d in self.drivers
                                   if d['status'] == 'Active'
                                   and d['home_warehouse_id'] == route['warehouse_id']]

                if available_drivers:
                    driver = random.choice(available_drivers)
                    vehicle = next((v for v in self.vehicles if v['vehicle_id'] == driver['assigned_vehicle_id']), None)

                    if not vehicle:
                        available_vehicles = [v for v in self.vehicles
                                            if v['status'] == 'Available'
                                            and v['assigned_warehouse_id'] == route['warehouse_id']]
                        vehicle = random.choice(available_vehicles) if available_vehicles else None

                    if vehicle:
                        start_time = datetime.combine(route['route_date'], datetime.min.time().replace(hour=8))

                        self.delivery_runs.append({
                            'run_id': self.run_id,
                            'route_id': route['route_id'],
                            'driver_id': driver['driver_id'],
                            'vehicle_id': vehicle['vehicle_id'],
                            'start_time': start_time,
                            'end_time': start_time + timedelta(hours=route['actual_duration_hours']) if route['actual_duration_hours'] else None,
                            'start_mileage': vehicle['current_mileage'],
                            'end_mileage': vehicle['current_mileage'] + int(route['total_distance_km'] * 0.621371) if route['status'] == 'Completed' else None,
                            'fuel_used_liters': route['total_distance_km'] * 0.08 if route['status'] == 'Completed' else None,
                            'status': route['status'],
                            'notes': None,
                            'created_at': start_time
                        })

    def generate_inventory_movements(self):
        """Generate inventory movement records"""
        print("Generating inventory movements...")

        movement_types = ['Receipt', 'Shipment', 'Transfer', 'Adjustment', 'Return']

        # Generate movements for recent orders
        for po in self.purchase_orders[-100:]:  # Last 100 POs
            if po['status'] == 'Received':
                po_items = [i for i in self.purchase_order_items if i['po_id'] == po['po_id']]

                for item in po_items:
                    self.movement_id += 1

                    # Find inventory location
                    inventory = next((inv for inv in self.inventory_levels
                                    if inv['product_id'] == item['product_id']
                                    and inv['warehouse_id'] == po['warehouse_id']), None)

                    if inventory:
                        self.inventory_movements.append({
                            'movement_id': self.movement_id,
                            'inventory_id': inventory['inventory_id'],
                            'movement_type': 'Receipt',
                            'reference_type': 'PO',
                            'reference_id': po['po_id'],
                            'quantity': item['quantity_received'],
                            'from_location': None,
                            'to_location': inventory['bin_location_id'],
                            'movement_date': po['actual_delivery'],
                            'performed_by': fake.name(),
                            'notes': f"Received from PO {po['po_number']}",
                            'created_at': po['actual_delivery']
                        })

    def generate_kpi_metrics(self):
        """Generate KPI metrics"""
        print("Generating KPI metrics...")

        # Generate daily metrics
        current = self.start_date.date()

        while current <= date.today():
            for warehouse in self.warehouses:
                self.kpi_id += 1

                # Calculate metrics for this day and warehouse
                day_orders = [o for o in self.sales_orders
                            if o['order_date'].date() == current
                            and o['warehouse_id'] == warehouse['warehouse_id']]

                day_shipments = [s for s in self.shipments
                               if s['ship_date'] and s['ship_date'].date() == current
                               and s['from_warehouse_id'] == warehouse['warehouse_id']]

                orders_received = len(day_orders)
                orders_shipped = len(day_shipments)

                # Calculate order fulfillment rate
                fulfillment_rate = (orders_shipped / orders_received * 100) if orders_received > 0 else 0

                # Inventory metrics
                warehouse_inventory = [inv for inv in self.inventory_levels
                                      if inv['warehouse_id'] == warehouse['warehouse_id']]

                total_inventory_value = sum(
                    inv['quantity_on_hand'] * next(p for p in self.products if p['product_id'] == inv['product_id'])['unit_cost']
                    for inv in warehouse_inventory
                )

                self.kpi_metrics.append({
                    'metric_id': self.kpi_id,
                    'warehouse_id': warehouse['warehouse_id'],
                    'metric_date': current,
                    'orders_received': orders_received,
                    'orders_shipped': orders_shipped,
                    'orders_pending': max(0, orders_received - orders_shipped),
                    'fulfillment_rate': round(fulfillment_rate, 2),
                    'inventory_turnover': round(random.uniform(4, 12), 2),
                    'inventory_value': round(total_inventory_value, 2),
                    'picking_accuracy': round(random.uniform(95, 99.9), 2),
                    'on_time_delivery_rate': round(random.uniform(85, 98), 2),
                    'warehouse_utilization': round(random.uniform(60, 95), 2),
                    'labor_productivity': round(random.uniform(20, 40), 2),
                    'created_at': datetime.combine(current, datetime.min.time())
                })

            current += timedelta(days=1)

    def generate_audit_log(self):
        """Generate audit log entries"""
        print("Generating audit logs...")

        actions = ['CREATE', 'UPDATE', 'DELETE', 'VIEW', 'EXPORT']
        entities = ['Order', 'Shipment', 'Inventory', 'Product', 'Customer']

        for _ in range(1000):  # Generate 1000 audit entries
            self.audit_id += 1

            action_time = fake.date_time_between(start_date=self.start_date, end_date='now')

            self.audit_log.append({
                'audit_id': self.audit_id,
                'user_id': fake.name(),
                'action': random.choice(actions),
                'entity_type': random.choice(entities),
                'entity_id': random.randint(1, 1000),
                'old_values': json.dumps({'field': 'old_value'}) if random.choice(actions) == 'UPDATE' else None,
                'new_values': json.dumps({'field': 'new_value'}) if random.choice(actions) in ['CREATE', 'UPDATE'] else None,
                'ip_address': fake.ipv4(),
                'user_agent': 'Mozilla/5.0',
                'action_timestamp': action_time,
                'created_at': action_time
            })

    def save_all(self):
        """Save all generated data to CSV files"""
        OUTPUT_DIR.mkdir(exist_ok=True)

        print("\nSaving data to CSV files...")

        datasets = [
            ('warehouses', self.warehouses),
            ('warehouse_zones', self.warehouse_zones),
            ('warehouse_bins', self.warehouse_bins),
            ('docking_stations', self.docking_stations),
            ('products', self.products),
            ('inventory_levels', self.inventory_levels),
            ('product_batches', self.product_batches),
            ('inventory_movements', self.inventory_movements),
            ('suppliers', self.suppliers),
            ('customers', self.customers),
            ('purchase_orders', self.purchase_orders),
            ('purchase_order_items', self.purchase_order_items[:5000]),  # Limit for demo
            ('sales_orders', self.sales_orders),
            ('sales_order_items', self.sales_order_items[:5000]),  # Limit for demo
            ('carriers', self.carriers),
            ('carrier_services', self.carrier_services),
            ('shipments', self.shipments),
            ('shipment_tracking', self.shipment_tracking),
            ('vehicles', self.vehicles),
            ('drivers', self.drivers),
            ('routes', self.routes),
            ('delivery_runs', self.delivery_runs),
            ('kpi_metrics', self.kpi_metrics),
            ('audit_log', self.audit_log)
        ]

        for name, data in datasets:
            if data:
                filepath = OUTPUT_DIR / f"{name}.csv"
                with open(filepath, 'w', newline='', encoding='utf-8') as f:
                    writer = csv.DictWriter(f, fieldnames=data[0].keys())
                    writer.writeheader()
                    writer.writerows(data)
                print(f"  [OK] {name}: {len(data):,} records")

        self.generate_summary()

    def generate_summary(self):
        """Generate summary statistics"""
        print(f"\nLogistics & Supply Chain Data Generation Summary")
        print("=" * 50)

        print(f"\nInfrastructure:")
        print(f"  Warehouses: {len(self.warehouses)}")
        print(f"  Warehouse Zones: {len(self.warehouse_zones)}")
        print(f"  Storage Bins: {len(self.warehouse_bins)}")
        print(f"  Docking Stations: {len(self.docking_stations)}")

        print(f"\nInventory:")
        print(f"  Products: {len(self.products)}")
        print(f"  Inventory Locations: {len(self.inventory_levels)}")
        print(f"  Product Batches: {len(self.product_batches)}")
        print(f"  Inventory Movements: {len(self.inventory_movements)}")

        print(f"\nPartners:")
        print(f"  Suppliers: {len(self.suppliers)}")
        print(f"  Customers: {len(self.customers)}")

        print(f"\nOrders:")
        print(f"  Purchase Orders: {len(self.purchase_orders)}")
        print(f"  Sales Orders: {len(self.sales_orders)}")
        print(f"  Total Order Items: {len(self.purchase_order_items) + len(self.sales_order_items):,}")

        print(f"\nShipping:")
        print(f"  Carriers: {len(self.carriers)}")
        print(f"  Carrier Services: {len(self.carrier_services)}")
        print(f"  Shipments: {len(self.shipments)}")
        print(f"  Tracking Events: {len(self.shipment_tracking)}")

        print(f"\nFleet:")
        print(f"  Vehicles: {len(self.vehicles)}")
        print(f"  Drivers: {len(self.drivers)}")
        print(f"  Routes: {len(self.routes)}")
        print(f"  Delivery Runs: {len(self.delivery_runs)}")

        print(f"\nAnalytics:")
        print(f"  KPI Metrics: {len(self.kpi_metrics)}")
        print(f"  Audit Logs: {len(self.audit_log)}")

        # Calculate some statistics
        total_inventory_value = sum(
            inv['quantity_on_hand'] * next(p for p in self.products if p['product_id'] == inv['product_id'])['unit_cost']
            for inv in self.inventory_levels
        )

        delivered_orders = len([o for o in self.sales_orders if o['status'] == 'Delivered'])
        if len(self.sales_orders) > 0:
            delivery_rate = (delivered_orders / len(self.sales_orders)) * 100
            print(f"\nPerformance:")
            print(f"  Order Delivery Rate: {delivery_rate:.1f}%")
            print(f"  Total Inventory Value: ${total_inventory_value:,.2f}")

        print(f"\nFiles Generated: 24")

if __name__ == "__main__":
    generator = LogisticsGenerator()
    generator.generate_all()
    print("\n[SUCCESS] Logistics & Supply Chain data generation complete!")