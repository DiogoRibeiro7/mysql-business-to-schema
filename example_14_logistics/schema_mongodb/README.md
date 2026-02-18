# MongoDB Schema for example_14_logistics

Converted from MySQL on 2026-02-17T23:16:48.816887

## Collections

### warehouses

**Document Structure:**
```json
{
  "warehouse_name": {
    "type": "String",
    "required": true
  },
  "warehouse_type": {
    "type": "String",
    "required": false
  },
  "address_line1": {
    "type": "String",
    "required": true
  },
  "address_line2": {
    "type": "String",
    "required": false
  },
  "city": {
    "type": "String",
    "required": true
  },
  "state_province": {
    "type": "String",
    "required": false
  },
  "postal_code": {
    "type": "String",
    "required": false
  },
  "country_code": {
    "type": "String",
    "required": true
  },
  "latitude": {
    "type": "Decimal128",
    "required": false
  },
  "longitude": {
    "type": "Decimal128",
    "required": false
  },
  "total_capacity_cbm": {
    "type": "Decimal128",
    "required": false
  },
  "available_capacity_cbm": {
    "type": "Decimal128",
    "required": false
  },
  "operating_hours": {
    "type": "Object",
    "required": false
  },
  "capabilities": {
    "type": "Array",
    "required": false
  },
  "manager_name": {
    "type": "String",
    "required": false
  },
  "contact_phone": {
    "type": "String",
    "required": false
  },
  "contact_email": {
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

### warehouse_zones

**Document Structure:**
```json
{
  "warehouse_id": {
    "type": "Number",
    "required": true
  },
  "zone_code": {
    "type": "String",
    "required": true
  },
  "zone_name": {
    "type": "String",
    "required": false
  },
  "zone_type": {
    "type": "String",
    "required": false
  },
  "temperature_range": {
    "type": "String",
    "required": false
  },
  "max_weight_kg": {
    "type": "Decimal128",
    "required": false
  },
  "max_height_meters": {
    "type": "Decimal128",
    "required": false
  },
  "total_locations": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "occupied_locations": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "aisle_width_meters": {
    "type": "Decimal128",
    "required": false
  },
  "is_automated": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
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

**References:** warehouses_id

### warehouse_bins

**Document Structure:**
```json
{
  "zone_id": {
    "type": "Number",
    "required": true
  },
  "bin_code": {
    "type": "String",
    "required": true
  },
  "aisle": {
    "type": "String",
    "required": false
  },
  "rack": {
    "type": "String",
    "required": false
  },
  "level": {
    "type": "String",
    "required": false
  },
  "position": {
    "type": "String",
    "required": false
  },
  "bin_type": {
    "type": "String",
    "required": false
  },
  "max_weight_kg": {
    "type": "Decimal128",
    "required": false
  },
  "dimensions_lwh": {
    "type": "String",
    "required": false
  },
  "volume_cbm": {
    "type": "Decimal128",
    "required": false
  },
  "is_occupied": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "current_product_id": {
    "type": "Number",
    "required": false
  },
  "current_quantity": {
    "type": "Decimal128",
    "required": false
  },
  "last_counted_date": {
    "type": "Date",
    "required": false
  },
  "is_locked": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "lock_reason": {
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

**References:** warehouse_zones_id

### docking_stations

**Document Structure:**
```json
{
  "warehouse_id": {
    "type": "Number",
    "required": true
  },
  "dock_number": {
    "type": "String",
    "required": true
  },
  "dock_type": {
    "type": "String",
    "required": false
  },
  "door_height_meters": {
    "type": "Decimal128",
    "required": false
  },
  "door_width_meters": {
    "type": "Decimal128",
    "required": false
  },
  "has_dock_leveler": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "has_dock_seal": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "current_vehicle_id": {
    "type": "Number",
    "required": false
  },
  "current_shipment_id": {
    "type": "Number",
    "required": false
  },
  "status": {
    "type": "String",
    "required": false
  },
  "next_available_time": {
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

**References:** warehouses_id

### products

**Document Structure:**
```json
{
  "product_name": {
    "type": "String",
    "required": true
  },
  "product_description": {
    "type": "String",
    "required": false
  },
  "category": {
    "type": "String",
    "required": false
  },
  "subcategory": {
    "type": "String",
    "required": false
  },
  "brand": {
    "type": "String",
    "required": false
  },
  "unit_of_measure": {
    "type": "String",
    "required": false
  },
  "weight_kg": {
    "type": "Decimal128",
    "required": false
  },
  "dimensions_lwh": {
    "type": "String",
    "required": false
  },
  "volume_cbm": {
    "type": "Decimal128",
    "required": false
  },
  "is_hazmat": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "hazmat_class": {
    "type": "String",
    "required": false
  },
  "requires_temperature_control": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "min_temperature_celsius": {
    "type": "Decimal128",
    "required": false
  },
  "max_temperature_celsius": {
    "type": "Decimal128",
    "required": false
  },
  "shelf_life_days": {
    "type": "Number",
    "required": false
  },
  "is_serialized": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "is_lot_controlled": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "reorder_point": {
    "type": "Number",
    "required": false
  },
  "reorder_quantity": {
    "type": "Number",
    "required": false
  },
  "lead_time_days": {
    "type": "Number",
    "required": false
  },
  "unit_cost": {
    "type": "Decimal128",
    "required": false
  },
  "selling_price": {
    "type": "Decimal128",
    "required": false
  },
  "abc_classification": {
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
  },
  "FULLTEXT": {
    "type": "String",
    "required": false
  }
}
```

### inventory_levels

**Document Structure:**
```json
{
  "warehouse_id": {
    "type": "Number",
    "required": true
  },
  "product_id": {
    "type": "Number",
    "required": true
  },
  "quantity_on_hand": {
    "type": "Decimal128",
    "required": false
  },
  "quantity_available": {
    "type": "Decimal128",
    "required": false
  },
  "quantity_allocated": {
    "type": "Decimal128",
    "required": false
  },
  "quantity_in_transit": {
    "type": "Decimal128",
    "required": false
  },
  "quantity_damaged": {
    "type": "Decimal128",
    "required": false
  },
  "quantity_quarantine": {
    "type": "Decimal128",
    "required": false
  },
  "average_cost": {
    "type": "Decimal128",
    "required": false
  },
  "last_received_date": {
    "type": "Date",
    "required": false
  },
  "last_counted_date": {
    "type": "Date",
    "required": false
  },
  "last_shipped_date": {
    "type": "Date",
    "required": false
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** warehouses_id, products_id

### product_batches

**Document Structure:**
```json
{
  "product_id": {
    "type": "Number",
    "required": true
  },
  "warehouse_id": {
    "type": "Number",
    "required": true
  },
  "batch_number": {
    "type": "String",
    "required": true
  },
  "lot_number": {
    "type": "String",
    "required": false
  },
  "serial_numbers": {
    "type": "Object",
    "required": false
  },
  "manufacture_date": {
    "type": "Date",
    "required": false
  },
  "expiry_date": {
    "type": "Date",
    "required": false
  },
  "received_date": {
    "type": "Date",
    "required": true
  },
  "quantity_received": {
    "type": "Decimal128",
    "required": false
  },
  "quantity_remaining": {
    "type": "Decimal128",
    "required": false
  },
  "supplier_id": {
    "type": "Number",
    "required": false
  },
  "purchase_order_id": {
    "type": "Number",
    "required": false
  },
  "quality_status": {
    "type": "String",
    "required": false
  },
  "quality_certificate_url": {
    "type": "String",
    "required": false
  },
  "storage_conditions": {
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

**References:** products_id, warehouses_id

### inventory_movements

**Document Structure:**
```json
{
  "movement_type": {
    "type": "String",
    "required": false
  },
  "reference_type": {
    "type": "String",
    "required": false
  },
  "reference_id": {
    "type": "Number",
    "required": false
  },
  "product_id": {
    "type": "Number",
    "required": true
  },
  "batch_id": {
    "type": "Number",
    "required": false
  },
  "from_warehouse_id": {
    "type": "Number",
    "required": false
  },
  "from_bin_id": {
    "type": "Number",
    "required": false
  },
  "to_warehouse_id": {
    "type": "Number",
    "required": false
  },
  "to_bin_id": {
    "type": "Number",
    "required": false
  },
  "quantity": {
    "type": "Decimal128",
    "required": false
  },
  "unit_cost": {
    "type": "Decimal128",
    "required": false
  },
  "total_cost": {
    "type": "Decimal128",
    "required": false
  },
  "movement_date": {
    "type": "Date",
    "required": true,
    "default": "CURRENT_TIMESTAMP"
  },
  "performed_by": {
    "type": "Number",
    "required": false
  },
  "reason": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "PARTITION": {
    "type": "String",
    "required": false
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** products_id, product_batches_id, warehouses_id, warehouses_id, warehouse_bins_id, warehouse_bins_id

### suppliers

**Document Structure:**
```json
{
  "supplier_name": {
    "type": "String",
    "required": true
  },
  "supplier_type": {
    "type": "String",
    "required": false
  },
  "tax_id": {
    "type": "String",
    "required": false
  },
  "address_line1": {
    "type": "String",
    "required": false
  },
  "address_line2": {
    "type": "String",
    "required": false
  },
  "city": {
    "type": "String",
    "required": false
  },
  "state_province": {
    "type": "String",
    "required": false
  },
  "postal_code": {
    "type": "String",
    "required": false
  },
  "country_code": {
    "type": "String",
    "required": false
  },
  "contact_name": {
    "type": "String",
    "required": false
  },
  "contact_phone": {
    "type": "String",
    "required": false
  },
  "contact_email": {
    "type": "String",
    "required": false
  },
  "payment_terms": {
    "type": "String",
    "required": false
  },
  "currency_code": {
    "type": "String",
    "required": false
  },
  "credit_limit": {
    "type": "Decimal128",
    "required": false
  },
  "lead_time_days": {
    "type": "Number",
    "required": false
  },
  "minimum_order_value": {
    "type": "Decimal128",
    "required": false
  },
  "performance_score": {
    "type": "Decimal128",
    "required": false
  },
  "is_preferred": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "is_active": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "certifications": {
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

### customers

**Document Structure:**
```json
{
  "customer_name": {
    "type": "String",
    "required": true
  },
  "customer_type": {
    "type": "String",
    "required": false
  },
  "tax_id": {
    "type": "String",
    "required": false
  },
  "billing_address_line1": {
    "type": "String",
    "required": false
  },
  "billing_address_line2": {
    "type": "String",
    "required": false
  },
  "billing_city": {
    "type": "String",
    "required": false
  },
  "billing_state_province": {
    "type": "String",
    "required": false
  },
  "billing_postal_code": {
    "type": "String",
    "required": false
  },
  "billing_country_code": {
    "type": "String",
    "required": false
  },
  "shipping_same_as_billing": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "shipping_address_line1": {
    "type": "String",
    "required": false
  },
  "shipping_address_line2": {
    "type": "String",
    "required": false
  },
  "shipping_city": {
    "type": "String",
    "required": false
  },
  "shipping_state_province": {
    "type": "String",
    "required": false
  },
  "shipping_postal_code": {
    "type": "String",
    "required": false
  },
  "shipping_country_code": {
    "type": "String",
    "required": false
  },
  "contact_name": {
    "type": "String",
    "required": false
  },
  "contact_phone": {
    "type": "String",
    "required": false
  },
  "contact_email": {
    "type": "String",
    "required": false
  },
  "payment_terms": {
    "type": "String",
    "required": false
  },
  "credit_limit": {
    "type": "Decimal128",
    "required": false
  },
  "current_balance": {
    "type": "Decimal128",
    "required": false
  },
  "priority_level": {
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

### purchase_orders

**Document Structure:**
```json
{
  "supplier_id": {
    "type": "Number",
    "required": true
  },
  "warehouse_id": {
    "type": "Number",
    "required": true
  },
  "order_date": {
    "type": "Date",
    "required": true
  },
  "expected_delivery_date": {
    "type": "Date",
    "required": false
  },
  "actual_delivery_date": {
    "type": "Date",
    "required": false
  },
  "total_amount": {
    "type": "Decimal128",
    "required": false
  },
  "currency_code": {
    "type": "String",
    "required": false
  },
  "status": {
    "type": "String",
    "required": false
  },
  "payment_status": {
    "type": "String",
    "required": false
  },
  "notes": {
    "type": "String",
    "required": false
  },
  "created_by": {
    "type": "Number",
    "required": false
  },
  "approved_by": {
    "type": "Number",
    "required": false
  },
  "approval_date": {
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

**Embedded Documents:** purchase_order_itemss

**References:** suppliers_id, warehouses_id

### purchase_order_items

**Document Structure:**
```json
{
  "po_id": {
    "type": "Number",
    "required": true
  },
  "product_id": {
    "type": "Number",
    "required": true
  },
  "quantity_ordered": {
    "type": "Decimal128",
    "required": false
  },
  "quantity_received": {
    "type": "Decimal128",
    "required": false
  },
  "unit_price": {
    "type": "Decimal128",
    "required": false
  },
  "line_total": {
    "type": "Decimal128",
    "required": false
  },
  "discount_percent": {
    "type": "Decimal128",
    "required": false
  },
  "tax_amount": {
    "type": "Decimal128",
    "required": false
  },
  "expected_delivery_date": {
    "type": "Date",
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

**References:** products_id

### sales_orders

**Document Structure:**
```json
{
  "customer_id": {
    "type": "Number",
    "required": true
  },
  "order_date": {
    "type": "Date",
    "required": true
  },
  "requested_delivery_date": {
    "type": "Date",
    "required": false
  },
  "promised_delivery_date": {
    "type": "Date",
    "required": false
  },
  "actual_delivery_date": {
    "type": "Date",
    "required": false
  },
  "shipping_address_line1": {
    "type": "String",
    "required": false
  },
  "shipping_address_line2": {
    "type": "String",
    "required": false
  },
  "shipping_city": {
    "type": "String",
    "required": false
  },
  "shipping_state_province": {
    "type": "String",
    "required": false
  },
  "shipping_postal_code": {
    "type": "String",
    "required": false
  },
  "shipping_country_code": {
    "type": "String",
    "required": false
  },
  "subtotal_amount": {
    "type": "Decimal128",
    "required": false
  },
  "discount_amount": {
    "type": "Decimal128",
    "required": false
  },
  "tax_amount": {
    "type": "Decimal128",
    "required": false
  },
  "shipping_cost": {
    "type": "Decimal128",
    "required": false
  },
  "total_amount": {
    "type": "Decimal128",
    "required": false
  },
  "currency_code": {
    "type": "String",
    "required": false
  },
  "status": {
    "type": "String",
    "required": false
  },
  "payment_status": {
    "type": "String",
    "required": false
  },
  "fulfillment_priority": {
    "type": "String",
    "required": false
  },
  "special_instructions": {
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

**Embedded Documents:** sales_order_itemss

**References:** customers_id

### sales_order_items

**Document Structure:**
```json
{
  "so_id": {
    "type": "Number",
    "required": true
  },
  "product_id": {
    "type": "Number",
    "required": true
  },
  "warehouse_id": {
    "type": "Number",
    "required": false
  },
  "quantity_ordered": {
    "type": "Decimal128",
    "required": false
  },
  "quantity_allocated": {
    "type": "Decimal128",
    "required": false
  },
  "quantity_picked": {
    "type": "Decimal128",
    "required": false
  },
  "quantity_shipped": {
    "type": "Decimal128",
    "required": false
  },
  "unit_price": {
    "type": "Decimal128",
    "required": false
  },
  "discount_percent": {
    "type": "Decimal128",
    "required": false
  },
  "tax_rate": {
    "type": "Decimal128",
    "required": false
  },
  "line_total": {
    "type": "Decimal128",
    "required": false
  },
  "allocated_batch_id": {
    "type": "Number",
    "required": false
  },
  "backorder_quantity": {
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

**References:** products_id, warehouses_id, product_batches_id

### carriers

**Document Structure:**
```json
{
  "carrier_name": {
    "type": "String",
    "required": true
  },
  "carrier_type": {
    "type": "String",
    "required": false
  },
  "scac_code": {
    "type": "String",
    "required": false
  },
  "mc_number": {
    "type": "String",
    "required": false
  },
  "dot_number": {
    "type": "String",
    "required": false
  },
  "contact_name": {
    "type": "String",
    "required": false
  },
  "contact_phone": {
    "type": "String",
    "required": false
  },
  "contact_email": {
    "type": "String",
    "required": false
  },
  "api_endpoint": {
    "type": "String",
    "required": false
  },
  "tracking_url_template": {
    "type": "String",
    "required": false
  },
  "insurance_coverage": {
    "type": "Decimal128",
    "required": false
  },
  "liability_limit": {
    "type": "Decimal128",
    "required": false
  },
  "performance_score": {
    "type": "Decimal128",
    "required": false
  },
  "on_time_percentage": {
    "type": "Decimal128",
    "required": false
  },
  "damage_claim_rate": {
    "type": "Decimal128",
    "required": false
  },
  "is_preferred": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "is_active": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "supported_services": {
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

### carrier_services

**Document Structure:**
```json
{
  "carrier_id": {
    "type": "Number",
    "required": true
  },
  "service_code": {
    "type": "String",
    "required": true
  },
  "service_name": {
    "type": "String",
    "required": true
  },
  "service_type": {
    "type": "String",
    "required": false
  },
  "transit_time_days": {
    "type": "Number",
    "required": false
  },
  "cutoff_time": {
    "type": "String",
    "required": false
  },
  "delivery_commitment": {
    "type": "String",
    "required": false
  },
  "max_weight_kg": {
    "type": "Decimal128",
    "required": false
  },
  "max_dimensions_cm": {
    "type": "String",
    "required": false
  },
  "supports_cod": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "supports_insurance": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "supports_signature": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
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

**References:** carriers_id

### shipments

**Document Structure:**
```json
{
  "shipment_type": {
    "type": "String",
    "required": false
  },
  "reference_type": {
    "type": "String",
    "required": false
  },
  "reference_id": {
    "type": "Number",
    "required": false
  },
  "carrier_id": {
    "type": "Number",
    "required": false
  },
  "service_id": {
    "type": "Number",
    "required": false
  },
  "tracking_number": {
    "type": "String",
    "required": false
  },
  "from_warehouse_id": {
    "type": "Number",
    "required": false
  },
  "to_warehouse_id": {
    "type": "Number",
    "required": false
  },
  "origin_address": {
    "type": "Object",
    "required": false
  },
  "destination_address": {
    "type": "Object",
    "required": false
  },
  "pickup_date": {
    "type": "Date",
    "required": false
  },
  "delivery_date": {
    "type": "Date",
    "required": false
  },
  "actual_delivery_date": {
    "type": "Date",
    "required": false
  },
  "total_packages": {
    "type": "Number",
    "required": false
  },
  "total_weight_kg": {
    "type": "Decimal128",
    "required": false
  },
  "total_volume_cbm": {
    "type": "Decimal128",
    "required": false
  },
  "declared_value": {
    "type": "Decimal128",
    "required": false
  },
  "insurance_amount": {
    "type": "Decimal128",
    "required": false
  },
  "shipping_cost": {
    "type": "Decimal128",
    "required": false
  },
  "fuel_surcharge": {
    "type": "Decimal128",
    "required": false
  },
  "other_charges": {
    "type": "Decimal128",
    "required": false
  },
  "total_cost": {
    "type": "Decimal128",
    "required": false
  },
  "status": {
    "type": "String",
    "required": false
  },
  "status_details": {
    "type": "String",
    "required": false
  },
  "pod_signature": {
    "type": "String",
    "required": false
  },
  "pod_timestamp": {
    "type": "Date",
    "required": false
  },
  "temperature_controlled": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "temperature_range": {
    "type": "String",
    "required": false
  },
  "special_handling": {
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
  },
  "PARTITION": {
    "type": "String",
    "required": false
  }
}
```

**References:** carriers_id, carrier_services_id, warehouses_id, warehouses_id

### shipment_tracking

**Document Structure:**
```json
{
  "shipment_id": {
    "type": "Number",
    "required": true
  },
  "status_code": {
    "type": "String",
    "required": false
  },
  "status_description": {
    "type": "String",
    "required": false
  },
  "location_city": {
    "type": "String",
    "required": false
  },
  "location_state": {
    "type": "String",
    "required": false
  },
  "location_country": {
    "type": "String",
    "required": false
  },
  "location_zip": {
    "type": "String",
    "required": false
  },
  "latitude": {
    "type": "Decimal128",
    "required": false
  },
  "longitude": {
    "type": "Decimal128",
    "required": false
  },
  "event_timestamp": {
    "type": "Date",
    "required": true
  },
  "carrier_status_code": {
    "type": "String",
    "required": false
  },
  "exception_type": {
    "type": "String",
    "required": false
  },
  "exception_description": {
    "type": "String",
    "required": false
  },
  "estimated_delivery": {
    "type": "Date",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "PARTITION": {
    "type": "String",
    "required": false
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** shipments_id

### vehicles

**Document Structure:**
```json
{
  "vehicle_type": {
    "type": "String",
    "required": false
  },
  "make": {
    "type": "String",
    "required": false
  },
  "model": {
    "type": "String",
    "required": false
  },
  "year": {
    "type": "Number",
    "required": false
  },
  "vin": {
    "type": "String",
    "required": false
  },
  "license_plate": {
    "type": "String",
    "required": false
  },
  "registration_state": {
    "type": "String",
    "required": false
  },
  "ownership_type": {
    "type": "String",
    "required": false
  },
  "capacity_kg": {
    "type": "Decimal128",
    "required": false
  },
  "capacity_cbm": {
    "type": "Decimal128",
    "required": false
  },
  "fuel_type": {
    "type": "String",
    "required": false
  },
  "fuel_efficiency_km_per_liter": {
    "type": "Decimal128",
    "required": false
  },
  "current_odometer_km": {
    "type": "Number",
    "required": false
  },
  "last_service_date": {
    "type": "Date",
    "required": false
  },
  "next_service_date": {
    "type": "Date",
    "required": false
  },
  "insurance_policy_number": {
    "type": "String",
    "required": false
  },
  "insurance_expiry_date": {
    "type": "Date",
    "required": false
  },
  "current_location_lat": {
    "type": "Decimal128",
    "required": false
  },
  "current_location_lng": {
    "type": "Decimal128",
    "required": false
  },
  "current_status": {
    "type": "String",
    "required": false
  },
  "assigned_driver_id": {
    "type": "Number",
    "required": false
  },
  "home_warehouse_id": {
    "type": "Number",
    "required": false
  },
  "is_active": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "telematics_device_id": {
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

**References:** warehouses_id

### drivers

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
  "license_number": {
    "type": "String",
    "required": true
  },
  "license_class": {
    "type": "String",
    "required": false
  },
  "license_expiry_date": {
    "type": "Date",
    "required": false
  },
  "license_state": {
    "type": "String",
    "required": false
  },
  "phone_number": {
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
  "hire_date": {
    "type": "Date",
    "required": false
  },
  "home_base_warehouse_id": {
    "type": "Number",
    "required": false
  },
  "current_vehicle_id": {
    "type": "Number",
    "required": false
  },
  "hours_of_service_remaining": {
    "type": "Decimal128",
    "required": false
  },
  "last_drug_test_date": {
    "type": "Date",
    "required": false
  },
  "medical_certificate_expiry": {
    "type": "Date",
    "required": false
  },
  "safety_score": {
    "type": "Decimal128",
    "required": false
  },
  "total_miles_driven": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "total_deliveries": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "status": {
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

**References:** warehouses_id, vehicles_id

### routes

**Document Structure:**
```json
{
  "route_name": {
    "type": "String",
    "required": false
  },
  "route_type": {
    "type": "String",
    "required": false
  },
  "origin_warehouse_id": {
    "type": "Number",
    "required": true
  },
  "destination_warehouse_id": {
    "type": "Number",
    "required": false
  },
  "total_distance_km": {
    "type": "Decimal128",
    "required": false
  },
  "estimated_duration_hours": {
    "type": "Decimal128",
    "required": false
  },
  "stops": {
    "type": "Object",
    "required": false
  },
  "preferred_departure_time": {
    "type": "String",
    "required": false
  },
  "service_days": {
    "type": "Array",
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

**References:** warehouses_id, warehouses_id

### delivery_runs

**Document Structure:**
```json
{
  "run_date": {
    "type": "Date",
    "required": true
  },
  "route_id": {
    "type": "Number",
    "required": false
  },
  "vehicle_id": {
    "type": "Number",
    "required": true
  },
  "driver_id": {
    "type": "Number",
    "required": true
  },
  "planned_start_time": {
    "type": "Date",
    "required": false
  },
  "actual_start_time": {
    "type": "Date",
    "required": false
  },
  "planned_end_time": {
    "type": "Date",
    "required": false
  },
  "actual_end_time": {
    "type": "Date",
    "required": false
  },
  "total_stops": {
    "type": "Number",
    "required": false
  },
  "completed_stops": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "total_packages": {
    "type": "Number",
    "required": false
  },
  "delivered_packages": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "total_distance_km": {
    "type": "Decimal128",
    "required": false
  },
  "fuel_consumed_liters": {
    "type": "Decimal128",
    "required": false
  },
  "status": {
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

**References:** routes_id, vehicles_id, drivers_id

### kpi_metrics

**Document Structure:**
```json
{
  "metric_date": {
    "type": "Date",
    "required": true
  },
  "metric_type": {
    "type": "String",
    "required": false
  },
  "warehouse_id": {
    "type": "Number",
    "required": false
  },
  "inventory_turnover_ratio": {
    "type": "Decimal128",
    "required": false
  },
  "stockout_incidents": {
    "type": "Number",
    "required": false
  },
  "inventory_accuracy_percent": {
    "type": "Decimal128",
    "required": false
  },
  "carrying_cost": {
    "type": "Decimal128",
    "required": false
  },
  "orders_processed": {
    "type": "Number",
    "required": false
  },
  "perfect_order_rate": {
    "type": "Decimal128",
    "required": false
  },
  "order_cycle_time_hours": {
    "type": "Decimal128",
    "required": false
  },
  "fill_rate_percent": {
    "type": "Decimal128",
    "required": false
  },
  "backorder_rate_percent": {
    "type": "Decimal128",
    "required": false
  },
  "warehouse_utilization_percent": {
    "type": "Decimal128",
    "required": false
  },
  "picking_accuracy_percent": {
    "type": "Decimal128",
    "required": false
  },
  "putaway_cycle_time_minutes": {
    "type": "Decimal128",
    "required": false
  },
  "labor_productivity_units_per_hour": {
    "type": "Decimal128",
    "required": false
  },
  "on_time_delivery_percent": {
    "type": "Decimal128",
    "required": false
  },
  "freight_cost_per_unit": {
    "type": "Decimal128",
    "required": false
  },
  "delivery_success_rate": {
    "type": "Decimal128",
    "required": false
  },
  "average_delivery_time_hours": {
    "type": "Decimal128",
    "required": false
  },
  "fuel_efficiency_km_per_liter": {
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

**References:** warehouses_id

### audit_log

**Document Structure:**
```json
{
  "table_name": {
    "type": "String",
    "required": true
  },
  "record_id": {
    "type": "Number",
    "required": true
  },
  "action": {
    "type": "String",
    "required": false
  },
  "changed_by": {
    "type": "Number",
    "required": false
  },
  "changed_at": {
    "type": "Date",
    "required": false,
    "default": "CURRENT_TIMESTAMP"
  },
  "old_values": {
    "type": "Object",
    "required": false
  },
  "new_values": {
    "type": "Object",
    "required": false
  },
  "ip_address": {
    "type": "String",
    "required": false
  },
  "user_agent": {
    "type": "String",
    "required": false
  },
  "PARTITION": {
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

