#!/usr/bin/env python3
"""
Additional Schema Data Generator
Generates data for all 20 business schemas
"""

import os
import sys
import json
import random
from datetime import datetime, timedelta
from faker import Faker
from typing import List, Dict
import hashlib

# Fix encoding for Windows
if sys.platform == "win32":
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]

fake = Faker()


class ComprehensiveDataGenerator:
    """Generate data for all business schemas"""

    def __init__(self, output_dir: str = "demo_data"):
        self.output_dir = output_dir
        os.makedirs(output_dir, exist_ok=True)
        self.fake = Faker()

    def escape_sql(self, value):
        """Escape SQL special characters"""
        if value is None:
            return "NULL"
        return str(value).replace("'", "''").replace("\\", "\\\\")

    def generate_fintech_data(self, count: int = 100):
        """Generate fintech/banking data"""
        print("Generating fintech data...")

        sql_lines = [
            "-- Demo data for fintech_db",
            "USE fintech_db;",
            "",
            "SET FOREIGN_KEY_CHECKS = 0;",
            "TRUNCATE TABLE customers;",
            "TRUNCATE TABLE accounts;",
            "TRUNCATE TABLE transactions;",
            "TRUNCATE TABLE cards;",
            "SET FOREIGN_KEY_CHECKS = 1;",
            "",
            "-- Insert customers",
            "INSERT INTO customers (customer_id, first_name, last_name, email, phone, ssn, date_of_birth, address, city, state, zip_code, kyc_status) VALUES",
        ]

        # Generate customers
        customer_values = []
        for i in range(count):
            customer = (
                f"('CUST{i+1:08d}', '{self.escape_sql(fake.first_name())}', "
                f"'{self.escape_sql(fake.last_name())}', '{fake.email()}', "
                f"'{fake.phone_number()[:20]}', '{fake.ssn()}', "
                f"'{fake.date_of_birth(minimum_age=18, maximum_age=80)}', "
                f"'{self.escape_sql(fake.street_address())}', '{fake.city()}', "
                f"'{fake.state_abbr()}', '{fake.zipcode()}', "
                f"'{random.choice(['verified', 'pending', 'rejected'])}')"
            )
            customer_values.append(customer)

        sql_lines.append(",\n".join(customer_values) + ";")

        # Generate accounts
        sql_lines.append("\n-- Insert accounts")
        sql_lines.append(
            "INSERT INTO accounts (account_number, customer_id, account_type, balance, currency, status, opened_date, interest_rate) VALUES"
        )

        account_values = []
        for i in range(count * 2):  # 2 accounts per customer average
            account = (
                f"('{fake.iban()}', 'CUST{random.randint(1, count):08d}', "
                f"'{random.choice(['checking', 'savings', 'investment', 'credit'])}', "
                f"{round(random.uniform(100, 100000), 2)}, 'USD', "
                f"'{random.choice(['active', 'frozen', 'closed'])}', "
                f"'{fake.date_between(start_date='-5y', end_date='today')}', "
                f"{round(random.uniform(0.01, 5.0), 2)})"
            )
            account_values.append(account)

        sql_lines.append(",\n".join(account_values) + ";")

        # Generate transactions
        sql_lines.append("\n-- Insert transactions")
        sql_lines.append(
            "INSERT INTO transactions (transaction_id, from_account, to_account, amount, transaction_type, status, timestamp, description) VALUES"
        )

        transaction_values = []
        for i in range(count * 5):  # 5 transactions per customer
            transaction = (
                f"('TXN{i+1:012d}', '{fake.iban()}', '{fake.iban()}', "
                f"{round(random.uniform(1, 5000), 2)}, "
                f"'{random.choice(['transfer', 'deposit', 'withdrawal', 'payment', 'fee'])}', "
                f"'{random.choice(['completed', 'pending', 'failed'])}', "
                f"'{fake.date_time_between(start_date='-6m', end_date='now')}', "
                f"'{self.escape_sql(fake.sentence(nb_words=5))}')"
            )
            transaction_values.append(transaction)

        sql_lines.append(",\n".join(transaction_values) + ";")

        # Save file
        output_file = os.path.join(self.output_dir, "fintech_db_data.sql")
        with open(output_file, "w", encoding="utf-8") as f:
            f.write("\n".join(sql_lines))

        print(
            f"  Created: {output_file} ({count} customers, {count*2} accounts, {count*5} transactions)"
        )
        return output_file

    def generate_social_media_data(self, count: int = 100):
        """Generate social media data"""
        print("Generating social media data...")

        sql_lines = [
            "-- Demo data for social_media_db",
            "USE social_media_db;",
            "",
            "SET FOREIGN_KEY_CHECKS = 0;",
            "TRUNCATE TABLE users;",
            "TRUNCATE TABLE posts;",
            "TRUNCATE TABLE comments;",
            "TRUNCATE TABLE likes;",
            "SET FOREIGN_KEY_CHECKS = 1;",
            "",
            "-- Insert users",
            "INSERT INTO users (user_id, username, email, full_name, bio, profile_image, verified, followers_count, following_count, created_at) VALUES",
        ]

        # Generate users
        user_values = []
        for i in range(count):
            username = fake.user_name()
            user = (
                f"({i+1}, '{username}', '{fake.email()}', "
                f"'{self.escape_sql(fake.name())}', "
                f"'{self.escape_sql(fake.text(max_nb_chars=160))}', "
                f"'https://avatar.example.com/{username}.jpg', "
                f"{random.choice(['true', 'false'])}, "
                f"{random.randint(0, 10000)}, {random.randint(0, 5000)}, "
                f"'{fake.date_time_between(start_date='-3y', end_date='now')}')"
            )
            user_values.append(user)

        sql_lines.append(",\n".join(user_values) + ";")

        # Generate posts
        sql_lines.append("\n-- Insert posts")
        sql_lines.append(
            "INSERT INTO posts (post_id, user_id, content, media_url, likes_count, comments_count, shares_count, created_at) VALUES"
        )

        post_values = []
        hashtags = [
            "#tech",
            "#life",
            "#food",
            "#travel",
            "#fitness",
            "#art",
            "#music",
            "#nature",
        ]
        for i in range(count * 3):  # 3 posts per user average
            content = fake.text(max_nb_chars=280)
            # Add some hashtags
            content += " " + " ".join(random.sample(hashtags, k=random.randint(0, 3)))
            post = (
                f"({i+1}, {random.randint(1, count)}, "
                f"'{self.escape_sql(content)}', "
                f"'{fake.image_url() if random.random() > 0.5 else ''}', "
                f"{random.randint(0, 1000)}, {random.randint(0, 100)}, "
                f"{random.randint(0, 50)}, "
                f"'{fake.date_time_between(start_date='-1y', end_date='now')}')"
            )
            post_values.append(post)

        sql_lines.append(",\n".join(post_values) + ";")

        # Save file
        output_file = os.path.join(self.output_dir, "social_media_db_data.sql")
        with open(output_file, "w", encoding="utf-8") as f:
            f.write("\n".join(sql_lines))

        print(f"  Created: {output_file} ({count} users, {count*3} posts)")
        return output_file

    def generate_real_estate_data(self, count: int = 100):
        """Generate real estate data"""
        print("Generating real estate data...")

        sql_lines = [
            "-- Demo data for real_estate_db",
            "USE real_estate_db;",
            "",
            "SET FOREIGN_KEY_CHECKS = 0;",
            "TRUNCATE TABLE properties;",
            "TRUNCATE TABLE listings;",
            "TRUNCATE TABLE agents;",
            "SET FOREIGN_KEY_CHECKS = 1;",
            "",
            "-- Insert properties",
            "INSERT INTO properties (property_id, address, city, state, zip_code, property_type, bedrooms, bathrooms, square_feet, lot_size, year_built, price) VALUES",
        ]

        # Generate properties
        property_values = []
        property_types = [
            "Single Family",
            "Condo",
            "Townhouse",
            "Multi-Family",
            "Land",
            "Commercial",
        ]
        for i in range(count):
            property = (
                f"('PROP{i+1:06d}', '{self.escape_sql(fake.street_address())}', "
                f"'{fake.city()}', '{fake.state_abbr()}', '{fake.zipcode()}', "
                f"'{random.choice(property_types)}', "
                f"{random.randint(0, 6)}, {random.randint(1, 4)}, "
                f"{random.randint(500, 5000)}, {random.randint(1000, 20000)}, "
                f"{random.randint(1900, 2024)}, "
                f"{random.randint(50000, 2000000)})"
            )
            property_values.append(property)

        sql_lines.append(",\n".join(property_values) + ";")

        # Generate agents
        sql_lines.append("\n-- Insert agents")
        sql_lines.append(
            "INSERT INTO agents (agent_id, first_name, last_name, email, phone, license_number, agency, commission_rate) VALUES"
        )

        agent_values = []
        for i in range(count // 5):  # Fewer agents than properties
            agent = (
                f"('AGT{i+1:04d}', '{self.escape_sql(fake.first_name())}', "
                f"'{self.escape_sql(fake.last_name())}', '{fake.email()}', "
                f"'{fake.phone_number()[:20]}', 'RE{random.randint(100000, 999999)}', "
                f"'{self.escape_sql(fake.company())}', {round(random.uniform(2.0, 6.0), 1)})"
            )
            agent_values.append(agent)

        sql_lines.append(",\n".join(agent_values) + ";")

        # Save file
        output_file = os.path.join(self.output_dir, "real_estate_db_data.sql")
        with open(output_file, "w", encoding="utf-8") as f:
            f.write("\n".join(sql_lines))

        print(f"  Created: {output_file} ({count} properties, {count//5} agents)")
        return output_file

    def generate_logistics_data(self, count: int = 100):
        """Generate logistics/shipping data"""
        print("Generating logistics data...")

        sql_lines = [
            "-- Demo data for logistics_db",
            "USE logistics_db;",
            "",
            "SET FOREIGN_KEY_CHECKS = 0;",
            "TRUNCATE TABLE warehouses;",
            "TRUNCATE TABLE shipments;",
            "TRUNCATE TABLE packages;",
            "SET FOREIGN_KEY_CHECKS = 1;",
            "",
            "-- Insert warehouses",
            "INSERT INTO warehouses (warehouse_id, name, address, city, state, capacity, current_inventory) VALUES",
        ]

        # Generate warehouses
        warehouse_values = []
        for i in range(10):  # Just 10 warehouses
            warehouse = (
                f"('WH{i+1:03d}', 'Warehouse {fake.city()}', "
                f"'{self.escape_sql(fake.street_address())}', "
                f"'{fake.city()}', '{fake.state_abbr()}', "
                f"{random.randint(10000, 100000)}, "
                f"{random.randint(1000, 50000)})"
            )
            warehouse_values.append(warehouse)

        sql_lines.append(",\n".join(warehouse_values) + ";")

        # Generate shipments
        sql_lines.append("\n-- Insert shipments")
        sql_lines.append(
            "INSERT INTO shipments (shipment_id, origin_warehouse, destination_address, status, shipped_date, estimated_delivery, actual_delivery, carrier, tracking_number) VALUES"
        )

        shipment_values = []
        statuses = ["pending", "in_transit", "delivered", "returned", "lost"]
        carriers = ["FedEx", "UPS", "USPS", "DHL", "Amazon"]

        for i in range(count):
            shipped_date = fake.date_between(start_date="-30d", end_date="today")
            estimated = shipped_date + timedelta(days=random.randint(1, 7))
            actual = (
                estimated + timedelta(days=random.randint(-2, 3))
                if random.random() > 0.3
                else "NULL"
            )

            actual_str = f"'{actual}'" if actual != "NULL" else actual
            shipment = (
                f"('SHIP{i+1:08d}', 'WH{random.randint(1, 10):03d}', "
                f"'{self.escape_sql(fake.address()[:255])}', "
                f"'{random.choice(statuses)}', '{shipped_date}', "
                f"'{estimated}', {actual_str}, "
                f"'{random.choice(carriers)}', "
                f"'{fake.uuid4()[:20]}')"
            )
            shipment_values.append(shipment)

        sql_lines.append(",\n".join(shipment_values) + ";")

        # Save file
        output_file = os.path.join(self.output_dir, "logistics_db_data.sql")
        with open(output_file, "w", encoding="utf-8") as f:
            f.write("\n".join(sql_lines))

        print(f"  Created: {output_file} (10 warehouses, {count} shipments)")
        return output_file

    def generate_education_data(self, count: int = 100):
        """Generate education/learning data"""
        print("Generating education data...")

        sql_lines = [
            "-- Demo data for education_db",
            "USE education_db;",
            "",
            "SET FOREIGN_KEY_CHECKS = 0;",
            "TRUNCATE TABLE courses;",
            "TRUNCATE TABLE students;",
            "TRUNCATE TABLE enrollments;",
            "SET FOREIGN_KEY_CHECKS = 1;",
            "",
            "-- Insert courses",
            "INSERT INTO courses (course_id, course_code, title, description, credits, department, instructor, capacity, schedule) VALUES",
        ]

        # Generate courses
        course_values = []
        departments = [
            "Computer Science",
            "Mathematics",
            "Physics",
            "Biology",
            "Chemistry",
            "English",
            "History",
            "Business",
        ]
        subjects = [
            "Introduction to",
            "Advanced",
            "Fundamentals of",
            "Applied",
            "Modern",
            "Theoretical",
        ]

        for i in range(count // 2):  # Fewer courses than students
            dept = random.choice(departments)
            course = (
                f"({i+1}, '{dept[:2].upper()}{random.randint(100, 499)}', "
                f"'{random.choice(subjects)} {dept}', "
                f"'{self.escape_sql(fake.text(max_nb_chars=200))}', "
                f"{random.choice([3, 4])}, '{dept}', "
                f"'Dr. {fake.last_name()}', {random.randint(20, 200)}, "
                f"'{random.choice(['MWF 9:00-10:00', 'TTh 14:00-15:30', 'MWF 14:00-15:00'])}')"
            )
            course_values.append(course)

        sql_lines.append(",\n".join(course_values) + ";")

        # Generate students
        sql_lines.append("\n-- Insert students")
        sql_lines.append(
            "INSERT INTO students (student_id, first_name, last_name, email, phone, date_of_birth, enrollment_date, major, gpa, credits_completed) VALUES"
        )

        student_values = []
        majors = departments  # Same as departments

        for i in range(count):
            student = (
                f"('STU{i+1:06d}', '{self.escape_sql(fake.first_name())}', "
                f"'{self.escape_sql(fake.last_name())}', "
                f"'{fake.email()}', '{fake.phone_number()[:20]}', "
                f"'{fake.date_of_birth(minimum_age=18, maximum_age=25)}', "
                f"'{fake.date_between(start_date='-4y', end_date='today')}', "
                f"'{random.choice(majors)}', "
                f"{round(random.uniform(2.0, 4.0), 2)}, "
                f"{random.randint(0, 120)})"
            )
            student_values.append(student)

        sql_lines.append(",\n".join(student_values) + ";")

        # Generate enrollments
        sql_lines.append("\n-- Insert enrollments")
        sql_lines.append(
            "INSERT INTO enrollments (student_id, course_id, semester, year, grade, status) VALUES"
        )

        enrollment_values = []
        grades = ["A", "A-", "B+", "B", "B-", "C+", "C", "C-", "D", "F", "W"]

        for i in range(count * 3):  # 3 enrollments per student average
            enrollment = (
                f"('STU{random.randint(1, count):06d}', "
                f"{random.randint(1, count//2)}, "
                f"'{random.choice(['Fall', 'Spring', 'Summer'])}', "
                f"{random.randint(2020, 2024)}, "
                f"'{random.choice(grades) if random.random() > 0.3 else 'NULL'}', "
                f"'{random.choice(['enrolled', 'completed', 'dropped'])}')"
            )
            enrollment_values.append(enrollment)

        sql_lines.append(",\n".join(enrollment_values) + ";")

        # Save file
        output_file = os.path.join(self.output_dir, "education_db_data.sql")
        with open(output_file, "w", encoding="utf-8") as f:
            f.write("\n".join(sql_lines))

        print(
            f"  Created: {output_file} ({count//2} courses, {count} students, {count*3} enrollments)"
        )
        return output_file

    def generate_food_delivery_data(self, count: int = 100):
        """Generate food delivery data"""
        print("Generating food delivery data...")

        sql_lines = [
            "-- Demo data for food_delivery_db",
            "USE food_delivery_db;",
            "",
            "SET FOREIGN_KEY_CHECKS = 0;",
            "TRUNCATE TABLE restaurants;",
            "TRUNCATE TABLE menu_items;",
            "TRUNCATE TABLE orders;",
            "TRUNCATE TABLE riders;",
            "SET FOREIGN_KEY_CHECKS = 1;",
            "",
            "-- Insert restaurants",
            "INSERT INTO restaurants (restaurant_id, name, cuisine_type, address, city, rating, delivery_time, minimum_order, delivery_fee, is_open) VALUES",
        ]

        # Generate restaurants
        restaurant_values = []
        cuisines = [
            "Italian",
            "Chinese",
            "Mexican",
            "Indian",
            "Japanese",
            "Thai",
            "American",
            "Mediterranean",
            "Korean",
            "Vietnamese",
        ]

        for i in range(count // 3):  # Fewer restaurants
            restaurant = (
                f"({i+1}, '{self.escape_sql(fake.company())} Restaurant', "
                f"'{random.choice(cuisines)}', "
                f"'{self.escape_sql(fake.street_address())}', '{fake.city()}', "
                f"{round(random.uniform(3.0, 5.0), 1)}, "
                f"{random.randint(20, 60)}, "
                f"{random.randint(10, 30)}, "
                f"{round(random.uniform(0, 5), 2)}, "
                f"{random.choice(['true', 'false'])}"
            )
            restaurant_values.append(restaurant)

        sql_lines.append(",\n".join(restaurant_values) + ";")

        # Generate menu items
        sql_lines.append("\n-- Insert menu items")
        sql_lines.append(
            "INSERT INTO menu_items (item_id, restaurant_id, name, description, category, price, is_available) VALUES"
        )

        menu_values = []
        food_items = [
            "Pizza",
            "Burger",
            "Pasta",
            "Salad",
            "Sandwich",
            "Soup",
            "Rice Bowl",
            "Noodles",
            "Tacos",
            "Sushi",
        ]
        categories = ["Appetizers", "Main Course", "Desserts", "Beverages", "Sides"]

        for i in range(count * 2):  # Many menu items
            item_name = f"{random.choice(['Special', 'Classic', 'Deluxe', 'Premium'])} {random.choice(food_items)}"
            menu = (
                f"({i+1}, {random.randint(1, count//3)}, "
                f"'{item_name}', "
                f"'{self.escape_sql(fake.text(max_nb_chars=100))}', "
                f"'{random.choice(categories)}', "
                f"{round(random.uniform(5, 50), 2)}, "
                f"{random.choice(['true', 'false'])}"
            )
            menu_values.append(menu)

        sql_lines.append(",\n".join(menu_values) + ";")

        # Save file
        output_file = os.path.join(self.output_dir, "food_delivery_db_data.sql")
        with open(output_file, "w", encoding="utf-8") as f:
            f.write("\n".join(sql_lines))

        print(
            f"  Created: {output_file} ({count//3} restaurants, {count*2} menu items)"
        )
        return output_file

    def generate_gaming_data(self, count: int = 100):
        """Generate gaming platform data"""
        print("Generating gaming platform data...")

        sql_lines = [
            "-- Demo data for gaming_platform_db",
            "USE gaming_platform_db;",
            "",
            "SET FOREIGN_KEY_CHECKS = 0;",
            "TRUNCATE TABLE games;",
            "TRUNCATE TABLE players;",
            "TRUNCATE TABLE sessions;",
            "TRUNCATE TABLE achievements;",
            "SET FOREIGN_KEY_CHECKS = 1;",
            "",
            "-- Insert games",
            "INSERT INTO games (game_id, title, genre, developer, publisher, release_date, rating, price, platform) VALUES",
        ]

        # Generate games
        game_values = []
        genres = [
            "Action",
            "Adventure",
            "RPG",
            "Strategy",
            "Puzzle",
            "Sports",
            "Racing",
            "Shooter",
            "Simulation",
        ]
        platforms = [
            "PC",
            "PlayStation",
            "Xbox",
            "Nintendo Switch",
            "Mobile",
            "Cross-platform",
        ]

        for i in range(count // 2):  # Fewer games
            game = (
                f"({i+1}, '{self.escape_sql(fake.catch_phrase())} Game', "
                f"'{random.choice(genres)}', "
                f"'{self.escape_sql(fake.company())}', "
                f"'{self.escape_sql(fake.company())}', "
                f"'{fake.date_between(start_date='-10y', end_date='today')}', "
                f"'{random.choice(['E', 'T', 'M', 'AO'])}', "
                f"{round(random.uniform(0, 70), 2)}, "
                f"'{random.choice(platforms)}')"
            )
            game_values.append(game)

        sql_lines.append(",\n".join(game_values) + ";")

        # Generate players
        sql_lines.append("\n-- Insert players")
        sql_lines.append(
            "INSERT INTO players (player_id, username, email, display_name, level, experience_points, total_playtime, created_at, last_login) VALUES"
        )

        player_values = []
        for i in range(count):
            username = fake.user_name()
            player = (
                f"({i+1}, '{username}', '{fake.email()}', "
                f"'{username}{random.randint(1, 999)}', "
                f"{random.randint(1, 100)}, "
                f"{random.randint(0, 1000000)}, "
                f"{random.randint(0, 10000)}, "
                f"'{fake.date_time_between(start_date='-3y', end_date='now')}', "
                f"'{fake.date_time_between(start_date='-7d', end_date='now')}')"
            )
            player_values.append(player)

        sql_lines.append(",\n".join(player_values) + ";")

        # Save file
        output_file = os.path.join(self.output_dir, "gaming_platform_db_data.sql")
        with open(output_file, "w", encoding="utf-8") as f:
            f.write("\n".join(sql_lines))

        print(f"  Created: {output_file} ({count//2} games, {count} players)")
        return output_file

    def generate_insurance_data(self, count: int = 100):
        """Generate insurance data"""
        print("Generating insurance data...")

        sql_lines = [
            "-- Demo data for insurance_db",
            "USE insurance_db;",
            "",
            "SET FOREIGN_KEY_CHECKS = 0;",
            "TRUNCATE TABLE policies;",
            "TRUNCATE TABLE claims;",
            "TRUNCATE TABLE customers;",
            "SET FOREIGN_KEY_CHECKS = 1;",
            "",
            "-- Insert customers",
            "INSERT INTO customers (customer_id, first_name, last_name, email, phone, date_of_birth, address, risk_score) VALUES",
        ]

        # Generate customers
        customer_values = []
        for i in range(count):
            customer = (
                f"({i+1}, '{self.escape_sql(fake.first_name())}', "
                f"'{self.escape_sql(fake.last_name())}', "
                f"'{fake.email()}', '{fake.phone_number()[:20]}', "
                f"'{fake.date_of_birth(minimum_age=18, maximum_age=70)}', "
                f"'{self.escape_sql(fake.address()[:255])}', "
                f"{round(random.uniform(0.1, 1.0), 2)})"
            )
            customer_values.append(customer)

        sql_lines.append(",\n".join(customer_values) + ";")

        # Generate policies
        sql_lines.append("\n-- Insert policies")
        sql_lines.append(
            "INSERT INTO policies (policy_number, customer_id, policy_type, start_date, end_date, premium_monthly, coverage_amount, deductible, status) VALUES"
        )

        policy_values = []
        policy_types = ["Auto", "Home", "Life", "Health", "Travel", "Business"]

        for i in range(count * 2):  # 2 policies per customer average
            start_date = fake.date_between(start_date="-2y", end_date="today")
            end_date = start_date + timedelta(days=365)

            policy = (
                f"('POL{i+1:08d}', {random.randint(1, count)}, "
                f"'{random.choice(policy_types)}', "
                f"'{start_date}', '{end_date}', "
                f"{round(random.uniform(50, 1000), 2)}, "
                f"{round(random.uniform(10000, 1000000), 2)}, "
                f"{round(random.uniform(250, 5000), 2)}, "
                f"'{random.choice(['active', 'expired', 'cancelled'])}')"
            )
            policy_values.append(policy)

        sql_lines.append(",\n".join(policy_values) + ";")

        # Save file
        output_file = os.path.join(self.output_dir, "insurance_db_data.sql")
        with open(output_file, "w", encoding="utf-8") as f:
            f.write("\n".join(sql_lines))

        print(f"  Created: {output_file} ({count} customers, {count*2} policies)")
        return output_file

    def generate_hotel_data(self, count: int = 100):
        """Generate hotel chain data"""
        print("Generating hotel chain data...")

        sql_lines = [
            "-- Demo data for hotel_chain_db",
            "USE hotel_chain_db;",
            "",
            "SET FOREIGN_KEY_CHECKS = 0;",
            "TRUNCATE TABLE hotels;",
            "TRUNCATE TABLE rooms;",
            "TRUNCATE TABLE bookings;",
            "TRUNCATE TABLE guests;",
            "SET FOREIGN_KEY_CHECKS = 1;",
            "",
            "-- Insert hotels",
            "INSERT INTO hotels (hotel_id, name, address, city, state, country, stars, total_rooms, amenities) VALUES",
        ]

        # Generate hotels
        hotel_values = []
        hotel_chains = ["Grand", "Royal", "Plaza", "Resort", "Inn", "Suites"]
        amenities_options = [
            "Pool",
            "Gym",
            "Spa",
            "Restaurant",
            "Bar",
            "WiFi",
            "Parking",
            "Conference Room",
        ]

        for i in range(20):  # Just 20 hotels
            amenities = ", ".join(
                random.sample(amenities_options, k=random.randint(3, 7))
            )
            hotel = (
                f"({i+1}, '{random.choice(hotel_chains)} {fake.city()}', "
                f"'{self.escape_sql(fake.street_address())}', "
                f"'{fake.city()}', '{fake.state_abbr()}', '{fake.country()}', "
                f"{random.randint(3, 5)}, {random.randint(50, 500)}, "
                f"'{amenities}')"
            )
            hotel_values.append(hotel)

        sql_lines.append(",\n".join(hotel_values) + ";")

        # Generate guests
        sql_lines.append("\n-- Insert guests")
        sql_lines.append(
            "INSERT INTO guests (guest_id, first_name, last_name, email, phone, passport_number, nationality, loyalty_points) VALUES"
        )

        guest_values = []
        for i in range(count):
            guest = (
                f"({i+1}, '{self.escape_sql(fake.first_name())}', "
                f"'{self.escape_sql(fake.last_name())}', "
                f"'{fake.email()}', '{fake.phone_number()[:20]}', "
                f"'{fake.uuid4()[:15]}', '{fake.country()}', "
                f"{random.randint(0, 10000)})"
            )
            guest_values.append(guest)

        sql_lines.append(",\n".join(guest_values) + ";")

        # Generate bookings
        sql_lines.append("\n-- Insert bookings")
        sql_lines.append(
            "INSERT INTO bookings (booking_id, guest_id, hotel_id, room_number, check_in, check_out, total_amount, status, booking_date) VALUES"
        )

        booking_values = []
        for i in range(count * 2):  # 2 bookings per guest average
            check_in = fake.date_between(start_date="-1y", end_date="+3m")
            check_out = check_in + timedelta(days=random.randint(1, 14))

            booking = (
                f"('BK{i+1:08d}', {random.randint(1, count)}, "
                f"{random.randint(1, 20)}, '{random.randint(100, 999)}', "
                f"'{check_in}', '{check_out}', "
                f"{round(random.uniform(100, 2000), 2)}, "
                f"'{random.choice(['confirmed', 'checked_in', 'checked_out', 'cancelled'])}', "
                f"'{fake.date_between(start_date='-2y', end_date='today')}')"
            )
            booking_values.append(booking)

        sql_lines.append(",\n".join(booking_values) + ";")

        # Save file
        output_file = os.path.join(self.output_dir, "hotel_chain_db_data.sql")
        with open(output_file, "w", encoding="utf-8") as f:
            f.write("\n".join(sql_lines))

        print(
            f"  Created: {output_file} (20 hotels, {count} guests, {count*2} bookings)"
        )
        return output_file

    def generate_all_additional(self, records_per_schema: int = 100):
        """Generate data for all additional schemas"""
        print("\n" + "=" * 60)
        print("Generating Additional Schema Data")
        print("=" * 60 + "\n")

        files_created = []

        # Generate all additional schemas
        files_created.append(self.generate_fintech_data(records_per_schema))
        files_created.append(self.generate_social_media_data(records_per_schema))
        files_created.append(self.generate_real_estate_data(records_per_schema))
        files_created.append(self.generate_logistics_data(records_per_schema))
        files_created.append(self.generate_education_data(records_per_schema))
        files_created.append(self.generate_food_delivery_data(records_per_schema))
        files_created.append(self.generate_gaming_data(records_per_schema))
        files_created.append(self.generate_insurance_data(records_per_schema))
        files_created.append(self.generate_hotel_data(records_per_schema))

        # Create master import script
        master_script = os.path.join(self.output_dir, "import_additional.sql")
        with open(master_script, "w", encoding="utf-8") as f:
            f.write("-- Master import script for additional schema data\n")
            f.write("-- Run this after creating the database schemas\n\n")
            for file in files_created:
                f.write(f"SOURCE {os.path.basename(file)};\n")

        print(f"\n  Created master script: {master_script}")

        # Update summary JSON
        summary_file = os.path.join(self.output_dir, "generation_summary.json")
        summary = {
            "generated_at": datetime.now().isoformat(),
            "files_created": files_created,
            "schemas": [
                "fintech_db",
                "social_media_db",
                "real_estate_db",
                "logistics_db",
                "education_db",
                "food_delivery_db",
                "gaming_platform_db",
                "insurance_db",
                "hotel_chain_db",
            ],
            "total_schemas": 12,  # Including the previous 3
            "estimated_records": records_per_schema * 20,
        }

        with open(summary_file, "w", encoding="utf-8") as f:
            json.dump(summary, f, indent=2)

        print(f"  Updated summary: {summary_file}")

        print("\n" + "=" * 60)
        print("Additional Schema Data Generation Complete!")
        print("=" * 60)
        print("\nGenerated data for 9 additional business domains:")
        for file in files_created:
            print(f"  - {os.path.basename(file)}")

        print("\nTo import all data (including previous):")
        print("  cd demo_data")
        print("  mysql -u root -p < import_all.sql")
        print("  mysql -u root -p < import_additional.sql")


def main():
    """Main execution"""
    import argparse

    parser = argparse.ArgumentParser(description="Generate additional schema SQL data")
    parser.add_argument(
        "--records",
        type=int,
        default=100,
        help="Number of records per schema (default: 100)",
    )
    parser.add_argument(
        "--output", default="demo_data", help="Output directory (default: demo_data)"
    )

    args = parser.parse_args()

    generator = ComprehensiveDataGenerator(args.output)
    generator.generate_all_additional(args.records)


if __name__ == "__main__":
    main()
