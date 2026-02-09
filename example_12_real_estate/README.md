# Example 12: Real Estate Platform

## Business Context

A comprehensive real estate platform that handles:
- Property listings for sale and rent
- Multiple listing service (MLS) integration
- Agent and brokerage management
- Buyer/seller matchmaking
- Virtual tours and property showcases
- Offer management and negotiations
- Transaction coordination
- Market analytics and pricing insights
- Mortgage pre-qualification
- Neighborhood information and amenities

## Learning Objectives

1. **Spatial Data Management**
   - Geographic coordinates and boundaries
   - Proximity searches (nearby properties)
   - Polygon storage for property boundaries
   - Spatial indexing for performance
   - Distance calculations

2. **Hierarchical Data Structures**
   - Property type hierarchies (residential → single family → detached)
   - Location hierarchies (country → state → city → neighborhood)
   - Organization structure (franchise → brokerage → team → agent)
   - Feature categorization

3. **Temporal Data Tracking**
   - Price history and trends
   - Listing status changes
   - Market time calculations
   - Seasonal patterns
   - Historical comparables

4. **Media and Document Management**
   - Photo galleries with ordering
   - Virtual tour integration
   - Document storage (contracts, disclosures)
   - Floor plans and blueprints
   - Drone footage and videos

5. **Complex Business Rules**
   - Commission calculations
   - Dual agency restrictions
   - Offer contingencies
   - Escrow timelines
   - Compliance requirements

6. **Search and Filtering**
   - Multi-criteria property search
   - Saved searches with alerts
   - Similar property recommendations
   - Price range overlaps
   - School district boundaries

## Schema Overview

### Core Entities

1. **Properties**
   - properties (main listing information)
   - property_details (extended attributes)
   - property_features (amenities, appliances)
   - property_rooms (room-level details)
   - property_taxes (tax history)

2. **Listings**
   - listings (active/sold/pending)
   - listing_status_history
   - price_changes
   - open_houses
   - listing_agreements

3. **Agents & Brokerages**
   - brokerages
   - agents
   - agent_licenses
   - agent_specializations
   - teams

4. **Users & Clients**
   - users (buyers, sellers, investors)
   - user_preferences (search criteria)
   - saved_searches
   - saved_properties (favorites)
   - user_alerts

5. **Property Media**
   - property_photos
   - virtual_tours
   - property_videos
   - floor_plans
   - property_documents

6. **Transactions**
   - offers
   - offer_contingencies
   - counter_offers
   - purchase_agreements
   - escrows

7. **Locations**
   - neighborhoods
   - school_districts
   - schools
   - amenities (parks, shopping, transit)
   - crime_statistics
   - demographic_data

8. **Market Data**
   - market_trends
   - comparable_sales
   - price_indices
   - absorption_rates
   - inventory_levels

9. **Appointments**
   - showing_requests
   - showing_schedules
   - showing_feedback
   - agent_availability

10. **Communications**
    - inquiries
    - messages
    - notifications
    - email_campaigns

## Key Features

### Property Search
- Advanced filters (price, size, bedrooms, features)
- Map-based search with boundaries
- Commute time calculations
- School ratings integration
- Walk score and transit score
- Custom polygon search areas

### Listing Management
- Automated MLS syndication
- Coming soon listings
- Pocket listings (off-market)
- Expired listing reactivation
- Comparative market analysis (CMA)

### Agent Tools
- Lead management and routing
- Commission tracking
- Performance dashboards
- Client relationship management
- Automated valuation models (AVM)

### Buyer/Seller Features
- Mortgage calculators
- Affordability analysis
- Moving cost estimates
- Home value estimates
- Market timing recommendations

### Analytics
- Days on market analysis
- Price per square foot trends
- Inventory absorption rates
- Seasonal pattern detection
- Neighborhood appreciation rates

## Data Characteristics

- **Volume**: 100K+ active listings, 1M+ historical transactions
- **Velocity**: 1000+ new listings/day, 10K+ price changes/day
- **Geographic**: Spatial queries across multiple regions
- **Media**: 20+ photos per listing, 500GB+ total storage

## Technical Patterns Demonstrated

1. **Spatial Indexes**: For geographic searches
2. **Full-Text Search**: Property descriptions and features
3. **Hierarchical Queries**: Location and category trees
4. **Temporal Tables**: Price and status history
5. **JSON Storage**: Flexible property attributes
6. **Materialized Views**: Pre-computed market statistics
7. **Partitioning**: By region and listing date
8. **Audit Trails**: All changes tracked for compliance

## Sample Use Cases

1. **Property Search**: Filters → Map view → Details → Schedule showing
2. **Listing Creation**: Property details → Photos → Pricing → MLS submission
3. **Offer Process**: Submit → Counter → Accept → Escrow → Close
4. **Market Analysis**: Comparables → Trends → Pricing recommendation
5. **Agent Matching**: Buyer preferences → Agent expertise → Introduction

## Performance Considerations

### Query Optimization
- Covering indexes for search queries
- Spatial indexes for map searches
- Materialized paths for hierarchies
- Query result caching

### Data Architecture
- Hot/cold data separation
- CDN for media files
- Read replicas for analytics
- Async processing for notifications

## Getting Started

```bash
# 1. Create database
mysql -u root < schema/00_create_database.sql

# 2. Create tables and constraints
mysql -u root real_estate < schema/01_tables.sql
mysql -u root real_estate < schema/02_constraints.sql
mysql -u root real_estate < schema/03_indexes.sql
mysql -u root real_estate < schema/04_spatial.sql
mysql -u root real_estate < schema/05_views.sql

# 3. Load sample data
mysql -u root real_estate < data/01_reference_data.sql
mysql -u root real_estate < data/02_sample_properties.sql

# 4. Run sample queries
mysql -u root real_estate < queries/01_property_search.sql
mysql -u root real_estate < queries/02_market_analysis.sql
mysql -u root real_estate < queries/03_agent_performance.sql
mysql -u root real_estate < queries/04_geographic_queries.sql
```

## Assignment Ideas

1. Build a property recommendation engine based on user preferences
2. Create a comparative market analysis (CMA) report generator
3. Implement a commission calculator with split rules
4. Design an algorithm for optimal showing route planning
5. Develop queries for market trend prediction

## Real-World Considerations

- **MLS Compliance**: RESO data dictionary standards
- **Fair Housing**: Avoid discriminatory filtering
- **Privacy**: Agent and seller information protection
- **Licensing**: State-specific real estate regulations
- **Data Accuracy**: Regular MLS feed synchronization
- **Scale**: Millions of properties across multiple markets