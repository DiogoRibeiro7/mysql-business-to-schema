-- ============================================================================
-- INDEXES FOR FOOD DELIVERY PLATFORM
-- ============================================================================

USE food_delivery;

-- ============================================================================
-- PERFORMANCE INDEXES
-- ============================================================================

-- Customers table - optimize for login and order lookups
CREATE INDEX idx_customers_email_status ON customers(email, status);
CREATE INDEX idx_customers_phone_status ON customers(phone_number, status);
CREATE INDEX idx_customers_last_order ON customers(last_order_at DESC);
CREATE INDEX idx_customers_loyalty ON customers(loyalty_tier, total_spent DESC);

-- Customer addresses - optimize for location-based queries
CREATE INDEX idx_addresses_customer_active ON customer_addresses(customer_id, is_active);
CREATE INDEX idx_addresses_customer_default ON customer_addresses(customer_id, is_default);

-- Restaurants table - optimize for search and discovery
CREATE INDEX idx_restaurants_status_rating ON restaurants(status, average_rating DESC);
CREATE INDEX idx_restaurants_featured ON restaurants(is_featured, average_rating DESC);

-- Restaurant hours - optimize for "open now" queries
CREATE INDEX idx_hours_restaurant_day ON restaurant_hours(restaurant_id, day_of_week);
CREATE INDEX idx_hours_special ON restaurant_hours(restaurant_id, special_hours_date);

-- Menu categories - optimize for menu display
CREATE INDEX idx_categories_restaurant_active ON menu_categories(restaurant_id, is_active, display_order);

-- Menu items - optimize for menu display and search
CREATE INDEX idx_items_restaurant_available ON menu_items(restaurant_id, is_available, category_id);
CREATE INDEX idx_items_popular ON menu_items(restaurant_id, is_popular, times_ordered DESC);
CREATE INDEX idx_items_dietary ON menu_items(restaurant_id, is_vegetarian, is_vegan, is_gluten_free);

-- Drivers table - optimize for dispatch and availability
CREATE INDEX idx_drivers_available_location ON drivers(is_available, status, current_latitude, current_longitude);
CREATE INDEX idx_drivers_status_rating ON drivers(status, average_rating DESC);
CREATE INDEX idx_drivers_vehicle ON drivers(vehicle_type, status);

-- Driver shifts - optimize for scheduling
CREATE INDEX idx_shifts_driver_active ON driver_shifts(driver_id, status, scheduled_start);
CREATE INDEX idx_shifts_schedule ON driver_shifts(scheduled_start, scheduled_end, status);

-- Orders table - optimize for order management
CREATE INDEX idx_orders_customer_recent ON orders(customer_id, placed_at DESC);
CREATE INDEX idx_orders_restaurant_status ON orders(restaurant_id, status, placed_at DESC);
CREATE INDEX idx_orders_driver_active ON orders(driver_id, status);
CREATE INDEX idx_orders_payment_pending ON orders(payment_status, created_at);
CREATE INDEX idx_orders_scheduled ON orders(is_scheduled, scheduled_for, status);

-- Order items - optimize for order details
CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_item ON order_items(item_id);

-- Delivery tracking - optimize for real-time tracking
CREATE INDEX idx_tracking_order_recent ON delivery_tracking(order_id, recorded_at DESC);
CREATE INDEX idx_tracking_driver_recent ON delivery_tracking(driver_id, recorded_at DESC);

-- Delivery zones - optimize for zone matching
CREATE INDEX idx_zones_active ON delivery_zones(is_active);
CREATE INDEX idx_zones_surge ON delivery_zones(surge_active, surge_multiplier);

-- Restaurant reviews - optimize for display and analytics
CREATE INDEX idx_reviews_restaurant_rating ON restaurant_reviews(restaurant_id, overall_rating DESC, created_at DESC);
CREATE INDEX idx_reviews_featured ON restaurant_reviews(restaurant_id, is_featured, overall_rating DESC);
CREATE INDEX idx_reviews_customer ON restaurant_reviews(customer_id, created_at DESC);

-- Driver ratings - optimize for driver metrics
CREATE INDEX idx_driver_ratings_driver ON driver_ratings(driver_id, rating DESC);

-- Promotions - optimize for validation
CREATE INDEX idx_promotions_active_code ON promotions(code, is_active, valid_from, valid_until);
CREATE INDEX idx_promotions_segment ON promotions(customer_segment, is_active);

-- Promotion usage - optimize for tracking
CREATE INDEX idx_promotion_usage_customer ON promotion_usage(customer_id, used_at DESC);

-- Notifications - optimize for delivery queue
CREATE INDEX idx_notifications_pending ON notifications(status, priority, created_at);
CREATE INDEX idx_notifications_recipient ON notifications(recipient_type, recipient_id, created_at DESC);

-- Payment methods - optimize for checkout
CREATE INDEX idx_payment_methods_customer ON payment_methods(customer_id, is_default DESC);

-- ============================================================================
-- COMPOSITE INDEXES FOR COMPLEX QUERIES
-- ============================================================================

-- Find nearby restaurants
CREATE INDEX idx_restaurants_nearby ON restaurants(status, delivery_enabled, latitude, longitude);

-- Find available drivers in zone
CREATE INDEX idx_drivers_dispatch ON drivers(status, is_available, vehicle_type, average_rating DESC);

-- Order history with filters
CREATE INDEX idx_orders_history ON orders(customer_id, status, placed_at DESC, total_amount);

-- Restaurant search by cuisine and rating
CREATE INDEX idx_restaurants_search ON restaurants(status, price_range, average_rating DESC);

-- Active orders for dashboard
CREATE INDEX idx_orders_active ON orders(status, placed_at, estimated_delivery_time);

-- Menu item search with dietary filters
CREATE INDEX idx_items_search ON menu_items(restaurant_id, is_available, is_vegetarian, is_vegan, base_price);

-- Driver earnings calculation
CREATE INDEX idx_orders_driver_earnings ON orders(driver_id, status, delivered_at, delivery_fee, tip_amount);

-- Customer segmentation for promotions
CREATE INDEX idx_customers_segmentation ON customers(status, loyalty_tier, total_spent, last_order_at);

-- ============================================================================
-- FULL-TEXT INDEXES
-- ============================================================================

-- Restaurant name and cuisine search
ALTER TABLE restaurants ADD FULLTEXT ft_restaurants_search (name);

-- Menu item search
ALTER TABLE menu_items ADD FULLTEXT ft_items_search (name, description);

-- Review text search
ALTER TABLE restaurant_reviews ADD FULLTEXT ft_reviews_search (review_text);

-- ============================================================================
-- ============================================================================

-- Restaurant location search
ALTER TABLE restaurants
    ADD COLUMN location POINT GENERATED ALWAYS AS (POINT(longitude, latitude)) STORED;

-- Customer address locations
ALTER TABLE customer_addresses
    ADD COLUMN location POINT GENERATED ALWAYS AS (POINT(longitude, latitude)) STORED;

-- Driver current location
ALTER TABLE drivers
    ADD COLUMN current_location POINT GENERATED ALWAYS AS
        (IF(current_longitude IS NOT NULL AND current_latitude IS NOT NULL,
            POINT(current_longitude, current_latitude), NULL)) STORED;

-- Order delivery location
ALTER TABLE orders
    ADD COLUMN delivery_location POINT GENERATED ALWAYS AS
        (IF(delivery_longitude IS NOT NULL AND delivery_latitude IS NOT NULL,
            POINT(delivery_longitude, delivery_latitude), NULL)) STORED;

-- ============================================================================
-- STATISTICS UPDATE
-- ============================================================================

-- Update table statistics for query optimizer
ANALYZE TABLE customers;
ANALYZE TABLE restaurants;
ANALYZE TABLE menu_items;
ANALYZE TABLE drivers;
ANALYZE TABLE orders;
ANALYZE TABLE order_items;
ANALYZE TABLE delivery_tracking;
ANALYZE TABLE delivery_zones;
ANALYZE TABLE restaurant_reviews;
ANALYZE TABLE promotions;

-- ============================================================================
-- INDEX HINTS FOR COMMON QUERIES
-- ============================================================================

/*
Common Query Patterns and Their Indexes:

1. Find restaurants near customer:
   Uses: idx_restaurants_location (spatial), idx_restaurants_nearby

2. Check restaurant availability:
   Uses: idx_hours_restaurant_day, idx_restaurants_status_rating

3. Browse menu items:
   Uses: idx_items_restaurant_available, idx_categories_restaurant_active

4. Find available drivers:
   Uses: idx_drivers_current_location (spatial), idx_drivers_available_location

5. Track active order:
   Uses: idx_tracking_order_recent, idx_orders_customer_recent

6. Calculate driver earnings:
   Uses: idx_orders_driver_earnings, idx_shifts_driver_active

7. Apply promotion:
   Uses: idx_promotions_active_code, idx_promotion_usage_customer

8. Search restaurants by cuisine:
   Uses: ft_restaurants_search, idx_restaurants_search

9. Get customer order history:
   Uses: idx_orders_customer_recent, idx_orders_history

10. Monitor zone demand:
    Uses: idx_zones_active, idx_zones_surge

11. Display restaurant reviews:
    Uses: idx_reviews_restaurant_rating, idx_reviews_featured

12. Send notifications:
    Uses: idx_notifications_pending, idx_notifications_recipient
*/
