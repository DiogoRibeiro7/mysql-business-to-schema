#!/bin/bash

# ========================================================================
# Update all examples with standardized Docker Compose configuration
# ========================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DOCKER_DIR="$SCRIPT_DIR"

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to get all example directories
get_examples() {
    find "$PROJECT_ROOT" -maxdepth 1 -type d -name "example_*" -exec basename {} \; | sort
}

# Function to get example name from directory
get_example_name() {
    local dir=$1
    echo "$dir" | sed 's/example_[0-9]*[a-z]*_//'
}

# Function to update docker-compose.yml for an example
update_docker_compose() {
    local example=$1
    local example_dir="$PROJECT_ROOT/$example"
    local example_name=$(get_example_name "$example")

    print_color "$BLUE" "Updating $example..."

    # Backup existing docker-compose.yml if it exists
    if [ -f "$example_dir/docker-compose.yml" ]; then
        cp "$example_dir/docker-compose.yml" "$example_dir/docker-compose.yml.backup"
        print_color "$YELLOW" "  → Backed up existing docker-compose.yml"
    fi

    # Copy standard docker-compose.yml
    cp "$DOCKER_DIR/docker-compose.standard.yml" "$example_dir/docker-compose.yml"

    # Create .env file
    cat > "$example_dir/.env" <<EOF
# Docker Compose Environment Variables for $example
COMPOSE_PROJECT_NAME=$example_name
EXAMPLE_NAME=$example_name

# MySQL Configuration
MYSQL_ROOT_PASSWORD=root
MYSQL_DATABASE=${example_name}_db
MYSQL_USER=app_user
MYSQL_PASSWORD=app_pass
MYSQL_PORT=3306

# Database Management Tools
PHPMYADMIN_PORT=8080
ADMINER_PORT=8081

# Data Generator
GENERATOR_MODE=test
GENERATOR_SEED=42
GENERATOR_SCALE=small

# Cache
REDIS_PORT=6379
EOF

    print_color "$GREEN" "  ✓ Updated docker-compose.yml"
    print_color "$GREEN" "  ✓ Created .env file"

    # Create necessary directories
    mkdir -p "$example_dir/backups"
    mkdir -p "$example_dir/data"

    # Create .gitignore for Docker-related files
    cat > "$example_dir/.gitignore" <<EOF
# Docker
.env
*.backup
backups/*.sql
data/*.csv
data/*.json

# Docker volumes
mysql_data/
redis_data/
EOF

    print_color "$GREEN" "  ✓ Created necessary directories"
}

# Function to create monitoring configuration
create_monitoring_config() {
    local example=$1
    local example_dir="$PROJECT_ROOT/$example"
    local example_name=$(get_example_name "$example")

    mkdir -p "$example_dir/monitoring"

    # Create Prometheus configuration
    cat > "$example_dir/monitoring/prometheus.yml" <<EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'mysql'
    static_configs:
      - targets: ['mysql_exporter:9104']
        labels:
          instance: '${example_name}_mysql'

  - job_name: 'redis'
    static_configs:
      - targets: ['redis:6379']
        labels:
          instance: '${example_name}_redis'
EOF

    print_color "$GREEN" "  ✓ Created monitoring configuration"
}

# Function to update all examples
update_all() {
    local count=0
    local total=$(get_examples | wc -l)

    print_color "$GREEN" "=========================================="
    print_color "$GREEN" "Updating Docker Compose for all examples"
    print_color "$GREEN" "=========================================="
    echo ""

    for example in $(get_examples); do
        count=$((count + 1))
        print_color "$BLUE" "[$count/$total] Processing $example"

        update_docker_compose "$example"

        # Optionally create monitoring config
        if [ "$1" == "--with-monitoring" ]; then
            create_monitoring_config "$example"
        fi

        echo ""
    done

    print_color "$GREEN" "=========================================="
    print_color "$GREEN" "✓ Updated $count examples successfully!"
    print_color "$GREEN" "=========================================="
}

# Function to validate Docker Compose files
validate_all() {
    local errors=0

    print_color "$BLUE" "Validating Docker Compose files..."
    echo ""

    for example in $(get_examples); do
        local example_dir="$PROJECT_ROOT/$example"

        if [ -f "$example_dir/docker-compose.yml" ]; then
            cd "$example_dir"
            if docker-compose config >/dev/null 2>&1; then
                print_color "$GREEN" "  ✓ $example: Valid"
            else
                print_color "$RED" "  ✗ $example: Invalid"
                errors=$((errors + 1))
            fi
        else
            print_color "$YELLOW" "  ⚠ $example: No docker-compose.yml"
        fi
    done

    echo ""
    if [ $errors -eq 0 ]; then
        print_color "$GREEN" "✓ All configurations are valid!"
    else
        print_color "$RED" "✗ Found $errors invalid configurations"
        return 1
    fi
}

# Function to show help
show_help() {
    echo "Update Docker Compose configurations for all examples"
    echo ""
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  update              Update all examples with standard config"
    echo "  update-with-monitoring  Update with monitoring support"
    echo "  validate            Validate all Docker Compose files"
    echo "  restore             Restore from backups"
    echo "  help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 update"
    echo "  $0 update-with-monitoring"
    echo "  $0 validate"
}

# Main logic
main() {
    local command="${1:-update}"

    case $command in
        update)
            update_all
            ;;
        update-with-monitoring)
            update_all "--with-monitoring"
            ;;
        validate)
            validate_all
            ;;
        restore)
            print_color "$YELLOW" "Restoring from backups..."
            for example in $(get_examples); do
                local example_dir="$PROJECT_ROOT/$example"
                if [ -f "$example_dir/docker-compose.yml.backup" ]; then
                    mv "$example_dir/docker-compose.yml.backup" "$example_dir/docker-compose.yml"
                    print_color "$GREEN" "  ✓ Restored $example"
                fi
            done
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_color "$RED" "Unknown command: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi