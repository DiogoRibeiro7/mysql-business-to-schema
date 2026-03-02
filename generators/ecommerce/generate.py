#!/usr/bin/env python3
"""
E-commerce Platform Data Generator

Generates realistic e-commerce data including:
- Users and customer segments
- Products, categories, and inventory
- Orders and order items
- Shopping carts
- Reviews and ratings
- Payment transactions
- Shipping and returns
"""

import csv
import random
import yaml
import argparse
from datetime import datetime, timedelta
from pathlib import Path
from typing import List, Dict, Tuple, Any
import hashlib
import uuid
from faker import Faker


class EcommerceGenerator:
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
        self.users: List[Any] = []
        self.addresses: List[Any] = []
        self.categories: List[Any] = []
        self.brands: List[Any] = []
        self.products: List[Any] = []
        self.warehouses: List[Any] = []
        self.suppliers: List[Any] = []
        self.inventory: List[Any] = []
        self.orders: List[Any] = []
        self.order_items: List[Any] = []
        self.payments: List[Any] = []
        self.shipments: List[Any] = []
        self.carts: List[Any] = []
        self.cart_items: List[Any] = []
        self.reviews: List[Any] = []
        self.wishlists: List[Any] = []
        self.coupons: List[Any] = []
        self.promotions: List[Any] = []

        # Tracking
        self.order_id_counter = 1
        self.payment_id_counter = 1
        self.shipment_id_counter = 1
        self.review_id_counter = 1
        self.cart_id_counter = 1

    def generate_all(self):
        """Generate all data in sequence"""
        print("Generating E-commerce data...")

        # Master data
        self._generate_categories()
        self._generate_brands()
        self._generate_suppliers()
        self._generate_warehouses()
        self._generate_users()
        self._generate_products()
        self._generate_inventory()
        self._generate_promotions()
        self._generate_coupons()

        # Transactional data
        self._generate_orders()
        self._generate_carts()
        self._generate_reviews()
        self._generate_wishlists()

        # Write to CSV
        self._write_all_csvs()

        # Generate SQL scripts
        self._generate_sql_scripts()

        print(
            f"[OK] Generated data for {len(self.users)} users, "
            f"{len(self.products)} products, {len(self.orders)} orders"
        )
        print(f"[OK] Output written to {self.output_dir}")

    def _generate_categories(self):
        """Generate product categories with hierarchy"""
        category_id = 1

        # Main categories from config
        main_categories = list(self.config["product_categories"].keys())

        for main_cat in main_categories:
            # Create main category
            main_category = {
                "category_id": category_id,
                "category_name": main_cat.replace("_", " ").title(),
                "parent_category_id": None,
                "category_path": main_cat,
                "is_active": True,
                "sort_order": category_id,
            }
            self.categories.append(main_category)
            parent_id = category_id
            category_id += 1

            # Create subcategories
            subcategories = self._get_subcategories(main_cat)
            for subcat in subcategories:
                sub_category = {
                    "category_id": category_id,
                    "category_name": subcat,
                    "parent_category_id": parent_id,
                    "category_path": f"{main_cat}/{subcat.lower().replace(' ', '_')}",
                    "is_active": True,
                    "sort_order": category_id,
                }
                self.categories.append(sub_category)
                category_id += 1

    def _get_subcategories(self, main_category: str) -> List[str]:
        """Get subcategories for a main category"""
        subcategories = {
            "electronics": [
                "Smartphones",
                "Laptops",
                "Tablets",
                "Headphones",
                "Cameras",
                "Gaming",
            ],
            "clothing": [
                "Men's Clothing",
                "Women's Clothing",
                "Shoes",
                "Accessories",
                "Kids",
            ],
            "home_garden": ["Furniture", "Kitchen", "Bedding", "Garden Tools", "Decor"],
            "books": ["Fiction", "Non-Fiction", "Educational", "Comics", "E-books"],
            "sports": [
                "Exercise Equipment",
                "Outdoor Gear",
                "Team Sports",
                "Fitness Accessories",
            ],
            "beauty": ["Skincare", "Makeup", "Hair Care", "Fragrances", "Tools"],
            "toys": [
                "Action Figures",
                "Board Games",
                "Educational Toys",
                "Outdoor Toys",
            ],
            "food": ["Snacks", "Beverages", "Organic", "International", "Gourmet"],
        }
        return subcategories.get(main_category, ["General"])

    def _generate_brands(self):
        """Generate product brands"""
        brand_names = [
            "TechPro",
            "StyleMax",
            "HomeComfort",
            "BookWorld",
            "SportZone",
            "BeautyLux",
            "ToyLand",
            "GourmetDelight",
            "EcoFriend",
            "ValueBest",
            "PremiumChoice",
            "QuickShip",
            "GlobalTrade",
            "LocalCraft",
            "Innovation",
        ]

        for i in range(self.config["counts"]["brands"]):
            brand = {
                "brand_id": i + 1,
                "brand_name": (
                    f"{random.choice(brand_names)} {chr(65 + (i % 26))}"
                    if i >= len(brand_names)
                    else brand_names[i % len(brand_names)]
                ),
                "brand_description": self.fake.catch_phrase(),
                "website": f"www.{brand_names[i % len(brand_names)].lower()}.com",
                "country": self.fake.country(),
                "established_year": random.randint(1950, 2020),
                "is_active": random.random() > 0.05,  # 95% active
            }
            self.brands.append(brand)

    def _generate_suppliers(self):
        """Generate suppliers"""
        for i in range(self.config["counts"]["suppliers"]):
            supplier = {
                "supplier_id": i + 1,
                "supplier_name": self.fake.company(),
                "contact_name": self.fake.name(),
                "email": self.fake.company_email(),
                "phone": self.fake.phone_number()[:20],
                "address": self.fake.street_address(),
                "city": self.fake.city(),
                "state": self.fake.state_abbr(),
                "country": self.fake.country(),
                "rating": round(random.uniform(3.0, 5.0), 1),
                "is_active": random.random() > 0.1,  # 90% active
            }
            self.suppliers.append(supplier)

    def _generate_warehouses(self):
        """Generate warehouse locations"""
        warehouse_cities = [
            ("New York", "NY", "northeast"),
            ("Los Angeles", "CA", "west"),
            ("Chicago", "IL", "midwest"),
            ("Houston", "TX", "southwest"),
            ("Atlanta", "GA", "southeast"),
        ]

        for i in range(self.config["counts"]["warehouses"]):
            city, state, region = warehouse_cities[i % len(warehouse_cities)]
            warehouse = {
                "warehouse_id": i + 1,
                "warehouse_code": f"WH{state}{i+1:03d}",
                "warehouse_name": f"{city} Distribution Center",
                "address": self.fake.street_address(),
                "city": city,
                "state": state,
                "zip_code": self.fake.zipcode(),
                "region": region,
                "capacity_units": random.randint(10000, 100000),
                "current_occupancy": random.uniform(0.3, 0.9),
                "is_active": True,
            }
            self.warehouses.append(warehouse)

    def _generate_users(self):
        """Generate user accounts"""
        user_id = 1

        for _ in range(self.config["counts"]["users"]):
            # Determine customer segment
            segment = random.choices(
                list(self.config["user_distribution"]["segments"].keys()),
                weights=list(self.config["user_distribution"]["segments"].values()),
            )[0]

            # Determine region
            region = random.choices(
                list(self.config["user_distribution"]["regions"].keys()),
                weights=list(self.config["user_distribution"]["regions"].values()),
            )[0]

            # Generate user data
            email = self.fake.email()
            created_date = self.fake.date_between(
                start_date=datetime.strptime(
                    self.config["date_ranges"]["business_start"], "%Y-%m-%d"
                ),
                end_date=datetime.strptime(
                    self.config["date_ranges"]["data_end"], "%Y-%m-%d"
                ),
            )

            user = {
                "user_id": user_id,
                "email": email,
                "username": email.split("@")[0] + str(random.randint(10, 99)),
                "first_name": self.fake.first_name(),
                "last_name": self.fake.last_name(),
                "password_hash": hashlib.md5(f"password{user_id}".encode()).hexdigest(),
                "phone": self.fake.phone_number()[:20],
                "date_of_birth": self.fake.date_of_birth(
                    minimum_age=18, maximum_age=80
                ),
                "gender": random.choice(["M", "F", "Other", None]),
                "customer_segment": segment,
                "region": region,
                "created_at": created_date,
                "last_login": self.fake.date_between(
                    start_date=created_date, end_date="now"
                ),
                "is_active": random.random() > 0.05,  # 95% active
                "email_verified": random.random() > 0.1,  # 90% verified
                "loyalty_points": (
                    random.randint(0, 5000)
                    if segment == "premium"
                    else random.randint(0, 1000)
                ),
            }
            self.users.append(user)

            # Generate addresses for user
            num_addresses = random.choices([1, 2, 3], weights=[0.7, 0.2, 0.1])[0]
            for addr_idx in range(num_addresses):
                address = {
                    "address_id": len(self.addresses) + 1,
                    "user_id": user_id,
                    "address_type": "primary" if addr_idx == 0 else "secondary",
                    "street": self.fake.street_address(),
                    "city": self.fake.city(),
                    "state": self.fake.state_abbr(),
                    "zip_code": self.fake.zipcode(),
                    "country": "USA",
                    "is_default": addr_idx == 0,
                }
                self.addresses.append(address)

            user_id += 1

    def _generate_products(self):
        """Generate products"""
        product_id = 1

        for _ in range(self.config["counts"]["products"]):
            # Select category (with subcategory)
            category = random.choice(
                [c for c in self.categories if c["parent_category_id"] is not None]
            )
            main_category_name = (
                next(
                    c["category_name"]
                    for c in self.categories
                    if c["category_id"] == category["parent_category_id"]
                )
                .lower()
                .replace(" ", "_")
            )

            # Select brand and supplier
            brand = random.choice(self.brands)
            supplier = random.choice(self.suppliers)

            # Generate price based on category
            price_range = self.config["price_ranges"].get(
                main_category_name, [9.99, 99.99]
            )
            price = round(random.uniform(price_range[0], price_range[1]), 2)

            # Generate product data
            product = {
                "product_id": product_id,
                "sku": f"SKU{product_id:06d}",
                "product_name": self._generate_product_name(
                    category["category_name"], brand["brand_name"]
                ),
                "description": self.fake.text(max_nb_chars=200),
                "category_id": category["category_id"],
                "brand_id": brand["brand_id"],
                "supplier_id": supplier["supplier_id"],
                "unit_price": price,
                "cost": round(price * random.uniform(0.3, 0.6), 2),  # 30-60% of price
                "weight": round(random.uniform(0.1, 10.0), 2),
                "dimensions": f"{random.randint(5,50)}x{random.randint(5,50)}x{random.randint(5,50)}",
                "is_active": random.random() > 0.1,  # 90% active
                "created_date": self.fake.date_between(
                    start_date="-2years", end_date="today"
                ),
                "average_rating": (
                    round(random.uniform(3.0, 5.0), 1)
                    if random.random() > 0.3
                    else None
                ),
                "review_count": 0,  # Will update later
            }
            self.products.append(product)
            product_id += 1

    def _generate_product_name(self, category: str, brand: str) -> str:
        """Generate realistic product name"""
        adjectives = [
            "Premium",
            "Professional",
            "Ultimate",
            "Essential",
            "Classic",
            "Modern",
            "Smart",
        ]
        product_types = {
            "Smartphones": ["Phone", "Mobile", "Device"],
            "Laptops": ["Laptop", "Notebook", "Computer"],
            "Tablets": ["Tablet", "Pad", "Device"],
            "Men's Clothing": ["Shirt", "Pants", "Jacket", "Sweater"],
            "Women's Clothing": ["Dress", "Blouse", "Skirt", "Coat"],
            "Furniture": ["Chair", "Table", "Sofa", "Desk"],
            "Kitchen": ["Blender", "Mixer", "Pan", "Knife Set"],
        }

        product_type = random.choice(product_types.get(category, ["Item", "Product"]))
        adjective = random.choice(adjectives)

        return f"{brand} {adjective} {product_type}"

    def _generate_inventory(self):
        """Generate inventory records for products in warehouses"""
        for product in self.products:
            # Determine distribution strategy
            strategy = random.choices(
                list(self.config["inventory"]["distribution_strategies"].keys()),
                weights=list(
                    self.config["inventory"]["distribution_strategies"].values()
                ),
            )[0]

            total_stock = random.randint(
                self.config["inventory"]["stock_min"],
                self.config["inventory"]["stock_max"],
            )

            if strategy == "centralized":
                # All stock in one warehouse
                warehouse = random.choice(self.warehouses)
                inventory = {
                    "inventory_id": len(self.inventory) + 1,
                    "product_id": product["product_id"],
                    "warehouse_id": warehouse["warehouse_id"],
                    "quantity_on_hand": total_stock,
                    "quantity_reserved": random.randint(0, min(50, total_stock)),
                    "reorder_point": int(
                        total_stock
                        * self.config["inventory"]["reorder_point_percentage"]
                    ),
                    "reorder_quantity": random.randint(100, 500),
                    "last_restock_date": self.fake.date_between(
                        start_date="-30days", end_date="today"
                    ),
                    "location_in_warehouse": f"{random.choice(['A','B','C'])}{random.randint(1,99):02d}",
                }
                self.inventory.append(inventory)
            else:
                # Distribute across warehouses
                warehouses_to_use = (
                    self.warehouses
                    if strategy == "distributed"
                    else random.sample(self.warehouses, 3)
                )
                stock_per_warehouse = total_stock // len(warehouses_to_use)

                for warehouse in warehouses_to_use:
                    if stock_per_warehouse > 0:
                        inventory = {
                            "inventory_id": len(self.inventory) + 1,
                            "product_id": product["product_id"],
                            "warehouse_id": warehouse["warehouse_id"],
                            "quantity_on_hand": stock_per_warehouse
                            + random.randint(-10, 10),
                            "quantity_reserved": random.randint(
                                0, min(20, stock_per_warehouse)
                            ),
                            "reorder_point": int(
                                stock_per_warehouse
                                * self.config["inventory"]["reorder_point_percentage"]
                            ),
                            "reorder_quantity": random.randint(50, 200),
                            "last_restock_date": self.fake.date_between(
                                start_date="-30days", end_date="today"
                            ),
                            "location_in_warehouse": f"{random.choice(['A','B','C'])}{random.randint(1,99):02d}",
                        }
                        self.inventory.append(inventory)

    def _generate_promotions(self):
        """Generate promotional campaigns"""
        for campaign in self.config["promotional_campaigns"]["campaigns"]:
            promotion = {
                "promotion_id": len(self.promotions) + 1,
                "promotion_name": campaign["name"],
                "promotion_type": "percentage",
                "discount_value": campaign["discount"],
                "start_date": campaign["start"],
                "end_date": campaign["end"],
                "minimum_purchase": random.choice([0, 25, 50, 100]),
                "usage_limit": random.choice([None, 1000, 5000]),
                "is_active": True,
            }
            self.promotions.append(promotion)

    def _generate_coupons(self):
        """Generate discount coupons"""
        coupon_prefixes = ["SAVE", "DEAL", "DISCOUNT", "OFFER", "SPECIAL"]

        for i in range(50):  # Generate 50 coupons
            coupon = {
                "coupon_id": i + 1,
                "coupon_code": f"{random.choice(coupon_prefixes)}{random.randint(10,99)}",
                "discount_type": random.choice(["percentage", "fixed"]),
                "discount_value": (
                    random.choice([5, 10, 15, 20, 25])
                    if random.random() > 0.5
                    else random.choice([5, 10, 15, 20])
                ),
                "valid_from": self.fake.date_between(
                    start_date="-60days", end_date="today"
                ),
                "valid_to": self.fake.date_between(
                    start_date="today", end_date="+30days"
                ),
                "usage_limit": random.choice([1, 5, 10, None]),
                "times_used": 0,
                "minimum_purchase": random.choice([0, 25, 50, 75, 100]),
                "is_active": random.random() > 0.2,  # 80% active
            }
            self.coupons.append(coupon)

    def _generate_orders(self):
        """Generate orders and related data"""
        print("  Generating orders...")

        start_date = datetime.strptime(
            self.config["date_ranges"]["data_start"], "%Y-%m-%d"
        )
        end_date = datetime.strptime(self.config["date_ranges"]["data_end"], "%Y-%m-%d")

        for _ in range(self.config["counts"]["orders"]):
            # Select user and their address
            user = random.choice(self.users)
            user_addresses = [
                a for a in self.addresses if a["user_id"] == user["user_id"]
            ]
            if not user_addresses:
                continue

            shipping_address = random.choice(user_addresses)
            billing_address = (
                shipping_address
                if random.random() > 0.2
                else random.choice(user_addresses)
            )

            # Generate order date
            order_date = self.fake.date_time_between(
                start_date=start_date, end_date=end_date
            )

            # Apply seasonal and daily patterns
            month = order_date.month
            day_of_week = order_date.strftime("%A").lower()

            seasonal_mult = self.config["order_patterns"]["seasonal"].get(
                order_date.strftime("%B").lower(), 1.0
            )
            daily_mult = self.config["order_patterns"]["weekday"].get(day_of_week, 1.0)

            # Skip this order randomly based on patterns
            if random.random() > (seasonal_mult * daily_mult) / 2:
                continue

            # Determine order status
            status_flow = self.config["order_status_flow"]
            if random.random() < status_flow.get("cancelled", 0):
                status = "cancelled"
            elif random.random() < status_flow.get("returned", 0):
                status = "returned"
            elif order_date > datetime.now() - timedelta(days=1):
                status = "pending"
            elif order_date > datetime.now() - timedelta(days=3):
                status = "processing"
            elif order_date > datetime.now() - timedelta(days=5):
                status = "shipped"
            elif order_date > datetime.now() - timedelta(days=7):
                status = "delivered"
            else:
                status = "completed"

            # Select payment method
            payment_method = random.choices(
                list(self.config["payment_methods"].keys()),
                weights=list(self.config["payment_methods"].values()),
            )[0]

            # Select shipping option
            shipping_option = random.choices(
                list(self.config["shipping_options"].keys()),
                weights=list(self.config["shipping_options"].values()),
            )[0]

            # Calculate shipping cost
            shipping_costs = {
                "standard": 5.99,
                "express": 12.99,
                "overnight": 29.99,
                "free": 0,
            }
            shipping_cost = shipping_costs.get(shipping_option, 5.99)

            # Check for coupon usage
            coupon_code = None
            discount_amount = 0
            if (
                random.random()
                < self.config["promotional_campaigns"]["coupon_usage_rate"]
            ):
                coupon = random.choice(self.coupons)
                if coupon["is_active"]:
                    coupon_code = coupon["coupon_code"]
                    coupon["times_used"] += 1

            # Create order
            order = {
                "order_id": self.order_id_counter,
                "order_number": f"ORD{self.order_id_counter:08d}",
                "user_id": user["user_id"],
                "order_date": order_date,
                "status": status,
                "payment_method": payment_method,
                "shipping_address_id": shipping_address["address_id"],
                "billing_address_id": billing_address["address_id"],
                "shipping_method": shipping_option,
                "shipping_cost": shipping_cost,
                "subtotal": 0,  # Will calculate after items
                "tax_amount": 0,  # Will calculate
                "discount_amount": discount_amount,
                "total_amount": 0,  # Will calculate
                "coupon_code": coupon_code,
                "notes": self.fake.sentence() if random.random() < 0.1 else None,
            }

            # Generate order items
            num_items = random.randint(
                self.config["order_patterns"]["items_per_order"]["min"],
                self.config["order_patterns"]["items_per_order"]["max"],
            )

            selected_products = random.sample(
                self.products, min(num_items, len(self.products))
            )
            subtotal = 0

            for product in selected_products:
                quantity = random.randint(1, 3)
                item_price = product["unit_price"]
                item_total = item_price * quantity

                order_item = {
                    "order_item_id": len(self.order_items) + 1,
                    "order_id": self.order_id_counter,
                    "product_id": product["product_id"],
                    "quantity": quantity,
                    "unit_price": item_price,
                    "discount": (
                        random.uniform(0, 0.1) * item_price
                        if random.random() < 0.2
                        else 0
                    ),
                    "total_price": item_total,
                }
                self.order_items.append(order_item)
                subtotal += item_total

            # Calculate totals
            order["subtotal"] = round(subtotal, 2)

            # Apply coupon discount if any
            if coupon_code:
                coupon = next(
                    c for c in self.coupons if c["coupon_code"] == coupon_code
                )
                if coupon["discount_type"] == "percentage":
                    discount_amount = subtotal * (coupon["discount_value"] / 100)
                else:
                    discount_amount = min(coupon["discount_value"], subtotal)
                order["discount_amount"] = round(discount_amount, 2)

            order["tax_amount"] = round(
                (subtotal - discount_amount) * 0.08, 2
            )  # 8% tax
            order["total_amount"] = round(
                subtotal - discount_amount + order["tax_amount"] + shipping_cost, 2
            )

            self.orders.append(order)

            # Generate payment record
            if status not in ["cancelled", "pending"]:
                payment = {
                    "payment_id": self.payment_id_counter,
                    "order_id": self.order_id_counter,
                    "payment_date": order_date
                    + timedelta(minutes=random.randint(1, 60)),
                    "payment_method": payment_method,
                    "amount": order["total_amount"],
                    "status": "completed" if status != "cancelled" else "failed",
                    "transaction_id": str(uuid.uuid4()),
                    "gateway_response": (
                        "Success" if status != "cancelled" else "Payment declined"
                    ),
                }
                self.payments.append(payment)
                self.payment_id_counter += 1

            # Generate shipment record
            if status in ["shipped", "delivered", "completed", "returned"]:
                shipment = {
                    "shipment_id": self.shipment_id_counter,
                    "order_id": self.order_id_counter,
                    "warehouse_id": random.choice(self.warehouses)["warehouse_id"],
                    "tracking_number": f"TRK{self.shipment_id_counter:010d}",
                    "carrier": random.choice(["UPS", "FedEx", "USPS", "DHL"]),
                    "shipped_date": order_date + timedelta(days=random.randint(1, 2)),
                    "estimated_delivery": order_date
                    + timedelta(days=random.randint(3, 7)),
                    "actual_delivery": (
                        order_date + timedelta(days=random.randint(3, 8))
                        if status in ["delivered", "completed"]
                        else None
                    ),
                    "status": (
                        "delivered"
                        if status in ["delivered", "completed"]
                        else "in_transit"
                    ),
                }
                self.shipments.append(shipment)
                self.shipment_id_counter += 1

            self.order_id_counter += 1

    def _generate_carts(self):
        """Generate abandoned cart data"""
        print("  Generating shopping carts...")

        # Generate carts for a portion of users
        users_with_carts = random.sample(
            self.users, int(len(self.users) * 0.3)  # 30% of users have carts
        )

        for user in users_with_carts:
            # Some users have multiple cart sessions
            num_carts = random.choices([1, 2, 3], weights=[0.7, 0.2, 0.1])[0]

            for _ in range(num_carts):
                created_date = self.fake.date_time_between(
                    start_date="-30days", end_date="now"
                )

                cart = {
                    "cart_id": self.cart_id_counter,
                    "user_id": user["user_id"],
                    "session_id": str(uuid.uuid4()),
                    "created_at": created_date,
                    "updated_at": created_date
                    + timedelta(minutes=random.randint(1, 120)),
                    "is_active": random.random()
                    > self.config["counts"]["cart_abandonment_rate"],
                    "total_items": 0,
                    "total_amount": 0,
                }

                # Add items to cart
                num_items = random.randint(1, 5)
                selected_products = random.sample(
                    self.products, min(num_items, len(self.products))
                )

                total_amount = 0
                for product in selected_products:
                    quantity = random.randint(1, 3)

                    cart_item = {
                        "cart_item_id": len(self.cart_items) + 1,
                        "cart_id": self.cart_id_counter,
                        "product_id": product["product_id"],
                        "quantity": quantity,
                        "added_at": cart["created_at"],
                    }
                    self.cart_items.append(cart_item)

                    cart["total_items"] += quantity
                    total_amount += product["unit_price"] * quantity

                cart["total_amount"] = round(total_amount, 2)
                self.carts.append(cart)
                self.cart_id_counter += 1

    def _generate_reviews(self):
        """Generate product reviews"""
        print("  Generating reviews...")

        # Generate reviews for a portion of completed orders
        completed_orders = [o for o in self.orders if o["status"] == "completed"]
        orders_to_review = random.sample(
            completed_orders,
            min(
                int(
                    len(completed_orders) * self.config["counts"]["reviews_percentage"]
                ),
                len(completed_orders),
            ),
        )

        for order in orders_to_review:
            # Get order items
            order_items_list = [
                oi for oi in self.order_items if oi["order_id"] == order["order_id"]
            ]

            # Review some or all items
            items_to_review = random.sample(
                order_items_list, random.randint(1, min(3, len(order_items_list)))
            )

            for item in items_to_review:
                # Determine rating
                rating = random.choices(
                    [5, 4, 3, 2, 1],
                    weights=[
                        self.config["review_distribution"]["5_star"],
                        self.config["review_distribution"]["4_star"],
                        self.config["review_distribution"]["3_star"],
                        self.config["review_distribution"]["2_star"],
                        self.config["review_distribution"]["1_star"],
                    ],
                )[0]

                # Generate review text based on rating
                review_text = None
                if random.random() < self.config["review_distribution"]["with_text"]:
                    if rating >= 4:
                        review_text = random.choice(
                            [
                                "Great product! Highly recommend.",
                                "Excellent quality, fast shipping.",
                                "Very satisfied with this purchase.",
                                "Exactly as described, love it!",
                            ]
                        )
                    elif rating == 3:
                        review_text = random.choice(
                            [
                                "Good product, but could be better.",
                                "Average quality for the price.",
                                "It's okay, nothing special.",
                            ]
                        )
                    else:
                        review_text = random.choice(
                            [
                                "Not satisfied with the quality.",
                                "Product didn't meet expectations.",
                                "Would not buy again.",
                                "Poor quality, disappointed.",
                            ]
                        )

                review = {
                    "review_id": self.review_id_counter,
                    "product_id": item["product_id"],
                    "user_id": order["user_id"],
                    "order_id": order["order_id"],
                    "rating": rating,
                    "title": f"{'Great' if rating >= 4 else 'Average' if rating == 3 else 'Poor'} product",
                    "review_text": review_text,
                    "is_verified_purchase": True,
                    "helpful_count": (
                        random.randint(0, 50) if random.random() < 0.3 else 0
                    ),
                    "created_at": order["order_date"]
                    + timedelta(days=random.randint(1, 30)),
                    "has_images": random.random()
                    < self.config["review_distribution"]["with_images"],
                }
                self.reviews.append(review)
                self.review_id_counter += 1

                # Update product review count
                product = next(
                    p for p in self.products if p["product_id"] == item["product_id"]
                )
                product["review_count"] += 1

    def _generate_wishlists(self):
        """Generate user wishlists"""
        print("  Generating wishlists...")

        # Some users have wishlists
        users_with_wishlists = random.sample(
            self.users, int(len(self.users) * 0.4)  # 40% of users
        )

        wishlist_id = 1
        for user in users_with_wishlists:
            # Add random products to wishlist
            num_items = random.randint(1, 10)
            wishlist_products = random.sample(
                self.products, min(num_items, len(self.products))
            )

            for product in wishlist_products:
                wishlist_item = {
                    "wishlist_id": wishlist_id,
                    "user_id": user["user_id"],
                    "product_id": product["product_id"],
                    "added_date": self.fake.date_between(
                        start_date="-60days", end_date="today"
                    ),
                    "priority": random.choice(["high", "medium", "low"]),
                    "notes": self.fake.sentence() if random.random() < 0.1 else None,
                }
                self.wishlists.append(wishlist_item)
                wishlist_id += 1

    def _write_all_csvs(self):
        """Write all data to CSV files"""
        datasets = [
            ("users", self.users),
            ("addresses", self.addresses),
            ("categories", self.categories),
            ("brands", self.brands),
            ("suppliers", self.suppliers),
            ("products", self.products),
            ("warehouses", self.warehouses),
            ("inventory", self.inventory),
            ("orders", self.orders),
            ("order_items", self.order_items),
            ("payments", self.payments),
            ("shipments", self.shipments),
            ("carts", self.carts),
            ("cart_items", self.cart_items),
            ("reviews", self.reviews),
            ("wishlists", self.wishlists),
            ("coupons", self.coupons),
            ("promotions", self.promotions),
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
        load_script = f"""-- Load generated E-commerce data
-- Generated on {datetime.now()}

-- Clear existing data
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE wishlists;
TRUNCATE TABLE reviews;
TRUNCATE TABLE cart_items;
TRUNCATE TABLE carts;
TRUNCATE TABLE shipments;
TRUNCATE TABLE payments;
TRUNCATE TABLE order_items;
TRUNCATE TABLE orders;
TRUNCATE TABLE inventory;
TRUNCATE TABLE products;
TRUNCATE TABLE categories;
TRUNCATE TABLE brands;
TRUNCATE TABLE suppliers;
TRUNCATE TABLE warehouses;
TRUNCATE TABLE addresses;
TRUNCATE TABLE users;
TRUNCATE TABLE promotions;
TRUNCATE TABLE coupons;
SET FOREIGN_KEY_CHECKS = 1;

-- Load data files
-- Note: Adjust paths as needed for your MySQL configuration

LOAD DATA INFILE '/var/lib/mysql-files/ecommerce/users.csv'
INTO TABLE users
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\\n'
IGNORE 1 ROWS;

LOAD DATA INFILE '/var/lib/mysql-files/ecommerce/addresses.csv'
INTO TABLE addresses
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\\n'
IGNORE 1 ROWS;

LOAD DATA INFILE '/var/lib/mysql-files/ecommerce/categories.csv'
INTO TABLE categories
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\\n'
IGNORE 1 ROWS;

LOAD DATA INFILE '/var/lib/mysql-files/ecommerce/products.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\\n'
IGNORE 1 ROWS;

LOAD DATA INFILE '/var/lib/mysql-files/ecommerce/orders.csv'
INTO TABLE orders
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\\n'
IGNORE 1 ROWS;

LOAD DATA INFILE '/var/lib/mysql-files/ecommerce/order_items.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\\n'
IGNORE 1 ROWS;

-- Update statistics
ANALYZE TABLE users, products, orders, order_items;

SELECT 'Data load complete!' as status;
SELECT COUNT(*) as user_count FROM users;
SELECT COUNT(*) as product_count FROM products;
SELECT COUNT(*) as order_count FROM orders;
"""

        script_path = self.output_dir / "load_data.sql"
        with open(script_path, "w") as f:
            f.write(load_script)

        print(f"  [OK] Generated SQL load script: load_data.sql")


def main():
    parser = argparse.ArgumentParser(description="Generate E-commerce data")
    parser.add_argument("--config", default="config.yaml", help="Path to config.yaml")
    args = parser.parse_args()

    generator = EcommerceGenerator(args.config)
    generator.generate_all()


if __name__ == "__main__":
    main()
