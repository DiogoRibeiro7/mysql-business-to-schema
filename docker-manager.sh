#!/bin/bash

# Docker Compose Manager for MySQL Business-to-Schema Examples
# Usage: ./docker-manager.sh [command] [example]

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    echo -e "${2}${1}${NC}"
}

# Function to show usage
show_usage() {
    echo "Docker Compose Manager for MySQL Business-to-Schema"
    echo "======================================================"
    echo ""
    echo "Usage: $0 [command] [example]"
    echo ""
    echo "Commands:"
    echo "  start [example]    - Start specific example or all"
    echo "  stop [example]     - Stop specific example or all"
    echo "  restart [example]  - Restart specific example or all"
    echo "  status [example]   - Show status of containers"
    echo "  logs [example]     - Show logs for specific example"
    echo "  generate [example] - Run data generator for example"
    echo "  clean [example]    - Stop and remove containers/volumes"
    echo "  list               - List all available examples"
    echo "  ports              - Show all exposed ports"
    echo ""
    echo "Examples:"
    echo "  $0 start clinic"
    echo "  $0 generate ecommerce"
    echo "  $0 status all"
    echo "  $0 clean all"
}

# Function to get all example directories
get_examples() {
    ls -d example_*/ 2>/dev/null | sed 's/\///' | sort
}

# Function to get example name from directory
get_example_name() {
    echo "$1" | sed 's/example_[0-9]*_//'
}

# Function to start containers
start_example() {
    local example=$1

    if [ "$example" = "all" ]; then
        print_color "Starting all examples..." "$BLUE"
        for dir in $(get_examples); do
            if [ -f "$dir/docker-compose.yml" ]; then
                print_color "Starting $dir..." "$GREEN"
                (cd "$dir" && docker-compose up -d)
            fi
        done
    else
        local found=false
        for dir in $(get_examples); do
            if [[ "$dir" == *"$example"* ]] && [ -f "$dir/docker-compose.yml" ]; then
                print_color "Starting $dir..." "$GREEN"
                (cd "$dir" && docker-compose up -d)
                found=true
                break
            fi
        done

        if [ "$found" = false ]; then
            print_color "Example '$example' not found!" "$RED"
            exit 1
        fi
    fi
}

# Function to stop containers
stop_example() {
    local example=$1

    if [ "$example" = "all" ]; then
        print_color "Stopping all examples..." "$BLUE"
        for dir in $(get_examples); do
            if [ -f "$dir/docker-compose.yml" ]; then
                print_color "Stopping $dir..." "$YELLOW"
                (cd "$dir" && docker-compose down)
            fi
        done
    else
        local found=false
        for dir in $(get_examples); do
            if [[ "$dir" == *"$example"* ]] && [ -f "$dir/docker-compose.yml" ]; then
                print_color "Stopping $dir..." "$YELLOW"
                (cd "$dir" && docker-compose down)
                found=true
                break
            fi
        done

        if [ "$found" = false ]; then
            print_color "Example '$example' not found!" "$RED"
            exit 1
        fi
    fi
}

# Function to show status
show_status() {
    local example=$1

    if [ "$example" = "all" ]; then
        print_color "Status of all examples:" "$BLUE"
        for dir in $(get_examples); do
            if [ -f "$dir/docker-compose.yml" ]; then
                echo ""
                print_color "=== $dir ===" "$GREEN"
                (cd "$dir" && docker-compose ps)
            fi
        done
    else
        local found=false
        for dir in $(get_examples); do
            if [[ "$dir" == *"$example"* ]] && [ -f "$dir/docker-compose.yml" ]; then
                print_color "Status of $dir:" "$GREEN"
                (cd "$dir" && docker-compose ps)
                found=true
                break
            fi
        done

        if [ "$found" = false ]; then
            print_color "Example '$example' not found!" "$RED"
            exit 1
        fi
    fi
}

# Function to run data generator
generate_data() {
    local example=$1
    local found=false

    for dir in $(get_examples); do
        if [[ "$dir" == *"$example"* ]] && [ -f "$dir/docker-compose.yml" ]; then
            print_color "Running data generator for $dir..." "$GREEN"
            (cd "$dir" && docker-compose run --rm data_generator)
            found=true
            break
        fi
    done

    if [ "$found" = false ]; then
        print_color "Example '$example' not found!" "$RED"
        exit 1
    fi
}

# Function to clean containers and volumes
clean_example() {
    local example=$1

    if [ "$example" = "all" ]; then
        print_color "WARNING: This will remove all containers and volumes!" "$RED"
        read -p "Are you sure? (y/N): " confirm
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            for dir in $(get_examples); do
                if [ -f "$dir/docker-compose.yml" ]; then
                    print_color "Cleaning $dir..." "$YELLOW"
                    (cd "$dir" && docker-compose down -v)
                fi
            done
        fi
    else
        local found=false
        for dir in $(get_examples); do
            if [[ "$dir" == *"$example"* ]] && [ -f "$dir/docker-compose.yml" ]; then
                print_color "WARNING: This will remove containers and volumes for $dir!" "$RED"
                read -p "Are you sure? (y/N): " confirm
                if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                    print_color "Cleaning $dir..." "$YELLOW"
                    (cd "$dir" && docker-compose down -v)
                fi
                found=true
                break
            fi
        done

        if [ "$found" = false ]; then
            print_color "Example '$example' not found!" "$RED"
            exit 1
        fi
    fi
}

# Function to list all examples
list_examples() {
    print_color "Available examples:" "$BLUE"
    echo ""

    for dir in $(get_examples); do
        if [ -f "$dir/docker-compose.yml" ]; then
            local name=$(get_example_name "$dir")
            printf "  %-35s %s\n" "$dir" "($name)"
        fi
    done
}

# Function to show all exposed ports
show_ports() {
    print_color "Exposed ports for all examples:" "$BLUE"
    echo ""
    echo "Example                              | MySQL Port | phpMyAdmin | Other Services"
    echo "------------------------------------ | ---------- | ---------- | --------------"

    for dir in $(get_examples); do
        if [ -f "$dir/docker-compose.yml" ]; then
            local mysql_port=$(grep -A 2 "ports:" "$dir/docker-compose.yml" | grep "3306" | head -1 | cut -d'"' -f2 | cut -d':' -f1 || echo "N/A")
            local phpmyadmin_port=$(grep -A 5 "phpmyadmin:" "$dir/docker-compose.yml" | grep "80" | head -1 | cut -d'"' -f2 | cut -d':' -f1 || echo "N/A")

            # Check for additional services
            local other_services=""
            if grep -q "redis:" "$dir/docker-compose.yml" 2>/dev/null; then
                local redis_port=$(grep -A 5 "redis:" "$dir/docker-compose.yml" | grep "6379" | head -1 | cut -d'"' -f2 | cut -d':' -f1 || echo "")
                [ -n "$redis_port" ] && other_services="Redis:$redis_port "
            fi
            if grep -q "elasticsearch:" "$dir/docker-compose.yml" 2>/dev/null; then
                local es_port=$(grep -A 5 "elasticsearch:" "$dir/docker-compose.yml" | grep "9200" | head -1 | cut -d'"' -f2 | cut -d':' -f1 || echo "")
                [ -n "$es_port" ] && other_services="${other_services}ES:$es_port"
            fi

            printf "%-36s | %-10s | %-10s | %s\n" "$dir" "$mysql_port" "localhost:$phpmyadmin_port" "$other_services"
        fi
    done
}

# Main script logic
case "$1" in
    start)
        start_example "${2:-all}"
        ;;
    stop)
        stop_example "${2:-all}"
        ;;
    restart)
        stop_example "${2:-all}"
        start_example "${2:-all}"
        ;;
    status)
        show_status "${2:-all}"
        ;;
    logs)
        if [ -z "$2" ]; then
            print_color "Please specify an example for logs" "$RED"
            exit 1
        fi
        for dir in $(get_examples); do
            if [[ "$dir" == *"$2"* ]] && [ -f "$dir/docker-compose.yml" ]; then
                (cd "$dir" && docker-compose logs -f)
                break
            fi
        done
        ;;
    generate)
        if [ -z "$2" ]; then
            print_color "Please specify an example for data generation" "$RED"
            exit 1
        fi
        generate_data "$2"
        ;;
    clean)
        clean_example "${2:-all}"
        ;;
    list)
        list_examples
        ;;
    ports)
        show_ports
        ;;
    *)
        show_usage
        ;;
esac