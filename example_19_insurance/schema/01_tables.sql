-- ============================================================================
-- CORE TABLES FOR INSURANCE MANAGEMENT PLATFORM
-- ============================================================================

USE insurance_platform;

-- ============================================================================
-- CUSTOMER MANAGEMENT
-- ============================================================================

-- Customers table
CREATE TABLE customers (
    customer_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    customer_type ENUM('individual', 'corporate') NOT NULL DEFAULT 'individual',

    -- Personal Information (for individuals)
    first_name VARCHAR(100),
    middle_name VARCHAR(100),
    last_name VARCHAR(100),
    date_of_birth DATE,
    gender ENUM('male', 'female', 'other'),
    marital_status ENUM('single', 'married', 'divorced', 'widowed'),

    -- Corporate Information (for companies)
    company_name VARCHAR(255),
    registration_number VARCHAR(100),
    incorporation_date DATE,

    -- Common Information
    email VARCHAR(255) NOT NULL,
    phone_primary VARCHAR(20) NOT NULL,
    phone_secondary VARCHAR(20),

    -- Identification
    ssn_tax_id VARCHAR(50), -- SSN for individuals, EIN for companies
    drivers_license VARCHAR(50),
    passport_number VARCHAR(50),

    -- Address
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    state_province VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(2) DEFAULT 'US',

    -- Risk Profile
    occupation VARCHAR(100),
    annual_income DECIMAL(15,2),
    credit_score INT,
    risk_category ENUM('low', 'medium', 'high', 'very_high') DEFAULT 'medium',

    -- Health Information (for health/life insurance)
    blood_type VARCHAR(5),
    is_smoker BOOLEAN DEFAULT FALSE,
    has_pre_existing_conditions BOOLEAN DEFAULT FALSE,

    -- Account Status
    status ENUM('active', 'inactive', 'suspended', 'blacklisted') DEFAULT 'active',
    kyc_verified BOOLEAN DEFAULT FALSE,
    kyc_verified_date DATE,

    -- Marketing
    acquisition_channel VARCHAR(100),
    preferred_contact_method ENUM('email', 'phone', 'mail', 'sms') DEFAULT 'email',
    marketing_consent BOOLEAN DEFAULT TRUE,

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (customer_id),
    UNIQUE KEY uk_email (email),
    INDEX idx_ssn (ssn_tax_id),
    INDEX idx_status (status),
    INDEX idx_risk (risk_category),
    INDEX idx_type (customer_type)
) ENGINE=InnoDB;

-- Beneficiaries table
CREATE TABLE beneficiaries (
    beneficiary_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    customer_id BIGINT UNSIGNED NOT NULL,

    -- Beneficiary Information
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE,
    relationship ENUM('spouse', 'child', 'parent', 'sibling', 'other') NOT NULL,

    -- Contact
    email VARCHAR(255),
    phone VARCHAR(20),
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    state_province VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(2) DEFAULT 'US',

    -- Allocation
    percentage_allocation DECIMAL(5,2) DEFAULT 100.00,
    is_primary BOOLEAN DEFAULT TRUE,
    is_contingent BOOLEAN DEFAULT FALSE,

    -- Status
    is_active BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (beneficiary_id),
    INDEX idx_customer (customer_id),
    INDEX idx_active (is_active),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
) ENGINE=InnoDB;

-- ============================================================================
-- PRODUCT MANAGEMENT
-- ============================================================================

-- Insurance products catalog
CREATE TABLE products (
    product_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    product_code VARCHAR(50) NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    product_type ENUM('life', 'health', 'auto', 'home', 'liability', 'disability', 'travel', 'pet') NOT NULL,

    -- Product Details
    description TEXT,
    coverage_details JSON, -- Detailed coverage information
    exclusions JSON, -- List of exclusions

    -- Limits and Deductibles
    min_coverage_amount DECIMAL(15,2),
    max_coverage_amount DECIMAL(15,2),
    default_deductible DECIMAL(15,2),

    -- Term Information
    min_term_months INT,
    max_term_months INT,
    renewable BOOLEAN DEFAULT TRUE,

    -- Eligibility
    min_age INT,
    max_age INT,
    requires_medical_exam BOOLEAN DEFAULT FALSE,
    requires_inspection BOOLEAN DEFAULT FALSE,

    -- Pricing
    base_premium_rate DECIMAL(10,6), -- Base rate per $1000 coverage
    risk_factors JSON, -- Factors that affect pricing

    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    launch_date DATE,
    discontinue_date DATE,

    -- Regulatory
    regulatory_code VARCHAR(100),
    states_available JSON, -- List of states where product is available

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (product_id),
    UNIQUE KEY uk_product_code (product_code),
    INDEX idx_type (product_type),
    INDEX idx_active (is_active)
) ENGINE=InnoDB;

-- ============================================================================
-- POLICY MANAGEMENT
-- ============================================================================

-- Insurance policies
CREATE TABLE policies (
    policy_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    policy_number VARCHAR(50) NOT NULL,
    customer_id BIGINT UNSIGNED NOT NULL,
    product_id INT UNSIGNED NOT NULL,

    -- Policy Details
    coverage_amount DECIMAL(15,2) NOT NULL,
    deductible DECIMAL(15,2) DEFAULT 0,

    -- Term
    effective_date DATE NOT NULL,
    expiry_date DATE NOT NULL,
    term_months INT GENERATED ALWAYS AS (PERIOD_DIFF(DATE_FORMAT(expiry_date, '%Y%m'), DATE_FORMAT(effective_date, '%Y%m'))) STORED,

    -- Premium Information
    premium_amount DECIMAL(15,2) NOT NULL,
    premium_frequency ENUM('monthly', 'quarterly', 'semi_annual', 'annual') DEFAULT 'monthly',
    payment_method ENUM('ach', 'credit_card', 'check', 'wire') DEFAULT 'ach',

    -- Status
    status ENUM('quote', 'pending', 'active', 'suspended', 'cancelled', 'expired', 'claimed') DEFAULT 'quote',
    underwriting_status ENUM('pending', 'approved', 'declined', 'referred') DEFAULT 'pending',

    -- Riders and Add-ons
    riders JSON, -- Additional coverage options
    total_riders_premium DECIMAL(15,2) DEFAULT 0,

    -- Discounts
    discounts JSON, -- Applied discounts
    total_discount_amount DECIMAL(15,2) DEFAULT 0,

    -- Risk Assessment
    risk_score DECIMAL(5,2),
    risk_category ENUM('preferred', 'standard', 'substandard', 'declined'),

    -- Agent/Broker Information
    agent_id BIGINT UNSIGNED,
    broker_id BIGINT UNSIGNED,
    commission_rate DECIMAL(5,2),

    -- Previous Policy (for renewals)
    previous_policy_id BIGINT UNSIGNED,
    is_renewal BOOLEAN DEFAULT FALSE,

    -- Cancellation Information
    cancelled_date DATE,
    cancellation_reason VARCHAR(500),
    refund_amount DECIMAL(15,2),

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    approved_at TIMESTAMP NULL,

    PRIMARY KEY (policy_id),
    UNIQUE KEY uk_policy_number (policy_number),
    INDEX idx_customer (customer_id),
    INDEX idx_product (product_id),
    INDEX idx_status (status),
    INDEX idx_expiry (expiry_date),
    INDEX idx_agent (agent_id),
    INDEX idx_broker (broker_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (previous_policy_id) REFERENCES policies(policy_id)
) ENGINE=InnoDB;

-- Policy beneficiaries (link table)
CREATE TABLE policy_beneficiaries (
    policy_beneficiary_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    policy_id BIGINT UNSIGNED NOT NULL,
    beneficiary_id BIGINT UNSIGNED NOT NULL,

    percentage_allocation DECIMAL(5,2) NOT NULL,
    beneficiary_type ENUM('primary', 'contingent') DEFAULT 'primary',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (policy_beneficiary_id),
    UNIQUE KEY uk_policy_beneficiary (policy_id, beneficiary_id),
    INDEX idx_policy (policy_id),
    INDEX idx_beneficiary (beneficiary_id),
    FOREIGN KEY (policy_id) REFERENCES policies(policy_id),
    FOREIGN KEY (beneficiary_id) REFERENCES beneficiaries(beneficiary_id)
) ENGINE=InnoDB;

-- Policy covered items (for auto, home insurance)
CREATE TABLE policy_items (
    item_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    policy_id BIGINT UNSIGNED NOT NULL,

    -- Item Details
    item_type ENUM('vehicle', 'property', 'valuable', 'equipment', 'other') NOT NULL,
    description VARCHAR(500),

    -- Vehicle Information (for auto insurance)
    vin VARCHAR(20),
    make VARCHAR(50),
    model VARCHAR(50),
    year YEAR,
    license_plate VARCHAR(20),

    -- Property Information (for home insurance)
    property_address VARCHAR(500),
    property_type ENUM('house', 'condo', 'apartment', 'land'),
    square_footage INT,
    year_built YEAR,

    -- Valuation
    estimated_value DECIMAL(15,2),
    insured_value DECIMAL(15,2),

    -- Status
    is_active BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (item_id),
    INDEX idx_policy (policy_id),
    INDEX idx_type (item_type),
    FOREIGN KEY (policy_id) REFERENCES policies(policy_id)
) ENGINE=InnoDB;

-- ============================================================================
-- CLAIMS MANAGEMENT
-- ============================================================================

-- Insurance claims
CREATE TABLE claims (
    claim_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    claim_number VARCHAR(50) NOT NULL,
    policy_id BIGINT UNSIGNED NOT NULL,
    customer_id BIGINT UNSIGNED NOT NULL,

    -- Claim Details
    claim_type ENUM('accident', 'theft', 'damage', 'liability', 'medical', 'death', 'disability', 'other') NOT NULL,
    incident_date DATE NOT NULL,
    reported_date DATE NOT NULL,
    description TEXT,

    -- Location
    incident_location VARCHAR(500),
    police_report_number VARCHAR(100),

    -- Claim Amount
    claimed_amount DECIMAL(15,2) NOT NULL,
    approved_amount DECIMAL(15,2),
    deductible_amount DECIMAL(15,2),
    paid_amount DECIMAL(15,2),

    -- Status and Workflow
    status ENUM('submitted', 'acknowledged', 'investigating', 'approved', 'denied', 'paid', 'closed', 'appealed') DEFAULT 'submitted',
    priority ENUM('low', 'medium', 'high', 'urgent') DEFAULT 'medium',

    -- Investigation
    assigned_adjuster_id BIGINT UNSIGNED,
    investigation_notes TEXT,
    fraud_suspected BOOLEAN DEFAULT FALSE,
    fraud_score DECIMAL(5,2),

    -- Decision
    decision_date DATE,
    decision_reason TEXT,
    appeal_deadline DATE,

    -- Payment Information
    payment_date DATE,
    payment_method ENUM('check', 'ach', 'wire'),
    payee_name VARCHAR(255),

    -- Documents
    documents_received JSON, -- List of received documents
    documents_pending JSON, -- List of pending documents

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    closed_at TIMESTAMP NULL,

    PRIMARY KEY (claim_id),
    UNIQUE KEY uk_claim_number (claim_number),
    INDEX idx_policy (policy_id),
    INDEX idx_customer (customer_id),
    INDEX idx_status (status),
    INDEX idx_incident_date (incident_date),
    INDEX idx_adjuster (assigned_adjuster_id),
    FOREIGN KEY (policy_id) REFERENCES policies(policy_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
) ENGINE=InnoDB;

-- Claim activities log
CREATE TABLE claim_activities (
    activity_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    claim_id BIGINT UNSIGNED NOT NULL,

    -- Activity Details
    activity_type VARCHAR(100) NOT NULL, -- 'status_change', 'document_received', 'payment', etc
    activity_description TEXT,

    -- Actor
    performed_by BIGINT UNSIGNED, -- User ID who performed the action
    actor_type ENUM('system', 'adjuster', 'customer', 'agent'),

    -- Status Change
    old_status VARCHAR(50),
    new_status VARCHAR(50),

    -- Metadata
    metadata JSON, -- Additional activity-specific data

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (activity_id),
    INDEX idx_claim (claim_id),
    INDEX idx_created (created_at DESC),
    FOREIGN KEY (claim_id) REFERENCES claims(claim_id)
) ENGINE=InnoDB;

-- ============================================================================
-- BILLING AND PAYMENTS
-- ============================================================================

-- Premium billing
CREATE TABLE billing_schedules (
    schedule_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    policy_id BIGINT UNSIGNED NOT NULL,

    -- Billing Details
    billing_frequency ENUM('monthly', 'quarterly', 'semi_annual', 'annual') NOT NULL,
    billing_day INT, -- Day of month for billing

    -- Amounts
    installment_amount DECIMAL(15,2) NOT NULL,
    total_annual_premium DECIMAL(15,2) NOT NULL,

    -- Payment Method
    payment_method ENUM('ach', 'credit_card', 'check', 'wire') DEFAULT 'ach',

    -- Bank/Card Information (encrypted)
    payment_details JSON,

    -- Auto-pay
    auto_pay_enabled BOOLEAN DEFAULT TRUE,

    -- Status
    is_active BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (schedule_id),
    UNIQUE KEY uk_policy (policy_id),
    INDEX idx_active (is_active),
    FOREIGN KEY (policy_id) REFERENCES policies(policy_id)
) ENGINE=InnoDB;

-- Payment transactions
CREATE TABLE payments (
    payment_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    policy_id BIGINT UNSIGNED,
    claim_id BIGINT UNSIGNED,

    -- Payment Type
    payment_type ENUM('premium', 'claim', 'refund', 'commission') NOT NULL,

    -- Amount
    amount DECIMAL(15,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',

    -- Payment Details
    payment_method ENUM('ach', 'credit_card', 'check', 'wire', 'cash') NOT NULL,
    transaction_reference VARCHAR(255),

    -- Status
    status ENUM('pending', 'processing', 'completed', 'failed', 'reversed') DEFAULT 'pending',

    -- Payer/Payee Information
    payer_type ENUM('customer', 'company', 'reinsurer'),
    payer_id BIGINT UNSIGNED,
    payee_type ENUM('customer', 'company', 'agent', 'broker', 'provider'),
    payee_id BIGINT UNSIGNED,

    -- Processing
    processed_date TIMESTAMP NULL,
    failure_reason VARCHAR(500),

    -- Reconciliation
    reconciled BOOLEAN DEFAULT FALSE,
    reconciliation_date DATE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (payment_id),
    INDEX idx_policy (policy_id),
    INDEX idx_claim (claim_id),
    INDEX idx_status (status),
    INDEX idx_type (payment_type),
    INDEX idx_processed (processed_date),
    FOREIGN KEY (policy_id) REFERENCES policies(policy_id),
    FOREIGN KEY (claim_id) REFERENCES claims(claim_id)
) ENGINE=InnoDB;

-- ============================================================================
-- AGENT AND BROKER MANAGEMENT
-- ============================================================================

-- Insurance agents
CREATE TABLE agents (
    agent_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    agent_code VARCHAR(50) NOT NULL,

    -- Personal Information
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,

    -- License Information
    license_number VARCHAR(100) NOT NULL,
    license_state VARCHAR(2),
    license_expiry DATE,
    licensed_products JSON, -- List of products agent can sell

    -- Hierarchy
    manager_id BIGINT UNSIGNED,
    agency_id BIGINT UNSIGNED,

    -- Commission Structure
    commission_structure JSON, -- Product-specific commission rates
    override_rate DECIMAL(5,2), -- Override commission for team sales

    -- Performance Metrics
    total_policies_sold INT DEFAULT 0,
    total_premium_sold DECIMAL(15,2) DEFAULT 0,
    current_month_sales DECIMAL(15,2) DEFAULT 0,
    ytd_sales DECIMAL(15,2) DEFAULT 0,

    -- Status
    status ENUM('active', 'inactive', 'terminated') DEFAULT 'active',
    hire_date DATE,
    termination_date DATE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (agent_id),
    UNIQUE KEY uk_agent_code (agent_code),
    UNIQUE KEY uk_email (email),
    UNIQUE KEY uk_license (license_number),
    INDEX idx_status (status),
    INDEX idx_manager (manager_id),
    INDEX idx_agency (agency_id),
    FOREIGN KEY (manager_id) REFERENCES agents(agent_id)
) ENGINE=InnoDB;

-- Insurance agencies
CREATE TABLE agencies (
    agency_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    agency_name VARCHAR(255) NOT NULL,

    -- Contact Information
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    state_province VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(2) DEFAULT 'US',
    phone VARCHAR(20),
    email VARCHAR(255),

    -- Business Information
    tax_id VARCHAR(50),
    license_number VARCHAR(100),

    -- Commission Structure
    base_commission_rate DECIMAL(5,2),
    bonus_structure JSON,

    -- Performance
    total_agents INT DEFAULT 0,
    total_policies INT DEFAULT 0,
    total_premium DECIMAL(15,2) DEFAULT 0,

    -- Status
    status ENUM('active', 'inactive', 'suspended') DEFAULT 'active',
    contract_start_date DATE,
    contract_end_date DATE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (agency_id),
    INDEX idx_status (status)
) ENGINE=InnoDB;

-- Brokers
CREATE TABLE brokers (
    broker_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    broker_code VARCHAR(50) NOT NULL,

    -- Company or Individual
    broker_type ENUM('individual', 'company') NOT NULL,

    -- Information
    company_name VARCHAR(255),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,

    -- License
    license_number VARCHAR(100) NOT NULL,
    license_states JSON, -- Multiple states

    -- Commission
    commission_rate DECIMAL(5,2),
    preferred_products JSON,

    -- Performance
    total_referrals INT DEFAULT 0,
    total_premium_referred DECIMAL(15,2) DEFAULT 0,

    -- Status
    status ENUM('active', 'inactive', 'suspended') DEFAULT 'active',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (broker_id),
    UNIQUE KEY uk_broker_code (broker_code),
    UNIQUE KEY uk_email (email),
    INDEX idx_status (status),
    INDEX idx_type (broker_type)
) ENGINE=InnoDB;

-- ============================================================================
-- UNDERWRITING
-- ============================================================================

-- Underwriting applications
CREATE TABLE underwriting_applications (
    application_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    policy_id BIGINT UNSIGNED NOT NULL,
    customer_id BIGINT UNSIGNED NOT NULL,
    product_id INT UNSIGNED NOT NULL,

    -- Application Details
    requested_coverage DECIMAL(15,2),
    requested_term_months INT,

    -- Risk Information
    health_questionnaire JSON,
    lifestyle_questionnaire JSON,
    financial_information JSON,

    -- Medical Information
    medical_exam_required BOOLEAN DEFAULT FALSE,
    medical_exam_completed BOOLEAN DEFAULT FALSE,
    medical_exam_date DATE,
    medical_exam_results JSON,

    -- Property Information (for property insurance)
    property_inspection_required BOOLEAN DEFAULT FALSE,
    property_inspection_completed BOOLEAN DEFAULT FALSE,
    property_inspection_date DATE,
    property_inspection_results JSON,

    -- Risk Assessment
    risk_score DECIMAL(5,2),
    risk_factors JSON,
    risk_category ENUM('preferred_plus', 'preferred', 'standard_plus', 'standard', 'substandard', 'declined'),

    -- Decision
    underwriter_id BIGINT UNSIGNED,
    decision ENUM('approved', 'declined', 'referred', 'pending') DEFAULT 'pending',
    decision_date DATE,
    decision_notes TEXT,

    -- Premium Calculation
    base_premium DECIMAL(15,2),
    risk_adjustment DECIMAL(15,2),
    final_premium DECIMAL(15,2),

    -- Conditions
    conditions JSON, -- Special conditions or exclusions

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (application_id),
    UNIQUE KEY uk_policy (policy_id),
    INDEX idx_customer (customer_id),
    INDEX idx_product (product_id),
    INDEX idx_decision (decision),
    INDEX idx_underwriter (underwriter_id),
    FOREIGN KEY (policy_id) REFERENCES policies(policy_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
) ENGINE=InnoDB;

-- ============================================================================
-- REINSURANCE
-- ============================================================================

-- Reinsurance treaties
CREATE TABLE reinsurance_treaties (
    treaty_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    treaty_number VARCHAR(100) NOT NULL,

    -- Treaty Information
    treaty_type ENUM('quota_share', 'surplus', 'excess_loss', 'stop_loss') NOT NULL,
    reinsurer_name VARCHAR(255) NOT NULL,

    -- Coverage
    coverage_products JSON, -- Products covered
    retention_amount DECIMAL(15,2), -- Amount retained by primary insurer
    cession_percentage DECIMAL(5,2), -- Percentage ceded to reinsurer

    -- Limits
    treaty_limit DECIMAL(15,2),
    occurrence_limit DECIMAL(15,2),
    aggregate_limit DECIMAL(15,2),

    -- Term
    effective_date DATE NOT NULL,
    expiry_date DATE NOT NULL,

    -- Premium
    reinsurance_premium DECIMAL(15,2),
    commission_rate DECIMAL(5,2),

    -- Status
    status ENUM('active', 'expired', 'cancelled') DEFAULT 'active',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (treaty_id),
    UNIQUE KEY uk_treaty_number (treaty_number),
    INDEX idx_status (status),
    INDEX idx_dates (effective_date, expiry_date)
) ENGINE=InnoDB;

-- Reinsurance cessions (policies ceded to reinsurer)
CREATE TABLE reinsurance_cessions (
    cession_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    treaty_id BIGINT UNSIGNED NOT NULL,
    policy_id BIGINT UNSIGNED NOT NULL,

    -- Cession Details
    ceded_amount DECIMAL(15,2) NOT NULL,
    ceded_premium DECIMAL(15,2) NOT NULL,
    cession_date DATE NOT NULL,

    -- Claims
    claims_paid DECIMAL(15,2) DEFAULT 0,
    claims_pending DECIMAL(15,2) DEFAULT 0,

    -- Status
    is_active BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (cession_id),
    UNIQUE KEY uk_treaty_policy (treaty_id, policy_id),
    INDEX idx_treaty (treaty_id),
    INDEX idx_policy (policy_id),
    FOREIGN KEY (treaty_id) REFERENCES reinsurance_treaties(treaty_id),
    FOREIGN KEY (policy_id) REFERENCES policies(policy_id)
) ENGINE=InnoDB;

-- ============================================================================
-- DOCUMENTS AND CORRESPONDENCE
-- ============================================================================

-- Document management
CREATE TABLE documents (
    document_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    -- Reference
    reference_type ENUM('policy', 'claim', 'customer', 'underwriting') NOT NULL,
    reference_id BIGINT UNSIGNED NOT NULL,

    -- Document Details
    document_type VARCHAR(100) NOT NULL, -- 'application', 'policy_document', 'claim_form', etc
    document_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500),
    file_size INT,
    mime_type VARCHAR(100),

    -- Metadata
    uploaded_by BIGINT UNSIGNED,
    upload_source ENUM('customer', 'agent', 'system', 'adjuster'),

    -- Verification
    is_verified BOOLEAN DEFAULT FALSE,
    verified_by BIGINT UNSIGNED,
    verified_at TIMESTAMP NULL,

    -- Status
    status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (document_id),
    INDEX idx_reference (reference_type, reference_id),
    INDEX idx_type (document_type),
    INDEX idx_status (status)
) ENGINE=InnoDB;

-- Communication logs
CREATE TABLE communications (
    communication_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    -- Reference
    reference_type ENUM('policy', 'claim', 'customer') NOT NULL,
    reference_id BIGINT UNSIGNED NOT NULL,

    -- Communication Details
    communication_type ENUM('email', 'phone', 'letter', 'sms', 'in_person') NOT NULL,
    direction ENUM('inbound', 'outbound') NOT NULL,

    -- Content
    subject VARCHAR(500),
    content TEXT,

    -- Participants
    from_party VARCHAR(255),
    to_party VARCHAR(255),

    -- Status
    status ENUM('sent', 'received', 'failed', 'pending') DEFAULT 'pending',

    -- Metadata
    template_used VARCHAR(100),
    attachments JSON,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (communication_id),
    INDEX idx_reference (reference_type, reference_id),
    INDEX idx_created (created_at DESC)
) ENGINE=InnoDB;

-- ============================================================================
-- REGULATORY AND COMPLIANCE
-- ============================================================================

-- Regulatory reports
CREATE TABLE regulatory_reports (
    report_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    -- Report Information
    report_type VARCHAR(100) NOT NULL, -- 'NAIC', 'state_filing', etc
    report_period_start DATE NOT NULL,
    report_period_end DATE NOT NULL,

    -- Jurisdiction
    jurisdiction VARCHAR(100) NOT NULL,
    regulatory_body VARCHAR(255),

    -- Content
    report_data JSON,

    -- Filing
    filing_deadline DATE,
    filed_date DATE,
    filing_reference VARCHAR(255),

    -- Status
    status ENUM('draft', 'review', 'filed', 'accepted', 'rejected') DEFAULT 'draft',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (report_id),
    INDEX idx_type (report_type),
    INDEX idx_period (report_period_start, report_period_end),
    INDEX idx_status (status)
) ENGINE=InnoDB;

-- ============================================================================
-- COMMISSIONS
-- ============================================================================

-- Commission calculations
CREATE TABLE commissions (
    commission_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    -- Reference
    policy_id BIGINT UNSIGNED NOT NULL,
    agent_id BIGINT UNSIGNED,
    broker_id BIGINT UNSIGNED,

    -- Commission Details
    commission_type ENUM('new_business', 'renewal', 'override', 'bonus') NOT NULL,
    commission_rate DECIMAL(5,2) NOT NULL,
    commission_amount DECIMAL(15,2) NOT NULL,

    -- Period
    earning_date DATE NOT NULL,
    payment_date DATE,

    -- Status
    status ENUM('pending', 'approved', 'paid', 'reversed') DEFAULT 'pending',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (commission_id),
    INDEX idx_policy (policy_id),
    INDEX idx_agent (agent_id),
    INDEX idx_broker (broker_id),
    INDEX idx_status (status),
    INDEX idx_payment_date (payment_date),
    FOREIGN KEY (policy_id) REFERENCES policies(policy_id),
    FOREIGN KEY (agent_id) REFERENCES agents(agent_id),
    FOREIGN KEY (broker_id) REFERENCES brokers(broker_id)
) ENGINE=InnoDB;