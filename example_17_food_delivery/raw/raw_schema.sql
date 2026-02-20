-- Raw denormalized table for normalization exercises
USE food_delivery;

DROP TABLE IF EXISTS raw_food_orders;

CREATE TABLE raw_food_orders (
    row_id INT AUTO_INCREMENT PRIMARY KEY,
    order_number VARCHAR(255),
    order_time VARCHAR(255),
    customer_email VARCHAR(255),
    restaurant_name VARCHAR(255),
    item_name VARCHAR(255),
    quantity VARCHAR(255),
    item_price VARCHAR(255),
    driver_name VARCHAR(255),
    order_status VARCHAR(255)
) ENGINE=InnoDB;
