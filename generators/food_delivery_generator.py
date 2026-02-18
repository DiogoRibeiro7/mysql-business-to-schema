#!/usr/bin/env python3
"""
Food Delivery Platform Data Generator

Generates realistic test data for the food delivery platform database.
Includes customers, restaurants, drivers, orders, and real-time tracking data.
"""

import random
import sys
import os
from datetime import datetime, timedelta, time
from decimal import Decimal
from typing import List, Dict, Tuple, Optional
import json

# Add parent directory to path for base generator
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from generators.base_generator import BaseGenerator


class FoodDeliveryGenerator(BaseGenerator):
    """Generator for Food Delivery Platform data"""

    def __init__(self, host='localhost', port=3337, user='food_admin',
                 password='food_pass_2024', database='food_delivery'):
        """Initialize the food delivery generator"""
        super().__init__(host, port, user, password, database)

        # Food categories and cuisines
        self.cuisines = [
            'Italian', 'Chinese', 'Mexican', 'Japanese', 'Indian',
            'Thai', 'Greek', 'French', 'American', 'Mediterranean',
            'Korean', 'Vietnamese', 'Lebanese', 'Turkish', 'Spanish'
        ]

        self.food_categories = [
            'Pizza', 'Burgers', 'Sushi', 'Pasta', 'Salads',
            'Sandwiches', 'Desserts', 'Beverages', 'Breakfast',
            'BBQ', 'Seafood', 'Vegetarian', 'Vegan', 'Healthy',
            'Fast Food', 'Comfort Food', 'Street Food'
        ]

        # Delivery zones (simplified city zones)
        self.zones = [
            'Downtown', 'Midtown', 'Uptown', 'North Side', 'South Side',
            'East End', 'West End', 'Airport Area', 'University District',
            'Business District', 'Waterfront', 'Suburbs North', 'Suburbs South'
        ]

        # Restaurant types
        self.restaurant_types = [
            'restaurant', 'cloud_kitchen', 'food_truck', 'cafe', 'bar_grill'
        ]

        # Order statuses for workflow
        self.order_workflow = [
            'pending', 'confirmed', 'preparing', 'ready',
            'assigned', 'picked_up', 'on_the_way', 'delivered'
        ]

    def generate_all_data(self, customers: int = 5000, restaurants: int = 500,
                         drivers: int = 1000, orders_per_day: int = 2000):
        """Generate all food delivery platform data"""
        print("Starting Food Delivery Platform data generation...")

        # Generate base data
        print("Generating customers...")
        self.generate_customers(customers)

        print("Generating delivery zones...")
        self.generate_delivery_zones()

        print("Generating restaurants...")
        self.generate_restaurants(restaurants)

        print("Generating restaurant menus...")
        self.generate_menus()

        print("Generating drivers...")
        self.generate_drivers(drivers)

        print("Generating orders and deliveries...")
        self.generate_orders(orders_per_day)

        print("Generating ratings and reviews...")
        self.generate_ratings()

        print("Generating promotions...")
        self.generate_promotions()

        print("Generating customer support tickets...")
        self.generate_support_tickets()

        print("Generation complete!")

    def generate_customers(self, count: int = 5000):
        """Generate customer accounts"""
        customers = []

        for i in range(count):
            email = self.faker.email()
            phone = self.faker.phone_number()

            # Customer preferences
            dietary_preferences = []
            if random.random() > 0.7:
                dietary_preferences = random.sample(
                    ['vegetarian', 'vegan', 'gluten_free', 'halal', 'kosher', 'dairy_free'],
                    random.randint(1, 2)
                )

            customer = (
                email,
                self.faker.first_name(),
                self.faker.last_name(),
                phone,
                self.generate_password_hash(),
                random.choice([0, 1]),  # email_verified
                random.choice([0, 1]),  # phone_verified
                json.dumps(dietary_preferences) if dietary_preferences else None,
                self.faker.random_element(self.cuisines[:5]),  # favorite_cuisine
                random.uniform(0, 5.0) if random.random() > 0.3 else None,  # avg_rating
                random.randint(0, 500) if random.random() > 0.5 else 0,  # total_orders
                random.uniform(0, 10000) if random.random() > 0.5 else 0,  # total_spent
                random.randint(0, 1000),  # loyalty_points
                self.faker.random_element(['bronze', 'silver', 'gold', 'platinum']),
                self.faker.random_element(['active', 'inactive', 'suspended', 'banned']),
                self.faker.date_time_between('-30 days', 'now') if random.random() > 0.3 else None,
                self.faker.date_time_between('-2 years', 'now'),
                self.faker.date_time_between('-2 years', 'now')
            )
            customers.append(customer)

            if (i + 1) % 1000 == 0:
                self.bulk_insert('customers', customers, [
                    'email', 'first_name', 'last_name', 'phone',
                    'password_hash', 'email_verified', 'phone_verified',
                    'dietary_preferences', 'favorite_cuisine', 'avg_rating',
                    'total_orders', 'total_spent', 'loyalty_points',
                    'loyalty_tier', 'account_status', 'last_order_date',
                    'created_at', 'updated_at'
                ])
                customers = []
                print(f"  Generated {i + 1}/{count} customers...")

        if customers:
            self.bulk_insert('customers', customers, [
                'email', 'first_name', 'last_name', 'phone',
                'password_hash', 'email_verified', 'phone_verified',
                'dietary_preferences', 'favorite_cuisine', 'avg_rating',
                'total_orders', 'total_spent', 'loyalty_points',
                'loyalty_tier', 'account_status', 'last_order_date',
                'created_at', 'updated_at'
            ])

    def generate_delivery_zones(self):
        """Generate delivery zones with surge pricing"""
        zones = []

        for zone_name in self.zones:
            # Generate zone polygon (simplified as bounding box)
            base_lat = 37.7749 + random.uniform(-0.1, 0.1)
            base_lon = -122.4194 + random.uniform(-0.1, 0.1)

            # Create a simple polygon (square for simplicity)
            polygon_points = [
                [base_lon - 0.01, base_lat - 0.01],
                [base_lon + 0.01, base_lat - 0.01],
                [base_lon + 0.01, base_lat + 0.01],
                [base_lon - 0.01, base_lat + 0.01],
                [base_lon - 0.01, base_lat - 0.01]
            ]

            zone_polygon = json.dumps({
                "type": "Polygon",
                "coordinates": [polygon_points]
            })

            zone = (
                zone_name,
                zone_name[:3].upper(),  # zone_code
                zone_polygon,
                random.uniform(2.99, 5.99),  # base_delivery_fee
                random.uniform(1.0, 2.0) if random.random() > 0.5 else 1.0,  # surge_multiplier
                random.choice([0, 1]),  # is_active
                random.uniform(15, 45),  # avg_delivery_time
                random.randint(5, 50),  # active_drivers
                random.randint(10, 100),  # pending_orders
                self.faker.date_time_between('-1 year', 'now')
            )
            zones.append(zone)

        self.bulk_insert('delivery_zones', zones, [
            'zone_name', 'zone_code', 'zone_polygon', 'base_delivery_fee',
            'surge_multiplier', 'is_active', 'avg_delivery_time_minutes',
            'active_drivers', 'pending_orders', 'created_at'
        ])

    def generate_restaurants(self, count: int = 500):
        """Generate restaurant accounts"""
        restaurants = []
        zone_ids = list(range(1, len(self.zones) + 1))

        for i in range(count):
            restaurant_name = self.faker.company() + random.choice([
                ' Kitchen', ' Grill', ' Bistro', ' Cafe', ' Restaurant',
                ' Diner', ' Pizzeria', ' Sushi', ' BBQ', ' Bakery'
            ])

            # Generate location
            lat = 37.7749 + random.uniform(-0.1, 0.1)
            lon = -122.4194 + random.uniform(-0.1, 0.1)
            location = f"POINT({lon} {lat})"

            # Generate operating hours
            open_time = random.choice(['06:00', '07:00', '08:00', '09:00', '10:00', '11:00'])
            close_time = random.choice(['20:00', '21:00', '22:00', '23:00', '00:00', '01:00'])

            restaurant = (
                restaurant_name,
                self.faker.slug(),
                self.faker.email(),
                self.faker.phone_number(),
                self.generate_password_hash(),
                random.choice(self.restaurant_types),
                random.sample(self.cuisines, random.randint(1, 3)),  # cuisine_types as JSON
                self.faker.address(),
                location,
                random.choice(zone_ids),
                open_time,
                close_time,
                random.choice([0, 1]),  # accepts_orders
                random.uniform(10, 100),  # min_order_amount
                random.uniform(15, 60),  # avg_prep_time
                random.uniform(3.0, 5.0),  # rating
                random.randint(0, 10000),  # total_reviews
                random.choice([0, 1]),  # is_featured
                random.uniform(0.10, 0.30),  # commission_rate
                self.faker.iban() if random.random() > 0.3 else None,
                random.choice(['pending', 'approved', 'suspended', 'rejected']),
                self.faker.date_time_between('-2 years', 'now'),
                self.faker.date_time_between('-2 years', 'now')
            )
            restaurants.append(restaurant)

            if (i + 1) % 100 == 0:
                self.bulk_insert('restaurants', restaurants, [
                    'restaurant_name', 'slug', 'email', 'phone',
                    'password_hash', 'restaurant_type', 'cuisine_types',
                    'address', 'location', 'zone_id', 'opening_time',
                    'closing_time', 'accepts_orders', 'min_order_amount',
                    'avg_preparation_time', 'rating', 'total_reviews',
                    'is_featured', 'commission_rate', 'bank_account',
                    'verification_status', 'created_at', 'updated_at'
                ])
                restaurants = []
                print(f"  Generated {i + 1}/{count} restaurants...")

        if restaurants:
            self.bulk_insert('restaurants', restaurants, [
                'restaurant_name', 'slug', 'email', 'phone',
                'password_hash', 'restaurant_type', 'cuisine_types',
                'address', 'location', 'zone_id', 'opening_time',
                'closing_time', 'accepts_orders', 'min_order_amount',
                'avg_preparation_time', 'rating', 'total_reviews',
                'is_featured', 'commission_rate', 'bank_account',
                'verification_status', 'created_at', 'updated_at'
            ])

    def generate_menus(self):
        """Generate restaurant menus with items"""
        restaurants = self.fetch_all("SELECT restaurant_id FROM restaurants WHERE verification_status = 'approved'")

        menu_items = []
        item_id = 1

        for restaurant in restaurants:
            # Each restaurant has 10-50 menu items
            num_items = random.randint(10, 50)

            for _ in range(num_items):
                item_name = self.faker.random_element([
                    'Margherita Pizza', 'Pepperoni Pizza', 'Caesar Salad',
                    'Greek Salad', 'Cheeseburger', 'Veggie Burger',
                    'Pad Thai', 'Chicken Tikka', 'Sushi Roll', 'Ramen Bowl',
                    'Tacos', 'Burrito', 'Pasta Carbonara', 'Fish & Chips',
                    'Chicken Wings', 'Spring Rolls', 'Fried Rice', 'Steak',
                    'Grilled Salmon', 'Vegetable Curry', 'Ice Cream',
                    'Chocolate Cake', 'Apple Pie', 'Coffee', 'Smoothie'
                ])

                # Add variations
                item_name = f"{random.choice(['Classic', 'Special', 'Deluxe', 'Mini', 'Large', ''])} {item_name}".strip()

                menu_item = (
                    restaurant['restaurant_id'],
                    item_name,
                    self.faker.text(max_nb_chars=200),
                    random.choice(self.food_categories),
                    random.uniform(5.99, 49.99),  # price
                    random.uniform(0, 20) if random.random() > 0.5 else None,  # discount_price
                    random.choice([0, 1]),  # is_available
                    random.choice([0, 1]) if random.random() > 0.7 else 0,  # is_vegetarian
                    random.choice([0, 1]) if random.random() > 0.8 else 0,  # is_vegan
                    random.choice([0, 1]) if random.random() > 0.8 else 0,  # is_gluten_free
                    random.choice([0, 1]) if random.random() > 0.9 else 0,  # is_spicy
                    random.randint(100, 800),  # calories
                    random.uniform(10, 45),  # prep_time_minutes
                    f"https://food-images.com/item_{item_id}.jpg",
                    random.randint(0, 1000) if random.random() > 0.3 else 0,  # times_ordered
                    random.uniform(3.5, 5.0) if random.random() > 0.3 else None,  # avg_rating
                    self.faker.date_time_between('-1 year', 'now')
                )
                menu_items.append(menu_item)
                item_id += 1

                if len(menu_items) >= 1000:
                    self.bulk_insert('menu_items', menu_items, [
                        'restaurant_id', 'item_name', 'description', 'category',
                        'price', 'discount_price', 'is_available', 'is_vegetarian',
                        'is_vegan', 'is_gluten_free', 'is_spicy', 'calories',
                        'prep_time_minutes', 'image_url', 'times_ordered',
                        'avg_rating', 'created_at'
                    ])
                    menu_items = []

        if menu_items:
            self.bulk_insert('menu_items', menu_items, [
                'restaurant_id', 'item_name', 'description', 'category',
                'price', 'discount_price', 'is_available', 'is_vegetarian',
                'is_vegan', 'is_gluten_free', 'is_spicy', 'calories',
                'prep_time_minutes', 'image_url', 'times_ordered',
                'avg_rating', 'created_at'
            ])

    def generate_drivers(self, count: int = 1000):
        """Generate delivery driver accounts"""
        drivers = []
        zone_ids = list(range(1, len(self.zones) + 1))

        for i in range(count):
            email = self.faker.email()
            phone = self.faker.phone_number()

            # Vehicle information
            vehicle_types = ['bicycle', 'scooter', 'motorcycle', 'car']
            vehicle_type = random.choice(vehicle_types)

            if vehicle_type == 'car':
                vehicle_make = random.choice(['Toyota', 'Honda', 'Ford', 'Chevrolet'])
                vehicle_model = random.choice(['Corolla', 'Civic', 'Focus', 'Cruze'])
                license_plate = self.faker.license_plate()
            else:
                vehicle_make = None
                vehicle_model = None
                license_plate = None if vehicle_type == 'bicycle' else self.faker.license_plate()

            # Driver location (current position)
            lat = 37.7749 + random.uniform(-0.1, 0.1)
            lon = -122.4194 + random.uniform(-0.1, 0.1)
            current_location = f"POINT({lon} {lat})"

            driver = (
                email,
                self.faker.first_name(),
                self.faker.last_name(),
                phone,
                self.generate_password_hash(),
                self.faker.ssn(),
                vehicle_type,
                vehicle_make,
                vehicle_model,
                license_plate,
                random.choice(['pending', 'approved', 'rejected']),
                random.choice(['offline', 'online', 'busy', 'break']),
                current_location,
                random.choice(zone_ids),
                random.uniform(3.5, 5.0),  # rating
                random.randint(0, 5000),  # total_deliveries
                random.randint(0, 10000),  # total_earnings
                random.uniform(0.85, 0.99) if random.random() > 0.2 else None,  # acceptance_rate
                random.uniform(0.90, 0.99) if random.random() > 0.2 else None,  # completion_rate
                random.uniform(15, 45),  # avg_delivery_time
                self.faker.date_time_between('-30 days', 'now') if random.random() > 0.3 else None,
                self.faker.date_time_between('-2 years', 'now'),
                self.faker.date_time_between('-2 years', 'now')
            )
            drivers.append(driver)

            if (i + 1) % 200 == 0:
                self.bulk_insert('drivers', drivers, [
                    'email', 'first_name', 'last_name', 'phone',
                    'password_hash', 'drivers_license', 'vehicle_type',
                    'vehicle_make', 'vehicle_model', 'license_plate',
                    'verification_status', 'availability_status',
                    'current_location', 'current_zone_id', 'rating',
                    'total_deliveries', 'total_earnings', 'acceptance_rate',
                    'completion_rate', 'avg_delivery_time', 'last_active',
                    'created_at', 'updated_at'
                ])
                drivers = []
                print(f"  Generated {i + 1}/{count} drivers...")

        if drivers:
            self.bulk_insert('drivers', drivers, [
                'email', 'first_name', 'last_name', 'phone',
                'password_hash', 'drivers_license', 'vehicle_type',
                'vehicle_make', 'vehicle_model', 'license_plate',
                'verification_status', 'availability_status',
                'current_location', 'current_zone_id', 'rating',
                'total_deliveries', 'total_earnings', 'acceptance_rate',
                'completion_rate', 'avg_delivery_time', 'last_active',
                'created_at', 'updated_at'
            ])

    def generate_orders(self, orders_per_day: int = 2000):
        """Generate orders with delivery tracking"""
        # Fetch required data
        customers = self.fetch_all("SELECT customer_id FROM customers WHERE account_status = 'active' LIMIT 2000")
        restaurants = self.fetch_all("SELECT restaurant_id, zone_id, avg_preparation_time FROM restaurants WHERE verification_status = 'approved'")
        drivers = self.fetch_all("SELECT driver_id, current_zone_id FROM drivers WHERE verification_status = 'approved'")
        menu_items = self.fetch_all("SELECT item_id, restaurant_id, price FROM menu_items WHERE is_available = 1")

        # Group menu items by restaurant
        items_by_restaurant = {}
        for item in menu_items:
            rid = item['restaurant_id']
            if rid not in items_by_restaurant:
                items_by_restaurant[rid] = []
            items_by_restaurant[rid].append(item)

        orders = []
        order_items = []
        deliveries = []
        delivery_tracking = []
        order_id = 1

        # Generate orders for last 30 days
        for days_ago in range(30, 0, -1):
            order_date = datetime.now() - timedelta(days=days_ago)
            daily_orders = random.randint(int(orders_per_day * 0.7), int(orders_per_day * 1.3))

            for _ in range(daily_orders):
                customer = random.choice(customers)
                restaurant = random.choice(restaurants)

                if restaurant['restaurant_id'] not in items_by_restaurant:
                    continue

                # Generate order
                order_status = random.choice(self.order_workflow + ['cancelled'])
                payment_method = random.choice(['credit_card', 'debit_card', 'paypal', 'cash', 'wallet'])

                # Calculate order totals
                restaurant_items = items_by_restaurant[restaurant['restaurant_id']]
                num_items = random.randint(1, min(5, len(restaurant_items)))
                selected_items = random.sample(restaurant_items, num_items)

                subtotal = sum(float(item['price']) * random.randint(1, 3) for item in selected_items)
                delivery_fee = random.uniform(2.99, 5.99)
                service_fee = subtotal * 0.10
                tip = subtotal * random.uniform(0, 0.25) if payment_method != 'cash' else 0
                total = subtotal + delivery_fee + service_fee + tip

                order_time = order_date + timedelta(
                    hours=random.randint(11, 22),
                    minutes=random.randint(0, 59)
                )

                # Generate delivery address
                delivery_lat = 37.7749 + random.uniform(-0.05, 0.05)
                delivery_lon = -122.4194 + random.uniform(-0.05, 0.05)
                delivery_location = f"POINT({delivery_lon} {delivery_lat})"

                order_record = (
                    customer['customer_id'],
                    restaurant['restaurant_id'],
                    order_status,
                    payment_method,
                    subtotal,
                    delivery_fee,
                    service_fee,
                    tip,
                    total,
                    None,  # promo_code
                    0,  # discount_amount
                    self.faker.address(),
                    delivery_location,
                    random.choice(['Leave at door', 'Hand to me', 'Meet outside', None]),
                    random.uniform(0, 60) if order_status == 'delivered' else None,
                    order_time,
                    order_time + timedelta(minutes=random.randint(20, 60)) if order_status == 'delivered' else None
                )
                orders.append(order_record)

                # Generate order items
                for item in selected_items:
                    quantity = random.randint(1, 3)
                    order_item = (
                        order_id,
                        item['item_id'],
                        quantity,
                        float(item['price']),
                        float(item['price']) * quantity,
                        None  # special_instructions
                    )
                    order_items.append(order_item)

                # Generate delivery if order was accepted
                if order_status not in ['pending', 'cancelled']:
                    driver = random.choice([d for d in drivers if d['current_zone_id'] == restaurant['zone_id']])

                    delivery = (
                        order_id,
                        driver['driver_id'],
                        random.choice(['pending', 'assigned', 'picked_up', 'delivered', 'failed']),
                        f"POINT({delivery_lon} {delivery_lat})",
                        f"POINT({delivery_lon + 0.01} {delivery_lat + 0.01})",
                        random.uniform(1, 10),  # distance_km
                        random.uniform(10, 45),  # estimated_time
                        random.uniform(10, 50) if order_status == 'delivered' else None,
                        order_time + timedelta(minutes=5),
                        order_time + timedelta(minutes=random.randint(15, 20)),
                        order_time + timedelta(minutes=random.randint(25, 35)) if order_status == 'delivered' else None,
                        order_time + timedelta(minutes=random.randint(30, 60)) if order_status == 'delivered' else None
                    )
                    deliveries.append(delivery)

                    # Generate tracking updates
                    if order_status in ['delivered', 'on_the_way', 'picked_up']:
                        # Generate 3-5 tracking points
                        num_updates = random.randint(3, 5)
                        for i in range(num_updates):
                            lat = delivery_lat + random.uniform(-0.01, 0.01)
                            lon = delivery_lon + random.uniform(-0.01, 0.01)
                            tracking = (
                                order_id,  # Will use delivery_id but simplified here
                                f"POINT({lon} {lat})",
                                order_time + timedelta(minutes=10 + i * 5)
                            )
                            delivery_tracking.append(tracking)

                order_id += 1

                # Bulk insert periodically
                if len(orders) >= 500:
                    self.bulk_insert('orders', orders, [
                        'customer_id', 'restaurant_id', 'order_status',
                        'payment_method', 'subtotal', 'delivery_fee',
                        'service_fee', 'tip_amount', 'total_amount',
                        'promo_code', 'discount_amount', 'delivery_address',
                        'delivery_location', 'delivery_instructions',
                        'estimated_delivery_time', 'created_at', 'delivered_at'
                    ])
                    orders = []

                if len(order_items) >= 1000:
                    self.bulk_insert('order_items', order_items, [
                        'order_id', 'item_id', 'quantity', 'unit_price',
                        'total_price', 'special_instructions'
                    ])
                    order_items = []

                if len(deliveries) >= 500:
                    self.bulk_insert('deliveries', deliveries, [
                        'order_id', 'driver_id', 'delivery_status',
                        'pickup_location', 'dropoff_location', 'distance_km',
                        'estimated_time_minutes', 'actual_time_minutes',
                        'assigned_at', 'picked_up_at', 'delivered_at',
                        'created_at'
                    ])
                    deliveries = []

            print(f"  Generated orders for {days_ago} days ago...")

        # Insert remaining data
        if orders:
            self.bulk_insert('orders', orders, [
                'customer_id', 'restaurant_id', 'order_status',
                'payment_method', 'subtotal', 'delivery_fee',
                'service_fee', 'tip_amount', 'total_amount',
                'promo_code', 'discount_amount', 'delivery_address',
                'delivery_location', 'delivery_instructions',
                'estimated_delivery_time', 'created_at', 'delivered_at'
            ])

        if order_items:
            self.bulk_insert('order_items', order_items, [
                'order_id', 'item_id', 'quantity', 'unit_price',
                'total_price', 'special_instructions'
            ])

        if deliveries:
            self.bulk_insert('deliveries', deliveries, [
                'order_id', 'driver_id', 'delivery_status',
                'pickup_location', 'dropoff_location', 'distance_km',
                'estimated_time_minutes', 'actual_time_minutes',
                'assigned_at', 'picked_up_at', 'delivered_at',
                'created_at'
            ])

    def generate_ratings(self):
        """Generate ratings and reviews"""
        # Get completed orders
        completed_orders = self.fetch_all("""
            SELECT o.order_id, o.customer_id, o.restaurant_id, d.driver_id
            FROM orders o
            LEFT JOIN deliveries d ON o.order_id = d.order_id
            WHERE o.order_status = 'delivered'
            LIMIT 1000
        """)

        ratings = []

        for order in completed_orders:
            # 70% chance of rating
            if random.random() > 0.3:
                # Restaurant rating
                rating = (
                    order['customer_id'],
                    order['restaurant_id'],
                    None,  # driver_id
                    order['order_id'],
                    random.randint(1, 5),  # food_rating
                    random.randint(1, 5) if random.random() > 0.3 else None,  # delivery_rating
                    random.randint(1, 5),  # overall_rating
                    self.faker.sentence() if random.random() > 0.5 else None,
                    self.faker.date_time_between('-30 days', 'now')
                )
                ratings.append(rating)

                # Driver rating (if applicable)
                if order['driver_id'] and random.random() > 0.5:
                    driver_rating = (
                        order['customer_id'],
                        None,  # restaurant_id
                        order['driver_id'],
                        order['order_id'],
                        None,  # food_rating
                        random.randint(1, 5),  # delivery_rating
                        random.randint(1, 5),  # overall_rating
                        self.faker.sentence() if random.random() > 0.7 else None,
                        self.faker.date_time_between('-30 days', 'now')
                    )
                    ratings.append(driver_rating)

        self.bulk_insert('ratings', ratings, [
            'customer_id', 'restaurant_id', 'driver_id', 'order_id',
            'food_rating', 'delivery_rating', 'overall_rating',
            'comment', 'created_at'
        ])

    def generate_promotions(self):
        """Generate promotional codes"""
        promotions = []

        promo_types = [
            ('percentage', 'SAVE20', 20, None, 'Get 20% off your order'),
            ('fixed', 'WELCOME10', None, 10, 'Welcome! $10 off your first order'),
            ('percentage', 'WEEKEND25', 25, None, 'Weekend special - 25% off'),
            ('fixed', 'FREEDELIVERY', None, 5.99, 'Free delivery on us'),
            ('percentage', 'STUDENT15', 15, None, 'Student discount - 15% off'),
            ('fixed', 'LOYALTY5', None, 5, 'Thank you for your loyalty - $5 off')
        ]

        for promo_type, code, percentage, fixed, description in promo_types:
            promotion = (
                code,
                description,
                promo_type,
                percentage,
                fixed,
                15.00,  # min_order_amount
                percentage * 2 if percentage else fixed * 3,  # max_discount
                random.randint(100, 1000),  # usage_limit
                random.randint(0, 500),  # times_used
                self.faker.date_time_between('-30 days', '-10 days'),
                self.faker.date_time_between('+10 days', '+30 days'),
                random.choice([0, 1]),  # is_active
                self.faker.date_time_between('-60 days', 'now')
            )
            promotions.append(promotion)

        self.bulk_insert('promotions', promotions, [
            'promo_code', 'description', 'discount_type', 'discount_percentage',
            'discount_fixed', 'min_order_amount', 'max_discount_amount',
            'usage_limit', 'times_used', 'valid_from', 'valid_to',
            'is_active', 'created_at'
        ])

    def generate_support_tickets(self):
        """Generate customer support tickets"""
        customers = self.fetch_all("SELECT customer_id FROM customers LIMIT 200")
        orders = self.fetch_all("SELECT order_id FROM orders LIMIT 500")

        tickets = []

        issue_types = [
            'order_issue', 'delivery_problem', 'payment_issue',
            'food_quality', 'missing_items', 'wrong_order',
            'app_bug', 'account_issue', 'other'
        ]

        for _ in range(300):
            customer = random.choice(customers)
            order = random.choice(orders) if random.random() > 0.3 else None

            ticket = (
                customer['customer_id'],
                order['order_id'] if order else None,
                random.choice(issue_types),
                self.faker.sentence(),
                self.faker.text(max_nb_chars=500),
                random.choice(['low', 'medium', 'high', 'urgent']),
                random.choice(['open', 'in_progress', 'resolved', 'closed']),
                random.randint(1, 10) if random.random() > 0.5 else None,  # assigned_to
                self.faker.text(max_nb_chars=300) if random.random() > 0.5 else None,
                random.randint(1, 5) if random.random() > 0.7 else None,
                self.faker.date_time_between('-30 days', 'now'),
                self.faker.date_time_between('-30 days', 'now') if random.random() > 0.5 else None
            )
            tickets.append(ticket)

        self.bulk_insert('support_tickets', tickets, [
            'customer_id', 'order_id', 'issue_type', 'subject',
            'description', 'priority', 'status', 'assigned_to',
            'resolution_notes', 'satisfaction_rating',
            'created_at', 'resolved_at'
        ])


def main():
    """Main function to run the generator"""
    import argparse

    parser = argparse.ArgumentParser(description='Generate test data for Food Delivery Platform')
    parser.add_argument('--host', default='localhost', help='MySQL host')
    parser.add_argument('--port', type=int, default=3337, help='MySQL port')
    parser.add_argument('--user', default='food_admin', help='MySQL user')
    parser.add_argument('--password', default='food_pass_2024', help='MySQL password')
    parser.add_argument('--database', default='food_delivery', help='MySQL database')
    parser.add_argument('--customers', type=int, default=5000, help='Number of customers')
    parser.add_argument('--restaurants', type=int, default=500, help='Number of restaurants')
    parser.add_argument('--drivers', type=int, default=1000, help='Number of drivers')
    parser.add_argument('--orders-per-day', type=int, default=2000, help='Average orders per day')

    args = parser.parse_args()

    generator = FoodDeliveryGenerator(
        host=args.host,
        port=args.port,
        user=args.user,
        password=args.password,
        database=args.database
    )

    try:
        generator.connect()
        generator.generate_all_data(
            customers=args.customers,
            restaurants=args.restaurants,
            drivers=args.drivers,
            orders_per_day=args.orders_per_day
        )
    finally:
        generator.disconnect()


if __name__ == '__main__':
    main()