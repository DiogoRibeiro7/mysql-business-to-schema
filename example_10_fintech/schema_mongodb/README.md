# MongoDB Schema for example_10_fintech

Converted from MySQL on 2026-02-17T23:16:48.765769

## Collections

### customers

**Document Structure:**
```json
{
  "customer_type": {
    "type": "String",
    "required": false
  },
  "email": {
    "type": "String",
    "required": true
  },
  "phone_number": {
    "type": "String",
    "required": true
  },
  "status": {
    "type": "String",
    "required": false
  },
  "risk_level": {
    "type": "String",
    "required": false
  },
  "onboarding_date": {
    "type": "Date",
    "required": true
  },
  "last_activity": {
    "type": "Date",
    "required": false
  },
  "preferred_currency": {
    "type": "String",
    "required": false,
    "default": "USD"
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### individual_customers

**Document Structure:**
```json
{
  "first_name": {
    "type": "String",
    "required": true
  },
  "last_name": {
    "type": "String",
    "required": true
  },
  "middle_name": {
    "type": "String",
    "required": false
  },
  "date_of_birth": {
    "type": "Date",
    "required": true
  },
  "ssn_encrypted": {
    "type": "BinData",
    "required": false
  },
  "nationality": {
    "type": "String",
    "required": true
  },
  "occupation": {
    "type": "String",
    "required": false
  },
  "annual_income": {
    "type": "Decimal128",
    "required": false
  },
  "source_of_wealth": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** customers_id

### business_customers

**Document Structure:**
```json
{
  "business_name": {
    "type": "String",
    "required": true
  },
  "business_type": {
    "type": "String",
    "required": false
  },
  "registration_number": {
    "type": "String",
    "required": false
  },
  "tax_id_encrypted": {
    "type": "BinData",
    "required": false
  },
  "incorporation_date": {
    "type": "Date",
    "required": false
  },
  "incorporation_country": {
    "type": "String",
    "required": false
  },
  "annual_revenue": {
    "type": "Decimal128",
    "required": false
  },
  "number_of_employees": {
    "type": "Number",
    "required": false
  },
  "industry": {
    "type": "String",
    "required": false
  },
  "website": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** customers_id

### kyc_documents

**Document Structure:**
```json
{
  "customer_id": {
    "type": "Number",
    "required": true
  },
  "document_type": {
    "type": "String",
    "required": false
  },
  "document_number": {
    "type": "String",
    "required": false
  },
  "issue_date": {
    "type": "Date",
    "required": false
  },
  "expiry_date": {
    "type": "Date",
    "required": false
  },
  "issuing_country": {
    "type": "String",
    "required": false
  },
  "verification_status": {
    "type": "String",
    "required": false
  },
  "verified_at": {
    "type": "Date",
    "required": false
  },
  "verified_by": {
    "type": "String",
    "required": false
  },
  "document_hash": {
    "type": "String",
    "required": false
  },
  "storage_path": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** customers_id

### customer_addresses

**Document Structure:**
```json
{
  "customer_id": {
    "type": "Number",
    "required": true
  },
  "address_type": {
    "type": "String",
    "required": false
  },
  "street_address_1": {
    "type": "String",
    "required": true
  },
  "street_address_2": {
    "type": "String",
    "required": false
  },
  "city": {
    "type": "String",
    "required": true
  },
  "state_province": {
    "type": "String",
    "required": false
  },
  "postal_code": {
    "type": "String",
    "required": false
  },
  "country": {
    "type": "String",
    "required": true
  },
  "is_primary": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "verified": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** customers_id

### accounts

**Document Structure:**
```json
{
  "account_number": {
    "type": "String",
    "required": true
  },
  "account_type": {
    "type": "String",
    "required": false
  },
  "currency": {
    "type": "String",
    "required": true,
    "default": "USD"
  },
  "status": {
    "type": "String",
    "required": false
  },
  "balance": {
    "type": "Decimal128",
    "required": false
  },
  "available_balance": {
    "type": "Decimal128",
    "required": false
  },
  "pending_balance": {
    "type": "Decimal128",
    "required": false
  },
  "interest_rate": {
    "type": "Decimal128",
    "required": false
  },
  "overdraft_limit": {
    "type": "Decimal128",
    "required": false
  },
  "minimum_balance": {
    "type": "Decimal128",
    "required": false
  },
  "opened_date": {
    "type": "Date",
    "required": true
  },
  "closed_date": {
    "type": "Date",
    "required": false
  },
  "last_transaction_date": {
    "type": "Date",
    "required": false
  },
  "last_interest_date": {
    "type": "Date",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "version": {
    "type": "Number",
    "required": false,
    "default": "0"
  }
}
```

### account_holders

**Document Structure:**
```json
{
  "account_id": {
    "type": "Number",
    "required": true
  },
  "customer_id": {
    "type": "Number",
    "required": true
  },
  "relationship_type": {
    "type": "String",
    "required": false
  },
  "ownership_percentage": {
    "type": "Decimal128",
    "required": false
  },
  "added_date": {
    "type": "Date",
    "required": true
  },
  "removed_date": {
    "type": "Date",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** accounts_id, customers_id

### chart_of_accounts

**Document Structure:**
```json
{
  "account_name": {
    "type": "String",
    "required": true
  },
  "account_type": {
    "type": "String",
    "required": false
  },
  "parent_account_code": {
    "type": "String",
    "required": false
  },
  "is_control_account": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "normal_balance": {
    "type": "String",
    "required": false
  },
  "description": {
    "type": "String",
    "required": false
  },
  "is_active": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** chart_of_accounts_id

### journal_entries

**Document Structure:**
```json
{
  "entry_date": {
    "type": "Date",
    "required": true
  },
  "posting_date": {
    "type": "Date",
    "required": false,
    "default": "CURRENT_TIMESTAMP"
  },
  "description": {
    "type": "String",
    "required": true
  },
  "reference_type": {
    "type": "String",
    "required": false
  },
  "reference_id": {
    "type": "Number",
    "required": false
  },
  "total_debits": {
    "type": "Decimal128",
    "required": false
  },
  "total_credits": {
    "type": "Decimal128",
    "required": false
  },
  "status": {
    "type": "String",
    "required": false
  },
  "posted_by": {
    "type": "String",
    "required": false
  },
  "reversed_by_journal_id": {
    "type": "Number",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "CONSTRAINT": {
    "type": "String",
    "required": false
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### journal_lines

**Document Structure:**
```json
{
  "journal_id": {
    "type": "Number",
    "required": true
  },
  "account_code": {
    "type": "String",
    "required": true
  },
  "debit_amount": {
    "type": "Decimal128",
    "required": false
  },
  "credit_amount": {
    "type": "Decimal128",
    "required": false
  },
  "currency": {
    "type": "String",
    "required": true,
    "default": "USD"
  },
  "exchange_rate": {
    "type": "Decimal128",
    "required": false
  },
  "base_currency_amount": {
    "type": "Decimal128",
    "required": false
  },
  "description": {
    "type": "String",
    "required": false
  },
  "CONSTRAINT": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** journal_entries_id, chart_of_accounts_id

### transactions

**Document Structure:**
```json
{
  "transaction_uuid": {
    "type": "String",
    "required": true
  },
  "account_id": {
    "type": "Number",
    "required": true
  },
  "transaction_type": {
    "type": "String",
    "required": false
  },
  "amount": {
    "type": "Decimal128",
    "required": false
  },
  "currency": {
    "type": "String",
    "required": true
  },
  "balance_after": {
    "type": "Decimal128",
    "required": false
  },
  "description": {
    "type": "String",
    "required": false
  },
  "reference_number": {
    "type": "String",
    "required": false
  },
  "status": {
    "type": "String",
    "required": false
  },
  "initiated_at": {
    "type": "String",
    "required": false
  },
  "completed_at": {
    "type": "Date",
    "required": false
  },
  "reversed_at": {
    "type": "Date",
    "required": false
  },
  "reversal_reason": {
    "type": "String",
    "required": false
  },
  "channel": {
    "type": "String",
    "required": false
  },
  "ip_address": {
    "type": "String",
    "required": false
  },
  "device_id": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** accounts_id

### transfers

**Document Structure:**
```json
{
  "from_transaction_id": {
    "type": "Number",
    "required": true
  },
  "to_transaction_id": {
    "type": "Number",
    "required": true
  },
  "transfer_type": {
    "type": "String",
    "required": false
  },
  "amount": {
    "type": "Decimal128",
    "required": false
  },
  "from_currency": {
    "type": "String",
    "required": true
  },
  "to_currency": {
    "type": "String",
    "required": true
  },
  "exchange_rate": {
    "type": "Decimal128",
    "required": false
  },
  "fee_amount": {
    "type": "Decimal128",
    "required": false
  },
  "swift_code": {
    "type": "String",
    "required": false
  },
  "routing_number": {
    "type": "String",
    "required": false
  },
  "beneficiary_name": {
    "type": "String",
    "required": false
  },
  "beneficiary_reference": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** transactions_id, transactions_id

### payment_methods

**Document Structure:**
```json
{
  "customer_id": {
    "type": "Number",
    "required": true
  },
  "method_type": {
    "type": "String",
    "required": false
  },
  "is_default": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "is_active": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** customers_id

### cards

**Document Structure:**
```json
{
  "payment_method_id": {
    "type": "Number",
    "required": true
  },
  "card_number_masked": {
    "type": "String",
    "required": true
  },
  "card_number_hash": {
    "type": "String",
    "required": true
  },
  "card_type": {
    "type": "String",
    "required": false
  },
  "card_brand": {
    "type": "String",
    "required": false
  },
  "expiry_month": {
    "type": "Number",
    "required": true
  },
  "expiry_year": {
    "type": "Number",
    "required": true
  },
  "cardholder_name": {
    "type": "String",
    "required": true
  },
  "billing_address_id": {
    "type": "Number",
    "required": false
  },
  "token": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** payment_methods_id, customer_addresses_id

### currencies

**Document Structure:**
```json
{
  "currency_name": {
    "type": "String",
    "required": true
  },
  "symbol": {
    "type": "String",
    "required": false
  },
  "decimal_places": {
    "type": "Number",
    "required": false,
    "default": "2"
  },
  "is_active": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### exchange_rates

**Document Structure:**
```json
{
  "from_currency": {
    "type": "String",
    "required": true
  },
  "to_currency": {
    "type": "String",
    "required": true
  },
  "rate_date": {
    "type": "Date",
    "required": true
  },
  "exchange_rate": {
    "type": "Decimal128",
    "required": false
  },
  "rate_source": {
    "type": "String",
    "required": false,
    "default": "SYSTEM"
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** currencies_id, currencies_id

### risk_rules

**Document Structure:**
```json
{
  "rule_name": {
    "type": "String",
    "required": true
  },
  "rule_type": {
    "type": "String",
    "required": false
  },
  "rule_condition": {
    "type": "Object",
    "required": true
  },
  "risk_score": {
    "type": "Number",
    "required": true
  },
  "action": {
    "type": "String",
    "required": false
  },
  "is_active": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### fraud_alerts

**Document Structure:**
```json
{
  "transaction_id": {
    "type": "Number",
    "required": false
  },
  "customer_id": {
    "type": "Number",
    "required": true
  },
  "rule_id": {
    "type": "Number",
    "required": false
  },
  "alert_type": {
    "type": "String",
    "required": false
  },
  "risk_score": {
    "type": "Number",
    "required": true
  },
  "alert_details": {
    "type": "Object",
    "required": false
  },
  "status": {
    "type": "String",
    "required": false
  },
  "action_taken": {
    "type": "String",
    "required": false
  },
  "investigated_by": {
    "type": "String",
    "required": false
  },
  "investigated_at": {
    "type": "Date",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** transactions_id, customers_id, risk_rules_id

### device_fingerprints

**Document Structure:**
```json
{
  "customer_id": {
    "type": "Number",
    "required": true
  },
  "device_hash": {
    "type": "String",
    "required": true
  },
  "device_type": {
    "type": "String",
    "required": false
  },
  "operating_system": {
    "type": "String",
    "required": false
  },
  "browser": {
    "type": "String",
    "required": false
  },
  "ip_address": {
    "type": "String",
    "required": false
  },
  "location_country": {
    "type": "String",
    "required": false
  },
  "location_city": {
    "type": "String",
    "required": false
  },
  "first_seen": {
    "type": "Date",
    "required": false,
    "default": "CURRENT_TIMESTAMP"
  },
  "last_seen": {
    "type": "Date",
    "required": false,
    "default": "CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP"
  },
  "trust_score": {
    "type": "Number",
    "required": false,
    "default": "50"
  },
  "is_blocked": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** customers_id

### aml_checks

**Document Structure:**
```json
{
  "customer_id": {
    "type": "Number",
    "required": true
  },
  "check_type": {
    "type": "String",
    "required": false
  },
  "check_provider": {
    "type": "String",
    "required": false
  },
  "check_date": {
    "type": "String",
    "required": false
  },
  "result": {
    "type": "String",
    "required": false
  },
  "match_details": {
    "type": "Object",
    "required": false
  },
  "reviewed_by": {
    "type": "String",
    "required": false
  },
  "reviewed_at": {
    "type": "Date",
    "required": false
  },
  "decision": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** customers_id

### sar_reports

**Document Structure:**
```json
{
  "customer_id": {
    "type": "Number",
    "required": true
  },
  "filing_date": {
    "type": "Date",
    "required": true
  },
  "reporting_period_start": {
    "type": "Date",
    "required": true
  },
  "reporting_period_end": {
    "type": "Date",
    "required": true
  },
  "suspicious_activity": {
    "type": "String",
    "required": true
  },
  "total_amount": {
    "type": "Decimal128",
    "required": false
  },
  "currency": {
    "type": "String",
    "required": false
  },
  "filing_status": {
    "type": "String",
    "required": false
  },
  "filing_reference": {
    "type": "String",
    "required": false
  },
  "prepared_by": {
    "type": "String",
    "required": false
  },
  "approved_by": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** customers_id

### audit_logs

**Document Structure:**
```json
{
  "user_id": {
    "type": "String",
    "required": true
  },
  "action_type": {
    "type": "String",
    "required": true
  },
  "entity_type": {
    "type": "String",
    "required": true
  },
  "entity_id": {
    "type": "Number",
    "required": true
  },
  "old_values": {
    "type": "Object",
    "required": false
  },
  "new_values": {
    "type": "Object",
    "required": false
  },
  "ip_address": {
    "type": "String",
    "required": false
  },
  "user_agent": {
    "type": "String",
    "required": false
  },
  "session_id": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### loan_applications

**Document Structure:**
```json
{
  "customer_id": {
    "type": "Number",
    "required": true
  },
  "loan_type": {
    "type": "String",
    "required": false
  },
  "requested_amount": {
    "type": "Decimal128",
    "required": false
  },
  "currency": {
    "type": "String",
    "required": false,
    "default": "USD"
  },
  "loan_purpose": {
    "type": "String",
    "required": false
  },
  "term_months": {
    "type": "Number",
    "required": true
  },
  "requested_rate": {
    "type": "Decimal128",
    "required": false
  },
  "credit_score": {
    "type": "Number",
    "required": false
  },
  "debt_to_income": {
    "type": "Decimal128",
    "required": false
  },
  "status": {
    "type": "String",
    "required": false
  },
  "decision_date": {
    "type": "Date",
    "required": false
  },
  "decision_reason": {
    "type": "String",
    "required": false
  },
  "approved_amount": {
    "type": "Decimal128",
    "required": false
  },
  "approved_rate": {
    "type": "Decimal128",
    "required": false
  },
  "approved_term_months": {
    "type": "Number",
    "required": false
  },
  "application_date": {
    "type": "Date",
    "required": false,
    "default": "CURRENT_TIMESTAMP"
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** customers_id

### loan_accounts

**Document Structure:**
```json
{
  "account_id": {
    "type": "Number",
    "required": true
  },
  "application_id": {
    "type": "Number",
    "required": true
  },
  "principal_amount": {
    "type": "Decimal128",
    "required": false
  },
  "outstanding_principal": {
    "type": "Decimal128",
    "required": false
  },
  "interest_rate": {
    "type": "Decimal128",
    "required": false
  },
  "term_months": {
    "type": "Number",
    "required": true
  },
  "monthly_payment": {
    "type": "Decimal128",
    "required": false
  },
  "origination_date": {
    "type": "Date",
    "required": true
  },
  "first_payment_date": {
    "type": "Date",
    "required": true
  },
  "maturity_date": {
    "type": "Date",
    "required": true
  },
  "last_payment_date": {
    "type": "Date",
    "required": false
  },
  "next_payment_date": {
    "type": "Date",
    "required": false
  },
  "payments_made": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "payments_remaining": {
    "type": "Number",
    "required": true
  },
  "status": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** accounts_id, loan_applications_id

### fee_schedule

**Document Structure:**
```json
{
  "fee_code": {
    "type": "String",
    "required": true
  },
  "fee_name": {
    "type": "String",
    "required": true
  },
  "fee_type": {
    "type": "String",
    "required": false
  },
  "amount": {
    "type": "Decimal128",
    "required": false
  },
  "percentage": {
    "type": "Decimal128",
    "required": false
  },
  "minimum_amount": {
    "type": "Decimal128",
    "required": false
  },
  "maximum_amount": {
    "type": "Decimal128",
    "required": false
  },
  "currency": {
    "type": "String",
    "required": false,
    "default": "USD"
  },
  "is_active": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "effective_date": {
    "type": "Date",
    "required": true
  },
  "end_date": {
    "type": "Date",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### notification_preferences

**Document Structure:**
```json
{
  "customer_id": {
    "type": "Number",
    "required": true
  },
  "notification_type": {
    "type": "String",
    "required": true
  },
  "email_enabled": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "sms_enabled": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "push_enabled": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "in_app_enabled": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "threshold_amount": {
    "type": "Decimal128",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** customers_id

