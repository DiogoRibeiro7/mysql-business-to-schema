-- ============================================================================
-- Smart Energy Monitoring System - Constraints
-- ============================================================================
-- Description: Defines foreign keys, check constraints, and referential integrity
-- Dependencies: 01_tables.sql must be run first
-- ============================================================================

USE smart_energy;

-- ============================================================================
-- Foreign Key Constraints - Building Infrastructure
-- ============================================================================

-- Floors table
ALTER TABLE floors
    ADD CONSTRAINT fk_floors_building
        FOREIGN KEY (building_id) REFERENCES buildings(building_id)
        ON DELETE CASCADE ON UPDATE CASCADE;

-- Zones table
ALTER TABLE zones
    ADD CONSTRAINT fk_zones_floor
        FOREIGN KEY (floor_id) REFERENCES floors(floor_id)
        ON DELETE CASCADE ON UPDATE CASCADE;

-- Tenant Zone Assignments
ALTER TABLE tenant_zone_assignments
    ADD CONSTRAINT fk_tza_tenant
        FOREIGN KEY (tenant_id) REFERENCES tenants(tenant_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    ADD CONSTRAINT fk_tza_zone
        FOREIGN KEY (zone_id) REFERENCES zones(zone_id)
        ON DELETE CASCADE ON UPDATE CASCADE;

-- ============================================================================
-- Foreign Key Constraints - Energy Infrastructure
-- ============================================================================

-- Energy Meters
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

-- Solar Systems
ALTER TABLE solar_systems
    ADD CONSTRAINT fk_solar_building
        FOREIGN KEY (building_id) REFERENCES buildings(building_id)
        ON DELETE CASCADE ON UPDATE CASCADE;

-- Battery Storage
ALTER TABLE battery_storage
    ADD CONSTRAINT fk_battery_building
        FOREIGN KEY (building_id) REFERENCES buildings(building_id)
        ON DELETE CASCADE ON UPDATE CASCADE;

-- ============================================================================
-- Foreign Key Constraints - Equipment
-- ============================================================================

-- HVAC Units
ALTER TABLE hvac_units
    ADD CONSTRAINT fk_hvac_building
        FOREIGN KEY (building_id) REFERENCES buildings(building_id)
        ON DELETE CASCADE ON UPDATE CASCADE;

-- Equipment Inventory
ALTER TABLE equipment_inventory
    ADD CONSTRAINT fk_equipment_zone
        FOREIGN KEY (zone_id) REFERENCES zones(zone_id)
        ON DELETE CASCADE ON UPDATE CASCADE;

-- ============================================================================
-- Foreign Key Constraints - Time Series Data
-- ============================================================================

-- Energy Readings
ALTER TABLE energy_readings
    ADD CONSTRAINT fk_readings_meter
        FOREIGN KEY (meter_id) REFERENCES energy_meters(meter_id)
        ON DELETE CASCADE ON UPDATE CASCADE;

-- Energy Consumption Hourly
ALTER TABLE energy_consumption_hourly
    ADD CONSTRAINT fk_hourly_meter
        FOREIGN KEY (meter_id) REFERENCES energy_meters(meter_id)
        ON DELETE CASCADE ON UPDATE CASCADE;

-- Energy Consumption Daily
ALTER TABLE energy_consumption_daily
    ADD CONSTRAINT fk_daily_meter
        FOREIGN KEY (meter_id) REFERENCES energy_meters(meter_id)
        ON DELETE CASCADE ON UPDATE CASCADE;

-- Solar Production
ALTER TABLE solar_production
    ADD CONSTRAINT fk_production_system
        FOREIGN KEY (system_id) REFERENCES solar_systems(system_id)
        ON DELETE CASCADE ON UPDATE CASCADE;

-- Battery Status
ALTER TABLE battery_status
    ADD CONSTRAINT fk_status_battery
        FOREIGN KEY (battery_id) REFERENCES battery_storage(battery_id)
        ON DELETE CASCADE ON UPDATE CASCADE;

-- HVAC Telemetry
ALTER TABLE hvac_telemetry
    ADD CONSTRAINT fk_telemetry_unit
        FOREIGN KEY (unit_id) REFERENCES hvac_units(unit_id)
        ON DELETE CASCADE ON UPDATE CASCADE;

-- ============================================================================
-- Foreign Key Constraints - Optimization
-- ============================================================================

-- Load Profiles
ALTER TABLE load_profiles
    ADD CONSTRAINT fk_profiles_building
        FOREIGN KEY (building_id) REFERENCES buildings(building_id)
        ON DELETE CASCADE ON UPDATE CASCADE;

-- Energy Forecasts
ALTER TABLE energy_forecasts
    ADD CONSTRAINT fk_forecasts_building
        FOREIGN KEY (building_id) REFERENCES buildings(building_id)
        ON DELETE CASCADE ON UPDATE CASCADE;

-- ============================================================================
-- Foreign Key Constraints - Billing
-- ============================================================================

-- Tenant Billing
ALTER TABLE tenant_billing
    ADD CONSTRAINT fk_billing_tenant
        FOREIGN KEY (tenant_id) REFERENCES tenants(tenant_id)
        ON DELETE RESTRICT ON UPDATE CASCADE;

-- ============================================================================
-- Foreign Key Constraints - Alerts
-- ============================================================================

-- Energy Alerts
ALTER TABLE energy_alerts
    ADD CONSTRAINT fk_alerts_rule
        FOREIGN KEY (rule_id) REFERENCES alert_rules(rule_id)
        ON DELETE CASCADE ON UPDATE CASCADE;

-- ============================================================================
-- Foreign Key Constraints - Performance
-- ============================================================================

-- Performance Metrics
ALTER TABLE performance_metrics
    ADD CONSTRAINT fk_metrics_building
        FOREIGN KEY (building_id) REFERENCES buildings(building_id)
        ON DELETE CASCADE ON UPDATE CASCADE;

-- ============================================================================
-- Check Constraints
-- ============================================================================

-- Buildings
ALTER TABLE buildings
    ADD CONSTRAINT chk_building_area CHECK (total_area_sqm > 0),
    ADD CONSTRAINT chk_building_floors CHECK (floors_count > 0),
    ADD CONSTRAINT chk_building_occupancy CHECK (typical_occupancy >= 0),
    ADD CONSTRAINT chk_building_coords CHECK (
        latitude BETWEEN -90 AND 90 AND
        longitude BETWEEN -180 AND 180
    );

-- Floors
ALTER TABLE floors
    ADD CONSTRAINT chk_floor_area CHECK (area_sqm > 0),
    ADD CONSTRAINT chk_floor_height CHECK (height_meters IS NULL OR height_meters > 0),
    ADD CONSTRAINT chk_floor_occupancy CHECK (typical_occupancy IS NULL OR typical_occupancy >= 0);

-- Zones
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

-- Tenants
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

-- Tenant Zone Assignments
ALTER TABLE tenant_zone_assignments
    ADD CONSTRAINT chk_assignment_dates CHECK (
        assignment_end_date IS NULL OR assignment_end_date >= assignment_start_date
    ),
    ADD CONSTRAINT chk_assignment_percentage CHECK (
        usage_percentage > 0 AND usage_percentage <= 100
    );

-- Meter Types
ALTER TABLE meter_types
    ADD CONSTRAINT chk_meter_type_frequency CHECK (reading_frequency_seconds > 0);

-- Energy Meters
ALTER TABLE energy_meters
    ADD CONSTRAINT chk_meter_calibration CHECK (
        next_calibration_date IS NULL OR
        calibration_date IS NULL OR
        next_calibration_date > calibration_date
    ),
    ADD CONSTRAINT chk_meter_constant CHECK (meter_constant > 0);

-- Solar Systems
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

-- Battery Storage
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

-- HVAC Units
ALTER TABLE hvac_units
    ADD CONSTRAINT chk_hvac_capacity CHECK (capacity_kw IS NULL OR capacity_kw > 0),
    ADD CONSTRAINT chk_hvac_efficiency CHECK (
        efficiency_rating IS NULL OR efficiency_rating > 0
    ),
    ADD CONSTRAINT chk_hvac_hours CHECK (operating_hours >= 0);

-- Equipment Inventory
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

-- Energy Readings
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

-- Energy Consumption Hourly
ALTER TABLE energy_consumption_hourly
    ADD CONSTRAINT chk_hourly_energy CHECK (energy_consumed_kwh >= 0),
    ADD CONSTRAINT chk_hourly_power CHECK (
        avg_power_kw IS NULL OR avg_power_kw >= 0
    ),
    ADD CONSTRAINT chk_hourly_power_factor CHECK (
        avg_power_factor IS NULL OR
        (avg_power_factor >= 0 AND avg_power_factor <= 1)
    );

-- Energy Consumption Daily
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

-- Solar Production
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

-- Battery Status
ALTER TABLE battery_status
    ADD CONSTRAINT chk_battery_status_soc CHECK (
        state_of_charge_pct >= 0 AND state_of_charge_pct <= 100
    ),
    ADD CONSTRAINT chk_battery_status_health CHECK (
        health_pct IS NULL OR
        (health_pct >= 0 AND health_pct <= 100)
    );

-- HVAC Telemetry
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

-- Demand Response Events
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

-- Load Profiles
ALTER TABLE load_profiles
    ADD CONSTRAINT chk_profile_hour CHECK (hour_of_day >= 0 AND hour_of_day <= 23),
    ADD CONSTRAINT chk_profile_load CHECK (
        typical_load_kw IS NULL OR typical_load_kw >= 0
    );

-- Energy Forecasts
ALTER TABLE energy_forecasts
    ADD CONSTRAINT chk_forecast_horizon CHECK (forecast_horizon_hours > 0),
    ADD CONSTRAINT chk_forecast_load CHECK (
        predicted_load_kw IS NULL OR predicted_load_kw >= 0
    ),
    ADD CONSTRAINT chk_forecast_error CHECK (
        error_pct IS NULL OR
        (error_pct >= -100 AND error_pct <= 100)
    );

-- Utility Rates
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

-- Tenant Billing
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

-- Maintenance Schedules
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

-- Performance Metrics
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

-- Display confirmation
SELECT 'All constraints created successfully' AS Status;
