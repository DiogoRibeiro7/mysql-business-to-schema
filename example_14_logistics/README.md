# 📦 Logistics & Supply Chain Management System

A comprehensive MySQL database schema for modern logistics operations, including warehouse management, inventory control, transportation planning, and end-to-end supply chain visibility.

## 📊 Database Overview

- **Industry**: Logistics & Supply Chain
- **Complexity**: High
- **Tables**: 24
- **Key Features**: Warehouse Management, Multi-modal Transportation, Real-time Tracking, Supply Chain Analytics
- **Data Generator**: ✅ Available

## 🗂️ Schema Structure

### Warehouse Management (4 tables)

1. **warehouses** - Distribution centers and fulfillment centers
   - Multiple warehouse types (DC, FC, Cross-dock, Cold storage)
   - Geospatial coordinates for location optimization
   - Capacity management (total/available in cubic meters)
   - Specialized capabilities (HAZMAT, refrigerated, pharma)
   - Operating hours and contact information

2. **warehouse_zones** - Storage areas within warehouses
   - Zone types (receiving, storage, picking, shipping, returns)
   - Temperature-controlled zones for cold chain
   - Automated vs manual zones
   - Occupancy tracking for optimization

3. **warehouse_bins** - Individual storage locations
   - Hierarchical location system (aisle/rack/level/position)
   - Multiple bin types (floor, pallet rack, shelf, bulk)
   - Weight and volume capacity constraints
   - Lock status for inventory control

4. **docking_stations** - Loading/unloading bays
   - Dock types (receiving, shipping, both)
   - Equipment specifications (levelers, seals)
   - Real-time availability tracking
   - Scheduling integration

### Inventory Management (4 tables)

5. **products** - SKU master data
   - Complete product specifications
   - Hazmat classification and handling requirements
   - Temperature control requirements
   - ABC classification for inventory optimization
   - Serialization and lot control flags
   - Reorder points and lead times

6. **inventory_levels** - Current stock levels by location
   - Real-time quantity tracking
   - Available vs reserved quantities
   - Last count dates for cycle counting
   - Multiple status types (available, hold, damaged)

7. **product_batches** - Batch/lot tracking
   - Manufacture and expiry dates
   - Quality control status
   - Batch-specific attributes
   - Traceability for recalls

8. **inventory_movements** - Stock transactions
   - Movement types (receipt, pick, transfer, adjustment)
   - Source and destination tracking
   - Reason codes for audit trail
   - User and timestamp tracking

### Order Management (4 tables)

9. **suppliers** - Vendor master data
   - Supplier classification and ratings
   - Payment terms and currencies
   - Lead times by product
   - Performance metrics tracking
   - Compliance certifications

10. **customers** - Customer information
    - Customer segments (B2B, B2C, distributor)
    - Credit limits and payment terms
    - Delivery preferences
    - Priority levels for allocation

11. **purchase_orders** - Inbound orders from suppliers
    - Multi-status workflow
    - Expected delivery dates
    - Terms and conditions
    - Approval workflows

12. **purchase_order_items** - Line items for POs
    - Quantity ordered vs received
    - Unit costs and discounts
    - Quality inspection requirements
    - Partial receipt handling

13. **sales_orders** - Outbound orders to customers
    - Order priorities and SLAs
    - Delivery instructions
    - Special handling requirements
    - Credit hold management

14. **sales_order_items** - Line items for sales orders
    - Inventory allocation
    - Backorder management
    - Pricing and discounts
    - Kit/bundle support

### Transportation Management (7 tables)

15. **carriers** - Shipping companies
    - Carrier types (LTL, FTL, parcel, air, ocean)
    - Service capabilities
    - Performance ratings
    - Contract terms

16. **carrier_services** - Service levels
    - Transit time commitments
    - Service types (express, standard, economy)
    - Geographic coverage
    - Cut-off times

17. **vehicles** - Fleet management
    - Vehicle specifications and capacity
    - Maintenance schedules
    - Fuel efficiency tracking
    - Equipment types (dry van, reefer, flatbed)

18. **drivers** - Driver information
    - License types and endorsements
    - Hours of service tracking
    - Performance metrics
    - Training certifications

19. **routes** - Predefined delivery routes
    - Multi-stop optimization
    - Distance and duration estimates
    - Toll and fuel cost calculations
    - Service windows

20. **delivery_runs** - Actual delivery execution
    - Planned vs actual times
    - Stop sequences
    - Delivery confirmations
    - Exception handling

21. **shipments** - Consolidated shipping records
    - Multi-modal support
    - Consolidation strategies
    - Documentation requirements
    - Customs information

22. **shipment_tracking** - Real-time status updates
    - GPS coordinates
    - Status milestones
    - Exception events
    - Proof of delivery

### Analytics & Monitoring (2 tables)

23. **kpi_metrics** - Key performance indicators
    - Operational metrics (fill rate, cycle time)
    - Financial metrics (cost per unit, margins)
    - Quality metrics (damage rate, accuracy)
    - Time-series storage for trending

24. **audit_log** - System audit trail
    - All data modifications
    - User actions tracking
    - Compliance reporting
    - Security monitoring

## 🔑 Key Features

### Warehouse Operations
- **Multi-echelon inventory** across warehouses, zones, and bins
- **Cross-docking** support for flow-through operations
- **Wave picking** optimization with zone assignments
- **Cycle counting** schedules with ABC stratification

### Transportation Planning
- **Multi-modal shipping** (road, rail, sea, air)
- **Route optimization** with multiple stops
- **Carrier selection** based on cost/service/performance
- **Load consolidation** for efficiency

### Inventory Control
- **FIFO/LIFO/FEFO** rotation strategies
- **Lot and serial tracking** for traceability
- **Safety stock** calculations
- **ABC analysis** for inventory optimization

### Supply Chain Visibility
- **End-to-end tracking** from supplier to customer
- **Real-time GPS** location updates
- **Exception management** with alerts
- **Performance scorecards** for suppliers/carriers

## 📈 Use Cases

### Operational Queries

1. **Available Inventory Check**
   ```sql
   -- Find available inventory across all warehouses for a SKU
   SELECT
     w.warehouse_name,
     wz.zone_name,
     il.quantity_on_hand,
     il.quantity_available,
     il.quantity_reserved,
     pb.batch_number,
     pb.expiry_date
   FROM inventory_levels il
   JOIN warehouse_bins wb ON il.bin_id = wb.bin_id
   JOIN warehouse_zones wz ON wb.zone_id = wz.zone_id
   JOIN warehouses w ON wz.warehouse_id = w.warehouse_id
   LEFT JOIN product_batches pb ON il.batch_id = pb.batch_id
   WHERE il.product_id = ?
     AND il.quantity_available > 0
     AND il.status = 'AVAILABLE'
   ORDER BY pb.expiry_date, w.warehouse_name;
   ```

2. **Optimal Warehouse Selection**
   ```sql
   -- Select best warehouse for order fulfillment
   SELECT
     w.warehouse_id,
     w.warehouse_name,
     ST_Distance_Sphere(
       POINT(w.longitude, w.latitude),
       POINT(c.longitude, c.latitude)
     ) / 1000 as distance_km,
     SUM(il.quantity_available) as total_available,
     COUNT(DISTINCT soi.product_id) as products_available
   FROM warehouses w
   CROSS JOIN customers c
   JOIN warehouse_zones wz ON w.warehouse_id = wz.warehouse_id
   JOIN warehouse_bins wb ON wz.zone_id = wb.zone_id
   JOIN inventory_levels il ON wb.bin_id = il.bin_id
   JOIN sales_order_items soi ON il.product_id = soi.product_id
   WHERE c.customer_id = ?
     AND soi.sales_order_id = ?
     AND w.is_active = TRUE
     AND il.quantity_available >= soi.quantity_ordered
   GROUP BY w.warehouse_id
   HAVING COUNT(DISTINCT soi.product_id) =
          (SELECT COUNT(*) FROM sales_order_items WHERE sales_order_id = ?)
   ORDER BY distance_km, total_available DESC;
   ```

3. **Delivery Route Optimization**
   ```sql
   -- Calculate optimal delivery sequence for a route
   WITH delivery_stops AS (
     SELECT
       s.shipment_id,
       s.delivery_address,
       s.delivery_latitude,
       s.delivery_longitude,
       s.delivery_window_start,
       s.delivery_window_end,
       s.priority,
       SUM(si.weight_kg) as total_weight,
       SUM(si.volume_cbm) as total_volume
     FROM shipments s
     JOIN sales_orders so ON s.order_id = so.order_id
     WHERE s.route_id = ?
       AND s.status = 'PLANNED'
     GROUP BY s.shipment_id
   ),
   stop_distances AS (
     SELECT
       a.shipment_id as from_shipment,
       b.shipment_id as to_shipment,
       ST_Distance_Sphere(
         POINT(a.delivery_longitude, a.delivery_latitude),
         POINT(b.delivery_longitude, b.delivery_latitude)
       ) / 1000 as distance_km
     FROM delivery_stops a
     CROSS JOIN delivery_stops b
     WHERE a.shipment_id != b.shipment_id
   )
   SELECT
     ds.*,
     sd.distance_km as distance_to_next
   FROM delivery_stops ds
   LEFT JOIN stop_distances sd
     ON ds.shipment_id = sd.from_shipment
   ORDER BY ds.priority DESC, ds.delivery_window_start;
   ```

### Analytical Queries

4. **Inventory Turnover Analysis**
   ```sql
   -- Calculate inventory turnover by product category
   SELECT
     p.category,
     COUNT(DISTINCT p.product_id) as sku_count,
     SUM(il.quantity_on_hand * p.unit_cost) as inventory_value,
     SUM(im.quantity) as units_moved_30d,
     SUM(im.quantity * p.unit_cost) / NULLIF(SUM(il.quantity_on_hand * p.unit_cost), 0) * 12 as annual_turnover,
     AVG(DATEDIFF(CURRENT_DATE, il.last_movement_date)) as avg_days_in_stock
   FROM products p
   JOIN inventory_levels il ON p.product_id = il.product_id
   LEFT JOIN inventory_movements im ON p.product_id = im.product_id
     AND im.movement_date >= DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY)
     AND im.movement_type = 'PICK'
   GROUP BY p.category
   ORDER BY annual_turnover DESC;
   ```

5. **Carrier Performance Scorecard**
   ```sql
   -- Evaluate carrier performance metrics
   SELECT
     c.carrier_name,
     cs.service_name,
     COUNT(DISTINCT s.shipment_id) as total_shipments,
     AVG(DATEDIFF(st.actual_delivery, s.estimated_delivery)) as avg_delay_days,
     SUM(CASE WHEN st.actual_delivery <= s.estimated_delivery THEN 1 ELSE 0 END) /
       COUNT(*) * 100 as on_time_percentage,
     AVG(s.actual_cost - s.estimated_cost) as avg_cost_variance,
     SUM(st.exception_count) as total_exceptions,
     AVG(CASE WHEN st.proof_of_delivery IS NOT NULL THEN 1 ELSE 0 END) * 100 as pod_percentage
   FROM carriers c
   JOIN carrier_services cs ON c.carrier_id = cs.carrier_id
   JOIN shipments s ON cs.service_id = s.service_id
   JOIN shipment_tracking st ON s.shipment_id = st.shipment_id
   WHERE s.ship_date >= DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY)
   GROUP BY c.carrier_id, cs.service_id
   HAVING COUNT(s.shipment_id) >= 10
   ORDER BY on_time_percentage DESC, avg_delay_days;
   ```

## 🚀 Getting Started

### 1. Create Database
```bash
mysql -u root -p < schema/00_create_database.sql
```

### 2. Create Schema
```bash
mysql -u root -p logistics_db < schema/01_tables.sql
mysql -u root -p logistics_db < schema/02_constraints.sql
mysql -u root -p logistics_db < schema/03_indexes.sql
```

### 3. Generate Test Data
```bash
# Using the unified runner (recommended)
python generators/run_generators.py logistics --test

# Or run directly
cd generators/logistics
python generator.py
```

### 4. Load Generated Data
```bash
mysql -u root -p logistics_db < generators/logistics/output/*.sql
```

### 5. Run Example Queries
```bash
mysql -u root -p logistics_db < queries/01_operational.sql
mysql -u root -p logistics_db < queries/02_analytics.sql
mysql -u root -p logistics_db < queries/03_kpi_reports.sql
```

## 📋 Business Rules

### Inventory Allocation
- **FIFO/LIFO/FEFO** strategies based on product type
- **Reserved stock** for priority customers
- **Safety stock** maintenance based on lead times
- **Cross-docking** for eligible products

### Shipping Rules
- **Weight and dimension** limits per carrier/service
- **HAZMAT regulations** for dangerous goods
- **Temperature control** for cold chain
- **International shipping** documentation requirements

### Warehouse Operations
- **Wave picking** with zone optimization
- **Putaway strategies** based on product velocity
- **Cycle counting** based on ABC classification
- **Labor standards** for productivity tracking

### Service Level Agreements
- **Order cut-off times** for same-day shipping
- **Delivery windows** for scheduled deliveries
- **Priority handling** for expedited orders
- **Performance penalties** for SLA violations

## 🔍 Performance Optimizations

### Indexes
- **Geospatial indexes** for location-based queries
- **Composite indexes** on frequently joined columns
- **Full-text indexes** for product searches
- **Temporal indexes** for time-series data

### Partitioning Strategy
- **Range partitioning** on shipment_tracking by date
- **List partitioning** on inventory_movements by warehouse
- **Hash partitioning** on audit_log for even distribution

### Materialized Views
- Pre-calculated route distances
- Daily inventory snapshots
- Carrier performance metrics
- Customer order history summaries

## 📊 Sample Data Statistics

When using the data generator with default configuration:

- **Warehouses**: 10 distribution centers
- **Products**: 5,000 SKUs across categories
- **Inventory Movements**: 50,000+ transactions/month
- **Orders**: 1,000+ daily orders
- **Shipments**: 2,000+ active shipments
- **Routes**: 100+ delivery routes
- **Vehicles**: 200 trucks/vans
- **Total Records**: ~250,000+

## 🎯 Learning Objectives

This example demonstrates:

1. **Hierarchical Data Modeling** - Warehouse → Zone → Bin structure
2. **Geospatial Queries** - Distance calculations and route optimization
3. **Time-Series Analysis** - Tracking history and performance metrics
4. **Complex Workflows** - Order to shipment to delivery process
5. **Inventory Algorithms** - FIFO/LIFO, safety stock, reorder points
6. **Performance Optimization** - Partitioning, indexing, materialized views
7. **Real-time Tracking** - GPS updates and status management

## 🔧 Customization

### Industry-Specific Extensions

1. **Cold Chain Logistics**
   ```sql
   CREATE TABLE temperature_logs (
     log_id BIGINT PRIMARY KEY,
     shipment_id INT,
     recorded_at TIMESTAMP,
     temperature_celsius DECIMAL(5,2),
     humidity_percent DECIMAL(5,2),
     alert_triggered BOOLEAN
   );
   ```

2. **Cross-Border Trade**
   ```sql
   CREATE TABLE customs_documents (
     document_id BIGINT PRIMARY KEY,
     shipment_id INT,
     document_type VARCHAR(50),
     document_number VARCHAR(100),
     issue_date DATE,
     expiry_date DATE,
     issuing_authority VARCHAR(100)
   );
   ```

3. **3PL Multi-Tenancy**
   ```sql
   CREATE TABLE tenant_companies (
     tenant_id INT PRIMARY KEY,
     company_name VARCHAR(100),
     subscription_tier VARCHAR(50),
     warehouse_allocation JSON,
     api_limits JSON
   );
   ```

## 🛠️ Technologies

- **Database**: MySQL 8.0+
- **Engine**: InnoDB (ACID compliance, foreign keys)
- **Spatial Extensions**: MySQL Spatial for geospatial queries
- **Character Set**: utf8mb4
- **Collation**: utf8mb4_unicode_ci

## 🔗 Integration Points

- **ERP Systems**: SAP, Oracle, Microsoft Dynamics
- **WMS**: Manhattan, Blue Yonder, Körber
- **TMS**: Oracle Transportation Management, SAP TM
- **IoT Devices**: RFID scanners, GPS trackers, temperature sensors
- **External APIs**: Carrier APIs, customs systems, weather data

## 📚 Additional Resources

- [Generator Documentation](../generators/logistics/README.md)
- [Query Examples](queries/)
- [Schema DDL](schema/)
- [Performance Tuning Guide](../docs/performance.md)
- [Integration Guide](../docs/integration.md)

## 🤝 Contributing

To improve this example:

1. Add blockchain integration for supply chain transparency
2. Implement predictive analytics for demand forecasting
3. Add autonomous vehicle support
4. Create drone delivery tables
5. Add sustainability tracking features

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

## 📝 License

This example is part of the MySQL Business-to-Schema project, licensed under MIT License.