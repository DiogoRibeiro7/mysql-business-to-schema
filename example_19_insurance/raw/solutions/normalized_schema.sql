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
    status VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_dim_policy_natural (number, status),
    INDEX idx_dim_policy_natural (number, status)
) ENGINE=InnoDB;

CREATE TABLE dim_customer (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(255),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_dim_customer_natural (full_name, first_name, last_name, email),
    INDEX idx_dim_customer_natural (full_name, first_name, last_name, email)
) ENGINE=InnoDB;

CREATE TABLE dim_product (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_dim_product_natural (name),
    INDEX idx_dim_product_natural (name)
) ENGINE=InnoDB;

CREATE TABLE dim_agent (
    agent_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(255),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_dim_agent_natural (full_name, first_name, last_name),
    INDEX idx_dim_agent_natural (full_name, first_name, last_name)
) ENGINE=InnoDB;

CREATE TABLE fact_policy_feed (
    fact_id INT AUTO_INCREMENT PRIMARY KEY,
    policy_id INT,
    customer_id INT,
    product_id INT,
    agent_id INT,
    source_row_id INT,
    UNIQUE KEY uq_fact_policy_feed_source (source_row_id),
    coverage_amount VARCHAR(255),
    premium_amount VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

ALTER TABLE fact_policy_feed
    ADD CONSTRAINT fk_fact_policy_feed_policy FOREIGN KEY (policy_id)
    REFERENCES dim_policy (policy_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE fact_policy_feed
    ADD CONSTRAINT fk_fact_policy_feed_customer FOREIGN KEY (customer_id)
    REFERENCES dim_customer (customer_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE fact_policy_feed
    ADD CONSTRAINT fk_fact_policy_feed_product FOREIGN KEY (product_id)
    REFERENCES dim_product (product_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE fact_policy_feed
    ADD CONSTRAINT fk_fact_policy_feed_agent FOREIGN KEY (agent_id)
    REFERENCES dim_agent (agent_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;
CREATE INDEX idx_fact_policy_feed_policy ON fact_policy_feed (policy_id);
CREATE INDEX idx_fact_policy_feed_customer ON fact_policy_feed (customer_id);
CREATE INDEX idx_fact_policy_feed_product ON fact_policy_feed (product_id);
CREATE INDEX idx_fact_policy_feed_agent ON fact_policy_feed (agent_id);
CREATE INDEX idx_fact_policy_feed_source ON fact_policy_feed (source_row_id);
