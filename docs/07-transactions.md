# Transactions

## Overview
Transactions are fundamental to maintaining data consistency in MySQL databases. This document covers transaction concepts, isolation levels, best practices, and common patterns used throughout the examples in this repository.

## ACID Properties

### Atomicity
All operations in a transaction succeed or fail as a unit:
```sql
START TRANSACTION;

INSERT INTO orders (customer_id, order_date) VALUES (123, NOW());
SET @order_id = LAST_INSERT_ID();

INSERT INTO order_items (order_id, product_id, quantity) VALUES
    (@order_id, 1, 2),
    (@order_id, 2, 1);

UPDATE inventory SET quantity = quantity - 2 WHERE product_id = 1;
UPDATE inventory SET quantity = quantity - 1 WHERE product_id = 2;

COMMIT;  -- All succeed
-- ROLLBACK;  -- All fail
```

### Consistency
Database remains in a valid state before and after transaction:
```sql
-- Check constraint ensures consistency
ALTER TABLE accounts
ADD CONSTRAINT chk_positive_balance CHECK (balance >= 0);

-- Transaction will fail if it violates consistency
START TRANSACTION;
UPDATE accounts SET balance = balance - 1000 WHERE account_id = 1;
-- Fails and rolls back if balance would go negative
COMMIT;
```

### Isolation
Transactions execute independently without interference:
```sql
-- Session 1
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
START TRANSACTION;
SELECT balance FROM accounts WHERE account_id = 1;
-- Sees committed data only

-- Session 2 (concurrent)
START TRANSACTION;
UPDATE accounts SET balance = balance + 100 WHERE account_id = 1;
COMMIT;

-- Session 1 continues
SELECT balance FROM accounts WHERE account_id = 1;
-- Now sees the updated balance
COMMIT;
```

### Durability
Committed transactions persist even after system failure:
```sql
-- Enable binary logging for durability
SET GLOBAL sync_binlog = 1;
SET GLOBAL innodb_flush_log_at_trx_commit = 1;

START TRANSACTION;
INSERT INTO critical_data (value) VALUES ('important');
COMMIT;  -- Guaranteed to persist
```

## Isolation Levels

### READ UNCOMMITTED (Lowest Isolation)
```sql
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
-- Can read uncommitted changes (dirty reads)
-- Fastest but least safe
-- Use case: Real-time monitoring where accuracy isn't critical
```

### READ COMMITTED (Default in PostgreSQL)
```sql
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- Prevents dirty reads
-- Allows non-repeatable reads
-- Use case: Most OLTP applications
```

### REPEATABLE READ (Default in MySQL)
```sql
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- Prevents dirty and non-repeatable reads
-- Allows phantom reads in some cases
-- Use case: Reports that need consistent view
```

### SERIALIZABLE (Highest Isolation)
```sql
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
-- Complete isolation, transactions execute serially
-- Prevents all phenomena but slowest
-- Use case: Critical financial transactions
```

## Transaction Patterns by Domain

### E-commerce Order Processing
```sql
DELIMITER $$
CREATE PROCEDURE process_order(
    IN p_customer_id INT,
    IN p_items JSON
)
BEGIN
    DECLARE v_order_id INT;
    DECLARE v_total DECIMAL(10,2) DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Order processing failed';
    END;

    START TRANSACTION;

    -- Create order
    INSERT INTO orders (customer_id, status, created_at)
    VALUES (p_customer_id, 'pending', NOW());

    SET v_order_id = LAST_INSERT_ID();

    -- Add items and check inventory
    INSERT INTO order_items (order_id, product_id, quantity, unit_price)
    SELECT
        v_order_id,
        JSON_UNQUOTE(JSON_EXTRACT(item.value, '$.product_id')),
        JSON_UNQUOTE(JSON_EXTRACT(item.value, '$.quantity')),
        p.price
    FROM JSON_TABLE(p_items, '$[*]' COLUMNS (value JSON PATH '$')) item
    JOIN products p ON p.product_id = JSON_UNQUOTE(JSON_EXTRACT(item.value, '$.product_id'));

    -- Update inventory
    UPDATE inventory i
    JOIN order_items oi ON i.product_id = oi.product_id
    SET i.quantity = i.quantity - oi.quantity
    WHERE oi.order_id = v_order_id
        AND i.quantity >= oi.quantity;

    -- Check if all items were in stock
    IF ROW_COUNT() < (SELECT COUNT(*) FROM order_items WHERE order_id = v_order_id) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Insufficient inventory';
    END IF;

    -- Calculate total
    SELECT SUM(quantity * unit_price) INTO v_total
    FROM order_items
    WHERE order_id = v_order_id;

    -- Update order total
    UPDATE orders SET total_amount = v_total WHERE order_id = v_order_id;

    COMMIT;

    SELECT v_order_id as order_id, v_total as total;
END$$
DELIMITER ;
```

### Banking Transfer Transaction
```sql
DELIMITER $$
CREATE PROCEDURE transfer_funds(
    IN p_from_account INT,
    IN p_to_account INT,
    IN p_amount DECIMAL(10,2)
)
BEGIN
    DECLARE v_from_balance DECIMAL(10,2);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Transfer failed';
    END;

    START TRANSACTION;

    -- Lock accounts in order to prevent deadlock
    IF p_from_account < p_to_account THEN
        SELECT balance INTO v_from_balance
        FROM accounts WHERE account_id = p_from_account FOR UPDATE;

        SELECT balance FROM accounts
        WHERE account_id = p_to_account FOR UPDATE;
    ELSE
        SELECT balance FROM accounts
        WHERE account_id = p_to_account FOR UPDATE;

        SELECT balance INTO v_from_balance
        FROM accounts WHERE account_id = p_from_account FOR UPDATE;
    END IF;

    -- Check sufficient funds
    IF v_from_balance < p_amount THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Insufficient funds';
    END IF;

    -- Perform transfer
    UPDATE accounts
    SET balance = balance - p_amount
    WHERE account_id = p_from_account;

    UPDATE accounts
    SET balance = balance + p_amount
    WHERE account_id = p_to_account;

    -- Log transaction
    INSERT INTO transaction_log (from_account, to_account, amount, timestamp)
    VALUES (p_from_account, p_to_account, p_amount, NOW());

    COMMIT;
END$$
DELIMITER ;
```

### IoT Sensor Data Processing
```sql
DELIMITER $$
CREATE PROCEDURE process_sensor_batch(
    IN p_sensor_id INT,
    IN p_readings JSON
)
BEGIN
    DECLARE v_alert_threshold DECIMAL(10,2);
    DECLARE v_last_reading DECIMAL(10,2);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        INSERT INTO error_log (sensor_id, error_message, timestamp)
        VALUES (p_sensor_id, 'Batch processing failed', NOW());
    END;

    START TRANSACTION;

    -- Get sensor configuration
    SELECT alert_threshold INTO v_alert_threshold
    FROM sensors
    WHERE sensor_id = p_sensor_id
    FOR SHARE;  -- Read lock, allows other reads

    -- Insert readings
    INSERT INTO sensor_readings (sensor_id, timestamp, value)
    SELECT
        p_sensor_id,
        STR_TO_DATE(JSON_UNQUOTE(JSON_EXTRACT(reading.value, '$.timestamp')), '%Y-%m-%d %H:%i:%s'),
        JSON_UNQUOTE(JSON_EXTRACT(reading.value, '$.value'))
    FROM JSON_TABLE(p_readings, '$[*]' COLUMNS (value JSON PATH '$')) reading;

    -- Check for alerts
    SELECT value INTO v_last_reading
    FROM sensor_readings
    WHERE sensor_id = p_sensor_id
    ORDER BY timestamp DESC
    LIMIT 1;

    IF v_last_reading > v_alert_threshold THEN
        INSERT INTO alerts (sensor_id, alert_type, value, timestamp)
        VALUES (p_sensor_id, 'threshold_exceeded', v_last_reading, NOW());
    END IF;

    -- Update sensor statistics
    UPDATE sensor_stats
    SET last_reading = v_last_reading,
        last_update = NOW(),
        total_readings = total_readings + JSON_LENGTH(p_readings)
    WHERE sensor_id = p_sensor_id;

    COMMIT;
END$$
DELIMITER ;
```

## Deadlock Prevention and Handling

### Deadlock Prevention Strategies

1. **Consistent Lock Ordering**:
```sql
-- Always lock in same order (e.g., by ID)
IF account1_id < account2_id THEN
    SELECT * FROM accounts WHERE id = account1_id FOR UPDATE;
    SELECT * FROM accounts WHERE id = account2_id FOR UPDATE;
ELSE
    SELECT * FROM accounts WHERE id = account2_id FOR UPDATE;
    SELECT * FROM accounts WHERE id = account1_id FOR UPDATE;
END IF;
```

2. **Lock Timeout**:
```sql
SET innodb_lock_wait_timeout = 5;  -- 5 seconds
```

3. **Retry Logic**:
```sql
DELIMITER $$
CREATE PROCEDURE safe_update_with_retry(IN p_id INT, IN p_value VARCHAR(255))
BEGIN
    DECLARE v_retry INT DEFAULT 3;
    DECLARE v_done INT DEFAULT FALSE;

    WHILE v_retry > 0 AND NOT v_done DO
        BEGIN
            DECLARE EXIT HANDLER FOR SQLEXCEPTION
            BEGIN
                SET v_retry = v_retry - 1;
                IF v_retry = 0 THEN
                    SIGNAL SQLSTATE '45000'
                        SET MESSAGE_TEXT = 'Update failed after retries';
                END IF;
            END;

            START TRANSACTION;
            UPDATE critical_table SET value = p_value WHERE id = p_id;
            COMMIT;
            SET v_done = TRUE;
        END;
    END WHILE;
END$$
DELIMITER ;
```

## Optimistic vs Pessimistic Locking

### Pessimistic Locking (FOR UPDATE)
```sql
-- Lock row immediately
START TRANSACTION;
SELECT * FROM inventory WHERE product_id = 1 FOR UPDATE;
-- Row is locked until commit
UPDATE inventory SET quantity = quantity - 1 WHERE product_id = 1;
COMMIT;
```

### Optimistic Locking (Version Column)
```sql
-- Add version column
ALTER TABLE products ADD COLUMN version INT DEFAULT 0;

-- Update with version check
UPDATE products
SET name = 'New Name',
    version = version + 1
WHERE product_id = 1
    AND version = 5;  -- Expected version

-- Check if update succeeded
IF ROW_COUNT() = 0 THEN
    -- Version mismatch, handle conflict
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Update conflict detected';
END IF;
```

## Transaction Best Practices

### 1. Keep Transactions Short
```sql
-- Bad: Long transaction
START TRANSACTION;
SELECT * FROM large_table;  -- Long running
-- Process data in application (slow)
UPDATE another_table SET ...;
COMMIT;

-- Good: Minimize transaction scope
SELECT * FROM large_table;  -- Outside transaction
-- Process data
START TRANSACTION;
UPDATE another_table SET ...;
COMMIT;
```

### 2. Handle Errors Properly
```sql
DELIMITER $$
CREATE PROCEDURE safe_operation()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @p1 = RETURNED_SQLSTATE,
            @p2 = MESSAGE_TEXT;
        ROLLBACK;
        INSERT INTO error_log (error_code, error_message, timestamp)
        VALUES (@p1, @p2, NOW());
    END;

    START TRANSACTION;
    -- Operations here
    COMMIT;
END$$
DELIMITER ;
```

### 3. Use Appropriate Isolation Level
```sql
-- For reports (read-only)
SET TRANSACTION ISOLATION LEVEL READ COMMITTED, READ ONLY;

-- For critical updates
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- For bulk operations
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
```

## Monitoring Transactions

### Active Transactions
```sql
-- View current transactions
SELECT
    trx_id,
    trx_state,
    trx_started,
    trx_mysql_thread_id,
    trx_query
FROM information_schema.innodb_trx;

-- Long-running transactions
SELECT
    trx_id,
    trx_started,
    TIMESTAMPDIFF(SECOND, trx_started, NOW()) as duration_seconds,
    trx_state
FROM information_schema.innodb_trx
WHERE TIMESTAMPDIFF(SECOND, trx_started, NOW()) > 10;
```

### Lock Monitoring
```sql
-- View locks
SELECT
    engine_transaction_id,
    object_schema,
    object_name,
    lock_type,
    lock_mode,
    lock_status
FROM performance_schema.data_locks;

-- Blocking transactions
SELECT
    blocking.trx_id as blocking_id,
    blocking.trx_mysql_thread_id as blocking_thread,
    waiting.trx_id as waiting_id,
    waiting.trx_mysql_thread_id as waiting_thread,
    waiting.trx_query as waiting_query
FROM information_schema.innodb_lock_waits lw
JOIN information_schema.innodb_trx blocking ON lw.blocking_trx_id = blocking.trx_id
JOIN information_schema.innodb_trx waiting ON lw.requesting_trx_id = waiting.trx_id;
```

### Deadlock Information
```sql
-- View last deadlock
SHOW ENGINE INNODB STATUS\G

-- Enable deadlock logging
SET GLOBAL innodb_print_all_deadlocks = ON;
```

## Performance Considerations

### Transaction Size Impact
- **Small Transactions**: Less lock contention, faster commits
- **Large Transactions**: Better throughput for bulk operations
- **Batch Processing**: Balance between transaction size and lock duration

### Commit Frequency
```sql
-- For bulk inserts
SET autocommit = 0;
INSERT INTO table VALUES (...);
-- Every 1000 rows
IF row_count % 1000 = 0 THEN
    COMMIT;
    START TRANSACTION;
END IF;
```

### Index Impact on Locking
```sql
-- Without index: Locks entire table
UPDATE orders SET status = 'shipped' WHERE customer_id = 123;

-- With index on customer_id: Locks only matching rows
CREATE INDEX idx_customer ON orders(customer_id);
UPDATE orders SET status = 'shipped' WHERE customer_id = 123;
```

## Common Transaction Antipatterns

### 1. Autocommit Overhead
```sql
-- Bad: Each statement is a transaction
SET autocommit = 1;
FOR each row:
    INSERT INTO table VALUES (...);  -- Commit each time

-- Good: Single transaction
SET autocommit = 0;
START TRANSACTION;
FOR each row:
    INSERT INTO table VALUES (...);
COMMIT;
```

### 2. Unnecessary Locking
```sql
-- Bad: Lock for reading
SELECT * FROM products FOR UPDATE;  -- Just reading

-- Good: Use appropriate lock
SELECT * FROM products;  -- No lock needed
-- Or
SELECT * FROM products FOR SHARE;  -- Read lock only
```

### 3. Transaction in Loop
```sql
-- Bad: Transaction per iteration
FOR each item:
    START TRANSACTION;
    Process item;
    COMMIT;

-- Good: Batch processing
START TRANSACTION;
FOR each batch of items:
    Process batch;
    IF batch complete:
        COMMIT;
        START TRANSACTION;
COMMIT;
```

## Next Steps

1. Review transaction usage in example schemas
2. Test different isolation levels for your use case
3. Implement proper error handling
4. Monitor transaction performance metrics
5. Set up deadlock detection and alerting