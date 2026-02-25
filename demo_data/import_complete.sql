-- Complete master import script for ALL 20 schemas
-- This imports all generated demo data

-- First batch (original 3)
SOURCE clinic_db_data.sql;
SOURCE ecommerce_db_data.sql;
SOURCE iot_bins_db_data.sql;

-- Second batch (additional 9)
SOURCE import_additional.sql;

-- Third batch (remaining 8)
SOURCE import_remaining.sql;
