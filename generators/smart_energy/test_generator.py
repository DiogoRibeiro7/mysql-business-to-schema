#!/usr/bin/env python3

"""Smart Energy Management - Test Generator.

Quick test with smaller dataset
"""

from pathlib import Path
import generators.smart_energy.generator as generator

# Override configuration for testing
TEST_CONFIG = {
    "buildings": 2,  # Reduced from 5
    "floors_per_building": 3,  # Reduced from 10
    "zones_per_floor": 3,  # Reduced from 8
    "tenants": 5,  # Reduced from 20
    "meters_per_building": 5,  # Reduced from 15
    "solar_systems": 1,  # Reduced from 3
    "battery_systems": 1,  # Reduced from 2
    "hvac_units_per_building": 2,  # Reduced from 5
    "days_of_history": 7,  # Reduced from 30
    "readings_per_hour": 4,  # Reduced from 12 (every 15 minutes)
}

print("Test Configuration:")
for key, value in TEST_CONFIG.items():
    print(f"  {key}: {value}")
print()

# Import and override the configuration

# Override configuration
generator.CONFIG = TEST_CONFIG
generator.OUTPUT_DIR = Path("test_output")

if __name__ == "__main__":
    print("=" * 50)
    print("Starting TEST Smart Energy Data Generation...")
    print("=" * 50)
    print()

    gen = generator.SmartEnergyGenerator()
    gen.generate_all()

    print("\n[SUCCESS] TEST generation complete!")
    print("Files saved to: test_output/")
