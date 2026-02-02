-- ============================================================================
-- IoT Garbage Bin Monitoring System - Constraints
-- ============================================================================
-- Description: Defines foreign keys, check constraints, and referential integrity
-- Dependencies: 01_tables.sql must be run first
-- ============================================================================

USE iot_bins;

-- ============================================================================
-- Foreign Key Constraints
-- ============================================================================

-- Bins table constraints
ALTER TABLE bins
    ADD CONSTRAINT fk_bins_district
        FOREIGN KEY (district_id) REFERENCES districts(district_id)
        ON DELETE RESTRICT ON UPDATE CASCADE;

-- Sensors table constraints
ALTER TABLE sensors
    ADD CONSTRAINT fk_sensors_bin
        FOREIGN KEY (bin_id) REFERENCES bins(bin_id)
        ON DELETE CASCADE ON UPDATE CASCADE;

-- Collection Routes table constraints
ALTER TABLE collection_routes
    ADD CONSTRAINT fk_routes_district
        FOREIGN KEY (district_id) REFERENCES districts(district_id)
        ON DELETE RESTRICT ON UPDATE CASCADE;

-- Route Bin Assignments table constraints
ALTER TABLE route_bin_assignments
    ADD CONSTRAINT fk_assignment_route
        FOREIGN KEY (route_id) REFERENCES collection_routes(route_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    ADD CONSTRAINT fk_assignment_bin
        FOREIGN KEY (bin_id) REFERENCES bins(bin_id)
        ON DELETE CASCADE ON UPDATE CASCADE;

-- Collection Schedules table constraints
ALTER TABLE collection_schedules
    ADD CONSTRAINT fk_schedule_route
        FOREIGN KEY (route_id) REFERENCES collection_routes(route_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    ADD CONSTRAINT fk_schedule_truck
        FOREIGN KEY (truck_id) REFERENCES trucks(truck_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    ADD CONSTRAINT fk_schedule_driver
        FOREIGN KEY (driver_id) REFERENCES drivers(driver_id)
        ON DELETE RESTRICT ON UPDATE CASCADE;

-- Collection Events table constraints
ALTER TABLE collection_events
    ADD CONSTRAINT fk_event_bin
        FOREIGN KEY (bin_id) REFERENCES bins(bin_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    ADD CONSTRAINT fk_event_schedule
        FOREIGN KEY (schedule_id) REFERENCES collection_schedules(schedule_id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    ADD CONSTRAINT fk_event_truck
        FOREIGN KEY (truck_id) REFERENCES trucks(truck_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    ADD CONSTRAINT fk_event_driver
        FOREIGN KEY (driver_id) REFERENCES drivers(driver_id)
        ON DELETE RESTRICT ON UPDATE CASCADE;

-- Sensor Readings table constraints
ALTER TABLE sensor_readings
    ADD CONSTRAINT fk_readings_sensor
        FOREIGN KEY (sensor_id) REFERENCES sensors(sensor_id)
        ON DELETE CASCADE ON UPDATE CASCADE;

-- Sensor Readings Hourly table constraints
ALTER TABLE sensor_readings_hourly
    ADD CONSTRAINT fk_hourly_sensor
        FOREIGN KEY (sensor_id) REFERENCES sensors(sensor_id)
        ON DELETE CASCADE ON UPDATE CASCADE;

-- Sensor Readings Daily table constraints
ALTER TABLE sensor_readings_daily
    ADD CONSTRAINT fk_daily_sensor
        FOREIGN KEY (sensor_id) REFERENCES sensors(sensor_id)
        ON DELETE CASCADE ON UPDATE CASCADE;

-- Alerts table constraints
ALTER TABLE alerts
    ADD CONSTRAINT fk_alerts_bin
        FOREIGN KEY (bin_id) REFERENCES bins(bin_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    ADD CONSTRAINT fk_alerts_sensor
        FOREIGN KEY (sensor_id) REFERENCES sensors(sensor_id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    ADD CONSTRAINT fk_alerts_threshold
        FOREIGN KEY (threshold_id) REFERENCES alert_thresholds(threshold_id)
        ON DELETE SET NULL ON UPDATE CASCADE;

-- Fill Rate Predictions table constraints
ALTER TABLE fill_rate_predictions
    ADD CONSTRAINT fk_predictions_bin
        FOREIGN KEY (bin_id) REFERENCES bins(bin_id)
        ON DELETE CASCADE ON UPDATE CASCADE;

-- ============================================================================
-- Check Constraints
-- ============================================================================

-- Districts table checks
ALTER TABLE districts
    ADD CONSTRAINT chk_district_area CHECK (area_km2 > 0),
    ADD CONSTRAINT chk_district_population CHECK (population >= 0);

-- Bins table checks
ALTER TABLE bins
    ADD CONSTRAINT chk_bin_capacity CHECK (capacity_liters > 0),
    ADD CONSTRAINT chk_bin_latitude CHECK (latitude BETWEEN -90 AND 90),
    ADD CONSTRAINT chk_bin_longitude CHECK (longitude BETWEEN -180 AND 180);

-- Sensors table checks
ALTER TABLE sensors
    ADD CONSTRAINT chk_sensor_frequency CHECK (reading_frequency_seconds > 0),
    ADD CONSTRAINT chk_sensor_battery CHECK (battery_level BETWEEN 0 AND 100);

-- Collection Routes table checks
ALTER TABLE collection_routes
    ADD CONSTRAINT chk_route_duration CHECK (estimated_duration_minutes > 0),
    ADD CONSTRAINT chk_route_distance CHECK (estimated_distance_km > 0);

-- Route Bin Assignments table checks
ALTER TABLE route_bin_assignments
    ADD CONSTRAINT chk_assignment_order CHECK (collection_order > 0);

-- Trucks table checks
ALTER TABLE trucks
    ADD CONSTRAINT chk_truck_capacity CHECK (capacity_kg > 0),
    ADD CONSTRAINT chk_truck_year CHECK (year >= 1990 AND year <= YEAR(CURDATE()) + 1),
    ADD CONSTRAINT chk_truck_odometer CHECK (odometer_km >= 0);

-- Drivers table checks
ALTER TABLE drivers
    ADD CONSTRAINT chk_driver_license_expiry CHECK (license_expiry_date > hire_date);

-- Collection Schedules table checks
ALTER TABLE collection_schedules
    ADD CONSTRAINT chk_schedule_times CHECK (scheduled_end_time > scheduled_start_time);

-- Collection Events table checks
ALTER TABLE collection_events
    ADD CONSTRAINT chk_event_fill_level CHECK (fill_level_before BETWEEN 0 AND 100),
    ADD CONSTRAINT chk_event_weight CHECK (weight_kg >= 0),
    ADD CONSTRAINT chk_event_duration CHECK (collection_duration_seconds >= 0);

-- Sensor Readings Hourly table checks
ALTER TABLE sensor_readings_hourly
    ADD CONSTRAINT chk_hourly_counts CHECK (reading_count > 0);

-- Sensor Readings Daily table checks
ALTER TABLE sensor_readings_daily
    ADD CONSTRAINT chk_daily_counts CHECK (reading_count > 0),
    ADD CONSTRAINT chk_daily_quality_pct CHECK (
        quality_good_pct >= 0 AND quality_good_pct <= 100 AND
        quality_warning_pct >= 0 AND quality_warning_pct <= 100 AND
        quality_error_pct >= 0 AND quality_error_pct <= 100
    );

-- Alert Thresholds table checks
ALTER TABLE alert_thresholds
    ADD CONSTRAINT chk_threshold_values CHECK (critical_value >= warning_value OR critical_value IS NULL OR warning_value IS NULL),
    ADD CONSTRAINT chk_threshold_interval CHECK (check_interval_seconds > 0);

-- Fill Rate Predictions table checks
ALTER TABLE fill_rate_predictions
    ADD CONSTRAINT chk_prediction_fill_rate CHECK (predicted_fill_rate BETWEEN 0 AND 100),
    ADD CONSTRAINT chk_prediction_confidence CHECK (confidence_score BETWEEN 0 AND 100);

-- Display confirmation
SELECT 'All constraints created successfully' AS Status;