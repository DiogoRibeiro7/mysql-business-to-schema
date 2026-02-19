-- ============================================================================
-- CONSTRAINTS FOR INSURANCE MANAGEMENT PLATFORM
-- ============================================================================

USE insurance;

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
    CHECK ((year IS NULL OR year >= 1900 AND year <= 2100) AND
           (year_built IS NULL OR year_built >= 1800 AND year_built <= 2100)),
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

-- Note: Aggregate allocation validation handled at application level.

-- ============================================================================
-- TRIGGERS FOR DATA INTEGRITY
-- ============================================================================


-- ============================================================================
-- EVENTS FOR AUTOMATED TASKS
-- ============================================================================

