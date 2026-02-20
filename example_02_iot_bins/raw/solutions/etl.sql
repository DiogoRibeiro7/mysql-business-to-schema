-- ETL from raw denormalized table into normalized tables
USE iot_bins;

INSERT INTO dim_device (id)
SELECT DISTINCT r.device_id
FROM raw_iot_bins r;

INSERT INTO dim_bin (code, type)
SELECT DISTINCT r.bin_code, r.bin_type
FROM raw_iot_bins r;

INSERT INTO dim_sensor (type)
SELECT DISTINCT r.sensor_type
FROM raw_iot_bins r;

INSERT INTO fact_iot_bins (device_id, bin_id, sensor_id, district_name, installed_at, reading_time, reading_value, reading_unit, battery_level, gps_lat, gps_lon, alert_type)
SELECT
    d_device.device_id,
    d_bin.bin_id,
    d_sensor.sensor_id,
    r.district_name,
    r.installed_at,
    r.reading_time,
    r.reading_value,
    r.reading_unit,
    r.battery_level,
    r.gps_lat,
    r.gps_lon,
    r.alert_type
FROM raw_iot_bins r
LEFT JOIN dim_device d_device ON r.device_id <=> d_device.id
LEFT JOIN dim_bin d_bin ON r.bin_code <=> d_bin.code AND r.bin_type <=> d_bin.type
LEFT JOIN dim_sensor d_sensor ON r.sensor_type <=> d_sensor.type
;
