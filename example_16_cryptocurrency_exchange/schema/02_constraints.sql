-- =====================================================
-- Cryptocurrency Exchange Constraints
-- =====================================================
-- Additional constraints and business rules
-- =====================================================

USE cryptocurrency_exchange;

-- =====================================================
-- Check Constraints
-- =====================================================

-- Users table constraints
ALTER TABLE users
    ADD CONSTRAINT chk_user_limits CHECK (daily_limit >= 0 AND monthly_limit >= daily_limit),
    ADD CONSTRAINT chk_user_2fa CHECK (
        (two_fa_enabled = 0 AND two_fa_secret IS NULL) OR
        (two_fa_enabled = 1 AND two_fa_secret IS NOT NULL)
    );

-- Wallets balance constraints
ALTER TABLE wallets
    ADD CONSTRAINT chk_wallet_balance CHECK (
        available_balance >= 0 AND
        locked_balance >= 0 AND
        staked_balance >= 0
    );

-- Orders constraints
ALTER TABLE orders
    ADD CONSTRAINT chk_order_quantity CHECK (quantity > 0 AND executed_quantity >= 0),
    ADD CONSTRAINT chk_order_price CHECK (
        (order_type IN ('limit', 'stop_limit') AND price > 0) OR
        (order_type IN ('market', 'stop'))
    ),
    ADD CONSTRAINT chk_order_execution CHECK (executed_quantity <= quantity);

-- Trades constraints
ALTER TABLE trades
    ADD CONSTRAINT chk_trade_values CHECK (
        price > 0 AND
        quantity > 0 AND
        total_value > 0
    ),
    ADD CONSTRAINT chk_trade_fees CHECK (
        buyer_fee >= 0 AND
        seller_fee >= 0
    );

-- Transactions constraints
ALTER TABLE transactions
    ADD CONSTRAINT chk_transaction_amount CHECK (amount > 0 AND fee >= 0);

-- Staking constraints
ALTER TABLE staking_products
    ADD CONSTRAINT chk_staking_amounts CHECK (
        min_stake_amount >= 0 AND
        (max_stake_amount IS NULL OR max_stake_amount >= min_stake_amount)
    ),
    ADD CONSTRAINT chk_staking_apy CHECK (apy_rate >= 0 AND apy_rate <= 1000);

ALTER TABLE staking_positions
    ADD CONSTRAINT chk_staking_position CHECK (staked_amount > 0 AND reward_earned >= 0);

-- Trading pairs constraints
ALTER TABLE trading_pairs
    ADD CONSTRAINT chk_trading_pair_limits CHECK (
        min_order_size > 0 AND
        (max_order_size IS NULL OR max_order_size >= min_order_size) AND
        min_price > 0 AND
        (max_price IS NULL OR max_price >= min_price)
    ),
    ADD CONSTRAINT chk_trading_fees CHECK (
        maker_fee >= 0 AND maker_fee <= 1 AND
        taker_fee >= 0 AND taker_fee <= 1 AND
        taker_fee >= maker_fee
    );

-- =====================================================
-- Triggers
-- =====================================================

-- Update wallet balance on transaction completion
DELIMITER //
CREATE TRIGGER update_wallet_on_transaction
AFTER UPDATE ON transactions
FOR EACH ROW
BEGIN
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        IF NEW.transaction_type = 'deposit' THEN
            UPDATE wallets
            SET available_balance = available_balance + NEW.amount - NEW.fee
            WHERE wallet_id = NEW.wallet_id;
        ELSEIF NEW.transaction_type = 'withdrawal' THEN
            UPDATE wallets
            SET available_balance = available_balance - NEW.amount - NEW.fee
            WHERE wallet_id = NEW.wallet_id;
        END IF;
    END IF;
END//
DELIMITER ;

-- Lock funds when placing order
DELIMITER //
CREATE TRIGGER lock_funds_on_order
AFTER INSERT ON orders
FOR EACH ROW
BEGIN
    DECLARE currency_id_to_lock INT;
    DECLARE amount_to_lock DECIMAL(30, 18);

    -- Determine which currency to lock based on order side
    IF NEW.side = 'buy' THEN
        -- For buy orders, lock quote currency
        SELECT quote_currency_id INTO currency_id_to_lock
        FROM trading_pairs WHERE pair_id = NEW.pair_id;

        -- Calculate amount to lock (quantity * price for limit orders)
        IF NEW.order_type IN ('limit', 'stop_limit') THEN
            SET amount_to_lock = NEW.quantity * NEW.price;
        END IF;
    ELSE -- sell
        -- For sell orders, lock base currency
        SELECT base_currency_id INTO currency_id_to_lock
        FROM trading_pairs WHERE pair_id = NEW.pair_id;
        SET amount_to_lock = NEW.quantity;
    END IF;

    -- Update wallet balances
    IF amount_to_lock IS NOT NULL AND amount_to_lock > 0 THEN
        UPDATE wallets
        SET available_balance = available_balance - amount_to_lock,
            locked_balance = locked_balance + amount_to_lock
        WHERE user_id = NEW.user_id AND currency_id = currency_id_to_lock;
    END IF;
END//
DELIMITER ;

-- Release funds when order is cancelled or completed
DELIMITER //
CREATE TRIGGER release_funds_on_order_update
AFTER UPDATE ON orders
FOR EACH ROW
BEGIN
    DECLARE currency_id_to_release INT;
    DECLARE amount_to_release DECIMAL(30, 18);

    -- Only process if order is moving to final state
    IF NEW.status IN ('filled', 'cancelled', 'expired', 'rejected') AND
       OLD.status NOT IN ('filled', 'cancelled', 'expired', 'rejected') THEN

        -- Determine which currency to release
        IF NEW.side = 'buy' THEN
            SELECT quote_currency_id INTO currency_id_to_release
            FROM trading_pairs WHERE pair_id = NEW.pair_id;

            -- Calculate amount to release (remaining unexecuted amount)
            IF NEW.order_type IN ('limit', 'stop_limit') THEN
                SET amount_to_release = (NEW.quantity - NEW.executed_quantity) * NEW.price;
            END IF;
        ELSE -- sell
            SELECT base_currency_id INTO currency_id_to_release
            FROM trading_pairs WHERE pair_id = NEW.pair_id;
            SET amount_to_release = NEW.quantity - NEW.executed_quantity;
        END IF;

        -- Update wallet balances
        IF amount_to_release IS NOT NULL AND amount_to_release > 0 THEN
            UPDATE wallets
            SET locked_balance = locked_balance - amount_to_release,
                available_balance = available_balance + amount_to_release
            WHERE user_id = NEW.user_id AND currency_id = currency_id_to_release;
        END IF;
    END IF;
END//
DELIMITER ;

-- Audit log trigger for sensitive operations
DELIMITER //
CREATE TRIGGER audit_user_changes
AFTER UPDATE ON users
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, entity_type, entity_id, old_values, new_values)
    VALUES (
        NEW.user_id,
        'user_update',
        'users',
        NEW.user_id,
        JSON_OBJECT(
            'kyc_level', OLD.kyc_level,
            'status', OLD.status,
            'daily_limit', OLD.daily_limit,
            'monthly_limit', OLD.monthly_limit
        ),
        JSON_OBJECT(
            'kyc_level', NEW.kyc_level,
            'status', NEW.status,
            'daily_limit', NEW.daily_limit,
            'monthly_limit', NEW.monthly_limit
        )
    );
END//
DELIMITER ;

-- Update last activity on user actions
DELIMITER //
CREATE TRIGGER update_user_activity_on_order
AFTER INSERT ON orders
FOR EACH ROW
BEGIN
    UPDATE users
    SET last_activity = CURRENT_TIMESTAMP
    WHERE user_id = NEW.user_id;
END//
DELIMITER ;

-- Calculate staking rewards
DELIMITER //
CREATE TRIGGER calculate_staking_reward
BEFORE UPDATE ON staking_positions
FOR EACH ROW
BEGIN
    DECLARE days_staked INT;
    DECLARE daily_rate DECIMAL(10, 6);
    DECLARE reward DECIMAL(30, 18);

    IF NEW.status = 'active' AND OLD.status = 'active' THEN
        -- Calculate days since last reward
        SET days_staked = DATEDIFF(NOW(), IFNULL(OLD.last_reward_date, OLD.stake_date));

        -- Get APY rate and calculate daily rate
        SELECT apy_rate / 365 INTO daily_rate
        FROM staking_products
        WHERE product_id = NEW.product_id;

        -- Calculate compound interest
        SET reward = OLD.staked_amount * POW(1 + daily_rate, days_staked) - OLD.staked_amount;

        -- Update reward
        SET NEW.reward_earned = OLD.reward_earned + reward;
        SET NEW.last_reward_date = NOW();
    END IF;
END//
DELIMITER ;

-- =====================================================
-- Functions
-- =====================================================

-- Calculate user's total portfolio value in USD
DELIMITER //
CREATE FUNCTION get_user_portfolio_value(p_user_id INT)
RETURNS DECIMAL(20, 2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE total_value DECIMAL(20, 2) DEFAULT 0;

    SELECT SUM(
        CASE
            WHEN c.symbol = 'USD' THEN w.available_balance + w.locked_balance + w.staked_balance
            ELSE (w.available_balance + w.locked_balance + w.staked_balance) *
                 IFNULL(
                     (SELECT close_price
                      FROM price_history ph
                      JOIN trading_pairs tp ON ph.pair_id = tp.pair_id
                      JOIN currencies qc ON tp.quote_currency_id = qc.currency_id
                      WHERE tp.base_currency_id = c.currency_id
                        AND qc.symbol = 'USD'
                        AND ph.timeframe = '1d'
                      ORDER BY ph.timestamp DESC
                      LIMIT 1), 0)
        END
    ) INTO total_value
    FROM wallets w
    JOIN currencies c ON w.currency_id = c.currency_id
    WHERE w.user_id = p_user_id;

    RETURN IFNULL(total_value, 0);
END//
DELIMITER ;

-- Check if user can trade (KYC and limit checks)
DELIMITER //
CREATE FUNCTION can_user_trade(p_user_id INT, p_amount DECIMAL(20, 2))
RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE user_status VARCHAR(50);
    DECLARE user_kyc_verified BOOLEAN;
    DECLARE daily_traded DECIMAL(20, 2);
    DECLARE daily_limit DECIMAL(20, 2);

    -- Get user status and KYC
    SELECT status, kyc_verified, daily_limit
    INTO user_status, user_kyc_verified, daily_limit
    FROM users
    WHERE user_id = p_user_id;

    -- Check user status
    IF user_status != 'active' OR user_kyc_verified = 0 THEN
        RETURN FALSE;
    END IF;

    -- Check daily trading limit
    SELECT IFNULL(SUM(total_value), 0) INTO daily_traded
    FROM trades
    WHERE (buyer_id = p_user_id OR seller_id = p_user_id)
      AND DATE(executed_at) = CURDATE();

    IF daily_traded + p_amount > daily_limit THEN
        RETURN FALSE;
    END IF;

    RETURN TRUE;
END//
DELIMITER ;

-- =====================================================
-- Procedures
-- =====================================================

-- Process market order matching
DELIMITER //
CREATE PROCEDURE match_market_order(IN p_order_id BIGINT)
BEGIN
    DECLARE v_side VARCHAR(10);
    DECLARE v_pair_id INT;
    DECLARE v_quantity DECIMAL(30, 18);
    DECLARE v_remaining DECIMAL(30, 18);
    DECLARE v_user_id INT;

    -- Get order details
    SELECT side, pair_id, quantity, quantity - executed_quantity, user_id
    INTO v_side, v_pair_id, v_quantity, v_remaining, v_user_id
    FROM orders
    WHERE order_id = p_order_id;

    -- Start transaction
    START TRANSACTION;

    -- Match against opposite side orders
    IF v_side = 'buy' THEN
        -- Match with sell orders
        CALL match_with_sells(p_order_id, v_pair_id, v_remaining, v_user_id);
    ELSE
        -- Match with buy orders
        CALL match_with_buys(p_order_id, v_pair_id, v_remaining, v_user_id);
    END IF;

    COMMIT;
END//
DELIMITER ;

-- Clean up expired sessions
DELIMITER //
CREATE PROCEDURE cleanup_expired_sessions()
BEGIN
    UPDATE user_sessions
    SET is_active = FALSE
    WHERE expires_at < NOW() AND is_active = TRUE;

    DELETE FROM user_sessions
    WHERE expires_at < DATE_SUB(NOW(), INTERVAL 30 DAY);
END//
DELIMITER ;
