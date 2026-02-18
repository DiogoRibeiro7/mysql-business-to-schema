# MongoDB Schema for example_07_fleet_management

Converted from MySQL on 2026-02-17T23:16:48.732360

## Collections

### companies

**Document Structure:**
```json
{
  "company_name": {
    "type": "String",
    "required": true
  },
  "mc_number": {
    "type": "String",
    "required": false
  },
  "address": {
    "type": "String",
    "required": false
  },
  "city": {
    "type": "String",
    "required": false
  },
  "state": {
    "type": "String",
    "required": false
  },
  "zip_code": {
    "type": "String",
    "required": false
  },
  "country": {
    "type": "String",
    "required": false,
    "default": "USA"
  },
  "phone": {
    "type": "String",
    "required": false
  },
  "email": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### depots

**Document Structure:**
```json
{
  "company_id": {
    "type": "Number",
    "required": true
  },
  "depot_name": {
    "type": "String",
    "required": true
  },
  "address": {
    "type": "String",
    "required": false
  },
  "city": {
    "type": "String",
    "required": false
  },
  "state": {
    "type": "String",
    "required": false
  },
  "latitude": {
    "type": "Decimal128",
    "required": false
  },
  "longitude": {
    "type": "Decimal128",
    "required": false
  },
  "timezone": {
    "type": "String",
    "required": false,
    "default": "America/New_York"
  },
  "is_active": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### vehicles

**Document Structure:**
```json
{
  "company_id": {
    "type": "Number",
    "required": true
  },
  "depot_id": {
    "type": "Number",
    "required": false
  },
  "vehicle_type": {
    "type": "String",
    "required": false
  },
  "make": {
    "type": "String",
    "required": false
  },
  "model": {
    "type": "String",
    "required": false
  },
  "year": {
    "type": "Number",
    "required": false
  },
  "color": {
    "type": "String",
    "required": false
  },
  "fuel_type": {
    "type": "String",
    "required": false
  },
  "fuel_capacity_gallons": {
    "type": "Decimal128",
    "required": false
  },
  "odometer_miles": {
    "type": "Decimal128",
    "required": false
  },
  "engine_hours": {
    "type": "Decimal128",
    "required": false
  },
  "purchase_date": {
    "type": "Date",
    "required": false
  },
  "registration_expiry": {
    "type": "Date",
    "required": false
  },
  "insurance_expiry": {
    "type": "Date",
    "required": false
  },
  "last_service_date": {
    "type": "Date",
    "required": false
  },
  "last_service_miles": {
    "type": "Decimal128",
    "required": false
  },
  "next_service_miles": {
    "type": "Decimal128",
    "required": false
  },
  "status": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### vehicle_specs

**Document Structure:**
```json
{
  "gross_vehicle_weight_lbs": {
    "type": "Number",
    "required": false
  },
  "cargo_capacity_lbs": {
    "type": "Number",
    "required": false
  },
  "cargo_volume_cubic_ft": {
    "type": "Decimal128",
    "required": false
  },
  "mpg_city": {
    "type": "Decimal128",
    "required": false
  },
  "mpg_highway": {
    "type": "Decimal128",
    "required": false
  },
  "has_gps": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "has_eld": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "has_camera": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "has_temperature_control": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "has_liftgate": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### drivers

**Document Structure:**
```json
{
  "company_id": {
    "type": "Number",
    "required": true
  },
  "first_name": {
    "type": "String",
    "required": true
  },
  "last_name": {
    "type": "String",
    "required": true
  },
  "phone": {
    "type": "String",
    "required": false
  },
  "license_state": {
    "type": "String",
    "required": false
  },
  "license_class": {
    "type": "String",
    "required": false
  },
  "license_expiry": {
    "type": "Date",
    "required": true
  },
  "medical_cert_expiry": {
    "type": "Date",
    "required": false
  },
  "hire_date": {
    "type": "Date",
    "required": false
  },
  "birth_date": {
    "type": "Date",
    "required": false
  },
  "address": {
    "type": "String",
    "required": false
  },
  "city": {
    "type": "String",
    "required": false
  },
  "state": {
    "type": "String",
    "required": false
  },
  "zip_code": {
    "type": "String",
    "required": false
  },
  "emergency_contact": {
    "type": "String",
    "required": false
  },
  "emergency_phone": {
    "type": "String",
    "required": false
  },
  "status": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### driver_certifications

**Document Structure:**
```json
{
  "driver_id": {
    "type": "Number",
    "required": true
  },
  "certification_type": {
    "type": "String",
    "required": true
  },
  "certification_number": {
    "type": "String",
    "required": false
  },
  "issue_date": {
    "type": "Date",
    "required": false
  },
  "expiry_date": {
    "type": "Date",
    "required": false
  },
  "issuing_authority": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### gps_positions

**Document Structure:**
```json
{
  "vehicle_id": {
    "type": "Number",
    "required": true
  },
  "driver_id": {
    "type": "Number",
    "required": false
  },
  "timestamp": {
    "type": "Date",
    "required": true
  },
  "latitude": {
    "type": "Decimal128",
    "required": false
  },
  "longitude": {
    "type": "Decimal128",
    "required": false
  },
  "speed_mph": {
    "type": "Decimal128",
    "required": false
  },
  "heading": {
    "type": "Number",
    "required": false
  },
  "altitude_feet": {
    "type": "Number",
    "required": false
  },
  "satellites": {
    "type": "Number",
    "required": false
  },
  "hdop": {
    "type": "Decimal128",
    "required": false
  },
  "ignition_on": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "odometer_miles": {
    "type": "Decimal128",
    "required": false
  },
  "engine_hours": {
    "type": "Decimal128",
    "required": false
  },
  "fuel_level_percent": {
    "type": "Decimal128",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### trips

**Document Structure:**
```json
{
  "vehicle_id": {
    "type": "Number",
    "required": true
  },
  "driver_id": {
    "type": "Number",
    "required": true
  },
  "start_time": {
    "type": "Date",
    "required": true
  },
  "end_time": {
    "type": "Date",
    "required": false
  },
  "start_location": {
    "type": "String",
    "required": false
  },
  "start_latitude": {
    "type": "Decimal128",
    "required": false
  },
  "start_longitude": {
    "type": "Decimal128",
    "required": false
  },
  "end_location": {
    "type": "String",
    "required": false
  },
  "end_latitude": {
    "type": "Decimal128",
    "required": false
  },
  "end_longitude": {
    "type": "Decimal128",
    "required": false
  },
  "distance_miles": {
    "type": "Decimal128",
    "required": false
  },
  "duration_minutes": {
    "type": "Number",
    "required": false
  },
  "max_speed_mph": {
    "type": "Decimal128",
    "required": false
  },
  "avg_speed_mph": {
    "type": "Decimal128",
    "required": false
  },
  "fuel_consumed_gallons": {
    "type": "Decimal128",
    "required": false
  },
  "idle_time_minutes": {
    "type": "Number",
    "required": false
  },
  "stops_count": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "harsh_events_count": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "status": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### stops

**Document Structure:**
```json
{
  "trip_id": {
    "type": "Number",
    "required": true
  },
  "stop_sequence": {
    "type": "Number",
    "required": true
  },
  "arrival_time": {
    "type": "Date",
    "required": true
  },
  "departure_time": {
    "type": "Date",
    "required": false
  },
  "latitude": {
    "type": "Decimal128",
    "required": false
  },
  "longitude": {
    "type": "Decimal128",
    "required": false
  },
  "address": {
    "type": "String",
    "required": false
  },
  "stop_type": {
    "type": "String",
    "required": false
  },
  "duration_minutes": {
    "type": "Number",
    "required": false
  },
  "notes": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### driver_events

**Document Structure:**
```json
{
  "vehicle_id": {
    "type": "Number",
    "required": true
  },
  "driver_id": {
    "type": "Number",
    "required": true
  },
  "trip_id": {
    "type": "Number",
    "required": false
  },
  "event_type": {
    "type": "String",
    "required": false
  },
  "timestamp": {
    "type": "Date",
    "required": true
  },
  "latitude": {
    "type": "Decimal128",
    "required": false
  },
  "longitude": {
    "type": "Decimal128",
    "required": false
  },
  "speed_mph": {
    "type": "Decimal128",
    "required": false
  },
  "g_force": {
    "type": "Decimal128",
    "required": false
  },
  "speed_limit_mph": {
    "type": "Number",
    "required": false
  },
  "duration_seconds": {
    "type": "Number",
    "required": false
  },
  "severity": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### driver_scores

**Document Structure:**
```json
{
  "driver_id": {
    "type": "Number",
    "required": true
  },
  "score_date": {
    "type": "Date",
    "required": true
  },
  "safety_score": {
    "type": "Decimal128",
    "required": false
  },
  "fuel_efficiency_score": {
    "type": "Decimal128",
    "required": false
  },
  "compliance_score": {
    "type": "Decimal128",
    "required": false
  },
  "overall_score": {
    "type": "Decimal128",
    "required": false
  },
  "miles_driven": {
    "type": "Decimal128",
    "required": false
  },
  "trips_count": {
    "type": "Number",
    "required": false
  },
  "harsh_events_count": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "speeding_minutes": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "idle_minutes": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### routes

**Document Structure:**
```json
{
  "route_name": {
    "type": "String",
    "required": true
  },
  "depot_id": {
    "type": "Number",
    "required": false
  },
  "total_distance_miles": {
    "type": "Decimal128",
    "required": false
  },
  "estimated_duration_minutes": {
    "type": "Number",
    "required": false
  },
  "waypoints": {
    "type": "Object",
    "required": false
  },
  "is_active": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### geofences

**Document Structure:**
```json
{
  "company_id": {
    "type": "Number",
    "required": true
  },
  "geofence_name": {
    "type": "String",
    "required": true
  },
  "geofence_type": {
    "type": "String",
    "required": false
  },
  "center_latitude": {
    "type": "Decimal128",
    "required": false
  },
  "center_longitude": {
    "type": "Decimal128",
    "required": false
  },
  "radius_meters": {
    "type": "Number",
    "required": false
  },
  "polygon": {
    "type": "Object",
    "required": false
  },
  "alert_on_entry": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "alert_on_exit": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "is_active": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### geofence_events

**Document Structure:**
```json
{
  "geofence_id": {
    "type": "Number",
    "required": true
  },
  "vehicle_id": {
    "type": "Number",
    "required": true
  },
  "driver_id": {
    "type": "Number",
    "required": false
  },
  "event_type": {
    "type": "String",
    "required": false
  },
  "timestamp": {
    "type": "Date",
    "required": true
  },
  "duration_minutes": {
    "type": "Number",
    "required": false
  },
  "time": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### fuel_transactions

**Document Structure:**
```json
{
  "vehicle_id": {
    "type": "Number",
    "required": true
  },
  "driver_id": {
    "type": "Number",
    "required": false
  },
  "transaction_date": {
    "type": "Date",
    "required": true
  },
  "station_name": {
    "type": "String",
    "required": false
  },
  "station_address": {
    "type": "String",
    "required": false
  },
  "latitude": {
    "type": "Decimal128",
    "required": false
  },
  "longitude": {
    "type": "Decimal128",
    "required": false
  },
  "gallons": {
    "type": "Decimal128",
    "required": false
  },
  "price_per_gallon": {
    "type": "Decimal128",
    "required": false
  },
  "total_cost": {
    "type": "Decimal128",
    "required": false
  },
  "odometer_miles": {
    "type": "Decimal128",
    "required": false
  },
  "payment_method": {
    "type": "String",
    "required": false
  },
  "receipt_number": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### maintenance_records

**Document Structure:**
```json
{
  "vehicle_id": {
    "type": "Number",
    "required": true
  },
  "maintenance_type": {
    "type": "String",
    "required": false
  },
  "service_date": {
    "type": "Date",
    "required": true
  },
  "odometer_miles": {
    "type": "Decimal128",
    "required": false
  },
  "engine_hours": {
    "type": "Decimal128",
    "required": false
  },
  "service_provider": {
    "type": "String",
    "required": false
  },
  "description": {
    "type": "String",
    "required": false
  },
  "parts_cost": {
    "type": "Decimal128",
    "required": false
  },
  "labor_cost": {
    "type": "Decimal128",
    "required": false
  },
  "total_cost": {
    "type": "Decimal128",
    "required": false
  },
  "next_service_miles": {
    "type": "Decimal128",
    "required": false
  },
  "next_service_date": {
    "type": "Date",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### vehicle_diagnostics

**Document Structure:**
```json
{
  "vehicle_id": {
    "type": "Number",
    "required": true
  },
  "timestamp": {
    "type": "Date",
    "required": true
  },
  "engine_rpm": {
    "type": "Number",
    "required": false
  },
  "engine_load_percent": {
    "type": "Decimal128",
    "required": false
  },
  "coolant_temp_f": {
    "type": "Number",
    "required": false
  },
  "oil_pressure_psi": {
    "type": "Decimal128",
    "required": false
  },
  "battery_voltage": {
    "type": "Decimal128",
    "required": false
  },
  "check_engine_light": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "dtc_codes": {
    "type": "Object",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### driver_logs

**Document Structure:**
```json
{
  "driver_id": {
    "type": "Number",
    "required": true
  },
  "log_date": {
    "type": "Date",
    "required": true
  },
  "duty_status": {
    "type": "String",
    "required": false
  },
  "start_time": {
    "type": "Date",
    "required": true
  },
  "end_time": {
    "type": "Date",
    "required": false
  },
  "duration_minutes": {
    "type": "Number",
    "required": false
  },
  "location": {
    "type": "String",
    "required": false
  },
  "latitude": {
    "type": "Decimal128",
    "required": false
  },
  "longitude": {
    "type": "Decimal128",
    "required": false
  },
  "vehicle_id": {
    "type": "Number",
    "required": false
  },
  "odometer_start": {
    "type": "Decimal128",
    "required": false
  },
  "odometer_end": {
    "type": "Decimal128",
    "required": false
  },
  "notes": {
    "type": "String",
    "required": false
  },
  "certified": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "certified_at": {
    "type": "Date",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### hos_violations

**Document Structure:**
```json
{
  "driver_id": {
    "type": "Number",
    "required": true
  },
  "violation_date": {
    "type": "Date",
    "required": true
  },
  "violation_type": {
    "type": "String",
    "required": false
  },
  "duration_minutes": {
    "type": "Number",
    "required": false
  },
  "description": {
    "type": "String",
    "required": false
  },
  "severity": {
    "type": "String",
    "required": false
  },
  "resolved": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### dvir_reports

**Document Structure:**
```json
{
  "vehicle_id": {
    "type": "Number",
    "required": true
  },
  "driver_id": {
    "type": "Number",
    "required": true
  },
  "inspection_date": {
    "type": "Date",
    "required": true
  },
  "inspection_type": {
    "type": "String",
    "required": false
  },
  "odometer_miles": {
    "type": "Decimal128",
    "required": false
  },
  "defects_found": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "defect_details": {
    "type": "Object",
    "required": false
  },
  "signature_driver": {
    "type": "String",
    "required": false
  },
  "signature_mechanic": {
    "type": "String",
    "required": false
  },
  "repaired": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "repair_date": {
    "type": "Date",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### messages

**Document Structure:**
```json
{
  "sender_type": {
    "type": "String",
    "required": false
  },
  "sender_id": {
    "type": "Number",
    "required": false
  },
  "recipient_type": {
    "type": "String",
    "required": false
  },
  "recipient_id": {
    "type": "Number",
    "required": false
  },
  "message_text": {
    "type": "String",
    "required": true
  },
  "priority": {
    "type": "String",
    "required": false
  },
  "read_status": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "sent_at": {
    "type": "Date",
    "required": false,
    "default": "CURRENT_TIMESTAMP"
  },
  "read_at": {
    "type": "Date",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### vehicle_daily_summary

**Document Structure:**
```json
{
  "vehicle_id": {
    "type": "Number",
    "required": true
  },
  "summary_date": {
    "type": "Date",
    "required": true
  },
  "total_miles": {
    "type": "Decimal128",
    "required": false
  },
  "total_hours": {
    "type": "Decimal128",
    "required": false
  },
  "total_trips": {
    "type": "Number",
    "required": false
  },
  "total_stops": {
    "type": "Number",
    "required": false
  },
  "total_fuel_gallons": {
    "type": "Decimal128",
    "required": false
  },
  "avg_mpg": {
    "type": "Decimal128",
    "required": false
  },
  "total_idle_minutes": {
    "type": "Number",
    "required": false
  },
  "harsh_events_count": {
    "type": "Number",
    "required": false
  },
  "max_speed_mph": {
    "type": "Decimal128",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### gps_positions_hourly

**Document Structure:**
```json
{
  "vehicle_id": {
    "type": "Number",
    "required": true
  },
  "hour_timestamp": {
    "type": "Date",
    "required": true
  },
  "avg_speed_mph": {
    "type": "Decimal128",
    "required": false
  },
  "max_speed_mph": {
    "type": "Decimal128",
    "required": false
  },
  "distance_miles": {
    "type": "Decimal128",
    "required": false
  },
  "position_count": {
    "type": "Number",
    "required": false
  },
  "idle_minutes": {
    "type": "Number",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

