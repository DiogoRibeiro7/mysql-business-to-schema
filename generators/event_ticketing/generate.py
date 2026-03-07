#!/usr/bin/env python3
"""Event Ticketing dataset generator.

Reads a JSON-compatible YAML config file and generates CSV data for an event ticketing platform.
The generated data is deterministic for a given seed and respects FK relationships.
"""

from __future__ import annotations

import argparse
import json
import random
import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.append(str(Path(__file__).parent.parent))


def parse_args() -> argparse.Namespace:
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(
        description="Generate sample data for event ticketing platform"
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
        "--venues",
        type=int,
        help="Number of venues to generate",
    )
    parser.add_argument(
        "--events",
        type=int,
        help="Number of events to generate",
    )
    parser.add_argument(
        "--performers",
        type=int,
        help="Number of performers to generate",
    )
    parser.add_argument(
        "--customers",
        type=int,
        help="Number of customers to generate",
    )
    parser.add_argument(
        "--bookings",
        type=int,
        help="Number of bookings to generate",
    )
    parser.add_argument(
        "--tickets",
        type=int,
        help="Number of tickets to generate",
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
    """Run the CLI entry point."""
    args = parse_args()
    from event_ticketing.generator import EventTicketingDataGenerator

    try:
        # Load configuration
        config = load_config(args.config)

        # Override config with command-line arguments
        if args.output_dir:
            config["output_dir"] = str(args.output_dir)
        if args.seed is not None:
            config["seed"] = args.seed
        if args.venues:
            config["counts"]["venues"] = args.venues
        if args.events:
            config["counts"]["events"] = args.events
        if args.performers:
            config["counts"]["performers"] = args.performers
        if args.customers:
            config["counts"]["customers"] = args.customers
        if args.bookings:
            config["counts"]["bookings"] = args.bookings
        if args.tickets:
            config["counts"]["tickets"] = args.tickets

        # Set random seeds
        random.seed(config["seed"])

        # Initialize generator
        if args.verbose:
            print(
                f"Initializing Event Ticketing Data Generator with seed {config['seed']}"
            )
            print(f"Output directory: {config['output_dir']}")

        # Create generator instance with the config
        generator = EventTicketingDataGenerator(config_path=args.config)

        # Create output directory
        output_dir = Path(config["output_dir"])
        output_dir.mkdir(parents=True, exist_ok=True)

        # Generate data
        if args.verbose:
            print("\nGenerating data...")
            print(f"  Venues: {config['counts'].get('venues', 20)}")
            print(f"  Events: {config['counts'].get('events', 100)}")
            print(f"  Performers: {config['counts'].get('performers', 200)}")
            print(f"  Customers: {config['counts'].get('customers', 1000)}")
            print(f"  Bookings: {config['counts'].get('bookings', 2000)}")
            print(f"  Tickets: {config['counts'].get('tickets', 5000)}")

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
