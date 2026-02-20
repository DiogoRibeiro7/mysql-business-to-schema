-- Normalized schema generated from raw denormalized table
USE food_delivery;

DROP TABLE IF EXISTS fact_food_orders;
DROP TABLE IF EXISTS dim_order;
DROP TABLE IF EXISTS dim_customer;
DROP TABLE IF EXISTS dim_restaurant;
DROP TABLE IF EXISTS dim_driver;

CREATE TABLE dim_order (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    number VARCHAR(255),
    time VARCHAR(255),
    status VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE dim_customer (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE dim_restaurant (
    restaurant_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE dim_driver (
    driver_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE fact_food_orders (
    fact_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT,
    customer_id INT,
    restaurant_id INT,
    driver_id INT,
    item_name VARCHAR(255),
    quantity VARCHAR(255),
    item_price VARCHAR(255)
) ENGINE=InnoDB;

ALTER TABLE fact_food_orders
    ADD CONSTRAINT fk_fact_food_orders_order FOREIGN KEY (order_id)
    REFERENCES dim_order (order_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE fact_food_orders
    ADD CONSTRAINT fk_fact_food_orders_customer FOREIGN KEY (customer_id)
    REFERENCES dim_customer (customer_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE fact_food_orders
    ADD CONSTRAINT fk_fact_food_orders_restaurant FOREIGN KEY (restaurant_id)
    REFERENCES dim_restaurant (restaurant_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE fact_food_orders
    ADD CONSTRAINT fk_fact_food_orders_driver FOREIGN KEY (driver_id)
    REFERENCES dim_driver (driver_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
