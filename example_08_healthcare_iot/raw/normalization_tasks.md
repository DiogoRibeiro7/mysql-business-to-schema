# Example 08 Healthcare Iot Normalization Tasks

## Goal
Normalize the raw data in `raw_vital_stream` into a clean schema.

## 1NF
- Split repeating groups and ensure atomic values.

## 2NF
- Remove partial dependencies from composite keys.

## 3NF
- Remove transitive dependencies.

## Suggested Target Entities
- patients
- devices
- vital_signs
- alerts

## Deliverables
- `normalized_schema.sql`
- `etl.sql` to migrate from `raw_vital_stream`
- Short note on anomalies and functional dependencies
