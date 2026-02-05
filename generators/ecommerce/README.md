# E-commerce Platform Data Generator

## Overview

Generates comprehensive synthetic data for an e-commerce platform including users, products, orders, inventory management, reviews, and shopping cart analytics.

## Features

### Data Generated

1. **User Management**
   - Users (5,000 customers)
   - Customer segments (Regular, Premium, Occasional, New)
   - Geographic distribution
   - Loyalty program data

2. **Product Catalog**
   - Products (2,000 items)
   - Categories (50 hierarchical)
   - Brands (100 manufacturers)
   - Pricing tiers
   - Product attributes

3. **Order Processing**
   - Orders (10,000 transactions)
   - Order items and line details
   - Payment processing
   - Shipping tracking
   - Returns and refunds

4. **Inventory Management**
   - Warehouses (5 locations)
   - Stock levels
   - Suppliers (50 vendors)
   - Reorder points
   - Transfer records

5. **Customer Engagement**
   - Product reviews (15% of orders)
   - Shopping carts
   - Wishlist items
   - Cart abandonment (70% rate)

## Configuration

Edit `config.yaml` to adjust:

```yaml
counts:
  users: 5000                    # Customer accounts
  products: 2000                 # Product catalog size
  categories: 50                 # Product categories
  brands: 100                    # Brand/manufacturers
  warehouses: 5                  # Fulfillment centers
  suppliers: 50                  # Vendor accounts
  orders: 10000                  # Transaction volume
  reviews_percentage: 0.15       # Review rate
  cart_abandonment_rate: 0.70    # Abandonment percentage
  days_of_data: 90              # Historical period
```

### Customer Segments

| Segment | Distribution | Behavior | Order Frequency | AOV |
|---------|-------------|----------|----------------|-----|
| Regular | 60% | Steady purchases | 2-3/month | $50-150 |
| Premium | 20% | High value | 4-5/month | $150-500 |
| Occasional | 15% | Seasonal | 1/month | $30-100 |
| New | 5% | First-time | 1-2 total | $40-120 |

### Product Categories

| Category | Distribution | Price Range | Popular Brands |
|----------|-------------|-------------|----------------|
| Electronics | 25% | $30-3000 | Samsung, Apple, Sony |
| Clothing | 20% | $10-300 | Nike, Adidas, Zara |
| Home & Garden | 15% | $15-1000 | IKEA, Home Depot |
| Books | 10% | $5-50 | Penguin, HarperCollins |
| Sports | 10% | $10-500 | Wilson, Spalding |
| Beauty | 10% | $5-150 | L'Oreal, Dove |
| Toys | 5% | $10-200 | LEGO, Mattel |
| Food | 5% | $3-100 | Nestle, Kraft |

### Geographic Distribution

- Northeast: 25%
- Southeast: 20%
- Midwest: 20%
- Southwest: 15%
- West: 20%

## Usage

```bash
cd generators/ecommerce
python generate.py
```

## Output Files

All files are generated in the `output/` directory:

### Core Data

- `users.csv` - Customer profiles and segments
- `products.csv` - Product catalog with attributes
- `categories.csv` - Category hierarchy
- `brands.csv` - Brand information
- `warehouses.csv` - Fulfillment center locations
- `suppliers.csv` - Vendor details

### Transactional Data

- `orders.csv` - Order headers with status
- `order_items.csv` - Line item details
- `payments.csv` - Payment transactions
- `shipments.csv` - Shipping and tracking
- `returns.csv` - Return and refund records

### Inventory Data

- `inventory.csv` - Current stock levels
- `inventory_movements.csv` - Stock transfers
- `purchase_orders.csv` - Supplier orders
- `reorder_alerts.csv` - Low stock notifications

### Customer Interaction

- `reviews.csv` - Product ratings and comments
- `carts.csv` - Shopping cart sessions
- `cart_items.csv` - Cart contents
- `wishlists.csv` - Saved items
- `browsing_history.csv` - Product views

### Metadata

- `generation_summary.json` - Statistics and configuration

## Data Patterns

### Order Patterns

**Daily Distribution:**
- Weekday baseline: 100-120 orders
- Weekend peak: 150-180 orders
- Monday dip: -10%
- Friday/Saturday surge: +20-50%

**Seasonal Patterns:**
| Month | Multiplier | Event |
|-------|-----------|-------|
| January | 0.8x | Post-holiday |
| November | 1.8x | Black Friday |
| December | 2.0x | Holiday shopping |
| July | 1.0x | Summer baseline |

**Time of Day:**
- Night (12-6 AM): 5%
- Morning (6-9 AM): 10%
- Workday (9 AM-5 PM): 35%
- Evening (5-9 PM): 35%
- Late (9 PM-12 AM): 15%

### Shopping Cart Behavior

- **Average Cart Size**: 2.5 items
- **Cart Abandonment**: 70%
- **Time to Purchase**: 1-7 days
- **Cross-sell Success**: 15%
- **Mobile vs Desktop**: 60/40 split

### Review Patterns

- **Review Rate**: 15% of orders
- **Rating Distribution**:
  - 5 stars: 45%
  - 4 stars: 30%
  - 3 stars: 15%
  - 2 stars: 7%
  - 1 star: 3%
- **Review Timing**: 3-14 days post-delivery

### Inventory Patterns

**Stock Distribution:**
- Fast-moving: 20% of SKUs, 80% of sales
- Regular: 60% of SKUs, 15% of sales
- Slow-moving: 20% of SKUs, 5% of sales

**Reorder Strategy:**
- Trigger: 20% of max stock
- Lead time: 3-14 days
- Safety stock: 10% buffer

## Realistic Features

### Dynamic Pricing
- Time-based discounts
- Inventory-driven pricing
- Competitor price matching
- Bundle offers

### Shipping Options
- Standard (5-7 days): 60%
- Express (2-3 days): 30%
- Next-day: 10%
- In-store pickup: 5%

### Payment Methods
- Credit Card: 50%
- PayPal: 20%
- Debit Card: 15%
- Buy Now Pay Later: 10%
- Gift Cards: 5%

### Return Reasons
- Damaged: 25%
- Wrong item: 20%
- Doesn't fit: 30%
- Not as described: 15%
- Changed mind: 10%

## Performance Notes

- Generation time: 3-5 minutes
- Memory usage: ~300MB
- CSV output: ~150MB
- Scalable to 1M orders

## Use Cases

1. **Sales Analytics**
   - Revenue forecasting
   - Customer segmentation
   - Product performance
   - Conversion optimization

2. **Inventory Optimization**
   - Demand planning
   - Stock optimization
   - Supplier performance
   - Warehouse efficiency

3. **Customer Experience**
   - Recommendation engines
   - Personalization testing
   - A/B testing platforms
   - Journey mapping

4. **Marketing Analytics**
   - Campaign effectiveness
   - Customer acquisition cost
   - Lifetime value analysis
   - Churn prediction

## Sample Queries

After importing the data:

```sql
-- Top selling products by category
SELECT
    c.name as category,
    p.name as product,
    COUNT(oi.order_item_id) as units_sold,
    SUM(oi.quantity * oi.unit_price) as revenue
FROM products p
JOIN categories c ON p.category_id = c.category_id
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status = 'delivered'
GROUP BY c.category_id, p.product_id
ORDER BY revenue DESC
LIMIT 10;

-- Cart abandonment analysis
SELECT
    DATE(c.created_at) as date,
    COUNT(*) as total_carts,
    COUNT(CASE WHEN c.status = 'abandoned' THEN 1 END) as abandoned,
    COUNT(CASE WHEN c.status = 'purchased' THEN 1 END) as purchased,
    ROUND(COUNT(CASE WHEN c.status = 'abandoned' THEN 1 END) * 100.0 / COUNT(*), 2) as abandonment_rate
FROM carts c
GROUP BY DATE(c.created_at);

-- Customer lifetime value
SELECT
    u.segment,
    COUNT(DISTINCT u.user_id) as customers,
    AVG(customer_orders.order_count) as avg_orders,
    AVG(customer_orders.total_spent) as avg_ltv
FROM users u
JOIN (
    SELECT
        user_id,
        COUNT(*) as order_count,
        SUM(total_amount) as total_spent
    FROM orders
    WHERE status = 'delivered'
    GROUP BY user_id
) customer_orders ON u.user_id = customer_orders.user_id
GROUP BY u.segment;
```

## Advanced Features

### Recommendation Engine Data
- Collaborative filtering signals
- Product affinity scores
- Browse-to-buy patterns
- Cross-category preferences

### Fraud Detection Patterns
- Unusual order patterns
- High-risk transactions
- Account takeover signals
- Payment anomalies

### Supply Chain Analytics
- Vendor performance metrics
- Lead time optimization
- Stock-out predictions
- Demand forecasting

## Customization

Extend the generator for:

1. **Promotions**: Coupons, flash sales, bundles
2. **Subscriptions**: Recurring orders
3. **Marketplace**: Third-party sellers
4. **International**: Multi-currency, customs
5. **B2B Features**: Bulk orders, net terms

## Notes

- All data is synthetic and randomly generated
- PII is completely fictional
- Follows e-commerce best practices
- Compatible with major platforms
- GDPR/CCPA compliant structure