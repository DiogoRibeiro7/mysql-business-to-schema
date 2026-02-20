# Example 12 Real Estate Normalization Tasks

## Goal
Normalize the raw data in `raw_property_feed` into a clean schema.

## 1NF
- Split repeating groups and ensure atomic values.

## 2NF
- Remove partial dependencies from composite keys.

## 3NF
- Remove transitive dependencies.

## Suggested Target Entities
- properties
- agents
- agencies
- listings

## Deliverables
- `normalized_schema.sql`
- `etl.sql` to migrate from `raw_property_feed`
- Short note on anomalies and functional dependencies
