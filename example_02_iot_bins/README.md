# IoT Garbage Bin Monitoring System

## Overview

This example demonstrates a comprehensive IoT-based smart city waste management system that monitors garbage bins in real-time, optimizes collection routes, and provides predictive analytics for efficient urban waste collection.

## Business Context

Modern cities face significant challenges in waste management:
- **Inefficient Collection**: Bins are often collected on fixed schedules regardless of fill levels
- **Overflow Issues**: Full bins create health hazards and environmental problems
- **Resource Waste**: Trucks collect partially-filled bins, wasting fuel and labor
- **Poor Visibility**: No real-time data on bin status or collection needs

This IoT solution addresses these challenges by:
- Installing smart sensors in garbage bins to monitor fill levels, temperature, and other metrics
- Collecting real-time data to optimize collection routes dynamically
- Predicting fill rates to prevent overflows
- Reducing operational costs through data-driven decision making

## Learning Objectives

### Primary Skills
- **Time Series Data Modeling**: Design schemas for high-volume sensor data
- **Partitioning Strategies**: Implement monthly partitions for performance
- **IoT Data Patterns**: Handle sensor readings, quality metrics, offline periods
- **Spatial Queries**: Use geographic functions for route optimization
- **Aggregation Techniques**: Create hourly/daily summaries from raw data

### Advanced Concepts
- **Predictive Analytics**: Forecast bin fill rates using historical patterns
- **Alert Management**: Design threshold-based alert systems
- **Route Optimization**: Apply spatial algorithms for efficient collection
- **Data Archival**: Implement retention policies for time series data
- **Performance Tuning**: Use indexes and partitions for query optimization

## Database Schema

### Core Components

1. **Infrastructure** (3 tables)
   - `districts`: City districts for organizing routes
   - `bins`: Physical bin locations with metadata
   - `sensors`: IoT devices monitoring each bin

2. **Time Series Data** (3 tables)
   - `sensor_readings`: Raw sensor data (partitioned monthly)
   - `sensor_readings_hourly`: Hourly aggregates
   - `sensor_readings_daily`: Daily summaries

3. **Collection Management** (7 tables)
   - `collection_routes`: Predefined collection paths
   - `trucks`: Fleet vehicles
   - `drivers`: Collection crew
   - `collection_schedules`: Planned collections
   - `collection_events`: Actual collection records
   - `route_bin_assignments`: Bin-to-route mappings

4. **Alert System** (2 tables)
   - `alert_thresholds`: Configurable alert rules
   - `alerts`: System-generated notifications

5. **Analytics** (1 table)
   - `fill_rate_predictions`: ML model outputs

### Key Design Decisions

**Partitioning Strategy**
- Monthly partitions for `sensor_readings` table
- Automatic partition management via stored procedures
- Improved query performance for date-range queries

**Indexing Approach**
- Composite indexes for common query patterns
- Covering indexes for dashboard queries
- Spatial indexes for geographic calculations

**Data Retention**
- Raw readings: 90 days
- Hourly aggregates: 1 year
- Daily summaries: Indefinite

## Setup Instructions

### Prerequisites
- MySQL 8.0+ (for spatial functions and CTEs)
- Python 3.8+ (for data generator)
- 2GB+ free disk space

### Installation

1. **Create Database**
```bash
mysql -u root -p < schema/00_create_database.sql
```

2. **Create Tables and Constraints**
```bash
mysql -u root -p iot_bins < schema/01_tables.sql
mysql -u root -p iot_bins < schema/02_constraints.sql
mysql -u root -p iot_bins < schema/03_indexes.sql
mysql -u root -p iot_bins < schema/04_partitions.sql
mysql -u root -p iot_bins < schema/05_aggregations.sql
```

3. **Generate Test Data**
```bash
cd ../generators/iot_bins
python generate.py --config config.yaml
```

4. **Load Generated Data**
```bash
cd ../../example_02_iot_bins
mysql -u root -p iot_bins < schema/10_load_generated.sql
```

5. **Create Stored Procedures**
```bash
mysql -u root -p iot_bins < procedures/01_aggregation.sql
mysql -u root -p iot_bins < procedures/02_archival.sql
```

## Usage Examples

### Real-time Monitoring

Find critical bins requiring immediate collection:
```sql
SELECT * FROM v_urgent_collections
WHERE urgency_level = 'Critical'
ORDER BY current_fill_percentage DESC;
```

### Route Optimization

Generate optimal collection route for a district:
```sql
CALL sp_generate_route_suggestions(1, 75.0);
```

### Predictive Analytics

Forecast bin fill levels for next 24 hours:
```sql
CALL sp_calculate_fill_predictions(100, 24);
```

### Performance Metrics

View collection efficiency by district:
```sql
SELECT * FROM v_collection_performance
WHERE collection_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY);
```

## Query Categories

### 1. Monitoring (01_monitoring.sql)
- Current critical bins
- Offline sensors
- Low battery alerts
- District overviews
- System performance metrics

### 2. Analytics (02_analytics.sql)
- Fill rate patterns by location type
- Peak usage hour analysis
- Seasonal trends
- Anomaly detection
- Temperature correlations

### 3. Route Optimization (03_route_optimization.sql)
- Proximity-based clustering
- Truck capacity planning
- Multi-district coordination
- Emergency collection routes

### 4. Reports (04_reports.sql)
- Executive dashboards
- Fleet utilization
- Driver performance
- Environmental impact
- SLA compliance

### 5. Maintenance (05_maintenance.sql)
- Battery degradation analysis
- Sensor failure prediction
- Component lifecycle tracking
- Maintenance cost projections

### 6. Student Assignments (06_assignments.sql)
- Beginner to expert exercises
- Real-world problem solving
- Performance optimization challenges

## Data Characteristics

### Volume
- ~1,000 bins across 10 districts
- ~4,000 sensors (4 per bin)
- ~500K sensor readings per day
- ~30 days of historical data

### Patterns
- **Residential**: Morning and evening peaks
- **Commercial**: Business hours activity
- **Seasonal**: Higher summer fill rates
- **Events**: Random spikes (10% probability)

### Quality
- 95% good readings
- 3% warnings
- 2% errors/offline

## Performance Considerations

### Query Optimization
- Use partitioned tables for date-range queries
- Leverage covering indexes for dashboards
- Apply spatial indexes for route calculations

### Best Practices
```sql
-- Good: Use partition pruning
SELECT * FROM sensor_readings
WHERE reading_time >= '2025-01-15'
  AND reading_time < '2025-01-16';

-- Avoid: Full table scans
SELECT * FROM sensor_readings
WHERE DATE(reading_time) = '2025-01-15';
```

### Maintenance Tasks
- Run hourly aggregations via scheduled events
- Archive old data monthly
- Rebuild statistics weekly
- Monitor partition sizes

## Advanced Features

### Predictive Maintenance
The system predicts sensor failures based on:
- Battery degradation rates
- Error frequency patterns
- Communication failures
- Age-based reliability curves

### Route Optimization Algorithm
Implements a greedy nearest-neighbor approach:
1. Start with most critical bin
2. Add nearest high-priority bin
3. Respect truck capacity constraints
4. Minimize total distance

### Alert Escalation
- **Info**: Logged only
- **Warning**: Dashboard notification
- **Critical**: SMS/email alert
- **Emergency**: Immediate dispatch

## Troubleshooting

### Common Issues

**Slow Queries**
- Check partition pruning with EXPLAIN
- Verify indexes are being used
- Run ANALYZE TABLE to update statistics

**High Disk Usage**
- Archive old sensor readings
- Drop unused partitions
- Optimize fragmented tables

**Missing Data**
- Check sensor status
- Verify collection schedules
- Review error logs

## Extensions

### Possible Enhancements
1. **Weather Integration**: Correlate fill rates with weather data
2. **ML Models**: Implement more sophisticated predictions
3. **Mobile App**: Real-time notifications for drivers
4. **Public API**: Open data for civic applications
5. **Carbon Tracking**: Calculate environmental impact

### Integration Points
- **MQTT Broker**: Real-time sensor data ingestion
- **GraphQL API**: Flexible data queries
- **Grafana**: Time series visualization
- **Apache Kafka**: Stream processing
- **TensorFlow**: Advanced predictions

## Learning Path

### Week 1: Basics
- Understand schema design
- Run monitoring queries
- Create simple reports

### Week 2: Analytics
- Analyze time series patterns
- Detect anomalies
- Calculate correlations

### Week 3: Optimization
- Design collection routes
- Optimize queries
- Implement aggregations

### Week 4: Advanced
- Build predictions
- Create custom procedures
- Design new features

## Resources

### Documentation
- [MySQL Partitioning](https://dev.mysql.com/doc/refman/8.0/en/partitioning.html)
- [Spatial Functions](https://dev.mysql.com/doc/refman/8.0/en/spatial-functions.html)
- [Window Functions](https://dev.mysql.com/doc/refman/8.0/en/window-functions.html)

### Related Examples
- `example_01_clinic`: Healthcare appointment system
- `example_03_ecommerce`: Online shopping platform (planned)
- `example_04_library`: Library management (planned)

## Contributing

To add new features or queries:
1. Follow existing naming conventions
2. Add comprehensive comments
3. Include test cases
4. Update documentation

## License

This educational example is provided as-is for learning purposes.