-- Normalized schema generated from raw denormalized table
USE logistics;

DROP TABLE IF EXISTS fact_shipment_feed;
DROP TABLE IF EXISTS dim_shipment;
DROP TABLE IF EXISTS dim_delivery;

CREATE TABLE dim_shipment (
    shipment_id INT AUTO_INCREMENT PRIMARY KEY,
    number VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_dim_shipment_natural (number),
    INDEX idx_dim_shipment_natural (number)
) ENGINE=InnoDB;

CREATE TABLE dim_delivery (
    delivery_id INT AUTO_INCREMENT PRIMARY KEY,
    date VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_dim_delivery_natural (date),
    INDEX idx_dim_delivery_natural (date)
) ENGINE=InnoDB;

CREATE TABLE fact_shipment_feed (
    fact_id INT AUTO_INCREMENT PRIMARY KEY,
    shipment_id INT,
    delivery_id INT,
    source_row_id INT,
    UNIQUE KEY uq_fact_shipment_feed_source (source_row_id),
    origin_warehouse VARCHAR(255),
    destination_city VARCHAR(255),
    carrier_name VARCHAR(255),
    ship_date VARCHAR(255),
    status ENUM('delivered', 'in_transit'),
    total_weight_kg VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

ALTER TABLE fact_shipment_feed
    ADD CONSTRAINT fk_fact_shipment_feed_shipment FOREIGN KEY (shipment_id)
    REFERENCES dim_shipment (shipment_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE fact_shipment_feed
    ADD CONSTRAINT fk_fact_shipment_feed_delivery FOREIGN KEY (delivery_id)
    REFERENCES dim_delivery (delivery_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;
CREATE INDEX idx_fact_shipment_feed_shipment ON fact_shipment_feed (shipment_id);
CREATE INDEX idx_fact_shipment_feed_delivery ON fact_shipment_feed (delivery_id);
CREATE INDEX idx_fact_shipment_feed_source ON fact_shipment_feed (source_row_id);
