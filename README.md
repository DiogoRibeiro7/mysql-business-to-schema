# mysql-business-to-schema

Learn how to move from a business narrative to a production-ready MySQL schema. This comprehensive repository contains **9 complete database examples** spanning IoT systems, healthcare, e-commerce, and machine learning applications. Each example includes schemas, queries, procedures, and detailed documentation.

## 🎯 What this repo teaches
- Business problem → requirements analysis
- Requirements → ER model design
- ER model → relational schema implementation
- Normalization and design tradeoffs
- MySQL physical design (types, storage, keys)
- Time series data modeling and partitioning
- IoT sensor data patterns and optimizations
- Spatial queries and GIS integration
- Machine learning feature engineering
- Multi-tenant architecture patterns
- Indexing strategies for different workloads
- Real-world queries and reporting
- Transactions and consistency
- Performance optimization techniques

## 📚 Available Examples

### IoT Systems (7 examples)
- **Example 02**: IoT Garbage Bin Monitoring - Smart city waste management
- **Example 03**: Smart Energy Grid - Multi-tenant utility monitoring
- **Example 05**: Industrial IoT - Manufacturing OEE and predictive maintenance
- **Example 06**: Smart Agriculture - Precision farming and irrigation
- **Example 07**: Fleet Management - Vehicle tracking and telematics
- **Example 08**: Healthcare IoT - Patient monitoring and medical devices
- **Example 09**: Streaming ML Platform - Real-time analytics and ML features

### Traditional Systems (2 examples)
- **Example 01**: Medical Clinic - Appointments, billing, and patient records
- **Example 04**: E-commerce Platform - Orders, inventory, and transactions

See [EXAMPLES_OVERVIEW.md](EXAMPLES_OVERVIEW.md) for detailed descriptions of each example.

## 🚀 Choosing Your Starting Point

### By Interest:
- **IoT/Sensors**: Start with Example 02 (IoT Bins) then explore 03, 05-08
- **Data Science/ML**: Jump to Example 09 (Streaming ML Platform)
- **Traditional RDBMS**: Begin with Example 01 (Clinic) or 04 (E-commerce)
- **Spatial/GIS**: Check out Examples 02, 06, or 07
- **Time Series**: Examples 02, 03, 05-09 all feature time series patterns

### By Complexity:
- **Beginner**: Example 01 (Clinic) → Example 04 (E-commerce)
- **Intermediate**: Example 02 (IoT Bins) → Example 03 (Smart Energy)
- **Advanced**: Example 09 (Streaming ML) or Example 08 (Healthcare IoT)

## Quick start (MySQL via Docker Compose)

PowerShell (Windows):
```powershell
docker compose -f docker/docker-compose.yml up -d
docker compose -f docker/docker-compose.yml ps
```

Bash (macOS/Linux/Git Bash):
```bash
docker compose -f docker/docker-compose.yml up -d
docker compose -f docker/docker-compose.yml ps
```

## Load any example schema and seed data

Replace `example_XX` with your chosen example (01-09). Example shown for clinic (01) and IoT bins (02):

PowerShell (Windows):
```powershell
# Enter the password configured in docker/docker-compose.yml when prompted
docker compose -f docker/docker-compose.yml exec mysql mysql -uroot -p < example_01_clinic/schema/00_create_database.sql
docker compose -f docker/docker-compose.yml exec mysql mysql -uroot -p < example_01_clinic/schema/01_tables.sql
docker compose -f docker/docker-compose.yml exec mysql mysql -uroot -p < example_01_clinic/schema/02_constraints.sql
docker compose -f docker/docker-compose.yml exec mysql mysql -uroot -p < example_01_clinic/schema/03_indexes.sql

# Seed data (if present)
docker compose -f docker/docker-compose.yml exec mysql mysql -uroot -p < example_01_clinic/data/seed.sql
```

Bash (macOS/Linux/Git Bash):
```bash
# Enter the password configured in docker/docker-compose.yml when prompted
docker compose -f docker/docker-compose.yml exec mysql mysql -uroot -p < example_01_clinic/schema/00_create_database.sql
docker compose -f docker/docker-compose.yml exec mysql mysql -uroot -p < example_01_clinic/schema/01_tables.sql
docker compose -f docker/docker-compose.yml exec mysql mysql -uroot -p < example_01_clinic/schema/02_constraints.sql
docker compose -f docker/docker-compose.yml exec mysql mysql -uroot -p < example_01_clinic/schema/03_indexes.sql

# Seed data (if present)
docker compose -f docker/docker-compose.yml exec mysql mysql -uroot -p < example_01_clinic/data/seed.sql
```

## Generate new datasets

PowerShell (Windows):
```powershell
python generators/clinic/generate.py --config generators/clinic/config.yaml
```

Bash (macOS/Linux/Git Bash):
```bash
python generators/clinic/generate.py --config generators/clinic/config.yaml
```

## Load generated CSVs into MySQL

These steps work with Docker on Windows because MySQL’s `secure_file_priv` only allows loading from `/var/lib/mysql-files`.

PowerShell (Windows):
```powershell
# 1) Generate data
python generators/clinic/generate.py --config generators/clinic/config.yaml

# 2) Copy CSVs into the MySQL container
docker compose -f docker/docker-compose.yml exec mysql mkdir -p /var/lib/mysql-files/clinic_generated
docker cp generators/clinic/output/patients.csv mysql_business_to_schema:/var/lib/mysql-files/clinic_generated/
docker cp generators/clinic/output/doctors.csv mysql_business_to_schema:/var/lib/mysql-files/clinic_generated/
docker cp generators/clinic/output/appointments.csv mysql_business_to_schema:/var/lib/mysql-files/clinic_generated/
docker cp generators/clinic/output/invoices.csv mysql_business_to_schema:/var/lib/mysql-files/clinic_generated/
docker cp generators/clinic/output/payments.csv mysql_business_to_schema:/var/lib/mysql-files/clinic_generated/

# 3) Load into MySQL
docker compose -f docker/docker-compose.yml exec mysql mysql -uroot -p < example_01_clinic/schema/10_load_generated.sql
```

Bash (macOS/Linux/Git Bash):
```bash
# 1) Generate data
python generators/clinic/generate.py --config generators/clinic/config.yaml

# 2) Copy CSVs into the MySQL container
docker compose -f docker/docker-compose.yml exec mysql mkdir -p /var/lib/mysql-files/clinic_generated
docker cp generators/clinic/output/patients.csv mysql_business_to_schema:/var/lib/mysql-files/clinic_generated/
docker cp generators/clinic/output/doctors.csv mysql_business_to_schema:/var/lib/mysql-files/clinic_generated/
docker cp generators/clinic/output/appointments.csv mysql_business_to_schema:/var/lib/mysql-files/clinic_generated/
docker cp generators/clinic/output/invoices.csv mysql_business_to_schema:/var/lib/mysql-files/clinic_generated/
docker cp generators/clinic/output/payments.csv mysql_business_to_schema:/var/lib/mysql-files/clinic_generated/

# 3) Load into MySQL
docker compose -f docker/docker-compose.yml exec mysql mysql -uroot -p < example_01_clinic/schema/10_load_generated.sql
```

Fallback (if LOAD DATA is blocked):
```powershell
# PowerShell or Bash
docker compose -f docker/docker-compose.yml exec mysql mysql -uroot -p < generators/clinic/output/seed_generated.sql
```

## Learning path
Work through these in order:
- docs/00-business-problem.md
- docs/01-requirements.md
- docs/02-conceptual-model-er.md
- docs/03-logical-model-relational.md
- docs/04-normalization.md
- docs/03-constraints.md
- docs/04-indexing.md
- docs/05-sample-data.md
- docs/06-queries.md
- docs/07-transactions.md
- docs/08-backups.md
- docs/09-backup-and-restore.md
- docs/assignments.md

## Assignments

Each example includes practice queries and exercises:

### Basic Level (Examples 01, 04)
- Implement constraints and foreign keys
- Write basic SELECT queries with JOINs
- Create views for common reports
- Practice transactions and data integrity

### IoT & Time Series (Examples 02, 03, 05-08)
- Design partitioning strategies
- Write aggregation queries (hourly/daily rollups)
- Implement real-time monitoring dashboards
- Create alert detection queries
- Optimize queries using EXPLAIN

### Advanced (Example 09)
- Build feature engineering pipelines
- Implement collaborative filtering
- Design A/B testing queries
- Create ML-ready data views

Check each example's `queries/` folder for specific exercises and the README for learning objectives.

## Troubleshooting
- `Access denied` when loading CSVs: ensure files are copied into `/var/lib/mysql-files/clinic_generated/` and use `example_01_clinic/schema/10_load_generated.sql`.
- `secure_file_priv` errors: use the fallback `generators/clinic/output/seed_generated.sql` load command.
- Port 3306 already in use: stop the conflicting service or change the host port in `docker/docker-compose.yml`.
- Container name mismatch: if you changed it, update `docker cp` commands to match.
