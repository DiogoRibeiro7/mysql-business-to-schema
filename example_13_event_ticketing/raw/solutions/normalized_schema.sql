-- Normalized schema generated from raw denormalized table
USE event_ticketing;

DROP TABLE IF EXISTS fact_ticket_sales;
DROP TABLE IF EXISTS dim_event;
DROP TABLE IF EXISTS dim_venue;
DROP TABLE IF EXISTS dim_ticket;
DROP TABLE IF EXISTS dim_seat;
DROP TABLE IF EXISTS dim_payment;

CREATE TABLE dim_event (
    event_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255),
    date VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE dim_venue (
    venue_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE dim_ticket (
    ticket_id INT AUTO_INCREMENT PRIMARY KEY,
    type VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE dim_seat (
    seat_id INT AUTO_INCREMENT PRIMARY KEY,
    label VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE dim_payment (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    method VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE fact_ticket_sales (
    fact_id INT AUTO_INCREMENT PRIMARY KEY,
    event_id INT,
    venue_id INT,
    ticket_id INT,
    seat_id INT,
    payment_id INT,
    buyer_email VARCHAR(255),
    price VARCHAR(255),
    purchase_time VARCHAR(255)
) ENGINE=InnoDB;

ALTER TABLE fact_ticket_sales
    ADD CONSTRAINT fk_fact_ticket_sales_event FOREIGN KEY (event_id)
    REFERENCES dim_event (event_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE fact_ticket_sales
    ADD CONSTRAINT fk_fact_ticket_sales_venue FOREIGN KEY (venue_id)
    REFERENCES dim_venue (venue_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE fact_ticket_sales
    ADD CONSTRAINT fk_fact_ticket_sales_ticket FOREIGN KEY (ticket_id)
    REFERENCES dim_ticket (ticket_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE fact_ticket_sales
    ADD CONSTRAINT fk_fact_ticket_sales_seat FOREIGN KEY (seat_id)
    REFERENCES dim_seat (seat_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE fact_ticket_sales
    ADD CONSTRAINT fk_fact_ticket_sales_payment FOREIGN KEY (payment_id)
    REFERENCES dim_payment (payment_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
