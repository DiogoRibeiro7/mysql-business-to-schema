-- ============================================================================
-- INDEXES FOR CRYPTOCURRENCY EXCHANGE
-- ============================================================================

USE crypto_exchange;

-- ============================================================================
-- PERFORMANCE INDEXES
-- ============================================================================

-- Users table - optimize for login and KYC queries
CREATE INDEX idx_users_email_status ON users(email, status);
CREATE INDEX idx_users_kyc_level_status ON users(kyc_level, kyc_status);
CREATE INDEX idx_users_last_login ON users(last_login_at DESC);
CREATE INDEX idx_users_created_at ON users(created_at DESC);

-- Wallets table - optimize for balance lookups
CREATE INDEX idx_wallets_user_available ON wallets(user_id, available_balance);
CREATE INDEX idx_wallets_user_total ON wallets(user_id, total_balance);

-- Orders table - optimize for order book and matching
CREATE INDEX idx_orders_pair_status_side ON orders(pair_id, status, side);
CREATE INDEX idx_orders_pair_open_buy ON orders(pair_id, status, side, price DESC)
    WHERE status = 'open' AND side = 'buy';
CREATE INDEX idx_orders_pair_open_sell ON orders(pair_id, status, side, price ASC)
    WHERE status = 'open' AND side = 'sell';
CREATE INDEX idx_orders_user_recent ON orders(user_id, created_at DESC);
CREATE INDEX idx_orders_filled_quantity ON orders(filled_quantity)
    WHERE status IN ('open', 'partially_filled');

-- Trades table - optimize for history and analytics
CREATE INDEX idx_trades_pair_time ON trades(pair_id, executed_at DESC);
CREATE INDEX idx_trades_user_maker_time ON trades(maker_user_id, executed_at DESC);
CREATE INDEX idx_trades_user_taker_time ON trades(taker_user_id, executed_at DESC);
CREATE INDEX idx_trades_price_volume ON trades(pair_id, price, quantity);

-- Transactions table - optimize for user history and admin monitoring
CREATE INDEX idx_transactions_user_type_status ON transactions(user_id, type, status);
CREATE INDEX idx_transactions_status_review ON transactions(status, requires_manual_review)
    WHERE requires_manual_review = TRUE;
CREATE INDEX idx_transactions_blockchain ON transactions(blockchain_txid, status)
    WHERE blockchain_txid IS NOT NULL;
CREATE INDEX idx_transactions_recent ON transactions(created_at DESC);

-- Price history table - optimize for chart queries
CREATE INDEX idx_price_history_pair_interval ON price_history(pair_id, interval_type, open_time DESC);
CREATE INDEX idx_price_history_volume ON price_history(pair_id, volume DESC);

-- Audit logs table - optimize for compliance queries
CREATE INDEX idx_audit_logs_user_time ON audit_logs(user_id, created_at DESC);
CREATE INDEX idx_audit_logs_type_time ON audit_logs(event_type, created_at DESC);
CREATE INDEX idx_audit_logs_entity_lookup ON audit_logs(entity_type, entity_id, created_at DESC);

-- API keys table - optimize for authentication
CREATE INDEX idx_api_keys_user_active ON api_keys(user_id, is_active);
CREATE INDEX idx_api_keys_last_used ON api_keys(last_used_at DESC);

-- User sessions table - optimize for session management
CREATE INDEX idx_sessions_user_active ON user_sessions(user_id, is_active, last_activity_at DESC);
CREATE INDEX idx_sessions_token_lookup ON user_sessions(session_token, is_active);

-- ============================================================================
-- FULL-TEXT INDEXES
-- ============================================================================

-- Full-text search on currencies
ALTER TABLE currencies ADD FULLTEXT ft_currencies_search (symbol, name);

-- Full-text search on trading pairs
ALTER TABLE trading_pairs ADD FULLTEXT ft_pairs_search (symbol);

-- Full-text search on audit logs
ALTER TABLE audit_logs ADD FULLTEXT ft_audit_search (event_type, event_subtype, error_message);

-- ============================================================================
-- COMPOSITE INDEXES FOR COMPLEX QUERIES
-- ============================================================================

-- Order book depth query optimization
CREATE INDEX idx_orderbook_depth ON orders(pair_id, side, status, price, quantity)
    WHERE status IN ('open', 'partially_filled');

-- User portfolio value calculation
CREATE INDEX idx_portfolio_value ON wallets(user_id, currency_id, total_balance)
    WHERE total_balance > 0;

-- 24h volume calculation per pair
CREATE INDEX idx_24h_volume ON trades(pair_id, executed_at, quantity, value)
    WHERE executed_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR);

-- User transaction history with pagination
CREATE INDEX idx_user_tx_history ON transactions(user_id, status, created_at DESC, transaction_id);

-- KYC document verification queue
CREATE INDEX idx_kyc_queue ON kyc_documents(verification_status, uploaded_at)
    WHERE verification_status = 'pending';

-- High-value transaction monitoring
CREATE INDEX idx_high_value_tx ON transactions(amount, status, created_at)
    WHERE amount > 10000 AND status = 'pending';

-- ============================================================================
-- STATISTICS UPDATE
-- ============================================================================

-- Update table statistics for query optimizer
ANALYZE TABLE users;
ANALYZE TABLE wallets;
ANALYZE TABLE orders;
ANALYZE TABLE trades;
ANALYZE TABLE transactions;
ANALYZE TABLE price_history;
ANALYZE TABLE currencies;
ANALYZE TABLE trading_pairs;
ANALYZE TABLE audit_logs;

-- ============================================================================
-- INDEX HINTS FOR COMMON QUERIES
-- ============================================================================

/*
Common Query Patterns and Their Indexes:

1. Get order book for a trading pair:
   Uses: idx_orders_pair_open_buy, idx_orders_pair_open_sell

2. Get user's open orders:
   Uses: idx_orders_user_status

3. Get recent trades for a pair:
   Uses: idx_trades_pair_time

4. Calculate 24h volume:
   Uses: idx_24h_volume or idx_trades_pair_time

5. Get user's transaction history:
   Uses: idx_user_tx_history

6. Find pending KYC documents:
   Uses: idx_kyc_queue

7. Monitor high-value transactions:
   Uses: idx_high_value_tx

8. Authenticate API request:
   Uses: uk_api_key (unique index on api_key)

9. Get user's portfolio:
   Uses: idx_portfolio_value

10. Search for trading pairs:
    Uses: ft_pairs_search (full-text index)
*/