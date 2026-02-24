-- Normalized schema generated from raw denormalized table
USE smart_energy;

DROP TABLE IF EXISTS fact_energy_feed;
DROP TABLE IF EXISTS dim_meter;

CREATE TABLE dim_meter (
    meter_id INT AUTO_INCREMENT PRIMARY KEY,
    id VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_dim_meter_natural (id),
    INDEX idx_dim_meter_natural (id)
) ENGINE=InnoDB;

CREATE TABLE fact_energy_feed (
    fact_id INT AUTO_INCREMENT PRIMARY KEY,
    meter_id INT,
    source_row_id INT,
    UNIQUE KEY uq_fact_energy_feed_source (source_row_id),
    utility_name VARCHAR(255),
    building_name VARCHAR(255),
    reading_time VARCHAR(255),
    kwh VARCHAR(255),
    kw_demand VARCHAR(255),
    rate_plan VARCHAR(255),
    solar_kw VARCHAR(255),
    outage_flag VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

ALTER TABLE fact_energy_feed
    ADD CONSTRAINT fk_fact_energy_feed_meter FOREIGN KEY (meter_id)
    REFERENCES dim_meter (meter_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;
CREATE INDEX idx_fact_energy_feed_meter ON fact_energy_feed (meter_id);
CREATE INDEX idx_fact_energy_feed_source ON fact_energy_feed (source_row_id);
