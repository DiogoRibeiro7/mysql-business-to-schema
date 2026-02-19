-- ============================================================================
-- CONSTRAINTS FOR CRYPTOCURRENCY EXCHANGE
-- ============================================================================

USE cryptocurrency;

-- ============================================================================
-- ADDITIONAL FOREIGN KEY CONSTRAINTS
-- ============================================================================

-- Users table - self-referential constraint for referrals
ALTER TABLE users
    ADD CONSTRAINT fk_users_referred_by
    FOREIGN KEY (referred_by_user_id) REFERENCES users(user_id);

-- KYC Documents - verified by admin user
ALTER TABLE kyc_documents
    ADD CONSTRAINT fk_kyc_verified_by
    FOREIGN KEY (verified_by_user_id) REFERENCES users(user_id);

-- Transactions - reviewed by admin user
ALTER TABLE transactions
    ADD CONSTRAINT fk_transactions_reviewed_by
    FOREIGN KEY (reviewed_by_user_id) REFERENCES users(user_id);

-- ============================================================================
-- CHECK CONSTRAINTS
-- ============================================================================

-- Users table
ALTER TABLE users
    ADD CONSTRAINT chk_users_withdrawal_limit
    CHECK (daily_withdrawal_limit >= 0),
    ADD CONSTRAINT chk_users_trading_limit
    CHECK (daily_trading_limit >= 0),
    ADD CONSTRAINT chk_users_aml_score
    CHECK (aml_risk_score IS NULL OR (aml_risk_score >= 0 AND aml_risk_score <= 100)),
    ADD CONSTRAINT chk_users_failed_attempts
    CHECK (failed_login_attempts >= 0);

-- Currencies table
ALTER TABLE currencies
    ADD CONSTRAINT chk_currencies_decimals
    CHECK (decimals >= 0 AND decimals <= 18),
    ADD CONSTRAINT chk_currencies_confirmations
    CHECK (deposit_confirmations >= 0),
    ADD CONSTRAINT chk_currencies_min_amounts
    CHECK (min_deposit >= 0 AND min_withdrawal >= 0 AND withdrawal_fee >= 0);

-- Trading pairs table
ALTER TABLE trading_pairs
    ADD CONSTRAINT chk_pairs_precision
    CHECK (price_precision >= 0 AND price_precision <= 18 AND
           quantity_precision >= 0 AND quantity_precision <= 18),
    ADD CONSTRAINT chk_pairs_order_limits
    CHECK (min_order_value >= 0 AND min_order_value <= max_order_value),
    ADD CONSTRAINT chk_pairs_quantity_limits
    CHECK (min_quantity >= 0 AND min_quantity <= max_quantity),
    ADD CONSTRAINT chk_pairs_fees
    CHECK (maker_fee_rate >= 0 AND taker_fee_rate >= 0),
    ADD CONSTRAINT chk_pairs_different_currencies
    CHECK (base_currency_id != quote_currency_id);

-- Wallets table
ALTER TABLE wallets
    ADD CONSTRAINT chk_wallets_balances
    CHECK (available_balance >= 0 AND locked_balance >= 0),
    ADD CONSTRAINT chk_wallets_totals
    CHECK (total_deposited >= 0 AND total_withdrawn >= 0);

-- Orders table
ALTER TABLE orders
    ADD CONSTRAINT chk_orders_quantity
    CHECK (quantity > 0),
    ADD CONSTRAINT chk_orders_filled
    CHECK (filled_quantity >= 0 AND filled_quantity <= quantity),
    ADD CONSTRAINT chk_orders_executed_value
    CHECK (executed_value >= 0),
    ADD CONSTRAINT chk_orders_fee
    CHECK (fee_amount >= 0),
    ADD CONSTRAINT chk_orders_price
    CHECK ((order_type IN ('limit', 'stop_limit') AND price > 0) OR
           (order_type IN ('market', 'stop_market') AND price IS NULL)),
    ADD CONSTRAINT chk_orders_stop_price
    CHECK ((order_type IN ('stop_limit', 'stop_market') AND stop_price > 0) OR
           (order_type IN ('limit', 'market') AND stop_price IS NULL));

-- Trades table
ALTER TABLE trades
    ADD CONSTRAINT chk_trades_amounts
    CHECK (price > 0 AND quantity > 0),
    ADD CONSTRAINT chk_trades_fees
    CHECK (maker_fee >= 0 AND taker_fee >= 0),
    ADD CONSTRAINT chk_trades_different_users
    CHECK (maker_user_id != taker_user_id);

-- Transactions table
ALTER TABLE transactions
    ADD CONSTRAINT chk_transactions_amount
    CHECK (amount > 0),
    ADD CONSTRAINT chk_transactions_fee
    CHECK (fee >= 0),
    ADD CONSTRAINT chk_transactions_confirmations
    CHECK (confirmations >= 0),
    ADD CONSTRAINT chk_transactions_risk_score
    CHECK (risk_score IS NULL OR (risk_score >= 0 AND risk_score <= 100));

-- Price history table
ALTER TABLE price_history
    ADD CONSTRAINT chk_price_history_prices
    CHECK (open_price > 0 AND high_price > 0 AND low_price > 0 AND close_price > 0),
    ADD CONSTRAINT chk_price_history_high_low
    CHECK (high_price >= low_price),
    ADD CONSTRAINT chk_price_history_high_prices
    CHECK (high_price >= open_price AND high_price >= close_price),
    ADD CONSTRAINT chk_price_history_low_prices
    CHECK (low_price <= open_price AND low_price <= close_price),
    ADD CONSTRAINT chk_price_history_volume
    CHECK (volume >= 0 AND quote_volume >= 0),
    ADD CONSTRAINT chk_price_history_time
    CHECK (close_time > open_time);

-- User fee tiers table
ALTER TABLE user_fee_tiers
    ADD CONSTRAINT chk_fee_tiers_volume
    CHECK (min_volume >= 0 AND (max_volume IS NULL OR max_volume > min_volume)),
    ADD CONSTRAINT chk_fee_tiers_rates
    CHECK (maker_fee_rate >= 0 AND taker_fee_rate >= 0),
    ADD CONSTRAINT chk_fee_tiers_discount
    CHECK (withdrawal_fee_discount >= 0 AND withdrawal_fee_discount <= 100);

-- User trading volumes table
ALTER TABLE user_trading_volumes
    ADD CONSTRAINT chk_trading_volumes
    CHECK (volume_30d >= 0 AND volume_7d >= 0 AND volume_24h >= 0);

-- ============================================================================
-- UNIQUE CONSTRAINTS
-- ============================================================================

-- Ensure one active session per device
ALTER TABLE user_sessions
    ADD CONSTRAINT uk_active_device_session
    UNIQUE KEY (user_id, device_id, is_active);

-- ============================================================================
-- DEFAULT VALUES FOR COMMON FIELDS
-- ============================================================================

-- Set default values for fee currencies to USDT (will be ID 3 after seeding)
ALTER TABLE orders
    ALTER COLUMN fee_currency_id SET DEFAULT 3;

ALTER TABLE trades
    ALTER COLUMN fee_currency_id SET DEFAULT 3;

-- ============================================================================
-- TRIGGERS FOR DATA INTEGRITY
-- ============================================================================

DELIMITER //

-- Trigger to update wallet balance on order creation
CREATE TRIGGER trg_order_create_lock_balance
AFTER INSERT ON orders
FOR EACH ROW
BEGIN
    DECLARE v_currency_id INT;

    -- Determine which currency to lock based on order side
    IF NEW.side = 'buy' THEN
        SELECT quote_currency_id INTO v_currency_id
        FROM trading_pairs WHERE pair_id = NEW.pair_id;
    ELSE
        SELECT base_currency_id INTO v_currency_id
        FROM trading_pairs WHERE pair_id = NEW.pair_id;
    END IF;

    -- Update wallet balances (lock funds)
    IF NEW.status IN ('open', 'pending') THEN
        UPDATE wallets
        SET available_balance = available_balance - (NEW.quantity * IFNULL(NEW.price, 0)),
            locked_balance = locked_balance + (NEW.quantity * IFNULL(NEW.price, 0))
        WHERE user_id = NEW.user_id AND currency_id = v_currency_id;
    END IF;
END//

-- Trigger to update wallet balance on order cancellation
CREATE TRIGGER trg_order_cancel_unlock_balance
AFTER UPDATE ON orders
FOR EACH ROW
BEGIN
    DECLARE v_currency_id INT;
    DECLARE v_amount_to_unlock DECIMAL(30,18);

    -- Only process if order is being cancelled
    IF OLD.status IN ('open', 'pending', 'partially_filled') AND NEW.status = 'cancelled' THEN
        -- Determine which currency to unlock based on order side
        IF NEW.side = 'buy' THEN
            SELECT quote_currency_id INTO v_currency_id
            FROM trading_pairs WHERE pair_id = NEW.pair_id;
        ELSE
            SELECT base_currency_id INTO v_currency_id
            FROM trading_pairs WHERE pair_id = NEW.pair_id;
        END IF;

        -- Calculate amount to unlock (remaining unfilled portion)
        SET v_amount_to_unlock = NEW.remaining_quantity * IFNULL(NEW.price, 0);

        -- Update wallet balances (unlock funds)
        UPDATE wallets
        SET available_balance = available_balance + v_amount_to_unlock,
            locked_balance = locked_balance - v_amount_to_unlock
        WHERE user_id = NEW.user_id AND currency_id = v_currency_id;
    END IF;
END//

-- Trigger to update trading pair statistics after trade
CREATE TRIGGER trg_trade_update_pair_stats
AFTER INSERT ON trades
FOR EACH ROW
BEGIN
    UPDATE trading_pairs
    SET last_price = NEW.price,
        volume_24h = (
            SELECT COALESCE(SUM(quantity), 0)
            FROM trades
            WHERE pair_id = NEW.pair_id
              AND executed_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
        ),
        updated_at = CURRENT_TIMESTAMP
    WHERE pair_id = NEW.pair_id;
END//

-- Trigger to update user trading volume after trade
CREATE TRIGGER trg_trade_update_user_volume
AFTER INSERT ON trades
FOR EACH ROW
BEGIN
    -- Update maker's volume
    INSERT INTO user_trading_volumes (user_id, volume_24h, volume_7d, volume_30d)
    VALUES (NEW.maker_user_id, NEW.value, NEW.value, NEW.value)
    ON DUPLICATE KEY UPDATE
        volume_24h = (
            SELECT COALESCE(SUM(t.value), 0)
            FROM trades t
            WHERE (t.maker_user_id = NEW.maker_user_id OR t.taker_user_id = NEW.maker_user_id)
              AND t.executed_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
        ),
        volume_7d = (
            SELECT COALESCE(SUM(t.value), 0)
            FROM trades t
            WHERE (t.maker_user_id = NEW.maker_user_id OR t.taker_user_id = NEW.maker_user_id)
              AND t.executed_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
        ),
        volume_30d = (
            SELECT COALESCE(SUM(t.value), 0)
            FROM trades t
            WHERE (t.maker_user_id = NEW.maker_user_id OR t.taker_user_id = NEW.maker_user_id)
              AND t.executed_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
        );

    -- Update taker's volume
    INSERT INTO user_trading_volumes (user_id, volume_24h, volume_7d, volume_30d)
    VALUES (NEW.taker_user_id, NEW.value, NEW.value, NEW.value)
    ON DUPLICATE KEY UPDATE
        volume_24h = (
            SELECT COALESCE(SUM(t.value), 0)
            FROM trades t
            WHERE (t.maker_user_id = NEW.taker_user_id OR t.taker_user_id = NEW.taker_user_id)
              AND t.executed_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
        ),
        volume_7d = (
            SELECT COALESCE(SUM(t.value), 0)
            FROM trades t
            WHERE (t.maker_user_id = NEW.taker_user_id OR t.taker_user_id = NEW.taker_user_id)
              AND t.executed_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
        ),
        volume_30d = (
            SELECT COALESCE(SUM(t.value), 0)
            FROM trades t
            WHERE (t.maker_user_id = NEW.taker_user_id OR t.taker_user_id = NEW.taker_user_id)
              AND t.executed_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
        );
END//

-- Trigger to create audit log entry for critical operations
CREATE TRIGGER trg_order_audit_log
AFTER INSERT ON orders
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, event_type, event_subtype, entity_type, entity_id, new_values, ip_address)
    VALUES (NEW.user_id, 'order', NEW.order_type, 'order', NEW.order_id,
            JSON_OBJECT('side', NEW.side, 'quantity', NEW.quantity, 'price', NEW.price),
            NEW.ip_address);
END//

CREATE TRIGGER trg_transaction_audit_log
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, event_type, event_subtype, entity_type, entity_id, new_values)
    VALUES (NEW.user_id, 'transaction', NEW.type, 'transaction', NEW.transaction_id,
            JSON_OBJECT('amount', NEW.amount, 'currency_id', NEW.currency_id, 'status', NEW.status));
END//

DELIMITER ;

-- ============================================================================
-- EVENTS FOR AUTOMATED TASKS
-- ============================================================================

DELIMITER //

-- Event to expire old orders with GTD (Good Till Date) time in force
CREATE EVENT IF NOT EXISTS evt_expire_gtd_orders
ON SCHEDULE EVERY 1 MINUTE
DO
BEGIN
    UPDATE orders
    SET status = 'expired',
        updated_at = CURRENT_TIMESTAMP
    WHERE status IN ('open', 'partially_filled')
      AND time_in_force = 'GTD'
      AND expire_time <= CURRENT_TIMESTAMP;
END//

-- Event to clean up expired sessions
CREATE EVENT IF NOT EXISTS evt_cleanup_expired_sessions
ON SCHEDULE EVERY 1 HOUR
DO
BEGIN
    UPDATE user_sessions
    SET is_active = FALSE
    WHERE is_active = TRUE
      AND expires_at <= CURRENT_TIMESTAMP;
END//

-- Event to unlock locked accounts after timeout
CREATE EVENT IF NOT EXISTS evt_unlock_user_accounts
ON SCHEDULE EVERY 5 MINUTE
DO
BEGIN
    UPDATE users
    SET failed_login_attempts = 0,
        locked_until = NULL
    WHERE locked_until IS NOT NULL
      AND locked_until <= CURRENT_TIMESTAMP;
END//

DELIMITER ;
