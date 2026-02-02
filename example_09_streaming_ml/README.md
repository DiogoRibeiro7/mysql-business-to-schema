# Streaming Platform Analytics - ML/Data Science Database

## Overview

This database is specifically designed for data science and machine learning workloads, modeling a streaming platform (like Netflix, Spotify, YouTube) with rich behavioral data, content features, and multiple ML use cases built-in.

## Why This Database for ML/DS?

This schema provides:
- **Rich Feature Sets**: User demographics, behavior, content metadata, temporal patterns
- **Multiple ML Problems**: Classification, regression, clustering, recommendation, time series
- **A/B Testing Framework**: Built-in experiment tracking for causal inference
- **Graph Relationships**: Social networks, content similarity graphs
- **Text Data**: Reviews, descriptions for NLP tasks
- **Time Series**: Viewing patterns, engagement metrics
- **High Cardinality**: Categorical features for embedding learning

## ML/DS Use Cases

### 1. Recommendation Systems
- **Collaborative Filtering**: User-item interaction matrix
- **Content-Based**: Content features and metadata
- **Hybrid Models**: Combining CF + content + contextual features
- **Session-Based**: Real-time next-item prediction
- **Explainable Recommendations**: Feature importance tracking

### 2. User Analytics
- **Churn Prediction**: Binary classification with time-based features
- **LTV Prediction**: Regression for customer lifetime value
- **Segmentation**: Clustering users by behavior
- **Anomaly Detection**: Unusual viewing patterns
- **Cohort Analysis**: User retention by acquisition source

### 3. Content Analytics
- **Popularity Prediction**: Forecast viral content
- **Quality Scoring**: Predict ratings before release
- **Optimal Release Time**: Time series analysis
- **Genre Classification**: Multi-label classification
- **Thumbnail Optimization**: A/B testing CTR

### 4. Business Intelligence
- **Demand Forecasting**: Predict server load
- **Revenue Optimization**: Pricing strategies
- **Content Investment**: ROI prediction
- **Market Expansion**: Geographic analysis
- **Competitive Analysis**: Market share trends

## Database Schema for ML

### Core Entities Optimized for ML

```sql
-- Users table with rich features for ML
CREATE TABLE users (
    user_id BIGINT PRIMARY KEY,
    -- Demographics (categorical features)
    age_group VARCHAR(20),  -- Bucketed for privacy
    gender VARCHAR(20),
    country_code VARCHAR(2),
    language_preference VARCHAR(5),

    -- Behavioral segments (derived features)
    user_segment VARCHAR(50),  -- 'binge_watcher', 'casual', 'new'
    lifecycle_stage VARCHAR(50),  -- 'acquisition', 'activation', 'retention'

    -- Subscription data (targets for prediction)
    subscription_type VARCHAR(50),
    is_trial BOOLEAN,
    subscription_start_date DATE,
    churn_date DATE,  -- NULL if active (target for churn prediction)

    -- Engagement metrics (aggregated features)
    total_watch_time_hours FLOAT,
    avg_session_duration_minutes FLOAT,
    content_diversity_score FLOAT,  -- Entropy of genres watched

    -- ML-specific columns
    acquisition_channel VARCHAR(50),  -- For attribution
    ab_test_group VARCHAR(50),  -- For experimentation
    propensity_score FLOAT,  -- Pre-calculated scores
    embedding_vector JSON  -- User embedding from deep learning model
);

-- Content table with features for similarity/recommendation
CREATE TABLE content (
    content_id BIGINT PRIMARY KEY,
    title VARCHAR(500),
    content_type VARCHAR(50),  -- 'movie', 'series', 'documentary'

    -- Content features for ML
    release_year INT,
    runtime_minutes INT,
    production_budget DECIMAL(15,2),

    -- Multi-label classification targets
    genres JSON,  -- ['action', 'comedy', 'drama']
    tags JSON,  -- ['award-winning', 'based-on-book', 'sequel']

    -- Text features for NLP
    description TEXT,
    synopsis TEXT,

    -- Quality indicators
    critic_score FLOAT,
    audience_score FLOAT,
    awards_count INT,

    -- Popularity metrics (targets for prediction)
    total_views BIGINT,
    trending_score FLOAT,
    virality_coefficient FLOAT,

    -- ML features
    content_embedding JSON,  -- Pre-trained embeddings
    feature_vector JSON,  -- Extracted features (color histogram, audio features)
    predicted_popularity FLOAT,
    quality_score FLOAT
);

-- Viewing sessions with sequential data for RNNs
CREATE TABLE viewing_sessions (
    session_id BIGINT PRIMARY KEY,
    user_id BIGINT,
    session_start TIMESTAMP,
    session_end TIMESTAMP,

    -- Session context (features)
    device_type VARCHAR(50),
    network_quality VARCHAR(20),
    day_of_week INT,
    hour_of_day INT,
    is_weekend BOOLEAN,
    is_holiday BOOLEAN,

    -- Sequence data for ML
    content_sequence JSON,  -- Order of content viewed
    action_sequence JSON,  -- ['play', 'pause', 'skip', 'like']
    timestamp_sequence JSON,  -- Timestamps for each action

    -- Session outcomes (targets)
    session_duration_minutes FLOAT,
    content_completed_count INT,
    engagement_score FLOAT,
    converted_to_paid BOOLEAN
);

-- Interactions for collaborative filtering
CREATE TABLE interactions (
    interaction_id BIGINT PRIMARY KEY,
    user_id BIGINT,
    content_id BIGINT,
    interaction_type VARCHAR(50),  -- 'view', 'like', 'skip', 'complete'

    -- Implicit feedback signals
    watch_duration_seconds INT,
    completion_rate FLOAT,  -- 0.0 to 1.0

    -- Explicit feedback
    rating INT,  -- 1-5 stars

    -- Context for context-aware recommendations
    timestamp TIMESTAMP,
    device_type VARCHAR(50),
    source VARCHAR(100),  -- 'search', 'recommendation', 'browse'
    position_in_list INT,  -- For position bias correction

    -- ML features
    is_repeated_viewing BOOLEAN,
    time_since_release_days INT,
    user_content_affinity_score FLOAT  -- Pre-calculated
);

-- A/B Testing Framework
CREATE TABLE experiments (
    experiment_id INT PRIMARY KEY,
    experiment_name VARCHAR(200),
    hypothesis TEXT,

    -- Experiment design
    start_date DATE,
    end_date DATE,
    control_group VARCHAR(100),
    treatment_groups JSON,  -- Multiple treatment arms

    -- Statistical parameters
    minimum_sample_size INT,
    confidence_level FLOAT,
    expected_effect_size FLOAT,

    -- Results
    p_value FLOAT,
    effect_size FLOAT,
    confidence_interval_lower FLOAT,
    confidence_interval_upper FLOAT,
    decision VARCHAR(50)  -- 'ship', 'iterate', 'abandon'
);

-- Feature Store for ML
CREATE TABLE ml_features (
    feature_id BIGINT PRIMARY KEY,
    entity_type VARCHAR(50),  -- 'user', 'content', 'session'
    entity_id BIGINT,
    feature_name VARCHAR(200),
    feature_value FLOAT,
    feature_timestamp TIMESTAMP,

    -- Feature metadata
    feature_version VARCHAR(20),
    computation_time_ms INT,
    is_derived BOOLEAN,
    parent_features JSON,

    INDEX idx_entity_feature (entity_type, entity_id, feature_name)
);

-- Model Performance Tracking
CREATE TABLE model_metrics (
    metric_id BIGINT PRIMARY KEY,
    model_name VARCHAR(200),
    model_version VARCHAR(50),

    -- Model metadata
    algorithm VARCHAR(100),
    hyperparameters JSON,
    training_date TIMESTAMP,

    -- Performance metrics
    metric_type VARCHAR(50),  -- 'accuracy', 'auc', 'rmse', 'map@k'
    metric_value FLOAT,

    -- Data split info
    dataset_split VARCHAR(50),  -- 'train', 'validation', 'test'
    sample_size INT,

    -- Business metrics
    business_impact FLOAT,  -- Revenue impact, user satisfaction

    INDEX idx_model_date (model_name, training_date)
);
```

## ML Feature Engineering

### User Features
```sql
-- User engagement features for churn prediction
CREATE VIEW ml_user_features AS
SELECT
    u.user_id,

    -- Demographic features
    CASE age_group
        WHEN '18-24' THEN 1
        WHEN '25-34' THEN 2
        WHEN '35-44' THEN 3
        WHEN '45-54' THEN 4
        WHEN '55+' THEN 5
    END as age_bucket,

    -- Behavioral features (last 30 days)
    COUNT(DISTINCT DATE(vs.session_start)) as active_days_30d,
    COUNT(DISTINCT vs.session_id) as session_count_30d,
    AVG(vs.session_duration_minutes) as avg_session_duration_30d,
    STDDEV(vs.session_duration_minutes) as session_duration_variance,

    -- Content diversity
    COUNT(DISTINCT c.genres) as genre_diversity,
    ENTROPY(c.genres) as genre_entropy,

    -- Temporal features
    DATEDIFF(CURDATE(), MAX(vs.session_start)) as days_since_last_session,
    HOUR(AVG(vs.session_start)) as preferred_hour,

    -- Engagement trend
    REGR_SLOPE(vs.engagement_score, UNIX_TIMESTAMP(vs.session_start)) as engagement_trend,

    -- Target variable
    CASE WHEN u.churn_date IS NULL THEN 0 ELSE 1 END as churned

FROM users u
LEFT JOIN viewing_sessions vs ON u.user_id = vs.user_id
LEFT JOIN interactions i ON u.user_id = i.user_id
LEFT JOIN content c ON i.content_id = c.content_id
WHERE vs.session_start >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY u.user_id;
```

### Content Features
```sql
-- Content features for popularity prediction
CREATE VIEW ml_content_features AS
SELECT
    c.content_id,

    -- Basic features
    c.release_year,
    c.runtime_minutes,
    LOG(c.production_budget + 1) as log_budget,

    -- Quality signals
    c.critic_score * c.audience_score as quality_product,
    c.awards_count,

    -- Temporal features
    DATEDIFF(CURDATE(), c.release_date) as days_since_release,

    -- Engagement metrics (first week)
    COUNT(DISTINCT i.user_id) as unique_viewers_week1,
    AVG(i.completion_rate) as avg_completion_rate,
    STDDEV(i.rating) as rating_variance,

    -- Network effects
    COUNT(DISTINCT i2.user_id) as referral_views,

    -- Text features (would need NLP processing)
    LENGTH(c.description) as description_length,

    -- Target
    LOG(c.total_views + 1) as log_total_views

FROM content c
LEFT JOIN interactions i ON c.content_id = i.content_id
    AND i.timestamp <= DATE_ADD(c.release_date, INTERVAL 7 DAY)
LEFT JOIN interactions i2 ON c.content_id = i2.content_id
    AND i2.source = 'social_share'
GROUP BY c.content_id;
```

## Sample ML Queries

### 1. Collaborative Filtering Matrix
```sql
-- User-Item interaction matrix for matrix factorization
SELECT
    user_id,
    content_id,
    -- Implicit feedback signal
    GREATEST(
        completion_rate,
        rating / 5.0,
        LEAST(watch_duration_seconds / 3600.0, 1.0)
    ) as interaction_strength
FROM interactions
WHERE timestamp >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
ORDER BY user_id, content_id;
```

### 2. Time Series for Demand Forecasting
```sql
-- Hourly viewing patterns for forecasting
SELECT
    DATE_FORMAT(session_start, '%Y-%m-%d %H:00:00') as hour,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(*) as session_count,
    SUM(session_duration_minutes) as total_minutes_watched,
    AVG(engagement_score) as avg_engagement,
    -- Lag features
    LAG(COUNT(*), 1) OVER (ORDER BY hour) as sessions_prev_hour,
    LAG(COUNT(*), 24) OVER (ORDER BY hour) as sessions_same_hour_yesterday,
    LAG(COUNT(*), 168) OVER (ORDER BY hour) as sessions_same_hour_last_week
FROM viewing_sessions
GROUP BY DATE_FORMAT(session_start, '%Y-%m-%d %H:00:00')
ORDER BY hour;
```

### 3. A/B Test Analysis
```sql
-- Statistical significance testing for experiments
WITH experiment_results AS (
    SELECT
        e.experiment_name,
        u.ab_test_group,
        COUNT(DISTINCT u.user_id) as users,
        AVG(CASE WHEN u.churn_date IS NULL THEN 0 ELSE 1 END) as churn_rate,
        AVG(total_watch_time_hours) as avg_watch_time,
        STDDEV(total_watch_time_hours) as std_watch_time
    FROM users u
    JOIN experiments e ON u.ab_test_group IN (
        SELECT JSON_UNQUOTE(JSON_EXTRACT(treatment_groups, '$[*]'))
        UNION SELECT control_group
    )
    WHERE e.experiment_id = 1
    GROUP BY e.experiment_name, u.ab_test_group
)
SELECT
    experiment_name,
    ab_test_group,
    users,
    churn_rate,
    avg_watch_time,
    -- Calculate t-statistic
    (avg_watch_time - LAG(avg_watch_time) OVER (ORDER BY ab_test_group)) /
    SQRT(
        POW(std_watch_time, 2) / users +
        POW(LAG(std_watch_time) OVER (ORDER BY ab_test_group), 2) /
        LAG(users) OVER (ORDER BY ab_test_group)
    ) as t_statistic
FROM experiment_results;
```

### 4. User Clustering Features
```sql
-- Features for user segmentation
SELECT
    user_id,
    -- Viewing behavior
    total_watch_time_hours,
    avg_session_duration_minutes,
    content_diversity_score,

    -- Content preferences (would need one-hot encoding)
    (SELECT genres FROM content c
     JOIN interactions i ON c.content_id = i.content_id
     WHERE i.user_id = u.user_id
     GROUP BY genres
     ORDER BY COUNT(*) DESC
     LIMIT 1) as favorite_genre,

    -- Engagement patterns
    CASE
        WHEN HOUR(session_start) BETWEEN 6 AND 12 THEN 'morning'
        WHEN HOUR(session_start) BETWEEN 12 AND 18 THEN 'afternoon'
        WHEN HOUR(session_start) BETWEEN 18 AND 24 THEN 'evening'
        ELSE 'night'
    END as preferred_time,

    -- Device usage
    (SELECT device_type FROM viewing_sessions
     WHERE user_id = u.user_id
     GROUP BY device_type
     ORDER BY COUNT(*) DESC
     LIMIT 1) as primary_device

FROM users u;
```

### 5. Content Similarity Matrix
```sql
-- Content-content similarity for recommendation
WITH content_features AS (
    SELECT
        c1.content_id as content_id_1,
        c2.content_id as content_id_2,
        -- Jaccard similarity for genres
        (
            SELECT COUNT(*)
            FROM JSON_TABLE(c1.genres, '$[*]' COLUMNS(g1 VARCHAR(50) PATH '$')) g1
            JOIN JSON_TABLE(c2.genres, '$[*]' COLUMNS(g2 VARCHAR(50) PATH '$')) g2
            ON g1.g1 = g2.g2
        ) / (
            SELECT COUNT(DISTINCT g)
            FROM (
                SELECT g1 FROM JSON_TABLE(c1.genres, '$[*]' COLUMNS(g1 VARCHAR(50) PATH '$'))
                UNION
                SELECT g2 FROM JSON_TABLE(c2.genres, '$[*]' COLUMNS(g2 VARCHAR(50) PATH '$'))
            ) combined
        ) as genre_similarity,

        -- Numerical feature similarity
        1 - ABS(c1.runtime_minutes - c2.runtime_minutes) / 300.0 as runtime_similarity,
        1 - ABS(c1.release_year - c2.release_year) / 50.0 as era_similarity,

        -- Collaborative similarity (users who watched both)
        (
            SELECT COUNT(DISTINCT user_id)
            FROM interactions
            WHERE content_id IN (c1.content_id, c2.content_id)
            GROUP BY user_id
            HAVING COUNT(DISTINCT content_id) = 2
        ) as co_watch_count

    FROM content c1
    CROSS JOIN content c2
    WHERE c1.content_id < c2.content_id
)
SELECT
    content_id_1,
    content_id_2,
    (genre_similarity * 0.4 +
     runtime_similarity * 0.2 +
     era_similarity * 0.2 +
     LEAST(co_watch_count / 1000.0, 1.0) * 0.2) as similarity_score
FROM content_features
WHERE (genre_similarity * 0.4 +
       runtime_similarity * 0.2 +
       era_similarity * 0.2 +
       LEAST(co_watch_count / 1000.0, 1.0) * 0.2) > 0.5
ORDER BY similarity_score DESC;
```

## ML Pipeline Integration

### 1. Feature Engineering Pipeline
```python
# Example Python integration for feature engineering
import pandas as pd
from sklearn.preprocessing import StandardScaler
from sklearn.decomposition import PCA

# Extract features from database
query = """
    SELECT * FROM ml_user_features
    WHERE churned IS NOT NULL
"""
df = pd.read_sql(query, connection)

# Feature scaling
scaler = StandardScaler()
scaled_features = scaler.fit_transform(df.drop(['user_id', 'churned'], axis=1))

# Dimensionality reduction
pca = PCA(n_components=50)
reduced_features = pca.fit_transform(scaled_features)

# Store back to database
feature_df = pd.DataFrame(reduced_features)
feature_df['user_id'] = df['user_id']
feature_df.to_sql('ml_user_embeddings', connection, if_exists='replace')
```

### 2. Model Training Query
```sql
-- Training dataset with balanced classes
WITH balanced_dataset AS (
    -- Get all churned users
    SELECT * FROM ml_user_features WHERE churned = 1
    UNION ALL
    -- Sample equal number of non-churned users
    SELECT * FROM ml_user_features
    WHERE churned = 0
    ORDER BY RAND()
    LIMIT (SELECT COUNT(*) FROM ml_user_features WHERE churned = 1)
)
SELECT
    -- Features
    age_bucket,
    active_days_30d,
    session_count_30d,
    avg_session_duration_30d,
    session_duration_variance,
    genre_diversity,
    genre_entropy,
    days_since_last_session,
    preferred_hour,
    engagement_trend,
    -- Target
    churned
FROM balanced_dataset
ORDER BY RAND()  -- Shuffle for training
```

### 3. Real-time Scoring
```sql
-- Score users for churn risk in real-time
CREATE PROCEDURE score_churn_risk(IN user_id_param BIGINT)
BEGIN
    DECLARE risk_score FLOAT;

    -- Calculate risk score using pre-trained model weights
    SELECT
        -- Simplified logistic regression scoring
        1 / (1 + EXP(-(
            -2.5 +  -- Intercept
            0.3 * age_bucket +
            -0.1 * active_days_30d +
            -0.05 * session_count_30d +
            -0.02 * avg_session_duration_30d +
            0.5 * days_since_last_session +
            -0.3 * engagement_trend
        )))
    INTO risk_score
    FROM ml_user_features
    WHERE user_id = user_id_param;

    -- Update user record with score
    UPDATE users
    SET propensity_score = risk_score,
        user_segment = CASE
            WHEN risk_score > 0.8 THEN 'high_risk'
            WHEN risk_score > 0.5 THEN 'medium_risk'
            ELSE 'low_risk'
        END
    WHERE user_id = user_id_param;

    SELECT risk_score;
END;
```

## Data Science Use Cases

### 1. Recommendation Systems
- **Collaborative Filtering**: User-item matrices
- **Content-Based**: Content similarity
- **Hybrid**: Combining multiple signals
- **Deep Learning**: Neural collaborative filtering
- **Reinforcement Learning**: Contextual bandits

### 2. Predictive Analytics
- **Churn Prediction**: Classification
- **LTV Forecasting**: Regression
- **Demand Forecasting**: Time series
- **Content Popularity**: Regression/ranking

### 3. Experimentation
- **A/B Testing**: Built-in framework
- **Multi-armed Bandits**: Exploration/exploitation
- **Causal Inference**: Observational studies

### 4. Natural Language Processing
- **Sentiment Analysis**: Reviews and comments
- **Topic Modeling**: Content descriptions
- **Named Entity Recognition**: Metadata extraction

### 5. Computer Vision
- **Thumbnail Optimization**: CTR prediction
- **Content Classification**: Auto-tagging
- **Quality Assessment**: Video quality scoring

## Performance Optimization for ML

### Indexing Strategy
```sql
-- Indexes optimized for ML workloads
CREATE INDEX idx_interactions_user_time ON interactions(user_id, timestamp DESC);
CREATE INDEX idx_interactions_content_time ON interactions(content_id, timestamp DESC);
CREATE INDEX idx_sessions_user_date ON viewing_sessions(user_id, DATE(session_start));
CREATE INDEX idx_ml_features_lookup ON ml_features(entity_type, entity_id, feature_name);
```

### Materialized Views for Features
```sql
-- Pre-compute expensive features
CREATE MATERIALIZED VIEW user_features_daily AS
SELECT
    user_id,
    DATE(CURDATE()) as feature_date,
    -- Expensive aggregations
    ...
REFRESH COMPLETE ON DEMAND;
```

### Partitioning for Time Series
```sql
ALTER TABLE interactions
PARTITION BY RANGE (YEAR(timestamp)) (
    PARTITION p2023 VALUES LESS THAN (2024),
    PARTITION p2024 VALUES LESS THAN (2025),
    PARTITION p2025 VALUES LESS THAN (2026),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);
```

## ML Model Deployment

### Online Inference
- Real-time recommendations
- Dynamic pricing
- Fraud detection
- Content moderation

### Batch Inference
- Daily churn scoring
- Weekly content popularity updates
- Monthly user segmentation
- Quarterly LTV recalculation

### Model Monitoring
```sql
-- Track model performance over time
SELECT
    DATE(prediction_time) as date,
    model_name,
    AVG(ABS(predicted_value - actual_value)) as mae,
    SQRT(AVG(POW(predicted_value - actual_value, 2))) as rmse,
    COUNT(*) as prediction_count
FROM model_predictions
WHERE prediction_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY DATE(prediction_time), model_name
ORDER BY date DESC;
```

## Benefits for Data Science

1. **Rich Features**: 100+ engineered features ready for ML
2. **Multiple Targets**: Churn, LTV, engagement, ratings
3. **Temporal Data**: Time series for forecasting
4. **Graph Structure**: User-content, content-content networks
5. **Text Data**: Descriptions, reviews for NLP
6. **Experiment Framework**: A/B testing built-in
7. **Feature Store**: Centralized feature management
8. **Model Tracking**: Performance monitoring

This database provides a complete playground for data scientists to practice:
- Classification (churn, content categorization)
- Regression (ratings, watch time, revenue)
- Clustering (user segmentation, content grouping)
- Recommendation (collaborative, content-based, hybrid)
- Time Series (forecasting, anomaly detection)
- NLP (sentiment, topics, summarization)
- Reinforcement Learning (personalization, exploration)
- Causal Inference (A/B tests, observational studies)