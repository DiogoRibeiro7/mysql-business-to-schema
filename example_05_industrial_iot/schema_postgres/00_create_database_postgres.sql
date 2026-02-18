-- PostgreSQL Schema
-- Converted from MySQL on 2026-02-17T23:11:17.341104
-- Generator: MySQL to PostgreSQL Converter

DROP DATABASE IF EXISTS industrial_iot;
-- Create database (run as superuser)
-- CREATE DATABASE industrial_iot;
-- \c industrial_iot

DELIMITER $$
CREATE PROCEDURE create_monthly_partitions(
IN table_name VARCHAR(64),
IN months_ahead INT
)
BEGIN
DECLARE i INT DEFAULT 0;
DECLARE partition_date DATE;
DECLARE partition_name VARCHAR(64);
DECLARE sql_text TEXT;
WHILE i < months_ahead DO
SET partition_date = DATE_ADD(CURDATE(), INTERVAL i MONTH);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
END WHILE;
END$$
DELIMITER ;
CREATE USER IF NOT EXISTS 'factory_operator'@'%' IDENTIFIED BY 'operator_pass_2024';
GRANT SELECT ON industrial_iot.* TO 'factory_operator'@'%';
CREATE USER IF NOT EXISTS 'production_manager'@'%' IDENTIFIED BY 'manager_pass_2024';
GRANT SELECT, INSERT, UPDATE ON industrial_iot.* TO 'production_manager'@'%';
CREATE USER IF NOT EXISTS 'maintenance_engineer'@'%' IDENTIFIED BY 'maintenance_pass_2024';
GRANT ALL PRIVILEGES ON industrial_iot.* TO 'maintenance_engineer'@'%';
CREATE USER IF NOT EXISTS 'data_analyst'@'%' IDENTIFIED BY 'analyst_pass_2024';
GRANT SELECT ON industrial_iot.* TO 'data_analyst'@'%';
FLUSH PRIVILEGES;