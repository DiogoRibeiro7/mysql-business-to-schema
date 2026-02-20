-- Raw denormalized transaction feed for normalization exercises
USE fintech;

DROP TABLE IF EXISTS raw_transaction_feed;

CREATE TABLE raw_transaction_feed (
    row_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_email VARCHAR(255) NOT NULL,
    customer_name VARCHAR(200) NOT NULL,
    customer_type VARCHAR(20) NOT NULL,
    account_number VARCHAR(30) NOT NULL,
    account_type VARCHAR(20) NOT NULL,
    currency CHAR(3) NOT NULL,
    transaction_id VARCHAR(50) NOT NULL,
    transaction_type VARCHAR(30) NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    transaction_date DATETIME NOT NULL,
    merchant_name VARCHAR(200),
    merchant_category VARCHAR(100),
    risk_score INT,
    kyc_status VARCHAR(20),
    device_fingerprint VARCHAR(100)
) ENGINE=InnoDB;
