// MongoDB Migration Script
// Generated: 2026-02-17T23:16:48.815372
// From MySQL to MongoDB

use converted_db;

// Create collection: warehouses
db.createCollection('warehouses');

// Create collection: warehouse_zones
db.createCollection('warehouse_zones');

// Create collection: warehouse_bins
db.createCollection('warehouse_bins');

// Create collection: docking_stations
db.createCollection('docking_stations');

// Create collection: products
db.createCollection('products');

// Create collection: inventory_levels
db.createCollection('inventory_levels');

// Create collection: product_batches
db.createCollection('product_batches');

// Create collection: inventory_movements
db.createCollection('inventory_movements');

// Create collection: suppliers
db.createCollection('suppliers');

// Create collection: customers
db.createCollection('customers');

// Create collection: purchase_orders
db.createCollection('purchase_orders');

// Create collection: purchase_order_items
db.createCollection('purchase_order_items');

// Create collection: sales_orders
db.createCollection('sales_orders');

// Create collection: sales_order_items
db.createCollection('sales_order_items');

// Create collection: carriers
db.createCollection('carriers');

// Create collection: carrier_services
db.createCollection('carrier_services');

// Create collection: shipments
db.createCollection('shipments');

// Create collection: shipment_tracking
db.createCollection('shipment_tracking');

// Create collection: vehicles
db.createCollection('vehicles');

// Create collection: drivers
db.createCollection('drivers');

// Create collection: routes
db.createCollection('routes');

// Create collection: delivery_runs
db.createCollection('delivery_runs');

// Create collection: kpi_metrics
db.createCollection('kpi_metrics');

// Create collection: audit_log
db.createCollection('audit_log');

// Indexes for warehouses

// Indexes for warehouse_zones
db.warehouse_zones.createIndex({"warehouse_id": 1}, {"name": "warehouse_zones_warehouse_id_idx"});

// Indexes for warehouse_bins
db.warehouse_bins.createIndex({"zone_id": 1}, {"name": "warehouse_bins_zone_id_idx"});

// Indexes for docking_stations
db.docking_stations.createIndex({"warehouse_id": 1}, {"name": "docking_stations_warehouse_id_idx"});

// Indexes for products
db.products.createIndex({"product_description": "text"}, {"name": "products_text"});

// Indexes for inventory_levels
db.inventory_levels.createIndex({"warehouse_id": 1}, {"name": "inventory_levels_warehouse_id_idx"});
db.inventory_levels.createIndex({"product_id": 1}, {"name": "inventory_levels_product_id_idx"});

// Indexes for product_batches
db.product_batches.createIndex({"product_id": 1}, {"name": "product_batches_product_id_idx"});
db.product_batches.createIndex({"warehouse_id": 1}, {"name": "product_batches_warehouse_id_idx"});
db.product_batches.createIndex({"storage_conditions": "text"}, {"name": "product_batches_text"});

// Indexes for inventory_movements
db.inventory_movements.createIndex({"product_id": 1}, {"name": "inventory_movements_product_id_idx"});
db.inventory_movements.createIndex({"batch_id": 1}, {"name": "inventory_movements_batch_id_idx"});
db.inventory_movements.createIndex({"from_warehouse_id": 1}, {"name": "inventory_movements_from_warehouse_id_idx"});
db.inventory_movements.createIndex({"to_warehouse_id": 1}, {"name": "inventory_movements_to_warehouse_id_idx"});
db.inventory_movements.createIndex({"from_bin_id": 1}, {"name": "inventory_movements_from_bin_id_idx"});
db.inventory_movements.createIndex({"to_bin_id": 1}, {"name": "inventory_movements_to_bin_id_idx"});
db.inventory_movements.createIndex({"reason": "text"}, {"name": "inventory_movements_text"});

// Indexes for suppliers

// Indexes for customers

// Indexes for purchase_orders
db.purchase_orders.createIndex({"supplier_id": 1}, {"name": "purchase_orders_supplier_id_idx"});
db.purchase_orders.createIndex({"warehouse_id": 1}, {"name": "purchase_orders_warehouse_id_idx"});
db.purchase_orders.createIndex({"notes": "text"}, {"name": "purchase_orders_text"});

// Indexes for purchase_order_items
db.purchase_order_items.createIndex({"po_id": 1}, {"name": "purchase_order_items_po_id_idx"});
db.purchase_order_items.createIndex({"product_id": 1}, {"name": "purchase_order_items_product_id_idx"});
db.purchase_order_items.createIndex({"notes": "text"}, {"name": "purchase_order_items_text"});

// Indexes for sales_orders
db.sales_orders.createIndex({"customer_id": 1}, {"name": "sales_orders_customer_id_idx"});
db.sales_orders.createIndex({"special_instructions": "text"}, {"name": "sales_orders_text"});

// Indexes for sales_order_items
db.sales_order_items.createIndex({"so_id": 1}, {"name": "sales_order_items_so_id_idx"});
db.sales_order_items.createIndex({"product_id": 1}, {"name": "sales_order_items_product_id_idx"});
db.sales_order_items.createIndex({"warehouse_id": 1}, {"name": "sales_order_items_warehouse_id_idx"});
db.sales_order_items.createIndex({"allocated_batch_id": 1}, {"name": "sales_order_items_allocated_batch_id_idx"});
db.sales_order_items.createIndex({"notes": "text"}, {"name": "sales_order_items_text"});

// Indexes for carriers

// Indexes for carrier_services
db.carrier_services.createIndex({"carrier_id": 1}, {"name": "carrier_services_carrier_id_idx"});

// Indexes for shipments
db.shipments.createIndex({"carrier_id": 1}, {"name": "shipments_carrier_id_idx"});
db.shipments.createIndex({"service_id": 1}, {"name": "shipments_service_id_idx"});
db.shipments.createIndex({"from_warehouse_id": 1}, {"name": "shipments_from_warehouse_id_idx"});
db.shipments.createIndex({"to_warehouse_id": 1}, {"name": "shipments_to_warehouse_id_idx"});
db.shipments.createIndex({"status_details": "text"}, {"name": "shipments_text"});

// Indexes for shipment_tracking
db.shipment_tracking.createIndex({"shipment_id": 1}, {"name": "shipment_tracking_shipment_id_idx"});
db.shipment_tracking.createIndex({"status_description": "text", "exception_description": "text"}, {"name": "shipment_tracking_text"});

// Indexes for vehicles
db.vehicles.createIndex({"home_warehouse_id": 1}, {"name": "vehicles_home_warehouse_id_idx"});

// Indexes for drivers
db.drivers.createIndex({"home_base_warehouse_id": 1}, {"name": "drivers_home_base_warehouse_id_idx"});
db.drivers.createIndex({"current_vehicle_id": 1}, {"name": "drivers_current_vehicle_id_idx"});

// Indexes for routes
db.routes.createIndex({"origin_warehouse_id": 1}, {"name": "routes_origin_warehouse_id_idx"});
db.routes.createIndex({"destination_warehouse_id": 1}, {"name": "routes_destination_warehouse_id_idx"});

// Indexes for delivery_runs
db.delivery_runs.createIndex({"route_id": 1}, {"name": "delivery_runs_route_id_idx"});
db.delivery_runs.createIndex({"vehicle_id": 1}, {"name": "delivery_runs_vehicle_id_idx"});
db.delivery_runs.createIndex({"driver_id": 1}, {"name": "delivery_runs_driver_id_idx"});
db.delivery_runs.createIndex({"notes": "text"}, {"name": "delivery_runs_text"});

// Indexes for kpi_metrics
db.kpi_metrics.createIndex({"warehouse_id": 1}, {"name": "kpi_metrics_warehouse_id_idx"});

// Validation for warehouses
db.runCommand({
  collMod: 'warehouses',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "warehouse_name",
      "address_line1",
      "city",
      "country_code"
    ],
    "properties": {
      "warehouse_name": {
        "bsonType": "string"
      },
      "warehouse_type": {
        "bsonType": "string"
      },
      "address_line1": {
        "bsonType": "string"
      },
      "address_line2": {
        "bsonType": "string"
      },
      "city": {
        "bsonType": "string"
      },
      "state_province": {
        "bsonType": "string"
      },
      "postal_code": {
        "bsonType": "string"
      },
      "country_code": {
        "bsonType": "string"
      },
      "latitude": {
        "bsonType": "decimal128"
      },
      "longitude": {
        "bsonType": "decimal128"
      },
      "total_capacity_cbm": {
        "bsonType": "decimal128"
      },
      "available_capacity_cbm": {
        "bsonType": "decimal128"
      },
      "operating_hours": {
        "bsonType": "object"
      },
      "capabilities": {
        "bsonType": "array"
      },
      "manager_name": {
        "bsonType": "string"
      },
      "contact_phone": {
        "bsonType": "string"
      },
      "contact_email": {
        "bsonType": "string"
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

// Validation for warehouse_zones
db.runCommand({
  collMod: 'warehouse_zones',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "warehouse_id",
      "zone_code"
    ],
    "properties": {
      "warehouse_id": {
        "bsonType": "number"
      },
      "zone_code": {
        "bsonType": "string"
      },
      "zone_name": {
        "bsonType": "string"
      },
      "zone_type": {
        "bsonType": "string"
      },
      "temperature_range": {
        "bsonType": "string"
      },
      "max_weight_kg": {
        "bsonType": "decimal128"
      },
      "max_height_meters": {
        "bsonType": "decimal128"
      },
      "total_locations": {
        "bsonType": "number"
      },
      "occupied_locations": {
        "bsonType": "number"
      },
      "aisle_width_meters": {
        "bsonType": "decimal128"
      },
      "is_automated": {
        "bsonType": "boolean"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for warehouse_bins
db.runCommand({
  collMod: 'warehouse_bins',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "zone_id",
      "bin_code"
    ],
    "properties": {
      "zone_id": {
        "bsonType": "number"
      },
      "bin_code": {
        "bsonType": "string"
      },
      "aisle": {
        "bsonType": "string"
      },
      "rack": {
        "bsonType": "string"
      },
      "level": {
        "bsonType": "string"
      },
      "position": {
        "bsonType": "string"
      },
      "bin_type": {
        "bsonType": "string"
      },
      "max_weight_kg": {
        "bsonType": "decimal128"
      },
      "dimensions_lwh": {
        "bsonType": "string"
      },
      "volume_cbm": {
        "bsonType": "decimal128"
      },
      "is_occupied": {
        "bsonType": "boolean"
      },
      "current_product_id": {
        "bsonType": "number"
      },
      "current_quantity": {
        "bsonType": "decimal128"
      },
      "last_counted_date": {
        "bsonType": "date"
      },
      "is_locked": {
        "bsonType": "boolean"
      },
      "lock_reason": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for docking_stations
db.runCommand({
  collMod: 'docking_stations',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "warehouse_id",
      "dock_number"
    ],
    "properties": {
      "warehouse_id": {
        "bsonType": "number"
      },
      "dock_number": {
        "bsonType": "string"
      },
      "dock_type": {
        "bsonType": "string"
      },
      "door_height_meters": {
        "bsonType": "decimal128"
      },
      "door_width_meters": {
        "bsonType": "decimal128"
      },
      "has_dock_leveler": {
        "bsonType": "boolean"
      },
      "has_dock_seal": {
        "bsonType": "boolean"
      },
      "current_vehicle_id": {
        "bsonType": "number"
      },
      "current_shipment_id": {
        "bsonType": "number"
      },
      "status": {
        "bsonType": "string"
      },
      "next_available_time": {
        "bsonType": "date"
      },
      "created_at": {
        "bsonType": "date"
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
      "product_description": {
        "bsonType": "string"
      },
      "category": {
        "bsonType": "string"
      },
      "subcategory": {
        "bsonType": "string"
      },
      "brand": {
        "bsonType": "string"
      },
      "unit_of_measure": {
        "bsonType": "string"
      },
      "weight_kg": {
        "bsonType": "decimal128"
      },
      "dimensions_lwh": {
        "bsonType": "string"
      },
      "volume_cbm": {
        "bsonType": "decimal128"
      },
      "is_hazmat": {
        "bsonType": "boolean"
      },
      "hazmat_class": {
        "bsonType": "string"
      },
      "requires_temperature_control": {
        "bsonType": "boolean"
      },
      "min_temperature_celsius": {
        "bsonType": "decimal128"
      },
      "max_temperature_celsius": {
        "bsonType": "decimal128"
      },
      "shelf_life_days": {
        "bsonType": "number"
      },
      "is_serialized": {
        "bsonType": "boolean"
      },
      "is_lot_controlled": {
        "bsonType": "boolean"
      },
      "reorder_point": {
        "bsonType": "number"
      },
      "reorder_quantity": {
        "bsonType": "number"
      },
      "lead_time_days": {
        "bsonType": "number"
      },
      "unit_cost": {
        "bsonType": "decimal128"
      },
      "selling_price": {
        "bsonType": "decimal128"
      },
      "abc_classification": {
        "bsonType": "string"
      },
      "is_active": {
        "bsonType": "boolean"
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

// Validation for inventory_levels
db.runCommand({
  collMod: 'inventory_levels',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "warehouse_id",
      "product_id"
    ],
    "properties": {
      "warehouse_id": {
        "bsonType": "number"
      },
      "product_id": {
        "bsonType": "number"
      },
      "quantity_on_hand": {
        "bsonType": "decimal128"
      },
      "quantity_available": {
        "bsonType": "decimal128"
      },
      "quantity_allocated": {
        "bsonType": "decimal128"
      },
      "quantity_in_transit": {
        "bsonType": "decimal128"
      },
      "quantity_damaged": {
        "bsonType": "decimal128"
      },
      "quantity_quarantine": {
        "bsonType": "decimal128"
      },
      "average_cost": {
        "bsonType": "decimal128"
      },
      "last_received_date": {
        "bsonType": "date"
      },
      "last_counted_date": {
        "bsonType": "date"
      },
      "last_shipped_date": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for product_batches
db.runCommand({
  collMod: 'product_batches',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "product_id",
      "warehouse_id",
      "batch_number",
      "received_date"
    ],
    "properties": {
      "product_id": {
        "bsonType": "number"
      },
      "warehouse_id": {
        "bsonType": "number"
      },
      "batch_number": {
        "bsonType": "string"
      },
      "lot_number": {
        "bsonType": "string"
      },
      "serial_numbers": {
        "bsonType": "object"
      },
      "manufacture_date": {
        "bsonType": "date"
      },
      "expiry_date": {
        "bsonType": "date"
      },
      "received_date": {
        "bsonType": "date"
      },
      "quantity_received": {
        "bsonType": "decimal128"
      },
      "quantity_remaining": {
        "bsonType": "decimal128"
      },
      "supplier_id": {
        "bsonType": "number"
      },
      "purchase_order_id": {
        "bsonType": "number"
      },
      "quality_status": {
        "bsonType": "string"
      },
      "quality_certificate_url": {
        "bsonType": "string"
      },
      "storage_conditions": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for inventory_movements
db.runCommand({
  collMod: 'inventory_movements',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "product_id",
      "movement_date"
    ],
    "properties": {
      "movement_type": {
        "bsonType": "string"
      },
      "reference_type": {
        "bsonType": "string"
      },
      "reference_id": {
        "bsonType": "number"
      },
      "product_id": {
        "bsonType": "number"
      },
      "batch_id": {
        "bsonType": "number"
      },
      "from_warehouse_id": {
        "bsonType": "number"
      },
      "from_bin_id": {
        "bsonType": "number"
      },
      "to_warehouse_id": {
        "bsonType": "number"
      },
      "to_bin_id": {
        "bsonType": "number"
      },
      "quantity": {
        "bsonType": "decimal128"
      },
      "unit_cost": {
        "bsonType": "decimal128"
      },
      "total_cost": {
        "bsonType": "decimal128"
      },
      "movement_date": {
        "bsonType": "date"
      },
      "performed_by": {
        "bsonType": "number"
      },
      "reason": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      },
      "PARTITION": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for suppliers
db.runCommand({
  collMod: 'suppliers',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "supplier_name"
    ],
    "properties": {
      "supplier_name": {
        "bsonType": "string"
      },
      "supplier_type": {
        "bsonType": "string"
      },
      "tax_id": {
        "bsonType": "string"
      },
      "address_line1": {
        "bsonType": "string"
      },
      "address_line2": {
        "bsonType": "string"
      },
      "city": {
        "bsonType": "string"
      },
      "state_province": {
        "bsonType": "string"
      },
      "postal_code": {
        "bsonType": "string"
      },
      "country_code": {
        "bsonType": "string"
      },
      "contact_name": {
        "bsonType": "string"
      },
      "contact_phone": {
        "bsonType": "string"
      },
      "contact_email": {
        "bsonType": "string"
      },
      "payment_terms": {
        "bsonType": "string"
      },
      "currency_code": {
        "bsonType": "string"
      },
      "credit_limit": {
        "bsonType": "decimal128"
      },
      "lead_time_days": {
        "bsonType": "number"
      },
      "minimum_order_value": {
        "bsonType": "decimal128"
      },
      "performance_score": {
        "bsonType": "decimal128"
      },
      "is_preferred": {
        "bsonType": "boolean"
      },
      "is_active": {
        "bsonType": "boolean"
      },
      "certifications": {
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

// Validation for customers
db.runCommand({
  collMod: 'customers',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "customer_name"
    ],
    "properties": {
      "customer_name": {
        "bsonType": "string"
      },
      "customer_type": {
        "bsonType": "string"
      },
      "tax_id": {
        "bsonType": "string"
      },
      "billing_address_line1": {
        "bsonType": "string"
      },
      "billing_address_line2": {
        "bsonType": "string"
      },
      "billing_city": {
        "bsonType": "string"
      },
      "billing_state_province": {
        "bsonType": "string"
      },
      "billing_postal_code": {
        "bsonType": "string"
      },
      "billing_country_code": {
        "bsonType": "string"
      },
      "shipping_same_as_billing": {
        "bsonType": "boolean"
      },
      "shipping_address_line1": {
        "bsonType": "string"
      },
      "shipping_address_line2": {
        "bsonType": "string"
      },
      "shipping_city": {
        "bsonType": "string"
      },
      "shipping_state_province": {
        "bsonType": "string"
      },
      "shipping_postal_code": {
        "bsonType": "string"
      },
      "shipping_country_code": {
        "bsonType": "string"
      },
      "contact_name": {
        "bsonType": "string"
      },
      "contact_phone": {
        "bsonType": "string"
      },
      "contact_email": {
        "bsonType": "string"
      },
      "payment_terms": {
        "bsonType": "string"
      },
      "credit_limit": {
        "bsonType": "decimal128"
      },
      "current_balance": {
        "bsonType": "decimal128"
      },
      "priority_level": {
        "bsonType": "string"
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

// Validation for purchase_orders
db.runCommand({
  collMod: 'purchase_orders',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "supplier_id",
      "warehouse_id",
      "order_date"
    ],
    "properties": {
      "supplier_id": {
        "bsonType": "number"
      },
      "warehouse_id": {
        "bsonType": "number"
      },
      "order_date": {
        "bsonType": "date"
      },
      "expected_delivery_date": {
        "bsonType": "date"
      },
      "actual_delivery_date": {
        "bsonType": "date"
      },
      "total_amount": {
        "bsonType": "decimal128"
      },
      "currency_code": {
        "bsonType": "string"
      },
      "status": {
        "bsonType": "string"
      },
      "payment_status": {
        "bsonType": "string"
      },
      "notes": {
        "bsonType": "string"
      },
      "created_by": {
        "bsonType": "number"
      },
      "approved_by": {
        "bsonType": "number"
      },
      "approval_date": {
        "bsonType": "date"
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

// Validation for purchase_order_items
db.runCommand({
  collMod: 'purchase_order_items',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "po_id",
      "product_id"
    ],
    "properties": {
      "po_id": {
        "bsonType": "number"
      },
      "product_id": {
        "bsonType": "number"
      },
      "quantity_ordered": {
        "bsonType": "decimal128"
      },
      "quantity_received": {
        "bsonType": "decimal128"
      },
      "unit_price": {
        "bsonType": "decimal128"
      },
      "line_total": {
        "bsonType": "decimal128"
      },
      "discount_percent": {
        "bsonType": "decimal128"
      },
      "tax_amount": {
        "bsonType": "decimal128"
      },
      "expected_delivery_date": {
        "bsonType": "date"
      },
      "notes": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for sales_orders
db.runCommand({
  collMod: 'sales_orders',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "customer_id",
      "order_date"
    ],
    "properties": {
      "customer_id": {
        "bsonType": "number"
      },
      "order_date": {
        "bsonType": "date"
      },
      "requested_delivery_date": {
        "bsonType": "date"
      },
      "promised_delivery_date": {
        "bsonType": "date"
      },
      "actual_delivery_date": {
        "bsonType": "date"
      },
      "shipping_address_line1": {
        "bsonType": "string"
      },
      "shipping_address_line2": {
        "bsonType": "string"
      },
      "shipping_city": {
        "bsonType": "string"
      },
      "shipping_state_province": {
        "bsonType": "string"
      },
      "shipping_postal_code": {
        "bsonType": "string"
      },
      "shipping_country_code": {
        "bsonType": "string"
      },
      "subtotal_amount": {
        "bsonType": "decimal128"
      },
      "discount_amount": {
        "bsonType": "decimal128"
      },
      "tax_amount": {
        "bsonType": "decimal128"
      },
      "shipping_cost": {
        "bsonType": "decimal128"
      },
      "total_amount": {
        "bsonType": "decimal128"
      },
      "currency_code": {
        "bsonType": "string"
      },
      "status": {
        "bsonType": "string"
      },
      "payment_status": {
        "bsonType": "string"
      },
      "fulfillment_priority": {
        "bsonType": "string"
      },
      "special_instructions": {
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

// Validation for sales_order_items
db.runCommand({
  collMod: 'sales_order_items',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "so_id",
      "product_id"
    ],
    "properties": {
      "so_id": {
        "bsonType": "number"
      },
      "product_id": {
        "bsonType": "number"
      },
      "warehouse_id": {
        "bsonType": "number"
      },
      "quantity_ordered": {
        "bsonType": "decimal128"
      },
      "quantity_allocated": {
        "bsonType": "decimal128"
      },
      "quantity_picked": {
        "bsonType": "decimal128"
      },
      "quantity_shipped": {
        "bsonType": "decimal128"
      },
      "unit_price": {
        "bsonType": "decimal128"
      },
      "discount_percent": {
        "bsonType": "decimal128"
      },
      "tax_rate": {
        "bsonType": "decimal128"
      },
      "line_total": {
        "bsonType": "decimal128"
      },
      "allocated_batch_id": {
        "bsonType": "number"
      },
      "backorder_quantity": {
        "bsonType": "decimal128"
      },
      "notes": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for carriers
db.runCommand({
  collMod: 'carriers',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "carrier_name"
    ],
    "properties": {
      "carrier_name": {
        "bsonType": "string"
      },
      "carrier_type": {
        "bsonType": "string"
      },
      "scac_code": {
        "bsonType": "string"
      },
      "mc_number": {
        "bsonType": "string"
      },
      "dot_number": {
        "bsonType": "string"
      },
      "contact_name": {
        "bsonType": "string"
      },
      "contact_phone": {
        "bsonType": "string"
      },
      "contact_email": {
        "bsonType": "string"
      },
      "api_endpoint": {
        "bsonType": "string"
      },
      "tracking_url_template": {
        "bsonType": "string"
      },
      "insurance_coverage": {
        "bsonType": "decimal128"
      },
      "liability_limit": {
        "bsonType": "decimal128"
      },
      "performance_score": {
        "bsonType": "decimal128"
      },
      "on_time_percentage": {
        "bsonType": "decimal128"
      },
      "damage_claim_rate": {
        "bsonType": "decimal128"
      },
      "is_preferred": {
        "bsonType": "boolean"
      },
      "is_active": {
        "bsonType": "boolean"
      },
      "supported_services": {
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

// Validation for carrier_services
db.runCommand({
  collMod: 'carrier_services',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "carrier_id",
      "service_code",
      "service_name"
    ],
    "properties": {
      "carrier_id": {
        "bsonType": "number"
      },
      "service_code": {
        "bsonType": "string"
      },
      "service_name": {
        "bsonType": "string"
      },
      "service_type": {
        "bsonType": "string"
      },
      "transit_time_days": {
        "bsonType": "number"
      },
      "cutoff_time": {
        "bsonType": "string"
      },
      "delivery_commitment": {
        "bsonType": "string"
      },
      "max_weight_kg": {
        "bsonType": "decimal128"
      },
      "max_dimensions_cm": {
        "bsonType": "string"
      },
      "supports_cod": {
        "bsonType": "boolean"
      },
      "supports_insurance": {
        "bsonType": "boolean"
      },
      "supports_signature": {
        "bsonType": "boolean"
      },
      "is_active": {
        "bsonType": "boolean"
      }
    }
  }
}
});

// Validation for shipments
db.runCommand({
  collMod: 'shipments',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [],
    "properties": {
      "shipment_type": {
        "bsonType": "string"
      },
      "reference_type": {
        "bsonType": "string"
      },
      "reference_id": {
        "bsonType": "number"
      },
      "carrier_id": {
        "bsonType": "number"
      },
      "service_id": {
        "bsonType": "number"
      },
      "tracking_number": {
        "bsonType": "string"
      },
      "from_warehouse_id": {
        "bsonType": "number"
      },
      "to_warehouse_id": {
        "bsonType": "number"
      },
      "origin_address": {
        "bsonType": "object"
      },
      "destination_address": {
        "bsonType": "object"
      },
      "pickup_date": {
        "bsonType": "date"
      },
      "delivery_date": {
        "bsonType": "date"
      },
      "actual_delivery_date": {
        "bsonType": "date"
      },
      "total_packages": {
        "bsonType": "number"
      },
      "total_weight_kg": {
        "bsonType": "decimal128"
      },
      "total_volume_cbm": {
        "bsonType": "decimal128"
      },
      "declared_value": {
        "bsonType": "decimal128"
      },
      "insurance_amount": {
        "bsonType": "decimal128"
      },
      "shipping_cost": {
        "bsonType": "decimal128"
      },
      "fuel_surcharge": {
        "bsonType": "decimal128"
      },
      "other_charges": {
        "bsonType": "decimal128"
      },
      "total_cost": {
        "bsonType": "decimal128"
      },
      "status": {
        "bsonType": "string"
      },
      "status_details": {
        "bsonType": "string"
      },
      "pod_signature": {
        "bsonType": "string"
      },
      "pod_timestamp": {
        "bsonType": "date"
      },
      "temperature_controlled": {
        "bsonType": "boolean"
      },
      "temperature_range": {
        "bsonType": "string"
      },
      "special_handling": {
        "bsonType": "object"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      },
      "PARTITION": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for shipment_tracking
db.runCommand({
  collMod: 'shipment_tracking',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "shipment_id",
      "event_timestamp"
    ],
    "properties": {
      "shipment_id": {
        "bsonType": "number"
      },
      "status_code": {
        "bsonType": "string"
      },
      "status_description": {
        "bsonType": "string"
      },
      "location_city": {
        "bsonType": "string"
      },
      "location_state": {
        "bsonType": "string"
      },
      "location_country": {
        "bsonType": "string"
      },
      "location_zip": {
        "bsonType": "string"
      },
      "latitude": {
        "bsonType": "decimal128"
      },
      "longitude": {
        "bsonType": "decimal128"
      },
      "event_timestamp": {
        "bsonType": "date"
      },
      "carrier_status_code": {
        "bsonType": "string"
      },
      "exception_type": {
        "bsonType": "string"
      },
      "exception_description": {
        "bsonType": "string"
      },
      "estimated_delivery": {
        "bsonType": "date"
      },
      "created_at": {
        "bsonType": "date"
      },
      "PARTITION": {
        "bsonType": "string"
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
    "required": [],
    "properties": {
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
      "vin": {
        "bsonType": "string"
      },
      "license_plate": {
        "bsonType": "string"
      },
      "registration_state": {
        "bsonType": "string"
      },
      "ownership_type": {
        "bsonType": "string"
      },
      "capacity_kg": {
        "bsonType": "decimal128"
      },
      "capacity_cbm": {
        "bsonType": "decimal128"
      },
      "fuel_type": {
        "bsonType": "string"
      },
      "fuel_efficiency_km_per_liter": {
        "bsonType": "decimal128"
      },
      "current_odometer_km": {
        "bsonType": "number"
      },
      "last_service_date": {
        "bsonType": "date"
      },
      "next_service_date": {
        "bsonType": "date"
      },
      "insurance_policy_number": {
        "bsonType": "string"
      },
      "insurance_expiry_date": {
        "bsonType": "date"
      },
      "current_location_lat": {
        "bsonType": "decimal128"
      },
      "current_location_lng": {
        "bsonType": "decimal128"
      },
      "current_status": {
        "bsonType": "string"
      },
      "assigned_driver_id": {
        "bsonType": "number"
      },
      "home_warehouse_id": {
        "bsonType": "number"
      },
      "is_active": {
        "bsonType": "boolean"
      },
      "telematics_device_id": {
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
      "license_number"
    ],
    "properties": {
      "first_name": {
        "bsonType": "string"
      },
      "last_name": {
        "bsonType": "string"
      },
      "license_number": {
        "bsonType": "string"
      },
      "license_class": {
        "bsonType": "string"
      },
      "license_expiry_date": {
        "bsonType": "date"
      },
      "license_state": {
        "bsonType": "string"
      },
      "phone_number": {
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
      "hire_date": {
        "bsonType": "date"
      },
      "home_base_warehouse_id": {
        "bsonType": "number"
      },
      "current_vehicle_id": {
        "bsonType": "number"
      },
      "hours_of_service_remaining": {
        "bsonType": "decimal128"
      },
      "last_drug_test_date": {
        "bsonType": "date"
      },
      "medical_certificate_expiry": {
        "bsonType": "date"
      },
      "safety_score": {
        "bsonType": "decimal128"
      },
      "total_miles_driven": {
        "bsonType": "number"
      },
      "total_deliveries": {
        "bsonType": "number"
      },
      "status": {
        "bsonType": "string"
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

// Validation for routes
db.runCommand({
  collMod: 'routes',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "origin_warehouse_id"
    ],
    "properties": {
      "route_name": {
        "bsonType": "string"
      },
      "route_type": {
        "bsonType": "string"
      },
      "origin_warehouse_id": {
        "bsonType": "number"
      },
      "destination_warehouse_id": {
        "bsonType": "number"
      },
      "total_distance_km": {
        "bsonType": "decimal128"
      },
      "estimated_duration_hours": {
        "bsonType": "decimal128"
      },
      "stops": {
        "bsonType": "object"
      },
      "preferred_departure_time": {
        "bsonType": "string"
      },
      "service_days": {
        "bsonType": "array"
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

// Validation for delivery_runs
db.runCommand({
  collMod: 'delivery_runs',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "run_date",
      "vehicle_id",
      "driver_id"
    ],
    "properties": {
      "run_date": {
        "bsonType": "date"
      },
      "route_id": {
        "bsonType": "number"
      },
      "vehicle_id": {
        "bsonType": "number"
      },
      "driver_id": {
        "bsonType": "number"
      },
      "planned_start_time": {
        "bsonType": "date"
      },
      "actual_start_time": {
        "bsonType": "date"
      },
      "planned_end_time": {
        "bsonType": "date"
      },
      "actual_end_time": {
        "bsonType": "date"
      },
      "total_stops": {
        "bsonType": "number"
      },
      "completed_stops": {
        "bsonType": "number"
      },
      "total_packages": {
        "bsonType": "number"
      },
      "delivered_packages": {
        "bsonType": "number"
      },
      "total_distance_km": {
        "bsonType": "decimal128"
      },
      "fuel_consumed_liters": {
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

// Validation for kpi_metrics
db.runCommand({
  collMod: 'kpi_metrics',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "metric_date"
    ],
    "properties": {
      "metric_date": {
        "bsonType": "date"
      },
      "metric_type": {
        "bsonType": "string"
      },
      "warehouse_id": {
        "bsonType": "number"
      },
      "inventory_turnover_ratio": {
        "bsonType": "decimal128"
      },
      "stockout_incidents": {
        "bsonType": "number"
      },
      "inventory_accuracy_percent": {
        "bsonType": "decimal128"
      },
      "carrying_cost": {
        "bsonType": "decimal128"
      },
      "orders_processed": {
        "bsonType": "number"
      },
      "perfect_order_rate": {
        "bsonType": "decimal128"
      },
      "order_cycle_time_hours": {
        "bsonType": "decimal128"
      },
      "fill_rate_percent": {
        "bsonType": "decimal128"
      },
      "backorder_rate_percent": {
        "bsonType": "decimal128"
      },
      "warehouse_utilization_percent": {
        "bsonType": "decimal128"
      },
      "picking_accuracy_percent": {
        "bsonType": "decimal128"
      },
      "putaway_cycle_time_minutes": {
        "bsonType": "decimal128"
      },
      "labor_productivity_units_per_hour": {
        "bsonType": "decimal128"
      },
      "on_time_delivery_percent": {
        "bsonType": "decimal128"
      },
      "freight_cost_per_unit": {
        "bsonType": "decimal128"
      },
      "delivery_success_rate": {
        "bsonType": "decimal128"
      },
      "average_delivery_time_hours": {
        "bsonType": "decimal128"
      },
      "fuel_efficiency_km_per_liter": {
        "bsonType": "decimal128"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for audit_log
db.runCommand({
  collMod: 'audit_log',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "table_name",
      "record_id"
    ],
    "properties": {
      "table_name": {
        "bsonType": "string"
      },
      "record_id": {
        "bsonType": "number"
      },
      "action": {
        "bsonType": "string"
      },
      "changed_by": {
        "bsonType": "number"
      },
      "changed_at": {
        "bsonType": "date"
      },
      "old_values": {
        "bsonType": "object"
      },
      "new_values": {
        "bsonType": "object"
      },
      "ip_address": {
        "bsonType": "string"
      },
      "user_agent": {
        "bsonType": "string"
      },
      "PARTITION": {
        "bsonType": "string"
      }
    }
  }
}
});
