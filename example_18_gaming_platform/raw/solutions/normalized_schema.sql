-- Normalized schema generated from raw denormalized table
USE gaming_platform;

DROP TABLE IF EXISTS fact_match_events;
DROP TABLE IF EXISTS dim_player;
DROP TABLE IF EXISTS dim_game;
DROP TABLE IF EXISTS dim_match;

CREATE TABLE dim_player (
    player_id INT AUTO_INCREMENT PRIMARY KEY,
    handle VARCHAR(255),
    UNIQUE KEY uq_dim_player_natural (handle)
) ENGINE=InnoDB;

CREATE TABLE dim_game (
    game_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255),
    UNIQUE KEY uq_dim_game_natural (title)
) ENGINE=InnoDB;

CREATE TABLE dim_match (
    match_id INT AUTO_INCREMENT PRIMARY KEY,
    time VARCHAR(255),
    result VARCHAR(255),
    UNIQUE KEY uq_dim_match_natural (time, result)
) ENGINE=InnoDB;

CREATE TABLE fact_match_events (
    fact_id INT AUTO_INCREMENT PRIMARY KEY,
    player_id INT,
    game_id INT,
    match_id INT,
    source_row_id INT,
    UNIQUE KEY uq_fact_match_events_source (source_row_id),
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
CREATE INDEX idx_fact_match_events_player ON fact_match_events (player_id);
CREATE INDEX idx_fact_match_events_game ON fact_match_events (game_id);
CREATE INDEX idx_fact_match_events_match ON fact_match_events (match_id);
CREATE INDEX idx_fact_match_events_source ON fact_match_events (source_row_id);
