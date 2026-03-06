#!/bin/bash

# ========================================================================
# Test Docker Setup for MySQL Business-to-Schema
# ========================================================================
# This script tests the Docker configuration for each example

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEST_RESULTS=()

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to test MySQL connection
test_mysql_connection() {
    local container=$1
    local max_attempts=30
    local attempt=0

    while [ $attempt -lt $max_attempts ]; do
        if docker exec "$container" mysqladmin ping -h localhost -u root -proot >/dev/null 2>&1; then
            return 0
        fi
        attempt=$((attempt + 1))
        sleep 2
    done

    return 1
}

# Function to test data generation
test_data_generation() {
    local example=$1
    local example_dir="$PROJECT_ROOT/$example"
    local example_name=$(echo "$example" | sed 's/example_[0-9]*[a-z]*_//')

    cd "$example_dir"

    # Check if generator exists
    if [ -d "../generators/$example_name" ]; then
        if docker-compose --profile generate up generator --exit-code-from generator >/dev/null 2>&1; then
            return 0
        fi
    fi

    return 1
}

# Function to test an example
test_example() {
    local example=$1
    local example_dir="$PROJECT_ROOT/$example"
    local example_name=$(echo "$example" | sed 's/example_[0-9]*[a-z]*_//')

    print_color "$BLUE" "\nTesting $example..."

    # Check if docker-compose.yml exists
    if [ ! -f "$example_dir/docker-compose.yml" ]; then
        print_color "$RED" "  ✗ No docker-compose.yml found"
        TEST_RESULTS+=("$example:FAIL:No docker-compose.yml")
        return 1
    fi

    cd "$example_dir"

    # Validate configuration
    if ! docker-compose config >/dev/null 2>&1; then
        print_color "$RED" "  ✗ Invalid docker-compose.yml"
        TEST_RESULTS+=("$example:FAIL:Invalid configuration")
        return 1
    fi
    print_color "$GREEN" "  ✓ Configuration valid"

    # Start containers
    print_color "$YELLOW" "  → Starting containers..."
    if ! docker-compose up -d >/dev/null 2>&1; then
        print_color "$RED" "  ✗ Failed to start containers"
        TEST_RESULTS+=("$example:FAIL:Cannot start containers")
        return 1
    fi
    print_color "$GREEN" "  ✓ Containers started"

    # Wait for MySQL to be ready
    print_color "$YELLOW" "  → Waiting for MySQL..."
    if test_mysql_connection "${example_name}_mysql"; then
        print_color "$GREEN" "  ✓ MySQL is ready"
    else
        print_color "$RED" "  ✗ MySQL not responding"
        TEST_RESULTS+=("$example:FAIL:MySQL not ready")
        docker-compose down >/dev/null 2>&1
        return 1
    fi

    # Test phpMyAdmin
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200\|302"; then
        print_color "$GREEN" "  ✓ phpMyAdmin accessible"
    else
        print_color "$YELLOW" "  ⚠ phpMyAdmin not accessible"
    fi

    # Test data generation (optional)
    if [ "$2" == "--with-generation" ]; then
        print_color "$YELLOW" "  → Testing data generation..."
        if test_data_generation "$example"; then
            print_color "$GREEN" "  ✓ Data generation successful"
        else
            print_color "$YELLOW" "  ⚠ Data generation failed or not available"
        fi
    fi

    # Clean up
    print_color "$YELLOW" "  → Cleaning up..."
    docker-compose down >/dev/null 2>&1
    print_color "$GREEN" "  ✓ Cleaned up"

    TEST_RESULTS+=("$example:PASS:All tests passed")
    return 0
}

# Function to run all tests
run_all_tests() {
    local test_mode="${1:-basic}"
    local examples=($(find "$PROJECT_ROOT" -maxdepth 1 -type d -name "example_*" -exec basename {} \; | sort))
    local total=${#examples[@]}
    local passed=0
    local failed=0

    print_color "$GREEN" "=========================================="
    print_color "$GREEN" "Docker Setup Test Suite"
    print_color "$GREEN" "=========================================="
    print_color "$BLUE" "Testing $total examples"
    print_color "$BLUE" "Mode: $test_mode"
    echo ""

    for i in "${!examples[@]}"; do
        local example="${examples[$i]}"
        local num=$((i + 1))

        print_color "$BLUE" "[$num/$total] $example"

        if [ "$test_mode" == "full" ]; then
            if test_example "$example" "--with-generation"; then
                passed=$((passed + 1))
            else
                failed=$((failed + 1))
            fi
        else
            if test_example "$example"; then
                passed=$((passed + 1))
            else
                failed=$((failed + 1))
            fi
        fi
    done

    # Print summary
    echo ""
    print_color "$GREEN" "=========================================="
    print_color "$GREEN" "Test Results Summary"
    print_color "$GREEN" "=========================================="

    for result in "${TEST_RESULTS[@]}"; do
        IFS=':' read -r example status message <<< "$result"
        if [ "$status" == "PASS" ]; then
            print_color "$GREEN" "  ✓ $example: $message"
        else
            print_color "$RED" "  ✗ $example: $message"
        fi
    done

    echo ""
    print_color "$BLUE" "Total: $total examples"
    print_color "$GREEN" "Passed: $passed"
    print_color "$RED" "Failed: $failed"

    if [ $failed -eq 0 ]; then
        print_color "$GREEN" "\n✓ All tests passed!"
        return 0
    else
        print_color "$RED" "\n✗ Some tests failed"
        return 1
    fi
}

# Function to test specific example
test_single() {
    local example=$1

    if [ ! -d "$PROJECT_ROOT/$example" ]; then
        print_color "$RED" "Example not found: $example"
        exit 1
    fi

    test_example "$example" "--with-generation"

    # Print result
    for result in "${TEST_RESULTS[@]}"; do
        IFS=':' read -r ex status message <<< "$result"
        if [ "$ex" == "$example" ]; then
            if [ "$status" == "PASS" ]; then
                print_color "$GREEN" "\n✓ Test passed: $message"
            else
                print_color "$RED" "\n✗ Test failed: $message"
                exit 1
            fi
        fi
    done
}

# Function to show help
show_help() {
    echo "Test Docker Setup for MySQL Business-to-Schema"
    echo ""
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  all         Test all examples (basic)"
    echo "  full        Test all examples with data generation"
    echo "  single      Test a specific example"
    echo "  help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 all"
    echo "  $0 full"
    echo "  $0 single example_01_clinic"
}

# Main logic
main() {
    local command="${1:-all}"

    # Check if Docker is running
    if ! docker info >/dev/null 2>&1; then
        print_color "$RED" "Error: Docker is not running"
        exit 1
    fi

    case $command in
        all)
            run_all_tests "basic"
            ;;
        full)
            run_all_tests "full"
            ;;
        single)
            if [ -z "$2" ]; then
                print_color "$RED" "Error: Please specify an example"
                show_help
                exit 1
            fi
            test_single "$2"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_color "$RED" "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi