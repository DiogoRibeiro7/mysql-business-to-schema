$ErrorActionPreference = 'Stop'

$rootDir = Split-Path -Parent $PSScriptRoot
$composeFile = Join-Path $rootDir 'docker/docker-compose.yml'
$outputDir = Join-Path $rootDir 'generators/clinic/output'

if (-not (Test-Path $outputDir)) {
    throw "Generated output not found. Run: python generators/clinic/generate.py --config generators/clinic/config.yaml"
}

docker compose -f $composeFile exec mysql mkdir -p /var/lib/mysql-files/clinic_generated | Out-Null

$files = @('patients.csv', 'doctors.csv', 'appointments.csv', 'invoices.csv', 'payments.csv')
foreach ($file in $files) {
    $src = Join-Path $outputDir $file
    if (-not (Test-Path $src)) {
        throw "Missing $file in generators/clinic/output. Re-run the generator."
    }
    docker cp $src mysql_business_to_schema:/var/lib/mysql-files/clinic_generated/
}

Write-Host "CSV files copied. Loading into MySQL..."
docker compose -f $composeFile exec mysql mysql -uroot -p < (Join-Path $rootDir 'example_01_clinic/schema/10_load_generated.sql')
