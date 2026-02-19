-- ============================================================================
-- Industrial IoT Manufacturing Indexes
-- ============================================================================

USE industrial_iot;

-- ============================================================================
-- Sensor Data Indexes (High-frequency queries)
-- ============================================================================

-- Composite index for time-series queries by sensor
CREATE INDEX idx_sensor_readings_lookup
    ON sensor_readings(sensor_id, timestamp DESC, value);

-- Index for anomaly detection queries
CREATE INDEX idx_sensor_quality
    ON sensor_readings(quality, timestamp DESC);

-- Index for latest readings per sensor
CREATE INDEX idx_sensor_latest
    ON sensor_readings(sensor_id, timestamp DESC);

-- ============================================================================
-- Production Performance Indexes
-- ============================================================================

-- Work order tracking and scheduling
CREATE INDEX idx_order_schedule
    ON work_orders(planned_start_time, planned_end_time, status);

-- Active work orders by line
CREATE INDEX idx_active_orders
    ON work_orders(line_id, status, planned_start_time);

-- Production run performance analysis
CREATE INDEX idx_run_performance
    ON production_runs(machine_id, start_time, end_time, quantity_good);

-- Quality tracking by product
CREATE INDEX idx_product_quality
    ON quality_inspections(product_id, inspection_time, pass_fail);

-- Defect analysis
CREATE INDEX idx_defect_analysis
    ON defects(defect_type, severity, created_at);

-- ============================================================================
-- OEE Calculation Indexes
-- ============================================================================

-- OEE trend analysis by machine
CREATE INDEX idx_oee_machine_trend
    ON oee_metrics(machine_id, metric_timestamp DESC, oee_percentage);

-- OEE by line for dashboard
CREATE INDEX idx_oee_line_dashboard
    ON oee_metrics(line_id, metric_timestamp DESC, availability_percentage,
                  performance_percentage, quality_percentage);

-- Low OEE detection
CREATE INDEX idx_low_oee
    ON oee_metrics(oee_percentage, metric_timestamp DESC);

-- ============================================================================
-- Maintenance Management Indexes
-- ============================================================================

-- Upcoming maintenance
CREATE INDEX idx_maintenance_due
    ON maintenance_schedules(next_due, machine_id);

-- Maintenance history by machine
CREATE INDEX idx_maintenance_history
    ON maintenance_records(machine_id, start_time DESC, maintenance_type);

-- Active maintenance work
CREATE INDEX idx_active_maintenance
    ON maintenance_records(status, start_time);

-- ============================================================================
-- Downtime Analysis Indexes
-- ============================================================================

-- Downtime by reason
CREATE INDEX idx_downtime_reason
    ON downtime_events(reason_category, start_time DESC, duration_minutes);

-- Active downtime events
CREATE INDEX idx_active_downtime
    ON downtime_events(end_time, machine_id);

-- Downtime impact analysis
CREATE INDEX idx_downtime_impact
    ON downtime_events(impact_level, lost_production_units, start_time DESC);

-- ============================================================================
-- Alert Management Indexes
-- ============================================================================

-- Unacknowledged alerts
CREATE INDEX idx_unacked_alerts
    ON alerts(severity, triggered_at DESC);

-- Unresolved alerts
CREATE INDEX idx_unresolved_alerts
    ON alerts(source_type, source_id, triggered_at DESC);

-- Alert history by source
CREATE INDEX idx_alert_source
    ON alerts(source_type, source_id, triggered_at DESC);

-- ============================================================================
-- Shift and Operator Indexes
-- ============================================================================

-- Shift performance tracking
CREATE INDEX idx_shift_performance
    ON shift_logs(shift_date DESC, shift_type, oee_actual);

-- Active operators by shift
CREATE INDEX idx_operator_shift
    ON operators(shift, factory_id, is_active);

-- Operator skill search
CREATE INDEX idx_operator_skills
    ON operators(skill_level, factory_id);

-- ============================================================================
-- Machine Status Indexes
-- ============================================================================

-- Current machine status
CREATE INDEX idx_machine_current_status
    ON machines(status, line_id);

-- Machines by type and status
CREATE INDEX idx_machine_type_status
    ON machines(machine_type, status, line_id);

-- High utilization machines
CREATE INDEX idx_machine_utilization
    ON machines(total_operating_hours DESC, total_cycle_count DESC);

-- ============================================================================
-- Full-Text Search Indexes
-- ============================================================================

-- Product search
CREATE FULLTEXT INDEX ft_product_search
    ON products(product_name, product_category);

-- Maintenance notes search
CREATE FULLTEXT INDEX ft_maintenance_notes
    ON maintenance_records(findings, actions_taken, next_action);

-- Alert message search
CREATE FULLTEXT INDEX ft_alert_messages
    ON alerts(message, resolution_notes);

-- ============================================================================
-- JSON Field Indexes (MySQL 5.7+)
-- ============================================================================

-- Product BOM component search
ALTER TABLE products ADD INDEX idx_bom_components
    ((CAST(bom->'$.components[*].part_number' AS CHAR(100) ARRAY)));

-- Quality spec parameter index
ALTER TABLE products ADD INDEX idx_quality_params
    ((CAST(quality_specs->'$.parameters[*].name' AS CHAR(50) ARRAY)));

-- Operator certification index
ALTER TABLE operators ADD INDEX idx_certifications
    ((CAST(certifications->'$[*].type' AS CHAR(50) ARRAY)));

-- ============================================================================
-- Covering Indexes for Common Queries
-- ============================================================================

-- Dashboard query - current production status
CREATE INDEX idx_dashboard_production
    ON work_orders(status, line_id, product_id, planned_start_time,
                  planned_quantity, produced_quantity);

-- Machine availability calculation
CREATE INDEX idx_machine_availability
    ON downtime_events(machine_id, start_time, end_time, duration_minutes);

-- Quality trend analysis
CREATE INDEX idx_quality_trend
    ON quality_inspections(product_id, inspection_time, pass_fail, defects_found);

-- Sensor alert correlation
CREATE INDEX idx_sensor_alert_correlation
    ON sensor_readings(sensor_id, timestamp, value);

-- ============================================================================
-- Partitioned Table Optimization
-- ============================================================================

-- Local index for each partition (automatically created)
-- Global indexes would need to be simulated with materialized views

-- Create summary table for fast aggregation
CREATE TABLE sensor_readings_hourly (
    sensor_id INT NOT NULL,
    hour_timestamp DATETIME NOT NULL,
    min_value DECIMAL(12,4),
    max_value DECIMAL(12,4),
    avg_value DECIMAL(12,4),
    reading_count INT,
    PRIMARY KEY (sensor_id, hour_timestamp),
    INDEX idx_hourly_lookup (hour_timestamp, sensor_id)
) ENGINE=InnoDB;

-- ============================================================================
-- Statistics Update
-- ============================================================================

-- Update table statistics for optimal query planning
ANALYZE TABLE factories;
ANALYZE TABLE production_lines;
ANALYZE TABLE machines;
ANALYZE TABLE sensors;
ANALYZE TABLE sensor_readings;
ANALYZE TABLE work_orders;
ANALYZE TABLE production_runs;
ANALYZE TABLE quality_inspections;
ANALYZE TABLE oee_metrics;
ANALYZE TABLE maintenance_records;
ANALYZE TABLE downtime_events;
ANALYZE TABLE alerts;
