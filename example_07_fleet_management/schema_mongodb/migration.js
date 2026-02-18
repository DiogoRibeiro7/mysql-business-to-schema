// MongoDB Migration Script
// Generated: 2026-02-17T23:16:48.731496
// From MySQL to MongoDB

use converted_db;

// Create collection: companies
db.createCollection('companies');

// Create collection: depots
db.createCollection('depots');

// Create collection: vehicles
db.createCollection('vehicles');

// Create collection: vehicle_specs
db.createCollection('vehicle_specs');

// Create collection: drivers
db.createCollection('drivers');

// Create collection: driver_certifications
db.createCollection('driver_certifications');

// Create collection: gps_positions
db.createCollection('gps_positions');

// Create collection: trips
db.createCollection('trips');

// Create collection: stops
db.createCollection('stops');

// Create collection: driver_events
db.createCollection('driver_events');

// Create collection: driver_scores
db.createCollection('driver_scores');

// Create collection: routes
db.createCollection('routes');

// Create collection: geofences
db.createCollection('geofences');

// Create collection: geofence_events
db.createCollection('geofence_events');

// Create collection: fuel_transactions
db.createCollection('fuel_transactions');

// Create collection: maintenance_records
db.createCollection('maintenance_records');

// Create collection: vehicle_diagnostics
db.createCollection('vehicle_diagnostics');

// Create collection: driver_logs
db.createCollection('driver_logs');

// Create collection: hos_violations
db.createCollection('hos_violations');

// Create collection: dvir_reports
db.createCollection('dvir_reports');

// Create collection: messages
db.createCollection('messages');

// Create collection: vehicle_daily_summary
db.createCollection('vehicle_daily_summary');

// Create collection: gps_positions_hourly
db.createCollection('gps_positions_hourly');

// Indexes for companies

// Indexes for depots

// Indexes for vehicles

// Indexes for vehicle_specs

// Indexes for drivers

// Indexes for stops
db.stops.createIndex({"notes": "text"}, {"name": "stops_text"});

// Indexes for driver_scores

// Indexes for routes

// Indexes for maintenance_records
db.maintenance_records.createIndex({"description": "text"}, {"name": "maintenance_records_text"});

// Indexes for driver_logs
db.driver_logs.createIndex({"notes": "text"}, {"name": "driver_logs_text"});

// Indexes for hos_violations
db.hos_violations.createIndex({"description": "text"}, {"name": "hos_violations_text"});

// Indexes for dvir_reports

// Indexes for messages
db.messages.createIndex({"message_text": "text"}, {"name": "messages_text"});

// Indexes for vehicle_daily_summary

// Validation for companies
db.runCommand({
  collMod: 'companies',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "company_name"
    ],
    "properties": {
      "company_name": {
        "bsonType": "string"
      },
      "mc_number": {
        "bsonType": "string"
      },
      "address": {
        "bsonType": "string"
      },
      "city": {
        "bsonType": "string"
      },
      "state": {
        "bsonType": "string"
      },
      "zip_code": {
        "bsonType": "string"
      },
      "country": {
        "bsonType": "string"
      },
      "phone": {
        "bsonType": "string"
      },
      "email": {
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

// Validation for depots
db.runCommand({
  collMod: 'depots',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "company_id",
      "depot_name"
    ],
    "properties": {
      "company_id": {
        "bsonType": "number"
      },
      "depot_name": {
        "bsonType": "string"
      },
      "address": {
        "bsonType": "string"
      },
      "city": {
        "bsonType": "string"
      },
      "state": {
        "bsonType": "string"
      },
      "latitude": {
        "bsonType": "decimal128"
      },
      "longitude": {
        "bsonType": "decimal128"
      },
      "timezone": {
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

// Validation for vehicles
db.runCommand({
  collMod: 'vehicles',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "company_id"
    ],
    "properties": {
      "company_id": {
        "bsonType": "number"
      },
      "depot_id": {
        "bsonType": "number"
      },
      "vehicle_type": {
        "bsonType": "string"
      },
      "make": {
        "bsonType": "string"
      },
      "model": {
        "bsonType": "string"
      },
      "year": {
        "bsonType": "number"
      },
      "color": {
        "bsonType": "string"
      },
      "fuel_type": {
        "bsonType": "string"
      },
      "fuel_capacity_gallons": {
        "bsonType": "decimal128"
      },
      "odometer_miles": {
        "bsonType": "decimal128"
      },
      "engine_hours": {
        "bsonType": "decimal128"
      },
      "purchase_date": {
        "bsonType": "date"
      },
      "registration_expiry": {
        "bsonType": "date"
      },
      "insurance_expiry": {
        "bsonType": "date"
      },
      "last_service_date": {
        "bsonType": "date"
      },
      "last_service_miles": {
        "bsonType": "decimal128"
      },
      "next_service_miles": {
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

// Validation for vehicle_specs
db.runCommand({
  collMod: 'vehicle_specs',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [],
    "properties": {
      "gross_vehicle_weight_lbs": {
        "bsonType": "number"
      },
      "cargo_capacity_lbs": {
        "bsonType": "number"
      },
      "cargo_volume_cubic_ft": {
        "bsonType": "decimal128"
      },
      "mpg_city": {
        "bsonType": "decimal128"
      },
      "mpg_highway": {
        "bsonType": "decimal128"
      },
      "has_gps": {
        "bsonType": "boolean"
      },
      "has_eld": {
        "bsonType": "boolean"
      },
      "has_camera": {
        "bsonType": "boolean"
      },
      "has_temperature_control": {
        "bsonType": "boolean"
      },
      "has_liftgate": {
        "bsonType": "boolean"
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
      "company_id",
      "first_name",
      "last_name",
      "license_expiry"
    ],
    "properties": {
      "company_id": {
        "bsonType": "number"
      },
      "first_name": {
        "bsonType": "string"
      },
      "last_name": {
        "bsonType": "string"
      },
      "phone": {
        "bsonType": "string"
      },
      "license_state": {
        "bsonType": "string"
      },
      "license_class": {
        "bsonType": "string"
      },
      "license_expiry": {
        "bsonType": "date"
      },
      "medical_cert_expiry": {
        "bsonType": "date"
      },
      "hire_date": {
        "bsonType": "date"
      },
      "birth_date": {
        "bsonType": "date"
      },
      "address": {
        "bsonType": "string"
      },
      "city": {
        "bsonType": "string"
      },
      "state": {
        "bsonType": "string"
      },
      "zip_code": {
        "bsonType": "string"
      },
      "emergency_contact": {
        "bsonType": "string"
      },
      "emergency_phone": {
        "bsonType": "string"
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

// Validation for driver_certifications
db.runCommand({
  collMod: 'driver_certifications',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "driver_id",
      "certification_type"
    ],
    "properties": {
      "driver_id": {
        "bsonType": "number"
      },
      "certification_type": {
        "bsonType": "string"
      },
      "certification_number": {
        "bsonType": "string"
      },
      "issue_date": {
        "bsonType": "date"
      },
      "expiry_date": {
        "bsonType": "date"
      },
      "issuing_authority": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for gps_positions
db.runCommand({
  collMod: 'gps_positions',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "vehicle_id",
      "timestamp"
    ],
    "properties": {
      "vehicle_id": {
        "bsonType": "number"
      },
      "driver_id": {
        "bsonType": "number"
      },
      "timestamp": {
        "bsonType": "date"
      },
      "latitude": {
        "bsonType": "decimal128"
      },
      "longitude": {
        "bsonType": "decimal128"
      },
      "speed_mph": {
        "bsonType": "decimal128"
      },
      "heading": {
        "bsonType": "number"
      },
      "altitude_feet": {
        "bsonType": "number"
      },
      "satellites": {
        "bsonType": "number"
      },
      "hdop": {
        "bsonType": "decimal128"
      },
      "ignition_on": {
        "bsonType": "boolean"
      },
      "odometer_miles": {
        "bsonType": "decimal128"
      },
      "engine_hours": {
        "bsonType": "decimal128"
      },
      "fuel_level_percent": {
        "bsonType": "decimal128"
      }
    }
  }
}
});

// Validation for trips
db.runCommand({
  collMod: 'trips',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "vehicle_id",
      "driver_id",
      "start_time"
    ],
    "properties": {
      "vehicle_id": {
        "bsonType": "number"
      },
      "driver_id": {
        "bsonType": "number"
      },
      "start_time": {
        "bsonType": "date"
      },
      "end_time": {
        "bsonType": "date"
      },
      "start_location": {
        "bsonType": "string"
      },
      "start_latitude": {
        "bsonType": "decimal128"
      },
      "start_longitude": {
        "bsonType": "decimal128"
      },
      "end_location": {
        "bsonType": "string"
      },
      "end_latitude": {
        "bsonType": "decimal128"
      },
      "end_longitude": {
        "bsonType": "decimal128"
      },
      "distance_miles": {
        "bsonType": "decimal128"
      },
      "duration_minutes": {
        "bsonType": "number"
      },
      "max_speed_mph": {
        "bsonType": "decimal128"
      },
      "avg_speed_mph": {
        "bsonType": "decimal128"
      },
      "fuel_consumed_gallons": {
        "bsonType": "decimal128"
      },
      "idle_time_minutes": {
        "bsonType": "number"
      },
      "stops_count": {
        "bsonType": "number"
      },
      "harsh_events_count": {
        "bsonType": "number"
      },
      "status": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for stops
db.runCommand({
  collMod: 'stops',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "trip_id",
      "stop_sequence",
      "arrival_time"
    ],
    "properties": {
      "trip_id": {
        "bsonType": "number"
      },
      "stop_sequence": {
        "bsonType": "number"
      },
      "arrival_time": {
        "bsonType": "date"
      },
      "departure_time": {
        "bsonType": "date"
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
      "stop_type": {
        "bsonType": "string"
      },
      "duration_minutes": {
        "bsonType": "number"
      },
      "notes": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for driver_events
db.runCommand({
  collMod: 'driver_events',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "vehicle_id",
      "driver_id",
      "timestamp"
    ],
    "properties": {
      "vehicle_id": {
        "bsonType": "number"
      },
      "driver_id": {
        "bsonType": "number"
      },
      "trip_id": {
        "bsonType": "number"
      },
      "event_type": {
        "bsonType": "string"
      },
      "timestamp": {
        "bsonType": "date"
      },
      "latitude": {
        "bsonType": "decimal128"
      },
      "longitude": {
        "bsonType": "decimal128"
      },
      "speed_mph": {
        "bsonType": "decimal128"
      },
      "g_force": {
        "bsonType": "decimal128"
      },
      "speed_limit_mph": {
        "bsonType": "number"
      },
      "duration_seconds": {
        "bsonType": "number"
      },
      "severity": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for driver_scores
db.runCommand({
  collMod: 'driver_scores',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "driver_id",
      "score_date"
    ],
    "properties": {
      "driver_id": {
        "bsonType": "number"
      },
      "score_date": {
        "bsonType": "date"
      },
      "safety_score": {
        "bsonType": "decimal128"
      },
      "fuel_efficiency_score": {
        "bsonType": "decimal128"
      },
      "compliance_score": {
        "bsonType": "decimal128"
      },
      "overall_score": {
        "bsonType": "decimal128"
      },
      "miles_driven": {
        "bsonType": "decimal128"
      },
      "trips_count": {
        "bsonType": "number"
      },
      "harsh_events_count": {
        "bsonType": "number"
      },
      "speeding_minutes": {
        "bsonType": "number"
      },
      "idle_minutes": {
        "bsonType": "number"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for routes
db.runCommand({
  collMod: 'routes',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "route_name"
    ],
    "properties": {
      "route_name": {
        "bsonType": "string"
      },
      "depot_id": {
        "bsonType": "number"
      },
      "total_distance_miles": {
        "bsonType": "decimal128"
      },
      "estimated_duration_minutes": {
        "bsonType": "number"
      },
      "waypoints": {
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

// Validation for geofences
db.runCommand({
  collMod: 'geofences',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "company_id",
      "geofence_name"
    ],
    "properties": {
      "company_id": {
        "bsonType": "number"
      },
      "geofence_name": {
        "bsonType": "string"
      },
      "geofence_type": {
        "bsonType": "string"
      },
      "center_latitude": {
        "bsonType": "decimal128"
      },
      "center_longitude": {
        "bsonType": "decimal128"
      },
      "radius_meters": {
        "bsonType": "number"
      },
      "polygon": {
        "bsonType": "object"
      },
      "alert_on_entry": {
        "bsonType": "boolean"
      },
      "alert_on_exit": {
        "bsonType": "boolean"
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

// Validation for geofence_events
db.runCommand({
  collMod: 'geofence_events',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "geofence_id",
      "vehicle_id",
      "timestamp"
    ],
    "properties": {
      "geofence_id": {
        "bsonType": "number"
      },
      "vehicle_id": {
        "bsonType": "number"
      },
      "driver_id": {
        "bsonType": "number"
      },
      "event_type": {
        "bsonType": "string"
      },
      "timestamp": {
        "bsonType": "date"
      },
      "duration_minutes": {
        "bsonType": "number"
      },
      "time": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for fuel_transactions
db.runCommand({
  collMod: 'fuel_transactions',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "vehicle_id",
      "transaction_date"
    ],
    "properties": {
      "vehicle_id": {
        "bsonType": "number"
      },
      "driver_id": {
        "bsonType": "number"
      },
      "transaction_date": {
        "bsonType": "date"
      },
      "station_name": {
        "bsonType": "string"
      },
      "station_address": {
        "bsonType": "string"
      },
      "latitude": {
        "bsonType": "decimal128"
      },
      "longitude": {
        "bsonType": "decimal128"
      },
      "gallons": {
        "bsonType": "decimal128"
      },
      "price_per_gallon": {
        "bsonType": "decimal128"
      },
      "total_cost": {
        "bsonType": "decimal128"
      },
      "odometer_miles": {
        "bsonType": "decimal128"
      },
      "payment_method": {
        "bsonType": "string"
      },
      "receipt_number": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for maintenance_records
db.runCommand({
  collMod: 'maintenance_records',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "vehicle_id",
      "service_date"
    ],
    "properties": {
      "vehicle_id": {
        "bsonType": "number"
      },
      "maintenance_type": {
        "bsonType": "string"
      },
      "service_date": {
        "bsonType": "date"
      },
      "odometer_miles": {
        "bsonType": "decimal128"
      },
      "engine_hours": {
        "bsonType": "decimal128"
      },
      "service_provider": {
        "bsonType": "string"
      },
      "description": {
        "bsonType": "string"
      },
      "parts_cost": {
        "bsonType": "decimal128"
      },
      "labor_cost": {
        "bsonType": "decimal128"
      },
      "total_cost": {
        "bsonType": "decimal128"
      },
      "next_service_miles": {
        "bsonType": "decimal128"
      },
      "next_service_date": {
        "bsonType": "date"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for vehicle_diagnostics
db.runCommand({
  collMod: 'vehicle_diagnostics',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "vehicle_id",
      "timestamp"
    ],
    "properties": {
      "vehicle_id": {
        "bsonType": "number"
      },
      "timestamp": {
        "bsonType": "date"
      },
      "engine_rpm": {
        "bsonType": "number"
      },
      "engine_load_percent": {
        "bsonType": "decimal128"
      },
      "coolant_temp_f": {
        "bsonType": "number"
      },
      "oil_pressure_psi": {
        "bsonType": "decimal128"
      },
      "battery_voltage": {
        "bsonType": "decimal128"
      },
      "check_engine_light": {
        "bsonType": "boolean"
      },
      "dtc_codes": {
        "bsonType": "object"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for driver_logs
db.runCommand({
  collMod: 'driver_logs',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "driver_id",
      "log_date",
      "start_time"
    ],
    "properties": {
      "driver_id": {
        "bsonType": "number"
      },
      "log_date": {
        "bsonType": "date"
      },
      "duty_status": {
        "bsonType": "string"
      },
      "start_time": {
        "bsonType": "date"
      },
      "end_time": {
        "bsonType": "date"
      },
      "duration_minutes": {
        "bsonType": "number"
      },
      "location": {
        "bsonType": "string"
      },
      "latitude": {
        "bsonType": "decimal128"
      },
      "longitude": {
        "bsonType": "decimal128"
      },
      "vehicle_id": {
        "bsonType": "number"
      },
      "odometer_start": {
        "bsonType": "decimal128"
      },
      "odometer_end": {
        "bsonType": "decimal128"
      },
      "notes": {
        "bsonType": "string"
      },
      "certified": {
        "bsonType": "boolean"
      },
      "certified_at": {
        "bsonType": "date"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for hos_violations
db.runCommand({
  collMod: 'hos_violations',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "driver_id",
      "violation_date"
    ],
    "properties": {
      "driver_id": {
        "bsonType": "number"
      },
      "violation_date": {
        "bsonType": "date"
      },
      "violation_type": {
        "bsonType": "string"
      },
      "duration_minutes": {
        "bsonType": "number"
      },
      "description": {
        "bsonType": "string"
      },
      "severity": {
        "bsonType": "string"
      },
      "resolved": {
        "bsonType": "boolean"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for dvir_reports
db.runCommand({
  collMod: 'dvir_reports',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "vehicle_id",
      "driver_id",
      "inspection_date"
    ],
    "properties": {
      "vehicle_id": {
        "bsonType": "number"
      },
      "driver_id": {
        "bsonType": "number"
      },
      "inspection_date": {
        "bsonType": "date"
      },
      "inspection_type": {
        "bsonType": "string"
      },
      "odometer_miles": {
        "bsonType": "decimal128"
      },
      "defects_found": {
        "bsonType": "boolean"
      },
      "defect_details": {
        "bsonType": "object"
      },
      "signature_driver": {
        "bsonType": "string"
      },
      "signature_mechanic": {
        "bsonType": "string"
      },
      "repaired": {
        "bsonType": "boolean"
      },
      "repair_date": {
        "bsonType": "date"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for messages
db.runCommand({
  collMod: 'messages',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "message_text"
    ],
    "properties": {
      "sender_type": {
        "bsonType": "string"
      },
      "sender_id": {
        "bsonType": "number"
      },
      "recipient_type": {
        "bsonType": "string"
      },
      "recipient_id": {
        "bsonType": "number"
      },
      "message_text": {
        "bsonType": "string"
      },
      "priority": {
        "bsonType": "string"
      },
      "read_status": {
        "bsonType": "boolean"
      },
      "sent_at": {
        "bsonType": "date"
      },
      "read_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for vehicle_daily_summary
db.runCommand({
  collMod: 'vehicle_daily_summary',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "vehicle_id",
      "summary_date"
    ],
    "properties": {
      "vehicle_id": {
        "bsonType": "number"
      },
      "summary_date": {
        "bsonType": "date"
      },
      "total_miles": {
        "bsonType": "decimal128"
      },
      "total_hours": {
        "bsonType": "decimal128"
      },
      "total_trips": {
        "bsonType": "number"
      },
      "total_stops": {
        "bsonType": "number"
      },
      "total_fuel_gallons": {
        "bsonType": "decimal128"
      },
      "avg_mpg": {
        "bsonType": "decimal128"
      },
      "total_idle_minutes": {
        "bsonType": "number"
      },
      "harsh_events_count": {
        "bsonType": "number"
      },
      "max_speed_mph": {
        "bsonType": "decimal128"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for gps_positions_hourly
db.runCommand({
  collMod: 'gps_positions_hourly',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "vehicle_id",
      "hour_timestamp"
    ],
    "properties": {
      "vehicle_id": {
        "bsonType": "number"
      },
      "hour_timestamp": {
        "bsonType": "date"
      },
      "avg_speed_mph": {
        "bsonType": "decimal128"
      },
      "max_speed_mph": {
        "bsonType": "decimal128"
      },
      "distance_miles": {
        "bsonType": "decimal128"
      },
      "position_count": {
        "bsonType": "number"
      },
      "idle_minutes": {
        "bsonType": "number"
      }
    }
  }
}
});
