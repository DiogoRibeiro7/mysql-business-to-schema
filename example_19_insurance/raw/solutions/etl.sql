-- ETL from raw denormalized table into normalized tables
USE insurance;

INSERT INTO dim_policy (number, status, created_at, updated_at)
SELECT DISTINCT r.policy_number, r.policy_status, NOW(), NOW()
FROM raw_policy_feed r;

INSERT INTO dim_customer (full_name, first_name, last_name, email, created_at, updated_at)
SELECT DISTINCT r.customer_name, SUBSTRING_INDEX(r.customer_name, ' ', 1), CASE WHEN INSTR(r.customer_name, ' ') > 0 THEN SUBSTRING(r.customer_name, INSTR(r.customer_name, ' ') + 1) ELSE '' END, r.customer_email, NOW(), NOW()
FROM raw_policy_feed r;

INSERT INTO dim_product (name, created_at, updated_at)
SELECT DISTINCT r.product_name, NOW(), NOW()
FROM raw_policy_feed r;

INSERT INTO dim_agent (full_name, first_name, last_name, created_at, updated_at)
SELECT DISTINCT r.agent_name, SUBSTRING_INDEX(r.agent_name, ' ', 1), CASE WHEN INSTR(r.agent_name, ' ') > 0 THEN SUBSTRING(r.agent_name, INSTR(r.agent_name, ' ') + 1) ELSE '' END, NOW(), NOW()
FROM raw_policy_feed r;

INSERT INTO fact_policy_feed (policy_id, customer_id, product_id, agent_id, source_row_id, coverage_amount, premium_amount, created_at, updated_at)
SELECT
    d_policy.policy_id,
    d_customer.customer_id,
    d_product.product_id,
    d_agent.agent_id,
    r.row_id,
    r.coverage_amount,
    r.premium_amount,
    NOW(),
    NOW()
FROM raw_policy_feed r
LEFT JOIN dim_policy d_policy ON r.policy_number <=> d_policy.number AND r.policy_status <=> d_policy.status
LEFT JOIN dim_customer d_customer ON r.customer_name <=> d_customer.full_name AND SUBSTRING_INDEX(r.customer_name, ' ', 1) <=> d_customer.first_name AND CASE WHEN INSTR(r.customer_name, ' ') > 0 THEN SUBSTRING(r.customer_name, INSTR(r.customer_name, ' ') + 1) ELSE '' END <=> d_customer.last_name AND r.customer_email <=> d_customer.email
LEFT JOIN dim_product d_product ON r.product_name <=> d_product.name
LEFT JOIN dim_agent d_agent ON r.agent_name <=> d_agent.full_name AND SUBSTRING_INDEX(r.agent_name, ' ', 1) <=> d_agent.first_name AND CASE WHEN INSTR(r.agent_name, ' ') > 0 THEN SUBSTRING(r.agent_name, INSTR(r.agent_name, ' ') + 1) ELSE '' END <=> d_agent.last_name
;
