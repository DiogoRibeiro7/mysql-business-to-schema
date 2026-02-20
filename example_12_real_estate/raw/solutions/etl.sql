-- ETL from raw denormalized table into normalized tables
USE real_estate;

INSERT INTO dim_listing (id, status)
SELECT DISTINCT r.listing_id, r.listing_status
FROM raw_property_feed r;

INSERT INTO dim_agent (name)
SELECT DISTINCT r.agent_name
FROM raw_property_feed r;

INSERT INTO fact_property_feed (listing_id, agent_id, address, city, state, price, beds, baths, agency_name)
SELECT
    d_listing.listing_id,
    d_agent.agent_id,
    r.address,
    r.city,
    r.state,
    r.price,
    r.beds,
    r.baths,
    r.agency_name
FROM raw_property_feed r
LEFT JOIN dim_listing d_listing ON r.listing_id <=> d_listing.id AND r.listing_status <=> d_listing.status
LEFT JOIN dim_agent d_agent ON r.agent_name <=> d_agent.name
;
