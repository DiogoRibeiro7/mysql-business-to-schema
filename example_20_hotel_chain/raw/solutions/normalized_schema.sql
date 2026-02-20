-- Normalized schema generated from raw denormalized table
USE hotel_chain;

DROP TABLE IF EXISTS fact_reservation_feed;
DROP TABLE IF EXISTS dim_reservation;
DROP TABLE IF EXISTS dim_guest;
DROP TABLE IF EXISTS dim_property;
DROP TABLE IF EXISTS dim_room;

CREATE TABLE dim_reservation (
    reservation_id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE dim_guest (
    guest_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255),
    email VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE dim_property (
    property_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE dim_room (
    room_id INT AUTO_INCREMENT PRIMARY KEY,
    type VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE fact_reservation_feed (
    fact_id INT AUTO_INCREMENT PRIMARY KEY,
    reservation_id INT,
    guest_id INT,
    property_id INT,
    room_id INT,
    check_in VARCHAR(255),
    check_out VARCHAR(255),
    rate VARCHAR(255),
    status VARCHAR(255)
) ENGINE=InnoDB;

ALTER TABLE fact_reservation_feed
    ADD CONSTRAINT fk_fact_reservation_feed_reservation FOREIGN KEY (reservation_id)
    REFERENCES dim_reservation (reservation_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE fact_reservation_feed
    ADD CONSTRAINT fk_fact_reservation_feed_guest FOREIGN KEY (guest_id)
    REFERENCES dim_guest (guest_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE fact_reservation_feed
    ADD CONSTRAINT fk_fact_reservation_feed_property FOREIGN KEY (property_id)
    REFERENCES dim_property (property_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE fact_reservation_feed
    ADD CONSTRAINT fk_fact_reservation_feed_room FOREIGN KEY (room_id)
    REFERENCES dim_room (room_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
