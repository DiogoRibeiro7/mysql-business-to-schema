@echo off
REM Docker Compose Manager for MySQL Business-to-Schema Examples (Windows)
REM Usage: docker-manager.bat [command] [example]

setlocal enabledelayedexpansion

REM Check if Docker is installed
docker --version >nul 2>&1
if errorlevel 1 (
    echo Error: Docker is not installed or not in PATH
    exit /b 1
)

REM Parse command
set COMMAND=%1
set EXAMPLE=%2

if "%COMMAND%"=="" goto :show_usage

REM Execute command
if /i "%COMMAND%"=="start" goto :start_example
if /i "%COMMAND%"=="stop" goto :stop_example
if /i "%COMMAND%"=="restart" goto :restart_example
if /i "%COMMAND%"=="status" goto :show_status
if /i "%COMMAND%"=="logs" goto :show_logs
if /i "%COMMAND%"=="generate" goto :generate_data
if /i "%COMMAND%"=="clean" goto :clean_example
if /i "%COMMAND%"=="list" goto :list_examples
if /i "%COMMAND%"=="ports" goto :show_ports
goto :show_usage

:show_usage
echo Docker Compose Manager for MySQL Business-to-Schema
echo ======================================================
echo.
echo Usage: %0 [command] [example]
echo.
echo Commands:
echo   start [example]    - Start specific example or all
echo   stop [example]     - Stop specific example or all
echo   restart [example]  - Restart specific example or all
echo   status [example]   - Show status of containers
echo   logs [example]     - Show logs for specific example
echo   generate [example] - Run data generator for example
echo   clean [example]    - Stop and remove containers/volumes
echo   list               - List all available examples
echo   ports              - Show all exposed ports
echo.
echo Examples:
echo   %0 start clinic
echo   %0 generate ecommerce
echo   %0 status all
echo   %0 clean all
goto :end

:start_example
if "%EXAMPLE%"=="" set EXAMPLE=all
echo Starting %EXAMPLE%...

if /i "%EXAMPLE%"=="all" (
    for /d %%D in (example_*) do (
        if exist "%%D\docker-compose.yml" (
            echo Starting %%D...
            cd %%D
            docker-compose up -d
            cd ..
        )
    )
) else (
    set FOUND=0
    for /d %%D in (example_*) do (
        echo %%D | findstr /i %EXAMPLE% >nul
        if !errorlevel!==0 (
            if exist "%%D\docker-compose.yml" (
                echo Starting %%D...
                cd %%D
                docker-compose up -d
                cd ..
                set FOUND=1
            )
        )
    )
    if !FOUND!==0 (
        echo Example '%EXAMPLE%' not found!
        exit /b 1
    )
)
goto :end

:stop_example
if "%EXAMPLE%"=="" set EXAMPLE=all
echo Stopping %EXAMPLE%...

if /i "%EXAMPLE%"=="all" (
    for /d %%D in (example_*) do (
        if exist "%%D\docker-compose.yml" (
            echo Stopping %%D...
            cd %%D
            docker-compose down
            cd ..
        )
    )
) else (
    set FOUND=0
    for /d %%D in (example_*) do (
        echo %%D | findstr /i %EXAMPLE% >nul
        if !errorlevel!==0 (
            if exist "%%D\docker-compose.yml" (
                echo Stopping %%D...
                cd %%D
                docker-compose down
                cd ..
                set FOUND=1
            )
        )
    )
    if !FOUND!==0 (
        echo Example '%EXAMPLE%' not found!
        exit /b 1
    )
)
goto :end

:restart_example
call :stop_example
call :start_example
goto :end

:show_status
if "%EXAMPLE%"=="" set EXAMPLE=all
echo Status of %EXAMPLE%:
echo.

if /i "%EXAMPLE%"=="all" (
    for /d %%D in (example_*) do (
        if exist "%%D\docker-compose.yml" (
            echo === %%D ===
            cd %%D
            docker-compose ps
            cd ..
            echo.
        )
    )
) else (
    set FOUND=0
    for /d %%D in (example_*) do (
        echo %%D | findstr /i %EXAMPLE% >nul
        if !errorlevel!==0 (
            if exist "%%D\docker-compose.yml" (
                echo === %%D ===
                cd %%D
                docker-compose ps
                cd ..
                set FOUND=1
            )
        )
    )
    if !FOUND!==0 (
        echo Example '%EXAMPLE%' not found!
        exit /b 1
    )
)
goto :end

:show_logs
if "%EXAMPLE%"=="" (
    echo Please specify an example for logs
    exit /b 1
)

set FOUND=0
for /d %%D in (example_*) do (
    echo %%D | findstr /i %EXAMPLE% >nul
    if !errorlevel!==0 (
        if exist "%%D\docker-compose.yml" (
            cd %%D
            docker-compose logs -f
            cd ..
            set FOUND=1
        )
    )
)
if !FOUND!==0 (
    echo Example '%EXAMPLE%' not found!
    exit /b 1
)
goto :end

:generate_data
if "%EXAMPLE%"=="" (
    echo Please specify an example for data generation
    exit /b 1
)

set FOUND=0
for /d %%D in (example_*) do (
    echo %%D | findstr /i %EXAMPLE% >nul
    if !errorlevel!==0 (
        if exist "%%D\docker-compose.yml" (
            echo Running data generator for %%D...
            cd %%D
            docker-compose run --rm data_generator
            cd ..
            set FOUND=1
        )
    )
)
if !FOUND!==0 (
    echo Example '%EXAMPLE%' not found!
    exit /b 1
)
goto :end

:clean_example
if "%EXAMPLE%"=="" set EXAMPLE=all

if /i "%EXAMPLE%"=="all" (
    echo WARNING: This will remove all containers and volumes!
    set /p CONFIRM="Are you sure? (y/N): "
    if /i "!CONFIRM!"=="y" (
        for /d %%D in (example_*) do (
            if exist "%%D\docker-compose.yml" (
                echo Cleaning %%D...
                cd %%D
                docker-compose down -v
                cd ..
            )
        )
    )
) else (
    set FOUND=0
    for /d %%D in (example_*) do (
        echo %%D | findstr /i %EXAMPLE% >nul
        if !errorlevel!==0 (
            if exist "%%D\docker-compose.yml" (
                echo WARNING: This will remove containers and volumes for %%D!
                set /p CONFIRM="Are you sure? (y/N): "
                if /i "!CONFIRM!"=="y" (
                    echo Cleaning %%D...
                    cd %%D
                    docker-compose down -v
                    cd ..
                )
                set FOUND=1
            )
        )
    )
    if !FOUND!==0 (
        echo Example '%EXAMPLE%' not found!
        exit /b 1
    )
)
goto :end

:list_examples
echo Available examples:
echo.
for /d %%D in (example_*) do (
    if exist "%%D\docker-compose.yml" (
        echo   %%D
    )
)
goto :end

:show_ports
echo Exposed ports for all examples:
echo.
echo Example                              ^| MySQL Port ^| phpMyAdmin
echo ------------------------------------ ^| ---------- ^| ----------

for /d %%D in (example_*) do (
    if exist "%%D\docker-compose.yml" (
        set MYSQL_PORT=N/A
        set PHPMYADMIN_PORT=N/A

        REM Parse MySQL port
        for /f "tokens=1 delims=:" %%P in ('findstr /c:"3306" "%%D\docker-compose.yml" 2^>nul ^| findstr /c:"ports:"') do (
            set MYSQL_PORT=%%P
        )

        REM Parse phpMyAdmin port
        for /f "tokens=1 delims=:" %%P in ('findstr /c:"80" "%%D\docker-compose.yml" 2^>nul ^| findstr /v "#"') do (
            set PHPMYADMIN_PORT=localhost:%%P
        )

        echo %%D                              ^| !MYSQL_PORT! ^| !PHPMYADMIN_PORT!
    )
)
goto :end

:end
endlocal