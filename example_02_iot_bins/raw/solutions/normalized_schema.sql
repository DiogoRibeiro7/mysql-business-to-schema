-- Normalized schema generated from raw denormalized table
USE iot_bins;

DROP TABLE IF EXISTS fact_iot_bins;
DROP TABLE IF EXISTS dim_device;
DROP TABLE IF EXISTS dim_bin;
DROP TABLE IF EXISTS dim_sensor;

CREATE TABLE dim_device (
    device_id INT AUTO_INCREMENT PRIMARY KEY,
    id VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_dim_device_natural (id),
    INDEX idx_dim_device_natural (id)
) ENGINE=InnoDB;

CREATE TABLE dim_bin (
    bin_id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(255),
    type VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_dim_bin_natural (code, type),
    INDEX idx_dim_bin_natural (code, type)
) ENGINE=InnoDB;

CREATE TABLE dim_sensor (
    sensor_id INT AUTO_INCREMENT PRIMARY KEY,
    type VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_dim_sensor_natural (type),
    INDEX idx_dim_sensor_natural (type)
) ENGINE=InnoDB;

CREATE TABLE fact_iot_bins (
    fact_id INT AUTO_INCREMENT PRIMARY KEY,
    device_id INT,
    bin_id INT,
    sensor_id INT,
    source_row_id INT,
    UNIQUE KEY uq_fact_iot_bins_source (source_row_id),
    district_name VARCHAR(255),
    installed_at VARCHAR(255),
    reading_time VARCHAR(255),
    reading_value VARCHAR(255),
    reading_unit VARCHAR(255),
    battery_level VARCHAR(255),
    gps_lat VARCHAR(255),
    gps_lon VARCHAR(255),
    alert_type ENUM('fill_critical', 'odor_high'),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

ALTER TABLE fact_iot_bins
    ADD CONSTRAINT fk_fact_iot_bins_device FOREIGN KEY (device_id)
    REFERENCES dim_device (device_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE fact_iot_bins
    ADD CONSTRAINT fk_fact_iot_bins_bin FOREIGN KEY (bin_id)
    REFERENCES dim_bin (bin_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE fact_iot_bins
    ADD CONSTRAINT fk_fact_iot_bins_sensor FOREIGN KEY (sensor_id)
    REFERENCES dim_sensor (sensor_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;
CREATE INDEX idx_fact_iot_bins_device ON fact_iot_bins (device_id);
CREATE INDEX idx_fact_iot_bins_bin ON fact_iot_bins (bin_id);
CREATE INDEX idx_fact_iot_bins_sensor ON fact_iot_bins (sensor_id);
CREATE INDEX idx_fact_iot_bins_source ON fact_iot_bins (source_row_id);
