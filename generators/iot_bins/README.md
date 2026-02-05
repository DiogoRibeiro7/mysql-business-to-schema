# IoT Smart Waste Management Data Generator

## Overview

Generates synthetic data for a smart city waste management system with IoT-enabled bins, sensor readings, collection routes, and operational analytics.

## Features

### Data Generated

1. **Infrastructure**
   - Districts (10 city districts)
   - Smart Bins (1,000 IoT-enabled containers)
   - Collection Trucks (50 vehicles)
   - Drivers (75 operators)

2. **Sensor Network**
   - Fill Level Sensors (ultrasonic)
   - Temperature Monitoring
   - Odor Detection
   - Battery Status

3. **Time Series Data**
   - Sensor readings every 5 minutes
   - 288 readings per sensor per day
   - 30 days of historical data

4. **Operational Data**
   - Collection Routes
   - Pickup Schedules
   - Alert Management
   - Maintenance Records

## Configuration

Edit `config.yaml` to adjust:

```yaml
counts:
  districts: 10                    # City districts
  bins: 1000                       # Number of smart bins
  sensors_per_bin: 4               # Sensor types per bin
  trucks: 50                       # Collection vehicles
  drivers: 75                      # Driver pool
  days_of_data: 30                 # Historical period
  readings_per_sensor_per_day: 288 # 5-minute intervals

date_ranges:
  historical_start: "2025-01-01"
  historical_end: "2025-01-31"
  installation_start: "2023-01-01"  # Bin installation period
  installation_end: "2024-12-31"
```

### Bin Type Distribution

- **General Waste (60%)**: Standard household waste
- **Recycling (25%)**: Recyclable materials
- **Organic (10%)**: Compostable waste
- **Paper (3%)**: Paper recycling
- **Glass (1%)**: Glass containers
- **Hazardous (1%)**: Special handling required

### Location Types

- **Residential (40%)**: Apartment complexes, neighborhoods
- **Commercial (25%)**: Shopping areas, offices
- **Public (15%)**: Streets, squares
- **Parks (8%)**: Recreational areas
- **Schools (7%)**: Educational institutions
- **Industrial (3%)**: Factory zones
- **Hospitals (2%)**: Medical facilities

### Sensor Types

1. **Fill Level**
   - Range: 0-100%
   - Accuracy: ±2%
   - Alert thresholds: 80% (warning), 90% (critical)

2. **Temperature**
   - Range: -10°C to 60°C
   - Seasonal variations included
   - Fire detection capability

3. **Odor Level**
   - Scale: 0-100
   - Increases with fill level and temperature
   - Health hazard alerts

4. **Battery Status**
   - Solar-powered with backup
   - Daily degradation: 0.1%
   - Low battery alerts: <20%

## Usage

```bash
cd generators/iot_bins
python generate.py
```

## Output Files

All files are generated in the `output/` directory:

### Static Data

- `districts.csv` - District definitions and boundaries
- `bins.csv` - Bin locations, types, and capacities
- `sensors.csv` - Sensor configurations per bin
- `trucks.csv` - Vehicle fleet details
- `drivers.csv` - Driver profiles and assignments

### Time Series Data

- `sensor_readings.csv` - All sensor measurements
- `fill_level_readings.csv` - Fill level time series
- `alerts.csv` - Generated alerts and warnings
- `collections.csv` - Pickup events and routes

### Operational Data

- `routes.csv` - Optimized collection routes
- `maintenance.csv` - Bin and sensor maintenance
- `incidents.csv` - Overflow and malfunction events

### Metadata

- `generation_summary.json` - Statistics and configuration

## Data Patterns

### Fill Rate Patterns by Location

| Location Type | Daily Fill Rate | Peak Hours | Weekly Pattern |
|--------------|----------------|------------|----------------|
| Residential | 150L ± 50L | 7-9 AM, 6-8 PM | Higher weekends |
| Commercial | 300L ± 100L | 12-2 PM, 5-7 PM | Lower weekends |
| Industrial | 500L ± 150L | 8 AM - 5 PM | Weekdays only |
| Parks | 100L ± 40L | 12-6 PM | Peak weekends |
| Schools | 200L ± 80L | 8 AM - 3 PM | Weekdays only |
| Hospitals | 400L ± 100L | Constant | Consistent |
| Public | 180L ± 60L | Variable | Event-driven |

### Sensor Reading Patterns

- **Fill Level**: Gradual increase with sudden drops (collections)
- **Temperature**: Daily cycles with seasonal trends
- **Odor**: Correlates with fill level and temperature
- **Battery**: Slow decline with solar recharge during day

### Alert Generation

| Alert Type | Threshold | Frequency | Priority |
|-----------|-----------|-----------|----------|
| Fill Warning | 80% | ~20/day | Medium |
| Fill Critical | 90% | ~5/day | High |
| Battery Low | 20% | ~10/day | Low |
| Battery Critical | 10% | ~2/day | Medium |
| Temperature High | 40°C | Seasonal | High |
| Odor High | 70/100 | ~15/day | Medium |
| Sensor Offline | 2 hours | ~5/day | Low |

## Realistic Features

### Geographic Distribution
- Clustered around city center
- Higher density in commercial areas
- GPS coordinates within city radius
- Realistic street-level placement

### Temporal Patterns
- Weekend vs weekday variations
- Holiday adjustments
- Seasonal effects
- Event-based spikes

### Sensor Behavior
- Occasional offline periods (2%)
- Error readings (0.5%)
- Battery degradation
- Weather impact on readings

### Collection Optimization
- Route efficiency calculations
- Dynamic scheduling based on fill levels
- Priority collections for critical alerts
- Fuel consumption tracking

## Performance Notes

- Generation time: 5-10 minutes for default config
- Memory usage: ~500MB for 30 days of data
- File sizes: ~200MB total CSV output
- Scalable to 10,000 bins

## Use Cases

1. **Route Optimization**
   - Collection path algorithms
   - Fuel efficiency studies
   - Dynamic scheduling systems

2. **Predictive Analytics**
   - Fill rate predictions
   - Maintenance forecasting
   - Demand planning

3. **Real-time Monitoring**
   - Dashboard development
   - Alert system testing
   - KPI tracking

4. **Environmental Impact**
   - Carbon footprint analysis
   - Recycling rate optimization
   - Waste reduction strategies

## Sample Queries

After importing the data:

```sql
-- Current fill levels by district
SELECT
    d.name as district,
    AVG(sr.value) as avg_fill_level,
    COUNT(CASE WHEN sr.value > 80 THEN 1 END) as bins_near_full
FROM sensor_readings sr
JOIN sensors s ON sr.sensor_id = s.sensor_id
JOIN bins b ON s.bin_id = b.bin_id
JOIN districts d ON b.district_id = d.district_id
WHERE s.sensor_type = 'fill_level'
  AND sr.timestamp > NOW() - INTERVAL 1 HOUR
GROUP BY d.district_id;

-- Collection efficiency metrics
SELECT
    DATE(collection_time) as date,
    COUNT(*) as collections,
    AVG(fill_level_at_collection) as avg_fill_at_pickup,
    SUM(volume_collected) as total_volume
FROM collections
GROUP BY DATE(collection_time);
```

## Advanced Features

### Smart Routing
- Considers current fill levels
- Traffic patterns integration
- Fuel optimization
- Priority bin handling

### Anomaly Detection
- Unusual fill patterns
- Sensor malfunction detection
- Vandalism indicators
- Fire hazard alerts

### Sustainability Metrics
- Recycling rates by area
- Carbon emission tracking
- Overflow prevention
- Waste reduction trends

## Customization

Extend the generator for:

1. **Additional Sensors**: Motion, weight, RFID
2. **Weather Integration**: Impact on fill rates
3. **Event Management**: Festivals, holidays
4. **Multi-city**: Expand geographic scope
5. **Cost Modeling**: Operational expense tracking

## Notes

- All data is synthetic and for testing purposes
- GPS coordinates are randomly distributed
- No real city data is used
- Suitable for smart city demonstrations
- Complies with IoT data standards