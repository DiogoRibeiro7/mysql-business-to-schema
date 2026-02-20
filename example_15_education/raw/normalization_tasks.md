# Example 15 Education Normalization Tasks

## Goal
Normalize the raw data in `raw_student_activity` into a clean schema.

## 1NF
- Split repeating groups and ensure atomic values.

## 2NF
- Remove partial dependencies from composite keys.

## 3NF
- Remove transitive dependencies.

## Suggested Target Entities
- students
- courses
- instructors
- enrollments
- assessments

## Deliverables
- `normalized_schema.sql`
- `etl.sql` to migrate from `raw_student_activity`
- Short note on anomalies and functional dependencies
