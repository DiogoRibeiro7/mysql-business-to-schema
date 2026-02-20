# Example 06 Smart Agriculture Normalization Tasks

## Goal
Normalize the raw data in `raw_farm_telemetry` into a clean schema.

## 1NF
- Split repeating groups and ensure atomic values.

## 2NF
- Remove partial dependencies from composite keys.

## 3NF
- Remove transitive dependencies.

## Suggested Target Entities
- farms
- fields
- zones
- sensors
- readings
- crops
- irrigation_events

## Deliverables
- `normalized_schema.sql`
- `etl.sql` to migrate from `raw_farm_telemetry`
- Short note on anomalies and functional dependencies
