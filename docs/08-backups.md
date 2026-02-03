# Backups

## Overview
Backup strategies are critical for data protection and disaster recovery. This document covers MySQL backup approaches, tools, and best practices applicable to all database examples in this repository.

## Backup Types

### 1. Logical Backups
Export data as SQL statements that can recreate the database.

**Advantages:**
- Human-readable format
- Platform independent
- Easy to modify or filter
- Version agnostic (mostly)

**Disadvantages:**
- Slower for large databases
- Larger file sizes
- Can't do incremental backups
- Locks tables during export

### 2. Physical Backups
Copy the actual database files from the file system.

**Advantages:**
- Very fast backup and restore
- Supports incremental backups
- Minimal impact on running database
- Exact copy of database state

**Disadvantages:**
- Platform and version specific
- Not human-readable
- Requires filesystem access
- Can be complex to manage

### 3. Snapshot Backups
Leverage filesystem or storage-level snapshots.

**Advantages:**
- Near-instantaneous
- Minimal performance impact
- Point-in-time recovery
- Works with any database size

**Disadvantages:**
- Requires specific infrastructure
- May need filesystem freeze
- Storage overhead
- Platform dependent

## Backup Tools

### mysqldump (Logical)
Standard MySQL backup utility for logical backups.

#### Basic Usage
```bash
# Single database
mysqldump -u root -p database_name > backup.sql

# All databases
mysqldump -u root -p --all-databases > all_databases.sql

# Specific tables
mysqldump -u root -p database_name table1 table2 > tables.sql
```

#### Advanced Options
```bash
# Complete backup with routines and triggers
mysqldump -u root -p \
  --single-transaction \
  --routines \
  --triggers \
  --events \
  --add-drop-database \
  database_name > complete_backup.sql

# Consistent backup for InnoDB
mysqldump -u root -p \
  --single-transaction \
  --quick \
  --lock-tables=false \
  database_name > consistent_backup.sql

# Structure only (no data)
mysqldump -u root -p \
  --no-data \
  database_name > schema_only.sql

# Data only (no structure)
mysqldump -u root -p \
  --no-create-info \
  database_name > data_only.sql
```

#### Compression
```bash
# Compress on the fly
mysqldump -u root -p database_name | gzip > backup.sql.gz

# With timestamp
mysqldump -u root -p database_name | gzip > backup_$(date +%Y%m%d_%H%M%S).sql.gz
```

### MySQL Enterprise Backup (Physical)
Commercial tool for hot physical backups.

```bash
# Full backup
mysqlbackup --user=root --password \
  --backup-dir=/backup/full \
  backup

# Incremental backup
mysqlbackup --user=root --password \
  --incremental \
  --incremental-base=dir:/backup/full \
  --incremental-backup-dir=/backup/inc1 \
  backup
```

### Percona XtraBackup (Physical)
Open-source hot backup tool for InnoDB.

```bash
# Full backup
xtrabackup --backup --target-dir=/backup/full

# Incremental backup
xtrabackup --backup \
  --target-dir=/backup/inc1 \
  --incremental-basedir=/backup/full

# Prepare backup for restore
xtrabackup --prepare --target-dir=/backup/full
```

### mydumper/myloader (Logical, Parallel)
Parallel logical backup utility.

```bash
# Parallel backup (4 threads)
mydumper -u root -p password \
  -B database_name \
  -c \
  -t 4 \
  -o /backup/mydumper/

# Parallel restore
myloader -u root -p password \
  -B database_name \
  -d /backup/mydumper/ \
  -t 4
```

## Backup Strategies by Example Type

### IoT Time Series Databases
Special considerations for high-volume time series data:

```bash
# Backup only recent partitions
#!/bin/bash
CUTOFF_DATE=$(date -d "30 days ago" +%Y%m%d)

mysql -u root -p -e "
  SELECT PARTITION_NAME
  FROM information_schema.PARTITIONS
  WHERE TABLE_NAME = 'sensor_readings'
    AND PARTITION_NAME > 'p${CUTOFF_DATE}'
" | while read partition; do
  mysqldump -u root -p \
    --where="DATE(timestamp) > DATE_SUB(NOW(), INTERVAL 30 DAY)" \
    database_name sensor_readings > backup_${partition}.sql
done
```

### E-commerce Databases
Critical transactional data requiring zero data loss:

```bash
# Point-in-time recovery setup
# Enable binary logging
SET GLOBAL log_bin = ON;
SET GLOBAL binlog_format = 'ROW';

# Backup with binary log position
mysqldump -u root -p \
  --single-transaction \
  --master-data=2 \
  --flush-logs \
  ecommerce > ecommerce_backup.sql

# Record binary log position from backup file
grep "CHANGE MASTER" ecommerce_backup.sql
```

### Healthcare Databases
Compliance and audit requirements:

```bash
# Encrypted backup
mysqldump -u root -p healthcare | \
  openssl enc -aes-256-cbc -salt -pass pass:YourPassword | \
  gzip > healthcare_encrypted.sql.gz.enc

# Decrypt and restore
gunzip < healthcare_encrypted.sql.gz.enc | \
  openssl enc -d -aes-256-cbc -pass pass:YourPassword | \
  mysql -u root -p healthcare
```

## Automated Backup Scripts

### Daily Backup Script
```bash
#!/bin/bash
# /usr/local/bin/mysql_daily_backup.sh

# Configuration
BACKUP_DIR="/backup/mysql"
MYSQL_USER="backup_user"
MYSQL_PASS="backup_password"
RETENTION_DAYS=30

# Create backup directory with date
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="${BACKUP_DIR}/${DATE}"
mkdir -p ${BACKUP_PATH}

# Backup all databases
databases=$(mysql -u${MYSQL_USER} -p${MYSQL_PASS} -e "SHOW DATABASES;" | grep -v Database)

for db in $databases; do
    if [[ "$db" != "information_schema" ]] && [[ "$db" != "performance_schema" ]] && [[ "$db" != "sys" ]]; then
        echo "Backing up ${db}..."
        mysqldump -u${MYSQL_USER} -p${MYSQL_PASS} \
            --single-transaction \
            --routines \
            --triggers \
            --events \
            ${db} | gzip > ${BACKUP_PATH}/${db}.sql.gz
    fi
done

# Remove old backups
find ${BACKUP_DIR} -type d -mtime +${RETENTION_DAYS} -exec rm -rf {} \;

# Log completion
echo "Backup completed at $(date)" >> ${BACKUP_DIR}/backup.log
```

### Crontab Entry
```bash
# Add to crontab -e
# Daily backup at 2 AM
0 2 * * * /usr/local/bin/mysql_daily_backup.sh

# Weekly full backup on Sunday
0 3 * * 0 /usr/local/bin/mysql_weekly_full_backup.sh

# Hourly incremental backup
0 * * * * /usr/local/bin/mysql_hourly_incremental.sh
```

## Backup Validation

### Test Restore Process
```bash
#!/bin/bash
# Test backup integrity

BACKUP_FILE=$1
TEST_DB="test_restore_${RANDOM}"

# Create test database
mysql -u root -p -e "CREATE DATABASE ${TEST_DB}"

# Restore backup
gunzip < ${BACKUP_FILE} | mysql -u root -p ${TEST_DB}

# Verify tables
table_count=$(mysql -u root -p ${TEST_DB} -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${TEST_DB}'" -s)

if [ $table_count -gt 0 ]; then
    echo "Backup validation successful: ${table_count} tables restored"

    # Run integrity checks
    mysql -u root -p ${TEST_DB} -e "CHECK TABLE \`*\`"
else
    echo "Backup validation failed: No tables restored"
fi

# Cleanup
mysql -u root -p -e "DROP DATABASE ${TEST_DB}"
```

### Checksum Verification
```bash
# Generate checksums during backup
mysqldump -u root -p database_name | tee >(md5sum > backup.md5) | gzip > backup.sql.gz

# Verify checksum
gunzip < backup.sql.gz | md5sum -c backup.md5
```

## Cloud Backup Solutions

### AWS S3
```bash
# Backup to S3
mysqldump -u root -p database_name | gzip | \
  aws s3 cp - s3://my-bucket/mysql-backups/backup_$(date +%Y%m%d).sql.gz

# Restore from S3
aws s3 cp s3://my-bucket/mysql-backups/backup_20240101.sql.gz - | \
  gunzip | mysql -u root -p database_name
```

### Google Cloud Storage
```bash
# Backup to GCS
mysqldump -u root -p database_name | gzip | \
  gsutil cp - gs://my-bucket/mysql-backups/backup_$(date +%Y%m%d).sql.gz

# Restore from GCS
gsutil cp gs://my-bucket/mysql-backups/backup_20240101.sql.gz - | \
  gunzip | mysql -u root -p database_name
```

### Azure Blob Storage
```bash
# Backup to Azure
mysqldump -u root -p database_name | gzip | \
  az storage blob upload \
    --container-name backups \
    --name backup_$(date +%Y%m%d).sql.gz \
    --file -
```

## Binary Log Management

### Enable Binary Logging
```sql
-- In my.cnf
[mysqld]
log_bin = /var/log/mysql/mysql-bin
binlog_format = ROW
expire_logs_days = 7
max_binlog_size = 100M
```

### Binary Log Backup
```bash
# Backup binary logs
mysqlbinlog --read-from-remote-server \
  --host=localhost \
  --user=root \
  --password \
  --raw \
  --to-last-log \
  --result-file=/backup/binlogs/ \
  mysql-bin.000001
```

### Point-in-Time Recovery
```bash
# Restore to specific time
mysqlbinlog --stop-datetime="2024-01-01 12:00:00" \
  mysql-bin.000001 mysql-bin.000002 | \
  mysql -u root -p
```

## Monitoring and Alerts

### Backup Monitoring Script
```bash
#!/bin/bash
# Check last backup age

BACKUP_DIR="/backup/mysql"
MAX_AGE_HOURS=26

# Find most recent backup
latest_backup=$(find ${BACKUP_DIR} -name "*.sql.gz" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -f2- -d" ")

if [ -z "$latest_backup" ]; then
    echo "CRITICAL: No backups found"
    exit 2
fi

# Check age
age_hours=$(( ($(date +%s) - $(stat -c %Y "$latest_backup")) / 3600 ))

if [ $age_hours -gt $MAX_AGE_HOURS ]; then
    echo "WARNING: Last backup is ${age_hours} hours old"
    exit 1
fi

echo "OK: Last backup is ${age_hours} hours old"
exit 0
```

## Performance Considerations

### Minimize Lock Time
```bash
# For InnoDB tables
mysqldump --single-transaction --quick --lock-tables=false

# For MyISAM tables
mysqldump --lock-all-tables
```

### Reduce I/O Impact
```bash
# Use nice and ionice
nice -n 19 ionice -c2 -n7 mysqldump -u root -p database_name > backup.sql

# Limit backup speed
mysqldump -u root -p database_name | pv -L 10M | gzip > backup.sql.gz
```

### Parallel Processing
```bash
# Parallel table dumps
for table in $(mysql -u root -p -e "SHOW TABLES FROM database_name" -s); do
    mysqldump -u root -p database_name $table > ${table}.sql &
done
wait
```

## Disaster Recovery Plan

### RPO and RTO Targets
- **RPO (Recovery Point Objective)**: Maximum data loss tolerance
  - Critical systems: < 1 hour
  - Important systems: < 4 hours
  - Standard systems: < 24 hours

- **RTO (Recovery Time Objective)**: Maximum downtime tolerance
  - Critical systems: < 1 hour
  - Important systems: < 4 hours
  - Standard systems: < 8 hours

### Recovery Testing Schedule
1. **Monthly**: Test single table restore
2. **Quarterly**: Test full database restore
3. **Annually**: Complete disaster recovery drill

### Documentation Requirements
- Backup schedules and retention policies
- Recovery procedures step-by-step
- Contact information for key personnel
- Infrastructure dependencies
- Testing logs and results

## Best Practices

1. **3-2-1 Rule**: Keep 3 copies, on 2 different media, with 1 offsite
2. **Test Restores**: Regularly verify backup integrity
3. **Automate**: Use scripts and schedulers for consistency
4. **Monitor**: Alert on backup failures or delays
5. **Document**: Maintain clear recovery procedures
6. **Encrypt**: Protect sensitive data in transit and at rest
7. **Version**: Include schema version in backup metadata
8. **Rotate**: Implement grandfather-father-son rotation

## Common Issues and Solutions

### Issue: Backup Takes Too Long
- Use parallel tools (mydumper)
- Implement incremental backups
- Use physical backups instead of logical
- Optimize with --single-transaction

### Issue: Storage Space
- Implement compression
- Use incremental backups
- Adjust retention policies
- Move to cloud storage

### Issue: Inconsistent Backups
- Use --single-transaction for InnoDB
- Stop applications during backup
- Use dedicated replica for backups
- Implement physical backups

## Next Steps

1. Define RPO/RTO requirements for your databases
2. Implement automated backup scripts
3. Set up monitoring and alerting
4. Test restore procedures regularly
5. Document recovery processes