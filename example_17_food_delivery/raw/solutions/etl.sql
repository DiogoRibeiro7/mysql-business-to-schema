-- ETL from raw denormalized table into normalized tables
USE food_delivery;

INSERT INTO dim_order (number, time, status)
SELECT DISTINCT r.order_number, r.order_time, r.order_status
FROM raw_food_orders r;

INSERT INTO dim_customer (email)
SELECT DISTINCT r.customer_email
FROM raw_food_orders r;

INSERT INTO dim_restaurant (name)
SELECT DISTINCT r.restaurant_name
FROM raw_food_orders r;

INSERT INTO dim_driver (name)
SELECT DISTINCT r.driver_name
FROM raw_food_orders r;

INSERT INTO fact_food_orders (order_id, customer_id, restaurant_id, driver_id, item_name, quantity, item_price)
SELECT
    d_order.order_id,
    d_customer.customer_id,
    d_restaurant.restaurant_id,
    d_driver.driver_id,
    r.item_name,
    r.quantity,
    r.item_price
FROM raw_food_orders r
LEFT JOIN dim_order d_order ON r.order_number <=> d_order.number AND r.order_time <=> d_order.time AND r.order_status <=> d_order.status
LEFT JOIN dim_customer d_customer ON r.customer_email <=> d_customer.email
LEFT JOIN dim_restaurant d_restaurant ON r.restaurant_name <=> d_restaurant.name
LEFT JOIN dim_driver d_driver ON r.driver_name <=> d_driver.name
;
