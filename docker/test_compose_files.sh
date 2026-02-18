#!/bin/bash

# Test all Docker Compose files for validity
# Usage: ./test_compose_files.sh

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# List of all examples
EXAMPLES=(
    "example_01_clinic"
    "example_02_iot_bins"
    "example_03_smart_energy"
    "example_04_ecommerce"
    "example_05_industrial_iot"
    "example_06_smart_agriculture"
    "example_07_fleet_management"
    "example_08_healthcare_iot"
    "example_09_streaming_ml"
    "example_10_fintech"
    "example_11_social_media"
    "example_12_real_estate"
    "example_13_event_ticketing"
    "example_14_logistics"
    "example_15_education"
)

echo "Testing Docker Compose Files"
echo "============================"
echo ""

total=0
valid=0
invalid=0

for example in "${EXAMPLES[@]}"; do
    total=$((total + 1))
    compose_file="$PROJECT_ROOT/$example/docker-compose.yml"

    if [ -f "$compose_file" ]; then
        echo -n "Testing $example... "

        # Test if docker-compose file is valid
        if docker-compose -f "$compose_file" config > /dev/null 2>&1; then
            echo -e "${GREEN}[OK]${NC}"
            valid=$((valid + 1))
        else
            echo -e "${RED}[FAIL]${NC}"
            invalid=$((invalid + 1))
            echo -e "${RED}  Error validating $compose_file${NC}"
            docker-compose -f "$compose_file" config 2>&1 | head -5
        fi
    else
        echo -e "$example... ${YELLOW}[MISSING]${NC}"
        invalid=$((invalid + 1))
    fi
done

echo ""
echo "Summary"
echo "-------"
echo -e "Total: $total"
echo -e "Valid: ${GREEN}$valid${NC}"
echo -e "Invalid: ${RED}$invalid${NC}"

if [ $invalid -eq 0 ]; then
    echo ""
    echo -e "${GREEN}All Docker Compose files are valid!${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}Some Docker Compose files have issues${NC}"
    exit 1
fi