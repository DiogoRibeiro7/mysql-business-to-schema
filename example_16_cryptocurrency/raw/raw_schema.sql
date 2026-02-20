-- Raw denormalized table for normalization exercises
USE cryptocurrency;

DROP TABLE IF EXISTS raw_trade_feed;

CREATE TABLE raw_trade_feed (
    row_id INT AUTO_INCREMENT PRIMARY KEY,
    pair_symbol VARCHAR(255),
    trade_time VARCHAR(255),
    side VARCHAR(255),
    price VARCHAR(255),
    quantity VARCHAR(255),
    trader_email VARCHAR(255),
    fee_amount VARCHAR(255),
    order_type VARCHAR(255)
) ENGINE=InnoDB;
