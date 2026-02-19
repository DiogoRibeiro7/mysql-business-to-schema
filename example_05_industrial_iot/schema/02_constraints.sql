-- ============================================================================
-- Industrial IoT Manufacturing Constraints
-- ============================================================================

USE industrial_iot;

-- ============================================================================
-- Foreign Key Constraints
-- ============================================================================

-- Production lines -> Factories
ALTER TABLE production_lines
    ADD CONSTRAINT fk_line_factory
    FOREIGN KEY (factory_id) REFERENCES factories(factory_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- Machines -> Production lines
ALTER TABLE machines
    ADD CONSTRAINT fk_machine_line
    FOREIGN KEY (line_id) REFERENCES production_lines(line_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- Sensors -> Machines
ALTER TABLE sensors
    ADD CONSTRAINT fk_sensor_machine
    FOREIGN KEY (machine_id) REFERENCES machines(machine_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- Sensor readings -> Sensors
-- Note: Partitioned tables have limitations with foreign keys in MySQL
-- We'll use triggers for referential integrity instead

-- Work orders -> Products and Lines
ALTER TABLE work_orders
    ADD CONSTRAINT fk_order_product
    FOREIGN KEY (product_id) REFERENCES products(product_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
    ADD CONSTRAINT fk_order_line
    FOREIGN KEY (line_id) REFERENCES production_lines(line_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- Production runs -> Work orders and Machines
ALTER TABLE production_runs
    ADD CONSTRAINT fk_run_order
    FOREIGN KEY (order_id) REFERENCES work_orders(order_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
    ADD CONSTRAINT fk_run_machine
    FOREIGN KEY (machine_id) REFERENCES machines(machine_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
    ADD CONSTRAINT fk_run_operator
    FOREIGN KEY (operator_id) REFERENCES operators(operator_id)
    ON DELETE SET NULL ON UPDATE CASCADE;

-- Quality inspections -> Production runs and Products
ALTER TABLE quality_inspections
    ADD CONSTRAINT fk_inspection_run
    FOREIGN KEY (run_id) REFERENCES production_runs(run_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
    ADD CONSTRAINT fk_inspection_product
    FOREIGN KEY (product_id) REFERENCES products(product_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
    ADD CONSTRAINT fk_inspection_inspector
    FOREIGN KEY (inspector_id) REFERENCES operators(operator_id)
    ON DELETE SET NULL ON UPDATE CASCADE;

-- Defects -> Quality inspections
ALTER TABLE defects
    ADD CONSTRAINT fk_defect_inspection
    FOREIGN KEY (inspection_id) REFERENCES quality_inspections(inspection_id)
    ON DELETE CASCADE ON UPDATE CASCADE;

-- OEE metrics -> Machines and Lines
ALTER TABLE oee_metrics
    ADD CONSTRAINT fk_oee_machine
    FOREIGN KEY (machine_id) REFERENCES machines(machine_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
    ADD CONSTRAINT fk_oee_line
    FOREIGN KEY (line_id) REFERENCES production_lines(line_id)
    ON DELETE CASCADE ON UPDATE CASCADE;

-- Maintenance schedules -> Machines
ALTER TABLE maintenance_schedules
    ADD CONSTRAINT fk_schedule_machine
    FOREIGN KEY (machine_id) REFERENCES machines(machine_id)
    ON DELETE CASCADE ON UPDATE CASCADE;

-- Maintenance records -> Machines and Schedules
ALTER TABLE maintenance_records
    ADD CONSTRAINT fk_maintenance_machine
    FOREIGN KEY (machine_id) REFERENCES machines(machine_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
    ADD CONSTRAINT fk_maintenance_schedule
    FOREIGN KEY (schedule_id) REFERENCES maintenance_schedules(schedule_id)
    ON DELETE SET NULL ON UPDATE CASCADE,
    ADD CONSTRAINT fk_maintenance_technician
    FOREIGN KEY (technician_id) REFERENCES operators(operator_id)
    ON DELETE SET NULL ON UPDATE CASCADE;

-- Downtime events -> Machines and Lines
ALTER TABLE downtime_events
    ADD CONSTRAINT fk_downtime_machine
    FOREIGN KEY (machine_id) REFERENCES machines(machine_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
    ADD CONSTRAINT fk_downtime_line
    FOREIGN KEY (line_id) REFERENCES production_lines(line_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- Operators -> Factories
ALTER TABLE operators
    ADD CONSTRAINT fk_operator_factory
    FOREIGN KEY (factory_id) REFERENCES factories(factory_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- Shift logs -> Lines and Supervisors
ALTER TABLE shift_logs
    ADD CONSTRAINT fk_shift_line
    FOREIGN KEY (line_id) REFERENCES production_lines(line_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
    ADD CONSTRAINT fk_shift_supervisor
    FOREIGN KEY (supervisor_id) REFERENCES operators(operator_id)
    ON DELETE SET NULL ON UPDATE CASCADE;

-- ============================================================================
-- Check Constraints
-- ============================================================================

-- Ensure positive values for quantities
ALTER TABLE work_orders
    ADD CONSTRAINT chk_order_quantities
    CHECK (planned_quantity > 0 AND produced_quantity >= 0
           AND good_quantity >= 0 AND rejected_quantity >= 0);

-- Ensure valid time ranges
ALTER TABLE work_orders
    ADD CONSTRAINT chk_order_times
    CHECK (planned_end_time > planned_start_time);

ALTER TABLE production_runs
    ADD CONSTRAINT chk_run_times
    CHECK (end_time IS NULL OR end_time > start_time);

ALTER TABLE maintenance_records
    ADD CONSTRAINT chk_maintenance_times
    CHECK (end_time IS NULL OR end_time > start_time);

ALTER TABLE downtime_events
    ADD CONSTRAINT chk_downtime_times
    CHECK (end_time IS NULL OR end_time > start_time);

-- Ensure sensor thresholds are logical
ALTER TABLE sensors
    ADD CONSTRAINT chk_sensor_ranges
    CHECK (min_value <= max_value
           AND critical_min <= normal_min
           AND normal_max <= critical_max
           AND normal_min <= normal_max);

-- Ensure OEE percentages are valid
ALTER TABLE oee_metrics
    ADD CONSTRAINT chk_oee_percentages
    CHECK (availability_percentage BETWEEN 0 AND 100
           AND performance_percentage BETWEEN 0 AND 100
           AND quality_percentage BETWEEN 0 AND 100
           AND oee_percentage BETWEEN 0 AND 100);

-- Ensure quality quantities are consistent
ALTER TABLE production_runs
    ADD CONSTRAINT chk_run_quantities
    CHECK (quantity_produced = quantity_good + quantity_rejected);

-- Ensure shift counts are positive
ALTER TABLE factories
    ADD CONSTRAINT chk_factory_shifts
    CHECK (shifts_per_day BETWEEN 1 AND 4);

-- Ensure priority is in valid range
ALTER TABLE work_orders
    ADD CONSTRAINT chk_order_priority
    CHECK (priority BETWEEN 1 AND 10);

-- ============================================================================
-- Triggers for Business Logic
-- ============================================================================

DELIMITER $$

-- Update machine status based on production runs
CREATE TRIGGER trg_update_machine_status_on_run
AFTER INSERT ON production_runs
FOR EACH ROW
BEGIN
    IF NEW.end_time IS NULL THEN
        UPDATE machines
        SET status = 'running'
        WHERE machine_id = NEW.machine_id;
    END IF;
END$$

-- Complete production run updates machine status
CREATE TRIGGER trg_complete_production_run
AFTER UPDATE ON production_runs
FOR EACH ROW
BEGIN
    IF OLD.end_time IS NULL AND NEW.end_time IS NOT NULL THEN
        UPDATE machines
        SET status = 'idle',
            total_operating_hours = total_operating_hours +
                TIMESTAMPDIFF(SECOND, NEW.start_time, NEW.end_time) / 3600,
            total_cycle_count = total_cycle_count + NEW.quantity_produced
        WHERE machine_id = NEW.machine_id;
    END IF;
END$$

-- Calculate OEE percentage when components are updated
CREATE TRIGGER trg_calculate_oee
BEFORE INSERT ON oee_metrics
FOR EACH ROW
BEGIN
    SET NEW.oee_percentage = (NEW.availability_percentage / 100) *
                             (NEW.performance_percentage / 100) *
                             (NEW.quality_percentage / 100) * 100;
END$$

CREATE TRIGGER trg_update_oee
BEFORE UPDATE ON oee_metrics
FOR EACH ROW
BEGIN
    SET NEW.oee_percentage = (NEW.availability_percentage / 100) *
                             (NEW.performance_percentage / 100) *
                             (NEW.quality_percentage / 100) * 100;
END$$

-- Update work order status and quantities
CREATE TRIGGER trg_update_work_order_from_run
AFTER UPDATE ON production_runs
FOR EACH ROW
BEGIN
    IF NEW.end_time IS NOT NULL THEN
        UPDATE work_orders
        SET produced_quantity = produced_quantity + NEW.quantity_produced,
            good_quantity = good_quantity + NEW.quantity_good,
            rejected_quantity = rejected_quantity + NEW.quantity_rejected
        WHERE order_id = NEW.order_id;
    END IF;
END$$

-- Auto-complete work order when quantity is reached
CREATE TRIGGER trg_complete_work_order
AFTER UPDATE ON work_orders
FOR EACH ROW
BEGIN
    IF NEW.produced_quantity >= NEW.planned_quantity
       AND OLD.status IN ('planned', 'in_progress') THEN
        UPDATE work_orders
        SET status = 'completed',
            actual_end_time = NOW()
        WHERE order_id = NEW.order_id;
    END IF;
END$$

-- Create alert for critical sensor readings
CREATE TRIGGER trg_sensor_alert
AFTER INSERT ON sensor_readings
FOR EACH ROW
BEGIN
    DECLARE v_sensor_type VARCHAR(50);
    DECLARE v_critical_min DECIMAL(12,4);
    DECLARE v_critical_max DECIMAL(12,4);
    DECLARE v_machine_id INT;

    SELECT s.sensor_type, s.critical_min, s.critical_max, s.machine_id
    INTO v_sensor_type, v_critical_min, v_critical_max, v_machine_id
    FROM sensors s
    WHERE s.sensor_id = NEW.sensor_id;

    IF NEW.value < v_critical_min OR NEW.value > v_critical_max THEN
        INSERT INTO alerts (source_type, source_id, alert_type, severity,
                          message, threshold_value, actual_value, triggered_at)
        VALUES ('sensor', NEW.sensor_id,
                CONCAT(v_sensor_type, '_critical'),
                'high',
                CONCAT('Sensor ', NEW.sensor_id, ' reading critical: ', NEW.value),
                CASE WHEN NEW.value < v_critical_min THEN v_critical_min ELSE v_critical_max END,
                NEW.value,
                NEW.timestamp);
    END IF;
END$$

-- Calculate downtime duration
CREATE TRIGGER trg_calculate_downtime
BEFORE UPDATE ON downtime_events
FOR EACH ROW
BEGIN
    IF NEW.end_time IS NOT NULL AND OLD.end_time IS NULL THEN
        SET NEW.duration_minutes = TIMESTAMPDIFF(MINUTE, NEW.start_time, NEW.end_time);
    END IF;
END$$

-- Update maintenance schedule next due date
CREATE TRIGGER trg_update_maintenance_schedule
AFTER UPDATE ON maintenance_records
FOR EACH ROW
BEGIN
    IF NEW.status = 'completed' AND NEW.schedule_id IS NOT NULL THEN
        UPDATE maintenance_schedules
        SET last_performed = DATE(NEW.end_time),
            next_due = DATE_ADD(DATE(NEW.end_time), INTERVAL frequency_days DAY)
        WHERE schedule_id = NEW.schedule_id;
    END IF;
END$$

DELIMITER ;

-- ============================================================================
-- Unique Constraints
-- ============================================================================

-- Ensure unique sensor codes per machine
ALTER TABLE sensors
    ADD CONSTRAINT uk_machine_sensor_code
    UNIQUE KEY (machine_id, sensor_code);

-- Ensure one active maintenance schedule per type per machine
ALTER TABLE maintenance_schedules
    ADD CONSTRAINT uk_machine_maintenance_type
    UNIQUE KEY (machine_id, maintenance_type, is_active);

-- ============================================================================
-- Default Value Constraints
-- ============================================================================

-- Set default timestamps for completion times
ALTER TABLE production_runs
    ALTER COLUMN end_time SET DEFAULT NULL;

ALTER TABLE maintenance_records
    ALTER COLUMN end_time SET DEFAULT NULL;

ALTER TABLE downtime_events
    ALTER COLUMN end_time SET DEFAULT NULL;
