# MongoDB Schema for example_01_clinic

Converted from MySQL on 2026-02-17T23:16:48.676382

## Collections

### patients

**Document Structure:**
```json
{
  "nif": {
    "type": "String",
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
  "date_of_birth": {
    "type": "Date",
    "required": true
  },
  "phone": {
    "type": "String",
    "required": true
  },
  "email": {
    "type": "String",
    "required": true
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "status": {
    "type": "String",
    "required": false
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### doctors

**Document Structure:**
```json
{
  "license_number": {
    "type": "String",
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
  "email": {
    "type": "String",
    "required": true
  },
  "phone": {
    "type": "String",
    "required": true
  },
  "active_from": {
    "type": "Date",
    "required": true
  },
  "active_to": {
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

### specialties

**Document Structure:**
```json
{
  "code": {
    "type": "String",
    "required": true
  },
  "name": {
    "type": "String",
    "required": true
  },
  "description": {
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

### doctor_specialties

**Document Structure:**
```json
{
  "doctor_id": {
    "type": "Number",
    "required": true
  },
  "specialty_id": {
    "type": "Number",
    "required": true
  },
  "assigned_at": {
    "type": "Date",
    "required": true,
    "default": "CURRENT_TIMESTAMP"
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

### appointments

**Document Structure:**
```json
{
  "patient_id": {
    "type": "Number",
    "required": true
  },
  "doctor_id": {
    "type": "Number",
    "required": true
  },
  "start_time": {
    "type": "Date",
    "required": true
  },
  "end_time": {
    "type": "Date",
    "required": true
  },
  "status": {
    "type": "String",
    "required": false
  },
  "cancel_reason": {
    "type": "String",
    "required": false
  },
  "no_show_reason": {
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

### invoices

**Document Structure:**
```json
{
  "patient_id": {
    "type": "Number",
    "required": true
  },
  "invoice_number": {
    "type": "String",
    "required": true
  },
  "issued_at": {
    "type": "Date",
    "required": true,
    "default": "CURRENT_TIMESTAMP"
  },
  "status": {
    "type": "String",
    "required": false
  },
  "total_amount": {
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

### invoice_items

**Document Structure:**
```json
{
  "invoice_id": {
    "type": "Number",
    "required": true
  },
  "appointment_id": {
    "type": "Number",
    "required": false
  },
  "description": {
    "type": "String",
    "required": true
  },
  "quantity": {
    "type": "Number",
    "required": true,
    "default": "1"
  },
  "unit_price": {
    "type": "Decimal128",
    "required": false
  },
  "line_total": {
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

### payments

**Document Structure:**
```json
{
  "patient_id": {
    "type": "Number",
    "required": true
  },
  "payment_date": {
    "type": "Date",
    "required": true,
    "default": "CURRENT_TIMESTAMP"
  },
  "method": {
    "type": "String",
    "required": false
  },
  "reference": {
    "type": "String",
    "required": false
  },
  "amount": {
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

### payment_allocations

**Document Structure:**
```json
{
  "payment_id": {
    "type": "Number",
    "required": true
  },
  "invoice_id": {
    "type": "Number",
    "required": true
  },
  "amount_applied": {
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

