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
    status VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_dim_order_natural (number, time, status),
    INDEX idx_dim_order_natural (number, time, status)
) ENGINE=InnoDB;

CREATE TABLE dim_customer (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_dim_customer_natural (email),
    INDEX idx_dim_customer_natural (email)
) ENGINE=InnoDB;

CREATE TABLE dim_restaurant (
    restaurant_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_dim_restaurant_natural (name),
    INDEX idx_dim_restaurant_natural (name)
) ENGINE=InnoDB;

CREATE TABLE dim_driver (
    driver_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(255),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_dim_driver_natural (full_name, first_name, last_name),
    INDEX idx_dim_driver_natural (full_name, first_name, last_name)
) ENGINE=InnoDB;

CREATE TABLE fact_food_orders (
    fact_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT,
    customer_id INT,
    restaurant_id INT,
    driver_id INT,
    source_row_id INT,
    UNIQUE KEY uq_fact_food_orders_source (source_row_id),
    item_name VARCHAR(255),
    quantity VARCHAR(255),
    item_price VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

ALTER TABLE fact_food_orders
    ADD CONSTRAINT fk_fact_food_orders_order FOREIGN KEY (order_id)
    REFERENCES dim_order (order_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE fact_food_orders
    ADD CONSTRAINT fk_fact_food_orders_customer FOREIGN KEY (customer_id)
    REFERENCES dim_customer (customer_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE fact_food_orders
    ADD CONSTRAINT fk_fact_food_orders_restaurant FOREIGN KEY (restaurant_id)
    REFERENCES dim_restaurant (restaurant_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE fact_food_orders
    ADD CONSTRAINT fk_fact_food_orders_driver FOREIGN KEY (driver_id)
    REFERENCES dim_driver (driver_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;
CREATE INDEX idx_fact_food_orders_order ON fact_food_orders (order_id);
CREATE INDEX idx_fact_food_orders_customer ON fact_food_orders (customer_id);
CREATE INDEX idx_fact_food_orders_restaurant ON fact_food_orders (restaurant_id);
CREATE INDEX idx_fact_food_orders_driver ON fact_food_orders (driver_id);
CREATE INDEX idx_fact_food_orders_source ON fact_food_orders (source_row_id);
