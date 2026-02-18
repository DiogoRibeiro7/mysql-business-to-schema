-- PostgreSQL Schema
-- Converted from MySQL on 2026-02-17T23:11:17.362885
-- Generator: MySQL to PostgreSQL Converter

DROP DATABASE IF EXISTS streaming_ml;
-- Create database (run as superuser)
-- CREATE DATABASE streaming_ml;
-- \c streaming_ml

CREATE USER IF NOT EXISTS 'ml_admin'@'localhost' IDENTIFIED BY 'MLAdm1n!2024';
GRANT ALL PRIVILEGES ON streaming_ml.* TO 'ml_admin'@'localhost';
CREATE USER IF NOT EXISTS 'data_scientist'@'localhost' IDENTIFIED BY 'DSc1ent!st2024';
GRANT SELECT, INSERT, UPDATE ON streaming_ml.* TO 'data_scientist'@'localhost';
CREATE USER IF NOT EXISTS 'ml_engineer'@'localhost' IDENTIFIED BY 'MLEng!neer2024';
GRANT SELECT, INSERT, UPDATE, DELETE ON streaming_ml.models TO 'ml_engineer'@'localhost';
GRANT SELECT, INSERT, UPDATE ON streaming_ml.model_deployments TO 'ml_engineer'@'localhost';
GRANT SELECT, INSERT ON streaming_ml.predictions TO 'ml_engineer'@'localhost';
CREATE USER IF NOT EXISTS 'stream_service'@'localhost' IDENTIFIED BY 'Str3am!ng2024';
GRANT SELECT, INSERT ON streaming_ml.data_streams TO 'stream_service'@'localhost';
GRANT SELECT, INSERT ON streaming_ml.stream_events TO 'stream_service'@'localhost';
GRANT SELECT, INSERT ON streaming_ml.raw_features TO 'stream_service'@'localhost';
CREATE USER IF NOT EXISTS 'ml_analyst'@'localhost' IDENTIFIED BY 'An@lyst2024';
GRANT SELECT ON streaming_ml.* TO 'ml_analyst'@'localhost';
FLUSH PRIVILEGES;
DELIMITER $$
CREATE FUNCTION calculate_accuracy(
true_positives INT,
true_negatives INT,
false_positives INT,
false_negatives INT
) RETURNS DECIMAL(5,4)
DETERMINISTIC
BEGIN
DECLARE total INT;
IF total = 0 THEN
RETURN NULL;
END IF;
RETURN (true_positives + true_negatives) / total;
END$$
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
CREATE FUNCTION calculate_auc_roc(
tpr_values JSON,
fpr_values JSON
) RETURNS DECIMAL(5,4)
DETERMINISTIC
BEGIN
DECLARE auc DECIMAL(10,6) DEFAULT 0;
DECLARE i INT DEFAULT 0;
DECLARE n INT;
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
END WHILE;
RETURN auc;
END$$
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
RETURN LEAST(psi, 1.0);
END$$
CREATE FUNCTION hash_feature_schema(
schema_json JSON
) RETURNS VARCHAR(64)
DETERMINISTIC
BEGIN
RETURN SHA2(CAST(schema_json AS CHAR), 256);
END$$
DELIMITER ;
DELIMITER $$
CREATE PROCEDURE manage_partitions()
BEGIN
DECLARE partition_date DATE;
DECLARE partition_name VARCHAR(20);
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
CREATE EVENT IF NOT EXISTS manage_partitions_monthly
ON SCHEDULE EVERY 1 MONTH
STARTS (DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL 1 MONTH), '%Y-%m-01 00:00:00'))
DO CALL manage_partitions();
DELIMITER $$
CREATE PROCEDURE archive_old_models()
BEGIN
UPDATE models
SET status = 'archived'
WHERE status IN ('trained', 'validated')
AND created_at < DATE_SUB(NOW(), INTERVAL 90 DAY)
AND model_id NOT IN (
SELECT model_id FROM model_deployments
WHERE status = 'active'
);
DELETE FROM predictions
WHERE prediction_timestamp < DATE_SUB(NOW(), INTERVAL 30 DAY);
DELETE FROM feature_computations
WHERE computed_at < DATE_SUB(NOW(), INTERVAL 7 DAY);
END$$
DELIMITER ;
CREATE EVENT IF NOT EXISTS archive_models_weekly
ON SCHEDULE EVERY 1 WEEK
STARTS (DATE_ADD(DATE(NOW()), INTERVAL 1 DAY))
DO CALL archive_old_models();
CREATE TABLE IF NOT EXISTS schema_version (
    version VARCHAR(20) NOT NULL,
    description TEXT,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    applied_by VARCHAR(100) DEFAULT USER()
);

INSERT INTO schema_version (version, description)
VALUES ('1.0.0', 'Initial Streaming ML Platform database schema');
CREATE TABLE IF NOT EXISTS system_metrics (
    metric_name VARCHAR(100) NOT NULL,
    metric_value DECIMAL(20,6),
    metric_unit VARCHAR(50),
    component VARCHAR(100),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP(3),
    tags JSONB
);

-- Indexes
