# MySQL Business-to-Schema

<p align="center">
  <img src="https://github.com/diogoribeiro7/mysql-business-to-schema/actions/workflows/schema-testing.yml/badge.svg" alt="Schema Testing" />
  <img src="https://github.com/diogoribeiro7/mysql-business-to-schema/actions/workflows/code-quality.yml/badge.svg" alt="Code Quality" />
  <img src="https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/diogoribeiro7/mysql-business-to-schema/develop/badges/examples.json" alt="Examples" />
  <img src="https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/diogoribeiro7/mysql-business-to-schema/develop/badges/generators_foldered.json" alt="Generators (foldered)" />
  <img src="https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/diogoribeiro7/mysql-business-to-schema/develop/badges/generators_scripts.json" alt="Generators (scripts)" />
  <img src="https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/diogoribeiro7/mysql-business-to-schema/develop/badges/generators_coverage.json" alt="Generator coverage" />
  <img src="https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/diogoribeiro7/mysql-business-to-schema/develop/badges/tables.json" alt="Tables" />
  <img src="https://img.shields.io/badge/MySQL-8.0%2B-orange" alt="MySQL 8.0+" />
  <img src="https://img.shields.io/badge/Python-3.10%2B-blue" alt="Python 3.10+" />
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License: MIT" />
</p>

Production-oriented MySQL schemas that map real business domains to concrete, runnable databases. This repo includes 21 examples, a web interface for browsing and analysis, data generators, normalization exercises, and CI workflows that validate schemas against MySQL 8.0 and 8.1.

Security: See [SECURITY.md](SECURITY.md) for responsible vulnerability reporting.

## Repo Snapshot (Current State)

- **21 examples** under `example_*/` (schemas, queries, and normalization exercises)
- **Generator suite** in `generators/` (foldered generators + standalone scripts)
- **Table counts & coverage** tracked via badges and `EXAMPLES_OVERVIEW.md`
- **Poetry-based Python tooling** (`pyproject.toml`)
- **CI split by concern** under `.github/workflows/`

## Examples (Table Counts + Generator Coverage)

Generator coverage legend:
- ✅ `foldered` = `generators/<name>/generate.py` + `config.yaml`
- 🟡 `script` = standalone script in `generators/` or a generator without config
- ⚪ `none`

| # | Example | Industry | Tables | Generator |
|---|---------|----------|--------|-----------|
| 01 | [Clinic Management](example_01_clinic/) | Healthcare | 9 | ✅ foldered |
| 02 | [IoT Bins](example_02_iot_bins/) | IoT | 15 | ✅ foldered |
| 03 | [Smart Energy](example_03_smart_energy/) | Energy | 26 | ✅ foldered |
| 04 | [E-commerce](example_04_ecommerce/) | Retail | 33 | ✅ foldered |
| 05 | [Industrial IoT](example_05_industrial_iot/) | Manufacturing | 18 | ✅ foldered |
| 06 | [Smart Agriculture](example_06_smart_agriculture/) | Agriculture | 23 | ✅ foldered |
| 07 | [Fleet Management](example_07_fleet_management/) | Transportation | 23 | ✅ foldered |
| 08 | [Healthcare IoT](example_08_healthcare_iot/) | Health Tech | 25 | ✅ foldered |
| 09 | [Streaming ML](example_09_streaming_ml/) | Analytics | 33 | ✅ foldered |
| 10 | [FinTech](example_10_fintech/) | Financial | 26 | ✅ foldered |
| 11 | [Social Media](example_11_social_media/) | Social | 25 | ✅ foldered |
| 12 | [Real Estate](example_12_real_estate/) | Real Estate | 29 | ✅ foldered |
| 13 | [Event Ticketing](example_13_event_ticketing/) | Entertainment | 26 | ✅ foldered |
| 14 | [Logistics](example_14_logistics/) | Logistics | 24 | ✅ foldered |
| 15 | [Education](example_15_education/) | Education | 33 | 🟡 script (`generators/education/generator.py`) |
| 16 | [Cryptocurrency](example_16_cryptocurrency/) | Finance | 14 | ✅ foldered |
| 16b | [Crypto Exchange](example_16_cryptocurrency_exchange/) | Finance | 17 | 🟡 script (`generators/cryptocurrency_exchange_generator.py`) |
| 17 | [Food Delivery](example_17_food_delivery/) | Delivery | 21 | 🟡 script (`generators/food_delivery_generator.py`) |
| 18 | [Gaming Platform](example_18_gaming_platform/) | Gaming | 25 | 🟡 script (`generators/gaming_platform_generator.py`) |
| 19 | [Insurance](example_19_insurance/) | Insurance | 20 | 🟡 script (`generators/insurance_generator.py`) |
| 20 | [Hotel Chain](example_20_hotel_chain/) | Hospitality | 20 | 🟡 script (`generators/hotel_chain_generator.py`) |

## Example Architecture Index

Each example README now includes a Mermaid ERD section.

| Example | Domain | Architecture Diagram |
|---|---|---|
| [example_01_clinic](example_01_clinic/README.md#database-architecture-mermaid-er-diagram) | Clinic | [ERD](example_01_clinic/README.md#database-architecture-mermaid-er-diagram) |
| [example_02_iot_bins](example_02_iot_bins/README.md#database-architecture-mermaid-er-diagram) | Iot Bins | [ERD](example_02_iot_bins/README.md#database-architecture-mermaid-er-diagram) |
| [example_03_smart_energy](example_03_smart_energy/README.md#database-architecture-mermaid-er-diagram) | Smart Energy | [ERD](example_03_smart_energy/README.md#database-architecture-mermaid-er-diagram) |
| [example_04_ecommerce](example_04_ecommerce/README.md#database-architecture-mermaid-er-diagram) | Ecommerce | [ERD](example_04_ecommerce/README.md#database-architecture-mermaid-er-diagram) |
| [example_05_industrial_iot](example_05_industrial_iot/README.md#database-architecture-mermaid-er-diagram) | Industrial Iot | [ERD](example_05_industrial_iot/README.md#database-architecture-mermaid-er-diagram) |
| [example_06_smart_agriculture](example_06_smart_agriculture/README.md#database-architecture-mermaid-er-diagram) | Smart Agriculture | [ERD](example_06_smart_agriculture/README.md#database-architecture-mermaid-er-diagram) |
| [example_07_fleet_management](example_07_fleet_management/README.md#database-architecture-mermaid-er-diagram) | Fleet Management | [ERD](example_07_fleet_management/README.md#database-architecture-mermaid-er-diagram) |
| [example_08_healthcare_iot](example_08_healthcare_iot/README.md#database-architecture-mermaid-er-diagram) | Healthcare Iot | [ERD](example_08_healthcare_iot/README.md#database-architecture-mermaid-er-diagram) |
| [example_09_streaming_ml](example_09_streaming_ml/README.md#database-architecture-mermaid-er-diagram) | Streaming Ml | [ERD](example_09_streaming_ml/README.md#database-architecture-mermaid-er-diagram) |
| [example_10_fintech](example_10_fintech/README.md#database-architecture-mermaid-er-diagram) | Fintech | [ERD](example_10_fintech/README.md#database-architecture-mermaid-er-diagram) |
| [example_11_social_media](example_11_social_media/README.md#database-architecture-mermaid-er-diagram) | Social Media | [ERD](example_11_social_media/README.md#database-architecture-mermaid-er-diagram) |
| [example_12_real_estate](example_12_real_estate/README.md#database-architecture-mermaid-er-diagram) | Real Estate | [ERD](example_12_real_estate/README.md#database-architecture-mermaid-er-diagram) |
| [example_13_event_ticketing](example_13_event_ticketing/README.md#database-architecture-mermaid-er-diagram) | Event Ticketing | [ERD](example_13_event_ticketing/README.md#database-architecture-mermaid-er-diagram) |
| [example_14_logistics](example_14_logistics/README.md#database-architecture-mermaid-er-diagram) | Logistics | [ERD](example_14_logistics/README.md#database-architecture-mermaid-er-diagram) |
| [example_15_education](example_15_education/README.md#database-architecture-mermaid-er-diagram) | Education | [ERD](example_15_education/README.md#database-architecture-mermaid-er-diagram) |
| [example_16_cryptocurrency](example_16_cryptocurrency/README.md#database-architecture-mermaid-er-diagram) | Cryptocurrency | [ERD](example_16_cryptocurrency/README.md#database-architecture-mermaid-er-diagram) |
| [example_16_cryptocurrency_exchange](example_16_cryptocurrency_exchange/README.md#database-architecture-mermaid-er-diagram) | Cryptocurrency Exchange | [ERD](example_16_cryptocurrency_exchange/README.md#database-architecture-mermaid-er-diagram) |
| [example_17_food_delivery](example_17_food_delivery/README.md#database-architecture-mermaid-er-diagram) | Food Delivery | [ERD](example_17_food_delivery/README.md#database-architecture-mermaid-er-diagram) |
| [example_18_gaming_platform](example_18_gaming_platform/README.md#database-architecture-mermaid-er-diagram) | Gaming Platform | [ERD](example_18_gaming_platform/README.md#database-architecture-mermaid-er-diagram) |
| [example_19_insurance](example_19_insurance/README.md#database-architecture-mermaid-er-diagram) | Insurance | [ERD](example_19_insurance/README.md#database-architecture-mermaid-er-diagram) |
| [example_20_hotel_chain](example_20_hotel_chain/README.md#database-architecture-mermaid-er-diagram) | Hotel Chain | [ERD](example_20_hotel_chain/README.md#database-architecture-mermaid-er-diagram) |

## Normalization Exercises (Raw → Normalized)

Every example includes a `raw/` package so students can normalize from denormalized inputs:

- `raw/raw_schema.sql` defines a denormalized intake table.
- `raw/raw_seed.csv` provides a small raw dataset.
- `raw/normalization_tasks.md` describes the target entities.
- `raw/solutions/normalized_schema.sql` and `raw/solutions/etl.sql` show one possible solution.

Quick path:

```bash
# 1) Create the raw table
mysql -u root -p < example_10_fintech/raw/raw_schema.sql

# 2) Load the raw CSV (requires local_infile enabled)
mysql --local-infile=1 -u root -p fintech -e "
LOAD DATA LOCAL INFILE 'example_10_fintech/raw/raw_seed.csv'
INTO TABLE raw_transaction_feed
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '\"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;"

# 3) Apply normalized schema + ETL
mysql -u root -p < example_10_fintech/raw/solutions/normalized_schema.sql
mysql -u root -p < example_10_fintech/raw/solutions/etl.sql
```

The CI job `normalization-check.yml` verifies that every example ships the full raw exercise bundle.

## Quick Start

### Install Python deps (Poetry)

```bash
poetry install --no-root
```

### Start the web interface

```bash
poetry install --no-root --with web
poetry run python web_interface/app.py
```

### Load an example schema

```bash
# Example: IoT Bins
mysql -u root -p < example_02_iot_bins/schema/00_create_database.sql
mysql -u root -p iot_bins < example_02_iot_bins/schema/01_tables.sql
mysql -u root -p iot_bins < example_02_iot_bins/schema/02_constraints.sql
mysql -u root -p iot_bins < example_02_iot_bins/schema/03_indexes.sql
```

### Generate sample data

```bash
cd generators/iot_bins
python generate.py --config config.yaml
```

You can also drive any generator through the unified runner:

```bash
python generators/run_generators.py --list          # show available generators
python generators/run_generators.py iot_bins --test # run one in reduced-volume test mode
```

### Run tests

```bash
poetry install --no-root --with dev
poetry run pytest tests/unit/ -m unit
```

The unit tests are fast and require no database. The integration/e2e suites under `tests/` rely on Docker-based services (MySQL, Kafka, Redis) and are exercised separately in CI.

## CI/CD

Workflows are split for faster feedback and smaller jobs:

- `main.yml` (umbrella checks)
- `pr-checks.yml` (pull request gating)
- `schema-testing.yml` (MySQL 8.0 + 8.1)
- `sql-validation.yml`
- `tools-testing.yml`
- `web-interface.yml`
- `code-quality.yml`
- `docs-check.yml`
- `security.yml` and `security-scan.yml`
- `test-suite.yml`
- `normalization-check.yml`
- `badges.yml`
- `dependabot-auto-merge.yml` (auto-merges passing Dependabot PRs)

Schema tests run against MySQL 8.0 and 8.1 via `schema-testing.yml`.

## Live Badge Strategy

Badges are generated automatically via `tools/update_badges.py` and committed by `.github/workflows/badges.yml`.

Badge endpoints used in the header:
- `badges/examples.json`
- `badges/tables.json`
- `badges/generators_foldered.json`
- `badges/generators_scripts.json`
- `badges/generators_coverage.json`

Each badge is a Shields endpoint file committed to the repo and served via raw GitHub:

```
https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/diogoribeiro7/mysql-business-to-schema/develop/badges/<file>.json
```

The workflow currently runs on every push to `main`, on a daily schedule, and via manual dispatch.

## Repo Layout

```
mysql-business-to-schema/
├── example_*/           # 21 database examples
│   ├── schema/          # SQL schemas
│   ├── queries/         # Sample queries
│   ├── raw/             # Normalization exercises (raw + solutions)
│   └── README.md        # Example documentation
├── generators/          # Data generators and runner
├── web_interface/       # Flask app + analytics
├── tools/               # Validation and testing tools
└── .github/workflows/   # CI workflows
```

## Contributing

See `CONTRIBUTING.md`.

Community and support files:
- `.github/CODE_OF_CONDUCT.md`
- `SECURITY.md`
- `SUPPORT.md`
- `docs/BRANCH_PROTECTION_CHECKLIST.md`
- `docs/ISSUE_LABELS_SYNC.md`

Optional local quality gate:

```bash
pip install pre-commit
pre-commit install
pre-commit run --all-files
```

## License

MIT. See `LICENSE`.

Security disclosures: [SECURITY.md](SECURITY.md)
