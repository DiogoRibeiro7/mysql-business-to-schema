-- ETL from raw denormalized table into normalized tables
USE industrial_iot;

INSERT INTO dim_sensor (type)
SELECT DISTINCT r.sensor_type
FROM raw_machine_feed r;

INSERT INTO fact_machine_feed (sensor_id, factory_name, line_name, machine_code, reading_time, reading_value, unit, operator_name, work_order_code)
SELECT
    d_sensor.sensor_id,
    r.factory_name,
    r.line_name,
    r.machine_code,
    r.reading_time,
    r.reading_value,
    r.unit,
    r.operator_name,
    r.work_order_code
FROM raw_machine_feed r
LEFT JOIN dim_sensor d_sensor ON r.sensor_type <=> d_sensor.type
;
