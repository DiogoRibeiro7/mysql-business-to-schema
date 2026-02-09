-- =========================================
-- Event Ticketing Platform Database
-- =========================================
-- A comprehensive ticketing system supporting:
-- - Venue and seat management
-- - Real-time booking and inventory
-- - Dynamic pricing
-- - Queue management
-- - Revenue optimization
-- =========================================

DROP DATABASE IF EXISTS event_ticketing;
CREATE DATABASE event_ticketing
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE event_ticketing;

-- Set session parameters for transactional integrity
SET sql_mode = 'STRICT_ALL_TABLES,NO_ZERO_DATE,NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO';
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

SHOW DATABASES LIKE 'event_ticketing';
SELECT 'Event Ticketing database created successfully' AS status;