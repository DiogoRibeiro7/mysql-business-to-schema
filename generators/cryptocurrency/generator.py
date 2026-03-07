#!/usr/bin/env python3
"""Cryptocurrency Exchange Data Generator.

Generates realistic sample data for the cryptocurrency exchange database schema
with market dynamics, trading patterns, and realistic transaction flows.
"""

import random
import json
import csv
import hashlib
from datetime import datetime, timedelta, date
from decimal import Decimal
from typing import List, Dict, Any, Optional
from pathlib import Path

# Required: pip install faker
from faker import Faker


class CryptocurrencyDataGenerator:
    """Generate realistic cryptocurrency exchange data."""

    def __init__(self, config_path: str = "config.yaml"):
        """Initialize the generator with configuration."""
        self.fake = Faker("en_US")

        # Load configuration
        config_file = (
            Path(config_path)
            if Path(config_path).is_absolute()
            else Path(__file__).parent / config_path
        )
        with open(config_file, "r") as f:
            self.config = json.load(f)

        # Set seed for reproducibility
        random.seed(self.config["seed"])
        Faker.seed(self.config["seed"])

        # Data storage
        self.users: List[Dict[str, Any]] = []
        self.kyc_documents: List[Dict[str, Any]] = []
        self.currencies: List[Dict[str, Any]] = []
        self.trading_pairs: List[Dict[str, Any]] = []
        self.wallets: List[Dict[str, Any]] = []
        self.orders: List[Dict[str, Any]] = []
        self.trades: List[Dict[str, Any]] = []
        self.transactions: List[Dict[str, Any]] = []
        self.price_history: List[Dict[str, Any]] = []
        self.api_keys: List[Dict[str, Any]] = []
        self.user_sessions: List[Dict[str, Any]] = []
        self.audit_logs: List[Dict[str, Any]] = []
        self.user_fee_tiers: List[Dict[str, Any]] = []
        self.user_trading_volumes: List[Dict[str, Any]] = []

        # Counters
        self.counters = {
            "user_id": 1,
            "kyc_id": 1,
            "currency_id": 1,
            "pair_id": 1,
            "wallet_id": 1,
            "order_id": 1,
            "trade_id": 1,
            "transaction_id": 1,
            "price_id": 1,
            "api_key_id": 1,
            "session_id": 1,
            "log_id": 1,
            "fee_tier_id": 1,
            "volume_id": 1,
        }

    def generate_password_hash(self, password: Optional[str] = None) -> str:
        """Generate a password hash."""
        password_value = password if password else self.fake.password(length=12)
        return hashlib.sha256(password_value.encode()).hexdigest()

    def generate_api_key(self) -> str:
        """Generate an API key."""
        return hashlib.sha256(
            f"{self.fake.uuid4()}{datetime.now()}".encode()
        ).hexdigest()

    def generate_users(self) -> None:
        """Generate users."""
        count = self.config["counts"]["users"]
        date_start = datetime.strptime(
            self.config["date_ranges"]["users_created_start"], "%Y-%m-%d"
        )
        date_end = datetime.strptime(
            self.config["date_ranges"]["users_created_end"], "%Y-%m-%d"
        )

        for _ in range(count):
            created_at = self.fake.date_time_between_dates(date_start, date_end)
            user = {
                "user_id": self.counters["user_id"],
                "email": self.fake.unique.email(),
                "username": self.fake.unique.user_name(),
                "password_hash": self.generate_password_hash(),
                "first_name": self.fake.first_name(),
                "last_name": self.fake.last_name(),
                "phone_number": self.fake.phone_number(),
                "country": self.fake.country_code(),
                "date_of_birth": self.fake.date_of_birth(
                    minimum_age=18, maximum_age=80
                ),
                "kyc_verified": random.choice([True, False]),
                "two_factor_enabled": random.choice([True, False]),
                "created_at": created_at,
                "updated_at": created_at + timedelta(days=random.randint(0, 30)),
                "last_login": created_at + timedelta(days=random.randint(1, 60)),
                "is_active": random.choice([True, True, True, False]),  # 75% active
                "email_verified": random.choice([True, True, False]),  # 66% verified
                "phone_verified": random.choice([True, False]),
            }
            self.users.append(user)
            self.counters["user_id"] += 1

    def generate_kyc_documents(self) -> None:
        """Generate KYC documents for verified users."""
        verified_users = [u for u in self.users if u["kyc_verified"]]

        for user in verified_users:
            doc_types = ["Passport", "Driver License", "National ID"]
            for doc_type in random.sample(doc_types, random.randint(1, 2)):
                kyc = {
                    "document_id": self.counters["kyc_id"],
                    "user_id": user["user_id"],
                    "document_type": doc_type,
                    "document_number": self.fake.uuid4()[:20],
                    "issue_date": self.fake.date_between(
                        start_date="-10y", end_date="-1y"
                    ),
                    "expiry_date": self.fake.date_between(
                        start_date="+1y", end_date="+10y"
                    ),
                    "country_of_issue": user["country"],
                    "verification_status": random.choice(
                        self.config["distributions"]["kyc_status"]
                    ),
                    "verified_at": user["created_at"]
                    + timedelta(days=random.randint(1, 7)),
                    "verified_by": f"admin_{random.randint(1, 10)}",
                    "document_hash": self.generate_api_key(),
                    "created_at": user["created_at"],
                    "updated_at": user["updated_at"],
                }
                self.kyc_documents.append(kyc)
                self.counters["kyc_id"] += 1

    def generate_currencies(self) -> None:
        """Generate cryptocurrency and fiat currencies."""
        # Major cryptocurrencies
        cryptos = [
            ("BTC", "Bitcoin", "Crypto", 8),
            ("ETH", "Ethereum", "Crypto", 18),
            ("USDT", "Tether", "Stablecoin", 6),
            ("USDC", "USD Coin", "Stablecoin", 6),
            ("BNB", "Binance Coin", "Crypto", 8),
            ("XRP", "Ripple", "Crypto", 6),
            ("ADA", "Cardano", "Crypto", 6),
            ("SOL", "Solana", "Crypto", 9),
            ("DOT", "Polkadot", "Crypto", 10),
            ("DOGE", "Dogecoin", "Crypto", 8),
        ]

        # Fiat currencies
        fiats = [
            ("USD", "US Dollar", "Fiat", 2),
            ("EUR", "Euro", "Fiat", 2),
            ("GBP", "British Pound", "Fiat", 2),
            ("JPY", "Japanese Yen", "Fiat", 0),
            ("CNY", "Chinese Yuan", "Fiat", 2),
        ]

        for symbol, name, currency_type, decimals in cryptos + fiats:
            currency = {
                "currency_id": self.counters["currency_id"],
                "symbol": symbol,
                "name": name,
                "currency_type": currency_type,
                "decimals": decimals,
                "min_withdrawal": (
                    Decimal("0.001") if currency_type != "Fiat" else Decimal("10")
                ),
                "max_withdrawal": (
                    Decimal("1000") if currency_type != "Fiat" else Decimal("100000")
                ),
                "withdrawal_fee": (
                    Decimal("0.001") if currency_type != "Fiat" else Decimal("5")
                ),
                "is_active": True,
                "created_at": datetime.now()
                - timedelta(days=random.randint(100, 1000)),
            }
            self.currencies.append(currency)
            self.counters["currency_id"] += 1

        # Add more random altcoins if needed
        remaining = self.config["counts"]["currencies"] - len(self.currencies)
        for _ in range(remaining):
            currency = {
                "currency_id": self.counters["currency_id"],
                "symbol": self.fake.unique.cryptocurrency_code(),
                "name": self.fake.company() + " Coin",
                "currency_type": "Crypto",
                "decimals": random.choice([6, 8, 9, 18]),
                "min_withdrawal": Decimal(str(random.uniform(0.001, 0.1))),
                "max_withdrawal": Decimal(str(random.uniform(100, 10000))),
                "withdrawal_fee": Decimal(str(random.uniform(0.0001, 0.01))),
                "is_active": random.choice([True, True, False]),
                "created_at": datetime.now() - timedelta(days=random.randint(30, 500)),
            }
            self.currencies.append(currency)
            self.counters["currency_id"] += 1

    def generate_trading_pairs(self) -> None:
        """Generate trading pairs."""
        # Get crypto currencies
        cryptos = [
            c for c in self.currencies if c["currency_type"] in ["Crypto", "Stablecoin"]
        ]
        fiats = [c for c in self.currencies if c["currency_type"] == "Fiat"]

        pairs_created = set()

        # Major pairs with USD/USDT
        usd = next((c for c in fiats if c["symbol"] == "USD"), None)
        usdt = next((c for c in cryptos if c["symbol"] == "USDT"), None)

        for crypto in cryptos[:20]:  # Top cryptos paired with USD/USDT
            if crypto["symbol"] not in ["USD", "USDT"]:
                if (
                    usd
                    and (crypto["currency_id"], usd["currency_id"]) not in pairs_created
                ):
                    pair = self.create_trading_pair(crypto, usd)
                    self.trading_pairs.append(pair)
                    pairs_created.add((crypto["currency_id"], usd["currency_id"]))

                if (
                    usdt
                    and (crypto["currency_id"], usdt["currency_id"])
                    not in pairs_created
                ):
                    pair = self.create_trading_pair(crypto, usdt)
                    self.trading_pairs.append(pair)
                    pairs_created.add((crypto["currency_id"], usdt["currency_id"]))

        # Add more random pairs to reach target count
        while len(self.trading_pairs) < self.config["counts"]["trading_pairs"]:
            base = random.choice(cryptos)
            quote = random.choice(cryptos + fiats)

            if (
                base["currency_id"] != quote["currency_id"]
                and (base["currency_id"], quote["currency_id"]) not in pairs_created
            ):
                pair = self.create_trading_pair(base, quote)
                self.trading_pairs.append(pair)
                pairs_created.add((base["currency_id"], quote["currency_id"]))

    def create_trading_pair(self, base: Dict, quote: Dict) -> Dict:
        """Create a trading pair."""
        pair = {
            "pair_id": self.counters["pair_id"],
            "base_currency_id": base["currency_id"],
            "quote_currency_id": quote["currency_id"],
            "symbol": f"{base['symbol']}/{quote['symbol']}",
            "min_order_size": Decimal(str(random.uniform(0.0001, 0.01))),
            "max_order_size": Decimal(str(random.uniform(100, 10000))),
            "price_precision": random.choice([2, 4, 6, 8]),
            "quantity_precision": random.choice([2, 4, 6, 8]),
            "maker_fee": Decimal(
                str(
                    random.uniform(
                        self.config["fee_ranges"]["maker_fee_min"],
                        self.config["fee_ranges"]["maker_fee_max"],
                    )
                )
            ),
            "taker_fee": Decimal(
                str(
                    random.uniform(
                        self.config["fee_ranges"]["taker_fee_min"],
                        self.config["fee_ranges"]["taker_fee_max"],
                    )
                )
            ),
            "is_active": random.choice([True, True, True, False]),  # 75% active
            "created_at": datetime.now() - timedelta(days=random.randint(30, 500)),
        }
        self.counters["pair_id"] += 1
        return pair

    def generate_wallets(self) -> None:
        """Generate wallets for users."""
        count = self.config["counts"]["wallets"]

        for _ in range(count):
            user = random.choice(self.users)
            currency = random.choice(self.currencies)

            # Generate wallet address based on currency type
            if currency["currency_type"] == "Crypto":
                address = self.fake.sha256()
            else:
                address = f"FIAT-{user['user_id']}-{currency['symbol']}"

            wallet = {
                "wallet_id": self.counters["wallet_id"],
                "user_id": user["user_id"],
                "currency_id": currency["currency_id"],
                "address": address,
                "balance": Decimal(str(random.uniform(0, 10000))),
                "locked_balance": Decimal(str(random.uniform(0, 100))),
                "wallet_type": random.choice(
                    self.config["distributions"]["wallet_types"]
                ),
                "created_at": user["created_at"]
                + timedelta(days=random.randint(0, 30)),
                "updated_at": datetime.now() - timedelta(days=random.randint(0, 30)),
            }
            self.wallets.append(wallet)
            self.counters["wallet_id"] += 1

    def generate_orders(self) -> None:
        """Generate trading orders."""
        count = self.config["counts"]["orders"]
        date_start = datetime.strptime(
            self.config["date_ranges"]["orders_start"], "%Y-%m-%d"
        )
        date_end = datetime.strptime(
            self.config["date_ranges"]["orders_end"], "%Y-%m-%d"
        )

        for _ in range(count):
            user = random.choice(self.users)
            pair = random.choice(self.trading_pairs)
            created_at = self.fake.date_time_between_dates(date_start, date_end)

            # Generate price based on pair
            if "BTC" in pair["symbol"]:
                price = Decimal(
                    str(
                        random.uniform(
                            self.config["price_ranges"]["min_btc_price"],
                            self.config["price_ranges"]["max_btc_price"],
                        )
                    )
                )
            elif "ETH" in pair["symbol"]:
                price = Decimal(
                    str(
                        random.uniform(
                            self.config["price_ranges"]["min_eth_price"],
                            self.config["price_ranges"]["max_eth_price"],
                        )
                    )
                )
            else:
                price = Decimal(
                    str(
                        random.uniform(
                            self.config["price_ranges"]["min_alt_price"],
                            self.config["price_ranges"]["max_alt_price"],
                        )
                    )
                )

            quantity = Decimal(
                str(
                    random.uniform(
                        self.config["volume_ranges"]["min_order_volume"],
                        self.config["volume_ranges"]["max_order_volume"],
                    )
                )
            )

            order_type = random.choice(self.config["distributions"]["order_types"])
            status = random.choice(self.config["distributions"]["order_status"])

            filled_quantity = Decimal("0")
            if status == "Filled":
                filled_quantity = quantity
            elif status == "Partially Filled":
                filled_quantity = quantity * Decimal(str(random.uniform(0.1, 0.9)))

            order = {
                "order_id": self.counters["order_id"],
                "user_id": user["user_id"],
                "pair_id": pair["pair_id"],
                "order_type": order_type,
                "side": random.choice(["Buy", "Sell"]),
                "status": status,
                "price": price if order_type != "Market" else None,
                "quantity": quantity,
                "filled_quantity": filled_quantity,
                "remaining_quantity": quantity - filled_quantity,
                "stop_price": price * Decimal("0.95") if "Stop" in order_type else None,
                "time_in_force": random.choice(["GTC", "IOC", "FOK"]),
                "created_at": created_at,
                "updated_at": created_at + timedelta(seconds=random.randint(0, 3600)),
                "expires_at": (
                    created_at + timedelta(days=30) if random.random() > 0.5 else None
                ),
            }
            self.orders.append(order)
            self.counters["order_id"] += 1

    def generate_trades(self) -> None:
        """Generate trades from filled orders."""
        # Get filled and partially filled orders
        filled_orders = [
            o for o in self.orders if o["status"] in ["Filled", "Partially Filled"]
        ]

        # Create trades for filled orders
        for order in filled_orders[: self.config["counts"]["trades"]]:
            pair = next(
                p for p in self.trading_pairs if p["pair_id"] == order["pair_id"]
            )

            trade = {
                "trade_id": self.counters["trade_id"],
                "pair_id": pair["pair_id"],
                "maker_order_id": order["order_id"],
                "taker_order_id": random.choice(self.orders)["order_id"],
                "price": (
                    order["price"]
                    if order["price"]
                    else self.generate_market_price(pair)
                ),
                "quantity": order["filled_quantity"],
                "maker_fee": (
                    order["filled_quantity"] * order["price"] * pair["maker_fee"]
                    if order["price"]
                    else Decimal("0")
                ),
                "taker_fee": (
                    order["filled_quantity"] * order["price"] * pair["taker_fee"]
                    if order["price"]
                    else Decimal("0")
                ),
                "timestamp": order["created_at"]
                + timedelta(seconds=random.randint(1, 300)),
            }
            self.trades.append(trade)
            self.counters["trade_id"] += 1

    def generate_market_price(self, pair: Dict) -> Decimal:
        """Generate a market price for a trading pair."""
        if "BTC" in pair["symbol"]:
            return Decimal(
                str(
                    random.uniform(
                        self.config["price_ranges"]["min_btc_price"],
                        self.config["price_ranges"]["max_btc_price"],
                    )
                )
            )
        elif "ETH" in pair["symbol"]:
            return Decimal(
                str(
                    random.uniform(
                        self.config["price_ranges"]["min_eth_price"],
                        self.config["price_ranges"]["max_eth_price"],
                    )
                )
            )
        else:
            return Decimal(
                str(
                    random.uniform(
                        self.config["price_ranges"]["min_alt_price"],
                        self.config["price_ranges"]["max_alt_price"],
                    )
                )
            )

    def generate_transactions(self) -> None:
        """Generate deposit/withdrawal transactions."""
        count = self.config["counts"]["transactions"]
        date_start = datetime.strptime(
            self.config["date_ranges"]["transactions_start"], "%Y-%m-%d"
        )
        date_end = datetime.strptime(
            self.config["date_ranges"]["transactions_end"], "%Y-%m-%d"
        )

        for _ in range(count):
            wallet = random.choice(self.wallets)
            user = next(u for u in self.users if u["user_id"] == wallet["user_id"])
            currency = next(
                c for c in self.currencies if c["currency_id"] == wallet["currency_id"]
            )

            tx_type = random.choice(self.config["distributions"]["transaction_types"])
            amount = Decimal(str(random.uniform(0.01, 1000)))

            transaction = {
                "transaction_id": self.counters["transaction_id"],
                "user_id": user["user_id"],
                "wallet_id": wallet["wallet_id"],
                "transaction_type": tx_type,
                "amount": amount,
                "fee": (
                    amount * Decimal("0.001")
                    if tx_type == "Withdrawal"
                    else Decimal("0")
                ),
                "status": random.choice(
                    self.config["distributions"]["transaction_status"]
                ),
                "blockchain_hash": (
                    self.fake.sha256()
                    if currency["currency_type"] == "Crypto"
                    else None
                ),
                "confirmations": (
                    random.randint(0, 100)
                    if currency["currency_type"] == "Crypto"
                    else None
                ),
                "from_address": (
                    self.fake.sha256() if tx_type == "Deposit" else wallet["address"]
                ),
                "to_address": (
                    self.fake.sha256() if tx_type == "Withdrawal" else wallet["address"]
                ),
                "created_at": self.fake.date_time_between_dates(date_start, date_end),
                "confirmed_at": self.fake.date_time_between_dates(date_start, date_end),
            }
            self.transactions.append(transaction)
            self.counters["transaction_id"] += 1

    def generate_price_history(self) -> None:
        """Generate price history for trading pairs."""
        count = self.config["counts"]["price_history_records"]
        date_start = datetime.strptime(
            self.config["date_ranges"]["price_history_start"], "%Y-%m-%d"
        )
        date_end = datetime.strptime(
            self.config["date_ranges"]["price_history_end"], "%Y-%m-%d"
        )

        for _ in range(count):
            pair = random.choice(self.trading_pairs)
            timestamp = self.fake.date_time_between_dates(date_start, date_end)

            base_price = self.generate_market_price(pair)

            price_record = {
                "price_id": self.counters["price_id"],
                "pair_id": pair["pair_id"],
                "open": base_price,
                "high": base_price * Decimal(str(random.uniform(1.0, 1.1))),
                "low": base_price * Decimal(str(random.uniform(0.9, 1.0))),
                "close": base_price * Decimal(str(random.uniform(0.95, 1.05))),
                "volume": Decimal(str(random.uniform(100, 100000))),
                "timestamp": timestamp,
                "interval": random.choice(["1m", "5m", "15m", "1h", "4h", "1d"]),
            }
            self.price_history.append(price_record)
            self.counters["price_id"] += 1

    def generate_api_keys(self) -> None:
        """Generate API keys for users."""
        count = self.config["counts"]["api_keys"]

        for _ in range(count):
            user = random.choice(self.users)

            api_key_data = {
                "key_id": self.counters["api_key_id"],
                "user_id": user["user_id"],
                "key_name": self.fake.word() + "_api_key",
                "api_key": self.generate_api_key(),
                "api_secret": self.generate_api_key(),
                "permissions": json.dumps(
                    random.sample(["read", "trade", "withdraw"], random.randint(1, 3))
                ),
                "ip_whitelist": json.dumps(
                    [self.fake.ipv4() for _ in range(random.randint(0, 3))]
                ),
                "is_active": random.choice([True, True, False]),
                "last_used": datetime.now() - timedelta(days=random.randint(0, 30)),
                "created_at": user["created_at"]
                + timedelta(days=random.randint(1, 100)),
                "expires_at": datetime.now() + timedelta(days=random.randint(30, 365)),
            }
            self.api_keys.append(api_key_data)
            self.counters["api_key_id"] += 1

    def generate_user_fee_tiers(self) -> None:
        """Generate user fee tiers."""
        for user in self.users:
            tier = {
                "tier_id": self.counters["fee_tier_id"],
                "user_id": user["user_id"],
                "tier_name": random.choice(self.config["distributions"]["fee_tiers"]),
                "maker_fee_discount": Decimal(str(random.uniform(0, 0.5))),
                "taker_fee_discount": Decimal(str(random.uniform(0, 0.3))),
                "volume_requirement": Decimal(str(random.uniform(0, 1000000))),
                "valid_from": user["created_at"],
                "valid_until": datetime.now() + timedelta(days=random.randint(30, 365)),
            }
            self.user_fee_tiers.append(tier)
            self.counters["fee_tier_id"] += 1

    def generate_user_trading_volumes(self) -> None:
        """Generate user trading volume records."""
        for user in self.users:
            # Generate monthly volume records
            for month_offset in range(3):
                period_start = datetime.now() - timedelta(days=30 * (month_offset + 1))

                volume = {
                    "volume_id": self.counters["volume_id"],
                    "user_id": user["user_id"],
                    "period_start": period_start,
                    "period_end": period_start + timedelta(days=30),
                    "spot_volume": Decimal(str(random.uniform(0, 100000))),
                    "futures_volume": Decimal(str(random.uniform(0, 50000))),
                    "total_volume": Decimal(str(random.uniform(0, 150000))),
                    "created_at": period_start + timedelta(days=30),
                }
                self.user_trading_volumes.append(volume)
                self.counters["volume_id"] += 1

    def generate(self) -> None:
        """Generate all data."""
        print("Generating users...")
        self.generate_users()

        print("Generating KYC documents...")
        self.generate_kyc_documents()

        print("Generating currencies...")
        self.generate_currencies()

        print("Generating trading pairs...")
        self.generate_trading_pairs()

        print("Generating wallets...")
        self.generate_wallets()

        print("Generating orders...")
        self.generate_orders()

        print("Generating trades...")
        self.generate_trades()

        print("Generating transactions...")
        self.generate_transactions()

        print("Generating price history...")
        self.generate_price_history()

        print("Generating API keys...")
        self.generate_api_keys()

        print("Generating user fee tiers...")
        self.generate_user_fee_tiers()

        print("Generating user trading volumes...")
        self.generate_user_trading_volumes()

    def export_to_csv(self, output_dir: str) -> None:
        """Export all data to CSV files."""
        output_path = Path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)

        datasets = {
            "users": self.users,
            "kyc_documents": self.kyc_documents,
            "currencies": self.currencies,
            "trading_pairs": self.trading_pairs,
            "wallets": self.wallets,
            "orders": self.orders,
            "trades": self.trades,
            "transactions": self.transactions,
            "price_history": self.price_history,
            "api_keys": self.api_keys,
            "user_fee_tiers": self.user_fee_tiers,
            "user_trading_volumes": self.user_trading_volumes,
        }

        for name, data in datasets.items():
            if data:
                file_path = output_path / f"{name}.csv"
                with open(file_path, "w", newline="", encoding="utf-8") as f:
                    writer = csv.DictWriter(f, fieldnames=data[0].keys())
                    writer.writeheader()
                    writer.writerows(data)
                print(f"Exported {len(data)} records to {file_path}")

    def export_to_sql(self, output_file: str) -> None:
        """Export all data to SQL insert statements."""
        with open(output_file, "w", encoding="utf-8") as f:
            # Write header
            f.write("-- Cryptocurrency Exchange Sample Data\n")
            f.write(f"-- Generated at {datetime.now()}\n\n")

            # Export each dataset
            self._write_sql_inserts(f, "users", self.users)
            self._write_sql_inserts(f, "kyc_documents", self.kyc_documents)
            self._write_sql_inserts(f, "currencies", self.currencies)
            self._write_sql_inserts(f, "trading_pairs", self.trading_pairs)
            self._write_sql_inserts(f, "wallets", self.wallets)
            self._write_sql_inserts(f, "orders", self.orders)
            self._write_sql_inserts(f, "trades", self.trades)
            self._write_sql_inserts(f, "transactions", self.transactions)
            self._write_sql_inserts(f, "price_history", self.price_history)
            self._write_sql_inserts(f, "api_keys", self.api_keys)
            self._write_sql_inserts(f, "user_fee_tiers", self.user_fee_tiers)
            self._write_sql_inserts(
                f, "user_trading_volumes", self.user_trading_volumes
            )

    def _write_sql_inserts(self, f, table_name: str, data: List[Dict]) -> None:
        """Write SQL insert statements for a table."""
        if not data:
            return

        f.write(f"\n-- {table_name}\n")
        for record in data:
            columns = ", ".join(record.keys())
            values = []
            for value in record.values():
                if value is None:
                    values.append("NULL")
                elif isinstance(value, (int, float, Decimal)):
                    values.append(str(value))
                elif isinstance(value, bool):
                    values.append("1" if value else "0")
                elif isinstance(value, (datetime, date)):
                    values.append(f"'{value}'")
                else:
                    # Escape single quotes in strings
                    escaped = str(value).replace("'", "''")
                    values.append(f"'{escaped}'")

            values_str = ", ".join(values)
            f.write(f"INSERT INTO {table_name} ({columns}) VALUES ({values_str});\n")


if __name__ == "__main__":
    # Example usage
    generator = CryptocurrencyDataGenerator()
    generator.generate()
    generator.export_to_csv("output")
    generator.export_to_sql("output/inserts.sql")
