#!/usr/bin/env bash
set -euo pipefail

echo "Running local CI checks..."

required_cmds=(python flake8 black mypy bandit safety sqlfluff docker)
for cmd in "${required_cmds[@]}"; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd"
    exit 1
  fi
done

echo "[1/2] Lint and security checks"
make lint-ci

echo "[2/2] Docker web build"
make docker-web

echo "Local CI checks completed successfully."
