# Data Model Design Guide

## Overview

This document covers the principles and best practices for designing data models in MySQL, with practical examples from our 9 database implementations.

## Table of Contents

1. [Data Modeling Fundamentals](#data-modeling-fundamentals)
2. [Design Patterns](#design-patterns)
3. [Time Series Data](#time-series-data)
4. [Multi-Tenant Architecture](#multi-tenant-architecture)
5. [Hierarchical Data](#hierarchical-data)
6. [Geospatial Data](#geospatial-data)
7. [Audit and Compliance](#audit-and-compliance)
8. [Performance Considerations](#performance-considerations)

## Data Modeling Fundamentals

### Entity Identification

The first step in data modeling is identifying entities and their relationships:

```sql
-- Example: E-commerce entities
CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    sku VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    price DECIMAL(10,2) NOT NULL
);

CREATE TABLE orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);
```

### Relationship Types

#### One-to-One
```sql
-- Example: User and user_profile
CREATE TABLE users (
    user_id INT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE user_profiles (
    user_id INT PRIMARY KEY,
    bio TEXT,
    avatar_url VARCHAR(255),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);
```

#### One-to-Many
```sql
-- Example: Department and employees
CREATE TABLE departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(100) NOT NULL
);

CREATE TABLE employees (
    emp_id INT PRIMARY KEY,
    dept_id INT,
    emp_name VARCHAR(100) NOT NULL,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);
```

#### Many-to-Many
```sql
-- Example: Students and courses
CREATE TABLE students (
    student_id INT PRIMARY KEY,
    student_name VARCHAR(100) NOT NULL
);

CREATE TABLE courses (
    course_id INT PRIMARY KEY,
    course_name VARCHAR(100) NOT NULL
);

CREATE TABLE enrollments (
    student_id INT,
    course_id INT,
    enrollment_date DATE,
    PRIMARY KEY (student_id, course_id),
    FOREIGN KEY (student_id) REFERENCES students(student_id),
    FOREIGN KEY (course_id) REFERENCES courses(course_id)
);
```

## Design Patterns

### 1. Star Schema (Analytics)

Used in our **E-commerce** and **Streaming ML** examples:

```sql
-- Fact table
CREATE TABLE sales_facts (
    sale_id INT PRIMARY KEY,
    date_id INT,
    product_id INT,
    customer_id INT,
    store_id INT,
    quantity INT,
    amount DECIMAL(10,2)
);

-- Dimension tables
CREATE TABLE date_dimension (
    date_id INT PRIMARY KEY,
    date DATE,
    year INT,
    quarter INT,
    month INT,
    week INT,
    day_of_week INT
);

CREATE TABLE product_dimension (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(200),
    category VARCHAR(100),
    brand VARCHAR(100)
);
```

### 2. Entity-Attribute-Value (EAV)

Used for flexible attributes in **Healthcare IoT**:

```sql
CREATE TABLE device_attributes (
    device_id INT,
    attribute_name VARCHAR(50),
    attribute_value VARCHAR(255),
    recorded_at TIMESTAMP,
    PRIMARY KEY (device_id, attribute_name, recorded_at),
    FOREIGN KEY (device_id) REFERENCES devices(device_id)
);
```

### 3. Polymorphic Associations

Used in **Smart Energy** for different meter types:

```sql
CREATE TABLE readings (
    reading_id INT PRIMARY KEY,
    measurable_type ENUM('ElectricMeter', 'GasMeter', 'WaterMeter'),
    measurable_id INT,
    value DECIMAL(10,3),
    unit VARCHAR(20),
    timestamp TIMESTAMP,
    INDEX idx_polymorphic (measurable_type, measurable_id)
);
```

## Time Series Data

Critical for IoT applications (IoT Bins, Smart Energy, Industrial IoT):

### Basic Time Series Table

```sql
CREATE TABLE sensor_readings (
    sensor_id INT,
    reading_time TIMESTAMP,
    reading_value DECIMAL(10,3),
    PRIMARY KEY (sensor_id, reading_time)
) PARTITION BY RANGE (UNIX_TIMESTAMP(reading_time)) (
    PARTITION p202501 VALUES LESS THAN (UNIX_TIMESTAMP('2025-02-01')),
    PARTITION p202502 VALUES LESS THAN (UNIX_TIMESTAMP('2025-03-01')),
    PARTITION p202503 VALUES LESS THAN (UNIX_TIMESTAMP('2025-04-01'))
);
```

### Aggregation Tables

```sql
-- Hourly aggregates for faster queries
CREATE TABLE sensor_readings_hourly (
    sensor_id INT,
    hour_start DATETIME,
    min_value DECIMAL(10,3),
    max_value DECIMAL(10,3),
    avg_value DECIMAL(10,3),
    sample_count INT,
    PRIMARY KEY (sensor_id, hour_start)
);

-- Daily aggregates
CREATE TABLE sensor_readings_daily (
    sensor_id INT,
    date DATE,
    min_value DECIMAL(10,3),
    max_value DECIMAL(10,3),
    avg_value DECIMAL(10,3),
    total_samples INT,
    PRIMARY KEY (sensor_id, date)
);
```

## Multi-Tenant Architecture

Used in **Smart Energy** for utility companies:

### Shared Database, Separate Schema

```sql
-- Tenant registry
CREATE TABLE tenants (
    tenant_id INT PRIMARY KEY,
    tenant_name VARCHAR(100),
    database_schema VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE
);

-- Each tenant gets their own schema
CREATE SCHEMA tenant_001;
CREATE SCHEMA tenant_002;
```

### Shared Database, Shared Schema (Row-Level)

```sql
-- All tables include tenant_id
CREATE TABLE meters (
    meter_id INT,
    tenant_id INT,
    meter_serial VARCHAR(50),
    PRIMARY KEY (tenant_id, meter_id),
    INDEX idx_tenant (tenant_id)
);

CREATE TABLE readings (
    reading_id BIGINT AUTO_INCREMENT,
    tenant_id INT,
    meter_id INT,
    reading_value DECIMAL(10,3),
    PRIMARY KEY (reading_id),
    INDEX idx_tenant_meter (tenant_id, meter_id),
    FOREIGN KEY (tenant_id, meter_id)
        REFERENCES meters(tenant_id, meter_id)
);
```

## Hierarchical Data

### Adjacency List (Simple)

Used in **E-commerce** for categories:

```sql
CREATE TABLE categories (
    category_id INT PRIMARY KEY,
    parent_id INT NULL,
    category_name VARCHAR(100),
    FOREIGN KEY (parent_id) REFERENCES categories(category_id)
);
```

### Nested Set Model (Complex Queries)

```sql
CREATE TABLE categories_nested (
    category_id INT PRIMARY KEY,
    name VARCHAR(100),
    lft INT NOT NULL,
    rgt INT NOT NULL,
    INDEX idx_nested (lft, rgt)
);

-- Find all descendants
SELECT * FROM categories_nested
WHERE lft > 2 AND rgt < 11;
```

### Path Enumeration

Used in **Smart Agriculture** for field zones:

```sql
CREATE TABLE zones (
    zone_id INT PRIMARY KEY,
    zone_path VARCHAR(255),  -- e.g., '/1/3/7/'
    zone_name VARCHAR(100),
    INDEX idx_path (zone_path)
);
```

## Geospatial Data

Used in **Fleet Management** and **IoT Bins**:

### Point Data

```sql
CREATE TABLE bin_locations (
    bin_id INT PRIMARY KEY,
    location POINT NOT NULL,
    address VARCHAR(255),
    SPATIAL INDEX idx_location (location)
);

-- Insert with ST_GeomFromText
INSERT INTO bin_locations VALUES
(1, ST_GeomFromText('POINT(40.7128 -74.0060)'), '123 Main St');

-- Find nearby bins
SELECT bin_id,
       ST_Distance_Sphere(location,
           ST_GeomFromText('POINT(40.7200 -74.0100)')) AS distance_meters
FROM bin_locations
HAVING distance_meters < 1000
ORDER BY distance_meters;
```

### Route Data

```sql
CREATE TABLE routes (
    route_id INT PRIMARY KEY,
    route_path LINESTRING NOT NULL,
    total_distance DECIMAL(10,2),
    SPATIAL INDEX idx_route (route_path)
);
```

## Audit and Compliance

Essential for **Healthcare IoT** and **Industrial IoT**:

### Audit Log Pattern

```sql
CREATE TABLE audit_log (
    audit_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(64) NOT NULL,
    record_id INT NOT NULL,
    action ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    user_id INT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    old_values JSON,
    new_values JSON,
    ip_address VARCHAR(45),
    user_agent VARCHAR(255),
    INDEX idx_table_record (table_name, record_id),
    INDEX idx_timestamp (timestamp),
    INDEX idx_user (user_id)
);
```

### HIPAA Compliance (Healthcare)

```sql
CREATE TABLE patient_access_log (
    log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    accessed_by INT NOT NULL,
    access_reason VARCHAR(255),
    access_type ENUM('VIEW', 'MODIFY', 'EXPORT'),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- Required for HIPAA
    workstation_id VARCHAR(100),
    application VARCHAR(100),
    INDEX idx_patient (patient_id),
    INDEX idx_timestamp (timestamp)
);
```

## Performance Considerations

### Denormalization for Performance

```sql
-- Normalized (slower reads, consistent)
CREATE TABLE order_items (
    order_id INT,
    product_id INT,
    quantity INT,
    unit_price DECIMAL(10,2),
    PRIMARY KEY (order_id, product_id)
);

-- Denormalized (faster reads, redundant)
CREATE TABLE orders_denormalized (
    order_id INT PRIMARY KEY,
    customer_name VARCHAR(100),  -- Denormalized from customers
    total_items INT,              -- Calculated
    total_amount DECIMAL(10,2),   -- Calculated
    items_json JSON               -- All items in JSON
);
```

### Materialized Views (Using Tables)

```sql
-- Create materialized view as table
CREATE TABLE daily_sales_summary AS
SELECT
    DATE(order_date) as sale_date,
    COUNT(*) as order_count,
    SUM(total_amount) as total_sales,
    AVG(total_amount) as avg_order_value
FROM orders
GROUP BY DATE(order_date);

-- Refresh procedure
DELIMITER //
CREATE PROCEDURE refresh_daily_sales()
BEGIN
    TRUNCATE TABLE daily_sales_summary;
    INSERT INTO daily_sales_summary
    SELECT
        DATE(order_date) as sale_date,
        COUNT(*) as order_count,
        SUM(total_amount) as total_sales,
        AVG(total_amount) as avg_order_value
    FROM orders
    GROUP BY DATE(order_date);
END//
DELIMITER ;
```

## Best Practices

### 1. Choose Appropriate Data Types

```sql
-- Good: Specific types
CREATE TABLE products (
    product_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    price DECIMAL(10,2) NOT NULL,
    weight DECIMAL(8,3),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bad: Generic types
CREATE TABLE products (
    product_id VARCHAR(255) PRIMARY KEY,
    price VARCHAR(255),
    weight TEXT,
    is_active VARCHAR(10),
    created_at VARCHAR(255)
);
```

### 2. Use Consistent Naming

- Tables: plural (users, orders, products)
- Primary keys: table_singular_id (user_id, order_id)
- Foreign keys: referenced_table_singular_id
- Indexes: idx_table_columns
- Timestamps: action_at (created_at, updated_at)

### 3. Plan for Scale

```sql
-- Use BIGINT for high-volume tables
CREATE TABLE events (
    event_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    event_data JSON,
    created_at TIMESTAMP
);

-- Partition large tables
ALTER TABLE events
PARTITION BY RANGE (YEAR(created_at)) (
    PARTITION p2024 VALUES LESS THAN (2025),
    PARTITION p2025 VALUES LESS THAN (2026),
    PARTITION p2026 VALUES LESS THAN (2027)
);
```

## Example Implementations

### IoT Time Series (IoT Bins)
- Partitioned sensor_readings table
- Separate aggregation tables
- Archive old data pattern

### Multi-Tenant (Smart Energy)
- Row-level isolation with tenant_id
- Composite primary keys
- Tenant-aware indexes

### E-commerce (E-commerce)
- Star schema for analytics
- Denormalized order summaries
- JSON for flexible attributes

### GPS Tracking (Fleet Management)
- Spatial indexes for location queries
- Time-based partitioning
- Compressed historical data

### Healthcare (Healthcare IoT)
- Strict audit logging
- Encrypted sensitive fields
- Compliance-driven design

## Conclusion

Effective data modeling requires:
1. Understanding business requirements
2. Choosing appropriate patterns
3. Planning for scale and performance
4. Implementing proper constraints
5. Considering maintenance and evolution

Each of our 9 examples demonstrates different aspects of these principles in action.