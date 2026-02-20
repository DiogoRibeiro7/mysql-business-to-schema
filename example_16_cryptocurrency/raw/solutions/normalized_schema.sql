-- Normalized schema generated from raw denormalized table
USE cryptocurrency;

DROP TABLE IF EXISTS fact_trade_feed;
DROP TABLE IF EXISTS dim_trade;
DROP TABLE IF EXISTS dim_order;

CREATE TABLE dim_trade (
    trade_id INT AUTO_INCREMENT PRIMARY KEY,
    time VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE dim_order (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    type VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE fact_trade_feed (
    fact_id INT AUTO_INCREMENT PRIMARY KEY,
    trade_id INT,
    order_id INT,
    pair_symbol VARCHAR(255),
    side VARCHAR(255),
    price VARCHAR(255),
    quantity VARCHAR(255),
    trader_email VARCHAR(255),
    fee_amount VARCHAR(255)
) ENGINE=InnoDB;

ALTER TABLE fact_trade_feed
    ADD CONSTRAINT fk_fact_trade_feed_trade FOREIGN KEY (trade_id)
    REFERENCES dim_trade (trade_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE fact_trade_feed
    ADD CONSTRAINT fk_fact_trade_feed_order FOREIGN KEY (order_id)
    REFERENCES dim_order (order_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
