-- PostgreSQL Schema
-- Converted from MySQL on 2026-02-17T23:11:17.334913
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
ALTER TABLE floors
ADD CONSTRAINT fk_floors_building
FOREIGN KEY (building_id) REFERENCES buildings(building_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE zones
ADD CONSTRAINT fk_zones_floor
FOREIGN KEY (floor_id) REFERENCES floors(floor_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE tenant_zone_assignments
ADD CONSTRAINT fk_tza_tenant
FOREIGN KEY (tenant_id) REFERENCES tenants(tenant_id)
ON DELETE CASCADE ON UPDATE CASCADE,
ADD CONSTRAINT fk_tza_zone
FOREIGN KEY (zone_id) REFERENCES zones(zone_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE energy_meters
ADD CONSTRAINT fk_meters_type
FOREIGN KEY (meter_type_id) REFERENCES meter_types(meter_type_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_meters_building
FOREIGN KEY (building_id) REFERENCES buildings(building_id)
ON DELETE CASCADE ON UPDATE CASCADE,
ADD CONSTRAINT fk_meters_zone
FOREIGN KEY (zone_id) REFERENCES zones(zone_id)
ON DELETE SET NULL ON UPDATE CASCADE,
ADD CONSTRAINT fk_meters_parent
FOREIGN KEY (parent_meter_id) REFERENCES energy_meters(meter_id)
ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE solar_systems
ADD CONSTRAINT fk_solar_building
FOREIGN KEY (building_id) REFERENCES buildings(building_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE battery_storage
ADD CONSTRAINT fk_battery_building
FOREIGN KEY (building_id) REFERENCES buildings(building_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE hvac_units
ADD CONSTRAINT fk_hvac_building
FOREIGN KEY (building_id) REFERENCES buildings(building_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE equipment_inventory
ADD CONSTRAINT fk_equipment_zone
FOREIGN KEY (zone_id) REFERENCES zones(zone_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE energy_readings
ADD CONSTRAINT fk_readings_meter
FOREIGN KEY (meter_id) REFERENCES energy_meters(meter_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE energy_consumption_hourly
ADD CONSTRAINT fk_hourly_meter
FOREIGN KEY (meter_id) REFERENCES energy_meters(meter_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE energy_consumption_daily
ADD CONSTRAINT fk_daily_meter
FOREIGN KEY (meter_id) REFERENCES energy_meters(meter_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE solar_production
ADD CONSTRAINT fk_production_system
FOREIGN KEY (system_id) REFERENCES solar_systems(system_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE battery_status
ADD CONSTRAINT fk_status_battery
FOREIGN KEY (battery_id) REFERENCES battery_storage(battery_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE hvac_telemetry
ADD CONSTRAINT fk_telemetry_unit
FOREIGN KEY (unit_id) REFERENCES hvac_units(unit_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE load_profiles
ADD CONSTRAINT fk_profiles_building
FOREIGN KEY (building_id) REFERENCES buildings(building_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE energy_forecasts
ADD CONSTRAINT fk_forecasts_building
FOREIGN KEY (building_id) REFERENCES buildings(building_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE tenant_billing
ADD CONSTRAINT fk_billing_tenant
FOREIGN KEY (tenant_id) REFERENCES tenants(tenant_id)
ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE energy_alerts
ADD CONSTRAINT fk_alerts_rule
FOREIGN KEY (rule_id) REFERENCES alert_rules(rule_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE performance_metrics
ADD CONSTRAINT fk_metrics_building
FOREIGN KEY (building_id) REFERENCES buildings(building_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE buildings
ADD CONSTRAINT chk_building_area CHECK (total_area_sqm > 0),
ADD CONSTRAINT chk_building_floors CHECK (floors_count > 0),
ADD CONSTRAINT chk_building_occupancy CHECK (typical_occupancy >= 0),
ADD CONSTRAINT chk_building_coords CHECK (
latitude BETWEEN -90 AND 90 AND
longitude BETWEEN -180 AND 180
);
ALTER TABLE floors
ADD CONSTRAINT chk_floor_area CHECK (area_sqm > 0),
ADD CONSTRAINT chk_floor_height CHECK (height_meters IS NULL OR height_meters > 0),
ADD CONSTRAINT chk_floor_occupancy CHECK (typical_occupancy IS NULL OR typical_occupancy >= 0);
ALTER TABLE zones
ADD CONSTRAINT chk_zone_area CHECK (area_sqm > 0),
ADD CONSTRAINT chk_zone_temperature CHECK (
target_temperature_c IS NULL OR
(target_temperature_c >= 10 AND target_temperature_c <= 35)
),
ADD CONSTRAINT chk_zone_humidity CHECK (
target_humidity_pct IS NULL OR
(target_humidity_pct >= 0 AND target_humidity_pct <= 100)
),
ADD CONSTRAINT chk_zone_occupancy CHECK (max_occupancy IS NULL OR max_occupancy >= 0);
ALTER TABLE tenants
ADD CONSTRAINT chk_tenant_lease CHECK (
lease_end_date IS NULL OR lease_end_date >= lease_start_date
),
ADD CONSTRAINT chk_tenant_rate CHECK (
monthly_base_rate IS NULL OR monthly_base_rate >= 0
),
ADD CONSTRAINT chk_tenant_budget CHECK (
energy_budget_kwh IS NULL OR energy_budget_kwh > 0
);
ALTER TABLE tenant_zone_assignments
ADD CONSTRAINT chk_assignment_dates CHECK (
assignment_end_date IS NULL OR assignment_end_date >= assignment_start_date
),
ADD CONSTRAINT chk_assignment_percentage CHECK (
usage_percentage > 0 AND usage_percentage <= 100
);
ALTER TABLE meter_types
ADD CONSTRAINT chk_meter_type_frequency CHECK (reading_frequency_seconds > 0);
ALTER TABLE energy_meters
ADD CONSTRAINT chk_meter_calibration CHECK (
next_calibration_date IS NULL OR
calibration_date IS NULL OR
next_calibration_date > calibration_date
),
ADD CONSTRAINT chk_meter_constant CHECK (meter_constant > 0);
ALTER TABLE solar_systems
ADD CONSTRAINT chk_solar_capacity CHECK (capacity_kw > 0),
ADD CONSTRAINT chk_solar_panels CHECK (panel_count IS NULL OR panel_count > 0),
ADD CONSTRAINT chk_solar_orientation CHECK (
orientation_degrees IS NULL OR
(orientation_degrees >= 0 AND orientation_degrees <= 360)
),
ADD CONSTRAINT chk_solar_tilt CHECK (
tilt_degrees IS NULL OR
(tilt_degrees >= 0 AND tilt_degrees <= 90)
),
ADD CONSTRAINT chk_solar_degradation CHECK (
degradation_rate_yearly >= 0 AND degradation_rate_yearly <= 5
);
ALTER TABLE battery_storage
ADD CONSTRAINT chk_battery_capacity CHECK (capacity_kwh > 0),
ADD CONSTRAINT chk_battery_power CHECK (max_power_kw > 0),
ADD CONSTRAINT chk_battery_efficiency CHECK (
efficiency_pct > 0 AND efficiency_pct <= 100
),
ADD CONSTRAINT chk_battery_dod CHECK (
depth_of_discharge_pct > 0 AND depth_of_discharge_pct <= 100
),
ADD CONSTRAINT chk_battery_soc CHECK (
state_of_charge_pct IS NULL OR
(state_of_charge_pct >= 0 AND state_of_charge_pct <= 100)
),
ADD CONSTRAINT chk_battery_cycles CHECK (
max_cycles IS NULL OR max_cycles > cycles_count
);
ALTER TABLE hvac_units
ADD CONSTRAINT chk_hvac_capacity CHECK (capacity_kw IS NULL OR capacity_kw > 0),
ADD CONSTRAINT chk_hvac_efficiency CHECK (
efficiency_rating IS NULL OR efficiency_rating > 0
),
ADD CONSTRAINT chk_hvac_hours CHECK (operating_hours >= 0);
ALTER TABLE equipment_inventory
ADD CONSTRAINT chk_equipment_power CHECK (
power_rating_watts IS NULL OR power_rating_watts >= 0
),
ADD CONSTRAINT chk_equipment_quantity CHECK (quantity > 0),
ADD CONSTRAINT chk_equipment_hours CHECK (
usage_hours_per_day IS NULL OR
(usage_hours_per_day >= 0 AND usage_hours_per_day <= 24)
),
ADD CONSTRAINT chk_equipment_efficiency CHECK (
efficiency_pct IS NULL OR
(efficiency_pct > 0 AND efficiency_pct <= 100)
);
ALTER TABLE energy_readings
ADD CONSTRAINT chk_readings_power_factor CHECK (
power_factor IS NULL OR
(power_factor >= 0 AND power_factor <= 1)
),
ADD CONSTRAINT chk_readings_voltage CHECK (
voltage_v IS NULL OR voltage_v >= 0
),
ADD CONSTRAINT chk_readings_current CHECK (
current_a IS NULL OR current_a >= 0
),
ADD CONSTRAINT chk_readings_frequency CHECK (
frequency_hz IS NULL OR
(frequency_hz >= 45 AND frequency_hz <= 65)
);
ALTER TABLE energy_consumption_hourly
ADD CONSTRAINT chk_hourly_energy CHECK (energy_consumed_kwh >= 0),
ADD CONSTRAINT chk_hourly_power CHECK (
avg_power_kw IS NULL OR avg_power_kw >= 0
),
ADD CONSTRAINT chk_hourly_power_factor CHECK (
avg_power_factor IS NULL OR
(avg_power_factor >= 0 AND avg_power_factor <= 1)
);
ALTER TABLE energy_consumption_daily
ADD CONSTRAINT chk_daily_energy CHECK (total_energy_kwh >= 0),
ADD CONSTRAINT chk_daily_peak CHECK (peak_power_kw IS NULL OR peak_power_kw >= 0),
ADD CONSTRAINT chk_daily_offpeak CHECK (
off_peak_energy_kwh IS NULL OR off_peak_energy_kwh >= 0
),
ADD CONSTRAINT chk_daily_load_factor CHECK (
load_factor IS NULL OR (load_factor >= 0 AND load_factor <= 1)
),
ADD CONSTRAINT chk_daily_cost CHECK (daily_cost IS NULL OR daily_cost >= 0);
ALTER TABLE solar_production
ADD CONSTRAINT chk_solar_power CHECK (power_kw >= 0),
ADD CONSTRAINT chk_solar_energy CHECK (energy_kwh IS NULL OR energy_kwh >= 0),
ADD CONSTRAINT chk_solar_irradiance CHECK (
irradiance_w_m2 IS NULL OR irradiance_w_m2 >= 0
),
ADD CONSTRAINT chk_solar_efficiency CHECK (
efficiency_pct IS NULL OR
(efficiency_pct >= 0 AND efficiency_pct <= 100)
);
ALTER TABLE battery_status
ADD CONSTRAINT chk_battery_status_soc CHECK (
state_of_charge_pct >= 0 AND state_of_charge_pct <= 100
),
ADD CONSTRAINT chk_battery_status_health CHECK (
health_pct IS NULL OR
(health_pct >= 0 AND health_pct <= 100)
);
ALTER TABLE hvac_telemetry
ADD CONSTRAINT chk_hvac_fan_speed CHECK (
fan_speed_pct IS NULL OR
(fan_speed_pct >= 0 AND fan_speed_pct <= 100)
),
ADD CONSTRAINT chk_hvac_power CHECK (power_kw IS NULL OR power_kw >= 0),
ADD CONSTRAINT chk_hvac_cop CHECK (efficiency_cop IS NULL OR efficiency_cop > 0),
ADD CONSTRAINT chk_hvac_runtime CHECK (
runtime_minutes IS NULL OR runtime_minutes >= 0
);
ALTER TABLE demand_response_events
ADD CONSTRAINT chk_dr_time CHECK (end_time > start_time),
ADD CONSTRAINT chk_dr_reduction CHECK (
target_reduction_kw IS NULL OR target_reduction_kw > 0
),
ADD CONSTRAINT chk_dr_reduction_pct CHECK (
target_reduction_pct IS NULL OR
(target_reduction_pct > 0 AND target_reduction_pct <= 100)
),
ADD CONSTRAINT chk_dr_incentive CHECK (
incentive_rate IS NULL OR incentive_rate >= 0
),
ADD CONSTRAINT chk_dr_compliance CHECK (
compliance_pct IS NULL OR
(compliance_pct >= 0 AND compliance_pct <= 100)
);
ALTER TABLE load_profiles
ADD CONSTRAINT chk_profile_hour CHECK (hour_of_day >= 0 AND hour_of_day <= 23),
ADD CONSTRAINT chk_profile_load CHECK (
typical_load_kw IS NULL OR typical_load_kw >= 0
);
ALTER TABLE energy_forecasts
ADD CONSTRAINT chk_forecast_horizon CHECK (forecast_horizon_hours > 0),
ADD CONSTRAINT chk_forecast_load CHECK (
predicted_load_kw IS NULL OR predicted_load_kw >= 0
),
ADD CONSTRAINT chk_forecast_error CHECK (
error_pct IS NULL OR
(error_pct >= -100 AND error_pct <= 100)
);
ALTER TABLE utility_rates
ADD CONSTRAINT chk_rate_dates CHECK (
end_date IS NULL OR end_date >= effective_date
),
ADD CONSTRAINT chk_rate_demand CHECK (
demand_charge IS NULL OR demand_charge >= 0
),
ADD CONSTRAINT chk_rate_fixed CHECK (
fixed_charge IS NULL OR fixed_charge >= 0
);
ALTER TABLE tenant_billing
ADD CONSTRAINT chk_billing_period CHECK (billing_period_end >= billing_period_start),
ADD CONSTRAINT chk_billing_energy CHECK (
total_energy_kwh IS NULL OR total_energy_kwh >= 0
),
ADD CONSTRAINT chk_billing_amounts CHECK (
energy_charge >= 0 AND
(demand_charge IS NULL OR demand_charge >= 0) AND
(fixed_charges IS NULL OR fixed_charges >= 0) AND
(taxes IS NULL OR taxes >= 0) AND
total_amount >= 0
);
ALTER TABLE maintenance_schedules
ADD CONSTRAINT chk_maintenance_frequency CHECK (
frequency_days IS NULL OR frequency_days > 0
),
ADD CONSTRAINT chk_maintenance_duration CHECK (
estimated_duration_hours IS NULL OR estimated_duration_hours > 0
),
ADD CONSTRAINT chk_maintenance_cost CHECK (
estimated_cost IS NULL OR estimated_cost >= 0
),
ADD CONSTRAINT chk_maintenance_actual_cost CHECK (
actual_cost IS NULL OR actual_cost >= 0
);
ALTER TABLE performance_metrics
ADD CONSTRAINT chk_metrics_intensity CHECK (
energy_intensity_kwh_sqm IS NULL OR energy_intensity_kwh_sqm >= 0
),
ADD CONSTRAINT chk_metrics_demand CHECK (
peak_demand_kw IS NULL OR peak_demand_kw >= 0
),
ADD CONSTRAINT chk_metrics_load_factor CHECK (
load_factor IS NULL OR (load_factor >= 0 AND load_factor <= 1)
),
ADD CONSTRAINT chk_metrics_renewable CHECK (
renewable_percentage IS NULL OR
(renewable_percentage >= 0 AND renewable_percentage <= 100)
),
ADD CONSTRAINT chk_metrics_carbon CHECK (
carbon_emissions_kg IS NULL OR carbon_emissions_kg >= 0
),
ADD CONSTRAINT chk_metrics_cost CHECK (
cost_per_kwh IS NULL OR cost_per_kwh >= 0
),
ADD CONSTRAINT chk_metrics_scores CHECK (
(power_quality_score IS NULL OR (power_quality_score >= 0 AND power_quality_score <= 100)) AND
(equipment_efficiency_score IS NULL OR (equipment_efficiency_score >= 0 AND equipment_efficiency_score <= 100))
);
SELECT 'All constraints created successfully' AS Status;
-- Indexes
