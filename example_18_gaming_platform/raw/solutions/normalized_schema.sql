-- Normalized schema generated from raw denormalized table
USE gaming_platform;

DROP TABLE IF EXISTS fact_match_events;
DROP TABLE IF EXISTS dim_player;
DROP TABLE IF EXISTS dim_game;
DROP TABLE IF EXISTS dim_match;

CREATE TABLE dim_player (
    player_id INT AUTO_INCREMENT PRIMARY KEY,
    handle VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE dim_game (
    game_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE dim_match (
    match_id INT AUTO_INCREMENT PRIMARY KEY,
    time VARCHAR(255),
    result VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE fact_match_events (
    fact_id INT AUTO_INCREMENT PRIMARY KEY,
    player_id INT,
    game_id INT,
    match_id INT,
    score VARCHAR(255),
    kills VARCHAR(255),
    deaths VARCHAR(255),
    server_region VARCHAR(255)
) ENGINE=InnoDB;

ALTER TABLE fact_match_events
    ADD CONSTRAINT fk_fact_match_events_player FOREIGN KEY (player_id)
    REFERENCES dim_player (player_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE fact_match_events
    ADD CONSTRAINT fk_fact_match_events_game FOREIGN KEY (game_id)
    REFERENCES dim_game (game_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE fact_match_events
    ADD CONSTRAINT fk_fact_match_events_match FOREIGN KEY (match_id)
    REFERENCES dim_match (match_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
