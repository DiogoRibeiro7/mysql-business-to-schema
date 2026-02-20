-- Raw denormalized table for normalization exercises
USE smart_energy;

DROP TABLE IF EXISTS raw_energy_feed;

CREATE TABLE raw_energy_feed (
    row_id INT AUTO_INCREMENT PRIMARY KEY,
    utility_name VARCHAR(255),
    building_name VARCHAR(255),
    meter_id VARCHAR(255),
    reading_time VARCHAR(255),
    kwh VARCHAR(255),
    kw_demand VARCHAR(255),
    rate_plan VARCHAR(255),
    solar_kw VARCHAR(255),
    outage_flag VARCHAR(255)
) ENGINE=InnoDB;
