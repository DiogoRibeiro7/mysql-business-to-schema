// MongoDB Migration Script
// Generated: 2026-02-17T23:16:48.681993
// From MySQL to MongoDB

use converted_db;

// Create collection: districts
db.createCollection('districts');

// Create collection: bins
db.createCollection('bins');

// Create collection: sensors
db.createCollection('sensors');

// Create collection: collection_routes
db.createCollection('collection_routes');

// Create collection: route_bin_assignments
db.createCollection('route_bin_assignments');

// Create collection: trucks
db.createCollection('trucks');

// Create collection: drivers
db.createCollection('drivers');

// Create collection: collection_schedules
db.createCollection('collection_schedules');

// Create collection: collection_events
db.createCollection('collection_events');

// Create collection: sensor_readings
db.createCollection('sensor_readings');

// Create collection: sensor_readings_hourly
db.createCollection('sensor_readings_hourly');

// Create collection: sensor_readings_daily
db.createCollection('sensor_readings_daily');

// Create collection: alert_thresholds
db.createCollection('alert_thresholds');

// Create collection: alerts
db.createCollection('alerts');

// Create collection: fill_rate_predictions
db.createCollection('fill_rate_predictions');

// Indexes for districts

// Indexes for bins

// Indexes for sensors

// Indexes for collection_routes

// Indexes for route_bin_assignments
db.route_bin_assignments.createIndex({"notes": "text"}, {"name": "route_bin_assignments_text"});

// Indexes for trucks

// Indexes for drivers

// Indexes for collection_schedules
db.collection_schedules.createIndex({"notes": "text"}, {"name": "collection_schedules_text"});

// Indexes for collection_events
db.collection_events.createIndex({"notes": "text"}, {"name": "collection_events_text"});

// Indexes for sensor_readings_hourly

// Indexes for sensor_readings_daily

// Indexes for alerts
db.alerts.createIndex({"message": "text"}, {"name": "alerts_text"});

// Indexes for fill_rate_predictions

// Validation for districts
db.runCommand({
  collMod: 'districts',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "name"
    ],
    "properties": {
      "name": {
        "bsonType": "string"
      },
      "area_km2": {
        "bsonType": "decimal128"
      },
      "population": {
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

// Validation for bins
db.runCommand({
  collMod: 'bins',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "district_id",
      "capacity_liters",
      "installation_date"
    ],
    "properties": {
      "district_id": {
        "bsonType": "number"
      },
      "bin_type": {
        "bsonType": "string"
      },
      "capacity_liters": {
        "bsonType": "number"
      },
      "latitude": {
        "bsonType": "decimal128"
      },
      "longitude": {
        "bsonType": "decimal128"
      },
      "address": {
        "bsonType": "string"
      },
      "location_type": {
        "bsonType": "string"
      },
      "installation_date": {
        "bsonType": "date"
      },
      "last_maintenance_date": {
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

// Validation for sensors
db.runCommand({
  collMod: 'sensors',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "bin_id",
      "installation_date",
      "reading_frequency_seconds"
    ],
    "properties": {
      "bin_id": {
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
      "firmware_version": {
        "bsonType": "string"
      },
      "installation_date": {
        "bsonType": "date"
      },
      "reading_frequency_seconds": {
        "bsonType": "number"
      },
      "battery_level": {
        "bsonType": "decimal128"
      },
      "last_reading_time": {
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

// Validation for collection_routes
db.runCommand({
  collMod: 'collection_routes',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "district_id"
    ],
    "properties": {
      "district_id": {
        "bsonType": "number"
      },
      "route_name": {
        "bsonType": "string"
      },
      "route_type": {
        "bsonType": "string"
      },
      "estimated_duration_minutes": {
        "bsonType": "number"
      },
      "estimated_distance_km": {
        "bsonType": "decimal128"
      },
      "active": {
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

// Validation for route_bin_assignments
db.runCommand({
  collMod: 'route_bin_assignments',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "route_id",
      "bin_id",
      "collection_order"
    ],
    "properties": {
      "route_id": {
        "bsonType": "number"
      },
      "bin_id": {
        "bsonType": "number"
      },
      "collection_order": {
        "bsonType": "number"
      },
      "estimated_collection_time": {
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

// Validation for trucks
db.runCommand({
  collMod: 'trucks',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "capacity_kg"
    ],
    "properties": {
      "manufacturer": {
        "bsonType": "string"
      },
      "model": {
        "bsonType": "string"
      },
      "year": {
        "bsonType": "number"
      },
      "capacity_kg": {
        "bsonType": "number"
      },
      "fuel_type": {
        "bsonType": "string"
      },
      "last_maintenance_date": {
        "bsonType": "date"
      },
      "next_maintenance_date": {
        "bsonType": "date"
      },
      "odometer_km": {
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

// Validation for drivers
db.runCommand({
  collMod: 'drivers',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "first_name",
      "last_name",
      "license_expiry_date",
      "hire_date"
    ],
    "properties": {
      "first_name": {
        "bsonType": "string"
      },
      "last_name": {
        "bsonType": "string"
      },
      "phone": {
        "bsonType": "string"
      },
      "license_expiry_date": {
        "bsonType": "date"
      },
      "hire_date": {
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

// Validation for collection_schedules
db.runCommand({
  collMod: 'collection_schedules',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "route_id",
      "truck_id",
      "driver_id",
      "scheduled_date",
      "scheduled_start_time",
      "scheduled_end_time"
    ],
    "properties": {
      "route_id": {
        "bsonType": "number"
      },
      "truck_id": {
        "bsonType": "number"
      },
      "driver_id": {
        "bsonType": "number"
      },
      "scheduled_date": {
        "bsonType": "date"
      },
      "scheduled_start_time": {
        "bsonType": "string"
      },
      "scheduled_end_time": {
        "bsonType": "string"
      },
      "status": {
        "bsonType": "string"
      },
      "actual_start_time": {
        "bsonType": "date"
      },
      "actual_end_time": {
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

// Validation for collection_events
db.runCommand({
  collMod: 'collection_events',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "bin_id",
      "truck_id",
      "driver_id",
      "collected_at"
    ],
    "properties": {
      "bin_id": {
        "bsonType": "number"
      },
      "schedule_id": {
        "bsonType": "number"
      },
      "truck_id": {
        "bsonType": "number"
      },
      "driver_id": {
        "bsonType": "number"
      },
      "collected_at": {
        "bsonType": "date"
      },
      "fill_level_before": {
        "bsonType": "decimal128"
      },
      "weight_kg": {
        "bsonType": "decimal128"
      },
      "collection_duration_seconds": {
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

// Validation for sensor_readings
db.runCommand({
  collMod: 'sensor_readings',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "sensor_id",
      "reading_time",
      "unit"
    ],
    "properties": {
      "sensor_id": {
        "bsonType": "number"
      },
      "reading_time": {
        "bsonType": "date"
      },
      "reading_value": {
        "bsonType": "decimal128"
      },
      "unit": {
        "bsonType": "string"
      },
      "quality": {
        "bsonType": "string"
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
      "hour_start"
    ],
    "properties": {
      "sensor_id": {
        "bsonType": "number"
      },
      "hour_start": {
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
      },
      "quality_good_count": {
        "bsonType": "number"
      },
      "quality_warning_count": {
        "bsonType": "number"
      },
      "quality_error_count": {
        "bsonType": "number"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for sensor_readings_daily
db.runCommand({
  collMod: 'sensor_readings_daily',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "sensor_id",
      "date"
    ],
    "properties": {
      "sensor_id": {
        "bsonType": "number"
      },
      "date": {
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
      "peak_hour": {
        "bsonType": "string"
      },
      "peak_value": {
        "bsonType": "decimal128"
      },
      "reading_count": {
        "bsonType": "number"
      },
      "quality_good_pct": {
        "bsonType": "decimal128"
      },
      "quality_warning_pct": {
        "bsonType": "decimal128"
      },
      "quality_error_pct": {
        "bsonType": "decimal128"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for alert_thresholds
db.runCommand({
  collMod: 'alert_thresholds',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "name"
    ],
    "properties": {
      "name": {
        "bsonType": "string"
      },
      "bin_type": {
        "bsonType": "string"
      },
      "sensor_type": {
        "bsonType": "string"
      },
      "warning_value": {
        "bsonType": "decimal128"
      },
      "critical_value": {
        "bsonType": "decimal128"
      },
      "check_interval_seconds": {
        "bsonType": "number"
      },
      "active": {
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

// Validation for alerts
db.runCommand({
  collMod: 'alerts',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "bin_id",
      "triggered_at"
    ],
    "properties": {
      "bin_id": {
        "bsonType": "number"
      },
      "sensor_id": {
        "bsonType": "number"
      },
      "threshold_id": {
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
      "resolved_at": {
        "bsonType": "date"
      },
      "alert_value": {
        "bsonType": "decimal128"
      },
      "message": {
        "bsonType": "string"
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
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for fill_rate_predictions
db.runCommand({
  collMod: 'fill_rate_predictions',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "bin_id",
      "prediction_date",
      "prediction_hour"
    ],
    "properties": {
      "bin_id": {
        "bsonType": "number"
      },
      "prediction_date": {
        "bsonType": "date"
      },
      "prediction_hour": {
        "bsonType": "string"
      },
      "predicted_fill_rate": {
        "bsonType": "decimal128"
      },
      "confidence_score": {
        "bsonType": "decimal128"
      },
      "model_version": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});
