-- =========================================
-- Social Media Platform - Social Graph Queries
-- =========================================

USE social_media;

-- =========================================
-- 1. Find Mutual Friends/Followers
-- =========================================

-- Find mutual followers between two users
WITH User1Followers AS (
    SELECT to_user_id AS follower_id
    FROM relationships
    WHERE from_user_id = 1
      AND relationship_type = 'follow'
      AND status = 'active'
),
User2Followers AS (
    SELECT to_user_id AS follower_id
    FROM relationships
    WHERE from_user_id = 2
      AND relationship_type = 'follow'
      AND status = 'active'
)
SELECT
    u.user_id,
    u.username,
    up.display_name,
    up.profile_picture_url,
    up.follower_count,
    up.verified_badge
FROM User1Followers u1
INNER JOIN User2Followers u2 ON u1.follower_id = u2.follower_id
JOIN users u ON u.user_id = u1.follower_id
JOIN user_profiles up ON u.user_id = up.user_id
WHERE u.status = 'active'
ORDER BY up.follower_count DESC
LIMIT 20;

-- =========================================
-- 2. Friend Recommendations (Friend-of-Friend)
-- =========================================

-- Suggest users based on mutual connections
WITH MyFriends AS (
    SELECT
        CASE
            WHEN from_user_id = 1 THEN to_user_id
            WHEN to_user_id = 1 THEN from_user_id
        END AS friend_id
    FROM relationships
    WHERE (from_user_id = 1 OR to_user_id = 1)
      AND relationship_type IN ('follow', 'friend')
      AND status = 'active'
),
FriendsOfFriends AS (
    SELECT
        r.to_user_id AS suggested_user_id,
        COUNT(DISTINCT mf.friend_id) AS mutual_friends_count
    FROM MyFriends mf
    JOIN relationships r ON mf.friend_id = r.from_user_id
    WHERE r.relationship_type IN ('follow', 'friend')
      AND r.status = 'active'
      AND r.to_user_id != 1
      AND r.to_user_id NOT IN (SELECT friend_id FROM MyFriends)
    GROUP BY r.to_user_id
)
SELECT
    u.user_id,
    u.username,
    up.display_name,
    up.bio,
    up.profile_picture_url,
    up.follower_count,
    up.verified_badge,
    fof.mutual_friends_count,
    CASE
        WHEN up.follower_count > 10000 THEN 'influencer'
        WHEN fof.mutual_friends_count > 5 THEN 'highly_connected'
        ELSE 'suggested'
    END AS recommendation_reason
FROM FriendsOfFriends fof
JOIN users u ON fof.suggested_user_id = u.user_id
JOIN user_profiles up ON u.user_id = up.user_id
WHERE u.status = 'active'
  AND up.is_private = FALSE
ORDER BY fof.mutual_friends_count DESC, up.follower_count DESC
LIMIT 30;

-- =========================================
-- 3. Calculate Degrees of Separation
-- =========================================

-- Find shortest path between two users (up to 3 degrees)
WITH RECURSIVE ConnectionPath AS (
    -- Direct connection (1 degree)
    SELECT
        1 AS user_id,
        5 AS target_user_id,
        CAST('1' AS CHAR(1000)) AS path,
        0 AS degrees

    UNION ALL

    -- Recursive connections
    SELECT
        r.to_user_id,
        cp.target_user_id,
        CONCAT(cp.path, ',', r.to_user_id) AS path,
        cp.degrees + 1
    FROM ConnectionPath cp
    JOIN relationships r ON r.from_user_id = cp.user_id
    WHERE r.relationship_type IN ('follow', 'friend')
      AND r.status = 'active'
      AND cp.degrees < 3
      AND NOT FIND_IN_SET(r.to_user_id, cp.path)
      AND r.to_user_id != cp.target_user_id
)
SELECT
    degrees + 1 AS separation_degree,
    CONCAT(path, ',', target_user_id) AS connection_path
FROM ConnectionPath
WHERE user_id = target_user_id
ORDER BY degrees
LIMIT 1;

-- =========================================
-- 4. Identify Influencers
-- =========================================

-- Find top influencers based on follower count and engagement
SELECT
    u.user_id,
    u.username,
    up.display_name,
    up.verified_badge,
    up.follower_count,
    up.following_count,
    ROUND(up.follower_count / GREATEST(up.following_count, 1), 2) AS follower_ratio,
    COUNT(DISTINCT p.post_id) AS recent_posts,
    AVG(p.engagement_score) AS avg_engagement_score,
    SUM(p.like_count) AS total_likes,
    SUM(p.share_count) AS total_shares,
    SUM(p.comment_count) AS total_comments,
    ROUND(
        (SUM(p.like_count) + SUM(p.comment_count) * 2 + SUM(p.share_count) * 3) /
        GREATEST(COUNT(p.post_id), 1),
        2
    ) AS engagement_per_post
FROM users u
JOIN user_profiles up ON u.user_id = up.user_id
LEFT JOIN posts p ON u.user_id = p.user_id
    AND p.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
    AND p.deleted_at IS NULL
WHERE u.status = 'active'
  AND up.follower_count > 1000
GROUP BY u.user_id
HAVING recent_posts > 5
ORDER BY up.follower_count DESC, engagement_per_post DESC
LIMIT 50;

-- =========================================
-- 5. Community Detection (Find Clusters)
-- =========================================

-- Identify tightly connected user groups
WITH UserConnections AS (
    SELECT
        from_user_id AS user_id,
        to_user_id AS connected_user_id
    FROM relationships
    WHERE relationship_type IN ('follow', 'friend')
      AND status = 'active'

    UNION

    SELECT
        to_user_id AS user_id,
        from_user_id AS connected_user_id
    FROM relationships
    WHERE relationship_type = 'friend'
      AND status = 'active'
),
UserTriangles AS (
    -- Find triangles (3 users all connected to each other)
    SELECT DISTINCT
        LEAST(uc1.user_id, uc1.connected_user_id, uc2.connected_user_id) AS user1,
        GREATEST(LEAST(uc1.user_id, uc1.connected_user_id),
                LEAST(uc1.connected_user_id, uc2.connected_user_id),
                LEAST(uc1.user_id, uc2.connected_user_id)) AS user2,
        GREATEST(uc1.user_id, uc1.connected_user_id, uc2.connected_user_id) AS user3
    FROM UserConnections uc1
    JOIN UserConnections uc2 ON uc1.connected_user_id = uc2.user_id
    JOIN UserConnections uc3 ON uc2.connected_user_id = uc3.connected_user_id
        AND uc3.user_id = uc1.user_id
)
SELECT
    user1,
    user2,
    user3,
    u1.username AS user1_name,
    u2.username AS user2_name,
    u3.username AS user3_name,
    'tight_cluster' AS community_type
FROM UserTriangles ut
JOIN users u1 ON ut.user1 = u1.user_id
JOIN users u2 ON ut.user2 = u2.user_id
JOIN users u3 ON ut.user3 = u3.user_id
LIMIT 20;

-- =========================================
-- 6. Follower Growth Analysis
-- =========================================

-- Track follower growth over time
WITH DailyFollowers AS (
    SELECT
        to_user_id,
        DATE(created_at) AS follow_date,
        COUNT(*) AS new_followers,
        SUM(COUNT(*)) OVER (
            PARTITION BY to_user_id
            ORDER BY DATE(created_at)
            ROWS UNBOUNDED PRECEDING
        ) AS cumulative_followers
    FROM relationships
    WHERE relationship_type = 'follow'
      AND status = 'active'
      AND created_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY to_user_id, DATE(created_at)
)
SELECT
    u.username,
    up.display_name,
    df.follow_date,
    df.new_followers,
    df.cumulative_followers,
    LAG(df.new_followers, 7) OVER (
        PARTITION BY df.to_user_id
        ORDER BY df.follow_date
    ) AS followers_week_ago,
    ROUND(
        100.0 * (df.new_followers - LAG(df.new_followers, 7) OVER (
            PARTITION BY df.to_user_id
            ORDER BY df.follow_date
        )) / GREATEST(LAG(df.new_followers, 7) OVER (
            PARTITION BY df.to_user_id
            ORDER BY df.follow_date
        ), 1),
        2
    ) AS week_over_week_growth
FROM DailyFollowers df
JOIN users u ON df.to_user_id = u.user_id
JOIN user_profiles up ON u.user_id = up.user_id
WHERE up.follower_count > 1000
ORDER BY df.to_user_id, df.follow_date DESC;

-- =========================================
-- 7. Relationship Reciprocity Analysis
-- =========================================

-- Find users who follow back vs one-way follows
SELECT
    u.user_id,
    u.username,
    up.display_name,
    COUNT(DISTINCT r1.to_user_id) AS following_count,
    COUNT(DISTINCT r2.from_user_id) AS follower_count,
    COUNT(DISTINCT
        CASE
            WHEN r3.relationship_id IS NOT NULL THEN r1.to_user_id
        END
    ) AS mutual_follow_count,
    ROUND(
        100.0 * COUNT(DISTINCT
            CASE
                WHEN r3.relationship_id IS NOT NULL THEN r1.to_user_id
            END
        ) / GREATEST(COUNT(DISTINCT r1.to_user_id), 1),
        2
    ) AS follow_back_rate
FROM users u
JOIN user_profiles up ON u.user_id = up.user_id
LEFT JOIN relationships r1 ON u.user_id = r1.from_user_id
    AND r1.relationship_type = 'follow'
    AND r1.status = 'active'
LEFT JOIN relationships r2 ON u.user_id = r2.to_user_id
    AND r2.relationship_type = 'follow'
    AND r2.status = 'active'
LEFT JOIN relationships r3 ON r1.to_user_id = r3.from_user_id
    AND r3.to_user_id = u.user_id
    AND r3.relationship_type = 'follow'
    AND r3.status = 'active'
WHERE u.status = 'active'
GROUP BY u.user_id
HAVING following_count > 10
ORDER BY follow_back_rate DESC
LIMIT 50;

-- =========================================
-- 8. Network Centrality Score
-- =========================================

-- Calculate importance of users in the network
WITH NetworkStats AS (
    SELECT
        u.user_id,
        -- In-degree centrality (followers)
        COUNT(DISTINCT r1.from_user_id) AS in_degree,
        -- Out-degree centrality (following)
        COUNT(DISTINCT r2.to_user_id) AS out_degree,
        -- Betweenness approximation (mutual connections)
        COUNT(DISTINCT r3.to_user_id) AS bridge_connections
    FROM users u
    LEFT JOIN relationships r1 ON u.user_id = r1.to_user_id
        AND r1.relationship_type = 'follow'
        AND r1.status = 'active'
    LEFT JOIN relationships r2 ON u.user_id = r2.from_user_id
        AND r2.relationship_type = 'follow'
        AND r2.status = 'active'
    LEFT JOIN relationships r3 ON u.user_id = r3.from_user_id
        AND r3.relationship_type = 'follow'
        AND r3.status = 'active'
        AND EXISTS (
            SELECT 1 FROM relationships r4
            WHERE r4.from_user_id = r3.to_user_id
              AND r4.to_user_id != u.user_id
              AND r4.relationship_type = 'follow'
              AND r4.status = 'active'
        )
    WHERE u.status = 'active'
    GROUP BY u.user_id
)
SELECT
    u.username,
    up.display_name,
    ns.in_degree AS followers,
    ns.out_degree AS following,
    ns.bridge_connections,
    -- Composite centrality score
    ROUND(
        (ns.in_degree * 0.5 +
         ns.bridge_connections * 0.3 +
         (ns.in_degree / GREATEST(ns.out_degree, 1)) * 0.2) / 100,
        4
    ) AS centrality_score,
    CASE
        WHEN ns.in_degree > 10000 THEN 'hub'
        WHEN ns.bridge_connections > 100 THEN 'bridge'
        WHEN ns.in_degree > ns.out_degree * 10 THEN 'authority'
        ELSE 'regular'
    END AS node_type
FROM NetworkStats ns
JOIN users u ON ns.user_id = u.user_id
JOIN user_profiles up ON u.user_id = up.user_id
ORDER BY centrality_score DESC
LIMIT 100;

-- =========================================
-- 9. Ghost Followers Detection
-- =========================================

-- Identify inactive followers (potential bots or abandoned accounts)
SELECT
    followed.user_id AS followed_user_id,
    followed.username AS followed_username,
    COUNT(DISTINCT follower.user_id) AS total_followers,
    COUNT(DISTINCT CASE
        WHEN follower.last_active < DATE_SUB(NOW(), INTERVAL 90 DAY)
        THEN follower.user_id
    END) AS inactive_followers,
    COUNT(DISTINCT CASE
        WHEN follower_profile.post_count = 0
        THEN follower.user_id
    END) AS never_posted_followers,
    COUNT(DISTINCT CASE
        WHEN follower_profile.profile_picture_url IS NULL
        THEN follower.user_id
    END) AS no_profile_pic_followers,
    ROUND(
        100.0 * COUNT(DISTINCT CASE
            WHEN follower.last_active < DATE_SUB(NOW(), INTERVAL 90 DAY)
            THEN follower.user_id
        END) / COUNT(DISTINCT follower.user_id),
        2
    ) AS ghost_follower_percentage
FROM relationships r
JOIN users followed ON r.to_user_id = followed.user_id
JOIN users follower ON r.from_user_id = follower.user_id
JOIN user_profiles follower_profile ON follower.user_id = follower_profile.user_id
WHERE r.relationship_type = 'follow'
  AND r.status = 'active'
  AND followed.status = 'active'
GROUP BY followed.user_id
HAVING total_followers > 100
ORDER BY ghost_follower_percentage DESC
LIMIT 50;

-- =========================================
-- 10. Social Graph Statistics
-- =========================================

-- Overall network statistics
SELECT
    'Network Statistics' AS metric_category,
    'Total Users' AS metric_name,
    COUNT(DISTINCT user_id) AS metric_value
FROM users
WHERE status = 'active'

UNION ALL

SELECT
    'Network Statistics',
    'Total Relationships',
    COUNT(*)
FROM relationships
WHERE status = 'active'

UNION ALL

SELECT
    'Network Statistics',
    'Average Followers per User',
    ROUND(AVG(follower_count), 2)
FROM user_profiles

UNION ALL

SELECT
    'Network Statistics',
    'Average Following per User',
    ROUND(AVG(following_count), 2)
FROM user_profiles

UNION ALL

SELECT
    'Network Statistics',
    'Users with > 1000 followers',
    COUNT(*)
FROM user_profiles
WHERE follower_count > 1000

UNION ALL

SELECT
    'Network Statistics',
    'Verified Users',
    COUNT(*)
FROM user_profiles
WHERE verified_badge = TRUE;