// MongoDB Migration Script
// Generated: 2026-02-17T23:16:48.675845
// From MySQL to MongoDB

use converted_db;

// Create collection: patients
db.createCollection('patients');

// Create collection: doctors
db.createCollection('doctors');

// Create collection: specialties
db.createCollection('specialties');

// Create collection: doctor_specialties
db.createCollection('doctor_specialties');

// Create collection: appointments
db.createCollection('appointments');

// Create collection: invoices
db.createCollection('invoices');

// Create collection: invoice_items
db.createCollection('invoice_items');

// Create collection: payments
db.createCollection('payments');

// Create collection: payment_allocations
db.createCollection('payment_allocations');

// Indexes for patients
db.patients.createIndex({"patient_id": 1}, {"unique": true, "name": "patients_pk"});

// Indexes for doctors
db.doctors.createIndex({"doctor_id": 1}, {"unique": true, "name": "doctors_pk"});

// Indexes for specialties
db.specialties.createIndex({"specialty_id": 1}, {"unique": true, "name": "specialties_pk"});

// Indexes for appointments
db.appointments.createIndex({"appointment_id": 1}, {"unique": true, "name": "appointments_pk"});

// Indexes for invoices
db.invoices.createIndex({"invoice_id": 1}, {"unique": true, "name": "invoices_pk"});

// Indexes for invoice_items
db.invoice_items.createIndex({"invoice_item_id": 1}, {"unique": true, "name": "invoice_items_pk"});

// Indexes for payments
db.payments.createIndex({"payment_id": 1}, {"unique": true, "name": "payments_pk"});

// Indexes for payment_allocations
db.payment_allocations.createIndex({"payment_allocation_id": 1}, {"unique": true, "name": "payment_allocations_pk"});

// Validation for patients
db.runCommand({
  collMod: 'patients',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "nif",
      "first_name",
      "last_name",
      "date_of_birth",
      "phone",
      "email",
      "created_at"
    ],
    "properties": {
      "nif": {
        "bsonType": "string"
      },
      "first_name": {
        "bsonType": "string"
      },
      "last_name": {
        "bsonType": "string"
      },
      "date_of_birth": {
        "bsonType": "date"
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
      "status": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for doctors
db.runCommand({
  collMod: 'doctors',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "license_number",
      "first_name",
      "last_name",
      "email",
      "phone",
      "active_from"
    ],
    "properties": {
      "license_number": {
        "bsonType": "string"
      },
      "first_name": {
        "bsonType": "string"
      },
      "last_name": {
        "bsonType": "string"
      },
      "email": {
        "bsonType": "string"
      },
      "phone": {
        "bsonType": "string"
      },
      "active_from": {
        "bsonType": "date"
      },
      "active_to": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for specialties
db.runCommand({
  collMod: 'specialties',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "code",
      "name"
    ],
    "properties": {
      "code": {
        "bsonType": "string"
      },
      "name": {
        "bsonType": "string"
      },
      "description": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for doctor_specialties
db.runCommand({
  collMod: 'doctor_specialties',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "doctor_id",
      "specialty_id",
      "assigned_at"
    ],
    "properties": {
      "doctor_id": {
        "bsonType": "number"
      },
      "specialty_id": {
        "bsonType": "number"
      },
      "assigned_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for appointments
db.runCommand({
  collMod: 'appointments',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "patient_id",
      "doctor_id",
      "start_time",
      "end_time",
      "created_at",
      "updated_at"
    ],
    "properties": {
      "patient_id": {
        "bsonType": "number"
      },
      "doctor_id": {
        "bsonType": "number"
      },
      "start_time": {
        "bsonType": "date"
      },
      "end_time": {
        "bsonType": "date"
      },
      "status": {
        "bsonType": "string"
      },
      "cancel_reason": {
        "bsonType": "string"
      },
      "no_show_reason": {
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

// Validation for invoices
db.runCommand({
  collMod: 'invoices',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "patient_id",
      "invoice_number",
      "issued_at"
    ],
    "properties": {
      "patient_id": {
        "bsonType": "number"
      },
      "invoice_number": {
        "bsonType": "string"
      },
      "issued_at": {
        "bsonType": "date"
      },
      "status": {
        "bsonType": "string"
      },
      "total_amount": {
        "bsonType": "decimal128"
      }
    }
  }
}
});

// Validation for invoice_items
db.runCommand({
  collMod: 'invoice_items',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "invoice_id",
      "description",
      "quantity"
    ],
    "properties": {
      "invoice_id": {
        "bsonType": "number"
      },
      "appointment_id": {
        "bsonType": "number"
      },
      "description": {
        "bsonType": "string"
      },
      "quantity": {
        "bsonType": "number"
      },
      "unit_price": {
        "bsonType": "decimal128"
      },
      "line_total": {
        "bsonType": "decimal128"
      }
    }
  }
}
});

// Validation for payments
db.runCommand({
  collMod: 'payments',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "patient_id",
      "payment_date"
    ],
    "properties": {
      "patient_id": {
        "bsonType": "number"
      },
      "payment_date": {
        "bsonType": "date"
      },
      "method": {
        "bsonType": "string"
      },
      "reference": {
        "bsonType": "string"
      },
      "amount": {
        "bsonType": "decimal128"
      }
    }
  }
}
});

// Validation for payment_allocations
db.runCommand({
  collMod: 'payment_allocations',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "payment_id",
      "invoice_id"
    ],
    "properties": {
      "payment_id": {
        "bsonType": "number"
      },
      "invoice_id": {
        "bsonType": "number"
      },
      "amount_applied": {
        "bsonType": "decimal128"
      }
    }
  }
}
});
