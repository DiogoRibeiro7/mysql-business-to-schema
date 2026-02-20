# Example 16 Cryptocurrency Exchange Normalization Tasks

## Goal
Normalize the raw data in `raw_exchange_feed` into a clean schema.

## 1NF
- Split repeating groups and ensure atomic values.

## 2NF
- Remove partial dependencies from composite keys.

## 3NF
- Remove transitive dependencies.

## Suggested Target Entities
- users
- wallets
- orders
- trades
- currencies

## Deliverables
- `normalized_schema.sql`
- `etl.sql` to migrate from `raw_exchange_feed`
- Short note on anomalies and functional dependencies
