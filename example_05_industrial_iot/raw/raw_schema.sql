-- Raw denormalized table for normalization exercises
USE industrial_iot;

DROP TABLE IF EXISTS raw_machine_feed;

CREATE TABLE raw_machine_feed (
    row_id INT AUTO_INCREMENT PRIMARY KEY,
    factory_name VARCHAR(255),
    line_name VARCHAR(255),
    machine_code VARCHAR(255),
    sensor_type VARCHAR(255),
    reading_time VARCHAR(255),
    reading_value VARCHAR(255),
    unit VARCHAR(255),
    operator_name VARCHAR(255),
    work_order_code VARCHAR(255)
) ENGINE=InnoDB;
