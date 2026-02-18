# MongoDB Schema for example_13_event_ticketing

Converted from MySQL on 2026-02-17T23:16:48.800564

## Collections

### venues

**Document Structure:**
```json
{
  "venue_name": {
    "type": "String",
    "required": true
  },
  "venue_type": {
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
  "country": {
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
  "capacity": {
    "type": "Number",
    "required": true
  },
  "phone": {
    "type": "String",
    "required": false
  },
  "email": {
    "type": "String",
    "required": false
  },
  "website": {
    "type": "String",
    "required": false
  },
  "parking_info": {
    "type": "String",
    "required": false
  },
  "public_transport_info": {
    "type": "String",
    "required": false
  },
  "accessibility_info": {
    "type": "String",
    "required": false
  },
  "venue_rules": {
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

### venue_sections

**Document Structure:**
```json
{
  "venue_id": {
    "type": "Number",
    "required": true
  },
  "section_name": {
    "type": "String",
    "required": true
  },
  "section_type": {
    "type": "String",
    "required": false
  },
  "capacity": {
    "type": "Number",
    "required": true
  },
  "rows_count": {
    "type": "Number",
    "required": false
  },
  "default_price_tier": {
    "type": "String",
    "required": false
  },
  "entry_gate": {
    "type": "String",
    "required": false
  },
  "is_accessible": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "view_quality": {
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

**References:** venues_id

### venue_rows

**Document Structure:**
```json
{
  "section_id": {
    "type": "Number",
    "required": true
  },
  "row_number": {
    "type": "String",
    "required": true
  },
  "seats_count": {
    "type": "Number",
    "required": true
  },
  "is_accessible": {
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

**References:** venue_sections_id

### venue_seats

**Document Structure:**
```json
{
  "row_id": {
    "type": "Number",
    "required": true
  },
  "seat_number": {
    "type": "String",
    "required": true
  },
  "seat_type": {
    "type": "String",
    "required": false
  },
  "x_coordinate": {
    "type": "Number",
    "required": false
  },
  "y_coordinate": {
    "type": "Number",
    "required": false
  },
  "is_aisle": {
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

**References:** venue_rows_id

### event_categories

**Document Structure:**
```json
{
  "category_name": {
    "type": "String",
    "required": true
  },
  "parent_category_id": {
    "type": "Number",
    "required": false
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

**References:** event_categories_id

### performers

**Document Structure:**
```json
{
  "performer_name": {
    "type": "String",
    "required": true
  },
  "performer_type": {
    "type": "String",
    "required": false
  },
  "genre": {
    "type": "String",
    "required": false
  },
  "bio": {
    "type": "String",
    "required": false
  },
  "image_url": {
    "type": "String",
    "required": false
  },
  "website": {
    "type": "String",
    "required": false
  },
  "social_media": {
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

### events

**Document Structure:**
```json
{
  "event_name": {
    "type": "String",
    "required": true
  },
  "event_type": {
    "type": "String",
    "required": false
  },
  "category_id": {
    "type": "Number",
    "required": false
  },
  "description": {
    "type": "String",
    "required": false
  },
  "image_url": {
    "type": "String",
    "required": false
  },
  "banner_url": {
    "type": "String",
    "required": false
  },
  "age_restriction": {
    "type": "String",
    "required": false
  },
  "duration_minutes": {
    "type": "Number",
    "required": false
  },
  "organizer_name": {
    "type": "String",
    "required": false
  },
  "organizer_contact": {
    "type": "String",
    "required": false
  },
  "is_featured": {
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

**References:** event_categories_id

### performances

**Document Structure:**
```json
{
  "event_id": {
    "type": "Number",
    "required": true
  },
  "venue_id": {
    "type": "Number",
    "required": true
  },
  "performance_datetime": {
    "type": "Date",
    "required": true
  },
  "doors_open_datetime": {
    "type": "Date",
    "required": false
  },
  "performance_status": {
    "type": "String",
    "required": false
  },
  "total_capacity": {
    "type": "Number",
    "required": false
  },
  "available_capacity": {
    "type": "Number",
    "required": false
  },
  "min_ticket_price": {
    "type": "Decimal128",
    "required": false
  },
  "max_ticket_price": {
    "type": "Decimal128",
    "required": false
  },
  "sales_start_datetime": {
    "type": "Date",
    "required": false
  },
  "sales_end_datetime": {
    "type": "Date",
    "required": false
  },
  "is_general_admission": {
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

**References:** events_id, venues_id

### event_performers

**Document Structure:**
```json
{
  "event_id": {
    "type": "Number",
    "required": true
  },
  "performer_id": {
    "type": "Number",
    "required": true
  },
  "billing_order": {
    "type": "Number",
    "required": false,
    "default": "1"
  },
  "is_headliner": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "performance_fee": {
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

**References:** events_id, performers_id

### customers

**Document Structure:**
```json
{
  "email": {
    "type": "String",
    "required": true
  },
  "password_hash": {
    "type": "String",
    "required": false
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
  "is_active": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "last_login": {
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

### customer_preferences

**Document Structure:**
```json
{
  "customer_id": {
    "type": "Number",
    "required": true
  },
  "favorite_venues": {
    "type": "Object",
    "required": false
  },
  "favorite_performers": {
    "type": "Object",
    "required": false
  },
  "preferred_categories": {
    "type": "Object",
    "required": false
  },
  "notification_events": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "notification_offers": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "notification_reminders": {
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

**References:** customers_id

### loyalty_members

**Document Structure:**
```json
{
  "customer_id": {
    "type": "Number",
    "required": true
  },
  "membership_tier": {
    "type": "String",
    "required": false
  },
  "points_balance": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "lifetime_points": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "join_date": {
    "type": "Date",
    "required": true
  },
  "expiry_date": {
    "type": "Date",
    "required": false
  },
  "perks": {
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

**References:** customers_id

### price_tiers

**Document Structure:**
```json
{
  "performance_id": {
    "type": "Number",
    "required": true
  },
  "tier_name": {
    "type": "String",
    "required": true
  },
  "base_price": {
    "type": "Decimal128",
    "required": false
  },
  "service_fee": {
    "type": "Decimal128",
    "required": false
  },
  "facility_fee": {
    "type": "Decimal128",
    "required": false
  },
  "tax_rate": {
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

**References:** performances_id

### section_pricing

**Document Structure:**
```json
{
  "performance_id": {
    "type": "Number",
    "required": true
  },
  "section_id": {
    "type": "Number",
    "required": true
  },
  "price_tier_id": {
    "type": "Number",
    "required": true
  },
  "current_price": {
    "type": "Decimal128",
    "required": false
  },
  "original_price": {
    "type": "Decimal128",
    "required": false
  },
  "min_price": {
    "type": "Decimal128",
    "required": false
  },
  "max_price": {
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

**References:** performances_id, venue_sections_id, price_tiers_id

### promotional_codes

**Document Structure:**
```json
{
  "promo_code": {
    "type": "String",
    "required": true
  },
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
  "min_purchase_amount": {
    "type": "Decimal128",
    "required": false
  },
  "max_discount_amount": {
    "type": "Decimal128",
    "required": false
  },
  "valid_from": {
    "type": "Date",
    "required": true
  },
  "valid_until": {
    "type": "Date",
    "required": true
  },
  "usage_limit": {
    "type": "Number",
    "required": false
  },
  "usage_count": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "applicable_performances": {
    "type": "Object",
    "required": false
  },
  "applicable_sections": {
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

### bookings

**Document Structure:**
```json
{
  "booking_reference": {
    "type": "String",
    "required": true
  },
  "customer_id": {
    "type": "Number",
    "required": true
  },
  "performance_id": {
    "type": "Number",
    "required": true
  },
  "booking_status": {
    "type": "String",
    "required": false
  },
  "total_amount": {
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
  "service_fee_amount": {
    "type": "Decimal128",
    "required": false
  },
  "payment_method": {
    "type": "String",
    "required": false
  },
  "payment_status": {
    "type": "String",
    "required": false
  },
  "promo_code_used": {
    "type": "String",
    "required": false
  },
  "booking_datetime": {
    "type": "Date",
    "required": false,
    "default": "CURRENT_TIMESTAMP"
  },
  "confirmation_sent": {
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

**References:** customers_id, performances_id

### tickets

**Document Structure:**
```json
{
  "booking_id": {
    "type": "Number",
    "required": true
  },
  "seat_id": {
    "type": "Number",
    "required": false
  },
  "ticket_number": {
    "type": "String",
    "required": true
  },
  "ticket_status": {
    "type": "String",
    "required": false
  },
  "price_paid": {
    "type": "Decimal128",
    "required": false
  },
  "barcode": {
    "type": "String",
    "required": false
  },
  "qr_code": {
    "type": "String",
    "required": false
  },
  "issue_datetime": {
    "type": "Date",
    "required": false,
    "default": "CURRENT_TIMESTAMP"
  },
  "used_datetime": {
    "type": "Date",
    "required": false
  },
  "entry_gate": {
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

**References:** bookings_id, venue_seats_id

### ticket_holds

**Document Structure:**
```json
{
  "session_id": {
    "type": "String",
    "required": true
  },
  "customer_id": {
    "type": "Number",
    "required": false
  },
  "performance_id": {
    "type": "Number",
    "required": true
  },
  "seat_id": {
    "type": "Number",
    "required": true
  },
  "hold_expiry": {
    "type": "Date",
    "required": true
  },
  "is_released": {
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

**References:** customers_id, performances_id, venue_seats_id

### shopping_carts

**Document Structure:**
```json
{
  "session_id": {
    "type": "String",
    "required": true
  },
  "customer_id": {
    "type": "Number",
    "required": false
  },
  "performance_id": {
    "type": "Number",
    "required": true
  },
  "cart_status": {
    "type": "String",
    "required": false
  },
  "expiry_datetime": {
    "type": "Date",
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

**References:** customers_id, performances_id

### cart_items

**Document Structure:**
```json
{
  "cart_id": {
    "type": "Number",
    "required": true
  },
  "seat_id": {
    "type": "Number",
    "required": false
  },
  "price_tier_id": {
    "type": "Number",
    "required": true
  },
  "quantity": {
    "type": "Number",
    "required": false,
    "default": "1"
  },
  "unit_price": {
    "type": "Decimal128",
    "required": false
  },
  "service_fee": {
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

**References:** shopping_carts_id, venue_seats_id, price_tiers_id

### entry_scans

**Document Structure:**
```json
{
  "ticket_id": {
    "type": "Number",
    "required": true
  },
  "scan_datetime": {
    "type": "Date",
    "required": false,
    "default": "CURRENT_TIMESTAMP"
  },
  "entry_gate": {
    "type": "String",
    "required": false
  },
  "scanner_device_id": {
    "type": "String",
    "required": false
  },
  "scan_result": {
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

**References:** tickets_id

### fraud_attempts

**Document Structure:**
```json
{
  "attempt_type": {
    "type": "String",
    "required": false
  },
  "customer_id": {
    "type": "Number",
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
  "details": {
    "type": "Object",
    "required": false
  },
  "action_taken": {
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

**References:** customers_id

### resale_listings

**Document Structure:**
```json
{
  "ticket_id": {
    "type": "Number",
    "required": true
  },
  "seller_customer_id": {
    "type": "Number",
    "required": true
  },
  "listing_price": {
    "type": "Decimal128",
    "required": false
  },
  "min_price": {
    "type": "Decimal128",
    "required": false
  },
  "listing_status": {
    "type": "String",
    "required": false
  },
  "listed_datetime": {
    "type": "Date",
    "required": false,
    "default": "CURRENT_TIMESTAMP"
  },
  "sold_datetime": {
    "type": "Date",
    "required": false
  },
  "expiry_datetime": {
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

**References:** tickets_id, customers_id

### resale_transactions

**Document Structure:**
```json
{
  "listing_id": {
    "type": "Number",
    "required": true
  },
  "buyer_customer_id": {
    "type": "Number",
    "required": true
  },
  "sale_price": {
    "type": "Decimal128",
    "required": false
  },
  "platform_fee": {
    "type": "Decimal128",
    "required": false
  },
  "seller_payout": {
    "type": "Decimal128",
    "required": false
  },
  "transaction_status": {
    "type": "String",
    "required": false
  },
  "transaction_datetime": {
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

**References:** resale_listings_id, customers_id

### sales_metrics

**Document Structure:**
```json
{
  "performance_id": {
    "type": "Number",
    "required": true
  },
  "metric_date": {
    "type": "Date",
    "required": true
  },
  "tickets_sold": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "gross_revenue": {
    "type": "Decimal128",
    "required": false
  },
  "service_fees": {
    "type": "Decimal128",
    "required": false
  },
  "average_ticket_price": {
    "type": "Decimal128",
    "required": false
  },
  "conversion_rate": {
    "type": "Decimal128",
    "required": false
  },
  "cart_abandonment_rate": {
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

**References:** performances_id

### venue_utilization

**Document Structure:**
```json
{
  "venue_id": {
    "type": "Number",
    "required": true
  },
  "performance_id": {
    "type": "Number",
    "required": true
  },
  "total_capacity": {
    "type": "Number",
    "required": true
  },
  "tickets_sold": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "utilization_percentage": {
    "type": "Decimal128",
    "required": false
  },
  "revenue_per_seat": {
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

**References:** venues_id, performances_id

