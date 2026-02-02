# E-commerce Platform Database

## Overview

This example demonstrates a comprehensive e-commerce platform with full marketplace capabilities, including product catalog management, inventory tracking, order processing, payment handling, customer analytics, and multi-vendor support.

## Business Context

Modern e-commerce platforms face complex challenges:
- **Inventory Management**: Real-time stock tracking across multiple warehouses
- **Order Fulfillment**: Complex workflow from cart to delivery
- **Payment Processing**: Multiple payment methods and fraud prevention
- **Customer Experience**: Personalization, recommendations, reviews
- **Marketing**: Promotions, discounts, loyalty programs
- **Analytics**: Customer behavior, conversion optimization
- **Scalability**: Handle traffic spikes during sales events

This platform addresses these challenges through:
- Comprehensive product catalog with variants and attributes
- Multi-warehouse inventory management
- Advanced order and fulfillment workflow
- Flexible payment and shipping options
- Customer analytics and personalization
- Robust promotion and pricing engine

## Key Differentiators from IoT Examples

While the IoT examples focused on sensor data and time series, this e-commerce platform emphasizes:

### Business Logic Complexity
- **Transaction Processing**: ACID compliance for orders and payments
- **Inventory Synchronization**: Real-time stock management
- **Pricing Calculations**: Dynamic pricing, taxes, discounts
- **State Machines**: Order status, payment status, fulfillment workflow

### Data Relationships
- **Product Variants**: Complex SKU management (size, color, etc.)
- **Category Hierarchy**: Recursive category structure
- **Customer Journey**: Browse → Cart → Checkout → Order → Delivery
- **Cross-selling**: Related products, bundles, recommendations

### Financial Aspects
- **Payment Processing**: Multiple gateways, tokenization, refunds
- **Tax Calculations**: Regional tax rules
- **Currency Handling**: Multi-currency support
- **Revenue Tracking**: Profit margins, COGS, lifetime value

### User Experience
- **Personalization**: Recommendations based on behavior
- **Search & Discovery**: Full-text search, faceted filtering
- **Reviews & Ratings**: Social proof and UGC
- **Wishlist & Cart**: Persistent shopping experience

## Learning Objectives

### Core E-commerce Concepts
- **Catalog Management**: Products, variants, categories, attributes
- **Inventory Control**: Stock levels, reservations, movements
- **Order Lifecycle**: From cart to delivery
- **Payment Flows**: Authorization, capture, refunds

### Advanced Database Patterns
- **Hierarchical Data**: Category trees, variant attributes
- **State Machines**: Order and payment status tracking
- **Audit Trails**: Order history, inventory movements
- **Soft Deletes**: Customer data retention

### Performance Optimization
- **Denormalization**: Cached calculations, materialized paths
- **Full-text Search**: Product search optimization
- **Query Optimization**: Complex JOIN operations
- **Caching Strategies**: Session data, recommendations

### Business Intelligence
- **Customer Analytics**: LTV, cohort analysis, segmentation
- **Product Performance**: Best sellers, conversion rates
- **Revenue Metrics**: GMV, AOV, profit margins
- **Marketing Attribution**: Campaign effectiveness

## Database Schema Highlights

### Architectural Decisions

1. **Product Variant System**
   ```sql
   -- Products have base attributes
   products (product_id, sku, name, base_price)
   -- Variants add specific combinations
   product_variants (variant_id, product_id, attributes JSON, price)
   -- Example: T-shirt (product) → Red/Large (variant)
   ```

2. **Flexible Attribute Storage**
   - JSON fields for specifications and features
   - Allows unlimited product attributes without schema changes
   - Enables faceted search and filtering

3. **Multi-Warehouse Inventory**
   - Track stock across locations
   - Reserve inventory for pending orders
   - Support transfers between warehouses

4. **Order State Management**
   - Separate order and payment status
   - Track fulfillment per line item
   - Complete audit trail of changes

## Key Features

### 1. Product Catalog
- **Hierarchical Categories**: Unlimited depth category tree
- **Product Variants**: Size, color, material combinations
- **Rich Media**: Multiple images per product/variant
- **SEO Optimization**: Slugs, meta tags, structured data

### 2. Inventory Management
- **Multi-Warehouse**: Stock tracking across locations
- **Reservations**: Hold stock for pending orders
- **Reorder Points**: Automatic restock alerts
- **Movement Tracking**: Complete audit trail

### 3. Shopping Experience
- **Persistent Cart**: Saved across sessions
- **Wishlist**: Save for later with price tracking
- **Recently Viewed**: Browsing history
- **Guest Checkout**: No account required

### 4. Order Processing
- **Complex Workflow**: Pending → Processing → Shipped → Delivered
- **Partial Fulfillment**: Ship from multiple warehouses
- **Order Modifications**: Cancel, modify before shipping
- **Split Payments**: Multiple payment methods per order

### 5. Payment Handling
- **Multiple Gateways**: Stripe, PayPal, Square integration
- **Saved Cards**: Tokenized storage for repeat customers
- **Refunds**: Full and partial refund support
- **Fraud Detection**: Risk scoring and verification

### 6. Shipping & Fulfillment
- **Multiple Carriers**: FedEx, UPS, USPS, DHL
- **Rate Calculation**: Weight and destination based
- **Label Generation**: Integrated shipping labels
- **Tracking**: Real-time shipment tracking

### 7. Customer Features
- **Reviews & Ratings**: Verified purchase badges
- **Q&A**: Product questions and answers
- **Recommendations**: Personalized product suggestions
- **Loyalty Program**: Points and rewards

### 8. Marketing Tools
- **Coupons**: Percentage, fixed, BOGO discounts
- **Price Rules**: Bulk discounts, flash sales
- **Email Campaigns**: Abandoned cart, recommendations
- **Affiliate Tracking**: Referral programs

### 9. Analytics & Reporting
- **Sales Analytics**: Revenue, orders, AOV trends
- **Customer Analytics**: LTV, retention, cohorts
- **Product Performance**: Best sellers, conversion rates
- **Marketing ROI**: Campaign attribution

### 10. Customer Service
- **Support Tickets**: Integrated helpdesk
- **Returns/RMA**: Return merchandise authorization
- **Live Chat**: Real-time customer support
- **FAQ Management**: Self-service resources

## Setup Instructions

### Prerequisites
- MySQL 8.0+ (for JSON support and CTEs)
- Python 3.8+ (for data generator)
- Redis (optional, for caching)
- Elasticsearch (optional, for search)

### Quick Start

1. **Create Database**
```bash
mysql -u root -p < schema/00_create_database.sql
```

2. **Install Schema**
```bash
mysql -u root -p ecommerce < schema/01_tables.sql
mysql -u root -p ecommerce < schema/02_constraints.sql
mysql -u root -p ecommerce < schema/03_indexes.sql
mysql -u root -p ecommerce < schema/04_views.sql
```

3. **Load Sample Data**
```bash
mysql -u root -p ecommerce < data/01_reference_data.sql
mysql -u root -p ecommerce < data/02_sample_products.sql
mysql -u root -p ecommerce < data/03_test_customers.sql
```

4. **Generate Test Orders**
```bash
cd generators/ecommerce
python generate_orders.py --count 10000
```

## Common Queries

### 1. Best Selling Products
```sql
SELECT
    p.product_name,
    p.sku,
    SUM(oi.quantity) as units_sold,
    SUM(oi.total_price) as revenue,
    COUNT(DISTINCT o.customer_id) as unique_buyers
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status NOT IN ('cancelled', 'refunded')
    AND o.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY p.product_id
ORDER BY units_sold DESC
LIMIT 10;
```

### 2. Cart Abandonment Analysis
```sql
WITH cart_stats AS (
    SELECT
        DATE(ci.added_at) as date,
        COUNT(DISTINCT ci.customer_id) as carts_created,
        SUM(ci.quantity * p.base_price) as cart_value
    FROM cart_items ci
    JOIN products p ON ci.product_id = p.product_id
    WHERE ci.added_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
        AND ci.saved_for_later = FALSE
    GROUP BY DATE(ci.added_at)
),
order_stats AS (
    SELECT
        DATE(created_at) as date,
        COUNT(*) as orders_placed,
        SUM(total_amount) as order_value
    FROM orders
    WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
    GROUP BY DATE(created_at)
)
SELECT
    cs.date,
    cs.carts_created,
    COALESCE(os.orders_placed, 0) as orders_placed,
    ROUND((cs.carts_created - COALESCE(os.orders_placed, 0)) * 100.0 / cs.carts_created, 2) as abandonment_rate,
    cs.cart_value,
    COALESCE(os.order_value, 0) as order_value
FROM cart_stats cs
LEFT JOIN order_stats os ON cs.date = os.date
ORDER BY cs.date DESC;
```

### 3. Customer Lifetime Value
```sql
SELECT
    c.customer_id,
    c.email,
    c.customer_type,
    COUNT(DISTINCT o.order_id) as order_count,
    SUM(o.total_amount) as total_spent,
    AVG(o.total_amount) as avg_order_value,
    DATEDIFF(MAX(o.created_at), MIN(o.created_at)) as customer_lifetime_days,
    MAX(o.created_at) as last_order_date,
    CASE
        WHEN MAX(o.created_at) > DATE_SUB(NOW(), INTERVAL 30 DAY) THEN 'Active'
        WHEN MAX(o.created_at) > DATE_SUB(NOW(), INTERVAL 90 DAY) THEN 'At Risk'
        ELSE 'Churned'
    END as customer_status
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status NOT IN ('cancelled', 'refunded')
GROUP BY c.customer_id
HAVING order_count > 0
ORDER BY total_spent DESC;
```

### 4. Inventory Alerts
```sql
SELECT
    p.sku,
    p.product_name,
    w.warehouse_name,
    i.quantity_available,
    i.quantity_reserved,
    i.reorder_point,
    i.average_daily_sales,
    CASE
        WHEN i.quantity_available <= 0 THEN 'OUT_OF_STOCK'
        WHEN i.quantity_available <= i.reorder_point THEN 'LOW_STOCK'
        WHEN i.days_of_stock <= 7 THEN 'REORDER_SOON'
        ELSE 'OK'
    END as stock_status
FROM inventory i
JOIN products p ON i.product_id = p.product_id
JOIN warehouses w ON i.warehouse_id = w.warehouse_id
WHERE i.quantity_available <= i.reorder_point
    OR i.days_of_stock <= 7
ORDER BY stock_status, i.quantity_available;
```

### 5. Conversion Funnel
```sql
WITH funnel AS (
    SELECT
        'Page Views' as stage,
        1 as stage_order,
        COUNT(DISTINCT session_id) as sessions
    FROM page_views
    WHERE created_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)

    UNION ALL

    SELECT
        'Product Views',
        2,
        COUNT(DISTINCT session_id)
    FROM page_views
    WHERE page_type = 'product'
        AND created_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)

    UNION ALL

    SELECT
        'Add to Cart',
        3,
        COUNT(DISTINCT customer_id)
    FROM cart_items
    WHERE added_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)

    UNION ALL

    SELECT
        'Checkout Started',
        4,
        COUNT(DISTINCT customer_id)
    FROM orders
    WHERE status IN ('pending', 'processing')
        AND created_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)

    UNION ALL

    SELECT
        'Order Completed',
        5,
        COUNT(*)
    FROM orders
    WHERE status IN ('confirmed', 'shipped', 'delivered')
        AND created_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
)
SELECT
    stage,
    sessions,
    LAG(sessions) OVER (ORDER BY stage_order) as previous_stage,
    ROUND(sessions * 100.0 / FIRST_VALUE(sessions) OVER (ORDER BY stage_order), 2) as pct_of_total,
    ROUND(sessions * 100.0 / LAG(sessions) OVER (ORDER BY stage_order), 2) as conversion_rate
FROM funnel
ORDER BY stage_order;
```

## Performance Optimization

### Indexing Strategy
1. **Primary Keys**: All tables have surrogate keys
2. **Foreign Keys**: Indexed for JOIN performance
3. **Search Indexes**: Full-text on product names and descriptions
4. **Composite Indexes**: For common query patterns
5. **Covering Indexes**: For high-frequency queries

### Caching Layers
1. **Session Cache**: Redis for cart and session data
2. **Product Cache**: Frequently accessed products
3. **Query Cache**: Expensive aggregation results
4. **CDN**: Product images and static assets

### Query Optimization
1. **Denormalization**: Product counts, average ratings
2. **Materialized Views**: Sales reports, inventory levels
3. **Partitioning**: Orders by date for archival
4. **Read Replicas**: Separate analytics queries

## Integration Points

### Payment Gateways
- Stripe API for card processing
- PayPal Express Checkout
- Apple Pay / Google Pay
- Cryptocurrency payments

### Shipping Providers
- FedEx Web Services
- UPS API
- USPS Web Tools
- EasyPost (multi-carrier)

### Marketing Tools
- Mailchimp for email campaigns
- Google Analytics for tracking
- Facebook Pixel for retargeting
- Klaviyo for automation

### Search & Discovery
- Elasticsearch for product search
- Algolia for instant search
- AI recommendations engine
- Visual search capabilities

## Testing Strategy

### Unit Tests
- Model validation
- Business logic
- Price calculations
- Inventory management

### Integration Tests
- Payment processing
- Order workflow
- Email notifications
- API endpoints

### Performance Tests
- Load testing (JMeter)
- Query performance
- Cache effectiveness
- Concurrent users

### Security Tests
- SQL injection prevention
- XSS protection
- PCI compliance
- GDPR compliance

## Monitoring & Analytics

### Key Metrics
- **Business KPIs**: GMV, AOV, conversion rate, CAC
- **Technical Metrics**: Response time, error rate, uptime
- **User Metrics**: DAU, MAU, retention, churn
- **Inventory Metrics**: Turnover, stockouts, carrying cost

### Dashboards
- Executive dashboard (revenue, orders, customers)
- Operations dashboard (inventory, fulfillment)
- Marketing dashboard (campaigns, attribution)
- Technical dashboard (performance, errors)

## Future Enhancements

1. **AI/ML Features**
   - Personalized recommendations
   - Dynamic pricing
   - Fraud detection
   - Demand forecasting

2. **Advanced Features**
   - Subscription commerce
   - B2B wholesale portal
   - Multi-vendor marketplace
   - Auction functionality

3. **International Expansion**
   - Multi-language support
   - Regional pricing
   - Cross-border shipping
   - Local payment methods

4. **Mobile Commerce**
   - Progressive Web App
   - Native mobile apps
   - Mobile-specific features
   - Push notifications

## License

This educational example is provided as-is for learning purposes.