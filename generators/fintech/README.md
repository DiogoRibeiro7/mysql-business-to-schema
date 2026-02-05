# FinTech Platform Data Generator

## Overview

Generates realistic financial services data for a modern digital banking platform, including:
- Customer profiles with KYC/AML compliance
- Multi-currency accounts and transactions
- Fraud detection patterns and alerts
- Payment processing workflows
- Regulatory compliance records

## Features

### Customer Generation
- **Individual Customers**: Personal banking users with demographics, SSN, income
- **Business Customers**: Corporate accounts with business details, EIN, revenue
- **Risk Profiles**: Low, medium, high, and prohibited risk levels
- **KYC Status**: Pending, active, suspended account states

### Account Types
- **Checking**: Daily transaction accounts with overdraft protection
- **Savings**: Interest-bearing accounts with minimum balance requirements
- **Credit Card**: Revolving credit with variable interest rates
- **Loan**: Term loans with amortization schedules
- **Investment**: Brokerage and trading accounts

### Transaction Patterns
- **Normal Patterns**: Regular payments, deposits, transfers
- **Velocity Patterns**: Rapid sequential transactions
- **Amount Patterns**: Large value transactions, structuring
- **Geographic Patterns**: Cross-border transfers, location changes
- **Behavioral Patterns**: Dormant account reactivation, unusual hours

### Fraud Simulation
- **Risk Scoring**: Multi-factor risk calculation
- **Alert Generation**: 2% of transactions flagged
- **Pattern Detection**: Structuring, rapid movement, round amounts
- **Device Fingerprinting**: Track trusted and suspicious devices
- **ML Anomaly Detection**: Statistical outlier detection

### Compliance Features
- **KYC Documents**: Passport, license, utility bills, incorporation docs
- **AML Checks**: Sanctions, PEP, adverse media screening
- **SAR Reporting**: Suspicious activity report generation
- **Audit Trail**: Complete transaction and change history

## Configuration

Edit `config.yaml` to customize:

```yaml
counts:
  individual_customers: 800
  business_customers: 200
  transactions_per_account_per_day:
    min: 0
    max: 10
  days_of_history: 90
  fraud_alert_rate: 0.02

distributions:
  customer_risk:
    low: 0.60
    medium: 0.30
    high: 0.08
    prohibited: 0.02

financial:
  initial_balance:
    checking:
      min: 100
      max: 50000
    savings:
      min: 500
      max: 100000
```

## Usage

```bash
# Generate data
python generate.py

# Output files created in generators/fintech/output/:
# - customers.csv (1,000 records)
# - individual_customers.csv (800 records)
# - business_customers.csv (200 records)
# - accounts.csv (~2,500 accounts)
# - transactions.csv (~500K transactions over 90 days)
# - fraud_alerts.csv (~10K alerts)
# - payment_methods.csv (~2K methods)
# - cards.csv (card details)
# - devices.csv (device fingerprints)
# - kyc_documents.csv (3K+ documents)
# - aml_checks.csv (periodic screening results)
# - currencies.csv (5 currencies)
# - exchange_rates.csv (daily rates for 90 days)
```

## Data Characteristics

### Volume
- **Customers**: 1,000 (800 individual, 200 business)
- **Accounts**: ~2,500 (1-4 per customer)
- **Transactions**: ~500K over 90 days
- **Fraud Alerts**: ~10K (2% of transactions)
- **Daily Volume**: 5-50 transactions per active account

### Temporal Patterns
- **Business Hours**: Higher volume 9am-5pm
- **End of Month**: Increased bill payments
- **Weekends**: Lower business transactions
- **Night Hours**: Flagged as higher risk

### Financial Distributions
- **Transaction Amounts**:
  - 60% small ($5-500)
  - 30% medium ($500-5K)
  - 9% large ($5K-50K)
  - 1% very large ($50K-500K)

- **Account Balances**:
  - Checking: $100-50K (median $2.5K)
  - Savings: $500-100K (median $10K)
  - Investment: $1K-500K (median $25K)

### Risk Distribution
- **Customer Risk**: 60% low, 30% medium, 8% high, 2% prohibited
- **Fraud Alerts**: 40% pending, 20% investigating, 35% cleared, 5% confirmed
- **Transaction Channels**: 40% online, 35% mobile, 10% ATM, 8% branch

## Output Schema

### customers.csv
```
customer_id, customer_type, email, phone_number, status, risk_level, onboarding_date, preferred_currency
```

### accounts.csv
```
account_id, customer_id, account_number, account_type, currency, status, balance, available_balance, interest_rate, opened_date
```

### transactions.csv
```
transaction_id, transaction_uuid, account_id, transaction_type, amount, currency, balance_after, description, status, initiated_at, channel
```

### fraud_alerts.csv
```
alert_id, transaction_id, customer_id, alert_type, risk_score, alert_details, status, created_at
```

## Integration

Load data into MySQL:

```sql
-- Load customers
LOAD DATA INFILE '/path/to/customers.csv'
INTO TABLE customers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Load accounts
LOAD DATA INFILE '/path/to/accounts.csv'
INTO TABLE accounts
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(account_id, @customer_id, account_number, ...)
SET customer_id = @customer_id;

-- Continue for other tables...
```

## Realistic Features

### Transaction Descriptions
- Payment processors (Stripe, Square)
- Utility companies (Electric, Gas, Water)
- Subscription services (Netflix, Spotify)
- International wires with SWIFT codes
- ATM locations in various cities

### Fraud Patterns
- **Velocity Abuse**: 5+ transactions in 1 hour
- **Amount Structuring**: Multiple $9,999 deposits
- **Geographic Jump**: Transaction from new country
- **Device Change**: Unknown device fingerprint
- **Behavioral Shift**: Night transactions for day user

### Compliance Realism
- Periodic AML checks every 30 days
- Higher risk customers = more potential matches
- Document expiry tracking
- Multi-level KYC verification
- Suspicious activity thresholds

## Performance

- Generation Time: ~30-60 seconds for full dataset
- Memory Usage: ~500MB peak
- Output Size: ~100MB total CSV files

## Validation

Run validation checks:

```python
# Check referential integrity
assert all(t['account_id'] in account_ids for t in transactions)
assert all(fa['customer_id'] in customer_ids for fa in fraud_alerts)

# Check balance consistency
for account in accounts:
    calc_balance = sum(t['amount'] for t in transactions if t['account_id'] == account['id'])
    assert abs(account['balance'] - calc_balance) < 0.01

# Check fraud alert rate
alert_rate = len(fraud_alerts) / len(transactions)
assert 0.015 <= alert_rate <= 0.025  # Should be ~2%
```

## Customization

To add new patterns:

1. Edit `config.yaml` to add new distributions
2. Modify generator methods:
   - `generate_transactions()` for new transaction types
   - `generate_fraud_alert_for_transaction()` for new fraud patterns
   - `generate_customers()` for new customer attributes

3. Update CSV output in `write_all_to_csv()`

## Troubleshooting

- **Memory Issues**: Reduce `days_of_history` or `transactions_per_account_per_day`
- **Slow Generation**: Use smaller customer counts for testing
- **Missing Dependencies**: Install `pip install faker pyyaml`