# mysql-business-to-schema

Learn how to move from a business narrative to a production-ready MySQL schema. This repo is structured as a guided path with docs, a worked example, and generators to create datasets you can practice on.

## What this repo teaches
- Business problem → requirements
- Requirements → ER model
- ER model → relational schema
- Normalization and design tradeoffs
- MySQL physical design (types, storage, keys)
- Indexing strategy
- Queries and reporting
- Transactions and consistency
- Backup and restore workflows

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

## Load schema and seed data (example_01_clinic)

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

## Assignments
- Implement all constraints in `example_01_clinic/schema/02_constraints.sql`.
- Write and verify queries in `example_01_clinic/queries/01_basic_selects.sql` through `example_01_clinic/queries/05_transactions.sql`.

## Troubleshooting
- `Access denied` when loading CSVs: ensure files are copied into `/var/lib/mysql-files/clinic_generated/` and use `example_01_clinic/schema/10_load_generated.sql`.
- `secure_file_priv` errors: use the fallback `generators/clinic/output/seed_generated.sql` load command.
- Port 3306 already in use: stop the conflicting service or change the host port in `docker/docker-compose.yml`.
- Container name mismatch: if you changed it, update `docker cp` commands to match.
