# Normalization Exercises

This guide links all raw datasets used for normalization practice. Each example includes:
- `raw_schema.sql` (denormalized table)
- `raw_seed.csv` (sample raw data)
- `normalization_tasks.md` (exercise prompts)

## Examples

- `example_01_clinic/raw/`
- `example_02_iot_bins/raw/`
- `example_03_smart_energy/raw/`
- `example_04_ecommerce/raw/`
- `example_05_industrial_iot/raw/`
- `example_06_smart_agriculture/raw/`
- `example_07_fleet_management/raw/`
- `example_08_healthcare_iot/raw/`
- `example_09_streaming_ml/raw/`
- `example_10_fintech/raw/`
- `example_11_social_media/raw/`
- `example_12_real_estate/raw/`
- `example_13_event_ticketing/raw/`
- `example_14_logistics/raw/`
- `example_15_education/raw/`
- `example_16_cryptocurrency/raw/`
- `example_16_cryptocurrency_exchange/raw/`
- `example_17_food_delivery/raw/`
- `example_18_gaming_platform/raw/`
- `example_19_insurance/raw/`
- `example_20_hotel_chain/raw/`

## Suggested Workflow
1. Load the raw schema and data.
2. Identify repeating groups and dependencies.
3. Design a 3NF schema.
4. Implement ETL to migrate raw data.

## Load Example (generic)
```bash
# Replace <db> and <raw_table> as needed
mysql -u root -p < example_XX_name/raw/raw_schema.sql
# Load CSV with your preferred tool (mysqlimport, LOAD DATA, etc.)
```

