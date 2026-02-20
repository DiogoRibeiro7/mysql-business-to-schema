-- Raw denormalized table for normalization exercises
USE cryptocurrency_exchange;

DROP TABLE IF EXISTS raw_exchange_feed;

CREATE TABLE raw_exchange_feed (
    row_id INT AUTO_INCREMENT PRIMARY KEY,
    user_email VARCHAR(255),
    asset_symbol VARCHAR(255),
    wallet_balance VARCHAR(255),
    order_id VARCHAR(255),
    order_status VARCHAR(255),
    order_time VARCHAR(255),
    trade_price VARCHAR(255),
    trade_qty VARCHAR(255)
) ENGINE=InnoDB;
