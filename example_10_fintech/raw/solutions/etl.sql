-- ETL from raw denormalized table into normalized tables
USE fintech;

INSERT INTO dim_customer (email, full_name, first_name, last_name, type, created_at, updated_at)
SELECT DISTINCT r.customer_email, r.customer_name, SUBSTRING_INDEX(r.customer_name, ' ', 1), CASE WHEN INSTR(r.customer_name, ' ') > 0 THEN SUBSTRING(r.customer_name, INSTR(r.customer_name, ' ') + 1) ELSE '' END, r.customer_type, NOW(), NOW()
FROM raw_transaction_feed r;

INSERT INTO dim_account (number, type, created_at, updated_at)
SELECT DISTINCT r.account_number, r.account_type, NOW(), NOW()
FROM raw_transaction_feed r;

INSERT INTO dim_transaction (id, type, date, created_at, updated_at)
SELECT DISTINCT r.transaction_id, r.transaction_type, r.transaction_date, NOW(), NOW()
FROM raw_transaction_feed r;

INSERT INTO dim_merchant (name, category, created_at, updated_at)
SELECT DISTINCT r.merchant_name, r.merchant_category, NOW(), NOW()
FROM raw_transaction_feed r;

INSERT INTO dim_device (fingerprint, created_at, updated_at)
SELECT DISTINCT r.device_fingerprint, NOW(), NOW()
FROM raw_transaction_feed r;

INSERT INTO fact_transaction_feed (customer_id, account_id, transaction_id, merchant_id, device_id, source_row_id, currency, amount, risk_score, kyc_status, created_at, updated_at)
SELECT
    d_customer.customer_id,
    d_account.account_id,
    d_transaction.transaction_id,
    d_merchant.merchant_id,
    d_device.device_id,
    r.row_id,
    r.currency,
    r.amount,
    r.risk_score,
    r.kyc_status,
    NOW(),
    NOW()
FROM raw_transaction_feed r
LEFT JOIN dim_customer d_customer ON r.customer_email <=> d_customer.email AND r.customer_name <=> d_customer.full_name AND SUBSTRING_INDEX(r.customer_name, ' ', 1) <=> d_customer.first_name AND CASE WHEN INSTR(r.customer_name, ' ') > 0 THEN SUBSTRING(r.customer_name, INSTR(r.customer_name, ' ') + 1) ELSE '' END <=> d_customer.last_name AND r.customer_type <=> d_customer.type
LEFT JOIN dim_account d_account ON r.account_number <=> d_account.number AND r.account_type <=> d_account.type
LEFT JOIN dim_transaction d_transaction ON r.transaction_id <=> d_transaction.id AND r.transaction_type <=> d_transaction.type AND r.transaction_date <=> d_transaction.date
LEFT JOIN dim_merchant d_merchant ON r.merchant_name <=> d_merchant.name AND r.merchant_category <=> d_merchant.category
LEFT JOIN dim_device d_device ON r.device_fingerprint <=> d_device.fingerprint
;
