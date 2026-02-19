-- =========================================
-- FinTech Platform - Constraints
-- =========================================

USE fintech;

-- =========================================
-- Additional Check Constraints
-- =========================================

-- Ensure balances are consistent
ALTER TABLE accounts
ADD CONSTRAINT chk_balances
CHECK (available_balance <= balance);

-- Ensure valid interest rates
ALTER TABLE accounts
ADD CONSTRAINT chk_interest_rate
CHECK (interest_rate >= 0 AND interest_rate <= 100);

-- Ensure valid percentages
ALTER TABLE account_holders
ADD CONSTRAINT chk_ownership
CHECK (ownership_percentage >= 0 AND ownership_percentage <= 100);

-- Ensure positive amounts
ALTER TABLE transactions
ADD CONSTRAINT chk_positive_amount
CHECK (amount > 0);

-- Ensure valid exchange rates
ALTER TABLE exchange_rates
ADD CONSTRAINT chk_exchange_rate
CHECK (exchange_rate > 0);

-- Ensure valid loan terms
ALTER TABLE loan_applications
ADD CONSTRAINT chk_term_months
CHECK (term_months > 0 AND term_months <= 360);

-- Ensure valid credit scores
ALTER TABLE loan_applications
ADD CONSTRAINT chk_credit_score
CHECK (credit_score IS NULL OR (credit_score >= 300 AND credit_score <= 850));

-- =========================================
-- Unique Constraints
-- =========================================

-- Prevent duplicate exchange rates for same date
ALTER TABLE exchange_rates
ADD CONSTRAINT uc_exchange_rate_date
UNIQUE (from_currency, to_currency, rate_date);

-- Prevent duplicate KYC documents
ALTER TABLE kyc_documents
ADD CONSTRAINT uc_document_number
UNIQUE (document_type, document_number);

-- Ensure one primary address per customer
ALTER TABLE customer_addresses
ADD CONSTRAINT uc_primary_address
UNIQUE (customer_id, is_primary);

-- =========================================
-- Default Values
-- =========================================

-- Set default currencies
ALTER TABLE transactions
ALTER COLUMN currency SET DEFAULT 'USD';

ALTER TABLE journal_lines
ALTER COLUMN currency SET DEFAULT 'USD';

-- =========================================
-- Triggers for Data Integrity
-- =========================================

DELIMITER //

-- Trigger to update account balance after transaction
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

-- Trigger to validate journal entry balance
CREATE TRIGGER validate_journal_balance
BEFORE INSERT ON journal_entries
FOR EACH ROW
BEGIN
    IF NEW.total_debits != NEW.total_credits THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Journal entry must balance (debits = credits)';
    END IF;
END//

-- Trigger to prevent negative account balances (except for credit accounts)
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

-- Trigger to maintain customer risk scoring
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

-- Trigger to enforce single default payment method
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

-- Trigger to auto-generate account numbers
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

-- Trigger to log audit trail for sensitive operations
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

-- =========================================
-- Foreign Key Constraints (Additional)
-- =========================================

-- Ensure transfer references valid transactions
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

-- =========================================
-- Performance Constraints
-- =========================================

-- Limit the number of active accounts per customer
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
