-- ETL from raw denormalized table into normalized tables
USE logistics;

INSERT INTO dim_shipment (number)
SELECT DISTINCT r.shipment_number
FROM raw_shipment_feed r;

INSERT INTO dim_delivery (date)
SELECT DISTINCT r.delivery_date
FROM raw_shipment_feed r;

INSERT INTO fact_shipment_feed (shipment_id, delivery_id, source_row_id, origin_warehouse, destination_city, carrier_name, ship_date, status, total_weight_kg)
SELECT
    d_shipment.shipment_id,
    d_delivery.delivery_id,
    r.row_id,
    r.origin_warehouse,
    r.destination_city,
    r.carrier_name,
    r.ship_date,
    r.status,
    r.total_weight_kg
FROM raw_shipment_feed r
LEFT JOIN dim_shipment d_shipment ON r.shipment_number <=> d_shipment.number
LEFT JOIN dim_delivery d_delivery ON r.delivery_date <=> d_delivery.date
;
