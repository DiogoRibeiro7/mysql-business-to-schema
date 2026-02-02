-- Load generated Smart Energy data
-- Generated on 2026-02-02 16:38:11.434442

-- Clear existing data
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE consumption_readings;
TRUNCATE TABLE production_readings;
TRUNCATE TABLE power_quality_readings;
TRUNCATE TABLE demand_response_events;
TRUNCATE TABLE outages;
TRUNCATE TABLE solar_panels;
TRUNCATE TABLE meters;
TRUNCATE TABLE customers;
TRUNCATE TABLE transformers;
TRUNCATE TABLE utilities;
SET FOREIGN_KEY_CHECKS = 1;

-- Load utilities
LOAD DATA INFILE '/var/lib/mysql-files/smart_energy/utilities.csv'
INTO TABLE utilities
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(utility_id, name, type, service_area, customer_count, created_at);

-- Load transformers
LOAD DATA INFILE '/var/lib/mysql-files/smart_energy/transformers.csv'
INTO TABLE transformers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(transformer_id, utility_id, transformer_code, location_lat, location_lon,
 capacity_kva, installation_date, status);

-- Load customers
LOAD DATA INFILE '/var/lib/mysql-files/smart_energy/customers.csv'
INTO TABLE customers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(customer_id, utility_id, transformer_id, account_number, customer_type,
 name, address, rate_plan, contract_start, status,
 has_solar, has_ev, enrolled_demand_response);

-- Load meters
LOAD DATA INFILE '/var/lib/mysql-files/smart_energy/meters.csv'
INTO TABLE meters
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(meter_id, customer_id, meter_number, meter_type, model,
 installation_date, last_reading_time, firmware_version,
 communication_type, status);

-- Load solar panels
LOAD DATA INFILE '/var/lib/mysql-files/smart_energy/solar_panels.csv'
INTO TABLE solar_panels
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(panel_id, customer_id, meter_id, capacity_kw, panel_count,
 panel_type, inverter_type, installation_date, orientation,
 tilt_angle, efficiency_rating, status);

-- Load sample consumption readings (limited dataset)
LOAD DATA INFILE '/var/lib/mysql-files/smart_energy/consumption_readings.csv'
INTO TABLE consumption_readings
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(meter_id, reading_time, consumption_kwh, power_kw, voltage,
 current, power_factor, frequency);

-- Load sample production readings (limited dataset)
LOAD DATA INFILE '/var/lib/mysql-files/smart_energy/production_readings.csv'
INTO TABLE production_readings
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(panel_id, reading_time, production_kwh, power_kw,
 panel_temperature, inverter_efficiency, dc_voltage, dc_current);

-- Update statistics
ANALYZE TABLE utilities, customers, meters, consumption_readings;

SELECT 'Data load complete!' as status;
SELECT COUNT(*) as utilities_count FROM utilities;
SELECT COUNT(*) as customers_count FROM customers;
SELECT COUNT(*) as meters_count FROM meters;
SELECT COUNT(*) as readings_count FROM consumption_readings;
