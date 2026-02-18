# MongoDB Schema for example_02_iot_bins

Converted from MySQL on 2026-02-17T23:16:48.682664

## Collections

### districts

**Document Structure:**
```json
{
  "name": {
    "type": "String",
    "required": true
  },
  "area_km2": {
    "type": "Decimal128",
    "required": false
  },
  "population": {
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

### bins

**Document Structure:**
```json
{
  "district_id": {
    "type": "Number",
    "required": true
  },
  "bin_type": {
    "type": "String",
    "required": false
  },
  "capacity_liters": {
    "type": "Number",
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
  "address": {
    "type": "String",
    "required": false
  },
  "location_type": {
    "type": "String",
    "required": false
  },
  "installation_date": {
    "type": "Date",
    "required": true
  },
  "last_maintenance_date": {
    "type": "Date",
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

### sensors

**Document Structure:**
```json
{
  "bin_id": {
    "type": "Number",
    "required": true
  },
  "sensor_type": {
    "type": "String",
    "required": false
  },
  "manufacturer": {
    "type": "String",
    "required": false
  },
  "model": {
    "type": "String",
    "required": false
  },
  "firmware_version": {
    "type": "String",
    "required": false
  },
  "installation_date": {
    "type": "Date",
    "required": true
  },
  "reading_frequency_seconds": {
    "type": "Number",
    "required": true,
    "default": "300"
  },
  "battery_level": {
    "type": "Decimal128",
    "required": false
  },
  "last_reading_time": {
    "type": "Date",
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

### collection_routes

**Document Structure:**
```json
{
  "district_id": {
    "type": "Number",
    "required": true
  },
  "route_name": {
    "type": "String",
    "required": false
  },
  "route_type": {
    "type": "String",
    "required": false
  },
  "estimated_duration_minutes": {
    "type": "Number",
    "required": false
  },
  "estimated_distance_km": {
    "type": "Decimal128",
    "required": false
  },
  "active": {
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

### route_bin_assignments

**Document Structure:**
```json
{
  "route_id": {
    "type": "Number",
    "required": true
  },
  "bin_id": {
    "type": "Number",
    "required": true
  },
  "collection_order": {
    "type": "Number",
    "required": true
  },
  "estimated_collection_time": {
    "type": "String",
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

### trucks

**Document Structure:**
```json
{
  "manufacturer": {
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
  "capacity_kg": {
    "type": "Number",
    "required": true
  },
  "fuel_type": {
    "type": "String",
    "required": false
  },
  "last_maintenance_date": {
    "type": "Date",
    "required": false
  },
  "next_maintenance_date": {
    "type": "Date",
    "required": false
  },
  "odometer_km": {
    "type": "Number",
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

### drivers

**Document Structure:**
```json
{
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
  "license_expiry_date": {
    "type": "Date",
    "required": true
  },
  "hire_date": {
    "type": "Date",
    "required": true
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

### collection_schedules

**Document Structure:**
```json
{
  "route_id": {
    "type": "Number",
    "required": true
  },
  "truck_id": {
    "type": "Number",
    "required": true
  },
  "driver_id": {
    "type": "Number",
    "required": true
  },
  "scheduled_date": {
    "type": "Date",
    "required": true
  },
  "scheduled_start_time": {
    "type": "String",
    "required": true
  },
  "scheduled_end_time": {
    "type": "String",
    "required": true
  },
  "status": {
    "type": "String",
    "required": false
  },
  "actual_start_time": {
    "type": "Date",
    "required": false
  },
  "actual_end_time": {
    "type": "Date",
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

### collection_events

**Document Structure:**
```json
{
  "bin_id": {
    "type": "Number",
    "required": true
  },
  "schedule_id": {
    "type": "Number",
    "required": false
  },
  "truck_id": {
    "type": "Number",
    "required": true
  },
  "driver_id": {
    "type": "Number",
    "required": true
  },
  "collected_at": {
    "type": "Date",
    "required": true
  },
  "fill_level_before": {
    "type": "Decimal128",
    "required": false
  },
  "weight_kg": {
    "type": "Decimal128",
    "required": false
  },
  "collection_duration_seconds": {
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

### sensor_readings

**Document Structure:**
```json
{
  "sensor_id": {
    "type": "Number",
    "required": true
  },
  "reading_time": {
    "type": "Date",
    "required": true
  },
  "reading_value": {
    "type": "Decimal128",
    "required": false
  },
  "unit": {
    "type": "String",
    "required": true
  },
  "quality": {
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

### sensor_readings_hourly

**Document Structure:**
```json
{
  "sensor_id": {
    "type": "Number",
    "required": true
  },
  "hour_start": {
    "type": "Date",
    "required": true
  },
  "min_value": {
    "type": "Decimal128",
    "required": false
  },
  "max_value": {
    "type": "Decimal128",
    "required": false
  },
  "avg_value": {
    "type": "Decimal128",
    "required": false
  },
  "reading_count": {
    "type": "Number",
    "required": false
  },
  "quality_good_count": {
    "type": "Number",
    "required": false
  },
  "quality_warning_count": {
    "type": "Number",
    "required": false
  },
  "quality_error_count": {
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

### sensor_readings_daily

**Document Structure:**
```json
{
  "sensor_id": {
    "type": "Number",
    "required": true
  },
  "date": {
    "type": "Date",
    "required": true
  },
  "min_value": {
    "type": "Decimal128",
    "required": false
  },
  "max_value": {
    "type": "Decimal128",
    "required": false
  },
  "avg_value": {
    "type": "Decimal128",
    "required": false
  },
  "peak_hour": {
    "type": "String",
    "required": false
  },
  "peak_value": {
    "type": "Decimal128",
    "required": false
  },
  "reading_count": {
    "type": "Number",
    "required": false
  },
  "quality_good_pct": {
    "type": "Decimal128",
    "required": false
  },
  "quality_warning_pct": {
    "type": "Decimal128",
    "required": false
  },
  "quality_error_pct": {
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

### alert_thresholds

**Document Structure:**
```json
{
  "name": {
    "type": "String",
    "required": true
  },
  "bin_type": {
    "type": "String",
    "required": false
  },
  "sensor_type": {
    "type": "String",
    "required": false
  },
  "warning_value": {
    "type": "Decimal128",
    "required": false
  },
  "critical_value": {
    "type": "Decimal128",
    "required": false
  },
  "check_interval_seconds": {
    "type": "Number",
    "required": false,
    "default": "300"
  },
  "active": {
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

### alerts

**Document Structure:**
```json
{
  "bin_id": {
    "type": "Number",
    "required": true
  },
  "sensor_id": {
    "type": "Number",
    "required": false
  },
  "threshold_id": {
    "type": "Number",
    "required": false
  },
  "alert_type": {
    "type": "String",
    "required": false
  },
  "severity": {
    "type": "String",
    "required": false
  },
  "triggered_at": {
    "type": "Date",
    "required": true
  },
  "resolved_at": {
    "type": "Date",
    "required": false
  },
  "alert_value": {
    "type": "Decimal128",
    "required": false
  },
  "message": {
    "type": "String",
    "required": false
  },
  "acknowledged": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "acknowledged_by": {
    "type": "String",
    "required": false
  },
  "acknowledged_at": {
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

### fill_rate_predictions

**Document Structure:**
```json
{
  "bin_id": {
    "type": "Number",
    "required": true
  },
  "prediction_date": {
    "type": "Date",
    "required": true
  },
  "prediction_hour": {
    "type": "String",
    "required": true
  },
  "predicted_fill_rate": {
    "type": "Decimal128",
    "required": false
  },
  "confidence_score": {
    "type": "Decimal128",
    "required": false
  },
  "model_version": {
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

