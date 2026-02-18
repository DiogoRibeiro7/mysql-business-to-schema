-- PostgreSQL Schema
-- Converted from MySQL on 2026-02-17T23:11:17.373138
-- Generator: MySQL to PostgreSQL Converter

-- Enum Types
CREATE TYPE customers_status AS ENUM ('low', 'medium', 'high', 'prohibited');
CREATE TYPE kyc_documents_status AS ENUM ('pending', 'verified', 'rejected', 'expired');
CREATE TYPE customer_addresses_status AS ENUM ('residential', 'business', 'mailing');
CREATE TYPE accounts_status AS ENUM ('pending', 'active', 'frozen', 'closed');
CREATE TYPE chart_of_accounts_status AS ENUM ('debit', 'credit');
CREATE TYPE journal_entries_status AS ENUM ('draft', 'posted', 'reversed');
CREATE TYPE transactions_status AS ENUM ('online', 'mobile', 'atm', 'branch', 'phone', 'system');
CREATE TYPE transfers_status AS ENUM ('internal', 'domestic_wire', 'international_wire', 'ach', 'p2p');
CREATE TYPE payment_methods_status AS ENUM ('card', 'bank_account', 'wallet');
CREATE TYPE cards_status AS ENUM ('visa', 'mastercard', 'amex', 'discover');
CREATE TYPE risk_rules_status AS ENUM ('velocity', 'amount', 'geographic', 'behavioral', 'ml_score');
CREATE TYPE fraud_alerts_status AS ENUM ('none', 'blocked', 'reversed', 'account_frozen');
CREATE TYPE aml_checks_status AS ENUM ('approved', 'rejected', 'escalated');
CREATE TYPE sar_reports_status AS ENUM ('draft', 'submitted', 'acknowledged');
CREATE TYPE loan_applications_status AS ENUM ('draft', 'submitted', 'under_review', 'approved', 'rejected', 'withdrawn');
CREATE TYPE loan_accounts_status AS ENUM ('active', 'paid_off', 'defaulted', 'charged_off');

DROP DATABASE IF EXISTS fintech;
-- Create database (run as superuser)
-- CREATE DATABASE fintech;
-- \c fintech

SHOW DATABASES LIKE 'fintech';
SELECT 'FinTech database created successfully' AS status;
CREATE TABLE IF NOT EXISTS customers (
    customer_type customers_status NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    status customers_status DEFAULT 'pending_kyc',
    risk_level customers_status DEFAULT 'medium',
    onboarding_date DATE NOT NULL,
    last_activity TIMESTAMP NULL,
    preferred_currency CHAR(3) DEFAULT 'USD',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (email)
);

CREATE TABLE IF NOT EXISTS individual_customers (
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    date_of_birth DATE NOT NULL,
    ssn_encrypted BYTEA,
    annual_income DECIMAL(15,2),
    source_of_wealth VARCHAR(255)
);

ALTER TABLE individual_customers ADD CONSTRAINT fk_individual_customers_customer_id FOREIGN KEY (customer_id) REFERENCES customers(customer_id);
CREATE TABLE IF NOT EXISTS business_customers (
    business_name VARCHAR(255) NOT NULL,
    business_type VARCHAR(100),
    registration_number VARCHAR(50),
    tax_id_encrypted BYTEA,
    incorporation_country CHAR(2),
    annual_revenue DECIMAL(15,2),
    number_of_employees INTEGER,
    industry VARCHAR(100),
    website VARCHAR(255),
    UNIQUE (registration_number)
);

ALTER TABLE business_customers ADD CONSTRAINT fk_business_customers_customer_id FOREIGN KEY (customer_id) REFERENCES customers(customer_id);
CREATE TABLE IF NOT EXISTS kyc_documents (
    customer_id BIGINT NOT NULL,
    document_type kyc_documents_status NOT NULL,
    document_number VARCHAR(100),
    issue_date DATE,
    expiry_date DATE,
    issuing_country CHAR(2),
    verification_status kyc_documents_status DEFAULT 'pending',
    verified_at TIMESTAMP NULL,
    verified_by VARCHAR(100),
    document_hash VARCHAR(64)
);

ALTER TABLE kyc_documents ADD CONSTRAINT fk_kyc_documents_customer_id FOREIGN KEY (customer_id) REFERENCES customers(customer_id);
CREATE TABLE IF NOT EXISTS customer_addresses (
    customer_id BIGINT NOT NULL,
    address_type customer_addresses_status NOT NULL,
    street_address_1 VARCHAR(255) NOT NULL,
    street_address_2 VARCHAR(255),
    city VARCHAR(100) NOT NULL,
    state_province VARCHAR(100),
    postal_code VARCHAR(20),
    country CHAR(2) NOT NULL,
    verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE customer_addresses ADD CONSTRAINT fk_customer_addresses_customer_id FOREIGN KEY (customer_id) REFERENCES customers(customer_id);
CREATE TABLE IF NOT EXISTS accounts (
    account_number VARCHAR(20) NOT NULL,
    currency CHAR(3) NOT NULL DEFAULT 'USD',
    status accounts_status DEFAULT 'pending',
    balance DECIMAL(19,4) DEFAULT 0.00,
    minimum_balance DECIMAL(15,2) DEFAULT 0.00,
    opened_date DATE NOT NULL,
    closed_date DATE,
    last_transaction_date TIMESTAMP NULL,
    last_interest_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    version INTEGER DEFAULT 0,
    UNIQUE (account_number)
);

CREATE TABLE IF NOT EXISTS account_holders (
    account_id BIGINT NOT NULL,
    customer_id BIGINT NOT NULL,
    ownership_percentage DECIMAL(5,2) DEFAULT 100.00,
    added_date DATE NOT NULL,
    removed_date DATE,
    UNIQUE (account_id, customer_id)
);

ALTER TABLE account_holders ADD CONSTRAINT fk_account_holders_account_id FOREIGN KEY (account_id) REFERENCES accounts(account_id);
ALTER TABLE account_holders ADD CONSTRAINT fk_account_holders_customer_id FOREIGN KEY (customer_id) REFERENCES customers(customer_id);
CREATE TABLE IF NOT EXISTS chart_of_accounts (
    account_name VARCHAR(100) NOT NULL,
    account_type chart_of_accounts_status NOT NULL,
    parent_account_code VARCHAR(20),
    is_control_account BOOLEAN DEFAULT FALSE,
    normal_balance chart_of_accounts_status NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE chart_of_accounts ADD CONSTRAINT fk_chart_of_accounts_parent_account_code FOREIGN KEY (parent_account_code) REFERENCES chart_of_accounts(account_code);
CREATE TABLE IF NOT EXISTS journal_entries (
    entry_date DATE NOT NULL,
    posting_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    description VARCHAR(500) NOT NULL,
    reference_type VARCHAR(50),
    total_credits DECIMAL(19,4) NOT NULL,
    status journal_entries_status DEFAULT 'posted',
    posted_by VARCHAR(100),
    reversed_by_journal_id BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS journal_lines (
    journal_id BIGINT NOT NULL,
    account_code VARCHAR(20) NOT NULL,
    debit_amount DECIMAL(19,4) DEFAULT 0.00,
    credit_amount DECIMAL(19,4) DEFAULT 0.00,
    currency CHAR(3) NOT NULL DEFAULT 'USD',
    exchange_rate DECIMAL(12,6) DEFAULT 1.000000,
    base_currency_amount DECIMAL(19,4) NOT NULL
);

ALTER TABLE journal_lines ADD CONSTRAINT fk_journal_lines_journal_id FOREIGN KEY (journal_id) REFERENCES journal_entries(journal_id);
ALTER TABLE journal_lines ADD CONSTRAINT fk_journal_lines_account_code FOREIGN KEY (account_code) REFERENCES chart_of_accounts(account_code);
CREATE TABLE IF NOT EXISTS transactions (
    transaction_uuid VARCHAR(36) NOT NULL,
    transaction_type transactions_status NOT NULL,
    amount DECIMAL(19,4) NOT NULL,
    currency CHAR(3) NOT NULL,
    balance_after DECIMAL(19,4) NOT NULL,
    description VARCHAR(500),
    reference_number VARCHAR(100),
    status transactions_status DEFAULT 'pending',
    initiated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP NULL,
    reversed_at TIMESTAMP NULL,
    reversal_reason VARCHAR(255),
    channel transactions_status NOT NULL,
    ip_address VARCHAR(45),
    device_id VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (transaction_uuid)
);

ALTER TABLE transactions ADD CONSTRAINT fk_transactions_account_id FOREIGN KEY (account_id) REFERENCES accounts(account_id);
CREATE TABLE IF NOT EXISTS transfers (
    from_transaction_id BIGINT NOT NULL,
    to_transaction_id BIGINT NOT NULL,
    transfer_type transfers_status NOT NULL,
    amount DECIMAL(19,4) NOT NULL,
    from_currency CHAR(3) NOT NULL,
    to_currency CHAR(3) NOT NULL,
    exchange_rate DECIMAL(12,6) DEFAULT 1.000000,
    fee_amount DECIMAL(15,2) DEFAULT 0.00,
    swift_code VARCHAR(11),
    routing_number VARCHAR(20),
    beneficiary_name VARCHAR(255),
    beneficiary_reference VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE transfers ADD CONSTRAINT fk_transfers_from_transaction_id FOREIGN KEY (from_transaction_id) REFERENCES transactions(transaction_id);
ALTER TABLE transfers ADD CONSTRAINT fk_transfers_to_transaction_id FOREIGN KEY (to_transaction_id) REFERENCES transactions(transaction_id);
CREATE TABLE IF NOT EXISTS payment_methods (
    customer_id BIGINT NOT NULL,
    method_type payment_methods_status NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE payment_methods ADD CONSTRAINT fk_payment_methods_customer_id FOREIGN KEY (customer_id) REFERENCES customers(customer_id);
CREATE TABLE IF NOT EXISTS cards (
    payment_method_id BIGINT NOT NULL,
    card_number_masked VARCHAR(19) NOT NULL,
    card_brand cards_status NOT NULL,
    expiry_month SMALLINT NOT NULL,
    expiry_year SMALLINT NOT NULL,
    cardholder_name VARCHAR(255) NOT NULL,
    billing_address_id BIGINT,
    token VARCHAR(100),
    UNIQUE (card_number_hash)
);

ALTER TABLE cards ADD CONSTRAINT fk_cards_payment_method_id FOREIGN KEY (payment_method_id) REFERENCES payment_methods(payment_method_id);
ALTER TABLE cards ADD CONSTRAINT fk_cards_billing_address_id FOREIGN KEY (billing_address_id) REFERENCES customer_addresses(address_id);
CREATE TABLE IF NOT EXISTS currencies (
    currency_name VARCHAR(50) NOT NULL,
    symbol VARCHAR(5),
    decimal_places SMALLINT DEFAULT 2,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS exchange_rates (
    from_currency CHAR(3) NOT NULL,
    to_currency CHAR(3) NOT NULL,
    rate_date DATE NOT NULL,
    exchange_rate DECIMAL(12,6) NOT NULL,
    rate_source VARCHAR(50) DEFAULT 'SYSTEM',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (from_currency, to_currency, rate_date)
);

ALTER TABLE exchange_rates ADD CONSTRAINT fk_exchange_rates_from_currency FOREIGN KEY (from_currency) REFERENCES currencies(currency_code);
ALTER TABLE exchange_rates ADD CONSTRAINT fk_exchange_rates_to_currency FOREIGN KEY (to_currency) REFERENCES currencies(currency_code);
CREATE TABLE IF NOT EXISTS risk_rules (
    rule_name VARCHAR(100) NOT NULL,
    rule_type risk_rules_status NOT NULL,
    rule_condition JSONB NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS fraud_alerts (
    transaction_id BIGINT,
    customer_id BIGINT NOT NULL,
    rule_id INTEGER,
    alert_type fraud_alerts_status NOT NULL,
    risk_score INTEGER NOT NULL,
    alert_details JSONB,
    status fraud_alerts_status DEFAULT 'pending',
    action_taken fraud_alerts_status,
    investigated_by VARCHAR(100),
    investigated_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE fraud_alerts ADD CONSTRAINT fk_fraud_alerts_transaction_id FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id);
ALTER TABLE fraud_alerts ADD CONSTRAINT fk_fraud_alerts_customer_id FOREIGN KEY (customer_id) REFERENCES customers(customer_id);
ALTER TABLE fraud_alerts ADD CONSTRAINT fk_fraud_alerts_rule_id FOREIGN KEY (rule_id) REFERENCES risk_rules(rule_id);
CREATE TABLE IF NOT EXISTS device_fingerprints (
    customer_id BIGINT NOT NULL,
    device_hash VARCHAR(64) NOT NULL,
    device_type VARCHAR(50),
    operating_system VARCHAR(50),
    browser VARCHAR(50),
    ip_address VARCHAR(45),
    location_country CHAR(2),
    location_city VARCHAR(100),
    first_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    trust_score INTEGER DEFAULT 50,
    is_blocked BOOLEAN DEFAULT FALSE,
    UNIQUE (customer_id, device_hash)
);

ALTER TABLE device_fingerprints ADD CONSTRAINT fk_device_fingerprints_customer_id FOREIGN KEY (customer_id) REFERENCES customers(customer_id);
CREATE TABLE IF NOT EXISTS aml_checks (
    customer_id BIGINT NOT NULL,
    result aml_checks_status NOT NULL,
    match_details JSONB,
    reviewed_by VARCHAR(100),
    reviewed_at TIMESTAMP NULL,
    decision aml_checks_status,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE aml_checks ADD CONSTRAINT fk_aml_checks_customer_id FOREIGN KEY (customer_id) REFERENCES customers(customer_id);
CREATE TABLE IF NOT EXISTS sar_reports (
    customer_id BIGINT NOT NULL,
    filing_date DATE NOT NULL,
    reporting_period_start DATE NOT NULL,
    reporting_period_end DATE NOT NULL,
    suspicious_activity TEXT NOT NULL,
    total_amount DECIMAL(19,4),
    currency CHAR(3),
    filing_status sar_reports_status DEFAULT 'draft',
    filing_reference VARCHAR(100),
    prepared_by VARCHAR(100),
    approved_by VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE sar_reports ADD CONSTRAINT fk_sar_reports_customer_id FOREIGN KEY (customer_id) REFERENCES customers(customer_id);
CREATE TABLE IF NOT EXISTS audit_logs (
    user_id VARCHAR(100) NOT NULL,
    action_type VARCHAR(50) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id BIGINT NOT NULL,
    old_values JSONB,
    new_values JSONB,
    ip_address VARCHAR(45),
    user_agent VARCHAR(500),
    session_id VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PARTITION TEXT VALUES LESS THAN (2026),
    PARTITION TEXT VALUES LESS THAN (2027),
    PARTITION TEXT VALUES LESS THAN MAXVALUE
);

CREATE TABLE IF NOT EXISTS loan_applications (
    customer_id BIGINT NOT NULL,
    loan_type loan_applications_status NOT NULL,
    requested_amount DECIMAL(15,2) NOT NULL,
    currency CHAR(3) DEFAULT 'USD',
    loan_purpose VARCHAR(500),
    term_months INTEGER NOT NULL,
    requested_rate DECIMAL(5,4),
    credit_score INTEGER,
    debt_to_income DECIMAL(5,2),
    status loan_applications_status DEFAULT 'draft',
    decision_date TIMESTAMP NULL,
    decision_reason VARCHAR(500),
    approved_amount DECIMAL(15,2),
    approved_rate DECIMAL(5,4),
    approved_term_months INTEGER,
    application_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE loan_applications ADD CONSTRAINT fk_loan_applications_customer_id FOREIGN KEY (customer_id) REFERENCES customers(customer_id);
CREATE TABLE IF NOT EXISTS loan_accounts (
    account_id BIGINT NOT NULL,
    application_id BIGINT NOT NULL,
    principal_amount DECIMAL(15,2) NOT NULL,
    outstanding_principal DECIMAL(15,2) NOT NULL,
    interest_rate DECIMAL(5,4) NOT NULL,
    term_months INTEGER NOT NULL,
    monthly_payment DECIMAL(15,2) NOT NULL,
    origination_date DATE NOT NULL,
    first_payment_date DATE NOT NULL,
    maturity_date DATE NOT NULL,
    last_payment_date DATE,
    next_payment_date DATE,
    payments_made INTEGER DEFAULT 0,
    payments_remaining INTEGER NOT NULL,
    status loan_accounts_status DEFAULT 'active'
);

ALTER TABLE loan_accounts ADD CONSTRAINT fk_loan_accounts_account_id FOREIGN KEY (account_id) REFERENCES accounts(account_id);
ALTER TABLE loan_accounts ADD CONSTRAINT fk_loan_accounts_application_id FOREIGN KEY (application_id) REFERENCES loan_applications(application_id);
CREATE TABLE IF NOT EXISTS fee_schedule (
    fee_code VARCHAR(20) NOT NULL,
    fee_name VARCHAR(100) NOT NULL,
    amount DECIMAL(15,2),
    percentage DECIMAL(5,4),
    minimum_amount DECIMAL(15,2),
    maximum_amount DECIMAL(15,2),
    currency CHAR(3) DEFAULT 'USD',
    is_active BOOLEAN DEFAULT TRUE,
    effective_date DATE NOT NULL,
    end_date DATE,
    UNIQUE (fee_code)
);

CREATE TABLE IF NOT EXISTS notification_preferences (
    customer_id BIGINT NOT NULL,
    notification_type VARCHAR(50) NOT NULL,
    email_enabled BOOLEAN DEFAULT TRUE,
    sms_enabled BOOLEAN DEFAULT FALSE,
    push_enabled BOOLEAN DEFAULT TRUE,
    in_app_enabled BOOLEAN DEFAULT TRUE,
    threshold_amount DECIMAL(15,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (customer_id, notification_type)
);

ALTER TABLE notification_preferences ADD CONSTRAINT fk_notification_preferences_customer_id FOREIGN KEY (customer_id) REFERENCES customers(customer_id);
SHOW TABLES;
SELECT 'FinTech tables created successfully' AS status;
ALTER TABLE accounts
ADD CONSTRAINT chk_balances
CHECK (available_balance <= balance);
ALTER TABLE accounts
ADD CONSTRAINT chk_interest_rate
CHECK (interest_rate >= 0 AND interest_rate <= 100);
ALTER TABLE account_holders
ADD CONSTRAINT chk_ownership
CHECK (ownership_percentage >= 0 AND ownership_percentage <= 100);
ALTER TABLE transactions
ADD CONSTRAINT chk_positive_amount
CHECK (amount > 0);
ALTER TABLE exchange_rates
ADD CONSTRAINT chk_exchange_rate
CHECK (exchange_rate > 0);
ALTER TABLE loan_applications
ADD CONSTRAINT chk_term_months
CHECK (term_months > 0 AND term_months <= 360);
ALTER TABLE loan_applications
ADD CONSTRAINT chk_credit_score
CHECK (credit_score IS NULL OR (credit_score >= 300 AND credit_score <= 850));
ALTER TABLE exchange_rates
ADD CONSTRAINT uc_exchange_rate_date
UNIQUE (from_currency, to_currency, rate_date);
ALTER TABLE kyc_documents
ADD CONSTRAINT uc_document_number
UNIQUE (document_type, document_number);
ALTER TABLE customer_addresses
ADD CONSTRAINT uc_primary_address
UNIQUE (customer_id, is_primary);
ALTER TABLE transactions
ALTER COLUMN currency SET DEFAULT 'USD';
ALTER TABLE journal_lines
ALTER COLUMN currency SET DEFAULT 'USD';
DELIMITER //
CREATE TRIGGER update_account_balance_after_transaction
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
IF NEW.status = 'completed' THEN
UPDATE accounts
SET balance = NEW.balance_after,
last_transaction_date = NEW.completed_at,
version = version + 1
WHERE account_id = NEW.account_id;
END IF;
END//
CREATE TRIGGER validate_journal_balance
BEFORE INSERT ON journal_entries
FOR EACH ROW
BEGIN
IF NEW.total_debits != NEW.total_credits THEN
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT = 'Journal entry must balance (debits = credits)';
END IF;
END//
CREATE TRIGGER prevent_negative_balance
BEFORE UPDATE ON accounts
FOR EACH ROW
BEGIN
IF NEW.balance < 0
AND OLD.account_type NOT IN ('credit_card', 'loan')
AND NEW.balance < -NEW.overdraft_limit THEN
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT = 'Insufficient funds';
END IF;
END//
CREATE TRIGGER update_risk_score
AFTER INSERT ON fraud_alerts
FOR EACH ROW
BEGIN
IF NEW.status = 'confirmed_fraud' THEN
UPDATE customers
SET risk_level = 'high'
WHERE customer_id = NEW.customer_id;
END IF;
END//
CREATE TRIGGER enforce_single_default_payment
BEFORE INSERT ON payment_methods
FOR EACH ROW
BEGIN
IF NEW.is_default = TRUE THEN
UPDATE payment_methods
SET is_default = FALSE
WHERE customer_id = NEW.customer_id
AND payment_method_id != NEW.payment_method_id;
END IF;
END//
CREATE TRIGGER generate_account_number
BEFORE INSERT ON accounts
FOR EACH ROW
BEGIN
IF NEW.account_number IS NULL OR NEW.account_number = '' THEN
SET NEW.account_number = CONCAT(
CASE NEW.account_type
WHEN 'checking' THEN '10'
WHEN 'savings' THEN '20'
WHEN 'loan' THEN '30'
WHEN 'credit_card' THEN '40'
WHEN 'investment' THEN '50'
END,
LPAD(NEW.account_id, 10, '0')
);
END IF;
END//
CREATE TRIGGER audit_customer_changes
AFTER UPDATE ON customers
FOR EACH ROW
BEGIN
INSERT INTO audit_logs (
user_id,
action_type,
entity_type,
entity_id,
old_values,
new_values,
created_at
) VALUES (
USER(),
'UPDATE',
'customer',
NEW.customer_id,
JSON_OBJECT(
'status', OLD.status,
'risk_level', OLD.risk_level
),
JSON_OBJECT(
'status', NEW.status,
'risk_level', NEW.risk_level
),
NOW()
);
END//
DELIMITER ;
ALTER TABLE transfers
ADD CONSTRAINT fk_transfer_from_valid
FOREIGN KEY (from_transaction_id)
REFERENCES transactions(transaction_id)
ON DELETE RESTRICT;
ALTER TABLE transfers
ADD CONSTRAINT fk_transfer_to_valid
FOREIGN KEY (to_transaction_id)
REFERENCES transactions(transaction_id)
ON DELETE RESTRICT;
DELIMITER //
CREATE TRIGGER limit_accounts_per_customer
BEFORE INSERT ON account_holders
FOR EACH ROW
BEGIN
DECLARE account_count INT;
SELECT COUNT(*) INTO account_count
FROM account_holders ah
JOIN accounts a ON ah.account_id = a.account_id
WHERE ah.customer_id = NEW.customer_id
AND a.status = 'active';
IF account_count >= 10 THEN
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT = 'Customer cannot have more than 10 active accounts';
END IF;
END//
DELIMITER ;
SELECT 'Constraints created successfully' AS status;
CREATE INDEX idx_transactions_date_range
ON transactions(account_id, initiated_at DESC, status)
INCLUDE (amount, currency, balance_after, description);
CREATE INDEX idx_pending_transactions
ON transactions(status, initiated_at)
WHERE status IN ('pending', 'processing');
CREATE INDEX idx_daily_transactions
ON transactions(DATE(initiated_at), transaction_type, status);
CREATE INDEX idx_transaction_velocity
ON transactions(account_id, initiated_at, amount)
WHERE initiated_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR);
CREATE INDEX idx_account_dashboard
ON accounts(status, account_type, currency)
INCLUDE (balance, available_balance, last_transaction_date);
CREATE INDEX idx_customer_accounts
ON account_holders(customer_id, relationship_type)
INCLUDE (account_id, ownership_percentage);
CREATE INDEX idx_interest_calculation
ON accounts(account_type, last_interest_date, status)
WHERE account_type IN ('savings', 'loan')
AND status = 'active';
CREATE FULLTEXT INDEX ft_individual_name
ON individual_customers(first_name, last_name);
CREATE FULLTEXT INDEX ft_business_name
ON business_customers(business_name);
CREATE INDEX idx_kyc_pending
ON customers(status, risk_level, created_at)
WHERE status = 'pending_kyc';
CREATE INDEX idx_document_expiry
ON kyc_documents(expiry_date, verification_status, customer_id)
WHERE verification_status = 'verified'
AND expiry_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 90 DAY);
CREATE INDEX idx_active_payment_methods
ON payment_methods(customer_id, is_active, is_default)
WHERE is_active = TRUE;
CREATE INDEX idx_card_expiry
ON cards(expiry_year, expiry_month)
WHERE expiry_year >= YEAR(CURDATE());
CREATE INDEX idx_journal_period
ON journal_entries(entry_date, status)
INCLUDE (total_debits, total_credits);
CREATE INDEX idx_journal_lines_period
ON journal_lines(account_code, journal_id)
INCLUDE (debit_amount, credit_amount);
CREATE INDEX idx_chart_accounts_reporting
ON chart_of_accounts(account_type, is_active, parent_account_code);
CREATE INDEX idx_fraud_alerts_active
ON fraud_alerts(customer_id, created_at DESC, status)
WHERE status IN ('pending', 'investigating');
CREATE INDEX idx_device_trust
ON device_fingerprints(customer_id, trust_score, is_blocked)
INCLUDE (device_hash, last_seen);
CREATE INDEX idx_active_risk_rules
ON risk_rules(is_active, rule_type)
WHERE is_active = TRUE;
CREATE INDEX idx_aml_review
ON aml_checks(result, reviewed_at, customer_id)
WHERE result IN ('potential_match', 'confirmed_match')
AND reviewed_at IS NULL;
CREATE INDEX idx_sar_period
ON sar_reports(filing_date, filing_status)
WHERE filing_status != 'acknowledged';
CREATE INDEX idx_audit_user_actions
ON audit_logs(user_id, created_at DESC, action_type);
CREATE INDEX idx_audit_entity_history
ON audit_logs(entity_type, entity_id, created_at DESC);
CREATE INDEX idx_loan_payments_due
ON loan_accounts(next_payment_date, status)
WHERE status = 'active'
AND next_payment_date <= DATE_ADD(CURDATE(), INTERVAL 7 DAY);
CREATE INDEX idx_loan_applications_pending
ON loan_applications(status, application_date)
WHERE status IN ('submitted', 'under_review');
CREATE INDEX idx_current_rates
ON exchange_rates(rate_date DESC, from_currency, to_currency);
CREATE INDEX idx_historical_rates
ON exchange_rates(from_currency, to_currency, rate_date DESC);
CREATE INDEX idx_notification_active
ON notification_preferences(customer_id, notification_type)
WHERE email_enabled = TRUE
OR sms_enabled = TRUE
OR push_enabled = TRUE;
CREATE INDEX idx_monthly_statement
ON transactions(account_id, initiated_at, status, transaction_type)
INCLUDE (amount, currency, balance_after, description, reference_number);
CREATE INDEX idx_transaction_search
ON transactions(reference_number, created_at DESC);
CREATE INDEX idx_customer_360
ON customers(customer_id, status, risk_level)
INCLUDE (email, phone_number, onboarding_date, last_activity);
CREATE INDEX idx_settlement_batch
ON transactions(DATE(completed_at), status, transaction_type)
WHERE status = 'completed'
AND completed_at >= CURDATE();
CREATE INDEX idx_suspicious_monitoring
ON transactions(amount, account_id, initiated_at)
WHERE amount > 10000
AND status = 'completed';
ANALYZE TABLE customers;
ANALYZE TABLE accounts;
ANALYZE TABLE transactions;
ANALYZE TABLE journal_entries;
ANALYZE TABLE fraud_alerts;
SELECT 'Indexes created successfully' AS status;
SELECT
table_name,
index_name,
cardinality,
ROUND((data_length + index_length) / 1024 / 1024, 2) AS size_mb
FROM information_schema.statistics
WHERE table_schema = 'fintech'
GROUP BY table_name, index_name
ORDER BY table_name, index_name;
-- Indexes
