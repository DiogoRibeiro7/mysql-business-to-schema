-- ============================================================================
-- SAMPLE CURRENCIES DATA
-- ============================================================================

USE crypto_exchange;

-- Insert major cryptocurrencies
INSERT INTO currencies (symbol, name, currency_type, blockchain, contract_address, decimals,
                       deposit_confirmations, min_withdrawal, withdrawal_fee, market_cap_rank)
VALUES
    -- Major cryptocurrencies
    ('BTC', 'Bitcoin', 'crypto', 'bitcoin', NULL, 8, 6, 0.0001, 0.0005, 1),
    ('ETH', 'Ethereum', 'crypto', 'ethereum', NULL, 18, 12, 0.001, 0.005, 2),

    -- Stablecoins
    ('USDT', 'Tether', 'stablecoin', 'ethereum', '0xdac17f958d2ee523a2206206994597c13d831ec7', 6, 12, 1, 1, 3),
    ('USDC', 'USD Coin', 'stablecoin', 'ethereum', '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48', 6, 12, 1, 1, 5),
    ('BUSD', 'Binance USD', 'stablecoin', 'ethereum', '0x4fabb145d64652a948d72533023f6e7a623c7c53', 18, 12, 1, 1, 8),

    -- Major altcoins
    ('BNB', 'Binance Coin', 'crypto', 'bsc', NULL, 18, 15, 0.001, 0.0005, 4),
    ('ADA', 'Cardano', 'crypto', 'cardano', NULL, 6, 15, 1, 0.5, 6),
    ('SOL', 'Solana', 'crypto', 'solana', NULL, 9, 32, 0.01, 0.005, 7),
    ('DOT', 'Polkadot', 'crypto', 'polkadot', NULL, 10, 25, 0.1, 0.05, 9),
    ('MATIC', 'Polygon', 'crypto', 'polygon', NULL, 18, 128, 1, 0.1, 10),

    -- DeFi tokens
    ('LINK', 'Chainlink', 'crypto', 'ethereum', '0x514910771af9ca656af840dff83e8264ecf986ca', 18, 12, 0.1, 0.5, 11),
    ('UNI', 'Uniswap', 'crypto', 'ethereum', '0x1f9840a85d5af5bf1d1762f925bdaddc4201f984', 18, 12, 0.5, 1, 12),
    ('AAVE', 'Aave', 'crypto', 'ethereum', '0x7fc66500c84a76ad7e9c93437bfc5ac33e2ddae9', 18, 12, 0.05, 0.5, 15),

    -- Layer 2 tokens
    ('ARB', 'Arbitrum', 'crypto', 'arbitrum', NULL, 18, 10, 1, 0.5, 20),
    ('OP', 'Optimism', 'crypto', 'optimism', '0x4200000000000000000000000000000000000042', 18, 10, 1, 0.5, 25),

    -- Meme coins (for trading volume)
    ('DOGE', 'Dogecoin', 'crypto', 'dogecoin', NULL, 8, 30, 10, 5, 13),
    ('SHIB', 'Shiba Inu', 'crypto', 'ethereum', '0x95ad61b0a150d79219dcf64e1e6cc01f0b64c4ce', 18, 12, 1000000, 500000, 14),

    -- Other popular tokens
    ('AVAX', 'Avalanche', 'crypto', 'avalanche', NULL, 18, 32, 0.01, 0.005, 16),
    ('TRX', 'TRON', 'crypto', 'tron', NULL, 6, 20, 10, 1, 17),
    ('XRP', 'Ripple', 'crypto', 'ripple', NULL, 6, 0, 1, 0.25, 18),

    -- Fiat currencies (for fiat gateways)
    ('USD', 'US Dollar', 'fiat', NULL, NULL, 2, 0, 10, 0, NULL),
    ('EUR', 'Euro', 'fiat', NULL, NULL, 2, 0, 10, 0, NULL),
    ('GBP', 'British Pound', 'fiat', NULL, NULL, 2, 0, 10, 0, NULL);

-- Update all currencies to active
UPDATE currencies SET is_active = TRUE, can_deposit = TRUE, can_withdraw = TRUE, can_trade = TRUE;

-- Disable fiat cryptocurrency trading (only for on/off ramps)
UPDATE currencies SET can_trade = FALSE WHERE currency_type = 'fiat';