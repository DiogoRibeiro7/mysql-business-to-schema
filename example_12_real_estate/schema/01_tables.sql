-- =========================================
-- Real Estate Platform - Core Tables
-- =========================================

USE real_estate;

-- =========================================
-- 1. LOCATION TABLES
-- =========================================

CREATE TABLE IF NOT EXISTS countries (
    country_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    country_code CHAR(2) NOT NULL,
    country_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE INDEX idx_country_code (country_code)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS states_provinces (
    state_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    country_id INT UNSIGNED NOT NULL,
    state_code VARCHAR(10) NOT NULL,
    state_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (country_id) REFERENCES countries(country_id),
    UNIQUE INDEX idx_state_code (country_id, state_code),
    INDEX idx_state_name (state_name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS cities (
    city_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    state_id INT UNSIGNED NOT NULL,
    city_name VARCHAR(100) NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    population INT UNSIGNED,
    median_income DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (state_id) REFERENCES states_provinces(state_id),
    INDEX idx_city_name (city_name),
    INDEX idx_state_city (state_id, city_name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS zip_codes (
    zip_code VARCHAR(10) PRIMARY KEY,
    city_id INT UNSIGNED NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    timezone VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (city_id) REFERENCES cities(city_id),
    INDEX idx_city_zip (city_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS neighborhoods (
    neighborhood_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    city_id INT UNSIGNED NOT NULL,
    neighborhood_name VARCHAR(100) NOT NULL,
    boundary_polygon POLYGON NOT NULL,
    center_point POINT NOT NULL,
    median_home_price DECIMAL(12, 2),
    median_rent DECIMAL(10, 2),
    walk_score TINYINT,
    transit_score TINYINT,
    crime_rate DECIMAL(5, 2),
    school_rating DECIMAL(3, 1),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (city_id) REFERENCES cities(city_id),
    INDEX idx_neighborhood_name (neighborhood_name),
    SPATIAL INDEX idx_boundary (boundary_polygon),
    SPATIAL INDEX idx_center (center_point)
) ENGINE=InnoDB;

-- =========================================
-- 2. PROPERTY TABLES
-- =========================================

CREATE TABLE IF NOT EXISTS property_types (
    type_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    parent_type_id INT UNSIGNED,
    type_name VARCHAR(50) NOT NULL,
    type_category ENUM('residential', 'commercial', 'land', 'industrial', 'special') NOT NULL,
    description TEXT,
    FOREIGN KEY (parent_type_id) REFERENCES property_types(type_id),
    INDEX idx_category (type_category),
    INDEX idx_parent (parent_type_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS properties (
    property_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    property_type_id INT UNSIGNED NOT NULL,
    address_line1 VARCHAR(255) NOT NULL,
    address_line2 VARCHAR(255),
    city_id INT UNSIGNED NOT NULL,
    state_id INT UNSIGNED NOT NULL,
    zip_code VARCHAR(10) NOT NULL,
    neighborhood_id INT UNSIGNED,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    location_point POINT NOT NULL,
    parcel_number VARCHAR(50),
    legal_description TEXT,
    year_built YEAR,
    lot_size_sqft INT UNSIGNED,
    building_size_sqft INT UNSIGNED,
    bedrooms TINYINT UNSIGNED,
    bathrooms DECIMAL(3, 1),
    parking_spaces TINYINT UNSIGNED,
    garage_spaces TINYINT UNSIGNED,
    stories TINYINT UNSIGNED,
    construction_type VARCHAR(50),
    roof_type VARCHAR(50),
    heating_type VARCHAR(50),
    cooling_type VARCHAR(50),
    zoning VARCHAR(50),
    hoa_fee DECIMAL(8, 2),
    tax_assessed_value DECIMAL(12, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (property_type_id) REFERENCES property_types(type_id),
    FOREIGN KEY (city_id) REFERENCES cities(city_id),
    FOREIGN KEY (state_id) REFERENCES states_provinces(state_id),
    FOREIGN KEY (neighborhood_id) REFERENCES neighborhoods(neighborhood_id),
    INDEX idx_type (property_type_id),
    INDEX idx_location (city_id, state_id, zip_code),
    INDEX idx_size (building_size_sqft),
    INDEX idx_bedrooms (bedrooms),
    INDEX idx_year_built (year_built),
    SPATIAL INDEX idx_location_point (location_point),
    FULLTEXT INDEX ft_address (address_line1, address_line2)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS property_features (
    feature_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    property_id BIGINT UNSIGNED NOT NULL,
    feature_category ENUM('interior', 'exterior', 'amenity', 'utility', 'safety', 'green') NOT NULL,
    feature_name VARCHAR(100) NOT NULL,
    feature_value VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (property_id) REFERENCES properties(property_id) ON DELETE CASCADE,
    INDEX idx_property_features (property_id),
    INDEX idx_feature_category (feature_category, feature_name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS property_rooms (
    room_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    property_id BIGINT UNSIGNED NOT NULL,
    room_type VARCHAR(50) NOT NULL,
    room_level VARCHAR(50),
    length_ft DECIMAL(5, 2),
    width_ft DECIMAL(5, 2),
    description TEXT,
    FOREIGN KEY (property_id) REFERENCES properties(property_id) ON DELETE CASCADE,
    INDEX idx_property_rooms (property_id)
) ENGINE=InnoDB;

-- =========================================
-- 3. AGENT & BROKERAGE TABLES
-- =========================================

CREATE TABLE IF NOT EXISTS brokerages (
    brokerage_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    brokerage_name VARCHAR(255) NOT NULL,
    license_number VARCHAR(50) NOT NULL,
    address VARCHAR(255),
    city_id INT UNSIGNED,
    state_id INT UNSIGNED,
    zip_code VARCHAR(10),
    phone VARCHAR(20),
    email VARCHAR(255),
    website VARCHAR(255),
    established_date DATE,
    total_agents INT UNSIGNED DEFAULT 0,
    active_listings INT UNSIGNED DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (city_id) REFERENCES cities(city_id),
    FOREIGN KEY (state_id) REFERENCES states_provinces(state_id),
    UNIQUE INDEX idx_license (license_number),
    INDEX idx_brokerage_name (brokerage_name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS agents (
    agent_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    brokerage_id INT UNSIGNED,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    mobile_phone VARCHAR(20),
    license_number VARCHAR(50) NOT NULL,
    license_state_id INT UNSIGNED NOT NULL,
    license_expiry_date DATE,
    specializations JSON,
    bio TEXT,
    profile_photo_url VARCHAR(500),
    years_experience TINYINT UNSIGNED,
    total_sales_volume DECIMAL(15, 2),
    total_transactions INT UNSIGNED DEFAULT 0,
    avg_days_on_market INT UNSIGNED,
    rating DECIMAL(3, 2),
    is_active BOOLEAN DEFAULT TRUE,
    joined_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (brokerage_id) REFERENCES brokerages(brokerage_id),
    FOREIGN KEY (license_state_id) REFERENCES states_provinces(state_id),
    UNIQUE INDEX idx_email (email),
    UNIQUE INDEX idx_license (license_number),
    INDEX idx_brokerage (brokerage_id),
    INDEX idx_name (last_name, first_name),
    INDEX idx_rating (rating DESC)
) ENGINE=InnoDB;

-- =========================================
-- 4. USER TABLES
-- =========================================

CREATE TABLE IF NOT EXISTS users (
    user_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(20),
    user_type ENUM('buyer', 'seller', 'investor', 'renter', 'agent', 'admin') NOT NULL,
    email_verified BOOLEAN DEFAULT FALSE,
    phone_verified BOOLEAN DEFAULT FALSE,
    profile_photo_url VARCHAR(500),
    preferred_contact ENUM('email', 'phone', 'text') DEFAULT 'email',
    last_login TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE INDEX idx_user_email (email),
    INDEX idx_user_type (user_type),
    INDEX idx_last_login (last_login DESC)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS user_preferences (
    preference_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    min_price DECIMAL(12, 2),
    max_price DECIMAL(12, 2),
    min_bedrooms TINYINT UNSIGNED,
    min_bathrooms DECIMAL(3, 1),
    min_sqft INT UNSIGNED,
    max_sqft INT UNSIGNED,
    property_types JSON,
    preferred_cities JSON,
    preferred_neighborhoods JSON,
    must_have_features JSON,
    nice_to_have_features JSON,
    max_hoa_fee DECIMAL(8, 2),
    school_rating_min DECIMAL(3, 1),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    UNIQUE INDEX idx_user_pref (user_id)
) ENGINE=InnoDB;

-- =========================================
-- 5. LISTING TABLES
-- =========================================

CREATE TABLE IF NOT EXISTS listings (
    listing_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    property_id BIGINT UNSIGNED NOT NULL,
    listing_agent_id INT UNSIGNED NOT NULL,
    co_listing_agent_id INT UNSIGNED,
    listing_type ENUM('for_sale', 'for_rent', 'for_lease', 'auction') NOT NULL,
    status ENUM('coming_soon', 'active', 'pending', 'contingent', 'sold', 'expired', 'withdrawn', 'cancelled') NOT NULL,
    list_price DECIMAL(12, 2) NOT NULL,
    original_price DECIMAL(12, 2),
    price_per_sqft DECIMAL(8, 2),
    listing_date DATE NOT NULL,
    expiry_date DATE,
    days_on_market INT UNSIGNED DEFAULT 0,
    title VARCHAR(255),
    description TEXT,
    virtual_tour_url VARCHAR(500),
    video_url VARCHAR(500),
    commission_buyer_agent DECIMAL(5, 2),
    commission_listing_agent DECIMAL(5, 2),
    showing_instructions TEXT,
    mls_number VARCHAR(50),
    is_featured BOOLEAN DEFAULT FALSE,
    view_count INT UNSIGNED DEFAULT 0,
    inquiry_count INT UNSIGNED DEFAULT 0,
    showing_count INT UNSIGNED DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (property_id) REFERENCES properties(property_id),
    FOREIGN KEY (listing_agent_id) REFERENCES agents(agent_id),
    FOREIGN KEY (co_listing_agent_id) REFERENCES agents(agent_id),
    INDEX idx_property (property_id),
    INDEX idx_status (status, listing_type),
    INDEX idx_price (list_price),
    INDEX idx_listing_date (listing_date DESC),
    INDEX idx_agent (listing_agent_id),
    INDEX idx_mls (mls_number),
    FULLTEXT INDEX ft_listing (title, description)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS listing_status_history (
    history_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    listing_id BIGINT UNSIGNED NOT NULL,
    status ENUM('coming_soon', 'active', 'pending', 'contingent', 'sold', 'expired', 'withdrawn', 'cancelled') NOT NULL,
    changed_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by_user_id BIGINT UNSIGNED,
    notes TEXT,
    FOREIGN KEY (listing_id) REFERENCES listings(listing_id) ON DELETE CASCADE,
    FOREIGN KEY (changed_by_user_id) REFERENCES users(user_id),
    INDEX idx_listing_history (listing_id, changed_date DESC)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS price_changes (
    change_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    listing_id BIGINT UNSIGNED NOT NULL,
    old_price DECIMAL(12, 2) NOT NULL,
    new_price DECIMAL(12, 2) NOT NULL,
    change_amount DECIMAL(12, 2) GENERATED ALWAYS AS (new_price - old_price) STORED,
    change_percentage DECIMAL(5, 2) GENERATED ALWAYS AS ((new_price - old_price) / old_price * 100) STORED,
    change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reason TEXT,
    FOREIGN KEY (listing_id) REFERENCES listings(listing_id) ON DELETE CASCADE,
    INDEX idx_listing_price_changes (listing_id, change_date DESC),
    INDEX idx_change_date (change_date DESC)
) ENGINE=InnoDB;

-- =========================================
-- 6. PROPERTY MEDIA TABLES
-- =========================================

CREATE TABLE IF NOT EXISTS property_photos (
    photo_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    property_id BIGINT UNSIGNED NOT NULL,
    photo_url VARCHAR(500) NOT NULL,
    thumbnail_url VARCHAR(500),
    caption VARCHAR(255),
    photo_type ENUM('exterior', 'interior', 'aerial', 'streetview', 'floorplan', 'other') DEFAULT 'other',
    display_order INT UNSIGNED DEFAULT 0,
    is_primary BOOLEAN DEFAULT FALSE,
    width INT UNSIGNED,
    height INT UNSIGNED,
    file_size INT UNSIGNED,
    uploaded_by_user_id BIGINT UNSIGNED,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (property_id) REFERENCES properties(property_id) ON DELETE CASCADE,
    FOREIGN KEY (uploaded_by_user_id) REFERENCES users(user_id),
    INDEX idx_property_photos (property_id, display_order),
    INDEX idx_primary_photo (property_id, is_primary)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS virtual_tours (
    tour_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    property_id BIGINT UNSIGNED NOT NULL,
    tour_type ENUM('360', 'video', 'matterport', 'other') NOT NULL,
    tour_url VARCHAR(500) NOT NULL,
    embed_code TEXT,
    provider VARCHAR(100),
    view_count INT UNSIGNED DEFAULT 0,
    avg_view_duration INT UNSIGNED,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (property_id) REFERENCES properties(property_id) ON DELETE CASCADE,
    UNIQUE INDEX idx_property_tour (property_id)
) ENGINE=InnoDB;

-- =========================================
-- 7. SAVED SEARCHES & FAVORITES
-- =========================================

CREATE TABLE IF NOT EXISTS saved_searches (
    search_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    search_name VARCHAR(100),
    search_criteria JSON NOT NULL,
    frequency ENUM('instant', 'daily', 'weekly', 'monthly') DEFAULT 'daily',
    last_run TIMESTAMP NULL,
    last_match_count INT UNSIGNED DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_user_searches (user_id, is_active),
    INDEX idx_frequency (frequency, last_run)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS saved_properties (
    saved_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    property_id BIGINT UNSIGNED NOT NULL,
    listing_id BIGINT UNSIGNED,
    notes TEXT,
    rating TINYINT,
    saved_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (property_id) REFERENCES properties(property_id),
    FOREIGN KEY (listing_id) REFERENCES listings(listing_id),
    UNIQUE INDEX idx_user_property (user_id, property_id),
    INDEX idx_saved_date (saved_date DESC)
) ENGINE=InnoDB;

-- =========================================
-- 8. SHOWING & APPOINTMENTS
-- =========================================

CREATE TABLE IF NOT EXISTS showing_requests (
    request_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    listing_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    agent_id INT UNSIGNED,
    preferred_date DATE NOT NULL,
    preferred_time_start TIME,
    preferred_time_end TIME,
    alternate_date DATE,
    status ENUM('pending', 'confirmed', 'rescheduled', 'cancelled', 'completed') DEFAULT 'pending',
    message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (listing_id) REFERENCES listings(listing_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (agent_id) REFERENCES agents(agent_id),
    INDEX idx_listing_showings (listing_id, preferred_date),
    INDEX idx_user_showings (user_id, status),
    INDEX idx_date (preferred_date)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS open_houses (
    open_house_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    listing_id BIGINT UNSIGNED NOT NULL,
    start_datetime DATETIME NOT NULL,
    end_datetime DATETIME NOT NULL,
    host_agent_id INT UNSIGNED NOT NULL,
    registration_required BOOLEAN DEFAULT FALSE,
    refreshments BOOLEAN DEFAULT FALSE,
    notes TEXT,
    attendee_count INT UNSIGNED DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (listing_id) REFERENCES listings(listing_id),
    FOREIGN KEY (host_agent_id) REFERENCES agents(agent_id),
    INDEX idx_listing_oh (listing_id),
    INDEX idx_datetime (start_datetime)
) ENGINE=InnoDB;

-- =========================================
-- 9. OFFERS & TRANSACTIONS
-- =========================================

CREATE TABLE IF NOT EXISTS offers (
    offer_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    listing_id BIGINT UNSIGNED NOT NULL,
    buyer_user_id BIGINT UNSIGNED,
    buyer_agent_id INT UNSIGNED,
    offer_amount DECIMAL(12, 2) NOT NULL,
    offer_type ENUM('standard', 'cash', 'contingent', 'backup') DEFAULT 'standard',
    status ENUM('draft', 'submitted', 'under_review', 'countered', 'accepted', 'rejected', 'withdrawn', 'expired') NOT NULL,
    earnest_money DECIMAL(10, 2),
    down_payment_amount DECIMAL(12, 2),
    down_payment_percentage DECIMAL(5, 2),
    financing_type ENUM('conventional', 'fha', 'va', 'usda', 'cash', 'other'),
    pre_approval_letter BOOLEAN DEFAULT FALSE,
    contingencies JSON,
    closing_date DATE,
    expiry_datetime DATETIME,
    submitted_at TIMESTAMP NULL,
    response_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (listing_id) REFERENCES listings(listing_id),
    FOREIGN KEY (buyer_user_id) REFERENCES users(user_id),
    FOREIGN KEY (buyer_agent_id) REFERENCES agents(agent_id),
    INDEX idx_listing_offers (listing_id, status),
    INDEX idx_buyer (buyer_user_id),
    INDEX idx_status (status),
    INDEX idx_submitted (submitted_at DESC)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS transactions (
    transaction_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    listing_id BIGINT UNSIGNED NOT NULL,
    accepted_offer_id BIGINT UNSIGNED NOT NULL,
    sale_price DECIMAL(12, 2) NOT NULL,
    closing_date DATE,
    escrow_company VARCHAR(255),
    escrow_number VARCHAR(100),
    title_company VARCHAR(255),
    transaction_status ENUM('pending', 'in_escrow', 'closed', 'cancelled') DEFAULT 'pending',
    commission_paid_listing DECIMAL(10, 2),
    commission_paid_buyer DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (listing_id) REFERENCES listings(listing_id),
    FOREIGN KEY (accepted_offer_id) REFERENCES offers(offer_id),
    INDEX idx_listing_transaction (listing_id),
    INDEX idx_closing_date (closing_date),
    INDEX idx_status (transaction_status)
) ENGINE=InnoDB;

-- =========================================
-- 10. MARKET DATA & ANALYTICS
-- =========================================

CREATE TABLE IF NOT EXISTS market_trends (
    trend_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    neighborhood_id INT UNSIGNED,
    city_id INT UNSIGNED,
    state_id INT UNSIGNED,
    trend_date DATE NOT NULL,
    property_type VARCHAR(50),
    median_list_price DECIMAL(12, 2),
    median_sold_price DECIMAL(12, 2),
    avg_price_per_sqft DECIMAL(8, 2),
    avg_days_on_market INT UNSIGNED,
    inventory_count INT UNSIGNED,
    new_listings_count INT UNSIGNED,
    sold_count INT UNSIGNED,
    pending_count INT UNSIGNED,
    price_reduced_count INT UNSIGNED,
    months_of_supply DECIMAL(4, 2),
    sale_to_list_ratio DECIMAL(5, 4),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (neighborhood_id) REFERENCES neighborhoods(neighborhood_id),
    FOREIGN KEY (city_id) REFERENCES cities(city_id),
    FOREIGN KEY (state_id) REFERENCES states_provinces(state_id),
    INDEX idx_location_date (neighborhood_id, trend_date DESC),
    INDEX idx_city_date (city_id, trend_date DESC),
    INDEX idx_trend_date (trend_date DESC)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS comparable_sales (
    comp_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    subject_property_id BIGINT UNSIGNED NOT NULL,
    comp_property_id BIGINT UNSIGNED NOT NULL,
    sale_date DATE NOT NULL,
    sale_price DECIMAL(12, 2) NOT NULL,
    price_per_sqft DECIMAL(8, 2),
    distance_miles DECIMAL(5, 2),
    similarity_score DECIMAL(3, 2),
    adjustments JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (subject_property_id) REFERENCES properties(property_id),
    FOREIGN KEY (comp_property_id) REFERENCES properties(property_id),
    INDEX idx_subject (subject_property_id),
    INDEX idx_sale_date (sale_date DESC)
) ENGINE=InnoDB;

-- =========================================
-- 11. SCHOOLS & AMENITIES
-- =========================================

CREATE TABLE IF NOT EXISTS school_districts (
    district_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    district_name VARCHAR(255) NOT NULL,
    district_type ENUM('elementary', 'middle', 'high', 'unified') NOT NULL,
    state_id INT UNSIGNED NOT NULL,
    boundary_polygon POLYGON NOT NULL,
    website VARCHAR(255),
    rating DECIMAL(3, 1),
    total_schools INT UNSIGNED,
    total_students INT UNSIGNED,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (state_id) REFERENCES states_provinces(state_id),
    INDEX idx_district_name (district_name),
    SPATIAL INDEX idx_district_boundary (boundary_polygon)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS schools (
    school_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    district_id INT UNSIGNED NOT NULL,
    school_name VARCHAR(255) NOT NULL,
    school_type ENUM('elementary', 'middle', 'high', 'k8', 'k12') NOT NULL,
    address VARCHAR(255),
    city_id INT UNSIGNED,
    zip_code VARCHAR(10),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    location_point POINT NOT NULL,
    grade_range VARCHAR(20),
    enrollment INT UNSIGNED,
    student_teacher_ratio DECIMAL(4, 1),
    rating DECIMAL(3, 1),
    test_scores JSON,
    website VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (district_id) REFERENCES school_districts(district_id),
    FOREIGN KEY (city_id) REFERENCES cities(city_id),
    INDEX idx_school_name (school_name),
    INDEX idx_district_schools (district_id),
    INDEX idx_rating (rating DESC),
    SPATIAL INDEX idx_school_location (location_point)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS property_schools (
    property_school_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    property_id BIGINT UNSIGNED NOT NULL,
    school_id INT UNSIGNED NOT NULL,
    school_type ENUM('assigned', 'nearby') NOT NULL,
    distance_miles DECIMAL(4, 2),
    FOREIGN KEY (property_id) REFERENCES properties(property_id) ON DELETE CASCADE,
    FOREIGN KEY (school_id) REFERENCES schools(school_id),
    UNIQUE INDEX idx_property_school (property_id, school_id),
    INDEX idx_property_schools (property_id)
) ENGINE=InnoDB;

-- =========================================
-- Show tables created
-- =========================================
SHOW TABLES;
SELECT 'Real Estate tables created successfully' AS status;
