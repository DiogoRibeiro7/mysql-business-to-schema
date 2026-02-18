-- ============================================================================
-- ANALYTICS QUERIES FOR CRYPTOCURRENCY EXCHANGE
-- ============================================================================

USE crypto_exchange;

-- ============================================================================
-- TRADING ANALYTICS
-- ============================================================================

-- Order book depth analysis for BTC/USDT
WITH order_book AS (
    SELECT
        'BID' as side,
        price,
        SUM(remaining_quantity) as total_quantity,
        COUNT(*) as order_count,
        SUM(remaining_quantity * price) as total_value
    FROM orders
    WHERE pair_id = 1  -- BTC/USDT
        AND status IN ('open', 'partially_filled')
        AND side = 'buy'
    GROUP BY price

    UNION ALL

    SELECT
        'ASK' as side,
        price,
        SUM(remaining_quantity) as total_quantity,
        COUNT(*) as order_count,
        SUM(remaining_quantity * price) as total_value
    FROM orders
    WHERE pair_id = 1  -- BTC/USDT
        AND status IN ('open', 'partially_filled')
        AND side = 'sell'
    GROUP BY price
)
SELECT
    side,
    price,
    total_quantity,
    order_count,
    total_value,
    SUM(total_value) OVER (PARTITION BY side ORDER BY
        CASE WHEN side = 'BID' THEN price END DESC,
        CASE WHEN side = 'ASK' THEN price END ASC
    ) as cumulative_value
FROM order_book
ORDER BY
    side DESC,
    CASE WHEN side = 'BID' THEN price END DESC,
    CASE WHEN side = 'ASK' THEN price END ASC
LIMIT 40;

-- Market maker vs taker volume analysis
SELECT
    DATE(t.executed_at) as trade_date,
    tp.symbol,
    COUNT(*) as trade_count,
    SUM(t.quantity) as total_volume,
    SUM(t.value) as total_value_usd,
    SUM(t.maker_fee) as total_maker_fees,
    SUM(t.taker_fee) as total_taker_fees,
    AVG(t.price) as avg_price,
    MIN(t.price) as min_price,
    MAX(t.price) as max_price
FROM trades t
JOIN trading_pairs tp ON t.pair_id = tp.pair_id
WHERE t.executed_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY DATE(t.executed_at), tp.pair_id
ORDER BY trade_date DESC, total_value_usd DESC;

-- User trading behavior analysis
SELECT
    u.account_type,
    COUNT(DISTINCT o.user_id) as active_traders,
    COUNT(o.order_id) as total_orders,
    SUM(CASE WHEN o.order_type = 'market' THEN 1 ELSE 0 END) as market_orders,
    SUM(CASE WHEN o.order_type = 'limit' THEN 1 ELSE 0 END) as limit_orders,
    AVG(o.quantity * o.price) as avg_order_value,
    SUM(o.fee_amount) as total_fees_paid
FROM orders o
JOIN users u ON o.user_id = u.user_id
WHERE o.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY u.account_type;

-- ============================================================================
-- LIQUIDITY ANALYTICS
-- ============================================================================

-- Spread analysis by trading pair
SELECT
    tp.symbol,
    tp.last_price,
    MIN(CASE WHEN o.side = 'sell' THEN o.price END) as best_ask,
    MAX(CASE WHEN o.side = 'buy' THEN o.price END) as best_bid,
    MIN(CASE WHEN o.side = 'sell' THEN o.price END) -
    MAX(CASE WHEN o.side = 'buy' THEN o.price END) as spread,
    (MIN(CASE WHEN o.side = 'sell' THEN o.price END) -
     MAX(CASE WHEN o.side = 'buy' THEN o.price END)) / tp.last_price * 100 as spread_percentage
FROM trading_pairs tp
LEFT JOIN orders o ON tp.pair_id = o.pair_id
    AND o.status IN ('open', 'partially_filled')
WHERE tp.is_active = TRUE
GROUP BY tp.pair_id
HAVING best_ask IS NOT NULL AND best_bid IS NOT NULL
ORDER BY spread_percentage ASC;

-- Order book imbalance indicator
SELECT
    tp.symbol,
    SUM(CASE WHEN o.side = 'buy' THEN o.remaining_quantity * o.price ELSE 0 END) as bid_volume,
    SUM(CASE WHEN o.side = 'sell' THEN o.remaining_quantity * o.price ELSE 0 END) as ask_volume,
    (SUM(CASE WHEN o.side = 'buy' THEN o.remaining_quantity * o.price ELSE 0 END) -
     SUM(CASE WHEN o.side = 'sell' THEN o.remaining_quantity * o.price ELSE 0 END)) /
    (SUM(CASE WHEN o.side = 'buy' THEN o.remaining_quantity * o.price ELSE 0 END) +
     SUM(CASE WHEN o.side = 'sell' THEN o.remaining_quantity * o.price ELSE 0 END)) * 100 as imbalance_ratio
FROM orders o
JOIN trading_pairs tp ON o.pair_id = tp.pair_id
WHERE o.status IN ('open', 'partially_filled')
GROUP BY tp.pair_id
ORDER BY ABS(imbalance_ratio) DESC;

-- ============================================================================
-- REVENUE ANALYTICS
-- ============================================================================

-- Daily revenue from trading fees
SELECT
    DATE(t.executed_at) as revenue_date,
    c.symbol as fee_currency,
    SUM(t.maker_fee + t.taker_fee) as total_fees,
    COUNT(DISTINCT t.maker_user_id) + COUNT(DISTINCT t.taker_user_id) as unique_traders,
    COUNT(t.trade_id) as total_trades
FROM trades t
JOIN currencies c ON t.fee_currency_id = c.currency_id
WHERE t.executed_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY DATE(t.executed_at), c.currency_id
ORDER BY revenue_date DESC, total_fees DESC;

-- Fee tier effectiveness
SELECT
    ft.tier_name,
    COUNT(DISTINCT utv.user_id) as users_in_tier,
    AVG(utv.volume_30d) as avg_30d_volume,
    ft.maker_fee_rate * 100 as maker_fee_percent,
    ft.taker_fee_rate * 100 as taker_fee_percent
FROM user_fee_tiers ft
LEFT JOIN user_trading_volumes utv ON ft.tier_id = utv.fee_tier_id
GROUP BY ft.tier_id
ORDER BY ft.min_volume;

-- Withdrawal fee revenue
SELECT
    c.symbol,
    COUNT(t.transaction_id) as withdrawal_count,
    SUM(t.amount) as total_withdrawn,
    SUM(t.fee) as total_fees_collected,
    AVG(t.fee) as avg_fee,
    SUM(t.fee) / SUM(t.amount) * 100 as effective_fee_rate
FROM transactions t
JOIN currencies c ON t.currency_id = c.currency_id
WHERE t.type = 'withdrawal'
    AND t.status = 'completed'
    AND t.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY c.currency_id
ORDER BY total_fees_collected DESC;

-- ============================================================================
-- USER ANALYTICS
-- ============================================================================

-- User acquisition and retention
SELECT
    DATE(created_at) as signup_date,
    COUNT(user_id) as new_users,
    SUM(CASE WHEN kyc_status = 'approved' THEN 1 ELSE 0 END) as kyc_approved,
    SUM(CASE WHEN two_factor_enabled = TRUE THEN 1 ELSE 0 END) as with_2fa,
    SUM(CASE WHEN last_login_at >= DATE_SUB(NOW(), INTERVAL 7 DAY) THEN 1 ELSE 0 END) as active_last_7d
FROM users
WHERE created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY DATE(created_at)
ORDER BY signup_date DESC;

-- User segmentation by trading volume
WITH user_volumes AS (
    SELECT
        u.user_id,
        u.account_type,
        u.kyc_level,
        COALESCE(utv.volume_30d, 0) as volume_30d,
        CASE
            WHEN COALESCE(utv.volume_30d, 0) = 0 THEN 'Inactive'
            WHEN utv.volume_30d < 1000 THEN 'Small Trader'
            WHEN utv.volume_30d < 10000 THEN 'Medium Trader'
            WHEN utv.volume_30d < 100000 THEN 'Large Trader'
            ELSE 'VIP Trader'
        END as trader_segment
    FROM users u
    LEFT JOIN user_trading_volumes utv ON u.user_id = utv.user_id
    WHERE u.status = 'active'
)
SELECT
    trader_segment,
    COUNT(user_id) as user_count,
    AVG(volume_30d) as avg_30d_volume,
    SUM(volume_30d) as total_30d_volume
FROM user_volumes
GROUP BY trader_segment
ORDER BY avg_30d_volume DESC;

-- ============================================================================
-- RISK & COMPLIANCE ANALYTICS
-- ============================================================================

-- High-risk transaction monitoring
SELECT
    DATE(t.created_at) as date,
    COUNT(CASE WHEN t.risk_score > 70 THEN 1 END) as high_risk_count,
    COUNT(CASE WHEN t.requires_manual_review = TRUE THEN 1 END) as manual_review_count,
    COUNT(CASE WHEN t.status = 'failed' THEN 1 END) as failed_count,
    SUM(CASE WHEN t.risk_score > 70 THEN t.amount ELSE 0 END) as high_risk_volume
FROM transactions t
WHERE t.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
    AND t.type IN ('withdrawal', 'deposit')
GROUP BY DATE(t.created_at)
ORDER BY date DESC;

-- KYC funnel analysis
SELECT
    'Total Users' as stage,
    COUNT(*) as user_count
FROM users

UNION ALL

SELECT
    'KYC Submitted' as stage,
    COUNT(*) as user_count
FROM users
WHERE kyc_status != 'pending' OR kyc_submitted_at IS NOT NULL

UNION ALL

SELECT
    'KYC Approved' as stage,
    COUNT(*) as user_count
FROM users
WHERE kyc_status = 'approved'

UNION ALL

SELECT
    'Advanced KYC' as stage,
    COUNT(*) as user_count
FROM users
WHERE kyc_level IN ('intermediate', 'advanced');

-- Suspicious activity patterns
SELECT
    u.user_id,
    u.email,
    COUNT(DISTINCT o.ip_address) as unique_ips,
    COUNT(o.order_id) as total_orders,
    COUNT(CASE WHEN o.status = 'cancelled' THEN 1 END) as cancelled_orders,
    COUNT(CASE WHEN o.status = 'cancelled' THEN 1 END) * 100.0 / COUNT(o.order_id) as cancel_rate,
    MAX(o.created_at) as last_order_time
FROM users u
JOIN orders o ON u.user_id = o.user_id
WHERE o.created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY u.user_id
HAVING cancelled_orders > 10 OR cancel_rate > 80
ORDER BY cancel_rate DESC;

-- ============================================================================
-- PERFORMANCE METRICS
-- ============================================================================

-- Average order execution time
SELECT
    tp.symbol,
    o.order_type,
    AVG(TIMESTAMPDIFF(SECOND, o.created_at, o.updated_at)) as avg_execution_seconds,
    COUNT(o.order_id) as order_count
FROM orders o
JOIN trading_pairs tp ON o.pair_id = tp.pair_id
WHERE o.status = 'filled'
    AND o.created_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
GROUP BY tp.pair_id, o.order_type
ORDER BY tp.symbol, o.order_type;

-- API usage statistics
SELECT
    DATE(ak.last_used_at) as usage_date,
    COUNT(DISTINCT ak.user_id) as active_api_users,
    COUNT(DISTINCT ak.api_key_id) as active_keys,
    SUM(CASE WHEN ak.can_trade = TRUE THEN 1 ELSE 0 END) as trading_keys,
    SUM(CASE WHEN ak.can_withdraw = TRUE THEN 1 ELSE 0 END) as withdrawal_keys
FROM api_keys ak
WHERE ak.is_active = TRUE
    AND ak.last_used_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY DATE(ak.last_used_at)
ORDER BY usage_date DESC;