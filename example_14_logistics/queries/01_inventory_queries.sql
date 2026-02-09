-- Inventory Management Queries
-- Complex queries for inventory optimization and analysis

USE logistics_db;

-- ========================================
-- INVENTORY AVAILABILITY & ALLOCATION
-- ========================================

-- Real-time inventory availability across all warehouses
SELECT
    p.sku,
    p.product_name,
    p.abc_classification,
    SUM(il.quantity_available) as total_available,
    SUM(il.quantity_on_hand) as total_on_hand,
    SUM(il.quantity_allocated) as total_allocated,
    SUM(il.quantity_in_transit) as total_in_transit,
    COUNT(DISTINCT il.warehouse_id) as warehouses_stocked,
    GROUP_CONCAT(
        CONCAT(w.warehouse_code, ':', il.quantity_available)
        ORDER BY il.quantity_available DESC
    ) as availability_by_warehouse
FROM products p
JOIN inventory_levels il ON p.product_id = il.product_id
JOIN warehouses w ON il.warehouse_id = w.warehouse_id
WHERE p.is_active = TRUE
GROUP BY p.product_id
HAVING total_available > 0
ORDER BY p.abc_classification, total_available DESC;

-- Multi-echelon inventory optimization
WITH inventory_distribution AS (
    SELECT
        p.product_id,
        p.sku,
        p.product_name,
        w.warehouse_type,
        w.warehouse_code,
        il.quantity_on_hand,
        il.quantity_available,
        il.average_cost,
        (il.quantity_on_hand * il.average_cost) as inventory_value,
        p.reorder_point,
        p.lead_time_days,
        -- Calculate days of supply
        CASE
            WHEN daily_demand.avg_daily_demand > 0
            THEN il.quantity_available / daily_demand.avg_daily_demand
            ELSE 999
        END as days_of_supply
    FROM inventory_levels il
    JOIN products p ON il.product_id = p.product_id
    JOIN warehouses w ON il.warehouse_id = w.warehouse_id
    LEFT JOIN (
        SELECT
            soi.product_id,
            AVG(soi.quantity_ordered) as avg_daily_demand
        FROM sales_order_items soi
        JOIN sales_orders so ON soi.so_id = so.so_id
        WHERE so.order_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
        GROUP BY soi.product_id
    ) daily_demand ON p.product_id = daily_demand.product_id
)
SELECT
    product_id,
    sku,
    product_name,
    warehouse_type,
    COUNT(*) as warehouse_count,
    SUM(quantity_on_hand) as total_on_hand,
    SUM(inventory_value) as total_value,
    AVG(days_of_supply) as avg_days_supply,
    MIN(days_of_supply) as min_days_supply,
    CASE
        WHEN MIN(days_of_supply) < 7 THEN 'CRITICAL'
        WHEN MIN(days_of_supply) < 14 THEN 'LOW'
        WHEN AVG(days_of_supply) > 90 THEN 'EXCESS'
        ELSE 'OPTIMAL'
    END as stock_status,
    GROUP_CONCAT(
        CONCAT(warehouse_code, ':', ROUND(days_of_supply, 1), ' days')
        ORDER BY days_of_supply
    ) as supply_by_warehouse
FROM inventory_distribution
GROUP BY product_id, warehouse_type
ORDER BY stock_status, min_days_supply;

-- FIFO/FEFO batch allocation for order fulfillment
WITH batch_availability AS (
    SELECT
        pb.batch_id,
        pb.product_id,
        pb.warehouse_id,
        pb.batch_number,
        pb.expiry_date,
        pb.quantity_remaining,
        pb.manufacture_date,
        w.warehouse_code,
        -- Priority based on FEFO (First Expired First Out)
        ROW_NUMBER() OVER (
            PARTITION BY pb.product_id, pb.warehouse_id
            ORDER BY
                CASE
                    WHEN pb.expiry_date IS NOT NULL THEN pb.expiry_date
                    ELSE DATE_ADD(pb.manufacture_date, INTERVAL 365 DAY)
                END,
                pb.received_date
        ) as allocation_priority
    FROM product_batches pb
    JOIN warehouses w ON pb.warehouse_id = w.warehouse_id
    WHERE pb.quantity_remaining > 0
      AND pb.quality_status = 'PASSED'
      AND (pb.expiry_date IS NULL OR pb.expiry_date > CURDATE())
)
SELECT
    soi.so_item_id,
    so.so_number,
    p.sku,
    p.product_name,
    soi.quantity_ordered,
    soi.quantity_allocated,
    soi.quantity_ordered - soi.quantity_allocated as quantity_needed,
    ba.batch_id,
    ba.batch_number,
    ba.warehouse_code,
    ba.expiry_date,
    ba.quantity_remaining as batch_available,
    LEAST(
        soi.quantity_ordered - soi.quantity_allocated,
        ba.quantity_remaining
    ) as suggested_allocation,
    ba.allocation_priority
FROM sales_order_items soi
JOIN sales_orders so ON soi.so_id = so.so_id
JOIN products p ON soi.product_id = p.product_id
JOIN batch_availability ba ON p.product_id = ba.product_id
WHERE so.status IN ('CONFIRMED', 'PICKING')
  AND soi.quantity_allocated < soi.quantity_ordered
  AND (soi.warehouse_id IS NULL OR soi.warehouse_id = ba.warehouse_id)
ORDER BY so.fulfillment_priority DESC, so.order_date, ba.allocation_priority;

-- ========================================
-- INVENTORY OPTIMIZATION & ANALYSIS
-- ========================================

-- ABC-XYZ Analysis Matrix
WITH demand_analysis AS (
    SELECT
        p.product_id,
        p.sku,
        p.product_name,
        p.abc_classification,
        COUNT(DISTINCT soi.so_id) as order_count,
        SUM(soi.quantity_ordered) as total_quantity,
        SUM(soi.line_total) as total_revenue,
        AVG(soi.quantity_ordered) as avg_quantity,
        STDDEV(soi.quantity_ordered) as stddev_quantity,
        -- Calculate coefficient of variation for XYZ classification
        CASE
            WHEN AVG(soi.quantity_ordered) > 0
            THEN STDDEV(soi.quantity_ordered) / AVG(soi.quantity_ordered)
            ELSE 0
        END as cv
    FROM products p
    LEFT JOIN sales_order_items soi ON p.product_id = soi.product_id
    LEFT JOIN sales_orders so ON soi.so_id = so.so_id
    WHERE so.order_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
    GROUP BY p.product_id
),
xyz_classification AS (
    SELECT
        *,
        CASE
            WHEN cv < 0.5 THEN 'X'  -- Stable demand
            WHEN cv < 1.0 THEN 'Y'  -- Variable demand
            ELSE 'Z'                -- Sporadic demand
        END as xyz_class
    FROM demand_analysis
)
SELECT
    abc_classification,
    xyz_class,
    CONCAT(abc_classification, xyz_class) as classification_matrix,
    COUNT(*) as product_count,
    SUM(total_revenue) as total_revenue,
    AVG(order_count) as avg_orders,
    AVG(cv) as avg_variability,
    -- Inventory strategy recommendation
    CASE CONCAT(abc_classification, xyz_class)
        WHEN 'AX' THEN 'High stock, automatic replenishment'
        WHEN 'AY' THEN 'Medium stock, frequent review'
        WHEN 'AZ' THEN 'Low stock, make-to-order'
        WHEN 'BX' THEN 'Medium stock, periodic review'
        WHEN 'BY' THEN 'Low stock, reorder point'
        WHEN 'BZ' THEN 'Minimal stock, manual order'
        WHEN 'CX' THEN 'Low stock, batch ordering'
        WHEN 'CY' THEN 'Minimal stock, consolidate orders'
        WHEN 'CZ' THEN 'No stock, drop-ship or special order'
        ELSE 'Review required'
    END as inventory_strategy,
    GROUP_CONCAT(sku ORDER BY total_revenue DESC LIMIT 5) as top_products
FROM xyz_classification
GROUP BY abc_classification, xyz_class
ORDER BY abc_classification, xyz_class;

-- Economic Order Quantity (EOQ) calculation
WITH demand_stats AS (
    SELECT
        p.product_id,
        p.sku,
        p.product_name,
        p.unit_cost,
        p.reorder_point,
        p.lead_time_days,
        SUM(soi.quantity_ordered) as annual_demand,
        COUNT(DISTINCT so.so_id) as order_frequency,
        AVG(il.average_cost) as holding_cost_per_unit
    FROM products p
    JOIN sales_order_items soi ON p.product_id = soi.product_id
    JOIN sales_orders so ON soi.so_id = so.so_id
    JOIN inventory_levels il ON p.product_id = il.product_id
    WHERE so.order_date >= DATE_SUB(CURDATE(), INTERVAL 365 DAY)
      AND so.status != 'CANCELLED'
    GROUP BY p.product_id
)
SELECT
    product_id,
    sku,
    product_name,
    annual_demand,
    unit_cost,
    holding_cost_per_unit * 0.20 as annual_holding_cost,  -- Assume 20% holding cost
    50.00 as ordering_cost,  -- Fixed ordering cost assumption
    -- Calculate EOQ
    ROUND(SQRT(
        (2 * annual_demand * 50.00) /
        (holding_cost_per_unit * 0.20)
    ), 0) as eoq,
    -- Calculate reorder point with safety stock
    ROUND(
        (annual_demand / 365) * lead_time_days +
        1.65 * SQRT(lead_time_days) * SQRT(annual_demand / 365),  -- 95% service level
        0
    ) as suggested_reorder_point,
    reorder_point as current_reorder_point,
    -- Number of orders per year
    ROUND(annual_demand / NULLIF(
        SQRT((2 * annual_demand * 50.00) / (holding_cost_per_unit * 0.20)),
        0
    ), 1) as orders_per_year
FROM demand_stats
WHERE annual_demand > 0
ORDER BY annual_demand * unit_cost DESC;

-- ========================================
-- WAREHOUSE OPTIMIZATION
-- ========================================

-- Warehouse capacity utilization and slotting optimization
WITH warehouse_utilization AS (
    SELECT
        w.warehouse_id,
        w.warehouse_code,
        w.warehouse_type,
        w.total_capacity_cbm,
        COUNT(DISTINCT wz.zone_id) as total_zones,
        COUNT(DISTINCT wb.bin_id) as total_bins,
        SUM(CASE WHEN wb.is_occupied THEN 1 ELSE 0 END) as occupied_bins,
        SUM(wb.volume_cbm) as total_bin_volume,
        SUM(CASE WHEN wb.is_occupied THEN wb.volume_cbm ELSE 0 END) as used_volume
    FROM warehouses w
    LEFT JOIN warehouse_zones wz ON w.warehouse_id = wz.warehouse_id
    LEFT JOIN warehouse_bins wb ON wz.zone_id = wb.zone_id
    WHERE w.is_active = TRUE
    GROUP BY w.warehouse_id
),
product_velocity AS (
    SELECT
        il.warehouse_id,
        p.product_id,
        p.sku,
        p.volume_cbm,
        COUNT(im.movement_id) as movement_count,
        RANK() OVER (PARTITION BY il.warehouse_id ORDER BY COUNT(im.movement_id) DESC) as velocity_rank
    FROM inventory_levels il
    JOIN products p ON il.product_id = p.product_id
    LEFT JOIN inventory_movements im ON p.product_id = im.product_id
        AND il.warehouse_id = im.from_warehouse_id
        AND im.movement_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY il.warehouse_id, p.product_id
)
SELECT
    wu.warehouse_code,
    wu.warehouse_type,
    wu.total_capacity_cbm,
    wu.total_zones,
    wu.total_bins,
    wu.occupied_bins,
    ROUND(wu.occupied_bins * 100.0 / NULLIF(wu.total_bins, 0), 2) as bin_utilization_pct,
    ROUND(wu.used_volume * 100.0 / NULLIF(wu.total_bin_volume, 0), 2) as volume_utilization_pct,
    COUNT(DISTINCT pv.product_id) as products_stored,
    -- Fast movers in picking zones
    SUM(CASE WHEN pv.velocity_rank <= 20 THEN 1 ELSE 0 END) as fast_movers,
    -- Slow movers that could be moved to overflow
    SUM(CASE WHEN pv.velocity_rank > 100 THEN 1 ELSE 0 END) as slow_movers,
    -- Suggested actions
    CASE
        WHEN ROUND(wu.occupied_bins * 100.0 / NULLIF(wu.total_bins, 0), 2) > 90 THEN 'CRITICAL: Expand capacity'
        WHEN ROUND(wu.occupied_bins * 100.0 / NULLIF(wu.total_bins, 0), 2) > 80 THEN 'WARNING: Plan for expansion'
        WHEN ROUND(wu.occupied_bins * 100.0 / NULLIF(wu.total_bins, 0), 2) < 50 THEN 'OPPORTUNITY: Consolidate inventory'
        ELSE 'OPTIMAL'
    END as capacity_status
FROM warehouse_utilization wu
LEFT JOIN product_velocity pv ON wu.warehouse_id = pv.warehouse_id
GROUP BY wu.warehouse_id
ORDER BY bin_utilization_pct DESC;

-- ========================================
-- EXPIRY & QUALITY MANAGEMENT
-- ========================================

-- Products approaching expiry with disposition recommendations
WITH expiring_inventory AS (
    SELECT
        pb.batch_id,
        pb.product_id,
        p.sku,
        p.product_name,
        pb.warehouse_id,
        w.warehouse_code,
        pb.batch_number,
        pb.expiry_date,
        DATEDIFF(pb.expiry_date, CURDATE()) as days_until_expiry,
        pb.quantity_remaining,
        pb.quantity_remaining * il.average_cost as inventory_value,
        p.shelf_life_days,
        -- Calculate percentage of shelf life remaining
        ROUND(
            DATEDIFF(pb.expiry_date, CURDATE()) * 100.0 /
            NULLIF(p.shelf_life_days, 0),
            1
        ) as shelf_life_remaining_pct
    FROM product_batches pb
    JOIN products p ON pb.product_id = p.product_id
    JOIN warehouses w ON pb.warehouse_id = w.warehouse_id
    JOIN inventory_levels il ON pb.product_id = il.product_id
        AND pb.warehouse_id = il.warehouse_id
    WHERE pb.expiry_date IS NOT NULL
      AND pb.quantity_remaining > 0
      AND pb.expiry_date <= DATE_ADD(CURDATE(), INTERVAL 90 DAY)
)
SELECT
    warehouse_code,
    sku,
    product_name,
    batch_number,
    expiry_date,
    days_until_expiry,
    shelf_life_remaining_pct,
    quantity_remaining,
    inventory_value,
    -- Disposition recommendation
    CASE
        WHEN days_until_expiry <= 0 THEN 'DISPOSE: Expired'
        WHEN days_until_expiry <= 7 THEN 'URGENT: Discount heavily or donate'
        WHEN days_until_expiry <= 30 THEN 'PRIORITY: Promote/discount'
        WHEN shelf_life_remaining_pct <= 25 THEN 'ACTION: Prioritize for fulfillment'
        WHEN days_until_expiry <= 60 THEN 'MONITOR: Plan disposition'
        ELSE 'WATCH: Track closely'
    END as disposition_action,
    -- Suggested markdown percentage
    CASE
        WHEN days_until_expiry <= 7 THEN 75
        WHEN days_until_expiry <= 14 THEN 50
        WHEN days_until_expiry <= 30 THEN 30
        WHEN days_until_expiry <= 60 THEN 15
        ELSE 0
    END as suggested_discount_pct
FROM expiring_inventory
ORDER BY days_until_expiry, inventory_value DESC;

-- ========================================
-- CYCLE COUNT PLANNING
-- ========================================

-- Generate cycle count schedule based on ABC classification and accuracy
WITH cycle_count_frequency AS (
    SELECT
        p.product_id,
        p.sku,
        p.product_name,
        p.abc_classification,
        il.warehouse_id,
        w.warehouse_code,
        il.quantity_on_hand,
        il.last_counted_date,
        DATEDIFF(CURDATE(), IFNULL(il.last_counted_date, DATE_SUB(CURDATE(), INTERVAL 365 DAY))) as days_since_count,
        -- Determine count frequency based on ABC class
        CASE p.abc_classification
            WHEN 'A' THEN 30   -- Monthly
            WHEN 'B' THEN 90   -- Quarterly
            WHEN 'C' THEN 180  -- Semi-annually
            ELSE 365           -- Annually
        END as required_count_frequency,
        -- Calculate accuracy from recent adjustments
        COALESCE(adj.accuracy_pct, 100) as historical_accuracy
    FROM inventory_levels il
    JOIN products p ON il.product_id = p.product_id
    JOIN warehouses w ON il.warehouse_id = w.warehouse_id
    LEFT JOIN (
        SELECT
            product_id,
            from_warehouse_id as warehouse_id,
            100 - (
                ABS(SUM(CASE WHEN movement_type = 'ADJUSTMENT' THEN quantity ELSE 0 END)) * 100.0 /
                NULLIF(AVG(quantity), 0)
            ) as accuracy_pct
        FROM inventory_movements
        WHERE movement_date >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
        GROUP BY product_id, from_warehouse_id
    ) adj ON il.product_id = adj.product_id AND il.warehouse_id = adj.warehouse_id
    WHERE il.quantity_on_hand > 0
)
SELECT
    warehouse_code,
    abc_classification,
    sku,
    product_name,
    quantity_on_hand,
    last_counted_date,
    days_since_count,
    required_count_frequency,
    historical_accuracy,
    CASE
        WHEN days_since_count >= required_count_frequency THEN 'OVERDUE'
        WHEN days_since_count >= required_count_frequency * 0.8 THEN 'DUE SOON'
        WHEN historical_accuracy < 95 THEN 'ACCURACY ISSUE'
        ELSE 'ON SCHEDULE'
    END as count_status,
    -- Prioritize counts
    CASE
        WHEN days_since_count >= required_count_frequency AND abc_classification = 'A' THEN 1
        WHEN historical_accuracy < 95 AND abc_classification = 'A' THEN 2
        WHEN days_since_count >= required_count_frequency AND abc_classification = 'B' THEN 3
        WHEN historical_accuracy < 95 AND abc_classification = 'B' THEN 4
        WHEN days_since_count >= required_count_frequency THEN 5
        ELSE 6
    END as count_priority
FROM cycle_count_frequency
WHERE days_since_count >= required_count_frequency * 0.8
   OR historical_accuracy < 95
ORDER BY count_priority, days_since_count DESC
LIMIT 100;