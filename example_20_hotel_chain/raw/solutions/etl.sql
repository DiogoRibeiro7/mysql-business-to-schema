-- ETL from raw denormalized table into normalized tables
USE hotel_chain;

INSERT INTO dim_reservation (code)
SELECT DISTINCT r.reservation_code
FROM raw_reservation_feed r;

INSERT INTO dim_guest (name, email)
SELECT DISTINCT r.guest_name, r.guest_email
FROM raw_reservation_feed r;

INSERT INTO dim_property (name)
SELECT DISTINCT r.property_name
FROM raw_reservation_feed r;

INSERT INTO dim_room (type)
SELECT DISTINCT r.room_type
FROM raw_reservation_feed r;

INSERT INTO fact_reservation_feed (reservation_id, guest_id, property_id, room_id, source_row_id, check_in, check_out, rate, status)
SELECT
    d_reservation.reservation_id,
    d_guest.guest_id,
    d_property.property_id,
    d_room.room_id,
    r.row_id,
    r.check_in,
    r.check_out,
    r.rate,
    r.status
FROM raw_reservation_feed r
LEFT JOIN dim_reservation d_reservation ON r.reservation_code <=> d_reservation.code
LEFT JOIN dim_guest d_guest ON r.guest_name <=> d_guest.name AND r.guest_email <=> d_guest.email
LEFT JOIN dim_property d_property ON r.property_name <=> d_property.name
LEFT JOIN dim_room d_room ON r.room_type <=> d_room.type
;
