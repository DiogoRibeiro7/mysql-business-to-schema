# FinTech Normalization Tasks

## Goal
Normalize the denormalized transaction feed in `raw_transaction_feed`.

## 1NF
- Separate customer, account, and transaction facts.
- Ensure each column is atomic and represents a single attribute.

## 2NF
- Remove partial dependencies (account attributes should not depend on transaction_id).

## 3NF
- Remove transitive dependencies (merchant category, KYC status).

## Suggested Target Entities
- customers
- accounts
- transactions
- merchants
- merchant_categories
- kyc_statuses
- devices

## Deliverables
- `normalized_schema.sql`
- `etl.sql` to migrate from `raw_transaction_feed` to normalized tables
- Short note on anomalies (update/delete/insert anomalies)
