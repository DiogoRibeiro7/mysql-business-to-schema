-- ETL from raw denormalized table into normalized tables
USE cryptocurrency_exchange;

INSERT INTO dim_user (email)
SELECT DISTINCT r.user_email
FROM raw_exchange_feed r;

INSERT INTO dim_asset (symbol)
SELECT DISTINCT r.asset_symbol
FROM raw_exchange_feed r;

INSERT INTO dim_wallet (balance)
SELECT DISTINCT r.wallet_balance
FROM raw_exchange_feed r;

INSERT INTO dim_order (id, status, time)
SELECT DISTINCT r.order_id, r.order_status, r.order_time
FROM raw_exchange_feed r;

INSERT INTO dim_trade (price, qty)
SELECT DISTINCT r.trade_price, r.trade_qty
FROM raw_exchange_feed r;

INSERT INTO fact_exchange_feed (user_id, asset_id, wallet_id, order_id, trade_id, source_row_id)
SELECT
    d_user.user_id,
    d_asset.asset_id,
    d_wallet.wallet_id,
    d_order.order_id,
    d_trade.trade_id,
    r.row_id
FROM raw_exchange_feed r
LEFT JOIN dim_user d_user ON r.user_email <=> d_user.email
LEFT JOIN dim_asset d_asset ON r.asset_symbol <=> d_asset.symbol
LEFT JOIN dim_wallet d_wallet ON r.wallet_balance <=> d_wallet.balance
LEFT JOIN dim_order d_order ON r.order_id <=> d_order.id AND r.order_status <=> d_order.status AND r.order_time <=> d_order.time
LEFT JOIN dim_trade d_trade ON r.trade_price <=> d_trade.price AND r.trade_qty <=> d_trade.qty
;
