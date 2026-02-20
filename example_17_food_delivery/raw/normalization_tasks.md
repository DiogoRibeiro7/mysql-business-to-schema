# Example 17 Food Delivery Normalization Tasks

## Goal
Normalize the raw data in `raw_food_orders` into a clean schema.

## 1NF
- Split repeating groups and ensure atomic values.

## 2NF
- Remove partial dependencies from composite keys.

## 3NF
- Remove transitive dependencies.

## Suggested Target Entities
- customers
- restaurants
- menu_items
- orders
- drivers

## Deliverables
- `normalized_schema.sql`
- `etl.sql` to migrate from `raw_food_orders`
- Short note on anomalies and functional dependencies
