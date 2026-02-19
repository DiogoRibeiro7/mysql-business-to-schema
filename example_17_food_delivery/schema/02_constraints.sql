-- ============================================================================
-- CONSTRAINTS FOR FOOD DELIVERY PLATFORM
-- ============================================================================

USE food_delivery;

-- ============================================================================
-- ADDITIONAL FOREIGN KEY CONSTRAINTS
-- ============================================================================

-- Customers table - self-referential for referrals
ALTER TABLE customers
    ADD CONSTRAINT fk_customers_referred_by
    FOREIGN KEY (referred_by_customer_id) REFERENCES customers(customer_id);

-- ============================================================================
-- CHECK CONSTRAINTS
-- ============================================================================

-- Customers table
ALTER TABLE customers
    ADD CONSTRAINT chk_customers_tip_percentage
    CHECK (default_tip_percentage >= 0 AND default_tip_percentage <= 100),
    ADD CONSTRAINT chk_customers_loyalty_points
    CHECK (loyalty_points >= 0),
    ADD CONSTRAINT chk_customers_totals
    CHECK (total_orders >= 0 AND total_spent >= 0);

-- Customer addresses table
ALTER TABLE customer_addresses
    ADD CONSTRAINT chk_addresses_coordinates
    CHECK (latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180);

-- Restaurants table
ALTER TABLE restaurants
    ADD CONSTRAINT chk_restaurants_delivery_radius
    CHECK (delivery_radius_km > 0 AND delivery_radius_km <= 50),
    ADD CONSTRAINT chk_restaurants_minimum_order
    CHECK (minimum_order_amount >= 0),
    ADD CONSTRAINT chk_restaurants_prep_time
    CHECK (preparation_time_minutes > 0 AND preparation_time_minutes <= 180),
    ADD CONSTRAINT chk_restaurants_fees
    CHECK (delivery_fee >= 0 AND service_fee_percentage >= 0 AND service_fee_percentage <= 100),
    ADD CONSTRAINT chk_restaurants_rating
    CHECK (average_rating >= 0 AND average_rating <= 5),
    ADD CONSTRAINT chk_restaurants_counts
    CHECK (total_ratings >= 0 AND total_orders >= 0),
    ADD CONSTRAINT chk_restaurants_coordinates
    CHECK (latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180);

-- Restaurant hours table
ALTER TABLE restaurant_hours
    ADD CONSTRAINT chk_hours_valid_time
    CHECK (close_time != open_time);

-- Menu items table
ALTER TABLE menu_items
    ADD CONSTRAINT chk_menu_items_price
    CHECK (base_price > 0),
    ADD CONSTRAINT chk_menu_items_sale_price
    CHECK (sale_price IS NULL OR (sale_price > 0 AND sale_price < base_price)),
    ADD CONSTRAINT chk_menu_items_calories
    CHECK (calories IS NULL OR calories >= 0),
    ADD CONSTRAINT chk_menu_items_prep_time
    CHECK (preparation_time_minutes > 0 AND preparation_time_minutes <= 180),
    ADD CONSTRAINT chk_menu_items_stock
    CHECK ((daily_limit IS NULL OR daily_limit > 0) AND
           (current_stock IS NULL OR current_stock >= 0)),
    ADD CONSTRAINT chk_menu_items_ordered
    CHECK (times_ordered >= 0);

-- Item customizations table
ALTER TABLE item_customizations
    ADD CONSTRAINT chk_customizations_selections
    CHECK (min_selections >= 0 AND max_selections >= min_selections);

-- Drivers table
ALTER TABLE drivers
    ADD CONSTRAINT chk_drivers_metrics
    CHECK (total_deliveries >= 0 AND successful_deliveries >= 0 AND
           successful_deliveries <= total_deliveries),
    ADD CONSTRAINT chk_drivers_rating
    CHECK (average_rating >= 0 AND average_rating <= 5),
    ADD CONSTRAINT chk_drivers_counts
    CHECK (total_ratings >= 0),
    ADD CONSTRAINT chk_drivers_percentages
    CHECK (on_time_percentage >= 0 AND on_time_percentage <= 100 AND
           acceptance_rate >= 0 AND acceptance_rate <= 100),
    ADD CONSTRAINT chk_drivers_earnings
    CHECK (total_earnings >= 0 AND pending_payout >= 0),
    ADD CONSTRAINT chk_drivers_concurrent
    CHECK (max_concurrent_orders > 0 AND max_concurrent_orders <= 10),
    ADD CONSTRAINT chk_drivers_coordinates
    CHECK ((current_latitude IS NULL OR (current_latitude BETWEEN -90 AND 90)) AND
           (current_longitude IS NULL OR (current_longitude BETWEEN -180 AND 180)));

-- Driver shifts table
ALTER TABLE driver_shifts
    ADD CONSTRAINT chk_shifts_schedule
    CHECK (scheduled_end > scheduled_start),
    ADD CONSTRAINT chk_shifts_metrics
    CHECK (orders_completed >= 0 AND distance_traveled_km >= 0 AND
           earnings >= 0 AND tips >= 0);

-- Orders table
ALTER TABLE orders
    ADD CONSTRAINT chk_orders_timing
    CHECK ((estimated_preparation_time IS NULL OR estimated_preparation_time > 0) AND
           (estimated_delivery_time IS NULL OR estimated_delivery_time > 0)),
    ADD CONSTRAINT chk_orders_amounts
    CHECK (subtotal >= 0 AND tax_amount >= 0 AND delivery_fee >= 0 AND
           service_fee >= 0 AND small_order_fee >= 0 AND tip_amount >= 0 AND
           discount_amount >= 0 AND promo_discount >= 0 AND total_amount >= 0),
    ADD CONSTRAINT chk_orders_refund
    CHECK (refund_amount IS NULL OR refund_amount >= 0),
    ADD CONSTRAINT chk_orders_ratings
    CHECK ((customer_rating IS NULL OR (customer_rating >= 1 AND customer_rating <= 5)) AND
           (driver_rating IS NULL OR (driver_rating >= 1 AND driver_rating <= 5))),
    ADD CONSTRAINT chk_orders_scheduled
    CHECK ((is_scheduled = FALSE AND scheduled_for IS NULL) OR
           (is_scheduled = TRUE AND scheduled_for IS NOT NULL)),
    ADD CONSTRAINT chk_orders_coordinates
    CHECK ((delivery_latitude IS NULL OR (delivery_latitude BETWEEN -90 AND 90)) AND
           (delivery_longitude IS NULL OR (delivery_longitude BETWEEN -180 AND 180)));

-- Order items table
ALTER TABLE order_items
    ADD CONSTRAINT chk_order_items_quantity
    CHECK (quantity > 0),
    ADD CONSTRAINT chk_order_items_price
    CHECK (item_price > 0 AND subtotal > 0);

-- Delivery tracking table
ALTER TABLE delivery_tracking
    ADD CONSTRAINT chk_tracking_coordinates
    CHECK (latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180),
    ADD CONSTRAINT chk_tracking_heading
    CHECK (heading IS NULL OR (heading >= 0 AND heading <= 360)),
    ADD CONSTRAINT chk_tracking_speed
    CHECK (speed_kmh IS NULL OR speed_kmh >= 0),
    ADD CONSTRAINT chk_tracking_distances
    CHECK ((distance_to_restaurant_km IS NULL OR distance_to_restaurant_km >= 0) AND
           (distance_to_customer_km IS NULL OR distance_to_customer_km >= 0));

-- Delivery zones table
ALTER TABLE delivery_zones
    ADD CONSTRAINT chk_zones_fees
    CHECK (base_delivery_fee >= 0 AND min_order_amount >= 0),
    ADD CONSTRAINT chk_zones_distance
    CHECK (max_delivery_distance_km > 0 AND max_delivery_distance_km <= 100),
    ADD CONSTRAINT chk_zones_surge
    CHECK (surge_multiplier >= 1.0 AND surge_multiplier <= 5.0),
    ADD CONSTRAINT chk_zones_metrics
    CHECK (active_drivers >= 0 AND pending_orders >= 0 AND
           average_wait_time_minutes >= 0);

-- Promotions table
ALTER TABLE promotions
    ADD CONSTRAINT chk_promotions_discount
    CHECK (discount_value > 0),
    ADD CONSTRAINT chk_promotions_max_discount
    CHECK (max_discount_amount IS NULL OR max_discount_amount > 0),
    ADD CONSTRAINT chk_promotions_min_order
    CHECK (min_order_amount >= 0),
    ADD CONSTRAINT chk_promotions_uses
    CHECK ((max_uses_total IS NULL OR max_uses_total > 0) AND
           (max_uses_per_customer IS NULL OR max_uses_per_customer > 0)),
    ADD CONSTRAINT chk_promotions_tracking
    CHECK (times_used >= 0 AND total_discount_given >= 0),
    ADD CONSTRAINT chk_promotions_validity
    CHECK (valid_until > valid_from);

-- Promotion usage table
ALTER TABLE promotion_usage
    ADD CONSTRAINT chk_usage_discount
    CHECK (discount_amount > 0);

-- Payment methods table
ALTER TABLE payment_methods
    ADD CONSTRAINT chk_payment_card_exp
    CHECK ((card_exp_month IS NULL OR (card_exp_month >= 1 AND card_exp_month <= 12)) AND
           (card_exp_year IS NULL OR card_exp_year >= 2024));

-- ============================================================================
-- UNIQUE CONSTRAINTS
-- ============================================================================

-- Ensure one default address per customer
ALTER TABLE customer_addresses
    ADD COLUMN default_customer_id BIGINT UNSIGNED GENERATED ALWAYS AS (
        CASE WHEN is_default = TRUE THEN customer_id ELSE NULL END
    ) STORED,
    ADD UNIQUE INDEX uk_customer_default (default_customer_id);

-- Ensure one default payment method per customer
ALTER TABLE payment_methods
    ADD COLUMN default_payment_customer_id BIGINT UNSIGNED GENERATED ALWAYS AS (
        CASE WHEN is_default = TRUE THEN customer_id ELSE NULL END
    ) STORED,
    ADD UNIQUE INDEX uk_customer_default_payment (default_payment_customer_id);
