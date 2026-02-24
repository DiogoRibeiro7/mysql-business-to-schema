-- ETL from raw denormalized table into normalized tables
USE ecommerce;

INSERT INTO dim_order (number, date, status, created_at, updated_at)
SELECT DISTINCT r.order_number, r.order_date, r.order_status, NOW(), NOW()
FROM raw_order_stream r;

INSERT INTO dim_customer (email, full_name, first_name, last_name, phone, created_at, updated_at)
SELECT DISTINCT r.customer_email, r.customer_name, SUBSTRING_INDEX(r.customer_name, ' ', 1), CASE WHEN INSTR(r.customer_name, ' ') > 0 THEN SUBSTRING(r.customer_name, INSTR(r.customer_name, ' ') + 1) ELSE '' END, r.customer_phone, NOW(), NOW()
FROM raw_order_stream r;

INSERT INTO dim_shipping (address_line_1, address_city, address_state, address_postal_code, address_country, created_at, updated_at)
SELECT DISTINCT r.shipping_address, NULL, NULL, NULL, NULL, NOW(), NOW()
FROM raw_order_stream r;

INSERT INTO dim_billing (address_line_1, address_city, address_state, address_postal_code, address_country, created_at, updated_at)
SELECT DISTINCT r.billing_address, NULL, NULL, NULL, NULL, NOW(), NOW()
FROM raw_order_stream r;

INSERT INTO dim_product (sku, name, category, brand, created_at, updated_at)
SELECT DISTINCT r.product_sku, r.product_name, r.product_category, r.product_brand, NOW(), NOW()
FROM raw_order_stream r;

INSERT INTO dim_payment (method, status, created_at, updated_at)
SELECT DISTINCT r.payment_method, r.payment_status, NOW(), NOW()
FROM raw_order_stream r;

INSERT INTO fact_order_stream (order_id, customer_id, shipping_id, billing_id, product_id, payment_id, source_row_id, unit_price, quantity, item_discount, created_at, updated_at)
SELECT
    d_order.order_id,
    d_customer.customer_id,
    d_shipping.shipping_id,
    d_billing.billing_id,
    d_product.product_id,
    d_payment.payment_id,
    r.row_id,
    r.unit_price,
    r.quantity,
    r.item_discount,
    NOW(),
    NOW()
FROM raw_order_stream r
LEFT JOIN dim_order d_order ON r.order_number <=> d_order.number AND r.order_date <=> d_order.date AND r.order_status <=> d_order.status
LEFT JOIN dim_customer d_customer ON r.customer_email <=> d_customer.email AND r.customer_name <=> d_customer.full_name AND SUBSTRING_INDEX(r.customer_name, ' ', 1) <=> d_customer.first_name AND CASE WHEN INSTR(r.customer_name, ' ') > 0 THEN SUBSTRING(r.customer_name, INSTR(r.customer_name, ' ') + 1) ELSE '' END <=> d_customer.last_name AND r.customer_phone <=> d_customer.phone
LEFT JOIN dim_shipping d_shipping ON r.shipping_address <=> d_shipping.address_line_1 AND d_shipping.address_city IS NULL AND d_shipping.address_state IS NULL AND d_shipping.address_postal_code IS NULL AND d_shipping.address_country IS NULL
LEFT JOIN dim_billing d_billing ON r.billing_address <=> d_billing.address_line_1 AND d_billing.address_city IS NULL AND d_billing.address_state IS NULL AND d_billing.address_postal_code IS NULL AND d_billing.address_country IS NULL
LEFT JOIN dim_product d_product ON r.product_sku <=> d_product.sku AND r.product_name <=> d_product.name AND r.product_category <=> d_product.category AND r.product_brand <=> d_product.brand
LEFT JOIN dim_payment d_payment ON r.payment_method <=> d_payment.method AND r.payment_status <=> d_payment.status
;
