-- Raw denormalized table for normalization exercises
USE streaming_ml;

DROP TABLE IF EXISTS raw_event_stream;

CREATE TABLE raw_event_stream (
    row_id INT AUTO_INCREMENT PRIMARY KEY,
    org_name VARCHAR(255),
    project_name VARCHAR(255),
    stream_name VARCHAR(255),
    event_time VARCHAR(255),
    event_type VARCHAR(255),
    feature_key VARCHAR(255),
    feature_value VARCHAR(255),
    model_name VARCHAR(255),
    prediction VARCHAR(255)
) ENGINE=InnoDB;
