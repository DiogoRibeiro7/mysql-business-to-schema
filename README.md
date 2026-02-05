# mysql-business-to-schema

Learn how to move from a business narrative to a production-ready MySQL schema. This comprehensive repository contains **9 complete database examples** with **6 working data generators**, covering everything from traditional CRUD applications to modern IoT systems and machine learning platforms.

## 🎯 What You'll Learn

- **Business Analysis** → Requirements gathering and domain modeling
- **Database Design** → ER models, normalization, and schema optimization
- **Time Series Data** → IoT sensors, partitioning, and aggregation strategies
- **Performance** → Indexing, query optimization, and scaling patterns
- **Real-world Patterns** → Multi-tenancy, compliance, spatial queries, and more
- **Data Generation** → Creating realistic test data with proper distributions

## 📚 Complete Database Examples

### IoT & Time Series (7 examples)

| Example | Domain | Key Learning Points | Tables | Generator |
|---------|--------|-------------------|---------|-----------|
| **02 - IoT Bins** | Smart Waste Management | Time series partitioning, spatial queries, route optimization | 15 | ✅ |
| **03 - Smart Energy** | Utility Grid Monitoring | Multi-tenant architecture, high-frequency readings, solar production | 30+ | ✅ |
| **05 - Industrial IoT** | Manufacturing | OEE metrics, predictive maintenance, quality control | 25 | ✅ |
| **06 - Smart Agriculture** | Precision Farming | GIS integration, irrigation automation, yield prediction | 20 | ❌ |
| **07 - Fleet Management** | Vehicle Tracking | High-frequency GPS (5-sec), telematics, compliance (HOS/DVIR) | 25 | ✅ |
| **08 - Healthcare IoT** | Patient Monitoring | HIPAA compliance, medical device integration, alert management | 35 | ❌ |
| **09 - Streaming ML** | Analytics Platform | Feature engineering, A/B testing, recommendation systems | 40 | ❌ |

### Traditional Systems (2 examples)

| Example | Domain | Key Learning Points | Tables | Generator |
|---------|--------|-------------------|---------|-----------|
| **01 - Medical Clinic** | Healthcare | Appointments, billing, referential integrity | 20 | ✅ |
| **04 - E-commerce** | Online Retail | Orders, inventory, payment processing, reviews | 40+ | ✅ |

## 🚀 Quick Start

### 1. Start MySQL with Docker

```bash
# Start MySQL container
docker-compose -f docker/docker-compose.yml up -d

# Verify connection
mysql -h 127.0.0.1 -P 3306 -u root -proot_password
```

### Smoke Test (Optional)

Run a minimal end-to-end check that generates data, loads MySQL, and runs sanity queries:

```bash
# Bash (macOS/Linux)
./scripts/smoke_test.sh

# PowerShell (Windows)
.\scripts\smoke_test.ps1
```

### 2. Choose Your Learning Path

#### Path A: Traditional Databases
Start here if you're new to database design:
1. **Example 01 - Clinic**: Basic relationships and transactions
2. **Example 04 - E-commerce**: Complex workflows and inventory

#### Path B: IoT & Time Series
For modern data engineering:
1. **Example 02 - IoT Bins**: Introduction to time series
2. **Example 03 - Smart Energy**: Multi-tenant IoT
3. **Example 05 - Industrial IoT**: Manufacturing metrics

#### Path C: Advanced Patterns
For specific domains:
1. **Example 07 - Fleet**: Real-time GPS and compliance
2. **Example 08 - Healthcare IoT**: Medical devices and HIPAA
3. **Example 09 - Streaming ML**: Machine learning pipelines

### 3. Deploy an Example

```bash
# Navigate to any example
cd example_02_iot_bins

# Create database and schema
mysql -u root -p < schema/00_create_database.sql
mysql -u root -p iot_bins < schema/01_tables.sql
mysql -u root -p iot_bins < schema/02_constraints.sql
mysql -u root -p iot_bins < schema/03_indexes.sql

# Load sample data (if available)
mysql -u root -p iot_bins < data/seed.sql

# Run example queries
mysql -u root -p iot_bins < queries/01_monitoring.sql
```

### 4. Generate Test Data

For examples with generators (marked with ✅):

```bash
# Navigate to generator
cd generators/iot_bins

# Generate data
python generate.py --config config.yaml

# Output will be in generators/iot_bins/output/
ls -la output/*.csv
```

## 📊 Data Patterns Covered

### Time Series Frequencies
- **1 second**: Industrial vibration sensors
- **5 seconds**: Fleet GPS tracking
- **15 minutes**: Smart energy consumption
- **1 hour**: Aggregated metrics
- **Daily**: Business reports

### Business Patterns
- **Multi-tenancy**: Isolated customer data (Example 03)
- **Compliance**: HIPAA, GDPR considerations (Examples 01, 08)
- **Geospatial**: GPS tracking, route optimization (Examples 02, 07)
- **Machine Learning**: Feature engineering, model deployment (Example 09)
- **Manufacturing**: OEE, Six Sigma metrics (Example 05)

## 🔧 Data Generators

### Available Generators (6 of 9 complete)

```bash
# Check generator status
for dir in generators/*/; do
  name=$(basename $dir)
  [ -f "${dir}generate.py" ] && echo "✅ $name" || echo "❌ $name"
done
```

### Generator Features
- **Configurable** via YAML files
- **Reproducible** with seed values
- **Realistic** patterns (daily/weekly/seasonal)
- **Scalable** from demo to production volumes
- **Includes** anomalies and edge cases

### Example: Generate E-commerce Data

```bash
cd generators/ecommerce
python generate.py --config config.yaml

# This generates:
# - 5,000 users across segments
# - 2,000 products in categories
# - 8,000+ orders with realistic patterns
# - Shopping cart abandonment (70% rate)
# - Reviews and ratings
# - Inventory across warehouses
```

## 📖 Documentation Structure

### For Each Example
```
example_XX_name/
├── README.md           # Business context and overview
├── schema/
│   ├── 00_create_database.sql
│   ├── 01_tables.sql   # Core tables
│   ├── 02_constraints.sql
│   └── 03_indexes.sql
├── queries/
│   ├── 01_basic.sql    # Learning queries
│   ├── 02_analytics.sql
│   └── 03_advanced.sql
├── data/
│   └── seed.sql        # Sample data
└── procedures/         # Stored procedures
```

### Learning Resources
- **[EXAMPLES_OVERVIEW.md](EXAMPLES_OVERVIEW.md)** - Detailed guide to all examples
- **[generators/GENERATOR_STATUS.md](generators/GENERATOR_STATUS.md)** - Generator implementation status
- **Individual READMEs** - Business context for each example

## 🎓 Learning Objectives by Level

### Beginner
- Understand entity relationships
- Write basic CRUD operations
- Design normalized schemas
- Create appropriate indexes

### Intermediate
- Implement time series partitioning
- Design for multi-tenancy
- Optimize query performance
- Handle transactions properly

### Advanced
- Build ML feature pipelines
- Implement event sourcing
- Design for horizontal scaling
- Create real-time analytics

## 💡 Key Insights from Examples

### IoT Systems Need Special Consideration
- **Data Volume**: Millions of readings require partitioning
- **Retention**: Implement data lifecycle (hot/warm/cold)
- **Aggregation**: Pre-compute rollups for performance
- **Anomalies**: Detect and handle sensor failures

### Business Logic Belongs in the Database
- **Constraints**: Enforce data integrity at the schema level
- **Procedures**: Encapsulate complex operations
- **Triggers**: Maintain audit trails automatically
- **Views**: Standardize reporting queries

### Performance Patterns
- **Partitioning**: Essential for time series (Examples 02, 03, 05)
- **Indexing**: Cover indexes for read-heavy workloads
- **Denormalization**: Strategic duplication for performance
- **Caching**: Materialized views for complex aggregations

## 🛠️ Installation Requirements

### For Schema Deployment
- MySQL 8.0+ or MariaDB 10.5+
- Docker (optional but recommended)

### For Data Generators
```bash
# Python 3.10+
pip install -e .

# Check Python version
python --version
```

## 📈 Project Statistics

- **9** Complete database examples
- **6** Working data generators
- **300+** Total tables across all schemas
- **100+** Sample queries
- **500K+** Records/day generation capability
- **15+** Different data patterns demonstrated

## 🤝 Use Cases

### For Learning
- University database courses
- Self-study progression
- Interview preparation
- Technology evaluation

### For Development
- Test data generation
- Performance benchmarking
- Proof of concepts
- Integration testing

### For Teaching
- Workshop materials
- Course assignments
- Hands-on exercises
- Case studies

## 📝 Assignments & Exercises

Each example includes practice exercises:

### Basic Level
- Write queries to answer business questions
- Add missing constraints
- Create appropriate indexes
- Implement simple stored procedures

### Advanced Level
- Optimize slow queries
- Design partitioning strategies
- Implement data archival
- Build real-time dashboards

Check each example's `queries/` folder for specific exercises.

## 🚦 Next Steps

1. **Choose an example** that matches your interest
2. **Deploy the schema** following the quick start
3. **Generate test data** if generator available
4. **Explore queries** to understand the patterns
5. **Complete exercises** to practice
6. **Modify and extend** for your needs

## 📚 Additional Resources

### MySQL Documentation
- [Partitioning](https://dev.mysql.com/doc/refman/8.0/en/partitioning.html)
- [Indexing](https://dev.mysql.com/doc/refman/8.0/en/optimization-indexes.html)
- [Stored Programs](https://dev.mysql.com/doc/refman/8.0/en/stored-programs.html)

### Best Practices
- [High Performance MySQL](https://www.oreilly.com/library/view/high-performance-mysql/9781492080503/)
- [Database Design](https://www.databasedesignbook.com/)
- [Time Series Databases](https://www.timescale.com/blog/time-series-database-design-best-practices/)

## 🐛 Troubleshooting

### Common Issues

**Problem**: "Access denied" when loading data
- Solution: Check MySQL user permissions
- Alternative: Use root user for initial setup

**Problem**: Generator runs out of memory
- Solution: Reduce data volume in config.yaml
- Check: `counts` and `days_of_data` settings

**Problem**: Docker container won't start
- Solution: Check if port 3306 is already in use
- Alternative: Change port in docker-compose.yml

## ✅ Smoke Test

Run a minimal end-to-end check that generates data, loads MySQL, and runs sanity queries.

```bash
# Bash (macOS/Linux)
./scripts/smoke_test.sh

# PowerShell (Windows)
.\scripts\smoke_test.ps1
```

## 📄 License

MIT License - See LICENSE file for details

## 🙏 Acknowledgments

This educational repository demonstrates database design patterns across multiple industries. Each example is simplified for learning purposes while maintaining realistic business logic.

---

**Ready to start?** Pick an example that interests you and dive in! Each one tells a complete story from business requirements to working database with test data.

For detailed information about each example, see [EXAMPLES_OVERVIEW.md](EXAMPLES_OVERVIEW.md).
