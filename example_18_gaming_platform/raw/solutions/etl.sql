-- ETL from raw denormalized table into normalized tables
USE gaming_platform;

INSERT INTO dim_player (handle, created_at, updated_at)
SELECT DISTINCT r.player_handle, NOW(), NOW()
FROM raw_match_events r;

INSERT INTO dim_game (title, created_at, updated_at)
SELECT DISTINCT r.game_title, NOW(), NOW()
FROM raw_match_events r;

INSERT INTO dim_match (time, result, created_at, updated_at)
SELECT DISTINCT r.match_time, r.match_result, NOW(), NOW()
FROM raw_match_events r;

INSERT INTO fact_match_events (player_id, game_id, match_id, source_row_id, score, kills, deaths, server_region, created_at, updated_at)
SELECT
    d_player.player_id,
    d_game.game_id,
    d_match.match_id,
    r.row_id,
    r.score,
    r.kills,
    r.deaths,
    r.server_region,
    NOW(),
    NOW()
FROM raw_match_events r
LEFT JOIN dim_player d_player ON r.player_handle <=> d_player.handle
LEFT JOIN dim_game d_game ON r.game_title <=> d_game.title
LEFT JOIN dim_match d_match ON r.match_time <=> d_match.time AND r.match_result <=> d_match.result
;
