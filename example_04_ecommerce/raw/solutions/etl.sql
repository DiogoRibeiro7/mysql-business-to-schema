-- ETL from raw denormalized table into normalized tables
USE ecommerce;

INSERT INTO dim_order (number, date, status)
SELECT DISTINCT r.order_number, r.order_date, r.order_status
FROM raw_order_stream r;

INSERT INTO dim_customer (email, name, phone)
SELECT DISTINCT r.customer_email, r.customer_name, r.customer_phone
FROM raw_order_stream r;

INSERT INTO dim_shipping (address)
SELECT DISTINCT r.shipping_address
FROM raw_order_stream r;

INSERT INTO dim_billing (address)
SELECT DISTINCT r.billing_address
FROM raw_order_stream r;

INSERT INTO dim_product (sku, name, category, brand)
SELECT DISTINCT r.product_sku, r.product_name, r.product_category, r.product_brand
FROM raw_order_stream r;

INSERT INTO dim_payment (method, status)
SELECT DISTINCT r.payment_method, r.payment_status
FROM raw_order_stream r;

INSERT INTO fact_order_stream (order_id, customer_id, shipping_id, billing_id, product_id, payment_id, source_row_id, unit_price, quantity, item_discount)
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
    r.item_discount
FROM raw_order_stream r
LEFT JOIN dim_order d_order ON r.order_number <=> d_order.number AND r.order_date <=> d_order.date AND r.order_status <=> d_order.status
LEFT JOIN dim_customer d_customer ON r.customer_email <=> d_customer.email AND r.customer_name <=> d_customer.name AND r.customer_phone <=> d_customer.phone
LEFT JOIN dim_shipping d_shipping ON r.shipping_address <=> d_shipping.address
LEFT JOIN dim_billing d_billing ON r.billing_address <=> d_billing.address
LEFT JOIN dim_product d_product ON r.product_sku <=> d_product.sku AND r.product_name <=> d_product.name AND r.product_category <=> d_product.category AND r.product_brand <=> d_product.brand
LEFT JOIN dim_payment d_payment ON r.payment_method <=> d_payment.method AND r.payment_status <=> d_payment.status
;
