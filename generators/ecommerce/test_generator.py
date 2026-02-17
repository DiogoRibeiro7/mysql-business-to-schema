#!/usr/bin/env python3
"""
E-commerce Platform Data Generator - Test Version
Quick test with smaller dataset
"""

import csv
import json
import random
import hashlib
from datetime import datetime, timedelta
from decimal import Decimal
from pathlib import Path
from faker import Faker
import numpy as np

# Configuration - SCALED DOWN FOR TESTING
SEED = 42
OUTPUT_DIR = Path("test_output")
fake = Faker()
Faker.seed(SEED)
random.seed(SEED)
np.random.seed(SEED)

# Scaled down configuration for testing
CONFIG = {
    "customers": 100,        # Reduced from 10000
    "products": 50,          # Reduced from 5000
    "categories": 10,        # Reduced from 150
    "brands": 10,            # Reduced from 200
    "warehouses": 2,         # Reduced from 5
    "orders_per_day": 5,     # Reduced from 500
    "days_of_history": 30,   # Reduced from 365
    "review_rate": 0.15,
    "cart_abandonment_rate": 0.70,
    "return_rate": 0.08,
    "support_ticket_rate": 0.05,
}

print(f"Test Configuration:")
print(f"  Customers: {CONFIG['customers']}")
print(f"  Products: {CONFIG['products']}")
print(f"  Orders: ~{CONFIG['orders_per_day'] * CONFIG['days_of_history']}")
print(f"  Days of history: {CONFIG['days_of_history']}")

# Import the main generator
import sys
sys.path.insert(0, str(Path(__file__).parent))
from generator import EcommerceGenerator

# Override the CONFIG in the imported module
import generator
generator.CONFIG = CONFIG
generator.OUTPUT_DIR = OUTPUT_DIR

if __name__ == "__main__":
    print("\n" + "="*50)
    print("Starting TEST E-commerce Data Generation...")
    print("="*50 + "\n")

    generator = EcommerceGenerator()
    generator.generate_all()

    print("\n[SUCCESS] TEST e-commerce data generation complete!")
    print(f"Output files saved to: {OUTPUT_DIR.absolute()}")