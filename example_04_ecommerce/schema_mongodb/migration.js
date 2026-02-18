// MongoDB Migration Script
// Generated: 2026-02-17T23:16:48.703158
// From MySQL to MongoDB

use converted_db;

// Create collection: customers
db.createCollection('customers');

// Create collection: customer_addresses
db.createCollection('customer_addresses');

// Create collection: categories
db.createCollection('categories');

// Create collection: brands
db.createCollection('brands');

// Create collection: products
db.createCollection('products');

// Create collection: product_variants
db.createCollection('product_variants');

// Create collection: product_images
db.createCollection('product_images');

// Create collection: warehouses
db.createCollection('warehouses');

// Create collection: inventory
db.createCollection('inventory');

// Create collection: inventory_movements
db.createCollection('inventory_movements');

// Create collection: cart_items
db.createCollection('cart_items');

// Create collection: wishlist_items
db.createCollection('wishlist_items');

// Create collection: orders
db.createCollection('orders');

// Create collection: order_items
db.createCollection('order_items');

// Create collection: order_status_history
db.createCollection('order_status_history');

// Create collection: payment_methods
db.createCollection('payment_methods');

// Create collection: payment_transactions
db.createCollection('payment_transactions');

// Create collection: shipping_methods
db.createCollection('shipping_methods');

// Create collection: shipments
db.createCollection('shipments');

// Create collection: product_reviews
db.createCollection('product_reviews');

// Create collection: review_votes
db.createCollection('review_votes');

// Create collection: coupons
db.createCollection('coupons');

// Create collection: coupon_usage
db.createCollection('coupon_usage');

// Create collection: price_rules
db.createCollection('price_rules');

// Create collection: page_views
db.createCollection('page_views');

// Create collection: search_queries
db.createCollection('search_queries');

// Create collection: recently_viewed
db.createCollection('recently_viewed');

// Create collection: product_recommendations
db.createCollection('product_recommendations');

// Create collection: support_tickets
db.createCollection('support_tickets');

// Create collection: returns
db.createCollection('returns');

// Create collection: return_items
db.createCollection('return_items');

// Create collection: email_templates
db.createCollection('email_templates');

// Create collection: email_queue
db.createCollection('email_queue');

// Indexes for customers

// Indexes for customer_addresses
db.customer_addresses.createIndex({"delivery_instructions": "text"}, {"name": "customer_addresses_text"});

// Indexes for categories
db.categories.createIndex({"description": "text", "meta_description": "text"}, {"name": "categories_text"});

// Indexes for brands
db.brands.createIndex({"description": "text"}, {"name": "brands_text"});

// Indexes for products
db.products.createIndex({"description": "text"}, {"name": "products_text"});

// Indexes for product_variants

// Indexes for warehouses

// Indexes for inventory

// Indexes for inventory_movements
db.inventory_movements.createIndex({"notes": "text"}, {"name": "inventory_movements_text"});

// Indexes for wishlist_items
db.wishlist_items.createIndex({"notes": "text"}, {"name": "wishlist_items_text"});

// Indexes for orders
db.orders.createIndex({"notes": "text", "internal_notes": "text", "user_agent": "text"}, {"name": "orders_text"});

// Indexes for order_items
db.order_items.createIndex({"gift_message": "text"}, {"name": "order_items_text"});

// Indexes for order_status_history
db.order_status_history.createIndex({"notes": "text"}, {"name": "order_status_history_text"});

// Indexes for shipping_methods

// Indexes for shipments
db.shipments.createIndex({"notes": "text"}, {"name": "shipments_text"});

// Indexes for product_reviews
db.product_reviews.createIndex({"review_text": "text", "pros": "text", "cons": "text"}, {"name": "product_reviews_text"});

// Indexes for review_votes

// Indexes for coupons
db.coupons.createIndex({"description": "text"}, {"name": "coupons_text"});

// Indexes for page_views
db.page_views.createIndex({"user_agent": "text"}, {"name": "page_views_text"});

// Indexes for recently_viewed

// Indexes for support_tickets
db.support_tickets.createIndex({"description": "text", "resolution": "text"}, {"name": "support_tickets_text"});

// Indexes for returns
db.returns.createIndex({"reason_details": "text", "inspection_notes": "text"}, {"name": "returns_text"});

// Indexes for return_items
db.return_items.createIndex({"notes": "text"}, {"name": "return_items_text"});

// Indexes for email_templates
db.email_templates.createIndex({"html_content": "text", "text_content": "text"}, {"name": "email_templates_text"});

// Indexes for email_queue
db.email_queue.createIndex({"error_message": "text"}, {"name": "email_queue_text"});

// Validation for customers
db.runCommand({
  collMod: 'customers',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "password_hash"
    ],
    "properties": {
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
      "customer_type": {
        "bsonType": "string"
      },
      "email_verified": {
        "bsonType": "boolean"
      },
      "phone_verified": {
        "bsonType": "boolean"
      },
      "two_factor_enabled": {
        "bsonType": "boolean"
      },
      "preferred_language": {
        "bsonType": "string"
      },
      "preferred_currency": {
        "bsonType": "string"
      },
      "referred_by": {
        "bsonType": "number"
      },
      "loyalty_points": {
        "bsonType": "number"
      },
      "lifetime_value": {
        "bsonType": "decimal128"
      },
      "status": {
        "bsonType": "string"
      },
      "last_login_at": {
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

// Validation for customer_addresses
db.runCommand({
  collMod: 'customer_addresses',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "customer_id",
      "address_line1",
      "city",
      "country_code"
    ],
    "properties": {
      "customer_id": {
        "bsonType": "number"
      },
      "address_type": {
        "bsonType": "string"
      },
      "is_default": {
        "bsonType": "boolean"
      },
      "recipient_name": {
        "bsonType": "string"
      },
      "company_name": {
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
      "phone": {
        "bsonType": "string"
      },
      "delivery_instructions": {
        "bsonType": "string"
      },
      "latitude": {
        "bsonType": "decimal128"
      },
      "longitude": {
        "bsonType": "decimal128"
      },
      "validated": {
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

// Validation for categories
db.runCommand({
  collMod: 'categories',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "category_name"
    ],
    "properties": {
      "parent_category_id": {
        "bsonType": "number"
      },
      "category_name": {
        "bsonType": "string"
      },
      "description": {
        "bsonType": "string"
      },
      "image_url": {
        "bsonType": "string"
      },
      "meta_title": {
        "bsonType": "string"
      },
      "meta_description": {
        "bsonType": "string"
      },
      "display_order": {
        "bsonType": "number"
      },
      "is_active": {
        "bsonType": "boolean"
      },
      "product_count": {
        "bsonType": "number"
      },
      "path": {
        "bsonType": "string"
      },
      "level": {
        "bsonType": "number"
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

// Validation for brands
db.runCommand({
  collMod: 'brands',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "brand_name"
    ],
    "properties": {
      "brand_name": {
        "bsonType": "string"
      },
      "logo_url": {
        "bsonType": "string"
      },
      "website_url": {
        "bsonType": "string"
      },
      "description": {
        "bsonType": "string"
      },
      "country_of_origin": {
        "bsonType": "string"
      },
      "is_featured": {
        "bsonType": "boolean"
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

// Validation for products
db.runCommand({
  collMod: 'products',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "product_name",
      "category_id"
    ],
    "properties": {
      "product_name": {
        "bsonType": "string"
      },
      "brand_id": {
        "bsonType": "number"
      },
      "category_id": {
        "bsonType": "number"
      },
      "description": {
        "bsonType": "string"
      },
      "short_description": {
        "bsonType": "string"
      },
      "features": {
        "bsonType": "object"
      },
      "specifications": {
        "bsonType": "object"
      },
      "base_price": {
        "bsonType": "decimal128"
      },
      "compare_at_price": {
        "bsonType": "decimal128"
      },
      "cost": {
        "bsonType": "decimal128"
      },
      "tax_class": {
        "bsonType": "string"
      },
      "weight_kg": {
        "bsonType": "decimal128"
      },
      "dimensions_cm": {
        "bsonType": "object"
      },
      "is_digital": {
        "bsonType": "boolean"
      },
      "is_featured": {
        "bsonType": "boolean"
      },
      "is_new": {
        "bsonType": "boolean"
      },
      "requires_shipping": {
        "bsonType": "boolean"
      },
      "max_quantity_per_order": {
        "bsonType": "number"
      },
      "min_quantity_per_order": {
        "bsonType": "number"
      },
      "status": {
        "bsonType": "string"
      },
      "launch_date": {
        "bsonType": "date"
      },
      "discontinue_date": {
        "bsonType": "date"
      },
      "view_count": {
        "bsonType": "number"
      },
      "sold_count": {
        "bsonType": "number"
      },
      "average_rating": {
        "bsonType": "decimal128"
      },
      "review_count": {
        "bsonType": "number"
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

// Validation for product_variants
db.runCommand({
  collMod: 'product_variants',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "product_id",
      "attributes"
    ],
    "properties": {
      "product_id": {
        "bsonType": "number"
      },
      "variant_name": {
        "bsonType": "string"
      },
      "attributes": {
        "bsonType": "object"
      },
      "price": {
        "bsonType": "decimal128"
      },
      "compare_at_price": {
        "bsonType": "decimal128"
      },
      "cost": {
        "bsonType": "decimal128"
      },
      "weight_kg": {
        "bsonType": "decimal128"
      },
      "barcode": {
        "bsonType": "string"
      },
      "image_url": {
        "bsonType": "string"
      },
      "position": {
        "bsonType": "number"
      },
      "is_default": {
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

// Validation for product_images
db.runCommand({
  collMod: 'product_images',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "product_id",
      "image_url"
    ],
    "properties": {
      "product_id": {
        "bsonType": "number"
      },
      "variant_id": {
        "bsonType": "number"
      },
      "image_url": {
        "bsonType": "string"
      },
      "thumbnail_url": {
        "bsonType": "string"
      },
      "alt_text": {
        "bsonType": "string"
      },
      "position": {
        "bsonType": "number"
      },
      "is_primary": {
        "bsonType": "boolean"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for warehouses
db.runCommand({
  collMod: 'warehouses',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "warehouse_name"
    ],
    "properties": {
      "warehouse_name": {
        "bsonType": "string"
      },
      "address": {
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
      "phone": {
        "bsonType": "string"
      },
      "email": {
        "bsonType": "string"
      },
      "manager_name": {
        "bsonType": "string"
      },
      "latitude": {
        "bsonType": "decimal128"
      },
      "longitude": {
        "bsonType": "decimal128"
      },
      "is_active": {
        "bsonType": "boolean"
      },
      "is_default": {
        "bsonType": "boolean"
      },
      "fulfills_online_orders": {
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

// Validation for inventory
db.runCommand({
  collMod: 'inventory',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "product_id",
      "warehouse_id",
      "quantity_available",
      "quantity_reserved",
      "quantity_incoming"
    ],
    "properties": {
      "product_id": {
        "bsonType": "number"
      },
      "variant_id": {
        "bsonType": "number"
      },
      "warehouse_id": {
        "bsonType": "number"
      },
      "quantity_available": {
        "bsonType": "number"
      },
      "quantity_reserved": {
        "bsonType": "number"
      },
      "quantity_incoming": {
        "bsonType": "number"
      },
      "reorder_point": {
        "bsonType": "number"
      },
      "reorder_quantity": {
        "bsonType": "number"
      },
      "last_restock_date": {
        "bsonType": "date"
      },
      "last_sale_date": {
        "bsonType": "date"
      },
      "last_counted_date": {
        "bsonType": "date"
      },
      "average_daily_sales": {
        "bsonType": "decimal128"
      },
      "days_of_stock": {
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

// Validation for inventory_movements
db.runCommand({
  collMod: 'inventory_movements',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "inventory_id",
      "quantity"
    ],
    "properties": {
      "inventory_id": {
        "bsonType": "number"
      },
      "movement_type": {
        "bsonType": "string"
      },
      "quantity": {
        "bsonType": "number"
      },
      "reference_type": {
        "bsonType": "string"
      },
      "reference_id": {
        "bsonType": "number"
      },
      "from_warehouse_id": {
        "bsonType": "number"
      },
      "to_warehouse_id": {
        "bsonType": "number"
      },
      "unit_cost": {
        "bsonType": "decimal128"
      },
      "notes": {
        "bsonType": "string"
      },
      "performed_by": {
        "bsonType": "number"
      },
      "created_at": {
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
      "customer_id",
      "product_id",
      "quantity"
    ],
    "properties": {
      "customer_id": {
        "bsonType": "number"
      },
      "product_id": {
        "bsonType": "number"
      },
      "variant_id": {
        "bsonType": "number"
      },
      "quantity": {
        "bsonType": "number"
      },
      "price_at_time": {
        "bsonType": "decimal128"
      },
      "discount_amount": {
        "bsonType": "decimal128"
      },
      "saved_for_later": {
        "bsonType": "boolean"
      },
      "added_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for wishlist_items
db.runCommand({
  collMod: 'wishlist_items',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "customer_id",
      "product_id"
    ],
    "properties": {
      "customer_id": {
        "bsonType": "number"
      },
      "product_id": {
        "bsonType": "number"
      },
      "variant_id": {
        "bsonType": "number"
      },
      "priority": {
        "bsonType": "number"
      },
      "notes": {
        "bsonType": "string"
      },
      "price_when_added": {
        "bsonType": "decimal128"
      },
      "notify_on_sale": {
        "bsonType": "boolean"
      },
      "notify_on_restock": {
        "bsonType": "boolean"
      },
      "added_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for orders
db.runCommand({
  collMod: 'orders',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [],
    "properties": {
      "customer_id": {
        "bsonType": "number"
      },
      "guest_email": {
        "bsonType": "string"
      },
      "status": {
        "bsonType": "string"
      },
      "payment_status": {
        "bsonType": "string"
      },
      "subtotal": {
        "bsonType": "decimal128"
      },
      "tax_amount": {
        "bsonType": "decimal128"
      },
      "shipping_amount": {
        "bsonType": "decimal128"
      },
      "discount_amount": {
        "bsonType": "decimal128"
      },
      "total_amount": {
        "bsonType": "decimal128"
      },
      "currency_code": {
        "bsonType": "string"
      },
      "exchange_rate": {
        "bsonType": "decimal128"
      },
      "shipping_address_id": {
        "bsonType": "number"
      },
      "billing_address_id": {
        "bsonType": "number"
      },
      "shipping_method": {
        "bsonType": "string"
      },
      "tracking_number": {
        "bsonType": "string"
      },
      "notes": {
        "bsonType": "string"
      },
      "internal_notes": {
        "bsonType": "string"
      },
      "ip_address": {
        "bsonType": "string"
      },
      "user_agent": {
        "bsonType": "string"
      },
      "referred_from": {
        "bsonType": "string"
      },
      "coupon_code": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      },
      "confirmed_at": {
        "bsonType": "date"
      },
      "shipped_at": {
        "bsonType": "date"
      },
      "delivered_at": {
        "bsonType": "date"
      },
      "cancelled_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for order_items
db.runCommand({
  collMod: 'order_items',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "order_id",
      "product_id",
      "product_name",
      "quantity"
    ],
    "properties": {
      "order_id": {
        "bsonType": "number"
      },
      "product_id": {
        "bsonType": "number"
      },
      "variant_id": {
        "bsonType": "number"
      },
      "product_name": {
        "bsonType": "string"
      },
      "variant_name": {
        "bsonType": "string"
      },
      "sku": {
        "bsonType": "string"
      },
      "quantity": {
        "bsonType": "number"
      },
      "unit_price": {
        "bsonType": "decimal128"
      },
      "discount_amount": {
        "bsonType": "decimal128"
      },
      "tax_amount": {
        "bsonType": "decimal128"
      },
      "total_price": {
        "bsonType": "decimal128"
      },
      "cost": {
        "bsonType": "decimal128"
      },
      "weight_kg": {
        "bsonType": "decimal128"
      },
      "requires_shipping": {
        "bsonType": "boolean"
      },
      "is_gift": {
        "bsonType": "boolean"
      },
      "gift_message": {
        "bsonType": "string"
      },
      "fulfillment_status": {
        "bsonType": "string"
      },
      "fulfilled_quantity": {
        "bsonType": "number"
      },
      "warehouse_id": {
        "bsonType": "number"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for order_status_history
db.runCommand({
  collMod: 'order_status_history',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "order_id"
    ],
    "properties": {
      "order_id": {
        "bsonType": "number"
      },
      "status": {
        "bsonType": "string"
      },
      "notes": {
        "bsonType": "string"
      },
      "changed_by": {
        "bsonType": "number"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for payment_methods
db.runCommand({
  collMod: 'payment_methods',
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
      "type": {
        "bsonType": "string"
      },
      "provider": {
        "bsonType": "string"
      },
      "is_default": {
        "bsonType": "boolean"
      },
      "card_brand": {
        "bsonType": "string"
      },
      "card_last_four": {
        "bsonType": "string"
      },
      "card_exp_month": {
        "bsonType": "number"
      },
      "card_exp_year": {
        "bsonType": "number"
      },
      "billing_address_id": {
        "bsonType": "number"
      },
      "token": {
        "bsonType": "string"
      },
      "fingerprint": {
        "bsonType": "string"
      },
      "metadata": {
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

// Validation for payment_transactions
db.runCommand({
  collMod: 'payment_transactions',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "order_id"
    ],
    "properties": {
      "order_id": {
        "bsonType": "number"
      },
      "payment_method_id": {
        "bsonType": "number"
      },
      "transaction_type": {
        "bsonType": "string"
      },
      "amount": {
        "bsonType": "decimal128"
      },
      "currency_code": {
        "bsonType": "string"
      },
      "status": {
        "bsonType": "string"
      },
      "gateway": {
        "bsonType": "string"
      },
      "gateway_transaction_id": {
        "bsonType": "string"
      },
      "gateway_response": {
        "bsonType": "object"
      },
      "failure_reason": {
        "bsonType": "string"
      },
      "processed_at": {
        "bsonType": "date"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for shipping_methods
db.runCommand({
  collMod: 'shipping_methods',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "carrier_name",
      "service_name"
    ],
    "properties": {
      "carrier_name": {
        "bsonType": "string"
      },
      "service_name": {
        "bsonType": "string"
      },
      "delivery_days_min": {
        "bsonType": "number"
      },
      "delivery_days_max": {
        "bsonType": "number"
      },
      "base_rate": {
        "bsonType": "decimal128"
      },
      "per_kg_rate": {
        "bsonType": "decimal128"
      },
      "per_item_rate": {
        "bsonType": "decimal128"
      },
      "free_shipping_threshold": {
        "bsonType": "decimal128"
      },
      "max_weight_kg": {
        "bsonType": "decimal128"
      },
      "countries": {
        "bsonType": "object"
      },
      "is_express": {
        "bsonType": "boolean"
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

// Validation for shipments
db.runCommand({
  collMod: 'shipments',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "order_id",
      "shipping_method_id"
    ],
    "properties": {
      "order_id": {
        "bsonType": "number"
      },
      "warehouse_id": {
        "bsonType": "number"
      },
      "shipping_method_id": {
        "bsonType": "number"
      },
      "tracking_number": {
        "bsonType": "string"
      },
      "carrier_name": {
        "bsonType": "string"
      },
      "status": {
        "bsonType": "string"
      },
      "weight_kg": {
        "bsonType": "decimal128"
      },
      "dimensions_cm": {
        "bsonType": "object"
      },
      "shipping_label_url": {
        "bsonType": "string"
      },
      "shipped_at": {
        "bsonType": "date"
      },
      "delivered_at": {
        "bsonType": "date"
      },
      "delivery_signature": {
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

// Validation for product_reviews
db.runCommand({
  collMod: 'product_reviews',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "product_id",
      "customer_id",
      "rating"
    ],
    "properties": {
      "product_id": {
        "bsonType": "number"
      },
      "variant_id": {
        "bsonType": "number"
      },
      "customer_id": {
        "bsonType": "number"
      },
      "order_item_id": {
        "bsonType": "number"
      },
      "rating": {
        "bsonType": "number"
      },
      "title": {
        "bsonType": "string"
      },
      "review_text": {
        "bsonType": "string"
      },
      "pros": {
        "bsonType": "string"
      },
      "cons": {
        "bsonType": "string"
      },
      "is_verified_purchase": {
        "bsonType": "boolean"
      },
      "is_featured": {
        "bsonType": "boolean"
      },
      "helpful_count": {
        "bsonType": "number"
      },
      "unhelpful_count": {
        "bsonType": "number"
      },
      "admin_reply": {
        "bsonType": "string"
      },
      "admin_reply_at": {
        "bsonType": "date"
      },
      "status": {
        "bsonType": "string"
      },
      "images": {
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

// Validation for review_votes
db.runCommand({
  collMod: 'review_votes',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "review_id",
      "customer_id",
      "is_helpful"
    ],
    "properties": {
      "review_id": {
        "bsonType": "number"
      },
      "customer_id": {
        "bsonType": "number"
      },
      "is_helpful": {
        "bsonType": "boolean"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for coupons
db.runCommand({
  collMod: 'coupons',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "valid_from",
      "valid_to"
    ],
    "properties": {
      "description": {
        "bsonType": "string"
      },
      "discount_type": {
        "bsonType": "string"
      },
      "discount_value": {
        "bsonType": "decimal128"
      },
      "minimum_amount": {
        "bsonType": "decimal128"
      },
      "maximum_discount": {
        "bsonType": "decimal128"
      },
      "applicable_to": {
        "bsonType": "string"
      },
      "applicable_ids": {
        "bsonType": "object"
      },
      "usage_limit": {
        "bsonType": "number"
      },
      "usage_limit_per_customer": {
        "bsonType": "number"
      },
      "usage_count": {
        "bsonType": "number"
      },
      "valid_from": {
        "bsonType": "date"
      },
      "valid_to": {
        "bsonType": "date"
      },
      "is_active": {
        "bsonType": "boolean"
      },
      "requires_account": {
        "bsonType": "boolean"
      },
      "stackable": {
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

// Validation for coupon_usage
db.runCommand({
  collMod: 'coupon_usage',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "coupon_id",
      "order_id"
    ],
    "properties": {
      "coupon_id": {
        "bsonType": "number"
      },
      "customer_id": {
        "bsonType": "number"
      },
      "order_id": {
        "bsonType": "number"
      },
      "discount_amount": {
        "bsonType": "decimal128"
      },
      "used_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for price_rules
db.runCommand({
  collMod: 'price_rules',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "rule_name",
      "valid_from",
      "valid_to"
    ],
    "properties": {
      "rule_name": {
        "bsonType": "string"
      },
      "rule_type": {
        "bsonType": "string"
      },
      "priority": {
        "bsonType": "number"
      },
      "conditions": {
        "bsonType": "object"
      },
      "discount_type": {
        "bsonType": "string"
      },
      "discount_value": {
        "bsonType": "decimal128"
      },
      "applicable_to": {
        "bsonType": "string"
      },
      "applicable_ids": {
        "bsonType": "object"
      },
      "valid_from": {
        "bsonType": "date"
      },
      "valid_to": {
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

// Validation for page_views
db.runCommand({
  collMod: 'page_views',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [],
    "properties": {
      "customer_id": {
        "bsonType": "number"
      },
      "session_id": {
        "bsonType": "string"
      },
      "product_id": {
        "bsonType": "number"
      },
      "page_type": {
        "bsonType": "string"
      },
      "page_url": {
        "bsonType": "string"
      },
      "referrer_url": {
        "bsonType": "string"
      },
      "ip_address": {
        "bsonType": "string"
      },
      "user_agent": {
        "bsonType": "string"
      },
      "device_type": {
        "bsonType": "string"
      },
      "duration_seconds": {
        "bsonType": "number"
      },
      "bounce": {
        "bsonType": "boolean"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for search_queries
db.runCommand({
  collMod: 'search_queries',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "query_text"
    ],
    "properties": {
      "customer_id": {
        "bsonType": "number"
      },
      "session_id": {
        "bsonType": "string"
      },
      "query_text": {
        "bsonType": "string"
      },
      "results_count": {
        "bsonType": "number"
      },
      "clicked_position": {
        "bsonType": "number"
      },
      "clicked_product_id": {
        "bsonType": "number"
      },
      "device_type": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      },
      "FULLTEXT": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for recently_viewed
db.runCommand({
  collMod: 'recently_viewed',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "customer_id",
      "product_id"
    ],
    "properties": {
      "customer_id": {
        "bsonType": "number"
      },
      "product_id": {
        "bsonType": "number"
      },
      "viewed_at": {
        "bsonType": "date"
      },
      "view_count": {
        "bsonType": "number"
      }
    }
  }
}
});

// Validation for product_recommendations
db.runCommand({
  collMod: 'product_recommendations',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "product_id"
    ],
    "properties": {
      "customer_id": {
        "bsonType": "number"
      },
      "product_id": {
        "bsonType": "number"
      },
      "recommendation_type": {
        "bsonType": "string"
      },
      "score": {
        "bsonType": "decimal128"
      },
      "reason": {
        "bsonType": "string"
      },
      "expires_at": {
        "bsonType": "date"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for support_tickets
db.runCommand({
  collMod: 'support_tickets',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "customer_id",
      "subject",
      "description"
    ],
    "properties": {
      "customer_id": {
        "bsonType": "number"
      },
      "order_id": {
        "bsonType": "number"
      },
      "category": {
        "bsonType": "string"
      },
      "priority": {
        "bsonType": "string"
      },
      "status": {
        "bsonType": "string"
      },
      "subject": {
        "bsonType": "string"
      },
      "description": {
        "bsonType": "string"
      },
      "resolution": {
        "bsonType": "string"
      },
      "assigned_to": {
        "bsonType": "number"
      },
      "resolved_at": {
        "bsonType": "date"
      },
      "satisfaction_rating": {
        "bsonType": "number"
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

// Validation for returns
db.runCommand({
  collMod: 'returns',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "order_id",
      "customer_id"
    ],
    "properties": {
      "order_id": {
        "bsonType": "number"
      },
      "customer_id": {
        "bsonType": "number"
      },
      "status": {
        "bsonType": "string"
      },
      "reason": {
        "bsonType": "string"
      },
      "reason_details": {
        "bsonType": "string"
      },
      "return_shipping_method": {
        "bsonType": "string"
      },
      "return_tracking_number": {
        "bsonType": "string"
      },
      "refund_amount": {
        "bsonType": "decimal128"
      },
      "restocking_fee": {
        "bsonType": "decimal128"
      },
      "return_label_url": {
        "bsonType": "string"
      },
      "received_condition": {
        "bsonType": "string"
      },
      "inspection_notes": {
        "bsonType": "string"
      },
      "requested_at": {
        "bsonType": "date"
      },
      "approved_at": {
        "bsonType": "date"
      },
      "received_at": {
        "bsonType": "date"
      },
      "refunded_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for return_items
db.runCommand({
  collMod: 'return_items',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "return_id",
      "order_item_id",
      "quantity"
    ],
    "properties": {
      "return_id": {
        "bsonType": "number"
      },
      "order_item_id": {
        "bsonType": "number"
      },
      "quantity": {
        "bsonType": "number"
      },
      "condition": {
        "bsonType": "string"
      },
      "refund_amount": {
        "bsonType": "decimal128"
      },
      "replacement_sent": {
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

// Validation for email_templates
db.runCommand({
  collMod: 'email_templates',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "template_name",
      "subject",
      "html_content"
    ],
    "properties": {
      "template_name": {
        "bsonType": "string"
      },
      "subject": {
        "bsonType": "string"
      },
      "html_content": {
        "bsonType": "string"
      },
      "text_content": {
        "bsonType": "string"
      },
      "variables": {
        "bsonType": "object"
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

// Validation for email_queue
db.runCommand({
  collMod: 'email_queue',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "to_email"
    ],
    "properties": {
      "customer_id": {
        "bsonType": "number"
      },
      "to_email": {
        "bsonType": "string"
      },
      "template_id": {
        "bsonType": "number"
      },
      "subject": {
        "bsonType": "string"
      },
      "variables": {
        "bsonType": "object"
      },
      "priority": {
        "bsonType": "number"
      },
      "status": {
        "bsonType": "string"
      },
      "attempts": {
        "bsonType": "number"
      },
      "sent_at": {
        "bsonType": "date"
      },
      "error_message": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});
