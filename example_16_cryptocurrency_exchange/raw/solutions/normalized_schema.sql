-- Normalized schema generated from raw denormalized table
USE cryptocurrency_exchange;

DROP TABLE IF EXISTS fact_exchange_feed;
DROP TABLE IF EXISTS dim_user;
DROP TABLE IF EXISTS dim_asset;
DROP TABLE IF EXISTS dim_wallet;
DROP TABLE IF EXISTS dim_order;
DROP TABLE IF EXISTS dim_trade;

CREATE TABLE dim_user (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE dim_asset (
    asset_id INT AUTO_INCREMENT PRIMARY KEY,
    symbol VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE dim_wallet (
    wallet_id INT AUTO_INCREMENT PRIMARY KEY,
    balance VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE dim_order (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    id VARCHAR(255),
    status VARCHAR(255),
    time VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE dim_trade (
    trade_id INT AUTO_INCREMENT PRIMARY KEY,
    price VARCHAR(255),
    qty VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE fact_exchange_feed (
    fact_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    asset_id INT,
    wallet_id INT,
    order_id INT,
    trade_id INT
) ENGINE=InnoDB;

ALTER TABLE fact_exchange_feed
    ADD CONSTRAINT fk_fact_exchange_feed_user FOREIGN KEY (user_id)
    REFERENCES dim_user (user_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE fact_exchange_feed
    ADD CONSTRAINT fk_fact_exchange_feed_asset FOREIGN KEY (asset_id)
    REFERENCES dim_asset (asset_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE fact_exchange_feed
    ADD CONSTRAINT fk_fact_exchange_feed_wallet FOREIGN KEY (wallet_id)
    REFERENCES dim_wallet (wallet_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE fact_exchange_feed
    ADD CONSTRAINT fk_fact_exchange_feed_order FOREIGN KEY (order_id)
    REFERENCES dim_order (order_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE fact_exchange_feed
    ADD CONSTRAINT fk_fact_exchange_feed_trade FOREIGN KEY (trade_id)
    REFERENCES dim_trade (trade_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
