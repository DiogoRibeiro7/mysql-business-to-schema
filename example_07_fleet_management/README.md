# Connected Fleet Management IoT System

## Overview

This example demonstrates a comprehensive fleet management system using IoT for vehicle tracking, driver behavior monitoring, predictive maintenance, route optimization, and compliance management.

## Business Context

Fleet operations face significant challenges:

- **Fuel Costs**: Largest operational expense, often 30-40% of total costs
- **Vehicle Downtime**: Unexpected breakdowns disrupt operations
- **Driver Safety**: Accidents cost lives and money
- **Route Efficiency**: Suboptimal routing wastes time and fuel
- **Compliance**: ELD, HOS, DVIR regulations
- **Asset Utilization**: Idle vehicles drain resources

This Fleet Management IoT solution provides:

- Real-time GPS tracking and geofencing
- Driver behavior scoring and coaching
- Predictive maintenance using OBD-II data
- Dynamic route optimization
- Electronic logging device (ELD) compliance
- Fuel consumption optimization

## Unique Fleet IoT Patterns

### Vehicle Telematics

- **CAN Bus Data**: Engine diagnostics via OBD-II
- **GPS Tracking**: Location, speed, heading
- **Accelerometer**: Harsh events (braking, acceleration, cornering)
- **Fuel Sensors**: Level, consumption, efficiency

### Driver Monitoring

- **Driving Events**: Speeding, harsh maneuvers, idle time
- **Hours of Service**: DOT compliance tracking
- **Driver Identification**: RFID/biometric authentication
- **Dashcam Integration**: Event-triggered recording

### Operational Data

- **Route Analytics**: Planned vs actual, delays
- **Cargo Monitoring**: Temperature, humidity, door sensors
- **Tire Pressure**: TPMS integration
- **Weight Sensors**: Load distribution, overweight detection

## Database Schema Highlights

### Core Entities

1. **Fleet Hierarchy**

  ```
  Company → Depots → Vehicles → Devices → Sensors
       → Drivers → Trips → Events
  ```

2. **Trip Lifecycle**

  ```
  Pre-trip → Dispatch → In-transit → Delivery → Post-trip
  ```

3. **Data Streams**

4. High-frequency GPS (1Hz)
5. Engine diagnostics (0.1Hz)
6. Driver events (event-driven)
7. Fuel consumption (continuous)

## Key Tables

### Fleet Management

- `vehicles` - Vehicle inventory and specifications
- `drivers` - Driver profiles and certifications
- `depots` - Facility locations
- `vehicle_assignments` - Driver-vehicle pairings

### Telematics Data

- `gps_positions` - Location tracking (partitioned)
- `engine_diagnostics` - OBD-II data
- `fuel_readings` - Consumption tracking
- `tire_pressure` - TPMS data

### Trip Management

- `trips` - Journey records
- `trip_stops` - Delivery/pickup points
- `trip_events` - Incidents during trips
- `driver_logs` - HOS compliance

### Maintenance

- `maintenance_schedules` - Service intervals
- `diagnostic_codes` - DTC alerts
- `service_history` - Completed maintenance
- `parts_inventory` - Spare parts tracking

### Compliance

- `eld_records` - Electronic logging
- `dvir_reports` - Pre/post-trip inspections
- `violations` - Compliance issues
- `certifications` - Driver qualifications

## Sample Queries

### 1\. Real-Time Fleet Status Dashboard

```sql
-- Current location and status of all vehicles
WITH latest_positions AS (
    SELECT
        v.vehicle_id,
        v.vehicle_number,
        v.plate_number,
        vt.type_name as vehicle_type,
        gp.latitude,
        gp.longitude,
        gp.speed_kmh,
        gp.heading,
        gp.timestamp,
        gp.address,
        ROW_NUMBER() OVER (PARTITION BY v.vehicle_id ORDER BY gp.timestamp DESC) as rn
    FROM vehicles v
    JOIN vehicle_types vt ON v.vehicle_type_id = vt.type_id
    JOIN gps_positions gp ON v.vehicle_id = gp.vehicle_id
    WHERE gp.timestamp >= NOW() - INTERVAL 10 MINUTE
),
current_trips AS (
    SELECT
        t.vehicle_id,
        t.trip_id,
        t.driver_id,
        d.driver_name,
        t.origin,
        t.destination,
        t.estimated_arrival,
        t.cargo_type,
        t.status
    FROM trips t
    JOIN drivers d ON t.driver_id = d.driver_id
    WHERE t.status IN ('dispatched', 'in_transit')
)
SELECT
    lp.vehicle_number,
    lp.vehicle_type,
    lp.latitude,
    lp.longitude,
    lp.speed_kmh,
    lp.address,
    ct.driver_name,
    ct.destination,
    ct.estimated_arrival,
    CASE
        WHEN lp.speed_kmh = 0 AND TIMESTAMPDIFF(MINUTE, lp.timestamp, NOW()) < 5 THEN 'STOPPED'
        WHEN lp.speed_kmh = 0 THEN 'IDLE'
        WHEN lp.speed_kmh > 0 AND ct.trip_id IS NOT NULL THEN 'IN_TRANSIT'
        WHEN lp.speed_kmh > 0 THEN 'MOVING'
        WHEN TIMESTAMPDIFF(MINUTE, lp.timestamp, NOW()) > 10 THEN 'OFFLINE'
        ELSE 'UNKNOWN'
    END as status,
    TIMESTAMPDIFF(MINUTE, lp.timestamp, NOW()) as last_update_minutes
FROM latest_positions lp
LEFT JOIN current_trips ct ON lp.vehicle_id = ct.vehicle_id
WHERE lp.rn = 1
ORDER BY status, lp.vehicle_number;
```

### 2\. Driver Behavior Scoring

```sql
-- Calculate driver safety scores based on events
WITH driver_events AS (
    SELECT
        d.driver_id,
        d.driver_name,
        d.license_number,
        COUNT(CASE WHEN de.event_type = 'harsh_brake' THEN 1 END) as harsh_brakes,
        COUNT(CASE WHEN de.event_type = 'harsh_acceleration' THEN 1 END) as harsh_accelerations,
        COUNT(CASE WHEN de.event_type = 'harsh_cornering' THEN 1 END) as harsh_corners,
        COUNT(CASE WHEN de.event_type = 'speeding' THEN 1 END) as speeding_events,
        COUNT(CASE WHEN de.event_type = 'idle_excessive' THEN 1 END) as excessive_idle,
        SUM(t.distance_km) as total_distance_km,
        SUM(TIMESTAMPDIFF(HOUR, t.start_time, t.end_time)) as total_hours
    FROM drivers d
    JOIN trips t ON d.driver_id = t.driver_id
    LEFT JOIN trip_events de ON t.trip_id = de.trip_id
    WHERE t.start_time >= DATE_SUB(NOW(), INTERVAL 30 DAY)
    GROUP BY d.driver_id
)
SELECT
    driver_name,
    license_number,
    total_distance_km,
    total_hours,
    harsh_brakes,
    harsh_accelerations,
    harsh_corners,
    speeding_events,
    excessive_idle,
    -- Calculate safety score (100 point scale)
    GREATEST(0, 100 -
        (harsh_brakes * 2) -
        (harsh_accelerations * 2) -
        (harsh_corners * 2) -
        (speeding_events * 5) -
        (excessive_idle * 1)
    ) as safety_score,
    -- Events per 1000 km
    ROUND((harsh_brakes + harsh_accelerations + harsh_corners) * 1000.0 / NULLIF(total_distance_km, 0), 2) as events_per_1000km,
    CASE
        WHEN GREATEST(0, 100 -
            (harsh_brakes * 2) -
            (harsh_accelerations * 2) -
            (harsh_corners * 2) -
            (speeding_events * 5) -
            (excessive_idle * 1)
        ) >= 90 THEN 'EXCELLENT'
        WHEN GREATEST(0, 100 -
            (harsh_brakes * 2) -
            (harsh_accelerations * 2) -
            (harsh_corners * 2) -
            (speeding_events * 5) -
            (excessive_idle * 1)
        ) >= 75 THEN 'GOOD'
        WHEN GREATEST(0, 100 -
            (harsh_brakes * 2) -
            (harsh_accelerations * 2) -
            (harsh_corners * 2) -
            (speeding_events * 5) -
            (excessive_idle * 1)
        ) >= 60 THEN 'NEEDS_IMPROVEMENT'
        ELSE 'POOR'
    END as rating
FROM driver_events
WHERE total_distance_km > 0
ORDER BY safety_score DESC;
```

### 3\. Predictive Maintenance Alert

```sql
-- Identify vehicles needing maintenance based on diagnostics and mileage
WITH vehicle_health AS (
    SELECT
        v.vehicle_id,
        v.vehicle_number,
        v.current_odometer_km,
        v.last_service_date,
        v.last_service_odometer_km,
        -- Distance since last service
        v.current_odometer_km - v.last_service_odometer_km as km_since_service,
        -- Days since last service
        DATEDIFF(CURDATE(), v.last_service_date) as days_since_service,
        -- Active diagnostic trouble codes
        COUNT(DISTINCT dc.dtc_code) as active_dtc_count,
        GROUP_CONCAT(DISTINCT dc.dtc_code) as dtc_codes,
        -- Oil life remaining
        (
            SELECT MIN(ed.value)
            FROM engine_diagnostics ed
            WHERE ed.vehicle_id = v.vehicle_id
                AND ed.parameter = 'oil_life_pct'
                AND ed.timestamp >= NOW() - INTERVAL 1 DAY
        ) as oil_life_pct,
        -- Brake pad thickness
        (
            SELECT MIN(ed.value)
            FROM engine_diagnostics ed
            WHERE ed.vehicle_id = v.vehicle_id
                AND ed.parameter = 'brake_pad_thickness_mm'
                AND ed.timestamp >= NOW() - INTERVAL 1 DAY
        ) as brake_pad_mm
    FROM vehicles v
    LEFT JOIN diagnostic_codes dc ON v.vehicle_id = dc.vehicle_id
        AND dc.cleared_at IS NULL
    GROUP BY v.vehicle_id
),
maintenance_rules AS (
    SELECT
        vehicle_id,
        vehicle_number,
        current_odometer_km,
        km_since_service,
        days_since_service,
        active_dtc_count,
        dtc_codes,
        oil_life_pct,
        brake_pad_mm,
        CASE
            WHEN active_dtc_count > 3 THEN 'CRITICAL - Multiple fault codes'
            WHEN oil_life_pct < 10 THEN 'CRITICAL - Oil change required'
            WHEN brake_pad_mm < 3 THEN 'CRITICAL - Brake service required'
            WHEN km_since_service > 15000 THEN 'DUE - Scheduled service'
            WHEN days_since_service > 180 THEN 'DUE - Time-based service'
            WHEN oil_life_pct < 25 THEN 'UPCOMING - Oil change soon'
            WHEN brake_pad_mm < 5 THEN 'UPCOMING - Brake check soon'
            WHEN km_since_service > 12000 THEN 'UPCOMING - Service soon'
            ELSE 'OK'
        END as maintenance_status,
        CASE
            WHEN km_since_service > 15000 THEN 0
            ELSE 15000 - km_since_service
        END as km_until_service
    FROM vehicle_health
)
SELECT
    vehicle_number,
    current_odometer_km,
    km_since_service,
    days_since_service,
    oil_life_pct,
    brake_pad_mm,
    active_dtc_count,
    dtc_codes,
    maintenance_status,
    km_until_service
FROM maintenance_rules
WHERE maintenance_status != 'OK'
ORDER BY
    FIELD(maintenance_status, 'CRITICAL - Multiple fault codes',
          'CRITICAL - Oil change required',
          'CRITICAL - Brake service required',
          'DUE - Scheduled service',
          'DUE - Time-based service',
          'UPCOMING - Oil change soon',
          'UPCOMING - Brake check soon',
          'UPCOMING - Service soon');
```

### 4\. Fuel Efficiency Analysis

```sql
-- Analyze fuel consumption patterns
WITH fuel_metrics AS (
    SELECT
        v.vehicle_id,
        v.vehicle_number,
        vt.type_name,
        DATE(fr.timestamp) as date,
        SUM(fr.fuel_consumed_liters) as daily_fuel_liters,
        SUM(t.distance_km) as daily_distance_km,
        AVG(fr.fuel_level_pct) as avg_fuel_level,
        COUNT(DISTINCT t.trip_id) as trips_count,
        AVG(gp.speed_kmh) as avg_speed,
        SUM(CASE WHEN gp.speed_kmh = 0 AND fr.engine_on = 1 THEN 1 ELSE 0 END) * 5 / 60.0 as idle_hours
    FROM vehicles v
    JOIN vehicle_types vt ON v.vehicle_type_id = vt.type_id
    JOIN fuel_readings fr ON v.vehicle_id = fr.vehicle_id
    JOIN trips t ON v.vehicle_id = t.vehicle_id
        AND DATE(t.start_time) = DATE(fr.timestamp)
    JOIN gps_positions gp ON v.vehicle_id = gp.vehicle_id
        AND DATE(gp.timestamp) = DATE(fr.timestamp)
    WHERE fr.timestamp >= DATE_SUB(NOW(), INTERVAL 7 DAY)
    GROUP BY v.vehicle_id, DATE(fr.timestamp)
),
efficiency_summary AS (
    SELECT
        vehicle_number,
        type_name,
        AVG(daily_fuel_liters) as avg_daily_fuel,
        AVG(daily_distance_km) as avg_daily_distance,
        AVG(daily_fuel_liters * 100 / NULLIF(daily_distance_km, 0)) as fuel_consumption_l_100km,
        AVG(avg_speed) as avg_speed_kmh,
        AVG(idle_hours) as avg_idle_hours,
        SUM(daily_fuel_liters) as total_fuel_liters,
        SUM(daily_distance_km) as total_distance_km
    FROM fuel_metrics
    GROUP BY vehicle_id
)
SELECT
    vehicle_number,
    type_name,
    ROUND(avg_daily_distance, 1) as avg_daily_km,
    ROUND(avg_daily_fuel, 2) as avg_daily_liters,
    ROUND(fuel_consumption_l_100km, 2) as liters_per_100km,
    ROUND(avg_speed_kmh, 1) as avg_speed_kmh,
    ROUND(avg_idle_hours, 2) as avg_idle_hours_per_day,
    ROUND(total_fuel_liters, 2) as week_total_fuel,
    ROUND(total_fuel_liters * 1.50, 2) as week_fuel_cost_usd, -- $1.50/liter
    CASE
        WHEN fuel_consumption_l_100km < 8 THEN 'EXCELLENT'
        WHEN fuel_consumption_l_100km < 10 THEN 'GOOD'
        WHEN fuel_consumption_l_100km < 12 THEN 'AVERAGE'
        ELSE 'POOR'
    END as efficiency_rating
FROM efficiency_summary
ORDER BY fuel_consumption_l_100km;
```

### 5\. Route Optimization Analysis

```sql
-- Compare planned vs actual routes
SELECT
    t.trip_id,
    t.vehicle_number,
    t.driver_name,
    t.origin,
    t.destination,
    t.planned_distance_km,
    t.actual_distance_km,
    t.planned_duration_hours,
    TIMESTAMPDIFF(HOUR, t.start_time, t.end_time) as actual_duration_hours,
    ROUND((t.actual_distance_km - t.planned_distance_km) / t.planned_distance_km * 100, 1) as distance_variance_pct,
    COUNT(ts.stop_id) as number_of_stops,
    SUM(ts.delay_minutes) as total_delay_minutes,
    t.fuel_consumed_liters,
    ROUND(t.fuel_consumed_liters * 100 / t.actual_distance_km, 2) as fuel_efficiency_l_100km,
    CASE
        WHEN (t.actual_distance_km - t.planned_distance_km) / t.planned_distance_km > 0.15 THEN 'INEFFICIENT_ROUTE'
        WHEN SUM(ts.delay_minutes) > 60 THEN 'EXCESSIVE_DELAYS'
        WHEN TIMESTAMPDIFF(HOUR, t.start_time, t.end_time) > t.planned_duration_hours * 1.2 THEN 'TIME_OVERRUN'
        ELSE 'ON_TRACK'
    END as trip_performance
FROM trips t
LEFT JOIN trip_stops ts ON t.trip_id = ts.trip_id
WHERE t.end_time IS NOT NULL
    AND t.start_time >= DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY t.trip_id
HAVING trip_performance != 'ON_TRACK'
ORDER BY t.start_time DESC;
```

## Advanced Features

### 1\. Route Optimization

- Multi-stop planning
- Traffic integration
- Dynamic re-routing
- Load optimization

### 2\. Geofencing

- Automated alerts
- Unauthorized use detection
- Customer site monitoring
- Route compliance

### 3\. ELD Compliance

- Automatic HOS tracking
- DVIR electronic forms
- DOT inspection readiness
- Violation prevention

### 4\. Integration Capabilities

- Fuel card systems
- Dispatch software
- Warehouse management
- Customer portals

## Performance Metrics

### Data Volume

- **GPS Data**: 1Hz × vehicles = 86,400 points/vehicle/day
- **Engine Data**: Every 10 seconds = 8,640 readings/vehicle/day
- **Storage**: ~50MB/vehicle/day

### Real-time Requirements

- **GPS Update**: <1 second latency
- **Alert Generation**: <5 seconds
- **Dashboard Refresh**: <2 seconds

## ROI & Benefits

### Cost Reductions

- **Fuel Savings**: 10-15%
- **Maintenance Costs**: -20%
- **Insurance Premiums**: -15%
- **Overtime Costs**: -25%

### Operational Improvements

- **Vehicle Utilization**: +20%
- **On-time Delivery**: +15%
- **Route Efficiency**: +12%
- **Driver Retention**: +30%

This Fleet Management system provides comprehensive vehicle and driver monitoring for operational excellence.
