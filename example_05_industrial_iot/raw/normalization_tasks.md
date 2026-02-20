# Example 05 Industrial Iot Normalization Tasks

## Goal
Normalize the raw data in `raw_machine_feed` into a clean schema.

## 1NF
- Split repeating groups and ensure atomic values.

## 2NF
- Remove partial dependencies from composite keys.

## 3NF
- Remove transitive dependencies.

## Suggested Target Entities
- factories
- production_lines
- machines
- sensor_readings
- work_orders

## Deliverables
- `normalized_schema.sql`
- `etl.sql` to migrate from `raw_machine_feed`
- Short note on anomalies and functional dependencies
