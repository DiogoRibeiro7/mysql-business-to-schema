# Example 20 Hotel Chain Normalization Tasks

## Goal
Normalize the raw data in `raw_reservation_feed` into a clean schema.

## 1NF
- Split repeating groups and ensure atomic values.

## 2NF
- Remove partial dependencies from composite keys.

## 3NF
- Remove transitive dependencies.

## Suggested Target Entities
- guests
- properties
- rooms
- reservations
- rates

## Deliverables
- `normalized_schema.sql`
- `etl.sql` to migrate from `raw_reservation_feed`
- Short note on anomalies and functional dependencies
