-- =========================================
-- FinTech Platform - Performance Indexes
-- =========================================

USE fintech;

-- =========================================
-- Transaction Performance Indexes
-- =========================================

-- For transaction history queries
CREATE INDEX idx_transactions_date_range
ON transactions(account_id, initiated_at DESC, status)
INCLUDE (amount, currency, balance_after, description);

-- For pending transaction monitoring
CREATE INDEX idx_pending_transactions
ON transactions(status, initiated_at)
WHERE status IN ('pending', 'processing');

-- For daily transaction reports
CREATE INDEX idx_daily_transactions
ON transactions(DATE(initiated_at), transaction_type, status);

-- For fraud detection velocity checks
CREATE INDEX idx_transaction_velocity
ON transactions(account_id, initiated_at, amount)
WHERE initiated_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR);

-- =========================================
-- Account Query Indexes
-- =========================================

-- For account dashboard queries
CREATE INDEX idx_account_dashboard
ON accounts(status, account_type, currency)
INCLUDE (balance, available_balance, last_transaction_date);

-- For customer account lookup
CREATE INDEX idx_customer_accounts
ON account_holders(customer_id, relationship_type)
INCLUDE (account_id, ownership_percentage);

-- For interest calculation batches
CREATE INDEX idx_interest_calculation
ON accounts(account_type, last_interest_date, status)
WHERE account_type IN ('savings', 'loan')
AND status = 'active';

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
ON customers(status, risk_level, created_at)
WHERE status = 'pending_kyc';

-- For document expiry monitoring
CREATE INDEX idx_document_expiry
ON kyc_documents(expiry_date, verification_status, customer_id)
WHERE verification_status = 'verified'
AND expiry_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 90 DAY);

-- =========================================
-- Payment Processing Indexes
-- =========================================

-- For payment method retrieval
CREATE INDEX idx_active_payment_methods
ON payment_methods(customer_id, is_active, is_default)
WHERE is_active = TRUE;

-- For card expiry monitoring
CREATE INDEX idx_card_expiry
ON cards(expiry_year, expiry_month)
WHERE expiry_year >= YEAR(CURDATE());

-- =========================================
-- Ledger & Accounting Indexes
-- =========================================

-- For trial balance generation
CREATE INDEX idx_journal_period
ON journal_entries(entry_date, status)
INCLUDE (total_debits, total_credits);

-- For account reconciliation
CREATE INDEX idx_journal_lines_period
ON journal_lines(account_code, journal_id)
INCLUDE (debit_amount, credit_amount);

-- For financial reporting
CREATE INDEX idx_chart_accounts_reporting
ON chart_of_accounts(account_type, is_active, parent_account_code);

-- =========================================
-- Fraud & Risk Indexes
-- =========================================

-- For real-time fraud scoring
CREATE INDEX idx_fraud_alerts_active
ON fraud_alerts(customer_id, created_at DESC, status)
WHERE status IN ('pending', 'investigating');

-- For device trust scoring
CREATE INDEX idx_device_trust
ON device_fingerprints(customer_id, trust_score, is_blocked)
INCLUDE (device_hash, last_seen);

-- For risk rule evaluation
CREATE INDEX idx_active_risk_rules
ON risk_rules(is_active, rule_type)
WHERE is_active = TRUE;

-- =========================================
-- Compliance & Regulatory Indexes
-- =========================================

-- For AML monitoring
CREATE INDEX idx_aml_review
ON aml_checks(result, reviewed_at, customer_id)
WHERE result IN ('potential_match', 'confirmed_match')
AND reviewed_at IS NULL;

-- For SAR reporting
CREATE INDEX idx_sar_period
ON sar_reports(filing_date, filing_status)
WHERE filing_status != 'acknowledged';

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
ON loan_accounts(next_payment_date, status)
WHERE status = 'active'
AND next_payment_date <= DATE_ADD(CURDATE(), INTERVAL 7 DAY);

-- For loan application workflow
CREATE INDEX idx_loan_applications_pending
ON loan_applications(status, application_date)
WHERE status IN ('submitted', 'under_review');

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
ON notification_preferences(customer_id, notification_type)
WHERE email_enabled = TRUE
OR sms_enabled = TRUE
OR push_enabled = TRUE;

-- =========================================
-- Composite Indexes for Complex Queries
-- =========================================

-- For monthly statements
CREATE INDEX idx_monthly_statement
ON transactions(account_id, initiated_at, status, transaction_type)
INCLUDE (amount, currency, balance_after, description, reference_number);

-- For transaction search
CREATE INDEX idx_transaction_search
ON transactions(reference_number, created_at DESC);

-- For customer 360 view
CREATE INDEX idx_customer_360
ON customers(customer_id, status, risk_level)
INCLUDE (email, phone_number, onboarding_date, last_activity);

-- =========================================
-- Partial Indexes for Specific Workflows
-- =========================================

-- For daily settlement batch
CREATE INDEX idx_settlement_batch
ON transactions(DATE(completed_at), status, transaction_type)
WHERE status = 'completed'
AND completed_at >= CURDATE();

-- For suspicious transaction monitoring
CREATE INDEX idx_suspicious_monitoring
ON transactions(amount, account_id, initiated_at)
WHERE amount > 10000
AND status = 'completed';

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
FROM information_schema.statistics
WHERE table_schema = 'fintech'
GROUP BY table_name, index_name
ORDER BY table_name, index_name;