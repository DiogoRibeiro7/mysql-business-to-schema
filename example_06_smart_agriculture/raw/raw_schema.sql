-- Raw denormalized table for normalization exercises
USE smart_agriculture;

DROP TABLE IF EXISTS raw_farm_telemetry;

CREATE TABLE raw_farm_telemetry (
    row_id INT AUTO_INCREMENT PRIMARY KEY,
    farm_name VARCHAR(255),
    field_name VARCHAR(255),
    zone_code VARCHAR(255),
    sensor_type VARCHAR(255),
    reading_time VARCHAR(255),
    reading_value VARCHAR(255),
    unit VARCHAR(255),
    crop_type VARCHAR(255),
    irrigation_event VARCHAR(255)
) ENGINE=InnoDB;
