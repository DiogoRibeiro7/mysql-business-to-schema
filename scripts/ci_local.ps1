$ErrorActionPreference = "Stop"

Write-Host "Running local CI checks..." -ForegroundColor Cyan

$required = @(
  "python",
  "flake8",
  "black",
  "mypy",
  "bandit",
  "safety",
  "sqlfluff",
  "docker"
)

foreach ($cmd in $required) {
  if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
    throw "Missing required command: $cmd"
  }
}

Write-Host "[1/2] Lint and security checks" -ForegroundColor Yellow
flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics
flake8 . --count --exit-zero --max-complexity=25 --max-line-length=200 --statistics
black --check generators/ analytics/ cdc/ ml/
mypy generators/ --ignore-missing-imports
bandit -r generators/ analytics/ cdc/ ml/ -f json -o bandit-report.json
if ($LASTEXITCODE -ne 0) { Write-Host "Bandit found issues (continuing)." -ForegroundColor DarkYellow }
safety check --json > safety-report.json
if ($LASTEXITCODE -ne 0) { Write-Host "Safety found issues (continuing)." -ForegroundColor DarkYellow }

$sqlFiles = Get-ChildItem -Recurse -File -Filter *.sql | Where-Object {
  $p = $_.FullName.Replace((Get-Location).Path + "\", "").Replace("\", "/")
  $p -notlike "demo_data/*" -and
  $p -notlike "data-pipeline/*" -and
  $p -notlike "cdc/ksql/*" -and
  $p -notlike "streaming/ksql/*" -and
  $p -notlike "migrations/*" -and
  $p -notlike "scripts/docker-init/*" -and
  $p -notlike "*/schema_postgres/*" -and
  $p -notlike "generators/*/output/*" -and
  $p -notlike "generators/*/generators/*/output/*" -and
  $p -notlike "example_*/*"
}
if ($sqlFiles.Count -gt 0) {
  sqlfluff lint --dialect mysql $sqlFiles.FullName
}

Write-Host "[2/2] Docker web build" -ForegroundColor Yellow
docker build -t web-demo:local -f web-demo/Dockerfile web-demo

Write-Host "Local CI checks completed successfully." -ForegroundColor Green
