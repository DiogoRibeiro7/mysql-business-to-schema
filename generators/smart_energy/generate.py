#!/usr/bin/env python3
"""
Smart Energy Grid Data Generator

Generates realistic smart meter and energy consumption data for:
- Multiple utility companies (multi-tenant)
- Residential and commercial customers
- Smart meters with high-frequency readings
- Solar production data
- Demand response events
- Time-of-use pricing patterns
"""

import csv
import random
import yaml
import argparse
from datetime import datetime, timedelta
from pathlib import Path
import math
from typing import List, Dict, Tuple, Any
import numpy as np

class SmartEnergyGenerator:
    def __init__(self, config_path: str):
        """Initialize generator with configuration"""
        with open(config_path, 'r') as f:
            self.config = yaml.safe_load(f)

        self.seed = self.config.get('seed', 42)
        random.seed(self.seed)
        np.random.seed(self.seed)

        self.output_dir = Path(self.config['output_dir'])
        self.output_dir.mkdir(parents=True, exist_ok=True)

        # Data containers
        self.utilities = []
        self.customers = []
        self.meters = []
        self.transformers = []
        self.solar_panels = []
        self.consumption_readings = []
        self.production_readings = []
        self.power_quality_readings = []
        self.demand_response_events = []
        self.outages = []

    def generate_all(self):
        """Generate all data in sequence"""
        print("Generating Smart Energy Grid data...")

        # Infrastructure
        self._generate_utilities()
        self._generate_transformers()
        self._generate_customers()
        self._generate_meters()
        self._generate_solar_panels()

        # Time series data
        self._generate_consumption_readings()
        self._generate_production_readings()
        self._generate_power_quality_readings()

        # Events
        self._generate_demand_response_events()
        self._generate_outages()

        # Write to CSV
        self._write_all_csvs()

        # Generate SQL scripts
        self._generate_sql_scripts()

        print(f"[OK] Generated data for {len(self.utilities)} utilities, "
              f"{len(self.customers)} customers, {len(self.meters)} meters")
        print(f"[OK] Generated {len(self.consumption_readings)} consumption readings")
        print(f"[OK] Output written to {self.output_dir}")

    def _generate_utilities(self):
        """Generate utility companies"""
        utility_names = [
            "Metro Power & Light", "Green Energy Co", "City Electric",
            "Sustainable Power Inc", "Regional Energy Services"
        ]

        for i in range(self.config['counts']['utilities']):
            utility = {
                'utility_id': i + 1,
                'name': utility_names[i % len(utility_names)] + (f" {i//len(utility_names) + 1}" if i >= len(utility_names) else ""),
                'type': random.choice(['municipal', 'cooperative', 'investor_owned']),
                'service_area': f"Region_{i+1}",
                'customer_count': 0,  # Will update later
                'created_at': datetime.now() - timedelta(days=random.randint(365, 3650))
            }
            self.utilities.append(utility)

    def _generate_transformers(self):
        """Generate distribution transformers"""
        transformer_id = 1
        for utility in self.utilities:
            num_transformers = self.config['counts']['transformers_per_utility']

            for t in range(num_transformers):
                transformer = {
                    'transformer_id': transformer_id,
                    'utility_id': utility['utility_id'],
                    'transformer_code': f"TR-{utility['utility_id']:02d}-{t+1:04d}",
                    'location_lat': 40.7128 + random.uniform(-0.5, 0.5),
                    'location_lon': -74.0060 + random.uniform(-0.5, 0.5),
                    'capacity_kva': random.choice([25, 50, 75, 100, 150, 250]),
                    'installation_date': datetime.now() - timedelta(days=random.randint(180, 1825)),
                    'status': random.choices(['active', 'maintenance'], weights=[0.95, 0.05])[0]
                }
                self.transformers.append(transformer)
                transformer_id += 1

    def _generate_customers(self):
        """Generate customer accounts"""
        customer_id = 1

        for utility in self.utilities:
            num_customers = self.config['counts']['customers_per_utility']
            utility_customer_count = 0

            for c in range(num_customers):
                customer_type = random.choices(
                    ['residential', 'commercial', 'industrial'],
                    weights=[0.7, 0.25, 0.05]
                )[0]

                # Select a transformer for this customer
                utility_transformers = [t for t in self.transformers if t['utility_id'] == utility['utility_id']]
                transformer = random.choice(utility_transformers)

                customer = {
                    'customer_id': customer_id,
                    'utility_id': utility['utility_id'],
                    'transformer_id': transformer['transformer_id'],
                    'account_number': f"ACC{customer_id:08d}",
                    'customer_type': customer_type,
                    'name': f"{random.choice(['Smith', 'Johnson', 'Williams', 'Brown', 'Jones'])} "
                            f"{random.choice(['Home', 'Residence', 'Corp', 'LLC', 'Inc'])}" if customer_type != 'residential'
                            else f"Customer_{customer_id}",
                    'address': f"{random.randint(1, 9999)} {random.choice(['Main', 'Oak', 'Elm', 'First'])} St",
                    'rate_plan': self._get_rate_plan(customer_type),
                    'contract_start': datetime.now() - timedelta(days=random.randint(90, 1095)),
                    'status': random.choices(['active', 'inactive'], weights=[0.95, 0.05])[0],
                    'has_solar': random.random() < 0.15,  # 15% have solar
                    'has_ev': random.random() < 0.10,  # 10% have EV
                    'enrolled_demand_response': random.random() < 0.30  # 30% in demand response
                }
                self.customers.append(customer)
                customer_id += 1
                utility_customer_count += 1

            # Update utility customer count
            utility['customer_count'] = utility_customer_count

    def _generate_meters(self):
        """Generate smart meters for customers"""
        meter_id = 1

        for customer in self.customers:
            # Most customers have 1 meter, some commercial/industrial have multiple
            num_meters = 1
            if customer['customer_type'] == 'commercial':
                num_meters = random.choices([1, 2, 3], weights=[0.7, 0.2, 0.1])[0]
            elif customer['customer_type'] == 'industrial':
                num_meters = random.choices([2, 3, 4, 5], weights=[0.3, 0.3, 0.2, 0.2])[0]

            for m in range(num_meters):
                meter = {
                    'meter_id': meter_id,
                    'customer_id': customer['customer_id'],
                    'meter_number': f"SM{meter_id:010d}",
                    'meter_type': 'smart_meter',
                    'model': random.choice(['GE_I210+', 'Landis_E650', 'Itron_OpenWay', 'Sensus_iCon']),
                    'installation_date': customer['contract_start'] - timedelta(days=random.randint(0, 30)),
                    'last_reading_time': datetime.now(),
                    'firmware_version': f"{random.randint(1,5)}.{random.randint(0,9)}.{random.randint(0,99)}",
                    'communication_type': random.choice(['cellular', 'rf_mesh', 'plc']),
                    'status': random.choices(['active', 'inactive', 'maintenance'], weights=[0.95, 0.03, 0.02])[0]
                }
                self.meters.append(meter)
                meter_id += 1

    def _generate_solar_panels(self):
        """Generate solar panel systems for customers with solar"""
        panel_id = 1

        for customer in self.customers:
            if not customer['has_solar']:
                continue

            # Get customer's meter
            customer_meters = [m for m in self.meters if m['customer_id'] == customer['customer_id']]
            if not customer_meters:
                continue

            meter = customer_meters[0]

            # Residential systems are smaller
            if customer['customer_type'] == 'residential':
                capacity_kw = random.uniform(3.0, 10.0)
                panel_count = random.randint(8, 30)
            elif customer['customer_type'] == 'commercial':
                capacity_kw = random.uniform(10.0, 100.0)
                panel_count = random.randint(30, 300)
            else:  # industrial
                capacity_kw = random.uniform(100.0, 1000.0)
                panel_count = random.randint(300, 3000)

            solar_panel = {
                'panel_id': panel_id,
                'customer_id': customer['customer_id'],
                'meter_id': meter['meter_id'],
                'capacity_kw': round(capacity_kw, 2),
                'panel_count': panel_count,
                'panel_type': random.choice(['monocrystalline', 'polycrystalline', 'thin_film']),
                'inverter_type': random.choice(['string', 'micro', 'power_optimizer']),
                'installation_date': customer['contract_start'] + timedelta(days=random.randint(30, 365)),
                'orientation': random.randint(150, 210),  # degrees (south-facing)
                'tilt_angle': random.randint(15, 45),  # degrees
                'efficiency_rating': random.uniform(0.15, 0.22),  # 15-22% efficiency
                'status': 'active'
            }
            self.solar_panels.append(solar_panel)
            panel_id += 1

    def _generate_consumption_readings(self):
        """Generate high-frequency consumption readings"""
        print("  Generating consumption readings...")

        start_date = datetime.now() - timedelta(days=self.config['date_ranges']['days_of_data'])
        end_date = datetime.now()

        for meter in self.meters[:self.config['counts'].get('meters_to_generate', 100)]:  # Limit for demo
            if meter['status'] != 'active':
                continue

            customer = next(c for c in self.customers if c['customer_id'] == meter['customer_id'])

            # Generate readings every 15 minutes
            current_time = start_date
            while current_time <= end_date:
                # Base consumption pattern
                hour = current_time.hour
                day_of_week = current_time.weekday()
                month = current_time.month

                # Get base consumption for customer type
                base_consumption = self._get_base_consumption(customer['customer_type'], hour, day_of_week)

                # Seasonal adjustment
                seasonal_factor = self._get_seasonal_factor(month)

                # Random variation
                variation = random.gauss(1.0, 0.1)

                # EV charging spike
                ev_consumption = 0
                if customer['has_ev'] and hour >= 18 and hour <= 23:
                    if random.random() < 0.3:  # 30% chance of charging
                        ev_consumption = random.uniform(3.0, 7.0)  # 3-7 kW

                consumption_kw = max(0.1, (base_consumption * seasonal_factor * variation) + ev_consumption)

                reading = {
                    'meter_id': meter['meter_id'],
                    'reading_time': current_time,
                    'consumption_kwh': round(consumption_kw / 4, 3),  # 15 min = 1/4 hour
                    'power_kw': round(consumption_kw, 2),
                    'voltage': round(random.gauss(240, 2), 1),
                    'current': round(consumption_kw / 0.24, 2),  # Assuming 240V
                    'power_factor': round(random.uniform(0.85, 0.98), 2),
                    'frequency': round(random.gauss(60, 0.1), 2)
                }
                self.consumption_readings.append(reading)

                current_time += timedelta(minutes=15)

    def _generate_production_readings(self):
        """Generate solar production readings"""
        print("  Generating solar production readings...")

        if not self.solar_panels:
            return

        start_date = datetime.now() - timedelta(days=self.config['date_ranges']['days_of_data'])
        end_date = datetime.now()

        for panel in self.solar_panels[:20]:  # Limit for demo
            current_time = start_date
            while current_time <= end_date:
                hour = current_time.hour
                month = current_time.month

                # Solar production curve (simplified)
                if hour < 6 or hour > 19:
                    production_kw = 0
                else:
                    # Peak at noon
                    sun_factor = math.sin(math.pi * (hour - 6) / 13)

                    # Seasonal variation
                    seasonal_factor = 0.6 + 0.4 * math.sin(math.pi * (month - 3) / 6)

                    # Cloud cover (random)
                    cloud_factor = random.uniform(0.3, 1.0)

                    # Calculate production
                    production_kw = panel['capacity_kw'] * sun_factor * seasonal_factor * cloud_factor

                if production_kw > 0:
                    reading = {
                        'panel_id': panel['panel_id'],
                        'reading_time': current_time,
                        'production_kwh': round(production_kw / 4, 3),  # 15 min interval
                        'power_kw': round(production_kw, 2),
                        'panel_temperature': round(25 + (production_kw / panel['capacity_kw']) * 20, 1),
                        'inverter_efficiency': round(random.uniform(0.94, 0.98), 3),
                        'dc_voltage': round(random.gauss(600, 10), 1),
                        'dc_current': round(production_kw / 0.6, 2)
                    }
                    self.production_readings.append(reading)

                current_time += timedelta(minutes=15)

    def _generate_power_quality_readings(self):
        """Generate power quality metrics"""
        print("  Generating power quality readings...")

        start_date = datetime.now() - timedelta(days=self.config['date_ranges']['days_of_data'])
        end_date = datetime.now()

        for transformer in self.transformers[:20]:  # Limit for demo
            current_time = start_date
            while current_time <= end_date:
                reading = {
                    'transformer_id': transformer['transformer_id'],
                    'reading_time': current_time,
                    'voltage_l1': round(random.gauss(240, 3), 1),
                    'voltage_l2': round(random.gauss(240, 3), 1),
                    'voltage_l3': round(random.gauss(240, 3), 1),
                    'current_l1': round(random.gauss(100, 20), 1),
                    'current_l2': round(random.gauss(100, 20), 1),
                    'current_l3': round(random.gauss(100, 20), 1),
                    'thd_voltage': round(random.uniform(1.0, 5.0), 2),  # Total harmonic distortion %
                    'thd_current': round(random.uniform(2.0, 8.0), 2),
                    'power_factor': round(random.uniform(0.85, 0.99), 3),
                    'frequency': round(random.gauss(60, 0.1), 2),
                    'transformer_temp': round(random.gauss(65, 10), 1)
                }
                self.power_quality_readings.append(reading)

                current_time += timedelta(hours=1)  # Hourly for power quality

    def _generate_demand_response_events(self):
        """Generate demand response events"""
        print("  Generating demand response events...")

        event_id = 1
        start_date = datetime.now() - timedelta(days=self.config['date_ranges']['days_of_data'])

        # Generate a few events over the time period
        for _ in range(self.config['counts'].get('demand_response_events', 10)):
            event_date = start_date + timedelta(days=random.randint(0, self.config['date_ranges']['days_of_data']))

            # Peak hours typically in afternoon
            start_hour = random.choice([14, 15, 16, 17])

            event = {
                'event_id': event_id,
                'utility_id': random.choice(self.utilities)['utility_id'],
                'event_type': random.choice(['critical_peak', 'peak_day', 'emergency']),
                'start_time': event_date.replace(hour=start_hour, minute=0, second=0),
                'end_time': event_date.replace(hour=start_hour + random.randint(2, 4), minute=0, second=0),
                'target_reduction_mw': round(random.uniform(5, 50), 1),
                'incentive_per_kwh': round(random.uniform(0.10, 0.50), 2),
                'notification_sent': event_date.replace(hour=start_hour - 2, minute=0, second=0),
                'status': 'completed'
            }
            self.demand_response_events.append(event)
            event_id += 1

    def _generate_outages(self):
        """Generate power outage events"""
        print("  Generating outage events...")

        outage_id = 1
        start_date = datetime.now() - timedelta(days=self.config['date_ranges']['days_of_data'])

        for _ in range(self.config['counts'].get('outages', 5)):
            outage_start = start_date + timedelta(
                days=random.randint(0, self.config['date_ranges']['days_of_data']),
                hours=random.randint(0, 23)
            )

            # Most outages are short
            duration_minutes = random.choices(
                [random.randint(1, 30), random.randint(30, 120), random.randint(120, 480)],
                weights=[0.6, 0.3, 0.1]
            )[0]

            affected_transformer = random.choice(self.transformers)

            outage = {
                'outage_id': outage_id,
                'transformer_id': affected_transformer['transformer_id'],
                'start_time': outage_start,
                'end_time': outage_start + timedelta(minutes=duration_minutes),
                'cause': random.choice(['equipment_failure', 'weather', 'tree_contact', 'animal', 'unknown']),
                'customers_affected': random.randint(10, 500),
                'estimated_load_lost_mw': round(random.uniform(0.1, 5.0), 2),
                'crew_dispatched': outage_start + timedelta(minutes=random.randint(5, 30)),
                'status': 'resolved'
            }
            self.outages.append(outage)
            outage_id += 1

    def _get_rate_plan(self, customer_type: str) -> str:
        """Get appropriate rate plan for customer type"""
        if customer_type == 'residential':
            return random.choice(['standard', 'time_of_use', 'tiered'])
        elif customer_type == 'commercial':
            return random.choice(['commercial_standard', 'commercial_tou', 'demand_charge'])
        else:  # industrial
            return random.choice(['industrial_demand', 'industrial_interruptible', 'custom_contract'])

    def _get_base_consumption(self, customer_type: str, hour: int, day_of_week: int) -> float:
        """Get base consumption in kW based on customer type and time"""
        if customer_type == 'residential':
            # Low at night, peaks in morning and evening
            if hour < 6:
                return random.uniform(0.5, 1.5)
            elif hour < 9:
                return random.uniform(1.5, 3.0)
            elif hour < 17:
                return random.uniform(1.0, 2.0)
            elif hour < 22:
                return random.uniform(2.0, 4.0)
            else:
                return random.uniform(0.5, 1.5)

        elif customer_type == 'commercial':
            # Business hours pattern
            if day_of_week >= 5:  # Weekend
                return random.uniform(5, 15)
            elif hour < 7 or hour > 19:
                return random.uniform(5, 15)
            else:
                return random.uniform(20, 50)

        else:  # industrial
            # Often 24/7 operation with some variation
            base = random.uniform(100, 500)
            if day_of_week >= 5:  # Weekend - slightly lower
                return base * 0.8
            return base

    def _get_seasonal_factor(self, month: int) -> float:
        """Get seasonal adjustment factor"""
        # Summer peak (cooling), winter secondary peak (heating)
        if month in [6, 7, 8]:  # Summer
            return random.uniform(1.2, 1.5)
        elif month in [12, 1, 2]:  # Winter
            return random.uniform(1.1, 1.3)
        else:  # Spring/Fall
            return random.uniform(0.8, 1.0)

    def _write_all_csvs(self):
        """Write all data to CSV files"""
        datasets = [
            ('utilities', self.utilities),
            ('transformers', self.transformers),
            ('customers', self.customers),
            ('meters', self.meters),
            ('solar_panels', self.solar_panels),
            ('consumption_readings', self.consumption_readings[:10000]),  # Limit for file size
            ('production_readings', self.production_readings[:10000]),
            ('power_quality_readings', self.power_quality_readings[:5000]),
            ('demand_response_events', self.demand_response_events),
            ('outages', self.outages)
        ]

        for filename, data in datasets:
            if not data:
                continue

            filepath = self.output_dir / f"{filename}.csv"
            with open(filepath, 'w', newline='', encoding='utf-8') as f:
                if data:
                    writer = csv.DictWriter(f, fieldnames=data[0].keys())
                    writer.writeheader()
                    writer.writerows(data)

            print(f"  [OK] Wrote {len(data)} records to {filename}.csv")

    def _generate_sql_scripts(self):
        """Generate SQL load scripts"""
        load_script = f"""-- Load generated Smart Energy data
-- Generated on {datetime.now()}

-- Clear existing data
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE consumption_readings;
TRUNCATE TABLE production_readings;
TRUNCATE TABLE power_quality_readings;
TRUNCATE TABLE demand_response_events;
TRUNCATE TABLE outages;
TRUNCATE TABLE solar_panels;
TRUNCATE TABLE meters;
TRUNCATE TABLE customers;
TRUNCATE TABLE transformers;
TRUNCATE TABLE utilities;
SET FOREIGN_KEY_CHECKS = 1;

-- Load utilities
LOAD DATA INFILE '/var/lib/mysql-files/smart_energy/utilities.csv'
INTO TABLE utilities
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\\n'
IGNORE 1 ROWS
(utility_id, name, type, service_area, customer_count, created_at);

-- Load transformers
LOAD DATA INFILE '/var/lib/mysql-files/smart_energy/transformers.csv'
INTO TABLE transformers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\\n'
IGNORE 1 ROWS
(transformer_id, utility_id, transformer_code, location_lat, location_lon,
 capacity_kva, installation_date, status);

-- Load customers
LOAD DATA INFILE '/var/lib/mysql-files/smart_energy/customers.csv'
INTO TABLE customers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\\n'
IGNORE 1 ROWS
(customer_id, utility_id, transformer_id, account_number, customer_type,
 name, address, rate_plan, contract_start, status,
 has_solar, has_ev, enrolled_demand_response);

-- Load meters
LOAD DATA INFILE '/var/lib/mysql-files/smart_energy/meters.csv'
INTO TABLE meters
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\\n'
IGNORE 1 ROWS
(meter_id, customer_id, meter_number, meter_type, model,
 installation_date, last_reading_time, firmware_version,
 communication_type, status);

-- Load solar panels
LOAD DATA INFILE '/var/lib/mysql-files/smart_energy/solar_panels.csv'
INTO TABLE solar_panels
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\\n'
IGNORE 1 ROWS
(panel_id, customer_id, meter_id, capacity_kw, panel_count,
 panel_type, inverter_type, installation_date, orientation,
 tilt_angle, efficiency_rating, status);

-- Load sample consumption readings (limited dataset)
LOAD DATA INFILE '/var/lib/mysql-files/smart_energy/consumption_readings.csv'
INTO TABLE consumption_readings
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\\n'
IGNORE 1 ROWS
(meter_id, reading_time, consumption_kwh, power_kw, voltage,
 current, power_factor, frequency);

-- Load sample production readings (limited dataset)
LOAD DATA INFILE '/var/lib/mysql-files/smart_energy/production_readings.csv'
INTO TABLE production_readings
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\\n'
IGNORE 1 ROWS
(panel_id, reading_time, production_kwh, power_kw,
 panel_temperature, inverter_efficiency, dc_voltage, dc_current);

-- Update statistics
ANALYZE TABLE utilities, customers, meters, consumption_readings;

SELECT 'Data load complete!' as status;
SELECT COUNT(*) as utilities_count FROM utilities;
SELECT COUNT(*) as customers_count FROM customers;
SELECT COUNT(*) as meters_count FROM meters;
SELECT COUNT(*) as readings_count FROM consumption_readings;
"""

        script_path = self.output_dir / 'load_data.sql'
        with open(script_path, 'w') as f:
            f.write(load_script)

        print(f"  [OK] Generated SQL load script: load_data.sql")

def main():
    parser = argparse.ArgumentParser(description='Generate Smart Energy Grid data')
    parser.add_argument('--config', required=True, help='Path to config.yaml')
    args = parser.parse_args()

    generator = SmartEnergyGenerator(args.config)
    generator.generate_all()

if __name__ == '__main__':
    main()