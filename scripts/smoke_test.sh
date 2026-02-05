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

cd "$root_dir"

echo "[1/5] Generating clinic data..."
python generators/clinic/generate.py --config generators/clinic/config.yaml

output_dir="$root_dir/generators/clinic/output"
if [[ ! -d "$output_dir" ]]; then
  echo "Output directory not found: $output_dir" >&2
  exit 1
fi

for f in patients.csv doctors.csv appointments.csv invoices.csv payments.csv; do
  if [[ ! -f "$output_dir/$f" ]]; then
    echo "Missing $f in $output_dir" >&2
    exit 1
  fi
done

echo "[2/5] Starting MySQL container..."
docker compose -f "$compose_file" up -d

echo "[3/5] Loading schema..."
docker compose -f "$compose_file" exec -T mysql mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" < "$root_dir/example_01_clinic/schema/00_create_database.sql"
docker compose -f "$compose_file" exec -T mysql mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" -D "$MYSQL_DATABASE" < "$root_dir/example_01_clinic/schema/01_tables.sql"
docker compose -f "$compose_file" exec -T mysql mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" -D "$MYSQL_DATABASE" < "$root_dir/example_01_clinic/schema/02_constraints.sql"
docker compose -f "$compose_file" exec -T mysql mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" -D "$MYSQL_DATABASE" < "$root_dir/example_01_clinic/schema/03_indexes.sql"

# Copy CSVs into container and load
docker compose -f "$compose_file" exec -T mysql mkdir -p /var/lib/mysql-files/clinic_generated > /dev/null
for f in patients.csv doctors.csv appointments.csv invoices.csv payments.csv; do
  docker cp "$output_dir/$f" mysql_business_to_schema:/var/lib/mysql-files/clinic_generated/
done

docker compose -f "$compose_file" exec -T mysql mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" -D "$MYSQL_DATABASE" < "$root_dir/example_01_clinic/schema/10_load_generated.sql"

echo "[4/5] Running sanity queries..."
patients=$(docker compose -f "$compose_file" exec -T mysql mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" -D "$MYSQL_DATABASE" -N -e "SELECT COUNT(*) FROM patients;")
appointments=$(docker compose -f "$compose_file" exec -T mysql mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" -D "$MYSQL_DATABASE" -N -e "SELECT COUNT(*) FROM appointments;")

if [[ "$patients" -le 0 || "$appointments" -le 0 ]]; then
  echo "Sanity checks failed: patients=$patients appointments=$appointments" >&2
  exit 1
fi

echo "[5/5] Smoke test passed. patients=$patients appointments=$appointments"
