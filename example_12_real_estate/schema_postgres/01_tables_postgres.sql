-- PostgreSQL Schema
-- Converted from MySQL on 2026-02-17T23:11:17.381445
-- Generator: MySQL to PostgreSQL Converter

-- Enum Types
CREATE TYPE property_types_status AS ENUM ('residential', 'commercial', 'land', 'industrial', 'special');
CREATE TYPE property_features_status AS ENUM ('interior', 'exterior', 'amenity', 'utility', 'safety', 'green');
CREATE TYPE users_status AS ENUM ('email', 'phone', 'text');
CREATE TYPE listings_status AS ENUM ('coming_soon', 'active', 'pending', 'contingent', 'sold', 'expired', 'withdrawn', 'cancelled');
CREATE TYPE listing_status_history_status AS ENUM ('coming_soon', 'active', 'pending', 'contingent', 'sold', 'expired', 'withdrawn', 'cancelled');
CREATE TYPE property_photos_status AS ENUM ('exterior', 'interior', 'aerial', 'streetview', 'floorplan', 'other');
CREATE TYPE virtual_tours_status AS ENUM ('360', 'video', 'matterport', 'other');
CREATE TYPE saved_searches_status AS ENUM ('instant', 'daily', 'weekly', 'monthly');
CREATE TYPE showing_requests_status AS ENUM ('pending', 'confirmed', 'rescheduled', 'cancelled', 'completed');
CREATE TYPE offers_status AS ENUM ('conventional', 'fha', 'va', 'usda', 'cash', 'other');
CREATE TYPE transactions_status AS ENUM ('pending', 'in_escrow', 'closed', 'cancelled');
CREATE TYPE school_districts_status AS ENUM ('elementary', 'middle', 'high', 'unified');
CREATE TYPE schools_status AS ENUM ('elementary', 'middle', 'high', 'k8', 'k12');
CREATE TYPE property_schools_status AS ENUM ('assigned', 'nearby');

DROP DATABASE IF EXISTS real_estate;
-- Create database (run as superuser)
-- CREATE DATABASE real_estate;
-- \c real_estate

SHOW DATABASES LIKE 'real_estate';
SELECT 'Real Estate database created successfully' AS status;
CREATE TABLE IF NOT EXISTS countries (
    country_code CHAR(2) NOT NULL,
    country_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (country_code)
);

CREATE TABLE IF NOT EXISTS states_provinces (
    country_id INTEGER NOT NULL,
    state_code VARCHAR(10) NOT NULL,
    state_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (country_id, state_code)
);

ALTER TABLE states_provinces ADD CONSTRAINT fk_states_provinces_country_id FOREIGN KEY (country_id) REFERENCES countries(country_id);
CREATE TABLE IF NOT EXISTS cities (
    state_id INTEGER NOT NULL,
    city_name VARCHAR(100) NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    population INTEGER,
    median_income DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE cities ADD CONSTRAINT fk_cities_state_id FOREIGN KEY (state_id) REFERENCES states_provinces(state_id);
CREATE TABLE IF NOT EXISTS zip_codes (
    city_id INTEGER NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    timezone VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE zip_codes ADD CONSTRAINT fk_zip_codes_city_id FOREIGN KEY (city_id) REFERENCES cities(city_id);
CREATE TABLE IF NOT EXISTS neighborhoods (
    city_id INTEGER NOT NULL,
    neighborhood_name VARCHAR(100) NOT NULL,
    boundary_polygon TEXT,
    center_point TEXT,
    median_home_price DECIMAL(12, 2),
    median_rent DECIMAL(10, 2),
    walk_score SMALLINT,
    transit_score SMALLINT,
    crime_rate DECIMAL(5, 2),
    school_rating DECIMAL(3, 1),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE neighborhoods ADD CONSTRAINT fk_neighborhoods_city_id FOREIGN KEY (city_id) REFERENCES cities(city_id);
CREATE TABLE IF NOT EXISTS property_types (
    parent_type_id INTEGER,
    type_name VARCHAR(50) NOT NULL,
    type_category property_types_status NOT NULL,
    description TEXT
);

ALTER TABLE property_types ADD CONSTRAINT fk_property_types_parent_type_id FOREIGN KEY (parent_type_id) REFERENCES property_types(type_id);
CREATE TABLE IF NOT EXISTS properties (
    property_type_id INTEGER NOT NULL,
    address_line1 VARCHAR(255) NOT NULL,
    address_line2 VARCHAR(255),
    city_id INTEGER NOT NULL,
    state_id INTEGER NOT NULL,
    zip_code VARCHAR(10) NOT NULL,
    neighborhood_id INTEGER,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    location_point TEXT NOT NULL,
    parcel_number VARCHAR(50),
    legal_description TEXT,
    year_built INTEGER,
    lot_size_sqft INTEGER,
    building_size_sqft INTEGER,
    bedrooms SMALLINT,
    bathrooms DECIMAL(3, 1),
    parking_spaces SMALLINT,
    garage_spaces SMALLINT,
    stories SMALLINT,
    construction_type VARCHAR(50),
    roof_type VARCHAR(50),
    heating_type VARCHAR(50),
    cooling_type VARCHAR(50),
    zoning VARCHAR(50),
    hoa_fee DECIMAL(8, 2),
    tax_assessed_value DECIMAL(12, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE properties ADD CONSTRAINT fk_properties_property_type_id FOREIGN KEY (property_type_id) REFERENCES property_types(type_id);
ALTER TABLE properties ADD CONSTRAINT fk_properties_city_id FOREIGN KEY (city_id) REFERENCES cities(city_id);
ALTER TABLE properties ADD CONSTRAINT fk_properties_state_id FOREIGN KEY (state_id) REFERENCES states_provinces(state_id);
ALTER TABLE properties ADD CONSTRAINT fk_properties_neighborhood_id FOREIGN KEY (neighborhood_id) REFERENCES neighborhoods(neighborhood_id);
CREATE TABLE IF NOT EXISTS property_features (
    property_id BIGINT NOT NULL,
    feature_category property_features_status NOT NULL,
    feature_name VARCHAR(100) NOT NULL,
    feature_value VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE property_features ADD CONSTRAINT fk_property_features_property_id FOREIGN KEY (property_id) REFERENCES properties(property_id) ON DELETE CASCADE;
CREATE TABLE IF NOT EXISTS property_rooms (
    property_id BIGINT NOT NULL,
    room_type VARCHAR(50) NOT NULL,
    room_level VARCHAR(50),
    length_ft DECIMAL(5, 2),
    width_ft DECIMAL(5, 2),
    description TEXT
);

ALTER TABLE property_rooms ADD CONSTRAINT fk_property_rooms_property_id FOREIGN KEY (property_id) REFERENCES properties(property_id) ON DELETE CASCADE;
CREATE TABLE IF NOT EXISTS brokerages (
    brokerage_name VARCHAR(255) NOT NULL,
    license_number VARCHAR(50) NOT NULL,
    address VARCHAR(255),
    city_id INTEGER,
    state_id INTEGER,
    zip_code VARCHAR(10),
    phone VARCHAR(20),
    email VARCHAR(255),
    website VARCHAR(255),
    established_date DATE,
    total_agents INTEGER DEFAULT 0,
    active_listings INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (license_number)
);

ALTER TABLE brokerages ADD CONSTRAINT fk_brokerages_city_id FOREIGN KEY (city_id) REFERENCES cities(city_id);
ALTER TABLE brokerages ADD CONSTRAINT fk_brokerages_state_id FOREIGN KEY (state_id) REFERENCES states_provinces(state_id);
CREATE TABLE IF NOT EXISTS agents (
    brokerage_id INTEGER,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    mobile_phone VARCHAR(20),
    license_number VARCHAR(50) NOT NULL,
    license_state_id INTEGER NOT NULL,
    license_expiry_date DATE,
    specializations JSONB,
    bio TEXT,
    profile_photo_url VARCHAR(500),
    years_experience SMALLINT,
    total_sales_volume DECIMAL(15, 2),
    total_transactions INTEGER DEFAULT 0,
    avg_days_on_market INTEGER,
    rating DECIMAL(3, 2),
    is_active BOOLEAN DEFAULT TRUE,
    joined_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (email),
    UNIQUE (license_number)
);

ALTER TABLE agents ADD CONSTRAINT fk_agents_brokerage_id FOREIGN KEY (brokerage_id) REFERENCES brokerages(brokerage_id);
ALTER TABLE agents ADD CONSTRAINT fk_agents_license_state_id FOREIGN KEY (license_state_id) REFERENCES states_provinces(state_id);
CREATE TABLE IF NOT EXISTS users (
    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(20),
    user_type users_status NOT NULL,
    email_verified BOOLEAN DEFAULT FALSE,
    phone_verified BOOLEAN DEFAULT FALSE,
    profile_photo_url VARCHAR(500),
    preferred_contact users_status DEFAULT 'email',
    last_login TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (email)
);

CREATE TABLE IF NOT EXISTS user_preferences (
    user_id BIGINT NOT NULL,
    min_price DECIMAL(12, 2),
    max_price DECIMAL(12, 2),
    min_bedrooms SMALLINT,
    min_bathrooms DECIMAL(3, 1),
    min_sqft INTEGER,
    max_sqft INTEGER,
    property_types JSONB,
    preferred_cities JSONB,
    preferred_neighborhoods JSONB,
    must_have_features JSONB,
    nice_to_have_features JSONB,
    max_hoa_fee DECIMAL(8, 2),
    school_rating_min DECIMAL(3, 1),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id)
);

ALTER TABLE user_preferences ADD CONSTRAINT fk_user_preferences_user_id FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;
CREATE TABLE IF NOT EXISTS listings (
    property_id BIGINT NOT NULL,
    listing_agent_id INTEGER NOT NULL,
    co_listing_agent_id INTEGER,
    listing_type listings_status NOT NULL,
    status listings_status NOT NULL,
    list_price DECIMAL(12, 2) NOT NULL,
    original_price DECIMAL(12, 2),
    price_per_sqft DECIMAL(8, 2),
    listing_date DATE NOT NULL,
    expiry_date DATE,
    days_on_market INTEGER DEFAULT 0,
    title VARCHAR(255),
    description TEXT,
    virtual_tour_url VARCHAR(500),
    video_url VARCHAR(500),
    commission_buyer_agent DECIMAL(5, 2),
    commission_listing_agent DECIMAL(5, 2),
    showing_instructions TEXT,
    mls_number VARCHAR(50),
    is_featured BOOLEAN DEFAULT FALSE,
    view_count INTEGER DEFAULT 0,
    inquiry_count INTEGER DEFAULT 0,
    showing_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE listings ADD CONSTRAINT fk_listings_property_id FOREIGN KEY (property_id) REFERENCES properties(property_id);
ALTER TABLE listings ADD CONSTRAINT fk_listings_listing_agent_id FOREIGN KEY (listing_agent_id) REFERENCES agents(agent_id);
ALTER TABLE listings ADD CONSTRAINT fk_listings_co_listing_agent_id FOREIGN KEY (co_listing_agent_id) REFERENCES agents(agent_id);
CREATE TABLE IF NOT EXISTS listing_status_history (
    listing_id BIGINT NOT NULL,
    status listing_status_history_status NOT NULL,
    changed_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by_user_id BIGINT,
    notes TEXT
);

ALTER TABLE listing_status_history ADD CONSTRAINT fk_listing_status_history_listing_id FOREIGN KEY (listing_id) REFERENCES listings(listing_id) ON DELETE CASCADE;
ALTER TABLE listing_status_history ADD CONSTRAINT fk_listing_status_history_changed_by_user_id FOREIGN KEY (changed_by_user_id) REFERENCES users(user_id);
CREATE TABLE IF NOT EXISTS price_changes (
    listing_id BIGINT NOT NULL,
    old_price DECIMAL(12, 2) NOT NULL,
    new_price DECIMAL(12, 2) NOT NULL,
    change_amount DECIMAL(12, 2) GENERATED ALWAYS AS (new_price - old_price) STORED,
    change_percentage DECIMAL(5, 2) GENERATED ALWAYS AS ((new_price - old_price) / old_price * 100) STORED,
    change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reason TEXT
);

ALTER TABLE price_changes ADD CONSTRAINT fk_price_changes_listing_id FOREIGN KEY (listing_id) REFERENCES listings(listing_id) ON DELETE CASCADE;
CREATE TABLE IF NOT EXISTS property_photos (
    property_id BIGINT NOT NULL,
    photo_url VARCHAR(500) NOT NULL,
    thumbnail_url VARCHAR(500),
    caption VARCHAR(255),
    photo_type property_photos_status DEFAULT 'other',
    display_order INTEGER DEFAULT 0,
    width INTEGER,
    height INTEGER,
    file_size INTEGER,
    uploaded_by_user_id BIGINT,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE property_photos ADD CONSTRAINT fk_property_photos_property_id FOREIGN KEY (property_id) REFERENCES properties(property_id) ON DELETE CASCADE;
ALTER TABLE property_photos ADD CONSTRAINT fk_property_photos_uploaded_by_user_id FOREIGN KEY (uploaded_by_user_id) REFERENCES users(user_id);
CREATE TABLE IF NOT EXISTS virtual_tours (
    property_id BIGINT NOT NULL,
    tour_type virtual_tours_status NOT NULL,
    tour_url VARCHAR(500) NOT NULL,
    embed_code TEXT,
    provider VARCHAR(100),
    view_count INTEGER DEFAULT 0,
    avg_view_duration INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (property_id)
);

ALTER TABLE virtual_tours ADD CONSTRAINT fk_virtual_tours_property_id FOREIGN KEY (property_id) REFERENCES properties(property_id) ON DELETE CASCADE;
CREATE TABLE IF NOT EXISTS saved_searches (
    user_id BIGINT NOT NULL,
    search_name VARCHAR(100),
    search_criteria JSONB NOT NULL,
    frequency saved_searches_status DEFAULT 'daily',
    last_run TIMESTAMP NULL,
    last_match_count INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE saved_searches ADD CONSTRAINT fk_saved_searches_user_id FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;
CREATE TABLE IF NOT EXISTS saved_properties (
    user_id BIGINT NOT NULL,
    property_id BIGINT NOT NULL,
    listing_id BIGINT,
    notes TEXT,
    rating SMALLINT,
    saved_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, property_id)
);

ALTER TABLE saved_properties ADD CONSTRAINT fk_saved_properties_user_id FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;
ALTER TABLE saved_properties ADD CONSTRAINT fk_saved_properties_property_id FOREIGN KEY (property_id) REFERENCES properties(property_id);
ALTER TABLE saved_properties ADD CONSTRAINT fk_saved_properties_listing_id FOREIGN KEY (listing_id) REFERENCES listings(listing_id);
CREATE TABLE IF NOT EXISTS showing_requests (
    listing_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    agent_id INTEGER,
    preferred_date DATE NOT NULL,
    preferred_time_start TIME,
    preferred_time_end TIME,
    alternate_date DATE,
    status showing_requests_status DEFAULT 'pending',
    message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE showing_requests ADD CONSTRAINT fk_showing_requests_listing_id FOREIGN KEY (listing_id) REFERENCES listings(listing_id);
ALTER TABLE showing_requests ADD CONSTRAINT fk_showing_requests_user_id FOREIGN KEY (user_id) REFERENCES users(user_id);
ALTER TABLE showing_requests ADD CONSTRAINT fk_showing_requests_agent_id FOREIGN KEY (agent_id) REFERENCES agents(agent_id);
CREATE TABLE IF NOT EXISTS open_houses (
    listing_id BIGINT NOT NULL,
    start_datetime TIMESTAMP NOT NULL,
    end_datetime TIMESTAMP NOT NULL,
    host_agent_id INTEGER NOT NULL,
    registration_required BOOLEAN DEFAULT FALSE,
    refreshments BOOLEAN DEFAULT FALSE,
    notes TEXT,
    attendee_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE open_houses ADD CONSTRAINT fk_open_houses_listing_id FOREIGN KEY (listing_id) REFERENCES listings(listing_id);
ALTER TABLE open_houses ADD CONSTRAINT fk_open_houses_host_agent_id FOREIGN KEY (host_agent_id) REFERENCES agents(agent_id);
CREATE TABLE IF NOT EXISTS offers (
    listing_id BIGINT NOT NULL,
    buyer_user_id BIGINT,
    buyer_agent_id INTEGER,
    offer_amount DECIMAL(12, 2) NOT NULL,
    offer_type offers_status DEFAULT 'standard',
    status offers_status NOT NULL,
    earnest_money DECIMAL(10, 2),
    down_payment_amount DECIMAL(12, 2),
    down_payment_percentage DECIMAL(5, 2),
    financing_type offers_status,
    pre_approval_letter BOOLEAN DEFAULT FALSE,
    contingencies JSONB,
    closing_date DATE,
    expiry_datetime TIMESTAMP,
    submitted_at TIMESTAMP NULL,
    response_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE offers ADD CONSTRAINT fk_offers_listing_id FOREIGN KEY (listing_id) REFERENCES listings(listing_id);
ALTER TABLE offers ADD CONSTRAINT fk_offers_buyer_user_id FOREIGN KEY (buyer_user_id) REFERENCES users(user_id);
ALTER TABLE offers ADD CONSTRAINT fk_offers_buyer_agent_id FOREIGN KEY (buyer_agent_id) REFERENCES agents(agent_id);
CREATE TABLE IF NOT EXISTS transactions (
    listing_id BIGINT NOT NULL,
    accepted_offer_id BIGINT NOT NULL,
    sale_price DECIMAL(12, 2) NOT NULL,
    closing_date DATE,
    escrow_company VARCHAR(255),
    escrow_number VARCHAR(100),
    title_company VARCHAR(255),
    transaction_status transactions_status DEFAULT 'pending',
    commission_paid_listing DECIMAL(10, 2),
    commission_paid_buyer DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE transactions ADD CONSTRAINT fk_transactions_listing_id FOREIGN KEY (listing_id) REFERENCES listings(listing_id);
ALTER TABLE transactions ADD CONSTRAINT fk_transactions_accepted_offer_id FOREIGN KEY (accepted_offer_id) REFERENCES offers(offer_id);
CREATE TABLE IF NOT EXISTS market_trends (
    neighborhood_id INTEGER,
    city_id INTEGER,
    state_id INTEGER,
    trend_date DATE NOT NULL,
    property_type VARCHAR(50),
    median_list_price DECIMAL(12, 2),
    median_sold_price DECIMAL(12, 2),
    avg_price_per_sqft DECIMAL(8, 2),
    avg_days_on_market INTEGER,
    inventory_count INTEGER,
    new_listings_count INTEGER,
    sold_count INTEGER,
    pending_count INTEGER,
    price_reduced_count INTEGER,
    months_of_supply DECIMAL(4, 2),
    sale_to_list_ratio DECIMAL(5, 4),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE market_trends ADD CONSTRAINT fk_market_trends_neighborhood_id FOREIGN KEY (neighborhood_id) REFERENCES neighborhoods(neighborhood_id);
ALTER TABLE market_trends ADD CONSTRAINT fk_market_trends_city_id FOREIGN KEY (city_id) REFERENCES cities(city_id);
ALTER TABLE market_trends ADD CONSTRAINT fk_market_trends_state_id FOREIGN KEY (state_id) REFERENCES states_provinces(state_id);
CREATE TABLE IF NOT EXISTS comparable_sales (
    subject_property_id BIGINT NOT NULL,
    comp_property_id BIGINT NOT NULL,
    sale_date DATE NOT NULL,
    sale_price DECIMAL(12, 2) NOT NULL,
    price_per_sqft DECIMAL(8, 2),
    distance_miles DECIMAL(5, 2),
    similarity_score DECIMAL(3, 2),
    adjustments JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE comparable_sales ADD CONSTRAINT fk_comparable_sales_subject_property_id FOREIGN KEY (subject_property_id) REFERENCES properties(property_id);
ALTER TABLE comparable_sales ADD CONSTRAINT fk_comparable_sales_comp_property_id FOREIGN KEY (comp_property_id) REFERENCES properties(property_id);
CREATE TABLE IF NOT EXISTS school_districts (
    district_name VARCHAR(255) NOT NULL,
    district_type school_districts_status NOT NULL,
    state_id INTEGER NOT NULL,
    boundary_polygon TEXT,
    website VARCHAR(255),
    rating DECIMAL(3, 1),
    total_schools INTEGER,
    total_students INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE school_districts ADD CONSTRAINT fk_school_districts_state_id FOREIGN KEY (state_id) REFERENCES states_provinces(state_id);
CREATE TABLE IF NOT EXISTS schools (
    district_id INTEGER NOT NULL,
    school_name VARCHAR(255) NOT NULL,
    school_type schools_status NOT NULL,
    address VARCHAR(255),
    city_id INTEGER,
    zip_code VARCHAR(10),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    location_point TEXT,
    grade_range VARCHAR(20),
    enrollment INTEGER,
    student_teacher_ratio DECIMAL(4, 1),
    rating DECIMAL(3, 1),
    test_scores JSONB,
    website VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE schools ADD CONSTRAINT fk_schools_district_id FOREIGN KEY (district_id) REFERENCES school_districts(district_id);
ALTER TABLE schools ADD CONSTRAINT fk_schools_city_id FOREIGN KEY (city_id) REFERENCES cities(city_id);
CREATE TABLE IF NOT EXISTS property_schools (
    property_id BIGINT NOT NULL,
    school_id INTEGER NOT NULL,
    school_type property_schools_status NOT NULL,
    distance_miles DECIMAL(4, 2),
    UNIQUE (property_id, school_id)
);

ALTER TABLE property_schools ADD CONSTRAINT fk_property_schools_property_id FOREIGN KEY (property_id) REFERENCES properties(property_id) ON DELETE CASCADE;
ALTER TABLE property_schools ADD CONSTRAINT fk_property_schools_school_id FOREIGN KEY (school_id) REFERENCES schools(school_id);
SHOW TABLES;
SELECT 'Real Estate tables created successfully' AS status;
-- Indexes
