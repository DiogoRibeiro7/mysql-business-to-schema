# MySQL Business-to-Schema

<p align="center">
  <img src="https://github.com/diogoribeiro7/mysql-business-to-schema/actions/workflows/schema-testing.yml/badge.svg" alt="Schema Testing" />
  <img src="https://github.com/diogoribeiro7/mysql-business-to-schema/actions/workflows/code-quality.yml/badge.svg" alt="Code Quality" />
  <img src="https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/diogoribeiro7/mysql-business-to-schema/main/badges/examples.json" alt="Examples" />
  <img src="https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/diogoribeiro7/mysql-business-to-schema/main/badges/generators_foldered.json" alt="Generators (foldered)" />
  <img src="https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/diogoribeiro7/mysql-business-to-schema/main/badges/generators_scripts.json" alt="Generators (scripts)" />
  <img src="https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/diogoribeiro7/mysql-business-to-schema/main/badges/generators_coverage.json" alt="Generator coverage" />
  <img src="https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/diogoribeiro7/mysql-business-to-schema/main/badges/tables.json" alt="Tables" />
  <img src="https://img.shields.io/badge/MySQL-8.0%2B-orange" alt="MySQL 8.0+" />
  <img src="https://img.shields.io/badge/Python-3.10%2B-blue" alt="Python 3.10+" />
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License: MIT" />
</p>

Production-oriented MySQL schemas that map real business domains to concrete, runnable databases. This repo includes 21 examples, a web interface for browsing and analysis, data generators, and CI workflows that validate schemas against MySQL 8.0 and 8.1.

## Repo Snapshot (Current State)

- **21 examples** under `example_*/`
- **11 foldered generators** (with `generate.py` + `config.yaml`)
- **6 standalone generator scripts** in `generators/`
- **485 tables** across all examples (counted from `schema/*.sql`)
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
| 12 | [Real Estate](example_12_real_estate/) | Real Estate | 29 | ⚪ none |
| 13 | [Event Ticketing](example_13_event_ticketing/) | Entertainment | 26 | ⚪ none |
| 14 | [Logistics](example_14_logistics/) | Logistics | 24 | ✅ foldered |
| 15 | [Education](example_15_education/) | Education | 33 | 🟡 script (`generators/education/generator.py`) |
| 16 | [Cryptocurrency](example_16_cryptocurrency/) | Finance | 14 | ⚪ none |
| 16b | [Crypto Exchange](example_16_cryptocurrency_exchange/) | Finance | 17 | 🟡 script (`generators/cryptocurrency_exchange_generator.py`) |
| 17 | [Food Delivery](example_17_food_delivery/) | Delivery | 21 | 🟡 script (`generators/food_delivery_generator.py`) |
| 18 | [Gaming Platform](example_18_gaming_platform/) | Gaming | 25 | 🟡 script (`generators/gaming_platform_generator.py`) |
| 19 | [Insurance](example_19_insurance/) | Insurance | 20 | 🟡 script (`generators/insurance_generator.py`) |
| 20 | [Hotel Chain](example_20_hotel_chain/) | Hospitality | 20 | 🟡 script (`generators/hotel_chain_generator.py`) |

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

## CI/CD

Workflows are split for faster feedback and smaller jobs:

- `sql-validation.yml`
- `schema-testing.yml` (MySQL 8.0 + 8.1)
- `tools-testing.yml`
- `web-interface.yml`
- `security-scan.yml`
- `docs-check.yml`
- `code-quality.yml`

Note: some examples still require MySQL 8.1 alignment. Check the latest `test_report_*.txt` in the repo root for current status.

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
https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/diogoribeiro7/mysql-business-to-schema/main/badges/<file>.json
```

The workflow runs on every push to `main`, on a daily schedule, and via manual dispatch.

## Repo Layout

```
mysql-business-to-schema/
├── example_*/           # 21 database examples
│   ├── schema/          # SQL schemas
│   ├── queries/         # Sample queries
│   └── README.md        # Example documentation
├── generators/          # Data generators and runner
├── web_interface/       # Flask app + analytics
├── tools/               # Validation and testing tools
└── .github/workflows/   # CI workflows
```

## Contributing

See `CONTRIBUTING.md`.

## License

MIT. See `LICENSE`.
