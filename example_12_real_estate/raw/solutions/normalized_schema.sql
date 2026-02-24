-- Normalized schema generated from raw denormalized table
USE real_estate;

DROP TABLE IF EXISTS fact_property_feed;
DROP TABLE IF EXISTS dim_listing;
DROP TABLE IF EXISTS dim_agent;

CREATE TABLE dim_listing (
    listing_id INT AUTO_INCREMENT PRIMARY KEY,
    id VARCHAR(255),
    status VARCHAR(255),
    UNIQUE KEY uq_dim_listing_natural (id, status)
) ENGINE=InnoDB;

CREATE TABLE dim_agent (
    agent_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255),
    UNIQUE KEY uq_dim_agent_natural (name)
) ENGINE=InnoDB;

CREATE TABLE fact_property_feed (
    fact_id INT AUTO_INCREMENT PRIMARY KEY,
    listing_id INT,
    agent_id INT,
    source_row_id INT,
    UNIQUE KEY uq_fact_property_feed_source (source_row_id),
    address VARCHAR(255),
    city VARCHAR(255),
    state VARCHAR(255),
    price VARCHAR(255),
    beds VARCHAR(255),
    baths VARCHAR(255),
    agency_name VARCHAR(255)
) ENGINE=InnoDB;

ALTER TABLE fact_property_feed
    ADD CONSTRAINT fk_fact_property_feed_listing FOREIGN KEY (listing_id)
    REFERENCES dim_listing (listing_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE fact_property_feed
    ADD CONSTRAINT fk_fact_property_feed_agent FOREIGN KEY (agent_id)
    REFERENCES dim_agent (agent_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
CREATE INDEX idx_fact_property_feed_listing ON fact_property_feed (listing_id);
CREATE INDEX idx_fact_property_feed_agent ON fact_property_feed (agent_id);
CREATE INDEX idx_fact_property_feed_source ON fact_property_feed (source_row_id);
