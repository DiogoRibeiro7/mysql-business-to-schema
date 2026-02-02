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

docker compose -f $composeFile up -d | Out-Null

Write-Host "MySQL is running."
Write-Host "Host: localhost"
Write-Host "Port: 3306"
Write-Host "User: root"
Write-Host "Password: $($env:MYSQL_ROOT_PASSWORD)"
Write-Host "Database: $($env:MYSQL_DATABASE)"
Write-Host ""
Write-Host "Opening MySQL shell..."
docker compose -f $composeFile exec mysql mysql -uroot -p$env:MYSQL_ROOT_PASSWORD -D $env:MYSQL_DATABASE
