-- PostgreSQL Schema
-- Converted from MySQL on 2026-02-17T23:11:17.345671
-- Generator: MySQL to PostgreSQL Converter

DROP DATABASE IF EXISTS smart_agriculture;
-- Create database (run as superuser)
-- CREATE DATABASE smart_agriculture;
-- \c smart_agriculture

DELIMITER $$
CREATE PROCEDURE create_daily_partitions(
IN table_name VARCHAR(64),
IN days_ahead INT
)
BEGIN
DECLARE i INT DEFAULT 0;
DECLARE partition_date DATE;
DECLARE partition_name VARCHAR(64);
DECLARE sql_text TEXT;
WHILE i < days_ahead DO
SET partition_date = DATE_ADD(CURDATE(), INTERVAL i DAY);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
END WHILE;
END$$
CREATE FUNCTION calculate_gdd(
min_temp DECIMAL(5,2),
max_temp DECIMAL(5,2),
base_temp DECIMAL(5,2)
)
RETURNS DECIMAL(8,2)
DETERMINISTIC
BEGIN
DECLARE avg_temp DECIMAL(5,2);
IF avg_temp <= base_temp THEN
RETURN 0;
ELSE
RETURN avg_temp - base_temp;
END IF;
END$$
DELIMITER ;
CREATE USER IF NOT EXISTS 'farm_operator'@'%' IDENTIFIED BY 'operator_pass_2024';
GRANT SELECT, INSERT, UPDATE ON smart_agriculture.* TO 'farm_operator'@'%';
CREATE USER IF NOT EXISTS 'agronomist'@'%' IDENTIFIED BY 'agro_pass_2024';
GRANT ALL PRIVILEGES ON smart_agriculture.* TO 'agronomist'@'%';
CREATE USER IF NOT EXISTS 'veterinarian'@'%' IDENTIFIED BY 'vet_pass_2024';
GRANT SELECT, INSERT, UPDATE ON smart_agriculture.animals TO 'veterinarian'@'%';
GRANT SELECT, INSERT, UPDATE ON smart_agriculture.health_records TO 'veterinarian'@'%';
CREATE USER IF NOT EXISTS 'farm_analyst'@'%' IDENTIFIED BY 'analyst_pass_2024';
GRANT SELECT ON smart_agriculture.* TO 'farm_analyst'@'%';
FLUSH PRIVILEGES;