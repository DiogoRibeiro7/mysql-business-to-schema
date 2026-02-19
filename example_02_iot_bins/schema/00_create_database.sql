-- ============================================================================
-- IoT Garbage Bin Monitoring System - Database Creation
-- ============================================================================
-- Description: Creates the iot_bins database for smart city waste management
-- Version: 1.0
-- ============================================================================

-- Drop database if exists (for clean installs)
DROP DATABASE IF EXISTS iot_bins;

-- Create database with UTF8MB4 for full Unicode support
CREATE DATABASE iot_bins
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- Use the database
USE iot_bins;

-- Create user for the application (optional - uncomment if needed)
-- CREATE USER IF NOT EXISTS 'iot_app'@'localhost' IDENTIFIED BY 'secure_password_here';
-- GRANT ALL PRIVILEGES ON iot_bins.* TO 'iot_app'@'localhost';
-- FLUSH PRIVILEGES;

-- Display confirmation
SELECT 'Database iot_bins created successfully' AS Status;
