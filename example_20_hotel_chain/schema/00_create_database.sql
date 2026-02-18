-- ============================================================================
-- Hotel Chain Management Database
-- ============================================================================
-- A comprehensive database schema for a modern hotel chain managing multiple
-- properties, reservations, guest services, loyalty programs, event management,
-- staff operations, and revenue optimization.
--
-- Key Features:
-- - Multi-property chain management
-- - Complete reservation and booking lifecycle
-- - Room inventory and dynamic pricing
-- - Guest profiles and loyalty programs
-- - Housekeeping and maintenance management
-- - Restaurant, spa, and amenity services
-- - Event and conference facilities
-- - Staff scheduling and payroll
-- - Revenue management and analytics
-- - Channel management (OTA integration)
-- ============================================================================

-- Drop and recreate database
DROP DATABASE IF EXISTS hotel_chain;
CREATE DATABASE hotel_chain
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

USE hotel_chain;

-- Set timezone to UTC for consistency across properties
SET time_zone = '+00:00';

-- Performance optimizations for hospitality workloads
SET GLOBAL innodb_buffer_pool_size = 4294967296; -- 4GB
SET GLOBAL innodb_flush_log_at_trx_commit = 2;
SET GLOBAL innodb_file_per_table = ON;
SET GLOBAL innodb_log_file_size = 1073741824; -- 1GB

-- Enable event scheduler for automated tasks
SET GLOBAL event_scheduler = ON;

-- Optimize for high-concurrency reservation systems
SET GLOBAL max_connections = 2000;
SET GLOBAL thread_cache_size = 100;