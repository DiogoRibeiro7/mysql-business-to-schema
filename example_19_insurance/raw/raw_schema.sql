-- Raw denormalized table for normalization exercises
USE insurance;

DROP TABLE IF EXISTS raw_policy_feed;

CREATE TABLE raw_policy_feed (
    row_id INT AUTO_INCREMENT PRIMARY KEY,
    policy_number VARCHAR(255),
    customer_name VARCHAR(255),
    customer_email VARCHAR(255),
    product_name VARCHAR(255),
    coverage_amount VARCHAR(255),
    premium_amount VARCHAR(255),
    agent_name VARCHAR(255),
    policy_status VARCHAR(255)
) ENGINE=InnoDB;
