-- =========================================
-- FinTech Platform - Core Tables
-- =========================================

USE fintech;

-- =========================================
-- 1. CUSTOMER & KYC TABLES
-- =========================================

CREATE TABLE IF NOT EXISTS customers (
    customer_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_type ENUM('individual', 'business') NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    status ENUM('pending_kyc', 'active', 'suspended', 'closed') DEFAULT 'pending_kyc',
    risk_level ENUM('low', 'medium', 'high', 'prohibited') DEFAULT 'medium',
    onboarding_date DATE NOT NULL,
    last_activity TIMESTAMP NULL,
    preferred_currency CHAR(3) DEFAULT 'USD',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE INDEX idx_email (email),
    INDEX idx_status (status),
    INDEX idx_risk_level (risk_level)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS individual_customers (
    customer_id BIGINT UNSIGNED PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    date_of_birth DATE NOT NULL,
    ssn_encrypted VARBINARY(255), -- Encrypted SSN
    nationality CHAR(2) NOT NULL, -- ISO country code
    occupation VARCHAR(100),
    annual_income DECIMAL(15,2),
    source_of_wealth VARCHAR(255),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    INDEX idx_name (last_name, first_name),
    INDEX idx_dob (date_of_birth)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS business_customers (
    customer_id BIGINT UNSIGNED PRIMARY KEY,
    business_name VARCHAR(255) NOT NULL,
    business_type VARCHAR(100),
    registration_number VARCHAR(50),
    tax_id_encrypted VARBINARY(255), -- Encrypted EIN
    incorporation_date DATE,
    incorporation_country CHAR(2),
    annual_revenue DECIMAL(15,2),
    number_of_employees INT,
    industry VARCHAR(100),
    website VARCHAR(255),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    INDEX idx_business_name (business_name),
    UNIQUE INDEX idx_registration (registration_number)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS kyc_documents (
    document_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id BIGINT UNSIGNED NOT NULL,
    document_type ENUM('passport', 'drivers_license', 'national_id', 'utility_bill', 'bank_statement', 'incorporation_cert') NOT NULL,
    document_number VARCHAR(100),
    issue_date DATE,
    expiry_date DATE,
    issuing_country CHAR(2),
    verification_status ENUM('pending', 'verified', 'rejected', 'expired') DEFAULT 'pending',
    verified_at TIMESTAMP NULL,
    verified_by VARCHAR(100),
    document_hash VARCHAR(64), -- SHA-256 hash for integrity
    storage_path VARCHAR(500), -- Encrypted document storage location
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    INDEX idx_customer_docs (customer_id, document_type),
    INDEX idx_verification_status (verification_status),
    INDEX idx_expiry (expiry_date)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS customer_addresses (
    address_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id BIGINT UNSIGNED NOT NULL,
    address_type ENUM('residential', 'business', 'mailing') NOT NULL,
    street_address_1 VARCHAR(255) NOT NULL,
    street_address_2 VARCHAR(255),
    city VARCHAR(100) NOT NULL,
    state_province VARCHAR(100),
    postal_code VARCHAR(20),
    country CHAR(2) NOT NULL,
    is_primary BOOLEAN DEFAULT FALSE,
    verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    INDEX idx_customer_addresses (customer_id, address_type),
    INDEX idx_country (country)
) ENGINE=InnoDB;

-- =========================================
-- 2. ACCOUNT TABLES
-- =========================================

CREATE TABLE IF NOT EXISTS accounts (
    account_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    account_number VARCHAR(20) NOT NULL,
    account_type ENUM('checking', 'savings', 'loan', 'credit_card', 'investment') NOT NULL,
    currency CHAR(3) NOT NULL DEFAULT 'USD',
    status ENUM('pending', 'active', 'frozen', 'closed') DEFAULT 'pending',
    balance DECIMAL(19,4) DEFAULT 0.00, -- Current balance (cached for performance)
    available_balance DECIMAL(19,4) DEFAULT 0.00, -- Available for withdrawal
    pending_balance DECIMAL(19,4) DEFAULT 0.00, -- Pending transactions
    interest_rate DECIMAL(5,4) DEFAULT 0.00, -- Annual percentage rate
    overdraft_limit DECIMAL(15,2) DEFAULT 0.00,
    minimum_balance DECIMAL(15,2) DEFAULT 0.00,
    opened_date DATE NOT NULL,
    closed_date DATE,
    last_transaction_date TIMESTAMP NULL,
    last_interest_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    version INT DEFAULT 0, -- For optimistic locking
    UNIQUE INDEX idx_account_number (account_number),
    INDEX idx_account_type (account_type),
    INDEX idx_status (status),
    INDEX idx_currency (currency)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS account_holders (
    account_holder_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    account_id BIGINT UNSIGNED NOT NULL,
    customer_id BIGINT UNSIGNED NOT NULL,
    relationship_type ENUM('primary', 'joint', 'authorized_user', 'beneficiary') NOT NULL,
    ownership_percentage DECIMAL(5,2) DEFAULT 100.00,
    added_date DATE NOT NULL,
    removed_date DATE,
    FOREIGN KEY (account_id) REFERENCES accounts(account_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    UNIQUE INDEX idx_account_customer (account_id, customer_id),
    INDEX idx_customer_accounts (customer_id),
    INDEX idx_relationship (relationship_type)
) ENGINE=InnoDB;

-- =========================================
-- 3. GENERAL LEDGER & ACCOUNTING
-- =========================================

CREATE TABLE IF NOT EXISTS chart_of_accounts (
    account_code VARCHAR(20) PRIMARY KEY,
    account_name VARCHAR(100) NOT NULL,
    account_type ENUM('asset', 'liability', 'equity', 'revenue', 'expense') NOT NULL,
    parent_account_code VARCHAR(20),
    is_control_account BOOLEAN DEFAULT FALSE,
    normal_balance ENUM('debit', 'credit') NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_account_code) REFERENCES chart_of_accounts(account_code),
    INDEX idx_account_type (account_type),
    INDEX idx_parent (parent_account_code)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS journal_entries (
    journal_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    entry_date DATE NOT NULL,
    posting_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    description VARCHAR(500) NOT NULL,
    reference_type VARCHAR(50), -- 'payment', 'transfer', 'fee', 'interest', etc.
    reference_id BIGINT UNSIGNED, -- ID in the referenced table
    total_debits DECIMAL(19,4) NOT NULL,
    total_credits DECIMAL(19,4) NOT NULL,
    status ENUM('draft', 'posted', 'reversed') DEFAULT 'posted',
    posted_by VARCHAR(100),
    reversed_by_journal_id BIGINT UNSIGNED,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_entry_date (entry_date),
    INDEX idx_reference (reference_type, reference_id),
    INDEX idx_status (status),
    CONSTRAINT chk_balance CHECK (total_debits = total_credits)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS journal_lines (
    line_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    journal_id BIGINT UNSIGNED NOT NULL,
    account_code VARCHAR(20) NOT NULL,
    debit_amount DECIMAL(19,4) DEFAULT 0.00,
    credit_amount DECIMAL(19,4) DEFAULT 0.00,
    currency CHAR(3) NOT NULL DEFAULT 'USD',
    exchange_rate DECIMAL(12,6) DEFAULT 1.000000,
    base_currency_amount DECIMAL(19,4) NOT NULL, -- Amount in system base currency
    description VARCHAR(255),
    FOREIGN KEY (journal_id) REFERENCES journal_entries(journal_id),
    FOREIGN KEY (account_code) REFERENCES chart_of_accounts(account_code),
    INDEX idx_journal_lines (journal_id),
    INDEX idx_account_code (account_code),
    CONSTRAINT chk_debit_credit CHECK (
        (debit_amount > 0 AND credit_amount = 0) OR
        (debit_amount = 0 AND credit_amount > 0)
    )
) ENGINE=InnoDB;

-- =========================================
-- 4. TRANSACTIONS & PAYMENTS
-- =========================================

CREATE TABLE IF NOT EXISTS transactions (
    transaction_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    transaction_uuid VARCHAR(36) NOT NULL, -- UUID for idempotency
    account_id BIGINT UNSIGNED NOT NULL,
    transaction_type ENUM('deposit', 'withdrawal', 'transfer', 'payment', 'fee', 'interest', 'adjustment') NOT NULL,
    amount DECIMAL(19,4) NOT NULL,
    currency CHAR(3) NOT NULL,
    balance_after DECIMAL(19,4) NOT NULL,
    description VARCHAR(500),
    reference_number VARCHAR(100),
    status ENUM('pending', 'processing', 'completed', 'failed', 'reversed') DEFAULT 'pending',
    initiated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP NULL,
    reversed_at TIMESTAMP NULL,
    reversal_reason VARCHAR(255),
    channel ENUM('online', 'mobile', 'atm', 'branch', 'phone', 'system') NOT NULL,
    ip_address VARCHAR(45),
    device_id VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (account_id) REFERENCES accounts(account_id),
    UNIQUE INDEX idx_uuid (transaction_uuid),
    INDEX idx_account_transactions (account_id, initiated_at DESC),
    INDEX idx_status (status),
    INDEX idx_type (transaction_type),
    INDEX idx_initiated (initiated_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS transfers (
    transfer_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    from_transaction_id BIGINT UNSIGNED NOT NULL,
    to_transaction_id BIGINT UNSIGNED NOT NULL,
    transfer_type ENUM('internal', 'domestic_wire', 'international_wire', 'ach', 'p2p') NOT NULL,
    amount DECIMAL(19,4) NOT NULL,
    from_currency CHAR(3) NOT NULL,
    to_currency CHAR(3) NOT NULL,
    exchange_rate DECIMAL(12,6) DEFAULT 1.000000,
    fee_amount DECIMAL(15,2) DEFAULT 0.00,
    swift_code VARCHAR(11),
    routing_number VARCHAR(20),
    beneficiary_name VARCHAR(255),
    beneficiary_reference VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (from_transaction_id) REFERENCES transactions(transaction_id),
    FOREIGN KEY (to_transaction_id) REFERENCES transactions(transaction_id),
    INDEX idx_from_transaction (from_transaction_id),
    INDEX idx_to_transaction (to_transaction_id),
    INDEX idx_transfer_type (transfer_type)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS payment_methods (
    payment_method_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id BIGINT UNSIGNED NOT NULL,
    method_type ENUM('card', 'bank_account', 'wallet') NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    INDEX idx_customer_methods (customer_id, is_active),
    INDEX idx_method_type (method_type)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS cards (
    card_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    payment_method_id BIGINT UNSIGNED NOT NULL,
    card_number_masked VARCHAR(19) NOT NULL, -- Only last 4 digits
    card_number_hash VARCHAR(64) NOT NULL, -- For duplicate detection
    card_type ENUM('debit', 'credit', 'prepaid') NOT NULL,
    card_brand ENUM('visa', 'mastercard', 'amex', 'discover') NOT NULL,
    expiry_month TINYINT NOT NULL,
    expiry_year SMALLINT NOT NULL,
    cardholder_name VARCHAR(255) NOT NULL,
    billing_address_id BIGINT UNSIGNED,
    token VARCHAR(100), -- Tokenized card for processing
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (payment_method_id) REFERENCES payment_methods(payment_method_id),
    FOREIGN KEY (billing_address_id) REFERENCES customer_addresses(address_id),
    UNIQUE INDEX idx_card_hash (card_number_hash),
    INDEX idx_expiry (expiry_year, expiry_month)
) ENGINE=InnoDB;

-- =========================================
-- 5. CURRENCY & EXCHANGE RATES
-- =========================================

CREATE TABLE IF NOT EXISTS currencies (
    currency_code CHAR(3) PRIMARY KEY,
    currency_name VARCHAR(50) NOT NULL,
    symbol VARCHAR(5),
    decimal_places TINYINT DEFAULT 2,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS exchange_rates (
    rate_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    from_currency CHAR(3) NOT NULL,
    to_currency CHAR(3) NOT NULL,
    rate_date DATE NOT NULL,
    exchange_rate DECIMAL(12,6) NOT NULL,
    rate_source VARCHAR(50) DEFAULT 'SYSTEM',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (from_currency) REFERENCES currencies(currency_code),
    FOREIGN KEY (to_currency) REFERENCES currencies(currency_code),
    UNIQUE INDEX idx_currency_date (from_currency, to_currency, rate_date),
    INDEX idx_date (rate_date DESC)
) ENGINE=InnoDB;

-- =========================================
-- 6. FRAUD & RISK MANAGEMENT
-- =========================================

CREATE TABLE IF NOT EXISTS risk_rules (
    rule_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    rule_name VARCHAR(100) NOT NULL,
    rule_type ENUM('velocity', 'amount', 'geographic', 'behavioral', 'ml_score') NOT NULL,
    rule_condition JSON NOT NULL, -- Flexible rule definition
    risk_score INT NOT NULL, -- Points to add to risk score
    action ENUM('monitor', 'review', 'block') NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_rule_type (rule_type),
    INDEX idx_active (is_active)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS fraud_alerts (
    alert_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    transaction_id BIGINT UNSIGNED,
    customer_id BIGINT UNSIGNED NOT NULL,
    rule_id INT UNSIGNED,
    alert_type ENUM('velocity', 'unusual_amount', 'location_change', 'device_change', 'ml_anomaly') NOT NULL,
    risk_score INT NOT NULL,
    alert_details JSON,
    status ENUM('pending', 'investigating', 'cleared', 'confirmed_fraud') DEFAULT 'pending',
    action_taken ENUM('none', 'blocked', 'reversed', 'account_frozen'),
    investigated_by VARCHAR(100),
    investigated_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (rule_id) REFERENCES risk_rules(rule_id),
    INDEX idx_customer_alerts (customer_id, created_at DESC),
    INDEX idx_status (status),
    INDEX idx_created (created_at DESC)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS device_fingerprints (
    fingerprint_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id BIGINT UNSIGNED NOT NULL,
    device_hash VARCHAR(64) NOT NULL,
    device_type VARCHAR(50),
    operating_system VARCHAR(50),
    browser VARCHAR(50),
    ip_address VARCHAR(45),
    location_country CHAR(2),
    location_city VARCHAR(100),
    first_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    trust_score INT DEFAULT 50,
    is_blocked BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    UNIQUE INDEX idx_customer_device (customer_id, device_hash),
    INDEX idx_device_hash (device_hash),
    INDEX idx_trust_score (trust_score)
) ENGINE=InnoDB;

-- =========================================
-- 7. COMPLIANCE & AUDIT
-- =========================================

CREATE TABLE IF NOT EXISTS aml_checks (
    check_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id BIGINT UNSIGNED NOT NULL,
    check_type ENUM('sanctions', 'pep', 'adverse_media', 'watchlist') NOT NULL,
    check_provider VARCHAR(50),
    check_date DATE NOT NULL,
    result ENUM('clear', 'potential_match', 'confirmed_match') NOT NULL,
    match_details JSON,
    reviewed_by VARCHAR(100),
    reviewed_at TIMESTAMP NULL,
    decision ENUM('approved', 'rejected', 'escalated'),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    INDEX idx_customer_checks (customer_id, check_date DESC),
    INDEX idx_result (result),
    INDEX idx_check_type (check_type)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS sar_reports (
    report_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id BIGINT UNSIGNED NOT NULL,
    filing_date DATE NOT NULL,
    reporting_period_start DATE NOT NULL,
    reporting_period_end DATE NOT NULL,
    suspicious_activity TEXT NOT NULL,
    total_amount DECIMAL(19,4),
    currency CHAR(3),
    filing_status ENUM('draft', 'submitted', 'acknowledged') DEFAULT 'draft',
    filing_reference VARCHAR(100),
    prepared_by VARCHAR(100),
    approved_by VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    INDEX idx_customer_sars (customer_id),
    INDEX idx_filing_date (filing_date),
    INDEX idx_status (filing_status)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS audit_logs (
    audit_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(100) NOT NULL,
    action_type VARCHAR(50) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id BIGINT UNSIGNED NOT NULL,
    old_values JSON,
    new_values JSON,
    ip_address VARCHAR(45),
    user_agent VARCHAR(500),
    session_id VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user (user_id),
    INDEX idx_entity (entity_type, entity_id),
    INDEX idx_created (created_at DESC),
    INDEX idx_action (action_type)
) ENGINE=InnoDB PARTITION BY RANGE (YEAR(created_at)) (
    PARTITION p2024 VALUES LESS THAN (2025),
    PARTITION p2025 VALUES LESS THAN (2026),
    PARTITION p2026 VALUES LESS THAN (2027),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);

-- =========================================
-- 8. LOANS & CREDIT
-- =========================================

CREATE TABLE IF NOT EXISTS loan_applications (
    application_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id BIGINT UNSIGNED NOT NULL,
    loan_type ENUM('personal', 'mortgage', 'auto', 'business', 'student') NOT NULL,
    requested_amount DECIMAL(15,2) NOT NULL,
    currency CHAR(3) DEFAULT 'USD',
    loan_purpose VARCHAR(500),
    term_months INT NOT NULL,
    requested_rate DECIMAL(5,4),
    credit_score INT,
    debt_to_income DECIMAL(5,2),
    status ENUM('draft', 'submitted', 'under_review', 'approved', 'rejected', 'withdrawn') DEFAULT 'draft',
    decision_date TIMESTAMP NULL,
    decision_reason VARCHAR(500),
    approved_amount DECIMAL(15,2),
    approved_rate DECIMAL(5,4),
    approved_term_months INT,
    application_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    INDEX idx_customer_apps (customer_id),
    INDEX idx_status (status),
    INDEX idx_application_date (application_date DESC)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS loan_accounts (
    loan_account_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    account_id BIGINT UNSIGNED NOT NULL,
    application_id BIGINT UNSIGNED NOT NULL,
    principal_amount DECIMAL(15,2) NOT NULL,
    outstanding_principal DECIMAL(15,2) NOT NULL,
    interest_rate DECIMAL(5,4) NOT NULL,
    term_months INT NOT NULL,
    monthly_payment DECIMAL(15,2) NOT NULL,
    origination_date DATE NOT NULL,
    first_payment_date DATE NOT NULL,
    maturity_date DATE NOT NULL,
    last_payment_date DATE,
    next_payment_date DATE,
    payments_made INT DEFAULT 0,
    payments_remaining INT NOT NULL,
    status ENUM('active', 'paid_off', 'defaulted', 'charged_off') DEFAULT 'active',
    FOREIGN KEY (account_id) REFERENCES accounts(account_id),
    FOREIGN KEY (application_id) REFERENCES loan_applications(application_id),
    INDEX idx_account (account_id),
    INDEX idx_status (status),
    INDEX idx_next_payment (next_payment_date)
) ENGINE=InnoDB;

-- =========================================
-- 9. FEES & CHARGES
-- =========================================

CREATE TABLE IF NOT EXISTS fee_schedule (
    fee_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    fee_code VARCHAR(20) NOT NULL,
    fee_name VARCHAR(100) NOT NULL,
    fee_type ENUM('transaction', 'maintenance', 'overdraft', 'wire', 'foreign_exchange') NOT NULL,
    amount DECIMAL(15,2),
    percentage DECIMAL(5,4),
    minimum_amount DECIMAL(15,2),
    maximum_amount DECIMAL(15,2),
    currency CHAR(3) DEFAULT 'USD',
    is_active BOOLEAN DEFAULT TRUE,
    effective_date DATE NOT NULL,
    end_date DATE,
    UNIQUE INDEX idx_fee_code (fee_code),
    INDEX idx_fee_type (fee_type),
    INDEX idx_effective (effective_date, end_date)
) ENGINE=InnoDB;

-- =========================================
-- 10. NOTIFICATIONS & ALERTS
-- =========================================

CREATE TABLE IF NOT EXISTS notification_preferences (
    preference_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id BIGINT UNSIGNED NOT NULL,
    notification_type VARCHAR(50) NOT NULL,
    email_enabled BOOLEAN DEFAULT TRUE,
    sms_enabled BOOLEAN DEFAULT FALSE,
    push_enabled BOOLEAN DEFAULT TRUE,
    in_app_enabled BOOLEAN DEFAULT TRUE,
    threshold_amount DECIMAL(15,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    UNIQUE INDEX idx_customer_type (customer_id, notification_type)
) ENGINE=InnoDB;

-- =========================================
-- Show tables created
-- =========================================
SHOW TABLES;
SELECT 'FinTech tables created successfully' AS status;