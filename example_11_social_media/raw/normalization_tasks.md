# Example 11 Social Media Normalization Tasks

## Goal
Normalize the raw data in `raw_social_events` into a clean schema.

## 1NF
- Split repeating groups and ensure atomic values.

## 2NF
- Remove partial dependencies from composite keys.

## 3NF
- Remove transitive dependencies.

## Suggested Target Entities
- users
- posts
- likes
- comments
- devices

## Deliverables
- `normalized_schema.sql`
- `etl.sql` to migrate from `raw_social_events`
- Short note on anomalies and functional dependencies
