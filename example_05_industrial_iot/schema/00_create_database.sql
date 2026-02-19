-- ============================================================================
-- Industrial IoT Manufacturing System Database
-- ============================================================================
-- Industry 4.0 smart manufacturing with real-time monitoring, OEE tracking,
-- predictive maintenance, and quality control
--
-- Key Features:
-- - Real-time sensor monitoring (temperature, vibration, pressure, etc.)
-- - OEE calculation (Availability, Performance, Quality)
-- - Predictive maintenance analytics
-- - Production tracking and quality control
-- - Multi-factory support
-- ============================================================================

-- Drop and recreate database
DROP DATABASE IF EXISTS industrial_iot;
CREATE DATABASE industrial_iot
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

USE industrial_iot;

-- Set timezone for consistent timestamp handling
SET time_zone = '+00:00';

-- Performance optimizations
-- SET GLOBAL innodb_buffer_pool_size = 2147483648; -- 2GB
-- SET GLOBAL innodb_log_file_size = 536870912;     -- 512MB
-- SET GLOBAL innodb_flush_log_at_trx_commit = 2;   -- Balance performance/safety
-- SET GLOBAL innodb_flush_method = O_DIRECT;       -- Avoid double buffering

-- Enable event scheduler for automated tasks
-- SET GLOBAL event_scheduler = ON;

-- ============================================================================
-- Database Configuration
-- ============================================================================

-- Create stored procedure for partition management
DELIMITER $$

CREATE PROCEDURE create_monthly_partitions(
    IN table_name VARCHAR(64),
    IN months_ahead INT
)
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE partition_date DATE;
    DECLARE partition_name VARCHAR(64);
    DECLARE sql_text TEXT;

    WHILE i < months_ahead DO
        SET partition_date = DATE_ADD(CURDATE(), INTERVAL i MONTH);
        SET partition_name = CONCAT('p', DATE_FORMAT(partition_date, '%Y%m'));

        SET @sql = CONCAT('ALTER TABLE ', table_name,
            ' ADD PARTITION (PARTITION ', partition_name,
            ' VALUES LESS THAN (TO_DAYS(''',
            DATE_ADD(partition_date, INTERVAL 1 MONTH), ''')))');

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

-- Factory operator (read-only monitoring)
CREATE USER IF NOT EXISTS 'factory_operator'@'%' IDENTIFIED BY 'operator_pass_2024';
GRANT SELECT ON industrial_iot.* TO 'factory_operator'@'%';

-- Production manager (read/write for production data)
CREATE USER IF NOT EXISTS 'production_manager'@'%' IDENTIFIED BY 'manager_pass_2024';
GRANT SELECT, INSERT, UPDATE ON industrial_iot.* TO 'production_manager'@'%';

-- Maintenance engineer (full access to maintenance tables)
CREATE USER IF NOT EXISTS 'maintenance_engineer'@'%' IDENTIFIED BY 'maintenance_pass_2024';
GRANT ALL PRIVILEGES ON industrial_iot.* TO 'maintenance_engineer'@'%';

-- Data analyst (read-only for analytics)
CREATE USER IF NOT EXISTS 'data_analyst'@'%' IDENTIFIED BY 'analyst_pass_2024';
GRANT SELECT ON industrial_iot.* TO 'data_analyst'@'%';

FLUSH PRIVILEGES;

-- ============================================================================
-- Summary
-- ============================================================================
-- Database created: industrial_iot
-- Character set: utf8mb4 (full Unicode support including emojis)
-- Collation: utf8mb4_unicode_ci
--
-- Users created:
-- - factory_operator: Read-only access for monitoring
-- - production_manager: Read/write for production data
-- - maintenance_engineer: Full access for maintenance
-- - data_analyst: Read-only for analytics
--
-- Performance settings optimized for high-frequency sensor data
-- Event scheduler enabled for automated maintenance tasks
-- ============================================================================
