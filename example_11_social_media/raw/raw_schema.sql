-- Raw denormalized table for normalization exercises
USE social_media;

DROP TABLE IF EXISTS raw_social_events;

CREATE TABLE raw_social_events (
    row_id INT AUTO_INCREMENT PRIMARY KEY,
    user_handle VARCHAR(255),
    event_time VARCHAR(255),
    event_type VARCHAR(255),
    target_handle VARCHAR(255),
    post_text VARCHAR(255),
    like_count VARCHAR(255),
    comment_count VARCHAR(255),
    device_type VARCHAR(255)
) ENGINE=InnoDB;
