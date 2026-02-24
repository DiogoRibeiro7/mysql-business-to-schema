-- ETL from raw denormalized table into normalized tables
USE insurance;

INSERT INTO dim_policy (number, status)
SELECT DISTINCT r.policy_number, r.policy_status
FROM raw_policy_feed r;

INSERT INTO dim_customer (name, email)
SELECT DISTINCT r.customer_name, r.customer_email
FROM raw_policy_feed r;

INSERT INTO dim_product (name)
SELECT DISTINCT r.product_name
FROM raw_policy_feed r;

INSERT INTO dim_agent (name)
SELECT DISTINCT r.agent_name
FROM raw_policy_feed r;

INSERT INTO fact_policy_feed (policy_id, customer_id, product_id, agent_id, source_row_id, coverage_amount, premium_amount)
SELECT
    d_policy.policy_id,
    d_customer.customer_id,
    d_product.product_id,
    d_agent.agent_id,
    r.row_id,
    r.coverage_amount,
    r.premium_amount
FROM raw_policy_feed r
LEFT JOIN dim_policy d_policy ON r.policy_number <=> d_policy.number AND r.policy_status <=> d_policy.status
LEFT JOIN dim_customer d_customer ON r.customer_name <=> d_customer.name AND r.customer_email <=> d_customer.email
LEFT JOIN dim_product d_product ON r.product_name <=> d_product.name
LEFT JOIN dim_agent d_agent ON r.agent_name <=> d_agent.name
;
