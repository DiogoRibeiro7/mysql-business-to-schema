-- ============================================================================
-- Smart Agriculture Constraints
-- ============================================================================

USE smart_agriculture;

-- ============================================================================
-- Foreign Key Constraints
-- ============================================================================

-- Fields -> Farms
ALTER TABLE fields
    ADD CONSTRAINT fk_field_farm
    FOREIGN KEY (farm_id) REFERENCES farms(farm_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- Zones -> Fields
ALTER TABLE zones
    ADD CONSTRAINT fk_zone_field
    FOREIGN KEY (field_id) REFERENCES fields(field_id)
    ON DELETE CASCADE ON UPDATE CASCADE;

-- Planting records -> Fields, Zones, and Crops
ALTER TABLE planting_records
    ADD CONSTRAINT fk_planting_field
    FOREIGN KEY (field_id) REFERENCES fields(field_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
    ADD CONSTRAINT fk_planting_zone
    FOREIGN KEY (zone_id) REFERENCES zones(zone_id)
    ON DELETE SET NULL ON UPDATE CASCADE,
    ADD CONSTRAINT fk_planting_crop
    FOREIGN KEY (crop_id) REFERENCES crops(crop_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- Growth stages -> Planting records
ALTER TABLE growth_stages
    ADD CONSTRAINT fk_stage_planting
    FOREIGN KEY (planting_id) REFERENCES planting_records(planting_id)
    ON DELETE CASCADE ON UPDATE CASCADE;

-- Sensors -> Zones
ALTER TABLE sensors
    ADD CONSTRAINT fk_sensor_zone
    FOREIGN KEY (zone_id) REFERENCES zones(zone_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- Weather stations -> Farms
ALTER TABLE weather_stations
    ADD CONSTRAINT fk_station_farm
    FOREIGN KEY (farm_id) REFERENCES farms(farm_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- Weather data -> Weather stations
ALTER TABLE weather_data
    ADD CONSTRAINT fk_weather_station
    FOREIGN KEY (station_id) REFERENCES weather_stations(station_id)
    ON DELETE CASCADE ON UPDATE CASCADE;

-- Irrigation systems -> Fields
ALTER TABLE irrigation_systems
    ADD CONSTRAINT fk_irrigation_field
    FOREIGN KEY (field_id) REFERENCES fields(field_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- Irrigation events -> Systems and Zones
ALTER TABLE irrigation_events
    ADD CONSTRAINT fk_event_system
    FOREIGN KEY (system_id) REFERENCES irrigation_systems(system_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
    ADD CONSTRAINT fk_event_zone
    FOREIGN KEY (zone_id) REFERENCES zones(zone_id)
    ON DELETE SET NULL ON UPDATE CASCADE;

-- Irrigation schedules -> Systems
ALTER TABLE irrigation_schedules
    ADD CONSTRAINT fk_schedule_system
    FOREIGN KEY (system_id) REFERENCES irrigation_systems(system_id)
    ON DELETE CASCADE ON UPDATE CASCADE;

-- Fertilizer applications -> Fields and Zones
ALTER TABLE fertilizer_applications
    ADD CONSTRAINT fk_fertilizer_field
    FOREIGN KEY (field_id) REFERENCES fields(field_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
    ADD CONSTRAINT fk_fertilizer_zone
    FOREIGN KEY (zone_id) REFERENCES zones(zone_id)
    ON DELETE SET NULL ON UPDATE CASCADE,
    ADD CONSTRAINT fk_fertilizer_operator
    FOREIGN KEY (operator_id) REFERENCES operators(operator_id)
    ON DELETE SET NULL ON UPDATE CASCADE;

-- Pesticide applications -> Fields and Zones
ALTER TABLE pesticide_applications
    ADD CONSTRAINT fk_pesticide_field
    FOREIGN KEY (field_id) REFERENCES fields(field_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
    ADD CONSTRAINT fk_pesticide_zone
    FOREIGN KEY (zone_id) REFERENCES zones(zone_id)
    ON DELETE SET NULL ON UPDATE CASCADE,
    ADD CONSTRAINT fk_pesticide_operator
    FOREIGN KEY (operator_id) REFERENCES operators(operator_id)
    ON DELETE SET NULL ON UPDATE CASCADE;

-- Animals -> Farms and parent relationships
ALTER TABLE animals
    ADD CONSTRAINT fk_animal_farm
    FOREIGN KEY (farm_id) REFERENCES farms(farm_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
    ADD CONSTRAINT fk_animal_mother
    FOREIGN KEY (mother_id) REFERENCES animals(animal_id)
    ON DELETE SET NULL ON UPDATE CASCADE,
    ADD CONSTRAINT fk_animal_father
    FOREIGN KEY (father_id) REFERENCES animals(animal_id)
    ON DELETE SET NULL ON UPDATE CASCADE;

-- Health records -> Animals
ALTER TABLE health_records
    ADD CONSTRAINT fk_health_animal
    FOREIGN KEY (animal_id) REFERENCES animals(animal_id)
    ON DELETE CASCADE ON UPDATE CASCADE;

-- Milk production -> Animals
ALTER TABLE milk_production
    ADD CONSTRAINT fk_milk_animal
    FOREIGN KEY (animal_id) REFERENCES animals(animal_id)
    ON DELETE CASCADE ON UPDATE CASCADE;

-- Harvest records -> Planting records
ALTER TABLE harvest_records
    ADD CONSTRAINT fk_harvest_planting
    FOREIGN KEY (planting_id) REFERENCES planting_records(planting_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- Yield predictions -> Planting records
ALTER TABLE yield_predictions
    ADD CONSTRAINT fk_prediction_planting
    FOREIGN KEY (planting_id) REFERENCES planting_records(planting_id)
    ON DELETE CASCADE ON UPDATE CASCADE;

-- Operators -> Farms
ALTER TABLE operators
    ADD CONSTRAINT fk_operator_farm
    FOREIGN KEY (farm_id) REFERENCES farms(farm_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- ============================================================================
-- Check Constraints
-- ============================================================================

-- Ensure positive areas
ALTER TABLE farms
    ADD CONSTRAINT chk_farm_area
    CHECK (total_area_hectares > 0);

ALTER TABLE fields
    ADD CONSTRAINT chk_field_area
    CHECK (area_hectares > 0);

ALTER TABLE zones
    ADD CONSTRAINT chk_zone_area
    CHECK (area_hectares > 0);

-- Ensure valid coordinates
ALTER TABLE farms
    ADD CONSTRAINT chk_farm_coordinates
    CHECK (latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180);

-- Ensure valid percentages
ALTER TABLE fields
    ADD CONSTRAINT chk_field_slope
    CHECK (slope_percentage BETWEEN 0 AND 100);

ALTER TABLE irrigation_systems
    ADD CONSTRAINT chk_irrigation_efficiency
    CHECK (efficiency_percentage BETWEEN 0 AND 100);

-- Ensure harvest after planting
ALTER TABLE planting_records
    ADD CONSTRAINT chk_planting_dates
    CHECK (expected_harvest_date > planting_date AND
           (actual_harvest_date IS NULL OR actual_harvest_date > planting_date));

-- Ensure valid sensor depths
ALTER TABLE sensors
    ADD CONSTRAINT chk_sensor_depth
    CHECK ((sensor_type LIKE 'soil_%' AND depth_cm > 0) OR
           (sensor_type NOT LIKE 'soil_%'));

-- Ensure valid irrigation times
ALTER TABLE irrigation_events
    ADD CONSTRAINT chk_irrigation_times
    CHECK (end_time IS NULL OR end_time > start_time);

-- Ensure valid moisture values
ALTER TABLE irrigation_events
    ADD CONSTRAINT chk_moisture_values
    CHECK ((soil_moisture_before BETWEEN 0 AND 100 OR soil_moisture_before IS NULL) AND
           (soil_moisture_after BETWEEN 0 AND 100 OR soil_moisture_after IS NULL));

-- Ensure valid crop pH ranges
ALTER TABLE crops
    ADD CONSTRAINT chk_crop_ph
    CHECK (optimal_ph_min <= optimal_ph_max);

-- Ensure valid temperature ranges
ALTER TABLE crops
    ADD CONSTRAINT chk_crop_temp
    CHECK (optimal_temp_min <= optimal_temp_max);

-- Ensure positive yields
ALTER TABLE harvest_records
    ADD CONSTRAINT chk_harvest_yield
    CHECK (total_yield_kg >= 0 AND marketable_yield_kg >= 0 AND
           marketable_yield_kg <= total_yield_kg);

-- Ensure valid percentages in milk production
ALTER TABLE milk_production
    ADD CONSTRAINT chk_milk_percentages
    CHECK (fat_percentage BETWEEN 0 AND 20 AND
           protein_percentage BETWEEN 0 AND 10);

-- ============================================================================
-- Triggers for Business Logic
-- ============================================================================

DELIMITER $$

-- Update planting status based on dates
CREATE TRIGGER trg_update_planting_status
BEFORE UPDATE ON planting_records
FOR EACH ROW
BEGIN
    IF NEW.actual_harvest_date IS NOT NULL THEN
        SET NEW.status = 'harvested';
    ELSEIF NEW.planting_date <= CURDATE() AND OLD.status = 'planned' THEN
        SET NEW.status = 'planted';
    END IF;
END$$

-- Calculate actual yield per hectare
CREATE TRIGGER trg_calculate_yield_per_hectare
BEFORE INSERT ON harvest_records
FOR EACH ROW
BEGIN
    DECLARE v_area_planted DECIMAL(10,2);

    SELECT area_planted_hectares INTO v_area_planted
    FROM planting_records
    WHERE planting_id = NEW.planting_id;

    IF NEW.area_harvested_hectares > 0 THEN
        UPDATE planting_records
        SET actual_yield_kg_per_hectare = NEW.total_yield_kg / NEW.area_harvested_hectares,
            status = 'harvested',
            actual_harvest_date = NEW.harvest_date
        WHERE planting_id = NEW.planting_id;
    END IF;
END$$

-- Trigger irrigation based on soil moisture
CREATE TRIGGER trg_check_irrigation_need
AFTER INSERT ON sensor_readings
FOR EACH ROW
BEGIN
    DECLARE v_sensor_type VARCHAR(50);
    DECLARE v_zone_id INT;
    DECLARE v_threshold_min DECIMAL(5,2);

    SELECT sensor_type, zone_id INTO v_sensor_type, v_zone_id
    FROM sensors
    WHERE sensor_id = NEW.sensor_id;

    IF v_sensor_type = 'soil_moisture' THEN
        SELECT moisture_threshold_min INTO v_threshold_min
        FROM irrigation_schedules isch
        INNER JOIN irrigation_systems isys ON isch.system_id = isys.system_id
        INNER JOIN fields f ON isys.field_id = f.field_id
        INNER JOIN zones z ON f.field_id = z.field_id
        WHERE z.zone_id = v_zone_id
          AND isch.is_active = TRUE
        LIMIT 1;

        IF NEW.value < v_threshold_min THEN
            -- Log irrigation need (would trigger actual irrigation in real system)
            INSERT INTO irrigation_events (system_id, zone_id, start_time, trigger_type, trigger_reason, soil_moisture_before)
            SELECT isys.system_id, v_zone_id, NOW(), 'sensor',
                   CONCAT('Soil moisture ', NEW.value, '% below threshold ', v_threshold_min, '%'),
                   NEW.value
            FROM irrigation_systems isys
            INNER JOIN fields f ON isys.field_id = f.field_id
            INNER JOIN zones z ON f.field_id = z.field_id
            WHERE z.zone_id = v_zone_id
              AND isys.is_active = TRUE
            LIMIT 1;
        END IF;
    END IF;
END$$

-- Update animal health status
CREATE TRIGGER trg_update_animal_health
AFTER INSERT ON health_records
FOR EACH ROW
BEGIN
    IF NEW.record_type IN ('treatment', 'injury') THEN
        UPDATE animals
        SET health_status = 'sick'
        WHERE animal_id = NEW.animal_id;
    ELSEIF NEW.record_type = 'death' THEN
        UPDATE animals
        SET health_status = 'deceased'
        WHERE animal_id = NEW.animal_id;
    END IF;
END$$

-- Calculate growing degree days
CREATE TRIGGER trg_calculate_gdd
AFTER INSERT ON weather_data
FOR EACH ROW
BEGIN
    DECLARE v_base_temp DECIMAL(4,1);
    DECLARE v_gdd DECIMAL(8,2);
    DECLARE v_farm_id INT;

    SELECT farm_id INTO v_farm_id
    FROM weather_stations
    WHERE station_id = NEW.station_id;

    -- For each active planting in this farm
    INSERT INTO growth_stages (planting_id, stage_name, observation_date, gdd_accumulated)
    SELECT
        pr.planting_id,
        'GDD Update',
        DATE(NEW.observation_time),
        calculate_gdd(
            NEW.temperature_c - 5,  -- Assuming daily min is 5°C less
            NEW.temperature_c + 5,  -- Assuming daily max is 5°C more
            c.base_temperature_c
        )
    FROM planting_records pr
    INNER JOIN fields f ON pr.field_id = f.field_id
    INNER JOIN crops c ON pr.crop_id = c.crop_id
    WHERE f.farm_id = v_farm_id
      AND pr.status = 'growing'
      AND DATE(NEW.observation_time) > pr.planting_date
    ON DUPLICATE KEY UPDATE
        gdd_accumulated = gdd_accumulated + VALUES(gdd_accumulated);
END$$

-- Validate zone area doesn't exceed field area
CREATE TRIGGER trg_validate_zone_area
BEFORE INSERT ON zones
FOR EACH ROW
BEGIN
    DECLARE v_field_area DECIMAL(10,2);
    DECLARE v_total_zone_area DECIMAL(10,2);

    SELECT area_hectares INTO v_field_area
    FROM fields
    WHERE field_id = NEW.field_id;

    SELECT COALESCE(SUM(area_hectares), 0) INTO v_total_zone_area
    FROM zones
    WHERE field_id = NEW.field_id;

    IF (v_total_zone_area + NEW.area_hectares) > v_field_area THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Total zone area cannot exceed field area';
    END IF;
END$$

DELIMITER ;

-- ============================================================================
-- Unique Constraints
-- ============================================================================

-- Ensure unique sensor codes per zone
ALTER TABLE sensors
    ADD CONSTRAINT uk_zone_sensor_code
    UNIQUE KEY (zone_id, sensor_code);

-- Ensure one active irrigation schedule per system
ALTER TABLE irrigation_schedules
    ADD CONSTRAINT uk_system_active_schedule
    UNIQUE KEY (system_id, schedule_name, is_active);

-- Ensure unique weather station per location
ALTER TABLE weather_stations
    ADD CONSTRAINT uk_station_location
    UNIQUE KEY (latitude, longitude);

-- ============================================================================
-- Default Value Constraints
-- ============================================================================

-- Set default timestamps
ALTER TABLE sensor_readings
    MODIFY COLUMN timestamp DATETIME DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE weather_data
    MODIFY COLUMN observation_time DATETIME DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE irrigation_events
    MODIFY COLUMN start_time DATETIME DEFAULT CURRENT_TIMESTAMP;
