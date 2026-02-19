-- =====================================================
-- Cryptocurrency Exchange Tables
-- =====================================================
-- Core tables for cryptocurrency exchange operations
-- =====================================================

USE cryptocurrency_exchange;

-- =====================================================
-- User Management Tables
-- =====================================================

-- Users table - Core user accounts
CREATE TABLE users (
    user_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    user_type ENUM('individual', 'corporate', 'institutional') DEFAULT 'individual',

    -- Personal/Company Information
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    company_name VARCHAR(255),
    phone_number VARCHAR(50),
    country_code CHAR(2),

    -- Security Settings
    preferred_2fa ENUM('google', 'sms', 'email') DEFAULT 'google',
    two_fa_enabled BOOLEAN DEFAULT FALSE,
    two_fa_secret VARCHAR(255),

    -- KYC/AML Status
    kyc_level ENUM('basic', 'verified', 'premium', 'institutional') DEFAULT 'basic',
    kyc_verified BOOLEAN DEFAULT FALSE,
    kyc_verified_date DATETIME,
    daily_limit DECIMAL(20, 2) DEFAULT 1000.00,
    monthly_limit DECIMAL(20, 2) DEFAULT 5000.00,

    -- Preferences
    marketing_consent BOOLEAN DEFAULT FALSE,
    language VARCHAR(10) DEFAULT 'en',
    timezone VARCHAR(50) DEFAULT 'UTC',

    -- Account Status
    status ENUM('active', 'suspended', 'pending_verification', 'closed') DEFAULT 'pending_verification',
    suspended_reason TEXT,

    -- Activity Tracking
    last_ip VARCHAR(45),
    last_activity DATETIME,
    last_login DATETIME,
    failed_login_attempts INT DEFAULT 0,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_email (email),
    INDEX idx_username (username),
    INDEX idx_kyc_level (kyc_level),
    INDEX idx_status (status),
    INDEX idx_country (country_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- KYC Documents - User verification documents
CREATE TABLE kyc_documents (
    document_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    document_type ENUM('passport', 'drivers_license', 'national_id', 'utility_bill', 'bank_statement', 'corporate_docs') NOT NULL,
    verification_status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    document_url VARCHAR(500),
    document_hash VARCHAR(255),
    submitted_at DATETIME,
    verified_at DATETIME,
    verified_by INT UNSIGNED,
    rejection_reason TEXT,
    expiry_date DATE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (verified_by) REFERENCES users(user_id) ON DELETE SET NULL,
    INDEX idx_user_status (user_id, verification_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- API Keys - For programmatic access
CREATE TABLE api_keys (
    api_key_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    key_name VARCHAR(100) NOT NULL,
    api_key VARCHAR(255) NOT NULL UNIQUE,
    api_secret_hash VARCHAR(255) NOT NULL,
    permissions JSON,
    ip_whitelist JSON,
    is_active BOOLEAN DEFAULT TRUE,
    last_used DATETIME,
    expires_at DATETIME,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_api_key (api_key),
    INDEX idx_user_active (user_id, is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- Currency and Market Data Tables
-- =====================================================

-- Currencies - Both crypto and fiat
CREATE TABLE currencies (
    currency_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    symbol VARCHAR(10) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    currency_type ENUM('crypto', 'fiat') NOT NULL,
    decimal_places INT DEFAULT 8,
    contract_address VARCHAR(255),
    blockchain VARCHAR(50),

    -- Network and fees
    min_withdrawal DECIMAL(30, 18) DEFAULT 0,
    max_withdrawal DECIMAL(30, 18),
    withdrawal_fee DECIMAL(30, 18) DEFAULT 0,
    deposit_confirmations INT DEFAULT 1,

    -- Market data
    circulating_supply DECIMAL(30, 18),
    max_supply DECIMAL(30, 18),
    market_cap DECIMAL(30, 2),

    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    trading_enabled BOOLEAN DEFAULT TRUE,
    deposits_enabled BOOLEAN DEFAULT TRUE,
    withdrawals_enabled BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_symbol (symbol),
    INDEX idx_type (currency_type),
    INDEX idx_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Trading Pairs - Available trading markets
CREATE TABLE trading_pairs (
    pair_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    symbol VARCHAR(20) NOT NULL UNIQUE,
    base_currency_id INT UNSIGNED NOT NULL,
    quote_currency_id INT UNSIGNED NOT NULL,

    -- Trading parameters
    min_order_size DECIMAL(30, 18) DEFAULT 0.00001,
    max_order_size DECIMAL(30, 18),
    min_price DECIMAL(30, 18) DEFAULT 0.00000001,
    max_price DECIMAL(30, 18),
    price_precision INT DEFAULT 8,
    quantity_precision INT DEFAULT 8,

    -- Fees
    maker_fee DECIMAL(6, 4) DEFAULT 0.0010,
    taker_fee DECIMAL(6, 4) DEFAULT 0.0020,

    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    trading_enabled BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (base_currency_id) REFERENCES currencies(currency_id),
    FOREIGN KEY (quote_currency_id) REFERENCES currencies(currency_id),
    UNIQUE KEY unique_pair (base_currency_id, quote_currency_id),
    INDEX idx_symbol (symbol),
    INDEX idx_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- Wallet and Balance Tables
-- =====================================================

-- Wallets - User cryptocurrency wallets
CREATE TABLE wallets (
    wallet_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    currency_id INT UNSIGNED NOT NULL,

    -- Addresses
    address VARCHAR(255) UNIQUE,
    tag_memo VARCHAR(100), -- For XRP, XLM, etc.

    -- Balances
    available_balance DECIMAL(30, 18) DEFAULT 0,
    locked_balance DECIMAL(30, 18) DEFAULT 0,
    staked_balance DECIMAL(30, 18) DEFAULT 0,

    -- Status
    is_active BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (currency_id) REFERENCES currencies(currency_id),
    UNIQUE KEY unique_wallet (user_id, currency_id),
    INDEX idx_user (user_id),
    INDEX idx_currency (currency_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Transactions - Deposits and withdrawals
CREATE TABLE transactions (
    transaction_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    wallet_id INT UNSIGNED NOT NULL,
    transaction_type ENUM('deposit', 'withdrawal', 'transfer_in', 'transfer_out', 'fee', 'reward') NOT NULL,

    -- Amount and currency
    amount DECIMAL(30, 18) NOT NULL,
    fee DECIMAL(30, 18) DEFAULT 0,
    currency_id INT UNSIGNED NOT NULL,

    -- Blockchain details
    tx_hash VARCHAR(255),
    from_address VARCHAR(255),
    to_address VARCHAR(255),
    confirmations INT DEFAULT 0,

    -- Status tracking
    status ENUM('pending', 'processing', 'confirmed', 'completed', 'failed', 'cancelled') DEFAULT 'pending',

    -- Additional info
    notes TEXT,
    admin_notes TEXT,
    processed_by INT UNSIGNED,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    completed_at DATETIME,

    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (wallet_id) REFERENCES wallets(wallet_id),
    FOREIGN KEY (currency_id) REFERENCES currencies(currency_id),
    FOREIGN KEY (processed_by) REFERENCES users(user_id) ON DELETE SET NULL,
    INDEX idx_user (user_id),
    INDEX idx_status (status),
    INDEX idx_tx_hash (tx_hash),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- Trading Tables
-- =====================================================

-- Orders - Trading orders
CREATE TABLE orders (
    order_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    pair_id INT UNSIGNED NOT NULL,

    -- Order details
    order_type ENUM('market', 'limit', 'stop', 'stop_limit') NOT NULL,
    side ENUM('buy', 'sell') NOT NULL,

    -- Quantities and prices
    quantity DECIMAL(30, 18) NOT NULL,
    price DECIMAL(30, 18),
    stop_price DECIMAL(30, 18),

    -- Execution details
    executed_quantity DECIMAL(30, 18) DEFAULT 0,
    executed_value DECIMAL(30, 18) DEFAULT 0,
    average_price DECIMAL(30, 18),

    -- Fees
    fee DECIMAL(30, 18) DEFAULT 0,
    fee_currency_id INT UNSIGNED,

    -- Status
    status ENUM('pending', 'open', 'partially_filled', 'filled', 'cancelled', 'expired', 'rejected') DEFAULT 'pending',

    -- Time in force
    time_in_force ENUM('GTC', 'IOC', 'FOK', 'GTD') DEFAULT 'GTC',
    expires_at DATETIME,

    -- Additional settings
    is_post_only BOOLEAN DEFAULT FALSE,
    reduce_only BOOLEAN DEFAULT FALSE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    executed_at DATETIME,

    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (pair_id) REFERENCES trading_pairs(pair_id),
    FOREIGN KEY (fee_currency_id) REFERENCES currencies(currency_id),
    INDEX idx_user (user_id),
    INDEX idx_pair_status (pair_id, status),
    INDEX idx_created (created_at),
    INDEX idx_price_time (pair_id, price, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Trades - Executed trades
CREATE TABLE trades (
    trade_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    buy_order_id BIGINT UNSIGNED NOT NULL,
    sell_order_id BIGINT UNSIGNED NOT NULL,
    pair_id INT UNSIGNED NOT NULL,

    -- Trade details
    price DECIMAL(30, 18) NOT NULL,
    quantity DECIMAL(30, 18) NOT NULL,
    total_value DECIMAL(30, 18) NOT NULL,

    -- Fees
    buyer_fee DECIMAL(30, 18) DEFAULT 0,
    seller_fee DECIMAL(30, 18) DEFAULT 0,

    -- User references
    buyer_id INT UNSIGNED NOT NULL,
    seller_id INT UNSIGNED NOT NULL,

    -- Maker/Taker
    maker_side ENUM('buy', 'sell') NOT NULL,

    executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (buy_order_id) REFERENCES orders(order_id),
    FOREIGN KEY (sell_order_id) REFERENCES orders(order_id),
    FOREIGN KEY (pair_id) REFERENCES trading_pairs(pair_id),
    FOREIGN KEY (buyer_id) REFERENCES users(user_id),
    FOREIGN KEY (seller_id) REFERENCES users(user_id),
    INDEX idx_pair_time (pair_id, executed_at),
    INDEX idx_buyer (buyer_id),
    INDEX idx_seller (seller_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- Market Data Tables
-- =====================================================

-- Price History - OHLCV data
CREATE TABLE price_history (
    price_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    pair_id INT UNSIGNED NOT NULL,
    timeframe ENUM('1m', '5m', '15m', '30m', '1h', '4h', '1d', '1w', '1M') NOT NULL,

    -- OHLCV data
    open_price DECIMAL(30, 18) NOT NULL,
    high_price DECIMAL(30, 18) NOT NULL,
    low_price DECIMAL(30, 18) NOT NULL,
    close_price DECIMAL(30, 18) NOT NULL,
    volume DECIMAL(30, 18) NOT NULL,

    -- Additional metrics
    trade_count INT UNSIGNED DEFAULT 0,
    quote_volume DECIMAL(30, 18),

    timestamp DATETIME NOT NULL,

    FOREIGN KEY (pair_id) REFERENCES trading_pairs(pair_id),
    UNIQUE KEY unique_candle (pair_id, timeframe, timestamp),
    INDEX idx_pair_time (pair_id, timestamp),
    INDEX idx_timeframe (timeframe)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Order Book Snapshots - For analysis
CREATE TABLE order_book_snapshots (
    snapshot_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    pair_id INT UNSIGNED NOT NULL,

    -- Aggregated data
    bid_levels JSON,
    ask_levels JSON,

    -- Summary stats
    best_bid DECIMAL(30, 18),
    best_ask DECIMAL(30, 18),
    spread DECIMAL(30, 18),
    mid_price DECIMAL(30, 18),

    -- Depth
    bid_volume DECIMAL(30, 18),
    ask_volume DECIMAL(30, 18),

    snapshot_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (pair_id) REFERENCES trading_pairs(pair_id),
    INDEX idx_pair_time (pair_id, snapshot_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- Staking and DeFi Tables
-- =====================================================

-- Staking Products - Available staking options
CREATE TABLE staking_products (
    product_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    currency_id INT UNSIGNED NOT NULL,
    product_name VARCHAR(100) NOT NULL,

    -- Staking parameters
    min_stake_amount DECIMAL(30, 18) DEFAULT 0,
    max_stake_amount DECIMAL(30, 18),
    lock_period_days INT DEFAULT 0,

    -- Rewards
    apy_rate DECIMAL(10, 4) DEFAULT 0,
    reward_currency_id INT UNSIGNED,
    compound_available BOOLEAN DEFAULT FALSE,

    -- Capacity
    total_staked DECIMAL(30, 18) DEFAULT 0,
    max_total_stake DECIMAL(30, 18),

    -- Status
    is_active BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (currency_id) REFERENCES currencies(currency_id),
    FOREIGN KEY (reward_currency_id) REFERENCES currencies(currency_id),
    INDEX idx_currency (currency_id),
    INDEX idx_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- User Staking Positions
CREATE TABLE staking_positions (
    position_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    product_id INT UNSIGNED NOT NULL,

    -- Stake details
    staked_amount DECIMAL(30, 18) NOT NULL,
    reward_earned DECIMAL(30, 18) DEFAULT 0,

    -- Dates
    stake_date DATETIME NOT NULL,
    unlock_date DATETIME,
    last_reward_date DATETIME,

    -- Status
    status ENUM('active', 'pending_unlock', 'unlocked', 'withdrawn') DEFAULT 'active',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES staking_products(product_id),
    INDEX idx_user_status (user_id, status),
    INDEX idx_unlock_date (unlock_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- Security and Audit Tables
-- =====================================================

-- User Sessions - Active login sessions
CREATE TABLE user_sessions (
    session_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    session_token VARCHAR(255) NOT NULL UNIQUE,

    -- Session details
    ip_address VARCHAR(45),
    user_agent TEXT,
    device_type VARCHAR(50),
    location VARCHAR(100),

    -- Status
    is_active BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at DATETIME NOT NULL,
    last_activity DATETIME,

    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_token (session_token),
    INDEX idx_user_active (user_id, is_active),
    INDEX idx_expires (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Audit Logs - Complete audit trail
CREATE TABLE audit_logs (
    log_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED,

    -- Action details
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50),
    entity_id VARCHAR(50),

    -- Change tracking
    old_values JSON,
    new_values JSON,

    -- Context
    ip_address VARCHAR(45),
    user_agent TEXT,
    api_key_id INT UNSIGNED,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL,
    FOREIGN KEY (api_key_id) REFERENCES api_keys(api_key_id) ON DELETE SET NULL,
    INDEX idx_user (user_id),
    INDEX idx_action (action),
    INDEX idx_entity (entity_type, entity_id),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Security Events - Login attempts, suspicious activity
CREATE TABLE security_events (
    event_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED,

    -- Event details
    event_type ENUM('login_success', 'login_failed', 'password_reset', 'two_fa_failed',
                    'suspicious_activity', 'account_locked', 'withdrawal_blocked') NOT NULL,

    -- Context
    ip_address VARCHAR(45),
    user_agent TEXT,
    details JSON,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_user (user_id),
    INDEX idx_type (event_type),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- Notification Tables
-- =====================================================

-- Notifications - User notifications
CREATE TABLE notifications (
    notification_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,

    -- Notification details
    type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT,
    data JSON,

    -- Status
    is_read BOOLEAN DEFAULT FALSE,
    is_email_sent BOOLEAN DEFAULT FALSE,
    is_push_sent BOOLEAN DEFAULT FALSE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_at DATETIME,

    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_user_unread (user_id, is_read),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
