-- ============================================================================
-- Smart Energy Monitoring System - Database Creation
-- ============================================================================
-- Description: Creates the smart_energy database for building energy management
-- Focus: Real-time power monitoring, demand response, renewable integration
-- Version: 1.0
-- ============================================================================

-- Drop database if exists (for clean installs)
DROP DATABASE IF EXISTS smart_energy;

-- Create database with UTF8MB4 for full Unicode support
CREATE DATABASE smart_energy
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- Use the database
USE smart_energy;

-- Set timezone for consistent timestamp handling
SET time_zone = '+00:00';

-- Create user for the application (optional - uncomment if needed)
-- CREATE USER IF NOT EXISTS 'energy_app'@'localhost' IDENTIFIED BY 'secure_password_here';
-- GRANT ALL PRIVILEGES ON smart_energy.* TO 'energy_app'@'localhost';
-- FLUSH PRIVILEGES;

-- Display confirmation
SELECT 'Database smart_energy created successfully' AS Status;
SELECT 'Focus: Commercial building energy management with IoT sensors' AS Description;
