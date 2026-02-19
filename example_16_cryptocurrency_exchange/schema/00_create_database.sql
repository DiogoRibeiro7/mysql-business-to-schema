-- =====================================================
-- Cryptocurrency Exchange Database Creation
-- =====================================================
-- A comprehensive database for a modern cryptocurrency exchange platform
-- supporting spot trading, staking, DeFi features, and regulatory compliance
--
-- Features:
-- - Multi-currency support (crypto and fiat)
-- - Order book and matching engine data
-- - KYC/AML compliance
-- - Wallet management
-- - Staking and yield farming
-- - API key management
-- - Audit logging and security
-- =====================================================

-- Drop database if exists (for development only)
DROP DATABASE IF EXISTS cryptocurrency_exchange;

-- Create database with UTF-8 support for international users
CREATE DATABASE cryptocurrency_exchange
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

-- Use the database
USE cryptocurrency_exchange;

-- Set timezone to UTC for consistency
SET time_zone = '+00:00';

-- Display creation confirmation
SELECT 'Database cryptocurrency_exchange created successfully' AS status;
