# 🏨 Hotel Chain Management System

A comprehensive MySQL database schema for managing a modern hotel chain with multiple properties, including reservations, guest services, loyalty programs, staff management, facilities, and revenue optimization across all locations.

## 📊 Database Overview

- **Industry**: Hospitality / Hotel Management
- **Complexity**: Very High
- **Tables**: 22
- **Key Features**: Multi-property management, Dynamic pricing, Loyalty program, Staff scheduling
- **Data Volume**: Designed for thousands of rooms across multiple properties
- **Special Features**: Spatial indexes, Event scheduling, Real-time availability

## 🗂️ Schema Structure

### Property Management

1. **properties** - Hotel properties in the chain
   - Multiple brands and property types
   - Geographic location with coordinates
   - Star ratings and amenities
   - Contact information
   - Property-specific settings

2. **room_types** - Room categories per property
   - Standard configurations (Single, Double, Suite, etc.)
   - Maximum occupancy settings
   - Base pricing
   - Amenity specifications
   - Active/inactive status

3. **rooms** - Individual room inventory
   - Physical room details (floor, view, size)
   - Current status tracking
   - Housekeeping status
   - Maintenance status
   - Last renovation dates

### Guest Management

1. **guests** - Guest profiles
   - Personal information
   - Contact details
   - Preferences (room, dietary, etc.)
   - VIP status levels
   - Loyalty program membership
   - Marketing consent
   - Stay history tracking

### Reservation System

1. **reservations** - Booking records
   - Complete booking lifecycle
   - Multiple booking channels (direct, OTA, corporate)
   - Group booking support
   - Special requests handling
   - Cancellation policies
   - No-show tracking
   - Rate codes and discounts

2. **room_assignments** - Room allocation
   - Links reservations to specific rooms
   - Check-in/out timestamps
   - Early/late checkout tracking
   - Room changes
   - Upgrade tracking

### Financial Management

1. **folios** - Guest billing accounts
   - Multiple folios per reservation
   - Running balance tracking
   - Tax calculations
   - Payment status
   - Split billing support

2. **folio_charges** - Individual charges
   - Room charges
   - Food & beverage
   - Spa services
   - Mini-bar
   - Telephone/internet
   - Miscellaneous charges
   - Department tracking

3. **payments** - Payment transactions
   - Multiple payment methods
   - Deposit tracking
   - Refund processing
   - Currency conversion
   - Authorization codes

### Loyalty Program

1. **loyalty_members** - Member profiles
   - Tier levels (Silver, Gold, Platinum, Diamond)
   - Points balance
   - Lifetime points
   - Elite night credits
   - Expiration tracking
   - Benefit eligibility

2. **loyalty_transactions** - Points activity
   - Earning transactions
   - Redemption transactions
   - Adjustments
   - Promotions
   - Point transfers

### Staff Management

1. **staff** - Employee records
   - Multi-property assignments
   - Department organization
   - Position hierarchy
   - Contact information
   - Emergency contacts
   - Salary information

2. **staff_schedules** - Work schedules
   - Shift management
   - Department coverage
   - Overtime tracking
   - Actual vs scheduled hours
   - Break tracking

### Operations

1. **housekeeping_tasks** - Cleaning assignments
   - Room cleaning schedules
   - Priority levels
   - Special instructions
   - Supply tracking
   - Quality inspections
   - Time tracking

2. **maintenance_requests** - Repair tracking
   - Issue categorization
   - Priority levels
   - Cost estimates
   - Parts/supplies needed
   - Vendor coordination
   - Resolution tracking

### Guest Services

1. **restaurant_reservations** - Dining bookings
   - Multiple outlets per property
   - Time slot management
   - Table assignments
   - Dietary requirements
   - Special occasions

2. **event_bookings** - Meeting/event space
   - Conference rooms
   - Ballrooms
   - Equipment requirements
   - Catering arrangements
   - Setup configurations
   - A/V requirements

3. **spa_appointments** - Wellness services
   - Treatment bookings
   - Therapist assignments
   - Package deals
   - Product sales
   - Guest preferences

4. **guest_requests** - Service requests
   - Concierge services
   - Room service
   - Wake-up calls
   - Transportation
   - Special arrangements
   - Priority handling

### Revenue Management

1. **rate_plans** - Pricing strategies
   - Seasonal rates
   - Weekend rates
   - Package deals
   - Corporate rates
   - Group rates
   - Promotional codes

2. **rate_overrides** - Dynamic pricing
   - Date-specific overrides
   - Event-based pricing
   - Occupancy-based rates
   - Competitive adjustments
   - Last-minute deals

## 🔑 Key Features

### Multi-Property Management
- **Centralized System**: Manage all properties from single database
- **Brand Consistency**: Maintain standards across chain
- **Cross-Property**: Bookings and loyalty benefits
- **Resource Sharing**: Staff and management
- **Consolidated Reporting**: Chain-wide analytics

### Revenue Optimization
- **Dynamic Pricing**: Occupancy and demand-based
- **Yield Management**: Maximize revenue per room
- **Package Creation**: Bundled services
- **Group Management**: Convention and tour groups
- **Channel Management**: OTA integration

### Guest Experience
- **Personalization**: Preference tracking
- **Loyalty Rewards**: Points and benefits
- **Mobile Check-in**: Streamlined arrival
- **Service Requests**: Real-time response
- **Feedback System**: Quality improvement

### Operational Efficiency
- **Housekeeping**: Optimized room turnover
- **Maintenance**: Preventive scheduling
- **Staff Management**: Efficient scheduling
- **Inventory Control**: Supply management
- **Energy Management**: Occupancy-based controls

## 📈 Use Cases

### Common Queries

1. **Room Availability Search**
```sql
-- Find available rooms for date range
SELECT
    r.room_id,
    r.room_number,
    rt.type_name,
    rt.base_rate,
    p.property_name
FROM rooms r
JOIN room_types rt ON r.room_type_id = rt.room_type_id
JOIN properties p ON r.property_id = p.property_id
LEFT JOIN room_assignments ra ON r.room_id = ra.room_id
    AND ra.status = 'occupied'
    AND '2024-03-15' < ra.check_out_date
    AND '2024-03-17' > ra.check_in_date
WHERE r.status = 'available'
    AND r.property_id = 1
    AND ra.assignment_id IS NULL
ORDER BY rt.base_rate;
```

2. **Daily Arrivals Report**
```sql
-- Today's expected arrivals
SELECT
    r.confirmation_number,
    g.first_name,
    g.last_name,
    g.vip_status,
    r.room_nights,
    r.total_amount,
    r.special_requests,
    r.arrival_time,
    CASE
        WHEN ra.room_id IS NOT NULL THEN rm.room_number
        ELSE 'Not Assigned'
    END as room_number
FROM reservations r
JOIN guests g ON r.guest_id = g.guest_id
LEFT JOIN room_assignments ra ON r.reservation_id = ra.reservation_id
LEFT JOIN rooms rm ON ra.room_id = rm.room_id
WHERE r.check_in_date = CURDATE()
    AND r.status = 'confirmed'
    AND r.property_id = 1
ORDER BY r.arrival_time;
```

3. **Occupancy Analysis**
```sql
-- Current and projected occupancy
WITH occupancy AS (
    SELECT
        p.property_id,
        p.property_name,
        COUNT(DISTINCT r.room_id) as total_rooms,
        COUNT(DISTINCT CASE
            WHEN ra.status = 'occupied' THEN ra.room_id
        END) as occupied_rooms,
        DATE(ra.check_in_date) as occupancy_date
    FROM properties p
    JOIN rooms r ON p.property_id = r.property_id
    LEFT JOIN room_assignments ra ON r.room_id = ra.room_id
        AND CURDATE() BETWEEN DATE(ra.check_in_date) AND DATE(ra.check_out_date)
    WHERE r.status = 'available'
    GROUP BY p.property_id, DATE(ra.check_in_date)
)
SELECT
    property_name,
    total_rooms,
    occupied_rooms,
    ROUND(occupied_rooms * 100.0 / total_rooms, 2) as occupancy_rate,
    (total_rooms - occupied_rooms) as available_rooms
FROM occupancy
ORDER BY occupancy_rate DESC;
```

4. **Revenue Report**
```sql
-- Monthly revenue by department
SELECT
    p.property_name,
    fc.department,
    MONTH(fc.posted_date) as month,
    COUNT(*) as transaction_count,
    SUM(fc.amount) as gross_revenue,
    SUM(fc.tax_amount) as tax_collected,
    SUM(fc.amount - fc.tax_amount) as net_revenue
FROM folio_charges fc
JOIN folios f ON fc.folio_id = f.folio_id
JOIN properties p ON f.property_id = p.property_id
WHERE fc.posted_date >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)
    AND f.status = 'closed'
GROUP BY p.property_id, fc.department, MONTH(fc.posted_date)
ORDER BY p.property_name, month, gross_revenue DESC;
```

5. **Guest Loyalty Status**
```sql
-- Top loyalty members by property
SELECT
    lm.member_number,
    g.first_name,
    g.last_name,
    lm.tier_level,
    lm.current_points,
    lm.ytd_nights,
    COUNT(r.reservation_id) as total_stays,
    SUM(f.total_charges) as lifetime_spend,
    MAX(r.check_out_date) as last_stay
FROM loyalty_members lm
JOIN guests g ON lm.guest_id = g.guest_id
JOIN reservations r ON g.guest_id = r.guest_id
JOIN folios f ON r.reservation_id = f.reservation_id
WHERE r.status IN ('checked_out', 'completed')
GROUP BY lm.member_id
ORDER BY lm.tier_level DESC, lifetime_spend DESC
LIMIT 100;
```

## 🚀 Getting Started

### 1. Create Database
```bash
mysql -u root -p < schema/00_create_database.sql
```

### 2. Create Schema
```bash
mysql -u root -p hotel_chain < schema/01_tables.sql
mysql -u root -p hotel_chain < schema/02_constraints.sql
mysql -u root -p hotel_chain < schema/03_indexes.sql
```

### 3. Load Sample Data (when available)
```bash
mysql -u root -p hotel_chain < data/01_properties.sql
mysql -u root -p hotel_chain < data/02_rooms.sql
mysql -u root -p hotel_chain < data/03_sample_guests.sql
```

### 4. Generate Test Data (when generator is ready)
```bash
cd generators/hotel_chain
python generator.py --properties 5 --rooms 2000 --guests 10000 --reservations 50000
```

## 📋 Business Rules

### Reservation Policies
- Check-in time: 3:00 PM
- Check-out time: 11:00 AM
- Cancellation: 24-48 hours depending on rate
- No-show: Charge one night
- Deposit: Required for peak seasons
- Group blocks: 10+ rooms

### Room Management
- Housekeeping: Daily for stayovers
- Deep cleaning: Every checkout
- Maintenance: Preventive every 90 days
- Renovation: Track 5-year cycles
- Out of order: Immediate status update

### Loyalty Program
- Points earning: 10 points per dollar
- Elite nights: Count toward status
- Tier benefits: Cumulative
- Point expiry: 18 months of inactivity
- Status qualification: Annual
- Bonus categories: Promotional periods

### Pricing Rules
- Base rates: Vary by season
- Dynamic pricing: Occupancy-based
- Group rates: Volume discounts
- Corporate rates: Negotiated
- Package deals: Bundled services
- Last-minute: Discounts or premiums

### Staff Operations
- Shifts: 3 per day (morning, evening, night)
- Departments: Coordinated scheduling
- Overtime: After 40 hours/week
- Training: Tracked and required
- Performance: Regular reviews

## 🔍 Indexes

Optimized for hotel operations:

- **Reservation Searches**: By date, guest, confirmation
- **Room Availability**: Real-time inventory
- **Guest Lookups**: Email, phone, loyalty number
- **Operational Queues**: Housekeeping, maintenance
- **Financial Reports**: Revenue and occupancy
- **Loyalty Queries**: Points and tier management

## 📊 Performance Considerations

### Scaling Strategies
- **Read Replicas**: For reporting and analytics
- **Partitioning**: Reservations by date, charges by month
- **Caching**: Room availability, rate plans
- **Archiving**: Old reservations after 2 years
- **CDN**: For property images and documents

### Critical Performance Areas
- Room search: < 500ms
- Availability check: < 200ms
- Reservation creation: < 2 seconds
- Check-in process: < 3 seconds
- Report generation: Background jobs

### Data Retention
- Active reservations: Online
- Historical data: 2 years online, then archive
- Financial records: 7 years (compliance)
- Guest profiles: Permanent (with consent)
- Loyalty history: Permanent

## 🎯 Learning Objectives

This example demonstrates:

1. **Multi-Location Management** - Chain-wide operations
2. **Complex Pricing** - Dynamic revenue management
3. **Guest Services** - Comprehensive hospitality features
4. **Operational Workflows** - Housekeeping, maintenance
5. **Financial Management** - Folios, charges, payments
6. **Loyalty Programs** - Points, tiers, benefits
7. **Staff Scheduling** - Multi-department coordination
8. **Spatial Data** - Location-based queries

## 🔧 Customization Options

### Additional Features to Consider

1. **Mobile Key System**
```sql
CREATE TABLE mobile_keys (
    key_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    room_assignment_id BIGINT,
    key_code VARCHAR(100),
    valid_from DATETIME,
    valid_to DATETIME,
    device_id VARCHAR(100),
    FOREIGN KEY (room_assignment_id) REFERENCES room_assignments(assignment_id)
);
```

2. **Guest Feedback**
```sql
CREATE TABLE guest_surveys (
    survey_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    reservation_id BIGINT,
    overall_rating INT,
    cleanliness_rating INT,
    service_rating INT,
    value_rating INT,
    comments TEXT,
    FOREIGN KEY (reservation_id) REFERENCES reservations(reservation_id)
);
```

3. **Energy Management**
```sql
CREATE TABLE room_energy_usage (
    usage_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    room_id INT,
    usage_date DATE,
    electricity_kwh DECIMAL(10,2),
    water_gallons DECIMAL(10,2),
    hvac_runtime_hours DECIMAL(5,2),
    occupancy_based BOOLEAN,
    FOREIGN KEY (room_id) REFERENCES rooms(room_id)
);
```

## 🛠️ Technologies

- **Database**: MySQL 8.0+
- **Engine**: InnoDB for ACID compliance
- **Character Set**: utf8mb4 for international guests
- **Triggers**: Automated workflows
- **Events**: Scheduled maintenance tasks
- **Spatial**: Geographic queries

## 📚 Additional Resources

- [Hotel Technology Next Generation (HTNG)](https://www.htng.org/)
- [HFTP Uniform System of Accounts](https://www.hftp.org/)
- [STR Benchmarking](https://str.com/)
- [Oracle Hospitality](https://www.oracle.com/industries/hospitality/)
- [Hotel PMS Standards](https://www.hospitalitynet.org/news/4098276.html)

## 🤝 Contributing

Areas for improvement:
1. Add IoT room controls
2. Implement voice assistant integration
3. Add predictive maintenance
4. Create mobile app APIs
5. Add AI-powered pricing
6. Implement contactless services

## 📝 License

Part of the MySQL Business-to-Schema project, MIT License.