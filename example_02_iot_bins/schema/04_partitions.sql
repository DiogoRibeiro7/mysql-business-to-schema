-- ============================================================================
-- IoT Garbage Bin Monitoring System - Table Partitioning
-- ============================================================================
-- Description: Implements partitioning for time series tables to improve performance
-- Dependencies: 01_tables.sql must be run first
-- ============================================================================

USE iot_bins;

-- Drop the existing sensor_readings table to recreate with partitioning
DROP TABLE IF EXISTS sensor_readings;

-- ============================================================================
-- Recreate Sensor Readings Table with Monthly Partitioning
-- ============================================================================

CREATE TABLE sensor_readings (
    reading_id BIGINT UNSIGNED AUTO_INCREMENT,
    sensor_id INT UNSIGNED NOT NULL,
    reading_time TIMESTAMP NOT NULL,
    reading_value DECIMAL(10, 3) NOT NULL,
    unit VARCHAR(20) NOT NULL,
    quality ENUM('good', 'warning', 'error') DEFAULT 'good',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (reading_id, reading_time),
    INDEX idx_sensor_time (sensor_id, reading_time),
    INDEX idx_reading_time (reading_time),
    INDEX idx_quality (quality),
    INDEX idx_sensor_time_quality (sensor_id, reading_time, quality),
    INDEX idx_time_sensor (reading_time, sensor_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
PARTITION BY RANGE (UNIX_TIMESTAMP(reading_time)) (
    -- Historical partitions (2024)
    PARTITION p2024_10 VALUES LESS THAN (UNIX_TIMESTAMP('2024-11-01 00:00:00')),
    PARTITION p2024_11 VALUES LESS THAN (UNIX_TIMESTAMP('2024-12-01 00:00:00')),
    PARTITION p2024_12 VALUES LESS THAN (UNIX_TIMESTAMP('2025-01-01 00:00:00')),

    -- Current year partitions (2025)
    PARTITION p2025_01 VALUES LESS THAN (UNIX_TIMESTAMP('2025-02-01 00:00:00')),
    PARTITION p2025_02 VALUES LESS THAN (UNIX_TIMESTAMP('2025-03-01 00:00:00')),
    PARTITION p2025_03 VALUES LESS THAN (UNIX_TIMESTAMP('2025-04-01 00:00:00')),
    PARTITION p2025_04 VALUES LESS THAN (UNIX_TIMESTAMP('2025-05-01 00:00:00')),
    PARTITION p2025_05 VALUES LESS THAN (UNIX_TIMESTAMP('2025-06-01 00:00:00')),
    PARTITION p2025_06 VALUES LESS THAN (UNIX_TIMESTAMP('2025-07-01 00:00:00')),
    PARTITION p2025_07 VALUES LESS THAN (UNIX_TIMESTAMP('2025-08-01 00:00:00')),
    PARTITION p2025_08 VALUES LESS THAN (UNIX_TIMESTAMP('2025-09-01 00:00:00')),
    PARTITION p2025_09 VALUES LESS THAN (UNIX_TIMESTAMP('2025-10-01 00:00:00')),
    PARTITION p2025_10 VALUES LESS THAN (UNIX_TIMESTAMP('2025-11-01 00:00:00')),
    PARTITION p2025_11 VALUES LESS THAN (UNIX_TIMESTAMP('2025-12-01 00:00:00')),
    PARTITION p2025_12 VALUES LESS THAN (UNIX_TIMESTAMP('2026-01-01 00:00:00')),

    -- Future partitions (2026)
    PARTITION p2026_01 VALUES LESS THAN (UNIX_TIMESTAMP('2026-02-01 00:00:00')),
    PARTITION p2026_02 VALUES LESS THAN (UNIX_TIMESTAMP('2026-03-01 00:00:00')),
    PARTITION p2026_03 VALUES LESS THAN (UNIX_TIMESTAMP('2026-04-01 00:00:00')),
    PARTITION p2026_04 VALUES LESS THAN (UNIX_TIMESTAMP('2026-05-01 00:00:00')),
    PARTITION p2026_05 VALUES LESS THAN (UNIX_TIMESTAMP('2026-06-01 00:00:00')),
    PARTITION p2026_06 VALUES LESS THAN (UNIX_TIMESTAMP('2026-07-01 00:00:00')),

    -- Overflow partition for future data
    PARTITION p_future VALUES LESS THAN MAXVALUE
);

-- Re-add foreign key constraint for sensor_readings
ALTER TABLE sensor_readings
    ADD CONSTRAINT fk_readings_sensor
        FOREIGN KEY (sensor_id) REFERENCES sensors(sensor_id)
        ON DELETE CASCADE ON UPDATE CASCADE;

-- ============================================================================
-- Partition Collection Events Table (Optional - for large deployments)
-- ============================================================================

-- Drop and recreate collection_events with partitioning if needed
DROP TABLE IF EXISTS collection_events;

CREATE TABLE collection_events (
    event_id INT UNSIGNED AUTO_INCREMENT,
    bin_id INT UNSIGNED NOT NULL,
    schedule_id INT UNSIGNED,
    truck_id INT UNSIGNED NOT NULL,
    driver_id INT UNSIGNED NOT NULL,
    collected_at TIMESTAMP NOT NULL,
    fill_level_before DECIMAL(5, 2),
    weight_kg DECIMAL(10, 2),
    collection_duration_seconds INT UNSIGNED,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (event_id, collected_at),
    INDEX idx_bin (bin_id),
    INDEX idx_schedule (schedule_id),
    INDEX idx_truck (truck_id),
    INDEX idx_driver (driver_id),
    INDEX idx_collected_at (collected_at),
    INDEX idx_bin_date (bin_id, collected_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
PARTITION BY RANGE (UNIX_TIMESTAMP(collected_at)) (
    -- Historical partitions
    PARTITION pe2024_q4 VALUES LESS THAN (UNIX_TIMESTAMP('2025-01-01 00:00:00')),

    -- Quarterly partitions for 2025
    PARTITION pe2025_q1 VALUES LESS THAN (UNIX_TIMESTAMP('2025-04-01 00:00:00')),
    PARTITION pe2025_q2 VALUES LESS THAN (UNIX_TIMESTAMP('2025-07-01 00:00:00')),
    PARTITION pe2025_q3 VALUES LESS THAN (UNIX_TIMESTAMP('2025-10-01 00:00:00')),
    PARTITION pe2025_q4 VALUES LESS THAN (UNIX_TIMESTAMP('2026-01-01 00:00:00')),

    -- Future partitions
    PARTITION pe2026_q1 VALUES LESS THAN (UNIX_TIMESTAMP('2026-04-01 00:00:00')),
    PARTITION pe2026_q2 VALUES LESS THAN (UNIX_TIMESTAMP('2026-07-01 00:00:00')),

    -- Overflow partition
    PARTITION pe_future VALUES LESS THAN MAXVALUE
);

-- Re-add foreign key constraints for collection_events
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

-- Re-add check constraints
ALTER TABLE collection_events
    ADD CONSTRAINT chk_event_fill_level CHECK (fill_level_before BETWEEN 0 AND 100),
    ADD CONSTRAINT chk_event_weight CHECK (weight_kg >= 0),
    ADD CONSTRAINT chk_event_duration CHECK (collection_duration_seconds >= 0);

-- ============================================================================
-- Partition Alerts Table (Optional - for large deployments)
-- ============================================================================

DROP TABLE IF EXISTS alerts;

CREATE TABLE alerts (
    alert_id BIGINT UNSIGNED AUTO_INCREMENT,
    bin_id INT UNSIGNED NOT NULL,
    sensor_id INT UNSIGNED,
    threshold_id INT UNSIGNED,
    alert_type ENUM('fill_critical', 'fill_warning', 'temperature_high', 'temperature_low',
                    'odor_high', 'battery_low', 'sensor_offline', 'tilt_detected',
                    'collection_overdue', 'maintenance_required') NOT NULL,
    severity ENUM('info', 'warning', 'critical', 'emergency') NOT NULL,
    triggered_at TIMESTAMP NOT NULL,
    resolved_at TIMESTAMP NULL,
    alert_value DECIMAL(10, 3),
    message TEXT,
    acknowledged BOOLEAN DEFAULT FALSE,
    acknowledged_by VARCHAR(100),
    acknowledged_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (alert_id, triggered_at),
    INDEX idx_bin (bin_id),
    INDEX idx_sensor (sensor_id),
    INDEX idx_triggered_at (triggered_at),
    INDEX idx_severity (severity),
    INDEX idx_resolved (resolved_at),
    INDEX idx_bin_unresolved (bin_id, resolved_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
PARTITION BY RANGE (UNIX_TIMESTAMP(triggered_at)) (
    -- Keep 6 months of alert history
    PARTITION pa2024_q4 VALUES LESS THAN (UNIX_TIMESTAMP('2025-01-01 00:00:00')),
    PARTITION pa2025_01 VALUES LESS THAN (UNIX_TIMESTAMP('2025-02-01 00:00:00')),
    PARTITION pa2025_02 VALUES LESS THAN (UNIX_TIMESTAMP('2025-03-01 00:00:00')),
    PARTITION pa2025_03 VALUES LESS THAN (UNIX_TIMESTAMP('2025-04-01 00:00:00')),
    PARTITION pa2025_04 VALUES LESS THAN (UNIX_TIMESTAMP('2025-05-01 00:00:00')),
    PARTITION pa2025_05 VALUES LESS THAN (UNIX_TIMESTAMP('2025-06-01 00:00:00')),
    PARTITION pa2025_06 VALUES LESS THAN (UNIX_TIMESTAMP('2025-07-01 00:00:00')),
    PARTITION pa_future VALUES LESS THAN MAXVALUE
);

-- Re-add foreign key constraints for alerts
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

-- ============================================================================
-- Partition Management Procedures
-- ============================================================================

DELIMITER //

-- Procedure to add new monthly partition for sensor_readings
CREATE PROCEDURE add_sensor_reading_partition(
    IN partition_date DATE
)
BEGIN
    DECLARE partition_name VARCHAR(20);
    DECLARE next_date DATE;

    SET partition_name = CONCAT('p', DATE_FORMAT(partition_date, '%Y_%m'));
    SET next_date = DATE_ADD(partition_date, INTERVAL 1 MONTH);

    SET @sql = CONCAT(
        'ALTER TABLE sensor_readings ',
        'REORGANIZE PARTITION p_future INTO (',
        'PARTITION ', partition_name, ' VALUES LESS THAN (UNIX_TIMESTAMP(''',
        next_date, ' 00:00:00'')), ',
        'PARTITION p_future VALUES LESS THAN MAXVALUE)'
    );

    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    SELECT CONCAT('Partition ', partition_name, ' created successfully') AS Result;
END//

-- Procedure to drop old partitions (data archival)
CREATE PROCEDURE drop_old_partition(
    IN table_name VARCHAR(64),
    IN partition_to_drop VARCHAR(64)
)
BEGIN
    SET @sql = CONCAT(
        'ALTER TABLE ', table_name, ' ',
        'DROP PARTITION ', partition_to_drop
    );

    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    SELECT CONCAT('Partition ', partition_to_drop, ' dropped from ', table_name) AS Result;
END//

-- Procedure to show partition information
CREATE PROCEDURE show_partition_info(
    IN table_name VARCHAR(64)
)
BEGIN
    SELECT
        partition_name,
        partition_ordinal_position,
        partition_method,
        partition_expression,
        partition_description,
        table_rows,
        avg_row_length,
        data_length / 1024 / 1024 AS data_mb,
        index_length / 1024 / 1024 AS index_mb
    FROM information_schema.partitions
    WHERE table_schema = 'iot_bins'
        AND table_name = table_name
        AND partition_name IS NOT NULL
    ORDER BY partition_ordinal_position;
END//

DELIMITER ;

-- Display partition information
CALL show_partition_info('sensor_readings');

SELECT 'Partitioning implemented successfully' AS Status;