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
    CHECK (year BETWEEN 1990 AND 2100);

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
    CHECK (status != 'active' OR license_expiry > '2100-01-01');

-- ============================================================================
-- Triggers for Business Logic
-- ============================================================================


-- ============================================================================
-- Unique Constraints
-- ============================================================================

-- Ensure unique stop sequence per trip
ALTER TABLE stops
    ADD CONSTRAINT uk_trip_stop_sequence
    UNIQUE KEY (trip_id, stop_sequence);

-- Ensure one active trip per vehicle
ALTER TABLE trips
    ADD COLUMN active_vehicle_id INT GENERATED ALWAYS AS (
        CASE WHEN status = 'in_progress' THEN vehicle_id ELSE NULL END
    ) STORED,
    ADD UNIQUE INDEX uk_active_trip_vehicle (active_vehicle_id);

-- ============================================================================
-- Default Value Constraints
-- ============================================================================

-- Set default timestamps
ALTER TABLE messages
    MODIFY COLUMN sent_at DATETIME DEFAULT CURRENT_TIMESTAMP;
