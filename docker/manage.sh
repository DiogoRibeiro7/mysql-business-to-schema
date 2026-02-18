#!/bin/bash

# MySQL Business-to-Schema Docker Management Script
# Usage: ./manage.sh [command] [example]

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

function print_usage() {
    echo "MySQL Business-to-Schema Docker Manager"
    echo ""
    echo "Usage: $0 [command] [example]"
    echo ""
    echo "Commands:"
    echo "  up [example]      Start services for an example"
    echo "  down [example]    Stop services for an example"
    echo "  restart [example] Restart services for an example"
    echo "  logs [example]    Show logs for an example"
    echo "  generate [example] Run data generator for an example"
    echo "  status [example]  Show status of services"
    echo "  clean [example]   Remove containers and volumes"
    echo "  list              List all available examples"
    echo "  all-up            Start all examples (requires lots of resources!)"
    echo "  all-down          Stop all examples"
    echo ""
    echo "Examples:"
    echo "  $0 up ecommerce"
    echo "  $0 generate fintech"
    echo "  $0 logs clinic"
    echo ""
}

function validate_example() {
    local example=$1
    local valid=false

    for e in "${EXAMPLES[@]}"; do
        if [[ "$e" == *"$example"* ]]; then
            valid=true
            EXAMPLE_DIR="$e"
            break
        fi
    done

    if [ "$valid" = false ]; then
        echo -e "${RED}Error: Invalid example '$example'${NC}"
        echo "Available examples:"
        for e in "${EXAMPLES[@]}"; do
            echo "  - ${e#example_*}"
        done
        exit 1
    fi
}

function check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Error: Docker is not installed${NC}"
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}Error: Docker Compose is not installed${NC}"
        exit 1
    fi
}

function up_example() {
    local example=$1
    validate_example "$example"

    echo -e "${GREEN}Starting $EXAMPLE_DIR...${NC}"
    cd "$PROJECT_ROOT/$EXAMPLE_DIR"

    if [ ! -f "docker-compose.yml" ]; then
        echo -e "${YELLOW}Warning: No docker-compose.yml found for $EXAMPLE_DIR${NC}"
        echo "Creating from template..."
        create_docker_compose "$EXAMPLE_DIR"
    fi

    docker-compose up -d
    echo -e "${GREEN}✓ $EXAMPLE_DIR is running${NC}"
    echo ""
    echo "Access points:"
    echo "  MySQL: localhost:3306"
    echo "  phpMyAdmin: http://localhost:8080"
}

function down_example() {
    local example=$1
    validate_example "$example"

    echo -e "${YELLOW}Stopping $EXAMPLE_DIR...${NC}"
    cd "$PROJECT_ROOT/$EXAMPLE_DIR"

    if [ -f "docker-compose.yml" ]; then
        docker-compose down
        echo -e "${GREEN}✓ $EXAMPLE_DIR stopped${NC}"
    else
        echo -e "${YELLOW}No docker-compose.yml found for $EXAMPLE_DIR${NC}"
    fi
}

function generate_data() {
    local example=$1
    validate_example "$example"

    echo -e "${GREEN}Generating data for $EXAMPLE_DIR...${NC}"
    cd "$PROJECT_ROOT/$EXAMPLE_DIR"

    if [ ! -f "docker-compose.yml" ]; then
        echo -e "${RED}Error: No docker-compose.yml found${NC}"
        exit 1
    fi

    # Check if MySQL is running
    if ! docker-compose ps | grep -q "mysql.*Up"; then
        echo -e "${YELLOW}MySQL is not running. Starting it now...${NC}"
        docker-compose up -d mysql
        echo "Waiting for MySQL to be ready..."
        sleep 10
    fi

    # Run the generator
    docker-compose run --rm data_generator
    echo -e "${GREEN}✓ Data generation complete${NC}"
}

function show_logs() {
    local example=$1
    validate_example "$example"

    cd "$PROJECT_ROOT/$EXAMPLE_DIR"
    docker-compose logs -f
}

function show_status() {
    local example=$1

    if [ -z "$example" ]; then
        echo "Status of all examples:"
        echo "----------------------"
        for e in "${EXAMPLES[@]}"; do
            cd "$PROJECT_ROOT/$e" 2>/dev/null || continue
            if [ -f "docker-compose.yml" ]; then
                status=$(docker-compose ps --services --filter "status=running" 2>/dev/null | wc -l)
                if [ "$status" -gt 0 ]; then
                    echo -e "  ${e#example_*}: ${GREEN}Running ($status services)${NC}"
                else
                    echo -e "  ${e#example_*}: ${RED}Stopped${NC}"
                fi
            else
                echo -e "  ${e#example_*}: ${YELLOW}Not configured${NC}"
            fi
        done
    else
        validate_example "$example"
        cd "$PROJECT_ROOT/$EXAMPLE_DIR"
        docker-compose ps
    fi
}

function clean_example() {
    local example=$1
    validate_example "$example"

    echo -e "${RED}Warning: This will remove all containers and volumes for $EXAMPLE_DIR${NC}"
    read -p "Are you sure? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cd "$PROJECT_ROOT/$EXAMPLE_DIR"
        docker-compose down -v
        echo -e "${GREEN}✓ Cleaned $EXAMPLE_DIR${NC}"
    fi
}

function create_docker_compose() {
    local example_dir=$1
    local example_name="${example_dir#example_*}"

    cat > "$PROJECT_ROOT/$example_dir/docker-compose.yml" << EOF
version: '3.8'

services:
  mysql:
    image: mysql:8.0
    container_name: ${example_name}_mysql
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: ${example_name}_root
      MYSQL_DATABASE: ${example_name}_db
      MYSQL_USER: ${example_name}_user
      MYSQL_PASSWORD: ${example_name}_pass
    ports:
      - "3306:3306"
    volumes:
      - ./schema:/docker-entrypoint-initdb.d:ro
      - ${example_name}_mysql_data:/var/lib/mysql
    networks:
      - ${example_name}_network

  phpmyadmin:
    image: phpmyadmin:latest
    container_name: ${example_name}_phpmyadmin
    depends_on:
      - mysql
    environment:
      PMA_HOST: mysql
      PMA_USER: root
      PMA_PASSWORD: ${example_name}_root
    ports:
      - "8080:80"
    networks:
      - ${example_name}_network

  data_generator:
    build:
      context: ../generators
      dockerfile: Dockerfile
    container_name: ${example_name}_generator
    depends_on:
      - mysql
    environment:
      MYSQL_HOST: mysql
      MYSQL_DATABASE: ${example_name}_db
      MYSQL_USER: ${example_name}_user
      MYSQL_PASSWORD: ${example_name}_pass
    volumes:
      - ../generators/${example_name}:/app
    networks:
      - ${example_name}_network

volumes:
  ${example_name}_mysql_data:

networks:
  ${example_name}_network:
    driver: bridge
EOF

    echo -e "${GREEN}Created docker-compose.yml for $example_dir${NC}"
}

function list_examples() {
    echo "Available examples:"
    echo "------------------"
    for e in "${EXAMPLES[@]}"; do
        echo "  ${e#example_*}"
    done
}

# Main script logic
check_docker

case "$1" in
    up)
        up_example "$2"
        ;;
    down)
        down_example "$2"
        ;;
    restart)
        down_example "$2"
        up_example "$2"
        ;;
    logs)
        show_logs "$2"
        ;;
    generate)
        generate_data "$2"
        ;;
    status)
        show_status "$2"
        ;;
    clean)
        clean_example "$2"
        ;;
    list)
        list_examples
        ;;
    all-up)
        for e in "${EXAMPLES[@]}"; do
            up_example "${e#example_*}"
        done
        ;;
    all-down)
        for e in "${EXAMPLES[@]}"; do
            down_example "${e#example_*}"
        done
        ;;
    *)
        print_usage
        exit 1
        ;;
esac