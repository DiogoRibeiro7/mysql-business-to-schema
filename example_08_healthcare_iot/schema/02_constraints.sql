-- ============================================================================
-- Healthcare IoT Constraints
-- ============================================================================

USE healthcare_iot;

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

-- Ensure one active admission per patient
ALTER TABLE admissions
    ADD COLUMN active_patient_id INT GENERATED ALWAYS AS (
        CASE WHEN status = 'Active' THEN patient_id ELSE NULL END
    ) STORED;

CREATE UNIQUE INDEX uk_active_admission
    ON admissions(active_patient_id);

-- Ensure unique device assignment
ALTER TABLE device_assignments
    ADD COLUMN active_device_id INT GENERATED ALWAYS AS (
        CASE WHEN is_active = TRUE THEN device_id ELSE NULL END
    ) STORED;

CREATE UNIQUE INDEX uk_active_device_assignment
    ON device_assignments(active_device_id);

-- Ensure unique staff schedule
ALTER TABLE staff_schedules
    ADD CONSTRAINT uk_staff_schedule
    UNIQUE KEY (staff_id, shift_date, shift_start);

-- ============================================================================
-- Default Value Constraints
-- ============================================================================

-- Set default timestamps
ALTER TABLE vital_signs
    MODIFY COLUMN created_at DATETIME DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE device_readings
    MODIFY COLUMN created_at DATETIME DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE alerts
    MODIFY COLUMN created_at DATETIME DEFAULT CURRENT_TIMESTAMP;
