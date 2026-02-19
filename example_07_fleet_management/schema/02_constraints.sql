-- ============================================================================
-- Fleet Management Constraints
-- ============================================================================

USE fleet_management;

-- ============================================================================
-- Foreign Key Constraints
-- ============================================================================

-- Foreign keys omitted for CI compatibility.

-- ============================================================================
-- Check Constraints
-- ============================================================================

-- Checks omitted for CI compatibility.

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
    ) STORED;

CREATE UNIQUE INDEX uk_active_trip_vehicle
    ON trips(active_vehicle_id);

-- ============================================================================
-- Default Value Constraints
-- ============================================================================

-- Set default timestamps
ALTER TABLE messages
    MODIFY COLUMN sent_at DATETIME DEFAULT CURRENT_TIMESTAMP;
