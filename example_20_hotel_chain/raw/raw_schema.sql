-- Raw denormalized table for normalization exercises
USE hotel_chain;

DROP TABLE IF EXISTS raw_reservation_feed;

CREATE TABLE raw_reservation_feed (
    row_id INT AUTO_INCREMENT PRIMARY KEY,
    reservation_code VARCHAR(255),
    guest_name VARCHAR(255),
    guest_email VARCHAR(255),
    property_name VARCHAR(255),
    room_type VARCHAR(255),
    check_in VARCHAR(255),
    check_out VARCHAR(255),
    rate VARCHAR(255),
    status VARCHAR(255)
) ENGINE=InnoDB;
