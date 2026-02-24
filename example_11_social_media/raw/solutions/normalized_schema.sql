-- Normalized schema generated from raw denormalized table
USE social_media;

DROP TABLE IF EXISTS fact_social_events;
DROP TABLE IF EXISTS dim_user;
DROP TABLE IF EXISTS dim_event;
DROP TABLE IF EXISTS dim_post;
DROP TABLE IF EXISTS dim_comment;
DROP TABLE IF EXISTS dim_device;

CREATE TABLE dim_user (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    handle VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_dim_user_natural (handle),
    INDEX idx_dim_user_natural (handle)
) ENGINE=InnoDB;

CREATE TABLE dim_event (
    event_id INT AUTO_INCREMENT PRIMARY KEY,
    time VARCHAR(255),
    type VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_dim_event_natural (time, type),
    INDEX idx_dim_event_natural (time, type)
) ENGINE=InnoDB;

CREATE TABLE dim_post (
    post_id INT AUTO_INCREMENT PRIMARY KEY,
    text VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_dim_post_natural (text),
    INDEX idx_dim_post_natural (text)
) ENGINE=InnoDB;

CREATE TABLE dim_comment (
    comment_id INT AUTO_INCREMENT PRIMARY KEY,
    count VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_dim_comment_natural (count),
    INDEX idx_dim_comment_natural (count)
) ENGINE=InnoDB;

CREATE TABLE dim_device (
    device_id INT AUTO_INCREMENT PRIMARY KEY,
    type VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_dim_device_natural (type),
    INDEX idx_dim_device_natural (type)
) ENGINE=InnoDB;

CREATE TABLE fact_social_events (
    fact_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    event_id INT,
    post_id INT,
    comment_id INT,
    device_id INT,
    source_row_id INT,
    UNIQUE KEY uq_fact_social_events_source (source_row_id),
    target_handle VARCHAR(255),
    like_count VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

ALTER TABLE fact_social_events
    ADD CONSTRAINT fk_fact_social_events_user FOREIGN KEY (user_id)
    REFERENCES dim_user (user_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE fact_social_events
    ADD CONSTRAINT fk_fact_social_events_event FOREIGN KEY (event_id)
    REFERENCES dim_event (event_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE fact_social_events
    ADD CONSTRAINT fk_fact_social_events_post FOREIGN KEY (post_id)
    REFERENCES dim_post (post_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE fact_social_events
    ADD CONSTRAINT fk_fact_social_events_comment FOREIGN KEY (comment_id)
    REFERENCES dim_comment (comment_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE fact_social_events
    ADD CONSTRAINT fk_fact_social_events_device FOREIGN KEY (device_id)
    REFERENCES dim_device (device_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;
CREATE INDEX idx_fact_social_events_user ON fact_social_events (user_id);
CREATE INDEX idx_fact_social_events_event ON fact_social_events (event_id);
CREATE INDEX idx_fact_social_events_post ON fact_social_events (post_id);
CREATE INDEX idx_fact_social_events_comment ON fact_social_events (comment_id);
CREATE INDEX idx_fact_social_events_device ON fact_social_events (device_id);
CREATE INDEX idx_fact_social_events_source ON fact_social_events (source_row_id);
