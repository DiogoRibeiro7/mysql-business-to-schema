-- ============================================================================
-- CORE TABLES FOR CRYPTOCURRENCY EXCHANGE
-- ============================================================================

USE cryptocurrency;

-- ============================================================================
-- USER MANAGEMENT
-- ============================================================================

-- Users table with KYC/AML fields
CREATE TABLE users (
    user_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    email VARCHAR(255) NOT NULL,
    username VARCHAR(50) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,

    -- Personal Information (KYC)
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    date_of_birth DATE,
    nationality VARCHAR(2), -- ISO country code

    -- Contact
    phone_number VARCHAR(20),
    phone_verified BOOLEAN DEFAULT FALSE,
    email_verified BOOLEAN DEFAULT FALSE,

    -- KYC/AML Status
    kyc_level ENUM('none', 'basic', 'intermediate', 'advanced') DEFAULT 'none',
    kyc_status ENUM('pending', 'approved', 'rejected', 'expired') DEFAULT 'pending',
    kyc_submitted_at TIMESTAMP NULL,
    kyc_approved_at TIMESTAMP NULL,
    aml_risk_score DECIMAL(5,2), -- 0-100 risk score

    -- Account Status
    status ENUM('active', 'suspended', 'banned', 'dormant') DEFAULT 'active',
    account_type ENUM('individual', 'institutional', 'vip') DEFAULT 'individual',

    -- Limits (in USD equivalent)
    daily_withdrawal_limit DECIMAL(20,2) DEFAULT 10000.00,
    daily_trading_limit DECIMAL(20,2) DEFAULT 50000.00,

    -- Security
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    two_factor_secret VARCHAR(255),
    last_login_at TIMESTAMP NULL,
    last_login_ip VARCHAR(45),
    failed_login_attempts INT DEFAULT 0,
    locked_until TIMESTAMP NULL,

    -- Referral
    referral_code VARCHAR(20) UNIQUE,
    referred_by_user_id BIGINT UNSIGNED,

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (user_id),
    UNIQUE KEY uk_email (email),
    UNIQUE KEY uk_username (username),
    INDEX idx_kyc_status (kyc_status),
    INDEX idx_status (status),
    INDEX idx_referral (referred_by_user_id)
) ENGINE=InnoDB;

-- KYC Documents
CREATE TABLE kyc_documents (
    document_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id BIGINT UNSIGNED NOT NULL,
    document_type ENUM('passport', 'drivers_license', 'national_id', 'proof_of_address', 'bank_statement', 'selfie') NOT NULL,
    document_number VARCHAR(100),
    file_path VARCHAR(500),
    file_hash VARCHAR(64), -- SHA-256 hash

    -- Verification
    verification_status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    verified_by_user_id BIGINT UNSIGNED,
    verification_notes TEXT,

    -- Document details
    issue_date DATE,
    expiry_date DATE,
    issuing_country VARCHAR(2),

    -- Timestamps
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    verified_at TIMESTAMP NULL,

    PRIMARY KEY (document_id),
    INDEX idx_user_documents (user_id),
    INDEX idx_verification_status (verification_status),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
) ENGINE=InnoDB;

-- ============================================================================
-- CRYPTOCURRENCY & TRADING PAIRS
-- ============================================================================

-- Supported cryptocurrencies
CREATE TABLE currencies (
    currency_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    symbol VARCHAR(10) NOT NULL, -- BTC, ETH, USDT
    name VARCHAR(100) NOT NULL,
    currency_type ENUM('crypto', 'fiat', 'stablecoin') NOT NULL,

    -- Blockchain details
    blockchain VARCHAR(50), -- bitcoin, ethereum, tron
    contract_address VARCHAR(255), -- For tokens
    decimals TINYINT UNSIGNED DEFAULT 18,

    -- Trading settings
    is_active BOOLEAN DEFAULT TRUE,
    can_deposit BOOLEAN DEFAULT TRUE,
    can_withdraw BOOLEAN DEFAULT TRUE,
    can_trade BOOLEAN DEFAULT TRUE,

    -- Limits
    min_deposit DECIMAL(30,18) DEFAULT 0,
    min_withdrawal DECIMAL(30,18) DEFAULT 0.00001,
    withdrawal_fee DECIMAL(30,18) DEFAULT 0,

    -- Network confirmations required
    deposit_confirmations INT DEFAULT 6,

    -- Metadata
    icon_url VARCHAR(500),
    website_url VARCHAR(500),
    market_cap_rank INT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (currency_id),
    UNIQUE KEY uk_symbol (symbol),
    INDEX idx_active (is_active),
    INDEX idx_type (currency_type)
) ENGINE=InnoDB;

-- Trading pairs
CREATE TABLE trading_pairs (
    pair_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    base_currency_id INT UNSIGNED NOT NULL,
    quote_currency_id INT UNSIGNED NOT NULL,
    symbol VARCHAR(20) NOT NULL, -- BTC/USDT

    -- Trading settings
    is_active BOOLEAN DEFAULT TRUE,

    -- Precision and limits
    price_precision TINYINT DEFAULT 8,
    quantity_precision TINYINT DEFAULT 8,
    min_order_value DECIMAL(20,8) DEFAULT 10.00, -- In quote currency
    max_order_value DECIMAL(20,8) DEFAULT 1000000.00,
    min_quantity DECIMAL(30,18) DEFAULT 0.00001,
    max_quantity DECIMAL(30,18) DEFAULT 10000,

    -- Fees (as percentage)
    maker_fee_rate DECIMAL(6,4) DEFAULT 0.1000, -- 0.1%
    taker_fee_rate DECIMAL(6,4) DEFAULT 0.2000, -- 0.2%

    -- Statistics (updated periodically)
    last_price DECIMAL(30,18),
    price_change_24h DECIMAL(10,2),
    volume_24h DECIMAL(30,18),
    high_24h DECIMAL(30,18),
    low_24h DECIMAL(30,18),

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (pair_id),
    UNIQUE KEY uk_pair (base_currency_id, quote_currency_id),
    UNIQUE KEY uk_symbol (symbol),
    INDEX idx_active (is_active),
    INDEX idx_base_currency (base_currency_id),
    INDEX idx_quote_currency (quote_currency_id),
    FOREIGN KEY (base_currency_id) REFERENCES currencies(currency_id),
    FOREIGN KEY (quote_currency_id) REFERENCES currencies(currency_id)
) ENGINE=InnoDB;

-- ============================================================================
-- WALLETS & BALANCES
-- ============================================================================

-- User wallets (one per currency per user)
CREATE TABLE wallets (
    wallet_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id BIGINT UNSIGNED NOT NULL,
    currency_id INT UNSIGNED NOT NULL,

    -- Blockchain addresses
    deposit_address VARCHAR(255),
    deposit_tag VARCHAR(100), -- For XRP, XLM etc

    -- Balances (all in smallest unit, e.g., satoshi for BTC)
    available_balance DECIMAL(30,18) DEFAULT 0,
    locked_balance DECIMAL(30,18) DEFAULT 0, -- Locked in orders
    total_balance DECIMAL(30,18) GENERATED ALWAYS AS (available_balance + locked_balance) STORED,

    -- Statistics
    total_deposited DECIMAL(30,18) DEFAULT 0,
    total_withdrawn DECIMAL(30,18) DEFAULT 0,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (wallet_id),
    UNIQUE KEY uk_user_currency (user_id, currency_id),
    INDEX idx_user (user_id),
    INDEX idx_currency (currency_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (currency_id) REFERENCES currencies(currency_id)
) ENGINE=InnoDB;

-- ============================================================================
-- ORDERS & TRADING
-- ============================================================================

-- Orders (both open and historical)
CREATE TABLE orders (
    order_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id BIGINT UNSIGNED NOT NULL,
    pair_id INT UNSIGNED NOT NULL,

    -- Order details
    order_type ENUM('limit', 'market', 'stop_limit', 'stop_market') NOT NULL,
    side ENUM('buy', 'sell') NOT NULL,
    price DECIMAL(30,18), -- NULL for market orders
    stop_price DECIMAL(30,18), -- For stop orders
    quantity DECIMAL(30,18) NOT NULL,

    -- Execution details
    filled_quantity DECIMAL(30,18) DEFAULT 0,
    remaining_quantity DECIMAL(30,18) GENERATED ALWAYS AS (quantity - filled_quantity) STORED,
    executed_value DECIMAL(30,18) DEFAULT 0, -- Total value of executed portion
    average_price DECIMAL(30,18), -- Average execution price

    -- Fees
    fee_amount DECIMAL(30,18) DEFAULT 0,
    fee_currency_id INT UNSIGNED,

    -- Status
    status ENUM('pending', 'open', 'partially_filled', 'filled', 'cancelled', 'rejected', 'expired') DEFAULT 'pending',
    time_in_force ENUM('GTC', 'IOC', 'FOK', 'GTD') DEFAULT 'GTC', -- Good Till Cancel, Immediate or Cancel, Fill or Kill, Good Till Date
    expire_time TIMESTAMP NULL,

    -- Source
    source ENUM('web', 'mobile', 'api', 'system') DEFAULT 'web',
    ip_address VARCHAR(45),

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    cancelled_at TIMESTAMP NULL,

    PRIMARY KEY (order_id),
    INDEX idx_user (user_id),
    INDEX idx_pair (pair_id),
    INDEX idx_status (status),
    INDEX idx_created (created_at),
    INDEX idx_user_status (user_id, status),
    INDEX idx_pair_side_price (pair_id, side, price),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (pair_id) REFERENCES trading_pairs(pair_id),
    FOREIGN KEY (fee_currency_id) REFERENCES currencies(currency_id)
) ENGINE=InnoDB;

-- Executed trades
CREATE TABLE trades (
    trade_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    pair_id INT UNSIGNED NOT NULL,

    -- Maker/Taker orders
    maker_order_id BIGINT UNSIGNED NOT NULL,
    taker_order_id BIGINT UNSIGNED NOT NULL,
    maker_user_id BIGINT UNSIGNED NOT NULL,
    taker_user_id BIGINT UNSIGNED NOT NULL,

    -- Trade details
    price DECIMAL(30,18) NOT NULL,
    quantity DECIMAL(30,18) NOT NULL,
    value DECIMAL(30,18) GENERATED ALWAYS AS (price * quantity) STORED,
    side ENUM('buy', 'sell') NOT NULL, -- From taker perspective

    -- Fees
    maker_fee DECIMAL(30,18) DEFAULT 0,
    taker_fee DECIMAL(30,18) DEFAULT 0,
    fee_currency_id INT UNSIGNED,

    -- Timestamp
    executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (trade_id),
    INDEX idx_pair (pair_id),
    INDEX idx_executed (executed_at),
    INDEX idx_maker_order (maker_order_id),
    INDEX idx_taker_order (taker_order_id),
    INDEX idx_maker_user (maker_user_id),
    INDEX idx_taker_user (taker_user_id),
    FOREIGN KEY (pair_id) REFERENCES trading_pairs(pair_id),
    FOREIGN KEY (maker_order_id) REFERENCES orders(order_id),
    FOREIGN KEY (taker_order_id) REFERENCES orders(order_id),
    FOREIGN KEY (maker_user_id) REFERENCES users(user_id),
    FOREIGN KEY (taker_user_id) REFERENCES users(user_id),
    FOREIGN KEY (fee_currency_id) REFERENCES currencies(currency_id)
) ENGINE=InnoDB;

-- ============================================================================
-- TRANSACTIONS (Deposits/Withdrawals)
-- ============================================================================

CREATE TABLE transactions (
    transaction_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id BIGINT UNSIGNED NOT NULL,
    wallet_id BIGINT UNSIGNED NOT NULL,
    currency_id INT UNSIGNED NOT NULL,

    -- Transaction details
    type ENUM('deposit', 'withdrawal', 'transfer_in', 'transfer_out', 'fee', 'reward', 'adjustment') NOT NULL,
    amount DECIMAL(30,18) NOT NULL,
    fee DECIMAL(30,18) DEFAULT 0,

    -- Blockchain details
    blockchain_txid VARCHAR(255),
    blockchain_address VARCHAR(255),
    confirmations INT DEFAULT 0,

    -- Status
    status ENUM('pending', 'confirming', 'completed', 'failed', 'cancelled') DEFAULT 'pending',

    -- Internal transfer details
    related_transaction_id BIGINT UNSIGNED, -- For internal transfers

    -- Notes
    notes TEXT,
    admin_notes TEXT,

    -- Risk management
    risk_score DECIMAL(5,2),
    requires_manual_review BOOLEAN DEFAULT FALSE,
    reviewed_by_user_id BIGINT UNSIGNED,
    reviewed_at TIMESTAMP NULL,

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    completed_at TIMESTAMP NULL,

    PRIMARY KEY (transaction_id),
    INDEX idx_user (user_id),
    INDEX idx_wallet (wallet_id),
    INDEX idx_currency (currency_id),
    INDEX idx_type (type),
    INDEX idx_status (status),
    INDEX idx_txid (blockchain_txid),
    INDEX idx_created (created_at),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (wallet_id) REFERENCES wallets(wallet_id),
    FOREIGN KEY (currency_id) REFERENCES currencies(currency_id),
    FOREIGN KEY (related_transaction_id) REFERENCES transactions(transaction_id)
) ENGINE=InnoDB;

-- ============================================================================
-- PRICE HISTORY & MARKET DATA
-- ============================================================================

-- OHLCV candlestick data
CREATE TABLE price_history (
    candle_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    pair_id INT UNSIGNED NOT NULL,
    interval_type ENUM('1m', '5m', '15m', '30m', '1h', '4h', '1d', '1w', '1mo') NOT NULL,

    -- OHLCV data
    open_time TIMESTAMP NOT NULL,
    close_time TIMESTAMP NOT NULL,
    open_price DECIMAL(30,18) NOT NULL,
    high_price DECIMAL(30,18) NOT NULL,
    low_price DECIMAL(30,18) NOT NULL,
    close_price DECIMAL(30,18) NOT NULL,
    volume DECIMAL(30,18) NOT NULL,
    quote_volume DECIMAL(30,18) NOT NULL, -- Volume in quote currency

    -- Statistics
    trade_count INT DEFAULT 0,

    PRIMARY KEY (candle_id),
    UNIQUE KEY uk_pair_interval_time (pair_id, interval_type, open_time),
    INDEX idx_pair (pair_id),
    INDEX idx_time (open_time),
    FOREIGN KEY (pair_id) REFERENCES trading_pairs(pair_id)
) ENGINE=InnoDB;

-- ============================================================================
-- SECURITY & API MANAGEMENT
-- ============================================================================

-- API Keys for users
CREATE TABLE api_keys (
    api_key_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id BIGINT UNSIGNED NOT NULL,

    -- Key details
    key_name VARCHAR(100),
    api_key VARCHAR(64) NOT NULL,
    api_secret_hash VARCHAR(255) NOT NULL,

    -- Permissions
    can_read BOOLEAN DEFAULT TRUE,
    can_trade BOOLEAN DEFAULT FALSE,
    can_withdraw BOOLEAN DEFAULT FALSE,

    -- IP whitelist (JSON array)
    ip_whitelist JSON,

    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    last_used_at TIMESTAMP NULL,
    last_used_ip VARCHAR(45),

    -- Expiry
    expires_at TIMESTAMP NULL,

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (api_key_id),
    UNIQUE KEY uk_api_key (api_key),
    INDEX idx_user (user_id),
    INDEX idx_active (is_active),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
) ENGINE=InnoDB;

-- User sessions
CREATE TABLE user_sessions (
    session_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id BIGINT UNSIGNED NOT NULL,

    -- Session details
    session_token VARCHAR(255) NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,

    -- Device info
    device_type ENUM('web', 'mobile', 'tablet', 'api') DEFAULT 'web',
    device_id VARCHAR(255),

    -- Status
    is_active BOOLEAN DEFAULT TRUE,

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_activity_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    logged_out_at TIMESTAMP NULL,

    PRIMARY KEY (session_id),
    UNIQUE KEY uk_token (session_token),
    INDEX idx_user (user_id),
    INDEX idx_active (is_active),
    INDEX idx_expires (expires_at),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
) ENGINE=InnoDB;

-- ============================================================================
-- AUDIT & COMPLIANCE
-- ============================================================================

-- Audit logs for all critical operations
CREATE TABLE audit_logs (
    audit_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id BIGINT UNSIGNED,

    -- Event details
    event_type VARCHAR(50) NOT NULL, -- login, withdrawal, trade, kyc_update, etc
    event_subtype VARCHAR(50),
    entity_type VARCHAR(50), -- user, order, transaction, etc
    entity_id BIGINT UNSIGNED,

    -- Change details (JSON)
    old_values JSON,
    new_values JSON,

    -- Request details
    ip_address VARCHAR(45),
    user_agent TEXT,
    request_id VARCHAR(100),

    -- Result
    result ENUM('success', 'failure', 'error') DEFAULT 'success',
    error_message TEXT,

    -- Timestamp
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (audit_id),
    INDEX idx_user (user_id),
    INDEX idx_event_type (event_type),
    INDEX idx_entity (entity_type, entity_id),
    INDEX idx_created (created_at),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
) ENGINE=InnoDB;

-- ============================================================================
-- FEE STRUCTURES
-- ============================================================================

-- User-specific fee tiers
CREATE TABLE user_fee_tiers (
    tier_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    tier_name VARCHAR(50) NOT NULL,

    -- Volume requirements (30-day volume in USD)
    min_volume DECIMAL(20,2) DEFAULT 0,
    max_volume DECIMAL(20,2),

    -- Fee rates (as percentage)
    maker_fee_rate DECIMAL(6,4) DEFAULT 0.1000,
    taker_fee_rate DECIMAL(6,4) DEFAULT 0.2000,

    -- Benefits
    withdrawal_fee_discount DECIMAL(5,2) DEFAULT 0, -- Percentage discount

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (tier_id),
    UNIQUE KEY uk_tier_name (tier_name),
    INDEX idx_volume (min_volume, max_volume)
) ENGINE=InnoDB;

-- User trading volumes (30-day rolling)
CREATE TABLE user_trading_volumes (
    volume_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id BIGINT UNSIGNED NOT NULL,

    -- Volume in USD
    volume_30d DECIMAL(30,2) DEFAULT 0,
    volume_7d DECIMAL(30,2) DEFAULT 0,
    volume_24h DECIMAL(30,2) DEFAULT 0,

    -- Current tier
    fee_tier_id INT UNSIGNED,

    -- Last calculation
    last_calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (volume_id),
    UNIQUE KEY uk_user (user_id),
    INDEX idx_tier (fee_tier_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (fee_tier_id) REFERENCES user_fee_tiers(tier_id)
) ENGINE=InnoDB;
