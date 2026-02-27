#!/usr/bin/env python3
"""
Demonstration of Cryptocurrency Exchange Generator

This script demonstrates the generator's data creation logic without
requiring an actual database connection.
"""

import random
import hashlib
import secrets
from datetime import datetime, timedelta
from faker import Faker

# Initialize Faker
faker = Faker()
Faker.seed(42)
random.seed(42)


def demonstrate_generator():
    """Demonstrate the cryptocurrency exchange data generation"""

    print("=" * 70)
    print("CRYPTOCURRENCY EXCHANGE DATA GENERATOR DEMONSTRATION")
    print("=" * 70)

    # Cryptocurrency data
    crypto_symbols = ["BTC", "ETH", "BNB", "XRP", "ADA", "SOL"]
    fiat_currencies = ["USD", "EUR", "GBP"]

    # User tiers and limits
    user_tiers = {
        "basic": {"daily_limit": 1000, "monthly_limit": 5000},
        "verified": {"daily_limit": 10000, "monthly_limit": 100000},
        "premium": {"daily_limit": 100000, "monthly_limit": 1000000},
    }

    print("\n1. GENERATING SAMPLE USERS")
    print("-" * 50)

    users = []
    for i in range(5):  # Generate 5 sample users
        user_type = random.choice(["individual", "corporate"])
        kyc_level = random.choice(list(user_tiers.keys()))

        user = {
            "user_id": i + 1,
            "email": faker.email(),
            "username": faker.user_name() + str(random.randint(100, 999)),
            "user_type": user_type,
            "first_name": faker.first_name() if user_type == "individual" else None,
            "last_name": faker.last_name() if user_type == "individual" else None,
            "company_name": faker.company() if user_type == "corporate" else None,
            "kyc_level": kyc_level,
            "daily_limit": user_tiers[kyc_level]["daily_limit"],
            "monthly_limit": user_tiers[kyc_level]["monthly_limit"],
            "country_code": faker.country_code(),
            "status": "active",
            "created_at": faker.date_time_between(start_date="-365d", end_date="now"),
        }
        users.append(user)

        print(f"User #{user['user_id']}: {user['username']} ({user['email']})")
        print(
            f"  Type: {user['user_type']}, KYC: {user['kyc_level']}, "
            f"Daily Limit: ${user['daily_limit']:,}"
        )

    print("\n2. GENERATING CURRENCIES AND TRADING PAIRS")
    print("-" * 50)

    # Generate currencies
    currencies = []
    for symbol in crypto_symbols:
        currency = {
            "symbol": symbol,
            "name": f"{symbol} Token",
            "type": "crypto",
            "decimal_places": 8,
            "min_withdrawal": random.uniform(0.001, 0.1),
        }
        currencies.append(currency)
        print(f"Crypto: {symbol} - Min withdrawal: {currency['min_withdrawal']:.4f}")

    for symbol in fiat_currencies:
        currency = {
            "symbol": symbol,
            "name": f"{symbol} Dollar",
            "type": "fiat",
            "decimal_places": 2,
            "min_withdrawal": 50.00,
        }
        currencies.append(currency)
        print(f"Fiat: {symbol} - Min withdrawal: ${currency['min_withdrawal']:.2f}")

    # Generate trading pairs
    print("\n3. GENERATING TRADING PAIRS")
    print("-" * 50)

    trading_pairs = []
    for crypto in crypto_symbols[:3]:  # Top 3 cryptos
        for fiat in fiat_currencies[:2]:  # USD and EUR
            pair = {
                "symbol": f"{crypto}/{fiat}",
                "base": crypto,
                "quote": fiat,
                "min_order": random.uniform(0.0001, 0.01),
                "maker_fee": 0.001,
                "taker_fee": 0.002,
            }
            trading_pairs.append(pair)
            print(f"Pair: {pair['symbol']} - Min order: {pair['min_order']:.6f}")

    print("\n4. GENERATING WALLETS")
    print("-" * 50)

    wallets = []
    for user in users[:3]:  # First 3 users
        # Each user gets 2-3 wallets
        user_currencies = random.sample(crypto_symbols + fiat_currencies, 3)

        for currency in user_currencies:
            if currency in crypto_symbols:
                # Crypto wallet
                address = "0x" + secrets.token_hex(20)
                balance = (
                    random.uniform(0, 10)
                    if currency == "BTC"
                    else random.uniform(0, 100)
                )
            else:
                # Fiat wallet
                address = "FIAT_" + str(random.randint(100000, 999999))
                balance = random.uniform(0, 10000)

            wallet = {
                "user_id": user["user_id"],
                "currency": currency,
                "address": address[:20] + "...",  # Truncated for display
                "balance": balance,
                "available": balance * 0.9,
            }
            wallets.append(wallet)
            print(
                f"User #{user['user_id']} - {currency}: {balance:.4f} "
                f"(Available: {wallet['available']:.4f})"
            )

    print("\n5. GENERATING SAMPLE ORDERS AND TRADES")
    print("-" * 50)

    orders = []
    trades = []
    order_id = 1

    for user in users[:3]:
        # Each user places 2 orders
        for _ in range(2):
            pair = random.choice(trading_pairs)
            order_type = random.choice(["market", "limit"])
            side = random.choice(["buy", "sell"])

            # Simplified price calculation
            if pair["base"] == "BTC":
                price = 45000 + random.uniform(-5000, 5000)
            elif pair["base"] == "ETH":
                price = 3000 + random.uniform(-500, 500)
            else:
                price = random.uniform(1, 100)

            quantity = random.uniform(0.001, 1)
            status = random.choice(["filled", "open", "cancelled"])

            order = {
                "order_id": order_id,
                "user_id": user["user_id"],
                "pair": pair["symbol"],
                "type": order_type,
                "side": side,
                "quantity": quantity,
                "price": price if order_type == "limit" else None,
                "status": status,
            }
            orders.append(order)

            print(
                f"Order #{order_id}: {side.upper()} {quantity:.4f} {pair['base']} "
                f"@ ${price:.2f} - Status: {status}"
            )

            # Generate trade if order is filled
            if status == "filled":
                trade = {
                    "trade_id": len(trades) + 1,
                    "order_id": order_id,
                    "price": price,
                    "quantity": quantity,
                    "fee": quantity * price * pair["taker_fee"],
                }
                trades.append(trade)

            order_id += 1

    print("\n6. GENERATING PRICE HISTORY")
    print("-" * 50)

    # Generate sample price history for BTC/USD
    price_history = []
    current_price = 45000.0

    for days_ago in range(7, 0, -1):
        timestamp = datetime.now() - timedelta(days=days_ago)

        # Daily price movement
        volatility = 0.03
        price_change = random.uniform(-volatility, volatility)
        current_price *= 1 + price_change

        candle = {
            "pair": "BTC/USD",
            "timestamp": timestamp.strftime("%Y-%m-%d"),
            "open": current_price,
            "high": current_price * 1.02,
            "low": current_price * 0.98,
            "close": current_price * random.uniform(0.99, 1.01),
            "volume": random.uniform(1000, 10000),
        }
        price_history.append(candle)

        print(
            f"{candle['timestamp']}: Open=${candle['open']:.2f}, "
            f"Close=${candle['close']:.2f}, Volume={candle['volume']:.2f} BTC"
        )

    print("\n7. SAMPLE STAKING POSITIONS")
    print("-" * 50)

    stakeable = ["ADA", "SOL"]
    for user in users[:2]:
        currency = random.choice(stakeable)
        amount = random.uniform(100, 1000)
        apy = random.uniform(4, 12)

        print(
            f"User #{user['user_id']}: Staking {amount:.2f} {currency} @ {apy:.2f}% APY"
        )

    print("\n8. DATA GENERATION SUMMARY")
    print("-" * 50)
    print(f"Users Generated: {len(users)}")
    print(
        f"Currencies: {len(currencies)} ({len(crypto_symbols)} crypto, {len(fiat_currencies)} fiat)"
    )
    print(f"Trading Pairs: {len(trading_pairs)}")
    print(f"Wallets: {len(wallets)}")
    print(f"Orders: {len(orders)}")
    print(f"Trades: {len(trades)}")
    print(f"Price History: {len(price_history)} daily candles")

    print("\n" + "=" * 70)
    print("DEMONSTRATION COMPLETE!")
    print("=" * 70)
    print("\nThis demonstration shows the types of data that would be generated")
    print("by the Cryptocurrency Exchange Generator when connected to a database.")
    print("\nWith a real database connection, the generator would:")
    print("  - Create thousands of users with realistic profiles")
    print("  - Generate complete order books and trade history")
    print("  - Simulate price movements and market data")
    print("  - Create wallet transactions and balances")
    print("  - Generate KYC documents and API keys")
    print("  - Simulate staking positions and rewards")

    return {
        "users": users,
        "currencies": currencies,
        "trading_pairs": trading_pairs,
        "wallets": wallets,
        "orders": orders,
        "trades": trades,
        "price_history": price_history,
    }


if __name__ == "__main__":
    # Run demonstration
    data = demonstrate_generator()

    # Show that data is properly structured for database insertion
    print("\n" + "=" * 70)
    print("SAMPLE DATA STRUCTURE (Ready for Database)")
    print("=" * 70)

    print("\nSample User Record (as it would be inserted):")
    user = data["users"][0]
    print(
        f"  INSERT INTO users (email, username, user_type, kyc_level, daily_limit, ...)"
    )
    print(
        f"  VALUES ('{user['email']}', '{user['username']}', '{user['user_type']}', "
        f"'{user['kyc_level']}', {user['daily_limit']}, ...)"
    )

    print("\nSample Order Record (as it would be inserted):")
    order = data["orders"][0]
    print(f"  INSERT INTO orders (user_id, pair, type, side, quantity, status, ...)")
    print(
        f"  VALUES ({order['user_id']}, '{order['pair']}', '{order['type']}', "
        f"'{order['side']}', {order['quantity']:.8f}, '{order['status']}', ...)"
    )

    print("\nThe full generator with database connection would insert")
    print("all this data efficiently using bulk operations.")
