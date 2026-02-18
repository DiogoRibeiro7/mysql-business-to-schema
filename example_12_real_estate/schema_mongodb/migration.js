// MongoDB Migration Script
// Generated: 2026-02-17T23:16:48.788101
// From MySQL to MongoDB

use converted_db;

// Create collection: countries
db.createCollection('countries');

// Create collection: states_provinces
db.createCollection('states_provinces');

// Create collection: cities
db.createCollection('cities');

// Create collection: zip_codes
db.createCollection('zip_codes');

// Create collection: neighborhoods
db.createCollection('neighborhoods');

// Create collection: property_types
db.createCollection('property_types');

// Create collection: properties
db.createCollection('properties');

// Create collection: property_features
db.createCollection('property_features');

// Create collection: property_rooms
db.createCollection('property_rooms');

// Create collection: brokerages
db.createCollection('brokerages');

// Create collection: agents
db.createCollection('agents');

// Create collection: users
db.createCollection('users');

// Create collection: user_preferences
db.createCollection('user_preferences');

// Create collection: listings
db.createCollection('listings');

// Create collection: listing_status_history
db.createCollection('listing_status_history');

// Create collection: price_changes
db.createCollection('price_changes');

// Create collection: property_photos
db.createCollection('property_photos');

// Create collection: virtual_tours
db.createCollection('virtual_tours');

// Create collection: saved_searches
db.createCollection('saved_searches');

// Create collection: saved_properties
db.createCollection('saved_properties');

// Create collection: showing_requests
db.createCollection('showing_requests');

// Create collection: open_houses
db.createCollection('open_houses');

// Create collection: offers
db.createCollection('offers');

// Create collection: transactions
db.createCollection('transactions');

// Create collection: market_trends
db.createCollection('market_trends');

// Create collection: comparable_sales
db.createCollection('comparable_sales');

// Create collection: school_districts
db.createCollection('school_districts');

// Create collection: schools
db.createCollection('schools');

// Create collection: property_schools
db.createCollection('property_schools');

// Indexes for countries

// Indexes for states_provinces
db.states_provinces.createIndex({"country_id": 1}, {"name": "states_provinces_country_id_idx"});

// Indexes for cities
db.cities.createIndex({"state_id": 1}, {"name": "cities_state_id_idx"});

// Indexes for zip_codes
db.zip_codes.createIndex({"city_id": 1}, {"name": "zip_codes_city_id_idx"});

// Indexes for neighborhoods
db.neighborhoods.createIndex({"city_id": 1}, {"name": "neighborhoods_city_id_idx"});
db.neighborhoods.createIndex({"description": "text"}, {"name": "neighborhoods_text"});

// Indexes for property_types
db.property_types.createIndex({"parent_type_id": 1}, {"name": "property_types_parent_type_id_idx"});
db.property_types.createIndex({"description": "text"}, {"name": "property_types_text"});

// Indexes for properties
db.properties.createIndex({"property_type_id": 1}, {"name": "properties_property_type_id_idx"});
db.properties.createIndex({"city_id": 1}, {"name": "properties_city_id_idx"});
db.properties.createIndex({"state_id": 1}, {"name": "properties_state_id_idx"});
db.properties.createIndex({"neighborhood_id": 1}, {"name": "properties_neighborhood_id_idx"});
db.properties.createIndex({"legal_description": "text"}, {"name": "properties_text"});

// Indexes for property_features
db.property_features.createIndex({"property_id": 1}, {"name": "property_features_property_id_idx"});

// Indexes for property_rooms
db.property_rooms.createIndex({"property_id": 1}, {"name": "property_rooms_property_id_idx"});
db.property_rooms.createIndex({"description": "text"}, {"name": "property_rooms_text"});

// Indexes for brokerages
db.brokerages.createIndex({"city_id": 1}, {"name": "brokerages_city_id_idx"});
db.brokerages.createIndex({"state_id": 1}, {"name": "brokerages_state_id_idx"});

// Indexes for agents
db.agents.createIndex({"brokerage_id": 1}, {"name": "agents_brokerage_id_idx"});
db.agents.createIndex({"license_state_id": 1}, {"name": "agents_license_state_id_idx"});
db.agents.createIndex({"bio": "text"}, {"name": "agents_text"});

// Indexes for users

// Indexes for user_preferences
db.user_preferences.createIndex({"user_id": 1}, {"name": "user_preferences_user_id_idx"});

// Indexes for listings
db.listings.createIndex({"property_id": 1}, {"name": "listings_property_id_idx"});
db.listings.createIndex({"listing_agent_id": 1}, {"name": "listings_listing_agent_id_idx"});
db.listings.createIndex({"co_listing_agent_id": 1}, {"name": "listings_co_listing_agent_id_idx"});
db.listings.createIndex({"description": "text", "showing_instructions": "text"}, {"name": "listings_text"});

// Indexes for listing_status_history
db.listing_status_history.createIndex({"listing_id": 1}, {"name": "listing_status_history_listing_id_idx"});
db.listing_status_history.createIndex({"changed_by_user_id": 1}, {"name": "listing_status_history_changed_by_user_id_idx"});
db.listing_status_history.createIndex({"notes": "text"}, {"name": "listing_status_history_text"});

// Indexes for price_changes
db.price_changes.createIndex({"listing_id": 1}, {"name": "price_changes_listing_id_idx"});
db.price_changes.createIndex({"reason": "text"}, {"name": "price_changes_text"});

// Indexes for property_photos
db.property_photos.createIndex({"property_id": 1}, {"name": "property_photos_property_id_idx"});
db.property_photos.createIndex({"uploaded_by_user_id": 1}, {"name": "property_photos_uploaded_by_user_id_idx"});

// Indexes for virtual_tours
db.virtual_tours.createIndex({"property_id": 1}, {"name": "virtual_tours_property_id_idx"});
db.virtual_tours.createIndex({"embed_code": "text"}, {"name": "virtual_tours_text"});

// Indexes for saved_searches
db.saved_searches.createIndex({"user_id": 1}, {"name": "saved_searches_user_id_idx"});

// Indexes for saved_properties
db.saved_properties.createIndex({"user_id": 1}, {"name": "saved_properties_user_id_idx"});
db.saved_properties.createIndex({"property_id": 1}, {"name": "saved_properties_property_id_idx"});
db.saved_properties.createIndex({"listing_id": 1}, {"name": "saved_properties_listing_id_idx"});
db.saved_properties.createIndex({"notes": "text"}, {"name": "saved_properties_text"});

// Indexes for showing_requests
db.showing_requests.createIndex({"listing_id": 1}, {"name": "showing_requests_listing_id_idx"});
db.showing_requests.createIndex({"user_id": 1}, {"name": "showing_requests_user_id_idx"});
db.showing_requests.createIndex({"agent_id": 1}, {"name": "showing_requests_agent_id_idx"});
db.showing_requests.createIndex({"message": "text"}, {"name": "showing_requests_text"});

// Indexes for open_houses
db.open_houses.createIndex({"listing_id": 1}, {"name": "open_houses_listing_id_idx"});
db.open_houses.createIndex({"host_agent_id": 1}, {"name": "open_houses_host_agent_id_idx"});
db.open_houses.createIndex({"notes": "text"}, {"name": "open_houses_text"});

// Indexes for offers
db.offers.createIndex({"listing_id": 1}, {"name": "offers_listing_id_idx"});
db.offers.createIndex({"buyer_user_id": 1}, {"name": "offers_buyer_user_id_idx"});
db.offers.createIndex({"buyer_agent_id": 1}, {"name": "offers_buyer_agent_id_idx"});

// Indexes for transactions
db.transactions.createIndex({"listing_id": 1}, {"name": "transactions_listing_id_idx"});
db.transactions.createIndex({"accepted_offer_id": 1}, {"name": "transactions_accepted_offer_id_idx"});

// Indexes for market_trends
db.market_trends.createIndex({"neighborhood_id": 1}, {"name": "market_trends_neighborhood_id_idx"});
db.market_trends.createIndex({"city_id": 1}, {"name": "market_trends_city_id_idx"});
db.market_trends.createIndex({"state_id": 1}, {"name": "market_trends_state_id_idx"});

// Indexes for comparable_sales
db.comparable_sales.createIndex({"subject_property_id": 1}, {"name": "comparable_sales_subject_property_id_idx"});
db.comparable_sales.createIndex({"comp_property_id": 1}, {"name": "comparable_sales_comp_property_id_idx"});

// Indexes for school_districts
db.school_districts.createIndex({"state_id": 1}, {"name": "school_districts_state_id_idx"});

// Indexes for schools
db.schools.createIndex({"district_id": 1}, {"name": "schools_district_id_idx"});
db.schools.createIndex({"city_id": 1}, {"name": "schools_city_id_idx"});

// Indexes for property_schools
db.property_schools.createIndex({"property_id": 1}, {"name": "property_schools_property_id_idx"});
db.property_schools.createIndex({"school_id": 1}, {"name": "property_schools_school_id_idx"});

// Validation for countries
db.runCommand({
  collMod: 'countries',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "country_code",
      "country_name"
    ],
    "properties": {
      "country_code": {
        "bsonType": "string"
      },
      "country_name": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for states_provinces
db.runCommand({
  collMod: 'states_provinces',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "country_id",
      "state_code",
      "state_name"
    ],
    "properties": {
      "country_id": {
        "bsonType": "number"
      },
      "state_code": {
        "bsonType": "string"
      },
      "state_name": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for cities
db.runCommand({
  collMod: 'cities',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "state_id",
      "city_name"
    ],
    "properties": {
      "state_id": {
        "bsonType": "number"
      },
      "city_name": {
        "bsonType": "string"
      },
      "latitude": {
        "bsonType": "decimal128"
      },
      "longitude": {
        "bsonType": "decimal128"
      },
      "population": {
        "bsonType": "number"
      },
      "median_income": {
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

// Validation for zip_codes
db.runCommand({
  collMod: 'zip_codes',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "city_id"
    ],
    "properties": {
      "city_id": {
        "bsonType": "number"
      },
      "latitude": {
        "bsonType": "decimal128"
      },
      "longitude": {
        "bsonType": "decimal128"
      },
      "timezone": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for neighborhoods
db.runCommand({
  collMod: 'neighborhoods',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "city_id",
      "neighborhood_name"
    ],
    "properties": {
      "city_id": {
        "bsonType": "number"
      },
      "neighborhood_name": {
        "bsonType": "string"
      },
      "boundary_polygon": {
        "bsonType": "string"
      },
      "center_point": {
        "bsonType": "string"
      },
      "median_home_price": {
        "bsonType": "decimal128"
      },
      "median_rent": {
        "bsonType": "decimal128"
      },
      "walk_score": {
        "bsonType": "number"
      },
      "transit_score": {
        "bsonType": "number"
      },
      "crime_rate": {
        "bsonType": "decimal128"
      },
      "school_rating": {
        "bsonType": "decimal128"
      },
      "description": {
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

// Validation for property_types
db.runCommand({
  collMod: 'property_types',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "type_name"
    ],
    "properties": {
      "parent_type_id": {
        "bsonType": "number"
      },
      "type_name": {
        "bsonType": "string"
      },
      "type_category": {
        "bsonType": "string"
      },
      "description": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for properties
db.runCommand({
  collMod: 'properties',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "property_type_id",
      "address_line1",
      "city_id",
      "state_id",
      "zip_code",
      "location_point"
    ],
    "properties": {
      "property_type_id": {
        "bsonType": "number"
      },
      "address_line1": {
        "bsonType": "string"
      },
      "address_line2": {
        "bsonType": "string"
      },
      "city_id": {
        "bsonType": "number"
      },
      "state_id": {
        "bsonType": "number"
      },
      "zip_code": {
        "bsonType": "string"
      },
      "neighborhood_id": {
        "bsonType": "number"
      },
      "latitude": {
        "bsonType": "decimal128"
      },
      "longitude": {
        "bsonType": "decimal128"
      },
      "location_point": {
        "bsonType": "string"
      },
      "parcel_number": {
        "bsonType": "string"
      },
      "legal_description": {
        "bsonType": "string"
      },
      "year_built": {
        "bsonType": "number"
      },
      "lot_size_sqft": {
        "bsonType": "number"
      },
      "building_size_sqft": {
        "bsonType": "number"
      },
      "bedrooms": {
        "bsonType": "number"
      },
      "bathrooms": {
        "bsonType": "decimal128"
      },
      "parking_spaces": {
        "bsonType": "number"
      },
      "garage_spaces": {
        "bsonType": "number"
      },
      "stories": {
        "bsonType": "number"
      },
      "construction_type": {
        "bsonType": "string"
      },
      "roof_type": {
        "bsonType": "string"
      },
      "heating_type": {
        "bsonType": "string"
      },
      "cooling_type": {
        "bsonType": "string"
      },
      "zoning": {
        "bsonType": "string"
      },
      "hoa_fee": {
        "bsonType": "decimal128"
      },
      "tax_assessed_value": {
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

// Validation for property_features
db.runCommand({
  collMod: 'property_features',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "property_id",
      "feature_name"
    ],
    "properties": {
      "property_id": {
        "bsonType": "number"
      },
      "feature_category": {
        "bsonType": "string"
      },
      "feature_name": {
        "bsonType": "string"
      },
      "feature_value": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for property_rooms
db.runCommand({
  collMod: 'property_rooms',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "property_id",
      "room_type"
    ],
    "properties": {
      "property_id": {
        "bsonType": "number"
      },
      "room_type": {
        "bsonType": "string"
      },
      "room_level": {
        "bsonType": "string"
      },
      "length_ft": {
        "bsonType": "decimal128"
      },
      "width_ft": {
        "bsonType": "decimal128"
      },
      "description": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for brokerages
db.runCommand({
  collMod: 'brokerages',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "brokerage_name",
      "license_number"
    ],
    "properties": {
      "brokerage_name": {
        "bsonType": "string"
      },
      "license_number": {
        "bsonType": "string"
      },
      "address": {
        "bsonType": "string"
      },
      "city_id": {
        "bsonType": "number"
      },
      "state_id": {
        "bsonType": "number"
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
      "website": {
        "bsonType": "string"
      },
      "established_date": {
        "bsonType": "date"
      },
      "total_agents": {
        "bsonType": "number"
      },
      "active_listings": {
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

// Validation for agents
db.runCommand({
  collMod: 'agents',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "first_name",
      "last_name",
      "email",
      "license_number",
      "license_state_id",
      "joined_date"
    ],
    "properties": {
      "brokerage_id": {
        "bsonType": "number"
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
      "mobile_phone": {
        "bsonType": "string"
      },
      "license_number": {
        "bsonType": "string"
      },
      "license_state_id": {
        "bsonType": "number"
      },
      "license_expiry_date": {
        "bsonType": "date"
      },
      "specializations": {
        "bsonType": "object"
      },
      "bio": {
        "bsonType": "string"
      },
      "profile_photo_url": {
        "bsonType": "string"
      },
      "years_experience": {
        "bsonType": "number"
      },
      "total_sales_volume": {
        "bsonType": "decimal128"
      },
      "total_transactions": {
        "bsonType": "number"
      },
      "avg_days_on_market": {
        "bsonType": "number"
      },
      "rating": {
        "bsonType": "decimal128"
      },
      "is_active": {
        "bsonType": "boolean"
      },
      "joined_date": {
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

// Validation for users
db.runCommand({
  collMod: 'users',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "email",
      "password_hash"
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
      "user_type": {
        "bsonType": "string"
      },
      "email_verified": {
        "bsonType": "boolean"
      },
      "phone_verified": {
        "bsonType": "boolean"
      },
      "profile_photo_url": {
        "bsonType": "string"
      },
      "preferred_contact": {
        "bsonType": "string"
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

// Validation for user_preferences
db.runCommand({
  collMod: 'user_preferences',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "user_id"
    ],
    "properties": {
      "user_id": {
        "bsonType": "number"
      },
      "min_price": {
        "bsonType": "decimal128"
      },
      "max_price": {
        "bsonType": "decimal128"
      },
      "min_bedrooms": {
        "bsonType": "number"
      },
      "min_bathrooms": {
        "bsonType": "decimal128"
      },
      "min_sqft": {
        "bsonType": "number"
      },
      "max_sqft": {
        "bsonType": "number"
      },
      "property_types": {
        "bsonType": "object"
      },
      "preferred_cities": {
        "bsonType": "object"
      },
      "preferred_neighborhoods": {
        "bsonType": "object"
      },
      "must_have_features": {
        "bsonType": "object"
      },
      "nice_to_have_features": {
        "bsonType": "object"
      },
      "max_hoa_fee": {
        "bsonType": "decimal128"
      },
      "school_rating_min": {
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

// Validation for listings
db.runCommand({
  collMod: 'listings',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "property_id",
      "listing_agent_id",
      "listing_date"
    ],
    "properties": {
      "property_id": {
        "bsonType": "number"
      },
      "listing_agent_id": {
        "bsonType": "number"
      },
      "co_listing_agent_id": {
        "bsonType": "number"
      },
      "listing_type": {
        "bsonType": "string"
      },
      "status": {
        "bsonType": "string"
      },
      "list_price": {
        "bsonType": "decimal128"
      },
      "original_price": {
        "bsonType": "decimal128"
      },
      "price_per_sqft": {
        "bsonType": "decimal128"
      },
      "listing_date": {
        "bsonType": "date"
      },
      "expiry_date": {
        "bsonType": "date"
      },
      "days_on_market": {
        "bsonType": "number"
      },
      "title": {
        "bsonType": "string"
      },
      "description": {
        "bsonType": "string"
      },
      "virtual_tour_url": {
        "bsonType": "string"
      },
      "video_url": {
        "bsonType": "string"
      },
      "commission_buyer_agent": {
        "bsonType": "decimal128"
      },
      "commission_listing_agent": {
        "bsonType": "decimal128"
      },
      "showing_instructions": {
        "bsonType": "string"
      },
      "mls_number": {
        "bsonType": "string"
      },
      "is_featured": {
        "bsonType": "boolean"
      },
      "view_count": {
        "bsonType": "number"
      },
      "inquiry_count": {
        "bsonType": "number"
      },
      "showing_count": {
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

// Validation for listing_status_history
db.runCommand({
  collMod: 'listing_status_history',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "listing_id"
    ],
    "properties": {
      "listing_id": {
        "bsonType": "number"
      },
      "status": {
        "bsonType": "string"
      },
      "changed_date": {
        "bsonType": "string"
      },
      "changed_by_user_id": {
        "bsonType": "number"
      },
      "notes": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for price_changes
db.runCommand({
  collMod: 'price_changes',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "listing_id"
    ],
    "properties": {
      "listing_id": {
        "bsonType": "number"
      },
      "old_price": {
        "bsonType": "decimal128"
      },
      "new_price": {
        "bsonType": "decimal128"
      },
      "change_amount": {
        "bsonType": "decimal128"
      },
      "change_percentage": {
        "bsonType": "decimal128"
      },
      "change_date": {
        "bsonType": "string"
      },
      "reason": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for property_photos
db.runCommand({
  collMod: 'property_photos',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "property_id",
      "photo_url"
    ],
    "properties": {
      "property_id": {
        "bsonType": "number"
      },
      "photo_url": {
        "bsonType": "string"
      },
      "thumbnail_url": {
        "bsonType": "string"
      },
      "caption": {
        "bsonType": "string"
      },
      "photo_type": {
        "bsonType": "string"
      },
      "display_order": {
        "bsonType": "number"
      },
      "is_primary": {
        "bsonType": "boolean"
      },
      "width": {
        "bsonType": "number"
      },
      "height": {
        "bsonType": "number"
      },
      "file_size": {
        "bsonType": "number"
      },
      "uploaded_by_user_id": {
        "bsonType": "number"
      },
      "uploaded_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for virtual_tours
db.runCommand({
  collMod: 'virtual_tours',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "property_id",
      "tour_url"
    ],
    "properties": {
      "property_id": {
        "bsonType": "number"
      },
      "tour_type": {
        "bsonType": "string"
      },
      "tour_url": {
        "bsonType": "string"
      },
      "embed_code": {
        "bsonType": "string"
      },
      "provider": {
        "bsonType": "string"
      },
      "view_count": {
        "bsonType": "number"
      },
      "avg_view_duration": {
        "bsonType": "number"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for saved_searches
db.runCommand({
  collMod: 'saved_searches',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "user_id",
      "search_criteria"
    ],
    "properties": {
      "user_id": {
        "bsonType": "number"
      },
      "search_name": {
        "bsonType": "string"
      },
      "search_criteria": {
        "bsonType": "object"
      },
      "frequency": {
        "bsonType": "string"
      },
      "last_run": {
        "bsonType": "date"
      },
      "last_match_count": {
        "bsonType": "number"
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

// Validation for saved_properties
db.runCommand({
  collMod: 'saved_properties',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "user_id",
      "property_id"
    ],
    "properties": {
      "user_id": {
        "bsonType": "number"
      },
      "property_id": {
        "bsonType": "number"
      },
      "listing_id": {
        "bsonType": "number"
      },
      "notes": {
        "bsonType": "string"
      },
      "rating": {
        "bsonType": "number"
      },
      "saved_date": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for showing_requests
db.runCommand({
  collMod: 'showing_requests',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "listing_id",
      "user_id",
      "preferred_date"
    ],
    "properties": {
      "listing_id": {
        "bsonType": "number"
      },
      "user_id": {
        "bsonType": "number"
      },
      "agent_id": {
        "bsonType": "number"
      },
      "preferred_date": {
        "bsonType": "date"
      },
      "preferred_time_start": {
        "bsonType": "string"
      },
      "preferred_time_end": {
        "bsonType": "string"
      },
      "alternate_date": {
        "bsonType": "date"
      },
      "status": {
        "bsonType": "string"
      },
      "message": {
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

// Validation for open_houses
db.runCommand({
  collMod: 'open_houses',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "listing_id",
      "start_datetime",
      "end_datetime",
      "host_agent_id"
    ],
    "properties": {
      "listing_id": {
        "bsonType": "number"
      },
      "start_datetime": {
        "bsonType": "date"
      },
      "end_datetime": {
        "bsonType": "date"
      },
      "host_agent_id": {
        "bsonType": "number"
      },
      "registration_required": {
        "bsonType": "boolean"
      },
      "refreshments": {
        "bsonType": "boolean"
      },
      "notes": {
        "bsonType": "string"
      },
      "attendee_count": {
        "bsonType": "number"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for offers
db.runCommand({
  collMod: 'offers',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "listing_id"
    ],
    "properties": {
      "listing_id": {
        "bsonType": "number"
      },
      "buyer_user_id": {
        "bsonType": "number"
      },
      "buyer_agent_id": {
        "bsonType": "number"
      },
      "offer_amount": {
        "bsonType": "decimal128"
      },
      "offer_type": {
        "bsonType": "string"
      },
      "status": {
        "bsonType": "string"
      },
      "earnest_money": {
        "bsonType": "decimal128"
      },
      "down_payment_amount": {
        "bsonType": "decimal128"
      },
      "down_payment_percentage": {
        "bsonType": "decimal128"
      },
      "financing_type": {
        "bsonType": "string"
      },
      "pre_approval_letter": {
        "bsonType": "boolean"
      },
      "contingencies": {
        "bsonType": "object"
      },
      "closing_date": {
        "bsonType": "date"
      },
      "expiry_datetime": {
        "bsonType": "date"
      },
      "submitted_at": {
        "bsonType": "date"
      },
      "response_at": {
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

// Validation for transactions
db.runCommand({
  collMod: 'transactions',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "listing_id",
      "accepted_offer_id"
    ],
    "properties": {
      "listing_id": {
        "bsonType": "number"
      },
      "accepted_offer_id": {
        "bsonType": "number"
      },
      "sale_price": {
        "bsonType": "decimal128"
      },
      "closing_date": {
        "bsonType": "date"
      },
      "escrow_company": {
        "bsonType": "string"
      },
      "escrow_number": {
        "bsonType": "string"
      },
      "title_company": {
        "bsonType": "string"
      },
      "transaction_status": {
        "bsonType": "string"
      },
      "commission_paid_listing": {
        "bsonType": "decimal128"
      },
      "commission_paid_buyer": {
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

// Validation for market_trends
db.runCommand({
  collMod: 'market_trends',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "trend_date"
    ],
    "properties": {
      "neighborhood_id": {
        "bsonType": "number"
      },
      "city_id": {
        "bsonType": "number"
      },
      "state_id": {
        "bsonType": "number"
      },
      "trend_date": {
        "bsonType": "string"
      },
      "property_type": {
        "bsonType": "string"
      },
      "median_list_price": {
        "bsonType": "decimal128"
      },
      "median_sold_price": {
        "bsonType": "decimal128"
      },
      "avg_price_per_sqft": {
        "bsonType": "decimal128"
      },
      "avg_days_on_market": {
        "bsonType": "number"
      },
      "inventory_count": {
        "bsonType": "number"
      },
      "new_listings_count": {
        "bsonType": "number"
      },
      "sold_count": {
        "bsonType": "number"
      },
      "pending_count": {
        "bsonType": "number"
      },
      "price_reduced_count": {
        "bsonType": "number"
      },
      "months_of_supply": {
        "bsonType": "decimal128"
      },
      "sale_to_list_ratio": {
        "bsonType": "decimal128"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for comparable_sales
db.runCommand({
  collMod: 'comparable_sales',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "subject_property_id",
      "comp_property_id",
      "sale_date"
    ],
    "properties": {
      "subject_property_id": {
        "bsonType": "number"
      },
      "comp_property_id": {
        "bsonType": "number"
      },
      "sale_date": {
        "bsonType": "date"
      },
      "sale_price": {
        "bsonType": "decimal128"
      },
      "price_per_sqft": {
        "bsonType": "decimal128"
      },
      "distance_miles": {
        "bsonType": "decimal128"
      },
      "similarity_score": {
        "bsonType": "decimal128"
      },
      "adjustments": {
        "bsonType": "object"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for school_districts
db.runCommand({
  collMod: 'school_districts',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "district_name",
      "state_id"
    ],
    "properties": {
      "district_name": {
        "bsonType": "string"
      },
      "district_type": {
        "bsonType": "string"
      },
      "state_id": {
        "bsonType": "number"
      },
      "boundary_polygon": {
        "bsonType": "string"
      },
      "website": {
        "bsonType": "string"
      },
      "rating": {
        "bsonType": "decimal128"
      },
      "total_schools": {
        "bsonType": "number"
      },
      "total_students": {
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

// Validation for schools
db.runCommand({
  collMod: 'schools',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "district_id",
      "school_name"
    ],
    "properties": {
      "district_id": {
        "bsonType": "number"
      },
      "school_name": {
        "bsonType": "string"
      },
      "school_type": {
        "bsonType": "string"
      },
      "address": {
        "bsonType": "string"
      },
      "city_id": {
        "bsonType": "number"
      },
      "zip_code": {
        "bsonType": "string"
      },
      "latitude": {
        "bsonType": "decimal128"
      },
      "longitude": {
        "bsonType": "decimal128"
      },
      "location_point": {
        "bsonType": "string"
      },
      "grade_range": {
        "bsonType": "string"
      },
      "enrollment": {
        "bsonType": "number"
      },
      "student_teacher_ratio": {
        "bsonType": "decimal128"
      },
      "rating": {
        "bsonType": "decimal128"
      },
      "test_scores": {
        "bsonType": "object"
      },
      "website": {
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

// Validation for property_schools
db.runCommand({
  collMod: 'property_schools',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "property_id",
      "school_id"
    ],
    "properties": {
      "property_id": {
        "bsonType": "number"
      },
      "school_id": {
        "bsonType": "number"
      },
      "school_type": {
        "bsonType": "string"
      },
      "distance_miles": {
        "bsonType": "decimal128"
      }
    }
  }
}
});
