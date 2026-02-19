-- ============================================================================
-- CORE TABLES FOR GAMING PLATFORM
-- ============================================================================

USE gaming_platform;

-- ============================================================================
-- PLAYER MANAGEMENT
-- ============================================================================

-- Players (users) table
CREATE TABLE players (
    player_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,

    -- Profile Information
    display_name VARCHAR(100) NOT NULL,
    avatar_url VARCHAR(500),
    banner_url VARCHAR(500),
    bio TEXT,
    country VARCHAR(2), -- ISO country code
    language VARCHAR(5) DEFAULT 'en', -- Language preference
    timezone VARCHAR(50) DEFAULT 'UTC',
    date_of_birth DATE,

    -- Account Status
    status ENUM('active', 'suspended', 'banned', 'deleted') DEFAULT 'active',
    email_verified BOOLEAN DEFAULT FALSE,
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    two_factor_secret VARCHAR(255),

    -- Player Level and Experience
    player_level INT DEFAULT 1,
    total_xp BIGINT DEFAULT 0,
    prestige_level INT DEFAULT 0,

    -- Statistics
    total_playtime_hours DECIMAL(10,2) DEFAULT 0,
    games_owned INT DEFAULT 0,
    achievements_earned INT DEFAULT 0,
    tournaments_won INT DEFAULT 0,

    -- Premium Status
    is_premium BOOLEAN DEFAULT FALSE,
    premium_until TIMESTAMP NULL,

    -- Anti-Cheat
    trust_score DECIMAL(5,2) DEFAULT 100.00, -- 0-100
    vac_banned BOOLEAN DEFAULT FALSE,
    vac_ban_date TIMESTAMP NULL,

    -- Privacy Settings
    profile_visibility ENUM('public', 'friends', 'private') DEFAULT 'public',
    show_online_status BOOLEAN DEFAULT TRUE,
    allow_friend_requests BOOLEAN DEFAULT TRUE,

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP NULL,
    last_activity_at TIMESTAMP NULL,

    PRIMARY KEY (player_id),
    UNIQUE KEY uk_username (username),
    UNIQUE KEY uk_email (email),
    INDEX idx_status (status),
    INDEX idx_level (player_level DESC),
    INDEX idx_country (country),
    INDEX idx_last_activity (last_activity_at DESC)
) ENGINE=InnoDB;

-- Player sessions
CREATE TABLE player_sessions (
    session_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    player_id BIGINT UNSIGNED NOT NULL,

    -- Session details
    session_token VARCHAR(255) NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    platform ENUM('pc', 'xbox', 'playstation', 'nintendo', 'mobile', 'web') DEFAULT 'pc',
    device_id VARCHAR(255),

    -- Location
    country VARCHAR(2),
    region VARCHAR(100),

    -- Status
    is_active BOOLEAN DEFAULT TRUE,

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_activity_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,

    PRIMARY KEY (session_id),
    UNIQUE KEY uk_token (session_token),
    INDEX idx_player (player_id),
    INDEX idx_active (is_active, expires_at),
    FOREIGN KEY (player_id) REFERENCES players(player_id)
) ENGINE=InnoDB;

-- ============================================================================
-- GAME CATALOG
-- ============================================================================

-- Games available on the platform
CREATE TABLE games (
    game_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) NOT NULL,

    -- Game Information
    description TEXT,
    developer VARCHAR(255),
    publisher VARCHAR(255),
    genre JSON, -- ["action", "rpg", "strategy", etc]
    tags JSON, -- ["multiplayer", "co-op", "pvp", etc]

    -- Release Information
    release_date DATE,
    early_access BOOLEAN DEFAULT FALSE,

    -- Platform Support
    platforms JSON, -- ["pc", "xbox", "playstation", etc]

    -- Pricing
    base_price DECIMAL(10,2),
    current_price DECIMAL(10,2),
    discount_percentage DECIMAL(5,2) DEFAULT 0,
    is_free_to_play BOOLEAN DEFAULT FALSE,

    -- Requirements
    min_age INT DEFAULT 0,
    content_rating ENUM('E', 'E10+', 'T', 'M', 'AO') DEFAULT 'E',

    -- Multiplayer
    max_players INT DEFAULT 1,
    has_multiplayer BOOLEAN DEFAULT FALSE,
    has_coop BOOLEAN DEFAULT FALSE,
    requires_online BOOLEAN DEFAULT FALSE,

    -- Statistics
    total_players INT DEFAULT 0,
    current_online INT DEFAULT 0,
    peak_online INT DEFAULT 0,
    average_playtime_hours DECIMAL(10,2) DEFAULT 0,

    -- Ratings
    critic_score DECIMAL(3,1), -- 0-10
    user_score DECIMAL(3,1), -- 0-10
    total_reviews INT DEFAULT 0,

    -- Media
    cover_image_url VARCHAR(500),
    hero_image_url VARCHAR(500),
    trailer_url VARCHAR(500),

    -- Status
    status ENUM('coming_soon', 'available', 'discontinued') DEFAULT 'available',
    is_featured BOOLEAN DEFAULT FALSE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (game_id),
    UNIQUE KEY uk_slug (slug),
    INDEX idx_title (title),
    INDEX idx_status (status),
    INDEX idx_genre ((CAST(genre AS CHAR(255)))),
    INDEX idx_release (release_date),
    INDEX idx_featured (is_featured, status),
    FULLTEXT INDEX ft_search (title, description)
) ENGINE=InnoDB;

-- Player game library
CREATE TABLE player_games (
    library_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    player_id BIGINT UNSIGNED NOT NULL,
    game_id BIGINT UNSIGNED NOT NULL,

    -- Acquisition
    acquired_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    acquisition_type ENUM('purchase', 'gift', 'free', 'subscription', 'trial') DEFAULT 'purchase',
    purchase_price DECIMAL(10,2),

    -- Play Statistics
    total_playtime_minutes INT DEFAULT 0,
    last_played_at TIMESTAMP NULL,
    times_launched INT DEFAULT 0,

    -- Installation
    is_installed BOOLEAN DEFAULT FALSE,
    install_size_gb DECIMAL(10,2),
    last_updated_at TIMESTAMP NULL,

    -- Status
    is_favorite BOOLEAN DEFAULT FALSE,
    is_hidden BOOLEAN DEFAULT FALSE,

    PRIMARY KEY (library_id),
    UNIQUE KEY uk_player_game (player_id, game_id),
    INDEX idx_player (player_id),
    INDEX idx_game (game_id),
    INDEX idx_last_played (last_played_at DESC),
    INDEX idx_favorites (player_id, is_favorite),
    FOREIGN KEY (player_id) REFERENCES players(player_id),
    FOREIGN KEY (game_id) REFERENCES games(game_id)
) ENGINE=InnoDB;

-- ============================================================================
-- MULTIPLAYER & MATCHMAKING
-- ============================================================================

-- Game servers
CREATE TABLE game_servers (
    server_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    game_id BIGINT UNSIGNED NOT NULL,

    -- Server Information
    server_name VARCHAR(255),
    server_region ENUM('us-east', 'us-west', 'eu-west', 'eu-central', 'asia-pacific', 'asia-east') NOT NULL,
    ip_address VARCHAR(45),
    port INT,

    -- Capacity
    max_players INT NOT NULL,
    current_players INT DEFAULT 0,

    -- Game Mode
    game_mode VARCHAR(100),
    map_name VARCHAR(100),

    -- Status
    status ENUM('starting', 'online', 'full', 'restarting', 'offline') DEFAULT 'starting',
    is_ranked BOOLEAN DEFAULT FALSE,
    is_private BOOLEAN DEFAULT FALSE,
    password_hash VARCHAR(255),

    -- Performance
    tick_rate INT DEFAULT 64,
    average_ping INT,

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_heartbeat TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (server_id),
    INDEX idx_game (game_id),
    INDEX idx_status (status),
    INDEX idx_region (server_region),
    INDEX idx_available (status, current_players, max_players),
    FOREIGN KEY (game_id) REFERENCES games(game_id)
) ENGINE=InnoDB;

-- Match sessions
CREATE TABLE match_sessions (
    match_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    game_id BIGINT UNSIGNED NOT NULL,
    server_id BIGINT UNSIGNED,

    -- Match Information
    match_type ENUM('quick', 'ranked', 'tournament', 'custom', 'practice') DEFAULT 'quick',
    game_mode VARCHAR(100),
    map_name VARCHAR(100),

    -- Timing
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP NULL,
    duration_seconds INT,

    -- Status
    status ENUM('waiting', 'starting', 'in_progress', 'completed', 'cancelled') DEFAULT 'waiting',

    -- Results
    winning_team INT,
    final_scores JSON, -- Team/player scores

    -- Statistics
    total_players INT DEFAULT 0,
    max_players INT NOT NULL,

    PRIMARY KEY (match_id),
    INDEX idx_game (game_id),
    INDEX idx_server (server_id),
    INDEX idx_status (status),
    INDEX idx_started (started_at DESC),
    INDEX idx_match_type (match_type, status),
    FOREIGN KEY (game_id) REFERENCES games(game_id),
    FOREIGN KEY (server_id) REFERENCES game_servers(server_id)
) ENGINE=InnoDB;

-- Match participants
CREATE TABLE match_participants (
    participant_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    match_id BIGINT UNSIGNED NOT NULL,
    player_id BIGINT UNSIGNED NOT NULL,

    -- Team/Side
    team_id INT,
    team_name VARCHAR(50),

    -- Performance
    score INT DEFAULT 0,
    kills INT DEFAULT 0,
    deaths INT DEFAULT 0,
    assists INT DEFAULT 0,
    damage_dealt INT DEFAULT 0,
    damage_taken INT DEFAULT 0,

    -- Match Data
    character_played VARCHAR(100),
    loadout JSON,

    -- Results
    placement INT, -- Position/rank in match
    xp_earned INT DEFAULT 0,
    currency_earned INT DEFAULT 0,
    is_winner BOOLEAN DEFAULT FALSE,

    -- Behavior
    left_early BOOLEAN DEFAULT FALSE,
    was_kicked BOOLEAN DEFAULT FALSE,
    reported_count INT DEFAULT 0,

    -- Rating Changes
    rating_before INT,
    rating_after INT,
    rating_change INT,

    -- Timestamps
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    left_at TIMESTAMP NULL,

    PRIMARY KEY (participant_id),
    UNIQUE KEY uk_match_player (match_id, player_id),
    INDEX idx_match (match_id),
    INDEX idx_player (player_id),
    INDEX idx_winner (is_winner),
    FOREIGN KEY (match_id) REFERENCES match_sessions(match_id),
    FOREIGN KEY (player_id) REFERENCES players(player_id)
) ENGINE=InnoDB;

-- Matchmaking queue
CREATE TABLE matchmaking_queue (
    queue_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    player_id BIGINT UNSIGNED NOT NULL,
    game_id BIGINT UNSIGNED NOT NULL,

    -- Preferences
    game_mode VARCHAR(100),
    preferred_region VARCHAR(50),
    skill_rating INT,

    -- Party
    party_id VARCHAR(100),
    party_size INT DEFAULT 1,

    -- Status
    status ENUM('searching', 'found', 'cancelled', 'timeout') DEFAULT 'searching',
    match_id BIGINT UNSIGNED,

    -- Timing
    queued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    matched_at TIMESTAMP NULL,
    search_time_seconds INT,

    PRIMARY KEY (queue_id),
    INDEX idx_searching (game_id, status, skill_rating),
    INDEX idx_player (player_id),
    INDEX idx_party (party_id),
    INDEX idx_queued (queued_at),
    FOREIGN KEY (player_id) REFERENCES players(player_id),
    FOREIGN KEY (game_id) REFERENCES games(game_id),
    FOREIGN KEY (match_id) REFERENCES match_sessions(match_id)
) ENGINE=InnoDB;

-- ============================================================================
-- SOCIAL FEATURES
-- ============================================================================

-- Friend relationships
CREATE TABLE friendships (
    friendship_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    player_id BIGINT UNSIGNED NOT NULL,
    friend_id BIGINT UNSIGNED NOT NULL,

    -- Status
    status ENUM('pending', 'accepted', 'blocked') DEFAULT 'pending',

    -- Metadata
    nickname VARCHAR(50), -- Custom nickname for friend
    is_favorite BOOLEAN DEFAULT FALSE,
    notifications_enabled BOOLEAN DEFAULT TRUE,

    -- Timestamps
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    accepted_at TIMESTAMP NULL,

    PRIMARY KEY (friendship_id),
    UNIQUE KEY uk_players (player_id, friend_id),
    INDEX idx_player (player_id, status),
    INDEX idx_friend (friend_id, status),
    FOREIGN KEY (player_id) REFERENCES players(player_id),
    FOREIGN KEY (friend_id) REFERENCES players(player_id)
) ENGINE=InnoDB;

-- Clans/Guilds
CREATE TABLE clans (
    clan_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    tag VARCHAR(10) NOT NULL, -- Short tag like [ABC]

    -- Information
    description TEXT,
    motto VARCHAR(255),
    founded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Leadership
    owner_id BIGINT UNSIGNED NOT NULL,

    -- Settings
    is_public BOOLEAN DEFAULT TRUE,
    min_level_required INT DEFAULT 1,
    max_members INT DEFAULT 100,
    current_members INT DEFAULT 1,

    -- Statistics
    total_wins INT DEFAULT 0,
    total_matches INT DEFAULT 0,
    clan_level INT DEFAULT 1,
    clan_xp BIGINT DEFAULT 0,

    -- Media
    emblem_url VARCHAR(500),
    banner_url VARCHAR(500),

    -- Status
    status ENUM('active', 'inactive', 'disbanded') DEFAULT 'active',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (clan_id),
    UNIQUE KEY uk_name (name),
    UNIQUE KEY uk_tag (tag),
    INDEX idx_status (status),
    INDEX idx_public (is_public, status),
    INDEX idx_owner (owner_id),
    FOREIGN KEY (owner_id) REFERENCES players(player_id)
) ENGINE=InnoDB;

-- Clan members
CREATE TABLE clan_members (
    member_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    clan_id BIGINT UNSIGNED NOT NULL,
    player_id BIGINT UNSIGNED NOT NULL,

    -- Role
    role ENUM('owner', 'officer', 'member') DEFAULT 'member',

    -- Contribution
    contribution_points INT DEFAULT 0,
    donations INT DEFAULT 0,

    -- Status
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_active_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (member_id),
    UNIQUE KEY uk_clan_player (clan_id, player_id),
    INDEX idx_clan (clan_id),
    INDEX idx_player (player_id),
    INDEX idx_role (role),
    FOREIGN KEY (clan_id) REFERENCES clans(clan_id),
    FOREIGN KEY (player_id) REFERENCES players(player_id)
) ENGINE=InnoDB;

-- Chat messages
CREATE TABLE chat_messages (
    message_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    sender_id BIGINT UNSIGNED NOT NULL,

    -- Channel
    channel_type ENUM('global', 'game', 'match', 'clan', 'party', 'private') NOT NULL,
    channel_id VARCHAR(100), -- game_id, match_id, clan_id, or conversation_id

    -- Message
    message_text TEXT NOT NULL,
    is_edited BOOLEAN DEFAULT FALSE,
    edited_at TIMESTAMP NULL,

    -- Moderation
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_by BIGINT UNSIGNED,
    deleted_at TIMESTAMP NULL,

    -- Metadata
    attachments JSON, -- URLs to images/files
    mentions JSON, -- Player IDs mentioned

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (message_id),
    INDEX idx_channel (channel_type, channel_id, created_at DESC),
    INDEX idx_sender (sender_id),
    FOREIGN KEY (sender_id) REFERENCES players(player_id)
) ENGINE=InnoDB;

-- ============================================================================
-- ECONOMY & PURCHASES
-- ============================================================================

-- Virtual currencies
CREATE TABLE currencies (
    currency_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    code VARCHAR(10) NOT NULL,
    name VARCHAR(50) NOT NULL,

    -- Type
    currency_type ENUM('premium', 'standard', 'event') DEFAULT 'standard',
    is_purchasable BOOLEAN DEFAULT TRUE,
    is_earnable BOOLEAN DEFAULT TRUE,
    is_tradeable BOOLEAN DEFAULT FALSE,

    -- Conversion
    usd_rate DECIMAL(10,4), -- How much USD per unit

    -- Display
    icon_url VARCHAR(500),
    color VARCHAR(7), -- Hex color

    PRIMARY KEY (currency_id),
    UNIQUE KEY uk_code (code)
) ENGINE=InnoDB;

-- Player wallets
CREATE TABLE player_wallets (
    wallet_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    player_id BIGINT UNSIGNED NOT NULL,
    currency_id INT UNSIGNED NOT NULL,

    -- Balance
    balance DECIMAL(20,2) DEFAULT 0,
    total_earned DECIMAL(20,2) DEFAULT 0,
    total_spent DECIMAL(20,2) DEFAULT 0,

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (wallet_id),
    UNIQUE KEY uk_player_currency (player_id, currency_id),
    INDEX idx_player (player_id),
    INDEX idx_currency (currency_id),
    FOREIGN KEY (player_id) REFERENCES players(player_id),
    FOREIGN KEY (currency_id) REFERENCES currencies(currency_id)
) ENGINE=InnoDB;

-- Store items
CREATE TABLE store_items (
    item_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    game_id BIGINT UNSIGNED,

    -- Item Information
    item_type ENUM('game', 'dlc', 'skin', 'currency', 'loot_box', 'battle_pass', 'other') NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,

    -- Pricing
    price DECIMAL(10,2),
    currency_id INT UNSIGNED,
    discount_percentage DECIMAL(5,2) DEFAULT 0,

    -- Availability
    is_available BOOLEAN DEFAULT TRUE,
    available_from TIMESTAMP NULL,
    available_until TIMESTAMP NULL,
    stock_limit INT,
    stock_remaining INT,

    -- Restrictions
    min_level INT DEFAULT 1,
    required_items JSON, -- Item IDs that must be owned

    -- Media
    image_url VARCHAR(500),

    -- Statistics
    times_purchased INT DEFAULT 0,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (item_id),
    INDEX idx_game (game_id),
    INDEX idx_type (item_type),
    INDEX idx_available (is_available),
    FOREIGN KEY (game_id) REFERENCES games(game_id),
    FOREIGN KEY (currency_id) REFERENCES currencies(currency_id)
) ENGINE=InnoDB;

-- Purchase transactions
CREATE TABLE transactions (
    transaction_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    player_id BIGINT UNSIGNED NOT NULL,

    -- Transaction Details
    transaction_type ENUM('purchase', 'earn', 'spend', 'transfer', 'refund') NOT NULL,
    amount DECIMAL(20,2) NOT NULL,
    currency_id INT UNSIGNED NOT NULL,

    -- Reference
    reference_type VARCHAR(50), -- 'store_item', 'match_reward', etc
    reference_id BIGINT UNSIGNED,

    -- Payment (for real money transactions)
    payment_method ENUM('card', 'paypal', 'crypto', 'platform') ,
    payment_status ENUM('pending', 'completed', 'failed', 'refunded'),
    payment_reference VARCHAR(255), -- External transaction ID

    -- Description
    description VARCHAR(500),

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (transaction_id),
    INDEX idx_player (player_id),
    INDEX idx_currency (currency_id),
    INDEX idx_created (created_at DESC),
    INDEX idx_reference (reference_type, reference_id),
    FOREIGN KEY (player_id) REFERENCES players(player_id),
    FOREIGN KEY (currency_id) REFERENCES currencies(currency_id)
) ENGINE=InnoDB;

-- ============================================================================
-- ACHIEVEMENTS & PROGRESSION
-- ============================================================================

-- Achievement definitions
CREATE TABLE achievements (
    achievement_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    game_id BIGINT UNSIGNED,

    -- Achievement Info
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100),

    -- Requirements
    requirement_type VARCHAR(50), -- 'kills', 'wins', 'playtime', etc
    requirement_value INT,
    requirement_data JSON, -- Additional criteria

    -- Rewards
    xp_reward INT DEFAULT 0,
    currency_rewards JSON, -- {currency_id: amount}
    item_rewards JSON, -- Item IDs

    -- Difficulty
    tier ENUM('bronze', 'silver', 'gold', 'platinum') DEFAULT 'bronze',
    points INT DEFAULT 10,

    -- Visibility
    is_hidden BOOLEAN DEFAULT FALSE,
    is_seasonal BOOLEAN DEFAULT FALSE,

    -- Media
    icon_url VARCHAR(500),

    -- Statistics
    times_earned INT DEFAULT 0,
    rarity_percentage DECIMAL(5,2), -- % of players who earned it

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (achievement_id),
    INDEX idx_game (game_id),
    INDEX idx_category (category),
    INDEX idx_tier (tier),
    FOREIGN KEY (game_id) REFERENCES games(game_id)
) ENGINE=InnoDB;

-- Player achievements
CREATE TABLE player_achievements (
    earned_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    player_id BIGINT UNSIGNED NOT NULL,
    achievement_id BIGINT UNSIGNED NOT NULL,

    -- Progress
    progress INT DEFAULT 0,
    is_completed BOOLEAN DEFAULT FALSE,

    -- Timestamps
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP NULL,

    PRIMARY KEY (earned_id),
    UNIQUE KEY uk_player_achievement (player_id, achievement_id),
    INDEX idx_player (player_id, is_completed),
    INDEX idx_achievement (achievement_id),
    INDEX idx_completed (completed_at DESC),
    FOREIGN KEY (player_id) REFERENCES players(player_id),
    FOREIGN KEY (achievement_id) REFERENCES achievements(achievement_id)
) ENGINE=InnoDB;

-- Player statistics
CREATE TABLE player_stats (
    stat_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    player_id BIGINT UNSIGNED NOT NULL,
    game_id BIGINT UNSIGNED NOT NULL,

    -- General Stats
    matches_played INT DEFAULT 0,
    matches_won INT DEFAULT 0,
    matches_lost INT DEFAULT 0,
    matches_drawn INT DEFAULT 0,
    win_rate DECIMAL(5,2) GENERATED ALWAYS AS
        (CASE WHEN matches_played > 0
            THEN (matches_won * 100.0 / matches_played)
            ELSE 0
        END) STORED,

    -- Combat Stats
    total_kills INT DEFAULT 0,
    total_deaths INT DEFAULT 0,
    total_assists INT DEFAULT 0,
    kd_ratio DECIMAL(10,2) GENERATED ALWAYS AS
        (CASE WHEN total_deaths > 0
            THEN (total_kills / total_deaths)
            ELSE total_kills
        END) STORED,

    -- Skill Rating
    current_rating INT DEFAULT 1000,
    peak_rating INT DEFAULT 1000,
    current_rank VARCHAR(50),
    current_tier INT,

    -- Time Stats
    playtime_hours DECIMAL(10,2) DEFAULT 0,
    longest_session_hours DECIMAL(10,2) DEFAULT 0,

    -- Streaks
    current_win_streak INT DEFAULT 0,
    longest_win_streak INT DEFAULT 0,

    -- Last Update
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (stat_id),
    UNIQUE KEY uk_player_game (player_id, game_id),
    INDEX idx_player (player_id),
    INDEX idx_game (game_id),
    INDEX idx_rating (current_rating DESC),
    INDEX idx_wins (matches_won DESC),
    FOREIGN KEY (player_id) REFERENCES players(player_id),
    FOREIGN KEY (game_id) REFERENCES games(game_id)
) ENGINE=InnoDB;

-- ============================================================================
-- TOURNAMENTS & COMPETITIONS
-- ============================================================================

-- Tournaments
CREATE TABLE tournaments (
    tournament_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    game_id BIGINT UNSIGNED NOT NULL,

    -- Tournament Info
    name VARCHAR(255) NOT NULL,
    description TEXT,
    tournament_type ENUM('single_elimination', 'double_elimination', 'round_robin', 'swiss', 'league') DEFAULT 'single_elimination',

    -- Timing
    registration_start TIMESTAMP NOT NULL,
    registration_end TIMESTAMP NOT NULL,
    tournament_start TIMESTAMP NOT NULL,
    tournament_end TIMESTAMP NULL,

    -- Participation
    max_participants INT NOT NULL,
    current_participants INT DEFAULT 0,
    entry_fee DECIMAL(10,2),
    entry_currency_id INT UNSIGNED,
    min_rating INT,
    min_level INT DEFAULT 1,

    -- Prizes
    prize_pool JSON, -- {position: {currency_id: amount}}
    total_prize_value DECIMAL(10,2),

    -- Status
    status ENUM('upcoming', 'registration', 'in_progress', 'completed', 'cancelled') DEFAULT 'upcoming',

    -- Settings
    format JSON, -- Tournament specific settings
    rules TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (tournament_id),
    INDEX idx_game (game_id),
    INDEX idx_status (status),
    INDEX idx_start (tournament_start),
    FOREIGN KEY (game_id) REFERENCES games(game_id),
    FOREIGN KEY (entry_currency_id) REFERENCES currencies(currency_id)
) ENGINE=InnoDB;

-- Tournament participants
CREATE TABLE tournament_participants (
    participant_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    tournament_id BIGINT UNSIGNED NOT NULL,
    player_id BIGINT UNSIGNED,
    team_id BIGINT UNSIGNED,

    -- Registration
    registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    seed_number INT,

    -- Progress
    current_round INT DEFAULT 0,
    matches_played INT DEFAULT 0,
    matches_won INT DEFAULT 0,

    -- Results
    final_position INT,
    prizes_won JSON,
    is_eliminated BOOLEAN DEFAULT FALSE,
    eliminated_round INT,

    PRIMARY KEY (participant_id),
    UNIQUE KEY uk_tournament_player (tournament_id, player_id),
    INDEX idx_tournament (tournament_id),
    INDEX idx_player (player_id),
    INDEX idx_position (final_position),
    FOREIGN KEY (tournament_id) REFERENCES tournaments(tournament_id),
    FOREIGN KEY (player_id) REFERENCES players(player_id)
) ENGINE=InnoDB;

-- ============================================================================
-- LEADERBOARDS
-- ============================================================================

-- Leaderboard definitions
CREATE TABLE leaderboards (
    leaderboard_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    game_id BIGINT UNSIGNED,

    -- Leaderboard Info
    name VARCHAR(255) NOT NULL,
    leaderboard_type ENUM('global', 'regional', 'friends', 'clan') DEFAULT 'global',
    stat_tracked VARCHAR(100), -- 'rating', 'wins', 'score', etc

    -- Reset Period
    reset_frequency ENUM('never', 'daily', 'weekly', 'monthly', 'seasonal') DEFAULT 'never',
    last_reset TIMESTAMP NULL,
    next_reset TIMESTAMP NULL,

    -- Rewards
    rewards JSON, -- Position-based rewards

    -- Status
    is_active BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (leaderboard_id),
    INDEX idx_game (game_id),
    INDEX idx_active (is_active),
    FOREIGN KEY (game_id) REFERENCES games(game_id)
) ENGINE=InnoDB;

-- Leaderboard entries
CREATE TABLE leaderboard_entries (
    entry_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    leaderboard_id BIGINT UNSIGNED NOT NULL,
    player_id BIGINT UNSIGNED NOT NULL,

    -- Score/Value
    score BIGINT NOT NULL,
    rank_position INT,

    -- Metadata
    extra_data JSON, -- Additional display data

    -- Timestamps
    achieved_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (entry_id),
    UNIQUE KEY uk_leaderboard_player (leaderboard_id, player_id),
    INDEX idx_leaderboard_score (leaderboard_id, score DESC),
    INDEX idx_player (player_id),
    FOREIGN KEY (leaderboard_id) REFERENCES leaderboards(leaderboard_id),
    FOREIGN KEY (player_id) REFERENCES players(player_id)
) ENGINE=InnoDB;

-- ============================================================================
-- ANTI-CHEAT & MODERATION
-- ============================================================================

-- Player reports
CREATE TABLE player_reports (
    report_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    reporter_id BIGINT UNSIGNED NOT NULL,
    reported_id BIGINT UNSIGNED NOT NULL,

    -- Context
    match_id BIGINT UNSIGNED,
    game_id BIGINT UNSIGNED,

    -- Report Details
    report_type ENUM('cheating', 'griefing', 'toxic_behavior', 'inappropriate_name', 'spam', 'other') NOT NULL,
    description TEXT,
    evidence_url VARCHAR(500),

    -- Review
    status ENUM('pending', 'reviewing', 'validated', 'dismissed') DEFAULT 'pending',
    reviewed_by BIGINT UNSIGNED,
    reviewed_at TIMESTAMP NULL,
    review_notes TEXT,

    -- Action Taken
    action_taken ENUM('none', 'warning', 'temp_ban', 'permanent_ban', 'chat_restriction'),
    action_duration_hours INT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (report_id),
    INDEX idx_reported (reported_id),
    INDEX idx_status (status),
    INDEX idx_created (created_at DESC),
    FOREIGN KEY (reporter_id) REFERENCES players(player_id),
    FOREIGN KEY (reported_id) REFERENCES players(player_id),
    FOREIGN KEY (match_id) REFERENCES match_sessions(match_id),
    FOREIGN KEY (game_id) REFERENCES games(game_id)
) ENGINE=InnoDB;

-- Ban history
CREATE TABLE ban_history (
    ban_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    player_id BIGINT UNSIGNED NOT NULL,

    -- Ban Details
    ban_type ENUM('temporary', 'permanent', 'vac', 'chat', 'trade') NOT NULL,
    reason TEXT,
    evidence TEXT,

    -- Duration
    banned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NULL,
    is_active BOOLEAN DEFAULT TRUE,

    -- Admin
    banned_by BIGINT UNSIGNED,
    lifted_by BIGINT UNSIGNED,
    lifted_at TIMESTAMP NULL,
    lift_reason TEXT,

    PRIMARY KEY (ban_id),
    INDEX idx_player (player_id),
    INDEX idx_active (is_active, expires_at),
    INDEX idx_type (ban_type),
    FOREIGN KEY (player_id) REFERENCES players(player_id)
) ENGINE=InnoDB;
