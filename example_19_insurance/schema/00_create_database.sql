-- ============================================================================
-- Insurance Management Platform Database
-- ============================================================================
-- A comprehensive database schema for a modern insurance company managing
-- multiple insurance products, claims processing, underwriting, risk assessment,
-- regulatory compliance, and agent/broker networks.
--
-- Key Features:
-- - Multi-product support (life, health, auto, property, liability)
-- - Complete policy lifecycle management
-- - Claims processing with workflow automation
-- - Premium calculation and billing cycles
-- - Agent/broker commission tracking
-- - Underwriting and risk assessment
-- - Reinsurance management
-- - Regulatory compliance and reporting
-- - Document and correspondence management
-- - Actuarial data and analytics support
-- ============================================================================

-- Drop and recreate database
DROP DATABASE IF EXISTS insurance;
CREATE DATABASE insurance
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

USE insurance;

-- Set timezone to UTC for consistency
SET time_zone = '+00:00';

-- Performance optimizations for insurance workloads
-- SET GLOBAL innodb_buffer_pool_size = 4294967296; -- 4GB
-- SET GLOBAL innodb_flush_log_at_trx_commit = 2;
-- SET GLOBAL innodb_file_per_table = ON;
-- SET GLOBAL innodb_log_file_size = 1073741824; -- 1GB

-- Enable event scheduler for automated tasks
-- SET GLOBAL event_scheduler = ON;

-- Optimize for financial calculations
-- SET GLOBAL max_connections = 1000;
-- SET GLOBAL group_concat_max_len = 100000;
