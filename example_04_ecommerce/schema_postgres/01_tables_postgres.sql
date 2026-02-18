-- PostgreSQL Schema
-- Converted from MySQL on 2026-02-17T23:11:17.340097
-- Generator: MySQL to PostgreSQL Converter

-- Enum Types
CREATE TYPE customers_status AS ENUM ('active', 'inactive', 'suspended', 'deleted');
CREATE TYPE customer_addresses_status AS ENUM ('billing', 'shipping', 'both');
CREATE TYPE products_status AS ENUM ('active', 'inactive', 'draft', 'out_of_stock', 'discontinued');
CREATE TYPE inventory_movements_status AS ENUM ('sale', 'return', 'restock', 'adjustment', 'transfer', 'damage', 'loss');
CREATE TYPE orders_status AS ENUM ('pending', 'paid', 'partially_paid', 'failed', 'refunded', 'partially_refunded');
CREATE TYPE order_items_status AS ENUM ('unfulfilled', 'partially_fulfilled', 'fulfilled', 'cancelled');
CREATE TYPE order_status_history_status AS ENUM ('pending', 'processing', 'confirmed', 'shipped', 'delivered', 'cancelled', 'refunded');
CREATE TYPE payment_methods_status AS ENUM ('credit_card', 'debit_card', 'paypal', 'bank_account', 'digital_wallet');
CREATE TYPE payment_transactions_status AS ENUM ('pending', 'processing', 'succeeded', 'failed', 'cancelled');
CREATE TYPE shipments_status AS ENUM ('pending', 'picked', 'packed', 'shipped', 'in_transit', 'delivered', 'returned', 'lost');
CREATE TYPE product_reviews_status AS ENUM ('pending', 'approved', 'rejected', 'flagged');
CREATE TYPE coupons_status AS ENUM ('all', 'specific_products', 'specific_categories', 'specific_brands');
CREATE TYPE price_rules_status AS ENUM ('all', 'specific_products', 'specific_categories', 'specific_brands');
CREATE TYPE page_views_status AS ENUM ('desktop', 'mobile', 'tablet');
CREATE TYPE search_queries_status AS ENUM ('desktop', 'mobile', 'tablet');
CREATE TYPE product_recommendations_status AS ENUM ('also_bought', 'viewed_together', 'personalized', 'trending', 'similar');
CREATE TYPE support_tickets_status AS ENUM ('open', 'in_progress', 'waiting_customer', 'waiting_internal', 'resolved', 'closed');
CREATE TYPE returns_status AS ENUM ('new', 'like_new', 'good', 'fair', 'poor', 'damaged');
CREATE TYPE return_items_status AS ENUM ('unopened', 'opened', 'used', 'damaged', 'defective');
CREATE TYPE email_queue_status AS ENUM ('pending', 'sending', 'sent', 'failed', 'cancelled');

DROP DATABASE IF EXISTS ecommerce;
-- Create database (run as superuser)
-- CREATE DATABASE ecommerce;
-- \c ecommerce

SELECT 'Database ecommerce created successfully' AS Status;
SELECT 'Focus: Full-featured e-commerce platform with marketplace capabilities' AS Description;
CREATE TABLE IF NOT EXISTS customers (
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(20),
    date_of_birth DATE,
    gender customers_status,
    customer_type customers_status DEFAULT 'regular',
    email_verified BOOLEAN DEFAULT FALSE,
    phone_verified BOOLEAN DEFAULT FALSE,
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    preferred_language VARCHAR(5) DEFAULT 'en',
    preferred_currency VARCHAR(3) DEFAULT 'USD',
    referred_by INTEGER,
    loyalty_points INTEGER DEFAULT 0,
    lifetime_value DECIMAL(12, 2) DEFAULT 0.00,
    status customers_status DEFAULT 'active',
    last_login_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS customer_addresses (
    customer_id INTEGER NOT NULL,
    address_type customer_addresses_status DEFAULT 'both',
    is_default BOOLEAN DEFAULT FALSE,
    recipient_name VARCHAR(200),
    company_name VARCHAR(200),
    address_line1 VARCHAR(255) NOT NULL,
    address_line2 VARCHAR(255),
    city VARCHAR(100) NOT NULL,
    state_province VARCHAR(100),
    postal_code VARCHAR(20),
    country_code VARCHAR(2) NOT NULL,
    phone VARCHAR(20),
    delivery_instructions TEXT,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    validated BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS categories (
    parent_category_id INTEGER,
    category_name VARCHAR(100) NOT NULL,
    description TEXT,
    image_url VARCHAR(500),
    meta_title VARCHAR(255),
    meta_description TEXT,
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    product_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS brands (
    brand_name VARCHAR(100) NOT NULL,
    logo_url VARCHAR(500),
    website_url VARCHAR(500),
    description TEXT,
    country_of_origin VARCHAR(2),
    is_featured BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS products (
    product_name VARCHAR(255) NOT NULL,
    brand_id INTEGER,
    category_id INTEGER NOT NULL,
    description TEXT,
    short_description VARCHAR(500),
    features JSONB,
    compare_at_price DECIMAL(10, 2),
    weight_kg DECIMAL(10, 3),
    dimensions_cm JSONB,
    is_featured BOOLEAN DEFAULT FALSE,
    is_new BOOLEAN DEFAULT FALSE,
    requires_shipping BOOLEAN DEFAULT TRUE,
    max_quantity_per_order INTEGER,
    min_quantity_per_order INTEGER DEFAULT 1,
    status products_status DEFAULT 'draft',
    launch_date DATE,
    discontinue_date DATE,
    view_count INTEGER DEFAULT 0,
    sold_count INTEGER DEFAULT 0,
    average_rating DECIMAL(3, 2) DEFAULT 0.00,
    review_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FULLTEXT TEXT (product_name, description, short_description)
);

CREATE TABLE IF NOT EXISTS product_variants (
    product_id INTEGER NOT NULL,
    variant_name VARCHAR(255),
    attributes JSONB NOT NULL,
    compare_at_price DECIMAL(10, 2),
    cost DECIMAL(10, 2),
    weight_kg DECIMAL(10, 3),
    barcode VARCHAR(100),
    image_url VARCHAR(500),
    position INTEGER DEFAULT 0,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS product_images (
    product_id INTEGER NOT NULL,
    variant_id INTEGER,
    image_url VARCHAR(500) NOT NULL,
    thumbnail_url VARCHAR(500),
    alt_text VARCHAR(255),
    position INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS warehouses (
    warehouse_name VARCHAR(100) NOT NULL,
    address VARCHAR(500),
    city VARCHAR(100),
    state_province VARCHAR(100),
    postal_code VARCHAR(20),
    country_code VARCHAR(2),
    phone VARCHAR(20),
    email VARCHAR(255),
    manager_name VARCHAR(200),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    is_active BOOLEAN DEFAULT TRUE,
    is_default BOOLEAN DEFAULT FALSE,
    fulfills_online_orders BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS inventory (
    product_id INTEGER NOT NULL,
    variant_id INTEGER,
    warehouse_id INTEGER NOT NULL,
    quantity_available INTEGER NOT NULL DEFAULT 0,
    quantity_reserved INTEGER NOT NULL DEFAULT 0,
    reorder_quantity INTEGER,
    last_restock_date DATE,
    last_sale_date DATE,
    last_counted_date DATE,
    average_daily_sales DECIMAL(10, 2),
    days_of_stock DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (product_id, variant_id, warehouse_id)
);

CREATE TABLE IF NOT EXISTS inventory_movements (
    inventory_id INTEGER NOT NULL,
    movement_type inventory_movements_status NOT NULL,
    quantity INTEGER NOT NULL,
    negative TEXT removals,
    to_warehouse_id INTEGER,
    unit_cost DECIMAL(10, 2),
    notes TEXT,
    performed_by INTEGER
);

CREATE TABLE IF NOT EXISTS cart_items (
    customer_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    variant_id INTEGER,
    quantity INTEGER NOT NULL DEFAULT 1,
    price_at_time DECIMAL(10, 2),
    saved_for_later BOOLEAN DEFAULT FALSE,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS wishlist_items (
    customer_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    variant_id INTEGER,
    priority INTEGER DEFAULT 0,
    notes TEXT,
    price_when_added DECIMAL(10, 2),
    notify_on_sale BOOLEAN DEFAULT TRUE,
    notify_on_restock BOOLEAN DEFAULT TRUE,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (customer_id, product_id, variant_id)
);

CREATE TABLE IF NOT EXISTS orders (
    customer_id INTEGER,
    guest_email VARCHAR(255),
    payment_status orders_status DEFAULT 'pending',
    subtotal DECIMAL(12, 2) NOT NULL,
    tax_amount DECIMAL(10, 2) DEFAULT 0.00,
    shipping_amount DECIMAL(10, 2) DEFAULT 0.00,
    discount_amount DECIMAL(10, 2) DEFAULT 0.00,
    total_amount DECIMAL(12, 2) NOT NULL,
    currency_code VARCHAR(3) DEFAULT 'USD',
    exchange_rate DECIMAL(10, 6) DEFAULT 1.000000,
    shipping_address_id INTEGER,
    billing_address_id INTEGER,
    shipping_method VARCHAR(100),
    tracking_number VARCHAR(255),
    notes TEXT,
    internal_notes TEXT,
    user_agent TEXT,
    referred_from VARCHAR(500),
    coupon_code VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    confirmed_at TIMESTAMP NULL,
    shipped_at TIMESTAMP NULL,
    delivered_at TIMESTAMP NULL,
    cancelled_at TIMESTAMP NULL
);

CREATE TABLE IF NOT EXISTS order_items (
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    variant_id INTEGER,
    product_name VARCHAR(255) NOT NULL,
    sku VARCHAR(100),
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    discount_amount DECIMAL(10, 2) DEFAULT 0.00,
    tax_amount DECIMAL(10, 2) DEFAULT 0.00,
    total_price DECIMAL(12, 2) NOT NULL,
    cost DECIMAL(10, 2),
    requires_shipping BOOLEAN DEFAULT TRUE,
    is_gift BOOLEAN DEFAULT FALSE,
    gift_message TEXT,
    fulfillment_status order_items_status DEFAULT 'unfulfilled',
    fulfilled_quantity INTEGER DEFAULT 0,
    warehouse_id INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS order_status_history (
    order_id INTEGER NOT NULL,
    status order_status_history_status NOT NULL,
    notes TEXT,
    changed_by INTEGER
);

CREATE TABLE IF NOT EXISTS payment_methods (
    customer_id INTEGER NOT NULL,
    type payment_methods_status NOT NULL,
    provider VARCHAR(50),
    card_brand VARCHAR(50),
    card_exp_month SMALLINT,
    card_exp_year SMALLINT,
    billing_address_id INTEGER,
    token VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS payment_transactions (
    order_id INTEGER NOT NULL,
    payment_method_id INTEGER,
    transaction_type payment_transactions_status NOT NULL,
    amount DECIMAL(12, 2) NOT NULL,
    currency_code VARCHAR(3) DEFAULT 'USD',
    status payment_transactions_status NOT NULL,
    gateway VARCHAR(50),
    gateway_response JSONB,
    failure_reason VARCHAR(500),
    processed_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS shipping_methods (
    carrier_name VARCHAR(100) NOT NULL,
    service_name VARCHAR(100) NOT NULL,
    delivery_days_min INTEGER,
    delivery_days_max INTEGER,
    base_rate DECIMAL(10, 2),
    per_kg_rate DECIMAL(10, 2),
    per_item_rate DECIMAL(10, 2),
    free_shipping_threshold DECIMAL(10, 2),
    max_weight_kg DECIMAL(10, 2),
    countries JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS shipments (
    order_id INTEGER NOT NULL,
    warehouse_id INTEGER,
    shipping_method_id INTEGER NOT NULL,
    tracking_number VARCHAR(255),
    carrier_name VARCHAR(100),
    status shipments_status DEFAULT 'pending',
    weight_kg DECIMAL(10, 3),
    dimensions_cm JSONB,
    shipping_label_url VARCHAR(500),
    shipped_at TIMESTAMP NULL,
    delivered_at TIMESTAMP NULL,
    delivery_signature VARCHAR(255),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS product_reviews (
    product_id INTEGER NOT NULL,
    variant_id INTEGER,
    customer_id INTEGER NOT NULL,
    order_item_id INTEGER,
    title VARCHAR(255),
    review_text TEXT,
    pros TEXT,
    cons TEXT,
    is_verified_purchase BOOLEAN DEFAULT FALSE,
    is_featured BOOLEAN DEFAULT FALSE,
    helpful_count INTEGER DEFAULT 0,
    unhelpful_count INTEGER DEFAULT 0,
    admin_reply TEXT,
    admin_reply_at TIMESTAMP NULL,
    status product_reviews_status DEFAULT 'pending',
    images JSONB,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS review_votes (
    review_id INTEGER NOT NULL,
    customer_id INTEGER NOT NULL,
    is_helpful BOOLEAN NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (review_id, customer_id)
);

CREATE TABLE IF NOT EXISTS coupons (
    description TEXT,
    discount_type coupons_status NOT NULL,
    discount_value DECIMAL(10, 2) NOT NULL,
    minimum_amount DECIMAL(10, 2),
    maximum_discount DECIMAL(10, 2),
    applicable_to coupons_status DEFAULT 'all',
    applicable_ids JSONB,
    usage_limit_per_customer INTEGER,
    usage_count INTEGER DEFAULT 0,
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    requires_account BOOLEAN DEFAULT FALSE,
    stackable BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS coupon_usage (
    coupon_id INTEGER NOT NULL,
    customer_id INTEGER,
    order_id INTEGER NOT NULL,
    discount_amount DECIMAL(10, 2) NOT NULL,
    used_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS price_rules (
    rule_name VARCHAR(100) NOT NULL,
    rule_type price_rules_status NOT NULL,
    priority INTEGER DEFAULT 0,
    conditions JSONB,
    discount_value DECIMAL(10, 2) NOT NULL,
    applicable_to price_rules_status DEFAULT 'all',
    applicable_ids JSONB,
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS page_views (
    customer_id INTEGER,
    session_id VARCHAR(128),
    product_id INTEGER,
    page_type VARCHAR(50),
    referrer_url VARCHAR(500),
    ip_address VARCHAR(45),
    user_agent TEXT,
    device_type page_views_status DEFAULT 'desktop',
    duration_seconds INTEGER,
    bounce BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS search_queries (
    customer_id INTEGER,
    session_id VARCHAR(128),
    query_text VARCHAR(255) NOT NULL,
    results_count INTEGER,
    clicked_position INTEGER,
    device_type search_queries_status DEFAULT 'desktop',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FULLTEXT TEXT (query_text)
);

CREATE TABLE IF NOT EXISTS recently_viewed (
    customer_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    viewed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    view_count INTEGER DEFAULT 1,
    UNIQUE (customer_id, product_id)
);

CREATE TABLE IF NOT EXISTS product_recommendations (
    customer_id INTEGER,
    product_id INTEGER NOT NULL,
    recommendation_type product_recommendations_status NOT NULL,
    score DECIMAL(5, 4) DEFAULT 0.0000,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS support_tickets (
    customer_id INTEGER NOT NULL,
    order_id INTEGER,
    category support_tickets_status NOT NULL,
    priority support_tickets_status DEFAULT 'medium',
    status support_tickets_status DEFAULT 'open',
    subject VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    resolution TEXT,
    assigned_to INTEGER,
    satisfaction_rating INTEGER,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS returns (
    order_id INTEGER NOT NULL,
    customer_id INTEGER NOT NULL,
    status returns_status DEFAULT 'requested',
    reason returns_status NOT NULL,
    reason_details TEXT,
    return_shipping_method VARCHAR(100),
    return_tracking_number VARCHAR(255),
    refund_amount DECIMAL(12, 2),
    restocking_fee DECIMAL(10, 2) DEFAULT 0.00,
    return_label_url VARCHAR(500),
    received_condition returns_status,
    inspection_notes TEXT,
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    approved_at TIMESTAMP NULL,
    received_at TIMESTAMP NULL,
    refunded_at TIMESTAMP NULL
);

CREATE TABLE IF NOT EXISTS return_items (
    return_id INTEGER NOT NULL,
    order_item_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    condition return_items_status NOT NULL,
    refund_amount DECIMAL(10, 2),
    replacement_sent BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS email_templates (
    template_name VARCHAR(100) NOT NULL,
    subject VARCHAR(255) NOT NULL,
    html_content TEXT NOT NULL,
    text_content TEXT,
    variables JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS email_queue (
    customer_id INTEGER,
    to_email VARCHAR(255) NOT NULL,
    template_id INTEGER,
    subject VARCHAR(255),
    variables JSONB,
    status email_queue_status DEFAULT 'pending',
    attempts INTEGER DEFAULT 0,
    sent_at TIMESTAMP NULL,
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

SELECT 'All e-commerce tables created successfully' AS Status;
SELECT COUNT(*) AS table_count FROM information_schema.tables
WHERE table_schema = 'ecommerce';
-- Indexes
