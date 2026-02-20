-- Raw denormalized table for normalization exercises
USE iot_bins;

DROP TABLE IF EXISTS raw_iot_bins;

CREATE TABLE raw_iot_bins (
    row_id INT AUTO_INCREMENT PRIMARY KEY,
    device_id VARCHAR(255),
    bin_code VARCHAR(255),
    district_name VARCHAR(255),
    bin_type VARCHAR(255),
    installed_at VARCHAR(255),
    sensor_type VARCHAR(255),
    reading_time VARCHAR(255),
    reading_value VARCHAR(255),
    reading_unit VARCHAR(255),
    battery_level VARCHAR(255),
    gps_lat VARCHAR(255),
    gps_lon VARCHAR(255),
    alert_type VARCHAR(255)
) ENGINE=InnoDB;
