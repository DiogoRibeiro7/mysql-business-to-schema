-- ============================================================================
-- Streaming Platform - Feature Engineering for Machine Learning
-- ============================================================================
-- Description: SQL queries to generate features for various ML models
-- ============================================================================

-- ============================================================================
-- 1. USER FEATURES FOR CHURN PREDICTION
-- ============================================================================

CREATE OR REPLACE VIEW ml_user_churn_features AS
WITH user_activity AS (
    SELECT
        u.user_id,

        -- Demographic features
        CASE
            WHEN u.age_group = '18-24' THEN 1
            WHEN u.age_group = '25-34' THEN 2
            WHEN u.age_group = '35-44' THEN 3
            WHEN u.age_group = '45-54' THEN 4
            WHEN u.age_group = '55-64' THEN 5
            ELSE 6
        END AS age_bucket,

        CASE u.gender
            WHEN 'M' THEN 1
            WHEN 'F' THEN 2
            ELSE 0
        END AS gender_encoded,

        -- Subscription features
        DATEDIFF(CURDATE(), u.subscription_start_date) AS subscription_age_days,
        CASE
            WHEN u.subscription_type = 'free' THEN 0
            WHEN u.subscription_type = 'basic' THEN 1
            WHEN u.subscription_type = 'premium' THEN 2
            WHEN u.subscription_type = 'family' THEN 3
            ELSE -1
        END AS subscription_tier,

        -- Activity features (last 30 days)
        COUNT(DISTINCT DATE(vs.session_start)) AS active_days_30d,
        COUNT(vs.session_id) AS session_count_30d,
        COALESCE(AVG(vs.session_duration_minutes), 0) AS avg_session_duration_30d,
        COALESCE(STDDEV(vs.session_duration_minutes), 0) AS session_duration_std_30d,
        COALESCE(MAX(vs.session_duration_minutes), 0) AS max_session_duration_30d,
        COALESCE(MIN(vs.session_duration_minutes), 0) AS min_session_duration_30d,

        -- Activity features (last 7 days)
        SUM(CASE WHEN vs.session_start >= DATE_SUB(CURDATE(), INTERVAL 7 DAY) THEN 1 ELSE 0 END) AS session_count_7d,
        SUM(CASE WHEN vs.session_start >= DATE_SUB(CURDATE(), INTERVAL 7 DAY) THEN vs.session_duration_minutes ELSE 0 END) AS total_minutes_7d,

        -- Recency features
        DATEDIFF(CURDATE(), MAX(vs.session_start)) AS days_since_last_session,
        DATEDIFF(CURDATE(), MIN(vs.session_start)) AS days_since_first_session,

        -- Time pattern features
        AVG(CASE WHEN vs.is_weekend = 1 THEN 1 ELSE 0 END) AS weekend_usage_ratio,
        MODE(vs.hour_of_day) AS most_common_hour,
        COUNT(DISTINCT vs.device_type) AS device_variety,

        -- Engagement trend (linear regression slope)
        COALESCE(
            (COUNT(*) * SUM(UNIX_TIMESTAMP(vs.session_start) * vs.engagement_score) -
             SUM(UNIX_TIMESTAMP(vs.session_start)) * SUM(vs.engagement_score)) /
            NULLIF(COUNT(*) * SUM(POW(UNIX_TIMESTAMP(vs.session_start), 2)) -
                   POW(SUM(UNIX_TIMESTAMP(vs.session_start)), 2), 0),
        0) AS engagement_trend,

        -- Target variable
        CASE WHEN u.churn_date IS NOT NULL THEN 1 ELSE 0 END AS churned

    FROM users u
    LEFT JOIN viewing_sessions vs ON u.user_id = vs.user_id
        AND vs.session_start >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY u.user_id
),
content_preferences AS (
    SELECT
        i.user_id,

        -- Content diversity
        COUNT(DISTINCT c.primary_genre) AS genre_count,
        COUNT(DISTINCT c.content_type) AS content_type_count,
        COUNT(DISTINCT c.language) AS language_count,

        -- Rating behavior
        AVG(i.rating) AS avg_rating_given,
        STDDEV(i.rating) AS rating_std,
        COUNT(i.rating) AS ratings_count,

        -- Completion behavior
        AVG(i.completion_rate) AS avg_completion_rate,
        SUM(CASE WHEN i.completion_rate > 0.9 THEN 1 ELSE 0 END) AS completed_content_count,
        SUM(CASE WHEN i.completion_rate < 0.1 THEN 1 ELSE 0 END) AS abandoned_content_count,

        -- Content freshness preference
        AVG(i.time_since_release_days) AS avg_content_age_days,

        -- Interaction patterns
        SUM(CASE WHEN i.interaction_type = 'like' THEN 1 ELSE 0 END) AS like_count,
        SUM(CASE WHEN i.interaction_type = 'skip' THEN 1 ELSE 0 END) AS skip_count,
        SUM(CASE WHEN i.interaction_type = 'replay' THEN 1 ELSE 0 END) AS replay_count

    FROM interactions i
    JOIN content c ON i.content_id = c.content_id
    WHERE i.timestamp >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY i.user_id
)
SELECT
    ua.*,
    COALESCE(cp.genre_count, 0) AS genre_count,
    COALESCE(cp.content_type_count, 0) AS content_type_count,
    COALESCE(cp.avg_rating_given, 0) AS avg_rating_given,
    COALESCE(cp.ratings_count, 0) AS ratings_count,
    COALESCE(cp.avg_completion_rate, 0) AS avg_completion_rate,
    COALESCE(cp.completed_content_count, 0) AS completed_content_count,
    COALESCE(cp.abandoned_content_count, 0) AS abandoned_content_count,
    COALESCE(cp.like_count, 0) AS like_count,
    COALESCE(cp.skip_count, 0) AS skip_count,

    -- Derived ratios
    CASE
        WHEN ua.session_count_30d > 0
        THEN cp.completed_content_count / ua.session_count_30d
        ELSE 0
    END AS completion_per_session,

    CASE
        WHEN cp.like_count + cp.skip_count > 0
        THEN cp.like_count / (cp.like_count + cp.skip_count)
        ELSE 0
    END AS like_ratio

FROM user_activity ua
LEFT JOIN content_preferences cp ON ua.user_id = cp.user_id;

-- ============================================================================
-- 2. CONTENT FEATURES FOR POPULARITY PREDICTION
-- ============================================================================

CREATE OR REPLACE VIEW ml_content_popularity_features AS
WITH content_stats AS (
    SELECT
        c.content_id,

        -- Basic metadata features
        c.release_year,
        YEAR(CURDATE()) - c.release_year AS years_since_release,
        c.runtime_minutes,
        c.season_number,
        c.episode_number,
        LOG(c.production_budget + 1) AS log_budget,

        -- Category encoding
        CASE c.content_type
            WHEN 'movie' THEN 1
            WHEN 'series' THEN 2
            WHEN 'documentary' THEN 3
            WHEN 'special' THEN 4
            ELSE 0
        END AS content_type_encoded,

        -- Quality signals
        c.critic_score,
        c.audience_score,
        c.critic_score * c.audience_score / 100 AS quality_product,
        ABS(c.critic_score - c.audience_score) AS score_divergence,
        c.awards_count,

        -- Cast and crew influence
        c.star_power_score,
        c.director_popularity,

        -- Content richness
        LENGTH(c.description) AS description_length,
        LENGTH(c.synopsis) - LENGTH(REPLACE(c.synopsis, ' ', '')) + 1 AS synopsis_word_count

    FROM content c
),
early_engagement AS (
    -- First week performance indicators
    SELECT
        i.content_id,

        -- User reach
        COUNT(DISTINCT i.user_id) AS unique_viewers_week1,
        COUNT(i.interaction_id) AS total_views_week1,

        -- Engagement quality
        AVG(i.completion_rate) AS avg_completion_week1,
        STDDEV(i.completion_rate) AS completion_std_week1,
        AVG(i.watch_duration_seconds) / 60 AS avg_watch_minutes_week1,

        -- User feedback
        AVG(CASE WHEN i.rating IS NOT NULL THEN i.rating END) AS avg_rating_week1,
        COUNT(CASE WHEN i.rating IS NOT NULL THEN 1 END) AS rating_count_week1,

        -- Virality indicators
        SUM(CASE WHEN i.source = 'social_share' THEN 1 ELSE 0 END) AS social_shares_week1,
        SUM(CASE WHEN i.source = 'recommendation' THEN 1 ELSE 0 END) AS recommended_views_week1,
        SUM(CASE WHEN i.interaction_type = 'like' THEN 1 ELSE 0 END) AS likes_week1

    FROM interactions i
    JOIN content c ON i.content_id = c.content_id
    WHERE i.timestamp <= DATE_ADD(c.release_date, INTERVAL 7 DAY)
    GROUP BY i.content_id
),
network_effects AS (
    SELECT
        c.content_id,

        -- Franchise/series effects
        COUNT(DISTINCT c2.content_id) AS franchise_size,
        AVG(c2.total_views) AS franchise_avg_views,

        -- Similar content performance
        AVG(similar.total_views) AS similar_content_avg_views

    FROM content c
    LEFT JOIN content c2 ON c.franchise_id = c2.franchise_id
    LEFT JOIN content_similarity cs ON c.content_id = cs.content_id_1
    LEFT JOIN content similar ON cs.content_id_2 = similar.content_id
    GROUP BY c.content_id
)
SELECT
    cs.*,
    COALESCE(ee.unique_viewers_week1, 0) AS unique_viewers_week1,
    COALESCE(ee.total_views_week1, 0) AS total_views_week1,
    COALESCE(ee.avg_completion_week1, 0) AS avg_completion_week1,
    COALESCE(ee.avg_rating_week1, 0) AS avg_rating_week1,
    COALESCE(ee.social_shares_week1, 0) AS social_shares_week1,
    COALESCE(ee.likes_week1, 0) AS likes_week1,
    COALESCE(ne.franchise_avg_views, 0) AS franchise_avg_views,
    COALESCE(ne.similar_content_avg_views, 0) AS similar_content_avg_views,

    -- Virality coefficient
    CASE
        WHEN ee.unique_viewers_week1 > 0
        THEN ee.social_shares_week1 / ee.unique_viewers_week1
        ELSE 0
    END AS virality_coefficient,

    -- Target variable (log scale for better distribution)
    LOG(c.total_views + 1) AS log_total_views,
    c.total_views AS total_views

FROM content_stats cs
JOIN content c ON cs.content_id = c.content_id
LEFT JOIN early_engagement ee ON cs.content_id = ee.content_id
LEFT JOIN network_effects ne ON cs.content_id = ne.content_id;

-- ============================================================================
-- 3. SESSION FEATURES FOR ENGAGEMENT PREDICTION
-- ============================================================================

CREATE OR REPLACE VIEW ml_session_engagement_features AS
SELECT
    vs.session_id,
    vs.user_id,

    -- Temporal features
    DAYOFWEEK(vs.session_start) AS day_of_week,
    vs.hour_of_day,
    vs.is_weekend,
    vs.is_holiday,
    MONTH(vs.session_start) AS month,

    -- Context features
    CASE vs.device_type
        WHEN 'mobile' THEN 1
        WHEN 'tablet' THEN 2
        WHEN 'desktop' THEN 3
        WHEN 'tv' THEN 4
        ELSE 0
    END AS device_encoded,

    CASE vs.network_quality
        WHEN 'poor' THEN 1
        WHEN 'fair' THEN 2
        WHEN 'good' THEN 3
        WHEN 'excellent' THEN 4
        ELSE 0
    END AS network_quality_score,

    -- User history features
    u.total_watch_time_hours AS user_total_watch_hours,
    u.avg_session_duration_minutes AS user_avg_session_minutes,
    u.content_diversity_score AS user_diversity_score,

    -- Session sequence features
    JSON_LENGTH(vs.content_sequence) AS content_count,
    JSON_LENGTH(vs.action_sequence) AS action_count,

    -- Previous session features
    LAG(vs.session_duration_minutes) OVER (PARTITION BY vs.user_id ORDER BY vs.session_start) AS prev_session_duration,
    LAG(vs.engagement_score) OVER (PARTITION BY vs.user_id ORDER BY vs.session_start) AS prev_engagement_score,
    UNIX_TIMESTAMP(vs.session_start) - LAG(UNIX_TIMESTAMP(vs.session_start)) OVER (PARTITION BY vs.user_id ORDER BY vs.session_start) AS seconds_since_last_session,

    -- Target variables
    vs.session_duration_minutes,
    vs.engagement_score,
    vs.content_completed_count,
    vs.converted_to_paid

FROM viewing_sessions vs
JOIN users u ON vs.user_id = u.user_id;

-- ============================================================================
-- 4. RECOMMENDATION FEATURES (USER-ITEM MATRIX)
-- ============================================================================

CREATE OR REPLACE VIEW ml_recommendation_features AS
SELECT
    i.user_id,
    i.content_id,

    -- Interaction strength (implicit feedback)
    GREATEST(
        COALESCE(i.completion_rate, 0) * 0.4,
        COALESCE(i.rating / 5.0, 0) * 0.3,
        LEAST(i.watch_duration_seconds / (c.runtime_minutes * 60), 1.0) * 0.3
    ) AS interaction_score,

    -- Context features
    i.device_type,
    i.source,
    i.position_in_list,

    -- Temporal features
    DATEDIFF(CURDATE(), DATE(i.timestamp)) AS days_ago,
    HOUR(i.timestamp) AS interaction_hour,
    DAYOFWEEK(i.timestamp) AS interaction_dow,

    -- User features at interaction time
    u.age_group,
    u.subscription_type,

    -- Content features
    c.content_type,
    c.primary_genre,
    c.release_year,
    c.runtime_minutes,
    c.critic_score,
    c.audience_score,

    -- Affinity features
    (
        SELECT COUNT(*)
        FROM interactions i2
        WHERE i2.user_id = i.user_id
            AND i2.content_id IN (
                SELECT content_id_2
                FROM content_similarity
                WHERE content_id_1 = i.content_id
                    AND similarity_score > 0.7
            )
    ) AS similar_content_watched,

    -- Collaborative signals
    (
        SELECT AVG(i2.rating)
        FROM interactions i2
        WHERE i2.content_id = i.content_id
            AND i2.user_id != i.user_id
            AND i2.user_id IN (
                SELECT user_id
                FROM user_similarity
                WHERE similar_user_id = i.user_id
                    AND similarity_score > 0.5
            )
    ) AS similar_users_avg_rating

FROM interactions i
JOIN users u ON i.user_id = u.user_id
JOIN content c ON i.content_id = c.content_id
WHERE i.timestamp >= DATE_SUB(CURDATE(), INTERVAL 90 DAY);

-- ============================================================================
-- 5. TIME SERIES FEATURES FOR DEMAND FORECASTING
-- ============================================================================

CREATE OR REPLACE VIEW ml_demand_forecast_features AS
WITH hourly_metrics AS (
    SELECT
        DATE_FORMAT(session_start, '%Y-%m-%d %H:00:00') AS hour_slot,

        -- Current metrics
        COUNT(DISTINCT user_id) AS unique_users,
        COUNT(session_id) AS session_count,
        SUM(session_duration_minutes) AS total_minutes,
        AVG(engagement_score) AS avg_engagement,

        -- Device distribution
        SUM(CASE WHEN device_type = 'mobile' THEN 1 ELSE 0 END) AS mobile_sessions,
        SUM(CASE WHEN device_type = 'tv' THEN 1 ELSE 0 END) AS tv_sessions,

        -- Content type distribution
        SUM(content_completed_count) AS content_completed,
        SUM(CASE WHEN converted_to_paid = 1 THEN 1 ELSE 0 END) AS conversions

    FROM viewing_sessions
    WHERE session_start >= DATE_SUB(NOW(), INTERVAL 90 DAY)
    GROUP BY DATE_FORMAT(session_start, '%Y-%m-%d %H:00:00')
)
SELECT
    hour_slot,
    unique_users,
    session_count,
    total_minutes,
    avg_engagement,

    -- Lag features (previous periods)
    LAG(session_count, 1) OVER (ORDER BY hour_slot) AS sessions_lag_1h,
    LAG(session_count, 24) OVER (ORDER BY hour_slot) AS sessions_lag_24h,
    LAG(session_count, 168) OVER (ORDER BY hour_slot) AS sessions_lag_1w,

    -- Moving averages
    AVG(session_count) OVER (ORDER BY hour_slot ROWS BETWEEN 24 PRECEDING AND CURRENT ROW) AS ma_24h,
    AVG(session_count) OVER (ORDER BY hour_slot ROWS BETWEEN 168 PRECEDING AND CURRENT ROW) AS ma_1w,

    -- Trend features
    session_count - LAG(session_count, 24) OVER (ORDER BY hour_slot) AS daily_change,
    session_count - LAG(session_count, 168) OVER (ORDER BY hour_slot) AS weekly_change,

    -- Temporal encoding
    HOUR(hour_slot) AS hour_of_day,
    DAYOFWEEK(hour_slot) AS day_of_week,
    DAYOFMONTH(hour_slot) AS day_of_month,
    MONTH(hour_slot) AS month,

    -- Cyclical encoding (for neural networks)
    SIN(2 * PI() * HOUR(hour_slot) / 24) AS hour_sin,
    COS(2 * PI() * HOUR(hour_slot) / 24) AS hour_cos,
    SIN(2 * PI() * DAYOFWEEK(hour_slot) / 7) AS dow_sin,
    COS(2 * PI() * DAYOFWEEK(hour_slot) / 7) AS dow_cos

FROM hourly_metrics
ORDER BY hour_slot;

-- ============================================================================
-- 6. A/B TEST FEATURES FOR CAUSAL INFERENCE
-- ============================================================================

CREATE OR REPLACE VIEW ml_experiment_features AS
SELECT
    e.experiment_id,
    e.experiment_name,
    u.user_id,
    u.ab_test_group,

    -- Pre-treatment covariates (for matching)
    u.age_group,
    u.gender,
    u.country_code,
    u.subscription_type AS pre_subscription_type,
    u.total_watch_time_hours AS pre_watch_hours,

    -- Treatment indicator
    CASE
        WHEN u.ab_test_group = e.control_group THEN 0
        ELSE 1
    END AS is_treatment,

    -- Outcome variables
    (
        SELECT SUM(session_duration_minutes)
        FROM viewing_sessions vs
        WHERE vs.user_id = u.user_id
            AND vs.session_start BETWEEN e.start_date AND e.end_date
    ) AS total_minutes_during_experiment,

    (
        SELECT COUNT(DISTINCT DATE(session_start))
        FROM viewing_sessions vs
        WHERE vs.user_id = u.user_id
            AND vs.session_start BETWEEN e.start_date AND e.end_date
    ) AS active_days_during_experiment,

    (
        SELECT AVG(engagement_score)
        FROM viewing_sessions vs
        WHERE vs.user_id = u.user_id
            AND vs.session_start BETWEEN e.start_date AND e.end_date
    ) AS avg_engagement_during_experiment,

    -- Check for conversion
    CASE
        WHEN u.subscription_type != 'free'
            AND u.subscription_start_date BETWEEN e.start_date AND e.end_date
        THEN 1
        ELSE 0
    END AS converted_during_experiment,

    -- Check for churn
    CASE
        WHEN u.churn_date BETWEEN e.start_date AND e.end_date
        THEN 1
        ELSE 0
    END AS churned_during_experiment

FROM experiments e
JOIN users u ON u.ab_test_group IN (
    e.control_group,
    JSON_UNQUOTE(JSON_EXTRACT(e.treatment_groups, '$[0]')),
    JSON_UNQUOTE(JSON_EXTRACT(e.treatment_groups, '$[1]')),
    JSON_UNQUOTE(JSON_EXTRACT(e.treatment_groups, '$[2]'))
)
WHERE e.start_date <= CURDATE()
    AND e.end_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY);

-- ============================================================================
-- Feature Store Management
-- ============================================================================

-- Procedure to refresh all feature views
DELIMITER //

CREATE PROCEDURE refresh_ml_features()
BEGIN
    -- Log start time
    INSERT INTO ml_feature_refresh_log (feature_set, start_time, status)
    VALUES ('all_features', NOW(), 'running');

    -- Refresh each view
    -- Note: In production, these would be materialized views

    -- Update completion time
    UPDATE ml_feature_refresh_log
    SET end_time = NOW(),
        status = 'completed',
        rows_processed = (
            SELECT COUNT(*) FROM ml_user_churn_features
        )
    WHERE feature_set = 'all_features'
        AND status = 'running';

    SELECT 'Feature refresh completed' AS status;
END //

DELIMITER ;