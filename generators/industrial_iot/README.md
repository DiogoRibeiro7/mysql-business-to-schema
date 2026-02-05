# Industrial IoT Manufacturing Data Generator

## Overview

Generates synthetic data for Industry 4.0 smart manufacturing systems including production lines, machine sensors, OEE metrics, quality control, and predictive maintenance.

## Features

### Data Generated

1. **Factory Infrastructure**
   - Factories (3 facilities)
   - Production Lines (12 lines, 4 per factory)
   - Machines (60 units, 5 per line)
   - Sensors (8 per machine, 480 total)

2. **Production Management**
   - Work Orders (50 per day)
   - Product Definitions (20 SKUs)
   - Production Schedules
   - Shift Management (2-3 shifts)

3. **Sensor Telemetry**
   - Temperature monitoring
   - Vibration analysis
   - Pressure readings
   - Power consumption
   - Speed/RPM tracking
   - Humidity levels
   - Current draw
   - Cycle counting

4. **Quality & Performance**
   - OEE metrics (Availability, Performance, Quality)
   - Defect tracking
   - Downtime events
   - Maintenance records
   - Operator performance

## Configuration

Edit `config.yaml` to adjust:

```yaml
counts:
  factories: 3                # Manufacturing facilities
  production_lines: 12        # Total production lines
  machines: 60               # Total machines
  sensors_per_machine: 8     # Sensors on each machine
  operators: 100             # Workforce size
  products: 20               # Product catalog
  work_orders_per_day: 50    # Daily production orders
  days_of_data: 7            # Historical period
```

### Factory Types

| Location | Type | Shifts | Focus Area |
|----------|------|--------|------------|
| Detroit Plant | Automotive | 3 | Heavy manufacturing |
| Phoenix Facility | Electronics | 2 | Precision assembly |
| Atlanta Factory | Consumer Goods | 3 | High volume production |

### Machine Types Distribution

| Type | Percentage | Production Rate | Key Metrics |
|------|------------|----------------|-------------|
| CNC Mill | 20% | 10-30 units/hr | Precision, tool wear |
| Injection Mold | 15% | 100-500 units/hr | Cycle time, temperature |
| Assembly Robot | 20% | 50-200 units/hr | Speed, accuracy |
| Conveyor | 10% | Continuous | Throughput, jams |
| Packaging | 10% | 200-1000 units/hr | Speed, waste |
| Quality Inspection | 10% | Variable | Accuracy, rejects |
| Welding Robot | 10% | 20-60 units/hr | Quality, consumables |
| 3D Printer | 5% | 1-5 units/hr | Layer quality, material |

### Sensor Configuration

| Sensor | Unit | Normal Range | Critical | Sample Rate |
|--------|------|-------------|----------|-------------|
| Temperature | °C | 60-80 | >95 | 5 sec |
| Vibration | mm/s | 0.5-4.5 | >7.0 | 1 sec |
| Pressure | bar | 4-6 | >8 | 5 sec |
| Current | amps | 10-30 | >40 | 1 sec |
| Speed | RPM | 1000-3000 | >3500 | 1 sec |
| Humidity | % | 30-60 | >80 | 30 sec |
| Power | kW | 5-25 | >30 | 5 sec |
| Cycle Count | cycles | 0-1M | >1M | 60 sec |

## Usage

```bash
cd generators/industrial_iot
python generate.py
```

## Output Files

All files are generated in the `output/` directory:

### Infrastructure Data

- `factories.csv` - Facility information
- `production_lines.csv` - Line configurations
- `machines.csv` - Machine specifications
- `sensors.csv` - Sensor deployments
- `operators.csv` - Workforce data

### Production Data

- `products.csv` - Product catalog
- `work_orders.csv` - Production orders
- `production_runs.csv` - Actual production records
- `shift_schedules.csv` - Shift assignments

### Time Series Data

- `sensor_readings.csv` - Raw sensor telemetry
- `machine_states.csv` - Machine status over time
- `oee_metrics.csv` - Hourly OEE calculations
- `alarms.csv` - Alert and alarm events

### Quality Data

- `quality_inspections.csv` - Quality check results
- `defects.csv` - Defect records
- `rework.csv` - Rework operations
- `scrap.csv` - Scrap and waste tracking

### Maintenance Data

- `downtime_events.csv` - Unplanned downtime
- `maintenance_records.csv` - Maintenance activities
- `spare_parts.csv` - Parts inventory
- `predictive_alerts.csv` - ML-based predictions

### Metadata

- `generation_summary.json` - Statistics and configuration

## Data Patterns

### OEE Metrics

**Target vs Actual Performance:**

| Metric | Target | Morning Shift | Afternoon Shift | Night Shift |
|--------|--------|--------------|-----------------|-------------|
| Availability | 90% | 88-94% | 85-92% | 82-90% |
| Performance | 95% | 92-98% | 90-96% | 88-94% |
| Quality | 99% | 97-99.5% | 96-99% | 95-98.5% |
| **OEE** | **85%** | **79-91%** | **74-87%** | **70-83%** |

### Downtime Categories

- **Planned Maintenance (10%)**: Scheduled preventive maintenance
- **Equipment Failure (35%)**: Mechanical/electrical failures
- **Changeover (20%)**: Product changeover time
- **Material Shortage (15%)**: Supply chain issues
- **Quality Issues (10%)**: Production holds for quality
- **Operator Unavailable (5%)**: Staffing gaps
- **Other (5%)**: Miscellaneous causes

### Production Patterns

**Daily Production Cycles:**
- Startup (6-7 AM): 60% efficiency
- Morning peak (8 AM-12 PM): 95% efficiency
- Lunch slowdown (12-1 PM): 70% efficiency
- Afternoon run (1-5 PM): 90% efficiency
- Shift change (5-6 PM): 50% efficiency
- Evening production (6-10 PM): 85% efficiency
- Night shift (10 PM-6 AM): 80% efficiency

### Sensor Anomaly Patterns

| Anomaly Type | Frequency | Duration | Impact |
|-------------|-----------|----------|--------|
| Temperature spike | 2-3/day | 5-15 min | Quality risk |
| Vibration increase | 1-2/day | 30-60 min | Maintenance need |
| Pressure drop | 3-4/day | 2-5 min | Performance loss |
| Power surge | 1/day | <1 min | Equipment risk |
| Speed variation | 5-8/day | 5-10 min | Quality impact |

## Realistic Features

### Predictive Maintenance Indicators
- Gradual vibration increase before failure
- Temperature trending upward
- Power consumption anomalies
- Cycle time degradation
- Tool wear patterns

### Quality Correlations
- Temperature affects product quality
- Speed impacts defect rates
- Humidity influences material properties
- Vibration correlates with precision

### Shift Performance Variations
- Morning shift: Highest performance
- Afternoon: Moderate decline
- Night shift: Lowest performance
- Monday: Startup inefficiencies
- Friday: End-of-week fatigue

### Supply Chain Integration
- Just-in-time material delivery
- Vendor quality tracking
- Inventory optimization
- Lead time management

## Performance Notes

- Generation time: 5-10 minutes
- Memory usage: ~400MB
- CSV output: ~300MB for 7 days
- Sensor data: ~100k readings/day

## Use Cases

1. **OEE Optimization**
   - Performance analysis
   - Bottleneck identification
   - Shift comparison
   - Best practice identification

2. **Predictive Maintenance**
   - Failure prediction models
   - Maintenance scheduling
   - Spare parts optimization
   - MTBF/MTTR analysis

3. **Quality Control**
   - Defect pattern analysis
   - Root cause analysis
   - SPC implementation
   - Six Sigma projects

4. **Energy Management**
   - Power consumption optimization
   - Peak demand management
   - Energy cost reduction
   - Carbon footprint tracking

## Sample Queries

After importing the data:

```sql
-- Current OEE by production line
SELECT
    pl.line_name,
    AVG(oee.availability) * 100 as availability_pct,
    AVG(oee.performance) * 100 as performance_pct,
    AVG(oee.quality) * 100 as quality_pct,
    AVG(oee.availability * oee.performance * oee.quality) * 100 as oee_pct
FROM oee_metrics oee
JOIN production_lines pl ON oee.line_id = pl.line_id
WHERE oee.timestamp > NOW() - INTERVAL 24 HOUR
GROUP BY pl.line_id
ORDER BY oee_pct DESC;

-- Machine health score based on sensor readings
SELECT
    m.machine_name,
    m.machine_type,
    AVG(CASE WHEN s.sensor_type = 'vibration'
             AND s.value > 4.5 THEN 0 ELSE 1 END) as vibration_health,
    AVG(CASE WHEN s.sensor_type = 'temperature'
             AND s.value > 85 THEN 0 ELSE 1 END) as temperature_health,
    COUNT(a.alarm_id) as alarm_count_24h
FROM machines m
LEFT JOIN sensor_readings s ON m.machine_id = s.machine_id
    AND s.timestamp > NOW() - INTERVAL 24 HOUR
LEFT JOIN alarms a ON m.machine_id = a.machine_id
    AND a.timestamp > NOW() - INTERVAL 24 HOUR
GROUP BY m.machine_id
HAVING vibration_health < 0.8 OR temperature_health < 0.8
ORDER BY vibration_health, temperature_health;

-- Production efficiency by product and shift
SELECT
    p.product_name,
    s.shift_type,
    COUNT(pr.run_id) as runs,
    SUM(pr.quantity_produced) as total_produced,
    AVG(pr.cycle_time_seconds) as avg_cycle_time,
    SUM(pr.quantity_defective) / SUM(pr.quantity_produced) * 100 as defect_rate
FROM production_runs pr
JOIN products p ON pr.product_id = p.product_id
JOIN shift_schedules s ON pr.shift_id = s.shift_id
WHERE pr.run_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
GROUP BY p.product_id, s.shift_type
ORDER BY defect_rate;
```

## Advanced Features

### Digital Twin Integration
- Real-time machine simulation
- What-if scenario analysis
- Virtual commissioning
- Process optimization

### AI/ML Applications
- Anomaly detection algorithms
- Quality prediction models
- Demand forecasting
- Resource optimization

### MES Integration
- Work order management
- Inventory tracking
- Traceability
- Compliance reporting

### Industry 4.0 Standards
- OPC UA compliance
- ISA-95 hierarchy
- MQTT messaging
- RESTful APIs

## Customization

Extend the generator for:

1. **Additional Sensors**: Sound, camera, gas detection
2. **Complex Products**: Multi-stage assembly
3. **Supply Chain**: Vendor integration
4. **Compliance**: FDA, ISO tracking
5. **Sustainability**: Carbon, waste metrics

## Notes

- Follows ISA-95 and MESA standards
- Compatible with major MES/SCADA systems
- Realistic sensor noise and drift
- Suitable for POCs and demos
- No proprietary data included