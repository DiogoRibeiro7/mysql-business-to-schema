# Example 11: Social Media Platform

## Business Context

A modern social media platform that handles:
- Millions of users with complex social graphs
- Real-time feed generation and content distribution
- User-generated content with moderation
- Viral content detection and trending topics
- Engagement analytics and recommendation algorithms
- Direct messaging and group communications
- Privacy controls and content visibility rules
- Influencer identification and network effects

## Learning Objectives

1. **Graph Relationships in Relational Databases**
   - Implementing friend/follower relationships
   - Recursive queries for network traversal
   - Mutual connections and friend-of-friend queries
   - Graph metrics (degree, centrality, clustering)

2. **Feed Generation Algorithms**
   - Timeline construction strategies
   - Content ranking and relevance scoring
   - Real-time vs pre-computed feeds
   - Push vs pull architectures
   - Cache invalidation strategies

3. **Content Management**
   - User-generated content handling
   - Media attachments and CDN references
   - Content versioning and edit history
   - Soft deletes and content recovery
   - Hashtag extraction and indexing

4. **Engagement Mechanics**
   - Like, comment, share implementations
   - Nested comment threads
   - Reaction types and emoji responses
   - View counting and impression tracking
   - Engagement rate calculations

5. **Viral Content Detection**
   - Velocity of engagement metrics
   - Share cascade tracking
   - Trend identification algorithms
   - Influencer impact measurement
   - Content reach calculations

6. **Privacy and Security**
   - Visibility rules (public, friends, private)
   - Block lists and mute lists
   - Content reporting and moderation queues
   - GDPR compliance (right to forget)
   - Rate limiting and spam detection

## Schema Overview

### Core Entities

1. **Users & Profiles**
   - users (authentication and core data)
   - user_profiles (extended profile information)
   - user_settings (privacy and notification preferences)
   - user_sessions (active sessions and devices)

2. **Social Graph**
   - relationships (followers, friends, blocks)
   - relationship_requests (pending connections)
   - user_lists (custom user groupings)
   - suggested_connections (recommendation cache)

3. **Content**
   - posts (text, images, videos, links)
   - post_media (attached media files)
   - comments (nested comment threads)
   - shares (reshares/retweets)
   - reactions (likes, loves, wows, etc.)

4. **Hashtags & Topics**
   - hashtags (tag dictionary)
   - post_hashtags (many-to-many relationship)
   - trending_topics (computed trends)
   - user_interests (topic preferences)

5. **Messaging**
   - conversations (direct and group chats)
   - conversation_participants
   - messages
   - message_reads (read receipts)

6. **Notifications**
   - notifications (all notification types)
   - notification_preferences
   - push_tokens (mobile push endpoints)

7. **Moderation**
   - reports (user reports of content/users)
   - moderation_queue
   - moderation_actions
   - banned_content (prohibited keywords/media)

8. **Analytics**
   - user_activity_logs
   - engagement_metrics (hourly/daily aggregates)
   - viral_content_tracking
   - user_influence_scores

## Key Features

### Social Graph Queries
- Find mutual friends
- Calculate degrees of separation
- Identify influencers (high follower count + engagement)
- Detect communities/clusters
- Friend recommendations based on mutual connections

### Feed Generation
- Chronological timeline
- Algorithmic feed (engagement-based ranking)
- Following-only feed
- Trending content feed
- Personalized recommendations

### Content Discovery
- Hashtag search
- Full-text search with relevance ranking
- Trending topics by region
- Viral content identification
- Similar content recommendations

### Privacy Controls
- Post visibility settings
- Story/ephemeral content
- Close friends lists
- Content restrictions by age/region
- Account privacy (public/private)

## Data Characteristics

- **Volume**: 1M+ users, 10M+ posts, 100M+ engagements
- **Velocity**: 1000+ posts/second, 10000+ engagements/second
- **Variety**: Text, images, videos, links, polls
- **Veracity**: Content moderation, fact-checking flags

## Technical Patterns Demonstrated

1. **Adjacency List Pattern**: For social graph relationships
2. **Closure Table**: For comment thread hierarchies
3. **Denormalization**: Cached follower counts, engagement metrics
4. **Sharding Strategy**: User-based sharding for horizontal scaling
5. **Event Sourcing**: Activity logs for feed generation
6. **Write-Through Cache**: Pre-computed feeds for active users
7. **Bloom Filters**: For efficient "seen" content tracking
8. **HyperLogLog**: For unique viewer counting

## Sample Use Cases

1. **User Registration**: Profile creation → Interest selection → Friend suggestions
2. **Content Creation**: Post → Media upload → Hashtag extraction → Feed distribution
3. **Viral Spread**: Initial post → Early engagement → Velocity detection → Trend promotion
4. **Feed Refresh**: Check last seen → Fetch new content → Apply ranking → Return personalized feed
5. **Influencer Campaign**: Identify influencers → Track sponsored content → Measure reach

## Performance Considerations

### Indexing Strategy
- Composite indexes for feed queries
- Full-text indexes for search
- Partial indexes for active content
- Covering indexes for hot queries

### Caching Layers
- User session cache
- Feed cache (Redis)
- Trending topics cache
- Friend list cache

### Optimization Techniques
- Query result pagination
- Lazy loading of comments
- Asynchronous engagement counting
- Batch notification processing

## Getting Started

```bash
# 1. Create database
mysql -u root < schema/00_create_database.sql

# 2. Create tables and constraints
mysql -u root social_media < schema/01_tables.sql
mysql -u root social_media < schema/02_constraints.sql
mysql -u root social_media < schema/03_indexes.sql
mysql -u root social_media < schema/04_views.sql
mysql -u root social_media < schema/05_procedures.sql

# 3. Generate sample data
cd ../generators/social_media
python generate.py

# 4. Load generated data
cd ../../example_11_social_media
mysql -u root social_media < schema/10_load_generated.sql

# 5. Run sample queries
mysql -u root social_media < queries/01_social_graph.sql
mysql -u root social_media < queries/02_feed_generation.sql
mysql -u root social_media < queries/03_trending_content.sql
mysql -u root social_media < queries/04_engagement_analytics.sql
mysql -u root social_media < queries/05_moderation.sql
```

## Assignment Ideas

1. Implement a "People You May Know" recommendation algorithm
2. Create a query to detect fake engagement (bot patterns)
3. Design a stored procedure for feed generation with personalization
4. Write queries to identify trending topics in the last hour
5. Build a content moderation workflow with escalation

## Real-World Considerations

- **Scale**: Billions of users and trillions of engagements
- **Latency**: < 100ms for feed generation
- **Consistency**: Eventual consistency for counts and metrics
- **Privacy**: GDPR, CCPA compliance requirements
- **Moderation**: AI + human review pipeline
- **Monetization**: Ad placement and sponsored content algorithms