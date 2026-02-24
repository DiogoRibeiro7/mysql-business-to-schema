-- Normalized schema generated from raw denormalized table
USE fintech;

DROP TABLE IF EXISTS fact_transaction_feed;
DROP TABLE IF EXISTS dim_customer;
DROP TABLE IF EXISTS dim_account;
DROP TABLE IF EXISTS dim_transaction;
DROP TABLE IF EXISTS dim_merchant;
DROP TABLE IF EXISTS dim_device;

CREATE TABLE dim_customer (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    name VARCHAR(200) NOT NULL,
    type VARCHAR(20) NOT NULL,
    UNIQUE KEY uq_dim_customer_natural (email, name, type)
) ENGINE=InnoDB;

CREATE TABLE dim_account (
    account_id INT AUTO_INCREMENT PRIMARY KEY,
    number VARCHAR(30) NOT NULL,
    type VARCHAR(20) NOT NULL,
    UNIQUE KEY uq_dim_account_natural (number, type)
) ENGINE=InnoDB;

CREATE TABLE dim_transaction (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    id VARCHAR(50) NOT NULL,
    type VARCHAR(30) NOT NULL,
    date DATETIME NOT NULL,
    UNIQUE KEY uq_dim_transaction_natural (id, type, date)
) ENGINE=InnoDB;

CREATE TABLE dim_merchant (
    merchant_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(200),
    category VARCHAR(100),
    UNIQUE KEY uq_dim_merchant_natural (name, category)
) ENGINE=InnoDB;

CREATE TABLE dim_device (
    device_id INT AUTO_INCREMENT PRIMARY KEY,
    fingerprint VARCHAR(100),
    UNIQUE KEY uq_dim_device_natural (fingerprint)
) ENGINE=InnoDB;

CREATE TABLE fact_transaction_feed (
    fact_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT,
    account_id INT,
    transaction_id INT,
    merchant_id INT,
    device_id INT,
    source_row_id INT,
    UNIQUE KEY uq_fact_transaction_feed_source (source_row_id),
    currency CHAR(3) NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    risk_score INT,
    kyc_status VARCHAR(20)
) ENGINE=InnoDB;

ALTER TABLE fact_transaction_feed
    ADD CONSTRAINT fk_fact_transaction_feed_customer FOREIGN KEY (customer_id)
    REFERENCES dim_customer (customer_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE fact_transaction_feed
    ADD CONSTRAINT fk_fact_transaction_feed_account FOREIGN KEY (account_id)
    REFERENCES dim_account (account_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE fact_transaction_feed
    ADD CONSTRAINT fk_fact_transaction_feed_transaction FOREIGN KEY (transaction_id)
    REFERENCES dim_transaction (transaction_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE fact_transaction_feed
    ADD CONSTRAINT fk_fact_transaction_feed_merchant FOREIGN KEY (merchant_id)
    REFERENCES dim_merchant (merchant_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE fact_transaction_feed
    ADD CONSTRAINT fk_fact_transaction_feed_device FOREIGN KEY (device_id)
    REFERENCES dim_device (device_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
CREATE INDEX idx_fact_transaction_feed_customer ON fact_transaction_feed (customer_id);
CREATE INDEX idx_fact_transaction_feed_account ON fact_transaction_feed (account_id);
CREATE INDEX idx_fact_transaction_feed_transaction ON fact_transaction_feed (transaction_id);
CREATE INDEX idx_fact_transaction_feed_merchant ON fact_transaction_feed (merchant_id);
CREATE INDEX idx_fact_transaction_feed_device ON fact_transaction_feed (device_id);
CREATE INDEX idx_fact_transaction_feed_source ON fact_transaction_feed (source_row_id);
