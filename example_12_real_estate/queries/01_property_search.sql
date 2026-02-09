-- =========================================
-- Real Estate Platform - Property Search Queries
-- =========================================

USE real_estate;

-- =========================================
-- 1. Basic Property Search with Filters
-- =========================================

-- Search properties by multiple criteria
SELECT
    p.property_id,
    p.address_line1,
    c.city_name,
    sp.state_name,
    p.zip_code,
    n.neighborhood_name,
    pt.type_name AS property_type,
    p.bedrooms,
    p.bathrooms,
    p.building_size_sqft,
    p.lot_size_sqft,
    p.year_built,
    l.listing_id,
    l.list_price,
    l.price_per_sqft,
    l.status AS listing_status,
    l.days_on_market,
    CONCAT(a.first_name, ' ', a.last_name) AS listing_agent,
    b.brokerage_name,
    (SELECT COUNT(*) FROM property_photos pp WHERE pp.property_id = p.property_id) AS photo_count,
    (SELECT photo_url FROM property_photos pp2
     WHERE pp2.property_id = p.property_id AND pp2.is_primary = TRUE
     LIMIT 1) AS primary_photo
FROM properties p
JOIN property_types pt ON p.property_type_id = pt.type_id
JOIN cities c ON p.city_id = c.city_id
JOIN states_provinces sp ON p.state_id = sp.state_id
LEFT JOIN neighborhoods n ON p.neighborhood_id = n.neighborhood_id
LEFT JOIN listings l ON p.property_id = l.property_id AND l.status = 'active'
LEFT JOIN agents a ON l.listing_agent_id = a.agent_id
LEFT JOIN brokerages b ON a.brokerage_id = b.brokerage_id
WHERE l.listing_id IS NOT NULL
  -- Price range filter
  AND l.list_price BETWEEN 300000 AND 600000
  -- Bedrooms filter
  AND p.bedrooms >= 3
  -- Bathrooms filter
  AND p.bathrooms >= 2
  -- Square footage filter
  AND p.building_size_sqft >= 1500
  -- Property type filter
  AND pt.type_category = 'residential'
  -- Location filter
  AND c.city_name IN ('San Francisco', 'Oakland', 'Berkeley')
  -- Year built filter
  AND p.year_built >= 1990
ORDER BY l.list_price ASC
LIMIT 50;

-- =========================================
-- 2. Geographic/Spatial Search
-- =========================================

-- Find properties within radius of a point (e.g., workplace)
SET @center_lat = 37.7749;  -- San Francisco coordinates
SET @center_lng = -122.4194;
SET @radius_miles = 5;

SELECT
    p.property_id,
    p.address_line1,
    c.city_name,
    p.bedrooms,
    p.bathrooms,
    l.list_price,
    ST_Distance_Sphere(
        p.location_point,
        POINT(@center_lng, @center_lat)
    ) * 0.000621371 AS distance_miles,
    l.days_on_market,
    n.walk_score,
    n.transit_score
FROM properties p
JOIN cities c ON p.city_id = c.city_id
LEFT JOIN neighborhoods n ON p.neighborhood_id = n.neighborhood_id
JOIN listings l ON p.property_id = l.property_id
WHERE l.status = 'active'
  AND ST_Distance_Sphere(
      p.location_point,
      POINT(@center_lng, @center_lat)
  ) <= @radius_miles * 1609.34  -- Convert miles to meters
ORDER BY distance_miles ASC
LIMIT 20;

-- =========================================
-- 3. School District Search
-- =========================================

-- Find properties in top-rated school districts
SELECT
    p.property_id,
    p.address_line1,
    c.city_name,
    l.list_price,
    p.bedrooms,
    p.bathrooms,
    p.building_size_sqft,
    sd.district_name,
    sd.rating AS district_rating,
    GROUP_CONCAT(
        CONCAT(s.school_name, ' (', s.rating, ')')
        ORDER BY s.rating DESC
        SEPARATOR ', '
    ) AS assigned_schools
FROM properties p
JOIN cities c ON p.city_id = c.city_id
JOIN listings l ON p.property_id = l.property_id
JOIN property_schools ps ON p.property_id = ps.property_id
JOIN schools s ON ps.school_id = s.school_id
JOIN school_districts sd ON s.district_id = sd.district_id
WHERE l.status = 'active'
  AND ps.school_type = 'assigned'
  AND sd.rating >= 8.0
  AND s.rating >= 7.5
GROUP BY p.property_id
HAVING COUNT(DISTINCT s.school_id) >= 2  -- At least 2 good schools
ORDER BY sd.rating DESC, l.list_price ASC
LIMIT 30;

-- =========================================
-- 4. Price Range Analysis
-- =========================================

-- Find properties with recent price reductions
SELECT
    p.property_id,
    p.address_line1,
    c.city_name,
    l.list_price AS current_price,
    l.original_price,
    pc.old_price AS previous_price,
    pc.change_amount,
    pc.change_percentage,
    pc.change_date,
    DATEDIFF(CURDATE(), pc.change_date) AS days_since_reduction,
    l.days_on_market,
    p.bedrooms,
    p.bathrooms,
    p.building_size_sqft
FROM properties p
JOIN cities c ON p.city_id = c.city_id
JOIN listings l ON p.property_id = l.property_id
JOIN (
    SELECT
        listing_id,
        old_price,
        new_price,
        change_amount,
        change_percentage,
        change_date,
        ROW_NUMBER() OVER (PARTITION BY listing_id ORDER BY change_date DESC) AS rn
    FROM price_changes
    WHERE change_amount < 0  -- Only price reductions
) pc ON l.listing_id = pc.listing_id AND pc.rn = 1
WHERE l.status = 'active'
  AND pc.change_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
ORDER BY pc.change_percentage ASC  -- Biggest reductions first
LIMIT 20;

-- =========================================
-- 5. Similar Properties (Comparables)
-- =========================================

-- Find similar properties to a given property
SET @target_property_id = 1;

WITH TargetProperty AS (
    SELECT
        property_id,
        property_type_id,
        city_id,
        neighborhood_id,
        bedrooms,
        bathrooms,
        building_size_sqft,
        lot_size_sqft,
        year_built,
        latitude,
        longitude,
        location_point
    FROM properties
    WHERE property_id = @target_property_id
)
SELECT
    p.property_id,
    p.address_line1,
    c.city_name,
    n.neighborhood_name,
    l.list_price,
    l.status,
    p.bedrooms,
    p.bathrooms,
    p.building_size_sqft,
    ABS(p.building_size_sqft - tp.building_size_sqft) AS sqft_difference,
    ABS(p.year_built - tp.year_built) AS year_difference,
    ST_Distance_Sphere(p.location_point, tp.location_point) * 0.000621371 AS distance_miles,
    -- Calculate similarity score
    (
        CASE WHEN p.bedrooms = tp.bedrooms THEN 25 ELSE 0 END +
        CASE WHEN p.bathrooms = tp.bathrooms THEN 20 ELSE 0 END +
        CASE WHEN ABS(p.building_size_sqft - tp.building_size_sqft) <= 200 THEN 20
             WHEN ABS(p.building_size_sqft - tp.building_size_sqft) <= 500 THEN 10
             ELSE 0 END +
        CASE WHEN ABS(p.year_built - tp.year_built) <= 5 THEN 15
             WHEN ABS(p.year_built - tp.year_built) <= 10 THEN 10
             ELSE 0 END +
        CASE WHEN p.neighborhood_id = tp.neighborhood_id THEN 20
             WHEN ST_Distance_Sphere(p.location_point, tp.location_point) <= 1609.34 THEN 10
             ELSE 0 END
    ) AS similarity_score
FROM properties p
CROSS JOIN TargetProperty tp
JOIN cities c ON p.city_id = c.city_id
LEFT JOIN neighborhoods n ON p.neighborhood_id = n.neighborhood_id
LEFT JOIN listings l ON p.property_id = l.property_id
WHERE p.property_id != @target_property_id
  AND p.property_type_id = tp.property_type_id
  AND ST_Distance_Sphere(p.location_point, tp.location_point) <= 5 * 1609.34  -- Within 5 miles
ORDER BY similarity_score DESC, distance_miles ASC
LIMIT 10;

-- =========================================
-- 6. Saved Search Matching
-- =========================================

-- Match properties to user's saved search criteria
SET @user_id = 1;

SELECT
    ss.search_id,
    ss.search_name,
    p.property_id,
    p.address_line1,
    c.city_name,
    l.list_price,
    p.bedrooms,
    p.bathrooms,
    p.building_size_sqft,
    l.listing_date,
    CASE
        WHEN l.listing_date >= DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN 'NEW'
        WHEN pc.change_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY) THEN 'PRICE REDUCED'
        ELSE 'MATCH'
    END AS match_type
FROM saved_searches ss
CROSS JOIN properties p
JOIN cities c ON p.city_id = c.city_id
JOIN listings l ON p.property_id = l.property_id
LEFT JOIN (
    SELECT listing_id, MAX(change_date) AS change_date
    FROM price_changes
    WHERE change_amount < 0
    GROUP BY listing_id
) pc ON l.listing_id = pc.listing_id
WHERE ss.user_id = @user_id
  AND ss.is_active = TRUE
  AND l.status = 'active'
  -- Parse JSON criteria and apply filters
  AND l.list_price BETWEEN
      JSON_EXTRACT(ss.search_criteria, '$.min_price') AND
      JSON_EXTRACT(ss.search_criteria, '$.max_price')
  AND p.bedrooms >= COALESCE(JSON_EXTRACT(ss.search_criteria, '$.min_bedrooms'), 0)
  AND p.bathrooms >= COALESCE(JSON_EXTRACT(ss.search_criteria, '$.min_bathrooms'), 0)
  AND p.building_size_sqft >= COALESCE(JSON_EXTRACT(ss.search_criteria, '$.min_sqft'), 0)
  AND (JSON_EXTRACT(ss.search_criteria, '$.cities') IS NULL
       OR JSON_CONTAINS(JSON_EXTRACT(ss.search_criteria, '$.cities'),
                        JSON_QUOTE(c.city_name)))
ORDER BY l.listing_date DESC
LIMIT 50;

-- =========================================
-- 7. Investment Property Analysis
-- =========================================

-- Find best investment properties based on rent estimates
SELECT
    p.property_id,
    p.address_line1,
    c.city_name,
    n.neighborhood_name,
    l.list_price,
    p.bedrooms,
    p.bathrooms,
    p.building_size_sqft,
    n.median_rent AS neighborhood_median_rent,
    -- Estimate monthly rent based on neighborhood data
    ROUND(n.median_rent * (p.bedrooms / 2.5), -2) AS estimated_monthly_rent,
    -- Calculate investment metrics
    ROUND((n.median_rent * (p.bedrooms / 2.5) * 12) / l.list_price * 100, 2) AS gross_rental_yield,
    ROUND(l.list_price / (n.median_rent * (p.bedrooms / 2.5)), 1) AS rent_price_ratio,
    p.tax_assessed_value,
    p.hoa_fee
FROM properties p
JOIN cities c ON p.city_id = c.city_id
JOIN neighborhoods n ON p.neighborhood_id = n.neighborhood_id
JOIN listings l ON p.property_id = l.property_id
WHERE l.status = 'active'
  AND l.listing_type = 'for_sale'
  AND n.median_rent > 0
  AND p.bedrooms BETWEEN 1 AND 4
  AND l.list_price < 1000000
HAVING gross_rental_yield > 5  -- At least 5% gross yield
ORDER BY gross_rental_yield DESC
LIMIT 20;

-- =========================================
-- 8. Luxury Property Search
-- =========================================

-- Find luxury properties with premium features
SELECT
    p.property_id,
    p.address_line1,
    c.city_name,
    n.neighborhood_name,
    l.list_price,
    p.bedrooms,
    p.bathrooms,
    p.building_size_sqft,
    p.lot_size_sqft,
    p.year_built,
    l.virtual_tour_url,
    GROUP_CONCAT(
        DISTINCT pf.feature_name
        ORDER BY pf.feature_category
        SEPARATOR ', '
    ) AS premium_features,
    (SELECT COUNT(*) FROM property_photos WHERE property_id = p.property_id) AS photo_count,
    a.first_name,
    a.last_name,
    a.rating AS agent_rating
FROM properties p
JOIN cities c ON p.city_id = c.city_id
JOIN neighborhoods n ON p.neighborhood_id = n.neighborhood_id
JOIN listings l ON p.property_id = l.property_id
JOIN agents a ON l.listing_agent_id = a.agent_id
LEFT JOIN property_features pf ON p.property_id = pf.property_id
    AND pf.feature_name IN ('Pool', 'Wine Cellar', 'Home Theater', 'Smart Home',
                            'Gourmet Kitchen', 'Ocean View', 'Private Beach')
WHERE l.status = 'active'
  AND l.list_price >= 2000000
  AND p.building_size_sqft >= 4000
  AND p.bathrooms >= 3
GROUP BY p.property_id
HAVING COUNT(DISTINCT pf.feature_name) >= 2  -- At least 2 luxury features
ORDER BY l.list_price DESC
LIMIT 20;

-- =========================================
-- 9. First-Time Buyer Properties
-- =========================================

-- Find affordable starter homes
SELECT
    p.property_id,
    p.address_line1,
    c.city_name,
    n.neighborhood_name,
    l.list_price,
    p.bedrooms,
    p.bathrooms,
    p.building_size_sqft,
    p.year_built,
    p.hoa_fee,
    -- Calculate affordability metrics
    ROUND(l.list_price * 0.20, 0) AS twenty_percent_down,
    ROUND(l.list_price * 0.03, 0) AS estimated_closing_costs,
    ROUND((l.list_price * 0.80 * 0.065 / 12) /
          (1 - POWER(1 + 0.065/12, -360)), 0) AS estimated_monthly_payment,
    n.school_rating,
    n.crime_rate,
    n.walk_score
FROM properties p
JOIN cities c ON p.city_id = c.city_id
LEFT JOIN neighborhoods n ON p.neighborhood_id = n.neighborhood_id
JOIN listings l ON p.property_id = l.property_id
WHERE l.status = 'active'
  AND l.listing_type = 'for_sale'
  AND l.list_price <= 500000  -- Affordable price range
  AND p.bedrooms >= 2
  AND p.bathrooms >= 1
  AND (p.hoa_fee IS NULL OR p.hoa_fee <= 200)  -- Low or no HOA
  AND n.crime_rate < 5  -- Safe neighborhood
ORDER BY l.list_price ASC
LIMIT 30;

-- =========================================
-- 10. Market Heat Map Data
-- =========================================

-- Get property density and average prices by neighborhood
SELECT
    n.neighborhood_id,
    n.neighborhood_name,
    c.city_name,
    ST_X(n.center_point) AS center_longitude,
    ST_Y(n.center_point) AS center_latitude,
    COUNT(DISTINCT p.property_id) AS total_properties,
    COUNT(DISTINCT CASE WHEN l.status = 'active' THEN l.listing_id END) AS active_listings,
    AVG(CASE WHEN l.status = 'active' THEN l.list_price END) AS avg_list_price,
    MIN(CASE WHEN l.status = 'active' THEN l.list_price END) AS min_list_price,
    MAX(CASE WHEN l.status = 'active' THEN l.list_price END) AS max_list_price,
    AVG(CASE WHEN l.status = 'active' THEN l.price_per_sqft END) AS avg_price_per_sqft,
    AVG(CASE WHEN l.status = 'active' THEN l.days_on_market END) AS avg_days_on_market,
    n.median_home_price,
    n.walk_score,
    n.transit_score,
    n.school_rating
FROM neighborhoods n
JOIN cities c ON n.city_id = c.city_id
LEFT JOIN properties p ON p.neighborhood_id = n.neighborhood_id
LEFT JOIN listings l ON p.property_id = l.property_id
GROUP BY n.neighborhood_id
HAVING active_listings > 0
ORDER BY active_listings DESC;