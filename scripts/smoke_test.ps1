$ErrorActionPreference = 'Stop'

$rootDir = Split-Path -Parent $PSScriptRoot
$composeFile = Join-Path $rootDir 'docker/docker-compose.yml'

function Load-EnvFile {
    param([string]$Path)
    if (Test-Path $Path) {
        Get-Content $Path | ForEach-Object {
            $line = $_.Trim()
            if (-not $line -or $line.StartsWith('#')) { return }
            $parts = $line.Split('=', 2)
            if ($parts.Count -eq 2) {
                $name = $parts[0].Trim()
                $value = $parts[1].Trim()
                if ($name) { $env:$name = $value }
            }
        }
    }
}

Load-EnvFile (Join-Path $rootDir '.env')
Load-EnvFile (Join-Path $rootDir '.env.example')

if (-not $env:MYSQL_ROOT_PASSWORD) { $env:MYSQL_ROOT_PASSWORD = 'changeme_local' }
if (-not $env:MYSQL_DATABASE) { $env:MYSQL_DATABASE = 'clinic' }

Set-Location $rootDir

Write-Host "[1/5] Generating clinic data..."
python generators/clinic/generate.py --config generators/clinic/config.yaml

$outputDir = Join-Path $rootDir 'generators/clinic/output'
if (-not (Test-Path $outputDir)) {
    throw "Output directory not found: $outputDir"
}

$files = @('patients.csv', 'doctors.csv', 'appointments.csv', 'invoices.csv', 'payments.csv')
foreach ($file in $files) {
    $src = Join-Path $outputDir $file
    if (-not (Test-Path $src)) {
        throw "Missing $file in $outputDir"
    }
}

Write-Host "[2/5] Starting MySQL container..."
docker compose -f $composeFile up -d | Out-Null

Write-Host "[3/5] Loading schema..."
docker compose -f $composeFile exec -T mysql mysql -uroot -p$env:MYSQL_ROOT_PASSWORD < (Join-Path $rootDir 'example_01_clinic/schema/00_create_database.sql')
docker compose -f $composeFile exec -T mysql mysql -uroot -p$env:MYSQL_ROOT_PASSWORD -D $env:MYSQL_DATABASE < (Join-Path $rootDir 'example_01_clinic/schema/01_tables.sql')
docker compose -f $composeFile exec -T mysql mysql -uroot -p$env:MYSQL_ROOT_PASSWORD -D $env:MYSQL_DATABASE < (Join-Path $rootDir 'example_01_clinic/schema/02_constraints.sql')
docker compose -f $composeFile exec -T mysql mysql -uroot -p$env:MYSQL_ROOT_PASSWORD -D $env:MYSQL_DATABASE < (Join-Path $rootDir 'example_01_clinic/schema/03_indexes.sql')

# Copy CSVs into container and load
$containerDir = '/var/lib/mysql-files/clinic_generated'
docker compose -f $composeFile exec -T mysql mkdir -p $containerDir | Out-Null
foreach ($file in $files) {
    $src = Join-Path $outputDir $file
    docker cp $src mysql_business_to_schema:$containerDir/
}

docker compose -f $composeFile exec -T mysql mysql -uroot -p$env:MYSQL_ROOT_PASSWORD -D $env:MYSQL_DATABASE < (Join-Path $rootDir 'example_01_clinic/schema/10_load_generated.sql')

Write-Host "[4/5] Running sanity queries..."
$patients = docker compose -f $composeFile exec -T mysql mysql -uroot -p$env:MYSQL_ROOT_PASSWORD -D $env:MYSQL_DATABASE -N -e "SELECT COUNT(*) FROM patients;"
$appointments = docker compose -f $composeFile exec -T mysql mysql -uroot -p$env:MYSQL_ROOT_PASSWORD -D $env:MYSQL_DATABASE -N -e "SELECT COUNT(*) FROM appointments;"

if ([int]$patients -le 0 -or [int]$appointments -le 0) {
    throw "Sanity checks failed: patients=$patients appointments=$appointments"
}

Write-Host "[5/5] Smoke test passed. patients=$patients appointments=$appointments"
