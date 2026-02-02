-- ============================================================================
-- E-commerce Platform - Database Creation
-- ============================================================================
-- Description: Creates the ecommerce database for online retail platform
-- Focus: Product catalog, inventory, orders, customers, payments, analytics
-- Version: 1.0
-- ============================================================================

-- Drop database if exists (for clean installs)
DROP DATABASE IF EXISTS ecommerce;

-- Create database with UTF8MB4 for full Unicode support (including emojis)
CREATE DATABASE ecommerce
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- Use the database
USE ecommerce;

-- Set timezone for consistent timestamp handling
SET time_zone = '+00:00';

-- Enable event scheduler for automated tasks
SET GLOBAL event_scheduler = ON;

-- Create user for the application (optional - uncomment if needed)
-- CREATE USER IF NOT EXISTS 'shop_app'@'localhost' IDENTIFIED BY 'secure_password_here';
-- GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON ecommerce.* TO 'shop_app'@'localhost';
-- CREATE USER IF NOT EXISTS 'shop_analytics'@'localhost' IDENTIFIED BY 'secure_password_here';
-- GRANT SELECT ON ecommerce.* TO 'shop_analytics'@'localhost';
-- FLUSH PRIVILEGES;

-- Display confirmation
SELECT 'Database ecommerce created successfully' AS Status;
SELECT 'Focus: Full-featured e-commerce platform with marketplace capabilities' AS Description;