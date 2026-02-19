-- =========================================
-- Real Estate Platform Database
-- =========================================
-- A comprehensive real estate database supporting:
-- - Property listings and transactions
-- - Spatial/geographic queries
-- - Agent and brokerage management
-- - Market analytics
-- - Virtual tours and media
-- =========================================

DROP DATABASE IF EXISTS real_estate;
CREATE DATABASE real_estate
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE real_estate;

-- Enable spatial extensions
-- SET GLOBAL log_bin_trust_function_creators = 1;

-- Set session parameters
SET sql_mode = 'STRICT_ALL_TABLES,NO_ZERO_DATE,NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO';

SHOW DATABASES LIKE 'real_estate';
SELECT 'Real Estate database created successfully' AS status;
