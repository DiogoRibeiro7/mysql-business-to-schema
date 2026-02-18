-- PostgreSQL Schema
-- Converted from MySQL on 2026-02-17T23:11:17.394293
-- Generator: MySQL to PostgreSQL Converter

-- Enum Types
CREATE TYPE warehouses_status AS ENUM ('DC', 'FC', 'CROSS_DOCK', 'COLD_STORAGE', 'BONDED');
CREATE TYPE warehouse_zones_status AS ENUM ('RECEIVING', 'STORAGE', 'PICKING', 'PACKING', 'SHIPPING', 'RETURNS', 'QUARANTINE');
CREATE TYPE warehouse_bins_status AS ENUM ('FLOOR', 'PALLET_RACK', 'SHELF', 'BULK', 'CANTILEVER');
CREATE TYPE docking_stations_status AS ENUM ('AVAILABLE', 'OCCUPIED', 'SCHEDULED', 'MAINTENANCE');
CREATE TYPE products_status AS ENUM ('EACH', 'CASE', 'PALLET', 'KG', 'LB', 'LITER', 'METER');
CREATE TYPE product_batches_status AS ENUM ('PASSED', 'FAILED', 'PENDING', 'CONDITIONAL');
CREATE TYPE inventory_movements_status AS ENUM ('PO', 'SO', 'TO', 'ADJUSTMENT', 'RMA');
CREATE TYPE suppliers_status AS ENUM ('MANUFACTURER', 'DISTRIBUTOR', 'WHOLESALER', 'DROPSHIPPER');
CREATE TYPE customers_status AS ENUM ('STANDARD', 'SILVER', 'GOLD', 'PLATINUM');
CREATE TYPE purchase_orders_status AS ENUM ('PENDING', 'PARTIAL', 'PAID', 'REFUNDED');
CREATE TYPE sales_orders_status AS ENUM ('STANDARD', 'EXPRESS', 'URGENT');
CREATE TYPE carriers_status AS ENUM ('PARCEL', 'LTL', 'FTL', 'AIR', 'OCEAN', 'RAIL', 'COURIER');
CREATE TYPE carrier_services_status AS ENUM ('GROUND', 'EXPRESS', 'OVERNIGHT', 'SAME_DAY', 'ECONOMY', 'PRIORITY');
CREATE TYPE shipments_status AS ENUM ('PENDING', 'READY', 'PICKED_UP', 'IN_TRANSIT', 'OUT_FOR_DELIVERY', 'DELIVERED', 'EXCEPTION', 'RETURNED');
CREATE TYPE vehicles_status AS ENUM ('AVAILABLE', 'IN_TRANSIT', 'LOADING', 'UNLOADING', 'MAINTENANCE', 'OUT_OF_SERVICE');
CREATE TYPE drivers_status AS ENUM ('AVAILABLE', 'DRIVING', 'RESTING', 'OFF_DUTY', 'ON_LEAVE');
CREATE TYPE routes_status AS ENUM ('DELIVERY', 'PICKUP', 'MILK_RUN', 'LINEHAUL', 'LAST_MILE');
CREATE TYPE delivery_runs_status AS ENUM ('PLANNED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED');
CREATE TYPE kpi_metrics_status AS ENUM ('DAILY', 'WEEKLY', 'MONTHLY');
CREATE TYPE audit_log_status AS ENUM ('INSERT', 'UPDATE', 'DELETE');

-- Create database (run as superuser)
-- CREATE DATABASE logistics_db;
-- \c logistics_db

CREATE TABLE IF NOT EXISTS warehouses (
    warehouse_name VARCHAR(100) NOT NULL,
    warehouse_type warehouses_status NOT NULL,
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
    operating_hours JSONB,
    capabilities TEXT[],
    manager_name VARCHAR(100),
    contact_phone VARCHAR(20),
    contact_email VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS warehouse_zones (
    warehouse_id INTEGER NOT NULL,
    zone_code VARCHAR(20) NOT NULL,
    zone_name VARCHAR(100),
    zone_type warehouse_zones_status NOT NULL,
    temperature_range VARCHAR(50),
    max_weight_kg DECIMAL(10, 2),
    max_height_meters DECIMAL(5, 2),
    total_locations INTEGER DEFAULT 0,
    occupied_locations INTEGER DEFAULT 0,
    aisle_width_meters DECIMAL(5, 2),
    is_automated BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (warehouse_id, zone_code)
);

ALTER TABLE warehouse_zones ADD CONSTRAINT fk_warehouse_zones_warehouse_id FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id) ON DELETE CASCADE;
CREATE TABLE IF NOT EXISTS warehouse_bins (
    zone_id INTEGER NOT NULL,
    bin_code VARCHAR(30) NOT NULL,
    aisle VARCHAR(10),
    rack VARCHAR(10),
    level VARCHAR(10),
    position VARCHAR(10),
    bin_type warehouse_bins_status NOT NULL,
    max_weight_kg DECIMAL(10, 2),
    dimensions_lwh VARCHAR(50),
    volume_cbm DECIMAL(8, 3),
    is_occupied BOOLEAN DEFAULT FALSE,
    current_product_id INTEGER,
    current_quantity DECIMAL(12, 3),
    last_counted_date DATE,
    is_locked BOOLEAN DEFAULT FALSE,
    lock_reason VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (zone_id, bin_code)
);

ALTER TABLE warehouse_bins ADD CONSTRAINT fk_warehouse_bins_zone_id FOREIGN KEY (zone_id) REFERENCES warehouse_zones(zone_id) ON DELETE CASCADE;
CREATE TABLE IF NOT EXISTS docking_stations (
    warehouse_id INTEGER NOT NULL,
    dock_number VARCHAR(20) NOT NULL,
    dock_type docking_stations_status NOT NULL,
    door_height_meters DECIMAL(5, 2),
    door_width_meters DECIMAL(5, 2),
    has_dock_leveler BOOLEAN DEFAULT TRUE,
    has_dock_seal BOOLEAN DEFAULT TRUE,
    current_vehicle_id INTEGER,
    current_shipment_id INTEGER,
    status docking_stations_status DEFAULT 'AVAILABLE',
    next_available_time TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (warehouse_id, dock_number)
);

ALTER TABLE docking_stations ADD CONSTRAINT fk_docking_stations_warehouse_id FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id) ON DELETE CASCADE;
CREATE TABLE IF NOT EXISTS products (
    product_name VARCHAR(200) NOT NULL,
    product_description TEXT,
    category VARCHAR(100),
    subcategory VARCHAR(100),
    brand VARCHAR(100),
    unit_of_measure products_status NOT NULL,
    weight_kg DECIMAL(10, 3),
    dimensions_lwh VARCHAR(50),
    volume_cbm DECIMAL(8, 3),
    is_hazmat BOOLEAN DEFAULT FALSE,
    hazmat_class VARCHAR(20),
    requires_temperature_control BOOLEAN DEFAULT FALSE,
    min_temperature_celsius DECIMAL(5, 2),
    max_temperature_celsius DECIMAL(5, 2),
    shelf_life_days INTEGER,
    is_serialized BOOLEAN DEFAULT FALSE,
    is_lot_controlled BOOLEAN DEFAULT FALSE,
    reorder_point INTEGER,
    reorder_quantity INTEGER,
    lead_time_days INTEGER,
    unit_cost DECIMAL(10, 2),
    selling_price DECIMAL(10, 2),
    abc_classification CHAR(1),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FULLTEXT TEXT (product_name, product_description)
);

CREATE TABLE IF NOT EXISTS inventory_levels (
    warehouse_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity_on_hand DECIMAL(12, 3) NOT NULL DEFAULT 0,
    quantity_available DECIMAL(12, 3) NOT NULL DEFAULT 0,
    quantity_allocated DECIMAL(12, 3) NOT NULL DEFAULT 0,
    quantity_in_transit DECIMAL(12, 3) NOT NULL DEFAULT 0,
    quantity_damaged DECIMAL(12, 3) NOT NULL DEFAULT 0,
    quantity_quarantine DECIMAL(12, 3) NOT NULL DEFAULT 0,
    average_cost DECIMAL(10, 4),
    last_received_date TIMESTAMP,
    last_counted_date TIMESTAMP,
    last_shipped_date TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (warehouse_id, product_id)
);

ALTER TABLE inventory_levels ADD CONSTRAINT fk_inventory_levels_warehouse_id FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id);
ALTER TABLE inventory_levels ADD CONSTRAINT fk_inventory_levels_product_id FOREIGN KEY (product_id) REFERENCES products(product_id);
CREATE TABLE IF NOT EXISTS product_batches (
    product_id INTEGER NOT NULL,
    warehouse_id INTEGER NOT NULL,
    batch_number VARCHAR(50) NOT NULL,
    lot_number VARCHAR(50),
    serial_numbers JSONB,
    manufacture_date DATE,
    expiry_date DATE,
    received_date TIMESTAMP NOT NULL,
    quantity_received DECIMAL(12, 3) NOT NULL,
    quantity_remaining DECIMAL(12, 3) NOT NULL,
    supplier_id INTEGER,
    purchase_order_id INTEGER,
    quality_status product_batches_status DEFAULT 'PENDING',
    quality_certificate_url VARCHAR(500),
    storage_conditions TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (product_id, batch_number)
);

ALTER TABLE product_batches ADD CONSTRAINT fk_product_batches_product_id FOREIGN KEY (product_id) REFERENCES products(product_id);
ALTER TABLE product_batches ADD CONSTRAINT fk_product_batches_warehouse_id FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id);
CREATE TABLE IF NOT EXISTS inventory_movements (
    movement_type inventory_movements_status NOT NULL,
    reference_type inventory_movements_status NOT NULL,
    reference_id INTEGER,
    product_id INTEGER NOT NULL,
    batch_id INTEGER,
    from_warehouse_id INTEGER,
    from_bin_id INTEGER,
    to_warehouse_id INTEGER,
    to_bin_id INTEGER,
    quantity DECIMAL(12, 3) NOT NULL,
    unit_cost DECIMAL(10, 4),
    total_cost DECIMAL(15, 2),
    movement_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    performed_by INTEGER,
    reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PARTITION TEXT VALUES LESS THAN (2025),
    PARTITION TEXT VALUES LESS THAN (2026),
    PARTITION TEXT VALUES LESS THAN MAXVALUE
);

ALTER TABLE inventory_movements ADD CONSTRAINT fk_inventory_movements_product_id FOREIGN KEY (product_id) REFERENCES products(product_id);
ALTER TABLE inventory_movements ADD CONSTRAINT fk_inventory_movements_batch_id FOREIGN KEY (batch_id) REFERENCES product_batches(batch_id);
ALTER TABLE inventory_movements ADD CONSTRAINT fk_inventory_movements_from_warehouse_id FOREIGN KEY (from_warehouse_id) REFERENCES warehouses(warehouse_id);
ALTER TABLE inventory_movements ADD CONSTRAINT fk_inventory_movements_to_warehouse_id FOREIGN KEY (to_warehouse_id) REFERENCES warehouses(warehouse_id);
ALTER TABLE inventory_movements ADD CONSTRAINT fk_inventory_movements_from_bin_id FOREIGN KEY (from_bin_id) REFERENCES warehouse_bins(bin_id);
ALTER TABLE inventory_movements ADD CONSTRAINT fk_inventory_movements_to_bin_id FOREIGN KEY (to_bin_id) REFERENCES warehouse_bins(bin_id);
CREATE TABLE IF NOT EXISTS suppliers (
    supplier_name VARCHAR(200) NOT NULL,
    supplier_type suppliers_status NOT NULL,
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
    lead_time_days INTEGER,
    minimum_order_value DECIMAL(10, 2),
    performance_score DECIMAL(3, 2),
    is_preferred BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    certifications JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS customers (
    customer_name VARCHAR(200) NOT NULL,
    customer_type customers_status NOT NULL,
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
    priority_level customers_status DEFAULT 'STANDARD',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS purchase_orders (
    supplier_id INTEGER NOT NULL,
    warehouse_id INTEGER NOT NULL,
    order_date DATE NOT NULL,
    expected_delivery_date DATE,
    actual_delivery_date DATE,
    total_amount DECIMAL(15, 2),
    currency_code CHAR(3),
    status purchase_orders_status NOT NULL,
    payment_status purchase_orders_status DEFAULT 'PENDING',
    notes TEXT,
    created_by INTEGER,
    approved_by INTEGER,
    approval_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE purchase_orders ADD CONSTRAINT fk_purchase_orders_supplier_id FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id);
ALTER TABLE purchase_orders ADD CONSTRAINT fk_purchase_orders_warehouse_id FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id);
CREATE TABLE IF NOT EXISTS purchase_order_items (
    po_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity_ordered DECIMAL(12, 3) NOT NULL,
    quantity_received DECIMAL(12, 3) DEFAULT 0,
    unit_price DECIMAL(10, 4),
    line_total DECIMAL(15, 2),
    discount_percent DECIMAL(5, 2),
    tax_amount DECIMAL(10, 2),
    expected_delivery_date DATE,
    notes TEXT
);

ALTER TABLE purchase_order_items ADD CONSTRAINT fk_purchase_order_items_po_id FOREIGN KEY (po_id) REFERENCES purchase_orders(po_id) ON DELETE CASCADE;
ALTER TABLE purchase_order_items ADD CONSTRAINT fk_purchase_order_items_product_id FOREIGN KEY (product_id) REFERENCES products(product_id);
CREATE TABLE IF NOT EXISTS sales_orders (
    customer_id INTEGER NOT NULL,
    order_date TIMESTAMP NOT NULL,
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
    status sales_orders_status NOT NULL,
    payment_status sales_orders_status DEFAULT 'PENDING',
    fulfillment_priority sales_orders_status DEFAULT 'STANDARD',
    special_instructions TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE sales_orders ADD CONSTRAINT fk_sales_orders_customer_id FOREIGN KEY (customer_id) REFERENCES customers(customer_id);
CREATE TABLE IF NOT EXISTS sales_order_items (
    so_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    warehouse_id INTEGER,
    quantity_ordered DECIMAL(12, 3) NOT NULL,
    quantity_allocated DECIMAL(12, 3) DEFAULT 0,
    quantity_picked DECIMAL(12, 3) DEFAULT 0,
    quantity_shipped DECIMAL(12, 3) DEFAULT 0,
    unit_price DECIMAL(10, 4),
    discount_percent DECIMAL(5, 2),
    tax_rate DECIMAL(5, 2),
    line_total DECIMAL(15, 2),
    allocated_batch_id INTEGER,
    backorder_quantity DECIMAL(12, 3) DEFAULT 0,
    notes TEXT
);

ALTER TABLE sales_order_items ADD CONSTRAINT fk_sales_order_items_so_id FOREIGN KEY (so_id) REFERENCES sales_orders(so_id) ON DELETE CASCADE;
ALTER TABLE sales_order_items ADD CONSTRAINT fk_sales_order_items_product_id FOREIGN KEY (product_id) REFERENCES products(product_id);
ALTER TABLE sales_order_items ADD CONSTRAINT fk_sales_order_items_warehouse_id FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id);
ALTER TABLE sales_order_items ADD CONSTRAINT fk_sales_order_items_allocated_batch_id FOREIGN KEY (allocated_batch_id) REFERENCES product_batches(batch_id);
CREATE TABLE IF NOT EXISTS carriers (
    carrier_name VARCHAR(200) NOT NULL,
    carrier_type carriers_status NOT NULL,
    scac_code VARCHAR(10),
    mc_number VARCHAR(20),
    dot_number VARCHAR(20),
    contact_name VARCHAR(100),
    contact_phone VARCHAR(20),
    contact_email VARCHAR(100),
    api_endpoint VARCHAR(500),
    tracking_url_template VARCHAR(500),
    insurance_coverage DECIMAL(15, 2),
    liability_limit DECIMAL(15, 2),
    performance_score DECIMAL(3, 2),
    on_time_percentage DECIMAL(5, 2),
    damage_claim_rate DECIMAL(5, 2),
    is_preferred BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    supported_services JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS carrier_services (
    carrier_id INTEGER NOT NULL,
    service_code VARCHAR(50) NOT NULL,
    service_name VARCHAR(100) NOT NULL,
    service_type carrier_services_status NOT NULL,
    transit_time_days INTEGER,
    cutoff_time TIME,
    delivery_commitment VARCHAR(100),
    max_weight_kg DECIMAL(10, 2),
    max_dimensions_cm VARCHAR(50),
    supports_cod BOOLEAN DEFAULT FALSE,
    supports_insurance BOOLEAN DEFAULT TRUE,
    supports_signature BOOLEAN DEFAULT TRUE,
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE (carrier_id, service_code)
);

ALTER TABLE carrier_services ADD CONSTRAINT fk_carrier_services_carrier_id FOREIGN KEY (carrier_id) REFERENCES carriers(carrier_id) ON DELETE CASCADE;
CREATE TABLE IF NOT EXISTS shipments (
    shipment_type shipments_status NOT NULL,
    reference_type shipments_status NOT NULL,
    reference_id INTEGER,
    carrier_id INTEGER,
    service_id INTEGER,
    tracking_number VARCHAR(100),
    from_warehouse_id INTEGER,
    to_warehouse_id INTEGER,
    origin_address JSONB,
    destination_address JSONB,
    pickup_date TIMESTAMP,
    delivery_date TIMESTAMP,
    actual_delivery_date TIMESTAMP,
    total_packages INTEGER,
    total_weight_kg DECIMAL(10, 2),
    total_volume_cbm DECIMAL(10, 3),
    declared_value DECIMAL(15, 2),
    insurance_amount DECIMAL(15, 2),
    shipping_cost DECIMAL(10, 2),
    fuel_surcharge DECIMAL(10, 2),
    other_charges DECIMAL(10, 2),
    total_cost DECIMAL(15, 2),
    status shipments_status NOT NULL,
    status_details TEXT,
    pod_signature VARCHAR(200),
    pod_timestamp TIMESTAMP,
    temperature_controlled BOOLEAN DEFAULT FALSE,
    temperature_range VARCHAR(50),
    special_handling JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PARTITION TEXT VALUES LESS THAN (2025),
    PARTITION TEXT VALUES LESS THAN (2026),
    PARTITION TEXT VALUES LESS THAN MAXVALUE
);

ALTER TABLE shipments ADD CONSTRAINT fk_shipments_carrier_id FOREIGN KEY (carrier_id) REFERENCES carriers(carrier_id);
ALTER TABLE shipments ADD CONSTRAINT fk_shipments_service_id FOREIGN KEY (service_id) REFERENCES carrier_services(service_id);
ALTER TABLE shipments ADD CONSTRAINT fk_shipments_from_warehouse_id FOREIGN KEY (from_warehouse_id) REFERENCES warehouses(warehouse_id);
ALTER TABLE shipments ADD CONSTRAINT fk_shipments_to_warehouse_id FOREIGN KEY (to_warehouse_id) REFERENCES warehouses(warehouse_id);
CREATE TABLE IF NOT EXISTS shipment_tracking (
    shipment_id INTEGER NOT NULL,
    status_code VARCHAR(50),
    status_description TEXT,
    location_city VARCHAR(100),
    location_state VARCHAR(50),
    location_country CHAR(2),
    location_zip VARCHAR(20),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    event_timestamp TIMESTAMP NOT NULL,
    carrier_status_code VARCHAR(50),
    exception_type VARCHAR(100),
    exception_description TEXT,
    estimated_delivery TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PARTITION TEXT VALUES LESS THAN (2025),
    PARTITION TEXT VALUES LESS THAN (2026),
    PARTITION TEXT VALUES LESS THAN MAXVALUE
);

ALTER TABLE shipment_tracking ADD CONSTRAINT fk_shipment_tracking_shipment_id FOREIGN KEY (shipment_id) REFERENCES shipments(shipment_id) ON DELETE CASCADE;
CREATE TABLE IF NOT EXISTS vehicles (
    vehicle_type vehicles_status NOT NULL,
    make VARCHAR(50),
    model VARCHAR(50),
    year INTEGER,
    vin VARCHAR(17),
    license_plate VARCHAR(20),
    registration_state VARCHAR(50),
    ownership_type vehicles_status NOT NULL,
    capacity_kg DECIMAL(10, 2),
    capacity_cbm DECIMAL(10, 2),
    fuel_type vehicles_status NOT NULL,
    fuel_efficiency_km_per_liter DECIMAL(5, 2),
    current_odometer_km INTEGER,
    last_service_date DATE,
    next_service_date DATE,
    insurance_policy_number VARCHAR(50),
    insurance_expiry_date DATE,
    current_location_lat DECIMAL(10, 8),
    current_location_lng DECIMAL(11, 8),
    current_status vehicles_status DEFAULT 'AVAILABLE',
    assigned_driver_id INTEGER,
    home_warehouse_id INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    telematics_device_id VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE vehicles ADD CONSTRAINT fk_vehicles_home_warehouse_id FOREIGN KEY (home_warehouse_id) REFERENCES warehouses(warehouse_id);
CREATE TABLE IF NOT EXISTS drivers (
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
    home_base_warehouse_id INTEGER,
    current_vehicle_id INTEGER,
    hours_of_service_remaining DECIMAL(5, 2),
    last_drug_test_date DATE,
    medical_certificate_expiry DATE,
    safety_score DECIMAL(3, 2),
    total_miles_driven INTEGER DEFAULT 0,
    total_deliveries INTEGER DEFAULT 0,
    status drivers_status DEFAULT 'AVAILABLE',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE drivers ADD CONSTRAINT fk_drivers_home_base_warehouse_id FOREIGN KEY (home_base_warehouse_id) REFERENCES warehouses(warehouse_id);
ALTER TABLE drivers ADD CONSTRAINT fk_drivers_current_vehicle_id FOREIGN KEY (current_vehicle_id) REFERENCES vehicles(vehicle_id);
CREATE TABLE IF NOT EXISTS routes (
    route_name VARCHAR(100),
    route_type routes_status NOT NULL,
    origin_warehouse_id INTEGER NOT NULL,
    destination_warehouse_id INTEGER,
    total_distance_km DECIMAL(10, 2),
    estimated_duration_hours DECIMAL(5, 2),
    stops JSONB,
    preferred_departure_time TIME,
    service_days TEXT[],
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE routes ADD CONSTRAINT fk_routes_origin_warehouse_id FOREIGN KEY (origin_warehouse_id) REFERENCES warehouses(warehouse_id);
ALTER TABLE routes ADD CONSTRAINT fk_routes_destination_warehouse_id FOREIGN KEY (destination_warehouse_id) REFERENCES warehouses(warehouse_id);
CREATE TABLE IF NOT EXISTS delivery_runs (
    run_date DATE NOT NULL,
    route_id INTEGER,
    vehicle_id INTEGER NOT NULL,
    driver_id INTEGER NOT NULL,
    planned_start_time TIMESTAMP,
    actual_start_time TIMESTAMP,
    planned_end_time TIMESTAMP,
    actual_end_time TIMESTAMP,
    total_stops INTEGER,
    completed_stops INTEGER DEFAULT 0,
    total_packages INTEGER,
    delivered_packages INTEGER DEFAULT 0,
    total_distance_km DECIMAL(10, 2),
    fuel_consumed_liters DECIMAL(10, 2),
    status delivery_runs_status DEFAULT 'PLANNED',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE delivery_runs ADD CONSTRAINT fk_delivery_runs_route_id FOREIGN KEY (route_id) REFERENCES routes(route_id);
ALTER TABLE delivery_runs ADD CONSTRAINT fk_delivery_runs_vehicle_id FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id);
ALTER TABLE delivery_runs ADD CONSTRAINT fk_delivery_runs_driver_id FOREIGN KEY (driver_id) REFERENCES drivers(driver_id);
CREATE TABLE IF NOT EXISTS kpi_metrics (
    metric_date DATE NOT NULL,
    metric_type kpi_metrics_status NOT NULL,
    warehouse_id INTEGER,
    inventory_turnover_ratio DECIMAL(10, 2),
    stockout_incidents INTEGER,
    inventory_accuracy_percent DECIMAL(5, 2),
    carrying_cost DECIMAL(15, 2),
    orders_processed INTEGER,
    perfect_order_rate DECIMAL(5, 2),
    order_cycle_time_hours DECIMAL(10, 2),
    fill_rate_percent DECIMAL(5, 2),
    backorder_rate_percent DECIMAL(5, 2),
    warehouse_utilization_percent DECIMAL(5, 2),
    picking_accuracy_percent DECIMAL(5, 2),
    putaway_cycle_time_minutes DECIMAL(10, 2),
    labor_productivity_units_per_hour DECIMAL(10, 2),
    on_time_delivery_percent DECIMAL(5, 2),
    freight_cost_per_unit DECIMAL(10, 2),
    delivery_success_rate DECIMAL(5, 2),
    average_delivery_time_hours DECIMAL(10, 2),
    fuel_efficiency_km_per_liter DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (metric_date, metric_type, warehouse_id)
);

ALTER TABLE kpi_metrics ADD CONSTRAINT fk_kpi_metrics_warehouse_id FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id);
CREATE TABLE IF NOT EXISTS audit_log (
    table_name VARCHAR(50) NOT NULL,
    record_id INTEGER NOT NULL,
    action audit_log_status NOT NULL,
    changed_by INTEGER,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    old_values JSONB,
    new_values JSONB,
    ip_address VARCHAR(45),
    user_agent VARCHAR(255),
    PARTITION TEXT VALUES LESS THAN (2025),
    PARTITION TEXT VALUES LESS THAN (2026),
    PARTITION TEXT VALUES LESS THAN MAXVALUE
);

CREATE INDEX idx_inventory_availability_composite
ON inventory_levels(product_id, quantity_available, warehouse_id)
WHERE quantity_available > 0;
CREATE INDEX idx_low_stock_alert
ON inventory_levels(product_id, quantity_available, quantity_on_hand)
WHERE quantity_available < 100;
CREATE INDEX idx_expiring_products
ON product_batches(expiry_date, product_id, warehouse_id, quantity_remaining)
WHERE expiry_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 30 DAY)
AND quantity_remaining > 0;
CREATE INDEX idx_pending_allocation
ON sales_order_items(so_id, product_id, quantity_ordered, quantity_allocated)
WHERE quantity_allocated < quantity_ordered;
CREATE INDEX idx_backorders
ON sales_order_items(product_id, backorder_quantity, so_id)
WHERE backorder_quantity > 0;
CREATE INDEX idx_order_priority_processing
ON sales_orders(status, fulfillment_priority, requested_delivery_date)
WHERE status IN ('PENDING', 'CONFIRMED', 'PICKING');
CREATE INDEX idx_active_shipments
ON shipments(status, carrier_id, delivery_date)
WHERE status IN ('PICKED_UP', 'IN_TRANSIT', 'OUT_FOR_DELIVERY');
CREATE INDEX idx_delivery_performance
ON shipments(carrier_id, actual_delivery_date, delivery_date, status)
WHERE status = 'DELIVERED';
ALTER TABLE shipment_tracking
ADD SPATIAL INDEX idx_tracking_location(latitude, longitude);
CREATE INDEX idx_bin_availability_composite
ON warehouse_bins(zone_id, is_occupied, bin_type, max_weight_kg)
WHERE is_occupied = FALSE AND is_locked = FALSE;
CREATE INDEX idx_dock_scheduling
ON docking_stations(warehouse_id, status, next_available_time)
WHERE status IN ('AVAILABLE', 'SCHEDULED');
CREATE INDEX idx_route_planning
ON routes(route_type, origin_warehouse_id, is_active)
WHERE is_active = TRUE;
CREATE INDEX idx_driver_availability
ON drivers(status, home_base_warehouse_id, safety_score)
WHERE status = 'AVAILABLE' AND is_active = TRUE;
CREATE INDEX idx_vehicle_scheduling
ON vehicles(current_status, vehicle_type, home_warehouse_id)
WHERE current_status = 'AVAILABLE' AND is_active = TRUE;
CREATE INDEX idx_preferred_suppliers
ON suppliers(is_active, is_preferred, performance_score, lead_time_days)
WHERE is_active = TRUE;
CREATE INDEX idx_supplier_products
ON purchase_order_items(product_id, po_id);
CREATE INDEX idx_kpi_trends
ON kpi_metrics(warehouse_id, metric_type, metric_date, on_time_delivery_percent);
CREATE INDEX idx_movement_analysis
ON inventory_movements(product_id, movement_type, movement_date, from_warehouse_id, to_warehouse_id);
ALTER TABLE shipments
ADD FULLTEXT INDEX idx_shipment_search(shipment_number, tracking_number);
ALTER TABLE customers
ADD FULLTEXT INDEX idx_customer_search(customer_name, customer_code);
ALTER TABLE suppliers
ADD FULLTEXT INDEX idx_supplier_search(supplier_name, supplier_code);
CREATE INDEX idx_order_summary_covering
ON sales_orders(customer_id, order_date, status, total_amount);
CREATE INDEX idx_inventory_summary_covering
ON inventory_levels(product_id, warehouse_id, quantity_on_hand, quantity_available);
CREATE INDEX idx_shipment_summary_covering
ON shipments(carrier_id, status, pickup_date, delivery_date, total_cost);
CREATE INDEX idx_tracking_hash USING HASH
ON shipments(tracking_number);
CREATE INDEX idx_order_hash USING HASH
ON sales_orders(so_number);
CREATE INDEX idx_sku_hash USING HASH
ON products(sku);
CREATE INDEX idx_product_characteristics
ON products(is_hazmat, requires_temperature_control, is_serialized, is_lot_controlled, abc_classification);
CREATE INDEX idx_warehouse_capabilities
ON warehouses(warehouse_type, is_active);
ANALYZE TABLE warehouses;
ANALYZE TABLE warehouse_zones;
ANALYZE TABLE warehouse_bins;
ANALYZE TABLE products;
ANALYZE TABLE inventory_levels;
ANALYZE TABLE product_batches;
ANALYZE TABLE inventory_movements;
ANALYZE TABLE suppliers;
ANALYZE TABLE customers;
ANALYZE TABLE purchase_orders;
ANALYZE TABLE sales_orders;
ANALYZE TABLE shipments;
ANALYZE TABLE shipment_tracking;
ANALYZE TABLE carriers;
ANALYZE TABLE vehicles;
ANALYZE TABLE drivers;
ANALYZE TABLE routes;
-- Indexes
