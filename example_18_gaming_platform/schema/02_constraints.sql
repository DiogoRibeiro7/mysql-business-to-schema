-- ============================================================================
-- CONSTRAINTS FOR GAMING PLATFORM
-- ============================================================================

USE gaming_platform;

-- ============================================================================
-- CHECK CONSTRAINTS
-- ============================================================================

-- Players table
ALTER TABLE players
    ADD CONSTRAINT chk_players_level
    CHECK (player_level > 0 AND prestige_level >= 0),
    ADD CONSTRAINT chk_players_xp
    CHECK (total_xp >= 0),
    ADD CONSTRAINT chk_players_playtime
    CHECK (total_playtime_hours >= 0),
    ADD CONSTRAINT chk_players_stats
    CHECK (games_owned >= 0 AND achievements_earned >= 0 AND tournaments_won >= 0),
    ADD CONSTRAINT chk_players_trust_score
    CHECK (trust_score >= 0 AND trust_score <= 100);

-- Games table
ALTER TABLE games
    ADD CONSTRAINT chk_games_price
    CHECK (base_price >= 0 AND current_price >= 0),
    ADD CONSTRAINT chk_games_discount
    CHECK (discount_percentage >= 0 AND discount_percentage <= 100),
    ADD CONSTRAINT chk_games_players
    CHECK (max_players > 0),
    ADD CONSTRAINT chk_games_stats
    CHECK (total_players >= 0 AND current_online >= 0 AND peak_online >= 0),
    ADD CONSTRAINT chk_games_ratings
    CHECK ((critic_score IS NULL OR (critic_score >= 0 AND critic_score <= 10)) AND
           (user_score IS NULL OR (user_score >= 0 AND user_score <= 10))),
    ADD CONSTRAINT chk_games_reviews
    CHECK (total_reviews >= 0);

-- Player games table
ALTER TABLE player_games
    ADD CONSTRAINT chk_player_games_price
    CHECK (purchase_price IS NULL OR purchase_price >= 0),
    ADD CONSTRAINT chk_player_games_playtime
    CHECK (total_playtime_minutes >= 0),
    ADD CONSTRAINT chk_player_games_launches
    CHECK (times_launched >= 0),
    ADD CONSTRAINT chk_player_games_size
    CHECK (install_size_gb IS NULL OR install_size_gb > 0);

-- Game servers table
ALTER TABLE game_servers
    ADD CONSTRAINT chk_servers_port
    CHECK (port IS NULL OR (port > 0 AND port <= 65535)),
    ADD CONSTRAINT chk_servers_players
    CHECK (max_players > 0 AND current_players >= 0 AND current_players <= max_players),
    ADD CONSTRAINT chk_servers_tick_rate
    CHECK (tick_rate > 0 AND tick_rate <= 128),
    ADD CONSTRAINT chk_servers_ping
    CHECK (average_ping IS NULL OR average_ping >= 0);

-- Match sessions table
ALTER TABLE match_sessions
    ADD CONSTRAINT chk_matches_duration
    CHECK (duration_seconds IS NULL OR duration_seconds > 0),
    ADD CONSTRAINT chk_matches_players
    CHECK (total_players >= 0 AND total_players <= max_players),
    ADD CONSTRAINT chk_matches_timing
    CHECK (ended_at IS NULL OR ended_at >= started_at);

-- Match participants table
ALTER TABLE match_participants
    ADD CONSTRAINT chk_participants_scores
    CHECK (score >= 0),
    ADD CONSTRAINT chk_participants_stats
    CHECK (kills >= 0 AND deaths >= 0 AND assists >= 0),
    ADD CONSTRAINT chk_participants_damage
    CHECK (damage_dealt >= 0 AND damage_taken >= 0),
    ADD CONSTRAINT chk_participants_earnings
    CHECK (xp_earned >= 0 AND currency_earned >= 0),
    ADD CONSTRAINT chk_participants_placement
    CHECK (placement IS NULL OR placement > 0),
    ADD CONSTRAINT chk_participants_reports
    CHECK (reported_count >= 0),
    ADD CONSTRAINT chk_participants_timing
    CHECK (left_at IS NULL OR left_at >= joined_at);

-- Matchmaking queue table
ALTER TABLE matchmaking_queue
    ADD CONSTRAINT chk_queue_skill
    CHECK (skill_rating IS NULL OR skill_rating >= 0),
    ADD CONSTRAINT chk_queue_party
    CHECK (party_size > 0),
    ADD CONSTRAINT chk_queue_time
    CHECK (search_time_seconds IS NULL OR search_time_seconds >= 0),
    ADD CONSTRAINT chk_queue_timing
    CHECK (matched_at IS NULL OR matched_at >= queued_at);

-- Clans table
ALTER TABLE clans
    ADD CONSTRAINT chk_clans_level
    CHECK (min_level_required > 0),
    ADD CONSTRAINT chk_clans_members
    CHECK (max_members > 0 AND current_members >= 0 AND current_members <= max_members),
    ADD CONSTRAINT chk_clans_stats
    CHECK (total_wins >= 0 AND total_matches >= 0 AND clan_level > 0 AND clan_xp >= 0),
    ADD CONSTRAINT chk_clans_wins
    CHECK (total_wins <= total_matches);

-- Clan members table
ALTER TABLE clan_members
    ADD CONSTRAINT chk_members_contribution
    CHECK (contribution_points >= 0 AND donations >= 0);

-- Currencies table
ALTER TABLE currencies
    ADD CONSTRAINT chk_currencies_rate
    CHECK (usd_rate IS NULL OR usd_rate > 0);

-- Player wallets table
ALTER TABLE player_wallets
    ADD CONSTRAINT chk_wallets_balance
    CHECK (balance >= 0),
    ADD CONSTRAINT chk_wallets_totals
    CHECK (total_earned >= 0 AND total_spent >= 0);

-- Store items table
ALTER TABLE store_items
    ADD CONSTRAINT chk_store_price
    CHECK (price IS NULL OR price >= 0),
    ADD CONSTRAINT chk_store_discount
    CHECK (discount_percentage >= 0 AND discount_percentage <= 100),
    ADD CONSTRAINT chk_store_stock
    CHECK ((stock_limit IS NULL OR stock_limit > 0) AND
           (stock_remaining IS NULL OR (stock_remaining >= 0 AND stock_remaining <= stock_limit))),
    ADD CONSTRAINT chk_store_level
    CHECK (min_level >= 1),
    ADD CONSTRAINT chk_store_purchases
    CHECK (times_purchased >= 0),
    ADD CONSTRAINT chk_store_availability
    CHECK (available_until IS NULL OR available_from IS NULL OR available_until > available_from);

-- Transactions table
ALTER TABLE transactions
    ADD CONSTRAINT chk_transactions_amount
    CHECK (amount != 0);

-- Achievements table
ALTER TABLE achievements
    ADD CONSTRAINT chk_achievements_requirement
    CHECK (requirement_value IS NULL OR requirement_value > 0),
    ADD CONSTRAINT chk_achievements_rewards
    CHECK (xp_reward >= 0 AND points >= 0),
    ADD CONSTRAINT chk_achievements_stats
    CHECK (times_earned >= 0),
    ADD CONSTRAINT chk_achievements_rarity
    CHECK (rarity_percentage IS NULL OR (rarity_percentage >= 0 AND rarity_percentage <= 100));

-- Player achievements table
ALTER TABLE player_achievements
    ADD CONSTRAINT chk_player_achievements_progress
    CHECK (progress >= 0),
    ADD CONSTRAINT chk_player_achievements_timing
    CHECK (completed_at IS NULL OR completed_at >= started_at);

-- Player stats table
ALTER TABLE player_stats
    ADD CONSTRAINT chk_stats_matches
    CHECK (matches_played >= 0 AND matches_won >= 0 AND matches_lost >= 0 AND matches_drawn >= 0),
    ADD CONSTRAINT chk_stats_total_matches
    CHECK (matches_played = matches_won + matches_lost + matches_drawn),
    ADD CONSTRAINT chk_stats_combat
    CHECK (total_kills >= 0 AND total_deaths >= 0 AND total_assists >= 0),
    ADD CONSTRAINT chk_stats_rating
    CHECK (current_rating >= 0 AND peak_rating >= current_rating),
    ADD CONSTRAINT chk_stats_time
    CHECK (playtime_hours >= 0 AND longest_session_hours >= 0),
    ADD CONSTRAINT chk_stats_streaks
    CHECK (current_win_streak >= 0 AND longest_win_streak >= 0 AND longest_win_streak >= current_win_streak);

-- Tournaments table
ALTER TABLE tournaments
    ADD CONSTRAINT chk_tournaments_participants
    CHECK (max_participants > 0 AND current_participants >= 0 AND current_participants <= max_participants),
    ADD CONSTRAINT chk_tournaments_fee
    CHECK (entry_fee IS NULL OR entry_fee >= 0),
    ADD CONSTRAINT chk_tournaments_requirements
    CHECK ((min_rating IS NULL OR min_rating >= 0) AND (min_level IS NULL OR min_level >= 1)),
    ADD CONSTRAINT chk_tournaments_prize
    CHECK (total_prize_value IS NULL OR total_prize_value >= 0),
    ADD CONSTRAINT chk_tournaments_timing
    CHECK (registration_end > registration_start AND tournament_start >= registration_end);

-- Tournament participants table
ALTER TABLE tournament_participants
    ADD CONSTRAINT chk_tournament_participants_seed
    CHECK (seed_number IS NULL OR seed_number > 0),
    ADD CONSTRAINT chk_tournament_participants_progress
    CHECK (current_round >= 0 AND matches_played >= 0 AND matches_won >= 0),
    ADD CONSTRAINT chk_tournament_participants_position
    CHECK (final_position IS NULL OR final_position > 0),
    ADD CONSTRAINT chk_tournament_participants_elimination
    CHECK ((is_eliminated = FALSE AND eliminated_round IS NULL) OR
           (is_eliminated = TRUE AND eliminated_round IS NOT NULL));

-- Leaderboard entries table
ALTER TABLE leaderboard_entries
    ADD CONSTRAINT chk_leaderboard_rank
    CHECK (rank IS NULL OR rank > 0);

-- Player reports table
ALTER TABLE player_reports
    ADD CONSTRAINT chk_reports_action_duration
    CHECK (action_duration_hours IS NULL OR action_duration_hours > 0),
    ADD CONSTRAINT chk_reports_timing
    CHECK (reviewed_at IS NULL OR reviewed_at >= created_at);

-- Ban history table
ALTER TABLE ban_history
    ADD CONSTRAINT chk_bans_timing
    CHECK ((expires_at IS NULL OR expires_at > banned_at) AND
           (lifted_at IS NULL OR lifted_at >= banned_at));

-- ============================================================================
-- UNIQUE CONSTRAINTS
-- ============================================================================

-- Ensure unique active friendships (prevent duplicate friend requests)
ALTER TABLE friendships
    ADD CONSTRAINT uk_friendship_pair
    UNIQUE KEY (LEAST(player_id, friend_id), GREATEST(player_id, friend_id), status)
    WHERE status = 'accepted';

-- ============================================================================
-- TRIGGERS FOR DATA INTEGRITY
-- ============================================================================

DELIMITER //

-- Update player level based on XP
CREATE TRIGGER trg_update_player_level
BEFORE UPDATE ON players
FOR EACH ROW
BEGIN
    -- Simple level calculation: level = floor(sqrt(xp / 100))
    SET NEW.player_level = GREATEST(1, FLOOR(SQRT(NEW.total_xp / 100)));

    -- Prestige at level 100
    IF NEW.player_level >= 100 THEN
        SET NEW.prestige_level = FLOOR(NEW.player_level / 100);
        SET NEW.player_level = NEW.player_level MOD 100;
    END IF;
END//

-- Update game statistics after match
CREATE TRIGGER trg_update_game_stats
AFTER UPDATE ON match_sessions
FOR EACH ROW
BEGIN
    IF OLD.status != 'completed' AND NEW.status = 'completed' THEN
        UPDATE games
        SET total_players = (
            SELECT COUNT(DISTINCT mp.player_id)
            FROM match_participants mp
            JOIN match_sessions ms ON mp.match_id = ms.match_id
            WHERE ms.game_id = NEW.game_id
        )
        WHERE game_id = NEW.game_id;
    END IF;
END//

-- Update player stats after match
CREATE TRIGGER trg_update_player_stats_after_match
AFTER INSERT ON match_participants
FOR EACH ROW
BEGIN
    INSERT INTO player_stats (player_id, game_id, matches_played)
    VALUES (NEW.player_id,
            (SELECT game_id FROM match_sessions WHERE match_id = NEW.match_id),
            1)
    ON DUPLICATE KEY UPDATE
        matches_played = matches_played + 1,
        matches_won = matches_won + IF(NEW.is_winner, 1, 0),
        matches_lost = matches_lost + IF(NOT NEW.is_winner AND NEW.placement IS NOT NULL, 1, 0),
        total_kills = total_kills + NEW.kills,
        total_deaths = total_deaths + NEW.deaths,
        total_assists = total_assists + NEW.assists,
        current_rating = COALESCE(NEW.rating_after, current_rating),
        peak_rating = GREATEST(peak_rating, COALESCE(NEW.rating_after, current_rating));
END//

-- Update clan statistics
CREATE TRIGGER trg_update_clan_member_count
AFTER INSERT ON clan_members
FOR EACH ROW
BEGIN
    UPDATE clans
    SET current_members = current_members + 1
    WHERE clan_id = NEW.clan_id;
END//

CREATE TRIGGER trg_update_clan_member_count_delete
AFTER DELETE ON clan_members
FOR EACH ROW
BEGIN
    UPDATE clans
    SET current_members = current_members - 1
    WHERE clan_id = OLD.clan_id;
END//

-- Update wallet on transaction
CREATE TRIGGER trg_update_wallet_balance
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
    IF NEW.payment_status = 'completed' OR NEW.payment_status IS NULL THEN
        UPDATE player_wallets
        SET balance = CASE
                WHEN NEW.transaction_type IN ('purchase', 'earn', 'refund') THEN balance + NEW.amount
                WHEN NEW.transaction_type IN ('spend', 'transfer') THEN balance - ABS(NEW.amount)
                ELSE balance
            END,
            total_earned = total_earned + IF(NEW.transaction_type IN ('earn', 'refund'), ABS(NEW.amount), 0),
            total_spent = total_spent + IF(NEW.transaction_type IN ('spend', 'purchase'), ABS(NEW.amount), 0)
        WHERE player_id = NEW.player_id AND currency_id = NEW.currency_id;
    END IF;
END//

-- Track achievement progress
CREATE TRIGGER trg_check_achievement_completion
AFTER UPDATE ON player_achievements
FOR EACH ROW
BEGIN
    DECLARE req_value INT;

    IF NOT NEW.is_completed AND NEW.progress > OLD.progress THEN
        SELECT requirement_value INTO req_value
        FROM achievements
        WHERE achievement_id = NEW.achievement_id;

        IF NEW.progress >= req_value THEN
            UPDATE player_achievements
            SET is_completed = TRUE,
                completed_at = CURRENT_TIMESTAMP
            WHERE earned_id = NEW.earned_id;

            -- Update achievement statistics
            UPDATE achievements
            SET times_earned = times_earned + 1
            WHERE achievement_id = NEW.achievement_id;
        END IF;
    END IF;
END//

-- Update tournament participants count
CREATE TRIGGER trg_update_tournament_participants
AFTER INSERT ON tournament_participants
FOR EACH ROW
BEGIN
    UPDATE tournaments
    SET current_participants = current_participants + 1
    WHERE tournament_id = NEW.tournament_id;
END//

-- Update leaderboard ranks
CREATE TRIGGER trg_update_leaderboard_ranks
AFTER INSERT ON leaderboard_entries
FOR EACH ROW
BEGIN
    SET @rank := 0;

    UPDATE leaderboard_entries
    SET rank = (@rank := @rank + 1)
    WHERE leaderboard_id = NEW.leaderboard_id
    ORDER BY score DESC;
END//

-- Track player activity
CREATE TRIGGER trg_update_player_activity
AFTER INSERT ON match_participants
FOR EACH ROW
BEGIN
    UPDATE players
    SET last_activity_at = CURRENT_TIMESTAMP
    WHERE player_id = NEW.player_id;
END//

-- Apply bans from reports
CREATE TRIGGER trg_apply_ban_from_report
AFTER UPDATE ON player_reports
FOR EACH ROW
BEGIN
    IF NEW.action_taken IN ('temp_ban', 'permanent_ban') AND OLD.action_taken IS NULL THEN
        INSERT INTO ban_history (player_id, ban_type, reason, expires_at, banned_by)
        VALUES (
            NEW.reported_id,
            IF(NEW.action_taken = 'temp_ban', 'temporary', 'permanent'),
            CONCAT('Report #', NEW.report_id, ': ', NEW.report_type),
            IF(NEW.action_taken = 'temp_ban',
               DATE_ADD(CURRENT_TIMESTAMP, INTERVAL NEW.action_duration_hours HOUR),
               NULL),
            NEW.reviewed_by
        );

        -- Update player status
        UPDATE players
        SET status = IF(NEW.action_taken = 'permanent_ban', 'banned', 'suspended')
        WHERE player_id = NEW.reported_id;
    END IF;
END//

DELIMITER ;

-- ============================================================================
-- EVENTS FOR AUTOMATED TASKS
-- ============================================================================

DELIMITER //

-- Clean up expired sessions
CREATE EVENT IF NOT EXISTS evt_cleanup_sessions
ON SCHEDULE EVERY 1 HOUR
DO
BEGIN
    UPDATE player_sessions
    SET is_active = FALSE
    WHERE is_active = TRUE AND expires_at <= CURRENT_TIMESTAMP;

    -- Delete very old sessions
    DELETE FROM player_sessions
    WHERE expires_at < DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 30 DAY);
END//

-- Update server heartbeats
CREATE EVENT IF NOT EXISTS evt_check_server_heartbeat
ON SCHEDULE EVERY 1 MINUTE
DO
BEGIN
    UPDATE game_servers
    SET status = 'offline'
    WHERE status != 'offline'
      AND last_heartbeat < DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 5 MINUTE);
END//

-- Process matchmaking timeouts
CREATE EVENT IF NOT EXISTS evt_matchmaking_timeout
ON SCHEDULE EVERY 30 SECOND
DO
BEGIN
    UPDATE matchmaking_queue
    SET status = 'timeout'
    WHERE status = 'searching'
      AND queued_at < DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 5 MINUTE);
END//

-- Reset daily leaderboards
CREATE EVENT IF NOT EXISTS evt_reset_daily_leaderboards
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_DATE + INTERVAL 1 DAY
DO
BEGIN
    UPDATE leaderboards
    SET last_reset = CURRENT_TIMESTAMP,
        next_reset = DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 1 DAY)
    WHERE reset_frequency = 'daily' AND is_active = TRUE;

    -- Clear entries for daily leaderboards
    DELETE le FROM leaderboard_entries le
    JOIN leaderboards l ON le.leaderboard_id = l.leaderboard_id
    WHERE l.reset_frequency = 'daily';
END//

-- Reset weekly leaderboards
CREATE EVENT IF NOT EXISTS evt_reset_weekly_leaderboards
ON SCHEDULE EVERY 1 WEEK
STARTS CURRENT_DATE + INTERVAL (7 - DAYOFWEEK(CURRENT_DATE) + 2) % 7 DAY
DO
BEGIN
    UPDATE leaderboards
    SET last_reset = CURRENT_TIMESTAMP,
        next_reset = DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 1 WEEK)
    WHERE reset_frequency = 'weekly' AND is_active = TRUE;

    -- Clear entries for weekly leaderboards
    DELETE le FROM leaderboard_entries le
    JOIN leaderboards l ON le.leaderboard_id = l.leaderboard_id
    WHERE l.reset_frequency = 'weekly';
END//

-- Process expired bans
CREATE EVENT IF NOT EXISTS evt_process_expired_bans
ON SCHEDULE EVERY 1 HOUR
DO
BEGIN
    UPDATE ban_history
    SET is_active = FALSE,
        lifted_at = CURRENT_TIMESTAMP
    WHERE is_active = TRUE
      AND ban_type = 'temporary'
      AND expires_at <= CURRENT_TIMESTAMP;

    -- Restore player status
    UPDATE players p
    JOIN ban_history b ON p.player_id = b.player_id
    SET p.status = 'active'
    WHERE b.is_active = FALSE
      AND b.lifted_at = CURRENT_TIMESTAMP
      AND p.status = 'suspended';
END//

-- Calculate achievement rarity
CREATE EVENT IF NOT EXISTS evt_calculate_achievement_rarity
ON SCHEDULE EVERY 1 DAY
DO
BEGIN
    UPDATE achievements a
    SET rarity_percentage = (
        SELECT COUNT(DISTINCT pa.player_id) * 100.0 / GREATEST(
            (SELECT COUNT(*) FROM players WHERE status = 'active'), 1
        )
        FROM player_achievements pa
        WHERE pa.achievement_id = a.achievement_id
          AND pa.is_completed = TRUE
    );
END//

-- Update game online counts
CREATE EVENT IF NOT EXISTS evt_update_game_online_counts
ON SCHEDULE EVERY 5 MINUTE
DO
BEGIN
    UPDATE games g
    SET current_online = (
        SELECT COUNT(DISTINCT p.player_id)
        FROM players p
        JOIN player_sessions ps ON p.player_id = ps.player_id
        JOIN player_games pg ON p.player_id = pg.player_id
        WHERE pg.game_id = g.game_id
          AND ps.is_active = TRUE
          AND ps.last_activity_at >= DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 5 MINUTE)
    ),
    peak_online = GREATEST(peak_online, current_online);
END//

DELIMITER ;