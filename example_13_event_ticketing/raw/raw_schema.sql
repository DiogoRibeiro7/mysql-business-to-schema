-- Raw denormalized table for normalization exercises
USE event_ticketing;

DROP TABLE IF EXISTS raw_ticket_sales;

CREATE TABLE raw_ticket_sales (
    row_id INT AUTO_INCREMENT PRIMARY KEY,
    event_name VARCHAR(255),
    venue_name VARCHAR(255),
    event_date VARCHAR(255),
    buyer_email VARCHAR(255),
    ticket_type VARCHAR(255),
    seat_label VARCHAR(255),
    price VARCHAR(255),
    purchase_time VARCHAR(255),
    payment_method VARCHAR(255)
) ENGINE=InnoDB;
