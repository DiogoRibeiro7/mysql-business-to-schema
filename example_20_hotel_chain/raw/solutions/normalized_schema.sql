-- Normalized schema generated from raw denormalized table
USE hotel_chain;

DROP TABLE IF EXISTS fact_reservation_feed;
DROP TABLE IF EXISTS dim_reservation;
DROP TABLE IF EXISTS dim_guest;
DROP TABLE IF EXISTS dim_property;
DROP TABLE IF EXISTS dim_room;

CREATE TABLE dim_reservation (
    reservation_id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_dim_reservation_natural (code),
    INDEX idx_dim_reservation_natural (code)
) ENGINE=InnoDB;

CREATE TABLE dim_guest (
    guest_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(255),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_dim_guest_natural (full_name, first_name, last_name, email),
    INDEX idx_dim_guest_natural (full_name, first_name, last_name, email)
) ENGINE=InnoDB;

CREATE TABLE dim_property (
    property_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_dim_property_natural (name),
    INDEX idx_dim_property_natural (name)
) ENGINE=InnoDB;

CREATE TABLE dim_room (
    room_id INT AUTO_INCREMENT PRIMARY KEY,
    type VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_dim_room_natural (type),
    INDEX idx_dim_room_natural (type)
) ENGINE=InnoDB;

CREATE TABLE fact_reservation_feed (
    fact_id INT AUTO_INCREMENT PRIMARY KEY,
    reservation_id INT,
    guest_id INT,
    property_id INT,
    room_id INT,
    source_row_id INT,
    UNIQUE KEY uq_fact_reservation_feed_source (source_row_id),
    check_in VARCHAR(255),
    check_out VARCHAR(255),
    rate VARCHAR(255),
    status ENUM('cancelled', 'checked_in', 'confirmed'),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

ALTER TABLE fact_reservation_feed
    ADD CONSTRAINT fk_fact_reservation_feed_reservation FOREIGN KEY (reservation_id)
    REFERENCES dim_reservation (reservation_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE fact_reservation_feed
    ADD CONSTRAINT fk_fact_reservation_feed_guest FOREIGN KEY (guest_id)
    REFERENCES dim_guest (guest_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE fact_reservation_feed
    ADD CONSTRAINT fk_fact_reservation_feed_property FOREIGN KEY (property_id)
    REFERENCES dim_property (property_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE fact_reservation_feed
    ADD CONSTRAINT fk_fact_reservation_feed_room FOREIGN KEY (room_id)
    REFERENCES dim_room (room_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;
CREATE INDEX idx_fact_reservation_feed_reservation ON fact_reservation_feed (reservation_id);
CREATE INDEX idx_fact_reservation_feed_guest ON fact_reservation_feed (guest_id);
CREATE INDEX idx_fact_reservation_feed_property ON fact_reservation_feed (property_id);
CREATE INDEX idx_fact_reservation_feed_room ON fact_reservation_feed (room_id);
CREATE INDEX idx_fact_reservation_feed_source ON fact_reservation_feed (source_row_id);
