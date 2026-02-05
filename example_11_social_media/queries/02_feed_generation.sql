-- =========================================
-- Social Media Platform - Feed Generation Queries
-- =========================================

USE social_media;

-- =========================================
-- 1. Chronological Timeline Feed
-- =========================================

-- Get user's home feed (posts from people they follow)
SELECT
    p.post_id,
    p.user_id,
    u.username,
    up.display_name,
    up.profile_picture_url,
    up.verified_badge,
    p.content,
    p.post_type,
    p.created_at,
    p.like_count,
    p.comment_count,
    p.share_count,
    p.view_count,
    -- Check if current user has liked
    EXISTS(
        SELECT 1 FROM reactions r
        WHERE r.target_type = 'post'
          AND r.target_id = p.post_id
          AND r.user_id = 1
    ) AS user_has_liked,
    -- Check if current user has shared
    EXISTS(
        SELECT 1 FROM shares s
        WHERE s.post_id = p.post_id
          AND s.user_id = 1
    ) AS user_has_shared,
    -- Get media attachments
    (
        SELECT JSON_ARRAYAGG(
            JSON_OBJECT(
                'media_type', pm.media_type,
                'media_url', pm.media_url,
                'thumbnail_url', pm.thumbnail_url
            )
        )
        FROM post_media pm
        WHERE pm.post_id = p.post_id
        ORDER BY pm.display_order
    ) AS media,
    -- Get first few comments
    (
        SELECT JSON_ARRAYAGG(
            JSON_OBJECT(
                'comment_id', c.comment_id,
                'username', cu.username,
                'content', c.content,
                'created_at', c.created_at
            )
        )
        FROM (
            SELECT * FROM comments
            WHERE post_id = p.post_id
              AND deleted_at IS NULL
            ORDER BY created_at DESC
            LIMIT 3
        ) c
        JOIN users cu ON c.user_id = cu.user_id
    ) AS recent_comments
FROM posts p
JOIN users u ON p.user_id = u.user_id
JOIN user_profiles up ON u.user_id = up.user_id
WHERE p.user_id IN (
    -- Get users that current user follows
    SELECT to_user_id
    FROM relationships
    WHERE from_user_id = 1
      AND relationship_type IN ('follow', 'friend')
      AND status = 'active'
)
  AND p.deleted_at IS NULL
  AND p.visibility IN ('public', 'friends')
  AND p.created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
  AND u.status = 'active'
ORDER BY p.created_at DESC
LIMIT 50;

-- =========================================
-- 2. Algorithmic Feed (Engagement-Based)
-- =========================================

-- Get personalized feed based on engagement patterns
WITH UserInterests AS (
    -- Find what the user typically engages with
    SELECT
        p.user_id AS content_creator_id,
        COUNT(DISTINCT CASE WHEN r.reaction_type = 'like' THEN r.reaction_id END) AS likes_given,
        COUNT(DISTINCT c.comment_id) AS comments_made,
        COUNT(DISTINCT s.share_id) AS shares_made
    FROM reactions r
    LEFT JOIN posts p ON r.target_type = 'post' AND r.target_id = p.post_id
    LEFT JOIN comments c ON c.user_id = 1 AND c.post_id = p.post_id
    LEFT JOIN shares s ON s.user_id = 1 AND s.post_id = p.post_id
    WHERE r.user_id = 1
      AND r.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
    GROUP BY p.user_id
),
PostScores AS (
    SELECT
        p.post_id,
        p.user_id,
        p.created_at,
        p.engagement_score,
        -- Recency score (newer = higher)
        GREATEST(0, 100 - TIMESTAMPDIFF(HOUR, p.created_at, NOW())) AS recency_score,
        -- Relationship score (friend vs follow)
        CASE
            WHEN r.relationship_type = 'friend' THEN 50
            WHEN r.relationship_type = 'follow' THEN 30
            ELSE 10
        END AS relationship_score,
        -- Interest score based on past engagement with this creator
        COALESCE(ui.likes_given * 5 + ui.comments_made * 10 + ui.shares_made * 15, 0) AS interest_score,
        -- Virality score
        CASE
            WHEN p.share_count > 100 THEN 50
            WHEN p.share_count > 50 THEN 30
            WHEN p.share_count > 10 THEN 10
            ELSE 0
        END AS virality_score
    FROM posts p
    LEFT JOIN relationships r ON r.from_user_id = 1
        AND r.to_user_id = p.user_id
        AND r.status = 'active'
    LEFT JOIN UserInterests ui ON ui.content_creator_id = p.user_id
    WHERE p.deleted_at IS NULL
      AND p.visibility IN ('public', 'friends')
      AND p.created_at >= DATE_SUB(NOW(), INTERVAL 24 DAY)
      AND (
          -- Include posts from followed users
          r.relationship_id IS NOT NULL
          -- Or highly viral public posts
          OR p.share_count > 50
          -- Or posts from verified users
          OR EXISTS(
              SELECT 1 FROM user_profiles up
              WHERE up.user_id = p.user_id
                AND up.verified_badge = TRUE
          )
      )
)
SELECT
    ps.post_id,
    u.username,
    up.display_name,
    up.profile_picture_url,
    p.content,
    p.post_type,
    p.created_at,
    p.like_count,
    p.comment_count,
    p.share_count,
    -- Calculate final score
    (ps.recency_score * 0.3 +
     ps.engagement_score * 0.25 +
     ps.relationship_score * 0.2 +
     ps.interest_score * 0.15 +
     ps.virality_score * 0.1) AS feed_score,
    ps.recency_score,
    ps.engagement_score,
    ps.relationship_score,
    ps.interest_score,
    ps.virality_score
FROM PostScores ps
JOIN posts p ON ps.post_id = p.post_id
JOIN users u ON p.user_id = u.user_id
JOIN user_profiles up ON u.user_id = up.user_id
WHERE u.status = 'active'
ORDER BY feed_score DESC, p.created_at DESC
LIMIT 50;

-- =========================================
-- 3. Explore/Discovery Feed
-- =========================================

-- Get trending and recommended content not from followed users
SELECT
    p.post_id,
    u.username,
    up.display_name,
    up.profile_picture_url,
    up.verified_badge,
    p.content,
    p.post_type,
    p.created_at,
    p.like_count,
    p.comment_count,
    p.share_count,
    p.view_count,
    -- Trending score calculation
    (p.like_count * 1 +
     p.comment_count * 2 +
     p.share_count * 3) /
    GREATEST(TIMESTAMPDIFF(HOUR, p.created_at, NOW()), 1) AS trending_score,
    -- Get dominant hashtags
    (
        SELECT GROUP_CONCAT(h.tag ORDER BY h.post_count DESC SEPARATOR ', ')
        FROM post_hashtags ph
        JOIN hashtags h ON ph.hashtag_id = h.hashtag_id
        WHERE ph.post_id = p.post_id
        LIMIT 3
    ) AS hashtags
FROM posts p
JOIN users u ON p.user_id = u.user_id
JOIN user_profiles up ON u.user_id = up.user_id
WHERE p.user_id NOT IN (
    -- Exclude already followed users
    SELECT to_user_id
    FROM relationships
    WHERE from_user_id = 1
      AND relationship_type IN ('follow', 'friend')
      AND status = 'active'
)
  AND p.user_id != 1 -- Exclude own posts
  AND p.deleted_at IS NULL
  AND p.visibility = 'public'
  AND p.created_at >= DATE_SUB(NOW(), INTERVAL 48 HOUR)
  AND u.status = 'active'
  -- Quality filters
  AND (
      p.like_count > 10
      OR p.share_count > 5
      OR up.verified_badge = TRUE
      OR up.follower_count > 1000
  )
ORDER BY trending_score DESC
LIMIT 50;

-- =========================================
-- 4. Story Feed (Ephemeral Content)
-- =========================================

-- Get stories from followed users
SELECT
    p.post_id AS story_id,
    p.user_id,
    u.username,
    up.display_name,
    up.profile_picture_url,
    p.created_at AS story_created,
    DATE_ADD(p.created_at, INTERVAL 24 HOUR) AS story_expires,
    TIMESTAMPDIFF(HOUR, NOW(), DATE_ADD(p.created_at, INTERVAL 24 HOUR)) AS hours_remaining,
    -- Check if user has viewed
    EXISTS(
        SELECT 1 FROM user_activity_logs ual
        WHERE ual.user_id = 1
          AND ual.action_type = 'view'
          AND ual.target_type = 'story'
          AND ual.target_id = p.post_id
    ) AS has_viewed,
    -- Get story media
    (
        SELECT JSON_OBJECT(
            'media_type', pm.media_type,
            'media_url', pm.media_url
        )
        FROM post_media pm
        WHERE pm.post_id = p.post_id
        ORDER BY pm.display_order
        LIMIT 1
    ) AS story_media,
    -- Count total stories from this user today
    (
        SELECT COUNT(*)
        FROM posts p2
        WHERE p2.user_id = p.user_id
          AND p2.post_type = 'story'
          AND p2.created_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
          AND p2.deleted_at IS NULL
    ) AS total_stories_today
FROM posts p
JOIN users u ON p.user_id = u.user_id
JOIN user_profiles up ON u.user_id = up.user_id
WHERE p.post_type = 'story'
  AND p.created_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
  AND p.deleted_at IS NULL
  AND p.user_id IN (
      SELECT to_user_id
      FROM relationships
      WHERE from_user_id = 1
        AND relationship_type IN ('follow', 'friend')
        AND status = 'active'
  )
  AND u.status = 'active'
GROUP BY p.user_id
ORDER BY
    has_viewed ASC, -- Unviewed first
    up.verified_badge DESC,
    story_created DESC
LIMIT 20;

-- =========================================
-- 5. For You Page (TikTok-style Algorithm)
-- =========================================

-- Highly personalized feed mixing followed and new content
WITH UserBehavior AS (
    -- Analyze user's viewing patterns
    SELECT
        target_id AS post_id,
        AVG(duration_ms) AS avg_view_duration,
        COUNT(*) AS view_count
    FROM user_activity_logs
    WHERE user_id = 1
      AND action_type = 'view'
      AND target_type = 'post'
      AND created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
    GROUP BY target_id
),
ContentFeatures AS (
    SELECT
        p.post_id,
        p.user_id,
        -- Content quality signals
        p.like_count / GREATEST(p.view_count, 1) AS like_rate,
        p.share_count / GREATEST(p.view_count, 1) AS share_rate,
        p.comment_count / GREATEST(p.view_count, 1) AS comment_rate,
        -- Completion rate (from similar users)
        (
            SELECT AVG(duration_ms / 1000)
            FROM user_activity_logs
            WHERE target_type = 'post'
              AND target_id = p.post_id
              AND action_type = 'view'
        ) AS avg_watch_time,
        -- Creator quality
        up.follower_count,
        up.verified_badge,
        -- Content freshness
        TIMESTAMPDIFF(HOUR, p.created_at, NOW()) AS hours_old
    FROM posts p
    JOIN user_profiles up ON p.user_id = up.user_id
    WHERE p.post_type IN ('video', 'image')
      AND p.deleted_at IS NULL
      AND p.visibility = 'public'
      AND p.created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
)
SELECT
    cf.post_id,
    u.username,
    up.display_name,
    p.content,
    p.post_type,
    -- Composite recommendation score
    (
        COALESCE(ub.view_count, 0) * 10 + -- User has engaged before
        cf.like_rate * 100 +
        cf.share_rate * 200 +
        cf.comment_rate * 150 +
        COALESCE(cf.avg_watch_time, 0) * 5 +
        IF(cf.verified_badge, 20, 0) +
        LEAST(cf.follower_count / 1000, 50) + -- Cap follower influence
        GREATEST(0, 100 - cf.hours_old * 2) -- Recency bonus
    ) AS recommendation_score,
    CASE
        WHEN ub.post_id IS NOT NULL THEN 'previously_engaged'
        WHEN cf.follower_count > 10000 THEN 'popular_creator'
        WHEN cf.hours_old < 3 THEN 'fresh_content'
        WHEN cf.like_rate > 0.1 THEN 'high_quality'
        ELSE 'discovery'
    END AS recommendation_reason
FROM ContentFeatures cf
JOIN posts p ON cf.post_id = p.post_id
JOIN users u ON p.user_id = u.user_id
JOIN user_profiles up ON u.user_id = up.user_id
LEFT JOIN UserBehavior ub ON cf.post_id = ub.post_id
WHERE u.status = 'active'
ORDER BY recommendation_score DESC
LIMIT 100;

-- =========================================
-- 6. Feed Diversity Analysis
-- =========================================

-- Ensure feed has diverse content types and creators
WITH FeedComposition AS (
    SELECT
        p.post_id,
        p.user_id,
        p.post_type,
        p.created_at,
        ROW_NUMBER() OVER (PARTITION BY p.user_id ORDER BY p.created_at DESC) AS creator_rank,
        ROW_NUMBER() OVER (PARTITION BY p.post_type ORDER BY p.created_at DESC) AS type_rank
    FROM posts p
    WHERE p.user_id IN (
        SELECT to_user_id
        FROM relationships
        WHERE from_user_id = 1
          AND relationship_type IN ('follow', 'friend')
          AND status = 'active'
    )
      AND p.deleted_at IS NULL
      AND p.visibility IN ('public', 'friends')
      AND p.created_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
)
SELECT
    post_type,
    COUNT(*) AS post_count,
    COUNT(DISTINCT user_id) AS unique_creators,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage_of_feed,
    AVG(creator_rank) AS avg_creator_diversity_rank
FROM FeedComposition
WHERE creator_rank <= 3  -- Max 3 posts per creator
  AND type_rank <= 20    -- Max 20 posts per type
GROUP BY post_type
ORDER BY percentage_of_feed DESC;

-- =========================================
-- 7. Feed Performance Metrics
-- =========================================

-- Analyze feed quality and engagement
SELECT
    'Feed Metrics' AS category,
    'Average Engagement Rate' AS metric,
    ROUND(AVG((p.like_count + p.comment_count + p.share_count) / GREATEST(p.view_count, 1) * 100), 2) AS value
FROM posts p
WHERE p.created_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
  AND p.view_count > 0

UNION ALL

SELECT
    'Feed Metrics',
    'Click-Through Rate',
    ROUND(
        100.0 * COUNT(DISTINCT ual.target_id) /
        (SELECT COUNT(*) FROM posts WHERE created_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)),
        2
    )
FROM user_activity_logs ual
WHERE ual.action_type = 'click'
  AND ual.target_type = 'post'
  AND ual.created_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)

UNION ALL

SELECT
    'Feed Metrics',
    'Average Session Duration (seconds)',
    ROUND(AVG(duration_ms / 1000), 2)
FROM user_activity_logs
WHERE action_type = 'view'
  AND created_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)

UNION ALL

SELECT
    'Feed Metrics',
    'Posts Per Session',
    ROUND(
        COUNT(*) /
        COUNT(DISTINCT session_id),
        2
    )
FROM user_activity_logs
WHERE action_type = 'view'
  AND target_type = 'post'
  AND created_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR);

-- =========================================
-- 8. User-Specific Feed Cache
-- =========================================

-- Pre-compute feed for active users (would be stored in cache)
CREATE TEMPORARY TABLE IF NOT EXISTS user_feed_cache AS
SELECT
    1 AS user_id,
    p.post_id,
    p.user_id AS creator_id,
    p.created_at,
    -- Pre-calculate all expensive operations
    (
        SELECT COUNT(*)
        FROM reactions
        WHERE target_type = 'post'
          AND target_id = p.post_id
    ) AS real_time_likes,
    (
        SELECT COUNT(*)
        FROM comments
        WHERE post_id = p.post_id
          AND deleted_at IS NULL
    ) AS real_time_comments,
    EXISTS(
        SELECT 1 FROM reactions
        WHERE target_type = 'post'
          AND target_id = p.post_id
          AND user_id = 1
    ) AS user_liked,
    NOW() AS cached_at
FROM posts p
WHERE p.user_id IN (
    SELECT to_user_id
    FROM relationships
    WHERE from_user_id = 1
      AND relationship_type IN ('follow', 'friend')
      AND status = 'active'
)
  AND p.deleted_at IS NULL
  AND p.created_at >= DATE_SUB(NOW(), INTERVAL 48 HOUR)
ORDER BY p.created_at DESC
LIMIT 200;

-- Query from cache
SELECT * FROM user_feed_cache
WHERE cached_at >= DATE_SUB(NOW(), INTERVAL 5 MINUTE)
ORDER BY created_at DESC
LIMIT 50;