-- ETL from raw denormalized table into normalized tables
USE smart_agriculture;

INSERT INTO dim_sensor (type, created_at, updated_at)
SELECT DISTINCT r.sensor_type, NOW(), NOW()
FROM raw_farm_telemetry r;

INSERT INTO fact_farm_telemetry (sensor_id, source_row_id, farm_name, field_name, zone_code, reading_time, reading_value, unit, crop_type, irrigation_event, created_at, updated_at)
SELECT
    d_sensor.sensor_id,
    r.row_id,
    r.farm_name,
    r.field_name,
    r.zone_code,
    r.reading_time,
    r.reading_value,
    r.unit,
    r.crop_type,
    r.irrigation_event,
    NOW(),
    NOW()
FROM raw_farm_telemetry r
LEFT JOIN dim_sensor d_sensor ON r.sensor_type <=> d_sensor.type
;
