-- ============================================================================
-- Food Delivery Platform Database
-- ============================================================================
-- A comprehensive database schema for a food delivery platform supporting
-- restaurant management, order processing, real-time delivery tracking,
-- customer satisfaction, and multi-modal delivery options.
--
-- Key Features:
-- - Multi-restaurant marketplace
-- - Dynamic pricing and surge pricing
-- - Real-time GPS tracking
-- - Multiple delivery methods (drivers, drones, robots)
-- - Loyalty programs and promotions
-- - Rating and review system
-- - Zone-based delivery management
-- ============================================================================

-- Drop and recreate database
DROP DATABASE IF EXISTS food_delivery;
CREATE DATABASE food_delivery
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

USE food_delivery;

-- Set timezone to UTC for consistency
SET time_zone = '+00:00';

-- Performance optimizations
-- SET GLOBAL innodb_buffer_pool_size = 2147483648; -- 2GB
-- SET GLOBAL innodb_flush_log_at_trx_commit = 2;
-- SET GLOBAL innodb_file_per_table = ON;
-- SET GLOBAL innodb_log_file_size = 536870912; -- 512MB

-- Enable event scheduler for automated tasks
-- SET GLOBAL event_scheduler = ON;
