// MongoDB Migration Script
// Generated: 2026-02-17T23:16:48.710316
// From MySQL to MongoDB

use converted_db;

// Create collection: factories
db.createCollection('factories');

// Create collection: production_lines
db.createCollection('production_lines');

// Create collection: machines
db.createCollection('machines');

// Create collection: sensors
db.createCollection('sensors');

// Create collection: sensor_readings
db.createCollection('sensor_readings');

// Create collection: products
db.createCollection('products');

// Create collection: work_orders
db.createCollection('work_orders');

// Create collection: production_runs
db.createCollection('production_runs');

// Create collection: quality_inspections
db.createCollection('quality_inspections');

// Create collection: defects
db.createCollection('defects');

// Create collection: oee_metrics
db.createCollection('oee_metrics');

// Create collection: maintenance_schedules
db.createCollection('maintenance_schedules');

// Create collection: maintenance_records
db.createCollection('maintenance_records');

// Create collection: alerts
db.createCollection('alerts');

// Create collection: downtime_events
db.createCollection('downtime_events');

// Create collection: operators
db.createCollection('operators');

// Create collection: shift_logs
db.createCollection('shift_logs');

// Create collection: sensor_readings_hourly
db.createCollection('sensor_readings_hourly');

// Indexes for machines

// Indexes for sensors

// Indexes for products

// Indexes for work_orders

// Indexes for production_runs
db.production_runs.createIndex({"notes": "text"}, {"name": "production_runs_text"});

// Indexes for quality_inspections
db.quality_inspections.createIndex({"notes": "text"}, {"name": "quality_inspections_text"});

// Indexes for defects
db.defects.createIndex({"corrective_action": "text"}, {"name": "defects_text"});

// Indexes for oee_metrics

// Indexes for maintenance_records
db.maintenance_records.createIndex({"findings": "text", "actions_taken": "text", "next_action": "text"}, {"name": "maintenance_records_text"});

// Indexes for alerts
db.alerts.createIndex({"message": "text", "resolution_notes": "text"}, {"name": "alerts_text"});

// Indexes for operators

// Indexes for shift_logs
db.shift_logs.createIndex({"notes": "text"}, {"name": "shift_logs_text"});

// Validation for factories
db.runCommand({
  collMod: 'factories',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "factory_name",
      "location",
      "country"
    ],
    "properties": {
      "factory_name": {
        "bsonType": "string"
      },
      "factory_type": {
        "bsonType": "string"
      },
      "location": {
        "bsonType": "string"
      },
      "country": {
        "bsonType": "string"
      },
      "timezone": {
        "bsonType": "string"
      },
      "established_date": {
        "bsonType": "date"
      },
      "total_area_sqm": {
        "bsonType": "decimal128"
      },
      "employee_count": {
        "bsonType": "number"
      },
      "shifts_per_day": {
        "bsonType": "number"
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

// Validation for production_lines
db.runCommand({
  collMod: 'production_lines',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "factory_id",
      "line_name"
    ],
    "properties": {
      "factory_id": {
        "bsonType": "number"
      },
      "line_name": {
        "bsonType": "string"
      },
      "line_type": {
        "bsonType": "string"
      },
      "capacity_per_hour": {
        "bsonType": "number"
      },
      "product_types": {
        "bsonType": "object"
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

// Validation for machines
db.runCommand({
  collMod: 'machines',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "line_id",
      "machine_name"
    ],
    "properties": {
      "line_id": {
        "bsonType": "number"
      },
      "machine_name": {
        "bsonType": "string"
      },
      "machine_type": {
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
      "installation_date": {
        "bsonType": "date"
      },
      "warranty_expiry": {
        "bsonType": "date"
      },
      "ideal_cycle_time_seconds": {
        "bsonType": "decimal128"
      },
      "max_capacity_per_hour": {
        "bsonType": "number"
      },
      "power_consumption_kw": {
        "bsonType": "decimal128"
      },
      "status": {
        "bsonType": "string"
      },
      "total_operating_hours": {
        "bsonType": "decimal128"
      },
      "total_cycle_count": {
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

// Validation for sensors
db.runCommand({
  collMod: 'sensors',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "machine_id",
      "unit_of_measure"
    ],
    "properties": {
      "machine_id": {
        "bsonType": "number"
      },
      "sensor_type": {
        "bsonType": "string"
      },
      "unit_of_measure": {
        "bsonType": "string"
      },
      "min_value": {
        "bsonType": "decimal128"
      },
      "max_value": {
        "bsonType": "decimal128"
      },
      "normal_min": {
        "bsonType": "decimal128"
      },
      "normal_max": {
        "bsonType": "decimal128"
      },
      "critical_min": {
        "bsonType": "decimal128"
      },
      "critical_max": {
        "bsonType": "decimal128"
      },
      "sampling_rate_seconds": {
        "bsonType": "number"
      },
      "calibration_date": {
        "bsonType": "date"
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
      "quality": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for products
db.runCommand({
  collMod: 'products',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "product_name"
    ],
    "properties": {
      "product_name": {
        "bsonType": "string"
      },
      "product_category": {
        "bsonType": "string"
      },
      "unit_of_measure": {
        "bsonType": "string"
      },
      "standard_cycle_time_seconds": {
        "bsonType": "decimal128"
      },
      "weight_kg": {
        "bsonType": "decimal128"
      },
      "quality_specs": {
        "bsonType": "object"
      },
      "bom": {
        "bsonType": "object"
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

// Validation for work_orders
db.runCommand({
  collMod: 'work_orders',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "product_id",
      "line_id",
      "planned_quantity",
      "planned_start_time",
      "planned_end_time"
    ],
    "properties": {
      "product_id": {
        "bsonType": "number"
      },
      "line_id": {
        "bsonType": "number"
      },
      "planned_quantity": {
        "bsonType": "number"
      },
      "planned_start_time": {
        "bsonType": "date"
      },
      "planned_end_time": {
        "bsonType": "date"
      },
      "actual_start_time": {
        "bsonType": "date"
      },
      "actual_end_time": {
        "bsonType": "date"
      },
      "produced_quantity": {
        "bsonType": "number"
      },
      "good_quantity": {
        "bsonType": "number"
      },
      "rejected_quantity": {
        "bsonType": "number"
      },
      "status": {
        "bsonType": "string"
      },
      "priority": {
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

// Validation for production_runs
db.runCommand({
  collMod: 'production_runs',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "order_id",
      "machine_id",
      "start_time"
    ],
    "properties": {
      "order_id": {
        "bsonType": "number"
      },
      "machine_id": {
        "bsonType": "number"
      },
      "operator_id": {
        "bsonType": "number"
      },
      "start_time": {
        "bsonType": "date"
      },
      "end_time": {
        "bsonType": "date"
      },
      "quantity_produced": {
        "bsonType": "number"
      },
      "quantity_good": {
        "bsonType": "number"
      },
      "quantity_rejected": {
        "bsonType": "number"
      },
      "cycle_time_actual": {
        "bsonType": "decimal128"
      },
      "downtime_minutes": {
        "bsonType": "decimal128"
      },
      "speed_percentage": {
        "bsonType": "decimal128"
      },
      "notes": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for quality_inspections
db.runCommand({
  collMod: 'quality_inspections',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "run_id",
      "product_id",
      "inspection_time"
    ],
    "properties": {
      "run_id": {
        "bsonType": "number"
      },
      "product_id": {
        "bsonType": "number"
      },
      "inspection_time": {
        "bsonType": "date"
      },
      "inspector_id": {
        "bsonType": "number"
      },
      "sample_size": {
        "bsonType": "number"
      },
      "defects_found": {
        "bsonType": "number"
      },
      "defect_types": {
        "bsonType": "object"
      },
      "measurements": {
        "bsonType": "object"
      },
      "pass_fail": {
        "bsonType": "string"
      },
      "notes": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for defects
db.runCommand({
  collMod: 'defects',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "inspection_id",
      "defect_type"
    ],
    "properties": {
      "inspection_id": {
        "bsonType": "number"
      },
      "defect_type": {
        "bsonType": "string"
      },
      "severity": {
        "bsonType": "string"
      },
      "quantity": {
        "bsonType": "number"
      },
      "root_cause": {
        "bsonType": "string"
      },
      "corrective_action": {
        "bsonType": "string"
      },
      "image_url": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for oee_metrics
db.runCommand({
  collMod: 'oee_metrics',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "machine_id",
      "line_id",
      "metric_timestamp",
      "hour_start",
      "hour_end"
    ],
    "properties": {
      "machine_id": {
        "bsonType": "number"
      },
      "line_id": {
        "bsonType": "number"
      },
      "metric_timestamp": {
        "bsonType": "date"
      },
      "hour_start": {
        "bsonType": "date"
      },
      "hour_end": {
        "bsonType": "date"
      },
      "planned_production_time_min": {
        "bsonType": "decimal128"
      },
      "operating_time_min": {
        "bsonType": "decimal128"
      },
      "downtime_min": {
        "bsonType": "decimal128"
      },
      "availability_percentage": {
        "bsonType": "decimal128"
      },
      "ideal_cycle_time_sec": {
        "bsonType": "decimal128"
      },
      "total_pieces_produced": {
        "bsonType": "number"
      },
      "performance_percentage": {
        "bsonType": "decimal128"
      },
      "good_pieces": {
        "bsonType": "number"
      },
      "total_pieces": {
        "bsonType": "number"
      },
      "quality_percentage": {
        "bsonType": "decimal128"
      },
      "oee_percentage": {
        "bsonType": "decimal128"
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
      "machine_id"
    ],
    "properties": {
      "machine_id": {
        "bsonType": "number"
      },
      "maintenance_type": {
        "bsonType": "string"
      },
      "frequency_days": {
        "bsonType": "number"
      },
      "last_performed": {
        "bsonType": "date"
      },
      "next_due": {
        "bsonType": "date"
      },
      "estimated_duration_hours": {
        "bsonType": "decimal128"
      },
      "parts_required": {
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

// Validation for maintenance_records
db.runCommand({
  collMod: 'maintenance_records',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "machine_id",
      "start_time"
    ],
    "properties": {
      "machine_id": {
        "bsonType": "number"
      },
      "schedule_id": {
        "bsonType": "number"
      },
      "maintenance_type": {
        "bsonType": "string"
      },
      "start_time": {
        "bsonType": "date"
      },
      "end_time": {
        "bsonType": "date"
      },
      "technician_id": {
        "bsonType": "number"
      },
      "downtime_minutes": {
        "bsonType": "decimal128"
      },
      "parts_replaced": {
        "bsonType": "object"
      },
      "cost": {
        "bsonType": "decimal128"
      },
      "findings": {
        "bsonType": "string"
      },
      "actions_taken": {
        "bsonType": "string"
      },
      "next_action": {
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

// Validation for alerts
db.runCommand({
  collMod: 'alerts',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "source_id",
      "alert_type",
      "message",
      "triggered_at"
    ],
    "properties": {
      "source_type": {
        "bsonType": "string"
      },
      "source_id": {
        "bsonType": "number"
      },
      "alert_type": {
        "bsonType": "string"
      },
      "severity": {
        "bsonType": "string"
      },
      "message": {
        "bsonType": "string"
      },
      "threshold_value": {
        "bsonType": "decimal128"
      },
      "actual_value": {
        "bsonType": "decimal128"
      },
      "triggered_at": {
        "bsonType": "date"
      },
      "acknowledged_at": {
        "bsonType": "date"
      },
      "acknowledged_by": {
        "bsonType": "number"
      },
      "resolved_at": {
        "bsonType": "date"
      },
      "resolved_by": {
        "bsonType": "number"
      },
      "resolution_notes": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for downtime_events
db.runCommand({
  collMod: 'downtime_events',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "machine_id",
      "line_id",
      "start_time"
    ],
    "properties": {
      "machine_id": {
        "bsonType": "number"
      },
      "line_id": {
        "bsonType": "number"
      },
      "start_time": {
        "bsonType": "date"
      },
      "end_time": {
        "bsonType": "date"
      },
      "duration_minutes": {
        "bsonType": "decimal128"
      },
      "reason_category": {
        "bsonType": "string"
      },
      "reason_detail": {
        "bsonType": "string"
      },
      "impact_level": {
        "bsonType": "string"
      },
      "lost_production_units": {
        "bsonType": "number"
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
      "first_name",
      "last_name",
      "factory_id"
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
      "shift": {
        "bsonType": "string"
      },
      "skill_level": {
        "bsonType": "string"
      },
      "certifications": {
        "bsonType": "object"
      },
      "factory_id": {
        "bsonType": "number"
      },
      "hire_date": {
        "bsonType": "date"
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

// Validation for shift_logs
db.runCommand({
  collMod: 'shift_logs',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "shift_date",
      "line_id"
    ],
    "properties": {
      "shift_date": {
        "bsonType": "date"
      },
      "shift_type": {
        "bsonType": "string"
      },
      "line_id": {
        "bsonType": "number"
      },
      "supervisor_id": {
        "bsonType": "number"
      },
      "operators_count": {
        "bsonType": "number"
      },
      "production_target": {
        "bsonType": "number"
      },
      "production_actual": {
        "bsonType": "number"
      },
      "oee_target": {
        "bsonType": "decimal128"
      },
      "oee_actual": {
        "bsonType": "decimal128"
      },
      "safety_incidents": {
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
