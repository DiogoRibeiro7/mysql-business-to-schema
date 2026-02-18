-- PostgreSQL Schema
-- Converted from MySQL on 2026-02-17T23:11:17.334123
-- Generator: MySQL to PostgreSQL Converter

-- Enum Types
CREATE TYPE buildings_status AS ENUM ('office', 'retail', 'mixed', 'industrial', 'residential', 'hotel', 'hospital', 'school');
CREATE TYPE zones_status AS ENUM ('N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW', 'Multiple', 'None');
CREATE TYPE tenants_status AS ENUM ('fixed', 'metered', 'hybrid');
CREATE TYPE energy_meters_status AS ENUM ('active', 'inactive', 'faulty', 'maintenance');
CREATE TYPE solar_systems_status AS ENUM ('active', 'inactive', 'maintenance', 'fault');
CREATE TYPE battery_storage_status AS ENUM ('active', 'charging', 'discharging', 'idle', 'maintenance', 'fault');
CREATE TYPE hvac_units_status AS ENUM ('ahu', 'vav', 'fcu', 'chiller', 'boiler', 'heat_pump', 'rooftop', 'split');
CREATE TYPE equipment_inventory_status AS ENUM ('active', 'inactive', 'maintenance');
CREATE TYPE hvac_telemetry_status AS ENUM ('off', 'on', 'variable');
CREATE TYPE demand_response_events_status AS ENUM ('pending', 'accepted', 'declined', 'completed');
CREATE TYPE load_profiles_status AS ENUM ('winter', 'spring', 'summer', 'fall');
CREATE TYPE utility_rates_status AS ENUM ('flat', 'tou', 'tiered', 'demand', 'real_time');
CREATE TYPE tenant_billing_status AS ENUM ('pending', 'paid', 'overdue', 'disputed');
CREATE TYPE alert_rules_status AS ENUM ('meter', 'hvac', 'solar', 'battery', 'building', 'zone');
CREATE TYPE energy_alerts_status AS ENUM ('info', 'warning', 'critical', 'emergency');
CREATE TYPE maintenance_schedules_status AS ENUM ('scheduled', 'in_progress', 'completed', 'cancelled', 'overdue');

DROP DATABASE IF EXISTS smart_energy;
-- Create database (run as superuser)
-- CREATE DATABASE smart_energy;
-- \c smart_energy

SELECT 'Database smart_energy created successfully' AS Status;
SELECT 'Focus: Commercial building energy management with IoT sensors' AS Description;
CREATE TABLE IF NOT EXISTS buildings (
    building_name VARCHAR(100) NOT NULL,
    address VARCHAR(255) NOT NULL,
    city VARCHAR(100),
    postal_code VARCHAR(20),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    total_area_sqm DECIMAL(10, 2) NOT NULL,
    floors_count INTEGER NOT NULL,
    year_built INTEGER,
    building_type buildings_status DEFAULT 'office',
    energy_rating VARCHAR(10),
    F TEXT ENUM('owner_occupied', 'single_tenant', 'multi_tenant') DEFAULT 'multi_tenant',
    typical_occupancy INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS floors (
    building_id INTEGER NOT NULL,
    floor_number INTEGER NOT NULL,
    floor_name VARCHAR(50),
    area_sqm DECIMAL(10, 2) NOT NULL,
    height_meters DECIMAL(5, 2),
    is_mechanical BOOLEAN DEFAULT FALSE,
    has_hvac_zone BOOLEAN DEFAULT TRUE,
    typical_occupancy INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (building_id, floor_number)
);

CREATE TABLE IF NOT EXISTS zones (
    floor_id INTEGER NOT NULL,
    zone_name VARCHAR(100),
    zone_type zones_status NOT NULL,
    area_sqm DECIMAL(10, 2) NOT NULL,
    has_windows BOOLEAN DEFAULT TRUE,
    window_orientation zones_status,
    target_temperature_c DECIMAL(4, 2),
    target_humidity_pct DECIMAL(5, 2),
    occupancy_schedule JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tenants (
    company_name VARCHAR(200) NOT NULL,
    contact_name VARCHAR(100),
    contact_email VARCHAR(150),
    contact_phone VARCHAR(20),
    lease_start_date DATE NOT NULL,
    lease_end_date DATE,
    billing_type tenants_status DEFAULT 'metered',
    monthly_base_rate DECIMAL(10, 2),
    energy_budget_kwh DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tenant_zone_assignments (
    tenant_id INTEGER NOT NULL,
    zone_id INTEGER NOT NULL,
    assignment_start_date DATE NOT NULL,
    assignment_end_date DATE,
    is_exclusive BOOLEAN DEFAULT TRUE,
    UNIQUE (tenant_id, zone_id, assignment_start_date)
);

CREATE TABLE IF NOT EXISTS meter_types (
    type_name VARCHAR(100) NOT NULL,
    measurement_unit VARCHAR(20) NOT NULL,
    is_sub_meter BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS energy_meters (
    meter_type_id INTEGER NOT NULL,
    building_id INTEGER NOT NULL,
    zone_id INTEGER,
    manufacturer VARCHAR(100),
    model VARCHAR(100),
    installation_date DATE NOT NULL,
    calibration_date DATE,
    next_calibration_date DATE,
    max_reading_value DECIMAL(12, 3),
    meter_constant DECIMAL(10, 4) DEFAULT 1.0000,
    communication_type energy_meters_status DEFAULT 'modbus',
    ip_address VARCHAR(45),
    status energy_meters_status DEFAULT 'active',
    parent_meter_id INTEGER,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS solar_systems (
    building_id INTEGER NOT NULL,
    system_name VARCHAR(100),
    installation_date DATE NOT NULL,
    capacity_kw DECIMAL(10, 3) NOT NULL,
    panel_count INTEGER,
    panel_type VARCHAR(100),
    inverter_model VARCHAR(100),
    inverter_count INTEGER,
    orientation_degrees INTEGER,
    degradation_rate_yearly DECIMAL(5, 3) DEFAULT 0.5,
    status solar_systems_status DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS battery_storage (
    building_id INTEGER NOT NULL,
    system_name VARCHAR(100),
    manufacturer VARCHAR(100),
    model VARCHAR(100),
    capacity_kwh DECIMAL(10, 3) NOT NULL,
    max_power_kw DECIMAL(10, 3) NOT NULL,
    efficiency_pct DECIMAL(5, 2) DEFAULT 95.0,
    cycles_count INTEGER DEFAULT 0,
    max_cycles INTEGER,
    depth_of_discharge_pct DECIMAL(5, 2) DEFAULT 80.0,
    state_of_charge_pct DECIMAL(5, 2),
    installation_date DATE NOT NULL,
    warranty_end_date DATE,
    temperature_c DECIMAL(5, 2),
    status battery_storage_status DEFAULT 'idle',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS hvac_units (
    building_id INTEGER NOT NULL,
    unit_name VARCHAR(100),
    unit_type hvac_units_status NOT NULL,
    manufacturer VARCHAR(100),
    model VARCHAR(100),
    serial_number VARCHAR(100),
    capacity_kw DECIMAL(10, 3),
    efficiency_rating DECIMAL(5, 2),
    installation_date DATE NOT NULL,
    last_service_date DATE,
    next_service_date DATE,
    operating_hours INTEGER DEFAULT 0,
    serves_zones JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS equipment_inventory (
    zone_id INTEGER NOT NULL,
    equipment_type equipment_inventory_status NOT NULL,
    equipment_name VARCHAR(100),
    manufacturer VARCHAR(100),
    model VARCHAR(100),
    power_rating_watts DECIMAL(10, 2),
    quantity INTEGER DEFAULT 1,
    usage_hours_per_day DECIMAL(4, 2),
    efficiency_pct DECIMAL(5, 2),
    installation_date DATE,
    status equipment_inventory_status DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS energy_readings (
    meter_id INTEGER NOT NULL,
    reading_timestamp TIMESTAMP NOT NULL,
    energy_value DECIMAL(12, 3) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS energy_consumption_hourly (
    meter_id INTEGER NOT NULL,
    hour_start TIMESTAMP NOT NULL,
    energy_consumed_kwh DECIMAL(10, 3) NOT NULL,
    avg_power_kw DECIMAL(10, 3),
    max_power_kw DECIMAL(10, 3),
    min_power_kw DECIMAL(10, 3),
    avg_power_factor DECIMAL(4, 3),
    reading_count INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (meter_id, hour_start)
);

CREATE TABLE IF NOT EXISTS energy_consumption_daily (
    meter_id INTEGER NOT NULL,
    consumption_date DATE NOT NULL,
    total_energy_kwh DECIMAL(12, 3) NOT NULL,
    peak_power_kw DECIMAL(10, 3),
    peak_hour TIME,
    off_peak_energy_kwh DECIMAL(10, 3),
    peak_energy_kwh DECIMAL(10, 3),
    base_load_kw DECIMAL(10, 3),
    weather_temp_avg_c DECIMAL(5, 2),
    weather_condition VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (meter_id, consumption_date)
);

CREATE TABLE IF NOT EXISTS solar_production (
    system_id INTEGER NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    power_kw DECIMAL(10, 3) NOT NULL,
    energy_kwh DECIMAL(10, 3),
    irradiance_w_m2 DECIMAL(8, 2),
    ambient_temp_c DECIMAL(5, 2),
    efficiency_pct DECIMAL(5, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS battery_status (
    battery_id INTEGER NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    state_of_charge_pct DECIMAL(5, 2) NOT NULL,
    power_kw DECIMAL(10, 3),
    voltage_v DECIMAL(8, 2),
    current_a DECIMAL(8, 2),
    temperature_c DECIMAL(5, 2),
    cycle_count INTEGER,
    health_pct DECIMAL(5, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS hvac_telemetry (
    unit_id INTEGER NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    supply_temp_c DECIMAL(5, 2),
    return_temp_c DECIMAL(5, 2),
    setpoint_temp_c DECIMAL(5, 2),
    outdoor_temp_c DECIMAL(5, 2),
    fan_speed_pct DECIMAL(5, 2),
    compressor_status hvac_telemetry_status DEFAULT 'off',
    power_kw DECIMAL(10, 3),
    efficiency_cop DECIMAL(5, 2),
    fault_code VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS demand_response_events (
    event_type demand_response_events_status NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    target_reduction_kw DECIMAL(10, 3),
    target_reduction_pct DECIMAL(5, 2),
    incentive_rate DECIMAL(10, 4),
    response_status demand_response_events_status DEFAULT 'pending',
    actual_reduction_kw DECIMAL(10, 3),
    compliance_pct DECIMAL(5, 2),
    revenue_earned DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS load_profiles (
    building_id INTEGER NOT NULL,
    profile_type load_profiles_status NOT NULL,
    season load_profiles_status NOT NULL,
    hour_of_day SMALLINT NOT NULL,
    min_load_kw DECIMAL(10, 3),
    max_load_kw DECIMAL(10, 3),
    std_deviation_kw DECIMAL(10, 3),
    sample_count INTEGER,
    last_updated DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (building_id, profile_type, season, hour_of_day)
);

CREATE TABLE IF NOT EXISTS energy_forecasts (
    building_id INTEGER NOT NULL,
    forecast_timestamp TIMESTAMP NOT NULL,
    forecast_horizon_hours INTEGER NOT NULL,
    predicted_load_kw DECIMAL(10, 3),
    confidence_lower_kw DECIMAL(10, 3),
    confidence_upper_kw DECIMAL(10, 3),
    weather_temp_c DECIMAL(5, 2),
    is_workday BOOLEAN,
    model_version VARCHAR(20),
    actual_load_kw DECIMAL(10, 3)
);

CREATE TABLE IF NOT EXISTS utility_rates (
    rate_name VARCHAR(100) NOT NULL,
    utility_company VARCHAR(100),
    rate_type utility_rates_status NOT NULL,
    effective_date DATE NOT NULL,
    end_date DATE,
    time_periods JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tenant_billing (
    tenant_id INTEGER NOT NULL,
    billing_period_start DATE NOT NULL,
    billing_period_end DATE NOT NULL,
    total_energy_kwh DECIMAL(12, 3),
    peak_demand_kw DECIMAL(10, 3),
    energy_charge DECIMAL(10, 2),
    demand_charge DECIMAL(10, 2),
    fixed_charges DECIMAL(10, 2),
    taxes DECIMAL(10, 2),
    total_amount DECIMAL(10, 2),
    payment_status tenant_billing_status DEFAULT 'pending',
    payment_date DATE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS alert_rules (
    rule_name VARCHAR(100) NOT NULL,
    rule_type alert_rules_status NOT NULL,
    entity_type alert_rules_status NOT NULL,
    condition_json JSONB NOT NULL,
    notification_channels JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS energy_alerts (
    rule_id INTEGER NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id INTEGER NOT NULL,
    alert_type VARCHAR(100) NOT NULL,
    severity energy_alerts_status NOT NULL,
    triggered_at TIMESTAMP NOT NULL,
    alert_value DECIMAL(12, 3),
    threshold_value DECIMAL(12, 3),
    message TEXT,
    resolved_at TIMESTAMP NULL,
    acknowledged BOOLEAN DEFAULT FALSE,
    acknowledged_by VARCHAR(100),
    acknowledged_at TIMESTAMP NULL,
    resolution_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS maintenance_schedules (
    equipment_type maintenance_schedules_status NOT NULL,
    equipment_id INTEGER NOT NULL,
    maintenance_type maintenance_schedules_status NOT NULL,
    scheduled_date DATE NOT NULL,
    frequency_days INTEGER,
    estimated_duration_hours DECIMAL(5, 2),
    contractor VARCHAR(100),
    estimated_cost DECIMAL(10, 2),
    status maintenance_schedules_status DEFAULT 'scheduled',
    completed_date DATE,
    actual_cost DECIMAL(10, 2),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS performance_metrics (
    building_id INTEGER NOT NULL,
    metric_date DATE NOT NULL,
    energy_intensity_kwh_sqm DECIMAL(10, 3),
    load_factor DECIMAL(4, 3),
    renewable_percentage DECIMAL(5, 2),
    carbon_emissions_kg DECIMAL(12, 2),
    cost_per_kwh DECIMAL(6, 4),
    total_cost DECIMAL(10, 2),
    power_quality_score DECIMAL(5, 2),
    UNIQUE (building_id, metric_date)
);

SELECT 'All smart energy tables created successfully' AS Status;
SELECT COUNT(*) AS table_count FROM information_schema.tables
WHERE table_schema = 'smart_energy';
-- Indexes
