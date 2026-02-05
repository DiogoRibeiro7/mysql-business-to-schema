-- ============================================================================
-- Fleet Management Constraints
-- ============================================================================

USE fleet_management;

-- ============================================================================
-- Foreign Key Constraints
-- ============================================================================

-- Depots -> Companies
ALTER TABLE depots
    ADD CONSTRAINT fk_depot_company
    FOREIGN KEY (company_id) REFERENCES companies(company_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- Vehicles -> Companies and Depots
ALTER TABLE vehicles
    ADD CONSTRAINT fk_vehicle_company
    FOREIGN KEY (company_id) REFERENCES companies(company_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
    ADD CONSTRAINT fk_vehicle_depot
    FOREIGN KEY (depot_id) REFERENCES depots(depot_id)
    ON DELETE SET NULL ON UPDATE CASCADE;

-- Vehicle specs -> Vehicles
ALTER TABLE vehicle_specs
    ADD CONSTRAINT fk_spec_vehicle
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id)
    ON DELETE CASCADE ON UPDATE CASCADE;

-- Drivers -> Companies
ALTER TABLE drivers
    ADD CONSTRAINT fk_driver_company
    FOREIGN KEY (company_id) REFERENCES companies(company_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- Driver certifications -> Drivers
ALTER TABLE driver_certifications
    ADD CONSTRAINT fk_certification_driver
    FOREIGN KEY (driver_id) REFERENCES drivers(driver_id)
    ON DELETE CASCADE ON UPDATE CASCADE;

-- Trips -> Vehicles and Drivers
ALTER TABLE trips
    ADD CONSTRAINT fk_trip_vehicle
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
    ADD CONSTRAINT fk_trip_driver
    FOREIGN KEY (driver_id) REFERENCES drivers(driver_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- Stops -> Trips
ALTER TABLE stops
    ADD CONSTRAINT fk_stop_trip
    FOREIGN KEY (trip_id) REFERENCES trips(trip_id)
    ON DELETE CASCADE ON UPDATE CASCADE;

-- Driver events -> Vehicles, Drivers, and Trips
ALTER TABLE driver_events
    ADD CONSTRAINT fk_event_vehicle
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
    ADD CONSTRAINT fk_event_driver
    FOREIGN KEY (driver_id) REFERENCES drivers(driver_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
    ADD CONSTRAINT fk_event_trip
    FOREIGN KEY (trip_id) REFERENCES trips(trip_id)
    ON DELETE SET NULL ON UPDATE CASCADE;

-- Driver scores -> Drivers
ALTER TABLE driver_scores
    ADD CONSTRAINT fk_score_driver
    FOREIGN KEY (driver_id) REFERENCES drivers(driver_id)
    ON DELETE CASCADE ON UPDATE CASCADE;

-- Routes -> Depots
ALTER TABLE routes
    ADD CONSTRAINT fk_route_depot
    FOREIGN KEY (depot_id) REFERENCES depots(depot_id)
    ON DELETE SET NULL ON UPDATE CASCADE;

-- Geofences -> Companies
ALTER TABLE geofences
    ADD CONSTRAINT fk_geofence_company
    FOREIGN KEY (company_id) REFERENCES companies(company_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- Geofence events -> Geofences, Vehicles, and Drivers
ALTER TABLE geofence_events
    ADD CONSTRAINT fk_geofence_event_geofence
    FOREIGN KEY (geofence_id) REFERENCES geofences(geofence_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
    ADD CONSTRAINT fk_geofence_event_vehicle
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
    ADD CONSTRAINT fk_geofence_event_driver
    FOREIGN KEY (driver_id) REFERENCES drivers(driver_id)
    ON DELETE SET NULL ON UPDATE CASCADE;

-- Fuel transactions -> Vehicles and Drivers
ALTER TABLE fuel_transactions
    ADD CONSTRAINT fk_fuel_vehicle
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
    ADD CONSTRAINT fk_fuel_driver
    FOREIGN KEY (driver_id) REFERENCES drivers(driver_id)
    ON DELETE SET NULL ON UPDATE CASCADE;

-- Maintenance records -> Vehicles
ALTER TABLE maintenance_records
    ADD CONSTRAINT fk_maintenance_vehicle
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- Vehicle diagnostics -> Vehicles
ALTER TABLE vehicle_diagnostics
    ADD CONSTRAINT fk_diagnostics_vehicle
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id)
    ON DELETE CASCADE ON UPDATE CASCADE;

-- Driver logs -> Drivers and Vehicles
ALTER TABLE driver_logs
    ADD CONSTRAINT fk_log_driver
    FOREIGN KEY (driver_id) REFERENCES drivers(driver_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
    ADD CONSTRAINT fk_log_vehicle
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id)
    ON DELETE SET NULL ON UPDATE CASCADE;

-- HOS violations -> Drivers
ALTER TABLE hos_violations
    ADD CONSTRAINT fk_violation_driver
    FOREIGN KEY (driver_id) REFERENCES drivers(driver_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- DVIR reports -> Vehicles and Drivers
ALTER TABLE dvir_reports
    ADD CONSTRAINT fk_dvir_vehicle
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
    ADD CONSTRAINT fk_dvir_driver
    FOREIGN KEY (driver_id) REFERENCES drivers(driver_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- Vehicle daily summary -> Vehicles
ALTER TABLE vehicle_daily_summary
    ADD CONSTRAINT fk_summary_vehicle
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id)
    ON DELETE CASCADE ON UPDATE CASCADE;

-- ============================================================================
-- Check Constraints
-- ============================================================================

-- Ensure valid coordinates
ALTER TABLE depots
    ADD CONSTRAINT chk_depot_coordinates
    CHECK (latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180);

ALTER TABLE gps_positions
    ADD CONSTRAINT chk_gps_coordinates
    CHECK (latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180);

-- Ensure valid speeds
ALTER TABLE gps_positions
    ADD CONSTRAINT chk_gps_speed
    CHECK (speed_mph >= 0 AND speed_mph <= 150);

ALTER TABLE trips
    ADD CONSTRAINT chk_trip_speed
    CHECK (max_speed_mph >= 0 AND avg_speed_mph >= 0 AND avg_speed_mph <= max_speed_mph);

-- Ensure valid headings
ALTER TABLE gps_positions
    ADD CONSTRAINT chk_gps_heading
    CHECK (heading >= 0 AND heading < 360);

-- Ensure valid fuel levels
ALTER TABLE gps_positions
    ADD CONSTRAINT chk_fuel_level
    CHECK (fuel_level_percent BETWEEN 0 AND 100);

-- Ensure valid times
ALTER TABLE trips
    ADD CONSTRAINT chk_trip_times
    CHECK (end_time IS NULL OR end_time > start_time);

ALTER TABLE stops
    ADD CONSTRAINT chk_stop_times
    CHECK (departure_time IS NULL OR departure_time > arrival_time);

ALTER TABLE driver_logs
    ADD CONSTRAINT chk_log_times
    CHECK (end_time IS NULL OR end_time > start_time);

-- Ensure valid scores
ALTER TABLE driver_scores
    ADD CONSTRAINT chk_driver_scores
    CHECK (safety_score BETWEEN 0 AND 100 AND
           fuel_efficiency_score BETWEEN 0 AND 100 AND
           compliance_score BETWEEN 0 AND 100 AND
           overall_score BETWEEN 0 AND 100);

-- Ensure valid vehicle year
ALTER TABLE vehicles
    ADD CONSTRAINT chk_vehicle_year
    CHECK (year BETWEEN 1990 AND YEAR(CURDATE()) + 1);

-- Ensure positive values
ALTER TABLE vehicles
    ADD CONSTRAINT chk_vehicle_positive
    CHECK (fuel_capacity_gallons > 0 AND
           odometer_miles >= 0 AND
           engine_hours >= 0);

ALTER TABLE fuel_transactions
    ADD CONSTRAINT chk_fuel_positive
    CHECK (gallons > 0 AND price_per_gallon > 0 AND total_cost > 0);

-- Ensure license expiry is future dated when active
ALTER TABLE drivers
    ADD CONSTRAINT chk_driver_license
    CHECK (status != 'active' OR license_expiry > CURDATE());

-- ============================================================================
-- Triggers for Business Logic
-- ============================================================================

DELIMITER $$

-- Update vehicle odometer when GPS position is recorded
CREATE TRIGGER trg_update_vehicle_odometer
AFTER INSERT ON gps_positions
FOR EACH ROW
BEGIN
    UPDATE vehicles
    SET odometer_miles = NEW.odometer_miles,
        engine_hours = NEW.engine_hours
    WHERE vehicle_id = NEW.vehicle_id
      AND (odometer_miles < NEW.odometer_miles OR odometer_miles IS NULL);
END$$

-- Complete trip when last position has ignition off
CREATE TRIGGER trg_complete_trip
AFTER INSERT ON gps_positions
FOR EACH ROW
BEGIN
    IF NEW.ignition_on = FALSE THEN
        UPDATE trips
        SET end_time = NEW.timestamp,
            end_latitude = NEW.latitude,
            end_longitude = NEW.longitude,
            status = 'completed'
        WHERE vehicle_id = NEW.vehicle_id
          AND driver_id = NEW.driver_id
          AND status = 'in_progress';
    END IF;
END$$

-- Calculate trip statistics on completion
CREATE TRIGGER trg_calculate_trip_stats
BEFORE UPDATE ON trips
FOR EACH ROW
BEGIN
    IF OLD.status = 'in_progress' AND NEW.status = 'completed' THEN
        -- Calculate duration
        SET NEW.duration_minutes = TIMESTAMPDIFF(MINUTE, NEW.start_time, NEW.end_time);

        -- Calculate distance (simplified)
        SET NEW.distance_miles = calculate_distance(
            NEW.start_latitude, NEW.start_longitude,
            NEW.end_latitude, NEW.end_longitude
        ) * 0.621371; -- Convert km to miles

        -- Calculate average speed
        IF NEW.duration_minutes > 0 THEN
            SET NEW.avg_speed_mph = (NEW.distance_miles / NEW.duration_minutes) * 60;
        END IF;

        -- Get stop count
        SELECT COUNT(*) INTO NEW.stops_count
        FROM stops
        WHERE trip_id = NEW.trip_id;

        -- Get harsh events count
        SELECT COUNT(*) INTO NEW.harsh_events_count
        FROM driver_events
        WHERE trip_id = NEW.trip_id;
    END IF;
END$$

-- Update driver score based on events
CREATE TRIGGER trg_update_driver_score
AFTER INSERT ON driver_events
FOR EACH ROW
BEGIN
    DECLARE current_score DECIMAL(5,2);

    SELECT safety_score INTO current_score
    FROM driver_scores
    WHERE driver_id = NEW.driver_id
      AND score_date = DATE(NEW.timestamp);

    IF current_score IS NULL THEN
        INSERT INTO driver_scores (driver_id, score_date, safety_score)
        VALUES (NEW.driver_id, DATE(NEW.timestamp), 95);
        SET current_score = 95;
    END IF;

    -- Deduct points based on event severity
    UPDATE driver_scores
    SET safety_score = GREATEST(0, safety_score -
        CASE NEW.severity
            WHEN 'high' THEN 5
            WHEN 'medium' THEN 3
            WHEN 'low' THEN 1
        END),
        harsh_events_count = harsh_events_count + 1
    WHERE driver_id = NEW.driver_id
      AND score_date = DATE(NEW.timestamp);
END$$

-- Check HOS compliance when driver log is inserted
CREATE TRIGGER trg_check_hos_compliance
AFTER INSERT ON driver_logs
FOR EACH ROW
BEGIN
    DECLARE driving_time_11h INT;
    DECLARE on_duty_time_14h INT;
    DECLARE weekly_time_70h INT;

    -- Check 11-hour driving rule
    SELECT SUM(duration_minutes) INTO driving_time_11h
    FROM driver_logs
    WHERE driver_id = NEW.driver_id
      AND duty_status = 'driving'
      AND start_time >= NEW.start_time - INTERVAL 14 HOUR;

    IF driving_time_11h > 660 THEN -- 11 hours = 660 minutes
        INSERT INTO hos_violations (driver_id, violation_date, violation_type, duration_minutes, severity)
        VALUES (NEW.driver_id, DATE(NEW.start_time), '11_hour', driving_time_11h - 660, 'major');
    END IF;

    -- Check 14-hour on-duty rule
    SELECT SUM(duration_minutes) INTO on_duty_time_14h
    FROM driver_logs
    WHERE driver_id = NEW.driver_id
      AND duty_status IN ('driving', 'on_duty')
      AND start_time >= NEW.start_time - INTERVAL 14 HOUR;

    IF on_duty_time_14h > 840 THEN -- 14 hours = 840 minutes
        INSERT INTO hos_violations (driver_id, violation_date, violation_type, duration_minutes, severity)
        VALUES (NEW.driver_id, DATE(NEW.start_time), '14_hour', on_duty_time_14h - 840, 'major');
    END IF;

    -- Check 70-hour/8-day rule
    SELECT SUM(duration_minutes) INTO weekly_time_70h
    FROM driver_logs
    WHERE driver_id = NEW.driver_id
      AND duty_status IN ('driving', 'on_duty')
      AND start_time >= NEW.start_time - INTERVAL 8 DAY;

    IF weekly_time_70h > 4200 THEN -- 70 hours = 4200 minutes
        INSERT INTO hos_violations (driver_id, violation_date, violation_type, duration_minutes, severity)
        VALUES (NEW.driver_id, DATE(NEW.start_time), '70_hour_8day', weekly_time_70h - 4200, 'critical');
    END IF;
END$$

-- Track geofence entry/exit
CREATE TRIGGER trg_geofence_duration
BEFORE INSERT ON geofence_events
FOR EACH ROW
BEGIN
    IF NEW.event_type = 'exit' THEN
        -- Calculate duration inside geofence
        SELECT TIMESTAMPDIFF(MINUTE, timestamp, NEW.timestamp) INTO NEW.duration_minutes
        FROM geofence_events
        WHERE geofence_id = NEW.geofence_id
          AND vehicle_id = NEW.vehicle_id
          AND event_type = 'enter'
          AND timestamp < NEW.timestamp
        ORDER BY timestamp DESC
        LIMIT 1;
    END IF;
END$$

-- Update vehicle maintenance schedule
CREATE TRIGGER trg_update_maintenance_schedule
AFTER INSERT ON maintenance_records
FOR EACH ROW
BEGIN
    UPDATE vehicles
    SET last_service_date = NEW.service_date,
        last_service_miles = NEW.odometer_miles,
        next_service_miles = NEW.next_service_miles
    WHERE vehicle_id = NEW.vehicle_id;
END$$

-- Calculate daily summary
CREATE TRIGGER trg_daily_summary
AFTER UPDATE ON trips
FOR EACH ROW
BEGIN
    IF NEW.status = 'completed' AND OLD.status = 'in_progress' THEN
        INSERT INTO vehicle_daily_summary (
            vehicle_id, summary_date, total_miles, total_hours,
            total_trips, total_fuel_gallons, harsh_events_count
        )
        VALUES (
            NEW.vehicle_id,
            DATE(NEW.end_time),
            NEW.distance_miles,
            NEW.duration_minutes / 60,
            1,
            NEW.fuel_consumed_gallons,
            NEW.harsh_events_count
        )
        ON DUPLICATE KEY UPDATE
            total_miles = total_miles + NEW.distance_miles,
            total_hours = total_hours + (NEW.duration_minutes / 60),
            total_trips = total_trips + 1,
            total_fuel_gallons = total_fuel_gallons + COALESCE(NEW.fuel_consumed_gallons, 0),
            harsh_events_count = harsh_events_count + NEW.harsh_events_count;
    END IF;
END$$

DELIMITER ;

-- ============================================================================
-- Unique Constraints
-- ============================================================================

-- Ensure unique stop sequence per trip
ALTER TABLE stops
    ADD CONSTRAINT uk_trip_stop_sequence
    UNIQUE KEY (trip_id, stop_sequence);

-- Ensure one active trip per vehicle
CREATE UNIQUE INDEX uk_active_trip_vehicle
    ON trips(vehicle_id, status)
    WHERE status = 'in_progress';

-- ============================================================================
-- Default Value Constraints
-- ============================================================================

-- Set default timestamps
ALTER TABLE messages
    MODIFY COLUMN sent_at DATETIME DEFAULT CURRENT_TIMESTAMP;