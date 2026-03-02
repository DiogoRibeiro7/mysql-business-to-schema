#!/usr/bin/env python3
"""FinTech Platform Data Generator.

Generates realistic financial data including:
- Customers (individual and business) with KYC
- Bank accounts (checking, savings, loans, credit cards, investment)
- Transactions with various patterns
- Fraud alerts and risk scoring
- Currency exchanges
- Compliance records
"""

import csv
import random
import hashlib
import uuid
from datetime import datetime, timedelta, date
from pathlib import Path
from typing import List, Dict, Optional, Any
import yaml
from faker import Faker

# Load configuration
with open("config.yaml", "r") as f:
    config = yaml.safe_load(f)

# Initialize Faker with seed
faker = Faker()
Faker.seed(config["seed"])
random.seed(config["seed"])

# Create output directory
output_dir = Path(config["output_dir"])
output_dir.mkdir(parents=True, exist_ok=True)


class FinTechDataGenerator:
    """Represent FinTechDataGenerator."""

    def __init__(self):
        """Initialize the instance."""
        self.customers: List[Any] = []
        self.accounts: List[Any] = []
        self.transactions: List[Any] = []
        self.fraud_alerts: List[Any] = []
        self.devices: List[Any] = []
        self.payment_methods: List[Any] = []
        self.kyc_documents: List[Any] = []
        self.exchange_rates: Dict[str, Any] = {}
        self.start_date = datetime.now() - timedelta(
            days=config["counts"]["days_of_history"]
        )

    def generate_all(self):
        """Generate all data for the FinTech platform."""
        print("Generating FinTech platform data...")

        # Generate base entities
        self.generate_currencies()
        self.generate_exchange_rates()
        self.generate_customers()
        self.generate_accounts()
        self.generate_payment_methods()
        self.generate_devices()

        # Generate transactional data
        self.generate_transactions()
        self.generate_fraud_alerts()

        # Generate compliance data
        self.generate_kyc_documents()
        self.generate_aml_checks()

        # Write all data to CSV files
        self.write_all_to_csv()

        print(f"Data generation complete. Files written to {output_dir}")

    def generate_currencies(self):
        """Generate currency reference data."""
        self.currencies = [
            ("USD", "US Dollar", "$", 2),
            ("EUR", "Euro", "€", 2),
            ("GBP", "British Pound", "£", 2),
            ("JPY", "Japanese Yen", "¥", 0),
            ("CAD", "Canadian Dollar", "C$", 2),
        ]

    def generate_exchange_rates(self):
        """Generate historical exchange rates."""
        base_rates = {
            ("USD", "EUR"): 0.85,
            ("USD", "GBP"): 0.73,
            ("USD", "JPY"): 110.0,
            ("USD", "CAD"): 1.25,
            ("EUR", "USD"): 1.18,
            ("EUR", "GBP"): 0.86,
            ("GBP", "USD"): 1.37,
            ("GBP", "EUR"): 1.16,
        }

        self.exchange_rates_list: List[Any] = []
        current_date = self.start_date.date()

        while current_date <= datetime.now().date():
            for (from_curr, to_curr), base_rate in base_rates.items():
                # Add some daily variation
                variation = random.uniform(-0.02, 0.02)
                rate = base_rate * (1 + variation)

                self.exchange_rates_list.append(
                    {
                        "from_currency": from_curr,
                        "to_currency": to_curr,
                        "rate_date": current_date,
                        "exchange_rate": round(rate, 6),
                        "rate_source": "SYSTEM",
                    }
                )

            current_date += timedelta(days=1)

    def generate_customers(self):
        """Generate individual and business customers."""
        total_customers = (
            config["counts"]["individual_customers"]
            + config["counts"]["business_customers"]
        )

        for i in range(1, total_customers + 1):
            is_business = i > config["counts"]["individual_customers"]

            # Base customer data
            customer = {
                "customer_id": i,
                "customer_type": "business" if is_business else "individual",
                "email": faker.email(),
                "phone_number": faker.phone_number()[:20],
                "status": random.choices(
                    ["pending_kyc", "active", "suspended"], weights=[0.05, 0.93, 0.02]
                )[0],
                "risk_level": random.choices(
                    list(config["distributions"]["customer_risk"].keys()),
                    weights=list(config["distributions"]["customer_risk"].values()),
                )[0],
                "onboarding_date": faker.date_between(
                    start_date=self.start_date, end_date="today"
                ),
                "preferred_currency": random.choices(
                    list(config["distributions"]["currencies"].keys()),
                    weights=list(config["distributions"]["currencies"].values()),
                )[0],
            }

            if is_business:
                # Business-specific data
                customer["business_name"] = faker.company()
                customer["business_type"] = random.choice(
                    ["LLC", "Corporation", "Partnership", "Sole Proprietorship"]
                )
                customer["registration_number"] = faker.uuid4()[:20]
                customer["tax_id"] = faker.uuid4()[
                    :20
                ]  # Would be encrypted in real system
                customer["incorporation_date"] = faker.date_between(
                    start_date="-10y", end_date="-1y"
                )
                customer["incorporation_country"] = faker.country_code()
                customer["annual_revenue"] = round(random.uniform(100000, 10000000), 2)
                customer["industry"] = faker.bs()
            else:
                # Individual-specific data
                customer["first_name"] = faker.first_name()
                customer["last_name"] = faker.last_name()
                customer["middle_name"] = (
                    faker.first_name() if random.random() > 0.5 else None
                )
                customer["date_of_birth"] = faker.date_of_birth(
                    minimum_age=18, maximum_age=80
                )
                customer["ssn"] = faker.ssn()[:20]  # Would be encrypted in real system
                customer["nationality"] = faker.country_code()
                customer["occupation"] = faker.job()
                customer["annual_income"] = round(random.uniform(20000, 500000), 2)

            self.customers.append(customer)

    def generate_accounts(self):
        """Generate bank accounts for customers."""
        account_id = 1

        for customer in self.customers:
            if customer["status"] != "active":
                continue

            num_accounts = random.randint(
                config["counts"]["accounts_per_customer"]["min"],
                config["counts"]["accounts_per_customer"]["max"],
            )

            # Ensure at least one checking account
            account_types = ["checking"] + random.choices(
                list(config["distributions"]["account_types"].keys()),
                weights=list(config["distributions"]["account_types"].values()),
                k=num_accounts - 1,
            )

            for account_type in account_types:
                # Determine initial balance based on account type
                balance_config = config["financial"]["initial_balance"].get(
                    account_type, config["financial"]["initial_balance"]["checking"]
                )

                initial_balance = round(
                    random.uniform(balance_config["min"], balance_config["max"]), 2
                )

                # Get interest rate
                if account_type in config["financial"]["interest_rates"]:
                    interest_config = config["financial"]["interest_rates"][
                        account_type
                    ]
                    interest_rate = round(
                        random.uniform(interest_config["min"], interest_config["max"]),
                        4,
                    )
                else:
                    interest_rate = 0

                account = {
                    "account_id": account_id,
                    "customer_id": customer["customer_id"],
                    "account_number": f"{account_type[:2].upper()}{account_id:010d}",
                    "account_type": account_type,
                    "currency": customer["preferred_currency"],
                    "status": "active",
                    "balance": initial_balance,
                    "available_balance": initial_balance * 0.95,  # 5% held
                    "pending_balance": initial_balance * 0.05,
                    "interest_rate": interest_rate,
                    "overdraft_limit": 500 if account_type == "checking" else 0,
                    "minimum_balance": 100 if account_type == "savings" else 0,
                    "opened_date": customer["onboarding_date"],
                    "last_transaction_date": None,
                }

                self.accounts.append(account)
                account_id += 1

    def generate_payment_methods(self):
        """Generate payment methods (cards, bank accounts) for customers."""
        payment_method_id = 1

        for customer in self.customers:
            if customer["status"] != "active":
                continue

            # Most customers have 1-3 payment methods
            num_methods = random.choices([1, 2, 3], weights=[0.4, 0.4, 0.2])[0]

            for i in range(num_methods):
                method_type = random.choices(
                    ["card", "bank_account"], weights=[0.7, 0.3]
                )[0]

                payment_method = {
                    "payment_method_id": payment_method_id,
                    "customer_id": customer["customer_id"],
                    "method_type": method_type,
                    "is_default": i == 0,
                    "is_active": random.random() > 0.1,
                }

                if method_type == "card":
                    # Generate card details
                    card_brand = random.choice(
                        ["visa", "mastercard", "amex", "discover"]
                    )
                    card_number = faker.credit_card_number(card_brand)

                    payment_method["card_details"] = {
                        "card_number_masked": f"****{card_number[-4:]}",
                        "card_number_hash": hashlib.sha256(
                            card_number.encode()
                        ).hexdigest(),
                        "card_type": random.choice(["debit", "credit", "prepaid"]),
                        "card_brand": card_brand,
                        "expiry_month": random.randint(1, 12),
                        "expiry_year": random.randint(2024, 2028),
                        "cardholder_name": f"{customer.get('first_name', customer.get('business_name', ''))} {customer.get('last_name', '')}".strip(),
                    }

                self.payment_methods.append(payment_method)
                payment_method_id += 1

    def generate_devices(self):
        """Generate device fingerprints for customers."""
        device_types = ["iPhone", "Android", "Desktop", "Tablet"]
        os_types = ["iOS", "Android", "Windows", "macOS", "Linux"]

        for customer in self.customers:
            if customer["status"] != "active":
                continue

            # Most customers use 1-2 devices
            num_devices = random.choices([1, 2, 3], weights=[0.5, 0.4, 0.1])[0]

            for _ in range(num_devices):
                device = {
                    "customer_id": customer["customer_id"],
                    "device_hash": faker.sha256(),
                    "device_type": random.choice(device_types),
                    "operating_system": random.choice(os_types),
                    "browser": random.choice(["Chrome", "Safari", "Firefox", "Edge"]),
                    "ip_address": faker.ipv4(),
                    "location_country": faker.country_code(),
                    "location_city": faker.city(),
                    "first_seen": faker.date_time_between(
                        start_date=customer["onboarding_date"], end_date="now"
                    ),
                    "trust_score": random.randint(30, 100),
                    "is_blocked": random.random() < 0.02,  # 2% blocked devices
                }

                self.devices.append(device)

    def generate_transactions(self):
        """Generate transaction history."""
        transaction_id = 1

        current_date = self.start_date

        while current_date <= datetime.now():
            # Generate transactions for each active account
            for account in self.accounts:
                if account["status"] != "active":
                    continue

                # Determine number of transactions for this day
                num_transactions = random.randint(
                    config["counts"]["transactions_per_account_per_day"]["min"],
                    config["counts"]["transactions_per_account_per_day"]["max"],
                )

                for _ in range(num_transactions):
                    # Select transaction type
                    tx_type = random.choices(
                        list(config["distributions"]["transaction_types"].keys()),
                        weights=list(
                            config["distributions"]["transaction_types"].values()
                        ),
                    )[0]

                    # Determine amount based on distribution
                    amount_category = random.choices(
                        ["small", "medium", "large", "very_large"],
                        weights=[0.6, 0.3, 0.09, 0.01],
                    )[0]

                    amount_range = config["financial"]["transaction_amounts"][
                        amount_category
                    ]
                    amount = round(
                        random.uniform(amount_range["min"], amount_range["max"]), 2
                    )

                    # Update account balance
                    if tx_type in ["withdrawal", "payment", "transfer"]:
                        new_balance = account["balance"] - amount
                    elif tx_type in ["deposit", "interest"]:
                        new_balance = account["balance"] + amount
                    else:  # fee, adjustment
                        new_balance = (
                            account["balance"] - amount
                            if random.random() > 0.5
                            else account["balance"] + amount
                        )

                    # Skip if would overdraw (unless it's a credit account)
                    if (
                        new_balance < -account["overdraft_limit"]
                        and account["account_type"] != "credit_card"
                    ):
                        continue

                    transaction = {
                        "transaction_id": transaction_id,
                        "transaction_uuid": str(uuid.uuid4()),
                        "account_id": account["account_id"],
                        "transaction_type": tx_type,
                        "amount": amount,
                        "currency": account["currency"],
                        "balance_after": round(new_balance, 2),
                        "description": self.generate_transaction_description(
                            tx_type, amount
                        ),
                        "reference_number": faker.uuid4()[:20],
                        "status": random.choices(
                            ["completed", "pending", "failed"],
                            weights=[0.95, 0.03, 0.02],
                        )[0],
                        "initiated_at": current_date
                        + timedelta(
                            hours=random.randint(0, 23), minutes=random.randint(0, 59)
                        ),
                        "channel": random.choices(
                            list(
                                config["distributions"]["transaction_channels"].keys()
                            ),
                            weights=list(
                                config["distributions"]["transaction_channels"].values()
                            ),
                        )[0],
                        "ip_address": faker.ipv4(),
                        "device_id": faker.uuid4()[:20],
                    }

                    if transaction["status"] == "completed":
                        transaction["completed_at"] = transaction[
                            "initiated_at"
                        ] + timedelta(seconds=random.randint(1, 60))
                        account["balance"] = new_balance
                        account["last_transaction_date"] = transaction["initiated_at"]

                    self.transactions.append(transaction)
                    transaction_id += 1

                    # Check if this transaction should trigger a fraud alert
                    if random.random() < config["counts"]["fraud_alert_rate"]:
                        self.generate_fraud_alert_for_transaction(transaction, account)

            current_date += timedelta(days=1)

    def generate_transaction_description(self, tx_type: str, amount: float) -> str:
        """Generate realistic transaction descriptions."""
        descriptions = {
            "payment": [
                f"Payment to {faker.company()}",
                f"Online purchase - {faker.company()}",
                f"Bill payment - {random.choice(['Utilities', 'Internet', 'Phone', 'Insurance'])}",
                f"Subscription - {random.choice(['Netflix', 'Spotify', 'Amazon Prime', 'Cloud Storage'])}",
            ],
            "transfer": [
                f"Transfer to {faker.name()}",
                f"Wire transfer - {faker.company()}",
                "Internal transfer between accounts",
                f"International wire to {faker.country()}",
            ],
            "deposit": [
                "Direct deposit - Salary",
                "Mobile deposit",
                "ATM deposit",
                f"Transfer from {faker.name()}",
                "Tax refund",
            ],
            "withdrawal": [
                "ATM withdrawal",
                "Cash withdrawal at branch",
                f"ATM withdrawal - {faker.city()}",
            ],
            "fee": [
                "Monthly maintenance fee",
                "Overdraft fee",
                "Wire transfer fee",
                "Foreign transaction fee",
                "ATM fee",
            ],
            "interest": [
                "Monthly interest credit",
                "Interest payment",
                "Bonus interest",
            ],
            "adjustment": [
                "Account adjustment",
                "Fee reversal",
                "Dispute resolution credit",
                "Error correction",
            ],
        }

        return random.choice(descriptions.get(tx_type, ["Transaction"]))

    def generate_fraud_alert_for_transaction(self, transaction: Dict, account: Dict):
        """Generate a fraud alert for a suspicious transaction."""
        customer_id = next(
            (
                acc["customer_id"]
                for acc in self.accounts
                if acc["account_id"] == account["account_id"]
            ),
            None,
        )

        if not customer_id:
            return

        alert_type = random.choices(
            list(config["distributions"]["fraud_patterns"].keys()),
            weights=list(config["distributions"]["fraud_patterns"].values()),
        )[0]

        risk_scores = {
            "velocity": random.randint(40, 90),
            "amount": random.randint(50, 95),
            "location": random.randint(30, 80),
            "device": random.randint(35, 85),
            "behavioral": random.randint(45, 90),
        }

        fraud_alert = {
            "alert_id": len(self.fraud_alerts) + 1,
            "transaction_id": transaction["transaction_id"],
            "customer_id": customer_id,
            "alert_type": alert_type,
            "risk_score": risk_scores[alert_type],
            "alert_details": {
                "reason": f"Suspicious {alert_type} pattern detected",
                "amount": transaction["amount"],
                "location": transaction["ip_address"],
            },
            "status": random.choices(
                ["pending", "investigating", "cleared", "confirmed_fraud"],
                weights=[0.4, 0.2, 0.35, 0.05],
            )[0],
            "created_at": transaction["initiated_at"],
        }

        self.fraud_alerts.append(fraud_alert)

    def generate_kyc_documents(self):
        """Generate KYC document records for customers."""
        document_id = 1

        for customer in self.customers:
            # Number of documents depends on customer type and status
            if customer["customer_type"] == "individual":
                doc_types = ["passport", "drivers_license", "utility_bill"]
            else:
                doc_types = ["incorporation_cert", "bank_statement", "utility_bill"]

            for doc_type in doc_types:
                document = {
                    "document_id": document_id,
                    "customer_id": customer["customer_id"],
                    "document_type": doc_type,
                    "document_number": (
                        faker.uuid4()[:20]
                        if doc_type in ["passport", "drivers_license"]
                        else None
                    ),
                    "issue_date": (
                        faker.date_between(start_date="-5y", end_date="-1y")
                        if doc_type in ["passport", "drivers_license"]
                        else None
                    ),
                    "expiry_date": (
                        faker.date_between(start_date="+1y", end_date="+10y")
                        if doc_type in ["passport", "drivers_license"]
                        else None
                    ),
                    "issuing_country": faker.country_code(),
                    "verification_status": random.choices(
                        ["verified", "pending", "rejected"], weights=[0.85, 0.10, 0.05]
                    )[0],
                    "document_hash": faker.sha256(),
                }

                self.kyc_documents.append(document)
                document_id += 1

    def generate_aml_checks(self):
        """Generate AML check records for customers."""
        self.aml_checks: List[Any] = []
        check_id = 1

        for customer in self.customers:
            if customer["status"] != "active":
                continue

            # Generate periodic AML checks
            check_date = customer["onboarding_date"]

            while check_date <= date.today():
                for check_type in ["sanctions", "pep", "adverse_media"]:
                    # Higher risk customers more likely to have matches
                    if customer["risk_level"] == "high":
                        result_weights = [0.6, 0.3, 0.1]
                    elif customer["risk_level"] == "medium":
                        result_weights = [0.8, 0.15, 0.05]
                    else:
                        result_weights = [0.95, 0.04, 0.01]

                    check = {
                        "check_id": check_id,
                        "customer_id": customer["customer_id"],
                        "check_type": check_type,
                        "check_provider": random.choice(
                            ["Provider_A", "Provider_B", "Internal"]
                        ),
                        "check_date": check_date,
                        "result": random.choices(
                            ["clear", "potential_match", "confirmed_match"],
                            weights=result_weights,
                        )[0],
                        "match_details": (
                            {}
                            if random.random() > 0.1
                            else {"score": random.uniform(0.5, 1.0)}
                        ),
                    }

                    self.aml_checks.append(check)
                    check_id += 1

                # Next check in 30 days
                check_date = check_date + timedelta(
                    days=config["compliance"]["aml_check_frequency_days"]
                )

    def write_all_to_csv(self):
        """Write all generated data to CSV files."""
        # Write customers
        self.write_customers_csv()

        # Write accounts
        with open(output_dir / "accounts.csv", "w", newline="", encoding="utf-8") as f:
            if self.accounts:
                writer = csv.DictWriter(f, fieldnames=self.accounts[0].keys())
                writer.writeheader()
                writer.writerows(self.accounts)

        # Write transactions
        with open(
            output_dir / "transactions.csv", "w", newline="", encoding="utf-8"
        ) as f:
            if self.transactions:
                fieldnames = [
                    k for k in self.transactions[0].keys() if k != "completed_at"
                ]
                writer = csv.DictWriter(f, fieldnames=fieldnames, extrasaction="ignore")
                writer.writeheader()
                writer.writerows(self.transactions)

        # Write fraud alerts
        with open(
            output_dir / "fraud_alerts.csv", "w", newline="", encoding="utf-8"
        ) as f:
            if self.fraud_alerts:
                # Flatten alert_details JSON
                rows = []
                for alert in self.fraud_alerts:
                    row = alert.copy()
                    row["alert_details"] = str(row["alert_details"])
                    rows.append(row)

                writer = csv.DictWriter(f, fieldnames=rows[0].keys())
                writer.writeheader()
                writer.writerows(rows)

        # Write other entities
        self.write_simple_csv(
            "currencies.csv",
            self.currencies,
            ["currency_code", "currency_name", "symbol", "decimal_places"],
        )
        self.write_simple_csv("exchange_rates.csv", self.exchange_rates_list)
        self.write_simple_csv("kyc_documents.csv", self.kyc_documents)
        self.write_simple_csv("aml_checks.csv", self.aml_checks)
        self.write_simple_csv("devices.csv", self.devices)

        # Write payment methods
        self.write_payment_methods_csv()

        print("Generated data summary:")
        print(f"  - Customers: {len(self.customers)}")
        print(f"  - Accounts: {len(self.accounts)}")
        print(f"  - Transactions: {len(self.transactions)}")
        print(f"  - Fraud Alerts: {len(self.fraud_alerts)}")
        print(f"  - KYC Documents: {len(self.kyc_documents)}")
        print(f"  - AML Checks: {len(self.aml_checks)}")

    def write_customers_csv(self):
        """Write customer data to separate CSV files."""
        individuals = [c for c in self.customers if c["customer_type"] == "individual"]
        businesses = [c for c in self.customers if c["customer_type"] == "business"]

        # Write base customers table
        base_fields = [
            "customer_id",
            "customer_type",
            "email",
            "phone_number",
            "status",
            "risk_level",
            "onboarding_date",
            "preferred_currency",
        ]

        with open(output_dir / "customers.csv", "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=base_fields, extrasaction="ignore")
            writer.writeheader()
            writer.writerows(self.customers)

        # Write individual customers
        if individuals:
            ind_fields = [
                "customer_id",
                "first_name",
                "last_name",
                "middle_name",
                "date_of_birth",
                "ssn",
                "nationality",
                "occupation",
                "annual_income",
            ]

            with open(
                output_dir / "individual_customers.csv",
                "w",
                newline="",
                encoding="utf-8",
            ) as f:
                writer = csv.DictWriter(f, fieldnames=ind_fields, extrasaction="ignore")
                writer.writeheader()
                writer.writerows(individuals)

        # Write business customers
        if businesses:
            bus_fields = [
                "customer_id",
                "business_name",
                "business_type",
                "registration_number",
                "tax_id",
                "incorporation_date",
                "incorporation_country",
                "annual_revenue",
                "industry",
            ]

            with open(
                output_dir / "business_customers.csv", "w", newline="", encoding="utf-8"
            ) as f:
                writer = csv.DictWriter(f, fieldnames=bus_fields, extrasaction="ignore")
                writer.writeheader()
                writer.writerows(businesses)

    def write_payment_methods_csv(self):
        """Write payment method data to CSV."""
        with open(
            output_dir / "payment_methods.csv", "w", newline="", encoding="utf-8"
        ) as f:
            if self.payment_methods:
                base_fields = [
                    "payment_method_id",
                    "customer_id",
                    "method_type",
                    "is_default",
                    "is_active",
                ]
                writer = csv.DictWriter(
                    f, fieldnames=base_fields, extrasaction="ignore"
                )
                writer.writeheader()
                writer.writerows(self.payment_methods)

        # Write card details separately
        cards = [pm for pm in self.payment_methods if pm["method_type"] == "card"]
        if cards:
            card_data = []
            for pm in cards:
                if "card_details" in pm:
                    card = pm["card_details"].copy()
                    card["payment_method_id"] = pm["payment_method_id"]
                    card_data.append(card)

            if card_data:
                with open(
                    output_dir / "cards.csv", "w", newline="", encoding="utf-8"
                ) as f:
                    writer = csv.DictWriter(f, fieldnames=card_data[0].keys())
                    writer.writeheader()
                    writer.writerows(card_data)

    def write_simple_csv(
        self, filename: str, data: List, fieldnames: Optional[List[str]] = None
    ):
        """Write simple data to CSV file."""
        if not data:
            return

        with open(output_dir / filename, "w", newline="", encoding="utf-8") as f:
            if isinstance(data[0], dict):
                dict_writer = csv.DictWriter(
                    f, fieldnames=fieldnames or data[0].keys()
                )
                dict_writer.writeheader()
                dict_writer.writerows(data)
            else:
                list_writer = csv.writer(f)
                if fieldnames:
                    list_writer.writerow(fieldnames)
                list_writer.writerows(data)


if __name__ == "__main__":
    generator = FinTechDataGenerator()
    generator.generate_all()
