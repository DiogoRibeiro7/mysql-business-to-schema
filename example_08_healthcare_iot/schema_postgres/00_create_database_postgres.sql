-- PostgreSQL Schema
-- Converted from MySQL on 2026-02-17T23:11:17.357028
-- Generator: MySQL to PostgreSQL Converter

-- Enum Types
CREATE TYPE audit_log_status AS ENUM ('INSERT', 'UPDATE', 'DELETE');

DROP DATABASE IF EXISTS healthcare_iot;
-- Create database (run as superuser)
-- CREATE DATABASE healthcare_iot;
-- \c healthcare_iot

CREATE USER IF NOT EXISTS 'health_admin'@'localhost' IDENTIFIED BY 'HealthAdm1n!2024';
GRANT ALL PRIVILEGES ON healthcare_iot.* TO 'health_admin'@'localhost';
CREATE USER IF NOT EXISTS 'medical_staff'@'localhost' IDENTIFIED BY 'MedSt@ff2024';
GRANT SELECT, INSERT, UPDATE ON healthcare_iot.* TO 'medical_staff'@'localhost';
CREATE USER IF NOT EXISTS 'monitoring_system'@'localhost' IDENTIFIED BY 'Mon1t0r$ys2024';
GRANT SELECT, INSERT ON healthcare_iot.vital_signs TO 'monitoring_system'@'localhost';
GRANT SELECT, INSERT ON healthcare_iot.device_readings TO 'monitoring_system'@'localhost';
GRANT SELECT, INSERT ON healthcare_iot.alerts TO 'monitoring_system'@'localhost';
CREATE USER IF NOT EXISTS 'health_analyst'@'localhost' IDENTIFIED BY 'An@lyst2024';
GRANT SELECT ON healthcare_iot.* TO 'health_analyst'@'localhost';
CREATE USER IF NOT EXISTS 'patient_portal'@'localhost' IDENTIFIED BY 'P@tient2024';
GRANT SELECT ON healthcare_iot.patients TO 'patient_portal'@'localhost';
GRANT SELECT ON healthcare_iot.vital_signs TO 'patient_portal'@'localhost';
GRANT SELECT ON healthcare_iot.medications TO 'patient_portal'@'localhost';
FLUSH PRIVILEGES;
DELIMITER $$
CREATE FUNCTION calculate_early_warning_score(
resp_rate INT,
oxygen_saturation DECIMAL(5,2),
systolic_bp INT,
pulse_rate INT,
consciousness_level VARCHAR(10),
temperature DECIMAL(4,1)
) RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
DECLARE score INT DEFAULT 0;
IF resp_rate <= 8 OR resp_rate >= 25 THEN
SET score = score + 3;
ELSEIF resp_rate BETWEEN 9 AND 11 THEN
SET score = score + 1;
ELSEIF resp_rate BETWEEN 21 AND 24 THEN
SET score = score + 2;
END IF;
IF oxygen_saturation <= 91 THEN
SET score = score + 3;
ELSEIF oxygen_saturation BETWEEN 92 AND 93 THEN
SET score = score + 2;
ELSEIF oxygen_saturation BETWEEN 94 AND 95 THEN
SET score = score + 1;
END IF;
IF systolic_bp <= 90 OR systolic_bp >= 220 THEN
SET score = score + 3;
ELSEIF systolic_bp BETWEEN 91 AND 100 THEN
SET score = score + 2;
ELSEIF systolic_bp BETWEEN 101 AND 110 THEN
SET score = score + 1;
END IF;
IF pulse_rate <= 40 OR pulse_rate >= 131 THEN
SET score = score + 3;
ELSEIF pulse_rate BETWEEN 41 AND 50 OR pulse_rate BETWEEN 91 AND 110 THEN
SET score = score + 1;
ELSEIF pulse_rate BETWEEN 111 AND 130 THEN
SET score = score + 2;
END IF;
IF consciousness_level != 'Alert' THEN
SET score = score + 3;
END IF;
IF temperature <= 35.0 THEN
SET score = score + 3;
ELSEIF temperature BETWEEN 35.1 AND 36.0 OR temperature >= 39.1 THEN
SET score = score + 2;
ELSEIF temperature BETWEEN 38.1 AND 39.0 THEN
SET score = score + 1;
END IF;
RETURN score;
END$$
CREATE FUNCTION calculate_bmi(
height_cm DECIMAL(5,2),
weight_kg DECIMAL(5,2)
) RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN
IF height_cm IS NULL OR weight_kg IS NULL OR height_cm = 0 THEN
RETURN NULL;
END IF;
RETURN weight_kg / POWER(height_cm / 100, 2);
END$$
CREATE FUNCTION calculate_adherence_rate(
patient_id INT,
days_back INT
) RETURNS DECIMAL(5,2)
READS SQL DATA
BEGIN
DECLARE total_doses INT;
DECLARE taken_doses INT;
DECLARE adherence_rate DECIMAL(5,2);
SELECT
COUNT(*) AS total,
SUM(CASE WHEN taken = TRUE THEN 1 ELSE 0 END) AS taken
INTO total_doses, taken_doses
FROM medication_administration
WHERE patient_id = patient_id
AND scheduled_time >= DATE_SUB(CURDATE(), INTERVAL days_back DAY)
AND scheduled_time <= NOW();
IF total_doses = 0 THEN
RETURN NULL;
END IF;
RETURN adherence_rate;
END$$
CREATE FUNCTION anonymize_patient_id(
patient_id INT,
salt VARCHAR(32)
) RETURNS VARCHAR(64)
DETERMINISTIC
BEGIN
RETURN SHA2(CONCAT(patient_id, salt), 256);
END$$
DELIMITER ;
DELIMITER $$
CREATE PROCEDURE manage_partitions()
BEGIN
DECLARE partition_date DATE;
DECLARE partition_name VARCHAR(20);
IF NOT EXISTS (
SELECT 1 FROM information_schema.partitions
WHERE table_schema = 'healthcare_iot'
AND table_name = 'vital_signs'
AND partition_name = partition_name
) THEN
SET @sql = CONCAT('ALTER TABLE vital_signs ADD PARTITION (PARTITION ',
partition_name, ' VALUES LESS THAN (TO_DAYS(''',
DATE_ADD(partition_date, INTERVAL 1 MONTH), ''')))');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
END IF;
IF EXISTS (
SELECT 1 FROM information_schema.partitions
WHERE table_schema = 'healthcare_iot'
AND table_name = 'vital_signs'
AND partition_name = partition_name
) THEN
SET @sql = CONCAT('ALTER TABLE vital_signs DROP PARTITION ', partition_name);
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
CREATE TABLE IF NOT EXISTS audit_log (
    table_name VARCHAR(64) NOT NULL,
    operation audit_log_status NOT NULL,
    user VARCHAR(100),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    record_id INTEGER,
    old_values JSONB,
    new_values JSONB
);

CREATE TABLE IF NOT EXISTS schema_version (
    version VARCHAR(20) NOT NULL,
    description TEXT,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    applied_by VARCHAR(100) DEFAULT USER()
);

INSERT INTO schema_version (version, description)
VALUES ('1.0.0', 'Initial Healthcare IoT database schema');
-- Indexes
