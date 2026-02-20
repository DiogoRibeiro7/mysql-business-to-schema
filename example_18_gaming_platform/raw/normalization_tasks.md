# Example 18 Gaming Platform Normalization Tasks

## Goal
Normalize the raw data in `raw_match_events` into a clean schema.

## 1NF
- Split repeating groups and ensure atomic values.

## 2NF
- Remove partial dependencies from composite keys.

## 3NF
- Remove transitive dependencies.

## Suggested Target Entities
- players
- games
- match_sessions
- match_participants
- servers

## Deliverables
- `normalized_schema.sql`
- `etl.sql` to migrate from `raw_match_events`
- Short note on anomalies and functional dependencies
