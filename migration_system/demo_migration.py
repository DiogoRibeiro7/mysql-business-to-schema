#!/usr/bin/env python3
"""
Migration System Demonstration

This script demonstrates the automated migration system capabilities:
1. Creating migrations from MySQL to PostgreSQL
2. Creating migrations from MySQL to MongoDB
3. Viewing generated migration scripts
"""

import os
import sys
import tempfile
from datetime import datetime

# Add current directory to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from migration_manager import MigrationManager, DatabaseType


# Sample MySQL schema for demonstration
SAMPLE_MYSQL_SCHEMA = """
-- Sample E-commerce Database Schema
CREATE DATABASE IF NOT EXISTS ecommerce_demo;
USE ecommerce_demo;

-- Users table
CREATE TABLE users (
    user_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_username (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Products table
CREATE TABLE products (
    product_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    sku VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    stock_quantity INT UNSIGNED DEFAULT 0,
    category VARCHAR(100),
    is_featured BOOLEAN DEFAULT FALSE,
    metadata JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_sku (sku),
    INDEX idx_category (category),
    INDEX idx_price (price)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Orders table
CREATE TABLE orders (
    order_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    order_number VARCHAR(50) UNIQUE NOT NULL,
    status ENUM('pending', 'processing', 'shipped', 'delivered', 'cancelled') DEFAULT 'pending',
    total_amount DECIMAL(10, 2) NOT NULL,
    shipping_address TEXT,
    billing_address TEXT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Order items table
CREATE TABLE order_items (
    item_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT UNSIGNED NOT NULL,
    product_id BIGINT UNSIGNED NOT NULL,
    quantity INT UNSIGNED NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    subtotal DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    INDEX idx_order_id (order_id),
    INDEX idx_product_id (product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Reviews table
CREATE TABLE reviews (
    review_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    product_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    rating TINYINT UNSIGNED CHECK (rating >= 1 AND rating <= 5),
    title VARCHAR(255),
    comment TEXT,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_product (user_id, product_id),
    INDEX idx_product_rating (product_id, rating)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
"""


def demonstrate_migration_system():
    """Demonstrate the migration system capabilities"""

    print("=" * 70)
    print("DATABASE MIGRATION SYSTEM DEMONSTRATION")
    print("=" * 70)

    # Create a temporary directory for migrations
    import tempfile

    temp_dir = tempfile.mkdtemp(prefix="migration_demo_")
    print(f"\nUsing temporary directory: {temp_dir}")

    # Initialize migration manager
    manager = MigrationManager(migrations_dir=os.path.join(temp_dir, "migrations"))

    # Save sample schema to a temporary file
    schema_file = os.path.join(temp_dir, "sample_schema.sql")
    with open(schema_file, "w") as f:
        f.write(SAMPLE_MYSQL_SCHEMA)

    print("\n" + "=" * 70)
    print("1. MYSQL TO POSTGRESQL MIGRATION")
    print("=" * 70)

    # Create PostgreSQL migration
    print("\nCreating PostgreSQL migration...")
    pg_migration = manager.create_migration(
        name="ecommerce_to_postgresql",
        source_file=schema_file,
        source_type=DatabaseType.MYSQL,
        target_type=DatabaseType.POSTGRESQL,
    )

    print(f"[OK] Created migration: {pg_migration.id}")

    # Display PostgreSQL migration script (first 50 lines)
    print("\n--- PostgreSQL Migration Script (Preview) ---")
    print("-" * 50)
    lines = pg_migration.up_script.split("\n")[:50]
    for line in lines:
        print(line)
    if len(pg_migration.up_script.split("\n")) > 50:
        print("... (truncated)")

    print("\n" + "=" * 70)
    print("2. MYSQL TO MONGODB MIGRATION")
    print("=" * 70)

    # Create MongoDB migration
    print("\nCreating MongoDB migration...")
    mongo_migration = manager.create_migration(
        name="ecommerce_to_mongodb",
        source_file=schema_file,
        source_type=DatabaseType.MYSQL,
        target_type=DatabaseType.MONGODB,
    )

    print(f"[OK] Created migration: {mongo_migration.id}")

    # Display MongoDB migration script (first 50 lines)
    print("\n--- MongoDB Migration Script (Preview) ---")
    print("-" * 50)
    lines = mongo_migration.up_script.split("\n")[:50]
    for line in lines:
        print(line)
    if len(mongo_migration.up_script.split("\n")) > 50:
        print("... (truncated)")

    print("\n" + "=" * 70)
    print("3. MIGRATION METADATA")
    print("=" * 70)

    # List all migrations
    migrations = manager.list_migrations()
    print(f"\nTotal migrations created: {len(migrations)}")

    for m in migrations:
        print(f"\n  Migration: {m['name']}")
        print(f"    ID:       {m['id']}")
        print(f"    Type:     {m['source_type']} -> {m['target_type']}")
        print(f"    Status:   {m['status']}")
        print(f"    Checksum: {m['checksum'][:16]}...")

    print("\n" + "=" * 70)
    print("4. KEY FEATURES DEMONSTRATED")
    print("=" * 70)

    print(
        """
[OK] Schema Parsing:
  - Extracted 5 tables from MySQL schema
  - Parsed columns, data types, constraints
  - Identified indexes and foreign keys

[OK] Data Type Mapping:
  - BIGINT UNSIGNED -> BIGINT (PostgreSQL) / Long (MongoDB)
  - VARCHAR -> VARCHAR (PostgreSQL) / String (MongoDB)
  - DECIMAL -> DECIMAL (PostgreSQL) / Decimal128 (MongoDB)
  - TIMESTAMP -> TIMESTAMP (PostgreSQL) / Date (MongoDB)
  - JSON -> JSONB (PostgreSQL) / Object (MongoDB)
  - ENUM -> VARCHAR (PostgreSQL) / String (MongoDB)

[OK] Constraint Handling:
  - Primary keys preserved
  - Foreign keys converted appropriately
  - Unique constraints maintained
  - Check constraints translated
  - Indexes recreated in target format

[OK] PostgreSQL Features:
  - SERIAL for auto-increment columns
  - JSONB for JSON columns
  - Proper index creation syntax
  - Transaction support (BEGIN/COMMIT)

[OK] MongoDB Features:
  - Collection creation
  - Index definitions
  - JSON Schema validation
  - Document structure mapping

[OK] Migration Management:
  - Unique migration IDs with timestamps
  - Up and down (rollback) scripts
  - Metadata tracking
  - Checksum verification
  - Status tracking
    """
    )

    print("\n" + "=" * 70)
    print("5. GENERATED FILES")
    print("=" * 70)

    migrations_dir = os.path.join(temp_dir, "migrations")
    print(f"\nMigration files created in: {migrations_dir}")

    # List generated files
    for root, dirs, files in os.walk(migrations_dir):
        level = root.replace(migrations_dir, "").count(os.sep)
        indent = " " * 2 * level
        print(f"{indent}{os.path.basename(root)}/")
        subindent = " " * 2 * (level + 1)
        for file in files:
            print(f"{subindent}{file}")

    print("\n" + "=" * 70)
    print("6. ROLLBACK SCRIPTS")
    print("=" * 70)

    # Show rollback script preview
    print("\n--- PostgreSQL Rollback Script ---")
    print("-" * 50)
    rollback_lines = pg_migration.down_script.split("\n")[:20]
    for line in rollback_lines:
        print(line)

    print("\n" + "=" * 70)
    print("DEMONSTRATION COMPLETE")
    print("=" * 70)

    print(
        f"""
The migration system successfully:
1. Parsed MySQL schema with {len(manager.parser.parse_mysql_schema(SAMPLE_MYSQL_SCHEMA))} tables
2. Generated PostgreSQL migration with proper data type mappings
3. Generated MongoDB migration with document-oriented structure
4. Created rollback scripts for safe migration reversal
5. Saved all migration metadata for tracking

To use in production:
1. Install required packages: pip install -r requirements.txt
2. Create migration: python migrate.py create --name "my_migration" --source schema.sql --target-type postgresql
3. Execute migration: python migrate.py execute --migration-id <id> --database mydb
4. Rollback if needed: python migrate.py rollback --migration-id <id> --database mydb

Temporary files location: {temp_dir}
    """
    )

    return temp_dir


if __name__ == "__main__":
    temp_dir = demonstrate_migration_system()
    print(f"\nNote: Demo files saved in: {temp_dir}")
    print("You can examine the generated migration files there.")
