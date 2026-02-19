-- ============================================================================
-- BASIC QUERIES FOR CRYPTOCURRENCY EXCHANGE
-- ============================================================================

USE cryptocurrency;

-- ============================================================================
-- USER QUERIES
-- ============================================================================

-- Get active users with KYC status
SELECT
    user_id,
    email,
    username,
    kyc_level,
    kyc_status,
    account_type,
    two_factor_enabled,
    created_at
FROM users
WHERE status = 'active'
ORDER BY created_at DESC
LIMIT 10;

-- Users pending KYC verification
SELECT
    user_id,
    email,
    CONCAT(first_name, ' ', last_name) as full_name,
    kyc_level,
    kyc_submitted_at,
    DATEDIFF(NOW(), kyc_submitted_at) as days_pending
FROM users
WHERE kyc_status = 'pending'
ORDER BY kyc_submitted_at ASC;

-- ============================================================================
-- CURRENCY QUERIES
-- ============================================================================

-- List all active cryptocurrencies
SELECT
    currency_id,
    symbol,
    name,
    currency_type,
    blockchain,
    decimals,
    market_cap_rank
FROM currencies
WHERE is_active = TRUE
    AND currency_type IN ('crypto', 'stablecoin')
ORDER BY market_cap_rank ASC;

-- Get deposit/withdrawal status for each currency
SELECT
    symbol,
    name,
    currency_type,
    can_deposit,
    can_withdraw,
    can_trade,
    min_withdrawal,
    withdrawal_fee,
    deposit_confirmations
FROM currencies
WHERE is_active = TRUE
ORDER BY currency_type, symbol;

-- ============================================================================
-- TRADING PAIR QUERIES
-- ============================================================================

-- List all active trading pairs with fees
SELECT
    pair_id,
    symbol,
    price_precision,
    quantity_precision,
    min_order_value,
    max_order_value,
    maker_fee_rate * 100 as maker_fee_percent,
    taker_fee_rate * 100 as taker_fee_percent
FROM trading_pairs
WHERE is_active = TRUE
ORDER BY symbol;

-- Get current prices and 24h statistics
SELECT
    symbol,
    last_price,
    price_change_24h,
    volume_24h,
    high_24h,
    low_24h,
    updated_at
FROM trading_pairs
WHERE is_active = TRUE
ORDER BY volume_24h DESC
LIMIT 10;

-- ============================================================================
-- WALLET QUERIES
-- ============================================================================

-- User wallet balances (sample user_id = 1)
SELECT
    w.wallet_id,
    c.symbol,
    c.name,
    w.available_balance,
    w.locked_balance,
    w.total_balance,
    w.available_balance * tp.last_price as value_usd
FROM wallets w
JOIN currencies c ON w.currency_id = c.currency_id
LEFT JOIN trading_pairs tp ON c.currency_id = tp.base_currency_id
    AND tp.quote_currency_id = 3 -- USDT
WHERE w.user_id = 1
    AND w.total_balance > 0
ORDER BY value_usd DESC;

-- Total platform holdings by currency
SELECT
    c.symbol,
    c.name,
    COUNT(DISTINCT w.user_id) as holder_count,
    SUM(w.total_balance) as total_holdings,
    AVG(w.total_balance) as avg_balance_per_holder
FROM wallets w
JOIN currencies c ON w.currency_id = c.currency_id
WHERE w.total_balance > 0
GROUP BY c.currency_id
ORDER BY holder_count DESC;

-- ============================================================================
-- ORDER QUERIES
-- ============================================================================

-- Recent orders (last 24 hours)
SELECT
    o.order_id,
    u.username,
    tp.symbol,
    o.order_type,
    o.side,
    o.price,
    o.quantity,
    o.filled_quantity,
    o.status,
    o.created_at
FROM orders o
JOIN users u ON o.user_id = u.user_id
JOIN trading_pairs tp ON o.pair_id = tp.pair_id
WHERE o.created_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
ORDER BY o.created_at DESC
LIMIT 20;

-- Open orders summary
SELECT
    tp.symbol,
    o.side,
    COUNT(*) as order_count,
    SUM(o.remaining_quantity) as total_quantity,
    AVG(o.price) as avg_price,
    MIN(o.price) as min_price,
    MAX(o.price) as max_price
FROM orders o
JOIN trading_pairs tp ON o.pair_id = tp.pair_id
WHERE o.status IN ('open', 'partially_filled')
GROUP BY tp.pair_id, o.side
ORDER BY tp.symbol, o.side;

-- ============================================================================
-- TRANSACTION QUERIES
-- ============================================================================

-- Recent deposits and withdrawals
SELECT
    t.transaction_id,
    u.username,
    c.symbol,
    t.type,
    t.amount,
    t.fee,
    t.status,
    t.blockchain_txid,
    t.confirmations,
    t.created_at
FROM transactions t
JOIN users u ON t.user_id = u.user_id
JOIN currencies c ON t.currency_id = c.currency_id
WHERE t.type IN ('deposit', 'withdrawal')
    AND t.created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
ORDER BY t.created_at DESC
LIMIT 20;

-- Pending withdrawals requiring review
SELECT
    t.transaction_id,
    u.email,
    c.symbol,
    t.amount,
    t.blockchain_address,
    t.risk_score,
    t.created_at
FROM transactions t
JOIN users u ON t.user_id = u.user_id
JOIN currencies c ON t.currency_id = c.currency_id
WHERE t.type = 'withdrawal'
    AND t.status = 'pending'
    AND (t.requires_manual_review = TRUE OR t.risk_score > 50)
ORDER BY t.risk_score DESC, t.created_at ASC;

-- ============================================================================
-- FEE TIER QUERIES
-- ============================================================================

-- Fee tier distribution
SELECT
    tier_name,
    min_volume,
    max_volume,
    maker_fee_rate * 100 as maker_fee_percent,
    taker_fee_rate * 100 as taker_fee_percent,
    withdrawal_fee_discount
FROM user_fee_tiers
ORDER BY min_volume;

-- ============================================================================
-- AUDIT QUERIES
-- ============================================================================

-- Recent critical events
SELECT
    audit_id,
    user_id,
    event_type,
    event_subtype,
    entity_type,
    entity_id,
    result,
    ip_address,
    created_at
FROM audit_logs
WHERE event_type IN ('withdrawal', 'login', 'api_key_created', 'kyc_update')
    AND created_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
ORDER BY created_at DESC
LIMIT 50;
