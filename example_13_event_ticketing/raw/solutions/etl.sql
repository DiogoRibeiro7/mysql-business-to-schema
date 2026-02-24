-- ETL from raw denormalized table into normalized tables
USE event_ticketing;

INSERT INTO dim_event (name, date, created_at, updated_at)
SELECT DISTINCT r.event_name, r.event_date, NOW(), NOW()
FROM raw_ticket_sales r;

INSERT INTO dim_venue (name, created_at, updated_at)
SELECT DISTINCT r.venue_name, NOW(), NOW()
FROM raw_ticket_sales r;

INSERT INTO dim_ticket (type, created_at, updated_at)
SELECT DISTINCT r.ticket_type, NOW(), NOW()
FROM raw_ticket_sales r;

INSERT INTO dim_seat (label, created_at, updated_at)
SELECT DISTINCT r.seat_label, NOW(), NOW()
FROM raw_ticket_sales r;

INSERT INTO dim_payment (method, created_at, updated_at)
SELECT DISTINCT r.payment_method, NOW(), NOW()
FROM raw_ticket_sales r;

INSERT INTO fact_ticket_sales (event_id, venue_id, ticket_id, seat_id, payment_id, source_row_id, buyer_email, price, purchase_time, created_at, updated_at)
SELECT
    d_event.event_id,
    d_venue.venue_id,
    d_ticket.ticket_id,
    d_seat.seat_id,
    d_payment.payment_id,
    r.row_id,
    r.buyer_email,
    r.price,
    r.purchase_time,
    NOW(),
    NOW()
FROM raw_ticket_sales r
LEFT JOIN dim_event d_event ON r.event_name <=> d_event.name AND r.event_date <=> d_event.date
LEFT JOIN dim_venue d_venue ON r.venue_name <=> d_venue.name
LEFT JOIN dim_ticket d_ticket ON r.ticket_type <=> d_ticket.type
LEFT JOIN dim_seat d_seat ON r.seat_label <=> d_seat.label
LEFT JOIN dim_payment d_payment ON r.payment_method <=> d_payment.method
;
