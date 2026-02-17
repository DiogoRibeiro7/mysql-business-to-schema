# MySQL Business-to-Schema Data Generators

This directory contains data generators for all 15 MySQL database examples. Each generator creates realistic, production-ready data that can scale to millions of records.

## 📊 Generator Coverage

| Example | Domain | Tables | Generator | Status | Records Generated |
|---------|--------|--------|-----------|---------|------------------|
| example_01 | Medical Clinic | 18 | `clinic` | ✅ Complete | ~50K+ records |
| example_02 | E-Commerce | 16 | `ecommerce` | ✅ Complete | ~100K+ records |
| example_03 | Education Platform | 13 | `education` | ✅ Complete | ~75K+ records |
| example_04 | Real Estate | 14 | `real_estate` | ✅ Complete | ~60K+ records |
| example_05 | Event Ticketing | 13 | `event_ticketing` | ✅ Complete | ~80K+ records |
| example_06 | Smart Agriculture | 21 | `smart_agriculture` | ✅ Complete | ~250K+ records |
| example_07 | Fleet Management | 22 | `fleet_management` | ✅ Complete | ~375K+ records |
| example_08 | IoT Waste Management | 15 | `iot_bins` | ✅ Complete | ~180K+ records |
| example_09 | Streaming ML Platform | 29 | `streaming_ml` | ✅ Complete | ~300K+ records |
| example_10 | FinTech Platform | 23 | `fintech` | ✅ Complete | ~200K+ records |
| example_11 | Social Media | 28 | `social_media` | ✅ Complete | ~150K+ records |
| example_12 | Smart Energy Grid | 18 | `smart_energy` | ✅ Complete | ~220K+ records |
| example_13 | Healthcare IoT | 24 | `healthcare_iot` | ✅ Complete | ~280K+ records |
| example_14 | Logistics & Supply Chain | 24 | `logistics` | ✅ Complete | ~250K+ records |
| example_15 | Industrial IoT | 20 | `industrial_iot` | ✅ Complete | ~320K+ records |

**Total Coverage: 15/15 (100%)** 🎉

## 🚀 Quick Start

### Using the Unified Runner

The easiest way to run generators is using the unified runner script:

```bash
# Run a single generator
python generators/run_generators.py clinic

# Run in test mode (reduced data)
python generators/run_generators.py clinic --test

# Run multiple generators
python generators/run_generators.py clinic ecommerce fintech

# Run all generators in test mode
python generators/run_generators.py --all --test

# List all available generators
python generators/run_generators.py --list

# Benchmark generators
python generators/run_generators.py --benchmark clinic fintech
```

### Running Individual Generators

Each generator can also be run independently:

```bash
# Run full generator
cd generators/clinic
python generator.py

# Run test version (if available)
python test_generator.py
```

## 📁 Generator Structure

Each generator follows a consistent structure:

```
generators/
├── <generator_name>/
│   ├── generator.py        # Main generator script
│   ├── test_generator.py   # Test version with reduced data
│   ├── README.md           # Generator-specific documentation
│   └── output/            # Generated SQL files (created on run)
│       ├── 01_users.sql
│       ├── 02_products.sql
│       └── ...
```

## ⚙️ Configuration

Each generator has configurable parameters at the top of the script:

```python
CONFIG = {
    "users": 1000,              # Number of users to generate
    "days_of_history": 30,      # Days of historical data
    "transactions_per_day": 50, # Daily transaction volume
    # ... generator-specific settings
}
```

### Test Mode Configuration

Test generators use reduced data volumes for faster execution:

```python
# Test mode configuration
CONFIG = {
    "users": 100,            # Reduced from 1000
    "days_of_history": 7,    # Reduced from 30
    # ... other reduced settings
}
```

## 🏗️ Generator Features

### Common Features

All generators include:
- ✅ Realistic data using Faker library
- ✅ Proper foreign key relationships
- ✅ Time-series data with realistic patterns
- ✅ Configurable data volumes
- ✅ Progress indicators
- ✅ Summary statistics
- ✅ SQL output files

### Specialized Features by Domain

#### IoT Generators
- **Smart Agriculture**: Weather data, soil sensors, irrigation schedules
- **Fleet Management**: GPS tracking (5-second intervals), fuel consumption, maintenance
- **Healthcare IoT**: Vital signs, medical device readings, alert thresholds
- **Industrial IoT**: Production metrics, quality control, predictive maintenance
- **Smart Energy**: Grid sensors, consumption patterns, demand forecasting
- **IoT Bins**: Fill levels, collection routes, sensor readings

#### Platform Generators
- **E-Commerce**: Order fulfillment, inventory management, customer reviews
- **Social Media**: Social graph, viral content, engagement metrics
- **Education**: Course progress, assessments, learning paths
- **Streaming ML**: Experiments, model deployments, feature stores
- **FinTech**: Double-entry accounting, KYC/AML compliance, transaction processing

#### Management Systems
- **Clinic**: Appointments, medical records, prescriptions, billing
- **Real Estate**: Property listings, viewings, lease management
- **Event Ticketing**: Seat maps, pricing tiers, promotional codes
- **Logistics**: Warehouse operations, shipment tracking, route optimization

## 📊 Performance Characteristics

| Generator Type | Typical Runtime (Full) | Typical Runtime (Test) | Memory Usage |
|---------------|------------------------|------------------------|--------------|
| Simple (<15 tables) | 30-60 seconds | 5-10 seconds | ~100-200 MB |
| Medium (15-20 tables) | 60-120 seconds | 10-20 seconds | ~200-400 MB |
| Complex (20+ tables) | 120-300 seconds | 20-40 seconds | ~400-800 MB |
| IoT with Time-Series | 180-600 seconds | 30-60 seconds | ~500-1000 MB |

## 🔧 Development Guide

### Creating a New Generator

1. **Copy Template Structure**
```bash
cp -r generators/clinic generators/new_domain
```

2. **Update Configuration**
```python
CONFIG = {
    # Define your domain-specific settings
}
```

3. **Implement Generation Methods**
```python
class YourGenerator:
    def __init__(self):
        self.fake = Faker()
        # Initialize collections

    def generate_entities(self):
        # Generate main entities

    def generate_relationships(self):
        # Generate relationship data

    def generate_transactions(self):
        # Generate transactional data
```

4. **Add Output Methods**
```python
def save_to_file(self, filename, table_name, data, columns):
    # Save data as SQL INSERT statements
```

5. **Create Test Version**
```python
# test_generator.py
import generator

# Override configuration for testing
generator.CONFIG = {
    "users": 100,  # Reduced volume
    # ...
}

if __name__ == "__main__":
    gen = generator.YourGenerator()
    gen.generate_all()
```

### Best Practices

1. **Memory Management**
   - Stream large datasets to files instead of keeping in memory
   - Use generators for very large collections
   - Clear collections after writing to files

2. **Realistic Data**
   - Use appropriate Faker providers
   - Maintain referential integrity
   - Follow business logic constraints

3. **Performance**
   - Batch database operations
   - Use appropriate data structures
   - Profile and optimize bottlenecks

4. **Error Handling**
   - Validate configuration parameters
   - Handle edge cases (empty collections, date ranges)
   - Provide meaningful error messages

## 🧪 Testing

### Unit Testing
```bash
# Run test generator
cd generators/<generator_name>
python test_generator.py
```

### Integration Testing
```bash
# Test with actual database
mysql -u root -p < output/*.sql
```

### Validation Checklist
- [ ] All foreign keys reference existing records
- [ ] Date ranges are consistent
- [ ] Numeric values are within realistic ranges
- [ ] Required fields are populated
- [ ] Unique constraints are respected

## 📈 Benchmarking

Use the benchmark feature to compare generator performance:

```bash
# Benchmark specific generators
python generators/run_generators.py --benchmark clinic fintech

# Benchmark all generators
python generators/run_generators.py --all --benchmark
```

## 🔍 Troubleshooting

### Common Issues

1. **Memory Errors**
   - Solution: Use test mode or reduce CONFIG values
   - Consider streaming output for large datasets

2. **Import Errors**
   - Solution: Ensure Faker is installed: `pip install faker`
   - Check Python version (3.7+ required)

3. **Division by Zero**
   - Solution: Add guards for empty collections
   - Example: `rate = count / total if total > 0 else 0`

4. **Date/Time Errors**
   - Solution: Ensure consistent use of date vs datetime
   - Use `.date()` method when comparing with date objects

5. **Random Range Errors**
   - Solution: Use min/max to ensure valid ranges
   - Example: `random.randint(min(a, b), max(a, b))`

## 📚 Additional Resources

- [Faker Documentation](https://faker.readthedocs.io/)
- [MySQL Data Types](https://dev.mysql.com/doc/refman/8.0/en/data-types.html)
- [SQL INSERT Syntax](https://dev.mysql.com/doc/refman/8.0/en/insert.html)

## 🤝 Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines on:
- Adding new generators
- Improving existing generators
- Performance optimizations
- Bug fixes

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.

---

**Status**: All 15 generators complete and production-ready! 🎉