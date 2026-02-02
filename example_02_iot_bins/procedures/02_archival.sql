-- ============================================================================
-- IoT Garbage Bin Monitoring System - Data Archival Procedures
-- ============================================================================
-- Description: Stored procedures for data archival and maintenance
-- ============================================================================

USE iot_bins;

DELIMITER //

-- ============================================================================
-- Procedure: Archive Old Sensor Readings
-- ============================================================================
DROP PROCEDURE IF EXISTS sp_archive_sensor_readings//

CREATE PROCEDURE sp_archive_sensor_readings(
    IN p_days_to_keep INT,
    IN p_batch_size INT
)
BEGIN
    DECLARE v_rows_deleted INT DEFAULT 0;
    DECLARE v_total_deleted INT DEFAULT 0;
    DECLARE v_archive_date DATETIME;

    SET p_batch_size = IFNULL(p_batch_size, 10000);
    SET v_archive_date = DATE_SUB(NOW(), INTERVAL p_days_to_keep DAY);

    -- Create archive table if it doesn't exist
    CREATE TABLE IF NOT EXISTS sensor_readings_archive LIKE sensor_readings;

    -- Archive in batches to avoid locking
    REPEAT
        START TRANSACTION;

        -- Copy old records to archive
        INSERT INTO sensor_readings_archive
        SELECT * FROM sensor_readings
        WHERE reading_time < v_archive_date
        LIMIT p_batch_size;

        SET v_rows_deleted = ROW_COUNT();

        -- Delete archived records
        DELETE FROM sensor_readings
        WHERE reading_time < v_archive_date
        LIMIT p_batch_size;

        COMMIT;

        SET v_total_deleted = v_total_deleted + v_rows_deleted;

    UNTIL v_rows_deleted < p_batch_size
    END REPEAT;

    SELECT CONCAT('Archived ', v_total_deleted, ' sensor readings older than ', p_days_to_keep, ' days') AS result;
END//

-- ============================================================================
-- Procedure: Clean Up Old Alerts
-- ============================================================================
DROP PROCEDURE IF EXISTS sp_cleanup_old_alerts//

CREATE PROCEDURE sp_cleanup_old_alerts(
    IN p_days_to_keep INT
)
BEGIN
    DECLARE v_deleted_count INT;

    -- Archive resolved alerts older than specified days
    CREATE TABLE IF NOT EXISTS alerts_archive LIKE alerts;

    INSERT INTO alerts_archive
    SELECT * FROM alerts
    WHERE resolved_at IS NOT NULL
        AND resolved_at < DATE_SUB(NOW(), INTERVAL p_days_to_keep DAY);

    SET v_deleted_count = ROW_COUNT();

    DELETE FROM alerts
    WHERE resolved_at IS NOT NULL
        AND resolved_at < DATE_SUB(NOW(), INTERVAL p_days_to_keep DAY);

    SELECT CONCAT('Archived ', v_deleted_count, ' resolved alerts older than ', p_days_to_keep, ' days') AS result;
END//

-- ============================================================================
-- Procedure: Optimize Partitions
-- ============================================================================
DROP PROCEDURE IF EXISTS sp_optimize_partitions//

CREATE PROCEDURE sp_optimize_partitions(
    IN p_table_name VARCHAR(64),
    IN p_months_to_keep INT
)
BEGIN
    DECLARE v_partition_name VARCHAR(64);
    DECLARE v_partition_date DATE;
    DECLARE done INT DEFAULT FALSE;

    DECLARE partition_cursor CURSOR FOR
        SELECT
            partition_name,
            STR_TO_DATE(
                SUBSTRING_INDEX(
                    SUBSTRING_INDEX(partition_description, "'", 2), "'", -1
                ),
                '%Y-%m-%d %H:%i:%s'
            ) AS partition_date
        FROM information_schema.partitions
        WHERE table_schema = DATABASE()
            AND table_name = p_table_name
            AND partition_name IS NOT NULL
            AND partition_name NOT IN ('p_future', 'pe_future', 'pa_future')
        ORDER BY partition_ordinal_position;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN partition_cursor;

    read_loop: LOOP
        FETCH partition_cursor INTO v_partition_name, v_partition_date;

        IF done THEN
            LEAVE read_loop;
        END IF;

        -- Drop partitions older than specified months
        IF v_partition_date < DATE_SUB(CURDATE(), INTERVAL p_months_to_keep MONTH) THEN
            SET @sql = CONCAT('ALTER TABLE ', p_table_name, ' DROP PARTITION ', v_partition_name);
            PREPARE stmt FROM @sql;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;

            SELECT CONCAT('Dropped partition ', v_partition_name, ' from ', p_table_name) AS action;
        END IF;
    END LOOP;

    CLOSE partition_cursor;

    -- Optimize table after dropping partitions
    SET @sql = CONCAT('OPTIMIZE TABLE ', p_table_name);
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END//

-- ============================================================================
-- Procedure: Create Future Partitions
-- ============================================================================
DROP PROCEDURE IF EXISTS sp_create_future_partitions//

CREATE PROCEDURE sp_create_future_partitions(
    IN p_table_name VARCHAR(64),
    IN p_months_ahead INT
)
BEGIN
    DECLARE v_future_date DATE;
    DECLARE v_partition_name VARCHAR(20);
    DECLARE v_counter INT DEFAULT 1;

    WHILE v_counter <= p_months_ahead DO
        SET v_future_date = DATE_ADD(CURDATE(), INTERVAL v_counter MONTH);
        SET v_partition_name = CONCAT('p', DATE_FORMAT(v_future_date, '%Y_%m'));

        -- Check if partition already exists
        IF NOT EXISTS (
            SELECT 1
            FROM information_schema.partitions
            WHERE table_schema = DATABASE()
                AND table_name = p_table_name
                AND partition_name = v_partition_name
        ) THEN
            -- Reorganize p_future partition to add new month
            SET @sql = CONCAT(
                'ALTER TABLE ', p_table_name, ' ',
                'REORGANIZE PARTITION p_future INTO (',
                'PARTITION ', v_partition_name,
                ' VALUES LESS THAN (UNIX_TIMESTAMP(''',
                DATE_ADD(v_future_date, INTERVAL 1 MONTH), ' 00:00:00'')), ',
                'PARTITION p_future VALUES LESS THAN MAXVALUE)'
            );

            PREPARE stmt FROM @sql;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;

            SELECT CONCAT('Created partition ', v_partition_name, ' for ', p_table_name) AS action;
        END IF;

        SET v_counter = v_counter + 1;
    END WHILE;
END//

-- ============================================================================
-- Procedure: Database Maintenance Report
-- ============================================================================
DROP PROCEDURE IF EXISTS sp_database_maintenance_report//

CREATE PROCEDURE sp_database_maintenance_report()
BEGIN
    -- Table sizes and row counts
    SELECT 'Table Size Report' AS report_section;
    SELECT
        table_name,
        table_rows AS row_count,
        ROUND(data_length / 1024 / 1024, 2) AS data_mb,
        ROUND(index_length / 1024 / 1024, 2) AS index_mb,
        ROUND((data_length + index_length) / 1024 / 1024, 2) AS total_mb
    FROM information_schema.tables
    WHERE table_schema = DATABASE()
        AND table_type = 'BASE TABLE'
    ORDER BY (data_length + index_length) DESC;

    -- Partition information
    SELECT 'Partition Report' AS report_section;
    SELECT
        table_name,
        partition_name,
        partition_ordinal_position,
        table_rows,
        ROUND((data_length + index_length) / 1024 / 1024, 2) AS partition_size_mb
    FROM information_schema.partitions
    WHERE table_schema = DATABASE()
        AND partition_name IS NOT NULL
    ORDER BY table_name, partition_ordinal_position;

    -- Index usage statistics
    SELECT 'Unused Indexes' AS report_section;
    SELECT
        s.table_name,
        s.index_name,
        s.cardinality
    FROM information_schema.statistics s
    LEFT JOIN sys.schema_unused_indexes ui
        ON s.table_schema = ui.object_schema
        AND s.table_name = ui.object_name
        AND s.index_name = ui.index_name
    WHERE s.table_schema = DATABASE()
        AND s.index_name != 'PRIMARY'
        AND ui.index_name IS NOT NULL
    GROUP BY s.table_name, s.index_name;
END//

-- ============================================================================
-- Procedure: Rebuild Statistics
-- ============================================================================
DROP PROCEDURE IF EXISTS sp_rebuild_statistics//

CREATE PROCEDURE sp_rebuild_statistics()
BEGIN
    DECLARE v_table_name VARCHAR(64);
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_count INT DEFAULT 0;

    DECLARE table_cursor CURSOR FOR
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = DATABASE()
            AND table_type = 'BASE TABLE';

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN table_cursor;

    read_loop: LOOP
        FETCH table_cursor INTO v_table_name;

        IF done THEN
            LEAVE read_loop;
        END IF;

        SET @sql = CONCAT('ANALYZE TABLE ', v_table_name);
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        SET v_count = v_count + 1;
    END LOOP;

    CLOSE table_cursor;

    SELECT CONCAT('Analyzed ', v_count, ' tables') AS result;
END//

-- ============================================================================
-- Procedure: Purge Test Data
-- ============================================================================
DROP PROCEDURE IF EXISTS sp_purge_test_data//

CREATE PROCEDURE sp_purge_test_data(
    IN p_confirm VARCHAR(10)
)
BEGIN
    IF p_confirm != 'YES' THEN
        SELECT 'Please confirm by passing ''YES'' as parameter' AS error;
    ELSE
        SET foreign_key_checks = 0;

        TRUNCATE TABLE sensor_readings;
        TRUNCATE TABLE sensor_readings_hourly;
        TRUNCATE TABLE sensor_readings_daily;
        TRUNCATE TABLE alerts;
        TRUNCATE TABLE collection_events;
        TRUNCATE TABLE collection_schedules;
        TRUNCATE TABLE fill_rate_predictions;

        SET foreign_key_checks = 1;

        SELECT 'Test data purged successfully' AS result;
    END IF;
END//

-- ============================================================================
-- Procedure: Backup Critical Data
-- ============================================================================
DROP PROCEDURE IF EXISTS sp_backup_critical_data//

CREATE PROCEDURE sp_backup_critical_data(
    IN p_backup_date DATE
)
BEGIN
    DECLARE v_table_suffix VARCHAR(10);
    SET v_table_suffix = DATE_FORMAT(p_backup_date, '%Y%m%d');

    -- Create backup tables with date suffix
    SET @sql = CONCAT('CREATE TABLE IF NOT EXISTS bins_backup_', v_table_suffix, ' LIKE bins');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    SET @sql = CONCAT('INSERT INTO bins_backup_', v_table_suffix, ' SELECT * FROM bins');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    SET @sql = CONCAT('CREATE TABLE IF NOT EXISTS sensors_backup_', v_table_suffix, ' LIKE sensors');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    SET @sql = CONCAT('INSERT INTO sensors_backup_', v_table_suffix, ' SELECT * FROM sensors');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    SELECT CONCAT('Critical data backed up with suffix _', v_table_suffix) AS result;
END//

-- ============================================================================
-- Procedure: Health Check
-- ============================================================================
DROP PROCEDURE IF EXISTS sp_health_check//

CREATE PROCEDURE sp_health_check()
BEGIN
    -- Check for tables needing optimization
    SELECT 'Tables Needing Optimization' AS check_type;
    SELECT
        table_name,
        ROUND((data_length + index_length) / 1024 / 1024, 2) AS total_mb,
        ROUND(data_free / 1024 / 1024, 2) AS free_mb,
        ROUND(data_free * 100.0 / (data_length + index_length), 2) AS fragmentation_pct
    FROM information_schema.tables
    WHERE table_schema = DATABASE()
        AND data_free > 100 * 1024 * 1024  -- More than 100MB free
    ORDER BY data_free DESC;

    -- Check for missing recent data
    SELECT 'Data Freshness Check' AS check_type;
    SELECT
        'sensor_readings' AS table_name,
        MAX(reading_time) AS latest_record,
        TIMESTAMPDIFF(MINUTE, MAX(reading_time), NOW()) AS minutes_since_last
    FROM sensor_readings
    UNION ALL
    SELECT
        'collection_events',
        MAX(collected_at),
        TIMESTAMPDIFF(HOUR, MAX(collected_at), NOW())
    FROM collection_events
    UNION ALL
    SELECT
        'alerts',
        MAX(triggered_at),
        TIMESTAMPDIFF(MINUTE, MAX(triggered_at), NOW())
    FROM alerts;

    -- Check for long-running transactions
    SELECT 'Long Running Queries' AS check_type;
    SELECT
        id,
        user,
        host,
        db,
        command,
        time AS seconds,
        state,
        LEFT(info, 100) AS query_preview
    FROM information_schema.processlist
    WHERE command != 'Sleep'
        AND time > 30
    ORDER BY time DESC;
END//

DELIMITER ;

-- ============================================================================
-- Schedule Maintenance Events (Examples - Uncomment to use)
-- ============================================================================
/*
-- Daily archival of old sensor readings
CREATE EVENT IF NOT EXISTS event_archive_sensor_readings
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_DATE + INTERVAL 2 HOUR
DO
    CALL sp_archive_sensor_readings(90, 10000);

-- Weekly cleanup of old alerts
CREATE EVENT IF NOT EXISTS event_cleanup_alerts
ON SCHEDULE EVERY 1 WEEK
STARTS CURRENT_DATE + INTERVAL 6 DAY + INTERVAL 3 HOUR
DO
    CALL sp_cleanup_old_alerts(180);

-- Monthly partition maintenance
CREATE EVENT IF NOT EXISTS event_partition_maintenance
ON SCHEDULE EVERY 1 MONTH
STARTS CURRENT_DATE + INTERVAL 1 MONTH + INTERVAL 4 HOUR
DO
BEGIN
    CALL sp_optimize_partitions('sensor_readings', 6);
    CALL sp_create_future_partitions('sensor_readings', 3);
END;

-- Daily statistics rebuild
CREATE EVENT IF NOT EXISTS event_rebuild_stats
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_DATE + INTERVAL 5 HOUR
DO
    CALL sp_rebuild_statistics();
*/

SELECT 'Archival procedures created successfully' AS Status;