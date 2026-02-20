# Example 03 Smart Energy Normalization Tasks

## Goal
Normalize the raw data in `raw_energy_feed` into a clean schema.

## 1NF
- Split repeating groups and ensure atomic values.

## 2NF
- Remove partial dependencies from composite keys.

## 3NF
- Remove transitive dependencies.

## Suggested Target Entities
- utilities
- buildings
- energy_meters
- energy_readings
- rate_plans

## Deliverables
- `normalized_schema.sql`
- `etl.sql` to migrate from `raw_energy_feed`
- Short note on anomalies and functional dependencies
