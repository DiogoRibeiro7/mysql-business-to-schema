# Example 07 Fleet Management Normalization Tasks

## Goal
Normalize the raw data in `raw_trip_feed` into a clean schema.

## 1NF
- Split repeating groups and ensure atomic values.

## 2NF
- Remove partial dependencies from composite keys.

## 3NF
- Remove transitive dependencies.

## Suggested Target Entities
- vehicles
- drivers
- trips
- gps_positions
- depots

## Deliverables
- `normalized_schema.sql`
- `etl.sql` to migrate from `raw_trip_feed`
- Short note on anomalies and functional dependencies
