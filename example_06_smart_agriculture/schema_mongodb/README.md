# MongoDB Schema for example_06_smart_agriculture

Converted from MySQL on 2026-02-17T23:16:48.721915

## Collections

### farms

**Document Structure:**
```json
{
  "farm_name": {
    "type": "String",
    "required": true
  },
  "farm_type": {
    "type": "String",
    "required": false
  },
  "owner_name": {
    "type": "String",
    "required": false
  },
  "location": {
    "type": "String",
    "required": false
  },
  "total_area_hectares": {
    "type": "Decimal128",
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
  "elevation_meters": {
    "type": "Number",
    "required": false
  },
  "climate_zone": {
    "type": "String",
    "required": false
  },
  "soil_type": {
    "type": "String",
    "required": false
  },
  "established_date": {
    "type": "Date",
    "required": false
  },
  "organic_certified": {
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

### fields

**Document Structure:**
```json
{
  "farm_id": {
    "type": "Number",
    "required": true
  },
  "field_name": {
    "type": "String",
    "required": true
  },
  "area_hectares": {
    "type": "Decimal128",
    "required": false
  },
  "soil_type": {
    "type": "String",
    "required": false
  },
  "slope_percentage": {
    "type": "Decimal128",
    "required": false
  },
  "drainage_class": {
    "type": "String",
    "required": false
  },
  "irrigation_type": {
    "type": "String",
    "required": false
  },
  "gps_boundaries": {
    "type": "Object",
    "required": false
  },
  "last_soil_test": {
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

### zones

**Document Structure:**
```json
{
  "field_id": {
    "type": "Number",
    "required": true
  },
  "zone_name": {
    "type": "String",
    "required": false
  },
  "area_hectares": {
    "type": "Decimal128",
    "required": false
  },
  "management_zone_type": {
    "type": "String",
    "required": false
  },
  "characteristics": {
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

### crops

**Document Structure:**
```json
{
  "crop_name": {
    "type": "String",
    "required": true
  },
  "scientific_name": {
    "type": "String",
    "required": false
  },
  "crop_family": {
    "type": "String",
    "required": false
  },
  "crop_type": {
    "type": "String",
    "required": false
  },
  "growth_days": {
    "type": "Number",
    "required": false
  },
  "base_temperature_c": {
    "type": "Decimal128",
    "required": false
  },
  "optimal_temp_min": {
    "type": "Decimal128",
    "required": false
  },
  "optimal_temp_max": {
    "type": "Decimal128",
    "required": false
  },
  "water_needs_mm_per_day": {
    "type": "Decimal128",
    "required": false
  },
  "nitrogen_kg_per_hectare": {
    "type": "Decimal128",
    "required": false
  },
  "phosphorus_kg_per_hectare": {
    "type": "Decimal128",
    "required": false
  },
  "potassium_kg_per_hectare": {
    "type": "Decimal128",
    "required": false
  },
  "optimal_ph_min": {
    "type": "Decimal128",
    "required": false
  },
  "optimal_ph_max": {
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

### planting_records

**Document Structure:**
```json
{
  "field_id": {
    "type": "Number",
    "required": true
  },
  "zone_id": {
    "type": "Number",
    "required": false
  },
  "crop_id": {
    "type": "Number",
    "required": true
  },
  "variety": {
    "type": "String",
    "required": false
  },
  "planting_date": {
    "type": "Date",
    "required": true
  },
  "expected_harvest_date": {
    "type": "Date",
    "required": false
  },
  "actual_harvest_date": {
    "type": "Date",
    "required": false
  },
  "area_planted_hectares": {
    "type": "Decimal128",
    "required": false
  },
  "seed_rate_kg_per_hectare": {
    "type": "Decimal128",
    "required": false
  },
  "row_spacing_cm": {
    "type": "Decimal128",
    "required": false
  },
  "plant_spacing_cm": {
    "type": "Decimal128",
    "required": false
  },
  "planting_depth_cm": {
    "type": "Decimal128",
    "required": false
  },
  "expected_yield_kg_per_hectare": {
    "type": "Decimal128",
    "required": false
  },
  "actual_yield_kg_per_hectare": {
    "type": "Decimal128",
    "required": false
  },
  "status": {
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

### growth_stages

**Document Structure:**
```json
{
  "planting_id": {
    "type": "Number",
    "required": true
  },
  "stage_name": {
    "type": "String",
    "required": true
  },
  "stage_code": {
    "type": "String",
    "required": false
  },
  "observation_date": {
    "type": "Date",
    "required": true
  },
  "gdd_accumulated": {
    "type": "Decimal128",
    "required": false
  },
  "plant_height_cm": {
    "type": "Decimal128",
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

### sensors

**Document Structure:**
```json
{
  "zone_id": {
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
  "installation_date": {
    "type": "Date",
    "required": false
  },
  "depth_cm": {
    "type": "Number",
    "required": false
  },
  "height_m": {
    "type": "Decimal128",
    "required": false
  },
  "calibration_date": {
    "type": "Date",
    "required": false
  },
  "battery_type": {
    "type": "String",
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

### sensor_readings

**Document Structure:**
```json
{
  "sensor_id": {
    "type": "Number",
    "required": true
  },
  "timestamp": {
    "type": "Date",
    "required": true
  },
  "value": {
    "type": "Decimal128",
    "required": false
  },
  "unit": {
    "type": "String",
    "required": false
  },
  "quality_flag": {
    "type": "String",
    "required": false
  },
  "battery_voltage": {
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

### weather_stations

**Document Structure:**
```json
{
  "farm_id": {
    "type": "Number",
    "required": true
  },
  "station_name": {
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
  "elevation_m": {
    "type": "Number",
    "required": false
  },
  "installation_date": {
    "type": "Date",
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

### weather_data

**Document Structure:**
```json
{
  "station_id": {
    "type": "Number",
    "required": true
  },
  "observation_time": {
    "type": "Date",
    "required": true
  },
  "temperature_c": {
    "type": "Decimal128",
    "required": false
  },
  "humidity_percent": {
    "type": "Decimal128",
    "required": false
  },
  "pressure_hpa": {
    "type": "Decimal128",
    "required": false
  },
  "rainfall_mm": {
    "type": "Decimal128",
    "required": false
  },
  "wind_speed_kmh": {
    "type": "Decimal128",
    "required": false
  },
  "wind_direction_degrees": {
    "type": "Number",
    "required": false
  },
  "solar_radiation_wm2": {
    "type": "Decimal128",
    "required": false
  },
  "evapotranspiration_mm": {
    "type": "Decimal128",
    "required": false
  },
  "dew_point_c": {
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

### irrigation_systems

**Document Structure:**
```json
{
  "field_id": {
    "type": "Number",
    "required": true
  },
  "system_type": {
    "type": "String",
    "required": false
  },
  "flow_rate_lpm": {
    "type": "Decimal128",
    "required": false
  },
  "coverage_area_hectares": {
    "type": "Decimal128",
    "required": false
  },
  "efficiency_percentage": {
    "type": "Decimal128",
    "required": false
  },
  "installation_date": {
    "type": "Date",
    "required": false
  },
  "last_maintenance_date": {
    "type": "Date",
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

### irrigation_events

**Document Structure:**
```json
{
  "system_id": {
    "type": "Number",
    "required": true
  },
  "zone_id": {
    "type": "Number",
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
  "water_amount_liters": {
    "type": "Decimal128",
    "required": false
  },
  "trigger_type": {
    "type": "String",
    "required": false
  },
  "trigger_reason": {
    "type": "String",
    "required": false
  },
  "soil_moisture_before": {
    "type": "Decimal128",
    "required": false
  },
  "soil_moisture_after": {
    "type": "Decimal128",
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

### irrigation_schedules

**Document Structure:**
```json
{
  "system_id": {
    "type": "Number",
    "required": true
  },
  "schedule_name": {
    "type": "String",
    "required": false
  },
  "days_of_week": {
    "type": "Array",
    "required": false
  },
  "start_time": {
    "type": "String",
    "required": false
  },
  "duration_minutes": {
    "type": "Number",
    "required": false
  },
  "water_amount_mm": {
    "type": "Decimal128",
    "required": false
  },
  "moisture_threshold_min": {
    "type": "Decimal128",
    "required": false
  },
  "moisture_threshold_max": {
    "type": "Decimal128",
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

### fertilizer_applications

**Document Structure:**
```json
{
  "field_id": {
    "type": "Number",
    "required": true
  },
  "zone_id": {
    "type": "Number",
    "required": false
  },
  "application_date": {
    "type": "Date",
    "required": true
  },
  "fertilizer_type": {
    "type": "String",
    "required": false
  },
  "n_kg_per_hectare": {
    "type": "Decimal128",
    "required": false
  },
  "p_kg_per_hectare": {
    "type": "Decimal128",
    "required": false
  },
  "k_kg_per_hectare": {
    "type": "Decimal128",
    "required": false
  },
  "application_method": {
    "type": "String",
    "required": false
  },
  "cost_per_hectare": {
    "type": "Decimal128",
    "required": false
  },
  "weather_conditions": {
    "type": "String",
    "required": false
  },
  "operator_id": {
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

### pesticide_applications

**Document Structure:**
```json
{
  "field_id": {
    "type": "Number",
    "required": true
  },
  "zone_id": {
    "type": "Number",
    "required": false
  },
  "application_date": {
    "type": "Date",
    "required": true
  },
  "product_name": {
    "type": "String",
    "required": true
  },
  "active_ingredient": {
    "type": "String",
    "required": false
  },
  "target_pest": {
    "type": "String",
    "required": false
  },
  "application_rate_per_hectare": {
    "type": "String",
    "required": false
  },
  "rei_hours": {
    "type": "Number",
    "required": false
  },
  "phi_days": {
    "type": "Number",
    "required": false
  },
  "application_method": {
    "type": "String",
    "required": false
  },
  "weather_conditions": {
    "type": "String",
    "required": false
  },
  "wind_speed_kmh": {
    "type": "Decimal128",
    "required": false
  },
  "temperature_c": {
    "type": "Decimal128",
    "required": false
  },
  "operator_id": {
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

### animals

**Document Structure:**
```json
{
  "farm_id": {
    "type": "Number",
    "required": true
  },
  "animal_type": {
    "type": "String",
    "required": false
  },
  "breed": {
    "type": "String",
    "required": false
  },
  "gender": {
    "type": "String",
    "required": false
  },
  "birth_date": {
    "type": "Date",
    "required": false
  },
  "weight_kg": {
    "type": "Decimal128",
    "required": false
  },
  "mother_id": {
    "type": "Number",
    "required": false
  },
  "father_id": {
    "type": "Number",
    "required": false
  },
  "purchase_date": {
    "type": "Date",
    "required": false
  },
  "purchase_price": {
    "type": "Decimal128",
    "required": false
  },
  "current_location": {
    "type": "String",
    "required": false
  },
  "health_status": {
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

### health_records

**Document Structure:**
```json
{
  "animal_id": {
    "type": "Number",
    "required": true
  },
  "record_date": {
    "type": "Date",
    "required": true
  },
  "record_type": {
    "type": "String",
    "required": false
  },
  "description": {
    "type": "String",
    "required": false
  },
  "medication": {
    "type": "String",
    "required": false
  },
  "dosage": {
    "type": "String",
    "required": false
  },
  "veterinarian_name": {
    "type": "String",
    "required": false
  },
  "cost": {
    "type": "Decimal128",
    "required": false
  },
  "next_followup_date": {
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

### milk_production

**Document Structure:**
```json
{
  "animal_id": {
    "type": "Number",
    "required": true
  },
  "milking_date": {
    "type": "Date",
    "required": true
  },
  "milking_time": {
    "type": "String",
    "required": false
  },
  "quantity_liters": {
    "type": "Decimal128",
    "required": false
  },
  "fat_percentage": {
    "type": "Decimal128",
    "required": false
  },
  "protein_percentage": {
    "type": "Decimal128",
    "required": false
  },
  "somatic_cell_count": {
    "type": "Number",
    "required": false
  },
  "temperature_c": {
    "type": "Decimal128",
    "required": false
  },
  "quality_grade": {
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

### harvest_records

**Document Structure:**
```json
{
  "planting_id": {
    "type": "Number",
    "required": true
  },
  "harvest_date": {
    "type": "Date",
    "required": true
  },
  "area_harvested_hectares": {
    "type": "Decimal128",
    "required": false
  },
  "total_yield_kg": {
    "type": "Decimal128",
    "required": false
  },
  "marketable_yield_kg": {
    "type": "Decimal128",
    "required": false
  },
  "moisture_percentage": {
    "type": "Decimal128",
    "required": false
  },
  "quality_grade": {
    "type": "String",
    "required": false
  },
  "storage_location": {
    "type": "String",
    "required": false
  },
  "harvest_method": {
    "type": "String",
    "required": false
  },
  "weather_conditions": {
    "type": "String",
    "required": false
  },
  "labor_hours": {
    "type": "Decimal128",
    "required": false
  },
  "harvest_cost": {
    "type": "Decimal128",
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

### yield_predictions

**Document Structure:**
```json
{
  "planting_id": {
    "type": "Number",
    "required": true
  },
  "prediction_date": {
    "type": "Date",
    "required": true
  },
  "predicted_yield_kg_per_hectare": {
    "type": "Decimal128",
    "required": false
  },
  "confidence_level": {
    "type": "Decimal128",
    "required": false
  },
  "model_version": {
    "type": "String",
    "required": false
  },
  "factors": {
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

### operators

**Document Structure:**
```json
{
  "farm_id": {
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
  "role": {
    "type": "String",
    "required": false
  },
  "specialization": {
    "type": "String",
    "required": false
  },
  "phone": {
    "type": "String",
    "required": false
  },
  "email": {
    "type": "String",
    "required": false
  },
  "hire_date": {
    "type": "Date",
    "required": false
  },
  "certifications": {
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

### sensor_readings_hourly

**Document Structure:**
```json
{
  "sensor_id": {
    "type": "Number",
    "required": true
  },
  "hour_timestamp": {
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

### weather_daily_summary

**Document Structure:**
```json
{
  "station_id": {
    "type": "Number",
    "required": true
  },
  "summary_date": {
    "type": "Date",
    "required": true
  },
  "temp_min": {
    "type": "Decimal128",
    "required": false
  },
  "temp_max": {
    "type": "Decimal128",
    "required": false
  },
  "temp_avg": {
    "type": "Decimal128",
    "required": false
  },
  "humidity_avg": {
    "type": "Decimal128",
    "required": false
  },
  "rainfall_total": {
    "type": "Decimal128",
    "required": false
  },
  "wind_speed_max": {
    "type": "Decimal128",
    "required": false
  },
  "solar_radiation_total": {
    "type": "Decimal128",
    "required": false
  },
  "gdd_accumulated": {
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

