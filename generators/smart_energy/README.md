# Smart Energy Grid Data Generator

## Overview

Generates synthetic data for a multi-tenant smart energy management system with utilities, customers, smart meters, solar generation, EV charging, and demand response programs.

## Features

### Data Generated

1. **Infrastructure**

  - Utilities (3 energy providers)
  - Transformers (20 per utility)
  - Smart Meters (configurable, 100 default)
  - Grid topology and connectivity

2. **Customer Profiles**

  - Residential (70%)
  - Commercial (25%)
  - Industrial (5%)
  - Solar adoption tracking
  - EV ownership data

3. **Energy Data**

  - Consumption readings (15-minute intervals)
  - Solar generation data
  - EV charging sessions
  - Power quality metrics
  - Demand response events

4. **Operational Data**

  - Outage management
  - Transformer loading
  - Rate plans and pricing
  - Billing cycles

## Configuration

Edit `config.yaml` to adjust:

```yaml
counts:
  utilities: 3                      # Energy providers
  transformers_per_utility: 20      # Distribution transformers
  customers_per_utility: 500        # Customer accounts
  meters_to_generate: 100           # Limit for demo
  demand_response_events: 10        # DR events per period
  outages: 5                        # Simulated outages

date_ranges:
  days_of_data: 7                   # Historical period
  historical_start: "2025-01-25"
  historical_end: "2025-02-01"
```

### Customer Type Distribution

Type        | Percentage | Typical Load | Solar Adoption | EV Adoption
----------- | ---------- | ------------ | -------------- | -----------
Residential | 70%        | 0.5-4.0 kW   | 15%            | 10%
Commercial  | 25%        | 10-50 kW     | 25%            | 5%
Industrial  | 5%         | 100-500 kW   | 35%            | 2%

### Rate Plans

**Residential Options:**

- Standard fixed rate
- Time-of-Use (TOU)
- Tiered pricing

**Commercial Options:**

- Commercial standard
- Commercial TOU
- Demand charge

**Industrial Options:**

- Industrial demand
- Interruptible service
- Custom contracts

### Time-of-Use Pricing

Period         | Rate (¢/kWh) | Hours
-------------- | ------------ | -----------------------------------
Peak           | 25.0         | Summer: 2-8 PM, Winter: 5-9 PM
Mid-Peak       | 18.0         | Summer: 10 AM-2 PM, Winter: 7-10 AM
Off-Peak       | 12.0         | All other hours
Super Off-Peak | 8.0          | 12-6 AM

## Usage

```bash
cd generators/smart_energy
python generate.py
```

## Output Files

All files are generated in the `output/` directory:

### Infrastructure Data

- `utilities.csv` - Utility company information
- `transformers.csv` - Transformer specifications and locations
- `customers.csv` - Customer accounts and profiles
- `meters.csv` - Smart meter installations

### Time Series Data

- `meter_readings.csv` - Energy consumption (15-min intervals)
- `solar_generation.csv` - Solar production data
- `ev_sessions.csv` - EV charging events
- `power_quality.csv` - Voltage, frequency, THD metrics

### Operational Data

- `demand_response_events.csv` - DR program activations
- `outages.csv` - Power interruption records
- `transformer_loading.csv` - Real-time loading percentages
- `billing.csv` - Customer bills and payments

### Metadata

- `generation_summary.json` - Statistics and configuration

## Data Patterns

### Consumption Patterns

**Daily Load Profiles:**

- **Residential**: Morning peak (6-9 AM), evening peak (5-9 PM)
- **Commercial**: Business hours peak (9 AM-6 PM)
- **Industrial**: Constant base load with shift changes

**Seasonal Variations:**

- Summer: +20-50% (cooling)
- Winter: +10-30% (heating)
- Spring/Fall: -20% to normal

### Solar Generation

Customer Type | Capacity Range | Daily Pattern            | Weather Impact
------------- | -------------- | ------------------------ | --------------
Residential   | 3-10 kW        | Bell curve, peak at noon | -60% cloudy
Commercial    | 10-100 kW      | Extended plateau         | -60% cloudy
Industrial    | 100-1000 kW    | Consistent 8 AM-5 PM     | -60% cloudy

### EV Charging Patterns

- **Home Charging**: 6 PM-6 AM (Level 2, 7.2 kW)
- **Workplace**: 9 AM-5 PM (Level 2, 7.2-19.2 kW)
- **Public Fast**: Random times (Level 3, 50-150 kW)

### Demand Response

**Enrollment Rates:**

- Residential: 30%
- Commercial: 50%
- Industrial: 70%

**Event Types:**

- Critical Peak Pricing
- Emergency Load Reduction
- Economic Dispatch
- Test Events

## Realistic Features

### Multi-Tenant Architecture

- Utility-level isolation
- Shared infrastructure modeling
- Cross-tenant analytics support
- Regulatory compliance per utility

### Smart Meter Features

- Communication types (cellular, RF mesh, PLC)
- Real meter models (GE, Landis, Itron, Sensus)
- Realistic failure rates (0.5%)
- Firmware versions and upgrades

### Power Quality Metrics

- Voltage: 240V ± 5V
- Frequency: 60Hz ± 0.5Hz
- THD Voltage: < 5%
- THD Current: < 8%
- Power Factor: > 0.85

### Grid Reliability

- SAIDI/SAIFI calculations
- Outage cause tracking
- Restoration time modeling
- Affected customer counts

## Performance Notes

- Generation time: 2-5 minutes
- Memory usage: ~200MB
- CSV output: ~100MB for 7 days
- Scalable to 100,000 meters

## Use Cases

1. **Smart Grid Analytics**

  - Load forecasting
  - Peak demand management
  - Grid optimization
  - Loss detection

2. **Renewable Integration**

  - Solar forecasting
  - Net metering calculations
  - Virtual power plants
  - Grid stability analysis

3. **Customer Programs**

  - Time-of-use optimization
  - Demand response testing
  - Bill analysis tools
  - Energy efficiency programs

4. **EV Grid Impact**

  - Charging infrastructure planning
  - Load management strategies
  - V2G potential analysis
  - Fleet electrification

## Sample Queries

After importing the data:

```sql
-- Current demand by utility and customer type
SELECT
    u.name as utility,
    c.customer_type,
    COUNT(*) as customer_count,
    SUM(mr.consumption_kwh) as total_demand_kwh,
    AVG(mr.consumption_kwh) as avg_demand_kwh
FROM meter_readings mr
JOIN meters m ON mr.meter_id = m.meter_id
JOIN customers c ON m.customer_id = c.customer_id
JOIN utilities u ON c.utility_id = u.utility_id
WHERE mr.reading_time > NOW() - INTERVAL 15 MINUTE
GROUP BY u.utility_id, c.customer_type;

-- Solar generation vs consumption
SELECT
    DATE(sg.timestamp) as date,
    SUM(sg.generation_kwh) as total_solar_kwh,
    SUM(mr.consumption_kwh) as total_consumption_kwh,
    (SUM(sg.generation_kwh) / SUM(mr.consumption_kwh) * 100) as solar_percentage
FROM solar_generation sg
JOIN meter_readings mr ON sg.meter_id = mr.meter_id
    AND DATE(sg.timestamp) = DATE(mr.reading_time)
GROUP BY DATE(sg.timestamp);

-- Demand response performance
SELECT
    dre.event_id,
    dre.event_type,
    COUNT(drp.customer_id) as participants,
    SUM(drp.baseline_kw - drp.actual_kw) as total_reduction_kw,
    AVG((drp.baseline_kw - drp.actual_kw) / drp.baseline_kw * 100) as avg_reduction_pct
FROM demand_response_events dre
JOIN demand_response_participation drp ON dre.event_id = drp.event_id
GROUP BY dre.event_id;
```

## Advanced Features

### Predictive Analytics

- Load forecasting models
- Outage prediction
- Equipment failure analysis
- Customer churn prediction

### Grid Optimization

- Volt/VAR optimization
- Phase balancing
- Loss minimization
- Capacity planning

### Customer Insights

- Usage pattern clustering
- Bill prediction
- Energy efficiency scoring
- Program recommendations

## Customization

Extend the generator for:

1. **Battery Storage**: Add residential/commercial batteries
2. **Microgrids**: Island mode operations
3. **Weather Integration**: Temperature-based consumption
4. **Market Pricing**: Real-time energy markets
5. **Carbon Tracking**: Emissions monitoring

## Notes

- All data is synthetic for testing
- Follows utility industry standards
- Multi-tenant architecture ready
- Suitable for AMI/MDM systems
- Complies with energy data protocols
