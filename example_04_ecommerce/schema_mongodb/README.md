# MongoDB Schema for example_04_ecommerce

Converted from MySQL on 2026-02-17T23:16:48.704087

## Collections

### customers

**Document Structure:**
```json
{
  "password_hash": {
    "type": "String",
    "required": true
  },
  "first_name": {
    "type": "String",
    "required": false
  },
  "last_name": {
    "type": "String",
    "required": false
  },
  "phone": {
    "type": "String",
    "required": false
  },
  "date_of_birth": {
    "type": "Date",
    "required": false
  },
  "gender": {
    "type": "String",
    "required": false
  },
  "customer_type": {
    "type": "String",
    "required": false
  },
  "email_verified": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "phone_verified": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "two_factor_enabled": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "preferred_language": {
    "type": "String",
    "required": false,
    "default": "en"
  },
  "preferred_currency": {
    "type": "String",
    "required": false,
    "default": "USD"
  },
  "referred_by": {
    "type": "Number",
    "required": false
  },
  "loyalty_points": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "lifetime_value": {
    "type": "Decimal128",
    "required": false
  },
  "status": {
    "type": "String",
    "required": false
  },
  "last_login_at": {
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

### customer_addresses

**Document Structure:**
```json
{
  "customer_id": {
    "type": "Number",
    "required": true
  },
  "address_type": {
    "type": "String",
    "required": false
  },
  "is_default": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "recipient_name": {
    "type": "String",
    "required": false
  },
  "company_name": {
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
  "phone": {
    "type": "String",
    "required": false
  },
  "delivery_instructions": {
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
  "validated": {
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

### categories

**Document Structure:**
```json
{
  "parent_category_id": {
    "type": "Number",
    "required": false
  },
  "category_name": {
    "type": "String",
    "required": true
  },
  "description": {
    "type": "String",
    "required": false
  },
  "image_url": {
    "type": "String",
    "required": false
  },
  "meta_title": {
    "type": "String",
    "required": false
  },
  "meta_description": {
    "type": "String",
    "required": false
  },
  "display_order": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "is_active": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "product_count": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "path": {
    "type": "String",
    "required": false
  },
  "level": {
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

### brands

**Document Structure:**
```json
{
  "brand_name": {
    "type": "String",
    "required": true
  },
  "logo_url": {
    "type": "String",
    "required": false
  },
  "website_url": {
    "type": "String",
    "required": false
  },
  "description": {
    "type": "String",
    "required": false
  },
  "country_of_origin": {
    "type": "String",
    "required": false
  },
  "is_featured": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
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

### products

**Document Structure:**
```json
{
  "product_name": {
    "type": "String",
    "required": true
  },
  "brand_id": {
    "type": "Number",
    "required": false
  },
  "category_id": {
    "type": "Number",
    "required": true
  },
  "description": {
    "type": "String",
    "required": false
  },
  "short_description": {
    "type": "String",
    "required": false
  },
  "features": {
    "type": "Object",
    "required": false
  },
  "specifications": {
    "type": "Object",
    "required": false
  },
  "base_price": {
    "type": "Decimal128",
    "required": false
  },
  "compare_at_price": {
    "type": "Decimal128",
    "required": false
  },
  "cost": {
    "type": "Decimal128",
    "required": false
  },
  "tax_class": {
    "type": "String",
    "required": false
  },
  "weight_kg": {
    "type": "Decimal128",
    "required": false
  },
  "dimensions_cm": {
    "type": "Object",
    "required": false
  },
  "is_digital": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "is_featured": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "is_new": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "requires_shipping": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "max_quantity_per_order": {
    "type": "Number",
    "required": false
  },
  "min_quantity_per_order": {
    "type": "Number",
    "required": false,
    "default": "1"
  },
  "status": {
    "type": "String",
    "required": false
  },
  "launch_date": {
    "type": "Date",
    "required": false
  },
  "discontinue_date": {
    "type": "Date",
    "required": false
  },
  "view_count": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "sold_count": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "average_rating": {
    "type": "Decimal128",
    "required": false
  },
  "review_count": {
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
  },
  "FULLTEXT": {
    "type": "String",
    "required": false
  }
}
```

### product_variants

**Document Structure:**
```json
{
  "product_id": {
    "type": "Number",
    "required": true
  },
  "variant_name": {
    "type": "String",
    "required": false
  },
  "attributes": {
    "type": "Object",
    "required": true
  },
  "price": {
    "type": "Decimal128",
    "required": false
  },
  "compare_at_price": {
    "type": "Decimal128",
    "required": false
  },
  "cost": {
    "type": "Decimal128",
    "required": false
  },
  "weight_kg": {
    "type": "Decimal128",
    "required": false
  },
  "barcode": {
    "type": "String",
    "required": false
  },
  "image_url": {
    "type": "String",
    "required": false
  },
  "position": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "is_default": {
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

### product_images

**Document Structure:**
```json
{
  "product_id": {
    "type": "Number",
    "required": true
  },
  "variant_id": {
    "type": "Number",
    "required": false
  },
  "image_url": {
    "type": "String",
    "required": true
  },
  "thumbnail_url": {
    "type": "String",
    "required": false
  },
  "alt_text": {
    "type": "String",
    "required": false
  },
  "position": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "is_primary": {
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

### warehouses

**Document Structure:**
```json
{
  "warehouse_name": {
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
  "phone": {
    "type": "String",
    "required": false
  },
  "email": {
    "type": "String",
    "required": false
  },
  "manager_name": {
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
  "is_active": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "is_default": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "fulfills_online_orders": {
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

### inventory

**Document Structure:**
```json
{
  "product_id": {
    "type": "Number",
    "required": true
  },
  "variant_id": {
    "type": "Number",
    "required": false
  },
  "warehouse_id": {
    "type": "Number",
    "required": true
  },
  "quantity_available": {
    "type": "Number",
    "required": true,
    "default": "0"
  },
  "quantity_reserved": {
    "type": "Number",
    "required": true,
    "default": "0"
  },
  "quantity_incoming": {
    "type": "Number",
    "required": true,
    "default": "0"
  },
  "reorder_point": {
    "type": "Number",
    "required": false
  },
  "reorder_quantity": {
    "type": "Number",
    "required": false
  },
  "last_restock_date": {
    "type": "Date",
    "required": false
  },
  "last_sale_date": {
    "type": "Date",
    "required": false
  },
  "last_counted_date": {
    "type": "Date",
    "required": false
  },
  "average_daily_sales": {
    "type": "Decimal128",
    "required": false
  },
  "days_of_stock": {
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

### inventory_movements

**Document Structure:**
```json
{
  "inventory_id": {
    "type": "Number",
    "required": true
  },
  "movement_type": {
    "type": "String",
    "required": false
  },
  "quantity": {
    "type": "Number",
    "required": true
  },
  "reference_type": {
    "type": "String",
    "required": false
  },
  "reference_id": {
    "type": "Number",
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
  "unit_cost": {
    "type": "Decimal128",
    "required": false
  },
  "notes": {
    "type": "String",
    "required": false
  },
  "performed_by": {
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

### cart_items

**Document Structure:**
```json
{
  "customer_id": {
    "type": "Number",
    "required": true
  },
  "product_id": {
    "type": "Number",
    "required": true
  },
  "variant_id": {
    "type": "Number",
    "required": false
  },
  "quantity": {
    "type": "Number",
    "required": true,
    "default": "1"
  },
  "price_at_time": {
    "type": "Decimal128",
    "required": false
  },
  "discount_amount": {
    "type": "Decimal128",
    "required": false
  },
  "saved_for_later": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "added_at": {
    "type": "Date",
    "required": false,
    "default": "CURRENT_TIMESTAMP"
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

### wishlist_items

**Document Structure:**
```json
{
  "customer_id": {
    "type": "Number",
    "required": true
  },
  "product_id": {
    "type": "Number",
    "required": true
  },
  "variant_id": {
    "type": "Number",
    "required": false
  },
  "priority": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "notes": {
    "type": "String",
    "required": false
  },
  "price_when_added": {
    "type": "Decimal128",
    "required": false
  },
  "notify_on_sale": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "notify_on_restock": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "added_at": {
    "type": "Date",
    "required": false,
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

### orders

**Document Structure:**
```json
{
  "customer_id": {
    "type": "Number",
    "required": false
  },
  "guest_email": {
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
  "subtotal": {
    "type": "Decimal128",
    "required": false
  },
  "tax_amount": {
    "type": "Decimal128",
    "required": false
  },
  "shipping_amount": {
    "type": "Decimal128",
    "required": false
  },
  "discount_amount": {
    "type": "Decimal128",
    "required": false
  },
  "total_amount": {
    "type": "Decimal128",
    "required": false
  },
  "currency_code": {
    "type": "String",
    "required": false,
    "default": "USD"
  },
  "exchange_rate": {
    "type": "Decimal128",
    "required": false
  },
  "shipping_address_id": {
    "type": "Number",
    "required": false
  },
  "billing_address_id": {
    "type": "Number",
    "required": false
  },
  "shipping_method": {
    "type": "String",
    "required": false
  },
  "tracking_number": {
    "type": "String",
    "required": false
  },
  "notes": {
    "type": "String",
    "required": false
  },
  "internal_notes": {
    "type": "String",
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
  "referred_from": {
    "type": "String",
    "required": false
  },
  "coupon_code": {
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
  },
  "confirmed_at": {
    "type": "Date",
    "required": false
  },
  "shipped_at": {
    "type": "Date",
    "required": false
  },
  "delivered_at": {
    "type": "Date",
    "required": false
  },
  "cancelled_at": {
    "type": "Date",
    "required": false
  }
}
```

### order_items

**Document Structure:**
```json
{
  "order_id": {
    "type": "Number",
    "required": true
  },
  "product_id": {
    "type": "Number",
    "required": true
  },
  "variant_id": {
    "type": "Number",
    "required": false
  },
  "product_name": {
    "type": "String",
    "required": true
  },
  "variant_name": {
    "type": "String",
    "required": false
  },
  "sku": {
    "type": "String",
    "required": false
  },
  "quantity": {
    "type": "Number",
    "required": true
  },
  "unit_price": {
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
  "total_price": {
    "type": "Decimal128",
    "required": false
  },
  "cost": {
    "type": "Decimal128",
    "required": false
  },
  "weight_kg": {
    "type": "Decimal128",
    "required": false
  },
  "requires_shipping": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "is_gift": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "gift_message": {
    "type": "String",
    "required": false
  },
  "fulfillment_status": {
    "type": "String",
    "required": false
  },
  "fulfilled_quantity": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "warehouse_id": {
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

### order_status_history

**Document Structure:**
```json
{
  "order_id": {
    "type": "Number",
    "required": true
  },
  "status": {
    "type": "String",
    "required": false
  },
  "notes": {
    "type": "String",
    "required": false
  },
  "changed_by": {
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

### payment_methods

**Document Structure:**
```json
{
  "customer_id": {
    "type": "Number",
    "required": true
  },
  "type": {
    "type": "String",
    "required": false
  },
  "provider": {
    "type": "String",
    "required": false
  },
  "is_default": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "card_brand": {
    "type": "String",
    "required": false
  },
  "card_last_four": {
    "type": "String",
    "required": false
  },
  "card_exp_month": {
    "type": "Number",
    "required": false
  },
  "card_exp_year": {
    "type": "Number",
    "required": false
  },
  "billing_address_id": {
    "type": "Number",
    "required": false
  },
  "token": {
    "type": "String",
    "required": false
  },
  "fingerprint": {
    "type": "String",
    "required": false
  },
  "metadata": {
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

### payment_transactions

**Document Structure:**
```json
{
  "order_id": {
    "type": "Number",
    "required": true
  },
  "payment_method_id": {
    "type": "Number",
    "required": false
  },
  "transaction_type": {
    "type": "String",
    "required": false
  },
  "amount": {
    "type": "Decimal128",
    "required": false
  },
  "currency_code": {
    "type": "String",
    "required": false,
    "default": "USD"
  },
  "status": {
    "type": "String",
    "required": false
  },
  "gateway": {
    "type": "String",
    "required": false
  },
  "gateway_transaction_id": {
    "type": "String",
    "required": false
  },
  "gateway_response": {
    "type": "Object",
    "required": false
  },
  "failure_reason": {
    "type": "String",
    "required": false
  },
  "processed_at": {
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

### shipping_methods

**Document Structure:**
```json
{
  "carrier_name": {
    "type": "String",
    "required": true
  },
  "service_name": {
    "type": "String",
    "required": true
  },
  "delivery_days_min": {
    "type": "Number",
    "required": false
  },
  "delivery_days_max": {
    "type": "Number",
    "required": false
  },
  "base_rate": {
    "type": "Decimal128",
    "required": false
  },
  "per_kg_rate": {
    "type": "Decimal128",
    "required": false
  },
  "per_item_rate": {
    "type": "Decimal128",
    "required": false
  },
  "free_shipping_threshold": {
    "type": "Decimal128",
    "required": false
  },
  "max_weight_kg": {
    "type": "Decimal128",
    "required": false
  },
  "countries": {
    "type": "Object",
    "required": false
  },
  "is_express": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
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

### shipments

**Document Structure:**
```json
{
  "order_id": {
    "type": "Number",
    "required": true
  },
  "warehouse_id": {
    "type": "Number",
    "required": false
  },
  "shipping_method_id": {
    "type": "Number",
    "required": true
  },
  "tracking_number": {
    "type": "String",
    "required": false
  },
  "carrier_name": {
    "type": "String",
    "required": false
  },
  "status": {
    "type": "String",
    "required": false
  },
  "weight_kg": {
    "type": "Decimal128",
    "required": false
  },
  "dimensions_cm": {
    "type": "Object",
    "required": false
  },
  "shipping_label_url": {
    "type": "String",
    "required": false
  },
  "shipped_at": {
    "type": "Date",
    "required": false
  },
  "delivered_at": {
    "type": "Date",
    "required": false
  },
  "delivery_signature": {
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

### product_reviews

**Document Structure:**
```json
{
  "product_id": {
    "type": "Number",
    "required": true
  },
  "variant_id": {
    "type": "Number",
    "required": false
  },
  "customer_id": {
    "type": "Number",
    "required": true
  },
  "order_item_id": {
    "type": "Number",
    "required": false
  },
  "rating": {
    "type": "Number",
    "required": true
  },
  "title": {
    "type": "String",
    "required": false
  },
  "review_text": {
    "type": "String",
    "required": false
  },
  "pros": {
    "type": "String",
    "required": false
  },
  "cons": {
    "type": "String",
    "required": false
  },
  "is_verified_purchase": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "is_featured": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "helpful_count": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "unhelpful_count": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "admin_reply": {
    "type": "String",
    "required": false
  },
  "admin_reply_at": {
    "type": "Date",
    "required": false
  },
  "status": {
    "type": "String",
    "required": false
  },
  "images": {
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

### review_votes

**Document Structure:**
```json
{
  "review_id": {
    "type": "Number",
    "required": true
  },
  "customer_id": {
    "type": "Number",
    "required": true
  },
  "is_helpful": {
    "type": "Boolean",
    "required": true
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

### coupons

**Document Structure:**
```json
{
  "description": {
    "type": "String",
    "required": false
  },
  "discount_type": {
    "type": "String",
    "required": false
  },
  "discount_value": {
    "type": "Decimal128",
    "required": false
  },
  "minimum_amount": {
    "type": "Decimal128",
    "required": false
  },
  "maximum_discount": {
    "type": "Decimal128",
    "required": false
  },
  "applicable_to": {
    "type": "String",
    "required": false
  },
  "applicable_ids": {
    "type": "Object",
    "required": false
  },
  "usage_limit": {
    "type": "Number",
    "required": false
  },
  "usage_limit_per_customer": {
    "type": "Number",
    "required": false
  },
  "usage_count": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "valid_from": {
    "type": "Date",
    "required": true
  },
  "valid_to": {
    "type": "Date",
    "required": true
  },
  "is_active": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "requires_account": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "stackable": {
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

### coupon_usage

**Document Structure:**
```json
{
  "coupon_id": {
    "type": "Number",
    "required": true
  },
  "customer_id": {
    "type": "Number",
    "required": false
  },
  "order_id": {
    "type": "Number",
    "required": true
  },
  "discount_amount": {
    "type": "Decimal128",
    "required": false
  },
  "used_at": {
    "type": "Date",
    "required": false,
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

### price_rules

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
  "priority": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "conditions": {
    "type": "Object",
    "required": false
  },
  "discount_type": {
    "type": "String",
    "required": false
  },
  "discount_value": {
    "type": "Decimal128",
    "required": false
  },
  "applicable_to": {
    "type": "String",
    "required": false
  },
  "applicable_ids": {
    "type": "Object",
    "required": false
  },
  "valid_from": {
    "type": "Date",
    "required": true
  },
  "valid_to": {
    "type": "Date",
    "required": true
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

### page_views

**Document Structure:**
```json
{
  "customer_id": {
    "type": "Number",
    "required": false
  },
  "session_id": {
    "type": "String",
    "required": false
  },
  "product_id": {
    "type": "Number",
    "required": false
  },
  "page_type": {
    "type": "String",
    "required": false
  },
  "page_url": {
    "type": "String",
    "required": false
  },
  "referrer_url": {
    "type": "String",
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
  "device_type": {
    "type": "String",
    "required": false
  },
  "duration_seconds": {
    "type": "Number",
    "required": false
  },
  "bounce": {
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

### search_queries

**Document Structure:**
```json
{
  "customer_id": {
    "type": "Number",
    "required": false
  },
  "session_id": {
    "type": "String",
    "required": false
  },
  "query_text": {
    "type": "String",
    "required": true
  },
  "results_count": {
    "type": "Number",
    "required": false
  },
  "clicked_position": {
    "type": "Number",
    "required": false
  },
  "clicked_product_id": {
    "type": "Number",
    "required": false
  },
  "device_type": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "FULLTEXT": {
    "type": "String",
    "required": false
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### recently_viewed

**Document Structure:**
```json
{
  "customer_id": {
    "type": "Number",
    "required": true
  },
  "product_id": {
    "type": "Number",
    "required": true
  },
  "viewed_at": {
    "type": "Date",
    "required": false,
    "default": "CURRENT_TIMESTAMP"
  },
  "view_count": {
    "type": "Number",
    "required": false,
    "default": "1"
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

### product_recommendations

**Document Structure:**
```json
{
  "customer_id": {
    "type": "Number",
    "required": false
  },
  "product_id": {
    "type": "Number",
    "required": true
  },
  "recommendation_type": {
    "type": "String",
    "required": false
  },
  "score": {
    "type": "Decimal128",
    "required": false
  },
  "reason": {
    "type": "String",
    "required": false
  },
  "expires_at": {
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

### support_tickets

**Document Structure:**
```json
{
  "customer_id": {
    "type": "Number",
    "required": true
  },
  "order_id": {
    "type": "Number",
    "required": false
  },
  "category": {
    "type": "String",
    "required": false
  },
  "priority": {
    "type": "String",
    "required": false
  },
  "status": {
    "type": "String",
    "required": false
  },
  "subject": {
    "type": "String",
    "required": true
  },
  "description": {
    "type": "String",
    "required": true
  },
  "resolution": {
    "type": "String",
    "required": false
  },
  "assigned_to": {
    "type": "Number",
    "required": false
  },
  "resolved_at": {
    "type": "Date",
    "required": false
  },
  "satisfaction_rating": {
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

### returns

**Document Structure:**
```json
{
  "order_id": {
    "type": "Number",
    "required": true
  },
  "customer_id": {
    "type": "Number",
    "required": true
  },
  "status": {
    "type": "String",
    "required": false
  },
  "reason": {
    "type": "String",
    "required": false
  },
  "reason_details": {
    "type": "String",
    "required": false
  },
  "return_shipping_method": {
    "type": "String",
    "required": false
  },
  "return_tracking_number": {
    "type": "String",
    "required": false
  },
  "refund_amount": {
    "type": "Decimal128",
    "required": false
  },
  "restocking_fee": {
    "type": "Decimal128",
    "required": false
  },
  "return_label_url": {
    "type": "String",
    "required": false
  },
  "received_condition": {
    "type": "String",
    "required": false
  },
  "inspection_notes": {
    "type": "String",
    "required": false
  },
  "requested_at": {
    "type": "Date",
    "required": false,
    "default": "CURRENT_TIMESTAMP"
  },
  "approved_at": {
    "type": "Date",
    "required": false
  },
  "received_at": {
    "type": "Date",
    "required": false
  },
  "refunded_at": {
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

### return_items

**Document Structure:**
```json
{
  "return_id": {
    "type": "Number",
    "required": true
  },
  "order_item_id": {
    "type": "Number",
    "required": true
  },
  "quantity": {
    "type": "Number",
    "required": true
  },
  "condition": {
    "type": "String",
    "required": false
  },
  "refund_amount": {
    "type": "Decimal128",
    "required": false
  },
  "replacement_sent": {
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

### email_templates

**Document Structure:**
```json
{
  "template_name": {
    "type": "String",
    "required": true
  },
  "subject": {
    "type": "String",
    "required": true
  },
  "html_content": {
    "type": "String",
    "required": true
  },
  "text_content": {
    "type": "String",
    "required": false
  },
  "variables": {
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

### email_queue

**Document Structure:**
```json
{
  "customer_id": {
    "type": "Number",
    "required": false
  },
  "to_email": {
    "type": "String",
    "required": true
  },
  "template_id": {
    "type": "Number",
    "required": false
  },
  "subject": {
    "type": "String",
    "required": false
  },
  "variables": {
    "type": "Object",
    "required": false
  },
  "priority": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "status": {
    "type": "String",
    "required": false
  },
  "attempts": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "sent_at": {
    "type": "Date",
    "required": false
  },
  "error_message": {
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

