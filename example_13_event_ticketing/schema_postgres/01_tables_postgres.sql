-- PostgreSQL Schema
-- Converted from MySQL on 2026-02-17T23:11:17.387199
-- Generator: MySQL to PostgreSQL Converter

-- Enum Types
CREATE TYPE venues_status AS ENUM ('stadium', 'arena', 'theater', 'concert_hall', 'conference_center', 'club', 'other');
CREATE TYPE venue_sections_status AS ENUM ('excellent', 'good', 'standard', 'obstructed');
CREATE TYPE venue_seats_status AS ENUM ('standard', 'accessible', 'companion', 'obstructed_view', 'premium');
CREATE TYPE performers_status AS ENUM ('artist', 'band', 'team', 'speaker', 'company', 'other');
CREATE TYPE events_status AS ENUM ('single', 'tour', 'season', 'festival', 'conference');
CREATE TYPE performances_status AS ENUM ('scheduled', 'on_sale', 'sold_out', 'cancelled', 'postponed', 'completed');
CREATE TYPE customers_status AS ENUM ('male', 'female', 'other', 'prefer_not_to_say');
CREATE TYPE loyalty_members_status AS ENUM ('basic', 'silver', 'gold', 'platinum', 'vip');
CREATE TYPE promotional_codes_status AS ENUM ('percentage', 'fixed_amount');
CREATE TYPE bookings_status AS ENUM ('pending', 'processing', 'completed', 'failed', 'refunded');
CREATE TYPE tickets_status AS ENUM ('valid', 'used', 'cancelled', 'transferred', 'resold');
CREATE TYPE shopping_carts_status AS ENUM ('active', 'expired', 'converted', 'abandoned');
CREATE TYPE entry_scans_status AS ENUM ('success', 'duplicate', 'invalid', 'expired');
CREATE TYPE fraud_attempts_status AS ENUM ('duplicate_booking', 'invalid_ticket', 'bot_activity', 'payment_fraud', 'resale_violation');
CREATE TYPE resale_listings_status AS ENUM ('active', 'sold', 'expired', 'withdrawn');
CREATE TYPE resale_transactions_status AS ENUM ('pending', 'completed', 'cancelled', 'disputed');

DROP DATABASE IF EXISTS event_ticketing;
-- Create database (run as superuser)
-- CREATE DATABASE event_ticketing;
-- \c event_ticketing

SHOW DATABASES LIKE 'event_ticketing';
SELECT 'Event Ticketing database created successfully' AS status;
CREATE TABLE IF NOT EXISTS venues (
    venue_name VARCHAR(255) NOT NULL,
    venue_type venues_status NOT NULL,
    address_line1 VARCHAR(255) NOT NULL,
    address_line2 VARCHAR(255),
    city VARCHAR(100) NOT NULL,
    state_province VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100) NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    capacity INTEGER NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(255),
    website VARCHAR(255),
    parking_info TEXT,
    public_transport_info TEXT,
    accessibility_info TEXT,
    venue_rules TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS venue_sections (
    venue_id INTEGER NOT NULL,
    section_name VARCHAR(100) NOT NULL,
    section_type venue_sections_status NOT NULL,
    capacity INTEGER NOT NULL,
    rows_count INTEGER,
    default_price_tier VARCHAR(50),
    entry_gate VARCHAR(50),
    is_accessible BOOLEAN DEFAULT FALSE,
    view_quality venue_sections_status DEFAULT 'standard',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (venue_id, section_name)
);

ALTER TABLE venue_sections ADD CONSTRAINT fk_venue_sections_venue_id FOREIGN KEY (venue_id) REFERENCES venues(venue_id) ON DELETE CASCADE;
CREATE TABLE IF NOT EXISTS venue_rows (
    section_id INTEGER NOT NULL,
    row_number VARCHAR(10) NOT NULL,
    seats_count INTEGER NOT NULL,
    is_accessible BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (section_id, row_number)
);

ALTER TABLE venue_rows ADD CONSTRAINT fk_venue_rows_section_id FOREIGN KEY (section_id) REFERENCES venue_sections(section_id) ON DELETE CASCADE;
CREATE TABLE IF NOT EXISTS venue_seats (
    row_id INTEGER NOT NULL,
    seat_number VARCHAR(10) NOT NULL,
    seat_type venue_seats_status DEFAULT 'standard',
    x_coordinate INTEGER,
    is_aisle BOOLEAN DEFAULT FALSE,
    notes VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (row_id, seat_number)
);

ALTER TABLE venue_seats ADD CONSTRAINT fk_venue_seats_row_id FOREIGN KEY (row_id) REFERENCES venue_rows(row_id) ON DELETE CASCADE;
CREATE TABLE IF NOT EXISTS event_categories (
    category_name VARCHAR(100) NOT NULL,
    parent_category_id INTEGER,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (category_name)
);

ALTER TABLE event_categories ADD CONSTRAINT fk_event_categories_parent_category_id FOREIGN KEY (parent_category_id) REFERENCES event_categories(category_id);
CREATE TABLE IF NOT EXISTS performers (
    performer_name VARCHAR(255) NOT NULL,
    performer_type performers_status NOT NULL,
    genre VARCHAR(100),
    bio TEXT,
    image_url VARCHAR(500),
    website VARCHAR(255),
    social_media JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS events (
    event_name VARCHAR(255) NOT NULL,
    event_type events_status NOT NULL,
    category_id INTEGER,
    description TEXT,
    image_url VARCHAR(500),
    banner_url VARCHAR(500),
    age_restriction VARCHAR(50),
    duration_minutes INTEGER,
    organizer_name VARCHAR(255),
    organizer_contact VARCHAR(255),
    is_featured BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE events ADD CONSTRAINT fk_events_category_id FOREIGN KEY (category_id) REFERENCES event_categories(category_id);
CREATE TABLE IF NOT EXISTS performances (
    event_id BIGINT NOT NULL,
    venue_id INTEGER NOT NULL,
    performance_datetime TIMESTAMP NOT NULL,
    doors_open_datetime TIMESTAMP,
    performance_status performances_status DEFAULT 'scheduled',
    total_capacity INTEGER,
    available_capacity INTEGER,
    min_ticket_price DECIMAL(10, 2),
    max_ticket_price DECIMAL(10, 2),
    sales_start_datetime TIMESTAMP,
    sales_end_datetime TIMESTAMP,
    is_general_admission BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE performances ADD CONSTRAINT fk_performances_event_id FOREIGN KEY (event_id) REFERENCES events(event_id);
ALTER TABLE performances ADD CONSTRAINT fk_performances_venue_id FOREIGN KEY (venue_id) REFERENCES venues(venue_id);
CREATE TABLE IF NOT EXISTS event_performers (
    event_id BIGINT NOT NULL,
    performer_id INTEGER NOT NULL,
    billing_order INTEGER DEFAULT 1,
    is_headliner BOOLEAN DEFAULT FALSE,
    performance_fee DECIMAL(12, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (event_id, performer_id)
);

ALTER TABLE event_performers ADD CONSTRAINT fk_event_performers_event_id FOREIGN KEY (event_id) REFERENCES events(event_id);
ALTER TABLE event_performers ADD CONSTRAINT fk_event_performers_performer_id FOREIGN KEY (performer_id) REFERENCES performers(performer_id);
CREATE TABLE IF NOT EXISTS customers (
    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(20),
    date_of_birth DATE,
    gender customers_status,
    preferred_language VARCHAR(10) DEFAULT 'en',
    preferred_currency CHAR(3) DEFAULT 'USD',
    email_verified BOOLEAN DEFAULT FALSE,
    phone_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (email)
);

CREATE TABLE IF NOT EXISTS customer_preferences (
    customer_id BIGINT NOT NULL,
    favorite_venues JSONB,
    favorite_performers JSONB,
    preferred_categories JSONB,
    notification_events BOOLEAN DEFAULT TRUE,
    notification_offers BOOLEAN DEFAULT TRUE,
    notification_reminders BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (customer_id)
);

ALTER TABLE customer_preferences ADD CONSTRAINT fk_customer_preferences_customer_id FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE;
CREATE TABLE IF NOT EXISTS loyalty_members (
    customer_id BIGINT NOT NULL,
    membership_tier loyalty_members_status DEFAULT 'basic',
    points_balance INTEGER DEFAULT 0,
    lifetime_points INTEGER DEFAULT 0,
    join_date DATE NOT NULL,
    expiry_date DATE,
    perks JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (customer_id)
);

ALTER TABLE loyalty_members ADD CONSTRAINT fk_loyalty_members_customer_id FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE;
CREATE TABLE IF NOT EXISTS price_tiers (
    performance_id BIGINT NOT NULL,
    tier_name VARCHAR(100) NOT NULL,
    base_price DECIMAL(10, 2) NOT NULL,
    service_fee DECIMAL(10, 2) DEFAULT 0.00,
    facility_fee DECIMAL(10, 2) DEFAULT 0.00,
    tax_rate DECIMAL(5, 4) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (performance_id, tier_name)
);

ALTER TABLE price_tiers ADD CONSTRAINT fk_price_tiers_performance_id FOREIGN KEY (performance_id) REFERENCES performances(performance_id) ON DELETE CASCADE;
CREATE TABLE IF NOT EXISTS section_pricing (
    performance_id BIGINT NOT NULL,
    section_id INTEGER NOT NULL,
    price_tier_id INTEGER NOT NULL,
    current_price DECIMAL(10, 2) NOT NULL,
    original_price DECIMAL(10, 2),
    min_price DECIMAL(10, 2),
    max_price DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (performance_id, section_id)
);

ALTER TABLE section_pricing ADD CONSTRAINT fk_section_pricing_performance_id FOREIGN KEY (performance_id) REFERENCES performances(performance_id) ON DELETE CASCADE;
ALTER TABLE section_pricing ADD CONSTRAINT fk_section_pricing_section_id FOREIGN KEY (section_id) REFERENCES venue_sections(section_id);
ALTER TABLE section_pricing ADD CONSTRAINT fk_section_pricing_price_tier_id FOREIGN KEY (price_tier_id) REFERENCES price_tiers(price_tier_id);
CREATE TABLE IF NOT EXISTS promotional_codes (
    promo_code VARCHAR(50) NOT NULL,
    description VARCHAR(255),
    discount_type promotional_codes_status NOT NULL,
    discount_value DECIMAL(10, 2) NOT NULL,
    min_purchase_amount DECIMAL(10, 2),
    max_discount_amount DECIMAL(10, 2),
    valid_from TIMESTAMP NOT NULL,
    valid_until TIMESTAMP NOT NULL,
    usage_limit INTEGER,
    usage_count INTEGER DEFAULT 0,
    applicable_performances JSONB,
    applicable_sections JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (promo_code)
);

CREATE TABLE IF NOT EXISTS bookings (
    booking_reference VARCHAR(20) NOT NULL,
    customer_id BIGINT NOT NULL,
    performance_id BIGINT NOT NULL,
    booking_status bookings_status DEFAULT 'pending',
    total_amount DECIMAL(10, 2) NOT NULL,
    discount_amount DECIMAL(10, 2) DEFAULT 0.00,
    tax_amount DECIMAL(10, 2) DEFAULT 0.00,
    service_fee_amount DECIMAL(10, 2) DEFAULT 0.00,
    payment_method VARCHAR(50),
    payment_status bookings_status DEFAULT 'pending',
    promo_code_used VARCHAR(50),
    booking_datetime TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    confirmation_sent BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (booking_reference)
);

ALTER TABLE bookings ADD CONSTRAINT fk_bookings_customer_id FOREIGN KEY (customer_id) REFERENCES customers(customer_id);
ALTER TABLE bookings ADD CONSTRAINT fk_bookings_performance_id FOREIGN KEY (performance_id) REFERENCES performances(performance_id);
CREATE TABLE IF NOT EXISTS tickets (
    booking_id BIGINT NOT NULL,
    seat_id BIGINT,
    ticket_status tickets_status DEFAULT 'valid',
    price_paid DECIMAL(10, 2) NOT NULL,
    barcode VARCHAR(100),
    qr_code VARCHAR(255),
    issue_datetime TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    used_datetime TIMESTAMP NULL,
    entry_gate VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (ticket_number)
);

ALTER TABLE tickets ADD CONSTRAINT fk_tickets_booking_id FOREIGN KEY (booking_id) REFERENCES bookings(booking_id);
ALTER TABLE tickets ADD CONSTRAINT fk_tickets_seat_id FOREIGN KEY (seat_id) REFERENCES venue_seats(seat_id);
CREATE TABLE IF NOT EXISTS ticket_holds (
    session_id VARCHAR(100) NOT NULL,
    customer_id BIGINT,
    performance_id BIGINT NOT NULL,
    seat_id BIGINT NOT NULL,
    hold_expiry TIMESTAMP NOT NULL,
    is_released BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (performance_id, seat_id)
);

ALTER TABLE ticket_holds ADD CONSTRAINT fk_ticket_holds_customer_id FOREIGN KEY (customer_id) REFERENCES customers(customer_id);
ALTER TABLE ticket_holds ADD CONSTRAINT fk_ticket_holds_performance_id FOREIGN KEY (performance_id) REFERENCES performances(performance_id);
ALTER TABLE ticket_holds ADD CONSTRAINT fk_ticket_holds_seat_id FOREIGN KEY (seat_id) REFERENCES venue_seats(seat_id);
CREATE TABLE IF NOT EXISTS shopping_carts (
    session_id VARCHAR(100) NOT NULL,
    customer_id BIGINT,
    performance_id BIGINT NOT NULL,
    cart_status shopping_carts_status DEFAULT 'active',
    expiry_datetime TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (session_id)
);

ALTER TABLE shopping_carts ADD CONSTRAINT fk_shopping_carts_customer_id FOREIGN KEY (customer_id) REFERENCES customers(customer_id);
ALTER TABLE shopping_carts ADD CONSTRAINT fk_shopping_carts_performance_id FOREIGN KEY (performance_id) REFERENCES performances(performance_id);
CREATE TABLE IF NOT EXISTS cart_items (
    cart_id BIGINT NOT NULL,
    seat_id BIGINT,
    price_tier_id INTEGER NOT NULL,
    quantity INTEGER DEFAULT 1,
    unit_price DECIMAL(10, 2) NOT NULL,
    service_fee DECIMAL(10, 2) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (cart_id, seat_id)
);

ALTER TABLE cart_items ADD CONSTRAINT fk_cart_items_cart_id FOREIGN KEY (cart_id) REFERENCES shopping_carts(cart_id) ON DELETE CASCADE;
ALTER TABLE cart_items ADD CONSTRAINT fk_cart_items_seat_id FOREIGN KEY (seat_id) REFERENCES venue_seats(seat_id);
ALTER TABLE cart_items ADD CONSTRAINT fk_cart_items_price_tier_id FOREIGN KEY (price_tier_id) REFERENCES price_tiers(price_tier_id);
CREATE TABLE IF NOT EXISTS entry_scans (
    ticket_id BIGINT NOT NULL,
    scan_datetime TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    entry_gate VARCHAR(50),
    scanner_device_id VARCHAR(100),
    scan_result entry_scans_status NOT NULL,
    notes VARCHAR(255)
);

ALTER TABLE entry_scans ADD CONSTRAINT fk_entry_scans_ticket_id FOREIGN KEY (ticket_id) REFERENCES tickets(ticket_id);
CREATE TABLE IF NOT EXISTS fraud_attempts (
    attempt_type fraud_attempts_status NOT NULL,
    customer_id BIGINT,
    ip_address VARCHAR(45),
    user_agent TEXT,
    details JSONB,
    action_taken VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE fraud_attempts ADD CONSTRAINT fk_fraud_attempts_customer_id FOREIGN KEY (customer_id) REFERENCES customers(customer_id);
CREATE TABLE IF NOT EXISTS resale_listings (
    ticket_id BIGINT NOT NULL,
    seller_customer_id BIGINT NOT NULL,
    listing_price DECIMAL(10, 2) NOT NULL,
    min_price DECIMAL(10, 2),
    listing_status resale_listings_status DEFAULT 'active',
    listed_datetime TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sold_datetime TIMESTAMP NULL,
    expiry_datetime TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE resale_listings ADD CONSTRAINT fk_resale_listings_ticket_id FOREIGN KEY (ticket_id) REFERENCES tickets(ticket_id);
ALTER TABLE resale_listings ADD CONSTRAINT fk_resale_listings_seller_customer_id FOREIGN KEY (seller_customer_id) REFERENCES customers(customer_id);
CREATE TABLE IF NOT EXISTS resale_transactions (
    listing_id BIGINT NOT NULL,
    buyer_customer_id BIGINT NOT NULL,
    sale_price DECIMAL(10, 2) NOT NULL,
    platform_fee DECIMAL(10, 2) DEFAULT 0.00,
    seller_payout DECIMAL(10, 2) NOT NULL,
    transaction_status resale_transactions_status DEFAULT 'pending',
    transaction_datetime TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE resale_transactions ADD CONSTRAINT fk_resale_transactions_listing_id FOREIGN KEY (listing_id) REFERENCES resale_listings(listing_id);
ALTER TABLE resale_transactions ADD CONSTRAINT fk_resale_transactions_buyer_customer_id FOREIGN KEY (buyer_customer_id) REFERENCES customers(customer_id);
CREATE TABLE IF NOT EXISTS sales_metrics (
    performance_id BIGINT NOT NULL,
    metric_date DATE NOT NULL,
    tickets_sold INTEGER DEFAULT 0,
    gross_revenue DECIMAL(12, 2) DEFAULT 0.00,
    service_fees DECIMAL(10, 2) DEFAULT 0.00,
    average_ticket_price DECIMAL(10, 2),
    conversion_rate DECIMAL(5, 4),
    cart_abandonment_rate DECIMAL(5, 4),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (performance_id, metric_date)
);

ALTER TABLE sales_metrics ADD CONSTRAINT fk_sales_metrics_performance_id FOREIGN KEY (performance_id) REFERENCES performances(performance_id);
CREATE TABLE IF NOT EXISTS venue_utilization (
    venue_id INTEGER NOT NULL,
    performance_id BIGINT NOT NULL,
    total_capacity INTEGER NOT NULL,
    tickets_sold INTEGER DEFAULT 0,
    utilization_percentage DECIMAL(5, 2),
    revenue_per_seat DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE venue_utilization ADD CONSTRAINT fk_venue_utilization_venue_id FOREIGN KEY (venue_id) REFERENCES venues(venue_id);
ALTER TABLE venue_utilization ADD CONSTRAINT fk_venue_utilization_performance_id FOREIGN KEY (performance_id) REFERENCES performances(performance_id);
SHOW TABLES;
SELECT 'Event Ticketing tables created successfully' AS status;
-- Indexes
