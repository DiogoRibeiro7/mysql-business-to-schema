# MongoDB Schema for example_08_healthcare_iot

Converted from MySQL on 2026-02-17T23:16:48.742844

## Collections

### audit_log

**Document Structure:**
```json
{
  "table_name": {
    "type": "String",
    "required": true
  },
  "operation": {
    "type": "String",
    "required": false
  },
  "user": {
    "type": "String",
    "required": false
  },
  "timestamp": {
    "type": "Date",
    "required": false,
    "default": "CURRENT_TIMESTAMP"
  },
  "record_id": {
    "type": "Number",
    "required": false
  },
  "old_values": {
    "type": "Object",
    "required": false
  },
  "new_values": {
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

### schema_version

**Document Structure:**
```json
{
  "version": {
    "type": "String",
    "required": true
  },
  "description": {
    "type": "String",
    "required": false
  },
  "applied_at": {
    "type": "Date",
    "required": false,
    "default": "CURRENT_TIMESTAMP"
  },
  "applied_by": {
    "type": "String",
    "required": false,
    "default": "USER()"
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

### hospitals

**Document Structure:**
```json
{
  "hospital_name": {
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
  "license_number": {
    "type": "String",
    "required": false
  },
  "accreditation": {
    "type": "String",
    "required": false
  },
  "bed_capacity": {
    "type": "Number",
    "required": false
  },
  "emergency_services": {
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

### departments

**Document Structure:**
```json
{
  "hospital_id": {
    "type": "Number",
    "required": true
  },
  "department_name": {
    "type": "String",
    "required": true
  },
  "department_code": {
    "type": "String",
    "required": true
  },
  "department_type": {
    "type": "String",
    "required": false
  },
  "floor_number": {
    "type": "Number",
    "required": false
  },
  "bed_count": {
    "type": "Number",
    "required": false
  },
  "nurse_station_location": {
    "type": "String",
    "required": false
  },
  "phone_extension": {
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

### rooms

**Document Structure:**
```json
{
  "department_id": {
    "type": "Number",
    "required": true
  },
  "room_number": {
    "type": "String",
    "required": true
  },
  "room_type": {
    "type": "String",
    "required": false
  },
  "bed_count": {
    "type": "Number",
    "required": false,
    "default": "1"
  },
  "floor": {
    "type": "Number",
    "required": false
  },
  "is_occupied": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "is_isolation": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "has_monitoring": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "equipment_list": {
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

### staff

**Document Structure:**
```json
{
  "hospital_id": {
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
  "title": {
    "type": "String",
    "required": false
  },
  "role": {
    "type": "String",
    "required": false
  },
  "specialization": {
    "type": "String",
    "required": false
  },
  "license_number": {
    "type": "String",
    "required": false
  },
  "license_expiry": {
    "type": "Date",
    "required": false
  },
  "department_id": {
    "type": "Number",
    "required": false
  },
  "email": {
    "type": "String",
    "required": false
  },
  "phone": {
    "type": "String",
    "required": false
  },
  "shift_type": {
    "type": "String",
    "required": false
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

### staff_schedules

**Document Structure:**
```json
{
  "staff_id": {
    "type": "Number",
    "required": true
  },
  "department_id": {
    "type": "Number",
    "required": true
  },
  "shift_date": {
    "type": "Date",
    "required": true
  },
  "shift_start": {
    "type": "String",
    "required": true
  },
  "shift_end": {
    "type": "String",
    "required": true
  },
  "break_minutes": {
    "type": "Number",
    "required": false,
    "default": "30"
  },
  "is_on_call": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "actual_start": {
    "type": "Date",
    "required": false
  },
  "actual_end": {
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

### patients

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
  "date_of_birth": {
    "type": "Date",
    "required": true
  },
  "gender": {
    "type": "String",
    "required": false
  },
  "blood_type": {
    "type": "String",
    "required": false
  },
  "height_cm": {
    "type": "Decimal128",
    "required": false
  },
  "weight_kg": {
    "type": "Decimal128",
    "required": false
  },
  "bmi": {
    "type": "Decimal128",
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
  "phone": {
    "type": "String",
    "required": false
  },
  "email": {
    "type": "String",
    "required": false
  },
  "emergency_contact_name": {
    "type": "String",
    "required": false
  },
  "emergency_contact_phone": {
    "type": "String",
    "required": false
  },
  "emergency_contact_relation": {
    "type": "String",
    "required": false
  },
  "insurance_provider": {
    "type": "String",
    "required": false
  },
  "insurance_id": {
    "type": "String",
    "required": false
  },
  "primary_physician_id": {
    "type": "Number",
    "required": false
  },
  "allergies": {
    "type": "Object",
    "required": false
  },
  "chronic_conditions": {
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

### admissions

**Document Structure:**
```json
{
  "patient_id": {
    "type": "Number",
    "required": true
  },
  "hospital_id": {
    "type": "Number",
    "required": true
  },
  "department_id": {
    "type": "Number",
    "required": true
  },
  "room_id": {
    "type": "Number",
    "required": false
  },
  "admission_date": {
    "type": "Date",
    "required": true
  },
  "discharge_date": {
    "type": "Date",
    "required": false
  },
  "admission_type": {
    "type": "String",
    "required": false
  },
  "admission_source": {
    "type": "String",
    "required": false
  },
  "chief_complaint": {
    "type": "String",
    "required": false
  },
  "diagnosis_codes": {
    "type": "Object",
    "required": false
  },
  "attending_physician_id": {
    "type": "Number",
    "required": true
  },
  "admitting_physician_id": {
    "type": "Number",
    "required": false
  },
  "status": {
    "type": "String",
    "required": false
  },
  "discharge_disposition": {
    "type": "String",
    "required": false
  },
  "total_charges": {
    "type": "Decimal128",
    "required": false
  },
  "insurance_coverage": {
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

### devices

**Document Structure:**
```json
{
  "device_type": {
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
  "hospital_id": {
    "type": "Number",
    "required": true
  },
  "department_id": {
    "type": "Number",
    "required": false
  },
  "room_id": {
    "type": "Number",
    "required": false
  },
  "current_patient_id": {
    "type": "Number",
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
  "next_maintenance_date": {
    "type": "Date",
    "required": false
  },
  "calibration_date": {
    "type": "Date",
    "required": false
  },
  "battery_level": {
    "type": "Number",
    "required": false
  },
  "connectivity_status": {
    "type": "String",
    "required": false
  },
  "last_seen": {
    "type": "Date",
    "required": false
  },
  "is_active": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "settings": {
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

### device_assignments

**Document Structure:**
```json
{
  "device_id": {
    "type": "Number",
    "required": true
  },
  "patient_id": {
    "type": "Number",
    "required": true
  },
  "admission_id": {
    "type": "Number",
    "required": true
  },
  "assigned_at": {
    "type": "Date",
    "required": true
  },
  "unassigned_at": {
    "type": "Date",
    "required": false
  },
  "assigned_by": {
    "type": "Number",
    "required": true
  },
  "unassigned_by": {
    "type": "Number",
    "required": false
  },
  "reason": {
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

### vital_signs

**Document Structure:**
```json
{
  "patient_id": {
    "type": "Number",
    "required": true
  },
  "admission_id": {
    "type": "Number",
    "required": false
  },
  "device_id": {
    "type": "Number",
    "required": false
  },
  "recorded_at": {
    "type": "String",
    "required": false
  },
  "heart_rate": {
    "type": "Number",
    "required": false
  },
  "respiratory_rate": {
    "type": "Number",
    "required": false
  },
  "systolic_bp": {
    "type": "Number",
    "required": false
  },
  "diastolic_bp": {
    "type": "Number",
    "required": false
  },
  "oxygen_saturation": {
    "type": "Decimal128",
    "required": false
  },
  "temperature": {
    "type": "String",
    "required": false
  },
  "blood_glucose": {
    "type": "Decimal128",
    "required": false
  },
  "pain_level": {
    "type": "Number",
    "required": false
  },
  "consciousness_level": {
    "type": "String",
    "required": false
  },
  "early_warning_score": {
    "type": "Number",
    "required": false
  },
  "recorded_by": {
    "type": "Number",
    "required": false
  },
  "is_manual_entry": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
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

### device_readings

**Document Structure:**
```json
{
  "device_id": {
    "type": "Number",
    "required": true
  },
  "patient_id": {
    "type": "Number",
    "required": false
  },
  "timestamp": {
    "type": "String",
    "required": false
  },
  "metric_type": {
    "type": "String",
    "required": true
  },
  "metric_value": {
    "type": "Decimal128",
    "required": false
  },
  "metric_unit": {
    "type": "String",
    "required": false
  },
  "quality_score": {
    "type": "Number",
    "required": false
  },
  "raw_data": {
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

### alerts

**Document Structure:**
```json
{
  "patient_id": {
    "type": "Number",
    "required": true
  },
  "admission_id": {
    "type": "Number",
    "required": false
  },
  "device_id": {
    "type": "Number",
    "required": false
  },
  "alert_type": {
    "type": "String",
    "required": false
  },
  "alert_category": {
    "type": "String",
    "required": false
  },
  "alert_code": {
    "type": "String",
    "required": false
  },
  "alert_message": {
    "type": "String",
    "required": true
  },
  "metric_name": {
    "type": "String",
    "required": false
  },
  "metric_value": {
    "type": "Decimal128",
    "required": false
  },
  "threshold_value": {
    "type": "Decimal128",
    "required": false
  },
  "triggered_at": {
    "type": "String",
    "required": false
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
  "escalated": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "response_time_seconds": {
    "type": "Number",
    "required": false
  },
  "actions_taken": {
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
  "metric_type": {
    "type": "String",
    "required": true
  },
  "condition_operator": {
    "type": "String",
    "required": false
  },
  "threshold_value1": {
    "type": "Decimal128",
    "required": false
  },
  "threshold_value2": {
    "type": "Decimal128",
    "required": false
  },
  "time_window_minutes": {
    "type": "Number",
    "required": false
  },
  "severity": {
    "type": "String",
    "required": false
  },
  "department_id": {
    "type": "Number",
    "required": false
  },
  "is_active": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "notification_channels": {
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

### medications

**Document Structure:**
```json
{
  "medication_name": {
    "type": "String",
    "required": true
  },
  "generic_name": {
    "type": "String",
    "required": false
  },
  "drug_class": {
    "type": "String",
    "required": false
  },
  "ndc_code": {
    "type": "String",
    "required": false
  },
  "dosage_form": {
    "type": "String",
    "required": false
  },
  "strength": {
    "type": "String",
    "required": false
  },
  "unit": {
    "type": "String",
    "required": false
  },
  "manufacturer": {
    "type": "String",
    "required": false
  },
  "controlled_substance_schedule": {
    "type": "String",
    "required": false
  },
  "requires_refrigeration": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "black_box_warning": {
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

### prescriptions

**Document Structure:**
```json
{
  "patient_id": {
    "type": "Number",
    "required": true
  },
  "admission_id": {
    "type": "Number",
    "required": false
  },
  "medication_id": {
    "type": "Number",
    "required": true
  },
  "prescribing_physician_id": {
    "type": "Number",
    "required": true
  },
  "dosage": {
    "type": "String",
    "required": true
  },
  "frequency": {
    "type": "String",
    "required": true
  },
  "route": {
    "type": "String",
    "required": false
  },
  "start_date": {
    "type": "Date",
    "required": true
  },
  "end_date": {
    "type": "Date",
    "required": false
  },
  "duration_days": {
    "type": "Number",
    "required": false
  },
  "refills": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "instructions": {
    "type": "String",
    "required": false
  },
  "is_prn": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "prn_reason": {
    "type": "String",
    "required": false
  },
  "is_active": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "discontinued_date": {
    "type": "Date",
    "required": false
  },
  "discontinued_by": {
    "type": "Number",
    "required": false
  },
  "discontinued_reason": {
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

### medication_administration

**Document Structure:**
```json
{
  "prescription_id": {
    "type": "Number",
    "required": true
  },
  "patient_id": {
    "type": "Number",
    "required": true
  },
  "scheduled_time": {
    "type": "Date",
    "required": true
  },
  "actual_time": {
    "type": "Date",
    "required": false
  },
  "administered_by": {
    "type": "Number",
    "required": false
  },
  "dosage_given": {
    "type": "String",
    "required": false
  },
  "route_used": {
    "type": "String",
    "required": false
  },
  "taken": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "missed": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "refused": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "reason": {
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

### lab_tests

**Document Structure:**
```json
{
  "test_code": {
    "type": "String",
    "required": true
  },
  "test_name": {
    "type": "String",
    "required": true
  },
  "test_category": {
    "type": "String",
    "required": false
  },
  "specimen_type": {
    "type": "String",
    "required": false
  },
  "normal_range_low": {
    "type": "Decimal128",
    "required": false
  },
  "normal_range_high": {
    "type": "Decimal128",
    "required": false
  },
  "unit": {
    "type": "String",
    "required": false
  },
  "critical_low": {
    "type": "Decimal128",
    "required": false
  },
  "critical_high": {
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

### lab_orders

**Document Structure:**
```json
{
  "patient_id": {
    "type": "Number",
    "required": true
  },
  "admission_id": {
    "type": "Number",
    "required": false
  },
  "ordering_physician_id": {
    "type": "Number",
    "required": true
  },
  "order_date": {
    "type": "String",
    "required": false
  },
  "priority": {
    "type": "String",
    "required": false
  },
  "tests_ordered": {
    "type": "Object",
    "required": true
  },
  "specimen_collected": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "collected_at": {
    "type": "Date",
    "required": false
  },
  "collected_by": {
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

### lab_results

**Document Structure:**
```json
{
  "order_id": {
    "type": "Number",
    "required": true
  },
  "test_id": {
    "type": "Number",
    "required": true
  },
  "patient_id": {
    "type": "Number",
    "required": true
  },
  "result_value": {
    "type": "Decimal128",
    "required": false
  },
  "result_text": {
    "type": "String",
    "required": false
  },
  "abnormal_flag": {
    "type": "String",
    "required": false
  },
  "reference_range": {
    "type": "String",
    "required": false
  },
  "resulted_at": {
    "type": "String",
    "required": false
  },
  "verified_by": {
    "type": "Number",
    "required": false
  },
  "verified_at": {
    "type": "Date",
    "required": false
  },
  "comments": {
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

### clinical_notes

**Document Structure:**
```json
{
  "patient_id": {
    "type": "Number",
    "required": true
  },
  "admission_id": {
    "type": "Number",
    "required": false
  },
  "note_type": {
    "type": "String",
    "required": false
  },
  "author_id": {
    "type": "Number",
    "required": true
  },
  "note_date": {
    "type": "String",
    "required": false
  },
  "note_text": {
    "type": "String",
    "required": true
  },
  "is_signed": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "signed_at": {
    "type": "Date",
    "required": false
  },
  "cosigner_id": {
    "type": "Number",
    "required": false
  },
  "cosigned_at": {
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
  },
  "FULLTEXT": {
    "type": "String",
    "required": false
  }
}
```

### emergency_events

**Document Structure:**
```json
{
  "patient_id": {
    "type": "Number",
    "required": true
  },
  "admission_id": {
    "type": "Number",
    "required": false
  },
  "event_type": {
    "type": "String",
    "required": false
  },
  "location": {
    "type": "String",
    "required": true
  },
  "initiated_at": {
    "type": "String",
    "required": false
  },
  "team_arrived_at": {
    "type": "Date",
    "required": false
  },
  "resolved_at": {
    "type": "Date",
    "required": false
  },
  "initiated_by": {
    "type": "Number",
    "required": true
  },
  "team_lead_id": {
    "type": "Number",
    "required": false
  },
  "outcome": {
    "type": "String",
    "required": false
  },
  "interventions": {
    "type": "Object",
    "required": false
  },
  "medications_given": {
    "type": "Object",
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

### patient_daily_summary

**Document Structure:**
```json
{
  "patient_id": {
    "type": "Number",
    "required": true
  },
  "admission_id": {
    "type": "Number",
    "required": true
  },
  "summary_date": {
    "type": "Date",
    "required": true
  },
  "avg_heart_rate": {
    "type": "Decimal128",
    "required": false
  },
  "avg_bp_systolic": {
    "type": "Decimal128",
    "required": false
  },
  "avg_bp_diastolic": {
    "type": "Decimal128",
    "required": false
  },
  "avg_temperature": {
    "type": "Decimal128",
    "required": false
  },
  "avg_oxygen_sat": {
    "type": "Decimal128",
    "required": false
  },
  "min_oxygen_sat": {
    "type": "Decimal128",
    "required": false
  },
  "max_early_warning_score": {
    "type": "Number",
    "required": false
  },
  "alert_count": {
    "type": "Number",
    "required": false
  },
  "critical_alert_count": {
    "type": "Number",
    "required": false
  },
  "medications_administered": {
    "type": "Number",
    "required": false
  },
  "medications_missed": {
    "type": "Number",
    "required": false
  },
  "lab_tests_ordered": {
    "type": "Number",
    "required": false
  },
  "lab_results_abnormal": {
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

### vital_signs_hourly

**Document Structure:**
```json
{
  "patient_id": {
    "type": "Number",
    "required": true
  },
  "admission_id": {
    "type": "Number",
    "required": false
  },
  "hour_timestamp": {
    "type": "Date",
    "required": true
  },
  "avg_heart_rate": {
    "type": "Decimal128",
    "required": false
  },
  "avg_respiratory_rate": {
    "type": "Decimal128",
    "required": false
  },
  "avg_systolic_bp": {
    "type": "Decimal128",
    "required": false
  },
  "avg_diastolic_bp": {
    "type": "Decimal128",
    "required": false
  },
  "avg_oxygen_sat": {
    "type": "Decimal128",
    "required": false
  },
  "avg_temperature": {
    "type": "Decimal128",
    "required": false
  },
  "max_early_warning_score": {
    "type": "Number",
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

