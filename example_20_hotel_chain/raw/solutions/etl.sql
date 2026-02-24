-- ETL from raw denormalized table into normalized tables
USE hotel_chain;

INSERT INTO dim_reservation (code, created_at, updated_at)
SELECT DISTINCT r.reservation_code, NOW(), NOW()
FROM raw_reservation_feed r;

INSERT INTO dim_guest (full_name, first_name, last_name, email, created_at, updated_at)
SELECT DISTINCT r.guest_name, SUBSTRING_INDEX(r.guest_name, ' ', 1), CASE WHEN INSTR(r.guest_name, ' ') > 0 THEN SUBSTRING(r.guest_name, INSTR(r.guest_name, ' ') + 1) ELSE '' END, r.guest_email, NOW(), NOW()
FROM raw_reservation_feed r;

INSERT INTO dim_property (name, created_at, updated_at)
SELECT DISTINCT r.property_name, NOW(), NOW()
FROM raw_reservation_feed r;

INSERT INTO dim_room (type, created_at, updated_at)
SELECT DISTINCT r.room_type, NOW(), NOW()
FROM raw_reservation_feed r;

INSERT INTO fact_reservation_feed (reservation_id, guest_id, property_id, room_id, source_row_id, check_in, check_out, rate, status, created_at, updated_at)
SELECT
    d_reservation.reservation_id,
    d_guest.guest_id,
    d_property.property_id,
    d_room.room_id,
    r.row_id,
    r.check_in,
    r.check_out,
    r.rate,
    r.status,
    NOW(),
    NOW()
FROM raw_reservation_feed r
LEFT JOIN dim_reservation d_reservation ON r.reservation_code <=> d_reservation.code
LEFT JOIN dim_guest d_guest ON r.guest_name <=> d_guest.full_name AND SUBSTRING_INDEX(r.guest_name, ' ', 1) <=> d_guest.first_name AND CASE WHEN INSTR(r.guest_name, ' ') > 0 THEN SUBSTRING(r.guest_name, INSTR(r.guest_name, ' ') + 1) ELSE '' END <=> d_guest.last_name AND r.guest_email <=> d_guest.email
LEFT JOIN dim_property d_property ON r.property_name <=> d_property.name
LEFT JOIN dim_room d_room ON r.room_type <=> d_room.type
;
