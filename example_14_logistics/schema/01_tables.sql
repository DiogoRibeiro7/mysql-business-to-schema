-- Logistics & Supply Chain Management System
-- Core tables for warehouse, inventory, and transportation management

-- Create database
CREATE DATABASE IF NOT EXISTS logistics_db;
USE logistics_db;

-- ========================================
-- WAREHOUSE MANAGEMENT
-- ========================================

-- Warehouses/Distribution Centers
CREATE TABLE warehouses (
    warehouse_id INT PRIMARY KEY AUTO_INCREMENT,
    warehouse_code VARCHAR(20) UNIQUE NOT NULL,
    warehouse_name VARCHAR(100) NOT NULL,
    warehouse_type ENUM('DC', 'FC', 'CROSS_DOCK', 'COLD_STORAGE', 'BONDED') NOT NULL,
    address_line1 VARCHAR(100) NOT NULL,
    address_line2 VARCHAR(100),
    city VARCHAR(50) NOT NULL,
    state_province VARCHAR(50),
    postal_code VARCHAR(20),
    country_code CHAR(2) NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    total_capacity_cbm DECIMAL(12, 2),
    available_capacity_cbm DECIMAL(12, 2),
    operating_hours JSON,
    capabilities SET('HAZMAT', 'REFRIGERATED', 'HIGH_VALUE', 'OVERSIZED', 'PHARMA'),
    manager_name VARCHAR(100),
    contact_phone VARCHAR(20),
    contact_email VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_warehouse_type (warehouse_type),
    INDEX idx_location (country_code, state_province, city),
    INDEX idx_active (is_active),
    SPATIAL INDEX idx_coordinates (latitude, longitude)
);

-- Warehouse Zones
CREATE TABLE warehouse_zones (
    zone_id INT PRIMARY KEY AUTO_INCREMENT,
    warehouse_id INT NOT NULL,
    zone_code VARCHAR(20) NOT NULL,
    zone_name VARCHAR(100),
    zone_type ENUM('RECEIVING', 'STORAGE', 'PICKING', 'PACKING', 'SHIPPING', 'RETURNS', 'QUARANTINE') NOT NULL,
    temperature_range VARCHAR(50),
    max_weight_kg DECIMAL(10, 2),
    max_height_meters DECIMAL(5, 2),
    total_locations INT DEFAULT 0,
    occupied_locations INT DEFAULT 0,
    aisle_width_meters DECIMAL(5, 2),
    is_automated BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id) ON DELETE CASCADE,
    UNIQUE KEY uk_warehouse_zone (warehouse_id, zone_code),
    INDEX idx_zone_type (zone_type),
    INDEX idx_zone_occupancy (warehouse_id, occupied_locations)
);

-- Storage Bins/Locations
CREATE TABLE warehouse_bins (
    bin_id INT PRIMARY KEY AUTO_INCREMENT,
    zone_id INT NOT NULL,
    bin_code VARCHAR(30) NOT NULL,
    aisle VARCHAR(10),
    rack VARCHAR(10),
    level VARCHAR(10),
    position VARCHAR(10),
    bin_type ENUM('FLOOR', 'PALLET_RACK', 'SHELF', 'BULK', 'CANTILEVER') NOT NULL,
    max_weight_kg DECIMAL(10, 2),
    dimensions_lwh VARCHAR(50),
    volume_cbm DECIMAL(8, 3),
    is_occupied BOOLEAN DEFAULT FALSE,
    current_product_id INT,
    current_quantity DECIMAL(12, 3),
    last_counted_date DATE,
    is_locked BOOLEAN DEFAULT FALSE,
    lock_reason VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (zone_id) REFERENCES warehouse_zones(zone_id) ON DELETE CASCADE,
    UNIQUE KEY uk_bin_code (zone_id, bin_code),
    INDEX idx_bin_availability (zone_id, is_occupied, is_locked),
    INDEX idx_current_product (current_product_id)
);

-- Docking Stations
CREATE TABLE docking_stations (
    dock_id INT PRIMARY KEY AUTO_INCREMENT,
    warehouse_id INT NOT NULL,
    dock_number VARCHAR(20) NOT NULL,
    dock_type ENUM('RECEIVING', 'SHIPPING', 'BOTH') NOT NULL,
    door_height_meters DECIMAL(5, 2),
    door_width_meters DECIMAL(5, 2),
    has_dock_leveler BOOLEAN DEFAULT TRUE,
    has_dock_seal BOOLEAN DEFAULT TRUE,
    current_vehicle_id INT,
    current_shipment_id INT,
    status ENUM('AVAILABLE', 'OCCUPIED', 'SCHEDULED', 'MAINTENANCE') DEFAULT 'AVAILABLE',
    next_available_time DATETIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id) ON DELETE CASCADE,
    UNIQUE KEY uk_dock_number (warehouse_id, dock_number),
    INDEX idx_dock_status (warehouse_id, status),
    INDEX idx_dock_availability (status, next_available_time)
);

-- ========================================
-- PRODUCT & INVENTORY MANAGEMENT
-- ========================================

-- Product Master
CREATE TABLE products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    sku VARCHAR(50) UNIQUE NOT NULL,
    product_name VARCHAR(200) NOT NULL,
    product_description TEXT,
    category VARCHAR(100),
    subcategory VARCHAR(100),
    brand VARCHAR(100),
    unit_of_measure ENUM('EACH', 'CASE', 'PALLET', 'KG', 'LB', 'LITER', 'METER') NOT NULL,
    weight_kg DECIMAL(10, 3),
    dimensions_lwh VARCHAR(50),
    volume_cbm DECIMAL(8, 3),
    is_hazmat BOOLEAN DEFAULT FALSE,
    hazmat_class VARCHAR(20),
    requires_temperature_control BOOLEAN DEFAULT FALSE,
    min_temperature_celsius DECIMAL(5, 2),
    max_temperature_celsius DECIMAL(5, 2),
    shelf_life_days INT,
    is_serialized BOOLEAN DEFAULT FALSE,
    is_lot_controlled BOOLEAN DEFAULT FALSE,
    reorder_point INT,
    reorder_quantity INT,
    lead_time_days INT,
    unit_cost DECIMAL(10, 2),
    selling_price DECIMAL(10, 2),
    abc_classification CHAR(1),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_sku (sku),
    INDEX idx_category (category, subcategory),
    INDEX idx_abc_class (abc_classification),
    INDEX idx_hazmat (is_hazmat, hazmat_class),
    FULLTEXT idx_product_search (product_name, product_description)
);

-- Inventory Levels
CREATE TABLE inventory_levels (
    inventory_id INT PRIMARY KEY AUTO_INCREMENT,
    warehouse_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity_on_hand DECIMAL(12, 3) NOT NULL DEFAULT 0,
    quantity_available DECIMAL(12, 3) NOT NULL DEFAULT 0,
    quantity_allocated DECIMAL(12, 3) NOT NULL DEFAULT 0,
    quantity_in_transit DECIMAL(12, 3) NOT NULL DEFAULT 0,
    quantity_damaged DECIMAL(12, 3) NOT NULL DEFAULT 0,
    quantity_quarantine DECIMAL(12, 3) NOT NULL DEFAULT 0,
    average_cost DECIMAL(10, 4),
    last_received_date DATETIME,
    last_counted_date DATETIME,
    last_shipped_date DATETIME,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    UNIQUE KEY uk_warehouse_product (warehouse_id, product_id),
    INDEX idx_availability (product_id, warehouse_id, quantity_available),
    INDEX idx_reorder_check (product_id, quantity_available)
);

-- Product Batches/Lots
CREATE TABLE product_batches (
    batch_id INT PRIMARY KEY AUTO_INCREMENT,
    product_id INT NOT NULL,
    warehouse_id INT NOT NULL,
    batch_number VARCHAR(50) NOT NULL,
    lot_number VARCHAR(50),
    serial_numbers JSON,
    manufacture_date DATE,
    expiry_date DATE,
    received_date DATETIME NOT NULL,
    quantity_received DECIMAL(12, 3) NOT NULL,
    quantity_remaining DECIMAL(12, 3) NOT NULL,
    supplier_id INT,
    purchase_order_id INT,
    quality_status ENUM('PASSED', 'FAILED', 'PENDING', 'CONDITIONAL') DEFAULT 'PENDING',
    quality_certificate_url VARCHAR(500),
    storage_conditions TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id),
    UNIQUE KEY uk_batch_number (product_id, batch_number),
    INDEX idx_expiry (expiry_date, quantity_remaining),
    INDEX idx_batch_availability (product_id, warehouse_id, quantity_remaining, expiry_date)
);

-- Inventory Movements
CREATE TABLE inventory_movements (
    movement_id INT PRIMARY KEY AUTO_INCREMENT,
    movement_type ENUM('RECEIPT', 'ISSUE', 'TRANSFER', 'ADJUSTMENT', 'RETURN', 'DAMAGE', 'DISPOSAL') NOT NULL,
    reference_type ENUM('PO', 'SO', 'TO', 'ADJUSTMENT', 'RMA') NOT NULL,
    reference_id INT,
    product_id INT NOT NULL,
    batch_id INT,
    from_warehouse_id INT,
    from_bin_id INT,
    to_warehouse_id INT,
    to_bin_id INT,
    quantity DECIMAL(12, 3) NOT NULL,
    unit_cost DECIMAL(10, 4),
    total_cost DECIMAL(15, 2),
    movement_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    performed_by INT,
    reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (batch_id) REFERENCES product_batches(batch_id),
    FOREIGN KEY (from_warehouse_id) REFERENCES warehouses(warehouse_id),
    FOREIGN KEY (to_warehouse_id) REFERENCES warehouses(warehouse_id),
    FOREIGN KEY (from_bin_id) REFERENCES warehouse_bins(bin_id),
    FOREIGN KEY (to_bin_id) REFERENCES warehouse_bins(bin_id),
    INDEX idx_movement_date (movement_date),
    INDEX idx_movement_type (movement_type, movement_date),
    INDEX idx_product_movements (product_id, movement_date),
    INDEX idx_warehouse_movements (from_warehouse_id, to_warehouse_id, movement_date)
) PARTITION BY RANGE (YEAR(movement_date)) (
    PARTITION p_2023 VALUES LESS THAN (2024),
    PARTITION p_2024 VALUES LESS THAN (2025),
    PARTITION p_2025 VALUES LESS THAN (2026),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);

-- ========================================
-- ORDERS & FULFILLMENT
-- ========================================

-- Suppliers
CREATE TABLE suppliers (
    supplier_id INT PRIMARY KEY AUTO_INCREMENT,
    supplier_code VARCHAR(30) UNIQUE NOT NULL,
    supplier_name VARCHAR(200) NOT NULL,
    supplier_type ENUM('MANUFACTURER', 'DISTRIBUTOR', 'WHOLESALER', 'DROPSHIPPER') NOT NULL,
    tax_id VARCHAR(50),
    address_line1 VARCHAR(100),
    address_line2 VARCHAR(100),
    city VARCHAR(50),
    state_province VARCHAR(50),
    postal_code VARCHAR(20),
    country_code CHAR(2),
    contact_name VARCHAR(100),
    contact_phone VARCHAR(20),
    contact_email VARCHAR(100),
    payment_terms VARCHAR(50),
    currency_code CHAR(3),
    credit_limit DECIMAL(15, 2),
    lead_time_days INT,
    minimum_order_value DECIMAL(10, 2),
    performance_score DECIMAL(3, 2),
    is_preferred BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    certifications JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_supplier_type (supplier_type),
    INDEX idx_performance (performance_score),
    INDEX idx_active_preferred (is_active, is_preferred)
);

-- Customers
CREATE TABLE customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_code VARCHAR(30) UNIQUE NOT NULL,
    customer_name VARCHAR(200) NOT NULL,
    customer_type ENUM('B2B', 'B2C', 'MARKETPLACE', 'INTERNAL') NOT NULL,
    tax_id VARCHAR(50),
    billing_address_line1 VARCHAR(100),
    billing_address_line2 VARCHAR(100),
    billing_city VARCHAR(50),
    billing_state_province VARCHAR(50),
    billing_postal_code VARCHAR(20),
    billing_country_code CHAR(2),
    shipping_same_as_billing BOOLEAN DEFAULT TRUE,
    shipping_address_line1 VARCHAR(100),
    shipping_address_line2 VARCHAR(100),
    shipping_city VARCHAR(50),
    shipping_state_province VARCHAR(50),
    shipping_postal_code VARCHAR(20),
    shipping_country_code CHAR(2),
    contact_name VARCHAR(100),
    contact_phone VARCHAR(20),
    contact_email VARCHAR(100),
    payment_terms VARCHAR(50),
    credit_limit DECIMAL(15, 2),
    current_balance DECIMAL(15, 2) DEFAULT 0,
    priority_level ENUM('STANDARD', 'SILVER', 'GOLD', 'PLATINUM') DEFAULT 'STANDARD',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_customer_type (customer_type),
    INDEX idx_priority (priority_level),
    INDEX idx_location (shipping_country_code, shipping_state_province)
);

-- Purchase Orders (Inbound)
CREATE TABLE purchase_orders (
    po_id INT PRIMARY KEY AUTO_INCREMENT,
    po_number VARCHAR(50) UNIQUE NOT NULL,
    supplier_id INT NOT NULL,
    warehouse_id INT NOT NULL,
    order_date DATE NOT NULL,
    expected_delivery_date DATE,
    actual_delivery_date DATE,
    total_amount DECIMAL(15, 2),
    currency_code CHAR(3),
    status ENUM('DRAFT', 'SUBMITTED', 'CONFIRMED', 'SHIPPED', 'PARTIAL', 'RECEIVED', 'CANCELLED') NOT NULL,
    payment_status ENUM('PENDING', 'PARTIAL', 'PAID', 'REFUNDED') DEFAULT 'PENDING',
    notes TEXT,
    created_by INT,
    approved_by INT,
    approval_date DATETIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id),
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id),
    INDEX idx_po_status (status),
    INDEX idx_po_dates (order_date, expected_delivery_date),
    INDEX idx_supplier_orders (supplier_id, order_date)
);

-- Purchase Order Items
CREATE TABLE purchase_order_items (
    po_item_id INT PRIMARY KEY AUTO_INCREMENT,
    po_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity_ordered DECIMAL(12, 3) NOT NULL,
    quantity_received DECIMAL(12, 3) DEFAULT 0,
    unit_price DECIMAL(10, 4),
    line_total DECIMAL(15, 2),
    discount_percent DECIMAL(5, 2),
    tax_amount DECIMAL(10, 2),
    expected_delivery_date DATE,
    notes TEXT,
    FOREIGN KEY (po_id) REFERENCES purchase_orders(po_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    INDEX idx_po_items (po_id),
    INDEX idx_product_orders (product_id)
);

-- Sales Orders (Outbound)
CREATE TABLE sales_orders (
    so_id INT PRIMARY KEY AUTO_INCREMENT,
    so_number VARCHAR(50) UNIQUE NOT NULL,
    customer_id INT NOT NULL,
    order_date DATETIME NOT NULL,
    requested_delivery_date DATE,
    promised_delivery_date DATE,
    actual_delivery_date DATE,
    shipping_address_line1 VARCHAR(100),
    shipping_address_line2 VARCHAR(100),
    shipping_city VARCHAR(50),
    shipping_state_province VARCHAR(50),
    shipping_postal_code VARCHAR(20),
    shipping_country_code CHAR(2),
    subtotal_amount DECIMAL(15, 2),
    discount_amount DECIMAL(10, 2),
    tax_amount DECIMAL(10, 2),
    shipping_cost DECIMAL(10, 2),
    total_amount DECIMAL(15, 2),
    currency_code CHAR(3),
    status ENUM('PENDING', 'CONFIRMED', 'PICKING', 'PACKED', 'SHIPPED', 'DELIVERED', 'CANCELLED', 'RETURNED') NOT NULL,
    payment_status ENUM('PENDING', 'AUTHORIZED', 'CAPTURED', 'PARTIAL', 'PAID', 'REFUNDED') DEFAULT 'PENDING',
    fulfillment_priority ENUM('STANDARD', 'EXPRESS', 'URGENT') DEFAULT 'STANDARD',
    special_instructions TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    INDEX idx_so_status (status),
    INDEX idx_so_dates (order_date, requested_delivery_date),
    INDEX idx_customer_orders (customer_id, order_date),
    INDEX idx_fulfillment (status, fulfillment_priority)
);

-- Sales Order Items
CREATE TABLE sales_order_items (
    so_item_id INT PRIMARY KEY AUTO_INCREMENT,
    so_id INT NOT NULL,
    product_id INT NOT NULL,
    warehouse_id INT,
    quantity_ordered DECIMAL(12, 3) NOT NULL,
    quantity_allocated DECIMAL(12, 3) DEFAULT 0,
    quantity_picked DECIMAL(12, 3) DEFAULT 0,
    quantity_shipped DECIMAL(12, 3) DEFAULT 0,
    unit_price DECIMAL(10, 4),
    discount_percent DECIMAL(5, 2),
    tax_rate DECIMAL(5, 2),
    line_total DECIMAL(15, 2),
    allocated_batch_id INT,
    backorder_quantity DECIMAL(12, 3) DEFAULT 0,
    notes TEXT,
    FOREIGN KEY (so_id) REFERENCES sales_orders(so_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id),
    FOREIGN KEY (allocated_batch_id) REFERENCES product_batches(batch_id),
    INDEX idx_so_items (so_id),
    INDEX idx_product_sales (product_id),
    INDEX idx_allocation_status (so_id, quantity_allocated, quantity_picked)
);

-- ========================================
-- SHIPPING & TRANSPORTATION
-- ========================================

-- Carriers
CREATE TABLE carriers (
    carrier_id INT PRIMARY KEY AUTO_INCREMENT,
    carrier_code VARCHAR(30) UNIQUE NOT NULL,
    carrier_name VARCHAR(200) NOT NULL,
    carrier_type ENUM('PARCEL', 'LTL', 'FTL', 'AIR', 'OCEAN', 'RAIL', 'COURIER') NOT NULL,
    scac_code VARCHAR(10),
    mc_number VARCHAR(20),
    dot_number VARCHAR(20),
    contact_name VARCHAR(100),
    contact_phone VARCHAR(20),
    contact_email VARCHAR(100),
    api_endpoint VARCHAR(500),
    api_key_encrypted VARCHAR(500),
    tracking_url_template VARCHAR(500),
    insurance_coverage DECIMAL(15, 2),
    liability_limit DECIMAL(15, 2),
    performance_score DECIMAL(3, 2),
    on_time_percentage DECIMAL(5, 2),
    damage_claim_rate DECIMAL(5, 2),
    is_preferred BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    supported_services JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_carrier_type (carrier_type),
    INDEX idx_performance (performance_score, on_time_percentage),
    INDEX idx_active_preferred (is_active, is_preferred)
);

-- Carrier Services
CREATE TABLE carrier_services (
    service_id INT PRIMARY KEY AUTO_INCREMENT,
    carrier_id INT NOT NULL,
    service_code VARCHAR(50) NOT NULL,
    service_name VARCHAR(100) NOT NULL,
    service_type ENUM('GROUND', 'EXPRESS', 'OVERNIGHT', 'SAME_DAY', 'ECONOMY', 'PRIORITY') NOT NULL,
    transit_time_days INT,
    cutoff_time TIME,
    delivery_commitment VARCHAR(100),
    max_weight_kg DECIMAL(10, 2),
    max_dimensions_cm VARCHAR(50),
    supports_cod BOOLEAN DEFAULT FALSE,
    supports_insurance BOOLEAN DEFAULT TRUE,
    supports_signature BOOLEAN DEFAULT TRUE,
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (carrier_id) REFERENCES carriers(carrier_id) ON DELETE CASCADE,
    UNIQUE KEY uk_carrier_service (carrier_id, service_code),
    INDEX idx_service_type (service_type),
    INDEX idx_transit_time (transit_time_days)
);

-- Shipments
CREATE TABLE shipments (
    shipment_id INT PRIMARY KEY AUTO_INCREMENT,
    shipment_number VARCHAR(50) UNIQUE NOT NULL,
    shipment_type ENUM('INBOUND', 'OUTBOUND', 'TRANSFER', 'RETURN') NOT NULL,
    reference_type ENUM('PO', 'SO', 'TO', 'RMA') NOT NULL,
    reference_id INT,
    carrier_id INT,
    service_id INT,
    tracking_number VARCHAR(100),
    from_warehouse_id INT,
    to_warehouse_id INT,
    origin_address JSON,
    destination_address JSON,
    pickup_date DATETIME,
    delivery_date DATETIME,
    actual_delivery_date DATETIME,
    total_packages INT,
    total_weight_kg DECIMAL(10, 2),
    total_volume_cbm DECIMAL(10, 3),
    declared_value DECIMAL(15, 2),
    insurance_amount DECIMAL(15, 2),
    shipping_cost DECIMAL(10, 2),
    fuel_surcharge DECIMAL(10, 2),
    other_charges DECIMAL(10, 2),
    total_cost DECIMAL(15, 2),
    status ENUM('PENDING', 'READY', 'PICKED_UP', 'IN_TRANSIT', 'OUT_FOR_DELIVERY', 'DELIVERED', 'EXCEPTION', 'RETURNED') NOT NULL,
    status_details TEXT,
    pod_signature VARCHAR(200),
    pod_timestamp DATETIME,
    temperature_controlled BOOLEAN DEFAULT FALSE,
    temperature_range VARCHAR(50),
    special_handling JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (carrier_id) REFERENCES carriers(carrier_id),
    FOREIGN KEY (service_id) REFERENCES carrier_services(service_id),
    FOREIGN KEY (from_warehouse_id) REFERENCES warehouses(warehouse_id),
    FOREIGN KEY (to_warehouse_id) REFERENCES warehouses(warehouse_id),
    INDEX idx_tracking (tracking_number),
    INDEX idx_shipment_status (status, delivery_date),
    INDEX idx_shipment_dates (pickup_date, delivery_date),
    INDEX idx_reference (reference_type, reference_id)
) PARTITION BY RANGE (YEAR(created_at)) (
    PARTITION p_2023 VALUES LESS THAN (2024),
    PARTITION p_2024 VALUES LESS THAN (2025),
    PARTITION p_2025 VALUES LESS THAN (2026),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);

-- Shipment Tracking
CREATE TABLE shipment_tracking (
    tracking_id INT PRIMARY KEY AUTO_INCREMENT,
    shipment_id INT NOT NULL,
    status_code VARCHAR(50),
    status_description TEXT,
    location_city VARCHAR(100),
    location_state VARCHAR(50),
    location_country CHAR(2),
    location_zip VARCHAR(20),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    event_timestamp DATETIME NOT NULL,
    carrier_status_code VARCHAR(50),
    exception_type VARCHAR(100),
    exception_description TEXT,
    estimated_delivery DATETIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (shipment_id) REFERENCES shipments(shipment_id) ON DELETE CASCADE,
    INDEX idx_shipment_events (shipment_id, event_timestamp),
    INDEX idx_tracking_status (status_code, event_timestamp)
) PARTITION BY RANGE (YEAR(event_timestamp)) (
    PARTITION p_2023 VALUES LESS THAN (2024),
    PARTITION p_2024 VALUES LESS THAN (2025),
    PARTITION p_2025 VALUES LESS THAN (2026),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);

-- ========================================
-- FLEET & VEHICLE MANAGEMENT
-- ========================================

-- Vehicles
CREATE TABLE vehicles (
    vehicle_id INT PRIMARY KEY AUTO_INCREMENT,
    vehicle_number VARCHAR(50) UNIQUE NOT NULL,
    vehicle_type ENUM('VAN', 'TRUCK', 'TRAILER', 'CONTAINER', 'REFRIGERATED', 'FLATBED', 'TANKER') NOT NULL,
    make VARCHAR(50),
    model VARCHAR(50),
    year INT,
    vin VARCHAR(17),
    license_plate VARCHAR(20),
    registration_state VARCHAR(50),
    ownership_type ENUM('OWNED', 'LEASED', 'RENTED', 'CONTRACTOR') NOT NULL,
    capacity_kg DECIMAL(10, 2),
    capacity_cbm DECIMAL(10, 2),
    fuel_type ENUM('DIESEL', 'GASOLINE', 'ELECTRIC', 'HYBRID', 'CNG') NOT NULL,
    fuel_efficiency_km_per_liter DECIMAL(5, 2),
    current_odometer_km INT,
    last_service_date DATE,
    next_service_date DATE,
    insurance_policy_number VARCHAR(50),
    insurance_expiry_date DATE,
    current_location_lat DECIMAL(10, 8),
    current_location_lng DECIMAL(11, 8),
    current_status ENUM('AVAILABLE', 'IN_TRANSIT', 'LOADING', 'UNLOADING', 'MAINTENANCE', 'OUT_OF_SERVICE') DEFAULT 'AVAILABLE',
    assigned_driver_id INT,
    home_warehouse_id INT,
    is_active BOOLEAN DEFAULT TRUE,
    telematics_device_id VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (home_warehouse_id) REFERENCES warehouses(warehouse_id),
    INDEX idx_vehicle_type (vehicle_type),
    INDEX idx_vehicle_status (current_status),
    INDEX idx_maintenance_due (next_service_date)
);

-- Drivers
CREATE TABLE drivers (
    driver_id INT PRIMARY KEY AUTO_INCREMENT,
    employee_id VARCHAR(50) UNIQUE,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    license_number VARCHAR(50) NOT NULL,
    license_class VARCHAR(20),
    license_expiry_date DATE,
    license_state VARCHAR(50),
    phone_number VARCHAR(20),
    email VARCHAR(100),
    emergency_contact_name VARCHAR(100),
    emergency_contact_phone VARCHAR(20),
    hire_date DATE,
    home_base_warehouse_id INT,
    current_vehicle_id INT,
    hours_of_service_remaining DECIMAL(5, 2),
    last_drug_test_date DATE,
    medical_certificate_expiry DATE,
    safety_score DECIMAL(3, 2),
    total_miles_driven INT DEFAULT 0,
    total_deliveries INT DEFAULT 0,
    status ENUM('AVAILABLE', 'DRIVING', 'RESTING', 'OFF_DUTY', 'ON_LEAVE') DEFAULT 'AVAILABLE',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (home_base_warehouse_id) REFERENCES warehouses(warehouse_id),
    FOREIGN KEY (current_vehicle_id) REFERENCES vehicles(vehicle_id),
    INDEX idx_driver_status (status),
    INDEX idx_license_expiry (license_expiry_date),
    INDEX idx_safety_score (safety_score)
);

-- Routes
CREATE TABLE routes (
    route_id INT PRIMARY KEY AUTO_INCREMENT,
    route_code VARCHAR(50) UNIQUE NOT NULL,
    route_name VARCHAR(100),
    route_type ENUM('DELIVERY', 'PICKUP', 'MILK_RUN', 'LINEHAUL', 'LAST_MILE') NOT NULL,
    origin_warehouse_id INT NOT NULL,
    destination_warehouse_id INT,
    total_distance_km DECIMAL(10, 2),
    estimated_duration_hours DECIMAL(5, 2),
    stops JSON,
    preferred_departure_time TIME,
    service_days SET('MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (origin_warehouse_id) REFERENCES warehouses(warehouse_id),
    FOREIGN KEY (destination_warehouse_id) REFERENCES warehouses(warehouse_id),
    INDEX idx_route_type (route_type),
    INDEX idx_route_warehouses (origin_warehouse_id, destination_warehouse_id)
);

-- Delivery Runs
CREATE TABLE delivery_runs (
    run_id INT PRIMARY KEY AUTO_INCREMENT,
    run_date DATE NOT NULL,
    route_id INT,
    vehicle_id INT NOT NULL,
    driver_id INT NOT NULL,
    planned_start_time DATETIME,
    actual_start_time DATETIME,
    planned_end_time DATETIME,
    actual_end_time DATETIME,
    total_stops INT,
    completed_stops INT DEFAULT 0,
    total_packages INT,
    delivered_packages INT DEFAULT 0,
    total_distance_km DECIMAL(10, 2),
    fuel_consumed_liters DECIMAL(10, 2),
    status ENUM('PLANNED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED') DEFAULT 'PLANNED',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (route_id) REFERENCES routes(route_id),
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id),
    FOREIGN KEY (driver_id) REFERENCES drivers(driver_id),
    INDEX idx_run_date (run_date),
    INDEX idx_run_status (status, run_date),
    INDEX idx_driver_runs (driver_id, run_date)
);

-- ========================================
-- ANALYTICS & REPORTING
-- ========================================

-- KPI Metrics
CREATE TABLE kpi_metrics (
    metric_id INT PRIMARY KEY AUTO_INCREMENT,
    metric_date DATE NOT NULL,
    metric_type ENUM('DAILY', 'WEEKLY', 'MONTHLY') NOT NULL,
    warehouse_id INT,

    -- Inventory KPIs
    inventory_turnover_ratio DECIMAL(10, 2),
    stockout_incidents INT,
    inventory_accuracy_percent DECIMAL(5, 2),
    carrying_cost DECIMAL(15, 2),

    -- Order Fulfillment KPIs
    orders_processed INT,
    perfect_order_rate DECIMAL(5, 2),
    order_cycle_time_hours DECIMAL(10, 2),
    fill_rate_percent DECIMAL(5, 2),
    backorder_rate_percent DECIMAL(5, 2),

    -- Warehouse KPIs
    warehouse_utilization_percent DECIMAL(5, 2),
    picking_accuracy_percent DECIMAL(5, 2),
    putaway_cycle_time_minutes DECIMAL(10, 2),
    labor_productivity_units_per_hour DECIMAL(10, 2),

    -- Transportation KPIs
    on_time_delivery_percent DECIMAL(5, 2),
    freight_cost_per_unit DECIMAL(10, 2),
    delivery_success_rate DECIMAL(5, 2),
    average_delivery_time_hours DECIMAL(10, 2),
    fuel_efficiency_km_per_liter DECIMAL(10, 2),

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id),
    UNIQUE KEY uk_metric_date (metric_date, metric_type, warehouse_id),
    INDEX idx_metric_type (metric_type, metric_date),
    INDEX idx_warehouse_metrics (warehouse_id, metric_date)
);

-- Audit Log
CREATE TABLE audit_log (
    audit_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    table_name VARCHAR(50) NOT NULL,
    record_id INT NOT NULL,
    action ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    changed_by INT,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    old_values JSON,
    new_values JSON,
    ip_address VARCHAR(45),
    user_agent VARCHAR(255),
    INDEX idx_audit_table (table_name, record_id),
    INDEX idx_audit_time (changed_at),
    INDEX idx_audit_user (changed_by)
) PARTITION BY RANGE (YEAR(changed_at)) (
    PARTITION p_2023 VALUES LESS THAN (2024),
    PARTITION p_2024 VALUES LESS THAN (2025),
    PARTITION p_2025 VALUES LESS THAN (2026),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);