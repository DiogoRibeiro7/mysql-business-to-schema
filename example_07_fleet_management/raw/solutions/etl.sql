-- ETL from raw denormalized table into normalized tables
USE fleet_management;

INSERT INTO dim_vehicle (number, created_at, updated_at)
SELECT DISTINCT r.vehicle_number, NOW(), NOW()
FROM raw_trip_feed r;

INSERT INTO dim_driver (full_name, first_name, last_name, created_at, updated_at)
SELECT DISTINCT r.driver_name, SUBSTRING_INDEX(r.driver_name, ' ', 1), CASE WHEN INSTR(r.driver_name, ' ') > 0 THEN SUBSTRING(r.driver_name, INSTR(r.driver_name, ' ') + 1) ELSE '' END, NOW(), NOW()
FROM raw_trip_feed r;

INSERT INTO fact_trip_feed (vehicle_id, driver_id, source_row_id, gps_time, latitude, longitude, speed_mph, trip_status, fuel_level, depot_name, created_at, updated_at)
SELECT
    d_vehicle.vehicle_id,
    d_driver.driver_id,
    r.row_id,
    r.gps_time,
    r.latitude,
    r.longitude,
    r.speed_mph,
    r.trip_status,
    r.fuel_level,
    r.depot_name,
    NOW(),
    NOW()
FROM raw_trip_feed r
LEFT JOIN dim_vehicle d_vehicle ON r.vehicle_number <=> d_vehicle.number
LEFT JOIN dim_driver d_driver ON r.driver_name <=> d_driver.full_name AND SUBSTRING_INDEX(r.driver_name, ' ', 1) <=> d_driver.first_name AND CASE WHEN INSTR(r.driver_name, ' ') > 0 THEN SUBSTRING(r.driver_name, INSTR(r.driver_name, ' ') + 1) ELSE '' END <=> d_driver.last_name
;
