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
    date VARCHAR(255),
    UNIQUE KEY uq_dim_event_natural (name, date)
) ENGINE=InnoDB;

CREATE TABLE dim_venue (
    venue_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255),
    UNIQUE KEY uq_dim_venue_natural (name)
) ENGINE=InnoDB;

CREATE TABLE dim_ticket (
    ticket_id INT AUTO_INCREMENT PRIMARY KEY,
    type VARCHAR(255),
    UNIQUE KEY uq_dim_ticket_natural (type)
) ENGINE=InnoDB;

CREATE TABLE dim_seat (
    seat_id INT AUTO_INCREMENT PRIMARY KEY,
    label VARCHAR(255),
    UNIQUE KEY uq_dim_seat_natural (label)
) ENGINE=InnoDB;

CREATE TABLE dim_payment (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    method VARCHAR(255),
    UNIQUE KEY uq_dim_payment_natural (method)
) ENGINE=InnoDB;

CREATE TABLE fact_ticket_sales (
    fact_id INT AUTO_INCREMENT PRIMARY KEY,
    event_id INT,
    venue_id INT,
    ticket_id INT,
    seat_id INT,
    payment_id INT,
    source_row_id INT,
    UNIQUE KEY uq_fact_ticket_sales_source (source_row_id),
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
CREATE INDEX idx_fact_ticket_sales_event ON fact_ticket_sales (event_id);
CREATE INDEX idx_fact_ticket_sales_venue ON fact_ticket_sales (venue_id);
CREATE INDEX idx_fact_ticket_sales_ticket ON fact_ticket_sales (ticket_id);
CREATE INDEX idx_fact_ticket_sales_seat ON fact_ticket_sales (seat_id);
CREATE INDEX idx_fact_ticket_sales_payment ON fact_ticket_sales (payment_id);
CREATE INDEX idx_fact_ticket_sales_source ON fact_ticket_sales (source_row_id);
