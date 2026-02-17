#!/usr/bin/env python3
"""
IoT Waste Management System - Test Generator
Quick test with smaller dataset
"""

import sys
from pathlib import Path

# Override configuration for testing
TEST_CONFIG = {
    "districts": 3,              # Reduced from 12
    "bins_per_district": 10,     # Reduced from 100
    "sensors_per_bin": 2,         # Reduced from 3
    "trucks": 5,                  # Reduced from 25
    "drivers": 8,                 # Reduced from 40
    "routes_per_district": 2,     # Reduced from 5
    "days_of_history": 7,         # Reduced from 90
    "readings_per_day_per_sensor": 24,  # Reduced from 288 (hourly instead of 5-minute)
    "collection_frequency_days": 3,
}

print("Test Configuration:")
for key, value in TEST_CONFIG.items():
    print(f"  {key}: {value}")
print()

# Import and override the configuration
sys.path.insert(0, str(Path(__file__).parent))
import generator

# Override configuration
generator.CONFIG = TEST_CONFIG
generator.OUTPUT_DIR = Path("test_output")

if __name__ == "__main__":
    print("="*50)
    print("Starting TEST IoT Waste Management Data Generation...")
    print("="*50)
    print()

    gen = generator.IoTBinsGenerator()
    gen.generate_all()

    print("\n[SUCCESS] TEST generation complete!")
    print(f"Files saved to: test_output/")