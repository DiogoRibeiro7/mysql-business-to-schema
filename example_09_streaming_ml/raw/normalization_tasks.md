# Example 09 Streaming Ml Normalization Tasks

## Goal
Normalize the raw data in `raw_event_stream` into a clean schema.

## 1NF
- Split repeating groups and ensure atomic values.

## 2NF
- Remove partial dependencies from composite keys.

## 3NF
- Remove transitive dependencies.

## Suggested Target Entities
- organizations
- projects
- data_streams
- raw_features
- models
- predictions

## Deliverables
- `normalized_schema.sql`
- `etl.sql` to migrate from `raw_event_stream`
- Short note on anomalies and functional dependencies
