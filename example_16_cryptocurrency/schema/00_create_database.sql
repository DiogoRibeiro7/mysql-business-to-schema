-- ============================================================================
-- Cryptocurrency Exchange Database
-- ============================================================================
-- A comprehensive database schema for a cryptocurrency exchange platform
-- supporting spot trading, wallet management, KYC/AML compliance, and
-- high-frequency trading operations.
--
-- Key Features:
-- - Multi-currency wallet management (hot/cold wallets)
-- - Order book and matching engine support
-- - KYC/AML compliance tracking
-- - Trading fee structures
-- - Audit logging for regulatory compliance
-- - API key management
-- - 2FA and security features
-- ============================================================================

-- Drop and recreate database
DROP DATABASE IF EXISTS crypto_exchange;
CREATE DATABASE crypto_exchange
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

USE crypto_exchange;

-- Set timezone to UTC for consistency
SET time_zone = '+00:00';

-- Performance optimizations
SET GLOBAL innodb_buffer_pool_size = 2147483648; -- 2GB
SET GLOBAL innodb_flush_log_at_trx_commit = 2;
SET GLOBAL innodb_file_per_table = ON;
SET GLOBAL innodb_log_file_size = 536870912; -- 512MB

-- Enable event scheduler for automated tasks
SET GLOBAL event_scheduler = ON;