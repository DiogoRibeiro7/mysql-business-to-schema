-- Normalized schema generated from raw denormalized table
USE smart_agriculture;

DROP TABLE IF EXISTS fact_farm_telemetry;
DROP TABLE IF EXISTS dim_sensor;

CREATE TABLE dim_sensor (
    sensor_id INT AUTO_INCREMENT PRIMARY KEY,
    type VARCHAR(255),
    UNIQUE KEY uq_dim_sensor_natural (type)
) ENGINE=InnoDB;

CREATE TABLE fact_farm_telemetry (
    fact_id INT AUTO_INCREMENT PRIMARY KEY,
    sensor_id INT,
    source_row_id INT,
    UNIQUE KEY uq_fact_farm_telemetry_source (source_row_id),
    farm_name VARCHAR(255),
    field_name VARCHAR(255),
    zone_code VARCHAR(255),
    reading_time VARCHAR(255),
    reading_value VARCHAR(255),
    unit VARCHAR(255),
    crop_type VARCHAR(255),
    irrigation_event VARCHAR(255)
) ENGINE=InnoDB;

ALTER TABLE fact_farm_telemetry
    ADD CONSTRAINT fk_fact_farm_telemetry_sensor FOREIGN KEY (sensor_id)
    REFERENCES dim_sensor (sensor_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
CREATE INDEX idx_fact_farm_telemetry_sensor ON fact_farm_telemetry (sensor_id);
CREATE INDEX idx_fact_farm_telemetry_source ON fact_farm_telemetry (source_row_id);
