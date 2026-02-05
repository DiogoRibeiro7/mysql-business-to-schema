$ErrorActionPreference = 'Stop'

param(
    [string]$Example = 'clinic'
)

$rootDir = Split-Path -Parent $PSScriptRoot
$composeFile = Join-Path $rootDir 'docker/docker-compose.yml'

$examples = @{
    clinic = @{
        OutputDir = Join-Path $rootDir 'generators/clinic/output'
        ContainerDir = '/var/lib/mysql-files/clinic_generated'
        LoadSql = Join-Path $rootDir 'example_01_clinic/schema/10_load_generated.sql'
        GeneratorHint = 'python generators/clinic/generate.py --config generators/clinic/config.yaml'
        Files = @('patients.csv', 'doctors.csv', 'appointments.csv', 'invoices.csv', 'payments.csv')
    }
}

if (-not $examples.ContainsKey($Example)) {
    $known = ($examples.Keys | Sort-Object) -join ', '
    throw "Unknown example '$Example'. Known examples: $known"
}

$config = $examples[$Example]

if (-not (Test-Path $config.OutputDir)) {
    throw "Generated output not found for '$Example'. Run: $($config.GeneratorHint)"
}

if (-not (Test-Path $config.LoadSql)) {
    throw "Load script not found: $($config.LoadSql)"
}

docker compose -f $composeFile exec mysql mkdir -p $config.ContainerDir | Out-Null

foreach ($file in $config.Files) {
    $src = Join-Path $config.OutputDir $file
    if (-not (Test-Path $src)) {
        throw "Missing $file in $($config.OutputDir). Re-run the generator."
    }
    docker cp $src mysql_business_to_schema:$($config.ContainerDir)/
}

Write-Host "CSV files copied for '$Example'. Loading into MySQL..."
docker compose -f $composeFile exec mysql mysql -uroot -p < $config.LoadSql
