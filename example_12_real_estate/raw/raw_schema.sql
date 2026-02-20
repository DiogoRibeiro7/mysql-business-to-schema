-- Raw denormalized table for normalization exercises
USE real_estate;

DROP TABLE IF EXISTS raw_property_feed;

CREATE TABLE raw_property_feed (
    row_id INT AUTO_INCREMENT PRIMARY KEY,
    listing_id VARCHAR(255),
    address VARCHAR(255),
    city VARCHAR(255),
    state VARCHAR(255),
    price VARCHAR(255),
    beds VARCHAR(255),
    baths VARCHAR(255),
    agent_name VARCHAR(255),
    agency_name VARCHAR(255),
    listing_status VARCHAR(255)
) ENGINE=InnoDB;
