#!/usr/bin/env python3
"""
Cryptocurrency Exchange Data Generator

Generates realistic test data for the cryptocurrency exchange database.
Includes users, KYC data, wallets, orders, trades, and market data.
"""

import random
import sys
import os
from datetime import datetime, timedelta
from decimal import Decimal
from typing import List, Dict, Tuple, Optional
import hashlib
import secrets

# Add parent directory to path for base generator
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from generators.base_generator import BaseGenerator

class CryptocurrencyExchangeGenerator(BaseGenerator):
    """Generator for Cryptocurrency Exchange data"""

    def __init__(self, host='localhost', port=3336, user='crypto_admin',
                 password='crypto_pass_2024', database='crypto_exchange'):
        """Initialize the cryptocurrency exchange generator"""
        super().__init__(host, port, user, password, database)

        # Cryptocurrency pairs and data
        self.crypto_symbols = [
            'BTC', 'ETH', 'BNB', 'XRP', 'ADA', 'SOL', 'DOGE', 'DOT',
            'MATIC', 'LTC', 'SHIB', 'TRX', 'AVAX', 'LINK', 'ATOM', 'XLM',
            'ALGO', 'VET', 'NEAR', 'FTM'
        ]

        self.fiat_currencies = ['USD', 'EUR', 'GBP', 'JPY', 'AUD', 'CAD']

        self.trading_pairs = []
        for crypto in self.crypto_symbols:
            for fiat in self.fiat_currencies[:3]:  # Main pairs with USD, EUR, GBP
                self.trading_pairs.append(f"{crypto}/{fiat}")
            # Add some crypto-to-crypto pairs
            if crypto != 'BTC':
                self.trading_pairs.append(f"{crypto}/BTC")
            if crypto not in ['ETH', 'BTC']:
                self.trading_pairs.append(f"{crypto}/ETH")

        # User tiers and limits
        self.kyc_levels = ['basic', 'verified', 'premium', 'institutional']
        self.user_tiers = {
            'basic': {'daily_limit': 1000, 'monthly_limit': 5000},
            'verified': {'daily_limit': 10000, 'monthly_limit': 100000},
            'premium': {'daily_limit': 100000, 'monthly_limit': 1000000},
            'institutional': {'daily_limit': 10000000, 'monthly_limit': 100000000}
        }

        # Market volatility settings
        self.volatility = {
            'BTC': 0.03,
            'ETH': 0.04,
            'default': 0.05
        }

    def generate_all_data(self, users: int = 10000, orders_per_user: int = 50):
        """Generate all cryptocurrency exchange data"""
        print("Starting Cryptocurrency Exchange data generation...")

        # Generate base data
        print("Generating users...")
        self.generate_users(users)

        print("Generating KYC data...")
        self.generate_kyc_data()

        print("Generating currencies and trading pairs...")
        self.generate_currencies()
        self.generate_trading_pairs()

        print("Generating wallets...")
        self.generate_wallets()

        print("Generating API keys...")
        self.generate_api_keys()

        print("Generating price history...")
        self.generate_price_history()

        print("Generating orders and trades...")
        self.generate_orders_and_trades(orders_per_user)

        print("Generating transactions...")
        self.generate_transactions()

        print("Generating staking positions...")
        self.generate_staking()

        print("Generating notifications and audit logs...")
        self.generate_notifications()
        self.generate_audit_logs()

        print("Generation complete!")

    def generate_users(self, count: int = 10000):
        """Generate cryptocurrency exchange users"""
        users = []

        for i in range(count):
            # Determine user type distribution
            user_type = self.faker.random_element([
                ('individual', 0.85),
                ('corporate', 0.10),
                ('institutional', 0.05)
            ])

            email = self.faker.email()
            username = self.faker.user_name() + str(random.randint(100, 9999))

            # Hash password (simplified)
            password_hash = hashlib.sha256(f"password{i}".encode()).hexdigest()

            # Determine account status
            status = self.faker.random_element([
                ('active', 0.80),
                ('suspended', 0.05),
                ('pending_verification', 0.10),
                ('closed', 0.05)
            ])

            # KYC level based on user type
            if user_type == 'institutional':
                kyc_level = 'institutional'
            elif user_type == 'corporate':
                kyc_level = self.faker.random_element(['verified', 'premium'])
            else:
                kyc_level = self.faker.random_element(self.kyc_levels[:3])

            # Generate user data
            user = (
                email,
                username,
                password_hash,
                user_type,
                self.faker.first_name() if user_type == 'individual' else None,
                self.faker.last_name() if user_type == 'individual' else None,
                self.faker.company() if user_type != 'individual' else None,
                self.faker.phone_number(),
                self.faker.country_code(),
                self.faker.random_element(['google', 'email', 'sms']),
                random.choice([0, 1]),  # 2fa_enabled
                secrets.token_hex(16) if random.random() > 0.5 else None,  # 2fa_secret
                kyc_level,
                random.choice([0, 1]) if kyc_level in ['verified', 'premium', 'institutional'] else 0,  # kyc_verified
                self.faker.date_time_between('-1 year', '-1 day') if kyc_level != 'basic' else None,
                self.user_tiers[kyc_level]['daily_limit'],
                self.user_tiers[kyc_level]['monthly_limit'],
                random.choice([0, 1]),  # marketing_consent
                self.faker.random_element(['en', 'es', 'zh', 'ja', 'de', 'fr']),
                self.faker.timezone(),
                status,
                None,  # suspended_reason
                self.faker.ipv4(),
                self.faker.date_time_between('-2 years', 'now'),
                None,  # last_login
                self.faker.date_time_between('-2 years', 'now')  # created_at
            )
            users.append(user)

            if (i + 1) % 1000 == 0:
                self.bulk_insert('users', users, [
                    'email', 'username', 'password_hash', 'user_type',
                    'first_name', 'last_name', 'company_name', 'phone_number',
                    'country_code', 'preferred_2fa', '2fa_enabled', '2fa_secret',
                    'kyc_level', 'kyc_verified', 'kyc_verified_date',
                    'daily_limit', 'monthly_limit', 'marketing_consent',
                    'language', 'timezone', 'status', 'suspended_reason',
                    'last_ip', 'last_activity', 'last_login', 'created_at'
                ])
                users = []
                print(f"  Generated {i + 1}/{count} users...")

        # Insert remaining users
        if users:
            self.bulk_insert('users', users, [
                'email', 'username', 'password_hash', 'user_type',
                'first_name', 'last_name', 'company_name', 'phone_number',
                'country_code', 'preferred_2fa', '2fa_enabled', '2fa_secret',
                'kyc_level', 'kyc_verified', 'kyc_verified_date',
                'daily_limit', 'monthly_limit', 'marketing_consent',
                'language', 'timezone', 'status', 'suspended_reason',
                'last_ip', 'last_activity', 'last_login', 'created_at'
            ])

    def generate_kyc_data(self):
        """Generate KYC verification data"""
        # Get verified users
        verified_users = self.fetch_all("""
            SELECT user_id FROM users
            WHERE kyc_level IN ('verified', 'premium', 'institutional')
            AND kyc_verified = 1
        """)

        kyc_documents = []

        for user in verified_users:
            user_id = user['user_id']

            # Generate 1-3 documents per user
            num_docs = random.randint(1, 3)

            for _ in range(num_docs):
                document = (
                    user_id,
                    self.faker.random_element([
                        'passport', 'drivers_license', 'national_id',
                        'utility_bill', 'bank_statement', 'corporate_docs'
                    ]),
                    self.faker.random_element(['pending', 'approved', 'rejected']),
                    f"doc_{user_id}_{secrets.token_hex(8)}.pdf",
                    hashlib.sha256(f"doc_{user_id}".encode()).hexdigest(),
                    self.faker.date_time_between('-6 months', 'now'),
                    self.faker.date_time_between('-6 months', 'now') if random.random() > 0.3 else None,
                    None if random.random() > 0.1 else self.faker.sentence(),
                    self.faker.date_time_between('-1 year', 'now')
                )
                kyc_documents.append(document)

        self.bulk_insert('kyc_documents', kyc_documents, [
            'user_id', 'document_type', 'verification_status',
            'document_url', 'document_hash', 'submitted_at',
            'verified_at', 'rejection_reason', 'created_at'
        ])

    def generate_currencies(self):
        """Generate cryptocurrency and fiat currency data"""
        currencies = []

        # Add cryptocurrencies
        crypto_data = {
            'BTC': ('Bitcoin', 8, 21000000),
            'ETH': ('Ethereum', 18, None),
            'BNB': ('Binance Coin', 18, 200000000),
            'XRP': ('Ripple', 6, 100000000000),
            'ADA': ('Cardano', 6, 45000000000),
            'SOL': ('Solana', 9, 511616946),
            'DOGE': ('Dogecoin', 8, None),
            'DOT': ('Polkadot', 10, None),
            'MATIC': ('Polygon', 18, 10000000000),
            'LTC': ('Litecoin', 8, 84000000)
        }

        for symbol, (name, decimals, max_supply) in crypto_data.items():
            currency = (
                symbol,
                name,
                'crypto',
                decimals,
                random.choice([0, 1]),  # is_active
                random.choice([0, 1]),  # deposit_enabled
                random.choice([0, 1]),  # withdrawal_enabled
                random.uniform(0.0001, 0.01),  # min_deposit
                random.uniform(0.001, 0.1),  # min_withdrawal
                random.uniform(0.0001, 0.001),  # withdrawal_fee
                random.randint(1, 12),  # confirmations_required
                None,  # contract_address for tokens
                max_supply,
                self.faker.date_time_between('-3 years', 'now')
            )
            currencies.append(currency)

        # Add fiat currencies
        for symbol in self.fiat_currencies:
            currency = (
                symbol,
                f"{symbol} Dollar" if symbol == 'USD' else symbol,
                'fiat',
                2,
                1,  # is_active
                1,  # deposit_enabled
                1,  # withdrawal_enabled
                10.00,  # min_deposit
                50.00,  # min_withdrawal
                0.00,  # withdrawal_fee
                0,  # confirmations_required
                None,
                None,
                self.faker.date_time_between('-3 years', 'now')
            )
            currencies.append(currency)

        self.bulk_insert('currencies', currencies, [
            'symbol', 'name', 'currency_type', 'decimal_places',
            'is_active', 'deposit_enabled', 'withdrawal_enabled',
            'min_deposit', 'min_withdrawal', 'withdrawal_fee',
            'confirmations_required', 'contract_address', 'max_supply',
            'created_at'
        ])

    def generate_trading_pairs(self):
        """Generate trading pairs"""
        pairs = []

        for pair in self.trading_pairs[:50]:  # Limit to 50 most popular pairs
            base, quote = pair.split('/')

            # Determine if it's a major pair
            is_major = base in ['BTC', 'ETH'] and quote == 'USD'

            trading_pair = (
                base,
                quote,
                pair,
                random.choice([0, 1]),  # is_active
                random.uniform(0.0001, 1) if base == 'BTC' else random.uniform(0.00001, 0.1),
                random.uniform(100, 1000000) if base == 'BTC' else random.uniform(10, 100000),
                random.uniform(0.0001, 0.001) if is_major else random.uniform(0.001, 0.003),
                random.uniform(0.0001, 0.001) if is_major else random.uniform(0.001, 0.003),
                8 if base == 'BTC' else 4,  # price_precision
                8 if base == 'BTC' else 2,  # quantity_precision
                self.faker.date_time_between('-2 years', 'now')
            )
            pairs.append(trading_pair)

        self.bulk_insert('trading_pairs', pairs, [
            'base_currency', 'quote_currency', 'symbol',
            'is_active', 'min_order_size', 'max_order_size',
            'maker_fee', 'taker_fee', 'price_precision',
            'quantity_precision', 'created_at'
        ])

    def generate_wallets(self):
        """Generate user wallets"""
        users = self.fetch_all("SELECT user_id FROM users")
        currencies = self.fetch_all("SELECT symbol FROM currencies WHERE is_active = 1")

        wallets = []

        for user in users:
            # Each user gets 3-8 wallets
            num_wallets = random.randint(3, min(8, len(currencies)))
            user_currencies = random.sample(currencies, num_wallets)

            for currency in user_currencies:
                # Generate wallet address
                address = '0x' + secrets.token_hex(20) if currency['symbol'] in ['ETH', 'MATIC'] else \
                         secrets.token_hex(32)

                # Random balance based on currency
                if currency['symbol'] == 'BTC':
                    balance = random.uniform(0, 10)
                    available = balance * random.uniform(0.8, 1.0)
                elif currency['symbol'] == 'ETH':
                    balance = random.uniform(0, 100)
                    available = balance * random.uniform(0.8, 1.0)
                elif currency['symbol'] in self.fiat_currencies:
                    balance = random.uniform(0, 100000)
                    available = balance * random.uniform(0.9, 1.0)
                else:
                    balance = random.uniform(0, 10000)
                    available = balance * random.uniform(0.7, 1.0)

                wallet = (
                    user['user_id'],
                    currency['symbol'],
                    address,
                    balance,
                    available,
                    balance - available,  # locked_balance
                    self.faker.date_time_between('-2 years', 'now'),
                    self.faker.date_time_between('-1 year', 'now')
                )
                wallets.append(wallet)

        self.bulk_insert('wallets', wallets, [
            'user_id', 'currency', 'address', 'balance',
            'available_balance', 'locked_balance', 'created_at',
            'updated_at'
        ])

    def generate_price_history(self):
        """Generate historical price data"""
        pairs = self.fetch_all("SELECT pair_id, symbol, base_currency FROM trading_pairs WHERE is_active = 1")

        price_history = []

        for pair in pairs[:20]:  # Limit to top 20 pairs for performance
            # Generate 30 days of hourly data
            current_time = datetime.now()

            # Set initial price based on currency
            if pair['base_currency'] == 'BTC':
                price = 45000.0
            elif pair['base_currency'] == 'ETH':
                price = 3000.0
            else:
                price = random.uniform(0.01, 100)

            for days_ago in range(30, 0, -1):
                for hour in range(24):
                    timestamp = current_time - timedelta(days=days_ago, hours=hour)

                    # Apply volatility
                    volatility = self.volatility.get(pair['base_currency'], self.volatility['default'])
                    price_change = random.uniform(-volatility, volatility)
                    price *= (1 + price_change)

                    # Generate OHLCV data
                    open_price = price
                    high = price * random.uniform(1.0, 1.02)
                    low = price * random.uniform(0.98, 1.0)
                    close = random.uniform(low, high)
                    volume = random.uniform(100, 100000) if pair['base_currency'] == 'BTC' else random.uniform(10, 10000)

                    history = (
                        pair['pair_id'],
                        '1h',  # interval
                        timestamp,
                        open_price,
                        high,
                        low,
                        close,
                        volume,
                        random.randint(10, 1000)  # trades
                    )
                    price_history.append(history)

                    price = close  # Next candle opens at previous close

                    if len(price_history) >= 1000:
                        self.bulk_insert('price_history', price_history, [
                            'pair_id', 'interval', 'timestamp', 'open',
                            'high', 'low', 'close', 'volume', 'trades'
                        ])
                        price_history = []

        # Insert remaining history
        if price_history:
            self.bulk_insert('price_history', price_history, [
                'pair_id', 'interval', 'timestamp', 'open',
                'high', 'low', 'close', 'volume', 'trades'
            ])

    def generate_orders_and_trades(self, orders_per_user: int = 50):
        """Generate orders and trades"""
        users = self.fetch_all("SELECT user_id FROM users WHERE status = 'active' LIMIT 1000")
        pairs = self.fetch_all("SELECT * FROM trading_pairs WHERE is_active = 1")

        orders = []
        trades = []
        order_id_counter = 1
        trade_id_counter = 1

        for user in users:
            num_orders = random.randint(10, orders_per_user)

            for _ in range(num_orders):
                pair = random.choice(pairs)

                # Order details
                order_type = self.faker.random_element([
                    ('market', 0.4),
                    ('limit', 0.5),
                    ('stop_loss', 0.05),
                    ('stop_limit', 0.05)
                ])

                side = random.choice(['buy', 'sell'])

                # Get current price (simplified)
                if pair['base_currency'] == 'BTC':
                    current_price = 45000.0 + random.uniform(-5000, 5000)
                elif pair['base_currency'] == 'ETH':
                    current_price = 3000.0 + random.uniform(-500, 500)
                else:
                    current_price = random.uniform(0.01, 100)

                quantity = random.uniform(0.001, 10) if pair['base_currency'] == 'BTC' else random.uniform(0.1, 1000)

                if order_type == 'limit':
                    price = current_price * random.uniform(0.95, 1.05)
                else:
                    price = None

                # Order status
                status = self.faker.random_element([
                    ('filled', 0.6),
                    ('partially_filled', 0.1),
                    ('open', 0.15),
                    ('cancelled', 0.15)
                ])

                filled_quantity = quantity if status == 'filled' else \
                                quantity * random.uniform(0.1, 0.9) if status == 'partially_filled' else 0

                order_time = self.faker.date_time_between('-30 days', 'now')

                order = (
                    user['user_id'],
                    pair['pair_id'],
                    order_type,
                    side,
                    quantity,
                    price,
                    None,  # stop_price
                    status,
                    filled_quantity,
                    quantity - filled_quantity,
                    pair['taker_fee'] if order_type == 'market' else pair['maker_fee'],
                    order_time,
                    order_time + timedelta(seconds=random.randint(1, 300)) if status in ['filled', 'partially_filled'] else None
                )
                orders.append(order)

                # Generate trades for filled orders
                if status in ['filled', 'partially_filled'] and filled_quantity > 0:
                    trade = (
                        order_id_counter,
                        pair['pair_id'],
                        user['user_id'] if side == 'buy' else None,
                        user['user_id'] if side == 'sell' else None,
                        price if price else current_price,
                        filled_quantity,
                        pair['taker_fee'],
                        pair['maker_fee'],
                        order_time + timedelta(seconds=random.randint(1, 10))
                    )
                    trades.append(trade)
                    trade_id_counter += 1

                order_id_counter += 1

                if len(orders) >= 1000:
                    self.bulk_insert('orders', orders, [
                        'user_id', 'pair_id', 'order_type', 'side',
                        'quantity', 'price', 'stop_price', 'status',
                        'filled_quantity', 'remaining_quantity', 'fee_rate',
                        'created_at', 'updated_at'
                    ])
                    orders = []

                if len(trades) >= 1000:
                    self.bulk_insert('trades', trades, [
                        'order_id', 'pair_id', 'buyer_user_id', 'seller_user_id',
                        'price', 'quantity', 'buyer_fee', 'seller_fee',
                        'created_at'
                    ])
                    trades = []

        # Insert remaining data
        if orders:
            self.bulk_insert('orders', orders, [
                'user_id', 'pair_id', 'order_type', 'side',
                'quantity', 'price', 'stop_price', 'status',
                'filled_quantity', 'remaining_quantity', 'fee_rate',
                'created_at', 'updated_at'
            ])

        if trades:
            self.bulk_insert('trades', trades, [
                'order_id', 'pair_id', 'buyer_user_id', 'seller_user_id',
                'price', 'quantity', 'buyer_fee', 'seller_fee',
                'created_at'
            ])

    def generate_transactions(self):
        """Generate deposit and withdrawal transactions"""
        wallets = self.fetch_all("""
            SELECT w.*, u.user_id
            FROM wallets w
            JOIN users u ON w.user_id = u.user_id
            WHERE u.status = 'active'
            LIMIT 500
        """)

        transactions = []

        for wallet in wallets:
            # Generate 1-5 transactions per wallet
            num_transactions = random.randint(1, 5)

            for _ in range(num_transactions):
                tx_type = random.choice(['deposit', 'withdrawal'])

                if tx_type == 'deposit':
                    amount = random.uniform(10, 10000) if wallet['currency'] in self.fiat_currencies else \
                            random.uniform(0.001, 10)
                    status = self.faker.random_element([
                        ('completed', 0.8),
                        ('pending', 0.15),
                        ('failed', 0.05)
                    ])
                else:
                    # Withdrawal - check balance
                    max_amount = float(wallet['available_balance']) * 0.5 if wallet['available_balance'] else 0
                    if max_amount <= 0:
                        continue
                    amount = random.uniform(0, max_amount)
                    status = self.faker.random_element([
                        ('completed', 0.7),
                        ('pending', 0.2),
                        ('failed', 0.05),
                        ('cancelled', 0.05)
                    ])

                transaction = (
                    wallet['user_id'],
                    wallet['currency'],
                    tx_type,
                    amount,
                    0 if tx_type == 'deposit' else amount * 0.001,  # fee
                    status,
                    '0x' + secrets.token_hex(32) if wallet['currency'] not in self.fiat_currencies else None,
                    wallet['address'] if tx_type == 'deposit' else '0x' + secrets.token_hex(20),
                    wallet['address'] if tx_type == 'withdrawal' else None,
                    random.randint(1, 12) if status == 'completed' else 0,
                    self.faker.date_time_between('-30 days', 'now'),
                    self.faker.date_time_between('-30 days', 'now') if status == 'completed' else None
                )
                transactions.append(transaction)

        self.bulk_insert('transactions', transactions, [
            'user_id', 'currency', 'transaction_type', 'amount',
            'fee', 'status', 'tx_hash', 'from_address', 'to_address',
            'confirmations', 'created_at', 'completed_at'
        ])

    def generate_staking(self):
        """Generate staking positions"""
        # Only certain currencies support staking
        stakeable = ['ADA', 'DOT', 'SOL', 'ATOM', 'ALGO']

        users = self.fetch_all("SELECT user_id FROM users WHERE status = 'active' LIMIT 200")

        staking_positions = []

        for user in users:
            if random.random() > 0.3:  # 70% of users stake
                currency = random.choice(stakeable)

                position = (
                    user['user_id'],
                    currency,
                    random.uniform(100, 10000),
                    random.uniform(0.04, 0.12),  # APY 4-12%
                    random.choice(['flexible', 'locked_30', 'locked_60', 'locked_90']),
                    'active',
                    0,  # rewards_earned (would be calculated)
                    self.faker.date_time_between('-60 days', 'now'),
                    None,  # unstaked_at
                    self.faker.date_time_between('-60 days', 'now')
                )
                staking_positions.append(position)

        self.bulk_insert('staking_positions', staking_positions, [
            'user_id', 'currency', 'amount', 'apy', 'lock_period',
            'status', 'rewards_earned', 'staked_at', 'unstaked_at',
            'created_at'
        ])

    def generate_api_keys(self):
        """Generate API keys for users"""
        users = self.fetch_all("SELECT user_id FROM users WHERE kyc_verified = 1 LIMIT 100")

        api_keys = []

        for user in users:
            if random.random() > 0.5:  # 50% of verified users have API keys
                num_keys = random.randint(1, 3)

                for i in range(num_keys):
                    key = (
                        user['user_id'],
                        f"Exchange API Key {i+1}",
                        secrets.token_hex(32),
                        secrets.token_hex(64),
                        self.faker.random_element(['read', 'trade', 'withdraw']),
                        ','.join(random.sample(['trading', 'account', 'market_data'], random.randint(1, 3))),
                        self.faker.ipv4() if random.random() > 0.5 else None,
                        random.choice([0, 1]),
                        self.faker.date_time_between('-30 days', 'now') if random.random() > 0.7 else None,
                        0,  # total_requests
                        self.faker.date_time_between('-90 days', 'now')
                    )
                    api_keys.append(key)

        self.bulk_insert('api_keys', api_keys, [
            'user_id', 'key_name', 'api_key', 'secret_key',
            'permission_level', 'allowed_operations', 'ip_whitelist',
            'is_active', 'last_used', 'total_requests', 'created_at'
        ])

    def generate_notifications(self):
        """Generate user notifications"""
        users = self.fetch_all("SELECT user_id FROM users WHERE status = 'active' LIMIT 500")

        notifications = []
        notification_types = [
            'trade_executed', 'deposit_received', 'withdrawal_completed',
            'kyc_approved', 'price_alert', 'security_alert', 'news_update'
        ]

        for user in users:
            num_notifications = random.randint(1, 10)

            for _ in range(num_notifications):
                notification = (
                    user['user_id'],
                    random.choice(notification_types),
                    self.faker.sentence(),
                    self.faker.text(max_nb_chars=200),
                    random.choice(['low', 'medium', 'high']),
                    random.choice([0, 1]),  # is_read
                    self.faker.date_time_between('-30 days', 'now')
                )
                notifications.append(notification)

        self.bulk_insert('notifications', notifications, [
            'user_id', 'notification_type', 'title', 'message',
            'priority', 'is_read', 'created_at'
        ])

    def generate_audit_logs(self):
        """Generate audit logs"""
        users = self.fetch_all("SELECT user_id FROM users LIMIT 200")

        audit_logs = []
        actions = [
            'login', 'logout', 'password_change', '2fa_enabled',
            'api_key_created', 'withdrawal_request', 'trade_placed',
            'kyc_submitted', 'profile_updated'
        ]

        for user in users:
            num_logs = random.randint(5, 20)

            for _ in range(num_logs):
                log = (
                    user['user_id'],
                    random.choice(actions),
                    self.faker.ipv4(),
                    self.faker.user_agent(),
                    None,  # details
                    self.faker.date_time_between('-90 days', 'now')
                )
                audit_logs.append(log)

        self.bulk_insert('audit_logs', audit_logs, [
            'user_id', 'action', 'ip_address', 'user_agent',
            'details', 'created_at'
        ])


def main():
    """Main function to run the generator"""
    import argparse

    parser = argparse.ArgumentParser(description='Generate test data for Cryptocurrency Exchange')
    parser.add_argument('--host', default='localhost', help='MySQL host')
    parser.add_argument('--port', type=int, default=3336, help='MySQL port')
    parser.add_argument('--user', default='crypto_admin', help='MySQL user')
    parser.add_argument('--password', default='crypto_pass_2024', help='MySQL password')
    parser.add_argument('--database', default='crypto_exchange', help='MySQL database')
    parser.add_argument('--users', type=int, default=10000, help='Number of users to generate')
    parser.add_argument('--orders-per-user', type=int, default=50, help='Average orders per user')

    args = parser.parse_args()

    generator = CryptocurrencyExchangeGenerator(
        host=args.host,
        port=args.port,
        user=args.user,
        password=args.password,
        database=args.database
    )

    try:
        generator.connect()
        generator.generate_all_data(
            users=args.users,
            orders_per_user=args.orders_per_user
        )
    finally:
        generator.disconnect()


if __name__ == '__main__':
    main()