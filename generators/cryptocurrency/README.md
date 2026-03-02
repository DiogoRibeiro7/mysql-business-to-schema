# Cryptocurrency Exchange Data Generator

Generates realistic sample data for a cryptocurrency exchange platform with proper foreign key relationships and market dynamics.

## Features

- **Users & KYC**: User accounts with KYC documentation
- **Currencies**: Cryptocurrencies, fiat currencies, and stablecoins
- **Trading**: Trading pairs, orders, trades, and market data
- **Wallets**: User wallets with balances
- **Transactions**: Deposits, withdrawals, and transfers
- **Price History**: OHLCV candlestick data
- **API Keys**: User API keys for programmatic access
- **Fee Tiers**: User-specific fee tier assignments
- **Trading Volumes**: Historical trading volume tracking

## Usage

### Basic Usage

Generate data with default configuration:

```bash
python generate.py -v
```

### Custom Configuration

Override specific counts:

```bash
python generate.py --users 1000 --orders 10000 --trades 5000 -v
```

### Generate SQL

Include SQL insert statements:

```bash
python generate.py --sql -v
```

### Custom Output Directory

```bash
python generate.py -o /path/to/output -v
```

## Configuration

Edit `config.yaml` to customize:

- **counts**: Number of records for each entity
- **distributions**: Status and type distributions
- **date_ranges**: Date ranges for historical data
- **price_ranges**: Price ranges for different currency types
- **volume_ranges**: Trading volume ranges
- **fee_ranges**: Fee percentage ranges

## Output Files

The generator creates the following CSV files:

- `users.csv` - User accounts
- `kyc_documents.csv` - KYC verification documents
- `currencies.csv` - Supported currencies
- `trading_pairs.csv` - Available trading pairs
- `wallets.csv` - User wallet addresses and balances
- `orders.csv` - Trading orders (limit, market, stop)
- `trades.csv` - Executed trades
- `transactions.csv` - Deposits and withdrawals
- `price_history.csv` - OHLCV price data
- `api_keys.csv` - API access keys
- `user_fee_tiers.csv` - User fee tier assignments
- `user_trading_volumes.csv` - Historical volume tracking

## Data Model Features

### Realistic Market Dynamics

- Price correlations between related pairs
- Volume-based fee discounts
- Order book depth simulation
- Market maker/taker fee structure

### Security Features

- Password hashing (SHA-256)
- API key generation
- IP whitelisting for API access
- Two-factor authentication flags

### Compliance

- KYC document tracking
- Transaction audit logs
- Country-based restrictions
- User verification status

## Examples

### Generate Small Test Dataset

```bash
python generate.py --users 50 --orders 500 --trades 300 -v
```

### Generate Large Production-like Dataset

```bash
python generate.py --users 5000 --orders 50000 --trades 30000 --transactions 80000 -v
```

### Generate with Custom Seed

```bash
python generate.py --seed 123 -v
```

## Dependencies

- Python 3.8+
- faker
- Standard library modules (json, csv, random, datetime, decimal, pathlib)