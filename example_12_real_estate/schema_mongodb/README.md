# MongoDB Schema for example_12_real_estate

Converted from MySQL on 2026-02-17T23:16:48.789516

## Collections

### countries

**Document Structure:**
```json
{
  "country_code": {
    "type": "String",
    "required": true
  },
  "country_name": {
    "type": "String",
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

### states_provinces

**Document Structure:**
```json
{
  "country_id": {
    "type": "Number",
    "required": true
  },
  "state_code": {
    "type": "String",
    "required": true
  },
  "state_name": {
    "type": "String",
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

**References:** countries_id

### cities

**Document Structure:**
```json
{
  "state_id": {
    "type": "Number",
    "required": true
  },
  "city_name": {
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
  "population": {
    "type": "Number",
    "required": false
  },
  "median_income": {
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

**References:** states_provinces_id

### zip_codes

**Document Structure:**
```json
{
  "city_id": {
    "type": "Number",
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
  "timezone": {
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

**References:** cities_id

### neighborhoods

**Document Structure:**
```json
{
  "city_id": {
    "type": "Number",
    "required": true
  },
  "neighborhood_name": {
    "type": "String",
    "required": true
  },
  "boundary_polygon": {
    "type": "String",
    "required": false
  },
  "center_point": {
    "type": "String",
    "required": false
  },
  "median_home_price": {
    "type": "Decimal128",
    "required": false
  },
  "median_rent": {
    "type": "Decimal128",
    "required": false
  },
  "walk_score": {
    "type": "Number",
    "required": false
  },
  "transit_score": {
    "type": "Number",
    "required": false
  },
  "crime_rate": {
    "type": "Decimal128",
    "required": false
  },
  "school_rating": {
    "type": "Decimal128",
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

**References:** cities_id

### property_types

**Document Structure:**
```json
{
  "parent_type_id": {
    "type": "Number",
    "required": false
  },
  "type_name": {
    "type": "String",
    "required": true
  },
  "type_category": {
    "type": "String",
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

**References:** property_types_id

### properties

**Document Structure:**
```json
{
  "property_type_id": {
    "type": "Number",
    "required": true
  },
  "address_line1": {
    "type": "String",
    "required": true
  },
  "address_line2": {
    "type": "String",
    "required": false
  },
  "city_id": {
    "type": "Number",
    "required": true
  },
  "state_id": {
    "type": "Number",
    "required": true
  },
  "zip_code": {
    "type": "String",
    "required": true
  },
  "neighborhood_id": {
    "type": "Number",
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
  "location_point": {
    "type": "String",
    "required": true
  },
  "parcel_number": {
    "type": "String",
    "required": false
  },
  "legal_description": {
    "type": "String",
    "required": false
  },
  "year_built": {
    "type": "Number",
    "required": false
  },
  "lot_size_sqft": {
    "type": "Number",
    "required": false
  },
  "building_size_sqft": {
    "type": "Number",
    "required": false
  },
  "bedrooms": {
    "type": "Number",
    "required": false
  },
  "bathrooms": {
    "type": "Decimal128",
    "required": false
  },
  "parking_spaces": {
    "type": "Number",
    "required": false
  },
  "garage_spaces": {
    "type": "Number",
    "required": false
  },
  "stories": {
    "type": "Number",
    "required": false
  },
  "construction_type": {
    "type": "String",
    "required": false
  },
  "roof_type": {
    "type": "String",
    "required": false
  },
  "heating_type": {
    "type": "String",
    "required": false
  },
  "cooling_type": {
    "type": "String",
    "required": false
  },
  "zoning": {
    "type": "String",
    "required": false
  },
  "hoa_fee": {
    "type": "Decimal128",
    "required": false
  },
  "tax_assessed_value": {
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

**References:** property_types_id, cities_id, states_provinces_id, neighborhoods_id

### property_features

**Document Structure:**
```json
{
  "property_id": {
    "type": "Number",
    "required": true
  },
  "feature_category": {
    "type": "String",
    "required": false
  },
  "feature_name": {
    "type": "String",
    "required": true
  },
  "feature_value": {
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

**References:** properties_id

### property_rooms

**Document Structure:**
```json
{
  "property_id": {
    "type": "Number",
    "required": true
  },
  "room_type": {
    "type": "String",
    "required": true
  },
  "room_level": {
    "type": "String",
    "required": false
  },
  "length_ft": {
    "type": "Decimal128",
    "required": false
  },
  "width_ft": {
    "type": "Decimal128",
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

**References:** properties_id

### brokerages

**Document Structure:**
```json
{
  "brokerage_name": {
    "type": "String",
    "required": true
  },
  "license_number": {
    "type": "String",
    "required": true
  },
  "address": {
    "type": "String",
    "required": false
  },
  "city_id": {
    "type": "Number",
    "required": false
  },
  "state_id": {
    "type": "Number",
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
  "website": {
    "type": "String",
    "required": false
  },
  "established_date": {
    "type": "Date",
    "required": false
  },
  "total_agents": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "active_listings": {
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

**References:** cities_id, states_provinces_id

### agents

**Document Structure:**
```json
{
  "brokerage_id": {
    "type": "Number",
    "required": false
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
    "required": false
  },
  "mobile_phone": {
    "type": "String",
    "required": false
  },
  "license_number": {
    "type": "String",
    "required": true
  },
  "license_state_id": {
    "type": "Number",
    "required": true
  },
  "license_expiry_date": {
    "type": "Date",
    "required": false
  },
  "specializations": {
    "type": "Object",
    "required": false
  },
  "bio": {
    "type": "String",
    "required": false
  },
  "profile_photo_url": {
    "type": "String",
    "required": false
  },
  "years_experience": {
    "type": "Number",
    "required": false
  },
  "total_sales_volume": {
    "type": "Decimal128",
    "required": false
  },
  "total_transactions": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "avg_days_on_market": {
    "type": "Number",
    "required": false
  },
  "rating": {
    "type": "Decimal128",
    "required": false
  },
  "is_active": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "joined_date": {
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

**References:** brokerages_id, states_provinces_id

### users

**Document Structure:**
```json
{
  "email": {
    "type": "String",
    "required": true
  },
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
  "user_type": {
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
  "profile_photo_url": {
    "type": "String",
    "required": false
  },
  "preferred_contact": {
    "type": "String",
    "required": false
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

### user_preferences

**Document Structure:**
```json
{
  "user_id": {
    "type": "Number",
    "required": true
  },
  "min_price": {
    "type": "Decimal128",
    "required": false
  },
  "max_price": {
    "type": "Decimal128",
    "required": false
  },
  "min_bedrooms": {
    "type": "Number",
    "required": false
  },
  "min_bathrooms": {
    "type": "Decimal128",
    "required": false
  },
  "min_sqft": {
    "type": "Number",
    "required": false
  },
  "max_sqft": {
    "type": "Number",
    "required": false
  },
  "property_types": {
    "type": "Object",
    "required": false
  },
  "preferred_cities": {
    "type": "Object",
    "required": false
  },
  "preferred_neighborhoods": {
    "type": "Object",
    "required": false
  },
  "must_have_features": {
    "type": "Object",
    "required": false
  },
  "nice_to_have_features": {
    "type": "Object",
    "required": false
  },
  "max_hoa_fee": {
    "type": "Decimal128",
    "required": false
  },
  "school_rating_min": {
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

**References:** users_id

### listings

**Document Structure:**
```json
{
  "property_id": {
    "type": "Number",
    "required": true
  },
  "listing_agent_id": {
    "type": "Number",
    "required": true
  },
  "co_listing_agent_id": {
    "type": "Number",
    "required": false
  },
  "listing_type": {
    "type": "String",
    "required": false
  },
  "status": {
    "type": "String",
    "required": false
  },
  "list_price": {
    "type": "Decimal128",
    "required": false
  },
  "original_price": {
    "type": "Decimal128",
    "required": false
  },
  "price_per_sqft": {
    "type": "Decimal128",
    "required": false
  },
  "listing_date": {
    "type": "Date",
    "required": true
  },
  "expiry_date": {
    "type": "Date",
    "required": false
  },
  "days_on_market": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "title": {
    "type": "String",
    "required": false
  },
  "description": {
    "type": "String",
    "required": false
  },
  "virtual_tour_url": {
    "type": "String",
    "required": false
  },
  "video_url": {
    "type": "String",
    "required": false
  },
  "commission_buyer_agent": {
    "type": "Decimal128",
    "required": false
  },
  "commission_listing_agent": {
    "type": "Decimal128",
    "required": false
  },
  "showing_instructions": {
    "type": "String",
    "required": false
  },
  "mls_number": {
    "type": "String",
    "required": false
  },
  "is_featured": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "view_count": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "inquiry_count": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "showing_count": {
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

**References:** properties_id, agents_id, agents_id

### listing_status_history

**Document Structure:**
```json
{
  "listing_id": {
    "type": "Number",
    "required": true
  },
  "status": {
    "type": "String",
    "required": false
  },
  "changed_date": {
    "type": "String",
    "required": false
  },
  "changed_by_user_id": {
    "type": "Number",
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

**References:** listings_id, users_id

### price_changes

**Document Structure:**
```json
{
  "listing_id": {
    "type": "Number",
    "required": true
  },
  "old_price": {
    "type": "Decimal128",
    "required": false
  },
  "new_price": {
    "type": "Decimal128",
    "required": false
  },
  "change_amount": {
    "type": "Decimal128",
    "required": false
  },
  "change_percentage": {
    "type": "Decimal128",
    "required": false
  },
  "change_date": {
    "type": "String",
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
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** listings_id

### property_photos

**Document Structure:**
```json
{
  "property_id": {
    "type": "Number",
    "required": true
  },
  "photo_url": {
    "type": "String",
    "required": true
  },
  "thumbnail_url": {
    "type": "String",
    "required": false
  },
  "caption": {
    "type": "String",
    "required": false
  },
  "photo_type": {
    "type": "String",
    "required": false
  },
  "display_order": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "is_primary": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "width": {
    "type": "Number",
    "required": false
  },
  "height": {
    "type": "Number",
    "required": false
  },
  "file_size": {
    "type": "Number",
    "required": false
  },
  "uploaded_by_user_id": {
    "type": "Number",
    "required": false
  },
  "uploaded_at": {
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

**References:** properties_id, users_id

### virtual_tours

**Document Structure:**
```json
{
  "property_id": {
    "type": "Number",
    "required": true
  },
  "tour_type": {
    "type": "String",
    "required": false
  },
  "tour_url": {
    "type": "String",
    "required": true
  },
  "embed_code": {
    "type": "String",
    "required": false
  },
  "provider": {
    "type": "String",
    "required": false
  },
  "view_count": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "avg_view_duration": {
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

**References:** properties_id

### saved_searches

**Document Structure:**
```json
{
  "user_id": {
    "type": "Number",
    "required": true
  },
  "search_name": {
    "type": "String",
    "required": false
  },
  "search_criteria": {
    "type": "Object",
    "required": true
  },
  "frequency": {
    "type": "String",
    "required": false
  },
  "last_run": {
    "type": "Date",
    "required": false
  },
  "last_match_count": {
    "type": "Number",
    "required": false,
    "default": "0"
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

**References:** users_id

### saved_properties

**Document Structure:**
```json
{
  "user_id": {
    "type": "Number",
    "required": true
  },
  "property_id": {
    "type": "Number",
    "required": true
  },
  "listing_id": {
    "type": "Number",
    "required": false
  },
  "notes": {
    "type": "String",
    "required": false
  },
  "rating": {
    "type": "Number",
    "required": false
  },
  "saved_date": {
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

**References:** users_id, properties_id, listings_id

### showing_requests

**Document Structure:**
```json
{
  "listing_id": {
    "type": "Number",
    "required": true
  },
  "user_id": {
    "type": "Number",
    "required": true
  },
  "agent_id": {
    "type": "Number",
    "required": false
  },
  "preferred_date": {
    "type": "Date",
    "required": true
  },
  "preferred_time_start": {
    "type": "String",
    "required": false
  },
  "preferred_time_end": {
    "type": "String",
    "required": false
  },
  "alternate_date": {
    "type": "Date",
    "required": false
  },
  "status": {
    "type": "String",
    "required": false
  },
  "message": {
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

**References:** listings_id, users_id, agents_id

### open_houses

**Document Structure:**
```json
{
  "listing_id": {
    "type": "Number",
    "required": true
  },
  "start_datetime": {
    "type": "Date",
    "required": true
  },
  "end_datetime": {
    "type": "Date",
    "required": true
  },
  "host_agent_id": {
    "type": "Number",
    "required": true
  },
  "registration_required": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "refreshments": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "notes": {
    "type": "String",
    "required": false
  },
  "attendee_count": {
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

**References:** listings_id, agents_id

### offers

**Document Structure:**
```json
{
  "listing_id": {
    "type": "Number",
    "required": true
  },
  "buyer_user_id": {
    "type": "Number",
    "required": false
  },
  "buyer_agent_id": {
    "type": "Number",
    "required": false
  },
  "offer_amount": {
    "type": "Decimal128",
    "required": false
  },
  "offer_type": {
    "type": "String",
    "required": false
  },
  "status": {
    "type": "String",
    "required": false
  },
  "earnest_money": {
    "type": "Decimal128",
    "required": false
  },
  "down_payment_amount": {
    "type": "Decimal128",
    "required": false
  },
  "down_payment_percentage": {
    "type": "Decimal128",
    "required": false
  },
  "financing_type": {
    "type": "String",
    "required": false
  },
  "pre_approval_letter": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "contingencies": {
    "type": "Object",
    "required": false
  },
  "closing_date": {
    "type": "Date",
    "required": false
  },
  "expiry_datetime": {
    "type": "Date",
    "required": false
  },
  "submitted_at": {
    "type": "Date",
    "required": false
  },
  "response_at": {
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

**References:** listings_id, users_id, agents_id

### transactions

**Document Structure:**
```json
{
  "listing_id": {
    "type": "Number",
    "required": true
  },
  "accepted_offer_id": {
    "type": "Number",
    "required": true
  },
  "sale_price": {
    "type": "Decimal128",
    "required": false
  },
  "closing_date": {
    "type": "Date",
    "required": false
  },
  "escrow_company": {
    "type": "String",
    "required": false
  },
  "escrow_number": {
    "type": "String",
    "required": false
  },
  "title_company": {
    "type": "String",
    "required": false
  },
  "transaction_status": {
    "type": "String",
    "required": false
  },
  "commission_paid_listing": {
    "type": "Decimal128",
    "required": false
  },
  "commission_paid_buyer": {
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

**References:** listings_id, offers_id

### market_trends

**Document Structure:**
```json
{
  "neighborhood_id": {
    "type": "Number",
    "required": false
  },
  "city_id": {
    "type": "Number",
    "required": false
  },
  "state_id": {
    "type": "Number",
    "required": false
  },
  "trend_date": {
    "type": "String",
    "required": false
  },
  "property_type": {
    "type": "String",
    "required": false
  },
  "median_list_price": {
    "type": "Decimal128",
    "required": false
  },
  "median_sold_price": {
    "type": "Decimal128",
    "required": false
  },
  "avg_price_per_sqft": {
    "type": "Decimal128",
    "required": false
  },
  "avg_days_on_market": {
    "type": "Number",
    "required": false
  },
  "inventory_count": {
    "type": "Number",
    "required": false
  },
  "new_listings_count": {
    "type": "Number",
    "required": false
  },
  "sold_count": {
    "type": "Number",
    "required": false
  },
  "pending_count": {
    "type": "Number",
    "required": false
  },
  "price_reduced_count": {
    "type": "Number",
    "required": false
  },
  "months_of_supply": {
    "type": "Decimal128",
    "required": false
  },
  "sale_to_list_ratio": {
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

**References:** neighborhoods_id, cities_id, states_provinces_id

### comparable_sales

**Document Structure:**
```json
{
  "subject_property_id": {
    "type": "Number",
    "required": true
  },
  "comp_property_id": {
    "type": "Number",
    "required": true
  },
  "sale_date": {
    "type": "Date",
    "required": true
  },
  "sale_price": {
    "type": "Decimal128",
    "required": false
  },
  "price_per_sqft": {
    "type": "Decimal128",
    "required": false
  },
  "distance_miles": {
    "type": "Decimal128",
    "required": false
  },
  "similarity_score": {
    "type": "Decimal128",
    "required": false
  },
  "adjustments": {
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

**References:** properties_id, properties_id

### school_districts

**Document Structure:**
```json
{
  "district_name": {
    "type": "String",
    "required": true
  },
  "district_type": {
    "type": "String",
    "required": false
  },
  "state_id": {
    "type": "Number",
    "required": true
  },
  "boundary_polygon": {
    "type": "String",
    "required": false
  },
  "website": {
    "type": "String",
    "required": false
  },
  "rating": {
    "type": "Decimal128",
    "required": false
  },
  "total_schools": {
    "type": "Number",
    "required": false
  },
  "total_students": {
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

**References:** states_provinces_id

### schools

**Document Structure:**
```json
{
  "district_id": {
    "type": "Number",
    "required": true
  },
  "school_name": {
    "type": "String",
    "required": true
  },
  "school_type": {
    "type": "String",
    "required": false
  },
  "address": {
    "type": "String",
    "required": false
  },
  "city_id": {
    "type": "Number",
    "required": false
  },
  "zip_code": {
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
  "location_point": {
    "type": "String",
    "required": false
  },
  "grade_range": {
    "type": "String",
    "required": false
  },
  "enrollment": {
    "type": "Number",
    "required": false
  },
  "student_teacher_ratio": {
    "type": "Decimal128",
    "required": false
  },
  "rating": {
    "type": "Decimal128",
    "required": false
  },
  "test_scores": {
    "type": "Object",
    "required": false
  },
  "website": {
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

**References:** school_districts_id, cities_id

### property_schools

**Document Structure:**
```json
{
  "property_id": {
    "type": "Number",
    "required": true
  },
  "school_id": {
    "type": "Number",
    "required": true
  },
  "school_type": {
    "type": "String",
    "required": false
  },
  "distance_miles": {
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

**References:** properties_id, schools_id

