-- Normalized schema generated from raw denormalized table
USE industrial_iot;

DROP TABLE IF EXISTS fact_machine_feed;
DROP TABLE IF EXISTS dim_sensor;

CREATE TABLE dim_sensor (
    sensor_id INT AUTO_INCREMENT PRIMARY KEY,
    type VARCHAR(255),
    UNIQUE KEY uq_dim_sensor_natural (type)
) ENGINE=InnoDB;

CREATE TABLE fact_machine_feed (
    fact_id INT AUTO_INCREMENT PRIMARY KEY,
    sensor_id INT,
    source_row_id INT,
    UNIQUE KEY uq_fact_machine_feed_source (source_row_id),
    factory_name VARCHAR(255),
    line_name VARCHAR(255),
    machine_code VARCHAR(255),
    reading_time VARCHAR(255),
    reading_value VARCHAR(255),
    unit VARCHAR(255),
    operator_name VARCHAR(255),
    work_order_code VARCHAR(255)
) ENGINE=InnoDB;

ALTER TABLE fact_machine_feed
    ADD CONSTRAINT fk_fact_machine_feed_sensor FOREIGN KEY (sensor_id)
    REFERENCES dim_sensor (sensor_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
CREATE INDEX idx_fact_machine_feed_sensor ON fact_machine_feed (sensor_id);
CREATE INDEX idx_fact_machine_feed_source ON fact_machine_feed (source_row_id);
