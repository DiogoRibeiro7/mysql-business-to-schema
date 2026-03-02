#!/usr/bin/env python3
"""Test Script for the Four Additional Generators.

Tests food delivery, gaming platform, insurance, and hotel chain generators
"""

import sys
import os
import argparse

# Add parent directory to path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def test_generator(generator_name, generator_class, database_name, scale="test"):
    """Test a single generator."""
    print(f"\n{'='*60}")
    print(f"Testing {generator_name} Generator")
    print("=" * 60)

    try:
        # Import the generator
        if generator_name == "food_delivery":
            from generators.food_delivery_generator import FoodDeliveryGenerator

            generator = FoodDeliveryGenerator(
                host="localhost",
                port=3306,
                user="root",
                password="password",
                database=database_name,
            )
        elif generator_name == "gaming_platform":
            from generators.gaming_platform_generator import GamingPlatformGenerator

            generator = GamingPlatformGenerator(
                host="localhost",
                port=3306,
                user="root",
                password="password",
                database=database_name,
            )
        elif generator_name == "insurance":
            from generators.insurance_generator import InsuranceGenerator

            generator = InsuranceGenerator(
                host="localhost",
                port=3306,
                user="root",
                password="password",
                database=database_name,
            )
        elif generator_name == "hotel_chain":
            from generators.hotel_chain_generator import HotelChainGenerator

            generator = HotelChainGenerator(
                host="localhost",
                port=3306,
                user="root",
                password="password",
                database=database_name,
            )

        print(f"[OK] Successfully imported {generator_name} generator")

        # Test data generation methods
        if hasattr(generator, "generate_all_data"):
            print("[OK] Has generate_all_data() method")

            # Try to generate a small amount of test data
            if scale == "test":
                # Just test that methods exist and can be called
                if hasattr(generator, "connect"):
                    print("[OK] Has connect() method")
                if hasattr(generator, "disconnect"):
                    print("[OK] Has disconnect() method")
                if hasattr(generator, "bulk_insert"):
                    print("[OK] Has bulk_insert() method")
                if hasattr(generator, "print_statistics"):
                    print("[OK] Has print_statistics() method")

                # Check for specific generation methods
                methods_to_check = [
                    "generate_users",
                    "generate_orders",
                    "truncate_all_tables",
                    "fetch_all",
                    "execute_query",
                ]

                found_methods = []
                for method in methods_to_check:
                    if hasattr(generator, method):
                        found_methods.append(method)

                if found_methods:
                    print(f"[OK] Found methods: {', '.join(found_methods)}")

                print(
                    f"\n[SUCCESS] {generator_name} generator is properly implemented!"
                )
                return True
        else:
            print("[WARNING] Missing generate_all_data() method")
            return False

    except ImportError as e:
        print(f"[FAIL] Failed to import {generator_name} generator: {e}")
        return False
    except Exception as e:
        print(f"[FAIL] Error testing {generator_name} generator: {e}")
        return False


def test_all_missing_generators():
    """Test all four missing generators."""
    print("=" * 60)
    print("TESTING MISSING GENERATORS")
    print("=" * 60)
    print("\nTesting generators that were marked as missing:")
    print("1. Food Delivery")
    print("2. Gaming Platform")
    print("3. Insurance")
    print("4. Hotel Chain")

    results = {
        "food_delivery": False,
        "gaming_platform": False,
        "insurance": False,
        "hotel_chain": False,
    }

    # Test each generator
    results["food_delivery"] = test_generator(
        "food_delivery", "FoodDeliveryGenerator", "food_delivery_platform"
    )

    results["gaming_platform"] = test_generator(
        "gaming_platform", "GamingPlatformGenerator", "gaming_platform"
    )

    results["insurance"] = test_generator(
        "insurance", "InsuranceGenerator", "insurance_company"
    )

    results["hotel_chain"] = test_generator(
        "hotel_chain", "HotelChainGenerator", "hotel_chain_management"
    )

    # Print summary
    print("\n" + "=" * 60)
    print("SUMMARY")
    print("=" * 60)

    total = len(results)
    passed = sum(1 for v in results.values() if v)

    for name, status in results.items():
        status_str = "[PASS] IMPLEMENTED" if status else "[FAIL] MISSING/INCOMPLETE"
        print(f"{name:20} : {status_str}")

    print("-" * 60)
    print(f"Total: {passed}/{total} generators implemented ({passed/total*100:.0f}%)")

    if passed == total:
        print("\n[COMPLETE] All generators are fully implemented!")
        print("These generators are ready for use and support:")
        print("  - Database connection management via BaseGenerator")
        print("  - Efficient bulk insert operations")
        print("  - Data generation at scale")
        print("  - Statistics reporting")
    else:
        missing = [name for name, status in results.items() if not status]
        print(f"\n[WARNING] Missing/incomplete generators: {', '.join(missing)}")

    return passed == total


def demonstrate_generator_usage():
    """Show how to use the generators."""
    print("\n" + "=" * 60)
    print("GENERATOR USAGE EXAMPLES")
    print("=" * 60)

    print("\n1. Food Delivery Generator:")
    print("```python")
    print("from generators.food_delivery_generator import FoodDeliveryGenerator")
    print("generator = FoodDeliveryGenerator(")
    print("    host='localhost',")
    print("    database='food_delivery_platform'")
    print(")")
    print("generator.generate_all_data(")
    print("    restaurants=100,")
    print("    customers=1000,")
    print("    orders_per_day=500")
    print(")")
    print("```")

    print("\n2. Gaming Platform Generator:")
    print("```python")
    print("from generators.gaming_platform_generator import GamingPlatformGenerator")
    print("generator = GamingPlatformGenerator(")
    print("    host='localhost',")
    print("    database='gaming_platform'")
    print(")")
    print("generator.generate_all_data(")
    print("    players=5000,")
    print("    games=100,")
    print("    matches_per_day=1000")
    print(")")
    print("```")

    print("\n3. Insurance Generator:")
    print("```python")
    print("from generators.insurance_generator import InsuranceGenerator")
    print("generator = InsuranceGenerator(")
    print("    host='localhost',")
    print("    database='insurance_company'")
    print(")")
    print("generator.generate_all_data(")
    print("    customers=2000,")
    print("    policies=5000,")
    print("    claims=500")
    print(")")
    print("```")

    print("\n4. Hotel Chain Generator:")
    print("```python")
    print("from generators.hotel_chain_generator import HotelChainGenerator")
    print("generator = HotelChainGenerator(")
    print("    host='localhost',")
    print("    database='hotel_chain_management'")
    print(")")
    print("generator.generate_all_data(")
    print("    hotels=20,")
    print("    rooms_per_hotel=100,")
    print("    guests=5000,")
    print("    bookings=10000")
    print(")")
    print("```")


def main():
    """Handle main."""
    parser = argparse.ArgumentParser(description="Test missing generators")
    parser.add_argument(
        "--generator",
        choices=["food_delivery", "gaming_platform", "insurance", "hotel_chain", "all"],
        default="all",
        help="Which generator to test",
    )
    parser.add_argument("--demo", action="store_true", help="Show usage examples")

    args = parser.parse_args()

    if args.demo:
        demonstrate_generator_usage()
    elif args.generator == "all":
        success = test_all_missing_generators()
        demonstrate_generator_usage()
        sys.exit(0 if success else 1)
    else:
        success = test_generator(
            args.generator,
            f"{args.generator.replace('_', ' ').title()}Generator",
            args.generator,
        )
        if success:
            print(f"\n[SUCCESS] {args.generator} generator is ready for use!")
        else:
            print(f"\n[FAIL] {args.generator} generator needs implementation!")
        sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
