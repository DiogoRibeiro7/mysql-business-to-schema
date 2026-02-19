-- =========================================
-- FinTech Platform - Performance Indexes
-- =========================================

USE fintech;

-- =========================================
-- Transaction Performance Indexes
-- =========================================

-- For transaction history queries
CREATE INDEX idx_transactions_date_range
ON transactions(account_id, initiated_at DESC, status);

-- For pending transaction monitoring
CREATE INDEX idx_pending_transactions
ON transactions(status, initiated_at);

-- For daily transaction reports
CREATE INDEX idx_daily_transactions
ON transactions(initiated_at, transaction_type, status);

-- For fraud detection velocity checks
CREATE INDEX idx_transaction_velocity
ON transactions(account_id, initiated_at, amount);

-- =========================================
-- Account Query Indexes
-- =========================================

-- For account dashboard queries
CREATE INDEX idx_account_dashboard
ON accounts(status, account_type, currency);

-- For customer account lookup

-- For interest calculation batches
CREATE INDEX idx_interest_calculation
ON accounts(account_type, last_interest_date, status);

-- =========================================
-- Customer Search Indexes
-- =========================================

-- For customer search by name
CREATE FULLTEXT INDEX ft_individual_name
ON individual_customers(first_name, last_name);

CREATE FULLTEXT INDEX ft_business_name
ON business_customers(business_name);

-- For KYC status monitoring
CREATE INDEX idx_kyc_pending
ON customers(status, risk_level, created_at);

-- For document expiry monitoring
CREATE INDEX idx_document_expiry
ON kyc_documents(expiry_date, verification_status, customer_id);

-- =========================================
-- Payment Processing Indexes
-- =========================================

-- For payment method retrieval
CREATE INDEX idx_active_payment_methods
ON payment_methods(customer_id, is_active, is_default);

-- For card expiry monitoring
CREATE INDEX idx_card_expiry
ON cards(expiry_year, expiry_month);

-- =========================================
-- Ledger & Accounting Indexes
-- =========================================

-- For trial balance generation
CREATE INDEX idx_journal_period
ON journal_entries(entry_date, status);

-- For account reconciliation
CREATE INDEX idx_journal_lines_period
ON journal_lines(account_code, journal_id);

-- For financial reporting
CREATE INDEX idx_chart_accounts_reporting
ON chart_of_accounts(account_type, is_active, parent_account_code);

-- =========================================
-- Fraud & Risk Indexes
-- =========================================

-- For real-time fraud scoring
CREATE INDEX idx_fraud_alerts_active
ON fraud_alerts(customer_id, created_at DESC, status);

-- For device trust scoring
CREATE INDEX idx_device_trust
ON device_fingerprints(customer_id, trust_score, is_blocked);

-- For risk rule evaluation
CREATE INDEX idx_active_risk_rules
ON risk_rules(is_active, rule_type);

-- =========================================
-- Compliance & Regulatory Indexes
-- =========================================

-- For AML monitoring
CREATE INDEX idx_aml_review
ON aml_checks(result, reviewed_at, customer_id);

-- For SAR reporting
CREATE INDEX idx_sar_period
ON sar_reports(filing_date, filing_status);

-- For audit trail queries
CREATE INDEX idx_audit_user_actions
ON audit_logs(user_id, created_at DESC, action_type);

CREATE INDEX idx_audit_entity_history
ON audit_logs(entity_type, entity_id, created_at DESC);

-- =========================================
-- Loan Management Indexes
-- =========================================

-- For loan payment processing
CREATE INDEX idx_loan_payments_due
ON loan_accounts(next_payment_date, status);

-- For loan application workflow
CREATE INDEX idx_loan_applications_pending
ON loan_applications(status, application_date);

-- =========================================
-- Currency & Exchange Indexes
-- =========================================

-- For current exchange rates
CREATE INDEX idx_current_rates
ON exchange_rates(rate_date DESC, from_currency, to_currency);

-- For historical rate lookup
CREATE INDEX idx_historical_rates
ON exchange_rates(from_currency, to_currency, rate_date DESC);

-- =========================================
-- Notification Indexes
-- =========================================

-- For notification preference lookup
CREATE INDEX idx_notification_active
ON notification_preferences(customer_id, notification_type);

-- =========================================
-- Composite Indexes for Complex Queries
-- =========================================

-- For monthly statements
CREATE INDEX idx_monthly_statement
ON transactions(account_id, initiated_at, status, transaction_type);

-- For transaction search
CREATE INDEX idx_transaction_search
ON transactions(reference_number, created_at DESC);

-- For customer 360 view
CREATE INDEX idx_customer_360
ON customers(customer_id, status, risk_level);

-- =========================================
-- Partial Indexes for Specific Workflows
-- =========================================

-- For daily settlement batch
CREATE INDEX idx_settlement_batch
ON transactions(completed_at, status, transaction_type);

-- For suspicious transaction monitoring
CREATE INDEX idx_suspicious_monitoring
ON transactions(amount, account_id, initiated_at);

-- =========================================
-- Statistics Update
-- =========================================

-- Update table statistics for query optimizer
ANALYZE TABLE customers;
ANALYZE TABLE accounts;
ANALYZE TABLE transactions;
ANALYZE TABLE journal_entries;
ANALYZE TABLE fraud_alerts;

SELECT 'Indexes created successfully' AS status;

-- Show index usage statistics
SELECT
    table_name,
    index_name,
    cardinality,
    ROUND((data_length + index_length) / 1024 / 1024, 2) AS size_mb
FROM information_schema.statistics;
