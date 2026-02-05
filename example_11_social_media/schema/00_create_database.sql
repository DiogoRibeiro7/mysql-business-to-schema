-- =========================================
-- Social Media Platform Database
-- =========================================
-- A comprehensive social networking database supporting:
-- - Social graph relationships
-- - Content creation and distribution
-- - Real-time feed generation
-- - Engagement tracking
-- - Content moderation
-- =========================================

DROP DATABASE IF EXISTS social_media;
CREATE DATABASE social_media
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE social_media;

-- Set session parameters for social media requirements
SET sql_mode = 'STRICT_ALL_TABLES,NO_ZERO_DATE,NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO';

-- Enable full Unicode support for emojis
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

SHOW DATABASES LIKE 'social_media';
SELECT 'Social Media database created successfully' AS status;