#!/usr/bin/env python3
"""
Event Ticketing Platform Data Generator
Generates realistic sample data for the event ticketing database schema
with dynamic pricing, seat management, and booking patterns
"""

import random
import json
import csv
import os
import sys
import math
import hashlib
import argparse
from datetime import datetime, timedelta, date, time
from typing import List, Dict, Any, Tuple, Optional
from decimal import Decimal
from pathlib import Path
from collections import defaultdict

# Required: pip install faker
from faker import Faker
from faker.providers import (
    person,
    address,
    phone_number,
    company,
    date_time,
    python,
    lorem,
    internet,
)


class EventTicketingDataGenerator:
    def __init__(self, config_path: str = "config.json"):
        """Initialize the generator with configuration"""
        self.fake = Faker("en_US")
        self.fake.add_provider(person)
        self.fake.add_provider(address)
        self.fake.add_provider(phone_number)
        self.fake.add_provider(company)
        self.fake.add_provider(date_time)
        self.fake.add_provider(python)
        self.fake.add_provider(lorem)
        self.fake.add_provider(internet)

        # Load configuration
        with open(config_path, "r") as f:
            self.config = json.load(f)

        # Set seed for reproducibility
        random.seed(self.config["seed"])
        Faker.seed(self.config["seed"])

        # Data storage
        self.venues = []
        self.venue_sections = []
        self.venue_rows = []
        self.venue_seats = []
        self.event_categories = []
        self.performers = []
        self.events = []
        self.performances = []
        self.performance_pricing = []
        self.event_performers = []
        self.customers = []
        self.customer_preferences = []
        self.loyalty_members = []
        self.payment_methods = []
        self.tickets = []
        self.ticket_holds = []
        self.booking_transactions = []
        self.booking_items = []
        self.payment_transactions = []
        self.promotional_codes = []
        self.applied_discounts = []
        self.price_tiers = []
        self.dynamic_pricing_logs = []
        self.shopping_carts = []
        self.cart_items = []
        self.abandoned_carts = []
        self.ticket_transfers = []
        self.ticket_scans = []
        self.resale_listings = []
        self.resale_transactions = []
        self.sales_metrics = []
        self.venue_utilization = []
        self.customer_analytics = []
        self.fraud_attempts = []

        # Counters for IDs
        self.counters = defaultdict(lambda: 1)

        # Venue and seating cache
        self.seat_cache = {}  # venue_id -> sections -> rows -> seats
        self.performance_seats = {}  # performance_id -> set of booked seat_ids

        # Performance names for events
        self.event_name_parts = {
            "Music": {
                "prefixes": [
                    "Summer",
                    "Winter",
                    "Spring",
                    "Fall",
                    "Annual",
                    "World",
                    "Ultimate",
                    "Epic",
                ],
                "suffixes": [
                    "Tour",
                    "Festival",
                    "Concert",
                    "Live",
                    "Experience",
                    "Showcase",
                    "Jam",
                    "Fest",
                ],
            },
            "Sports": {
                "prefixes": [
                    "Championship",
                    "Premier",
                    "Elite",
                    "Pro",
                    "National",
                    "International",
                ],
                "suffixes": [
                    "Game",
                    "Match",
                    "Tournament",
                    "Series",
                    "Finals",
                    "Playoffs",
                    "Cup",
                ],
            },
            "Theater": {
                "prefixes": ["Broadway", "Classic", "Modern", "Original", "Revival"],
                "suffixes": ["Musical", "Play", "Performance", "Show", "Production"],
            },
            "Comedy": {
                "prefixes": ["Late Night", "Stand-up", "Comedy", "Laugh"],
                "suffixes": ["Show", "Special", "Night", "Hour", "Tour"],
            },
            "Conference": {
                "prefixes": ["Annual", "Global", "International", "Tech", "Innovation"],
                "suffixes": [
                    "Summit",
                    "Conference",
                    "Expo",
                    "Convention",
                    "Forum",
                    "Symposium",
                ],
            },
            "Family": {
                "prefixes": ["Amazing", "Magical", "Wonderful", "Spectacular"],
                "suffixes": [
                    "Show",
                    "Adventure",
                    "Experience",
                    "Spectacular",
                    "On Ice",
                ],
            },
        }

        # Artist/performer names
        self.performer_first_names = [
            "The",
            "DJ",
            "MC",
            "Sir",
            "Lady",
            "Dr.",
            "Professor",
        ]
        self.performer_last_names = [
            "Stars",
            "Band",
            "Orchestra",
            "Ensemble",
            "Collective",
            "Experience",
            "Project",
        ]

    def generate_venues(self):
        """Generate venue configurations with detailed seating"""
        print("  Generating venues...")

        venue_names = {
            "stadium": ["Stadium", "Field", "Park", "Dome", "Coliseum"],
            "arena": ["Arena", "Center", "Pavilion", "Forum"],
            "theater": ["Theater", "Theatre", "Playhouse", "Opera House"],
            "concert_hall": [
                "Music Hall",
                "Symphony Hall",
                "Concert Hall",
                "Auditorium",
            ],
            "club": ["Club", "Lounge", "Venue", "Room", "Stage"],
            "conference_center": [
                "Convention Center",
                "Conference Center",
                "Expo Center",
            ],
        }

        for _ in range(self.config["counts"]["venues"]):
            venue_id = self.counters["venue"]
            self.counters["venue"] += 1

            # Select venue type based on distribution
            venue_type = self._weighted_choice(
                list(self.config["venue_types"].keys()),
                [
                    self.config["venue_types"][vt]["distribution"]
                    for vt in self.config["venue_types"].keys()
                ],
            )

            venue_config = self.config["venue_types"][venue_type]
            capacity = random.randint(
                venue_config["capacity_min"], venue_config["capacity_max"]
            )

            # Generate venue name
            city_prefix = self.fake.city()
            venue_suffix = random.choice(venue_names[venue_type])
            venue_name = f"{city_prefix} {venue_suffix}"

            venue = {
                "venue_id": venue_id,
                "venue_name": venue_name,
                "venue_type": venue_type,
                "address_line1": self.fake.street_address(),
                "address_line2": (
                    self.fake.secondary_address() if random.random() > 0.7 else None
                ),
                "city": self.fake.city(),
                "state_province": self.fake.state(),
                "postal_code": self.fake.zipcode(),
                "country": "United States",
                "latitude": float(self.fake.latitude()),
                "longitude": float(self.fake.longitude()),
                "capacity": capacity,
                "phone": self.fake.phone_number(),
                "email": f"info@{venue_name.lower().replace(' ', '')}.com",
                "website": f"www.{venue_name.lower().replace(' ', '')}.com",
                "parking_info": f"{random.randint(500, 5000)} parking spaces available. ${random.randint(10, 30)} event parking.",
                "public_transport_info": f"Metro: {self.fake.street_name()} Station (5 min walk)",
                "accessibility_info": "ADA compliant with wheelchair accessible seating and facilities",
                "venue_rules": "No outside food/drinks. No professional cameras. No smoking.",
                "is_active": True,
            }

            self.venues.append(venue)

            # Generate seating configuration
            self._generate_venue_seating(
                venue_id, venue_type, capacity, venue_config["sections"]
            )

    def _generate_venue_seating(
        self,
        venue_id: int,
        venue_type: str,
        total_capacity: int,
        section_types: List[str],
    ):
        """Generate detailed seating configuration for a venue"""

        self.seat_cache[venue_id] = {}
        remaining_capacity = total_capacity
        sections_count = min(
            len(section_types), self.config["counts"]["sections_per_venue"]
        )

        # Distribute capacity across sections
        capacities = []
        for i in range(sections_count):
            if i == sections_count - 1:
                section_capacity = remaining_capacity
            else:
                section_capacity = int(remaining_capacity * random.uniform(0.15, 0.35))
            capacities.append(section_capacity)
            remaining_capacity -= section_capacity

        # Create sections
        for i, section_type in enumerate(section_types[:sections_count]):
            section_id = self.counters["section"]
            self.counters["section"] += 1

            section_capacity = capacities[i]

            # Section naming based on type
            if section_type in ["orchestra", "mezzanine", "balcony"]:
                section_name = section_type.title()
            elif section_type in ["floor", "standing", "general_admission"]:
                section_name = section_type.replace("_", " ").title()
            else:
                section_name = f"Section {chr(65 + i)}"  # Section A, B, C...

            # Determine view quality based on section type
            view_quality_map = {
                "orchestra": "excellent",
                "floor": "excellent",
                "club": "excellent",
                "suite": "excellent",
                "mezzanine": "good",
                "lower_bowl": "good",
                "balcony": "standard",
                "upper_bowl": "standard",
                "standing": "standard",
                "general_admission": "standard",
            }

            section = {
                "section_id": section_id,
                "venue_id": venue_id,
                "section_name": section_name,
                "section_type": section_type,
                "capacity": section_capacity,
                "rows_count": 0,  # Will be updated
                "default_price_tier": random.choice(
                    ["VIP", "Premium", "Standard", "Economy"]
                ),
                "entry_gate": f"Gate {chr(65 + (i % 4))}",
                "is_accessible": random.random() > 0.7,
                "view_quality": view_quality_map.get(section_type, "standard"),
            }

            self.venue_sections.append(section)
            self.seat_cache[venue_id][section_id] = {}

            # Generate rows and seats for non-GA sections
            if section_type not in ["standing", "general_admission"]:
                self._generate_rows_and_seats(section_id, section_capacity, venue_type)
                # Update rows count
                section["rows_count"] = len(self.seat_cache[venue_id][section_id])

    def _generate_rows_and_seats(
        self, section_id: int, section_capacity: int, venue_type: str
    ):
        """Generate rows and individual seats for a section"""

        # Calculate rows and seats distribution
        if venue_type in ["stadium", "arena"]:
            avg_seats_per_row = random.randint(20, 40)
        elif venue_type in ["theater", "concert_hall"]:
            avg_seats_per_row = random.randint(15, 30)
        else:
            avg_seats_per_row = random.randint(10, 25)

        rows_needed = max(1, section_capacity // avg_seats_per_row)

        remaining_seats = section_capacity
        venue_id = next(
            s["venue_id"] for s in self.venue_sections if s["section_id"] == section_id
        )

        for row_num in range(rows_needed):
            row_id = self.counters["row"]
            self.counters["row"] += 1

            # Row naming (letters for small venues, numbers for large)
            if venue_type in ["theater", "concert_hall"] and row_num < 26:
                row_number = chr(65 + row_num)  # A, B, C...
            else:
                row_number = str(row_num + 1)

            # Calculate seats in this row
            if row_num == rows_needed - 1:
                seats_in_row = remaining_seats
            else:
                seats_in_row = min(
                    avg_seats_per_row + random.randint(-5, 5), remaining_seats
                )

            row = {
                "row_id": row_id,
                "section_id": section_id,
                "row_number": row_number,
                "seats_count": seats_in_row,
                "is_accessible": row_num == 0
                and random.random() > 0.5,  # First row often accessible
            }

            self.venue_rows.append(row)
            self.seat_cache[venue_id][section_id][row_id] = []

            # Generate individual seats
            for seat_num in range(seats_in_row):
                seat_id = self.counters["seat"]
                self.counters["seat"] += 1

                # Determine seat type
                if row["is_accessible"] and seat_num < 4:
                    seat_type = random.choice(["accessible", "companion"])
                elif random.random() < 0.05:
                    seat_type = "obstructed_view"
                elif random.random() < 0.1:
                    seat_type = "premium"
                else:
                    seat_type = "standard"

                seat = {
                    "seat_id": seat_id,
                    "row_id": row_id,
                    "seat_number": str(seat_num + 1),
                    "seat_type": seat_type,
                    "x_coordinate": seat_num * 30,  # For visualization
                    "y_coordinate": row_num * 40,
                    "is_aisle": seat_num == 0
                    or seat_num == seats_in_row - 1
                    or (seats_in_row > 20 and seat_num == seats_in_row // 2),
                    "notes": (
                        "Limited leg room" if seat_type == "obstructed_view" else None
                    ),
                }

                self.venue_seats.append(seat)
                self.seat_cache[venue_id][section_id][row_id].append(seat_id)

            remaining_seats -= seats_in_row

    def generate_event_categories(self):
        """Generate event category hierarchy"""
        print("  Generating event categories...")

        for main_category in self.config["event_categories"]:
            # Create main category
            main_id = self.counters["category"]
            self.counters["category"] += 1

            self.event_categories.append(
                {
                    "category_id": main_id,
                    "category_name": main_category["name"],
                    "parent_category_id": None,
                    "description": f"All {main_category['name']} events",
                }
            )

            # Create subcategories
            for subcat in main_category["subcategories"]:
                subcat_id = self.counters["category"]
                self.counters["category"] += 1

                self.event_categories.append(
                    {
                        "category_id": subcat_id,
                        "category_name": subcat,
                        "parent_category_id": main_id,
                        "description": f"{subcat} events and performances",
                    }
                )

    def generate_performers(self):
        """Generate performers and artists"""
        print("  Generating performers...")

        performer_types = ["artist", "band", "team", "speaker", "company", "other"]

        for _ in range(self.config["counts"]["performers"]):
            performer_id = self.counters["performer"]
            self.counters["performer"] += 1

            performer_type = random.choice(performer_types)

            # Generate performer name based on type
            if performer_type == "artist":
                name = self.fake.name()
            elif performer_type == "band":
                name = f"{random.choice(self.performer_first_names)} {self.fake.last_name()} {random.choice(self.performer_last_names)}"
            elif performer_type == "team":
                name = f"{self.fake.city()} {random.choice(['Lions', 'Tigers', 'Bears', 'Eagles', 'Hawks', 'Wolves', 'Knights', 'Warriors'])}"
            elif performer_type == "speaker":
                name = f"Dr. {self.fake.name()}"
            elif performer_type == "company":
                name = self.fake.company()
            else:
                name = f"{self.fake.catch_phrase()} Show"

            # Select genre based on performer type
            genre_map = {
                "artist": [
                    "Pop",
                    "Rock",
                    "Jazz",
                    "Classical",
                    "Electronic",
                    "Hip-Hop",
                    "Country",
                ],
                "band": ["Rock", "Pop", "Metal", "Punk", "Indie", "Alternative"],
                "team": ["Basketball", "Hockey", "Baseball", "Football", "Soccer"],
                "speaker": [
                    "Technology",
                    "Business",
                    "Motivation",
                    "Science",
                    "Politics",
                ],
                "company": ["Theater", "Dance", "Circus", "Magic"],
                "other": ["Comedy", "Family", "Variety"],
            }

            genre = random.choice(genre_map.get(performer_type, ["Other"]))

            performer = {
                "performer_id": performer_id,
                "performer_name": name,
                "performer_type": performer_type,
                "genre": genre,
                "bio": self.fake.paragraph(nb_sentences=5),
                "image_url": f"https://images.ticketing.com/performers/{performer_id}.jpg",
                "website": f"www.{name.lower().replace(' ', '').replace('.', '')}.com",
                "social_media": json.dumps(
                    {
                        "twitter": f"@{name.lower().replace(' ', '')}",
                        "instagram": f"@{name.lower().replace(' ', '')}",
                        "facebook": f"/{name.lower().replace(' ', '')}",
                    }
                ),
            }

            self.performers.append(performer)

    def generate_events(self):
        """Generate events with multiple performances"""
        print("  Generating events and performances...")

        for _ in range(self.config["counts"]["events"]):
            event_id = self.counters["event"]
            self.counters["event"] += 1

            # Select category
            main_categories = [
                c for c in self.event_categories if c["parent_category_id"] is None
            ]
            main_category = random.choice(main_categories)
            subcategories = [
                c
                for c in self.event_categories
                if c["parent_category_id"] == main_category["category_id"]
            ]
            category = random.choice(subcategories) if subcategories else main_category

            # Generate event name
            event_type = random.choice(
                ["single", "tour", "season", "festival", "conference"]
            )

            name_parts = self.event_name_parts.get(
                main_category["category_name"], self.event_name_parts["Music"]
            )
            event_name = f"{random.choice(name_parts['prefixes'])} {self.fake.catch_phrase()} {random.choice(name_parts['suffixes'])}"

            # Age restriction based on category
            age_restrictions = {
                "Comedy": random.choice(["18+", "21+", "All Ages"]),
                "Family": "All Ages",
                "Music": random.choice(["All Ages", "18+", "21+"]),
                "Sports": "All Ages",
                "Theater": random.choice(["All Ages", "13+", "Mature"]),
                "Conference": "18+",
            }

            event = {
                "event_id": event_id,
                "event_name": event_name,
                "event_type": event_type,
                "category_id": category["category_id"],
                "description": self.fake.paragraph(nb_sentences=6),
                "image_url": f"https://images.ticketing.com/events/{event_id}.jpg",
                "banner_url": f"https://images.ticketing.com/events/{event_id}_banner.jpg",
                "age_restriction": age_restrictions.get(
                    main_category["category_name"], "All Ages"
                ),
                "duration_minutes": random.choice([60, 90, 120, 150, 180, 240]),
                "organizer_name": self.fake.company(),
                "organizer_contact": self.fake.email(),
                "is_featured": random.random() > 0.8,
            }

            self.events.append(event)

            # Link performers to events
            num_performers = random.randint(1, 3)
            selected_performers = random.sample(
                self.performers, min(num_performers, len(self.performers))
            )

            for i, performer in enumerate(selected_performers):
                self.event_performers.append(
                    {
                        "event_performer_id": self.counters["event_performer"],
                        "event_id": event_id,
                        "performer_id": performer["performer_id"],
                        "is_headliner": i == 0,
                        "performance_order": i + 1,
                    }
                )
                self.counters["event_performer"] += 1

            # Generate performances for this event
            self._generate_performances(event)

    def _generate_performances(self, event: Dict):
        """Generate individual performances for an event"""

        # Determine number of performances based on event type
        if event["event_type"] == "single":
            num_performances = 1
        elif event["event_type"] == "tour":
            num_performances = random.randint(5, 20)
        elif event["event_type"] == "season":
            num_performances = random.randint(10, 40)
        elif event["event_type"] == "festival":
            num_performances = random.randint(3, 10)
        else:  # conference
            num_performances = random.randint(1, 5)

        # Generate performances across different venues
        for _ in range(num_performances):
            performance_id = self.counters["performance"]
            self.counters["performance"] += 1

            venue = random.choice(self.venues)

            # Schedule performance
            days_ahead = random.randint(
                1, self.config["date_ranges"]["performance_window"]
            )
            performance_date = datetime.now() + timedelta(days=days_ahead)

            # Performance time based on day of week
            if performance_date.weekday() in [4, 5]:  # Friday, Saturday
                hour = random.choice([19, 20, 21])  # Evening shows
            elif performance_date.weekday() == 6:  # Sunday
                hour = random.choice([14, 15, 19])  # Matinee or evening
            else:  # Weekdays
                hour = random.choice([19, 20])  # Evening shows

            performance_datetime = performance_date.replace(
                hour=hour, minute=0, second=0, microsecond=0
            )
            doors_open = performance_datetime - timedelta(hours=1)

            # Determine performance status
            if performance_date < datetime.now():
                status = "completed"
            elif performance_date < datetime.now() + timedelta(days=7):
                status = random.choice(["on_sale", "sold_out"])
            else:
                status = random.choice(["scheduled", "on_sale"])

            # Calculate pricing
            base_price = random.uniform(
                self.config["pricing"]["base_price_min"],
                self.config["pricing"]["base_price_max"],
            )

            # Apply dynamic pricing factors
            day_factor = self._get_day_of_week_factor(performance_datetime)
            demand_factor = random.uniform(0.8, 1.5)

            min_price = base_price * 0.5 * day_factor * demand_factor
            max_price = base_price * 3 * day_factor * demand_factor

            performance = {
                "performance_id": performance_id,
                "event_id": event["event_id"],
                "venue_id": venue["venue_id"],
                "performance_datetime": performance_datetime,
                "doors_open_datetime": doors_open,
                "performance_status": status,
                "total_capacity": venue["capacity"],
                "available_capacity": (
                    int(venue["capacity"] * random.uniform(0, 0.8))
                    if status == "on_sale"
                    else 0
                ),
                "min_ticket_price": round(min_price, 2),
                "max_ticket_price": round(max_price, 2),
                "sales_start_datetime": performance_datetime
                - timedelta(days=random.randint(30, 90)),
                "sales_end_datetime": performance_datetime + timedelta(hours=2),
                "is_general_admission": venue["venue_type"] == "club"
                or random.random() < 0.1,
                "notes": None if random.random() > 0.3 else "Special guest appearance",
            }

            self.performances.append(performance)
            self.performance_seats[performance_id] = set()

            # Generate pricing tiers for this performance
            self._generate_performance_pricing(
                performance_id, venue["venue_id"], min_price, max_price
            )

    def _generate_performance_pricing(
        self, performance_id: int, venue_id: int, min_price: float, max_price: float
    ):
        """Generate pricing tiers for a performance"""

        sections = [s for s in self.venue_sections if s["venue_id"] == venue_id]

        price_range = max_price - min_price

        for section in sections:
            # Price based on section quality
            quality_multiplier = {
                "excellent": 1.0,
                "good": 0.7,
                "standard": 0.5,
                "obstructed": 0.3,
            }

            base_multiplier = quality_multiplier.get(section["view_quality"], 0.5)
            section_price = min_price + (price_range * base_multiplier)

            # Create price tiers within section
            tiers = ["VIP", "Premium", "Standard", "Economy"]

            for i, tier in enumerate(tiers):
                tier_id = self.counters["price_tier"]
                self.counters["price_tier"] += 1

                tier_multiplier = 1.5 - (
                    i * 0.2
                )  # VIP=1.5, Premium=1.3, Standard=1.1, Economy=0.9
                tier_price = section_price * tier_multiplier

                self.price_tiers.append(
                    {
                        "tier_id": tier_id,
                        "performance_id": performance_id,
                        "section_id": section["section_id"],
                        "tier_name": tier,
                        "base_price": round(tier_price, 2),
                        "service_fee": round(
                            tier_price
                            * self.config["pricing"]["service_fee_percentage"],
                            2,
                        ),
                        "facility_fee": self.config["pricing"]["facility_fee"],
                        "processing_fee": self.config["pricing"]["processing_fee"],
                        "total_price": round(
                            tier_price
                            * (1 + self.config["pricing"]["service_fee_percentage"])
                            + self.config["pricing"]["facility_fee"]
                            + self.config["pricing"]["processing_fee"],
                            2,
                        ),
                    }
                )

    def generate_customers(self):
        """Generate customer accounts"""
        print("  Generating customers...")

        for _ in range(self.config["counts"]["customers"]):
            customer_id = self.counters["customer"]
            self.counters["customer"] += 1

            # Generate customer profile
            first_name = self.fake.first_name()
            last_name = self.fake.last_name()
            email = f"{first_name.lower()}.{last_name.lower()}@{self.fake.free_email_domain()}"

            customer = {
                "customer_id": customer_id,
                "email": email,
                "password_hash": hashlib.sha256(
                    self.fake.password().encode()
                ).hexdigest(),
                "first_name": first_name,
                "last_name": last_name,
                "phone": self.fake.phone_number(),
                "date_of_birth": self.fake.date_of_birth(
                    minimum_age=18, maximum_age=80
                ),
                "address_line1": self.fake.street_address(),
                "address_line2": (
                    self.fake.secondary_address() if random.random() > 0.7 else None
                ),
                "city": self.fake.city(),
                "state_province": self.fake.state(),
                "postal_code": self.fake.zipcode(),
                "country": "United States",
                "email_verified": random.random() > 0.2,
                "phone_verified": random.random() > 0.5,
                "marketing_consent": random.random() > 0.4,
                "created_at": self.fake.date_time_between(
                    start_date="-2y", end_date="now"
                ),
                "last_login": self.fake.date_time_between(
                    start_date="-30d", end_date="now"
                ),
            }

            self.customers.append(customer)

            # Generate customer preferences
            self._generate_customer_preferences(customer_id)

            # Generate payment methods
            self._generate_payment_methods(customer_id)

            # Create loyalty member if applicable
            if (
                random.random()
                < self.config["customer_behavior"]["loyalty_signup_rate"]
            ):
                self._generate_loyalty_member(customer_id)

    def _generate_customer_preferences(self, customer_id: int):
        """Generate customer preferences for personalization"""

        pref_id = self.counters["preference"]
        self.counters["preference"] += 1

        # Select favorite categories
        main_categories = [
            c["category_name"]
            for c in self.event_categories
            if c["parent_category_id"] is None
        ]
        num_favorites = min(random.randint(1, 3), len(main_categories))
        categories = (
            random.sample(main_categories, k=num_favorites) if main_categories else []
        )

        self.customer_preferences.append(
            {
                "preference_id": pref_id,
                "customer_id": customer_id,
                "favorite_categories": json.dumps(categories),
                "favorite_venues": json.dumps(
                    random.sample(
                        [v["venue_id"] for v in self.venues], k=min(3, len(self.venues))
                    )
                ),
                "price_range_min": random.choice([25, 50, 75, 100]),
                "price_range_max": random.choice([100, 200, 300, 500, 1000]),
                "preferred_days": json.dumps(
                    random.sample(
                        [
                            "Monday",
                            "Tuesday",
                            "Wednesday",
                            "Thursday",
                            "Friday",
                            "Saturday",
                            "Sunday",
                        ],
                        k=3,
                    )
                ),
                "notification_frequency": random.choice(
                    ["daily", "weekly", "monthly", "never"]
                ),
                "language": "en",
            }
        )

    def _generate_payment_methods(self, customer_id: int):
        """Generate payment methods for a customer"""

        num_methods = random.randint(1, 2)

        for i in range(num_methods):
            payment_id = self.counters["payment_method"]
            self.counters["payment_method"] += 1

            payment_type = self._weighted_choice(
                list(self.config["customer_behavior"]["payment_methods"].keys()),
                list(self.config["customer_behavior"]["payment_methods"].values()),
            )

            # Generate card details (masked)
            if payment_type in ["credit_card", "debit_card"]:
                card_brands = ["Visa", "Mastercard", "Amex", "Discover"]
                brand = random.choice(card_brands)
                last_four = str(random.randint(1000, 9999))
            else:
                brand = payment_type
                last_four = None

            self.payment_methods.append(
                {
                    "payment_method_id": payment_id,
                    "customer_id": customer_id,
                    "payment_type": payment_type,
                    "card_brand": brand,
                    "last_four_digits": last_four,
                    "expiry_month": random.randint(1, 12),
                    "expiry_year": random.randint(2024, 2029),
                    "billing_name": f"{self.customers[customer_id-1]['first_name']} {self.customers[customer_id-1]['last_name']}",
                    "billing_address": self.customers[customer_id - 1]["address_line1"],
                    "is_default": i == 0,
                    "is_active": True,
                }
            )

    def _generate_loyalty_member(self, customer_id: int):
        """Generate loyalty program membership"""

        member_id = self.counters["loyalty"]
        self.counters["loyalty"] += 1

        tiers = ["Bronze", "Silver", "Gold", "Platinum"]
        tier = random.choices(tiers, weights=[0.5, 0.3, 0.15, 0.05])[0]

        self.loyalty_members.append(
            {
                "member_id": member_id,
                "customer_id": customer_id,
                "member_number": f"LM{customer_id:06d}",
                "tier": tier,
                "points_balance": random.randint(0, 10000),
                "lifetime_points": random.randint(0, 50000),
                "join_date": self.customers[customer_id - 1]["created_at"],
                "expiry_date": datetime.now() + timedelta(days=365),
                "benefits": json.dumps(
                    {
                        "early_access": tier in ["Gold", "Platinum"],
                        "discount_percentage": {
                            "Bronze": 5,
                            "Silver": 10,
                            "Gold": 15,
                            "Platinum": 20,
                        }[tier],
                        "free_fees": tier == "Platinum",
                    }
                ),
            }
        )

    def generate_bookings(self):
        """Generate ticket bookings and transactions"""
        print("  Generating bookings and tickets...")

        # Get performances available for booking
        available_performances = [
            p
            for p in self.performances
            if p["performance_status"] in ["on_sale", "sold_out"]
        ]

        total_bookings = min(
            self.config["counts"]["total_tickets"]
            // 3,  # Average 3 tickets per booking
            len(available_performances) * 50,  # Max 50 bookings per performance
        )

        for _ in range(total_bookings):
            self._generate_booking()

    def _generate_booking(self):
        """Generate a single booking with tickets"""

        booking_id = self.counters["booking"]
        self.counters["booking"] += 1

        # Select customer and performance
        customer = random.choice(self.customers)
        performance = random.choice(self.performances)

        # Determine number of tickets
        num_tickets = min(
            random.choices(
                [1, 2, 3, 4, 5, 6, 8, 10],
                weights=[0.2, 0.35, 0.15, 0.15, 0.05, 0.05, 0.03, 0.02],
            )[0],
            10,  # Max tickets per booking
        )

        # Check if group booking
        is_group = (
            num_tickets >= self.config["booking_patterns"]["group_booking_threshold"]
        )

        # Calculate booking time relative to performance
        perf_datetime = performance["performance_datetime"]
        if isinstance(perf_datetime, str):
            perf_datetime = datetime.fromisoformat(perf_datetime)

        days_before = random.randint(1, 60)
        booking_datetime = perf_datetime - timedelta(days=days_before)

        # Select payment method
        payment_method = random.choice(
            [
                pm
                for pm in self.payment_methods
                if pm["customer_id"] == customer["customer_id"]
            ]
        )

        # Calculate totals
        tickets_data = []
        subtotal = 0

        for _ in range(num_tickets):
            ticket_data = self._create_ticket(performance, customer["customer_id"])
            if ticket_data:
                tickets_data.append(ticket_data)
                subtotal += ticket_data["price"]

        if not tickets_data:
            return  # No seats available

        # Apply discounts
        discount_amount = 0
        promo_code = None

        if random.random() < 0.2:  # 20% chance of using promo code
            promo_code = self._get_or_create_promo_code()
            if promo_code:
                discount_amount = subtotal * promo_code["discount_percentage"] / 100

        # Add fees
        service_fee = subtotal * self.config["pricing"]["service_fee_percentage"]
        facility_fee = self.config["pricing"]["facility_fee"] * num_tickets
        processing_fee = self.config["pricing"]["processing_fee"]

        total = subtotal - discount_amount + service_fee + facility_fee + processing_fee

        # Create booking transaction
        booking = {
            "booking_id": booking_id,
            "customer_id": customer["customer_id"],
            "booking_reference": f"BK{booking_id:08d}",
            "booking_datetime": booking_datetime,
            "booking_status": random.choices(
                ["confirmed", "cancelled", "refunded"], weights=[0.9, 0.08, 0.02]
            )[0],
            "payment_method_id": payment_method["payment_method_id"],
            "subtotal": round(subtotal, 2),
            "discount_amount": round(discount_amount, 2),
            "service_fee": round(service_fee, 2),
            "facility_fee": round(facility_fee, 2),
            "processing_fee": round(processing_fee, 2),
            "tax_amount": round(total * 0.08, 2),  # 8% tax
            "total_amount": round(total * 1.08, 2),
            "currency": "USD",
            "promo_code": promo_code["code"] if promo_code else None,
            "is_group_booking": is_group,
            "delivery_method": self._weighted_choice(
                list(self.config["customer_behavior"]["ticket_delivery"].keys()),
                list(self.config["customer_behavior"]["ticket_delivery"].values()),
            ),
            "ip_address": self.fake.ipv4(),
            "user_agent": self.fake.user_agent(),
        }

        self.booking_transactions.append(booking)

        # Create tickets
        for ticket_data in tickets_data:
            ticket_id = self.counters["ticket"]
            self.counters["ticket"] += 1

            ticket = {
                "ticket_id": ticket_id,
                "booking_id": booking_id,
                "performance_id": performance["performance_id"],
                "seat_id": ticket_data["seat_id"],
                "ticket_number": f"TK{ticket_id:010d}",
                "barcode": hashlib.md5(f"TK{ticket_id}".encode()).hexdigest(),
                "price": ticket_data["price"],
                "ticket_status": (
                    "valid"
                    if booking["booking_status"] == "confirmed"
                    else booking["booking_status"]
                ),
                "is_resale": False,
                "original_price": ticket_data["price"],
            }

            self.tickets.append(ticket)

            # Mark seat as booked
            self.performance_seats[performance["performance_id"]].add(
                ticket_data["seat_id"]
            )

        # Create payment transaction
        self._create_payment_transaction(booking)

        # Generate ticket transfer or resale
        if booking["booking_status"] == "confirmed":
            if random.random() < self.config["booking_patterns"]["transfer_rate"]:
                self._generate_ticket_transfer(booking_id)
            elif random.random() < self.config["booking_patterns"]["resale_rate"]:
                self._generate_resale_listing(booking_id)

    def _create_ticket(self, performance: Dict, customer_id: int) -> Optional[Dict]:
        """Create a single ticket with seat selection"""

        venue_id = performance["venue_id"]

        # Get available sections
        sections = [s for s in self.venue_sections if s["venue_id"] == venue_id]
        if not sections:
            return None

        # Try to find an available seat
        for _ in range(10):  # Try up to 10 times
            section = random.choice(sections)

            if section["section_type"] in ["standing", "general_admission"]:
                # No specific seat for GA
                return {
                    "seat_id": None,
                    "section_id": section["section_id"],
                    "price": random.uniform(50, 200),
                }

            # Find available seat in section
            if section["section_id"] in self.seat_cache.get(venue_id, {}):
                rows = self.seat_cache[venue_id][section["section_id"]]

                for row_id, seats in rows.items():
                    available_seats = [
                        s
                        for s in seats
                        if s
                        not in self.performance_seats[performance["performance_id"]]
                    ]

                    if available_seats:
                        seat_id = random.choice(available_seats)

                        # Get price for this section/tier
                        price_tier = random.choice(
                            [
                                pt
                                for pt in self.price_tiers
                                if pt["performance_id"] == performance["performance_id"]
                                and pt["section_id"] == section["section_id"]
                            ]
                        )

                        return {
                            "seat_id": seat_id,
                            "section_id": section["section_id"],
                            "price": (
                                price_tier["base_price"]
                                if price_tier
                                else random.uniform(50, 200)
                            ),
                        }

        return None  # No available seats found

    def _get_or_create_promo_code(self) -> Optional[Dict]:
        """Get existing or create new promotional code"""

        if not self.promotional_codes:
            # Create some promotional codes
            for _ in range(self.config["counts"]["promotional_codes"]):
                promo_id = self.counters["promo"]
                self.counters["promo"] += 1

                code_types = ["SAVE", "DEAL", "SPECIAL", "DISCOUNT", "PROMO"]
                code = f"{random.choice(code_types)}{random.randint(10, 99)}"

                self.promotional_codes.append(
                    {
                        "promo_id": promo_id,
                        "code": code,
                        "description": f"{random.randint(5, 25)}% off select events",
                        "discount_percentage": random.choice([5, 10, 15, 20, 25]),
                        "discount_amount": None,
                        "valid_from": datetime.now() - timedelta(days=30),
                        "valid_until": datetime.now() + timedelta(days=90),
                        "usage_limit": random.randint(100, 1000),
                        "usage_count": 0,
                        "min_purchase": random.choice([0, 50, 100]),
                        "applicable_categories": None,
                        "is_active": True,
                    }
                )

        # Return a random promo code
        active_promos = [p for p in self.promotional_codes if p["is_active"]]
        return random.choice(active_promos) if active_promos else None

    def _create_payment_transaction(self, booking: Dict):
        """Create payment transaction record"""

        payment_id = self.counters["payment_transaction"]
        self.counters["payment_transaction"] += 1

        self.payment_transactions.append(
            {
                "transaction_id": payment_id,
                "booking_id": booking["booking_id"],
                "transaction_type": "purchase",
                "amount": booking["total_amount"],
                "currency": booking["currency"],
                "payment_method_id": booking["payment_method_id"],
                "transaction_status": (
                    "completed"
                    if booking["booking_status"] == "confirmed"
                    else "failed"
                ),
                "gateway_transaction_id": self.fake.uuid4(),
                "gateway_response": (
                    "Approved"
                    if booking["booking_status"] == "confirmed"
                    else "Declined"
                ),
                "transaction_datetime": booking["booking_datetime"],
                "refund_amount": (
                    booking["total_amount"]
                    if booking["booking_status"] == "refunded"
                    else 0
                ),
            }
        )

    def _generate_ticket_transfer(self, booking_id: int):
        """Generate ticket transfer to another customer"""

        tickets = [t for t in self.tickets if t["booking_id"] == booking_id]
        if not tickets:
            return

        # Transfer random number of tickets
        num_to_transfer = min(random.randint(1, len(tickets)), len(tickets))
        tickets_to_transfer = random.sample(tickets, num_to_transfer)

        # Select recipient
        original_customer = next(
            b["customer_id"]
            for b in self.booking_transactions
            if b["booking_id"] == booking_id
        )
        recipient = random.choice(
            [c for c in self.customers if c["customer_id"] != original_customer]
        )

        for ticket in tickets_to_transfer:
            transfer_id = self.counters["transfer"]
            self.counters["transfer"] += 1

            self.ticket_transfers.append(
                {
                    "transfer_id": transfer_id,
                    "ticket_id": ticket["ticket_id"],
                    "from_customer_id": original_customer,
                    "to_customer_id": recipient["customer_id"],
                    "transfer_datetime": datetime.now()
                    - timedelta(days=random.randint(1, 30)),
                    "transfer_status": "completed",
                    "transfer_fee": 0 if random.random() > 0.5 else 5.00,
                }
            )

    def _generate_resale_listing(self, booking_id: int):
        """Generate resale listing for tickets"""

        tickets = [
            t
            for t in self.tickets
            if t["booking_id"] == booking_id and t["ticket_status"] == "valid"
        ]
        if not tickets:
            return

        # List random number of tickets for resale
        num_to_resell = min(random.randint(1, len(tickets)), len(tickets))
        tickets_to_resell = random.sample(tickets, num_to_resell)

        for ticket in tickets_to_resell:
            listing_id = self.counters["resale"]
            self.counters["resale"] += 1

            # Determine resale price (can be higher or lower than original)
            markup = random.uniform(0.5, self.config["pricing"]["resale_markup_max"])
            resale_price = ticket["price"] * markup

            listing = {
                "listing_id": listing_id,
                "ticket_id": ticket["ticket_id"],
                "seller_customer_id": next(
                    b["customer_id"]
                    for b in self.booking_transactions
                    if b["booking_id"] == booking_id
                ),
                "listing_price": round(resale_price, 2),
                "listing_status": random.choice(
                    ["active", "sold", "expired", "cancelled"]
                ),
                "listed_datetime": datetime.now()
                - timedelta(days=random.randint(1, 30)),
                "sold_datetime": (
                    datetime.now() - timedelta(days=random.randint(0, 15))
                    if random.random() > 0.5
                    else None
                ),
                "buyer_customer_id": (
                    random.choice(self.customers)["customer_id"]
                    if random.random() > 0.5
                    else None
                ),
                "platform_fee": round(resale_price * 0.1, 2),  # 10% platform fee
                "seller_payout": round(resale_price * 0.9, 2),
            }

            self.resale_listings.append(listing)

            # Create resale transaction if sold
            if listing["listing_status"] == "sold" and listing["buyer_customer_id"]:
                self._create_resale_transaction(listing)

    def _create_resale_transaction(self, listing: Dict):
        """Create resale transaction record"""

        trans_id = self.counters["resale_transaction"]
        self.counters["resale_transaction"] += 1

        self.resale_transactions.append(
            {
                "transaction_id": trans_id,
                "listing_id": listing["listing_id"],
                "buyer_customer_id": listing["buyer_customer_id"],
                "seller_customer_id": listing["seller_customer_id"],
                "transaction_amount": listing["listing_price"],
                "platform_fee": listing["platform_fee"],
                "seller_payout": listing["seller_payout"],
                "transaction_datetime": listing["sold_datetime"],
                "transaction_status": "completed",
            }
        )

    def generate_analytics(self):
        """Generate analytics and metrics data"""
        print("  Generating analytics data...")

        # Generate sales metrics by performance
        for performance in self.performances[:100]:  # Sample for demo
            tickets_sold = len(
                [
                    t
                    for t in self.tickets
                    if t.get("performance_id") == performance["performance_id"]
                ]
            )
            revenue = sum(
                [
                    b["total_amount"]
                    for b in self.booking_transactions
                    if any(
                        t.get("performance_id") == performance["performance_id"]
                        for t in self.tickets
                        if t.get("booking_id") == b["booking_id"]
                    )
                ]
            )

            self.sales_metrics.append(
                {
                    "metric_id": self.counters["metric"],
                    "performance_id": performance["performance_id"],
                    "date": (
                        performance["performance_datetime"].date()
                        if isinstance(performance["performance_datetime"], datetime)
                        else performance["performance_datetime"]
                    ),
                    "tickets_sold": tickets_sold,
                    "total_revenue": round(revenue, 2),
                    "average_ticket_price": (
                        round(revenue / tickets_sold, 2) if tickets_sold > 0 else 0
                    ),
                    "occupancy_rate": (
                        round(tickets_sold / performance["total_capacity"], 4)
                        if performance["total_capacity"] > 0
                        else 0
                    ),
                }
            )
            self.counters["metric"] += 1

        # Generate venue utilization
        for venue in self.venues:
            performances_at_venue = [
                p for p in self.performances if p["venue_id"] == venue["venue_id"]
            ]

            self.venue_utilization.append(
                {
                    "utilization_id": self.counters["utilization"],
                    "venue_id": venue["venue_id"],
                    "month": datetime.now().strftime("%Y-%m"),
                    "total_events": len(performances_at_venue),
                    "total_capacity": venue["capacity"] * len(performances_at_venue),
                    "tickets_sold": random.randint(
                        1000, venue["capacity"] * len(performances_at_venue)
                    ),
                    "utilization_rate": round(random.uniform(0.4, 0.95), 4),
                }
            )
            self.counters["utilization"] += 1

    def _get_day_of_week_factor(self, date: datetime) -> float:
        """Get pricing factor based on day of week"""

        days = [
            "monday",
            "tuesday",
            "wednesday",
            "thursday",
            "friday",
            "saturday",
            "sunday",
        ]
        day_name = days[date.weekday()]

        return self.config["dynamic_pricing"]["day_of_week_factors"].get(day_name, 1.0)

    def _weighted_choice(self, choices: List, weights: List):
        """Make a weighted random choice"""

        return random.choices(choices, weights=weights)[0]

    def save_to_csv(self, output_dir: Optional[str] = None):
        """Save all generated data to CSV files"""

        if output_dir is None:
            output_dir = self.config["output_dir"]

        # Create output directory if it doesn't exist
        Path(output_dir).mkdir(parents=True, exist_ok=True)

        # Define tables and their data
        tables = {
            "venues": self.venues,
            "venue_sections": self.venue_sections,
            "venue_rows": self.venue_rows,
            "venue_seats": self.venue_seats,
            "event_categories": self.event_categories,
            "performers": self.performers,
            "events": self.events,
            "performances": self.performances,
            "event_performers": self.event_performers,
            "price_tiers": self.price_tiers,
            "customers": self.customers,
            "customer_preferences": self.customer_preferences,
            "loyalty_members": self.loyalty_members,
            "payment_methods": self.payment_methods,
            "tickets": self.tickets,
            "booking_transactions": self.booking_transactions,
            "payment_transactions": self.payment_transactions,
            "promotional_codes": self.promotional_codes,
            "ticket_transfers": self.ticket_transfers,
            "resale_listings": self.resale_listings,
            "resale_transactions": self.resale_transactions,
            "sales_metrics": self.sales_metrics,
            "venue_utilization": self.venue_utilization,
        }

        # Save each table to CSV
        for table_name, data in tables.items():
            if data:
                file_path = Path(output_dir) / f"{table_name}.csv"

                # Convert dates and complex types to strings
                clean_data = []
                for row in data:
                    clean_row = {}
                    for key, value in row.items():
                        if isinstance(value, (datetime, date)):
                            clean_row[key] = value.strftime(
                                "%Y-%m-%d %H:%M:%S"
                                if isinstance(value, datetime)
                                else "%Y-%m-%d"
                            )
                        elif value is None:
                            clean_row[key] = ""
                        else:
                            clean_row[key] = str(value)
                    clean_data.append(clean_row)

                # Write to CSV
                with open(file_path, "w", newline="", encoding="utf-8") as f:
                    if clean_data:
                        writer = csv.DictWriter(f, fieldnames=clean_data[0].keys())
                        writer.writeheader()
                        writer.writerows(clean_data)

                print(f"  Saved {len(data)} records to {table_name}.csv")

    def generate_all_data(self):
        """Generate all data in the correct sequence"""

        print("Event Ticketing Data Generator Starting...")
        print(
            f"  Configuration: {self.config['counts']['venues']} venues, {self.config['counts']['events']} events"
        )

        print("\n1. Generating venue infrastructure...")
        self.generate_venues()
        print(f"  - {len(self.venues)} venues")
        print(f"  - {len(self.venue_sections)} sections")
        print(f"  - {len(self.venue_rows)} rows")
        print(f"  - {len(self.venue_seats)} seats")

        print("\n2. Generating event catalog...")
        self.generate_event_categories()
        self.generate_performers()
        self.generate_events()
        print(f"  - {len(self.event_categories)} categories")
        print(f"  - {len(self.performers)} performers")
        print(f"  - {len(self.events)} events")
        print(f"  - {len(self.performances)} performances")
        print(f"  - {len(self.price_tiers)} price tiers")

        print("\n3. Generating customer base...")
        self.generate_customers()
        print(f"  - {len(self.customers)} customers")
        print(f"  - {len(self.loyalty_members)} loyalty members")
        print(f"  - {len(self.payment_methods)} payment methods")

        print("\n4. Generating bookings and tickets...")
        self.generate_bookings()
        print(f"  - {len(self.booking_transactions)} bookings")
        print(f"  - {len(self.tickets)} tickets")
        print(f"  - {len(self.payment_transactions)} payment transactions")
        print(f"  - {len(self.ticket_transfers)} transfers")
        print(f"  - {len(self.resale_listings)} resale listings")

        print("\n5. Generating analytics...")
        self.generate_analytics()
        print(f"  - {len(self.sales_metrics)} sales metrics")
        print(f"  - {len(self.venue_utilization)} utilization records")

        print("\n[COMPLETE] Data generation complete!")
        return self


def main():
    parser = argparse.ArgumentParser(
        description="Generate event ticketing platform sample data"
    )
    parser.add_argument(
        "--config", type=str, default="config.json", help="Path to configuration file"
    )
    parser.add_argument(
        "--output", type=str, default=None, help="Output directory for CSV files"
    )
    parser.add_argument(
        "--seed", type=int, default=None, help="Random seed for reproducibility"
    )

    args = parser.parse_args()

    # Initialize generator
    generator = EventTicketingDataGenerator(args.config)

    # Override seed if provided
    if args.seed:
        random.seed(args.seed)
        Faker.seed(args.seed)

    # Generate all data
    generator.generate_all_data()

    # Save to CSV files
    print("\n[SAVING] Saving data to CSV files...")
    generator.save_to_csv(args.output)

    print("\n[SUCCESS] Event Ticketing data generation complete!")
    print(f"  Output directory: {args.output or generator.config['output_dir']}")

    # Print summary statistics
    print("\n[SUMMARY] Statistics:")
    print(f"  Venues: {len(generator.venues):,}")
    print(f"  Total Seats: {len(generator.venue_seats):,}")
    print(f"  Events: {len(generator.events):,}")
    print(f"  Performances: {len(generator.performances):,}")
    print(f"  Customers: {len(generator.customers):,}")
    print(f"  Tickets Sold: {len(generator.tickets):,}")
    print(f"  Total Bookings: {len(generator.booking_transactions):,}")
    print(f"  Resale Listings: {len(generator.resale_listings):,}")


if __name__ == "__main__":
    main()
