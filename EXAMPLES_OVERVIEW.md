# MySQL Business-to-Schema Examples Portfolio

## 📚 Complete Database Examples Collection

This repository contains 21 comprehensive database examples across multiple industries. Each example includes schemas, queries, and detailed documentation.

## 🎯 Examples Overview (with Table Counts)

Generator coverage legend:
- ✅ `foldered` = `generators/<name>/generate.py` + `config.yaml`
- 🟡 `script` = standalone script in `generators/`
- ⚪ `none`

| Example | Domain | Tables | Generator |
|---------|--------|--------|-----------|
| **01 - Clinic Management** | Healthcare | 9 | ✅ foldered |
| **02 - IoT Bins** | Smart City | 15 | ✅ foldered |
| **03 - Smart Energy** | Utilities | 26 | ✅ foldered |
| **04 - E-commerce** | Retail | 33 | ✅ foldered |
| **05 - Industrial IoT** | Manufacturing | 18 | ✅ foldered |
| **06 - Smart Agriculture** | Farming | 23 | ✅ foldered |
| **07 - Fleet Management** | Transportation | 23 | ✅ foldered |
| **08 - Healthcare IoT** | Medical | 25 | ✅ foldered |
| **09 - Streaming ML** | Analytics | 33 | ✅ foldered |
| **10 - FinTech Platform** | Financial | 26 | ✅ foldered |
| **11 - Social Media Network** | Social | 25 | ✅ foldered |
| **12 - Real Estate Marketplace** | Real Estate | 29 | ⚪ none |
| **13 - Event Ticketing** | Entertainment | 26 | ⚪ none |
| **14 - Logistics & Supply Chain** | Logistics | 24 | ✅ foldered |
| **15 - Education & LMS** | Education | 33 | 🟡 script |
| **16 - Cryptocurrency** | Finance | 14 | ⚪ none |
| **16b - Crypto Exchange** | Finance | 17 | 🟡 script |
| **17 - Food Delivery** | Delivery | 21 | 🟡 script |
| **18 - Gaming Platform** | Gaming | 25 | 🟡 script |
| **19 - Insurance** | Insurance | 20 | 🟡 script |
| **20 - Hotel Chain** | Hospitality | 20 | 🟡 script |

## 📊 Technical Patterns Demonstrated

### Time Series Data
- **Partitioning**: Monthly/daily partitions for efficient querying
- **Aggregations**: Hourly/daily rollups for performance
- **Retention**: Archival strategies for historical data
- **Examples**: 02, 03, 05, 06, 07, 08, 09

### IoT Specific
- **Sensor Management**: Device registry, health monitoring
- **Real-time Processing**: Stream processing patterns
- **Anomaly Detection**: Statistical and ML-based
- **Examples**: 02, 03, 05, 06, 07, 08

### Spatial/GIS
- **Location Tracking**: GPS coordinates, geofencing
- **Route Optimization**: Distance calculations, clustering
- **Zone Management**: Spatial indexing
- **Examples**: 02, 06, 07

### Machine Learning
- **Feature Engineering**: Pre-computed features for ML
- **Model Management**: Versioning, A/B testing
- **Collaborative Filtering**: User-item interactions
- **Examples**: 09

### Compliance & Security
- **HIPAA**: Healthcare data protection (08)
- **Multi-tenancy**: Data isolation (03)
- **Audit Trails**: Change tracking
- **Examples**: 01, 03, 08

## 🚀 Quick Start Guide

### 1. Environment Setup
```bash
# Start MySQL container
docker-compose up -d

# Verify connection
mysql -h 127.0.0.1 -P 3306 -u root -proot_password
```

### 2. Choose an Example
Start with simpler examples and progress to more complex ones:

**Learning Path for IoT:**
1. `example_02_iot_bins` - Basic IoT patterns
2. `example_03_smart_energy` - Multi-tenant IoT
3. `example_05_industrial_iot` - Manufacturing IoT
4. Choose specialized: Agriculture (06), Fleet (07), or Healthcare (08)

**Learning Path for Traditional:**
1. `example_01_clinic` - Basic relational design
2. `example_04_ecommerce` - Complex transactions

**Learning Path for ML/DS:**
1. `example_09_streaming_ml` - Complete ML pipeline

### 3. Deploy an Example
```bash
# Navigate to example
cd example_02_iot_bins

# Create database and schema
mysql -u root -p < schema/00_create_database.sql
mysql -u root -p iot_bins < schema/01_tables.sql
mysql -u root -p iot_bins < schema/02_constraints.sql
mysql -u root -p iot_bins < schema/03_indexes.sql

# Load sample data
mysql -u root -p iot_bins < data/seed.sql

# Run example queries
mysql -u root -p iot_bins < queries/01_monitoring.sql
```

## 📈 Data Characteristics

### Volume Comparison

| Example | Tables | Daily Records | Storage/Day | Retention |
|---------|--------|---------------|-------------|-----------|
| IoT Bins | 15 | 500K | 50MB | 90 days |
| Smart Energy | 30+ | 1M+ | 100MB | 1 year |
| Industrial | 25 | 100K | 20MB | 2 years |
| Agriculture | 20 | 200K | 30MB | 1 season |
| Fleet | 25 | 1M+ | 50MB/vehicle | 90 days |
| Healthcare | 35 | 500K | 75MB | 7 years |
| Streaming ML | 40 | 10M+ | 1GB | 180 days |
| Clinic | 20 | 1K | 5MB | Permanent |
| E-commerce | 40+ | 50K | 25MB | Permanent |

## 🎓 Educational Value

### By Skill Level

**Beginner:**
- Basic table relationships (01, 04)
- Simple queries and joins
- CRUD operations
- Data integrity constraints

**Intermediate:**
- Time series modeling (02, 03)
- Indexing strategies
- Stored procedures
- Performance optimization

**Advanced:**
- Partitioning strategies (02, 03, 05, 06, 07, 08, 09)
- Spatial queries (02, 06, 07)
- ML feature engineering (09)
- Multi-tenant architecture (03)
- Real-time analytics (all IoT)

### By Business Domain

**Operations:**
- Fleet Management (07)
- Industrial IoT (05)
- Garbage Collection (02)

**Healthcare:**
- Medical Clinic (01)
- Healthcare IoT (08)

**Utilities:**
- Smart Energy (03)
- Smart Agriculture (06)

**Data Science:**
- Streaming ML Platform (09)

**Retail:**
- E-commerce (04)

## 🔧 Common Operations

### Performance Monitoring
```sql
-- Check partition usage (IoT examples)
SELECT
    partition_name,
    table_rows,
    data_length/1024/1024 as size_mb
FROM information_schema.partitions
WHERE table_schema = 'iot_bins'
    AND table_name = 'sensor_readings';
```

### Data Aggregation
```sql
-- Hourly rollups (common pattern)
INSERT INTO sensor_readings_hourly
SELECT
    sensor_id,
    DATE_FORMAT(reading_time, '%Y-%m-%d %H:00:00') as hour,
    AVG(value) as avg_value,
    MIN(value) as min_value,
    MAX(value) as max_value
FROM sensor_readings
WHERE reading_time >= DATE_SUB(NOW(), INTERVAL 1 HOUR)
GROUP BY sensor_id, DATE_FORMAT(reading_time, '%Y-%m-%d %H:00:00');
```

## 📝 Key Takeaways

1. **IoT Systems** require special consideration for:
   - High-volume time series data
   - Real-time processing needs
   - Data retention and archival
   - Device management and health monitoring

2. **Different domains** have unique requirements:
   - Healthcare: Compliance and audit trails
   - Manufacturing: OEE and quality metrics
   - Agriculture: Seasonal patterns and GIS
   - Fleet: Real-time tracking and route optimization

3. **Performance optimization** is critical:
   - Use partitioning for time series
   - Implement aggregation tables
   - Design efficient indexes
   - Consider data archival strategies

4. **Machine Learning integration** requires:
   - Pre-computed features
   - Efficient data pipelines
   - Model versioning
   - A/B testing infrastructure

## 🚦 Next Steps

1. **Pick an example** that matches your interest or industry
2. **Deploy the schema** and explore the structure
3. **Run the queries** to understand the patterns
4. **Modify and extend** based on your needs
5. **Combine patterns** from different examples for your projects

## 📚 Resources

- [MySQL Documentation](https://dev.mysql.com/doc/)
- [Time Series Best Practices](https://www.timescale.com/blog/time-series-data-best-practices/)
- [IoT Database Design](https://aws.amazon.com/iot/solutions/iot-database/)
- [ML Database Patterns](https://www.oreilly.com/library/view/designing-machine-learning/9781098107956/)

---

**Repository Structure:**
```
mysql-business-to-schema/
├── docker-compose.yml           # MySQL environment
├── docs/                        # Learning materials
├── generators/                  # Data generation tools
├── example_01_clinic/          # Medical clinic system
├── example_02_iot_bins/        # IoT garbage monitoring
├── example_03_smart_energy/    # Smart energy grid
├── example_04_ecommerce/       # E-commerce platform
├── example_05_industrial_iot/  # Manufacturing IoT
├── example_06_smart_agriculture/ # Precision farming
├── example_07_fleet_management/ # Vehicle tracking
├── example_08_healthcare_iot/  # Patient monitoring
└── example_09_streaming_ml/    # ML analytics platform
```

Each example is self-contained with its own README, schema, queries, and documentation.

## 🤝 Contributing

Feel free to:
- Add new examples
- Improve existing schemas
- Contribute more complex queries
- Share performance optimization tips
- Report issues or suggestions

Happy learning! 🎉
