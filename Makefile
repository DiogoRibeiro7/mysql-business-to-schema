# Makefile for MySQL Business-to-Schema Testing

.PHONY: help install test test-unit test-integration test-e2e test-performance test-chaos test-all coverage clean docker-up docker-down lint format security-scan lint-ci ci-local docker-web

# Variables
PYTHON := python3
PIP := pip3
PYTEST := pytest
BLACK := black
FLAKE8 := flake8
MYPY := mypy
COVERAGE := coverage
DOCKER_COMPOSE := docker-compose

# Default target
help:
	@echo "MySQL Business-to-Schema Testing Commands"
	@echo "========================================="
	@echo "install          - Install all dependencies"
	@echo "test            - Run all tests"
	@echo "test-unit       - Run unit tests only"
	@echo "test-integration - Run integration tests"
	@echo "test-e2e        - Run end-to-end tests"
	@echo "test-performance - Run performance tests"
	@echo "test-chaos      - Run chaos engineering tests"
	@echo "test-smoke      - Run smoke tests (quick)"
	@echo "coverage        - Generate coverage report"
	@echo "lint            - Run code linting"
	@echo "lint-ci         - Run CI-aligned lint checks locally"
	@echo "ci-local        - Run local CI script (lint + Docker web build)"
	@echo "docker-web      - Build web-demo Docker image locally"
	@echo "format          - Format code with black"
	@echo "security-scan   - Run security scanning"
	@echo "docker-up       - Start test containers"
	@echo "docker-down     - Stop test containers"
	@echo "clean           - Clean test artifacts"

# Installation
install:
	$(PIP) install -r requirements.txt
	$(PIP) install -r test-requirements.txt
	playwright install chromium

# Docker management
docker-up:
	$(DOCKER_COMPOSE) -f docker-compose.yml up -d mysql redis kafka
	@echo "Waiting for services to be ready..."
	@sleep 10

docker-down:
	$(DOCKER_COMPOSE) -f docker-compose.yml down -v

# Test execution
test: docker-up
	$(PYTEST) tests/ -v
	@make docker-down

test-unit:
	$(PYTEST) tests/unit/ -v -m unit

test-integration: docker-up
	$(PYTEST) tests/integration/ -v -m integration
	@make docker-down

test-e2e: docker-up
	$(PYTEST) tests/e2e/ -v -m e2e
	@make docker-down

test-performance: docker-up
	$(PYTEST) tests/performance/ -v -m performance
	@make docker-down

test-chaos: docker-up
	$(PYTEST) tests/chaos/ -v -m chaos
	@make docker-down

test-smoke:
	$(PYTEST) tests/ -v -m smoke --maxfail=1

test-regression:
	$(PYTEST) tests/ -v -m regression

# Parallel test execution
test-parallel: docker-up
	$(PYTEST) tests/ -v -n auto
	@make docker-down

# Test with coverage
test-with-coverage: docker-up
	$(PYTEST) tests/ --cov=. --cov-report=term-missing --cov-report=html
	@echo "Coverage report generated in htmlcov/index.html"
	@make docker-down

# Coverage
coverage:
	$(COVERAGE) run -m pytest tests/
	$(COVERAGE) report
	$(COVERAGE) html
	@echo "Coverage report generated in htmlcov/index.html"

coverage-xml:
	$(COVERAGE) xml -o coverage.xml

# Code quality
lint:
	$(FLAKE8) . --count --select=E9,F63,F7,F82 --show-source --statistics
	$(FLAKE8) . --count --exit-zero --max-complexity=25 --max-line-length=200 --statistics
	$(MYPY) . --ignore-missing-imports

format:
	$(BLACK) . --line-length=100 --skip-string-normalization

format-check:
	$(BLACK) . --line-length=100 --skip-string-normalization --check

# Security scanning
security-scan:
	pip install safety bandit
	safety check
	bandit -r . -f json -o bandit-report.json

# Performance profiling
profile-tests:
	$(PYTEST) tests/performance/ --profile --profile-svg
	@echo "Profile saved as prof/combined.svg"

# Load testing
load-test:
	locust -f tests/performance/test_load.py --headless -u 100 -r 10 -t 60s --host=http://localhost:3001

# Generate test report
test-report:
	$(PYTEST) tests/ --html=report.html --self-contained-html
	@echo "Test report generated: report.html"

# Allure reporting
allure-test:
	$(PYTEST) tests/ --alluredir=allure-results
	allure serve allure-results

# Clean up
clean:
	find . -type f -name "*.pyc" -delete
	find . -type d -name "__pycache__" -delete
	find . -type d -name ".pytest_cache" -delete
	find . -type d -name ".coverage" -delete
	find . -type d -name "htmlcov" -delete
	find . -type d -name "allure-results" -delete
	find . -type f -name ".coverage" -delete
	find . -type f -name "coverage.xml" -delete
	find . -type f -name "report.html" -delete
	find . -type f -name "*.log" -delete
	rm -rf prof/

# Continuous Integration targets
ci-test:
	$(PYTEST) tests/ -v -m "not chaos and not slow" --junitxml=test-results.xml

ci-coverage:
	$(PYTEST) tests/ --cov=. --cov-report=xml --cov-report=term

# Development helpers
watch:
	ptw -- -v tests/unit/

debug-test:
	$(PYTEST) tests/ -v --pdb --pdbcls=IPython.terminal.debugger:TerminalPdb

# Performance baseline
baseline:
	$(PYTEST) tests/performance/ -v --benchmark-save=baseline

compare-baseline:
	$(PYTEST) tests/performance/ -v --benchmark-compare=baseline

# Database migrations testing
test-migrations: docker-up
	$(PYTHON) scripts/test_migrations.py
	@make docker-down

# Contract testing
test-contracts:
	$(PYTEST) tests/contracts/ -v

# Specific test file
test-file:
	@read -p "Enter test file path: " filepath; \
	$(PYTEST) $$filepath -v

# Run tests matching pattern
test-match:
	@read -p "Enter test pattern: " pattern; \
	$(PYTEST) tests/ -v -k "$$pattern"

# Generate test data
generate-test-data:
	$(PYTHON) scripts/generate_test_data.py

# Validate schemas
validate-schemas:
	$(PYTHON) scripts/validate_schemas.py

# Full test suite with all checks
test-all: format-check lint security-scan test coverage
	@echo "All tests and checks completed successfully!"

# Development setup
dev-setup: install docker-up
	@echo "Development environment ready!"

# Quick check before commit
pre-commit: format lint test-unit
	@echo "Pre-commit checks passed!"

# CI-aligned checks from .github/workflows/main.yml
lint-ci:
	$(FLAKE8) . --count --select=E9,F63,F7,F82 --show-source --statistics
	$(FLAKE8) . --count --exit-zero --max-complexity=25 --max-line-length=200 --statistics
	$(BLACK) --check generators/ analytics/ cdc/ ml/
	$(MYPY) generators/ --ignore-missing-imports
	bandit -r generators/ analytics/ cdc/ ml/ -f json -o bandit-report.json || true
	safety check --json > safety-report.json || true
	sqlfluff lint --dialect mysql $$(find . -name "*.sql" -type f \
		! -path "./demo_data/*" \
		! -path "./data-pipeline/*" \
		! -path "./cdc/ksql/*" \
		! -path "./streaming/ksql/*" \
		! -path "./migrations/*" \
		! -path "./scripts/docker-init/*" \
		! -path "./*/schema_postgres/*" \
		! -path "./generators/*/output/*" \
		! -path "./generators/*/generators/*/output/*" \
		! -path "./example_*/*")

docker-web:
	docker build -t web-demo:local -f web-demo/Dockerfile web-demo

ci-local:
	./scripts/ci_local.sh
