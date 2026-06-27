# 💱 Cryptocurrency Exchange (Spot + Staking)

Production-ready MySQL schema for a modern cryptocurrency exchange with spot trading, wallet management, KYC/AML compliance, and staking/yield features.

## 📊 Overview

- **Industry**: FinTech / Crypto
- **Complexity**: High
- **Database**: `crypto_exchange`
- **Focus**: Orders, trades, wallets, compliance, and auditability

## 🗂️ Schema Files

```
schema/
├── 00_create_database.sql
├── 01_tables.sql
├── 02_constraints.sql
└── 03_indexes.sql
```

## 🚀 Quick Start

```bash
# Create database
mysql -u root -p < schema/00_create_database.sql

# Apply schema
mysql -u root -p crypto_exchange < schema/01_tables.sql
mysql -u root -p crypto_exchange < schema/02_constraints.sql
mysql -u root -p crypto_exchange < schema/03_indexes.sql
```

## 🔍 Queries & Data

The `queries/` and `data/` folders are reserved for:
- Example analytics and reports
- Seed data for local testing

Add files as needed for your workflows.

## ✅ What This Example Demonstrates

- Order book and trade execution storage
- Multi-currency wallet balances and transactions
- KYC/AML compliance tracking
- API key governance and audit trails
- Indexing strategies for high-volume trading

## 📄 License

Part of the MySQL Business-to-Schema project, MIT License.

## Database Architecture (Mermaid ERD)

```mermaid
erDiagram
  users {
    INT user_id
    STRING email
    STRING status
    DATETIME created_at
    DATETIME updated_at
    STRING username
    STRING password_hash
  }
  kyc_documents {
    INT document_id
    INT user_id
    DATETIME created_at
    DATETIME updated_at
    STRING document_type
    STRING verification_status
    STRING document_url
  }
  api_keys {
    INT api_key_id
    INT user_id
    DATETIME created_at
    DATETIME updated_at
    STRING api_key
    STRING api_secret_hash
    JSON permissions
  }
  currencies {
    INT currency_id
    STRING name
    DATETIME created_at
    DATETIME updated_at
    STRING symbol
    STRING currency_type
    INT decimal_places
  }
  trading_pairs {
    INT pair_id
    INT base_currency_id
    INT quote_currency_id
    DATETIME created_at
    DATETIME updated_at
    STRING symbol
    DECIMAL min_order_size
  }
  wallets {
    INT wallet_id
    INT user_id
    INT currency_id
    DATETIME created_at
    DATETIME updated_at
    STRING address
    STRING tag_memo
  }
  transactions {
    INT transaction_id
    INT user_id
    INT wallet_id
    DECIMAL amount
    INT currency_id
    STRING status
    DATETIME created_at
  }
  orders {
    BIGINT order_id
    INT user_id
    INT pair_id
    DECIMAL price
    INT fee_currency_id
    STRING status
    DATETIME created_at
  }
  trades {
    BIGINT trade_id
    BIGINT buy_order_id
    BIGINT sell_order_id
    INT pair_id
    DECIMAL price
    INT buyer_id
    INT seller_id
  }
  price_history {
    BIGINT price_id
    INT pair_id
    STRING timeframe
    DECIMAL open_price
    DECIMAL high_price
    DECIMAL low_price
    DECIMAL close_price
  }
  order_book_snapshots {
    BIGINT snapshot_id
    INT pair_id
    JSON bid_levels
    JSON ask_levels
    DECIMAL best_bid
    DECIMAL best_ask
    DECIMAL spread
  }
  staking_products {
    INT product_id
    INT currency_id
    INT reward_currency_id
    DATETIME created_at
    DATETIME updated_at
    STRING product_name
    DECIMAL min_stake_amount
  }
  staking_positions {
    INT position_id
    INT user_id
    INT product_id
    STRING status
    DATETIME created_at
    DATETIME updated_at
    DECIMAL staked_amount
  }
  user_sessions {
    INT session_id
    INT user_id
    DATETIME created_at
    STRING session_token
    STRING ip_address
    STRING user_agent
    STRING device_type
  }
  audit_logs {
    BIGINT log_id
    INT user_id
    STRING entity_id
    INT api_key_id
    DATETIME created_at
    STRING action
    STRING entity_type
  }
  security_events {
    INT event_id
    INT user_id
    DATETIME created_at
    STRING event_type
    STRING ip_address
    STRING user_agent
    JSON details
  }
  notifications {
    INT notification_id
    INT user_id
    STRING type
    STRING title
    DATETIME created_at
    STRING message
    JSON data
  }

  users ||--o{ kyc_documents : references
  users ||--o{ api_keys : references
  currencies ||--o{ trading_pairs : references
  users ||--o{ wallets : references
  currencies ||--o{ wallets : references
  users ||--o{ transactions : references
  wallets ||--o{ transactions : references
  currencies ||--o{ transactions : references
  users ||--o{ orders : references
  trading_pairs ||--o{ orders : references
  currencies ||--o{ orders : references
  orders ||--o{ trades : references
  trading_pairs ||--o{ trades : references
  users ||--o{ trades : references
  trading_pairs ||--o{ price_history : references
  trading_pairs ||--o{ order_book_snapshots : references
  currencies ||--o{ staking_products : references
  users ||--o{ staking_positions : references
  staking_products ||--o{ staking_positions : references
  users ||--o{ user_sessions : references
  users ||--o{ audit_logs : references
  api_keys ||--o{ audit_logs : references
  users ||--o{ security_events : references
  users ||--o{ notifications : references
```
