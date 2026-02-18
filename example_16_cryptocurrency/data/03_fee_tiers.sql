-- ============================================================================
-- SAMPLE FEE TIERS DATA
-- ============================================================================

USE crypto_exchange;

-- Insert fee tiers based on 30-day trading volume (in USD)
INSERT INTO user_fee_tiers (tier_name, min_volume, max_volume,
                           maker_fee_rate, taker_fee_rate,
                           withdrawal_fee_discount)
VALUES
    -- Basic tiers
    ('Bronze', 0, 10000, 0.1000, 0.2000, 0.00),
    ('Silver', 10000, 50000, 0.0900, 0.1800, 5.00),
    ('Gold', 50000, 100000, 0.0800, 0.1600, 10.00),
    ('Platinum', 100000, 500000, 0.0700, 0.1400, 15.00),

    -- Advanced tiers
    ('Diamond', 500000, 1000000, 0.0600, 0.1200, 20.00),
    ('Elite', 1000000, 5000000, 0.0500, 0.1000, 25.00),
    ('Pro', 5000000, 10000000, 0.0400, 0.0800, 30.00),

    -- VIP tiers
    ('VIP 1', 10000000, 50000000, 0.0300, 0.0600, 40.00),
    ('VIP 2', 50000000, 100000000, 0.0250, 0.0500, 50.00),
    ('VIP 3', 100000000, NULL, 0.0200, 0.0400, 60.00),

    -- Market maker program
    ('Market Maker', 0, NULL, 0.0000, 0.0300, 75.00);