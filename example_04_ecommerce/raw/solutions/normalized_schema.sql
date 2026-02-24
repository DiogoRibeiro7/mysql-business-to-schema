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
    status VARCHAR(30),
    UNIQUE KEY uq_dim_order_natural (number, date, status)
) ENGINE=InnoDB;

CREATE TABLE dim_customer (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    name VARCHAR(200) NOT NULL,
    phone VARCHAR(30),
    UNIQUE KEY uq_dim_customer_natural (email, name, phone)
) ENGINE=InnoDB;

CREATE TABLE dim_shipping (
    shipping_id INT AUTO_INCREMENT PRIMARY KEY,
    address VARCHAR(255),
    UNIQUE KEY uq_dim_shipping_natural (address)
) ENGINE=InnoDB;

CREATE TABLE dim_billing (
    billing_id INT AUTO_INCREMENT PRIMARY KEY,
    address VARCHAR(255),
    UNIQUE KEY uq_dim_billing_natural (address)
) ENGINE=InnoDB;

CREATE TABLE dim_product (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    sku VARCHAR(50) NOT NULL,
    name VARCHAR(200) NOT NULL,
    category VARCHAR(100),
    brand VARCHAR(100),
    UNIQUE KEY uq_dim_product_natural (sku, name, category, brand)
) ENGINE=InnoDB;

CREATE TABLE dim_payment (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    method VARCHAR(30),
    status VARCHAR(30),
    UNIQUE KEY uq_dim_payment_natural (method, status)
) ENGINE=InnoDB;

CREATE TABLE fact_order_stream (
    fact_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT,
    customer_id INT,
    shipping_id INT,
    billing_id INT,
    product_id INT,
    payment_id INT,
    source_row_id INT,
    UNIQUE KEY uq_fact_order_stream_source (source_row_id),
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
CREATE INDEX idx_fact_order_stream_order ON fact_order_stream (order_id);
CREATE INDEX idx_fact_order_stream_customer ON fact_order_stream (customer_id);
CREATE INDEX idx_fact_order_stream_shipping ON fact_order_stream (shipping_id);
CREATE INDEX idx_fact_order_stream_billing ON fact_order_stream (billing_id);
CREATE INDEX idx_fact_order_stream_product ON fact_order_stream (product_id);
CREATE INDEX idx_fact_order_stream_payment ON fact_order_stream (payment_id);
CREATE INDEX idx_fact_order_stream_source ON fact_order_stream (source_row_id);
