// MongoDB Migration Script
// Generated: 2026-02-17T23:16:48.741965
// From MySQL to MongoDB

use converted_db;

// Create collection: audit_log
db.createCollection('audit_log');

// Create collection: schema_version
db.createCollection('schema_version');

// Create collection: hospitals
db.createCollection('hospitals');

// Create collection: departments
db.createCollection('departments');

// Create collection: rooms
db.createCollection('rooms');

// Create collection: staff
db.createCollection('staff');

// Create collection: staff_schedules
db.createCollection('staff_schedules');

// Create collection: patients
db.createCollection('patients');

// Create collection: admissions
db.createCollection('admissions');

// Create collection: devices
db.createCollection('devices');

// Create collection: device_assignments
db.createCollection('device_assignments');

// Create collection: vital_signs
db.createCollection('vital_signs');

// Create collection: device_readings
db.createCollection('device_readings');

// Create collection: alerts
db.createCollection('alerts');

// Create collection: alert_rules
db.createCollection('alert_rules');

// Create collection: medications
db.createCollection('medications');

// Create collection: prescriptions
db.createCollection('prescriptions');

// Create collection: medication_administration
db.createCollection('medication_administration');

// Create collection: lab_tests
db.createCollection('lab_tests');

// Create collection: lab_orders
db.createCollection('lab_orders');

// Create collection: lab_results
db.createCollection('lab_results');

// Create collection: clinical_notes
db.createCollection('clinical_notes');

// Create collection: emergency_events
db.createCollection('emergency_events');

// Create collection: patient_daily_summary
db.createCollection('patient_daily_summary');

// Create collection: vital_signs_hourly
db.createCollection('vital_signs_hourly');

// Indexes for schema_version
db.schema_version.createIndex({"description": "text"}, {"name": "schema_version_text"});

// Indexes for hospitals
db.hospitals.createIndex({"address": "text"}, {"name": "hospitals_text"});

// Indexes for departments

// Indexes for rooms

// Indexes for staff

// Indexes for staff_schedules

// Indexes for patients
db.patients.createIndex({"address": "text"}, {"name": "patients_text"});

// Indexes for admissions
db.admissions.createIndex({"chief_complaint": "text", "notes": "text"}, {"name": "admissions_text"});

// Indexes for devices

// Indexes for vital_signs
db.vital_signs.createIndex({"notes": "text"}, {"name": "vital_signs_text"});

// Indexes for alerts
db.alerts.createIndex({"alert_message": "text", "actions_taken": "text"}, {"name": "alerts_text"});

// Indexes for medications
db.medications.createIndex({"black_box_warning": "text"}, {"name": "medications_text"});

// Indexes for prescriptions
db.prescriptions.createIndex({"instructions": "text"}, {"name": "prescriptions_text"});

// Indexes for medication_administration
db.medication_administration.createIndex({"notes": "text"}, {"name": "medication_administration_text"});

// Indexes for lab_tests

// Indexes for lab_results
db.lab_results.createIndex({"comments": "text"}, {"name": "lab_results_text"});

// Indexes for clinical_notes
db.clinical_notes.createIndex({"note_text": "text"}, {"name": "clinical_notes_text"});

// Indexes for emergency_events
db.emergency_events.createIndex({"notes": "text"}, {"name": "emergency_events_text"});

// Indexes for patient_daily_summary

// Validation for audit_log
db.runCommand({
  collMod: 'audit_log',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "table_name"
    ],
    "properties": {
      "table_name": {
        "bsonType": "string"
      },
      "operation": {
        "bsonType": "string"
      },
      "user": {
        "bsonType": "string"
      },
      "timestamp": {
        "bsonType": "date"
      },
      "record_id": {
        "bsonType": "number"
      },
      "old_values": {
        "bsonType": "object"
      },
      "new_values": {
        "bsonType": "object"
      }
    }
  }
}
});

// Validation for schema_version
db.runCommand({
  collMod: 'schema_version',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "version"
    ],
    "properties": {
      "version": {
        "bsonType": "string"
      },
      "description": {
        "bsonType": "string"
      },
      "applied_at": {
        "bsonType": "date"
      },
      "applied_by": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for hospitals
db.runCommand({
  collMod: 'hospitals',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "hospital_name"
    ],
    "properties": {
      "hospital_name": {
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
      "license_number": {
        "bsonType": "string"
      },
      "accreditation": {
        "bsonType": "string"
      },
      "bed_capacity": {
        "bsonType": "number"
      },
      "emergency_services": {
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

// Validation for departments
db.runCommand({
  collMod: 'departments',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "hospital_id",
      "department_name",
      "department_code"
    ],
    "properties": {
      "hospital_id": {
        "bsonType": "number"
      },
      "department_name": {
        "bsonType": "string"
      },
      "department_code": {
        "bsonType": "string"
      },
      "department_type": {
        "bsonType": "string"
      },
      "floor_number": {
        "bsonType": "number"
      },
      "bed_count": {
        "bsonType": "number"
      },
      "nurse_station_location": {
        "bsonType": "string"
      },
      "phone_extension": {
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

// Validation for rooms
db.runCommand({
  collMod: 'rooms',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "department_id",
      "room_number"
    ],
    "properties": {
      "department_id": {
        "bsonType": "number"
      },
      "room_number": {
        "bsonType": "string"
      },
      "room_type": {
        "bsonType": "string"
      },
      "bed_count": {
        "bsonType": "number"
      },
      "floor": {
        "bsonType": "number"
      },
      "is_occupied": {
        "bsonType": "boolean"
      },
      "is_isolation": {
        "bsonType": "boolean"
      },
      "has_monitoring": {
        "bsonType": "boolean"
      },
      "equipment_list": {
        "bsonType": "object"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for staff
db.runCommand({
  collMod: 'staff',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "hospital_id",
      "first_name",
      "last_name"
    ],
    "properties": {
      "hospital_id": {
        "bsonType": "number"
      },
      "first_name": {
        "bsonType": "string"
      },
      "last_name": {
        "bsonType": "string"
      },
      "title": {
        "bsonType": "string"
      },
      "role": {
        "bsonType": "string"
      },
      "specialization": {
        "bsonType": "string"
      },
      "license_number": {
        "bsonType": "string"
      },
      "license_expiry": {
        "bsonType": "date"
      },
      "department_id": {
        "bsonType": "number"
      },
      "email": {
        "bsonType": "string"
      },
      "phone": {
        "bsonType": "string"
      },
      "shift_type": {
        "bsonType": "string"
      },
      "hire_date": {
        "bsonType": "date"
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

// Validation for staff_schedules
db.runCommand({
  collMod: 'staff_schedules',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "staff_id",
      "department_id",
      "shift_date",
      "shift_start",
      "shift_end"
    ],
    "properties": {
      "staff_id": {
        "bsonType": "number"
      },
      "department_id": {
        "bsonType": "number"
      },
      "shift_date": {
        "bsonType": "date"
      },
      "shift_start": {
        "bsonType": "string"
      },
      "shift_end": {
        "bsonType": "string"
      },
      "break_minutes": {
        "bsonType": "number"
      },
      "is_on_call": {
        "bsonType": "boolean"
      },
      "actual_start": {
        "bsonType": "date"
      },
      "actual_end": {
        "bsonType": "date"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for patients
db.runCommand({
  collMod: 'patients',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "first_name",
      "last_name",
      "date_of_birth"
    ],
    "properties": {
      "first_name": {
        "bsonType": "string"
      },
      "last_name": {
        "bsonType": "string"
      },
      "date_of_birth": {
        "bsonType": "date"
      },
      "gender": {
        "bsonType": "string"
      },
      "blood_type": {
        "bsonType": "string"
      },
      "height_cm": {
        "bsonType": "decimal128"
      },
      "weight_kg": {
        "bsonType": "decimal128"
      },
      "bmi": {
        "bsonType": "decimal128"
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
      "phone": {
        "bsonType": "string"
      },
      "email": {
        "bsonType": "string"
      },
      "emergency_contact_name": {
        "bsonType": "string"
      },
      "emergency_contact_phone": {
        "bsonType": "string"
      },
      "emergency_contact_relation": {
        "bsonType": "string"
      },
      "insurance_provider": {
        "bsonType": "string"
      },
      "insurance_id": {
        "bsonType": "string"
      },
      "primary_physician_id": {
        "bsonType": "number"
      },
      "allergies": {
        "bsonType": "object"
      },
      "chronic_conditions": {
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

// Validation for admissions
db.runCommand({
  collMod: 'admissions',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "patient_id",
      "hospital_id",
      "department_id",
      "admission_date",
      "attending_physician_id"
    ],
    "properties": {
      "patient_id": {
        "bsonType": "number"
      },
      "hospital_id": {
        "bsonType": "number"
      },
      "department_id": {
        "bsonType": "number"
      },
      "room_id": {
        "bsonType": "number"
      },
      "admission_date": {
        "bsonType": "date"
      },
      "discharge_date": {
        "bsonType": "date"
      },
      "admission_type": {
        "bsonType": "string"
      },
      "admission_source": {
        "bsonType": "string"
      },
      "chief_complaint": {
        "bsonType": "string"
      },
      "diagnosis_codes": {
        "bsonType": "object"
      },
      "attending_physician_id": {
        "bsonType": "number"
      },
      "admitting_physician_id": {
        "bsonType": "number"
      },
      "status": {
        "bsonType": "string"
      },
      "discharge_disposition": {
        "bsonType": "string"
      },
      "total_charges": {
        "bsonType": "decimal128"
      },
      "insurance_coverage": {
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

// Validation for devices
db.runCommand({
  collMod: 'devices',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "hospital_id"
    ],
    "properties": {
      "device_type": {
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
      "hospital_id": {
        "bsonType": "number"
      },
      "department_id": {
        "bsonType": "number"
      },
      "room_id": {
        "bsonType": "number"
      },
      "current_patient_id": {
        "bsonType": "number"
      },
      "installation_date": {
        "bsonType": "date"
      },
      "last_maintenance_date": {
        "bsonType": "date"
      },
      "next_maintenance_date": {
        "bsonType": "date"
      },
      "calibration_date": {
        "bsonType": "date"
      },
      "battery_level": {
        "bsonType": "number"
      },
      "connectivity_status": {
        "bsonType": "string"
      },
      "last_seen": {
        "bsonType": "date"
      },
      "is_active": {
        "bsonType": "boolean"
      },
      "settings": {
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

// Validation for device_assignments
db.runCommand({
  collMod: 'device_assignments',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "device_id",
      "patient_id",
      "admission_id",
      "assigned_at",
      "assigned_by"
    ],
    "properties": {
      "device_id": {
        "bsonType": "number"
      },
      "patient_id": {
        "bsonType": "number"
      },
      "admission_id": {
        "bsonType": "number"
      },
      "assigned_at": {
        "bsonType": "date"
      },
      "unassigned_at": {
        "bsonType": "date"
      },
      "assigned_by": {
        "bsonType": "number"
      },
      "unassigned_by": {
        "bsonType": "number"
      },
      "reason": {
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

// Validation for vital_signs
db.runCommand({
  collMod: 'vital_signs',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "patient_id",
      "recorded_at"
    ],
    "properties": {
      "patient_id": {
        "bsonType": "number"
      },
      "admission_id": {
        "bsonType": "number"
      },
      "device_id": {
        "bsonType": "number"
      },
      "recorded_at": {
        "bsonType": "string"
      },
      "heart_rate": {
        "bsonType": "number"
      },
      "respiratory_rate": {
        "bsonType": "number"
      },
      "systolic_bp": {
        "bsonType": "number"
      },
      "diastolic_bp": {
        "bsonType": "number"
      },
      "oxygen_saturation": {
        "bsonType": "decimal128"
      },
      "temperature": {
        "bsonType": "string"
      },
      "blood_glucose": {
        "bsonType": "decimal128"
      },
      "pain_level": {
        "bsonType": "number"
      },
      "consciousness_level": {
        "bsonType": "string"
      },
      "early_warning_score": {
        "bsonType": "number"
      },
      "recorded_by": {
        "bsonType": "number"
      },
      "is_manual_entry": {
        "bsonType": "boolean"
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

// Validation for device_readings
db.runCommand({
  collMod: 'device_readings',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "device_id",
      "timestamp",
      "metric_type"
    ],
    "properties": {
      "device_id": {
        "bsonType": "number"
      },
      "patient_id": {
        "bsonType": "number"
      },
      "timestamp": {
        "bsonType": "string"
      },
      "metric_type": {
        "bsonType": "string"
      },
      "metric_value": {
        "bsonType": "decimal128"
      },
      "metric_unit": {
        "bsonType": "string"
      },
      "quality_score": {
        "bsonType": "number"
      },
      "raw_data": {
        "bsonType": "object"
      },
      "created_at": {
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
      "patient_id",
      "alert_message",
      "triggered_at"
    ],
    "properties": {
      "patient_id": {
        "bsonType": "number"
      },
      "admission_id": {
        "bsonType": "number"
      },
      "device_id": {
        "bsonType": "number"
      },
      "alert_type": {
        "bsonType": "string"
      },
      "alert_category": {
        "bsonType": "string"
      },
      "alert_code": {
        "bsonType": "string"
      },
      "alert_message": {
        "bsonType": "string"
      },
      "metric_name": {
        "bsonType": "string"
      },
      "metric_value": {
        "bsonType": "decimal128"
      },
      "threshold_value": {
        "bsonType": "decimal128"
      },
      "triggered_at": {
        "bsonType": "string"
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
      "escalated": {
        "bsonType": "boolean"
      },
      "response_time_seconds": {
        "bsonType": "number"
      },
      "actions_taken": {
        "bsonType": "string"
      },
      "created_at": {
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
      "metric_type"
    ],
    "properties": {
      "rule_name": {
        "bsonType": "string"
      },
      "rule_type": {
        "bsonType": "string"
      },
      "metric_type": {
        "bsonType": "string"
      },
      "condition_operator": {
        "bsonType": "string"
      },
      "threshold_value1": {
        "bsonType": "decimal128"
      },
      "threshold_value2": {
        "bsonType": "decimal128"
      },
      "time_window_minutes": {
        "bsonType": "number"
      },
      "severity": {
        "bsonType": "string"
      },
      "department_id": {
        "bsonType": "number"
      },
      "is_active": {
        "bsonType": "boolean"
      },
      "notification_channels": {
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

// Validation for medications
db.runCommand({
  collMod: 'medications',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "medication_name"
    ],
    "properties": {
      "medication_name": {
        "bsonType": "string"
      },
      "generic_name": {
        "bsonType": "string"
      },
      "drug_class": {
        "bsonType": "string"
      },
      "ndc_code": {
        "bsonType": "string"
      },
      "dosage_form": {
        "bsonType": "string"
      },
      "strength": {
        "bsonType": "string"
      },
      "unit": {
        "bsonType": "string"
      },
      "manufacturer": {
        "bsonType": "string"
      },
      "controlled_substance_schedule": {
        "bsonType": "string"
      },
      "requires_refrigeration": {
        "bsonType": "boolean"
      },
      "black_box_warning": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for prescriptions
db.runCommand({
  collMod: 'prescriptions',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "patient_id",
      "medication_id",
      "prescribing_physician_id",
      "dosage",
      "frequency",
      "start_date"
    ],
    "properties": {
      "patient_id": {
        "bsonType": "number"
      },
      "admission_id": {
        "bsonType": "number"
      },
      "medication_id": {
        "bsonType": "number"
      },
      "prescribing_physician_id": {
        "bsonType": "number"
      },
      "dosage": {
        "bsonType": "string"
      },
      "frequency": {
        "bsonType": "string"
      },
      "route": {
        "bsonType": "string"
      },
      "start_date": {
        "bsonType": "date"
      },
      "end_date": {
        "bsonType": "date"
      },
      "duration_days": {
        "bsonType": "number"
      },
      "refills": {
        "bsonType": "number"
      },
      "instructions": {
        "bsonType": "string"
      },
      "is_prn": {
        "bsonType": "boolean"
      },
      "prn_reason": {
        "bsonType": "string"
      },
      "is_active": {
        "bsonType": "boolean"
      },
      "discontinued_date": {
        "bsonType": "date"
      },
      "discontinued_by": {
        "bsonType": "number"
      },
      "discontinued_reason": {
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

// Validation for medication_administration
db.runCommand({
  collMod: 'medication_administration',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "prescription_id",
      "patient_id",
      "scheduled_time"
    ],
    "properties": {
      "prescription_id": {
        "bsonType": "number"
      },
      "patient_id": {
        "bsonType": "number"
      },
      "scheduled_time": {
        "bsonType": "date"
      },
      "actual_time": {
        "bsonType": "date"
      },
      "administered_by": {
        "bsonType": "number"
      },
      "dosage_given": {
        "bsonType": "string"
      },
      "route_used": {
        "bsonType": "string"
      },
      "taken": {
        "bsonType": "boolean"
      },
      "missed": {
        "bsonType": "boolean"
      },
      "refused": {
        "bsonType": "boolean"
      },
      "reason": {
        "bsonType": "string"
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

// Validation for lab_tests
db.runCommand({
  collMod: 'lab_tests',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "test_code",
      "test_name"
    ],
    "properties": {
      "test_code": {
        "bsonType": "string"
      },
      "test_name": {
        "bsonType": "string"
      },
      "test_category": {
        "bsonType": "string"
      },
      "specimen_type": {
        "bsonType": "string"
      },
      "normal_range_low": {
        "bsonType": "decimal128"
      },
      "normal_range_high": {
        "bsonType": "decimal128"
      },
      "unit": {
        "bsonType": "string"
      },
      "critical_low": {
        "bsonType": "decimal128"
      },
      "critical_high": {
        "bsonType": "decimal128"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for lab_orders
db.runCommand({
  collMod: 'lab_orders',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "patient_id",
      "ordering_physician_id",
      "order_date",
      "tests_ordered"
    ],
    "properties": {
      "patient_id": {
        "bsonType": "number"
      },
      "admission_id": {
        "bsonType": "number"
      },
      "ordering_physician_id": {
        "bsonType": "number"
      },
      "order_date": {
        "bsonType": "string"
      },
      "priority": {
        "bsonType": "string"
      },
      "tests_ordered": {
        "bsonType": "object"
      },
      "specimen_collected": {
        "bsonType": "boolean"
      },
      "collected_at": {
        "bsonType": "date"
      },
      "collected_by": {
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

// Validation for lab_results
db.runCommand({
  collMod: 'lab_results',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "order_id",
      "test_id",
      "patient_id",
      "resulted_at"
    ],
    "properties": {
      "order_id": {
        "bsonType": "number"
      },
      "test_id": {
        "bsonType": "number"
      },
      "patient_id": {
        "bsonType": "number"
      },
      "result_value": {
        "bsonType": "decimal128"
      },
      "result_text": {
        "bsonType": "string"
      },
      "abnormal_flag": {
        "bsonType": "string"
      },
      "reference_range": {
        "bsonType": "string"
      },
      "resulted_at": {
        "bsonType": "string"
      },
      "verified_by": {
        "bsonType": "number"
      },
      "verified_at": {
        "bsonType": "date"
      },
      "comments": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for clinical_notes
db.runCommand({
  collMod: 'clinical_notes',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "patient_id",
      "author_id",
      "note_date",
      "note_text"
    ],
    "properties": {
      "patient_id": {
        "bsonType": "number"
      },
      "admission_id": {
        "bsonType": "number"
      },
      "note_type": {
        "bsonType": "string"
      },
      "author_id": {
        "bsonType": "number"
      },
      "note_date": {
        "bsonType": "string"
      },
      "note_text": {
        "bsonType": "string"
      },
      "is_signed": {
        "bsonType": "boolean"
      },
      "signed_at": {
        "bsonType": "date"
      },
      "cosigner_id": {
        "bsonType": "number"
      },
      "cosigned_at": {
        "bsonType": "date"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      },
      "FULLTEXT": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for emergency_events
db.runCommand({
  collMod: 'emergency_events',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "patient_id",
      "location",
      "initiated_at",
      "initiated_by"
    ],
    "properties": {
      "patient_id": {
        "bsonType": "number"
      },
      "admission_id": {
        "bsonType": "number"
      },
      "event_type": {
        "bsonType": "string"
      },
      "location": {
        "bsonType": "string"
      },
      "initiated_at": {
        "bsonType": "string"
      },
      "team_arrived_at": {
        "bsonType": "date"
      },
      "resolved_at": {
        "bsonType": "date"
      },
      "initiated_by": {
        "bsonType": "number"
      },
      "team_lead_id": {
        "bsonType": "number"
      },
      "outcome": {
        "bsonType": "string"
      },
      "interventions": {
        "bsonType": "object"
      },
      "medications_given": {
        "bsonType": "object"
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

// Validation for patient_daily_summary
db.runCommand({
  collMod: 'patient_daily_summary',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "patient_id",
      "admission_id",
      "summary_date"
    ],
    "properties": {
      "patient_id": {
        "bsonType": "number"
      },
      "admission_id": {
        "bsonType": "number"
      },
      "summary_date": {
        "bsonType": "date"
      },
      "avg_heart_rate": {
        "bsonType": "decimal128"
      },
      "avg_bp_systolic": {
        "bsonType": "decimal128"
      },
      "avg_bp_diastolic": {
        "bsonType": "decimal128"
      },
      "avg_temperature": {
        "bsonType": "decimal128"
      },
      "avg_oxygen_sat": {
        "bsonType": "decimal128"
      },
      "min_oxygen_sat": {
        "bsonType": "decimal128"
      },
      "max_early_warning_score": {
        "bsonType": "number"
      },
      "alert_count": {
        "bsonType": "number"
      },
      "critical_alert_count": {
        "bsonType": "number"
      },
      "medications_administered": {
        "bsonType": "number"
      },
      "medications_missed": {
        "bsonType": "number"
      },
      "lab_tests_ordered": {
        "bsonType": "number"
      },
      "lab_results_abnormal": {
        "bsonType": "number"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for vital_signs_hourly
db.runCommand({
  collMod: 'vital_signs_hourly',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "patient_id",
      "hour_timestamp"
    ],
    "properties": {
      "patient_id": {
        "bsonType": "number"
      },
      "admission_id": {
        "bsonType": "number"
      },
      "hour_timestamp": {
        "bsonType": "date"
      },
      "avg_heart_rate": {
        "bsonType": "decimal128"
      },
      "avg_respiratory_rate": {
        "bsonType": "decimal128"
      },
      "avg_systolic_bp": {
        "bsonType": "decimal128"
      },
      "avg_diastolic_bp": {
        "bsonType": "decimal128"
      },
      "avg_oxygen_sat": {
        "bsonType": "decimal128"
      },
      "avg_temperature": {
        "bsonType": "decimal128"
      },
      "max_early_warning_score": {
        "bsonType": "number"
      },
      "reading_count": {
        "bsonType": "number"
      }
    }
  }
}
});
