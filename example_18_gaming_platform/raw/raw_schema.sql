-- Raw denormalized table for normalization exercises
USE gaming_platform;

DROP TABLE IF EXISTS raw_match_events;

CREATE TABLE raw_match_events (
    row_id INT AUTO_INCREMENT PRIMARY KEY,
    player_handle VARCHAR(255),
    game_title VARCHAR(255),
    match_time VARCHAR(255),
    score VARCHAR(255),
    kills VARCHAR(255),
    deaths VARCHAR(255),
    server_region VARCHAR(255),
    match_result VARCHAR(255)
) ENGINE=InnoDB;
