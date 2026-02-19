-- Additional Indexes for Logistics & Supply Chain System
-- Performance optimization for common query patterns

USE logistics;

-- ========================================
-- INVENTORY SEARCH INDEXES
-- ========================================

-- Composite index for inventory availability checks
CREATE INDEX idx_inventory_availability_composite
ON inventory_levels(product_id, quantity_available, warehouse_id);

-- Index for low stock alerts
CREATE INDEX idx_low_stock_alert
ON inventory_levels(product_id, quantity_available, quantity_on_hand);

-- Index for expiring products
CREATE INDEX idx_expiring_products
ON product_batches(expiry_date, product_id, warehouse_id, quantity_remaining);

-- ========================================
-- ORDER FULFILLMENT INDEXES
-- ========================================

-- Index for pending order allocation
CREATE INDEX idx_pending_allocation
ON sales_order_items(so_id, product_id, quantity_ordered, quantity_allocated);

-- Index for backorder management
CREATE INDEX idx_backorders
ON sales_order_items(product_id, backorder_quantity, so_id);

-- Index for order priority processing
CREATE INDEX idx_order_priority_processing
ON sales_orders(status, fulfillment_priority, requested_delivery_date);

-- ========================================
-- SHIPMENT TRACKING INDEXES
-- ========================================

-- Index for active shipment tracking
CREATE INDEX idx_active_shipments
ON shipments(status, carrier_id, delivery_date);

-- Index for delivery performance analysis
CREATE INDEX idx_delivery_performance
ON shipments(carrier_id, actual_delivery_date, delivery_date, status);

ALTER TABLE shipment_tracking

-- ========================================
-- WAREHOUSE OPTIMIZATION INDEXES
-- ========================================

-- Index for bin availability
CREATE INDEX idx_bin_availability_composite
ON warehouse_bins(zone_id, is_occupied, bin_type, max_weight_kg);

-- Index for dock scheduling
CREATE INDEX idx_dock_scheduling
ON docking_stations(warehouse_id, status, next_available_time);

-- ========================================
-- ROUTE OPTIMIZATION INDEXES
-- ========================================

-- Index for route planning
CREATE INDEX idx_route_planning
ON routes(route_type, origin_warehouse_id, is_active);

-- Index for driver availability
CREATE INDEX idx_driver_availability
ON drivers(status, home_base_warehouse_id, safety_score);

-- Index for vehicle scheduling
CREATE INDEX idx_vehicle_scheduling
ON vehicles(current_status, vehicle_type, home_warehouse_id);

-- ========================================
-- SUPPLIER PERFORMANCE INDEXES
-- ========================================

-- Index for preferred supplier selection
CREATE INDEX idx_preferred_suppliers
ON suppliers(is_active, is_preferred, performance_score, lead_time_days);

-- Index for supplier product lookup
CREATE INDEX idx_supplier_products
ON purchase_order_items(product_id, po_id);

-- ========================================
-- ANALYTICS INDEXES
-- ========================================

-- Index for KPI trend analysis
CREATE INDEX idx_kpi_trends
ON kpi_metrics(warehouse_id, metric_type, metric_date, on_time_delivery_percent);

-- Index for inventory movement analysis
CREATE INDEX idx_movement_analysis
ON inventory_movements(product_id, movement_type, movement_date, from_warehouse_id, to_warehouse_id);

-- ========================================
-- FULL-TEXT SEARCH INDEXES
-- ========================================

-- Full-text index for shipment search
ALTER TABLE shipments
ADD FULLTEXT INDEX idx_shipment_search(shipment_number, tracking_number);

-- Full-text index for customer search
ALTER TABLE customers
ADD FULLTEXT INDEX idx_customer_search(customer_name, customer_code);

-- Full-text index for supplier search
ALTER TABLE suppliers
ADD FULLTEXT INDEX idx_supplier_search(supplier_name, supplier_code);

-- ========================================
-- COVERING INDEXES
-- ========================================

-- Covering index for order summary queries
CREATE INDEX idx_order_summary_covering
ON sales_orders(customer_id, order_date, status, total_amount);

-- Covering index for inventory summary queries
CREATE INDEX idx_inventory_summary_covering
ON inventory_levels(product_id, warehouse_id, quantity_on_hand, quantity_available);

-- Covering index for shipment summary queries
CREATE INDEX idx_shipment_summary_covering
ON shipments(carrier_id, status, pickup_date, delivery_date, total_cost);

-- ========================================
-- HASH INDEXES (for exact lookups)
-- ========================================

-- Hash index for tracking number lookup
CREATE INDEX idx_tracking_hash USING HASH
ON shipments(tracking_number);

-- Hash index for order number lookup
CREATE INDEX idx_order_hash USING HASH
ON sales_orders(so_number);

-- Hash index for SKU lookup
CREATE INDEX idx_sku_hash USING HASH
ON products(sku);

-- ========================================
-- BITMAP INDEXES (simulated with composite)
-- ========================================

-- Bitmap-like index for product characteristics
CREATE INDEX idx_product_characteristics
ON products(is_hazmat, requires_temperature_control, is_serialized, is_lot_controlled, abc_classification);

-- Bitmap-like index for warehouse capabilities
CREATE INDEX idx_warehouse_capabilities
ON warehouses(warehouse_type, is_active);

-- ========================================
-- INDEX STATISTICS UPDATE
-- ========================================

-- Update statistics for all tables
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
