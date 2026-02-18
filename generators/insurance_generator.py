#!/usr/bin/env python3
"""
Insurance Management Platform Data Generator

Generates realistic test data for the insurance platform database.
Includes customers, policies, claims, agents, underwriting, and reinsurance.
"""

import random
import sys
import os
from datetime import datetime, timedelta, date
from decimal import Decimal
from typing import List, Dict, Tuple, Optional
import json

# Add parent directory to path for base generator
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from generators.base_generator import BaseGenerator


class InsuranceGenerator(BaseGenerator):
    """Generator for Insurance Management Platform data"""

    def __init__(self, host='localhost', port=3339, user='insurance_admin',
                 password='insurance_pass_2024', database='insurance_platform'):
        """Initialize the insurance generator"""
        super().__init__(host, port, user, password, database)

        # Insurance specific data
        self.product_types = ['life', 'health', 'auto', 'home', 'disability', 'travel', 'pet', 'business']

        self.claim_types = ['accident', 'illness', 'death', 'property_damage', 'theft',
                           'liability', 'natural_disaster', 'medical', 'dental', 'vision']

        self.risk_categories = ['low', 'medium', 'high', 'very_high']

        self.policy_statuses = ['active', 'expired', 'cancelled', 'suspended', 'pending']

        self.claim_statuses = ['submitted', 'acknowledged', 'investigating', 'approved',
                               'rejected', 'paid', 'appealed', 'closed']

        self.underwriting_decisions = ['approved', 'rejected', 'pending', 'referred']

        # Commission rates by product type
        self.commission_rates = {
            'life': 0.50,  # 50% first year
            'health': 0.15,
            'auto': 0.12,
            'home': 0.15,
            'disability': 0.40,
            'travel': 0.20,
            'pet': 0.15,
            'business': 0.20
        }

    def generate_all_data(self, customers: int = 10000, agents: int = 500,
                         policies_per_customer: float = 1.5):
        """Generate all insurance platform data"""
        print("Starting Insurance Platform data generation...")

        # Generate base data
        print("Generating customers...")
        self.generate_customers(customers)

        print("Generating beneficiaries...")
        self.generate_beneficiaries()

        print("Generating agencies and agents...")
        self.generate_agencies_and_agents(agents)

        print("Generating brokers...")
        self.generate_brokers()

        print("Generating insurance products...")
        self.generate_products()

        print("Generating underwriting applications...")
        self.generate_underwriting()

        print("Generating policies...")
        self.generate_policies(int(customers * policies_per_customer))

        print("Generating policy items and beneficiaries...")
        self.generate_policy_items()
        self.generate_policy_beneficiaries()

        print("Generating billing schedules...")
        self.generate_billing_schedules()

        print("Generating claims...")
        self.generate_claims()

        print("Generating claim activities...")
        self.generate_claim_activities()

        print("Generating payments...")
        self.generate_payments()

        print("Generating commissions...")
        self.generate_commissions()

        print("Generating reinsurance...")
        self.generate_reinsurance()

        print("Generating documents and communications...")
        self.generate_documents()
        self.generate_communications()

        print("Generating regulatory reports...")
        self.generate_regulatory_reports()

        print("Generation complete!")

    def generate_customers(self, count: int = 10000):
        """Generate insurance customers"""
        customers = []

        for i in range(count):
            customer_type = self.faker.random_element([
                ('individual', 0.85),
                ('corporate', 0.15)
            ])

            if customer_type == 'individual':
                first_name = self.faker.first_name()
                last_name = self.faker.last_name()
                company_name = None
                ssn = self.faker.ssn()
            else:
                first_name = None
                last_name = None
                company_name = self.faker.company()
                ssn = self.faker.ein()

            # Risk assessment
            age = random.randint(18, 80) if customer_type == 'individual' else None
            risk_category = self.calculate_risk_category(age, customer_type)

            # Credit score (US range)
            credit_score = random.randint(300, 850)

            # Health information (for life/health insurance)
            if customer_type == 'individual':
                health_conditions = random.choice([
                    None,
                    json.dumps(['hypertension']),
                    json.dumps(['diabetes']),
                    json.dumps(['asthma']),
                    json.dumps(['hypertension', 'diabetes'])
                ])
                smoker = random.choice([0, 1]) if random.random() > 0.7 else 0
                bmi = random.uniform(18.5, 35.0)
            else:
                health_conditions = None
                smoker = 0
                bmi = None

            customer = (
                customer_type,
                first_name,
                last_name,
                company_name,
                self.faker.email(),
                self.faker.phone_number(),
                self.faker.address(),
                self.faker.city(),
                self.faker.state_abbr(),
                self.faker.zipcode(),
                self.faker.country(),
                self.faker.date_of_birth(minimum_age=18, maximum_age=80) if customer_type == 'individual' else None,
                random.choice(['M', 'F', None]) if customer_type == 'individual' else None,
                ssn,
                risk_category,
                credit_score,
                random.choice([0, 1]),  # kyc_verified
                self.faker.date_time_between('-1 year', 'now') if random.random() > 0.3 else None,
                health_conditions,
                smoker,
                bmi,
                random.choice([0, 1]),  # marketing_consent
                random.randint(0, 20),  # total_policies
                random.uniform(0, 100000),  # total_premiums_paid
                random.randint(0, 10),  # total_claims_filed
                self.faker.date_time_between('-5 years', 'now'),
                self.faker.date_time_between('-5 years', 'now')
            )
            customers.append(customer)

            if (i + 1) % 1000 == 0:
                self.bulk_insert('customers', customers, [
                    'customer_type', 'first_name', 'last_name', 'company_name',
                    'email', 'phone', 'address', 'city', 'state', 'postal_code',
                    'country', 'date_of_birth', 'gender', 'ssn_tax_id',
                    'risk_category', 'credit_score', 'kyc_verified',
                    'kyc_verified_date', 'health_conditions', 'smoker', 'bmi',
                    'marketing_consent', 'total_policies', 'total_premiums_paid',
                    'total_claims_filed', 'created_at', 'updated_at'
                ])
                customers = []
                print(f"  Generated {i + 1}/{count} customers...")

        if customers:
            self.bulk_insert('customers', customers, [
                'customer_type', 'first_name', 'last_name', 'company_name',
                'email', 'phone', 'address', 'city', 'state', 'postal_code',
                'country', 'date_of_birth', 'gender', 'ssn_tax_id',
                'risk_category', 'credit_score', 'kyc_verified',
                'kyc_verified_date', 'health_conditions', 'smoker', 'bmi',
                'marketing_consent', 'total_policies', 'total_premiums_paid',
                'total_claims_filed', 'created_at', 'updated_at'
            ])

    def calculate_risk_category(self, age: Optional[int], customer_type: str) -> str:
        """Calculate risk category based on age and type"""
        if customer_type == 'corporate':
            return random.choice(['low', 'medium', 'high'])

        if age is None:
            return 'medium'

        if age < 25:
            return random.choice(['medium', 'high', 'very_high'])
        elif age < 40:
            return random.choice(['low', 'medium'])
        elif age < 60:
            return random.choice(['medium', 'high'])
        else:
            return random.choice(['high', 'very_high'])

    def generate_beneficiaries(self):
        """Generate beneficiaries for customers"""
        customers = self.fetch_all("""
            SELECT customer_id FROM customers
            WHERE customer_type = 'individual'
            LIMIT 5000
        """)

        beneficiaries = []

        for customer in customers:
            # Each customer has 0-3 beneficiaries
            num_beneficiaries = random.randint(0, 3)

            for i in range(num_beneficiaries):
                is_primary = i == 0  # First beneficiary is primary

                beneficiary = (
                    customer['customer_id'],
                    self.faker.first_name(),
                    self.faker.last_name(),
                    random.choice(['spouse', 'child', 'parent', 'sibling', 'other']),
                    self.faker.date_of_birth(minimum_age=0, maximum_age=90),
                    self.faker.ssn() if random.random() > 0.5 else None,
                    self.faker.phone_number(),
                    self.faker.email() if random.random() > 0.5 else None,
                    self.faker.address(),
                    100.0 if is_primary and num_beneficiaries == 1 else random.uniform(20, 80),
                    is_primary,
                    random.choice(['revocable', 'irrevocable']),
                    random.choice([0, 1]),  # is_active
                    self.faker.date_time_between('-5 years', 'now')
                )
                beneficiaries.append(beneficiary)

        self.bulk_insert('beneficiaries', beneficiaries, [
            'customer_id', 'first_name', 'last_name', 'relationship',
            'date_of_birth', 'ssn', 'phone', 'email', 'address',
            'percentage_allocation', 'is_primary', 'beneficiary_type',
            'is_active', 'created_at'
        ])

    def generate_agencies_and_agents(self, total_agents: int = 500):
        """Generate insurance agencies and agents"""
        # Generate agencies
        agencies = []
        num_agencies = 20

        for i in range(num_agencies):
            agency = (
                f"{self.faker.company()} Insurance Agency",
                f"AG{str(i+1).zfill(5)}",
                self.faker.address(),
                self.faker.city(),
                self.faker.state_abbr(),
                self.faker.zipcode(),
                self.faker.phone_number(),
                self.faker.email(),
                self.faker.url(),
                random.uniform(0.02, 0.05),  # commission_rate
                self.faker.date_between('-10 years', '-1 year'),
                self.faker.date_between('+1 year', '+5 years'),
                'active',
                random.randint(0, 100),  # total_agents
                random.uniform(0, 10000000),  # total_premium
                self.faker.date_time_between('-10 years', 'now')
            )
            agencies.append(agency)

        self.bulk_insert('agencies', agencies, [
            'agency_name', 'agency_code', 'address', 'city', 'state',
            'postal_code', 'phone', 'email', 'website', 'commission_rate',
            'contract_start_date', 'contract_end_date', 'status',
            'total_agents', 'total_premium', 'created_at'
        ])

        # Generate agents
        agents = []
        agency_ids = list(range(1, num_agencies + 1))

        for i in range(total_agents):
            # Hierarchical structure - some agents are managers
            is_manager = i < total_agents * 0.1  # 10% are managers
            manager_id = random.randint(1, int(total_agents * 0.1)) if not is_manager and random.random() > 0.5 else None

            agent = (
                random.choice(agency_ids) if random.random() > 0.2 else None,  # 80% belong to agencies
                f"LIC{str(i+1).zfill(8)}",
                self.faker.first_name(),
                self.faker.last_name(),
                self.faker.email(),
                self.faker.phone_number(),
                manager_id,
                json.dumps(random.sample(self.product_types, random.randint(1, 4))),  # licensed_products
                json.dumps(random.sample(['CA', 'NY', 'TX', 'FL', 'IL'], random.randint(1, 3))),  # licensed_states
                self.faker.date_between('-2 years', '+1 year'),
                random.uniform(0.05, 0.15),  # commission_rate
                random.uniform(0.01, 0.03) if is_manager else None,  # override_rate
                'active',
                random.randint(0, 1000),  # total_policies_sold
                random.uniform(0, 5000000),  # total_premium_sold
                random.uniform(0, 1000000),  # current_month_sales
                random.uniform(0, 10000000),  # ytd_sales
                self.faker.date_time_between('-5 years', 'now')
            )
            agents.append(agent)

            if (i + 1) % 100 == 0:
                self.bulk_insert('agents', agents, [
                    'agency_id', 'license_number', 'first_name', 'last_name',
                    'email', 'phone', 'manager_id', 'licensed_products',
                    'licensed_states', 'license_expiry', 'commission_rate',
                    'override_rate', 'status', 'total_policies_sold',
                    'total_premium_sold', 'current_month_sales', 'ytd_sales',
                    'created_at'
                ])
                agents = []
                print(f"  Generated {i + 1}/{total_agents} agents...")

        if agents:
            self.bulk_insert('agents', agents, [
                'agency_id', 'license_number', 'first_name', 'last_name',
                'email', 'phone', 'manager_id', 'licensed_products',
                'licensed_states', 'license_expiry', 'commission_rate',
                'override_rate', 'status', 'total_policies_sold',
                'total_premium_sold', 'current_month_sales', 'ytd_sales',
                'created_at'
            ])

    def generate_brokers(self):
        """Generate insurance brokers"""
        brokers = []

        for i in range(50):
            broker_type = random.choice(['individual', 'company'])

            if broker_type == 'individual':
                broker_name = f"{self.faker.first_name()} {self.faker.last_name()}"
                company_name = None
            else:
                broker_name = None
                company_name = f"{self.faker.company()} Insurance Brokers"

            broker = (
                f"BRK{str(i+1).zfill(6)}",
                broker_type,
                broker_name,
                company_name,
                self.faker.email(),
                self.faker.phone_number(),
                self.faker.address(),
                json.dumps(random.sample(['CA', 'NY', 'TX', 'FL', 'IL'], random.randint(1, 5))),
                random.uniform(0.03, 0.10),  # commission_rate
                'active',
                random.randint(0, 500),  # total_policies_referred
                random.uniform(0, 2000000),  # total_premium_referred
                self.faker.date_time_between('-5 years', 'now')
            )
            brokers.append(broker)

        self.bulk_insert('brokers', brokers, [
            'broker_code', 'broker_type', 'broker_name', 'company_name',
            'email', 'phone', 'address', 'licensed_states',
            'commission_rate', 'status', 'total_policies_referred',
            'total_premium_referred', 'created_at'
        ])

    def generate_products(self):
        """Generate insurance products"""
        products = []

        # Define products by type
        product_definitions = {
            'life': [
                ('Term Life Insurance', 'term_life', [100000, 1000000]),
                ('Whole Life Insurance', 'whole_life', [50000, 500000]),
                ('Universal Life Insurance', 'universal_life', [100000, 2000000])
            ],
            'health': [
                ('Basic Health Plan', 'health_basic', [5000, 10000]),
                ('Premium Health Plan', 'health_premium', [2000, 5000]),
                ('Family Health Plan', 'health_family', [10000, 25000])
            ],
            'auto': [
                ('Liability Only', 'auto_liability', [25000, 50000]),
                ('Comprehensive Coverage', 'auto_comprehensive', [50000, 100000]),
                ('Full Coverage', 'auto_full', [100000, 250000])
            ],
            'home': [
                ('Basic Homeowners', 'home_basic', [100000, 250000]),
                ('Premium Homeowners', 'home_premium', [250000, 1000000]),
                ('Renters Insurance', 'renters', [10000, 50000])
            ]
        }

        for product_type, type_products in product_definitions.items():
            for product_name, product_code, coverage_range in type_products:
                product = (
                    product_name,
                    product_code,
                    product_type,
                    self.faker.text(max_nb_chars=500),
                    coverage_range[0],  # min_coverage
                    coverage_range[1],  # max_coverage
                    random.uniform(100, 5000) if product_type != 'life' else random.uniform(20, 200),  # min_premium
                    random.uniform(5000, 50000) if product_type != 'life' else random.uniform(200, 5000),  # max_premium
                    random.randint(100, 5000) if product_type in ['auto', 'home'] else 0,  # deductible
                    random.randint(0, 90),  # waiting_period_days
                    random.randint(18, 65),  # min_age
                    random.randint(65, 99),  # max_age
                    json.dumps(['medical_exam']) if product_type == 'life' else None,  # eligibility_criteria
                    json.dumps(['CA', 'NY', 'TX', 'FL', 'IL']),  # states_available
                    random.choice([0, 1]),  # renewable
                    random.choice([0, 1]),  # is_active
                    self.faker.date_time_between('-3 years', 'now')
                )
                products.append(product)

        self.bulk_insert('products', products, [
            'product_name', 'product_code', 'product_type', 'description',
            'min_coverage', 'max_coverage', 'min_premium', 'max_premium',
            'deductible', 'waiting_period_days', 'min_age', 'max_age',
            'eligibility_criteria', 'states_available', 'renewable',
            'is_active', 'created_at'
        ])

    def generate_underwriting(self):
        """Generate underwriting applications"""
        customers = self.fetch_all("SELECT customer_id, risk_category FROM customers LIMIT 2000")
        products = self.fetch_all("SELECT product_id, product_type FROM products")
        agents = self.fetch_all("SELECT agent_id FROM agents WHERE status = 'active'")

        applications = []

        for customer in customers:
            # Each customer may have 1-2 underwriting applications
            num_apps = random.randint(1, 2)

            for _ in range(num_apps):
                product = random.choice(products)

                # Risk assessment based on product type
                if product['product_type'] == 'life':
                    medical_exam_required = True
                    medical_exam_completed = random.choice([0, 1])
                else:
                    medical_exam_required = random.choice([0, 1])
                    medical_exam_completed = medical_exam_required and random.choice([0, 1])

                # Decision based on risk
                if customer['risk_category'] in ['low', 'medium']:
                    decision = self.faker.random_element([
                        ('approved', 0.8),
                        ('pending', 0.15),
                        ('rejected', 0.05)
                    ])
                else:
                    decision = self.faker.random_element([
                        ('approved', 0.4),
                        ('pending', 0.3),
                        ('referred', 0.2),
                        ('rejected', 0.1)
                    ])

                application = (
                    customer['customer_id'],
                    product['product_id'],
                    random.choice(agents)['agent_id'] if agents and random.random() > 0.3 else None,
                    random.uniform(10000, 1000000),  # requested_coverage
                    random.uniform(50, 5000),  # quoted_premium
                    customer['risk_category'],
                    random.randint(300, 850),  # risk_score
                    medical_exam_required,
                    medical_exam_completed,
                    None if not medical_exam_completed else self.faker.date_time_between('-60 days', 'now'),
                    random.choice([0, 1]) if product['product_type'] == 'home' else 0,  # property_inspection_required
                    random.choice([0, 1]) if product['product_type'] == 'home' else 0,  # property_inspection_completed
                    decision,
                    random.uniform(50, 5000) if decision == 'approved' else None,  # final_premium
                    None if decision != 'rejected' else random.choice([
                        'High risk score', 'Medical conditions', 'Age limit exceeded',
                        'Coverage amount too high', 'Incomplete documentation'
                    ]),
                    random.randint(1, 10) if decision != 'pending' else None,  # underwriter_id
                    self.faker.date_time_between('-90 days', 'now'),
                    self.faker.date_time_between('-60 days', 'now') if decision != 'pending' else None
                )
                applications.append(application)

        self.bulk_insert('underwriting_applications', applications, [
            'customer_id', 'product_id', 'agent_id', 'requested_coverage',
            'quoted_premium', 'risk_category', 'risk_score',
            'medical_exam_required', 'medical_exam_completed',
            'medical_exam_date', 'property_inspection_required',
            'property_inspection_completed', 'decision', 'final_premium',
            'rejection_reason', 'underwriter_id', 'created_at', 'decision_date'
        ])

    def generate_policies(self, count: int = 15000):
        """Generate insurance policies"""
        # Get approved underwriting applications
        approved_apps = self.fetch_all("""
            SELECT ua.*, p.product_type, p.product_code
            FROM underwriting_applications ua
            JOIN products p ON ua.product_id = p.product_id
            WHERE ua.decision = 'approved'
        """)

        customers = self.fetch_all("SELECT customer_id FROM customers")
        products = self.fetch_all("SELECT * FROM products WHERE is_active = 1")
        agents = self.fetch_all("SELECT agent_id FROM agents WHERE status = 'active'")
        brokers = self.fetch_all("SELECT broker_id FROM brokers WHERE status = 'active'")

        policies = []

        # Generate policies from approved applications
        for app in approved_apps[:min(count, len(approved_apps))]:
            policy = self.create_policy_from_application(app, agents, brokers)
            policies.append(policy)

        # Generate additional direct policies if needed
        remaining = count - len(policies)
        for _ in range(remaining):
            customer = random.choice(customers)
            product = random.choice(products)
            policy = self.create_direct_policy(customer, product, agents, brokers)
            policies.append(policy)

            if len(policies) % 1000 == 0:
                self.bulk_insert('policies', policies[-1000:], [
                    'policy_number', 'customer_id', 'product_id', 'agent_id',
                    'broker_id', 'underwriting_id', 'status', 'effective_date',
                    'expiry_date', 'term_months', 'coverage_amount', 'deductible',
                    'premium_amount', 'payment_frequency', 'commission_rate',
                    'discount_percentage', 'risk_category', 'risk_score',
                    'underwriting_status', 'auto_renewal', 'renewal_count',
                    'previous_policy_id', 'is_renewal', 'cancellation_date',
                    'cancellation_reason', 'created_at', 'updated_at'
                ])
                print(f"  Generated {len(policies)}/{count} policies...")

        # Insert remaining policies
        if len(policies) % 1000 != 0:
            remaining_policies = policies[-(len(policies) % 1000):]
            self.bulk_insert('policies', remaining_policies, [
                'policy_number', 'customer_id', 'product_id', 'agent_id',
                'broker_id', 'underwriting_id', 'status', 'effective_date',
                'expiry_date', 'term_months', 'coverage_amount', 'deductible',
                'premium_amount', 'payment_frequency', 'commission_rate',
                'discount_percentage', 'risk_category', 'risk_score',
                'underwriting_status', 'auto_renewal', 'renewal_count',
                'previous_policy_id', 'is_renewal', 'cancellation_date',
                'cancellation_reason', 'created_at', 'updated_at'
            ])

    def create_policy_from_application(self, app: dict, agents: list, brokers: list) -> tuple:
        """Create a policy from an approved underwriting application"""
        policy_number = f"POL{str(random.randint(100000, 999999))}-{app['product_code']}"

        effective_date = self.faker.date_between('-2 years', 'today')
        term_months = random.choice([6, 12, 24, 36]) if app['product_type'] != 'life' else random.choice([120, 240, 360])
        expiry_date = effective_date + timedelta(days=term_months * 30)

        status = 'active' if expiry_date > date.today() else 'expired'

        return (
            policy_number,
            app['customer_id'],
            app['product_id'],
            app['agent_id'],
            random.choice(brokers)['broker_id'] if brokers and random.random() > 0.8 else None,
            app['application_id'],
            status,
            effective_date,
            expiry_date,
            term_months,
            app['requested_coverage'],
            random.uniform(100, 5000) if app['product_type'] in ['auto', 'home'] else 0,
            app['final_premium'],
            random.choice(['monthly', 'quarterly', 'semi_annual', 'annual']),
            self.commission_rates.get(app['product_type'], 0.15),
            random.uniform(0, 20) if random.random() > 0.7 else 0,
            app['risk_category'],
            app['risk_score'],
            'approved',
            random.choice([0, 1]),
            0,
            None,
            False,
            None if status == 'active' else self.faker.date_between(effective_date, expiry_date) if status == 'cancelled' else None,
            None if status == 'active' else random.choice(['non_payment', 'customer_request', 'fraud', 'risk_change']) if status == 'cancelled' else None,
            self.faker.date_time_between('-2 years', 'now'),
            self.faker.date_time_between('-2 years', 'now')
        )

    def create_direct_policy(self, customer: dict, product: dict, agents: list, brokers: list) -> tuple:
        """Create a direct policy without underwriting application"""
        policy_number = f"POL{str(random.randint(100000, 999999))}-{product['product_code']}"

        effective_date = self.faker.date_between('-2 years', 'today')
        term_months = random.choice([6, 12, 24, 36]) if product['product_type'] != 'life' else random.choice([120, 240, 360])
        expiry_date = effective_date + timedelta(days=term_months * 30)

        status = self.faker.random_element([
            ('active', 0.6),
            ('expired', 0.25),
            ('cancelled', 0.10),
            ('suspended', 0.05)
        ])

        coverage = random.uniform(product['min_coverage'], product['max_coverage'])
        premium = random.uniform(product['min_premium'], product['max_premium'])

        return (
            policy_number,
            customer['customer_id'],
            product['product_id'],
            random.choice(agents)['agent_id'] if agents and random.random() > 0.3 else None,
            random.choice(brokers)['broker_id'] if brokers and random.random() > 0.9 else None,
            None,  # no underwriting_id
            status,
            effective_date,
            expiry_date,
            term_months,
            coverage,
            product['deductible'],
            premium,
            random.choice(['monthly', 'quarterly', 'semi_annual', 'annual']),
            self.commission_rates.get(product['product_type'], 0.15),
            random.uniform(0, 20) if random.random() > 0.7 else 0,
            random.choice(self.risk_categories),
            random.randint(300, 850),
            'auto_approved',
            random.choice([0, 1]),
            random.randint(0, 3),
            None,
            random.choice([0, 1]) if random.random() > 0.8 else 0,
            None if status == 'active' else self.faker.date_between(effective_date, expiry_date) if status == 'cancelled' else None,
            None if status == 'active' else random.choice(['non_payment', 'customer_request', 'fraud']) if status == 'cancelled' else None,
            self.faker.date_time_between('-2 years', 'now'),
            self.faker.date_time_between('-2 years', 'now')
        )

    def generate_policy_items(self):
        """Generate policy items (vehicles, properties, etc.)"""
        # Get auto and home policies
        auto_policies = self.fetch_all("""
            SELECT p.policy_id FROM policies p
            JOIN products pr ON p.product_id = pr.product_id
            WHERE pr.product_type = 'auto'
            LIMIT 1000
        """)

        home_policies = self.fetch_all("""
            SELECT p.policy_id FROM policies p
            JOIN products pr ON p.product_id = pr.product_id
            WHERE pr.product_type = 'home'
            LIMIT 1000
        """)

        items = []

        # Generate vehicle items
        for policy in auto_policies:
            vehicle = (
                policy['policy_id'],
                'vehicle',
                self.faker.vehicle_year_make_model(),
                self.faker.vin(),
                self.faker.license_plate(),
                None,  # property_address
                None,  # property_type
                random.uniform(5000, 50000),  # item_value
                random.choice([0, 1]),  # is_primary
                random.choice([0, 1]),  # is_active
                self.faker.date_time_between('-2 years', 'now')
            )
            items.append(vehicle)

        # Generate property items
        for policy in home_policies:
            property_item = (
                policy['policy_id'],
                'property',
                None,  # item_description (for property)
                None,  # vin
                None,  # license_plate
                self.faker.address(),
                random.choice(['single_family', 'condo', 'townhouse', 'apartment']),
                random.uniform(100000, 1000000),
                random.choice([0, 1]),  # is_primary
                random.choice([0, 1]),  # is_active
                self.faker.date_time_between('-2 years', 'now')
            )
            items.append(property_item)

        self.bulk_insert('policy_items', items, [
            'policy_id', 'item_type', 'item_description', 'vin',
            'license_plate', 'property_address', 'property_type',
            'item_value', 'is_primary', 'is_active', 'created_at'
        ])

    def generate_policy_beneficiaries(self):
        """Generate policy beneficiaries for life insurance"""
        life_policies = self.fetch_all("""
            SELECT p.policy_id, p.customer_id
            FROM policies p
            JOIN products pr ON p.product_id = pr.product_id
            WHERE pr.product_type = 'life'
            LIMIT 1000
        """)

        # Get beneficiaries for these customers
        customer_ids = [p['customer_id'] for p in life_policies]
        beneficiaries = self.fetch_all(f"""
            SELECT beneficiary_id, customer_id
            FROM beneficiaries
            WHERE customer_id IN ({','.join(map(str, customer_ids))})
            AND is_active = 1
        """) if customer_ids else []

        # Group beneficiaries by customer
        beneficiaries_by_customer = {}
        for ben in beneficiaries:
            cid = ben['customer_id']
            if cid not in beneficiaries_by_customer:
                beneficiaries_by_customer[cid] = []
            beneficiaries_by_customer[cid].append(ben['beneficiary_id'])

        policy_beneficiaries = []

        for policy in life_policies:
            customer_beneficiaries = beneficiaries_by_customer.get(policy['customer_id'], [])

            if customer_beneficiaries:
                # Assign beneficiaries to policy
                total_percentage = 100.0
                num_beneficiaries = min(len(customer_beneficiaries), 3)

                for i, ben_id in enumerate(customer_beneficiaries[:num_beneficiaries]):
                    if i == num_beneficiaries - 1:
                        percentage = total_percentage
                    else:
                        percentage = random.uniform(20, total_percentage - 20)
                        total_percentage -= percentage

                    policy_ben = (
                        policy['policy_id'],
                        ben_id,
                        percentage,
                        'primary' if i == 0 else 'contingent',
                        self.faker.date_time_between('-2 years', 'now')
                    )
                    policy_beneficiaries.append(policy_ben)

        self.bulk_insert('policy_beneficiaries', policy_beneficiaries, [
            'policy_id', 'beneficiary_id', 'percentage_allocation',
            'beneficiary_type', 'created_at'
        ])

    def generate_billing_schedules(self):
        """Generate billing schedules for active policies"""
        active_policies = self.fetch_all("""
            SELECT policy_id, premium_amount, payment_frequency
            FROM policies
            WHERE status = 'active'
            LIMIT 2000
        """)

        schedules = []

        for policy in active_policies:
            # Calculate billing amount based on frequency
            frequency_multiplier = {
                'monthly': 1,
                'quarterly': 3,
                'semi_annual': 6,
                'annual': 12
            }

            multiplier = frequency_multiplier.get(policy['payment_frequency'], 1)
            billing_amount = float(policy['premium_amount']) * multiplier

            schedule = (
                policy['policy_id'],
                policy['payment_frequency'],
                billing_amount,
                random.randint(1, 28),  # billing_day
                random.choice(['credit_card', 'debit_card', 'bank_transfer', 'check']),
                random.choice([0, 1]),  # auto_pay_enabled
                self.faker.credit_card_number() if random.random() > 0.5 else None,
                self.faker.iban() if random.random() > 0.5 else None,
                random.choice([0, 1]),  # is_active
                self.faker.date_time_between('-1 year', '+1 month'),  # next_billing_date
                self.faker.date_time_between('-1 year', 'now')
            )
            schedules.append(schedule)

        self.bulk_insert('billing_schedules', schedules, [
            'policy_id', 'billing_frequency', 'billing_amount', 'billing_day',
            'payment_method', 'auto_pay_enabled', 'card_last_four',
            'bank_account_last_four', 'is_active', 'next_billing_date',
            'created_at'
        ])

    def generate_claims(self):
        """Generate insurance claims"""
        policies = self.fetch_all("""
            SELECT p.policy_id, p.customer_id, p.coverage_amount, pr.product_type
            FROM policies p
            JOIN products pr ON p.product_id = pr.product_id
            WHERE p.status IN ('active', 'expired')
            LIMIT 2000
        """)

        claims = []

        for policy in policies:
            # 30% of policies have claims
            if random.random() > 0.7:
                num_claims = random.randint(1, 3)

                for _ in range(num_claims):
                    claim_type = self.get_claim_type_for_product(policy['product_type'])
                    claimed_amount = random.uniform(100, min(float(policy['coverage_amount']), 50000))

                    # Determine claim status and amounts
                    status = random.choice(self.claim_statuses)

                    if status in ['approved', 'paid']:
                        approved_amount = claimed_amount * random.uniform(0.5, 1.0)
                        paid_amount = approved_amount if status == 'paid' else 0
                        fraud_suspected = False
                        fraud_score = random.uniform(0, 30)
                    elif status == 'rejected':
                        approved_amount = 0
                        paid_amount = 0
                        fraud_suspected = random.random() > 0.7
                        fraud_score = random.uniform(50, 100) if fraud_suspected else random.uniform(0, 50)
                    else:
                        approved_amount = None
                        paid_amount = None
                        fraud_suspected = random.random() > 0.9
                        fraud_score = random.uniform(0, 100)

                    claim = (
                        f"CLM{str(random.randint(1000000, 9999999))}",
                        policy['policy_id'],
                        policy['customer_id'],
                        claim_type,
                        self.faker.date_time_between('-1 year', 'now'),
                        self.faker.date_time_between('-1 year', 'now'),
                        self.faker.text(max_nb_chars=500),
                        claimed_amount,
                        approved_amount,
                        paid_amount,
                        500 if policy['product_type'] in ['auto', 'home'] else 0,  # deductible_applied
                        status,
                        random.choice(['low', 'medium', 'high', 'urgent']) if status not in ['paid', 'closed'] else 'low',
                        random.randint(1, 100) if status not in ['submitted'] else None,  # assigned_adjuster_id
                        fraud_suspected,
                        fraud_score,
                        random.choice([0, 1]) if fraud_suspected else 0,  # investigation_required
                        self.faker.date_time_between('-30 days', 'now') if status in ['approved', 'rejected'] else None,
                        None if status not in ['rejected', 'closed'] else random.choice([
                            'Not covered', 'Policy expired', 'Fraudulent claim',
                            'Insufficient documentation', 'Pre-existing condition'
                        ]),
                        self.faker.date_time_between('-30 days', 'now') if status == 'paid' else None,
                        self.faker.date_time_between('-1 year', 'now'),
                        self.faker.date_time_between('-1 year', 'now')
                    )
                    claims.append(claim)

        self.bulk_insert('claims', claims, [
            'claim_number', 'policy_id', 'customer_id', 'claim_type',
            'incident_date', 'reported_date', 'description', 'claimed_amount',
            'approved_amount', 'paid_amount', 'deductible_applied', 'status',
            'priority', 'assigned_adjuster_id', 'fraud_suspected', 'fraud_score',
            'investigation_required', 'decision_date', 'decision_reason',
            'payment_date', 'created_at', 'updated_at'
        ])

    def get_claim_type_for_product(self, product_type: str) -> str:
        """Get appropriate claim type for product type"""
        claim_type_map = {
            'life': ['death', 'disability'],
            'health': ['illness', 'medical', 'dental', 'vision'],
            'auto': ['accident', 'theft', 'property_damage', 'liability'],
            'home': ['property_damage', 'theft', 'natural_disaster', 'liability']
        }
        return random.choice(claim_type_map.get(product_type, ['other']))

    def generate_claim_activities(self):
        """Generate claim activity logs"""
        claims = self.fetch_all("SELECT claim_id, status FROM claims LIMIT 500")

        activities = []

        for claim in claims:
            # Generate 2-10 activities per claim
            num_activities = random.randint(2, 10)

            activity_types = ['status_change', 'document_received', 'investigation_update',
                            'adjuster_notes', 'payment_processed', 'customer_contact']

            for i in range(num_activities):
                activity = (
                    claim['claim_id'],
                    random.choice(activity_types),
                    self.faker.sentence(),
                    self.faker.text(max_nb_chars=300) if random.random() > 0.3 else None,
                    random.randint(1, 100),  # performed_by (user_id)
                    self.faker.date_time_between('-60 days', 'now')
                )
                activities.append(activity)

        self.bulk_insert('claim_activities', activities, [
            'claim_id', 'activity_type', 'activity_description',
            'notes', 'performed_by', 'created_at'
        ])

    def generate_payments(self):
        """Generate payment transactions"""
        # Get policies with billing schedules
        policies_with_billing = self.fetch_all("""
            SELECT p.policy_id, bs.billing_amount
            FROM policies p
            JOIN billing_schedules bs ON p.policy_id = bs.policy_id
            WHERE p.status IN ('active', 'expired')
            LIMIT 1000
        """)

        # Get paid claims
        paid_claims = self.fetch_all("""
            SELECT claim_id, paid_amount
            FROM claims
            WHERE status = 'paid'
            AND paid_amount > 0
        """)

        payments = []

        # Generate premium payments
        for policy in policies_with_billing:
            # Generate 1-12 payments per policy
            num_payments = random.randint(1, 12)

            for _ in range(num_payments):
                payment = (
                    policy['policy_id'],
                    None,  # claim_id
                    'premium',
                    float(policy['billing_amount']),
                    'USD',
                    random.choice(['credit_card', 'debit_card', 'bank_transfer', 'check']),
                    f"PAY{random.randint(100000, 999999)}",
                    'completed',
                    random.choice([0, 1]),  # reconciled
                    self.faker.date_time_between('-1 year', 'now'),
                    self.faker.date_time_between('-1 year', 'now')
                )
                payments.append(payment)

        # Generate claim payments
        for claim in paid_claims:
            payment = (
                None,  # policy_id
                claim['claim_id'],
                'claim_payout',
                float(claim['paid_amount']),
                'USD',
                'bank_transfer',
                f"CLM-PAY{random.randint(100000, 999999)}",
                'completed',
                1,  # reconciled
                self.faker.date_time_between('-60 days', 'now'),
                self.faker.date_time_between('-60 days', 'now')
            )
            payments.append(payment)

        self.bulk_insert('payments', payments, [
            'policy_id', 'claim_id', 'payment_type', 'amount', 'currency',
            'payment_method', 'transaction_id', 'status', 'reconciled',
            'processed_date', 'created_at'
        ])

    def generate_commissions(self):
        """Generate agent/broker commissions"""
        # Get policies with agents/brokers
        agent_policies = self.fetch_all("""
            SELECT policy_id, agent_id, premium_amount, commission_rate
            FROM policies
            WHERE agent_id IS NOT NULL
            AND status IN ('active', 'expired')
            LIMIT 500
        """)

        broker_policies = self.fetch_all("""
            SELECT policy_id, broker_id, premium_amount, commission_rate
            FROM policies
            WHERE broker_id IS NOT NULL
            AND status IN ('active', 'expired')
            LIMIT 200
        """)

        commissions = []

        # Generate agent commissions
        for policy in agent_policies:
            commission_amount = float(policy['premium_amount']) * float(policy['commission_rate'])

            commission = (
                policy['agent_id'],
                None,  # broker_id
                policy['policy_id'],
                'new_business' if random.random() > 0.3 else 'renewal',
                commission_amount,
                'USD',
                'pending' if random.random() > 0.7 else 'paid',
                self.faker.date_between('-1 year', 'today'),
                self.faker.date_between('-30 days', 'today') if random.random() > 0.5 else None,
                None,  # payment_reference
                self.faker.date_time_between('-1 year', 'now')
            )
            commissions.append(commission)

        # Generate broker commissions
        for policy in broker_policies:
            commission_amount = float(policy['premium_amount']) * 0.05  # Broker commission rate

            commission = (
                None,  # agent_id
                policy['broker_id'],
                policy['policy_id'],
                'referral',
                commission_amount,
                'USD',
                'pending' if random.random() > 0.6 else 'paid',
                self.faker.date_between('-1 year', 'today'),
                self.faker.date_between('-30 days', 'today') if random.random() > 0.5 else None,
                None,  # payment_reference
                self.faker.date_time_between('-1 year', 'now')
            )
            commissions.append(commission)

        self.bulk_insert('commissions', commissions, [
            'agent_id', 'broker_id', 'policy_id', 'commission_type',
            'commission_amount', 'currency', 'status', 'earning_date',
            'payment_date', 'payment_reference', 'created_at'
        ])

    def generate_reinsurance(self):
        """Generate reinsurance treaties and cessions"""
        # Generate reinsurance treaties
        treaties = []

        treaty_types = ['quota_share', 'surplus', 'excess_loss', 'stop_loss']

        for i in range(10):
            treaty = (
                f"TREATY-{str(i+1).zfill(4)}",
                random.choice(treaty_types),
                f"{self.faker.company()} Re",
                json.dumps(random.sample(self.product_types, random.randint(1, 3))),
                random.uniform(1000000, 100000000),  # coverage_limit
                random.uniform(100000, 5000000),  # retention_amount
                random.uniform(0.10, 0.50),  # cession_percentage
                random.uniform(0.01, 0.05),  # premium_rate
                'active',
                self.faker.date_between('-2 years', 'today'),
                self.faker.date_between('+1 year', '+5 years'),
                self.faker.date_time_between('-2 years', 'now')
            )
            treaties.append(treaty)

        self.bulk_insert('reinsurance_treaties', treaties, [
            'treaty_number', 'treaty_type', 'reinsurer_name', 'coverage_products',
            'coverage_limit', 'retention_amount', 'cession_percentage',
            'premium_rate', 'status', 'effective_date', 'expiry_date', 'created_at'
        ])

        # Generate reinsurance cessions
        high_value_policies = self.fetch_all("""
            SELECT policy_id, coverage_amount, premium_amount
            FROM policies
            WHERE coverage_amount > 500000
            AND status = 'active'
            LIMIT 100
        """)

        cessions = []

        for policy in high_value_policies:
            treaty_id = random.randint(1, 10)
            cession_percentage = random.uniform(0.20, 0.80)

            cession = (
                treaty_id,
                policy['policy_id'],
                float(policy['coverage_amount']) * cession_percentage,
                cession_percentage,
                float(policy['premium_amount']) * cession_percentage * 0.9,  # Reinsurance premium
                random.choice([0, 1]),  # is_active
                0,  # claims_ceded
                self.faker.date_time_between('-1 year', 'now')
            )
            cessions.append(cession)

        self.bulk_insert('reinsurance_cessions', cessions, [
            'treaty_id', 'policy_id', 'ceded_amount', 'cession_percentage',
            'reinsurance_premium', 'is_active', 'claims_ceded', 'created_at'
        ])

    def generate_documents(self):
        """Generate policy and claim documents"""
        policies = self.fetch_all("SELECT policy_id FROM policies LIMIT 500")
        claims = self.fetch_all("SELECT claim_id FROM claims LIMIT 200")

        documents = []

        # Policy documents
        for policy in policies:
            # Generate 1-3 documents per policy
            num_docs = random.randint(1, 3)

            for _ in range(num_docs):
                doc = (
                    'policy',
                    policy['policy_id'],
                    random.choice(['policy_document', 'application', 'id_proof', 'medical_report', 'other']),
                    f"policy_{policy['policy_id']}_{random.randint(1000, 9999)}.pdf",
                    f"https://docs.insurance.com/policies/{policy['policy_id']}/doc.pdf",
                    random.choice([0, 1]),  # is_verified
                    self.faker.date_time_between('-1 year', 'now') if random.random() > 0.3 else None,
                    'active',
                    self.faker.date_time_between('-2 years', 'now')
                )
                documents.append(doc)

        # Claim documents
        for claim in claims:
            # Generate 2-5 documents per claim
            num_docs = random.randint(2, 5)

            for _ in range(num_docs):
                doc = (
                    'claim',
                    claim['claim_id'],
                    random.choice(['claim_form', 'police_report', 'medical_bill', 'repair_estimate', 'photos', 'other']),
                    f"claim_{claim['claim_id']}_{random.randint(1000, 9999)}.pdf",
                    f"https://docs.insurance.com/claims/{claim['claim_id']}/doc.pdf",
                    random.choice([0, 1]),  # is_verified
                    self.faker.date_time_between('-60 days', 'now') if random.random() > 0.3 else None,
                    'active',
                    self.faker.date_time_between('-1 year', 'now')
                )
                documents.append(doc)

        self.bulk_insert('documents', documents, [
            'reference_type', 'reference_id', 'document_type', 'document_name',
            'document_url', 'is_verified', 'verified_date', 'status', 'created_at'
        ])

    def generate_communications(self):
        """Generate customer communications"""
        customers = self.fetch_all("SELECT customer_id FROM customers LIMIT 500")

        communications = []

        comm_types = ['email', 'sms', 'phone', 'letter', 'in_app']
        subjects = [
            'Policy Renewal Reminder', 'Premium Due Notice', 'Claim Update',
            'Welcome to Insurance', 'Policy Changes', 'Important Information'
        ]

        for _ in range(1000):
            customer = random.choice(customers)

            communication = (
                'customer',
                customer['customer_id'],
                random.choice(comm_types),
                random.choice(['inbound', 'outbound']),
                random.choice(subjects),
                self.faker.text(max_nb_chars=500),
                f"TPL-{random.randint(1, 100)}",  # template_id
                random.choice(['sent', 'delivered', 'failed', 'pending']),
                self.faker.date_time_between('-90 days', 'now')
            )
            communications.append(communication)

        self.bulk_insert('communications', communications, [
            'reference_type', 'reference_id', 'channel', 'direction',
            'subject', 'content', 'template_id', 'status', 'created_at'
        ])

    def generate_regulatory_reports(self):
        """Generate regulatory compliance reports"""
        reports = []

        report_types = ['annual_statement', 'quarterly_filing', 'risk_assessment',
                       'solvency_report', 'market_conduct', 'financial_audit']

        jurisdictions = ['Federal', 'CA', 'NY', 'TX', 'FL', 'IL']

        for _ in range(50):
            report = (
                random.choice(report_types),
                random.choice(jurisdictions),
                self.faker.date_between('-1 year', 'today'),
                self.faker.date_between('-1 year', '+30 days'),
                random.choice(['draft', 'review', 'submitted', 'accepted', 'rejected']),
                self.faker.date_between('-30 days', '+60 days'),
                self.faker.date_time_between('-30 days', 'now') if random.random() > 0.5 else None,
                f"https://reports.insurance.com/regulatory/{random.randint(1000, 9999)}.pdf",
                self.faker.date_time_between('-1 year', 'now')
            )
            reports.append(report)

        self.bulk_insert('regulatory_reports', reports, [
            'report_type', 'jurisdiction', 'report_period_start',
            'report_period_end', 'status', 'filing_deadline',
            'submitted_date', 'report_url', 'created_at'
        ])


def main():
    """Main function to run the generator"""
    import argparse

    parser = argparse.ArgumentParser(description='Generate test data for Insurance Management Platform')
    parser.add_argument('--host', default='localhost', help='MySQL host')
    parser.add_argument('--port', type=int, default=3339, help='MySQL port')
    parser.add_argument('--user', default='insurance_admin', help='MySQL user')
    parser.add_argument('--password', default='insurance_pass_2024', help='MySQL password')
    parser.add_argument('--database', default='insurance_platform', help='MySQL database')
    parser.add_argument('--customers', type=int, default=10000, help='Number of customers')
    parser.add_argument('--agents', type=int, default=500, help='Number of agents')
    parser.add_argument('--policies-per-customer', type=float, default=1.5, help='Average policies per customer')

    args = parser.parse_args()

    generator = InsuranceGenerator(
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
            agents=args.agents,
            policies_per_customer=args.policies_per_customer
        )
    finally:
        generator.disconnect()


if __name__ == '__main__':
    main()