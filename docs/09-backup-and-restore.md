# Backup and Restore

## Overview
This document provides detailed procedures for backing up and restoring MySQL databases, with specific focus on restore operations, disaster recovery scenarios, and migration strategies for the database examples in this repository.

## Complete Backup and Restore Workflow

### Full Database Backup and Restore

#### 1. Create Full Backup
```bash
#!/bin/bash
# Full backup with all metadata

DB_NAME="production_db"
BACKUP_DIR="/backup/mysql/$(date +%Y%m%d_%H%M%S)"
mkdir -p ${BACKUP_DIR}

# Backup database structure and data
mysqldump -u root -p \
  --single-transaction \
  --routines \
  --triggers \
  --events \
  --set-gtid-purged=OFF \
  --databases ${DB_NAME} > ${BACKUP_DIR}/${DB_NAME}_full.sql

# Backup users and privileges
mysql -u root -p -e "SELECT CONCAT('SHOW CREATE USER ''', user, '''@''', host, ''';') FROM mysql.user" | \
  mysql -u root -p -s | \
  mysql -u root -p -s > ${BACKUP_DIR}/users.sql

mysql -u root -p -e "SELECT CONCAT('SHOW GRANTS FOR ''', user, '''@''', host, ''';') FROM mysql.user" | \
  mysql -u root -p -s | \
  mysql -u root -p -s > ${BACKUP_DIR}/grants.sql

# Create restore script
cat > ${BACKUP_DIR}/restore.sh << 'EOF'
#!/bin/bash
echo "Restoring database..."
mysql -u root -p < ${DB_NAME}_full.sql
echo "Restoring users and privileges..."
mysql -u root -p < users.sql
mysql -u root -p < grants.sql
echo "Restore complete!"
EOF
chmod +x ${BACKUP_DIR}/restore.sh

echo "Backup complete: ${BACKUP_DIR}"
```

#### 2. Perform Complete Restore
```bash
# Navigate to backup directory
cd /backup/mysql/20240101_120000

# Stop applications
systemctl stop application-service

# Optional: Drop existing database
mysql -u root -p -e "DROP DATABASE IF EXISTS production_db"

# Restore database
mysql -u root -p < production_db_full.sql

# Restore users and privileges
mysql -u root -p < users.sql
mysql -u root -p < grants.sql
mysql -u root -p -e "FLUSH PRIVILEGES"

# Verify restore
mysql -u root -p -e "USE production_db; SHOW TABLES"

# Start applications
systemctl start application-service
```

## Restore Scenarios

### Scenario 1: Complete System Failure
Complete server failure requiring full rebuild.

```bash
#!/bin/bash
# Complete disaster recovery

# 1. Install MySQL on new server
apt-get update
apt-get install -y mysql-server-8.0

# 2. Configure MySQL
cat > /etc/mysql/conf.d/restore.cnf << EOF
[mysqld]
innodb_flush_log_at_trx_commit = 0
innodb_flush_method = O_DIRECT
innodb_buffer_pool_size = 4G
EOF

# 3. Start MySQL
systemctl start mysql

# 4. Restore from backup
LATEST_BACKUP=$(find /backup -name "*.sql.gz" -type f | sort -r | head -1)
gunzip < ${LATEST_BACKUP} | mysql -u root -p

# 5. Verify data integrity
mysql -u root -p -e "
  SELECT
    table_schema,
    COUNT(*) as table_count
  FROM information_schema.tables
  WHERE table_schema NOT IN ('information_schema', 'performance_schema', 'sys', 'mysql')
  GROUP BY table_schema
"

# 6. Update application configuration
sed -i 's/old-server/new-server/g' /app/config/database.yml

# 7. Test application connectivity
mysql -h localhost -u app_user -p -e "SELECT 1"
```

### Scenario 2: Corrupted Tables
Specific tables corrupted, need selective restore.

```bash
#!/bin/bash
# Selective table restore

DB_NAME="production_db"
TABLES="orders order_items customers"

# Extract specific tables from backup
for table in ${TABLES}; do
  echo "Extracting ${table}..."
  sed -n "/^-- Table structure for table \`${table}\`/,/^-- Table structure for table/p" backup.sql > ${table}.sql
done

# Restore tables
for table in ${TABLES}; do
  echo "Restoring ${table}..."
  mysql -u root -p ${DB_NAME} < ${table}.sql
done

# Verify restoration
for table in ${TABLES}; do
  COUNT=$(mysql -u root -p ${DB_NAME} -e "SELECT COUNT(*) FROM ${table}" -s)
  echo "${table}: ${COUNT} rows"
done
```

### Scenario 3: Point-in-Time Recovery
Recover to specific moment before data loss.

```bash
#!/bin/bash
# Point-in-time recovery using binary logs

# 1. Restore last full backup
mysql -u root -p < /backup/full_backup_20240101.sql

# 2. Identify target recovery time
TARGET_TIME="2024-01-02 14:30:00"

# 3. Apply binary logs up to target time
mysqlbinlog --stop-datetime="${TARGET_TIME}" \
  /var/log/mysql/mysql-bin.000001 \
  /var/log/mysql/mysql-bin.000002 \
  /var/log/mysql/mysql-bin.000003 | mysql -u root -p

# 4. Verify recovery point
mysql -u root -p -e "
  SELECT MAX(created_at) as last_transaction
  FROM production_db.audit_log
"
```

### Scenario 4: Accidental Data Deletion
User accidentally deleted important data.

```bash
#!/bin/bash
# Recover deleted data

# 1. Create temporary database
mysql -u root -p -e "CREATE DATABASE temp_recovery"

# 2. Restore backup to temporary database
sed 's/production_db/temp_recovery/g' backup.sql | mysql -u root -p

# 3. Copy deleted data back
mysql -u root -p << EOF
INSERT INTO production_db.deleted_table
SELECT * FROM temp_recovery.deleted_table
WHERE created_at BETWEEN '2024-01-01' AND '2024-01-02';
EOF

# 4. Verify recovery
mysql -u root -p -e "
  SELECT COUNT(*) as recovered_rows
  FROM production_db.deleted_table
  WHERE created_at BETWEEN '2024-01-01' AND '2024-01-02'
"

# 5. Cleanup
mysql -u root -p -e "DROP DATABASE temp_recovery"
```

## Migration and Cloning

### Production to Development Clone
```bash
#!/bin/bash
# Clone production to development environment

PROD_HOST="prod-server"
DEV_HOST="localhost"
DB_NAME="application_db"

# 1. Dump production database (sanitized)
ssh ${PROD_HOST} "mysqldump -u root -p \
  --single-transaction \
  --routines \
  --triggers \
  --events \
  --ignore-table=${DB_NAME}.sensitive_data \
  --ignore-table=${DB_NAME}.payment_info \
  ${DB_NAME}" > prod_dump.sql

# 2. Sanitize data
cat prod_dump.sql | sed \
  -e "s/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/test@example.com/g" \
  -e "s/[0-9]{3}-[0-9]{3}-[0-9]{4}/555-555-5555/g" \
  > sanitized_dump.sql

# 3. Drop and recreate dev database
mysql -u root -p -e "DROP DATABASE IF EXISTS ${DB_NAME}_dev"
mysql -u root -p -e "CREATE DATABASE ${DB_NAME}_dev"

# 4. Import to development
mysql -u root -p ${DB_NAME}_dev < sanitized_dump.sql

# 5. Update dev-specific settings
mysql -u root -p ${DB_NAME}_dev << EOF
UPDATE settings SET value = 'development' WHERE key = 'environment';
UPDATE users SET password = MD5('devpassword');
EOF
```

### Cross-Version Migration
```bash
#!/bin/bash
# Migrate from MySQL 5.7 to 8.0

# 1. Check compatibility on source
mysql -u root -p -e "SELECT @@version"
mysqlcheck -u root -p --all-databases --check-upgrade

# 2. Backup with compatibility flags
mysqldump -u root -p \
  --all-databases \
  --routines \
  --events \
  --single-transaction \
  --set-gtid-purged=OFF \
  --column-statistics=0 > mysql57_backup.sql

# 3. Prepare for MySQL 8.0
sed -i 's/utf8mb4_0900_ai_ci/utf8mb4_general_ci/g' mysql57_backup.sql

# 4. Import to MySQL 8.0
mysql -u root -p < mysql57_backup.sql

# 5. Run upgrade checker
mysql_upgrade -u root -p

# 6. Optimize tables
mysqlcheck -u root -p --all-databases --optimize
```

## Parallel Restore for Large Databases

### Using mydumper/myloader
```bash
#!/bin/bash
# Parallel backup and restore

# Parallel backup
mydumper \
  -u root \
  -p password \
  -B large_database \
  -c \
  -t 8 \
  -F 256 \
  -o /backup/mydumper/

# Parallel restore
myloader \
  -u root \
  -p password \
  -B large_database \
  -d /backup/mydumper/ \
  -t 8 \
  -o
```

### Custom Parallel Restore Script
```bash
#!/bin/bash
# Custom parallel table restore

DB_NAME="large_database"
BACKUP_DIR="/backup/tables"
PARALLEL_JOBS=4

# Function to restore table
restore_table() {
    local table=$1
    echo "Restoring ${table}..."
    mysql -u root -p${MYSQL_PWD} ${DB_NAME} < ${BACKUP_DIR}/${table}.sql
    echo "Completed ${table}"
}

# Export function for parallel execution
export -f restore_table
export MYSQL_PWD="password"
export DB_NAME
export BACKUP_DIR

# Get list of tables
TABLES=$(ls ${BACKUP_DIR}/*.sql | xargs -n1 basename | sed 's/.sql//')

# Restore in parallel
echo "${TABLES}" | xargs -P ${PARALLEL_JOBS} -I {} bash -c 'restore_table "{}"'
```

## Restore Validation

### Data Integrity Checks
```bash
#!/bin/bash
# Comprehensive restore validation

DB_NAME="restored_database"

# 1. Check table counts
mysql -u root -p ${DB_NAME} << 'EOF' > restore_validation.txt
SELECT 'Table Counts:' as '';
SELECT
    table_name,
    table_rows
FROM information_schema.tables
WHERE table_schema = DATABASE()
ORDER BY table_name;
EOF

# 2. Check foreign key constraints
mysql -u root -p ${DB_NAME} << 'EOF' >> restore_validation.txt
SELECT 'Foreign Key Validation:' as '';
SELECT
    constraint_name,
    table_name,
    referenced_table_name
FROM information_schema.key_column_usage
WHERE constraint_schema = DATABASE()
    AND referenced_table_name IS NOT NULL;
EOF

# 3. Check for orphaned records
mysql -u root -p ${DB_NAME} << 'EOF' >> restore_validation.txt
SELECT 'Orphaned Records Check:' as '';
-- Example for orders/customers
SELECT COUNT(*) as orphaned_orders
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.id
WHERE c.id IS NULL;
EOF

# 4. Verify stored procedures
mysql -u root -p ${DB_NAME} << 'EOF' >> restore_validation.txt
SELECT 'Stored Procedures:' as '';
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_schema = DATABASE();
EOF

# 5. Check triggers
mysql -u root -p ${DB_NAME} << 'EOF' >> restore_validation.txt
SELECT 'Triggers:' as '';
SELECT trigger_name, event_manipulation, event_object_table
FROM information_schema.triggers
WHERE trigger_schema = DATABASE();
EOF

echo "Validation complete. Results in restore_validation.txt"
```

### Application-Level Validation
```bash
#!/bin/bash
# Application smoke tests after restore

# 1. Database connectivity
echo "Testing database connectivity..."
mysql -u app_user -p -e "SELECT 1" || exit 1

# 2. Critical queries
echo "Testing critical queries..."
mysql -u app_user -p production_db << EOF
-- Test user authentication
SELECT COUNT(*) FROM users WHERE active = 1;

-- Test recent transactions
SELECT COUNT(*) FROM orders
WHERE created_at > DATE_SUB(NOW(), INTERVAL 1 DAY);

-- Test data integrity
SELECT
    (SELECT COUNT(*) FROM orders) as orders,
    (SELECT COUNT(*) FROM order_items) as items,
    (SELECT SUM(quantity) FROM inventory) as stock;
EOF

# 3. API endpoint tests
echo "Testing API endpoints..."
curl -f http://localhost/api/health || exit 1
curl -f http://localhost/api/users/1 || exit 1

# 4. Run application test suite
cd /app && npm test
```

## Restore Performance Optimization

### Pre-Restore Optimization
```sql
-- Disable constraints temporarily
SET FOREIGN_KEY_CHECKS = 0;
SET UNIQUE_CHECKS = 0;
SET AUTOCOMMIT = 0;
SET SQL_LOG_BIN = 0;

-- Increase buffer sizes
SET GLOBAL innodb_buffer_pool_size = 8G;
SET GLOBAL innodb_log_file_size = 2G;
SET GLOBAL max_allowed_packet = 1G;
```

### Post-Restore Optimization
```sql
-- Re-enable constraints
SET FOREIGN_KEY_CHECKS = 1;
SET UNIQUE_CHECKS = 1;
SET AUTOCOMMIT = 1;
SET SQL_LOG_BIN = 1;

-- Analyze tables
ANALYZE TABLE table1, table2, table3;

-- Optimize tables
OPTIMIZE TABLE table1, table2, table3;

-- Update statistics
SET GLOBAL innodb_stats_persistent_sample_pages = 100;
ANALYZE TABLE table1, table2, table3;
```

## Emergency Recovery Procedures

### Corrupted InnoDB Recovery
```bash
# 1. Try automatic recovery
cat >> /etc/mysql/my.cnf << EOF
[mysqld]
innodb_force_recovery = 1
EOF

# 2. Start MySQL and dump data
systemctl start mysql
mysqldump -u root -p --all-databases > emergency_backup.sql

# 3. If level 1 fails, try higher levels (2-6)
# Level 4: No background operations
# Level 6: No redo log application

# 4. Rebuild after dump
systemctl stop mysql
rm -rf /var/lib/mysql/*
mysql_install_db --user=mysql
systemctl start mysql
mysql -u root -p < emergency_backup.sql
```

### Binary Log Recovery
```bash
#!/bin/bash
# Recover using only binary logs

# 1. Find all binary logs
BINLOGS=$(ls /var/log/mysql/mysql-bin.* | grep -v index)

# 2. Extract SQL statements
for log in ${BINLOGS}; do
    mysqlbinlog ${log} > ${log}.sql
done

# 3. Filter for specific database/table
grep -h "USE.*production_db" mysql-bin.*.sql > filtered_recovery.sql

# 4. Apply filtered statements
mysql -u root -p < filtered_recovery.sql
```

## Monitoring Restore Progress

### Real-time Progress Monitoring
```bash
# Monitor restore progress
pv backup.sql | mysql -u root -p database_name

# Or with custom progress
(pv -n backup.sql | mysql -u root -p database_name) 2>&1 | \
  dialog --gauge "Restoring database..." 10 70 0
```

### Restore Metrics Collection
```bash
#!/bin/bash
# Collect restore metrics

START_TIME=$(date +%s)
BACKUP_SIZE=$(stat -c%s backup.sql)

# Restore with monitoring
mysql -u root -p database_name < backup.sql &
RESTORE_PID=$!

# Monitor progress
while kill -0 $RESTORE_PID 2>/dev/null; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))

    # Check MySQL processlist
    mysql -u root -p -e "SHOW PROCESSLIST\G" | grep -E "State|Info"

    echo "Elapsed: ${ELAPSED} seconds"
    sleep 5
done

END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))

echo "Restore Statistics:"
echo "- Backup Size: $((BACKUP_SIZE / 1024 / 1024)) MB"
echo "- Total Time: ${TOTAL_TIME} seconds"
echo "- Rate: $((BACKUP_SIZE / TOTAL_TIME / 1024)) KB/s"
```

## Disaster Recovery Runbook

### Pre-Disaster Preparation
1. **Documentation**: Keep restore procedures printed/offline
2. **Contacts**: Maintain emergency contact list
3. **Credentials**: Store passwords securely but accessible
4. **Backup Locations**: Document all backup storage locations
5. **Dependencies**: List all system dependencies

### During Disaster
1. **Assess**: Determine scope of failure
2. **Communicate**: Notify stakeholders
3. **Decide**: Choose recovery strategy
4. **Execute**: Follow documented procedures
5. **Validate**: Verify data integrity
6. **Monitor**: Watch for issues post-recovery

### Post-Recovery Actions
1. **Root Cause Analysis**: Understand what happened
2. **Documentation Update**: Improve procedures
3. **Testing**: Schedule recovery drills
4. **Backup Review**: Assess backup strategy
5. **Monitoring Enhancement**: Improve alerting

## Best Practices

1. **Regular Testing**: Test restores monthly
2. **Documentation**: Keep procedures current
3. **Automation**: Script common scenarios
4. **Monitoring**: Alert on backup/restore failures
5. **Validation**: Always verify restored data
6. **Security**: Encrypt sensitive backups
7. **Redundancy**: Multiple backup locations
8. **Retention**: Define clear policies
9. **Performance**: Optimize for speed
10. **Training**: Ensure team knows procedures

## Next Steps

1. Create restore runbooks for each database
2. Schedule regular restore drills
3. Automate validation procedures
4. Set up monitoring and alerting
5. Document lessons learned from each restore