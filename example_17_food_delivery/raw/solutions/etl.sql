-- ETL from raw denormalized table into normalized tables
USE food_delivery;

INSERT INTO dim_order (number, time, status, created_at, updated_at)
SELECT DISTINCT r.order_number, r.order_time, r.order_status, NOW(), NOW()
FROM raw_food_orders r;

INSERT INTO dim_customer (email, created_at, updated_at)
SELECT DISTINCT r.customer_email, NOW(), NOW()
FROM raw_food_orders r;

INSERT INTO dim_restaurant (name, created_at, updated_at)
SELECT DISTINCT r.restaurant_name, NOW(), NOW()
FROM raw_food_orders r;

INSERT INTO dim_driver (full_name, first_name, last_name, created_at, updated_at)
SELECT DISTINCT r.driver_name, SUBSTRING_INDEX(r.driver_name, ' ', 1), CASE WHEN INSTR(r.driver_name, ' ') > 0 THEN SUBSTRING(r.driver_name, INSTR(r.driver_name, ' ') + 1) ELSE '' END, NOW(), NOW()
FROM raw_food_orders r;

INSERT INTO fact_food_orders (order_id, customer_id, restaurant_id, driver_id, source_row_id, item_name, quantity, item_price, created_at, updated_at)
SELECT
    d_order.order_id,
    d_customer.customer_id,
    d_restaurant.restaurant_id,
    d_driver.driver_id,
    r.row_id,
    r.item_name,
    r.quantity,
    r.item_price,
    NOW(),
    NOW()
FROM raw_food_orders r
LEFT JOIN dim_order d_order ON r.order_number <=> d_order.number AND r.order_time <=> d_order.time AND r.order_status <=> d_order.status
LEFT JOIN dim_customer d_customer ON r.customer_email <=> d_customer.email
LEFT JOIN dim_restaurant d_restaurant ON r.restaurant_name <=> d_restaurant.name
LEFT JOIN dim_driver d_driver ON r.driver_name <=> d_driver.full_name AND SUBSTRING_INDEX(r.driver_name, ' ', 1) <=> d_driver.first_name AND CASE WHEN INSTR(r.driver_name, ' ') > 0 THEN SUBSTRING(r.driver_name, INSTR(r.driver_name, ' ') + 1) ELSE '' END <=> d_driver.last_name
;
