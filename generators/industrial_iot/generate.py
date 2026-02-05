#!/usr/bin/env python3
"""
Industrial IoT Data Generator

Generates realistic manufacturing IoT data including:
- Production line sensors
- Machine performance (OEE)
- Quality control metrics
- Predictive maintenance data
- Energy consumption
- Work orders and production
"""

import csv
import random
import yaml
import argparse
from datetime import datetime, timedelta
from pathlib import Path
import math
from typing import List, Dict, Tuple, Any
import uuid

class IndustrialIoTGenerator:
    def __init__(self, config_path: str):
        """Initialize generator with configuration"""
        with open(config_path, 'r') as f:
            self.config = yaml.safe_load(f)

        self.seed = self.config.get('seed', 42)
        random.seed(self.seed)

        self.output_dir = Path(self.config['output_dir'])
        self.output_dir.mkdir(parents=True, exist_ok=True)

        # Data containers
        self.factories = []
        self.production_lines = []
        self.machines = []
        self.sensors = []
        self.operators = []
        self.products = []
        self.work_orders = []
        self.production_runs = []
        self.sensor_readings = []
        self.machine_states = []
        self.quality_inspections = []
        self.downtime_events = []
        self.maintenance_records = []
        self.alarms = []
        self.oee_metrics = []
        self.energy_consumption = []

        # Counters
        self.work_order_id = 1
        self.production_run_id = 1
        self.inspection_id = 1
        self.downtime_id = 1
        self.maintenance_id = 1
        self.alarm_id = 1

    def generate_all(self):
        """Generate all data in sequence"""
        print("Generating Industrial IoT data...")

        # Master data
        self._generate_factories()
        self._generate_production_lines()
        self._generate_machines()
        self._generate_sensors()
        self._generate_operators()
        self._generate_products()

        # Production data
        self._generate_work_orders()
        self._generate_production_runs()
        self._generate_sensor_readings()
        self._generate_machine_states()
        self._generate_quality_inspections()
        self._generate_downtime_events()
        self._generate_oee_metrics()
        self._generate_maintenance_records()
        self._generate_alarms()
        self._generate_energy_consumption()

        # Write to CSV
        self._write_all_csvs()

        # Generate SQL scripts
        self._generate_sql_scripts()

        print(f"[OK] Generated data for {len(self.factories)} factories, "
              f"{len(self.machines)} machines, {len(self.work_orders)} work orders")
        print(f"[OK] Generated {len(self.sensor_readings)} sensor readings")
        print(f"[OK] Output written to {self.output_dir}")

    def _generate_factories(self):
        """Generate factory locations"""
        for i, factory_config in enumerate(self.config['factory_distribution']['locations']):
            factory = {
                'factory_id': i + 1,
                'factory_name': factory_config['name'],
                'factory_type': factory_config['type'],
                'location': factory_config['name'].split()[0],
                'country': 'USA',
                'timezone': self._get_timezone(factory_config['name']),
                'shifts_per_day': factory_config['shifts'],
                'established_date': self.config['date_ranges']['factory_established'],
                'floor_area_sqm': random.randint(5000, 20000),
                'employees_count': random.randint(100, 500),
                'iso_certified': True,
                'is_active': True
            }
            self.factories.append(factory)

    def _generate_production_lines(self):
        """Generate production lines for each factory"""
        line_id = 1

        for factory in self.factories:
            lines_per_factory = self.config['counts']['production_lines'] // len(self.factories)

            for line_num in range(lines_per_factory):
                line = {
                    'line_id': line_id,
                    'factory_id': factory['factory_id'],
                    'line_name': f"Line-{chr(65 + line_num)}",  # Line-A, Line-B, etc
                    'line_type': random.choice(['assembly', 'machining', 'packaging', 'quality']),
                    'capacity_per_hour': random.randint(50, 500),
                    'product_types': random.choice(['single', 'multiple', 'flexible']),
                    'automation_level': random.choice(['manual', 'semi_auto', 'full_auto']),
                    'installation_date': datetime.strptime(
                        self.config['date_ranges']['factory_established'], '%Y-%m-%d'
                    ) + timedelta(days=random.randint(0, 365*5)),
                    'last_upgrade': datetime.now() - timedelta(days=random.randint(30, 365)),
                    'status': random.choices(['operational', 'maintenance', 'idle'],
                                           weights=[0.85, 0.10, 0.05])[0]
                }
                self.production_lines.append(line)
                line_id += 1

    def _generate_machines(self):
        """Generate machines for each production line"""
        machine_id = 1

        for line in self.production_lines:
            machines_per_line = self.config['counts']['machines'] // len(self.production_lines)

            for _ in range(machines_per_line):
                machine_type = random.choices(
                    list(self.config['machine_types'].keys()),
                    weights=list(self.config['machine_types'].values())
                )[0]

                # Calculate MTBF for this machine
                mtbf_range = self.config['maintenance_patterns']['mtbf_ranges'].get(
                    machine_type, [1000, 2000]
                )
                mtbf_hours = random.uniform(mtbf_range[0], mtbf_range[1])

                machine = {
                    'machine_id': machine_id,
                    'line_id': line['line_id'],
                    'machine_code': f"MCH{machine_id:04d}",
                    'machine_name': f"{machine_type.replace('_', ' ').title()} {machine_id}",
                    'machine_type': machine_type,
                    'manufacturer': random.choice(['Siemens', 'ABB', 'Fanuc', 'Kuka', 'Mitsubishi']),
                    'model': f"Model-{random.choice(['X', 'Y', 'Z'])}{random.randint(100, 999)}",
                    'serial_number': self._generate_serial(),
                    'installation_date': line['installation_date'] + timedelta(days=random.randint(0, 30)),
                    'operating_hours': random.randint(1000, 50000),
                    'maintenance_interval_hours': int(mtbf_hours / 10),  # Preventive maintenance
                    'last_maintenance': datetime.now() - timedelta(days=random.randint(1, 60)),
                    'next_maintenance': datetime.now() + timedelta(days=random.randint(1, 30)),
                    'status': random.choices(['running', 'idle', 'maintenance', 'fault'],
                                           weights=[0.70, 0.20, 0.08, 0.02])[0]
                }
                self.machines.append(machine)
                machine_id += 1

    def _generate_sensors(self):
        """Generate sensors for each machine"""
        sensor_id = 1

        for machine in self.machines:
            # Each machine gets multiple sensors
            for sensor_type in list(self.config['sensor_types'].keys())[:self.config['counts']['sensors_per_machine']]:
                sensor_config = self.config['sensor_types'][sensor_type]

                sensor = {
                    'sensor_id': sensor_id,
                    'machine_id': machine['machine_id'],
                    'sensor_code': f"SNS{sensor_id:05d}",
                    'sensor_type': sensor_type,
                    'unit': sensor_config['unit'],
                    'min_value': sensor_config['normal_range'][0],
                    'max_value': sensor_config['normal_range'][1],
                    'critical_value': sensor_config['critical'],
                    'sampling_rate_seconds': sensor_config['sampling_rate_seconds'],
                    'accuracy': random.uniform(0.95, 0.99),
                    'calibration_date': datetime.now() - timedelta(days=random.randint(30, 180)),
                    'status': random.choices(['active', 'inactive', 'faulty'],
                                           weights=[0.95, 0.03, 0.02])[0]
                }
                self.sensors.append(sensor)
                sensor_id += 1

    def _generate_operators(self):
        """Generate operator profiles"""
        operator_id = 1
        first_names = ['John', 'Jane', 'Mike', 'Sarah', 'Bob', 'Alice', 'Tom', 'Lisa']
        last_names = ['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller']

        for _ in range(self.config['counts']['operators']):
            skill_level = random.choices(
                list(self.config['operator_skills']['levels'].keys()),
                weights=list(self.config['operator_skills']['levels'].values())
            )[0]

            operator = {
                'operator_id': operator_id,
                'employee_id': f"EMP{operator_id:05d}",
                'name': f"{random.choice(first_names)} {random.choice(last_names)}",
                'skill_level': skill_level,
                'factory_id': random.choice(self.factories)['factory_id'],
                'shift': random.choice(['morning', 'afternoon', 'night']),
                'hire_date': datetime.now() - timedelta(days=random.randint(30, 3650)),
                'safety_certified': random.random() < self.config['operator_skills']['certifications']['safety'],
                'quality_certified': random.random() < self.config['operator_skills']['certifications']['quality'],
                'maintenance_certified': random.random() < self.config['operator_skills']['certifications']['maintenance'],
                'programming_certified': random.random() < self.config['operator_skills']['certifications']['programming'],
                'error_rate': self.config['operator_skills']['error_rates'][skill_level],
                'status': random.choices(['active', 'on_leave', 'training'],
                                       weights=[0.90, 0.05, 0.05])[0]
            }
            self.operators.append(operator)
            operator_id += 1

    def _generate_products(self):
        """Generate product specifications"""
        product_id = 1
        product_prefixes = ['PART', 'COMP', 'ASSY', 'PROD']

        for _ in range(self.config['counts']['products']):
            complexity = random.choices(
                list(self.config['product_specifications']['complexity'].keys()),
                weights=list(self.config['product_specifications']['complexity'].values())
            )[0]

            # Determine tolerance based on complexity
            if complexity == 'advanced':
                tolerance = self.config['product_specifications']['tolerances']['ultra_precision']
            elif complexity == 'complex':
                tolerance = self.config['product_specifications']['tolerances']['precision']
            else:
                tolerance = self.config['product_specifications']['tolerances']['standard']

            product = {
                'product_id': product_id,
                'product_code': f"{random.choice(product_prefixes)}-{product_id:04d}",
                'product_name': f"Product {chr(65 + (product_id % 26))}{product_id:03d}",
                'product_family': random.choice(['automotive', 'electronics', 'consumer', 'industrial']),
                'complexity': complexity,
                'tolerance_mm': tolerance,
                'cycle_time_seconds': random.randint(30, 600),
                'material': random.choice(['steel', 'aluminum', 'plastic', 'composite']),
                'weight_kg': random.uniform(0.1, 50),
                'quality_level': random.choice(['high_quality', 'standard', 'economy']),
                'unit_cost': round(random.uniform(10, 1000), 2),
                'is_active': True
            }
            self.products.append(product)
            product_id += 1

    def _generate_work_orders(self):
        """Generate work orders for production"""
        print("  Generating work orders...")

        start_date = datetime.strptime(self.config['date_ranges']['data_start'], '%Y-%m-%d')
        end_date = datetime.strptime(self.config['date_ranges']['data_end'], '%Y-%m-%d')
        current_date = start_date

        while current_date <= end_date:
            daily_orders = self.config['counts']['work_orders_per_day']

            for _ in range(daily_orders):
                product = random.choice(self.products)
                line = random.choice(self.production_lines)

                # Determine batch size
                batch_size_range = random.choice([
                    self.config['product_specifications']['batch_sizes']['small'],
                    self.config['product_specifications']['batch_sizes']['medium'],
                    self.config['product_specifications']['batch_sizes']['large']
                ])
                batch_size = random.randint(batch_size_range[0], batch_size_range[1])

                # Calculate scheduled time
                scheduled_start = current_date + timedelta(hours=random.randint(0, 23))
                production_hours = (batch_size * product['cycle_time_seconds']) / 3600
                scheduled_end = scheduled_start + timedelta(hours=production_hours)

                work_order = {
                    'work_order_id': self.work_order_id,
                    'order_number': f"WO{self.work_order_id:08d}",
                    'product_id': product['product_id'],
                    'line_id': line['line_id'],
                    'batch_size': batch_size,
                    'priority': random.choice(['low', 'normal', 'high', 'urgent']),
                    'scheduled_start': scheduled_start,
                    'scheduled_end': scheduled_end,
                    'actual_start': None,
                    'actual_end': None,
                    'quantity_produced': 0,
                    'quantity_good': 0,
                    'quantity_scrap': 0,
                    'status': 'scheduled',
                    'customer': f"Customer_{random.randint(1, 100)}",
                    'due_date': scheduled_end + timedelta(days=random.randint(1, 7))
                }
                self.work_orders.append(work_order)
                self.work_order_id += 1

            current_date += timedelta(days=1)

    def _generate_production_runs(self):
        """Generate actual production runs from work orders"""
        print("  Generating production runs...")

        for work_order in self.work_orders:
            if work_order['scheduled_start'] > datetime.now():
                continue  # Future order

            # Start production with some delay
            actual_start = work_order['scheduled_start'] + timedelta(minutes=random.randint(-30, 60))

            # Determine production efficiency
            shift = self._get_shift(actual_start.hour)
            shift_config = self.config['production_metrics']['shift_performance'][shift]

            availability = random.uniform(shift_config['availability'][0], shift_config['availability'][1])
            performance = random.uniform(shift_config['performance'][0], shift_config['performance'][1])
            quality = random.uniform(shift_config['quality'][0], shift_config['quality'][1])

            # Calculate actual production
            planned_quantity = work_order['batch_size']
            actual_quantity = int(planned_quantity * availability * performance)
            good_quantity = int(actual_quantity * quality)
            scrap_quantity = actual_quantity - good_quantity

            production_run = {
                'run_id': self.production_run_id,
                'work_order_id': work_order['work_order_id'],
                'line_id': work_order['line_id'],
                'product_id': work_order['product_id'],
                'operator_id': random.choice(self.operators)['operator_id'],
                'start_time': actual_start,
                'end_time': actual_start + timedelta(hours=random.uniform(2, 12)),
                'planned_quantity': planned_quantity,
                'actual_quantity': actual_quantity,
                'good_quantity': good_quantity,
                'scrap_quantity': scrap_quantity,
                'availability': round(availability, 3),
                'performance': round(performance, 3),
                'quality': round(quality, 3),
                'oee': round(availability * performance * quality, 3),
                'status': 'completed'
            }
            self.production_runs.append(production_run)

            # Update work order
            work_order['actual_start'] = actual_start
            work_order['actual_end'] = production_run['end_time']
            work_order['quantity_produced'] = actual_quantity
            work_order['quantity_good'] = good_quantity
            work_order['quantity_scrap'] = scrap_quantity
            work_order['status'] = 'completed'

            self.production_run_id += 1

    def _generate_sensor_readings(self):
        """Generate sensor readings"""
        print("  Generating sensor readings...")

        # LIMIT DATA: Only last 2 days and subset of sensors to prevent memory issues
        start_date = datetime.now() - timedelta(days=2)
        end_date = datetime.now()

        # Limit to small sample of sensors for performance
        active_sensors = [s for s in self.sensors if s['status'] == 'active'][:10]  # Only 10 sensors

        for sensor in active_sensors:
            current_time = start_date
            sensor_config = self.config['sensor_types'][sensor['sensor_type']]

            # Initialize with normal value
            current_value = random.uniform(
                sensor_config['normal_range'][0],
                sensor_config['normal_range'][1]
            )

            # Limit readings per sensor
            readings_count = 0
            max_readings_per_sensor = 1000  # Limit to 1000 readings per sensor

            while current_time <= end_date and readings_count < max_readings_per_sensor:
                # Check if machine is running
                machine = next(m for m in self.machines if m['machine_id'] == sensor['machine_id'])

                if machine['status'] == 'running':
                    # Add some variation
                    variation = random.gauss(0, (sensor_config['normal_range'][1] - sensor_config['normal_range'][0]) / 20)
                    current_value = max(
                        sensor_config['normal_range'][0],
                        min(sensor_config['normal_range'][1],
                            current_value + variation)
                    )

                    # Chance of anomaly
                    if random.random() < self.config['anomaly_patterns']['sensor_drift']:
                        current_value *= random.uniform(1.1, 1.3)

                    reading = {
                        'reading_id': len(self.sensor_readings) + 1,
                        'sensor_id': sensor['sensor_id'],
                        'timestamp': current_time,
                        'value': round(current_value, 2),
                        'quality': 'good' if sensor_config['normal_range'][0] <= current_value <= sensor_config['normal_range'][1] else 'warning'
                    }
                    self.sensor_readings.append(reading)
                    readings_count += 1

                current_time += timedelta(seconds=sensor['sampling_rate_seconds'])

    def _generate_machine_states(self):
        """Generate machine state history"""
        print("  Generating machine states...")

        start_date = datetime.strptime(self.config['date_ranges']['data_start'], '%Y-%m-%d')
        end_date = datetime.now()

        for machine in self.machines[:20]:  # Limit for performance
            current_time = start_date
            current_state = 'idle'

            while current_time <= end_date:
                # State duration
                if current_state == 'running':
                    duration_hours = random.uniform(2, 8)
                elif current_state == 'idle':
                    duration_hours = random.uniform(0.5, 2)
                elif current_state == 'maintenance':
                    duration_hours = random.uniform(1, 4)
                else:  # fault
                    duration_hours = random.uniform(0.25, 1)

                state_entry = {
                    'state_id': len(self.machine_states) + 1,
                    'machine_id': machine['machine_id'],
                    'state': current_state,
                    'start_time': current_time,
                    'end_time': current_time + timedelta(hours=duration_hours),
                    'operator_id': random.choice(self.operators)['operator_id'] if current_state == 'running' else None,
                    'work_order_id': random.choice(self.work_orders)['work_order_id'] if current_state == 'running' else None,
                    'reason': self._get_state_reason(current_state)
                }
                self.machine_states.append(state_entry)

                # Transition to next state
                current_time = state_entry['end_time']
                current_state = self._get_next_state(current_state)

    def _generate_quality_inspections(self):
        """Generate quality inspection records"""
        print("  Generating quality inspections...")

        for production_run in self.production_runs:
            # Number of inspections based on batch size
            num_inspections = min(10, max(1, production_run['actual_quantity'] // 100))

            for _ in range(num_inspections):
                # Determine if defect found
                product = next(p for p in self.products if p['product_id'] == production_run['product_id'])
                defect_rate = self.config['quality_defects']['defect_rates'][product['quality_level']]
                has_defect = random.random() < defect_rate

                inspection = {
                    'inspection_id': self.inspection_id,
                    'production_run_id': production_run['run_id'],
                    'product_id': production_run['product_id'],
                    'inspection_time': production_run['start_time'] + timedelta(
                        minutes=random.randint(10, 120)
                    ),
                    'inspector_id': random.choice(self.operators)['operator_id'],
                    'sample_size': random.randint(1, 10),
                    'passed': not has_defect,
                    'defect_type': random.choices(
                        list(self.config['quality_defects'].keys())[:5],
                        weights=[self.config['quality_defects'][k] for k in list(self.config['quality_defects'].keys())[:5]]
                    )[0] if has_defect else None,
                    'measurements': {
                        'dimension': round(random.gauss(10, 0.1), 3),
                        'weight': round(random.gauss(100, 1), 2),
                        'surface_roughness': round(random.uniform(0.5, 2.0), 2)
                    },
                    'notes': 'Defect found' if has_defect else 'Pass'
                }
                self.quality_inspections.append(inspection)
                self.inspection_id += 1

    def _generate_downtime_events(self):
        """Generate downtime events"""
        print("  Generating downtime events...")

        for machine in self.machines:
            # Generate some downtime events
            num_events = random.randint(0, 5)

            for _ in range(num_events):
                downtime_type = random.choice(['planned', 'unplanned'])

                if downtime_type == 'planned':
                    reason = random.choices(
                        list(self.config['downtime_reasons']['planned'].keys()),
                        weights=list(self.config['downtime_reasons']['planned'].values())
                    )[0]
                else:
                    reason = random.choices(
                        list(self.config['downtime_reasons']['unplanned'].keys()),
                        weights=list(self.config['downtime_reasons']['unplanned'].values())
                    )[0]

                start_time = datetime.strptime(
                    self.config['date_ranges']['data_start'], '%Y-%m-%d'
                ) + timedelta(hours=random.randint(0, 168))

                duration_minutes = random.randint(15, 240)

                downtime = {
                    'downtime_id': self.downtime_id,
                    'machine_id': machine['machine_id'],
                    'downtime_type': downtime_type,
                    'reason': reason,
                    'start_time': start_time,
                    'end_time': start_time + timedelta(minutes=duration_minutes),
                    'duration_minutes': duration_minutes,
                    'operator_id': random.choice(self.operators)['operator_id'],
                    'production_loss_units': random.randint(10, 500),
                    'resolved': True,
                    'notes': f"{reason.replace('_', ' ').title()} event"
                }
                self.downtime_events.append(downtime)
                self.downtime_id += 1

    def _generate_oee_metrics(self):
        """Generate OEE metrics for each shift"""
        print("  Generating OEE metrics...")

        start_date = datetime.strptime(self.config['date_ranges']['data_start'], '%Y-%m-%d')
        end_date = datetime.strptime(self.config['date_ranges']['data_end'], '%Y-%m-%d')

        for line in self.production_lines:
            current_date = start_date

            while current_date <= end_date:
                for shift in ['morning', 'afternoon', 'night']:
                    shift_config = self.config['production_metrics']['shift_performance'][shift]

                    availability = random.uniform(shift_config['availability'][0], shift_config['availability'][1])
                    performance = random.uniform(shift_config['performance'][0], shift_config['performance'][1])
                    quality = random.uniform(shift_config['quality'][0], shift_config['quality'][1])
                    oee = availability * performance * quality

                    metric = {
                        'metric_id': len(self.oee_metrics) + 1,
                        'line_id': line['line_id'],
                        'date': current_date.date(),
                        'shift': shift,
                        'availability': round(availability, 3),
                        'performance': round(performance, 3),
                        'quality': round(quality, 3),
                        'oee': round(oee, 3),
                        'planned_production_time_hours': 8,
                        'actual_production_time_hours': round(8 * availability, 2),
                        'total_units_produced': random.randint(100, 1000),
                        'good_units': int(random.randint(100, 1000) * quality),
                        'target_oee': self.config['production_metrics']['availability_target'] *
                                     self.config['production_metrics']['performance_target'] *
                                     self.config['production_metrics']['quality_target']
                    }
                    self.oee_metrics.append(metric)

                current_date += timedelta(days=1)

    def _generate_maintenance_records(self):
        """Generate maintenance records"""
        print("  Generating maintenance records...")

        for machine in self.machines:
            # Generate maintenance history
            maintenance_type = random.choices(
                list(self.config['maintenance_patterns']['maintenance_types'].keys()),
                weights=list(self.config['maintenance_patterns']['maintenance_types'].values())
            )[0]

            maintenance = {
                'maintenance_id': self.maintenance_id,
                'machine_id': machine['machine_id'],
                'maintenance_type': maintenance_type,
                'scheduled_date': machine['next_maintenance'],
                'actual_date': machine['next_maintenance'] + timedelta(days=random.randint(-2, 5)),
                'technician_id': random.choice(self.operators)['operator_id'],
                'duration_hours': random.uniform(0.5, 8),
                'parts_replaced': 'Various components' if random.random() < 0.3 else None,
                'cost': round(random.uniform(100, 5000), 2),
                'next_maintenance_due': machine['next_maintenance'] + timedelta(days=30),
                'notes': f"{maintenance_type.replace('_', ' ').title()} maintenance completed"
            }
            self.maintenance_records.append(maintenance)
            self.maintenance_id += 1

    def _generate_alarms(self):
        """Generate alarm events"""
        print("  Generating alarms...")

        for sensor in self.sensors[:50]:  # Limit for performance
            # Generate some alarms
            num_alarms = random.randint(0, 3)

            for _ in range(num_alarms):
                severity = random.choices(
                    list(self.config['alarm_patterns']['severity_distribution'].keys()),
                    weights=list(self.config['alarm_patterns']['severity_distribution'].values())
                )[0]

                response_range = self.config['alarm_patterns']['response_times'][severity]
                response_time = random.uniform(response_range[0], response_range[1])

                triggered_at = datetime.now() - timedelta(days=random.randint(0, 7))

                alarm = {
                    'alarm_id': self.alarm_id,
                    'sensor_id': sensor['sensor_id'],
                    'machine_id': sensor['machine_id'],
                    'alarm_type': f"{sensor['sensor_type']}_threshold",
                    'severity': severity,
                    'triggered_at': triggered_at,
                    'acknowledged_at': triggered_at + timedelta(minutes=response_time),
                    'resolved_at': triggered_at + timedelta(minutes=response_time + random.uniform(5, 60)),
                    'threshold_value': sensor['critical_value'],
                    'actual_value': sensor['critical_value'] * random.uniform(1.01, 1.5),
                    'operator_id': random.choice(self.operators)['operator_id'],
                    'action_taken': 'Investigated and resolved',
                    'false_positive': random.random() < 0.1
                }
                self.alarms.append(alarm)
                self.alarm_id += 1

    def _generate_energy_consumption(self):
        """Generate energy consumption data"""
        print("  Generating energy consumption...")

        # LIMIT DATA: Only last day to prevent memory issues
        start_date = datetime.now() - timedelta(days=1)
        end_date = datetime.now()

        for machine in self.machines[:5]:  # Only 5 machines for performance
            machine_type = machine['machine_type']
            consumption_range = self.config['energy_consumption']['machine_consumption'].get(
                machine_type, [5, 15]
            )

            current_time = start_date
            while current_time <= end_date:
                # Check if machine is running
                is_running = machine['status'] == 'running'

                if is_running:
                    base_consumption = random.uniform(consumption_range[0], consumption_range[1])

                    # Peak hour adjustment
                    hour = current_time.hour
                    peak_hours = self.config['energy_consumption']['peak_hours']
                    if peak_hours[0] <= hour <= peak_hours[1]:
                        consumption = base_consumption * 1.1  # Higher during peak
                    else:
                        consumption = base_consumption

                    power_factor = random.uniform(
                        self.config['energy_consumption']['power_factor'][0],
                        self.config['energy_consumption']['power_factor'][1]
                    )
                else:
                    consumption = consumption_range[0] * 0.1  # Standby power
                    power_factor = 0.85

                energy_record = {
                    'record_id': len(self.energy_consumption) + 1,
                    'machine_id': machine['machine_id'],
                    'timestamp': current_time,
                    'power_kw': round(consumption, 2),
                    'energy_kwh': round(consumption / 4, 3),  # 15-minute interval
                    'power_factor': round(power_factor, 3),
                    'voltage': round(random.gauss(400, 5), 1),
                    'current': round(consumption / (0.4 * math.sqrt(3)), 2),
                    'frequency': round(random.gauss(50, 0.1), 2),
                    'is_peak_hour': peak_hours[0] <= hour <= peak_hours[1]
                }
                self.energy_consumption.append(energy_record)

                current_time += timedelta(minutes=15)

    # Helper methods
    def _get_timezone(self, location: str) -> str:
        """Get timezone for location"""
        if 'Detroit' in location:
            return 'America/Detroit'
        elif 'Phoenix' in location:
            return 'America/Phoenix'
        elif 'Atlanta' in location:
            return 'America/New_York'
        else:
            return 'UTC'

    def _generate_serial(self) -> str:
        """Generate serial number"""
        return ''.join(random.choices('ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789', k=12))

    def _get_shift(self, hour: int) -> str:
        """Get shift based on hour"""
        if 6 <= hour < 14:
            return 'morning'
        elif 14 <= hour < 22:
            return 'afternoon'
        else:
            return 'night'

    def _get_state_reason(self, state: str) -> str:
        """Get reason for machine state"""
        reasons = {
            'running': 'Production',
            'idle': 'No work order',
            'maintenance': 'Scheduled maintenance',
            'fault': 'Equipment failure'
        }
        return reasons.get(state, 'Unknown')

    def _get_next_state(self, current_state: str) -> str:
        """Get next machine state"""
        transitions = {
            'running': ['idle', 'maintenance', 'fault', 'running'],
            'idle': ['running', 'maintenance', 'idle'],
            'maintenance': ['idle', 'running'],
            'fault': ['maintenance', 'idle']
        }
        weights = {
            'running': [0.3, 0.05, 0.02, 0.63],
            'idle': [0.7, 0.1, 0.2],
            'maintenance': [0.5, 0.5],
            'fault': [0.8, 0.2]
        }

        return random.choices(transitions[current_state], weights=weights[current_state])[0]

    def _write_all_csvs(self):
        """Write all data to CSV files"""
        datasets = [
            ('factories', self.factories),
            ('production_lines', self.production_lines),
            ('machines', self.machines),
            ('sensors', self.sensors),
            ('operators', self.operators),
            ('products', self.products),
            ('work_orders', self.work_orders),
            ('production_runs', self.production_runs),
            ('sensor_readings', self.sensor_readings[:10000]),  # Limit for size
            ('machine_states', self.machine_states),
            ('quality_inspections', self.quality_inspections),
            ('downtime_events', self.downtime_events),
            ('maintenance_records', self.maintenance_records),
            ('alarms', self.alarms),
            ('oee_metrics', self.oee_metrics),
            ('energy_consumption', self.energy_consumption[:5000])  # Limit for size
        ]

        for filename, data in datasets:
            if not data:
                continue

            filepath = self.output_dir / f"{filename}.csv"
            with open(filepath, 'w', newline='', encoding='utf-8') as f:
                if data:
                    # Convert dict values to strings for measurements
                    if filename == 'quality_inspections':
                        for item in data:
                            if 'measurements' in item:
                                item['measurements'] = str(item['measurements'])

                    writer = csv.DictWriter(f, fieldnames=data[0].keys())
                    writer.writeheader()
                    writer.writerows(data)

            print(f"  [OK] Wrote {len(data)} records to {filename}.csv")

    def _generate_sql_scripts(self):
        """Generate SQL load scripts"""
        load_script = f"""-- Load generated Industrial IoT data
-- Generated on {datetime.now()}

-- Clear existing data
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE energy_consumption;
TRUNCATE TABLE alarms;
TRUNCATE TABLE oee_metrics;
TRUNCATE TABLE maintenance_records;
TRUNCATE TABLE downtime_events;
TRUNCATE TABLE quality_inspections;
TRUNCATE TABLE machine_states;
TRUNCATE TABLE sensor_readings;
TRUNCATE TABLE production_runs;
TRUNCATE TABLE work_orders;
TRUNCATE TABLE products;
TRUNCATE TABLE operators;
TRUNCATE TABLE sensors;
TRUNCATE TABLE machines;
TRUNCATE TABLE production_lines;
TRUNCATE TABLE factories;
SET FOREIGN_KEY_CHECKS = 1;

-- Load data files
LOAD DATA INFILE '/var/lib/mysql-files/industrial_iot/factories.csv'
INTO TABLE factories
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\\n'
IGNORE 1 ROWS;

LOAD DATA INFILE '/var/lib/mysql-files/industrial_iot/machines.csv'
INTO TABLE machines
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\\n'
IGNORE 1 ROWS;

-- Update statistics
ANALYZE TABLE factories, machines, work_orders, sensor_readings;

SELECT 'Data load complete!' as status;
SELECT COUNT(*) as factory_count FROM factories;
SELECT COUNT(*) as machine_count FROM machines;
SELECT COUNT(*) as work_order_count FROM work_orders;
SELECT COUNT(*) as sensor_reading_count FROM sensor_readings;
"""

        script_path = self.output_dir / 'load_data.sql'
        with open(script_path, 'w') as f:
            f.write(load_script)

        print(f"  [OK] Generated SQL load script: load_data.sql")

def main():
    parser = argparse.ArgumentParser(description='Generate Industrial IoT data')
    parser.add_argument('--config', default='config.yaml', help='Path to config.yaml')
    args = parser.parse_args()

    generator = IndustrialIoTGenerator(args.config)
    generator.generate_all()

if __name__ == '__main__':
    main()
