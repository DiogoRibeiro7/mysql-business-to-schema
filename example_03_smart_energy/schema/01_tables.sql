-- ============================================================================
-- Smart Energy Monitoring System - Core Tables
-- ============================================================================
-- Description: Creates tables for commercial building energy management
-- Dependencies: 00_create_database.sql must be run first
-- ============================================================================

USE smart_energy;

-- ============================================================================
-- Building Infrastructure Tables
-- ============================================================================

-- Buildings - Commercial properties being monitored
CREATE TABLE IF NOT EXISTS buildings (
    building_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    building_code VARCHAR(20) UNIQUE NOT NULL,
    building_name VARCHAR(100) NOT NULL,
    address VARCHAR(255) NOT NULL,
    city VARCHAR(100),
    postal_code VARCHAR(20),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    total_area_sqm DECIMAL(10, 2) NOT NULL,
    floors_count INT UNSIGNED NOT NULL,
    year_built YEAR,
    building_type ENUM('office', 'retail', 'mixed', 'industrial', 'residential', 'hotel', 'hospital', 'school') DEFAULT 'office',
    energy_rating VARCHAR(10), -- A+, A, B, C, D, E, F
    occupancy_type ENUM('owner_occupied', 'single_tenant', 'multi_tenant') DEFAULT 'multi_tenant',
    typical_occupancy INT UNSIGNED, -- Typical number of people
    status ENUM('active', 'inactive', 'construction', 'renovation') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_building_code (building_code),
    INDEX idx_building_type (building_type),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Floors - Individual floors in buildings
CREATE TABLE IF NOT EXISTS floors (
    floor_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    building_id INT UNSIGNED NOT NULL,
    floor_number INT NOT NULL,
    floor_name VARCHAR(50),
    area_sqm DECIMAL(10, 2) NOT NULL,
    height_meters DECIMAL(5, 2),
    is_mechanical BOOLEAN DEFAULT FALSE,
    has_hvac_zone BOOLEAN DEFAULT TRUE,
    typical_occupancy INT UNSIGNED,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unique_building_floor (building_id, floor_number),
    INDEX idx_building (building_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Zones - HVAC and energy zones within floors
CREATE TABLE IF NOT EXISTS zones (
    zone_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    zone_code VARCHAR(30) UNIQUE NOT NULL,
    floor_id INT UNSIGNED NOT NULL,
    zone_name VARCHAR(100),
    zone_type ENUM('office', 'conference', 'lobby', 'corridor', 'restroom', 'kitchen', 'server_room', 'storage', 'parking') NOT NULL,
    area_sqm DECIMAL(10, 2) NOT NULL,
    has_windows BOOLEAN DEFAULT TRUE,
    window_orientation ENUM('N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW', 'Multiple', 'None'),
    target_temperature_c DECIMAL(4, 2),
    target_humidity_pct DECIMAL(5, 2),
    occupancy_schedule JSON, -- {"monday": [{"start": "09:00", "end": "18:00"}], ...}
    max_occupancy INT UNSIGNED,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_floor (floor_id),
    INDEX idx_zone_type (zone_type),
    INDEX idx_zone_code (zone_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tenants - Organizations occupying building spaces
CREATE TABLE IF NOT EXISTS tenants (
    tenant_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tenant_code VARCHAR(20) UNIQUE NOT NULL,
    company_name VARCHAR(200) NOT NULL,
    contact_name VARCHAR(100),
    contact_email VARCHAR(150),
    contact_phone VARCHAR(20),
    lease_start_date DATE NOT NULL,
    lease_end_date DATE,
    billing_type ENUM('fixed', 'metered', 'hybrid') DEFAULT 'metered',
    monthly_base_rate DECIMAL(10, 2),
    energy_budget_kwh DECIMAL(10, 2), -- Monthly energy budget
    status ENUM('active', 'pending', 'expired', 'terminated') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_tenant_code (tenant_code),
    INDEX idx_status (status),
    INDEX idx_lease_dates (lease_start_date, lease_end_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tenant Zone Assignments - Which zones are assigned to which tenants
CREATE TABLE IF NOT EXISTS tenant_zone_assignments (
    assignment_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tenant_id INT UNSIGNED NOT NULL,
    zone_id INT UNSIGNED NOT NULL,
    assignment_start_date DATE NOT NULL,
    assignment_end_date DATE,
    is_exclusive BOOLEAN DEFAULT TRUE, -- False for shared spaces
    usage_percentage DECIMAL(5, 2) DEFAULT 100.00, -- For shared spaces
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_tenant_zone_date (tenant_id, zone_id, assignment_start_date),
    INDEX idx_tenant (tenant_id),
    INDEX idx_zone (zone_id),
    INDEX idx_dates (assignment_start_date, assignment_end_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- Energy Infrastructure Tables
-- ============================================================================

-- Meter Types - Categories of energy meters
CREATE TABLE IF NOT EXISTS meter_types (
    meter_type_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    type_code VARCHAR(20) UNIQUE NOT NULL,
    type_name VARCHAR(100) NOT NULL,
    measurement_unit VARCHAR(20) NOT NULL, -- kWh, kW, m3, liters, etc.
    reading_frequency_seconds INT UNSIGNED DEFAULT 300, -- Default 5 minutes
    is_utility_meter BOOLEAN DEFAULT FALSE,
    is_sub_meter BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Energy Meters - All types of meters (electricity, gas, water, etc.)
CREATE TABLE IF NOT EXISTS energy_meters (
    meter_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    meter_code VARCHAR(30) UNIQUE NOT NULL,
    meter_type_id INT UNSIGNED NOT NULL,
    building_id INT UNSIGNED NOT NULL,
    zone_id INT UNSIGNED, -- NULL for main building meters
    meter_name VARCHAR(100),
    manufacturer VARCHAR(100),
    model VARCHAR(100),
    serial_number VARCHAR(100) UNIQUE,
    installation_date DATE NOT NULL,
    calibration_date DATE,
    next_calibration_date DATE,
    max_reading_value DECIMAL(12, 3),
    meter_constant DECIMAL(10, 4) DEFAULT 1.0000, -- Multiplication factor
    is_smart_meter BOOLEAN DEFAULT TRUE,
    communication_type ENUM('modbus', 'bacnet', 'mqtt', 'api', 'manual') DEFAULT 'modbus',
    ip_address VARCHAR(45), -- IPv4 or IPv6
    last_reading_time TIMESTAMP NULL,
    status ENUM('active', 'inactive', 'faulty', 'maintenance') DEFAULT 'active',
    parent_meter_id INT UNSIGNED, -- For sub-metering hierarchy
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_meter_type (meter_type_id),
    INDEX idx_building (building_id),
    INDEX idx_zone (zone_id),
    INDEX idx_status (status),
    INDEX idx_parent_meter (parent_meter_id),
    INDEX idx_meter_code (meter_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- Renewable Energy Systems
-- ============================================================================

-- Solar Systems - Photovoltaic installations
CREATE TABLE IF NOT EXISTS solar_systems (
    system_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    system_code VARCHAR(30) UNIQUE NOT NULL,
    building_id INT UNSIGNED NOT NULL,
    system_name VARCHAR(100),
    installation_date DATE NOT NULL,
    capacity_kw DECIMAL(10, 3) NOT NULL,
    panel_count INT UNSIGNED,
    panel_type VARCHAR(100),
    inverter_model VARCHAR(100),
    inverter_count INT UNSIGNED,
    orientation_degrees INT, -- 0-360, 0=North, 180=South
    tilt_degrees INT, -- 0-90
    annual_production_estimate_kwh DECIMAL(12, 2),
    degradation_rate_yearly DECIMAL(5, 3) DEFAULT 0.5, -- Percentage
    warranty_end_date DATE,
    status ENUM('active', 'inactive', 'maintenance', 'fault') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_building (building_id),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Battery Storage Systems
CREATE TABLE IF NOT EXISTS battery_storage (
    battery_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    battery_code VARCHAR(30) UNIQUE NOT NULL,
    building_id INT UNSIGNED NOT NULL,
    system_name VARCHAR(100),
    manufacturer VARCHAR(100),
    model VARCHAR(100),
    capacity_kwh DECIMAL(10, 3) NOT NULL,
    max_power_kw DECIMAL(10, 3) NOT NULL,
    efficiency_pct DECIMAL(5, 2) DEFAULT 95.0,
    cycles_count INT UNSIGNED DEFAULT 0,
    max_cycles INT UNSIGNED,
    depth_of_discharge_pct DECIMAL(5, 2) DEFAULT 80.0,
    state_of_charge_pct DECIMAL(5, 2),
    installation_date DATE NOT NULL,
    warranty_end_date DATE,
    temperature_c DECIMAL(5, 2),
    status ENUM('active', 'charging', 'discharging', 'idle', 'maintenance', 'fault') DEFAULT 'idle',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_building (building_id),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- HVAC and Equipment Tables
-- ============================================================================

-- HVAC Units - Heating, Ventilation, and Air Conditioning systems
CREATE TABLE IF NOT EXISTS hvac_units (
    unit_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    unit_code VARCHAR(30) UNIQUE NOT NULL,
    building_id INT UNSIGNED NOT NULL,
    unit_name VARCHAR(100),
    unit_type ENUM('ahu', 'vav', 'fcu', 'chiller', 'boiler', 'heat_pump', 'rooftop', 'split') NOT NULL,
    manufacturer VARCHAR(100),
    model VARCHAR(100),
    serial_number VARCHAR(100),
    capacity_kw DECIMAL(10, 3),
    efficiency_rating DECIMAL(5, 2), -- COP, SEER, EER, etc.
    refrigerant_type VARCHAR(20),
    installation_date DATE NOT NULL,
    last_service_date DATE,
    next_service_date DATE,
    operating_hours INT UNSIGNED DEFAULT 0,
    serves_zones JSON, -- Array of zone_ids
    status ENUM('active', 'inactive', 'maintenance', 'fault') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_building (building_id),
    INDEX idx_unit_type (unit_type),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Equipment Inventory - Other energy-consuming equipment
CREATE TABLE IF NOT EXISTS equipment_inventory (
    equipment_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    equipment_code VARCHAR(30) UNIQUE NOT NULL,
    zone_id INT UNSIGNED NOT NULL,
    equipment_type ENUM('lighting', 'computer', 'server', 'printer', 'appliance', 'elevator', 'pump', 'fan', 'other') NOT NULL,
    equipment_name VARCHAR(100),
    manufacturer VARCHAR(100),
    model VARCHAR(100),
    power_rating_watts DECIMAL(10, 2),
    quantity INT UNSIGNED DEFAULT 1,
    usage_hours_per_day DECIMAL(4, 2),
    efficiency_pct DECIMAL(5, 2),
    installation_date DATE,
    status ENUM('active', 'inactive', 'maintenance') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_zone (zone_id),
    INDEX idx_equipment_type (equipment_type),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- Time Series Data Tables
-- ============================================================================

-- Energy Readings - High-frequency energy consumption data (will be partitioned)
CREATE TABLE IF NOT EXISTS energy_readings (
    reading_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    meter_id INT UNSIGNED NOT NULL,
    reading_timestamp TIMESTAMP NOT NULL,
    energy_value DECIMAL(12, 3) NOT NULL, -- Cumulative or instantaneous based on meter type
    power_value DECIMAL(10, 3), -- Instantaneous power (kW)
    power_factor DECIMAL(4, 3), -- For electrical meters
    voltage_v DECIMAL(6, 2), -- For electrical meters
    current_a DECIMAL(8, 2), -- For electrical meters
    frequency_hz DECIMAL(5, 2), -- For electrical meters
    quality_flag ENUM('good', 'estimated', 'manual', 'error') DEFAULT 'good',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_meter_timestamp (meter_id, reading_timestamp),
    INDEX idx_timestamp (reading_timestamp),
    INDEX idx_quality (quality_flag)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Energy Consumption Hourly - Hourly aggregates
CREATE TABLE IF NOT EXISTS energy_consumption_hourly (
    consumption_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    meter_id INT UNSIGNED NOT NULL,
    hour_start TIMESTAMP NOT NULL,
    energy_consumed_kwh DECIMAL(10, 3) NOT NULL,
    avg_power_kw DECIMAL(10, 3),
    max_power_kw DECIMAL(10, 3),
    min_power_kw DECIMAL(10, 3),
    avg_power_factor DECIMAL(4, 3),
    reading_count INT UNSIGNED,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_meter_hour (meter_id, hour_start),
    INDEX idx_hour (hour_start),
    INDEX idx_meter_hour (meter_id, hour_start)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Energy Consumption Daily - Daily aggregates with patterns
CREATE TABLE IF NOT EXISTS energy_consumption_daily (
    consumption_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    meter_id INT UNSIGNED NOT NULL,
    consumption_date DATE NOT NULL,
    total_energy_kwh DECIMAL(12, 3) NOT NULL,
    peak_power_kw DECIMAL(10, 3),
    peak_hour TIME,
    off_peak_energy_kwh DECIMAL(10, 3),
    peak_energy_kwh DECIMAL(10, 3),
    base_load_kw DECIMAL(10, 3), -- Minimum sustained load
    load_factor DECIMAL(4, 3), -- Average load / peak load
    daily_cost DECIMAL(10, 2),
    weather_temp_avg_c DECIMAL(5, 2),
    weather_condition VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_meter_date (meter_id, consumption_date),
    INDEX idx_date (consumption_date),
    INDEX idx_meter_date (meter_id, consumption_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Solar Production - Time series data for solar generation
CREATE TABLE IF NOT EXISTS solar_production (
    production_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    system_id INT UNSIGNED NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    power_kw DECIMAL(10, 3) NOT NULL,
    energy_kwh DECIMAL(10, 3),
    irradiance_w_m2 DECIMAL(8, 2), -- Solar irradiance
    panel_temp_c DECIMAL(5, 2),
    ambient_temp_c DECIMAL(5, 2),
    efficiency_pct DECIMAL(5, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_system_time (system_id, timestamp),
    INDEX idx_timestamp (timestamp)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Battery Status - Battery charge/discharge cycles
CREATE TABLE IF NOT EXISTS battery_status (
    status_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    battery_id INT UNSIGNED NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    state_of_charge_pct DECIMAL(5, 2) NOT NULL,
    power_kw DECIMAL(10, 3), -- Positive=charging, Negative=discharging
    energy_kwh DECIMAL(10, 3),
    voltage_v DECIMAL(8, 2),
    current_a DECIMAL(8, 2),
    temperature_c DECIMAL(5, 2),
    cycle_count INT UNSIGNED,
    health_pct DECIMAL(5, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_battery_time (battery_id, timestamp),
    INDEX idx_timestamp (timestamp)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- HVAC Telemetry - Real-time HVAC performance data
CREATE TABLE IF NOT EXISTS hvac_telemetry (
    telemetry_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    unit_id INT UNSIGNED NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    supply_temp_c DECIMAL(5, 2),
    return_temp_c DECIMAL(5, 2),
    setpoint_temp_c DECIMAL(5, 2),
    outdoor_temp_c DECIMAL(5, 2),
    fan_speed_pct DECIMAL(5, 2),
    compressor_status ENUM('off', 'on', 'variable') DEFAULT 'off',
    power_kw DECIMAL(10, 3),
    efficiency_cop DECIMAL(5, 2), -- Coefficient of Performance
    runtime_minutes INT UNSIGNED,
    fault_code VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_unit_time (unit_id, timestamp),
    INDEX idx_timestamp (timestamp)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- Demand Response and Optimization Tables
-- ============================================================================

-- Demand Response Events - Grid operator requests to reduce load
CREATE TABLE IF NOT EXISTS demand_response_events (
    event_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    event_code VARCHAR(30) UNIQUE NOT NULL,
    event_type ENUM('voluntary', 'mandatory', 'emergency', 'test') NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    target_reduction_kw DECIMAL(10, 3),
    target_reduction_pct DECIMAL(5, 2),
    incentive_rate DECIMAL(10, 4), -- $/kWh reduced
    notification_time TIMESTAMP,
    response_status ENUM('pending', 'accepted', 'declined', 'completed') DEFAULT 'pending',
    actual_reduction_kw DECIMAL(10, 3),
    compliance_pct DECIMAL(5, 2),
    revenue_earned DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_event_time (start_time, end_time),
    INDEX idx_event_type (event_type),
    INDEX idx_status (response_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Load Profiles - Typical consumption patterns
CREATE TABLE IF NOT EXISTS load_profiles (
    profile_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    building_id INT UNSIGNED NOT NULL,
    profile_type ENUM('weekday', 'saturday', 'sunday', 'holiday') NOT NULL,
    season ENUM('winter', 'spring', 'summer', 'fall') NOT NULL,
    hour_of_day TINYINT UNSIGNED NOT NULL, -- 0-23
    typical_load_kw DECIMAL(10, 3),
    min_load_kw DECIMAL(10, 3),
    max_load_kw DECIMAL(10, 3),
    std_deviation_kw DECIMAL(10, 3),
    sample_count INT UNSIGNED,
    last_updated DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_profile (building_id, profile_type, season, hour_of_day),
    INDEX idx_building (building_id),
    INDEX idx_profile_type (profile_type, season)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Energy Forecasts - Predicted consumption
CREATE TABLE IF NOT EXISTS energy_forecasts (
    forecast_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    building_id INT UNSIGNED NOT NULL,
    forecast_timestamp TIMESTAMP NOT NULL,
    forecast_horizon_hours INT UNSIGNED NOT NULL,
    predicted_load_kw DECIMAL(10, 3),
    confidence_lower_kw DECIMAL(10, 3),
    confidence_upper_kw DECIMAL(10, 3),
    weather_temp_c DECIMAL(5, 2),
    is_workday BOOLEAN,
    model_version VARCHAR(20),
    actual_load_kw DECIMAL(10, 3), -- Filled in after the fact
    error_pct DECIMAL(5, 2), -- Calculated after actual is known
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_building_time (building_id, forecast_timestamp),
    INDEX idx_timestamp (forecast_timestamp)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- Billing and Cost Management
-- ============================================================================

-- Utility Rates - Time-of-use electricity rates
CREATE TABLE IF NOT EXISTS utility_rates (
    rate_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    rate_name VARCHAR(100) NOT NULL,
    utility_company VARCHAR(100),
    rate_type ENUM('flat', 'tou', 'tiered', 'demand', 'real_time') NOT NULL,
    effective_date DATE NOT NULL,
    end_date DATE,
    time_periods JSON, -- {"peak": {"start": "14:00", "end": "20:00", "rate": 0.25}, ...}
    demand_charge DECIMAL(10, 4), -- $/kW for peak demand
    fixed_charge DECIMAL(10, 2), -- Monthly fixed charge
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_dates (effective_date, end_date),
    INDEX idx_rate_type (rate_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tenant Billing - Monthly energy bills for tenants
CREATE TABLE IF NOT EXISTS tenant_billing (
    bill_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tenant_id INT UNSIGNED NOT NULL,
    billing_period_start DATE NOT NULL,
    billing_period_end DATE NOT NULL,
    total_energy_kwh DECIMAL(12, 3),
    peak_demand_kw DECIMAL(10, 3),
    energy_charge DECIMAL(10, 2),
    demand_charge DECIMAL(10, 2),
    fixed_charges DECIMAL(10, 2),
    taxes DECIMAL(10, 2),
    total_amount DECIMAL(10, 2),
    payment_status ENUM('pending', 'paid', 'overdue', 'disputed') DEFAULT 'pending',
    payment_date DATE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_tenant (tenant_id),
    INDEX idx_period (billing_period_start, billing_period_end),
    INDEX idx_status (payment_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- Alerts and Maintenance
-- ============================================================================

-- Alert Rules - Configurable alert conditions
CREATE TABLE IF NOT EXISTS alert_rules (
    rule_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    rule_name VARCHAR(100) NOT NULL,
    rule_type ENUM('threshold', 'anomaly', 'equipment', 'cost', 'maintenance') NOT NULL,
    entity_type ENUM('meter', 'hvac', 'solar', 'battery', 'building', 'zone') NOT NULL,
    condition_json JSON NOT NULL, -- {"metric": "power_kw", "operator": ">", "value": 100, "duration_minutes": 15}
    severity ENUM('info', 'warning', 'critical', 'emergency') NOT NULL,
    notification_channels JSON, -- ["email", "sms", "dashboard"]
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_rule_type (rule_type),
    INDEX idx_entity_type (entity_type),
    INDEX idx_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Energy Alerts - Generated alerts
CREATE TABLE IF NOT EXISTS energy_alerts (
    alert_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    rule_id INT UNSIGNED NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id INT UNSIGNED NOT NULL,
    alert_type VARCHAR(100) NOT NULL,
    severity ENUM('info', 'warning', 'critical', 'emergency') NOT NULL,
    triggered_at TIMESTAMP NOT NULL,
    alert_value DECIMAL(12, 3),
    threshold_value DECIMAL(12, 3),
    message TEXT,
    resolved_at TIMESTAMP NULL,
    acknowledged BOOLEAN DEFAULT FALSE,
    acknowledged_by VARCHAR(100),
    acknowledged_at TIMESTAMP NULL,
    resolution_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_rule (rule_id),
    INDEX idx_entity (entity_type, entity_id),
    INDEX idx_triggered (triggered_at),
    INDEX idx_severity (severity),
    INDEX idx_resolved (resolved_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Maintenance Schedules - Preventive maintenance planning
CREATE TABLE IF NOT EXISTS maintenance_schedules (
    schedule_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    equipment_type ENUM('meter', 'hvac', 'solar', 'battery', 'other') NOT NULL,
    equipment_id INT UNSIGNED NOT NULL,
    maintenance_type ENUM('preventive', 'calibration', 'inspection', 'cleaning', 'replacement') NOT NULL,
    scheduled_date DATE NOT NULL,
    frequency_days INT UNSIGNED,
    estimated_duration_hours DECIMAL(5, 2),
    contractor VARCHAR(100),
    estimated_cost DECIMAL(10, 2),
    status ENUM('scheduled', 'in_progress', 'completed', 'cancelled', 'overdue') DEFAULT 'scheduled',
    completed_date DATE,
    actual_cost DECIMAL(10, 2),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_equipment (equipment_type, equipment_id),
    INDEX idx_date (scheduled_date),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- System Performance and Analytics
-- ============================================================================

-- System Performance Metrics - KPIs and benchmarks
CREATE TABLE IF NOT EXISTS performance_metrics (
    metric_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    building_id INT UNSIGNED NOT NULL,
    metric_date DATE NOT NULL,
    energy_intensity_kwh_sqm DECIMAL(10, 3), -- Energy use per square meter
    peak_demand_kw DECIMAL(10, 3),
    load_factor DECIMAL(4, 3),
    renewable_percentage DECIMAL(5, 2),
    carbon_emissions_kg DECIMAL(12, 2),
    cost_per_kwh DECIMAL(6, 4),
    total_cost DECIMAL(10, 2),
    power_quality_score DECIMAL(5, 2), -- 0-100
    equipment_efficiency_score DECIMAL(5, 2), -- 0-100
    benchmark_comparison DECIMAL(5, 2), -- % vs similar buildings
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_building_date (building_id, metric_date),
    INDEX idx_building (building_id),
    INDEX idx_date (metric_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Display confirmation
SELECT 'All smart energy tables created successfully' AS Status;
SELECT COUNT(*) AS table_count FROM information_schema.tables WHERE table_schema = 'smart_energy';
