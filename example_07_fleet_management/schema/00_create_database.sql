-- ============================================================================
-- Fleet Management System Database
-- ============================================================================
-- Commercial fleet tracking with GPS monitoring, driver behavior analysis,
-- vehicle diagnostics, compliance tracking (HOS/ELD), and route optimization
--
-- Key Features:
-- - Real-time GPS tracking with geofencing
-- - Driver behavior scoring (harsh events, speeding)
-- - Vehicle diagnostics (OBD-II parameters)
-- - HOS (Hours of Service) and ELD compliance
-- - DVIR (Driver Vehicle Inspection Reports)
-- - Fuel efficiency and route optimization
-- ============================================================================

-- Drop and recreate database
DROP DATABASE IF EXISTS fleet_management;
CREATE DATABASE fleet_management
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

USE fleet_management;

-- Set timezone for consistent timestamp handling
SET time_zone = '+00:00';

-- Performance optimizations for high-frequency GPS data
SET GLOBAL innodb_buffer_pool_size = 3221225472; -- 3GB for GPS data
SET GLOBAL innodb_log_file_size = 536870912;     -- 512MB
SET GLOBAL innodb_flush_log_at_trx_commit = 2;   -- Balance performance/safety
SET GLOBAL innodb_file_per_table = ON;           -- Separate files for large tables

-- Enable event scheduler for automated compliance checks
SET GLOBAL event_scheduler = ON;

-- ============================================================================
-- Stored Procedures and Functions
-- ============================================================================

DELIMITER $$

-- Function to calculate distance between two GPS points (Haversine formula)
CREATE FUNCTION calculate_distance(
    lat1 DECIMAL(10,6),
    lon1 DECIMAL(10,6),
    lat2 DECIMAL(10,6),
    lon2 DECIMAL(10,6)
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE R DECIMAL(10,2) DEFAULT 6371; -- Earth radius in km
    DECLARE dLat DECIMAL(10,6);
    DECLARE dLon DECIMAL(10,6);
    DECLARE a DECIMAL(10,6);
    DECLARE c DECIMAL(10,6);

    SET dLat = RADIANS(lat2 - lat1);
    SET dLon = RADIANS(lon2 - lon1);

    SET a = SIN(dLat/2) * SIN(dLat/2) +
            COS(RADIANS(lat1)) * COS(RADIANS(lat2)) *
            SIN(dLon/2) * SIN(dLon/2);

    SET c = 2 * ATAN2(SQRT(a), SQRT(1-a));

    RETURN R * c; -- Distance in km
END$$

-- Procedure for partition management (daily partitions for GPS data)
CREATE PROCEDURE create_gps_partitions(
    IN days_ahead INT
)
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE partition_date DATE;
    DECLARE partition_name VARCHAR(64);

    WHILE i < days_ahead DO
        SET partition_date = DATE_ADD(CURDATE(), INTERVAL i DAY);
        SET partition_name = CONCAT('p', DATE_FORMAT(partition_date, '%Y%m%d'));

        SET @sql = CONCAT('ALTER TABLE gps_positions ADD PARTITION (PARTITION ',
            partition_name, ' VALUES LESS THAN (TO_DAYS(''',
            DATE_ADD(partition_date, INTERVAL 1 DAY), ''')))');

        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        SET i = i + 1;
    END WHILE;
END$$

DELIMITER ;

-- ============================================================================
-- User Roles and Permissions
-- ============================================================================

-- Fleet manager (full access)
CREATE USER IF NOT EXISTS 'fleet_manager'@'%' IDENTIFIED BY 'fleet_pass_2024';
GRANT ALL PRIVILEGES ON fleet_management.* TO 'fleet_manager'@'%';

-- Dispatcher (operational access)
CREATE USER IF NOT EXISTS 'dispatcher'@'%' IDENTIFIED BY 'dispatch_pass_2024';
GRANT SELECT, INSERT, UPDATE ON fleet_management.* TO 'dispatcher'@'%';

-- Driver (limited access to own data)
CREATE USER IF NOT EXISTS 'driver_app'@'%' IDENTIFIED BY 'driver_pass_2024';
GRANT SELECT ON fleet_management.* TO 'driver_app'@'%';
GRANT INSERT ON fleet_management.gps_positions TO 'driver_app'@'%';
GRANT INSERT ON fleet_management.driver_logs TO 'driver_app'@'%';

-- Compliance officer (read-only for audits)
CREATE USER IF NOT EXISTS 'compliance'@'%' IDENTIFIED BY 'compliance_pass_2024';
GRANT SELECT ON fleet_management.* TO 'compliance'@'%';

-- Analytics user (read-only for reporting)
CREATE USER IF NOT EXISTS 'analyst'@'%' IDENTIFIED BY 'analyst_pass_2024';
GRANT SELECT ON fleet_management.* TO 'analyst'@'%';

FLUSH PRIVILEGES;

-- ============================================================================
-- Summary
-- ============================================================================
-- Database created: fleet_management
-- Character set: utf8mb4 (full Unicode support)
-- Collation: utf8mb4_unicode_ci
--
-- Users created:
-- - fleet_manager: Full fleet management access
-- - dispatcher: Operational management
-- - driver_app: Driver mobile app access
-- - compliance: Compliance and audit access
-- - analyst: Read-only analytics access
--
-- Performance settings optimized for high-frequency GPS tracking
-- Event scheduler enabled for compliance automation
-- Custom functions for distance calculations
-- ============================================================================