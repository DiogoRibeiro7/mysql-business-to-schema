-- ETL from raw denormalized table into normalized tables
USE smart_energy;

INSERT INTO dim_meter (id)
SELECT DISTINCT r.meter_id
FROM raw_energy_feed r;

INSERT INTO fact_energy_feed (meter_id, utility_name, building_name, reading_time, kwh, kw_demand, rate_plan, solar_kw, outage_flag)
SELECT
    d_meter.meter_id,
    r.utility_name,
    r.building_name,
    r.reading_time,
    r.kwh,
    r.kw_demand,
    r.rate_plan,
    r.solar_kw,
    r.outage_flag
FROM raw_energy_feed r
LEFT JOIN dim_meter d_meter ON r.meter_id <=> d_meter.id
;
