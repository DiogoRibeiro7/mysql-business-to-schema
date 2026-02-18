# 🎮 Gaming Platform

A comprehensive MySQL database schema for a modern gaming platform supporting multiple games, real-time multiplayer, in-game economies, social features, tournaments, and advanced analytics - similar to Steam, Epic Games, or Xbox Live.

## 📊 Database Overview

- **Industry**: Gaming / Entertainment
- **Complexity**: Very High
- **Tables**: 38
- **Key Features**: Multiplayer Matchmaking, Virtual Economy, Social Network, Tournaments
- **Data Volume**: Designed for millions of players and billions of events
- **Partitioning**: Chat messages by year for performance

## 🗂️ Schema Structure

### Player Management

1. **players** - Platform users/gamers
   - Profile and preferences
   - Level and XP progression system
   - Premium subscription tracking
   - Anti-cheat trust scoring
   - Privacy settings
   - VAC ban tracking

2. **player_sessions** - Active sessions
   - Multi-platform support (PC, console, mobile)
   - Session token management
   - Geographic tracking
   - Device fingerprinting

### Game Catalog

1. **games** - Available games
   - Multi-platform support
   - Pricing and discounts
   - Content ratings (ESRB)
   - Multiplayer capabilities
   - Real-time player counts
   - Review scores

2. **player_games** - Game ownership
   - Purchase history
   - Play time tracking
   - Installation status
   - Favorites management

### Multiplayer Infrastructure

1. **game_servers** - Dedicated servers
   - Regional distribution
   - Capacity management
   - Game mode configuration
   - Performance metrics (tick rate, ping)

2. **match_sessions** - Game matches
   - Multiple match types (quick, ranked, tournament)
   - Status lifecycle
   - Results tracking

3. **match_participants** - Players in matches
   - Performance statistics
   - Skill rating changes
   - Behavior tracking
   - Reward distribution

4. **matchmaking_queue** - Player matching
   - Skill-based matching
   - Party support
   - Regional preferences
   - Queue time tracking

### Social Features

1. **friendships** - Friend relationships
   - Request/accept workflow
   - Block functionality
   - Favorite friends
   - Custom nicknames

2. **clans** - Gaming communities
   - Hierarchical roles
   - Member limits
   - Statistics tracking
   - Clan progression

3. **clan_members** - Clan rosters
   - Role management
   - Contribution tracking
   - Activity monitoring

4. **chat_messages** - Communication
   - Multiple channel types
   - Message editing
   - Moderation features
   - Attachment support
   - Year-based partitioning

### Economy System

1. **currencies** - Virtual money types
   - Premium vs standard
   - USD exchange rates
   - Trading restrictions

2. **player_wallets** - Balance management
   - Multi-currency support
   - Transaction history
   - Spending limits

3. **store_items** - Digital goods
   - Games, DLC, cosmetics
   - Dynamic pricing
   - Stock limits
   - Time-limited offers

4. **transactions** - Financial records
   - Purchase tracking
   - Refund support
   - Payment methods
   - External references

### Progression & Achievements

1. **achievements** - Goals and milestones
   - Multi-tier system (bronze to platinum)
   - Hidden achievements
   - Seasonal events
   - Rarity tracking

2. **player_achievements** - Progress tracking
   - Partial completion
   - Time tracking
   - Reward distribution

3. **player_stats** - Performance metrics
   - Per-game statistics
   - Win rates, K/D ratios
   - Skill ratings
   - Play time tracking

### Competitive Gaming

1. **tournaments** - Organized competitions
   - Multiple formats (elimination, round-robin, etc.)
   - Entry fees and prizes
   - Registration management
   - Bracket generation

2. **tournament_participants** - Competitors
   - Seeding system
   - Progress tracking
   - Prize distribution

3. **leaderboards** - Rankings
   - Global, regional, friends
   - Reset schedules
   - Reward tiers

4. **leaderboard_entries** - Player rankings
   - Score tracking
   - Rank calculation
   - Metadata storage

### Moderation & Safety

1. **player_reports** - User complaints
   - Multiple report types
   - Evidence submission
   - Review workflow
   - Action tracking

2. **ban_history** - Punishment records
   - Temporary and permanent bans
   - VAC bans
   - Appeal process
   - Automatic expiry

## 🔑 Key Features

### Real-Time Multiplayer
- **Matchmaking Algorithm**: Skill-based with regional preferences
- **Server Browser**: Filter by region, game mode, ping
- **Party System**: Group queueing for teams
- **Spectator Mode**: Watch live matches
- **Replay System**: Match recording and playback

### Virtual Economy
- **Multiple Currencies**: Premium, standard, event-specific
- **Marketplace**: Player-to-player trading
- **Loot Boxes**: Randomized rewards
- **Battle Pass**: Seasonal progression
- **Refund System**: Automated and manual

### Social Network
- **Friend System**: Add, block, favorite
- **Clan/Guild System**: Organized groups with hierarchy
- **Chat System**: Text, voice, video support
- **Activity Feed**: Friend updates and achievements
- **Profile Customization**: Avatars, banners, showcases

### Progression Systems
- **Player Levels**: XP-based with prestige
- **Achievement System**: Goals with rewards
- **Daily Quests**: Engagement incentives
- **Season Pass**: Time-limited content
- **Skill Rankings**: ELO/MMR systems

### Anti-Cheat & Moderation
- **Trust Score**: Behavior-based reputation
- **VAC System**: Anti-cheat integration
- **Report System**: Community moderation
- **Auto-moderation**: Chat filters and detection
- **Appeal Process**: Ban reviews

## 📈 Use Cases

### Common Queries

1. **Find Online Friends Playing Same Game**
```sql
SELECT
    f.friend_id,
    p.display_name,
    p.last_activity_at,
    pg.game_id,
    g.title,
    pg.last_played_at
FROM friendships f
JOIN players p ON f.friend_id = p.player_id
JOIN player_games pg ON p.player_id = pg.player_id
JOIN games g ON pg.game_id = g.game_id
JOIN player_sessions ps ON p.player_id = ps.player_id
WHERE f.player_id = 1
    AND f.status = 'accepted'
    AND ps.is_active = TRUE
    AND ps.last_activity_at >= DATE_SUB(NOW(), INTERVAL 5 MINUTE)
    AND pg.last_played_at >= DATE_SUB(NOW(), INTERVAL 5 MINUTE)
ORDER BY f.is_favorite DESC, p.display_name;
```

2. **Matchmaking Query**
```sql
-- Find suitable opponents for matchmaking
WITH player_skill AS (
    SELECT skill_rating, preferred_region
    FROM matchmaking_queue
    WHERE player_id = 1 AND status = 'searching'
)
SELECT
    mq.queue_id,
    mq.player_id,
    p.display_name,
    mq.skill_rating,
    ABS(mq.skill_rating - ps.skill_rating) as skill_diff,
    mq.preferred_region,
    mq.party_size,
    TIMESTAMPDIFF(SECOND, mq.queued_at, NOW()) as wait_seconds
FROM matchmaking_queue mq
JOIN players p ON mq.player_id = p.player_id
CROSS JOIN player_skill ps
WHERE mq.game_id = 1
    AND mq.game_mode = 'ranked'
    AND mq.status = 'searching'
    AND mq.player_id != 1
    AND ABS(mq.skill_rating - ps.skill_rating) <= 200
    AND (mq.preferred_region = ps.preferred_region OR mq.preferred_region IS NULL)
ORDER BY skill_diff, wait_seconds DESC
LIMIT 9; -- For 5v5 match
```

3. **Calculate Player Level from XP**
```sql
-- Level progression with prestige system
SELECT
    player_id,
    display_name,
    total_xp,
    FLOOR(SQRT(total_xp / 100)) as calculated_level,
    FLOOR(FLOOR(SQRT(total_xp / 100)) / 100) as prestige,
    (FLOOR(SQRT(total_xp / 100)) MOD 100) as display_level,
    POWER(((FLOOR(SQRT(total_xp / 100)) + 1)), 2) * 100 - total_xp as xp_to_next_level
FROM players
WHERE player_id = 1;
```

4. **Tournament Bracket Generation**
```sql
-- Generate tournament matchups for current round
SELECT
    tp1.seed_number as seed1,
    p1.display_name as player1,
    tp2.seed_number as seed2,
    p2.display_name as player2,
    tp1.current_round as round
FROM tournament_participants tp1
JOIN tournament_participants tp2 ON tp1.tournament_id = tp2.tournament_id
    AND tp1.current_round = tp2.current_round
    AND tp1.seed_number < tp2.seed_number
    AND tp1.seed_number + tp2.seed_number = POWER(2, CEIL(LOG2(
        (SELECT COUNT(*) FROM tournament_participants WHERE tournament_id = tp1.tournament_id)
    ))) + 1
JOIN players p1 ON tp1.player_id = p1.player_id
JOIN players p2 ON tp2.player_id = p2.player_id
WHERE tp1.tournament_id = 1
    AND tp1.is_eliminated = FALSE
    AND tp2.is_eliminated = FALSE
ORDER BY tp1.current_round, tp1.seed_number;
```

5. **Store Recommendations**
```sql
-- Recommend games based on play history and friends
WITH played_genres AS (
    SELECT DISTINCT JSON_UNQUOTE(JSON_EXTRACT(g.genre, '$[*]')) as genre
    FROM player_games pg
    JOIN games g ON pg.game_id = g.game_id
    WHERE pg.player_id = 1
),
friend_games AS (
    SELECT pg.game_id, COUNT(*) as friend_count
    FROM friendships f
    JOIN player_games pg ON f.friend_id = pg.player_id
    WHERE f.player_id = 1 AND f.status = 'accepted'
    GROUP BY pg.game_id
)
SELECT
    g.game_id,
    g.title,
    g.current_price,
    g.discount_percentage,
    g.user_score,
    fg.friend_count as friends_playing,
    CASE
        WHEN g.discount_percentage > 50 THEN 'Great Deal!'
        WHEN fg.friend_count > 3 THEN 'Friends Playing'
        WHEN g.user_score > 8 THEN 'Highly Rated'
        ELSE 'Recommended'
    END as recommendation_reason
FROM games g
LEFT JOIN friend_games fg ON g.game_id = fg.game_id
WHERE g.status = 'available'
    AND g.game_id NOT IN (SELECT game_id FROM player_games WHERE player_id = 1)
    AND (
        EXISTS (
            SELECT 1 FROM played_genres pg
            WHERE JSON_CONTAINS(g.genre, JSON_QUOTE(pg.genre))
        )
        OR fg.friend_count > 0
    )
ORDER BY
    fg.friend_count DESC,
    g.discount_percentage DESC,
    g.user_score DESC
LIMIT 10;
```

## 🚀 Getting Started

### 1. Create Database
```bash
mysql -u root -p < schema/00_create_database.sql
```

### 2. Create Schema
```bash
mysql -u root -p gaming_platform < schema/01_tables.sql
mysql -u root -p gaming_platform < schema/02_constraints.sql
mysql -u root -p gaming_platform < schema/03_indexes.sql
```

### 3. Load Sample Data (when available)
```bash
mysql -u root -p gaming_platform < data/01_currencies.sql
mysql -u root -p gaming_platform < data/02_games.sql
mysql -u root -p gaming_platform < data/03_achievements.sql
```

### 4. Generate Test Data (when generator is ready)
```bash
cd generators/gaming_platform
python generator.py --players 100000 --games 500 --matches 1000000
```

## 📋 Business Rules

### Account Management
- Usernames must be unique and 3-50 characters
- Email verification required for trading
- 2FA optional but recommended for high-value accounts
- Trust score affects matchmaking and trading
- VAC bans are permanent and cross-game

### Matchmaking Rules
- Skill-based matching with expanding range over time
- Party members matched together
- Regional preferences respected when possible
- Abandon penalties for leaving matches early
- Skill rating updates after every ranked match

### Economy Rules
- Premium currency purchased with real money
- Standard currency earned through gameplay
- Trading restrictions based on account age and trust
- Refunds available within 14 days and < 2 hours played
- Regional pricing adjustments

### Social Rules
- Friend limit of 500 (1000 for premium)
- Clan size limited by clan level
- Chat message retention for 30 days
- Automatic moderation for prohibited content
- Report threshold triggers automatic review

### Tournament Rules
- Entry requirements (level, rating, fee)
- Seeding based on skill rating
- Prize distribution based on placement
- Automatic bracket progression
- Dispute resolution process

## 🔍 Indexes

Optimized for gaming workloads:

- **Authentication**: Username and email lookups
- **Matchmaking**: Skill and region-based queries
- **Social**: Friend lists and clan rosters
- **Store**: Browsing and recommendations
- **Leaderboards**: Top player queries
- **Moderation**: Report queues and ban checks

## 📊 Performance Considerations

### Scaling Strategies
- **Sharding**: By player_id for horizontal scaling
- **Read Replicas**: For leaderboards and statistics
- **Caching**: Redis for session and matchmaking
- **CDN**: Game assets and store images
- **Message Queue**: Match events and notifications

### Real-Time Requirements
- Match state updates: < 50ms
- Chat delivery: < 100ms
- Leaderboard updates: < 1 second
- Store transactions: < 500ms
- Friend status changes: < 200ms

### Data Retention
- Match history: 90 days (summary forever)
- Chat messages: 30 days
- Detailed statistics: 1 year
- Achievements: Permanent
- Transaction history: 7 years

## 🎯 Learning Objectives

This example demonstrates:

1. **Complex Relationships** - Many-to-many social connections
2. **Real-Time Systems** - Matchmaking and game sessions
3. **Virtual Economies** - Multi-currency with transactions
4. **Progression Systems** - XP, levels, achievements
5. **Competitive Gaming** - Tournaments and leaderboards
6. **Content Moderation** - Reports and automated enforcement
7. **Analytics** - Player behavior and engagement tracking

## 🔧 Customization Options

### Additional Features to Consider

1. **Battle Royale Mode**
```sql
CREATE TABLE battle_royale_matches (
    br_match_id BIGINT UNSIGNED PRIMARY KEY,
    match_id BIGINT UNSIGNED,
    starting_players INT,
    safe_zone_phase INT,
    winner_player_id BIGINT UNSIGNED,
    match_duration_seconds INT,
    FOREIGN KEY (match_id) REFERENCES match_sessions(match_id)
);
```

2. **Streaming Integration**
```sql
CREATE TABLE player_streams (
    stream_id BIGINT UNSIGNED PRIMARY KEY,
    player_id BIGINT UNSIGNED,
    platform ENUM('twitch', 'youtube', 'facebook'),
    stream_url VARCHAR(500),
    viewer_count INT,
    is_live BOOLEAN DEFAULT TRUE,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (player_id) REFERENCES players(player_id)
);
```

3. **Esports Teams**
```sql
CREATE TABLE esports_teams (
    team_id BIGINT UNSIGNED PRIMARY KEY,
    organization_name VARCHAR(255),
    team_name VARCHAR(255),
    founded_date DATE,
    total_earnings DECIMAL(15,2),
    world_ranking INT
);
```

## 🛠️ Technologies

- **Database**: MySQL 8.0+ with JSON support
- **Engine**: InnoDB for ACID compliance
- **Partitioning**: Time-based for chat and events
- **Character Set**: utf8mb4 for emoji support
- **Collation**: utf8mb4_unicode_ci

## 📚 Additional Resources

- [Database Design for Gaming](https://www.gamedeveloper.com/programming/database-design)
- [Matchmaking Algorithms](https://www.gamedev.net/articles/programming/networking-and-multiplayer/)
- [Virtual Economy Design](https://www.gamesindustry.biz/articles/)
- [Anti-Cheat Systems](https://technology.riotgames.com/)

## 🤝 Contributing

Areas for improvement:
1. Add voice chat room management
2. Implement item trading marketplace
3. Add cloud save synchronization
4. Create coaching/mentorship system
5. Add tournament streaming integration

## 📝 License

Part of the MySQL Business-to-Schema project, MIT License.