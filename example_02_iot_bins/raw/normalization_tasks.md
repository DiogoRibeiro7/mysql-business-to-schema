# Example 02 Iot Bins Normalization Tasks

## Goal
Normalize the raw data in `raw_iot_bins` into a clean schema.

## 1NF
- Split repeating groups and ensure atomic values.

## 2NF
- Remove partial dependencies from composite keys.

## 3NF
- Remove transitive dependencies.

## Suggested Target Entities
- districts
- bins
- sensors
- sensor_readings
- alerts

## Deliverables
- `normalized_schema.sql`
- `etl.sql` to migrate from `raw_iot_bins`
- Short note on anomalies and functional dependencies
