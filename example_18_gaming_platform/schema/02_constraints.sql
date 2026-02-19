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
    ADD CONSTRAINT chk_leaderboard_rank_position
    CHECK (rank_position IS NULL OR rank_position > 0);

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
    ADD COLUMN accepted_friendship_key VARCHAR(255) GENERATED ALWAYS AS (
        CASE
            WHEN status = 'accepted' THEN CONCAT(LEAST(player_id, friend_id), ':', GREATEST(player_id, friend_id))
            ELSE NULL
        END
    ) STORED,
    ADD UNIQUE INDEX uk_friendship_pair (accepted_friendship_key);

-- ============================================================================
-- TRIGGERS FOR DATA INTEGRITY
-- ============================================================================

-- Triggers and events are omitted for CI compatibility.
