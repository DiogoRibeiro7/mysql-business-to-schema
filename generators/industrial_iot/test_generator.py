#!/usr/bin/env python3
"""
Industrial IoT Manufacturing - Test Generator
Quick test with smaller dataset
"""

import sys
from pathlib import Path

# Override configuration for testing
TEST_CONFIG = {
    "factories": 1,              # Reduced from 3
    "lines_per_factory": 2,      # Reduced from 5
    "machines_per_line": 3,      # Reduced from 8
    "sensors_per_machine": 2,    # Reduced from 4
    "products": 10,              # Reduced from 50
    "work_orders_per_day": 5,    # Reduced from 20
    "days_of_history": 7,        # Reduced from 30
    "readings_per_hour": 12,     # Reduced from 60 (every 5 minutes instead of every minute)
    "shifts_per_day": 2,         # Reduced from 3
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
    print("Starting TEST Industrial IoT Data Generation...")
    print("="*50)
    print()

    gen = generator.IndustrialIoTGenerator()
    gen.generate_all()

    print("\n[SUCCESS] TEST generation complete!")
    print(f"Files saved to: test_output/")