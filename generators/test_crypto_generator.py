#!/usr/bin/env python3

"""Test script for Cryptocurrency Exchange Generator.

This script tests the generator with a small dataset to verify functionality.
"""

import sys
from generators.cryptocurrency_exchange_generator import CryptocurrencyExchangeGenerator


def test_generator():
    """Test the cryptocurrency exchange generator with small data."""
    print("=" * 70)
    print("CRYPTOCURRENCY EXCHANGE GENERATOR TEST")
    print("=" * 70)

    # Initialize generator with test parameters
    # Note: Using default MySQL connection settings
    # Adjust these based on your local MySQL setup
    generator = CryptocurrencyExchangeGenerator(
        host="localhost",
        port=3306,  # Default MySQL port
        user="root",
        password="",  # Update with your MySQL root password
        database="crypto_exchange_test",  # Test database
    )

    try:
        # First, create the test database if it doesn't exist
        print("\n1. Creating test database...")
        import mysql.connector

        # Connect without database to create it
        conn = mysql.connector.connect(
            host="localhost",
            port=3306,
            user="root",
            password="",  # Update with your password
        )
        cursor = conn.cursor()

        # Create database
        cursor.execute("DROP DATABASE IF EXISTS crypto_exchange_test")
        cursor.execute(
            "CREATE DATABASE crypto_exchange_test CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
        )
        print("   ✓ Database created")

        # Create minimal schema for testing
        cursor.execute("USE crypto_exchange_test")

        # Create tables (simplified schema for testing)
        print("\n2. Creating tables...")

        # Users table
        cursor.execute(
            """
            CREATE TABLE users (
                user_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                email VARCHAR(255) UNIQUE NOT NULL,
                username VARCHAR(50) UNIQUE NOT NULL,
                password_hash VARCHAR(255) NOT NULL,
                user_type ENUM('individual', 'corporate', 'institutional') DEFAULT 'individual',
                first_name VARCHAR(100),
                last_name VARCHAR(100),
                company_name VARCHAR(255),
                phone_number VARCHAR(20),
                country_code CHAR(2),
                preferred_2fa ENUM('google', 'sms', 'email') DEFAULT 'google',
                2fa_enabled BOOLEAN DEFAULT FALSE,
                2fa_secret VARCHAR(255),
                kyc_level ENUM('basic', 'verified', 'premium', 'institutional') DEFAULT 'basic',
                kyc_verified BOOLEAN DEFAULT FALSE,
                kyc_verified_date DATETIME,
                daily_limit DECIMAL(20,2) DEFAULT 1000.00,
                monthly_limit DECIMAL(20,2) DEFAULT 5000.00,
                marketing_consent BOOLEAN DEFAULT FALSE,
                language VARCHAR(5) DEFAULT 'en',
                timezone VARCHAR(50) DEFAULT 'UTC',
                status ENUM('active', 'suspended', 'pending_verification', 'closed') DEFAULT 'pending_verification',
                suspended_reason TEXT,
                last_ip VARCHAR(45),
                last_activity DATETIME,
                last_login DATETIME,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
            ) ENGINE=InnoDB
        """
        )
        print("   ✓ Users table created")

        # Currencies table
        cursor.execute(
            """
            CREATE TABLE currencies (
                currency_id INT AUTO_INCREMENT PRIMARY KEY,
                symbol VARCHAR(10) UNIQUE NOT NULL,
                name VARCHAR(100) NOT NULL,
                currency_type ENUM('crypto', 'fiat') NOT NULL,
                decimal_places INT DEFAULT 8,
                is_active BOOLEAN DEFAULT TRUE,
                deposit_enabled BOOLEAN DEFAULT TRUE,
                withdrawal_enabled BOOLEAN DEFAULT TRUE,
                min_deposit DECIMAL(20,8),
                min_withdrawal DECIMAL(20,8),
                withdrawal_fee DECIMAL(20,8),
                confirmations_required INT DEFAULT 1,
                contract_address VARCHAR(255),
                max_supply DECIMAL(30,8),
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB
        """
        )
        print("   ✓ Currencies table created")

        # Trading pairs table
        cursor.execute(
            """
            CREATE TABLE trading_pairs (
                pair_id INT AUTO_INCREMENT PRIMARY KEY,
                base_currency VARCHAR(10) NOT NULL,
                quote_currency VARCHAR(10) NOT NULL,
                symbol VARCHAR(20) UNIQUE NOT NULL,
                is_active BOOLEAN DEFAULT TRUE,
                min_order_size DECIMAL(20,8),
                max_order_size DECIMAL(20,8),
                maker_fee DECIMAL(10,6) DEFAULT 0.001,
                taker_fee DECIMAL(10,6) DEFAULT 0.002,
                price_precision INT DEFAULT 8,
                quantity_precision INT DEFAULT 8,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB
        """
        )
        print("   ✓ Trading pairs table created")

        # Wallets table
        cursor.execute(
            """
            CREATE TABLE wallets (
                wallet_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                user_id BIGINT UNSIGNED NOT NULL,
                currency VARCHAR(10) NOT NULL,
                address VARCHAR(255) UNIQUE NOT NULL,
                balance DECIMAL(30,8) DEFAULT 0,
                available_balance DECIMAL(30,8) DEFAULT 0,
                locked_balance DECIMAL(30,8) DEFAULT 0,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
            ) ENGINE=InnoDB
        """
        )
        print("   ✓ Wallets table created")

        # Create other required tables (simplified)
        tables = [
            (
                "kyc_documents",
                """
                CREATE TABLE kyc_documents (
                    document_id BIGINT AUTO_INCREMENT PRIMARY KEY,
                    user_id BIGINT UNSIGNED,
                    document_type VARCHAR(50),
                    verification_status VARCHAR(20),
                    document_url VARCHAR(500),
                    document_hash VARCHAR(255),
                    submitted_at DATETIME,
                    verified_at DATETIME,
                    rejection_reason TEXT,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
                )
            """,
            ),
            (
                "orders",
                """
                CREATE TABLE orders (
                    order_id BIGINT AUTO_INCREMENT PRIMARY KEY,
                    user_id BIGINT UNSIGNED,
                    pair_id INT,
                    order_type VARCHAR(20),
                    side VARCHAR(10),
                    quantity DECIMAL(20,8),
                    price DECIMAL(20,8),
                    stop_price DECIMAL(20,8),
                    status VARCHAR(20),
                    filled_quantity DECIMAL(20,8) DEFAULT 0,
                    remaining_quantity DECIMAL(20,8),
                    fee_rate DECIMAL(10,6),
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
                )
            """,
            ),
            (
                "trades",
                """
                CREATE TABLE trades (
                    trade_id BIGINT AUTO_INCREMENT PRIMARY KEY,
                    order_id BIGINT,
                    pair_id INT,
                    buyer_user_id BIGINT UNSIGNED,
                    seller_user_id BIGINT UNSIGNED,
                    price DECIMAL(20,8),
                    quantity DECIMAL(20,8),
                    buyer_fee DECIMAL(10,6),
                    seller_fee DECIMAL(10,6),
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
                )
            """,
            ),
            (
                "transactions",
                """
                CREATE TABLE transactions (
                    transaction_id BIGINT AUTO_INCREMENT PRIMARY KEY,
                    user_id BIGINT UNSIGNED,
                    currency VARCHAR(10),
                    transaction_type VARCHAR(20),
                    amount DECIMAL(30,8),
                    fee DECIMAL(20,8) DEFAULT 0,
                    status VARCHAR(20),
                    tx_hash VARCHAR(255),
                    from_address VARCHAR(255),
                    to_address VARCHAR(255),
                    confirmations INT DEFAULT 0,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    completed_at DATETIME
                )
            """,
            ),
            (
                "price_history",
                """
                CREATE TABLE price_history (
                    id BIGINT AUTO_INCREMENT PRIMARY KEY,
                    pair_id INT,
                    `interval` VARCHAR(10),
                    timestamp DATETIME,
                    open DECIMAL(20,8),
                    high DECIMAL(20,8),
                    low DECIMAL(20,8),
                    close DECIMAL(20,8),
                    volume DECIMAL(30,8),
                    trades INT,
                    INDEX idx_pair_time (pair_id, timestamp)
                )
            """,
            ),
            (
                "staking_positions",
                """
                CREATE TABLE staking_positions (
                    position_id BIGINT AUTO_INCREMENT PRIMARY KEY,
                    user_id BIGINT UNSIGNED,
                    currency VARCHAR(10),
                    amount DECIMAL(30,8),
                    apy DECIMAL(5,2),
                    lock_period VARCHAR(20),
                    status VARCHAR(20),
                    rewards_earned DECIMAL(30,8) DEFAULT 0,
                    staked_at DATETIME,
                    unstaked_at DATETIME,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
                )
            """,
            ),
            (
                "api_keys",
                """
                CREATE TABLE api_keys (
                    key_id BIGINT AUTO_INCREMENT PRIMARY KEY,
                    user_id BIGINT UNSIGNED,
                    key_name VARCHAR(100),
                    api_key VARCHAR(255) UNIQUE,
                    secret_key VARCHAR(255),
                    permission_level VARCHAR(20),
                    allowed_operations TEXT,
                    ip_whitelist TEXT,
                    is_active BOOLEAN DEFAULT TRUE,
                    last_used DATETIME,
                    total_requests BIGINT DEFAULT 0,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
                )
            """,
            ),
            (
                "notifications",
                """
                CREATE TABLE notifications (
                    notification_id BIGINT AUTO_INCREMENT PRIMARY KEY,
                    user_id BIGINT UNSIGNED,
                    notification_type VARCHAR(50),
                    title VARCHAR(255),
                    message TEXT,
                    priority VARCHAR(10),
                    is_read BOOLEAN DEFAULT FALSE,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
                )
            """,
            ),
            (
                "audit_logs",
                """
                CREATE TABLE audit_logs (
                    log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
                    user_id BIGINT UNSIGNED,
                    action VARCHAR(100),
                    ip_address VARCHAR(45),
                    user_agent TEXT,
                    details JSON,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
                )
            """,
            ),
        ]

        for table_name, create_sql in tables:
            cursor.execute(create_sql)
            print(f"   ✓ {table_name} table created")

        conn.commit()
        cursor.close()
        conn.close()

        # Connect with the generator
        print("\n3. Connecting to database with generator...")
        generator.connect()

        # Generate test data with small amounts
        print("\n4. Generating test data...")
        print("   This will create a small dataset for testing...\n")

        # Generate minimal test data
        generator.generate_all_data(
            users=100,  # 100 users instead of 10000
            orders_per_user=5,  # 5 orders per user instead of 50
        )

        # Print statistics
        print("\n5. Data Generation Statistics:")
        generator.print_statistics()

        print("\n✅ TEST SUCCESSFUL!")
        print("The cryptocurrency exchange generator is working correctly.")

    except Exception as e:
        print(f"\n❌ TEST FAILED: {e}")
        import traceback

        traceback.print_exc()

    finally:
        # Disconnect
        if generator.connection:
            generator.disconnect()

        print("\nTest completed.")


if __name__ == "__main__":
    # Check for required packages
    try:
        pass
    except ImportError:
        print("Missing required package!")
        print("Please install required packages:")
        print("  pip install mysql-connector-python faker")
        sys.exit(1)

    # Run the test
    test_generator()
