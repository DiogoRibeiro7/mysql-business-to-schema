-- ============================================================================
-- Streaming ML Platform Database Creation
-- ============================================================================

-- Drop and recreate database
DROP DATABASE IF EXISTS streaming_ml;
CREATE DATABASE streaming_ml
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE streaming_ml;

-- ============================================================================
-- User Roles and Permissions
-- ============================================================================

-- ML Platform administrator role
CREATE USER IF NOT EXISTS 'ml_admin'@'localhost' IDENTIFIED BY 'MLAdm1n!2024';
GRANT ALL PRIVILEGES ON streaming_ml.* TO 'ml_admin'@'localhost';

-- Data scientist role (model development)
CREATE USER IF NOT EXISTS 'data_scientist'@'localhost' IDENTIFIED BY 'DSc1ent!st2024';
GRANT SELECT, INSERT, UPDATE ON streaming_ml.* TO 'data_scientist'@'localhost';

-- ML engineer role (deployment and operations)
CREATE USER IF NOT EXISTS 'ml_engineer'@'localhost' IDENTIFIED BY 'MLEng!neer2024';
GRANT SELECT, INSERT, UPDATE, DELETE ON streaming_ml.models TO 'ml_engineer'@'localhost';
GRANT SELECT, INSERT, UPDATE ON streaming_ml.model_deployments TO 'ml_engineer'@'localhost';
GRANT SELECT, INSERT ON streaming_ml.predictions TO 'ml_engineer'@'localhost';

-- Streaming service role (data ingestion)
CREATE USER IF NOT EXISTS 'stream_service'@'localhost' IDENTIFIED BY 'Str3am!ng2024';
GRANT SELECT, INSERT ON streaming_ml.data_streams TO 'stream_service'@'localhost';
GRANT SELECT, INSERT ON streaming_ml.stream_events TO 'stream_service'@'localhost';
GRANT SELECT, INSERT ON streaming_ml.raw_features TO 'stream_service'@'localhost';

-- Analytics role (read-only for reporting)
CREATE USER IF NOT EXISTS 'ml_analyst'@'localhost' IDENTIFIED BY 'An@lyst2024';
GRANT SELECT ON streaming_ml.* TO 'ml_analyst'@'localhost';

FLUSH PRIVILEGES;

-- ============================================================================
-- Stored Functions
-- ============================================================================

DELIMITER $$

-- Calculate model accuracy
CREATE FUNCTION calculate_accuracy(
    true_positives INT,
    true_negatives INT,
    false_positives INT,
    false_negatives INT
) RETURNS DECIMAL(5,4)
DETERMINISTIC
BEGIN
    DECLARE total INT;
    SET total = true_positives + true_negatives + false_positives + false_negatives;

    IF total = 0 THEN
        RETURN NULL;
    END IF;

    RETURN (true_positives + true_negatives) / total;
END$$

-- Calculate F1 score
CREATE FUNCTION calculate_f1_score(
    true_positives INT,
    false_positives INT,
    false_negatives INT
) RETURNS DECIMAL(5,4)
DETERMINISTIC
BEGIN
    DECLARE precision_val DECIMAL(5,4);
    DECLARE recall_val DECIMAL(5,4);

    IF (true_positives + false_positives) = 0 THEN
        SET precision_val = 0;
    ELSE
        SET precision_val = true_positives / (true_positives + false_positives);
    END IF;

    IF (true_positives + false_negatives) = 0 THEN
        SET recall_val = 0;
    ELSE
        SET recall_val = true_positives / (true_positives + false_negatives);
    END IF;

    IF (precision_val + recall_val) = 0 THEN
        RETURN 0;
    END IF;

    RETURN 2 * (precision_val * recall_val) / (precision_val + recall_val);
END$$

-- Calculate AUC-ROC approximation (using trapezoidal rule)
CREATE FUNCTION calculate_auc_roc(
    tpr_values JSON,
    fpr_values JSON
) RETURNS DECIMAL(5,4)
DETERMINISTIC
BEGIN
    DECLARE auc DECIMAL(10,6) DEFAULT 0;
    DECLARE i INT DEFAULT 0;
    DECLARE n INT;

    SET n = JSON_LENGTH(tpr_values);

    IF n IS NULL OR n < 2 THEN
        RETURN NULL;
    END IF;

    WHILE i < n - 1 DO
        SET auc = auc + (
            (JSON_EXTRACT(fpr_values, CONCAT('$[', i + 1, ']')) -
             JSON_EXTRACT(fpr_values, CONCAT('$[', i, ']'))) *
            (JSON_EXTRACT(tpr_values, CONCAT('$[', i + 1, ']')) +
             JSON_EXTRACT(tpr_values, CONCAT('$[', i, ']'))) / 2
        );
        SET i = i + 1;
    END WHILE;

    RETURN auc;
END$$

-- Calculate drift score
CREATE FUNCTION calculate_drift_score(
    baseline_mean DECIMAL(10,4),
    baseline_std DECIMAL(10,4),
    current_mean DECIMAL(10,4),
    current_std DECIMAL(10,4)
) RETURNS DECIMAL(5,4)
DETERMINISTIC
BEGIN
    DECLARE psi DECIMAL(10,6);

    IF baseline_std = 0 OR current_std = 0 THEN
        RETURN NULL;
    END IF;

    -- Population Stability Index (PSI) approximation
    SET psi = ABS(current_mean - baseline_mean) / baseline_std +
              0.5 * ABS(LOG(current_std / baseline_std));

    RETURN LEAST(psi, 1.0);
END$$

-- Hash function for feature versioning
CREATE FUNCTION hash_feature_schema(
    schema_json JSON
) RETURNS VARCHAR(64)
DETERMINISTIC
BEGIN
    RETURN SHA2(CAST(schema_json AS CHAR), 256);
END$$

DELIMITER ;

-- ============================================================================
-- Event Scheduler Configuration
-- ============================================================================

-- Enable event scheduler
SET GLOBAL event_scheduler = ON;

-- ============================================================================
-- Partition Management
-- ============================================================================

-- Create procedure to manage time-series partitions
DELIMITER $$

CREATE PROCEDURE manage_partitions()
BEGIN
    DECLARE partition_date DATE;
    DECLARE partition_name VARCHAR(20);

    -- Add new partition for next month (stream_events)
    SET partition_date = DATE_ADD(CURDATE(), INTERVAL 1 MONTH);
    SET partition_name = CONCAT('p', DATE_FORMAT(partition_date, '%Y%m'));

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.partitions
        WHERE table_schema = 'streaming_ml'
        AND table_name = 'stream_events'
        AND partition_name = partition_name
    ) THEN
        SET @sql = CONCAT('ALTER TABLE stream_events ADD PARTITION (PARTITION ',
                         partition_name, ' VALUES LESS THAN (TO_DAYS(''',
                         DATE_ADD(partition_date, INTERVAL 1 MONTH), ''')))');
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;

    -- Remove old partitions (keep 6 months)
    SET partition_date = DATE_SUB(CURDATE(), INTERVAL 6 MONTH);
    SET partition_name = CONCAT('p', DATE_FORMAT(partition_date, '%Y%m'));

    IF EXISTS (
        SELECT 1 FROM information_schema.partitions
        WHERE table_schema = 'streaming_ml'
        AND table_name = 'stream_events'
        AND partition_name = partition_name
    ) THEN
        SET @sql = CONCAT('ALTER TABLE stream_events DROP PARTITION ', partition_name);
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
END$$

DELIMITER ;

-- Schedule partition management
CREATE EVENT IF NOT EXISTS manage_partitions_monthly
ON SCHEDULE EVERY 1 MONTH
STARTS (DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL 1 MONTH), '%Y-%m-01 00:00:00'))
DO CALL manage_partitions();

-- ============================================================================
-- Model Registry Cleanup
-- ============================================================================

-- Create procedure to archive old model versions
DELIMITER $$

CREATE PROCEDURE archive_old_models()
BEGIN
    -- Archive models older than 90 days that are not deployed
    UPDATE models
    SET status = 'archived'
    WHERE status IN ('trained', 'validated')
      AND created_at < DATE_SUB(NOW(), INTERVAL 90 DAY)
      AND model_id NOT IN (
          SELECT model_id FROM model_deployments
          WHERE status = 'active'
      );

    -- Clean up old prediction logs (keep 30 days)
    DELETE FROM predictions
    WHERE prediction_timestamp < DATE_SUB(NOW(), INTERVAL 30 DAY);

    -- Clean up old feature computations (keep 7 days)
    DELETE FROM feature_computations
    WHERE computed_at < DATE_SUB(NOW(), INTERVAL 7 DAY);
END$$

DELIMITER ;

-- Schedule model cleanup
CREATE EVENT IF NOT EXISTS archive_models_weekly
ON SCHEDULE EVERY 1 WEEK
STARTS (DATE_ADD(DATE(NOW()), INTERVAL 1 DAY))
DO CALL archive_old_models();

-- ============================================================================
-- Database Configuration
-- ============================================================================

-- Set session variables for optimal performance
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
SET SESSION foreign_key_checks = 1;
SET SESSION unique_checks = 1;

-- Create schema version table
CREATE TABLE schema_version (
    version_id INT AUTO_INCREMENT PRIMARY KEY,
    version VARCHAR(20) NOT NULL,
    description TEXT,
    applied_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    applied_by VARCHAR(100) DEFAULT USER()
) ENGINE=InnoDB;

-- Insert initial version
INSERT INTO schema_version (version, description)
VALUES ('1.0.0', 'Initial Streaming ML Platform database schema');

-- ============================================================================
-- Performance Configuration
-- ============================================================================

-- Configure for high-throughput streaming workloads
SET GLOBAL max_connections = 500;
SET GLOBAL innodb_buffer_pool_size = 2147483648; -- 2GB
SET GLOBAL innodb_log_file_size = 536870912; -- 512MB
SET GLOBAL innodb_flush_log_at_trx_commit = 2; -- Better performance, slight durability trade-off
SET GLOBAL innodb_flush_method = O_DIRECT;

-- ============================================================================
-- Monitoring Tables
-- ============================================================================

-- System metrics table for platform monitoring
CREATE TABLE system_metrics (
    metric_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    metric_name VARCHAR(100) NOT NULL,
    metric_value DECIMAL(20,6),
    metric_unit VARCHAR(50),
    component VARCHAR(100),
    timestamp DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3),
    tags JSON,
    INDEX idx_metrics_lookup (metric_name, timestamp DESC),
    INDEX idx_metrics_component (component, timestamp DESC)
) ENGINE=InnoDB;