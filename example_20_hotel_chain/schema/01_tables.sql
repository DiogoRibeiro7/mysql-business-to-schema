-- ============================================================================
-- CORE TABLES FOR HOTEL CHAIN MANAGEMENT
-- ============================================================================

USE hotel_chain;

-- ============================================================================
-- PROPERTY MANAGEMENT
-- ============================================================================

-- Hotel properties in the chain
CREATE TABLE properties (
    property_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    property_code VARCHAR(10) NOT NULL,
    property_name VARCHAR(255) NOT NULL,
    brand ENUM('luxury', 'premium', 'select', 'economy') NOT NULL,
    property_type ENUM('hotel', 'resort', 'boutique', 'extended_stay') NOT NULL,

    -- Location
    address_line1 VARCHAR(255) NOT NULL,
    address_line2 VARCHAR(255),
    city VARCHAR(100) NOT NULL,
    state_province VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(2) NOT NULL,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    timezone VARCHAR(50) NOT NULL,

    -- Contact
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(255) NOT NULL,
    website VARCHAR(255),

    -- Property Details
    star_rating DECIMAL(2,1),
    total_rooms INT NOT NULL,
    total_floors INT,
    year_built YEAR,
    last_renovation YEAR,

    -- Facilities
    has_restaurant BOOLEAN DEFAULT FALSE,
    has_bar BOOLEAN DEFAULT FALSE,
    has_spa BOOLEAN DEFAULT FALSE,
    has_gym BOOLEAN DEFAULT FALSE,
    has_pool BOOLEAN DEFAULT FALSE,
    has_business_center BOOLEAN DEFAULT FALSE,
    has_conference_rooms BOOLEAN DEFAULT FALSE,
    parking_spaces INT DEFAULT 0,

    -- Policies
    check_in_time TIME DEFAULT '15:00:00',
    check_out_time TIME DEFAULT '11:00:00',
    cancellation_hours INT DEFAULT 24,
    pets_allowed BOOLEAN DEFAULT FALSE,
    smoking_allowed BOOLEAN DEFAULT FALSE,

    -- Status
    status ENUM('active', 'renovation', 'closed', 'seasonal') DEFAULT 'active',

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (property_id),
    UNIQUE KEY uk_property_code (property_code),
    INDEX idx_brand (brand),
    INDEX idx_location (country, state_province, city),
    INDEX idx_status (status)
) ENGINE=InnoDB;

-- ============================================================================
-- ROOM MANAGEMENT
-- ============================================================================

-- Room types configuration
CREATE TABLE room_types (
    room_type_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    property_id INT UNSIGNED NOT NULL,

    -- Room Type Information
    type_code VARCHAR(20) NOT NULL,
    type_name VARCHAR(100) NOT NULL,
    description TEXT,

    -- Capacity
    standard_occupancy INT NOT NULL,
    max_occupancy INT NOT NULL,
    max_adults INT NOT NULL,
    max_children INT NOT NULL,

    -- Size and Features
    size_sqft INT,
    bed_type VARCHAR(100), -- 'King', 'Queen', 'Twin', etc
    num_beds INT DEFAULT 1,
    view_type ENUM('ocean', 'garden', 'city', 'mountain', 'pool', 'standard'),

    -- Amenities (as JSON for flexibility)
    amenities JSON,

    -- Pricing
    base_rate DECIMAL(10,2) NOT NULL,
    extra_person_charge DECIMAL(10,2) DEFAULT 0,

    -- Inventory
    total_rooms INT NOT NULL,

    -- Status
    is_active BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (room_type_id),
    UNIQUE KEY uk_property_type_code (property_id, type_code),
    INDEX idx_property (property_id),
    FOREIGN KEY (property_id) REFERENCES properties(property_id)
) ENGINE=InnoDB;

-- Individual rooms
CREATE TABLE rooms (
    room_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    property_id INT UNSIGNED NOT NULL,
    room_type_id INT UNSIGNED NOT NULL,

    -- Room Identification
    room_number VARCHAR(20) NOT NULL,
    floor INT NOT NULL,
    building VARCHAR(50), -- For resorts with multiple buildings

    -- Status
    status ENUM('available', 'occupied', 'maintenance', 'blocked', 'out_of_order') DEFAULT 'available',
    housekeeping_status ENUM('clean', 'dirty', 'inspected', 'in_progress', 'do_not_disturb') DEFAULT 'clean',

    -- Features
    is_connecting BOOLEAN DEFAULT FALSE,
    connecting_room_id BIGINT UNSIGNED,
    is_accessible BOOLEAN DEFAULT FALSE, -- ADA compliant

    -- Notes
    internal_notes TEXT,

    -- Last Service
    last_cleaned_at TIMESTAMP NULL,
    last_inspected_at TIMESTAMP NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (room_id),
    UNIQUE KEY uk_property_room_number (property_id, room_number),
    INDEX idx_property_status (property_id, status),
    INDEX idx_room_type (room_type_id),
    INDEX idx_housekeeping (property_id, housekeeping_status),
    FOREIGN KEY (property_id) REFERENCES properties(property_id),
    FOREIGN KEY (room_type_id) REFERENCES room_types(room_type_id),
    FOREIGN KEY (connecting_room_id) REFERENCES rooms(room_id)
) ENGINE=InnoDB;

-- ============================================================================
-- GUEST MANAGEMENT
-- ============================================================================

-- Guest profiles
CREATE TABLE guests (
    guest_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    -- Personal Information
    title ENUM('Mr', 'Ms', 'Mrs', 'Dr', 'Prof'),
    first_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE,
    gender ENUM('male', 'female', 'other'),
    nationality VARCHAR(2),

    -- Contact Information
    email VARCHAR(255),
    phone VARCHAR(20),
    mobile VARCHAR(20),

    -- Address
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    state_province VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(2),

    -- Identification
    id_type ENUM('passport', 'drivers_license', 'national_id'),
    id_number VARCHAR(50),
    id_country VARCHAR(2),
    id_expiry DATE,

    -- Preferences
    language_preference VARCHAR(5) DEFAULT 'en',
    currency_preference VARCHAR(3) DEFAULT 'USD',
    room_preferences JSON, -- Floor, bed type, smoking, etc
    dietary_restrictions JSON,
    special_requests TEXT,

    -- Loyalty Program
    loyalty_number VARCHAR(50),
    loyalty_tier ENUM('basic', 'silver', 'gold', 'platinum', 'diamond') DEFAULT 'basic',
    loyalty_points INT DEFAULT 0,
    lifetime_stays INT DEFAULT 0,
    lifetime_nights INT DEFAULT 0,
    lifetime_revenue DECIMAL(15,2) DEFAULT 0,

    -- Marketing
    newsletter_subscribed BOOLEAN DEFAULT FALSE,
    marketing_consent BOOLEAN DEFAULT FALSE,

    -- Company Information
    company_name VARCHAR(255),
    company_tax_id VARCHAR(50),

    -- Status
    vip_status BOOLEAN DEFAULT FALSE,
    blacklisted BOOLEAN DEFAULT FALSE,
    blacklist_reason TEXT,

    -- Account
    password_hash VARCHAR(255), -- For online accounts
    last_login TIMESTAMP NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (guest_id),
    UNIQUE KEY uk_email (email),
    UNIQUE KEY uk_loyalty_number (loyalty_number),
    INDEX idx_name (last_name, first_name),
    INDEX idx_phone (phone),
    INDEX idx_nationality (nationality),
    INDEX idx_loyalty_tier (loyalty_tier),
    INDEX idx_company (company_name)
) ENGINE=InnoDB;

-- ============================================================================
-- RESERVATION MANAGEMENT
-- ============================================================================

-- Reservations
CREATE TABLE reservations (
    reservation_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    confirmation_number VARCHAR(20) NOT NULL,
    property_id INT UNSIGNED NOT NULL,

    -- Guest Information
    guest_id BIGINT UNSIGNED,
    guest_name VARCHAR(255) NOT NULL, -- Denormalized for quick access
    guest_email VARCHAR(255),
    guest_phone VARCHAR(20),

    -- Room Information
    room_type_id INT UNSIGNED NOT NULL,
    room_id BIGINT UNSIGNED, -- Assigned at check-in
    num_rooms INT DEFAULT 1,

    -- Dates
    check_in_date DATE NOT NULL,
    check_out_date DATE NOT NULL,
    nights INT GENERATED ALWAYS AS (DATEDIFF(check_out_date, check_in_date)) STORED,

    -- Occupancy
    adults INT NOT NULL,
    children INT DEFAULT 0,
    infants INT DEFAULT 0,

    -- Rates
    rate_plan_id INT UNSIGNED,
    room_rate DECIMAL(10,2) NOT NULL,
    total_room_charges DECIMAL(10,2),
    total_taxes DECIMAL(10,2),
    total_fees DECIMAL(10,2),
    total_amount DECIMAL(10,2),
    currency VARCHAR(3) DEFAULT 'USD',

    -- Status
    status ENUM('confirmed', 'pending', 'checked_in', 'checked_out', 'cancelled', 'no_show') DEFAULT 'pending',

    -- Channel Information
    booking_source ENUM('direct', 'website', 'phone', 'walk_in', 'ota', 'corporate', 'group') DEFAULT 'direct',
    channel_name VARCHAR(100), -- OTA name if applicable
    channel_reference VARCHAR(100),
    commission_rate DECIMAL(5,2),

    -- Payment
    payment_method ENUM('credit_card', 'debit_card', 'cash', 'check', 'wire', 'corporate_account'),
    payment_status ENUM('pending', 'authorized', 'partial', 'paid', 'refunded') DEFAULT 'pending',
    deposit_amount DECIMAL(10,2),

    -- Special Requests
    special_requests TEXT,
    arrival_time TIME,

    -- Group/Corporate
    group_id BIGINT UNSIGNED,
    company_id BIGINT UNSIGNED,
    travel_agent_id BIGINT UNSIGNED,

    -- Cancellation
    is_cancelled BOOLEAN DEFAULT FALSE,
    cancelled_at TIMESTAMP NULL,
    cancellation_reason TEXT,
    cancellation_fee DECIMAL(10,2),

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (reservation_id),
    UNIQUE KEY uk_confirmation_number (confirmation_number),
    INDEX idx_property_dates (property_id, check_in_date, check_out_date),
    INDEX idx_guest (guest_id),
    INDEX idx_status (status),
    INDEX idx_check_in (check_in_date, status),
    INDEX idx_room_type (room_type_id),
    INDEX idx_room (room_id),
    FOREIGN KEY (property_id) REFERENCES properties(property_id),
    FOREIGN KEY (guest_id) REFERENCES guests(guest_id),
    FOREIGN KEY (room_type_id) REFERENCES room_types(room_type_id),
    FOREIGN KEY (room_id) REFERENCES rooms(room_id)
) ENGINE=InnoDB;

-- Check-in/Check-out records
CREATE TABLE stays (
    stay_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    reservation_id BIGINT UNSIGNED NOT NULL,
    guest_id BIGINT UNSIGNED NOT NULL,
    room_id BIGINT UNSIGNED NOT NULL,

    -- Check-in Details
    actual_check_in TIMESTAMP NULL,
    checked_in_by BIGINT UNSIGNED, -- Staff member

    -- Check-out Details
    actual_check_out TIMESTAMP NULL,
    checked_out_by BIGINT UNSIGNED,
    late_check_out BOOLEAN DEFAULT FALSE,

    -- Stay Details
    room_moves INT DEFAULT 0,

    -- Keys
    key_cards_issued INT DEFAULT 0,
    key_cards_active INT DEFAULT 0,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (stay_id),
    UNIQUE KEY uk_reservation (reservation_id),
    INDEX idx_guest (guest_id),
    INDEX idx_room (room_id),
    INDEX idx_check_in (actual_check_in),
    FOREIGN KEY (reservation_id) REFERENCES reservations(reservation_id),
    FOREIGN KEY (guest_id) REFERENCES guests(guest_id),
    FOREIGN KEY (room_id) REFERENCES rooms(room_id)
) ENGINE=InnoDB;

-- ============================================================================
-- BILLING AND CHARGES
-- ============================================================================

-- Guest folios
CREATE TABLE folios (
    folio_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    reservation_id BIGINT UNSIGNED NOT NULL,
    folio_number VARCHAR(20) NOT NULL,

    -- Folio Type
    folio_type ENUM('master', 'split', 'incidental', 'group') DEFAULT 'master',

    -- Billing Information
    bill_to_name VARCHAR(255),
    bill_to_address TEXT,
    bill_to_tax_id VARCHAR(50),

    -- Totals
    total_charges DECIMAL(10,2) DEFAULT 0,
    total_payments DECIMAL(10,2) DEFAULT 0,
    balance DECIMAL(10,2) GENERATED ALWAYS AS (total_charges - total_payments) STORED,

    -- Status
    status ENUM('open', 'closed', 'settled', 'disputed') DEFAULT 'open',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    closed_at TIMESTAMP NULL,

    PRIMARY KEY (folio_id),
    UNIQUE KEY uk_folio_number (folio_number),
    INDEX idx_reservation (reservation_id),
    INDEX idx_status (status),
    FOREIGN KEY (reservation_id) REFERENCES reservations(reservation_id)
) ENGINE=InnoDB;

-- Folio transactions
CREATE TABLE folio_transactions (
    transaction_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    folio_id BIGINT UNSIGNED NOT NULL,

    -- Transaction Details
    transaction_date DATE NOT NULL,
    transaction_time TIME NOT NULL,
    transaction_type ENUM('charge', 'payment', 'adjustment', 'transfer') NOT NULL,

    -- Category and Description
    category VARCHAR(50), -- 'Room', 'Food', 'Beverage', 'Spa', etc
    description VARCHAR(255) NOT NULL,
    reference VARCHAR(100),

    -- Amounts
    quantity INT DEFAULT 1,
    unit_price DECIMAL(10,2),
    amount DECIMAL(10,2) NOT NULL,
    tax_amount DECIMAL(10,2) DEFAULT 0,

    -- Department/Outlet
    department_id INT UNSIGNED,
    outlet_id INT UNSIGNED,

    -- Staff
    posted_by BIGINT UNSIGNED,

    -- Reversal
    is_reversed BOOLEAN DEFAULT FALSE,
    reversal_reason TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (transaction_id),
    INDEX idx_folio (folio_id),
    INDEX idx_date (transaction_date),
    INDEX idx_type (transaction_type),
    INDEX idx_category (category),
    FOREIGN KEY (folio_id) REFERENCES folios(folio_id)
) ENGINE=InnoDB;

-- ============================================================================
-- HOUSEKEEPING MANAGEMENT
-- ============================================================================

-- Housekeeping tasks
CREATE TABLE housekeeping_tasks (
    task_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    property_id INT UNSIGNED NOT NULL,
    room_id BIGINT UNSIGNED NOT NULL,

    -- Task Details
    task_type ENUM('checkout_clean', 'stayover_clean', 'deep_clean', 'inspection', 'maintenance') NOT NULL,
    priority ENUM('low', 'normal', 'high', 'urgent') DEFAULT 'normal',

    -- Assignment
    assigned_to BIGINT UNSIGNED, -- Staff member
    assigned_at TIMESTAMP NULL,

    -- Status
    status ENUM('pending', 'in_progress', 'completed', 'inspected', 'failed') DEFAULT 'pending',

    -- Timing
    scheduled_date DATE NOT NULL,
    started_at TIMESTAMP NULL,
    completed_at TIMESTAMP NULL,
    inspected_at TIMESTAMP NULL,

    -- Notes
    notes TEXT,
    inspection_notes TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (task_id),
    INDEX idx_property_date (property_id, scheduled_date),
    INDEX idx_room (room_id),
    INDEX idx_assigned (assigned_to),
    INDEX idx_status (status),
    FOREIGN KEY (property_id) REFERENCES properties(property_id),
    FOREIGN KEY (room_id) REFERENCES rooms(room_id)
) ENGINE=InnoDB;

-- Lost and found items
CREATE TABLE lost_and_found (
    item_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    property_id INT UNSIGNED NOT NULL,

    -- Item Details
    item_description TEXT NOT NULL,
    category VARCHAR(50),
    brand VARCHAR(100),
    color VARCHAR(50),

    -- Location Found
    found_location VARCHAR(255),
    room_id BIGINT UNSIGNED,

    -- Guest Information
    guest_id BIGINT UNSIGNED,
    reservation_id BIGINT UNSIGNED,

    -- Finder Information
    found_by BIGINT UNSIGNED, -- Staff member
    found_date DATE NOT NULL,

    -- Status
    status ENUM('logged', 'claimed', 'disposed', 'donated') DEFAULT 'logged',

    -- Return Information
    claimed_by_name VARCHAR(255),
    claimed_date DATE,
    return_method VARCHAR(100),
    shipping_address TEXT,

    -- Storage
    storage_location VARCHAR(100),

    -- Disposal
    disposal_date DATE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (item_id),
    INDEX idx_property (property_id),
    INDEX idx_found_date (found_date),
    INDEX idx_status (status),
    INDEX idx_guest (guest_id),
    FOREIGN KEY (property_id) REFERENCES properties(property_id),
    FOREIGN KEY (room_id) REFERENCES rooms(room_id),
    FOREIGN KEY (guest_id) REFERENCES guests(guest_id),
    FOREIGN KEY (reservation_id) REFERENCES reservations(reservation_id)
) ENGINE=InnoDB;

-- ============================================================================
-- STAFF MANAGEMENT
-- ============================================================================

-- Staff members
CREATE TABLE staff (
    staff_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    property_id INT UNSIGNED,

    -- Personal Information
    employee_id VARCHAR(50) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(20),

    -- Employment Details
    department ENUM('front_desk', 'housekeeping', 'maintenance', 'food_beverage', 'management', 'security', 'spa', 'other') NOT NULL,
    position VARCHAR(100),
    hire_date DATE NOT NULL,

    -- Access and Permissions
    system_access BOOLEAN DEFAULT FALSE,
    access_level ENUM('basic', 'supervisor', 'manager', 'admin') DEFAULT 'basic',

    -- Status
    status ENUM('active', 'on_leave', 'terminated') DEFAULT 'active',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (staff_id),
    UNIQUE KEY uk_employee_id (employee_id),
    INDEX idx_property (property_id),
    INDEX idx_department (department),
    INDEX idx_status (status),
    FOREIGN KEY (property_id) REFERENCES properties(property_id)
) ENGINE=InnoDB;

-- Staff schedules
CREATE TABLE staff_schedules (
    schedule_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    staff_id BIGINT UNSIGNED NOT NULL,
    property_id INT UNSIGNED NOT NULL,

    -- Schedule Details
    schedule_date DATE NOT NULL,
    shift_type ENUM('morning', 'afternoon', 'evening', 'night', 'split') NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,

    -- Department/Area
    department ENUM('front_desk', 'housekeeping', 'maintenance', 'food_beverage', 'management', 'security', 'spa', 'other') NOT NULL,
    work_area VARCHAR(100),

    -- Status
    status ENUM('scheduled', 'confirmed', 'working', 'completed', 'absent', 'cancelled') DEFAULT 'scheduled',

    -- Actual Times
    actual_start TIME,
    actual_end TIME,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (schedule_id),
    UNIQUE KEY uk_staff_date_shift (staff_id, schedule_date, shift_type),
    INDEX idx_property_date (property_id, schedule_date),
    INDEX idx_department (department, schedule_date),
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id),
    FOREIGN KEY (property_id) REFERENCES properties(property_id)
) ENGINE=InnoDB;

-- ============================================================================
-- FACILITIES AND SERVICES
-- ============================================================================

-- Restaurants and outlets
CREATE TABLE outlets (
    outlet_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    property_id INT UNSIGNED NOT NULL,

    -- Outlet Information
    outlet_name VARCHAR(255) NOT NULL,
    outlet_type ENUM('restaurant', 'bar', 'cafe', 'room_service', 'pool_bar', 'spa', 'shop') NOT NULL,

    -- Operating Hours
    opens_at TIME,
    closes_at TIME,
    days_open VARCHAR(20), -- 'Mon-Sun', 'Mon-Fri', etc

    -- Capacity
    seating_capacity INT,

    -- Status
    is_active BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (outlet_id),
    INDEX idx_property (property_id),
    INDEX idx_type (outlet_type),
    FOREIGN KEY (property_id) REFERENCES properties(property_id)
) ENGINE=InnoDB;

-- Event spaces
CREATE TABLE event_spaces (
    space_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    property_id INT UNSIGNED NOT NULL,

    -- Space Information
    space_name VARCHAR(255) NOT NULL,
    space_type ENUM('ballroom', 'meeting_room', 'conference_room', 'boardroom', 'outdoor', 'other') NOT NULL,

    -- Capacity
    max_capacity_theater INT,
    max_capacity_classroom INT,
    max_capacity_banquet INT,
    max_capacity_cocktail INT,

    -- Size
    size_sqft INT,
    ceiling_height_ft DECIMAL(5,2),

    -- Features
    has_av_equipment BOOLEAN DEFAULT FALSE,
    has_video_conferencing BOOLEAN DEFAULT FALSE,
    has_natural_light BOOLEAN DEFAULT FALSE,
    is_divisible BOOLEAN DEFAULT FALSE,

    -- Rates
    hourly_rate DECIMAL(10,2),
    half_day_rate DECIMAL(10,2),
    full_day_rate DECIMAL(10,2),

    -- Status
    is_active BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (space_id),
    INDEX idx_property (property_id),
    INDEX idx_type (space_type),
    FOREIGN KEY (property_id) REFERENCES properties(property_id)
) ENGINE=InnoDB;

-- Event bookings
CREATE TABLE event_bookings (
    booking_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    property_id INT UNSIGNED NOT NULL,
    space_id INT UNSIGNED NOT NULL,

    -- Client Information
    client_name VARCHAR(255) NOT NULL,
    client_company VARCHAR(255),
    client_email VARCHAR(255),
    client_phone VARCHAR(20),

    -- Event Details
    event_name VARCHAR(255),
    event_type ENUM('meeting', 'conference', 'wedding', 'party', 'exhibition', 'other') NOT NULL,

    -- Dates and Times
    event_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    setup_time TIME,
    breakdown_time TIME,

    -- Attendees
    expected_attendees INT NOT NULL,
    guaranteed_attendees INT,

    -- Setup Style
    setup_style ENUM('theater', 'classroom', 'u_shape', 'boardroom', 'banquet', 'cocktail', 'custom'),

    -- Catering
    has_catering BOOLEAN DEFAULT FALSE,
    catering_type VARCHAR(100),
    menu_selections JSON,

    -- Rates and Charges
    space_rental DECIMAL(10,2),
    catering_charges DECIMAL(10,2),
    equipment_charges DECIMAL(10,2),
    other_charges DECIMAL(10,2),
    total_amount DECIMAL(10,2),

    -- Payment
    deposit_amount DECIMAL(10,2),
    deposit_paid BOOLEAN DEFAULT FALSE,

    -- Status
    status ENUM('inquiry', 'tentative', 'confirmed', 'cancelled', 'completed') DEFAULT 'inquiry',

    -- Notes
    special_requirements TEXT,
    internal_notes TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (booking_id),
    INDEX idx_property (property_id),
    INDEX idx_space (space_id),
    INDEX idx_date (event_date),
    INDEX idx_status (status),
    FOREIGN KEY (property_id) REFERENCES properties(property_id),
    FOREIGN KEY (space_id) REFERENCES event_spaces(space_id)
) ENGINE=InnoDB;

-- ============================================================================
-- MAINTENANCE MANAGEMENT
-- ============================================================================

-- Maintenance requests
CREATE TABLE maintenance_requests (
    request_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    property_id INT UNSIGNED NOT NULL,

    -- Location
    location_type ENUM('room', 'public_area', 'back_office', 'exterior', 'equipment') NOT NULL,
    room_id BIGINT UNSIGNED,
    location_description VARCHAR(255),

    -- Issue Details
    category ENUM('plumbing', 'electrical', 'hvac', 'furniture', 'appliance', 'structural', 'other') NOT NULL,
    issue_description TEXT NOT NULL,
    priority ENUM('low', 'medium', 'high', 'emergency') DEFAULT 'medium',

    -- Reporter
    reported_by BIGINT UNSIGNED, -- Staff member
    reported_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Assignment
    assigned_to BIGINT UNSIGNED,
    assigned_date TIMESTAMP NULL,

    -- Status
    status ENUM('open', 'assigned', 'in_progress', 'on_hold', 'completed', 'closed') DEFAULT 'open',

    -- Resolution
    resolution_notes TEXT,
    parts_used JSON,
    labor_hours DECIMAL(5,2),
    total_cost DECIMAL(10,2),

    -- Timing
    scheduled_date DATE,
    completed_date TIMESTAMP NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (request_id),
    INDEX idx_property (property_id),
    INDEX idx_room (room_id),
    INDEX idx_status (status),
    INDEX idx_priority (priority),
    INDEX idx_category (category),
    FOREIGN KEY (property_id) REFERENCES properties(property_id),
    FOREIGN KEY (room_id) REFERENCES rooms(room_id)
) ENGINE=InnoDB;

-- ============================================================================
-- REVENUE MANAGEMENT
-- ============================================================================

-- Rate plans
CREATE TABLE rate_plans (
    rate_plan_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    property_id INT UNSIGNED NOT NULL,

    -- Plan Information
    plan_code VARCHAR(20) NOT NULL,
    plan_name VARCHAR(100) NOT NULL,
    description TEXT,

    -- Rate Type
    rate_type ENUM('rack', 'corporate', 'government', 'aaa', 'senior', 'package', 'promotional', 'group') NOT NULL,

    -- Validity
    valid_from DATE,
    valid_to DATE,

    -- Days of Week
    monday BOOLEAN DEFAULT TRUE,
    tuesday BOOLEAN DEFAULT TRUE,
    wednesday BOOLEAN DEFAULT TRUE,
    thursday BOOLEAN DEFAULT TRUE,
    friday BOOLEAN DEFAULT TRUE,
    saturday BOOLEAN DEFAULT TRUE,
    sunday BOOLEAN DEFAULT TRUE,

    -- Booking Conditions
    min_stay INT DEFAULT 1,
    max_stay INT,
    advance_booking_days INT,

    -- Inclusions
    includes_breakfast BOOLEAN DEFAULT FALSE,
    includes_wifi BOOLEAN DEFAULT TRUE,
    includes_parking BOOLEAN DEFAULT FALSE,
    other_inclusions JSON,

    -- Policies
    is_refundable BOOLEAN DEFAULT TRUE,
    cancellation_hours INT DEFAULT 24,

    -- Status
    is_active BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (rate_plan_id),
    UNIQUE KEY uk_property_plan_code (property_id, plan_code),
    INDEX idx_property (property_id),
    INDEX idx_rate_type (rate_type),
    INDEX idx_validity (valid_from, valid_to),
    FOREIGN KEY (property_id) REFERENCES properties(property_id)
) ENGINE=InnoDB;

-- Dynamic pricing
CREATE TABLE dynamic_rates (
    rate_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    property_id INT UNSIGNED NOT NULL,
    room_type_id INT UNSIGNED NOT NULL,
    rate_plan_id INT UNSIGNED NOT NULL,

    -- Date
    rate_date DATE NOT NULL,

    -- Rates
    single_rate DECIMAL(10,2),
    double_rate DECIMAL(10,2),
    triple_rate DECIMAL(10,2),
    quad_rate DECIMAL(10,2),
    extra_person_rate DECIMAL(10,2),

    -- Availability
    rooms_available INT,
    rooms_sold INT DEFAULT 0,

    -- Restrictions
    closed_to_arrival BOOLEAN DEFAULT FALSE,
    closed_to_departure BOOLEAN DEFAULT FALSE,
    min_stay_through INT DEFAULT 1,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (rate_id),
    UNIQUE KEY uk_property_room_plan_date (property_id, room_type_id, rate_plan_id, rate_date),
    INDEX idx_date (rate_date),
    INDEX idx_availability (property_id, rate_date, rooms_available),
    FOREIGN KEY (property_id) REFERENCES properties(property_id),
    FOREIGN KEY (room_type_id) REFERENCES room_types(room_type_id),
    FOREIGN KEY (rate_plan_id) REFERENCES rate_plans(rate_plan_id)
) ENGINE=InnoDB;

-- ============================================================================
-- LOYALTY PROGRAM
-- ============================================================================

-- Loyalty transactions
CREATE TABLE loyalty_transactions (
    transaction_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    guest_id BIGINT UNSIGNED NOT NULL,

    -- Transaction Type
    transaction_type ENUM('earn', 'redeem', 'expire', 'adjust', 'transfer') NOT NULL,

    -- Points
    points INT NOT NULL, -- Positive for earn, negative for redeem

    -- Reference
    reference_type ENUM('stay', 'dining', 'spa', 'promotion', 'manual', 'other'),
    reference_id BIGINT UNSIGNED,

    -- Description
    description VARCHAR(255),

    -- Expiry
    expiry_date DATE,

    -- Status
    status ENUM('pending', 'confirmed', 'expired', 'reversed') DEFAULT 'pending',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (transaction_id),
    INDEX idx_guest (guest_id),
    INDEX idx_type (transaction_type),
    INDEX idx_expiry (expiry_date),
    INDEX idx_status (status),
    FOREIGN KEY (guest_id) REFERENCES guests(guest_id)
) ENGINE=InnoDB;

-- ============================================================================
-- REPORTING AND ANALYTICS
-- ============================================================================

-- Daily statistics snapshot
CREATE TABLE daily_statistics (
    stat_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    property_id INT UNSIGNED NOT NULL,
    stat_date DATE NOT NULL,

    -- Occupancy
    total_rooms INT,
    rooms_occupied INT,
    occupancy_rate DECIMAL(5,2),

    -- Revenue
    room_revenue DECIMAL(15,2),
    fb_revenue DECIMAL(15,2),
    other_revenue DECIMAL(15,2),
    total_revenue DECIMAL(15,2),

    -- Rates
    adr DECIMAL(10,2), -- Average Daily Rate
    revpar DECIMAL(10,2), -- Revenue Per Available Room

    -- Arrivals and Departures
    arrivals INT,
    departures INT,
    stay_overs INT,

    -- Guest Statistics
    total_guests INT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (stat_id),
    UNIQUE KEY uk_property_date (property_id, stat_date),
    INDEX idx_date (stat_date),
    FOREIGN KEY (property_id) REFERENCES properties(property_id)
) ENGINE=InnoDB;
