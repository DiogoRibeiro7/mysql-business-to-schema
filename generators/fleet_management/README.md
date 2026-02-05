# Fleet Management System Data Generator

## Overview

Generates comprehensive synthetic data for a commercial fleet management system including GPS tracking, driver behavior monitoring, vehicle diagnostics, compliance tracking, and route optimization.

## Features

### Data Generated

1. **Fleet Assets**

  - Vehicles (100 units)
  - Drivers (150 operators)
  - Depots (5 locations)
  - Routes (20 predefined)

2. **GPS Tracking**

  - Position updates every 5 seconds
  - Speed and heading
  - Geofence events
  - Route adherence

3. **Driver Behavior**

  - Harsh events (brake, acceleration, cornering)
  - Speeding violations
  - Idle time tracking
  - HOS (Hours of Service) compliance

4. **Vehicle Diagnostics**

  - Engine parameters (OBD-II)
  - Fuel consumption
  - Maintenance alerts
  - Diagnostic trouble codes (DTC)

5. **Operations Management**

  - Trip logs
  - Stop events
  - Delivery confirmations
  - Fuel transactions

## Configuration

Edit `config.yaml` to adjust:

```yaml
counts:
  vehicles: 100                    # Fleet size
  drivers: 150                     # Driver pool
  depots: 5                        # Base locations
  routes: 20                       # Predefined routes
  trips_per_vehicle_per_day: 3     # Daily utilization
  days_of_data: 7                  # Historical period
  gps_frequency_seconds: 5         # Tracking interval

date_ranges:
  fleet_start: "2020-01-01"        # Fleet inception
  data_start: "2025-01-25"         # Data period start
  data_end: "2025-02-01"           # Data period end
```

### Vehicle Types Distribution

Type         | Percentage | Typical Use        | Capacity   | Fuel Economy
------------ | ---------- | ------------------ | ---------- | ------------
Delivery Van | 40%        | Last-mile delivery | 1,500 lbs  | 20-25 mpg
Box Truck    | 30%        | Regional delivery  | 5,000 lbs  | 12-15 mpg
Semi Truck   | 15%        | Long-haul freight  | 40,000 lbs | 5-7 mpg
Refrigerated | 10%        | Cold chain         | 3,000 lbs  | 10-12 mpg
Flatbed      | 5%         | Construction       | 10,000 lbs | 8-10 mpg

### Driver Experience Levels

Level       | Experience | Distribution | Safety Score | Efficiency
----------- | ---------- | ------------ | ------------ | ----------
Rookie      | 0-2 years  | 20%          | 75-85        | Learning
Regular     | 2-5 years  | 35%          | 80-90        | Competent
Experienced | 5-10 years | 30%          | 85-95        | Skilled
Veteran     | 10+ years  | 15%          | 90-98        | Expert

### License Classes

- **CDL-A (30%)**: Interstate commerce, semi-trucks
- **CDL-B (40%)**: Large trucks, buses, local routes
- **Regular (30%)**: Vans, light trucks under 26,000 lbs

## Usage

```bash
cd generators/fleet_management
python generate.py
```

## Output Files

All files are generated in the `output/` directory:

### Fleet Data

- `vehicles.csv` - Vehicle registry with specs
- `drivers.csv` - Driver profiles and licenses
- `depots.csv` - Base locations and facilities
- `routes.csv` - Predefined route definitions

### GPS & Telematics

- `gps_positions.csv` - Real-time location data
- `trips.csv` - Trip summaries
- `stops.csv` - Stop events and durations
- `geofence_events.csv` - Zone entry/exit

### Driver Performance

- `driver_events.csv` - Harsh driving events
- `speeding_violations.csv` - Speed limit violations
- `driver_scores.csv` - Daily safety scores
- `hos_logs.csv` - Hours of service records

### Vehicle Health

- `engine_diagnostics.csv` - OBD-II parameters
- `fuel_consumption.csv` - Fuel usage tracking
- `maintenance_alerts.csv` - Service requirements
- `dtc_codes.csv` - Diagnostic trouble codes

### Operational Data

- `deliveries.csv` - Delivery confirmations
- `fuel_transactions.csv` - Refueling records
- `idle_events.csv` - Excessive idle tracking
- `route_deviations.csv` - Off-route events

### Compliance

- `dvir_reports.csv` - Daily vehicle inspection
- `eld_logs.csv` - Electronic logging device
- `incidents.csv` - Accidents and violations
- `certifications.csv` - License renewals

### Metadata

- `generation_summary.json` - Statistics and configuration

## Data Patterns

### Driving Patterns by Road Type

Road Type | Speed Range | Typical | Events/100mi   | Fuel Economy
--------- | ----------- | ------- | -------------- | ------------
Highway   | 55-75 mph   | 65 mph  | Low (5-10)     | Best
Urban     | 15-45 mph   | 25 mph  | High (20-30)   | Worst
Rural     | 35-55 mph   | 45 mph  | Medium (10-15) | Moderate

### Event Rates (per 100 miles)

- **Harsh Braking**: 2.5 events
- **Harsh Acceleration**: 2.0 events
- **Harsh Cornering**: 1.5 events
- **Speeding**: 3.0 events
- **Excessive Idle**: 5.0 events

### Stop Patterns by Vehicle Type

Vehicle Type | Stops/Trip | Stop Duration | Daily Mileage
------------ | ---------- | ------------- | -------------
Delivery Van | 5-20       | 5-15 min      | 80-150 miles
Box Truck    | 3-10       | 10-20 min     | 100-200 miles
Semi Truck   | 1-3        | 20-45 min     | 300-500 miles
Refrigerated | 2-8        | 15-30 min     | 150-250 miles
Flatbed      | 1-4        | 30-60 min     | 100-180 miles

### Fuel Consumption Patterns

**Factors Affecting Fuel Economy:**

- Speed: -0.5% mpg per mph over 60
- Idle: 0.5 gallons/hour
- Load: -2% mpg per 1,000 lbs
- Weather: -10% in extreme conditions
- Maintenance: -5% if overdue

### HOS Compliance (ELD)

**Federal Regulations:**

- 11-hour driving limit
- 14-hour on-duty limit
- 30-minute break required after 8 hours
- 10-hour off-duty requirement
- 60/70-hour weekly limits

## Realistic Features

### GPS Accuracy

- Urban canyon effect simulation
- Signal loss in tunnels
- GPS drift when stationary
- Heading calculation from positions

### Driver Behavior Scoring

**Safety Score Components:**

- Harsh events: -5 points each
- Speeding: -3 points per minute
- Seat belt: -10 points if not worn
- Phone use: -15 points per event
- Base score: 100 points/day

### Vehicle Wear Patterns

- Mileage-based degradation
- Age-related issues
- Usage pattern impact
- Seasonal effects

### Route Optimization

- Traffic pattern consideration
- Delivery window constraints
- Driver hour limitations
- Vehicle capacity limits

## Performance Notes

- Generation time: 10-15 minutes (GPS data intensive)
- Memory usage: ~500MB
- CSV output: ~400MB for 7 days
- GPS points: ~2M for 100 vehicles/week

## Use Cases

1. **Fleet Optimization**

  - Route efficiency analysis
  - Vehicle utilization
  - Driver assignment
  - Fuel cost reduction

2. **Safety Management**

  - Driver coaching programs
  - Accident prevention
  - Insurance premium reduction
  - Compliance monitoring

3. **Predictive Maintenance**

  - Service scheduling
  - Part failure prediction
  - Downtime reduction
  - Cost optimization

4. **Customer Service**

  - Real-time tracking
  - ETA accuracy
  - Proof of delivery
  - Service quality metrics

## Sample Queries

After importing the data:

```sql
-- Fleet utilization by vehicle type
SELECT
    v.vehicle_type,
    COUNT(DISTINCT t.vehicle_id) as active_vehicles,
    COUNT(t.trip_id) as total_trips,
    AVG(t.distance_miles) as avg_trip_distance,
    SUM(t.distance_miles) as total_miles,
    AVG(t.fuel_consumed) as avg_fuel_per_trip
FROM vehicles v
LEFT JOIN trips t ON v.vehicle_id = t.vehicle_id
    AND t.start_time >= DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY v.vehicle_type
ORDER BY total_miles DESC;

-- Driver safety scores and rankings
SELECT
    d.driver_name,
    d.experience_years,
    COUNT(de.event_id) as total_events,
    SUM(CASE WHEN de.event_type = 'harsh_brake' THEN 1 ELSE 0 END) as harsh_brakes,
    SUM(CASE WHEN de.event_type = 'speeding' THEN 1 ELSE 0 END) as speeding_events,
    AVG(ds.safety_score) as avg_safety_score,
    RANK() OVER (ORDER BY AVG(ds.safety_score) DESC) as safety_rank
FROM drivers d
LEFT JOIN driver_events de ON d.driver_id = de.driver_id
    AND de.timestamp >= DATE_SUB(NOW(), INTERVAL 30 DAY)
LEFT JOIN driver_scores ds ON d.driver_id = ds.driver_id
    AND ds.date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY d.driver_id
ORDER BY avg_safety_score DESC;

-- Geofence compliance (depot departure/arrival times)
SELECT
    v.vehicle_number,
    g.geofence_name,
    DATE(g.timestamp) as date,
    MIN(CASE WHEN g.event_type = 'exit' THEN g.timestamp END) as first_departure,
    MAX(CASE WHEN g.event_type = 'enter' THEN g.timestamp END) as last_arrival,
    COUNT(CASE WHEN g.event_type = 'exit' THEN 1 END) as departures,
    COUNT(CASE WHEN g.event_type = 'enter' THEN 1 END) as arrivals
FROM geofence_events g
JOIN vehicles v ON g.vehicle_id = v.vehicle_id
WHERE g.geofence_type = 'depot'
    AND g.timestamp >= DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY v.vehicle_id, g.geofence_name, DATE(g.timestamp);

-- Maintenance prediction based on diagnostics
SELECT
    v.vehicle_number,
    v.odometer_miles,
    MAX(ed.coolant_temp) as max_coolant_temp,
    MIN(ed.oil_pressure) as min_oil_pressure,
    AVG(ed.engine_load) as avg_engine_load,
    COUNT(dtc.code) as dtc_count,
    CASE
        WHEN v.odometer_miles - v.last_service_miles > 5000 THEN 'Overdue'
        WHEN v.odometer_miles - v.last_service_miles > 4000 THEN 'Due Soon'
        ELSE 'OK'
    END as service_status
FROM vehicles v
LEFT JOIN engine_diagnostics ed ON v.vehicle_id = ed.vehicle_id
    AND ed.timestamp >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
LEFT JOIN dtc_codes dtc ON v.vehicle_id = dtc.vehicle_id
    AND dtc.timestamp >= DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY v.vehicle_id
HAVING service_status != 'OK' OR dtc_count > 0
ORDER BY service_status, dtc_count DESC;
```

## Advanced Features

### Real-time Tracking

- Live GPS updates
- Traffic integration
- Weather impact
- Dynamic ETA calculation

### Predictive Analytics

- Breakdown prediction
- Delivery time forecasting
- Fuel cost projection
- Driver turnover risk

### Integration Points

- ERP systems
- Customer portals
- Mobile driver apps
- Maintenance systems

### Compliance Automation

- Automatic HOS tracking
- DVIR digital forms
- IFTA reporting
- DOT audit preparation

## Customization

Extend the generator for:

1. **International**: Metric units, local regulations
2. **Specialized**: Hazmat, oversized loads
3. **Public Transit**: Bus routes, passenger counts
4. **Emergency**: Ambulance, fire response times
5. **Construction**: Equipment tracking, job sites

## Notes

- Follows FMCSA regulations
- Compatible with major telematics platforms
- Realistic driving patterns
- No real driver/vehicle data
- Suitable for demos and testing
