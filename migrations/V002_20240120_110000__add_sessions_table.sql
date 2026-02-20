-- Migration: Add sessions table for user authentication
-- Generated: 2024-01-20T11:00:00

-- ============================================
-- UP MIGRATION
-- ============================================

-- Create sessions table for managing user sessions
CREATE TABLE IF NOT EXISTS sessions (
    id VARCHAR(128) PRIMARY KEY,
    user_id INT NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    payload TEXT,
    last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_last_activity (last_activity),
    INDEX idx_expires_at (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Add last_login column to users table
ALTER TABLE users
    ADD COLUMN last_login TIMESTAMP NULL AFTER is_active,
    ADD COLUMN login_count INT DEFAULT 0 AFTER last_login,
    ADD COLUMN failed_login_attempts INT DEFAULT 0 AFTER login_count,
    ADD COLUMN locked_until TIMESTAMP NULL AFTER failed_login_attempts;

-- Create index for locked accounts
CREATE INDEX idx_locked_until ON users(locked_until);

-- Create stored procedure for cleaning expired sessions
DELIMITER //
CREATE PROCEDURE cleanup_expired_sessions()
BEGIN
    DELETE FROM sessions WHERE expires_at < NOW();
END//
DELIMITER ;

-- Create event to run cleanup daily
CREATE EVENT IF NOT EXISTS cleanup_sessions_event
    ON SCHEDULE EVERY 1 DAY
    STARTS CURRENT_TIMESTAMP
    DO CALL cleanup_expired_sessions();

-- ============================================
-- ==== ROLLBACK ====
-- ============================================

-- Drop event
DROP EVENT IF EXISTS cleanup_sessions_event;

-- Drop stored procedure
DROP PROCEDURE IF EXISTS cleanup_expired_sessions;

-- Drop index
DROP INDEX idx_locked_until ON users;

-- Remove columns from users table
ALTER TABLE users
    DROP COLUMN last_login,
    DROP COLUMN login_count,
    DROP COLUMN failed_login_attempts,
    DROP COLUMN locked_until;

-- Drop sessions table
DROP TABLE IF EXISTS sessions;