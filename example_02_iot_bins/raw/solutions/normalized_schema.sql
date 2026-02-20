-- Normalized schema generated from raw denormalized table
USE iot_bins;

DROP TABLE IF EXISTS fact_iot_bins;
DROP TABLE IF EXISTS dim_device;
DROP TABLE IF EXISTS dim_bin;
DROP TABLE IF EXISTS dim_sensor;

CREATE TABLE dim_device (
    device_id INT AUTO_INCREMENT PRIMARY KEY,
    id VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE dim_bin (
    bin_id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(255),
    type VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE dim_sensor (
    sensor_id INT AUTO_INCREMENT PRIMARY KEY,
    type VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE fact_iot_bins (
    fact_id INT AUTO_INCREMENT PRIMARY KEY,
    device_id INT,
    bin_id INT,
    sensor_id INT,
    district_name VARCHAR(255),
    installed_at VARCHAR(255),
    reading_time VARCHAR(255),
    reading_value VARCHAR(255),
    reading_unit VARCHAR(255),
    battery_level VARCHAR(255),
    gps_lat VARCHAR(255),
    gps_lon VARCHAR(255),
    alert_type VARCHAR(255)
) ENGINE=InnoDB;

ALTER TABLE fact_iot_bins
    ADD CONSTRAINT fk_fact_iot_bins_device FOREIGN KEY (device_id)
    REFERENCES dim_device (device_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE fact_iot_bins
    ADD CONSTRAINT fk_fact_iot_bins_bin FOREIGN KEY (bin_id)
    REFERENCES dim_bin (bin_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE fact_iot_bins
    ADD CONSTRAINT fk_fact_iot_bins_sensor FOREIGN KEY (sensor_id)
    REFERENCES dim_sensor (sensor_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
