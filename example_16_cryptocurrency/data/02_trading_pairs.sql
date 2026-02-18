-- ============================================================================
-- SAMPLE TRADING PAIRS DATA
-- ============================================================================

USE crypto_exchange;

-- Insert major trading pairs
-- Note: Assumes currency IDs from 01_currencies.sql

-- BTC pairs (BTC = 1)
INSERT INTO trading_pairs (base_currency_id, quote_currency_id, symbol,
                          price_precision, quantity_precision,
                          min_order_value, max_order_value,
                          min_quantity, max_quantity,
                          maker_fee_rate, taker_fee_rate)
VALUES
    -- BTC against stablecoins
    (1, 3, 'BTC/USDT', 2, 8, 10, 10000000, 0.00001, 1000, 0.0500, 0.1000),
    (1, 4, 'BTC/USDC', 2, 8, 10, 10000000, 0.00001, 1000, 0.0500, 0.1000),
    (1, 5, 'BTC/BUSD', 2, 8, 10, 10000000, 0.00001, 1000, 0.0750, 0.1500),

    -- ETH pairs (ETH = 2)
    (2, 3, 'ETH/USDT', 2, 8, 10, 5000000, 0.0001, 10000, 0.0500, 0.1000),
    (2, 4, 'ETH/USDC', 2, 8, 10, 5000000, 0.0001, 10000, 0.0500, 0.1000),
    (2, 1, 'ETH/BTC', 8, 8, 0.0001, 100, 0.0001, 10000, 0.0750, 0.1500),

    -- BNB pairs (BNB = 6)
    (6, 3, 'BNB/USDT', 2, 6, 10, 1000000, 0.01, 50000, 0.0750, 0.1500),
    (6, 1, 'BNB/BTC', 8, 6, 0.0001, 10, 0.01, 50000, 0.1000, 0.2000),

    -- ADA pairs (ADA = 7)
    (7, 3, 'ADA/USDT', 4, 2, 10, 500000, 1, 1000000, 0.0750, 0.1500),
    (7, 1, 'ADA/BTC', 8, 2, 0.0001, 5, 1, 1000000, 0.1000, 0.2000),

    -- SOL pairs (SOL = 8)
    (8, 3, 'SOL/USDT', 2, 6, 10, 500000, 0.01, 50000, 0.0750, 0.1500),
    (8, 1, 'SOL/BTC', 8, 6, 0.0001, 10, 0.01, 50000, 0.1000, 0.2000),

    -- DOT pairs (DOT = 9)
    (9, 3, 'DOT/USDT', 2, 4, 10, 500000, 0.1, 100000, 0.0750, 0.1500),
    (9, 1, 'DOT/BTC', 8, 4, 0.0001, 10, 0.1, 100000, 0.1000, 0.2000),

    -- MATIC pairs (MATIC = 10)
    (10, 3, 'MATIC/USDT', 4, 2, 10, 500000, 1, 5000000, 0.0750, 0.1500),
    (10, 1, 'MATIC/BTC', 8, 2, 0.0001, 5, 1, 5000000, 0.1000, 0.2000),

    -- DeFi token pairs
    (11, 3, 'LINK/USDT', 3, 4, 10, 500000, 0.1, 100000, 0.1000, 0.2000),
    (11, 1, 'LINK/BTC', 8, 4, 0.0001, 10, 0.1, 100000, 0.1000, 0.2000),
    (12, 3, 'UNI/USDT', 3, 4, 10, 500000, 0.1, 100000, 0.1000, 0.2000),
    (13, 3, 'AAVE/USDT', 2, 4, 10, 500000, 0.01, 10000, 0.1000, 0.2000),

    -- Layer 2 pairs
    (14, 3, 'ARB/USDT', 4, 2, 10, 300000, 1, 1000000, 0.1000, 0.2000),
    (15, 3, 'OP/USDT', 4, 2, 10, 300000, 1, 1000000, 0.1000, 0.2000),

    -- Meme coin pairs (higher volume, higher fees)
    (16, 3, 'DOGE/USDT', 6, 0, 10, 500000, 10, 50000000, 0.1500, 0.2500),
    (17, 3, 'SHIB/USDT', 10, 0, 10, 100000, 1000000, 1000000000000, 0.1500, 0.2500),

    -- Other popular pairs
    (18, 3, 'AVAX/USDT', 2, 4, 10, 500000, 0.01, 50000, 0.0750, 0.1500),
    (19, 3, 'TRX/USDT', 6, 0, 10, 300000, 10, 10000000, 0.1000, 0.2000),
    (20, 3, 'XRP/USDT', 4, 2, 10, 500000, 1, 5000000, 0.0750, 0.1500),

    -- Cross pairs (non-USD quote)
    (7, 6, 'ADA/BNB', 6, 2, 0.01, 1000, 1, 1000000, 0.1000, 0.2000),
    (8, 2, 'SOL/ETH', 6, 4, 0.001, 100, 0.01, 10000, 0.1000, 0.2000),
    (11, 2, 'LINK/ETH', 6, 4, 0.001, 100, 0.1, 100000, 0.1000, 0.2000);

-- Set initial 24h statistics (sample data)
UPDATE trading_pairs SET
    last_price = CASE symbol
        WHEN 'BTC/USDT' THEN 67500.00
        WHEN 'ETH/USDT' THEN 3450.00
        WHEN 'BNB/USDT' THEN 580.50
        WHEN 'ADA/USDT' THEN 0.6850
        WHEN 'SOL/USDT' THEN 145.75
        WHEN 'DOT/USDT' THEN 8.95
        WHEN 'MATIC/USDT' THEN 1.0250
        WHEN 'LINK/USDT' THEN 18.50
        WHEN 'DOGE/USDT' THEN 0.16234
        WHEN 'XRP/USDT' THEN 0.6234
        ELSE 1.00
    END,
    price_change_24h = FLOOR(RAND() * 20 - 10), -- Random -10% to +10%
    volume_24h = FLOOR(RAND() * 10000000), -- Random volume
    high_24h = last_price * 1.05,
    low_24h = last_price * 0.95
WHERE is_active = TRUE;

-- Activate all trading pairs
UPDATE trading_pairs SET is_active = TRUE;