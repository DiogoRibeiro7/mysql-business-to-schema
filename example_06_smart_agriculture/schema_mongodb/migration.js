// MongoDB Migration Script
// Generated: 2026-02-17T23:16:48.720929
// From MySQL to MongoDB

use converted_db;

// Create collection: farms
db.createCollection('farms');

// Create collection: fields
db.createCollection('fields');

// Create collection: zones
db.createCollection('zones');

// Create collection: crops
db.createCollection('crops');

// Create collection: planting_records
db.createCollection('planting_records');

// Create collection: growth_stages
db.createCollection('growth_stages');

// Create collection: sensors
db.createCollection('sensors');

// Create collection: sensor_readings
db.createCollection('sensor_readings');

// Create collection: weather_stations
db.createCollection('weather_stations');

// Create collection: weather_data
db.createCollection('weather_data');

// Create collection: irrigation_systems
db.createCollection('irrigation_systems');

// Create collection: irrigation_events
db.createCollection('irrigation_events');

// Create collection: irrigation_schedules
db.createCollection('irrigation_schedules');

// Create collection: fertilizer_applications
db.createCollection('fertilizer_applications');

// Create collection: pesticide_applications
db.createCollection('pesticide_applications');

// Create collection: animals
db.createCollection('animals');

// Create collection: health_records
db.createCollection('health_records');

// Create collection: milk_production
db.createCollection('milk_production');

// Create collection: harvest_records
db.createCollection('harvest_records');

// Create collection: yield_predictions
db.createCollection('yield_predictions');

// Create collection: operators
db.createCollection('operators');

// Create collection: sensor_readings_hourly
db.createCollection('sensor_readings_hourly');

// Create collection: weather_daily_summary
db.createCollection('weather_daily_summary');

// Indexes for planting_records
db.planting_records.createIndex({"notes": "text"}, {"name": "planting_records_text"});

// Indexes for growth_stages
db.growth_stages.createIndex({"notes": "text"}, {"name": "growth_stages_text"});

// Indexes for sensors

// Indexes for irrigation_events
db.irrigation_events.createIndex({"notes": "text"}, {"name": "irrigation_events_text"});

// Indexes for fertilizer_applications
db.fertilizer_applications.createIndex({"notes": "text"}, {"name": "fertilizer_applications_text"});

// Indexes for pesticide_applications
db.pesticide_applications.createIndex({"notes": "text"}, {"name": "pesticide_applications_text"});

// Indexes for animals

// Indexes for health_records
db.health_records.createIndex({"description": "text"}, {"name": "health_records_text"});

// Indexes for milk_production

// Indexes for harvest_records
db.harvest_records.createIndex({"notes": "text"}, {"name": "harvest_records_text"});

// Validation for farms
db.runCommand({
  collMod: 'farms',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "farm_name"
    ],
    "properties": {
      "farm_name": {
        "bsonType": "string"
      },
      "farm_type": {
        "bsonType": "string"
      },
      "owner_name": {
        "bsonType": "string"
      },
      "location": {
        "bsonType": "string"
      },
      "total_area_hectares": {
        "bsonType": "decimal128"
      },
      "latitude": {
        "bsonType": "decimal128"
      },
      "longitude": {
        "bsonType": "decimal128"
      },
      "elevation_meters": {
        "bsonType": "number"
      },
      "climate_zone": {
        "bsonType": "string"
      },
      "soil_type": {
        "bsonType": "string"
      },
      "established_date": {
        "bsonType": "date"
      },
      "organic_certified": {
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

// Validation for fields
db.runCommand({
  collMod: 'fields',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "farm_id",
      "field_name"
    ],
    "properties": {
      "farm_id": {
        "bsonType": "number"
      },
      "field_name": {
        "bsonType": "string"
      },
      "area_hectares": {
        "bsonType": "decimal128"
      },
      "soil_type": {
        "bsonType": "string"
      },
      "slope_percentage": {
        "bsonType": "decimal128"
      },
      "drainage_class": {
        "bsonType": "string"
      },
      "irrigation_type": {
        "bsonType": "string"
      },
      "gps_boundaries": {
        "bsonType": "object"
      },
      "last_soil_test": {
        "bsonType": "date"
      },
      "created_at": {
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
      "field_id"
    ],
    "properties": {
      "field_id": {
        "bsonType": "number"
      },
      "zone_name": {
        "bsonType": "string"
      },
      "area_hectares": {
        "bsonType": "decimal128"
      },
      "management_zone_type": {
        "bsonType": "string"
      },
      "characteristics": {
        "bsonType": "object"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for crops
db.runCommand({
  collMod: 'crops',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "crop_name"
    ],
    "properties": {
      "crop_name": {
        "bsonType": "string"
      },
      "scientific_name": {
        "bsonType": "string"
      },
      "crop_family": {
        "bsonType": "string"
      },
      "crop_type": {
        "bsonType": "string"
      },
      "growth_days": {
        "bsonType": "number"
      },
      "base_temperature_c": {
        "bsonType": "decimal128"
      },
      "optimal_temp_min": {
        "bsonType": "decimal128"
      },
      "optimal_temp_max": {
        "bsonType": "decimal128"
      },
      "water_needs_mm_per_day": {
        "bsonType": "decimal128"
      },
      "nitrogen_kg_per_hectare": {
        "bsonType": "decimal128"
      },
      "phosphorus_kg_per_hectare": {
        "bsonType": "decimal128"
      },
      "potassium_kg_per_hectare": {
        "bsonType": "decimal128"
      },
      "optimal_ph_min": {
        "bsonType": "decimal128"
      },
      "optimal_ph_max": {
        "bsonType": "decimal128"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for planting_records
db.runCommand({
  collMod: 'planting_records',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "field_id",
      "crop_id",
      "planting_date"
    ],
    "properties": {
      "field_id": {
        "bsonType": "number"
      },
      "zone_id": {
        "bsonType": "number"
      },
      "crop_id": {
        "bsonType": "number"
      },
      "variety": {
        "bsonType": "string"
      },
      "planting_date": {
        "bsonType": "date"
      },
      "expected_harvest_date": {
        "bsonType": "date"
      },
      "actual_harvest_date": {
        "bsonType": "date"
      },
      "area_planted_hectares": {
        "bsonType": "decimal128"
      },
      "seed_rate_kg_per_hectare": {
        "bsonType": "decimal128"
      },
      "row_spacing_cm": {
        "bsonType": "decimal128"
      },
      "plant_spacing_cm": {
        "bsonType": "decimal128"
      },
      "planting_depth_cm": {
        "bsonType": "decimal128"
      },
      "expected_yield_kg_per_hectare": {
        "bsonType": "decimal128"
      },
      "actual_yield_kg_per_hectare": {
        "bsonType": "decimal128"
      },
      "status": {
        "bsonType": "string"
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

// Validation for growth_stages
db.runCommand({
  collMod: 'growth_stages',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "planting_id",
      "stage_name",
      "observation_date"
    ],
    "properties": {
      "planting_id": {
        "bsonType": "number"
      },
      "stage_name": {
        "bsonType": "string"
      },
      "stage_code": {
        "bsonType": "string"
      },
      "observation_date": {
        "bsonType": "date"
      },
      "gdd_accumulated": {
        "bsonType": "decimal128"
      },
      "plant_height_cm": {
        "bsonType": "decimal128"
      },
      "notes": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for sensors
db.runCommand({
  collMod: 'sensors',
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
      "sensor_type": {
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
      "depth_cm": {
        "bsonType": "number"
      },
      "height_m": {
        "bsonType": "decimal128"
      },
      "calibration_date": {
        "bsonType": "date"
      },
      "battery_type": {
        "bsonType": "string"
      },
      "is_active": {
        "bsonType": "boolean"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for sensor_readings
db.runCommand({
  collMod: 'sensor_readings',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "sensor_id",
      "timestamp"
    ],
    "properties": {
      "sensor_id": {
        "bsonType": "number"
      },
      "timestamp": {
        "bsonType": "date"
      },
      "value": {
        "bsonType": "decimal128"
      },
      "unit": {
        "bsonType": "string"
      },
      "quality_flag": {
        "bsonType": "string"
      },
      "battery_voltage": {
        "bsonType": "decimal128"
      }
    }
  }
}
});

// Validation for weather_stations
db.runCommand({
  collMod: 'weather_stations',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "farm_id"
    ],
    "properties": {
      "farm_id": {
        "bsonType": "number"
      },
      "station_name": {
        "bsonType": "string"
      },
      "latitude": {
        "bsonType": "decimal128"
      },
      "longitude": {
        "bsonType": "decimal128"
      },
      "elevation_m": {
        "bsonType": "number"
      },
      "installation_date": {
        "bsonType": "date"
      },
      "is_active": {
        "bsonType": "boolean"
      }
    }
  }
}
});

// Validation for weather_data
db.runCommand({
  collMod: 'weather_data',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "station_id",
      "observation_time"
    ],
    "properties": {
      "station_id": {
        "bsonType": "number"
      },
      "observation_time": {
        "bsonType": "date"
      },
      "temperature_c": {
        "bsonType": "decimal128"
      },
      "humidity_percent": {
        "bsonType": "decimal128"
      },
      "pressure_hpa": {
        "bsonType": "decimal128"
      },
      "rainfall_mm": {
        "bsonType": "decimal128"
      },
      "wind_speed_kmh": {
        "bsonType": "decimal128"
      },
      "wind_direction_degrees": {
        "bsonType": "number"
      },
      "solar_radiation_wm2": {
        "bsonType": "decimal128"
      },
      "evapotranspiration_mm": {
        "bsonType": "decimal128"
      },
      "dew_point_c": {
        "bsonType": "decimal128"
      }
    }
  }
}
});

// Validation for irrigation_systems
db.runCommand({
  collMod: 'irrigation_systems',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "field_id"
    ],
    "properties": {
      "field_id": {
        "bsonType": "number"
      },
      "system_type": {
        "bsonType": "string"
      },
      "flow_rate_lpm": {
        "bsonType": "decimal128"
      },
      "coverage_area_hectares": {
        "bsonType": "decimal128"
      },
      "efficiency_percentage": {
        "bsonType": "decimal128"
      },
      "installation_date": {
        "bsonType": "date"
      },
      "last_maintenance_date": {
        "bsonType": "date"
      },
      "is_active": {
        "bsonType": "boolean"
      }
    }
  }
}
});

// Validation for irrigation_events
db.runCommand({
  collMod: 'irrigation_events',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "system_id",
      "start_time"
    ],
    "properties": {
      "system_id": {
        "bsonType": "number"
      },
      "zone_id": {
        "bsonType": "number"
      },
      "start_time": {
        "bsonType": "date"
      },
      "end_time": {
        "bsonType": "date"
      },
      "water_amount_liters": {
        "bsonType": "decimal128"
      },
      "trigger_type": {
        "bsonType": "string"
      },
      "trigger_reason": {
        "bsonType": "string"
      },
      "soil_moisture_before": {
        "bsonType": "decimal128"
      },
      "soil_moisture_after": {
        "bsonType": "decimal128"
      },
      "notes": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for irrigation_schedules
db.runCommand({
  collMod: 'irrigation_schedules',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "system_id"
    ],
    "properties": {
      "system_id": {
        "bsonType": "number"
      },
      "schedule_name": {
        "bsonType": "string"
      },
      "days_of_week": {
        "bsonType": "array"
      },
      "start_time": {
        "bsonType": "string"
      },
      "duration_minutes": {
        "bsonType": "number"
      },
      "water_amount_mm": {
        "bsonType": "decimal128"
      },
      "moisture_threshold_min": {
        "bsonType": "decimal128"
      },
      "moisture_threshold_max": {
        "bsonType": "decimal128"
      },
      "is_active": {
        "bsonType": "boolean"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for fertilizer_applications
db.runCommand({
  collMod: 'fertilizer_applications',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "field_id",
      "application_date"
    ],
    "properties": {
      "field_id": {
        "bsonType": "number"
      },
      "zone_id": {
        "bsonType": "number"
      },
      "application_date": {
        "bsonType": "date"
      },
      "fertilizer_type": {
        "bsonType": "string"
      },
      "n_kg_per_hectare": {
        "bsonType": "decimal128"
      },
      "p_kg_per_hectare": {
        "bsonType": "decimal128"
      },
      "k_kg_per_hectare": {
        "bsonType": "decimal128"
      },
      "application_method": {
        "bsonType": "string"
      },
      "cost_per_hectare": {
        "bsonType": "decimal128"
      },
      "weather_conditions": {
        "bsonType": "string"
      },
      "operator_id": {
        "bsonType": "number"
      },
      "notes": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for pesticide_applications
db.runCommand({
  collMod: 'pesticide_applications',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "field_id",
      "application_date",
      "product_name"
    ],
    "properties": {
      "field_id": {
        "bsonType": "number"
      },
      "zone_id": {
        "bsonType": "number"
      },
      "application_date": {
        "bsonType": "date"
      },
      "product_name": {
        "bsonType": "string"
      },
      "active_ingredient": {
        "bsonType": "string"
      },
      "target_pest": {
        "bsonType": "string"
      },
      "application_rate_per_hectare": {
        "bsonType": "string"
      },
      "rei_hours": {
        "bsonType": "number"
      },
      "phi_days": {
        "bsonType": "number"
      },
      "application_method": {
        "bsonType": "string"
      },
      "weather_conditions": {
        "bsonType": "string"
      },
      "wind_speed_kmh": {
        "bsonType": "decimal128"
      },
      "temperature_c": {
        "bsonType": "decimal128"
      },
      "operator_id": {
        "bsonType": "number"
      },
      "notes": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for animals
db.runCommand({
  collMod: 'animals',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "farm_id"
    ],
    "properties": {
      "farm_id": {
        "bsonType": "number"
      },
      "animal_type": {
        "bsonType": "string"
      },
      "breed": {
        "bsonType": "string"
      },
      "gender": {
        "bsonType": "string"
      },
      "birth_date": {
        "bsonType": "date"
      },
      "weight_kg": {
        "bsonType": "decimal128"
      },
      "mother_id": {
        "bsonType": "number"
      },
      "father_id": {
        "bsonType": "number"
      },
      "purchase_date": {
        "bsonType": "date"
      },
      "purchase_price": {
        "bsonType": "decimal128"
      },
      "current_location": {
        "bsonType": "string"
      },
      "health_status": {
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

// Validation for health_records
db.runCommand({
  collMod: 'health_records',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "animal_id",
      "record_date"
    ],
    "properties": {
      "animal_id": {
        "bsonType": "number"
      },
      "record_date": {
        "bsonType": "date"
      },
      "record_type": {
        "bsonType": "string"
      },
      "description": {
        "bsonType": "string"
      },
      "medication": {
        "bsonType": "string"
      },
      "dosage": {
        "bsonType": "string"
      },
      "veterinarian_name": {
        "bsonType": "string"
      },
      "cost": {
        "bsonType": "decimal128"
      },
      "next_followup_date": {
        "bsonType": "date"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for milk_production
db.runCommand({
  collMod: 'milk_production',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "animal_id",
      "milking_date"
    ],
    "properties": {
      "animal_id": {
        "bsonType": "number"
      },
      "milking_date": {
        "bsonType": "date"
      },
      "milking_time": {
        "bsonType": "string"
      },
      "quantity_liters": {
        "bsonType": "decimal128"
      },
      "fat_percentage": {
        "bsonType": "decimal128"
      },
      "protein_percentage": {
        "bsonType": "decimal128"
      },
      "somatic_cell_count": {
        "bsonType": "number"
      },
      "temperature_c": {
        "bsonType": "decimal128"
      },
      "quality_grade": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for harvest_records
db.runCommand({
  collMod: 'harvest_records',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "planting_id",
      "harvest_date"
    ],
    "properties": {
      "planting_id": {
        "bsonType": "number"
      },
      "harvest_date": {
        "bsonType": "date"
      },
      "area_harvested_hectares": {
        "bsonType": "decimal128"
      },
      "total_yield_kg": {
        "bsonType": "decimal128"
      },
      "marketable_yield_kg": {
        "bsonType": "decimal128"
      },
      "moisture_percentage": {
        "bsonType": "decimal128"
      },
      "quality_grade": {
        "bsonType": "string"
      },
      "storage_location": {
        "bsonType": "string"
      },
      "harvest_method": {
        "bsonType": "string"
      },
      "weather_conditions": {
        "bsonType": "string"
      },
      "labor_hours": {
        "bsonType": "decimal128"
      },
      "harvest_cost": {
        "bsonType": "decimal128"
      },
      "notes": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for yield_predictions
db.runCommand({
  collMod: 'yield_predictions',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "planting_id",
      "prediction_date"
    ],
    "properties": {
      "planting_id": {
        "bsonType": "number"
      },
      "prediction_date": {
        "bsonType": "date"
      },
      "predicted_yield_kg_per_hectare": {
        "bsonType": "decimal128"
      },
      "confidence_level": {
        "bsonType": "decimal128"
      },
      "model_version": {
        "bsonType": "string"
      },
      "factors": {
        "bsonType": "object"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for operators
db.runCommand({
  collMod: 'operators',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "farm_id",
      "first_name",
      "last_name"
    ],
    "properties": {
      "farm_id": {
        "bsonType": "number"
      },
      "first_name": {
        "bsonType": "string"
      },
      "last_name": {
        "bsonType": "string"
      },
      "role": {
        "bsonType": "string"
      },
      "specialization": {
        "bsonType": "string"
      },
      "phone": {
        "bsonType": "string"
      },
      "email": {
        "bsonType": "string"
      },
      "hire_date": {
        "bsonType": "date"
      },
      "certifications": {
        "bsonType": "object"
      },
      "is_active": {
        "bsonType": "boolean"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for sensor_readings_hourly
db.runCommand({
  collMod: 'sensor_readings_hourly',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "sensor_id",
      "hour_timestamp"
    ],
    "properties": {
      "sensor_id": {
        "bsonType": "number"
      },
      "hour_timestamp": {
        "bsonType": "date"
      },
      "min_value": {
        "bsonType": "decimal128"
      },
      "max_value": {
        "bsonType": "decimal128"
      },
      "avg_value": {
        "bsonType": "decimal128"
      },
      "reading_count": {
        "bsonType": "number"
      }
    }
  }
}
});

// Validation for weather_daily_summary
db.runCommand({
  collMod: 'weather_daily_summary',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "station_id",
      "summary_date"
    ],
    "properties": {
      "station_id": {
        "bsonType": "number"
      },
      "summary_date": {
        "bsonType": "date"
      },
      "temp_min": {
        "bsonType": "decimal128"
      },
      "temp_max": {
        "bsonType": "decimal128"
      },
      "temp_avg": {
        "bsonType": "decimal128"
      },
      "humidity_avg": {
        "bsonType": "decimal128"
      },
      "rainfall_total": {
        "bsonType": "decimal128"
      },
      "wind_speed_max": {
        "bsonType": "decimal128"
      },
      "solar_radiation_total": {
        "bsonType": "decimal128"
      },
      "gdd_accumulated": {
        "bsonType": "decimal128"
      }
    }
  }
}
});
