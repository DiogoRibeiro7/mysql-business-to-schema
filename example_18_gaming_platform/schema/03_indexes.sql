-- ============================================================================
-- INDEXES FOR GAMING PLATFORM
-- ============================================================================

USE gaming_platform;

-- ============================================================================
-- PERFORMANCE INDEXES
-- ============================================================================

-- Players table - optimize for authentication and search
CREATE INDEX idx_players_username_status ON players(username, status);
CREATE INDEX idx_players_email_status ON players(email, status);
CREATE INDEX idx_players_level_xp ON players(player_level DESC, total_xp DESC);
CREATE INDEX idx_players_premium ON players(is_premium, premium_until);
CREATE INDEX idx_players_trust ON players(trust_score, vac_banned);
CREATE INDEX idx_players_online ON players(last_activity_at DESC, status);

-- Player sessions - optimize for session management
CREATE INDEX idx_sessions_player_active ON player_sessions(player_id, is_active, last_activity_at DESC);
CREATE INDEX idx_sessions_expiry ON player_sessions(expires_at, is_active);

-- Games table - optimize for discovery and filtering
CREATE INDEX idx_games_status_featured ON games(status, is_featured, user_score DESC);
CREATE INDEX idx_games_price ON games(current_price, discount_percentage);
CREATE INDEX idx_games_release ON games(release_date DESC, status);
CREATE INDEX idx_games_multiplayer ON games(has_multiplayer, current_online DESC);
CREATE INDEX idx_games_f2p ON games(is_free_to_play, total_players DESC);

-- Player games - optimize for library queries
CREATE INDEX idx_player_games_library ON player_games(player_id, is_hidden, last_played_at DESC);
CREATE INDEX idx_player_games_installed ON player_games(player_id, is_installed);
CREATE INDEX idx_player_games_favorites ON player_games(player_id, is_favorite);
CREATE INDEX idx_player_games_recent ON player_games(last_played_at DESC);

-- Game servers - optimize for matchmaking
CREATE INDEX idx_servers_available ON game_servers(game_id, status, server_region, current_players, max_players);
CREATE INDEX idx_servers_region_status ON game_servers(server_region, status, current_players);
CREATE INDEX idx_servers_ranked ON game_servers(game_id, is_ranked, status);

-- Match sessions - optimize for history and active matches
CREATE INDEX idx_matches_game_status ON match_sessions(game_id, status, started_at DESC);
CREATE INDEX idx_matches_active ON match_sessions(status, started_at);
CREATE INDEX idx_matches_completed ON match_sessions(game_id, ended_at DESC);
CREATE INDEX idx_matches_tournament ON match_sessions(match_type, game_id, started_at DESC);

-- Match participants - optimize for player history
CREATE INDEX idx_participants_player_recent ON match_participants(player_id, joined_at DESC);
CREATE INDEX idx_participants_winner ON match_participants(match_id, is_winner);
CREATE INDEX idx_participants_performance ON match_participants(match_id, score DESC);
CREATE INDEX idx_participants_left_early ON match_participants(match_id, left_early);

-- Matchmaking queue - optimize for matching algorithm
CREATE INDEX idx_matchmaking_active ON matchmaking_queue(game_id, game_mode, skill_rating, queued_at);
CREATE INDEX idx_matchmaking_party ON matchmaking_queue(party_id, status);
CREATE INDEX idx_matchmaking_region ON matchmaking_queue(game_id, preferred_region, status);

-- Friendships - optimize for friend lists
CREATE INDEX idx_friendships_accepted ON friendships(player_id, status, is_favorite DESC);
CREATE INDEX idx_friendships_pending ON friendships(friend_id, status, requested_at DESC);
CREATE INDEX idx_friendships_blocked ON friendships(player_id, status);

-- Clans - optimize for search and ranking
CREATE INDEX idx_clans_public ON clans(is_public, status, clan_level DESC, total_wins DESC);
CREATE INDEX idx_clans_recruiting ON clans(is_public, current_members, max_members, min_level_required);

-- Clan members - optimize for roster queries
CREATE INDEX idx_clan_members_roster ON clan_members(clan_id, role, contribution_points DESC);
CREATE INDEX idx_clan_members_player ON clan_members(player_id, joined_at DESC);

-- Chat messages - optimize for retrieval
CREATE INDEX idx_chat_channel_recent ON chat_messages(channel_type, channel_id, created_at DESC, is_deleted);
CREATE INDEX idx_chat_sender ON chat_messages(sender_id, created_at DESC);

-- Player wallets - optimize for balance checks
CREATE INDEX idx_wallets_player_currency ON player_wallets(player_id, currency_id, balance);

-- Store items - optimize for shop browsing
CREATE INDEX idx_store_available ON store_items(game_id, item_type, is_available, available_from, available_until);
CREATE INDEX idx_store_discounted ON store_items(discount_percentage DESC, is_available);

-- Transactions - optimize for history and analytics
CREATE INDEX idx_transactions_player_recent ON transactions(player_id, created_at DESC);
CREATE INDEX idx_transactions_type ON transactions(transaction_type, currency_id, created_at DESC);
CREATE INDEX idx_transactions_pending ON transactions(payment_status, created_at);

-- Achievements - optimize for progress tracking
CREATE INDEX idx_achievements_game_tier ON achievements(game_id, tier, is_hidden);
CREATE INDEX idx_achievements_seasonal ON achievements(is_seasonal, game_id);
CREATE INDEX idx_achievements_rarity ON achievements(rarity_percentage, tier);

-- Player achievements - optimize for profile display
CREATE INDEX idx_player_achievements_profile ON player_achievements(player_id, is_completed, completed_at DESC);
CREATE INDEX idx_player_achievements_progress ON player_achievements(player_id, is_completed, progress);
CREATE INDEX idx_player_achievements_recent ON player_achievements(completed_at DESC);

-- Player stats - optimize for leaderboards and matchmaking
CREATE INDEX idx_stats_game_rating ON player_stats(game_id, current_rating DESC);
CREATE INDEX idx_stats_game_wins ON player_stats(game_id, matches_won DESC);
CREATE INDEX idx_stats_player_games ON player_stats(player_id, playtime_hours DESC);
CREATE INDEX idx_stats_kd_ratio ON player_stats(game_id, kd_ratio DESC);

-- Tournaments - optimize for discovery
CREATE INDEX idx_tournaments_upcoming ON tournaments(status, tournament_start, game_id);
CREATE INDEX idx_tournaments_active ON tournaments(status, tournament_start);
CREATE INDEX idx_tournaments_registration ON tournaments(status, registration_end, current_participants, max_participants);

-- Tournament participants - optimize for brackets
CREATE INDEX idx_tournament_participants_bracket ON tournament_participants(tournament_id, current_round, seed_number);
CREATE INDEX idx_tournament_participants_player ON tournament_participants(player_id, is_eliminated);

-- Leaderboards - optimize for display
CREATE INDEX idx_leaderboards_game_active ON leaderboards(game_id, leaderboard_type, is_active);
CREATE INDEX idx_leaderboards_reset ON leaderboards(reset_frequency, next_reset);

-- Leaderboard entries - optimize for ranking
CREATE INDEX idx_leaderboard_entries_top ON leaderboard_entries(leaderboard_id, score DESC, rank_position);
CREATE INDEX idx_leaderboard_entries_player ON leaderboard_entries(player_id, achieved_at DESC);

-- Player reports - optimize for moderation
CREATE INDEX idx_reports_pending ON player_reports(status, created_at);
CREATE INDEX idx_reports_player ON player_reports(reported_id, status, created_at DESC);
CREATE INDEX idx_reports_match ON player_reports(match_id, status);

-- Ban history - optimize for enforcement
CREATE INDEX idx_bans_active ON ban_history(player_id, ban_type, is_active, expires_at);
CREATE INDEX idx_bans_expiring ON ban_history(expires_at, is_active);

-- ============================================================================
-- COMPOSITE INDEXES FOR COMPLEX QUERIES
-- ============================================================================

-- Find friends who are online and playing same game
CREATE INDEX idx_friends_online_game ON friendships(player_id, status);

-- Matchmaking with skill and region
CREATE INDEX idx_matchmaking_composite ON matchmaking_queue(
    game_id, game_mode, preferred_region, skill_rating, party_size, queued_at
);

-- Tournament standings
CREATE INDEX idx_tournament_standings ON tournament_participants(
    tournament_id, is_eliminated, matches_won DESC, final_position
);

-- Active game sessions per player
CREATE INDEX idx_active_game_sessions ON match_participants(
    player_id, joined_at DESC
);

-- Store recommendations based on owned games
CREATE INDEX idx_store_recommendations ON store_items(
    game_id, item_type, is_available, times_purchased DESC
);

-- Clan war participants
CREATE INDEX idx_clan_war_performance
    ON match_participants(match_id, score DESC, player_id);

-- ============================================================================
-- FULL-TEXT INDEXES
-- ============================================================================

-- Game search
ALTER TABLE games ADD FULLTEXT ft_games_search (title, description);

-- Player search
ALTER TABLE players ADD FULLTEXT ft_players_search (username, display_name);

-- Clan search
ALTER TABLE clans ADD FULLTEXT ft_clans_search (name, description, motto);

-- Chat message search
ALTER TABLE chat_messages ADD FULLTEXT ft_chat_search (message_text);

-- Store item search
ALTER TABLE store_items ADD FULLTEXT ft_store_search (name, description);

-- ============================================================================
-- STATISTICS UPDATE
-- ============================================================================

-- Update table statistics for query optimizer
ANALYZE TABLE players;
ANALYZE TABLE games;
ANALYZE TABLE player_games;
ANALYZE TABLE match_sessions;
ANALYZE TABLE match_participants;
ANALYZE TABLE friendships;
ANALYZE TABLE player_stats;
ANALYZE TABLE achievements;
ANALYZE TABLE player_achievements;
ANALYZE TABLE transactions;
ANALYZE TABLE chat_messages;

-- ============================================================================
-- INDEX HINTS FOR COMMON QUERIES
-- ============================================================================

/*
Common Query Patterns and Their Indexes:

1. User authentication:
   Uses: uk_username or uk_email

2. Friend list with online status:
   Uses: idx_friendships_accepted, idx_players_online

3. Finding available game servers:
   Uses: idx_servers_available

4. Matchmaking queue:
   Uses: idx_matchmaking_active, idx_matchmaking_composite

5. Player game library:
   Uses: idx_player_games_library

6. Leaderboard display:
   Uses: idx_leaderboard_entries_top

7. Achievement progress:
   Uses: idx_player_achievements_progress

8. Tournament brackets:
   Uses: idx_tournament_participants_bracket

9. Recent match history:
   Uses: idx_participants_player_recent

10. Store browsing:
    Uses: idx_store_available, idx_store_discounted

11. Clan member list:
    Uses: idx_clan_members_roster

12. Chat history:
    Uses: idx_chat_channel_recent

13. Moderation queue:
    Uses: idx_reports_pending

14. Active ban check:
    Uses: idx_bans_active

15. Game discovery:
    Uses: ft_games_search, idx_games_status_featured
*/
