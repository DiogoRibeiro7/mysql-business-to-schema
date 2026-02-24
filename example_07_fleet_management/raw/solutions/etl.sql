-- ETL from raw denormalized table into normalized tables
USE fleet_management;

INSERT INTO dim_vehicle (number)
SELECT DISTINCT r.vehicle_number
FROM raw_trip_feed r;

INSERT INTO dim_driver (name)
SELECT DISTINCT r.driver_name
FROM raw_trip_feed r;

INSERT INTO fact_trip_feed (vehicle_id, driver_id, source_row_id, gps_time, latitude, longitude, speed_mph, trip_status, fuel_level, depot_name)
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
    r.depot_name
FROM raw_trip_feed r
LEFT JOIN dim_vehicle d_vehicle ON r.vehicle_number <=> d_vehicle.number
LEFT JOIN dim_driver d_driver ON r.driver_name <=> d_driver.name
;
