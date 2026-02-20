-- Raw denormalized table for normalization exercises
USE logistics;

DROP TABLE IF EXISTS raw_shipment_feed;

CREATE TABLE raw_shipment_feed (
    row_id INT AUTO_INCREMENT PRIMARY KEY,
    shipment_number VARCHAR(255),
    origin_warehouse VARCHAR(255),
    destination_city VARCHAR(255),
    carrier_name VARCHAR(255),
    ship_date VARCHAR(255),
    delivery_date VARCHAR(255),
    status VARCHAR(255),
    total_weight_kg VARCHAR(255)
) ENGINE=InnoDB;
