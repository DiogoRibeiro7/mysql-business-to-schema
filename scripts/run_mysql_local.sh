#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
compose_file="$root_dir/docker/docker-compose.yml"

load_env_file() {
  local env_file="$1"
  if [[ -f "$env_file" ]]; then
    while IFS='=' read -r key value; do
      [[ -z "$key" || "$key" =~ ^# ]] && continue
      value="${value%$'\r'}"
      export "$key=$value"
    done < "$env_file"
  fi
}

load_env_file "$root_dir/.env"
load_env_file "$root_dir/.env.example"

: "${MYSQL_ROOT_PASSWORD:=changeme_local}"
: "${MYSQL_DATABASE:=clinic}"

docker compose -f "$compose_file" up -d

echo "MySQL is running."
echo "Host: localhost"
echo "Port: 3306"
echo "User: root"
echo "Password: ${MYSQL_ROOT_PASSWORD}"
echo "Database: ${MYSQL_DATABASE}"
echo ""
echo "Opening MySQL shell..."
docker compose -f "$compose_file" exec mysql mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" -D "${MYSQL_DATABASE}"
