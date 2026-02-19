-- ============================================================================
-- CORE TABLES FOR FOOD DELIVERY PLATFORM
-- ============================================================================

USE food_delivery;

-- ============================================================================
-- USER MANAGEMENT
-- ============================================================================

-- Customers table
CREATE TABLE customers (
    customer_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    email VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,

    -- Personal Information
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE,

    -- Preferences
    dietary_restrictions JSON, -- ["vegetarian", "gluten-free", "halal", etc]
    preferred_cuisines JSON, -- ["italian", "chinese", "mexican", etc]
    default_tip_percentage DECIMAL(5,2) DEFAULT 15.00,

    -- Account Status
    status ENUM('active', 'suspended', 'deactivated') DEFAULT 'active',
    email_verified BOOLEAN DEFAULT FALSE,
    phone_verified BOOLEAN DEFAULT FALSE,

    -- Loyalty Program
    loyalty_points INT DEFAULT 0,
    loyalty_tier ENUM('bronze', 'silver', 'gold', 'platinum') DEFAULT 'bronze',
    total_orders INT DEFAULT 0,
    total_spent DECIMAL(10,2) DEFAULT 0,

    -- Notifications
    push_notifications_enabled BOOLEAN DEFAULT TRUE,
    sms_notifications_enabled BOOLEAN DEFAULT TRUE,
    email_notifications_enabled BOOLEAN DEFAULT TRUE,

    -- Referral
    referral_code VARCHAR(20) UNIQUE,
    referred_by_customer_id BIGINT UNSIGNED,

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_order_at TIMESTAMP NULL,

    PRIMARY KEY (customer_id),
    UNIQUE KEY uk_email (email),
    UNIQUE KEY uk_phone (phone_number),
    INDEX idx_status (status),
    INDEX idx_loyalty_tier (loyalty_tier),
    INDEX idx_referral (referred_by_customer_id)
) ENGINE=InnoDB;

-- Customer addresses
CREATE TABLE customer_addresses (
    address_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    customer_id BIGINT UNSIGNED NOT NULL,

    -- Address details
    label VARCHAR(50), -- "Home", "Work", "Gym", etc.
    address_line1 VARCHAR(255) NOT NULL,
    address_line2 VARCHAR(255),
    city VARCHAR(100) NOT NULL,
    state_province VARCHAR(100) NOT NULL,
    postal_code VARCHAR(20) NOT NULL,
    country VARCHAR(2) DEFAULT 'US', -- ISO country code

    -- Location
    latitude DECIMAL(10,8) NOT NULL,
    longitude DECIMAL(11,8) NOT NULL,

    -- Delivery instructions
    delivery_instructions TEXT,
    gate_code VARCHAR(20),

    -- Metadata
    is_default BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (address_id),
    INDEX idx_customer (customer_id),
    INDEX idx_location (latitude, longitude),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
) ENGINE=InnoDB;

-- ============================================================================
-- RESTAURANT MANAGEMENT
-- ============================================================================

-- Restaurants table
CREATE TABLE restaurants (
    restaurant_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) NOT NULL, -- URL-friendly name

    -- Contact Information
    email VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,

    -- Business Information
    business_license VARCHAR(100),
    tax_id VARCHAR(50),

    -- Location
    address_line1 VARCHAR(255) NOT NULL,
    address_line2 VARCHAR(255),
    city VARCHAR(100) NOT NULL,
    state_province VARCHAR(100) NOT NULL,
    postal_code VARCHAR(20) NOT NULL,
    country VARCHAR(2) DEFAULT 'US',
    latitude DECIMAL(10,8) NOT NULL,
    longitude DECIMAL(11,8) NOT NULL,

    -- Service Settings
    cuisine_types JSON, -- ["italian", "pizza", "pasta"]
    price_range ENUM('$', '$$', '$$$', '$$$$') DEFAULT '$$',
    delivery_radius_km DECIMAL(5,2) DEFAULT 5.00,
    minimum_order_amount DECIMAL(10,2) DEFAULT 0,

    -- Timing
    preparation_time_minutes INT DEFAULT 30,
    pickup_enabled BOOLEAN DEFAULT TRUE,
    delivery_enabled BOOLEAN DEFAULT TRUE,
    schedule_orders_enabled BOOLEAN DEFAULT TRUE,

    -- Fees and Commission
    delivery_fee DECIMAL(10,2) DEFAULT 0,
    service_fee_percentage DECIMAL(5,2) DEFAULT 15.00, -- Platform commission

    -- Status
    status ENUM('pending', 'active', 'suspended', 'closed') DEFAULT 'pending',
    is_featured BOOLEAN DEFAULT FALSE,
    is_promoted BOOLEAN DEFAULT FALSE,

    -- Ratings
    average_rating DECIMAL(3,2) DEFAULT 0,
    total_ratings INT DEFAULT 0,
    total_orders INT DEFAULT 0,

    -- Media
    logo_url VARCHAR(500),
    banner_image_url VARCHAR(500),

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    activated_at TIMESTAMP NULL,

    PRIMARY KEY (restaurant_id),
    UNIQUE KEY uk_slug (slug),
    UNIQUE KEY uk_email (email),
    INDEX idx_status (status),
    INDEX idx_location (latitude, longitude),
    INDEX idx_rating (average_rating DESC),
    FULLTEXT INDEX ft_name (name)
) ENGINE=InnoDB;

-- Restaurant operating hours
CREATE TABLE restaurant_hours (
    hours_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    restaurant_id BIGINT UNSIGNED NOT NULL,

    -- Schedule
    day_of_week ENUM('monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday') NOT NULL,
    open_time TIME NOT NULL,
    close_time TIME NOT NULL,
    is_closed BOOLEAN DEFAULT FALSE,

    -- Special hours
    special_hours_date DATE,
    special_hours_reason VARCHAR(100), -- "Holiday", "Maintenance", etc.

    PRIMARY KEY (hours_id),
    UNIQUE KEY uk_restaurant_day (restaurant_id, day_of_week, special_hours_date),
    INDEX idx_restaurant (restaurant_id),
    FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id)
) ENGINE=InnoDB;

-- ============================================================================
-- MENU MANAGEMENT
-- ============================================================================

-- Menu categories
CREATE TABLE menu_categories (
    category_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    restaurant_id BIGINT UNSIGNED NOT NULL,

    name VARCHAR(100) NOT NULL,
    description TEXT,
    display_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,

    -- Schedule (for breakfast, lunch, dinner menus)
    available_start_time TIME,
    available_end_time TIME,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (category_id),
    INDEX idx_restaurant (restaurant_id),
    INDEX idx_active_order (restaurant_id, is_active, display_order),
    FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id)
) ENGINE=InnoDB;

-- Menu items
CREATE TABLE menu_items (
    item_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    restaurant_id BIGINT UNSIGNED NOT NULL,
    category_id BIGINT UNSIGNED NOT NULL,

    -- Basic Information
    name VARCHAR(255) NOT NULL,
    description TEXT,

    -- Pricing
    base_price DECIMAL(10,2) NOT NULL,
    sale_price DECIMAL(10,2),

    -- Attributes
    calories INT,
    preparation_time_minutes INT DEFAULT 15,
    spice_level ENUM('none', 'mild', 'medium', 'hot', 'extra_hot'),

    -- Dietary Information
    is_vegetarian BOOLEAN DEFAULT FALSE,
    is_vegan BOOLEAN DEFAULT FALSE,
    is_gluten_free BOOLEAN DEFAULT FALSE,
    is_halal BOOLEAN DEFAULT FALSE,
    is_kosher BOOLEAN DEFAULT FALSE,
    allergens JSON, -- ["nuts", "dairy", "eggs", etc]

    -- Availability
    is_available BOOLEAN DEFAULT TRUE,
    daily_limit INT,
    current_stock INT,

    -- Popularity
    times_ordered INT DEFAULT 0,
    is_popular BOOLEAN DEFAULT FALSE,
    is_recommended BOOLEAN DEFAULT FALSE,

    -- Media
    image_url VARCHAR(500),

    -- Display
    display_order INT DEFAULT 0,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (item_id),
    INDEX idx_restaurant (restaurant_id),
    INDEX idx_category (category_id),
    INDEX idx_available (restaurant_id, is_available),
    INDEX idx_popular (restaurant_id, is_popular),
    FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id),
    FOREIGN KEY (category_id) REFERENCES menu_categories(category_id),
    FULLTEXT INDEX ft_name_description (name, description)
) ENGINE=InnoDB;

-- Customization options for menu items
CREATE TABLE item_customizations (
    customization_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    item_id BIGINT UNSIGNED NOT NULL,

    -- Customization details
    group_name VARCHAR(100) NOT NULL, -- "Size", "Toppings", "Sides"
    is_required BOOLEAN DEFAULT FALSE,
    min_selections INT DEFAULT 0,
    max_selections INT DEFAULT 1,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (customization_id),
    INDEX idx_item (item_id),
    FOREIGN KEY (item_id) REFERENCES menu_items(item_id)
) ENGINE=InnoDB;

-- Customization options
CREATE TABLE customization_options (
    option_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    customization_id BIGINT UNSIGNED NOT NULL,

    name VARCHAR(100) NOT NULL,
    price_adjustment DECIMAL(10,2) DEFAULT 0,
    is_default BOOLEAN DEFAULT FALSE,
    is_available BOOLEAN DEFAULT TRUE,

    PRIMARY KEY (option_id),
    INDEX idx_customization (customization_id),
    FOREIGN KEY (customization_id) REFERENCES item_customizations(customization_id)
) ENGINE=InnoDB;

-- ============================================================================
-- DELIVERY PERSONNEL
-- ============================================================================

-- Delivery drivers/riders
CREATE TABLE drivers (
    driver_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    email VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,

    -- Personal Information
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,

    -- Documents
    license_number VARCHAR(50),
    license_expiry DATE,
    insurance_policy_number VARCHAR(100),
    insurance_expiry DATE,
    background_check_status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    background_check_date DATE,

    -- Vehicle Information
    vehicle_type ENUM('bicycle', 'scooter', 'motorcycle', 'car', 'drone', 'robot') DEFAULT 'car',
    vehicle_make VARCHAR(50),
    vehicle_model VARCHAR(50),
    vehicle_year YEAR,
    vehicle_color VARCHAR(30),
    vehicle_plate VARCHAR(20),

    -- Status
    status ENUM('pending', 'active', 'busy', 'offline', 'suspended') DEFAULT 'pending',
    is_available BOOLEAN DEFAULT FALSE,
    current_latitude DECIMAL(10,8),
    current_longitude DECIMAL(11,8),
    last_location_update TIMESTAMP NULL,

    -- Performance Metrics
    total_deliveries INT DEFAULT 0,
    successful_deliveries INT DEFAULT 0,
    average_rating DECIMAL(3,2) DEFAULT 5.00,
    total_ratings INT DEFAULT 0,
    on_time_percentage DECIMAL(5,2) DEFAULT 100.00,
    acceptance_rate DECIMAL(5,2) DEFAULT 100.00,

    -- Earnings
    total_earnings DECIMAL(10,2) DEFAULT 0,
    pending_payout DECIMAL(10,2) DEFAULT 0,

    -- Shifts
    preferred_zones JSON, -- Zone IDs where driver prefers to work
    max_concurrent_orders INT DEFAULT 2,

    -- Bank Information (encrypted)
    bank_account_info JSON,

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_active_at TIMESTAMP NULL,

    PRIMARY KEY (driver_id),
    UNIQUE KEY uk_email (email),
    UNIQUE KEY uk_phone (phone_number),
    UNIQUE KEY uk_license (license_number),
    INDEX idx_status (status),
    INDEX idx_available (is_available, status),
    INDEX idx_location (current_latitude, current_longitude),
    INDEX idx_rating (average_rating DESC),
) ENGINE=InnoDB;

-- Driver shift schedule
CREATE TABLE driver_shifts (
    shift_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    driver_id BIGINT UNSIGNED NOT NULL,

    -- Shift timing
    scheduled_start TIMESTAMP NOT NULL,
    scheduled_end TIMESTAMP NOT NULL,
    actual_start TIMESTAMP NULL,
    actual_end TIMESTAMP NULL,

    -- Metrics
    orders_completed INT DEFAULT 0,
    distance_traveled_km DECIMAL(10,2) DEFAULT 0,
    earnings DECIMAL(10,2) DEFAULT 0,
    tips DECIMAL(10,2) DEFAULT 0,

    -- Status
    status ENUM('scheduled', 'active', 'completed', 'cancelled') DEFAULT 'scheduled',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (shift_id),
    INDEX idx_driver (driver_id),
    INDEX idx_schedule (scheduled_start, scheduled_end),
    INDEX idx_status (status),
    FOREIGN KEY (driver_id) REFERENCES drivers(driver_id)
) ENGINE=InnoDB;

-- ============================================================================
-- ORDER MANAGEMENT
-- ============================================================================

-- Orders table
CREATE TABLE orders (
    order_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    order_number VARCHAR(20) NOT NULL, -- Human-readable order number
    customer_id BIGINT UNSIGNED NOT NULL,
    restaurant_id BIGINT UNSIGNED NOT NULL,
    driver_id BIGINT UNSIGNED,

    -- Order Type
    order_type ENUM('delivery', 'pickup', 'dine_in') DEFAULT 'delivery',

    -- Delivery Information
    delivery_address_id BIGINT UNSIGNED,
    delivery_latitude DECIMAL(10,8),
    delivery_longitude DECIMAL(11,8),
    delivery_instructions TEXT,

    -- Timing
    placed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    confirmed_at TIMESTAMP NULL,
    preparing_at TIMESTAMP NULL,
    ready_at TIMESTAMP NULL,
    picked_up_at TIMESTAMP NULL,
    delivered_at TIMESTAMP NULL,

    -- Scheduled orders
    is_scheduled BOOLEAN DEFAULT FALSE,
    scheduled_for TIMESTAMP NULL,

    -- Estimated times
    estimated_preparation_time INT, -- minutes
    estimated_delivery_time INT, -- minutes
    actual_delivery_time INT, -- minutes

    -- Amounts (all in order currency)
    subtotal DECIMAL(10,2) NOT NULL,
    tax_amount DECIMAL(10,2) DEFAULT 0,
    delivery_fee DECIMAL(10,2) DEFAULT 0,
    service_fee DECIMAL(10,2) DEFAULT 0,
    small_order_fee DECIMAL(10,2) DEFAULT 0,
    tip_amount DECIMAL(10,2) DEFAULT 0,
    discount_amount DECIMAL(10,2) DEFAULT 0,
    total_amount DECIMAL(10,2) NOT NULL,

    -- Promo codes
    promo_code VARCHAR(50),
    promo_discount DECIMAL(10,2) DEFAULT 0,

    -- Payment
    payment_method ENUM('card', 'cash', 'wallet', 'paypal') DEFAULT 'card',
    payment_status ENUM('pending', 'authorized', 'captured', 'failed', 'refunded') DEFAULT 'pending',
    payment_intent_id VARCHAR(255), -- Stripe/payment processor ID

    -- Status
    status ENUM('pending', 'confirmed', 'preparing', 'ready', 'picked_up',
                'on_the_way', 'delivered', 'cancelled', 'refunded') DEFAULT 'pending',

    -- Cancellation
    cancelled_by ENUM('customer', 'restaurant', 'driver', 'system'),
    cancellation_reason TEXT,
    refund_amount DECIMAL(10,2),
    refund_status ENUM('pending', 'processing', 'completed', 'failed'),

    -- Rating
    customer_rating INT, -- 1-5 stars
    customer_review TEXT,
    driver_rating INT, -- 1-5 stars

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (order_id),
    UNIQUE KEY uk_order_number (order_number),
    INDEX idx_customer (customer_id),
    INDEX idx_restaurant (restaurant_id),
    INDEX idx_driver (driver_id),
    INDEX idx_status (status),
    INDEX idx_placed_at (placed_at DESC),
    INDEX idx_scheduled (is_scheduled, scheduled_for),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id),
    FOREIGN KEY (driver_id) REFERENCES drivers(driver_id),
    FOREIGN KEY (delivery_address_id) REFERENCES customer_addresses(address_id)
) ENGINE=InnoDB;

-- Order items
CREATE TABLE order_items (
    order_item_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    order_id BIGINT UNSIGNED NOT NULL,
    item_id BIGINT UNSIGNED NOT NULL,

    -- Item details (denormalized for history)
    item_name VARCHAR(255) NOT NULL,
    item_price DECIMAL(10,2) NOT NULL,

    -- Quantity and totals
    quantity INT NOT NULL DEFAULT 1,
    subtotal DECIMAL(10,2) NOT NULL,

    -- Special instructions
    special_instructions TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (order_item_id),
    INDEX idx_order (order_id),
    INDEX idx_item (item_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (item_id) REFERENCES menu_items(item_id)
) ENGINE=InnoDB;

-- Order item customizations
CREATE TABLE order_item_customizations (
    customization_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    order_item_id BIGINT UNSIGNED NOT NULL,

    -- Customization details (denormalized)
    group_name VARCHAR(100) NOT NULL,
    option_name VARCHAR(100) NOT NULL,
    price_adjustment DECIMAL(10,2) DEFAULT 0,

    PRIMARY KEY (customization_id),
    INDEX idx_order_item (order_item_id),
    FOREIGN KEY (order_item_id) REFERENCES order_items(order_item_id)
) ENGINE=InnoDB;

-- ============================================================================
-- DELIVERY TRACKING
-- ============================================================================

-- Real-time delivery tracking
CREATE TABLE delivery_tracking (
    tracking_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    order_id BIGINT UNSIGNED NOT NULL,
    driver_id BIGINT UNSIGNED NOT NULL,

    -- Location
    latitude DECIMAL(10,8) NOT NULL,
    longitude DECIMAL(11,8) NOT NULL,
    heading INT, -- Direction in degrees (0-360)
    speed_kmh DECIMAL(5,2),

    -- Distance
    distance_to_restaurant_km DECIMAL(10,2),
    distance_to_customer_km DECIMAL(10,2),

    -- Status
    status ENUM('heading_to_restaurant', 'at_restaurant', 'heading_to_customer',
                'near_customer', 'delivered') DEFAULT 'heading_to_restaurant',

    -- Timestamp
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (tracking_id),
    INDEX idx_order (order_id),
    INDEX idx_driver (driver_id),
    INDEX idx_recorded (recorded_at DESC),
    INDEX idx_location (latitude, longitude),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (driver_id) REFERENCES drivers(driver_id)
) ENGINE=InnoDB;

-- ============================================================================
-- ZONES AND SURGE PRICING
-- ============================================================================

-- Delivery zones
CREATE TABLE delivery_zones (
    zone_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,

    -- Zone boundary (GeoJSON polygon)
    boundary GEOMETRY NOT NULL SRID 4326,

    -- Settings
    base_delivery_fee DECIMAL(10,2) DEFAULT 5.00,
    min_order_amount DECIMAL(10,2) DEFAULT 10.00,
    max_delivery_distance_km DECIMAL(5,2) DEFAULT 10.00,

    -- Surge pricing
    surge_multiplier DECIMAL(3,2) DEFAULT 1.00, -- 1.5 = 50% increase
    surge_active BOOLEAN DEFAULT FALSE,
    surge_reason VARCHAR(100), -- "High demand", "Bad weather", etc.

    -- Statistics
    active_drivers INT DEFAULT 0,
    pending_orders INT DEFAULT 0,
    average_wait_time_minutes INT DEFAULT 0,

    -- Status
    is_active BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (zone_id),
    UNIQUE KEY uk_name (name),
) ENGINE=InnoDB;

-- ============================================================================
-- RATINGS AND REVIEWS
-- ============================================================================

-- Restaurant reviews
CREATE TABLE restaurant_reviews (
    review_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    restaurant_id BIGINT UNSIGNED NOT NULL,
    customer_id BIGINT UNSIGNED NOT NULL,
    order_id BIGINT UNSIGNED NOT NULL,

    -- Rating
    food_rating INT NOT NULL CHECK (food_rating BETWEEN 1 AND 5),
    delivery_rating INT CHECK (delivery_rating BETWEEN 1 AND 5),
    overall_rating INT NOT NULL CHECK (overall_rating BETWEEN 1 AND 5),

    -- Review
    review_text TEXT,

    -- Response
    restaurant_response TEXT,
    responded_at TIMESTAMP NULL,

    -- Flags
    is_verified_purchase BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    is_hidden BOOLEAN DEFAULT FALSE,

    -- Helpful votes
    helpful_count INT DEFAULT 0,
    not_helpful_count INT DEFAULT 0,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (review_id),
    UNIQUE KEY uk_order (order_id),
    INDEX idx_restaurant (restaurant_id),
    INDEX idx_customer (customer_id),
    INDEX idx_rating (overall_rating DESC),
    INDEX idx_created (created_at DESC),
    FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
) ENGINE=InnoDB;

-- Driver ratings
CREATE TABLE driver_ratings (
    rating_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    driver_id BIGINT UNSIGNED NOT NULL,
    customer_id BIGINT UNSIGNED NOT NULL,
    order_id BIGINT UNSIGNED NOT NULL,

    -- Rating
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),

    -- Feedback
    on_time BOOLEAN,
    friendly BOOLEAN,
    order_handled_carefully BOOLEAN,
    followed_instructions BOOLEAN,

    -- Comments
    comments TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (rating_id),
    UNIQUE KEY uk_order (order_id),
    INDEX idx_driver (driver_id),
    INDEX idx_customer (customer_id),
    FOREIGN KEY (driver_id) REFERENCES drivers(driver_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
) ENGINE=InnoDB;

-- ============================================================================
-- PROMOTIONS AND DISCOUNTS
-- ============================================================================

-- Promotional campaigns
CREATE TABLE promotions (
    promotion_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    -- Basic Information
    name VARCHAR(255) NOT NULL,
    description TEXT,
    code VARCHAR(50) UNIQUE,

    -- Discount Type
    discount_type ENUM('percentage', 'fixed_amount', 'delivery_fee', 'bogo') NOT NULL,
    discount_value DECIMAL(10,2) NOT NULL,
    max_discount_amount DECIMAL(10,2),

    -- Conditions
    min_order_amount DECIMAL(10,2) DEFAULT 0,
    max_uses_total INT,
    max_uses_per_customer INT DEFAULT 1,

    -- Targeting
    customer_segment ENUM('all', 'new', 'returning', 'vip', 'inactive'),
    applicable_restaurants JSON, -- Restaurant IDs, NULL = all
    applicable_categories JSON, -- Category names, NULL = all

    -- Validity
    valid_from TIMESTAMP NOT NULL,
    valid_until TIMESTAMP NOT NULL,

    -- Days of week (JSON array of days)
    valid_days JSON, -- ["monday", "friday", "saturday"]
    valid_hours_start TIME,
    valid_hours_end TIME,

    -- Usage tracking
    times_used INT DEFAULT 0,
    total_discount_given DECIMAL(10,2) DEFAULT 0,

    -- Status
    is_active BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (promotion_id),
    UNIQUE KEY uk_code (code),
    INDEX idx_valid_dates (valid_from, valid_until),
    INDEX idx_active (is_active)
) ENGINE=InnoDB;

-- Promotion usage tracking
CREATE TABLE promotion_usage (
    usage_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    promotion_id BIGINT UNSIGNED NOT NULL,
    customer_id BIGINT UNSIGNED NOT NULL,
    order_id BIGINT UNSIGNED NOT NULL,

    discount_amount DECIMAL(10,2) NOT NULL,
    used_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (usage_id),
    UNIQUE KEY uk_order (order_id),
    INDEX idx_promotion (promotion_id),
    INDEX idx_customer (customer_id),
    FOREIGN KEY (promotion_id) REFERENCES promotions(promotion_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
) ENGINE=InnoDB;

-- ============================================================================
-- NOTIFICATIONS
-- ============================================================================

-- Push notification logs
CREATE TABLE notifications (
    notification_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    -- Recipient
    recipient_type ENUM('customer', 'driver', 'restaurant') NOT NULL,
    recipient_id BIGINT UNSIGNED NOT NULL,

    -- Content
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    action_url VARCHAR(500),

    -- Type and priority
    notification_type ENUM('order_update', 'promotion', 'system', 'chat') NOT NULL,
    priority ENUM('low', 'medium', 'high', 'urgent') DEFAULT 'medium',

    -- Delivery
    channel ENUM('push', 'sms', 'email', 'in_app') NOT NULL,
    status ENUM('pending', 'sent', 'delivered', 'failed', 'read') DEFAULT 'pending',

    -- Tracking
    sent_at TIMESTAMP NULL,
    delivered_at TIMESTAMP NULL,
    read_at TIMESTAMP NULL,
    error_message TEXT,

    -- Reference
    order_id BIGINT UNSIGNED,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (notification_id),
    INDEX idx_recipient (recipient_type, recipient_id),
    INDEX idx_status (status),
    INDEX idx_created (created_at DESC),
    INDEX idx_order (order_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
) ENGINE=InnoDB;

-- ============================================================================
-- PAYMENT METHODS
-- ============================================================================

-- Customer saved payment methods
CREATE TABLE payment_methods (
    payment_method_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    customer_id BIGINT UNSIGNED NOT NULL,

    -- Payment details
    type ENUM('card', 'paypal', 'apple_pay', 'google_pay') NOT NULL,

    -- Card details (encrypted/tokenized)
    card_last_four VARCHAR(4),
    card_brand VARCHAR(20), -- Visa, Mastercard, etc.
    card_exp_month TINYINT,
    card_exp_year YEAR,

    -- External references
    stripe_payment_method_id VARCHAR(255),
    paypal_account_id VARCHAR(255),

    -- Metadata
    is_default BOOLEAN DEFAULT FALSE,
    nickname VARCHAR(50), -- "Personal Visa", "Work Card"

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (payment_method_id),
    INDEX idx_customer (customer_id),
    INDEX idx_default (customer_id, is_default),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
) ENGINE=InnoDB;
