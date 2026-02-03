# Database Constraints Guide

## Overview

Constraints are rules enforced at the database level to ensure data integrity and consistency. This guide covers all types of MySQL constraints with examples from our 9 database implementations.

## Table of Contents

1. [Primary Key Constraints](#primary-key-constraints)
2. [Foreign Key Constraints](#foreign-key-constraints)
3. [Unique Constraints](#unique-constraints)
4. [Check Constraints](#check-constraints)
5. [NOT NULL Constraints](#not-null-constraints)
6. [Default Constraints](#default-constraints)
7. [Complex Constraints](#complex-constraints)
8. [Performance Impact](#performance-impact)

## Primary Key Constraints

### Single Column Primary Key

```sql
-- Simple auto-increment primary key
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL
);

-- UUID primary key (for distributed systems)
CREATE TABLE events (
    event_id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    event_type VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Composite Primary Key

Used in **Smart Energy** for multi-tenant design:

```sql
-- Multi-tenant composite key
CREATE TABLE meter_readings (
    tenant_id INT,
    meter_id INT,
    reading_timestamp TIMESTAMP,
    reading_value DECIMAL(10,3),
    PRIMARY KEY (tenant_id, meter_id, reading_timestamp)
);

-- Many-to-many relationship
CREATE TABLE user_roles (
    user_id INT,
    role_id INT,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, role_id)
);
```

### Natural vs Surrogate Keys

```sql
-- Natural key (using business data)
CREATE TABLE countries (
    country_code CHAR(2) PRIMARY KEY,  -- ISO code
    country_name VARCHAR(100) NOT NULL
);

-- Surrogate key (artificial identifier)
CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,  -- Surrogate
    email VARCHAR(100) UNIQUE NOT NULL,         -- Natural candidate
    phone VARCHAR(20)
);
```

## Foreign Key Constraints

### Basic Foreign Key

```sql
-- Parent table
CREATE TABLE departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(100) NOT NULL
);

-- Child table with foreign key
CREATE TABLE employees (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(100) NOT NULL,
    dept_id INT,
    CONSTRAINT fk_emp_dept
        FOREIGN KEY (dept_id)
        REFERENCES departments(dept_id)
);
```

### Cascade Options

Used in **E-commerce** for order management:

```sql
-- CASCADE DELETE: Delete order items when order is deleted
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE order_items (
    item_id INT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- SET NULL: Set to null when referenced record deleted
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    category_id INT,
    product_name VARCHAR(200) NOT NULL,
    CONSTRAINT fk_product_category
        FOREIGN KEY (category_id)
        REFERENCES categories(category_id)
        ON DELETE SET NULL
);

-- RESTRICT: Prevent deletion if references exist (default)
CREATE TABLE brands (
    brand_id INT PRIMARY KEY,
    brand_name VARCHAR(100) NOT NULL
);

CREATE TABLE products_restrict (
    product_id INT PRIMARY KEY,
    brand_id INT NOT NULL,
    CONSTRAINT fk_product_brand
        FOREIGN KEY (brand_id)
        REFERENCES brands(brand_id)
        ON DELETE RESTRICT
);
```

### Self-Referencing Foreign Key

Used in **Industrial IoT** for equipment hierarchy:

```sql
CREATE TABLE equipment (
    equipment_id INT PRIMARY KEY,
    parent_equipment_id INT,
    equipment_name VARCHAR(100) NOT NULL,
    equipment_type VARCHAR(50),
    CONSTRAINT fk_equipment_parent
        FOREIGN KEY (parent_equipment_id)
        REFERENCES equipment(equipment_id)
        ON DELETE CASCADE
);
```

### Composite Foreign Keys

Used in **Smart Energy** for multi-tenant references:

```sql
-- Parent table with composite primary key
CREATE TABLE tenant_meters (
    tenant_id INT,
    meter_id INT,
    meter_serial VARCHAR(50) NOT NULL,
    PRIMARY KEY (tenant_id, meter_id)
);

-- Child table referencing composite key
CREATE TABLE tenant_readings (
    reading_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    tenant_id INT,
    meter_id INT,
    reading_value DECIMAL(10,3),
    CONSTRAINT fk_reading_meter
        FOREIGN KEY (tenant_id, meter_id)
        REFERENCES tenant_meters(tenant_id, meter_id)
        ON DELETE CASCADE
);
```

## Unique Constraints

### Single Column Unique

```sql
CREATE TABLE users (
    user_id INT PRIMARY KEY,
    email VARCHAR(100) UNIQUE NOT NULL,
    username VARCHAR(50) UNIQUE NOT NULL,
    phone VARCHAR(20),
    CONSTRAINT uk_phone UNIQUE (phone)
);
```

### Composite Unique Constraints

Used in **Fleet Management** for vehicle tracking:

```sql
CREATE TABLE vehicles (
    vehicle_id INT PRIMARY KEY,
    license_plate VARCHAR(20) NOT NULL,
    registration_state CHAR(2) NOT NULL,
    vin VARCHAR(17) UNIQUE NOT NULL,
    -- Combination of plate and state must be unique
    CONSTRAINT uk_plate_state UNIQUE (license_plate, registration_state)
);

-- Prevent duplicate sensor readings
CREATE TABLE sensor_readings (
    reading_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    sensor_id INT NOT NULL,
    reading_timestamp TIMESTAMP NOT NULL,
    reading_value DECIMAL(10,3),
    -- Prevent duplicate readings for same sensor/time
    CONSTRAINT uk_sensor_time UNIQUE (sensor_id, reading_timestamp)
);
```

### Partial Unique Index (Conditional Uniqueness)

```sql
-- Only one active assignment per vehicle
CREATE TABLE driver_assignments (
    assignment_id INT PRIMARY KEY,
    driver_id INT NOT NULL,
    vehicle_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    is_active BOOLEAN DEFAULT TRUE
);

-- Create unique index only for active assignments
CREATE UNIQUE INDEX uk_active_assignment
ON driver_assignments(vehicle_id, is_active)
WHERE is_active = TRUE;
```

## Check Constraints

MySQL 8.0+ supports CHECK constraints:

### Basic Check Constraints

```sql
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(200) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    discount_percent INT,
    stock_quantity INT NOT NULL,
    CONSTRAINT chk_price CHECK (price > 0),
    CONSTRAINT chk_discount CHECK (discount_percent BETWEEN 0 AND 100),
    CONSTRAINT chk_stock CHECK (stock_quantity >= 0)
);
```

### Complex Check Constraints

Used in **Healthcare IoT** for vital signs validation:

```sql
CREATE TABLE vital_signs (
    reading_id INT PRIMARY KEY,
    patient_id INT NOT NULL,
    heart_rate INT,
    blood_pressure_systolic INT,
    blood_pressure_diastolic INT,
    temperature DECIMAL(4,1),
    spo2 INT,
    -- Physiological constraints
    CONSTRAINT chk_heart_rate CHECK (heart_rate BETWEEN 20 AND 300),
    CONSTRAINT chk_bp_systolic CHECK (blood_pressure_systolic BETWEEN 50 AND 300),
    CONSTRAINT chk_bp_diastolic CHECK (blood_pressure_diastolic BETWEEN 30 AND 200),
    CONSTRAINT chk_bp_order CHECK (blood_pressure_systolic > blood_pressure_diastolic),
    CONSTRAINT chk_temperature CHECK (temperature BETWEEN 30.0 AND 45.0),
    CONSTRAINT chk_spo2 CHECK (spo2 BETWEEN 0 AND 100)
);
```

### Date Range Constraints

Used in **Smart Agriculture** for planting seasons:

```sql
CREATE TABLE planting_records (
    planting_id INT PRIMARY KEY,
    crop_id INT NOT NULL,
    planting_date DATE NOT NULL,
    expected_harvest_date DATE NOT NULL,
    actual_harvest_date DATE,
    -- Date validation
    CONSTRAINT chk_harvest_after_planting
        CHECK (expected_harvest_date > planting_date),
    CONSTRAINT chk_actual_harvest
        CHECK (actual_harvest_date IS NULL OR actual_harvest_date >= planting_date)
);
```

### Enum-like Constraints

```sql
CREATE TABLE shipments (
    shipment_id INT PRIMARY KEY,
    status VARCHAR(20) NOT NULL,
    priority VARCHAR(10) NOT NULL,
    CONSTRAINT chk_status CHECK (
        status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled')
    ),
    CONSTRAINT chk_priority CHECK (
        priority IN ('standard', 'express', 'overnight')
    )
);
```

## NOT NULL Constraints

### Strategic NOT NULL Usage

```sql
CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    -- Required fields
    email VARCHAR(100) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    -- Optional fields
    middle_name VARCHAR(50),  -- Can be NULL
    phone VARCHAR(20),        -- Can be NULL
    date_of_birth DATE,       -- Can be NULL
    -- System fields (never NULL)
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);
```

### Conditional NOT NULL (Business Rules)

```sql
-- In application logic or triggers
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    status VARCHAR(20) NOT NULL,
    payment_method VARCHAR(20),
    paid_at TIMESTAMP,
    shipped_at TIMESTAMP,
    -- paid_at must be NOT NULL if status is 'paid' or 'shipped'
    -- shipped_at must be NOT NULL if status is 'shipped'
    CONSTRAINT chk_payment_consistency CHECK (
        (status NOT IN ('paid', 'shipped')) OR
        (status IN ('paid', 'shipped') AND paid_at IS NOT NULL)
    ),
    CONSTRAINT chk_shipping_consistency CHECK (
        (status != 'shipped') OR
        (status = 'shipped' AND shipped_at IS NOT NULL)
    )
);
```

## Default Constraints

### Common Default Values

```sql
CREATE TABLE audit_log (
    log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    -- Booleans
    is_processed BOOLEAN DEFAULT FALSE,
    is_archived BOOLEAN DEFAULT FALSE,
    -- Enums with defaults
    severity VARCHAR(10) DEFAULT 'info',
    -- Numeric defaults
    retry_count INT DEFAULT 0,
    priority INT DEFAULT 5,
    -- String defaults
    status VARCHAR(20) DEFAULT 'pending',
    -- UUID generation
    trace_id CHAR(36) DEFAULT (UUID())
);
```

### Dynamic Defaults

Used in **IoT Bins** for sensor configuration:

```sql
CREATE TABLE sensors (
    sensor_id INT AUTO_INCREMENT PRIMARY KEY,
    sensor_type VARCHAR(50) NOT NULL,
    -- Dynamic default based on type (handled by trigger)
    sampling_interval INT DEFAULT 300,  -- 5 minutes
    -- Calculated defaults
    next_maintenance DATE DEFAULT (DATE_ADD(CURDATE(), INTERVAL 90 DAY)),
    -- JSON defaults
    configuration JSON DEFAULT '{"alerts": true, "threshold": 80}'
);
```

## Complex Constraints

### Business Rule Enforcement

Used in **E-commerce** for inventory management:

```sql
CREATE TABLE inventory_transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    warehouse_id INT NOT NULL,
    transaction_type ENUM('in', 'out', 'transfer') NOT NULL,
    quantity INT NOT NULL,
    balance_before INT NOT NULL,
    balance_after INT NOT NULL,
    -- Complex business rules
    CONSTRAINT chk_quantity_positive CHECK (
        (transaction_type = 'in' AND quantity > 0) OR
        (transaction_type = 'out' AND quantity < 0) OR
        (transaction_type = 'transfer' AND quantity != 0)
    ),
    CONSTRAINT chk_balance_calculation CHECK (
        balance_after = balance_before + quantity
    ),
    CONSTRAINT chk_no_negative_inventory CHECK (
        balance_after >= 0
    )
);
```

### Temporal Constraints

Used in **Fleet Management** for trip validation:

```sql
CREATE TABLE trips (
    trip_id INT AUTO_INCREMENT PRIMARY KEY,
    vehicle_id INT NOT NULL,
    driver_id INT NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    start_odometer INT NOT NULL,
    end_odometer INT,
    -- Temporal constraints
    CONSTRAINT chk_trip_duration CHECK (
        end_time IS NULL OR end_time > start_time
    ),
    CONSTRAINT chk_trip_distance CHECK (
        end_odometer IS NULL OR end_odometer > start_odometer
    ),
    -- Maximum trip duration (24 hours)
    CONSTRAINT chk_max_duration CHECK (
        end_time IS NULL OR
        TIMESTAMPDIFF(HOUR, start_time, end_time) <= 24
    )
);
```

### Cross-Table Constraints (Using Triggers)

```sql
-- Ensure total order items match order summary
DELIMITER //
CREATE TRIGGER trg_validate_order_total
BEFORE UPDATE ON orders
FOR EACH ROW
BEGIN
    DECLARE calculated_total DECIMAL(10,2);

    SELECT SUM(quantity * unit_price)
    INTO calculated_total
    FROM order_items
    WHERE order_id = NEW.order_id;

    IF NEW.total_amount != calculated_total THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Order total does not match sum of items';
    END IF;
END//
DELIMITER ;
```

## Performance Impact

### Index Creation by Constraints

```sql
-- Primary key creates clustered index
CREATE TABLE users (
    user_id INT PRIMARY KEY  -- Creates PRIMARY index
);

-- Unique constraint creates unique index
CREATE TABLE emails (
    email_id INT PRIMARY KEY,
    email_address VARCHAR(100) UNIQUE  -- Creates unique index
);

-- Foreign key creates index on referencing column
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
    -- Creates index on customer_id
);
```

### Constraint Performance Tips

```sql
-- Disable foreign key checks for bulk inserts
SET FOREIGN_KEY_CHECKS = 0;
-- Bulk insert operations
SET FOREIGN_KEY_CHECKS = 1;

-- Defer constraint checking (not available in MySQL, use transactions)
START TRANSACTION;
-- Multiple related inserts
INSERT INTO orders VALUES ...;
INSERT INTO order_items VALUES ...;
COMMIT;  -- Constraints checked here
```

## Best Practices

### 1. Naming Conventions

```sql
-- Use descriptive constraint names
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    sku VARCHAR(50) NOT NULL,
    category_id INT,
    price DECIMAL(10,2) NOT NULL,
    -- Good naming
    CONSTRAINT uk_product_sku UNIQUE (sku),
    CONSTRAINT fk_product_category
        FOREIGN KEY (category_id) REFERENCES categories(category_id),
    CONSTRAINT chk_product_price_positive CHECK (price > 0)
);
```

### 2. Documentation

```sql
-- Document complex constraints
CREATE TABLE subscription_tiers (
    tier_id INT PRIMARY KEY,
    tier_name VARCHAR(50) NOT NULL,
    max_users INT NOT NULL,
    max_storage_gb INT NOT NULL,
    price_monthly DECIMAL(10,2) NOT NULL,
    -- Business rule: Higher tiers must have more features
    CONSTRAINT chk_tier_progression CHECK (
        -- Document the business logic
        tier_id = 1 OR  -- Base tier has no constraints
        (max_users >= (
            SELECT MAX(max_users)
            FROM subscription_tiers t2
            WHERE t2.tier_id < subscription_tiers.tier_id
        ))
    )
) COMMENT = 'Subscription tiers with progressive feature constraints';
```

### 3. Error Handling

```sql
-- Provide meaningful error messages
DELIMITER //
CREATE TRIGGER trg_validate_stock
BEFORE INSERT ON order_items
FOR EACH ROW
BEGIN
    DECLARE available_stock INT;

    SELECT stock_quantity INTO available_stock
    FROM products
    WHERE product_id = NEW.product_id;

    IF NEW.quantity > available_stock THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = CONCAT(
            'Insufficient stock. Requested: ', NEW.quantity,
            ', Available: ', available_stock
        );
    END IF;
END//
DELIMITER ;
```

## Example Implementations

### Healthcare IoT (Strict Validation)
- Vital sign range checks
- Temporal constraints for readings
- Audit trail requirements

### E-commerce (Business Rules)
- Inventory constraints
- Price validation
- Order status transitions

### Fleet Management (Operational Constraints)
- Trip duration limits
- License validations
- Maintenance schedules

### Smart Energy (Multi-tenant Isolation)
- Composite keys for tenant separation
- Consumption limits
- Billing period constraints

## Conclusion

Effective constraint design:
1. Prevents invalid data at the database level
2. Enforces business rules consistently
3. Documents system requirements
4. Improves data quality
5. Reduces application complexity

Choose constraints carefully to balance data integrity with system flexibility and performance.