// MongoDB Migration Script
// Generated: 2026-02-17T23:16:48.799137
// From MySQL to MongoDB

use converted_db;

// Create collection: venues
db.createCollection('venues');

// Create collection: venue_sections
db.createCollection('venue_sections');

// Create collection: venue_rows
db.createCollection('venue_rows');

// Create collection: venue_seats
db.createCollection('venue_seats');

// Create collection: event_categories
db.createCollection('event_categories');

// Create collection: performers
db.createCollection('performers');

// Create collection: events
db.createCollection('events');

// Create collection: performances
db.createCollection('performances');

// Create collection: event_performers
db.createCollection('event_performers');

// Create collection: customers
db.createCollection('customers');

// Create collection: customer_preferences
db.createCollection('customer_preferences');

// Create collection: loyalty_members
db.createCollection('loyalty_members');

// Create collection: price_tiers
db.createCollection('price_tiers');

// Create collection: section_pricing
db.createCollection('section_pricing');

// Create collection: promotional_codes
db.createCollection('promotional_codes');

// Create collection: bookings
db.createCollection('bookings');

// Create collection: tickets
db.createCollection('tickets');

// Create collection: ticket_holds
db.createCollection('ticket_holds');

// Create collection: shopping_carts
db.createCollection('shopping_carts');

// Create collection: cart_items
db.createCollection('cart_items');

// Create collection: entry_scans
db.createCollection('entry_scans');

// Create collection: fraud_attempts
db.createCollection('fraud_attempts');

// Create collection: resale_listings
db.createCollection('resale_listings');

// Create collection: resale_transactions
db.createCollection('resale_transactions');

// Create collection: sales_metrics
db.createCollection('sales_metrics');

// Create collection: venue_utilization
db.createCollection('venue_utilization');

// Indexes for venues
db.venues.createIndex({"parking_info": "text", "public_transport_info": "text", "accessibility_info": "text"}, {"name": "venues_text"});

// Indexes for venue_sections
db.venue_sections.createIndex({"venue_id": 1}, {"name": "venue_sections_venue_id_idx"});

// Indexes for venue_rows
db.venue_rows.createIndex({"section_id": 1}, {"name": "venue_rows_section_id_idx"});

// Indexes for venue_seats
db.venue_seats.createIndex({"row_id": 1}, {"name": "venue_seats_row_id_idx"});

// Indexes for event_categories
db.event_categories.createIndex({"parent_category_id": 1}, {"name": "event_categories_parent_category_id_idx"});
db.event_categories.createIndex({"description": "text"}, {"name": "event_categories_text"});

// Indexes for performers
db.performers.createIndex({"bio": "text"}, {"name": "performers_text"});

// Indexes for events
db.events.createIndex({"category_id": 1}, {"name": "events_category_id_idx"});
db.events.createIndex({"description": "text"}, {"name": "events_text"});

// Indexes for performances
db.performances.createIndex({"event_id": 1}, {"name": "performances_event_id_idx"});
db.performances.createIndex({"venue_id": 1}, {"name": "performances_venue_id_idx"});
db.performances.createIndex({"notes": "text"}, {"name": "performances_text"});

// Indexes for event_performers
db.event_performers.createIndex({"event_id": 1}, {"name": "event_performers_event_id_idx"});
db.event_performers.createIndex({"performer_id": 1}, {"name": "event_performers_performer_id_idx"});

// Indexes for customers

// Indexes for customer_preferences
db.customer_preferences.createIndex({"customer_id": 1}, {"name": "customer_preferences_customer_id_idx"});

// Indexes for loyalty_members
db.loyalty_members.createIndex({"customer_id": 1}, {"name": "loyalty_members_customer_id_idx"});

// Indexes for price_tiers
db.price_tiers.createIndex({"performance_id": 1}, {"name": "price_tiers_performance_id_idx"});

// Indexes for section_pricing
db.section_pricing.createIndex({"performance_id": 1}, {"name": "section_pricing_performance_id_idx"});
db.section_pricing.createIndex({"section_id": 1}, {"name": "section_pricing_section_id_idx"});
db.section_pricing.createIndex({"price_tier_id": 1}, {"name": "section_pricing_price_tier_id_idx"});

// Indexes for promotional_codes

// Indexes for bookings
db.bookings.createIndex({"customer_id": 1}, {"name": "bookings_customer_id_idx"});
db.bookings.createIndex({"performance_id": 1}, {"name": "bookings_performance_id_idx"});
db.bookings.createIndex({"notes": "text"}, {"name": "bookings_text"});

// Indexes for tickets
db.tickets.createIndex({"booking_id": 1}, {"name": "tickets_booking_id_idx"});
db.tickets.createIndex({"seat_id": 1}, {"name": "tickets_seat_id_idx"});

// Indexes for ticket_holds
db.ticket_holds.createIndex({"customer_id": 1}, {"name": "ticket_holds_customer_id_idx"});
db.ticket_holds.createIndex({"performance_id": 1}, {"name": "ticket_holds_performance_id_idx"});
db.ticket_holds.createIndex({"seat_id": 1}, {"name": "ticket_holds_seat_id_idx"});

// Indexes for shopping_carts
db.shopping_carts.createIndex({"customer_id": 1}, {"name": "shopping_carts_customer_id_idx"});
db.shopping_carts.createIndex({"performance_id": 1}, {"name": "shopping_carts_performance_id_idx"});

// Indexes for cart_items
db.cart_items.createIndex({"cart_id": 1}, {"name": "cart_items_cart_id_idx"});
db.cart_items.createIndex({"seat_id": 1}, {"name": "cart_items_seat_id_idx"});
db.cart_items.createIndex({"price_tier_id": 1}, {"name": "cart_items_price_tier_id_idx"});

// Indexes for entry_scans
db.entry_scans.createIndex({"ticket_id": 1}, {"name": "entry_scans_ticket_id_idx"});

// Indexes for fraud_attempts
db.fraud_attempts.createIndex({"customer_id": 1}, {"name": "fraud_attempts_customer_id_idx"});
db.fraud_attempts.createIndex({"user_agent": "text"}, {"name": "fraud_attempts_text"});

// Indexes for resale_listings
db.resale_listings.createIndex({"ticket_id": 1}, {"name": "resale_listings_ticket_id_idx"});
db.resale_listings.createIndex({"seller_customer_id": 1}, {"name": "resale_listings_seller_customer_id_idx"});

// Indexes for resale_transactions
db.resale_transactions.createIndex({"listing_id": 1}, {"name": "resale_transactions_listing_id_idx"});
db.resale_transactions.createIndex({"buyer_customer_id": 1}, {"name": "resale_transactions_buyer_customer_id_idx"});

// Indexes for sales_metrics
db.sales_metrics.createIndex({"performance_id": 1}, {"name": "sales_metrics_performance_id_idx"});

// Indexes for venue_utilization
db.venue_utilization.createIndex({"venue_id": 1}, {"name": "venue_utilization_venue_id_idx"});
db.venue_utilization.createIndex({"performance_id": 1}, {"name": "venue_utilization_performance_id_idx"});

// Validation for venues
db.runCommand({
  collMod: 'venues',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "venue_name",
      "address_line1",
      "city",
      "country",
      "capacity"
    ],
    "properties": {
      "venue_name": {
        "bsonType": "string"
      },
      "venue_type": {
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
      "country": {
        "bsonType": "string"
      },
      "latitude": {
        "bsonType": "decimal128"
      },
      "longitude": {
        "bsonType": "decimal128"
      },
      "capacity": {
        "bsonType": "number"
      },
      "phone": {
        "bsonType": "string"
      },
      "email": {
        "bsonType": "string"
      },
      "website": {
        "bsonType": "string"
      },
      "parking_info": {
        "bsonType": "string"
      },
      "public_transport_info": {
        "bsonType": "string"
      },
      "accessibility_info": {
        "bsonType": "string"
      },
      "venue_rules": {
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

// Validation for venue_sections
db.runCommand({
  collMod: 'venue_sections',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "venue_id",
      "section_name",
      "capacity"
    ],
    "properties": {
      "venue_id": {
        "bsonType": "number"
      },
      "section_name": {
        "bsonType": "string"
      },
      "section_type": {
        "bsonType": "string"
      },
      "capacity": {
        "bsonType": "number"
      },
      "rows_count": {
        "bsonType": "number"
      },
      "default_price_tier": {
        "bsonType": "string"
      },
      "entry_gate": {
        "bsonType": "string"
      },
      "is_accessible": {
        "bsonType": "boolean"
      },
      "view_quality": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for venue_rows
db.runCommand({
  collMod: 'venue_rows',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "section_id",
      "row_number",
      "seats_count"
    ],
    "properties": {
      "section_id": {
        "bsonType": "number"
      },
      "row_number": {
        "bsonType": "string"
      },
      "seats_count": {
        "bsonType": "number"
      },
      "is_accessible": {
        "bsonType": "boolean"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for venue_seats
db.runCommand({
  collMod: 'venue_seats',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "row_id",
      "seat_number"
    ],
    "properties": {
      "row_id": {
        "bsonType": "number"
      },
      "seat_number": {
        "bsonType": "string"
      },
      "seat_type": {
        "bsonType": "string"
      },
      "x_coordinate": {
        "bsonType": "number"
      },
      "y_coordinate": {
        "bsonType": "number"
      },
      "is_aisle": {
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

// Validation for event_categories
db.runCommand({
  collMod: 'event_categories',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "category_name"
    ],
    "properties": {
      "category_name": {
        "bsonType": "string"
      },
      "parent_category_id": {
        "bsonType": "number"
      },
      "description": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for performers
db.runCommand({
  collMod: 'performers',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "performer_name"
    ],
    "properties": {
      "performer_name": {
        "bsonType": "string"
      },
      "performer_type": {
        "bsonType": "string"
      },
      "genre": {
        "bsonType": "string"
      },
      "bio": {
        "bsonType": "string"
      },
      "image_url": {
        "bsonType": "string"
      },
      "website": {
        "bsonType": "string"
      },
      "social_media": {
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

// Validation for events
db.runCommand({
  collMod: 'events',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "event_name"
    ],
    "properties": {
      "event_name": {
        "bsonType": "string"
      },
      "event_type": {
        "bsonType": "string"
      },
      "category_id": {
        "bsonType": "number"
      },
      "description": {
        "bsonType": "string"
      },
      "image_url": {
        "bsonType": "string"
      },
      "banner_url": {
        "bsonType": "string"
      },
      "age_restriction": {
        "bsonType": "string"
      },
      "duration_minutes": {
        "bsonType": "number"
      },
      "organizer_name": {
        "bsonType": "string"
      },
      "organizer_contact": {
        "bsonType": "string"
      },
      "is_featured": {
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

// Validation for performances
db.runCommand({
  collMod: 'performances',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "event_id",
      "venue_id",
      "performance_datetime"
    ],
    "properties": {
      "event_id": {
        "bsonType": "number"
      },
      "venue_id": {
        "bsonType": "number"
      },
      "performance_datetime": {
        "bsonType": "date"
      },
      "doors_open_datetime": {
        "bsonType": "date"
      },
      "performance_status": {
        "bsonType": "string"
      },
      "total_capacity": {
        "bsonType": "number"
      },
      "available_capacity": {
        "bsonType": "number"
      },
      "min_ticket_price": {
        "bsonType": "decimal128"
      },
      "max_ticket_price": {
        "bsonType": "decimal128"
      },
      "sales_start_datetime": {
        "bsonType": "date"
      },
      "sales_end_datetime": {
        "bsonType": "date"
      },
      "is_general_admission": {
        "bsonType": "boolean"
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

// Validation for event_performers
db.runCommand({
  collMod: 'event_performers',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "event_id",
      "performer_id"
    ],
    "properties": {
      "event_id": {
        "bsonType": "number"
      },
      "performer_id": {
        "bsonType": "number"
      },
      "billing_order": {
        "bsonType": "number"
      },
      "is_headliner": {
        "bsonType": "boolean"
      },
      "performance_fee": {
        "bsonType": "decimal128"
      },
      "created_at": {
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
      "email"
    ],
    "properties": {
      "email": {
        "bsonType": "string"
      },
      "password_hash": {
        "bsonType": "string"
      },
      "first_name": {
        "bsonType": "string"
      },
      "last_name": {
        "bsonType": "string"
      },
      "phone": {
        "bsonType": "string"
      },
      "date_of_birth": {
        "bsonType": "date"
      },
      "gender": {
        "bsonType": "string"
      },
      "preferred_language": {
        "bsonType": "string"
      },
      "preferred_currency": {
        "bsonType": "string"
      },
      "email_verified": {
        "bsonType": "boolean"
      },
      "phone_verified": {
        "bsonType": "boolean"
      },
      "is_active": {
        "bsonType": "boolean"
      },
      "last_login": {
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

// Validation for customer_preferences
db.runCommand({
  collMod: 'customer_preferences',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "customer_id"
    ],
    "properties": {
      "customer_id": {
        "bsonType": "number"
      },
      "favorite_venues": {
        "bsonType": "object"
      },
      "favorite_performers": {
        "bsonType": "object"
      },
      "preferred_categories": {
        "bsonType": "object"
      },
      "notification_events": {
        "bsonType": "boolean"
      },
      "notification_offers": {
        "bsonType": "boolean"
      },
      "notification_reminders": {
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

// Validation for loyalty_members
db.runCommand({
  collMod: 'loyalty_members',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "customer_id",
      "join_date"
    ],
    "properties": {
      "customer_id": {
        "bsonType": "number"
      },
      "membership_tier": {
        "bsonType": "string"
      },
      "points_balance": {
        "bsonType": "number"
      },
      "lifetime_points": {
        "bsonType": "number"
      },
      "join_date": {
        "bsonType": "date"
      },
      "expiry_date": {
        "bsonType": "date"
      },
      "perks": {
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

// Validation for price_tiers
db.runCommand({
  collMod: 'price_tiers',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "performance_id",
      "tier_name"
    ],
    "properties": {
      "performance_id": {
        "bsonType": "number"
      },
      "tier_name": {
        "bsonType": "string"
      },
      "base_price": {
        "bsonType": "decimal128"
      },
      "service_fee": {
        "bsonType": "decimal128"
      },
      "facility_fee": {
        "bsonType": "decimal128"
      },
      "tax_rate": {
        "bsonType": "decimal128"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for section_pricing
db.runCommand({
  collMod: 'section_pricing',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "performance_id",
      "section_id",
      "price_tier_id"
    ],
    "properties": {
      "performance_id": {
        "bsonType": "number"
      },
      "section_id": {
        "bsonType": "number"
      },
      "price_tier_id": {
        "bsonType": "number"
      },
      "current_price": {
        "bsonType": "decimal128"
      },
      "original_price": {
        "bsonType": "decimal128"
      },
      "min_price": {
        "bsonType": "decimal128"
      },
      "max_price": {
        "bsonType": "decimal128"
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

// Validation for promotional_codes
db.runCommand({
  collMod: 'promotional_codes',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "promo_code",
      "valid_from",
      "valid_until"
    ],
    "properties": {
      "promo_code": {
        "bsonType": "string"
      },
      "description": {
        "bsonType": "string"
      },
      "discount_type": {
        "bsonType": "string"
      },
      "discount_value": {
        "bsonType": "decimal128"
      },
      "min_purchase_amount": {
        "bsonType": "decimal128"
      },
      "max_discount_amount": {
        "bsonType": "decimal128"
      },
      "valid_from": {
        "bsonType": "date"
      },
      "valid_until": {
        "bsonType": "date"
      },
      "usage_limit": {
        "bsonType": "number"
      },
      "usage_count": {
        "bsonType": "number"
      },
      "applicable_performances": {
        "bsonType": "object"
      },
      "applicable_sections": {
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

// Validation for bookings
db.runCommand({
  collMod: 'bookings',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "booking_reference",
      "customer_id",
      "performance_id"
    ],
    "properties": {
      "booking_reference": {
        "bsonType": "string"
      },
      "customer_id": {
        "bsonType": "number"
      },
      "performance_id": {
        "bsonType": "number"
      },
      "booking_status": {
        "bsonType": "string"
      },
      "total_amount": {
        "bsonType": "decimal128"
      },
      "discount_amount": {
        "bsonType": "decimal128"
      },
      "tax_amount": {
        "bsonType": "decimal128"
      },
      "service_fee_amount": {
        "bsonType": "decimal128"
      },
      "payment_method": {
        "bsonType": "string"
      },
      "payment_status": {
        "bsonType": "string"
      },
      "promo_code_used": {
        "bsonType": "string"
      },
      "booking_datetime": {
        "bsonType": "date"
      },
      "confirmation_sent": {
        "bsonType": "boolean"
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

// Validation for tickets
db.runCommand({
  collMod: 'tickets',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "booking_id",
      "ticket_number"
    ],
    "properties": {
      "booking_id": {
        "bsonType": "number"
      },
      "seat_id": {
        "bsonType": "number"
      },
      "ticket_number": {
        "bsonType": "string"
      },
      "ticket_status": {
        "bsonType": "string"
      },
      "price_paid": {
        "bsonType": "decimal128"
      },
      "barcode": {
        "bsonType": "string"
      },
      "qr_code": {
        "bsonType": "string"
      },
      "issue_datetime": {
        "bsonType": "date"
      },
      "used_datetime": {
        "bsonType": "date"
      },
      "entry_gate": {
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

// Validation for ticket_holds
db.runCommand({
  collMod: 'ticket_holds',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "session_id",
      "performance_id",
      "seat_id",
      "hold_expiry"
    ],
    "properties": {
      "session_id": {
        "bsonType": "string"
      },
      "customer_id": {
        "bsonType": "number"
      },
      "performance_id": {
        "bsonType": "number"
      },
      "seat_id": {
        "bsonType": "number"
      },
      "hold_expiry": {
        "bsonType": "date"
      },
      "is_released": {
        "bsonType": "boolean"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for shopping_carts
db.runCommand({
  collMod: 'shopping_carts',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "session_id",
      "performance_id",
      "expiry_datetime"
    ],
    "properties": {
      "session_id": {
        "bsonType": "string"
      },
      "customer_id": {
        "bsonType": "number"
      },
      "performance_id": {
        "bsonType": "number"
      },
      "cart_status": {
        "bsonType": "string"
      },
      "expiry_datetime": {
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

// Validation for cart_items
db.runCommand({
  collMod: 'cart_items',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "cart_id",
      "price_tier_id"
    ],
    "properties": {
      "cart_id": {
        "bsonType": "number"
      },
      "seat_id": {
        "bsonType": "number"
      },
      "price_tier_id": {
        "bsonType": "number"
      },
      "quantity": {
        "bsonType": "number"
      },
      "unit_price": {
        "bsonType": "decimal128"
      },
      "service_fee": {
        "bsonType": "decimal128"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for entry_scans
db.runCommand({
  collMod: 'entry_scans',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "ticket_id"
    ],
    "properties": {
      "ticket_id": {
        "bsonType": "number"
      },
      "scan_datetime": {
        "bsonType": "date"
      },
      "entry_gate": {
        "bsonType": "string"
      },
      "scanner_device_id": {
        "bsonType": "string"
      },
      "scan_result": {
        "bsonType": "string"
      },
      "notes": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for fraud_attempts
db.runCommand({
  collMod: 'fraud_attempts',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [],
    "properties": {
      "attempt_type": {
        "bsonType": "string"
      },
      "customer_id": {
        "bsonType": "number"
      },
      "ip_address": {
        "bsonType": "string"
      },
      "user_agent": {
        "bsonType": "string"
      },
      "details": {
        "bsonType": "object"
      },
      "action_taken": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for resale_listings
db.runCommand({
  collMod: 'resale_listings',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "ticket_id",
      "seller_customer_id"
    ],
    "properties": {
      "ticket_id": {
        "bsonType": "number"
      },
      "seller_customer_id": {
        "bsonType": "number"
      },
      "listing_price": {
        "bsonType": "decimal128"
      },
      "min_price": {
        "bsonType": "decimal128"
      },
      "listing_status": {
        "bsonType": "string"
      },
      "listed_datetime": {
        "bsonType": "date"
      },
      "sold_datetime": {
        "bsonType": "date"
      },
      "expiry_datetime": {
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

// Validation for resale_transactions
db.runCommand({
  collMod: 'resale_transactions',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "listing_id",
      "buyer_customer_id"
    ],
    "properties": {
      "listing_id": {
        "bsonType": "number"
      },
      "buyer_customer_id": {
        "bsonType": "number"
      },
      "sale_price": {
        "bsonType": "decimal128"
      },
      "platform_fee": {
        "bsonType": "decimal128"
      },
      "seller_payout": {
        "bsonType": "decimal128"
      },
      "transaction_status": {
        "bsonType": "string"
      },
      "transaction_datetime": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for sales_metrics
db.runCommand({
  collMod: 'sales_metrics',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "performance_id",
      "metric_date"
    ],
    "properties": {
      "performance_id": {
        "bsonType": "number"
      },
      "metric_date": {
        "bsonType": "date"
      },
      "tickets_sold": {
        "bsonType": "number"
      },
      "gross_revenue": {
        "bsonType": "decimal128"
      },
      "service_fees": {
        "bsonType": "decimal128"
      },
      "average_ticket_price": {
        "bsonType": "decimal128"
      },
      "conversion_rate": {
        "bsonType": "decimal128"
      },
      "cart_abandonment_rate": {
        "bsonType": "decimal128"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for venue_utilization
db.runCommand({
  collMod: 'venue_utilization',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "venue_id",
      "performance_id",
      "total_capacity"
    ],
    "properties": {
      "venue_id": {
        "bsonType": "number"
      },
      "performance_id": {
        "bsonType": "number"
      },
      "total_capacity": {
        "bsonType": "number"
      },
      "tickets_sold": {
        "bsonType": "number"
      },
      "utilization_percentage": {
        "bsonType": "decimal128"
      },
      "revenue_per_seat": {
        "bsonType": "decimal128"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});
