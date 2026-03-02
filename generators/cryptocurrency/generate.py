#!/usr/bin/env python3
"""Cryptocurrency Exchange dataset generator.

Reads a JSON-compatible YAML config file and generates CSV data for a cryptocurrency exchange.
The generated data is deterministic for a given seed and respects FK relationships.
"""

from __future__ import annotations

import argparse
import json
import random
import sys
from pathlib import Path
from typing import Optional

# Add parent directory to path for imports
sys.path.append(str(Path(__file__).parent.parent))

from cryptocurrency.generator import CryptocurrencyDataGenerator


def parse_args() -> argparse.Namespace:
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(
        description="Generate sample data for cryptocurrency exchange"
    )
    parser.add_argument(
        "-c",
        "--config",
        type=Path,
        default=Path(__file__).parent / "config.yaml",
        help="Path to config file (default: config.yaml)",
    )
    parser.add_argument(
        "-o",
        "--output-dir",
        type=Path,
        help="Output directory for generated files (overrides config)",
    )
    parser.add_argument(
        "--seed",
        type=int,
        help="Random seed (overrides config)",
    )
    parser.add_argument(
        "--users",
        type=int,
        help="Number of users to generate",
    )
    parser.add_argument(
        "--currencies",
        type=int,
        help="Number of currencies to generate",
    )
    parser.add_argument(
        "--orders",
        type=int,
        help="Number of orders to generate",
    )
    parser.add_argument(
        "--trades",
        type=int,
        help="Number of trades to generate",
    )
    parser.add_argument(
        "--transactions",
        type=int,
        help="Number of transactions to generate",
    )
    parser.add_argument(
        "--sql",
        action="store_true",
        help="Also generate SQL insert statements",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="Enable verbose output",
    )

    return parser.parse_args()


def load_config(config_path: Path) -> dict:
    """Load configuration from YAML/JSON file."""
    if not config_path.exists():
        raise FileNotFoundError(f"Config file not found: {config_path}")

    with open(config_path, "r") as f:
        config = json.load(f)

    return config


def main() -> int:
    """Main entry point."""
    args = parse_args()

    try:
        # Load configuration
        config = load_config(args.config)

        # Override config with command-line arguments
        if args.output_dir:
            config["output_dir"] = str(args.output_dir)
        if args.seed is not None:
            config["seed"] = args.seed
        if args.users:
            config["counts"]["users"] = args.users
        if args.currencies:
            config["counts"]["currencies"] = args.currencies
        if args.orders:
            config["counts"]["orders"] = args.orders
        if args.trades:
            config["counts"]["trades"] = args.trades
        if args.transactions:
            config["counts"]["transactions"] = args.transactions

        # Set random seeds
        random.seed(config["seed"])

        # Initialize generator
        if args.verbose:
            print(f"Initializing Cryptocurrency Exchange Data Generator with seed {config['seed']}")
            print(f"Output directory: {config['output_dir']}")

        # Create generator instance with the config
        generator = CryptocurrencyDataGenerator(config_path=args.config)

        # Create output directory
        output_dir = Path(config["output_dir"])
        output_dir.mkdir(parents=True, exist_ok=True)

        # Generate data
        if args.verbose:
            print("\nGenerating data...")
            print(f"  Users: {config['counts'].get('users', 500)}")
            print(f"  Currencies: {config['counts'].get('currencies', 50)}")
            print(f"  Trading Pairs: {config['counts'].get('trading_pairs', 100)}")
            print(f"  Orders: {config['counts'].get('orders', 5000)}")
            print(f"  Trades: {config['counts'].get('trades', 3000)}")
            print(f"  Transactions: {config['counts'].get('transactions', 8000)}")

        # Run the generation
        generator.generate()

        # Export to CSV
        if args.verbose:
            print("\nExporting data to CSV files...")

        generator.export_to_csv(str(output_dir))

        # Optionally generate SQL
        if args.sql:
            if args.verbose:
                print("\nGenerating SQL insert statements...")
            sql_path = output_dir / "inserts.sql"
            generator.export_to_sql(str(sql_path))
            if args.verbose:
                print(f"SQL written to: {sql_path}")

        if args.verbose:
            print("\nGeneration complete!")
            print(f"Files written to: {output_dir}")

        return 0

    except FileNotFoundError as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1
    except KeyError as e:
        print(f"Configuration error: Missing key {e}", file=sys.stderr)
        return 1
    except Exception as e:
        print(f"Unexpected error: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())