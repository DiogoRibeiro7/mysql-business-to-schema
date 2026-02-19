-- =========================================
-- FinTech Platform Database
-- =========================================
-- A comprehensive financial services database supporting:
-- - Double-entry accounting
-- - Multi-currency transactions
-- - Fraud detection
-- - Regulatory compliance
-- - Payment processing
-- =========================================

DROP DATABASE IF EXISTS fintech;
CREATE DATABASE fintech
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE fintech;

-- Set session parameters for financial precision
SET sql_mode = 'STRICT_ALL_TABLES,NO_ZERO_DATE,NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO';

SHOW DATABASES LIKE 'fintech';
SELECT 'FinTech database created successfully' AS status;
