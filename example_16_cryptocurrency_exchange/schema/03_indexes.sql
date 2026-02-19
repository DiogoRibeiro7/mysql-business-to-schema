-- =====================================================
-- Cryptocurrency Exchange Indexes
-- =====================================================
-- Performance optimization indexes
-- =====================================================

USE cryptocurrency_exchange;

-- =====================================================
-- Composite Indexes for Common Queries
-- =====================================================

-- User authentication and lookup
CREATE INDEX idx_users_auth ON users(email, password_hash, status);
CREATE INDEX idx_users_login ON users(username, password_hash, status);

-- KYC verification queries
CREATE INDEX idx_kyc_pending ON kyc_documents(verification_status, submitted_at);

-- Wallet balance lookups
CREATE INDEX idx_wallet_user_balance ON wallets(user_id, available_balance);

-- Active orders by user
CREATE INDEX idx_orders_user_active ON orders(user_id, status, created_at);

-- Orders for matching engine
CREATE INDEX idx_orders_matching ON orders(pair_id, side, price, created_at);

-- Best bid/ask prices
CREATE INDEX idx_orders_best_bid ON orders(pair_id, price DESC);

CREATE INDEX idx_orders_best_ask ON orders(pair_id, price ASC);

-- Recent trades for price ticker
CREATE INDEX idx_trades_recent ON trades(pair_id, executed_at DESC);

-- User trade history
CREATE INDEX idx_trades_user_history ON trades(buyer_id, executed_at DESC);
CREATE INDEX idx_trades_seller_history ON trades(seller_id, executed_at DESC);

-- Transaction processing
CREATE INDEX idx_transactions_pending ON transactions(status, created_at);

-- Price history queries
CREATE INDEX idx_price_latest ON price_history(pair_id, timeframe, timestamp DESC);

-- Staking positions
CREATE INDEX idx_staking_active ON staking_positions(user_id, status, unlock_date);

-- API key lookups
CREATE INDEX idx_api_keys_lookup ON api_keys(api_key, is_active);

-- Session management
CREATE INDEX idx_sessions_cleanup ON user_sessions(expires_at, is_active);

-- Audit log queries
CREATE INDEX idx_audit_user_time ON audit_logs(user_id, created_at DESC);
CREATE INDEX idx_audit_entity ON audit_logs(entity_type, entity_id, created_at DESC);

-- Notification queries
CREATE INDEX idx_notifications_user ON notifications(user_id, is_read, created_at DESC);

-- Security event analysis
CREATE INDEX idx_security_ip ON security_events(ip_address, created_at DESC);
CREATE INDEX idx_security_user_type ON security_events(user_id, event_type, created_at DESC);

-- =====================================================
-- Full-Text Search Indexes
-- =====================================================

-- Search users by name or company
ALTER TABLE users ADD FULLTEXT idx_users_search (first_name, last_name, company_name, email);

-- Search currencies
ALTER TABLE currencies ADD FULLTEXT idx_currencies_search (symbol, name);

-- Search trading pairs
ALTER TABLE trading_pairs ADD FULLTEXT idx_pairs_search (symbol);

-- =====================================================
-- Spatial Indexes (if storing location data)
-- =====================================================

-- If we add geolocation features later
-- ALTER TABLE users ADD location POINT;
-- CREATE SPATIAL INDEX idx_users_location ON users(location);

-- =====================================================
-- Covering Indexes for Read-Heavy Queries
-- =====================================================

-- Order book query (returns all needed data from index)
CREATE INDEX idx_orderbook_covering ON orders(
    pair_id,
    side,
    status,
    price,
    quantity,
    user_id
);

-- Portfolio overview
CREATE INDEX idx_portfolio_covering ON wallets(
    user_id,
    currency_id,
    available_balance,
    locked_balance,
    staked_balance
);

-- Trade history export
CREATE INDEX idx_trade_export ON trades(
    executed_at,
    pair_id,
    price,
    quantity,
    buyer_id,
    seller_id,
    buyer_fee,
    seller_fee
);

-- =====================================================
-- Partial Indexes for Specific Conditions
-- =====================================================

-- High-value transactions
CREATE INDEX idx_transactions_high_value ON transactions(user_id, amount, created_at);

-- VIP users
CREATE INDEX idx_users_vip ON users(user_id, email, kyc_level);

-- Failed login attempts
CREATE INDEX idx_security_failed_logins ON security_events(user_id, created_at);

-- =====================================================
-- Hash Indexes for Exact Lookups (if using MEMORY engine)
-- =====================================================

-- For session tokens (if using MEMORY engine for sessions)
-- CREATE INDEX idx_session_token_hash USING HASH ON user_sessions(session_token);

-- =====================================================
-- Index Statistics Update
-- =====================================================

-- Update index statistics for better query planning
ANALYZE TABLE users;
ANALYZE TABLE orders;
ANALYZE TABLE trades;
ANALYZE TABLE wallets;
ANALYZE TABLE transactions;
ANALYZE TABLE price_history;

-- =====================================================
-- Index Maintenance Commands (for regular maintenance)
-- =====================================================

-- Check for unused indexes (run periodically)
-- SELECT * FROM sys.schema_unused_indexes;

-- Check for missing indexes (run periodically)
-- SELECT * FROM sys.statements_with_full_table_scans;

-- Optimize tables (run during maintenance windows)
-- OPTIMIZE TABLE orders;
-- OPTIMIZE TABLE trades;
-- OPTIMIZE TABLE price_history;
