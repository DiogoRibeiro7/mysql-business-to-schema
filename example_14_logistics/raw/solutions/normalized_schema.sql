-- Normalized schema generated from raw denormalized table
USE logistics;

DROP TABLE IF EXISTS fact_shipment_feed;
DROP TABLE IF EXISTS dim_shipment;
DROP TABLE IF EXISTS dim_delivery;

CREATE TABLE dim_shipment (
    shipment_id INT AUTO_INCREMENT PRIMARY KEY,
    number VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE dim_delivery (
    delivery_id INT AUTO_INCREMENT PRIMARY KEY,
    date VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE fact_shipment_feed (
    fact_id INT AUTO_INCREMENT PRIMARY KEY,
    shipment_id INT,
    delivery_id INT,
    origin_warehouse VARCHAR(255),
    destination_city VARCHAR(255),
    carrier_name VARCHAR(255),
    ship_date VARCHAR(255),
    status VARCHAR(255),
    total_weight_kg VARCHAR(255)
) ENGINE=InnoDB;

ALTER TABLE fact_shipment_feed
    ADD CONSTRAINT fk_fact_shipment_feed_shipment FOREIGN KEY (shipment_id)
    REFERENCES dim_shipment (shipment_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE fact_shipment_feed
    ADD CONSTRAINT fk_fact_shipment_feed_delivery FOREIGN KEY (delivery_id)
    REFERENCES dim_delivery (delivery_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
