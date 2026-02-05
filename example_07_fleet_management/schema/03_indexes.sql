-- ============================================================================
-- Fleet Management Indexes
-- ============================================================================

USE fleet_management;

-- ============================================================================
-- GPS Data Indexes (High-frequency queries)
-- ============================================================================

-- Composite index for vehicle tracking
CREATE INDEX idx_gps_vehicle_tracking
    ON gps_positions(vehicle_id, timestamp DESC, latitude, longitude, speed_mph);

-- Index for driver location history
CREATE INDEX idx_gps_driver_tracking
    ON gps_positions(driver_id, timestamp DESC)
    WHERE driver_id IS NOT NULL;

-- Index for speed violations
CREATE INDEX idx_gps_speeding
    ON gps_positions(speed_mph, timestamp DESC)
    WHERE speed_mph > 70;

-- Index for idle detection
CREATE INDEX idx_gps_idle
    ON gps_positions(vehicle_id, timestamp, speed_mph)
    WHERE ignition_on = TRUE AND speed_mph < 5;

-- Spatial index for location-based queries (if using spatial extensions)
-- CREATE SPATIAL INDEX idx_gps_spatial ON gps_positions(POINT(latitude, longitude));

-- ============================================================================
-- Trip Management Indexes
-- ============================================================================

-- Active trips lookup
CREATE INDEX idx_active_trips
    ON trips(status, vehicle_id, driver_id)
    WHERE status = 'in_progress';

-- Trip history by vehicle
CREATE INDEX idx_trip_history_vehicle
    ON trips(vehicle_id, start_time DESC, end_time);

-- Trip history by driver
CREATE INDEX idx_trip_history_driver
    ON trips(driver_id, start_time DESC, end_time);

-- Long trips detection
CREATE INDEX idx_long_trips
    ON trips(distance_miles DESC, duration_minutes DESC)
    WHERE distance_miles > 500;

-- Stop analysis
CREATE INDEX idx_stop_analysis
    ON stops(stop_type, arrival_time, duration_minutes);

-- ============================================================================
-- Driver Behavior Indexes
-- ============================================================================

-- Event analysis by driver
CREATE INDEX idx_driver_event_analysis
    ON driver_events(driver_id, event_type, timestamp DESC, severity);

-- High severity events
CREATE INDEX idx_severe_events
    ON driver_events(severity, timestamp DESC)
    WHERE severity = 'high';

-- Speeding events
CREATE INDEX idx_speeding_events
    ON driver_events(event_type, timestamp DESC, speed_mph)
    WHERE event_type = 'speeding';

-- Driver performance tracking
CREATE INDEX idx_driver_performance
    ON driver_scores(driver_id, score_date DESC, overall_score);

-- Low performing drivers
CREATE INDEX idx_low_scores
    ON driver_scores(overall_score, score_date DESC)
    WHERE overall_score < 70;

-- ============================================================================
-- Vehicle Management Indexes
-- ============================================================================

-- Active vehicles by depot
CREATE INDEX idx_active_vehicles_depot
    ON vehicles(depot_id, status, vehicle_type)
    WHERE status = 'active';

-- Maintenance due
CREATE INDEX idx_maintenance_due
    ON vehicles(next_service_miles, last_service_date)
    WHERE status = 'active';

-- Vehicle diagnostics alerts
CREATE INDEX idx_diagnostic_alerts
    ON vehicle_diagnostics(vehicle_id, timestamp DESC, check_engine_light)
    WHERE check_engine_light = TRUE;

-- Maintenance history
CREATE INDEX idx_maintenance_history
    ON maintenance_records(vehicle_id, service_date DESC, maintenance_type);

-- ============================================================================
-- Fuel Management Indexes
-- ============================================================================

-- Fuel transactions by vehicle
CREATE INDEX idx_fuel_by_vehicle
    ON fuel_transactions(vehicle_id, transaction_date DESC, gallons);

-- Fuel efficiency analysis
CREATE INDEX idx_fuel_efficiency
    ON fuel_transactions(transaction_date, gallons, total_cost);

-- Fuel card usage
CREATE INDEX idx_fuel_card_usage
    ON fuel_transactions(payment_method, driver_id, transaction_date)
    WHERE payment_method = 'fuel_card';

-- ============================================================================
-- Compliance Indexes
-- ============================================================================

-- Driver log lookup
CREATE INDEX idx_driver_log_lookup
    ON driver_logs(driver_id, log_date DESC, duty_status);

-- Active duty status
CREATE INDEX idx_active_duty
    ON driver_logs(duty_status, start_time DESC)
    WHERE end_time IS NULL;

-- HOS violation tracking
CREATE INDEX idx_hos_violations
    ON hos_violations(driver_id, violation_date DESC, violation_type);

-- Unresolved violations
CREATE INDEX idx_unresolved_violations
    ON hos_violations(resolved, severity, violation_date)
    WHERE resolved = FALSE;

-- DVIR with defects
CREATE INDEX idx_dvir_defects
    ON dvir_reports(defects_found, vehicle_id, inspection_date)
    WHERE defects_found = TRUE;

-- Unrepaired defects
CREATE INDEX idx_unrepaired_defects
    ON dvir_reports(repaired, inspection_date)
    WHERE defects_found = TRUE AND repaired = FALSE;

-- ============================================================================
-- Geofencing Indexes
-- ============================================================================

-- Active geofences
CREATE INDEX idx_active_geofences_lookup
    ON geofences(company_id, geofence_type, is_active)
    WHERE is_active = TRUE;

-- Geofence event history
CREATE INDEX idx_geofence_event_history
    ON geofence_events(geofence_id, timestamp DESC, event_type);

-- Vehicle geofence activity
CREATE INDEX idx_vehicle_geofence_activity
    ON geofence_events(vehicle_id, timestamp DESC, geofence_id);

-- ============================================================================
-- Route Management Indexes
-- ============================================================================

-- Active routes by depot
CREATE INDEX idx_active_routes_depot
    ON routes(depot_id, is_active)
    WHERE is_active = TRUE;

-- ============================================================================
-- Communication Indexes
-- ============================================================================

-- Unread messages
CREATE INDEX idx_unread_messages
    ON messages(recipient_type, recipient_id, read_status, sent_at DESC)
    WHERE read_status = FALSE;

-- High priority messages
CREATE INDEX idx_priority_messages
    ON messages(priority, sent_at DESC)
    WHERE priority IN ('high', 'urgent');

-- ============================================================================
-- Analytics and Reporting Indexes
-- ============================================================================

-- Daily summary lookup
CREATE INDEX idx_daily_summary_lookup
    ON vehicle_daily_summary(summary_date DESC, vehicle_id);

-- High mileage vehicles
CREATE INDEX idx_high_mileage
    ON vehicle_daily_summary(total_miles DESC, summary_date);

-- License expiry tracking
CREATE INDEX idx_license_expiry
    ON drivers(license_expiry, status)
    WHERE status = 'active';

-- Medical cert expiry
CREATE INDEX idx_medical_expiry
    ON drivers(medical_cert_expiry, status)
    WHERE status = 'active' AND medical_cert_expiry IS NOT NULL;

-- ============================================================================
-- Full-Text Search Indexes
-- ============================================================================

-- Driver search
CREATE FULLTEXT INDEX ft_driver_search
    ON drivers(first_name, last_name, email);

-- Vehicle search
CREATE FULLTEXT INDEX ft_vehicle_search
    ON vehicles(vehicle_number, vin, license_plate);

-- Message search
CREATE FULLTEXT INDEX ft_message_search
    ON messages(message_text);

-- Maintenance notes search
CREATE FULLTEXT INDEX ft_maintenance_search
    ON maintenance_records(description);

-- ============================================================================
-- JSON Field Indexes (MySQL 5.7+)
-- ============================================================================

-- Route waypoints (for route matching)
ALTER TABLE routes ADD INDEX idx_route_waypoints
    ((CAST(waypoints->'$[0].lat' AS DECIMAL(10,6))),
     (CAST(waypoints->'$[0].lng' AS DECIMAL(10,6))));

-- DTC codes in diagnostics
ALTER TABLE vehicle_diagnostics ADD INDEX idx_dtc_codes
    ((CAST(dtc_codes->'$[*]' AS CHAR(10) ARRAY)));

-- DVIR defect types
ALTER TABLE dvir_reports ADD INDEX idx_defect_types
    ((CAST(defect_details->'$[*].type' AS CHAR(50) ARRAY)));

-- ============================================================================
-- Covering Indexes for Common Queries
-- ============================================================================

-- Fleet dashboard query
CREATE INDEX idx_fleet_dashboard
    ON vehicles(company_id, status, vehicle_type, depot_id, odometer_miles)
    WHERE status = 'active';

-- Driver dashboard query
CREATE INDEX idx_driver_dashboard
    ON drivers(company_id, status, license_class, license_expiry)
    WHERE status = 'active';

-- Real-time tracking query
CREATE INDEX idx_realtime_tracking
    ON gps_positions(timestamp DESC, vehicle_id, latitude, longitude, speed_mph, ignition_on);

-- Compliance dashboard
CREATE INDEX idx_compliance_dashboard
    ON driver_logs(log_date DESC, driver_id, duty_status, certified);

-- ============================================================================
-- Partitioned Table Optimization
-- ============================================================================

-- Create hourly summary for GPS data
CREATE TABLE gps_positions_hourly (
    vehicle_id INT NOT NULL,
    hour_timestamp DATETIME NOT NULL,
    avg_speed_mph DECIMAL(5,2),
    max_speed_mph DECIMAL(5,2),
    distance_miles DECIMAL(10,2),
    position_count INT,
    idle_minutes INT,
    PRIMARY KEY (vehicle_id, hour_timestamp),
    INDEX idx_hourly_lookup (hour_timestamp, vehicle_id)
) ENGINE=InnoDB;

-- ============================================================================
-- Statistics Update
-- ============================================================================

-- Update table statistics for optimal query planning
ANALYZE TABLE companies;
ANALYZE TABLE depots;
ANALYZE TABLE vehicles;
ANALYZE TABLE drivers;
ANALYZE TABLE gps_positions;
ANALYZE TABLE trips;
ANALYZE TABLE driver_events;
ANALYZE TABLE driver_scores;
ANALYZE TABLE fuel_transactions;
ANALYZE TABLE maintenance_records;
ANALYZE TABLE driver_logs;
ANALYZE TABLE hos_violations;