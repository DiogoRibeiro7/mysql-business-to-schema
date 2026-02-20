-- ETL from raw denormalized table into normalized tables
USE fintech;

INSERT INTO dim_customer (email, name, type)
SELECT DISTINCT r.customer_email, r.customer_name, r.customer_type
FROM raw_transaction_feed r;

INSERT INTO dim_account (number, type)
SELECT DISTINCT r.account_number, r.account_type
FROM raw_transaction_feed r;

INSERT INTO dim_transaction (id, type, date)
SELECT DISTINCT r.transaction_id, r.transaction_type, r.transaction_date
FROM raw_transaction_feed r;

INSERT INTO dim_merchant (name, category)
SELECT DISTINCT r.merchant_name, r.merchant_category
FROM raw_transaction_feed r;

INSERT INTO dim_device (fingerprint)
SELECT DISTINCT r.device_fingerprint
FROM raw_transaction_feed r;

INSERT INTO fact_transaction_feed (customer_id, account_id, transaction_id, merchant_id, device_id, currency, amount, risk_score, kyc_status)
SELECT
    d_customer.customer_id,
    d_account.account_id,
    d_transaction.transaction_id,
    d_merchant.merchant_id,
    d_device.device_id,
    r.currency,
    r.amount,
    r.risk_score,
    r.kyc_status
FROM raw_transaction_feed r
LEFT JOIN dim_customer d_customer ON r.customer_email <=> d_customer.email AND r.customer_name <=> d_customer.name AND r.customer_type <=> d_customer.type
LEFT JOIN dim_account d_account ON r.account_number <=> d_account.number AND r.account_type <=> d_account.type
LEFT JOIN dim_transaction d_transaction ON r.transaction_id <=> d_transaction.id AND r.transaction_type <=> d_transaction.type AND r.transaction_date <=> d_transaction.date
LEFT JOIN dim_merchant d_merchant ON r.merchant_name <=> d_merchant.name AND r.merchant_category <=> d_merchant.category
LEFT JOIN dim_device d_device ON r.device_fingerprint <=> d_device.fingerprint
;
