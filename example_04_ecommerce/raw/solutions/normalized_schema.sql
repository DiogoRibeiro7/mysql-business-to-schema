-- Normalized schema generated from raw denormalized table
USE ecommerce;

DROP TABLE IF EXISTS fact_order_stream;
DROP TABLE IF EXISTS dim_order;
DROP TABLE IF EXISTS dim_customer;
DROP TABLE IF EXISTS dim_shipping;
DROP TABLE IF EXISTS dim_billing;
DROP TABLE IF EXISTS dim_product;
DROP TABLE IF EXISTS dim_payment;

CREATE TABLE dim_order (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    number VARCHAR(50) NOT NULL,
    date DATETIME NOT NULL,
    status VARCHAR(30)
) ENGINE=InnoDB;

CREATE TABLE dim_customer (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    name VARCHAR(200) NOT NULL,
    phone VARCHAR(30)
) ENGINE=InnoDB;

CREATE TABLE dim_shipping (
    shipping_id INT AUTO_INCREMENT PRIMARY KEY,
    address VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE dim_billing (
    billing_id INT AUTO_INCREMENT PRIMARY KEY,
    address VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE dim_product (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    sku VARCHAR(50) NOT NULL,
    name VARCHAR(200) NOT NULL,
    category VARCHAR(100),
    brand VARCHAR(100)
) ENGINE=InnoDB;

CREATE TABLE dim_payment (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    method VARCHAR(30),
    status VARCHAR(30)
) ENGINE=InnoDB;

CREATE TABLE fact_order_stream (
    fact_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT,
    customer_id INT,
    shipping_id INT,
    billing_id INT,
    product_id INT,
    payment_id INT,
    unit_price DECIMAL(10,2) NOT NULL,
    quantity INT NOT NULL,
    item_discount DECIMAL(10,2) DEFAULT 0
) ENGINE=InnoDB;

ALTER TABLE fact_order_stream
    ADD CONSTRAINT fk_fact_order_stream_order FOREIGN KEY (order_id)
    REFERENCES dim_order (order_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE fact_order_stream
    ADD CONSTRAINT fk_fact_order_stream_customer FOREIGN KEY (customer_id)
    REFERENCES dim_customer (customer_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE fact_order_stream
    ADD CONSTRAINT fk_fact_order_stream_shipping FOREIGN KEY (shipping_id)
    REFERENCES dim_shipping (shipping_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE fact_order_stream
    ADD CONSTRAINT fk_fact_order_stream_billing FOREIGN KEY (billing_id)
    REFERENCES dim_billing (billing_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE fact_order_stream
    ADD CONSTRAINT fk_fact_order_stream_product FOREIGN KEY (product_id)
    REFERENCES dim_product (product_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE fact_order_stream
    ADD CONSTRAINT fk_fact_order_stream_payment FOREIGN KEY (payment_id)
    REFERENCES dim_payment (payment_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
