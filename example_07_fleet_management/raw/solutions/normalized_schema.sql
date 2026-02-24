-- Normalized schema generated from raw denormalized table
USE fleet_management;

DROP TABLE IF EXISTS fact_trip_feed;
DROP TABLE IF EXISTS dim_vehicle;
DROP TABLE IF EXISTS dim_driver;

CREATE TABLE dim_vehicle (
    vehicle_id INT AUTO_INCREMENT PRIMARY KEY,
    number VARCHAR(255),
    UNIQUE KEY uq_dim_vehicle_natural (number)
) ENGINE=InnoDB;

CREATE TABLE dim_driver (
    driver_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255),
    UNIQUE KEY uq_dim_driver_natural (name)
) ENGINE=InnoDB;

CREATE TABLE fact_trip_feed (
    fact_id INT AUTO_INCREMENT PRIMARY KEY,
    vehicle_id INT,
    driver_id INT,
    source_row_id INT,
    UNIQUE KEY uq_fact_trip_feed_source (source_row_id),
    gps_time VARCHAR(255),
    latitude VARCHAR(255),
    longitude VARCHAR(255),
    speed_mph VARCHAR(255),
    trip_status VARCHAR(255),
    fuel_level VARCHAR(255),
    depot_name VARCHAR(255)
) ENGINE=InnoDB;

ALTER TABLE fact_trip_feed
    ADD CONSTRAINT fk_fact_trip_feed_vehicle FOREIGN KEY (vehicle_id)
    REFERENCES dim_vehicle (vehicle_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE fact_trip_feed
    ADD CONSTRAINT fk_fact_trip_feed_driver FOREIGN KEY (driver_id)
    REFERENCES dim_driver (driver_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
CREATE INDEX idx_fact_trip_feed_vehicle ON fact_trip_feed (vehicle_id);
CREATE INDEX idx_fact_trip_feed_driver ON fact_trip_feed (driver_id);
CREATE INDEX idx_fact_trip_feed_source ON fact_trip_feed (source_row_id);
