#!/usr/bin/env python3
"""
FinTech Platform Data Generator
Generates realistic data for a financial technology platform with double-entry accounting,
KYC/AML compliance, fraud detection, and complete transaction processing
"""

import csv
import json
import random
import hashlib
import uuid
from datetime import datetime, timedelta, date
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path
from faker import Faker
import numpy as np

# Configuration
SEED = 42
OUTPUT_DIR = Path("output")
fake = Faker()
Faker.seed(SEED)
random.seed(SEED)
np.random.seed(SEED)

# Scale configuration
CONFIG = {
    "customers": 500,
    "individual_ratio": 0.8,  # 80% individual, 20% business
    "accounts_per_customer": (1, 4),
    "transactions_per_day": 100,
    "days_of_history": 30,
    "fraud_rate": 0.02,  # 2% of transactions flagged
    "loan_applications": 50,
    "kyc_documents_per_customer": 2,
}

class FinTechGenerator:
    def __init__(self):
        # Customer entities
        self.customers = []
        self.individual_customers = []
        self.business_customers = []
        self.kyc_documents = []
        self.customer_addresses = []

        # Account entities
        self.accounts = []
        self.account_holders = []

        # Accounting entities
        self.chart_of_accounts = []
        self.journal_entries = []
        self.journal_lines = []

        # Transaction entities
        self.transactions = []
        self.transfers = []
        self.payment_methods = []
        self.cards = []

        # Currency and exchange
        self.currencies = []
        self.exchange_rates = []

        # Risk and compliance
        self.risk_rules = []
        self.fraud_alerts = []
        self.device_fingerprints = []
        self.aml_checks = []
        self.sar_reports = []

        # Loans
        self.loan_applications = []
        self.loan_accounts = []

        # Other entities
        self.audit_logs = []
        self.fee_schedule = []
        self.notification_preferences = []

        # Counters
        self.customer_id = 0
        self.address_id = 0
        self.kyc_id = 0
        self.account_id = 0
        self.holder_id = 0
        self.journal_id = 0
        self.line_id = 0
        self.transaction_id = 0
        self.transfer_id = 0
        self.payment_method_id = 0
        self.card_id = 0
        self.rate_id = 0
        self.rule_id = 0
        self.alert_id = 0
        self.device_id = 0
        self.aml_id = 0
        self.sar_id = 0
        self.loan_app_id = 0
        self.loan_account_id = 0
        self.audit_id = 0
        self.fee_id = 0
        self.notification_id = 0

        # Start date for historical data
        self.start_date = datetime.now() - timedelta(days=CONFIG['days_of_history'])

        # Running balances for double-entry accounting
        self.gl_balances = {}

    def generate_all(self):
        """Generate all fintech data"""
        print("Starting FinTech Platform Data Generation...")
        print(f"Configuration:")
        print(f"  Customers: {CONFIG['customers']}")
        print(f"  Individual/Business ratio: {CONFIG['individual_ratio']:.0%}/{1-CONFIG['individual_ratio']:.0%}")
        print(f"  Transactions per day: {CONFIG['transactions_per_day']}")
        print(f"  Days of history: {CONFIG['days_of_history']}")

        # Setup foundation
        self.setup_chart_of_accounts()
        self.setup_currencies()
        self.setup_risk_rules()
        self.setup_fee_schedule()

        # Generate customers and accounts
        self.generate_customers()
        self.generate_customer_addresses()
        self.generate_kyc_documents()
        self.generate_accounts()
        self.generate_payment_methods()
        self.generate_cards()

        # Generate transactions and accounting
        self.generate_daily_transactions()
        self.generate_transfers()
        self.generate_exchange_rates()

        # Generate loans
        self.generate_loan_applications()
        self.generate_loan_accounts()

        # Generate compliance and monitoring
        self.generate_aml_checks()
        self.generate_fraud_alerts()
        self.generate_device_fingerprints()
        self.generate_sar_reports()

        # Generate preferences and audit
        self.generate_notification_preferences()
        self.generate_audit_logs()

        # Save all data
        self.save_all()

    def setup_chart_of_accounts(self):
        """Setup standard chart of accounts for double-entry bookkeeping"""
        print("Setting up chart of accounts...")

        # Standard accounts following accounting principles
        accounts = [
            # Assets (1000-1999)
            ('1000', 'Cash and Cash Equivalents', 'asset', None, True, 'debit'),
            ('1010', 'Customer Deposits', 'asset', '1000', False, 'debit'),
            ('1020', 'Reserve Funds', 'asset', '1000', False, 'debit'),
            ('1100', 'Loans Receivable', 'asset', None, True, 'debit'),
            ('1110', 'Personal Loans', 'asset', '1100', False, 'debit'),
            ('1120', 'Business Loans', 'asset', '1100', False, 'debit'),
            ('1200', 'Investments', 'asset', None, True, 'debit'),
            ('1300', 'Fixed Assets', 'asset', None, True, 'debit'),
            ('1400', 'Intangible Assets', 'asset', None, True, 'debit'),
            ('1500', 'Other Assets', 'asset', None, True, 'debit'),

            # Liabilities (2000-2999)
            ('2000', 'Customer Accounts Payable', 'liability', None, True, 'credit'),
            ('2010', 'Checking Accounts', 'liability', '2000', False, 'credit'),
            ('2020', 'Savings Accounts', 'liability', '2000', False, 'credit'),
            ('2100', 'Loans Payable', 'liability', None, True, 'credit'),
            ('2200', 'Accrued Expenses', 'liability', None, True, 'credit'),
            ('2210', 'Accrued Interest Payable', 'liability', '2200', False, 'credit'),
            ('2300', 'Deferred Revenue', 'liability', None, True, 'credit'),
            ('2400', 'Other Liabilities', 'liability', None, True, 'credit'),

            # Equity (3000-3999)
            ('3000', 'Share Capital', 'equity', None, True, 'credit'),
            ('3100', 'Retained Earnings', 'equity', None, True, 'credit'),
            ('3200', 'Current Year Earnings', 'equity', None, True, 'credit'),

            # Revenue (4000-4999)
            ('4000', 'Interest Income', 'revenue', None, True, 'credit'),
            ('4010', 'Loan Interest Income', 'revenue', '4000', False, 'credit'),
            ('4020', 'Investment Income', 'revenue', '4000', False, 'credit'),
            ('4100', 'Fee Income', 'revenue', None, True, 'credit'),
            ('4110', 'Transaction Fees', 'revenue', '4100', False, 'credit'),
            ('4120', 'Account Maintenance Fees', 'revenue', '4100', False, 'credit'),
            ('4130', 'Overdraft Fees', 'revenue', '4100', False, 'credit'),
            ('4200', 'Foreign Exchange Gains', 'revenue', None, True, 'credit'),
            ('4300', 'Other Revenue', 'revenue', None, True, 'credit'),

            # Expenses (5000-5999)
            ('5000', 'Interest Expense', 'expense', None, True, 'debit'),
            ('5010', 'Deposit Interest Expense', 'expense', '5000', False, 'debit'),
            ('5100', 'Operating Expenses', 'expense', None, True, 'debit'),
            ('5110', 'Salaries and Wages', 'expense', '5100', False, 'debit'),
            ('5120', 'Technology Costs', 'expense', '5100', False, 'debit'),
            ('5130', 'Compliance Costs', 'expense', '5100', False, 'debit'),
            ('5200', 'Credit Loss Provision', 'expense', None, True, 'debit'),
            ('5300', 'Foreign Exchange Losses', 'expense', None, True, 'debit'),
            ('5400', 'Other Expenses', 'expense', None, True, 'debit'),
        ]

        for account_code, name, acc_type, parent, is_control, normal_balance in accounts:
            self.chart_of_accounts.append({
                'account_code': account_code,
                'account_name': name,
                'account_type': acc_type,
                'parent_account_code': parent,
                'is_control_account': is_control,
                'normal_balance': normal_balance,
                'description': f"Standard {acc_type} account for {name.lower()}",
                'is_active': True,
                'created_at': datetime.now()
            })
            # Initialize balance
            self.gl_balances[account_code] = Decimal('0')

    def setup_currencies(self):
        """Setup supported currencies"""
        print("Setting up currencies...")

        currencies_data = [
            ('USD', 'US Dollar', '$', 2),
            ('EUR', 'Euro', '€', 2),
            ('GBP', 'British Pound', '£', 2),
            ('JPY', 'Japanese Yen', '¥', 0),
            ('CAD', 'Canadian Dollar', 'C$', 2),
            ('AUD', 'Australian Dollar', 'A$', 2),
            ('CHF', 'Swiss Franc', 'CHF', 2),
            ('CNY', 'Chinese Yuan', '¥', 2),
        ]

        for code, name, symbol, decimals in currencies_data:
            self.currencies.append({
                'currency_code': code,
                'currency_name': name,
                'symbol': symbol,
                'decimal_places': decimals,
                'is_active': True,
                'created_at': datetime.now()
            })

    def setup_risk_rules(self):
        """Setup fraud detection and risk rules"""
        print("Setting up risk rules...")

        rules = [
            ('HIGH_AMOUNT', 'Transaction amount > $10,000', 'amount > 10000', 'high', True),
            ('RAPID_TRANSACTIONS', 'More than 5 transactions in 1 hour', 'count > 5', 'medium', True),
            ('NEW_DEVICE', 'Transaction from unrecognized device', 'device_new = true', 'medium', True),
            ('INTERNATIONAL', 'International transaction', 'country != home_country', 'low', True),
            ('UNUSUAL_TIME', 'Transaction at unusual hour', 'hour < 5 or hour > 23', 'low', True),
            ('VELOCITY_CHECK', 'High velocity spending', 'daily_total > 5000', 'high', True),
            ('MERCHANT_RISK', 'High-risk merchant category', 'mcc in (7995, 5999)', 'medium', True),
            ('GEO_IMPOSSIBLE', 'Geographic impossibility', 'distance/time > 500', 'critical', True),
        ]

        for rule_id, (code, desc, condition, risk_level, is_active) in enumerate(rules, 1):
            self.risk_rules.append({
                'rule_id': rule_id,
                'rule_code': code,
                'rule_description': desc,
                'rule_condition': condition,
                'risk_level': risk_level,
                'action': 'review' if risk_level in ['low', 'medium'] else 'block',
                'is_active': is_active,
                'created_at': datetime.now()
            })

    def setup_fee_schedule(self):
        """Setup fee schedule"""
        print("Setting up fee schedule...")

        fees = [
            ('MONTHLY_MAINTENANCE', 'checking', 12.00, 'monthly', 'Account maintenance'),
            ('OVERDRAFT', 'checking', 35.00, 'per_occurrence', 'Overdraft fee'),
            ('WIRE_DOMESTIC', 'all', 25.00, 'per_transaction', 'Domestic wire transfer'),
            ('WIRE_INTERNATIONAL', 'all', 45.00, 'per_transaction', 'International wire transfer'),
            ('ATM_OUT_NETWORK', 'all', 3.00, 'per_transaction', 'Out-of-network ATM'),
            ('PAPER_STATEMENT', 'all', 5.00, 'monthly', 'Paper statement fee'),
            ('EARLY_CLOSURE', 'all', 25.00, 'one_time', 'Account early closure'),
            ('CARD_REPLACEMENT', 'all', 15.00, 'per_occurrence', 'Card replacement'),
        ]

        for fee_id, (code, acc_type, amount, frequency, desc) in enumerate(fees, 1):
            self.fee_schedule.append({
                'fee_id': fee_id,
                'fee_code': code,
                'account_type': acc_type,
                'fee_amount': amount,
                'currency': 'USD',
                'fee_frequency': frequency,
                'description': desc,
                'is_active': True,
                'created_at': datetime.now()
            })

    def generate_customers(self):
        """Generate customer data"""
        print(f"Generating {CONFIG['customers']} customers...")

        num_individual = int(CONFIG['customers'] * CONFIG['individual_ratio'])
        num_business = CONFIG['customers'] - num_individual

        # Generate individual customers
        for _ in range(num_individual):
            self.customer_id += 1

            registration_date = fake.date_between(start_date='-2y', end_date='today')
            risk_score = random.randint(300, 850)  # Similar to credit score

            customer = {
                'customer_id': self.customer_id,
                'customer_type': 'individual',
                'email': fake.email(),
                'phone_number': fake.phone_number()[:20],
                'status': random.choices(['active', 'inactive', 'suspended'],
                                        weights=[0.9, 0.08, 0.02])[0],
                'risk_score': risk_score,
                'risk_category': 'low' if risk_score > 700 else 'medium' if risk_score > 500 else 'high',
                'kyc_status': random.choices(['verified', 'pending', 'failed'],
                                           weights=[0.85, 0.1, 0.05])[0],
                'kyc_date': registration_date + timedelta(days=random.randint(0, 7)),
                'aml_status': 'cleared',
                'registration_date': registration_date,
                'last_login_date': fake.date_time_between(start_date='-7d', end_date='now'),
                'preferred_language': random.choice(['en', 'es', 'fr', 'de']),
                'created_at': registration_date
            }
            self.customers.append(customer)

            # Generate individual customer details
            birth_date = fake.date_of_birth(minimum_age=18, maximum_age=80)

            self.individual_customers.append({
                'customer_id': self.customer_id,
                'first_name': fake.first_name(),
                'last_name': fake.last_name(),
                'middle_name': fake.first_name() if random.random() < 0.3 else None,
                'date_of_birth': birth_date,
                'ssn_hash': hashlib.sha256(f"SSN{self.customer_id}".encode()).hexdigest(),
                'gender': random.choice(['M', 'F', 'Other']),
                'marital_status': random.choice(['single', 'married', 'divorced', 'widowed']),
                'nationality': 'USA',
                'occupation': fake.job()[:100],
                'annual_income': random.randint(20000, 250000),
                'employer_name': fake.company() if random.random() > 0.2 else None,
                'created_at': registration_date
            })

        # Generate business customers
        for _ in range(num_business):
            self.customer_id += 1

            registration_date = fake.date_between(start_date='-2y', end_date='today')
            risk_score = random.randint(400, 900)

            customer = {
                'customer_id': self.customer_id,
                'customer_type': 'business',
                'email': fake.company_email(),
                'phone_number': fake.phone_number()[:20],
                'status': random.choices(['active', 'inactive', 'suspended'],
                                        weights=[0.9, 0.08, 0.02])[0],
                'risk_score': risk_score,
                'risk_category': 'low' if risk_score > 700 else 'medium' if risk_score > 500 else 'high',
                'kyc_status': random.choices(['verified', 'pending', 'failed'],
                                           weights=[0.85, 0.1, 0.05])[0],
                'kyc_date': registration_date + timedelta(days=random.randint(0, 14)),
                'aml_status': 'cleared',
                'registration_date': registration_date,
                'last_login_date': fake.date_time_between(start_date='-7d', end_date='now'),
                'preferred_language': 'en',
                'created_at': registration_date
            }
            self.customers.append(customer)

            # Generate business customer details
            self.business_customers.append({
                'customer_id': self.customer_id,
                'business_name': fake.company(),
                'legal_name': fake.company() + ' LLC',
                'business_type': random.choice(['LLC', 'Corporation', 'Partnership', 'Sole Proprietorship']),
                'ein_hash': hashlib.sha256(f"EIN{self.customer_id}".encode()).hexdigest(),
                'incorporation_date': fake.date_between(start_date='-20y', end_date='-1y'),
                'incorporation_state': fake.state_abbr(),
                'industry': random.choice(['Technology', 'Retail', 'Healthcare', 'Finance', 'Manufacturing']),
                'annual_revenue': random.randint(100000, 10000000),
                'number_of_employees': random.randint(1, 500),
                'website': f"https://www.{fake.domain_name()}",
                'created_at': registration_date
            })

    def generate_customer_addresses(self):
        """Generate customer addresses"""
        print("Generating customer addresses...")

        for customer in self.customers:
            # Primary address
            self.address_id += 1
            self.customer_addresses.append({
                'address_id': self.address_id,
                'customer_id': customer['customer_id'],
                'address_type': 'primary',
                'street_address': fake.street_address(),
                'street_address2': fake.secondary_address() if random.random() < 0.2 else None,
                'city': fake.city(),
                'state': fake.state_abbr(),
                'postal_code': fake.zipcode(),
                'country': 'USA',
                'is_verified': random.random() > 0.1,
                'created_at': customer['created_at']
            })

            # Some customers have mailing address
            if random.random() < 0.15:
                self.address_id += 1
                self.customer_addresses.append({
                    'address_id': self.address_id,
                    'customer_id': customer['customer_id'],
                    'address_type': 'mailing',
                    'street_address': fake.street_address(),
                    'street_address2': None,
                    'city': fake.city(),
                    'state': fake.state_abbr(),
                    'postal_code': fake.zipcode(),
                    'country': 'USA',
                    'is_verified': True,
                    'created_at': customer['created_at']
                })

    def generate_kyc_documents(self):
        """Generate KYC documents"""
        print("Generating KYC documents...")

        doc_types = ['passport', 'drivers_license', 'state_id', 'utility_bill', 'bank_statement']

        for customer in self.customers:
            if customer['kyc_status'] == 'verified':
                num_docs = CONFIG['kyc_documents_per_customer']

                for _ in range(num_docs):
                    self.kyc_id += 1

                    doc_type = random.choice(doc_types[:3] if customer['customer_type'] == 'individual' else doc_types[3:])

                    self.kyc_documents.append({
                        'document_id': self.kyc_id,
                        'customer_id': customer['customer_id'],
                        'document_type': doc_type,
                        'document_number': f"DOC{self.kyc_id:08d}",
                        'issue_date': fake.date_between(start_date='-5y', end_date='-1y'),
                        'expiry_date': fake.date_between(start_date='+1y', end_date='+5y'),
                        'issuing_country': 'USA',
                        'issuing_state': fake.state_abbr() if doc_type in ['drivers_license', 'state_id'] else None,
                        'verification_status': 'verified',
                        'verification_date': customer['kyc_date'],
                        'file_hash': hashlib.sha256(f"FILE{self.kyc_id}".encode()).hexdigest(),
                        'created_at': customer['kyc_date']
                    })

    def generate_accounts(self):
        """Generate customer accounts"""
        print("Generating accounts...")

        for customer in self.customers:
            num_accounts = random.randint(*CONFIG['accounts_per_customer'])

            account_types = ['checking', 'savings'] if customer['customer_type'] == 'individual' else ['checking']
            if random.random() < 0.2:
                account_types.append('investment')

            for i in range(min(num_accounts, len(account_types))):
                self.account_id += 1

                account_type = account_types[i]
                opened_date = customer['registration_date'] + timedelta(days=random.randint(0, 30))

                # Generate initial balance
                if account_type == 'checking':
                    balance = Decimal(str(random.uniform(100, 10000)))
                elif account_type == 'savings':
                    balance = Decimal(str(random.uniform(500, 50000)))
                else:  # investment
                    balance = Decimal(str(random.uniform(1000, 100000)))

                balance = balance.quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)

                account = {
                    'account_id': self.account_id,
                    'account_number': f"ACC{self.account_id:010d}",
                    'account_type': account_type,
                    'currency': 'USD',
                    'status': 'active' if customer['status'] == 'active' else 'frozen',
                    'balance': balance,
                    'available_balance': balance * Decimal('0.95'),  # 5% held
                    'pending_balance': Decimal('0'),
                    'interest_rate': Decimal('0.0001') if account_type == 'savings' else Decimal('0'),
                    'overdraft_limit': Decimal('500') if account_type == 'checking' else Decimal('0'),
                    'minimum_balance': Decimal('100') if account_type == 'checking' else Decimal('500'),
                    'opened_date': opened_date,
                    'closed_date': None,
                    'last_transaction_date': None,
                    'last_interest_date': opened_date.replace(day=1) if account_type == 'savings' else None,
                    'created_at': opened_date,
                    'version': 0
                }
                self.accounts.append(account)

                # Create account holder relationship
                self.holder_id += 1
                self.account_holders.append({
                    'account_holder_id': self.holder_id,
                    'account_id': self.account_id,
                    'customer_id': customer['customer_id'],
                    'relationship_type': 'primary',
                    'ownership_percentage': Decimal('100.00'),
                    'added_date': opened_date,
                    'removed_date': None
                })

                # Create opening journal entry (double-entry)
                self.create_journal_entry(
                    opened_date,
                    f"Account opening - {account['account_number']}",
                    'account_opening',
                    self.account_id,
                    [
                        ('1010', balance, Decimal('0')),  # Debit: Customer Deposits (Asset)
                        ('2010' if account_type == 'checking' else '2020', Decimal('0'), balance)  # Credit: Customer Account
                    ]
                )

    def generate_payment_methods(self):
        """Generate payment methods"""
        print("Generating payment methods...")

        for customer in self.customers:
            # Bank accounts as payment methods
            customer_accounts = [a for a in self.accounts
                               if any(h['customer_id'] == customer['customer_id']
                                    for h in self.account_holders
                                    if h['account_id'] == a['account_id'])]

            for account in customer_accounts:
                if account['account_type'] == 'checking':
                    self.payment_method_id += 1

                    self.payment_methods.append({
                        'payment_method_id': self.payment_method_id,
                        'customer_id': customer['customer_id'],
                        'method_type': 'bank_account',
                        'is_default': True,
                        'account_id': account['account_id'],
                        'card_id': None,
                        'bank_name': fake.company() + ' Bank',
                        'account_last_four': account['account_number'][-4:],
                        'routing_number': f"{random.randint(100000000, 999999999)}",
                        'is_verified': True,
                        'created_at': account['created_at']
                    })

    def generate_cards(self):
        """Generate payment cards"""
        print("Generating payment cards...")

        card_brands = ['Visa', 'Mastercard', 'Amex', 'Discover']

        for account in self.accounts:
            if account['account_type'] in ['checking', 'credit_card'] and account['status'] == 'active':
                self.card_id += 1

                issue_date = account['opened_date']
                expiry_date = issue_date + timedelta(days=365*3)  # 3 years

                card = {
                    'card_id': self.card_id,
                    'account_id': account['account_id'],
                    'card_number_hash': hashlib.sha256(f"CARD{self.card_id}".encode()).hexdigest(),
                    'card_last_four': f"{random.randint(1000, 9999)}",
                    'card_brand': random.choice(card_brands),
                    'card_type': 'debit' if account['account_type'] == 'checking' else 'credit',
                    'cardholder_name': fake.name(),
                    'issue_date': issue_date,
                    'expiry_date': expiry_date,
                    'cvv_hash': hashlib.sha256(f"CVV{self.card_id}".encode()).hexdigest(),
                    'pin_hash': hashlib.sha256(f"PIN{self.card_id}".encode()).hexdigest(),
                    'status': 'active',
                    'activation_date': issue_date + timedelta(days=random.randint(1, 7)),
                    'daily_limit': Decimal('2500.00'),
                    'monthly_limit': Decimal('10000.00'),
                    'created_at': issue_date
                }
                self.cards.append(card)

    def generate_daily_transactions(self):
        """Generate daily transactions with proper double-entry accounting"""
        print("Generating transactions and journal entries...")

        transaction_types = ['deposit', 'withdrawal', 'payment', 'fee', 'interest']

        current_date = self.start_date.date()
        end_date = datetime.now().date()

        while current_date <= end_date:
            daily_transactions = random.randint(min(50, CONFIG['transactions_per_day']), max(50, CONFIG['transactions_per_day']))

            for _ in range(daily_transactions):
                # Select random active account
                active_accounts = [a for a in self.accounts if a['status'] == 'active']
                if not active_accounts:
                    continue

                account = random.choice(active_accounts)
                self.transaction_id += 1

                trans_type = random.choice(transaction_types)
                trans_time = datetime.combine(current_date,
                                            datetime.min.time().replace(
                                                hour=random.randint(6, 22),
                                                minute=random.randint(0, 59)))

                # Generate transaction amount based on type
                if trans_type == 'deposit':
                    amount = Decimal(str(random.uniform(100, 5000)))
                    account['balance'] += amount
                elif trans_type == 'withdrawal':
                    amount = Decimal(str(random.uniform(20, 500)))
                    amount = min(amount, account['balance'])  # Can't withdraw more than balance
                    account['balance'] -= amount
                elif trans_type == 'payment':
                    amount = Decimal(str(random.uniform(10, 1000)))
                    amount = min(amount, account['balance'])
                    account['balance'] -= amount
                elif trans_type == 'fee':
                    amount = Decimal('12.00')  # Monthly fee
                    account['balance'] -= amount
                else:  # interest
                    amount = account['balance'] * account['interest_rate']

                amount = amount.quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)

                transaction = {
                    'transaction_id': self.transaction_id,
                    'account_id': account['account_id'],
                    'transaction_type': trans_type,
                    'transaction_date': trans_time,
                    'amount': amount,
                    'currency': account['currency'],
                    'balance_after': account['balance'],
                    'description': f"{trans_type.capitalize()} - {fake.company() if trans_type == 'payment' else 'Cash'}",
                    'reference_number': f"TXN{self.transaction_id:012d}",
                    'merchant_name': fake.company() if trans_type == 'payment' else None,
                    'merchant_category': random.choice(['5411', '5812', '5999']) if trans_type == 'payment' else None,
                    'channel': random.choice(['online', 'atm', 'branch', 'mobile']),
                    'status': 'completed',
                    'posted_date': trans_time + timedelta(hours=random.randint(1, 24)),
                    'created_at': trans_time
                }
                self.transactions.append(transaction)

                # Create journal entries for double-entry bookkeeping
                if trans_type == 'deposit':
                    entries = [
                        ('1010', amount, Decimal('0')),  # Debit: Customer Deposits
                        ('2010' if account['account_type'] == 'checking' else '2020', Decimal('0'), amount)  # Credit: Customer Account
                    ]
                elif trans_type == 'withdrawal':
                    entries = [
                        ('2010' if account['account_type'] == 'checking' else '2020', amount, Decimal('0')),  # Debit: Customer Account
                        ('1010', Decimal('0'), amount)  # Credit: Customer Deposits
                    ]
                elif trans_type == 'payment':
                    entries = [
                        ('2010' if account['account_type'] == 'checking' else '2020', amount, Decimal('0')),  # Debit: Customer Account
                        ('1010', Decimal('0'), amount)  # Credit: Customer Deposits
                    ]
                elif trans_type == 'fee':
                    entries = [
                        ('2010', amount, Decimal('0')),  # Debit: Customer Account
                        ('4120', Decimal('0'), amount)  # Credit: Account Maintenance Fees
                    ]
                else:  # interest
                    if account['account_type'] == 'savings':
                        entries = [
                            ('5010', amount, Decimal('0')),  # Debit: Deposit Interest Expense
                            ('2020', Decimal('0'), amount)  # Credit: Savings Account
                        ]

                self.create_journal_entry(
                    trans_time,
                    transaction['description'],
                    'transaction',
                    self.transaction_id,
                    entries
                )

                # Update last transaction date
                account['last_transaction_date'] = trans_time

            current_date += timedelta(days=1)

    def generate_transfers(self):
        """Generate account transfers"""
        print("Generating transfers...")

        for _ in range(100):  # Generate 100 transfers
            # Get two different accounts from same customer
            customers_with_multiple = []
            for customer in self.customers:
                customer_accounts = [a for a in self.accounts
                                   if any(h['customer_id'] == customer['customer_id']
                                        for h in self.account_holders
                                        if h['account_id'] == a['account_id'])]
                if len(customer_accounts) >= 2:
                    customers_with_multiple.append((customer, customer_accounts))

            if not customers_with_multiple:
                continue

            customer, accounts = random.choice(customers_with_multiple)
            from_account, to_account = random.sample(accounts, 2)

            self.transfer_id += 1

            amount = Decimal(str(random.uniform(50, 1000)))
            amount = min(amount, from_account['balance'])
            amount = amount.quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)

            transfer_time = fake.date_time_between(start_date=self.start_date, end_date='now')

            self.transfers.append({
                'transfer_id': self.transfer_id,
                'from_account_id': from_account['account_id'],
                'to_account_id': to_account['account_id'],
                'amount': amount,
                'currency': 'USD',
                'transfer_date': transfer_time,
                'description': f"Transfer between accounts",
                'status': 'completed',
                'created_at': transfer_time
            })

            # Create journal entries
            entries = [
                ('2010' if from_account['account_type'] == 'checking' else '2020', amount, Decimal('0')),  # Debit from account
                ('2010' if to_account['account_type'] == 'checking' else '2020', Decimal('0'), amount)  # Credit to account
            ]

            self.create_journal_entry(
                transfer_time,
                f"Transfer from {from_account['account_number']} to {to_account['account_number']}",
                'transfer',
                self.transfer_id,
                entries
            )

    def generate_exchange_rates(self):
        """Generate exchange rates"""
        print("Generating exchange rates...")

        base_rates = {
            'EUR': 0.85,
            'GBP': 0.73,
            'JPY': 110.0,
            'CAD': 1.25,
            'AUD': 1.35,
            'CHF': 0.92,
            'CNY': 6.45
        }

        current_date = self.start_date.date()
        end_date = datetime.now().date()

        while current_date <= end_date:
            for currency, base_rate in base_rates.items():
                self.rate_id += 1

                # Add some daily variation
                rate = base_rate * random.uniform(0.98, 1.02)

                self.exchange_rates.append({
                    'rate_id': self.rate_id,
                    'from_currency': 'USD',
                    'to_currency': currency,
                    'rate_date': current_date,
                    'exchange_rate': round(Decimal(str(rate)), 6),
                    'rate_type': 'spot',
                    'created_at': datetime.combine(current_date, datetime.min.time())
                })

            current_date += timedelta(days=1)

    def generate_loan_applications(self):
        """Generate loan applications"""
        print("Generating loan applications...")

        loan_purposes = ['personal', 'auto', 'home_improvement', 'debt_consolidation', 'business']

        for _ in range(CONFIG['loan_applications']):
            customer = random.choice(self.customers)

            self.loan_app_id += 1

            application_date = fake.date_between(start_date=self.start_date, end_date='today')

            # Determine approval based on risk score
            risk_score = customer['risk_score']
            if risk_score > 700:
                status = random.choices(['approved', 'pending', 'rejected'], weights=[0.8, 0.15, 0.05])[0]
            elif risk_score > 500:
                status = random.choices(['approved', 'pending', 'rejected'], weights=[0.5, 0.3, 0.2])[0]
            else:
                status = random.choices(['approved', 'pending', 'rejected'], weights=[0.2, 0.3, 0.5])[0]

            self.loan_applications.append({
                'application_id': self.loan_app_id,
                'customer_id': customer['customer_id'],
                'loan_type': random.choice(['personal', 'auto', 'business']),
                'requested_amount': Decimal(str(random.randint(5000, 100000))),
                'loan_purpose': random.choice(loan_purposes),
                'loan_term_months': random.choice([12, 24, 36, 48, 60]),
                'interest_rate': Decimal(str(random.uniform(3.5, 15.0))).quantize(Decimal('0.01')),
                'application_date': application_date,
                'credit_score': risk_score,
                'annual_income': Decimal(str(random.randint(30000, 200000))),
                'employment_status': random.choice(['employed', 'self_employed', 'retired']),
                'status': status,
                'decision_date': application_date + timedelta(days=random.randint(1, 7)) if status != 'pending' else None,
                'rejection_reason': 'Low credit score' if status == 'rejected' and risk_score < 600 else None,
                'created_at': application_date
            })

    def generate_loan_accounts(self):
        """Generate loan accounts for approved applications"""
        print("Generating loan accounts...")

        approved_apps = [app for app in self.loan_applications if app['status'] == 'approved']

        for app in approved_apps:
            self.loan_account_id += 1

            disbursement_date = app['decision_date'] + timedelta(days=random.randint(1, 3))

            self.loan_accounts.append({
                'loan_account_id': self.loan_account_id,
                'application_id': app['application_id'],
                'account_number': f"LOAN{self.loan_account_id:08d}",
                'principal_amount': app['requested_amount'],
                'interest_rate': app['interest_rate'],
                'term_months': app['loan_term_months'],
                'monthly_payment': self.calculate_monthly_payment(
                    app['requested_amount'],
                    app['interest_rate'] / 12 / 100,
                    app['loan_term_months']
                ),
                'disbursement_date': disbursement_date,
                'first_payment_date': disbursement_date.replace(day=1) + timedelta(days=32),
                'maturity_date': disbursement_date + timedelta(days=30 * app['loan_term_months']),
                'outstanding_balance': app['requested_amount'],
                'total_interest_paid': Decimal('0'),
                'total_principal_paid': Decimal('0'),
                'next_payment_date': disbursement_date.replace(day=1) + timedelta(days=32),
                'payment_status': 'current',
                'created_at': disbursement_date
            })

            # Create journal entry for loan disbursement
            entries = [
                ('1110', app['requested_amount'], Decimal('0')),  # Debit: Personal Loans (Asset)
                ('1010', Decimal('0'), app['requested_amount'])  # Credit: Customer Deposits
            ]

            self.create_journal_entry(
                disbursement_date,
                f"Loan disbursement - {app['requested_amount']}",
                'loan_disbursement',
                self.loan_account_id,
                entries
            )

    def calculate_monthly_payment(self, principal, rate, months):
        """Calculate monthly loan payment"""
        if rate == 0:
            return principal / months
        return (principal * rate * (1 + rate) ** months) / ((1 + rate) ** months - 1)

    def generate_aml_checks(self):
        """Generate AML checks"""
        print("Generating AML checks...")

        for customer in self.customers:
            # Generate periodic AML checks
            check_date = customer['registration_date']

            while check_date <= datetime.now().date():
                self.aml_id += 1

                self.aml_checks.append({
                    'check_id': self.aml_id,
                    'customer_id': customer['customer_id'],
                    'check_date': check_date,
                    'check_type': random.choice(['pep', 'sanctions', 'adverse_media', 'periodic_review']),
                    'risk_score': customer['risk_score'],
                    'status': 'cleared' if customer['risk_score'] > 500 else random.choice(['cleared', 'review', 'escalated']),
                    'reviewed_by': fake.name() if random.random() < 0.3 else None,
                    'notes': None,
                    'created_at': check_date
                })

                check_date += timedelta(days=90)  # Quarterly checks

    def generate_fraud_alerts(self):
        """Generate fraud alerts"""
        print("Generating fraud alerts...")

        suspicious_transactions = random.sample(
            self.transactions,
            min(int(len(self.transactions) * CONFIG['fraud_rate']), len(self.transactions))
        )

        for trans in suspicious_transactions:
            self.alert_id += 1

            triggered_rules = random.sample(self.risk_rules, random.randint(1, 3))

            self.fraud_alerts.append({
                'alert_id': self.alert_id,
                'transaction_id': trans['transaction_id'],
                'alert_type': 'fraud_suspected',
                'risk_score': random.randint(60, 100),
                'triggered_rules': json.dumps([r['rule_code'] for r in triggered_rules]),
                'alert_date': trans['transaction_date'],
                'status': random.choice(['pending', 'investigating', 'confirmed_fraud', 'false_positive']),
                'investigated_by': fake.name() if random.random() < 0.5 else None,
                'investigation_date': trans['transaction_date'] + timedelta(hours=random.randint(1, 24)),
                'resolution': None,
                'created_at': trans['transaction_date']
            })

    def generate_device_fingerprints(self):
        """Generate device fingerprints"""
        print("Generating device fingerprints...")

        device_types = ['ios', 'android', 'web']
        browsers = ['Chrome', 'Safari', 'Firefox', 'Edge']

        for customer in self.customers:
            # Each customer has 1-3 devices
            num_devices = random.randint(1, 3)

            for _ in range(num_devices):
                self.device_id += 1

                device_type = random.choice(device_types)

                self.device_fingerprints.append({
                    'fingerprint_id': self.device_id,
                    'customer_id': customer['customer_id'],
                    'device_id': str(uuid.uuid4()),
                    'device_type': device_type,
                    'os_name': 'iOS' if device_type == 'ios' else 'Android' if device_type == 'android' else 'Windows',
                    'os_version': f"{random.randint(10, 15)}.{random.randint(0, 5)}",
                    'browser_name': random.choice(browsers) if device_type == 'web' else None,
                    'browser_version': f"{random.randint(90, 110)}.0" if device_type == 'web' else None,
                    'ip_address': fake.ipv4(),
                    'location_country': 'USA',
                    'location_city': fake.city(),
                    'first_seen': customer['registration_date'],
                    'last_seen': fake.date_time_between(start_date='-7d', end_date='now'),
                    'is_trusted': random.random() > 0.1,
                    'created_at': customer['registration_date']
                })

    def generate_sar_reports(self):
        """Generate Suspicious Activity Reports"""
        print("Generating SAR reports...")

        high_risk_customers = [c for c in self.customers if c['risk_category'] == 'high']

        for customer in random.sample(high_risk_customers, min(10, len(high_risk_customers))):
            self.sar_id += 1

            filing_date = fake.date_between(start_date=self.start_date, end_date='today')

            self.sar_reports.append({
                'sar_id': self.sar_id,
                'customer_id': customer['customer_id'],
                'filing_date': filing_date,
                'suspicious_activity_date': filing_date - timedelta(days=random.randint(1, 30)),
                'suspicious_amount': Decimal(str(random.uniform(10000, 100000))),
                'activity_description': 'Unusual transaction patterns detected',
                'filing_institution': 'FinTech Platform Inc.',
                'filer_name': fake.name(),
                'filer_title': 'Compliance Officer',
                'status': random.choice(['draft', 'filed', 'acknowledged']),
                'fincen_tracking': f"FIN{random.randint(1000000, 9999999)}" if random.random() < 0.7 else None,
                'created_at': filing_date
            })

    def generate_notification_preferences(self):
        """Generate notification preferences"""
        print("Generating notification preferences...")

        notification_types = ['transaction', 'security', 'marketing', 'account_update']
        channels = ['email', 'sms', 'push', 'in_app']

        for customer in self.customers:
            for notif_type in notification_types:
                self.notification_id += 1

                enabled_channels = random.sample(channels, random.randint(1, len(channels)))

                self.notification_preferences.append({
                    'preference_id': self.notification_id,
                    'customer_id': customer['customer_id'],
                    'notification_type': notif_type,
                    'email_enabled': 'email' in enabled_channels,
                    'sms_enabled': 'sms' in enabled_channels,
                    'push_enabled': 'push' in enabled_channels,
                    'in_app_enabled': 'in_app' in enabled_channels,
                    'frequency': random.choice(['immediate', 'daily', 'weekly']) if notif_type != 'transaction' else 'immediate',
                    'created_at': customer['created_at']
                })

    def generate_audit_logs(self):
        """Generate audit logs"""
        print("Generating audit logs...")

        actions = ['login', 'logout', 'view_account', 'transfer', 'payment', 'profile_update']

        for _ in range(1000):  # Generate 1000 audit logs
            self.audit_id += 1

            customer = random.choice(self.customers)
            action_time = fake.date_time_between(start_date=self.start_date, end_date='now')

            self.audit_logs.append({
                'log_id': self.audit_id,
                'user_id': customer['customer_id'],
                'user_type': 'customer',
                'action': random.choice(actions),
                'resource_type': 'account' if 'account' in random.choice(actions) else 'transaction',
                'resource_id': random.randint(1, 1000),
                'ip_address': fake.ipv4(),
                'user_agent': fake.user_agent()[:200],
                'status': random.choices(['success', 'failure'], weights=[0.95, 0.05])[0],
                'error_message': 'Invalid credentials' if random.random() < 0.05 else None,
                'created_at': action_time
            })

    def create_journal_entry(self, date, description, ref_type, ref_id, lines):
        """Create journal entry with balanced debits and credits"""
        self.journal_id += 1

        total_debits = sum(debit for _, debit, _ in lines)
        total_credits = sum(credit for _, _, credit in lines)

        # Ensure balanced entry
        if total_debits != total_credits:
            raise ValueError(f"Unbalanced journal entry: Debits {total_debits} != Credits {total_credits}")

        journal_entry = {
            'journal_id': self.journal_id,
            'entry_date': date.date() if isinstance(date, datetime) else date,
            'posting_date': date if isinstance(date, datetime) else datetime.combine(date, datetime.min.time()),
            'description': description,
            'reference_type': ref_type,
            'reference_id': ref_id,
            'total_debits': total_debits,
            'total_credits': total_credits,
            'status': 'posted',
            'posted_by': 'system',
            'reversed_by_journal_id': None,
            'created_at': date if isinstance(date, datetime) else datetime.combine(date, datetime.min.time())
        }
        self.journal_entries.append(journal_entry)

        # Create journal lines
        for account_code, debit, credit in lines:
            self.line_id += 1

            self.journal_lines.append({
                'line_id': self.line_id,
                'journal_id': self.journal_id,
                'account_code': account_code,
                'debit_amount': debit,
                'credit_amount': credit,
                'currency': 'USD',
                'exchange_rate': Decimal('1.000000'),
                'base_currency_amount': debit if debit > 0 else credit,
                'description': description[:255]
            })

            # Update GL balances
            account = next((a for a in self.chart_of_accounts if a['account_code'] == account_code), None)
            if account:
                if account['normal_balance'] == 'debit':
                    self.gl_balances[account_code] += debit - credit
                else:
                    self.gl_balances[account_code] += credit - debit

    def save_all(self):
        """Save all generated data to CSV files"""
        OUTPUT_DIR.mkdir(exist_ok=True)

        print("\nSaving data to CSV files...")

        datasets = [
            ('customers', self.customers),
            ('individual_customers', self.individual_customers),
            ('business_customers', self.business_customers),
            ('kyc_documents', self.kyc_documents),
            ('customer_addresses', self.customer_addresses),
            ('accounts', self.accounts),
            ('account_holders', self.account_holders),
            ('chart_of_accounts', self.chart_of_accounts),
            ('journal_entries', self.journal_entries),
            ('journal_lines', self.journal_lines),
            ('transactions', self.transactions[:5000]),  # Limit for demo
            ('transfers', self.transfers),
            ('payment_methods', self.payment_methods),
            ('cards', self.cards),
            ('currencies', self.currencies),
            ('exchange_rates', self.exchange_rates[:1000]),  # Limit for demo
            ('risk_rules', self.risk_rules),
            ('fraud_alerts', self.fraud_alerts),
            ('device_fingerprints', self.device_fingerprints),
            ('aml_checks', self.aml_checks[:1000]),  # Limit for demo
            ('sar_reports', self.sar_reports),
            ('audit_logs', self.audit_logs),
            ('loan_applications', self.loan_applications),
            ('loan_accounts', self.loan_accounts),
            ('fee_schedule', self.fee_schedule),
            ('notification_preferences', self.notification_preferences)
        ]

        for name, data in datasets:
            if data:
                filepath = OUTPUT_DIR / f"{name}.csv"
                with open(filepath, 'w', newline='', encoding='utf-8') as f:
                    writer = csv.DictWriter(f, fieldnames=data[0].keys())
                    writer.writeheader()
                    writer.writerows(data)
                print(f"  [OK] {name}: {len(data):,} records")

        self.generate_summary()

    def generate_summary(self):
        """Generate summary statistics"""
        print(f"\nFinTech Platform Data Generation Summary")
        print("=" * 50)

        print(f"\nCustomers:")
        print(f"  Total Customers: {len(self.customers)}")
        print(f"  Individual: {len(self.individual_customers)}")
        print(f"  Business: {len(self.business_customers)}")
        print(f"  KYC Documents: {len(self.kyc_documents)}")

        print(f"\nAccounts:")
        print(f"  Total Accounts: {len(self.accounts)}")
        print(f"  Checking: {len([a for a in self.accounts if a['account_type'] == 'checking'])}")
        print(f"  Savings: {len([a for a in self.accounts if a['account_type'] == 'savings'])}")
        print(f"  Investment: {len([a for a in self.accounts if a['account_type'] == 'investment'])}")

        print(f"\nTransactions:")
        print(f"  Total Transactions: {len(self.transactions):,}")
        print(f"  Transfers: {len(self.transfers)}")
        print(f"  Cards Issued: {len(self.cards)}")

        print(f"\nAccounting:")
        print(f"  Chart of Accounts: {len(self.chart_of_accounts)}")
        print(f"  Journal Entries: {len(self.journal_entries):,}")
        print(f"  Journal Lines: {len(self.journal_lines):,}")

        # Verify double-entry balance
        total_debits = sum(entry['total_debits'] for entry in self.journal_entries)
        total_credits = sum(entry['total_credits'] for entry in self.journal_entries)
        print(f"  Total Debits: ${total_debits:,.2f}")
        print(f"  Total Credits: ${total_credits:,.2f}")
        print(f"  Balanced: {'YES' if total_debits == total_credits else 'NO'}")

        print(f"\nLoans:")
        print(f"  Applications: {len(self.loan_applications)}")
        print(f"  Approved: {len([l for l in self.loan_applications if l['status'] == 'approved'])}")
        print(f"  Active Loans: {len(self.loan_accounts)}")

        print(f"\nRisk & Compliance:")
        print(f"  Risk Rules: {len(self.risk_rules)}")
        print(f"  Fraud Alerts: {len(self.fraud_alerts)}")
        print(f"  AML Checks: {len(self.aml_checks)}")
        print(f"  SAR Reports: {len(self.sar_reports)}")

        print(f"\nAudit & Monitoring:")
        print(f"  Audit Logs: {len(self.audit_logs)}")
        print(f"  Device Fingerprints: {len(self.device_fingerprints)}")

        print(f"\nFiles Generated: 26")

if __name__ == "__main__":
    generator = FinTechGenerator()
    generator.generate_all()
    print("\n[SUCCESS] FinTech platform data generation complete!")