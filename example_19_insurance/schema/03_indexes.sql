-- ============================================================================
-- INDEXES FOR INSURANCE MANAGEMENT PLATFORM
-- ============================================================================

USE insurance_platform;

-- ============================================================================
-- PERFORMANCE INDEXES
-- ============================================================================

-- Customers table - optimize for search and risk assessment
CREATE INDEX idx_customers_email_status ON customers(email, status);
CREATE INDEX idx_customers_ssn ON customers(ssn_tax_id);
CREATE INDEX idx_customers_risk ON customers(risk_category, credit_score);
CREATE INDEX idx_customers_type_status ON customers(customer_type, status);
CREATE INDEX idx_customers_kyc ON customers(kyc_verified, kyc_verified_date);
CREATE INDEX idx_customers_created ON customers(created_at DESC);

-- Beneficiaries table - optimize for policy lookups
CREATE INDEX idx_beneficiaries_customer ON beneficiaries(customer_id, is_active);
CREATE INDEX idx_beneficiaries_primary ON beneficiaries(customer_id, is_primary);

-- Products table - optimize for product search
CREATE INDEX idx_products_type_active ON products(product_type, is_active);
CREATE INDEX idx_products_eligibility ON products(min_age, max_age, is_active);
CREATE INDEX idx_products_states ON products((CAST(states_available AS CHAR)));

-- Policies table - optimize for policy management
CREATE INDEX idx_policies_customer_status ON policies(customer_id, status);
CREATE INDEX idx_policies_expiry_status ON policies(expiry_date, status);
CREATE INDEX idx_policies_underwriting ON policies(underwriting_status, created_at);
CREATE INDEX idx_policies_agent_active ON policies(agent_id, status, effective_date);
CREATE INDEX idx_policies_broker_active ON policies(broker_id, status, effective_date);
CREATE INDEX idx_policies_renewal ON policies(previous_policy_id, is_renewal);

-- Policy beneficiaries - optimize for beneficiary lookups
CREATE INDEX idx_policy_beneficiaries_policy ON policy_beneficiaries(policy_id, beneficiary_type);

-- Policy items - optimize for item searches
CREATE INDEX idx_policy_items_policy ON policy_items(policy_id, is_active);
CREATE INDEX idx_policy_items_vehicle ON policy_items(vin, is_active);
CREATE INDEX idx_policy_items_property ON policy_items(property_address(100), is_active);

-- Claims table - optimize for claim processing
CREATE INDEX idx_claims_policy_status ON claims(policy_id, status);
CREATE INDEX idx_claims_customer ON claims(customer_id, status, incident_date DESC);
CREATE INDEX idx_claims_adjuster ON claims(assigned_adjuster_id, status, priority);
CREATE INDEX idx_claims_fraud ON claims(fraud_suspected, fraud_score);
CREATE INDEX idx_claims_pending ON claims(status, priority, reported_date);
CREATE INDEX idx_claims_payment ON claims(payment_date, status);

-- Claim activities - optimize for audit trail
CREATE INDEX idx_claim_activities_claim ON claim_activities(claim_id, created_at DESC);
CREATE INDEX idx_claim_activities_type ON claim_activities(activity_type, created_at DESC);

-- Billing schedules - optimize for payment processing
CREATE INDEX idx_billing_active ON billing_schedules(is_active, billing_day);
CREATE INDEX idx_billing_autopay ON billing_schedules(auto_pay_enabled, billing_day);

-- Payments table - optimize for financial reconciliation
CREATE INDEX idx_payments_policy ON payments(policy_id, payment_type, status);
CREATE INDEX idx_payments_claim ON payments(claim_id, status);
CREATE INDEX idx_payments_pending ON payments(status, created_at);
CREATE INDEX idx_payments_reconciliation ON payments(reconciled, processed_date);
CREATE INDEX idx_payments_date ON payments(processed_date, payment_type);

-- Agents table - optimize for performance tracking
CREATE INDEX idx_agents_status_sales ON agents(status, total_premium_sold DESC);
CREATE INDEX idx_agents_manager ON agents(manager_id, status);
CREATE INDEX idx_agents_agency ON agents(agency_id, status);
CREATE INDEX idx_agents_license ON agents(license_number, license_expiry);

-- Agencies table - optimize for agency management
CREATE INDEX idx_agencies_status ON agencies(status, total_premium DESC);
CREATE INDEX idx_agencies_contract ON agencies(contract_end_date, status);

-- Brokers table - optimize for referral tracking
CREATE INDEX idx_brokers_status ON brokers(status, total_premium_referred DESC);
CREATE INDEX idx_brokers_type ON brokers(broker_type, status);

-- Underwriting applications - optimize for processing queue
CREATE INDEX idx_underwriting_pending ON underwriting_applications(decision, created_at);
CREATE INDEX idx_underwriting_underwriter ON underwriting_applications(underwriter_id, decision);
CREATE INDEX idx_underwriting_risk ON underwriting_applications(risk_category, decision);

-- Reinsurance treaties - optimize for treaty management
CREATE INDEX idx_reinsurance_active ON reinsurance_treaties(status, effective_date, expiry_date);
CREATE INDEX idx_reinsurance_products ON reinsurance_treaties((CAST(coverage_products AS CHAR)));

-- Reinsurance cessions - optimize for cession tracking
CREATE INDEX idx_cessions_treaty ON reinsurance_cessions(treaty_id, is_active);
CREATE INDEX idx_cessions_policy ON reinsurance_cessions(policy_id, is_active);

-- Documents table - optimize for document retrieval
CREATE INDEX idx_documents_reference ON documents(reference_type, reference_id, status);
CREATE INDEX idx_documents_type_status ON documents(document_type, status);
CREATE INDEX idx_documents_verification ON documents(is_verified, status);

-- Communications table - optimize for correspondence tracking
CREATE INDEX idx_communications_reference ON communications(reference_type, reference_id, created_at DESC);
CREATE INDEX idx_communications_pending ON communications(status, created_at);

-- Regulatory reports - optimize for compliance
CREATE INDEX idx_regulatory_period ON regulatory_reports(report_period_start, report_period_end);
CREATE INDEX idx_regulatory_deadline ON regulatory_reports(filing_deadline, status);
CREATE INDEX idx_regulatory_jurisdiction ON regulatory_reports(jurisdiction, report_type);

-- Commissions table - optimize for commission processing
CREATE INDEX idx_commissions_agent ON commissions(agent_id, status, payment_date);
CREATE INDEX idx_commissions_broker ON commissions(broker_id, status, payment_date);
CREATE INDEX idx_commissions_pending ON commissions(status, earning_date);
CREATE INDEX idx_commissions_payment ON commissions(payment_date, status);

-- ============================================================================
-- COMPOSITE INDEXES FOR COMPLEX QUERIES
-- ============================================================================

-- Policy renewal processing
CREATE INDEX idx_policy_renewal_due ON policies(expiry_date, status, customer_id);

-- Claim processing queue
CREATE INDEX idx_claims_queue ON claims(status, priority DESC, reported_date, assigned_adjuster_id);

-- Premium collection
CREATE INDEX idx_premium_collection ON policies p
    JOIN billing_schedules bs ON p.policy_id = bs.policy_id
    (p.status, bs.billing_day, bs.auto_pay_enabled);

-- Agent performance dashboard
CREATE INDEX idx_agent_performance ON agents(status, current_month_sales DESC, ytd_sales DESC);

-- Customer lifetime value
CREATE INDEX idx_customer_ltv ON policies(customer_id, status, premium_amount);

-- Risk portfolio analysis
CREATE INDEX idx_risk_portfolio ON policies(product_id, risk_category, status, coverage_amount);

-- Claims loss ratio
CREATE INDEX idx_claims_loss_ratio ON claims(policy_id, status, paid_amount, incident_date);

-- Commission payout queue
CREATE INDEX idx_commission_payout ON commissions(status, payment_date, agent_id, broker_id);

-- ============================================================================
-- FULL-TEXT INDEXES
-- ============================================================================

-- Customer search
ALTER TABLE customers ADD FULLTEXT ft_customers_search
    (first_name, last_name, company_name, email);

-- Policy search
ALTER TABLE policies ADD FULLTEXT ft_policies_search
    (policy_number, cancellation_reason);

-- Claims search
ALTER TABLE claims ADD FULLTEXT ft_claims_search
    (claim_number, description, investigation_notes, decision_reason);

-- Product search
ALTER TABLE products ADD FULLTEXT ft_products_search
    (product_name, description);

-- Communications search
ALTER TABLE communications ADD FULLTEXT ft_communications_search
    (subject, content);

-- ============================================================================
-- STATISTICS UPDATE
-- ============================================================================

-- Update table statistics for query optimizer
ANALYZE TABLE customers;
ANALYZE TABLE policies;
ANALYZE TABLE claims;
ANALYZE TABLE payments;
ANALYZE TABLE agents;
ANALYZE TABLE billing_schedules;
ANALYZE TABLE underwriting_applications;
ANALYZE TABLE commissions;
ANALYZE TABLE policy_items;
ANALYZE TABLE claim_activities;

-- ============================================================================
-- INDEX HINTS FOR COMMON QUERIES
-- ============================================================================

/*
Common Query Patterns and Their Indexes:

1. Customer policy lookup:
   Uses: idx_policies_customer_status

2. Active policies expiring soon:
   Uses: idx_policies_expiry_status

3. Claims processing queue:
   Uses: idx_claims_queue

4. Agent commission calculation:
   Uses: idx_policies_agent_active, idx_commissions_agent

5. Premium billing run:
   Uses: idx_billing_active, idx_premium_collection

6. Underwriting queue:
   Uses: idx_underwriting_pending

7. Claims fraud detection:
   Uses: idx_claims_fraud

8. Policy renewal processing:
   Uses: idx_policy_renewal_due

9. Regulatory report generation:
   Uses: idx_regulatory_deadline

10. Customer risk assessment:
    Uses: idx_customers_risk, idx_policies_customer_status

11. Agency performance:
    Uses: idx_agencies_status, idx_agents_agency

12. Reinsurance cession tracking:
    Uses: idx_cessions_treaty, idx_reinsurance_active

13. Document verification queue:
    Uses: idx_documents_verification

14. Payment reconciliation:
    Uses: idx_payments_reconciliation

15. Customer search:
    Uses: ft_customers_search
*/
