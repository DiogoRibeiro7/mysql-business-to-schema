#!/usr/bin/env python3
"""Hotel Chain Management Data Generator.

Generates realistic test data for the hotel chain database.
Includes properties, rooms, reservations, guests, staff, and services.
"""

import random
from datetime import datetime, timedelta, date, time
import json
from typing import Dict, List, Any

from generators.base_generator import BaseGenerator


class HotelChainGenerator(BaseGenerator):
    """Generator for Hotel Chain Management data."""

    def __init__(
        self,
        host="localhost",
        port=3340,
        user="hotel_admin",
        password="hotel_pass_2024",
        database="hotel_chain",
    ):
        """Initialize the hotel chain generator."""
        super().__init__(host, port, user, password, database)

        # Hotel specific data
        self.property_types = [
            "hotel",
            "resort",
            "boutique",
            "airport",
            "extended_stay",
            "conference_center",
        ]

        self.room_categories = [
            "standard",
            "deluxe",
            "suite",
            "executive",
            "presidential",
        ]

        self.bed_configurations = [
            "Single",
            "Double",
            "Queen",
            "King",
            "Twin",
            "King + Sofa Bed",
        ]

        self.view_types = ["city", "ocean", "garden", "pool", "mountain", "courtyard"]

        self.booking_channels = [
            "direct",
            "website",
            "mobile_app",
            "call_center",
            "walk_in",
            "ota_booking",
            "ota_expedia",
            "corporate",
            "group",
            "travel_agent",
        ]

        self.vip_status_levels = [
            "none",
            "silver",
            "gold",
            "platinum",
            "diamond",
            "invitation_only",
        ]

        self.departments = [
            "front_office",
            "housekeeping",
            "food_beverage",
            "maintenance",
            "security",
            "spa",
            "concierge",
            "management",
            "accounting",
            "hr",
        ]

        self.amenities = {
            "property": [
                "pool",
                "gym",
                "spa",
                "restaurant",
                "bar",
                "parking",
                "wifi",
                "business_center",
                "conference_rooms",
                "concierge",
                "room_service",
            ],
            "room": [
                "wifi",
                "tv",
                "minibar",
                "safe",
                "coffee_maker",
                "balcony",
                "bathtub",
                "air_conditioning",
                "desk",
                "refrigerator",
            ],
        }

        self.brand_names = [
            "Luxury Hotels",
            "Comfort Suites",
            "Business Express",
            "Family Resorts",
            "Urban Boutique",
            "Beach Paradise",
        ]

    def generate_all_data(
        self,
        properties: int = 10,
        rooms_per_property: int = 200,
        guests: int = 10000,
        reservations_per_day: int = 500,
    ):
        """Generate all hotel chain management data."""
        print("Starting Hotel Chain Management data generation...")

        # Generate base data
        print("Generating properties...")
        self.generate_properties(properties)

        print("Generating room types...")
        self.generate_room_types()

        print("Generating rooms...")
        self.generate_rooms(rooms_per_property)

        print("Generating guests...")
        self.generate_guests(guests)

        print("Generating loyalty members...")
        self.generate_loyalty_members()

        print("Generating staff...")
        self.generate_staff()

        print("Generating reservations...")
        self.generate_reservations(reservations_per_day)

        print("Generating room assignments...")
        self.generate_room_assignments()

        print("Generating folios and charges...")
        self.generate_folios_and_charges()

        print("Generating payments...")
        self.generate_payments()

        print("Generating loyalty transactions...")
        self.generate_loyalty_transactions()

        print("Generating housekeeping tasks...")
        self.generate_housekeeping_tasks()

        print("Generating maintenance requests...")
        self.generate_maintenance_requests()

        print("Generating guest services...")
        self.generate_guest_services()

        print("Generating rate plans...")
        self.generate_rate_plans()

        print("Generation complete!")

    def generate_properties(self, count: int = 10):
        """Generate hotel properties."""
        properties = []

        cities = [
            ("New York", "NY", "USA"),
            ("Los Angeles", "CA", "USA"),
            ("Chicago", "IL", "USA"),
            ("Miami", "FL", "USA"),
            ("Las Vegas", "NV", "USA"),
            ("San Francisco", "CA", "USA"),
            ("Boston", "MA", "USA"),
            ("Seattle", "WA", "USA"),
            ("Orlando", "FL", "USA"),
            ("Washington", "DC", "USA"),
        ]

        for i in range(min(count, len(cities))):
            city, state, country = cities[i]

            # Location coordinates (simplified)
            lat = 40.7128 + random.uniform(-10, 10)
            lon = -74.0060 + random.uniform(-10, 10)
            location = f"POINT({lon} {lat})"

            property_name = f"{random.choice(self.brand_names)} {city}"

            property_data = (
                property_name,
                random.choice(self.property_types),
                random.choice(self.brand_names),
                f"{random.randint(100, 999)} {self.faker.street_name()}",
                city,
                state,
                self.faker.zipcode(),
                country,
                self.faker.phone_number(),
                f"info@{property_name.lower().replace(' ', '')}.com",
                f"www.{property_name.lower().replace(' ', '')}.com",
                random.randint(3, 5),  # star_rating
                random.randint(100, 500),  # total_rooms
                random.randint(5, 20),  # total_floors
                random.randint(1980, 2020),  # year_built
                (
                    random.randint(2018, 2023) if random.random() > 0.5 else None
                ),  # last_renovation
                "15:00:00",  # check_in_time
                "11:00:00",  # check_out_time
                json.dumps(
                    random.sample(self.amenities["property"], random.randint(5, 10))
                ),
                location,
                "active",
                random.randint(1, 100),  # general_manager_id (will be created later)
                self.faker.date_time_between("-10 years", "now"),
                self.faker.date_time_between("-10 years", "now"),
            )
            properties.append(property_data)

        self.bulk_insert(
            "properties",
            properties,
            [
                "property_name",
                "property_type",
                "brand_name",
                "address",
                "city",
                "state_province",
                "postal_code",
                "country",
                "phone",
                "email",
                "website",
                "star_rating",
                "total_rooms",
                "total_floors",
                "year_built",
                "last_renovation",
                "check_in_time",
                "check_out_time",
                "amenities",
                "location_coordinates",
                "status",
                "general_manager_id",
                "created_at",
                "updated_at",
            ],
        )

    def generate_room_types(self):
        """Generate room types for each property."""
        properties = self.fetch_all("SELECT property_id FROM properties")

        room_types = []

        for property in properties:
            # Each property has 3-8 room types
            for category in self.room_categories:
                # Base rate varies by category
                base_rates = {
                    "standard": random.uniform(100, 200),
                    "deluxe": random.uniform(150, 300),
                    "suite": random.uniform(250, 500),
                    "executive": random.uniform(300, 600),
                    "presidential": random.uniform(500, 2000),
                }

                max_occupancy = {
                    "standard": 2,
                    "deluxe": 3,
                    "suite": 4,
                    "executive": 4,
                    "presidential": 6,
                }

                room_type = (
                    property["property_id"],
                    f"{category.title()} Room",
                    category.upper()[:3],
                    category,
                    self.faker.text(max_nb_chars=200),
                    max_occupancy[category],
                    max_occupancy[category] - 1,
                    category in ["suite", "executive", "presidential"],
                    base_rates[category],
                    (
                        random.uniform(200, 500)
                        if category != "standard"
                        else random.uniform(150, 250)
                    ),  # size_sqft
                    json.dumps(
                        random.sample(self.amenities["room"], random.randint(5, 10))
                    ),
                    random.choice([0, 1]),  # is_active
                    self.faker.date_time_between("-5 years", "now"),
                )
                room_types.append(room_type)

        self.bulk_insert(
            "room_types",
            room_types,
            [
                "property_id",
                "type_name",
                "type_code",
                "category",
                "description",
                "max_occupancy",
                "standard_occupancy",
                "extra_bed_allowed",
                "base_rate",
                "size_sqft",
                "amenities",
                "is_active",
                "created_at",
            ],
        )

    def generate_rooms(self, rooms_per_property: int = 200):
        """Generate individual rooms."""
        room_types = self.fetch_all(
            """
            SELECT rt.room_type_id, rt.property_id, rt.category, p.total_floors
            FROM room_types rt
            JOIN properties p ON rt.property_id = p.property_id
            WHERE rt.is_active = 1
        """
        )

        # Group room types by property
        types_by_property: Dict[int, List[Dict[str, Any]]] = {}
        for rt in room_types:
            prop_id = rt["property_id"]
            if prop_id not in types_by_property:
                types_by_property[prop_id] = []
            types_by_property[prop_id].append(rt)

        rooms = []

        for property_id, property_types in types_by_property.items():
            total_floors = property_types[0]["total_floors"]

            for floor in range(1, min(total_floors + 1, 21)):  # Max 20 floors
                rooms_on_floor = rooms_per_property // total_floors

                for room_num in range(1, rooms_on_floor + 1):
                    room_type = random.choice(property_types)

                    # Room number format: Floor + Number (e.g., 305 for floor 3, room 5)
                    room_number = f"{floor}{str(room_num).zfill(2)}"

                    room = (
                        property_id,
                        room_type["room_type_id"],
                        room_number,
                        floor,
                        (
                            random.choice(["North", "South", "East", "West"])
                            if floor > 5
                            else None
                        ),
                        random.choice(self.view_types),
                        json.dumps(random.choice(self.bed_configurations)),
                        (
                            random.choice([0, 1])
                            if room_type["category"] == "standard"
                            else 0
                        ),  # is_accessible
                        0,  # is_smoking (mostly non-smoking)
                        "available",  # status
                        "clean",  # housekeeping_status
                        self.faker.date_time_between("-7 days", "now"),  # last_cleaned
                        "none",  # maintenance_status
                        (
                            self.faker.date_between("-5 years", "-1 year")
                            if random.random() > 0.5
                            else None
                        ),
                        self.faker.date_time_between("-5 years", "now"),
                    )
                    rooms.append(room)

                    if len(rooms) >= 1000:
                        self.bulk_insert(
                            "rooms",
                            rooms,
                            [
                                "property_id",
                                "room_type_id",
                                "room_number",
                                "floor_number",
                                "building_section",
                                "view_type",
                                "bed_configuration",
                                "is_accessible",
                                "is_smoking",
                                "status",
                                "housekeeping_status",
                                "last_cleaned",
                                "maintenance_status",
                                "last_renovated",
                                "created_at",
                            ],
                        )
                        rooms = []

        if rooms:
            self.bulk_insert(
                "rooms",
                rooms,
                [
                    "property_id",
                    "room_type_id",
                    "room_number",
                    "floor_number",
                    "building_section",
                    "view_type",
                    "bed_configuration",
                    "is_accessible",
                    "is_smoking",
                    "status",
                    "housekeeping_status",
                    "last_cleaned",
                    "maintenance_status",
                    "last_renovated",
                    "created_at",
                ],
            )

    def generate_guests(self, count: int = 10000):
        """Generate hotel guests."""
        guests = []

        for i in range(count):
            # VIP status distribution
            vip_status = self.faker.random_element(
                [
                    ("none", 0.70),
                    ("silver", 0.15),
                    ("gold", 0.10),
                    ("platinum", 0.04),
                    ("diamond", 0.01),
                ]
            )

            # Generate preferences
            preferences = {
                "room": random.choice(
                    ["high_floor", "low_floor", "quiet", "near_elevator"]
                ),
                "bed": random.choice(self.bed_configurations),
                "pillow": random.choice(["firm", "soft", "memory_foam"]),
                "newspaper": random.choice([None, "WSJ", "NYT", "Local"]),
            }

            guest = (
                self.faker.first_name(),
                self.faker.last_name(),
                self.faker.email(),
                self.faker.phone_number(),
                self.faker.phone_number() if random.random() > 0.7 else None,
                self.faker.address(),
                self.faker.city(),
                self.faker.state_abbr(),
                self.faker.zipcode(),
                self.faker.country(),
                self.faker.date_of_birth(minimum_age=18, maximum_age=80),
                self.faker.country(),
                self.faker.lexify("??" + "????????"),  # passport_number
                self.faker.lexify("ID" + "????????") if random.random() > 0.5 else None,
                self.faker.company() if random.random() > 0.5 else None,
                vip_status,
                json.dumps(preferences),
                random.choice(
                    [None, "vegetarian", "vegan", "gluten_free", "halal", "kosher"]
                ),
                (
                    random.randint(1, 10) if random.random() > 0.3 else None
                ),  # loyalty_member_id
                random.choice([0, 1]),  # marketing_consent
                (
                    random.choice([0, 1])
                    if vip_status == "none" and random.random() > 0.95
                    else 0
                ),  # blacklisted
                "No shows" if random.random() > 0.95 else None,  # blacklist_reason
                random.randint(0, 100),  # total_stays
                random.uniform(0, 50000),  # total_spent
                (
                    self.faker.date_between("-1 year", "today")
                    if random.random() > 0.3
                    else None
                ),
                self.faker.date_time_between("-5 years", "now"),
                self.faker.date_time_between("-5 years", "now"),
            )
            guests.append(guest)

            if (i + 1) % 1000 == 0:
                self.bulk_insert(
                    "guests",
                    guests,
                    [
                        "first_name",
                        "last_name",
                        "email",
                        "phone_number",
                        "alternate_phone",
                        "address",
                        "city",
                        "state_province",
                        "postal_code",
                        "country",
                        "date_of_birth",
                        "nationality",
                        "passport_number",
                        "identity_document",
                        "company_name",
                        "vip_status",
                        "preferences",
                        "dietary_restrictions",
                        "loyalty_member_id",
                        "marketing_consent",
                        "blacklisted",
                        "blacklist_reason",
                        "total_stays",
                        "total_spent",
                        "last_stay_date",
                        "created_at",
                        "updated_at",
                    ],
                )
                guests = []
                print(f"  Generated {i + 1}/{count} guests...")

        if guests:
            self.bulk_insert(
                "guests",
                guests,
                [
                    "first_name",
                    "last_name",
                    "email",
                    "phone_number",
                    "alternate_phone",
                    "address",
                    "city",
                    "state_province",
                    "postal_code",
                    "country",
                    "date_of_birth",
                    "nationality",
                    "passport_number",
                    "identity_document",
                    "company_name",
                    "vip_status",
                    "preferences",
                    "dietary_restrictions",
                    "loyalty_member_id",
                    "marketing_consent",
                    "blacklisted",
                    "blacklist_reason",
                    "total_stays",
                    "total_spent",
                    "last_stay_date",
                    "created_at",
                    "updated_at",
                ],
            )

    def generate_loyalty_members(self):
        """Generate loyalty program members."""
        # Get guests with loyalty_member_id
        guests = self.fetch_all(
            """
            SELECT guest_id, vip_status, total_stays, total_spent
            FROM guests
            WHERE loyalty_member_id IS NOT NULL
            LIMIT 3000
        """
        )

        loyalty_members = []

        tier_requirements = {
            "member": {"nights": 0, "points": 0},
            "silver": {"nights": 10, "points": 10000},
            "gold": {"nights": 25, "points": 25000},
            "platinum": {"nights": 50, "points": 50000},
            "diamond": {"nights": 100, "points": 100000},
        }

        for guest in guests:
            # Determine tier based on stays
            total_nights = guest["total_stays"] * random.randint(2, 5)

            if total_nights >= 100:
                tier = "diamond"
            elif total_nights >= 50:
                tier = "platinum"
            elif total_nights >= 25:
                tier = "gold"
            elif total_nights >= 10:
                tier = "silver"
            else:
                tier = "member"

            points = int(guest["total_spent"] * 10)  # 10 points per dollar

            member = (
                guest["guest_id"],
                f"LM{str(guest['guest_id']).zfill(8)}",
                tier,
                points,
                points * random.randint(2, 5),  # lifetime_points
                points,  # ytd_points
                total_nights,  # ytd_nights
                total_nights * random.randint(2, 5),  # lifetime_nights
                tier_requirements[tier]["points"],  # tier_qualifying_points
                tier_requirements.get(tier, {}).get("points", 999999)
                - points,  # next_tier_points
                self.faker.date_between("-5 years", "-1 year"),  # member_since
                (
                    self.faker.date_between("+6 months", "+1 year")
                    if tier != "member"
                    else None
                ),  # tier_expiry
                (
                    self.faker.date_between("+1 year", "+2 years")
                    if points > 0
                    else None
                ),  # points_expiry
                random.choice([0, 1]),  # is_active
                self.faker.date_time_between("-5 years", "now"),
            )
            loyalty_members.append(member)

        self.bulk_insert(
            "loyalty_members",
            loyalty_members,
            [
                "guest_id",
                "member_number",
                "tier_level",
                "current_points",
                "lifetime_points",
                "ytd_points",
                "ytd_nights",
                "lifetime_nights",
                "tier_qualifying_points",
                "next_tier_points",
                "member_since",
                "tier_expiry_date",
                "points_expiry_date",
                "is_active",
                "created_at",
            ],
        )

    def generate_staff(self):
        """Generate hotel staff members."""
        properties = self.fetch_all("SELECT property_id FROM properties")

        staff = []
        staff_id = 1

        for property in properties:
            # Each property has 50-150 staff members
            num_staff = random.randint(50, 150)

            # Department distribution
            dept_distribution = {
                "front_office": 0.15,
                "housekeeping": 0.30,
                "food_beverage": 0.20,
                "maintenance": 0.10,
                "security": 0.05,
                "spa": 0.05,
                "concierge": 0.05,
                "management": 0.05,
                "accounting": 0.03,
                "hr": 0.02,
            }

            # Generate managers first
            managers = []
            for dept in dept_distribution.keys():
                manager = (
                    property["property_id"],
                    f"EMP{str(staff_id).zfill(6)}",
                    self.faker.first_name(),
                    self.faker.last_name(),
                    self.faker.email(),
                    self.faker.phone_number(),
                    f"{random.randint(100, 999)} {self.faker.street_name()}",
                    self.faker.first_name()
                    + " "
                    + self.faker.last_name(),  # emergency_contact_name
                    self.faker.phone_number(),  # emergency_contact_phone
                    dept,
                    f"{dept.title()} Manager",
                    None,  # manager_id (department heads have no manager)
                    self.faker.date_between("-10 years", "-2 years"),  # hire_date
                    None,  # termination_date
                    "active",  # employment_status
                    "full_time",
                    random.uniform(50000, 100000),  # salary
                    self.faker.date_time_between("-10 years", "now"),
                )
                staff.append(manager)
                managers.append(staff_id)
                staff_id += 1

            # Generate regular staff
            for _ in range(num_staff - len(managers)):
                dept = self.faker.random_element(elements=dept_distribution)

                # Position titles by department
                positions = {
                    "front_office": [
                        "Front Desk Agent",
                        "Night Auditor",
                        "Reservations Agent",
                    ],
                    "housekeeping": [
                        "Room Attendant",
                        "Housekeeping Supervisor",
                        "Laundry Attendant",
                    ],
                    "food_beverage": ["Server", "Bartender", "Cook", "Chef"],
                    "maintenance": [
                        "Maintenance Technician",
                        "HVAC Specialist",
                        "Electrician",
                    ],
                    "security": ["Security Officer", "Security Supervisor"],
                    "spa": ["Spa Therapist", "Massage Therapist", "Spa Receptionist"],
                    "concierge": ["Concierge", "Bell Captain", "Bellhop"],
                    "management": ["Assistant Manager", "Operations Manager"],
                    "accounting": ["Accountant", "Bookkeeper", "Payroll Specialist"],
                    "hr": ["HR Specialist", "Recruiter", "Training Coordinator"],
                }

                # Get manager for this department
                dept_manager = managers[list(dept_distribution.keys()).index(dept)]

                employee = (
                    property["property_id"],
                    f"EMP{str(staff_id).zfill(6)}",
                    self.faker.first_name(),
                    self.faker.last_name(),
                    self.faker.email(),
                    self.faker.phone_number(),
                    self.faker.address(),
                    self.faker.first_name() + " " + self.faker.last_name(),
                    self.faker.phone_number(),
                    dept,
                    random.choice(positions.get(dept, ["Staff"])),
                    dept_manager,
                    self.faker.date_between("-5 years", "-1 month"),
                    (
                        None
                        if random.random() > 0.1
                        else self.faker.date_between("-1 year", "today")
                    ),
                    "active" if random.random() > 0.1 else "terminated",
                    random.choice(["full_time", "part_time", "contract"]),
                    random.uniform(25000, 60000),
                    self.faker.date_time_between("-5 years", "now"),
                )
                staff.append(employee)
                staff_id += 1

                if len(staff) >= 500:
                    self.bulk_insert(
                        "staff",
                        staff,
                        [
                            "property_id",
                            "employee_id",
                            "first_name",
                            "last_name",
                            "email",
                            "phone",
                            "address",
                            "emergency_contact_name",
                            "emergency_contact_phone",
                            "department",
                            "position_title",
                            "manager_id",
                            "hire_date",
                            "termination_date",
                            "employment_status",
                            "employment_type",
                            "salary",
                            "created_at",
                        ],
                    )
                    staff = []

        if staff:
            self.bulk_insert(
                "staff",
                staff,
                [
                    "property_id",
                    "employee_id",
                    "first_name",
                    "last_name",
                    "email",
                    "phone",
                    "address",
                    "emergency_contact_name",
                    "emergency_contact_phone",
                    "department",
                    "position_title",
                    "manager_id",
                    "hire_date",
                    "termination_date",
                    "employment_status",
                    "employment_type",
                    "salary",
                    "created_at",
                ],
            )

    def generate_reservations(self, reservations_per_day: int = 500):
        """Generate hotel reservations."""
        properties = self.fetch_all("SELECT property_id FROM properties")
        guests = self.fetch_all("SELECT guest_id, vip_status FROM guests LIMIT 5000")
        room_types = self.fetch_all(
            """
            SELECT room_type_id, property_id, base_rate, max_occupancy
            FROM room_types
            WHERE is_active = 1
        """
        )

        # Group room types by property
        types_by_property: Dict[int, List[Dict[str, Any]]] = {}
        for rt in room_types:
            prop_id = rt["property_id"]
            if prop_id not in types_by_property:
                types_by_property[prop_id] = []
            types_by_property[prop_id].append(rt)

        reservations = []
        reservation_id = 1

        # Generate reservations for last 60 days and next 30 days
        for days_offset in range(-60, 31):
            check_in_date = date.today() + timedelta(days=days_offset)
            daily_reservations = random.randint(
                int(reservations_per_day * 0.7), int(reservations_per_day * 1.3)
            )

            for _ in range(daily_reservations):
                property = random.choice(properties)

                if property["property_id"] not in types_by_property:
                    continue

                guest = random.choice(guests)
                room_type = random.choice(types_by_property[property["property_id"]])

                # Booking details
                nights = random.randint(1, 7)
                check_out_date = check_in_date + timedelta(days=nights)

                # Room rate calculation (with seasonal variation)
                base_rate = float(room_type["base_rate"])
                if check_in_date.month in [6, 7, 8, 12]:  # Peak season
                    room_rate = base_rate * random.uniform(1.2, 1.5)
                else:
                    room_rate = base_rate * random.uniform(0.8, 1.1)

                # Apply VIP discount
                if guest["vip_status"] in ["gold", "platinum", "diamond"]:
                    room_rate *= 0.9

                total_amount = room_rate * nights

                # Determine status based on dates
                if check_in_date < date.today() - timedelta(days=1):
                    status = random.choice(
                        ["completed", "checked_out", "no_show", "cancelled"]
                    )
                elif check_in_date == date.today():
                    status = random.choice(["confirmed", "checked_in"])
                else:
                    status = random.choice(
                        ["pending", "confirmed", "guaranteed", "cancelled"]
                    )

                confirmation_number = f"CNF{str(reservation_id).zfill(8)}"

                reservation = (
                    confirmation_number,
                    property["property_id"],
                    guest["guest_id"],
                    random.choice(self.booking_channels),
                    check_in_date,
                    check_out_date,
                    nights,
                    random.randint(
                        1, min(4, room_type["max_occupancy"])
                    ),  # adults_count
                    (
                        random.randint(0, 2) if room_type["max_occupancy"] > 2 else 0
                    ),  # children_count
                    room_type["room_type_id"],
                    f"RATE{random.randint(100, 999)}",  # rate_code
                    room_rate,
                    total_amount,
                    (
                        total_amount * 0.2
                        if status in ["confirmed", "guaranteed"]
                        else None
                    ),  # deposit_amount
                    status,
                    f"{random.randint(14, 18)}:00:00",  # arrival_time
                    f"{random.randint(9, 11)}:00:00",  # departure_time
                    (
                        self.faker.sentence() if random.random() > 0.7 else None
                    ),  # special_requests
                    None,  # internal_notes
                    (
                        random.randint(1, 100) if random.random() > 0.9 else None
                    ),  # group_booking_id
                    (
                        random.choice([0, 1]) if random.random() > 0.8 else 0
                    ),  # is_corporate
                    (
                        f"CORP{random.randint(100, 999)}"
                        if random.random() > 0.9
                        else None
                    ),  # corporate_id
                    (
                        random.randint(1, 50) if random.random() > 0.7 else None
                    ),  # agent_id
                    None,  # broker_id
                    (
                        self.faker.date_time_between(
                            check_in_date - timedelta(days=30), check_in_date
                        )
                        if status == "cancelled"
                        else None
                    ),
                    "Guest request" if status == "cancelled" else None,
                    self.faker.date_time_between("-90 days", "now"),
                    self.faker.date_time_between("-90 days", "now"),
                )
                reservations.append(reservation)
                reservation_id += 1

                if len(reservations) >= 1000:
                    self.bulk_insert(
                        "reservations",
                        reservations,
                        [
                            "confirmation_number",
                            "property_id",
                            "guest_id",
                            "booking_channel",
                            "check_in_date",
                            "check_out_date",
                            "room_nights",
                            "adults_count",
                            "children_count",
                            "room_type_id",
                            "rate_code",
                            "room_rate",
                            "total_amount",
                            "deposit_amount",
                            "status",
                            "arrival_time",
                            "departure_time",
                            "special_requests",
                            "internal_notes",
                            "group_booking_id",
                            "is_corporate",
                            "corporate_id",
                            "agent_id",
                            "broker_id",
                            "cancellation_date",
                            "cancellation_reason",
                            "created_at",
                            "updated_at",
                        ],
                    )
                    reservations = []

            print(f"  Generated reservations for day {days_offset}...")

        if reservations:
            self.bulk_insert(
                "reservations",
                reservations,
                [
                    "confirmation_number",
                    "property_id",
                    "guest_id",
                    "booking_channel",
                    "check_in_date",
                    "check_out_date",
                    "room_nights",
                    "adults_count",
                    "children_count",
                    "room_type_id",
                    "rate_code",
                    "room_rate",
                    "total_amount",
                    "deposit_amount",
                    "status",
                    "arrival_time",
                    "departure_time",
                    "special_requests",
                    "internal_notes",
                    "group_booking_id",
                    "is_corporate",
                    "corporate_id",
                    "agent_id",
                    "broker_id",
                    "cancellation_date",
                    "cancellation_reason",
                    "created_at",
                    "updated_at",
                ],
            )

    def generate_room_assignments(self):
        """Generate room assignments for checked-in reservations."""
        # Get reservations that should have room assignments
        reservations = self.fetch_all(
            """
            SELECT reservation_id, property_id, room_type_id, check_in_date,
                   check_out_date, adults_count, children_count
            FROM reservations
            WHERE status IN ('checked_in', 'checked_out', 'completed')
            LIMIT 2000
        """
        )

        # Get available rooms
        rooms = self.fetch_all(
            """
            SELECT room_id, property_id, room_type_id
            FROM rooms
            WHERE status = 'available'
        """
        )

        # Group rooms by property and type
        rooms_by_property_type = {}
        for room in rooms:
            key = (room["property_id"], room["room_type_id"])
            if key not in rooms_by_property_type:
                rooms_by_property_type[key] = []
            rooms_by_property_type[key].append(room["room_id"])

        assignments = []

        for reservation in reservations:
            key = (reservation["property_id"], reservation["room_type_id"])

            if key in rooms_by_property_type and rooms_by_property_type[key]:
                room_id = random.choice(rooms_by_property_type[key])

                # Calculate actual check-in/out times
                check_in_datetime = datetime.combine(
                    reservation["check_in_date"],
                    time(random.randint(14, 20), random.randint(0, 59)),
                )

                if reservation["check_out_date"] <= date.today():
                    check_out_datetime = datetime.combine(
                        reservation["check_out_date"],
                        time(random.randint(8, 12), random.randint(0, 59)),
                    )
                    status = "checked_out"
                else:
                    check_out_datetime = datetime.combine(
                        reservation["check_out_date"], time(11, 0)
                    )
                    status = (
                        "occupied"
                        if reservation["check_in_date"] <= date.today()
                        else "reserved"
                    )

                assignment = (
                    reservation["reservation_id"],
                    room_id,
                    check_in_datetime,
                    check_out_datetime,
                    check_in_datetime if status != "reserved" else None,
                    check_out_datetime if status == "checked_out" else None,
                    reservation["adults_count"],
                    reservation["children_count"],
                    status,
                    (
                        random.choice([0, 1]) if random.random() > 0.9 else 0
                    ),  # early_check_in
                    (
                        random.choice([0, 1]) if random.random() > 0.9 else 0
                    ),  # late_check_out
                    None,  # upgraded_from
                    (
                        random.randint(1, 50) if random.random() > 0.5 else None
                    ),  # assigned_by
                    self.faker.date_time_between("-60 days", "now"),
                )
                assignments.append(assignment)

        self.bulk_insert(
            "room_assignments",
            assignments,
            [
                "reservation_id",
                "room_id",
                "check_in_date",
                "check_out_date",
                "actual_check_in",
                "actual_check_out",
                "adults_count",
                "children_count",
                "status",
                "early_check_in",
                "late_check_out",
                "upgraded_from",
                "assigned_by",
                "created_at",
            ],
        )

    def generate_folios_and_charges(self):
        """Generate guest folios and charges."""
        # Get reservations that should have folios
        reservations = self.fetch_all(
            """
            SELECT r.reservation_id, r.property_id, r.guest_id, r.room_rate,
                   r.room_nights, r.status
            FROM reservations r
            WHERE r.status IN ('checked_in', 'checked_out', 'completed')
            LIMIT 1000
        """
        )

        folios = []
        charges = []
        folio_id = 1

        for reservation in reservations:
            # Create folio
            folio_number = f"FOL{str(folio_id).zfill(8)}"

            # Calculate charges
            room_charges = float(reservation["room_rate"]) * reservation["room_nights"]
            tax_amount = room_charges * 0.15  # 15% tax
            other_charges = random.uniform(0, 500) if random.random() > 0.5 else 0
            total_charges = room_charges + tax_amount + other_charges

            # Payments (for completed stays)
            if reservation["status"] in ["checked_out", "completed"]:
                total_payments = total_charges
                balance = 0
                status = "closed"
            else:
                total_payments = total_charges * random.uniform(0, 0.5)
                balance = total_charges - total_payments
                status = "open"

            folio_record = (
                folio_number,
                reservation["property_id"],
                reservation["reservation_id"],
                reservation["guest_id"],
                status,
                total_charges,
                total_payments,
                balance,
                tax_amount,
                "USD",
                None,  # master_folio_id
                self.faker.date_time_between("-60 days", "now"),
                (
                    self.faker.date_time_between("-30 days", "now")
                    if status == "closed"
                    else None
                ),
            )
            folios.append(folio_record)

            # Generate room charges (one per night)
            for night in range(reservation["room_nights"]):
                charge_date = date.today() - timedelta(days=30 - night)

                room_charge = (
                    folio_id,
                    "room",
                    f"Room Charge - Night {night+1}",
                    1,
                    float(reservation["room_rate"]),
                    float(reservation["room_rate"]),
                    float(reservation["room_rate"]) * 0.15,
                    "rooms",
                    f"ROOM-{reservation['reservation_id']}",
                    charge_date,
                    random.randint(1, 50),  # posted_by
                    None,  # voided_at
                    None,  # void_reason
                )
                charges.append(room_charge)

            # Generate additional charges
            if other_charges > 0:
                # Restaurant charges
                if random.random() > 0.5:
                    restaurant_charge = (
                        folio_id,
                        "food",
                        "Restaurant - Dinner",
                        1,
                        random.uniform(50, 200),
                        random.uniform(50, 200),
                        random.uniform(5, 20),
                        "restaurant",
                        None,
                        date.today() - timedelta(days=random.randint(1, 30)),
                        random.randint(1, 50),
                        None,
                        None,
                    )
                    charges.append(restaurant_charge)

                # Spa charges
                if random.random() > 0.7:
                    spa_charge = (
                        folio_id,
                        "spa",
                        "Spa Treatment",
                        1,
                        random.uniform(100, 300),
                        random.uniform(100, 300),
                        random.uniform(10, 30),
                        "spa",
                        None,
                        date.today() - timedelta(days=random.randint(1, 30)),
                        random.randint(1, 50),
                        None,
                        None,
                    )
                    charges.append(spa_charge)

            folio_id += 1

            if len(folios) >= 500:
                self.bulk_insert(
                    "folios",
                    folios,
                    [
                        "folio_number",
                        "property_id",
                        "reservation_id",
                        "guest_id",
                        "status",
                        "total_charges",
                        "total_payments",
                        "balance_due",
                        "tax_amount",
                        "currency",
                        "master_folio_id",
                        "created_at",
                        "closed_at",
                    ],
                )
                folios = []

            if len(charges) >= 1000:
                self.bulk_insert(
                    "folio_charges",
                    charges,
                    [
                        "folio_id",
                        "charge_type",
                        "description",
                        "quantity",
                        "unit_price",
                        "amount",
                        "tax_amount",
                        "department",
                        "reference",
                        "posted_date",
                        "posted_by",
                        "voided_at",
                        "void_reason",
                    ],
                )
                charges = []

        # Insert remaining data
        if folios:
            self.bulk_insert(
                "folios",
                folios,
                [
                    "folio_number",
                    "property_id",
                    "reservation_id",
                    "guest_id",
                    "status",
                    "total_charges",
                    "total_payments",
                    "balance_due",
                    "tax_amount",
                    "currency",
                    "master_folio_id",
                    "created_at",
                    "closed_at",
                ],
            )

        if charges:
            self.bulk_insert(
                "folio_charges",
                charges,
                [
                    "folio_id",
                    "charge_type",
                    "description",
                    "quantity",
                    "unit_price",
                    "amount",
                    "tax_amount",
                    "department",
                    "reference",
                    "posted_date",
                    "posted_by",
                    "voided_at",
                    "void_reason",
                ],
            )

    def generate_payments(self):
        """Generate payment records."""
        folios = self.fetch_all(
            """
            SELECT folio_id, total_charges, total_payments
            FROM folios
            WHERE total_payments > 0
            LIMIT 500
        """
        )

        payments = []

        for folio in folios:
            # Generate 1-3 payments per folio
            num_payments = random.randint(1, 3)
            remaining_amount = float(folio["total_payments"])

            for i in range(num_payments):
                if remaining_amount <= 0:
                    break

                if i == num_payments - 1:
                    amount = remaining_amount
                else:
                    amount = remaining_amount * random.uniform(0.3, 0.7)

                remaining_amount -= amount

                payment = (
                    folio["folio_id"],
                    random.choice(
                        [
                            "credit_card",
                            "debit_card",
                            "cash",
                            "bank_transfer",
                            "mobile_payment",
                        ]
                    ),
                    amount,
                    "USD",
                    f"TXN{random.randint(100000, 999999)}",
                    f"AUTH{random.randint(100000, 999999)}",
                    (
                        str(random.randint(1000, 9999))
                        if random.random() > 0.5
                        else None
                    ),  # card_last_four
                    self.faker.date_time_between("-30 days", "now"),
                    random.randint(1, 50),  # processed_by
                    random.choice([0, 1]),  # is_processed
                    0,  # refunded_amount
                )
                payments.append(payment)

        self.bulk_insert(
            "payments",
            payments,
            [
                "folio_id",
                "payment_method",
                "amount",
                "currency",
                "reference_number",
                "authorization_code",
                "card_last_four",
                "payment_date",
                "processed_by",
                "is_processed",
                "refunded_amount",
            ],
        )

    def generate_loyalty_transactions(self):
        """Generate loyalty points transactions."""
        members = self.fetch_all(
            """
            SELECT member_id, guest_id, current_points
            FROM loyalty_members
            WHERE is_active = 1
            LIMIT 500
        """
        )

        # Get folios for these guests
        guest_ids = [m["guest_id"] for m in members]
        folios = (
            self.fetch_all(
                f"""
            SELECT folio_id, guest_id, total_charges
            FROM folios
            WHERE guest_id IN ({','.join(map(str, guest_ids))})
            AND status = 'closed'
        """
            )
            if guest_ids
            else []
        )

        # Group folios by guest
        folios_by_guest = {}
        for folio in folios:
            guest_id = folio["guest_id"]
            if guest_id not in folios_by_guest:
                folios_by_guest[guest_id] = []
            folios_by_guest[guest_id].append(folio)

        transactions = []

        for member in members:
            guest_folios = folios_by_guest.get(member["guest_id"], [])

            # Generate earning transactions
            for folio in guest_folios[:5]:  # Limit to 5 transactions per member
                points_earned = int(
                    float(folio["total_charges"]) * 10
                )  # 10 points per dollar

                transaction = (
                    member["member_id"],
                    "earn",
                    points_earned,
                    f"Points earned for stay - Folio {folio['folio_id']}",
                    folio["folio_id"],
                    self.faker.date_between("+2 years", "+3 years"),  # expiry_date
                    self.faker.date_time_between("-30 days", "now"),
                )
                transactions.append(transaction)

            # Generate redemption transactions
            if member["current_points"] > 10000 and random.random() > 0.5:
                points_redeemed = random.randint(
                    5000, min(20000, member["current_points"])
                )

                transaction = (
                    member["member_id"],
                    "redeem",
                    -points_redeemed,
                    "Points redeemed for free night",
                    None,  # folio_id
                    None,  # expiry_date
                    self.faker.date_time_between("-30 days", "now"),
                )
                transactions.append(transaction)

        self.bulk_insert(
            "loyalty_transactions",
            transactions,
            [
                "member_id",
                "transaction_type",
                "points",
                "description",
                "folio_id",
                "expiry_date",
                "transaction_date",
            ],
        )

    def generate_housekeeping_tasks(self):
        """Generate housekeeping tasks."""
        rooms = self.fetch_all(
            """
            SELECT room_id, property_id, housekeeping_status
            FROM rooms
            LIMIT 500
        """
        )

        # Get housekeeping staff
        housekeepers = self.fetch_all(
            """
            SELECT staff_id, property_id
            FROM staff
            WHERE department = 'housekeeping'
            AND employment_status = 'active'
        """
        )

        # Group housekeepers by property
        housekeepers_by_property = {}
        for hk in housekeepers:
            prop_id = hk["property_id"]
            if prop_id not in housekeepers_by_property:
                housekeepers_by_property[prop_id] = []
            housekeepers_by_property[prop_id].append(hk["staff_id"])

        tasks = []

        for room in rooms:
            # Generate daily cleaning task
            task_type = (
                "daily_cleaning"
                if room["housekeeping_status"] != "clean"
                else "inspection"
            )

            housekeepers_list = housekeepers_by_property.get(room["property_id"], [])

            task = (
                room["room_id"],
                task_type,
                "high" if room["housekeeping_status"] == "dirty" else "medium",
                random.choice(["pending", "in_progress", "completed"]),
                date.today(),
                f"{random.randint(9, 14)}:00:00",
                random.choice(housekeepers_list) if housekeepers_list else None,
                (
                    self.faker.date_time_between("-8 hours", "now")
                    if random.random() > 0.5
                    else None
                ),
                (
                    self.faker.date_time_between("-4 hours", "now")
                    if random.random() > 0.3
                    else None
                ),
                (
                    random.choice(housekeepers_list)
                    if housekeepers_list and random.random() > 0.7
                    else None
                ),
                (
                    self.faker.date_time_between("-2 hours", "now")
                    if random.random() > 0.5
                    else None
                ),
                None,  # notes
                (
                    json.dumps({"towels": 2, "sheets": 1, "toiletries": 1})
                    if random.random() > 0.5
                    else None
                ),
                self.faker.date_time_between("-24 hours", "now"),
            )
            tasks.append(task)

        self.bulk_insert(
            "housekeeping_tasks",
            tasks,
            [
                "room_id",
                "task_type",
                "priority",
                "status",
                "scheduled_date",
                "scheduled_time",
                "assigned_to",
                "started_at",
                "completed_at",
                "inspected_by",
                "inspected_at",
                "notes",
                "supplies_used",
                "created_at",
            ],
        )

    def generate_maintenance_requests(self):
        """Generate maintenance requests."""
        rooms = self.fetch_all(
            """
            SELECT room_id, property_id
            FROM rooms
            WHERE maintenance_status != 'none'
            LIMIT 100
        """
        )

        properties = self.fetch_all("SELECT property_id FROM properties")

        # Get maintenance staff
        maintenance_staff = self.fetch_all(
            """
            SELECT staff_id, property_id
            FROM staff
            WHERE department = 'maintenance'
            AND employment_status = 'active'
        """
        )

        # Group maintenance staff by property
        maintenance_by_property = {}
        for ms in maintenance_staff:
            prop_id = ms["property_id"]
            if prop_id not in maintenance_by_property:
                maintenance_by_property[prop_id] = []
            maintenance_by_property[prop_id].append(ms["staff_id"])

        requests = []

        issue_types = [
            "plumbing",
            "electrical",
            "hvac",
            "appliance",
            "structural",
            "cosmetic",
            "other",
        ]

        # Room-specific requests
        for room in rooms:
            maintenance_list = maintenance_by_property.get(room["property_id"], [])

            request = (
                room["room_id"],
                room["property_id"],
                random.choice(issue_types),
                self.faker.sentence(),
                random.choice(["low", "medium", "high", "urgent"]),
                random.choice(["open", "in_progress", "completed", "cancelled"]),
                (
                    random.choice(maintenance_list) if maintenance_list else None
                ),  # reported_by
                self.faker.date_time_between("-30 days", "now"),
                (
                    random.choice(maintenance_list)
                    if maintenance_list and random.random() > 0.5
                    else None
                ),
                random.uniform(50, 1000) if random.random() > 0.5 else None,
                random.uniform(30, 800) if random.random() > 0.3 else None,
                json.dumps(["parts"]) if random.random() > 0.7 else None,
                self.faker.sentence() if random.random() > 0.5 else None,
                (
                    self.faker.date_time_between("-7 days", "now")
                    if random.random() > 0.5
                    else None
                ),
                self.faker.date_time_between("-30 days", "now"),
            )
            requests.append(request)

        # Property-wide requests
        for property in properties[:5]:
            maintenance_list = maintenance_by_property.get(property["property_id"], [])

            request = (
                None,  # room_id
                property["property_id"],
                random.choice(["hvac", "elevator", "pool", "parking", "landscaping"]),
                self.faker.sentence(),
                random.choice(["low", "medium", "high"]),
                random.choice(["open", "in_progress", "scheduled"]),
                random.choice(maintenance_list) if maintenance_list else None,
                self.faker.date_time_between("-30 days", "now"),
                (
                    random.choice(maintenance_list)
                    if maintenance_list and random.random() > 0.5
                    else None
                ),
                random.uniform(500, 5000),
                None,
                None,
                None,
                None,
                self.faker.date_time_between("-30 days", "now"),
            )
            requests.append(request)

        self.bulk_insert(
            "maintenance_requests",
            requests,
            [
                "room_id",
                "property_id",
                "issue_type",
                "description",
                "priority",
                "status",
                "reported_by",
                "reported_date",
                "assigned_to",
                "estimated_cost",
                "actual_cost",
                "parts_required",
                "resolution_notes",
                "completed_at",
                "created_at",
            ],
        )

    def generate_guest_services(self):
        """Generate guest service requests and restaurant/spa bookings."""
        guests = self.fetch_all(
            """
            SELECT g.guest_id, r.reservation_id, r.property_id
            FROM guests g
            JOIN reservations r ON g.guest_id = r.guest_id
            WHERE r.status IN ('checked_in', 'confirmed')
            LIMIT 500
        """
        )

        # Guest requests
        guest_requests = []
        request_types = [
            "housekeeping",
            "concierge",
            "maintenance",
            "room_service",
            "amenities",
            "other",
        ]

        for guest in guests[:200]:
            if random.random() > 0.5:
                request = (
                    guest["guest_id"],
                    guest["reservation_id"],
                    random.choice(request_types),
                    self.faker.sentence(),
                    random.choice(["low", "medium", "high", "urgent"]),
                    random.choice(["pending", "assigned", "in_progress", "completed"]),
                    random.randint(1, 50) if random.random() > 0.5 else None,
                    self.faker.date_time_between("-7 days", "now"),
                    (
                        self.faker.date_time_between("-7 days", "now")
                        if random.random() > 0.5
                        else None
                    ),
                    self.faker.sentence() if random.random() > 0.5 else None,
                    random.randint(1, 5) if random.random() > 0.7 else None,
                    self.faker.date_time_between("-7 days", "now"),
                )
                guest_requests.append(request)

        self.bulk_insert(
            "guest_requests",
            guest_requests,
            [
                "guest_id",
                "reservation_id",
                "request_type",
                "request_details",
                "priority",
                "status",
                "assigned_to",
                "requested_at",
                "completed_at",
                "resolution_notes",
                "satisfaction_rating",
                "created_at",
            ],
        )

    def generate_rate_plans(self):
        """Generate rate plans and overrides."""
        room_types = self.fetch_all(
            """
            SELECT room_type_id, property_id, base_rate
            FROM room_types
            WHERE is_active = 1
            LIMIT 100
        """
        )

        rate_plans = []
        rate_overrides = []

        plan_types = [
            ("Standard Rate", "STD", 1.0),
            ("Advance Purchase", "ADV", 0.85),
            ("Weekend Special", "WKD", 0.9),
            ("Corporate Rate", "CORP", 0.8),
            ("Group Rate", "GRP", 0.75),
            ("Package Deal", "PKG", 1.1),
        ]

        for room_type in room_types:
            # Generate 2-4 rate plans per room type
            selected_plans = random.sample(
                plan_types, random.randint(2, min(4, len(plan_types)))
            )

            for plan_name, plan_code, rate_multiplier in selected_plans:
                base_rate = float(room_type["base_rate"])

                rate_plan = (
                    room_type["property_id"],
                    room_type["room_type_id"],
                    plan_name,
                    plan_code,
                    self.faker.sentence(),
                    base_rate * rate_multiplier,
                    (
                        base_rate * rate_multiplier * 1.2
                        if plan_code == "WKD"
                        else None
                    ),  # weekend_rate
                    1 if plan_code == "ADV" else 2,  # minimum_stay
                    30 if plan_code == "ADV" else None,  # maximum_stay
                    14 if plan_code == "ADV" else None,  # advance_booking_days
                    (
                        "48 hours" if plan_code == "ADV" else "24 hours"
                    ),  # cancellation_policy
                    (
                        json.dumps(["breakfast"]) if plan_code == "PKG" else None
                    ),  # inclusions
                    self.faker.date_between("-1 year", "today"),
                    self.faker.date_between("+6 months", "+1 year"),
                    random.choice([0, 1]),
                    self.faker.date_time_between("-1 year", "now"),
                )
                rate_plans.append(rate_plan)

        self.bulk_insert(
            "rate_plans",
            rate_plans,
            [
                "property_id",
                "room_type_id",
                "plan_name",
                "plan_code",
                "description",
                "base_rate",
                "weekend_rate",
                "minimum_stay",
                "maximum_stay",
                "advance_booking_days",
                "cancellation_policy",
                "inclusions",
                "valid_from",
                "valid_to",
                "is_active",
                "created_at",
            ],
        )

        # Generate rate overrides for special dates
        properties = self.fetch_all("SELECT property_id FROM properties")

        for property in properties[:5]:
            # Generate overrides for holidays and special events
            for _ in range(10):
                override_date = self.faker.date_between("today", "+60 days")
                property_room_types = [
                    rt
                    for rt in room_types
                    if rt["property_id"] == property["property_id"]
                ]

                if property_room_types:
                    room_type = random.choice(property_room_types)

                    override = (
                        property["property_id"],
                        room_type["room_type_id"],
                        override_date,
                        float(room_type["base_rate"]) * random.uniform(1.2, 2.0),
                        random.choice(
                            ["Holiday", "Special Event", "Peak Season", "Convention"]
                        ),
                        random.randint(2, 3) if random.random() > 0.5 else None,
                        random.choice([0, 1]) if random.random() > 0.8 else 0,
                        random.choice([0, 1]) if random.random() > 0.8 else 0,
                        random.randint(1, 50),  # created_by
                        self.faker.date_time_between("-30 days", "now"),
                    )
                    rate_overrides.append(override)

        self.bulk_insert(
            "rate_overrides",
            rate_overrides,
            [
                "property_id",
                "room_type_id",
                "override_date",
                "override_rate",
                "reason",
                "minimum_stay",
                "closed_to_arrival",
                "closed_to_departure",
                "created_by",
                "created_at",
            ],
        )


def main():
    """Run function to run the generator."""
    import argparse

    parser = argparse.ArgumentParser(
        description="Generate test data for Hotel Chain Management"
    )
    parser.add_argument("--host", default="localhost", help="MySQL host")
    parser.add_argument("--port", type=int, default=3340, help="MySQL port")
    parser.add_argument("--user", default="hotel_admin", help="MySQL user")
    parser.add_argument("--password", default="hotel_pass_2024", help="MySQL password")
    parser.add_argument("--database", default="hotel_chain", help="MySQL database")
    parser.add_argument(
        "--properties", type=int, default=10, help="Number of properties"
    )
    parser.add_argument(
        "--rooms-per-property", type=int, default=200, help="Rooms per property"
    )
    parser.add_argument("--guests", type=int, default=10000, help="Number of guests")
    parser.add_argument(
        "--reservations-per-day",
        type=int,
        default=500,
        help="Average reservations per day",
    )

    args = parser.parse_args()

    generator = HotelChainGenerator(
        host=args.host,
        port=args.port,
        user=args.user,
        password=args.password,
        database=args.database,
    )

    try:
        generator.connect()
        generator.generate_all_data(
            properties=args.properties,
            rooms_per_property=args.rooms_per_property,
            guests=args.guests,
            reservations_per_day=args.reservations_per_day,
        )
    finally:
        generator.disconnect()


if __name__ == "__main__":
    main()
