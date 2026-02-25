@echo off
REM MySQL Business-to-Schema Data Generation Script for Windows
REM Generates test data for all schemas

echo ==========================================
echo MySQL Business-to-Schema Data Generation
echo ==========================================
echo.

REM Configuration
set MYSQL_HOST=localhost
set MYSQL_USER=root
set MYSQL_PASSWORD=root
set MYSQL_PORT=3306

REM Default values
set RECORDS_PER_TABLE=1000
set CLEAN_FIRST=
set PARALLEL=
set SCHEMAS=

REM Parse arguments
:parse_args
if "%~1"=="" goto :end_parse
if "%~1"=="--records" (
    set RECORDS_PER_TABLE=%~2
    shift
    shift
    goto :parse_args
)
if "%~1"=="--clean" (
    set CLEAN_FIRST=--clean
    shift
    goto :parse_args
)
if "%~1"=="--parallel" (
    set PARALLEL=--parallel
    shift
    goto :parse_args
)
if "%~1"=="--schemas" (
    set SCHEMAS=--schemas %~2
    shift
    shift
    goto :parse_args
)
shift
goto :parse_args
:end_parse

echo Configuration:
echo   - MySQL Host: %MYSQL_HOST%:%MYSQL_PORT%
echo   - Records per table: %RECORDS_PER_TABLE%
echo   - Clean existing data: %CLEAN_FIRST%
echo   - Parallel generation: %PARALLEL%
echo.

REM Check MySQL connection
echo Checking MySQL connection...
mysql -h %MYSQL_HOST% -P %MYSQL_PORT% -u %MYSQL_USER% -p%MYSQL_PASSWORD% -e "SELECT 1" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Error: Cannot connect to MySQL
    exit /b 1
)
echo MySQL connection successful
echo.

REM List available schemas
echo Available Schemas:
mysql -h %MYSQL_HOST% -P %MYSQL_PORT% -u %MYSQL_USER% -p%MYSQL_PASSWORD% -e "SHOW DATABASES" 2>nul | findstr "_db$"

REM Run Python generator
echo.
echo Starting data generation...

REM Build command
set CMD=python generators\generate_all_data.py --records %RECORDS_PER_TABLE% %CLEAN_FIRST% %PARALLEL% %SCHEMAS%

REM Execute generator
echo Running: %CMD%
%CMD%

if %ERRORLEVEL% NEQ 0 (
    echo Error: Data generation failed
    exit /b 1
)

REM Verify data generation
echo.
echo Verifying generated data...
mysql -h %MYSQL_HOST% -P %MYSQL_PORT% -u %MYSQL_USER% -p%MYSQL_PASSWORD% -e "SELECT table_schema AS 'Schema', COUNT(*) AS 'Tables', SUM(table_rows) AS 'Total Rows' FROM information_schema.tables WHERE table_schema LIKE '%%_db' GROUP BY table_schema ORDER BY table_schema;"

REM Summary
echo.
echo ==========================================
echo Data Generation Complete!
echo ==========================================
echo.
echo Next steps:
echo   1. Verify data: mysql -u %MYSQL_USER% -p -e "USE clinic_db; SELECT COUNT(*) FROM patients;"
echo   2. Run tests: python test_system.py
echo   3. Start services: docker-compose up -d
echo.