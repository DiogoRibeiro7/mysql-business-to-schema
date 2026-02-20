-- Raw denormalized order stream for normalization exercises
USE ecommerce;

DROP TABLE IF EXISTS raw_order_stream;

CREATE TABLE raw_order_stream (
    row_id INT AUTO_INCREMENT PRIMARY KEY,
    order_number VARCHAR(50) NOT NULL,
    order_date DATETIME NOT NULL,
    customer_email VARCHAR(255) NOT NULL,
    customer_name VARCHAR(200) NOT NULL,
    customer_phone VARCHAR(30),
    shipping_address VARCHAR(255),
    billing_address VARCHAR(255),
    product_sku VARCHAR(50) NOT NULL,
    product_name VARCHAR(200) NOT NULL,
    product_category VARCHAR(100),
    product_brand VARCHAR(100),
    unit_price DECIMAL(10,2) NOT NULL,
    quantity INT NOT NULL,
    item_discount DECIMAL(10,2) DEFAULT 0,
    order_status VARCHAR(30),
    payment_method VARCHAR(30),
    payment_status VARCHAR(30)
) ENGINE=InnoDB;
