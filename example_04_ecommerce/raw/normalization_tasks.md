# E-commerce Normalization Tasks

## Goal
Normalize the denormalized order stream in `raw_order_stream`.

## 1NF
- Separate customer, address, product, and order item data.
- Ensure each row represents a single fact (order line item).

## 2NF
- Remove partial dependencies (e.g., product attributes should not depend on order_number).

## 3NF
- Remove transitive dependencies (e.g., brand/category should be in separate tables or referenced).

## Suggested Target Entities
- customers
- addresses
- orders
- order_items
- products
- categories
- brands
- payments

## Deliverables
- `normalized_schema.sql`
- `etl.sql` to migrate from `raw_order_stream` to normalized tables
- Short note on anomalies present in the raw data
