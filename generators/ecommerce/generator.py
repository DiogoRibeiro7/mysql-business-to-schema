#!/usr/bin/env python3
"""E-commerce Platform Data Generator.

Generates realistic data for a comprehensive online retail platform
"""

import csv
import json
import random
import hashlib
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
    "customers": 10000,
    "products": 5000,
    "categories": 150,
    "brands": 200,
    "warehouses": 5,
    "orders_per_day": 500,
    "days_of_history": 365,
    "review_rate": 0.15,  # 15% of purchases get reviewed
    "cart_abandonment_rate": 0.70,  # 70% cart abandonment
    "return_rate": 0.08,  # 8% of orders have returns
    "support_ticket_rate": 0.05,  # 5% of orders generate tickets
}


class EcommerceGenerator:
    """Represent EcommerceGenerator."""

    def __init__(self):
        """Initialize the instance."""
        self.customers: List[Any] = []
        self.addresses: List[Any] = []
        self.categories: List[Any] = []
        self.brands: List[Any] = []
        self.products: List[Any] = []
        self.variants: List[Any] = []
        self.images: List[Any] = []
        self.warehouses: List[Any] = []
        self.inventory: List[Any] = []
        self.orders: List[Any] = []
        self.order_items: List[Any] = []
        self.cart_items: List[Any] = []
        self.wishlist: List[Any] = []
        self.reviews: List[Any] = []
        self.coupons: List[Any] = []
        self.page_views: List[Any] = []
        self.search_queries: List[Any] = []
        self.support_tickets: List[Any] = []
        self.returns: List[Any] = []
        self.shipments: List[Any] = []
        self.payments: List[Any] = []

        # Counters
        self.address_id = 0
        self.variant_id = 0
        self.image_id = 0
        self.inventory_id = 0
        self.order_id = 0
        self.order_item_id = 0
        self.cart_id = 0
        self.wishlist_id = 0
        self.review_id = 0
        self.view_id = 0
        self.search_id = 0
        self.ticket_id = 0
        self.return_id = 0
        self.shipment_id = 0
        self.payment_id = 0
        self.transaction_id = 0

    def generate_all(self):
        """Generate all e-commerce data."""
        print("Starting E-commerce Data Generation...")

        # Core entities
        self.generate_customers()
        self.generate_categories()
        self.generate_brands()
        self.generate_products()
        self.generate_warehouses()
        self.generate_inventory()

        # Shopping activity
        self.generate_shopping_behavior()
        self.generate_orders()

        # Reviews and support
        self.generate_reviews()
        self.generate_support_and_returns()

        # Promotions
        self.generate_promotions()

        # Analytics
        self.generate_analytics()

        # Save all data
        self.save_all()

    def generate_customers(self):
        """Generate customer accounts."""
        print(f"Generating {CONFIG['customers']} customers...")

        customer_types = (
            ["regular"] * 70 + ["prime"] * 25 + ["vip"] * 4 + ["wholesale"] * 1
        )

        for i in range(CONFIG["customers"]):
            # Create customer
            customer = {
                "customer_id": i + 1,
                "email": fake.unique.email(),
                "username": fake.unique.user_name(),
                "password_hash": hashlib.sha256(fake.password().encode()).hexdigest(),
                "first_name": fake.first_name(),
                "last_name": fake.last_name(),
                "phone": fake.phone_number()[:20],
                "date_of_birth": fake.date_of_birth(minimum_age=18, maximum_age=80),
                "gender": random.choice(["M", "F", "Other", "Prefer not to say"]),
                "customer_type": random.choice(customer_types),
                "email_verified": random.random() > 0.1,
                "phone_verified": random.random() > 0.3,
                "two_factor_enabled": random.random() > 0.8,
                "preferred_language": random.choice(
                    ["en"] * 80 + ["es"] * 10 + ["fr"] * 5 + ["de"] * 3 + ["zh"] * 2
                ),
                "preferred_currency": random.choice(
                    ["USD"] * 70 + ["EUR"] * 15 + ["GBP"] * 10 + ["CAD"] * 5
                ),
                "referral_code": fake.bothify(text="REF####???"),
                "referred_by": random.choice([None] * 80 + list(range(1, min(i, 100)))),
                "loyalty_points": (
                    random.randint(0, 5000) if random.random() > 0.5 else 0
                ),
                "lifetime_value": 0,  # Will be calculated from orders
                "status": random.choice(
                    ["active"] * 95 + ["inactive"] * 4 + ["suspended"] * 1
                ),
                "last_login_at": (
                    fake.date_time_between(start_date="-30d", end_date="now")
                    if random.random() > 0.2
                    else None
                ),
                "created_at": fake.date_time_between(start_date="-3y", end_date="now"),
                "updated_at": fake.date_time_between(start_date="-30d", end_date="now"),
            }
            self.customers.append(customer)

            # Create 1-3 addresses per customer
            num_addresses = random.choices([1, 2, 3], weights=[60, 30, 10])[0]
            for j in range(num_addresses):
                self.address_id += 1
                address = {
                    "address_id": self.address_id,
                    "customer_id": i + 1,
                    "address_type": random.choice(["billing", "shipping", "both"]),
                    "is_default": j == 0,
                    "recipient_name": f"{customer['first_name']} {customer['last_name']}",
                    "company_name": fake.company() if random.random() > 0.7 else None,
                    "address_line1": fake.street_address(),
                    "address_line2": (
                        fake.secondary_address() if random.random() > 0.7 else None
                    ),
                    "city": fake.city(),
                    "state_province": fake.state(),
                    "postal_code": fake.postcode(),
                    "country_code": fake.country_code(),
                    "phone": customer["phone"],
                    "delivery_instructions": (
                        fake.sentence() if random.random() > 0.8 else None
                    ),
                    "latitude": float(fake.latitude()),
                    "longitude": float(fake.longitude()),
                    "validated": random.random() > 0.2,
                    "created_at": customer["created_at"],
                    "updated_at": customer["updated_at"],
                }
                self.addresses.append(address)

    def generate_categories(self):
        """Generate product categories with hierarchy."""
        print(f"Generating {CONFIG['categories']} categories...")

        # Main categories
        main_categories = [
            "Electronics",
            "Clothing & Accessories",
            "Home & Garden",
            "Sports & Outdoors",
            "Books & Media",
            "Toys & Games",
            "Health & Beauty",
            "Automotive",
            "Food & Beverages",
            "Office Supplies",
            "Pet Supplies",
            "Tools & Hardware",
        ]

        category_id = 0

        # Create main categories
        for cat_name in main_categories:
            category_id += 1
            category = {
                "category_id": category_id,
                "parent_category_id": None,
                "category_name": cat_name,
                "slug": cat_name.lower().replace(" & ", "-").replace(" ", "-"),
                "description": fake.paragraph(),
                "image_url": f"https://cdn.example.com/categories/{category_id}.jpg",
                "meta_title": f"{cat_name} - Best Selection Online",
                "meta_description": fake.sentence(),
                "meta_keywords": ", ".join(fake.words(5)),
                "display_order": category_id,
                "is_active": True,
                "product_count": 0,
                "path": str(category_id),
                "level": 0,
                "created_at": fake.date_time_between(start_date="-2y", end_date="-1y"),
                "updated_at": fake.date_time_between(start_date="-30d", end_date="now"),
            }
            self.categories.append(category)

        # Create subcategories
        while category_id < CONFIG["categories"]:
            parent_id = random.randint(1, min(category_id, len(main_categories) * 2))
            parent = next(c for c in self.categories if c["category_id"] == parent_id)
            category_id += 1

            category = {
                "category_id": category_id,
                "parent_category_id": parent_id,
                "category_name": fake.word().capitalize()
                + " "
                + fake.word().capitalize(),
                "slug": fake.slug(),
                "description": fake.paragraph(),
                "image_url": f"https://cdn.example.com/categories/{category_id}.jpg",
                "meta_title": fake.sentence(),
                "meta_description": fake.sentence(),
                "meta_keywords": ", ".join(fake.words(5)),
                "display_order": category_id,
                "is_active": random.random() > 0.05,
                "product_count": 0,
                "path": f"{parent['path']}/{category_id}",
                "level": parent["level"] + 1,
                "created_at": fake.date_time_between(start_date="-2y", end_date="-1y"),
                "updated_at": fake.date_time_between(start_date="-30d", end_date="now"),
            }
            self.categories.append(category)

    def generate_brands(self):
        """Generate product brands."""
        print(f"Generating {CONFIG['brands']} brands...")

        for i in range(CONFIG["brands"]):
            brand = {
                "brand_id": i + 1,
                "brand_name": fake.company(),
                "slug": fake.slug(),
                "logo_url": f"https://cdn.example.com/brands/{i+1}.png",
                "website_url": fake.url(),
                "description": fake.paragraph(),
                "country_of_origin": fake.country_code(),
                "is_featured": random.random() > 0.85,
                "is_active": random.random() > 0.05,
                "created_at": fake.date_time_between(start_date="-3y", end_date="-1y"),
                "updated_at": fake.date_time_between(start_date="-30d", end_date="now"),
            }
            self.brands.append(brand)

    def generate_products(self):
        """Generate products with variants and images."""
        print(f"Generating {CONFIG['products']} products...")

        statuses = (
            ["active"] * 80
            + ["inactive"] * 10
            + ["out_of_stock"] * 5
            + ["discontinued"] * 3
            + ["draft"] * 2
        )

        for i in range(CONFIG["products"]):
            # Base product
            category = random.choice(self.categories)
            brand = random.choice(self.brands) if random.random() > 0.2 else None

            base_price = round(random.uniform(9.99, 999.99), 2)
            cost = round(base_price * random.uniform(0.3, 0.7), 2)

            product = {
                "product_id": i + 1,
                "sku": f"SKU{str(i+1).zfill(6)}",
                "product_name": " ".join(
                    [fake.word().capitalize() for _ in range(random.randint(2, 5))]
                ),
                "slug": fake.slug(),
                "brand_id": brand["brand_id"] if brand else None,
                "category_id": category["category_id"],
                "description": fake.paragraph(nb_sentences=5),
                "short_description": fake.sentence(),
                "features": json.dumps(
                    [fake.sentence() for _ in range(random.randint(3, 7))]
                ),
                "specifications": json.dumps(
                    {
                        "weight": f"{random.uniform(0.1, 10):.1f}kg",
                        "dimensions": f"{random.randint(10, 50)}x{random.randint(10, 50)}x{random.randint(10, 50)}cm",
                        "material": random.choice(
                            ["Plastic", "Metal", "Wood", "Fabric", "Glass", "Ceramic"]
                        ),
                        "warranty": random.choice(
                            ["6 months", "1 year", "2 years", "3 years", "Lifetime"]
                        ),
                    }
                ),
                "base_price": base_price,
                "compare_at_price": (
                    round(base_price * random.uniform(1.1, 1.5), 2)
                    if random.random() > 0.6
                    else None
                ),
                "cost": cost,
                "tax_class": random.choice(["standard", "reduced", "zero"]),
                "weight_kg": round(random.uniform(0.1, 20), 3),
                "dimensions_cm": json.dumps(
                    {
                        "length": random.randint(5, 100),
                        "width": random.randint(5, 100),
                        "height": random.randint(5, 100),
                    }
                ),
                "is_digital": random.random() > 0.9,
                "is_featured": random.random() > 0.85,
                "is_new": random.random() > 0.8,
                "requires_shipping": random.random() > 0.1,
                "max_quantity_per_order": random.choice([None] * 80 + [5, 10, 20]),
                "min_quantity_per_order": random.choice([1] * 95 + [2, 3, 5]),
                "status": random.choice(statuses),
                "launch_date": fake.date_between(start_date="-1y", end_date="+1m"),
                "discontinue_date": (
                    fake.date_between(start_date="+1y", end_date="+3y")
                    if random.random() > 0.95
                    else None
                ),
                "view_count": random.randint(0, 10000),
                "sold_count": random.randint(0, 1000),
                "average_rating": round(random.uniform(3.0, 5.0), 2),
                "review_count": random.randint(0, 200),
                "created_at": fake.date_time_between(start_date="-2y", end_date="-1m"),
                "updated_at": fake.date_time_between(start_date="-30d", end_date="now"),
            }
            self.products.append(product)

            # Update category product count
            category["product_count"] += 1

            # Generate variants (sizes, colors, etc.)
            if random.random() > 0.3:  # 70% of products have variants
                num_variants = random.randint(2, 8)
                variant_types = random.choice(
                    [
                        ["Small", "Medium", "Large", "X-Large"],
                        ["Red", "Blue", "Green", "Black", "White"],
                        ["32GB", "64GB", "128GB", "256GB"],
                        ["Standard", "Pro", "Premium"],
                    ]
                )

                for j, variant_name in enumerate(variant_types[:num_variants]):
                    self.variant_id += 1
                    price_modifier = random.uniform(0.8, 1.3)
                    variant = {
                        "variant_id": self.variant_id,
                        "product_id": i + 1,
                        "variant_sku": f"{product['sku']}-{variant_name[:3].upper()}",
                        "variant_name": variant_name,
                        "attributes": json.dumps({"option": variant_name}),
                        "price": round(base_price * price_modifier, 2),
                        "compare_at_price": (
                            round(base_price * price_modifier * 1.2, 2)
                            if random.random() > 0.7
                            else None
                        ),
                        "cost": round(cost * price_modifier, 2),
                        "weight_kg": product["weight_kg"] * random.uniform(0.9, 1.1),
                        "barcode": fake.ean13(),
                        "image_url": f"https://cdn.example.com/products/{i+1}/variant_{j+1}.jpg",
                        "position": j,
                        "is_default": j == 0,
                        "created_at": product["created_at"],
                        "updated_at": product["updated_at"],
                    }
                    self.variants.append(variant)

            # Generate product images
            num_images = random.randint(1, 6)
            for j in range(num_images):
                self.image_id += 1
                image = {
                    "image_id": self.image_id,
                    "product_id": i + 1,
                    "variant_id": None,
                    "image_url": f"https://cdn.example.com/products/{i+1}/image_{j+1}.jpg",
                    "thumbnail_url": f"https://cdn.example.com/products/{i+1}/thumb_{j+1}.jpg",
                    "alt_text": f"{product['product_name']} - View {j+1}",
                    "position": j,
                    "is_primary": j == 0,
                    "created_at": product["created_at"],
                }
                self.images.append(image)

    def generate_warehouses(self):
        """Generate warehouse locations."""
        print(f"Generating {CONFIG['warehouses']} warehouses...")

        warehouse_locations = [
            ("WH-EAST", "East Coast Distribution", "New York", "NY"),
            ("WH-WEST", "West Coast Distribution", "Los Angeles", "CA"),
            ("WH-CENTRAL", "Central Distribution", "Chicago", "IL"),
            ("WH-SOUTH", "South Distribution", "Atlanta", "GA"),
            ("WH-NORTH", "North Distribution", "Seattle", "WA"),
        ]

        for i, (code, name, city, state) in enumerate(
            warehouse_locations[: CONFIG["warehouses"]]
        ):
            warehouse = {
                "warehouse_id": i + 1,
                "warehouse_code": code,
                "warehouse_name": name,
                "address": fake.street_address(),
                "city": city,
                "state_province": state,
                "postal_code": fake.postcode(),
                "country_code": "US",
                "phone": fake.phone_number()[:20],
                "email": f"{code.lower()}@example.com",
                "manager_name": fake.name(),
                "latitude": float(fake.latitude()),
                "longitude": float(fake.longitude()),
                "is_active": True,
                "is_default": i == 0,
                "fulfills_online_orders": True,
                "created_at": fake.date_time_between(start_date="-3y", end_date="-2y"),
                "updated_at": fake.date_time_between(start_date="-30d", end_date="now"),
            }
            self.warehouses.append(warehouse)

    def generate_inventory(self):
        """Generate inventory levels for products in warehouses."""
        print("Generating inventory...")

        inventory_movements = []
        movement_id = 0

        for product in self.products:
            # Determine if product has variants
            product_variants = [
                v for v in self.variants if v["product_id"] == product["product_id"]
            ]

            if product_variants:
                # Create inventory for each variant in each warehouse
                for variant in product_variants:
                    for warehouse in self.warehouses:
                        if random.random() > 0.2:  # 80% chance of stocking
                            self.inventory_id += 1
                            qty_available = random.randint(0, 500)
                            qty_reserved = random.randint(0, min(50, qty_available))

                            inventory = {
                                "inventory_id": self.inventory_id,
                                "product_id": product["product_id"],
                                "variant_id": variant["variant_id"],
                                "warehouse_id": warehouse["warehouse_id"],
                                "quantity_available": qty_available,
                                "quantity_reserved": qty_reserved,
                                "quantity_incoming": (
                                    random.randint(0, 100)
                                    if random.random() > 0.7
                                    else 0
                                ),
                                "reorder_point": random.randint(10, 50),
                                "reorder_quantity": random.randint(50, 200),
                                "last_restock_date": fake.date_between(
                                    start_date="-60d", end_date="today"
                                ),
                                "last_sale_date": (
                                    fake.date_between(
                                        start_date="-7d", end_date="today"
                                    )
                                    if qty_reserved > 0
                                    else None
                                ),
                                "last_counted_date": fake.date_between(
                                    start_date="-30d", end_date="today"
                                ),
                                "average_daily_sales": round(
                                    random.uniform(0.5, 10), 2
                                ),
                                "days_of_stock": round(
                                    qty_available / max(0.5, random.uniform(0.5, 10)), 2
                                ),
                                "created_at": warehouse["created_at"],
                                "updated_at": fake.date_time_between(
                                    start_date="-7d", end_date="now"
                                ),
                            }
                            self.inventory.append(inventory)

                            # Create initial stock movement
                            movement_id += 1
                            movement = {
                                "movement_id": movement_id,
                                "inventory_id": self.inventory_id,
                                "movement_type": "restock",
                                "quantity": qty_available + qty_reserved,
                                "reference_type": "initial_stock",
                                "reference_id": None,
                                "from_warehouse_id": None,
                                "to_warehouse_id": warehouse["warehouse_id"],
                                "unit_cost": variant["cost"],
                                "notes": "Initial inventory",
                                "performed_by": 1,
                                "created_at": inventory["created_at"],
                            }
                            inventory_movements.append(movement)
            else:
                # Create inventory for product without variants
                for warehouse in self.warehouses:
                    if random.random() > 0.2:  # 80% chance of stocking
                        self.inventory_id += 1
                        qty_available = random.randint(0, 500)
                        qty_reserved = random.randint(0, min(50, qty_available))

                        inventory = {
                            "inventory_id": self.inventory_id,
                            "product_id": product["product_id"],
                            "variant_id": None,
                            "warehouse_id": warehouse["warehouse_id"],
                            "quantity_available": qty_available,
                            "quantity_reserved": qty_reserved,
                            "quantity_incoming": (
                                random.randint(0, 100) if random.random() > 0.7 else 0
                            ),
                            "reorder_point": random.randint(10, 50),
                            "reorder_quantity": random.randint(50, 200),
                            "last_restock_date": fake.date_between(
                                start_date="-60d", end_date="today"
                            ),
                            "last_sale_date": (
                                fake.date_between(start_date="-7d", end_date="today")
                                if qty_reserved > 0
                                else None
                            ),
                            "last_counted_date": fake.date_between(
                                start_date="-30d", end_date="today"
                            ),
                            "average_daily_sales": round(random.uniform(0.5, 10), 2),
                            "days_of_stock": round(
                                qty_available / max(0.5, random.uniform(0.5, 10)), 2
                            ),
                            "created_at": warehouse["created_at"],
                            "updated_at": fake.date_time_between(
                                start_date="-7d", end_date="now"
                            ),
                        }
                        self.inventory.append(inventory)

                        # Create initial stock movement
                        movement_id += 1
                        movement = {
                            "movement_id": movement_id,
                            "inventory_id": self.inventory_id,
                            "movement_type": "restock",
                            "quantity": qty_available + qty_reserved,
                            "reference_type": "initial_stock",
                            "reference_id": None,
                            "from_warehouse_id": None,
                            "to_warehouse_id": warehouse["warehouse_id"],
                            "unit_cost": product["cost"],
                            "notes": "Initial inventory",
                            "performed_by": 1,
                            "created_at": inventory["created_at"],
                        }
                        inventory_movements.append(movement)

        # Save inventory movements
        self.save_to_csv("inventory_movements", inventory_movements)

    def generate_shopping_behavior(self):
        """Generate shopping cart, wishlist, and browsing behavior."""
        print("Generating shopping behavior...")

        # Shopping carts (active and abandoned)
        for customer in random.sample(self.customers, int(len(self.customers) * 0.3)):
            num_items = random.randint(1, 5)
            for _ in range(num_items):
                self.cart_id += 1
                product = random.choice(self.products)
                variant = random.choice(
                    [
                        v
                        for v in self.variants
                        if v["product_id"] == product["product_id"]
                    ]
                    or [None]
                )

                cart_item = {
                    "cart_item_id": self.cart_id,
                    "customer_id": customer["customer_id"],
                    "product_id": product["product_id"],
                    "variant_id": variant["variant_id"] if variant else None,
                    "quantity": random.randint(1, 3),
                    "price_at_time": (
                        variant["price"] if variant else product["base_price"]
                    ),
                    "discount_amount": 0,
                    "saved_for_later": random.random() > 0.9,
                    "added_at": fake.date_time_between(
                        start_date="-7d", end_date="now"
                    ),
                    "updated_at": fake.date_time_between(
                        start_date="-1d", end_date="now"
                    ),
                }
                self.cart_items.append(cart_item)

        # Wishlists
        for customer in random.sample(self.customers, int(len(self.customers) * 0.4)):
            num_items = random.randint(1, 10)
            for _ in range(num_items):
                self.wishlist_id += 1
                product = random.choice(self.products)

                wishlist_item = {
                    "wishlist_item_id": self.wishlist_id,
                    "customer_id": customer["customer_id"],
                    "product_id": product["product_id"],
                    "variant_id": None,
                    "priority": random.randint(0, 5),
                    "notes": fake.sentence() if random.random() > 0.8 else None,
                    "price_when_added": product["base_price"],
                    "notify_on_sale": random.random() > 0.3,
                    "notify_on_restock": random.random() > 0.5,
                    "added_at": fake.date_time_between(
                        start_date="-90d", end_date="now"
                    ),
                }
                self.wishlist.append(wishlist_item)

        # Recently viewed products
        recently_viewed = []
        view_id = 0
        for customer in random.sample(self.customers, int(len(self.customers) * 0.6)):
            num_views = random.randint(3, 20)
            for _ in range(num_views):
                view_id += 1
                product = random.choice(self.products)

                recent_view = {
                    "view_id": view_id,
                    "customer_id": customer["customer_id"],
                    "product_id": product["product_id"],
                    "viewed_at": fake.date_time_between(
                        start_date="-30d", end_date="now"
                    ),
                    "view_count": random.randint(1, 5),
                }
                recently_viewed.append(recent_view)

        self.save_to_csv("recently_viewed", recently_viewed)

    def generate_orders(self):
        """Generate orders with items, payments, and shipments."""
        print(
            f"Generating {CONFIG['orders_per_day']} orders per day for {CONFIG['days_of_history']} days..."
        )

        order_statuses = (
            ["delivered"] * 60
            + ["shipped"] * 15
            + ["processing"] * 10
            + ["confirmed"] * 10
            + ["pending"] * 3
            + ["cancelled"] * 2
        )
        payment_methods_data = []
        payment_transactions = []
        order_status_history = []
        shipping_methods = self.generate_shipping_methods()

        start_date = datetime.now() - timedelta(days=CONFIG["days_of_history"])

        for day in range(CONFIG["days_of_history"]):
            current_date = start_date + timedelta(days=day)
            daily_orders = random.randint(
                int(CONFIG["orders_per_day"] * 0.7), int(CONFIG["orders_per_day"] * 1.3)
            )

            for _ in range(daily_orders):
                self.order_id += 1
                customer = random.choice(self.customers)
                status = random.choice(order_statuses)

                # Create order
                order = {
                    "order_id": self.order_id,
                    "order_number": f"ORD{str(self.order_id).zfill(8)}",
                    "customer_id": customer["customer_id"],
                    "guest_email": None,
                    "status": status,
                    "payment_status": (
                        "paid"
                        if status in ["shipped", "delivered"]
                        else random.choice(["pending", "paid", "failed"])
                    ),
                    "subtotal": 0,  # Will be calculated
                    "tax_amount": 0,
                    "shipping_amount": round(random.uniform(5, 25), 2),
                    "discount_amount": (
                        round(random.uniform(0, 50), 2) if random.random() > 0.7 else 0
                    ),
                    "total_amount": 0,  # Will be calculated
                    "currency_code": customer["preferred_currency"],
                    "exchange_rate": 1.0,
                    "shipping_address_id": random.choice(
                        [
                            a["address_id"]
                            for a in self.addresses
                            if a["customer_id"] == customer["customer_id"]
                        ]
                    ),
                    "billing_address_id": random.choice(
                        [
                            a["address_id"]
                            for a in self.addresses
                            if a["customer_id"] == customer["customer_id"]
                        ]
                    ),
                    "shipping_method": random.choice(shipping_methods)["service_name"],
                    "tracking_number": (
                        fake.bothify(text="??########??")
                        if status in ["shipped", "delivered"]
                        else None
                    ),
                    "notes": fake.sentence() if random.random() > 0.9 else None,
                    "internal_notes": (
                        fake.sentence() if random.random() > 0.95 else None
                    ),
                    "ip_address": fake.ipv4(),
                    "user_agent": fake.user_agent(),
                    "referred_from": random.choice(
                        ["google", "facebook", "instagram", "email", "direct", None]
                    ),
                    "coupon_code": (
                        fake.bothify(text="????##") if random.random() > 0.8 else None
                    ),
                    "created_at": current_date,
                    "updated_at": current_date + timedelta(hours=random.randint(1, 24)),
                    "confirmed_at": (
                        current_date + timedelta(hours=random.randint(1, 4))
                        if status != "pending"
                        else None
                    ),
                    "shipped_at": (
                        current_date + timedelta(days=random.randint(1, 3))
                        if status in ["shipped", "delivered"]
                        else None
                    ),
                    "delivered_at": (
                        current_date + timedelta(days=random.randint(3, 7))
                        if status == "delivered"
                        else None
                    ),
                    "cancelled_at": (
                        current_date + timedelta(hours=random.randint(1, 48))
                        if status == "cancelled"
                        else None
                    ),
                }

                # Create order items
                num_items = random.randint(1, 5)
                order_subtotal = 0

                for _ in range(num_items):
                    self.order_item_id += 1
                    product = random.choice(self.products)
                    variant = random.choice(
                        [
                            v
                            for v in self.variants
                            if v["product_id"] == product["product_id"]
                        ]
                        or [None]
                    )
                    quantity = random.randint(1, 3)

                    unit_price = variant["price"] if variant else product["base_price"]
                    item_discount = (
                        round(unit_price * random.uniform(0, 0.2), 2)
                        if random.random() > 0.7
                        else 0
                    )
                    item_tax = round(
                        (unit_price - item_discount) * 0.08 * quantity, 2
                    )  # 8% tax
                    item_total = (unit_price - item_discount) * quantity + item_tax

                    order_item = {
                        "order_item_id": self.order_item_id,
                        "order_id": self.order_id,
                        "product_id": product["product_id"],
                        "variant_id": variant["variant_id"] if variant else None,
                        "product_name": product["product_name"],
                        "variant_name": variant["variant_name"] if variant else None,
                        "sku": variant["variant_sku"] if variant else product["sku"],
                        "quantity": quantity,
                        "unit_price": unit_price,
                        "discount_amount": item_discount,
                        "tax_amount": item_tax,
                        "total_price": item_total,
                        "cost": variant["cost"] if variant else product["cost"],
                        "weight_kg": product["weight_kg"],
                        "requires_shipping": product["requires_shipping"],
                        "is_gift": random.random() > 0.95,
                        "gift_message": (
                            fake.sentence() if random.random() > 0.98 else None
                        ),
                        "fulfillment_status": (
                            "fulfilled" if status == "delivered" else "unfulfilled"
                        ),
                        "fulfilled_quantity": quantity if status == "delivered" else 0,
                        "warehouse_id": random.choice(self.warehouses)["warehouse_id"],
                        "created_at": order["created_at"],
                    }
                    self.order_items.append(order_item)
                    order_subtotal += item_total - item_tax

                # Update order totals
                order["subtotal"] = round(order_subtotal, 2)
                order["tax_amount"] = round(order_subtotal * 0.08, 2)
                order["total_amount"] = round(
                    order["subtotal"]
                    + order["tax_amount"]
                    + order["shipping_amount"]
                    - order["discount_amount"],
                    2,
                )

                self.orders.append(order)

                # Update customer lifetime value
                customer["lifetime_value"] = float(
                    customer.get("lifetime_value", 0)
                ) + float(order["total_amount"])

                # Create payment method if doesn't exist
                if random.random() > 0.3:  # 70% use saved payment method
                    self.payment_id += 1
                    payment_type = random.choice(
                        ["credit_card", "debit_card", "paypal", "digital_wallet"]
                    )
                    payment_method = {
                        "payment_method_id": self.payment_id,
                        "customer_id": customer["customer_id"],
                        "type": payment_type,
                        "provider": random.choice(
                            ["stripe", "paypal", "square", "braintree"]
                        ),
                        "is_default": random.random() > 0.7,
                        "card_brand": (
                            random.choice(["visa", "mastercard", "amex", "discover"])
                            if "card" in payment_type
                            else None
                        ),
                        "card_last_four": str(random.randint(1000, 9999)),
                        "card_exp_month": random.randint(1, 12),
                        "card_exp_year": random.randint(2024, 2030),
                        "billing_address_id": order["billing_address_id"],
                        "token": fake.sha256(),
                        "fingerprint": fake.md5(),
                        "metadata": json.dumps({"customer_ip": fake.ipv4()}),
                        "created_at": order["created_at"],
                        "updated_at": order["updated_at"],
                    }
                    payment_methods_data.append(payment_method)

                # Create payment transaction
                self.transaction_id += 1
                transaction = {
                    "transaction_id": self.transaction_id,
                    "order_id": self.order_id,
                    "payment_method_id": (
                        random.randint(1, self.payment_id)
                        if self.payment_id > 0
                        else None
                    ),
                    "transaction_type": "charge",
                    "amount": order["total_amount"],
                    "currency_code": order["currency_code"],
                    "status": (
                        "succeeded"
                        if order["payment_status"] == "paid"
                        else order["payment_status"]
                    ),
                    "gateway": random.choice(["stripe", "paypal", "square"]),
                    "gateway_transaction_id": fake.uuid4(),
                    "gateway_response": json.dumps({"status": "ok", "code": "200"}),
                    "failure_reason": (
                        None
                        if order["payment_status"] == "paid"
                        else "Insufficient funds"
                    ),
                    "processed_at": order["created_at"]
                    + timedelta(minutes=random.randint(1, 10)),
                    "created_at": order["created_at"],
                }
                payment_transactions.append(transaction)

                # Create order status history
                statuses_sequence = [
                    "pending",
                    "processing",
                    "confirmed",
                    "shipped",
                    "delivered",
                ]
                current_status_index = (
                    statuses_sequence.index(status)
                    if status in statuses_sequence
                    else 0
                )

                for i, hist_status in enumerate(
                    statuses_sequence[: current_status_index + 1]
                ):
                    history_entry = {
                        "history_id": len(order_status_history) + 1,
                        "order_id": self.order_id,
                        "status": hist_status,
                        "notes": f"Order {hist_status}",
                        "changed_by": random.randint(1, 10),  # Admin user ID
                        "created_at": order["created_at"] + timedelta(hours=i * 24),
                    }
                    order_status_history.append(history_entry)

                # Create shipment for shipped/delivered orders
                if status in ["shipped", "delivered"]:
                    self.shipment_id += 1
                    shipment = {
                        "shipment_id": self.shipment_id,
                        "order_id": self.order_id,
                        "warehouse_id": random.choice(self.warehouses)["warehouse_id"],
                        "shipping_method_id": random.choice(shipping_methods)[
                            "shipping_method_id"
                        ],
                        "tracking_number": order["tracking_number"],
                        "carrier_name": random.choice(["UPS", "FedEx", "USPS", "DHL"]),
                        "status": (
                            "delivered" if status == "delivered" else "in_transit"
                        ),
                        "weight_kg": sum(
                            [
                                oi["weight_kg"] * oi["quantity"]
                                for oi in self.order_items
                                if oi["order_id"] == self.order_id
                            ]
                        ),
                        "dimensions_cm": json.dumps(
                            {"length": 30, "width": 20, "height": 15}
                        ),
                        "shipping_label_url": f"https://labels.example.com/{self.shipment_id}.pdf",
                        "shipped_at": order["shipped_at"],
                        "delivered_at": order["delivered_at"],
                        "delivery_signature": (
                            fake.name() if status == "delivered" else None
                        ),
                        "notes": None,
                        "created_at": order["created_at"],
                        "updated_at": order["updated_at"],
                    }
                    self.shipments.append(shipment)

        # Save payment related data
        self.save_to_csv("payment_methods", payment_methods_data)
        self.save_to_csv("payment_transactions", payment_transactions)
        self.save_to_csv("order_status_history", order_status_history)

    def generate_reviews(self):
        """Generate product reviews and ratings."""
        print("Generating product reviews...")

        review_votes = []
        vote_id = 0

        # Generate reviews for delivered orders
        delivered_orders = [o for o in self.orders if o["status"] == "delivered"]

        for order in random.sample(
            delivered_orders, int(len(delivered_orders) * CONFIG["review_rate"])
        ):
            order_items_list = [
                oi for oi in self.order_items if oi["order_id"] == order["order_id"]
            ]

            for item in order_items_list:
                if random.random() < 0.3:  # 30% chance to review each item
                    self.review_id += 1

                    rating = random.choices(
                        [5, 4, 3, 2, 1], weights=[40, 30, 15, 10, 5]
                    )[0]

                    review = {
                        "review_id": self.review_id,
                        "product_id": item["product_id"],
                        "variant_id": item["variant_id"],
                        "customer_id": order["customer_id"],
                        "order_item_id": item["order_item_id"],
                        "rating": rating,
                        "title": fake.sentence()[:100],
                        "review_text": fake.paragraph(
                            nb_sentences=random.randint(2, 5)
                        ),
                        "pros": fake.sentence() if random.random() > 0.5 else None,
                        "cons": fake.sentence() if rating <= 3 else None,
                        "is_verified_purchase": True,
                        "is_featured": random.random() > 0.95,
                        "helpful_count": random.randint(0, 100),
                        "unhelpful_count": random.randint(0, 20),
                        "admin_reply": (
                            fake.sentence() if random.random() > 0.9 else None
                        ),
                        "admin_reply_at": (
                            fake.date_time_between(
                                start_date=order["delivered_at"], end_date="now"
                            )
                            if random.random() > 0.9
                            else None
                        ),
                        "status": random.choice(
                            ["approved"] * 90
                            + ["pending"] * 5
                            + ["flagged"] * 3
                            + ["rejected"] * 2
                        ),
                        "images": json.dumps(
                            [
                                f"https://reviews.example.com/{self.review_id}_{i}.jpg"
                                for i in range(random.randint(0, 3))
                            ]
                        ),
                        "created_at": fake.date_time_between(
                            start_date=order["delivered_at"], end_date="now"
                        ),
                        "updated_at": fake.date_time_between(
                            start_date=order["delivered_at"], end_date="now"
                        ),
                    }
                    self.reviews.append(review)

                    # Generate votes for popular reviews
                    if review["helpful_count"] > 0:
                        num_votes = min(
                            review["helpful_count"] + review["unhelpful_count"], 50
                        )
                        voters = random.sample(
                            self.customers, min(num_votes, len(self.customers) // 10)
                        )

                        for voter in voters[: review["helpful_count"]]:
                            vote_id += 1
                            vote = {
                                "vote_id": vote_id,
                                "review_id": self.review_id,
                                "customer_id": voter["customer_id"],
                                "is_helpful": True,
                                "created_at": fake.date_time_between(
                                    start_date=review["created_at"], end_date="now"
                                ),
                            }
                            review_votes.append(vote)

        self.save_to_csv("review_votes", review_votes)

    def generate_support_and_returns(self):
        """Generate support tickets and returns."""
        print("Generating support tickets and returns...")

        return_items = []
        return_item_id = 0

        # Support tickets
        for order in random.sample(
            self.orders, int(len(self.orders) * CONFIG["support_ticket_rate"])
        ):
            self.ticket_id += 1

            ticket = {
                "ticket_id": self.ticket_id,
                "ticket_number": f"TKT{str(self.ticket_id).zfill(6)}",
                "customer_id": order["customer_id"],
                "order_id": order["order_id"],
                "category": random.choice(
                    [
                        "order",
                        "product",
                        "shipping",
                        "payment",
                        "return",
                        "technical",
                        "other",
                    ]
                ),
                "priority": random.choice(["low", "medium", "high", "urgent"]),
                "status": random.choice(
                    ["resolved"] * 60
                    + ["closed"] * 20
                    + ["open"] * 10
                    + ["in_progress"] * 10
                ),
                "subject": fake.sentence()[:100],
                "description": fake.paragraph(),
                "resolution": fake.paragraph() if random.random() > 0.3 else None,
                "assigned_to": random.randint(1, 10),
                "resolved_at": (
                    fake.date_time_between(
                        start_date=order["created_at"], end_date="now"
                    )
                    if random.random() > 0.3
                    else None
                ),
                "satisfaction_rating": (
                    random.randint(1, 5) if random.random() > 0.4 else None
                ),
                "created_at": fake.date_time_between(
                    start_date=order["created_at"], end_date="now"
                ),
                "updated_at": fake.date_time_between(
                    start_date=order["created_at"], end_date="now"
                ),
            }
            self.support_tickets.append(ticket)

        # Returns
        delivered_orders = [o for o in self.orders if o["status"] == "delivered"]
        for order in random.sample(
            delivered_orders, int(len(delivered_orders) * CONFIG["return_rate"])
        ):
            self.return_id += 1

            return_status = random.choice(
                ["completed"] * 50
                + ["processing"] * 20
                + ["approved"] * 15
                + ["requested"] * 10
                + ["rejected"] * 5
            )

            return_data = {
                "return_id": self.return_id,
                "return_number": f"RET{str(self.return_id).zfill(6)}",
                "order_id": order["order_id"],
                "customer_id": order["customer_id"],
                "status": return_status,
                "reason": random.choice(
                    [
                        "defective",
                        "wrong_item",
                        "not_as_described",
                        "no_longer_needed",
                        "damaged",
                        "other",
                    ]
                ),
                "reason_details": fake.paragraph(),
                "return_shipping_method": random.choice(
                    ["Prepaid Label", "Customer Ships", "Store Dropoff"]
                ),
                "return_tracking_number": (
                    fake.bothify(text="RET########")
                    if return_status != "requested"
                    else None
                ),
                "refund_amount": round(
                    order["total_amount"] * random.uniform(0.5, 1.0), 2
                ),
                "restocking_fee": (
                    round(order["total_amount"] * 0.1, 2)
                    if random.random() > 0.8
                    else 0
                ),
                "return_label_url": f"https://returns.example.com/label_{self.return_id}.pdf",
                "received_condition": (
                    random.choice(["new", "like_new", "good", "fair", "poor"])
                    if return_status in ["processing", "completed"]
                    else None
                ),
                "inspection_notes": (
                    fake.sentence()
                    if return_status in ["processing", "completed"]
                    else None
                ),
                "requested_at": fake.date_time_between(
                    start_date=order["delivered_at"], end_date="now"
                ),
                "approved_at": (
                    fake.date_time_between(
                        start_date=order["delivered_at"], end_date="now"
                    )
                    if return_status != "requested"
                    else None
                ),
                "received_at": (
                    fake.date_time_between(
                        start_date=order["delivered_at"], end_date="now"
                    )
                    if return_status in ["processing", "completed"]
                    else None
                ),
                "refunded_at": (
                    fake.date_time_between(
                        start_date=order["delivered_at"], end_date="now"
                    )
                    if return_status == "completed"
                    else None
                ),
            }
            self.returns.append(return_data)

            # Add return items
            items_to_return = random.sample(
                [oi for oi in self.order_items if oi["order_id"] == order["order_id"]],
                random.randint(
                    1,
                    min(
                        3,
                        len(
                            [
                                oi
                                for oi in self.order_items
                                if oi["order_id"] == order["order_id"]
                            ]
                        ),
                    ),
                ),
            )

            for item in items_to_return:
                return_item_id += 1
                return_item = {
                    "return_item_id": return_item_id,
                    "return_id": self.return_id,
                    "order_item_id": item["order_item_id"],
                    "quantity": min(
                        item["quantity"], random.randint(1, item["quantity"])
                    ),
                    "condition": random.choice(
                        ["unopened", "opened", "used", "damaged", "defective"]
                    ),
                    "refund_amount": round(
                        item["total_price"] * random.uniform(0.5, 1.0), 2
                    ),
                    "replacement_sent": random.random() > 0.8,
                    "notes": fake.sentence() if random.random() > 0.7 else None,
                    "created_at": return_data["requested_at"],
                }
                return_items.append(return_item)

        self.save_to_csv("return_items", return_items)

    def generate_promotions(self):
        """Generate coupons and price rules."""
        print("Generating promotions...")

        coupon_usage = []
        usage_id = 0

        # Generate coupons
        for i in range(50):
            coupon = {
                "coupon_id": i + 1,
                "code": fake.bothify(text="????##").upper(),
                "description": fake.sentence(),
                "discount_type": random.choice(
                    ["percentage", "fixed_amount", "free_shipping"]
                ),
                "discount_value": random.choice([5, 10, 15, 20, 25, 50]),
                "minimum_amount": random.choice([0, 50, 100, 200]),
                "maximum_discount": random.choice([None, 50, 100, 200]),
                "applicable_to": random.choice(
                    ["all", "specific_categories", "specific_products"]
                ),
                "applicable_ids": (
                    json.dumps(
                        [random.randint(1, 100) for _ in range(random.randint(1, 5))]
                    )
                    if random.random() > 0.5
                    else None
                ),
                "usage_limit": random.choice([None, 100, 500, 1000]),
                "usage_limit_per_customer": random.choice([1, 3, 5, None]),
                "usage_count": 0,
                "valid_from": fake.date_time_between(start_date="-6m", end_date="now"),
                "valid_to": fake.date_time_between(start_date="now", end_date="+6m"),
                "is_active": random.random() > 0.2,
                "requires_account": random.random() > 0.5,
                "stackable": random.random() > 0.8,
                "created_at": fake.date_time_between(start_date="-1y", end_date="now"),
                "updated_at": fake.date_time_between(start_date="-30d", end_date="now"),
            }
            self.coupons.append(coupon)

            # Track coupon usage
            if coupon["is_active"]:
                orders_with_coupon = random.sample(
                    self.orders, min(random.randint(0, 50), len(self.orders))
                )
                for order in orders_with_coupon:
                    usage_id += 1
                    usage = {
                        "usage_id": usage_id,
                        "coupon_id": i + 1,
                        "customer_id": order["customer_id"],
                        "order_id": order["order_id"],
                        "discount_amount": order["discount_amount"],
                        "used_at": order["created_at"],
                    }
                    coupon_usage.append(usage)
                    coupon["usage_count"] += 1

        # Generate price rules
        price_rules = []
        for i in range(30):
            rule = {
                "rule_id": i + 1,
                "rule_name": fake.catch_phrase(),
                "rule_type": random.choice(["sale", "bulk", "bundle", "flash"]),
                "priority": random.randint(1, 10),
                "conditions": json.dumps({"min_quantity": random.randint(2, 10)}),
                "discount_type": random.choice(["percentage", "fixed_amount"]),
                "discount_value": random.choice([5, 10, 15, 20, 30]),
                "applicable_to": random.choice(
                    ["all", "specific_categories", "specific_products"]
                ),
                "applicable_ids": json.dumps(
                    [random.randint(1, 100) for _ in range(random.randint(1, 10))]
                ),
                "valid_from": fake.date_time_between(start_date="-3m", end_date="now"),
                "valid_to": fake.date_time_between(start_date="now", end_date="+3m"),
                "is_active": random.random() > 0.3,
                "created_at": fake.date_time_between(start_date="-6m", end_date="now"),
                "updated_at": fake.date_time_between(start_date="-7d", end_date="now"),
            }
            price_rules.append(rule)

        self.save_to_csv("price_rules", price_rules)
        self.save_to_csv("coupon_usage", coupon_usage)

    def generate_analytics(self):
        """Generate analytics data (page views, searches, recommendations)."""
        print("Generating analytics data...")

        # Page views
        for _ in range(50000):  # Generate substantial page view data
            self.view_id += 1

            customer = random.choice(
                self.customers + [None] * int(len(self.customers) * 0.3)
            )  # 30% anonymous
            product = random.choice(
                self.products + [None] * int(len(self.products) * 0.2)
            )  # 20% non-product pages

            page_view = {
                "view_id": self.view_id,
                "customer_id": customer["customer_id"] if customer else None,
                "session_id": fake.uuid4()[:128],
                "product_id": product["product_id"] if product else None,
                "page_type": random.choice(
                    ["product", "category", "search", "home", "checkout", "account"]
                ),
                "page_url": (
                    f"/products/{product['slug']}" if product else f"/{fake.slug()}"
                ),
                "referrer_url": random.choice(
                    [
                        "https://google.com",
                        "https://facebook.com",
                        None,
                        "/home",
                        "/search",
                    ]
                ),
                "ip_address": fake.ipv4(),
                "user_agent": fake.user_agent()[:500],
                "device_type": random.choice(["desktop", "mobile", "tablet"]),
                "duration_seconds": random.randint(5, 600),
                "bounce": random.random() > 0.7,
                "created_at": fake.date_time_between(start_date="-90d", end_date="now"),
            }
            self.page_views.append(page_view)

        # Search queries
        search_terms = [
            "laptop",
            "shoes",
            "phone",
            "dress",
            "watch",
            "headphones",
            "camera",
            "tablet",
            "gaming",
            "kitchen",
        ]
        for _ in range(10000):
            self.search_id += 1

            customer = random.choice(
                self.customers + [None] * int(len(self.customers) * 0.4)
            )

            search_query = {
                "search_id": self.search_id,
                "customer_id": customer["customer_id"] if customer else None,
                "session_id": fake.uuid4()[:128],
                "query_text": " ".join(
                    random.sample(search_terms, random.randint(1, 3))
                ),
                "results_count": random.randint(0, 200),
                "clicked_position": random.choice([None, 1, 2, 3, 4, 5]),
                "clicked_product_id": (
                    random.choice(self.products)["product_id"]
                    if random.random() > 0.5
                    else None
                ),
                "device_type": random.choice(["desktop", "mobile", "tablet"]),
                "created_at": fake.date_time_between(start_date="-90d", end_date="now"),
            }
            self.search_queries.append(search_query)

        # Product recommendations
        recommendations = []
        rec_id = 0
        for customer in random.sample(self.customers, int(len(self.customers) * 0.5)):
            num_recs = random.randint(5, 20)
            for _ in range(num_recs):
                rec_id += 1
                product = random.choice(self.products)

                recommendation = {
                    "recommendation_id": rec_id,
                    "customer_id": customer["customer_id"],
                    "product_id": product["product_id"],
                    "recommendation_type": random.choice(
                        [
                            "also_bought",
                            "viewed_together",
                            "personalized",
                            "trending",
                            "similar",
                        ]
                    ),
                    "score": round(random.uniform(0.5, 1.0), 4),
                    "reason": f"Based on your interest in {random.choice(['Electronics', 'Fashion', 'Home', 'Sports'])}",
                    "expires_at": fake.date_time_between(
                        start_date="now", end_date="+30d"
                    ),
                    "created_at": fake.date_time_between(
                        start_date="-7d", end_date="now"
                    ),
                }
                recommendations.append(recommendation)

        self.save_to_csv("product_recommendations", recommendations)

    def generate_shipping_methods(self):
        """Generate available shipping methods."""
        methods = []
        shipping_options = [
            ("Standard Ground", "USPS", "standard", 5, 7, 5.99),
            ("Express Shipping", "FedEx", "express", 2, 3, 15.99),
            ("Overnight", "UPS", "overnight", 1, 1, 29.99),
            ("Economy", "USPS", "economy", 7, 10, 3.99),
            ("Prime 2-Day", "Amazon", "prime", 2, 2, 0),
        ]

        for i, (service, carrier, code, min_days, max_days, base_rate) in enumerate(
            shipping_options
        ):
            method = {
                "shipping_method_id": i + 1,
                "carrier_name": carrier,
                "service_name": service,
                "code": code,
                "delivery_days_min": min_days,
                "delivery_days_max": max_days,
                "base_rate": base_rate,
                "per_kg_rate": round(base_rate * 0.1, 2),
                "per_item_rate": round(base_rate * 0.05, 2),
                "free_shipping_threshold": 100 if code != "prime" else 0,
                "max_weight_kg": 50,
                "countries": json.dumps(["US", "CA", "MX"]),
                "is_express": code in ["express", "overnight", "prime"],
                "is_active": True,
                "created_at": fake.date_time_between(start_date="-2y", end_date="-1y"),
                "updated_at": fake.date_time_between(start_date="-30d", end_date="now"),
            }
            methods.append(method)

        self.save_to_csv("shipping_methods", methods)
        return methods

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
            ("customers", self.customers),
            ("customer_addresses", self.addresses),
            ("categories", self.categories),
            ("brands", self.brands),
            ("products", self.products),
            ("product_variants", self.variants),
            ("product_images", self.images),
            ("warehouses", self.warehouses),
            ("inventory", self.inventory),
            ("cart_items", self.cart_items),
            ("wishlist_items", self.wishlist),
            ("orders", self.orders),
            ("order_items", self.order_items),
            ("product_reviews", self.reviews),
            ("coupons", self.coupons),
            ("page_views", self.page_views),
            ("search_queries", self.search_queries),
            ("support_tickets", self.support_tickets),
            ("returns", self.returns),
            ("shipments", self.shipments),
        ]

        for table_name, data in tables:
            if data:
                self.save_to_csv(table_name, data)
                print(f"  [OK] {table_name}: {len(data):,} records")

        # Generate summary statistics
        self.generate_summary()

    def generate_summary(self):
        """Generate summary statistics."""
        summary = f"""
E-commerce Data Generation Summary
==================================
Customers: {len(self.customers):,}
Products: {len(self.products):,}
Product Variants: {len(self.variants):,}
Categories: {len(self.categories):,}
Brands: {len(self.brands):,}

Orders: {len(self.orders):,}
Order Items: {len(self.order_items):,}
Total Revenue: ${sum(o['total_amount'] for o in self.orders):,.2f}
Average Order Value: ${sum(o['total_amount'] for o in self.orders) / len(self.orders):.2f}

Reviews: {len(self.reviews):,}
Support Tickets: {len(self.support_tickets):,}
Returns: {len(self.returns):,}

Cart Items: {len(self.cart_items):,}
Wishlist Items: {len(self.wishlist):,}
Page Views: {len(self.page_views):,}
Search Queries: {len(self.search_queries):,}

Files Generated: {len(list(OUTPUT_DIR.glob('*.csv')))}
Total Records: {sum(len(data) for _, data in [(t, getattr(self, t.replace('_', ''), [])) for t in ['customers', 'products', 'orders', 'reviews']]):,}
"""

        print(summary)

        # Save summary to file
        with open(OUTPUT_DIR / "generation_summary.txt", "w") as f:
            f.write(summary)


if __name__ == "__main__":
    generator = EcommerceGenerator()
    generator.generate_all()
    print("\n[SUCCESS] E-commerce data generation complete!")
