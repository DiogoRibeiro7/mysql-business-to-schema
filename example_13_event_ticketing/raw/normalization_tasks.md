# Example 13 Event Ticketing Normalization Tasks

## Goal
Normalize the raw data in `raw_ticket_sales` into a clean schema.

## 1NF
- Split repeating groups and ensure atomic values.

## 2NF
- Remove partial dependencies from composite keys.

## 3NF
- Remove transitive dependencies.

## Suggested Target Entities
- events
- venues
- tickets
- customers
- payments

## Deliverables
- `normalized_schema.sql`
- `etl.sql` to migrate from `raw_ticket_sales`
- Short note on anomalies and functional dependencies
