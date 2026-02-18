-- PostgreSQL Schema
-- Converted from MySQL on 2026-02-17T23:11:17.376987
-- Generator: MySQL to PostgreSQL Converter

-- Enum Types
CREATE TYPE users_status AS ENUM ('personal', 'business', 'creator', 'verified');
CREATE TYPE user_profiles_status AS ENUM ('male', 'female', 'other', 'prefer_not_to_say');
CREATE TYPE user_settings_status AS ENUM ('everyone', 'friends', 'none');
CREATE TYPE relationships_status AS ENUM ('active', 'pending', 'removed');
CREATE TYPE relationship_requests_status AS ENUM ('pending', 'accepted', 'rejected', 'cancelled');
CREATE TYPE posts_status AS ENUM ('public', 'friends', 'private', 'custom');
CREATE TYPE post_media_status AS ENUM ('image', 'video', 'audio', 'document');
CREATE TYPE reactions_status AS ENUM ('like', 'love', 'haha', 'wow', 'sad', 'angry');
CREATE TYPE shares_status AS ENUM ('repost', 'quote', 'message', 'external');
CREATE TYPE conversations_status AS ENUM ('direct', 'group');
CREATE TYPE conversation_participants_status AS ENUM ('member', 'admin', 'owner');
CREATE TYPE messages_status AS ENUM ('text', 'image', 'video', 'file', 'voice');
CREATE TYPE notifications_status AS ENUM ('post', 'comment', 'user', 'message');
CREATE TYPE reports_status AS ENUM ('none', 'warning', 'content_removed', 'account_suspended', 'account_banned');
CREATE TYPE banned_content_status AS ENUM ('low', 'medium', 'high', 'critical');
CREATE TYPE user_activity_logs_status AS ENUM ('view', 'click', 'scroll', 'search', 'share');
CREATE TYPE engagement_metrics_status AS ENUM ('post', 'user', 'hashtag');

DROP DATABASE IF EXISTS social_media;
-- Create database (run as superuser)
-- CREATE DATABASE social_media;
-- \c social_media

SHOW DATABASES LIKE 'social_media';
SELECT 'Social Media database created successfully' AS status;
CREATE TABLE IF NOT EXISTS users (
    username VARCHAR(30) NOT NULL,
    email VARCHAR(255) NOT NULL,
    email_verified BOOLEAN DEFAULT FALSE,
    password_hash VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20),
    phone_verified BOOLEAN DEFAULT FALSE,
    status users_status DEFAULT 'active',
    account_type users_status DEFAULT 'personal',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_active TIMESTAMP NULL,
    deleted_at TIMESTAMP NULL,
    UNIQUE (username),
    UNIQUE (email)
);

CREATE TABLE IF NOT EXISTS user_profiles (
    user_id BIGINT NOT NULL,
    display_name VARCHAR(100),
    bio TEXT,
    profile_picture_url VARCHAR(500),
    cover_picture_url VARCHAR(500),
    website VARCHAR(255),
    location VARCHAR(100),
    birth_date DATE,
    gender user_profiles_status,
    language VARCHAR(10) DEFAULT 'en',
    timezone VARCHAR(50) DEFAULT 'UTC',
    is_private BOOLEAN DEFAULT FALSE,
    verified_badge BOOLEAN DEFAULT FALSE,
    follower_count INTEGER DEFAULT 0,
    following_count INTEGER DEFAULT 0,
    post_count INTEGER DEFAULT 0,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE user_profiles ADD CONSTRAINT fk_user_profiles_user_id FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;
CREATE TABLE IF NOT EXISTS user_settings (
    user_id BIGINT NOT NULL,
    notification_email BOOLEAN DEFAULT TRUE,
    notification_push BOOLEAN DEFAULT TRUE,
    notification_sms BOOLEAN DEFAULT FALSE,
    privacy_profile_visibility user_settings_status DEFAULT 'public',
    privacy_message_requests user_settings_status DEFAULT 'friends',
    privacy_show_activity_status BOOLEAN DEFAULT TRUE,
    privacy_show_read_receipts BOOLEAN DEFAULT TRUE,
    content_filter_sensitive BOOLEAN DEFAULT FALSE,
    content_filter_violence BOOLEAN DEFAULT TRUE,
    content_language_preferences JSONB,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id)
);

ALTER TABLE user_settings ADD CONSTRAINT fk_user_settings_user_id FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;
CREATE TABLE IF NOT EXISTS relationships (
    from_user_id BIGINT NOT NULL,
    to_user_id BIGINT NOT NULL,
    relationship_type relationships_status NOT NULL,
    status relationships_status DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (from_user_id, to_user_id, relationship_type)
);

ALTER TABLE relationships ADD CONSTRAINT fk_relationships_from_user_id FOREIGN KEY (from_user_id) REFERENCES users(user_id) ON DELETE CASCADE;
ALTER TABLE relationships ADD CONSTRAINT fk_relationships_to_user_id FOREIGN KEY (to_user_id) REFERENCES users(user_id) ON DELETE CASCADE;
CREATE TABLE IF NOT EXISTS relationship_requests (
    from_user_id BIGINT NOT NULL,
    to_user_id BIGINT NOT NULL,
    request_type relationship_requests_status NOT NULL,
    status relationship_requests_status DEFAULT 'pending',
    message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    responded_at TIMESTAMP NULL,
    UNIQUE (from_user_id, to_user_id, request_type, status)
);

ALTER TABLE relationship_requests ADD CONSTRAINT fk_relationship_requests_from_user_id FOREIGN KEY (from_user_id) REFERENCES users(user_id) ON DELETE CASCADE;
ALTER TABLE relationship_requests ADD CONSTRAINT fk_relationship_requests_to_user_id FOREIGN KEY (to_user_id) REFERENCES users(user_id) ON DELETE CASCADE;
CREATE TABLE IF NOT EXISTS posts (
    user_id BIGINT NOT NULL,
    parent_post_id BIGINT,
    post_type posts_status NOT NULL,
    visibility posts_status DEFAULT 'public',
    is_edited BOOLEAN DEFAULT FALSE,
    edit_history JSONB,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    view_count INTEGER DEFAULT 0,
    share_count INTEGER DEFAULT 0,
    comment_count INTEGER DEFAULT 0,
    like_count INTEGER DEFAULT 0,
    engagement_score DECIMAL(10, 4) DEFAULT 0,
    is_archived BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    PARTITION TEXT VALUES LESS THAN (2025),
    PARTITION TEXT VALUES LESS THAN (2026),
    PARTITION TEXT VALUES LESS THAN MAXVALUE
);

ALTER TABLE posts ADD CONSTRAINT fk_posts_user_id FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;
ALTER TABLE posts ADD CONSTRAINT fk_posts_parent_post_id FOREIGN KEY (parent_post_id) REFERENCES posts(post_id) ON DELETE SET;
CREATE TABLE IF NOT EXISTS post_media (
    post_id BIGINT NOT NULL,
    media_type post_media_status NOT NULL,
    media_url VARCHAR(500) NOT NULL,
    thumbnail_url VARCHAR(500),
    media_metadata JSONB,
    alt_text TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE post_media ADD CONSTRAINT fk_post_media_post_id FOREIGN KEY (post_id) REFERENCES posts(post_id) ON DELETE CASCADE;
CREATE TABLE IF NOT EXISTS comments (
    post_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    parent_comment_id BIGINT,
    like_count INTEGER DEFAULT 0,
    is_edited BOOLEAN DEFAULT FALSE,
    is_hidden BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);

ALTER TABLE comments ADD CONSTRAINT fk_comments_post_id FOREIGN KEY (post_id) REFERENCES posts(post_id) ON DELETE CASCADE;
ALTER TABLE comments ADD CONSTRAINT fk_comments_user_id FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;
ALTER TABLE comments ADD CONSTRAINT fk_comments_parent_comment_id FOREIGN KEY (parent_comment_id) REFERENCES comments(comment_id) ON DELETE CASCADE;
CREATE TABLE IF NOT EXISTS reactions (
    user_id BIGINT NOT NULL,
    target_type reactions_status NOT NULL,
    target_id BIGINT NOT NULL,
    reaction_type reactions_status DEFAULT 'like',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, target_type, target_id)
);

ALTER TABLE reactions ADD CONSTRAINT fk_reactions_user_id FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;
CREATE TABLE IF NOT EXISTS shares (
    post_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    share_type shares_status NOT NULL,
    share_text TEXT
);

ALTER TABLE shares ADD CONSTRAINT fk_shares_post_id FOREIGN KEY (post_id) REFERENCES posts(post_id) ON DELETE CASCADE;
ALTER TABLE shares ADD CONSTRAINT fk_shares_user_id FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;
CREATE TABLE IF NOT EXISTS bookmarks (
    user_id BIGINT NOT NULL,
    post_id BIGINT NOT NULL,
    collection_name VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, post_id)
);

ALTER TABLE bookmarks ADD CONSTRAINT fk_bookmarks_user_id FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;
ALTER TABLE bookmarks ADD CONSTRAINT fk_bookmarks_post_id FOREIGN KEY (post_id) REFERENCES posts(post_id) ON DELETE CASCADE;
CREATE TABLE IF NOT EXISTS hashtags (
    tag VARCHAR(100) NOT NULL,
    tag_normalized VARCHAR(100) NOT NULL,
    no TEXT chars,
    weekly_count INTEGER DEFAULT 0,
    daily_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_used TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tag_normalized)
);

CREATE TABLE IF NOT EXISTS post_hashtags (
    post_id BIGINT NOT NULL,
    hashtag_id BIGINT NOT NULL,
    position INTEGER,
    UNIQUE (post_id, hashtag_id)
);

ALTER TABLE post_hashtags ADD CONSTRAINT fk_post_hashtags_post_id FOREIGN KEY (post_id) REFERENCES posts(post_id) ON DELETE CASCADE;
ALTER TABLE post_hashtags ADD CONSTRAINT fk_post_hashtags_hashtag_id FOREIGN KEY (hashtag_id) REFERENCES hashtags(hashtag_id) ON DELETE CASCADE;
CREATE TABLE IF NOT EXISTS trending_topics (
    trend_value VARCHAR(100) NOT NULL,
    region VARCHAR(50) DEFAULT 'global',
    score DECIMAL(10, 4) NOT NULL,
    user_count INTEGER DEFAULT 0,
    start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    peak_time TIMESTAMP NULL,
    end_time TIMESTAMP NULL
);

CREATE TABLE IF NOT EXISTS conversations (
    conversation_type conversations_status NOT NULL,
    title VARCHAR(255),
    description TEXT,
    creator_user_id BIGINT,
    is_archived BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_message_at TIMESTAMP NULL
);

ALTER TABLE conversations ADD CONSTRAINT fk_conversations_creator_user_id FOREIGN KEY (creator_user_id) REFERENCES users(user_id) ON DELETE SET;
CREATE TABLE IF NOT EXISTS conversation_participants (
    conversation_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    role conversation_participants_status DEFAULT 'member',
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_read_at TIMESTAMP NULL,
    is_muted BOOLEAN DEFAULT FALSE,
    left_at TIMESTAMP NULL,
    UNIQUE (conversation_id, user_id)
);

ALTER TABLE conversation_participants ADD CONSTRAINT fk_conversation_participants_conversation_id FOREIGN KEY (conversation_id) REFERENCES conversations(conversation_id) ON DELETE CASCADE;
ALTER TABLE conversation_participants ADD CONSTRAINT fk_conversation_participants_user_id FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;
CREATE TABLE IF NOT EXISTS messages (
    conversation_id BIGINT NOT NULL,
    sender_user_id BIGINT NOT NULL,
    message_type messages_status DEFAULT 'text',
    content TEXT,
    media_url VARCHAR(500),
    is_edited BOOLEAN DEFAULT FALSE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    edited_at TIMESTAMP NULL,
    deleted_at TIMESTAMP NULL
);

ALTER TABLE messages ADD CONSTRAINT fk_messages_conversation_id FOREIGN KEY (conversation_id) REFERENCES conversations(conversation_id) ON DELETE CASCADE;
ALTER TABLE messages ADD CONSTRAINT fk_messages_sender_user_id FOREIGN KEY (sender_user_id) REFERENCES users(user_id) ON DELETE CASCADE;
CREATE TABLE IF NOT EXISTS notifications (
    user_id BIGINT NOT NULL,
    type notifications_status NOT NULL,
    actor_user_id BIGINT,
    target_type notifications_status,
    target_id BIGINT,
    title VARCHAR(255),
    body TEXT,
    data JSONB,
    is_pushed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP NULL
);

ALTER TABLE notifications ADD CONSTRAINT fk_notifications_user_id FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;
ALTER TABLE notifications ADD CONSTRAINT fk_notifications_actor_user_id FOREIGN KEY (actor_user_id) REFERENCES users(user_id) ON DELETE CASCADE;
CREATE TABLE IF NOT EXISTS reports (
    reporter_user_id BIGINT NOT NULL,
    reported_type reports_status NOT NULL,
    reported_id BIGINT NOT NULL,
    reason reports_status NOT NULL,
    description TEXT,
    status reports_status DEFAULT 'pending',
    priority reports_status DEFAULT 'medium',
    moderator_id BIGINT,
    action_taken reports_status,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reviewed_at TIMESTAMP NULL
);

ALTER TABLE reports ADD CONSTRAINT fk_reports_reporter_user_id FOREIGN KEY (reporter_user_id) REFERENCES users(user_id) ON DELETE CASCADE;
CREATE TABLE IF NOT EXISTS banned_content (
    content_value VARCHAR(500) NOT NULL,
    severity banned_content_status DEFAULT 'medium',
    reason TEXT,
    added_by BIGINT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NULL,
    UNIQUE (content_type, content_value)
);

CREATE TABLE IF NOT EXISTS user_activity_logs (
    user_id BIGINT NOT NULL,
    action_type user_activity_logs_status NOT NULL,
    target_type VARCHAR(50),
    target_id BIGINT,
    session_id VARCHAR(100),
    ip_address VARCHAR(45),
    user_agent VARCHAR(500),
    referrer VARCHAR(500),
    duration_ms INTEGER,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PARTITION TEXT VALUES LESS THAN (TO_DAYS('2024-04-01')),
    PARTITION TEXT VALUES LESS THAN (TO_DAYS('2024-07-01')),
    PARTITION TEXT VALUES LESS THAN (TO_DAYS('2024-10-01')),
    PARTITION TEXT VALUES LESS THAN MAXVALUE
);

CREATE TABLE IF NOT EXISTS engagement_metrics (
    metric_date DATE NOT NULL,
    metric_hour SMALLINT,
    metric_type engagement_metrics_status NOT NULL,
    entity_id BIGINT NOT NULL,
    impressions INTEGER DEFAULT 0,
    engagements INTEGER DEFAULT 0,
    clicks INTEGER DEFAULT 0,
    shares INTEGER DEFAULT 0,
    comments INTEGER DEFAULT 0,
    likes INTEGER DEFAULT 0,
    reach INTEGER DEFAULT 0,
    UNIQUE (metric_date, metric_hour, metric_type, entity_id)
);

CREATE TABLE IF NOT EXISTS viral_content_tracking (
    post_id BIGINT NOT NULL,
    view_velocity DECIMAL(10, 4),
    cascade_depth INTEGER,
    trend_score DECIMAL(10, 4)
);

ALTER TABLE viral_content_tracking ADD CONSTRAINT fk_viral_content_tracking_post_id FOREIGN KEY (post_id) REFERENCES posts(post_id) ON DELETE CASCADE;
CREATE TABLE IF NOT EXISTS user_lists (
    user_id BIGINT NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_public BOOLEAN DEFAULT FALSE,
    member_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE user_lists ADD CONSTRAINT fk_user_lists_user_id FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;
CREATE TABLE IF NOT EXISTS list_members (
    list_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (list_id, user_id)
);

ALTER TABLE list_members ADD CONSTRAINT fk_list_members_list_id FOREIGN KEY (list_id) REFERENCES user_lists(list_id) ON DELETE CASCADE;
ALTER TABLE list_members ADD CONSTRAINT fk_list_members_user_id FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;
SHOW TABLES;
SELECT 'Social Media tables created successfully' AS status;
-- Indexes
