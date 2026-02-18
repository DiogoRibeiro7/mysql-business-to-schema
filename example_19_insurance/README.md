# 🏛️ Insurance Management Platform

A comprehensive MySQL database schema for a modern insurance company managing multiple insurance products, claims processing, underwriting, regulatory compliance, and agent networks - suitable for life, health, auto, and property insurance operations.

## 📊 Database Overview

- **Industry**: Insurance / Financial Services
- **Complexity**: Very High
- **Tables**: 23
- **Key Features**: Policy Lifecycle, Claims Processing, Underwriting, Reinsurance
- **Data Volume**: Designed for millions of policies and claims
- **Compliance**: Built for regulatory reporting requirements

## 🗂️ Schema Structure

### Customer Management

1. **customers** - Policyholders (individuals and corporations)
   - Personal and corporate information
   - Risk profiling and credit scoring
   - KYC verification tracking
   - Health information for life/health insurance
   - Marketing preferences

2. **beneficiaries** - Policy beneficiaries
   - Primary and contingent beneficiaries
   - Percentage allocations
   - Relationship tracking
   - Contact information

### Product & Policy Management

1. **products** - Insurance product catalog
   - Multiple product types (life, health, auto, property, etc.)
   - Coverage limits and deductibles
   - Eligibility criteria
   - State availability
   - Pricing factors

2. **policies** - Active insurance policies
   - Complete policy lifecycle
   - Premium calculations
   - Riders and add-ons
   - Discount tracking
   - Renewal management

3. **policy_beneficiaries** - Beneficiary assignments
   - Link between policies and beneficiaries
   - Allocation percentages
   - Primary vs contingent

4. **policy_items** - Covered items
   - Vehicles (auto insurance)
   - Properties (home insurance)
   - Valuables and equipment
   - Item-specific details

### Claims Processing

1. **claims** - Insurance claims
   - Multiple claim types
   - Workflow status tracking
   - Fraud detection scoring
   - Investigation management
   - Payment processing

2. **claim_activities** - Claim audit trail
   - Complete activity log
   - Status changes
   - Document tracking
   - Actor identification

### Financial Management

1. **billing_schedules** - Premium billing
   - Flexible payment frequencies
   - Auto-pay configuration
   - Payment method management

2. **payments** - Financial transactions
   - Premium payments
   - Claim payouts
   - Refunds and adjustments
   - Commission payments
   - Reconciliation tracking

3. **commissions** - Agent/broker commissions
   - New business and renewal commissions
   - Override commissions
   - Bonus calculations
   - Payment tracking

### Distribution Network

1. **agents** - Insurance agents
   - License management
   - Hierarchical structure
   - Performance metrics
   - Commission structures
   - Territory assignments

2. **agencies** - Insurance agencies
   - Agency contracts
   - Performance tracking
   - Agent management
   - Commission agreements

3. **brokers** - Insurance brokers
   - Individual and company brokers
   - Multi-state licensing
   - Referral tracking
   - Commission rates

### Risk Management

1. **underwriting_applications** - Risk assessment
   - Medical exams (life/health)
   - Property inspections
   - Risk scoring
   - Premium calculations
   - Approval workflow

2. **reinsurance_treaties** - Reinsurance agreements
   - Multiple treaty types
   - Coverage limits
   - Retention amounts
   - Premium calculations

3. **reinsurance_cessions** - Ceded policies
   - Policy-to-treaty mapping
   - Ceded amounts
   - Claims tracking

### Documentation & Compliance

1. **documents** - Document management
   - Policy documents
   - Claim evidence
   - Underwriting documents
   - Verification tracking

2. **communications** - Correspondence log
   - Multi-channel communications
   - Templates usage
   - Inbound/outbound tracking

3. **regulatory_reports** - Compliance reporting
   - NAIC reporting
   - State filings
   - Jurisdiction tracking
   - Filing deadlines

## 🔑 Key Features

### Policy Lifecycle Management
- **Quote Generation**: Risk-based pricing
- **Underwriting**: Automated and manual review
- **Policy Issuance**: Document generation
- **Renewal Processing**: Automatic renewals
- **Cancellation**: Refund calculations
- **Endorsements**: Mid-term adjustments

### Claims Processing Workflow
- **FNOL**: First notice of loss capture
- **Assignment**: Adjuster allocation
- **Investigation**: Fraud detection
- **Approval**: Multi-level authorization
- **Payment**: Direct deposit/check
- **Subrogation**: Recovery tracking

### Commission Management
- **Tiered Structure**: Product-specific rates
- **Override Commissions**: Manager earnings
- **Bonus Calculations**: Performance incentives
- **Chargeback**: Policy cancellation adjustments
- **Payment Processing**: Batch payments

### Regulatory Compliance
- **State Filings**: Multi-jurisdiction support
- **NAIC Reporting**: Annual statements
- **Reserve Calculations**: Actuarial requirements
- **Audit Trails**: Complete activity logging
- **Data Retention**: Compliance with regulations

## 📈 Use Cases

### Common Queries

1. **Policy Portfolio Analysis**
```sql
-- Active policies by product type with premium totals
SELECT
    pr.product_type,
    pr.product_name,
    COUNT(p.policy_id) as policy_count,
    SUM(p.coverage_amount) as total_coverage,
    SUM(p.premium_amount) as total_premium,
    AVG(p.risk_score) as avg_risk_score
FROM policies p
JOIN products pr ON p.product_id = pr.product_id
WHERE p.status = 'active'
GROUP BY pr.product_type, pr.product_id
ORDER BY total_premium DESC;
```

2. **Claims Loss Ratio**
```sql
-- Calculate loss ratio by product line
WITH premiums AS (
    SELECT
        pr.product_type,
        SUM(p.premium_amount * p.term_months) as earned_premium
    FROM policies p
    JOIN products pr ON p.product_id = pr.product_id
    WHERE p.status IN ('active', 'expired')
        AND p.effective_date >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
    GROUP BY pr.product_type
),
claims AS (
    SELECT
        pr.product_type,
        SUM(c.paid_amount) as paid_claims
    FROM claims c
    JOIN policies p ON c.policy_id = p.policy_id
    JOIN products pr ON p.product_id = pr.product_id
    WHERE c.status = 'paid'
        AND c.incident_date >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
    GROUP BY pr.product_type
)
SELECT
    p.product_type,
    p.earned_premium,
    COALESCE(c.paid_claims, 0) as paid_claims,
    COALESCE(c.paid_claims / p.earned_premium * 100, 0) as loss_ratio_percent
FROM premiums p
LEFT JOIN claims c ON p.product_type = c.product_type
ORDER BY loss_ratio_percent DESC;
```

3. **Agent Performance Dashboard**
```sql
-- Top performing agents with commission earnings
SELECT
    a.agent_id,
    CONCAT(a.first_name, ' ', a.last_name) as agent_name,
    ag.agency_name,
    a.total_policies_sold,
    a.total_premium_sold,
    a.current_month_sales,
    a.ytd_sales,
    COUNT(DISTINCT p.policy_id) as active_policies,
    SUM(c.commission_amount) as total_commissions_earned
FROM agents a
LEFT JOIN agencies ag ON a.agency_id = ag.agency_id
LEFT JOIN policies p ON a.agent_id = p.agent_id AND p.status = 'active'
LEFT JOIN commissions c ON a.agent_id = c.agent_id AND c.status = 'paid'
WHERE a.status = 'active'
GROUP BY a.agent_id
ORDER BY a.ytd_sales DESC
LIMIT 20;
```

4. **Renewal Processing**
```sql
-- Policies due for renewal in next 30 days
SELECT
    p.policy_id,
    p.policy_number,
    c.email,
    CONCAT(c.first_name, ' ', c.last_name) as customer_name,
    pr.product_name,
    p.coverage_amount,
    p.premium_amount,
    p.expiry_date,
    DATEDIFF(p.expiry_date, CURDATE()) as days_until_expiry,
    CASE
        WHEN prev.policy_id IS NOT NULL THEN 'Renewal'
        ELSE 'New Business'
    END as policy_origin
FROM policies p
JOIN customers c ON p.customer_id = c.customer_id
JOIN products pr ON p.product_id = pr.product_id
LEFT JOIN policies prev ON p.previous_policy_id = prev.policy_id
WHERE p.status = 'active'
    AND p.expiry_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 30 DAY)
    AND pr.renewable = TRUE
ORDER BY p.expiry_date;
```

5. **Claims Processing Queue**
```sql
-- Priority queue for claim adjusters
SELECT
    c.claim_id,
    c.claim_number,
    c.claim_type,
    c.priority,
    c.status,
    cu.email as customer_email,
    p.policy_number,
    c.claimed_amount,
    c.incident_date,
    c.reported_date,
    DATEDIFF(CURDATE(), c.reported_date) as days_pending,
    c.fraud_score,
    CONCAT(adj.first_name, ' ', adj.last_name) as assigned_adjuster
FROM claims c
JOIN policies p ON c.policy_id = p.policy_id
JOIN customers cu ON c.customer_id = cu.customer_id
LEFT JOIN agents adj ON c.assigned_adjuster_id = adj.agent_id
WHERE c.status IN ('submitted', 'acknowledged', 'investigating')
ORDER BY
    FIELD(c.priority, 'urgent', 'high', 'medium', 'low'),
    c.reported_date
LIMIT 50;
```

## 🚀 Getting Started

### 1. Create Database
```bash
mysql -u root -p < schema/00_create_database.sql
```

### 2. Create Schema
```bash
mysql -u root -p insurance_platform < schema/01_tables.sql
mysql -u root -p insurance_platform < schema/02_constraints.sql
mysql -u root -p insurance_platform < schema/03_indexes.sql
```

### 3. Load Sample Data (when available)
```bash
mysql -u root -p insurance_platform < data/01_products.sql
mysql -u root -p insurance_platform < data/02_agents_agencies.sql
mysql -u root -p insurance_platform < data/03_sample_policies.sql
```

### 4. Generate Test Data (when generator is ready)
```bash
cd generators/insurance
python generator.py --customers 10000 --policies 50000 --claims 5000
```

## 📋 Business Rules

### Underwriting Rules
- Risk assessment required for coverage > $500,000
- Medical exam required for life insurance > $1M
- Property inspection for home insurance > $750K
- Credit check for all new policies
- Previous claims history affects pricing

### Claims Processing
- FNOL must be filed within 30 days of incident
- Investigation triggered for claims > $50,000
- Fraud detection on all claims > $10,000
- Two-approver rule for claims > $100,000
- Payment within 30 days of approval

### Commission Rules
- New business: 10-20% of first year premium
- Renewals: 2-5% of renewal premium
- Override: 2-3% for managers
- Chargeback if cancelled within 6 months
- Bonus tiers based on production

### Regulatory Compliance
- Daily backup of all transactions
- 7-year retention for all documents
- Quarterly state filings
- Annual NAIC reporting
- SOX compliance for public insurers

### Premium Billing
- Grace period of 30 days
- Auto-suspend after 30 days overdue
- Reinstatement within 60 days
- Pro-rata refunds for cancellations
- NSF fee for returned payments

## 🔍 Indexes

Optimized for insurance operations:

- **Policy Management**: Customer and expiry date lookups
- **Claims Processing**: Status and adjuster queues
- **Commission Calculation**: Agent and broker earnings
- **Underwriting Queue**: Pending applications
- **Billing Operations**: Payment due dates
- **Regulatory Reporting**: Period-based queries

## 📊 Performance Considerations

### Scaling Strategies
- **Partitioning**: Claims by year, Policies by product
- **Read Replicas**: Reporting and analytics
- **Caching**: Product catalog, agent hierarchy
- **Archiving**: Expired policies after 7 years
- **Batch Processing**: Commission calculations, renewals

### Critical Performance Areas
- Policy issuance: < 2 seconds
- Claims FNOL: < 1 second
- Premium calculation: < 500ms
- Commission calculation: Batch overnight
- Report generation: Background jobs

### Data Retention
- Active policies: Online
- Expired policies: 7 years online, then archive
- Claims: 10 years online
- Communications: 3 years online
- Audit logs: 7 years minimum

## 🎯 Learning Objectives

This example demonstrates:

1. **Complex Workflows** - Multi-step approval processes
2. **Financial Calculations** - Premiums, commissions, claims
3. **Risk Management** - Underwriting and reinsurance
4. **Regulatory Compliance** - Audit trails and reporting
5. **Distribution Networks** - Agent/broker hierarchies
6. **Document Management** - Policy documents and evidence
7. **Actuarial Support** - Loss ratios and reserves

## 🔧 Customization Options

### Additional Features to Consider

1. **Actuarial Tables**
```sql
CREATE TABLE mortality_tables (
    table_id INT PRIMARY KEY,
    age INT,
    gender ENUM('male', 'female'),
    mortality_rate DECIMAL(10,8),
    life_expectancy DECIMAL(5,2)
);
```

2. **Investment Products**
```sql
CREATE TABLE investment_policies (
    policy_id BIGINT UNSIGNED PRIMARY KEY,
    investment_type ENUM('whole_life', 'universal', 'variable'),
    cash_value DECIMAL(15,2),
    surrender_value DECIMAL(15,2),
    loan_amount DECIMAL(15,2),
    FOREIGN KEY (policy_id) REFERENCES policies(policy_id)
);
```

3. **Catastrophe Modeling**
```sql
CREATE TABLE catastrophe_events (
    event_id BIGINT PRIMARY KEY,
    event_type ENUM('hurricane', 'earthquake', 'flood', 'wildfire'),
    event_date DATE,
    affected_area GEOMETRY,
    estimated_losses DECIMAL(15,2),
    claims_count INT
);
```

## 🛠️ Technologies

- **Database**: MySQL 8.0+ with JSON support
- **Engine**: InnoDB for ACID compliance
- **Character Set**: utf8mb4 for international support
- **Events**: Automated expiry and billing
- **Triggers**: Workflow automation

## 📚 Additional Resources

- [Insurance Data Model](https://www.ibm.com/docs/en/industry-models/insurance)
- [NAIC Data Standards](https://www.naic.org/)
- [Insurance Accounting (IFRS 17)](https://www.ifrs.org/issued-standards/list-of-standards/ifrs-17-insurance-contracts/)
- [Actuarial Standards](https://www.actuarialstandardsboard.org/)

## 🤝 Contributing

Areas for improvement:
1. Add actuarial calculation tables
2. Implement blockchain for claims
3. Add telematics for auto insurance
4. Create mobile app API views
5. Add predictive analytics models

## 📝 License

Part of the MySQL Business-to-Schema project, MIT License.