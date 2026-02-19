-- ============================================================================
-- Gaming Platform Database
-- ============================================================================
-- A comprehensive database schema for a modern gaming platform supporting
-- multiple games, multiplayer features, in-game economies, social features,
-- tournaments, and advanced analytics.
--
-- Key Features:
-- - Multi-game platform with cross-game features
-- - Real-time multiplayer matchmaking
-- - Virtual economy with multiple currencies
-- - Achievement and progression systems
-- - Social features (friends, clans, messaging)
-- - Tournament and competitive play
-- - Anti-cheat and player behavior tracking
-- - Comprehensive analytics and telemetry
-- ============================================================================

-- Drop and recreate database
DROP DATABASE IF EXISTS gaming_platform;
CREATE DATABASE gaming_platform
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

USE gaming_platform;

-- Set timezone to UTC for consistency
SET time_zone = '+00:00';

-- Performance optimizations for gaming workloads
-- SET GLOBAL innodb_buffer_pool_size = 4294967296; -- 4GB
-- SET GLOBAL innodb_flush_log_at_trx_commit = 2;
-- SET GLOBAL innodb_file_per_table = ON;
-- SET GLOBAL innodb_log_file_size = 1073741824; -- 1GB
-- SET GLOBAL innodb_write_io_threads = 8;
-- SET GLOBAL innodb_read_io_threads = 8;

-- Enable event scheduler for automated tasks
-- SET GLOBAL event_scheduler = ON;

-- Optimize for high-concurrency gaming scenarios
-- SET GLOBAL max_connections = 2000;
-- SET GLOBAL thread_cache_size = 100;
