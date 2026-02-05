-- =========================================
-- Social Media Platform - Core Tables
-- =========================================

USE social_media;

-- =========================================
-- 1. USER MANAGEMENT TABLES
-- =========================================

CREATE TABLE IF NOT EXISTS users (
    user_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(30) NOT NULL,
    email VARCHAR(255) NOT NULL,
    email_verified BOOLEAN DEFAULT FALSE,
    password_hash VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20),
    phone_verified BOOLEAN DEFAULT FALSE,
    status ENUM('active', 'suspended', 'banned', 'deleted') DEFAULT 'active',
    account_type ENUM('personal', 'business', 'creator', 'verified') DEFAULT 'personal',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_active TIMESTAMP NULL,
    deleted_at TIMESTAMP NULL,
    UNIQUE INDEX idx_username (username),
    UNIQUE INDEX idx_email (email),
    INDEX idx_status (status),
    INDEX idx_created (created_at DESC)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS user_profiles (
    profile_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    display_name VARCHAR(100),
    bio TEXT,
    profile_picture_url VARCHAR(500),
    cover_picture_url VARCHAR(500),
    website VARCHAR(255),
    location VARCHAR(100),
    birth_date DATE,
    gender ENUM('male', 'female', 'other', 'prefer_not_to_say'),
    language VARCHAR(10) DEFAULT 'en',
    timezone VARCHAR(50) DEFAULT 'UTC',
    is_private BOOLEAN DEFAULT FALSE,
    verified_badge BOOLEAN DEFAULT FALSE,
    follower_count INT UNSIGNED DEFAULT 0,
    following_count INT UNSIGNED DEFAULT 0,
    post_count INT UNSIGNED DEFAULT 0,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_user_profile (user_id),
    FULLTEXT INDEX ft_bio (bio),
    FULLTEXT INDEX ft_display_name (display_name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS user_settings (
    setting_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    notification_email BOOLEAN DEFAULT TRUE,
    notification_push BOOLEAN DEFAULT TRUE,
    notification_sms BOOLEAN DEFAULT FALSE,
    privacy_profile_visibility ENUM('public', 'friends', 'private') DEFAULT 'public',
    privacy_message_requests ENUM('everyone', 'friends', 'none') DEFAULT 'friends',
    privacy_show_activity_status BOOLEAN DEFAULT TRUE,
    privacy_show_read_receipts BOOLEAN DEFAULT TRUE,
    content_filter_sensitive BOOLEAN DEFAULT FALSE,
    content_filter_violence BOOLEAN DEFAULT TRUE,
    content_language_preferences JSON,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    UNIQUE INDEX idx_user_settings (user_id)
) ENGINE=InnoDB;

-- =========================================
-- 2. SOCIAL GRAPH TABLES
-- =========================================

CREATE TABLE IF NOT EXISTS relationships (
    relationship_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    from_user_id BIGINT UNSIGNED NOT NULL,
    to_user_id BIGINT UNSIGNED NOT NULL,
    relationship_type ENUM('follow', 'friend', 'block', 'mute') NOT NULL,
    status ENUM('active', 'pending', 'removed') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (from_user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (to_user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    UNIQUE INDEX idx_relationship (from_user_id, to_user_id, relationship_type),
    INDEX idx_from_user (from_user_id, relationship_type, status),
    INDEX idx_to_user (to_user_id, relationship_type, status),
    INDEX idx_created (created_at DESC)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS relationship_requests (
    request_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    from_user_id BIGINT UNSIGNED NOT NULL,
    to_user_id BIGINT UNSIGNED NOT NULL,
    request_type ENUM('follow', 'friend') NOT NULL,
    status ENUM('pending', 'accepted', 'rejected', 'cancelled') DEFAULT 'pending',
    message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    responded_at TIMESTAMP NULL,
    FOREIGN KEY (from_user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (to_user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    UNIQUE INDEX idx_pending_request (from_user_id, to_user_id, request_type, status),
    INDEX idx_to_user_pending (to_user_id, status),
    INDEX idx_created (created_at DESC)
) ENGINE=InnoDB;

-- =========================================
-- 3. CONTENT TABLES
-- =========================================

CREATE TABLE IF NOT EXISTS posts (
    post_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    parent_post_id BIGINT UNSIGNED, -- For reposts/quotes
    content TEXT,
    post_type ENUM('text', 'image', 'video', 'link', 'poll', 'story') NOT NULL,
    visibility ENUM('public', 'friends', 'private', 'custom') DEFAULT 'public',
    is_edited BOOLEAN DEFAULT FALSE,
    edit_history JSON, -- Stores previous versions
    location VARCHAR(255),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    view_count INT UNSIGNED DEFAULT 0,
    share_count INT UNSIGNED DEFAULT 0,
    comment_count INT UNSIGNED DEFAULT 0,
    like_count INT UNSIGNED DEFAULT 0,
    engagement_score DECIMAL(10, 4) DEFAULT 0, -- Calculated metric
    is_promoted BOOLEAN DEFAULT FALSE,
    is_archived BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (parent_post_id) REFERENCES posts(post_id) ON DELETE SET NULL,
    INDEX idx_user_posts (user_id, created_at DESC),
    INDEX idx_visibility (visibility, created_at DESC),
    INDEX idx_parent_post (parent_post_id),
    INDEX idx_engagement (engagement_score DESC),
    INDEX idx_created (created_at DESC),
    FULLTEXT INDEX ft_content (content)
) ENGINE=InnoDB PARTITION BY RANGE (YEAR(created_at)) (
    PARTITION p2023 VALUES LESS THAN (2024),
    PARTITION p2024 VALUES LESS THAN (2025),
    PARTITION p2025 VALUES LESS THAN (2026),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);

CREATE TABLE IF NOT EXISTS post_media (
    media_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    post_id BIGINT UNSIGNED NOT NULL,
    media_type ENUM('image', 'video', 'audio', 'document') NOT NULL,
    media_url VARCHAR(500) NOT NULL,
    thumbnail_url VARCHAR(500),
    media_metadata JSON, -- Dimensions, duration, format, etc.
    display_order INT DEFAULT 0,
    alt_text TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES posts(post_id) ON DELETE CASCADE,
    INDEX idx_post_media (post_id, display_order)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS comments (
    comment_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    post_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    parent_comment_id BIGINT UNSIGNED, -- For nested comments
    content TEXT NOT NULL,
    like_count INT UNSIGNED DEFAULT 0,
    is_edited BOOLEAN DEFAULT FALSE,
    is_hidden BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (post_id) REFERENCES posts(post_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (parent_comment_id) REFERENCES comments(comment_id) ON DELETE CASCADE,
    INDEX idx_post_comments (post_id, created_at),
    INDEX idx_parent_comment (parent_comment_id),
    INDEX idx_user_comments (user_id, created_at DESC),
    FULLTEXT INDEX ft_comment_content (content)
) ENGINE=InnoDB;

-- =========================================
-- 4. ENGAGEMENT TABLES
-- =========================================

CREATE TABLE IF NOT EXISTS reactions (
    reaction_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    target_type ENUM('post', 'comment', 'message') NOT NULL,
    target_id BIGINT UNSIGNED NOT NULL,
    reaction_type ENUM('like', 'love', 'haha', 'wow', 'sad', 'angry') DEFAULT 'like',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    UNIQUE INDEX idx_user_reaction (user_id, target_type, target_id),
    INDEX idx_target (target_type, target_id),
    INDEX idx_created (created_at DESC)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS shares (
    share_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    post_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    share_type ENUM('repost', 'quote', 'message', 'external') NOT NULL,
    share_text TEXT, -- For quote tweets
    platform VARCHAR(50), -- For external shares
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES posts(post_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_post_shares (post_id, created_at DESC),
    INDEX idx_user_shares (user_id, created_at DESC)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS bookmarks (
    bookmark_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    post_id BIGINT UNSIGNED NOT NULL,
    collection_name VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (post_id) REFERENCES posts(post_id) ON DELETE CASCADE,
    UNIQUE INDEX idx_user_bookmark (user_id, post_id),
    INDEX idx_user_collection (user_id, collection_name),
    INDEX idx_created (created_at DESC)
) ENGINE=InnoDB;

-- =========================================
-- 5. HASHTAG & TRENDING TABLES
-- =========================================

CREATE TABLE IF NOT EXISTS hashtags (
    hashtag_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tag VARCHAR(100) NOT NULL,
    tag_normalized VARCHAR(100) NOT NULL, -- Lowercase, no special chars
    post_count INT UNSIGNED DEFAULT 0,
    weekly_count INT UNSIGNED DEFAULT 0,
    daily_count INT UNSIGNED DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_used TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE INDEX idx_tag_normalized (tag_normalized),
    INDEX idx_post_count (post_count DESC),
    INDEX idx_weekly_count (weekly_count DESC),
    INDEX idx_daily_count (daily_count DESC)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS post_hashtags (
    post_hashtag_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    post_id BIGINT UNSIGNED NOT NULL,
    hashtag_id BIGINT UNSIGNED NOT NULL,
    position INT, -- Position in post text
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES posts(post_id) ON DELETE CASCADE,
    FOREIGN KEY (hashtag_id) REFERENCES hashtags(hashtag_id) ON DELETE CASCADE,
    UNIQUE INDEX idx_post_hashtag (post_id, hashtag_id),
    INDEX idx_hashtag_posts (hashtag_id, created_at DESC)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS trending_topics (
    trend_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    trend_type ENUM('hashtag', 'keyword', 'event') NOT NULL,
    trend_value VARCHAR(100) NOT NULL,
    region VARCHAR(50) DEFAULT 'global',
    score DECIMAL(10, 4) NOT NULL, -- Trending score
    velocity DECIMAL(10, 4), -- Rate of increase
    post_count INT UNSIGNED DEFAULT 0,
    user_count INT UNSIGNED DEFAULT 0,
    start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    peak_time TIMESTAMP NULL,
    end_time TIMESTAMP NULL,
    INDEX idx_region_score (region, score DESC),
    INDEX idx_active_trends (end_time, region, score DESC)
) ENGINE=InnoDB;

-- =========================================
-- 6. MESSAGING TABLES
-- =========================================

CREATE TABLE IF NOT EXISTS conversations (
    conversation_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    conversation_type ENUM('direct', 'group') NOT NULL,
    title VARCHAR(255),
    description TEXT,
    creator_user_id BIGINT UNSIGNED,
    is_archived BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_message_at TIMESTAMP NULL,
    FOREIGN KEY (creator_user_id) REFERENCES users(user_id) ON DELETE SET NULL,
    INDEX idx_last_message (last_message_at DESC)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS conversation_participants (
    participant_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    conversation_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    role ENUM('member', 'admin', 'owner') DEFAULT 'member',
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_read_at TIMESTAMP NULL,
    is_muted BOOLEAN DEFAULT FALSE,
    left_at TIMESTAMP NULL,
    FOREIGN KEY (conversation_id) REFERENCES conversations(conversation_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    UNIQUE INDEX idx_conversation_user (conversation_id, user_id),
    INDEX idx_user_conversations (user_id, left_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS messages (
    message_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    conversation_id BIGINT UNSIGNED NOT NULL,
    sender_user_id BIGINT UNSIGNED NOT NULL,
    message_type ENUM('text', 'image', 'video', 'file', 'voice') DEFAULT 'text',
    content TEXT,
    media_url VARCHAR(500),
    is_edited BOOLEAN DEFAULT FALSE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    edited_at TIMESTAMP NULL,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (conversation_id) REFERENCES conversations(conversation_id) ON DELETE CASCADE,
    FOREIGN KEY (sender_user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_conversation_messages (conversation_id, created_at DESC),
    INDEX idx_sender_messages (sender_user_id, created_at DESC)
) ENGINE=InnoDB;

-- =========================================
-- 7. NOTIFICATIONS TABLES
-- =========================================

CREATE TABLE IF NOT EXISTS notifications (
    notification_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    type ENUM('like', 'comment', 'follow', 'mention', 'share', 'message', 'friend_request') NOT NULL,
    actor_user_id BIGINT UNSIGNED,
    target_type ENUM('post', 'comment', 'user', 'message'),
    target_id BIGINT UNSIGNED,
    title VARCHAR(255),
    body TEXT,
    data JSON, -- Additional context
    is_read BOOLEAN DEFAULT FALSE,
    is_pushed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (actor_user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_user_unread (user_id, is_read, created_at DESC),
    INDEX idx_created (created_at DESC)
) ENGINE=InnoDB;

-- =========================================
-- 8. MODERATION TABLES
-- =========================================

CREATE TABLE IF NOT EXISTS reports (
    report_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    reporter_user_id BIGINT UNSIGNED NOT NULL,
    reported_type ENUM('post', 'comment', 'user', 'message') NOT NULL,
    reported_id BIGINT UNSIGNED NOT NULL,
    reason ENUM('spam', 'harassment', 'hate_speech', 'violence', 'nudity', 'misinformation', 'other') NOT NULL,
    description TEXT,
    status ENUM('pending', 'reviewing', 'actioned', 'dismissed') DEFAULT 'pending',
    priority ENUM('low', 'medium', 'high', 'critical') DEFAULT 'medium',
    moderator_id BIGINT UNSIGNED,
    action_taken ENUM('none', 'warning', 'content_removed', 'account_suspended', 'account_banned'),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reviewed_at TIMESTAMP NULL,
    FOREIGN KEY (reporter_user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_status_priority (status, priority DESC, created_at),
    INDEX idx_reported (reported_type, reported_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS banned_content (
    ban_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    content_type ENUM('keyword', 'url', 'media_hash') NOT NULL,
    content_value VARCHAR(500) NOT NULL,
    severity ENUM('low', 'medium', 'high', 'critical') DEFAULT 'medium',
    reason TEXT,
    added_by BIGINT UNSIGNED,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NULL,
    UNIQUE INDEX idx_content (content_type, content_value),
    INDEX idx_active (is_active, content_type)
) ENGINE=InnoDB;

-- =========================================
-- 9. ANALYTICS TABLES
-- =========================================

CREATE TABLE IF NOT EXISTS user_activity_logs (
    log_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    action_type ENUM('view', 'click', 'scroll', 'search', 'share') NOT NULL,
    target_type VARCHAR(50),
    target_id BIGINT UNSIGNED,
    session_id VARCHAR(100),
    ip_address VARCHAR(45),
    user_agent VARCHAR(500),
    referrer VARCHAR(500),
    duration_ms INT,
    metadata JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_activity (user_id, created_at DESC),
    INDEX idx_session (session_id),
    INDEX idx_action_type (action_type, created_at DESC)
) ENGINE=InnoDB PARTITION BY RANGE (TO_DAYS(created_at)) (
    PARTITION p0 VALUES LESS THAN (TO_DAYS('2024-01-01')),
    PARTITION p1 VALUES LESS THAN (TO_DAYS('2024-04-01')),
    PARTITION p2 VALUES LESS THAN (TO_DAYS('2024-07-01')),
    PARTITION p3 VALUES LESS THAN (TO_DAYS('2024-10-01')),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);

CREATE TABLE IF NOT EXISTS engagement_metrics (
    metric_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    metric_date DATE NOT NULL,
    metric_hour TINYINT,
    metric_type ENUM('post', 'user', 'hashtag') NOT NULL,
    entity_id BIGINT UNSIGNED NOT NULL,
    impressions INT UNSIGNED DEFAULT 0,
    engagements INT UNSIGNED DEFAULT 0,
    clicks INT UNSIGNED DEFAULT 0,
    shares INT UNSIGNED DEFAULT 0,
    comments INT UNSIGNED DEFAULT 0,
    likes INT UNSIGNED DEFAULT 0,
    reach INT UNSIGNED DEFAULT 0, -- Unique users
    engagement_rate DECIMAL(5, 4), -- Calculated
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE INDEX idx_metric (metric_date, metric_hour, metric_type, entity_id),
    INDEX idx_entity (entity_id, metric_type, metric_date DESC),
    INDEX idx_date (metric_date, metric_type)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS viral_content_tracking (
    tracking_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    post_id BIGINT UNSIGNED NOT NULL,
    check_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    view_velocity DECIMAL(10, 4), -- Views per hour
    share_velocity DECIMAL(10, 4), -- Shares per hour
    engagement_velocity DECIMAL(10, 4), -- Total engagements per hour
    total_reach INT UNSIGNED,
    unique_sharers INT UNSIGNED,
    cascade_depth INT, -- How many levels of reshares
    is_trending BOOLEAN DEFAULT FALSE,
    trend_score DECIMAL(10, 4),
    FOREIGN KEY (post_id) REFERENCES posts(post_id) ON DELETE CASCADE,
    INDEX idx_post_tracking (post_id, check_time DESC),
    INDEX idx_trending (is_trending, trend_score DESC)
) ENGINE=InnoDB;

-- =========================================
-- 10. USER LISTS & COLLECTIONS
-- =========================================

CREATE TABLE IF NOT EXISTS user_lists (
    list_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_public BOOLEAN DEFAULT FALSE,
    member_count INT UNSIGNED DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_user_lists (user_id),
    INDEX idx_public_lists (is_public, created_at DESC)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS list_members (
    member_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    list_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (list_id) REFERENCES user_lists(list_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    UNIQUE INDEX idx_list_member (list_id, user_id),
    INDEX idx_user_lists_membership (user_id)
) ENGINE=InnoDB;

-- =========================================
-- Show tables created
-- =========================================
SHOW TABLES;
SELECT 'Social Media tables created successfully' AS status;