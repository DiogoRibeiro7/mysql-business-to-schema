-- Normalized schema generated from raw denormalized table
USE streaming_ml;

DROP TABLE IF EXISTS fact_event_stream;
DROP TABLE IF EXISTS dim_stream;
DROP TABLE IF EXISTS dim_event;
DROP TABLE IF EXISTS dim_feature;
DROP TABLE IF EXISTS dim_model;

CREATE TABLE dim_stream (
    stream_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255),
    UNIQUE KEY uq_dim_stream_natural (name)
) ENGINE=InnoDB;

CREATE TABLE dim_event (
    event_id INT AUTO_INCREMENT PRIMARY KEY,
    time VARCHAR(255),
    type VARCHAR(255),
    UNIQUE KEY uq_dim_event_natural (time, type)
) ENGINE=InnoDB;

CREATE TABLE dim_feature (
    feature_id INT AUTO_INCREMENT PRIMARY KEY,
    key VARCHAR(255),
    value VARCHAR(255),
    UNIQUE KEY uq_dim_feature_natural (key, value)
) ENGINE=InnoDB;

CREATE TABLE dim_model (
    model_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255),
    UNIQUE KEY uq_dim_model_natural (name)
) ENGINE=InnoDB;

CREATE TABLE fact_event_stream (
    fact_id INT AUTO_INCREMENT PRIMARY KEY,
    stream_id INT,
    event_id INT,
    feature_id INT,
    model_id INT,
    source_row_id INT,
    UNIQUE KEY uq_fact_event_stream_source (source_row_id),
    org_name VARCHAR(255),
    project_name VARCHAR(255),
    prediction VARCHAR(255)
) ENGINE=InnoDB;

ALTER TABLE fact_event_stream
    ADD CONSTRAINT fk_fact_event_stream_stream FOREIGN KEY (stream_id)
    REFERENCES dim_stream (stream_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE fact_event_stream
    ADD CONSTRAINT fk_fact_event_stream_event FOREIGN KEY (event_id)
    REFERENCES dim_event (event_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE fact_event_stream
    ADD CONSTRAINT fk_fact_event_stream_feature FOREIGN KEY (feature_id)
    REFERENCES dim_feature (feature_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE fact_event_stream
    ADD CONSTRAINT fk_fact_event_stream_model FOREIGN KEY (model_id)
    REFERENCES dim_model (model_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
CREATE INDEX idx_fact_event_stream_stream ON fact_event_stream (stream_id);
CREATE INDEX idx_fact_event_stream_event ON fact_event_stream (event_id);
CREATE INDEX idx_fact_event_stream_feature ON fact_event_stream (feature_id);
CREATE INDEX idx_fact_event_stream_model ON fact_event_stream (model_id);
CREATE INDEX idx_fact_event_stream_source ON fact_event_stream (source_row_id);
