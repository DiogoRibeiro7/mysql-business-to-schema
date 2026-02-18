// MongoDB Migration Script
// Generated: 2026-02-17T23:16:48.691168
// From MySQL to MongoDB

use converted_db;

// Create collection: buildings
db.createCollection('buildings');

// Create collection: floors
db.createCollection('floors');

// Create collection: zones
db.createCollection('zones');

// Create collection: tenants
db.createCollection('tenants');

// Create collection: tenant_zone_assignments
db.createCollection('tenant_zone_assignments');

// Create collection: meter_types
db.createCollection('meter_types');

// Create collection: energy_meters
db.createCollection('energy_meters');

// Create collection: solar_systems
db.createCollection('solar_systems');

// Create collection: battery_storage
db.createCollection('battery_storage');

// Create collection: hvac_units
db.createCollection('hvac_units');

// Create collection: equipment_inventory
db.createCollection('equipment_inventory');

// Create collection: energy_readings
db.createCollection('energy_readings');

// Create collection: energy_consumption_hourly
db.createCollection('energy_consumption_hourly');

// Create collection: energy_consumption_daily
db.createCollection('energy_consumption_daily');

// Create collection: solar_production
db.createCollection('solar_production');

// Create collection: battery_status
db.createCollection('battery_status');

// Create collection: hvac_telemetry
db.createCollection('hvac_telemetry');

// Create collection: demand_response_events
db.createCollection('demand_response_events');

// Create collection: load_profiles
db.createCollection('load_profiles');

// Create collection: energy_forecasts
db.createCollection('energy_forecasts');

// Create collection: utility_rates
db.createCollection('utility_rates');

// Create collection: tenant_billing
db.createCollection('tenant_billing');

// Create collection: alert_rules
db.createCollection('alert_rules');

// Create collection: energy_alerts
db.createCollection('energy_alerts');

// Create collection: maintenance_schedules
db.createCollection('maintenance_schedules');

// Create collection: performance_metrics
db.createCollection('performance_metrics');

// Indexes for buildings

// Indexes for floors

// Indexes for zones

// Indexes for tenants

// Indexes for tenant_zone_assignments

// Indexes for meter_types

// Indexes for energy_meters

// Indexes for solar_systems

// Indexes for battery_storage

// Indexes for hvac_units

// Indexes for equipment_inventory

// Indexes for energy_consumption_hourly

// Indexes for energy_consumption_daily

// Indexes for demand_response_events

// Indexes for load_profiles

// Indexes for tenant_billing
db.tenant_billing.createIndex({"notes": "text"}, {"name": "tenant_billing_text"});

// Indexes for energy_alerts
db.energy_alerts.createIndex({"message": "text", "resolution_notes": "text"}, {"name": "energy_alerts_text"});

// Indexes for maintenance_schedules
db.maintenance_schedules.createIndex({"notes": "text"}, {"name": "maintenance_schedules_text"});

// Indexes for performance_metrics

// Validation for buildings
db.runCommand({
  collMod: 'buildings',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "building_name",
      "address",
      "floors_count"
    ],
    "properties": {
      "building_name": {
        "bsonType": "string"
      },
      "address": {
        "bsonType": "string"
      },
      "city": {
        "bsonType": "string"
      },
      "postal_code": {
        "bsonType": "string"
      },
      "latitude": {
        "bsonType": "decimal128"
      },
      "longitude": {
        "bsonType": "decimal128"
      },
      "total_area_sqm": {
        "bsonType": "decimal128"
      },
      "floors_count": {
        "bsonType": "number"
      },
      "year_built": {
        "bsonType": "number"
      },
      "building_type": {
        "bsonType": "string"
      },
      "energy_rating": {
        "bsonType": "string"
      },
      "occupancy_type": {
        "bsonType": "string"
      },
      "typical_occupancy": {
        "bsonType": "number"
      },
      "status": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for floors
db.runCommand({
  collMod: 'floors',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "building_id",
      "floor_number"
    ],
    "properties": {
      "building_id": {
        "bsonType": "number"
      },
      "floor_number": {
        "bsonType": "number"
      },
      "floor_name": {
        "bsonType": "string"
      },
      "area_sqm": {
        "bsonType": "decimal128"
      },
      "height_meters": {
        "bsonType": "decimal128"
      },
      "is_mechanical": {
        "bsonType": "boolean"
      },
      "has_hvac_zone": {
        "bsonType": "boolean"
      },
      "typical_occupancy": {
        "bsonType": "number"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for zones
db.runCommand({
  collMod: 'zones',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "floor_id"
    ],
    "properties": {
      "floor_id": {
        "bsonType": "number"
      },
      "zone_name": {
        "bsonType": "string"
      },
      "zone_type": {
        "bsonType": "string"
      },
      "area_sqm": {
        "bsonType": "decimal128"
      },
      "has_windows": {
        "bsonType": "boolean"
      },
      "window_orientation": {
        "bsonType": "string"
      },
      "target_temperature_c": {
        "bsonType": "decimal128"
      },
      "target_humidity_pct": {
        "bsonType": "decimal128"
      },
      "occupancy_schedule": {
        "bsonType": "object"
      },
      "max_occupancy": {
        "bsonType": "number"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for tenants
db.runCommand({
  collMod: 'tenants',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "company_name",
      "lease_start_date"
    ],
    "properties": {
      "company_name": {
        "bsonType": "string"
      },
      "contact_name": {
        "bsonType": "string"
      },
      "contact_email": {
        "bsonType": "string"
      },
      "contact_phone": {
        "bsonType": "string"
      },
      "lease_start_date": {
        "bsonType": "date"
      },
      "lease_end_date": {
        "bsonType": "date"
      },
      "billing_type": {
        "bsonType": "string"
      },
      "monthly_base_rate": {
        "bsonType": "decimal128"
      },
      "energy_budget_kwh": {
        "bsonType": "decimal128"
      },
      "status": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for tenant_zone_assignments
db.runCommand({
  collMod: 'tenant_zone_assignments',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "tenant_id",
      "zone_id",
      "assignment_start_date"
    ],
    "properties": {
      "tenant_id": {
        "bsonType": "number"
      },
      "zone_id": {
        "bsonType": "number"
      },
      "assignment_start_date": {
        "bsonType": "date"
      },
      "assignment_end_date": {
        "bsonType": "date"
      },
      "is_exclusive": {
        "bsonType": "boolean"
      },
      "usage_percentage": {
        "bsonType": "decimal128"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for meter_types
db.runCommand({
  collMod: 'meter_types',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "type_name",
      "measurement_unit"
    ],
    "properties": {
      "type_name": {
        "bsonType": "string"
      },
      "measurement_unit": {
        "bsonType": "string"
      },
      "reading_frequency_seconds": {
        "bsonType": "number"
      },
      "is_utility_meter": {
        "bsonType": "boolean"
      },
      "is_sub_meter": {
        "bsonType": "boolean"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for energy_meters
db.runCommand({
  collMod: 'energy_meters',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "meter_type_id",
      "building_id",
      "installation_date"
    ],
    "properties": {
      "meter_type_id": {
        "bsonType": "number"
      },
      "building_id": {
        "bsonType": "number"
      },
      "zone_id": {
        "bsonType": "number"
      },
      "meter_name": {
        "bsonType": "string"
      },
      "manufacturer": {
        "bsonType": "string"
      },
      "model": {
        "bsonType": "string"
      },
      "installation_date": {
        "bsonType": "date"
      },
      "calibration_date": {
        "bsonType": "date"
      },
      "next_calibration_date": {
        "bsonType": "date"
      },
      "max_reading_value": {
        "bsonType": "decimal128"
      },
      "meter_constant": {
        "bsonType": "decimal128"
      },
      "is_smart_meter": {
        "bsonType": "boolean"
      },
      "communication_type": {
        "bsonType": "string"
      },
      "ip_address": {
        "bsonType": "string"
      },
      "last_reading_time": {
        "bsonType": "date"
      },
      "status": {
        "bsonType": "string"
      },
      "parent_meter_id": {
        "bsonType": "number"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for solar_systems
db.runCommand({
  collMod: 'solar_systems',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "building_id",
      "installation_date"
    ],
    "properties": {
      "building_id": {
        "bsonType": "number"
      },
      "system_name": {
        "bsonType": "string"
      },
      "installation_date": {
        "bsonType": "date"
      },
      "capacity_kw": {
        "bsonType": "decimal128"
      },
      "panel_count": {
        "bsonType": "number"
      },
      "panel_type": {
        "bsonType": "string"
      },
      "inverter_model": {
        "bsonType": "string"
      },
      "inverter_count": {
        "bsonType": "number"
      },
      "orientation_degrees": {
        "bsonType": "number"
      },
      "tilt_degrees": {
        "bsonType": "number"
      },
      "annual_production_estimate_kwh": {
        "bsonType": "decimal128"
      },
      "degradation_rate_yearly": {
        "bsonType": "decimal128"
      },
      "warranty_end_date": {
        "bsonType": "date"
      },
      "status": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for battery_storage
db.runCommand({
  collMod: 'battery_storage',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "building_id",
      "installation_date"
    ],
    "properties": {
      "building_id": {
        "bsonType": "number"
      },
      "system_name": {
        "bsonType": "string"
      },
      "manufacturer": {
        "bsonType": "string"
      },
      "model": {
        "bsonType": "string"
      },
      "capacity_kwh": {
        "bsonType": "decimal128"
      },
      "max_power_kw": {
        "bsonType": "decimal128"
      },
      "efficiency_pct": {
        "bsonType": "decimal128"
      },
      "cycles_count": {
        "bsonType": "number"
      },
      "max_cycles": {
        "bsonType": "number"
      },
      "depth_of_discharge_pct": {
        "bsonType": "decimal128"
      },
      "state_of_charge_pct": {
        "bsonType": "decimal128"
      },
      "installation_date": {
        "bsonType": "date"
      },
      "warranty_end_date": {
        "bsonType": "date"
      },
      "temperature_c": {
        "bsonType": "decimal128"
      },
      "status": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for hvac_units
db.runCommand({
  collMod: 'hvac_units',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "building_id",
      "installation_date"
    ],
    "properties": {
      "building_id": {
        "bsonType": "number"
      },
      "unit_name": {
        "bsonType": "string"
      },
      "unit_type": {
        "bsonType": "string"
      },
      "manufacturer": {
        "bsonType": "string"
      },
      "model": {
        "bsonType": "string"
      },
      "serial_number": {
        "bsonType": "string"
      },
      "capacity_kw": {
        "bsonType": "decimal128"
      },
      "efficiency_rating": {
        "bsonType": "decimal128"
      },
      "refrigerant_type": {
        "bsonType": "string"
      },
      "installation_date": {
        "bsonType": "date"
      },
      "last_service_date": {
        "bsonType": "date"
      },
      "next_service_date": {
        "bsonType": "date"
      },
      "operating_hours": {
        "bsonType": "number"
      },
      "serves_zones": {
        "bsonType": "object"
      },
      "status": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for equipment_inventory
db.runCommand({
  collMod: 'equipment_inventory',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "zone_id"
    ],
    "properties": {
      "zone_id": {
        "bsonType": "number"
      },
      "equipment_type": {
        "bsonType": "string"
      },
      "equipment_name": {
        "bsonType": "string"
      },
      "manufacturer": {
        "bsonType": "string"
      },
      "model": {
        "bsonType": "string"
      },
      "power_rating_watts": {
        "bsonType": "decimal128"
      },
      "quantity": {
        "bsonType": "number"
      },
      "usage_hours_per_day": {
        "bsonType": "decimal128"
      },
      "efficiency_pct": {
        "bsonType": "decimal128"
      },
      "installation_date": {
        "bsonType": "date"
      },
      "status": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for energy_readings
db.runCommand({
  collMod: 'energy_readings',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "meter_id",
      "reading_timestamp"
    ],
    "properties": {
      "meter_id": {
        "bsonType": "number"
      },
      "reading_timestamp": {
        "bsonType": "date"
      },
      "energy_value": {
        "bsonType": "decimal128"
      },
      "power_value": {
        "bsonType": "decimal128"
      },
      "power_factor": {
        "bsonType": "decimal128"
      },
      "voltage_v": {
        "bsonType": "decimal128"
      },
      "current_a": {
        "bsonType": "decimal128"
      },
      "frequency_hz": {
        "bsonType": "decimal128"
      },
      "quality_flag": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for energy_consumption_hourly
db.runCommand({
  collMod: 'energy_consumption_hourly',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "meter_id",
      "hour_start"
    ],
    "properties": {
      "meter_id": {
        "bsonType": "number"
      },
      "hour_start": {
        "bsonType": "date"
      },
      "energy_consumed_kwh": {
        "bsonType": "decimal128"
      },
      "avg_power_kw": {
        "bsonType": "decimal128"
      },
      "max_power_kw": {
        "bsonType": "decimal128"
      },
      "min_power_kw": {
        "bsonType": "decimal128"
      },
      "avg_power_factor": {
        "bsonType": "decimal128"
      },
      "reading_count": {
        "bsonType": "number"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for energy_consumption_daily
db.runCommand({
  collMod: 'energy_consumption_daily',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "meter_id",
      "consumption_date"
    ],
    "properties": {
      "meter_id": {
        "bsonType": "number"
      },
      "consumption_date": {
        "bsonType": "date"
      },
      "total_energy_kwh": {
        "bsonType": "decimal128"
      },
      "peak_power_kw": {
        "bsonType": "decimal128"
      },
      "peak_hour": {
        "bsonType": "string"
      },
      "off_peak_energy_kwh": {
        "bsonType": "decimal128"
      },
      "peak_energy_kwh": {
        "bsonType": "decimal128"
      },
      "base_load_kw": {
        "bsonType": "decimal128"
      },
      "load_factor": {
        "bsonType": "decimal128"
      },
      "daily_cost": {
        "bsonType": "decimal128"
      },
      "weather_temp_avg_c": {
        "bsonType": "decimal128"
      },
      "weather_condition": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for solar_production
db.runCommand({
  collMod: 'solar_production',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "system_id",
      "timestamp"
    ],
    "properties": {
      "system_id": {
        "bsonType": "number"
      },
      "timestamp": {
        "bsonType": "date"
      },
      "power_kw": {
        "bsonType": "decimal128"
      },
      "energy_kwh": {
        "bsonType": "decimal128"
      },
      "irradiance_w_m2": {
        "bsonType": "decimal128"
      },
      "panel_temp_c": {
        "bsonType": "decimal128"
      },
      "ambient_temp_c": {
        "bsonType": "decimal128"
      },
      "efficiency_pct": {
        "bsonType": "decimal128"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for battery_status
db.runCommand({
  collMod: 'battery_status',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "battery_id",
      "timestamp"
    ],
    "properties": {
      "battery_id": {
        "bsonType": "number"
      },
      "timestamp": {
        "bsonType": "date"
      },
      "state_of_charge_pct": {
        "bsonType": "decimal128"
      },
      "power_kw": {
        "bsonType": "decimal128"
      },
      "energy_kwh": {
        "bsonType": "decimal128"
      },
      "voltage_v": {
        "bsonType": "decimal128"
      },
      "current_a": {
        "bsonType": "decimal128"
      },
      "temperature_c": {
        "bsonType": "decimal128"
      },
      "cycle_count": {
        "bsonType": "number"
      },
      "health_pct": {
        "bsonType": "decimal128"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for hvac_telemetry
db.runCommand({
  collMod: 'hvac_telemetry',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "unit_id",
      "timestamp"
    ],
    "properties": {
      "unit_id": {
        "bsonType": "number"
      },
      "timestamp": {
        "bsonType": "date"
      },
      "supply_temp_c": {
        "bsonType": "decimal128"
      },
      "return_temp_c": {
        "bsonType": "decimal128"
      },
      "setpoint_temp_c": {
        "bsonType": "decimal128"
      },
      "outdoor_temp_c": {
        "bsonType": "decimal128"
      },
      "fan_speed_pct": {
        "bsonType": "decimal128"
      },
      "compressor_status": {
        "bsonType": "string"
      },
      "power_kw": {
        "bsonType": "decimal128"
      },
      "efficiency_cop": {
        "bsonType": "decimal128"
      },
      "runtime_minutes": {
        "bsonType": "number"
      },
      "fault_code": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for demand_response_events
db.runCommand({
  collMod: 'demand_response_events',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "start_time",
      "end_time"
    ],
    "properties": {
      "event_type": {
        "bsonType": "string"
      },
      "start_time": {
        "bsonType": "date"
      },
      "end_time": {
        "bsonType": "date"
      },
      "target_reduction_kw": {
        "bsonType": "decimal128"
      },
      "target_reduction_pct": {
        "bsonType": "decimal128"
      },
      "incentive_rate": {
        "bsonType": "decimal128"
      },
      "notification_time": {
        "bsonType": "date"
      },
      "response_status": {
        "bsonType": "string"
      },
      "actual_reduction_kw": {
        "bsonType": "decimal128"
      },
      "compliance_pct": {
        "bsonType": "decimal128"
      },
      "revenue_earned": {
        "bsonType": "decimal128"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for load_profiles
db.runCommand({
  collMod: 'load_profiles',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "building_id",
      "hour_of_day"
    ],
    "properties": {
      "building_id": {
        "bsonType": "number"
      },
      "profile_type": {
        "bsonType": "string"
      },
      "season": {
        "bsonType": "string"
      },
      "hour_of_day": {
        "bsonType": "number"
      },
      "typical_load_kw": {
        "bsonType": "decimal128"
      },
      "min_load_kw": {
        "bsonType": "decimal128"
      },
      "max_load_kw": {
        "bsonType": "decimal128"
      },
      "std_deviation_kw": {
        "bsonType": "decimal128"
      },
      "sample_count": {
        "bsonType": "number"
      },
      "last_updated": {
        "bsonType": "date"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for energy_forecasts
db.runCommand({
  collMod: 'energy_forecasts',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "building_id",
      "forecast_timestamp",
      "forecast_horizon_hours"
    ],
    "properties": {
      "building_id": {
        "bsonType": "number"
      },
      "forecast_timestamp": {
        "bsonType": "date"
      },
      "forecast_horizon_hours": {
        "bsonType": "number"
      },
      "predicted_load_kw": {
        "bsonType": "decimal128"
      },
      "confidence_lower_kw": {
        "bsonType": "decimal128"
      },
      "confidence_upper_kw": {
        "bsonType": "decimal128"
      },
      "weather_temp_c": {
        "bsonType": "decimal128"
      },
      "is_workday": {
        "bsonType": "boolean"
      },
      "model_version": {
        "bsonType": "string"
      },
      "actual_load_kw": {
        "bsonType": "decimal128"
      },
      "error_pct": {
        "bsonType": "decimal128"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for utility_rates
db.runCommand({
  collMod: 'utility_rates',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "rate_name",
      "effective_date"
    ],
    "properties": {
      "rate_name": {
        "bsonType": "string"
      },
      "utility_company": {
        "bsonType": "string"
      },
      "rate_type": {
        "bsonType": "string"
      },
      "effective_date": {
        "bsonType": "date"
      },
      "end_date": {
        "bsonType": "date"
      },
      "time_periods": {
        "bsonType": "object"
      },
      "demand_charge": {
        "bsonType": "decimal128"
      },
      "fixed_charge": {
        "bsonType": "decimal128"
      },
      "is_default": {
        "bsonType": "boolean"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for tenant_billing
db.runCommand({
  collMod: 'tenant_billing',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "tenant_id",
      "billing_period_start",
      "billing_period_end"
    ],
    "properties": {
      "tenant_id": {
        "bsonType": "number"
      },
      "billing_period_start": {
        "bsonType": "date"
      },
      "billing_period_end": {
        "bsonType": "date"
      },
      "total_energy_kwh": {
        "bsonType": "decimal128"
      },
      "peak_demand_kw": {
        "bsonType": "decimal128"
      },
      "energy_charge": {
        "bsonType": "decimal128"
      },
      "demand_charge": {
        "bsonType": "decimal128"
      },
      "fixed_charges": {
        "bsonType": "decimal128"
      },
      "taxes": {
        "bsonType": "decimal128"
      },
      "total_amount": {
        "bsonType": "decimal128"
      },
      "payment_status": {
        "bsonType": "string"
      },
      "payment_date": {
        "bsonType": "date"
      },
      "notes": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for alert_rules
db.runCommand({
  collMod: 'alert_rules',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "rule_name",
      "condition_json"
    ],
    "properties": {
      "rule_name": {
        "bsonType": "string"
      },
      "rule_type": {
        "bsonType": "string"
      },
      "entity_type": {
        "bsonType": "string"
      },
      "condition_json": {
        "bsonType": "object"
      },
      "severity": {
        "bsonType": "string"
      },
      "notification_channels": {
        "bsonType": "object"
      },
      "is_active": {
        "bsonType": "boolean"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for energy_alerts
db.runCommand({
  collMod: 'energy_alerts',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "rule_id",
      "entity_type",
      "entity_id",
      "alert_type",
      "triggered_at"
    ],
    "properties": {
      "rule_id": {
        "bsonType": "number"
      },
      "entity_type": {
        "bsonType": "string"
      },
      "entity_id": {
        "bsonType": "number"
      },
      "alert_type": {
        "bsonType": "string"
      },
      "severity": {
        "bsonType": "string"
      },
      "triggered_at": {
        "bsonType": "date"
      },
      "alert_value": {
        "bsonType": "decimal128"
      },
      "threshold_value": {
        "bsonType": "decimal128"
      },
      "message": {
        "bsonType": "string"
      },
      "resolved_at": {
        "bsonType": "date"
      },
      "acknowledged": {
        "bsonType": "boolean"
      },
      "acknowledged_by": {
        "bsonType": "string"
      },
      "acknowledged_at": {
        "bsonType": "date"
      },
      "resolution_notes": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for maintenance_schedules
db.runCommand({
  collMod: 'maintenance_schedules',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "equipment_id",
      "scheduled_date"
    ],
    "properties": {
      "equipment_type": {
        "bsonType": "string"
      },
      "equipment_id": {
        "bsonType": "number"
      },
      "maintenance_type": {
        "bsonType": "string"
      },
      "scheduled_date": {
        "bsonType": "date"
      },
      "frequency_days": {
        "bsonType": "number"
      },
      "estimated_duration_hours": {
        "bsonType": "decimal128"
      },
      "contractor": {
        "bsonType": "string"
      },
      "estimated_cost": {
        "bsonType": "decimal128"
      },
      "status": {
        "bsonType": "string"
      },
      "completed_date": {
        "bsonType": "date"
      },
      "actual_cost": {
        "bsonType": "decimal128"
      },
      "notes": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for performance_metrics
db.runCommand({
  collMod: 'performance_metrics',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "building_id",
      "metric_date"
    ],
    "properties": {
      "building_id": {
        "bsonType": "number"
      },
      "metric_date": {
        "bsonType": "date"
      },
      "energy_intensity_kwh_sqm": {
        "bsonType": "decimal128"
      },
      "peak_demand_kw": {
        "bsonType": "decimal128"
      },
      "load_factor": {
        "bsonType": "decimal128"
      },
      "renewable_percentage": {
        "bsonType": "decimal128"
      },
      "carbon_emissions_kg": {
        "bsonType": "decimal128"
      },
      "cost_per_kwh": {
        "bsonType": "decimal128"
      },
      "total_cost": {
        "bsonType": "decimal128"
      },
      "power_quality_score": {
        "bsonType": "decimal128"
      },
      "equipment_efficiency_score": {
        "bsonType": "decimal128"
      },
      "benchmark_comparison": {
        "bsonType": "decimal128"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});
