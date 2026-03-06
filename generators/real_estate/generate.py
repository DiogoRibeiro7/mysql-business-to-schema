#!/usr/bin/env python3
"""Real Estate dataset generator.

Reads a JSON-compatible YAML config file and generates CSV data for a real estate platform.
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
        description="Generate sample data for real estate platform"
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
        "--countries",
        type=int,
        help="Number of countries to generate",
    )
    parser.add_argument(
        "--properties",
        type=int,
        help="Number of properties to generate",
    )
    parser.add_argument(
        "--agents",
        type=int,
        help="Number of agents to generate",
    )
    parser.add_argument(
        "--users",
        type=int,
        help="Number of users to generate",
    )
    parser.add_argument(
        "--listings",
        type=int,
        help="Number of listings to generate",
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
    from real_estate.generator import RealEstateDataGenerator

    try:
        # Load configuration
        config = load_config(args.config)

        # Override config with command-line arguments
        if args.output_dir:
            config["output_dir"] = str(args.output_dir)
        if args.seed is not None:
            config["seed"] = args.seed
        if args.countries:
            config["counts"]["countries"] = args.countries
        if args.properties:
            config["counts"]["properties"] = args.properties
        if args.agents:
            config["counts"]["agents"] = args.agents
        if args.users:
            config["counts"]["users"] = args.users
        if args.listings:
            config["counts"]["listings"] = args.listings

        # Set random seeds
        random.seed(config["seed"])

        # Initialize generator
        if args.verbose:
            print(f"Initializing Real Estate Data Generator with seed {config['seed']}")
            print(f"Output directory: {config['output_dir']}")

        # Create generator instance with the config
        generator = RealEstateDataGenerator(config_path=args.config)

        # Create output directory
        output_dir = Path(config["output_dir"])
        output_dir.mkdir(parents=True, exist_ok=True)

        # Generate data
        if args.verbose:
            print("\nGenerating data...")
            print(f"  Countries: {config['counts'].get('countries', 5)}")
            print(f"  Properties: {config['counts'].get('properties', 1000)}")
            print(f"  Agents: {config['counts'].get('agents', 100)}")
            print(f"  Users: {config['counts'].get('users', 500)}")
            print(f"  Listings: {config['counts'].get('listings', 800)}")

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
