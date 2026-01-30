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
python generators/clinic/generate.py --config generators/clinic/config.yaml --out generators/clinic/output
```

Bash (macOS/Linux/Git Bash):
```bash
python generators/clinic/generate.py --config generators/clinic/config.yaml --out generators/clinic/output
```

## Learning path
Work through these in order:
- docs/00-business-problem.md
- docs/01-requirements.md
- docs/02-data-model.md
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
