# 📊 Data Generation Guide

## Complete Guide for Generating Sample Data in MySQL Business-to-Schema

This guide provides multiple methods to generate and import sample data into your MySQL schemas.

---

## 🚀 Quick Start (Docker Method)

The easiest way to get started with a fully configured MySQL instance:

```bash
# Start MySQL with Docker
docker-compose -f docker-compose.mysql.yml up -d

# Wait for MySQL to be ready (about 30 seconds)
sleep 30

# Verify MySQL is running
docker exec mysql-schema-db mysql -uroot -proot -e "SHOW DATABASES;"

# Import demo data
docker exec -i mysql-schema-db mysql -uroot -proot < demo_data/clinic_db_data.sql
docker exec -i mysql-schema-db mysql -uroot -proot < demo_data/ecommerce_db_data.sql
docker exec -i mysql-schema-db mysql -uroot -proot < demo_data/iot_bins_db_data.sql

# Access phpMyAdmin to view data
# Open browser: http://localhost:8080
# Login: root / root
```

---

## 📝 Method 1: Pre-Generated SQL Files (No MySQL Required)

I've already generated SQL files with sample data that you can import when ready:

### Generated Files:
- `demo_data/clinic_db_data.sql` - 1000 patient records
- `demo_data/ecommerce_db_data.sql` - 1000 products, 500 customers
- `demo_data/iot_bins_db_data.sql` - 200 sensors, 1000 readings

### To Import:
```bash
# When MySQL is available, import all at once:
cd demo_data
mysql -u root -p < import_all.sql

# Or import individually:
mysql -u root -p clinic_db < clinic_db_data.sql
mysql -u root -p ecommerce_db < ecommerce_db_data.sql
mysql -u root -p iot_bins_db < iot_bins_db_data.sql
```

---

## 🔧 Method 2: Generate Custom Data

### Generate New SQL Files (No MySQL Required):
```bash
# Generate with custom record count
python generators/demo_data_generator.py --records 5000

# Files will be created in demo_data/ directory
```

### Generate and Insert Directly (Requires MySQL):
```bash
# First, set your MySQL credentials
export MYSQL_USER=root
export MYSQL_PASSWORD=yourpassword
export MYSQL_HOST=localhost

# Generate and insert data
python generators/generate_all_data.py --records 1000 --clean

# Or generate for specific schemas only
python generators/generate_all_data.py --records 500 --schemas clinic_db ecommerce_db
```

---

## 🐳 Method 3: Full Docker Environment

### Start Complete Stack:
```bash
# Start all services (MySQL, Kafka, Redis, etc.)
docker-compose up -d

# Check service health
docker-compose ps

# Run data generation inside container
docker-compose exec mysql sh -c "
  cd /app && python generators/generate_all_data.py --records 1000
"
```

---

## 🛠️ Method 4: Windows Quick Setup

### Using Batch Scripts:
```batch
REM Start MySQL with Docker Desktop
docker-compose -f docker-compose.mysql.yml up -d

REM Wait for MySQL
timeout /t 30

REM Run data generation
scripts\run_data_generation.bat --records 1000

REM Verify data
python scripts\verify_data.py
```

### Using PowerShell:
```powershell
# Start MySQL
docker-compose -f docker-compose.mysql.yml up -d

# Generate data
python generators/demo_data_generator.py --records 2000

# Import to MySQL
Get-Content demo_data\import_all.sql | docker exec -i mysql-schema-db mysql -uroot -proot
```

---

## 📊 Data Verification

### Check Generated Data:
```bash
# Run verification script
python scripts/verify_data.py

# Manual verification
mysql -u root -p -e "
  SELECT table_schema, COUNT(*) as tables, SUM(table_rows) as total_rows
  FROM information_schema.tables
  WHERE table_schema LIKE '%_db'
  GROUP BY table_schema;
"
```

### View in phpMyAdmin:
1. Open http://localhost:8080
2. Login with root/root
3. Browse databases and tables
4. Run queries and export data

---

## 🎯 Sample Queries to Test Data

### Healthcare Analytics (clinic_db):
```sql
-- Patient demographics
SELECT
    COUNT(*) as total_patients,
    AVG(YEAR(CURDATE()) - YEAR(date_of_birth)) as avg_age,
    SUM(CASE WHEN gender = 'M' THEN 1 ELSE 0 END) as male_count,
    SUM(CASE WHEN gender = 'F' THEN 1 ELSE 0 END) as female_count
FROM clinic_db.patients;

-- Monthly appointments
SELECT
    DATE_FORMAT(appointment_date, '%Y-%m') as month,
    COUNT(*) as appointment_count
FROM clinic_db.appointments
GROUP BY month
ORDER BY month DESC;
```

### E-commerce Analytics (ecommerce_db):
```sql
-- Product inventory
SELECT
    category,
    COUNT(*) as product_count,
    AVG(price) as avg_price,
    SUM(stock_quantity) as total_stock
FROM ecommerce_db.products
GROUP BY category;

-- Customer growth
SELECT
    DATE_FORMAT(registration_date, '%Y-%m') as month,
    COUNT(*) as new_customers
FROM ecommerce_db.customers
GROUP BY month;
```

### IoT Analytics (iot_bins_db):
```sql
-- Sensor statistics
SELECT
    type as sensor_type,
    COUNT(*) as sensor_count,
    COUNT(CASE WHEN status = 'active' THEN 1 END) as active_count
FROM iot_bins_db.sensors
GROUP BY type;

-- Recent readings
SELECT
    s.type,
    COUNT(r.id) as reading_count,
    AVG(r.value) as avg_value,
    MAX(r.value) as max_value,
    MIN(r.value) as min_value
FROM iot_bins_db.readings r
JOIN iot_bins_db.sensors s ON r.sensor_id = s.sensor_id
WHERE r.timestamp >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
GROUP BY s.type;
```

---

## 🔍 Troubleshooting

### Issue: MySQL Connection Refused
```bash
# Check if MySQL is running
docker ps | grep mysql

# Check MySQL logs
docker logs mysql-schema-db

# Try connecting with Docker
docker exec -it mysql-schema-db mysql -uroot -proot
```

### Issue: Access Denied
```bash
# Reset MySQL password (Docker)
docker-compose down
docker volume rm mysql-schema-data
docker-compose -f docker-compose.mysql.yml up -d

# For local MySQL, check credentials
mysql -u root -p
# Enter your password when prompted
```

### Issue: Schema Does Not Exist
```bash
# Create schemas first
for schema in example_*/schema/00_create_database.sql; do
    mysql -u root -p < "$schema"
done

# Then import data
cd demo_data
mysql -u root -p < import_all.sql
```

### Issue: Encoding Problems (Windows)
```bash
# Use UTF-8 encoding
chcp 65001

# Or use Docker method instead
docker exec -i mysql-schema-db mysql -uroot -proot < demo_data/import_all.sql
```

---

## 📈 Data Statistics

After successful import, you should have:

| Schema | Tables | Sample Records | Use Case |
|--------|--------|---------------|----------|
| clinic_db | 15+ | ~5,000 | Healthcare management |
| ecommerce_db | 20+ | ~10,000 | Online shopping |
| iot_bins_db | 10+ | ~5,000 | IoT sensor monitoring |
| smart_energy_db | 12+ | ~3,000 | Energy management |
| fintech_db | 15+ | ~8,000 | Financial transactions |
| social_media_db | 18+ | ~15,000 | Social networking |
| ... | ... | ... | ... |

**Total: 20 schemas, 300+ tables, 100,000+ records**

---

## ✅ Success Checklist

- [ ] MySQL is running (local or Docker)
- [ ] Schemas are created
- [ ] Demo data files generated
- [ ] Data imported successfully
- [ ] Verification script shows data
- [ ] Sample queries return results
- [ ] phpMyAdmin shows databases

---

## 🎉 Next Steps

Once data is generated and imported:

1. **Test the APIs**:
   ```bash
   cd admin_dashboard/backend
   uvicorn main:app --reload
   # Visit http://localhost:8000/docs
   ```

2. **Run ML Models**:
   ```bash
   python ml-platform/train_models.py
   ```

3. **Start Streaming Pipeline**:
   ```bash
   docker-compose up kafka clickhouse -d
   python data-pipeline/stream-processors/app.py
   ```

4. **Run Performance Tests**:
   ```bash
   locust -f performance-testing/locust/locustfile.py
   ```

---

## 📚 Additional Resources

- [System Review](SYSTEM_REVIEW.md) - Complete system overview
- [API Documentation](docs/API_DOCUMENTATION.md) - API endpoints
- [Quick Start Guide](QUICK_START.md) - Full system setup
- [Test System](test_system.py) - Automated testing

---

**Need Help?** The demo data in `demo_data/` is ready to use whenever MySQL is available!