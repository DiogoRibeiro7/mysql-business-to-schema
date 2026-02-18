// MongoDB Migration Script
// Generated: 2026-02-17T23:16:48.764520
// From MySQL to MongoDB

use converted_db;

// Create collection: customers
db.createCollection('customers');

// Create collection: individual_customers
db.createCollection('individual_customers');

// Create collection: business_customers
db.createCollection('business_customers');

// Create collection: kyc_documents
db.createCollection('kyc_documents');

// Create collection: customer_addresses
db.createCollection('customer_addresses');

// Create collection: accounts
db.createCollection('accounts');

// Create collection: account_holders
db.createCollection('account_holders');

// Create collection: chart_of_accounts
db.createCollection('chart_of_accounts');

// Create collection: journal_entries
db.createCollection('journal_entries');

// Create collection: journal_lines
db.createCollection('journal_lines');

// Create collection: transactions
db.createCollection('transactions');

// Create collection: transfers
db.createCollection('transfers');

// Create collection: payment_methods
db.createCollection('payment_methods');

// Create collection: cards
db.createCollection('cards');

// Create collection: currencies
db.createCollection('currencies');

// Create collection: exchange_rates
db.createCollection('exchange_rates');

// Create collection: risk_rules
db.createCollection('risk_rules');

// Create collection: fraud_alerts
db.createCollection('fraud_alerts');

// Create collection: device_fingerprints
db.createCollection('device_fingerprints');

// Create collection: aml_checks
db.createCollection('aml_checks');

// Create collection: sar_reports
db.createCollection('sar_reports');

// Create collection: audit_logs
db.createCollection('audit_logs');

// Create collection: loan_applications
db.createCollection('loan_applications');

// Create collection: loan_accounts
db.createCollection('loan_accounts');

// Create collection: fee_schedule
db.createCollection('fee_schedule');

// Create collection: notification_preferences
db.createCollection('notification_preferences');

// Indexes for customers

// Indexes for individual_customers
db.individual_customers.createIndex({"customer_id": 1}, {"name": "individual_customers_customer_id_idx"});

// Indexes for business_customers
db.business_customers.createIndex({"customer_id": 1}, {"name": "business_customers_customer_id_idx"});

// Indexes for kyc_documents
db.kyc_documents.createIndex({"customer_id": 1}, {"name": "kyc_documents_customer_id_idx"});

// Indexes for customer_addresses
db.customer_addresses.createIndex({"customer_id": 1}, {"name": "customer_addresses_customer_id_idx"});

// Indexes for accounts

// Indexes for account_holders
db.account_holders.createIndex({"account_id": 1}, {"name": "account_holders_account_id_idx"});
db.account_holders.createIndex({"customer_id": 1}, {"name": "account_holders_customer_id_idx"});

// Indexes for chart_of_accounts
db.chart_of_accounts.createIndex({"parent_account_code": 1}, {"name": "chart_of_accounts_parent_account_code_idx"});
db.chart_of_accounts.createIndex({"description": "text"}, {"name": "chart_of_accounts_text"});

// Indexes for journal_lines
db.journal_lines.createIndex({"journal_id": 1}, {"name": "journal_lines_journal_id_idx"});
db.journal_lines.createIndex({"account_code": 1}, {"name": "journal_lines_account_code_idx"});

// Indexes for transactions
db.transactions.createIndex({"account_id": 1}, {"name": "transactions_account_id_idx"});

// Indexes for transfers
db.transfers.createIndex({"from_transaction_id": 1}, {"name": "transfers_from_transaction_id_idx"});
db.transfers.createIndex({"to_transaction_id": 1}, {"name": "transfers_to_transaction_id_idx"});

// Indexes for payment_methods
db.payment_methods.createIndex({"customer_id": 1}, {"name": "payment_methods_customer_id_idx"});

// Indexes for cards
db.cards.createIndex({"payment_method_id": 1}, {"name": "cards_payment_method_id_idx"});
db.cards.createIndex({"billing_address_id": 1}, {"name": "cards_billing_address_id_idx"});

// Indexes for exchange_rates
db.exchange_rates.createIndex({"from_currency": 1}, {"name": "exchange_rates_from_currency_idx"});
db.exchange_rates.createIndex({"to_currency": 1}, {"name": "exchange_rates_to_currency_idx"});

// Indexes for fraud_alerts
db.fraud_alerts.createIndex({"transaction_id": 1}, {"name": "fraud_alerts_transaction_id_idx"});
db.fraud_alerts.createIndex({"customer_id": 1}, {"name": "fraud_alerts_customer_id_idx"});
db.fraud_alerts.createIndex({"rule_id": 1}, {"name": "fraud_alerts_rule_id_idx"});

// Indexes for device_fingerprints
db.device_fingerprints.createIndex({"customer_id": 1}, {"name": "device_fingerprints_customer_id_idx"});

// Indexes for aml_checks
db.aml_checks.createIndex({"customer_id": 1}, {"name": "aml_checks_customer_id_idx"});

// Indexes for sar_reports
db.sar_reports.createIndex({"customer_id": 1}, {"name": "sar_reports_customer_id_idx"});
db.sar_reports.createIndex({"suspicious_activity": "text"}, {"name": "sar_reports_text"});

// Indexes for loan_applications
db.loan_applications.createIndex({"customer_id": 1}, {"name": "loan_applications_customer_id_idx"});

// Indexes for loan_accounts
db.loan_accounts.createIndex({"account_id": 1}, {"name": "loan_accounts_account_id_idx"});
db.loan_accounts.createIndex({"application_id": 1}, {"name": "loan_accounts_application_id_idx"});

// Indexes for fee_schedule

// Indexes for notification_preferences
db.notification_preferences.createIndex({"customer_id": 1}, {"name": "notification_preferences_customer_id_idx"});

// Validation for customers
db.runCommand({
  collMod: 'customers',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "email",
      "phone_number",
      "onboarding_date"
    ],
    "properties": {
      "customer_type": {
        "bsonType": "string"
      },
      "email": {
        "bsonType": "string"
      },
      "phone_number": {
        "bsonType": "string"
      },
      "status": {
        "bsonType": "string"
      },
      "risk_level": {
        "bsonType": "string"
      },
      "onboarding_date": {
        "bsonType": "date"
      },
      "last_activity": {
        "bsonType": "date"
      },
      "preferred_currency": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for individual_customers
db.runCommand({
  collMod: 'individual_customers',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "first_name",
      "last_name",
      "date_of_birth",
      "nationality"
    ],
    "properties": {
      "first_name": {
        "bsonType": "string"
      },
      "last_name": {
        "bsonType": "string"
      },
      "middle_name": {
        "bsonType": "string"
      },
      "date_of_birth": {
        "bsonType": "date"
      },
      "ssn_encrypted": {
        "bsonType": "bindata"
      },
      "nationality": {
        "bsonType": "string"
      },
      "occupation": {
        "bsonType": "string"
      },
      "annual_income": {
        "bsonType": "decimal128"
      },
      "source_of_wealth": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for business_customers
db.runCommand({
  collMod: 'business_customers',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "business_name"
    ],
    "properties": {
      "business_name": {
        "bsonType": "string"
      },
      "business_type": {
        "bsonType": "string"
      },
      "registration_number": {
        "bsonType": "string"
      },
      "tax_id_encrypted": {
        "bsonType": "bindata"
      },
      "incorporation_date": {
        "bsonType": "date"
      },
      "incorporation_country": {
        "bsonType": "string"
      },
      "annual_revenue": {
        "bsonType": "decimal128"
      },
      "number_of_employees": {
        "bsonType": "number"
      },
      "industry": {
        "bsonType": "string"
      },
      "website": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for kyc_documents
db.runCommand({
  collMod: 'kyc_documents',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "customer_id"
    ],
    "properties": {
      "customer_id": {
        "bsonType": "number"
      },
      "document_type": {
        "bsonType": "string"
      },
      "document_number": {
        "bsonType": "string"
      },
      "issue_date": {
        "bsonType": "date"
      },
      "expiry_date": {
        "bsonType": "date"
      },
      "issuing_country": {
        "bsonType": "string"
      },
      "verification_status": {
        "bsonType": "string"
      },
      "verified_at": {
        "bsonType": "date"
      },
      "verified_by": {
        "bsonType": "string"
      },
      "document_hash": {
        "bsonType": "string"
      },
      "storage_path": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for customer_addresses
db.runCommand({
  collMod: 'customer_addresses',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "customer_id",
      "street_address_1",
      "city",
      "country"
    ],
    "properties": {
      "customer_id": {
        "bsonType": "number"
      },
      "address_type": {
        "bsonType": "string"
      },
      "street_address_1": {
        "bsonType": "string"
      },
      "street_address_2": {
        "bsonType": "string"
      },
      "city": {
        "bsonType": "string"
      },
      "state_province": {
        "bsonType": "string"
      },
      "postal_code": {
        "bsonType": "string"
      },
      "country": {
        "bsonType": "string"
      },
      "is_primary": {
        "bsonType": "boolean"
      },
      "verified": {
        "bsonType": "boolean"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for accounts
db.runCommand({
  collMod: 'accounts',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "account_number",
      "currency",
      "opened_date"
    ],
    "properties": {
      "account_number": {
        "bsonType": "string"
      },
      "account_type": {
        "bsonType": "string"
      },
      "currency": {
        "bsonType": "string"
      },
      "status": {
        "bsonType": "string"
      },
      "balance": {
        "bsonType": "decimal128"
      },
      "available_balance": {
        "bsonType": "decimal128"
      },
      "pending_balance": {
        "bsonType": "decimal128"
      },
      "interest_rate": {
        "bsonType": "decimal128"
      },
      "overdraft_limit": {
        "bsonType": "decimal128"
      },
      "minimum_balance": {
        "bsonType": "decimal128"
      },
      "opened_date": {
        "bsonType": "date"
      },
      "closed_date": {
        "bsonType": "date"
      },
      "last_transaction_date": {
        "bsonType": "date"
      },
      "last_interest_date": {
        "bsonType": "date"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      },
      "version": {
        "bsonType": "number"
      }
    }
  }
}
});

// Validation for account_holders
db.runCommand({
  collMod: 'account_holders',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "account_id",
      "customer_id",
      "added_date"
    ],
    "properties": {
      "account_id": {
        "bsonType": "number"
      },
      "customer_id": {
        "bsonType": "number"
      },
      "relationship_type": {
        "bsonType": "string"
      },
      "ownership_percentage": {
        "bsonType": "decimal128"
      },
      "added_date": {
        "bsonType": "date"
      },
      "removed_date": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for chart_of_accounts
db.runCommand({
  collMod: 'chart_of_accounts',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "account_name"
    ],
    "properties": {
      "account_name": {
        "bsonType": "string"
      },
      "account_type": {
        "bsonType": "string"
      },
      "parent_account_code": {
        "bsonType": "string"
      },
      "is_control_account": {
        "bsonType": "boolean"
      },
      "normal_balance": {
        "bsonType": "string"
      },
      "description": {
        "bsonType": "string"
      },
      "is_active": {
        "bsonType": "boolean"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for journal_entries
db.runCommand({
  collMod: 'journal_entries',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "entry_date",
      "description"
    ],
    "properties": {
      "entry_date": {
        "bsonType": "date"
      },
      "posting_date": {
        "bsonType": "date"
      },
      "description": {
        "bsonType": "string"
      },
      "reference_type": {
        "bsonType": "string"
      },
      "reference_id": {
        "bsonType": "number"
      },
      "total_debits": {
        "bsonType": "decimal128"
      },
      "total_credits": {
        "bsonType": "decimal128"
      },
      "status": {
        "bsonType": "string"
      },
      "posted_by": {
        "bsonType": "string"
      },
      "reversed_by_journal_id": {
        "bsonType": "number"
      },
      "created_at": {
        "bsonType": "date"
      },
      "CONSTRAINT": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for journal_lines
db.runCommand({
  collMod: 'journal_lines',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "journal_id",
      "account_code",
      "currency"
    ],
    "properties": {
      "journal_id": {
        "bsonType": "number"
      },
      "account_code": {
        "bsonType": "string"
      },
      "debit_amount": {
        "bsonType": "decimal128"
      },
      "credit_amount": {
        "bsonType": "decimal128"
      },
      "currency": {
        "bsonType": "string"
      },
      "exchange_rate": {
        "bsonType": "decimal128"
      },
      "base_currency_amount": {
        "bsonType": "decimal128"
      },
      "description": {
        "bsonType": "string"
      },
      "CONSTRAINT": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for transactions
db.runCommand({
  collMod: 'transactions',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "transaction_uuid",
      "account_id",
      "currency"
    ],
    "properties": {
      "transaction_uuid": {
        "bsonType": "string"
      },
      "account_id": {
        "bsonType": "number"
      },
      "transaction_type": {
        "bsonType": "string"
      },
      "amount": {
        "bsonType": "decimal128"
      },
      "currency": {
        "bsonType": "string"
      },
      "balance_after": {
        "bsonType": "decimal128"
      },
      "description": {
        "bsonType": "string"
      },
      "reference_number": {
        "bsonType": "string"
      },
      "status": {
        "bsonType": "string"
      },
      "initiated_at": {
        "bsonType": "string"
      },
      "completed_at": {
        "bsonType": "date"
      },
      "reversed_at": {
        "bsonType": "date"
      },
      "reversal_reason": {
        "bsonType": "string"
      },
      "channel": {
        "bsonType": "string"
      },
      "ip_address": {
        "bsonType": "string"
      },
      "device_id": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for transfers
db.runCommand({
  collMod: 'transfers',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "from_transaction_id",
      "to_transaction_id",
      "from_currency",
      "to_currency"
    ],
    "properties": {
      "from_transaction_id": {
        "bsonType": "number"
      },
      "to_transaction_id": {
        "bsonType": "number"
      },
      "transfer_type": {
        "bsonType": "string"
      },
      "amount": {
        "bsonType": "decimal128"
      },
      "from_currency": {
        "bsonType": "string"
      },
      "to_currency": {
        "bsonType": "string"
      },
      "exchange_rate": {
        "bsonType": "decimal128"
      },
      "fee_amount": {
        "bsonType": "decimal128"
      },
      "swift_code": {
        "bsonType": "string"
      },
      "routing_number": {
        "bsonType": "string"
      },
      "beneficiary_name": {
        "bsonType": "string"
      },
      "beneficiary_reference": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for payment_methods
db.runCommand({
  collMod: 'payment_methods',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "customer_id"
    ],
    "properties": {
      "customer_id": {
        "bsonType": "number"
      },
      "method_type": {
        "bsonType": "string"
      },
      "is_default": {
        "bsonType": "boolean"
      },
      "is_active": {
        "bsonType": "boolean"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for cards
db.runCommand({
  collMod: 'cards',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "payment_method_id",
      "card_number_masked",
      "card_number_hash",
      "expiry_month",
      "expiry_year",
      "cardholder_name"
    ],
    "properties": {
      "payment_method_id": {
        "bsonType": "number"
      },
      "card_number_masked": {
        "bsonType": "string"
      },
      "card_number_hash": {
        "bsonType": "string"
      },
      "card_type": {
        "bsonType": "string"
      },
      "card_brand": {
        "bsonType": "string"
      },
      "expiry_month": {
        "bsonType": "number"
      },
      "expiry_year": {
        "bsonType": "number"
      },
      "cardholder_name": {
        "bsonType": "string"
      },
      "billing_address_id": {
        "bsonType": "number"
      },
      "token": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for currencies
db.runCommand({
  collMod: 'currencies',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "currency_name"
    ],
    "properties": {
      "currency_name": {
        "bsonType": "string"
      },
      "symbol": {
        "bsonType": "string"
      },
      "decimal_places": {
        "bsonType": "number"
      },
      "is_active": {
        "bsonType": "boolean"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for exchange_rates
db.runCommand({
  collMod: 'exchange_rates',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "from_currency",
      "to_currency",
      "rate_date"
    ],
    "properties": {
      "from_currency": {
        "bsonType": "string"
      },
      "to_currency": {
        "bsonType": "string"
      },
      "rate_date": {
        "bsonType": "date"
      },
      "exchange_rate": {
        "bsonType": "decimal128"
      },
      "rate_source": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for risk_rules
db.runCommand({
  collMod: 'risk_rules',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "rule_name",
      "rule_condition",
      "risk_score"
    ],
    "properties": {
      "rule_name": {
        "bsonType": "string"
      },
      "rule_type": {
        "bsonType": "string"
      },
      "rule_condition": {
        "bsonType": "object"
      },
      "risk_score": {
        "bsonType": "number"
      },
      "action": {
        "bsonType": "string"
      },
      "is_active": {
        "bsonType": "boolean"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for fraud_alerts
db.runCommand({
  collMod: 'fraud_alerts',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "customer_id",
      "risk_score"
    ],
    "properties": {
      "transaction_id": {
        "bsonType": "number"
      },
      "customer_id": {
        "bsonType": "number"
      },
      "rule_id": {
        "bsonType": "number"
      },
      "alert_type": {
        "bsonType": "string"
      },
      "risk_score": {
        "bsonType": "number"
      },
      "alert_details": {
        "bsonType": "object"
      },
      "status": {
        "bsonType": "string"
      },
      "action_taken": {
        "bsonType": "string"
      },
      "investigated_by": {
        "bsonType": "string"
      },
      "investigated_at": {
        "bsonType": "date"
      },
      "created_at": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for device_fingerprints
db.runCommand({
  collMod: 'device_fingerprints',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "customer_id",
      "device_hash"
    ],
    "properties": {
      "customer_id": {
        "bsonType": "number"
      },
      "device_hash": {
        "bsonType": "string"
      },
      "device_type": {
        "bsonType": "string"
      },
      "operating_system": {
        "bsonType": "string"
      },
      "browser": {
        "bsonType": "string"
      },
      "ip_address": {
        "bsonType": "string"
      },
      "location_country": {
        "bsonType": "string"
      },
      "location_city": {
        "bsonType": "string"
      },
      "first_seen": {
        "bsonType": "date"
      },
      "last_seen": {
        "bsonType": "date"
      },
      "trust_score": {
        "bsonType": "number"
      },
      "is_blocked": {
        "bsonType": "boolean"
      }
    }
  }
}
});

// Validation for aml_checks
db.runCommand({
  collMod: 'aml_checks',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "customer_id",
      "check_date"
    ],
    "properties": {
      "customer_id": {
        "bsonType": "number"
      },
      "check_type": {
        "bsonType": "string"
      },
      "check_provider": {
        "bsonType": "string"
      },
      "check_date": {
        "bsonType": "string"
      },
      "result": {
        "bsonType": "string"
      },
      "match_details": {
        "bsonType": "object"
      },
      "reviewed_by": {
        "bsonType": "string"
      },
      "reviewed_at": {
        "bsonType": "date"
      },
      "decision": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for sar_reports
db.runCommand({
  collMod: 'sar_reports',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "customer_id",
      "filing_date",
      "reporting_period_start",
      "reporting_period_end",
      "suspicious_activity"
    ],
    "properties": {
      "customer_id": {
        "bsonType": "number"
      },
      "filing_date": {
        "bsonType": "date"
      },
      "reporting_period_start": {
        "bsonType": "date"
      },
      "reporting_period_end": {
        "bsonType": "date"
      },
      "suspicious_activity": {
        "bsonType": "string"
      },
      "total_amount": {
        "bsonType": "decimal128"
      },
      "currency": {
        "bsonType": "string"
      },
      "filing_status": {
        "bsonType": "string"
      },
      "filing_reference": {
        "bsonType": "string"
      },
      "prepared_by": {
        "bsonType": "string"
      },
      "approved_by": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for audit_logs
db.runCommand({
  collMod: 'audit_logs',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "user_id",
      "action_type",
      "entity_type",
      "entity_id"
    ],
    "properties": {
      "user_id": {
        "bsonType": "string"
      },
      "action_type": {
        "bsonType": "string"
      },
      "entity_type": {
        "bsonType": "string"
      },
      "entity_id": {
        "bsonType": "number"
      },
      "old_values": {
        "bsonType": "object"
      },
      "new_values": {
        "bsonType": "object"
      },
      "ip_address": {
        "bsonType": "string"
      },
      "user_agent": {
        "bsonType": "string"
      },
      "session_id": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for loan_applications
db.runCommand({
  collMod: 'loan_applications',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "customer_id",
      "term_months"
    ],
    "properties": {
      "customer_id": {
        "bsonType": "number"
      },
      "loan_type": {
        "bsonType": "string"
      },
      "requested_amount": {
        "bsonType": "decimal128"
      },
      "currency": {
        "bsonType": "string"
      },
      "loan_purpose": {
        "bsonType": "string"
      },
      "term_months": {
        "bsonType": "number"
      },
      "requested_rate": {
        "bsonType": "decimal128"
      },
      "credit_score": {
        "bsonType": "number"
      },
      "debt_to_income": {
        "bsonType": "decimal128"
      },
      "status": {
        "bsonType": "string"
      },
      "decision_date": {
        "bsonType": "date"
      },
      "decision_reason": {
        "bsonType": "string"
      },
      "approved_amount": {
        "bsonType": "decimal128"
      },
      "approved_rate": {
        "bsonType": "decimal128"
      },
      "approved_term_months": {
        "bsonType": "number"
      },
      "application_date": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for loan_accounts
db.runCommand({
  collMod: 'loan_accounts',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "account_id",
      "application_id",
      "term_months",
      "origination_date",
      "first_payment_date",
      "maturity_date",
      "payments_remaining"
    ],
    "properties": {
      "account_id": {
        "bsonType": "number"
      },
      "application_id": {
        "bsonType": "number"
      },
      "principal_amount": {
        "bsonType": "decimal128"
      },
      "outstanding_principal": {
        "bsonType": "decimal128"
      },
      "interest_rate": {
        "bsonType": "decimal128"
      },
      "term_months": {
        "bsonType": "number"
      },
      "monthly_payment": {
        "bsonType": "decimal128"
      },
      "origination_date": {
        "bsonType": "date"
      },
      "first_payment_date": {
        "bsonType": "date"
      },
      "maturity_date": {
        "bsonType": "date"
      },
      "last_payment_date": {
        "bsonType": "date"
      },
      "next_payment_date": {
        "bsonType": "date"
      },
      "payments_made": {
        "bsonType": "number"
      },
      "payments_remaining": {
        "bsonType": "number"
      },
      "status": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for fee_schedule
db.runCommand({
  collMod: 'fee_schedule',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "fee_code",
      "fee_name",
      "effective_date"
    ],
    "properties": {
      "fee_code": {
        "bsonType": "string"
      },
      "fee_name": {
        "bsonType": "string"
      },
      "fee_type": {
        "bsonType": "string"
      },
      "amount": {
        "bsonType": "decimal128"
      },
      "percentage": {
        "bsonType": "decimal128"
      },
      "minimum_amount": {
        "bsonType": "decimal128"
      },
      "maximum_amount": {
        "bsonType": "decimal128"
      },
      "currency": {
        "bsonType": "string"
      },
      "is_active": {
        "bsonType": "boolean"
      },
      "effective_date": {
        "bsonType": "date"
      },
      "end_date": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for notification_preferences
db.runCommand({
  collMod: 'notification_preferences',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "customer_id",
      "notification_type"
    ],
    "properties": {
      "customer_id": {
        "bsonType": "number"
      },
      "notification_type": {
        "bsonType": "string"
      },
      "email_enabled": {
        "bsonType": "boolean"
      },
      "sms_enabled": {
        "bsonType": "boolean"
      },
      "push_enabled": {
        "bsonType": "boolean"
      },
      "in_app_enabled": {
        "bsonType": "boolean"
      },
      "threshold_amount": {
        "bsonType": "decimal128"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});
