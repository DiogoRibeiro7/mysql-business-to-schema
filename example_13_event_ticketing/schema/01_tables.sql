-- =========================================
-- Event Ticketing Platform - Core Tables
-- =========================================

USE event_ticketing;

-- =========================================
-- 1. VENUE CONFIGURATION TABLES
-- =========================================

CREATE TABLE IF NOT EXISTS venues (
    venue_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    venue_name VARCHAR(255) NOT NULL,
    venue_type ENUM('stadium', 'arena', 'theater', 'concert_hall', 'conference_center', 'club', 'other') NOT NULL,
    address_line1 VARCHAR(255) NOT NULL,
    address_line2 VARCHAR(255),
    city VARCHAR(100) NOT NULL,
    state_province VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100) NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    capacity INT UNSIGNED NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(255),
    website VARCHAR(255),
    parking_info TEXT,
    public_transport_info TEXT,
    accessibility_info TEXT,
    venue_rules TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_venue_name (venue_name),
    INDEX idx_city (city),
    INDEX idx_active (is_active)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS venue_sections (
    section_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    venue_id INT UNSIGNED NOT NULL,
    section_name VARCHAR(100) NOT NULL,
    section_type ENUM('orchestra', 'mezzanine', 'balcony', 'floor', 'lower_bowl', 'upper_bowl', 'club', 'suite', 'standing', 'general_admission') NOT NULL,
    capacity INT UNSIGNED NOT NULL,
    rows_count INT UNSIGNED,
    default_price_tier VARCHAR(50),
    entry_gate VARCHAR(50),
    is_accessible BOOLEAN DEFAULT FALSE,
    view_quality ENUM('excellent', 'good', 'standard', 'obstructed') DEFAULT 'standard',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (venue_id) REFERENCES venues(venue_id) ON DELETE CASCADE,
    INDEX idx_venue_sections (venue_id),
    UNIQUE INDEX idx_venue_section_name (venue_id, section_name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS venue_rows (
    row_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    section_id INT UNSIGNED NOT NULL,
    row_number VARCHAR(10) NOT NULL,
    seats_count INT UNSIGNED NOT NULL,
    is_accessible BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (section_id) REFERENCES venue_sections(section_id) ON DELETE CASCADE,
    INDEX idx_section_rows (section_id),
    UNIQUE INDEX idx_section_row_number (section_id, row_number)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS venue_seats (
    seat_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    row_id INT UNSIGNED NOT NULL,
    seat_number VARCHAR(10) NOT NULL,
    seat_type ENUM('standard', 'accessible', 'companion', 'obstructed_view', 'premium') DEFAULT 'standard',
    x_coordinate INT,  -- For seat map visualization
    y_coordinate INT,
    is_aisle BOOLEAN DEFAULT FALSE,
    notes VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (row_id) REFERENCES venue_rows(row_id) ON DELETE CASCADE,
    INDEX idx_row_seats (row_id),
    UNIQUE INDEX idx_row_seat_number (row_id, seat_number)
) ENGINE=InnoDB;

-- =========================================
-- 2. EVENT MANAGEMENT TABLES
-- =========================================

CREATE TABLE IF NOT EXISTS event_categories (
    category_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL,
    parent_category_id INT UNSIGNED,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_category_id) REFERENCES event_categories(category_id),
    UNIQUE INDEX idx_category_name (category_name),
    INDEX idx_parent (parent_category_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS performers (
    performer_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    performer_name VARCHAR(255) NOT NULL,
    performer_type ENUM('artist', 'band', 'team', 'speaker', 'company', 'other') NOT NULL,
    genre VARCHAR(100),
    bio TEXT,
    image_url VARCHAR(500),
    website VARCHAR(255),
    social_media JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_performer_name (performer_name),
    INDEX idx_genre (genre)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS events (
    event_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    event_name VARCHAR(255) NOT NULL,
    event_type ENUM('single', 'tour', 'season', 'festival', 'conference') NOT NULL,
    category_id INT UNSIGNED,
    description TEXT,
    image_url VARCHAR(500),
    banner_url VARCHAR(500),
    age_restriction VARCHAR(50),
    duration_minutes INT UNSIGNED,
    organizer_name VARCHAR(255),
    organizer_contact VARCHAR(255),
    is_featured BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES event_categories(category_id),
    INDEX idx_event_name (event_name),
    INDEX idx_event_type (event_type),
    INDEX idx_featured (is_featured),
    FULLTEXT INDEX ft_event (event_name, description)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS performances (
    performance_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    event_id BIGINT UNSIGNED NOT NULL,
    venue_id INT UNSIGNED NOT NULL,
    performance_datetime DATETIME NOT NULL,
    doors_open_datetime DATETIME,
    performance_status ENUM('scheduled', 'on_sale', 'sold_out', 'cancelled', 'postponed', 'completed') DEFAULT 'scheduled',
    total_capacity INT UNSIGNED,
    available_capacity INT UNSIGNED,
    min_ticket_price DECIMAL(10, 2),
    max_ticket_price DECIMAL(10, 2),
    sales_start_datetime DATETIME,
    sales_end_datetime DATETIME,
    is_general_admission BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (event_id) REFERENCES events(event_id),
    FOREIGN KEY (venue_id) REFERENCES venues(venue_id),
    INDEX idx_event_performances (event_id),
    INDEX idx_venue_performances (venue_id),
    INDEX idx_datetime (performance_datetime),
    INDEX idx_status (performance_status),
    INDEX idx_sales_dates (sales_start_datetime, sales_end_datetime)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS event_performers (
    event_performer_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    event_id BIGINT UNSIGNED NOT NULL,
    performer_id INT UNSIGNED NOT NULL,
    billing_order INT UNSIGNED DEFAULT 1,
    is_headliner BOOLEAN DEFAULT FALSE,
    performance_fee DECIMAL(12, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (event_id) REFERENCES events(event_id),
    FOREIGN KEY (performer_id) REFERENCES performers(performer_id),
    UNIQUE INDEX idx_event_performer (event_id, performer_id),
    INDEX idx_performer_events (performer_id)
) ENGINE=InnoDB;

-- =========================================
-- 3. CUSTOMER TABLES
-- =========================================

CREATE TABLE IF NOT EXISTS customers (
    customer_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(20),
    date_of_birth DATE,
    gender ENUM('male', 'female', 'other', 'prefer_not_to_say'),
    preferred_language VARCHAR(10) DEFAULT 'en',
    preferred_currency CHAR(3) DEFAULT 'USD',
    email_verified BOOLEAN DEFAULT FALSE,
    phone_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE INDEX idx_email (email),
    INDEX idx_name (last_name, first_name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS customer_preferences (
    preference_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id BIGINT UNSIGNED NOT NULL,
    favorite_venues JSON,
    favorite_performers JSON,
    preferred_categories JSON,
    notification_events BOOLEAN DEFAULT TRUE,
    notification_offers BOOLEAN DEFAULT TRUE,
    notification_reminders BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE,
    UNIQUE INDEX idx_customer_prefs (customer_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS loyalty_members (
    member_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id BIGINT UNSIGNED NOT NULL,
    membership_tier ENUM('basic', 'silver', 'gold', 'platinum', 'vip') DEFAULT 'basic',
    points_balance INT UNSIGNED DEFAULT 0,
    lifetime_points INT UNSIGNED DEFAULT 0,
    join_date DATE NOT NULL,
    expiry_date DATE,
    perks JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE,
    UNIQUE INDEX idx_customer_loyalty (customer_id),
    INDEX idx_tier (membership_tier)
) ENGINE=InnoDB;

-- =========================================
-- 4. PRICING TABLES
-- =========================================

CREATE TABLE IF NOT EXISTS price_tiers (
    price_tier_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    performance_id BIGINT UNSIGNED NOT NULL,
    tier_name VARCHAR(100) NOT NULL,
    base_price DECIMAL(10, 2) NOT NULL,
    service_fee DECIMAL(10, 2) DEFAULT 0.00,
    facility_fee DECIMAL(10, 2) DEFAULT 0.00,
    tax_rate DECIMAL(5, 4) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (performance_id) REFERENCES performances(performance_id) ON DELETE CASCADE,
    INDEX idx_performance_tiers (performance_id),
    UNIQUE INDEX idx_performance_tier_name (performance_id, tier_name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS section_pricing (
    section_price_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    performance_id BIGINT UNSIGNED NOT NULL,
    section_id INT UNSIGNED NOT NULL,
    price_tier_id INT UNSIGNED NOT NULL,
    current_price DECIMAL(10, 2) NOT NULL,
    original_price DECIMAL(10, 2),
    min_price DECIMAL(10, 2),
    max_price DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (performance_id) REFERENCES performances(performance_id) ON DELETE CASCADE,
    FOREIGN KEY (section_id) REFERENCES venue_sections(section_id),
    FOREIGN KEY (price_tier_id) REFERENCES price_tiers(price_tier_id),
    UNIQUE INDEX idx_performance_section (performance_id, section_id),
    INDEX idx_price_tier (price_tier_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS promotional_codes (
    promo_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    promo_code VARCHAR(50) NOT NULL,
    description VARCHAR(255),
    discount_type ENUM('percentage', 'fixed_amount') NOT NULL,
    discount_value DECIMAL(10, 2) NOT NULL,
    min_purchase_amount DECIMAL(10, 2),
    max_discount_amount DECIMAL(10, 2),
    valid_from DATETIME NOT NULL,
    valid_until DATETIME NOT NULL,
    usage_limit INT UNSIGNED,
    usage_count INT UNSIGNED DEFAULT 0,
    applicable_performances JSON,
    applicable_sections JSON,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE INDEX idx_promo_code (promo_code),
    INDEX idx_validity (valid_from, valid_until),
    INDEX idx_active (is_active)
) ENGINE=InnoDB;

-- =========================================
-- 5. BOOKING & TICKETING TABLES
-- =========================================

CREATE TABLE IF NOT EXISTS bookings (
    booking_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    booking_reference VARCHAR(20) NOT NULL,
    customer_id BIGINT UNSIGNED NOT NULL,
    performance_id BIGINT UNSIGNED NOT NULL,
    booking_status ENUM('pending', 'confirmed', 'cancelled', 'refunded') DEFAULT 'pending',
    total_amount DECIMAL(10, 2) NOT NULL,
    discount_amount DECIMAL(10, 2) DEFAULT 0.00,
    tax_amount DECIMAL(10, 2) DEFAULT 0.00,
    service_fee_amount DECIMAL(10, 2) DEFAULT 0.00,
    payment_method VARCHAR(50),
    payment_status ENUM('pending', 'processing', 'completed', 'failed', 'refunded') DEFAULT 'pending',
    promo_code_used VARCHAR(50),
    booking_datetime TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    confirmation_sent BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (performance_id) REFERENCES performances(performance_id),
    UNIQUE INDEX idx_booking_reference (booking_reference),
    INDEX idx_customer_bookings (customer_id),
    INDEX idx_performance_bookings (performance_id),
    INDEX idx_status (booking_status),
    INDEX idx_booking_datetime (booking_datetime DESC)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS tickets (
    ticket_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    booking_id BIGINT UNSIGNED NOT NULL,
    seat_id BIGINT UNSIGNED,  -- NULL for general admission
    ticket_number VARCHAR(50) NOT NULL,
    ticket_status ENUM('valid', 'used', 'cancelled', 'transferred', 'resold') DEFAULT 'valid',
    price_paid DECIMAL(10, 2) NOT NULL,
    barcode VARCHAR(100),
    qr_code VARCHAR(255),
    issue_datetime TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    used_datetime TIMESTAMP NULL,
    entry_gate VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id),
    FOREIGN KEY (seat_id) REFERENCES venue_seats(seat_id),
    UNIQUE INDEX idx_ticket_number (ticket_number),
    INDEX idx_booking_tickets (booking_id),
    INDEX idx_seat (seat_id),
    INDEX idx_status (ticket_status),
    INDEX idx_barcode (barcode)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS ticket_holds (
    hold_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    session_id VARCHAR(100) NOT NULL,
    customer_id BIGINT UNSIGNED,
    performance_id BIGINT UNSIGNED NOT NULL,
    seat_id BIGINT UNSIGNED NOT NULL,
    hold_expiry TIMESTAMP NOT NULL,
    is_released BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (performance_id) REFERENCES performances(performance_id),
    FOREIGN KEY (seat_id) REFERENCES venue_seats(seat_id),
    UNIQUE INDEX idx_performance_seat (performance_id, seat_id),
    INDEX idx_session (session_id),
    INDEX idx_expiry (hold_expiry),
    INDEX idx_released (is_released)
) ENGINE=InnoDB;

-- =========================================
-- 6. CART & CHECKOUT TABLES
-- =========================================

CREATE TABLE IF NOT EXISTS shopping_carts (
    cart_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    session_id VARCHAR(100) NOT NULL,
    customer_id BIGINT UNSIGNED,
    performance_id BIGINT UNSIGNED NOT NULL,
    cart_status ENUM('active', 'expired', 'converted', 'abandoned') DEFAULT 'active',
    expiry_datetime TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (performance_id) REFERENCES performances(performance_id),
    UNIQUE INDEX idx_session_cart (session_id),
    INDEX idx_customer_carts (customer_id),
    INDEX idx_status (cart_status),
    INDEX idx_expiry (expiry_datetime)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS cart_items (
    cart_item_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    cart_id BIGINT UNSIGNED NOT NULL,
    seat_id BIGINT UNSIGNED,
    price_tier_id INT UNSIGNED NOT NULL,
    quantity INT UNSIGNED DEFAULT 1,
    unit_price DECIMAL(10, 2) NOT NULL,
    service_fee DECIMAL(10, 2) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cart_id) REFERENCES shopping_carts(cart_id) ON DELETE CASCADE,
    FOREIGN KEY (seat_id) REFERENCES venue_seats(seat_id),
    FOREIGN KEY (price_tier_id) REFERENCES price_tiers(price_tier_id),
    INDEX idx_cart_items (cart_id),
    UNIQUE INDEX idx_cart_seat (cart_id, seat_id)
) ENGINE=InnoDB;

-- =========================================
-- 7. ACCESS CONTROL TABLES
-- =========================================

CREATE TABLE IF NOT EXISTS entry_scans (
    scan_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    ticket_id BIGINT UNSIGNED NOT NULL,
    scan_datetime TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    entry_gate VARCHAR(50),
    scanner_device_id VARCHAR(100),
    scan_result ENUM('success', 'duplicate', 'invalid', 'expired') NOT NULL,
    notes VARCHAR(255),
    FOREIGN KEY (ticket_id) REFERENCES tickets(ticket_id),
    INDEX idx_ticket_scans (ticket_id),
    INDEX idx_scan_datetime (scan_datetime DESC),
    INDEX idx_result (scan_result)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS fraud_attempts (
    fraud_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    attempt_type ENUM('duplicate_booking', 'invalid_ticket', 'bot_activity', 'payment_fraud', 'resale_violation') NOT NULL,
    customer_id BIGINT UNSIGNED,
    ip_address VARCHAR(45),
    user_agent TEXT,
    details JSON,
    action_taken VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    INDEX idx_customer_fraud (customer_id),
    INDEX idx_attempt_type (attempt_type),
    INDEX idx_created (created_at DESC)
) ENGINE=InnoDB;

-- =========================================
-- 8. SECONDARY MARKET TABLES
-- =========================================

CREATE TABLE IF NOT EXISTS resale_listings (
    listing_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    ticket_id BIGINT UNSIGNED NOT NULL,
    seller_customer_id BIGINT UNSIGNED NOT NULL,
    listing_price DECIMAL(10, 2) NOT NULL,
    min_price DECIMAL(10, 2),
    listing_status ENUM('active', 'sold', 'expired', 'withdrawn') DEFAULT 'active',
    listed_datetime TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sold_datetime TIMESTAMP NULL,
    expiry_datetime TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (ticket_id) REFERENCES tickets(ticket_id),
    FOREIGN KEY (seller_customer_id) REFERENCES customers(customer_id),
    INDEX idx_ticket_listing (ticket_id),
    INDEX idx_seller (seller_customer_id),
    INDEX idx_status (listing_status),
    INDEX idx_price (listing_price)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS resale_transactions (
    resale_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    listing_id BIGINT UNSIGNED NOT NULL,
    buyer_customer_id BIGINT UNSIGNED NOT NULL,
    sale_price DECIMAL(10, 2) NOT NULL,
    platform_fee DECIMAL(10, 2) DEFAULT 0.00,
    seller_payout DECIMAL(10, 2) NOT NULL,
    transaction_status ENUM('pending', 'completed', 'cancelled', 'disputed') DEFAULT 'pending',
    transaction_datetime TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (listing_id) REFERENCES resale_listings(listing_id),
    FOREIGN KEY (buyer_customer_id) REFERENCES customers(customer_id),
    INDEX idx_listing (listing_id),
    INDEX idx_buyer (buyer_customer_id),
    INDEX idx_status (transaction_status)
) ENGINE=InnoDB;

-- =========================================
-- 9. ANALYTICS TABLES
-- =========================================

CREATE TABLE IF NOT EXISTS sales_metrics (
    metric_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    performance_id BIGINT UNSIGNED NOT NULL,
    metric_date DATE NOT NULL,
    tickets_sold INT UNSIGNED DEFAULT 0,
    gross_revenue DECIMAL(12, 2) DEFAULT 0.00,
    service_fees DECIMAL(10, 2) DEFAULT 0.00,
    average_ticket_price DECIMAL(10, 2),
    conversion_rate DECIMAL(5, 4),
    cart_abandonment_rate DECIMAL(5, 4),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (performance_id) REFERENCES performances(performance_id),
    UNIQUE INDEX idx_performance_date (performance_id, metric_date),
    INDEX idx_date (metric_date DESC)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS venue_utilization (
    utilization_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    venue_id INT UNSIGNED NOT NULL,
    performance_id BIGINT UNSIGNED NOT NULL,
    total_capacity INT UNSIGNED NOT NULL,
    tickets_sold INT UNSIGNED DEFAULT 0,
    utilization_percentage DECIMAL(5, 2),
    revenue_per_seat DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (venue_id) REFERENCES venues(venue_id),
    FOREIGN KEY (performance_id) REFERENCES performances(performance_id),
    INDEX idx_venue (venue_id),
    INDEX idx_performance (performance_id)
) ENGINE=InnoDB;

-- =========================================
-- Show tables created
-- =========================================
SHOW TABLES;
SELECT 'Event Ticketing tables created successfully' AS status;