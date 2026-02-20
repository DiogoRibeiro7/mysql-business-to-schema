-- Raw denormalized table for normalization exercises
USE fleet_management;

DROP TABLE IF EXISTS raw_trip_feed;

CREATE TABLE raw_trip_feed (
    row_id INT AUTO_INCREMENT PRIMARY KEY,
    vehicle_number VARCHAR(255),
    driver_name VARCHAR(255),
    gps_time VARCHAR(255),
    latitude VARCHAR(255),
    longitude VARCHAR(255),
    speed_mph VARCHAR(255),
    trip_status VARCHAR(255),
    fuel_level VARCHAR(255),
    depot_name VARCHAR(255)
) ENGINE=InnoDB;
