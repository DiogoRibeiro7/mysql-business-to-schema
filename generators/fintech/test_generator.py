#!/usr/bin/env python3
"""Test the fintech generator with reduced data volume"""

import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Modify configuration for faster testing
import generator

# Reduce data volume for testing
generator.CONFIG = {
    "customers": 50,  # Reduced from 500
    "individual_ratio": 0.8,
    "accounts_per_customer": (1, 2),  # Reduced from (1, 4)
    "transactions_per_day": 10,  # Reduced from 100
    "days_of_history": 7,  # Reduced from 30
    "fraud_rate": 0.02,
    "loan_applications": 10,  # Reduced from 50
    "kyc_documents_per_customer": 1,  # Reduced from 2
}

print("Test Configuration:")
print(f"  Customers: {generator.CONFIG['customers']}")
print(f"  Transactions per day: {generator.CONFIG['transactions_per_day']}")
print(f"  Days of history: {generator.CONFIG['days_of_history']}")
print("")

if __name__ == "__main__":
    gen = generator.FinTechGenerator()
    gen.generate_all()
    print("\n[SUCCESS] FinTech test generation complete!")
