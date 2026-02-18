# MongoDB Schema for example_03_smart_energy

Converted from MySQL on 2026-02-17T23:16:48.692017

## Collections

### buildings

**Document Structure:**
```json
{
  "building_name": {
    "type": "String",
    "required": true
  },
  "address": {
    "type": "String",
    "required": true
  },
  "city": {
    "type": "String",
    "required": false
  },
  "postal_code": {
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
  "total_area_sqm": {
    "type": "Decimal128",
    "required": false
  },
  "floors_count": {
    "type": "Number",
    "required": true
  },
  "year_built": {
    "type": "Number",
    "required": false
  },
  "building_type": {
    "type": "String",
    "required": false
  },
  "energy_rating": {
    "type": "String",
    "required": false
  },
  "occupancy_type": {
    "type": "String",
    "required": false
  },
  "typical_occupancy": {
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

### floors

**Document Structure:**
```json
{
  "building_id": {
    "type": "Number",
    "required": true
  },
  "floor_number": {
    "type": "Number",
    "required": true
  },
  "floor_name": {
    "type": "String",
    "required": false
  },
  "area_sqm": {
    "type": "Decimal128",
    "required": false
  },
  "height_meters": {
    "type": "Decimal128",
    "required": false
  },
  "is_mechanical": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "has_hvac_zone": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "typical_occupancy": {
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

### zones

**Document Structure:**
```json
{
  "floor_id": {
    "type": "Number",
    "required": true
  },
  "zone_name": {
    "type": "String",
    "required": false
  },
  "zone_type": {
    "type": "String",
    "required": false
  },
  "area_sqm": {
    "type": "Decimal128",
    "required": false
  },
  "has_windows": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "window_orientation": {
    "type": "String",
    "required": false
  },
  "target_temperature_c": {
    "type": "Decimal128",
    "required": false
  },
  "target_humidity_pct": {
    "type": "Decimal128",
    "required": false
  },
  "occupancy_schedule": {
    "type": "Object",
    "required": false
  },
  "max_occupancy": {
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

### tenants

**Document Structure:**
```json
{
  "company_name": {
    "type": "String",
    "required": true
  },
  "contact_name": {
    "type": "String",
    "required": false
  },
  "contact_email": {
    "type": "String",
    "required": false
  },
  "contact_phone": {
    "type": "String",
    "required": false
  },
  "lease_start_date": {
    "type": "Date",
    "required": true
  },
  "lease_end_date": {
    "type": "Date",
    "required": false
  },
  "billing_type": {
    "type": "String",
    "required": false
  },
  "monthly_base_rate": {
    "type": "Decimal128",
    "required": false
  },
  "energy_budget_kwh": {
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

### tenant_zone_assignments

**Document Structure:**
```json
{
  "tenant_id": {
    "type": "Number",
    "required": true
  },
  "zone_id": {
    "type": "Number",
    "required": true
  },
  "assignment_start_date": {
    "type": "Date",
    "required": true
  },
  "assignment_end_date": {
    "type": "Date",
    "required": false
  },
  "is_exclusive": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "usage_percentage": {
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

### meter_types

**Document Structure:**
```json
{
  "type_name": {
    "type": "String",
    "required": true
  },
  "measurement_unit": {
    "type": "String",
    "required": true
  },
  "reading_frequency_seconds": {
    "type": "Number",
    "required": false,
    "default": "300"
  },
  "is_utility_meter": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "is_sub_meter": {
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

### energy_meters

**Document Structure:**
```json
{
  "meter_type_id": {
    "type": "Number",
    "required": true
  },
  "building_id": {
    "type": "Number",
    "required": true
  },
  "zone_id": {
    "type": "Number",
    "required": false
  },
  "meter_name": {
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
    "required": true
  },
  "calibration_date": {
    "type": "Date",
    "required": false
  },
  "next_calibration_date": {
    "type": "Date",
    "required": false
  },
  "max_reading_value": {
    "type": "Decimal128",
    "required": false
  },
  "meter_constant": {
    "type": "Decimal128",
    "required": false
  },
  "is_smart_meter": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "communication_type": {
    "type": "String",
    "required": false
  },
  "ip_address": {
    "type": "String",
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
  "parent_meter_id": {
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

### solar_systems

**Document Structure:**
```json
{
  "building_id": {
    "type": "Number",
    "required": true
  },
  "system_name": {
    "type": "String",
    "required": false
  },
  "installation_date": {
    "type": "Date",
    "required": true
  },
  "capacity_kw": {
    "type": "Decimal128",
    "required": false
  },
  "panel_count": {
    "type": "Number",
    "required": false
  },
  "panel_type": {
    "type": "String",
    "required": false
  },
  "inverter_model": {
    "type": "String",
    "required": false
  },
  "inverter_count": {
    "type": "Number",
    "required": false
  },
  "orientation_degrees": {
    "type": "Number",
    "required": false
  },
  "tilt_degrees": {
    "type": "Number",
    "required": false
  },
  "annual_production_estimate_kwh": {
    "type": "Decimal128",
    "required": false
  },
  "degradation_rate_yearly": {
    "type": "Decimal128",
    "required": false
  },
  "warranty_end_date": {
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

### battery_storage

**Document Structure:**
```json
{
  "building_id": {
    "type": "Number",
    "required": true
  },
  "system_name": {
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
  "capacity_kwh": {
    "type": "Decimal128",
    "required": false
  },
  "max_power_kw": {
    "type": "Decimal128",
    "required": false
  },
  "efficiency_pct": {
    "type": "Decimal128",
    "required": false
  },
  "cycles_count": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "max_cycles": {
    "type": "Number",
    "required": false
  },
  "depth_of_discharge_pct": {
    "type": "Decimal128",
    "required": false
  },
  "state_of_charge_pct": {
    "type": "Decimal128",
    "required": false
  },
  "installation_date": {
    "type": "Date",
    "required": true
  },
  "warranty_end_date": {
    "type": "Date",
    "required": false
  },
  "temperature_c": {
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

### hvac_units

**Document Structure:**
```json
{
  "building_id": {
    "type": "Number",
    "required": true
  },
  "unit_name": {
    "type": "String",
    "required": false
  },
  "unit_type": {
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
  "serial_number": {
    "type": "String",
    "required": false
  },
  "capacity_kw": {
    "type": "Decimal128",
    "required": false
  },
  "efficiency_rating": {
    "type": "Decimal128",
    "required": false
  },
  "refrigerant_type": {
    "type": "String",
    "required": false
  },
  "installation_date": {
    "type": "Date",
    "required": true
  },
  "last_service_date": {
    "type": "Date",
    "required": false
  },
  "next_service_date": {
    "type": "Date",
    "required": false
  },
  "operating_hours": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "serves_zones": {
    "type": "Object",
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

### equipment_inventory

**Document Structure:**
```json
{
  "zone_id": {
    "type": "Number",
    "required": true
  },
  "equipment_type": {
    "type": "String",
    "required": false
  },
  "equipment_name": {
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
  "power_rating_watts": {
    "type": "Decimal128",
    "required": false
  },
  "quantity": {
    "type": "Number",
    "required": false,
    "default": "1"
  },
  "usage_hours_per_day": {
    "type": "Decimal128",
    "required": false
  },
  "efficiency_pct": {
    "type": "Decimal128",
    "required": false
  },
  "installation_date": {
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

### energy_readings

**Document Structure:**
```json
{
  "meter_id": {
    "type": "Number",
    "required": true
  },
  "reading_timestamp": {
    "type": "Date",
    "required": true
  },
  "energy_value": {
    "type": "Decimal128",
    "required": false
  },
  "power_value": {
    "type": "Decimal128",
    "required": false
  },
  "power_factor": {
    "type": "Decimal128",
    "required": false
  },
  "voltage_v": {
    "type": "Decimal128",
    "required": false
  },
  "current_a": {
    "type": "Decimal128",
    "required": false
  },
  "frequency_hz": {
    "type": "Decimal128",
    "required": false
  },
  "quality_flag": {
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

### energy_consumption_hourly

**Document Structure:**
```json
{
  "meter_id": {
    "type": "Number",
    "required": true
  },
  "hour_start": {
    "type": "Date",
    "required": true
  },
  "energy_consumed_kwh": {
    "type": "Decimal128",
    "required": false
  },
  "avg_power_kw": {
    "type": "Decimal128",
    "required": false
  },
  "max_power_kw": {
    "type": "Decimal128",
    "required": false
  },
  "min_power_kw": {
    "type": "Decimal128",
    "required": false
  },
  "avg_power_factor": {
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

### energy_consumption_daily

**Document Structure:**
```json
{
  "meter_id": {
    "type": "Number",
    "required": true
  },
  "consumption_date": {
    "type": "Date",
    "required": true
  },
  "total_energy_kwh": {
    "type": "Decimal128",
    "required": false
  },
  "peak_power_kw": {
    "type": "Decimal128",
    "required": false
  },
  "peak_hour": {
    "type": "String",
    "required": false
  },
  "off_peak_energy_kwh": {
    "type": "Decimal128",
    "required": false
  },
  "peak_energy_kwh": {
    "type": "Decimal128",
    "required": false
  },
  "base_load_kw": {
    "type": "Decimal128",
    "required": false
  },
  "load_factor": {
    "type": "Decimal128",
    "required": false
  },
  "daily_cost": {
    "type": "Decimal128",
    "required": false
  },
  "weather_temp_avg_c": {
    "type": "Decimal128",
    "required": false
  },
  "weather_condition": {
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

### solar_production

**Document Structure:**
```json
{
  "system_id": {
    "type": "Number",
    "required": true
  },
  "timestamp": {
    "type": "Date",
    "required": true
  },
  "power_kw": {
    "type": "Decimal128",
    "required": false
  },
  "energy_kwh": {
    "type": "Decimal128",
    "required": false
  },
  "irradiance_w_m2": {
    "type": "Decimal128",
    "required": false
  },
  "panel_temp_c": {
    "type": "Decimal128",
    "required": false
  },
  "ambient_temp_c": {
    "type": "Decimal128",
    "required": false
  },
  "efficiency_pct": {
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

### battery_status

**Document Structure:**
```json
{
  "battery_id": {
    "type": "Number",
    "required": true
  },
  "timestamp": {
    "type": "Date",
    "required": true
  },
  "state_of_charge_pct": {
    "type": "Decimal128",
    "required": false
  },
  "power_kw": {
    "type": "Decimal128",
    "required": false
  },
  "energy_kwh": {
    "type": "Decimal128",
    "required": false
  },
  "voltage_v": {
    "type": "Decimal128",
    "required": false
  },
  "current_a": {
    "type": "Decimal128",
    "required": false
  },
  "temperature_c": {
    "type": "Decimal128",
    "required": false
  },
  "cycle_count": {
    "type": "Number",
    "required": false
  },
  "health_pct": {
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

### hvac_telemetry

**Document Structure:**
```json
{
  "unit_id": {
    "type": "Number",
    "required": true
  },
  "timestamp": {
    "type": "Date",
    "required": true
  },
  "supply_temp_c": {
    "type": "Decimal128",
    "required": false
  },
  "return_temp_c": {
    "type": "Decimal128",
    "required": false
  },
  "setpoint_temp_c": {
    "type": "Decimal128",
    "required": false
  },
  "outdoor_temp_c": {
    "type": "Decimal128",
    "required": false
  },
  "fan_speed_pct": {
    "type": "Decimal128",
    "required": false
  },
  "compressor_status": {
    "type": "String",
    "required": false
  },
  "power_kw": {
    "type": "Decimal128",
    "required": false
  },
  "efficiency_cop": {
    "type": "Decimal128",
    "required": false
  },
  "runtime_minutes": {
    "type": "Number",
    "required": false
  },
  "fault_code": {
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

### demand_response_events

**Document Structure:**
```json
{
  "event_type": {
    "type": "String",
    "required": false
  },
  "start_time": {
    "type": "Date",
    "required": true
  },
  "end_time": {
    "type": "Date",
    "required": true
  },
  "target_reduction_kw": {
    "type": "Decimal128",
    "required": false
  },
  "target_reduction_pct": {
    "type": "Decimal128",
    "required": false
  },
  "incentive_rate": {
    "type": "Decimal128",
    "required": false
  },
  "notification_time": {
    "type": "Date",
    "required": false
  },
  "response_status": {
    "type": "String",
    "required": false
  },
  "actual_reduction_kw": {
    "type": "Decimal128",
    "required": false
  },
  "compliance_pct": {
    "type": "Decimal128",
    "required": false
  },
  "revenue_earned": {
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

### load_profiles

**Document Structure:**
```json
{
  "building_id": {
    "type": "Number",
    "required": true
  },
  "profile_type": {
    "type": "String",
    "required": false
  },
  "season": {
    "type": "String",
    "required": false
  },
  "hour_of_day": {
    "type": "Number",
    "required": true
  },
  "typical_load_kw": {
    "type": "Decimal128",
    "required": false
  },
  "min_load_kw": {
    "type": "Decimal128",
    "required": false
  },
  "max_load_kw": {
    "type": "Decimal128",
    "required": false
  },
  "std_deviation_kw": {
    "type": "Decimal128",
    "required": false
  },
  "sample_count": {
    "type": "Number",
    "required": false
  },
  "last_updated": {
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

### energy_forecasts

**Document Structure:**
```json
{
  "building_id": {
    "type": "Number",
    "required": true
  },
  "forecast_timestamp": {
    "type": "Date",
    "required": true
  },
  "forecast_horizon_hours": {
    "type": "Number",
    "required": true
  },
  "predicted_load_kw": {
    "type": "Decimal128",
    "required": false
  },
  "confidence_lower_kw": {
    "type": "Decimal128",
    "required": false
  },
  "confidence_upper_kw": {
    "type": "Decimal128",
    "required": false
  },
  "weather_temp_c": {
    "type": "Decimal128",
    "required": false
  },
  "is_workday": {
    "type": "Boolean",
    "required": false
  },
  "model_version": {
    "type": "String",
    "required": false
  },
  "actual_load_kw": {
    "type": "Decimal128",
    "required": false
  },
  "error_pct": {
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

### utility_rates

**Document Structure:**
```json
{
  "rate_name": {
    "type": "String",
    "required": true
  },
  "utility_company": {
    "type": "String",
    "required": false
  },
  "rate_type": {
    "type": "String",
    "required": false
  },
  "effective_date": {
    "type": "Date",
    "required": true
  },
  "end_date": {
    "type": "Date",
    "required": false
  },
  "time_periods": {
    "type": "Object",
    "required": false
  },
  "demand_charge": {
    "type": "Decimal128",
    "required": false
  },
  "fixed_charge": {
    "type": "Decimal128",
    "required": false
  },
  "is_default": {
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

### tenant_billing

**Document Structure:**
```json
{
  "tenant_id": {
    "type": "Number",
    "required": true
  },
  "billing_period_start": {
    "type": "Date",
    "required": true
  },
  "billing_period_end": {
    "type": "Date",
    "required": true
  },
  "total_energy_kwh": {
    "type": "Decimal128",
    "required": false
  },
  "peak_demand_kw": {
    "type": "Decimal128",
    "required": false
  },
  "energy_charge": {
    "type": "Decimal128",
    "required": false
  },
  "demand_charge": {
    "type": "Decimal128",
    "required": false
  },
  "fixed_charges": {
    "type": "Decimal128",
    "required": false
  },
  "taxes": {
    "type": "Decimal128",
    "required": false
  },
  "total_amount": {
    "type": "Decimal128",
    "required": false
  },
  "payment_status": {
    "type": "String",
    "required": false
  },
  "payment_date": {
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

### alert_rules

**Document Structure:**
```json
{
  "rule_name": {
    "type": "String",
    "required": true
  },
  "rule_type": {
    "type": "String",
    "required": false
  },
  "entity_type": {
    "type": "String",
    "required": false
  },
  "condition_json": {
    "type": "Object",
    "required": true
  },
  "severity": {
    "type": "String",
    "required": false
  },
  "notification_channels": {
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

### energy_alerts

**Document Structure:**
```json
{
  "rule_id": {
    "type": "Number",
    "required": true
  },
  "entity_type": {
    "type": "String",
    "required": true
  },
  "entity_id": {
    "type": "Number",
    "required": true
  },
  "alert_type": {
    "type": "String",
    "required": true
  },
  "severity": {
    "type": "String",
    "required": false
  },
  "triggered_at": {
    "type": "Date",
    "required": true
  },
  "alert_value": {
    "type": "Decimal128",
    "required": false
  },
  "threshold_value": {
    "type": "Decimal128",
    "required": false
  },
  "message": {
    "type": "String",
    "required": false
  },
  "resolved_at": {
    "type": "Date",
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
  "resolution_notes": {
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

### maintenance_schedules

**Document Structure:**
```json
{
  "equipment_type": {
    "type": "String",
    "required": false
  },
  "equipment_id": {
    "type": "Number",
    "required": true
  },
  "maintenance_type": {
    "type": "String",
    "required": false
  },
  "scheduled_date": {
    "type": "Date",
    "required": true
  },
  "frequency_days": {
    "type": "Number",
    "required": false
  },
  "estimated_duration_hours": {
    "type": "Decimal128",
    "required": false
  },
  "contractor": {
    "type": "String",
    "required": false
  },
  "estimated_cost": {
    "type": "Decimal128",
    "required": false
  },
  "status": {
    "type": "String",
    "required": false
  },
  "completed_date": {
    "type": "Date",
    "required": false
  },
  "actual_cost": {
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

### performance_metrics

**Document Structure:**
```json
{
  "building_id": {
    "type": "Number",
    "required": true
  },
  "metric_date": {
    "type": "Date",
    "required": true
  },
  "energy_intensity_kwh_sqm": {
    "type": "Decimal128",
    "required": false
  },
  "peak_demand_kw": {
    "type": "Decimal128",
    "required": false
  },
  "load_factor": {
    "type": "Decimal128",
    "required": false
  },
  "renewable_percentage": {
    "type": "Decimal128",
    "required": false
  },
  "carbon_emissions_kg": {
    "type": "Decimal128",
    "required": false
  },
  "cost_per_kwh": {
    "type": "Decimal128",
    "required": false
  },
  "total_cost": {
    "type": "Decimal128",
    "required": false
  },
  "power_quality_score": {
    "type": "Decimal128",
    "required": false
  },
  "equipment_efficiency_score": {
    "type": "Decimal128",
    "required": false
  },
  "benchmark_comparison": {
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

