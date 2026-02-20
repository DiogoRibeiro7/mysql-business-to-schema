-- Normalized schema generated from raw denormalized table
USE smart_energy;

DROP TABLE IF EXISTS fact_energy_feed;
DROP TABLE IF EXISTS dim_meter;

CREATE TABLE dim_meter (
    meter_id INT AUTO_INCREMENT PRIMARY KEY,
    id VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE fact_energy_feed (
    fact_id INT AUTO_INCREMENT PRIMARY KEY,
    meter_id INT,
    utility_name VARCHAR(255),
    building_name VARCHAR(255),
    reading_time VARCHAR(255),
    kwh VARCHAR(255),
    kw_demand VARCHAR(255),
    rate_plan VARCHAR(255),
    solar_kw VARCHAR(255),
    outage_flag VARCHAR(255)
) ENGINE=InnoDB;

ALTER TABLE fact_energy_feed
    ADD CONSTRAINT fk_fact_energy_feed_meter FOREIGN KEY (meter_id)
    REFERENCES dim_meter (meter_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
