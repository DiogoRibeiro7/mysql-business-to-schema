-- Normalized schema generated from raw denormalized table
USE insurance;

DROP TABLE IF EXISTS fact_policy_feed;
DROP TABLE IF EXISTS dim_policy;
DROP TABLE IF EXISTS dim_customer;
DROP TABLE IF EXISTS dim_product;
DROP TABLE IF EXISTS dim_agent;

CREATE TABLE dim_policy (
    policy_id INT AUTO_INCREMENT PRIMARY KEY,
    number VARCHAR(255),
    status VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE dim_customer (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255),
    email VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE dim_product (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE dim_agent (
    agent_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE fact_policy_feed (
    fact_id INT AUTO_INCREMENT PRIMARY KEY,
    policy_id INT,
    customer_id INT,
    product_id INT,
    agent_id INT,
    coverage_amount VARCHAR(255),
    premium_amount VARCHAR(255)
) ENGINE=InnoDB;

ALTER TABLE fact_policy_feed
    ADD CONSTRAINT fk_fact_policy_feed_policy FOREIGN KEY (policy_id)
    REFERENCES dim_policy (policy_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE fact_policy_feed
    ADD CONSTRAINT fk_fact_policy_feed_customer FOREIGN KEY (customer_id)
    REFERENCES dim_customer (customer_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE fact_policy_feed
    ADD CONSTRAINT fk_fact_policy_feed_product FOREIGN KEY (product_id)
    REFERENCES dim_product (product_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE fact_policy_feed
    ADD CONSTRAINT fk_fact_policy_feed_agent FOREIGN KEY (agent_id)
    REFERENCES dim_agent (agent_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
