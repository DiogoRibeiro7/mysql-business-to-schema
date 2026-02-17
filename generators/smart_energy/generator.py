#!/usr/bin/env python3
"""
Smart Energy Management System Data Generator
Generates realistic data for commercial building energy monitoring with renewables and optimization
"""

import csv
import json
import random
import hashlib
from datetime import datetime, timedelta, time
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
    "buildings": 5,
    "floors_per_building": 10,
    "zones_per_floor": 8,
    "tenants": 20,
    "meters_per_building": 15,
    "solar_systems": 3,  # Some buildings have solar
    "battery_systems": 2,  # Some buildings have batteries
    "hvac_units_per_building": 5,
    "days_of_history": 30,
    "readings_per_hour": 12,  # Every 5 minutes
}

class SmartEnergyGenerator:
    def __init__(self):
        self.buildings = []
        self.floors = []
        self.zones = []
        self.tenants = []
        self.tenant_assignments = []
        self.meter_types = []
        self.energy_meters = []
        self.solar_systems = []
        self.battery_storage = []
        self.hvac_units = []
        self.equipment_inventory = []
        self.energy_readings = []
        self.energy_consumption_hourly = []
        self.energy_consumption_daily = []
        self.solar_production = []
        self.battery_status = []
        self.hvac_telemetry = []
        self.demand_response_events = []

        # Counters
        self.floor_id = 0
        self.zone_id = 0
        self.assignment_id = 0
        self.meter_id = 0
        self.system_id = 0
        self.battery_id = 0
        self.unit_id = 0
        self.equipment_id = 0
        self.reading_id = 0
        self.consumption_id = 0
        self.production_id = 0
        self.status_id = 0
        self.telemetry_id = 0
        self.event_id = 0

        # Start date for historical data
        self.start_date = datetime.now() - timedelta(days=CONFIG['days_of_history'])

    def generate_all(self):
        """Generate all smart energy data"""
        print("Starting Smart Energy Management Data Generation...")
        print(f"Configuration:")
        print(f"  Buildings: {CONFIG['buildings']}")
        print(f"  Total floors: {CONFIG['buildings'] * CONFIG['floors_per_building']}")
        print(f"  Total zones: {CONFIG['buildings'] * CONFIG['floors_per_building'] * CONFIG['zones_per_floor']}")
        print(f"  Days of history: {CONFIG['days_of_history']}")

        # Core infrastructure
        self.generate_buildings()
        self.generate_floors_and_zones()
        self.generate_tenants()

        # Energy infrastructure
        self.generate_meter_types()
        self.generate_energy_meters()

        # Renewable energy
        self.generate_solar_systems()
        self.generate_battery_storage()

        # HVAC and equipment
        self.generate_hvac_units()
        self.generate_equipment()

        # Time series data
        self.generate_energy_consumption()
        self.generate_solar_and_battery_data()
        self.generate_hvac_telemetry()

        # Demand response
        self.generate_demand_response_events()

        # Save all data
        self.save_all()

    def generate_buildings(self):
        """Generate commercial buildings"""
        print(f"Generating {CONFIG['buildings']} buildings...")

        building_types = ['office', 'retail', 'mixed', 'hotel', 'hospital']
        cities = ['New York', 'San Francisco', 'Chicago', 'Boston', 'Seattle']
        energy_ratings = ['A+', 'A', 'B', 'B', 'C']  # Most are efficient

        for i in range(CONFIG['buildings']):
            building = {
                'building_id': i + 1,
                'building_code': f"BLD{str(i+1).zfill(3)}",
                'building_name': f"{fake.company()} {random.choice(['Tower', 'Center', 'Plaza', 'Building'])}",
                'address': fake.street_address(),
                'city': cities[i % len(cities)],
                'postal_code': fake.postcode(),
                'latitude': float(fake.latitude()),
                'longitude': float(fake.longitude()),
                'total_area_sqm': round(random.uniform(5000, 50000), 2),
                'floors_count': CONFIG['floors_per_building'],
                'year_built': random.randint(1980, 2020),
                'building_type': building_types[i % len(building_types)],
                'energy_rating': energy_ratings[i % len(energy_ratings)],
                'occupancy_type': random.choice(['owner_occupied', 'single_tenant', 'multi_tenant']),
                'typical_occupancy': random.randint(100, 2000),
                'status': 'active',
                'created_at': fake.date_time_between(start_date='-5y', end_date='-1y'),
                'updated_at': fake.date_time_between(start_date='-30d', end_date='now')
            }
            self.buildings.append(building)

    def generate_floors_and_zones(self):
        """Generate floors and zones for buildings"""
        print("Generating floors and zones...")

        zone_types = ['office', 'conference', 'lobby', 'corridor', 'restroom', 'kitchen', 'server_room', 'storage']
        orientations = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW']

        for building in self.buildings:
            building_area = building['total_area_sqm']
            floor_area = building_area / building['floors_count']

            for floor_num in range(building['floors_count']):
                self.floor_id += 1
                floor = {
                    'floor_id': self.floor_id,
                    'building_id': building['building_id'],
                    'floor_number': floor_num,
                    'floor_name': f"Floor {floor_num}" if floor_num > 0 else "Ground Floor",
                    'area_sqm': round(floor_area, 2),
                    'height_meters': round(random.uniform(3.0, 4.5), 2),
                    'is_mechanical': floor_num == building['floors_count'] - 1,  # Top floor
                    'has_hvac_zone': True,
                    'typical_occupancy': building['typical_occupancy'] // building['floors_count'],
                    'created_at': building['created_at'],
                    'updated_at': building['updated_at']
                }
                self.floors.append(floor)

                # Generate zones for this floor
                zone_area = floor_area / CONFIG['zones_per_floor']
                for zone_num in range(CONFIG['zones_per_floor']):
                    self.zone_id += 1

                    # Create occupancy schedule
                    occupancy_schedule = {
                        "monday": [{"start": "08:00", "end": "18:00"}],
                        "tuesday": [{"start": "08:00", "end": "18:00"}],
                        "wednesday": [{"start": "08:00", "end": "18:00"}],
                        "thursday": [{"start": "08:00", "end": "18:00"}],
                        "friday": [{"start": "08:00", "end": "17:00"}],
                        "saturday": [] if building['building_type'] == 'office' else [{"start": "09:00", "end": "14:00"}],
                        "sunday": []
                    }

                    zone = {
                        'zone_id': self.zone_id,
                        'zone_code': f"Z{building['building_code']}{floor_num:02d}{zone_num:02d}",
                        'floor_id': self.floor_id,
                        'zone_name': f"{random.choice(zone_types).replace('_', ' ').title()} {zone_num+1}",
                        'zone_type': random.choice(zone_types),
                        'area_sqm': round(zone_area * random.uniform(0.8, 1.2), 2),
                        'has_windows': zone_num < 4,  # Perimeter zones have windows
                        'window_orientation': random.choice(orientations) if zone_num < 4 else 'None',
                        'target_temperature_c': round(random.uniform(20, 24), 2),
                        'target_humidity_pct': round(random.uniform(40, 60), 2),
                        'occupancy_schedule': json.dumps(occupancy_schedule),
                        'max_occupancy': random.randint(5, 50),
                        'created_at': floor['created_at'],
                        'updated_at': floor['updated_at']
                    }
                    self.zones.append(zone)

    def generate_tenants(self):
        """Generate tenant organizations"""
        print(f"Generating {CONFIG['tenants']} tenants...")

        for i in range(CONFIG['tenants']):
            tenant = {
                'tenant_id': i + 1,
                'tenant_code': f"TEN{str(i+1).zfill(4)}",
                'company_name': fake.company(),
                'contact_name': fake.name(),
                'contact_email': fake.company_email(),
                'contact_phone': fake.phone_number()[:20],
                'lease_start_date': fake.date_between(start_date='-3y', end_date='today'),
                'lease_end_date': fake.date_between(start_date='+1y', end_date='+5y'),
                'billing_type': random.choice(['fixed', 'metered', 'hybrid']),
                'monthly_base_rate': round(random.uniform(1000, 50000), 2),
                'energy_budget_kwh': round(random.uniform(5000, 100000), 2),
                'status': random.choices(['active', 'pending', 'expired'], weights=[90, 5, 5])[0],
                'created_at': fake.date_time_between(start_date='-3y', end_date='-1m'),
                'updated_at': fake.date_time_between(start_date='-7d', end_date='now')
            }
            self.tenants.append(tenant)

            # Assign zones to tenants
            num_zones = random.randint(1, 5)
            assigned_zones = random.sample(self.zones, min(num_zones, len(self.zones)))

            for zone in assigned_zones:
                self.assignment_id += 1
                assignment = {
                    'assignment_id': self.assignment_id,
                    'tenant_id': tenant['tenant_id'],
                    'zone_id': zone['zone_id'],
                    'assignment_start_date': tenant['lease_start_date'],
                    'assignment_end_date': tenant['lease_end_date'],
                    'is_exclusive': random.random() > 0.2,
                    'usage_percentage': 100.0 if random.random() > 0.2 else round(random.uniform(20, 80), 2),
                    'created_at': tenant['created_at']
                }
                self.tenant_assignments.append(assignment)

    def generate_meter_types(self):
        """Generate meter type definitions"""
        print("Generating meter types...")

        meter_type_configs = [
            ('ELEC_MAIN', 'Main Electricity', 'kWh', 300, True, False),
            ('ELEC_SUB', 'Sub Electricity', 'kWh', 300, False, True),
            ('GAS_MAIN', 'Main Gas', 'm3', 900, True, False),
            ('WATER_MAIN', 'Main Water', 'm3', 3600, True, False),
            ('SOLAR_GEN', 'Solar Generation', 'kWh', 300, False, False),
            ('BATTERY', 'Battery Storage', 'kWh', 300, False, False),
            ('HVAC_POWER', 'HVAC Power', 'kW', 60, False, True),
        ]

        for i, (code, name, unit, freq, is_utility, is_sub) in enumerate(meter_type_configs, 1):
            meter_type = {
                'meter_type_id': i,
                'type_code': code,
                'type_name': name,
                'measurement_unit': unit,
                'reading_frequency_seconds': freq,
                'is_utility_meter': is_utility,
                'is_sub_meter': is_sub,
                'created_at': fake.date_time_between(start_date='-5y', end_date='-4y')
            }
            self.meter_types.append(meter_type)

    def generate_energy_meters(self):
        """Generate energy meters for buildings"""
        print("Generating energy meters...")

        manufacturers = ['Schneider', 'Siemens', 'ABB', 'Honeywell', 'GE']
        communication_types = ['modbus', 'bacnet', 'mqtt', 'api']

        for building in self.buildings:
            # Main utility meters
            for meter_type in self.meter_types:
                if meter_type['is_utility_meter']:
                    self.meter_id += 1
                    meter = {
                        'meter_id': self.meter_id,
                        'meter_code': f"MTR{building['building_code']}{meter_type['type_code']}",
                        'meter_type_id': meter_type['meter_type_id'],
                        'building_id': building['building_id'],
                        'zone_id': None,  # Main meters not tied to zones
                        'meter_name': f"{building['building_name']} {meter_type['type_name']}",
                        'manufacturer': random.choice(manufacturers),
                        'model': f"Model-{random.randint(100, 999)}",
                        'serial_number': fake.bothify(text='SN########'),
                        'installation_date': fake.date_between(start_date='-5y', end_date='-1y'),
                        'calibration_date': fake.date_between(start_date='-1y', end_date='today'),
                        'next_calibration_date': fake.date_between(start_date='+6m', end_date='+1y'),
                        'max_reading_value': 999999.999,
                        'meter_constant': 1.0,
                        'is_smart_meter': True,
                        'communication_type': random.choice(communication_types),
                        'ip_address': fake.ipv4() if random.random() > 0.3 else None,
                        'last_reading_time': fake.date_time_between(start_date='-1h', end_date='now'),
                        'status': random.choices(['active', 'inactive', 'faulty'], weights=[95, 3, 2])[0],
                        'parent_meter_id': None,
                        'created_at': building['created_at'],
                        'updated_at': fake.date_time_between(start_date='-7d', end_date='now')
                    }
                    self.energy_meters.append(meter)

            # Sub-meters for some zones
            building_zones = [z for z in self.zones if z['floor_id'] in
                            [f['floor_id'] for f in self.floors if f['building_id'] == building['building_id']]]

            for zone in random.sample(building_zones, min(10, len(building_zones))):
                if zone['zone_type'] in ['office', 'server_room', 'kitchen']:
                    self.meter_id += 1
                    # Find parent meter (main electricity meter)
                    parent_meter = next((m for m in self.energy_meters
                                      if m['building_id'] == building['building_id']
                                      and m['meter_type_id'] == 1), None)  # ELEC_MAIN

                    meter = {
                        'meter_id': self.meter_id,
                        'meter_code': f"MTR{zone['zone_code']}",
                        'meter_type_id': 2,  # ELEC_SUB
                        'building_id': building['building_id'],
                        'zone_id': zone['zone_id'],
                        'meter_name': f"{zone['zone_name']} Sub-meter",
                        'manufacturer': random.choice(manufacturers),
                        'model': f"Model-{random.randint(100, 999)}",
                        'serial_number': fake.bothify(text='SN########'),
                        'installation_date': fake.date_between(start_date='-3y', end_date='-1y'),
                        'calibration_date': fake.date_between(start_date='-6m', end_date='today'),
                        'next_calibration_date': fake.date_between(start_date='+6m', end_date='+1y'),
                        'max_reading_value': 99999.999,
                        'meter_constant': 1.0,
                        'is_smart_meter': True,
                        'communication_type': random.choice(communication_types),
                        'ip_address': fake.ipv4() if random.random() > 0.5 else None,
                        'last_reading_time': fake.date_time_between(start_date='-1h', end_date='now'),
                        'status': 'active',
                        'parent_meter_id': parent_meter['meter_id'] if parent_meter else None,
                        'created_at': zone['created_at'],
                        'updated_at': fake.date_time_between(start_date='-7d', end_date='now')
                    }
                    self.energy_meters.append(meter)

    def generate_solar_systems(self):
        """Generate solar PV systems for some buildings"""
        print(f"Generating {CONFIG['solar_systems']} solar systems...")

        # Only some buildings get solar
        solar_buildings = random.sample(self.buildings, min(CONFIG['solar_systems'], len(self.buildings)))

        for building in solar_buildings:
            self.system_id += 1

            # Calculate capacity based on roof area (assume 20% of building footprint)
            roof_area = building['total_area_sqm'] / building['floors_count'] * 0.2
            # Assume 200W/m2 panel efficiency
            capacity = roof_area * 0.2

            system = {
                'system_id': self.system_id,
                'system_code': f"SOL{building['building_code']}",
                'building_id': building['building_id'],
                'system_name': f"{building['building_name']} Solar Array",
                'installation_date': fake.date_between(start_date='-5y', end_date='-1y'),
                'capacity_kw': round(capacity, 3),
                'panel_count': int(capacity / 0.4),  # 400W panels
                'panel_type': random.choice(['Monocrystalline', 'Polycrystalline', 'Thin-film']),
                'inverter_model': f"Inverter-{random.randint(1000, 9999)}",
                'inverter_count': max(1, int(capacity / 50)),  # 50kW inverters
                'orientation_degrees': random.randint(160, 200),  # Mostly south-facing
                'tilt_degrees': random.randint(15, 45),
                'annual_production_estimate_kwh': capacity * 1500,  # 1500 hours/year
                'degradation_rate_yearly': 0.5,
                'warranty_end_date': fake.date_between(start_date='+15y', end_date='+25y'),
                'status': 'active',
                'created_at': building['created_at'],
                'updated_at': fake.date_time_between(start_date='-7d', end_date='now')
            }
            self.solar_systems.append(system)

    def generate_battery_storage(self):
        """Generate battery storage systems"""
        print(f"Generating {CONFIG['battery_systems']} battery systems...")

        # Only buildings with solar get batteries
        battery_buildings = [s['building_id'] for s in self.solar_systems[:CONFIG['battery_systems']]]

        for building_id in battery_buildings:
            self.battery_id += 1

            # Size battery based on solar capacity
            solar_system = next(s for s in self.solar_systems if s['building_id'] == building_id)
            battery_capacity = solar_system['capacity_kw'] * 2  # 2 hours of storage

            battery = {
                'battery_id': self.battery_id,
                'battery_code': f"BAT{str(building_id).zfill(3)}",
                'building_id': building_id,
                'system_name': f"Building {building_id} Battery Storage",
                'manufacturer': random.choice(['Tesla', 'LG Chem', 'BYD', 'Samsung SDI']),
                'model': f"PowerPack-{random.randint(100, 999)}",
                'capacity_kwh': round(battery_capacity, 3),
                'max_power_kw': round(battery_capacity / 2, 3),  # C/2 rate
                'efficiency_pct': round(random.uniform(92, 98), 2),
                'cycles_count': random.randint(100, 1000),
                'max_cycles': random.randint(3000, 6000),
                'depth_of_discharge_pct': 80.0,
                'state_of_charge_pct': round(random.uniform(20, 80), 2),
                'installation_date': solar_system['installation_date'],
                'warranty_end_date': fake.date_between(start_date='+5y', end_date='+10y'),
                'temperature_c': round(random.uniform(15, 25), 2),
                'status': random.choice(['active', 'charging', 'discharging', 'idle']),
                'created_at': solar_system['created_at'],
                'updated_at': fake.date_time_between(start_date='-1d', end_date='now')
            }
            self.battery_storage.append(battery)

    def generate_hvac_units(self):
        """Generate HVAC units for buildings"""
        print("Generating HVAC units...")

        unit_types = ['ahu', 'vav', 'chiller', 'boiler', 'rooftop']
        refrigerants = ['R-410A', 'R-32', 'R-134a', 'R-407C']

        for building in self.buildings:
            building_zones = [z['zone_id'] for z in self.zones
                            if z['floor_id'] in [f['floor_id'] for f in self.floors
                                                if f['building_id'] == building['building_id']]]

            for unit_num in range(CONFIG['hvac_units_per_building']):
                self.unit_id += 1

                # Assign zones to HVAC units
                num_zones_served = random.randint(5, 15)
                served_zones = random.sample(building_zones, min(num_zones_served, len(building_zones)))

                unit = {
                    'unit_id': self.unit_id,
                    'unit_code': f"HVAC{building['building_code']}{str(unit_num+1).zfill(2)}",
                    'building_id': building['building_id'],
                    'unit_name': f"HVAC Unit {unit_num+1}",
                    'unit_type': random.choice(unit_types),
                    'manufacturer': random.choice(['Carrier', 'Trane', 'Daikin', 'Johnson Controls']),
                    'model': f"Model-{random.randint(1000, 9999)}",
                    'serial_number': fake.bothify(text='SN########'),
                    'capacity_kw': round(random.uniform(50, 500), 3),
                    'efficiency_rating': round(random.uniform(3.0, 5.0), 2),  # COP
                    'refrigerant_type': random.choice(refrigerants),
                    'installation_date': fake.date_between(start_date='-10y', end_date='-1y'),
                    'last_service_date': fake.date_between(start_date='-3m', end_date='today'),
                    'next_service_date': fake.date_between(start_date='+1m', end_date='+6m'),
                    'operating_hours': random.randint(1000, 50000),
                    'serves_zones': json.dumps(served_zones),
                    'status': random.choices(['active', 'inactive', 'maintenance'], weights=[90, 5, 5])[0],
                    'created_at': building['created_at'],
                    'updated_at': fake.date_time_between(start_date='-7d', end_date='now')
                }
                self.hvac_units.append(unit)

    def generate_equipment(self):
        """Generate equipment inventory"""
        print("Generating equipment inventory...")

        equipment_types = ['lighting', 'computer', 'server', 'printer', 'appliance', 'elevator', 'pump', 'fan']

        # Sample zones for equipment
        for zone in random.sample(self.zones, min(200, len(self.zones))):
            num_equipment = random.randint(1, 5)

            for _ in range(num_equipment):
                self.equipment_id += 1

                equipment_type = random.choice(equipment_types)

                # Power ratings based on type
                power_ratings = {
                    'lighting': (20, 200),
                    'computer': (100, 500),
                    'server': (500, 5000),
                    'printer': (100, 1000),
                    'appliance': (500, 3000),
                    'elevator': (5000, 20000),
                    'pump': (1000, 10000),
                    'fan': (50, 500)
                }
                power = random.uniform(*power_ratings.get(equipment_type, (100, 1000)))

                equipment = {
                    'equipment_id': self.equipment_id,
                    'equipment_code': f"EQP{zone['zone_code']}{str(self.equipment_id).zfill(4)}",
                    'zone_id': zone['zone_id'],
                    'equipment_type': equipment_type,
                    'equipment_name': f"{equipment_type.title()} {self.equipment_id}",
                    'manufacturer': fake.company(),
                    'model': f"Model-{random.randint(100, 999)}",
                    'power_rating_watts': round(power, 2),
                    'quantity': random.randint(1, 10) if equipment_type == 'lighting' else 1,
                    'usage_hours_per_day': round(random.uniform(4, 24), 2),
                    'efficiency_pct': round(random.uniform(80, 95), 2),
                    'installation_date': fake.date_between(start_date='-5y', end_date='-1m'),
                    'status': random.choices(['active', 'inactive', 'maintenance'], weights=[95, 3, 2])[0],
                    'created_at': zone['created_at'],
                    'updated_at': fake.date_time_between(start_date='-7d', end_date='now')
                }
                self.equipment_inventory.append(equipment)

    def generate_energy_consumption(self):
        """Generate energy consumption time series data"""
        print("Generating energy consumption data (this may take a while)...")

        # Sample period
        sample_days = min(7, CONFIG['days_of_history'])
        start_date = datetime.now() - timedelta(days=sample_days)

        # Generate for main electricity meters
        electricity_meters = [m for m in self.energy_meters if m['meter_type_id'] == 1]  # ELEC_MAIN

        for meter in random.sample(electricity_meters, min(len(electricity_meters), 5)):
            building = next(b for b in self.buildings if b['building_id'] == meter['building_id'])
            base_load = building['total_area_sqm'] * 0.05  # 50W/m2 base load

            current_date = start_date
            daily_consumptions = []
            cumulative_reading = random.uniform(100000, 500000)  # Starting meter reading

            while current_date < datetime.now():
                # Daily pattern
                daily_total = 0
                hourly_data = []

                for hour in range(24):
                    hour_start = current_date.replace(hour=hour, minute=0, second=0, microsecond=0)

                    # Calculate hourly consumption based on patterns
                    if building['building_type'] == 'office':
                        # Office pattern: high during business hours
                        if 8 <= hour <= 18:
                            hour_consumption = base_load * random.uniform(0.8, 1.2)
                        else:
                            hour_consumption = base_load * random.uniform(0.2, 0.4)
                    else:
                        # Other buildings: more constant
                        hour_consumption = base_load * random.uniform(0.6, 1.0)

                    # Weekend reduction
                    if current_date.weekday() >= 5:
                        hour_consumption *= 0.6

                    # Seasonal adjustment
                    month = current_date.month
                    if month in [6, 7, 8]:  # Summer - more cooling
                        hour_consumption *= 1.3
                    elif month in [12, 1, 2]:  # Winter - more heating
                        hour_consumption *= 1.2

                    daily_total += hour_consumption

                    # Create hourly aggregate
                    hourly = {
                        'consumption_id': len(self.energy_consumption_hourly) + 1,
                        'meter_id': meter['meter_id'],
                        'hour_start': hour_start,
                        'energy_consumed_kwh': round(hour_consumption, 3),
                        'avg_power_kw': round(hour_consumption, 3),
                        'max_power_kw': round(hour_consumption * 1.2, 3),
                        'min_power_kw': round(hour_consumption * 0.8, 3),
                        'avg_power_factor': round(random.uniform(0.85, 0.95), 3),
                        'reading_count': 12,  # 12 five-minute readings per hour
                        'created_at': hour_start + timedelta(hours=1)
                    }
                    hourly_data.append(hourly)

                    # Generate individual readings (sampled)
                    if random.random() < 0.1:  # Sample 10% for performance
                        for minute in range(0, 60, 5):
                            reading_time = hour_start + timedelta(minutes=minute)
                            cumulative_reading += hour_consumption / 12

                            self.reading_id += 1
                            reading = {
                                'reading_id': self.reading_id,
                                'meter_id': meter['meter_id'],
                                'reading_timestamp': reading_time,
                                'energy_value': round(cumulative_reading, 3),
                                'power_value': round(hour_consumption + random.uniform(-5, 5), 3),
                                'power_factor': round(random.uniform(0.85, 0.95), 3),
                                'voltage_v': round(random.uniform(230, 240), 2),
                                'current_a': round(hour_consumption / 0.23, 2),  # Rough calculation
                                'frequency_hz': round(random.uniform(59.9, 60.1), 2),
                                'quality_flag': 'good' if random.random() > 0.05 else 'estimated',
                                'created_at': reading_time
                            }
                            self.energy_readings.append(reading)

                self.energy_consumption_hourly.extend(hourly_data)

                # Create daily aggregate
                peak_hour = max(hourly_data, key=lambda x: x['avg_power_kw'])
                daily = {
                    'consumption_id': len(self.energy_consumption_daily) + 1,
                    'meter_id': meter['meter_id'],
                    'consumption_date': current_date.date(),
                    'total_energy_kwh': round(daily_total, 3),
                    'peak_power_kw': peak_hour['max_power_kw'],
                    'peak_hour': f"{peak_hour['hour_start'].hour:02d}:00:00",
                    'off_peak_energy_kwh': round(daily_total * 0.4, 3),
                    'peak_energy_kwh': round(daily_total * 0.6, 3),
                    'base_load_kw': round(base_load * 0.3, 3),
                    'load_factor': round(random.uniform(0.6, 0.8), 3),
                    'daily_cost': round(daily_total * 0.12, 2),  # $0.12/kWh average
                    'weather_temp_avg_c': round(random.uniform(10, 30), 2),
                    'weather_condition': random.choice(['sunny', 'cloudy', 'rainy', 'partly cloudy']),
                    'created_at': current_date + timedelta(days=1)
                }
                daily_consumptions.append(daily)

                current_date += timedelta(days=1)

            self.energy_consumption_daily.extend(daily_consumptions)

    def generate_solar_and_battery_data(self):
        """Generate solar production and battery status data"""
        print("Generating solar and battery data...")

        sample_days = min(7, CONFIG['days_of_history'])
        start_date = datetime.now() - timedelta(days=sample_days)

        for solar_system in self.solar_systems:
            current_date = start_date

            while current_date < datetime.now():
                # Generate hourly solar production
                for hour in range(24):
                    timestamp = current_date.replace(hour=hour, minute=0, second=0, microsecond=0)

                    # Solar production curve (bell curve during daylight)
                    if 6 <= hour <= 18:
                        # Peak at noon
                        hour_offset = abs(hour - 12)
                        base_production = solar_system['capacity_kw'] * (1 - hour_offset * 0.15)

                        # Weather factor
                        weather_factor = random.uniform(0.2, 1.0)  # 20-100% based on clouds

                        # Seasonal factor
                        month = current_date.month
                        if month in [6, 7, 8]:  # Summer
                            seasonal_factor = 1.2
                        elif month in [12, 1, 2]:  # Winter
                            seasonal_factor = 0.7
                        else:
                            seasonal_factor = 1.0

                        power_kw = base_production * weather_factor * seasonal_factor
                    else:
                        power_kw = 0

                    self.production_id += 1
                    production = {
                        'production_id': self.production_id,
                        'system_id': solar_system['system_id'],
                        'timestamp': timestamp,
                        'power_kw': round(max(0, power_kw), 3),
                        'energy_kwh': round(max(0, power_kw), 3),  # Hourly energy = average power
                        'irradiance_w_m2': round(power_kw / solar_system['capacity_kw'] * 1000, 2) if power_kw > 0 else 0,
                        'panel_temp_c': round(random.uniform(15, 45), 2) if power_kw > 0 else None,
                        'ambient_temp_c': round(random.uniform(10, 35), 2),
                        'efficiency_pct': round(random.uniform(15, 20), 2) if power_kw > 0 else 0,
                        'created_at': timestamp
                    }
                    self.solar_production.append(production)

                current_date += timedelta(days=1)

        # Generate battery status for buildings with batteries
        for battery in self.battery_storage:
            current_date = start_date
            soc = battery['state_of_charge_pct']

            while current_date < datetime.now():
                for hour in range(24):
                    timestamp = current_date.replace(hour=hour, minute=0, second=0, microsecond=0)

                    # Battery charge/discharge logic
                    solar_system = next(s for s in self.solar_systems if s['building_id'] == battery['building_id'])
                    solar_production = next((p for p in self.solar_production
                                           if p['system_id'] == solar_system['system_id']
                                           and p['timestamp'] == timestamp), None)

                    if solar_production and solar_production['power_kw'] > 0:
                        # Charge during solar production
                        power_kw = min(solar_production['power_kw'], battery['max_power_kw'])
                        soc = min(95, soc + (power_kw / battery['capacity_kwh']) * 100)
                    elif 17 <= hour <= 21:  # Peak evening hours
                        # Discharge during peak
                        power_kw = -min(battery['max_power_kw'], battery['capacity_kwh'] * soc / 100)
                        soc = max(20, soc - (abs(power_kw) / battery['capacity_kwh']) * 100)
                    else:
                        power_kw = 0

                    self.status_id += 1
                    status = {
                        'status_id': self.status_id,
                        'battery_id': battery['battery_id'],
                        'timestamp': timestamp,
                        'state_of_charge_pct': round(soc, 2),
                        'power_kw': round(power_kw, 3),
                        'energy_kwh': round(abs(power_kw), 3),
                        'voltage_v': round(400 + random.uniform(-10, 10), 2),
                        'current_a': round(abs(power_kw) * 2.5, 2) if power_kw != 0 else 0,
                        'temperature_c': round(random.uniform(20, 30), 2),
                        'cycle_count': battery['cycles_count'],
                        'health_pct': round(random.uniform(95, 100), 2),
                        'created_at': timestamp
                    }
                    self.battery_status.append(status)

                current_date += timedelta(days=1)

    def generate_hvac_telemetry(self):
        """Generate HVAC telemetry data"""
        print("Generating HVAC telemetry...")

        sample_days = min(3, CONFIG['days_of_history'])
        start_date = datetime.now() - timedelta(days=sample_days)

        for hvac in random.sample(self.hvac_units, min(10, len(self.hvac_units))):
            current_date = start_date

            while current_date < datetime.now():
                for hour in range(24):
                    timestamp = current_date.replace(hour=hour, minute=0, second=0, microsecond=0)

                    # HVAC operation based on time and building type
                    building = next(b for b in self.buildings if b['building_id'] == hvac['building_id'])

                    if building['building_type'] == 'office' and (8 <= hour <= 18):
                        operation_mode = 'on'
                        fan_speed = random.uniform(60, 100)
                    elif 6 <= hour <= 22:
                        operation_mode = random.choice(['on', 'variable'])
                        fan_speed = random.uniform(30, 80)
                    else:
                        operation_mode = 'off'
                        fan_speed = 0

                    outdoor_temp = random.uniform(10, 35)
                    setpoint = 22

                    self.telemetry_id += 1
                    telemetry = {
                        'telemetry_id': self.telemetry_id,
                        'unit_id': hvac['unit_id'],
                        'timestamp': timestamp,
                        'supply_temp_c': round(setpoint + random.uniform(-2, 2), 2) if operation_mode != 'off' else None,
                        'return_temp_c': round(setpoint + random.uniform(-1, 3), 2) if operation_mode != 'off' else None,
                        'setpoint_temp_c': setpoint,
                        'outdoor_temp_c': round(outdoor_temp, 2),
                        'fan_speed_pct': round(fan_speed, 2),
                        'compressor_status': operation_mode,
                        'power_kw': round(hvac['capacity_kw'] * fan_speed / 100, 3) if operation_mode != 'off' else 0,
                        'efficiency_cop': round(random.uniform(3.0, 4.5), 2) if operation_mode != 'off' else None,
                        'runtime_minutes': random.randint(30, 60) if operation_mode != 'off' else 0,
                        'fault_code': None if random.random() > 0.02 else f"E{random.randint(100, 999)}",
                        'created_at': timestamp
                    }
                    self.hvac_telemetry.append(telemetry)

                current_date += timedelta(days=1)

    def generate_demand_response_events(self):
        """Generate demand response events"""
        print("Generating demand response events...")

        event_types = ['voluntary', 'mandatory', 'test']

        for i in range(random.randint(5, 15)):
            self.event_id += 1

            event_date = fake.date_time_between(start_date=self.start_date, end_date='now')
            duration_hours = random.randint(2, 4)

            event = {
                'event_id': self.event_id,
                'event_code': f"DR{event_date.strftime('%Y%m%d')}{str(self.event_id).zfill(3)}",
                'event_type': random.choice(event_types),
                'start_time': event_date.replace(hour=random.choice([14, 15, 16, 17]), minute=0, second=0),
                'end_time': event_date.replace(hour=random.choice([14, 15, 16, 17]), minute=0, second=0) + timedelta(hours=duration_hours),
                'target_reduction_kw': round(random.uniform(100, 500), 3),
                'target_reduction_pct': round(random.uniform(10, 30), 2),
                'incentive_rate': round(random.uniform(0.05, 0.20), 4),
                'notification_time': event_date - timedelta(hours=random.choice([1, 2, 24])),
                'response_status': random.choice(['completed', 'accepted', 'declined']),
                'actual_reduction_kw': round(random.uniform(50, 400), 3) if random.random() > 0.3 else None,
                'compliance_pct': round(random.uniform(60, 110), 2) if random.random() > 0.3 else None,
                'revenue_earned': round(random.uniform(50, 500), 2) if random.random() > 0.3 else None,
                'created_at': event_date - timedelta(days=1)
            }
            self.demand_response_events.append(event)

    def save_to_csv(self, table_name, data):
        """Save data to CSV file"""
        if not data:
            return

        output_file = OUTPUT_DIR / f"{table_name}.csv"

        with open(output_file, 'w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=data[0].keys())
            writer.writeheader()
            writer.writerows(data)

    def save_all(self):
        """Save all generated data to CSV files"""
        print("\nSaving data to CSV files...")

        OUTPUT_DIR.mkdir(exist_ok=True)

        # Save all tables
        tables = [
            ('buildings', self.buildings),
            ('floors', self.floors),
            ('zones', self.zones),
            ('tenants', self.tenants),
            ('tenant_zone_assignments', self.tenant_assignments),
            ('meter_types', self.meter_types),
            ('energy_meters', self.energy_meters),
            ('solar_systems', self.solar_systems),
            ('battery_storage', self.battery_storage),
            ('hvac_units', self.hvac_units),
            ('equipment_inventory', self.equipment_inventory),
            ('energy_readings', self.energy_readings),
            ('energy_consumption_hourly', self.energy_consumption_hourly),
            ('energy_consumption_daily', self.energy_consumption_daily),
            ('solar_production', self.solar_production),
            ('battery_status', self.battery_status),
            ('hvac_telemetry', self.hvac_telemetry),
            ('demand_response_events', self.demand_response_events),
        ]

        for table_name, data in tables:
            if data:
                self.save_to_csv(table_name, data)
                print(f"  [OK] {table_name}: {len(data):,} records")

        # Generate summary statistics
        self.generate_summary()

    def generate_summary(self):
        """Generate summary statistics"""
        total_consumption = sum(d['total_energy_kwh'] for d in self.energy_consumption_daily)
        total_solar = sum(s['energy_kwh'] for s in self.solar_production)
        renewable_pct = (total_solar / total_consumption * 100) if total_consumption > 0 else 0

        summary = f"""
Smart Energy Management Data Generation Summary
===============================================
Infrastructure:
  Buildings: {len(self.buildings)}
  Floors: {len(self.floors)}
  Zones: {len(self.zones)}
  Tenants: {len(self.tenants)}

Energy Systems:
  Energy Meters: {len(self.energy_meters)}
  Solar Systems: {len(self.solar_systems)}
  Battery Storage: {len(self.battery_storage)}
  HVAC Units: {len(self.hvac_units)}
  Equipment Items: {len(self.equipment_inventory)}

Energy Data:
  Total Consumption: {total_consumption:,.0f} kWh
  Solar Production: {total_solar:,.0f} kWh
  Renewable Percentage: {renewable_pct:.1f}%

Time Series Records:
  Energy Readings: {len(self.energy_readings):,}
  Hourly Consumption: {len(self.energy_consumption_hourly):,}
  Daily Consumption: {len(self.energy_consumption_daily):,}
  Solar Production: {len(self.solar_production):,}
  Battery Status: {len(self.battery_status):,}
  HVAC Telemetry: {len(self.hvac_telemetry):,}

Demand Response:
  Events: {len(self.demand_response_events)}
  Average Reduction Target: {sum(e.get('target_reduction_kw', 0) for e in self.demand_response_events) / len(self.demand_response_events):.1f} kW

Files Generated: {len(list(OUTPUT_DIR.glob('*.csv')))}
"""

        print(summary)

        # Save summary to file
        with open(OUTPUT_DIR / "generation_summary.txt", "w") as f:
            f.write(summary)

if __name__ == "__main__":
    generator = SmartEnergyGenerator()
    generator.generate_all()
    print("\n[SUCCESS] Smart Energy Management data generation complete!")