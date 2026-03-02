#!/usr/bin/env python3
"""Real Estate Platform Data Generator.

Generates realistic sample data for the real estate database schema
with market dynamics, seasonal patterns, and realistic property distributions
"""

import random
import json
import csv
import argparse
from datetime import datetime, timedelta, date
from typing import List, Dict, Any, Optional
from pathlib import Path

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
)


class RealEstateDataGenerator:
    """Represent RealEstateDataGenerator."""

    def __init__(self, config_path: str = "config.json"):
        """Initialize the generator with configuration."""
        self.fake = Faker("en_US")
        self.fake.add_provider(person)
        self.fake.add_provider(address)
        self.fake.add_provider(phone_number)
        self.fake.add_provider(company)
        self.fake.add_provider(date_time)
        self.fake.add_provider(python)
        self.fake.add_provider(lorem)

        # Load configuration
        with open(config_path, "r") as f:
            self.config = json.load(f)

        # Set seed for reproducibility
        random.seed(self.config["seed"])
        Faker.seed(self.config["seed"])

        # Data storage
        self.countries: List[Any] = []
        self.states: List[Any] = []
        self.cities: List[Any] = []
        self.zip_codes: List[Any] = []
        self.neighborhoods: List[Any] = []
        self.property_types: List[Any] = []
        self.properties: List[Any] = []
        self.brokerages: List[Any] = []
        self.agents: List[Any] = []
        self.users: List[Any] = []
        self.user_preferences: List[Any] = []
        self.listings: List[Any] = []
        self.listing_status_history: List[Any] = []
        self.price_changes: List[Any] = []
        self.property_features: List[Any] = []
        self.property_rooms: List[Any] = []
        self.property_photos: List[Any] = []
        self.viewings: List[Any] = []
        self.viewing_feedback: List[Any] = []
        self.offers: List[Any] = []
        self.offer_contingencies: List[Any] = []
        self.saved_properties: List[Any] = []
        self.saved_searches: List[Any] = []
        self.property_taxes: List[Any] = []
        self.market_trends: List[Any] = []
        self.comparable_sales: List[Any] = []

        # Counters for IDs
        self.counters = {
            "country": 1,
            "state": 1,
            "city": 1,
            "neighborhood": 1,
            "property_type": 1,
            "property": 1,
            "brokerage": 1,
            "agent": 1,
            "user": 1,
            "preference": 1,
            "listing": 1,
            "status_history": 1,
            "price_change": 1,
            "feature": 1,
            "room": 1,
            "photo": 1,
            "viewing": 1,
            "feedback": 1,
            "offer": 1,
            "contingency": 1,
            "saved_property": 1,
            "saved_search": 1,
            "tax": 1,
            "trend": 1,
            "comp": 1,
        }

        # Property types hierarchy
        self.property_type_hierarchy = {
            "residential": {
                "single_family": ["detached", "attached", "townhouse"],
                "condo": ["high_rise", "low_rise", "garden"],
                "multi_family": ["duplex", "triplex", "fourplex"],
                "mobile": ["manufactured", "modular"],
                "other": ["co_op", "senior_living"],
            },
            "commercial": {
                "retail": ["shopping_center", "standalone", "strip_mall"],
                "office": ["class_a", "class_b", "class_c", "medical"],
                "industrial": ["warehouse", "manufacturing", "flex_space"],
                "hospitality": ["hotel", "motel", "resort"],
                "special": ["gas_station", "car_wash", "self_storage"],
            },
            "land": {
                "vacant": ["residential", "commercial", "agricultural"],
                "farm": ["crop", "livestock", "orchard"],
                "recreational": ["hunting", "camping", "waterfront"],
            },
        }

        # Feature categories and examples
        self.features = {
            "interior": [
                "Hardwood Floors",
                "Granite Countertops",
                "Stainless Steel Appliances",
                "Crown Molding",
                "Vaulted Ceilings",
                "Walk-in Closet",
                "Fireplace",
                "Central Vacuum",
                "Smart Home System",
                "Wine Cellar",
                "Home Theater",
                "Wet Bar",
                "Kitchen Island",
                "Pantry",
                "Breakfast Nook",
            ],
            "exterior": [
                "Swimming Pool",
                "Hot Tub",
                "Deck",
                "Patio",
                "Balcony",
                "Garden",
                "Sprinkler System",
                "Privacy Fence",
                "Security Gate",
                "RV Parking",
                "Basketball Court",
                "Tennis Court",
                "Playground",
                "Gazebo",
                "Shed",
            ],
            "amenity": [
                "Gym",
                "Clubhouse",
                "Concierge",
                "Doorman",
                "Business Center",
                "Conference Room",
                "Dog Park",
                "Car Wash",
                "Storage Unit",
                "Guest Parking",
                "Bike Storage",
                "Package Room",
                "Rooftop Access",
            ],
            "utility": [
                "Solar Panels",
                "Tankless Water Heater",
                "Central AC",
                "Heat Pump",
                "Radiant Floor Heating",
                "Double Pane Windows",
                "Insulated Garage",
                "Generator",
                "Water Softener",
                "Sump Pump",
                "French Drain",
            ],
            "safety": [
                "Security System",
                "Smoke Detectors",
                "Carbon Monoxide Detector",
                "Fire Sprinklers",
                "Security Cameras",
                "Video Doorbell",
                "Storm Shelter",
                "Hurricane Shutters",
                "Earthquake Retrofit",
                "Fire Escape",
            ],
            "green": [
                "Energy Star Appliances",
                "LED Lighting",
                "Low Flow Fixtures",
                "Rainwater Harvesting",
                "Composting",
                "Native Landscaping",
                "Electric Car Charger",
                "Greywater System",
                "Green Roof",
            ],
        }

        # Room types
        self.room_types = [
            "Master Bedroom",
            "Bedroom",
            "Guest Bedroom",
            "Living Room",
            "Family Room",
            "Dining Room",
            "Kitchen",
            "Breakfast Area",
            "Office",
            "Den",
            "Library",
            "Media Room",
            "Game Room",
            "Bathroom",
            "Master Bathroom",
            "Half Bath",
            "Laundry Room",
            "Mudroom",
            "Foyer",
            "Hallway",
            "Closet",
            "Pantry",
            "Garage",
            "Basement",
            "Attic",
            "Storage Room",
            "Workshop",
            "Studio",
            "Sunroom",
            "Screened Porch",
            "Bonus Room",
        ]

        # US States (simplified list)
        self.us_states = [
            ("CA", "California"),
            ("TX", "Texas"),
            ("FL", "Florida"),
            ("NY", "New York"),
            ("PA", "Pennsylvania"),
        ]

        # School ratings distribution
        self.school_ratings = [
            3.5,
            4.0,
            4.5,
            5.0,
            5.5,
            6.0,
            6.5,
            7.0,
            7.5,
            8.0,
            8.5,
            9.0,
        ]

        # Offer contingency types
        self.contingency_types = [
            "financing",
            "inspection",
            "appraisal",
            "home_sale",
            "title_review",
            "homeowners_insurance",
        ]

    def generate_location_hierarchy(self):
        """Generate countries, states, cities, zip codes, and neighborhoods."""
        # Generate country (USA)
        country_id = self.counters["country"]
        self.counters["country"] += 1
        self.countries.append(
            {
                "country_id": country_id,
                "country_code": "US",
                "country_name": "United States",
            }
        )

        # Generate states
        for state_code, state_name in self.us_states[: self.config["counts"]["states"]]:
            state_id = self.counters["state"]
            self.counters["state"] += 1
            self.states.append(
                {
                    "state_id": state_id,
                    "country_id": country_id,
                    "state_code": state_code,
                    "state_name": state_name,
                }
            )

            # Generate cities per state
            cities_per_state = (
                self.config["counts"]["cities"] // self.config["counts"]["states"]
            )
            for _ in range(cities_per_state):
                city_id = self.counters["city"]
                self.counters["city"] += 1

                # Generate realistic city data
                city_name = self.fake.city()
                population = random.randint(50000, 2000000)
                median_income = random.randint(35000, 150000)
                lat = float(self.fake.latitude())
                lng = float(self.fake.longitude())

                self.cities.append(
                    {
                        "city_id": city_id,
                        "state_id": state_id,
                        "city_name": city_name,
                        "latitude": lat,
                        "longitude": lng,
                        "population": population,
                        "median_income": median_income,
                    }
                )

                # Generate zip codes per city
                zips_per_city = (
                    self.config["counts"]["zip_codes"]
                    // self.config["counts"]["cities"]
                )
                for _ in range(zips_per_city):
                    zip_code = self.fake.zipcode()
                    self.zip_codes.append(
                        {
                            "zip_code": zip_code,
                            "city_id": city_id,
                            "latitude": lat + random.uniform(-0.1, 0.1),
                            "longitude": lng + random.uniform(-0.1, 0.1),
                            "timezone": "America/New_York",  # Simplified
                        }
                    )

                # Generate neighborhoods per city
                neighborhoods_per_city = (
                    self.config["counts"]["neighborhoods"]
                    // self.config["counts"]["cities"]
                )
                for _ in range(neighborhoods_per_city):
                    neighborhood_id = self.counters["neighborhood"]
                    self.counters["neighborhood"] += 1

                    # Generate neighborhood characteristics
                    median_home_price = self._calculate_neighborhood_price(
                        median_income
                    )
                    median_rent = (
                        median_home_price * 0.005
                    )  # 0.5% of home value as monthly rent

                    self.neighborhoods.append(
                        {
                            "neighborhood_id": neighborhood_id,
                            "city_id": city_id,
                            "neighborhood_name": f"{self.fake.last_name()} {random.choice(['Heights', 'Park', 'Village', 'Hills', 'Gardens', 'Estates'])}",
                            "center_lat": lat + random.uniform(-0.05, 0.05),
                            "center_lng": lng + random.uniform(-0.05, 0.05),
                            "median_home_price": median_home_price,
                            "median_rent": median_rent,
                            "walk_score": random.randint(20, 95),
                            "transit_score": random.randint(15, 85),
                            "crime_rate": round(random.uniform(10, 100), 2),
                            "school_rating": random.choice(self.school_ratings),
                            "description": self.fake.paragraph(),
                        }
                    )

    def _calculate_neighborhood_price(self, city_median_income: int) -> int:
        """Calculate neighborhood median home price based on city income."""
        base_multiplier = 3.5  # Home price to income ratio
        neighborhood_variance = random.uniform(0.7, 1.5)
        return int(city_median_income * base_multiplier * neighborhood_variance)

    def generate_property_types(self):
        """Generate property type hierarchy."""
        for category, subcategories in self.property_type_hierarchy.items():
            # Parent category
            parent_id = self.counters["property_type"]
            self.counters["property_type"] += 1
            self.property_types.append(
                {
                    "type_id": parent_id,
                    "parent_type_id": None,
                    "type_name": category.title(),
                    "type_category": category,
                    "description": f"All {category} properties",
                }
            )

            # Subcategories
            for subcat_name, types in subcategories.items():
                subcat_id = self.counters["property_type"]
                self.counters["property_type"] += 1
                self.property_types.append(
                    {
                        "type_id": subcat_id,
                        "parent_type_id": parent_id,
                        "type_name": subcat_name.replace("_", " ").title(),
                        "type_category": category,
                        "description": f"{subcat_name} properties",
                    }
                )

                # Specific types
                for specific_type in types:
                    type_id = self.counters["property_type"]
                    self.counters["property_type"] += 1
                    self.property_types.append(
                        {
                            "type_id": type_id,
                            "parent_type_id": subcat_id,
                            "type_name": specific_type.replace("_", " ").title(),
                            "type_category": category,
                            "description": f"{specific_type} property type",
                        }
                    )

    def generate_brokerages(self):
        """Generate real estate brokerages."""
        brokerage_names = [
            "Realty",
            "Properties",
            "Real Estate",
            "Homes",
            "Group",
            "Associates",
            "Partners",
            "Brokers",
            "Agency",
            "Realtors",
        ]

        for _ in range(self.config["counts"]["brokerages"]):
            brokerage_id = self.counters["brokerage"]
            self.counters["brokerage"] += 1

            city = random.choice(self.cities)
            state = next(s for s in self.states if s["state_id"] == city["state_id"])

            name = f"{self.fake.last_name()} {random.choice(brokerage_names)}"

            self.brokerages.append(
                {
                    "brokerage_id": brokerage_id,
                    "brokerage_name": name,
                    "license_number": f"BRK{random.randint(100000, 999999)}",
                    "address": self.fake.street_address(),
                    "city_id": city["city_id"],
                    "state_id": state["state_id"],
                    "zip_code": random.choice(
                        [
                            z["zip_code"]
                            for z in self.zip_codes
                            if z["city_id"] == city["city_id"]
                        ]
                    ),
                    "phone": self.fake.phone_number(),
                    "email": f"info@{name.lower().replace(' ', '')}.com",
                    "website": f"www.{name.lower().replace(' ', '')}.com",
                    "established_date": self.fake.date_between(
                        start_date="-30y", end_date="-1y"
                    ),
                    "total_agents": 0,  # Will update after generating agents
                    "active_listings": 0,  # Will update after generating listings
                }
            )

    def generate_agents(self):
        """Generate real estate agents."""
        specializations = [
            "Residential Sales",
            "Commercial Sales",
            "Luxury Homes",
            "First-Time Buyers",
            "Investment Properties",
            "Foreclosures",
            "New Construction",
            "Condos",
            "Waterfront",
            "Historic Homes",
            "Green Homes",
            "Senior Living",
            "Relocation",
            "Military Relocation",
        ]

        for _ in range(self.config["counts"]["agents"]):
            agent_id = self.counters["agent"]
            self.counters["agent"] += 1

            brokerage = random.choice(self.brokerages)
            state = random.choice(self.states)

            # Agent performance metrics
            years_exp = random.randint(1, 30)
            total_transactions = years_exp * random.randint(5, 50)
            total_volume = total_transactions * random.randint(200000, 800000)
            avg_dom = random.randint(15, 90)  # Average days on market
            rating = round(random.uniform(3.5, 5.0), 2)

            # Agent specializations (1-3)
            agent_specs = random.sample(specializations, k=random.randint(1, 3))

            self.agents.append(
                {
                    "agent_id": agent_id,
                    "brokerage_id": brokerage["brokerage_id"],
                    "first_name": self.fake.first_name(),
                    "last_name": self.fake.last_name(),
                    "email": self.fake.email(),
                    "phone": self.fake.phone_number(),
                    "mobile_phone": self.fake.phone_number(),
                    "license_number": f"AGT{random.randint(100000, 999999)}",
                    "license_state_id": state["state_id"],
                    "license_expiry_date": self.fake.date_between(
                        start_date="today", end_date="+3y"
                    ),
                    "specializations": json.dumps(agent_specs),
                    "bio": self.fake.paragraph(nb_sentences=5),
                    "profile_photo_url": f"https://photos.realestate.com/agents/{agent_id}.jpg",
                    "years_experience": years_exp,
                    "total_sales_volume": total_volume,
                    "total_transactions": total_transactions,
                    "avg_days_on_market": avg_dom,
                    "rating": rating,
                    "is_active": True,
                    "joined_date": self.fake.date_between(
                        start_date=f"-{years_exp}y", end_date="today"
                    ),
                }
            )

            # Update brokerage agent count
            brokerage["total_agents"] += 1

    def generate_users(self):
        """Generate platform users (buyers, sellers, renters, investors)."""
        user_types = ["buyer", "seller", "investor", "renter"]
        user_type_weights = [0.5, 0.2, 0.1, 0.2]  # More buyers than sellers

        for _ in range(self.config["counts"]["users"]):
            user_id = self.counters["user"]
            self.counters["user"] += 1

            user_type = random.choices(user_types, weights=user_type_weights)[0]

            self.users.append(
                {
                    "user_id": user_id,
                    "email": self.fake.email(),
                    "password_hash": self.fake.sha256(),
                    "first_name": self.fake.first_name(),
                    "last_name": self.fake.last_name(),
                    "phone": self.fake.phone_number(),
                    "user_type": user_type,
                    "email_verified": random.choice([True, False]),
                    "phone_verified": random.choice([True, False]),
                    "profile_photo_url": (
                        f"https://photos.realestate.com/users/{user_id}.jpg"
                        if random.random() > 0.5
                        else None
                    ),
                    "preferred_contact": random.choice(["email", "phone", "text"]),
                    "last_login": self.fake.date_time_between(
                        start_date="-30d", end_date="now"
                    ),
                    "created_at": self.fake.date_between(
                        start_date="-2y", end_date="today"
                    ),
                }
            )

            # Generate user preferences for buyers and renters
            if user_type in ["buyer", "renter"]:
                self._generate_user_preferences(user_id, user_type)

    def _generate_user_preferences(self, user_id: int, user_type: str):
        """Generate search preferences for a user."""
        preference_id = self.counters["preference"]
        self.counters["preference"] += 1

        if user_type == "buyer":
            min_price = random.choice([200000, 300000, 400000, 500000])
            max_price = min_price + random.choice([100000, 200000, 300000, 500000])
        else:  # renter
            min_price = random.choice([1000, 1500, 2000, 2500])
            max_price = min_price + random.choice([500, 1000, 1500])

        preferred_cities = random.sample(
            [c["city_id"] for c in self.cities], k=random.randint(1, 3)
        )

        self.user_preferences.append(
            {
                "preference_id": preference_id,
                "user_id": user_id,
                "min_price": min_price,
                "max_price": max_price,
                "min_bedrooms": random.choice([1, 2, 3, 4]),
                "min_bathrooms": random.choice([1, 1.5, 2, 2.5, 3]),
                "min_sqft": random.choice([800, 1000, 1500, 2000, 2500]),
                "max_sqft": random.choice([2000, 2500, 3000, 4000, 5000]),
                "property_types": json.dumps(
                    random.sample(
                        ["single_family", "condo", "townhouse"], k=random.randint(1, 3)
                    )
                ),
                "preferred_cities": json.dumps(preferred_cities),
                "max_hoa_fee": (
                    random.choice([0, 100, 200, 300, 500])
                    if random.random() > 0.3
                    else None
                ),
                "min_year_built": (
                    random.choice([1980, 1990, 2000, 2010])
                    if random.random() > 0.5
                    else None
                ),
                "parking_required": random.choice([True, False]),
                "pets_allowed": (
                    random.choice([True, False]) if user_type == "renter" else None
                ),
                "features_required": json.dumps(
                    random.sample(
                        [f for cat in self.features.values() for f in cat],
                        k=random.randint(0, 5),
                    )
                ),
            }
        )

    def generate_properties(self):
        """Generate property listings with realistic distributions."""
        for _ in range(self.config["counts"]["properties"]):
            property_id = self.counters["property"]
            self.counters["property"] += 1

            # Select location
            neighborhood = random.choice(self.neighborhoods)
            city = next(
                c for c in self.cities if c["city_id"] == neighborhood["city_id"]
            )
            state = next(s for s in self.states if s["state_id"] == city["state_id"])
            zip_code = random.choice(
                [z for z in self.zip_codes if z["city_id"] == city["city_id"]]
            )

            # Select property type (weighted towards residential)
            category_weights = {"residential": 0.7, "commercial": 0.2, "land": 0.1}
            category = random.choices(
                list(category_weights.keys()), weights=list(category_weights.values())
            )[0]

            # Get specific property type
            property_type = random.choice(
                [
                    pt
                    for pt in self.property_types
                    if pt["type_category"] == category
                    and pt["parent_type_id"] is not None
                ]
            )

            # Generate property characteristics based on type
            if category == "residential":
                bedrooms = random.choices(
                    [1, 2, 3, 4, 5, 6], weights=[0.1, 0.2, 0.3, 0.25, 0.1, 0.05]
                )[0]
                bathrooms = bedrooms * 0.75 + random.choice([0, 0.5, 1])
                building_sqft = bedrooms * random.randint(400, 800) + random.randint(
                    -200, 500
                )
                lot_sqft = (
                    building_sqft * random.uniform(1.5, 5)
                    if "single" in property_type["type_name"].lower()
                    else 0
                )
                stories = (
                    random.choice([1, 2, 3])
                    if "single" in property_type["type_name"].lower()
                    else random.randint(1, 30)
                )
                year_built = random.randint(1950, 2024)
                parking = random.randint(0, 4)
                garage = random.randint(0, min(3, parking))
            elif category == "commercial":
                bedrooms = 0
                bathrooms = random.randint(2, 10)
                building_sqft = random.randint(2000, 50000)
                lot_sqft = building_sqft * random.uniform(1.2, 3)
                stories = random.randint(1, 10)
                year_built = random.randint(1960, 2024)
                parking = int(building_sqft / 1000) * random.randint(2, 5)
                garage = 0
            else:  # land
                bedrooms = 0
                bathrooms = 0
                building_sqft = 0
                lot_sqft = random.randint(5000, 500000)
                stories = 0
                year_built = None
                parking = 0
                garage = 0

            # Calculate property value based on neighborhood and characteristics
            base_price = neighborhood["median_home_price"]
            price_per_sqft = base_price / 2000  # Assume median home is 2000 sqft

            if building_sqft > 0:
                property_value = price_per_sqft * building_sqft
                # Adjust for age
                if year_built:
                    age = 2024 - year_built
                    if age < 5:
                        property_value *= 1.1
                    elif age > 30:
                        property_value *= 0.9
                # Adjust for bedrooms
                property_value *= 1 + (bedrooms - 3) * 0.05
            else:
                # Land value
                property_value = (lot_sqft / 43560) * random.randint(
                    10000, 100000
                )  # Per acre

            # HOA fee (mainly for condos and some planned communities)
            hoa_fee = (
                random.randint(100, 500)
                if "condo" in property_type["type_name"].lower()
                else (random.randint(50, 200) if random.random() > 0.7 else 0)
            )

            # Tax assessed value (typically 80-100% of market value)
            tax_assessed = property_value * random.uniform(0.8, 1.0)

            property_data = {
                "property_id": property_id,
                "property_type_id": property_type["type_id"],
                "address_line1": self.fake.street_address(),
                "address_line2": (
                    self.fake.secondary_address() if random.random() > 0.8 else None
                ),
                "city_id": city["city_id"],
                "state_id": state["state_id"],
                "zip_code": zip_code["zip_code"],
                "neighborhood_id": neighborhood["neighborhood_id"],
                "latitude": float(neighborhood["center_lat"])
                + random.uniform(-0.01, 0.01),
                "longitude": float(neighborhood["center_lng"])
                + random.uniform(-0.01, 0.01),
                "parcel_number": f"{state['state_code']}-{random.randint(1000, 9999)}-{random.randint(100, 999)}-{random.randint(10, 99)}",
                "legal_description": f"Lot {random.randint(1, 100)}, Block {random.randint(1, 50)}, {neighborhood['neighborhood_name']} Subdivision",
                "year_built": year_built,
                "lot_size_sqft": int(lot_sqft),
                "building_size_sqft": int(building_sqft),
                "bedrooms": bedrooms,
                "bathrooms": bathrooms,
                "parking_spaces": parking,
                "garage_spaces": garage,
                "stories": stories,
                "construction_type": random.choice(
                    ["Wood Frame", "Brick", "Concrete", "Steel Frame", "Masonry"]
                ),
                "roof_type": random.choice(
                    ["Shingle", "Tile", "Metal", "Flat", "Slate"]
                ),
                "heating_type": random.choice(
                    ["Forced Air", "Radiant", "Baseboard", "Heat Pump", "Boiler"]
                ),
                "cooling_type": random.choice(
                    ["Central AC", "Window Units", "Evaporative", "Heat Pump", "None"]
                ),
                "zoning": random.choice(["R1", "R2", "R3", "C1", "C2", "M1", "A1"]),
                "hoa_fee": hoa_fee,
                "tax_assessed_value": int(tax_assessed),
                "market_value": int(property_value),
            }

            self.properties.append(property_data)

            # Generate property features
            self._generate_property_features(property_id, category, building_sqft)

            # Generate property rooms
            if bedrooms > 0:
                self._generate_property_rooms(property_id, bedrooms, bathrooms)

            # Generate property photos
            self._generate_property_photos(property_id)

            # Generate property taxes
            self._generate_property_taxes(property_id, tax_assessed)

    def _generate_property_features(self, property_id: int, category: str, sqft: int):
        """Generate features for a property."""
        # Determine number of features based on property size/value
        if category == "residential":
            num_features = (
                random.randint(5, 15) if sqft > 2000 else random.randint(3, 8)
            )
        elif category == "commercial":
            num_features = random.randint(3, 10)
        else:
            num_features = random.randint(1, 5)

        # Select features from different categories
        for _ in range(num_features):
            feature_id = self.counters["feature"]
            self.counters["feature"] += 1

            category = random.choice(list(self.features.keys()))
            feature = random.choice(self.features[category])

            self.property_features.append(
                {
                    "feature_id": feature_id,
                    "property_id": property_id,
                    "feature_category": category,
                    "feature_name": feature,
                    "feature_value": "Yes",  # Could be more specific for some features
                }
            )

    def _generate_property_rooms(
        self, property_id: int, bedrooms: int, bathrooms: float
    ):
        """Generate room details for a property."""
        rooms = []

        # Bedrooms
        for i in range(bedrooms):
            room_id = self.counters["room"]
            self.counters["room"] += 1

            is_master = i == 0
            room_type = "Master Bedroom" if is_master else "Bedroom"

            rooms.append(
                {
                    "room_id": room_id,
                    "property_id": property_id,
                    "room_type": room_type,
                    "room_level": random.choice(
                        ["Ground Floor", "Second Floor", "Third Floor", "Basement"]
                    ),
                    "length_ft": (
                        random.randint(10, 20)
                        if not is_master
                        else random.randint(12, 25)
                    ),
                    "width_ft": (
                        random.randint(10, 18)
                        if not is_master
                        else random.randint(12, 20)
                    ),
                    "description": f"{'Spacious master bedroom with walk-in closet' if is_master else 'Comfortable bedroom with closet'}",
                }
            )

        # Bathrooms
        full_baths = int(bathrooms)
        has_half_bath = bathrooms % 1 != 0

        for i in range(full_baths):
            room_id = self.counters["room"]
            self.counters["room"] += 1

            is_master = i == 0
            room_type = "Master Bathroom" if is_master else "Bathroom"

            rooms.append(
                {
                    "room_id": room_id,
                    "property_id": property_id,
                    "room_type": room_type,
                    "room_level": random.choice(
                        ["Ground Floor", "Second Floor", "Basement"]
                    ),
                    "length_ft": (
                        random.randint(8, 12)
                        if not is_master
                        else random.randint(10, 15)
                    ),
                    "width_ft": (
                        random.randint(6, 10)
                        if not is_master
                        else random.randint(8, 12)
                    ),
                    "description": f"{'Luxurious master bath with dual vanity' if is_master else 'Full bathroom'}",
                }
            )

        if has_half_bath:
            room_id = self.counters["room"]
            self.counters["room"] += 1
            rooms.append(
                {
                    "room_id": room_id,
                    "property_id": property_id,
                    "room_type": "Half Bath",
                    "room_level": "Ground Floor",
                    "length_ft": random.randint(5, 8),
                    "width_ft": random.randint(4, 6),
                    "description": "Powder room",
                }
            )

        # Common rooms
        common_rooms = [
            ("Living Room", 15, 25, 12, 20, "Spacious living area"),
            ("Kitchen", 10, 20, 10, 15, "Modern kitchen with island"),
            ("Dining Room", 10, 15, 10, 14, "Formal dining area"),
        ]

        for room_name, min_l, max_l, min_w, max_w, desc in common_rooms:
            room_id = self.counters["room"]
            self.counters["room"] += 1
            rooms.append(
                {
                    "room_id": room_id,
                    "property_id": property_id,
                    "room_type": room_name,
                    "room_level": "Ground Floor",
                    "length_ft": random.randint(min_l, max_l),
                    "width_ft": random.randint(min_w, max_w),
                    "description": desc,
                }
            )

        self.property_rooms.extend(rooms)

    def _generate_property_photos(self, property_id: int):
        """Generate photo records for a property."""
        photo_types = [
            "Front Exterior",
            "Back Exterior",
            "Living Room",
            "Kitchen",
            "Master Bedroom",
            "Master Bathroom",
            "Dining Room",
            "Backyard",
            "Street View",
            "Aerial View",
            "Bedroom 2",
            "Bedroom 3",
            "Garage",
            "Pool Area",
            "Patio",
        ]

        num_photos = random.randint(10, 20)
        selected_types = random.sample(photo_types, min(num_photos, len(photo_types)))

        for i, photo_type in enumerate(selected_types):
            photo_id = self.counters["photo"]
            self.counters["photo"] += 1

            self.property_photos.append(
                {
                    "photo_id": photo_id,
                    "property_id": property_id,
                    "photo_url": f"https://photos.realestate.com/properties/{property_id}/{photo_id}.jpg",
                    "photo_type": photo_type,
                    "display_order": i + 1,
                    "caption": f"{photo_type} view",
                    "is_primary": i == 0,
                    "width": 1920,
                    "height": 1080,
                    "file_size": random.randint(500000, 2000000),  # bytes
                }
            )

    def _generate_property_taxes(self, property_id: int, assessed_value: float):
        """Generate property tax history."""
        tax_rate = random.uniform(0.005, 0.02)  # 0.5% to 2% tax rate

        for year in range(2020, 2025):
            tax_id = self.counters["tax"]
            self.counters["tax"] += 1

            # Assessed value changes slightly each year
            year_assessed = assessed_value * (1 + random.uniform(-0.03, 0.05))
            annual_tax = year_assessed * tax_rate

            self.property_taxes.append(
                {
                    "tax_id": tax_id,
                    "property_id": property_id,
                    "tax_year": year,
                    "assessed_value": int(year_assessed),
                    "tax_rate": round(tax_rate, 4),
                    "annual_tax_amount": int(annual_tax),
                    "paid_amount": int(annual_tax) if year < 2024 else 0,
                    "paid_date": (
                        f"{year}-12-{random.randint(1, 31)}" if year < 2024 else None
                    ),
                    "delinquent": False,
                }
            )

    def generate_listings(self):
        """Generate property listings with realistic status distributions."""
        # Select properties to list (not all properties are currently listed)
        num_total_listings = (
            self.config["counts"]["active_listings"]
            + self.config["counts"]["sold_listings"]
            + self.config["counts"]["pending_listings"]
        )

        listed_properties = random.sample(
            self.properties, min(num_total_listings, len(self.properties))
        )

        # Distribute listing statuses
        active_count = self.config["counts"]["active_listings"]
        _ = self.config["counts"]["sold_listings"]
        pending_count = self.config["counts"]["pending_listings"]

        for i, property_data in enumerate(listed_properties):
            listing_id = self.counters["listing"]
            self.counters["listing"] += 1

            # Determine listing status
            if i < active_count:
                status = "active"
                list_date = self.fake.date_between(start_date="-180d", end_date="today")
                sold_date = None
                sold_price = None
            elif i < active_count + pending_count:
                status = "pending"
                list_date = self.fake.date_between(start_date="-60d", end_date="-7d")
                sold_date = None
                sold_price = None
            else:
                status = "sold"
                list_date = self.fake.date_between(start_date="-365d", end_date="-30d")
                days_on_market = random.randint(7, 120)
                sold_date = list_date + timedelta(days=days_on_market)
                sold_price = property_data["market_value"] * random.uniform(0.95, 1.05)

            # Select listing agent
            agent = random.choice(self.agents)

            # Determine list price (may differ from market value)
            if status == "active":
                # Active listings might be priced optimistically
                list_price = property_data["market_value"] * random.uniform(0.98, 1.15)
            else:
                list_price = property_data["market_value"] * random.uniform(0.95, 1.05)

            # Listing type
            listing_type = "sale" if random.random() > 0.2 else "rent"
            if listing_type == "rent":
                list_price = property_data["market_value"] * 0.005 * 12  # Annual rent

            listing = {
                "listing_id": listing_id,
                "property_id": property_data["property_id"],
                "listing_agent_id": agent["agent_id"],
                "co_listing_agent_id": (
                    random.choice(self.agents)["agent_id"]
                    if random.random() > 0.8
                    else None
                ),
                "listing_type": listing_type,
                "status": status,
                "list_price": int(list_price),
                "list_date": list_date,
                "expiry_date": (
                    list_date + timedelta(days=180) if status == "active" else None
                ),
                "sold_date": sold_date,
                "sold_price": int(sold_price) if sold_price else None,
                "days_on_market": (
                    (sold_date - list_date).days
                    if sold_date
                    else (datetime.now().date() - list_date).days
                ),
                "commission_rate": (
                    0.06 if listing_type == "sale" else 1.0
                ),  # One month's rent for rentals
                "virtual_tour_url": (
                    f"https://tours.realestate.com/{listing_id}"
                    if random.random() > 0.3
                    else None
                ),
                "listing_url": f"https://realestate.com/listings/{listing_id}",
                "mls_number": f"MLS{random.randint(1000000, 9999999)}",
                "showing_instructions": self._generate_showing_instructions(),
                "listing_remarks": self.fake.paragraph(nb_sentences=4),
                "is_featured": random.random() > 0.9,
                "view_count": (
                    random.randint(0, 5000)
                    if status == "active"
                    else random.randint(100, 10000)
                ),
            }

            self.listings.append(listing)

            # Update agent's listing count
            agent["active_listings"] = sum(
                1
                for listing in self.listings
                if listing["listing_agent_id"] == agent["agent_id"]
                and listing["status"] == "active"
            )

            # Generate listing status history
            self._generate_listing_history(listing_id, list_date, status, sold_date)

            # Generate price changes for active listings
            if status == "active" and random.random() > 0.6:
                self._generate_price_changes(listing_id, list_price, list_date)

    def _generate_showing_instructions(self) -> str:
        """Generate showing instructions for a listing."""
        instructions = [
            "Call listing agent to schedule showing",
            "Use showing time app to schedule",
            "Lockbox on front door, code in MLS",
            "Owner occupied, 24 hour notice required",
            "Tenant occupied, 48 hour notice required",
            "By appointment only",
            "Open house Saturdays 1-4 PM",
            "Call owner directly for showing",
        ]
        return random.choice(instructions)

    def _generate_listing_history(
        self,
        listing_id: int,
        list_date: date,
        current_status: str,
        sold_date: Optional[date],
    ):
        """Generate status history for a listing."""
        statuses = []

        # Initial listing
        history_id = self.counters["status_history"]
        self.counters["status_history"] += 1
        statuses.append(
            {
                "history_id": history_id,
                "listing_id": listing_id,
                "status": "active",
                "status_date": list_date,
                "notes": "New listing",
            }
        )

        # Additional status changes
        if current_status == "pending":
            pending_date = list_date + timedelta(days=random.randint(30, 90))
            history_id = self.counters["status_history"]
            self.counters["status_history"] += 1
            statuses.append(
                {
                    "history_id": history_id,
                    "listing_id": listing_id,
                    "status": "pending",
                    "status_date": pending_date,
                    "notes": "Offer accepted, pending inspection",
                }
            )
        elif current_status == "sold":
            # May have gone pending first
            if sold_date is None:
                sold_date = list_date + timedelta(days=random.randint(15, 30))
            if random.random() > 0.3:
                pending_date = sold_date - timedelta(days=random.randint(15, 30))
                history_id = self.counters["status_history"]
                self.counters["status_history"] += 1
                statuses.append(
                    {
                        "history_id": history_id,
                        "listing_id": listing_id,
                        "status": "pending",
                        "status_date": pending_date,
                        "notes": "Under contract",
                    }
                )

            history_id = self.counters["status_history"]
            self.counters["status_history"] += 1
            statuses.append(
                {
                    "history_id": history_id,
                    "listing_id": listing_id,
                    "status": "sold",
                    "status_date": sold_date,
                    "notes": "Closed",
                }
            )

        self.listing_status_history.extend(statuses)

    def _generate_price_changes(
        self, listing_id: int, current_price: float, list_date: date
    ):
        """Generate price change history for a listing."""
        num_changes = random.randint(1, 3)
        price = current_price * 1.1  # Start higher

        for i in range(num_changes):
            change_id = self.counters["price_change"]
            self.counters["price_change"] += 1

            old_price = price
            # Usually price reductions
            price = price * random.uniform(0.95, 0.98)
            change_date = list_date + timedelta(days=(i + 1) * 30)

            self.price_changes.append(
                {
                    "change_id": change_id,
                    "listing_id": listing_id,
                    "old_price": int(old_price),
                    "new_price": int(price),
                    "change_date": change_date,
                    "change_percentage": round(
                        (price - old_price) / old_price * 100, 2
                    ),
                    "reason": random.choice(
                        [
                            "Price reduction",
                            "Market adjustment",
                            "Motivated seller",
                            "End of season adjustment",
                        ]
                    ),
                }
            )

    def generate_viewings_and_offers(self):
        """Generate property viewings and offers."""
        active_listings = [
            listing for listing in self.listings if listing["status"] == "active"
        ]

        # Generate viewings for active listings
        for listing in active_listings:
            # Number of viewings depends on days on market and price
            avg_viewings_per_week = random.randint(2, 10)
            weeks_on_market = listing["days_on_market"] / 7
            num_viewings = int(
                avg_viewings_per_week * weeks_on_market * random.uniform(0.5, 1.5)
            )

            for _ in range(min(num_viewings, 50)):  # Cap at 50 viewings per property
                viewing_id = self.counters["viewing"]
                self.counters["viewing"] += 1

                # Random user who viewed
                viewer = random.choice(
                    [u for u in self.users if u["user_type"] in ["buyer", "investor"]]
                )

                # Viewing date within listing period
                viewing_date = listing["list_date"] + timedelta(
                    days=random.randint(0, listing["days_on_market"])
                )
                viewing_time = random.choice(
                    ["09:00", "10:00", "11:00", "14:00", "15:00", "16:00", "17:00"]
                )

                viewing = {
                    "viewing_id": viewing_id,
                    "listing_id": listing["listing_id"],
                    "user_id": viewer["user_id"],
                    "agent_id": listing["listing_agent_id"],
                    "scheduled_date": viewing_date,
                    "scheduled_time": viewing_time,
                    "duration_minutes": random.choice([30, 45, 60]),
                    "status": random.choices(
                        ["completed", "cancelled", "no_show"], weights=[0.8, 0.15, 0.05]
                    )[0],
                    "viewing_type": random.choice(
                        ["in_person", "virtual", "open_house"]
                    ),
                    "notes": self.fake.sentence() if random.random() > 0.7 else None,
                }

                self.viewings.append(viewing)

                # Generate feedback for completed viewings
                if viewing["status"] == "completed":
                    self._generate_viewing_feedback(viewing_id, viewer["user_id"])

                # Some viewings lead to offers
                if viewing["status"] == "completed" and random.random() > 0.85:
                    self._generate_offer(listing, viewer["user_id"])

    def _generate_viewing_feedback(self, viewing_id: int, user_id: int):
        """Generate feedback for a viewing."""
        feedback_id = self.counters["feedback"]
        self.counters["feedback"] += 1

        self.viewing_feedback.append(
            {
                "feedback_id": feedback_id,
                "viewing_id": viewing_id,
                "user_id": user_id,
                "rating": random.randint(1, 5),
                "interested": random.choice([True, False]),
                "comments": self.fake.paragraph(nb_sentences=2),
                "follow_up_requested": random.choice([True, False]),
                "submitted_date": datetime.now(),
            }
        )

    def _generate_offer(self, listing: Dict, user_id: int):
        """Generate an offer on a property."""
        offer_id = self.counters["offer"]
        self.counters["offer"] += 1

        # Offer amount relative to list price
        offer_percentage = random.uniform(0.9, 1.05)
        offer_amount = listing["list_price"] * offer_percentage

        # Offer details
        offer = {
            "offer_id": offer_id,
            "listing_id": listing["listing_id"],
            "user_id": user_id,
            "offer_amount": int(offer_amount),
            "offer_date": datetime.now().date() - timedelta(days=random.randint(0, 30)),
            "expiry_date": datetime.now().date() + timedelta(days=random.randint(1, 7)),
            "status": random.choice(
                ["pending", "accepted", "rejected", "countered", "withdrawn"]
            ),
            "earnest_money": int(offer_amount * 0.01),  # 1% earnest money
            "down_payment_amount": int(
                offer_amount * random.choice([0.05, 0.10, 0.20])
            ),
            "financing_type": random.choice(
                ["conventional", "FHA", "VA", "cash", "jumbo"]
            ),
            "closing_date": datetime.now().date()
            + timedelta(days=random.randint(30, 60)),
            "is_cash_offer": random.random() > 0.8,
            "waive_inspection": random.random() > 0.9,
            "waive_appraisal": random.random() > 0.95,
            "include_appliances": random.choice([True, False]),
            "seller_concessions": (
                int(offer_amount * random.uniform(0, 0.03))
                if random.random() > 0.7
                else 0
            ),
            "notes": self.fake.paragraph(nb_sentences=2),
        }

        self.offers.append(offer)

        # Generate contingencies
        if not offer["is_cash_offer"]:
            num_contingencies = random.randint(1, 4)
            for contingency_type in random.sample(
                self.contingency_types, num_contingencies
            ):
                contingency_id = self.counters["contingency"]
                self.counters["contingency"] += 1

                self.offer_contingencies.append(
                    {
                        "contingency_id": contingency_id,
                        "offer_id": offer_id,
                        "contingency_type": contingency_type,
                        "deadline_date": offer["offer_date"]
                        + timedelta(days=random.randint(7, 21)),
                        "status": "pending",
                        "notes": f"{contingency_type.replace('_', ' ').title()} contingency",
                    }
                )

    def generate_market_trends(self):
        """Generate market trend data."""
        # Generate monthly trends for each city
        for city in self.cities:
            for year in [2023, 2024]:
                for month in range(1, 13):
                    if year == 2024 and month > 12:
                        break

                    trend_id = self.counters["trend"]
                    self.counters["trend"] += 1

                    # Calculate seasonal adjustments
                    seasonal_factor = 1.0
                    if month in [3, 4, 5, 6]:  # Spring/Summer boost
                        seasonal_factor = self.config["market_dynamics"]["spring_boost"]
                    elif month in [11, 12, 1, 2]:  # Winter slowdown
                        seasonal_factor = self.config["market_dynamics"][
                            "winter_slowdown"
                        ]

                    # Base metrics
                    base_price = city["median_income"] * 3.5
                    median_price = (
                        base_price * seasonal_factor * random.uniform(0.95, 1.05)
                    )

                    self.market_trends.append(
                        {
                            "trend_id": trend_id,
                            "city_id": city["city_id"],
                            "month": f"{year}-{month:02d}-01",
                            "median_sale_price": int(median_price),
                            "median_list_price": int(median_price * 1.02),
                            "median_rent": int(median_price * 0.005),
                            "inventory_count": random.randint(100, 1000),
                            "new_listings_count": random.randint(50, 300),
                            "sold_count": random.randint(40, 250),
                            "pending_count": random.randint(20, 100),
                            "avg_days_on_market": int(
                                self.config["market_dynamics"]["average_days_on_market"]
                                / seasonal_factor
                            ),
                            "months_of_inventory": round(random.uniform(1, 6), 1),
                            "list_to_sold_ratio": round(random.uniform(0.96, 1.02), 3),
                            "absorption_rate": round(random.uniform(0.1, 0.4), 2),
                        }
                    )

    def save_to_csv(self, output_dir: Optional[str] = None):
        """Save all generated data to CSV files."""
        if output_dir is None:
            output_dir = self.config["output_dir"]

        # Create output directory if it doesn't exist
        Path(output_dir).mkdir(parents=True, exist_ok=True)

        # Define tables and their data
        tables = {
            "countries": self.countries,
            "states_provinces": self.states,
            "cities": self.cities,
            "zip_codes": self.zip_codes,
            "neighborhoods": self.neighborhoods,
            "property_types": self.property_types,
            "properties": self.properties,
            "brokerages": self.brokerages,
            "agents": self.agents,
            "users": self.users,
            "user_preferences": self.user_preferences,
            "listings": self.listings,
            "listing_status_history": self.listing_status_history,
            "price_changes": self.price_changes,
            "property_features": self.property_features,
            "property_rooms": self.property_rooms,
            "property_photos": self.property_photos,
            "property_taxes": self.property_taxes,
            "viewings": self.viewings,
            "viewing_feedback": self.viewing_feedback,
            "offers": self.offers,
            "offer_contingencies": self.offer_contingencies,
            "saved_properties": self.saved_properties,
            "saved_searches": self.saved_searches,
            "market_trends": self.market_trends,
            "comparable_sales": self.comparable_sales,
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
        """Generate all data in the correct sequence."""
        print("Real Estate Data Generator Starting...")
        print(
            f"   Using configuration: {self.config['counts']['properties']} properties"
        )

        print("\n1. Generating location hierarchy...")
        self.generate_location_hierarchy()
        print(
            f"   - {len(self.countries)} countries, {len(self.states)} states, {len(self.cities)} cities"
        )
        print(
            f"   - {len(self.neighborhoods)} neighborhoods, {len(self.zip_codes)} zip codes"
        )

        print("\n2. Generating property types...")
        self.generate_property_types()
        print(f"   - {len(self.property_types)} property types")

        print("\n3. Generating brokerages...")
        self.generate_brokerages()
        print(f"   - {len(self.brokerages)} brokerages")

        print("\n4. Generating agents...")
        self.generate_agents()
        print(f"   - {len(self.agents)} agents")

        print("\n5. Generating users...")
        self.generate_users()
        print(f"   - {len(self.users)} users, {len(self.user_preferences)} preferences")

        print("\n6. Generating properties...")
        self.generate_properties()
        print(f"   - {len(self.properties)} properties")
        print(f"   - {len(self.property_features)} features")
        print(f"   - {len(self.property_rooms)} rooms")
        print(f"   - {len(self.property_photos)} photos")

        print("\n7. Generating listings...")
        self.generate_listings()
        active = len(
            [listing for listing in self.listings if listing["status"] == "active"]
        )
        sold = len(
            [listing for listing in self.listings if listing["status"] == "sold"]
        )
        pending = len(
            [listing for listing in self.listings if listing["status"] == "pending"]
        )
        print(f"   - {len(self.listings)} total listings")
        print(f"   - {active} active, {pending} pending, {sold} sold")
        print(f"   - {len(self.price_changes)} price changes")

        print("\n8. Generating viewings and offers...")
        self.generate_viewings_and_offers()
        print(f"   - {len(self.viewings)} viewings")
        print(f"   - {len(self.offers)} offers")
        print(f"   - {len(self.offer_contingencies)} contingencies")

        print("\n9. Generating market trends...")
        self.generate_market_trends()
        print(f"   - {len(self.market_trends)} market trend records")

        print("\n[COMPLETE] Data generation complete!")
        return self


def main():
    """Handle main."""
    parser = argparse.ArgumentParser(
        description="Generate real estate platform sample data"
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
    generator = RealEstateDataGenerator(args.config)

    # Override seed if provided
    if args.seed:
        random.seed(args.seed)
        Faker.seed(args.seed)

    # Generate all data
    generator.generate_all_data()

    # Save to CSV files
    print("\n[SAVING] Saving data to CSV files...")
    generator.save_to_csv(args.output)

    print("\n[SUCCESS] Real Estate data generation complete!")
    print(f"   Output directory: {args.output or generator.config['output_dir']}")

    # Print summary statistics
    print("\n[SUMMARY] Summary Statistics:")
    print(f"   Properties: {len(generator.properties):,}")
    print(
        f"   Active Listings: {len([listing for listing in generator.listings if listing['status'] == 'active']):,}"
    )
    print(f"   Agents: {len(generator.agents):,}")
    print(f"   Users: {len(generator.users):,}")
    print(f"   Total Viewings: {len(generator.viewings):,}")
    print(f"   Total Offers: {len(generator.offers):,}")


if __name__ == "__main__":
    main()
