-- PostgreSQL Schema
-- Converted from MySQL on 2026-02-17T23:11:17.351672
-- Generator: MySQL to PostgreSQL Converter

DROP DATABASE IF EXISTS fleet_management;
-- Create database (run as superuser)
-- CREATE DATABASE fleet_management;
-- \c fleet_management

DELIMITER $$
CREATE FUNCTION calculate_distance(
lat1 DECIMAL(10,6),
lon1 DECIMAL(10,6),
lat2 DECIMAL(10,6),
lon2 DECIMAL(10,6)
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
DECLARE R DECIMAL(10,2) DEFAULT 6371; -- Earth radius in km
DECLARE dLat DECIMAL(10,6);
DECLARE dLon DECIMAL(10,6);
DECLARE a DECIMAL(10,6);
DECLARE c DECIMAL(10,6);
RETURN R * c; -- Distance in km
END$$
CREATE PROCEDURE create_gps_partitions(
IN days_ahead INT
)
BEGIN
DECLARE i INT DEFAULT 0;
DECLARE partition_date DATE;
DECLARE partition_name VARCHAR(64);
WHILE i < days_ahead DO
SET partition_date = DATE_ADD(CURDATE(), INTERVAL i DAY);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
END WHILE;
END$$
DELIMITER ;
CREATE USER IF NOT EXISTS 'fleet_manager'@'%' IDENTIFIED BY 'fleet_pass_2024';
GRANT ALL PRIVILEGES ON fleet_management.* TO 'fleet_manager'@'%';
CREATE USER IF NOT EXISTS 'dispatcher'@'%' IDENTIFIED BY 'dispatch_pass_2024';
GRANT SELECT, INSERT, UPDATE ON fleet_management.* TO 'dispatcher'@'%';
CREATE USER IF NOT EXISTS 'driver_app'@'%' IDENTIFIED BY 'driver_pass_2024';
GRANT SELECT ON fleet_management.* TO 'driver_app'@'%';
GRANT INSERT ON fleet_management.gps_positions TO 'driver_app'@'%';
GRANT INSERT ON fleet_management.driver_logs TO 'driver_app'@'%';
CREATE USER IF NOT EXISTS 'compliance'@'%' IDENTIFIED BY 'compliance_pass_2024';
GRANT SELECT ON fleet_management.* TO 'compliance'@'%';
CREATE USER IF NOT EXISTS 'analyst'@'%' IDENTIFIED BY 'analyst_pass_2024';
GRANT SELECT ON fleet_management.* TO 'analyst'@'%';
FLUSH PRIVILEGES;