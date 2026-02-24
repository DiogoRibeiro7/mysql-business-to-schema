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
    email VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_dim_user_natural (email),
    INDEX idx_dim_user_natural (email)
) ENGINE=InnoDB;

CREATE TABLE dim_asset (
    asset_id INT AUTO_INCREMENT PRIMARY KEY,
    symbol VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_dim_asset_natural (symbol),
    INDEX idx_dim_asset_natural (symbol)
) ENGINE=InnoDB;

CREATE TABLE dim_wallet (
    wallet_id INT AUTO_INCREMENT PRIMARY KEY,
    balance VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_dim_wallet_natural (balance),
    INDEX idx_dim_wallet_natural (balance)
) ENGINE=InnoDB;

CREATE TABLE dim_order (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    id VARCHAR(255),
    status VARCHAR(255),
    time VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_dim_order_natural (id, status, time),
    INDEX idx_dim_order_natural (id, status, time)
) ENGINE=InnoDB;

CREATE TABLE dim_trade (
    trade_id INT AUTO_INCREMENT PRIMARY KEY,
    price VARCHAR(255),
    qty VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_dim_trade_natural (price, qty),
    INDEX idx_dim_trade_natural (price, qty)
) ENGINE=InnoDB;

CREATE TABLE fact_exchange_feed (
    fact_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    asset_id INT,
    wallet_id INT,
    order_id INT,
    trade_id INT,
    source_row_id INT,
    UNIQUE KEY uq_fact_exchange_feed_source (source_row_id),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

ALTER TABLE fact_exchange_feed
    ADD CONSTRAINT fk_fact_exchange_feed_user FOREIGN KEY (user_id)
    REFERENCES dim_user (user_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE fact_exchange_feed
    ADD CONSTRAINT fk_fact_exchange_feed_asset FOREIGN KEY (asset_id)
    REFERENCES dim_asset (asset_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE fact_exchange_feed
    ADD CONSTRAINT fk_fact_exchange_feed_wallet FOREIGN KEY (wallet_id)
    REFERENCES dim_wallet (wallet_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE fact_exchange_feed
    ADD CONSTRAINT fk_fact_exchange_feed_order FOREIGN KEY (order_id)
    REFERENCES dim_order (order_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE fact_exchange_feed
    ADD CONSTRAINT fk_fact_exchange_feed_trade FOREIGN KEY (trade_id)
    REFERENCES dim_trade (trade_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;
CREATE INDEX idx_fact_exchange_feed_user ON fact_exchange_feed (user_id);
CREATE INDEX idx_fact_exchange_feed_asset ON fact_exchange_feed (asset_id);
CREATE INDEX idx_fact_exchange_feed_wallet ON fact_exchange_feed (wallet_id);
CREATE INDEX idx_fact_exchange_feed_order ON fact_exchange_feed (order_id);
CREATE INDEX idx_fact_exchange_feed_trade ON fact_exchange_feed (trade_id);
CREATE INDEX idx_fact_exchange_feed_source ON fact_exchange_feed (source_row_id);
