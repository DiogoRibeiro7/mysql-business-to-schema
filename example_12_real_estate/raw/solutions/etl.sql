-- ETL from raw denormalized table into normalized tables
USE real_estate;

INSERT INTO dim_listing (id, status, created_at, updated_at)
SELECT DISTINCT r.listing_id, r.listing_status, NOW(), NOW()
FROM raw_property_feed r;

INSERT INTO dim_agent (full_name, first_name, last_name, created_at, updated_at)
SELECT DISTINCT r.agent_name, SUBSTRING_INDEX(r.agent_name, ' ', 1), CASE WHEN INSTR(r.agent_name, ' ') > 0 THEN SUBSTRING(r.agent_name, INSTR(r.agent_name, ' ') + 1) ELSE '' END, NOW(), NOW()
FROM raw_property_feed r;

INSERT INTO fact_property_feed (listing_id, agent_id, source_row_id, address, city, state, price, beds, baths, agency_name, created_at, updated_at)
SELECT
    d_listing.listing_id,
    d_agent.agent_id,
    r.row_id,
    r.address,
    r.city,
    r.state,
    r.price,
    r.beds,
    r.baths,
    r.agency_name,
    NOW(),
    NOW()
FROM raw_property_feed r
LEFT JOIN dim_listing d_listing ON r.listing_id <=> d_listing.id AND r.listing_status <=> d_listing.status
LEFT JOIN dim_agent d_agent ON r.agent_name <=> d_agent.full_name AND SUBSTRING_INDEX(r.agent_name, ' ', 1) <=> d_agent.first_name AND CASE WHEN INSTR(r.agent_name, ' ') > 0 THEN SUBSTRING(r.agent_name, INSTR(r.agent_name, ' ') + 1) ELSE '' END <=> d_agent.last_name
;
