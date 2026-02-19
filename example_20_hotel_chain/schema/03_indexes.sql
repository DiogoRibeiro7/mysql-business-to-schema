-- ============================================================================
-- INDEXES FOR HOTEL CHAIN MANAGEMENT DATABASE
-- ============================================================================

USE hotel_chain;

-- ============================================================================
-- PERFORMANCE INDEXES
-- ============================================================================

-- Properties table - optimize for chain management
CREATE INDEX idx_properties_brand ON properties(brand, status);
CREATE INDEX idx_properties_location ON properties(country, state_province, city);
CREATE INDEX idx_properties_rating ON properties(star_rating, status);
-- Room types - optimize for inventory management
CREATE INDEX idx_room_types_property ON room_types(property_id, is_active);

-- Rooms table - optimize for availability searches
CREATE INDEX idx_rooms_property_status ON rooms(property_id, status);

-- Guests table - optimize for guest lookups
CREATE INDEX idx_guests_email ON guests(email);
CREATE INDEX idx_guests_created ON guests(created_at DESC);
CREATE INDEX idx_guests_vip ON guests(vip_status);

-- Reservations table - optimize for booking operations
CREATE INDEX idx_reservations_property_dates ON reservations(property_id, check_in_date, check_out_date);
CREATE INDEX idx_reservations_guest ON reservations(guest_id, status);
CREATE INDEX idx_reservations_status_dates ON reservations(status, check_in_date);
CREATE INDEX idx_reservations_confirmation ON reservations(confirmation_number);
CREATE INDEX idx_reservations_arrival ON reservations(check_in_date, status);

-- Room assignments - optimize for room allocation

-- Folios table - optimize for billing operations
CREATE INDEX idx_folios_reservation ON folios(reservation_id, status);
CREATE INDEX idx_folios_checkout ON folios(status, created_at);

-- Folio charges - optimize for charge lookups

-- Payments table - optimize for payment processing

-- Loyalty members - optimize for loyalty program

-- Loyalty transactions - optimize for points management

-- Staff table - optimize for workforce management
CREATE INDEX idx_staff_property_dept ON staff(property_id, department);

-- Staff schedules - optimize for scheduling

-- Housekeeping tasks - optimize for task management
CREATE INDEX idx_housekeeping_room ON housekeeping_tasks(room_id, status, scheduled_date);
CREATE INDEX idx_housekeeping_assigned ON housekeeping_tasks(assigned_to, status, priority);
CREATE INDEX idx_housekeeping_pending ON housekeeping_tasks(status, priority DESC, scheduled_date);

-- Maintenance requests - optimize for maintenance tracking
CREATE INDEX idx_maintenance_room ON maintenance_requests(room_id, status);
CREATE INDEX idx_maintenance_priority ON maintenance_requests(priority DESC, status, reported_date);
CREATE INDEX idx_maintenance_assigned ON maintenance_requests(assigned_to, status);

-- Restaurant reservations - optimize for dining management

-- Event bookings - optimize for event management
CREATE INDEX idx_events_property_dates ON event_bookings(property_id, event_date, status);
CREATE INDEX idx_events_upcoming ON event_bookings(event_date, status);

-- Spa appointments - optimize for spa scheduling

-- Guest requests - optimize for service management

-- Rate plans - optimize for revenue management
CREATE INDEX idx_rate_plans_property ON rate_plans(property_id, is_active);
CREATE INDEX idx_rate_plans_dates ON rate_plans(valid_from, valid_to, is_active);

-- Rate overrides - optimize for dynamic pricing

-- ============================================================================
-- COMPOSITE INDEXES FOR COMPLEX QUERIES
-- ============================================================================

-- Room availability search (most critical query)
CREATE INDEX idx_room_availability
    ON rooms(property_id, room_type_id, status);

-- Arrival report
CREATE INDEX idx_arrivals_today ON reservations(property_id, check_in_date, status, arrival_time);

-- Departure report
CREATE INDEX idx_departures_today ON reservations(property_id, check_out_date, status);

-- Occupancy calculation

-- Revenue reporting

-- Guest history
CREATE INDEX idx_guest_history ON reservations(guest_id, check_in_date DESC, property_id);

-- Housekeeping workload
CREATE INDEX idx_housekeeping_workload ON housekeeping_tasks(property_id, scheduled_date, status, assigned_to);

-- Loyalty points expiration

-- Group bookings

-- VIP guests
CREATE INDEX idx_vip_arrivals
    ON reservations(check_in_date, property_id, guest_id);

-- ============================================================================
-- ============================================================================

-- Property location searches

-- ============================================================================
-- FULL-TEXT INDEXES
-- ============================================================================

-- Guest search
ALTER TABLE guests ADD FULLTEXT ft_guests_search
    (first_name, last_name, email, company_name);

-- Reservation notes search
ALTER TABLE reservations ADD FULLTEXT ft_reservations_notes
    (special_requests, internal_notes);

-- Maintenance request search
ALTER TABLE maintenance_requests ADD FULLTEXT ft_maintenance_search
    (description, resolution_notes);

-- Guest request search

-- Event booking search
ALTER TABLE event_bookings ADD FULLTEXT ft_events_search
    (event_name, organizer_name, special_requirements);

-- ============================================================================
-- STATISTICS UPDATE
-- ============================================================================

-- Update table statistics for query optimizer
ANALYZE TABLE properties;
ANALYZE TABLE rooms;
ANALYZE TABLE guests;
ANALYZE TABLE reservations;
ANALYZE TABLE folios;
ANALYZE TABLE loyalty_transactions;
ANALYZE TABLE staff;
ANALYZE TABLE staff_schedules;
ANALYZE TABLE housekeeping_tasks;
ANALYZE TABLE maintenance_requests;

-- ============================================================================
-- INDEX HINTS FOR COMMON QUERIES
-- ============================================================================

/*
Common Query Patterns and Their Indexes:

1. Room availability search:
   Uses: idx_room_availability, idx_rooms_property_status

2. Today's arrivals:
   Uses: idx_arrivals_today

3. Today's departures:
   Uses: idx_departures_today

4. Guest lookup by email:
   Uses: idx_guests_email

5. Reservation lookup by confirmation:
   Uses: idx_reservations_confirmation

6. Outstanding folios:
   Uses: idx_folios_outstanding

7. Housekeeping task queue:
   Uses: idx_housekeeping_pending

8. Maintenance priorities:
   Uses: idx_maintenance_priority

9. Revenue by date range:
   Uses: idx_revenue_reporting

10. Occupancy calculation:
    Uses: idx_occupancy

11. Loyalty point expiration:
    Uses: idx_loyalty_expiration

12. VIP arrivals:
    Uses: idx_vip_arrivals

13. Group booking management:
    Uses: idx_group_bookings

14. Staff scheduling:
    Uses: idx_schedules_property_date

15. Restaurant availability:
    Uses: idx_dining_outlet_date

16. Event calendar:
    Uses: idx_events_upcoming

17. Spa scheduling:
    Uses: idx_spa_therapist_date

18. Guest request queue:
    Uses: idx_requests_pending

19. Rate management:
    Uses: idx_rate_plans_dates, idx_rate_overrides_dates

20. Guest history/profile:
    Uses: idx_guest_history
*/

-- ============================================================================
-- PERFORMANCE OPTIMIZATION NOTES
-- ============================================================================

/*
Key Performance Considerations:

1. Room Availability: Most critical query, heavily optimized with composite indexes
2. Daily Operations: Separate indexes for arrivals/departures for fast daily reports
3. Billing: Optimized for quick folio lookups and outstanding balance checks
4. Housekeeping: Priority-based indexes for efficient task distribution
5. Guest Service: Fast lookup by email, phone, and loyalty number
6. Revenue Management: Date-based indexes for financial reporting
7. Spatial Queries: Geographic searches for nearby properties
8. Full-Text Search: Comprehensive guest and reservation searches

Maintenance Schedule:
- Run ANALYZE TABLE weekly during low-traffic hours
- Monitor index usage with performance_schema
- Consider partitioning large tables (reservations, folio_charges) by date
- Archive old data (>2 years) to maintain performance
*/
