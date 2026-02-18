-- ============================================================================
-- CONSTRAINTS FOR HOTEL CHAIN MANAGEMENT
-- ============================================================================

USE hotel_chain;

-- ============================================================================
-- CHECK CONSTRAINTS
-- ============================================================================

-- Properties table
ALTER TABLE properties
    ADD CONSTRAINT chk_properties_rating
    CHECK (star_rating IS NULL OR (star_rating >= 1 AND star_rating <= 5)),
    ADD CONSTRAINT chk_properties_rooms
    CHECK (total_rooms > 0),
    ADD CONSTRAINT chk_properties_floors
    CHECK (total_floors IS NULL OR total_floors > 0),
    ADD CONSTRAINT chk_properties_parking
    CHECK (parking_spaces >= 0),
    ADD CONSTRAINT chk_properties_cancellation
    CHECK (cancellation_hours >= 0);

-- Room types table
ALTER TABLE room_types
    ADD CONSTRAINT chk_room_types_occupancy
    CHECK (standard_occupancy > 0 AND max_occupancy >= standard_occupancy),
    ADD CONSTRAINT chk_room_types_capacity
    CHECK (max_adults > 0 AND max_children >= 0),
    ADD CONSTRAINT chk_room_types_beds
    CHECK (num_beds IS NULL OR num_beds > 0),
    ADD CONSTRAINT chk_room_types_size
    CHECK (size_sqft IS NULL OR size_sqft > 0),
    ADD CONSTRAINT chk_room_types_rates
    CHECK (base_rate > 0 AND extra_person_charge >= 0),
    ADD CONSTRAINT chk_room_types_inventory
    CHECK (total_rooms > 0);

-- Rooms table
ALTER TABLE rooms
    ADD CONSTRAINT chk_rooms_floor
    CHECK (floor >= 0);

-- Guests table
ALTER TABLE guests
    ADD CONSTRAINT chk_guests_loyalty_points
    CHECK (loyalty_points >= 0),
    ADD CONSTRAINT chk_guests_lifetime
    CHECK (lifetime_stays >= 0 AND lifetime_nights >= 0 AND lifetime_revenue >= 0);

-- Reservations table
ALTER TABLE reservations
    ADD CONSTRAINT chk_reservations_dates
    CHECK (check_out_date > check_in_date),
    ADD CONSTRAINT chk_reservations_occupancy
    CHECK (adults > 0 AND children >= 0 AND infants >= 0),
    ADD CONSTRAINT chk_reservations_rooms
    CHECK (num_rooms > 0),
    ADD CONSTRAINT chk_reservations_rates
    CHECK (room_rate > 0),
    ADD CONSTRAINT chk_reservations_amounts
    CHECK ((total_room_charges IS NULL OR total_room_charges >= 0) AND
           (total_taxes IS NULL OR total_taxes >= 0) AND
           (total_fees IS NULL OR total_fees >= 0) AND
           (total_amount IS NULL OR total_amount >= 0) AND
           (deposit_amount IS NULL OR deposit_amount >= 0)),
    ADD CONSTRAINT chk_reservations_commission
    CHECK (commission_rate IS NULL OR (commission_rate >= 0 AND commission_rate <= 100)),
    ADD CONSTRAINT chk_reservations_cancellation_fee
    CHECK (cancellation_fee IS NULL OR cancellation_fee >= 0);

-- Stays table
ALTER TABLE stays
    ADD CONSTRAINT chk_stays_room_moves
    CHECK (room_moves >= 0),
    ADD CONSTRAINT chk_stays_key_cards
    CHECK (key_cards_issued >= 0 AND key_cards_active >= 0 AND key_cards_active <= key_cards_issued);

-- Folios table
ALTER TABLE folios
    ADD CONSTRAINT chk_folios_amounts
    CHECK (total_charges >= 0 AND total_payments >= 0);

-- Folio transactions table
ALTER TABLE folio_transactions
    ADD CONSTRAINT chk_transactions_quantity
    CHECK (quantity > 0),
    ADD CONSTRAINT chk_transactions_amounts
    CHECK (tax_amount >= 0);

-- Housekeeping tasks table
ALTER TABLE housekeeping_tasks
    ADD CONSTRAINT chk_housekeeping_timing
    CHECK ((completed_at IS NULL OR started_at IS NULL OR completed_at >= started_at) AND
           (inspected_at IS NULL OR completed_at IS NULL OR inspected_at >= completed_at));

-- Staff schedules table
ALTER TABLE staff_schedules
    ADD CONSTRAINT chk_schedules_times
    CHECK (end_time != start_time);

-- Outlets table
ALTER TABLE outlets
    ADD CONSTRAINT chk_outlets_capacity
    CHECK (seating_capacity IS NULL OR seating_capacity > 0);

-- Event spaces table
ALTER TABLE event_spaces
    ADD CONSTRAINT chk_event_spaces_capacity
    CHECK ((max_capacity_theater IS NULL OR max_capacity_theater > 0) AND
           (max_capacity_classroom IS NULL OR max_capacity_classroom > 0) AND
           (max_capacity_banquet IS NULL OR max_capacity_banquet > 0) AND
           (max_capacity_cocktail IS NULL OR max_capacity_cocktail > 0)),
    ADD CONSTRAINT chk_event_spaces_size
    CHECK ((size_sqft IS NULL OR size_sqft > 0) AND
           (ceiling_height_ft IS NULL OR ceiling_height_ft > 0)),
    ADD CONSTRAINT chk_event_spaces_rates
    CHECK ((hourly_rate IS NULL OR hourly_rate > 0) AND
           (half_day_rate IS NULL OR half_day_rate > 0) AND
           (full_day_rate IS NULL OR full_day_rate > 0));

-- Event bookings table
ALTER TABLE event_bookings
    ADD CONSTRAINT chk_event_bookings_times
    CHECK (end_time > start_time),
    ADD CONSTRAINT chk_event_bookings_attendees
    CHECK (expected_attendees > 0 AND (guaranteed_attendees IS NULL OR guaranteed_attendees <= expected_attendees)),
    ADD CONSTRAINT chk_event_bookings_amounts
    CHECK ((space_rental IS NULL OR space_rental >= 0) AND
           (catering_charges IS NULL OR catering_charges >= 0) AND
           (equipment_charges IS NULL OR equipment_charges >= 0) AND
           (other_charges IS NULL OR other_charges >= 0) AND
           (total_amount IS NULL OR total_amount >= 0) AND
           (deposit_amount IS NULL OR deposit_amount >= 0));

-- Maintenance requests table
ALTER TABLE maintenance_requests
    ADD CONSTRAINT chk_maintenance_labor
    CHECK (labor_hours IS NULL OR labor_hours >= 0),
    ADD CONSTRAINT chk_maintenance_cost
    CHECK (total_cost IS NULL OR total_cost >= 0);

-- Rate plans table
ALTER TABLE rate_plans
    ADD CONSTRAINT chk_rate_plans_validity
    CHECK (valid_to IS NULL OR valid_from IS NULL OR valid_to >= valid_from),
    ADD CONSTRAINT chk_rate_plans_stay
    CHECK ((min_stay IS NULL OR min_stay > 0) AND
           (max_stay IS NULL OR max_stay >= min_stay)),
    ADD CONSTRAINT chk_rate_plans_booking
    CHECK (advance_booking_days IS NULL OR advance_booking_days >= 0),
    ADD CONSTRAINT chk_rate_plans_cancellation
    CHECK (cancellation_hours IS NULL OR cancellation_hours >= 0);

-- Dynamic rates table
ALTER TABLE dynamic_rates
    ADD CONSTRAINT chk_dynamic_rates_amounts
    CHECK ((single_rate IS NULL OR single_rate > 0) AND
           (double_rate IS NULL OR double_rate > 0) AND
           (triple_rate IS NULL OR triple_rate > 0) AND
           (quad_rate IS NULL OR quad_rate > 0) AND
           (extra_person_rate IS NULL OR extra_person_rate >= 0)),
    ADD CONSTRAINT chk_dynamic_rates_availability
    CHECK ((rooms_available IS NULL OR rooms_available >= 0) AND
           rooms_sold >= 0 AND
           (rooms_available IS NULL OR rooms_sold <= rooms_available)),
    ADD CONSTRAINT chk_dynamic_rates_stay
    CHECK (min_stay_through IS NULL OR min_stay_through > 0);

-- Daily statistics table
ALTER TABLE daily_statistics
    ADD CONSTRAINT chk_statistics_occupancy
    CHECK (rooms_occupied >= 0 AND rooms_occupied <= total_rooms AND
           occupancy_rate >= 0 AND occupancy_rate <= 100),
    ADD CONSTRAINT chk_statistics_revenue
    CHECK ((room_revenue IS NULL OR room_revenue >= 0) AND
           (fb_revenue IS NULL OR fb_revenue >= 0) AND
           (other_revenue IS NULL OR other_revenue >= 0) AND
           (total_revenue IS NULL OR total_revenue >= 0)),
    ADD CONSTRAINT chk_statistics_rates
    CHECK ((adr IS NULL OR adr >= 0) AND
           (revpar IS NULL OR revpar >= 0)),
    ADD CONSTRAINT chk_statistics_counts
    CHECK ((arrivals IS NULL OR arrivals >= 0) AND
           (departures IS NULL OR departures >= 0) AND
           (stay_overs IS NULL OR stay_overs >= 0) AND
           (total_guests IS NULL OR total_guests >= 0));

-- ============================================================================
-- UNIQUE CONSTRAINTS
-- ============================================================================

-- Ensure unique active room connections
ALTER TABLE rooms
    ADD CONSTRAINT uk_connecting_rooms
    CHECK (connecting_room_id != room_id);

-- ============================================================================
-- TRIGGERS FOR DATA INTEGRITY
-- ============================================================================

DELIMITER //

-- Generate confirmation number
CREATE TRIGGER trg_generate_confirmation_number
BEFORE INSERT ON reservations
FOR EACH ROW
BEGIN
    SET NEW.confirmation_number = CONCAT(
        UPPER(LEFT(UUID(), 8)),
        DATE_FORMAT(NOW(), '%Y%m')
    );
END//

-- Generate folio number
CREATE TRIGGER trg_generate_folio_number
BEFORE INSERT ON folios
FOR EACH ROW
BEGIN
    SET NEW.folio_number = CONCAT(
        'F',
        DATE_FORMAT(NOW(), '%Y%m%d'),
        LPAD(FLOOR(RAND() * 9999), 4, '0')
    );
END//

-- Update room status on check-in
CREATE TRIGGER trg_checkin_room_status
AFTER INSERT ON stays
FOR EACH ROW
BEGIN
    IF NEW.actual_check_in IS NOT NULL THEN
        UPDATE rooms
        SET status = 'occupied'
        WHERE room_id = NEW.room_id;

        UPDATE reservations
        SET status = 'checked_in'
        WHERE reservation_id = NEW.reservation_id;
    END IF;
END//

-- Update room status on check-out
CREATE TRIGGER trg_checkout_room_status
AFTER UPDATE ON stays
FOR EACH ROW
BEGIN
    IF OLD.actual_check_out IS NULL AND NEW.actual_check_out IS NOT NULL THEN
        UPDATE rooms
        SET status = 'available',
            housekeeping_status = 'dirty'
        WHERE room_id = NEW.room_id;

        UPDATE reservations
        SET status = 'checked_out'
        WHERE reservation_id = NEW.reservation_id;
    END IF;
END//

-- Update folio totals on transaction
CREATE TRIGGER trg_update_folio_totals
AFTER INSERT ON folio_transactions
FOR EACH ROW
BEGIN
    IF NEW.transaction_type = 'charge' THEN
        UPDATE folios
        SET total_charges = total_charges + NEW.amount + NEW.tax_amount
        WHERE folio_id = NEW.folio_id;
    ELSEIF NEW.transaction_type = 'payment' THEN
        UPDATE folios
        SET total_payments = total_payments + NEW.amount
        WHERE folio_id = NEW.folio_id;
    END IF;
END//

-- Update guest loyalty points on stay completion
CREATE TRIGGER trg_update_loyalty_points
AFTER UPDATE ON reservations
FOR EACH ROW
BEGIN
    DECLARE points_earned INT;

    IF OLD.status != 'checked_out' AND NEW.status = 'checked_out' AND NEW.guest_id IS NOT NULL THEN
        -- Calculate points (1 point per dollar spent)
        SET points_earned = FLOOR(NEW.total_amount);

        -- Update guest profile
        UPDATE guests
        SET loyalty_points = loyalty_points + points_earned,
            lifetime_stays = lifetime_stays + 1,
            lifetime_nights = lifetime_nights + NEW.nights,
            lifetime_revenue = lifetime_revenue + NEW.total_amount
        WHERE guest_id = NEW.guest_id;

        -- Create loyalty transaction
        INSERT INTO loyalty_transactions (guest_id, transaction_type, points,
                                         reference_type, reference_id, description, status)
        VALUES (NEW.guest_id, 'earn', points_earned,
                'stay', NEW.reservation_id,
                CONCAT('Stay at property #', NEW.property_id), 'confirmed');
    END IF;
END//

-- Update guest loyalty tier based on lifetime stays
CREATE TRIGGER trg_update_loyalty_tier
AFTER UPDATE ON guests
FOR EACH ROW
BEGIN
    IF OLD.lifetime_nights != NEW.lifetime_nights THEN
        UPDATE guests
        SET loyalty_tier = CASE
            WHEN lifetime_nights >= 100 THEN 'diamond'
            WHEN lifetime_nights >= 50 THEN 'platinum'
            WHEN lifetime_nights >= 25 THEN 'gold'
            WHEN lifetime_nights >= 10 THEN 'silver'
            ELSE 'basic'
        END
        WHERE guest_id = NEW.guest_id;
    END IF;
END//

-- Auto-create housekeeping task on checkout
CREATE TRIGGER trg_create_housekeeping_checkout
AFTER UPDATE ON rooms
FOR EACH ROW
BEGIN
    IF OLD.status = 'occupied' AND NEW.status = 'available' THEN
        INSERT INTO housekeeping_tasks (property_id, room_id, task_type, priority, scheduled_date, status)
        VALUES (NEW.property_id, NEW.room_id, 'checkout_clean', 'high', CURDATE(), 'pending');
    END IF;
END//

-- Update room housekeeping status on task completion
CREATE TRIGGER trg_update_room_housekeeping
AFTER UPDATE ON housekeeping_tasks
FOR EACH ROW
BEGIN
    IF OLD.status != 'completed' AND NEW.status = 'completed' THEN
        UPDATE rooms
        SET housekeeping_status = 'clean',
            last_cleaned_at = NEW.completed_at
        WHERE room_id = NEW.room_id;
    ELSEIF OLD.status != 'inspected' AND NEW.status = 'inspected' THEN
        UPDATE rooms
        SET housekeeping_status = 'inspected',
            last_inspected_at = NEW.inspected_at
        WHERE room_id = NEW.room_id;
    END IF;
END//

-- Update dynamic rates availability
CREATE TRIGGER trg_update_availability
AFTER UPDATE ON reservations
FOR EACH ROW
BEGIN
    IF OLD.status = 'confirmed' AND NEW.status = 'cancelled' THEN
        -- Increase availability
        UPDATE dynamic_rates
        SET rooms_available = rooms_available + NEW.num_rooms,
            rooms_sold = rooms_sold - NEW.num_rooms
        WHERE property_id = NEW.property_id
          AND room_type_id = NEW.room_type_id
          AND rate_date BETWEEN NEW.check_in_date AND DATE_SUB(NEW.check_out_date, INTERVAL 1 DAY);
    ELSEIF OLD.status = 'pending' AND NEW.status = 'confirmed' THEN
        -- Decrease availability
        UPDATE dynamic_rates
        SET rooms_available = rooms_available - NEW.num_rooms,
            rooms_sold = rooms_sold + NEW.num_rooms
        WHERE property_id = NEW.property_id
          AND room_type_id = NEW.room_type_id
          AND rate_date BETWEEN NEW.check_in_date AND DATE_SUB(NEW.check_out_date, INTERVAL 1 DAY);
    END IF;
END//

DELIMITER ;

-- ============================================================================
-- EVENTS FOR AUTOMATED TASKS
-- ============================================================================

DELIMITER //

-- Daily housekeeping task generation for stayovers
CREATE EVENT IF NOT EXISTS evt_generate_stayover_cleaning
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_DATE + INTERVAL 1 DAY + INTERVAL 6 HOUR
DO
BEGIN
    INSERT INTO housekeeping_tasks (property_id, room_id, task_type, priority, scheduled_date, status)
    SELECT r.property_id, r.room_id, 'stayover_clean', 'normal', CURDATE(), 'pending'
    FROM rooms r
    JOIN stays s ON r.room_id = s.room_id
    WHERE r.status = 'occupied'
      AND s.actual_check_in < CURDATE()
      AND s.actual_check_out IS NULL
      AND NOT EXISTS (
          SELECT 1 FROM housekeeping_tasks ht
          WHERE ht.room_id = r.room_id
            AND ht.scheduled_date = CURDATE()
            AND ht.task_type = 'stayover_clean'
      );
END//

-- Auto no-show for reservations not checked in by midnight
CREATE EVENT IF NOT EXISTS evt_process_no_shows
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_DATE + INTERVAL 1 DAY + INTERVAL 1 MINUTE
DO
BEGIN
    UPDATE reservations
    SET status = 'no_show'
    WHERE status = 'confirmed'
      AND check_in_date = DATE_SUB(CURDATE(), INTERVAL 1 DAY)
      AND reservation_id NOT IN (SELECT reservation_id FROM stays);
END//

-- Calculate daily statistics
CREATE EVENT IF NOT EXISTS evt_calculate_daily_stats
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_DATE + INTERVAL 1 DAY + INTERVAL 2 HOUR
DO
BEGIN
    INSERT INTO daily_statistics (property_id, stat_date, total_rooms, rooms_occupied,
                                 occupancy_rate, room_revenue, adr, revpar,
                                 arrivals, departures, stay_overs, total_guests)
    SELECT
        p.property_id,
        DATE_SUB(CURDATE(), INTERVAL 1 DAY) as stat_date,
        p.total_rooms,
        COUNT(DISTINCT CASE WHEN r.status = 'occupied' THEN r.room_id END) as rooms_occupied,
        COUNT(DISTINCT CASE WHEN r.status = 'occupied' THEN r.room_id END) * 100.0 / p.total_rooms as occupancy_rate,
        COALESCE(SUM(res.room_rate), 0) as room_revenue,
        AVG(res.room_rate) as adr,
        COALESCE(SUM(res.room_rate), 0) / p.total_rooms as revpar,
        COUNT(DISTINCT CASE WHEN res.check_in_date = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN res.reservation_id END) as arrivals,
        COUNT(DISTINCT CASE WHEN res.check_out_date = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN res.reservation_id END) as departures,
        COUNT(DISTINCT CASE WHEN res.check_in_date < DATE_SUB(CURDATE(), INTERVAL 1 DAY)
                             AND res.check_out_date > DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN res.reservation_id END) as stay_overs,
        SUM(res.adults + res.children) as total_guests
    FROM properties p
    LEFT JOIN rooms r ON p.property_id = r.property_id
    LEFT JOIN reservations res ON r.room_id = res.room_id
        AND res.status IN ('checked_in', 'checked_out')
        AND DATE_SUB(CURDATE(), INTERVAL 1 DAY) BETWEEN res.check_in_date AND DATE_SUB(res.check_out_date, INTERVAL 1 DAY)
    WHERE p.status = 'active'
    GROUP BY p.property_id
    ON DUPLICATE KEY UPDATE
        rooms_occupied = VALUES(rooms_occupied),
        occupancy_rate = VALUES(occupancy_rate),
        room_revenue = VALUES(room_revenue),
        adr = VALUES(adr),
        revpar = VALUES(revpar);
END//

-- Expire loyalty points older than 2 years
CREATE EVENT IF NOT EXISTS evt_expire_loyalty_points
ON SCHEDULE EVERY 1 MONTH
STARTS CURRENT_DATE + INTERVAL 1 MONTH + INTERVAL 3 HOUR
DO
BEGIN
    UPDATE loyalty_transactions
    SET status = 'expired'
    WHERE status = 'confirmed'
      AND transaction_type = 'earn'
      AND expiry_date IS NOT NULL
      AND expiry_date < CURDATE();

    -- Deduct expired points from guest accounts
    UPDATE guests g
    SET loyalty_points = loyalty_points - (
        SELECT COALESCE(SUM(points), 0)
        FROM loyalty_transactions lt
        WHERE lt.guest_id = g.guest_id
          AND lt.status = 'expired'
          AND lt.expiry_date >= DATE_SUB(CURDATE(), INTERVAL 1 DAY)
          AND lt.expiry_date < CURDATE()
    );
END//

-- Auto-close completed maintenance requests
CREATE EVENT IF NOT EXISTS evt_close_maintenance_requests
ON SCHEDULE EVERY 1 DAY
DO
BEGIN
    UPDATE maintenance_requests
    SET status = 'closed'
    WHERE status = 'completed'
      AND completed_date < DATE_SUB(NOW(), INTERVAL 7 DAY);
END//

-- Clean up old lost and found items
CREATE EVENT IF NOT EXISTS evt_dispose_lost_items
ON SCHEDULE EVERY 1 MONTH
DO
BEGIN
    UPDATE lost_and_found
    SET status = 'disposed',
        disposal_date = CURDATE()
    WHERE status = 'logged'
      AND found_date < DATE_SUB(CURDATE(), INTERVAL 90 DAY);
END//

DELIMITER ;