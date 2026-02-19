-- ============================================================================
-- Smart Agriculture IoT Database
-- ============================================================================
-- Precision farming system with crop monitoring, irrigation management,
-- livestock tracking, weather integration, and yield optimization
--
-- Key Features:
-- - Field and zone management with GPS boundaries
-- - Soil sensors (moisture, temperature, pH, nutrients)
-- - Weather station integration
-- - Automated irrigation control
-- - Crop health monitoring and yield prediction
-- - Livestock tracking and health management
-- ============================================================================

-- Drop and recreate database
DROP DATABASE IF EXISTS smart_agriculture;
CREATE DATABASE smart_agriculture
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

USE smart_agriculture;

-- Set timezone for consistent timestamp handling
SET time_zone = '+00:00';

-- Performance optimizations for IoT data
-- SET GLOBAL innodb_buffer_pool_size = 2147483648; -- 2GB
-- SET GLOBAL innodb_log_file_size = 536870912;     -- 512MB
-- SET GLOBAL innodb_flush_log_at_trx_commit = 2;   -- Balance performance/safety

-- Enable event scheduler for automated tasks
-- SET GLOBAL event_scheduler = ON;

-- ============================================================================
-- Database Configuration
-- ============================================================================

-- Create stored procedure for partition management
DELIMITER $$

CREATE PROCEDURE create_daily_partitions(
    IN table_name VARCHAR(64),
    IN days_ahead INT
)
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE partition_date DATE;
    DECLARE partition_name VARCHAR(64);
    DECLARE sql_text TEXT;

    WHILE i < days_ahead DO
        SET partition_date = DATE_ADD(CURDATE(), INTERVAL i DAY);
        SET partition_name = CONCAT('p', DATE_FORMAT(partition_date, '%Y%m%d'));

        SET @sql = CONCAT('ALTER TABLE ', table_name,
            ' ADD PARTITION (PARTITION ', partition_name,
            ' VALUES LESS THAN (TO_DAYS(''',
            DATE_ADD(partition_date, INTERVAL 1 DAY), ''')))');

        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        SET i = i + 1;
    END WHILE;
END$$

-- Stored procedure for calculating growing degree days (GDD)
CREATE FUNCTION calculate_gdd(
    min_temp DECIMAL(5,2),
    max_temp DECIMAL(5,2),
    base_temp DECIMAL(5,2)
)
RETURNS DECIMAL(8,2)
DETERMINISTIC
BEGIN
    DECLARE avg_temp DECIMAL(5,2);
    SET avg_temp = (min_temp + max_temp) / 2;

    IF avg_temp <= base_temp THEN
        RETURN 0;
    ELSE
        RETURN avg_temp - base_temp;
    END IF;
END$$

DELIMITER ;

-- ============================================================================
-- User Roles and Permissions
-- ============================================================================

-- Farm operator (field operations)
CREATE USER IF NOT EXISTS 'farm_operator'@'%' IDENTIFIED BY 'operator_pass_2024';
GRANT SELECT, INSERT, UPDATE ON smart_agriculture.* TO 'farm_operator'@'%';

-- Agronomist (crop and soil management)
CREATE USER IF NOT EXISTS 'agronomist'@'%' IDENTIFIED BY 'agro_pass_2024';
GRANT ALL PRIVILEGES ON smart_agriculture.* TO 'agronomist'@'%';

-- Veterinarian (livestock access)
CREATE USER IF NOT EXISTS 'veterinarian'@'%' IDENTIFIED BY 'vet_pass_2024';
GRANT SELECT, INSERT, UPDATE ON smart_agriculture.* TO 'veterinarian'@'%';
GRANT SELECT, INSERT, UPDATE ON smart_agriculture.* TO 'veterinarian'@'%';

-- Data analyst (read-only analytics)
CREATE USER IF NOT EXISTS 'farm_analyst'@'%' IDENTIFIED BY 'analyst_pass_2024';
GRANT SELECT ON smart_agriculture.* TO 'farm_analyst'@'%';

FLUSH PRIVILEGES;

-- ============================================================================
-- Summary
-- ============================================================================
-- Database created: smart_agriculture
-- Character set: utf8mb4 (full Unicode support)
-- Collation: utf8mb4_unicode_ci
--
-- Users created:
-- - farm_operator: Field operations management
-- - agronomist: Full crop and soil management
-- - veterinarian: Livestock management
-- - farm_analyst: Read-only analytics
--
-- Performance settings optimized for high-frequency sensor data
-- Event scheduler enabled for automated irrigation and monitoring
-- ============================================================================
