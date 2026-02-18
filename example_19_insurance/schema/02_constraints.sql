-- ============================================================================
-- CONSTRAINTS FOR INSURANCE MANAGEMENT PLATFORM
-- ============================================================================

USE insurance_platform;

-- ============================================================================
-- CHECK CONSTRAINTS
-- ============================================================================

-- Customers table
ALTER TABLE customers
    ADD CONSTRAINT chk_customers_income
    CHECK (annual_income IS NULL OR annual_income >= 0),
    ADD CONSTRAINT chk_customers_credit
    CHECK (credit_score IS NULL OR (credit_score >= 300 AND credit_score <= 850)),
    ADD CONSTRAINT chk_customers_type_fields
    CHECK ((customer_type = 'individual' AND first_name IS NOT NULL AND last_name IS NOT NULL) OR
           (customer_type = 'corporate' AND company_name IS NOT NULL));

-- Beneficiaries table
ALTER TABLE beneficiaries
    ADD CONSTRAINT chk_beneficiaries_allocation
    CHECK (percentage_allocation > 0 AND percentage_allocation <= 100);

-- Products table
ALTER TABLE products
    ADD CONSTRAINT chk_products_coverage
    CHECK ((min_coverage_amount IS NULL OR min_coverage_amount > 0) AND
           (max_coverage_amount IS NULL OR max_coverage_amount > min_coverage_amount)),
    ADD CONSTRAINT chk_products_deductible
    CHECK (default_deductible IS NULL OR default_deductible >= 0),
    ADD CONSTRAINT chk_products_term
    CHECK ((min_term_months IS NULL OR min_term_months > 0) AND
           (max_term_months IS NULL OR max_term_months >= min_term_months)),
    ADD CONSTRAINT chk_products_age
    CHECK ((min_age IS NULL OR min_age >= 0) AND
           (max_age IS NULL OR max_age > min_age)),
    ADD CONSTRAINT chk_products_premium_rate
    CHECK (base_premium_rate IS NULL OR base_premium_rate > 0);

-- Policies table
ALTER TABLE policies
    ADD CONSTRAINT chk_policies_coverage
    CHECK (coverage_amount > 0),
    ADD CONSTRAINT chk_policies_deductible
    CHECK (deductible >= 0),
    ADD CONSTRAINT chk_policies_dates
    CHECK (expiry_date > effective_date),
    ADD CONSTRAINT chk_policies_premium
    CHECK (premium_amount > 0),
    ADD CONSTRAINT chk_policies_riders
    CHECK (total_riders_premium >= 0),
    ADD CONSTRAINT chk_policies_discount
    CHECK (total_discount_amount >= 0),
    ADD CONSTRAINT chk_policies_risk_score
    CHECK (risk_score IS NULL OR (risk_score >= 0 AND risk_score <= 100)),
    ADD CONSTRAINT chk_policies_commission
    CHECK (commission_rate IS NULL OR (commission_rate >= 0 AND commission_rate <= 100)),
    ADD CONSTRAINT chk_policies_refund
    CHECK (refund_amount IS NULL OR refund_amount >= 0);

-- Policy beneficiaries table
ALTER TABLE policy_beneficiaries
    ADD CONSTRAINT chk_policy_beneficiaries_allocation
    CHECK (percentage_allocation > 0 AND percentage_allocation <= 100);

-- Policy items table
ALTER TABLE policy_items
    ADD CONSTRAINT chk_policy_items_value
    CHECK ((estimated_value IS NULL OR estimated_value > 0) AND
           (insured_value IS NULL OR insured_value > 0)),
    ADD CONSTRAINT chk_policy_items_year
    CHECK ((year IS NULL OR year >= 1900 AND year <= YEAR(CURDATE()) + 1) AND
           (year_built IS NULL OR year_built >= 1800 AND year_built <= YEAR(CURDATE()))),
    ADD CONSTRAINT chk_policy_items_sqft
    CHECK (square_footage IS NULL OR square_footage > 0);

-- Claims table
ALTER TABLE claims
    ADD CONSTRAINT chk_claims_dates
    CHECK (reported_date >= incident_date),
    ADD CONSTRAINT chk_claims_amounts
    CHECK (claimed_amount > 0 AND
           (approved_amount IS NULL OR approved_amount >= 0) AND
           (deductible_amount IS NULL OR deductible_amount >= 0) AND
           (paid_amount IS NULL OR paid_amount >= 0)),
    ADD CONSTRAINT chk_claims_fraud_score
    CHECK (fraud_score IS NULL OR (fraud_score >= 0 AND fraud_score <= 100)),
    ADD CONSTRAINT chk_claims_decision
    CHECK ((decision_date IS NULL AND approved_amount IS NULL) OR
           (decision_date IS NOT NULL));

-- Billing schedules table
ALTER TABLE billing_schedules
    ADD CONSTRAINT chk_billing_day
    CHECK (billing_day IS NULL OR (billing_day >= 1 AND billing_day <= 31)),
    ADD CONSTRAINT chk_billing_amounts
    CHECK (installment_amount > 0 AND total_annual_premium > 0);

-- Payments table
ALTER TABLE payments
    ADD CONSTRAINT chk_payments_amount
    CHECK (amount != 0);

-- Agents table
ALTER TABLE agents
    ADD CONSTRAINT chk_agents_commission
    CHECK ((commission_structure IS NULL OR JSON_VALID(commission_structure)) AND
           (override_rate IS NULL OR (override_rate >= 0 AND override_rate <= 100))),
    ADD CONSTRAINT chk_agents_metrics
    CHECK (total_policies_sold >= 0 AND total_premium_sold >= 0 AND
           current_month_sales >= 0 AND ytd_sales >= 0),
    ADD CONSTRAINT chk_agents_dates
    CHECK (termination_date IS NULL OR termination_date >= hire_date);

-- Agencies table
ALTER TABLE agencies
    ADD CONSTRAINT chk_agencies_commission
    CHECK (base_commission_rate IS NULL OR (base_commission_rate >= 0 AND base_commission_rate <= 100)),
    ADD CONSTRAINT chk_agencies_metrics
    CHECK (total_agents >= 0 AND total_policies >= 0 AND total_premium >= 0),
    ADD CONSTRAINT chk_agencies_contract
    CHECK (contract_end_date IS NULL OR contract_end_date >= contract_start_date);

-- Brokers table
ALTER TABLE brokers
    ADD CONSTRAINT chk_brokers_commission
    CHECK (commission_rate IS NULL OR (commission_rate >= 0 AND commission_rate <= 100)),
    ADD CONSTRAINT chk_brokers_metrics
    CHECK (total_referrals >= 0 AND total_premium_referred >= 0),
    ADD CONSTRAINT chk_brokers_type_fields
    CHECK ((broker_type = 'company' AND company_name IS NOT NULL) OR
           (broker_type = 'individual' AND first_name IS NOT NULL AND last_name IS NOT NULL));

-- Underwriting applications table
ALTER TABLE underwriting_applications
    ADD CONSTRAINT chk_underwriting_coverage
    CHECK (requested_coverage > 0),
    ADD CONSTRAINT chk_underwriting_term
    CHECK (requested_term_months > 0),
    ADD CONSTRAINT chk_underwriting_risk_score
    CHECK (risk_score IS NULL OR (risk_score >= 0 AND risk_score <= 100)),
    ADD CONSTRAINT chk_underwriting_premiums
    CHECK ((base_premium IS NULL OR base_premium >= 0) AND
           (risk_adjustment IS NULL OR risk_adjustment >= -100) AND
           (final_premium IS NULL OR final_premium >= 0));

-- Reinsurance treaties table
ALTER TABLE reinsurance_treaties
    ADD CONSTRAINT chk_reinsurance_retention
    CHECK (retention_amount IS NULL OR retention_amount >= 0),
    ADD CONSTRAINT chk_reinsurance_cession
    CHECK (cession_percentage IS NULL OR (cession_percentage >= 0 AND cession_percentage <= 100)),
    ADD CONSTRAINT chk_reinsurance_limits
    CHECK ((treaty_limit IS NULL OR treaty_limit > 0) AND
           (occurrence_limit IS NULL OR occurrence_limit > 0) AND
           (aggregate_limit IS NULL OR aggregate_limit > 0)),
    ADD CONSTRAINT chk_reinsurance_dates
    CHECK (expiry_date > effective_date),
    ADD CONSTRAINT chk_reinsurance_premium
    CHECK (reinsurance_premium IS NULL OR reinsurance_premium >= 0),
    ADD CONSTRAINT chk_reinsurance_commission
    CHECK (commission_rate IS NULL OR (commission_rate >= 0 AND commission_rate <= 100));

-- Reinsurance cessions table
ALTER TABLE reinsurance_cessions
    ADD CONSTRAINT chk_cessions_amounts
    CHECK (ceded_amount > 0 AND ceded_premium > 0),
    ADD CONSTRAINT chk_cessions_claims
    CHECK (claims_paid >= 0 AND claims_pending >= 0);

-- Documents table
ALTER TABLE documents
    ADD CONSTRAINT chk_documents_file_size
    CHECK (file_size IS NULL OR file_size > 0);

-- Commissions table
ALTER TABLE commissions
    ADD CONSTRAINT chk_commissions_rate
    CHECK (commission_rate >= 0 AND commission_rate <= 100),
    ADD CONSTRAINT chk_commissions_amount
    CHECK (commission_amount >= 0),
    ADD CONSTRAINT chk_commissions_dates
    CHECK (payment_date IS NULL OR payment_date >= earning_date);

-- ============================================================================
-- UNIQUE CONSTRAINTS
-- ============================================================================

-- Ensure total beneficiary allocation doesn't exceed 100% per policy
ALTER TABLE policy_beneficiaries
    ADD CONSTRAINT uk_policy_allocation
    CHECK ((SELECT SUM(percentage_allocation)
            FROM policy_beneficiaries pb2
            WHERE pb2.policy_id = policy_id
            AND pb2.beneficiary_type = beneficiary_type) <= 100);

-- ============================================================================
-- TRIGGERS FOR DATA INTEGRITY
-- ============================================================================

DELIMITER //

-- Generate policy number
CREATE TRIGGER trg_generate_policy_number
BEFORE INSERT ON policies
FOR EACH ROW
BEGIN
    DECLARE product_code VARCHAR(10);
    DECLARE seq_num INT;

    SELECT product_type INTO product_code
    FROM products WHERE product_id = NEW.product_id;

    SET seq_num = (SELECT COUNT(*) + 1 FROM policies WHERE product_id = NEW.product_id);

    SET NEW.policy_number = CONCAT(
        UPPER(LEFT(product_code, 3)),
        DATE_FORMAT(NOW(), '%Y'),
        LPAD(seq_num, 8, '0')
    );
END//

-- Generate claim number
CREATE TRIGGER trg_generate_claim_number
BEFORE INSERT ON claims
FOR EACH ROW
BEGIN
    SET NEW.claim_number = CONCAT(
        'CLM',
        DATE_FORMAT(NOW(), '%Y%m'),
        LPAD(FLOOR(RAND() * 999999), 6, '0')
    );
END//

-- Update customer risk category based on risk score
CREATE TRIGGER trg_update_customer_risk
AFTER INSERT ON policies
FOR EACH ROW
BEGIN
    DECLARE avg_risk_score DECIMAL(5,2);

    SELECT AVG(risk_score) INTO avg_risk_score
    FROM policies
    WHERE customer_id = NEW.customer_id
      AND status = 'active';

    UPDATE customers
    SET risk_category = CASE
        WHEN avg_risk_score < 25 THEN 'low'
        WHEN avg_risk_score < 50 THEN 'medium'
        WHEN avg_risk_score < 75 THEN 'high'
        ELSE 'very_high'
    END
    WHERE customer_id = NEW.customer_id;
END//

-- Update policy status based on payment
CREATE TRIGGER trg_update_policy_status_payment
AFTER INSERT ON payments
FOR EACH ROW
BEGIN
    IF NEW.payment_type = 'premium' AND NEW.status = 'completed' THEN
        UPDATE policies
        SET status = 'active'
        WHERE policy_id = NEW.policy_id
          AND status = 'pending';
    END IF;
END//

-- Create claim activity on status change
CREATE TRIGGER trg_claim_status_activity
AFTER UPDATE ON claims
FOR EACH ROW
BEGIN
    IF OLD.status != NEW.status THEN
        INSERT INTO claim_activities (claim_id, activity_type, activity_description,
                                    old_status, new_status, actor_type)
        VALUES (NEW.claim_id, 'status_change',
                CONCAT('Status changed from ', OLD.status, ' to ', NEW.status),
                OLD.status, NEW.status, 'system');
    END IF;
END//

-- Calculate agent commission on policy creation
CREATE TRIGGER trg_calculate_agent_commission
AFTER INSERT ON policies
FOR EACH ROW
BEGIN
    DECLARE base_commission_rate DECIMAL(5,2);

    IF NEW.agent_id IS NOT NULL AND NEW.status = 'active' THEN
        -- Get agent's commission rate for this product
        SELECT JSON_EXTRACT(commission_structure,
                          CONCAT('$."', NEW.product_id, '"'))
        INTO base_commission_rate
        FROM agents
        WHERE agent_id = NEW.agent_id;

        -- Use default if product-specific rate not found
        IF base_commission_rate IS NULL THEN
            SET base_commission_rate = NEW.commission_rate;
        END IF;

        -- Create commission record
        INSERT INTO commissions (policy_id, agent_id, commission_type,
                               commission_rate, commission_amount,
                               earning_date, status)
        VALUES (NEW.policy_id, NEW.agent_id,
                IF(NEW.is_renewal, 'renewal', 'new_business'),
                base_commission_rate,
                NEW.premium_amount * base_commission_rate / 100,
                NEW.effective_date, 'pending');
    END IF;
END//

-- Update agent performance metrics
CREATE TRIGGER trg_update_agent_metrics
AFTER INSERT ON policies
FOR EACH ROW
BEGIN
    IF NEW.agent_id IS NOT NULL AND NEW.status = 'active' THEN
        UPDATE agents
        SET total_policies_sold = total_policies_sold + 1,
            total_premium_sold = total_premium_sold + NEW.premium_amount,
            current_month_sales = current_month_sales + NEW.premium_amount,
            ytd_sales = ytd_sales + NEW.premium_amount
        WHERE agent_id = NEW.agent_id;
    END IF;
END//

-- Update agency metrics
CREATE TRIGGER trg_update_agency_metrics
AFTER INSERT ON policies
FOR EACH ROW
BEGIN
    DECLARE agency_id_val BIGINT;

    IF NEW.agent_id IS NOT NULL AND NEW.status = 'active' THEN
        SELECT agency_id INTO agency_id_val
        FROM agents WHERE agent_id = NEW.agent_id;

        IF agency_id_val IS NOT NULL THEN
            UPDATE agencies
            SET total_policies = total_policies + 1,
                total_premium = total_premium + NEW.premium_amount
            WHERE agency_id = agency_id_val;
        END IF;
    END IF;
END//

-- Auto-expire policies
CREATE TRIGGER trg_check_policy_expiry
BEFORE UPDATE ON policies
FOR EACH ROW
BEGIN
    IF NEW.expiry_date < CURDATE() AND OLD.status = 'active' THEN
        SET NEW.status = 'expired';
    END IF;
END//

-- Validate beneficiary allocations
CREATE TRIGGER trg_validate_beneficiary_allocation
BEFORE INSERT ON policy_beneficiaries
FOR EACH ROW
BEGIN
    DECLARE total_allocation DECIMAL(5,2);

    SELECT SUM(percentage_allocation) INTO total_allocation
    FROM policy_beneficiaries
    WHERE policy_id = NEW.policy_id
      AND beneficiary_type = NEW.beneficiary_type;

    IF (total_allocation + NEW.percentage_allocation) > 100 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Total beneficiary allocation cannot exceed 100%';
    END IF;
END//

DELIMITER ;

-- ============================================================================
-- EVENTS FOR AUTOMATED TASKS
-- ============================================================================

DELIMITER //

-- Daily policy expiry check
CREATE EVENT IF NOT EXISTS evt_check_policy_expiry
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_DATE + INTERVAL 1 DAY + INTERVAL 1 HOUR
DO
BEGIN
    UPDATE policies
    SET status = 'expired'
    WHERE status = 'active'
      AND expiry_date < CURDATE();
END//

-- Monthly agent sales reset
CREATE EVENT IF NOT EXISTS evt_reset_monthly_sales
ON SCHEDULE EVERY 1 MONTH
STARTS DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL 1 MONTH), '%Y-%m-01') + INTERVAL 1 HOUR
DO
BEGIN
    UPDATE agents
    SET current_month_sales = 0;
END//

-- Yearly agent sales reset
CREATE EVENT IF NOT EXISTS evt_reset_yearly_sales
ON SCHEDULE EVERY 1 YEAR
STARTS CONCAT(YEAR(CURDATE()) + 1, '-01-01 00:01:00')
DO
BEGIN
    UPDATE agents
    SET ytd_sales = 0;
END//

-- Premium billing reminders (3 days before due)
CREATE EVENT IF NOT EXISTS evt_premium_reminders
ON SCHEDULE EVERY 1 DAY
DO
BEGIN
    INSERT INTO communications (reference_type, reference_id, communication_type,
                              direction, subject, content, status)
    SELECT 'policy', p.policy_id, 'email', 'outbound',
           'Premium Payment Reminder',
           CONCAT('Your premium payment of $', bs.installment_amount, ' is due in 3 days.'),
           'pending'
    FROM policies p
    JOIN billing_schedules bs ON p.policy_id = bs.policy_id
    WHERE p.status = 'active'
      AND bs.is_active = TRUE
      AND DAY(DATE_ADD(CURDATE(), INTERVAL 3 DAY)) = bs.billing_day
      AND NOT EXISTS (
          SELECT 1 FROM communications c
          WHERE c.reference_type = 'policy'
            AND c.reference_id = p.policy_id
            AND c.subject = 'Premium Payment Reminder'
            AND DATE(c.created_at) = CURDATE()
      );
END//

-- Auto-suspend policies for non-payment (30 days overdue)
CREATE EVENT IF NOT EXISTS evt_suspend_overdue_policies
ON SCHEDULE EVERY 1 DAY
DO
BEGIN
    UPDATE policies p
    SET status = 'suspended'
    WHERE p.status = 'active'
      AND EXISTS (
          SELECT 1 FROM billing_schedules bs
          WHERE bs.policy_id = p.policy_id
            AND bs.is_active = TRUE
            AND NOT EXISTS (
                SELECT 1 FROM payments pay
                WHERE pay.policy_id = p.policy_id
                  AND pay.payment_type = 'premium'
                  AND pay.status = 'completed'
                  AND DATE(pay.processed_date) >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
            )
      );
END//

-- Process pending claim escalations
CREATE EVENT IF NOT EXISTS evt_escalate_claims
ON SCHEDULE EVERY 1 HOUR
DO
BEGIN
    UPDATE claims
    SET priority = CASE
        WHEN DATEDIFF(CURDATE(), reported_date) > 30 THEN 'urgent'
        WHEN DATEDIFF(CURDATE(), reported_date) > 14 THEN 'high'
        ELSE priority
    END
    WHERE status IN ('submitted', 'acknowledged', 'investigating')
      AND priority != 'urgent';
END//

-- Clean up old claim activities (keep 7 years for compliance)
CREATE EVENT IF NOT EXISTS evt_cleanup_claim_activities
ON SCHEDULE EVERY 1 MONTH
DO
BEGIN
    DELETE FROM claim_activities
    WHERE created_at < DATE_SUB(CURDATE(), INTERVAL 7 YEAR);
END//

-- Generate regulatory report reminders
CREATE EVENT IF NOT EXISTS evt_regulatory_reminders
ON SCHEDULE EVERY 1 DAY
DO
BEGIN
    INSERT INTO communications (reference_type, reference_id, communication_type,
                              direction, subject, content, status)
    SELECT 'customer', 1, 'email', 'outbound',
           CONCAT('Regulatory Report Due: ', report_type),
           CONCAT('Report ', report_type, ' is due in 7 days. Deadline: ', filing_deadline),
           'pending'
    FROM regulatory_reports
    WHERE status IN ('draft', 'review')
      AND filing_deadline = DATE_ADD(CURDATE(), INTERVAL 7 DAY);
END//

DELIMITER ;