-- ETL from raw denormalized table into normalized tables
USE cryptocurrency;

INSERT INTO dim_trade (time)
SELECT DISTINCT r.trade_time
FROM raw_trade_feed r;

INSERT INTO dim_order (type)
SELECT DISTINCT r.order_type
FROM raw_trade_feed r;

INSERT INTO fact_trade_feed (trade_id, order_id, source_row_id, pair_symbol, side, price, quantity, trader_email, fee_amount)
SELECT
    d_trade.trade_id,
    d_order.order_id,
    r.row_id,
    r.pair_symbol,
    r.side,
    r.price,
    r.quantity,
    r.trader_email,
    r.fee_amount
FROM raw_trade_feed r
LEFT JOIN dim_trade d_trade ON r.trade_time <=> d_trade.time
LEFT JOIN dim_order d_order ON r.order_type <=> d_order.type
;
