# Streaming ML Platform Data Generator

## Overview

Generates synthetic data for a streaming platform with machine learning features, including user behavior, content recommendations, A/B testing, and predictive analytics.

## Features

### Data Generated

1. **Static Data**
   - Categories (20 content categories)
   - Creators (500 content creators with popularity scores)
   - Content Items (5,000 videos/music/podcasts)
   - Users (10,000 users across segments)

2. **Behavioral Data**
   - User Sessions (device, duration, bounce rate)
   - Interaction Events (views, likes, shares, comments)
   - Watch Time Analytics
   - Engagement Patterns

3. **ML/AI Features**
   - Recommendation Data (5 algorithms)
   - User Feature Vectors (18 features)
   - A/B Test Assignments (3 concurrent tests)
   - Churn Predictions

4. **Revenue Data**
   - Subscription Payments
   - In-App Purchases
   - Payment Methods
   - Transaction Status

## Configuration

Edit `config.yaml` to adjust:

```yaml
counts:
  users: 10000              # Number of platform users
  content_items: 5000       # Videos, music, podcasts
  events_per_user_per_day: [10, 100]  # Interaction range
  days_of_data: 30          # Historical period
```

### User Segments

- **Power Users (5%)**: Very active, high engagement, premium subscribers
- **Regular (25%)**: Daily active users, moderate engagement
- **Casual (40%)**: Weekly active users, basic engagement
- **Dormant (20%)**: Rarely active, high churn risk
- **New (10%)**: Recently joined, learning platform

### Content Types

- Music (25%)
- Video (20%)
- Podcast (15%)
- Gaming (15%)
- News (10%)
- Education (8%)
- Sports (7%)

### Recommendation Algorithms

1. **Collaborative Filtering (30%)**: User-based recommendations
2. **Content-Based (25%)**: Similar content suggestions
3. **Hybrid (20%)**: Combined approach
4. **Popularity (15%)**: Trending content
5. **Random (10%)**: Control group

## Usage

```bash
cd generators/streaming_ml
python generate.py
```

## Output Files

All files are generated in the `output/` directory:

### Core Data Files

- `users.csv` - User profiles with segments
- `creators.csv` - Content creator profiles
- `content_items.csv` - Content metadata
- `categories.csv` - Content categorization

### Behavioral Data

- `user_sessions.csv` - Session tracking
- `events.csv` - User interactions (limited to 50k)
- `recommendations.csv` - Recommendation impressions
- `ab_test_assignments.csv` - Experiment groups

### ML Features

- `ml_features.csv` - Pre-computed feature vectors
  - User engagement metrics
  - Content diversity scores
  - Temporal patterns
  - Churn indicators

### Revenue Data

- `revenue_events.csv` - Transactions and payments

### Metadata

- `generation_summary.json` - Statistics and configuration

## Data Patterns

### Engagement Patterns

- **Time of Day**: Peak usage 6-10 PM (30%)
- **Day of Week**: Higher weekend engagement
- **Seasonal**: Included in trending scores

### User Behavior by Segment

| Segment | Daily Active | Session Duration | Content/Session |
|---------|--------------|------------------|-----------------|
| Power User | 95% | 30-180 min | 10-50 items |
| Regular | 70% | 15-60 min | 5-20 items |
| Casual | 30% | 5-30 min | 2-10 items |
| Dormant | 10% | 2-10 min | 1-3 items |

### ML Features Generated

1. **User Features**
   - Age on platform (days)
   - Total sessions
   - Average session duration
   - Content diversity score
   - Peak usage hour
   - Weekend vs weekday ratio

2. **Engagement Metrics**
   - Like rate
   - Share rate
   - Completion rate
   - Interaction frequency

3. **Predictive Scores**
   - Churn probability
   - Predicted lifetime value
   - Segment classification

## A/B Testing

Three concurrent experiments:

1. **New Recommendation Algorithm**
   - Control vs 2 variants
   - Metrics: CTR, session duration, retention

2. **UI Redesign**
   - Old vs New interface
   - Metrics: Bounce rate, conversion, engagement

3. **Pricing Test**
   - Current vs Lower vs Higher
   - Metrics: Conversion rate, revenue, churn

## Performance Notes

- Limited to 50,000 events for file size
- User features computed for first 1,000 users
- Sessions generated for 1,000 daily active users
- Approximately 5-10 minutes generation time

## Use Cases

1. **Recommendation System Development**
   - Algorithm comparison
   - Cold start problem
   - Real-time personalization

2. **Churn Prediction**
   - Feature engineering
   - Model training
   - Risk scoring

3. **A/B Testing Analysis**
   - Statistical significance
   - Metric computation
   - Experiment design

4. **Revenue Analytics**
   - LTV calculation
   - Subscription analysis
   - Payment optimization

5. **User Segmentation**
   - Behavioral clustering
   - Engagement analysis
   - Personalization strategies