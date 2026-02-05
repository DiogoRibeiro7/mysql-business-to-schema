# Smart Agriculture IoT Data Generator

## Overview

Generates synthetic data for precision agriculture systems including crop monitoring, livestock tracking, irrigation management, weather stations, and yield optimization.

## Features

### Data Generated

1. **Farm Infrastructure**
   - Farms (5 operations)
   - Fields (20 total, 4 per farm)
   - Zones (60 total, 3 per field)
   - Sensors (240 IoT devices)

2. **Crop Management**
   - Crop Types (10 varieties)
   - Growth Stages
   - Planting/Harvest Records
   - Yield Predictions

3. **Livestock Tracking**
   - Animals (200 head)
   - Health Monitoring
   - Feed Tracking
   - Milk Production (dairy)

4. **Environmental Monitoring**
   - Soil moisture, temperature, pH
   - Air temperature and humidity
   - Light intensity
   - Rainfall measurement
   - Wind speed

5. **Irrigation & Resource Management**
   - Irrigation Events (50 per day)
   - Water Usage
   - Fertilizer Application
   - Pesticide Tracking

## Configuration

Edit `config.yaml` to adjust:

```yaml
counts:
  farms: 5                      # Number of farms
  fields: 20                    # Total fields (4 per farm)
  zones: 60                     # Total zones (3 per field)
  sensors: 240                  # IoT sensors (4 per zone)
  crops: 10                     # Crop varieties
  animals: 200                  # Livestock count
  irrigation_events_per_day: 50 # Irrigation activities
  days_of_data: 7               # Historical period

date_ranges:
  planting_season_start: "2024-03-01"
  harvest_season_end: "2024-11-30"
  data_start: "2025-01-25"
  data_end: "2025-02-01"
```

### Farm Type Distribution

| Type | Percentage | Focus | Technology Level |
|------|------------|-------|-----------------|
| Crop Farm | 40% | Grain/vegetables | High automation |
| Dairy Farm | 20% | Milk production | IoT monitoring |
| Mixed Farm | 20% | Crops + livestock | Moderate tech |
| Orchard | 10% | Fruit trees | Precision irrigation |
| Greenhouse | 10% | Controlled environment | Full automation |

### Sensor Network

| Sensor Type | Unit | Optimal Range | Sampling Rate | Purpose |
|------------|------|---------------|---------------|---------|
| Soil Moisture | % | 40-60% | 15 min | Irrigation timing |
| Soil Temperature | °C | 18-24°C | 30 min | Planting decisions |
| Soil pH | pH | 6.0-7.0 | 60 min | Fertilizer needs |
| Air Temperature | °C | 20-28°C | 5 min | Growth monitoring |
| Humidity | % | 50-70% | 5 min | Disease prevention |
| Light Intensity | lux | 30k-50k | 10 min | Photosynthesis |
| Rainfall | mm | 0-10mm | 60 min | Water management |
| Wind Speed | km/h | 0-20 | 5 min | Spray conditions |

### Crop Varieties

| Crop | Growth Days | Water Needs | Optimal Temp | Yield/Hectare |
|------|------------|-------------|--------------|---------------|
| Wheat | 120 | Medium | 15-25°C | 3-5 tons |
| Corn | 100 | High | 20-30°C | 8-12 tons |
| Soybeans | 90 | Medium | 20-28°C | 2-4 tons |
| Rice | 130 | Very High | 25-32°C | 5-7 tons |
| Potatoes | 80 | Medium | 15-20°C | 20-40 tons |
| Tomatoes | 70 | High | 20-26°C | 40-80 tons |
| Lettuce | 45 | Low | 15-20°C | 20-30 tons |
| Strawberries | 60 | Medium | 18-24°C | 10-20 tons |
| Apples | Perennial | Medium | 18-24°C | 30-50 tons |
| Grapes | Perennial | Low | 20-30°C | 10-15 tons |

## Usage

```bash
cd generators/smart_agriculture
python generate.py
```

## Output Files

All files are generated in the `output/` directory:

### Infrastructure Data

- `farms.csv` - Farm details and locations
- `fields.csv` - Field boundaries and soil types
- `zones.csv` - Zone definitions within fields
- `sensors.csv` - Sensor deployments and calibration

### Crop Management

- `crops.csv` - Crop type definitions
- `planting_records.csv` - Planting history
- `growth_stages.csv` - Current growth status
- `harvest_records.csv` - Yield data
- `crop_health.csv` - Disease/pest monitoring

### Livestock Data

- `animals.csv` - Animal registry
- `health_records.csv` - Veterinary data
- `feed_logs.csv` - Feed consumption
- `milk_production.csv` - Daily milk yields

### Environmental Data

- `sensor_readings.csv` - All sensor measurements
- `weather_data.csv` - Weather station readings
- `soil_analysis.csv` - Soil test results
- `water_quality.csv` - Irrigation water tests

### Operations Data

- `irrigation_events.csv` - Water application records
- `fertilizer_applications.csv` - Nutrient management
- `pesticide_applications.csv` - Pest control
- `equipment_usage.csv` - Machinery tracking

### Analytics

- `yield_predictions.csv` - ML-based forecasts
- `resource_efficiency.csv` - Water/fertilizer ROI
- `cost_analysis.csv` - Economic metrics

### Metadata

- `generation_summary.json` - Statistics and configuration

## Data Patterns

### Irrigation Patterns

**Smart Irrigation Triggers:**
- Soil moisture < 35%: Immediate irrigation
- Forecast rain < 24h: Postpone irrigation
- Temperature > 35°C: Increase frequency
- Growth stage critical: Priority irrigation

**Water Usage by Crop:**
| Crop | Daily Water (L/m²) | Peak Season | Efficiency |
|------|-------------------|-------------|------------|
| Rice | 10-15 | Flowering | 60% |
| Corn | 5-8 | Tasseling | 75% |
| Wheat | 3-5 | Grain filling | 80% |
| Vegetables | 4-7 | Fruiting | 85% |

### Growth Stage Monitoring

| Stage | Duration | Key Metrics | Interventions |
|-------|----------|-------------|---------------|
| Germination | 5-10 days | Soil moisture, temp | Irrigation |
| Vegetative | 20-40 days | Light, nutrients | Fertilizer |
| Flowering | 10-20 days | Temperature, water | Pest control |
| Fruiting | 20-30 days | Water, nutrients | Support/prune |
| Maturity | 10-20 days | Moisture, weather | Harvest timing |

### Livestock Patterns

**Dairy Production:**
- Morning milking: 60% of daily yield
- Evening milking: 40% of daily yield
- Peak production: Month 3-6 of lactation
- Average: 25-35 liters/cow/day

**Health Monitoring:**
- Temperature: 38.5°C ± 0.5°C
- Heart rate: 60-80 bpm
- Activity level: 8-12 hours/day
- Feed intake: 15-20 kg/day

### Weather Impact

| Condition | Impact on Yield | Management Action |
|-----------|----------------|-------------------|
| Drought | -30% to -50% | Increase irrigation |
| Excessive rain | -20% to -30% | Improve drainage |
| Heat wave | -15% to -25% | Shade nets, cooling |
| Frost | -40% to -60% | Frost protection |
| Optimal | +10% to +20% | Maintain conditions |

## Realistic Features

### Precision Agriculture
- Variable rate application
- GPS-guided operations
- Drone imagery integration
- Satellite data correlation
- AI-powered recommendations

### Sustainability Metrics
- Water use efficiency
- Carbon sequestration
- Soil health index
- Biodiversity score
- Chemical reduction

### Economic Optimization
- Cost per yield unit
- ROI by field/crop
- Market price integration
- Labor efficiency
- Equipment utilization

### Compliance & Certification
- Organic certification tracking
- GAP compliance
- Water rights management
- Pesticide regulations
- Traceability records

## Performance Notes

- Generation time: 3-5 minutes
- Memory usage: ~250MB
- CSV output: ~150MB for 7 days
- Sensor readings: ~50k/day

## Use Cases

1. **Yield Optimization**
   - Predictive modeling
   - Resource allocation
   - Variety selection
   - Planting optimization

2. **Resource Management**
   - Water conservation
   - Fertilizer efficiency
   - Energy optimization
   - Labor planning

3. **Risk Management**
   - Weather impact analysis
   - Pest/disease prediction
   - Insurance claims
   - Market timing

4. **Sustainability Reporting**
   - Carbon footprint
   - Water usage reports
   - Chemical reduction
   - Biodiversity impact

## Sample Queries

After importing the data:

```sql
-- Current field conditions and irrigation needs
SELECT
    f.field_name,
    z.zone_name,
    AVG(CASE WHEN s.sensor_type = 'soil_moisture' THEN sr.value END) as avg_moisture,
    AVG(CASE WHEN s.sensor_type = 'soil_temperature' THEN sr.value END) as avg_temp,
    CASE
        WHEN AVG(CASE WHEN s.sensor_type = 'soil_moisture' THEN sr.value END) < 35
        THEN 'Immediate'
        WHEN AVG(CASE WHEN s.sensor_type = 'soil_moisture' THEN sr.value END) < 40
        THEN 'Soon'
        ELSE 'Adequate'
    END as irrigation_need
FROM fields f
JOIN zones z ON f.field_id = z.field_id
JOIN sensors s ON z.zone_id = s.zone_id
JOIN sensor_readings sr ON s.sensor_id = sr.sensor_id
WHERE sr.timestamp > NOW() - INTERVAL 1 HOUR
GROUP BY f.field_id, z.zone_id
ORDER BY irrigation_need DESC;

-- Crop yield prediction vs actual
SELECT
    c.crop_name,
    f.field_name,
    pr.planted_area_hectares,
    pr.expected_yield_kg,
    hr.actual_yield_kg,
    (hr.actual_yield_kg - pr.expected_yield_kg) / pr.expected_yield_kg * 100 as variance_pct
FROM planting_records pr
JOIN harvest_records hr ON pr.planting_id = hr.planting_id
JOIN crops c ON pr.crop_id = c.crop_id
JOIN fields f ON pr.field_id = f.field_id
WHERE hr.harvest_date >= DATE_SUB(NOW(), INTERVAL 30 DAY);

-- Water efficiency by irrigation method
SELECT
    ie.irrigation_method,
    COUNT(*) as events,
    SUM(ie.water_amount_liters) as total_water,
    AVG(ie.duration_minutes) as avg_duration,
    SUM(ie.water_amount_liters) / SUM(z.area_hectares) as liters_per_hectare
FROM irrigation_events ie
JOIN zones z ON ie.zone_id = z.zone_id
WHERE ie.timestamp >= DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY ie.irrigation_method
ORDER BY liters_per_hectare;
```

## Advanced Features

### AI/ML Integration
- Yield prediction models
- Disease detection
- Optimal harvest timing
- Market price forecasting
- Weather pattern analysis

### Drone Integration
- NDVI mapping
- Crop health assessment
- Field surveying
- Pest detection
- Irrigation monitoring

### Blockchain Traceability
- Seed-to-sale tracking
- Organic certification
- Supply chain transparency
- Quality assurance

### IoT Platform
- Real-time monitoring
- Alert management
- Remote control
- Data analytics
- Mobile apps

## Customization

Extend the generator for:

1. **Aquaculture**: Fish farming metrics
2. **Vertical Farming**: Indoor agriculture
3. **Beekeeping**: Hive monitoring
4. **Forestry**: Tree growth tracking
5. **Cannabis**: Controlled cultivation

## Notes

- Based on real agricultural practices
- Follows precision agriculture standards
- Weather patterns are realistic
- Suitable for AgTech demonstrations
- No proprietary farming data