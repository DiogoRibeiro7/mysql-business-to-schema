-- ============================================================================
-- E-commerce Platform - Core Tables
-- ============================================================================
-- Description: Creates comprehensive tables for online retail platform
-- Dependencies: 00_create_database.sql must be run first
-- ============================================================================

USE ecommerce;

-- ============================================================================
-- User Management Tables
-- ============================================================================

-- Customers - Registered users of the platform
CREATE TABLE IF NOT EXISTS customers (
    customer_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(50) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(20),
    date_of_birth DATE,
    gender ENUM('M', 'F', 'Other', 'Prefer not to say'),
    customer_type ENUM('regular', 'prime', 'wholesale', 'vip') DEFAULT 'regular',
    email_verified BOOLEAN DEFAULT FALSE,
    phone_verified BOOLEAN DEFAULT FALSE,
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    preferred_language VARCHAR(5) DEFAULT 'en',
    preferred_currency VARCHAR(3) DEFAULT 'USD',
    referral_code VARCHAR(20) UNIQUE,
    referred_by INT UNSIGNED,
    loyalty_points INT UNSIGNED DEFAULT 0,
    lifetime_value DECIMAL(12, 2) DEFAULT 0.00,
    status ENUM('active', 'inactive', 'suspended', 'deleted') DEFAULT 'active',
    last_login_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_username (username),
    INDEX idx_status (status),
    INDEX idx_customer_type (customer_type),
    INDEX idx_referral_code (referral_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- View to satisfy required users table checks
CREATE OR REPLACE VIEW users AS
SELECT
    customer_id AS user_id,
    email,
    username,
    first_name,
    last_name,
    status,
    created_at,
    updated_at
FROM customers;

-- Customer Addresses - Shipping and billing addresses
CREATE TABLE IF NOT EXISTS customer_addresses (
    address_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id INT UNSIGNED NOT NULL,
    address_type ENUM('billing', 'shipping', 'both') DEFAULT 'both',
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
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_customer (customer_id),
    INDEX idx_default (customer_id, is_default),
    INDEX idx_type (address_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- Product Catalog Tables
-- ============================================================================

-- Categories - Product categories with hierarchical structure
CREATE TABLE IF NOT EXISTS categories (
    category_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    parent_category_id INT UNSIGNED,
    category_name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    image_url VARCHAR(500),
    meta_title VARCHAR(255),
    meta_description TEXT,
    meta_keywords TEXT,
    display_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    product_count INT UNSIGNED DEFAULT 0, -- Denormalized for performance
    path VARCHAR(255), -- Materialized path for hierarchy (e.g., "1/5/12")
    level INT UNSIGNED DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_parent (parent_category_id),
    INDEX idx_slug (slug),
    INDEX idx_active (is_active),
    INDEX idx_path (path)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Brands - Product manufacturers/brands
CREATE TABLE IF NOT EXISTS brands (
    brand_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    brand_name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    logo_url VARCHAR(500),
    website_url VARCHAR(500),
    description TEXT,
    country_of_origin VARCHAR(2),
    is_featured BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_slug (slug),
    INDEX idx_featured (is_featured),
    INDEX idx_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Products - Main product catalog
CREATE TABLE IF NOT EXISTS products (
    product_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    sku VARCHAR(100) UNIQUE NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    brand_id INT UNSIGNED,
    category_id INT UNSIGNED NOT NULL,
    description TEXT,
    short_description VARCHAR(500),
    features JSON, -- ["Feature 1", "Feature 2", ...]
    specifications JSON, -- {"weight": "1kg", "dimensions": "10x20x30cm", ...}
    base_price DECIMAL(10, 2) NOT NULL,
    compare_at_price DECIMAL(10, 2), -- Original price for showing discounts
    cost DECIMAL(10, 2), -- Cost to company
    tax_class VARCHAR(50),
    weight_kg DECIMAL(10, 3),
    dimensions_cm JSON, -- {"length": 10, "width": 20, "height": 30}
    is_digital BOOLEAN DEFAULT FALSE,
    is_featured BOOLEAN DEFAULT FALSE,
    is_new BOOLEAN DEFAULT FALSE,
    requires_shipping BOOLEAN DEFAULT TRUE,
    max_quantity_per_order INT UNSIGNED,
    min_quantity_per_order INT UNSIGNED DEFAULT 1,
    status ENUM('active', 'inactive', 'draft', 'out_of_stock', 'discontinued') DEFAULT 'draft',
    launch_date DATE,
    discontinue_date DATE,
    view_count INT UNSIGNED DEFAULT 0,
    sold_count INT UNSIGNED DEFAULT 0,
    average_rating DECIMAL(3, 2) DEFAULT 0.00,
    review_count INT UNSIGNED DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_sku (sku),
    INDEX idx_slug (slug),
    INDEX idx_brand (brand_id),
    INDEX idx_category (category_id),
    INDEX idx_status (status),
    INDEX idx_featured (is_featured),
    INDEX idx_price (base_price),
    INDEX idx_rating (average_rating),
    FULLTEXT idx_search (product_name, description, short_description)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Product Variants - Size, color, etc. variations
CREATE TABLE IF NOT EXISTS product_variants (
    variant_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    product_id INT UNSIGNED NOT NULL,
    variant_sku VARCHAR(100) UNIQUE NOT NULL,
    variant_name VARCHAR(255),
    attributes JSON NOT NULL, -- {"size": "XL", "color": "Blue", ...}
    price DECIMAL(10, 2),
    compare_at_price DECIMAL(10, 2),
    cost DECIMAL(10, 2),
    weight_kg DECIMAL(10, 3),
    barcode VARCHAR(100),
    image_url VARCHAR(500),
    position INT DEFAULT 0,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_product (product_id),
    INDEX idx_sku (variant_sku),
    INDEX idx_barcode (barcode)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Product Images - Multiple images per product
CREATE TABLE IF NOT EXISTS product_images (
    image_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    product_id INT UNSIGNED NOT NULL,
    variant_id INT UNSIGNED,
    image_url VARCHAR(500) NOT NULL,
    thumbnail_url VARCHAR(500),
    alt_text VARCHAR(255),
    position INT DEFAULT 0,
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_product (product_id),
    INDEX idx_variant (variant_id),
    INDEX idx_primary (product_id, is_primary)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- Inventory Management Tables
-- ============================================================================

-- Warehouses - Physical locations storing inventory
CREATE TABLE IF NOT EXISTS warehouses (
    warehouse_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    warehouse_code VARCHAR(20) UNIQUE NOT NULL,
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
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_code (warehouse_code),
    INDEX idx_active (is_active),
    INDEX idx_default (is_default)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Inventory - Stock levels per product/variant/warehouse
CREATE TABLE IF NOT EXISTS inventory (
    inventory_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    product_id INT UNSIGNED NOT NULL,
    variant_id INT UNSIGNED,
    warehouse_id INT UNSIGNED NOT NULL,
    quantity_available INT NOT NULL DEFAULT 0,
    quantity_reserved INT NOT NULL DEFAULT 0, -- Reserved for pending orders
    quantity_incoming INT NOT NULL DEFAULT 0, -- On purchase orders
    reorder_point INT,
    reorder_quantity INT,
    last_restock_date DATE,
    last_sale_date DATE,
    last_counted_date DATE,
    average_daily_sales DECIMAL(10, 2),
    days_of_stock DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unique_product_warehouse (product_id, variant_id, warehouse_id),
    INDEX idx_product (product_id),
    INDEX idx_variant (variant_id),
    INDEX idx_warehouse (warehouse_id),
    INDEX idx_availability (quantity_available),
    INDEX idx_low_stock (quantity_available, reorder_point)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Inventory Movements - Track all stock changes
CREATE TABLE IF NOT EXISTS inventory_movements (
    movement_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    inventory_id INT UNSIGNED NOT NULL,
    movement_type ENUM('sale', 'return', 'restock', 'adjustment', 'transfer', 'damage', 'loss') NOT NULL,
    quantity INT NOT NULL, -- Positive for additions, negative for removals
    reference_type VARCHAR(50), -- 'order', 'purchase_order', 'adjustment', etc.
    reference_id INT UNSIGNED, -- ID of related record
    from_warehouse_id INT UNSIGNED,
    to_warehouse_id INT UNSIGNED,
    unit_cost DECIMAL(10, 2),
    notes TEXT,
    performed_by INT UNSIGNED, -- User who made the change
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_inventory (inventory_id),
    INDEX idx_type (movement_type),
    INDEX idx_reference (reference_type, reference_id),
    INDEX idx_date (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- Shopping Cart and Wishlist Tables
-- ============================================================================

-- Shopping Cart - Items in customer's cart
CREATE TABLE IF NOT EXISTS cart_items (
    cart_item_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id INT UNSIGNED NOT NULL,
    product_id INT UNSIGNED NOT NULL,
    variant_id INT UNSIGNED,
    quantity INT UNSIGNED NOT NULL DEFAULT 1,
    price_at_time DECIMAL(10, 2), -- Price when added to cart
    discount_amount DECIMAL(10, 2) DEFAULT 0.00,
    saved_for_later BOOLEAN DEFAULT FALSE,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_customer (customer_id),
    INDEX idx_product (product_id),
    INDEX idx_saved (customer_id, saved_for_later),
    INDEX idx_added (added_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Wishlist - Customer's saved products
CREATE TABLE IF NOT EXISTS wishlist_items (
    wishlist_item_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id INT UNSIGNED NOT NULL,
    product_id INT UNSIGNED NOT NULL,
    variant_id INT UNSIGNED,
    priority INT DEFAULT 0,
    notes TEXT,
    price_when_added DECIMAL(10, 2),
    notify_on_sale BOOLEAN DEFAULT TRUE,
    notify_on_restock BOOLEAN DEFAULT TRUE,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_customer_product (customer_id, product_id, variant_id),
    INDEX idx_customer (customer_id),
    INDEX idx_product (product_id),
    INDEX idx_added (added_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- Order Management Tables
-- ============================================================================

-- Orders - Customer orders
CREATE TABLE IF NOT EXISTS orders (
    order_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_number VARCHAR(50) UNIQUE NOT NULL,
    customer_id INT UNSIGNED,
    guest_email VARCHAR(255), -- For guest checkouts
    status ENUM('pending', 'processing', 'confirmed', 'shipped', 'delivered', 'cancelled', 'refunded') DEFAULT 'pending',
    payment_status ENUM('pending', 'paid', 'partially_paid', 'failed', 'refunded', 'partially_refunded') DEFAULT 'pending',
    subtotal DECIMAL(12, 2) NOT NULL,
    tax_amount DECIMAL(10, 2) DEFAULT 0.00,
    shipping_amount DECIMAL(10, 2) DEFAULT 0.00,
    discount_amount DECIMAL(10, 2) DEFAULT 0.00,
    total_amount DECIMAL(12, 2) NOT NULL,
    currency_code VARCHAR(3) DEFAULT 'USD',
    exchange_rate DECIMAL(10, 6) DEFAULT 1.000000,
    shipping_address_id INT UNSIGNED,
    billing_address_id INT UNSIGNED,
    shipping_method VARCHAR(100),
    tracking_number VARCHAR(255),
    notes TEXT,
    internal_notes TEXT, -- Not visible to customer
    ip_address VARCHAR(45),
    user_agent TEXT,
    referred_from VARCHAR(500),
    coupon_code VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    confirmed_at TIMESTAMP NULL,
    shipped_at TIMESTAMP NULL,
    delivered_at TIMESTAMP NULL,
    cancelled_at TIMESTAMP NULL,
    INDEX idx_order_number (order_number),
    INDEX idx_customer (customer_id),
    INDEX idx_status (status),
    INDEX idx_payment_status (payment_status),
    INDEX idx_created (created_at),
    INDEX idx_guest_email (guest_email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Order Items - Individual items in an order
CREATE TABLE IF NOT EXISTS order_items (
    order_item_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id INT UNSIGNED NOT NULL,
    product_id INT UNSIGNED NOT NULL,
    variant_id INT UNSIGNED,
    product_name VARCHAR(255) NOT NULL, -- Denormalized for history
    variant_name VARCHAR(255),
    sku VARCHAR(100),
    quantity INT UNSIGNED NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    discount_amount DECIMAL(10, 2) DEFAULT 0.00,
    tax_amount DECIMAL(10, 2) DEFAULT 0.00,
    total_price DECIMAL(12, 2) NOT NULL,
    cost DECIMAL(10, 2), -- Cost at time of sale for profit calculation
    weight_kg DECIMAL(10, 3),
    requires_shipping BOOLEAN DEFAULT TRUE,
    is_gift BOOLEAN DEFAULT FALSE,
    gift_message TEXT,
    fulfillment_status ENUM('unfulfilled', 'partially_fulfilled', 'fulfilled', 'cancelled') DEFAULT 'unfulfilled',
    fulfilled_quantity INT UNSIGNED DEFAULT 0,
    warehouse_id INT UNSIGNED,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_order (order_id),
    INDEX idx_product (product_id),
    INDEX idx_variant (variant_id),
    INDEX idx_fulfillment (fulfillment_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Order Status History - Track order status changes
CREATE TABLE IF NOT EXISTS order_status_history (
    history_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id INT UNSIGNED NOT NULL,
    status ENUM('pending', 'processing', 'confirmed', 'shipped', 'delivered', 'cancelled', 'refunded') NOT NULL,
    notes TEXT,
    changed_by INT UNSIGNED, -- Admin user ID
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_order (order_id),
    INDEX idx_status (status),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- Payment Tables
-- ============================================================================

-- Payment Methods - Customer's saved payment methods
CREATE TABLE IF NOT EXISTS payment_methods (
    payment_method_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id INT UNSIGNED NOT NULL,
    type ENUM('credit_card', 'debit_card', 'paypal', 'bank_account', 'digital_wallet') NOT NULL,
    provider VARCHAR(50), -- 'stripe', 'paypal', 'square', etc.
    is_default BOOLEAN DEFAULT FALSE,
    card_brand VARCHAR(50), -- 'visa', 'mastercard', etc.
    card_last_four VARCHAR(4),
    card_exp_month TINYINT,
    card_exp_year SMALLINT,
    billing_address_id INT UNSIGNED,
    token VARCHAR(255), -- Encrypted payment token
    fingerprint VARCHAR(255), -- For duplicate detection
    metadata JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_customer (customer_id),
    INDEX idx_default (customer_id, is_default),
    INDEX idx_type (type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Payment Transactions - All payment activities
CREATE TABLE IF NOT EXISTS payment_transactions (
    transaction_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id INT UNSIGNED NOT NULL,
    payment_method_id INT UNSIGNED,
    transaction_type ENUM('charge', 'refund', 'partial_refund', 'void', 'authorization') NOT NULL,
    amount DECIMAL(12, 2) NOT NULL,
    currency_code VARCHAR(3) DEFAULT 'USD',
    status ENUM('pending', 'processing', 'succeeded', 'failed', 'cancelled') NOT NULL,
    gateway VARCHAR(50), -- Payment gateway used
    gateway_transaction_id VARCHAR(255),
    gateway_response JSON,
    failure_reason VARCHAR(500),
    processed_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_order (order_id),
    INDEX idx_status (status),
    INDEX idx_gateway_id (gateway_transaction_id),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- Shipping Tables
-- ============================================================================

-- Shipping Methods - Available shipping options
CREATE TABLE IF NOT EXISTS shipping_methods (
    shipping_method_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    carrier_name VARCHAR(100) NOT NULL,
    service_name VARCHAR(100) NOT NULL,
    code VARCHAR(50) UNIQUE NOT NULL,
    delivery_days_min INT,
    delivery_days_max INT,
    base_rate DECIMAL(10, 2),
    per_kg_rate DECIMAL(10, 2),
    per_item_rate DECIMAL(10, 2),
    free_shipping_threshold DECIMAL(10, 2),
    max_weight_kg DECIMAL(10, 2),
    countries JSON, -- List of supported country codes
    is_express BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_code (code),
    INDEX idx_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Shipments - Tracking order shipments
CREATE TABLE IF NOT EXISTS shipments (
    shipment_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id INT UNSIGNED NOT NULL,
    warehouse_id INT UNSIGNED,
    shipping_method_id INT UNSIGNED NOT NULL,
    tracking_number VARCHAR(255),
    carrier_name VARCHAR(100),
    status ENUM('pending', 'picked', 'packed', 'shipped', 'in_transit', 'delivered', 'returned', 'lost') DEFAULT 'pending',
    weight_kg DECIMAL(10, 3),
    dimensions_cm JSON,
    shipping_label_url VARCHAR(500),
    shipped_at TIMESTAMP NULL,
    delivered_at TIMESTAMP NULL,
    delivery_signature VARCHAR(255),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_order (order_id),
    INDEX idx_tracking (tracking_number),
    INDEX idx_status (status),
    INDEX idx_warehouse (warehouse_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- Reviews and Ratings Tables
-- ============================================================================

-- Product Reviews - Customer reviews and ratings
CREATE TABLE IF NOT EXISTS product_reviews (
    review_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    product_id INT UNSIGNED NOT NULL,
    variant_id INT UNSIGNED,
    customer_id INT UNSIGNED NOT NULL,
    order_item_id INT UNSIGNED, -- Link to specific purchase
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    title VARCHAR(255),
    review_text TEXT,
    pros TEXT,
    cons TEXT,
    is_verified_purchase BOOLEAN DEFAULT FALSE,
    is_featured BOOLEAN DEFAULT FALSE,
    helpful_count INT UNSIGNED DEFAULT 0,
    unhelpful_count INT UNSIGNED DEFAULT 0,
    admin_reply TEXT,
    admin_reply_at TIMESTAMP NULL,
    status ENUM('pending', 'approved', 'rejected', 'flagged') DEFAULT 'pending',
    images JSON, -- Array of image URLs
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_product (product_id),
    INDEX idx_customer (customer_id),
    INDEX idx_rating (rating),
    INDEX idx_status (status),
    INDEX idx_verified (is_verified_purchase),
    INDEX idx_helpful (helpful_count),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Review Votes - Track helpful/unhelpful votes
CREATE TABLE IF NOT EXISTS review_votes (
    vote_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    review_id INT UNSIGNED NOT NULL,
    customer_id INT UNSIGNED NOT NULL,
    is_helpful BOOLEAN NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_review_customer (review_id, customer_id),
    INDEX idx_review (review_id),
    INDEX idx_customer (customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- Promotions and Discounts Tables
-- ============================================================================

-- Coupons - Discount codes
CREATE TABLE IF NOT EXISTS coupons (
    coupon_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    discount_type ENUM('percentage', 'fixed_amount', 'free_shipping', 'buy_x_get_y') NOT NULL,
    discount_value DECIMAL(10, 2) NOT NULL,
    minimum_amount DECIMAL(10, 2),
    maximum_discount DECIMAL(10, 2),
    applicable_to ENUM('all', 'specific_products', 'specific_categories', 'specific_brands') DEFAULT 'all',
    applicable_ids JSON, -- Array of product/category/brand IDs
    usage_limit INT UNSIGNED,
    usage_limit_per_customer INT UNSIGNED,
    usage_count INT UNSIGNED DEFAULT 0,
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    requires_account BOOLEAN DEFAULT FALSE,
    stackable BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_code (code),
    INDEX idx_active (is_active),
    INDEX idx_valid_dates (valid_from, valid_to)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Coupon Usage - Track coupon usage
CREATE TABLE IF NOT EXISTS coupon_usage (
    usage_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    coupon_id INT UNSIGNED NOT NULL,
    customer_id INT UNSIGNED,
    order_id INT UNSIGNED NOT NULL,
    discount_amount DECIMAL(10, 2) NOT NULL,
    used_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_coupon (coupon_id),
    INDEX idx_customer (customer_id),
    INDEX idx_order (order_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Price Rules - Dynamic pricing rules (sales, bulk discounts)
CREATE TABLE IF NOT EXISTS price_rules (
    rule_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    rule_name VARCHAR(100) NOT NULL,
    rule_type ENUM('sale', 'bulk', 'bundle', 'tiered', 'flash') NOT NULL,
    priority INT DEFAULT 0,
    conditions JSON, -- {"min_quantity": 10, "customer_type": "wholesale", ...}
    discount_type ENUM('percentage', 'fixed_amount', 'fixed_price') NOT NULL,
    discount_value DECIMAL(10, 2) NOT NULL,
    applicable_to ENUM('all', 'specific_products', 'specific_categories', 'specific_brands') DEFAULT 'all',
    applicable_ids JSON,
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_type (rule_type),
    INDEX idx_active (is_active),
    INDEX idx_valid_dates (valid_from, valid_to),
    INDEX idx_priority (priority)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- Analytics and Behavior Tables
-- ============================================================================

-- Page Views - Track product page views
CREATE TABLE IF NOT EXISTS page_views (
    view_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id INT UNSIGNED,
    session_id VARCHAR(128),
    product_id INT UNSIGNED,
    page_type VARCHAR(50), -- 'product', 'category', 'search', 'home', etc.
    page_url VARCHAR(500),
    referrer_url VARCHAR(500),
    ip_address VARCHAR(45),
    user_agent TEXT,
    device_type ENUM('desktop', 'mobile', 'tablet') DEFAULT 'desktop',
    duration_seconds INT UNSIGNED,
    bounce BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_customer (customer_id),
    INDEX idx_session (session_id),
    INDEX idx_product (product_id),
    INDEX idx_created (created_at),
    INDEX idx_page_type (page_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Search Queries - Track what customers search for
CREATE TABLE IF NOT EXISTS search_queries (
    search_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id INT UNSIGNED,
    session_id VARCHAR(128),
    query_text VARCHAR(255) NOT NULL,
    results_count INT UNSIGNED,
    clicked_position INT, -- Which result they clicked (if any)
    clicked_product_id INT UNSIGNED,
    device_type ENUM('desktop', 'mobile', 'tablet') DEFAULT 'desktop',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_customer (customer_id),
    INDEX idx_query (query_text),
    INDEX idx_created (created_at),
    FULLTEXT idx_query_text (query_text)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Recently Viewed - Products recently viewed by customer
CREATE TABLE IF NOT EXISTS recently_viewed (
    view_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id INT UNSIGNED NOT NULL,
    product_id INT UNSIGNED NOT NULL,
    viewed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    view_count INT UNSIGNED DEFAULT 1,
    UNIQUE KEY unique_customer_product (customer_id, product_id),
    INDEX idx_customer_viewed (customer_id, viewed_at),
    INDEX idx_product (product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Product Recommendations - Personalized recommendations
CREATE TABLE IF NOT EXISTS product_recommendations (
    recommendation_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id INT UNSIGNED,
    product_id INT UNSIGNED NOT NULL,
    recommendation_type ENUM('also_bought', 'viewed_together', 'personalized', 'trending', 'similar') NOT NULL,
    score DECIMAL(5, 4) DEFAULT 0.0000, -- Relevance score 0-1
    reason VARCHAR(255), -- "Based on your purchase of..."
    expires_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_customer (customer_id),
    INDEX idx_product (product_id),
    INDEX idx_type (recommendation_type),
    INDEX idx_score (score DESC),
    INDEX idx_expires (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- Customer Service Tables
-- ============================================================================

-- Support Tickets - Customer service requests
CREATE TABLE IF NOT EXISTS support_tickets (
    ticket_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    ticket_number VARCHAR(20) UNIQUE NOT NULL,
    customer_id INT UNSIGNED NOT NULL,
    order_id INT UNSIGNED,
    category ENUM('order', 'product', 'shipping', 'payment', 'return', 'technical', 'other') NOT NULL,
    priority ENUM('low', 'medium', 'high', 'urgent') DEFAULT 'medium',
    status ENUM('open', 'in_progress', 'waiting_customer', 'waiting_internal', 'resolved', 'closed') DEFAULT 'open',
    subject VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    resolution TEXT,
    assigned_to INT UNSIGNED, -- Staff user ID
    resolved_at TIMESTAMP NULL,
    satisfaction_rating INT, -- 1-5 rating
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_ticket_number (ticket_number),
    INDEX idx_customer (customer_id),
    INDEX idx_order (order_id),
    INDEX idx_status (status),
    INDEX idx_priority (priority),
    INDEX idx_assigned (assigned_to)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Returns - Product return requests
CREATE TABLE IF NOT EXISTS returns (
    return_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    return_number VARCHAR(20) UNIQUE NOT NULL,
    order_id INT UNSIGNED NOT NULL,
    customer_id INT UNSIGNED NOT NULL,
    status ENUM('requested', 'approved', 'rejected', 'shipped', 'received', 'processing', 'refunded', 'completed') DEFAULT 'requested',
    reason ENUM('defective', 'wrong_item', 'not_as_described', 'no_longer_needed', 'better_price', 'damaged', 'other') NOT NULL,
    reason_details TEXT,
    return_shipping_method VARCHAR(100),
    return_tracking_number VARCHAR(255),
    refund_amount DECIMAL(12, 2),
    restocking_fee DECIMAL(10, 2) DEFAULT 0.00,
    return_label_url VARCHAR(500),
    received_condition ENUM('new', 'like_new', 'good', 'fair', 'poor', 'damaged'),
    inspection_notes TEXT,
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    approved_at TIMESTAMP NULL,
    received_at TIMESTAMP NULL,
    refunded_at TIMESTAMP NULL,
    INDEX idx_return_number (return_number),
    INDEX idx_order (order_id),
    INDEX idx_customer (customer_id),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Return Items - Items being returned
CREATE TABLE IF NOT EXISTS return_items (
    return_item_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    return_id INT UNSIGNED NOT NULL,
    order_item_id INT UNSIGNED NOT NULL,
    quantity INT UNSIGNED NOT NULL,
    item_condition ENUM('unopened', 'opened', 'used', 'damaged', 'defective') NOT NULL,
    refund_amount DECIMAL(10, 2),
    replacement_sent BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_return (return_id),
    INDEX idx_order_item (order_item_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- Email and Notifications Tables
-- ============================================================================

-- Email Templates - Transactional email templates
CREATE TABLE IF NOT EXISTS email_templates (
    template_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    template_code VARCHAR(50) UNIQUE NOT NULL,
    template_name VARCHAR(100) NOT NULL,
    subject VARCHAR(255) NOT NULL,
    html_content TEXT NOT NULL,
    text_content TEXT,
    variables JSON, -- List of available variables
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_code (template_code),
    INDEX idx_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Email Queue - Emails to be sent
CREATE TABLE IF NOT EXISTS email_queue (
    queue_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id INT UNSIGNED,
    to_email VARCHAR(255) NOT NULL,
    template_id INT UNSIGNED,
    subject VARCHAR(255),
    variables JSON, -- Template variables
    priority INT DEFAULT 0,
    status ENUM('pending', 'sending', 'sent', 'failed', 'cancelled') DEFAULT 'pending',
    attempts INT DEFAULT 0,
    sent_at TIMESTAMP NULL,
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_status (status),
    INDEX idx_priority (priority),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Display confirmation
SELECT 'All e-commerce tables created successfully' AS Status;
SELECT COUNT(*) AS table_count FROM information_schema.tables WHERE table_schema = 'ecommerce';
