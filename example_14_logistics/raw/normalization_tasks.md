# Example 14 Logistics Normalization Tasks

## Goal
Normalize the raw data in `raw_shipment_feed` into a clean schema.

## 1NF
- Split repeating groups and ensure atomic values.

## 2NF
- Remove partial dependencies from composite keys.

## 3NF
- Remove transitive dependencies.

## Suggested Target Entities
- shipments
- warehouses
- carriers
- routes

## Deliverables
- `normalized_schema.sql`
- `etl.sql` to migrate from `raw_shipment_feed`
- Short note on anomalies and functional dependencies
