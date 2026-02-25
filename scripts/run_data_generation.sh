#!/bin/bash

# MySQL Business-to-Schema Data Generation Script
# Generates test data for all schemas

set -e

echo "=========================================="
echo "MySQL Business-to-Schema Data Generation"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MYSQL_HOST=${MYSQL_HOST:-localhost}
MYSQL_USER=${MYSQL_USER:-root}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-root}
MYSQL_PORT=${MYSQL_PORT:-3306}

# Parse arguments
RECORDS_PER_TABLE=1000
CLEAN_FIRST=false
PARALLEL=false
SCHEMAS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --records)
            RECORDS_PER_TABLE="$2"
            shift 2
            ;;
        --clean)
            CLEAN_FIRST=true
            shift
            ;;
        --parallel)
            PARALLEL=true
            shift
            ;;
        --schemas)
            SCHEMAS="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}Configuration:${NC}"
echo "  - MySQL Host: $MYSQL_HOST:$MYSQL_PORT"
echo "  - Records per table: $RECORDS_PER_TABLE"
echo "  - Clean existing data: $CLEAN_FIRST"
echo "  - Parallel generation: $PARALLEL"
echo ""

# Check MySQL connection
echo -e "${YELLOW}Checking MySQL connection...${NC}"
if mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SELECT 1" &>/dev/null; then
    echo -e "${GREEN}✓ MySQL connection successful${NC}"
else
    echo -e "${RED}✗ Cannot connect to MySQL${NC}"
    exit 1
fi

# List available schemas
echo -e "\n${BLUE}Available Schemas:${NC}"
mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SHOW DATABASES" | grep -E "_db$" | while read schema; do
    echo "  - $schema"
done

# Ensure schemas exist
echo -e "\n${YELLOW}Creating schemas if not exist...${NC}"
for i in {01..20}; do
    example_dir=$(find . -maxdepth 1 -type d -name "example_${i}_*" | head -n 1)
    if [[ -n "$example_dir" && -f "$example_dir/schema/00_create_database.sql" ]]; then
        mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" < "$example_dir/schema/00_create_database.sql" 2>/dev/null || true

        # Create tables
        if [[ -f "$example_dir/schema/01_tables.sql" ]]; then
            schema_name=$(grep "CREATE DATABASE" "$example_dir/schema/00_create_database.sql" | sed -E 's/.*`([^`]+)`.*/\1/')
            mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$schema_name" < "$example_dir/schema/01_tables.sql" 2>/dev/null || true
        fi
    fi
done

# Clean data if requested
if [ "$CLEAN_FIRST" = true ]; then
    echo -e "\n${YELLOW}Cleaning existing data...${NC}"
    mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SHOW DATABASES" | grep -E "_db$" | while read schema; do
        echo -e "  Cleaning $schema..."
        mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$schema" -e "
            SET FOREIGN_KEY_CHECKS = 0;
            SELECT CONCAT('TRUNCATE TABLE ', table_name, ';')
            FROM information_schema.tables
            WHERE table_schema = '$schema';
            SET FOREIGN_KEY_CHECKS = 1;
        " | grep "TRUNCATE" | mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$schema" 2>/dev/null || true
    done
fi

# Run Python generator
echo -e "\n${YELLOW}Starting data generation...${NC}"

# Build command
CMD="python generators/generate_all_data.py --records $RECORDS_PER_TABLE"

if [ "$CLEAN_FIRST" = true ]; then
    CMD="$CMD --clean"
fi

if [ "$PARALLEL" = true ]; then
    CMD="$CMD --parallel"
fi

if [ -n "$SCHEMAS" ]; then
    CMD="$CMD --schemas $SCHEMAS"
fi

# Execute generator
echo "Running: $CMD"
$CMD

# Verify data generation
echo -e "\n${BLUE}Verifying generated data...${NC}"
mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "
    SELECT
        table_schema AS 'Schema',
        COUNT(*) AS 'Tables',
        SUM(table_rows) AS 'Total Rows',
        ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)'
    FROM information_schema.tables
    WHERE table_schema LIKE '%_db'
    GROUP BY table_schema
    ORDER BY table_schema;
"

# Summary
echo -e "\n${GREEN}=========================================="
echo -e "Data Generation Complete!"
echo -e "==========================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Verify data: mysql -u $MYSQL_USER -p -e 'USE clinic_db; SELECT COUNT(*) FROM patients;'"
echo "  2. Run tests: python test_system.py"
echo "  3. Start services: docker-compose up -d"
echo ""