# MongoDB Schema for example_05_industrial_iot

Converted from MySQL on 2026-02-17T23:16:48.710996

## Collections

### factories

**Document Structure:**
```json
{
  "factory_name": {
    "type": "String",
    "required": true
  },
  "factory_type": {
    "type": "String",
    "required": false
  },
  "location": {
    "type": "String",
    "required": true
  },
  "country": {
    "type": "String",
    "required": true
  },
  "timezone": {
    "type": "String",
    "required": false,
    "default": "UTC"
  },
  "established_date": {
    "type": "Date",
    "required": false
  },
  "total_area_sqm": {
    "type": "Decimal128",
    "required": false
  },
  "employee_count": {
    "type": "Number",
    "required": false
  },
  "shifts_per_day": {
    "type": "Number",
    "required": false,
    "default": "2"
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

### production_lines

**Document Structure:**
```json
{
  "factory_id": {
    "type": "Number",
    "required": true
  },
  "line_name": {
    "type": "String",
    "required": true
  },
  "line_type": {
    "type": "String",
    "required": false
  },
  "capacity_per_hour": {
    "type": "Number",
    "required": false
  },
  "product_types": {
    "type": "Object",
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

### machines

**Document Structure:**
```json
{
  "line_id": {
    "type": "Number",
    "required": true
  },
  "machine_name": {
    "type": "String",
    "required": true
  },
  "machine_type": {
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
  "installation_date": {
    "type": "Date",
    "required": false
  },
  "warranty_expiry": {
    "type": "Date",
    "required": false
  },
  "ideal_cycle_time_seconds": {
    "type": "Decimal128",
    "required": false
  },
  "max_capacity_per_hour": {
    "type": "Number",
    "required": false
  },
  "power_consumption_kw": {
    "type": "Decimal128",
    "required": false
  },
  "status": {
    "type": "String",
    "required": false
  },
  "total_operating_hours": {
    "type": "Decimal128",
    "required": false
  },
  "total_cycle_count": {
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

### sensors

**Document Structure:**
```json
{
  "machine_id": {
    "type": "Number",
    "required": true
  },
  "sensor_type": {
    "type": "String",
    "required": false
  },
  "unit_of_measure": {
    "type": "String",
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
  "normal_min": {
    "type": "Decimal128",
    "required": false
  },
  "normal_max": {
    "type": "Decimal128",
    "required": false
  },
  "critical_min": {
    "type": "Decimal128",
    "required": false
  },
  "critical_max": {
    "type": "Decimal128",
    "required": false
  },
  "sampling_rate_seconds": {
    "type": "Number",
    "required": false,
    "default": "60"
  },
  "calibration_date": {
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

### products

**Document Structure:**
```json
{
  "product_name": {
    "type": "String",
    "required": true
  },
  "product_category": {
    "type": "String",
    "required": false
  },
  "unit_of_measure": {
    "type": "String",
    "required": false,
    "default": "unit"
  },
  "standard_cycle_time_seconds": {
    "type": "Decimal128",
    "required": false
  },
  "weight_kg": {
    "type": "Decimal128",
    "required": false
  },
  "quality_specs": {
    "type": "Object",
    "required": false
  },
  "bom": {
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

### work_orders

**Document Structure:**
```json
{
  "product_id": {
    "type": "Number",
    "required": true
  },
  "line_id": {
    "type": "Number",
    "required": true
  },
  "planned_quantity": {
    "type": "Number",
    "required": true
  },
  "planned_start_time": {
    "type": "Date",
    "required": true
  },
  "planned_end_time": {
    "type": "Date",
    "required": true
  },
  "actual_start_time": {
    "type": "Date",
    "required": false
  },
  "actual_end_time": {
    "type": "Date",
    "required": false
  },
  "produced_quantity": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "good_quantity": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "rejected_quantity": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "status": {
    "type": "String",
    "required": false
  },
  "priority": {
    "type": "Number",
    "required": false,
    "default": "5 COMMENT "
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

### production_runs

**Document Structure:**
```json
{
  "order_id": {
    "type": "Number",
    "required": true
  },
  "machine_id": {
    "type": "Number",
    "required": true
  },
  "operator_id": {
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
  "quantity_produced": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "quantity_good": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "quantity_rejected": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "cycle_time_actual": {
    "type": "Decimal128",
    "required": false
  },
  "downtime_minutes": {
    "type": "Decimal128",
    "required": false
  },
  "speed_percentage": {
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

### quality_inspections

**Document Structure:**
```json
{
  "run_id": {
    "type": "Number",
    "required": true
  },
  "product_id": {
    "type": "Number",
    "required": true
  },
  "inspection_time": {
    "type": "Date",
    "required": true
  },
  "inspector_id": {
    "type": "Number",
    "required": false
  },
  "sample_size": {
    "type": "Number",
    "required": false
  },
  "defects_found": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "defect_types": {
    "type": "Object",
    "required": false
  },
  "measurements": {
    "type": "Object",
    "required": false
  },
  "pass_fail": {
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

### defects

**Document Structure:**
```json
{
  "inspection_id": {
    "type": "Number",
    "required": true
  },
  "defect_type": {
    "type": "String",
    "required": true
  },
  "severity": {
    "type": "String",
    "required": false
  },
  "quantity": {
    "type": "Number",
    "required": false,
    "default": "1"
  },
  "root_cause": {
    "type": "String",
    "required": false
  },
  "corrective_action": {
    "type": "String",
    "required": false
  },
  "image_url": {
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

### oee_metrics

**Document Structure:**
```json
{
  "machine_id": {
    "type": "Number",
    "required": true
  },
  "line_id": {
    "type": "Number",
    "required": true
  },
  "metric_timestamp": {
    "type": "Date",
    "required": true
  },
  "hour_start": {
    "type": "Date",
    "required": true
  },
  "hour_end": {
    "type": "Date",
    "required": true
  },
  "planned_production_time_min": {
    "type": "Decimal128",
    "required": false
  },
  "operating_time_min": {
    "type": "Decimal128",
    "required": false
  },
  "downtime_min": {
    "type": "Decimal128",
    "required": false
  },
  "availability_percentage": {
    "type": "Decimal128",
    "required": false
  },
  "ideal_cycle_time_sec": {
    "type": "Decimal128",
    "required": false
  },
  "total_pieces_produced": {
    "type": "Number",
    "required": false
  },
  "performance_percentage": {
    "type": "Decimal128",
    "required": false
  },
  "good_pieces": {
    "type": "Number",
    "required": false
  },
  "total_pieces": {
    "type": "Number",
    "required": false
  },
  "quality_percentage": {
    "type": "Decimal128",
    "required": false
  },
  "oee_percentage": {
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

### maintenance_schedules

**Document Structure:**
```json
{
  "machine_id": {
    "type": "Number",
    "required": true
  },
  "maintenance_type": {
    "type": "String",
    "required": false
  },
  "frequency_days": {
    "type": "Number",
    "required": false
  },
  "last_performed": {
    "type": "Date",
    "required": false
  },
  "next_due": {
    "type": "Date",
    "required": false
  },
  "estimated_duration_hours": {
    "type": "Decimal128",
    "required": false
  },
  "parts_required": {
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

### maintenance_records

**Document Structure:**
```json
{
  "machine_id": {
    "type": "Number",
    "required": true
  },
  "schedule_id": {
    "type": "Number",
    "required": false
  },
  "maintenance_type": {
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
  "technician_id": {
    "type": "Number",
    "required": false
  },
  "downtime_minutes": {
    "type": "Decimal128",
    "required": false
  },
  "parts_replaced": {
    "type": "Object",
    "required": false
  },
  "cost": {
    "type": "Decimal128",
    "required": false
  },
  "findings": {
    "type": "String",
    "required": false
  },
  "actions_taken": {
    "type": "String",
    "required": false
  },
  "next_action": {
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

### alerts

**Document Structure:**
```json
{
  "source_type": {
    "type": "String",
    "required": false
  },
  "source_id": {
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
  "message": {
    "type": "String",
    "required": true
  },
  "threshold_value": {
    "type": "Decimal128",
    "required": false
  },
  "actual_value": {
    "type": "Decimal128",
    "required": false
  },
  "triggered_at": {
    "type": "Date",
    "required": true
  },
  "acknowledged_at": {
    "type": "Date",
    "required": false
  },
  "acknowledged_by": {
    "type": "Number",
    "required": false
  },
  "resolved_at": {
    "type": "Date",
    "required": false
  },
  "resolved_by": {
    "type": "Number",
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

### downtime_events

**Document Structure:**
```json
{
  "machine_id": {
    "type": "Number",
    "required": true
  },
  "line_id": {
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
  "duration_minutes": {
    "type": "Decimal128",
    "required": false
  },
  "reason_category": {
    "type": "String",
    "required": false
  },
  "reason_detail": {
    "type": "String",
    "required": false
  },
  "impact_level": {
    "type": "String",
    "required": false
  },
  "lost_production_units": {
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

### operators

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
  "shift": {
    "type": "String",
    "required": false
  },
  "skill_level": {
    "type": "String",
    "required": false
  },
  "certifications": {
    "type": "Object",
    "required": false
  },
  "factory_id": {
    "type": "Number",
    "required": true
  },
  "hire_date": {
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

### shift_logs

**Document Structure:**
```json
{
  "shift_date": {
    "type": "Date",
    "required": true
  },
  "shift_type": {
    "type": "String",
    "required": false
  },
  "line_id": {
    "type": "Number",
    "required": true
  },
  "supervisor_id": {
    "type": "Number",
    "required": false
  },
  "operators_count": {
    "type": "Number",
    "required": false
  },
  "production_target": {
    "type": "Number",
    "required": false
  },
  "production_actual": {
    "type": "Number",
    "required": false
  },
  "oee_target": {
    "type": "Decimal128",
    "required": false
  },
  "oee_actual": {
    "type": "Decimal128",
    "required": false
  },
  "safety_incidents": {
    "type": "Number",
    "required": false,
    "default": "0"
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

